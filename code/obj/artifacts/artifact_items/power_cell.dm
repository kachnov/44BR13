/obj/item/cell/artifact
	name = "artifact power cell"
	icon = 'icons/obj/artifacts/artifactsitemS.dmi'
	maxcharge = 10000
	genrate = 50
	specialicon = 1
	artifact = 1
	module_research_no_diminish = 1
	mat_changename = 0
	mat_changedesc = 0

	New(var/loc, var/forceartitype)
		//artifact = new /artifact/powercell(src)
		var/artifact/powercell/AS = new /artifact/powercell(src)
		if (forceartitype)
			AS.validtypes = list("[forceartitype]")
		artifact = AS
		spawn (0)
			ArtifactSetup()
			var/artifact/A = artifact
			maxcharge = rand(15,1000)
			maxcharge *= 100
			A.react_elec[2] = maxcharge
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

/artifact/powercell
	associated_object = /obj/item/cell/artifact
	rarity_class = 1
	validtypes = list("ancient","martian","wizard","precursor")
	automatic_activation = 1
	react_elec = list("equal",0,10)
	react_xray = list(10,80,95,11,"SEGMENTED")
	examine_hint = "It kinda looks like it's supposed to be inserted into something."
	module_research = list("energy" = 15, "miniaturization" = 20)
	module_research_insight = 1

	New()
		..()
		react_heat[2] = "VOLATILE REACTION DETECTED"