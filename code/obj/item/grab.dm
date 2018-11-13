/obj/item/grab
	flags = SUPPRESSATTACK
	var/mob/living/assailant
	var/mob/living/affecting
	var/state = 0 // 0 = passive, 1 aggressive, 2 neck, 3 kill
	var/choke_count = 0
	icon = 'icons/mob/hud_human_new.dmi'
	icon_state = "reinforce"
	name = "grab"
	w_class = 5

	New()
		..()
		spawn (0)
			var/icon/hud_style = hud_style_selection[get_hud_style(assailant)]
			if (isicon(hud_style))
				icon = hud_style

	disposing()
		if (affecting)
			if (state == 3)
				logTheThing("combat", assailant, affecting, "releases their choke on %target% after [choke_count] cycles")
			else
				logTheThing("combat", assailant, affecting, "drops their grab on %target%")
			affecting.grabbed_by -= src
			affecting = null
		assailant = null
		..()

	dropped()
		qdel(src)

	process()
		if (check())
			return

		var/mob/living/carbon/human/H
		if (istype(affecting, /mob/living/carbon/human))
			H = affecting

		if (state >= 2)
			if (!affecting.buckled)
				affecting.set_loc(assailant.loc)
			if (H) H.remove_stamina(STAMINA_REGEN+7)
		if (state == 3)
			//affecting.losebreath++
			//if (affecting.paralysis < 2)
			//	affecting.paralysis = 2
			if (H)
				choke_count++
				H.remove_stamina(STAMINA_REGEN+7)
				H.stamina_stun()
				if (H.stamina <= -75)
					H.losebreath += 2
				else if (H.stamina <= -50)
					H.losebreath++
				else if (H.stamina <= -33)
					if (prob(33)) H.losebreath++
		update_icon()

	attack(atom/target, mob/user)
		if (check())
			return
		if (target == affecting)
			attack_self()
			return

	attack_hand(mob/user)
		return

	attack_self(mob/user)
		if (!user)
			return
		if (check())
			return
		switch (state)
			if (0)
				if (prob(75))
					logTheThing("combat", assailant, affecting, "'s grip upped to aggressive on %target%")
					for (var/mob/O in AIviewers(assailant, null))
						O.show_message("<span style=\"color:red\">[assailant] has grabbed [affecting] aggressively (now hands)!</span>", 1)
					icon_state = "reinforce"
					state = 1
				else
					for (var/mob/O in AIviewers(assailant, null))
						O.show_message("<span style=\"color:red\">[assailant] has failed to grab [affecting] aggressively!</span>", 1)
					/*if (!disable_next_click) this actually is always gunna be a mob so we want to use next click even if disabled
						*/user.next_click = world.time + 10
			if (1)
				if (ishuman(affecting))
					var/mob/living/carbon/human/H = affecting
					if (H.bioHolder.HasEffect("fat"))
						boutput(assailant, "<span style=\"color:blue\">You can't strangle [affecting] through all that fat!</span>")
						return
					for (var/obj/item/clothing/C in list(H.head, H.wear_suit, H.wear_mask, H.w_uniform))
						if (C.body_parts_covered & HEAD)
							boutput(assailant, "<span style=\"color:blue\">You have to take off [affecting]'s [C.name] first!</span>")
							return
				icon_state = "!reinforce"
				state = 2
				if (!affecting.buckled)
					affecting.set_loc(assailant.loc)
				assailant.lastattacked = affecting
				affecting.lastattacker = assailant
				affecting.lastattackertime = world.time
				logTheThing("combat", assailant, affecting, "'s grip upped to neck on %target%")
				for (var/mob/O in AIviewers(assailant, null))
					O.show_message("<span style=\"color:red\">[assailant] has reinforced [his_or_her(assailant)] grip on [affecting] (now neck)!</span>", 1)
			if (2)
				icon_state = "disarm/kill"
				logTheThing("combat", assailant, affecting, "chokes %target%")
				choke_count = 0
				for (var/mob/O in AIviewers(assailant, null))
					O.show_message("<span style=\"color:red\">[assailant] has tightened [his_or_her(assailant)] grip on [affecting]'s neck!</span>", 1)
				state = 3
				assailant.lastattacked = affecting
				affecting.lastattacker = assailant
				affecting.lastattackertime = world.time
				if (!affecting.buckled)
					affecting.set_loc(assailant.loc)
				if (assailant.bioHolder.HasEffect("fat"))
					affecting.unlock_medal("Bear Hug", 1)
				//affecting.losebreath++
				//if (affecting.paralysis < 2)
				//	affecting.paralysis = 2
				affecting.stunned = max(affecting.stunned, 3)
				if (ishuman(affecting))
					var/mob/living/carbon/human/H = affecting
					H.set_stamina(min(0, H.stamina))
				if (/*!disable_next_click && */user)
					user.next_click = world.time + 10
			if (3)
				state = 2
				logTheThing("combat", assailant, affecting, "releases their choke on %target% after [choke_count] cycles")
				for (var/mob/O in AIviewers(assailant, null))
					O.show_message("<span style=\"color:red\">[assailant] has loosened [his_or_her(assailant)] grip on [affecting]'s neck!</span>", 1)
				/*if (!disable_next_click) same as before
					*/user.next_click = world.time + 10
		update_icon()

	proc/check()
		if (!affecting || get_dist(assailant, affecting) > 1 || loc != assailant)
			qdel(src)
			return TRUE
		return FALSE

	proc/update_icon()
		switch (state)
			if (0)
				icon_state = "reinforce"
			if (1)
				icon_state = "!reinforce"
			if (2)
				icon_state = "disarm/kill"
			if (3)
				icon_state = "disarm/kill1"