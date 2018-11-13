/obj/artifact
	// a totally inert piece of shit that does nothing (alien art)
	// might as well use it as the category header for non-machinery artifacts just to be efficient
	name = "artifact large art piece"
	icon = 'icons/obj/artifacts/artifacts.dmi'
	icon_state = "wizard-1" // it's technically pointless to set this but it makes it easier to find in the dreammaker tree
	opacity = 0
	density = 1
	anchored = 0
	artifact = 1
	mat_changename = 0
	mat_changedesc = 0
	var/associated_datum = /artifact/art

	New(var/loc, var/forceartitype)
		var/artifact/AS = new associated_datum(src)
		if (forceartitype) AS.validtypes = list("[forceartitype]")
		artifact = AS

		spawn (0)
			ArtifactSetup()

	UpdateName()
		name = "[name_prefix(null, 1)][real_name][name_suffix(null, 1)]"

	attack_hand(mob/user as mob)
		ArtifactTouched(user)
		return

	attack_ai(mob/user as mob)
		return attack_hand(user)

	attackby(obj/item/W as obj, mob/user as mob)
		if (Artifact_attackby(W,user))
			..()

	meteorhit(obj/O as obj)
		ArtifactStimulus("force", 60)
		..()

	examine()
		set src in oview()
		boutput(usr, "You have no idea what this thing is!")
		if (!ArtifactSanityCheck())
			return
		var/artifact/A = artifact
		if (istext(A.examine_hint))
			boutput(usr, "[A.examine_hint]")

	ex_act(severity)
		switch(severity)
			if (1.0)
				ArtifactStimulus("force", 200)
				ArtifactStimulus("heat", 500)
			if (2.0)
				ArtifactStimulus("force", 75)
				ArtifactStimulus("heat", 450)
			if (3.0)
				ArtifactStimulus("force", 25)
				ArtifactStimulus("heat", 380)
		return

	reagent_act(reagent_id,volume)
		if (..())
			return
		if (!ArtifactSanityCheck())
			return
		var/artifact/A = artifact
		ArtifactStimulus(reagent_id, volume)
		switch(reagent_id)
			if ("radium","porktonium")
				ArtifactStimulus("radiate", round(volume / 10))
			if ("polonium","strange_reagent")
				ArtifactStimulus("radiate", round(volume / 5))
			if ("uranium")
				ArtifactStimulus("radiate", round(volume / 2))
			if ("dna_mutagen","mutagen","omega_mutagen")
				if (A.artitype == "martian")
					ArtifactDevelopFault(80)
			if ("napalm","dbreath","el_diablo")
				ArtifactStimulus("heat", 310 + (volume * 5))
			if ("infernite","foof","ghostchilijuice")
				ArtifactStimulus("heat", 310 + (volume * 10))
			if ("cryostylane")
				ArtifactStimulus("heat", 310 - (volume * 10))
			if ("acid")
				ArtifactTakeDamage(volume * 2)
			if ("pacid")
				ArtifactTakeDamage(volume * 10)
			if ("george_melonium")
				var/random_stimulus = pick("heat","force","radiate","elec")
				var/random_strength = 0
				switch(random_stimulus)
					if ("heat")
						random_strength = rand(200,400)
					if ("elec")
						random_strength = rand(5,5000)
					if ("force")
						random_strength = rand(3,30)
					if ("radiate")
						random_strength = rand(1,10)
				ArtifactStimulus(random_stimulus,random_strength)
		return

	emp_act()
		ArtifactStimulus("elec", 800)
		ArtifactStimulus("radiate", 3)

	blob_act(var/power)
		ArtifactStimulus("force", power)
		ArtifactStimulus("carbtouch", 1)

	bullet_act(var/obj/projectile/P)
		if (material) material.triggerOnAttacked(src, P.shooter, src, (ismob(P.shooter) ? P.shooter:equipped() : P.shooter))
		for (var/atom/A in src)
			if (A.material)
				A.material.triggerOnAttacked(A, P.shooter, src, (ismob(P.shooter) ? P.shooter:equipped() : P.shooter))

		switch (P.proj_data.damage_type)
			if (D_KINETIC,D_PIERCING,D_SLASHING)
				ArtifactStimulus("force", P.power)
				for (var/obj/machinery/networked/test_apparatus/impact_pad/I in loc.contents)
					I.impactpad_senseforce_shot(src, P)
			if (D_ENERGY)
				ArtifactStimulus("elec", P.power * 10)
			if (D_BURNING)
				ArtifactStimulus("heat", 310 + (P.power * 5))
			if (D_RADIOACTIVE)
				ArtifactStimulus("radiate", P.power)
		..()

	Bumped(M as mob|obj)
		if (istype(M,/obj/item))
			var/obj/item/ITM = M
			ArtifactStimulus("force", ITM.throwforce)
			for (var/obj/machinery/networked/test_apparatus/impact_pad/I in loc.contents)
				I.impactpad_senseforce(src, ITM)
		..()

/obj/machinery/artifact
	name = "artifact large art piece"
	icon = 'icons/obj/artifacts/artifacts.dmi'
	icon_state = "wizard-1" // it's technically pointless to set this but it makes it easier to find in the dreammaker tree
	opacity = 0
	density = 1
	anchored = 0
	artifact = 1
	mat_changename = 0
	mat_changedesc = 0
	var/associated_datum = /artifact/art

	New(var/loc, var/forceartitype)
		..()
		var/artifact/AS = new associated_datum(src)
		if (forceartitype)
			AS.validtypes = list("[forceartitype]")
		artifact = AS

		spawn (0)
			ArtifactSetup()

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

	process()
		..()
		if (!ArtifactSanityCheck())
			return
		var/artifact/A = artifact

		if (A.activated)
			A.effect_process(src)

	attack_hand(mob/user as mob)
		ArtifactTouched(user)
		return

	attack_ai(mob/user as mob)
		return attack_hand(user)

	attackby(obj/item/W as obj, mob/user as mob)
		if (Artifact_attackby(W,user))
			..()

	meteorhit(obj/O as obj)
		ArtifactStimulus("force", 60)
		..()

	ex_act(severity)
		switch(severity)
			if (1.0)
				ArtifactStimulus("force", 200)
				ArtifactStimulus("heat", 500)
			if (2.0)
				ArtifactStimulus("force", 75)
				ArtifactStimulus("heat", 450)
			if (3.0)
				ArtifactStimulus("force", 25)
				ArtifactStimulus("heat", 380)
		return

	reagent_act(reagent_id,volume)
		if (..())
			return
		if (!ArtifactSanityCheck())
			return
		var/artifact/A = artifact
		ArtifactStimulus(reagent_id, volume)
		switch(reagent_id)
			if ("radium","porktonium")
				ArtifactStimulus("radiate", round(volume / 10))
			if ("polonium","strange_reagent")
				ArtifactStimulus("radiate", round(volume / 5))
			if ("uranium")
				ArtifactStimulus("radiate", round(volume / 2))
			if ("dna_mutagen","mutagen","omega_mutagen")
				if (A.artitype == "martian")
					ArtifactDevelopFault(80)
			if ("napalm","dbreath","el_diablo")
				ArtifactStimulus("heat", 310 + (volume * 5))
			if ("infernite","foof","ghostchilijuice")
				ArtifactStimulus("heat", 310 + (volume * 10))
			if ("cryostylane")
				ArtifactStimulus("heat", 310 - (volume * 10))
			if ("acid")
				ArtifactTakeDamage(volume * 2)
			if ("pacid")
				ArtifactTakeDamage(volume * 10)
			if ("george_melonium")
				var/random_stimulus = pick("heat","force","radiate","elec")
				var/random_strength = 0
				switch(random_stimulus)
					if ("heat")
						random_strength = rand(200,400)
					if ("elec")
						random_strength = rand(5,5000)
					if ("force")
						random_strength = rand(3,30)
					if ("radiate")
						random_strength = rand(1,10)
				ArtifactStimulus(random_stimulus,random_strength)
		return

	emp_act()
		ArtifactStimulus("elec", 800)
		ArtifactStimulus("radiate", 3)

	blob_act(var/power)
		ArtifactStimulus("force", power)
		ArtifactStimulus("carbtouch", 1)

	bullet_act(var/obj/projectile/P)
		switch (P.proj_data.damage_type)
			if (D_KINETIC,D_PIERCING,D_SLASHING)
				ArtifactStimulus("force", P.power)
				if (istype(loc,/turf))
					for (var/obj/machinery/networked/test_apparatus/impact_pad/I in loc.contents)
						I.impactpad_senseforce_shot(src, P)
			if (D_ENERGY)
				ArtifactStimulus("elec", P.power * 10)
			if (D_BURNING)
				ArtifactStimulus("heat", P.power * 5)
			if (D_RADIOACTIVE)
				ArtifactStimulus("radiate", P.power)
		..()

	Bumped(M as mob|obj)
		if (istype(M,/obj/item))
			var/obj/item/ITM = M
			ArtifactStimulus("force", ITM.throwforce)
			for (var/obj/machinery/networked/test_apparatus/impact_pad/I in loc.contents)
				I.impactpad_senseforce(src, ITM)
		..()

/obj/item/artifact
	name = "artifact small art piece"
	icon = 'icons/obj/artifacts/artifactsitem.dmi'
	icon_state = "wizard-1"
	artifact = 1
	mat_changename = 0
	mat_changedesc = 0
	var/associated_datum = /artifact/art

	New(var/loc, var/forceartitype)
		var/artifact/AS = new associated_datum(src)
		if (forceartitype)
			AS.validtypes = list("[forceartitype]")
		artifact = AS

		spawn (0)
			ArtifactSetup()

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

/obj/artifact_spawner
	// pretty much entirely for debugging/gimmick use
	New(var/loc,var/forceartitype = null,var/cinematic = 0)
		var/turf/T = get_turf(src)
		if (cinematic)
			T.visible_message("<span style=\"color:red\"><strong>An artifact suddenly warps into existance!</strong></span>")
			playsound(T,"sound/effects/teleport.ogg",50,1)
			var/obj/decal/teleport_swirl/swirl = unpool(/obj/decal/teleport_swirl)
			swirl.set_loc(T)
			spawn (15)
				pool(swirl)
		Artifact_spawn (T,forceartitype)
		qdel(src)
		return