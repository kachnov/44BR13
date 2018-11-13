/obj/machinery/sec_lock/attack_ai(user as mob)
	return //attack_hand(user)

/obj/machinery/sec_lock/attack_hand(var/mob/user as mob)
	if (..())
		return
	use_power(10)

	if (loc == user.loc)
		var/dat = text("<strong>Security Pad:</strong><BR><br>Keycard: []<BR><br><A href='?src=\ref[];door1=1'>Toggle Outer Door</A><BR><br><A href='?src=\ref[];door2=1'>Toggle Inner Door</A><BR><br><BR><br><A href='?src=\ref[];em_cl=1'>Emergency Close</A><BR><br><A href='?src=\ref[];em_op=1'>Emergency Open</A><BR>", (scan ? text("<A href='?src=\ref[];card=1'>[]</A>", src, scan.name) : text("<A href='?src=\ref[];card=1'>-----</A>", src)), src, src, src, src)
		user << browse(dat, "window=sec_lock")
		onclose(user, "sec_lock")
	return

/obj/machinery/sec_lock/attackby(nothing, user as mob)
	return attack_hand(user)

/obj/machinery/sec_lock/New()
	..()
	spawn ( 2 )
		if (a_type == 1)
			d2 = locate(/obj/machinery/door, locate(x - 2, y - 1, z))
			d1 = locate(/obj/machinery/door, get_step(src, SOUTHWEST))
		else
			if (a_type == 2)
				d2 = locate(/obj/machinery/door, locate(x - 2, y + 1, z))
				d1 = locate(/obj/machinery/door, get_step(src, NORTHWEST))
			else
				d1 = locate(/obj/machinery/door, get_step(src, SOUTH))
				d2 = locate(/obj/machinery/door, get_step(src, SOUTHEAST))
		return
	return

/obj/machinery/sec_lock/Topic(href, href_list)
	if (..())
		return
	if ((!( d1 ) || !( d2 )))
		boutput(usr, "<span style=\"color:red\">Error: Cannot interface with door security!</span>")
		return
	if ((usr.contents.Find(src) || (in_range(src, usr) && istype(loc, /turf)) || (istype(usr, /mob/living/silicon))))
		usr.machine = src
		if (href_list["card"])
			if (scan)
				scan.set_loc(loc)
				scan = null
			else
				var/obj/item/card/id/I = usr.equipped()
				if (istype(I, /obj/item/card/id))
					usr.drop_item()
					I.set_loc(src)
					scan = I
		if (href_list["door1"])
			if (scan)
				if (check_access(scan))
					if (d1.density)
						spawn ( 0 )
							d1.open()
							return
					else
						spawn ( 0 )
							d1.close()
							return
		if (href_list["door2"])
			if (scan)
				if (check_access(scan))
					if (d2.density)
						spawn ( 0 )
							d2.open()
							return
					else
						spawn ( 0 )
							d2.close()
							return
		if (href_list["em_cl"])
			if (scan)
				if (check_access(scan))
					if (!( d1.density ))
						d1.close()
						return
					sleep(1)
					spawn ( 0 )
						if (!( d2.density ))
							d2.close()
						return
		if (href_list["em_op"])
			if (scan)
				if (check_access(scan))
					spawn ( 0 )
						if (d1.density)
							d1.open()
						return
					sleep(1)
					spawn ( 0 )
						if (d2.density)
							d2.open()
						return
		add_fingerprint(usr)
		updateUsrDialog()
	return
