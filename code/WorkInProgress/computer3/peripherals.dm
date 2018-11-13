//CONTENTS
//format_net_id proc
//Base peripheral card
//radio card
//powernet communication card
//combo powernet comm/printer terminal card
//printer card
//prize vending card
//ID scanning card
//Sound card
//Floppy drive
//Rom cart reader
//Electrical scanner interface.
//Portables battery monitor card.




/obj/item/peripheral
	name = "Peripheral card"
	desc = "A computer circuit board."
	icon = 'icons/obj/module.dmi'
	inhand_image_icon = 'icons/mob/inhand/hand_tools.dmi'
	icon_state = "id_mod"
	item_state = "electronic"
	w_class = 2
	var/obj/machinery/computer3/host
	var/id = null
	var/func_tag = "GENERIC" //What kind of peripheral is this, huh??
	var/setup_has_badge = 0 //IF this is set, present return_badge() in the host's browse window
	mats = 8

	New(location)
		..()
		if (istype(location,/obj/machinery/computer3))
			host = location
			if (!host.peripherals)
				host.peripherals = list()
			host.peripherals.Add(src)
		id = "\ref[src]"

	/* new disposing() pattern should handle this. -singh
	Del()
		if (host)
			host.peripherals.Remove(src)
		..()
	*/

	disposing()
		if (host)
			host.peripherals.Remove(src)
			host = null

		..()


	proc
		receive_command(obj/source, command, signal/signal)
			if ((source != host) || !(src in host))
				return TRUE

			if (!command || (signal && signal.encryption && signal.encryption != id))
				return TRUE

			return FALSE

		send_command(command, signal/signal)
			if (!command || !host)
				return

			if (!istype(host) || (host.stat & (NOPOWER|BROKEN)))
				return

			src.host.receive_command(src, command, signal)

			return

		return_status_text()
			return "OK"

		installed(var/obj/machinery/computer3/newhost)
			if (!newhost)
				return TRUE

			if (newhost != src.host)
				src.host = newhost

			if (!(src in src.host.peripherals))
				src.host.peripherals.Add(src)

			return FALSE

		uninstalled() //Called when removed from computer3frame/computer3 is taken apart
			return FALSE

		//If setup_has_badge is set, the text returned here will be available in the computer3 browse window
		return_badge()
			return

	Topic(href, href_list)
		if (!src.host || !(src in src.host.contents))
			return TRUE

		if (usr.stat || usr.restrained())
			return TRUE

		if ((!usr.contents.Find(src.host) && (!in_range(src.host, usr) || !istype(src.host.loc, /turf))) && (!istype(usr, /mob/living/silicon)))
			return TRUE

		if (src.host.stat & (NOPOWER|BROKEN))
			return TRUE

		return FALSE


/obj/item/peripheral/network
	var/code = null //Signal encryption code
	var/net_id = null //What is our ID on the network?
	var/last_ping = 0

/obj/item/peripheral/network/radio
	name = "wireless card"
	desc = "A wireless computer card. It has a bit of a limited range."
	icon_state = "radio_mod"
	func_tag = "RAD_ADAPTER"
	var/frequency = 1419
	var/radio_frequency/radio_connection
	var/range = 8 //How far can our signal travel?? HOW FAR
	var/setup_freq_locked = 0 //If set, frequency cannot be adjusted.
	var/setup_netmode_norange = 1 //If set, there is no range limit in network mode.
	var/net_mode = 0 //If 1, act like a powernet card (ignore tranmissions not addressed to us.)
	//var/logstring = null //Log incoming transmissions.  With a string.

	locked //Locked wireless card
		name = "Limited Wireless card"
		desc = "A wireless computer card, capable of transmitting only at a single frequency."
		//range = 0 //Infinite range!! Infinite range!!
		setup_freq_locked = 1

		pda
			frequency = 1149 //Standard PDA comm frequency.
			net_mode = 1
			func_tag = "NET_ADAPTER"

		status //This one is for status display control.
			frequency = 1435
			setup_netmode_norange = 0

	New()
		..()
		if (radio_controller)
			initialize()

		net_id = format_net_id("\ref[src]")


	initialize()
		set_frequency(frequency)

	disposing()
		if (radio_controller)
			radio_controller.remove_object(src, "[frequency]")
		radio_connection = null

		..()

	proc
		set_frequency(new_frequency)
			radio_controller.remove_object(src, "[frequency]")
			frequency = new_frequency
			radio_connection = radio_controller.add_object(src, "[frequency]")


	receive_command(obj/source, command, signal/signal)
		if (..())
			return TRUE

		if (!radio_connection)
			return TRUE

		var/broadcast_range = range //No range in network mode!!
		if (setup_netmode_norange && net_mode)
			broadcast_range = 0

		switch(command)
			if ("transmit")
				if (!signal)
					return
				var/signal/newsignal = get_free_signal()
				newsignal.data = signal.data:Copy()
				if (signal.data_file) //Gonna transfer so many files.
					newsignal.data_file = signal.data_file.copy_file()
				newsignal.encryption = code
				newsignal.transmission_method = TRANSMISSION_RADIO
				if (net_mode)
					if (!newsignal.data["address_1"])
						//Net_mode demands an address_1 value!
						//qdel(newsignal)
						return TRUE

					newsignal.data["sender"] = net_id

				radio_connection.post_signal(src, newsignal, broadcast_range)

				return FALSE

			if ("mode_net")
				net_mode = 1
				func_tag = "NET_ADAPTER" //Pretend to be that fukken wired card.
				return FALSE

			if ("mode_free")
				net_mode = 0
				func_tag = "RAD_ADAPTER"
				return FALSE

			if ("ping")
				if (!net_mode)
					return TRUE

				if ( (last_ping && ((last_ping + 10) >= world.time) ) || !net_id)
					return TRUE

				last_ping = world.time
				var/signal/newsignal = get_free_signal()
				newsignal.data["address_1"] = "ping"
				newsignal.data["sender"] = net_id
				newsignal.transmission_method = TRANSMISSION_RADIO
				radio_connection.post_signal(src, newsignal, broadcast_range)
				return FALSE

			if ("help")
				return "Valid commands: transmit, mode_net, mode_free, ping, or 1000-1500 to set frequency."

			else
				if (!setup_freq_locked)
					var/new_freq = round(text2num(command))
					if (new_freq && (new_freq >= 1000 && new_freq <= 1500))
						set_frequency(new_freq)
						return FALSE


		return TRUE

	receive_signal(signal/signal)
		if (!src.host || host.stat & (NOPOWER|BROKEN))
			return

		if (!signal || (signal.encryption && signal.encryption != code))
			return

		//src.logstring += "R@[src.frequency]:[src.code];"

		//It better be for us.  Or a ping request.
		if (net_mode)

			if (signal.data["address_1"] != net_id)
				if ((signal.data["address_1"] == "ping") && signal.data["sender"])
					var/signal/pingsignal = get_free_signal()
					pingsignal.source = host
					pingsignal.data["device"] = "WNET_ADAPTER"
					pingsignal.data["netid"] = net_id
					pingsignal.data["address_1"] = signal.data["sender"]
					pingsignal.data["command"] = "ping_reply"
					pingsignal.data["data"] = host.name
					pingsignal.transmission_method = TRANSMISSION_RADIO
					var/broadcast_range = range
					if (setup_netmode_norange)
						broadcast_range = 0
					spawn (5) //Send a reply for those curious jerks
						radio_connection.post_signal(src, pingsignal, broadcast_range)

				return

		var/signal/newsignal = get_free_signal()
		newsignal.data = signal.data:Copy()
		//if (code)
			//newsignal.encryption = code
		if (signal.data_file)
			newsignal.data_file = signal.data_file.copy_file()

		send_command("receive",newsignal)
		return


	return_status_text()
		. = "FREQ: [frequency]"
		if (net_mode)
			//We are in powernet card emulation mode.
			. += " | NETID: [net_id ? net_id : "NONE"]"
		else //We are in free radio mode.
			. += " | RANGE: [range ? "[range]" : "FULL"]"

/obj/item/peripheral/network/powernet_card
	name = "wired network card"
	desc = "A computer networking card designed to transmit information over power lines."
	icon_state = "power_mod"
	func_tag = "NET_ADAPTER"
	var/net_number = null
	var/obj/machinery/power/data_terminal/data_link = null //For communicating with the powernet.

	New()
		..()
		spawn (10)
			if (host && !data_link) //Wait for the map to load and hook up if installed() hasn't done it.
				check_connection()
			//Let's blindy attempt to generate a unique network ID!
			net_id = format_net_id("\ref[src]")



	installed(var/obj/machinery/computer3/newhost)
		if (..())
			return TRUE

		data_link = null
		check_connection()

		return FALSE

	uninstalled()
		//Clear our status as the link's master, then null out that link.

		//boutput(world, "uninstalling")
		if ((data_link) && (data_link.master == src))
			//boutput(world, "clearing link of [src]")
			data_link.master = null

		data_link = null
		return FALSE

	disposing()
		uninstalled()

		..()

	receive_command(obj/source, command, signal/signal)
		if (..())
			return TRUE

		if (!check_connection())
			return TRUE

		if (command == "transmit") //Transmit a copy of the command signal
			if (!signal)
				return TRUE

			var/signal/newsignal = get_free_signal()
			newsignal.data = signal.data:Copy()

			if (signal.data_file) //Gonna transfer so many files.
				newsignal.data_file = signal.data_file.copy_file()

			newsignal.data["sender"] = net_id //Override whatever jerk info they put here.
			newsignal.encryption = code
			newsignal.transmission_method = TRANSMISSION_WIRE
			data_link.post_signal(src, newsignal)
			return FALSE

		else if (dd_hasprefix(command, "ping")) //Just a shortcut for pinging the network.
			if ( (last_ping && ((last_ping + 10) >= world.time) ) || !net_id)
				return TRUE

			last_ping = world.time
			var/signal/newsignal = get_free_signal()
			newsignal.data["address_1"] = "ping"
			newsignal.data["sender"] = net_id
			if (length(command) > 4)
				var/new_net_number = text2num( copytext(command, 5) )
				if (new_net_number != null && new_net_number >= 0 && new_net_number <= 16)
					newsignal.data["net"] = "[new_net_number]"
				else if (net_number)
					newsignal.data["net"] = "[net_number]"
			else if (net_number)
				newsignal.data["net"] = "[net_number]"

			newsignal.transmission_method = TRANSMISSION_WIRE
			data_link.post_signal(src, newsignal)
			return FALSE

		else if (dd_hasprefix(command, "subnet"))
			if (length(command) > 6)
				var/new_net_number = text2num( copytext(command, 7) )
				if (new_net_number != null && new_net_number >= 0 && new_net_number <= 16)
					net_number = new_net_number
			else
				net_number = null

			return FALSE

		else if (command == "help")
			return "Valid commands: transmit, ping, or subnet# to set subnet"

		return TRUE

	receive_signal(signal/signal)
		if (!src.host || host.stat & (NOPOWER|BROKEN))
			return
		if (!signal || !net_id || (signal.encryption && signal.encryption != code))
			return

		if (signal.transmission_method != TRANSMISSION_WIRE) //No radio for us thanks
			return

		if (!data_link || !check_connection())
			return

		//They don't need to target us specifically to ping us.
		//Otherwise, ff they aren't addressing us, ignore them
		if (signal.data["address_1"] != net_id)
			if ((signal.data["address_1"] == "ping") && ((signal.data["net"] == null) || ("[signal.data["net"]]" == "[net_number]")) && signal.data["sender"])
				var/signal/pingsignal = get_free_signal()
				pingsignal.data["device"] = "PNET_ADAPTER"
				pingsignal.data["netid"] = net_id
				pingsignal.data["address_1"] = signal.data["sender"]
				pingsignal.data["command"] = "ping_reply"
				pingsignal.transmission_method = TRANSMISSION_WIRE
				spawn (5) //Send a reply for those curious jerks
					data_link.post_signal(src, pingsignal)

			return //Just toss out the rest of the signal then I guess

		var/signal/newsignal = get_free_signal()
		newsignal.data = signal.data:Copy()
		if (signal.data_file) //Gonna transfer so many files.
			newsignal.data_file = signal.data_file.copy_file()

		send_command("receive",newsignal)
		return


	return_status_text()
		. = "LINK: [data_link ? "ACTIVE" : "!NONE!"]"
		. += " | NETID: [net_id ? net_id : "NONE"]"


	proc
		check_connection()
			//if there is a link, it has a master, and the master is valid..
			if (data_link && istype(data_link) && (data_link.master) && data_link.is_valid_master(data_link.master))
				if (data_link.master == src)
					return TRUE //If it's already us, the connection is fine!
				else//Otherwise welp no this thing is taken.
					data_link = null
					return FALSE
			data_link = null
			var/turf/T = get_turf(src)
			var/obj/machinery/power/data_terminal/test_link = locate() in T
			if (test_link && !test_link.is_valid_master(test_link.master))
				data_link = test_link
				data_link.master = src
				return TRUE
			else
				//boutput(world, "couldn't link")
				return FALSE

			return FALSE

/obj/item/peripheral/network/powernet_card/terminal
	name = "Terminal card"
	desc = "A networking/printing combo card designed to fit into a computer casing."
	icon_state = "card_mod"
	var/printing = 0

	receive_command(obj/source, command, signal/signal)
		if ((source != host) || !(src in host))
			return TRUE

		if (!command || (signal && signal.encryption && signal.encryption != id))
			return TRUE

		if (!check_connection())
			return TRUE

		switch(command)
			if ("transmit") //Transmit a copy of the command signal
				if (!signal)
					return TRUE

				var/signal/newsignal = get_free_signal()
				newsignal.data = signal.data:Copy()

				if (signal.data_file) //Gonna transfer so many files.
					newsignal.data_file = signal.data_file.copy_file()

				newsignal.data["sender"] = net_id //Override whatever jerk info they put here.
				newsignal.encryption = code
				newsignal.transmission_method = TRANSMISSION_WIRE
				data_link.post_signal(src, newsignal)



				//src.logstring += "T@[time2text(world.realtime, "hh:mm:ss")]|[src.code]|[strip_html(command)];"
/*
			if ("ping")
				if ( (last_ping && ((last_ping + 10) >= world.time) ) || !net_id)
					return

				last_ping = world.time
				var/signal/newsignal = get_free_signal()
				newsignal.data["address_1"] = "ping"
				newsignal.data["sender"] = net_id
				newsignal.transmission_method = TRANSMISSION_WIRE
				data_link.post_signal(src, newsignal)
*/
			if ("print")
				if (printing)
					return TRUE
				printing = 1

				var/print_data = signal.data["data"]
				var/print_title = signal.data["title"]
				if (!print_data)
					printing = 0
					return TRUE
				spawn (50)
					var/obj/item/paper/thermal/P = new /obj/item/paper/thermal( src.host.loc )
					playsound(src.host.loc, "sound/machines/printer_thermal.ogg", 50, 1)
					P.info = "<tt>[print_data]</tt>"
					if (print_title)
						P.name = "paper- '[print_title]'"

					printing = 0
					return FALSE

			if ("help")
				return "Valid commands: transmit, print, or subnet# to set subnet."

			else
				if (dd_hasprefix(command, "ping"))
					if ( (last_ping && ((last_ping + 10) >= world.time) ) || !net_id)
						return TRUE

					last_ping = world.time
					var/signal/newsignal = get_free_signal()
					newsignal.data["address_1"] = "ping"
					newsignal.data["sender"] = net_id

					if (length(command) > 4)
						var/new_net_number = text2num( copytext(command, 5) )
						if (new_net_number != null && new_net_number >= 0 && new_net_number <= 16)
							newsignal.data["net"] = "[new_net_number]"
						else if (net_number)
							newsignal.data["net"] = "[net_number]"
					else if (net_number)
						newsignal.data["net"] = "[net_number]"

					newsignal.transmission_method = TRANSMISSION_WIRE
					data_link.post_signal(src, newsignal)

				else if (dd_hasprefix(command, "subnet"))
					if (length(command) > 6)
						var/new_net_number = text2num( copytext(command, 7) )
						if (new_net_number != null && new_net_number >= 0 && new_net_number <= 16)
							net_number = new_net_number
					else
						net_number = null

		return FALSE

/obj/item/peripheral/network/omni
	name = "omni network card"
	desc = "A computer networking card designed to transmit information over either power lines or wirelessly.  It has a mode_wire mode in addition to the typical mode_net and mode_free options."
	icon_state = "radio_mod"
	func_tag = "RAD_ADAPTER"
	var/mode = 2 //0: is free radio, 1 is network radio, 2 is wired network
	var/printing = 0

	var/obj/machinery/power/data_terminal/wired_link = null
	var/subnet = null

	var/radio_frequency/wireless_link = null
	var/frequency = 1419
	var/wireless_range = 8

	New()
		..()
		if (radio_controller)
			initialize()

		spawn (10)
			if (src.host && !src.wired_link) //Wait for the map to load and hook up if installed() hasn't done it.
				check_wired_connection()
			//Let's blindy attempt to generate a unique network ID!
			net_id = format_net_id("\ref[src]")

			set_frequency(frequency)

	receive_command(obj/source, command, signal/signal)
		if ((source != host) || !(src in host))
			return TRUE

		if (!command || (signal && signal.encryption && signal.encryption != id))
			return TRUE

		command = lowertext(command)
		switch(command)
			if ("transmit")
				if (mode < 2)
					if (!wireless_link)
						return TRUE

					var/signal/newsignal = get_free_signal()
					newsignal.data = signal.data:Copy()

					if (signal.data_file) //Gonna transfer so many files.
						newsignal.data_file = signal.data_file.copy_file()

					if (mode == 1)
						newsignal.data["sender"] = net_id
					newsignal.transmission_method = TRANSMISSION_RADIO
					wireless_link.post_signal(src, newsignal, (mode == 1 ? 0 : wireless_range))
					return FALSE

				else
					if (!wired_link && !check_wired_connection())
						return TRUE

					var/signal/newsignal = get_free_signal()
					newsignal.data = signal.data:Copy()

					if (signal.data_file) //Gonna transfer so many files.
						newsignal.data_file = signal.data_file.copy_file()

					newsignal.data["sender"] = net_id
					newsignal.transmission_method = TRANSMISSION_WIRE
					wired_link.post_signal(src, newsignal)
					return FALSE

				return TRUE

			if ("mode_free")
				mode = 0
				func_tag = "RAD_ADAPTER"
				return FALSE

			if ("mode_net")
				mode = 1
				func_tag = "NET_ADAPTER"
				return FALSE

			if ("mode_wire")
				mode = 2
				func_tag = "NET_ADAPTER"
				return FALSE

			if ("print")
				if (printing)
					return TRUE
				printing = 1

				var/print_data = signal.data["data"]
				var/print_title = signal.data["title"]
				if (!print_data)
					printing = 0
					return TRUE
				spawn (50)
					var/obj/item/paper/thermal/P = new /obj/item/paper/thermal( src.host.loc )
					playsound(src.host.loc, "sound/machines/printer_thermal.ogg", 50, 1)
					P.info = "<tt>[print_data]</tt>"
					if (print_title)
						P.name = "paper- '[print_title]'"

					printing = 0
					return FALSE

			if ("help")
				return "Valid commands: transmit, mode_net, mode_free, mode_wire, print, ping, subnet# to set subnet, or 1000-1500 to set frequency in wireless modes."

			else
				if (copytext(command, 1, 5) == "ping")
					if (mode == 1)
						if (!wireless_link)
							return TRUE

						if ( (last_ping && ((last_ping + 10) >= world.time) ) || !net_id)
							return TRUE

						last_ping = world.time
						var/signal/newsignal = get_free_signal()
						newsignal.data["address_1"] = "ping"
						newsignal.data["sender"] = net_id

						newsignal.transmission_method = TRANSMISSION_RADIO
						wireless_link.post_signal(src, newsignal)

						return FALSE

					else if (mode == 2)
						if (!wired_link)
							return TRUE

						if ( (last_ping && ((last_ping + 10) >= world.time) ) || !net_id)
							return TRUE

						last_ping = world.time
						var/signal/newsignal = get_free_signal()
						newsignal.data["address_1"] = "ping"
						newsignal.data["sender"] = net_id

						if (subnet)
							newsignal.data["net"] = "[subnet]"

						newsignal.transmission_method = TRANSMISSION_WIRE
						wired_link.post_signal(src, newsignal)

						return FALSE

					return TRUE

				else if (copytext(command, 1, 7) == "subnet")
					. = text2num( copytext(command, 7) )
					if (. != null && . >= 0 && . <= 16)
						subnet = .
					else
						subnet = null

					return FALSE

				else if (mode < 2)
					. = text2num(command)
					if (isnum(.))
						. = round( max(1000, min(., 1500)) )
						set_frequency(.)
						return FALSE

		return TRUE

	receive_signal(signal/signal)
		if (!src.host || host.stat & (NOPOWER|BROKEN))
			return

		if (!signal || !net_id || signal.encryption)
			return

		if ((mode < 2 && !wireless_link) || (mode == 2 && (!wired_link || !check_wired_connection())))
			return

		if (signal.data["address_1"] != net_id)
			if ((signal.data["address_1"] == "ping") && ((signal.data["net"] == null) || ("[signal.data["net"]]" == "[subnet]")) && signal.data["sender"])
				var/signal/pingsignal = get_free_signal()
				pingsignal.data["device"] = "[mode == 2 ? "P" : null]NET_ADAPTER"
				pingsignal.data["netid"] = net_id
				pingsignal.data["address_1"] = signal.data["sender"]
				pingsignal.data["command"] = "ping_reply"
				pingsignal.transmission_method = mode == 2 ? TRANSMISSION_WIRE : TRANSMISSION_RADIO
				spawn (5) //Send a reply for those curious jerks
					if (mode == 2 && wired_link)
						wired_link.post_signal(src, pingsignal)
					else if (wireless_link)
						wireless_link.post_signal(src, pingsignal)

			return //Just toss out the rest of the signal then I guess

		var/signal/newsignal = get_free_signal()
		newsignal.data = signal.data:Copy()
		if (signal.data_file) //Gonna transfer so many files.
			newsignal.data_file = signal.data_file.copy_file()

		send_command("receive",newsignal)
		return

	installed(var/obj/machinery/computer3/newhost)
		if (..())
			return TRUE

		if (!wireless_link)
			wireless_link = radio_controller.add_object(src, "[frequency]")

		//wired_link = null
		check_wired_connection()

		return FALSE

	uninstalled()

		//Unsubscribe from any wireless link we might have
		if (wireless_link)
			radio_controller.remove_object(src, "[frequency]")
			wireless_link = null

		//Clear our status as the wired link's master, then null out that link.
		if ((wired_link) && (wired_link.master == src))
			wired_link.master = null

		wired_link = null
		return FALSE

	return_status_text()
		if (mode < 2)
			. = "FREQ: [frequency]"
			if (mode == 1)
				//We are in powernet card emulation mode.
				. += " | NETID: [net_id ? net_id : "NONE"]"
			else //We are in free radio mode.
				. += " | RANGE: [wireless_range ? "[wireless_range]" : "FULL"]"

		else
			. = "LINK: [wired_link ? "ACTIVE" : "!NONE!"]"
			. += " | NETID: [net_id ? net_id : "NONE"]"

	disposing()
		uninstalled()

		..()

	proc/set_frequency(new_frequency)
		radio_controller.remove_object(src, "[frequency]")
		frequency = new_frequency
		wireless_link = radio_controller.add_object(src, "[frequency]")

	proc/check_wired_connection()
		//if there is a link, it has a master, and the master is valid..
		if (istype(wired_link) && (wired_link.master) && wired_link.is_valid_master(wired_link.master))
			if (wired_link.master == src)
				return TRUE //If it's already us, the connection is fine!
			else//Otherwise welp no this thing is taken.
				wired_link = null
				return FALSE

		wired_link = null
		var/turf/T = get_turf(src)
		var/obj/machinery/power/data_terminal/test_link = locate() in T
		if (test_link && !test_link.is_valid_master(test_link.master))
			wired_link = test_link
			wired_link.master = src
			return TRUE
		else
			return FALSE

		return FALSE

/obj/item/peripheral/printer
	name = "Printer module"
	desc = "A small printer designed to fit into a computer casing."
	icon_state = "card_mod"
	func_tag = "LAR_PRINTER"
	var/printing = 0

	receive_command(obj/source,command, signal/signal)
		if (..())
			return TRUE

		if (!signal)
			return TRUE

		if ((command == "print") && !printing)
			printing = 1

			var/print_data = signal.data["data"]
			var/print_title = signal.data["title"]
			if (!print_data)
				printing = 0
				return
			spawn (50)
				var/obj/item/paper/thermal/P = new /obj/item/paper/thermal( src.host.loc )
				playsound(src.host.loc, "sound/machines/printer_thermal.ogg", 50, 1)
				P.info = "<tt>[print_data]</tt>"
				if (print_title)
					P.name = "paper- '[print_title]'"

				printing = 0
				return FALSE
		else if (command == "help")
			return "Valid command: print, accompanied by a file to print."


		return TRUE

	return_status_text()
		var/status = "PRINTING?: [printing ? "YES" : "NO"]"

		return status


/obj/item/peripheral/prize_vendor
	name = "Prize vending module"
	desc = "An arcade prize dispenser designed to fit inside a computer casing."
	icon_state = "id_mod"
	func_tag = "LAR_VENDOR"
	var/last_vend = 0 //Delay between vends so it can't be spammed (ie a dude is holding it and shaking stuff out)

	return_status_text()
		var/status_text = "RECHARGING"
		if ((last_vend + 400) < world.time)
			status_text = "READY"
		return status_text

	receive_command(obj/source,command, signal/signal)
		if (..())
			return TRUE

		if ((command == "vend") && ((last_vend + 400) < world.time))
			vend_prize()
			last_vend = world.time
			return FALSE

		else
			return "Valid command: \"vend\" to vend prize."

		return TRUE

	attack_self(mob/user as mob)
		if ( (last_vend + 400) < world.time)
			boutput(user, "You shake something out of [src]!")
			vend_prize()
			last_vend = world.time
		else
			boutput(user, "<span style=\"color:red\">[src] isn't ready to dispense a prize yet.</span>")

		return

	proc/vend_prize()
		var/obj/item/prize
		var/prizeselect = rand(1,4)
		var/turf/prize_location = null

		if (src.host)
			prize_location = src.host.loc
		else
			prize_location = get_turf(src)

		switch(prizeselect)
			if (1)
				prize = new /obj/item/spacecash( prize_location )
				prize.name = "space ticket"
				prize.desc = "It's almost like actual currency!"
			if (2)
				prize = new /obj/item/device/radio/beacon( prize_location )
				prize.name = "electronic blink toy game"
				prize.desc = "Blink.  Blink.  Blink."
			if (3)
				prize = new /obj/item/zippo( prize_location )
				prize.name = "Burno Lighter"
				prize.desc = "Almost like a decent lighter!"
			if (4)
				prize = new /obj/item/toy/sword( prize_location )
			if (5)
				prize = new /obj/item/harmonica( prize_location )
				prize.name = "reverse harmonica"
				prize.desc = "To the untrained eye it is like any other harmonica, but the professional will notice that it is BACKWARDS."
			if (6)
				prize = new /obj/item/wrench( prize_location )
				prize.name = "golden wrench"
				prize.desc = "A generic wrench, but now with gold plating!"
				prize.icon_state = "gold_wrench"
			if (7)
				prize = new /obj/item/firework( prize_location )
				prize.icon = 'icons/obj/device.dmi'
				prize.icon_state = "shield0"
				prize.name = "decloaking device"
				prize.desc = "A device for removing cloaks. Made in Space-Taiwan."
				prize:det_time = 5


/obj/item/peripheral/card_scanner
	name = "ID scanner module"
	desc = "A peripheral board for scanning ID cards."
	icon_state = "card_mod"
	setup_has_badge = 1
	func_tag = "ID_SCANNER"
	var/obj/item/card/id/authid = null
	var/can_manage_access = 0 //Can it change a card's accesses?
	var/can_manage_money = 0 //Can it adjust a card's money balance?

	editor
		name = "ID modifier module"
		desc = "A peripheral board for editing ID cards."
		can_manage_access = 1

	register //A card scanner...that manages money??
		name = "ATM card module"
		desc = "A peripheral board for managing an ID card's credit balance."
		func_tag = "ATM_SCANNER"
		can_manage_money = 1

		return_status_text()
			var/status_text = "No card loaded"
			if (authid)
				status_text = "Balance: [authid.money]"
			return status_text

	return_status_text()
		var/status_text = "No card loaded"
		if (authid)
			status_text = "Card: [authid.registered]"
		return status_text

	return_badge()
		var/dat = "Card: <a href='?src=\ref[src];card=1'>[authid ? "Eject" : "-----"]</a>"
		return dat

	proc/eject_card()
		if (authid)
			authid.set_loc(get_turf(src))

			authid = null
		return

	attack_self(mob/user as mob)
		if (authid)
			boutput(user, "The card falls out.")
			eject_card()

		return

	receive_command(obj/source,command, signal/signal)
		if (..())
			return TRUE

		switch(command)
			if ("eject")
				eject_card()
				return FALSE

			if ("scan_card")
				if (!authid)
					return "nocard"

				if (!authid.registered)
					return "noreg"
				else if (!authid.assignment)
					return "noassign"

				var/signal/newsignal = get_free_signal()
				newsignal.data["registered"] = authid.registered
				newsignal.data["assignment"] = authid.assignment
				newsignal.data["access"] = jointext(authid.access, ";")
				newsignal.data["balance"] = authid.money

				spawn (4)
					send_command("card_authed", newsignal)

				return newsignal

			if ("checkaccess")
				if (!authid)
					return "nocard"
				var/new_access = 0
				if (signal)
					new_access = text2num(signal.data["access"])

				if (!new_access || (new_access in authid.access))
					var/signal/newsignal = get_free_signal()
					newsignal.data["registered"] = authid.registered
					newsignal.data["assignment"] = authid.assignment
					newsignal.data["balance"] = authid.money

					spawn (4)
						send_command("card_authed", newsignal)

					return newsignal

			if ("charge")
				if (!authid || !can_manage_money || !signal)
					return "nocard"
/*
				//We need correct PIN numbers you jerks.
				if (text2num(signal.data["pin"]) != authid.pin)
					spawn (4)
						send_command("card_bad_pin")
					return
*/
				var/charge_amount = text2num(signal.data["data"])
				if (!charge_amount || (charge_amount <= 0) || charge_amount > authid.money)
					spawn (4)
						send_command("card_bad_charge")
					return TRUE

				authid.money = max(authid.money - charge_amount, 0)
				//to-do: new balance reply.
				return "[authid.money]"

			if ("grantaccess")
				if (!authid || !can_manage_access || !signal)
					return "nocard"

				var/new_access = text2num(signal.data["access"])
				if (!new_access || (new_access <= 0))
					return

				if (!(new_access in authid.access))
					authid.access += new_access

					//Send a reply to confirm the granting of this access.
					var/signal/newsignal = get_free_signal()
					newsignal.data["access"] = new_access

					spawn (4)
						send_command("card_add")

					return FALSE

			if ("removeaccess")
				if (!authid || !can_manage_access || !signal)
					return "nocard"

				var/rem_access = text2num(signal.data["access"])
				if (!rem_access || (rem_access <= 0))
					return TRUE

				if (rem_access in authid.access)
					authid.access -= rem_access

					//Send a reply to confirm the granting of this access.
					var/signal/newsignal = get_free_signal()
					newsignal.data["access"] = rem_access

					spawn (4)
						send_command("card_remove")

					return FALSE

			else
				return "Valid commands: eject, scan_card, checkaccess[can_manage_access ? ", grantaccess or removeaccess with signal with access=X" : null]"


		return

	Topic(href, href_list)
		if (..())
			return

		if (istype(usr,/mob/living/silicon) && get_dist(src, usr) > 1)
			boutput(usr, "<span style=\"color:red\">You cannot press the ejection button.</span>")
			return

		if (src.host)
			usr.machine = src.host

		if (href_list["card"])
			if (!isnull(authid))
				eject_card()
			else
				var/obj/item/I = usr.equipped()
				if (istype(I, /obj/item/card/id))
					usr.drop_item()
					I.set_loc(src)
					authid = I

		src.host.updateUsrDialog()
		return

/obj/item/peripheral/sound_card
	name = "Sound synthesizer module"
	desc = "A computer module designed to synthesize voice and sound."
	icon_state = "std_mod"
	func_tag = "LAR_SOUND"

	receive_command(obj/source,command, signal/signal)
		if (..())
			return TRUE

		switch(command)
			if ("beep")
				playsound(src.host.loc, "sound/machines/twobeep.ogg", 50, 1)
				for (var/mob/O in hearers(3, src.host.loc))
					O.show_message(text("[bicon(src.host)] *beep*"))

			if ("speak")
				if (!signal)
					return TRUE

				var/speak_name = signal.data["name"]
				var/speak_data = signal.data["data"]
				if (!speak_data)
					return TRUE
				if (!speak_name)
					speak_name = src.host.name

				for (var/mob/O in hearers(src.host, null))
					O.show_message("<span class='game say'><span class='name'>[speak_name]</span> [bicon(src.host)] beeps, \"[speak_data]\"",2)

			else
				return "Valid commands: beep, speak with signal containing name=X, data=Y"


		return FALSE

/obj/item/peripheral/drive
	name = "Floppy drive module"
	desc = "A peripheral board containing a floppy diskette interface."
	setup_has_badge = 1
	icon_state = "card_mod"
	func_tag = "SHU_FLOPPY"
	var/obj/item/disk/data/disk = null
	var/setup_disk_type = /obj/item/disk/data/floppy //Inserted disks need to be a child type of this.

	disposing()
		disk = null

		..()

	installed(var/obj/machinery/computer3/newhost)
		if (..())
			return TRUE

		if (disk)
			newhost.contents += disk

		return FALSE

	return_badge()
		var/dat = "Disk: <a href='?src=\ref[src];disk=1'>[disk ? "Eject" : "-----"]</a>"
		return dat

	uninstalled()
		if (disk)
			disk.set_loc(src)

		return FALSE

	return_status_text()
		var/status_text = "No disk loaded"
		if (disk)
			status_text = "Disk loaded"
		return status_text

	proc/eject_disk()
		if (disk)
			if (src.host)
				//Let the host programs know the disk is going out.
				for (var/computer/file/terminal_program/P in src.host.processing_programs)
					P.disk_ejected(disk)
				src.disk.set_loc(src.host.loc)
			else
				disk.set_loc(get_turf(src))

			disk = null
		return

	Topic(href, href_list)
		if (..())
			return

		if (istype(usr,/mob/living/silicon) && get_dist(src, usr) > 1)
			boutput(usr, "<span style=\"color:red\">You cannot press the ejection button.</span>")
			return

		if (src.host)
			usr.machine = src.host

		if (href_list["disk"])
			if (!isnull(disk))
				eject_disk()
			else
				var/obj/item/I = usr.equipped()
				if (istype(I, setup_disk_type))
					usr.drop_item()
					if (src.host)
						I.set_loc(src.host)
					else
						I.set_loc(src)
					disk = I

		src.host.updateUsrDialog()
		return

	attack_self(mob/user as mob)
		if (disk)
			boutput(user, "The disk pops out.")
			eject_disk()

		return

/obj/item/peripheral/drive/cart_reader
	name = "ROM cart reader module"
	desc = "A peripheral board for reading ROM carts."
	setup_disk_type = /obj/item/disk/data/cartridge
	func_tag = "SHU_ROM"

	return_badge()
		var/dat = "Cart: <a href='?src=\ref[src];disk=1'>[disk ? "Eject" : "-----"]</a>"
		return dat

	return_status_text()
		var/status_text = "No cart loaded"
		if (disk)
			status_text = "Cart loaded"
		return status_text

	attack_self(mob/user as mob)
		if (disk)
			boutput(user, "The cart pops out.")
			eject_disk()

		return

/obj/item/peripheral/drive/tape_reader
	name = "Tape drive module"
	desc = "A peripheral board designed for reading magnetic data tape."
	setup_disk_type = /obj/item/disk/data/tape
	func_tag = "SHU_TAPE"

	return_badge()
		var/dat = "Tape: <a href='?src=\ref[src];disk=1'>[disk ? "Eject" : "-----"]</a>"
		return dat

	return_status_text()
		var/status_text = "No tape loaded"
		if (disk)
			status_text = "Tape loaded"
		return status_text

	attack_self(mob/user as mob)
		if (disk)
			boutput(user, "The reel pops out.")
			eject_disk()

		return

/obj/item/peripheral/cell_monitor
	name = "cell monitor module"
	desc = "A peripheral board for monitoring charges in power applications."
	icon_state = "elec_mod"
	setup_has_badge = 1
	func_tag = "PWR_MONITOR"

	return_status_text()
		var/obj/machinery/computer3/luggable/checkhost = src.host
		var/status_text = "CELL: No cell!"
		if (istype(checkhost) && checkhost.cell)
			var/obj/item/cell/cell = checkhost.cell
			var/charge_percentage = round((cell.charge/cell.maxcharge)*100)
			status_text = "CELL: [charge_percentage]%"

		return status_text

	return_badge()
		var/obj/machinery/computer3/luggable/checkhost = src.host
		if (!istype(checkhost))
			return null

		var/obj/item/cell/cell = checkhost.cell
		var/readout_color = "#000000"
		var/readout = "NONE"
		if (cell)
			var/charge_percentage = round((cell.charge/cell.maxcharge)*100)
			switch(charge_percentage)
				if (0 to 10)
					readout_color = "#F80000"
				if (11 to 25)
					readout_color = "#FFCC00"
				if (26 to 50)
					readout_color = "#CCFF00"
				if (51 to 75)
					readout_color = "#33CC00"
				if (76 to 100)
					readout_color = "#33FF00"

			readout = charge_percentage

		var/dat = {"Cell: <font color=[readout_color]>[readout]%</font>"}
		return dat


/obj/item/peripheral/videocard
	name = "fancy video card"
	desc = "A G0KU FACTORY-OC eXeter 4950XL. You have no clue what any of that means."
	icon_state = "gpu_mod"
	func_tag = "VGA_ADAPTER"

	throwforce = 10

	installed(var/obj/machinery/computer3/newhost)
		if (..())
			return TRUE

		spawn (rand(50,100))
			if (host)
				for (var/mob/M in hearers(host, null))
					if (M.client)
						M.show_message(text("<span style=\"color:red\">You hear a loud whirring noise coming from the [src.host.name].</span>"), 2)
				// add a sound effect maybe
				sleep(rand(50,100))
				if (host)
					if (prob(50))
						for (var/mob/M in AIviewers(host, null))
							if (M.client)
								M.show_message("<span style=\"color:red\"><strong>The [src.host.name] explodes!</strong></span>", 1)
						var/turf/T = get_turf(src.host.loc)
						if (T)
							T.hotspot_expose(700,125)
							explosion(src, T, -1, -1, 2, 3)
						//dispose()
						dispose()
						return
					for (var/mob/M in AIviewers(host, null))
						if (M.client)
							M.show_message("<span style=\"color:red\"><strong>The [src.host.name] catches on fire!</strong></span>", 1)
						fireflash(src.host.loc, 0)
						playsound(src.host.loc, "sound/items/Welder2.ogg", 50, 1)
						src.host.set_broken()
						//dispose()
						dispose()
						return
		return FALSE