# texlive

## Installation

This texlive profile has the following features:
- defaults to letter
- installs to `/opt` rather than `/usr/local`
- configuration is set to `~/.config`
- `texmf` is hidden at `~/.texmf` instead of being in the middle of `$HOME`

Follow the steps [here](https://tug.org/texlive/quickinstall.html) to download `texlive`. To install using the profile provided here, run:

```sh
sudo perl ./install-tl --profile texlive.profile
```
