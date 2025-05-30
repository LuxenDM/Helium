## Utility functions
Provides functions for operating on iup objects, but don't create iup objects themselves.

### helium.util.map_dialog
Similar to iup's :map(), but recursively activates all ``map_cb()`` functions in every child iup object. Many helium objects require this to render correctly.

``map_dialog(iup_handle) -> nil``
 - iup_handle: The iup object to be mapped

example:
```lua
helium.util.map_dialog(StationDialog)
```

### helium.util.trigger_on_show
*** This function has been delayed until Helium v1.1.x
overrides the default show_cb behavior of a dialog to also call a specific child's show_cb function.
Doesn't iterate over all items like map_dialog for efficiency - large iup trees would be slow to iterate during showtime.
suggested to use within a map_dialog() if iup elements are not constructed at load times.

``trigger_on_show(iup_child, iup_root) -> nil``
 - iup_child: child iup element to be hooked to parent
 - iup_root: Parent dialog to hook show_cb function. If nil, assumes the root dialog of the child.

example:
```lua
helium.util.trigger_on_show(tabrow, StationDialog)
```

### helium.util.index_container
Iterates over an iup tree and returns the lua table equivilant. Intended for debugging use only.

``index_container(iup_handle) -> table_iup_tree``
- iup_handle: the iup object to be indexed
- table_iup_tree: lua table representing the iup object and its children.
  - children are numerically indexed. any 'containers' have an additional ``_type`` key

example:
```lua
local station_map = helium.util.index_container(StationDialog)
```


### helium.util.iup_prepend
Intended to behave like ``iup.Append()``, but the child is put before instead of after other children

``iup_prepend(iup_parent, iup_child) -> nil``
- iup_parent: parent to be modified
- iup_child: child to be added to parent

example:
```lua
helium.util.iup_prepend(OptionsDialog[1], my_button)
```

### helium.util.iup_insert
Intended to behave like ``iup.Append()``, but the child can be inserted at an arbitrary location

``iup_insert(iup_parent, iup_child, insertion_index) -> nil``
- iup_parent: parent to be modified
- iup_child: child to be added to parent
- insertion_index: where to add child to parent.
  - if negative, the index counts in reverse; ie -1 would add the child to the end of the parent, like how append() is used

example:
```lua
helium.util.iup_prepend(OptionsDialog[1], my_button, 3)
```

### helium.util.is_iup
Behaves similarly to ``iup.IsValid()``, but only checks if the object is an iup element. doesn't test actual validity (has iup object been destroyed?)
This function has been kept for posterity, but iup's own function will perform better

``is_iup(iup_handle) -> status``
- iup_handle: iup object to test against
- status: boolean state true if provided an iup object, false otherwise

example:
```lua
print( "The StationDialog object " .. tostring( helium.util.is_iup(StationDialog) and "does" or "does not" ) .. " exist!" )
```

### helium.util.get_mouse_abs_pos
Retrieves the pixel coordinates of the mouse position. Used internally to place subdialogs.

``get_mouse_abs_pos(offset_x, offset_y) -> coord_x, coord_y``
- offset_x: Numeric pixel offset of the current mouse x position, can be nil
- offset_y: Numeric pixel offset of the current mouse y position, can be nil
- coord_x: Numeric x position of the mouse plus the offset
- coord_y: Numeric y position of the mouse plus the offset

example:
```lua
local mouse_x, mouse_y = helium.util.get_mouse_abs_pos()
```

### helium.util.scale_size
Using the known scaling value of Font.Default, applies a consistant scale to the provided value
Font.Default is set to a value based on the user's screen and scale factor, and is relatively accurate to keeping the value consistant regardless of the end user's display

``scale_size(input_value, expected_default) -> scaled_output_value``
- input_value: the numeric value to be scaled
- expected_default: The expected value of Font.Default as on the designer's computer. defaults to 24 if nil
- scaled_output_value: The modified input value after scaling

example:
```lua
local my_button = iup.button {
 title = "this",
 size = tostring(helium.util.scale_size(200, 24)) .. "x",
}
```

### helium.util.scale_2x
A preset function wrapper around scale_size to provide an iup size attribute's expected format.

``scale_2x(input_value_1, input_value_2, expected_default) -> scaled_output
- input_value_1: The first number to be scaled
- input_value_2: The second number to be scaled
- expected_default: The expected value of Font.Default
- scaled_output: modified values after scaling in the string format "<first>x<second>"

example:
```lua
local my_frame = iup.frame {
 size = helium.util.scale_2x(300, 200, 24),
 my_object,
}
```

### helium.util.iter_nums_from_string
A function to split numbers from a non-numerically delimited string, returned as a table
When used with an iup size attribute, returns the values {x, y}

``iter_nums_from_string(value) -> split_nums``
- value: string containing numbers delimited by a non-numeric value
- split_nums: table containing numbers within the string

example:
```lua
print("The size of StationDialog is " .. spickle( helium.util.iter_nums_from_string( StationDialog.size ) ) )
```

## Helium primitive objects
These provide preset singular iup objects for building basic interface objects with more easily.

### helium.primitives.clearframe
A frame preset with no image and no border; should be visually invisible.

``clearframe { <your frame attributes> } -> frame_object``
- <args>: All arguments are passed to iup.frame.
- frame_object: an ordinary iup.frame

If not provided, these are the default values used:
- image = "<helium library file path>/solidframe.png"
- bgcolor = "0 0 0 0 *"
- segmented = "0 0 1 1"
- iup.vbox { }
- expand = "NO"

### helium.primitives.solidframe
A frame preset with no border and a solid opaque background.
Other than a different image, all behavior is the same as clearframe

### helium.primitives.borderframe
A frame preset with a thin border.
Other than a different image and 'segmented' value, all behavior is the same as clearframe

### helium.primitives.highlite_panel
An image used internally for 'highlite on mouse hover' behavior.

### helium.primitives.progressbar
A set of basic preset values for an iup.progressbar

### helium.primitives.hslider
A horizontal scroll bar object

Normal behavior expects scroll_cb() to activate on scrollbar feedback. However, this occurs *every single frame* the scrollbar is being dragged, which can lag the client interface.
Instead, scroll_cb changes a value, and your function should be tied to the input key 'scroll_event_cb' which is called by a background timer.
This allows the slider to not detrimentally affect the client interface when a drag action occurs.

### helium.primitives.vslider
A vertical scroll bar object

### helium.primitives.cyclebutton
A button that changes its contents every press, cycling through indexed options.

## Helium Constructs
Constructs are functions that create multiple iup objects contained within a frame parent

### helium.constructs.hexpandbox
A frame-style object that operates like a horizontal 'drawer'; when open, the contents are seen. when closed, the contents are hidden.

### helium.constructs.vexpandbox
A frame-style object that operates like a vertical 'drawer'; when open, the contents are seen. when closed, the contents are hidden.

### helium.constructs.vscroll
A frame-style object that allows its contents to be scrolled vertically.
This does NOT rely on a 'control' list or iup.matrix

### helium.constructs.hscroll
A frame-style object that allows its contents to be scrolled horizontally.
This does NOT rely on an iup.matrix

### helium.constructs.ascroll
A frame style object that exposes scrolling mechanics as functions but provides no scrolling elements natively.
The preset vscroll/hscroll provide their own scroll bars and can be scrolled directly, but aren't set up to scroll both directions. 
This 'adaptive' scrolling panel is instead controlled by the caller to set the scrolling target.
Since bounds can be unlocked from the parent, this object should be considered more like a viewport to a seperate moveable surface.

### helium.constructs.hbuttonlist
A frame containing a horizontal list of buttons, intended for use as a tab row

### helium.constructs.vbuttonlist
A frame containing a vertical list of buttons, intended for use as a tab row

### helium.constructs.coverbutton
This hides an invisible button over the child element, providing on-click functionality to non-clickable objects and frames

### helium.constructs.select_text
A preset of coverbutton over a label element

### helium.constructs.link_text
A preset of select_text that mimics a hyperlink to open a webpage

### helium.constructs.ticker
Two buttons and a field for inputting and editing a numeric entry

### helium.constructs.slide_toggle
A "toggle" object that mimics the popular mobile switch style

### helium.constructs.multi_button
A three-button setup; two to navigate left and right through options, and a central button to activate the displayed item

### helium.constructs.radio_collect
A collection of linked toggle options that may be duplicate of existing iup.radio behavior, may be deprecated

### helium.constructs.bg_frame
Acts like a background element handler

### helium.constructs.shrink_label
Automatically wordwraps and shrinks horizontal size to fit containing element.

## Helium preset dialogs
Presets are full dialogs worth of items, with completely custom behaviors and purpose-built uses.

### helium.presets.subdialog
Creates a modal-style dialog that can be positioned on the screen (defaults to center). Position defined can be mapped to dialog corners or to dialog center.
If the position of a corner would be off-screen, the dialog is shifted to fit on screen.
Minimum size is a %THIRDx%THIRD, and contents are stored in a vscroll.
The dialog defaults to closing if the user 'clicks off', or this behavior can be blocked by the close callback.

### helium.presets.context_menu
Creates a preset of the subdialog that mimics the behavior of a single-layer context menu. the user's selection (or _close) is returned to the action callback.
By default, the position of a context menu is the current mouse position.

### helium.presets.alert
Creates a very simple subdialog at center screen to show the user a single message.

### helium.presets.reader
Creates a large subdialog for displaying a large amount of text in a multiline element.

...and more...

## Helium Drag-and-drop support
Helium provides these to create easy drag and drop functionality.

### helium.constructs.drag_item
Creates a transparent field above the target object. this has a drag behavior associated with it. Intended to be paired with a drag_target object.
The drag_item takes an iup object and a generator function, in addition to other table entries:
- The iup object is the visual target where a user begins dragging from
- The generator function recieves the iup object as an argument, and returns an iup object as a visual element of 'what' is being dragged
- any additional data is used to generate the field and its behaviors, or is passed to a drag_target on drop.

### helium.constructs.drag_target
Creates a transparent field above the target objects. this has a drop behavior associated with it. Intended to be paired with a drag_item object.

## helium paint and color support
Helium provides these to create easy methods to select both RGB and indexed ship colors. Delayed until Helium v1.1.x!

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

## Helium widgets
End-result items used for single-function purpose that don't fit in other categories are kept in the widgets table.

### helium.widgets.clock
A preset clock widget with timezone selection and 12/24 hour display.

### helium.widgets.stopwatch
A preset stopwatch widget. action returns either ``_start`` or ``_stop, <time in ms>``.

### helium.widgets.numpad
A preset number pad entry widget

### helium.widgets.marquee_text
A preset label display that scrolls its contents. Uses three labels to give the semblance of continuous scrolling

### helium.widgets.marquee_obj
A preset display that scrolls its contents. Must be provided with a generator to duplicate displayed contents.
