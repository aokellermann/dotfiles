# dotfiles

My personal dotfiles for [swaywm](https://swaywm.org/) on [Arch Linux](https://archlinux.org/).

## Usage

Sway should be started from TTY with `runsway`, which will add some helpful environment variables.

## Installation

### Firefox

1. Install `firefox-user-autoconfig` from AUR.
2. Go to `about:profiles` and under `Profile:default`, click on Open Directory next to Root Directory.
3. Open a terminal at that location and run the following: `ln -s ../chrome`

### Encryption (LUKS)

Archinstall should be able to encrypt your root + other partitions. In case you want to encrypt a new partition:

```sh
# format + key the partition
cryptsetup luksFormat /dev/nvme0n1p4
cryptsetup luksOpen /dev/nvme0n1p4 nvme0n1p4_crypt

# add a filesystem of your choosing
mkfs.xfs -f /dev/mapper/nvme0n1p4_crypt
```

Make sure that the partition table knows it's encrypted:

```sh
sudo gdisk /dev/nvme0n1
# press t (to change partition type code), 4 (for the 4th partition), 8309 (short hex code for generic Linux LUKS), w (to write to partition table), Y (to confirm)
```

To automatically unlock it on decrypting your root partition:

```sh
# create a key
dd if=/dev/urandom of=/etc/cryptsetup-keys.d/ainstnvme0n1p4.key bs=512 count=1
chmod 400 /etc/cryptsetup-keys.d/ainstnvme0n1p4.key

# allow the partition to be unlocked by the key in addition to password
cryptsetup luksAddKey /dev/nvme0n1p4 /etc/cryptsetup-keys.d/ainstnvme0n1p4.key

# tell systemd which key to use
# no-read-workqueue,no-write-workqueue are performance optimizations for SSDs: https://wiki.archlinux.org/title/Dm-crypt/Specialties#Disable_workqueue_for_increased_solid_state_drive_(SSD)_performance
echo xfs /dev/nvme0n1p4 /etc/cryptsetup-keys.d/ainstnvme0n1p4.key luks,no-read-workqueue,no-write-workqueue >> /etc/crypttab
```

### Docker

I use [containerd image store](https://docs.docker.com/engine/storage/containerd/):

```sh
sudo mkdir -p /etc/docker
echo '{                     
    "features": {
        "containerd-snapshotter": true
    }
}' | sudo tee /etc/docker/daemon.json
```

and `/xfs` as image store directory. Set `root = '/xfs/containerd'` in `/etc/containerd/config.toml` and create a directory owned by root:

```sh
sudo mkdir /xfs/containerd
sudo chmod 755 /xfs/containerd
```

If you want to move data from your old location, you can `rsync` it over:
```sh
sudo rsync -avxP /var/lib/containerd/ /xfs/containerd
rm -rf /var/lib/containerd/*
```

Additionally, [systemd cgroup setting](https://kubernetes.io/docs/setup/production-environment/container-runtimes/#containerd-systemd) should be configured on cgroup v2 kernels:

```
[plugins.'io.containerd.cri.v1.runtime'.containerd.runtimes.runc.options]
    SystemdCgroup = true
```

XFS is one of the better options for image store. It's pretty optimal out of the box, but you can add `noatime,nodiratime` options to your `/etc/fstab`.

### Intel graphics

You can use the newer `xe` driver instead of the old `i915` driver. Find the hex code of your device:

```sh
lspci -nnd ::03xx
# 00:02.0 VGA compatible controller [0300]: Intel Corporation Lunar Lake [Intel Arc Graphics 130V / 140V] [8086:64a0] (rev 04)
```

The hex code above is `64a0`. Then, add the following to your kernel params (e.g. in `/boot/loader/entries/foo.conf`) and replace the nex code with yours: `i915.force_probe=!64a0 xe.force_probe=64a0`

## Credits

Other people's helpful dotfiles:
- [emersion](https://git.sr.ht/~emersion/dotfiles)
- [sircmpwn](https://git.sr.ht/~sircmpwn/dotfiles)
