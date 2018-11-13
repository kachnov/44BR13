// Contains:
// - Sleeper control console
// - Sleeper
// - Portable sleeper (fake Port-a-Medbay)

// I overhauled the sleeper to make it a little more viable. Aside from being a saline dispenser,
// it was of practically no use to medical personnel and thus ignored in general. The current
// implemention is by no means a substitute for a doctor in the same way that a medibot isn't, but
// the sleeper should now be capable of keeping light-crit patients stabilized for a reasonable
// amount of time. I tried to ensure that, at the time of writing, the sleeper is neither under-
// or overpowered with regard to other methods of healing mobs (Convair880).

//////////////////////////////////////// Sleeper control console //////////////////////////////

/obj/machinery/sleep_console
	name = "sleeper console"
	desc = "A device that displays the vital signs of the occupant of the sleeper, and can dispense chemicals."
	icon = 'icons/obj/Cryogenic2.dmi'
	icon_state = "sleeperconsole"
	anchored = 1
	density = 1
	mats = 8
	var/timing = 0 // Timer running?
	var/time = null // In seconds.
	var/obj/machinery/sleeper/our_sleeper = null

	New()
		..()
		spawn (5)
			if (src)
				find_sleeper()
		return

	ex_act(severity)
		switch (severity)
			if (1.0)
				qdel(src)
				return
			if (2.0)
				if (prob(50))
					qdel(src)
					return
			else
		return

	// Just relay emag_act() here.
	emag_act(var/mob/user, var/obj/item/card/emag/E)
		add_fingerprint(user)
		if (!our_sleeper)
			return FALSE
		switch (our_sleeper.emag_act(user, E))
			if (0) return FALSE
			if (1) return TRUE

	proc/find_sleeper()
		if (!src)
			return
		var/sleeper_west = locate(/obj/machinery/sleeper, get_step(src, WEST))
		var/sleeper_east = locate(/obj/machinery/sleeper, get_step(src, EAST))
		if (sleeper_west)
			our_sleeper = sleeper_west
			dir = 2
		else if (sleeper_east)
			our_sleeper = sleeper_east
			dir = 4
		return

	proc/wake_occupant()
		if (!src || !our_sleeper)
			return

		var/mob/occupant = our_sleeper.occupant
		if (ishuman(occupant))
			var/mob/living/carbon/human/O = occupant
			if (O.sleeping)
				O.sleeping = 3
				if (prob(5)) // Heh.
					boutput(O, "<font color='green'> [bicon(src)] Wake up, Neo...</font>")
				else
					boutput(O, "<font color='blue'> [bicon(src)] *beep* *beep*</font>")
			visible_message("<span style=\"color:blue\">The [name]'s occupant alarm clock dings!</span>")
			playsound(loc, "sound/machines/ding.ogg", 100, 1)
		return

	process()
		if (!src)
			return
		if (stat & (NOPOWER|BROKEN))
			return
		if (!our_sleeper)
			time = 0
			timing = 0
			updateDialog()
			return
		if (timing)
			if (time > 0)
				time = round(time) - 1
				var/mob/occupant = our_sleeper.occupant
				if (occupant)
					if (ishuman(occupant))
						var/mob/living/carbon/human/O = occupant
						if (O.stat == 2)
							visible_message("<span class='game say'><span class='name'>[src]</span> beeps, \"Alert! No further life signs detected from occupant.\"")
							playsound(loc, "sound/machines/buzz-two.ogg", 100, 0)
							timing = 0
						else
							if (O.sleeping != 5)
								O.sleeping = 5
							our_sleeper.alter_health(O)
				else
					timing = 0
			else
				wake_occupant()
				time = 0
				timing = 0

		updateDialog()
		return

	// Makes sense, I suppose. They're on the shuttles too.
	powered()
		return

	use_power()
		return

	power_change()
		return

	attack_hand(mob/user as mob)
		if (..())
			return

		add_fingerprint(user)
		user.machine = src

		var/dat = ""

		if (our_sleeper)
			var/mob/occupant = our_sleeper.occupant
			dat += "<font color='blue'><strong>Occupant Statistics:</strong></FONT><BR>"

			if (occupant)
				var/t1
				switch(occupant.stat)
					if (0)
						t1 = "Conscious"
					if (1)
						t1 = "Unconscious"
					if (2)
						t1 = "*dead*"
					else

				var/brute = occupant.get_brute_damage()
				var/burn = occupant.get_burn_damage()
				dat += "<hr>[occupant.health > 50 ? "<font color='blue'>" : "<font color='red'>"]\tHealth: [occupant.health]% ([t1])</FONT><BR>"
				dat += "[occupant.get_oxygen_deprivation() < 60 ? "<font color='blue'>" : "<font color='red'>"]&emsp;-Respiratory Damage: [occupant.get_oxygen_deprivation()]</FONT><BR>"
				dat += "[occupant.get_toxin_damage() < 60 ? "<font color='blue'>" : "<font color='red'>"]&emsp;-Toxin Content: [occupant.get_toxin_damage()]</FONT><BR>"
				dat += "[burn < 60 ? "<font color='blue'>" : "<font color='red'>"]&emsp;-Burn Severity: [burn]</FONT><BR>"
				dat += "[brute < 60 ? "<font color='blue'>" : "<font color='red'>"]&emsp;-Brute Damage: [brute]</FONT><BR>"

				// We don't have a fully-fledged reagent scanner built-in. Of course, this also means
				// we can't detect our own poisons if the sleeper's emagged. Too bad.
				var/reagents = ""
				for (var/R in occupant.reagents.reagent_list)
					var/reagent/MR = occupant.reagents.reagent_list[R]
					if (istype(MR, /reagent/medical))
						reagents += " [MR.name] ([MR.volume]),"
				if (reagents == "")
					reagents += "None "
				var/report = copytext(reagents, 1, -1)
				dat += "<br>Detectable rejuvenators in occupant's bloodstream:<br>"
				dat += "<font color='blue' size=2>[report]</font><br>"
				dat += "<br><font size=2>Note: Use separate reagent scanner for complete analysis.</font><br>"

				dat += "<hr>"

				// Capped at 3 min. Used to be 10 min, Christ.
				var/second = time % 60
				var/minute = (time - second) / 60
				dat += "<TT><strong>Occupant Alarm Clock</strong><br>[timing ? "<A href='?src=\ref[src];time=0'>Timing</A>" : "<A href='?src=\ref[src];time=1'>Not Timing</A>"] [minute]:[second]<br><A href='?src=\ref[src];tp=-30'>-</A> <A href='?src=\ref[src];tp=-1'>-</A> <A href='?src=\ref[src];tp=1'>+</A> <A href='?src=\ref[src];tp=30'>+</A><br></TT>"
				dat += "<br><font size=2>System will inject rejuvenators automatically when occupant is in hibernation.</font>"

				dat += "<hr>"

				dat += "<A href='?src=\ref[src];refresh=1'>Refresh</A> | <A href='?src=\ref[src];rejuv=1'>Inject Rejuvenators</A> | <A href='?src=\ref[src];eject_occupant=1'>Eject Occupant</A>"

			else
				dat += "<HR>The sleeper is unoccupied."

		else
			dat += "<font color='red'><strong>ERROR:</strong> No sleeper detected!</font><br>"
			dat += "<br><A href='?src=\ref[src];refresh=1'>Refresh Connection</A>"

		user << browse(dat, "window=sleeper")
		onclose(user, "sleeper")

		return

	Topic(href, href_list)
		if (..()) return
		if (!isturf(loc)) return
		if ((our_sleeper && our_sleeper.occupant == usr) || usr.stunned || usr.weakened || usr.stat || usr.restrained()) return
		if (!issilicon(usr) && !in_range(src, usr)) return

		add_fingerprint(usr)
		usr.machine = src

		if (href_list["time"])
			if (our_sleeper && our_sleeper.occupant)
				if (our_sleeper.occupant.stat == 2)
					usr.show_text("The occupant is dead.", "red")
				else
					timing = text2num(href_list["time"])
					visible_message("<span style=\"color:blue\">[usr] [timing ? "sets" : "stops"] the [src]'s occupant alarm clock.</span>")
					if (timing)
						// People do use sleepers for grief from time to time.
						logTheThing("station", usr, our_sleeper.occupant, "initiates a sleeper's timer ([our_sleeper.emagged ? "<strong>EMAGGED</strong>, " : ""][time] seconds), forcing %target% asleep at [log_loc(our_sleeper)].")
					else
						wake_occupant()

		// Capped at 3 min. Used to be 10 min, Christ.
		if (href_list["tp"])
			if (our_sleeper)
				var/t = text2num(href_list["tp"])
				if (t > 0 && timing && our_sleeper.occupant)
					// People do use sleepers for grief from time to time.
					logTheThing("station", usr, our_sleeper.occupant, "increases a sleeper's timer ([our_sleeper.emagged ? "<strong>EMAGGED</strong>, " : ""]occupied by %target%) by [t] seconds at [log_loc(our_sleeper)].")
				time = min(180, max(0, time + t))

		if (href_list["rejuv"])
			if (our_sleeper && our_sleeper.occupant)
				if (timing)
					// So they can't combine this with manual injections to spam/farm reagents.
					usr.show_text("Occupant alarm clock active. Manual injection unavailable.", "red")
				else
					our_sleeper.inject(usr, 1)

		if (href_list["refresh"])
			if (!our_sleeper)
				find_sleeper()

		if (href_list["eject_occupant"])
			if (our_sleeper && our_sleeper.occupant)
				our_sleeper.go_out()
				usr.machine = null
				usr << browse(null, "window=sleeper")

		updateUsrDialog()
		return

////////////////////////////////////////////// Sleeper ////////////////////////////////////////

/obj/machinery/sleeper
	name = "sleeper"
	icon = 'icons/obj/Cryogenic2.dmi'
	icon_state = "sleeper_0"
	desc = "An enterable machine that analyzes and stabilizes the vital signs of the occupant."
	density = 1
	anchored = 1
	mats = 25
	var/mob/occupant = null
	var/obj/machinery/power/data_terminal/data_link = null
	var/net_id = null //net id for control over powernet

	var/no_med_spam = 0 // In relation to world time.
	var/med_stabilizer = "saline" // Basic med that will always be injected.
	var/med_crit = "ephedrine" // If < -25 health.
	var/med_oxy = "salbutamol" // If > +15 OXY.
	var/med_tox = "charcoal" // If > +15 TOX.

	var/emagged = 0
	var/list/med_emag = list("sulfonal", "toxin", "mercury") // Picked at random per injection.

	New()
		..()
		spawn (6)
			if (src && !data_link)
				var/turf/T = get_turf(src)
				var/obj/machinery/power/data_terminal/test_link = locate() in T
				if (test_link && !test_link.is_valid_master(test_link.master))
					data_link = test_link
					data_link.master = src
			net_id = format_net_id("\ref[src]")

	proc/update_icon()
		if (!src)
			return
		icon_state = "sleeper_[!isnull(occupant)]"
		return

	ex_act(severity)
		switch (severity)
			if (1.0)
				for (var/atom/movable/A as mob|obj in src)
					A.set_loc(loc)
					A.ex_act(severity)
				qdel(src)
				return
			if (2.0)
				if (prob(50))
					for (var/atom/movable/A as mob|obj in src)
						A.set_loc(loc)
						A.ex_act(severity)
					qdel(src)
					return
			if (3.0)
				if (prob(25))
					for (var/atom/movable/A as mob|obj in src)
						A.set_loc(loc)
						A.ex_act(severity)
					qdel(src)
					return
		return

	// Let's get us some poisons.
	emag_act(var/mob/user, var/obj/item/card/emag/E)
		add_fingerprint(user)
		if (emagged == 1)
			return FALSE
		else
			emagged = 1
			if (user && ismob(user))
				user.show_text("You short out the [name]'s reagent synthesis safety protocols.", "blue")
			visible_message("<span style=\"color:red\"><strong>The [name] buzzes oddly!</strong></span>")
			logTheThing("station", user, occupant, "emags a [name] [occupant ? "with %target% inside " : ""](setting it to inject poisons) at [log_loc(src)].")
			return TRUE

	demag(var/mob/user)
		if (!emagged)
			return FALSE
		if (user)
			user.show_text("You repair the [name]'s reagent synthesis safety protocols.", "blue")
		emagged = 0
		return TRUE

	blob_act(var/power)
		if (prob(power * 3.75))
			for (var/atom/movable/A as mob|obj in src)
				A.set_loc(loc)
				A.blob_act(power)
			qdel(src)
		return

	relaymove(mob/user as mob)
		if (usr.stat != 0 || usr.stunned != 0)
			return
		go_out()
		return

	allow_drop()
		return FALSE

	attackby(obj/item/grab/G as obj, mob/user as mob)
		add_fingerprint(user)

		if (!istype(G, /obj/item/grab) || !ismob(G.affecting))
			..()
			return
		if (occupant)
			user.show_text("The [name] is already occupied!", "red")
			return

		var/mob/M = G.affecting
		M.set_loc(src)
		occupant = M
		update_icon()
		#ifdef DATALOGGER
		game_stats.Increment("sleeper")
		#endif
		for (var/obj/O in src)
			O.set_loc(loc)
		qdel(G)
		return

	// Makes sense, I suppose. They're on the shuttles too.
	powered()
		return

	use_power()
		return

	power_change()
		return

	// Called by sleeper console once per tick when occupant is asleep/hibernating.
	alter_health(var/mob/living/M as mob)
		if (!M || !isliving(M))
			return
		if (M.stat == 2)
			return

		// We always inject this, even when emagged to mask the fact we're malfunctioning.
		// Otherwise, one glance at the control console would be sufficient.
		if (M.reagents.get_reagent_amount(med_stabilizer) == 0)
			M.reagents.add_reagent(med_stabilizer, 2)

		// Why not, I guess? Might convince people to willingly enter hiberation, providing
		// traitorous MDs with a good opportunity to off somebody with an emagged sleeper.
		if (M.ailments)
			for (var/ailment_data/D in M.ailments)
				if (istype(D.master, /ailment/addiction))
					var/ailment_data/addiction/A = D
					var/probability = 5
					if (world.timeofday > A.last_reagent_dose + 1500)
						probability = 10
					if (prob(probability))
						//DEBUG("Healed [M]'s [A.associated_reagent] addiction.")
						M.show_text("You no longer feel reliant on [A.associated_reagent]!", "blue")
						M.ailments -= A
						qdel(A)

		// No life-saving meds for you, buddy.
		if (emagged)
			var/our_poison = pick(med_emag)
			if (M.reagents.get_reagent_amount(our_poison) == 0)
				//DEBUG("Injected occupant with [our_poison] at [log_loc(src)].")
				M.reagents.add_reagent(our_poison, 2)
		else
			if (M.health < -25 && M.reagents.get_reagent_amount(med_crit) == 0)
				M.reagents.add_reagent(med_crit, 2)
			if (M.get_oxygen_deprivation() >= 15 && M.reagents.get_reagent_amount(med_oxy) == 0)
				M.reagents.add_reagent(med_oxy, 2)
			if (M.get_toxin_damage() >= 15 && M.reagents.get_reagent_amount(med_tox) == 0)
				M.reagents.add_reagent(med_tox, 2)

		no_med_spam = world.time // So they can't combine this with manual injections.
		return

	// Called by sleeper console when injecting stuff manually.
	proc/inject(mob/user_feedback as mob, var/manual_injection = 0)
		if (!src)
			return
		if (occupant)
			if (occupant.stat == 2)
				if (user_feedback && ismob(user_feedback))
					user_feedback.show_text("The occupant is dead.", "red")
				return
			if (no_med_spam && world.time < no_med_spam + 50)
				if (user_feedback && ismob(user_feedback))
					user_feedback.show_text("The reagent synthesizer is recharging.", "red")
				return

			var/crit = occupant.reagents.get_reagent_amount(med_crit)
			var/rejuv = occupant.reagents.get_reagent_amount(med_stabilizer)
			var/oxy = occupant.reagents.get_reagent_amount(med_oxy)
			var/tox = occupant.reagents.get_reagent_amount(med_tox)

			// We always inject this, even when emagged to mask the fact we're malfunctioning.
			// Otherwise, one glance at the control console would be sufficient.
			if (rejuv < 10)
				var/inject_r = 5
				if ((rejuv + 5) > 10)
					inject_r = max(0, (10 - rejuv))
				occupant.reagents.add_reagent(med_stabilizer, inject_r)

			// No life-saving meds for you, buddy.
			if (emagged)
				var/our_poison = pick(med_emag)
				var/poison = occupant.reagents.get_reagent_amount(our_poison)
				if (poison < 5)
					var/inject_p = 2.5
					if ((poison + 2.5) > 5)
						inject_p = max(0, (2.5 - poison))
					occupant.reagents.add_reagent(our_poison, inject_p)
					//DEBUG("Injected occupant with [inject_p] units of [our_poison] at [log_loc(src)].")
					if (manual_injection == 1)
						logTheThing("station", user_feedback, occupant, "manually injects %target% with [our_poison] ([inject_p]) from an emagged sleeper at [log_loc(src)].")
			else
				if (occupant.health < -25 && crit < 10)
					var/inject_c = 5
					if ((crit + 5) > 10)
						inject_c = max(0, (10 - crit))
					occupant.reagents.add_reagent(med_crit, inject_c)

				if (occupant.get_oxygen_deprivation() >= 15 && oxy < 10)
					var/inject_o = 5
					if ((oxy + 5) > 10)
						inject_o = max(0, (10 - oxy))
					occupant.reagents.add_reagent(med_oxy, inject_o)

				if (occupant.get_toxin_damage() >= 15 && tox < 10)
					var/inject_t = 5
					if ((tox + 5) > 10)
						inject_t = max(0, (10 - tox))
					occupant.reagents.add_reagent(med_tox, inject_t)

			no_med_spam = world.time

		return

	proc/go_out()
		if (!src || !occupant)
			return
		for (var/obj/O in src)
			O.set_loc(loc)
		add_fingerprint(usr)
		occupant.set_loc(loc)
		occupant.weakened = 2
		occupant = null
		update_icon()
		return

	verb/move_inside()
		set src in oview(1)
		set category = "Local"

		if (!src) return
		if (usr.stat || usr.stunned || usr.weakened || usr.paralysis) return
		if (occupant)
			usr.show_text("The [name] is already occupied!", "red")
			return
		usr.pulling = null
		usr.set_loc(src)
		occupant = usr
		update_icon()
		for (var/obj/O in src)
			O.set_loc(loc)
		return

	verb/eject()
		set src in oview(1)
		set category = "Local"

		if (!src) return
		if (usr.stat != 0 || usr.stunned != 0) return
		go_out()
		return

	//Sleeper communication over powernet link thing.
	receive_signal(signal/signal)
		if (stat & (NOPOWER|BROKEN) || !data_link)
			return
		if (!signal || !net_id || signal.encryption)
			return

		if (signal.transmission_method != TRANSMISSION_WIRE) //No radio for us thanks
			return

		//They don't need to target us specifically to ping us.
		//Otherwise, ff they aren't addressing us, ignore them
		if (signal.data["address_1"] != net_id)
			if ((signal.data["address_1"] == "ping") && signal.data["sender"])
				var/signal/pingsignal = get_free_signal()
				pingsignal.data["device"] = "MED_SLEEPER"
				pingsignal.data["netid"] = net_id
				pingsignal.data["address_1"] = signal.data["sender"]
				pingsignal.data["command"] = "ping_reply"
				pingsignal.data["sender"] = net_id
				pingsignal.transmission_method = TRANSMISSION_WIRE
				spawn (5) //Send a reply for those curious jerks
					data_link.post_signal(src, pingsignal)

			return

		var/sigcommand = lowertext(signal.data["command"])
		if (!sigcommand || !signal.data["sender"])
			return

		switch(sigcommand)
			if ("status") //How is our patient doing?
				var/patient_stat = "NONE"
				if (occupant)
					patient_stat = "[occupant.get_brute_damage()];[occupant.get_burn_damage()];[occupant.get_toxin_damage()];[occupant.get_oxygen_deprivation()]"

				var/signal/reply = new
				reply.data["command"] = "device_reply"
				reply.data["status"] = patient_stat
				reply.data["address_1"] = signal.data["sender"]
				reply.data["sender"] = net_id
				reply.transmission_method = TRANSMISSION_WIRE
				spawn (5)
					data_link.post_signal(src, reply)

			if ("inject")
				inject(null, 1)

		return

/obj/machinery/sleeper/portable
	name = "Port-A-Medbay"
	desc = "Huh... so that's where it went..."
	icon = 'icons/obj/porters.dmi'
	icon_state = "med_0"
	anchored = 0

	update_icon()
		icon_state = "med_[!isnull(occupant)]"
		return