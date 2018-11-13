/var/const/OPEN = 1
/var/const/CLOSED = 2

/obj/machinery/door/firedoor
	name = "Firelock"
	desc = "Thick, fire-proof doors that prevent the spread of fire, they can only be pried open unless the fire alarm is cleared."
	icon = 'icons/obj/doors/Doorfire.dmi'
	icon_state = "door0"
	var/blocked = null
	opacity = 0
	density = 0
	var/nextstate = null
	var/radio_frequency/control_frequency = "1437"
	var/zone
	var/image/welded_image = null
	var/welded_icon_state = "welded"

/obj/machinery/door/firedoor/border_only
	name = "Firelock"
	icon = 'icons/obj/doors/door_fire2.dmi'
	icon_state = "door0"

/obj/machinery/door/firedoor/pyro
	icon = 'icons/obj/doors/SL_doors.dmi'
	icon_state = "fdoor0"
	icon_base = "fdoor"
	welded_icon_state = "fdoor_welded"

/obj/machinery/door/firedoor/New()
	..()
	if (!zone)
		var/area/A = get_area(loc)
		zone = A.name
	spawn (5)
		if (radio_controller)
			radio_controller.add_object(src, "[control_frequency]")


/obj/machinery/door/firedoor/proc/set_open()
	if (!blocked)
		if (operating)
			nextstate = OPEN
		else
			open()
	return

/obj/machinery/door/firedoor/proc/set_closed()
	if (!blocked)
		if (operating)
			nextstate = CLOSED
		else
			close()
	return

// listen for fire alert from firealarm
/obj/machinery/door/firedoor/receive_signal(signal/signal)
	if (signal.data["zone"] == zone && signal.data["type"] == "Fire")
		if (signal.data["alert"] == "fire")
			set_closed()
		else
			set_open()
	return


/obj/machinery/door/firedoor/power_change()
	if ( powered(ENVIRON) )
		stat &= ~NOPOWER
	else
		stat |= NOPOWER

/obj/machinery/door/firedoor/bumpopen(mob/user as mob)
	return

/obj/machinery/door/firedoor/isblocked()
	if (blocked)
		return TRUE
	return FALSE

/obj/machinery/door/firedoor/attackby(obj/item/C as obj, mob/user as mob)
	add_fingerprint(user)
	if ((istype(C, /obj/item/weldingtool) && !( operating ) && density))
		var/obj/item/weldingtool/W = C
		if (W.welding)
			if (W.get_fuel() > 2)
				W.use_fuel(2)
			if (!( blocked ))
				blocked = 1
			else
				blocked = 0
			update_icon()

			return
	if (!( istype(C, /obj/item/crowbar) ))
		return

	if (!blocked && !operating)
		if (density)
			spawn ( 0 )
				operating = 1

				play_animation("opening")
				update_icon(1)
				sleep(15)
				density = 0

				RL_SetOpacity(0)
				operating = 0
				return
		else //close it up again
			spawn ( 0 )
				operating = 1

				play_animation("closing")
				update_icon(1)
				density = 1
				sleep(15)

				RL_SetOpacity(1)
				operating = 0
				return
	return


/obj/machinery/door/firedoor/attack_ai(mob/user as mob)
	if (!blocked && !operating)
		if (density)
			set_open()
		else
			set_closed()
	return

/obj/machinery/door/firedoor/proc/check_nextstate()
	switch (nextstate)
		if (OPEN)
			open()
		if (CLOSED)
			close()
	nextstate = null

/obj/machinery/door/firedoor/opened()
	..()
	check_nextstate()

/obj/machinery/door/firedoor/closed()
	..()
	check_nextstate()

/obj/machinery/door/firedoor/border_only
	CanPass(atom/movable/mover, turf/target, height=0, air_group=0)
		if (air_group)
			var/direction = get_dir(src,target)
			return (dir != direction)
		else if (density)
			if (!height)
				var/direction = get_dir(src,target)
				return (dir != direction)
			else
				return FALSE

		return TRUE

	update_nearby_tiles(need_rebuild)
		if (!air_master) return FALSE

		var/turf/simulated/source = loc
		var/turf/simulated/destination = get_step(source,dir)

		if (need_rebuild)
			if (istype(source)) //Rebuild/update nearby group geometry
				if (source.parent)
					air_master.queue_update_group(source.parent)
				else
					air_master.queue_update_tile(source)
			if (istype(destination))
				if (destination.parent)
					air_master.queue_update_group(destination.parent)
				else
					air_master.queue_update_tile(destination)

		else
			if (istype(source)) air_master.queue_update_tile(source)
			if (istype(destination)) air_master.queue_update_tile(destination)

		return TRUE

/obj/machinery/door/firedoor/update_icon(var/toggling = 0)
	if (toggling? !density : density)
		if (locked)
			icon_state = "[icon_base]_locked"
		else
			icon_state = "[icon_base]1"
		if (blocked)
			if (!welded_image)
				welded_image = image(icon, welded_icon_state)
			UpdateOverlays(welded_image, "weld")
		else
			UpdateOverlays(null, "weld")
	else
		UpdateOverlays(null, "weld")
		icon_state = "[icon_base]0"

	return