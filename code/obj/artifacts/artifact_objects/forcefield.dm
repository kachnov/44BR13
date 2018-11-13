/obj/artifact/forcefield_generator
	name = "artifact forcefield generator"
	associated_datum = /artifact/forcefield_gen

/artifact/forcefield_gen
	associated_object = /obj/artifact/forcefield_generator
	rarity_class = 1
	validtypes = list("wizard","eldritch","precursor")
	validtriggers = list(/artifact_trigger/force,/artifact_trigger/carbon_touch,
	/artifact_trigger/silicon_touch)
	activated = 0
	activ_text = "comes to life, projecting out a wall of force!"
	deact_text = "shuts down, causing the forcefield to vanish!"
	react_xray = list(13,60,95,11,"NONE")
	var/cooldown = 80
	var/field_radius = 3
	var/field_time = 80
	var/icon_state = "shieldsparkles"
	var/next_activate = 0

	New()
		..()
		icon_state = pick("shieldsparkles","empdisable","greenglow","enshield","energyorb","forcewall","meteor_shield")
		field_radius = rand(2,6) // forcefield radius
		field_time = rand(15,1500) // forcefield duration
		cooldown = rand(50, 1200)
		activ_sound = pick('sound/effects/mag_forcewall.ogg','sound/effects/mag_warp.ogg','sound/effects/MagShieldUp.ogg')
		deact_sound = pick('sound/effects/MagShieldDown.ogg','sound/effects/shielddown2.ogg','sound/effects/singsuck.ogg')

	may_activate(var/obj/O)
		if (!..())
			return FALSE
		if (ticker.round_elapsed_ticks < next_activate)
			O.visible_message("<span style=\"color:red\">[O] emits a loud pop and lights up momentarily but nothing happens!</span>")
			return FALSE
		return TRUE

	effect_activate(var/obj/O,var/mob/living/user)
		if (..())
			return
		O.anchored = 1
		var/turf/Aloc = get_turf(O)
		var/list/forcefields = list()
		for (var/turf/T in range(field_radius,Aloc))
			if (get_dist(O,T) == field_radius)
				var/obj/forcefield/wand/FF = new /obj/forcefield/wand(T,0,icon_state)
				forcefields += FF
		spawn (field_time)
			for (var/obj/forcefield/F in forcefields)
				forcefields -= F
				qdel(F)
			next_activate = ticker.round_elapsed_ticks + cooldown
			if (O)
				O.ArtifactDeactivated()
				O.anchored = 0