Any details listed here are intended to be revisited after public release v1.0.0; nothing defined in this document is guaranteed.

# radial menus
One part of the initial concepting phase included investigations into creating a 'radial' menu - a series of options listed in a circle on the screen, as a preset dialog. Primary tests were promising, but issues with centering and ordering objects reliably paused work. Original inspirations came from emote and team communications menus in Overwatch
Things to investigate:
 - determine altenrative view modes to show when user's display is too small for the radial menu
 - radial menus do not work well when displaying large amounts of text
 - consider limiting menu to some amount of options?
 - radial-depth could be defined, but consider making this a %% to screen edge?
 - make joystick friendly

# auto-wrapping labels
Originally defined in the indev phase but never actualized was an auto-wordwrapping text element. iup.label supports the wordwrap attribute, but only works when size is explicitly defined. the helium module's "shrinkwrapped" label would automatically wordwrap if neccesary; for instance, on map, if the width of the label was greater than the size of its containing frame, set the wordwrap flag and refresh.

# custom keyboard
Toyed with but never making it into even the indev phase, helium could provide custom on-focus functions to generate a custom keybaord with advanced macro support, command auto-completion, and easy access to copying and/or pasting from clipboard.
