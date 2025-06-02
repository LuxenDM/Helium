local file_args = {...}

local public = file_args[1]
local private = file_args[2]
local config = file_args[3]

local he = {} -->>public.construct._func()



--invisible button to cover selected object
he.coverbutton = function(intable)
	local default = {
		action = function(self) end,
		expand = "NO",
		highlite = "NO",
		[1] = iup.vbox { },
		size = nil,
	}
	
	for k, v in pairs(intable) do
		default[k] = v
	end
	
	local hlpane = public.primitives.highlite_panel()
	
	local cover = iup.button {
		title = "", 
		bgcolor = "0 0 0 0 *",
		expand = "YES",
		action = default.action,
		size = default.size,
		enterwindow_cb = function(self)
			hlpane:highlite()
		end,
		leavewindow_cb = function(self)
			hlpane:clear_highlite()
		end,
		destroy_cb = function()
			hlpane:destroy()
		end,
	}
	
	return iup.zbox {
		all = "YES",
		expand = default.expand,
		alignment = "ACENTER",
		--default.highlite == "YES" and hlpane or nil,
		default[1],
		cover,
	}
end



--invisible button to cover selected object, more keys get passed to the button (for drag and drop, or for other more complex situations)
he.coverbutton_complex = function(intable)
	local default = {
		action = function(self) end,
		expand = "NO",
		size = nil,
		[1] = iup.vbox { },
	}
	
	for k, v in pairs(intable) do
		default[k] = v
	end
	
	local zbox_keys = {
		expand = default.expand,
		alignment = default.alignment or "ACENTER",
	}
	
	default.title = ""
	default.expand = "YES"
	default.bgcolor = "0 0 0 0 *"
	
	local cover = iup.button(default)
	
	return iup.zbox {
		all = "YES",
		expand = zbox_keys.expand,
		alignment = zbox_keys.alignment,
		default[1],
		cover,
	}
end



--selectable_text uses a cover_button on top of a label. eventually will use frame/image properties to underline text maybe?
he.select_text = function(intable)
	local default = {
		title = "selectable text",
		action = function(self) end,
		font = Font.Default,
		fgcolor = nil,
		bgcolor = nil,
		highlite = "NO",
		size = nil,
	}
	
	for k, v in pairs(intable) do
		default[k] = v
	end
	
	local obj = he.coverbutton {
		action = default.action,
		highlite = default.highlite,
		size = default.size,
		iup.label {
			title = default.title,
			font = default.font,
			fgcolor = default.fgcolor,
			bgcolor = default.bgcolor,
		},
	}
	
	return obj
end

--preset select_text used for URLs
he.link_text = function(intable)
	local default = {
		title = "selectable url",
		url = "http://vendetta-online.com/",
		font = Font.Default,
		fgcolor = "128 0 255",
		bgcolor = nil,
		highlite = "YES",
		size = nil,
		link_image = private.tryfile("weblink.png"),
	}
	
	for k, v in pairs(intable) do
		default[k] = v
	end
	
	local linkimg = iup.label {
		title = "",
		image = default.link_image,
		size = tostring(default.font) .. "x" .. tostring(default.font),
	}
	
	local obj = he.coverbutton {
		action = function(self)
			Game.OpenWebBrowser(default.url or default.title)
		end,
		highlite = default.highlite,
		size = default.size,
		iup.hbox {
			iup.label {
				title = default.title,
				font = default.font,
				fgcolor = default.fgcolor,
				bgcolor = default.bgcolor,
			},
			(default.link_image ~= "NO" and linkimg) or nil,
		},
	}
	
	return obj
end



--numeric input 'spin dial'
he.ticker = function(intable)
	local default = {
		constrain = "YES", --limit to min/max if yes
		min = 0,
		max = 10,
		default = 0,
		readonly = "NO", --prevents text edits. buttons are active.
		active = "YES", --overrides readonly; prevents any changes
		action = function(self, value, caller) end,
		v_size = tostring(Font.Default),
		h_size = "200", --h_size of text control
	}
	
	for k, v in pairs(intable) do
		default[k] = v
	end
	
	local tickframe
	
	local update_val = function(input, mod, editor)
		mod = tonumber(mod) or 0
		input = (tonumber(input) or 0) + mod
		if default.constrain == "YES" then
			if input > default.max then
				input = default.max
			elseif input < default.min then
				input = default.min
			end
		end
		tickframe.value = tostring(input)
		default.action(tickframe, tickframe.value, editor)
	end
	
	local tickreader = iup.text {
		size = tostring(default.h_size) .. "x" .. tostring(tonumber(default.v_size)),
		value = default.default,
		readonly = (default.active == "NO" and "YES") or default.readonly,
		action = function(self)
			if tickframe.active == "NO" then
				self.value = tickframe.value
				return 
			end
			
			local raw = string.match(self.value, "-?%d+%.?%d*")
			local parsed = tonumber(raw)

			if not parsed then
				-- Revert to last valid value if input is unusable
				self.value = tickframe.value
				return
			end

			-- Apply and update
			update_val(parsed, 0, "edit")

			-- If input does not reflect final computed value, sync it
			if tonumber(self.value) ~= tonumber(tickframe.value) then
				self.value = tickframe.value
			end
		end,
	}
	
	local uptick = iup.stationbutton {
		title = "+",
		size = tostring(default.v_size) .. "x" .. tostring(tonumber(default.v_size / 2)),
		active = default.active,
		action = function()
			if tickframe.active == "NO" then return end
			
			update_val(tickframe.value, 1, "up")
			tickreader.value = tickframe.value
		end,
	}
	
	local downtick = iup.stationbutton {
		title = "-",
		size = tostring(default.v_size) .. "x" .. tostring(tonumber(default.v_size / 2)),
		active = default.active,
		action = function()
			if tickframe.active == "NO" then return end
			
			update_val(tickframe.value, -1, "down")
			tickreader.value = tickframe.value
		end,
	}
	
	tickframe = public.primitives.borderframe {
		value = tostring(default.default),
		active = default.active,
		iup.hbox {
			tickreader,
			iup.vbox {
				uptick,
				downtick,
			},
		},
		value = default.default,
	}
	
	return tickframe
end



--mobile-style slide toggle control
he.slide_toggle = function(intable)
	assert(type(intable) == "table", "helium.slide_toggle expects a table")

	local default = {
		value = "NO",
		active = "YES",

		image_off = private.tryfile("slide_off.png"),
		image_on  = private.tryfile("slide_on.png"),
		--image_off_inactive = private.tryfile("slide_off_in.png")
		--image_on_inactive  = private.tryfile("slide_on_in.png")

		size = tostring(Font.Default * 2) .. "x" .. tostring(Font.Default),
		action = function(self, value) end,
		highlite = "YES",
	}

	for k, v in pairs(intable) do
		default[k] = v
	end

	local img = iup.label {
		title = "",
		image = (default.value == "YES") and default.image_on or default.image_off,
		size = default.size,
		--bgcolor = "0 0 0  *",
	}
	
	local toggle_container
	toggle_container = public.constructs.coverbutton {
		highlite = default.highlite,
		action = function(self)
			if toggle_container.active == "NO" then
				return
			end
			if img.value == "YES" then
				img.value = "NO"
				img.image = default.image_off
			else
				img.value = "YES"
				img.image = default.image_on
			end
			default.action(self, img.value)
		end,
		img
	}
	
	toggle_container.active = default.active
	toggle_container.set_active = function(self, active_value)
		toggle_container.active = ((active_value == "YES" or active_value == "NO") and active_value) or (toggle_container.active == "YES" and "NO") or ("YES")
		--change image to match active state
	end

	-- Expose helper functions
	toggle_container.set_value = function(self, val)
		if val == "YES" then
			img.value = "YES"
			img.image = default.image_on
		elseif val == "NO" then
			img.value = "NO"
			img.image = default.image_off
		end
	end

	toggle_container.get_value = function(self)
		return img.value
	end

	return toggle_container
end




--triple-button list navigator with an activator
he.multi_button = function(intable)
	local default = {
		button_provider = iup.stationbutton,
		action = function(nav_frame, new_value, nav_effect) end,
		default = 1,
		[1] = "NULL",
	}
	local current_position = default.default
	local longest_entry = ""

	for k, v in pairs(intable) do
		default[k] = v
		if type(k) == "number" and string.len(v) > string.len(longest_entry) then
			longest_entry = v
		end
	end
	
	local nav_frame
	
	local main_button = default.button_provider {
		title = longest_entry, --set to longest; reset to default value at map
		map_cb = function(self)
			self.size = tostring(self.w) .. "x" .. tostring(self.h)
			self.title = default[current_position]
		end,
		action = function(self)
			if nav_frame.active == "NO" then return end
			default.action(nav_frame, default[current_position], "_select")
		end,
	}

	local select_next = default.button_provider {
		title = ">",
		action = function(self)
			if nav_frame.active == "NO" then return end
			current_position = current_position + 1
			if current_position > #default then
				current_position = 1
			end
			main_button.title = default[current_position]
			nav_frame.value = default[current_position]
			nav_frame.index = current_position
			default.action(nav_frame, default[current_position], "_next")
		end,
	}

	local select_prev = default.button_provider {
		title = "<",
		action = function(self)
			if nav_frame.active == "NO" then return end
			current_position = current_position - 1
			if current_position < 1 then
				current_position = #default
			end
			main_button.title = default[current_position]
			nav_frame.value = default[current_position]
			nav_frame.index = current_position
			default.action(nav_frame, default[current_position], "_prev")
		end,
	}

	nav_frame = public.primitives.clearframe {
		size = default.size,
		value = default[current_position],
		index = current_position,
		active = default.active,
		iup.hbox {
			select_prev,
			main_button,
			select_next,
		},
		
		set_active = function(self, active_value)
			self.active = ((active_value == "YES" or active_value == "NO") and active_value) or (self.active == "YES" and "NO") or ("YES")
			
			select_next.active = self.active
			main_button.active = self.active
			select_prev.active = self.active
		end,
		get_list = function(self)
			local items = {}
			for k, v in ipairs(default) do
				items[k] = v
			end

			return items
		end,
		set_list = function(self, new_table)
			for i=#default, 1, -1 do
				default[i] = nil
			end
			for i, v in ipairs(new_table) do
				default[i] = v
			end
			current_position = 1
			self.index = current_position
			main_button.title = default[current_position]
			self.value = default[current_position]
			default.action(self, default[current_position], "_reset")
		end,
		get_index = function(self)
			return current_position
		end,
		set_index = function(self, new_index)
			if new_index > #default then
				new_index = #default
			end
			if new_index < 1 then
				new_index = 1
			end
			current_position = new_index
			self.index = current_position
			main_button.title = default[current_position]
			self.value = default[current_position]
			default.action(self, default[current_position], "_set")
		end,
	}

	return nav_frame
end



he.radio_collect = function()
	private.cerr("radio_collect is a stub")
end



--background element for visible object
he.bg_frame = function(intable)
	local defaults = {
		image = "",
		iup.vbox { },
	}
	
	for k, v in pairs(intable) do
		defaults[k] = v
	end

	local image_panel = iup.label {
		title = "",
		image = defaults.image,
	}
	defaults.image = nil
	
	defaults[1] = public.primitives.clearframe(default)

	local control_frame = public.primitives.clearframe {
		map_cb = function(self)
			self.size = tostring(defaults[1].w) .. "x" .. tostring(defaults[1].h)
			image_panel.size = self.size
			iup.Refresh(self)
		end,
		iup.zbox {
			all = "YES",
			image_panel,
			defaults[1],
		},
	}

	return control_frame
end



he.shrink_label = function(intable)
	assert(type(intable) == "table", "helium.shrink_label expects a table")

	local default = {
		title = "Placeholder text",
	}

	for k, v in pairs(intable) do
		default[k] = v
	end

	local label = iup.label {
		title = "", --default.title,
		expand = "YES",
		font = default.font,
		alignment = default.alignment or "ALEFT",
		wordwrap = "YES",
	}

	local wrapper = public.primitives.clearframe {
		expand = default.expand or "HORIZONTAL",
		label,
	}

	wrapper.map_cb = function(self)
		local frame_w = tonumber(wrapper.w) or 0
		local label_w = tonumber(label.w) or 0
		label.size = tostring(frame_w) .. "x"
		label.wordwrap = "YES"
		label.title = default.title
		iup.Refresh(label)
	end

	return wrapper
end




public.constructs = he
