// Added support for old-style grenades (Convair880).
/obj/item/mousetrap
	name = "mousetrap"
	desc = "A handy little spring-loaded trap for catching pesty rodents."
	icon = 'icons/obj/weapons.dmi'
	icon_state = "mousetrap"
	item_state = "mousetrap"
	w_class = 1
	force = null
	throwforce = null
	var/armed = 0
	var/obj/item/chem_grenade/grenade = null
	var/obj/item/old_grenade/grenade_old = null
	var/obj/item/pipebomb/bomb/pipebomb = null
	var/obj/item/reagent_containers/food/snacks/pie/pie = null
	var/obj/item/parts/arm = null
	stamina_damage = 5
	stamina_cost = 5
	stamina_crit_chance = 5

	armed
		icon_state = "mousetraparmed"
		armed = 1

		triggered(mob/target as mob, var/type = "feet")
			..(target, type)
			armed = 1
			return

		cleaner
			name = "cleantrap"

			New()
				..()
				overlays += image('icons/obj/weapons.dmi', "trap-grenade")
				grenade = new /obj/item/chem_grenade/cleaner(src)
				return

	examine()
		set src in oview(12)
		set category = "Local"
		..()
		if (armed)
			boutput(usr, "<span style=\"color:red\">It looks like it's armed.</span>")
		return

	attack_self(mob/user as mob)
		if (!armed)
			icon_state = "mousetraparmed"
			user.show_text("You arm the mousetrap.", "blue")
		else
			icon_state = "mousetrap"
			if ((user.get_brain_damage() >= 60 || user.bioHolder.HasEffect("clumsy")) && prob(50))
				var/which_hand = "l_arm"
				if (!user.hand)
					which_hand = "r_arm"
				triggered(user, which_hand)
				user.visible_message("<span style=\"color:red\"><strong>[user] accidentally sets off the mousetrap, breaking their fingers.</strong></span>",\
				"<span style=\"color:red\"><strong>You accidentally trigger the mousetrap!</strong></span>")
				return
			user.show_text("You disarm the mousetrap.", "blue")

		armed = !armed
		playsound(user.loc, "sound/weapons/handcuffs.ogg", 30, 1, -3)
		return

	attack_hand(mob/user as mob)
		if (armed)
			if ((user.get_brain_damage() >= 60 || user.bioHolder.HasEffect("clumsy")) && prob(50))
				var/which_hand = "l_arm"
				if (!user.hand)
					which_hand = "r_arm"
				triggered(user, which_hand)
				user.visible_message("<span style=\"color:red\"><strong>[user] accidentally sets off the mousetrap, breaking their fingers.</strong></span>",\
				"<span style=\"color:red\"><strong>You accidentally trigger the mousetrap!</strong></span>")
				return
		..()
		return

	attackby(obj/item/C as obj, mob/user as mob)
		if (istype(C, /obj/item/chem_grenade) && !grenade && !grenade_old && !pipebomb && !arm)
			var/obj/item/chem_grenade/CG = C
			if (CG.stage == 2 && !CG.state)
				user.u_equip(CG)
				CG.set_loc(src)
				user.show_text("You attach [CG]'s detonator to [src].", "blue")
				grenade = CG
				overlays += image('icons/obj/weapons.dmi', "trap-grenade")

				message_admins("[key_name(user)] rigs [src] with [CG] at [log_loc(user)].")
				logTheThing("bombing", user, null, "rigs [src] with [CG] at [log_loc(user)].")

		else if (istype(C, /obj/item/old_grenade) && !grenade && !grenade_old && !pipebomb && !arm)
			var/obj/item/old_grenade/OG = C
			if (OG.not_in_mousetraps == 0 && !OG.state)
				user.u_equip(OG)
				OG.set_loc(src)
				user.show_text("You attach [OG]'s detonator to [src].", "blue")
				grenade_old = OG
				overlays += image('icons/obj/weapons.dmi', "trap-grenade")

				message_admins("[key_name(user)] rigs [src] with [OG] at [log_loc(user)].")
				logTheThing("bombing", user, null, "rigs [src] with [OG] at [log_loc(user)].")

		else if (istype(C, /obj/item/pipebomb/bomb) && !grenade && !grenade_old && !pipebomb && !arm)
			var/obj/item/pipebomb/bomb/PB = C
			if (!PB.armed)
				user.u_equip(PB)
				PB.set_loc(src)
				user.show_text("You attach [PB]'s detonator to [src].", "blue")
				pipebomb = PB
				overlays += image('icons/obj/weapons.dmi', "trap-pipebomb")

				message_admins("[key_name(user)] rigs [src] with [PB] at [log_loc(user)].")
				logTheThing("bombing", user, null, "rigs [src] with [PB] at [log_loc(user)].")

		else if (istype(C, /obj/item/pipebomb/frame))
			var/obj/item/pipebomb/frame/PF = C
			if (loc != user)
				user.show_text("You need to actually be holding [src] to do this.", "red")
				return

			if (PF.state > 2)
				user.show_text("[PF] needs to be empty to be used.", "red")
				return

			// Pies won't do, they require a mob as the target. Obviously, the mousetrap roller is much more
			// likely to bump into an inanimate object.
			if (!grenade && !grenade_old && !pipebomb)
				user.show_text("[src] must have a grenade or pipe bomb attached first.", "red")
				return

			user.u_equip(src)
			user.u_equip(PF)
			new /obj/item/mousetrap_roller(get_turf(src), src, PF)
			return

		else if (!arm && (istype(C, /obj/item/parts/robot_parts/arm) || istype(C, /obj/item/parts/human_parts/arm)) && !grenade && !grenade_old && !pipebomb)
			user.u_equip(C)
			arm = C
			C.set_loc(src)
			overlays += image(C.icon, C.icon_state)
			user.show_text("You add [C] to [src].", "blue")

		else if (istype(C, /obj/item/reagent_containers/food/snacks/pie) && !grenade && !grenade_old && !pipebomb)
			if (pie)
				user.show_text("There's already a pie attached to [src]!", "red")
				return
			else if (!arm)
				user.show_text("You can't quite seem to get [C] to stay on [src]. Seems like it needs something to hold it in place.", "red")
				return
			else if (C.w_class > 1) // Transfer valve bomb pies are a thing. Shouldn't fit in a backpack, much less a box.
				user.show_text("[C] is way too large. You can't find any way to balance it on the arm.", "red")
				return
			user.u_equip(C)
			pie = C
			C.set_loc(src)
			overlays += image(C.icon, C.icon_state)
			user.show_text("You carefully set [C] in [src]'s [arm].", "blue")

			logTheThing("bombing", user, null, "rigs [src] with [arm] and [C] at [log_loc(user)].")

		else if (istype(C, /obj/item/wrench))
			if (grenade)
				user.show_text("You detach [grenade].", "blue")
				grenade.set_loc(get_turf(src))
				grenade = null
				overlays -= image('icons/obj/weapons.dmi', "trap-grenade")
			else if (grenade_old)
				user.show_text("You detach [grenade_old].", "blue")
				grenade_old.set_loc(get_turf(src))
				grenade_old = null
				overlays -= image('icons/obj/weapons.dmi', "trap-grenade")
			else if (pipebomb)
				user.show_text("You detach [pipebomb].", "blue")
				pipebomb.set_loc(get_turf(src))
				pipebomb = null
				overlays -= image('icons/obj/weapons.dmi', "trap-pipebomb")
			else if (pie)
				user.show_text("You remove [pie] from [src].", "blue")
				overlays -= image(pie.icon, pie.icon_state)
				pie.layer = initial(pie.layer)
				pie.set_loc(get_turf(src))
				pie = null
			else if (arm)
				user.show_text("You remove [arm] from [src].", "blue")
				overlays -= image(arm.icon, arm.icon_state)
				arm.layer = initial(arm.layer)
				arm.set_loc(get_turf(src))
				arm = null
		else
			..()
		return

	HasEntered(AM as mob|obj)
		if ((ishuman(AM)) && (armed))
			var/mob/living/carbon/H = AM
			if (H.m_intent == "run")
				triggered(H)
				H.visible_message("<span style=\"color:red\"><strong>[H] accidentally steps on the mousetrap.</strong></span>",\
				"<span style=\"color:red\"><strong>You accidentally step on the mousetrap!</strong></span>")

		else if (istype(AM, /obj/critter/mouse) && (armed))
			var/obj/critter/mouse/M = AM
			playsound(loc, "sound/effects/snap.ogg", 50, 1)
			icon_state = "mousetrap"
			armed = 0
			visible_message("<span style=\"color:red\"><strong>[M] is caught in the trap!</strong></span>")
			M.CritterDeath()
		..()
		return

	hitby(A as mob|obj)
		if (!armed)
			return ..()
		visible_message("<span style=\"color:red\"><strong>The mousetrap is triggered by [A].</strong></span>")
		triggered(null)
		return

	proc/triggered(mob/target as mob, var/type = "feet")
		if (!src || !armed)
			return

		var/obj/item/affecting = null
		if (target && ishuman(target))
			var/mob/living/carbon/human/H = target
			switch(type)
				if ("feet")
					if (!H.shoes)
						affecting = H.organs[pick("l_leg", "r_leg")]
						H.weakened = max(3, H.weakened)
				if ("l_arm", "r_arm")
					if (!H.gloves)
						affecting = H.organs[type]
						H.stunned = max(3, H.stunned)
			if (affecting)
				affecting.take_damage(1, 0)
				H.UpdateDamageIcon()
				H.updatehealth()

		if (target)
			playsound(target.loc, "sound/effects/snap.ogg", 50, 1)
		icon_state = "mousetrap"
		armed = 0

		if (grenade)
			logTheThing("bombing", target, null, "triggers [src] (armed with: [grenade]) at [log_loc(src)]")
			grenade.explode()
			grenade = null
			overlays -= image('icons/obj/weapons.dmi', "trap-grenade")

		else if (grenade_old)
			logTheThing("bombing", target, null, "triggers [src] (armed with: [grenade_old]) at [log_loc(src)]")
			grenade_old.prime()
			grenade_old = null
			overlays -= image('icons/obj/weapons.dmi', "trap-grenade")

		else if (pipebomb)
			logTheThing("bombing", target, null, "triggers [src] (armed with: [pipebomb]) at [log_loc(src)]")
			overlays -= image('icons/obj/weapons.dmi', "trap-pipebomb")
			pipebomb.do_explode()
			pipebomb = null

		else if (pie && arm)
			logTheThing("bombing", target, null, "triggers [src] (armed with: [arm] and [pie]) at [log_loc(src)]")
			target.visible_message("<span style=\"color:red\"><strong>[src]'s [arm] launches [pie] at [target]!</strong></span>",\
			"<span style=\"color:red\"><strong>[src]'s [arm] launches [pie] at you!</strong></span>")
			overlays -= image(pie.icon, pie.icon_state)
			pie.layer = initial(pie.layer)
			pie.set_loc(get_turf(target))
			pie.throw_impact(target)
			pie = null

		return

// Added support for old-style grenades and pipe bombs (Convair880).
/obj/item/mousetrap_roller
	name = "mousetrap roller assembly"
	desc = "A mousetrap bomb attached to a set of wheels. Looks like the mousetrap going off would send it rolling. Huh."
	icon = 'icons/obj/weapons.dmi'
	icon_state = "mousetrap_roller"
	item_state = "mousetrap"
	w_class = 1
	var/armed = 0
	var/obj/item/mousetrap/mousetrap = null
	var/obj/item/pipebomb/frame/frame = null
	var/payload = ""

	New(ourLoc, var/obj/item/mousetrap/newtrap, obj/item/pipebomb/frame/newframe)
		..()

		if (newtrap)
			newtrap.set_loc(src)
			mousetrap = newtrap
		else
			mousetrap = new /obj/item/mousetrap(src)

		// Fallback in case something goes wrong.
		if (!mousetrap.grenade && !mousetrap.grenade_old && !mousetrap.pipebomb)
			mousetrap.grenade = new /obj/item/chem_grenade/flashbang(mousetrap)
			mousetrap.overlays += image('icons/obj/weapons.dmi', "trap-grenade")

		if (mousetrap.grenade)
			payload = mousetrap.grenade.name
			name = "mousetrap/grenade/roller assembly"
		else if (mousetrap.grenade_old)
			payload = mousetrap.grenade_old.name
			name = "mousetrap/grenade/roller assembly"
		else if (mousetrap.pipebomb)
			payload = mousetrap.pipebomb.name
			name = "mousetrap/pipe bomb/roller assembly"
		else
			payload = "*unknown or null*"

		if (newframe)
			newframe.set_loc(src)
			frame = newframe
		else
			frame = new /obj/item/pipebomb/frame(src)

		return

	attackby(obj/item/C as obj, mob/user as mob)
		if (istype(C, /obj/item/wrench))
			if (!isturf(loc))
				user.show_text("Place the [name] on the ground first.", "red")
				return

			user.visible_message("<strong>[user]</strong> disassembles [src].","You disassemble [src].")

			if (mousetrap)
				mousetrap.set_loc(loc)
				mousetrap = null

			if (frame)
				frame.set_loc(loc)
				frame = null

			qdel(src)

		else
			..()
		return

	attack_hand(mob/user as mob)
		if (armed)
			return

		return ..()

	attack_self(mob/user as mob)
		if (!isturf(user.loc))
			user.show_text("You can't release the [name] in a confined space.", "red")
			return

		if (armed)
			return

		user.visible_message("<span style=\"color:red\">[user] starts up the [name].</span>", "You start up the [name]")
		message_admins("[key_name(user)] releases a [src] (Payload: [payload]) at [log_loc(user)]. Direction: [dir2text(user.dir)].")
		logTheThing("bombing", user, null, "releases a [src] (Payload: [payload]) at [log_loc(user)]. Direction: [dir2text(user.dir)].")

		armed = 1
		if (mousetrap)
			src.mousetrap.armed = 1 // Must be armed or it won't work in mousetrap.triggered().
		density = 1
		user.u_equip(src)

		layer = initial(layer)
		dir = user.dir
		walk(src, dir, 3)

	Bump(atom/movable/AM as mob|obj)
		if (armed && mousetrap)
			visible_message("<span style=\"color:red\">[src] bumps against [AM]!</span>")
			walk(src, 0)
			mousetrap.triggered(AM && ismob(AM) ? AM : null)

			if (mousetrap)
				mousetrap.set_loc(loc)
				mousetrap = null
			if (frame)
				frame.set_loc(loc)
				frame = null

			qdel(src)

		return