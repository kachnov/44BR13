/obj/artifact/teleport_recaller
	name = "artifact recaller"
	associated_datum = /artifact/recaller

/artifact/recaller
	associated_object = /obj/artifact/teleport_recaller
	rarity_class = 2
	validtypes = list("wizard","eldritch","precursor")
	validtriggers = list(/artifact_trigger/force,/artifact_trigger/electric,/artifact_trigger/heat,
	/artifact_trigger/radiation,/artifact_trigger/carbon_touch,/artifact_trigger/silicon_touch)
	activated = 0
	react_xray = list(15,75,90,3,"ANOMALOUS")
	var/recall_delay = 10

	New()
		..()
		recall_delay = rand(2,600) // how long *10 it takes for the recall to happen
		recall_delay *= 10

	effect_touch(var/obj/O,var/mob/living/user)
		if (..())
			return
		if (!user)
			return

		spawn (recall_delay)
			user.visible_message("<span style=\"color:red\"><strong>[user]</strong> is suddenly pulled through space!</span>")
			playsound(user.loc, "sound/effects/mag_warp.ogg", 50, 1, -1)
			var/turf/T = get_turf(O)
			if (T)
				user.set_loc(T)
