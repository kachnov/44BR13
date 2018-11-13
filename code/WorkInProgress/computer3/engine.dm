//Singularity engine control program
#ifdef SINGULARITY_TIME
/computer/file/terminal_program/engine_control
	name = "EngineMaster"
	size = 10
	req_access = list(access_engineering_engine)
	var/tmp/authenticated = null //Are we currently logged in?
	var/computer/file/user_data/account = null
	var/log_string = null
	var/obj/item/peripheral/network/powernet_card/netcard = null
	var/obj/item/peripheral/network/radio/radiocard = null
	var/tmp/task = null //What are we doing at the moment?
	var/tmp/startup_line = 1
	var/tmp/starting_up = 0 //Are we currently starting up?
	var/list/emitter_ids = list() //Net ids of located emitters.
	var/list/fieldgen_ids = list() //Net ids of located field generators.
	var/tmp/last_event_report = 0 //When did we last report an event?

	var/setup_acc_filepath = "/logs/sysusr"//Where do we look for login data?
	var/setup_logdump_name = "englog"
	var/setup_mail_freq = 1149 //Which freq do we report to?
	var/setup_mailgroup = "engineer" //The PDA mailgroup used when alerting engineer pdas.


	initialize()

		authenticated = null
		task = null
		master.temp = null
		startup_line = 1

		if (!find_access_file()) //Find the account information, as it's essentially a ~digital ID card~
			src.print_text("<strong>Error:</strong> Cannot locate user file.  Quitting...")
			master.unload_program(src) //Oh no, couldn't find the file.
			return
		if (!check_access(account.access))
			src.print_text("User [src.account.registered] does not have needed access credentials.<br>Quitting...")
			master.unload_program(src)
			return

		netcard = locate() in master.peripherals
		if (!netcard || !istype(netcard))
			src.print_text("<strong>Error:</strong> No network card detected.<br>Quitting...")
			log_string += "<br>Startup Failure: No network card."
			master.unload_program(src)
			return

		radiocard = locate() in master.peripherals
		if (!radiocard || !istype(radiocard))
			radiocard = null
			print_text("<strong>Warning:</strong> No radio module detected.")
			log_string += "<br>Startup Error: No radio."

		authenticated = account.registered
		log_string += "<br><strong>LOGIN:</strong> [authenticated]"

		ping_devices()

		var/intro_text = {"<br>EngineMaster
		<br>Automated Engine Control System
		<br><strong>Commands:</strong>
		<br>(Startup) to activate engine systems.
		<br>(Abort) to abort startup procedure.
		<br>(Rescan) to rescan for engine devices.
		<br>(Clear) to clear the screen.
		<br>(Quit) to exit."}
		print_text(intro_text)

		return

	input_text(text)
		if (..())
			return

		var/list/command_list = parse_string(text)
		var/command = command_list[1]
		command_list -= command_list[1]

		print_text(strip_html(text))

		switch(lowertext(command))

			if ("startup")
				//We're already starting, jeez give it some time
				if (starting_up)
					print_text("Startup already in progress.")
					master.add_fingerprint(usr)
					return

				if (!emitter_ids || emitter_ids.len <= 0)
					print_text("<strong>Error:</strong> Insufficient emitters detected.")
					master.add_fingerprint(usr)
					return

				if (!fieldgen_ids || fieldgen_ids.len < 4)
					print_text("<strong>Error:</strong> Insufficient field generators detected.")
					master.add_fingerprint(usr)
					return

				startup_line = 1
				starting_up = 1
				task = "startup-emit"
				log_string += "<br>Startup initiated."
				src.report_event("Engine starting up...")
				print_text("Startup procedure initiated.")

			if ("abort")
				if (!starting_up)
					print_text("No startup procedure in progress.")
					master.add_fingerprint(usr)
					return

				startup_line = 1
				task = null
				starting_up = 0
				log_string += "<br>Startup aborted."
				print_text("Startup procedure aborted.")

			if ("rescan")
				if ((task && task != "scan") || starting_up)
					print_text("Unable to scan, system is busy.")
					return

				ping_devices()

			if ("logdump")
				if (!log_string) //Something is wrong.
					print_text("<strong>Error:</strong> No log data to dump.")
					return

				if (holder.read_only)
					print_text("<strong>Error:</strong> Destination drive is read-only.")
					return

				var/computer/file/text/logdump = get_file_name(setup_logdump_name, holding_folder)
				if (logdump && !istype(logdump) || get_folder_name(setup_logdump_name, holding_folder))
					print_text("<strong>Error:</strong> Name in use.")
					return

				if (logdump && istype(logdump))
					logdump.data = log_string
				else
					logdump = new /computer/file/text
					logdump.name = setup_logdump_name
					logdump.data = log_string
					if (!holding_folder.add_file(logdump))
						//qdel(logdump)
						logdump.dispose()
						print_text("<strong>Error:</strong> Cannot save to disk.")
						return

				print_text("Log dumped to holding directory.")

			if ("clear")
				master.temp = null
				master.temp_add = "Workspace cleared.<br>"

			if ("quit")
				log_string += "<br><strong>LOGOUT:</strong> [authenticated]"
				src.print_text("Now quitting...")
				master.unload_program(src)
				return

			else
				print_text("Unknown command.")

		master.add_fingerprint(usr)
		master.updateUsrDialog()
		return

	process()
		if (..() || !src.task)
			return

		switch(task)
			if ("startup-emit")
				if (startup_line > emitter_ids.len)
					task = "startup-field"
					startup_line = 1
					return

				post_status(emitter_ids[startup_line], "command", "activate")
				startup_line++

			if ("startup-field")
				if (startup_line > fieldgen_ids.len)
					task = null
					startup_line = 1
					starting_up = 0
					print_text("Startup procedure complete.")
					return

				post_status(fieldgen_ids[startup_line], "command", "activate")
				startup_line++

	receive_command(obj/source, command, signal/signal)
		if ((..()) || !signal)
			return

		//Time to populate our lists of components.
		if (signal.data["command"] == "ping_reply" && (task == "scan"))
			if (!signal.data["netid"])
				return

			switch(signal.data["device"])
				if ("PNET_ENG_EMITR") //Oh hey a new emitter.
					if (!(signal.data["netid"] in emitter_ids))
						emitter_ids += signal.data["netid"]
				if ("PNET_ENG_FIELD")
					if (!(signal.data["netid"] in fieldgen_ids))
						fieldgen_ids += signal.data["netid"]
				else
					return

		return

	proc
		ping_devices()
			if (!netcard)
				return
			task = "scan"
			emitter_ids = new
			fieldgen_ids = new

			var/signal/newsignal = get_free_signal()
			//newsignal.encryption = "\ref[netcard]"

			src.log_string += "<br>Scanning for devices..."
			src.print_text("Scanning for devices...")
			peripheral_command("ping", newsignal, "\ref[netcard]")

			return

		post_status(var/target_id, var/key, var/value, var/key2, var/value2, var/key3, var/value3)
			if (!netcard)
				return

			var/signal/signal = get_free_signal()

			//signal.encryption = "\ref[netcard]"
			signal.data[key] = value
			if (key2)
				signal.data[key2] = value2
			if (key3)
				signal.data[key3] = value3

			signal.data["address_1"] = target_id
			peripheral_command("transmit", signal, "\ref[netcard]")

		report_event(var/event_string)
			if (!event_string || !radiocard)
				return

			//Unlikely that this would be a problem but OH WELL
			if (last_event_report && world.time < (last_event_report + 10))
				return

			//Set card frequency if it isn't already.
			if (radiocard.frequency != setup_mail_freq && !radiocard.setup_freq_locked)
				var/signal/freqsignal = get_free_signal()
				//freqsignal.encryption = "\ref[radiocard]"
				peripheral_command("[setup_mail_freq]", freqsignal,"\ref[radiocard]")
				src.log_string += "<br>Adjusting frequency... \[[src.setup_mail_freq]]."

			var/signal/signal = get_free_signal()
			//signal.encryption = "\ref[radiocard]"

			//Create a PDA mass-message string.
			signal.data["address_1"] = "00000000"
			signal.data["command"] = "text_message"
			signal.data["sender_name"] = "ENGINE-MAILBOT"
			signal.data["group"] = setup_mailgroup //Only engineer PDAs should be informed.
			signal.data["message"] = "Notice: [event_string]"

			log_string += "<br>Event notification sent."
			last_event_report = world.time
			peripheral_command("transmit", signal, "\ref[radiocard]")
			return

		find_access_file() //Look for the whimsical account_data file
			var/computer/folder/accdir = holder.root
			if (master.host_program) //Check where the OS is, preferably.
				accdir = master.host_program.holder.root

			var/computer/file/user_data/target = parse_file_directory(setup_acc_filepath, accdir)
			if (target && istype(target))
				account = target
				return TRUE

			return FALSE
#endif