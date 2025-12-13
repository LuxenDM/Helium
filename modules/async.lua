--[[
[metadata]
description=Asynchronous style variants of certain helium utility functions
version=1.0.0
owner=helium|1.1.1
type=lua
created=2025-06-01
]]--

local file_args = {...}

local public = file_args[1]
local private = file_args[2]
local config = file_args[3]

local he = {} --these go to async



--asynchronous method to index an iup container, getting a table representation on callback
he.index_container = function(root, on_complete)
	assert(iup.IsValid(root), "he.index_container expects a valid IUP handle")
	assert(type(on_complete) == "function", "he.index_container requires an on_complete callback")

	local container_types = {
		hbox = true, vbox = true, frame = true,
		zbox = true, cbox = true, dialog = true, sbox = true,
	}

	local queue = {{handle = root, parent_tbl = nil, result_tbl = {}}}
	local index_timer = Timer()

	local step
	step = function()
		local current = table.remove(queue, 1)
		if not current then
			index_timer:Kill()
			on_complete(queue[1] and queue[1].result_tbl or {}) -- fallback empty
			return
		end

		local handle = current.handle
		local result_tbl = current.result_tbl
		if current.parent_tbl then
			table.insert(current.parent_tbl, result_tbl)
		end

		local obj_type = iup.GetType(handle)
		if container_types[obj_type] then
			result_tbl._type = obj_type
			local next = iup.GetNextChild(handle)
			while next do
				table.insert(queue, {
					handle = next,
					parent_tbl = result_tbl,
					result_tbl = container_types[iup.GetType(next)] and {} or next
				})
				next = iup.GetNextChild(handle, next)
			end
		else
			index_timer:SetTimeout(1, step)
			return
		end

		index_timer:SetTimeout(1, step)
	end

	index_timer:SetTimeout(1, step)
end




--asynchronous method to map a dialog and execute all embedded map_cb. triggers callback on complete
he.map_dialog = function(dialog, on_complete)
	assert(iup.IsValid(dialog), "he.map_dialog expects a valid IUP dialog")
	assert(type(on_complete) == "function" or on_complete == nil, "he.map_dialog requires a callback or nil")

	local map_timer = Timer()
	local container_types = {
		hbox = true, vbox = true, frame = true,
		zbox = true, cbox = true, dialog = true, sbox = true,
	}

	local queue = {}

	-- Step 0: Map the root dialog if not already
	if iup.GetType(dialog) == "dialog" then
		dialog:map()
	end

	table.insert(queue, dialog)

	local step
	step = function()
		local current = table.remove(queue, 1)
		if not current then
			map_timer:Kill()
			if on_complete then on_complete() end
			return
		end

		if current.map_cb and type(current.map_cb) == "function" then
			current:map_cb()
		end

		if container_types[iup.GetType(current)] then
			local next = iup.GetNextChild(current)
			while next do
				table.insert(queue, next)
				next = iup.GetNextChild(current, next)
			end
		end

		map_timer:SetTimeout(1, step)
	end

	map_timer:SetTimeout(1, step)
end




--asynchronous method to add an element to the top of an iup struc. triggers callback on complete
he.prepend = function(root, obj, on_complete)
	assert(iup.IsValid(obj) and iup.IsValid(root), "he.prepend expects both root and object to be valid IUP containers!")

	local children = {}
	local detach_timer = Timer()
	local append_obj_timer = Timer()
	local append_children_timer = Timer()
	local finish_timer = Timer()

	-- Phase 0: Gather all current children
	do
		local next = iup.GetNextChild(root)
		while next do
			table.insert(children, next)
			next = iup.GetNextChild(root, next)
		end
	end

	local detach_index = 1
	local reattach_index = 1

	-- Phase 1: Detach children
	local detach_step
	detach_step = function()
		if children[detach_index] then
			children[detach_index]:detach()
			detach_index = detach_index + 1
			detach_timer:SetTimeout(1, detach_step)
		else
			-- Proceed to next phase
			append_obj_timer:SetTimeout(1, function()
				obj:detach()
				root:append(obj)
				-- Proceed to next phase
				append_children_timer:SetTimeout(1, append_children_step)
			end)
		end
	end

	-- Phase 2: Reattach children
	local append_children_step
	append_children_step = function()
		if children[reattach_index] then
			root:append(children[reattach_index])
			reattach_index = reattach_index + 1
			append_children_timer:SetTimeout(1, append_children_step)
		else
			-- Final refresh and cleanup
			finish_timer:SetTimeout(1, function()
				iup.Refresh(root)
				if on_complete then on_complete() end
				detach_timer:Kill()
				append_obj_timer:Kill()
				append_children_timer:Kill()
				finish_timer:Kill()
			end)
		end
	end

	-- Begin phase 1
	detach_timer:SetTimeout(1, detach_step)
end




--asynchronous method to insert an element in an iup struc. triggers callback on complete
he.insert = function(root, ihandle, position, on_complete)
	assert(iup.IsValid(root) and iup.IsValid(ihandle), "he.insert expects valid IUP handles")
	assert(type(position) == "number", "he.insert expects a numeric position")

	local detach_timer = Timer()
	local append_timer = Timer()
	local finish_timer = Timer()

	local children = {}
	local detach_index = 1
	local reattach_index = 1
	local insert_done = false

	-- Step 0: Snapshot all children
	do
		local next = iup.GetNextChild(root)
		while next do
			table.insert(children, next)
			next = iup.GetNextChild(root, next)
		end
	end

	-- Normalize position
	if position < 0 then
		position = #children + position + 1
	end
	if position < 1 then
		position = 1
	elseif position > (#children + 1) then
		position = #children + 1
	end

	-- Step 1: Detach everything
	local detach_step
	detach_step = function()
		local child = children[detach_index]
		if child then
			child:detach()
			detach_index = detach_index + 1
			detach_timer:SetTimeout(1, detach_step)
		else
			append_timer:SetTimeout(1, append_step)
		end
	end

	-- Step 2: Reattach with inserted element
	local append_step
	append_step = function()
		if not insert_done and reattach_index == position then
			ihandle:detach()
			root:append(ihandle)
			insert_done = true
			append_timer:SetTimeout(1, append_step)
			return
		end

		local child = children[reattach_index]
		if child then
			root:append(child)
			reattach_index = reattach_index + 1
			append_timer:SetTimeout(1, append_step)
		else
			finish_timer:SetTimeout(1, function()
				iup.Refresh(root)
				if on_complete then on_complete() end
				detach_timer:Kill()
				append_timer:Kill()
				finish_timer:Kill()
			end)
		end
	end

	-- Begin
	detach_timer:SetTimeout(1, detach_step)
end




--tween between two values.
he.tween_value = function(start_v, end_v, time_to_tween, callback, ease_amount)
	local time_start = gkmisc.GetGameTime()
	local duration = tonumber(time_to_tween) or 1000
	local tween_timer = Timer()
	local ease_alpha = math.min(math.max(tonumber(ease_amount) or 0, 0), 1)

	--blend two values on a ratio
	local mix = function(value_a, value_b, balance)
		return value_a * (1 - balance) + value_b * balance
	end
	
	-- Simple ease-in-out quad function
	local function ease_in_out(t)
		if t < 0.5 then
			return 2 * t * t
		else
			return -1 + (4 - 2 * t) * t
		end
	end

	local tween_func
	tween_func = function()
		local now = gkmisc.GetGameTime()
		local progress = (now - time_start) / duration

		if progress >= 1 then
			callback(end_v)
			tween_timer:Kill()
			return -- Done tweening
		end

		local linear_value = progress
		local eased_value = ease_in_out(progress)
		local blended_value = mix(linear_value, eased_value, ease_alpha)
		local tweened_value = start_v + (end_v - start_v) * blended_value
		callback(tweened_value)
		
		tween_timer:SetTimeout(16, tween_func) -- Approximately tweens once a frame at ~60fps
	end

	tween_func()
end




public.async = he
