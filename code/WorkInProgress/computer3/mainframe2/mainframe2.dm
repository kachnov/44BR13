

/*
 *	The Terminal Connection datum, used to keep track of, well, terminal connections.
 */

/terminal_connection
	var/obj/machinery/networked/master = null
	var/net_id = null //Network ID of connected device.
	var/term_type = null //Terminal type ID of connected device.  i.e. PNET_MAINFRAME or HUI_TERMINAL

	New(var/obj/machinery/networked/newmaster, var/new_id, var/newterm_type)
		..()
		if (istype(newmaster))
			master = newmaster

		if (new_id)
			net_id = new_id

		if (newterm_type)
			term_type = newterm_type
		return

	disposing()
		master = null

		..()

/*
 *	The physical mainframe, communication through wired network.
 */

/obj/machinery/networked/mainframe
	name = "Mainframe"
	desc = "A mainframe computer. It's pretty big!"
	density = 1
	anchored = 1
	icon_state = "dwaine"
	device_tag = "PNET_MAINFRAME"
	timeout = 30
	req_access = list(access_heads)
	var/list/terminals = list() //list of netIDs/terminal profiles of connected terminal devices.
	var/list/processing = list() //As the name implies, this is the list of programs that should be updated every process call on the mainframe object.
	var/list/timeout_list = list() //Terminals currently set to time out
	var/computer/file/mainframe_program/os/os = null //Ref to current operating system program
	var/computer/file/mainframe_program/os/bootstrap = null //Ref to bootloader program, instanciated when a main OS cannot be located on the memory card
	var/computer/folder/runfolder = null //Storage folder for currently running programs.
	var/obj/item/disk/data/memcard/hd = null  //Only internal storage for the mainframe--core memory, used as primary storage.

	var/posted = 1 //Have we run through the POST sequence?  Set to 1 initially so it doesn't freak out during map powernet generation.

	var/setup_drive_size = 4096
	var/setup_drive_type = /obj/item/disk/data/memcard //Use this path for the hd
	var/setup_bootstrap_path = /computer/file/mainframe_program/os/bootstrap //The bootstrapping system.
	var/setup_os_string = null
	power_usage = 500

	zeta
		//setup_starting_os = /computer/file/mainframe_program/os/main_os
		setup_drive_type = /obj/item/disk/data/memcard/main2

	New()
		..()
		spawn (10)

			net_id = generate_net_id(src)

			if (!data_link)
				var/turf/T = get_turf(src)
				var/obj/machinery/power/data_terminal/test_link = locate() in T
				if (test_link && !test_link.is_valid_master(test_link.master))
					data_link = test_link
					data_link.master = src

			if (!hd && (setup_drive_size > 0))
				if (setup_drive_type)
					hd = new setup_drive_type
					hd.set_loc(src)
				else
					hd = new /obj/item/disk/data/memcard(src)
				hd.file_amount = setup_drive_size

			if (ispath(setup_bootstrap_path))
				bootstrap = new setup_bootstrap_path
				bootstrap.master = src

			sleep(54)
			posted = 0
			post_system()

		return

	disposing()
		if (terminals)
			for (var/datum/conn in terminals)
				conn.dispose()

			terminals.len = 0
			terminals = null

		if (processing)
			processing.len = 0
			processing = null

		if (timeout_list)
			timeout_list.len = 0
			timeout_list = null

		if (os)
			os.dispose()
			os = null

		if (bootstrap)
			bootstrap.dispose()
			bootstrap = null

		if (runfolder)
			runfolder = null

		if (hd)
			hd.dispose()
			hd = null

		..()

	attack_ai(mob/user as mob)
		return

	attack_hand(mob/user as mob)
		if (user.stat || user.restrained())
			return

		if (stat & BROKEN)
			if (!hd)
				return

			boutput(user, "<span style=\"color:red\">The mainframe is trashed, but the memory core could probably salvaged.</span>")
			return

		var/dat = "<html><head><title>Mainframe Access Panel</title></head><body><hr>"

		dat += "<strong>ACTIVE:</strong> [os ? "YES" : "NO"]<br>"
		dat += "<strong>BOOTING:</strong> [(bootstrap && os && istype(os, bootstrap.type)) ? "YES" : "NO"]<br><br>"

		if (stat & NOPOWER)

			dat += "<strong>Memory Core:</strong> <a href='?src=\ref[src];core=1'>[hd ? "LOADED" : "---------"]</a><br>"
			dat += "Core Shield Maglock is <strong>OFF</strong><hr>[net_switch_html()]<hr>"
		else

			dat += "<strong>Memory Core:</strong> [hd ? "LOADED" : "---------"]<br>"
			dat += "Core Shield Maglock is <strong>ON</strong><hr>"


		user << browse(dat, "window=mainframe;size=245x202")
		onclose(user, "mainframe")
		return

	Topic(href, href_list)
		if (stat & BROKEN)
			return

		if (istype(loc, /turf) && get_dist(src, usr) <= 1)
			if (usr.stat || usr.restrained())
				return

			usr.machine = src

			if (href_list["core"])

				if (!(stat & NOPOWER))
					boutput(usr, "<span style=\"color:red\">The electromagnetic lock is still on!</span>")
					return

				//Ai/cyborgs cannot physically remove a memory board from a room away.
				if (istype(usr,/mob/living/silicon) && get_dist(src, usr) > 1)
					boutput(usr, "<span style=\"color:red\">You cannot physically touch the board.</span>")
					return

				if (hd)
					hd.set_loc(loc)
					boutput(usr, "You remove the memory core from the mainframe.")
					usr.unlock_medal("421", 1)
					stat |= MAINT
					unload_all()
					hd = null
					runfolder = null
					posted = 0

				else
					var/obj/item/I = usr.equipped()
					if (istype(I, /obj/item/disk/data/memcard))
						usr.drop_item()
						I.set_loc(src)
						hd = I
						stat &= ~MAINT
						boutput(usr, "You insert [I].")

			else if (href_list["dipsw"] && (stat & NOPOWER))
				var/switchNum = text2num(href_list["dipsw"])
				if (switchNum < 1 || switchNum > 8)
					return TRUE

				switchNum = round(switchNum)
				if (net_number & switchNum)
					net_number &= ~switchNum
				else
					net_number |= switchNum

			updateUsrDialog()
			add_fingerprint(usr)
		return

	attackby(obj/item/W as obj, mob/user as mob)
		if (istype(W, /obj/item/crowbar))
			if (!(stat & BROKEN))
				return

			if (!hd)
				boutput(usr, "<span style=\"color:red\">The memory core has already been removed.</span>")
				return

			stat |= MAINT
			unload_all()
			hd.set_loc(loc)
			hd = null
			posted = 0

			boutput(usr, "You pry out the memory core.")
			updateUsrDialog()
			return

		else
			..()

		return


	process()
		..()
		if (stat & (NOPOWER|BROKEN|MAINT) || !processing)
			return
		use_power(500)
		if (prob(3))
			spawn (1)
				playsound(loc, pick(ambience_computer), 50, 1)

		for (var/progIndex = 1, progIndex <= processing.len, progIndex++)
			var/computer/file/mainframe_program/prog = processing[progIndex]
			if (prog)
				if (prog.disposed)
					processing[progIndex] = null
					continue

				prog.process()
/*
		for (var/computer/file/mainframe_program/P in processing)
			if (P)
				P.process()
*/
		if (timeout == 0)
			timeout = initial(timeout)
			timeout_alert = 0
			for (var/timed in timeout_list)
				var/terminal_connection/conn = terminals[timed]
				terminals -= timed
				if (os && conn)
					src.os.closed_connection(conn)
				//qdel(conn)
				if (conn)
					conn.dispose()
		else
			timeout--
			if (timeout <= 5 && !timeout_alert)
				timeout_alert = 1
				timeout_list = terminals.Copy()
				for (var/id in timeout_list)
					post_status(id, "command","term_ping","data","reply")

		return

	receive_signal(signal/signal)
		if (stat & (NOPOWER|BROKEN|MAINT) || !data_link)
			return
		if (!signal || !net_id || signal.encryption)
			return

		if (signal.transmission_method != TRANSMISSION_WIRE) //No radio for us thanks
			return

		var/target = signal.data["sender"]

		//They don't need to target us specifically to ping us.
		//Otherwise, if they aren't addressing us, ignore them
		if (signal.data["address_1"] != net_id)
			if ((signal.data["address_1"] == "ping") && ((signal.data["net"] == null) || ("[signal.data["net"]]" == "[net_number]")) && signal.data["sender"])
				spawn (5) //Send a reply for those curious jerks
					post_status(target, "command", "ping_reply", "device", device_tag, "netid", net_id)

			return

		var/sigcommand = lowertext(signal.data["command"])
		if (!sigcommand || !signal.data["sender"])
			return

		switch(sigcommand)
			if ("term_connect") //Terminal interface stuff.
				if (target in terminals)
					//something might be wrong here, disconnect them!
					var/terminal_connection/conn = terminals[target]
					terminals.Remove(target)
					if (os)
						src.os.closed_connection(conn)
					//qdel(conn)
					if (conn)
						conn.dispose()
					spawn (3)
						post_status(target, "command","term_disconnect")
					return

				var/devtype = signal.data["device"]
				if (!devtype) return
				var/terminal_connection/newconn = new /terminal_connection(src, target, devtype)
				terminals[target] = newconn //Accept the connection!
				if (signal.data["data"] != "noreply")
					post_status(target, "command","term_connect","data","noreply")
				//also say hi.
				if (os)
					var/computer/theFile = null
					if (signal.data_file)
						theFile = signal.data_file.copy_file()
					os.new_connection(newconn, theFile)
					//qdel(file)
					if (theFile)
						theFile.dispose()
				return

			if ("term_message","term_file")
				if (!(target in terminals)) //Huh, who is this?
					return

				//visible_message("[src] beeps.")
				var/data = signal.data["data"]
				var/file = null
				if (signal.data_file)
					file = signal.data_file.copy_file()
				if (os && data)
					os.term_input(data, target, file)
					//qdel(file)

				return

			if ("term_break")
				if (!(target in terminals))
					return

				if (os)
					os.term_input(1, target, null, 1)

			if ("term_ping")
				if (!(target in terminals))
					spawn (3) //Go away!!
						post_status(target, "command","term_disconnect")
					return
				if (target in timeout_list)
					timeout_list -= target
				if (signal.data["data"] == "reply")
					post_status(target, "command","term_ping")
				return

			if ("term_disconnect")
				if (target in terminals)
					var/terminal_connection/conn = terminals[target]
					if (os)
						src.os.closed_connection(conn)
					terminals -= target
					//qdel(conn)
					if (conn)
						conn.dispose()

				return

			if ("ping_reply")
				if (os)
					os.ping_reply(signal.data["netid"],signal.data["device"])
				return

		return

	power_change()
		if (stat & BROKEN)
			icon_state = initial(icon_state)
			icon_state += "b"
			return

		else if (powered())
			icon_state = initial(icon_state)
			stat &= ~NOPOWER
			post_system() //Will simply return if POSTed already.
		else
			spawn (rand(0, 15))
				icon_state = initial(icon_state)
				icon_state += "0"
				stat |= NOPOWER
				posted = 0
				os = null

	clone()
		var/obj/machinery/networked/mainframe/cloneframe = ..()
		if (!cloneframe)
			return

		cloneframe.setup_bootstrap_path = setup_bootstrap_path
		cloneframe.setup_os_string = setup_os_string
		if (hd)
			cloneframe.hd = src.hd.clone()

		return cloneframe

	meteorhit(var/obj/O as obj)
		if (stat & BROKEN)
			//dispose()
			dispose()
		set_broken()
		var/effects/system/harmless_smoke_spread/smoke = new /effects/system/harmless_smoke_spread()
		smoke.set_up(5, 0, src)
		smoke.start()
		return

	ex_act(severity)
		switch(severity)
			if (1.0)
				//dispose()
				dispose()
				return
			if (2.0)
				if (prob(50))
					set_broken()
			if (3.0)
				if (prob(25))
					set_broken()
			else
		return

	blob_act(var/power)
		if (prob(power * 2.5))
			set_broken()
			density = 0

	proc
		run_program(computer/file/mainframe_program/program, var/mainframe2_user_data/user, var/computer/file/mainframe_program/caller, var/runparams)
			if (!hd || !program || (!program.holder && program.needs_holder))
				return FALSE

			if (!runfolder)
				for (var/computer/folder/F in hd.root.contents)
					if (F.name == "proc")
						runfolder = F
						runfolder.metadata["permission"] = COMP_HIDDEN
						break

				if (!runfolder)
					runfolder = new /computer/folder(  )
					runfolder.name = "proc"
					runfolder.metadata["permission"] = COMP_HIDDEN
					if (!hd.root.add_file( runfolder ))
						//qdel(runfolder)
						runfolder.dispose()
						return FALSE
			if (!(program in processing))
				program = program.copy_file()
				if (!runfolder.add_file( program ))
					//qdel(program)
					program.dispose()
					return FALSE

			if (program.master != src)
				program.master = src

			if (istype(program, /computer/file/mainframe_program/os))
				if (!os)
					os = program
				else
					//qdel(program)
					program.dispose()
					return FALSE

			if (!(program in processing))
				if (os == program && processing.len)
					processing.len++
					for (var/x = processing.len, x > 0, x--)
						var/computer/file/mainframe_program/P = processing[x]
						if (istype(P))
							P.progid = x+1
						if (processing.len == x)
							processing.len++
						processing[x+1] = P

					processing[1] = os
					os.progid = 1

				else
					var/success = 0
					for (var/x = 1, x <= processing.len, x++)
						if (!isnull(processing[x]))
							continue

						processing[x] = program
						program.progid = x
						success = 1
						break

					if (!success)
						processing += program
						program.progid = processing.len

			if (user)
				program.useracc = user
				user.current_prog = program

			if (caller)
				program.parent_task = caller

			program.initialize(runparams)
			//program.initialized = 1
			return program

		unload_program(computer/file/mainframe_program/program)
			if (!program)
				return FALSE

			if (program == os)
				return FALSE

			if (processing[processing.len] == program)
				processing -= program
			else if (program.progid && program.progid <= processing.len)
				processing[program.progid] = null
	//		if (active_program == program)
	//			src.active_program = src.host_program
			program.initialized = 0
			program.unloaded()

			if (program.holding_folder == runfolder)
				//qdel(program)
				program.dispose()

			return TRUE

		unload_all()
			os = null
			for (var/computer/file/mainframe_program/M in processing)
				unload_program(M)

			return


		delete_file(computer/file/theFile)
			if ((!theFile) || (!theFile.holder) || (theFile.holder.read_only))
				//boutput(world, "Cannot delete :(")
				return FALSE

			//qdel(file)
			theFile.dispose()
			return TRUE

		relay_progsignal(var/computer/file/mainframe_program/caller, var/progid, var/list/data = null, var/computer/file/file)
			if (progid < 1 || progid > processing.len || !caller)
				return ESIG_GENERIC

			var/computer/file/mainframe_program/P = processing[progid]
			if (!istype(P))
				return ESIG_GENERIC

			var/callID = processing.Find(caller)
			return P.receive_progsignal(callID, data, file)

		set_broken()
			icon_state = initial(icon_state)
			icon_state += "b"
			stat |= BROKEN

		reconnect_all_devices()
			for (var/device_id in terminals)
				var/terminal_connection/conn = terminals[device_id]
				if (istype(conn) && cmptext(conn.term_type, "hui_terminal"))
					continue

				reconnect_device(device_id)

			return ESIG_SUCCESS

		reconnect_device(var/device_netid)
			if (!device_netid)
				return ESIG_GENERIC

			device_netid = lowertext(device_netid)
			if (device_netid in terminals)
				var/terminal_connection/conn = terminals[device_netid]
				if (os)
					src.os.closed_connection(conn)
				terminals -= device_netid
				//qdel(conn)
				if (conn)
					conn.dispose()

			post_status(device_netid, "command", "term_connect", "device", device_tag)
			return ESIG_SUCCESS

		/*
		 *	Overview of startup process:
		 *		If we already have an OS reference, initialize it and return.
		 *		If not, begin looking for an OS file in memory (Of type /computer/file/mainframe_program/os)
		 *			Ideally, there is a folder named "sys" in the root directory to look in.
		 *		If we can't find the OS there, we pass control over the our bootstrapping program.
		 */

		post_system()
			if (posted || !hd)
				return

			posted = 1

			if (os) //Let the starting programs set up vars or whatever
				os.initialize()

			else

				if (runfolder)
					//qdel(runfolder)
					runfolder.dispose()
					runfolder = null

				if (hd && hd.root)
					var/computer/folder/sysfolder = null
					for (var/computer/folder/F in hd.root.contents)
						if (F.name == "sys")
							sysfolder = F
							break

					if (sysfolder)
						var/computer/file/mainframe_program/os/newos = locate(/computer/file/mainframe_program/os) in sysfolder.contents
						if (istype(newos))
							visible_message("[src] beeps")
							newos.initialized = 0
							run_program(newos)
							return

					if (!istype(bootstrap))
						bootstrap = new setup_bootstrap_path

					//Run the bootstrapping code!
					if (bootstrap)
						run_program(bootstrap)

			return


/*
 *	Bootstrapping System
 */

/computer/file/mainframe_program/os/bootstrap
	name = "NETBOOT"
	size = 4
	needs_holder = 0
	var/tmp/list/known_banks = list()
	var/tmp/current = null //Net ID of current bank.
	var/tmp/stage = 0
	var/tmp/ping_wait = 0
	var/tmp/stage_wait = 0
	var/tmp/rescan_wait = 0
	var/setup_system_directory = "/sys"
	var/setup_driver_directory = "/sys/drvr"
	var/setup_bin_directory = "/bin"

	disposing()
		known_banks = null
		..()

	initialize()
		if (..())
			return

		known_banks.len = 0

		clear_core()

		find_existing_databanks()

		stage_wait = 4
		stage = 1
		ping_wait = 4
		current = null
		spawn (1)
			master.post_status("ping","data","NETBOOT","net","[master.net_number]")
		return

	process()
		if (..())
			return

		if (ping_wait)
			ping_wait--
			return

		if (rescan_wait)
			if (--rescan_wait < 1)
				initialized = 0
				initialize()
			return

		if (stage_wait)
			stage_wait--
			if (stage_wait <= 0)
				stage = 0

		if (!stage)
			if (!known_banks.len)
				master.os = null
				handle_quit()
				//qdel (src)
				dispose()
				return

			new_current()
			message_term("command=bootreq",current)
			return
		return

	new_connection(terminal_connection/conn)
		if (!istype(conn))
			return

		if (conn.term_type == "PNET_DATA_BANK" && !(conn.net_id in known_banks) )
			known_banks += conn.net_id

		return

	closed_connection(terminal_connection/conn)
		if (!istype(conn)) return
		var/del_netid = conn.net_id
		if (del_netid in known_banks)
			known_banks -= del_netid
		return

	ping_reply(var/senderid,var/sendertype)
		if (..() || !ping_wait)
			return

		if ( !(senderid in master.terminals) && (sendertype == "PNET_DATA_BANK" || sendertype == "HUI_TERMINAL"))
			spawn (rand(1,4))
				src.master.post_status(senderid,"command","term_connect","device",master.device_tag)
		return

	term_input(var/data, var/termid, var/computer/file/the_file)
		if (..() || !stage)
			return

		var/terminal_connection/conn = master.terminals[termid]
		if (!conn || !conn.term_type)
			return
		var/device_type = conn.term_type
		if (device_type == "PNET_DATA_BANK")
			var/list/commandlist = params2list(data)
			if (!commandlist || !commandlist["command"])
				return
			var/command = lowertext(commandlist["command"])

			//boutput(world, "\[[conn.net_id]]")

			switch(command)
				if ("register")
					return

				if ("file")
					//boutput(world, "FILE")
					if (!the_file)
						new_current()
						return

					var/computer/file/archive/arc = the_file.copy_file()
					if (!istype(arc))
						//qdel(arc)
						arc.dispose()
						new_current()
						return

					var/computer/file/mainframe_program/os/newos = locate() in arc.contained_files
					if (!istype(newos))
						//qdel(arc)
						arc.dispose()
						new_current()
						return

					var/computer/folder/sysdir = parse_directory(setup_system_directory, holder.root, 1)
					var/computer/folder/drivedir = parse_directory(setup_driver_directory, holder.root, 1)
					var/computer/folder/bindir = parse_directory(setup_bin_directory, holder.root, 1)
					var/computer/folder/srvdir = parse_directory("srv", sysdir, 1)
					if (!sysdir || !drivedir || !bindir || !srvdir)
						master.visible_message("[master] boops")
						master.os = null
						handle_quit()
						//dispose()
						dispose()
						return

					for (var/computer/file/mainframe_program/MP in arc.contained_files)
						if (istype(MP, /computer/file/mainframe_program/os))
							continue

						var/computer/file/mainframe_program/MP_copy = MP.copy_file()
						if (istype(MP_copy, /computer/file/mainframe_program/driver))
							if (get_computer_datum(MP_copy.name, drivedir))
								continue
							if (!drivedir.add_file(MP_copy))
								//qdel(MP_copy)
								MP_copy.dispose()
								break

						else if (istype(MP_copy, /computer/file/mainframe_program/utility))
							if (get_computer_datum(MP_copy.name, bindir))
								continue
							if (!bindir.add_file(MP_copy))
								///qdel(MP_copy)
								MP_copy.dispose()
								break

						else if (istype(MP_copy, /computer/file/mainframe_program/srv))
							if (get_computer_datum(MP_copy.name, sysdir))
								continue

							if (!srvdir.add_file(MP_copy))
								MP_copy.dispose()

						else
							if (get_computer_datum(MP_copy.name, sysdir))
								continue
							if (!sysdir.add_file(MP_copy))
								//qdel(MP_copy)
								MP_copy.dispose()
								break

					newos = newos.copy_file()
					if (sysdir.add_file(newos))
						master.os = null
						//qdel(arc)
						arc.dispose()
						master.visible_message("[master] beeps")
						master.run_program(newos)
						handle_quit()
						//dispose()
						dispose()
						return
					else
						//qdel(arc)
						//qdel(newos)
						if (arc)
							arc.dispose()
						if (newos)
							newos.dispose()
						/*
						quit()
						qdel(src)
						*/
						master.visible_message("[master] boops sadly.")
						rescan_wait = 20
						return


				if ("status")
					stage_wait = 1
					return

		return

	proc
		new_current() //Move on to a new current in the list.
			if (current)
				known_banks.Cut(1,2)
				current = null

			if (!known_banks.len)
				/*
				master.os = null
				quit()
				qdel(src)
				*/
				rescan_wait = 20
				return

			stage_wait = 4
			stage = 1
			current = known_banks[1]
			return

		clear_core() //Clear the core memory board.
			if (!holder || !holder.root)
				return FALSE

			for (var/computer/C in holder.root)
				if (C == src || C == holding_folder)
					continue

				//qdel(C)
				C.dispose()

			return TRUE

		find_existing_databanks() //Find databank connections already in master.terminals
			if (!master)
				return

			for (var/x in master.terminals)
				var/terminal_connection/conn = master.terminals[x]
				if (!istype(conn))
					continue

				master.terminals -= x
				//qdel(conn)
				conn.dispose()

				var/tempx = x
				spawn (rand(1,4))
					master.post_status(tempx, "command", "term_disconnect")


			return


/*
 *	A little mass message proc for some SPOOKY ANTICS
 */

/proc/send_spooky_mainframe_message(var/the_message, var/a_spooky_custom_name)
	if (!the_message)
		return TRUE

	for (var/obj/machinery/networked/mainframe/aMainframe in world)
		if (aMainframe.z != 1)
			continue

		if (!aMainframe.os || !hascall(aMainframe.os, "message_all_users"))
			continue

		aMainframe.os:message_all_users(the_message, a_spooky_custom_name, 1)
		return FALSE

	return 2