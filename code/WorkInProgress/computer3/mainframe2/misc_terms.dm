//Miscellaneous Terminal Devices
//CONTENTS:
// Basic pnet machine
// HIGH-TECH tape storage
// A bomb simulator.  Test bombs in VR!
// Outpost self-destruct !nuke!
// A wirenet -> wireless link thing.
// A printer! All the fun of printing, now in SS13!
// Pathogen manipulator TO-DO
// Security system monitor
// A dangerous teleportation-oriented testing apparatus.
// Generic testing appartus

/obj/machinery/networked
	anchored = 1
	density = 1
	icon = 'icons/obj/networked.dmi'
	var/net_id = null
	var/host_id = null //Who are we connected to? (If we have a single host)
	var/old_host_id = null //Were we previously connected to someone?  Do we care?
	var/obj/machinery/power/data_terminal/data_link = null
	var/device_tag = "PNET_GENERICDV"
	var/timeout = 40 //The time until we auto disconnect (if we don't get a refresh ping)
	var/timeout_alert = 0 //Have we sent a timeout refresh alert?

	var/last_reset = 0 //Last world.time we were manually reset.
	var/net_number = 0 //A cute little bitfield (0-3 exposed) to allow multiple networks on one wirenet.  Differentiate between intended hosts, if they care.
	var/panel_open = 0

	proc/post_status(var/target_id, var/key, var/value, var/key2, var/value2, var/key3, var/value3, var/key4, var/value4)
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
		if (key4)
			signal.data[key4] = value4

		signal.data["address_1"] = target_id
		signal.data["sender"] = net_id

		data_link.post_signal(src, signal)

	proc/post_file(var/target_id, var/key, var/value, var/file)
		if (!data_link || !target_id)
			return

		var/signal/signal = get_free_signal()
		signal.source = src
		signal.transmission_method = TRANSMISSION_WIRE
		signal.data[key] = value
		if (file)
			var/computer/file/F = file
			signal.data_file = F.copy_file()

		signal.data["address_1"] = target_id
		signal.data["command"] = "term_file"
		signal.data["sender"] = net_id

		data_link.post_signal(src, signal)

	proc/net_switch_html()
		. = "<br>Configuration Switches:<br><table border='1' style='background-color:#7A7A7A'><tr>"
		for (var/i = 8, i >= 1, i >>= 1)
			var/styleColor = (net_number & i) ? "#60B54A" : "#CD1818"
			. += "<td style='background-color:[styleColor]'><a href='?src=\ref[src];dipsw=[i]' style='color:[styleColor]'>##</a></td>"

		. += "</tr></table>"

	Topic(href, href_list)
		if (..())
			return TRUE

		if (href_list["dipsw"] && panel_open && get_dist(usr, src) < 2)
			var/switchNum = text2num(href_list["dipsw"])
			if (switchNum < 1 || switchNum > 8)
				return TRUE

			switchNum = round(switchNum)
			if (net_number & switchNum)
				net_number &= ~switchNum
			else
				net_number |= switchNum

			updateUsrDialog()
			return TRUE

		return FALSE

	disposing()
		if (data_link)
			data_link.master = null
			data_link = null

		..()

/obj/machinery/networked/storage
	name = "Databank"
	desc = "A networked data storage device."
	anchored = 1
	density = 1
	icon_state = "tapedrive0"
	device_tag = "PNET_DATA_BANK"
	mats = 12
	var/base_icon_state = "tapedrive"
	var/bank_id = null //Unique Identifier for this databank.
	var/locked = 1
	var/read_only = 0 //Read only, even if the disk isn't!
	var/obj/item/disk/data/tape = null
	var/setup_drive_size = 128
	var/setup_tape_tag = "tape"
	var/setup_tape_type = /obj/item/disk/data/tape //Parent type that can be used as disk.
	var/setup_drive_type = /obj/item/disk/data/tape //Use this path for the tape
	var/setup_spawn_with_tape = 1 //Spawn with tape in the drive.
	var/setup_access_click = 0 //Play tape drive noise when accessed.
	var/setup_allow_boot = 0 //We respond to bootreq requests.
	var/setup_accept_tapes = 1
	power_usage = 200

	tape_drive
		name = "Databank"
		desc = "A networked tape drive."
		icon_state = "tapedrive0"
		base_icon_state = "tapedrive"
		setup_access_click = 1
		setup_tape_tag = "tape"
		setup_tape_type = /obj/item/disk/data/tape
		setup_allow_boot = 1

	clone()
		var/obj/machinery/networked/storage/clonestore = ..()
		if (!clonestore)
			return

		clonestore.locked = locked
		clonestore.base_icon_state = base_icon_state
		clonestore.device_tag = device_tag
		clonestore.read_only = read_only
		clonestore.setup_access_click = setup_access_click
		clonestore.setup_allow_boot = setup_allow_boot
		clonestore.setup_tape_type = setup_tape_type
		clonestore.setup_drive_type = setup_drive_type
		clonestore.bank_id = bank_id
		if (tape)
			clonestore.tape = src.tape.clone()

		return clonestore

	New()
		..()
		if (!bank_id)
			bank_id = "GENERIC"

		net_id = generate_net_id(src)

		spawn (5)

			if (!data_link)
				var/turf/T = get_turf(src)
				var/obj/machinery/power/data_terminal/test_link = locate() in T
				if (test_link && !test_link.is_valid_master(test_link.master))
					data_link = test_link
					data_link.master = src

			if (!tape && (setup_drive_size > 0) && setup_spawn_with_tape)
				if (setup_drive_type)
					if (istext(setup_drive_type))
						setup_drive_type = text2path(setup_drive_type)

					tape = new setup_drive_type (src)
					tape.set_loc(src)

				tape.file_amount = max(setup_drive_size, tape.file_amount)

			power_change() //Update the icon

	disposing()
		if (tape)
			tape.dispose()
			tape = null

		..()

	process()
		if (stat & BROKEN)
			return
		..()
		if (stat & NOPOWER)
			return
		use_power(200)

		if (!host_id || !data_link)
			return

		if (timeout == 0)
			post_status(host_id, "command","term_disconnect","data","timeout")
			src.host_id = null
			updateUsrDialog()
			timeout = initial(timeout)
			timeout_alert = 0
		else
			timeout--
			if (timeout <= 5 && !timeout_alert)
				timeout_alert = 1
				src.post_status(src.host_id, "command","term_ping","data","reply")

		return

	attack_hand(mob/user as mob)
		if (..() && !(stat & NOPOWER)) //Allow them to remove tapes even if the power's out.
			return

		user.machine = src

		var/dat = "<html><head><title>Databank - \[[bank_id]]</title></head><body>"

		dat += "<strong>[capitalize(setup_tape_tag)]:</strong> <a href='?src=\ref[src];tape=1'>[tape ? "Eject" : "--------"]</a><hr>"

		if (stat & NOPOWER)
			user << browse(dat,"window=databank;size=245x302")
			onclose(user,"databank")
			return

		var/readout_color = "#000000"
		var/readout = "ERROR"
		if (src.host_id)
			readout_color = "#33FF00"
			readout = "OK CONNECTION"
		else
			readout_color = "#F80000"
			readout = "NO CONNECTION"

		dat += "Host Connection: "
		dat += "<table border='1' style='background-color:[readout_color]'><tr><td><font color=white>[readout]</font></td></tr></table><br>"

		dat += "<a href='?src=\ref[src];reset=1'>Reset Connection</a><br>"

		dat += "<br>Read Only: "
		if (!read_only)
			dat += "<a href='?src=\ref[src];read=1'>YES</a> <strong>NO</strong><br>"
		else
			dat += "<strong>YES</strong> <a href='?src=\ref[src];read=1'>NO</a><br>"

		if (panel_open)
			dat += net_switch_html()

		user << browse(dat,"window=databank;size=245x302")
		onclose(user,"databank")
		return

	Topic(href, href_list)
		if (..() && !(href_list["tape"] && (stat&NOPOWER)))
			return

		usr.machine = src

		if (href_list["tape"])
			if (locked)
				boutput(usr, "<span style=\"color:red\">The cover is screwed shut.</span>")
				return

			//Ai/cyborgs cannot physically remove a tape from a room away.
			if (istype(usr,/mob/living/silicon) && get_dist(src, usr) > 1)
				boutput(usr, "<span style=\"color:red\">You cannot press the ejection button.</span>")
				return

			if (tape)
				tape.set_loc(loc)
				tape = null
				boutput(usr, "You remove the [setup_tape_tag] from the drive.")
				power_change()
				if (src.host_id && !(stat & (NOPOWER|BROKEN)))
					src.post_status(src.host_id,"command","term_message","data","command=status&status=notape")

			else
				var/obj/item/I = usr.equipped()
				if (istype(I, setup_tape_type))
					usr.drop_item()
					I.set_loc(src)
					tape = I
					boutput(usr, "You insert [I].")

					src.sync(src.host_id)

				power_change()

			updateUsrDialog()
			return

		else if (href_list["reset"])
			if (last_reset && (last_reset + NETWORK_MACHINE_RESET_DELAY >= world.time))
				return

			if (!host_id && !old_host_id)
				return

			last_reset = world.time
			var/rem_host = src.host_id ? src.host_id : src.old_host_id
			src.host_id = null
			old_host_id = null
			post_status(rem_host, "command","term_disconnect")
			spawn (5)
				post_status(rem_host, "command","term_connect","device",device_tag)

			updateUsrDialog()
			return

		else if (href_list["read"])
			read_only = !read_only

			updateUsrDialog()
			return

		add_fingerprint(usr)
		return

	attackby(obj/item/W as obj, mob/user as mob)
		if (istype(W, setup_tape_type) && setup_accept_tapes) //INSERT SOME TAPES
			if (tape)
				boutput(user, "<span style=\"color:red\">There is already a [setup_tape_tag] in the drive.</span>")
				return
			if (locked)
				boutput(user, "<span style=\"color:red\">The cover is screwed shut.</span>")
				return
			user.drop_item()
			W.set_loc(src)
			tape = W
			boutput(user, "You insert [W].")
			power_change()
			updateUsrDialog()
			src.sync(src.host_id)
			return

		else if (istype(W, /obj/item/screwdriver))
			playsound(loc, "sound/items/Screwdriver.ogg", 50, 1)
			locked = !locked
			panel_open = !locked
			boutput(user, "You [locked ? "secure" : "unscrew"] the cover.")
			updateUsrDialog()
			return

		else
			..()

		return

	receive_signal(signal/signal)
		if (stat & (NOPOWER) || !data_link)
			return
		if (!signal || !net_id || signal.encryption)
			return

		if (signal.transmission_method != TRANSMISSION_WIRE) //This is a wired device only.
			return

		var/target = signal.data["sender"]

		//They don't need to target us specifically to ping us.
		//Otherwise, if they aren't addressing us, ignore them
		if (signal.data["address_1"] != net_id)
			if ((signal.data["address_1"] == "ping") && ((signal.data["net"] == null) || ("[signal.data["net"]]" == "[net_number]")) && signal.data["sender"])
				spawn (5) //Send a reply for those curious jerks
					post_status(target, "command", "ping_reply", "device", device_tag, "netid", net_id, "net", "[net_number]")

			return

		var/sigcommand = lowertext(signal.data["command"])
		if (!sigcommand || !signal.data["sender"])
			return

		switch(sigcommand)
			if ("term_connect") //Terminal interface stuff.
				if (target == src.host_id)
					//WHAT IS THIS, HOW COULD THIS HAPPEN??
					src.host_id = null
					updateUsrDialog()
					spawn (3)
						post_status(target, "command","term_disconnect")
					return

				if (src.host_id)
					return

				timeout = initial(timeout)
				timeout_alert = 0
				src.host_id = target
				old_host_id = target
				if (signal.data["data"] != "noreply")
					post_status(target, "command","term_connect","data","noreply","device",device_tag)
				updateUsrDialog()
				spawn (2) //Sign up with the driver (if a mainframe contacted us)
					post_status(target,"command","term_message","data","command=register&data=[bank_id]")
				return

			if ("term_message","term_file")
				if (target != src.host_id) //Huh, who is this?
					return

				var/list/data = params2list(signal.data["data"])
				if (!data)
					return

				var/sessionid = data["session"]
				if (!sessionid)
					sessionid = 0

				if (setup_access_click)
					playsound(loc, "sound/machines/driveclick.ogg", 25, 0, -2)
				switch(data["command"])
					if ("sync")
						if (!tape)
							post_status(target,"command","term_message","data","command=status&status=notape&session=[sessionid]")
							return

						sync(target)
						return
					if ("catalog") //List file directory/tape information
						if (!tape)
							post_status(target,"command","term_message","data","command=status&status=notape&session=[sessionid]")
							return
						var/computer/file/record/catrec = new
						catrec.fields["/header"] = "name=[tape.title]&used=[tape.file_used]&size=[tape.file_amount]"
						if (!tape.root.contents.len)
							catrec.fields["NOFILE"] = "NOFILES"
						else
							for (var/computer/file/F in tape.root.contents)
								catrec.fields[F.name] = "[F.extension] - [F.size]"

						spawn (2)
							post_file(target, "data","command=catalog",catrec)
							//qdel(catrec) //A copy is sent, the original is no longer needed.
							if (catrec)
								catrec.dispose()
						return
					if ("filereq") //Send a file from tape if available.
						if (!tape)
							post_status(target,"command","term_message","data","command=status&status=notape&session=[sessionid]")
							return
						if (isnull(data["fname"]))
							post_status(target,"command","term_message","data","command=status&status=noparam&session=[sessionid]")
							return

						var/checkname = data["fname"]
						var/computer/file/sought = get_file_name(checkname, tape.root)
						if (istype(sought))
							post_file(target, "data","command=file",sought)
						else
							post_status(target,"command","term_message","data","command=status&status=nofile&session=[sessionid]")
						return
					if ("filestore") //Store a file on tape.
						if (!tape)
							post_status(target,"command","term_message","data","command=status&status=notape&session=[sessionid]")
							return

						if (tape.read_only || read_only)
							post_status(target,"command","term_message","data","command=status&status=readonly&session=[sessionid]")
							return

						var/computer/file/newfile = signal.data_file
						if (!istype(newfile))
							post_status(target,"command","term_message","data","command=status&status=badfile&session=[sessionid]")
							return

						if (findtext(newfile.name, "/"))
							post_status(target,"command","term_message","data","command=status&status=badname&session=[sessionid]")
							return

						var/computer/taken = get_file_name(newfile.name, tape.root)
						if (taken)
							if (istype(taken, newfile.type))
								taken.dispose()
								taken = null
							else
								post_status(target,"command","term_message","data","command=status&status=takenfile&session=[sessionid]")
								return

						var/computer/file/F2 = newfile.copy_file()
						if (tape.root.add_file(F2) != 1)
							//qdel(F2)
							F2.dispose()
							F2 = null
							post_status(target,"command","term_message","data","command=status&status=noroom&session=[sessionid]")
							return

						post_status(target,"command","term_message","data","command=status&status=success&session=[sessionid]")

						return

					if ("delfile")
						if (!tape)
							post_status(target,"command","term_message","data","command=status&status=notape&session=[sessionid]")
							return
						if (tape.read_only || read_only)
							post_status(target,"command","term_message","data","command=status&status=readonly&session=[sessionid]")
							return
						if (isnull(data["fname"]))
							post_status(target,"command","term_message","data","command=status&status=noparam&session=[sessionid]")
							return

						var/checkname = data["fname"]
						var/computer/file/sought = get_file_name(checkname, tape.root)

						if (istype(sought))
							//qdel(sought)
							sought.dispose()
							post_status(target,"command","term_message","data","command=status&status=success&session=[sessionid]")
							return

						post_status(target,"command","term_message","data","command=status&status=nofile&session=[sessionid]")
						return
					if ("modfile")
						if (!tape)
							post_status(target,"command","term_message","data","command=status&status=notape&session=[sessionid]")
							return
						if (tape.read_only || read_only)
							post_status(target,"command","term_message","data","command=status&status=readonly&session=[sessionid]")
							return
						if (isnull(data["fname"]) || isnull(data["field"]))
							post_status(target,"command","term_message","data","command=status&status=noparam&session=[sessionid]")
							return

						var/checkname = data["fname"]
						var/computer/file/sought = get_file_name(checkname, tape.root)

						if (istype(sought))
							var/newval = data["val"]
							if (isnum(text2num(newval)))
								newval = text2num(newval)
							sought.metadata[data["field"]] = newval
							post_status(target,"command","term_message","data","command=status&status=success&session=[sessionid]")
							return

						post_status(target,"command","term_message","data","command=status&status=nofile&session=[sessionid]")
						return
					if ("bootreq") //Special request for a mainframe OS file + any drivers on tape.
						if (!tape || !setup_allow_boot)
							post_status(target,"command","term_message","data","command=status&status=notape&session=[sessionid]")
							return

						var/computer/file/mainframe_program/os/foundos = locate() in tape.root.contents
						if (!istype(foundos))
							post_status(target,"command","term_message","data","command=status&status=nofile&session=[sessionid]")
							return
						//Stuff it in a file archive.
						var/computer/file/archive/archive = new
						archive.max_contained_size = tape.file_amount

						var/computer/file/foundos_copy = foundos.copy_file()
						archive.add_file(foundos_copy)
						//Might as well stuff any other executable files hanging around too.
						for (var/computer/file/mainframe_program/MP in tape.root.contents)
							if (MP == foundos)
								continue

							var/computer/file/MP_copy = MP.copy_file()
							var/success = archive.add_file(MP_copy)
							if (!success)
								//qdel(MP_copy)
								MP_copy.dispose()
								break

						post_file(target, "data","command=file&session=[sessionid]",archive)
						return

				return

			if ("term_ping")
				if (target != src.host_id)
					return
				if (signal.data["data"] == "reply")
					post_status(target, "command","term_ping")
				timeout = initial(timeout)
				timeout_alert = 0 //no really please stay zero
				return

			if ("term_disconnect")
				if (target == src.host_id)
					src.host_id = null
				timeout = initial(timeout)
				timeout_alert = 0 //no really please stay zero
				updateUsrDialog()
				return

		return

	power_change()
		if (!tape)
			icon_state = "[base_icon_state]0"
			return

		else if (powered())
			icon_state = "[base_icon_state]1"
			stat &= ~NOPOWER
		else
			spawn (rand(0, 15))
				icon_state = "[base_icon_state]-p"
				stat |= NOPOWER

	proc //Computer3/Mainframe loan procs are the best procs!!
		is_name_invalid(string) //Check if a filename is invalid somehow
			if (!string)
				return TRUE

			if (ckey(string) != replacetext(lowertext(string), " ", null))
				return TRUE

			if (findtext(string, "/"))
				return TRUE

			return FALSE

		//Find a file with a given name
		get_file_name(string, var/computer/folder/check_folder)
			if (!string || (!check_folder || !istype(check_folder)))
				return null

			var/computer/taken = null
			for (var/computer/file/F in check_folder.contents)
				var/string2 = ckey(F.name)

				if (cmptext(string,string2))
					taken = F
					break

			return taken

		sync(var/target)
			if (!tape || !target || stat & (NOPOWER|BROKEN))
				return

			var/computer/file/archive/archive = new
			archive.max_contained_size = tape.file_amount

			for (var/computer/file/F in tape.root.contents)
				var/computer/file/F_copy = F.copy_file()
				var/success = archive.add_file(F_copy)
				if (!success)
					//qdel(F_copy)
					F_copy.dispose()
					break

			post_file(target, "data","command=sync",archive)
			return

/obj/machinery/networked/storage/bomb_tester
	name = "Explosive Simulator"
	desc = "A networked device designed to simulate and analyze explosions.  Takes two tanks."
	anchored = 1
	density = 1
	icon_state = "bomb_scanner0"
	base_icon_state = "bomb_scanner"

	setup_access_click = 0
	read_only = 1
	setup_drive_size = 4
	setup_drive_type = /obj/item/disk/data/bomb_tester
	setup_accept_tapes = 0

	var/obj/item/tank/tank1 = null
	var/obj/item/tank/tank2 = null
	var/computer/file/record/results = null
	var/setup_result_name = "Bomblog"
	var/obj/item/device/transfer_valve/vr/vrbomb = null
	var/last_sim = 0 //Last world.time we tested a bomb.
	var/sim_delay = 300 //Time until next simulation.
	power_usage = 200

	var/vr_landmark = "bombtest-bomb" //Landmark where the ~vr bomb~ spawns.

	power_change()
		if (powered())
			stat &= ~NOPOWER
			update_icon()
		else
			spawn (rand(0, 15))
				stat |= NOPOWER
				update_icon()
				if (vrbomb)
					qdel(vrbomb)

		return

	process()
		if (stat & BROKEN)
			return
		..()
		if (stat & NOPOWER)
			return
		use_power(200)

		if (!host_id || !data_link)
			return

		if (timeout == 0)
			post_status(host_id, "command","term_disconnect","data","timeout")
			src.host_id = null
			updateUsrDialog()
			timeout = initial(timeout)
			timeout_alert = 0
		else
			timeout--
			if (timeout <= 5 && !timeout_alert)
				timeout_alert = 1
				src.post_status(src.host_id, "command","term_ping","data","reply")

		return

	attackby(obj/item/W as obj, mob/user as mob)
		if (istype(W, /obj/item/tank))
			return attack_hand(user)
		else if (istype(W, /obj/item/screwdriver))
			playsound(loc, "sound/items/Screwdriver.ogg", 50, 1)
			boutput(user, "You [locked ? "secure" : "unscrew"] the maintenance panel.")
			panel_open = !panel_open
			updateUsrDialog()
			return
		else
			..()
		return

	attack_hand(mob/user as mob)
		if (stat & (NOPOWER|BROKEN))
			return

		if (user.lying || user.stat)
			return TRUE

		if ((get_dist(src, user) > 1 || !istype(loc, /turf)) && !istype(user, /mob/living/silicon))
			return TRUE

		user.machine = src

		var/dat = "<html><head><title>SimUnit - \[[bank_id]]</title></head><body>"

		dat += "<strong>Tank One:</strong> <a href='?src=\ref[src];tank=1'>[tank1 ? "Eject" : "None"]</a><br>"
		dat += "<strong>Tank Two:</strong> <a href='?src=\ref[src];tank=2'>[tank2 ? "Eject" : "None"]</a><hr>"

		dat += "<strong>Simulation:</strong> [vrbomb ? "IN PROGRESS" : "<a href='?src=\ref[src];simulate=1'>BEGIN</a>"]<br>"

		var/readout_color = "#000000"
		var/readout = "ERROR"
		if (src.host_id)
			readout_color = "#33FF00"
			readout = "OK CONNECTION"
		else
			readout_color = "#F80000"
			readout = "NO CONNECTION"

		dat += "Host Connection: "
		dat += "<table border='1' style='background-color:[readout_color]'><tr><td><font color=white>[readout]</font></td></tr></table><br>"

		dat += "<a href='?src=\ref[src];reset=1'>Reset Connection</a><br>"

		if (panel_open)
			dat += net_switch_html()

		user << browse(dat,"window=bombtester;size=245x302")
		onclose(user,"bombtester")
		return

	Topic(href, href_list)
		if (..())
			return

		usr.machine = src

		if (href_list["tank"])

			//Ai/cyborgs cannot physically remove a tape from a room away.
			if (istype(usr,/mob/living/silicon) && get_dist(src, usr) > 1)
				boutput(usr, "<span style=\"color:red\">You cannot press the ejection button.</span>")
				return

			switch(href_list["tank"])
				if ("1")
					if (tank1)
						tank1.set_loc(loc)
						tank1 = null
						boutput(usr, "You remove the tank.")
						if (vrbomb)
							qdel(vrbomb)
					else
						var/obj/item/I = usr.equipped()
						if (istype(I, /obj/item/tank))
							usr.drop_item()
							I.set_loc(src)
							tank1 = I
							boutput(usr, "You insert [I].")
					update_icon()
				if ("2")
					if (tank2)
						tank2.set_loc(loc)
						tank2 = null
						boutput(usr, "You remove the tank.")
						if (vrbomb)
							qdel(vrbomb)
					else
						var/obj/item/I = usr.equipped()
						if (istype(I, /obj/item/tank))
							usr.drop_item()
							I.set_loc(src)
							tank2 = I
							boutput(usr, "You insert [I].")
					update_icon()

			updateUsrDialog()

		else if (href_list["simulate"])
			if (!tank1 || !tank2)
				boutput(usr, "<span style=\"color:red\">Both tanks are required!</span>")
				return

			if (last_sim && (last_sim + sim_delay > world.time))
				boutput(usr, "<span style=\"color:red\">Simulator not ready, please try again later.</span>")
				return

			if (vrbomb)
				boutput(usr, "<span style=\"color:red\">Simulation already in progress!</span>")
				return

			generate_vrbomb()
			updateUsrDialog()

		else if (href_list["reset"])
			if (last_reset && (last_reset + NETWORK_MACHINE_RESET_DELAY >= world.time))
				return

			if (!host_id)
				return

			last_reset = world.time
			var/rem_host = src.host_id ? src.host_id : src.old_host_id
			src.host_id = null
			old_host_id = null
			post_status(rem_host, "command","term_disconnect")
			spawn (5)
				post_status(rem_host, "command","term_connect","device",device_tag)

			updateUsrDialog()
			return

		add_fingerprint(usr)
		return

	proc
		generate_vrbomb()
			if (!tank1 || !tank2)
				return

			if (vrbomb)
				qdel(vrbomb)

			var/obj/landmark/B = locate("landmark*[vr_landmark]")
			if (!B)
				playsound(loc, "sound/machines/buzz-sigh.ogg", 50, 1)
				visible_message("[src] emits a somber ping.")
				return

			vrbomb = new
			vrbomb.set_loc(B.loc)
			vrbomb.anchored = 1
			vrbomb.tester = src

			var/obj/item/device/timer/T = new
			vrbomb.attached_device = T
			T.master = vrbomb
			T.time = 6

			var/obj/item/tank/vrtank1 = new tank1.type
			var/obj/item/tank/vrtank2 = new tank2.type

			vrtank1.air_contents.copy_from(tank1.air_contents)
			vrtank2.air_contents.copy_from(tank2.air_contents)

			vrbomb.tank_one = vrtank1
			vrbomb.tank_two = vrtank2
			vrtank1.master = vrbomb
			vrtank1.set_loc(vrbomb)
			vrtank2.master = vrbomb
			vrtank2.set_loc(vrbomb)

			vrbomb.update_icon()

			T.timing = 1
			T.c_state(1)
			if (!(T in processing_items))
				processing_items.Add(T)
			last_sim = world.time

			var/area/to_reset = get_area(vrbomb) //Reset the magic vr turf.
			if (to_reset && to_reset.name != "Space")
				for (var/turf/unsimulated/bombvr/VT in to_reset)
					VT.icon_state = initial(VT.icon_state)
				for (var/turf/unsimulated/wall/bombvr/VT in to_reset)
					VT.icon_state = initial(VT.icon_state)
					VT.opacity = 1
					VT.density = 1

			if (results)
				//qdel(results)
				results.dispose()
			new_bomb_log()
			return

		new_bomb_log()
			if (!tape)
				return

			if (results)
				//qdel(results)
				results.dispose()

			results = new
			results.name = setup_result_name

			results.fields += "Test [time2text(world.realtime, "DDD MMM DD hh:mm:ss")], 2053"

			results.fields += "Atmospheric Tank #1:"
			if (tank1)
				var/gas_mixture/environment = tank1.return_air()
				var/pressure = environment.return_pressure()
				var/total_moles = environment.total_moles()

				results.fields += "Tank Pressure: [round(pressure,0.1)] kPa"
				if (total_moles)
					var/o2_level = environment.oxygen/total_moles
					var/n2_level = environment.nitrogen/total_moles
					var/co2_level = environment.carbon_dioxide/total_moles
					var/plasma_level = environment.toxins/total_moles
					var/unknown_level =  1-(o2_level+n2_level+co2_level+plasma_level)

					results.fields += "Nitrogen: [round(n2_level*100)]%"
					results.fields += "Oxygen: [round(o2_level*100)]%"
					results.fields += "Carbon Dioxide: [round(co2_level*100)]%"
					results.fields += "FAAE-1 (\"Plasma\"): [round(plasma_level*100)]%"

					if (unknown_level > 0.01)
						results.fields += "Unknown: [round(unknown_level)]%"

					results.fields += "|n"

				else
					results.fields += "Tank Empty"
			else
				results.fields += "None. (Sensor Error?)"

			results.fields += "Atmospheric Tank #2:"
			if (tank2)
				var/gas_mixture/environment = tank2.return_air()
				var/pressure = environment.return_pressure()
				var/total_moles = environment.total_moles()

				results.fields += "Tank Pressure: [round(pressure,0.1)] kPa"
				if (total_moles)
					var/o2_level = environment.oxygen/total_moles
					var/n2_level = environment.nitrogen/total_moles
					var/co2_level = environment.carbon_dioxide/total_moles
					var/plasma_level = environment.toxins/total_moles
					var/unknown_level =  1-(o2_level+n2_level+co2_level+plasma_level)

					results.fields += "Nitrogen: [round(n2_level*100)]%"
					results.fields += "Oxygen: [round(o2_level*100)]%"
					results.fields += "Carbon Dioxide: [round(co2_level*100)]%"
					results.fields += "FAAE-1 (\"Plasma\"): [round(plasma_level*100)]%"

					if (unknown_level > 0.01)
						results.fields += "Unknown: [round(unknown_level)]%"

					results.fields += "|n"

				else
					results.fields += "Tank Empty"
			else
				results.fields += "None. (Sensor Error?)"

			results.fields += "VR Bomb Monitor log:|nWaiting for monitor..."

			tape.root.add_file( results )
			src.sync(src.host_id)
			return

		//Called by our vrbomb as it heats up (Or doesn't.)
		update_bomb_log(var/newdata, var/sync_log = 0)
			if (!results || !newdata || !tape)
				return

			results.fields += newdata
			if (sync_log)
				src.sync(src.host_id)
			return

		update_icon()
			overlays = null
			if (tank1) //Update tank overlays.
				overlays += image(icon,"bscanner-tank1")
			if (tank2)
				overlays += image(icon,"bscanner-tank2")

			if (stat & BROKEN)
				icon_state = "bomb_scannerb"
				return
			if (stat & NOPOWER)
				icon_state = "bomb_scanner-p"
				return

			if (tank1 && tank2)
				icon_state = "bomb_scanner1"
			else
				icon_state = "bomb_scanner0"
			return

//Generic disk to hold VR bomb log
/obj/item/disk/data/bomb_tester
	desc = "You shouldn't be seeing this!"
	title = "TEMPBUFFER"
	file_amount = 4


/obj/machinery/networked/nuclear_charge
	name = "Nuclear Charge"
	anchored = 1
	density = 1
	icon_state = "net_nuke0"
	desc = "A nuclear charge used as a self-destruct device. Uh oh!"
	device_tag = "PNET_NUCCHARGE"
	var/timing = 0
	var/time = 60
	power_usage = 120

	var/status_display_freq = "1435"


#define DISARM_CUTOFF 10 //Can't disarm past this point! OH NO!

	mats = 80 //haha this is a bad idea
	is_syndicate = 1 //^ Agreed

	New()
		..()
		spawn (5)
			net_id = generate_net_id(src)

			if (!data_link)
				var/turf/T = get_turf(src)
				var/obj/machinery/power/data_terminal/test_link = locate() in T
				if (test_link && !test_link.is_valid_master(test_link.master))
					data_link = test_link
					data_link.master = src

	attack_hand(mob/user as mob)
		if (..() || stat & NOPOWER)
			return

		user.machine = src

		var/dat = "<html><head><title>Nuclear Charge</title></head><body>"

		dat += "<hr>[timing ? "SYSTEM ACTIVE" : "System Idle"]<br>Time: [time]<hr>"

		var/readout_color = "#000000"
		var/readout = "ERROR"
		if (src.host_id)
			readout_color = "#33FF00"
			readout = "OK CONNECTION"
		else
			readout_color = "#F80000"
			readout = "NO CONNECTION"

		dat += "Host Connection: "
		dat += "<table border='1' style='background-color:[readout_color]'><tr><td><font color=white>[readout]</font></td></tr></table><br>"

		dat += "<a href='?src=\ref[src];reset=1'>Reset Connection</a><br>"

		if (panel_open)
			dat += net_switch_html()

		user << browse(dat,"window=pnetnuke;size=245x302")
		onclose(user,"pnetnuke")
		return

	Topic(href, href_list)
		if (..())
			return

		usr.machine = src

		if (href_list["reset"])
			if (last_reset && (last_reset + NETWORK_MACHINE_RESET_DELAY >= world.time))
				return

			if (!host_id)
				return

			last_reset = world.time
			var/rem_host = src.host_id ? src.host_id : src.old_host_id
			src.host_id = null
			old_host_id = null
			post_status(rem_host, "command","term_disconnect")
			spawn (5)
				post_status(rem_host, "command","term_connect","device",device_tag)

			updateUsrDialog()
			return

		add_fingerprint(usr)
		return

	process()
		..()
		if (stat & NOPOWER)
			return
		use_power(120)

		if (!host_id || !data_link)
			return

		if (timeout == 0)
			post_status(host_id, "command","term_disconnect","data","timeout")
			src.host_id = null
			updateUsrDialog()
			timeout = initial(timeout)
			timeout_alert = 0
		else
			timeout--
			if (timeout <= 5 && !timeout_alert)
				timeout_alert = 1
				src.post_status(src.host_id, "command","term_ping","data","reply")

		if (timing)
			time--
			post_display_status(time)
			if (time <= 0)
				outpost_destroyed = 1
				detonate()
				return
			if (time == DISARM_CUTOFF)
				world << sound('sound/misc/airraid_loop.ogg')
			if (time <= DISARM_CUTOFF)
				icon_state = "net_nuke2"
				boutput(world, "<span style=\"color:red\"><strong>[time] seconds until nuclear charge detonation.</strong></span>")
			else
				time -= 2
				icon_state = "net_nuke1"

			updateUsrDialog()
		else
			icon_state = "net_nuke0"

		return

	power_change()
		if (powered())
			stat &= ~NOPOWER
			if (timing)
				if (time <= DISARM_CUTOFF)
					icon_state = "net_nuke2"
				else
					icon_state = "net_nuke1"
			else
				icon_state = "net_nuke0"
		else
			spawn (rand(0, 15))
				icon_state = "net_nuke-p"
				stat |= NOPOWER

		return

	attackby(obj/item/W as obj, mob/user as mob)
		if (istype(W, /obj/item/screwdriver))
			playsound(loc, "sound/items/Screwdriver.ogg", 50, 1)
			boutput(user, "You [panel_open ? "secure" : "unscrew"] the maintenance panel.")
			panel_open = !panel_open
			updateUsrDialog()
			return
		else
			..()

	receive_signal(signal/signal)
		if (stat & (NOPOWER) || !data_link)
			return
		if (!signal || !net_id || signal.encryption)
			return

		if (signal.transmission_method != TRANSMISSION_WIRE)
			return

		var/target = signal.data["sender"]

		//They don't need to target us specifically to ping us.
		//Otherwise, if they aren't addressing us, ignore them
		if (signal.data["address_1"] != net_id)
			if ((signal.data["address_1"] == "ping") && ((signal.data["net"] == null) || ("[signal.data["net"]]" == "[net_number]")) && signal.data["sender"])
				spawn (5) //Send a reply for those curious jerks
					post_status(target, "command", "ping_reply", "device", device_tag, "netid", net_id, "net", "[net_number]")

			return

		var/sigcommand = lowertext(signal.data["command"])
		if (!sigcommand || !signal.data["sender"])
			return

		switch(sigcommand)
			if ("term_connect") //Terminal interface stuff.
				if (target == src.host_id)
					//WHAT IS THIS, HOW COULD THIS HAPPEN??
					src.host_id = null
					updateUsrDialog()
					spawn (3)
						post_status(target, "command","term_disconnect")
					return

				if (src.host_id)
					return

				timeout = initial(timeout)
				timeout_alert = 0
				src.host_id = target
				old_host_id = target
				if (signal.data["data"] != "noreply")
					post_status(target, "command","term_connect","data","noreply","device",device_tag)
				updateUsrDialog()
				spawn (2) //Sign up with the driver (if a mainframe contacted us)
					post_status(target,"command","term_message","data","command=register&data=nucharge")
				return

			if ("term_message","term_file")
				if (target != src.host_id) //Huh, who is this?
					return

				var/list/data = params2list(signal.data["data"])
				if (!data)
					return

				var/sessionid = data["session"]
				if (!sessionid)
					sessionid = 0

				switch(data["command"])
					if ("status")
						var/status_string = "command=n_status"
						status_string += "&active=[timing]&timeleft=[time]&session=[sessionid]"
						spawn (0)
							post_status(target,"command","term_message","data",status_string)
						return

					if ("settime")
						if (timing) //No changing the time when we're already timing!
							post_status(target,"command","term_message","data","command=status&status=failure&session=[sessionid]")
							return
						var/thetime = text2num(data["time"])
						if (isnull(thetime))
							post_status(target,"command","term_message","data","command=status&status=noparam&session=[sessionid]")
							return
						thetime = max( min(thetime,440), 30)
						time = thetime
						post_status(target,"command","term_message","data","command=status&status=success&session=[sessionid]")
						return
					if ("act")
						if (timing)
							post_status(target,"command","term_message","data","command=status&status=failure&session=[sessionid]")
							return
						if (data["auth"] != netpass_heads)
							post_status(target,"command","term_message","data","command=status&status=badauth&session=[sessionid]")
							return
						timing = 1
						post_status(target,"command","term_message","data","command=status&status=success&session=[sessionid]")

						var/admessage = "NUKE: Network Nuclear Charge armed for [time] seconds."
						var/turf/T = get_turf(src)
						if (T)
							admessage += "<strong> ([T.x],[T.y],[T.z])</strong>"
						message_admins(admessage)
						//World announcement.
						boutput(world, "<span style=\"color:red\"><strong>Alert: Self-Destruct Sequence has been engaged.</strong></span>")
						boutput(world, "<span style=\"color:red\"><strong>Detonation in T-[time] seconds!</strong></span>")
						return
					if ("deact")
						if (data["auth"] != netpass_heads)
							post_status(target,"command","term_message","data","command=status&status=badauth&session=[sessionid]")
							return
						if (!timing || time <= DISARM_CUTOFF)
							post_status(target,"command","term_message","data","command=status&status=failure&session=[sessionid]")
							return

						timing = 0
						time = max(time,30) //so we don't have some jerk letting it tick down to 11 and then saving it for later.
						icon_state = "net_nuke0"
						post_status(target,"command","term_message","data","command=status&status=success&session=[sessionid]")
						//World announcement.
						boutput(world, "<span style=\"color:red\"><strong>Alert: Self-Destruct Sequence has been disengaged!</strong></span>")
						post_display_status(-1)
						return

				return

			if ("term_ping")
				if (target != src.host_id)
					return
				if (signal.data["data"] == "reply")
					post_status(target, "command","term_ping")
				timeout = initial(timeout)
				timeout_alert = 0
				return

			if ("term_disconnect")
				if (target == src.host_id)
					src.host_id = null
				timeout = initial(timeout)
				timeout_alert = 0 //no really please stay zero
				updateUsrDialog()
				return

		return

	proc/detonate()
		world << sound('sound/effects/kaboom.ogg')
		//explosion(src, loc, 10, 20, 30, 35)
		explosion_new(src, get_turf(src), 10000)
		//dispose()
		dispose()
		return



	proc/post_display_status(var/timeleft)

		var/radio_frequency/frequency = radio_controller.return_frequency(status_display_freq)

		if (!frequency) return

		var/signal/status_signal = get_free_signal()
		status_signal.source = src
		status_signal.transmission_method = 1
		if (timeleft < 0)
			status_signal.data["command"] = "blank"
		else
			status_signal.data["command"] = "destruct"
			status_signal.data["time"] = "[timeleft]"

		frequency.post_signal(src, status_signal)

#undef DISARM_CUTOFF


/obj/machinery/networked/radio
	name = "Network Radio"
	desc = "A networked radio interface."
	anchored = 1
	density = 1
	icon_state = "net_radio"
	device_tag = "PNET_PR6_RADIO"
	//var/freq = 1219
	mats = 8
	var/list/frequencies = list()
	var/radio_frequency/radio_connection
	var/transmission_range = 100 //How far does our signal reach?
	var/take_radio_input = 1 //Do we echo radio signals addresed to us back to our host?
	var/can_be_host = 0
	power_usage = 100
	var/last_ping = 0

	New()
		..()

		net_id = generate_net_id(src)

		spawn (5)

			if (radio_controller)
				frequencies["1411"] = radio_controller.add_object(src, "1411")
				frequencies["1419"] = radio_controller.add_object(src, "1419")

			if (!data_link)
				var/turf/T = get_turf(src)
				var/obj/machinery/power/data_terminal/test_link = locate() in T
				if (test_link && !test_link.is_valid_master(test_link.master))
					data_link = test_link
					data_link.master = src

	attack_hand(mob/user as mob)
		if (..() || (stat & (NOPOWER|BROKEN)))
			return

		user.machine = src

		var/dat = "<html><head><title>Network Radio</title></head><body>"

		dat += "Active  Frequencies:<hr>"
		if (frequencies.len)
			var/linebreakCounter = 2
			for (var/theFreq in frequencies)
				dat += "[copytext(theFreq, 1, 4)].[copytext(theFreq, 4)] MHz&nbsp;&nbsp;&nbsp;"
				if (linebreakCounter-- < 1)
					linebreakCounter = 2
					dat += "<br>"

		else
			dat += "<center>None</center>"


		var/readout_color = "#000000"
		var/readout = "ERROR"
		if (src.host_id)
			readout_color = "#33FF00"
			readout = "OK CONNECTION"
		else
			readout_color = "#F80000"
			readout = "NO CONNECTION"

		dat += "<hr>Host Connection: "
		dat += "<table border='1' style='background-color:[readout_color]'><tr><td><font color=white>[readout]</font></td></tr></table><br>"

		dat += "<a href='?src=\ref[src];reset=1'>Reset Connection</a><br>"

		if (panel_open)
			dat += net_switch_html()

		user << browse(dat,"window=net_radio;size=245x302")
		onclose(user,"net_radio")
		return

	attackby(obj/item/W as obj, mob/user as mob)
		if (istype(W, /obj/item/screwdriver))
			playsound(loc, "sound/items/Screwdriver.ogg", 50, 1)
			boutput(user, "You [panel_open ? "secure" : "unscrew"] the maintenance panel.")
			panel_open = !panel_open
			updateUsrDialog()
			return
		else
			..()

	Topic(href, href_list)
		if (..())
			return

		usr.machine = src

		if (href_list["reset"])
			if (last_reset && (last_reset + NETWORK_MACHINE_RESET_DELAY >= world.time))
				return

			if (!host_id)
				return

			last_reset = world.time
			var/rem_host = src.host_id ? src.host_id : src.old_host_id
			src.host_id = null
			old_host_id = null
			post_status(rem_host, "command","term_disconnect")
			spawn (5)
				post_status(rem_host, "command","term_connect","device",device_tag)

			updateUsrDialog()
			return

		add_fingerprint(usr)
		return


	power_change()
		if (powered())
			icon_state = "net_radio"
			stat &= ~NOPOWER
		else
			spawn (rand(0, 15))
				icon_state = "net_radio0"
				stat |= NOPOWER

	process()
		..()
		if (stat & NOPOWER)
			return
		use_power(100)

		if (!host_id || !data_link)
			return

		if (timeout == 0)
			post_status(host_id, "command","term_disconnect","data","timeout")
			src.host_id = null
			updateUsrDialog()
			timeout = initial(timeout)
			timeout_alert = 0
		else
			timeout--
			if (timeout <= 5 && !timeout_alert)
				timeout_alert = 1
				src.post_status(src.host_id, "command","term_ping","data","reply")

		return

	receive_signal(signal/signal, transmission_type, theFreq)
		if (stat & (NOPOWER) || !data_link)
			return
		if (!signal || !net_id || signal.encryption)
			return

		var/target = signal.data["sender"] ? signal.data["sender"] : signal.data["netid"]
		if (!target)
			return

		//We care very deeply about address_1.
		if (!cmptext(signal.data["address_1"], net_id))
			if ((signal.data["address_1"] == "ping") && ((signal.data["net"] == null) || ("[signal.data["net"]]" == "[net_number]")))
				spawn (5) //Send a reply for those curious jerks
					if (signal.transmission_method == TRANSMISSION_RADIO)
						var/radio_frequency/transmit_connection = radio_controller.return_frequency("[theFreq]")

						if (!transmit_connection)
							return

						var/signal/rsignal = get_free_signal()
						rsignal.source = src
						rsignal.transmission_method = TRANSMISSION_RADIO
						rsignal.data = list("address_1"=target, "command"="ping_reply", "device"=device_tag, "netid"=net_id, "net"="[net_number]", "sender" = net_id)

						transmit_connection.post_signal(src, rsignal, transmission_range)
					else
						post_status(target, "command", "ping_reply", "device", device_tag, "netid", net_id, "net", "[net_number]")
				return

			if (signal.transmission_method == TRANSMISSION_WIRE)
				return
		//	if (!signal.data["target_device"])
		//		return

		if (signal.transmission_method == TRANSMISSION_RADIO && take_radio_input)
			if (!host_id)
				if (can_be_host && signal.data["address_2"])
					var/signal/redirected_signal = get_free_signal()
					redirected_signal.source = src
					redirected_signal.transmission_method = TRANSMISSION_WIRE
					redirected_signal.data = signal.data:Copy()
					redirected_signal.data["address_1"] = redirected_signal.data["address_2"]
					redirected_signal.data["sender1"] = redirected_signal.data["sender"]
					redirected_signal.data["sender"] = net_id
					data_link.post_signal(src, redirected_signal)

				return
			//var/list/working = signal.data:Copy()
			var/computer/working_file = null
			if (signal.data_file)
				working_file = signal.data_file.copy_file()

			var/workparams = list2params(signal.data)
			if (!workparams)
				//qdel(working)
			//	if (working)
			//		working.len = 0
			//		working = null
				//qdel(working_file)
				if (working_file)
					working_file.dispose()
				return

			if (theFreq)
				workparams += "&_freq=[theFreq]"

			spawn (2)
				if (working_file)
					src.post_file(src.host_id,"data",workparams,working_file)
				else
					src.post_status(src.host_id,"command","term_message","data",workparams)

			return

		var/sigcommand = lowertext(signal.data["command"])
		if (!sigcommand || !target)
			return

		switch(sigcommand)
			if ("term_connect") //Terminal interface stuff.
				if (target == src.host_id)
					src.host_id = null
					updateUsrDialog()
					spawn (3)
						post_status(target, "command","term_disconnect")
					return

				if (src.host_id)
					return

				timeout = initial(timeout)
				timeout_alert = 0
				src.host_id = target
				old_host_id = target
				if (signal.data["data"] != "noreply")
					post_status(target, "command","term_connect","data","noreply","device",device_tag)
				updateUsrDialog()
				spawn (5) //Sign up with the driver (if a mainframe contacted us)
					post_status(target,"command","term_message","data","command=register[(frequencies && frequencies.len) ? "&freqs=[jointext(frequencies,",")]" : ""]")
				return

			if ("term_message","term_file")
				if (target != src.host_id) //Huh, who is this?
					return

				var/list/data = params2list(signal.data["data"])
				if (!data || !data["_freq"])// || (!data["_command"] && !data["address_1"] && data["acc_code"] != netpass_heads) ) //Either address a specific bot or have the code for all of them, buddy
					post_status(target,"command","term_message","data","command=status&status=failure")
					return

				if (data["_command"])
					switch (lowertext(data["_command"]))
						if ("add")
							var/newFreq = "[round(max(1000, min(text2num(data["_freq"]), 1500)))]"
							if (newFreq && !(newFreq in frequencies))
								frequencies[newFreq] = radio_controller.add_object(src, newFreq)

						if ("remove")
							var/newFreq = "[round(max(1000, min(text2num(data["_freq"]), 1500)))]"
							if (newFreq && (newFreq in frequencies))
								radio_controller.remove_object(src, newFreq)
								frequencies -= newFreq

						if ("clear")
							for (var/x in frequencies)
								radio_controller.remove_object(src, x)

							frequencies.len = 0

						else
							post_status(target,"command","term_message","data","command=status&status=failure")
					return

				var/newFreq = round(max(1000, min(text2num(data["_freq"]), 1500)))
				data -= "_freq"
				if (!newFreq || !radio_controller || !data.len)
					post_status(target,"command","term_message","data","command=status&status=failure")
					return
				var/radio_frequency/transmit_connection = radio_controller.return_frequency("[newFreq]")

				if (!transmit_connection)
					post_status(target,"command","term_message","data","command=status&status=failure")
					return

				var/signal/rsignal = get_free_signal()
				rsignal.source = src
				rsignal.transmission_method = TRANSMISSION_RADIO
				rsignal.data = data.Copy()

				rsignal.data["sender"] = net_id

				spawn (0)
					transmit_connection.post_signal(src, rsignal, transmission_range)
					flick("net_radio-blink", src)
				post_status(target,"command","term_message","data","command=status&status=success")

				return

			if ("term_ping")
				if (target != src.host_id)
					return
				if (signal.data["data"] == "reply")
					post_status(target, "command","term_ping")
				timeout = initial(timeout)
				timeout_alert = 0
				return

			if ("term_disconnect")
				if (target == src.host_id)
					src.host_id = null
				timeout = initial(timeout)
				timeout_alert = 0 //No need to be alerted about this anymore.
				updateUsrDialog()
				return

		return


/obj/machinery/networked/printer
	name = "Printer"
	desc = "A networked printer.  It's designed to print."
	anchored = 1
	density = 1
	icon_state = "printer0"
	device_tag = "PNET_PRINTDEVC"
	mats = 6
	var/print_id = null //Just like databanks.
	var/temp_msg = "PRINTER OK" //Appears in the interface window.
	var/printing = 0 //Are we printing RIGHT NOW?
	var/list/print_buffer = list() //Are we waiting to print anything?
	var/jam = 0 //Oh no! A jam! I hope somebody unjams us right quick!
	var/blinking = 0 //Is our indicator light blinking?
	var/sheets_remaining = 15 //How many blank sheets of paper do we have left?
	power_usage = 200

#define MAX_SHEETS 20
#define SETUP_JAM_IGNITION 6 //How jammed do we have to be before we break down?
#define MAX_PRINTBUFFER_SIZE 10

	New()
		..()
		if (!print_id)
			print_id = "GENERIC"

		spawn (5)
			net_id = generate_net_id(src)

			if (!data_link)
				var/turf/T = get_turf(src)
				var/obj/machinery/power/data_terminal/test_link = locate() in T
				if (test_link && !test_link.is_valid_master(test_link.master))
					data_link = test_link
					data_link.master = src

			update_icon() //Update the icon
		return


	attackby(obj/item/W as obj, mob/user as mob)
		if (istype(W, /obj/item/paper)) //Load up the printer!
			if (sheets_remaining >= MAX_SHEETS)
				boutput(user, "<span style=\"color:red\">The tray is full!</span>")
				return

			if (W:info)
				boutput(user, "<span style=\"color:red\">That paper has already been used!</span>")
				return

			user.drop_item()
			qdel(W)
			boutput(user, "You load the paper into [src].")
			if (!sheets_remaining && !jam)
				clear_alert()

			sheets_remaining++
			updateUsrDialog()
			return

		else if (istype(W, /obj/item/paper_bin)) //Load up the printer!
			if (sheets_remaining >= MAX_SHEETS)
				boutput(user, "<span style=\"color:red\">The tray is full!</span>")
				return

			var/to_remove = MAX_SHEETS - sheets_remaining
			if (W:amount > to_remove)
				W:amount -= to_remove
				boutput(user, "You load [to_remove] sheets into the tray.")
				sheets_remaining += to_remove
			else
				boutput(user, "You load [W:amount] sheets into the tray.")
				sheets_remaining += W:amount
				user.drop_item()
				qdel(W)

			if (!jam)
				clear_alert()

			if (temp_msg == "PC LOAD LETTER")
				temp_msg = "PRINTER OK"
			updateUsrDialog()
			return

		else if (istype(W, /obj/item/screwdriver))
			playsound(loc, "sound/items/Screwdriver.ogg", 50, 1)
			boutput(user, "You [panel_open ? "secure" : "unscrew"] the maintenance panel.")
			panel_open = !panel_open
			updateUsrDialog()
			return

		else
			return attack_hand(user)

		return

	attack_hand(mob/user as mob)
		if (..() || (stat & (NOPOWER|BROKEN)))
			return

		user.machine = src

		var/dat = "<html><head><title>Printer - \[[print_id]]</title></head><body>"

		dat += "<hr><tt>[temp_msg]</tt><hr>"

		if (jam)
			dat += "<strong>Printing:</strong> <a href='?src=\ref[src];unjam=1'>JAMMED</a><br>"
		else
			dat += "<strong>Printing:</strong> [printing ? "YES" : "NO"]<br>"

		var/readout_color = "#000000"
		var/readout = "ERROR"
		if (src.host_id)
			readout_color = "#33FF00"
			readout = "OK CONNECTION"
		else
			readout_color = "#F80000"
			readout = "NO CONNECTION"

		dat += "Host Connection: "
		dat += "<table border='1' style='background-color:[readout_color]'><tr><td><font color=white>[readout]</font></td></tr></table><br>"

		dat += "<a href='?src=\ref[src];reset=1'>Reset Connection</a><br>"

		if (panel_open)
			dat += net_switch_html()

		user << browse(dat,"window=printer;size=245x302")
		onclose(user,"printer")
		return

	Topic(href, href_list)
		if (..())
			return

		usr.machine = src

		if (href_list["unjam"])
			if (jam)
				if (get_dist(src,usr) > 1)
					boutput(usr, "You are too far away to unjam it.")
					return
				jam = 0
				blinking = 0
				update_icon()
				temp_msg = "PRINTER OK"
				updateUsrDialog()
				boutput(usr, "<span style=\"color:blue\">You clear the jam.</span>")
			else
				boutput(usr, "There is no jam to clear.")

		else if (href_list["reset"])
			if (last_reset && (last_reset + NETWORK_MACHINE_RESET_DELAY >= world.time))
				return

			if (!host_id)
				return

			print_buffer.len = 0
			last_reset = world.time
			var/rem_host = src.host_id ? src.host_id : src.old_host_id
			src.host_id = null
			old_host_id = null
			post_status(rem_host, "command","term_disconnect")
			spawn (5)
				post_status(rem_host, "command","term_connect","device",device_tag)

			updateUsrDialog()
			return

		add_fingerprint(usr)
		return

	process()
		if (stat & BROKEN)
			printing = 0
			return
		..()
		if (stat & NOPOWER)
			printing = 0
			return
		use_power(200)

		if (!host_id || !data_link)
			return

		if (timeout == 0)
			post_status(host_id, "command","term_disconnect","data","timeout")
			src.host_id = null
			updateUsrDialog()
			timeout = initial(timeout)
			timeout_alert = 0
		else
			timeout--
			if (timeout <= 5 && !timeout_alert)
				timeout_alert = 1
				src.post_status(src.host_id, "command","term_ping","data","reply")

		if (!printing && print_buffer.len)
			print()

		return

	receive_signal(signal/signal)
		if (stat & (NOPOWER|BROKEN) || !data_link)
			return
		if (!signal || !net_id || signal.encryption)
			return

		if (signal.transmission_method != TRANSMISSION_WIRE) //No radio for us thanks
			return

		var/target = signal.data["sender"]

		if (signal.data["address_1"] != net_id)
			if ((signal.data["address_1"] == "ping") && ((signal.data["net"] == null) || ("[signal.data["net"]]" == "[net_number]")) && signal.data["sender"])
				spawn (5)
					post_status(target, "command", "ping_reply", "device", device_tag, "netid", net_id, "net", "[net_number]")

			return

		var/sigcommand = lowertext(signal.data["command"])
		if (!sigcommand || !signal.data["sender"])
			return

		switch(sigcommand)
			if ("term_connect") //Terminal interface stuff.
				if (target == src.host_id)
					//WHAT IS THIS, HOW COULD THIS HAPPEN??
					src.host_id = null
					updateUsrDialog()
					spawn (3)
						post_status(target, "command","term_disconnect")
					return

				if (src.host_id)
					return

				timeout = initial(timeout)
				timeout_alert = 0
				src.host_id = target
				old_host_id = target
				if (signal.data["data"] != "noreply")
					post_status(target, "command","term_connect","data","noreply","device",device_tag)
				updateUsrDialog()
				spawn (2) //Sign up with the driver (if a mainframe contacted us)
					post_status(target,"command","term_message","data","command=register&data=[print_id]")
				return

			if ("term_message","term_file")
				if (target != src.host_id) //Huh, who is this?
					return

				var/list/data = params2list(signal.data["data"])
				if (!data)
					return

				switch(data["command"])
					if ("print")

						if (!signal.data_file || (!istype(signal.data_file, /computer/file/text) && !istype(signal.data_file, /computer/file/record)))
							post_status(target,"command","term_message","data","command=status&status=badfile")
							return

						if (print_buffer.len+1 > MAX_PRINTBUFFER_SIZE)
							post_status(target,"command","term_message","data","command=status&status=bufferfull")
							return

						var/buffer_add = null
						if (istype(signal.data_file, /computer/file/record))
							var/computer/file/record/rec = signal.data_file
							if (rec.fields)
								buffer_add = jointext(rec.fields, "<br>")
						else
							buffer_add = signal.data_file:data

						if (!buffer_add)
							post_status(target,"command","term_message","data","command=status&status=badfile")
							return


						var/title = copytext(data["title"], 1, 64)
						if (!title)
							title = "printout"

						buffer_add = "[title]&title;[buffer_add]"
						print_buffer += buffer_add
						return
					if ("clearbuffer")
						print_buffer.len = 0
						post_status(target,"command","term_message","data","command=status&status=success")
						return
				return

			if ("term_ping")
				if (target != src.host_id)
					return
				if (signal.data["data"] == "reply")
					post_status(target, "command","term_ping")
				timeout = initial(timeout)
				timeout_alert = 0
				return

			if ("term_disconnect")
				if (target == src.host_id)
					src.host_id = null
				timeout = initial(timeout)
				timeout_alert = 0
				updateUsrDialog()
				return

		return

	proc
		print()
			if (stat & (NOPOWER|BROKEN))
				return FALSE
			if (!src.host_id)
				return FALSE
			if (printing || !print_buffer.len)
				return FALSE

			var/print_text = print_buffer[1]
			print_buffer.Cut(1,2) //Remove the first stage.

//			if (!userid)
//				src.post_status(src.host_id,"command","term_message","data","command=status&status=nouser")
//				return FALSE

			if (!sheets_remaining)
				src.post_status(src.host_id,"command","term_message","data","command=status&status=nopaper")
				return FALSE
			if (prob(1) || jam)
				if (jam())
					return TRUE
				src.post_status(src.host_id,"command","term_message","data","command=status&status=jam")
				print_alert()
				return TRUE

			printing = 1
			if (!print_text)
				printing = 0
				return FALSE

			sheets_remaining--

			flick("printer-printing",src)
			playsound(loc, "sound/machines/printer_dotmatrix.ogg", 50, 1)
			spawn (32)

				var/obj/item/paper/P = new /obj/item/paper( loc )

				var/titlepoint = findtext(print_text, "&title;",1 , 72)
				if (titlepoint)
					P.name = "paper- '[copytext(print_text,1,titlepoint)]'"
					print_text = copytext(print_text, titlepoint+7)
				else
					P.name = "paper- 'Printout'"

				P.info = print_text

				var/formStartPoint = 1
				var/formEndPoint = 0

				if (!P.form_startpoints)
					P.form_startpoints = list()
					P.form_endpoints = list()

				. = 0
				while (formStartPoint)
					formStartPoint = findtext(P.info, "__", formStartPoint)
					if (formStartPoint)
						formEndPoint = formStartPoint + 1
						while (copytext(P.info, formEndPoint, formEndPoint+1) == "_")
							formEndPoint++

						P.form_startpoints["[.]"] = formStartPoint
						P.form_endpoints["[.++]"] = formEndPoint

						formStartPoint = formEndPoint+1


				printing = 0

			if (sheets_remaining <= 0)
				temp_msg = "PC LOAD LETTER"
				print_alert()
				src.post_status(src.host_id,"command","term_message","data","command=status&status=lowpaper")
			else
				src.post_status(src.host_id,"command","term_message","data","command=status&status=success")
			updateUsrDialog()
			return TRUE

		jam()
			jam++
			if (jam >= SETUP_JAM_IGNITION && !(stat & BROKEN))
				stat |= BROKEN
				visible_message("<span style=\"color:red\"><strong>[src]</strong> bursts into flames!</span>")
				printing = 0
				print_buffer.len = 0

				update_icon()

				var/effects/system/spark_spread/s = unpool(/effects/system/spark_spread)
				s.set_up(3, 1, src)
				s.start()
				if (src.host_id) //welp, we're broken.
					src.post_status(src.host_id,"command","term_message","data","command=status&status=thermalert")
				return TRUE

			printing = 0
			print_buffer.len = 0
			return FALSE

		print_alert()
			blinking = 1
			update_icon()
			playsound(loc, "sound/machines/buzz-sigh.ogg", 50, 1)
			visible_message("<span style=\"color:red\">[src] pings!</span>")
			return

		clear_alert()
			blinking = 0
			update_icon()
			return

		update_icon()
			overlays = null
			if (jam) //Update jam overlay.
				overlays += image(icon,"printer-jamoverlay")

			if (stat & BROKEN)
				icon_state = "printerb"
				return
			if (stat & NOPOWER)
				icon_state = "printer-p"
				return

			if (blinking)
				icon_state = "printer-blink"
			else
				icon_state = "printer0"
			return

#undef MAX_SHEETS
#undef SETUP_JAM_IGNITION
#undef MAX_PRINTBUFFER_SIZE

/obj/machinery/networked/storage/scanner
	name = "Scanner"
	desc = "A networked drum scanner.  It's designed to...scan documents."
	anchored = 1
	density = 1
	icon_state = "scanner0"
	//device_tag = "PNET_SCANDEVC"
	var/scanning = 0 //Are we scanning RIGHT NOW?
	var/obj/item/scanned_thing //Ideally, this would be a paper or photo.

	var/computer/file/scan_buffer

	setup_access_click = 0
	read_only = 1
	setup_drive_size = 16
	setup_drive_type = /obj/item/disk/data/bomb_tester
	setup_accept_tapes = 0
	power_usage = 200

	New()
		..()
		if (!dd_hasprefix(uppertext(bank_id),"SC-"))
			bank_id = "SC-[bank_id]"

	attack_hand(mob/user as mob)
		if (stat & (NOPOWER|BROKEN))
			return

		if (user.lying || user.stat)
			return TRUE

		if ((get_dist(src, user) > 1 || !istype(loc, /turf)) && !istype(user, /mob/living/silicon))
			return TRUE

		user.machine = src

		var/dat = "<html><head><title>Scanner - \[[copytext(bank_id,4)]]</title></head><body>"

		dat += "<strong>Document:</strong> <a href='?src=\ref[src];document=1'>[scanned_thing ? scanned_thing.name : "-----"]</a><br>"

		var/readout_color = "#000000"
		var/readout = "ERROR"
		if (src.host_id)
			readout_color = "#33FF00"
			readout = "OK CONNECTION"
		else
			readout_color = "#F80000"
			readout = "NO CONNECTION"

		dat += "Host Connection: "
		dat += "<table border='1' style='background-color:[readout_color]'><tr><td><font color=white>[readout]</font></td></tr></table><br>"

		dat += "<a href='?src=\ref[src];reset=1'>Reset Connection</a><br>"

		if (panel_open)
			dat += net_switch_html()

		user << browse(dat,"window=scanner;size=245x302")
		onclose(user,"scanner")
		return

	attackby(obj/item/W as obj, mob/user as mob)
		if (istype(W, /obj/item/paper) || istype(W, /obj/item/photo))
			if (scanned_thing)
				boutput(user, "<span style=\"color:red\">There is already something in the scanner!</span>")
				return

			usr.drop_item()
			W.set_loc(src)
			scanned_thing = W
			power_change()
			spawn (0)
				scan_document()
			updateUsrDialog()

		else
			return ..()

	Topic(href, href_list)
		if (..())
			return

		usr.machine = src

		if (href_list["document"])
			if (istype(usr,/mob/living/silicon) && get_dist(src, usr) > 1)
				boutput(usr, "<span style=\"color:red\">There is no electronic control over the actual document.</span>")
				return

			if (scanned_thing)
				scanned_thing.set_loc(loc)
				scanned_thing = null
			else
				var/obj/item/I = usr.equipped()
				if (istype(I, /obj/item/paper) || istype(I, /obj/item/photo))
					usr.drop_item()
					I.set_loc(src)
					scanned_thing = I
					boutput(usr, "You insert [I].")
			power_change()
			updateUsrDialog()


		add_fingerprint(usr)
		return

	power_change()
		if (powered())
			stat &= ~NOPOWER
			icon_state = "scanner[!isnull(scanned_thing)]"
		else
			spawn (rand(0, 15))
				stat |= NOPOWER
				icon_state = "scanner[!isnull(scanned_thing)]-p"
		return

	process()
		if (stat & BROKEN)
			return
		..()
		if (stat & NOPOWER)
			return
		use_power(200)

		if (!host_id || !data_link)
			return

		if (timeout == 0)
			post_status(host_id, "command","term_disconnect","data","timeout")
			src.host_id = null
			updateUsrDialog()
			timeout = initial(timeout)
			timeout_alert = 0
		else
			timeout--
			if (timeout <= 5 && !timeout_alert)
				timeout_alert = 1
				src.post_status(src.host_id, "command","term_ping","data","reply")

		return

	proc/scan_document()
		if ((stat & (NOPOWER|BROKEN)) || !src.host_id || src.scanning)
			return TRUE

		if (!scanned_thing)
			return TRUE

		scanning = 1
		flick("scanner-scanning",src)
		sleep(20)
		if (scan_buffer)
			scan_buffer.dispose()
			scan_buffer = null

		if (istype(scanned_thing, /obj/item/paper))
			var/obj/item/paper/paper_thing = scanned_thing
			var/computer/file/record/scanned = new
			scanned.fields = process_paper_info( paper_thing.info )
			scanned.name = "document"
			if (tape.root.add_file( scanned ))
				scan_buffer = scanned
				src.sync(src.host_id)
				playsound(loc, "sound/machines/ping.ogg", 50, 0)
			else
				scanned.dispose()

			scanning = 0
			return FALSE
		else if (istype(scanned_thing, /obj/item/photo))
			var/obj/item/photo/photo_thing = scanned_thing
			var/computer/file/image/scanned = new
			scanned.ourImage = photo_thing.fullImage
			scanned.name = "document"
			if (tape.root.add_file( scanned ))
				scan_buffer = scanned
				src.sync(src.host_id)
				playsound(loc, "sound/machines/ping.ogg", 50, 0)
			else
				scanned.dispose()

			scanning = 0
			return FALSE

		scanning = 0
		return TRUE

	proc/process_paper_info(var/info)
		if (!istext(info))
			return null

		var/list/output = list()
		var/infoLength = length(info)
		var/searchPosition = 1
		var/findPosition = 1

		while (1)
			findPosition = findtext(info, "<br>", searchPosition, 0)
			. = copytext(info, searchPosition, findPosition)
			var/innerOpen = 1
			var/innerClose = 1
			while (1)
				innerOpen = findtext(., "<", 1, 0)
				innerClose = findtext(., ">", innerOpen, 0)
				if (!innerOpen || !innerClose)
					break

				. = copytext(., 1, innerOpen) + copytext(., innerClose + 1)


			output += .
			if (!findPosition)
				break

			searchPosition = findPosition + 4
			if (searchPosition > infoLength)
				break

		return output


//IR tripwire/threat analyzer.
/obj/machinery/networked/secdetector
	name = "IR Detector"
	desc = "An infrared tripwire and video camera coupled with a sophisticated threat-analysis system."
	icon_state = "secdetector0"
	device_tag = "PNET_IR_DETECT"

	var/detector_id = null
	var/obj/beam/ir_beam/scan_beam = null
	var/online = 1 //Are we looking for anything or just sitting there?
	var/state = 1 //1 idle, 2 active, 3 triggered.
	var/active_time = 0 //Set >0 when active, decrement every tick, return to idle state when zero.

	var/active_brightness = 0.7 //Luminosity when seeking (State == 2)
	var/alert_brightness = 0.4

	var/setup_beam_length = 24 //Max length of scan_beam.
	var/setup_active_time = 20 //Length of time active after beam is crossed.
	var/setup_alerted_time = 60 //Length of time alerted after seeing a threat.
	var/area_access = access_heads //ID access required to not be considered a threat.

	var/light/light

	New()
		..() //Set detector ID if not already set, generate net ID, then update icon.
		if (!detector_id)
			detector_id = "GENERIC"

		light = new /light/point
		light.set_color(0.20, 0.65, 0.20)
		light.attach(src)

		spawn (5)
			net_id = generate_net_id(src)

			if (!data_link)
				var/turf/T = get_turf(src)
				var/obj/machinery/power/data_terminal/test_link = locate() in T
				if (test_link && !test_link.is_valid_master(test_link.master))
					data_link = test_link
					data_link.master = src

			update_icon()
		return
/*
	Del()
		if (scan_beam)
			qdel(scan_beam)

		..()
*/
	disposing()
		if (scan_beam)
			scan_beam.dispose()
			scan_beam = null
		if (data_link)
			data_link.master = null
			data_link = null

		..()

	attack_hand(mob/user as mob)
		if (..() || (stat & (NOPOWER|BROKEN)))
			return

		user.machine = src

		var/dat = "<html><head><title>IR Detector - \[[detector_id]]</title></head><body>"

		dat += "Status: "
		switch (state)
			if (0)
				dat += "<strong>INACTIVE</strong>"
			if (1)
				dat += "<strong>IDLE</strong>"
			if (2)
				dat += "<strong>ON GUARD</strong>"
			if (3)
				dat += "<strong>ALERTED</strong>"
			else
				dat += "<strong>ERROR</strong>"

		var/readout_color = "#000000"
		var/readout = "ERROR"
		if (src.host_id)
			readout_color = "#33FF00"
			readout = "OK CONNECTION"
		else
			readout_color = "#F80000"
			readout = "NO CONNECTION"

		dat += "<br>Host Connection: "
		dat += "<table border='1' style='background-color:[readout_color]'><tr><td><font color=white>[readout]</font></td></tr></table><br>"

		dat += "<a href='?src=\ref[src];reset=1'>Reset Connection</a><br>"

		if (panel_open)
			dat += net_switch_html()

		user << browse(dat,"window=secdetector;size=245x302")
		onclose(user,"secdetector")
		return

	Topic(href, href_list)
		if (..())
			return

		usr.machine = src

		if (href_list["reset"])
			if (last_reset && (last_reset + NETWORK_MACHINE_RESET_DELAY >= world.time))
				return

			if (!host_id)
				return

			last_reset = world.time
			var/rem_host = src.host_id ? src.host_id : src.old_host_id
			src.host_id = null
			old_host_id = null
			post_status(rem_host, "command","term_disconnect")
			spawn (5)
				post_status(rem_host, "command","term_connect","device",device_tag)

			updateUsrDialog()
			return

		add_fingerprint(usr)
		return

	process()
		if (stat & BROKEN)
			return
		power_usage = max(20, 20*state)
		..()
		if (stat & NOPOWER)
			return
		use_power(power_usage)

		if (active_time > 0)
			active_time--
			if (!active_time)
				//state = online
				update_icon(online)

		switch (state)
			if (0)
				if (scan_beam)
					//qdel(scan_beam)
					scan_beam.dispose()
			if (1)
				if (!scan_beam)
					var/turf/beamTurf = get_step(src, dir)
					if (!istype(beamTurf) || beamTurf.density)
						return
					scan_beam = new /obj/beam/ir_beam(beamTurf, setup_beam_length)
					scan_beam.master = src
					scan_beam.dir = dir

				return
			if (2)
				for (var/mob/living/C in view(7,src))
					if (C.stat)
						continue

					if (assess_threat(C))
						state = 3
						active_time = setup_alerted_time

						if (src.host_id)
							src.post_status(src.host_id,"command","term_message","data","command=statechange&state=alert")

						update_icon(3)
						playsound(loc, "sound/machines/whistlealert.ogg", 50, 1)
						return

				return

		return

	receive_signal(signal/signal)
		if ((stat & (NOPOWER|BROKEN)) || !data_link)
			return
		if (!signal || !net_id || signal.encryption)
			return

		if (signal.transmission_method != TRANSMISSION_WIRE) //Wired comms only.
			return

		var/target = signal.data["sender"]

		if (signal.data["address_1"] != net_id)
			if ((signal.data["address_1"] == "ping") && ((signal.data["net"] == null) || ("[signal.data["net"]]" == "[net_number]")) && signal.data["sender"])
				spawn (5)
					post_status(target, "command", "ping_reply", "device", device_tag, "netid", net_id, "net", "[net_number]")

			return

		var/sigcommand = lowertext(signal.data["command"])
		if (!sigcommand || !signal.data["sender"])
			return

		switch(sigcommand)
			if ("term_connect") //Terminal interface stuff.
				if (target == src.host_id)

					src.host_id = null
					updateUsrDialog()
					spawn (3)
						post_status(target, "command","term_disconnect")
					return

				if (src.host_id)
					return

				timeout = initial(timeout)
				timeout_alert = 0
				src.host_id = target
				old_host_id = target
				if (signal.data["data"] != "noreply")
					post_status(target, "command","term_connect","data","noreply","device",device_tag)
				updateUsrDialog()
				spawn (2) //Sign up with the driver (if a mainframe contacted us)
					post_status(target,"command","term_message","data","command=register&data=[detector_id]")
				return

			if ("term_message","term_file")
				if (target != src.host_id) //Huh, who is this?
					return

				var/list/data = params2list(signal.data["data"])
				if (!data)
					return

				switch(lowertext(data["command"]))
					if ("activate")
						online = 1
						update_icon(max(1, state))

					if ("deactivate")
						online = 0
						active_time = 0
						update_icon(0)


				return

			if ("term_ping")
				if (target != src.host_id)
					return
				if (signal.data["data"] == "reply")
					post_status(target, "command","term_ping")
				timeout = initial(timeout)
				timeout_alert = 0
				return

			if ("term_disconnect")
				if (target == src.host_id)
					src.host_id = null
				timeout = initial(timeout)
				timeout_alert = 0
				updateUsrDialog()
				return

		return

	ex_act(severity)
		switch(severity)
			if (1.0)
				qdel(src)
				return
			if (2.0)
				if (prob(50))
					stat |= BROKEN
					update_icon(0)
			if (3.0)
				if (prob(25))
					stat |= BROKEN
					update_icon(0)
			else
		return

	power_change()
		if (powered(ENVIRON))
			stat &= ~NOPOWER
		else
			stat |= NOPOWER

		update_icon(state)

	proc
		update_icon(var/newState = 1)
			if (stat & (NOPOWER|BROKEN))
				light.disable()
				icon_state = "secdetector-p"
				if (scan_beam)
					//qdel(scan_beam)
					scan_beam.dispose()
				state = online
				return

			var/change = (state != newState)
			state = newState

			icon_state = "secdetector[state]"
			switch (state)
				if (2 to 3)
					light.set_brightness(state == 2 ? active_brightness : alert_brightness)
					light.enable()
				if (1)
					light.disable()
					if (src.host_id && change)
						src.post_status(src.host_id,"command","term_message","data","command=statechange&state=idle")
				if (0)
					light.disable()
					if (src.host_id && change)
						src.post_status(src.host_id,"command","term_message","data","command=statechange&state=inactive")

			return

		beam_crossed() //Called when anything solid crosses the beam, places us into the alert state.
			if (state != 1)
				return
			//qdel(scan_beam)
			if (scan_beam)
				scan_beam.dispose()
			active_time = setup_active_time
			update_icon(2)
			if (src.host_id)
				src.post_status(src.host_id,"command","term_message","data","command=statechange&state=onguard")
			playsound(loc, "sound/machines/whistlebeep.ogg", 50, 1)
			return

		assess_threat(mob/living/threat as mob) //Default scanners just check for humans without proper access and aliens.

			if (issilicon(threat))
				return FALSE

			if (ismonkey(threat))
				return FALSE

			if (!ishuman(threat))
				return TRUE

			var/mob/living/carbon/human/humanThreat = threat
			if (humanThreat.wear_id)
				if (area_access in humanThreat.wear_id:access)
					return FALSE

			return TRUE

/obj/beam
	var/obj/beam/next
	var/limit = 48

	dir = 2
	layer = NOLIGHT_EFFECTS_LAYER_BASE
	anchored = 1.0
	flags = TABLEPASS

	disposing()
		if (next)
			next.dispose()
			next = null

	Bumped()
		hit()
		return

	HasEntered(atom/movable/AM as mob|obj)
		if (istype(AM, /obj/beam) || istype(AM, /obj/critter/aberration))
			return
		spawn ( 0 )
			hit(AM)
			return
		return

	proc
		hit(atom/movable/AM as mob|obj)

		generate_next()
			if (limit < 1)
				return

			var/turf/nextTurf = get_step(src, dir)
			if (istype(nextTurf))
				if (nextTurf.density)
					return

				next = new type(nextTurf, limit-1)
				//next.master = master
				next.dir = dir
				for (var/atom/movable/hitAtom in nextTurf)
					if (hitAtom.density && !hitAtom.anchored)
						hit(hitAtom)

					continue
			return

//Infrared beam for secdetector
/obj/beam/ir_beam
	name = "infrared beam"
	desc = "A beam of infrared light."
	icon = 'icons/obj/projectiles.dmi'
	icon_state = "ibeam"
	invisibility = 2
	dir = 2
	//var/obj/beam/ir_beam/next = null
	var/obj/machinery/networked/secdetector/master = null
	//var/limit = 24
	anchored = 1.0
	flags = TABLEPASS

	New(location, newLimit)
		..()
		if (newLimit != null)
			limit = newLimit
		spawn (3)
			generate_next()
		return
/*
	Del()
		if (next)
			qdel(next)

		..()
*/
	disposing()

		master = null

		..()


	HasEntered(atom/movable/AM as mob|obj)
		if (isobserver(AM) || isintangible(AM)) return
		if (istype(AM, /obj/beam))
			return
		spawn ( 0 )
			hit()
			return
		return

	hit()
		if (istype(master))
			master.beam_crossed()
		//dispose()
		dispose()
		return

	generate_next()
		if (limit < 1)
			return

		var/turf/nextTurf = get_step(src, dir)
		if (istype(nextTurf))
			if (nextTurf.density)
				return

			next = new /obj/beam/ir_beam(nextTurf, limit-1)
			next:master = master
			next.dir = dir
		return

//Rather fancy science emitter gizmo
/obj/machinery/networked/h7_emitter
	name = "HEPT emitter"
	desc = "An incredibly complex and dangerous analysis tool that generates a particle-transposition beam via applied use of telecrystal properties."
	icon_state = "heptemitter0"
	device_tag = "PNET_HEPT_EMIT"
	dir = NORTH

	var/obj/beam/h7_beam/beam = null
	var/list/telecrystals[5]
	var/crystalCount = 0
	power_usage = 0

	var/setup_beam_length = 48

	New()
		..()

		spawn (5)
			net_id = generate_net_id(src)

			if (!data_link)
				var/turf/T = get_turf(src)
				var/obj/machinery/power/data_terminal/test_link = locate() in T
				if (test_link && !test_link.is_valid_master(test_link.master))
					data_link = test_link
					data_link.master = src

			update_icon()
		return
/*
	Del()
		if (beam)
			qdel(beam)

		..()
*/
	disposing()
		if (beam)
			beam.dispose()
			beam = null

		if (data_link)
			data_link.master = null
			data_link = null

		for (var/obj/item/I in telecrystals)
			I.set_loc(loc)

		telecrystals.len = 0
		..()

	attackby(obj/item/W as obj, mob/user as mob)
		if (istype(W, /obj/item/raw_material/telecrystal))
			return attack_hand(user)
		else if (istype(W, /obj/item/screwdriver))
			playsound(loc, "sound/items/Screwdriver.ogg", 50, 1)
			boutput(user, "You [panel_open ? "secure" : "unscrew"] the maintenance panel.")
			panel_open = !panel_open
			updateUsrDialog()
			return
		else
			..()
		return

	attack_hand(mob/user as mob)
		if (..() || (stat & (NOPOWER|BROKEN)))
			return

		user.machine = src

		var/dat = "<html><head><title>HEPT Emitter</title></head><body><hr><center>Emission Crystals<br>"

		if (!telecrystals)
			telecrystals = new/list(5)

		if (beam)
			dat += "<em>Panel is locked while active</em><br><table border='1'><tr>"
		else
			dat += "<table border='1'><tr>"

		for (var/i = 1, i <= telecrystals.len, i++)
			if (beam)

				if (isnull(telecrystals[i]))
					dat += "<td style='background-color:#F80000'><font color=white>-----<font></td>"
				else
					dat += "<td style='background-color:#33FF00'><font color=white>+++++<font></td>"
			else
				if (isnull(telecrystals[i]))
					dat += "<td style='background-color:#F80000'><font color=white><a href='?src=\ref[src];insert=[i]'>-----</a><font></td>"
				else
					dat += "<td style='background-color:#33FF00'><font color=white><a href='?src=\ref[src];eject=[i]'>EJECT</a><font></td>"

		var/readout_color = "#000000"
		var/readout = "ERROR"
		if (src.host_id)
			readout_color = "#33FF00"
			readout = "OK CONNECTION"
		else
			readout_color = "#F80000"
			readout = "NO CONNECTION"

		dat += "</tr></table></center><hr><br>Host Connection: "
		dat += "<table border='1' style='background-color:[readout_color]'><tr><td><font color=white>[readout]</font></td></tr></table><br>"

		dat += "<a href='?src=\ref[src];reset=1'>Reset Connection</a><br>"

		if (panel_open)
			dat += net_switch_html()

		user << browse(dat,"window=h7emitter;size=285x302")
		onclose(user,"h7emitter")
		return

	Topic(href, href_list)
		if (..())
			return

		usr.machine = src
		add_fingerprint(usr)

		if (href_list["insert"])
			if (beam)
				boutput(usr, "<span style=\"color:red\">The panel is locked.</span>")
				return

			var/targetSlot = round(text2num(href_list["insert"]))
			if (!targetSlot || (targetSlot < 1) || (targetSlot > telecrystals.len))
				return

			if (telecrystals[targetSlot] != null)
				return

			var/obj/item/I = usr.equipped()
			if (istype(I, /obj/item/raw_material/telecrystal))
				usr.drop_item()
				I.set_loc(src)
				telecrystals[targetSlot] = I
				crystalCount = min(crystalCount + 1, telecrystals.len)
				boutput(usr, "<span style=\"color:blue\">You insert [I] into the slot.</span>")

			updateUsrDialog()
			return

		else if (href_list["eject"])
			if (beam)
				boutput(usr, "<span style=\"color:red\">The panel is locked.</span>")
				return

			var/targetCrystal = round(text2num(href_list["eject"]))
			if (!targetCrystal || (targetCrystal < 1) || (targetCrystal > telecrystals.len))
				return

			var/obj/item/toEject = telecrystals[targetCrystal]
			if (toEject)
				telecrystals[targetCrystal] = null
				crystalCount = max(crystalCount - 1, 0)
				toEject.set_loc(get_turf(src))
				boutput(usr, "<span style=\"color:blue\">You remove [toEject] from the slot.</span>")

			updateUsrDialog()
			return

		else if (href_list["reset"])
			if (last_reset && (last_reset + NETWORK_MACHINE_RESET_DELAY >= world.time))
				return

			if (!host_id)
				return

			last_reset = world.time
			var/rem_host = src.host_id ? src.host_id : src.old_host_id
			src.host_id = null
			old_host_id = null
			post_status(rem_host, "command","term_disconnect")
			spawn (5)
				post_status(rem_host, "command","term_connect","device",device_tag)

			updateUsrDialog()
			return

		add_fingerprint(usr)
		return

	process()
		if (stat & BROKEN)
			return
		power_usage = 200 * crystalCount
		..()
		if (stat & NOPOWER)
			return

		use_power(power_usage)

		return

	receive_signal(signal/signal)
		if (stat & (NOPOWER|BROKEN) || !data_link)
			return
		if (!signal || !net_id || signal.encryption)
			return

		if (signal.transmission_method != TRANSMISSION_WIRE)
			return

		var/target = signal.data["sender"]

		if (signal.data["address_1"] != net_id)
			if ((signal.data["address_1"] == "ping") && ((signal.data["net"] == null) || ("[signal.data["net"]]" == "[net_number]")) && signal.data["sender"])
				spawn (5)
					post_status(target, "command", "ping_reply", "device", device_tag, "netid", net_id, "net", "[net_number]")

			return

		var/sigcommand = lowertext(signal.data["command"])
		if (!sigcommand || !signal.data["sender"])
			return

		switch(sigcommand)
			if ("term_connect")
				if (target == src.host_id)

					src.host_id = null
					updateUsrDialog()
					spawn (3)
						post_status(target, "command","term_disconnect")
					return

				if (src.host_id)
					return

				timeout = initial(timeout)
				timeout_alert = 0
				src.host_id = target
				old_host_id = target
				if (signal.data["data"] != "noreply")
					post_status(target, "command","term_connect","data","noreply","device",device_tag)
				updateUsrDialog()
				spawn (2) //Sign up with the driver (if a mainframe contacted us)
					post_status(target,"command","term_message","data","command=register&data=[isnull(beam) ? "0" : "1"]")
				return

			if ("term_message","term_file")
				if (target != src.host_id)
					return

				var/list/data = params2list(signal.data["data"])
				if (!data)
					return

				switch(lowertext(data["command"]))
					if ("activate")
						if (!beam && generate_beam())
							post_status(target,"command","term_message","data","command=ack")
						else
							post_status(target,"command","term_message","data","command=nack")

					if ("deactivate")
						if (beam)
							//qdel(beam)
							beam.dispose()
						post_status(target,"command","term_message","data","command=ack")

				return

			if ("term_ping")
				if (target != src.host_id)
					return
				if (signal.data["data"] == "reply")
					post_status(target, "command","term_ping")
				timeout = initial(timeout)
				timeout_alert = 0
				return

			if ("term_disconnect")
				if (target == src.host_id)
					src.host_id = null
				timeout = initial(timeout)
				timeout_alert = 0
				updateUsrDialog()
				return

		return

	power_change()
		if (powered())
			stat &= ~NOPOWER
			update_icon()
		else
			spawn (rand(0, 15))
				stat |= NOPOWER
				update_icon()

	ex_act(severity)
		switch(severity)
			if (1.0)
				//dispose()
				dispose()
				return
			if (2.0)
				if (prob(50))
					stat |= BROKEN
					update_icon()
			if (3.0)
				if (prob(25))
					stat |= BROKEN
					update_icon()
			else
		return

	proc
		update_icon()
			if (stat & (NOPOWER|BROKEN))
				icon_state = "heptemitter-p"
				if (beam)
					//qdel(beam)
					beam.dispose()
			else
				icon_state = "heptemitter[beam ? "1" : "0"]"
			return

		generate_beam()
			if ((stat & (NOPOWER|BROKEN)) || !crystalCount)
				return FALSE

			if (!beam)
				var/turf/beamTurf = get_step(src, dir)
				if (!istype(beamTurf) || beamTurf.density)
					return FALSE
				beam = new /obj/beam/h7_beam(beamTurf, setup_beam_length, crystalCount)
				beam.master = src
				beam.dir = dir
				for (var/atom/movable/hitAtom in beamTurf)
					if (hitAtom.density && !hitAtom.anchored)
						beam.hit(hitAtom)

					continue
			else
				beam.update_power(crystalCount)

			update_icon()
			updateUsrDialog()
			return TRUE

//Deathbeam for preceding death emitter
/obj/beam/h7_beam
	name = "energy beam"
	desc = "A rather threatening beam of photons!"
	icon = 'icons/obj/projectiles.dmi'
	icon_state = "h7beam1"
	dir = 2
	layer = NOLIGHT_EFFECTS_LAYER_BASE
	var/power = 1 //How dangerous is this beam, anyhow? 1-5. 1-3 cause minor teleport hops and radiation damage, 4 tends to deposit people in a place separate from their stuff (or organs), and 5 tears their molecules apart
	//var/obj/beam/h7_beam/next = null
	var/obj/machinery/networked/h7_emitter/master = null
	limit = 48
	anchored = 1.0
	flags = TABLEPASS
	var/light/light

	New(location, newLimit, newPower)
		..()
		light = new /light/point
		light.attach(src)
		light.set_color(0.28, 0.07, 0.58)
		light.set_brightness(min(power, 3) / 5)
		light.set_height(0.5)
		light.enable()

		if (newLimit != null)
			limit = newLimit
		if (newPower != null)
			power = newPower
		icon_state = "h7beam[min(power, 5)]"
		spawn (2)
			generate_next()
		return

	disposing()
		if (master)
			if (master.beam == src)
				master.beam = null
			master = null
		..()
/*
	Del()
		if (next)
			qdel(next)

		..()

	disposing()
		if (next)
			next.dispose()
			next = null

		if (master)
			if (master.beam == src)
				master.beam = null
			master = null
		..()

	Bumped()
		hit()
		return

	HasEntered(atom/movable/AM as mob|obj)
		if (istype(AM, /obj/beam) || istype(AM, /obj/critter/aberration))
			return
		spawn ( 0 )
			hit(AM)
			return
		return
*/
	proc
		update_power(var/newPower)
			if (!newPower)
				return

			power = max(1, newPower)
			if (next)
				next:update_power(newPower)
			return

		telehop(atom/movable/hopAtom as mob|obj, hopOffset=1, varyZ=0)
			var/targetZLevel = hopAtom.z
			if (varyZ)
				targetZLevel = pick(1,3,4,5)

			hopOffset *= 3

			var/turf/lowerLeft = locate( max(hopAtom.x - hopOffset, 1), max(1, hopAtom.y - hopOffset), targetZLevel)
			var/turf/upperRight = locate( min( world.maxx, hopAtom.x + hopOffset), min(world.maxy, hopAtom.y + hopOffset), targetZLevel)

			if (!lowerLeft || !upperRight)
				return

			var/list/hopTurfs = block(lowerLeft, upperRight)
			if (!hopTurfs.len)
				return

			playsound(hopAtom.loc, "warp", 50, 1)
			do_teleport(hopAtom, pick(hopTurfs), 0)
			return

	hit(atom/movable/AM as mob|obj)
		if (istype(AM, /mob/living))
			var/mob/living/hitMob = AM

			switch (power)
				if (1 to 3)
					//telehop + radiation
					if (iscarbon(hitMob))
						hitMob.irradiate(100)
						hitMob.weakened = max(hitMob.weakened, 2)
					telehop(hitMob, power, power > 2)
					return

				if (4)
					//big telehop + might leave parts behind.
					if (iscarbon(hitMob))
						hitMob.irradiate(100)

						random_brute_damage(hitMob, 25)
						hitMob.weakened = max(hitMob.weakened, 2)
						if (ishuman(hitMob) && prob(25))
							var/mob/living/carbon/human/hitHuman = hitMob
							if (hitHuman.organHolder && hitHuman.organHolder.brain)
								var/obj/item/organ/brain/B = hitHuman.organHolder.drop_organ("Brain", hitHuman.loc)
								telehop(B, 2, 0)
								boutput(hitHuman, "<span style=\"color:red\"><strong>You seem to have left something...behind.</strong></span>")

						telehop(hitMob, power, 1)
					return

				else
					//Are they a human wearing the obsidian crown?
					if (ishuman(hitMob) && istype(hitMob:head, /obj/item/clothing/head/void_crown))
						var/obj/source = locate(/obj/dfissure_from)
						if (!source)
							telehop(AM, 5, 1)
							return

						var/area/sourceArea = get_area(source)
						sourceArea.Entered(AM, AM.loc)

						AM.set_loc(get_turf(source))
						return

					//death!!
					hitMob.vaporize()
					return
		else if (istype(AM, /obj) && !istype(AM, /obj/effects))
			telehop(AM, power, power > 2)
			return


		return

	generate_next()
		if (limit < 1)
			return

		var/turf/nextTurf = get_step(src, dir)
		if (istype(nextTurf))
			if (nextTurf.density)
				return

			next = new /obj/beam/h7_beam(nextTurf, limit-1, power)
			next:master = master
			next.dir = dir
			for (var/atom/movable/hitAtom in nextTurf)
				if (hitAtom.density && !hitAtom.anchored)
					hit(hitAtom)

				continue
		return

//Generic test apparatus
/obj/machinery/networked/test_apparatus
	name = "Generic Testing Apparatus"
	desc = "A large device designed to facilitate...some manner... of analysis."
	icon_state = "pathmanip0"

	var/active = 0 //If this device is currently activated in some manner. The device will assume the icon state of setup_base_icon_state + active (1 : 0) when the icon is updated.
	var/session = null

	var/setup_base_icon_state = "pathmanip"
	var/setup_test_id = "GENERIC" //Simple test identifier, sent upon mainframe connection.
	var/setup_device_name = "Testing Apparatus" //Device name to appear in html interface
	var/setup_capability_value = "E" //E for Enactor (provides a stimulus), S for Sensor (Records stimulus), or B for both.
	//Don't forget to give devices unique device_tag values of the form "PNET_XXXXXXXXX"
	device_tag = "PNET_TEST_APPT" //This is the device tag used to interface with the mainframe GTPIO driver.

	power_usage = 200
	var/dragload = 0 // can we click-drag a machinery-type artifact into this machine?

	New()
		..()

		spawn (5)
			net_id = generate_net_id(src)

			if (!data_link)
				var/turf/T = get_turf(src)
				var/obj/machinery/power/data_terminal/test_link = locate() in T
				if (test_link && !test_link.is_valid_master(test_link.master))
					data_link = test_link
					data_link.master = src

			update_icon()
		return

	attackby(obj/item/W as obj, mob/user as mob)
		if (istype(W, /obj/item/raw_material/telecrystal))
			return attack_hand(user)

		else if (istype(W, /obj/item/screwdriver))
			playsound(loc, "sound/items/Screwdriver.ogg", 50, 1)
			boutput(user, "You [panel_open ? "secure" : "unscrew"] the maintenance panel.")
			panel_open = !panel_open
			updateUsrDialog()
			return
		else
			..()
		return

	attack_hand(mob/user as mob)
		if (..() || (stat & (NOPOWER|BROKEN)))
			return

		user.machine = src

		var/dat = "<html><head><title>[setup_device_name]</title></head><body>"

		dat += "<hr>[return_html_interface()]<hr>"

		var/readout_color = "#000000"
		var/readout = "ERROR"
		if (src.host_id)
			readout_color = "#33FF00"
			readout = "OK CONNECTION"
		else
			readout_color = "#F80000"
			readout = "NO CONNECTION"

		dat += "<br>Host Connection: "
		dat += "<table border='1' style='background-color:[readout_color]'><tr><td><font color=white>[readout]</font></td></tr></table><br>"

		dat += "<a href='?src=\ref[src];reset=1'>Reset Connection</a><br>"

		if (panel_open)
			dat += net_switch_html()

		user << browse(dat,"window=testap\ref[src];size=285x302")
		onclose(user,"testap\ref[src]")
		return

	MouseDrop_T(atom/movable/O as mob|obj, mob/user as mob)
		if (!istype(O,/obj) || O.anchored) return
		if (get_dist(src,O) > 1 || !isturf(O.loc)) return
		if (dragload)
			if (contents.len)
				boutput(user, "<span style=\"color:red\">[name] is already loaded!</span>")
				return
			visible_message("<strong>[user.name]</strong> loads [O] into [name]!")
			O.set_loc(src)
			update_icon()
		else return

	MouseDrop(obj/over_object as obj, src_location, over_location)
		var/mob/M = usr
		if (!istype(over_object, /turf)) return
		if (!dragload) return
		if (get_dist(src,over_object) > 1) return
		if ((get_dist(src, M) > 1) || M.stat) return
		if (active)
			boutput(usr, "<span style=\"color:red\">You can't unload it while it's active!</span>")
			return
		for (var/obj/O in contents) O.set_loc(over_object)
		visible_message("<strong>[M.name]</strong> unloads [name]!")
		update_icon()

	Topic(href, href_list)
		if (..())
			return

		usr.machine = src
		add_fingerprint(usr)

		interface_topic(href_list)

		if (href_list["reset"])
			if (last_reset && (last_reset + NETWORK_MACHINE_RESET_DELAY >= world.time))
				return

			if (!host_id)
				return

			last_reset = world.time
			var/rem_host = src.host_id ? src.host_id : src.old_host_id
			src.host_id = null
			old_host_id = null
			post_status(rem_host, "command","term_disconnect")
			spawn (5)
				post_status(rem_host, "command","term_connect","device",device_tag)

			updateUsrDialog()
			return

		add_fingerprint(usr)
		return

	process()
		if (stat & BROKEN)
			return TRUE
		..()
		if (stat & NOPOWER)
			return TRUE

		use_power(200)

		return FALSE

	receive_signal(signal/signal)
		if (stat & (NOPOWER|BROKEN) || !data_link)
			return
		if (!signal || !net_id || signal.encryption)
			return

		if (signal.transmission_method != TRANSMISSION_WIRE)
			return

		var/target = signal.data["sender"]

		if (signal.data["address_1"] != net_id)
			if ((signal.data["address_1"] == "ping") && ((signal.data["net"] == null) || ("[signal.data["net"]]" == "[net_number]")) && signal.data["sender"])
				spawn (5)
					post_status(target, "command", "ping_reply", "device", device_tag, "netid", net_id, "net", "[net_number]")

			return

		var/sigcommand = lowertext(signal.data["command"])
		if (!sigcommand || !signal.data["sender"])
			return

		switch(sigcommand)
			if ("term_connect")
				if (target == src.host_id)

					src.host_id = null
					updateUsrDialog()
					spawn (3)
						post_status(target, "command","term_disconnect")
					return

				if (src.host_id)
					return

				timeout = initial(timeout)
				timeout_alert = 0
				src.host_id = target
				old_host_id = target
				if (signal.data["data"] != "noreply")
					post_status(target, "command","term_connect","data","noreply","device",device_tag)
				updateUsrDialog()
				spawn (2) //Sign up with the driver (if a mainframe contacted us)
					message_host("command=register&id=[setup_test_id]&data=[isnull(active) ? "0" : "1"]&capability=[setup_capability_value]")
				return

			if ("term_message","term_file")
				if (target != src.host_id)
					return

				var/list/data = params2list(signal.data["data"])
				if (!data)
					return

				if (data["session"])
					session = data["session"]
				else
					session = null

				message_interface(data)
				return

			if ("term_ping")
				if (target != src.host_id)
					return
				if (signal.data["data"] == "reply")
					post_status(target, "command","term_ping")
				timeout = initial(timeout)
				timeout_alert = 0
				return

			if ("term_disconnect")
				if (target == src.host_id)
					src.host_id = null
				timeout = initial(timeout)
				timeout_alert = 0
				updateUsrDialog()
				return

		return

	power_change()
		if (powered())
			stat &= ~NOPOWER
			update_icon()
		else
			spawn (rand(0, 15))
				stat |= NOPOWER
				update_icon()

	ex_act(severity)
		switch(severity)
			if (1.0)
				//dispose()
				dispose()
				return
			if (2.0)
				if (prob(50))
					stat |= BROKEN
					update_icon()
			if (3.0)
				if (prob(25))
					stat |= BROKEN
					update_icon()
			else
		return

	proc
		update_icon()
			if (stat & (NOPOWER|BROKEN))
				icon_state = "[setup_base_icon_state]-p"
			else
				icon_state = "[setup_base_icon_state][active ? "1" : "0"]"
			return

		//Generate html interface to appear in interaction window above the host connection controls
		return_html_interface()
			return

		//The accompanying Topic to go with the html interface. Mob proximity and the reset input are already handled outside of this.
		interface_topic(list/href_list)
			return

		//Mainframe terminal message interface. Typically, a command is contained within the "command" key in the list, all values as strings.
		//Though this will generally be used by an appropriate mainframe driver, it IS possible for players to connect directly and issue their own commands
		//over the terminal interface.
		//Example response to "read" command:
		//	message_host("command=read&data=hello&format=sread")
		//Example response to "info" command:
		//	message_host("command=info&id=[setup_test_id]&capability=[setup_capability_value]&status=[active ? "1" : "0"]&valuelist=Power-Charge")
		message_interface(var/list/packetData)
			return

		//Send a terminal message to our host device
		message_host(var/message, var/computer/file/file)
			if (!src.host_id || !message)
				return

			if (file)
				if (session)
					message += "&session=[session]"
				src.post_file(src.host_id,"data",message, file)
			else
				if (session)
					message += "&session=[session]"
				src.post_status(src.host_id,"command","term_message","data",message)

			return

//A test enactor that fires small objects at things. Things like artifacts.
/obj/machinery/networked/test_apparatus/pitching_machine
	name = "Automatic Pitching Machine"
	desc = "A large computer-controlled pitching machine."
	icon_state = "pitching0"

	setup_base_icon_state = "pitching"
	setup_test_id = "PITCHER"
	setup_device_name = "Pitching Machine"
	setup_capability_value = "E"

	var/throw_strength = 50
	var/setup_max_objects = 10

	return_html_interface()
		return "<strong>Pitching:</strong> [active ? "YES" : "NO"]<br><br><strong>Strength:</strong> [throw_strength]%"

	message_interface(var/list/packetData)
		switch (lowertext(packetData["command"]))
			if ("info")
				message_host("command=info&id=[setup_test_id]&capability=[setup_capability_value]&status=[active ? "1" : "0"]&valuelist=Power")

			if ("status")
				message_host("command=status&data=[active ? "1" : "0"]")

			if ("poke")
				if (lowertext(packetData["field"]) != "power")
					message_host("command=nack")
					return

				var/newPower = text2num(packetData["value"])
				if (!isnum(newPower) || (newPower < 1) || (newPower > 100))
					message_host("command=nack")
					return

				throw_strength = round(newPower)
				message_host("command=ack")

			if ("peek")
				if (lowertext(packetData["field"]) != "power")
					message_host("command=nack")
					return

				message_host("command=peeked&field=power&value=[throw_strength]")

			if ("activate")
				if (contents.len)
					active = contents.len
					message_host("command=ack")
					update_icon()
				else
					message_host("command=nack")

			if ("pulse")
				var/duration = text2num(packetData["duration"])
				if (isnum(duration))
					duration = round(max(1, min(duration, 255)))
				else
					active = 0
					message_host("command=nack")
					return

				active = duration
				message_host("command=ack")
				update_icon()

			if ("deactivate")
				active = 0
				message_host("command=ack")
				update_icon()

		return

	process()
		if (..())
			return
		if (active)
			if (contents.len)
				active--
				var/atom/movable/to_toss = pick(contents)
				if (istype(to_toss))
					to_toss.set_loc(loc)
					visible_message("<strong>[name]</strong> launches [to_toss]!")
					playsound(loc, "sound/effects/syringeproj.ogg", 50, 1)
					to_toss.throw_at(get_edge_target_turf(src, dir), throw_strength, (throw_strength/50))

				if (!active)
					visible_message("<strong>[name]</strong> pings.")
					active = 0
					playsound(src, "sound/machines/buzz-two.ogg", 50, 1)
					update_icon()
				return

			visible_message("<strong>[name]</strong> pings.")
			active = 0
			playsound(src, "sound/machines/chime.ogg", 50, 1)
			update_icon()

		return

	attackby(var/obj/item/I, mob/user)
		if (stat & (NOPOWER|BROKEN))
			return
		if (istype(I, /obj/item/grab))
			return

		if (I.w_class < 4)
			if (contents.len < setup_max_objects)
				user.drop_item()
				I.set_loc(src)
				user.visible_message("<strong>[user]</strong> loads [I] into [name]!")
				return
			else
				boutput(user, "There is no room left for that!")
				return
		else
			boutput(user, "That is far too big to fit!")
			return

		return ..()

/obj/machinery/networked/test_apparatus/impact_pad
	name = "Impact Sensor Pad"
	desc = "A floor pad that detects the physical reactions of objects placed on it."
	icon_state = "impactpad0"
	density = 0

	setup_base_icon_state = "impactpad"
	setup_test_id = "IMPACTPAD"
	setup_device_name = "Impact Pad"
	setup_capability_value = "S"

	var/list/sensed = list("0","0")

	return_html_interface()
		return "<strong>Detecting:</strong> [active ? "YES" : "NO"]<br><br><strong>Stand Extended:</strong> [density ? "YES" : "NO"]"

	message_interface(var/list/packetData)
		switch (lowertext(packetData["command"]))
			if ("info")
				message_host("command=info&id=[setup_test_id]&capability=[setup_capability_value]&status=[active ? "1" : "0"]&valuelist=Stand&readinglist=Vibration Amplitude-VF,Vibration Frequency-VPS")

			if ("status")
				message_host("command=status&data=[active ? "1" : "0"]")

			if ("poke")
				if (lowertext(packetData["field"]) != "stand")
					message_host("command=nack")
					return

				var/standval = text2num(packetData["value"])
				if (standval < 0 || standval > 1)
					message_host("command=nack")
					return

				if (standval == 1 && density == 0)
					if (!locate(/obj/item/) in src.loc.contents)
						visible_message("<strong>[name]</strong> extends its stand.")
						density = 1
						setup_base_icon_state = "impactstand"
						flick("impactpad-extend",src)
						update_icon()
						playsound(loc, "sound/effects/pump.ogg", 50, 1)
					else
						visible_message("<span style=\"color:red\"><strong>[name]</strong> clanks and clatters noisily!</span>")
						playsound(loc, "sound/effects/clang.ogg", 50, 1)
					message_host("command=ack")
				else if (standval == 0 && density == 1)
					visible_message("<strong>[name]</strong> retracts its stand.")
					density = 0
					setup_base_icon_state = "impactpad"
					flick("impactstand-retract",src)
					update_icon()
					playsound(loc, "sound/effects/pump.ogg", 50, 1)
					message_host("command=ack")
				else
					message_host("command=ack")
					return

			if ("peek")
				if (lowertext(packetData["field"]) != "stand")
					message_host("command=nack")
					return

				message_host("command=peeked&field=stand&value=[density]")

			if ("read")
				if (sensed[1] == null || sensed[2] == null)
					message_host("command=nack")
				else
					message_host("command=read&data=[sensed[1]],[sensed[2]]")
					message_host("command=ack")

		return

	attackby(var/obj/item/I, mob/user)
		if (istype(I, /obj/item/grab))
			return

		if (density)
			if (locate(/obj/item/) in src.loc.contents)
				boutput(user, "<span style=\"color:red\">There's already something on the stand!</span>")
				return
			else
				user.drop_item()
				I.set_loc(loc)
		else
			user.drop_item()
			I.set_loc(loc)

		return

	Bumped(M as mob|obj)
		if (density)
			for (var/obj/item/I in loc.contents)
				I.Bumped(M)
				if (istype(I.artifact,/artifact/) && istype(M,/obj/item))
					var/obj/item/ITM = M
					var/obj/ART = I
					impactpad_senseforce(ART, ITM)
				return

	bullet_act(var/obj/projectile/P)
		if (density)
			for (var/obj/item/I in loc.contents)
				I.bullet_act(P)
				switch (P.proj_data.damage_type)
					if (D_KINETIC,D_PIERCING,D_SLASHING)
						impactpad_senseforce_shot(I, P)
				return

	proc/impactpad_senseforce(var/obj/I, var/obj/item/M)
		if (istype(I.artifact,/artifact))
			var/artifact/ARTDATA = I.artifact
			var/stimforce = M.throwforce
			sensed[1] = stimforce * ARTDATA.react_mpct[1]
			sensed[2] = stimforce * ARTDATA.react_mpct[2]
			if (sensed[2] != 0 && ARTDATA.faults.len)
				sensed[2] += rand(ARTDATA.faults.len / 2,ARTDATA.faults.len * 2)
			var/artifact_trigger/AT = ARTDATA.get_trigger_by_string("force")
			if (AT)
				sensed[1] *= 5
				sensed[2] *= 5
		else
			sensed[1] = "???"
			sensed[2] = "0"
		visible_message("<strong>[name]</strong> registers an impact and chimes.")
		playsound(loc, "sound/machines/chime.ogg", 50, 1)

	proc/impactpad_senseforce_shot(var/obj/I, var/projectile/P)
		if (istype(I.artifact,/artifact))
			var/artifact/ARTDATA = I.artifact
			var/stimforce = P.power
			sensed[1] = stimforce * ARTDATA.react_mpct[1]
			sensed[2] = stimforce * ARTDATA.react_mpct[2]

			if (sensed[2] != 0 && ARTDATA.faults.len)
				sensed[2] += rand(ARTDATA.faults.len / 2,ARTDATA.faults.len * 2)

			var/artifact_trigger/AT = ARTDATA.get_trigger_by_string("force")
			if (AT)
				sensed[1] *= 5
				sensed[2] *= 5
		else
			sensed[1] = "???"
			sensed[2] = "0"

		visible_message("<strong>[name]</strong> registers an impact and chimes.")
		playsound(src, "sound/machines/chime.ogg", 50, 1)

/obj/machinery/networked/test_apparatus/electrobox
	name = "Electrical Testing Apparatus"
	desc = "A contained unit for exposing machinery to electrical currents."
	icon_state = "elecbox0"
	density = 1
	dragload = 1

	setup_base_icon_state = "elecbox"
	setup_test_id = "ELEC_BOX"
	setup_device_name = "Electrical Testing Apparatus"
	setup_capability_value = "B"

	var/voltage = 10 // runs from 1 to 100
	var/wattage = 1  // runs from 1 to 50
	var/timer = 0
	var/list/sensed = list("???","???","100")

	return_html_interface()
		return "<strong>Loaded:</strong> [contents.len ? "YES" : "NO"]<br><strong>Active:</strong> [active ? "YES" : "NO"]<br><br><strong>Wattage:</strong> [wattage]W<br><strong>Voltage:</strong> [voltage]V"

	update_icon()
		overlays = null
		if (contents.len)
			overlays += image('icons/obj/networked.dmi', "elecbox-doors")
		..()

	process()
		if (active && contents.len && !(stat & BROKEN))
			power_usage = wattage * voltage + 220
		else
			power_usage = 220
		if (..())
			if (active && (stat & NOPOWER))
				active = 0
			return
		if (!contents.len && active)
			active = 0
			visible_message("<strong>[name]</strong> buzzes angrily and stops operating!")
			playsound(loc, "sound/machines/buzz-two.ogg", 50, 1)
			update_icon()
			return

		if (active)
			use_power(wattage * voltage) // ???????? (voltwatts????)
			if (timer > 0)
				timer--
			if (timer == 0)
				active = 0
				timer = -1
				visible_message("<strong>[name]</strong> emits a buzz and shuts down.")
				playsound(loc, "sound/machines/buzz-sigh.ogg", 50, 1)
				update_icon()
				return
			var/current = wattage * voltage
			if (locate(/mob/living/) in contents)
				for (var/mob/living/carbon/OUCH in contents)
					OUCH.TakeDamage("All",0,current / 500)
			else
				var/obj/M = pick(contents)
				if (istype(M.artifact,/artifact))
					M.ArtifactStimulus("elec", current)

		else use_power(20)

		return

	attackby(var/obj/item/I, mob/user)
		if (stat & (NOPOWER|BROKEN))
			return
		if (istype(I, /obj/item/grab))
			return // do this later when everything else is ironed out

		if (!contents.len)
			user.drop_item()
			I.set_loc(src)
			user.visible_message("<strong>[user]</strong> loads [I] into [name]!")
			update_icon()
			return
		else
			boutput(user, "There is no room left for that!")
			return

		return ..()

	message_interface(var/list/packetData)
		switch (lowertext(packetData["command"]))
			if ("info")
				message_host("command=info&id=[setup_test_id]&capability=[setup_capability_value]&status=[active ? "1" : "0"]&valuelist=Voltage,Wattage&readinglist=Test Amps-A,Load Impedance-Ohm,Circuit Capacity-J,Interference-%")

			if ("status")
				message_host("command=status&data=[active ? "1" : "0"]")

			if ("poke")
				if (lowertext(packetData["field"]) != "voltage" && lowertext(packetData["field"]) != "wattage")
					message_host("command=nack")
					return

				var/pokeval = text2num(packetData["value"])
				if (lowertext(packetData["field"]) == "voltage")
					if (pokeval < 1 || pokeval > 100)
						message_host("command=nack")
						return
					voltage = pokeval

				if (lowertext(packetData["field"]) == "wattage")
					if (pokeval < 1 || pokeval > 50)
						message_host("command=nack")
						return
					wattage = pokeval

				message_host("command=ack")
				return

			if ("peek")
				if (lowertext(packetData["field"]) != "voltage" && lowertext(packetData["field"]) != "wattage")
					message_host("command=nack")
					return

				if (lowertext(packetData["field"]) == "voltage")
					message_host("command=peeked&field=voltage&value=[voltage]")
				else if (lowertext(packetData["field"]) == "wattage")
					message_host("command=peeked&field=wattage&value=[wattage]")

			if ("read")
				if (sensed[1] == null || sensed[2] == null || sensed[3] == null || !active)
					message_host("command=nack")
				else
					// Electrobox - returns Returned Current, Circuit Capacity, Circuit Interference
					var/current = "ERROR"
					if (wattage > 0 && voltage > 0)
						current = wattage / voltage
					message_host("command=read&data=[current],[sensed[1]],[sensed[2]],[sensed[3]]")
					message_host("command=ack")

			if ("sense")
				if (contents.len && active)
					var/obj/M = pick(contents)
					if (istype(M.artifact,/artifact))
						var/artifact/A = M.artifact
						var/current = wattage / voltage

						if (A.react_elec[1] == "equal")
							sensed[1] = voltage / current
						else
							sensed[1] = voltage / (current * A.react_elec[1])

						sensed[2] = A.react_elec[2]

						sensed[3] = A.react_elec[3]

						if (A.artitype == "eldritch")
							sensed[3] += rand(-7,7)

						for (var/artifact_fault in A.faults)
							if (prob(50))
								sensed[1] *= rand(1.5,4.0)
							else
								sensed[1] /= rand(1.5,4.0)
							sensed[3] += rand(-4,4)

						var/artifact_trigger/AT = A.get_trigger_by_string("elec")
						if (AT)
							sensed[3] *= 3
					else
						sensed[1] = "???"
						sensed[2] = "???"
						sensed[3] = "100"
				else message_host("command=nack")
				// Electrobox - returns Returned Current, Circuit Capacity, Circuit Interference

			if ("activate")
				if (contents.len && !active)
					active = 1
					timer = -1
					message_host("command=ack")
					update_icon()
				else
					message_host("command=nack")

			if ("pulse")
				var/duration = text2num(packetData["duration"])
				if (isnum(duration) && !active)
					duration = round(max(1, min(duration, 255)))
				else
					active = 0
					message_host("command=nack")
					return

				active = 1
				timer = duration
				message_host("command=ack")
				update_icon()

			if ("deactivate")
				active = 0
				timer = -1
				message_host("command=ack")
				update_icon()
		return

/obj/machinery/networked/test_apparatus/xraymachine
	name = "X-Ray Scanner"
	desc = "Performs radiography on objects to determine their structure."
	icon_state = "xray0"
	density = 1
	dragload = 1

	setup_base_icon_state = "xray"
	setup_test_id = "X_RAY"
	setup_device_name = "X-Ray Scanner"
	setup_capability_value = "B"

	var/radstrength = 1 // 1 to 10
	var/list/sensed = list("???","???","???","NO","NONE")
	// X-ray - returns Density, Structural Consistency, Structural Integrity

	return_html_interface()
		return "<strong>Loaded:</strong> [contents.len ? "YES" : "NO"]<br><strong>Active:</strong> [active ? "YES" : "NO"]<br><br>Radiation Strength:</strong> [radstrength * 10]%"

	update_icon()
		overlays = null
		if (contents.len) overlays += image('icons/obj/networked.dmi', "xray-lid")
		..()

	attackby(var/obj/item/I, mob/user)
		if (stat & (NOPOWER|BROKEN))
			return
		if (istype(I, /obj/item/grab))
			return

		if (!contents.len)
			user.drop_item()
			I.set_loc(src)
			user.visible_message("<strong>[user]</strong> loads [I] into [name]!")
			update_icon()
			return
		else
			boutput(user, "There is no room left for that!")
			return

		return ..()

	message_interface(var/list/packetData)
		switch (lowertext(packetData["command"]))
			if ("info")
				message_host("command=info&id=[setup_test_id]&capability=[setup_capability_value]&status=[active ? "1" : "0"]&valuelist=Radstrength&readinglist=Radiation Strength-%,Object Density-p,Structural Consistency-%,Structural Integrity-%,Radiation Response,Special Features of Object")

			if ("status")
				message_host("command=status&data=[active ? "1" : "0"]")

			if ("poke")
				var/pokeval = text2num(packetData["value"])
				if (lowertext(packetData["field"]) == "radstrength")
					if (pokeval < 1 || pokeval > 10)
						message_host("command=nack")
						return

					radstrength = round(pokeval)
					message_host("command=ack")
					return

				message_host("command=nack")
				return

			if ("peek")
				if (lowertext(packetData["field"]) != "radstrength")
					message_host("command=nack")
					return

				message_host("command=peeked&field=radstrength&value=[radstrength]")

			if ("read")
				if (sensed[1] == null || sensed[2] == null || sensed[3] == null || sensed[4] == null || sensed[5] == null || active)
					message_host("command=nack")
				else
					// X-ray - returns Density, Structural Consistency, Structural Integrity, Response
					message_host("command=read&data=[radstrength * 10],[sensed[1]],[sensed[2]],[sensed[3]],[sensed[4]],[sensed[5]]")
					message_host("command=ack")

			if ("sense","deactivate")
				message_host("command=nack")

			if ("activate", "pulse")
				if (contents.len && !active)
					message_host("command=ack")
					active = 1
					update_icon()
					visible_message("<strong>[name]</strong> begins to operate.")
					if (narrator_mode)
						playsound(loc, 'sound/vox/genetics.ogg', 50, 1)
					else if (prob(1))
						playsound(loc, 'sound/vox/genetics.ogg', 50, 1)
					else
						playsound(loc, 'sound/machines/genetics.ogg', 50, 1)

					if (contents.len)
						var/obj/M = pick(contents)
						if (istype(M.artifact,/artifact))
							var/artifact/A = M.artifact

							// Density
							var/density = A.react_xray[1]

							if (A.artitype == "eldritch" && prob(33))
								var/randval = rand(-2,6)
								if (prob(50))
									density *= rand(-2,6)
								else
									density /= (randval == 0 ? 1 : randval)
							if (A.artitype == "eldritch" && prob(6))
								density = 666

							sensed[1] = density

							// Structural Consistency
							var/consistency = A.react_xray[2]

							if (consistency > 85 && A.artitype == "martian")
								consistency = 85

							if (A.artitype == "eldritch" && prob(20))
								consistency *= rand(2,6)

							sensed[2] = consistency

							// Structural Integrity
							var/integrity = A.react_xray[3]

							for (var/artifact_fault in A.faults)
								integrity -= 7

							if (A.artitype == "eldritch" && prob(33))
								if (prob(50)) integrity *= rand(2,4)
								else integrity /= rand(2,4)

							if (integrity > 80 && A.artitype == "martian")
								integrity = 80

							if (integrity < 0) sensed[3] = "< 1"
							else sensed[3] = integrity

							// Radiation Response
							var/responsive = A.react_xray[4]
							if (A.artitype == "martian")
								responsive -= 3
							if (A.artitype == "eldritch" && prob(33))
								responsive += rand(-2,2)
							if (responsive <= radstrength)
								sensed[4] = "WEAK RESPONSE"
							else
								sensed[4] = "NO RESPONSE"

							var/artifact_trigger/AT = A.get_trigger_by_string("radiate")
							if (AT)
								if (sensed[4] == "WEAK RESPONSE")
									sensed[4] = "POWERFUL RESPONSE"
								else
									sensed[4] = "STRONG RESPONSE"

							// Special Features
							sensed[5] = A.react_xray[5]
							if (A.artitype == "martian")
								sensed[5] += ",ORGANIC"
							if (M.contents.len)
								sensed[5] += ",CONTAINS OTHER OBJECT"
							if (A.artitype == "eldritch" && prob(6))
								sensed[5] = "ERROR"

							M.ArtifactStimulus("radiate", radstrength)

						else
							sensed[1] = "???"
							sensed[2] = "???"
							sensed[3] = "???"
							sensed[4] = "NO"
							sensed[5] = "NONE"

					spawn (50)
						visible_message("<strong>[name]</strong> finishes working and shuts down.")
						playsound(src, "sound/machines/chime.ogg", 50, 1)
						active = 0
						update_icon()
				else
					message_host("command=nack")
		return

/obj/machinery/networked/test_apparatus/heater
	name = "Heater Plate"
	desc = "Exposes artifacts to heat and measures their reaction."
	icon_state = "heater0"
	density = 0
	var/image/heat_overlay = null

	setup_base_icon_state = "heater"
	setup_test_id = "HEATER"
	setup_device_name = "Heater Plate"
	setup_capability_value = "B"

	var/temptarget = 310  // 200 to 400
	var/temperature = 310 // the plate's actual current temperature
	var/stopattarget = 0  // pulse mode - do we automatically stop when we hit the target temp?
	var/list/sensed = list("UNKNOWN","UNKNOWN","UNKNOWN")
	// Heat Plate - returns Artifact Temp, Heat Response, Cold Response
	power_usage = 200

	New()
		..()
		heat_overlay = image('icons/obj/networked.dmi', "")

	return_html_interface()
		return "<strong>Active:</strong> [active ? "YES" : "NO"]<br><br>Target Temperature:</strong> [temptarget]K<br>Current Temperature:</strong> [temperature]K"

	update_icon()
		overlays = null
		switch(temperature)
			if (371 to INFINITY)
				heat_overlay.icon_state = "heat+3"
			if (351 to 370)
				heat_overlay.icon_state = "heat+2"
			if (331 to 350)
				heat_overlay.icon_state = "heat+1"
			if (270 to 289)
				heat_overlay.icon_state = "heat-1"
			if (250 to 269)
				heat_overlay.icon_state = "heat-2"
			if (230 to -99)
				heat_overlay.icon_state = "heat-3"
			else
				heat_overlay.icon_state = ""
		overlays += heat_overlay
		..()

	attackby(var/obj/item/I, mob/user)
		if (istype(I, /obj/item/grab))
			return

		if (locate(/obj/) in src.loc.contents)
			..()
		else
			user.drop_item()
			I.set_loc(loc)
		return

	process()
		if (active)
			power_usage = 280
		else
			power_usage = 200
		if (..())
			return

		if (active)
			use_power(80)

			if (temperature < temptarget)
				temperature += 5
			else if (temperature > temptarget)
				temperature -= 5

			if (temperature != 310)
				for (var/obj/M in loc.contents)
					if (istype(M.artifact,/artifact))
						M.ArtifactStimulus("heat", temperature)

			if (stopattarget && temperature == temptarget)
				active = 0
				visible_message("<strong>[name]</strong> reaches its target temperature and shuts down.")
				playsound(loc, "sound/machines/chime.ogg", 50, 1)
		else
			use_power(20)
			if (temperature > 310)
				temperature--
			else if (temperature < 310)
				temperature++

		update_icon()

		return

	message_interface(var/list/packetData)
		switch (lowertext(packetData["command"]))
			if ("info")
				message_host("command=info&id=[setup_test_id]&capability=[setup_capability_value]&status=[active ? "1" : "0"]&valuelist=Temptarget,Temperature&readinglist=Target Temperature-K,Current Temperature-K,Artifact Temperature-K,Object Responds to Temperature,Details")

			if ("status")
				message_host("command=status&data=[active ? "1" : "0"]")

			if ("poke")
				if (lowertext(packetData["field"]) != "temptarget")
					message_host("command=nack")
					return

				var/pokeval = text2num(packetData["value"])
				if (pokeval < 200 || pokeval > 400)
					message_host("command=nack")
					return
				temptarget = pokeval

				message_host("command=ack")
				return

			if ("peek")
				if (lowertext(packetData["field"]) == "temperature")
					message_host("command=peeked&field=temperature&value=[temperature]")
				else if (lowertext(packetData["field"]) == "temptarget")
					message_host("command=peeked&field=temptarget&value=[temptarget]")
				else
					message_host("command=nack")

			if ("read")
				if (sensed[1] == null || sensed[2] == null || sensed[3] == null)
					message_host("command=nack")
				else
					// Heat Plate - returns Artifact Temp, Heat Response, Cold Response
					message_host("command=read&data=[temptarget],[temperature],[sensed[1]],[sensed[2]],[sensed[3]]")
					message_host("command=ack")

			if ("sense")
				// Heat Plate - returns Artifact Temp, Heat Response, Cold Response

				var/obj/M = null
				for (var/obj/M2 in loc.contents)
					if (M2 == src)
						continue
					if (M2.artifact)
						M = M2
						break

				if (!M)
					sensed[1] = "ERROR"
					sensed[2] = "ERROR"
					sensed[3] = "ERROR"

				else

					if (istype(M.artifact,/artifact))
						var/artifact/A = M.artifact

						// Artifact Temperature
						var/tempdiff = (temperature - 310) * A.react_heat[1]
						sensed[1] = "[310 + tempdiff]"

						// Response
						var/artifact_trigger/AT_H = A.get_trigger_by_path(/artifact_trigger/heat)
						var/artifact_trigger/AT_C = A.get_trigger_by_path(/artifact_trigger/cold)
						if ((istype(AT_H) && temperature > 310) || (istype(AT_C) && temperature < 310))
							sensed[2] = "YES"
						else
							sensed[2] = "NO"

						sensed[3] = A.react_heat[2]

					else
						sensed[1] = "???"
						sensed[2] = "NO"
						sensed[3] = "NONE"

				message_host("command=ack")

			if ("activate")
				active = 1
				stopattarget = 0
				message_host("command=ack")
				update_icon()

			if ("pulse")
				var/duration = text2num(packetData["duration"])
				if (isnum(duration))
					temptarget = duration
				else
					message_host("command=nack")
					return

				stopattarget = 1
				active = 1
				message_host("command=ack")
				update_icon()

			if ("deactivate")
				active = 0
				message_host("command=ack")
				update_icon()
		return

/* Finish this later when I can think of how exactly to implement it
/obj/machinery/networked/test_apparatus/laserE
	name = "Laser Emitter"
	desc = "Emits a laser beam for artifact testing purposes."
	icon_state = "laserE0"
	density = 1

	setup_base_icon_state = "laserE"
	setup_test_id = "LASER_E"
	setup_device_name = "Laser Emitter"
	setup_capability_value = "E"

	var/strength = 1 // 1 to 5?
	var/duration = -1 // seconds

	power_usage = 200

	return_html_interface()
		return "<strong>Active:</strong> [active ? "YES" : "NO"]<br><br>Laser Strength:</strong> [strength]"

	process()
		if (active)
			power_usage = 200 + strength * 500
		else
			power_usage = 200
		if (..())
			return

		if (active)
			use_power(strength * 500)
			duration--
			if (duration == 0)
				active = 0
		else
			use_power(20)

		return

	message_interface(var/list/packetData)
		switch (lowertext(packetData["command"]))
			if ("info")
				message_host("command=info&id=[setup_test_id]&capability=[setup_capability_value]&status=[active ? "1" : "0"]&valuelist=Strength,Duration")

			if ("status")
				message_host("command=status&data=[active ? "1" : "0"]")

			if ("poke")
				if (lowertext(packetData["field"]) != "strength")
					message_host("command=nack")
					return

				var/pokeval = text2num(packetData["value"])
				if (pokeval < 1 || pokeval > 5)
					message_host("command=nack")
					return
				strength = pokeval

				message_host("command=ack")
				return

			if ("peek")
				if (lowertext(packetData["field"]) != "strength")
					message_host("command=nack")
					return

				if (lowertext(packetData["field"]) == "strength") message_host("command=peeked&value=[strength]")

			if ("activate")
				if (!active)
					active = 1
					duration = -1
					message_host("command=ack")
					update_icon()
				else message_host("command=nack")

			if ("pulse")
				var/timer = text2num(packetData["duration"])
				if (!active)
					if (isnum(duration)) duration = timer
					else message_host("command=nack")
				else message_host("command=nack")

				active = 1
				message_host("command=ack")
				update_icon()

			if ("deactivate")
				active = 0
				duration = -1
				message_host("command=ack")
				update_icon()
		return

/obj/machinery/networked/test_apparatus/laserR
	name = "Laser Reciever"
	desc = "Catches a laser beam and analyses how it was changed since emission."
	icon_state = "laserR0"
	density = 1

	setup_base_icon_state = "laserR"
	setup_test_id = "LASER_R"
	setup_device_name = "Laser Reciever"
	setup_capability_value = "S"

	var/list/sensed = list(null,null)*/


/obj/machinery/networked/test_apparatus/gas_sensor
	icon_state = "gsensor1"
	name = "Gas Sensor"
	desc = "A device that detects the composition of the air nearby."
	density = 0
	dragload = 0

	setup_base_icon_state = "gsensor"
	setup_test_id = "GAS_0"
	setup_device_name = "Gas Sensor"
	setup_capability_value = "S"
	active = 1

	var/setup_tag = null
			//Pressure, Temperature, O2, N2, CO2, Plasma, Misc
	var/list/sensed = list(null, null, null, null, null, null, null)

	New()
		..()
		if (setup_tag)
			setup_test_id = "GAS_[uppertext( copytext(setup_tag,1,9) )]"

	return_html_interface()
		return "<strong>Active:</strong> [active ? "YES" : "NO"]"

	message_interface(var/list/packetData)
		switch (lowertext(packetData["command"]))
			if ("info")
				message_host("command=info&id=[setup_test_id]&capability=[setup_capability_value]&status=[active ? "1" : "0"]&valuelist=None&readinglist=Pressure-kPa,Temperature-K,Oxygen-%,Nitrogen-%,CO2-%,FAAE_1-%,Misc-%")

			if ("status")
				message_host("command=status&data=[active ? "1" : "0"]")

			if ("poke","peek")
				message_host("command=nack")

			if ("sense")
				var/gas_mixture/air_sample = return_air()
				var/total_moles = max(air_sample.total_moles(), 1)
				if (air_sample)
					sensed[1] = round(air_sample.return_pressure(), 0.1)
					sensed[2] = round(air_sample.temperature, 0.1)
					sensed[3] = round(100*air_sample.oxygen/total_moles, 0.1)
					sensed[4] = round(100*air_sample.nitrogen/total_moles, 0.1)
					sensed[5] = round(100*air_sample.carbon_dioxide/total_moles, 0.1)
					sensed[6] = round(100*air_sample.toxins/total_moles, 0.1)

					var/tgmoles = 0
					if (air_sample.trace_gases && air_sample.trace_gases.len)
						for (var/gas/trace_gas in air_sample.trace_gases)
							tgmoles += trace_gas.moles
					sensed[7] = round(100*tgmoles/total_moles, 0.1)
				else
					for (var/i = 1, i <= sensed.len, i++)
						sensed[i] = "???"

				message_host("command=ack")

			if ("read")
				if (!sensed || sensed.len < 7)
					message_host("command=nack")
					return
				for (var/i=1,i<=sensed.len,i++)
					if (sensed[i] == null)
						message_host("command=nack")
						return

				message_host("command=read&data=[sensed[1]],[sensed[2]],[sensed[3]],[sensed[4]],[sensed[5]],[sensed[6]],[sensed[7]]")
				message_host("command=ack")
		return



/obj/machinery/networked/test_apparatus/mechanics
	name = "IO Block"
	desc = "An 8 input, 8 output interface for mechanics components."
	icon_state = "generic0"
	density = 1
	dragload = 0
	setup_base_icon_state = "generic"

	setup_test_id = "PIO"
	setup_device_name = "IO Block"
	setup_capability_value = "B"

	var/output_word = 0
	var/input_word = 0
	var/buffered_input_word = 0
	var/pulses = 0 //If nonzero, we will pulse this many times and then deactivate
	var/tmp/mechanicsMessage/lastSignal = null
	power_usage = 200

	New()
		..()

		mechanics = new(src)
		mechanics.master = src

		mechanics.addInput("input 0", "fire0")
		mechanics.addInput("input 1", "fire1")
		mechanics.addInput("input 2", "fire2")
		mechanics.addInput("input 3", "fire3")
		mechanics.addInput("input 4", "fire4")
		mechanics.addInput("input 5", "fire5")
		mechanics.addInput("input 6", "fire6")
		mechanics.addInput("input 7", "fire7")

	return_html_interface()
		. = {"<strong>INPUT STATUS</strong>
		<table border='1' style='color:#FFFFFF'>
		<tr>"}

		for (var/bit = 7, bit >= 0, bit--)
			. += "<td id='bit[bit]'> <div align=left style='background-color=[input_word & (1<<bit) ? "#33FF00" : "#F80000"]'>[bit]</div></td>"

		. += "</tr></table>"

	message_interface(var/list/packetData)
		switch (lowertext(packetData["command"]))
			if ("info")
				message_host("command=info&id=[setup_test_id]&capability=[setup_capability_value]&status=[active ? "1" : "0"]&valuelist=OutputWord&readinglist=Input Line")

			if ("status")
				message_host("command=status&data=[active ? "1" : "0"]")

			if ("poke")
				. = lowertext(packetData["field"])
				if (. == "outputword")
					var/pokeval = text2num(packetData["value"])
					if (pokeval < 0 || pokeval > 255)
						message_host("command=nack")
						return

					output_word = pokeval

					message_host("command=ack")

				else if (copytext(.,1,7) == "output")
					. = round( text2num(copytext(.,7)) )

					if (!isnum(.) || . < 0 || . > 7)
						message_host("command=nack")
						return

					if (packetData["value"] == "1")
						output_word |= 1<<.

					else if (packetData["value"] == "0")
						output_word &= ~(1<<.)

					else
						message_host("command=nack")
						return

					message_host("command=ack")

				else
					message_host("command=nack")
					return

				return

			if ("peek")
				if (lowertext(packetData["field"]) == "outputword")
					message_host("command=peeked&field=outputword&value=[output_word]")
				message_host("command=nack")

			if ("read")
				message_host("command=read&data=[buffered_input_word ? "TRUE" : "FALSE"]")

				message_host("command=ack")

			if ("sense")
				buffered_input_word = input_word

				message_host("command=ack")

			if ("activate")
				pulses = 0
				active = 1
				message_host("command=ack")
				update_icon()

			if ("pulse")
				var/duration = text2num(packetData["duration"])
				if (isnum(duration))
					pulses = max(0, min(round(duration), 255))
				else
					message_host("command=nack")
					return

				active = 1
				message_host("command=ack")
				update_icon()

			if ("deactivate")
				active = 0
				pulses = 0
				message_host("command=ack")
				update_icon()
		return

	process()
		if (active)
			power_usage = 300
		else
			power_usage = 200
		if (..())
			return

		if (active)
			use_power(100)

			if (lastSignal)
				lastSignal.signal = "[output_word]"
				mechanics.fireOutgoing(lastSignal)
				lastSignal = null

			else
				mechanics.fireOutgoing(mechanics.newSignal("[output_word]"))


			if (pulses)
				pulses--
				if (pulses < 1)
					active = 0

		else
			use_power(20)

		return

	proc
		fire0(var/mechanicsMessage/anInput)

			if (anInput && anInput.isTrue())
				input_word |= 1

			else
				input_word &= ~1

			lastSignal = anInput

		fire1(var/mechanicsMessage/anInput)

			if (anInput && anInput.isTrue())
				input_word |= 2

			else
				input_word &= ~2

			lastSignal = anInput

		fire2(var/mechanicsMessage/anInput)

			if (anInput && anInput.isTrue())
				input_word |= 4

			else
				input_word &= ~4

			lastSignal = anInput

		fire3(var/mechanicsMessage/anInput)

			if (anInput && anInput.isTrue())
				input_word |= 8

			else
				input_word &= ~8

			lastSignal = anInput

		fire4(var/mechanicsMessage/anInput)

			if (anInput && anInput.isTrue())
				input_word |= 16

			else
				input_word &= ~16

			lastSignal = anInput

		fire5(var/mechanicsMessage/anInput)

			if (anInput && anInput.isTrue())
				input_word |= 32

			else
				input_word &= ~32

		fire6(var/mechanicsMessage/anInput)

			if (anInput && anInput.isTrue())
				input_word |= 64

			else
				input_word &= ~64

			lastSignal = anInput

		fire7(var/mechanicsMessage/anInput)

			if (anInput && anInput.isTrue())
				input_word |= 128

			else
				input_word &= ~128

			lastSignal = anInput