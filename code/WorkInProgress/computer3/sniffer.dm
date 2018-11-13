//A packet sniffer!!

/obj/item/device/net_sniffer
	name = "Packet Sniffer"
	desc = "An electronic device designed to intercept network transmissions."
	icon_state = "sniffer0"
	item_state = "electronic"
	w_class = 4.0
	rand_pos = 0
	var/mode = 0
	var/obj/machinery/power/data_terminal/link = null
	var/filter_id = null
	var/list/Filters = list()
	var/last_intercept = 0
	var/list/packet_data = list()
	var/max_logs = 8

	attack_ai()
		return

	attack_hand(mob/user as mob)
		if (mode)
			interact(user)
			return

		else
			..()

	attackby(var/obj/item/I, var/mob/user)
		if (istype(I, /obj/item/screwdriver))
			if (!mode)
				var/turf/T = loc
				if (isturf(T) && !T.intact)
					var/obj/machinery/power/data_terminal/test_link = locate() in T
					if (test_link && !test_link.is_valid_master(test_link.master))
						link = test_link
						link.master = src

						anchored = 1
						mode = 1
						user.visible_message("[user] attaches the [src] to the data terminal.","You attach the [src] to the data terminal.")

						icon_state = "sniffer1"

					else

						boutput(user, "<span style=\"color:red\">The [src] couldn't be attached here!</span>")
						return

				else
					boutput(user, "Device must be placed over a free data terminal to attach to it.")
					return
			else
				anchored = 0
				mode = 0
				user.visible_message("[user] detaches the [src] from the data terminal.","You detach the [src] from the data terminal.")
				icon_state = "sniffer0"
				if (link)
					link.master = null
				link = null
				return
		else
			..()

	attack_self(mob/user as mob)
		return interact(user)

	proc/interact(mob/user as mob)

		var/dat = "<html><head><title>Packet Sniffer</title></head><body>"

		dat += "Current sender filter: <a href='byond://?src=\ref[src];filtid=1'>[filter_id ? filter_id : "NONE"]</a><br>"

		dat += "<hr><strong>Packet log:</strong><hr>"
		if (packet_data.len)
			for (var/a in packet_data)
				dat += "<tt>[a]</tt><br>"
		else
			dat += "<strong>NONE</strong>"

		dat += "<hr>"
		user << browse(dat,"window=packets")
		onclose(user,"packets")
		return

	Topic(href, href_list)
		..()

		if (usr.contents.Find(src) || usr.contents.Find(master) || (istype(loc, /turf) && get_dist(src, usr) <= 1))
			if (usr.stat || usr.restrained())
				return

			add_fingerprint(usr)
			usr.machine = src

			if (href_list["filtid"])
				var/t = input(usr, "Please enter new filter net id", name, filter_id) as text
				if (!t)
					filter_id = null
					updateIntDialog()
					return

				if (!in_range(src, usr) || usr.stat || usr.restrained())
					return

				if (length(t) != 8 || !ishex(t))
					filter_id = null
					updateIntDialog()
					return

				filter_id = t

			updateIntDialog()
			return

		return

	proc/updateIntDialog()
		if (mode)
			updateUsrDialog()
		else
			updateSelfDialog()
		return

	receive_signal(signal/signal)
		if (!mode || !link)
			return
		if (!signal || signal.encryption)
			return

		if (signal.transmission_method != TRANSMISSION_WIRE) //No radio for us thanks
			return

		var/target = signal.data["address_1"]
		if (filter_id && filter_id != target)
			return

		var/badcheck = 0
		for (var/check in Filters)
			if (!(check in signal.data) || signal.data[check] != Filters[check])
				badcheck = 1
				break
		if (badcheck)
			return

		if (!last_intercept || last_intercept + 40 <= world.time)
			playsound(loc, "sound/machines/twobeep.ogg", 25, 1)
		//packet_data = signal.data:Copy()
		var/newdat = "<strong>\[[time2text(world.timeofday,"mm:ss")]:[(world.timeofday%10)]\]:</strong>"
		for (var/i in signal.data)
			newdat += "[i][isnull(signal.data[i]) ? "; " : "=[signal.data[i]]; "]"

		if (signal.data_file)
			. = signal.data_file.asText()
			newdat += "<br>Included file ([signal.data_file.name], [signal.data_file.extension]): [. ? . : "Not printable."]"

		packet_data += newdat
		if (packet_data.len > max_logs)
			packet_data.Cut(1,2)
		last_intercept = world.time
		updateIntDialog()
		return