/obj/machinery/atmospherics/unary/cold_sink/freezer
	name = "freezer"
	icon = 'icons/obj/Cryogenic2.dmi'
	icon_state = "freezer_0"
	density = 1
	anchored = 1.0
	current_heat_capacity = 1000
	var/pipe_direction = 1

	north
		dir = NORTH
	east
		dir = EAST
	south
		dir = SOUTH
	west
		dir = WEST

	// Medbay and kitchen freezers start at correct temperature to avoid pointless busywork.
	cryo
		name = "freezer (cryo cell)"
		current_temperature = 73.15

		north
			dir = NORTH
		east
			dir = EAST
		south
			dir = SOUTH
		west
			dir = WEST

	kitchen
		name = "freezer (kitchen)"
		current_temperature = 150
		on = 1

		north
			dir = NORTH
		east
			dir = EAST
		south
			dir = SOUTH
		west
			dir = WEST

	New()
		..()
		pipe_direction = dir
		initialize_directions = pipe_direction

	initialize()
		if (node) return

		var/node_connect = pipe_direction

		for (var/obj/machinery/atmospherics/target in get_step(src,node_connect))
			if (target.initialize_directions & get_dir(target,src))
				node = target
				break

		update_icon()


	update_icon()
		if (node)
			if (on)
				icon_state = "freezer_1"
			else
				icon_state = "freezer"
		else
			icon_state = "freezer_0"
		return

	attack_ai(mob/user as mob)
		return attack_hand(user)

	attack_hand(mob/user as mob)
		user.machine = src
		var/temp_text = ""
		if (air_contents.temperature > (T0C - 20))
			temp_text = "<FONT color=red>[air_contents.temperature]</FONT>"
		else if (air_contents.temperature < (T0C - 20) && air_contents.temperature > (T0C - 100))
			temp_text = "<FONT color=black>[air_contents.temperature]</FONT>"
		else
			temp_text = "<FONT color=blue>[air_contents.temperature]</FONT>"

		var/dat = {"<strong>Cryo gas cooling system</strong><BR>
		Current status: [ on ? "<A href='?src=\ref[src];start=1'>Off</A> <strong>On</strong>" : "<strong>Off</strong> <A href='?src=\ref[src];start=1'>On</A>"]<BR>
		Current gas temperature: [temp_text]<BR>
		Current air pressure: [air_contents.return_pressure()]<BR>
		Target gas temperature: <A href='?src=\ref[src];temp=-10'>-</A> <A href='?src=\ref[src];temp=-1'>-</A> <A href='?src=\ref[src];settemp=1'>[current_temperature]</A> <A href='?src=\ref[src];temp=1'>+</A> <A href='?src=\ref[src];temp=10'>+</A><BR>
		"}

		user << browse(dat, "window=freezer;size=400x500")
		onclose(user, "freezer")

	Topic(href, href_list)
		if ((usr.contents.Find(src) || ((get_dist(src, usr) <= 1) && istype(loc, /turf))) || (istype(usr, /mob/living/silicon/ai)))
			usr.machine = src
			if (href_list["start"])
				on = !on
				update_icon()
			if (href_list["temp"])
				var/amount = text2num(href_list["temp"])
				if (amount > 0)
					current_temperature = min(T20C, current_temperature+amount)
				else
					current_temperature = max((T0C - 200), current_temperature+amount)
			if (href_list["settemp"])
				var/change = input(usr,"Target Temperature (73.15-293.15):","Enter target temperature",current_temperature) as num
				if (!isnum(change)) return
				current_temperature = min(max(73.15, change),293.15)
				updateUsrDialog()
				return

		updateUsrDialog()
		add_fingerprint(usr)
		return

	process()
		..()
		updateUsrDialog()
		if (prob(5) && on)
			playsound(loc, ambience_atmospherics, 30, 1)