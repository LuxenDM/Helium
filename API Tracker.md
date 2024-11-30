## Utility functions
Provides functions for operating on iup objects, but don't create iup objects themselves.

### helium.util.map_dialog
Similar to iup's :map(), but recursively activates all ``map_cb()`` functions in every child iup object. Many helium objects require this to render correctly.

``map_dialog(iup_handle) -> nil``
 - iup_handle: The iup object to be mapped

### helium.util.trigger_on_show
overrides the default show_cb behavior of a dialog to also call a specific child's show_cb function.
Doesn't iterate over all items like map_dialog for efficiency - large iup trees would be slow to iterate during showtime.
suggested to use within a map_dialog() if iup elements are not constructed at load times.

``trigger_on_show(iup_child, iup_root) -> nil``
 - iup_child: child iup element to be hooked to parent
 - iup_root: Parent dialog to hook show_cb function. If nil, assumes the root dialog of the child.

### helium.util.index_container
Iterates over an iup tree and returns the lua table equivilant. Intended for debugging use only.

``index_container(iup_handle) -> table_iup_tree``
- iup_handle: the iup object to be indexed
- table_iup_tree: lua table representing the iup object and its children.
  - children are numerically indexed. any 'containers' have an additional ``_type`` key


### helium.util.iup_prepend
Intended to behave like ``iup.Append()``, but the child is put before instead of after other children

``iup_prepend(iup_parent, iup_child) -> nil``
- iup_parent: parent to be modified
- iup_child: child to be added to parent

### helium.util.iup_insert
Intended to behave like ``iup.Append()``, but the child can be inserted at an arbitrary location

``iup_insert(iup_parent, iup_child, insertion_index) -> nil``
- iup_parent: parent to be modified
- iup_child: child to be added to parent
- insertion_index: where to add child to parent.
  - if negative, the index counts in reverse; ie -1 would add the child to the end of the parent, like how append() is used

### helium.util.is_iup
Behaves similarly to ``iup.IsValid()``, but only checks if the object is an iup element. doesn't test actual validity (has iup object been destroyed?)
This function has been kept for posterity, but iup's own function will perform better

``is_iup(iup_handle) -> status``
- iup_handle: iup object to test against
- status: boolean state true if provided an iup object, false otherwise

