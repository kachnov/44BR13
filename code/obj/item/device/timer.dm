/obj/item/device/timer
	name = "timer"
	icon_state = "timer0"
	item_state = "electronic"
	var/timing = 0.0
	var/time = null
	var/last_tick = 0
	flags = FPRINT | TABLEPASS| CONDUCT
	w_class = 2.0
	m_amt = 100
	mats = 2
	desc = "A device that emits a signal when the time reaches 0."
	module_research = list("devices" = 1, "miniaturization" = 4)

/obj/item/device/timer/proc/time()
	c_state(0)

	if (master)
		spawn ( 0 )
			var/signal/signal = get_free_signal()
			signal.source = src
			signal.data["message"] = "ACTIVATE"
			master.receive_signal(signal)
			//qdel(signal)
			return
	else
		for (var/mob/O in hearers(null, null))
			O.show_message("[bicon(src)] *beep* *beep*", 3, "*beep* *beep*", 2)
	return

//*****RM


/obj/item/device/timer/proc/c_state(n)
	//icon_state = text("timer[]", n)

	if (master)
		master:c_state(n)

	return

//*****

/obj/item/device/timer/process()
	if (timing)
		if (!last_tick) last_tick = world.time
		var/passed_time = round(max(round(world.time - last_tick),10) / 10)

		if (time > 0)
			time -= passed_time
			if (time<5)
				c_state(2)
			else
				// they might increase the time while it is timing
				c_state(1)
		else
			time()
			time = 0
			timing = 0
			last_tick = 0

		last_tick = world.time

		if (!master)
			if (istype(loc, /mob))
				attack_self(loc)
			else
				for (var/mob/M in viewers(1, src))
					if (M.client && (M.machine == master || M.machine == src))
						attack_self(M)
		else
			if (istype(master.loc, /mob))
				attack_self(master.loc)
			else
				for (var/mob/M in viewers(1, master))
					if (M.client && (M.machine == master || M.machine == src))
						attack_self(M)
	else
		// If it's not timing, reset the icon so it doesn't look like it's still about to go off.
		c_state(0)
		processing_items.Remove(src)
		last_tick = 0

	return

/obj/item/device/timer/attackby(obj/item/W as obj, mob/user as mob)
	if (istype(W, /obj/item/device/radio/signaler) )
		var/obj/item/device/radio/signaler/S = W
		if (!S.b_stat)
			return

		var/obj/item/assembly/rad_time/R = new /obj/item/assembly/rad_time( user )
		S.set_loc(R)
		R.part1 = S
		S.layer = initial(S.layer)
		user.u_equip(S)
		user.put_in_hand_or_drop(R)
		S.master = R
		master = R
		layer = initial(layer)
		user.u_equip(src)
		set_loc(R)
		R.part2 = src
		R.dir = dir
		add_fingerprint(user)
		return

/obj/item/device/timer/attack_self(mob/user as mob)
	..()
	if (user.stat || user.restrained() || user.lying)
		return

	if ((src in user) || (master && (master in user)) || (get_dist(src, user) <= 1 && istype(loc, /turf)) || is_detonator_trigger())
		user.machine = src
		var/second = time % 60
		var/minute = (time - second) / 60
		var/detonator_trigger = is_detonator_trigger()
		var/timing_links = (timing ? text("<A href='?src=\ref[];time=0'>Timing</A>", src) : text("<A href='?src=\ref[];time=1'>Not Timing</A>", src))
		var/timing_text = (timing ? "Timing - controls locked" : "Not timing - controls unlocked")
		var/dat = text("<TT><strong>Timing Unit</strong><br>[] []:[]<br><A href='?src=\ref[];tp=-30'>-</A> <A href='?src=\ref[];tp=-1'>-</A> <A href='?src=\ref[];tp=1'>+</A> <A href='?src=\ref[];tp=30'>+</A><br></TT>", detonator_trigger ? timing_text : timing_links, minute, second, src, src, src, src)
		dat += "<BR><BR><A href='?src=\ref[src];close=1'>Close</A>"
		user << browse(dat, "window=timer")
		onclose(user, "timer")
	else
		user << browse(null, "window=timer")
		user.machine = null

	return

/obj/item/device/timer/proc/is_detonator_trigger()
	if (master)
		if (istype(src.master, /obj/item/assembly/detonator) && src.master.master)
			if (istype(src.master.master, /obj/machinery/portable_atmospherics/canister) && in_range(src.master.master, usr))
				return TRUE
	return FALSE

/obj/item/device/timer/Topic(href, href_list)
	..()
	if (usr.stat || usr.restrained() || usr.lying)
		return
	var/can_use_detonator = is_detonator_trigger() && !timing
	if (can_use_detonator || (src in usr) || (master && master in usr) || in_range(src, usr) && istype(loc, /turf))
		usr.machine = src
		if (href_list["time"])
			timing = text2num(href_list["time"])
			if (timing)
				c_state(1)
				if (!(src in processing_items))
					processing_items.Add(src)

			if (master && istype(master, /obj/item/device/transfer_valve))
				logTheThing("bombing", usr, null, "[timing ? "initiated" : "defused"] a timer on a transfer valve at [log_loc(master)].")
				message_admins("[key_name(usr)] [timing ? "initiated" : "defused"] a timer on a transfer valve at [log_loc(master)].")
			else if (master && istype(master, /obj/item/assembly/time_ignite)) //Timer-detonated beaker assemblies
				var/obj/item/assembly/rad_ignite/RI = master
				logTheThing("bombing", usr, null, "[timing ? "initiated" : "defused"] a timer on a timer-igniter assembly at [log_loc(master)]. Contents: [log_reagents(RI.part3)]")

			else if (master && istype(master, /obj/item/assembly/time_bomb))	//Timer-detonated single-tank bombs
				logTheThing("bombing", usr, null, "[timing ? "initiated" : "defused"] a timer on a single-tank bomb at [log_loc(master)].")
				message_admins("[key_name(usr)] [timing ? "initiated" : "defused"] a timer on a single-tank bomb at [log_loc(master)].")

			else if (master && istype(master, /obj/item/mine)) // Land mine.
				logTheThing("bombing", usr, null, "[timing ? "initiated" : "defused"] a timer on a [master.name] at [log_loc(master)].")

		if (href_list["tp"])
			var/tp = text2num(href_list["tp"])
			time += tp
			time = min(max(round(time), 0), 600)
			if (can_use_detonator && time < 90)
				time = 90

		if (href_list["close"])
			usr << browse(null, "window=timer")
			usr.machine = null
			return

		if (!master)
			if (istype(loc, /mob))
				attack_self(loc)
			else
				for (var/mob/M in viewers(1, src))
					if (M.client && (M.machine == master || M.machine == src))
						attack_self(M)
		else
			if (can_use_detonator)
				attack_self(usr)
			if (istype(master.loc, /mob))
				attack_self(master.loc)
			else
				for (var/mob/M in viewers(1, master))
					if (M.client && (M.machine == master || M.machine == src))
						attack_self(M)
		add_fingerprint(usr)
	else
		usr << browse(null, "window=timer")
		return
	return