/* Contains:
- Single tank bomb logs
- Single tank bomb (proximity)
- Single tank bomb (timer)
- Single tank bomb (remote signaller)
*/

// Just a little helper. These three bombs are very similar (Convair880).
/obj/item/assembly/proc/bomb_logs(var/mob/user, var/obj/item/bomb, var/type = "", var/welded_or_unwelded = 0, var/is_dud = 0)
	if (!bomb || !type)
		return

	if (is_dud == 1)
		message_admins("A [type] single tank bomb would have opened at [log_loc(bomb)] but was forced to dud! Last touched by: [bomb.fingerprintslast ? "[bomb.fingerprintslast]" : "*null*"]")
		logTheThing("bombing", null, null, "A [type] single tank bomb would have opened at [log_loc(bomb)] but was forced to dud! Last touched by: [bomb.fingerprintslast ? "[bomb.fingerprintslast]" : "*null*"]")
		return

	var/obj/item/tank/T = null

	if (istype(bomb, /obj/item/assembly/proximity_bomb))
		var/obj/item/assembly/proximity_bomb/PB = bomb
		if (PB.part3)
			T = PB.part3
	if (istype(bomb, /obj/item/assembly/time_bomb))
		var/obj/item/assembly/time_bomb/TB = bomb
		if (TB.part3)
			T = TB.part3
	if (istype(bomb, /obj/item/assembly/radio_bomb))
		var/obj/item/assembly/radio_bomb/RB = bomb
		if (RB.part3)
			T = RB.part3

	if (!T || !istype(T, /obj/item/tank))
		return

	logTheThing("bombing", user, null, "[welded_or_unwelded == 0 ? "welded" : "unwelded"] a [type] single tank bomb [log_atmos(T)] at [log_loc(user)].")
	if (welded_or_unwelded == 0)
		message_admins("[key_name(user)] welded a [type] single tank bomb at [log_loc(user)]. See bombing logs or bomb monitor for complete atmos readout.")

	return

/////////////////////////////////////////////////// Single tank bomb (proximity) ////////////////////////////////////

/obj/item/assembly/proximity_bomb
	desc = "A very intricate igniter and proximity sensor electrical assembly mounted onto top of a plasma tank."
	name = "Proximity/Igniter/Plasma Tank Assembly"
	icon_state = "prox-igniter-tank0"
	var/obj/item/device/prox_sensor/part1 = null
	var/obj/item/device/igniter/part2 = null
	var/obj/item/tank/plasma/part3 = null
	status = 0.0
	flags = FPRINT | TABLEPASS| CONDUCT

/obj/item/assembly/proximity_bomb/dropped()

	spawn ( 0 )
		part1.sense()
		return
	return

/obj/item/assembly/proximity_bomb/examine()
	..()
	part3.examine()

/obj/item/assembly/proximity_bomb/disposing()
	qdel(part1)
	part1 = null
	qdel(part2)
	part2 = null
	qdel(part3)
	part3 = null
	..()
	return

/obj/item/assembly/proximity_bomb/attackby(obj/item/W as obj, mob/user as mob)
	if ((istype(W, /obj/item/wrench) && !( status )))
		var/obj/item/assembly/prox_ignite/R = new /obj/item/assembly/prox_ignite(  )
		R.part1 = part1
		R.part2 = part2
		user.put_in_hand_or_drop(R)
		part1.set_loc(R)
		part2.set_loc(R)
		part1.master = R
		part2.master = R
		var/turf/T = loc
		if (!( istype(T, /turf) ))
			T = T.loc
		if (!( istype(T, /turf) ))
			T = T.loc
		part3.set_loc(T)
		part1 = null
		part2 = null
		part3 = null
		//SN src = null
		qdel(src)
		return
	if (!( istype(W, /obj/item/weldingtool) ))
		return
	if (!( status ))
		status = 1
		user.show_message("<span style=\"color:blue\">A pressure hole has been bored to the plasma tank valve. The plasma tank can now be ignited.</span>", 1)
	else
		status = 0
		boutput(user, "<span style=\"color:blue\">The hole has been closed.</span>")

	bomb_logs(user, src, "proximity", status == 1 ? 0 : 1, 0)
	part2.status = status
	add_fingerprint(user)
	return

/obj/item/assembly/proximity_bomb/attack_self(mob/user as mob)

	playsound(loc, "sound/weapons/armbomb.ogg", 100, 1)
	part1.attack_self(user, 1)
	add_fingerprint(user)
	return

/obj/item/assembly/proximity_bomb/receive_signal()
	//boutput(world, "miptank [src] got signal")
	for (var/mob/O in hearers(1, null))
		O.show_message("[bicon(src)] *beep* *beep*", 3, "*beep* *beep*", 2)
		//Foreach goto(19)

	if (status)
		part1.armed = 0
		c_state(0)
		if (force_dud == 1)
			bomb_logs(usr, src, "proximity", 0, 1)
			return
		part3.ignite()
	else
		if (!status && force_dud == 0)
			part1.armed = 0
			c_state(0)
			part3.release()

	return

/obj/item/assembly/proximity_bomb/c_state(n)

	icon_state = text("prox-igniter-tank[]", n)
	return

/obj/item/assembly/proximity_bomb/HasProximity(atom/movable/AM as mob|obj)
	if (istype(AM, /obj/projectile))
		return
	if (AM.move_speed < 12 && part1)
		part1.sense()
	return

/obj/item/assembly/proximity_bomb/Bump(atom/O)
	spawn (0)
		//boutput(world, "miptank bumped into [O]")
		if (part1.armed)
			//boutput(world, "sending signal")
			receive_signal()
		else
			//boutput(world, "not active")
	..()

/obj/item/assembly/proximity_bomb/proc/prox_check()
	if (!part1 || !part1.armed)
		return
	for (var/atom/A in view(1, loc))
		if (A!=src && !istype(A, /turf/space) && !isarea(A))
			//boutput(world, "[A]:[A.type] was sensed")
			part1.sense()
			break

	spawn (10)
		prox_check()

/////////////////////////////////////////////////// Single tank bomb (timer) ////////////////////////////////////

/obj/item/assembly/time_bomb
	desc = "A very intricate igniter and timer assembly mounted onto top of a plasma tank."
	name = "Timer/Igniter/Plasma Tank Assembly"
	icon_state = "timer-igniter-tank0"
	var/obj/item/device/timer/part1 = null
	var/obj/item/device/igniter/part2 = null
	var/obj/item/tank/plasma/part3 = null
	status = 0.0
	flags = FPRINT | TABLEPASS| CONDUCT

/obj/item/assembly/time_bomb/c_state(n)

	icon_state = text("timer-igniter-tank[]", n)
	return

/obj/item/assembly/time_bomb/examine()
	..()
	part3.examine()

/obj/item/assembly/time_bomb/disposing()
	qdel(part1)
	part1 = null
	qdel(part2)
	part2 = null
	qdel(part3)
	part3 = null
	..()
	return

/obj/item/assembly/time_bomb/attackby(obj/item/W as obj, mob/user as mob)
	if ((istype(W, /obj/item/wrench) && !( status )))
		var/obj/item/assembly/time_ignite/R = new /obj/item/assembly/time_ignite(  )
		R.part1 = part1
		R.part2 = part2
		user.put_in_hand_or_drop(R)
		part1.set_loc(R)
		part2.set_loc(R)
		part1.master = R
		part2.master = R
		var/turf/T = loc
		if (!( istype(T, /turf) ))
			T = T.loc
		if (!( istype(T, /turf) ))
			T = T.loc
		part3.set_loc(T)
		part1 = null
		part2 = null
		part3 = null
		//SN src = null
		qdel(src)
		return
	if (!( istype(W, /obj/item/weldingtool) ))
		return
	if (!( status ))
		status = 1
		user.show_message("<span style=\"color:blue\">A pressure hole has been bored to the plasma tank valve. The plasma tank can now be ignited.</span>", 1)
	else
		status = 0
		boutput(user, "<span style=\"color:blue\">The hole has been closed.</span>")

	part2.status = status
	bomb_logs(user, src, "timer", status == 1 ? 0 : 1, 0)
	add_fingerprint(user)
	return

/obj/item/assembly/time_bomb/attack_self(mob/user as mob)

	if (part1)
		part1.attack_self(user, 1)
		playsound(loc, "sound/weapons/armbomb.ogg", 100, 1)
	add_fingerprint(user)
	return

/obj/item/assembly/time_bomb/receive_signal()
	//boutput(world, "tiptank [src] got signal")
	for (var/mob/O in hearers(1, null))
		O.show_message("[bicon(src)] *beep* *beep*", 3, "*beep* *beep*", 2)
	if (status)
		if (force_dud == 1)
			bomb_logs(usr, src, "timer", 0, 1)
			return
		part3.ignite()
	else
		if (!status && force_dud == 0)
			part3.release()
	return

/////////////////////////////////////////////////// Single tank bomb (remote signaller) ////////////////////////////////////

/obj/item/assembly/radio_bomb
	desc = "A very intricate igniter and signaller electrical assembly mounted onto top of a plasma tank."
	name = "Radio/Igniter/Plasma Tank Assembly"
	icon_state = "radio-igniter-tank"
	var/obj/item/device/radio/signaler/part1 = null
	var/obj/item/device/igniter/part2 = null
	var/obj/item/tank/plasma/part3 = null
	status = 0.0
	flags = FPRINT | TABLEPASS| CONDUCT

/obj/item/assembly/radio_bomb/examine()
	..()
	part3.examine()

/obj/item/assembly/radio_bomb/Del()

	//part1 = null
	qdel(part1)
	//part2 = null
	qdel(part2)
	//part3 = null
	qdel(part3)
	..()
	return

/obj/item/assembly/radio_bomb/attackby(obj/item/W as obj, mob/user as mob)
	if ((istype(W, /obj/item/wrench) && !( status )))
		var/obj/item/assembly/rad_ignite/R = new /obj/item/assembly/rad_ignite(  )
		R.part1 = part1
		R.part2 = part2
		user.put_in_hand_or_drop(R)
		part1.set_loc(R)
		part2.set_loc(R)
		part1.master = R
		part2.master = R
		var/turf/T = loc
		if (!( istype(T, /turf) ))
			T = T.loc
		if (!( istype(T, /turf) ))
			T = T.loc
		part3.set_loc(T)
		part1 = null
		part2 = null
		part3 = null
		//SN src = null
		qdel(src)
		return
	if (!( istype(W, /obj/item/weldingtool) ))
		return
	if (!( status ))
		status = 1
		user.show_message("<span style=\"color:blue\">A pressure hole has been bored to the plasma tank valve. The plasma tank can now be ignited.</span>", 1)
	else
		status = 0
		boutput(user, "<span style=\"color:blue\">The hole has been closed.</span>")

	bomb_logs(user, src, "radio", status == 1 ? 0 : 1, 0)
	part2.status = status
	part1.b_stat = !( status )
	add_fingerprint(user)
	return

/obj/item/assembly/radio_bomb/attack_self(mob/user as mob)

	if (part1)
		playsound(loc, "sound/weapons/armbomb.ogg", 100, 1)
		part1.attack_self(user, 1)
	add_fingerprint(user)
	return

/obj/item/assembly/radio_bomb/receive_signal()
	//boutput(world, "riptank [src] got signal")
	for (var/mob/O in hearers(1, null))
		O.show_message("[bicon(src)] *beep* *beep*", 3, "*beep* *beep*", 2)
	if (status)
		if (force_dud == 1)
			bomb_logs(usr, src, "radio", 0, 1)
			return
		part3.ignite()
	else
		if (!status && force_dud == 0)
			part3.release()
	return