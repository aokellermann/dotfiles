# System Security Hardening

Record of security hardening applied to this machine. Based on a Lynis audit (2026-04-24, score 72) and the Arch Wiki security page. These changes live in `/etc/` and are not captured by the dotfiles repo — this file is the source of truth.

## Hardware context

- **Laptop**: Lenovo ThinkPad, Intel Core Ultra 7 258V (Lunar Lake)
- **Encryption**: Full-disk LUKS, single partition layout
- **Sandboxing**: firejail (for IPFS, browsers, etc.)
- **Kernel**: `linux` (not `linux-hardened` — Electron/Chromium sandbox compatibility issues outweigh the ASLR improvement on a desktop)

## Applied hardening

### Sysctl (`/etc/sysctl.d/99-hardening.conf`)

```ini
kernel.kptr_restrict = 2
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1
net.ipv4.conf.default.send_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
fs.suid_dumpable = 0
```

`fs.suid_dumpable` is set to 2 by `/usr/lib/sysctl.d/50-coredump.conf` — the `99-` prefix ensures our file loads last and overrides to 0.

### Already-good sysctl values (do not regress)

- `kernel.dmesg_restrict = 1`
- `kernel.yama.ptrace_scope = 1`
- `kernel.unprivileged_bpf_disabled = 2`
- `net.ipv4.conf.all.send_redirects = 0`
- `net.ipv4.tcp_syncookies = 1`
- `net.ipv4.icmp_ignore_bogus_error_responses = 1`
- `fs.protected_hardlinks = 1`, `fs.protected_symlinks = 1`, `fs.protected_regular = 1`, `fs.protected_fifos = 1`

### Disabled kernel modules

`/etc/modprobe.d/disable-uncommon-protocols.conf`:
```
install dccp /bin/true
install sctp /bin/true
install rds /bin/true
install tipc /bin/true
```

`/etc/modprobe.d/disable-firewire.conf`:
```
install firewire-sbp2 /bin/true
install firewire_sbp2 /bin/true
```

### Core dump limits

`/etc/security/limits.d/99-coredump.conf`:
```
* hard core 0
```

### login.defs

- `UMASK` = 022 (default). Previously hardened to 027 but reverted 2026-05-18 — on a single-user laptop with `chmod 750 /home/aokellermann` already gating other-user access, stripping other-read from every new file is belt-and-suspenders against a threat that doesn't exist. The cost is real, though: any process running under a different uid/gid that needs to read a file you own — containers with non-root users (mysql, www-data, nobody), sandboxed services, bind-mounted scripts into Docker — silently breaks with permission denied. Git stores only the executable bit and uses umask for the rest, so cloning a repo with 027 umask materializes files at e.g. 640 instead of their tracked 644 and downstream consumers fail in confusing ways. The work of "no other human reads my files" is already done by the home-dir 750, LUKS, and firejail/Flatpak sandboxes — umask 027 doesn't add to that. Do not propose re-tightening to 027.
- `YESCRYPT_COST_FACTOR` = 11 (was unset, default 5)
- `ENCRYPT_METHOD` = YESCRYPT (already default)

### Home directory

`chmod 750 /home/aokellermann`

### /etc/hosts

```
127.0.0.1  arch localhost
::1        arch localhost
```

### Login banner (`/etc/issue`)

```
Authorized uses only. All activity may be monitored and reported.
```

### Security packages

- `arch-audit` — check for vulnerable installed packages
- `libpwquality` — PAM password strength (installed, not wired into PAM)
- `aide` — file integrity monitoring
- `sysstat` — system accounting
- `intel-ucode` — CPU microcode updates

### Enabled services

- `auditd` — kernel audit framework
- `sysstat` — system accounting collection
- `aide-check.timer` — daily AIDE integrity checks

### AIDE

Database initialized at `/var/lib/aide/aide.db.gz` (649,545 entries). After legitimate changes (package upgrades), update baseline:
```bash
sudo aide --update
sudo mv /var/lib/aide/aide.db.new.gz /var/lib/aide/aide.db.gz
```

## Pending improvements

### High priority

- **Firewall (ufw/nftables)** — currently inactive. PostgreSQL (5432), Redis (6379), port 8888, and port 3000 are bound to 0.0.0.0 and reachable on the network. Either bind them to 127.0.0.1 or enable a firewall with default-deny inbound.
- **Disable kexec** — add `kernel.kexec_load_disabled = 1` to `99-hardening.conf`
- **BPF JIT hardening** — add `net.core.bpf_jit_harden = 2` to `99-hardening.conf`
- **Failed login delay** — add `auth optional pam_faildelay.so delay=4000000` as first line of `/etc/pam.d/system-login`

### Medium priority

- **BIOS password + Secure Boot** — Secure Boot alone is meaningless since an attacker can disable it in UEFI settings. Set a ThinkPad supervisor/BIOS password first, then enable Secure Boot. Together they complete the boot chain: can't boot from USB (boot order locked), can't disable Secure Boot (BIOS password), can't modify kernel/initramfs (signature check), can't read disk (LUKS). Without the BIOS password, skip Secure Boot entirely.

  **ThinkPad-specific brick warning**: many Lenovo ThinkPad X/P/T series laptops sign their UEFI firmware/applications with a Lenovo CA. Replacing the Platform Key without preserving the Lenovo CA can brick the firmware (no recovery via firmware settings). Always use `-m -f` to keep both Microsoft and OEM firmware keys when enrolling.

  Two viable approaches:

  **Option A — sbctl (works with any boot loader):**
  ```bash
  sudo pacman -S sbctl
  sbctl create-keys
  sbctl enroll-keys -m -f         # -m: Microsoft keys, -f: OEM firmware keys (Lenovo CA)
  sbctl sign -s /boot/vmlinuz-linux
  sbctl sign -s /boot/EFI/systemd/systemd-bootx64.efi
  sbctl verify
  # then reboot into UEFI, set supervisor password, enable Secure Boot
  ```
  Pacman hook auto-signs new kernels/boot loader on update. For systemd-boot, sign the binary in `/usr/lib/` so `bootctl update` picks it up:
  ```bash
  sbctl sign -s -o /usr/lib/systemd/boot/efi/systemd-bootx64.efi.signed /usr/lib/systemd/boot/efi/systemd-bootx64.efi
  ```

  **Option B — systemd built-in (v257+, simpler if using systemd-boot):**
  ```bash
  sudo pacman -S systemd-ukify
  ukify genkey --config /etc/kernel/uki.conf
  /usr/lib/systemd/systemd-sbsign sign \
    --private-key /etc/kernel/secure-boot-private-key.pem \
    --certificate /etc/kernel/secure-boot-certificate.pem \
    --output /usr/lib/systemd/boot/efi/systemd-bootx64.efi.signed \
    /usr/lib/systemd/boot/efi/systemd-bootx64.efi
  bootctl install --secure-boot-auto-enroll yes \
    --certificate /etc/kernel/secure-boot-certificate.pem \
    --private-key /etc/kernel/secure-boot-private-key.pem
  # set `secure-boot-enroll force` in /boot/loader/loader.conf
  # reboot to enroll keys
  ```
  Caveat: this method does NOT include Microsoft or OEM firmware certs by default — risk of bricking the ThinkPad. Option A with `sbctl -m -f` is safer.
- **Kernel lockdown (integrity mode)** — add `lockdown=integrity` to kernel cmdline. Prevents userland from modifying the running kernel. Disables hibernation. Auto-enforced when Secure Boot is active on some setups.

### Low priority

- **Password aging** — `PASS_MIN_DAYS 1`, `PASS_MAX_DAYS 365` in `/etc/login.defs`. Low value for single-user desktop.
- **PAM pwquality** — wire `pam_pwquality.so` into `/etc/pam.d/passwd` before `pam_unix.so`.

## Intentionally not applied

| Item | Reason |
|---|---|
| `linux-hardened` kernel | Breaks Electron/Chromium unprivileged user namespaces; ASLR gain is marginal on desktop with existing sysctl hardening |
| AppArmor / SELinux | firejail already provides application sandboxing; AppArmor profile coverage is thin on Arch |
| `hardened_malloc` | Can break applications; marginal benefit with ASLR in place |
| USBGuard | USB storage actively used; overkill for personal desktop |
| Separate `/var` partition | Intentional single LUKS partition layout |
| Remote syslog | Personal desktop |
| Restrict compilers | Developer machine |
| `mitigations=off` | Meaningful security loss; not worth 5-10% perf on a browser/dev box |
| Disable USB storage | Actively used |
| Shell timeout (TMOUT) | Only useful for unattended TTYs; sway locks screen instead |

## Application sandboxing: Flatpak vs native

Heuristic for deciding which apps to install as Flatpak vs pacman/AUR. The goal is meaningful sandbox boundaries, not Flatpak-everywhere.

### Use Flatpak for

Third-party desktop GUI apps where the sandbox actually constrains something useful and Flathub tracks upstream more closely than Arch:

- **GIMP** (`org.gimp.GIMP`)
- **Anki** (`net.ankiweb.Anki`)
- **OBS Studio** (`com.obsproject.Studio`) — first-class PipeWire/portal screen capture
- **Kdenlive** (`org.kde.kdenlive`)
- **Spotify, Slack, Postman, Signal, Deluge** — proprietary or networked apps; sandbox limits blast radius

### Keep native (do NOT move to Flatpak)

**Browsers (Firefox, Chromium):** They already implement a stronger internal sandbox (site isolation, seccomp-bpf, namespaces) than Flatpak adds, need broad host access anyway (downloads, webcam, native messaging hosts), and Firefox specifically depends on `firefox-user-autoconfig` loading `/usr/lib/firefox/firefox.cfg` → `~/.mozilla/firefox/user.js` for VA-API — this path doesn't exist in the Flatpak layout, so HW video decode tuning breaks. PWAsForFirefox native messaging host also breaks under sandbox.

**File managers (Caja, yazi):** Their entire purpose is broad filesystem access plus deep desktop integration (udisks2, gvfs, FileManager1, thumbnailers, MIME dispatch). Punching enough holes to make them work negates the sandbox.

**System/disk tools (GParted, gnome-disks):** Need raw block-device access (`/dev/sda` etc.) which Flatpak fundamentally won't grant.

**Image viewers tightly integrated with the desktop (Loupe):** Loupe already sandboxes per-image-decoder via `glycin` (bubblewrap+seccomp per file) — wrapping the whole app in Flatpak is redundant. Cold-start latency matters for short-lived launches, and the GNOME runtime is hundreds of MB for a ~1 MB app whose deps are already on the system.

**Dev tools (VS Code, neovim, kitty, zathura, IDEs, terminals):** Sandboxing fights with development workflows — filesystem access, IPC, GPU, kernel keyring, language servers, debuggers all want host access.

**CLI tools and daemons (bitwarden-cli, signal-cli, claude-code, mullvad-vpn, mpv):** No GUI sandbox benefit; CLI tools especially want host integration.

### Decision rule

**If the app's job is to manipulate the host system itself, keep it native.** File managers, partition editors, system monitors, package managers, terminals, and IDEs all fall in that bucket. Flatpak is for application-layer software whose function is self-contained.

### Anti-patterns

- Don't propose Flatpak Firefox/Chromium — see above.
- Don't propose Flatpak GParted / disk utilities — block device access won't work.
- Don't recommend "Notion Flatpak" — there is no official one on Flathub, only unofficial Electron wrappers. The AUR `notion-app-electron` is the cleaner option.

## Credentials and signing

### Threat model accepted

`ssh-agent`, `rbw-agent`, `gnome-keyring`/Secret Service, and `gh`'s keyring-stored OAuth token all share the same model: a Unix socket or D-Bus endpoint owned by the user, with **no per-app authorization and no per-request prompt**. Any process running as `aokellermann` can use them. Defense against disk theft (vault encrypted at rest) is solid; defense against a compromised local process running as the user is essentially nil. The mitigations below apply this assumption — the high-value path (git signing) gets a hardware boundary; the rest accepts the risk.

### No SSH agent

`SSH_AUTH_SOCK` is **not exported** anywhere. All SSH keys are YubiKey-backed FIDO2 (`sk-ssh-ed25519`); ssh talks directly to the YubiKey via libfido2 using the handle file referenced by `IdentityFile` in `~/.ssh/config`. There is no agent to compromise. Git signing also bypasses any agent (`ssh-keygen -Y sign` calls libfido2 directly).

Brief history: previously used rbw-agent's built-in SSH socket at `$XDG_RUNTIME_DIR/rbw/ssh-agent-socket`, which itself replaced the Bitwarden-desktop agent at `~/.bitwarden-ssh-agent.sock`. Both are obsolete here. rbw is still the password vault CLI; only its SSH-agent feature is unused.

Migration is incomplete for some keys, intentionally — `cais`, `huggingface`, `cvebench_aws`, and `cloudlab` remain as software entries in the rbw vault but are **broken** without an agent. Acceptable until those services are needed; re-migrate via `sk-keygen <name>` + upload pubkey + change `IdentityFile` to handle path. Until migration, those `Host` blocks in `~/.ssh/config` will fail with "bad permissions" when ssh tries to load `.pub` as a private key.

Active sk auth keys (handle files in `~/.ssh/`): `github`, `aur`, plus `git_signing_touch` for commits (and a retired `git_signing` from the verify-required era — see below). Each was created via `~/.local/bin/sk-keygen <name>` (except `git_signing_touch`, which intentionally skips the script — see below) and stored as a resident credential on the YubiKey (re-derivable via `ssh-keygen -K`).

### Git signing: YubiKey FIDO2 (touch-only)

**Status: signing is currently DISABLED by default** — `commit.gpgSign` and `tag.gpgSign` are set to `false` in `~/.config/git/config` (as of 2026-07-05). The key + verifier infrastructure below remains fully wired up, so re-enabling is a one-line flip of each back to `true` (or per-commit `git commit -S`). Everything in this section documents that still-present infrastructure; it just isn't invoked automatically right now.

When signing is enabled, git commits are signed with a hardware-backed FIDO2 SSH key, **not** a software key in the agent. Current key generated 2026-05-11:

```sh
ssh-keygen -t ed25519-sk -O resident \
  -O application=ssh:git-signing-touch \
  -f ~/.ssh/git_signing_touch -N "" \
  -C "git signing (yubikey, touch-only)"
```

- `-t ed25519-sk` → key material is bound to the YubiKey; signing always happens on-device.
- **No `-O verify-required`** → only touch is required per signature, no PIN. This is a deliberate policy choice — see "Policy: touch-only, not PIN+touch" below.
- `-O resident` → credential is stored in YubiKey NVRAM and can be re-derived on a new machine via `ssh-keygen -K`. Loss of the handle file ≠ loss of the key. (Loss of the YubiKey itself = loss; mitigate with a backup YubiKey enrolled the same way.)
- No passphrase on the handle file: redundant given touch already required, and `-O resident` makes the handle re-derivable.
- Application slot `ssh:git-signing-touch` is distinct from the retired `ssh:git-signing` slot, so both resident credentials coexist on the YubiKey.

**Do not regenerate this key with `~/.local/bin/sk-keygen`** — that script hardcodes `-O verify-required`, which is exactly what we don't want here. Run the `ssh-keygen` command above directly, or edit `sk-keygen` to accept a touch-only flag.

Wired up in `~/.config/git/config`:
```ini
[user]
    signingkey = ~/.ssh/git_signing_touch    # path to handle file, NOT literal pubkey — git's ssh signer feeds this to ssh-keygen -Y sign -f
[commit]
    gpgSign = false    # signing disabled by default (2026-07-05); flip to true to re-enable
[tag]
    gpgSign = false
[gpg]
    format = ssh
[gpg "ssh"]
    allowedSignersFile = /home/aokellermann/.ssh/allowed_signers
```

`~/.ssh/allowed_signers` lists three pubkeys per email (current touch-only, retired verify-required `git_signing`, retired pre-YubiKey ed25519) so `git log --show-signature` verifies all historical commits.

**Critical: do not delete any of the retired pubkeys from GitHub or `allowed_signers`.** GitHub re-checks the "Verified" badge against the *current* set of signing keys on every page load. Removing a retired pubkey would instantly mark every commit signed with it as "Unverified."

GitHub signing keys (`gh api /user/ssh_signing_keys`) currently has:
- `arch sign` (ed25519, retired pre-YubiKey, kept for past-commit verification)
- `yubikey git-signing` (sk-ed25519, retired verify-required era, kept for 2026-05-02 → 2026-05-11 commits)
- `yubikey git-signing-touch` (sk-ed25519, current)

Signing path bypasses ssh-agent entirely: git invokes `ssh-keygen -Y sign -f ~/.ssh/git_signing_touch` which talks to the YubiKey through libfido2. `SSH_AUTH_SOCK` is irrelevant here. The hardware boundary (touch required per signature) is the load-bearing property.

Backup YubiKey: not yet enrolled. Until then, losing the YubiKey means losing the ability to sign new commits until a replacement is provisioned and added to GitHub + `allowed_signers`.

#### Policy: touch-only, not PIN+touch

The original signing key (2026-05-02 to 2026-05-11) used `-O verify-required`, forcing PIN+touch per signature. **This proved untenable for rebases**: a 30-commit rebase meant 30 PIN entries. Investigated whether OpenSSH's `ssh-agent` caches the FIDO2 `pinUvAuthToken` across signature requests to amortize the PIN — it does not, in current OpenSSH. The agent stores the key handle but re-runs UV (PIN+touch) on every sign call.

Tried building infrastructure around this (`signed-rebase` wrapper, `ssh-keygen-git-sign` shim that injects `-U`, custom askpass) — none of it worked, because the bottleneck is the YubiKey enforcing UV on the credential, not the agent. The only fix is to drop `verify-required` on the credential itself.

**Threat-model delta:** with PIN+touch, an attacker with code execution as `aokellermann` could not forge a commit signature even with the YubiKey plugged in — they'd lack the PIN. With touch-only, an attacker who can time their request precisely with a legitimate touch the user is about to perform could conceivably forge one signature per legit touch. In practice: still a hardware boundary, still requires physical presence at the keyboard, just no second factor. For a single-user developer laptop, accepted.

If signing ever needs to be PIN-protected again (e.g. shared workstation, higher-assurance project), regenerate with `-O verify-required` and accept the rebase friction, OR move to a different signing mechanism that supports proper session caching (e.g. GPG with `gpg-agent` cache, though that loses hardware binding unless paired with smartcard).

Do not propose re-adding `verify-required`, ssh-agent shenanigans, `ssh-keygen -U` wrappers, or custom askpass scripts for the signing key — that path was investigated and rejected.

### gh OAuth token

Stored in the system keyring (libsecret). Scope hygiene matters because the token is bearer-equivalent to anything within its scopes.

Daily-use scopes: `repo, read:org, gist, workflow`. `workflow` is included because Claude Code commits routinely touch `.github/workflows/`. Avoided: `admin:public_key`, `admin:ssh_signing_key`, `admin:org`, `delete_repo`.

Pattern for elevated work:
```sh
gh auth refresh -h github.com -s admin:ssh_signing_key   # add scope for one-off
# do the work
gh auth refresh -h github.com --reset-scopes -s repo,read:org,gist,workflow   # reset back
```

`--reset-scopes` rebuilds the token with exactly the listed scopes (replaces, not adds). Use it after any temporary scope grant — scopes accumulate silently otherwise.

No `[credential] helper` is configured in `~/.config/git/config` — removed because all git remotes are SSH (`Git operations protocol: ssh` per `gh auth status`), so the helper was never invoked. If an HTTPS clone is ever needed, git will prompt interactively rather than silently consult the keyring. The keyring's active gh consumer is `gh` itself, which uses libsecret directly regardless of git config.

`GIT_TERMINAL_PROMPT=0` is exported in `~/.bashrc` so HTTPS git auth fails immediately with `terminal prompts disabled` instead of prompting. Forces SSH usage. There is no git-config equivalent — this control is env-only.

### Generic secret storage: libsecret vs rbw

Decision rule for where a new credential lives:

- **libsecret (system keyring)** when the consuming tool has **first-class credential-helper plumbing** that talks to it natively — no glue script. Current consumers: `docker-credential-secretservice` (via `credsStore: secretservice` in `~/.docker/config.json`), Chromium/Brave/Signal "Safe Storage" master keys, `gh` OAuth token, Bitwarden Desktop session (when present).
- **rbw (Bitwarden vault)** for everything else — generic API keys (Airtable, OpenAI, etc.), secrets used from arbitrary scripts. Pull with `export FOO_API_KEY=$(rbw get foo-api-key)`. Store as a Login item (not Secure Note) so the password field is what `rbw get` returns by default; put rotation URL in URI, scope/creation-date in notes.

**Why:** libsecret has no clean shell ergonomic (`secret-tool lookup` requires inventing a schema per secret); rbw has no native integration with most apps. So the call splits on which side of the integration friction each secret sits on.

**Why not bws (Bitwarden Secrets Manager):** retired from this machine. The machine-account access-token model is designed for unattended/CI contexts and is *less* secure on a laptop than rbw — the token is a long-lived bearer credential ungated by any unlock prompt. For headless/server contexts (systemd unit, cron, second machine) bws is appropriate; for an interactive workstation it isn't.

### Container registry credentials

Docker Hub auth uses a **Personal Access Token**, never the account password. Stored in libsecret via `credsStore: secretservice`. PAT requirements:

- Scoped to the minimum needed (Public Repo Read-only for pull, Read & Write for push). Never Admin.
- Named per device (so it can be revoked individually without disrupting other machines).
- Expiring (1y max). Rotate via https://app.docker.com/settings/personal-access-tokens.

ECR auth handled by `aws-vault exec <profile> -- docker ...` flowing through `docker-credential-ecr-login` or transient `aws ecr get-login-password` — short-lived STS-derived, no long-lived secret in the keyring.

**SSH key auth is not an option for container registries.** OCI distribution spec is HTTPS-only (Basic auth or OAuth Bearer); there is no SSH transport. Don't propose SSH-key alternatives for Docker Hub, ECR, GHCR, GCR, etc. The closest workaround is a credential helper that fetches the PAT from `rbw` per call (sketched but not implemented — adds latency and breaks when rbw-agent is locked).

### SSH config hardening

`~/.ssh/config` global block:
```
AddKeysToAgent yes
IdentitiesOnly yes
HashKnownHosts yes
```

- `IdentitiesOnly yes` + per-host `IdentityFile` means ssh offers only the named key to each host. Without this, ssh-agent enumerates *every* loaded key to *every* server you connect to, leaking pubkey existence to each.
- `HashKnownHosts yes` hashes new entries in `~/.ssh/known_hosts` so a leak of that file doesn't enumerate your server inventory. To rehash the existing file: `ssh-keygen -H -f ~/.ssh/known_hosts && rm -f ~/.ssh/known_hosts.old`.
- `ControlMaster auto` + `ControlPath ~/.ssh/cm-%r@%h:%p` + `ControlPersist 8h` enables ssh connection multiplexing. First connection to a host opens a master socket; subsequent connections within 8h reuse it without re-authenticating. Critical for sk (YubiKey) auth keys — without multiplexing, every `git fetch` would require a fresh touch. With it, one touch per ~workday. Stale sockets (from killed masters) are harmless; `rm ~/.ssh/cm-*` to clean.

`ForwardAgent yes` was **removed** from all hosts (was on runpod, lambda, imbue, cais, uiuc). Agent forwarding extends a remote-host compromise into a full credential compromise: anyone with root on the remote can use the forwarded socket to authenticate as the user to GitHub or any other ssh host. Especially dangerous with rbw-agent holding all service keys. If a workflow ever needs to push to GitHub from a cloud box, prefer a per-host deploy key (limited to one repo) over re-enabling agent forwarding. For ssh chaining, use `ProxyJump` instead.

`StrictHostKeyChecking no` + `UserKnownHostsFile /dev/null` is intentionally retained on `runpod` and `lambda` because their host keys cycle across instances. Don't "fix" this to `accept-new` without confirming the hosts are stable — first-connect TOFU breaks when the next instance presents a different key.

The `IdentityFile` entries point at `.pub` files (e.g. `~/.ssh/github.pub`). For `IdentitiesOnly yes` to work with an agent that holds the private key, ssh uses the pubkey as a *selector* — there are no private key bytes on disk for these; the actual material lives in rbw.

### Not done (deliberate)

- **Auth-side YubiKey migration.** Each remote service (lambda, runpod, etc.) would need its `authorized_keys` rotated. Cost-benefit doesn't pencil out vs. the symmetry argument; the high-value signing path is already protected.
- **`lock_timeout = 0`** for rbw (force pinentry per use). Would prompt on every git fetch / ssh into a server. Rejected as friction not worth the marginal benefit given infrequent threat.
- **Fine-grained PATs instead of OAuth for `gh`.** Would scope down per-repo, but `gh` CLI assumes classic-OAuth shapes for some commands. Not worth the breakage for a personal account.

## CPU vulnerabilities

Lunar Lake (Core Ultra 7 258V) is "Not affected" for: L1TF, MDS, Meltdown, TSX Async Abort, SRBDS, Retbleed, MMIO Stale Data, GDS, RFDS, Ghostwrite, Spec RStack Overflow, TSA, ITLB Multihit. Mitigated: Spectre v1/v2, Spec Store Bypass, VMScape. No action needed beyond keeping `intel-ucode` updated.

## Diagnostic recipes

```bash
# Lynis audit
sudo lynis audit system

# Check AIDE integrity
sudo aide --check

# Vulnerable packages
arch-audit

# Open ports
ss -lpntu | grep LISTEN

# SUID files
find /usr -perm /u=s -type f

# Audit log
ausearch -m avc -ts recent
```
