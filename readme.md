Helium is an interface control and generation library for use in Vendetta Online. It is a distributable library, intended to be included with other plugins as a sub-module and loaded via the LME provider. On its own, this library will not do anything, but can greatly assist in the construction of interfaces used in other plugins.

Some of the features Helium provides include:
- Scrolling frames, without the use of a control list or iup.matrix element
- iup.map() wrapper which calls all defined map_cb elements in the dialog tree
- prepend and insert iup elements into existing iup trees
- simple scaling functions to keep interfaces consistent across multiple resolutions (and maybe aspect ratios someday!)
- preset primitive elements for easier access
- common gui elements such as a spin dial, multi-select button, mobile-style toggle switches, and simple color access dialog
- basic asynchronous editions of certain utility functions



Roadmap:
[x] indev: [complete] concepting and exploration of functionality
[ ] dev: [in-progress ] construction of intended release functionality
[ ] alpha: [upcoming] refining release functionality, limited release
[ ] beta: [upcoming] public release, bug hunting
[ ] release: [upcoming] public release as intended

For the intended API, please see ``API Tracker.txt``
For explored ideas that didn't make the cut for v1.0.0, please see ``post-release development ideas.txt``
