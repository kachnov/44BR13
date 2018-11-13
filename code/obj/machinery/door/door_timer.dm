/obj/machinery/door_timer
	name = "Door Timer"
	icon = 'icons/obj/stationobjs.dmi'
	icon_state = "doortimer0"
	desc = "A remote control switch for a door."
	req_access = list(access_security)
	anchored = 1.0
	var/id = null
	var/time = 30.0
	var/timing = 0.0
	var/last_tick = 0

	// Please keep synchronizied with these lists for easy map changes:
	// /obj/storage/secure/closet/brig/automatic (secure_closets.dm)
	// /obj/machinery/floorflusher (floorflusher.dm)
	// /obj/machinery/door/window/brigdoor (window.dm)
	// /obj/machinery/flasher (flasher.dm)
	solitary
		name = "Cell #1"
		id = "solitary"

		new_walls
			north
				pixel_y = 24
			east
				pixel_x = 22
			south
				pixel_y = -19
			west
				pixel_x = -22

	solitary2
		name = "Cell #2"
		id = "solitary2"

		new_walls
			north
				pixel_y = 24
			east
				pixel_x = 22
			south
				pixel_y = -19
			west
				pixel_x = -22

	solitary3
		name = "Cell #3"
		id = "solitary3"

		new_walls
			north
				pixel_y = 24
			east
				pixel_x = 22
			south
				pixel_y = -19
			west
				pixel_x = -22

	solitary4
		name = "Cell #4"
		id = "solitary4"

		new_walls
			north
				pixel_y = 24
			east
				pixel_x = 22
			south
				pixel_y = -19
			west
				pixel_x = -22

	minibrig
		name = "Mini-Brig"
		id = "minibrig"

		new_walls
			north
				pixel_y = 24
			east
				pixel_x = 22
			south
				pixel_y = -19
			west
				pixel_x = -22

	minibrig2
		name = "Mini-Brig #2"
		id = "minibrig2"

		new_walls
			north
				pixel_y = 24
			east
				pixel_x = 22
			south
				pixel_y = -19
			west
				pixel_x = -22

	minibrig3
		name = "Mini-Brig #3"
		id = "minibrig3"

		new_walls
			north
				pixel_y = 24
			east
				pixel_x = 22
			south
				pixel_y = -19
			west
				pixel_x = -22

	genpop
		name = "General Population"
		id = "genpop"

		new_walls
			north
				pixel_y = 24
			east
				pixel_x = 22
			south
				pixel_y = -19
			west
				pixel_x = -22

	genpop_n
		name = "General Population North"
		id = "genpop_n"

		new_walls
			north
				pixel_y = 24
			east
				pixel_x = 22
			south
				pixel_y = -19
			west
				pixel_x = -22

	genpop_s
		name = "General Population South"
		id = "genpop_s"

		new_walls
			north
				pixel_y = 24
			east
				pixel_x = 22
			south
				pixel_y = -19
			west
				pixel_x = -22

/obj/machinery/door_timer/examine()
	set src in oview()
	set category = "Local"
	boutput(usr, "A remote control switch for a door.")
	if (timing)
		var/second = time % 60
		var/minute = (time - second) / 60
		boutput(usr, "<span style=\"color:red\">Time Remaining: <strong>[(minute ? text("[minute]:") : null)][second]</strong></span>")
	else boutput(usr, "<span style=\"color:red\">There is no time set.</span>")

/obj/machinery/door_timer/process()
	..()
	if (timing)
		if (!last_tick) last_tick = world.time
		var/passed_time = round(max(round(world.time - last_tick),10) / 10)
		if (time > 0)
			time -= passed_time
		else
			alarm()
			time = 0
			timing = 0
			last_tick = 0
		updateDialog()
		update_icon()
		last_tick = world.time
	else
		last_tick = 0
	return

/obj/machinery/door_timer/power_change()
	update_icon()


// Why range 30? COG2 places linked fixtures much further away from the timer than originally envisioned.
/obj/machinery/door_timer/proc/alarm()
	if (!src)
		return
	if (stat & (NOPOWER|BROKEN))
		return
/*
	for (var/obj/machinery/sim/chair/C in range(30, src))
		if (C.id == id)
			if (!C.active)
				continue
			if (C.con_user)
				C.con_user.network_device = null
				C.active = 0
*/
	for (var/obj/machinery/door/window/brigdoor/M in range(30, src))
		if (M.id == id)
			/*
			if (M.density)
				if (M.id == "genpop")	// opens the inner gen pop door and not the outer so that the perp (and anyone who manages to stow away with him) can be processed for release
					spawn ( 50 )
						M.open()
						spawn ( 250 )
							M.close()
			*/
			spawn (0)
				if (M) M.close()

	for (var/obj/machinery/floorflusher/FF in range(30, src))
		if (FF.id == id)
			if (FF.open != 1)
				FF.openup()
				spawn (300)
					if (FF && FF.open == 1)
						FF.closeup()

	for (var/obj/storage/secure/closet/brig/automatic/B in range(30, src))
		if (B.id == id && B.our_timer == src)
			if (B.locked)
				B.locked = 0
				B.update_icon()
				B.visible_message("<span style=\"color:blue\">[B.name] unlocks automatically.</span>")

	updateUsrDialog()
	update_icon()
	return

/obj/machinery/door_timer/attack_ai(var/mob/user as mob)
	return attack_hand(user)

/obj/machinery/door_timer/attack_hand(var/mob/user as mob)
	if (..())
		return

	var/dat = "<HTML><BODY><TT><strong>[name] door controls</strong>"
	user.machine = src
	var/d2 = "<A href='?src=\ref[src];time=1'>Initiate Time</A><br>"
	if (timing)
		d2 = "<A href='?src=\ref[src];time=0'>Stop Timed</A><br>"
	var/second = time % 60
	var/minute = (time - second) / 60
	dat += "<br><HR><br>Timer System: [d2]<br>Time Left: [(minute ? text("[minute]:") : null)][second] <A href='?src=\ref[src];tp=-30'>-</A> <A href='?src=\ref[src];tp=-1'>-</A> <A href='?src=\ref[src];tp=1'>+</A> <A href='?src=\ref[src];tp=30'>+</A>"
	for (var/obj/machinery/flasher/F in range(10, src))
		if (F.id == id)
			if (F.last_flash && world.time < F.last_flash + 150)
				dat += "<BR><BR><A href='?src=\ref[src];fc=1'>Flash Cell (Charging)</A>"
			else
				dat += "<BR><BR><A href='?src=\ref[src];fc=1'>Flash Cell</A>"
	dat += "<BR><BR><A href='?action=mach_close&window=computer'>Close</A></TT></BODY></HTML>"
	user << browse(dat, "window=computer;size=400x500")
	onclose(user, "computer")
	return

/obj/machinery/door_timer/Topic(href, href_list)
	if (..())
		return
	if ((usr.contents.Find(src) || (in_range(src, usr) && istype(loc, /turf))) || (istype(usr, /mob/living/silicon)))
		usr.machine = src
		if (href_list["time"])
			if (allowed(usr, req_only_one_required))
				if (timing == 0)
					for (var/obj/machinery/door/window/brigdoor/M in range(10, src))
						if (M.id == id)
							M.close()				//close the cell door up when the timer starts.
				else
					for (var/obj/machinery/door/window/brigdoor/M in range(10, src))
						if (M.id == id)
							M.open()				//open the cell door if the timer is stopped.

				timing = text2num(href_list["time"])
				logTheThing("station", usr, null, "[timing ? "starts" : "stops"] a door timer: [src] [log_loc(src)].")

		else
			if (href_list["tp"])
				if (allowed(usr, req_only_one_required))
					var/tp = text2num(href_list["tp"])
					time += tp
					time = min(max(round(time), 0), 300)
					logTheThing("station", usr, null, "[tp > 0 ? "added" : "removed"] [tp % 60]sec (total: [time % 60]sec) to a door timer: [src] [log_loc(src)].")
			if (href_list["fc"])
				if (allowed(usr, req_only_one_required))
					logTheThing("station", usr, null, "sets off flashers from a door timer: [src] [log_loc(src)].")
					for (var/obj/machinery/flasher/F in range(10, src))
						if (F.id == id)
							F.flash()
		add_fingerprint(usr)
		updateUsrDialog()
		update_icon()
	return

/obj/machinery/door_timer/proc/update_icon()
	if (stat & (NOPOWER))
		icon_state = "doortimer-p"
		return
	else if (stat & (BROKEN))
		icon_state = "doortimer-b"
		return
	else
		if (timing)
			icon_state = "doortimer1"
		else if (time > 0)
			icon_state = "doortimer0"
		else
			spawn (50)
				icon_state = "doortimer0"
			icon_state = "doortimer2"