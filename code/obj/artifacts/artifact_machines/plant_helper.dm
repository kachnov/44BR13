/obj/machinery/artifact/plant_helper
	name = "artifact plant_helper"
	associated_datum = /artifact/plant_helper

/artifact/plant_helper
	associated_object = /obj/machinery/artifact/plant_helper
	rarity_class = 2
	validtypes = list("martian","precursor")
	validtriggers = list(/artifact_trigger/force,/artifact_trigger/electric,/artifact_trigger/carbon_touch)
	activated = 0
	activ_text = "begins to radiate a strange energy field!"
	deact_text = "shuts down, causing the energy field to vanish!"
	react_xray = list(9,45,85,11,"ORGANIC")
	var/field_radius = 7
	var/list/helpers = list("water") // make it a bit more modular

	New()
		..()
		react_heat[2] = "SUPERFICIAL DAMAGE DETECTED"
		field_radius = rand(2,9) // field radius
		if (prob(80))
			helpers.Add("growth")
		if (prob(60))
			helpers.Add("health")
		if (prob(40))
			helpers.Add("weedkiller")
		if (prob(20))
			helpers.Add("mutation")

	effect_process(var/obj/O)
		if (..())
			return
		for (var/obj/machinery/plantpot/P in range(O,field_radius))
			var/plant/growing = P.current
			for (var/X in helpers)
				if (X == "water")
					var/wateramt = P.reagents.get_reagent_amount("water")
					if (wateramt > 200)
						P.reagents.remove_reagent("water", 1)
					if (wateramt < 100)
						P.reagents.add_reagent("water", 1)
				if (X == "growth" && growing)
					P.growth++
				if (X == "health" && growing)
					P.health++
				if (X == "weedkiller" && growing)
					if (growing.growthmode == "weed")
						P.health -= 3
				if (X == "mutation" && growing)
					if (prob(8))
						P.HYPmutateplant()