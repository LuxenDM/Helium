if type(lib) == "table" and lib[0] == "LME" then
	if not lib.is_exist("helium", "1.0.0") then
		lib.register("plugins/helium/helium.lua")
	end
else
	print("Helium is an LME library; please install an LME interface such as Neoloader to use this library's features")
end