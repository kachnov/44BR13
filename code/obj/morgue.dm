/obj/morgue
	name = "morgue"
	icon = 'icons/obj/stationobjs.dmi'
	icon_state = "morgue1"
	density = 1
	var/obj/m_tray/connected = null
	anchored = 1.0
	dir = EAST

/obj/morgue/proc/update()
	if (connected)
		icon_state = "morgue0"
	else
		if (contents.len)
			icon_state = "morgue2"
		else
			icon_state = "morgue1"
	return

/obj/morgue/ex_act(severity)
	switch(severity)
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
			if (prob(5))
				for (var/atom/movable/A as mob|obj in src)
					A.set_loc(loc)
					A.ex_act(severity)
				qdel(src)
				return
	return

/obj/morgue/alter_health()
	return loc

/obj/morgue/attack_hand(mob/user as mob)
	if (connected)
		for ( var/atom/movable/A as mob|obj in connected.loc)
			if (!( A.anchored ))
				A.set_loc(src)
		playsound(loc, "sound/items/Deconstruct.ogg", 50, 1)
		qdel(connected)
		connected = null
	else
		playsound(loc, "sound/items/Deconstruct.ogg", 50, 1)
		connected = new /obj/m_tray( loc )
		step(connected, dir)//EAST)
		connected.layer = OBJ_LAYER
		var/turf/T = get_step(src, dir)//EAST)
		if (T.contents.Find(connected))
			src.connected.connected = src
			for (var/atom/movable/A as mob|obj in src)
				A.set_loc(connected.loc)
			connected.icon_state = "morguet"
		else
			qdel(connected)
			connected = null
	add_fingerprint(user)
	update()
	return

/obj/morgue/attackby(P as obj, mob/user as mob)
	add_fingerprint(user)
	if (istype(P, /obj/item/pen))
		var/t = input(user, "What would you like the label to be?", name, null) as null|text
		if (!t)
			return
		if (user.equipped() != P)
			return
		if ((!in_range(src, usr) && loc != user))
			return
		t = copytext(adminscrub(t),1,128)
		if (t)
			name = "Morgue- '[t]'"
		else
			name = "Morgue"
	else
		return ..()

/obj/morgue/relaymove(mob/user as mob)
	if (user.stat)
		return
	connected = new /obj/m_tray( loc )
	step(connected, dir)//EAST)
	connected.layer = OBJ_LAYER
	var/turf/T = get_step(src, dir)//EAST)
	if (T.contents.Find(connected))
		src.connected.connected = src
		for (var/atom/movable/A as mob|obj in src)
			A.set_loc(connected.loc)
			//Foreach goto(106)
		connected.icon_state = "morguet"
	else
		qdel(connected)
		connected = null
	update()
	return

/obj/m_tray
	name = "morgue tray"
	icon = 'icons/obj/stationobjs.dmi'
	icon_state = "morguet"
	density = 1
	layer = FLOOR_EQUIP_LAYER1
	var/obj/morgue/connected = null
	anchored = 1.0

/obj/m_tray/CanPass(atom/movable/mover, turf/target, height=0, air_group=0)
	if (istype(mover, /obj/item/dummy))
		return TRUE
	else
		return ..()

/obj/m_tray/attack_hand(mob/user as mob)
	if (connected)
		for (var/atom/movable/A as mob|obj in loc)
			if (!( A.anchored ))
				A.set_loc(connected)
			//Foreach goto(26)
		playsound(loc, "sound/items/Deconstruct.ogg", 50, 1)
		src.connected.connected = null
		connected.update()
		add_fingerprint(user)
		//SN src = null
		qdel(src)
		return
	return

/obj/m_tray/MouseDrop_T(atom/movable/O as mob|obj, mob/user as mob)
	if ((!( istype(O, /atom/movable) ) || O.anchored || get_dist(user, src) > 1 || get_dist(user, O) > 1 || user.contents.Find(src)))
		return
	O.set_loc(loc)
	if (user != O)
		visible_message("<span style=\"color:red\">[user] stuffs [O] into [src]!</span>")
			//Foreach goto(99)
	return


/obj/crematorium
	name = "crematorium"
	desc = "A human incinerator."
	icon = 'icons/obj/stationobjs.dmi'
	icon_state = "crema1"
	density = 1
	var/obj/c_tray/connected = null
	anchored = 1.0
	var/cremating = 0
	var/id = 1
	var/locked = 0

/obj/crematorium/proc/update()
	if (connected)
		icon_state = "crema0"
	else
		if (contents.len)
			icon_state = "crema2"
		else
			icon_state = "crema1"
	return

/obj/crematorium/ex_act(severity)
	switch(severity)
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
			if (prob(5))
				for (var/atom/movable/A as mob|obj in src)
					A.set_loc(loc)
					A.ex_act(severity)
				qdel(src)
				return
	return

/obj/crematorium/alter_health()
	return loc

/obj/crematorium/attack_hand(mob/user as mob)
//	if (cremating) AWW MAN! THIS WOULD BE SO MUCH MORE FUN ... TO WATCH
//		user.show_message("<span style=\"color:red\">Uh-oh, that was a bad idea.</span>", 1)
//		//boutput(usr, "Uh-oh, that was a bad idea.")
//		src:loc:poison += 20000000
//		src:loc:firelevel = src:loc:poison
//		return
	if (cremating)
		boutput(usr, "<span style=\"color:red\">It's locked.</span>")
		return
	if ((connected) && (locked == 0))
		for (var/atom/movable/A as mob|obj in connected.loc)
			if (!( A.anchored ))
				A.set_loc(src)
		playsound(loc, "sound/items/Deconstruct.ogg", 50, 1)
		qdel(connected)
		connected = null
	else if (locked == 0)
		playsound(loc, "sound/items/Deconstruct.ogg", 50, 1)
		connected = new /obj/c_tray( loc )
		step(connected, SOUTH)
		connected.layer = OBJ_LAYER
		var/turf/T = get_step(src, SOUTH)
		if (T.contents.Find(connected))
			src.connected.connected = src
			update()
			for (var/atom/movable/A as mob|obj in src)
				A.set_loc(connected.loc)
			connected.icon_state = "cremat"
		else
			qdel(connected)
			connected = null
	add_fingerprint(user)
	update()

/obj/crematorium/attackby(P as obj, mob/user as mob)
	if (istype(P, /obj/item/pen))
		var/t = input(user, "What would you like the label to be?", name, null) as null|text
		if (!t)
			return
		if (user.equipped() != P)
			return
		if ((!in_range(src, usr) > 1 && loc != user))
			return
		t = copytext(adminscrub(t),1,128)
		if (t)
			name = "Crematorium- '[t]'"
		else
			name = "Crematorium"
	add_fingerprint(user)
	return

/obj/crematorium/relaymove(mob/user as mob)
	if (user.stat || locked)
		return
	connected = new /obj/c_tray( loc )
	step(connected, SOUTH)
	connected.layer = OBJ_LAYER
	var/turf/T = get_step(src, SOUTH)
	if (T.contents.Find(connected))
		src.connected.connected = src
		icon_state = "crema0"
		for (var/atom/movable/A as mob|obj in src)
			A.set_loc(connected.loc)
			//Foreach goto(106)
		connected.icon_state = "cremat"
	else
		qdel(connected)
		connected = null
	update()
	return

/obj/crematorium/proc/cremate(mob/user as mob)
	if (!src || !istype(src))
		return
	if (cremating)
		return //don't let you cremate something twice or w/e
	if (!contents || !contents.len)
		visible_message("<span style=\"color:red\">You hear a hollow crackle, but nothing else happens.</span>")
		return

	visible_message("<span style=\"color:red\">You hear a roar as the crematorium activates.</span>")
	cremating = 1
	locked = 1
	var/ashes = 0

	for (var/M in contents)
		if (isliving(M))
			var/mob/living/L = M
			spawn (0)
				L.stunned = 100 //You really dont want to place this inside the loop.

				var/i
				for (i = 0, i < 10, i++)
					sleep(10)
					L.TakeDamage("chest", 0, 30)
					if (L.stat != 2 && prob(25))
						L.emote("scream")

				for (var/obj/item/W in L)
					if (prob(10))
						W.set_loc(L.loc)

				logTheThing("combat", user, L, "cremates %target% in a crematorium at [log_loc(src)].")
				if (L.mind)
					L.ghostize()
				ashes += 1
				qdel(L)

		else if (!ismob(M))
			if (prob(max(0, 100 - (ashes * 10))))
				ashes += 1
			qdel(M)

	spawn (100)
		if (src)
			visible_message("<span style=\"color:red\">The crematorium finishes and shuts down.</span>")
			cremating = 0
			locked = 0
			playsound(loc, "sound/machines/ding.ogg", 50, 1)

			while (ashes > 0)
				new /obj/decal/cleanable/ash(src)
				ashes -= 1

	return

/obj/c_tray
	name = "crematorium tray"
	icon = 'icons/obj/stationobjs.dmi'
	icon_state = "cremat"
	density = 1
	layer = FLOOR_EQUIP_LAYER1
	var/obj/crematorium/connected = null
	anchored = 1.0

/obj/c_tray/CanPass(atom/movable/mover, turf/target, height=0, air_group=0)
	if (istype(mover, /obj/item/dummy))
		return TRUE
	else
		return ..()

/obj/c_tray/attack_hand(mob/user as mob)
	if (connected)
		for (var/atom/movable/A as mob|obj in loc)
			if (!( A.anchored ))
				A.set_loc(connected)
			//Foreach goto(26)
		playsound(loc, "sound/items/Deconstruct.ogg", 50, 1)
		src.connected.connected = null
		connected.update()
		add_fingerprint(user)
		//SN src = null
		qdel(src)
		return
	return

/obj/c_tray/MouseDrop_T(atom/movable/O as mob|obj, mob/user as mob)
	if ((!( istype(O, /atom/movable) ) || O.anchored || get_dist(user, src) > 1 || get_dist(user, O) > 1 || user.contents.Find(src)))
		return
	O.set_loc(loc)
	if (user != O)
		user.visible_message("<span style=\"color:red\">[user] stuffs [O] into [src]!</span>", "<span style=\"color:red\">You stuff [O] into [src]!</span>")
			//Foreach goto(99)
	return

/obj/machinery/crema_switch/New()
	..()
	UnsubscribeProcess()

/obj/machinery/crema_switch/attack_hand(mob/user as mob)
	if (allowed(user, req_only_one_required))
		for (var/obj/crematorium/C in world)
			if (C.id == id)
				if (!C.cremating)
					C.cremate(user)
	else
		boutput(user, "<span style=\"color:red\">Access denied.</span>")
	return

