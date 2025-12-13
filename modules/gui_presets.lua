local file_args = {...}

local public = file_args[1]
local private = file_args[2]
local config = file_args[3]

local he = {} --these go to public.presets



--subdialog: modal-style popup with custom placement, with screen-edge awareness
he.subdialog = function(intable)
	assert(type(intable) == "table", "helium.subdialog expects a table")

	local default = {
		lock_focus = "NO",
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

	local blocker = iup.canvas {
		cx = 0,
		cy = 0,
		size = HUDSize(1, 1),
		border = "NO",
		expand = "YES",
		bgcolor = "0 0 0 0 *",
		button_cb = function(self, button, pressed, mx, my)
			--console_print(tostring(button) .. ", " .. tostring(pressed) .. ", " .. tostring(mx) .. ", " .. tostring(my))
			--8 lmb 16 mmb 32 rmb 256 xmb4 512 xmb5
			if (button == 8) and (pressed == 0) and (default.lock_focus ~= "YES") then
				local dialog = iup.GetDialog(self)
				HideDialog(dialog)
				if iup.IsValid(dialog) and dialog.on_action then
					dialog:on_action(-1, "_closed")
				end
			end
		end,
	}
	
	local shield = iup.canvas {
		cx = default.pos_x or 0,
		cy = default.pos_y or 0,
		size = "32x32", --overwritten at map_cb
		expand = "NO",
		border = "NO",
		bgcolor = "0 0 0 0 *",
		button_cb = function(self, button, pressed, mx, my)
			-- Just swallow the click for this dialog layer
			return iup.DEFAULT
		end,
	}

	-- Add content second so it appears above blocker
	local ab = public.constructs.autobox {
		cx = default.pos_x or 0,
		cy = default.pos_y or 0,
		blocker,
		shield,
		default[1], -- main content, appears on top
	}

	local root_dialog = iup.dialog {
		topmost = "YES",
		fullscreen = "YES",
		bgcolor = "0 0 0 80 *",
		public.primitives.clearframe {
			expand = "YES",
			ab,
		}
	}

	root_dialog.on_action = default.on_action

	root_dialog.map_cb = function(self)
		local pos_x = default.pos_x or (screen_w / 2)
		local pos_y = default.pos_y or (screen_h / 2)

		-- content is third element, blocker is first
		local content = ab.cbox_children[3]
		local sh_obj = ab.cbox_children[2]

		local dialog_size = {}
		for value in string.gmatch(content.size or "", "%d+") do
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

		content.cx = pos_x
		content.cy = pos_y
		sh_obj.cx = pos_x
		sh_obj.cy = pos_y
		shield.size = content.size or default[1].size or "32x32"
		--sh_obj.size = content.size or default[1].size or "32x32"
		iup.Refresh(ab)
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

	local dialog

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
	local visual_box = public.primitives.solidframe {
		button_container
	}

	-- Build subdialog
	dialog = he.subdialog {
		pos_x = default.pos_x,
		pos_y = default.pos_y,
		lock_focus = "NO",
		alignment = "SE",
		visual_box,
		on_action = default.on_action,
	}
	
	return dialog
end


--alert: preset subdialog to display a message to the user.
he.alert_box = function(intable)
	assert(type(intable) == "table", "helium.alert_box expects a table")

	local default = {
		title = "Alert",
		button_text = "Okay",
		timeout = -1,
		lock_focus = "YES",
		on_action = function(self, code, label) end,
	}

	for k, v in pairs(intable) do
		default[k] = v
	end

	local message = public.constructs.shrink_label {
		title = default.title,
	}

	local dialog

	local confirm_button = iup.stationbutton {
		title = default.button_text,
		action = function(self)
			if dialog.on_action then
				dialog:on_action(1, "_confirm")
			end
			HideDialog(dialog)
		end,
	}

	local dialog_content = iup.vbox {
		alignment = "ACENTER",
		margin = "10x10",
		gap = 6,
		message,
		confirm_button,
	}

	default[1] = dialog_content

	dialog = he.subdialog {default}

	-- Handle timeout
	if default.timeout and tonumber(default.timeout) > 0 then
		local t = Timer()
		t:SetTimeout(tonumber(default.timeout), function()
			HideDialog(dialog)
			if dialog.on_action then
				dialog:on_action(-1, "_timeout")
			end
			t:Kill()
		end)
	end
	
	return dialog
end



he.choice_box = function(intable)
	assert(type(intable) == "table", "helium.choice_box expects a table")

	local default = {
		lock_focus = "YES",
		on_action = function(self, index, label) end,
		title = "Choose an Option",
		[1] = "Yes",
		[2] = "No",
	}
	local option_list = {}
	for k, v in ipairs(intable) do
		option_list[k] = v
	end

	for k, v in pairs(intable) do
		if type(k) == "number" then
			v = nil
		end
		default[k] = v
	end

	local message = public.constructs.shrink_label {
		title = default.title,
	}

	local button_container = iup.hbox {
		alignment = "ACENTER",
		gap = 8,
		margin = "0x4",
	}

	local dialog

	for index, label in ipairs(option_list) do
		local btn = iup.stationbutton {
			title = label,
			action = function(self)
				if dialog.on_action then
					dialog:on_action(index, label)
				end
				HideDialog(dialog)
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

	default[1] = dialog_content

	dialog = he.subdialog {default}
	
	return dialog
end



he.list_box = function(intable)
	assert(type(intable) == "table", "helium.list_box expects a table")

	local default = {
		title = "Select an Option",
		[1] = "Option 1",
		[2] = "Option 2",
		[3] = "Option 3",
		button_text = "Select",
		lock_focus = "YES",
		on_action = function(self, index, text) end,
	}
	local option_list = {}
	for k, v in ipairs(intable) do
		option_list[k] = v
	end

	for k, v in pairs(intable) do
		if type(k) == "number" then
			v = nil
		end
		default[k] = v
	end

	local message = public.constructs.shrink_label {
		title = default.title,
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

	for i, v in ipairs(option_list) do
		dropdown[i] = tostring(v)
	end

	local dialog

	local confirm_button = iup.stationbutton {
		title = default.button_text,
		action = function(self)
			if dialog.on_action then
				dialog:on_action(current_index, option_list[current_index])
			end
			HideDialog(dialog)
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
	default[1] = dialog_content

	dialog = he.subdialog {default}
	
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
		on_action = default.on_action,
	}
	
	return dialog
end



he.input_box = function(intable)
	assert(type(intable) == "table", "helium.input_box expects a table")

	local default = {
		title = "Please enter a value:",
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
		title = default.title,
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
		dialog_content,
		on_action = function(self, code, status)
			if status == "_closed" then
				default.on_action(self, 0, "_closed")
			end
		end,
	}

	-- Submit via Enter key
	input_field.action = function(self, text, newchar, newval)
		if newchar == iup.K_CR then -- Enter key
			confirm_btn.action(confirm_btn)
			return iup.IGNORE
		end
	end
	
	return dialog
end



public.presets = he