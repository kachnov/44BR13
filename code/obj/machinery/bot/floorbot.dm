//Floorbot assemblies
/obj/item/toolbox_tiles
	desc = "It's a toolbox with tiles sticking out the top"
	name = "tiles and toolbox"
	icon = 'icons/obj/aibots.dmi'
	icon_state = "toolbox_tiles"
	force = 3.0
	throwforce = 10.0
	throw_speed = 2
	throw_range = 5
	w_class = 3.0
	flags = TABLEPASS

/obj/item/toolbox_tiles_sensor
	desc = "It's a toolbox with tiles sticking out the top and a sensor attached"
	name = "tiles, toolbox and sensor arrangement"
	icon = 'icons/obj/aibots.dmi'
	icon_state = "toolbox_tiles_sensor"
	force = 3.0
	throwforce = 10.0
	throw_speed = 2
	throw_range = 5
	w_class = 3.0
	flags = TABLEPASS

//Floorbot
/obj/machinery/bot/floorbot
	name = "Floorbot"
	desc = "A little floor repairing robot, he looks so excited!"
	icon = 'icons/obj/aibots.dmi'
	icon_state = "floorbot0"
	layer = 5.0 //TODO LAYER
	density = 0
	anchored = 0
	//weight = 1.0E7
	var/amount = 10
	on = 1
	var/repairing = 0
	var/improvefloors = 0
	var/eattiles = 0
	var/maketiles = 0
	locked = 1
	health = 25
	var/turf/target
	var/turf/oldtarget
	var/oldloc = null
	req_access = list(access_engineering)
	access_lookup = "Chief Engineer"
	var/list/path = null
	no_camera = 1

/obj/machinery/bot/floorbot/New()
	..()
	spawn (5)
		if (src)
			botcard = new /obj/item/card/id(src)
			botcard.access = get_access(access_lookup)
			updateicon()
	return

/obj/machinery/bot/floorbot/attack_hand(user as mob)
	var/dat
	dat += text({"
<TT><strong>Automatic Station Floor Repairer v1.0</strong></TT><BR><BR>
Status: []<BR>
Tiles left: [amount]<BR>
Behaviour controls are [locked ? "locked" : "unlocked"]"},
text("<A href='?src=\ref[src];operation=start'>[on ? "On" : "Off"]</A>"))
	if (!locked)
		dat += text({"<BR>
Improves floors: []<BR>
Finds tiles: []<BR>
Make single pieces of metal into tiles when empty: []"},
text("<A href='?src=\ref[src];operation=improve'>[improvefloors ? "Yes" : "No"]</A>"),
text("<A href='?src=\ref[src];operation=tiles'>[eattiles ? "Yes" : "No"]</A>"),
text("<A href='?src=\ref[src];operation=make'>[maketiles ? "Yes" : "No"]</A>"))

	user << browse("<HEAD><TITLE>Repairbot v1.0 controls</TITLE></HEAD>[dat]", "window=autorepair")
	onclose(user, "autorepair")
	return

/obj/machinery/bot/floorbot/emag_act(var/mob/user, var/obj/item/card/emag/E)
	if (!emagged)
		if (user)
			boutput(user, "<span style=\"color:red\">You short out [src]'s target assessment circuits.</span>")
		spawn (0)
			for (var/mob/O in hearers(src, null))
				O.show_message("<span style=\"color:red\"><strong>[src] buzzes oddly!</strong></span>", 1)
		target = null
		oldtarget = null
		anchored = 0
		emagged = 1
		on = 1
		icon_state = "floorbot[on]"
		return TRUE
	return FALSE


/obj/machinery/bot/floorbot/demag(var/mob/user)
	if (!emagged)
		return FALSE
	if (user)
		user.show_text("You repair [src]'s target assessment circuits.", "blue")
	emagged = 0
	return TRUE

/obj/machinery/bot/floorbot/emp_act()
	..()
	if (!emagged && prob(75))
		visible_message("<span style=\"color:red\"><strong>[src] buzzes oddly!</strong></span>")
		target = null
		oldtarget = null
		anchored = 0
		emagged = 1
		on = 1
		icon_state = "floorbot[on]"
	else
		explode()
	return

/obj/machinery/bot/floorbot/attackby(var/obj/item/W , mob/user as mob)
	if (istype(W, /obj/item/tile))
		var/obj/item/tile/T = W
		if (amount >= 50)
			return
		var/loaded = 0
		if (amount + T.amount > 50)
			var/i = 50 - amount
			amount += i
			T.amount -= i
			loaded = i
		else
			amount += T.amount
			loaded = T.amount
			qdel(T)
		boutput(user, "<span style=\"color:red\">You load [loaded] tiles into the floorbot. He now contains [amount] tiles!</span>")
		updateicon()
	//Regular ID
	if (istype(W, /obj/item/device/pda2) && W:ID_card)
		W = W:ID_card
	if (istype(W, /obj/item/card/id))
		if (allowed(usr, req_only_one_required))
			locked = !locked
			boutput(user, "You [locked ? "lock" : "unlock"] the [src] behaviour controls.")
		else
			boutput(user, "The [src] doesn't seem to accept your authority.")
		updateUsrDialog()



/obj/machinery/bot/floorbot/Topic(href, href_list)
	if (..())
		return
	usr.machine = src
	add_fingerprint(usr)
	switch(href_list["operation"])
		if ("start")
			on = !on
			target = null
			oldtarget = null
			oldloc = null
			updateicon()
			path = null
			updateUsrDialog()
		if ("improve")
			improvefloors = !improvefloors
			updateUsrDialog()
		if ("tiles")
			eattiles = !eattiles
			updateUsrDialog()
		if ("make")
			maketiles = !maketiles
			updateUsrDialog()

/obj/machinery/bot/floorbot/attack_ai()
	on = !on
	target = null
	oldtarget = null
	oldloc = null
	updateicon()
	path = null

/obj/machinery/bot/floorbot/process()
	//checks to see if robot is on
	if (!on)
		return
	//checks to see if already repairing
	if (repairing)
		return
	var/list/floorbottargets = list()
	//checks if already targeting something
	if (!target || target == null)
		for (var/obj/machinery/bot/floorbot/bot in machines)
			if (bot != src)
				floorbottargets += bot.target
	///Code for handling when out of tiles
	if (amount <= 0 && ((target == null) || !target))
		if (eattiles)
			for (var/obj/item/tile/T in view(7, src))
				if (T != oldtarget && !(target in floorbottargets))
					oldtarget = T
					target = T
					break
		if (target == null || !target)
			if (maketiles)
				if (target == null || !target)
					for (var/obj/item/sheet/M in view(7, src))
						if (!(M in floorbottargets) && M != oldtarget && M.amount == 1 && !(istype(M.loc, /turf/simulated/wall)))
							oldtarget = M
							target = M
							break
		else
			return
	if (prob(5))
		visible_message("[src] makes an excited booping beeping sound!")
	/////////Search for target code
	if ((!target || target == null) && (!emagged))
	    ///Search for space turf
		for (var/turf/space/D in view(7,src))
			if (!(D in floorbottargets) && D != oldtarget && (D.loc.name != "Space"))
				oldtarget = D
				target = D
				break
		///Search for incomplete floor
		if ((!target || target == null ) && improvefloors)
			for (var/turf/simulated/floor/F in view(7,src))
				if (!(F in floorbottargets) && F != oldtarget && F.icon_state == "Floor1" && !(istype(F, /turf/simulated/floor/plating)))
					oldtarget = F
					target = F
					break
		///search for tiles
		if ((!target || target == null) && eattiles)
			for (var/obj/item/tile/T in view(7, src))
				if (!(T in floorbottargets) && T != oldtarget)
					oldtarget = T
					target = T
					break
	else if ((!target || target == null) && (emagged))
		for (var/turf/simulated/floor/F in view(7,src))
			if (!(F in floorbottargets) && F != oldtarget)
				oldtarget = F
				target = F
				break

	if (!target || target == null)
		if (loc != oldloc)
			oldtarget = null
		return

	if (target && (!path || !path.len))
		spawn (0)
			if (!isturf(loc))
				return
			if (!target)
				return
			path = AStar(loc, get_turf(target), /turf/proc/CardinalTurfsSpace, /turf/proc/Distance, 120)
			if (!path || !path.len)
				oldtarget = target
				target = null
		return
	if (path && path.len && target)
		step_to(src, path[1])
		path -= path[1]

	if (loc == target || loc == target.loc)
		if (istype(target, /obj/item/tile))
			eattile(target)
		else if (istype(target, /obj/item/sheet))
			maketile(target)
		else if (istype(target, /turf))
			repair(target)
		path = null
		return

	oldloc = loc


/obj/machinery/bot/floorbot/proc/repair(var/turf/target)
	if (istype(target, /turf/space))
		if (target.loc.name == "Space")
			return
	else if (!istype(target, /turf/simulated/floor))
		return
	if (amount <= 0 && (!emagged))
		return
	anchored = 1
	icon_state = "floorbot-c"
	if (istype(target, /turf/space))
		visible_message("<span style=\"color:red\">[src] begins to repair the hole</span>")
		var/obj/item/tile/T = new /obj/item/tile
		repairing = 1
		spawn (50)
			T.build(loc)
			repairing = 0
			amount -= 1
			updateicon()
			anchored = 0
			target = null
	/////////////////////////////////////////////////
	///Emagged "repair"       ///////////////////////
	/////////////////////////////////////////////////
	if ((istype(target, /turf/simulated/floor)) && (emagged))
		visible_message("<span style=\"color:red\">[src] begins to remove the tile</span>")
		repairing = 1
		spawn (50)
			qdel(target)
			repairing = 0
			updateicon()
			anchored = 0
			target = null
	else
		visible_message("<span style=\"color:red\">[src] begins to improve the floor.</span>")
		repairing = 1
		spawn (50)
			loc.icon_state = "floor"
			repairing = 0
			amount -= 1
			updateicon()
			anchored = 0
			target = null

/obj/machinery/bot/floorbot/proc/eattile(var/obj/item/tile/T)
	if (!istype(T, /obj/item/tile))
		return
	visible_message("<span style=\"color:red\">[src] begins to collect tiles.</span>")
	repairing = 1
	spawn (20)
		if (isnull(T))
			target = null
			repairing = 0
			return
		if (amount + T.amount > 50)
			var/i = 50 - amount
			amount += i
			T.amount -= i
		else
			amount += T.amount
			qdel(T)
		updateicon()
		target = null
		repairing = 0

/obj/machinery/bot/floorbot/proc/maketile(var/obj/item/sheet/M)
	if (!istype(M, /obj/item/sheet))
		return
	if (M.amount > 1)
		return
	visible_message("<span style=\"color:red\">[src] begins to create tiles.</span>")
	repairing = 1
	spawn (20)
		if (isnull(M))
			target = null
			repairing = 0
			return
		var/obj/item/tile/T = new /obj/item/tile/steel
		T.amount = 4
		T.set_loc(M.loc)
		qdel(M)
		target = null
		repairing = 0

/obj/machinery/bot/floorbot/proc/updateicon()
	if (map_setting == "DESTINY" && icon == 'icons/obj/aibots.dmi')
		icon = 'icons/obj/toolbots.dmi'
	if (amount > 0)
		icon_state = "floorbot[on]"
	else
		icon_state = "floorbot[on]e"


/////////////////////////////////////////
//////Floorbot Construction/////////////
/////////////////////////////////////////
/obj/item/storage/toolbox/mechanical/attackby(var/obj/item/tile/T, mob/user as mob)
	if (!istype(T, /obj/item/tile))
		..()
		return
	if (contents.len >= 1)
		boutput(user, "They wont fit in as there is already stuff inside!")
		return
	var/obj/item/toolbox_tiles/B = new /obj/item/toolbox_tiles
	user.u_equip(T)
	user.put_in_hand_or_drop(B)
	boutput(user, "You add the tiles into the empty toolbox. They stick oddly out the top.")
	qdel(T)
	qdel(src)

/obj/item/toolbox_tiles/attackby(var/obj/item/device/prox_sensor/D, mob/user as mob)
	if (!istype(D, /obj/item/device/prox_sensor))
		return
	var/obj/item/toolbox_tiles_sensor/B = new /obj/item/toolbox_tiles_sensor
	B.set_loc(user)
	user.u_equip(D)
	user.put_in_hand_or_drop(B)
	boutput(user, "You add the sensor to the toolbox and tiles!")
	qdel(D)
	qdel(src)

/obj/item/toolbox_tiles_sensor/attackby(var/obj/item/parts/robot_parts/P, mob/user as mob)
	if (!istype(P, /obj/item/parts/robot_parts/arm))
		return
	var/obj/machinery/bot/floorbot/A = new /obj/machinery/bot/floorbot
	if (user.r_hand == src || user.l_hand == src)
		A.set_loc(user.loc)
	else
		A.set_loc(loc)
	boutput(user, "You add the robot arm to the odd looking toolbox assembly! Boop beep!")
	qdel(P)
	qdel(src)

/obj/machinery/bot/floorbot/explode()
	on = 0
	for (var/mob/O in hearers(src, null))
		O.show_message("<span style=\"color:red\"><strong>[src] blows apart!</strong></span>", 1)
	var/effects/system/spark_spread/s = unpool(/effects/system/spark_spread)
	s.set_up(3, 1, src)
	s.start()
	qdel(src)
	return
