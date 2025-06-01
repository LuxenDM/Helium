# 📘 Helium Interface Library – Quick API Reference (v1.0.0)
**Helium's library is obtained through your LME provider. Use `lib.get_class("helium", "<version>")` to obtain the class table**

---

## ⚙️ Utility Functions (`helium.util`)
**Helpers for layout, sizing, and object management**

| Function | Description |
|----------|-------------|
| `map_dialog(iup_handle)` | Recursively triggers `map_cb` on all children |
| `index_container(iup_handle)` | Returns table of all valid children |
| `iup_prepend(root, child)` | Moves child to top of container |
| `iup_insert(root, child, index)` | Inserts child at position in container |
| `is_iup(obj)` | Failsafe IUP handle checker (kept for historical reasons, use iup.IsValid) |
| `get_mouse_abs_pos(xoff, yoff)` | Gets absolute mouse position from normalized coords |
| `scale_size(val, default)` | Scales number using `Font.Default` |
| `scale_2x(x, y, default)` | Returns `"WxH"` string from scaled dimensions |
| `iter_nums_from_string("WxH")` | Parses size string into `{w, h}` table |

---

## 🕒 Async Functions (`helium.async`)
**Non-blocking variants of utility functions**

| Function | Description |
|----------|-------------|
| `index_container(root, on_complete)` | Async version of `.util.index_container` |
| `map_dialog(dialog, on_complete)` | Async version of `.util.map_dialog` |
| `prepend(root, obj, on_complete)` | Async version of `.util.iup_prepend` |
| `insert(root, obj, index, on_complete)` | Async version of `.util.iup_insert` |
| `tween_value(from, to, ms, cb, ease)` | Tween from one value to another over time with ease-in-out |

---

## 🔧 Primitive Elements (`helium.primitives`)
**Single IUP elements with optional enhancements**

| Function | Description |
|----------|-------------|
| `clearframe(t)` | Transparent frame preset |
| `borderframe(t)` | Frame preset with a narrow border |
| `solidframe(t)` | Frame preset with a fully opaque background |
| `progress_bar(t)` | Wrapper for IUP progress bar with sane default values |
| `hslider(t)` / `vslider(t)` | Directional sliders, `value` in 0–100 |
| `cycle_button(t)` | Click-to-cycle button through string list |

---

## 🧱 Constructed Elements (`helium.constructs`)
**Multi-element structures for layout and interaction**

### 📦 Containers and display
| Function | Description |
|----------|-------------|
| `bg_frame(t)` | Displays a background image behind an object or frame |
| `vexpandbox(t)` / `hexpandbox(t)` | drawer-style visibility controllers |
| `vscroll(t)` / `hscroll(t)` | Scrollable view area with auto scrollbar |
| `ascroll(t)` | Freely controlled viewport area |
| `shrink_label(t)` | Label that auto-fits to the width of text |

### 🔘 Selection and input
| Function | Description |
|----------|-------------|
| `hbuttonlist(t)` / `vbuttonlist(t)` | Auto-built toggleable button lists |
| `multi_button(t)` | cycled list iteration using button controls |
| `select_text(t)` / `link_text(t)` | Clickable text labels (hyperlink style supported) |
| `coverbutton(t)` / `coverbutton_complex(t)` | Overlay button for intercepting input on visual child |
| `ticker(t)` | Number entry box with up/down buttons |
| `slide_toggle(t)` | Image-based ON/OFF toggle |

### 🧲 Drag & Drop
| Function | Description |
|----------|-------------|
| `drag_item(t)` | Draggable item; supports `data`, `on_feedback`, `on_query`, `on_result`, `drag_visual` |
| `drag_target(t)` | Drop target; supports `accepted_types`, `on_enter`, `on_drop`, `on_leave` |

---

## 🪟 Dialog Presets (`helium.presets`)
**Full-window layouts for specifically built purposes**

| Function | Description |
|----------|-------------|
| `subdialog(t)` | creates a modal dialog with screen-edge awareness, used to make all other dialog presets |
| `context_menu(t)` | display an option list for input selection |
| `alert_box(t)` | single-label warning dialog |
| `choice_box(t)` | single-label selection dialog |
| `list_box(t)` | list selection dialog |
| `reader_box(t)` | large label dialog using a multiline |
| `input_box(t)` | user input dialog |

---

## 🧪 Widgets (`helium.widgets`) *(future)*
Custom reusable tools (e.g., clocks, numeric pads, calendars). *Coming soon.*

## 🖌️ Paint and color ('various') *(future)*
Constructs and preset dialogs for selecting paint indexes and RGB color. *Coming soon.*