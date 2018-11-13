/obj/item/reagent_containers/glass/wateringcan/artifact
	name = "artifact watering can"
	icon = 'icons/obj/artifacts/artifactsitem.dmi'
	desc = "You have no idea what this thing is!"
	artifact = 1
	module_research_no_diminish = 1
	mat_changename = 0
	mat_changedesc = 0

	New(var/loc, var/forceartitype)
		..()
		var/artifact/watercan/AS = new /artifact/watercan(src)
		if (forceartitype)
			AS.validtypes = list("[forceartitype]")
		artifact = AS
		spawn (0)
			ArtifactSetup()

		var/capacity = rand(1,20)
		capacity *= 1000
		var/reagents/R = new/reagents(capacity)
		reagents = R
		R.my_atom = src
		R.add_reagent("water", capacity / 2)
		R.add_reagent("saltpetre", capacity / 2)

	attackby(obj/item/W as obj, mob/user as mob)
		if (Artifact_attackby(W,user))
			..()

	examine()
		boutput(usr, "[desc]")
		return

	UpdateName()
		name = "[name_prefix(null, 1)][real_name][name_suffix(null, 1)]"

/artifact/watercan
	associated_object = /obj/item/reagent_containers/glass/wateringcan/artifact
	rarity_class = 1
	validtypes = list("martian","wizard","precursor")
	min_triggers = 0
	max_triggers = 0
	react_xray = list(2,90,15,11,"HOLLOW")
	module_research = list("medicine" = 5, "science" = 5, "miniaturization" = 15)
	module_research_insight = 3


	New()
		..()
		react_heat[2] = "HIGH INTERNAL CONVECTION"