/*
Contains:

- Laser tripwire
- Infrared sensor
- Remote signaller/tripwire assembly
*/

//////////////////////////////////////// Laser tripwire //////////////////////////////

/obj/item/device/infra
	name = "Laser Tripwire"
	desc = "Emits a visible or invisible beam and is triggered when the beam is interrupted."
	icon_state = "infrared0"
	var/obj/beam/i_beam/first = null
	var/state = 0.0
	var/visible = 0.0
	flags = FPRINT | TABLEPASS| CONDUCT
	w_class = 2.0
	item_state = "electronic"
	m_amt = 150
	mats = 3

///////////////////////////////////////// Infrared sensor ///////////////////////////////////////////

/obj/item/device/infra_sensor
	name = "Infrared Sensor"
	desc = "Scans for infrared beams in the vicinity."
	icon_state = "infra_sensor"
	var/passive = 1.0
	flags = FPRINT | TABLEPASS| CONDUCT
	item_state = "electronic"
	m_amt = 150
	mats = 4

/* When/if someone ever gets around to fixing these uncomment this
/obj/item/device/infra_sensor/process()
	if (passive)
		for (var/obj/beam/i_beam/I in range(2, loc))
			I.left = 2
		return TRUE

	else
		processing_items.Remove(src)
		return null

/obj/item/device/infra_sensor/proc/burst()
	for (var/obj/beam/i_beam/I in range(loc))
		I.left = 10
	for (var/obj/item/device/infra/I in range(loc))
		I.visible = 1
		spawn ( 0 )
			if ((I && I.first))
				I.first.vis_spread(1)
			return
	for (var/obj/item/assembly/rad_infra/I in range(loc))
		I.part2.visible = 1
		spawn ( 0 )
			if ((I.part2 && I.part2.first))
				I.part2.first.vis_spread(1)
			return
	return

/obj/item/device/infra_sensor/attack_self(mob/user as mob)
	user.machine = src
	var/dat = text("<TT><strong>Infrared Sensor</strong><BR><br><strong>Passive Emitter</strong>: []<BR><br><strong>Active Emitter</strong>: <A href='?src=\ref[];active=0'>Burst Fire</A><br></TT>", (passive ? text("<A href='?src=\ref[];passive=0'>On</A>", src) : text("<A href='?src=\ref[];passive=1'>Off</A>", src)), src)
	user << browse(dat, "window=infra_sensor")
	onclose(user, "infra_sensor")
	return

/obj/item/device/infra_sensor/Topic(href, href_list)
	..()
	if (usr.stat || usr.restrained())
		return
	if ((usr.contents.Find(src) || (usr.contents.Find(master) || ((get_dist(src, usr) <= 1) && istype(loc, /turf)))))
		usr.machine = src
		if (href_list["passive"])
			passive = !( passive )
			if (passive && !(src in processing_items))
				processing_items.Add(src)
		if (href_list["active"])
			spawn ( 0 )
				burst()
				return
		if (!( master ))
			if (istype(loc, /mob))
				attack_self(loc)
			else
				for (var/mob/M in viewers(1, src))
					if (M.client)
						attack_self(M)
		else
			if (istype(master.loc, /mob))
				attack_self(master.loc)
			else
				for (var/mob/M in viewers(1, master))
					if (M.client)
						attack_self(M)
		add_fingerprint(usr)
	else
		usr << browse(null, "window=infra_sensor")
		onclose(usr, "infra_sensor")
		return
	return

/obj/item/device/infra/proc/hit()
	if (master)
		spawn ()
			var/signal/signal = new
			signal.data["message"] = "ACTIVATE"
			master.receive_signal(signal)
			qdel(signal)
			return
	else
		for (var/mob/O in hearers(null, null))
			O.show_message(text("[bicon()] *beep* *beep*", src), 3, "*beep* *beep*", 2)
	return

/obj/item/device/infra/process()
	if (!state)
		processing_items.Remove(src)
		return null

	if ((!( first ) && (state && (istype(loc, /turf) || (master && istype(master.loc, /turf))))))
		var/obj/beam/i_beam/I = new /obj/beam/i_beam( (master ? master.loc : loc) )
		//boutput(world, "infra spawning beam : \ref[I]")
		I.master = src
		I.density = 1
		I.dir = dir
		step(I, I.dir)
		if (I)
			//boutput(world, "infra: beam at [I.x] [I.y] [I.z]")
			I.density = 0
			first = I
			//boutput(world, "infra : vis_spread")
			I.vis_spread(visible)
			spawn ( 0 )
				if (I)
					//boutput(world, "infra: setting limit")
					I.limit = 20
					//boutput(world, "infra: processing beam \ref[I]")
					I.process()
				return
	if (!( state ))
		//first = null
		qdel(first)
	return

/obj/item/device/infra/attackby(obj/item/device/radio/signaler/S as obj, mob/user as mob)
	if ((!( istype(S, /obj/item/device/radio/signaler) ) || !( S.b_stat )))
		return
	var/obj/item/assembly/rad_infra/R = new /obj/item/assembly/rad_infra( user )
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

/obj/item/device/infra/attack_self(mob/user as mob)
	user.machine = src
	var/dat = text("<TT><strong>Infrared Laser</strong><br><strong>Status</strong>: []<BR><br><strong>Visibility</strong>: []<BR><br></TT>", (state ? text("<A href='?src=\ref[];state=0'>On</A>", src) : text("<A href='?src=\ref[];state=1'>Off</A>", src)), (visible ? text("<A href='?src=\ref[];visible=0'>Visible</A>", src) : text("<A href='?src=\ref[];visible=1'>Invisible</A>", src)))
	user << browse(dat, "window=infra")
	onclose(user, "infra")
	return

/obj/item/device/infra/Topic(href, href_list)
	..()
	if (usr.stat || usr.restrained())
		return
	if ((usr.contents.Find(src) || usr.contents.Find(master) || in_range(src, usr) && istype(loc, /turf)))
		usr.machine = src
		if (href_list["state"])
			state = !( state )
			icon_state = text("infrared[]", state)
			if (master)
				master:c_state(state, src)
			if (state && !(src in processing_items))
				processing_items.Add(src)
		if (href_list["visible"])
			visible = !( visible )
			spawn ( 0 )
				if (first)
					first.vis_spread(visible)
				return
		if (!( master ))
			if (istype(loc, /mob))
				attack_self(loc)
			else
				for (var/mob/M in viewers(1, src))
					if (M.client)
						attack_self(M)
					//Foreach goto(211)
		else
			if (istype(master.loc, /mob))
				attack_self(master.loc)
			else
				for (var/mob/M in viewers(1, master))
					if (M.client)
						attack_self(M)
					//Foreach goto(287)
	else
		usr << browse(null, "window=infra")
		onclose(usr, "infra")
		return
	return

/obj/item/device/infra/attack_hand()
	//first = null
	qdel(first)
	..()
	return

/obj/item/device/infra/Move()
	var/t = dir
	..()
	dir = t
	//first = null
	qdel(first)
	return

/obj/item/device/infra/verb/rotate()
	set src in usr

	dir = turn(dir, 90)
	return

*/

/////////////////////////////////////// Remote signaller/tripwire assembly /////////////////////////////////

/obj/item/assembly/rad_infra
	name = "Signaller/Infrared Assembly"
	desc = "An infrared-activated radio signaller"
	icon_state = "infrared-radio0"
	var/obj/item/device/radio/signaler/part1 = null
	var/obj/item/device/infra/part2 = null
	status = null
	flags = FPRINT | TABLEPASS| CONDUCT

/obj/item/assembly/rad_infra/c_state(n)
	icon_state = text("infrared-radio[]", n)
	return
/*
/obj/item/assembly/rad_infra/Del()
	qdel(part1)
	qdel(part2)
	..()
	return

/obj/item/assembly/rad_infra/attackby(obj/item/W as obj, mob/user as mob)

	if ((istype(W, /obj/item/wrench) && !( status )))
		var/turf/T = loc
		if (ismob(T))
			T = T.loc
		part1.set_loc(T)
		part2.set_loc(T)
		part1.master = null
		part2.master = null
		part1 = null
		part2 = null
		//SN src = null
		qdel(src)
		return
	if (!( istype(W, /obj/item/screwdriver) ))
		return
	status = !( status )
	if (status)
		user.show_message("<span style=\"color:blue\">The infrared laser is now secured!</span>", 1)
	else
		user.show_message("<span style=\"color:blue\">The infrared laser is now unsecured!</span>", 1)
	part1.b_stat = !( status )
	add_fingerprint(user)
	return

/obj/item/assembly/rad_infra/attack_self(mob/user as mob)

	part1.attack_self(user, status)
	part2.attack_self(user, status)
	add_fingerprint(user)
	return

/obj/item/assembly/rad_infra/receive_signal(signal/signal)

	if (signal.source == part2)
		part1.send_signal("ACTIVATE")
	return

/obj/item/assembly/rad_infra/verb/rotate()
	set src in usr

	dir = turn(dir, 90)
	part2.dir = dir
	add_fingerprint(usr)
	return

/obj/item/assembly/rad_infra/Move()

	var/t = dir
	..()
	dir = t
	//part2.first = null
	qdel(part2.first)
	return

/obj/item/assembly/rad_infra/attack_hand(M)
	qdel(part2.first)
	..()
	return
*/