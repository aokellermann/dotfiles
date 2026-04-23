# System Performance Tuning

Record of performance-related system configuration on this machine. These changes live outside the dotfiles git tree (in `/etc/`, the EFI partition, and Firefox autoconfig) so they aren't captured by this repo — this file is the source of truth for what was changed and why.

## Hardware context

- **Laptop**: Lenovo ThinkPad, plugged in most of the time
- **CPU**: Intel Core Ultra 7 258V (Lunar Lake, 4P+4E, 8 threads)
- **RAM**: 32 GB LPDDR5X, **soldered / non-upgradeable**
- **Storage**: Samsung 990 EVO Plus 4TB NVMe
- **GPU**: Intel Arc 130V/140V (integrated)

The soldered RAM is load-bearing for several tuning decisions: we can't add memory, so we extract more effective memory via zram and add disk swap as OOM insurance.

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

### LUKS discard (TODO — not yet applied)

Weekly `fstrim.timer` is enabled but only trims `/boot` because `/`, `/home`, `/xfs` are LUKS-encrypted without `discard` passthrough. To fix:

- Add `:discard` to `rd.luks.name=` in `/boot/loader/entries/arch.conf`
- Add `discard` to the options column in `/etc/crypttab` for `/home` and `/xfs`

Minor threat-model cost (deleted block patterns observable on raw disk) — irrelevant for laptop.

## Boot time

### firejail-bridge decoupled from network-online

Drop-in at `/etc/systemd/system/firejail-bridge.service.d/override.conf`:
```ini
[Unit]
Wants=
After=
After=wg-quick@wg0-mullvad.service
```

The upstream unit had `Wants=network-online.target` + `After=network-online.target`, forcing boot to block on `network-online.target` for ~44s. The bridge actually only needs the WireGuard tunnel interface to exist (handled by `wg-quick@wg0-mullvad.service`), not full network readiness. Removing the `network-online.target` dependency dropped boot time significantly.

If the bridge ever fails at boot, revert by removing the override file and running `systemctl daemon-reload`.

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
