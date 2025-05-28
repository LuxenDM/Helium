local file_args = {...}

local public = file_args[1]
local private = file_args[2]
local config = file_args[3]

local he = {} --these go to constructs



--button to launch a dragable item.
he.drag_item = function(intable)
	assert(type(intable) == "table", "helium.drag_item expects a table")

	local default = {
		data = { text = "undefined" }, -- 'text' is required by VO drag system
		image = private.tryfile("solidbutton.png"),
		size = "32x32",
		drag_visual = public.primitives.clearframe {
			iup.label {
				title = "",
				image = private.tryfile("solidbutton.png"),
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
	local drag_button = public.constructs.coverbutton {
		action = function() end, -- placeholder action
		iup.label {
			image = default.image,
			title = "",
			size = default.size,
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




--panel to accept dragged items
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

	local target = he.constructs.coverbutton {
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




for k, v in pairs(he) do
	public.constructs[k] = v
end