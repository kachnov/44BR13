/obj/artifact/container
	name = "artifact sealed container"
	associated_datum = /artifact/container

	New(var/loc, var/forceartitype)
		..()

	ArtifactActivated(var/mob/living/user as mob)
		var/artifact/A = artifact
		if (A.activated)
			return
		A.activated = 1
		playsound(loc, A.activ_sound, 100, 1)
		overlays += A.fx_image
		src.visible_message("<strong>[src] seems like it has something inside it...</strong>")
		switch(rand(1,4))
			if (1)
				if (prob(5))
					new/obj/item/artifact/activator_key(src)
				else
					new/obj/item/cell/artifact(src)
					new/obj/item/cell/artifact(src)
					new/obj/item/cell/artifact(src)
			if (2)
				if (prob(5))
					new/obj/critter/domestic_bee/buddy(src)
					new/obj/item/clothing/suit/bee(src)
				else
					new/obj/critter/domestic_bee_larva(src)
					new/obj/critter/domestic_bee_larva(src)
					new/obj/critter/domestic_bee_larva(src)
					new/obj/critter/domestic_bee_larva(src)
					new/obj/critter/domestic_bee_larva(src)
			if (3)
				if (prob(5))
					new/obj/item/gimmickbomb/owlclothes(src)
					new/obj/item/gimmickbomb/owlclothes(src)
					new/obj/item/gimmickbomb/owlclothes(src)
					new/obj/item/gimmickbomb/owlclothes(src)
					new/obj/item/gimmickbomb/owlclothes(src)
				else
					new/obj/item/gimmickbomb/owlclothes(src)
			if (4)
				new/obj/item/old_grenade/light_gimmick(src)

/artifact/container
	associated_object = /obj/artifact/container
	rarity_class = 1
	validtypes = list("ancient","martian","wizard","eldritch","precursor")
	validtriggers = list(/artifact_trigger/force,/artifact_trigger/electric,/artifact_trigger/heat,
	/artifact_trigger/radiation,/artifact_trigger/carbon_touch,/artifact_trigger/silicon_touch)
	activ_text = "deposits its contents on the ground."
	deact_text = "ceases functioning."
	react_xray = list(7,50,40,11,"HOLLOW")

	New()
		..()
		react_heat[2] = "HIGH INTERNAL CONVECTION"

	effect_touch(var/obj/O,var/mob/living/user)
		if (..())
			return
		for (var/obj/I in O.contents)
			I.set_loc(O.loc)
		for (var/mob/N in viewers(O, null))
			N.flash(30)
			if (N.client)
				shake_camera(N, 6, 4)
		O.visible_message("<span style=\"color:red\"><strong>With a blinding light [O] vanishes, leaving its contents behind.</strong></span>")
		playsound(O.loc, "sound/effects/warp2.ogg", 50, 1)
		artifact_controls.artifacts -= src
		qdel(O)
		return