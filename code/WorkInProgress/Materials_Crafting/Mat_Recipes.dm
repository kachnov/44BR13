/material_recipe
	var/name = ""
	var/result_id = "" //Id of the result material. used as fallback or when you do not want to use a result item.
	var/result_item = null //Path of the resulting material item.

	//This checks if the recipe applies to the given result material.
	//This is a proc so you can do practically anything for recipes.
	//Want a recipe that only applies to wool + erebite composites and only if they have a high temperature resistance? You can.
	//Try to keep these cheap if you can.
	proc/validate(var/material/M)
		return null

	//If no result id or result items are defined, this proc will be executed on the material. Do this if you want a recipe to just modifiy a material.
	proc/apply_to(var/material/M)
		return M

/material_recipe/spacelag
	name = "spacelag"
	result_id = "spacelag"
	result_item = /obj/item/material_piece/spacelag

	validate(var/material/M)
		if (M.name == "spacelag") return TRUE
		else return FALSE

/material_recipe/dyneema
	name = "dyneema"
	result_id = "dyneema"
	result_item = /obj/item/material_piece/cloth/dyneema

	validate(var/material/M)
		var/hasCarbon = 0
		var/hasSilk = 0

		for (var/material/CM in M.parent_materials)
			if (CM.mat_id == "carbonfibre") hasCarbon = 1
			if (CM.mat_id == "spidersilk") hasSilk = 1

		if (M.mat_id == "carbonfibre") hasCarbon = 1
		if (M.mat_id == "spidersilk") hasSilk = 1

		if (hasCarbon && hasSilk) return TRUE
		else return FALSE
