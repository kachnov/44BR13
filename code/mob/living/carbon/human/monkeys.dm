
/mob/living/carbon/human/monkey //Please ignore how silly this path is.
	name = "monkey"

	New()
		..()
		spawn (5)
			if (!disposed)
				cust_one_state = "None"
				bioHolder.AddEffect("monkey")
				if (name == "monkey" || !name)
					name = pick(monkey_names)
				real_name = name

// special monkeys.
/mob/living/carbon/human/npc/monkey/mr_muggles
	name = "Mr. Muggles"
	real_name = "Mr. Muggles"
	gender = "male"
	New()
		..()
		spawn (10)
			equip_if_possible(new /obj/item/clothing/under/monkey/blue(src), slot_w_uniform)

/mob/living/carbon/human/npc/monkey/mrs_muggles
	name = "Mrs. Muggles"
	real_name = "Mrs. Muggles"
	gender = "female"
	New()
		..()
		spawn (10)
			equip_if_possible(new /obj/item/clothing/under/monkey/pink(src), slot_w_uniform)

/mob/living/carbon/human/npc/monkey/mr_rathen
	name = "Mr. Rathen"
	real_name = "Mr. Rathen"
	gender = "male"
	New()
		..()
		spawn (10)
			equip_if_possible(new /obj/item/clothing/under/monkey/yellow(src), slot_w_uniform)

/mob/living/carbon/human/npc/monkey/albert
	name = "Albert"
	real_name = "Albert"
	gender = "male"
	New()
		..()
		spawn (10)
			equip_if_possible(new /obj/item/clothing/suit/space/monkey(src), slot_wear_suit)

/mob/living/carbon/human/npc/monkey/von_braun
	name = "Von Braun"
	real_name = "Von Braun"
	gender = "male"
	New()
		..()
		spawn (10)
			equip_if_possible(new /obj/item/clothing/suit/space/monkey/syndicate(src), slot_wear_suit)

/mob/living/carbon/human/npc/monkey/horse
	name = "????"
	real_name = "????"
	gender = "male"
	New()
		..()
		spawn (10)
			equip_if_possible(new /obj/item/clothing/mask/monkey/horse_mask(src), slot_wear_mask)

/mob/living/carbon/human/npc/monkey/tanhony
	name = "Tanhony"
	real_name = "Tanhony"
	gender = "female"
	New()
		..()
		spawn (10)
			equip_if_possible(new /obj/item/clothing/head/monkey/paper_hat(src), slot_head)

/mob/living/carbon/human/npc/monkey/krimpus
	name = "Krimpus"
	real_name = "Krimpus"
	gender = "female"
	New()
		..()
		spawn (10)
			equip_if_possible(new /obj/item/clothing/under/monkey/green(src), slot_w_uniform)

/mob/living/carbon/human/npc/monkey // :getin:
	name = "monkey"
	ai_aggressive = 0
	ai_calm_down = 1
	ai_default_intent = INTENT_HELP
	var/list/shitlist = list()
	var/ai_aggression_timeout = 600

	New()
		..()
		spawn (5)
			if (!disposed)
				bioHolder.mobAppearance.customization_first = "None"
				cust_one_state = "None"
				bioHolder.AddEffect("monkey")
				if (name == "monkey" || !name)
					name = pick(monkey_names)
				real_name = name

	ai_action()
		if (ai_aggressive)
			return ..()

		if (ai_state == 2 && done_with_you(ai_target))
			return
		..()
		if (ai_state == 0)
			if (prob(10))
				ai_pickpocket()
			else if (prob(10))
				ai_knock_from_hand()

	ai_findtarget_new()
		if (ai_aggressive || ai_aggression_timeout == 0 || (world.timeofday - ai_threatened) < ai_aggression_timeout)
			..()

	was_harmed(var/mob/M as mob, var/obj/item/weapon as obj)
		//ai_aggressive = 1
		target = M
		ai_state = 2
		ai_threatened = world.timeofday
		ai_target = M
		shitlist[M] ++
		if (prob(40))
			emote("scream")
		var/pals = 0
		for (var/mob/living/carbon/human/npc/monkey/pal in all_viewers(7, src))
			if (pals >= 5)
				return
			if (prob(10))
				continue
			//pal.ai_aggressive = 1
			pal.target = M
			pal.ai_state = 2
			pal.ai_threatened = world.timeofday
			pal.ai_target = M
			pal.shitlist[M] ++
			pals ++
			if (prob(40))
				emote("scream")

	proc/done_with_you(var/mob/M as mob)
		if (!M)
			return FALSE
		if (health <= 0)
			target = null
			ai_state = 0
			ai_target = null
			ai_frustration = 0
			walk_towards(src,null)
			return TRUE
		if (shitlist[M] && shitlist[M] > 10)
			return FALSE
		if ((M.health <= 0) || (get_dist(src, M) >= 7))
			target = null
			ai_state = 0
			ai_target = null
			ai_frustration = 0
			walk_towards(src,null)
			return TRUE
		else
			return FALSE

	proc/ai_pickpocket()
		if (weakened || stunned || paralysis || stat || ai_picking_pocket)
			return
		var/list/possible_targets = list()
		for (var/mob/living/carbon/human/H in view(1, src))
			if (istype(H, /mob/living/carbon/human/npc/monkey))
				continue
			if (!H.l_store && !H.r_store)
				continue
			possible_targets += H
		if (!possible_targets.len)
			return
		var/mob/living/carbon/human/theft_target = pick(possible_targets)
		var/obj/item/thingy
		var/slot = 15
		if (theft_target.l_store && theft_target.r_store)
			thingy = pick(theft_target.l_store, theft_target.r_store)
			if (thingy == theft_target.r_store)
				slot = 16
		else if (theft_target.l_store)
			thingy = theft_target.l_store
		else if (theft_target.r_store)
			thingy = theft_target.r_store
			slot = 16
		else // ???
			return
		walk_towards(src, null)
		actions.start(new/action/bar/icon/filthyPickpocket(src, theft_target, slot), src)

	proc/ai_knock_from_hand()
		if (weakened || stunned || paralysis || stat || ai_picking_pocket || r_hand)
			return
		var/list/possible_targets = list()
		for (var/mob/living/carbon/human/H in view(1, src))
			if (istype(H, /mob/living/carbon/human/npc/monkey))
				continue
			if (!H.l_hand && !H.r_hand)
				continue
			possible_targets += H
		if (!possible_targets.len)
			return
		var/mob/living/carbon/human/theft_target = pick(possible_targets)
		walk_towards(src, null)
		a_intent = INTENT_DISARM
		theft_target.attack_hand(src)
		a_intent = ai_default_intent

/action/bar/icon/filthyPickpocket
	id = "pickpocket"
	interrupt_flags = INTERRUPT_MOVE | INTERRUPT_ACT | INTERRUPT_STUNNED | INTERRUPT_ACTION
	icon = 'icons/mob/screen1.dmi'
	icon_state = "grabbed"

	var/mob/living/carbon/human/npc/source  //The npc doing the action
	var/mob/living/carbon/human/target  	//The target of the action
	var/slot						    	//The slot number

	New(var/Source, var/Target, var/Slot)
		source = Source
		target = Target
		slot = Slot

		var/obj/item/I = target.get_slot(slot)
		if (I)
			if (I.duration_remove > 0)
				duration = I.duration_remove
			else
				duration = 25
		..()

	onStart()
		..()

		target.add_fingerprint(source) // Added for forensics (Convair880).
		var/obj/item/I = target.get_slot(slot)

		if (!I)
			source.show_text("There's nothing in that slot.", "red")
			interrupt(INTERRUPT_ALWAYS)
			return

		if (!I.handle_other_remove(source, target))
			source.show_text("[I] can not be removed.", "red")
			interrupt(INTERRUPT_ALWAYS)
			return

		logTheThing("combat", source, target, "tries to pickpocket \an [I] from %target%")

		for (var/mob/O in AIviewers(owner))
			O.show_message("<strong>[source]</strong> rifles through [target]'s pockets!", 1)

		source.ai_picking_pocket = 1

	onEnd()
		..()

		if (get_dist(source, target) > 1 || target == null || source == null)
			interrupt(INTERRUPT_ALWAYS)
			return

		var/obj/item/I = target.get_slot(slot)

		if (I.handle_other_remove(source, target))
			logTheThing("combat", source, target, "successfully pickpockets \an [I] from %target%!")
			for (var/mob/O in AIviewers(owner))
				O.show_message("<strong>[source]</strong> grabs [I] from [target]'s pockets!", 1)
			target.u_equip(I)
			I.dropped(target)
			I.layer = initial(I.layer)
			I.add_fingerprint(source)
			source.put_in_hand_or_drop(I)
		else
			source.show_text("You fail to remove [I] from [target].", "red")

		source.ai_picking_pocket = 0

	onUpdate()
		..()
		if (get_dist(source, target) > 1 || target == null || source == null)
			interrupt(INTERRUPT_ALWAYS)
			return

		if (!target.get_slot(slot=slot))
			interrupt(INTERRUPT_ALWAYS)

	onInterrupt()
		..()
		source.ai_picking_pocket = 0
