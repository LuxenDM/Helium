if type(lib) == "table" and lib[0] == "LME" then
	if not lib.is_exist("helium") then
		lib.register("plugins/Helium/helium.ini")
	end
else
	print("Helium is an LME library; please install an LME interface such as Neoloader to use this library's features")
end