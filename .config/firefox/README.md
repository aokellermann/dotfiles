# firefox

Adds dark background for new tabs and whatnot.

This directory isn't read by firefox, so you will have to manually configure:

1. Go to about:config and set toolkit.legacyUserProfileCustomizations.stylesheets to true.
2. Go to about:profiles and under Profile:default, click on Open Directory next to Root Directory.
3. Open a terminal at that location and run the following: `ln -s ~/.config/firefox/*`
