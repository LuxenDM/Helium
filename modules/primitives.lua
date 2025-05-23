local file_args = {...}

local public = file_args[1]
local private = file_args[2]

local he = {} -->>public.primitives._func()



--todo: replace assert() with cerr()?



--transparent frame template
he.clearframe = function(intable)
	assert(type(intable) == "table", "Helium.clearframe expects a table for its argument, got a " .. type(intable))
	assert((iup.IsValid(intable[1])) or (intable[1] == nil), "Helium.solidframe input table did not have a valid IUP element at [1]; got " .. type(intable[1]))
	
	local defaults = {
		image = private.tryfile("solidframe.png"),
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
he.solidframe = function(intable)
	assert(type(intable) == "table", "Helium.solidframe expects a table for its argument, got a " .. type(intable))
	assert((iup.IsValid(intable[1])) or (intable[1] == nil), "Helium.solidframe input table did not have a valid IUP element at [1]; got " .. type(intable[1]))
	
	local defaults = {
		image = private.tryfile("solidframe.png"),
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
he.borderframe = function(intable)
	assert(type(intable) == "table", "Helium.borderframe expects a table for its argument, got a " .. type(intable))
	
	local defaults = {
		image = private.tryfile("borderframe.png"),
		bgcolor = "255 255 255 255 *",
		segmented = "0.1 0.1 0.9 0.9",
		iup.vbox { },
	}
	
	for k, v in pairs(intable) do
		defaults[k] = v
	end
	
	assert((iup.IsValid(intable[1])), "Helium.solidframe input table did not have a valid IUP element at [1]; got " .. type(intable[1]))
	
	return iup.frame(defaults)
end



--primitive object used for highlite rules (hover on mouseover stuff), controlled by parent
he.highlite_panel = function()
	local highlite_obj = iup.label {
		title = "",
		image = private.tryfile("buttonRounded.png"),
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
--its actually a complex, but bite me
he.page_rule = function(intable)
	local default = {
		orientation = "HORIZONTAL",
	}
	
	for k, v in pairs(intable) do
		default[k] = v
	end
	default[1] = iup.vbox {
		((default.orientation == "VERTICAL") or (default.orientation == "ALL")) and iup.fill { } or nil,
		iup.hbox {
			((default.orientation == "HORIZONTAL") or (default.orientation == "ALL")) and iup.fill { } or nil,
		},
	}
	
	local object = he.control.solidframe (default)
	
	return object
end



--preset progress bar. default valuess of iup.progressbar are wierd.
--todo: add functions for async value tweening and preset images. also, just figure out things?
he.progressbar = function(intable)
	local defaults = {
		--uppertexture = tryfile("progress_frame.png")
		--middletexture = tryfile("??")
		--lowertexture = tryfile("??")
		
		uppercolor = "255 255 255 255 *",
		--middleabovecolor = 
		--middlebelowcolor = 
		lowercolor = "0 0 0 255 *",
		
		type = "HORIZONTAL",
		
		minvalue = 0,
		maxvalue = 100,
		value = 33,
		
		size = "200x" .. tostring(Font.Default),
	}
	
	for k, v in pairs(intable) do
		defaults[k] = v
	end
	
	return iup.progressbar(defaults)
end



he.hslider = function(intable)
	
end



he.vslider = function(intable)
	
	local scroll_timer = Timer()
		--scroll_cb is called EVERY FRAME during a drag event. if your function is heavy, use scroll_event_cb() instead. There should be an EVEN better way of doing this, but i've not found it
	
	local default = {
		ymin = 0,
		ymax = 100,
		dy = 30,
		posy = 0,
		scrollbar = "VERTICAL",
		expand = "VERTICAL",
		scroll_event_cb = function() end, --called by timer with default scroll_cb()
		scroll_cb = function(self)
			scroll_timer:SetTimeout(1, self.scroll_event_cb)
		end,
		border = "NO",
	}
	
	for k, v in pairs(intable) do
		default[k] = v
	end
	
	local scroller - iup.canvas(default)
	
	scroller.get_pos = function(self)
		--get percentage position
		return (self.posy / (self.ymax - self.ymin) * 100)
	end
	
	return scroller
end



public.primitives = he
return public