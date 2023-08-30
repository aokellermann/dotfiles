# firefox

## Preferences

Install [firefox-user-autoconfig](https://github.com/aokellermann/firefox-user-autoconfig) which will allow `user.js` to be read.

## Dark background

Adds dark background for new tabs and whatnot.

Setup requires preferences to be read as described above (or just set toolkit.legacyUserProfileCustomizations.stylesheets to true). This directory isn't read by firefox, so you will have to manually configure:

1. Go to about:profiles and under Profile:default, click on Open Directory next to Root Directory.
2. Open a terminal at that location and run the following: `ln -s ~/.config/firefox/*`

