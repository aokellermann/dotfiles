# dotfiles

My personal dotfiles for [swaywm](https://swaywm.org/) on [Arch Linux](https://archlinux.org/).

## Usage

Sway should be started from TTY with `runsway`, which will add some helpful environment variables.

## Installation

### Firefox

1. Install `firefox-user-autoconfig` from AUR.
2. Go to `about:profiles` and under `Profile:default`, click on Open Directory next to Root Directory.
3. Open a terminal at that location and run the following: `ln -s ../chrome`

### Zen

1. Go to `about:profiles` and under `Profile:default (beta)`, click on Open Directory next to Root Directory.
2. Open a terminal at that location and run the following: `ln -s ../../userChrome.css chrome/userChrome.css`

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

and `/home/containerd` as image store directory:

Set `root = '/home/containerd'` in `/etc/containerd/config.toml` and create a home folder owned by root:

```sh
sudo mkdir /home/containerd
sudo chmod 755 /home/containerd
```

If you want to move data from your old docker location, you can `rsync` it over:
```sh
sudo rsync -avxP /var/lib/docker/ /home/containerd
rm -rf /var/lib/docker/*
```

Additionally, [systemd cgroup setting](https://kubernetes.io/docs/setup/production-environment/container-runtimes/#containerd-systemd) should be configured on cgroup v2 kernels:

```
[plugins.'io.containerd.cri.v1.runtime'.containerd.runtimes.runc.options]
    SystemdCgroup = true
```

## Credits

Other people's helpful dotfiles:
- [emersion](https://git.sr.ht/~emersion/dotfiles)
- [sircmpwn](https://git.sr.ht/~sircmpwn/dotfiles)
