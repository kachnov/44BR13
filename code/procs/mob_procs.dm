/mob/proc/find_in_hand(var/obj/item/I, var/this_hand) // for when you need to find a SPECIFIC THING and not just a type
	if (!I) // did we not get passed a thing to look for?
		return FALSE // fuck you
	if (!r_hand && !l_hand) // is there nothing in either hand?
		return FALSE

	if (this_hand) // were we asked to find a thing in a specific hand?
		if (this_hand == "right")
			if (r_hand && r_hand == I) // is there something in the right hand and is it the thing?
				return r_hand // say where we found it
			else
				return FALSE
		else if (this_hand == "left")
			if (l_hand && l_hand == I) // is there something in the left hand and is it the thing?
				return l_hand // say where we found it
			else
				return FALSE
		else
			return FALSE

	if (r_hand && r_hand == I) // is there something in the right hand and is it the thing?
		return r_hand // say where we found it
	else if (l_hand && l_hand == I) // is there something in the left hand and is it the thing?
		return l_hand // say where we found it
	else
		return FALSE // vOv

/mob/proc/find_type_in_hand(var/obj/item/I, var/this_hand) // for finding a thing of a type but not a specific instance
	if (!I)
		return FALSE
	if (!r_hand && !l_hand)
		return FALSE

	if (this_hand)
		if (this_hand == "right")
			if (r_hand && istype(r_hand, I))
				return r_hand
			else
				return FALSE
		else if (this_hand == "left")
			if (l_hand && istype(l_hand, I))
				return l_hand
			else
				return FALSE
		else
			return FALSE

	if (r_hand && istype(r_hand, I))
		return r_hand
	else if (l_hand && istype(l_hand, I))
		return l_hand
	else
		return FALSE // vOv

/mob/living/silicon/robot/find_in_hand(var/obj/item/I, var/this_hand)
	if (!I)
		return FALSE
	if (!module_states[3] && !module_states[2] && !module_states[1])
		return FALSE

	if (this_hand)
		if (this_hand == "right" || this_hand == 3)
			if (module_states[3] && module_states[3] == I)
				return TRUE
			else
				return FALSE
		else if (this_hand == "middle" || this_hand == 2)
			if (module_states[2] && module_states[2] == I)
				return TRUE
			else
				return FALSE
		else if (this_hand == "left" || this_hand == 1)
			if (module_states[1] && module_states[1] == I)
				return TRUE
			else
				return FALSE
		else
			return FALSE

	if (module_states[3] && module_states[3] == I)
		return module_states[3]
	else if (module_states[2] && module_states[2] == I)
		return module_states[2]
	else if (module_states[1] && module_states[1] == I)
		return module_states[1]
	else
		return FALSE

/mob/living/silicon/robot/find_type_in_hand(var/obj/item/I, var/this_hand)
	if (!I)
		return FALSE
	if (!module_states[3] && !module_states[2] && !module_states[1])
		return FALSE

	if (this_hand)
		if (this_hand == "right" || this_hand == 3)
			if (module_states[3] && istype(I, module_states[3]))
				return TRUE
			else
				return FALSE
		else if (this_hand == "middle" || this_hand == 2)
			if (module_states[2] && istype(I, module_states[2]))
				return TRUE
			else
				return FALSE
		else if (this_hand == "left" || this_hand == 1)
			if (module_states[1] && istype(I, module_states[1]))
				return TRUE
			else
				return FALSE
		else
			return FALSE

	if (module_states[3] && istype(I, module_states[3]))
		return module_states[3]
	else if (module_states[2] && istype(I, module_states[2]))
		return module_states[2]
	else if (module_states[1] && istype(I, module_states[1]))
		return module_states[1]
	else
		return FALSE

/mob/proc/put_in_hand_or_drop(var/obj/item/I)
	if (!I)
		return FALSE
	if (!put_in_hand(I))
		I.set_loc(get_turf(src))
		return TRUE
	return TRUE

// some procs moved out of ISN's stuff, just for some semblance of things not being scattered randomly through our WIP files

/mob/proc/irradiate(var/rad_strength,var/bypass_resistance = 0, var/cap = 0)
	if (!isnum(rad_strength))
		return FALSE

	var/final_rads = rad_strength

	if (istype(src, /mob/living/carbon/human))
		var/mob/living/carbon/human/H = src

		if (rad_strength >= 0 && H.bioHolder && H.bioHolder.HasEffect("rad_resist"))
			return FALSE

		//If the rad source has a cap we don't want to increase the current radiation amount beyond that
		if (cap > 0)
			if (H.radiation + rad_strength > cap) //Okay, this will overshoot the cap
				final_rads = max(0, cap - H.radiation) //Reduce the amount of radiation we inflict to not overshoot


		var/total_resistance = 0


		//boutput(world, "irradiation event on [H]")
		if (final_rads > 0 && !bypass_resistance)
			// if we're taking damage then calculate resistances, otherwise just pass it through and heal the rads
			if (H.wear_suit && H.wear_suit.radproof)
				total_resistance += 2
			else if (H.w_uniform && H.w_uniform.radproof)
				total_resistance += 1
			if (H.head && H.head.radproof)
				total_resistance += 1
			else if (H.wear_mask && H.wear_mask.radproof)
				total_resistance += 1
			if (H.shoes && H.shoes.radproof)
				total_resistance += 0.5
			if (H.gloves && H.gloves.radproof)
				total_resistance += 0.5
			if (H.bioHolder && H.bioHolder.HasEffect("radioactive"))
				total_resistance += 1

			//boutput(world, "calculated resistance is [total_resistance]")
			switch (total_resistance)
				if (-INFINITY to 0)
				if (1)
					final_rads *= 0.75
				if (2)
					final_rads *= 0.5
				if (3 to INFINITY)
					return FALSE
			final_rads = round(final_rads,1)

		//boutput(world, "adding [final_rads] to radiation")
		H.radiation += final_rads
		H.radiation = max(0,min(200,H.radiation))
		// this value clamps at 200 according to human.dm so lets take care of it here rather than in the loop,
		// less constant work going on that way
		return final_rads

	else
		// could add something in for borgs later on
		return FALSE

/mob/proc/can_slip(var/walking_matters = 1)
	return TRUE
	
/mob/living/carbon/human/var/list/slipped_on_things = list()

/mob/living/carbon/human/can_slip(var/walking_matters = 1, var/thing = null)
	if (!istype(src) || isxenomorph(src)) // if not human
		return FALSE // let's default to saying we can't
	if (walking_matters && (m_intent == "walk" || lying)) // if walking can make you not slip and we're walking or lying down
		return FALSE // we can't slip
	if (!shoes) // if we're not wearing shoes
		return can_slip_on_thing(thing) // we can slip
	if (shoes && (shoes.c_flags & NOSLIP)) // if we're wearing shoes that prevent slipping
		return FALSE // we can't slip
	return can_slip_on_thing(thing) // if all else fails, we can slip
	
/mob/living/carbon/human/proc/can_slip_on_thing(var/atom/thing)
	if (!thing || !thing.loc)
		return FALSE 
	if (!(thing in slipped_on_things))
		if (slipped_on_things.len >= 5)
			while (slipped_on_things.len >= 5)
				slipped_on_things -= slipped_on_things[slipped_on_things.len]
		slipped_on_things.Insert(1, thing)
		return TRUE 
	return FALSE

/mob/living/carbon/human/proc/skeletonize()
	if (!istype(src))
		return
	set_mutantrace(/mutantrace/skeleton)
	decomp_stage = 4
	if (organHolder && organHolder.brain)
		qdel(organHolder.brain)
	set_clothing_icon_dirty()

/mob/proc/show_text(var/message, var/color = "#000000", var/hearing_check = 0, var/sight_check = 0, var/allow_corruption = 0)
	if (!client || !istext(message) || !message)
		// if they're not logged in, save some cycles by not bothering
		return

	if (sight_check && !sight_check(1))
		return
	if (hearing_check && !hearing_check(1))
		return

	switch (color)
		if ("red") color = "#FF0000"
		if ("blue") color = "#0000FF"
		if ("green") color = "#008800" // we dont want FF for this because it's fucking unreadable against white

	boutput(src, "<span style='color: [color]'>[message]</span>")

/mob/proc/sight_check(var/consciousness_check = 0)
	return TRUE

/mob/living/carbon/human/sight_check(var/consciousness_check = 0)
	if (consciousness_check && (paralysis || sleeping || stat))
		return FALSE

	if (istype(glasses, /obj/item/clothing/glasses))
		var/obj/item/clothing/glasses/G = glasses
		if (G.allow_blind_sight)
			return TRUE
		if (G.block_vision)
			return FALSE

	if ((bioHolder && bioHolder.HasEffect("blind")) || blinded || get_eye_damage(1) || (organHolder && !organHolder.left_eye && !organHolder.right_eye))
		return FALSE

	return TRUE

/mob/living/critter/sight_check(var/consciousness_check = 0)
	if (consciousness_check && (paralysis || sleeping || stat))
		return FALSE
	return TRUE

/mob/proc/eyes_protected_from_light()
	return FALSE

/mob/living/carbon/human/eyes_protected_from_light()
	if (!sight_check(1)) // Blindness etc (Convair880).
		return TRUE
	if (glasses && istype(glasses, /obj/item/clothing/glasses/sunglasses))
		return TRUE
	if (eye_istype(/obj/item/organ/eye/cyber/thermal))
		return FALSE
	if (eye_istype(/obj/item/organ/eye/cyber/sunglass))
		return TRUE
	if (head && istype(head, /obj/item/clothing/head/helmet/welding) && !head:up)
		return TRUE
	return FALSE

/mob/proc/apply_flash()
	return

// We've had like 10+ code snippets for a variation of the same thing, now it's just one mob proc (Convair880).
/mob/living/apply_flash(var/animation_duration = 30, var/weak = 8, var/stun = 0, var/misstep = 0, var/eyes_blurry = 0, var/eyes_damage = 0, var/eye_tempblind = 0, var/burn = 0, var/uncloak_prob = 50)
	if (!src || !isliving(src) || isintangible(src) || istype(src, /mob/living/object))
		return
	if (animation_duration <= 0)
		return

	// Target checks.
	var/mod_animation = 0 // Note: these aren't multipliers.
	var/mod_weak = 0
	var/mod_stun = 0
	var/mod_misstep = 0
	var/mod_eyeblurry = 0
	var/mod_eyedamage = 0
	var/mod_eyetempblind = 0
	var/mod_burning = 0
	var/mod_uncloak = 0

	var/safety = 0
	if (eyes_protected_from_light())
		safety = 1

	if (safety == 0 && ishuman(src))
		var/mob/living/carbon/human/H = src
		var/hulk = 0
		if (H.bioHolder && H.bioHolder.HasEffect("hulk"))
			mod_weak = -INFINITY
			mod_stun = -INFINITY
			hulk = 1
		if ((H.glasses && istype(H.glasses, /obj/item/clothing/glasses/thermal)) || H.eye_istype(/obj/item/organ/eye/cyber/thermal))
			H.show_text("<strong>Your thermals intensify the bright flash of light, hurting your eyes quite a bit.</strong>", "red")
			mod_animation = 20
			if (hulk == 0)
				mod_weak = rand(1, 2)
			mod_eyeblurry = rand(4, 6)
			mod_eyedamage = rand(2, 3)

	// No negative values.
	animation_duration = max(0, animation_duration + mod_animation)
	weak = max(0, weak + mod_weak)
	stun = max(0, stun + mod_stun)
	misstep = max(0, misstep + mod_misstep)
	eyes_blurry = max(0, eyes_blurry + mod_eyeblurry)
	eyes_damage = max(0, eyes_damage + mod_eyedamage)
	eye_tempblind = max(0, eye_tempblind + mod_eyetempblind)
	burn = max(0, burn + mod_burning)
	uncloak_prob = max(0, uncloak_prob + mod_uncloak)

	if (animation_duration <= 0)
		return

	//DEBUG("Apply_flash() called for [src] at [log_loc(src)]. Safe: [safety == 1 ? "Y" : "N"], AD: [animation_duration], W: [weak], S: [stun], MS: [misstep], EB [eyes_blurry], ED: [eyes_damage], EB: [eye_tempblind], B: [burn], UP: [uncloak_prob]")

	// Stun target mob.
	if (safety == 0)
		flash(animation_duration)

		if (weakened < weak)
			weakened = weak
		if (stunned < stun)
			stunned = stun

		if (!issilicon(src))
			if (eyes_damage > 0)
				var/eye_dam = get_eye_damage()
				if ((eye_dam > 15 && prob(eye_dam + 50)))
					take_eye_damage(eyes_damage * 1.5)
				else
					take_eye_damage(eyes_damage)

			if (misstep_chance < misstep)
				change_misstep_chance(misstep)
			if (get_eye_blurry() < eyes_blurry)
				change_eye_blurry(eyes_blurry)
			if (eye_tempblind > 0)
				take_eye_damage(eye_tempblind, 1)

	// Certain effects apply regardless of eye protection.
	if (burn > 0)
		update_burning(burn)
		TakeDamage("head", 0, 5)
		updatehealth()

	if (prob(max(0, min(uncloak_prob, 100))))
		for (var/obj/item/cloaking_device/C in src)
			if (C.active)
				C.deactivate(src)
				visible_message("<span style=\"color:blue\"><strong>[src]'s cloak is disrupted!</strong></span>")
		for (var/obj/item/device/disguiser/D in src)
			if (D.on)
				D.disrupt(src)
				visible_message("<span style=\"color:blue\"><strong>[src]'s disguiser is disrupted!</strong></span>")

	return

/mob/proc/hearing_check(var/consciousness_check = 0)
	return TRUE

/mob/living/carbon/human/hearing_check(var/consciousness_check = 0)
	if (consciousness_check && (paralysis || sleeping || stat))
		// you may be physically capable of hearing it, but you're sure as hell not mentally able when you're out cold
		return FALSE

	if (istype(ears, /obj/item/device/radio/headset))
		var/obj/item/device/radio/headset/HS = ears
		if (HS.allow_deaf_hearing)
			return TRUE

	else if (istype(ears, /obj/item/clothing/ears))
		var/obj/item/clothing/ears/E = ears
		if (E.block_hearing)
			return FALSE

	if ((bioHolder && bioHolder.HasEffect("deaf")) || get_ear_damage(1))
		return FALSE

	return TRUE

/mob/living/silicon/hearing_check(var/consciousness_check = 0)
	if (consciousness_check && (paralysis || sleeping || stat))
		return FALSE

	if ((bioHolder && bioHolder.HasEffect("deaf")))
		return FALSE

	return TRUE

// Bit redundant at the moment, but we might get ear transplants at some point, who knows? Just put 'em here (Convair880).
/mob/proc/ears_protected_from_sound()
	return FALSE

/mob/living/carbon/human/ears_protected_from_sound()
	if (!hearing_check(1))
		return TRUE
	return FALSE

/mob/proc/apply_sonic_stun()
	return

// Similar concept to apply_flash(). One proc in place of a bunch of individually implemented code snippets (Convair880).
#define DO_NOTHING (!weak && !stun && !misstep && !slow && !drop_item && !ears_damage && !ear_tempdeaf)
/mob/living/apply_sonic_stun(var/weak = 0, var/stun = 8, var/misstep = 0, var/slow = 0, var/drop_item = 0, var/ears_damage = 0, var/ear_tempdeaf = 0)
	if (!src || !isliving(src) || isintangible(src) || istype(src, /mob/living/object))
		return
	if (DO_NOTHING)
		return

	// Target checks.
	var/mod_weak = 0 // Note: these aren't multipliers.
	var/mod_stun = 0
	var/mod_misstep = 0
	var/mod_slow = 0
	var/mod_drop = 0
	var/mod_eardamage = 0
	var/mod_eartempdeaf = 0

	if (ears_protected_from_sound())
		return

	if (ishuman(src))
		var/mob/living/carbon/human/H = src
		if (H.bioHolder && H.bioHolder.HasEffect("hulk"))
			mod_weak = -INFINITY
			mod_stun = -INFINITY

	// No negative values.
	weak = max(0, weak + mod_weak)
	stun = max(0, stun + mod_stun)
	misstep = max(0, misstep + mod_misstep)
	slow = max(0, slow + mod_slow)
	drop_item = max(0, drop_item + mod_drop)
	ears_damage = max(0, ears_damage + mod_eardamage)
	ear_tempdeaf = max(0, ear_tempdeaf + mod_eartempdeaf)

	if (DO_NOTHING)
		return

	//DEBUG("Apply_sonic_stun() called for [src] at [log_loc(src)]. W: [weak], S: [stun], MS: [misstep], SL: [slow], DI: [drop_item], ED: [ears_damage], EF: [ear_tempdeaf]")

	// Stun target mob.
	boutput(src, "<span style=\"color:red\"><strong>You hear an extremely loud noise!</strong></span>")

	if (weakened < weak)
		weakened = weak
	if (stunned < stun)
		stunned = stun

	if (!issilicon(src))
		if (ears_damage > 0)
			take_ear_damage(ears_damage)
		if (misstep_chance < misstep)
			change_misstep_chance(misstep)
		if (slowed < slow)
			slowed = slow
		if (ear_tempdeaf > 0)
			take_ear_damage(ear_tempdeaf, 1)

		if (weak == 0 && stun == 0 && prob(max(0, min(drop_item, 100))))
			show_message(__red("<strong>You drop what you were holding to clutch at your ears!</strong>"))
			drop_item()

	return
#undef DO_NOTHING

/mob/proc/is_mentally_dominated_by(var/mob/dominator)
	if (!dominator || !mind)
		return FALSE

	if (mind.master)
		var/mob/mymaster = whois_ckey_to_mob_reference(mind.master)
		if (mymaster && (mymaster == dominator))
			return TRUE

	return FALSE

/mob/proc/violate_hippocratic_oath()
	if (!mind)
		return FALSE

	mind.violated_hippocratic_oath = 1
	return TRUE

/proc/his_or_her(var/mob/subject)
	if (!subject)
		return "their"

	if (subject.gender == "male")
		return "his"
	else if (subject.gender == "female")
		return "her"
	else
		return "their"

/proc/him_or_her(var/mob/subject)
	if (!subject)
		return "their"

	if (subject.gender == "male")
		return "him"
	else if (subject.gender == "female")
		return "her"
	else
		return "their"

/proc/he_or_she(var/mob/subject)
	if (!subject)
		return "they"

	if (subject.gender == "male")
		return "he"
	else if (subject.gender == "female")
		return "she"
	else
		return "they"

/proc/himself_or_herself(var/mob/subject)
	if (!subject)
		return "themself"

	if (subject.gender == "male")
		return "himself"
	else if (subject.gender == "female")
		return "herself"
	else
		return "themself"

/mob/proc/get_explosion_resistance()
	return FALSE

/mob/living/carbon/human/get_explosion_resistance()
	// @todo

/mob/proc/spread_blood_clothes(mob/whose)
	return

/mob/living/carbon/human/spread_blood_clothes(mob/whose)
	if (!whose || !ismob(whose))
		return

	if (wear_mask)
		wear_mask.add_blood(whose)
	if (head)
		head.add_blood(whose)
	if (glasses && prob(33))
		glasses.add_blood(whose)
	if (prob(15))
		if (wear_suit)
			wear_suit.add_blood(whose)
		else if (w_uniform)
			w_uniform.add_blood(whose)

	update_clothing()
	update_body()
	return

/mob/proc/spread_blood_hands(mob/whose)
	return

/mob/living/carbon/human/spread_blood_hands(mob/whose)
	if (!whose || !ismob(whose))
		return

	if (gloves)
		gloves.add_blood(whose)
	else
		add_blood(whose)
	if (equipped())
		var/obj/item/I = equipped()
		if (istype(I))
			I.add_blood(whose)
	if (prob(15))
		if (wear_suit)
			wear_suit.add_blood(whose)
		else if (w_uniform)
			w_uniform.add_blood(whose)

	update_clothing()
	update_body()
	return

/mob/proc/is_bleeding()
	return FALSE

/mob/living/carbon/human/is_bleeding()
	return bleeding

/mob/proc/equipped_limb()
	return null

/mob/living/carbon/human/equipped_limb()
	if (!hand && limbs && limbs.r_arm)
		return limbs.r_arm.limb_data
	else if (hand && limbs && limbs.l_arm)
		return limbs.l_arm.limb_data
	return null

/mob/proc/process_stamina(var/cost)
	return TRUE

/mob/living/carbon/human/process_stamina(var/cost)
	if (!STAMINA_NO_ATTACK_CAP)
		// why
		// in what world is condition two not equivalent to condition one
		// there are literally two outcomes to this
		// if (true or true); and if (false or false)
		if (stamina <= cost || (stamina - cost) <= 0)
			boutput(src, STAMINA_EXHAUSTED_STR)
			return FALSE

	if (STAMINA_NO_ATTACK_CAP && stamina > STAMINA_MIN_ATTACK)
		remove_stamina(cost)
	else if (!STAMINA_NO_ATTACK_CAP)
		remove_stamina(cost)
	return TRUE

// This proc copies one mob's inventory to another. Why the separate entry? I don't wanna have to
// rip it out of unkillable_respawn () later for unforseeable reasons (Convair880).
/mob/living/carbon/human/proc/transfer_mob_inventory(var/mob/living/carbon/human/old, var/mob/living/carbon/human/newbody, var/copy_organs = 0, var/copy_limbs = 0, var/transfer_inventory = 1)
	if (!old || !newbody || !ishuman(old) || !ishuman(newbody))
		return

	spawn (20) // OrganHolders etc need time to initialize. Transferring inventory doesn't.
		if (copy_organs && old && newbody && old.organHolder && newbody.organHolder)
			if (old.organHolder.skull && (old.organHolder.skull.type != newbody.organHolder.skull.type))
				var/obj/item/organ/NO = new old.organHolder.skull.type(newbody)
				NO.donor = newbody
				var/DEL = newbody.organHolder.drop_organ("skull")
				qdel(DEL)
				newbody.organHolder.receive_organ(NO, "skull")
			// Prone to failure, don't enable.
			/*if (old.organHolder.brain && (old.organHolder.brain.type != newbody.organHolder.brain.type))
				var/obj/item/organ/NO2 = new old.organHolder.brain.type(newbody)
				NO2.donor = newbody
				var/DEL2 = newbody.organHolder.drop_organ("Brain")
				qdel(DEL2)
				newbody.organHolder.receive_organ(NO2, "Brain")*/
			if (old.organHolder.left_eye && (old.organHolder.left_eye.type != newbody.organHolder.left_eye.type))
				var/obj/item/organ/NO3 = new old.organHolder.left_eye.type(newbody)
				NO3.donor = newbody
				var/DEL3 = newbody.organHolder.drop_organ("left_eye")
				qdel(DEL3)
				newbody.organHolder.receive_organ(NO3, "left_eye")
			if (old.organHolder.right_eye && (old.organHolder.right_eye.type != newbody.organHolder.right_eye.type))
				var/obj/item/organ/NO4 = new old.organHolder.right_eye.type(newbody)
				NO4.donor = newbody
				var/DEL4 = newbody.organHolder.drop_organ("right_eye")
				qdel(DEL4)
				newbody.organHolder.receive_organ(NO4, "right_eye")
			if (old.organHolder.left_lung && (old.organHolder.left_lung.type != newbody.organHolder.left_lung.type))
				var/obj/item/organ/NO5 = new old.organHolder.left_lung.type(newbody)
				NO5.donor = newbody
				var/DEL5 = newbody.organHolder.drop_organ("left_lung")
				qdel(DEL5)
				newbody.organHolder.receive_organ(NO5, "left_lung")
			if (old.organHolder.right_lung && (old.organHolder.right_lung.type != newbody.organHolder.right_lung.type))
				var/obj/item/organ/NO6 = new old.organHolder.right_lung.type(newbody)
				NO6.donor = newbody
				var/DEL6 = newbody.organHolder.drop_organ("right_lung")
				qdel(DEL6)
				newbody.organHolder.receive_organ(NO6, "right_lung")
			if (old.organHolder.heart && (old.organHolder.heart.type != newbody.organHolder.heart.type))
				var/obj/item/organ/NO7 = new old.organHolder.heart.type
				NO7.donor = newbody
				var/DEL7 = newbody.organHolder.drop_organ("heart")
				qdel(DEL7)
				newbody.organHolder.receive_organ(NO7, "heart")
			if (old.organHolder.butt && (old.organHolder.butt.type != newbody.organHolder.butt.type))
				var/obj/item/organ/NO8 = new old.organHolder.butt.type(newbody)
				NO8.donor = newbody
				var/DEL8 = newbody.organHolder.drop_organ("butt")
				qdel(DEL8)
				newbody.organHolder.receive_organ(NO8, "butt")

		// Some mutantraces get powerful limbs and we generally don't want the player to keep them.
		if (copy_limbs && old && !old.mutantrace && newbody && old.limbs && newbody.limbs)
			if (old.limbs.l_arm && (old.limbs.l_arm.type != newbody.limbs.l_arm.type))
				if (istype(old.limbs.l_arm, /obj/item/parts/human_parts/arm/left/item))
					var/obj/item/parts/human_parts/arm/left/item/NL_item = new old.limbs.l_arm.type(newbody)
					if (old.limbs.l_arm.remove_object)
						var/obj/item/new_LAI = new old.limbs.l_arm.remove_object.type(NL_item)
						NL_item.set_item(new_LAI)
					NL_item.holder = newbody
					qdel(newbody.limbs.l_arm)
					newbody.limbs.l_arm = NL_item
				else
					var/obj/item/parts/NL = new old.limbs.l_arm.type(newbody)
					NL.holder = newbody
					qdel(newbody.limbs.l_arm)
					newbody.limbs.l_arm = NL
			if (old.limbs.r_arm && (old.limbs.r_arm.type != newbody.limbs.r_arm.type))
				if (istype(old.limbs.r_arm, /obj/item/parts/human_parts/arm/right/item))
					var/obj/item/parts/human_parts/arm/right/item/NL2_item = new old.limbs.r_arm.type(newbody)
					if (old.limbs.r_arm.remove_object)
						var/obj/item/new_RAI = new old.limbs.r_arm.remove_object.type(NL2_item)
						NL2_item.set_item(new_RAI)
					NL2_item.holder = newbody
					qdel(newbody.limbs.r_arm)
					newbody.limbs.r_arm = NL2_item
				else
					var/obj/item/parts/NL2 = new old.limbs.r_arm.type(newbody)
					NL2.holder = newbody
					qdel(newbody.limbs.r_arm)
					newbody.limbs.r_arm = NL2
			if (old.limbs.l_leg && (old.limbs.l_leg.type != newbody.limbs.l_leg.type))
				var/obj/item/parts/NL3 = new old.limbs.l_leg.type(newbody)
				NL3.holder = newbody
				qdel(newbody.limbs.l_leg)
				newbody.limbs.l_leg = NL3
			if (old.limbs.r_leg && (old.limbs.r_leg.type != newbody.limbs.r_leg.type))
				var/obj/item/parts/NL4 = new old.limbs.r_leg.type(newbody)
				NL4.holder = newbody
				qdel(newbody.limbs.r_leg)
				newbody.limbs.r_leg = NL4

	if (transfer_inventory && old && newbody)
		if (old.w_uniform)
			var/obj/item/CI = old.w_uniform
			var/obj/item/CI2 = old.belt
			var/obj/item/CI3 = old.wear_id
			var/obj/item/CI4 = old.l_store
			var/obj/item/CI5 = old.r_store

			if (old.belt)
				old.u_equip(CI2)
			if (old.wear_id)
				old.u_equip(CI3)
			if (old.l_store)
				old.u_equip(CI4)
			if (old.r_store)
				old.u_equip(CI5)

			old.u_equip(CI)
			newbody.equip_if_possible(CI, slot_w_uniform) // Has to be at the top of the list, naturally.
			if (CI2) newbody.equip_if_possible(CI2, slot_belt)
			if (CI3) newbody.equip_if_possible(CI3, slot_wear_id)
			if (CI4) newbody.equip_if_possible(CI4, slot_l_store)
			if (CI5) newbody.equip_if_possible(CI5, slot_r_store)

		if (old.wear_suit)
			var/obj/item/CI6 = old.wear_suit
			old.u_equip(CI6)
			newbody.equip_if_possible(CI6, slot_wear_suit)
		if (old.head)
			var/obj/item/CI7 = old.head
			old.u_equip(CI7)
			newbody.equip_if_possible(CI7, slot_head)
		if (old.wear_mask)
			var/obj/item/CI8 = old.wear_mask
			old.u_equip(CI8)
			newbody.equip_if_possible(CI8, slot_wear_mask)
		if (old.ears)
			var/obj/item/CI9 = old.ears
			old.u_equip(CI9)
			newbody.equip_if_possible(CI9, slot_ears)
		if (old.glasses)
			var/obj/item/CI10 = old.glasses
			old.u_equip(CI10)
			newbody.equip_if_possible(CI10, slot_glasses)
		if (old.gloves)
			var/obj/item/CI11 = old.gloves
			old.u_equip(CI11)
			newbody.equip_if_possible(CI11, slot_gloves)
		if (old.shoes)
			var/obj/item/CI12 = old.shoes
			old.u_equip(CI12)
			newbody.equip_if_possible(CI12, slot_shoes)
		if (old.back)
			var/obj/item/CI13 = old.back
			old.u_equip(CI13)
			newbody.equip_if_possible(CI13, slot_back)
		if (old.l_hand)
			var/obj/item/CI14 = old.l_hand
			old.u_equip(CI14)
			newbody.equip_if_possible(CI14, slot_l_hand)
		if (old.r_hand)
			var/obj/item/CI15 = old.r_hand
			old.u_equip(CI15)
			newbody.equip_if_possible(CI15, slot_r_hand)

	spawn (20) // Necessary.
		if (newbody)
			newbody.set_face_icon_dirty()
			newbody.set_body_icon_dirty()
			newbody.update_clothing()

	return

// Used to refresh the antagonist overlays certain mobs can see, such as admins, revs or Syndie robots (Convair880).
/mob/proc/antagonist_overlay_refresh(var/bypass_cooldown = 0, var/remove = 0)
	if (!bypass_cooldown && (last_overlay_refresh && world.time < last_overlay_refresh + 1200))
		return
	if (!(ticker && ticker.mode && ticker.current_state >= GAME_STATE_PLAYING))
		return
	if (!ismob(src) || !client || !mind)
		return

	if (remove)
		goto delete_overlays

	// Setup.
	var/list/can_see = list()
	var/see_traitors = 0
	var/see_nukeops = 0
	var/see_wizards = 0
	var/see_revs = 0
	var/see_xmas = 0
	var/see_special = 0 // Just a pass-through. Game mode-specific stuff is handled further down in the proc.
	var/see_everything = 0

	if (isadminghost(src))
		see_everything = 1
	else
		if (istype(ticker.mode, /game_mode/revolution))
			var/game_mode/revolution/R = ticker.mode
			var/list/mind/HR = R.head_revolutionaries
			var/list/mind/RR = R.revolutionaries
			if (mind in (HR + RR))
				see_revs = 1
		if (istype(ticker.mode, /game_mode/spy))
			var/game_mode/spy/S = ticker.mode
			var/list/L = S.leaders
			var/list/M = S.spies
			if (mind in (L + M))
				see_special = 1
		if (istype(ticker.mode, /game_mode/gang))
			var/game_mode/gang/G = ticker.mode
			var/list/L2 = G.leaders
			if (mind in L2)
				see_special = 1
		if (issilicon(src)) // We need to look for borged antagonists too.
			var/mob/living/silicon/S = src
			if (mind.special_role == "syndicate robot" || (S.syndicate && !S.dependent)) // No AI shells.
				see_traitors = 1
				see_nukeops = 1
				see_revs = 1
		if (mind && mind.special_role == "nukeop")
			see_nukeops = 1
		if (mind && mind.special_role == "wizard")
			see_wizards = 1
		if (mind && mind.special_role == "grinch")
			see_xmas = 1

	// Clear existing overlays.
	delete_overlays
	for (var/image/I in client.images)
		if (!I) continue
		if (I.icon == 'icons/mob/antag_overlays.dmi')
			//DEBUG("Deleted overlay ([I.icon_state]) from [src].")
			qdel(I)

	if (remove)
		return

	if (!see_traitors && !see_nukeops && !see_wizards && !see_revs && !see_xmas && !see_special && !see_everything)
		last_overlay_refresh = world.time
		return

	// Default antagonists that can appear in every game mode.
	var/list/mind/regular = ticker.mode.traitors
	var/list/mind/misc = ticker.mode.Agimmicks

	var/robot_override = 0 // Syndicate/emagged robot overlay overrides traitor etc for borged antagonists.

	for (var/mind/M in (regular + misc))
		robot_override = 0 // Gotta reset this.

		if (M.current && issilicon(M.current)) // We need to look for borged antagonists too.
			var/mob/living/silicon/S = M.current
			if (M.special_role == "syndicate robot" || (S.syndicate && !S.dependent)) // No AI shells.
				if (see_everything || see_traitors)
					if (!see_everything && S.stat == 2) continue
					var/I = image(antag_syndieborg, loc = M.current)
					can_see.Add(I)
					robot_override = 1
			if (M.special_role == "emagged robot" || (S.emagged && !S.dependent))
				if (see_everything)
					var/I = image(antag_emagged, loc = M.current)
					can_see.Add(I)
					robot_override = 1

		if (robot_override != 1)
			switch (M.special_role)
				if ("traitor", "hard-mode traitor")
					if (see_everything || see_traitors)
						if (M.current)
							if (!see_everything && isobserver(M.current)) continue
							var/I = image(antag_traitor, loc = M.current)
							can_see.Add(I)
				if ("changeling")
					if (see_everything)
						if (M.current)
							var/I = image(antag_changeling, loc = M.current)
							can_see.Add(I)
				if ("wizard")
					if (see_everything || see_wizards)
						if (M.current)
							if (!see_everything && isobserver(M.current)) continue
							var/I = image(antag_wizard, loc = M.current)
							can_see.Add(I)
				if ("vampire")
					if (see_everything)
						if (M.current)
							var/I = image(antag_vampire, loc = M.current)
							can_see.Add(I)
				if ("predator")
					if (see_everything)
						if (M.current)
							var/I = image(antag_predator, loc = M.current)
							can_see.Add(I)
				if ("werewolf")
					if (see_everything)
						if (M.current)
							var/I = image(antag_werewolf, loc = M.current)
							can_see.Add(I)
				if ("mindslave")
					if (see_everything)
						if (M.current)
							var/I = image(antag_mindslave, loc = M.current)
							can_see.Add(I)
				if ("vampthrall")
					if (see_everything)
						if (M.current)
							var/I = image(antag_vampthrall, loc = M.current)
							can_see.Add(I)
				if ("wraith")
					if (see_everything)
						if (M.current)
							var/I = image(antag_wraith, loc = M.current)
							can_see.Add(I)
				if ("blob")
					if (see_everything)
						if (M.current)
							var/I = image(antag_blob, loc = M.current)
							can_see.Add(I)
				if ("omnitraitor")
					if (see_everything)
						if (M.current)
							var/I = image(antag_omnitraitor, loc = M.current)
							can_see.Add(I)
				if ("wrestler")
					if (see_everything)
						if (M.current)
							var/I = image(antag_wrestler, loc = M.current)
							can_see.Add(I)
				if ("grinch")
					if (see_everything || see_xmas)
						if (M.current)
							if (!see_everything && isobserver(M.current)) continue
							var/I = image(antag_grinch, loc = M.current)
							can_see.Add(I)
				else
					if (see_everything)
						if (M.current)
							var/I = image(antag_generic, loc = M.current) // Default to this.
							can_see.Add(I)

	// Antagonists who generally only appear in certain game modes.
	if (istype(ticker.mode, /game_mode/revolution))
		var/game_mode/revolution/R = ticker.mode
		var/list/mind/HR = R.head_revolutionaries
		var/list/mind/RR = R.revolutionaries
		var/list/mind/heads = R.get_all_heads()

		if (see_revs || see_everything)
			for (var/mind/M in HR)
				if (M.current)
					if (!see_everything && isobserver(M.current)) continue
					var/I = image(antag_revhead, loc = M.current)
					can_see.Add(I)
			for (var/mind/M in RR)
				if (M.current)
					if (!see_everything && isobserver(M.current)) continue
					var/I = image(antag_rev, loc = M.current)
					can_see.Add(I)

		if (see_everything)
			for (var/mind/M in heads)
				if (M.current)
					var/I = image(antag_head, loc = M.current)
					can_see.Add(I)

	else if (istype(ticker.mode, /game_mode/nuclear))
		var/game_mode/nuclear/N = ticker.mode
		var/list/mind/syndicates = N.syndicates
		if (see_nukeops || see_everything)
			for (var/mind/M in syndicates)
				if (M.current)
					if (!see_everything && isobserver(M.current)) continue
					var/I = image(antag_syndicate, loc = M.current)
					can_see.Add(I)

	else if (istype(ticker.mode, /game_mode/spy))
		var/game_mode/spy/S = ticker.mode
		var/list/spies = S.spies
		if (see_everything)
			for (var/mind/M in S.leaders)
				if (M.current)
					var/I = image(antag_spyleader, loc = M.current)
					can_see.Add(I)
			for (var/mind/M in spies)
				if (M.current)
					var/I = image(antag_spyslave, loc = M.current)
					can_see.Add(I)

		else if (mind in spies)
			var/mind/leader_mind = spies[mind]
			if (istype(leader_mind) && leader_mind.current && !isobserver(leader_mind.current))
				var/I = image(antag_spyleader, loc = leader_mind.current)
				can_see.Add(I)

	else if (istype(ticker.mode, /game_mode/gang))
		var/game_mode/gang/G = ticker.mode
		if (see_everything)
			for (var/mind/M in G.leaders)
				if (M.current)
					var/I = image(antag_gang, loc = M.current)
					can_see.Add(I)
		for (var/mind/M in G.leaders)
			if (M.current)
				if (src in M.gang.members)
					if (!see_everything && isobserver(M.current)) continue
					var/I = image(antag_gang, loc = M.current)
					can_see.Add(I)

	if (can_see.len > 0)
		//logTheThing("debug", src, null, "<strong>Convair880 antag overlay:</strong> [can_see.len] added with parameters all ([see_everything]), T ([see_traitors]), S ([see_nukeops]), W ([see_wizards]), R ([see_revs]), SP ([see_special])")
		//DEBUG("Overlay parameters for [src]: all ([see_everything]), T ([see_traitors]), S ([see_nukeops]), W ([see_wizards]), R ([see_revs]), SP ([see_special])")
		//DEBUG("Added [can_see.len] overlays to [src].")
		client.images.Add(can_see)

	last_overlay_refresh = world.time
	return

// Avoids some C&P since multiple procs make use of this ability (Convair880).
/mob/proc/smash_through(var/obj/target, var/list/can_smash)
	if (!src || !ismob(src) || !target || !isobj(target))
		return FALSE

	if (!islist(can_smash) || !can_smash.len)
		return FALSE

	for (var/S in can_smash)
		if (S == "window" && istype(target, /obj/window))
			var/obj/window/W = target
			visible_message("<span style=\"color:red\">[src] smashes through the window.</span>", "<span style=\"color:blue\">You smash through the window.</span>")
			W.health = 0
			W.smash()
			return TRUE

		if (S == "grille" && istype(target, /obj/grille))
			var/obj/grille/G = target
			if (!G.shock(src, 70))
				G.visible_message("<span style=\"color:red\"><strong>[src]</strong> violently slashes [G]!</span>")
				playsound(G.loc, "sound/effects/grillehit.ogg", 80, 1)
				G.damage_slashing(15)
				return TRUE

		if (S == "door" && istype(target, /obj/machinery/door))
			var/obj/machinery/door/door = target
			door.tear_apart(src)
			return TRUE

	return FALSE

/mob/proc/saylist(var/message, var/list/heard, var/list/olocs, var/thickness, var/italics, var/list/processed, var/use_voice_name = 0)
	var/message_a

	message_a = say_quote(message)

	if (italics)
		message_a = "<em>[message_a]</em>"

	var/my_name = "<span class='name' data-ctx='\ref[mind]'>[voice_name]</span>"
	if (!use_voice_name)
		my_name = get_heard_name()
	var/rendered = "<span class='game say'>[my_name] <span class='message'>[message_a]</span></span>"

	var/rendered_outside = null
	if (olocs.len)
		var/atom/movable/OL = olocs[olocs.len]
		if (thickness < 0)
			rendered_outside = rendered
		else if (thickness == 0)
			rendered_outside = "<span class='game say'>[my_name] (on [bicon(OL)] [OL]) <span class='message'>[message_a]</span></span>"
		else if (thickness < 10)
			rendered_outside = "<span class='game say'>[my_name] (inside [bicon(OL)] [OL])  <span class='message'>[message_a]</span></span>"
		else if (thickness < 20)
			rendered_outside = "<span class='game say'>muffled <span class='name' data-ctx='\ref[mind]'>[voice_name]</span> (inside [bicon(OL)] [OL])  <span class='message'>[message_a]</span></span>"

	for (var/mob/M in heard)
		if (M in processed)
			continue
		processed += M
		var/thisR = rendered
		if (olocs.len && !(M.loc in olocs))
			if (rendered_outside)
				thisR = rendered_outside
			else
				continue
		if (M.client && M.client.holder && mind)
			thisR = "<span class='adminHearing' data-ctx='[M.client.chatOutput.ctxFlag]'>[thisR]</span>"
		M.heard_say(src)
		M.show_message(thisR, 2)

	return processed

/mob/proc/abuse_clown()
	return

/mob/living/carbon/human/abuse_clown()
	if (mind)
		if (mind.assigned_role == "Clown")
			score_clownabuse++