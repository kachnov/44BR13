/obj/item/device/prox_sensor
	name = "Proximity Sensor"
	icon_state = "motion0"
	var/armed = 0.0
	var/timing = 0.0
	var/time = null
	flags = FPRINT | TABLEPASS| CONDUCT
	w_class = 2.0
	item_state = "electronic"
	m_amt = 300
	mats = 2
	desc = "A device which transmits a signal when it detects movement nearby."
	module_research = list("science" = 2, "devices" = 1, "miniaturization" = 4)

/obj/item/device/prox_sensor/dropped()
	..()
	spawn (0)
		sense()

/obj/item/device/prox_sensor/proc/update_icon()
	var/n = 0
	if (armed) n = 1
	else if (timing) n = 2

	icon_state = "motion[n]"

	if (master)
		master:c_state(n)

	return

/obj/item/device/prox_sensor/proc/sense()
	if (armed == 1)
		if (master)
			spawn (0)
				var/signal/signal = get_free_signal()
				signal.source = src
				signal.data["message"] = "ACTIVATE"
				master.receive_signal(signal)
				return
		else
			for (var/mob/O in hearers(null, null))
				O.show_message("[bicon(src)] *beep* *beep*", 3, "*beep* *beep*", 2)
	return

/obj/item/device/prox_sensor/process()
	if (timing)
		if (time > 0)
			if (armed != 1)
				update_icon()
				time = round(time) - 1
			else timing = 0
		else
			armed = 1
			time = 0
			timing = 0
			update_icon()
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
		processing_items.Remove(src)
		return
	return

/obj/item/device/prox_sensor/HasProximity(atom/movable/AM as mob|obj)
	if (istype(AM, /obj/projectile))
		return
	if (AM.move_speed < 12)
		sense()
	return

/obj/item/device/prox_sensor/attackby(obj/item/device/radio/signaler/S as obj, mob/user as mob)
	if ((!( istype(S, /obj/item/device/radio/signaler) ) || !( S.b_stat )))
		return
	var/obj/item/assembly/rad_prox/R = new /obj/item/assembly/rad_prox( user )
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

/obj/item/device/prox_sensor/attack_self(mob/user as mob)
	if (user.stat || user.restrained() || user.lying)
		return
	if ((src in user) || (master && master in user) || get_dist(src, user) <= 1 && istype(loc, /turf))
		user.machine = src
		var/second = time % 60
		var/minute = (time - second) / 60
		var/dat = text("<TT><strong>Proximity Sensor</strong><br>[] []:[]<br><A href='?src=\ref[];tp=-30'>-</A> <A href='?src=\ref[];tp=-1'>-</A> <A href='?src=\ref[];tp=1'>+</A> <A href='?src=\ref[];tp=30'>+</A><br></TT>", (timing ? text("<A href='?src=\ref[];time=0'>Timing</A>", src) : text("<A href='?src=\ref[];time=1'>Not Timing</A>", src)), minute, second, src, src, src, src)
		dat += "<BR><A href='?src=\ref[src];arm=1'>[armed ? "Armed":"Not Armed"]</A> (Movement sensor active when armed!)"
		dat += "<BR><BR><A href='?src=\ref[src];close=1'>Close</A>"
		user << browse(dat, "window=prox")
		onclose(user, "prox")
	else
		user << browse(null, "window=prox")
		user.machine = null
		return

/obj/item/device/prox_sensor/Topic(href, href_list)
	..()
	if (usr.stat || usr.restrained() || usr.lying)
		return
	if ((src in usr) || (master && (master in usr)) || ((get_dist(src, usr) <= 1) && istype(loc, /turf)))
		usr.machine = src
		if (href_list["arm"])
			armed = !armed
			update_icon()
			if (timing || armed && !(src in processing_items))
				processing_items.Add(src)

			var/turf/T = get_turf(src)
			if (master && istype(master, /obj/item/device/transfer_valve))
				logTheThing("bombing", usr, null, "[armed ? "armed" : "disarmed"] a proximity device on a transfer valve at [showCoords(T.x, T.y, T.z)].")
				message_admins("[key_name(usr)] [armed ? "armed" : "disarmed"] a proximity device on a transfer valve at [showCoords(T.x, T.y, T.z)].")
			else if (master && istype(master, /obj/item/assembly/prox_ignite)) //Prox-detonated beaker assemblies
				var/obj/item/assembly/rad_ignite/RI = master
				logTheThing("bombing", usr, null, "[armed ? "armed" : "disarmed"] a proximity device on a radio-igniter assembly at [T ? showCoords(T.x, T.y, T.z) : "horrible no-loc nowhere void"]. Contents: [log_reagents(RI.part3)]")

			else if (master && istype(master, /obj/item/assembly/proximity_bomb))	//Prox-detonated single-tank bombs
				logTheThing("bombing", usr, null, "[armed ? "armed" : "disarmed"] a proximity device on a single-tank bomb at [T ? showCoords(T.x, T.y, T.z) : "horrible no-loc nowhere void"].")
				message_admins("[key_name(usr)] [armed ? "armed" : "disarmed"] a proximity device on a single-tank bomb at [T ? showCoords(T.x, T.y, T.z) : "horrible no-loc nowhere void"].")

		if (href_list["time"])
			timing = text2num(href_list["time"])
			update_icon()
			if (timing || armed && !(src in processing_items))
				processing_items.Add(src)

			var/turf/T = get_turf(src)
			if (master && istype(master, /obj/item/device/transfer_valve))
				logTheThing("bombing", usr, null, "[timing ? "initiated" : "defused"] a prox-arming timer on a transfer valve at [showCoords(T.x, T.y, T.z)].")
				message_admins("[key_name(usr)] [timing ? "initiated" : "defused"] a prox-arming timer on a transfer valve at [showCoords(T.x, T.y, T.z)].")
			else if (master && istype(master, /obj/item/assembly/prox_ignite)) //Proximity-detonated beaker assemblies
				var/obj/item/assembly/rad_ignite/RI = master
				logTheThing("bombing", usr, null, "[timing ? "initiated" : "defused"] a prox-arming timer on a radio-igniter assembly at [T ? showCoords(T.x, T.y, T.z) : "horrible no-loc nowhere void"]. Contents: [log_reagents(RI.part3)]")

			else if (master && istype(master, /obj/item/assembly/proximity_bomb))	//Radio-detonated single-tank bombs
				logTheThing("bombing", usr, null, "[timing ? "initiated" : "defused"] a prox-arming timer on a single-tank bomb at [T ? showCoords(T.x, T.y, T.z) : "horrible no-loc nowhere void"].")
				message_admins("[key_name(usr)] [timing ? "initiated" : "defused"] a prox-arming timer on a single-tank bomb at [T ? showCoords(T.x, T.y, T.z) : "horrible no-loc nowhere void"].")

		if (href_list["tp"])
			var/tp = text2num(href_list["tp"])
			time += tp
			time = min(max(round(time), 0), 600)

		if (href_list["close"])
			usr << browse(null, "window=prox")
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
			if (istype(master.loc, /mob))
				attack_self(master.loc)
			else
				for (var/mob/M in viewers(1, master))
					if (M.client && (M.machine == master || M.machine == src))
						attack_self(M)
	else
		usr << browse(null, "window=prox")
		return
	return

/obj/item/device/prox_sensor/Move()
	..()
	sense()
	return