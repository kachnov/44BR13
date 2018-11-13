/*
CONTAINS:
LOCATOR
HAND_TELE

*/
/obj/item/locator
	name = "locator"
	icon = 'icons/obj/device.dmi'
	icon_state = "locator"
	var/temp = null
	var/frequency = 1451
	var/broadcasting = null
	var/listening = 1.0
	flags = FPRINT | TABLEPASS| CONDUCT
	w_class = 2.0
	item_state = "electronic"
	throw_speed = 4
	throw_range = 20
	m_amt = 400

/obj/item/locator/attack_self(mob/user as mob)
	user.machine = src
	var/dat
	if (temp)
		dat = "[temp]<BR><BR><A href='byond://?src=\ref[src];temp=1'>Clear</A>"
	else
		dat = {"
<strong>Persistent Signal Locator</strong><HR>
Frequency:
<A href='byond://?src=\ref[src];freq=-10'>-</A>
<A href='byond://?src=\ref[src];freq=-2'>-</A> [format_frequency(frequency)]
<A href='byond://?src=\ref[src];freq=2'>+</A>
<A href='byond://?src=\ref[src];freq=10'>+</A><BR>

<A href='?src=\ref[src];refresh=1'>Refresh</A>"}
	user << browse(dat, "window=radio")
	onclose(user, "radio")
	return

/obj/item/locator/Topic(href, href_list)
	..()
	if (usr.stat || usr.restrained())
		return
	if ((usr.contents.Find(src) || (in_range(src, usr) && istype(loc, /turf))))
		usr.machine = src
		if (href_list["refresh"])
			temp = "<strong>Persistent Signal Locator</strong><HR>"
			var/turf/sr = get_turf(src)

			if (sr)
				temp += "<strong>Located Beacons:</strong><BR>"

				for (var/obj/item/device/radio/beacon/W in world)
					if (W.frequency == frequency)
						var/turf/tr = get_turf(W)
						if (tr.z == sr.z && tr)
							var/direct = max(abs(tr.x - sr.x), abs(tr.y - sr.y))
							if (direct < 5)
								direct = "very strong"
							else
								if (direct < 10)
									direct = "strong"
								else
									if (direct < 20)
										direct = "weak"
									else
										direct = "very weak"
							temp += "[dir2text(get_dir(sr, tr))]-[direct]<BR>"

				temp += "<strong>Extranneous Signals:</strong><BR>"
				for (var/obj/item/implant/tracking/W in world)
					if (W.frequency == frequency)
						if (!W.implanted || !ismob(W.loc))
							continue
						else
							var/mob/M = W.loc
							if (M.stat == 2)
								if (M.timeofdeath + 6000 < world.time)
									continue

						var/turf/tr = get_turf(W)
						if (tr.z == sr.z && tr)
							var/direct = max(abs(tr.x - sr.x), abs(tr.y - sr.y))
							if (direct < 20)
								if (direct < 5)
									direct = "very strong"
								else
									if (direct < 10)
										direct = "strong"
									else
										direct = "weak"
								temp += "[W.id]-[dir2text(get_dir(sr, tr))]-[direct]<BR>"

				temp += "<strong>You are at \[[sr.x],[sr.y],[sr.z]\]</strong> in orbital coordinates.<BR><BR><A href='byond://?src=\ref[src];refresh=1'>Refresh</A><BR>"
			else
				temp += "<strong><FONT color='red'>Processing Error:</FONT></strong> Unable to locate orbital position.<BR>"
		else
			if (href_list["freq"])
				frequency += text2num(href_list["freq"])
				frequency = sanitize_frequency(frequency)
			else
				if (href_list["temp"])
					temp = null
		if (istype(loc, /mob))
			attack_self(loc)
		else
			for (var/mob/M in viewers(1, src))
				if (M.client)
					attack_self(M)
	return

/// HAND TELE

/obj/item/hand_tele
	name = "hand tele"
	icon = 'icons/obj/device.dmi'
	icon_state = "hand_tele"
	item_state = "electronic"
	throwforce = 5
	w_class = 2.0
	throw_speed = 3
	throw_range = 5
	m_amt = 10000
	var/unscrewed = 0
	mats = 8
	desc = "An experimental portable teleportation device that can create portals that link to the same destination as a teleport computer."
	var/obj/item/our_target = null
	var/turf/our_random_target = null
	var/list/portals = list()

	// Port of the telegun improvements (Convair880).
	attack_self(mob/user as mob)
		add_fingerprint(user)

		if (portals.len > 2)
			user.show_text("The hand teleporter is recharging!", "red")
			return

		var/turf/our_loc = get_turf(src)
		if (isrestrictedz(our_loc.z))
			user.show_text("The [name] does not seem to work here!", "red")
			return

		var/list/L = list()
		L += "Cancel" // So we'll always get a list.

		// Default option that should always be available, regardless of number of teleporters (or lack thereof).
		var/list/random_turfs = list()
		for (var/turf/T in orange(10))
			var/area/tele_check = get_area(T)
			if (T.x > world.maxx-4 || T.x < 4) // Don't put them at the edge.
				continue
			if (T.y > world.maxy-4 || T.y < 4)
				continue
			if (tele_check.teleport_blocked)
				continue
			random_turfs += T
		if (random_turfs && random_turfs.len)
			L["None (Dangerous)"] += pick(random_turfs)

		for (var/obj/machinery/teleport/portal_generator/PG in machines)
			if (!PG.linked_computer || !PG.linked_rings)
				continue
			var/turf/PG_loc = get_turf(PG)
			if (PG && isrestrictedz(PG_loc.z)) // Don't show teleporters in "somewhere", okay.
				continue

			var/obj/machinery/computer/teleporter/Control = PG.linked_computer
			if (Control)
				switch (Control.check_teleporter())
					if (0) // It's busted, Jim.
						continue
					if (1)
						L["Tele at [get_area(Control)]: Locked in ([ismob(Control.locked.loc) ? "[Control.locked.loc.name]" : "[get_area(Control.locked)]"])"] += Control
					if (2)
						L["Tele at [get_area(Control)]: *NOPOWER*"] += Control
					if (3)
						L["Tele at [get_area(Control)]: Inactive"] += Control
			else
				continue

		if (L.len < 2) // Shouldn't happen, but you never know.
			user.show_text("Error: couldn't find valid coordinates or working teleporters.", "red")
			return

		var/t1 = input(user, "Please select a teleporter to lock in on.", "Target Selection") in L
		if ((user.equipped() != src) || user.stat || user.restrained())
			return
		if (t1 == "Cancel")
			return

		// "None" is a random turf, whereas computer-assisted teleportation locks on to a beacon or tracking implant.
		if (t1 == "None (Dangerous)")
			our_random_target = L[t1]
			our_target = null
			user.show_text("Warning: Hand tele locked in on random coordinates.", "red")
		else
			var/obj/machinery/computer/teleporter/Control2 = L[t1]
			if (Control2)
				our_target = null
				our_random_target = null
				switch (Control2.check_teleporter())
					if (0)
						user.show_text("Error: selected teleporter is out of order.", "red")
						return
					if (1)
						our_target = Control2.locked
						if (!our_target)
							user.show_text("Error: selected teleporter is locked in to invalid coordinates.", "red")
							return
						else
							user.show_text("Teleporter selected. Locked in on [ismob(Control2.locked.loc) ? "[Control2.locked.loc.name]" : "beacon"] in [get_area(Control2.locked)].", "blue")
					if (2)
						user.show_text("Error: selected teleporter is unpowered.", "red")
						return
					if (3)
						user.show_text("Error: selected teleporter is not locked in.", "red")
						return
			else
				user.show_text("Error: couldn't establish connection to selected teleporter.", "red")
				return

		if (!our_target && !our_random_target)
			user.show_text("Error: invalid coordinates detected, please try again.", "red")
			return

		var/obj/portal/P = unpool(/obj/portal)
		P.set_loc(get_turf(src))
		portals += P
		if (!our_target)
			P.target = our_random_target
		else
			P.target = our_target

		for (var/mob/O in hearers(user, null))
			O.show_message("<span style=\"color:blue\">Portal opened.</span>", 2)
		logTheThing("station", user, null, "creates a hand tele portal (<strong>Destination:</strong> [our_target ? "[log_loc(our_target)]" : "*random coordinates*"]) at [log_loc(user)].")

		spawn (300)
			if (P)
				portals -= P
				pool(P)

		return