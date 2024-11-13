local cp = function(msg)
	lib.log_error(msg, 2, "helium", "0.4.2 -indev")
end

local he_ver = "0.4.2 -indev"
local he_path = lib.get_path("helium", he_ver)

cp("Helium " .. he_ver .. " is operating out of " .. he_path)

local config = {
	async_process_time = gkini.ReadInt("helium", "async_process_time", 10),
}

local he = {
	preset = {},
	buttons = {},
	frames = {},
	async = {},
	--public container class
}

local tryfile = function(file)
	local skinfile = (IMAGE_DIR or "skins/platinum/") .. file
	return gksys.IsExist(skinfile) and skinfile or (he_path .. "img/" .. file)
end



local container_types = {
	["hbox"] = true,
	["vbox"] = true,
	["frame"] = true,
	["zbox"] = true,
	["cbox"] = true,
	["dialog"] = true,
	["sbox"] = true,
}

--Maps a dialog, and handles map_cb() for ALL CHILDREN
he.map_dialog = function(ihandle)
	local cb_children
	cb_children = function(ihandle)
		local children = {}
		while true do
			local obj = iup.GetNextChild(ihandle, children[#children])
			if not obj then 
				break
			elseif obj.map_cb and type(obj.map_cb) == "function" then
				obj:map_cb()
			end
			table.insert(children, obj)
			if container_types[iup.GetType(obj)] then
				cb_children(obj)
			end
		end
		children = nil
	end
	
	if iup.IsValid(ihandle) then
		if iup.GetType(ihandle) == "dialog" then
			ihandle:map()
		end
		cb_children(ihandle)
		iup.Refresh(ihandle)
	end
end

--[[ old he.index_container
creates a simple table mapping an iup object.
he.index_container = function(ihandle)
	assert(iup.IsValid(ihandle) == true, type(ihandle) .. ":" .. tostring(ihandle) .. " was not a valid iup object for helium.index_container")
	
	local index_object
	index_object = function(ihandle)
		local children = {}
		while true do
			local obj = iup.GetNextChild(ihandle, children[#children])
			local obj_for_table
			if not obj then
				break
			elseif containter_types[iup.GetType(obj)] then
				obj_for_table = index_object(obj)
				obj_for_table.type = iup.GetType(obj)
			else
				obj_for_table = obj
			end
			table.insert(children, obj_for_table)
		end
		
		return children
	end
	
	return index_object(ihandle)
end
]]--

--creates a simple table mapping an iup object. Replace iup.GetType with iup.GetClassName if using iup >3.xx
he.index_container = function(roothandle)
	local index_object
    index_object = function(ihandle)
        local children = {}
        local last_child = nil
        while true do
            local obj = iup.GetNextChild(ihandle, last_child)
            if not obj then
                break
            end
            local obj_type = iup.GetType(obj)
            local obj_for_table
            if container_types[obj_type] then
                obj_for_table = index_object(obj)
                obj_for_table["_type"] = obj_type
            else
                obj_for_table = obj
            end
            table.insert(children, obj_for_table)
            last_child = obj
        end
        return children
    end

    return index_object(roothandle)
end

--like Append, but as a prefix. puts an object on the front of an iup stack
he.iup_prepend = function(root, obj)
	assert(iup.IsValid(obj) and iup.IsValid(root), "helium.iup_prepend expects both root and object to be valid iup containers!")
	
	local contents = {}
	local next = iup.GetNextChild(root)
	
	while next do
		table.insert(contents, next)
		next = iup.GetNextChild(root, next)
	end
	
	for k, v in ipairs(contents) do
		v:detach()
	end
	
	root:append(obj)
	
	for k, v in ipairs(contents) do
		root:append(v)
	end
	
	iup.Refresh(root)
end

he.async.iup_prepend = function(root, obj, on_complete)
	assert(iup.IsValid(obj) and iup.IsValid(root), "he.iup_prepend_async expects both root and object to be valid IUP containers!")

	local timer = Timer()
	local children = {}
	local current_step = 1
	local start_time = gkmisc.GetGameTime()

	-- Determine chunk size based on async_process_time
	local chunk_size = math.max(1, math.floor(config.async_process_time * 0.10)) -- Scale percentage to reasonable chunks

	-- Step 1: Detach the object to prepare for insertion
	obj:detach()

	-- Step 2: Get all current children of the root
	local next_child = iup.GetNextChild(root)
	while next_child do
		table.insert(children, next_child)
		next_child = iup.GetNextChild(root, next_child)
	end

	-- Timer handler function
	local function handle_prepend()
		if current_step == 1 then
			-- Detach current children in chunks
			for i = 1, chunk_size do
				local child = table.remove(children, 1)
				if child then
					child:detach()
				else
					current_step = 2
					break
				end
			end
		elseif current_step == 2 then
			-- Append the new object
			root:append(obj)
			current_step = 3
		elseif current_step == 3 then
			-- Reattach children in chunks
			for i = 1, chunk_size do
				local child = table.remove(children, 1)
				if child then
					root:append(child)
				else
					current_step = 4
					break
				end
			end
		elseif current_step == 4 then
			-- Final step: Refresh the root
			iup.Refresh(root)
			timer:Stop()

			-- Invoke the callback if provided
			if type(on_complete) == "function" then
				on_complete()
			end

			-- Output the elapsed time for debugging
			--cp(string.format("Async prepend completed in %.2f seconds", gkmisc.GetGameTime() - start_time))
		end
	end

	-- Start the timer to run the handler function every 1 ms
	timer:SetTimeout(1, handle_prepend)
end


--inserts the element in the target position
he.iup_insert = function(root, ihandle, position)
	assert(iup.IsValid(root) and iup.IsValid(ihandle), "helium.iup_insert expects both root and object to be valid iup containers!")
	assert(type(position) == "number", "helium.iup_insert expects the insert position to be a number; was type " .. type(position))
	
	local contents = {}
	local next = iup.GetNextChild(root)
	
	while next do
		table.insert(contents, next)
		next = iup.GetNextChild(root, next)
	end
	
	for i=1, #contents do
		contents[i]:detach()
	end
	
	if position < 0 then
		position = #contents + position
	end
	
	if position == 0 then
		position = 1
	end
	
	if position > #contents then
		position = #contents
	end
	
	table.insert(contents, position, ihandle)
	
	for k, v in ipairs(contents) do
		root:append(v)
	end
	
	iup.Refresh(root)
end

--draugath's old iup.IsValid, kept for posterity
he.IsIup = function(ihandle)
	return pcall(iup.GetType, ihandle)
end

--gets pixel position of the mouse
he.get_mouse_abs_pos = function(x_off, y_off)
	local perX, perY = gkinterface.GetMousePosition()
	local absX = (gkinterface.GetXResolution() * perX) + (tonumber(x_off) or 0)
	local absY = (gkinterface.GetYResolution() * perY) + (tonumber(y_off) or 0)
	
	return absX, absY
end

--scales a 1d value so that sizes are similar on all systems
he.scale_size = function(expected_size, expected_default)
	assert(type(expected_size) == "number", "helium.scale_size expects a number for the 'expected size' (arg 1), got " .. type(expected_size))
	if (type(expected_default) ~= "number") or (expected_default < 1) then
		expected_default = 24
	end
	
	return (Font.Default / expected_default) * expected_size
end

--scales 2d sizes based on an expected font size
he.scale_2x = function(exp_x, exp_y, exp_def)
	if (type(exp_def) ~= "number") or (exp_def < 1) then
		exp_def = 24
	end
	return tostring(he.scale_size(exp_x, exp_def)) .. "x" .. tostring(he.scale_size(exp_y, exp_def))
end

local is_mobile = gkinterface.IsTouchModeEnabled() and 2 or 1
local mobile_scalar = function()
	--Font.Default when PC, Font.Default * 2 when mobile
	return Font.Default * is_mobile
end








--transparent frame template, for frame shenanigans.
he.frames.clearframe = function(intable)
	assert(type(intable) == "table", "Helium.clearframe expects a table for its argument, got a " .. type(intable))
	assert((iup.IsValid(intable[1])) or (intable[1] == nil), "Helium.solidframe input table did not have a valid IUP element at [1]; got " .. type(intable[1]))
	
	local defaults = {
		image = tryfile("solidframe.png"),
		bgcolor = "0 0 0 0 *",
		segmented = "0 0 1 1",
		iup.vbox { },
	}
	
	for k, v in pairs(intable) do
		defaults[k] = v
	end
	
	return iup.frame(defaults)
end

--very simple opaque panel
he.frames.solidframe = function(intable)
	assert(type(intable) == "table", "Helium.solidframe expects a table for its argument, got a " .. type(intable))
	assert((iup.IsValid(intable[1])) or (intable[1] == nil), "Helium.solidframe input table did not have a valid IUP element at [1]; got " .. type(intable[1]))
	
	local defaults = {
		image = tryfile("solidframe.png"),
		bgcolor = "255 255 255 255 *",
		segmented = "0.1 0.1 0.9 0.9",
		iup.vbox { },
	}
	
	for k, v in pairs(intable) do
		defaults[k] = v
	end
	
	return iup.frame(defaults)
end

--very simple edge frame
he.frames.borderframe = function(intable)
	assert(type(intable) == "table", "Helium.borderframe expects a table for its argument, got a " .. type(intable))
	assert((iup.IsValid(intable[1])) or (intable[1] == nil), "Helium.solidframe input table did not have a valid IUP element at [1]; got " .. type(intable[1]))
	
	local defaults = {
		image = tryfile("borderframe.png"),
		bgcolor = "255 255 255 255 *",
		segmented = "0.1 0.1 0.9 0.9",
		iup.vbox { },
	}
	
	for k, v in pairs(intable) do
		defaults[k] = v
	end
	
	return iup.frame(defaults)
end

--primitive object used for highlite rules
he.highlite_panel = function()
	local highlite_obj = iup.label {
		title = "",
		image = tryfile("buttonRounded.png"),
		bgcolor = "255 255 255 0 *",
		expand = "YES",
		highlite = function(self)
			self.bgcolor = "255 255 255 255 *"
		end,
		clear_highlite = function(self)
			self.bgcolor = "255 255 255 0 *"
		end,
	}
	
	return highlite_obj
end

--primitive spacer using a frame object, mimics html <hr> kinda
he.page_rule = function(intable)
	local default = {
		orientation = "HORIZONTAL",
	}
	
	local object = he.control.solidframe {
		iup.vbox {
			((default.orientation == "VERTICAL") or (default.orientation == "ALL")) and iup.fill { } or nil,
			iup.hbox {
				((default.orientation == "HORIZONTAL") or (default.orientation == "ALL")) and iup.fill { } or nil,
			},
		},
	}
	
	return object
end

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
	
	local hlpane = he.highlite_panel()
	
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
		default.highlite == "YES" and hlpane or nil,
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

--preset he.control.select_text used for URLs
he.link_text = function(intable)
	local default = {
		title = "selectable url",
		url = "http://vendetta-online.com/",
		font = Font.Default,
		fgcolor = "128 0 255",
		bgcol
