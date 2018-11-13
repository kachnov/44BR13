//
// Party alarm
//

/obj/machinery/partyalarm
	name = "Party Button"
	icon = 'icons/obj/monitors.dmi'
	icon_state = "party"
	desc = "WOOP WOOP PARTY ALARM WOOP WOOP"
	var/detecting = 1.0
	var/working = 1.0
	var/time = 10.0
	var/timing = 0.0
	var/lockdownbyai = 0
	anchored = 1.0
	mats = 5

/obj/machinery/partyalarm/attack_hand(mob/user as mob)
	if (user.stat || stat & (NOPOWER|BROKEN))
		return

	user.machine = src
	var/area/A = loc
	var/d1
	var/d2
	A = A.loc

	if (A.party)
		d1 = text("<A href='?src=\ref[];reset=1'>No Party :(</A>", src)
	else
		d1 = text("<A href='?src=\ref[];alarm=1'>PARTY!!!</A>", src)
	if (timing)
		d2 = text("<A href='?src=\ref[];time=0'>Stop Time Lock</A>", src)
	else
		d2 = text("<A href='?src=\ref[];time=1'>Initiate Time Lock</A>", src)
	var/second = time % 60
	var/minute = (time - second) / 60
	var/dat = text("<HTML><HEAD></HEAD><BODY><TT><strong>Party Button</strong> []<br><HR><br>Timer System: []<BR><br>Time Left: [][] <A href='?src=\ref[];tp=-30'>-</A> <A href='?src=\ref[];tp=-1'>-</A> <A href='?src=\ref[];tp=1'>+</A> <A href='?src=\ref[];tp=30'>+</A><br></TT></BODY></HTML>", d1, d2, (minute ? text("[]:", minute) : null), second, src, src, src, src)
	user << browse(dat, "window=partyalarm")
	onclose(user, "partyalarm")
	return

/obj/machinery/partyalarm/proc/reset()
	if (!( working ))
		return
	var/area/A = get_area(src)
	if (!( istype(A, /area) ))
		return
	A.partyreset()
	return

/obj/machinery/partyalarm/proc/alarm()
	if (!( working ))
		return
	var/area/A = get_area(src)
	if (!( istype(A, /area) ))
		return
	A.partyalert()
	return

/obj/machinery/partyalarm/Topic(href, href_list)
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
		usr << browse(null, "window=partyalarm")
		return
	return
