//CONTENTS:
//format_net_id proc (Eventually! Maybe when computer3 is dead?)
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

/*
//Basically just reframing ref
/proc/format_net_id(var/refstring)
	if (!refstring)
		return
	var/id_attempt = copytext(refstring,4,(length(refstring)))
	id_attempt = add_zero(id_attempt, 8)

	return id_attempt

//A little more involved
/proc/generate_net_id(var/atom/da_atom)
	if (!da_atom) return
	var/tag_holder = da_atom.tag
	da_atom.tag = null //So we generate from internal ref id
	var/new_id = format_net_id("\ref[da_atom]")
	da_atom.tag = tag_holder

	return new_id
*/

//TO-DO: Major rewrite in communication method between peripherals and the host system.

/obj/item/peripheralx
	name = "Peripheral card"
	desc = "A computer circuit board."
	icon = 'icons/obj/module.dmi'
	inhand_image_icon = 'icons/mob/inhand/hand_tools.dmi'
	icon_state = "id_mod"
	item_state = "electronic"
	w_class = 2
	var/obj/machinery/computerx/host
	var/id = null
	var/func_tag = "GENERIC" //What kind of peripheral is this, huh??
	var/setup_has_badge = 0 //IF this is set, present return_badge() in the host's browse window
	mats = 8

	New(location)
		..()
		if (istype(location,/obj/machinery/computerx))
			installed(location)
		id = "\ref[src]"

	Del()
		if (host)
			host.peripherals.Remove(src)
		..()


	proc
		receive_command(obj/source, command, computer/file/pfile)
			if ((source != host) || !(src in host) || !command)
				return TRUE

			return FALSE

		send_command(command, computer/file/pfile)
			if (!command || !host)
				return

			if (!istype(host) || (host.stat & (NOPOWER|BROKEN)))
				return

			src.host.receive_command(src, command, pfile)

			return

		return_status_text()
			return "OK"

		installed(var/obj/machinery/computerx/newhost)
			if (!newhost)
				return TRUE

			if (newhost != src.host)
				src.host = newhost

			if (!(src in src.host.peripherals))
				src.host.peripherals.Add(src)

			return FALSE

		uninstalled() //Called when removed from computerxframe/computerx is taken apart
			return FALSE

		//If setup_has_badge is set, the text returned here will be available in the computerx browse window
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


/obj/item/peripheralx/network
	var/code = null //Signal encryption code
	var/net_id = null //What is our ID on the network?
	var/last_ping = 0

/obj/item/peripheralx/network/radio
	name = "wireless card"
	desc = "A wireless computer card. It has a bit of a limited range."
	icon_state = "power_mod"
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

	proc
		set_frequency(new_frequency)
			radio_controller.remove_object(src, "[frequency]")
			frequency = new_frequency
			radio_connection = radio_controller.add_object(src, "[frequency]")


	receive_command(obj/source, command, computer/file/signal/sfile)
		if (..())
			return

		if (!istype(sfile) || !radio_connection)
			return

		var/broadcast_range = range //No range in network mode!!
		if (setup_netmode_norange && net_mode)
			broadcast_range = 0

		switch(command)
			if ("transmit")
				var/signal/newsignal = get_free_signal()
				newsignal.data = sfile.data:Copy()
				if (sfile.data_file) //Gonna transfer so many files.
					newsignal.data_file = sfile.data_file.copy_file()
				newsignal.encryption = code
				newsignal.transmission_method = TRANSMISSION_RADIO
				if (net_mode)
					if (!newsignal.data["address_1"])
						//Net_mode demands an address_1 value!
						qdel(newsignal)
						return

					newsignal.data["sender"] = net_id

				radio_connection.post_signal(src, newsignal, broadcast_range)

				//src.logstring += "T@[src.frequency]:[src.code];"

			if ("mode_net")
				net_mode = 1
				func_tag = "NET_ADAPTER" //Pretend to be that fukken wired card.

			if ("mode_free")
				net_mode = 0
				func_tag = "RAD_ADAPTER"

			if ("ping") //Just a shortcut for pinging the system, really.
				if (!net_mode)
					return

				if ( (last_ping && ((last_ping + 10) >= world.time) ) || !net_id)
					return

				last_ping = world.time
				var/signal/newsignal = get_free_signal()
				newsignal.data["address_1"] = "ping"
				newsignal.data["sender"] = net_id
				newsignal.transmission_method = TRANSMISSION_RADIO
				radio_connection.post_signal(src, newsignal, broadcast_range)

			else
				if (!setup_freq_locked)
					var/new_freq = round(text2num(command))
					if (new_freq && (new_freq >= 1000 && new_freq <= 1500))
						set_frequency(new_freq)

		return

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

				return //Just toss out the rest of the signal then I guess

		var/computer/file/signal/sfile = new
		sfile.data = signal.data:Copy()
		//if (code)
			//newsignal.encryption = code
		if (signal.data_file)
			sfile.data_file = signal.data_file.copy_file()

		send_command("receive",sfile)
		return


	return_status_text()
		var/status = "FREQ: [frequency]"
		if (net_mode)
			//We are in powernet card emulation mode.
			status += " | NETID: [net_id ? net_id : "NONE"]"
		else //We are in free radio mode.
			status += " | RANGE: [range ? "[range]" : "FULL"]"
		return status

/obj/item/peripheralx/network/powernet_card
	name = "wired network card"
	desc = "A computer networking card designed to transmit information over power lines."
	icon_state = "power_mod"
	func_tag = "NET_ADAPTER"
	var/obj/machinery/power/data_terminal/link = null //For communicating with the powernet.

	New()
		..()
		spawn (10)
			if (src.host && !src.link) //Wait for the map to load and hook up if installed() hasn't done it.
				check_connection()
			//Let's blindy attempt to generate a unique network ID!
			net_id = format_net_id("\ref[src]")



	installed(var/obj/machinery/computerx/newhost)
		if (..())
			return TRUE

		link = null
		check_connection()

		return FALSE

	uninstalled()
		//Clear our status as the link's master, then null out that link.

		if ((link) && (link.master == src))
			link.master = null

		link = null
		return FALSE

	receive_command(obj/source, command, computer/file/signal/signal)
		if (..())
			return

		if (!check_connection())
			return

		switch(command)
			if ("transmit") //Transmit a copy of the command signal
				if (!istype(signal))
					return

				var/signal/newsignal = get_free_signal()
				newsignal.data = signal.data:Copy()

				if (signal.data_file) //Gonna transfer so many files.
					newsignal.data_file = signal.data_file.copy_file()

				newsignal.data["sender"] = net_id //Override whatever jerk info they put here.
				newsignal.encryption = code
				newsignal.transmission_method = TRANSMISSION_WIRE
				link.post_signal(src, newsignal)

			if ("ping") //Just a shortcut for pinging the system, really.
				if ( (last_ping && ((last_ping + 10) >= world.time) ) || !net_id)
					return

				last_ping = world.time
				var/signal/newsignal = get_free_signal()
				newsignal.data["address_1"] = "ping"
				newsignal.data["sender"] = net_id
				newsignal.transmission_method = TRANSMISSION_WIRE
				link.post_signal(src, newsignal)

		return

	receive_signal(signal/signal)
		if (!src.host || host.stat & (NOPOWER|BROKEN))
			return
		if (!signal || !net_id || (signal.encryption && signal.encryption != code))
			return

		if (signal.transmission_method != TRANSMISSION_WIRE) //No radio for us thanks
			return

		if (!link || !check_connection())
			return

		//They don't need to target us specifically to ping us.
		//Otherwise, ff they aren't addressing us, ignore them
		if (signal.data["address_1"] != net_id)
			if ((signal.data["address_1"] == "ping") && signal.data["sender"])
				var/signal/pingsignal = get_free_signal()
				pingsignal.data["device"] = "PNET_ADAPTER"
				pingsignal.data["netid"] = net_id
				pingsignal.data["address_1"] = signal.data["sender"]
				pingsignal.data["command"] = "ping_reply"
				pingsignal.transmission_method = TRANSMISSION_WIRE
				spawn (5) //Send a reply for those curious jerks
					link.post_signal(src, pingsignal)

			return //Just toss out the rest of the signal then I guess

		var/computer/file/signal/newsignal = get_free_signal()
		newsignal.data = signal.data:Copy()

		if (signal.data_file) //Transfer all of the files.  Every file in the world.
			newsignal.data_file = signal.data_file.copy_file()

		send_command("receive",newsignal)
		return


	return_status_text()
		var/status = "LINK: [link ? "ACTIVE" : "!NONE!"]"
		status += " | NETID: [net_id ? net_id : "NONE"]"
		return status

	proc
		check_connection()
			//if there is a link, it has a master, and the master is valid..
			if (link && istype(link) && (link.master) && link.is_valid_master(link.master))
				if (link.master == src)
					return TRUE //If it's already us, the connection is fine!
				else//Otherwise welp no this thing is taken.
					link = null
					return FALSE
			link = null
			var/turf/T = get_turf(src)
			var/obj/machinery/power/data_terminal/test_link = locate() in T
			if (test_link && !test_link.is_valid_master(test_link.master))
				link = test_link
				link.master = src
				return TRUE
			else
				return FALSE

			return FALSE

/obj/item/peripheralx/network/powernet_card/terminal
	name = "Terminal card"
	desc = "A networking/printing combo card designed to fit into a computer casing."
	icon_state = "card_mod"
	var/printing = 0

	receive_command(obj/source, command, computer/file/pfile)
		if ((source != host) || !(src in host))
			return

		if (!command)// || (signal && signal.encryption && signal.encryption != id))
			return

		if (!check_connection())
			return

		switch(command)
			if ("transmit") //Transmit a copy of the command signal
				var/computer/file/signal/signal = pfile
				if (!istype(signal))
					return

				var/signal/newsignal = get_free_signal()
				newsignal.data = signal.data:Copy()

				if (signal.data_file) //Gonna transfer so many files.
					newsignal.data_file = signal.data_file.copy_file()

				newsignal.data["sender"] = net_id //Override whatever jerk info they put here.
				newsignal.encryption = code
				newsignal.transmission_method = TRANSMISSION_WIRE
				link.post_signal(src, newsignal)

			if ("ping") //Just a shortcut for pinging the system, really.
				if ( (last_ping && ((last_ping + 10) >= world.time) ) || !net_id)
					return

				last_ping = world.time
				var/signal/newsignal = get_free_signal()
				newsignal.data["address_1"] = "ping"
				newsignal.data["sender"] = net_id
				newsignal.transmission_method = TRANSMISSION_WIRE
				link.post_signal(src, newsignal)

			if ("print")
				var/computer/file/text/txtfile = pfile
				if (!istype(txtfile) || printing)
					return
				printing = 1

				var/print_data = txtfile.data
				var/print_title = txtfile.name
				if (!print_data)
					printing = 0
					return
				spawn (50)
					var/obj/item/paper/P = new /obj/item/paper( src.host.loc )
					P.info = print_data
					if (print_title)
						P.name = "paper- '[print_title]'"

					printing = 0
					return

		return

/obj/item/peripheralx/printer
	name = "Printer module"
	desc = "A small printer designed to fit into a computer casing."
	icon_state = "card_mod"
	func_tag = "LAR_PRINTER"
	var/printing = 0

	receive_command(obj/source,command, computer/file/text/txtfile)
		if (..())
			return

		if ((command == "print") && istype(txtfile) && !printing)
			printing = 1

			var/print_data = txtfile.data
			var/print_title = txtfile.name
			if (!print_data)
				printing = 0
				return
			spawn (50)
				var/obj/item/paper/P = new /obj/item/paper( src.host.loc )
				P.info = print_data
				if (print_title)
					P.name = "paper- '[print_title]'"

				printing = 0
				return

		return

	return_status_text()
		var/status = "PRINTING?: [printing ? "YES" : "NO"]"

		return status


/obj/item/peripheralx/prize_vendor
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

	receive_command(obj/source,command, computer/file/pfile)
		if (..())
			return

		if ((command == "vend") && ((last_vend + 400) < world.time))
			vend_prize()
			last_vend = world.time

		return

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


/obj/item/peripheralx/card_scanner
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
			if (src.host)
				src.authid.set_loc(src.host.loc)
			else
				authid.set_loc(get_turf(src))

			authid = null
		return

	attack_self(mob/user as mob)
		if (authid)
			boutput(user, "The card falls out.")
			eject_card()

		return

	receive_command(obj/source,command, computer/file/record/rec)
		if (..())
			return

		switch(command)
			if ("eject")
				eject_card()

			if ("scan_card")
				if (!authid)
					return "nocard"

				var/computer/file/record/newrec = new
				newrec.fields["registered"] = authid.registered
				newrec.fields["assignment"] = authid.assignment
				newrec.fields["access"] = jointext(authid.access, ";")
				newrec.fields["balance"] = authid.money

				spawn (4)
					send_command("card_authed", newrec)

				return newrec

			if ("checkaccess")
				if (!authid)
					return "nocard"
				var/new_access = 0
				if (istype(rec))
					new_access = text2num(rec.fields["access"])

				if (!new_access || (new_access in authid.access))
					var/computer/file/record/newrec = new
					newrec.fields["registered"] = authid.registered
					newrec.fields["assignment"] = authid.assignment
					newrec.fields["balance"] = authid.money
					spawn (4)
						send_command("card_authed", newrec)

					return newrec

			if ("charge")
				if (!authid || !can_manage_money || !istype(rec))
					return "nocard"

				//We need correct PIN numbers you jerks.
				if (text2num(rec.fields["pin"]) != authid.pin)
					spawn (4)
						send_command("card_bad_pin")
					return

				var/charge_amount = text2num(rec.fields["amount"])
				if (!charge_amount || (charge_amount <= 0) || charge_amount > authid.money)
					spawn (4)
						send_command("card_bad_charge")
					return

				authid.money = max(authid.money - charge_amount, 0)
				//to-do: new balance reply.
				return

			if ("grantaccess")
				if (!authid || !can_manage_access || !istype(rec))
					return "nocard"

				var/new_access = text2num(rec.fields["access"])
				if (!new_access || (new_access <= 0))
					return

				if (!(new_access in authid.access))
					authid.access += new_access
/*
					//Send a reply to confirm the granting of this access.
					var/signal/newrec = new
					newrec.fields["access"] = new_access
*/
					spawn (4)
						send_command("card_add")

					return

			if ("removeaccess")
				if (!authid || !can_manage_access || !istype(rec))
					return "nocard"

				var/rem_access = text2num(rec.fields["access"])
				if (!rem_access || (rem_access <= 0))
					return

				if (rem_access in authid.access)
					authid.access -= rem_access
/*
					//Send a reply to confirm the granting of this access.
					var/signal/newrec = new
					newrec.fields["access"] = rem_access
*/
					spawn (4)
						send_command("card_remove")

					return


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

/obj/item/peripheralx/sound_card
	name = "Sound synthesizer module"
	desc = "A computer module designed to synthesize voice and sound."
	icon_state = "std_mod"
	func_tag = "LAR_SOUND"

	receive_command(obj/source,command, computer/file/record/rec)
		if (..())
			return

		switch(command)
			if ("beep")
				playsound(src.host.loc, "sound/machines/twobeep.ogg", 50, 1)
				for (var/mob/O in hearers(3, src.host.loc))
					O.show_message(text("[bicon(src.host)] *beep*"))

			if ("speak")
				if (!istype(rec))
					return

				var/speak_name = rec.fields["name"]
				var/speak_data = rec.fields["data"]
				if (!speak_data)
					return
				if (!speak_name)
					speak_name = src.host.name

				for (var/mob/O in hearers(src.host, null))
					O.show_message("<span class='game say'><span class='name'>[speak_name]</span> [bicon(src.host)] beeps, \"[speak_data]\"",2)


		return

/obj/item/peripheralx/drive
	name = "Floppy drive module"
	desc = "A peripheral board containing a floppy diskette interface."
	setup_has_badge = 1
	icon_state = "card_mod"
	func_tag = "SHU_FLOPPY"
	var/label = "fd"
	var/obj/item/disk/data/disk = null
	var/setup_disk_type = /obj/item/disk/data/floppy //Inserted disks need to be a child type of this.

	return_badge()
		var/dat = "Disk: <a href='?src=\ref[src];disk=1'>[disk ? "Eject" : "-----"]</a>"
		return dat

	return_status_text()
		var/status_text = "No disk loaded"
		if (disk)
			status_text = "Disk loaded"
		return status_text

	installed(var/obj/machinery/computerx/newhost)
		if (..())
			return TRUE

		label = initial(label)

		var/count = 0
		for (var/obj/item/peripheralx/drive/D in newhost.peripherals)
			if (D == src)
				continue

			if (initial(D.label) == label)
				count++

		label = "[label][count]"

		if (disk)
			for (var/computer/file/terminalx_program/P in src.host.processing_programs)
				P.disk_inserted(disk)

		return FALSE

	proc/eject_disk()
		if (src.host && src.host.restarting)
			return
		if (disk)
			var/obj/ejected = disk
			disk = null //We need to clear disk before letting the OS know or things get screwy OK
			if (src.host)
				//Let the host programs know the disk is going out.
				for (var/computer/file/terminalx_program/P in src.host.processing_programs)
					P.disk_ejected(ejected)
				ejected.set_loc(src.host.loc)
			else
				ejected.set_loc(get_turf(src))

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
					I.set_loc(src)
					disk = I
					//Let the host programs know the disk is coming in.
					for (var/computer/file/terminalx_program/P in src.host.processing_programs)
						P.disk_inserted(I)

		src.host.updateUsrDialog()
		return

	attack_self(mob/user as mob)
		if (disk)
			boutput(user, "The disk pops out.")
			eject_disk()

		return

/obj/item/peripheralx/drive/cart_reader
	name = "ROM cart reader module"
	desc = "A peripheral board for reading ROM carts."
	setup_disk_type = /obj/item/disk/data/cartridge
	func_tag = "SHU_ROM"
	label = "sr"

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

/obj/item/peripheralx/drive/tape_reader
	name = "Tape drive module"
	desc = "A peripheral board designed for reading magnetic data tape."
	setup_disk_type = /obj/item/disk/data/tape
	func_tag = "SHU_TAPE"
	label = "st"

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

/obj/item/peripheralx/electrical
	name = "Electrical scanner interface"
	desc = "A sophisticated peripheral board for interfacing with an electrical scanner."
	icon_state = "elec_mod"
	func_tag = "ELEC_ADAPTER"
	var/obj/item/electronics/scanner/scanner = null

	return_status_text()
		var/status_text = "UNLOADED"
		if (scanner)
			status_text = "LOADED"
		return status_text

	return_badge()
		var/dat = "Scan: <a href='?src=\ref[src];scanner=1'>[scanner ? "Eject" : "-----"]</a>"
		return dat

	Topic(href, href_list)
		if (..())
			return

		if (istype(usr,/mob/living/silicon) && get_dist(src, usr) > 1)
			boutput(usr, "<span style=\"color:red\">You cannot press the ejection button.</span>")
			return

		if (src.host)
			usr.machine = src.host

		if (href_list["scanner"])
			if (!isnull(scanner))
				eject_scanner()
			else
				var/obj/item/I = usr.equipped()
				if (istype(I, /obj/item/electronics/scanner))
					usr.drop_item()
					if (src.host)
						I.set_loc(src.host)
					else
						I.set_loc(src)
					scanner = I

		src.host.updateUsrDialog()
		return

	attack_self(mob/user as mob)
		if (scanner)
			boutput(user, "The scanner pops out.")
			eject_scanner()

		return

	proc/eject_scanner()
		if (scanner)
			scanner.set_loc(get_turf(src))
			scanner = null

		return
/*
/obj/item/peripheralx/cell_monitor
	name = "cell monitor module"
	desc = "A peripheral board for monitoring charges in power applications."
	icon_state = "elec_mod"
	setup_has_badge = 1
	func_tag = "PWR_MONITOR"

	return_status_text()
		var/obj/machinery/computerx/luggable/checkhost = src.host
		var/status_text = "CELL: No cell!"
		if (istype(checkhost) && checkhost.cell)
			var/obj/item/cell/cell = checkhost.cell
			var/charge_percentage = round((cell.charge/cell.maxcharge)*100)
			status_text = "CELL: [charge_percentage]%"

		return status_text

	return_badge()
		var/obj/machinery/computerx/luggable/checkhost = src.host
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
*/
//Putting this here for the moment, a bit wary about arbitrary DNA modification.
//I guess they wouldn't be able to make a working signal but WHAT IF MAN
/*
/proc/ishex(hex)

	if (!( istext(hex) ))
		return FALSE
	hex = lowertext(hex)
	var/list/hex_list = list("0","1","2","3","4","5","6","7","8","9","a","b","c","d","e","f")
	var/i = null
	i = length(hex)
	while (i > 0)
		var/char = copytext(hex, i, i + 1)
		if (!(char in hex_list))
			return FALSE
		i--
	return TRUE
*/
/obj/item/peripheralx/videocard
	name = "fancy video card"
	desc = "A G0KU FACTORY-OC eXeter 4950XL. You have no clue what any of that means."
	icon_state = "gpu_mod"
	func_tag = "VGA_ADAPTER"

	throwforce = 10

	installed(var/obj/machinery/computerx/newhost)
		if (..())
			return TRUE

		spawn (rand(50,100))
			if (host)
				for (var/mob/M in viewers(host, null))
					if (M.client)
						M.show_message(text("<span style=\"color:red\">You hear a loud whirring noise coming from the [src.host.name].</span>"), 2)
				// add a sound effect maybe
				sleep(rand(50,100))
				if (host)
					if (prob(50))
						for (var/mob/M in viewers(host, null))
							if (M.client)
								M.show_message(text("<span style=\"color:red\"><strong>The [src.host.name] explodes!</strong></span>"), 1)
						var/turf/T = get_turf(src.host.loc)
						if (T)
							T.hotspot_expose(700,125)
							explosion(src, T, -1, -1, 2, 3)
						qdel(src)
						return
					for (var/mob/M in viewers(host, null))
						if (M.client)
							M.show_message(text("<span style=\"color:red\"><strong>The [src.host.name] catches on fire!</strong></span>"), 1)
						fireflash(src.host.loc, 0)
						playsound(src.host.loc, "sound/items/Welder2.ogg", 50, 1)
						src.host.set_broken()
						qdel(src)
						return
		return FALSE