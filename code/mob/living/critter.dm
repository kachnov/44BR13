/mob/living/critter
	name = "critter"
	desc = "A beastie!"
	icon = 'icons/misc/critter.dmi'
	icon_state = "lavacrab"
	var/icon_state_dead = "lavacrab-dead"
	abilityHolder = /abilityHolder/critter

	var/hud/critter/hud

	var/hand_count = 0		// Used to ease setup. Setting this in-game has no effect.
	var/list/hands = list()
	var/list/equipment = list()
	var/image/equipment_image = new
	var/image/burning_image = new
	var/burning_suffix = "generic"
	var/active_hand = 0		// ID of the active hand

	var/can_burn = 1
	var/can_throw = 0
	var/can_choke = 0
	var/in_throw_mode = 0

	var/can_help = 0
	var/can_grab = 0
	var/can_disarm = 0

	var/metabolizes = 1

	var/reagent_capacity = 50
	max_health = 0
	health = 0

	var/ultravision = 0
	var/tranquilizer_resistance = 0
	explosion_resistance = 0

	var/list/inhands = list()
	var/list/healthlist = list()

	New()
	
		if (ispath(abilityHolder))
			abilityHolder = new abilityHolder(src)
//		if (ispath(default_task))
//			default_task = new default_task
//		if (ispath(current_task))
//			current_task = new current_task

		setup_hands()
		post_setup_hands()
		setup_equipment_slots()
		setup_reagents()
		setup_healths()
		if (!healthlist.len)
			message_coders("ALERT: Critter [type] ([name]) does not have health holders.")
		count_healths()

		hud = new(src)
		attach_hud(hud)
		zone_sel = new(src, "CENTER[hud.next_right()], SOUTH")
		attach_hud(zone_sel)

		for (var/equipmentHolder/EE in equipment)
			EE.after_setup(hud)

		burning_image.icon = 'icons/misc/critter.dmi'
		burning_image.icon_state = null

		updatehealth()

		..()

	proc/setup_healths()
		// add_health_holder(/healthHolder/flesh)
		// etc..

	proc/add_health_holder(var/T)
		var/healthHolder/HH = new T
		if (!istype(HH))
			return null
		if (HH.associated_damage_type in healthlist)
			var/healthHolder/OH = healthlist[HH.associated_damage_type]
			if (OH.type == T)
				return OH
			return null
		HH.holder = src
		healthlist[HH.associated_damage_type] = HH
		return HH

	proc/get_health_percentage()
		var/hp = 0
		for (var/T in healthlist)
			var/healthHolder/HH = healthlist[T]
			if (HH.count_in_total)
				hp += HH.value
		if (max_health > 0)
			return hp / max_health
		return FALSE

	proc/count_healths()
		max_health = 0
		health = 0
		for (var/T in healthlist)
			var/healthHolder/HH = healthlist[T]
			if (HH.count_in_total)
				max_health += HH.maximum_value
				health += HH.maximum_value

	// begin convenience procs
	proc/add_hh_flesh(var/min, var/max, var/mult)
		var/healthHolder/Brute = add_health_holder(/healthHolder/flesh)
		Brute.maximum_value = max
		Brute.value = max
		Brute.last_value = max
		Brute.damage_multiplier = mult
		Brute.depletion_threshold = min
		Brute.minimum_value = min
		return Brute

	proc/add_hh_flesh_burn(var/min, var/max, var/mult)
		var/healthHolder/Burn = add_health_holder(/healthHolder/flesh_burn)
		Burn.maximum_value = max
		Burn.value = max
		Burn.last_value = max
		Burn.damage_multiplier = mult
		Burn.depletion_threshold = min
		Burn.minimum_value = min
		return Burn

	proc/add_hh_robot(var/min, var/max, var/mult)
		var/healthHolder/Brute = add_health_holder(/healthHolder/structure)
		Brute.maximum_value = max
		Brute.value = max
		Brute.last_value = max
		Brute.damage_multiplier = mult
		Brute.depletion_threshold = min
		Brute.minimum_value = min
		return Brute

	proc/add_hh_robot_burn(var/min, var/max, var/mult)
		var/healthHolder/Burn = add_health_holder(/healthHolder/wiring)
		Burn.maximum_value = max
		Burn.value = max
		Burn.last_value = max
		Burn.damage_multiplier = mult
		Burn.depletion_threshold = min
		Burn.minimum_value = min
		return Burn

	// end convenience procs

	on_reagent_react(var/reagents/R, var/method = 1, var/react_volume)
		for (var/T in healthlist)
			var/healthHolder/HH = healthlist[T]
			HH.on_react(R, method, react_volume)

	proc/equip_click(var/equipmentHolder/EH)
		if (!handcheck())
			return
		var/obj/item/I = equipped()
		var/obj/item/W = EH.item
		if (I && W)
			W.attackby(I)
		else if (I)
			if (EH.can_equip(I))
				u_equip(I)
				EH.equip(I)
				hud.add_object(I, HUD_LAYER+2, EH.screenObj.screen_loc)
			else
				boutput(src, "<span style='color:red'>You cannot equip [I] in that slot!</span>")
			update_clothing()
		else if (W)
			if (!EH.remove())
				boutput(src, "<span style='color:red'>You cannot remove [W] from that slot!</span>")
			update_clothing()

	proc/handcheck()
		if (!hand_count)
			return FALSE
		if (!active_hand)
			return FALSE
		if (hands.len >= active_hand)
			return TRUE
		return FALSE

	attackby(var/obj/item/I, var/mob/M)
		var/rv = 1
		for (var/T in healthlist)
			var/healthHolder/HH = healthlist[T]
			rv = min(HH.on_attack(I, M), rv)
		if (!rv)
			return
		else
			..()

	// The throw code is a direct copy-paste from humans
	// pending better solution.
	proc/toggle_throw_mode()
		if (in_throw_mode)
			throw_mode_off()
		else
			throw_mode_on()

	proc/throw_mode_off()
		in_throw_mode = 0
		update_cursor()
		hud.update_throwing()

	proc/throw_mode_on()
		if (!can_throw)
			return
		in_throw_mode = 1
		update_cursor()
		hud.update_throwing()

	proc/throw_item(atom/target)
		if (!can_throw)
			return
		throw_mode_off()
		if (usr.stat)
			return

		var/atom/movable/item = equipped()

		if (istype(item, /obj/item) && item:cant_self_remove)
			return

		if (!item) return

		u_equip(item)

		if (istype(item, /obj/item/grab))
			var/obj/item/grab/grab = item
			var/mob/M = grab.affecting
			if (grab.state < 1 && !(M.paralysis || M.weakened || M.stat))
				visible_message("<span style=\"color:red\">[M] stumbles a little!</span>")
				qdel(grab)
				return
			M.lastattacker = src
			M.lastattackertime = world.time
			item = M
			qdel(grab)

		item.set_loc(loc)

		if (istype(item, /obj/item))
			item:dropped(src) // let it know it's been dropped

		//actually throw it!
		if (item)
			item.layer = initial(item.layer)
			visible_message("<span style=\"color:red\">[src] throws [item].</span>")
			if (iscarbon(item))
				var/mob/living/carbon/C = item
				logTheThing("combat", src, C, "throws %target% at [log_loc(src)].")
				if ( ishuman(C) )
					C.weakened = max(weakened, 1)
			else
				// Added log_reagents() call for drinking glasses. Also the location (Convair880).
				logTheThing("combat", src, null, "throws [item] [item.is_open_container() ? "[log_reagents(item)]" : ""] at [log_loc(src)].")
			if (istype(loc, /turf/space)) //they're in space, move em one space in the opposite direction
				inertia_dir = get_dir(target, src)
				step(src, inertia_dir)
			if (istype(item.loc, /turf/space) && istype(item, /mob))
				var/mob/M = item
				M.inertia_dir = get_dir(src,target)
			item.throw_at(target, item.throw_range, item.throw_speed)

	click(atom/target, list/params)
		if ((in_throw_mode || params.Find("shift")) && can_throw)
			throw_item(target)
			return
		return ..()

	update_cursor()
		if (((client && client.check_key("shift")) || in_throw_mode) && can_throw)
			set_cursor('icons/cursors/throw.dmi')
			return
		return ..()

	update_clothing()
		//overlays -= equipment_image
		equipment_image.overlays.len = 0
		for (var/equipmentHolder/EH in equipment)
			EH.on_update()
			if (EH.item)
				var/obj/item/I = EH.item
				var/image/w_image = I.wear_image
				w_image.icon_state = "[I.icon_state]"
				w_image.layer = EH.equipment_layer
				w_image.alpha = I.alpha
				w_image.color = I.color
				w_image.pixel_x = EH.offset_x
				w_image.pixel_y = EH.offset_y
				equipment_image.overlays += w_image
		UpdateOverlays(equipment_image, "equipment")

	find_in_equipment(var/eqtype)
		for (var/equipmentHolder/EH in equipment)
			if (EH.item && istype(EH.item, eqtype))
				return EH.item
		return null

	find_in_hands(var/eqtype)
		for (var/handHolder/HH in equipment)
			if (HH.item && istype(HH.item, eqtype))
				return HH.item
		return null

	is_in_hands(var/obj/O)
		for (var/handHolder/HH in equipment)
			if (HH.item && HH.item == O)
				return TRUE
		return FALSE

	swap_hand()
		if (!handcheck())
			return
		if (active_hand < hands.len)
			active_hand++
			hand = active_hand
		else
			active_hand = 1
			hand = active_hand
		hud.update_hands()

	hand_range_attack(atom/target, params)
		var/handHolder/ch = get_active_hand()
		if (ch && ch.can_range_attack && ch.limb)
			ch.limb.attack_range(target, src, params)
			ch.set_cooldown_overlay()

	hand_attack(atom/target, params)
		var/limb/L = equipped_limb()
		var/handHolder/HH = get_active_hand()
		if (!L || !HH)
			boutput(src, "<span style='color:red'>You have no limbs to attack with!</span>")
			return
		if (!HH.can_attack && HH.can_range_attack)
			hand_range_attack(target, params)
		else if (HH.can_attack)
			if (ismob(target))
				switch (a_intent)
					if (INTENT_HELP)
						if (can_help)
							L.help(target, src)
					if (INTENT_DISARM)
						if (can_disarm)
							L.disarm(target, src)
					if (INTENT_HARM)
						if (HH.can_attack)
							L.harm(target, src)
					if (INTENT_GRAB)
						if (HH.can_hold_items && can_grab)
							L.grab(target, src)
			else
				L.attack_hand(target, src)
				HH.set_cooldown_overlay()
		else
			boutput(src, "<span style='color:red'>You cannot attack with your [HH.name]!</span>")

	proc/melee_attack_human(var/mob/living/carbon/human/M, var/extra_damage) // non-special limb attack
		if (M.nodamage)
			visible_message("<strong><span style='color:red'>[src]'s attack bounces uselessly off [M]!</span></strong>")
			playsound_local(M, "punch", 50, 0)
			return
		visible_message("<strong><span style='color:red'>[src] punches [M]!</span></strong>")
		playsound_local(M, "punch", 50, 0)
		M.TakeDamageAccountArmor(zone_sel.selecting, rand(3,6), 0, 0, DAMAGE_BLUNT)

	can_strip()
		var/handHolder/HH = get_active_hand()
		if (!HH)
			return FALSE
		if (HH.can_hold_items)
			return TRUE
		else
			boutput(src, "<span style='color:red'>You cannot strip other people with your [HH.name].</span>")

	attack_hand(var/mob/living/M)
		switch (M.a_intent)
			if (INTENT_HELP)
				visible_message("<strong><span style='color:blue'>[M] pets [src]!</span></strong>")
			if (INTENT_DISARM)
				actions.interrupt(src, INTERRUPT_ATTACKED)
				if (hands.len)
					M.disarm(src)
			if (INTENT_HARM)
				actions.interrupt(src, INTERRUPT_ATTACKED)
				if (isxenomorph(M) || ismutt(M))
					var/mob/living/carbon/human/H = M
					H.melee_attack(src)
				else
					TakeDamage(M.zone_sel.selecting, rand(1,3), 0)
					playsound_local(src, "punch", 50, 0)
					visible_message("<strong><span style='color:red'>[M] punches [src]!</span></strong>")
			if (INTENT_GRAB)
				visible_message("<strong><span style='color:red'>[M] attempts to grab [src] but it is not implemented yet!</span></strong>")

	proc/get_active_hand()
		if (!handcheck())
			return null
		return hands[active_hand]

	equipped_limb()
		var/handHolder/HH = get_active_hand()
		if (HH)
			return HH.limb
		return null

	proc/setup_hands()
		if (hand_count)
			for (var/i = 1, i <= hand_count, i++)
				var/handHolder/HH = new
				HH.holder = src
				hands += HH
			active_hand = 1
			hand = active_hand

	proc/post_setup_hands()
		if (hand_count)
			for (var/handHolder/HH in hands)
				if (!HH.limb)
					HH.limb = new /limb
				HH.spawn_dummy_holder()

	proc/setup_equipment_slots()

	proc/setup_reagents()
		reagent_capacity = max(0, reagent_capacity)
		var/reagents/R = new(reagent_capacity)
		R.my_atom = src
		reagents = R

	equipped()
		if (active_hand)
			if (hands.len >= active_hand)
				var/handHolder/HH = hands[active_hand]
				return HH.item
		return null

	u_equip(var/obj/item/I)
		var/inhand = 0
		var/clothing = 0
		for (var/handHolder/HH in hands)
			if (HH.item == I)
				HH.item = null
				hud.remove_object(I)
				inhand = 1
		if (inhand)
			update_inhands()
		for (var/equipmentHolder/EH in equipment)
			if (EH.item == I)
				EH.item = null
				hud.remove_object(I)
				clothing = 1
		if (clothing)
			update_clothing()

	put_in_hand(obj/item/I, t_hand)
		if (!hands.len)
			return FALSE
		if (t_hand)
			if (t_hand > hands.len)
				return FALSE
			var/handHolder/HH = hands[t_hand]
			if (HH.item || !HH.can_hold_items)
				return FALSE
			HH.item = I
			hud.add_object(I, HUD_LAYER+2, HH.screenObj.screen_loc)
			update_inhands()
			return TRUE
		else if (active_hand)
			var/handHolder/HH = hands[active_hand]
			if (HH.item || !HH.can_hold_items)
				return FALSE
			HH.item = I
			hud.add_object(I, HUD_LAYER+2, HH.screenObj.screen_loc)
			update_inhands()
			return TRUE
		return FALSE

	Life(controller/process/mobs/parent)
		if (..(parent))
			return TRUE

		if (burning)
			if (isturf(loc))
				var/turf/location = loc
				location.hotspot_expose(T0C + 100 + burning * 3, 400)
			var/damage = 1
			if (burning > 66)
				damage = 3
			else if (burning > 33)
				damage = 2
			TakeDamage("All", 0, damage)
			update_burning(-2)

		if (stat == 2)
			return FALSE

		if (get_eye_blurry())
			change_eye_blurry(-1)

		if (drowsyness)
			drowsyness = max(0, drowsyness - 1)
			if (drowsyness >= tranquilizer_resistance)
				change_eye_blurry(2)
				if (prob(5 + drowsyness - tranquilizer_resistance))
					sleeping = 2
					paralysis = 5

		handle_hud_overlays()
		antagonist_overlay_refresh(0, 0)

		if (paralysis || stunned || weakened)
			canmove = 0
		else
			canmove = 1

		if (sleeping)
			sleeping = max(0, sleeping - 1)
			paralysis = max(1, paralysis)

		var/may_deliver_recovery_warning = (paralysis || stunned || weakened)

		if (may_deliver_recovery_warning)
			empty_hands()
			actions.interrupt(src, INTERRUPT_STUNNED)

		if (paralysis)
			if (stat < 1)
				stat = 1
			paralysis = max(0, paralysis-2)
		else if (stat == 1)
			stat = 0

		if (stunned)
			stunned = max(0, stunned-2)

		if (weakened)
			weakened = max(0, weakened-2)

		if (stuttering)
			stuttering = max(0, stuttering-2)

		if (may_deliver_recovery_warning && max(max(paralysis, weakened), stunned) <= 2)
			boutput(src, "<span style='color:green'>You begin to recover</span>")

		if (reagents && metabolizes)
			reagents.metabolize(src)

		for (var/T in healthlist)
			var/healthHolder/HH = healthlist[T]
			HH.Life()

		for (var/obj/item/grab/G in src)
			G.process()

		if (stat)
			return FALSE

//		if (!client && istype(current_task))


	proc/handle_hud_overlays()
		var/color_mod_r = 255
		var/color_mod_g = 255
		var/color_mod_b = 255
		if (druggy)
			vision.animate_color_mod(rgb(rand(0, 255), rand(0, 255), rand(0, 255)), 15)
		else
			vision.set_color_mod(rgb(color_mod_r, color_mod_g, color_mod_b))

		if (!sight_check(1) && stat != 2)
			addOverlayComposition(/overlayComposition/blinded) //ov1
		else
			removeOverlayComposition(/overlayComposition/blinded) //ov1
		vision.animate_dither_alpha(get_eye_blurry() / 10 * 255, 15)
		return TRUE

	death(var/gibbed)
		density = 0
		if (!gibbed)
			visible_message("<span style=\"color:red\"><strong>[src]</strong> dies!</span>")
			stat = 2
			icon_state = icon_state_dead
		else
			empty_hands()
			drop_equipment()
		hud.update_health()

	proc/get_health_holder(var/assoc)
		if (assoc in healthlist)
			return healthlist[assoc]
		return null

	TakeDamage(zone, brute, burn)
		hit_twitch()
		if (nodamage)
			return
		var/healthHolder/Br = get_health_holder("brute")
		if (Br)
			Br.TakeDamage(brute)
		var/healthHolder/Bu = get_health_holder("burn")
		if (Bu && !is_heat_resistant())
			Bu.TakeDamage(burn)
		updatehealth()

	take_brain_damage(var/amount)
		if (..())
			return TRUE
		if (nodamage)
			return
		var/healthHolder/Br = get_health_holder("brain")
		if (Br)
			Br.TakeDamage(amount)
		return FALSE

	take_toxin_damage(var/amount)
		if (..())
			return TRUE
		if (nodamage)
			return
		var/healthHolder/Tx = get_health_holder("toxin")
		if (Tx)
			Tx.TakeDamage(amount)
		return FALSE

	take_oxygen_deprivation(var/amount)
		if (..())
			return TRUE
		if (nodamage)
			return
		var/healthHolder/Ox = get_health_holder("oxy")
		if (Ox)
			Ox.TakeDamage(amount)
		return FALSE

	get_brain_damage()
		var/healthHolder/Br = get_health_holder("brain")
		if (Br)
			return Br.maximum_value - Br.value

	get_toxin_damage()
		var/healthHolder/Tx = get_health_holder("toxin")
		if (Tx)
			return Tx.maximum_value - Tx.value

	get_oxygen_deprivation()
		var/healthHolder/Ox = get_health_holder("oxy")
		if (Ox)
			return Ox.maximum_value - Ox.value

	lose_breath(var/amount)
		if (..())
			return TRUE
		var/healthHolder/suffocation/Ox = get_health_holder("oxy")
		if (!istype(Ox))
			return FALSE
		Ox.lose_breath(amount)
		return FALSE

	HealDamage()
		..()
		updatehealth()

	updatehealth()
		if (nodamage)
			if (health != max_health)
				full_heal()
			health = max_health
			stat = 0
			icon_state = initial(icon_state)
		else
			health = max_health
			for (var/T in healthlist)
				var/healthHolder/HH = healthlist[T]
				if (HH.count_in_total)
					health -= (HH.maximum_value - HH.value)
		hud.update_health()
		if (health <= 0 && stat < 2)
			death()

	proc/specific_emotes(var/act, var/param = null, var/voluntary = 0)
		return null

	proc/specific_emote_type(var/act)
		return TRUE

	update_inhands()
		inhands.len = 0
		for (var/handHolder/HH in hands)
			var/obj/item/I = HH.item
			if (!I)
				continue
			if (!I.inhand_image)
				I.inhand_image = image(I.inhand_image_icon, "", HH.render_layer)
			I.inhand_image.icon_state = I.item_state ? "[I.item_state][HH.suffix]" : "[I.icon_state][HH.suffix]"
			I.inhand_image.pixel_x = HH.offset_x
			I.inhand_image.pixel_y = HH.offset_y
			I.inhand_image.layer = HH.render_layer
			inhands += I.inhand_image
		if (stat != 2)
			UpdateOverlays(inhands, "inhands")

	proc/empty_hands()
		for (var/handHolder/HH in hands)
			if (HH.item)
				if (istype(HH.item, /obj/item/grab))
					qdel(HH.item)
					continue
				var/obj/item/I = HH.item
				I.loc = loc
				I.master = null
				I.layer = initial(I.layer)
				u_equip(I)

	proc/drop_equipment()
		for (var/equipmentHolder/EH in equipment)
			if (EH.item)
				EH.drop(1)

	emote(var/act, var/voluntary = 0)
		var/param = null

		if (findtext(act, " ", 1, null))
			var/t1 = findtext(act, " ", 1, null)
			param = copytext(act, t1 + 1, length(act) + 1)
			act = copytext(act, 1, t1)

		var/message = specific_emotes(act, param, voluntary)
		var/m_type = specific_emote_type(act)
		if (!message)
			switch (lowertext(act))
				if ("gasp")
					if (emote_check(voluntary, 10))
						message = "<strong>[src]</strong> gasps."
				if ("cough")
					if (emote_check(voluntary, 10))
						message = "<strong>[src]</strong> coughs."
				if ("laugh")
					if (emote_check(voluntary, 10))
						message = "<strong>[src]</strong> laughs."
				if ("giggle")
					if (emote_check(voluntary, 10))
						message = "<strong>[src]</strong> giggles."
				if ("flip")
					if (emote_check(voluntary, 50) && !shrunk)
						if (istype(loc,/obj))
							var/obj/container = loc
							boutput(src, "<span style=\"color:red\">You leap and slam your head against the inside of [container]! Ouch!</span>")
							paralysis += 2
							weakened += 4
							container.visible_message("<span style=\"color:red\"><strong>[container]</strong> emits a loud thump and rattles a bit.</span>")
							playsound(loc, "sound/effects/bang.ogg", 50, 1)
							var/wiggle = 6
							while (wiggle > 0)
								wiggle--
								container.pixel_x = rand(-3,3)
								container.pixel_y = rand(-3,3)
								sleep(1)
							container.pixel_x = 0
							container.pixel_y = 0
							if (prob(33))
								if (istype(container, /obj/storage))
									var/obj/storage/C = container
									if (C.can_flip_bust == 1)
										boutput(src, "<span style=\"color:red\">[C] [pick("cracks","bends","shakes","groans")].</span>")
										C.bust_out()
						else
							message = "<strong>[src]</strong> does a flip!"
							if (prob(50))
								animate_spin(src, "R", 1, 0)
							else
								animate_spin(src, "L", 1, 0)
		if (message)
			logTheThing("say", src, null, "EMOTE: [message]")
			if (m_type & 1)
				for (var/mob/O in viewers(src, null))
					O.show_message(message, m_type)
			else if (m_type & 2)
				for (var/mob/O in hearers(src, null))
					O.show_message(message, m_type)
			else if (!isturf(loc))
				var/atom/A = loc
				for (var/mob/O in A.contents)
					O.show_message(message, m_type)


	talk_into_equipment(var/mode, var/message, var/param)
		switch (mode)
			if ("left hand")
				for (var/i = 1, i <= hands.len, i++)
					var/handHolder/HH = hands[i]
					if (HH.can_hold_items)
						if (HH.item)
							HH.item.talk_into(src, message, param, real_name)
						return
			if ("right hand")
				for (var/i = hands.len, i >= 1, i--)
					var/handHolder/HH = hands[i]
					if (HH.can_hold_items)
						if (HH.item)
							HH.item.talk_into(src, message, param, real_name)
						return
			else
				..()

	update_burning()
		if (can_burn)
			..()

	update_burning_icon(var/old_burning)
		if (!burning)
			UpdateOverlays(null, "burning")
			return
		else if (burning < 33)
			burning_image.icon_state = "fire1_[burning_suffix]"
		else if (burning < 66)
			burning_image.icon_state = "fire2_[burning_suffix]"
		else
			burning_image.icon_state = "fire3_[burning_suffix]"
		UpdateOverlays(burning_image, "burning")

	get_head_armor_modifier()
		var/armor_mod = 0
		for (var/equipmentHolder/EH in equipment)
			if ((EH.armor_coverage & HEAD) && istype(EH.item, /obj/item/clothing))
				var/obj/item/clothing/C = EH.item
				armor_mod = max(C.armor_value_melee, armor_mod)
		return armor_mod

	get_chest_armor_modifier()
		var/armor_mod = 0
		for (var/equipmentHolder/EH in equipment)
			if ((EH.armor_coverage & TORSO) && istype(EH.item, /obj/item/clothing))
				var/obj/item/clothing/C = EH.item
				armor_mod = max(C.armor_value_melee, armor_mod)
		return armor_mod

	full_heal()
		..()
		icon_state = initial(icon_state)
		density = 1

	does_it_metabolize()
		return metabolizes

	is_heat_resistant()
		if (!get_health_holder("burn"))
			return TRUE
		return FALSE

	get_explosion_resistance()
		var/ret = explosion_resistance
		for (var/equipmentHolder/EH in equipment)
			if (EH.armor_coverage & TORSO)
				var/obj/item/clothing/suit/S = EH.item
				if (istype(S))
					ret += S.armor_value_explosion
		return ret

	ex_act(var/severity)
		..() // Logs.
		var/ex_res = get_explosion_resistance()
		if (ex_res >= 15 && prob(ex_res * 3.5))
			severity++
		if (ex_res >= 30 && prob(ex_res * 1.5))
			severity++
		switch(severity)
			if (1)
				gib()
			if (2)
				if (health < max_health * 0.35 && prob(50))
					gib()
				else
					TakeDamage("All", rand(10, 30), rand(10, 30))
			if (3)
				TakeDamage("All", rand(20, 20))
