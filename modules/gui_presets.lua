local file_args = {...}

local public = file_args[1]
local private = file_args[2]
local config = file_args[3]

local he = {} --these go to presets



--subdialog: modal-style popup with custom placement, with screen-edge awareness
he.subdialog = function(intable)
	assert(type(intable) == "table", "helium.subdialog expects a table")

	local default = {
		lock_focus = "NO", -- prevent closing on outside click
		alignment = "ACENTER",
		pos_x = nil,
		pos_y = nil,
		on_action = function(self, status, status_text) end,
		[1] = iup.vbox {}, -- user content
	}

	for k, v in pairs(intable) do
		default[k] = v
	end

	local screen_w = gkinterface.GetXResolution()
	local screen_h = gkinterface.GetYResolution()

	local container = he.control.clearframe {
		default[1]
	}

	local blocker = iup.canvas {
		size = HUDSize(1, 1),
		border = "NO",
		expand = "YES",
		button_cb = function(self, _, button, pressed)
			if pressed == 0 and default.lock_focus ~= "YES" then
				local dialog = iup.GetDialog(self)
				HideDialog(dialog)
				if iup.IsValid(dialog) and dialog.on_action then
					dialog:on_action(-1, "_closed")
				end
			end
		end,
	}

	local root_dialog = iup.dialog {
		topmost = "YES",
		fullscreen = "YES",
		bgcolor = "0 0 0 80 *",
		public.primitives.clearframe {
			expand = "YES",
			iup.cbox {
				blocker,
				container,
			},
		},
	}
	
	root_dialog.on_action = default.on_action

	root_dialog.map_cb = function(self)
		local pos_x = default.pos_x or (screen_w / 2)
		local pos_y = default.pos_y or (screen_h / 2)

		local dialog_size = {}
		for value in string.gmatch(container.size or "", "%d+") do
			table.insert(dialog_size, tonumber(value))
		end

		local align = default.alignment
		if align == "ACENTER" then
			pos_x = pos_x - (dialog_size[1] or 0) / 2
			pos_y = pos_y - (dialog_size[2] or 0) / 2
		elseif align == "NW" then
			-- no change
		elseif align == "NE" then
			pos_x = pos_x - (dialog_size[1] or 0)
		elseif align == "SW" then
			pos_y = pos_y - (dialog_size[2] or 0)
		elseif align == "SE" then
			pos_x = pos_x - (dialog_size[1] or 0)
			pos_y = pos_y - (dialog_size[2] or 0)
		end

		container.cx = pos_x
		container.cy = pos_y
		iup.Refresh(container)
	end

	public.util.map_dialog(root_dialog)
	return root_dialog
end


--context_menu: subdialog to mimic single-layer context menu behavior
he.context_menu = function(intable)
	assert(type(intable) == "table", "helium.context_menu expects a table")

	local mx, my = public.util.get_mouse_abs_pos()

	local default = {
		pos_x = mx,
		pos_y = my,
		on_action = function(self, index, title) end,
		-- Item list
		[1] = "Option",
	}

	for k, v in pairs(intable) do
		default[k] = v
	end

	-- Build option buttons
	local button_list = {}
	local button_container = iup.vbox {
		alignment = "ACENTER",
		gap = "2",
	}

	for index, title in ipairs(default) do
		local label_button = he.constructs.coverbutton {
			highlite = "YES",
			iup.label {
				title = tostring(title),
				expand = "HORIZONTAL",
				alignment = "ALEFT",
				padding = "8x4",
			},
			action = function(self)
				local dialog = iup.GetDialog(self)
				if dialog.on_action then
					dialog:on_action(index, title)
				end
				HideDialog(dialog)
			end,
		}
		table.insert(button_list, label_button)
		iup.Append(button_container, label_button)
	end

	-- Wrap in solidframe
	local visual_box = he.control.solidframe {
		button_container
	}

	-- Build subdialog
	local dialog = he.subdialog {
		pos_x = default.pos_x,
		pos_y = default.pos_y,
		lock_focus = "NO",
		alignment = "SE",
		visual_box,
		on_action = function(self, code, status)
			default.on_action(self, code, status)
		end,
	}
	
	return dialog
end


--alert: preset subdialog to display a message to the user.
he.alert_box = function(intable)
	assert(type(intable) == "table", "helium.alert_box expects a table")

	local default = {
		title = "Alert",
		[1] = "Something happened.",
		button_text = "Okay",
		timeout = -1,
		lock_focus = "YES",
		on_action = function(self, code, label) end,
	}

	for k, v in pairs(intable) do
		default[k] = v
	end

	local message = public.constructs.shrink_label {
		title = default[1],
	}

	local confirm_button = iup.stationbutton {
		title = default.button_text,
		action = function(self)
			local dlg = iup.GetDialog(self)
			if dlg.on_action then
				dlg:on_action(1, "_confirm")
			end
			HideDialog(dlg)
		end,
	}

	local dialog_content = iup.vbox {
		alignment = "ACENTER",
		margin = "10x10",
		gap = 6,
		message,
		confirm_button,
	}

	local dialog = he.subdialog {
		lock_focus = default.lock_focus,
		title = default.title,
		dialog_content,
		on_action = function(self, code, label)
			if label == "_closed" then
				default.on_action(self, 0, "_closed")
			end
		end,
	}

	dialog.on_action = default.on_action

	-- Handle timeout
	if default.timeout and tonumber(default.timeout) > 0 then
		local t = Timer()
		t:SetTimeout(default.timeout, function()
			if dialog.on_action then
				dialog:on_action(-2, "_timeout")
			end
			HideDialog(dialog)
			t:Kill()
		end)
	end
	
	return dialog
end



he.choice_box = function(intable)
	assert(type(intable) == "table", "helium.choice_box expects a table")

	local default = {
		title = "Choose an Option",
		[1] = "Make a decision.",
		buttons = { "Yes", "No" },
		lock_focus = "YES",
		on_action = function(self, index, label) end,
	}

	for k, v in pairs(intable) do
		default[k] = v
	end

	local message = public.constructs.shrink_label {
		title = default[1],
	}

	local button_container = iup.hbox {
		alignment = "ACENTER",
		gap = 8,
		margin = "0x4",
	}

	for index, label in ipairs(default.buttons) do
		local btn = iup.stationbutton {
			title = label,
			action = function(self)
				local dlg = iup.GetDialog(self)
				if dlg.on_action then
					dlg:on_action(index, label)
				end
				HideDialog(dlg)
			end,
		}
		iup.Append(button_container, btn)
	end

	local dialog_content = iup.vbox {
		alignment = "ACENTER",
		margin = "10x10",
		gap = 6,
		message,
		button_container,
	}

	local dialog = he.subdialog {
		lock_focus = default.lock_focus,
		title = default.title,
		dialog_content,
		on_action = function(self, code, status)
			if status == "_closed" then
				default.on_action(self, 0, "_closed")
			end
		end,
	}
	
	return dialog
end



he.list_box = function(intable)
	assert(type(intable) == "table", "helium.list_box expects a table")

	local default = {
		title = "Select an Option",
		[1] = "Please choose:",
		options = { "Option 1", "Option 2", "Option 3" },
		button_text = "Select",
		lock_focus = "YES",
		on_action = function(self, index, text) end,
	}

	for k, v in pairs(intable) do
		default[k] = v
	end

	local message = public.constructs.shrink_label {
		title = default[1],
	}

	local current_index = 1
	local dropdown = iup.stationsublist {
		dropdown = "YES",
		size = "%20",
		action = function(self, text, index, checked)
			if tonumber(index) then
				current_index = tonumber(index)
			end
		end,
	}

	for i, v in ipairs(default.options) do
		dropdown[i] = tostring(v)
	end

	local confirm_button = iup.stationbutton {
		title = default.button_text,
		action = function(self)
			local dlg = iup.GetDialog(self)
			if dlg.on_action then
				dlg:on_action(current_index, default.options[current_index])
			end
			HideDialog(dlg)
		end,
	}

	local dialog_content = iup.vbox {
		alignment = "ACENTER",
		margin = "10x10",
		gap = 6,
		message,
		dropdown,
		confirm_button,
	}

	local dialog = he.subdialog {
		lock_focus = default.lock_focus,
		title = default.title,
		dialog_content,
		on_action = function(self, code, status)
			if status == "_closed" then
				default.on_action(self, 0, "_closed")
			end
		end,
	}
	
	return dialog
end




--reader: preset subdialog to display a large text block.
he.reader_box = function(intable)
	assert(type(intable) == "table", "helium.reader_box expects a table")

	local default = {
		text = "Long content goes here...",
		[1] = "Okay",
		[2] = nil, -- optional second button
		lock_focus = "NO",
		font = Font.Default,
		on_action = function(self, index, label) end,
	}

	for k, v in pairs(intable) do
		default[k] = v
	end

	local textbox = iup.multiline {
		value = default.text,
		readonly = "YES",
		size = "%30x%30",
		font = default.font,
		bgcolor = "0 0 0 180 *",
	}

	local button_row = iup.hbox {
		alignment = "ACENTER",
		gap = 10,
		margin = "0x6",
	}

	local primary = iup.stationbutton {
		title = default[1] or "Okay",
		action = function(self)
			local dlg = iup.GetDialog(self)
			if dlg.on_action then
				dlg:on_action(1, default[1])
			end
			HideDialog(dlg)
		end,
	}
	iup.Append(button_row, primary)

	if default[2] then
		local secondary = iup.stationbutton {
			title = default[2],
			action = function(self)
				local dlg = iup.GetDialog(self)
				if dlg.on_action then
					dlg:on_action(2, default[2])
				end
				HideDialog(dlg)
			end,
		}
		iup.Append(button_row, secondary)
	end

	local dialog_content = iup.vbox {
		alignment = "ACENTER",
		margin = "10x10",
		gap = 6,
		textbox,
		button_row,
	}

	local dialog = he.subdialog {
		lock_focus = default.lock_focus,
		dialog_content,
		on_action = function(self, code, status)
			if status == "_closed" then
				default.on_action(self, 0, "_closed")
			end
		end,
	}
	
	return dialog
end



he.input_box = function(intable)
	assert(type(intable) == "table", "helium.input_box expects a table")

	local default = {
		title = "Enter Text",
		[1] = "Please enter a value:",
		default_text = "",
		confirm_text = "Submit",
		cancel_text = "Cancel",
		lock_focus = "YES",
		on_action = function(self, index, value) end,
	}

	for k, v in pairs(intable) do
		default[k] = v
	end

	local message = public.constructs.shrink_label {
		title = default[1],
	}

	local input_field = iup.text {
		value = default.default_text,
		size = "%40",
		padding = "4x2",
	}

	-- Confirm button
	local confirm_btn = iup.stationbutton {
		title = default.confirm_text,
		action = function(self)
			local dlg = iup.GetDialog(self)
			if dlg.on_action then
				dlg:on_action(1, input_field.value)
			end
			HideDialog(dlg)
		end,
	}

	-- Optional cancel button
	local button_row = iup.hbox {
		alignment = "ACENTER",
		gap = 8,
		confirm_btn,
	}

	if default.cancel_text then
		local cancel_btn = iup.stationbutton {
			title = default.cancel_text,
			action = function(self)
				local dlg = iup.GetDialog(self)
				if dlg.on_action then
					dlg:on_action(0, "_closed")
				end
				HideDialog(dlg)
			end,
		}
		iup.Append(button_row, cancel_btn)
	end

	local dialog_content = iup.vbox {
		alignment = "ACENTER",
		margin = "10x10",
		gap = 6,
		message,
		input_field,
		button_row,
	}

	local dialog = he.subdialog {
		lock_focus = default.lock_focus,
		title = default.title,
		dialog_content,
		on_action = function(self, code, status)
			if status == "_closed" then
				default.on_action(self, 0, "_closed")
			end
		end,
	}

	-- Submit via Enter key
	input_field.killfocus_cb = function(self)
		-- could validate input here
	end
	input_field.action = function(self, text, newchar, newval)
		if newchar == iup.K_CR then -- Enter key
			confirm_btn.action(confirm_btn)
			return iup.IGNORE
		end
	end
	
	return dialog
end



public.presets = he
