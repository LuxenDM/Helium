local file_args = {...}

local public = file_args[1]
local private = file_args[2]

local he = {} -->>public.construct._func()



he.hslider = function(intable)
	
end



he.vslider = function(intable)
	
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
	
	vexpand = he.control.clearframe {
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
he.hexpandbox = function()
	local default = {
		state = "CLOSED",
		map_cb = nil,
		drawer_cb = function(self) end,
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
	
	hexpand = he.control.clearframe {
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



--horizontal list of tabs, scrollable
he.htablist = function()
	
end



--vertical list of tabs, scrollable
he.vtablist = function()
	
end



--a vertically scrolling pane, without using a control iup.list
he.vscroll = function()
	
end



--a horizontally scrolling pane, which iup.list cannot do
he.hscroll = function()
	
end



--a reactive scrolling frame. end my suffering...
he.scrollframe = function()
	
end



for k, v in pairs(he) do
	public.constructs[k] = v
end
return public