/proc/shakespearify(var/string)
	string = replacetext(string, "your ", "[pick("thy", "thine")] ")
	string = replacetext(string, " your", " [pick("thy", "thine")]")
	string = replacetext(string, " is ", " be ")
	string = replacetext(string, "you ", "thou ")
	string = replacetext(string, " you", " thou")
	string = replacetext(string, "are ", "art ")
	string = replacetext(string, " are", " art")
	string = replacetext(string, "does ", "doth ")
	string = replacetext(string, " does", " doth")
	string = replacetext(string, "do ", "doth ")
	string = replacetext(string, " do", " doth")
	string = replacetext(string, "she ", "the lady ")
	string = replacetext(string, " she", " the lady")
	string = replacetext(string, "i think", "methinks")
	return string

/mob/living/carbon/human/proc/become_ice_statue()
	var/obj/overlay/iceman = new /obj/overlay(get_turf(src))
	pixel_x = 0
	pixel_y = 0
	set_loc(iceman)
	iceman.name = "ice statue of [name]"
	iceman.desc = "We here at Space Station 13 believe in the transparency of our employees. It doesn't look like a functioning human can be retrieved from this."
	iceman.anchored = 0
	iceman.density = 1
	iceman.layer = MOB_LAYER
	iceman.dir = dir
	iceman.alpha = 128

	var/ist = "body_f"
	if (gender == "male")
		ist = "body_m"
	var/icon/composite = icon('icons/mob/human.dmi', ist, null, 1)
	for (var/O in overlays)
		var/image/I = O
		composite.Blend(icon(I.icon, I.icon_state, null, 1), ICON_OVERLAY)
	composite.ColorTone( rgb(165,242,243) ) // ice
	iceman.icon = composite
	take_toxin_damage(INFINITY)
	ghostize()

/proc/generate_random_pathogen()
	var/pathogen/P = unpool(/pathogen)
	P.setup(1, null, 0)
	return P

/proc/wrap_pathogen(var/reagents/reagents, var/pathogen/P, var/units = 5)
	reagents.add_reagent("pathogen", units)
	var/reagent/blood/pathogen/R = reagents.get_reagent("pathogen")
	if (R)
		R.pathogens[P.pathogen_uid] = P

/proc/ez_pathogen(var/stype)
	var/pathogen/P = unpool(/pathogen)
	var/pathogen_cdc/cdc = P.generate_name()
	cdc.mutations += P.name
	cdc.mutations[P.name] = P
	P.generate_components(cdc, 0)
	P.generate_attributes(0)
	P.mutativeness = 0
	P.mutation_speed = 0
	P.advance_speed = 6
	P.suppression_threshold = max(1, P.suppression_threshold)
	P.add_symptom(pathogen_controller.path_to_symptom[stype])
	logTheThing("pathology", null, null, "Pathogen [P.name] created by quick-pathogen-proc with symptom [stype].")
	return P
