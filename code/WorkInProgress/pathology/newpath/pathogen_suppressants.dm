/**
 * Pathogen suppressants
 *
 * A well identifiable trait of each pathogen which inhibits its growth. The method of identification is through colour.
 * Suppression cannot completely cure a pathogen, however, its destructive potential may be severely limited by suppression.
 *
 * Suppressants may react to events the same way symptoms can - as suppressants are instantiated per pathogen, they may have their
 * own internal state without breaking anything.
 *
 * Suppressants also play a large role in the synthesis of cure for all default microbodies - each suppressant indicates a
 * list of reagents which may be used for cure synthesis. Curing therefore requires at least some analysis of the pathogen.
 */

/suppressant
	var/name = "Suppressant"
	var/color = "transparent"
	var/desc = "The pathogen is not suppressed by any external effects."
	var/therapy = "unknown"

	// A list of reagent IDs which may be used for cure synthesis with this suppressant.
	var/list/cure_synthesis = list()

	// Override this to define when your suppression method should act.
	// Returns the new value for suppressed which is ONLY considered if suppressed is 0.
	// Is not called if suppressed is -1. A secondary resistance may overpower a primary weakness.
	proc/suppress_act(var/pathogen/P)
		return

	proc/ongrab(var/mob/target as mob, var/pathogen/P)
		return
	proc/onpunched(var/mob/origin as mob, zone, var/pathogen/P)
	proc/onpunch(var/mob/target as mob, zone, var/pathogen/P )
	proc/ondisarm(var/mob/target as mob, isPushDown, var/pathogen/P)
	proc/onshocked(var/shockparam/param, var/pathogen/P)
	proc/onsay(message, var/pathogen/P)
	proc/onadd(var/pathogen/P)
	proc/onemote(var/mob/target, message, var/pathogen/P)

	// While doing pathogen research, the suppression method may define how the pathogen reacts to certain reagents.
	// Returns null if the pathogen does not react to the reagent.
	// Returns a string describing what happened if it does react to the reagent.
	// NOTE: Conforming with the new chemistry system, R is now a reagent ID, not a reagent instance.
	proc/react_to(var/R)
		return ""

	proc/may_react_to()
		return ""

/suppressant/heat
	color = "blue"
	name = "Heat"
	desc = "The pathogen is suppressed by a high body temperature."
	therapy = "thermal"

	cure_synthesis = list("napalm", "infernite")

	suppress_act(var/pathogen/P)
		if (P.infected.bodytemperature > 310 + P.suppression_threshold)
			if (P.stage > 3 && prob(P.advance_speed * 2))
				P.infected.show_message("<span style=\"color:blue\">You feel better.</span>")
				P.stage--
			return TRUE
		return FALSE

	may_react_to()
		return "A peculiar gland on the pathogen suggests it may be <b style='font-size:20px;color:red'>suppressed</strong> by affecting its temperature."

	react_to(var/R)
		if (R == "napalm" || R == "infernite")
			return "The pathogens are attemping to escape from the area affected by the [R]."
		else if (R in cure_synthesis)
			return "The pathogens are moving towards the area affected by the [R]"
		else return null

/suppressant/cold
	color = "red"
	name = "Cold"
	desc = "The pathogen is suppressed by a low body temperature."
	therapy = "thermal"

	cure_synthesis = list("cryostylane", "cryoxadone")

	suppress_act(var/pathogen/P)
		if (P.infected.bodytemperature < 300 - P.suppression_threshold)
			if (P.stage > 3 && prob(P.advance_speed * 2))
				P.infected.show_message("<span style=\"color:blue\">You feel better.</span>")
				P.stage--
			return TRUE
		return FALSE

	may_react_to()
		return "A peculiar gland on the pathogen suggests it may be <b style='font-size:20px;color:red'>suppressed</strong> by affecting its temperature."

	react_to(var/R)
		if (R == "napalm" || R == "infernite")
			return "The pathogens are moving towards the area affected by the [R]"
		else if (R in cure_synthesis)
			return "The pathogens are attemping to escape from the area affected by the [R]."
		else return null

/suppressant/sleeping
	color = "green"
	name = "Sedative"
	desc = "The pathogen is suppressed by sleeping."
	therapy = "sedative"

	suppress_act(var/pathogen/P)
		if (P.infected.sleeping)
			P.symptom_data["suppressant"]++
			var/slept = P.symptom_data["suppressant"]
			if (slept > P.suppression_threshold)
				if (P.stage > 3 && prob(P.advance_speed * 4))
					P.infected.show_message("<span style=\"color:blue\">You feel better.</span>")
					P.stage--
					P.symptom_data["suppressant"] = 0
				return TRUE
		else
			P.symptom_data["suppressant"] = 0
		return FALSE

	cure_synthesis = list("morphine", "sonambutril")

	onadd(var/pathogen/P)
		P.symptom_data["suppressant"] = 0

	may_react_to()
		return "Membrane patterns of the pathogen indicate it might be <b style='font-size:20px;color:red'>suppressed</strong> by a reagent affecting neural activity."

	react_to(var/R)
		if (R in cure_synthesis)
			return "The pathogens near the sedative appear to be in stasis."
		else return null

/suppressant/brutemeds
	color = "black"
	name = "Brute Medicine"
	desc = "The pathogen is suppressed by brute medicine."
	therapy = "medical"

	suppress_act(var/pathogen/P)
		if (P.infected.reagents.has_reagent("stypic_powder", P.suppression_threshold) || P.infected.reagents.has_reagent("synthflesh", P.suppression_threshold))
			if (P.stage > 3 && prob(P.advance_speed * 2))
				P.infected.show_message("<span style=\"color:blue\">You feel better.</span>")
				P.stage--
			return TRUE
		return FALSE

	cure_synthesis = list("stypic_powder", "synthflesh")

	may_react_to()
		return "The DNA repair processes of the pathogen indicate that it might be <b style='font-size:20px;color:red'>suppressed</strong> by certain kinds of medicine."

	react_to(var/R)
		if (R in cure_synthesis)
			return "The pathogens near the [R] appear to be weakened by the brute medicine's presence."
		else return null

/suppressant/burnmeds
	color = "cyan"
	name = "Burn Medicine"
	desc = "The pathogen is suppressed by burn medicine."
	therapy = "medical"

	suppress_act(var/pathogen/P)
		if (P.infected.reagents.has_reagent("silver_sulfadiazine", P.suppression_threshold))
			if (P.stage > 3 && prob(P.advance_speed * 2))
				P.infected.show_message("<span style=\"color:blue\">You feel better.</span>")
				P.stage--
			return TRUE
		return FALSE

	cure_synthesis = list("silver_sulfadiazine")

	may_react_to()
		return "The DNA repair processes of the pathogen indicate that it might be <b style='font-size:20px;color:red'>suppressed</strong> by certain kinds of medicine."

	react_to(var/R)
		if (R in cure_synthesis)
			return "The pathogens near the [R] appear to be weakened by the burn medicine's presence."
		else return null

/suppressant/muscle
	color = "white"
	name = "Muscle"
	desc = "The pathogen is suppressed by disrupting muscle function."
	therapy = "sedative"

	cure_synthesis = list("haloperidol", "neurotoxin")

	suppress_act(var/pathogen/P)
		if (P.infected.reagents.has_reagent("haloperidol", P.suppression_threshold) || P.infected.reagents.has_reagent("neurotoxin", P.suppression_threshold))
			if (P.stage > 3 && prob(P.advance_speed * 2))
				P.infected.show_message("<span style=\"color:blue\">You feel better.</span>")
				P.stage--
			return TRUE
		return FALSE

	onshocked(var/shockparam/param, var/pathogen/P)
		if (param.skipsupp)
			return
		if (P.stage > 3)
			var/better = 0
			if (param.amt > 50)
				P.stage = 3
			else if (param.amt > 30)
				if (prob(P.advance_speed * 2))
					P.stage = 3
				else
					P.stage--
			else if (param.amt > 15 && prob(P.advance_speed * 2))
				P.stage--
				better = 1
			if (param.amt > 30 || better)
				P.infected.show_message("<span style=\"color:blue\">You feel better.</span>")
		if (P.suppressed == 0)
			P.suppressed = 1

	may_react_to()
		return "Membrane patterns of the pathogen indicate it might be <b style='font-size:20px;color:red'>suppressed</strong> by a reagent affecting neural activity."

	react_to(var/R)
		if (R == "haloperidol")
			return "The pathogens near the [R] appear to move at a slower pace."
		if (R == "neurotoxin")
			return "The pathogens near the [R] appear to be confused."
		else return null

/suppressant/fat
	color = "orange"
	name = "Fat"
	desc = "The pathogen is suppressed by fats."
	cure_synthesis = list("bad_grease", "grease", "porktonium")
	therapy = "gastronomical"

	suppress_act(var/pathogen/P)
		if (P.infected.reagents.has_reagent("bad_grease", P.suppression_threshold) || P.infected.reagents.has_reagent("grease", P.suppression_threshold) || P.infected.reagents.has_reagent("porktonium", P.suppression_threshold))
			if (P.stage > 3 && prob(P.advance_speed * 2))
				P.infected.show_message("<span style=\"color:blue\">You feel better.</span>")
				P.stage--
			return TRUE
		return FALSE

	may_react_to()
		return "An observation of the metabolizing processes of the pathogen shows that it might be <b style='font-size:20px;color:red'>suppressed</strong> by certain kinds of foodstuffs."

	react_to(var/reagent/R)
		if (R in cure_synthesis)
			return "The pathogens near the fatty substance appear to be significantly heavier and slower than their unaffected counterparts."
		else return null

/suppressant/chickensoup
	color = "pink"
	name = "Chicken Soup"
	desc = "The pathogen is suppressed by a nice bowl of old fashioned chicken soup."
	therapy = "gastronomical"

	cure_synthesis = list("chickensoup")

	suppress_act(var/pathogen/P)
		if (P.infected.reagents.has_reagent("chickensoup", P.suppression_threshold))
			if (P.stage > 3 && prob(P.advance_speed * 2))
				P.infected.show_message("<span style=\"color:blue\">You feel better.</span>")
				P.stage--
			return TRUE
		return FALSE

	may_react_to()
		return "An observation of the metabolizing processes of the pathogen shows that it might be <b style='font-size:20px;color:red'>suppressed</strong> by certain kinds of foodstuffs."

	react_to(var/reagent/R)
		if (R == "chickensoup")
			return "The pathogens near the chicken soup appear to be having a great meal and are ignorant of their surroundings."

/suppressant/radiation
	color = "viridian"
	name = "Radiation"
	desc = "The pathogen is suppressed by radiation."
	therapy = "radioactive"

	cure_synthesis = list("radium", "polonium", "uranium")

	suppress_act(var/pathogen/P)
		if (P.infected.reagents.has_reagent("radium", P.suppression_threshold * 2) || P.infected.reagents.has_reagent("polonium", P.suppression_threshold) || P.infected.reagents.has_reagent("uranium", P.suppression_threshold * 10) || P.infected.get_radiation() > P.suppression_threshold * 0.1)
			if (P.stage > 3 && prob(P.advance_speed * 2))
				P.infected.show_message("<span style=\"color:blue\">You feel better.</span>")
				P.stage--
			return TRUE
		return FALSE

	may_react_to()
		return "The chemical structure of the pathogen's membrane indicates it may be <b style='font-size:20px;color:red'>suppressed</strong> by either gamma rays or mutagenic substances."

	react_to(var/reagent/R)
		if (R in cure_synthesis)
			return "The radiation emitted by the [R] is severely damaging the inner elements of the pathogen."

/suppressant/mutagen
	color = "olive drab"
	name = "Mutagen"
	desc = "The pathogen is suppressed by mutagenic substances."
	therapy = "radioactive"

	cure_synthesis = list("mutagen", "dna_mutagen")

	suppress_act(var/pathogen/P)
		if (P.infected.reagents.has_reagent("mutagen", P.suppression_threshold) || P.infected.reagents.has_reagent("dna_mutagen", P.suppression_threshold))
			if (P.stage > 3 && prob(P.advance_speed * 2))
				P.infected.show_message("<span style=\"color:blue\">You feel better.</span>")
				P.stage--
			return TRUE
		return FALSE

	may_react_to()
		return "The chemical structure of the pathogen's membrane indicates it may be <b style='font-size:20px;color:red'>suppressed</strong> by either gamma rays or mutagenic substances."

	react_to(var/reagent/R)
		if (R in cure_synthesis)
			return "The mutagenic substance is severely damaging the inner elements of the pathogen."

