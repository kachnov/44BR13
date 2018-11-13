//
// Firealarm
//

/obj/machinery/firealarm
	name = "Fire Alarm"
	icon = 'icons/obj/monitors.dmi'
	icon_state = "fire0"
	var/alarm_frequency = "1437"
	var/detecting = 1.0
	var/working = 1.0
	var/time = 10.0
	var/timing = 0.0
	var/lockdownbyai = 0
	anchored = 1.0
	var/alarm_zone
	var/net_id
	var/ringlimiter = 0
	var/radio_frequency/frequency
	desc = "A fire sensor and alarm system. When it detects fire or is manually activated, it closes all firelocks in the area to minimize the spread of fire."

/obj/machinery/firealarm/New()
	..()
	if (!alarm_zone)
		var/area/A = get_area(loc)
		alarm_zone = A.name

	if (!net_id)
		net_id = generate_net_id(src)

	mechanics = new(src)
	mechanics.master = src
	mechanics.addInput("toggle", "toggleinput")
	spawn (10)
		frequency = radio_controller.return_frequency(alarm_frequency)

/obj/machinery/firealarm/proc/toggleinput(var/mechanicsMessage/inp)
	if (icon_state == "fire0")
		alarm()
	else
		reset()
	return

/obj/machinery/firealarm/temperature_expose(gas_mixture/air, temperature, volume)
	if (detecting)
		if (temperature > T0C+200)
			alarm()			// added check of detector status here
	return

/obj/machinery/firealarm/attack_ai(mob/user as mob)
	return attack_hand(user)

/obj/machinery/firealarm/bullet_act(BLAH)
	return alarm()

/obj/machinery/firealarm/emp_act()
	..()
	if (prob(50))
		alarm()
	return

/obj/machinery/firealarm/attackby(obj/item/W as obj, mob/user as mob)
	if (istype(W, /obj/item/wirecutters))
		detecting = !( detecting )
		if (detecting)
			user.visible_message("<span style=\"color:red\">[user] has reconnected [src]'s detecting unit!</span>", "You have reconnected [src]'s detecting unit.")
		else
			user.visible_message("<span style=\"color:red\">[user] has disconnected [src]'s detecting unit!</span>", "You have disconnected [src]'s detecting unit.")
	else
		alarm()
	add_fingerprint(user)
	return

/obj/machinery/firealarm/process()
	if (stat & (NOPOWER|BROKEN))
		return

	use_power(10, ENVIRON)

	if (timing)
		if (time > 0)
			time = round(time) - 1
		else
			alarm()
			time = 0
			timing = 0
		updateDialog()
	return

/obj/machinery/firealarm/power_change()
	if (powered(ENVIRON))
		stat &= ~NOPOWER
		icon_state = "fire0"
	else
		spawn (rand(0,15))
			stat |= NOPOWER
			icon_state = "firep"

/obj/machinery/firealarm/attack_hand(mob/user as mob)
	if (user.stat || stat & (NOPOWER|BROKEN))
		return

	user.machine = src
	var/area/A = loc
	var/d1
	var/d2
	A = A.loc

	if (A.fire)
		d1 = text("<A href='?src=\ref[];reset=1'>Reset - Lockdown</A>", src)
	else
		d1 = text("<A href='?src=\ref[];alarm=1'>Alarm - Lockdown</A>", src)
	if (timing)
		d2 = text("<A href='?src=\ref[];time=0'>Stop Time Lock</A>", src)
	else
		d2 = text("<A href='?src=\ref[];time=1'>Initiate Time Lock</A>", src)
	var/second = time % 60
	var/minute = (time - second) / 60
	var/dat = text("<HTML><HEAD></HEAD><BODY><TT><strong>Fire alarm</strong> []<br><HR><br>Timer System: []<BR><br>Time Left: [][] <A href='?src=\ref[];tp=-30'>-</A> <A href='?src=\ref[];tp=-1'>-</A> <A href='?src=\ref[];tp=1'>+</A> <A href='?src=\ref[];tp=30'>+</A><br></TT></BODY></HTML>", d1, d2, (minute ? text("[]:", minute) : null), second, src, src, src, src)
	user << browse(dat, "window=firealarm")
	onclose(user, "firealarm")
	return

/obj/machinery/firealarm/Topic(href, href_list)
	..()
	if (usr.stat || stat & (BROKEN|NOPOWER))
		return
	if ((usr.contents.Find(src) || ((get_dist(src, usr) <= 1) && istype(loc, /turf))) || (istype(usr, /mob/living/silicon/ai)))
		usr.machine = src
		if (href_list["reset"])
			reset()
		else
			if (href_list["alarm"])
				alarm()
			else
				if (href_list["time"])
					timing = text2num(href_list["time"])
				else
					if (href_list["tp"])
						var/tp = text2num(href_list["tp"])
						time += tp
						time = min(max(round(time), 0), 120)
		updateUsrDialog()

		add_fingerprint(usr)
	else
		usr << browse(null, "window=firealarm")
		return
	return

/obj/machinery/firealarm/proc/reset()
	if (!working)
		return

	post_alert(0)
	var/area/A = get_area(loc)
	if (!isarea(A))
		return
	if (mechanics) mechanics.fireOutgoing(mechanics.newSignal("alertReset"))
	A.firereset()
	if (ringlimiter)
		ringlimiter = 0
		icon_state = "fire0"
	post_alert(0)
	return

/obj/machinery/firealarm/proc/alarm()
	if (!working)
		return

	var/area/A = get_area(loc)
	if (!isarea(A))
		return
	if (A.fire) // maybe we should trigger an alarm when there already is one, goddamn
		return

	A.firealert()
	post_alert(1)

	if (mechanics) mechanics.fireOutgoing(mechanics.newSignal("alertTriggered"))
	if (!ringlimiter)
		ringlimiter = 1
		playsound(loc, "sound/machines/firealarm.ogg", 50, 1)
		icon_state = "fire1"
	return


/obj/machinery/firealarm/proc/post_alert(var/alarm, var/specific_target)
//	var/radio_frequency/frequency = radio_controller.return_frequency(alarm_frequency)

	if (!frequency) return

	var/signal/alert_signal = get_free_signal()
	alert_signal.source = src
	alert_signal.transmission_method = TRANSMISSION_RADIO
	alert_signal.data["zone"] = alarm_zone
	alert_signal.data["type"] = "Fire"
	alert_signal.data["netid"] = net_id
	alert_signal.data["sender"] = net_id
	if (specific_target)
		alert_signal.data["address_1"] = specific_target

	if (alarm)
		alert_signal.data["alert"] = "fire"
	else
		alert_signal.data["alert"] = "reset"

	frequency.post_signal(src, alert_signal)

/obj/machinery/firealarm/receive_signal(signal/signal)
	if (stat & NOPOWER || !frequency)
		return

	var/sender = signal.data["sender"]
	if (!signal || signal.encryption || !sender)
		return

	if (signal.data["address_1"] == net_id)
		switch (lowertext(signal.data["command"]))
			if ("status")
				post_alert(icon_state == "fire0", sender)
			if ("trigger")
				alarm()
			if ("reset")
				reset()


	else if (signal.data["address_1"] == "ping")
		var/signal/reply = new
		reply.source = src
		reply.transmission_method = TRANSMISSION_RADIO
		reply.data["address_1"] = sender
		reply.data["command"] = "ping_reply"
		reply.data["device"] = "PNET_FIREALARM"
		reply.data["netid"] = net_id
		reply.data["alert"] = icon_state == "fire0" ? "reset" : "fire"
		reply.data["zone"] = alarm_zone
		reply.data["type"] = "Fire"
		spawn (5)
			frequency.post_signal(src, reply)
		return

	return