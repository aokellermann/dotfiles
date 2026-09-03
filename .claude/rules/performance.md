# System Performance Tuning

Record of performance-related system configuration on this machine. These changes live outside the dotfiles git tree (in `/etc/`, the EFI partition, and Firefox autoconfig) so they aren't captured by this repo — this file is the source of truth for what was changed and why.

## Hardware context

- **Laptop**: Lenovo ThinkPad, plugged in most of the time
- **CPU**: Intel Core Ultra 7 258V (Lunar Lake, 4P+4E, 8 threads)
- **RAM**: 32 GB LPDDR5X, **soldered / non-upgradeable**
- **Storage**: Samsung 990 EVO Plus 4TB NVMe
- **GPU**: Intel Arc 130V/140V (integrated)

The soldered RAM is load-bearing for several tuning decisions: we can't add memory, so we extract more effective memory via zram and add disk swap as OOM insurance.

## CPU stuck at ~400 MHz after resume (Lunar Lake bug)

Known platform bug on Lunar Lake ThinkPads (Lenovo tracks it for these models; also widely reported by Phoronix/Arch users): after s2idle resume the SoC sometimes comes back clamped to its minimum frequency (~400 MHz) and won't boost even under load. Diagnosed 2026-08-23 on this machine (BIOS N4BET34W 1.06, model 21NS0014US).

**Un-stick immediately**: toggle the ACPI platform profile and back —
```bash
powerprofilesctl set performance && sleep 1 && powerprofilesctl set balanced
```
(or write to `/sys/firmware/acpi/platform_profile` directly as root).

**Confirm stuck vs. fine**: load one core and watch it — `taskset -c 3 timeout 3 sh -c 'while :; do :; done' & sleep 1; cat /sys/devices/system/cpu/cpu3/cpufreq/scaling_cur_freq`. ≥2 GHz = fine; ~400000 = stuck.

**Durable fixes**:
- Resume hook that auto-bounces the profile: `~/.local/share/platform-profile-bounce.sh`, installed to `/usr/lib/systemd/system-sleep/platform-profile-bounce`.
- BIOS update — **done 2026-08-24**: now System Firmware 1.29 / UEFI 1.47 (N4BET77W) / EC 1.41 / ME 20.0.5.1722, the latest as of that date. Machine is ThinkPad X1 Carbon Gen 13 (21NS/21NT); it shipped on the initial factory release (UEFI 1.06, N4BET34W, 2024-11) and was never updated until now.

**How to update firmware on this machine (lessons from the 2026-08-24 update):**
- **fwupd/LVFS is the right tool, with a catch**: on factory firmware the ESRT device has no LVFS matches, which looks like "no coverage". Coverage appears once the firmware is past ~1.06, and LVFS then only ever shows the *next allowed hop*, not the whole chain — run `fwupdmgr upgrade`, reboot, repeat until "No updates available". The chain walked 1.08 → 1.11 → 1.29 here.
- **Bootstrap from factory firmware needed Lenovo's Update CD ISO once** (dd to USB, F12 boot, "Update system program"; AC required): package N4BUR11W (https://download.lenovo.com/pccbbs/mobiles/n4bur11w.iso, sha256 47385817812d...f8702). The latest CD (N4BUR30W) refuses to flash over factory firmware directly. Gotcha: the CD flashed UEFI+EC but silently skipped the **ME firmware** stage, which left the ESRT composite version at 0 and kept N4BUR30W refusing — the LVFS 1.08 capsule is what completed ME and unstuck everything.
- Component versions from Linux: UEFI `/sys/class/dmi/id/bios_version`, EC `/sys/class/dmi/id/ec_firmware_release`, ME `/sys/class/mei/mei0/fw_ver`, composite via `fwupdmgr get-devices` (System Firmware entry).
- Once on 1.22+, firmware cannot be rolled back below 1.22.

Not a thermal/RAPL issue — PL1/PL2 are 37 W and throttle counters are normal when this happens.

## Memory / swap

### zram (16G)

Config: `/etc/systemd/zram-generator.conf`
```ini
[zram0]
zram-size = 16384
```

Sized at ~50% of RAM. At measured ~3.25x zstd compression ratio, worst-case real RAM cost is ~5 GB when full. Browser + Electron + Claude processes compress very well (text-heavy).

Priority 100 (default) — used before disk swap.

### Disk swapfile (8G) — OOM insurance

Created via:
```bash
sudo fallocate -l 8G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon -p 10 /swapfile
```

`/etc/fstab` entry:
```
/swapfile none swap defaults,pri=10 0 0
```

Priority 10 (well below zram's 100) — only touched under genuine memory exhaustion. On the 990 EVO Plus, swap-in is fast enough to be acceptable as fallback. Exists because RAM is non-upgradeable.

### sysctl tuning

`/etc/sysctl.d/99-zram.conf`:
```
vm.page-cluster = 0
```

`page-cluster=0` is the standard zram recommendation: kernel default (3) prefetches 8 pages on swap-in, which makes sense for spinning disk but is wasted overhead for zram's random-access compressed memory.

Left `vm.swappiness` at default 60 — was working fine.

## NVMe

### APST latency cap

Added to kernel cmdline in `/boot/loader/entries/arch.conf` (systemd-boot):
```
nvme_core.default_ps_max_latency_us=10000
```

Samsung 990 EVO Plus's deepest power state (PS4) has **43 ms exit latency** — causes occasional ~10,000× stalls when the drive wakes from deep idle. Capping at 10ms forces the drive to stop at PS3 (4.6 ms exit, 0.08 W). Battery cost is negligible (~0.07 W) and the stalls disappear.

Verify after boot:
```bash
sudo nvme get-feature /dev/nvme0 -f 0x0c -H
```
Entry 3 should no longer transition to PS4.

### LUKS discard — intentionally NOT enabled

Weekly `fstrim.timer` only trims `/boot` because `/`, `/home`, `/xfs` are LUKS-encrypted and LUKS blocks TRIM passthrough by default. Enabling `discard` on the LUKS layer would restore TRIM for better sustained write performance and SSD wear-leveling, but leaks coarse disk-usage patterns (free vs. used regions) to anyone with physical access to the raw ciphertext.

User chose to keep TRIM disabled on encrypted volumes. Drive is at 1% wear after 3310 hours, so this is fine — performance impact is long-term and gradual, not acute. Do not re-propose this change.

## XFS (Docker data on /xfs)

`/xfs` holds only the Docker/containerd data root (`/xfs/docker`, `/xfs/containerd`). fstab entry (UUID `d2aa202e-470e-419c-bb6a-1ea24a679221`):

```
UUID=... /xfs xfs rw,noatime,nodiratime,logbsize=256k 0 2
```

`logbsize=256k` (up from the kernel default 32k) was added 2026-08-19 to speed up the metadata-heavy container builds — `pnpm`/`composer`/`apt` steps create thousands of tiny files, and a larger in-memory log buffer batches more journal writes per flush. `logbsize` is fixed at mount time and **cannot** be changed via `mount -o remount`; it requires a full umount/mount (stop docker+containerd, or reboot). Downside is bounded: an unclean shutdown loses a slightly larger window of un-checkpointed *metadata* (XFS stays consistent via journal replay — no corruption), and ~224KB extra RAM per mount. Acceptable for a disposable-layer filesystem on a plugged-in laptop.

`noatime,nodiratime` already set. Do not add `discard` here — see the LUKS discard note above (same reasoning applies to this encrypted volume).

## LUKS keyfile slots (home/xfs) — cheap KDF

`/dev/nvme0n1p3` (home) and `/dev/nvme0n1p4` (xfs) unlock at boot via random keyfiles in `/etc/cryptsetup-keys.d/` (see `/etc/crypttab`). As installed, the keyfile lived in slot 0 with PBKDF2 @ 6.7M iterations, and slot 1 holds an Argon2id (1 GiB, time cost 6) passphrase. Because cryptsetup pays each slot's full KDF cost while searching for a match, and both volumes unlocked concurrently during early-boot CPU contention, the two unlocks took 26–32s and dominated the boot critical chain.

Fixed 2026-08-22 via `~/luks-cheap-keyslot.sh`: the same keyfile was re-added to slot 2 with PBKDF2 @ 1000 iterations and priority `prefer` (tried first), then the expensive slot 0 was removed. A high-entropy random keyfile gains nothing from a memory-hard KDF — Argon2/PBKDF2 cost only protects weak passphrases — so this is zero security loss. Slot 1 (passphrase, strong Argon2id) is untouched and remains the backup way in; do not weaken or remove it.

Current layout per volume: slot 1 = passphrase (argon2id, strong), slot 2 = keyfile (pbkdf2, 1000 iter, prefer). If a keyfile is ever regenerated, re-add it with `--pbkdf pbkdf2 --pbkdf-force-iterations 1000 --new-key-slot <n>` + `cryptsetup config --key-slot <n> --priority prefer`, not with defaults.

## Boot time

### firejail-bridge — removed

The firejail/IPFS stack was uninstalled 2026-08-22. `firejail-bridge.service` (custom unit in `/etc/systemd/system/`, plus its `override.conf` drop-in that had decoupled it from `network-online.target` for boot speed) and the `/usr/local/bin/firejail-bridge-{up,down}.sh` scripts were removed along with it. If a sandboxed-network need returns, the old bridge setup is in the dotfiles git history (README.md, "Sandboxed IPFS Network" section).

### docker/containerd off the boot critical path

docker.service was `WantedBy=multi-user.target`; because targets implicitly wait (`After=`) for every unit they Want, graphical.target sat behind docker+containerd (~6.6s of the critical chain). Fixed 2026-08-22 via `~/docker-boot-timer.sh`: `docker.service` disabled, and `/etc/systemd/system/docker-boot.timer` (OnBootSec=3s, Unit=docker.service, WantedBy=timers.target) enabled instead. Timer units activate instantly at boot; the service start they fire is not ordered before any boot target, so docker still starts every boot (~3s in, restoring `unless-stopped` containers like the cvebench buildx builder) without gating login.

`systemctl start/restart docker` still works; shutdown ordering unchanged. **Do not run `systemctl enable docker`** (and decline if a package update suggests it) — that re-adds the boot gate; `docker-boot.timer` is the enabled thing now. Revert: disable the timer, remove the unit file, daemon-reload, re-enable docker.service.

## Firefox

### Hardware video acceleration (VA-API)

Added to `~/.mozilla/firefox/user.js` (loaded globally via autoconfig at `/usr/lib/firefox/firefox.cfg`):
```javascript
defaultPref("media.ffmpeg.vaapi.enabled", true)
defaultPref("media.hardware-video-decoding.force-enabled", true)
defaultPref("media.rdd-ffmpeg.enabled", true)
defaultPref("widget.dmabuf.force-enabled", true)
```

Firefox was doing CPU video decode despite `intel-media-driver` being installed and `vainfo` showing full codec support. Huge battery / thermal / CPU win for video playback.

Verify at `about:support` → Compositing should show `WebRender` and HARDWARE_VIDEO_DECODING should be `Available`.

## Already-optimal settings (do not "fix")

- **CPU governor = `powersave`** with `intel_pstate` active + EPP=performance. This is the correct modern Intel setup — the "performance" governor is only for the legacy `acpi_cpufreq` driver.
- **I/O scheduler = `none`** on NVMe. Correct; mq-deadline / kyber / bfq all add overhead for no benefit on fast NVMe.
- **Power profile = `performance`** via `power-profiles-daemon` (AC-switcher script handles battery).
- **THP = `always`** — fine for desktop.
- **Docker** already uses BuildKit + containerd snapshotter, `overlayfs` driver, data root on XFS at `/xfs/docker`.
- **zswap disabled** in kernel cmdline (`zswap.enabled=0`) — correct because we use zram instead.

## Things intentionally NOT changed

- **`mitigations=off`** — would give ~5-10% on syscall-heavy workloads but meaningful security loss. Not worth it on a browser/dev box.
- **XFS Docker partition** — migrating Docker storage back to ext4 on root is annoying and the perf difference is single-digit % on NVMe. Left alone.
- **earlyoom / systemd-oomd** — optional; no OOM history, not installed.
- **swappiness tuning** — default 60 working fine with current zram config.

## Diagnostic recipes

```bash
# Memory pressure snapshot
free -h && zramctl && cat /proc/pressure/memory

# Is the system actively swapping vs just holding compressed pages?
vmstat 1 5    # si/so columns: 0 = fine, nonzero = active swapping

# zram compression ratio
cat /sys/block/zram0/mm_stat   # DATA COMPR TOTAL — ratio = DATA / TOTAL

# NVMe health + APST state
sudo nvme smart-log /dev/nvme0 | grep -E "percentage_used|media_errors|temperature"
sudo nvme get-feature /dev/nvme0 -f 0x0c -H

# Boot time analysis
systemd-analyze
systemd-analyze critical-chain
systemd-analyze blame | head

# OOM history
journalctl -k --since "1 month ago" | grep -iE "killed process|oom-kill"
```
