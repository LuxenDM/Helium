local file_args = {...}

local public = file_args[1]
local private = file_args[2]

local he = {} --these go to presets



--subdialog: modal-style popup with custom placement, with screen-edge awareness
he.subdialog = function(intable)
	local default = {
		lock_focus = "NO",
		alignment = "ACENTER",
		pos_x = nil,
		pos_y = nil, --replaced with screen center coords if nil
		[1] = iup.vbox { },
		--size = resolve(THIRDxTHIRD),
	}
end

--context_menu: subdialog to mimic single-layer context menu behavior
he.context_menu = function(intable)
	local default = {
		pos_x = nil,
		pos_y = nil, --defaults to user mouse position
		button_provider = iup.stationbutton,
		[1] = "Menu",
	}
end

--alert: preset subdialog to display a message to the user.
he.alert = function(intable)
	local default = {
		[1] = "alert message",
		timeout = -1,
		response = "Okay",
	}
end

--reader: preset subdialog to display a large text block.
he.reader = function(intable)
	local default = {
		[1] = "Large text block",
	}
end



public.presets = he
return public
