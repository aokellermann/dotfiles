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

I like to store docker data in `/home/docker` so that is not on my root drive:

```sh
sudo mkdir -p /etc/docker
echo '{                     
    "data-root": "/home/docker"
}' | sudo tee /etc/docker/daemon.json
```

If you want to move data from your old docker location, you can `rsync` it over:
```sh
sudo rsync -avxP /var/lib/docker/ /home/docker
rm -rf /var/lib/docker/*
```

Clean up old directory:
```sh
rm -rf /var/lib/docker/*
```

## Credits

Other people's helpful dotfiles:
- [emersion](https://git.sr.ht/~emersion/dotfiles)
- [sircmpwn](https://git.sr.ht/~sircmpwn/dotfiles)
