// Contains:
// - Sliding door parent
// - Brig door
// - Opaque door
// - Generic door

////////////////////////////////////////////////////// Sliding door parent ////////////////////////////////////

/obj/machinery/door/window
	name = "interior door"
	icon = 'icons/obj/doors/windoor.dmi'
	icon_state = "left"
	var/base_state = "left"
	visible = 0
	flags = ON_BORDER
	opacity = 0
	brainloss_stumble = 1
	autoclose = 1

	New()
		..()

		if (req_access && req_access.len)
			icon_state = "[icon_state]"
			base_state = icon_state
		return

	attack_hand(mob/user as mob)
		if (issilicon(user) && hardened == 1)
			user.show_text("You cannot control this door.", "red")
			return
		else
			return attackby(null, user)

	attackby(obj/item/I as obj, mob/user as mob)
		if (user.stunned || user.weakened || user.stat || user.restrained())
			return
		if (isblocked() == 1)
			return
		if (operating)
			return

		add_fingerprint(user)

		if (density && brainloss_stumble && do_brainstumble(user) == 1)
			return

		if (!requiresID())
			if (density)
				open()
			else
				close()
			return

		if (allowed(user, req_only_one_required))
			if (density)
				open()
			else
				close()
		else
			if (density)
				flick(text("[]deny", base_state), src)

		return

	emp_act()
		..()
		if (prob(20) && (density && cant_emag != 1 && isblocked() != 1))
			open(1)
		if (prob(40))
			if (secondsElectrified == 0)
				secondsElectrified = -1
				spawn (300)
					if (src)
						secondsElectrified = 0
		return

	emag_act(var/mob/user, var/obj/item/card/emag/E)
		if (density && cant_emag != 1 && isblocked() != 1)
			flick(text("[]spark", base_state), src)
			spawn (6)
				if (src)
					open(1)
			return TRUE
		return FALSE


	demag(var/mob/user)
		if (operating != -1)
			return FALSE
		operating = 0
		sleep(6)
		close()
		return TRUE

	CanPass(atom/movable/mover, turf/target, height=0, air_group=0)
		if (istype(mover, /obj/projectile))
			var/obj/projectile/P = mover
			if (P.proj_data.window_pass)
				return TRUE

		if (get_dir(loc, target) == dir) // Check for appropriate border.
			return !density
		else
			return TRUE

	CheckExit(atom/movable/mover as mob|obj, turf/target as turf)
		if (istype(mover, /obj/projectile))
			var/obj/projectile/P = mover
			if (P.proj_data.window_pass)
				return TRUE

		if (get_dir(loc, target) == dir)
			return !density
		else
			return TRUE

	update_nearby_tiles(need_rebuild)
		if (!air_master) return FALSE

		var/turf/simulated/source = loc
		var/turf/simulated/target = get_step(source,dir)

		if (need_rebuild)
			if (istype(source)) // Rebuild resp. update nearby group geometry.
				if (source.parent)
					air_master.queue_update_group(source.parent)
				else
					air_master.queue_update_tile(source)

			if (istype(target))
				if (target.parent)
					air_master.queue_update_group(target.parent)
				else
					air_master.queue_update_tile(target)
		else
			if (istype(source)) air_master.queue_update_tile(source)
			if (istype(target)) air_master.queue_update_tile(target)

		return TRUE

	open(var/emag_open = 0)
		if (!ticker)
			return FALSE
		if (operating)
			return FALSE
		operating = 1

		flick(text("[]opening", base_state), src)
		playsound(loc, "sound/machines/windowdoor.ogg", 100, 1)
		icon_state = text("[]open", base_state)

		spawn (10)
			if (src)
				density = 0
				RL_SetOpacity(0)
				update_nearby_tiles()
				if (emag_open == 1)
					operating = -1
				else
					operating = 0

		spawn (50)
			if (src && !operating && !density && autoclose == 1)
				close()

		return TRUE

	close()
		if (!ticker)
			return FALSE
		if (operating)
			return FALSE
		operating = 1

		flick(text("[]closing", base_state), src)
		playsound(loc, "sound/machines/windowdoor.ogg", 100, 1)
		icon_state = text("[]", base_state)

		density = 1
		if (visible)
			RL_SetOpacity(1)
		update_nearby_tiles()

		spawn (10)
			if (src)
				operating = 0

		return TRUE

	// Since these things don't have a maintenance panel or any other place to put this, really (Convair880).
	verb/toggle_autoclose()
		set src in oview(1)
		set category = "Local"

		if (isobserver(usr) || isintangible(usr))
			return
		if (usr.stunned > 0 || usr.weakened > 0 || usr.paralysis > 0 || usr.stat || usr.restrained())
			return
		if (!in_range(src, usr))
			usr.show_text("You are too far away.", "red")
			return
		if (hardened == 1)
			usr.show_text("You cannot control this door.", "red")
			return
		if (!allowed(usr, req_only_one_required))
			usr.show_text("Access denied.", "red")
			return
		if (operating == -1) // Emagged.
			usr.show_text("[src] is unresponsive.", "red")
			return

		if (autoclose)
			autoclose = 0
		else
			autoclose = 1
			spawn (50)
				if (src && !density)
					close()

		usr.show_text("Setting confirmed. [src] will [autoclose == 0 ? "no longer" : "now"] close automatically.", "blue")
		return

////////////////////////////////////////////// Brig door //////////////////////////////////////////////

/obj/machinery/door/window/brigdoor
	name = "Brig Door"
	icon = 'icons/obj/doors/windoor.dmi'
	icon_state = "leftsecure"
	base_state = "leftsecure"
	var/id = 1.0
	req_access = list(access_brig)
	autoclose = 0 //brig doors close only when the cell timer starts

	// Please keep synchronizied with these lists for easy map changes:
	// /obj/storage/secure/closet/brig/automatic (secure_closets.dm)
	// /obj/machinery/floorflusher (floorflusher.dm)
	// /obj/machinery/door_timer (door_timer.dm)
	// /obj/machinery/flasher (flasher.dm)
	solitary
		name = "Cell"
		id = "solitary"

		northleft
			dir = NORTH

		eastleft
			dir = EAST

		westleft
			dir = WEST

		southleft
			dir = SOUTH

		northright
			dir = NORTH
			icon_state = "rightsecure"
			base_state = "rightsecure"

		eastright
			dir = EAST
			icon_state = "rightsecure"
			base_state = "rightsecure"

		westright
			dir = WEST
			icon_state = "rightsecure"
			base_state = "rightsecure"

		southright
			dir = SOUTH
			icon_state = "rightsecure"
			base_state = "rightsecure"

	solitary2
		name = "Cell #2"
		id = "solitary2"

		northleft
			dir = NORTH

		eastleft
			dir = EAST

		westleft
			dir = WEST

		southleft
			dir = SOUTH

		northright
			dir = NORTH
			icon_state = "rightsecure"
			base_state = "rightsecure"

		eastright
			dir = EAST
			icon_state = "rightsecure"
			base_state = "rightsecure"

		westright
			dir = WEST
			icon_state = "rightsecure"
			base_state = "rightsecure"

		southright
			dir = SOUTH
			icon_state = "rightsecure"
			base_state = "rightsecure"

	solitary3
		name = "Cell #3"
		id = "solitary3"

		northleft
			dir = NORTH

		eastleft
			dir = EAST

		westleft
			dir = WEST

		southleft
			dir = SOUTH

		northright
			dir = NORTH
			icon_state = "rightsecure"
			base_state = "rightsecure"

		eastright
			dir = EAST
			icon_state = "rightsecure"
			base_state = "rightsecure"

		westright
			dir = WEST
			icon_state = "rightsecure"
			base_state = "rightsecure"

		southright
			dir = SOUTH
			icon_state = "rightsecure"
			base_state = "rightsecure"

	solitary4
		name = "Cell #4"
		id = "solitary4"

		northleft
			dir = NORTH

		eastleft
			dir = EAST

		westleft
			dir = WEST

		southleft
			dir = SOUTH

		northright
			dir = NORTH
			icon_state = "rightsecure"
			base_state = "rightsecure"

		eastright
			dir = EAST
			icon_state = "rightsecure"
			base_state = "rightsecure"

		westright
			dir = WEST
			icon_state = "rightsecure"
			base_state = "rightsecure"

		southright
			dir = SOUTH
			icon_state = "rightsecure"
			base_state = "rightsecure"

	minibrig
		name = "Mini-Brig"
		id = "minibrig"

		northleft
			dir = NORTH

		eastleft
			dir = EAST

		westleft
			dir = WEST

		southleft
			dir = SOUTH

		northright
			dir = NORTH
			icon_state = "rightsecure"
			base_state = "rightsecure"

		eastright
			dir = EAST
			icon_state = "rightsecure"
			base_state = "rightsecure"

		westright
			dir = WEST
			icon_state = "rightsecure"
			base_state = "rightsecure"

		southright
			dir = SOUTH
			icon_state = "rightsecure"
			base_state = "rightsecure"

	minibrig2
		name = "Mini-Brig #2"
		id = "minibrig2"

		northleft
			dir = NORTH

		eastleft
			dir = EAST

		westleft
			dir = WEST

		southleft
			dir = SOUTH

		northright
			dir = NORTH
			icon_state = "rightsecure"
			base_state = "rightsecure"

		eastright
			dir = EAST
			icon_state = "rightsecure"
			base_state = "rightsecure"

		westright
			dir = WEST
			icon_state = "rightsecure"
			base_state = "rightsecure"

		southright
			dir = SOUTH
			icon_state = "rightsecure"
			base_state = "rightsecure"

	minibrig3
		name = "Mini-Brig #3"
		id = "minibrig3"

		northleft
			dir = NORTH

		eastleft
			dir = EAST

		westleft
			dir = WEST

		southleft
			dir = SOUTH

		northright
			dir = NORTH
			icon_state = "rightsecure"
			base_state = "rightsecure"

		eastright
			dir = EAST
			icon_state = "rightsecure"
			base_state = "rightsecure"

		westright
			dir = WEST
			icon_state = "rightsecure"
			base_state = "rightsecure"

		southright
			dir = SOUTH
			icon_state = "rightsecure"
			base_state = "rightsecure"

	genpop
		name = "General Population"
		id = "genpop"

		northleft
			dir = NORTH

		eastleft
			dir = EAST

		westleft
			dir = WEST

		southleft
			dir = SOUTH

		northright
			dir = NORTH
			icon_state = "rightsecure"
			base_state = "rightsecure"

		eastright
			dir = EAST
			icon_state = "rightsecure"
			base_state = "rightsecure"

		westright
			dir = WEST
			icon_state = "rightsecure"
			base_state = "rightsecure"

		southright
			dir = SOUTH
			icon_state = "rightsecure"
			base_state = "rightsecure"

	genpop_n
		name = "General Population North"
		id = "genpop_n"

		northleft
			dir = NORTH

		eastleft
			dir = EAST

		westleft
			dir = WEST

		southleft
			dir = SOUTH

		northright
			dir = NORTH
			icon_state = "rightsecure"
			base_state = "rightsecure"

		eastright
			dir = EAST
			icon_state = "rightsecure"
			base_state = "rightsecure"

		westright
			dir = WEST
			icon_state = "rightsecure"
			base_state = "rightsecure"

		southright
			dir = SOUTH
			icon_state = "rightsecure"
			base_state = "rightsecure"

	genpop_s
		name = "General Population South"
		id = "genpop_s"

		northleft
			dir = NORTH

		eastleft
			dir = EAST

		westleft
			dir = WEST

		southleft
			dir = SOUTH

		northright
			dir = NORTH
			icon_state = "rightsecure"
			base_state = "rightsecure"

		eastright
			dir = EAST
			icon_state = "rightsecure"
			base_state = "rightsecure"

		westright
			dir = WEST
			icon_state = "rightsecure"
			base_state = "rightsecure"

		southright
			dir = SOUTH
			icon_state = "rightsecure"
			base_state = "rightsecure"

/////////////////////////////////////////////////////////// Opaque door //////////////////////////////////////

/obj/machinery/door/window/opaque
	icon_state = "opaque-left"
	base_state = "opaque-left"
	visible = 1
	opacity = 1
/obj/machinery/door/window/opaque/northleft
	dir = NORTH
/obj/machinery/door/window/opaque/eastleft
	dir = EAST
/obj/machinery/door/window/opaque/westleft
	dir = WEST
/obj/machinery/door/window/opaque/southleft
	dir = SOUTH
/obj/machinery/door/window/opaque/northright
	dir = NORTH
	icon_state = "opaque-right"
	base_state = "opaque-right"
/obj/machinery/door/window/opaque/eastright
	dir = EAST
	icon_state = "opaque-right"
	base_state = "opaque-right"
/obj/machinery/door/window/opaque/westright
	dir = WEST
	icon_state = "opaque-right"
	base_state = "opaque-right"
/obj/machinery/door/window/opaque/southright
	dir = SOUTH
	icon_state = "opaque-right"
	base_state = "opaque-right"

//////////////////////////////////////////////////////// Generic door //////////////////////////////////////////////

/obj/machinery/door/window/northleft
	dir = NORTH

/obj/machinery/door/window/eastleft
	dir = EAST

/obj/machinery/door/window/westleft
	dir = WEST

/obj/machinery/door/window/southleft
	dir = SOUTH

/obj/machinery/door/window/northright
	dir = NORTH
	icon_state = "right"
	base_state = "right"

/obj/machinery/door/window/eastright
	dir = EAST
	icon_state = "right"
	base_state = "right"

/obj/machinery/door/window/westright
	dir = WEST
	icon_state = "right"
	base_state = "right"

/obj/machinery/door/window/southright
	dir = SOUTH
	icon_state = "right"
	base_state = "right"