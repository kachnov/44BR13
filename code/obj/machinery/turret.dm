/obj/machinery/turret
	name = "turret"
	icon = 'icons/obj/turrets.dmi'
	icon_state = "grey_target_prism"
	var/raised = 0
	var/enabled = 1
	anchored = 1
	layer = OBJ_LAYER
	invisibility = 2
	density = 1
	var/lasers = 0
	var/health = 100
	var/obj/machinery/turretcover/cover = null
	var/popping = 0
	var/wasvalid = 0
	var/lastfired = 0
	var/shot_delay = 15 //1.5 seconds between shots (previously 3, way too much to be useful)
	var/shot_type = 0
	var/override_area_bullshit = 0
	var/projectile/lethal = new/projectile/laser/heavy
	var/projectile/stun = new/projectile/energy_bolt/robust
	var/list/mob/target_list = null

/obj/machinery/turretcover
	name = "pop-up turret cover"
	icon = 'icons/obj/turrets.dmi'
	icon_state = "turretCover"
	anchored = 1
	layer = OBJ_LAYER+0.5
	density = 0

/obj/machinery/turret/New()
	..()
	var/area/station/turret_protected/TP = get_area(src)
	if (istype(TP))
		TP.turret_list += src

/obj/machinery/turret/disposing()
	var/area/station/turret_protected/TP = get_area(src)
	if (istype(TP))
		TP.turret_list -= src
	..()

/obj/machinery/turret/proc/isPopping()
	return (popping!=0)

/obj/machinery/turret/power_change()
	if (stat & BROKEN)
		icon_state = "grey_target_prism"
	else
		if ( powered() )
			if (enabled)
				if (lasers)
					icon_state = "orange_target_prism"
				else
					icon_state = "target_prism"
			else
				icon_state = "grey_target_prism"
			stat &= ~NOPOWER
		else
			spawn (rand(0, 15))
				icon_state = "grey_target_prism"
				stat |= NOPOWER

/obj/machinery/turret/proc/setState(var/enabled, var/lethal)
	enabled = enabled
	lasers = lethal
	power_change()

/obj/machinery/turret/process()
	if (stat & BROKEN)
		return
	..()
	if (stat & NOPOWER)
		return
	if (override_area_bullshit)
		return
	if (lastfired && world.time - lastfired < shot_delay)
		return

	if (cover==null)
		cover = new /obj/machinery/turretcover(loc)
	use_power(50)
	var/area/area = get_area(loc)
	if (istype(area))
		if (!target_list)
			target_list = get_target_list()	//Calculate a new batch of targets
			if (istype(area, /area/station/turret_protected)) //It'd be faster to just throw our turret buds our target list.
				var/area/station/turret_protected/TP = area
				for (var/obj/machinery/turret/T in TP.turret_list) //Sharing is caring - give it to our turret friends so they don't have to work out a target list
					T.target_list = target_list


		if (target_list && target_list.len)
			if (!isPopping())
				if (isDown())
					popUp()
				else
					var/mob/target = pick(target_list)
					dir = get_dir(src, target)
					lastfired = world.time //Setting this here to prevent immediate firing when enabled
					if (enabled)
						if (istype(target, /mob/living))
							if (target.stat!=2)
								shootAt(target)
		else if (!isDown() && !isPopping())
			popDown()

		target_list = null //Get ready for a new batch of targets during the next cycle

/obj/machinery/turret/proc/get_target_list()
	var/area/A = get_area(src)
	.= list()
	for (var/mob/living/C in A)
		if (!iscarbon(C) && !iscritter(C))
			continue
		if (C.stat == 2)
			continue
		. += C

/obj/machinery/turret/proc/isDown()
	return (invisibility!=0)

/obj/machinery/turret/proc/popUp()
	if (!isDown()) return
	if ((!isPopping()) || popping==-1)
		invisibility = 0
		popping = 1
		if (cover!=null)
			flick("popup", cover)
			cover.icon_state = "openTurretCover"
		spawn (10)
			if (popping==1) popping = 0

/obj/machinery/turret/proc/popDown()
	if (isDown()) return
	if ((!isPopping()) || popping==1)
		popping = -1
		if (cover!=null)
			flick("popdown", cover)
			cover.icon_state = "turretCover"
		spawn (13)
			if (popping==-1)
				invisibility = 2
				popping = 0

/obj/machinery/turret/proc/shootAt(var/mob/target)
	var/turf/T = loc
	var/atom/U = (istype(target, /atom/movable) ? target.loc : target)
	if ((!( U ) || !( T )))
		return
	while (!( istype(U, /turf) ))
		U = U.loc
	if (!( istype(T, /turf) ))
		return

	if (shot_type == 1)
		return
	else

		if (lasers)
			use_power(200)
			shoot_projectile_ST(src, lethal, U)
		else
			use_power(100)
			shoot_projectile_ST(src, stun, U)


	return

/obj/machinery/turret/bullet_act(var/obj/projectile/P)
	var/damage = 0
	damage = round((P.power*P.proj_data.ks_ratio), 1.0)

	if (material) material.triggerOnAttacked(src, P.shooter, src, (ismob(P.shooter) ? P.shooter:equipped() : P.shooter))
	for (var/atom/A in src)
		if (A.material)
			A.material.triggerOnAttacked(A, P.shooter, src, (ismob(P.shooter) ? P.shooter:equipped() : P.shooter))

	if (P.proj_data.damage_type == D_KINETIC)
		health -= damage
	else if (P.proj_data.damage_type == D_PIERCING)
		health -= (damage*2)
	else if (P.proj_data.damage_type == D_ENERGY)
		health -= damage / 2

	if (health <= 0)
		die()
	return


/obj/machinery/turret/ex_act(severity)
	if (severity < 3)
		die()

/obj/machinery/turret/emp_act()
	..()
	enabled = 0
	lasers = 0
	power_change()
	return

/obj/machinery/turret/proc/die()
	health = 0
	density = 0
	stat |= BROKEN
	icon_state = "destroyed_target_prism"
	if (cover!=null)
		qdel(cover)
	sleep(3)
	flick("explosion", src)
	spawn (13)
		qdel(src)

/*
 *	Network turret, a turret controlled over the wire network instead of a turretid
 */

/obj/machinery/turret/network
	var/net_id = null
	var/obj/machinery/power/data_terminal/data_link = null

	New()
		..()
		spawn (6)
			net_id = generate_net_id(src)
			if (!data_link)
				var/turf/T = get_turf(src)
				var/obj/machinery/power/data_terminal/test_link = locate() in T
				if (test_link && !test_link.is_valid_master(test_link.master))
					data_link = test_link
					data_link.master = src

		return

	receive_signal(signal/signal)
		if (stat & NOPOWER)
			return

		if (!signal || signal.encryption || !signal.data["sender"])
			return

		if (signal.transmission_method != TRANSMISSION_WIRE)
			return

		var/sender = signal.data["sender"]
		if ((signal.data["address_1"] == "ping") && sender)
			spawn (5)
				post_status(sender, "command", "ping_reply", "device", "PNET_SEC_TURRT", "netid", net_id)
			return

		if (signal.data["address_1"] == net_id && signal.data["acc_code"] == netpass_security)
			var/command = lowertext(signal.data["command"])
			switch(command)
				if ("status")
					var/status_string = "on=[!(stat & NOPOWER)]&health=[health]&lethal=[lasers]&active=[enabled]"
					spawn (3)
						post_status(sender, "command", "device_reply", status_string)
				if ("setmode")
					var/list/L = params2list(signal.data["data"])
					if (!L || !L.len) return
					var/new_lethal_state = text2num(L["lethal"])
					var/new_enabled_state = text2num(L["active"])
					if (!isnull(new_lethal_state))
						if (new_lethal_state)
							lasers = 1
						else
							lasers = 0
					if (!isnull(new_enabled_state))
						if (new_enabled_state)
							enabled = 1
						else
							enabled = 0

			return
		return

	proc/post_status(var/target_id, var/key, var/value, var/key2, var/value2, var/key3, var/value3)
		if (!data_link || !target_id)
			return

		var/signal/signal = get_free_signal()
		signal.source = src
		signal.transmission_method = TRANSMISSION_WIRE
		signal.data[key] = value
		if (key2)
			signal.data[key2] = value2
		if (key3)
			signal.data[key3] = value3

		signal.data["address_1"] = target_id
		signal.data["sender"] = net_id

		data_link.post_signal(src, signal)

/obj/machinery/turretid
	name = "Turret deactivation control"
	icon = 'icons/obj/device.dmi'
	icon_state = "motion3"
	anchored = 1
	density = 0
	var/enabled = 1
	var/lethal = 0
	var/locked = 1
	var/emagged = 0
	var/turretsExist = 1

	req_access = list(access_ai_upload)

/obj/machinery/turretid/attackby(obj/item/W, mob/user)
	if (stat & BROKEN) return
	if (istype(user, /mob/living/silicon))
		return attack_hand(user)
	else // trying to unlock the interface
		if (allowed(usr, req_only_one_required))
			locked = !locked
			boutput(user, "You [ locked ? "lock" : "unlock"] the panel.")
			if (locked)
				if (user.machine==src)
					user.machine = null
					user << browse(null, "window=turretid")
			else
				if (user.machine==src)
					attack_hand(usr)
		else
			boutput(user, "<span style=\"color:red\">Access denied.</span>")

/obj/machinery/turretid/attack_ai(mob/user as mob)
	return attack_hand(user)

/obj/machinery/turretid/attack_hand(mob/user as mob)
	if (user.stunned || user.weakened || user.stat)
		return

	if ( (get_dist(src, user) > 1 ))
		if (!istype(user, /mob/living/silicon))
			boutput(user, text("Too far away."))
			user.machine = null
			user << browse(null, "window=turretid")
			return

	user.machine = src
	var/_loc = loc
	if (istype(_loc, /turf))
		_loc = _loc:loc
	if (!istype(_loc, /area))
		boutput(user, text("Turret badly positioned - loc.loc is [].", _loc))
		return
	var/area/area = _loc
	var/t = "<TT><strong>Turret Control Panel</strong> ([area.name])<HR>"

	if (!emagged && turretsExist)
		if (locked && (!istype(user, /mob/living/silicon)))
			t += "<em>(Swipe ID card to unlock control panel.)</em><BR>"
		else
			t += text("Turrets [] - <A href='?src=\ref[];toggleOn=1'>[]?</a><br><br>", enabled?"activated":"deactivated", src, enabled?"Disable":"Enable")
			t += text("Currently set for [] - <A href='?src=\ref[];toggleLethal=1'>Change to []?</a><br><br>", lethal?"lethal":"stun repeatedly", src,  lethal?"Stun repeatedly":"Lethal")
	else if (emagged)
		var/o = ""
		for (var/i=rand(4,50), i > 0, i--)
			o += "kill[prob(50)?" ":null]"


		for (var/i=1, i <= length(o), i++)
			var/mod = rand(-5, 5)
			t += text("<font size=[][]>[]</font>",mod>=0?"+":"-" ,mod , copytext(o, i, i+1))
		t = "<strong><font color=#FF0000>[t]</font></strong>"
		t += "<br><br>"


	else
		t += "!ALERT! Unable to connect to a turret!<br><br>"

	user << browse(t, "window=turretid")
	onclose(user, "turretid")

/obj/machinery/turretid/Topic(href, href_list)
	..()
	if (!isliving(usr) || usr.stunned || usr.weakened || usr.stat)
		return
	if (locked)
		if (!issilicon(usr))
			boutput(usr, "Control panel is locked!")
			return

	if (!issilicon(usr) && get_dist(usr, src) > 1)
		return

	if (href_list["toggleOn"])
		enabled = !enabled
		logTheThing("combat", usr, null, "turned [enabled ? "ON" : "OFF"] turrets from control \[[showCoords(x, y, z)]].")
		updateTurrets()
	else if (href_list["toggleLethal"])
		lethal = !lethal
		if (lethal)
			logTheThing("combat", usr, null, "set turrets to LETHAL from control \[[showCoords(x, y, z)]].")
			message_admins("[key_name(usr)] set turrets to LETHAL from control \[[showCoords(x, y, z)]].")
		else
			logTheThing("combat", usr, null, "set turrets to STUN from control \[[showCoords(x, y, z)]].")
			message_admins("[key_name(usr)] set turrets to STUN from control \[[showCoords(x, y, z)]].")
		updateTurrets()
	attack_hand(usr)

/obj/machinery/turretid/proc/updateTurrets()
	if (turretsExist) //Let's not waste a lot of time here.
		if (enabled)
			if (lethal)
				icon_state = "motion1"
			else
				icon_state = "motion3"
		else
			icon_state = "motion0"

		var/_loc = loc
		if (istype(_loc, /turf))
			_loc = _loc:loc
		if (!istype(_loc, /area))
			boutput(world, text("Turret badly positioned - loc.loc is [_loc]."))
			return
		var/area/area = _loc
		turretsExist = 0
		for (var/obj/machinery/turret/aTurret in get_area_all_atoms(area))
			aTurret.setState(enabled, lethal)
			turretsExist = 1

/obj/machinery/turretid/emag_act(var/mob/user)
	if (!emagged)
		if (user)
			user.show_text("You short out the control circuit on [src]!", "blue")
			logTheThing("combat", user, null, "emagged the turret control in [loc.name] \[[showCoords(x, y, z)]]")
			logTheThing("admin", user, null, "emagged the turret control in [loc.name] \[[showCoords(x, y, z)]]")
		emagged = 1
		enabled = 0
		updateTurrets()
		spawn (100 + (rand(0,20)*10))
			process_emag()

		return TRUE

	else
		if (user) user.show_text("This thing is already fried!", "red")
		return FALSE

/obj/machinery/turretid/demag(var/mob/user)
	if (!emagged)
		return FALSE
	if (user)
		user.show_text("You repair the control circuit on [src]!", "blue")
	emagged = 0
	updateTurrets()
	return TRUE

/obj/machinery/turretid/proc/process_emag()
	do
		enabled = prob(90)
		lethal = prob(60)
		updateTurrets()

		sleep(rand(1, 10) * 10)
	while (emagged && turretsExist)