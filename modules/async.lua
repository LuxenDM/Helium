local file_args = {...}

local public = file_args[1]
local private = file_args[2]

local he = {} --these go to async



--asynchronous method to index an iup container, getting a table representation on callback
he.index_container = function()
	
end



--asynchronous method to map a dialog and execute all embedded map_cb. triggers callback on complete
he.map_dialog = function()
	
end



--asynchronous method to add an element to the top of an iup struc. triggers callback on complete
he.prepend = function(root, obj, on_complete)
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



--asynchronous method to insert an element in an iup struc. triggers callback on complete
he.insert = function()
	
end



--tween between two values.
he.tween_value = function(start_v, end_v, time_to_tween, callback, ease_amount)
	local time_start = gksys.GKGetGameTime()
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
		local now = gksys.GKGetGameTime()
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
return public
