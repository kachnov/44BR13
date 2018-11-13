/obj/machinery/artifact/bio_damage_field_generator
	name = "artifact bio damage field generator"
	associated_datum = /artifact/bio_damage_field_generator

/artifact/bio_damage_field_generator
	associated_object = /obj/machinery/artifact/bio_damage_field_generator
	rarity_class = 3
	validtypes = list("martian","wizard","eldritch","precursor")
	validtriggers = list(/artifact_trigger/force,/artifact_trigger/electric,/artifact_trigger/heat,
	/artifact_trigger/radiation,/artifact_trigger/carbon_touch)
	activated = 0
	activ_text = "begins to radiate a strange energy field!"
	deact_text = "shuts down, causing the energy field to vanish!"
	react_xray = list(12,70,90,11,"COMPLEX")
	var/field_radius = 7
	var/field_type = 0 // 0 healing, 1 harming
	var/field_strength = 2

	New()
		..()
		field_radius = rand(2,9) // field radius
		field_type = rand(0,1)
		field_strength = rand(1,5)
		var/harmprob = 33
		if (artitype == "eldritch")
			harmprob += 42 // total of 75% chance of it being nasty
		if (prob(harmprob))
			field_type = 1

		if (field_type && artitype == "eldritch")
			field_strength *= 2

	effect_process(var/obj/O)
		if (..())
			return
		for (var/mob/living/carbon/M in range(O,field_radius))
			if (field_type)
				random_brute_damage(M, field_strength)
				boutput(M, "<span style=\"color:red\">Waves of painful energy wrack your body!</span>")
			else
				M.HealDamage("All", field_strength, field_strength)
				boutput(M, "<span style=\"color:blue\">Waves of soothing energy wash over you!</span>")