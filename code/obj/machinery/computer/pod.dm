/obj/machinery/computer/pod
	name = "Pod Launch Control"
	icon_state = "computer_generic"
	var/id = 1.0
	var/obj/machinery/mass_driver/connected = null
	var/timing = 0.0
	var/time = 30.0
	var/TPR = 0

/obj/machinery/computer/pod/old
	icon_state = "old"
	name = "DoorMex Control Computer"

/obj/machinery/computer/pod/old/syndicate
	name = "ProComp Executive IIc"
	desc = "The Syndicate operate on a tight budget. Operates external airlocks."

/obj/machinery/computer/pod/old/swf
	name = "Magix System IV"
	desc = "An arcane artifact that holds much magic. Running E-Knock 2.2: Sorceror's Edition"

	attack_hand(var/mob/user as mob)
		if (!iswizard(user))
			user.show_text("The [name] doesn't respond to your inputs.", "red")
			return
		else
			return ..()

/obj/machinery/computer/pod/proc/alarm()
	if (stat & (NOPOWER|BROKEN))
		return

	if (!( connected ))
		viewers(null, null) << "Cannot locate mass driver connector. Cancelling firing sequence!"
		return
	for (var/obj/machinery/door/poddoor/M)
		if (M.id == id)
			spawn ( 0 )
				M.open()
				return
	sleep(20)

	//connected.drive()		*****RM from 40.93.3S
	for (var/obj/machinery/mass_driver/M in machines)
		if (M.id == id)
			M.power = connected.power
			M.drive()

	sleep(50)
	for (var/obj/machinery/door/poddoor/M)
		if (M.id == id)
			spawn ( 0 )
				M.close()
				return
	return

/obj/machinery/computer/pod/New()
	..()
	spawn ( 5 )
		for (var/obj/machinery/mass_driver/M in machines)
			if (M.id == id)
				connected = M
			else
		return
	return

/obj/machinery/computer/pod/attackby(I as obj, user as mob)
	if (istype(I, /obj/item/screwdriver))
		playsound(loc, "sound/items/Screwdriver.ogg", 50, 1)
		if (do_after(user, 20))
			if (stat & BROKEN)
				boutput(user, "<span style=\"color:blue\">The broken glass falls out.</span>")
				var/obj/computerframe/A = new /obj/computerframe( loc )
				if (material) A.setMaterial(material)
				new /obj/item/raw_material/shard/glass( loc )

				//generate appropriate circuitboard. Accounts for /pod/old computer types
				var/obj/item/circuitboard/pod/M = null
				if (istype(src, /obj/machinery/computer/pod/old))
					M = new /obj/item/circuitboard/olddoor( A )
					if (istype(src, /obj/machinery/computer/pod/old/syndicate))
						M = new /obj/item/circuitboard/syndicatedoor( A )
					if (istype(src, /obj/machinery/computer/pod/old/swf))
						M = new /obj/item/circuitboard/swfdoor( A )
				else //it's not an old computer. Generate standard pod circuitboard.
					M = new /obj/item/circuitboard/pod( A )

				for (var/obj/C in src)
					C.set_loc(loc)
				M.id = id
				A.circuit = M
				A.state = 3
				A.icon_state = "3"
				A.anchored = 1
				qdel(src)
			else
				boutput(user, "<span style=\"color:blue\">You disconnect the monitor.</span>")
				var/obj/computerframe/A = new /obj/computerframe( loc )
				if (material) A.setMaterial(material)
				//generate appropriate circuitboard. Accounts for /pod/old computer types
				var/obj/item/circuitboard/pod/M = null
				if (istype(src, /obj/machinery/computer/pod/old))
					M = new /obj/item/circuitboard/olddoor( A )
					if (istype(src, /obj/machinery/computer/pod/old/syndicate))
						M = new /obj/item/circuitboard/syndicatedoor( A )
					if (istype(src, /obj/machinery/computer/pod/old/swf))
						M = new /obj/item/circuitboard/swfdoor( A )
				else //it's not an old computer. Generate standard pod circuitboard.
					M = new /obj/item/circuitboard/pod( A )

				for (var/obj/C in src)
					C.set_loc(loc)
				M.id = id
				A.circuit = M
				A.state = 4
				A.icon_state = "4"
				A.anchored = 1
				qdel(src)
	else
		attack_hand(user)
	return

/obj/machinery/computer/pod/attack_ai(var/mob/user as mob)
	return attack_hand(user)

/obj/machinery/computer/pod/attack_hand(var/mob/user as mob)
	if (..())
		return

	var/dat = "<HTML><BODY><TT><strong>Mass Driver Controls</strong>"
	user.machine = src
	var/d2
	if (timing)
		d2 = text("<A href='?src=\ref[];time=0'>Stop Time Launch</A>", src)
	else
		d2 = text("<A href='?src=\ref[];time=1'>Initiate Time Launch</A>", src)
	var/second = time % 60
	var/minute = (time - second) / 60
	dat += text("<HR><br>Timer System: []<br>Time Left: [][] <A href='?src=\ref[];tp=-30'>-</A> <A href='?src=\ref[];tp=-1'>-</A> <A href='?src=\ref[];tp=1'>+</A> <A href='?src=\ref[];tp=30'>+</A>", d2, (minute ? text("[]:", minute) : null), second, src, src, src, src)
	if (connected)
		var/temp = ""
		var/list/L = list( 0.25, 0.5, 1, 2, 4, 8, 16 )
		for (var/t in L)
			if (t == connected.power)
				temp += text("[] ", t)
			else
				temp += text("<A href = '?src=\ref[];power=[]'>[]</A> ", src, t, t)
			//Foreach goto(172)
		dat += text("<HR><br>Power Level: []<BR><br><A href = '?src=\ref[];alarm=1'>Firing Sequence</A><BR><br><A href = '?src=\ref[];drive=1'>Test Fire Driver</A><BR><br><A href = '?src=\ref[];door=1'>Toggle Outer Door</A><BR>", temp, src, src, src)
	//*****RM from 40.93.3S
	else
		dat += text("<BR><br><A href = '?src=\ref[];door=1'>Toggle Outer Door</A><BR>", src)
	//*****
	dat += text("<BR><BR><A href='?action=mach_close&window=computer'>Close</A></TT></BODY></HTML>")
	if (istype(src, /obj/machinery/computer/pod/old/swf))
		dat = "<HTML><BODY><TT><strong>Magix IV Shuttle and Teleport Control</strong>"
		if (!TPR)
			dat += "<BR><BR><BR><A href='byond://?src=\ref[src];spell_teleport=1'>Teleport</A><BR>"
		else
			dat += "<BR><BR><BR>RECHARGING TELEPORT<BR><DD>Please stand by...</DD>"
		dat += text("<BR><BR><A href = '?src=\ref[];door=1'>Toggle Outer Door</A><BR>", src)
		dat += text("<BR><BR><A href='?action=mach_close&window=computer'>Close</A></TT></BODY></HTML>")
	user << browse(dat, "window=computer;size=400x500")
	onclose(user, "computer")
	return

/obj/machinery/computer/pod/process()
	..()
	if (timing)
		if (time > 0)
			time = round(time) - 1
		else
			alarm()
			time = 0
			timing = 0
		updateDialog()
	return

/obj/machinery/computer/pod/Topic(href, href_list)
	if (..())
		return
	if ((usr.contents.Find(src) || (in_range(src, usr) && istype(loc, /turf))) || (istype(usr, /mob/living/silicon)))
		usr.machine = src
		if (href_list["spell_teleport"])
			TPR = 1
			spawn (600)
				if (src)
					TPR = 0
					updateDialog()
			usr.machine = null
			usr << browse(null, "window=computer")
			usr.teleportscroll(1, 2, src)
			return
		if (href_list["power"])
			var/t = text2num(href_list["power"])
			t = min(max(0.25, t), 16)
			if (connected)
				connected.power = t
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
					else
						if (href_list["door"])
							for (var/obj/machinery/door/poddoor/M)
								if (M.id == id)
									if (M.density)
										spawn ( 0 )
											M.open()
											return
									else
										spawn ( 0 )
											M.close()
											return
								//Foreach goto(298)
		add_fingerprint(usr)
		updateUsrDialog()

	return



