/obj/artifact/healer_bio
	name = "artifact carbon healer"
	associated_datum = /artifact/healer_bio

/artifact/healer_bio
	associated_object = /obj/artifact/healer_bio
	rarity_class = 1
	validtypes = list("martian","precursor")
	validtriggers = list(/artifact_trigger/force,/artifact_trigger/electric,/artifact_trigger/heat,
	/artifact_trigger/radiation,/artifact_trigger/carbon_touch)
	activated = 0
	activ_text = "begins to pulse softly."
	deact_text = "ceases pulsing."
	react_xray = list(11,70,90,9,"NONE")
	var/heal_amt = 20
	var/field_range = 0
	var/recharge_time = 600
	var/recharging = 0

	New()
		..()
		react_heat[2] = "SUPERFICIAL DAMAGE DETECTED"
		if (prob(20))
			field_range = rand(3,10) // range
		heal_amt = rand(5,75) // amount of healing
		recharge_time = rand(1,10) * 10
		if (prob(5))
			recharge_time = 0

	effect_touch(var/obj/O,var/mob/living/user)
		if (..())
			return
		if (!user)
			return
		var/turf/T = get_turf(O)
		if (recharging)
			boutput(user, "<span style=\"color:red\">The artifact pulses briefly, but nothing else happens.</span>")
			return
		if (recharge_time > 0)
			recharging = 1
		T.visible_message("<strong>[O]</strong> emits a wave of energy!")
		if (istype(user,/mob/living/carbon))
			var/mob/living/carbon/C = user
			C.HealDamage("All", heal_amt, heal_amt)
			boutput(C, "<span style=\"color:blue\">Soothing energy saturates your body, making you feel refreshed and healthy.</span>")
		if (field_range > 0)
			for (var/mob/living/carbon/C in range(field_range,T))
				if (C == user)
					continue
				C.HealDamage("All", heal_amt, heal_amt)
				boutput(C, "<span style=\"color:blue\">Waves of soothing energy wash over you, making you feel refreshed and healthy.</span>")
		spawn (recharge_time)
			recharging = 0
			T.visible_message("<strong>[O]</strong> becomes energized.")