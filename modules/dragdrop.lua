local file_args = {...}

local public = file_args[1]
local private = file_args[2]
local config = file_args[3]

local he = {} --these go to constructs



--button to launch a dragable item.
--[[incorrect
he.drag_item = function(intable)
	assert(type(intable) == "table", "helium.drag_item expects a table")

	local default = {
		data = { text = "undefined" }, -- 'text' is required by VO drag system
		image = private.tryfile("solidbutton.png"),
		size = "32x32",
		drag_visual = public.primitives.clearframe {
			iup.label {
				title = "",
				image = private.tryfile("drag_item.png"),
				bgcolor = "255 255 255",
				size = "32x32",
			},
		},
		on_result = function(self, effect) end,
		on_feedback = function(self, effect) return 1 end,
		on_query = function(self, escape, keys) return iup.DRAG_DROP end,
	}

	-- Overwrite defaults with provided arguments
	for k, v in pairs(intable) do
		default[k] = v
	end

	-- Ensure required drag field exists
	if type(default.data) ~= "table" then
		private.cerr("helium.drag_item: 'data' must be a table")
		default.data = { text = "undefined" }
	elseif not default.data.text then
		private.cp("helium.drag_item: added missing 'text' field to drag data")
		default.data.text = "undefined"
	end
	
	if not iup.IsValid(default.drag_visual) then
		private.cerr("helium.drag_item: drag_visual element is not a valid iup object!")
	end

	-- Visual drag overlay (shown when dragging)
	local drag_overlay = iup.dialog {
		visible = "NO",
		topmost = "YES",
		border = "NO",
		menubox = "NO",
		resize = "NO",
		bgcolor = "0 0 0 0 *",
		default.drag_visual,
	}
	drag_overlay:map()

	-- Wrap user-provided content (if any)
	local drag_button = public.constructs.coverbutton_complex {
		action = function() end, -- placeholder action
		iup.label {
			title = "yarr",
		},
	}

	-- Drag callbacks
	drag_button.begindrag_cb = function(self)
		iup.DoDragDrop(default.data, self, iup.DROP_COPY + iup.DROP_MOVE)
	end

	drag_button.givefeedback_cb = function(self, effect)
		local result = default.on_feedback(self, effect)
		drag_overlay:showxy(gl.get_mouse_abs_pos(2, 2))
		drag_overlay.visible = "YES"
		return result or 1
	end

	drag_button.dragresult_cb = function(self, effect)
		drag_overlay:hide()
		drag_overlay.visible = "NO"
		default.on_result(self, effect)
	end

	drag_button.querycontinuedrag_cb = function(self, esc, keys)
		return default.on_query(self, esc, keys)
	end

	-- Optionally let the user update the drag data later
	drag_button.set_drag_data = function(self, new_data)
		if type(new_data) == "table" then
			default.data = new_data
			if not default.data.text then
				private.cp("helium.drag_item.set_drag_data: added missing 'text' field")
				default.data.text = "undefined"
			end
		else
			private.cerr("set_drag_data expected table, got " .. type(new_data))
		end
	end

	return drag_button
end

]]--

he.drag_item = function(intable)
	assert(type(intable) == "table", "drag_item expects a table")

	local default = {
		data = { text = "drag item", type = "generic" }, -- must include .text
		effects = iup.DROP_COPY + iup.DROP_MOVE,
		[1] = iup.label { title = "??" }, -- required visual element

		-- Optional, an iup element (label, vbox, etc) for the floating ghost. set to non-iup to skip, such as "NO" or false.
		drag_visual = public.primitives.clearframe {
			iup.label {
				title = "",
				image = private.tryfile("drag_item.png"),
				bgcolor = "255 255 255",
				size = "32x32",
			},
		},
		
		on_result = function(self, effect) end,
		on_feedback = function(self, effect) return 1 end,
		on_query = function(self, escape, keys) return iup.DRAG_DROP end,
	}

	for k, v in pairs(intable) do
		default[k] = v
	end
	
	assert(type(default.data) == "table" and default.data.text, "drag_item requires .data with a .text field")

	local drag_data = default.data
	local drag_overlay = nil

	-- If user provided a visual ghost, create an overlay dialog
	if iup.IsValid(default.drag_visual) then
		drag_overlay = iup.dialog {
			topmost = "YES",
			border = "NO",
			menubox = "NO",
			resize = "NO",
			bgcolor = "0 0 0 0 *",
			default.drag_visual,
		}
		drag_overlay:map()
	end

	-- Callbacks must be pre-set in default for coverbutton_complex to see them
	default.begindrag_cb = function(self)
		iup.DoDragDrop(drag_data, self, default.effects)
	end

	default.givefeedback_cb = function(self, effect)
		if drag_overlay then
			drag_overlay:showxy(public.util.get_mouse_abs_pos(2, 2))
		end
		if default.on_feedback then
			return default.on_feedback(self, effect) or 1
		end
		return 1
	end

	default.dragresult_cb = function(self, effect)
		if drag_overlay then
			drag_overlay:hide()
		end
		if default.on_result then
			default.on_result(self, effect)
		end
	end

	default.querycontinuedrag_cb = function(self, escape, keys)
		if default.on_query then
			return default.on_query(self, escape, keys) or iup.DRAG_OK
		end
		return iup.DRAG_OK
	end

	-- Create the actual draggable UI element
	local dragbox = public.constructs.coverbutton_complex(default)

	-- Optional helper to update drag data at runtime
	dragbox.set_drag_data = function(self, new_data)
		if type(new_data) == "table" and new_data.text then
			drag_data = new_data
		end
	end

	return dragbox
end






--panel to accept dragged items
--[[incorrect
he.drag_target = function(intable)
	assert(type(intable) == "table", "helium.drag_target expects a table")

	local default = {
		accepted_types = nil,

		on_enter = function(self, data, x, y, keys, effect) end,
		on_over = function(self, data, x, y, keys, effect) end,
		on_drop = function(self, data, x, y, keys, effect) end,
		on_leave = function(self) end,
		on_cancel = function(self, data, x, y, keys, effect) end,

		on_state = function(self, state, ...) end,

		highlite = "YES",
		[1] = iup.vbox {},
	}

	for k, v in pairs(intable) do
		default[k] = v
	end

	local target = public.constructs.coverbutton_complex {
		highlite = default.highlite,
		action = function() end,
		default[1],
	}

	-- Default fallback data
	target.last_drag_data = { type = "empty", text = "no drag data available" }

	local function is_accepted(data)
		if not default.accepted_types or type(data) ~= "table" then
			return true
		end
		if type(data.type) ~= "string" then return false end
		for _, t in ipairs(default.accepted_types) do
			if data.type == t then return true end
		end
		return false
	end

	target.dragenter_cb = function(self, data, x, y, keys, effect)
		self.last_drag_data = data or { type = "empty", text = "no drag data available" }
		if is_accepted(data) then
			default.on_state(self, "entered", data, x, y, keys, effect)
			default.on_enter(self, data, x, y, keys, effect)
			return iup.DROP_MOVE
		else
			default.on_state(self, "canceled", data, x, y, keys, effect)
			default.on_cancel(self, data, x, y, keys, effect)
			return iup.DROP_NONE
		end
	end

	target.dragover_cb = function(self, x, y, keys, effect)
		default.on_state(self, "over", self.last_drag_data, x, y, keys, effect)
		default.on_over(self, self.last_drag_data, x, y, keys, effect)
		return iup.DROP_MOVE
	end

	target.dragleave_cb = function(self)
		default.on_state(self, "left", self.last_drag_data)
		default.on_leave(self)
	end

	target.drop_cb = function(self, data, x, y, keys, effect)
		self.last_drag_data = data or { type = "empty", text = "no drag data available" }
		if is_accepted(data) then
			default.on_state(self, "dropped", data, x, y, keys, effect)
			default.on_drop(self, data, x, y, keys, effect)
			return iup.DROP_MOVE
		else
			default.on_state(self, "canceled", data, x, y, keys, effect)
			default.on_cancel(self, data, x, y, keys, effect)
			return iup.DROP_NONE
		end
	end

	return target
end

]]--

he.drag_target = function(intable)
	assert(type(intable) == "table", "drag_target expects a table")

	local default = {
		accepted_types = {}, -- list of string types to accept
		on_enter = function(self, data, x, y, keys, effect) end,
		on_leave = function(self) end,
		on_drop = function(self, data, x, y, keys, effect) end,
		[1] = iup.label { title = "Drop here", expand = "YES" },
	}

	for k, v in pairs(intable) do
		default[k] = v
	end

	assert(iup.IsValid(default[1]), "drag_target requires a valid IUP object at [1]")
	assert(type(default.accepted_types) == "table", "drag_target requires accepted_types as a table")

	-- Track last drag data (optional, for debug/state)
	local last_drag_data = nil

	-- Generate the actual drop target
	local dropzone = public.constructs.coverbutton_complex {
		default[1],
		dragenter_cb = function(self, data, x, y, keys, effect)
			if type(data) ~= "table" or type(data.type) ~= "string" then return iup.DROP_NONE end

			-- Check if this drop target accepts the type
			for _, allowed_type in ipairs(default.accepted_types) do
				if data.type == allowed_type then
					last_drag_data = data
					default.on_enter(self, data, x, y, keys, effect)
					return iup.DROP_MOVE
				end
			end
			return iup.DROP_NONE
		end,

		dragleave_cb = function(self)
			last_drag_data = nil
			default.on_leave(self)
		end,

		dragover_cb = function(self, x, y, keys, effect)
			if last_drag_data then
				return iup.DROP_MOVE
			end
			return iup.DROP_NONE
		end,

		drop_cb = function(self, data, x, y, keys, effect)
			if last_drag_data then
				default.on_drop(self, data, x, y, keys, effect)
				last_drag_data = nil
				return iup.DROP_MOVE
			end
			return iup.DROP_NONE
		end
	}

	return dropzone
end





for k, v in pairs(he) do
	public.constructs[k] = v
end