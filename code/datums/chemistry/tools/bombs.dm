
/* =============================================== */
/* -------------------- Bombs -------------------- */
/* =============================================== */

/obj/item/assembly/chem_bomb
	var/obj/item/device/triggering_device = null
	var/obj/item/device/igniter/igniter = null
	var/obj/item/chem_grenade/payload = null
	status = 0.0
	flags = FPRINT | TABLEPASS | CONDUCT
	var/mob/attacher = "Unknown"

/obj/item/assembly/chem_bomb/c_state(n)
	switch(triggering_device.type)
		if (/obj/item/device/timer)
			icon_state = text("timer-igniter-chem[]", n)
		if (/obj/item/device/prox_sensor)
			icon_state = text("prox-igniter-chem[]", n)
		if (/obj/item/device/radio/signaler)
			icon_state = "radio-igniter-chem"
	return

/obj/item/assembly/chem_bomb/HasProximity(atom/movable/AM as mob|obj)
	if (!istype(triggering_device, /obj/item/device/prox_sensor))
		return
	if (istype(AM, /obj/projectile))
		return
	if (AM.move_speed < 12 && triggering_device)
		triggering_device:sense()
	return

/obj/item/assembly/chem_bomb/Bump(atom/O)
	if (!istype(triggering_device, /obj/item/device/prox_sensor))
		return
	spawn (0)
		//boutput(world, "miptank bumped into [O]")
		if (triggering_device:state)
			//boutput(world, "sending signal")
			receive_signal()
		else
			//boutput(world, "not active")
	..()

/obj/item/assembly/chem_bomb/proc/prox_check()
	if (!istype(triggering_device, /obj/item/device/prox_sensor))
		return
	if (!triggering_device || !triggering_device:state)
		return
	for (var/atom/A in view(1, loc))
		if (A!=src && !istype(A, /turf/space) && !isarea(A))
			//boutput(world, "[A]:[A.type] was sensed")
			triggering_device:sense()
			break

	spawn (10)
		prox_check()

/obj/item/assembly/chem_bomb/dropped()
	if (!istype(triggering_device, /obj/item/device/prox_sensor))
		return
	spawn ( 0 )
		triggering_device:sense()
		return
	return

/obj/item/assembly/chem_bomb/get_desc()
	return payload.get_desc()

/obj/item/assembly/chem_bomb/Del()
	qdel(triggering_device)
	triggering_device = null
	qdel(igniter)
	igniter = null
	qdel(payload)
	payload = null
	..()	

/obj/item/assembly/chem_bomb/attackby(obj/item/W as obj, mob/user as mob)
	if (istype(W, /obj/item/wrench))
		var/obj/item/assembly/R = null
		switch(triggering_device.type)
			if (/obj/item/device/timer)
				R = new /obj/item/assembly/time_ignite()
			if (/obj/item/device/prox_sensor)
				R = new /obj/item/assembly/prox_ignite()
			if (/obj/item/device/radio/signaler)
				R = new /obj/item/assembly/rad_ignite()
		if (!R)
			return
		R:part1 = triggering_device
		R:part2 = igniter
		user.put_in_hand_or_drop(R)
		triggering_device.set_loc(R)
		igniter.set_loc(R)
		triggering_device.master = R
		igniter.master = R
		var/turf/T = loc
		if (!( istype(T, /turf) ))
			T = T.loc
		if (!( istype(T, /turf) ))
			T = T.loc
		payload.set_loc(T)
		triggering_device = null
		igniter = null
		payload = null
		//SN src = null
		qdel(src)
		return

	add_fingerprint(user)
	return

/obj/item/assembly/chem_bomb/attack_self(mob/user as mob)
	playsound(loc, 'sound/weapons/armbomb.ogg', 100, 1)
	// drsingh for Cannot execute null.attack self()
	if (isnull(src) || isnull(triggering_device))
		return

	triggering_device.attack_self(user, 1)
	add_fingerprint(user)
	return

/obj/item/assembly/chem_bomb/receive_signal()
	//boutput(world, "miptank [src] got signal")
	for (var/mob/O in hearers(1, null))
		O.show_message("[bicon(src)] *beep* *beep*", 3, "*beep* *beep*", 2)

	var/turf/bombturf = get_turf(src)
	var/bombarea = bombturf.loc.name

	logTheThing("bombing", null, null, "Chemical ([src]) Bomb triggered in [bombarea] with device attacher: [attacher]. Last touched by: [fingerprintslast]")
	message_admins("Chemical Bomb ([src]) triggered in [bombarea] with device attacher: [attacher]. Last touched by: [fingerprintslast]")

	//boutput(world, "sent explode() to [payload]")
	payload.explode()
	return
