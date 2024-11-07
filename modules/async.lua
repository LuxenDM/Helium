local file_args = {...}

local public = file_args[1]
local private = file_args[2]

local he = {} --these go to async



--asynchronous method to index an iup container, getting a table representation on callback
he.async_index_container = function()
	
end



--asynchronous method to map a dialog and execute all embedded map_cb. triggers callback on complete
he.async_map_dialog = function()
	
end



--asynchronous method to add an element to the top of an iup struc. triggers callback on complete
he.async_prepend = function()
	
end



--asynchronous method to insert an element in an iup struc. triggers callback on complete
he.async_insert = function()
	
end



public.constructs = he
return public