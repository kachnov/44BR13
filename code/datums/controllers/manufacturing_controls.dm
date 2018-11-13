var/manufacturing_controller/manuf_controls = null

/manufacturing_controller
	var/list/manufacturing_units = list()
	var/list/normal_schematics = list()
	var/list/custom_schematics = list()

	proc/set_up()
		for (var/M in subtypesof(/manufacture))
			normal_schematics += new M
		for (var/obj/machinery/manufacturer/M in world)
			manufacturing_units += M
			M.set_up_schematics()
			M.claim_free_resources()

/proc/get_schematic_from_path(var/schematic_path)
	if (!ispath(schematic_path))
		logTheThing("debug", null, null, "<strong>Manufacturer:</strong> Attempt to find schematic with null path")
		return null
	if (!manuf_controls.normal_schematics.len)
		logTheThing("debug", null, null, "<strong>Manufacturer:</strong> Cant find schematic due to empty schematic list")
		return null
	for (var/manufacture/M in manuf_controls.normal_schematics)
		if (schematic_path == M.type)
			return M
	logTheThing("debug", null, null, "<strong>Manufacturer:</strong> Schematic \"[schematic_path]\" not found")
	return null

/proc/get_schematic_from_name(var/schematic_name)
	if (!istext(schematic_name))
		logTheThing("debug", null, null, "<strong>Manufacturer:</strong> Attempt to find schematic with non-string")
		return null
	if (!manuf_controls.normal_schematics.len && !manuf_controls.custom_schematics.len)
		logTheThing("debug", null, null, "<strong>Manufacturer:</strong> Cant find schematic due to empty schematic lists")
		return null
	for (var/manufacture/M in (manuf_controls.normal_schematics + manuf_controls.custom_schematics))
		if (schematic_name == M.name)
			return M
	logTheThing("debug", null, null, "<strong>Manufacturer:</strong> Schematic with name \"[schematic_name]\" not found")
	return null

/proc/get_schematic_from_name_in_custom(var/schematic_name)
	if (!istext(schematic_name))
		logTheThing("debug", null, null, "<strong>Manufacturer:</strong> Attempt to find schematic with non-string")
		return null
	if (!manuf_controls.custom_schematics.len)
		logTheThing("debug", null, null, "<strong>Manufacturer:</strong> Cant find schematic due to empty schematic lists")
		return null
	for (var/manufacture/M in manuf_controls.custom_schematics)
		if (schematic_name == M.name)
			return M
	logTheThing("debug", null, null, "<strong>Manufacturer:</strong> Schematic with name \"[schematic_name]\" not found")
	return null