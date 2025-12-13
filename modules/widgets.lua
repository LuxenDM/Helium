--[[
[metadata]
description=A collection of specific-purpose widget items. Coming at a later date!
version=1.0.0
owner=helium|1.1.1
type=lua
created=2025-06-01
]]--

local file_args = {...}

local public = file_args[1]
local private = file_args[2]
local config = file_args[3]

local he = {} --widgets

--functions

public.widgets = he