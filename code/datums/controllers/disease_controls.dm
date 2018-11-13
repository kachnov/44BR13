var/disease_controller/disease_controls = null

/disease_controller
	var/list/standard_diseases = list()
	var/list/custom_diseases = list()

	New()
		for (var/X in typesof(/ailment))
			if (X == /ailment || X == /ailment/disease || X == /ailment/parasite || X == /ailment/disability)
				continue
			var/ailment/A = new X
			standard_diseases += A

/proc/get_disease_from_path(var/disease_path)
	if (!ispath(disease_path))
		logTheThing("debug", null, null, "<strong>Disease:</strong> Attempt to find schematic with null path")
		return null
	if (!disease_controls.standard_diseases.len)
		logTheThing("debug", null, null, "<strong>Disease:</strong> Cant find disease due to empty disease list")
		return null
	for (var/ailment/A in disease_controls.standard_diseases)
		if (disease_path == A.type)
			return A
	logTheThing("debug", null, null, "<strong>Disease:</strong> Disease \"[disease_path]\" not found")
	return null

/proc/get_disease_from_name(var/disease_name)
	if (!istext(disease_name))
		logTheThing("debug", null, null, "<strong>Disease:</strong> Attempt to find disase with non-string")
		return null
	if (!disease_controls.standard_diseases.len && !disease_controls.custom_diseases.len)
		logTheThing("debug", null, null, "<strong>Disease:</strong> Cant find schematic due to empty disease lists")
		return null
	for (var/ailment/A in (disease_controls.standard_diseases + disease_controls.custom_diseases))
		if (disease_name == A.name)
			return A
	logTheThing("debug", null, null, "<strong>Disease:</strong> Disease with name \"[disease_name]\" not found")
	return null