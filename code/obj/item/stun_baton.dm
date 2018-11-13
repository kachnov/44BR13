// Contains:
// - Baton parent
// - Subtypes

////////////////////////////////////////// Stun baton parent //////////////////////////////////////////////////

// Completely refactored the ca. 2009-era code here. Powered batons also use power cells now (Convair880).
/obj/item/baton
	name = "stun baton"
	desc = "A standard issue baton for stunning people with."
	icon = 'icons/obj/weapons.dmi'
	icon_state = "stunbaton"
	inhand_image_icon = 'icons/mob/inhand/hand_weapons.dmi'
	item_state = "baton"
	flags = FPRINT | ONBELT | TABLEPASS
	force = 10
	throwforce = 7
	w_class = 3
	mats = 8
	contraband = 4
	stamina_damage = 15
	stamina_cost = 10
	stamina_crit_chance = 5

	var/icon_on = "stunbaton_active"
	var/icon_off = "stunbaton"
	var/wait_cycle = 0 // Update sprite periodically if we're using a self-charging cell.

	var/cell_type = /obj/item/ammo/power_cell/med_power // Type of cell to spawn by default.
	var/obj/item/ammo/power_cell/cell = null // Ignored for cyborgs and when used_electricity is false.
	var/cost_normal = 25 // Cost in PU. Doesn't apply to cyborgs.
	var/cost_cyborg = 500 // Battery charge to drain when user is a cyborg.
	var/uses_charges = 1 // Does it deduct charges when used? Distinct from...
	var/uses_electricity = 1 // Does it use electricity? Certain interactions don't work with a wooden baton.
	var/status = 1

	var/stun_normal_weakened = 10
	var/stun_normal_stuttering = 10
	var/stun_harm_weakened = 5 // Only used when next flag is set to 1.
	var/instant_harmbaton_stun = 0 // Legacy behaviour for harmbaton, that is an instant knockdown.
	var/stamina_based_stun = 0 // Experimental. Centered around stamina instead of traditional stun.
	var/stamina_based_stun_amount = 275 // Amount of stamina drained.

	New()
		..()
		if (uses_electricity != 0 && (!isnull(cell_type) && ispath(cell_type, /obj/item/ammo/power_cell)) && (!cell || !istype(cell)))
			cell = new cell_type(src)
		if (!(src in processing_items)) // No self-charging cell? Will be removed after the first tick.
			processing_items.Add(src)
		update_icon()
		return

	disposing()
		if (src in processing_items)
			processing_items.Remove(src)
		..()
		return

	examine()
		..()
		if (uses_charges != 0 && uses_electricity != 0)
			if (!cell || !istype(cell))
				boutput(usr, "<span style=\"color:red\">No power cell installed.</span>")
			else
				boutput(usr, "The baton is turned [status ? "on" : "off"]. There are [cell.charge]/[cell.max_charge] PUs left! Each stun will use [cost_normal] PUs.")
		return

	emp_act()
		if (uses_charges != 0 && uses_electricity != 0)
			status = 0
			process_charges(-INFINITY)
		return

	process()
		wait_cycle = !wait_cycle
		if (wait_cycle)
			return

		if (!(src in processing_items))
			logTheThing("debug", null, null, "<strong>Convair880</strong>: Process() was called for a stun baton ([type]) that wasn't in the item loop. Last touched by: [fingerprintslast ? "[fingerprintslast]" : "*null*"]")
			processing_items.Add(src)
			return
		if (!cell || !istype(cell) || uses_electricity == 0)
			processing_items.Remove(src)
			return
		if (!istype(cell, /obj/item/ammo/power_cell/self_charging)) // Kick out batons with a plain cell.
			processing_items.Remove(src)
			return
		if (src.cell.charge == src.cell.max_charge) // Keep self-charging cells in the loop, though.
			return

		update_icon()
		return

	proc/update_icon()
		if (!src || !istype(src))
			return

		if (status)
			icon_state = icon_on
		else
			icon_state = icon_off

		return

	proc/can_stun(var/requires_electricity = 0, var/amount = 1, var/mob/user)
		if (!src || !istype(src))
			return FALSE
		if (uses_electricity == 0)
			if (requires_electricity == 0)
				return TRUE
			else
				return FALSE
		if (status == 0)
			return FALSE
		if (amount <= 0)
			return FALSE

		regulate_charge()
		if (user && isrobot(user))
			var/mob/living/silicon/robot/R = user
			if (R.cell && R.cell.charge >= (cost_cyborg * amount))
				return TRUE
			else
				return FALSE
		if (!cell || !istype(cell))
			if (user && ismob(user))
				user.show_text("The [name] doesn't have a power cell!", "red")
			return FALSE
		if (cell.charge < (cost_normal * amount))
			if (user && ismob(user))
				user.show_text("The [name] is out of charge!", "red")
			return FALSE
		else
			return TRUE

	proc/regulate_charge()
		if (!src || !istype(src))
			return

		if (cell && istype(cell))
			if (cell.charge < 0)
				cell.charge = 0
			if (cell.charge > cell.max_charge)
				cell.charge = cell.max_charge

			cell.update_icon()
			update_icon()

		return

	proc/process_charges(var/amount = -1, var/mob/user)
		if (!src || !istype(src) || amount == 0)
			return
		if (uses_electricity == 0)
			return

		if (user && isrobot(user))
			var/mob/living/silicon/robot/R = user
			if (amount < 0)
				R.cell.use(cost_cyborg * -(amount))
		else
			if (uses_charges != 0 && (cell && istype(cell)))
				if (amount < 0)
					cell.use(cost_normal * -(amount))
					if (user && ismob(user))
						if (cell.charge > 0)
							user.show_text("The [name] now has [cell.charge]/[cell.max_charge] PUs remaining.", "blue")
						else if (cell.charge <= 0)
							user.show_text("The [name] is now out of charge!", "red")
				else if (amount > 0)
					cell.charge(cost_normal * amount)

		update_icon()
		return

	proc/use_stamina_stun()
		if (!src || !istype(src))
			return FALSE

		if (stamina_based_stun != 0)
			stamina_damage = stamina_based_stun_amount
			return TRUE
		else
			stamina_damage = initial(stamina_damage) // Doubles as reset fallback (var editing).
			return FALSE

	proc/do_stun(var/mob/user, var/mob/victim, var/type = "", var/stun_who = 2)
		if (!src || !istype(src) || type == "")
			return
		if (!user || !victim || !ismob(victim))
			return

		// Sound effects, log entries and text messages.
		switch (type)
			if ("failed")
				logTheThing("combat", user, null, "accidentally stuns [himself_or_herself(user)] with the [name] at [log_loc(user)].")

				if (uses_electricity != 0)
					user.visible_message("<span style=\"color:red\"><strong>[user]</strong> fumbles with the [name] and accidentally stuns [himself_or_herself(user)]!</span>")
					flick("baton_active", src)
					playsound(loc, "sound/weapons/Egloves.ogg", 50, 1, -1)
				else
					user.visible_message("<span style=\"color:red\"><strong>[user]</strong> swings the [name] in the wrong way and accidentally hits [himself_or_herself(user)]!</span>")
					playsound(loc, "sound/weapons/Genhit.ogg", 50, 1, -1)
					random_brute_damage(user, 2 * force)

			if ("failed_stun")
				user.visible_message("<span style=\"color:red\"><strong>[victim] has been prodded with the [name] by [user]! Luckily it was off.</strong></span>")
				playsound(loc, "sound/weapons/Genhit.ogg", 25, 1, -1)
				logTheThing("combat", user, victim, "unsuccessfully tries to stun %target% with the [name] at [log_loc(victim)].")

				if (uses_electricity && status == 1 && (cell && istype(cell) && (cell.charge < cost_normal)))
					if (user && ismob(user))
						user.show_text("The [name] is out of charge!", "red")
				return

			if ("failed_harm")
				user.visible_message("<span style=\"color:red\"><strong>[user] has attempted to beat [victim] with the [name] but held it wrong!</strong></span>")
				playsound(loc, "sound/weapons/Genhit.ogg", 50, 1, -1)
				logTheThing("combat", user, victim, "unsuccessfully tries to beat %target% with the [name] at [log_loc(victim)].")

			if ("stun", "stun_classic")
				user.visible_message("<span style=\"color:red\"><strong>[victim] has been stunned with the [name] by [user]!</strong></span>")
				logTheThing("combat", user, victim, "stuns %target% with the [name] at [log_loc(victim)].")

				if (type == "stun_classic")
					playsound(loc, "sound/weapons/Genhit.ogg", 50, 1, -1)
				else
					flick("baton_active", src)
					playsound(loc, "sound/weapons/Egloves.ogg", 50, 1, -1)

			if ("harm_classic")
				user.visible_message("<span style=\"color:red\"><strong>[victim] has been beaten with the [name] by [user]!</strong></span>")
				playsound(loc, "swing_hit", 50, 1, -1)
				logTheThing("combat", user, victim, "beats %target% with the [name] at [log_loc(victim)].")

			else
				logTheThing("debug", user, null, "<strong>Convair880</strong>: stun baton ([type]) do_stun() was called with an invalid argument ([type]), aborting. Last touched by: [fingerprintslast ? "[fingerprintslast]" : "*null*"]")
				return

		// Target setup. User might not be a mob (Beepsky), but the victim needs to be one.
		var/mob/dude_to_stun
		if (stun_who == 1 && user && ismob(user))
			dude_to_stun = user
		else
			dude_to_stun = victim

		var/hulk = 0
		if (dude_to_stun.bioHolder && dude_to_stun.bioHolder.HasEffect("hulk"))
			hulk = 1

		// Stun the target mob.
		if (type == "harm_classic")
			if ((dude_to_stun.weakened < stun_harm_weakened) && !hulk)
				dude_to_stun.weakened = stun_harm_weakened
			random_brute_damage(dude_to_stun, force) // Necessary since the item/attack() parent wasn't called.
			dude_to_stun.remove_stamina(stamina_damage)
			if (user && ismob(user))
				user.remove_stamina(stamina_cost)

		else
			if (dude_to_stun.bioHolder && dude_to_stun.bioHolder.HasEffect("resist_electric") && uses_electricity != 0)
				boutput(dude_to_stun, "<span style=\"color:blue\">Thankfully, electricity doesn't do much to you in your current state.</span>")
			else
				if (!use_stamina_stun() || (use_stamina_stun() && ismob(dude_to_stun) && !hasvar(dude_to_stun, "stamina")))
					if ((dude_to_stun.weakened < stun_normal_weakened) && !hulk)
						dude_to_stun.weakened = stun_normal_weakened
					if ((dude_to_stun.stuttering < stun_normal_stuttering) && !hulk)
						dude_to_stun.stuttering = stun_normal_stuttering
				else
					dude_to_stun.remove_stamina(stamina_damage)
					dude_to_stun.stamina_stun() // Must be called manually here to apply the stun instantly.

				if (isliving(dude_to_stun) && uses_electricity != 0)
					var/mob/living/L = dude_to_stun
					L.Virus_ShockCure(33)
					L.shock_cyberheart(33)

			process_charges(-1, user)

		// Some after attack stuff.
		if (user && ismob(user))
			user.lastattacked = dude_to_stun
			dude_to_stun.lastattacker = user
			dude_to_stun.lastattackertime = world.time

		update_icon()
		return

	attack_self(mob/user as mob)
		add_fingerprint(user)

		if (uses_electricity == 0)
			return

		regulate_charge()
		status = !status

		if (can_stun() == 1 && user.bioHolder && user.bioHolder.HasEffect("clumsy") && prob(50))
			do_stun(user, user, "failed", 1)
			return

		if (status)
			user.show_text("The [name] is now on.", "blue")
			playsound(loc, "sparks", 75, 1, -1)
		else
			user.show_text("The [name] is now off.", "blue")
			playsound(loc, "sparks", 75, 1, -1)

		update_icon()
		return

	attack(mob/M as mob, mob/user as mob)
		add_fingerprint(user)
		regulate_charge()

		if (can_stun() == 1 && user.bioHolder && user.bioHolder.HasEffect("clumsy") && prob(50))
			do_stun(user, M, "failed", 1)
			return

		switch (user.a_intent)
			if ("harm")
				if (uses_electricity == 0)
					if (instant_harmbaton_stun != 0)
						do_stun(user, M, "harm_classic", 2)
					else
						playsound(loc, "swing_hit", 50, 1, -1)
						..() // Parent handles attack log entry and stamina drain.
				else
					if (status == 0 || (status != 0 && can_stun() == 0))
						if (instant_harmbaton_stun != 0)
							do_stun(user, M, "harm_classic", 2)
						else
							playsound(loc, "swing_hit", 50, 1, -1)
							..()
					else
						do_stun(user, M, "failed_harm", 1)

			else
				if (uses_electricity == 0)
					do_stun(user, M, "stun_classic", 2)
				else
					if (status == 0 || (status != 0 && can_stun() == 0))
						do_stun(user, M, "failed_stun", 1)
					else
						do_stun(user, M, "stun", 2)

		return

	proc/log_cellswap(var/mob/user as mob, var/obj/item/ammo/power_cell/C)
		if (!user || !src || !istype(src) || !C || !istype(C))
			return

		logTheThing("combat", user, null, "swaps the power cell (<strong>Cell type:</strong> <em>[C.type]</em>) of [src] at [log_loc(user)].")
		return

/////////////////////////////////////////////// Subtypes //////////////////////////////////////////////////////

/obj/item/baton/secbot
	uses_charges = 0

/obj/item/baton/stamina
	stamina_based_stun = 1

/obj/item/baton/cane
	name = "stun cane"
	desc = "A stun baton built into the casing of a cane."
	icon_state = "stuncane"
	item_state = "cane"
	icon_on = "stuncane_active"
	icon_off = "stuncane"
	cell_type = /obj/item/ammo/power_cell

/obj/item/baton/classic
	name = "police baton"
	desc = "A wooden truncheon for beating criminal scum."
	icon_state = "baton"
	item_state = "classic_baton"
	force = 10
	mats = 0
	contraband = 6
	icon_on = "baton"
	icon_off = "baton"
	uses_charges = 0
	uses_electricity = 0
	stun_normal_weakened = 8
	stun_normal_stuttering = 8
	instant_harmbaton_stun = 1