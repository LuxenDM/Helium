--[[
[metadata]
description=Various advanced frame container constructs for the helium library
version=1.0.0
owner=helium|1.1.1
type=lua
created=2025-06-01
]]--

local file_args = {...}

local public = file_args[1]
local private = file_args[2]
local config = file_args[3]

local he = {} -->>public.construct._func()





--cbox helper, expands the cbox to its parent (because cbox's expand = "YES" doesn't work all the time
he.autobox = function(intable)
	local default = {
		expand = "YES",
		[1] = iup.vbox {},
		cx = 0,
		cy = 0,
	}
	
	for k, v in pairs(intable) do
		default[k] = v
	end
	
	local cbox_children = {}
	--add from default
	for k, v in ipairs(default) do
		cbox_children[k] = public.primitives.clearframe {
			cx = v.cx or default.cx,
			cy = v.cy or default.cy,
			v,
		}
	end
	--clear from default
	for k, v in ipairs(cbox_children) do
		default[k] = nil
	end
	
	local imposter = public.primitives.clearframe {
		--used to get size of parent
		expand = "YES",
		iup.vbox {
			iup.hbox {
				iup.fill { },
			},
			iup.fill { },
		},
	}
	
	local cbox_area = iup.cbox (cbox_children)
	
	default[1] = iup.zbox {
		cbox_area,
		default.expand ~= "NO" and imposter or nil,
	}
		
	
	local root_frame = public.primitives.clearframe(default)
	root_frame.map_cb = function(self)
		local root = imposter
		local w = tostring(root.w)
		local h = tostring(root.h)
		cbox_area.size = w .. "x" .. h
		for k, v in ipairs(cbox_children) do
			v.size = w .. "x" .. h
		end
		iup.Refresh(self)
	end
	
	root_frame.cbox = cbox_area
	root_frame.cbox_children = cbox_children
	root_frame.imposter = imposter
	
	return root_frame
end

--a simple frame that can be expanded or shrank vertically; contents are stored and append/detached
he.vexpandbox = function(intable)
	local default = {
		state = "CLOSED",
		map_cb = nil,
		drawer_cb = function(self) end,
		[1] = iup.vbox {},
	}
	
	for k, v in pairs(intable) do
		default[k] = v
	end
	
	local vexpand
	local contents = iup.vbox {}
	local contents_table = {}
	
	for k, v in ipairs(default) do 
		table.insert(contents_table, v)
		if default.state == "OPEN" then
			contents:append(v)
		end
	end
	
	vexpand = public.primitives.clearframe {
		map_cb = default.map_cb,
		contents,
		state = default.state,
		get_obj_table = function(self)
			return contents_table
		end,
		drawer_toggle = function(self, new_state)
			if new_state == "OPEN" or new_state == "CLOSED" then
				self.state = new_state
			else
				self.state = self.state == "OPEN" and "CLOSED" or "OPEN"
			end
			
			if self.state == "CLOSED" then
				for k, v in ipairs(contents_table) do
					v:detach()
				end
			else
				for k, v in ipairs(contents_table) do
					contents:append(v)
				end
			end
			
			iup.Refresh(self)
			default.drawer_cb(self)
		end,
	}
	
	return vexpand
end



--a simple frame that can be expanded or shrank horizontally; contents are stored and append/detached
he.hexpandbox = function(intable)
	local default = {
		state = "CLOSED", --current state of drawer. closed is hidden.
		map_cb = nil,
		drawer_cb = function(self) end, --called after expand/contracting the drawer
		[1] = iup.hbox {},
	}
	
	for k, v in pairs(intable) do
		default[k] = v
	end
	
	local vexpand
	local contents = iup.hbox {}
	local contents_table = {}
	
	for k, v in ipairs(default) do 
		table.insert(contents_table, v)
		if default.state == "OPEN" then
			contents:append(v)
		end
	end
	
	hexpand = public.primitives.clearframe {
		map_cb = default.map_cb,
		contents,
		state = default.state,
		get_obj_table = function(self)
			return contents_table
		end,
		drawer_toggle = function(self, new_state)
			if new_state == "OPEN" or new_state == "CLOSED" then
				self.state = new_state
			else
				self.state = self.state == "OPEN" and "CLOSED" or "OPEN"
			end
			
			if self.state == "CLOSED" then
				for k, v in ipairs(contents_table) do
					v:detach()
				end
			else
				for k, v in ipairs(contents_table) do
					contents:append(v)
				end
			end
			
			iup.Refresh(self)
			default.drawer_cb(self)
		end,
	}
	
	return hexpand
end



he.vscroll = function(intable)
	local default = {
		expand = "YES",
		scrollbar = "YES",
		[1] = iup.vbox {},
	}

	for k, v in pairs(intable) do
		default[k] = v
	end

	local iup_element = default[1]
	default[1] = nil

	-- use autobox with one child: the scrollable element
	local ab = public.constructs.autobox {
		iup_element,
	}

	local scroller
	scroller = public.primitives.vslider {
		scroll_event_cb = function()
			local content = ab.cbox_children[1]
			content.cy = ((scroller:get_pos() * (content.h - scroller.h)) / 100) * -1
			iup.Refresh(content)
		end,
	}

	default[1] = iup.hbox {
		ab,
		scroller,
	}

	local root_frame = public.primitives.clearframe(default)

	root_frame.map_cb = function(self)
		if self.expand == "NO" then return end

		local w = ab.imposter.w
		local h = ab.imposter.h

		self.size = tostring(w) .. "x" .. tostring(h)
		scroller.size = tostring(Font.Default) .. "x" .. tostring(h)

		local content = ab.cbox_children[1]

		-- handle scrollbar logic
		local content_h = content.h
		local inner_w = w - Font.Default

		if default.scrollbar == "NO" or content_h < h then
			-- disable scrollbar if content fits
			scroller:detach()
			ab.cbox.size = w .. "x" .. h
			content.size = w .. "x" .. h
		else
			ab.cbox.size = inner_w .. "x" .. h
			content.size = inner_w .. "x" .. content_h
		end

		iup.Refresh(self)
	end

	-- same utility functions as before
	root_frame.get_position_percent = function()
		return scroller:get_pos()
	end

	root_frame.set_position_percent = function(self, percent)
		scroller:set_pos_percent(percent)
	end

	root_frame.move_to_position_percent = function(self, percent, duration)
		public.async.tween_value(scroller:get_pos(), percent, duration, function(val)
			scroller:set_pos_percent(val)
		end)
	end

	return root_frame
end




--a horizontally scrolling pane, which iup.list cannot do
he.hscroll = function(intable)
	local default = {
		expand = "YES",
		scrollbar = "YES",
		[1] = iup.hbox { },
	}
	
	for k, v in pairs(intable) do
		default[k] = v
	end
	
	local iup_element = default[1]
	default[1] = nil
	
	local ab = public.constructs.autobox {
		iup_element,
	}

	local scroller
	scroller = public.primitives.hslider {
		scroll_event_cb = function()
			local content = ab.cbox_children[1]
			content.cx = ((scroller:get_pos() * (content.w - scroller.w)) / 100) * -1
			iup.Refresh(content)
		end,
	}
	
	default[1] = iup.vbox {
		ab,
		scroller,
	}
	
	local root_frame = public.primitives.clearframe(default)
	
	root_frame.map_cb = function(self)
		if self.expand == "NO" then return end

		local w = ab.imposter.w
		local h = ab.imposter.h

		self.size = tostring(w) .. "x" .. tostring(h)
		scroller.size = tostring(w) .. "x" .. tostring(Font.Default)

		local content = ab.cbox_children[1]

		-- handle scrollbar logic
		local inner_h = h - Font.Default
		local content_w = content.w

		if default.scrollbar == "NO" or content_w < w then
			-- disable scrollbar if content fits
			scroller:detach()
			ab.cbox.size = w .. "x" .. h
			content.size = w .. "x" .. h
		else
			ab.cbox.size = w .. "x" .. inner_h
			content.size = content_w .. "x" .. inner_h
		end

		iup.Refresh(self)
	end
	
	-- Get vertical scroll position as display percent (0–100)
	root_frame.get_position_percent = function()
		return scroller:get_pos()
	end

	-- Instantly set vertical scroll to display percent (0–100)
	root_frame.set_position_percent = function(self, percent)
		scroller:set_pos_percent(percent)
	end

	-- Tween vertical scroll to display percent (0–100)
	root_frame.move_to_position_percent = function(self, percent, duration)
		public.async.tween_value(scroller:get_pos(), percent, duration, function(val)
			scroller:set_pos_percent(val)
		end)
	end
	
	return root_frame
end



--"attached panel viewport" - a freely scrolled panel in two directions.
he.ascroll = function(intable)
	local default = {
		expand = "YES",
		expand_child = "YES",
			--YES: expands both child content_frame and bounds to match cbox
			--CONTENT: expands only content_frame
			--BOUND: sets content_frame to match logical bounds
			--NO: no resizing. suggested to set own size.
		bound_match_override = "NO",
			--set yes if expand_child is not YES to update bounds seperately
			--occurs AFTER expand_child handling
		
		--percentage bounds of viewport
		xbound_min = -100,
		xbound_max = 100,
		ybound_min = -100,
		ybound_max = 100,
		
		[1] = iup.vbox { },
	}

	for k, v in pairs(intable) do
		default[k] = v
	end

	local iup_element = default[1]
	default[1] = nil

	local ab = public.constructs.autobox {
		iup_element,
	}

	default[1] = ab
		
	local child_obj = ab.cbox_children[1]
	
	local root_frame = public.primitives.clearframe(default)
	
	root_frame.map_cb = function(self)
		if default.expand == "NO" then return end
		
		local w = tonumber(ab.imposter.w) or tonumber(iup.GetParent(self).w) or 32
		local h = tonumber(ab.imposter.h) or tonumber(iup.GetParent(self).h) or 32

		local view_size = tostring(w) .. "x" .. tostring(h)
		self.size = view_size
		iup.Refresh(self)
		ab.cbox.size = view_size
		
		iup.Refresh(self)

		if default.expand_child == "NO" then return end

		if default.expand_child == "YES" then
			-- Resize both content and logical bounds to match viewport
			child_obj.size = view_size

			self.xbound_min = 0
			self.xbound_max = w
			self.ybound_min = 0
			self.ybound_max = h

		elseif default.expand_child == "CONTENT" then
			local content_w = tonumber(child_obj.w)
			local content_h = tonumber(child_obj.h)

			if content_w < w then content_w = w end
			if content_h < h then content_h = h end

			child_obj.size = tostring(content_w) .. "x" .. tostring(content_h)

		elseif default.expand_child == "BOUND" then
			local bw = self.xbound_max - self.xbound_min
			local bh = self.ybound_max - self.ybound_min

			child_obj.size = tostring(bw) .. "x" .. tostring(bh)
		end
		
		if default.bound_match_override == "YES" then
			self.xbound_min = 0
			self.xbound_max = w
			self.ybound_min = 0
			self.ybound_max = h
		end
		
		iup.Refresh(self)
	end
	
	root_frame.update_bounds = function(self, xmin, xmax, ymin, ymax)
		self.xbound_min = tonumber(xmin) or -100
		self.xbound_max = tonumber(xmax) or 100
		self.ybound_min = tonumber(ymin) or -100
		self.ybound_max = tonumber(ymax) or 100
	end

	
	-- Get scroll offset in raw coordinates
	root_frame.get_position = function()
		return child_obj.cx, child_obj.cy
	end

	-- Set scroll position in raw coordinates
	root_frame.set_position = function(self, target_x, target_y)
		child_obj.cx = tonumber(target_x) or child_obj.cx
		child_obj.cy = tonumber(target_y) or child_obj.cy
		iup.Refresh(self)
	end

	-- Tween scroll position in raw coordinates
	root_frame.move_to_position = function(self, target_x, target_y, time_to_tween)
		self.tween_id = (self.tween_id or 0) + 1
		local this_tween_id = self.tween_id
		local start_x = child_obj.cx
		local start_y = child_obj.cy
		local apply_tween = function(tween_x, tween_y)
			if self.tween_id ~= this_tween_id then return end
			child_obj.cx = tween_x or child_obj.cx
			child_obj.cy = tween_y or child_obj.cy
			iup.Refresh(self)
		end

		public.async.tween_value(start_x, target_x, time_to_tween, function(xval) apply_tween(xval, nil) end)
		public.async.tween_value(start_y, target_y, time_to_tween, function(yval) apply_tween(nil, yval) end)
	end

	-- Get scroll position as a percentage within logical bounds
	root_frame.get_position_percent = function()
		local px, py = child_obj.cx, child_obj.cy
		local bx = root_frame.xbound_max - root_frame.xbound_min
		local by = root_frame.ybound_max - root_frame.ybound_min

		-- Convert position to display percent (0–100)
		local cx = ((px / bx) + 0.5) * 100
		local cy = ((py / by) + 0.5) * 100

		return cx, cy
	end


	-- Set scroll position as a percentage relative to bounds (0.0 = top/left, 1.0 = bottom/right)
	root_frame.set_position_percent = function(self, percent_x, percent_y)
		local bx = root_frame.xbound_max - root_frame.xbound_min
		local by = root_frame.ybound_max - root_frame.ybound_min

		local px = ((tonumber(percent_x) or 50) / 100 - 0.5) * bx
		local py = ((tonumber(percent_y) or 50) / 100 - 0.5) * by

		self:set_position(px, py)
	end


	-- Tween to a percent-based scroll position within bounds
	root_frame.move_to_position_percent = function(self, percent_x, percent_y, duration)
		local bx = root_frame.xbound_max - root_frame.xbound_min
		local by = root_frame.ybound_max - root_frame.ybound_min

		local target_cx = ((tonumber(percent_x) or 50) / 100 - 0.5) * bx
		local target_cy = ((tonumber(percent_y) or 50) / 100 - 0.5) * by

		self:move_to_position(target_cx, target_cy, duration)
	end
	
	return root_frame
end



--horizontal list of buttons, used for tabs maybe
he.hbuttonlist = function(intable)
	local default = {
		select_cb = function(self, select_index, previous_index)
			
		end,
		provider = iup.stationbutton,
		
		fgcolor_base = "100 100 100",
		fgcolor_select = "255 255 255",
		
		bgcolor_base = nil,
		bgcolor_select = nil,
		
		default_select = 1,
		
		[1] = "untitled",
	}
	
	for k, v in pairs(intable) do
		default[k] = v
	end
	
	local last_selection = default.default_select
	
	local button_tabl = {}
	local button_disp = iup.hbox {}
	local button_frame = public.primitives.clearframe {
		button_disp,
	}
	
	local make_button = function(text, index)
		local new_button = default.provider {
			title = tostring(text),
			button_index = index,
			fgcolor = default.fgcolor_base,
			bgcolor = default.bgcolor_base,
			action = function(self)
				if default.fgcolor_select then
					button_tabl[last_selection].fgcolor = default.fgcolor_base
					self.fgcolor = default.fgcolor_select
				end
				
				if default.bgcolor_select then
					button_tabl[last_selection].bgcolor = default.bgcolor_base
					self.bgcolor = default.bgcolor_select
				end
				
				default.select_cb(button_frame, self.button_index, last_selection)
				
				last_selection = tonumber(self.button_index)
			end,
		}
		
		if default.fgcolor_select and index == (default.default_select) then
			new_button.fgcolor = default.fgcolor_select
		end
		
		if default.bgcolor_select and index == (default.default_select) then
			new_button.bgcolor = default.bgcolor_select
		end
		
		return new_button
	end
	
	for k, v in ipairs(intable) do
		local new_button = make_button(v, k)
		
		table.insert(button_tabl, new_button)
		iup.Append(button_disp, new_button)
	end
	
	button_frame.get_button_by_index = function(self, index)
		return button_tabl[index]
	end
	
	button_frame.get_num_buttons = function(self)
		return #button_tabl
	end
	
	--todo: ability to add, remove buttons. indexes need to be configured on every refresh
	
	return button_frame
end



--vertical list of buttons, used for tabs maybe
he.vbuttonlist = function(intable)
	local default = {
		select_cb = function(self, select_index, previous_index)
			
		end,
		provider = iup.stationbutton,
		
		fgcolor_base = "100 100 100",
		fgcolor_select = "255 255 255",
		
		bgcolor_base = nil,
		bgcolor_select = nil,
		
		default_select = 1,
		
		[1] = "untitled",
	}
	
	for k, v in pairs(intable) do
		default[k] = v
	end
	
	local last_selection = default.default_select
	
	local button_tabl = {}
	local button_disp = iup.vbox {}
	local button_frame = public.primitives.clearframe {
		button_disp,
	}
	
	local make_button = function(text, index)
		local new_button = default.provider {
			title = tostring(text),
			button_index = index,
			fgcolor = default.fgcolor_base,
			bgcolor = default.bgcolor_base,
			action = function(self)
				if default.fgcolor_select then
					button_tabl[last_selection].fgcolor = default.fgcolor_base
					self.fgcolor = default.fgcolor_select
				end
				
				if default.bgcolor_select then
					button_tabl[last_selection].bgcolor = default.bgcolor_base
					self.bgcolor = default.bgcolor_select
				end
				
				default.select_cb(button_frame, self.button_index, last_selection)
				
				last_selection = tonumber(self.button_index)
			end,
		}
		
		if default.fgcolor_select and index == (default.default_select) then
			new_button.fgcolor = default.fgcolor_select
		end
		
		if default.bgcolor_select and index == (default.default_select) then
			new_button.bgcolor = default.bgcolor_select
		end
		
		return new_button
	end
	
	for k, v in ipairs(intable) do
		local new_button = make_button(v, k)
		
		table.insert(button_tabl, new_button)
		iup.Append(button_disp, new_button)
	end
	
	button_frame.get_button_by_index = function(self, index)
		return button_tabl[index]
	end
	
	button_frame.get_num_buttons = function(self)
		return #button_tabl
	end
	
	--todo: ability to add, remove buttons. indexes need to be configured on every refresh
	
	return button_frame
end



--[[
💡 Helium Gesture Layer – Future Plan

Why This Works
In Vendetta Online’s IUP system, a `canvas` element can capture `button_cb` events even when visually under other non-interactive elements (e.g., `frame`, `fill`, `label`).
This means a gesture-detecting canvas can be layered *under* the visible content and still receive click/drag events — unless blocked by another interactive control like `button`, `list`, or another `canvas`.
This provides a workaround to the current limitation where only scrollbar elements can drive scrolling.

Overview
Create a `helium.constructs.gesture_layer {}` object that enables drag-scrolling or gesture detection on both desktop and mobile, replacing or supplementing scrollbar use.

Key Features
- Canvas-based input layer that:
  - Captures drag or gesture input
  - Remains visually passive (invisible, underneath content)
- Supports gesture callbacks:
  - `on_drag_start(x, y)`
  - `on_drag_move(dx, dy)`
  - `on_drag_end(x, y)`
  - Optional: `on_tap()`, `on_hold()`

Detection Rules
- Gesture starts when:
  - Drag distance exceeds pixel threshold, OR
  - Time threshold is passed (for “press and hold” detection)
- Gesture ends on mouse/touch release (`pressed == false`)
- Fires through most non-action UI elements (frames, etc.)

Input Details
- Driven by `button_cb(self, button, pressed, x, y)`
  - LMB (button `8`) is primary target
  - `x/y` are relative to the gesture canvas
  - `pressed == true`: gesture begins
  - `pressed == false`: gesture ends
- Works on desktop and likely works on mobile; needs verification
- Uses async loop to poll current mouse position for drag delta
- Optional second async to animate viewport scrolling

Limitations
- Cannot detect physical screen size or PPI (affects how we 'debounce', or reduce jitter)
- Some mobile resolutions have extremely high pixel density — gesture thresholds must be conservative and fixed
- Can be blocked by other interactive widgets layered above (use carefully)

Recommended Defaults
drag_threshold = 8         -- pixels
drag_time_min = 150        -- ms (minimum hold before drag)

Optional:
sensitivity = "low" | "medium" | "high" -- maps to internal presets

Bonus Features (Optional)
- Exclusion zones (rects where input is ignored)
- Visual debug overlay
- Tap/hold detection for additional gestures

Integration
- Use as a child of a `scrollbox` or custom viewport
- Hook up to scroll offset using `set_position(dx, dy)` or similar

]]--



for k, v in pairs(he) do
	public.constructs[k] = v
end
