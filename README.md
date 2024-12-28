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

## Credits

Other people's helpful dotfiles:
- [emersion](https://git.sr.ht/~emersion/dotfiles)
- [sircmpwn](https://git.sr.ht/~sircmpwn/dotfiles)
