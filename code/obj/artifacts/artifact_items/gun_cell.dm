/obj/item/ammo/power_cell/self_charging/artifact
	name = "artifact energy gun power cell"
	icon = 'icons/obj/artifacts/artifactsitemS.dmi'
	artifact = 1
	charge = 400.0
	max_charge = 400.0
	recharge_rate = 0.0
	module_research_no_diminish = 1
	mat_changename = 0
	mat_changedesc = 0

	New(var/loc, var/forceartitype)
		//artifact = new /artifact/energyammo(src)
		var/artifact/energyammo/A = new /artifact/energyammo(src)
		if (forceartitype)
			A.validtypes = list("[forceartitype]")
		artifact = A
		spawn (0)
			ArtifactSetup()

			max_charge = rand(5,100)
			max_charge *= 10
			A.react_elec[2] = max_charge
			recharge_rate = rand(5,60)
		..()

	examine()
		set src in oview()
		boutput(usr, "You have no idea what this thing is!")
		if (!ArtifactSanityCheck())
			return
		var/artifact/A = artifact
		if (istext(A.examine_hint))
			boutput(usr, "[A.examine_hint]")

	UpdateName()
		name = "[name_prefix(null, 1)][real_name][name_suffix(null, 1)]"

	attackby(obj/item/W as obj, mob/user as mob)
		if (Artifact_attackby(W,user))
			..()

/artifact/energyammo
	associated_object = /obj/item/ammo/power_cell/self_charging/artifact
	rarity_class = 0
	validtypes = list("ancient","eldritch","precursor")
	automatic_activation = 1
	react_elec = list("equal",0,0)
	react_xray = list(8,80,95,11,"SEGMENTED")
	examine_hint = "It kinda looks like it's supposed to be inserted into something."
	module_research = list("energy" = 15, "weapons" = 1, "miniaturization" = 15)
	module_research_insight = 1

	New()
		..()
		react_heat[2] = "VOLATILE REACTION DETECTED"