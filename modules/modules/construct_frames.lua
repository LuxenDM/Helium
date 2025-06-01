local file_args = {...}

local public = file_args[1]
local private = file_args[2]
local config = file_args[3]

local he = {} -->>public.construct._func()





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



--a vertically scrolling pane, without using a control iup.list
he.vscroll = function(intable)
	local default = {
		expand = "YES",
		scrollbar = "YES",
		[1] = iup.vbox { },
	}
	
	for k, v in pairs(intable) do
		default[k] = v
	end
	
	local iup_element = default[1]
	default[1] = nil
	
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
	
	local content_frame = public.primitives.clearframe {
		cx = 0,
		cy = 0,
		iup_element,
	}
	
	local scroller
	scroller = public.primitives.vslider {
		scroll_event_cb = function()
			content_frame.cy = ((scroller:get_pos() * (content_frame.h - scroller.h)) / 100) * -1
			iup.Refresh(content_frame)
		end,
	}
	
	local cbox_area = iup.cbox {
		expand = "YES",
		content_frame,
	}
	
	default[1] = iup.hbox {
		cbox_area,
		scroller,
	}
	
	local root_frame = public.primitives.clearframe(default)
	root_frame.map_cb = function(self)
		if self.expand == "NO" then
			return
		end
		
		--todo: auto-detect if contents change size and re-determine scroller visibility & values
		
		local root = imposter --iup.GetParent(self)
		local w = root.w
		local h = root.h
		self.size = tostring(w) .. "x" .. tostring(h)
		cbox_area.size = tostring(w - Font.Default) .. "x" .. tostring(h)
		scroller.size = tostring(Font.Default) .. "x" .. tostring(h)
		content_frame.size = tostring(w - Font.Default) .. "x" .. tostring(content_frame.h)
		if (default.scrollbar == "NO") or (tonumber(content_frame.h) < tonumber(h)) then
			private.cp("cbox area smaller than parent frame")
			private.cp("	cbox: " .. tostring(content_frame.h))
			private.cp("	root: " .. tostring(h))
			cbox_area.size = tostring(w) .. "x" .. tostring(h)
			scroller:detach()
			content_frame.size = tostring(w) .. "x" .. tostring(h)
		end
		private.cp("vscroller fit-to-parent feedback:")
		private.cp("	parent w: " .. tostring(w))
		private.cp("	parent h: " .. tostring(h))
		private.cp("	size: " .. tostring(self.size))
		iup.Refresh(self)
		private.cp("	size (post-refresh): " .. tostring(self.size))
	end
	
	local final_frame = iup.zbox {
		root_frame,
		default.expand == "YES" and imposter or nil,
	}
	
	-- Get vertical scroll position as display percent (0–100)
	final_frame.get_position_percent = function()
		return scroller:get_pos()
	end

	-- Instantly set vertical scroll to display percent (0–100)
	final_frame.set_position_percent = function(self, percent)
		scroller:set_pos_percent(percent)
	end

	-- Tween vertical scroll to display percent (0–100)
	final_frame.move_to_position_percent = function(self, percent, duration)
		public.async.tween_value(scroller:get_pos(), percent, duration, function(val)
			scroller:set_pos_percent(val)
		end)
	end
	
	
	return final_frame
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
	
	local content_frame = public.primitives.clearframe {
		cx = 0,
		cy = 0,
		iup_element,
	}
	
	local scroller
	scroller = public.primitives.hslider {
		scroll_event_cb = function()
			content_frame.cx = ((scroller:get_pos() * (content_frame.w - scroller.w)) / 100) * -1
			iup.Refresh(content_frame)
		end,
	}
	
	local cbox_area = iup.cbox {
		expand = "YES",
		content_frame,
	}
	
	default[1] = iup.vbox {
		cbox_area,
		scroller,
	}
	
	local root_frame = public.primitives.clearframe(default)
	root_frame.map_cb = function(self)
		if self.expand == "NO" then
			return
		end
		
		local root = imposter --iup.GetParent(self)
		local w = root.w
		local h = root.h
		private.cp("hscroller fit-to-parent feedback:")
		private.cp(" imposter.h = " .. tostring(imposter.h))
		private.cp(" content_frame.h = " .. tostring(content_frame.h))
		private.cp(" cbox_area.h = " .. tostring(cbox_area.h))
		self.size = tostring(w) .. "x" .. tostring(h + Font.Default)
		cbox_area.size = tostring(w) .. "x" .. tostring(h + Font.Default)
		scroller.size = tostring(w) .. "x" .. tostring(Font.Default)
		content_frame.size = tostring(content_frame.w) .. "x" .. tostring(h)
		if (default.scrollbar == "NO") or (tonumber(content_frame.w) < tonumber(w)) then
			cbox_area.size = tostring(w) .. "x" .. tostring(h)
			scroller:detach()
			content_frame.size = tostring(w) .. "x" .. tostring(h)
		end
		private.cp("	size: " .. tostring(self.size))
		iup.Refresh(self)
		private.cp("hscroller fit-to-parent feedback:")
		private.cp(" imposter.h = " .. tostring(imposter.h))
		private.cp(" content_frame.h = " .. tostring(content_frame.h))
		private.cp(" cbox_area.h = " .. tostring(cbox_area.h))
		private.cp("	parent w: " .. tostring(w))
		private.cp("	parent h: " .. tostring(h))
		private.cp("	size (post-refresh): " .. tostring(self.size))
	end
	
	local final_frame = iup.zbox {
		root_frame,
		default.expand == "YES" and imposter or nil,
	}
	
	-- Get vertical scroll position as display percent (0–100)
	final_frame.get_position_percent = function()
		return scroller:get_pos()
	end

	-- Instantly set vertical scroll to display percent (0–100)
	final_frame.set_position_percent = function(self, percent)
		scroller:set_pos_percent(percent)
	end

	-- Tween vertical scroll to display percent (0–100)
	final_frame.move_to_position_percent = function(self, percent, duration)
		public.async.tween_value(scroller:get_pos(), percent, duration, function(val)
			scroller:set_pos_percent(val)
		end)
	end
	
	return final_frame
end



--"attached panel viewport" - a freely scrolled panel in two directions.
he.ascroll = function(intable)
	local default = {
		expand = "YES",
		expand_child = "YES",
			--YES: expands both child content_frame and bounds to match cbox
			--CONTENT: expands only content_frame
			--BOUND: sets content_frame to match bounds
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

	local imposter = public.primitives.clearframe {
		expand = (not default.size and "YES") or "NO",
		size = default.size,
		iup.vbox {
			iup.hbox {
				iup.fill { },
			},
			iup.fill { },
		},
	}

	local content_frame = public.primitives.clearframe {
		cx = 0,
		cy = 0,
		iup_element,
	}

	local cbox_area = iup.cbox {
		expand = "YES",
		content_frame,
	}

	default[1] = iup.vbox {
		cbox_area,
	}


	local root_frame = public.primitives.clearframe(default)
	root_frame.map_cb = function(self)
		if default.expand == "NO" then return end

		local w = tonumber(imposter.w) or tonumber(iup.GetParent(self).w) or 32
		local h = tonumber(imposter.h) or tonumber(iup.GetParent(self).h) or 32

		local view_size = tostring(w) .. "x" .. tostring(h)
		self.size = view_size
		iup.Refresh(self)
		cbox_area.size = view_size
		
		iup.Refresh(self)

		if default.expand_child == "NO" then return end

		if default.expand_child == "YES" then
			-- Resize both content and logical bounds to match viewport
			content_frame.size = view_size

			self.xbound_min = 0
			self.xbound_max = w
			self.ybound_min = 0
			self.ybound_max = h

		elseif default.expand_child == "CONTENT" then
			local content_w = tonumber(content_frame.w)
			local content_h = tonumber(content_frame.h)

			if content_w < w then content_w = w end
			if content_h < h then content_h = h end

			content_frame.size = tostring(content_w) .. "x" .. tostring(content_h)

		elseif default.expand_child == "BOUND" then
			local bw = self.xbound_max - self.xbound_min
			local bh = self.ybound_max - self.ybound_min

			content_frame.size = tostring(bw) .. "x" .. tostring(bh)
		end
		
		if default.bound_match_override == "YES" then
			self.xbound_min = 0
			self.xbound_max = w
			self.ybound_min = 0
			self.ybound_max = h
		end
		
		iup.Refresh(self)
	end



	local output_frame = iup.zbox {
		root_frame,
		imposter,
	}
	
	output_frame.update_bounds = function(self, xmin, xmax, ymin, ymax)
		self.xbound_min = tonumber(xmin) or -100
		self.xbound_max = tonumber(xmax) or 100
		self.ybound_min = tonumber(ymin) or -100
		self.ybound_max = tonumber(ymax) or 100
	end

	
	-- Get scroll offset in raw coordinates
	output_frame.get_position = function()
		return content_frame.cx, content_frame.cy
	end

	-- Set scroll position in raw coordinates
	output_frame.set_position = function(self, target_x, target_y)
		content_frame.cx = tonumber(target_x) or content_frame.cx
		content_frame.cy = tonumber(target_y) or content_frame.cy
		iup.Refresh(self)
	end

	-- Tween scroll position in raw coordinates
	output_frame.move_to_position = function(self, target_x, target_y, time_to_tween)
		self.tween_id = (self.tween_id or 0) + 1
		local this_tween_id = self.tween_id
		local start_x = content_frame.cx
		local start_y = content_frame.cy
		local apply_tween = function(tween_x, tween_y)
			if self.tween_id ~= this_tween_id then return end
			content_frame.cx = tween_x or content_frame.cx
			content_frame.cy = tween_y or content_frame.cy
			iup.Refresh(self)
		end

		public.async.tween_value(start_x, target_x, time_to_tween, function(xval) apply_tween(xval, nil) end)
		public.async.tween_value(start_y, target_y, time_to_tween, function(yval) apply_tween(nil, yval) end)
	end

	-- Get scroll position as a percentage within logical bounds
	output_frame.get_position_percent = function()
		local px, py = content_frame.cx, content_frame.cy
		local bx = root_frame.xbound_max - root_frame.xbound_min
		local by = root_frame.ybound_max - root_frame.ybound_min

		-- Convert position to display percent (0–100)
		local cx = ((px / bx) + 0.5) * 100
		local cy = ((py / by) + 0.5) * 100

		return cx, cy
	end


	-- Set scroll position as a percentage relative to bounds (0.0 = top/left, 1.0 = bottom/right)
	output_frame.set_position_percent = function(self, percent_x, percent_y)
		local bx = root_frame.xbound_max - root_frame.xbound_min
		local by = root_frame.ybound_max - root_frame.ybound_min

		local px = ((tonumber(percent_x) or 50) / 100 - 0.5) * bx
		local py = ((tonumber(percent_y) or 50) / 100 - 0.5) * by

		self:set_position(px, py)
	end


	-- Tween to a percent-based scroll position within bounds
	output_frame.move_to_position_percent = function(self, percent_x, percent_y, duration)
		local bx = root_frame.xbound_max - root_frame.xbound_min
		local by = root_frame.ybound_max - root_frame.ybound_min

		local target_cx = ((tonumber(percent_x) or 50) / 100 - 0.5) * bx
		local target_cy = ((tonumber(percent_y) or 50) / 100 - 0.5) * by

		self:move_to_position(target_cx, target_cy, duration)
	end




	return output_frame
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



for k, v in pairs(he) do
	public.constructs[k] = v
end
