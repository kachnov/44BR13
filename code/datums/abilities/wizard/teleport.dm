/targetable/spell/teleport
	name = "Teleport"
	desc = "Teleports you to an area of your choice after a short delay."
	icon_state = "phaseshift"
	targeted = 0
	cooldown = 450
	requires_robes = 1
	cooldown_staff = 1
	restricted_area_check = 1

	cast()
		if (!holder)
			return TRUE

		if (holder.owner && ismob(holder.owner) && holder.owner.teleportscroll(0, 3) == 1)
			return FALSE

		return TRUE

// These two procs were so similar that I combined them (Convair880).
/mob/proc/teleportscroll(var/effect = 0, var/perform_check = 0, var/obj/item_to_check = null)
	if (paralysis > 0 || stat != 0)
		boutput(src, "<span style=\"color:red\">Not when you're incapacitated.</span>")
		return FALSE

	if (!isturf(loc)) // Teleport doesn't go along well with doppelgaenger or phaseshift.
		boutput(src, "<span style=\"color:red\">You can't seem to teleport from here.</span>")
		return FALSE

	var/turf/T = get_turf(src)
	if (!T || !isturf(T))
		boutput(src, "<span style=\"color:red\">You can't seem to teleport from here.</span>")
		return FALSE
	if (isrestrictedz(T.z))
		boutput(src, "<span style=\"color:red\">You can't seem to teleport from here.</span>")
		return FALSE

	var/A
	A = input("Area to jump to", "Teleportation", A) in teleareas
	var/area/thearea = teleareas[A]

	if (!thearea || !istype(thearea))
		show_text("Invalid selection.", "red")
		return FALSE

	// You can keep the selection window open, so we have to do the checks again (individual item/spell procs handle the first batch).
	switch (perform_check)
		if (1)
			var/obj/item/teleportation_scroll/scroll_check = item_to_check
			if (!scroll_check || !istype(scroll_check))
				show_text("The scroll appears to have been destroyed.", "red")
				return FALSE
			if (!iswizard(src))
				boutput(src, "<span style=\"color:red\">The scroll is illegible!</span>")
				return FALSE
			if (scroll_check.uses < 1)
				show_text("The scroll is depleted!", "src")
				return FALSE
			if (scroll_check.loc != src && scroll_check.loc != back) // Pocket or backpack.
				show_text("You reach for the scroll, but it's just too far away.", "red")
				return FALSE

		if (2)
			var/obj/machinery/computer/pod/comp_check = item_to_check
			if (!comp_check || !istype(comp_check))
				show_text("The computer appears to have been destroyed.", "red")
				return FALSE
			if (comp_check.stat & (NOPOWER|BROKEN))
				show_text("[comp_check] is out of order.", "red")
				return FALSE
			if (get_dist(src, comp_check) > 1)
				show_text("[comp_check] is too far away.", "red")
				return FALSE

		if (3)
			if (!iswizard(src))
				boutput(src, "<span style=\"color:red\">You seem to have lost all magical abilities.</span>")
				return FALSE
			if (wizard_castcheck() == 0)
				return FALSE // Has own user feedback.

	if (paralysis > 0 || stat != 0)
		boutput(src, "<span style=\"color:red\">Not when you're incapacitated.</span>")
		return FALSE

	if (!isturf(loc))
		boutput(src, "<span style=\"color:red\">You can't seem to teleport from here.</span>")
		return FALSE

	var/turf/T2 = get_turf(src)
	if (!T2 || !isturf(T2))
		boutput(src, "<span style=\"color:red\">You can't seem to teleport from here.</span>")
		return FALSE
	if (isrestrictedz(T2.z))
		boutput(src, "<span style=\"color:red\">You can't seem to teleport from here.</span>")
		return FALSE

	switch (perform_check)
		if (1)
			visible_message("<span style=\"color:red\"><strong>[src] magically disappears!</strong></span>")

		if (2)
			visible_message("<span style=\"color:red\"><strong>[src]</strong> presses a button and teleports away.</span>")

		if (3) // Spell-specific stuff.
			say("SCYAR NILA [uppertext(A)]")
			playsound(loc, "sound/voice/wizard/TeleportLoud.ogg", 50, 0, -1)
			visible_message("<span style=\"color:red\"><strong>[src] begins to fade away!</strong></span>")
			animate_teleport_wiz(src)
			sleep(40) // Animation.

			var/mob/living/carbon/human/H = src
			if (istype(H) && H.burning)
				boutput(H, "<span style=\"color:blue\">The flames sputter out as you phase shift.</span>")
				H.set_burning(0)

			playsound(loc, "sound/effects/mag_teleport.ogg", 25, 1, -1)

	var/list/L = list()
	for (var/turf/T3 in get_area_turfs(thearea.type))
		if (!T3.density)
			var/clear = 1
			for (var/obj/O in T3)
				if (O.density)
					clear = 0
					break
			if (clear)
				L += T3

	if (effect)
		var/effects/system/spark_spread/s = unpool(/effects/system/spark_spread)
		s.set_up(5, 1, loc)

		if (perform_check == 3)
			set_loc(pick(L))
			s.start() // Effect second because we had sound effects etc at the old loc.
		else
			s.start()
			set_loc(pick(L))

	else
		var/effects/system/harmless_smoke_spread/smoke = new /effects/system/harmless_smoke_spread()
		smoke.set_up(5, 0, loc)
		smoke.attach(src)

		if (perform_check == 3)
			set_loc(pick(L))
			smoke.start()
		else
			smoke.start()
			set_loc(pick(L))

	return TRUE
