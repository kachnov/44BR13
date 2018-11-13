/obj/machinery/artifact/gravity_well_generator
	name = "artifact gravity well generator"
	associated_datum = /artifact/gravity_well_generator

/artifact/gravity_well_generator
	associated_object = /obj/machinery/artifact/gravity_well_generator
	rarity_class = 2
	validtypes = list("wizard","precursor")
	validtriggers = list(/artifact_trigger/force,/artifact_trigger/electric,/artifact_trigger/heat,
	/artifact_trigger/radiation,/artifact_trigger/carbon_touch)
	activated = 0
	activ_text = "activates and begins to warp gravity around it!"
	deact_text = "shuts down, returning gravity to normal!"
	activ_sound = 'sound/effects/mag_warp.ogg'
	deact_sound = 'sound/effects/singsuck.ogg'
	react_xray = list(20,80,99,0,"ULTRADENSE")
	touch_descriptors = list("You seem to have a little difficulty taking your hand off its surface.")
	var/field_radius = 7
	var/gravity_type = 0 // push or pull?
	examine_hint = "It is covered in very conspicuous markings."

	New()
		..()
		field_radius = rand(4,9) // well radius
		gravity_type = rand(0,1) // 0 for pull, 1 for push

	effect_process(var/obj/O)
		if (..())
			return
		for (var/obj/V in orange(field_radius,O))
			if (V.anchored)
				continue

			if (gravity_type)
				step_away(V,O)
			else
				step_towards(V,O)
		for (var/mob/living/M in orange(field_radius,O))
			if (gravity_type)
				step_away(M,O)
			else
				step_towards(M,O)