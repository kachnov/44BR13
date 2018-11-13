//Firebot
//Firebot assembly

/obj/machinery/bot/firebot
	name = "Firebot"
	desc = "A little fire-fighting robot!  He looks so darn chipper."
	icon = 'icons/obj/aibots.dmi'
	icon_state = "firebot0"
	layer = 5.0 //TODO LAYER
	density = 0
	anchored = 0
	req_access = list(access_engineering_atmos)
	on = 1
	health = 20
	var/stunned = 0 //It can be stunned by tasers. Delicate circuits.
	locked = 1
	var/frustration = 0
	var/list/path = null
	var/obj/hotspot/target = null
	var/obj/hotspot/oldtarget = null
	var/oldloc = null
	var/last_found = 0
	var/last_spray = 0
	var/setup_party = 0
	//To-Do: Patrol the station for fires maybe??

/obj/machinery/bot/firebot/party
	name = "Partybot"
	desc = "Isn't that a firebot? What's his deal?"
	emagged = 1
	setup_party = 1

//
/obj/item/toolbox_arm
	name = "toolbox/robot arm assembly"
	icon = 'icons/obj/aibots.dmi'
	icon_state = "toolbox_arm"
	force = 3.0
	throwforce = 10.0
	throw_speed = 2
	throw_range = 5
	w_class = 3.0
	flags = TABLEPASS
	var/extinguisher = 0 //Is the extinguisher added?
	var/created_name = "Firebot"

/obj/machinery/bot/firebot/New()
	if (map_setting == "DESTINY" && icon == 'icons/obj/aibots.dmi')
		icon = 'icons/obj/toolbots.dmi'
	..()
	spawn (5)
		if (src)
			// Firebots are used in multiple department, so I guess they get all-access instead of only engineering.
			botcard = new /obj/item/card/id(src)
			botcard.access = get_access(access_lookup)
			icon_state = "firebot[on]"
	return

//		if (radio_connection)
//			radio_controller.add_object(src, "[beacon_freq]")

/obj/machinery/bot/firebot/examine()
	set src in view()
	set category = "Local"
	..()

	if (health < 20)
		if (health > 15)
			boutput(usr, text("<span style=\"color:red\">[src]'s parts look loose.</span>"))
		else
			boutput(usr, text("<span style=\"color:red\"><strong>[src]'s parts look very loose!</strong></span>"))
	return

/obj/machinery/bot/firebot/attack_ai(mob/user as mob)
	return toggle_power()

/obj/machinery/bot/firebot/attack_hand(mob/user as mob)
	var/dat
	dat += "<TT><strong>Automatic Fire-Fighting Unit v1.0</strong></TT><BR><BR>"
	dat += "Status: <A href='?src=\ref[src];power=1'>[on ? "On" : "Off"]</A><BR>"

//	dat += "<br>Behaviour controls are [locked ? "locked" : "unlocked"]<hr>"
//	if (!locked)
//To-Do: Behavior control stuff to go with ~fire patrols~

	user << browse("<HEAD><TITLE>Firebot v1.0 controls</TITLE></HEAD>[dat]", "window=automed")
	onclose(user, "autofire")
	return

/obj/machinery/bot/firebot/Topic(href, href_list)
	if (..())
		return
	usr.machine = src
	add_fingerprint(usr)
	if ((href_list["power"]) && (allowed(usr, req_only_one_required)))
		toggle_power()


	updateUsrDialog()
	return

/obj/machinery/bot/firebot/emag_act(var/mob/user, var/obj/item/card/emag/E)
	if (!emagged)
		if (user)
			boutput(user, "<span style=\"color:red\">You short out [src]'s valve control circuit!</span>")
		spawn (0)
			for (var/mob/O in hearers(src, null))
				O.show_message("<span style=\"color:red\"><strong>[src] buzzes oddly!</strong></span>", 1)
		flick("firebot_spark", src)
		target = null
		last_found = world.time
		anchored = 0
		emagged = 1
		on = 1
		icon_state = "firebot[on]"
		return TRUE
	return FALSE


/obj/machinery/bot/firebot/demag(var/mob/user)
	if (!emagged)
		return FALSE
	if (user)
		user.show_text("You repair [src]'s valve control circuit.", "blue")
	emagged = 0
	return TRUE

/obj/machinery/bot/firebot/emp_act()
	..()
	if (!emagged && prob(75))
		visible_message("<span style=\"color:red\"><strong>[src] buzzes oddly!</strong></span>")
		flick("firebot_spark", src)
		target = null
		last_found = world.time
		anchored = 0
		emagged = 1
		on = 1
		icon_state = "firebot[on]"
	else
		explode()
	return

/obj/machinery/bot/firebot/attackby(obj/item/W as obj, mob/user as mob)
	if (istype(W, /obj/item/card/emag))
		//Swedenfact:
		//"Fart" means "speed", so if a policeman pulls you over with the words "fartkontroll" you should not pull your pants down
		return
	if (istype(W, /obj/item/device/pda2) && W:ID_card)
		W = W:ID_card
	if (istype(W, /obj/item/card/id))
		if (allowed(user, req_only_one_required))
			locked = !locked
			boutput(user, "Controls are now [locked ? "locked." : "unlocked."]")
			updateUsrDialog()
		else
			boutput(user, "<span style=\"color:red\">Access denied.</span>")

	else if (istype(W, /obj/item/screwdriver))
		if (health < initial(health))
			health = initial(health)
			visible_message("<span style=\"color:blue\">[user] repairs [src]!</span>", "<span style=\"color:blue\">You repair [src].</span>")
	else
		switch(W.damtype)
			if ("fire")
				health -= W.force * 0.1 //More fire resistant than other bots
			if ("brute")
				health -= W.force * 0.5
			else
		if (health <= 0)
			explode()
		else if (W.force)
			step_to(src, (get_step_away(src,user)))
		..()

/obj/machinery/bot/firebot/process()
	if (!on)
		stunned = 0
		return

	if (stunned)
		icon_state = "firebota"
		stunned--

		oldtarget = target
		target = null

		if (stunned <= 0)
			icon_state = "firebot[on]"
			stunned = 0
		return

	if (frustration > 8)
		oldtarget = target
		target = null
		//currently_healing = 0
		last_found = world.time
		path = null
		frustration = 0

	if (!target)
		for (var/obj/hotspot/H in view(7,src))
			if ((H == oldtarget) && (world.time < last_found + 80))
				continue

			target = H
			oldtarget = H
			last_found = world.time
			frustration = 0
			if (prob(10))
				spawn (0)
					speak( setup_party ? pick("IT IS PARTY TIME.","I AM A FAN OF PARTIES", "PARTIES ARE THE FUTURE") : pick("I AM GOING TO MURDER THIS FIRE.","KILL ALL FIRES.","I DIDN'T START THIS, BUT I'M GOING TO END IT.","A fire is going to die tonight.") )
			break

		if (!target)
			for (var/mob/living/carbon/burningMob in view(7, src))
				if (burningMob == oldtarget && (world.time < last_found + 80))
					continue

				if (burningMob.stat == 2)
					continue

				if (burningMob.burning || (emagged && prob(25)))
					target = burningMob
					oldtarget = burningMob
					last_found = world.time
					frustration = 0
					visible_message("<strong>[src]</strong> points at [burningMob.name]!")
					if (setup_party)
						speak(pick("YOU NEED TO GET DOWN -- ON THE DANCE FLOOR", "PARTY HARDER", "HAPPY BIRTHDAY.", "YOU ARE NOT PARTYING SUFFICIENTLY.", "NOW CORRECTING PARTY DEFICIENCY."))
					else
						speak(pick("YOU ARE ON FIRE!", "STOP DROP AND ROLL","THE FIRE IS ATTEMPTING TO FEED FROM YOU! I WILL STOP IT","I WON'T LET YOU BURN AWAY!",5;"Taste the meat, not the heat."))
					break

	if (target && (get_dist(src,target) <= 2))
		if (world.time > last_spray + 30)
			frustration = 0
			spray_at(target)
		if (iscarbon(target)) //Check if this is a mob and we can stop spraying when they are no longer on fire.
			var/mob/living/carbon/C = target
			if (!C.burning || C.stat == 2)
				frustration = INFINITY
		return

	else if (target && path && path.len && (get_dist(target,path[path.len]) > 2))
		path = new()
//		currently_healing = 0
		last_found = world.time

	if (target && (!path || !path.len) && (get_dist(src,target) > 1))
		spawn (0)
			if (!isturf(loc))
				return
			path = AStar(get_turf(src), get_turf(target), /turf/proc/CardinalTurfsWithAccess, /turf/proc/Distance, adjacent_param = botcard)
			if (!path)
				frustration += 4
		return

	if (path && path.len && target)
		step_to(src, path[1])
		path -= path[1]
		spawn (3)
			if (path && path.len)
				step_to(src, path[1])
				path -= path[1]

	if (path && path.len > 8 && target)
		frustration++

	return

//Oh no we're emagged!! Nobody better try to cross us!
/obj/machinery/bot/firebot/HasProximity(atom/movable/AM as mob|obj)
	if (!on || !emagged || stunned)
		return

	if (iscarbon(AM) && prob(40))
		spray_at(AM)

	return

/obj/machinery/bot/firebot/proc/spray_at(atom/target)
	if (!target || !on || stunned)
		return

	last_spray = world.time
	var/direction = get_dir(src,target)

	var/turf/T = get_turf(target)
	T = get_step(T, direction)
	var/turf/T1 = get_step(T,turn(direction, 90))
	var/turf/T2 = get_step(T,turn(direction, -90))

	var/list/the_targets = list(T,T1,T2)

	flick("firebot-c", src)
	if (setup_party)
		playsound(loc, "sound/items/bikehorn.ogg", 75, 1, -3)

	else
		playsound(loc, "sound/effects/spray.ogg", 75, 1, -3)

	for (var/a=0, a<5, a++)
		spawn (0)
			var/obj/effects/water/W = unpool(/obj/effects/water)
			if (!W) return
			W.set_loc( get_turf(src) )
			var/turf/my_target = pick(the_targets)
			var/reagents/R = new/reagents(5)
			R.add_reagent("water", 2)
			R.add_reagent("fffoam", 3)
			W.spray_at(my_target, R)

	if (emagged && iscarbon(target))
		var/atom/targetTurf = get_edge_target_turf(target, get_dir(src, get_step_away(target, src)))

		spawn (0)
			var/mob/living/carbon/Ctarget = target
			boutput(Ctarget, "<span style=\"color:red\"><strong>[src] knocks you back!</strong></span>")
			Ctarget.weakened += 2
			Ctarget.throw_at(targetTurf, 200, 4)

	return

/obj/machinery/bot/firebot/ex_act(severity)
	switch(severity)
		if (1.0)
			explode()
			return
		if (2.0)
			health -= 15
			if (health <= 0)
				explode()
			return
	return

/obj/machinery/bot/firebot/meteorhit()
	explode()
	return

/obj/machinery/bot/firebot/blob_act(var/power)
	if (prob(25 * power / 20))
		explode()
	return

/obj/machinery/bot/firebot/gib()
	return explode()

/obj/machinery/bot/firebot/explode()
	on = 0
	for (var/mob/O in hearers(src, null))
		O.show_message("<span style=\"color:red\"><strong>[src] blows apart!</strong></span>", 1)
	var/turf/Tsec = get_turf(src)

	new /obj/item/device/prox_sensor(Tsec)

	new /obj/item/extinguisher(Tsec)

	if (prob(50))
		new /obj/item/parts/robot_parts/arm/left(Tsec)

	var/obj/item/storage/toolbox/emergency/emptybox = new /obj/item/storage/toolbox/emergency(Tsec)
	for (var/obj/item/I in emptybox.contents) //Empty the toolbox so we don't have infinite crowbars or whatever
		qdel(I)

	var/effects/system/spark_spread/s = unpool(/effects/system/spark_spread)
	s.set_up(3, 1, src)
	s.start()
	qdel(src)
	return

/obj/machinery/bot/firebot/proc/toggle_power()
	on = !on
	target = null
	oldtarget = null
	oldloc = null
	path = null
	last_found = 0
	last_spray = 0
	icon_state = "firebot[on]"
	updateUsrDialog()
	return

/obj/machinery/bot/firebot/Bumped(M as mob|obj)
	spawn (0)
		var/turf/T = get_turf(src)
		M:set_loc(T)


/*
 *	Firebot construction
 */

/obj/item/storage/toolbox/emergency/attackby(var/obj/item/parts/robot_parts/P, mob/user as mob)
	if (!istype(P, /obj/item/parts/robot_parts/arm))
		..()
		return

	if (contents.len >= 1)
		boutput(user, "<span style=\"color:red\">You need to empty [src] out first!</span>")
		return

	var/obj/item/toolbox_arm/B = new /obj/item/toolbox_arm
	B.set_loc(user)
	user.u_equip(P)
	user.put_in_hand_or_drop(B)
	boutput(user, "You add the arm to the empty toolbox.  It's a little awkward.")
	qdel(P)
	qdel(src)

/obj/item/toolbox_arm/attackby(obj/item/W as obj, mob/user as mob)
	if ((istype(W, /obj/item/extinguisher)) && (!extinguisher))
		extinguisher = 1
		boutput(user, "You add the fire extinguisher to [src]!")
		name = "Toolbox/robot arm/fire extinguisher assembly"
		icon_state = "toolbox_arm_ext"
		qdel(W)

	else if ((istype(W, /obj/item/device/prox_sensor)) && (extinguisher))
		boutput(user, "You complete the Firebot! Beep boop.")
		var/obj/machinery/bot/firebot/S = new /obj/machinery/bot/firebot
		S.set_loc(get_turf(src))
		S.name = created_name
		qdel(W)
		qdel(src)

	else if (istype(W, /obj/item/pen))
		var/t = input(user, "Enter new robot name", name, created_name) as text
		t = strip_html(replacetext(t, "'",""))
		t = copytext(t, 1, 45)
		if (!t)
			return
		if (!in_range(src, usr) && loc != usr)
			return

		created_name = t