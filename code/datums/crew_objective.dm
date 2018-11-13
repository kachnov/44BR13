#ifdef CREW_OBJECTIVES

/controller/gameticker/proc
	generate_crew_objectives()
		set background = 1
		if (master_mode == "construction")
			return
		for (var/mind/crewMind in minds)
			if (prob(10)) generate_miscreant_objectives(crewMind)
			else generate_individual_objectives(crewMind)

		return

	generate_individual_objectives(var/mind/crewMind)
		set background = 1
		//Requirements for individual objectives: 1) You have a mind (this eliminates 90% of our playerbase ~heh~)
												//2) You are not a traitor
		if (!crewMind)
			return
		if (!crewMind.current || !crewMind.objectives || crewMind.objectives.len || crewMind.special_role || (crewMind.assigned_role == "MODE"))
			return

		var/rolePathString = ckey(crewMind.assigned_role)
		if (!rolePathString)
			return

		rolePathString = "/objective/crew/[rolePathString]"
		var/rolePath = text2path(rolePathString)
		if (isnull(rolePathString))
			return

		var/list/objectiveTypes = subtypesof(rolePath)
		if (!objectiveTypes.len)
			return

		var/obj_count = 1
		var/assignCount = min(rand(1,3), objectiveTypes.len)
		while (assignCount && objectiveTypes.len)
			assignCount--
			var/selectedType = pick(objectiveTypes)
			var/objective/crew/newObjective = new selectedType
			objectiveTypes -= newObjective.type

			newObjective.owner = crewMind
			crewMind.objectives += newObjective
			newObjective.setup()

			if (obj_count <= 1)
				boutput(crewMind.current, "<strong>Your OPTIONAL Crew Objectives are as follows:</strong>")
			boutput(crewMind.current, "<strong>Objective #[obj_count]</strong>: [newObjective.explanation_text]")
			obj_count++

		return

/*
 *	HOW-TO: Make Crew Objectives
 *	It's literally as simple as defining an objective of type "/objective/crew/[ckey(job title) goes here]/objective name"
 *	Please take note that it goes live as soon as you define it, so if it isn't ready you should probably comment it out!!
 */

/objective/crew
	proc/setup()

	captain
		hat
			explanation_text = "Don't lose your hat!"
			medal_name = "Hatris"
			check_completion()
				if (owner.current && owner.current.check_contents_for (/obj/item/clothing/head/caphat))
					return TRUE
				else
					return FALSE
		drunk
			explanation_text = "Have alcohol in your bloodstream at the end of the round."
			medal_name = "Edward Smith"
			check_completion()
				if (owner.current && owner.current.reagents && owner.current.reagents.has_reagent("ethanol"))
					return TRUE
				else
					return FALSE

	headofsecurity
		hat
			explanation_text = "Don't lose your hat/beret!"
			medal_name = "Hatris"
			check_completion()
				if (owner.current && owner.current.check_contents_for (/obj/item/clothing/head/helmet/HoS))
					return TRUE
				else
					return FALSE
		brig
			explanation_text = "Have at least one antagonist cuffed in the brig at the end of the round." //can be dead as people usually suicide
			medal_name = "Suitable? How about the Oubliette?!"
			check_completion()
				for (var/mind/M in ticker.minds)
					if (M.special_role && M.current && !istype(M.current,/mob/dead) && istype(get_area(M.current),/area/station/security/brig) && M.current.handcuffed) //think that's everything...
						return TRUE
				return FALSE
		centcom
			explanation_text = "Bring at least one antagonist back to CentCom in handcuffs for interrogation. You must accompany them on the escape shuttle." //can also be dead I guess
			medal_name = "Dead or alive, you're coming with me"
			check_completion()
				for (var/mind/M in ticker.minds)
					if (M.special_role && M.current && !istype(M.current,/mob/dead) && istype(get_area(M.current),/area/shuttle/escape/centcom) && M.current.handcuffed)
						if (owner.current && owner.current.stat != 2 && istype(get_area(owner.current),/area/shuttle/escape/centcom)) //split this up as it was long
							return TRUE
				return FALSE

	headofpersonnel
		vanish
			explanation_text = "End the round alive but not on the station or escape levels."
			medal_name = "Unperson"
			check_completion()
				if (owner.current && owner.current.stat != 2 && owner.current.z != 1 && owner.current.z != 2) return TRUE
				else return FALSE

	chiefengineer
		power
			explanation_text = "Ensure that all APCs are powered at the end of the round."
			medal_name = "1.21 Jiggawatts"
			check_completion()
				if (score_powerloss == 0) return TRUE
				else return FALSE
		furnaces
			explanation_text = "Make sure all furnaces on the station are active at the end of the round."
			medal_name = "Slow Burn"
			check_completion()
				for (var/obj/machinery/power/furnace/F in machines)
					if (F.z == 1 && F.active == 0)
						return FALSE
				return TRUE

//	securityofficer

	quartermaster
		profit
			explanation_text = "End the round with a budget of over 50,000 credits."
			medal_name = "Tax Haven"
			check_completion()
				if (wagesystem.shipping_budget > 50000) return TRUE
				else return FALSE

	detective
		drunk
			explanation_text = "Have alcohol in your bloodstream at the end of the round."
			medal_name = "Tipsy"
			check_completion()
				if (owner.current && owner.current.reagents && owner.current.reagents.has_reagent("ethanol"))
					return TRUE
				else
					return FALSE
		gear
			explanation_text = "Ensure that you are still wearing your coat, hat and uniform at the end of the round."
			medal_name = "Neither fashionable noir stylish"
			check_completion()
				if (owner.current && ishuman(owner.current))
					var/mob/living/carbon/human/H = owner.current
					if (istype(H.w_uniform, /obj/item/clothing/under/rank/det) && istype(H.wear_suit, /obj/item/clothing/suit/det_suit) && istype(H.head, /obj/item/clothing/head/det_hat)) return TRUE
				return FALSE
		smoke
			explanation_text = "Make sure you're smoking at the end of the round."
			medal_name = "Where's the smoking gun?"
			check_completion()
				if (owner.current && istype(owner.current.wear_mask,/obj/item/clothing/mask/cigarette)) return TRUE
				else return FALSE

	botanist
		mutantplants
			explanation_text = "Have at least three mutant plants alive at the end of the round."
			medal_name = "Bill Masen"
			check_completion()
				var/mutcount = 0
				for (var/obj/machinery/plantpot/PP in machines)
					if (PP.current)
						var/plantgenes/DNA = PP.plantgenes
						var/plantmutation/MUT = DNA.mutation
						if (MUT)
							mutcount++
							if (mutcount >= 3) return TRUE
				return FALSE
		noweed
			explanation_text = "Make sure there are no cannabis plants, seeds or products in Hydroponics at the end of the round."
			medal_name = "Reefer Madness"
			check_completion()
				for (var/obj/item/clothing/mask/cigarette/W in world)
					if (W.reagents.has_reagent("THC"))
						if (istype(get_area(W), /area/station/hydroponics) || istype(get_area(W), /area/station/hydroponics/lobby))
							return FALSE
				for (var/obj/item/plant/herb/cannabis/C in world)
					if (istype(get_area(C), /area/station/hydroponics) || istype(get_area(C), /area/station/hydroponics/lobby))
						return FALSE
				for (var/obj/item/seed/cannabis/S in world)
					if (istype(get_area(S), /area/station/hydroponics) || istype(get_area(S), /area/station/hydroponics/lobby))
						return FALSE
				for (var/obj/machinery/plantpot/PP in machines)
					if (PP.current && istype(PP.current, /plant/cannabis))
						if (istype(get_area(PP), /area/station/hydroponics) || istype(get_area(PP), /area/station/hydroponics/lobby))
							return FALSE
				return TRUE

	chaplain
		funeral
			explanation_text = "Have no corpses on the station level at the end of the round."
			medal_name = "Bury the Dead"
			check_completion()
				for (var/mob/living/carbon/human/H in mobs)
					if (H.z == 1 && H.stat == 2)
						return FALSE
				return TRUE

	janitor
		cleanbar
			explanation_text = "Make sure the bar is spotless at the end of the round."
			medal_name = "Spotless"
			check_completion()
				for (var/turf/T in get_area_turfs(/area/station/crew_quarters/bar, 0))
					for (var/obj/decal/cleanable/D in T)
						return FALSE
				return TRUE
		cleanmedbay
			explanation_text = "Make sure medbay is spotless at the end of the round."
			medal_name = "Spotless"
			check_completion()
				for (var/turf/T in get_area_turfs(/area/station/medical/medbay, 0))
					for (var/obj/decal/cleanable/D in T)
						return FALSE
				return TRUE
		cleanbrig
			explanation_text = "Make sure the brig is spotless at the end of the round."
			medal_name = "Spotless"
			check_completion()
				for (var/turf/T in get_area_turfs(/area/station/security/brig, 0))
					for (var/obj/decal/cleanable/D in T)
						return FALSE
				return TRUE

//	barman

//	chef

//	engineer

	miner
		// just fyi dont make a "gather ore" objective, it'd be a boring-ass grind (like mining is(dohohohoho))
		gems
			explanation_text = "Find at least ten gems between all miners."
			medal_name = "This object menaces with spikes of..."
			check_completion()
				if (score_gemsmined >= 10) return TRUE
				else return FALSE
		isa
			explanation_text = "Create at least three suits of Industrial Space Armor."
			medal_name = "40K"
			check_completion()
				var/suitcount = 0
				for (var/obj/item/clothing/suit/space/industrial/I in world)
					suitcount++
				if (suitcount > 2) return TRUE
				else return FALSE

	mechanic
		scanned
			explanation_text = "Have at least ten items scanned and researched in the ruckingenur at the end of the round."
			medal_name = "Man with a Scan"
			check_completion()
				if (mechanic_controls.scanned_items.len > 9) return TRUE
				else return FALSE
		teleporter
			explanation_text = "Ensure that there are at least two teleporters on the station level at the end of the round, excluding the science teleporter."
			medal_name = "It's not 'Door to Heaven'"
			check_completion()
				var/telecount = 0
				for (var/obj/machinery/teleport/portal_generator/S in machines) //really shitty, I know
					if (S.z != 1) continue
					for (var/obj/machinery/teleport/portal_ring/H in orange(2,S))
						for (var/obj/machinery/computer/teleporter/C in orange(2,S))
							telecount++
							break
				if (telecount > 1) return TRUE
				else return FALSE
/*
		cloner
			explanation_text = "Ensure that there are at least two cloners on the station level at the end of the round."
			check_completion()
				var/clonecount = 0
				for (var/obj/machinery/computer/cloning/C in machines) //ugh
					for (var/obj/machinery/dna_scannernew/D in orange(2,C))
						for (var/obj/machinery/clonepod/P in orange(2,C))
							clonecount++
							break
				if (clonecount > 1) return TRUE
				return FALSE
*/

	researchdirector
		heisenbee
			explanation_text = "Ensure that Heisenbee escapes on the shuttle."
			check_completion()
				for (var/obj/critter/domestic_bee/heisenbee/H in world)
					if (istype(get_area(H),/area/shuttle/escape/centcom) && H.alive)
						return TRUE
				return FALSE
		noscorch
			explanation_text = "Ensure that the floors of the chemistry lab are not scorched at the end of the round."
			medal_name = "We didn't start the fire"
			check_completion()
				for (var/turf/simulated/floor/T in get_area_turfs(/area/station/chemistry, 0))
					if (T.burnt == 1) return FALSE
				return TRUE
		hyper
			explanation_text = "Have methamphetamine in your bloodstream at the end of the round."
			medal_name = "Meth is a hell of a drug"
			check_completion()
				if (owner.current && owner.current.reagents && owner.current.reagents.has_reagent("methamphetamine"))
					return TRUE
				else
					return FALSE
		void
			explanation_text = "Create a portal to the void using the science teleporter."
			medal_name = "Where we're going, we won't need eyes to see"
			check_completion()
				for (var/obj/dfissure_to/F in world)
					if (F.z == 1) return TRUE
				return FALSE
		onfire
			explanation_text = "Escape on the shuttle alive while on fire with silver sulfadiazine in your bloodstream."
			medal_name = "Better to burn out, than fade away"
			check_completion()
				if (owner.current && owner.current.stat != 2 && ishuman(owner.current))
					var/mob/living/carbon/human/H = owner.current
					if (istype(get_area(H),/area/shuttle/escape/centcom) && H.burning > 1 && owner.current.reagents.has_reagent("silver_sulfadiazine")) return TRUE
					else return FALSE

	scientist
		noscorch
			explanation_text = "Ensure that the floors of the chemistry lab are not scorched at the end of the round."
			medal_name = "We didn't start the fire"
			check_completion()
				for (var/turf/simulated/floor/T in get_area_turfs(/area/station/chemistry, 0))
					if (T.burnt == 1) return FALSE
				return TRUE
		hyper
			explanation_text = "Have methamphetamine in your bloodstream at the end of the round."
			medal_name = "Meth is a hell of a drug"
			check_completion()
				if (owner.current && owner.current.reagents && owner.current.reagents.has_reagent("methamphetamine"))
					return TRUE
				else
					return FALSE
		void
			explanation_text = "Create a portal to the void using the science teleporter."
			medal_name = "Where we're going, we won't need eyes to see"
			check_completion()
				for (var/obj/dfissure_to/F in world)
					if (F.z == 1) return TRUE
				return FALSE
		onfire
			explanation_text = "Escape on the shuttle alive while on fire with silver sulfadiazine in your bloodstream."
			medal_name = "Better to burn out, than fade away"
			check_completion()
				if (owner.current && owner.current.stat != 2 && ishuman(owner.current))
					var/mob/living/carbon/human/H = owner.current
					if (istype(get_area(H),/area/shuttle/escape/centcom) && H.burning > 1 && owner.current.reagents.has_reagent("silver_sulfadiazine")) return TRUE
					else return FALSE

		/*artifact // This is going to be really fucking awkward to do so disabling for now
			explanation_text = "Activate at least one artifact on the station z level by the end of the round, excluding the test artifact."
			check_completion()
				for (var/obj/machinery/artifact/A in machines)
					if (A.z == 1 && A.activated == 1 && A.name != "Test Artifact") return TRUE //someone could label it I guess but I don't want to go adding an istestartifact var just for this..
				return FALSE*/

	medicaldirector // so much copy/pasted stuff  :(
		dr_acula
			explanation_text = "Ensure that Dr. Acula escapes on the shuttle."
			check_completion()
				for (var/obj/critter/bat/doctor/Dr in world)
					if (istype(get_area(Dr),/area/shuttle/escape/centcom) && Dr.alive)
						return TRUE
				return FALSE
		headsurgeon
			explanation_text = "Ensure that the Head Surgeon escapes on the shuttle."
			medal_name = "What's this box doing here?"
			check_completion()
				for (var/obj/machinery/bot/medbot/head_surgeon/H in world)
					if (istype(get_area(H),/area/shuttle/escape/centcom))
						return TRUE
				for (var/obj/item/clothing/suit/cardboard_box/head_surgeon/H in world)
					if (istype(get_area(H),/area/shuttle/escape/centcom))
						return TRUE
				for (var/obj/machinery/bot/medbot/head_surgeon/H in world)
					if (istype(get_area(H),/area/shuttle/escape/centcom))
						return TRUE
				return FALSE
		scanned
			explanation_text = "Have at least 5 people's DNA scanned in the cloning console at the end of the round."
			medal_name = "Life, uh... finds a way"
			check_completion()
				for (var/obj/machinery/computer/cloning/C in machines)
					if (C.records.len > 4)
						return TRUE
				return FALSE
		cyborgs
			explanation_text = "Ensure that there are at least three living cyborgs at the end of the round."
			medal_name = "Progenitor"
			check_completion()
				var/borgcount = 0
				for (var/mob/living/silicon/robot in mobs) //borgs gib when they die so no need to check stat I think
					borgcount ++
				if (borgcount > 2) return TRUE
				else return FALSE
		medibots
			explanation_text = "Have at least five medibots on the station level at the end of the round."
			medal_name = "Silent Running"
			check_completion()
				var/medbots = 0
				for (var/obj/machinery/bot/medbot/M in machines)
					if (M.z == 1)
						medbots++
				if (medbots > 4) return TRUE
				else return FALSE
		buttbots
			explanation_text = "Have at least five buttbots on the station level at the end of the round."
			medal_name = "Puerile humour"
			check_completion()
				var/buttbots = 0
				for (var/obj/machinery/bot/buttbot/B in machines)
					if (B.z == 1)
						buttbots ++
				if (buttbots > 4) return TRUE
				else return FALSE
		cryo
			explanation_text = "Ensure that both cryo cells are online and below 225K at the end of the round."
			medal_name = "It's frickin' freezing in here, Mr. Bigglesworth"
			check_completion()
				var/cryocount = 0
				for (var/obj/machinery/atmospherics/unary/cryo_cell/C in atmos_machines)
					if (C.on && C.air_contents.temperature < 225)
						cryocount ++
				if (cryocount > 1) return TRUE
				else return FALSE
		healself
			explanation_text = "Make sure you are completely unhurt when the escape shuttle leaves."
			medal_name = "Smooth Operator"
			check_completion()
				if (owner.current && owner.current.stat != 2 && (owner.current.get_brute_damage() + owner.current.get_oxygen_deprivation() + owner.current.get_burn_damage() + owner.current.get_toxin_damage()) == 0)
					return TRUE
				else
					return FALSE
		heal
			var/patchesused = 0
			explanation_text = "Use at least 10 medical patches on injured people."
			medal_name = "Patchwork"
			check_completion()
				if (patchesused > 9) return TRUE
				else return FALSE
		oath
			explanation_text = "Do not commit a violent act all round - punching someone, hitting them with a weapon or shooting them with a laser will all cause you to fail."
			medal_name = "Primum non nocere"
			check_completion()
				if (owner && owner.violated_hippocratic_oath)
					return FALSE
				else
					return TRUE

	geneticist
		scanned
			explanation_text = "Have at least 5 people's DNA scanned in the cloning console at the end of the round."
			medal_name = "Life, uh... finds a way"
			check_completion()
				for (var/obj/machinery/computer/cloning/C in machines)
					if (C.records.len > 4)
						return TRUE
				return FALSE
				/*
		power
			explanation_text = "Save a DNA sequence with at least one superpower onto a floppy disk and ensure it reaches CentCom."
			check_completion()
				for (var/obj/item/disk/data/floppy/F in world)
					if (F.data_type == "se" && F.data && istype(get_area(F),/area/shuttle/escape/centcom)) //prerequesites
						if (isblockon(getblock(F.data,XRAYBLOCK,3),8) || isblockon(getblock(F.data,FIREBLOCK,3),10) || isblockon(getblock(F.data,HULKBLOCK,3),2) || isblockon(getblock(F.data,TELEBLOCK,3),12))
							return TRUE
				return FALSE
				*/

	roboticist
		cyborgs
			explanation_text = "Ensure that there are at least three living cyborgs at the end of the round."
			medal_name = "Progenitor"
			check_completion()
				var/borgcount = 0
				for (var/mob/living/silicon/robot in mobs) //borgs gib when they die so no need to check stat I think
					borgcount ++
				if (borgcount > 2) return TRUE
				else return FALSE
		/*
		replicant
			explanation_text = "Make sure at least one replicant survives until the end of the round."
			medal_name = "Progenitor"
			check_completion()
				for (var/mob/living/silicon/robot/R in mobs)
					if (R.replicant)
						return TRUE
				return FALSE
		*/
		medibots
			explanation_text = "Have at least five medibots on the station level at the end of the round."
			medal_name = "Silent Running"
			check_completion()
				var/medbots = 0
				for (var/obj/machinery/bot/medbot/M in machines)
					if (M.z == 1)
						medbots++
				if (medbots > 4) return TRUE
				else return FALSE
		buttbots
			explanation_text = "Have at least five buttbots on the station level at the end of the round."
			medal_name = "Puerile humour"
			check_completion()
				var/buttbots = 0
				for (var/obj/machinery/bot/buttbot/B in machines)
					if (B.z == 1)
						buttbots ++
				if (buttbots > 4) return TRUE
				else return FALSE

	medicaldoctor
		cryo
			explanation_text = "Ensure that both cryo cells are online and below 225K at the end of the round."
			medal_name = "It's frickin' freezing in here, Mr. Bigglesworth"
			check_completion()
				var/cryocount = 0
				for (var/obj/machinery/atmospherics/unary/cryo_cell/C in atmos_machines)
					if (C.on && C.air_contents.temperature < 225)
						cryocount ++
				if (cryocount > 1) return TRUE
				else return FALSE
		healself
			explanation_text = "Make sure you are completely unhurt when the escape shuttle leaves."
			medal_name = "Smooth Operator"
			check_completion()
				if (owner.current && owner.current.stat != 2 && (owner.current.get_brute_damage() + owner.current.get_oxygen_deprivation() + owner.current.get_burn_damage() + owner.current.get_toxin_damage()) == 0)
					return TRUE
				else
					return FALSE
		heal
			var/patchesused = 0
			explanation_text = "Use at least 10 medical patches on injured people."
			medal_name = "Patchwork"
			check_completion()
				if (patchesused > 9) return TRUE
				else return FALSE
		oath
			explanation_text = "Do not commit a violent act all round - punching someone, hitting them with a weapon or shooting them with a laser will all cause you to fail."
			medal_name = "Primum non nocere"
			check_completion()
				if (owner && owner.violated_hippocratic_oath)
					return FALSE
				else
					return TRUE

	staffassistant
		butt
			explanation_text = "Have your butt removed somehow by the end of the round."
			medal_name = "I don't give a shit"
			check_completion()
				if (owner.current && ishuman(owner.current))
					var/mob/living/carbon/human/H = owner.current
					if (H.butt_op_stage == 4) return TRUE
				return FALSE
		wearbutt
			explanation_text = "Make sure that you are wearing your own butt on your head when the escape shuttle leaves."
			medal_name = "Shit for brains"
			check_completion()
				if (owner.current && owner.current.stat != 2 && ishuman(owner.current))
					var/mob/living/carbon/human/H = owner.current
					if (istype(get_area(H),/area/shuttle/escape/centcom) && H.head && H.head.name == "[H.real_name]'s butt") return TRUE
				return FALSE
		promotion
			explanation_text = "Escape on the shuttle alive with a non-assistant ID registered to you."
			medal_name = "Glass ceiling"
			check_completion()
				if (owner.current && owner.current.stat != 2 && ishuman(owner.current))
					var/mob/living/carbon/human/H = owner.current
					if (istype(get_area(H),/area/shuttle/escape/centcom) && H.wear_id && H.wear_id:registered == H.real_name && H.wear_id:assignment != ("Technical Assistant" || "Staff Assistant" || "Medical Assistant")) return TRUE
					else return FALSE
		clown
			explanation_text = "Escape on the shuttle alive wearing at least one piece of clown clothing."
			medal_name = "honk HONK mother FU-"
			check_completion()
				if (owner.current && ishuman(owner.current))
					var/mob/living/carbon/human/H = owner.current
					if (istype(H.wear_mask,/obj/item/clothing/mask/clown_hat) || istype(H.w_uniform,/obj/item/clothing/under/misc/clown) || istype(H.shoes,/obj/item/clothing/shoes/clown_shoes)) return TRUE
				return FALSE
		chompski
			explanation_text = "Ensure that Gnome Chompski escapes on the shuttle."
			medal_name = "Guardin' gnome"
			check_completion()
				for (var/obj/item/gnomechompski/G in world)
					if (istype(get_area(G),/area/shuttle/escape/centcom)) return TRUE
				return FALSE
		mailman
			explanation_text = "Escape on the shuttle alive wearing at least one piece of mailman clothing."
			medal_name = "The mail always goes through"
			check_completion()
				if (owner.current && ishuman(owner.current))
					var/mob/living/carbon/human/H = owner.current
					if (istype(H.w_uniform,/obj/item/clothing/under/misc/mail) || istype(H.head,/obj/item/clothing/head/mailcap)) return TRUE
				else return FALSE
		spacesuit
			explanation_text = "Get your grubby hands on a spacesuit."
			medal_name = "Vacuum Sealed"
			check_completion()
				if (owner.current)
					for (var/obj/item/clothing/suit/space/S in owner.current.contents)
						return TRUE
				return FALSE
		monkey
			explanation_text = "Escape on the shuttle alive as a monkey."
			medal_name = "Primordial"
			check_completion()
				if (owner.current && owner.current.stat != 2 && istype(get_area(owner.current),/area/shuttle/escape/centcom) && ismonkey(owner.current)) return TRUE
				else return FALSE

		headsurgeon
			explanation_text = "Ensure that the Head Surgeon escapes on the shuttle."
			medal_name = "What's this box doing here?"
			check_completion()
				for (var/obj/machinery/bot/medbot/head_surgeon/H in world)
					if (istype(get_area(H),/area/shuttle/escape/centcom))
						return TRUE
				for (var/obj/item/clothing/suit/cardboard_box/head_surgeon/H in world)
					if (istype(get_area(H),/area/shuttle/escape/centcom))
						return TRUE
				return FALSE

	//Keeping this around just in case some idiot gets a medal in an admin gimmick or something
	technicalassistant
		wearbutt
			explanation_text = "Make sure that you are wearing your own butt on your head when the escape shuttle leaves."
			medal_name = "Shit for brains"
			check_completion()
				if (owner.current && owner.current.stat != 2 && ishuman(owner.current))
					var/mob/living/carbon/human/H = owner.current
					if (istype(get_area(H),/area/shuttle/escape/centcom) && H.head && H.head.name == "[H.real_name]'s butt") return TRUE
				return FALSE
		mailman
			explanation_text = "Escape on the shuttle alive wearing at least one piece of mailman clothing."
			medal_name = "The mail always goes through"
			check_completion()
				if (owner.current && ishuman(owner.current))
					var/mob/living/carbon/human/H = owner.current
					if (istype(H.w_uniform,/obj/item/clothing/under/misc/mail) || istype(H.head,/obj/item/clothing/head/mailcap)) return TRUE
				else return FALSE
		promotion
			explanation_text = "Escape on the shuttle alive with a non-assistant ID registered to you."
			medal_name = "Glass ceiling"
			check_completion()
				if (owner.current && owner.current.stat != 2 && istype(get_area(owner.current),/area/shuttle/escape/centcom)) //checking basic stuff - they escaped alive and have an ID
					var/mob/living/carbon/human/H = owner.current
					if (H.wear_id && H.wear_id:registered == H.real_name && H.wear_id:assignment != ("Technical Assistant" || "Staff Assistant" || "Medical Assistant")) return TRUE
					else return FALSE
		spacesuit
			explanation_text = "Get your grubby hands on a spacesuit."
			medal_name = "Vacuum Sealed"
			check_completion()
				if (owner.current)
					for (var/obj/item/clothing/suit/space/S in owner.current.contents)
						return TRUE
				return FALSE

	medicalassistant
		monkey
			explanation_text = "Escape on the shuttle alive as a monkey."
			medal_name = "Primordial"
			check_completion()
				if (owner.current && owner.current.stat != 2 && istype(get_area(owner.current),/area/shuttle/escape/centcom) && ismonkey(owner.current)) return TRUE
				else return FALSE
		promotion
			explanation_text = "Escape on the shuttle alive with a non-assistant ID registered to you."
			medal_name = "Glass ceiling"
			check_completion()
				if (owner.current && owner.current.stat != 2 && istype(get_area(owner.current),/area/shuttle/escape/centcom)) //checking basic stuff - they escaped alive and have an ID
					var/mob/living/carbon/human/H = owner.current
					if (H.wear_id && H.wear_id:registered == H.real_name && H.wear_id:assignment != ("Technical Assistant" || "Staff Assistant" || "Medical Assistant")) return TRUE
					else return FALSE
		healself
			explanation_text = "Make sure you are completely unhurt when the escape shuttle leaves."
			medal_name = "Smooth Operator"
			check_completion()
				if (owner.current && owner.current.stat != 2 && (owner.current.get_brute_damage() + owner.current.get_oxygen_deprivation() + owner.current.get_burn_damage() + owner.current.get_toxin_damage()) == 0)
					return TRUE
				else
					return FALSE
		headsurgeon
			explanation_text = "Ensure that the Head Surgeon escapes on the shuttle."
			medal_name = "What's this box doing here?"
			check_completion()
				for (var/obj/machinery/bot/medbot/head_surgeon/H in world)
					if (istype(get_area(H),/area/shuttle/escape/centcom)) return TRUE
				for (var/obj/item/clothing/suit/cardboard_box/head_surgeon/H in world)
					if (istype(get_area(H),/area/shuttle/escape/centcom)) return TRUE
				return FALSE


//	cyborg

#endif