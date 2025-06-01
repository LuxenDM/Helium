This is as much a wishlist as it is future design goals

# radial menus
One part of the initial concepting phase included investigations into creating a 'radial' menu - a series of options listed in a circle on the screen, as a preset dialog. Primary tests were promising, but issues with centering and ordering objects reliably paused work. Original inspirations came from emote and team communications menus in Overwatch
Things to investigate:
 - determine alternative view modes to show when user's display is too small for the radial menu
 - radial menus do not work well when displaying large amounts of text
 - consider limiting menu to some amount of options?
 - radial-depth could be defined, but consider making this a %% to screen edge?
 - make joystick friendly

# custom keyboard
Toyed with but never making it into even the indev phase, helium could provide custom on-focus functions to generate a custom keybaord with advanced macro support, command auto-completion, and easy access to copying and/or pasting from clipboard.

# better mobile-friendly controls
for starters, scrollbars that we can control internal primitives of would be great, as scrollbars may be too narrow on high DPI screens with a low font scaling. Additionally, gesture support for scrolling panels should be investigated.

# charts/graphs/plots
More of a wishlist item than anything actually investigated at this time, but wouldn't that be cool? Gotta figure how to create a frame and set specific plot points within it, then scale an image so it appears like a line, bar, or other chart methods.

# radio collection
I really disliked iup's radio collection system back when trying to use it. If I revisit and continue to dislike it, i'll add my own edition (you'll notice there is a stub in constructs_misc.lua)

# paint and color
This feature was intended for v1.0.0, but has been delayed. 

### helium.constructs.paint_panel
Creates a single color thumbnail with a click action and can also be dragged from with a colored paint bucket feedback image.
This panel accepts a single number as a ship color index.

### helium.constructs.color_panel
Creates a single color thumbnail with a click action and can also be dragged from with a colored paint bucket feedback image.
This panel accepts an RGB or Hex string as color input. Output cannot be used for ship paint.

### helium.constructs.paint_select
A full palette list for user selection. Each vertical column lists a general color, with indexes from light to dark.

### helium.constructs.color_select
Contains RGB color finding controls:
- RGB color sliders and input fields
- switch between hex and dec values

### helium.presets.color_picker
A custom dialog that allows the user to select from a palette list, recent selections, or use a color finder.
if called from a paint_select (or configured by caller), color finder tools are hidden and deactivated.
Recent selections contains the eight most recent colors selected (this session)

# widgets
Parts of this feature were intended for v1.0.0 but has been delayed. Others may be further out.

End-result items used for single-function purpose that don't fit in other categories are kept in the widgets table.

### helium.widgets.clock
A preset clock widget with timezone selection and 12/24 hour display.

### helium.widgets.stopwatch
A preset stopwatch widget. action returns either ``_start`` or ``_stop, <time in ms>``.

### helium.widgets.numpad
A preset number pad entry widget

### helium.widgets.keyboard
A miniature keyboard that can be embedded directly into an interface, or opens the full helium keyboard dialog

### helium.widgets.input_pad
A dedicated mousepad-like object for accepting user input.

### helium.widgets.joypad
A dedicated analog-stick visualization for accepting user input

### helium.widgets.joybutton
A dedicated digital button visualization for accepting user input

### helium.widgets.joycontroller
A dedicated simulation of a game controller for accepting user input
The intention here is to help with making joystick action mapping easier, though could be used for other things. The joycontroller combines joypads and joybuttons with a visual skin.

### helium.widgets.level_select
A scrollbar-esque object, drag a bar within a region to select a value. think of a color or shade selector within gimp.

### helium.widgets.marquee_text
A preset label display that scrolls its contents.

### helium.widgets.marquee_obj
A preset display that scrolls its contents.