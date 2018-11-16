//Small programs not worthy of their own file
//CONTENTS
//Background program base
//Signal interceptor program
//Ping program
//Terminal client / File transfer program
//Signal file creator/editor
//Disease research program
//Artifact research program
//Crew manifest program
//Robotics research.

#define MAX_BACKGROUND_PROGS 7//If staying resident would leave us with more than this, don't do it.

//A program designed to remain processing while the user executes more interesting programs
/computer/file/terminal_program/background
	name = "Background"
	size = 4


	//It's like having the master unload it, but it remains processing.
	proc/exit_stay_resident()
		if ((!holder) || (!master))
			return TRUE

		if ((!istype(holder)) || (!istype(master)))
			return TRUE

		if (!(holder in master.contents))
			if (master.active_program == src)
				master.active_program = null
			master.processing_programs.Remove(src)
			return TRUE

		if (master.processing_programs.len > MAX_BACKGROUND_PROGS) //Don't want too many background programs.
			return TRUE

		if (!(src in master.processing_programs))
			master.processing_programs.Add(src)

		master.active_program = master.host_program

		return FALSE

//Signal interception program
/computer/file/terminal_program/background/signal_catcher
	name = "SigCatcher"
	var/active = 1 //Are we currently catching signals?
	var/logging = 0
	var/list/working_signal = list()
	var/last_command = null
	var/computer/file/text/logfile = null

	var/const/max_working_signal_len = 8
	var/const/logfile_path = "signal_log"

	initialize()
		print_text("Signal Catcher 1.2<br>Commands: \"active \[ON/OFF/AUTO],\" \"Save \[filename]\" as signal, \"View\" current signal.<br>\"Quit\" to exit but remain in memory, \"FQuit\" to quit normally.")

	disposing()
		working_signal = null
		logfile = null

		..()

	input_text(text)
		if (..())
			return

		var/list/command_list = parse_string(text)
		var/command = command_list[1]
		command_list -= command_list[1]

		print_text(strip_html(text))

		switch(lowertext(command))
			if ("active") //Determine whether we are catching incoming signals or not
				var/argument1 = null
				if (command_list.len)
					argument1 = command_list[1]

				switch(lowertext(argument1))
					if ("on")
						active = 1

					if ("off")
						active = 0

					if ("auto")
						active = 2

					else
						active = !active

				print_text("Signal Catching is now [active ? "ON" : "OFF"]")

			if ("log") //Determine whether we should log incoming signals.
				var/argument1 = null
				if (command_list.len)
					argument1 = command_list[1]

				switch(lowertext(argument1))
					if ("on")
						logging = 1

					if ("off")
						logging = 0

					else
						logging = !logging

				print_text("Signal Logging is now [logging ? "ON" : "OFF"]")


			if ("view")
				if (!working_signal || !working_signal.len)
					print_text("Error, no signal loaded.")
					return
				else
					print_text("Current signal:<br>Last Command: [last_command ? last_command : "None"]")
					for (var/x = 1, x <= working_signal.len, x++)
						var/part = "\[UNUSED]"
						if (x <= working_signal.len)
							var/title_text = working_signal[x]
							var/main_text = working_signal[title_text]
							part = " \[[isnull(title_text) ? "Untitled" : title_text]] \[[isnull(main_text) ? "Blank" : copytext(strip_html(main_text), 1, 25)]]"

						print_text("\[[x]] [part]")

			if ("save")
				var/new_name = strip_html(jointext(command_list, " "))
				new_name = copytext(new_name, 1, 16)

				if (!new_name)
					print_text("Syntax: \"save \[file name]\"")
					return

				var/computer/file/signal/saved = get_file_name(new_name, holding_folder)
				if (saved && !istype(saved) || get_folder_name(new_name, holding_folder))
					print_text("Error: Name in use.")
					return

				if (is_name_invalid(new_name))
					print_text("Error: Invalid character in name.")
					return

				if (saved && istype(saved))
					saved.data = working_signal.Copy()
				else
					saved = new /computer/file/signal
					saved.name = new_name
					saved.data = working_signal.Copy()
					if (!holding_folder.add_file(saved))
						//qdel(saved)
						saved.dispose()
						print_text("Error: Cannot save to disk.")
						return

				print_text("Signal \"[new_name]\" saved.")

			if ("help")
				print_text("Commands: \"active \[ON/OFF],\" \"Save \[filename]\" as signal, \"View\" current signal.<br>\"Quit\" to exit but remain in memory, \"FQuit\" to quit normally.")

			if ("quit")
				print_text("Now returning to OS. Program will remain in background.")
				if (exit_stay_resident())
					print_text("Error: Background Memory full.")

					master.unload_program(src)
					return

			if ("fquit")
				src.print_text("Now Fully Quitting...")
				master.unload_program(src)
				return

			else
				print_text("Unknown Command.")

		master.add_fingerprint(usr)
		master.updateUsrDialog()
		return

	receive_command(obj/source, command, signal/signal)
		if ((..()) || (!signal) || !src.active)
			return

		//Auto mode means shutoff after next signal
		if (active == 2) active = 0

		working_signal = signal.data:Copy()
		src.working_signal.len = min(src.working_signal.len, max_working_signal_len)
		last_command = command
		if (logging && !holder.read_only)
			if (!logfile)
				logfile = parse_file_directory(logfile_path)
				if (!istype(logfile))
					logfile = new /computer/file/text
					logfile.name = logfile_path
					if (!holding_folder.add_file(logfile))
						//qdel(logfile)
						logfile.dispose()
						return

			logfile.data += "<br>"
			for (var/i = 1, i <= working_signal.len, i++)
				logfile.data += "<br>[working_signal[i]]: [working_signal[working_signal[i]]]"

		return

//Pnet ping program.
/computer/file/terminal_program/background/ping
	name = "Ping"
	var/active = 1
	var/list/replies = list() //Replies to our ping request.
	var/obj/item/peripheral/network/ping_card = null //The card we are actually going to use to send pings.

	initialize()
		ping_card = null
		print_text("Ping! V4.92<br>Commands: \"Ping\" to ping network. \"View\" to view prevous ping data.<br>\"Quit\" to exit but remain in memory, \"FQuit\" to quit normally.")

		ping_card = find_peripheral("NET_ADAPTER")
		if (!ping_card || !istype(ping_card))
			ping_card = null
			print_text("Error:No network card detected.")

		return

	disposing()
		ping_card = null
		replies = null

		..()

	input_text(text)
		if (..())
			return

		var/list/command_list = parse_string(text)
		var/command = command_list[1]
		command_list -= command_list[1]

		print_text(strip_html(text))

		switch(lowertext(command))
			if ("ping")
				if (!ping_card)
					print_text("Error: Network card required.")
					return

				var/signal/newsignal = get_free_signal()
				newsignal.encryption = "\ref[ping_card]" //No need to actually set data on it
				//The signal is really only needed to target our ping card for the job.

				src.print_text("Pinging...")
				replies = new
				peripheral_command("ping", null, "\ref[ping_card]")

			if ("view")
				if (!replies || !replies.len)
					print_text("Error, no reply data found.")
					return
				else
					print_text("Reply List:")
					var/part = null
					for (var/x = 1, x <= replies.len, x++)
						var/reply_id = replies[x]
						var/reply_device = replies[reply_id]
						part += " \[[isnull(reply_id) ? "ERR: ID" : reply_id]]-TYPE: [isnull(reply_device) ? "ERR: DEVICE" : reply_device]<br>"

					if (part)
						print_text(part)


			if ("help")
				print_text("Commands: \"Ping\" to ping network. \"View\" to view prevous ping data.<br>\"Quit\" to exit but remain in memory, \"FQuit\" to quit normally.")

			if ("quit")
				print_text("Now returning to OS. Program will remain in background.")
				if (exit_stay_resident())
					print_text("Error: Background Memory full.")

					master.unload_program(src)
					return

			if ("fquit")
				src.print_text("Now Fully Quitting...")
				master.unload_program(src)
				return

			else
				print_text("Unknown Command.")

		master.add_fingerprint(usr)
		master.updateUsrDialog()
		return

	receive_command(obj/source, command, signal/signal)
		if ((..()) || (!signal) || !src.active)
			return

		//If we get a ping reply, add it to the list and print it.
		if (signal.data["command"] == "ping_reply")
			if (!signal.data["device"] || !signal.data["netid"])
				return

			var/reply_device = signal.data["device"]
			var/reply_id = signal.data["netid"]
			//boutput(world, "device: [reply_device] id: [reply_id]")
			replies[reply_id] = reply_device
			print_text("\[[reply_id]]-TYPE: [reply_device]")

		return

//Pnet file transfer program.
/computer/file/terminal_program/file_transfer
	name = "FROG"
	var/tmp/serv_id = null //NetID of connected server
	var/tmp/last_serv_id = null //Last valid serv_id.
	var/tmp/attempt_id = null //Are we attempting to connect to something?
	var/obj/item/peripheral/network/pnet_card = null
	var/tmp/disconnect_wait = -1 //Are we waiting to disconnect?
	var/tmp/ping_wait = 0 //Are we waiting for a ping reply?
	var/auto_accept = 1 //Do we automatically accept connection attempts?
	var/tmp/service_mode = 0

	var/tmp/computer/file/temp_file

	var/setup_acc_filepath = "/logs/sysusr"//Where do we look for login data?

	initialize()
		attempt_id = null
		pnet_card = null
		var/introdat = "FROG Terminal Client V1.3<br>Copyright 2053 Thinktronic Systems, LTD."

		pnet_card = find_peripheral("NET_ADAPTER")
		if (!pnet_card || !istype(pnet_card))
			pnet_card = find_peripheral("RAD_ADAPTER")
			if (istype(pnet_card))
				peripheral_command("mode_net", null, "\ref[pnet_card]")
				introdat += "<br>Network card detected."
			else
				if (serv_id)
					serv_id = null

				ping_wait = 0
				disconnect_wait = 0
				serv_id = null

				pnet_card = null
				introdat += "<br>Error: No network card detected."

		if (pnet_card)
			introdat += "<br>Network ID: [pnet_card.net_id]"

			if (serv_id) //We have been rebooted or force-closed OR SOMETHING, so disconnect.
				var/signal/termsignal = get_free_signal()

				termsignal.data["address_1"] = serv_id
				termsignal.data["command"] = "term_disconnect"

				peripheral_command("transmit", termsignal, "\ref[pnet_card]")

				ping_wait = 0
				disconnect_wait = 0
				serv_id = null

		print_text(introdat + "<br>Ready.")

		return

	process()
		if (..())
			return

		if (ping_wait)
			ping_wait--

		if (disconnect_wait > 0)
			disconnect_wait--
			if (disconnect_wait == 0)
				print_text("Timed out. Please retry.")
				serv_id = null
				attempt_id = null

	input_text(text)
		if (..())
			return

		var/list/command_list = parse_string(text)
		var/command = lowertext(command_list[1])
		command_list -= command_list[1]

		print_text(">[strip_html(text)]")

		if (disconnect_wait > 0)
			print_text("Alert: System busy, please hold.")
			return

		if (command == "help" && !serv_id)
			var/help_message = {"Terminal Commands:<br>
term_status - View current status of terminal.<br>
term_accept - Toggle connection auto-accept.<br>
term_login - Transmit login file (ID Required)<br>
term_ping - Scan network for terminal devices.<br>
term_break - Send break signal to host.<br>
Connection Commands:<br>
connect \[Net ID] - Connect to a specified device.<br>
disconnect - Disconnect from current device.
File Commands<br>
file_status - View status of loaded file.<br>
file_send - Transmit loaded file.<br>
file_print - Print contents of file.<br>
file_load - Load file from local disk.
file_save - Save file to local disk."}
			print_text(help_message)
			return

		switch(command)
			if ("term_status")
				if (pnet_card)
					var/statdat = pnet_card.return_status_text()
					print_text("[pnet_card.func_tag]<br>Status: [statdat]")
				else
					print_text("No network card detected.")

				print_text("Current Server Address: [serv_id ? serv_id : "NONE"]<br>Auto-accept connections is [auto_accept ? "ON" : "OFF"]<br>Toggle this with \"term_accept\"[service_mode ? "<br>Service mode active." : ""]")

			if ("term_accept")
				auto_accept = !auto_accept
				print_text("Auto-Accept is now [auto_accept ? "ON" : "OFF"]")


			if ("term_break")
				if (!serv_id || !pnet_card)
					return

				var/signal/termsignal = get_free_signal()
				//termsignal.encryption = "\ref[netcard]"
				termsignal.data["address_1"] = serv_id
				termsignal.data["command"] = "term_break"

				peripheral_command("transmit", termsignal, "\ref[pnet_card]")

			if ("term_ping")
				if (serv_id)
					print_text("Alert: Cannot ping while connected.")
					return

				if (!pnet_card)
					print_text("Alert: No network card detected.")
					return

				var/signal/newsignal = get_free_signal()
				newsignal.encryption = "\ref[pnet_card]"
				ping_wait = 4

				src.print_text("Pinging...")
				peripheral_command("ping", newsignal, "\ref[pnet_card]")

			if ("term_service")
				if (serv_id)
					print_text("Alert: Cannot switch mode while connected.")
					return

				service_mode = !service_mode
				print_text("Service mode [service_mode ? "" : "de"]activated.")

			if ("term_login")
				var/obj/item/peripheral/scanner = find_peripheral("ID_SCANNER")
				if (!scanner)
					print_text("Error: No ID scanner detected.")
					return
				if (!pnet_card)
					print_text("Alert: No network card detected.")
					return
				if (!serv_id)
					print_text("Alert: Connection required.")
					return
				ping_wait = 2

				var/signal/scansignal = peripheral_command("scan_card",null,"\ref[scanner]")
				if (istype(scansignal))
					var/computer/file/record/udat = new
					udat.fields["registered"] = scansignal.data["registered"]
					udat.fields["assignment"] = scansignal.data["assignment"]
					udat.fields["access"] = scansignal.data["access"]
					if (!udat.fields["access"] || !udat.fields["assignment"] || !udat.fields["access"])
						//qdel(udat)
						udat.dispose()
						return

					var/signal/termsignal = get_free_signal()
					//termsignal.encryption = "\ref[netcard]"
					termsignal.data["address_1"] = serv_id
					termsignal.data["command"] = "term_file"
					termsignal.data["data"] = "login"
					termsignal.data_file = udat

					peripheral_command("transmit", termsignal, "\ref[pnet_card]")
					return


			if ("connect")
				if (serv_id)
					print_text("Alert: Terminal is already connected.")
					return

				if (attempt_id)
					print_text("Alert: Already attempting to connect.")
					return

				var/argument1 = null
				if (command_list.len)
					argument1 = command_list[1]

				argument1 = ckey(copytext(argument1, 1, 9))
				if (!argument1 || (length(argument1) != 8))
					print_text("Alert: Invalid ID. (Must be 8 characters.)")
					return

				attempt_id = argument1

				var/computer/file/user_data/user_data = get_user_data()
				var/computer/file/record/udat = null
				if (istype(user_data))
					udat = new
					udat.fields["registered"] = user_data.registered
					if (service_mode)
						udat.fields["userid"] = format_username(user_data.registered)

					udat.fields["assignment"] = user_data.assignment
					udat.fields["access"] = list2params(user_data.access)
					if (!udat.fields["registered"] || !udat.fields["assignment"] || !udat.fields["access"])
						//qdel(udat)
						udat.dispose()
						print_text("Error: User credential validity error.")
						return

				var/signal/termsignal = get_free_signal()

				termsignal.data["address_1"] = argument1
				termsignal.data["command"] = "term_connect"
				termsignal.data["device"] = "[service_mode ? "SRV" : "HUI"]_TERMINAL"
				if (istype(udat))
					termsignal.data_file = udat

				disconnect_wait = 4

				src.print_text("Attempting to connect...")
				peripheral_command("transmit", termsignal, "\ref[pnet_card]")

			if ("reconnect")
				if (serv_id)
					print_text("Alert: Terminal is already connected.")
					return

				if (attempt_id)
					print_text("Alert: Already attempting to connect.")
					return

				if (!last_serv_id)
					print_text("Alert: No prior connection address in memory.")
					return

				attempt_id = last_serv_id

				var/signal/termsignal = get_free_signal()
				//termsignal.encryption = "\ref[netcard]"
				termsignal.data["address_1"] = attempt_id
				termsignal.data["command"] = "term_connect"
				termsignal.data["device"] = "[service_mode ? "SRV" : "HUI"]_TERMINAL"
				disconnect_wait = 4

				src.print_text("Attempting to reconnect to \[[src.attempt_id]]...")
				peripheral_command("transmit", termsignal, "\ref[pnet_card]")

			if ("disconnect")
				if (serv_id)
					var/signal/termsignal = get_free_signal()

					termsignal.data["address_1"] = serv_id
					termsignal.data["command"] = "term_disconnect"
					serv_id = null

					peripheral_command("transmit", termsignal, "\ref[pnet_card]")
					print_text("Connection Closed.")
					disconnect_wait = -1

			if ("file_load")
				var/toLoadName = "temp"
				if (command_list.len)
					toLoadName = jointext(command_list, "")

				var/computer/file/loadedFile = parse_file_directory(toLoadName,holding_folder)

				if (istype(loadedFile))
					print_text("File loaded.")
					temp_file = loadedFile
					return

				print_text("Alert: File not found (or invalid).")
				return

			if ("file_save")
				if (!temp_file)
					print_text("Error: No file to save!")
					return

				var/toSaveName = "temp"
				if (command_list.len)
					toSaveName = jointext(command_list, "")

				var/computer/file/record/saved = get_file_name(toSaveName, holding_folder)
				if (saved || get_folder_name(toSaveName, holding_folder))
					print_text("Error: Name in use.")
					return

				if (is_name_invalid(toSaveName))
					print_text("Error: Invalid character in name.")
					return

				saved = temp_file.copy_file()
				if (!saved)
					print_text("Error: Cannot save to disk.")
					return

				if (!holding_folder.add_file(saved))
					saved.dispose()
					print_text("Error: Cannot save to disk.")
					return

				print_text("File saved.")
				return

			if ("file_send")
				if (!istype(temp_file))
					print_text("Alert: No file loaded.")
					return

				if (!serv_id)
					print_text("Alert: Connection required.")
					return

				var/sendText = "login"
				if (command_list.len)
					sendText = jointext(command_list, " ")

				send_term_message(sendText, 1)
				print_text("File sent.")

			if ("file_status")
				if (!temp_file || !istype(temp_file))
					print_text("Alert: No file loaded.")
					return

				var/file_info = "[temp_file.name] - [temp_file.extension] - \[Size: [temp_file.size]]<br>Enter command \"file_save\" to save to external disk."
				if (istype(temp_file, /computer/file/text))
					file_info += "<br>Enter command \"file_print\" to print."
				else
					file_info += "<br>Unrecognized filetype."

				print_text(file_info)

			if ("file_print")
				if (!temp_file)
					print_text("Alert: File invalid or missing.")
					return

				var/to_print = temp_file.asText()
				if (!to_print)
					print_text("Alert: Nothing to print.")
					return

				src.print_text("Sending print command...")
				var/signal/printsig = new
				printsig.data["data"] = to_print
				printsig.data["title"] = "Printout"

				peripheral_command("print",printsig)

			if ("quit")
				if (serv_id)
					var/signal/termsignal = get_free_signal()

					termsignal.data["address_1"] = serv_id
					termsignal.data["command"] = "term_disconnect"
					serv_id = null

					peripheral_command("transmit", termsignal, "\ref[pnet_card]")
					print_text("Connection Closed.")
					disconnect_wait = -1

				src.print_text("Now Quitting...")
				master.unload_program(src)
				return

			else
				send_term_message(text)

		master.add_fingerprint(usr)
		master.updateUsrDialog()
		return

	disk_ejected(var/obj/item/disk/data/thedisk)
		if (!thedisk)
			return

		if (holder == thedisk)
			if (serv_id)
				var/signal/termsignal = get_free_signal()

				termsignal.data["address_1"] = serv_id
				termsignal.data["command"] = "term_disconnect"
				serv_id = null

				peripheral_command("transmit", termsignal, "\ref[pnet_card]")
				disconnect_wait = -1

			src.print_text("<font color=red>Fatal Error. Returning to system...</font>")
			master.unload_program(src)
			return

		return

	receive_command(obj/source, command, signal/signal)
		if ((..()) || (!signal))
			return

		if (!serv_id || signal.data["sender"] != serv_id)
			if (cmptext(signal.data["command"], "ping_reply") && ping_wait)
				if (!signal.data["device"] || !signal.data["netid"])
					return

				var/reply_device = signal.data["device"]
				var/reply_id = signal.data["netid"]

				print_text("P: \[[reply_id]]-TYPE: [reply_device]")

			//oh, somebody trying to connect!
			else if (cmptext(signal.data["command"], "term_connect") && !serv_id)
				if (!attempt_id && signal.data["sender"] && auto_accept)
					serv_id = signal.data["sender"]
					disconnect_wait = -1
					print_text("Connection established to [serv_id]!")
					//well okay but now they need to know we've accepted!
					if (signal.data["data"] != "noreply")
						var/signal/termsignal = get_free_signal()

						termsignal.data["address_1"] = signal.data["sender"]
						termsignal.data["command"] = "term_connect"

						peripheral_command("transmit", termsignal, "\ref[pnet_card]")


				else if (cmptext(signal.data["sender"], attempt_id))
					attempt_id = null
					serv_id = signal.data["sender"]
					disconnect_wait = -1
					print_text("Connection to [serv_id] successful.")

		if (cmptext(signal.data["sender"], serv_id))
			switch(lowertext(signal.data["command"]))
				if ("term_message")
					var/new_message = signal.data["data"]
					if (!new_message)
						return

					switch(lowertext(signal.data["render"]))
						if ("clear") //They want the screen clear before printing
							master.temp = null

						if ("multiline") //Oh, they want multiple lines of stuff.
							new_message = replacetext(new_message, "|n", "<br>]")

						if ("multiline|clear","clear|multiline") //Both of the above!
							master.temp = null
							new_message = replacetext(new_message, "|n", "<br>]")

					print_text("][new_message]")
					return

				if ("term_file") //oh boy, a file!
					if (!signal.data_file || !istype(signal.data_file))
						return //oh no the file is bad
/*
					//Will it fit? Check before clearing out our old temp file!
					if ((holder.file_used + signal.data_file.size) > holder.file_amount)
						print_text("Alert: Unable to accept file transfer, disk is full!")
						return
*/
					if (temp_file && !temp_file.holding_folder)
						temp_file.dispose()

					temp_file = signal.data_file.copy_file()
					temp_file.name = "temp"
					print_text("Alert: File received from remote host!<br>Valid commands: file_status, file_print")

				if ("term_ping")
					if (signal.data["data"] == "reply")
						var/signal/termsignal = get_free_signal()

						termsignal.data["address_1"] = signal.data["sender"]
						termsignal.data["command"] = "term_ping"

						peripheral_command("transmit", termsignal, "\ref[pnet_card]")
					return

				if ("term_disconnect")
					serv_id = null
					attempt_id = null

					print_text("Connection closed by remote host.")
					return

		return

	proc/send_term_message(var/message, send_file)
		if (!message || !serv_id || !pnet_card)
			return

		message = strip_html(message)

		var/signal/termsignal = get_free_signal()

		termsignal.data["address_1"] = serv_id
		termsignal.data["data"] = message
		termsignal.data["command"] = "term_[send_file ? "file" : "message"]"
		if (send_file && temp_file)
			termsignal.data_file = temp_file.copy_file()

		peripheral_command("transmit", termsignal, "\ref[pnet_card]")
		return

	proc/get_user_data()
		var/computer/folder/accdir = holder.root
		if (master.host_program) //Check where the OS is, preferably.
			accdir = master.host_program.holder.root

		var/computer/file/user_data/target = parse_file_directory(setup_acc_filepath, accdir)
		if (target && istype(target))
			return target

		return null

#define WORKING_PACKET_MAX 32

/computer/file/terminal_program/sigpal
	name = "SigPal"
	size = 4
	var/list/working_signal = list()
	var/obj/item/peripheral/network/pnet_card
	var/computer/file/attached_file = null

	disposing()
		pnet_card = null
		working_signal = null
		attached_file = null
		..()

	initialize()
		working_signal = list()
		pnet_card = null
		attached_file = null
		var/introdat = "SigPal Signal Manager<br>Copyright 2053 Thinktronic Systems, LTD."

		pnet_card = find_peripheral("NET_ADAPTER")
		if (!pnet_card || !istype(pnet_card))
			pnet_card = find_peripheral("RAD_ADAPTER")
			if (istype(pnet_card))
				peripheral_command("mode_net", null, "\ref[pnet_card]")
				introdat += "<br>Network card detected (Radio)."
			else

				pnet_card = null
				introdat += "<br>Error: No network card detected."

		if (pnet_card)
			introdat += "<br>Network ID: [pnet_card.net_id]"


		print_text("[introdat]<br>Type \"help\" for commands.")


	input_text(text)
		if (..())
			return

		var/list/command_list = parse_string(text)
		var/command = command_list[1]
		command_list -= command_list[1] //Remove the command we are now processing.

		switch(lowertext(command))
			if ("help")
				print_text("Command List:<br> ADD \[key] \[data]  to add (or replace) a key-value pair to the packet.<br> REMOVE \[key]  to remove existing key pair <br> VIEW  to view current packet.<br> SEND  to transmit packet over network card.<br> SAVE/LOAD \[file name] to save/load the signal as a record.<br> NEW to clear current signal.<br> FILE to set an attachment to send (This is not saved to disk)")
				return

			if ("add")
				var/key = null
				var/data = null
				. = 0
				if (command_list.len >= 2)

					key = command_list[1]
					command_list -= command_list[1]
					key = copytext(lowertext(strip_html(key)), 1, 128)

					data = jointext(command_list, " ")
					data = copytext(strip_html(data), 1, 256)

				if (!ckey(key) || ckey(!data))
					print_text("Syntax: \"add \[key] \[data]\"")
					return

				if (working_signal.len >= WORKING_PACKET_MAX)
					print_text("Error: Maximum packet keys reached.")
					return

				if (!isnull(working_signal[key]))
					. = 1

				working_signal[key] = data
				print_text("Addition complete. (Signal length: \[[working_signal.len]])[. ? "<br>That key was already present and has been modified." : ""]")

			if ("remove")
				var/key = lowertext(command_list[1])
				if (key in working_signal)
					working_signal -= key
					print_text("Key removed. (Signal length: \[[working_signal.len]])")
				else
					print_text("Key not present.")

			if ("send","transmit")
				if (!working_signal.len)
					print_text("Error: Cannot send empty packet.")
					return

				if (!pnet_card)
					print_text("Error: No network card present!")
					return

				var/signal/sig = get_free_signal()
				for (var/entry in working_signal)
					var/equalpos = findtext("=", entry)
					if (equalpos)
						sig.data["[copytext(entry, 1, equalpos)]"] = "[copytext(entry, equalpos)]"
					else
						if (!isnull(working_signal[entry]))
							sig.data["[entry]"] = working_signal[entry]
						else
							sig.data += entry

				if (attached_file)
					sig.data_file = attached_file

				peripheral_command("transmit", sig, "\ref[pnet_card]")
				print_text("Packet sent.")

			if ("view")
				if (!working_signal.len)
					print_text("The current packet is empty.")
					return

				. = ""
				for (var/key in working_signal)
					. += "[key] = [working_signal[key]]<br>"


				print_text(.)
				return

			if ("save")
				var/new_name = strip_html(jointext(command_list, " "))
				new_name = copytext(new_name, 1, 16)

				if (!new_name)
					print_text("Syntax: \"SAVE \[file name]\"")
					return

				var/computer/file/record/saved = get_file_name(new_name, holding_folder)
				if (saved && !istype(saved) || get_folder_name(new_name, holding_folder))
					print_text("Error: Name in use.")
					return

				if (is_name_invalid(new_name))
					print_text("Error: Invalid character in name.")
					return

				if (saved && istype(saved))
					saved.fields = working_signal.Copy()
				else
					saved = new /computer/file/record
					saved.name = new_name
					saved.fields = working_signal.Copy()
					if (!holding_folder.add_file(saved))
						//qdel(saved)
						saved.dispose()
						print_text("Error: Cannot save to disk.")
						return

				print_text("Record \"[new_name]\" saved.")

			if ("load")
				var/file_name = ckey(jointext(command_list, " "))

				if (!file_name)
					print_text("Syntax: \"LOAD \[file name]\"")
					return

				var/computer/file/record/to_load = get_file_name(file_name, holding_folder)
				if (!to_load || !istype(to_load))
					print_text("Error: File not found or corrupt.")
					return

				working_signal = to_load.fields.Copy()
				working_signal.len = min(working_signal.len, WORKING_PACKET_MAX)

				print_text("Load complete.")

			if ("new")
				working_signal = list()
				attached_file = null
				print_text("Signal cleared.")

			if ("file")
				var/file_name = ckey(jointext(command_list, " "))

				if (!file_name)
					attached_file = null
					print_text("File attachment cleared.")
					return

				var/computer/file/to_load = get_file_name(file_name, holding_folder)
				if (!istype(to_load))
					print_text("Error: File not found or corrupt.")
					return

				attached_file = to_load.copy_file()

			if ("quit","exit")
				master.temp = ""
				print_text("Now quitting...")
				master.unload_program(src)
				return

			else
				print_text("Unknown command.")

#undef WORKING_PACKET_MAX

/computer/file/terminal_program/sigcrafter
	name = "SigCraft"
	size = 4
	var/temp= null
	var/computer/file/included_file = null //File to include in signal file.
	var/list/text_buffer = list()
	var/list/working_signal = list()
	var/selected_line = 1 //Which line of the signal are we working on?

#define WORKING_DISPLAY_LENGTH 8 //How many lines is the working portion?

	input_text(text)
		if (..())
			return

		var/list/command_list = parse_string(text)
		var/command = command_list[1]
		command_list -= command_list[1] //Remove the command we are now processing.

		switch(lowertext(command))
			if ("line") //Set working line to provided num.
				var/target_line = 0
				if (command_list.len)
					target_line = round(text2num(command_list[1]))
				else
					print_half_text("Line number required.")
					return


				if ((!target_line) || (target_line > WORKING_DISPLAY_LENGTH) || (target_line <= 0))
					print_half_text("Error: Line invalid or out of bounds.")
					return

				selected_line = target_line
				print_half_text("Active line set to [target_line].")

			if ("add") //Add new line to signal if possible.
				var/title = null
				var/data = null
				if (command_list.len >= 2)

					title = command_list[1]
					command_list -= command_list[1]
					title = copytext(lowertext(strip_html(title)), 1, 16)

					data = jointext(command_list, " ")
					data = copytext(strip_html(data), 1, 255)

				if (!ckey(title) || ckey(!data))
					print_half_text("Syntax: \"add \[title] \[data]\"")
					return

				if (working_signal.len >= WORKING_DISPLAY_LENGTH)
					print_half_text("Error: Working Signal Full.")
					return

				if (!isnull(working_signal[title]))
					print_half_text("Error: Title already in use.")
					return

				working_signal[title] = data
				print_half_text("Addition complete. (Signal length: \[[working_signal.len]])")

			if ("view")
				if ((selected_line > working_signal.len) || (selected_line <= 0))
					print_half_text("Error: Working line out of bounds.")
					return

				print_half_text("L\[[selected_line]]: [working_signal[working_signal[selected_line]]]")

			if ("remove")
				if ((selected_line > working_signal.len) || (selected_line <= 0))
					print_half_text("Error: Working line out of bounds.")
					return

				working_signal -= working_signal[selected_line]

				print_half_text("Line \[[selected_line]] cleared.")

			if ("load")
				var/file_name = ckey(jointext(command_list, " "))

				if (!file_name)
					print_half_text("Syntax: \"load \[file name]\"")
					return

				var/computer/file/signal/to_load = get_file_name(file_name, holding_folder)
				if (!to_load || !istype(to_load))
					print_half_text("Error: File not found or corrupt.")
					return

				working_signal = to_load.data.Copy()
				working_signal.len = min(working_signal.len, WORKING_DISPLAY_LENGTH)
				included_file = null
				if (to_load.data_file)
					included_file = to_load.data_file.copy_file()

				print_half_text("Load complete.")

			if ("save")
				var/new_name = strip_html(jointext(command_list, " "))
				new_name = copytext(new_name, 1, 16)

				if (!new_name)
					print_half_text("Syntax: \"save \[file name]\"")
					return

				var/computer/file/signal/saved = get_file_name(new_name, holding_folder)
				if (saved && !istype(saved) || get_folder_name(new_name, holding_folder))
					print_half_text("Error: Name in use.")
					return

				if (is_name_invalid(new_name))
					print_half_text("Error: Invalid character in name.")
					return

				if (saved && istype(saved))
					saved.data = working_signal.Copy()
					if (saved.data_file)
						//qdel(saved.data_file)
						saved.data_file.dispose()
					if (included_file)
						saved.data_file = included_file.copy_file()
				else
					saved = new /computer/file/signal
					saved.name = new_name
					saved.data = working_signal.Copy()
					if (included_file)
						saved.data_file = included_file.copy_file()
					if (!holding_folder.add_file(saved))
//						qdel(saved)
						saved.dispose()
						print_half_text("Error: Cannot save to disk.")
						return

				print_half_text("Signal \"[new_name]\" saved.")

			if ("recsave")
				var/new_name = strip_html(jointext(command_list, " "))
				new_name = copytext(new_name, 1, 16)

				if (!new_name)
					print_half_text("Syntax: \"recsave \[file name]\"")
					return

				var/computer/file/record/saved = get_file_name(new_name, holding_folder)
				if (saved && !istype(saved) || get_folder_name(new_name, holding_folder))
					print_half_text("Error: Name in use.")
					return

				if (is_name_invalid(new_name))
					print_half_text("Error: Invalid character in name.")
					return

				if (saved && istype(saved))
					saved.fields = working_signal.Copy()
				else
					saved = new /computer/file/record
					saved.name = new_name
					saved.fields = working_signal.Copy()
					if (!holding_folder.add_file(saved))
						//qdel(saved)
						saved.dispose()
						print_half_text("Error: Cannot save to disk.")
						return

				print_half_text("Record \"[new_name]\" saved.")

			if ("file")
				var/inc_path = jointext(command_list, " ")
				if (!ckey(inc_path))
					print_half_text("Syntax: \"file \[filepath]\"")
					print_half_text("Path of file to include in signal.")
					print_half_text("Current: [istype(included_file) ? included_file.name : "NONE"]")
					return

				var/computer/file/to_inc = parse_file_directory(inc_path, holding_folder)
				if (!istype(to_inc))
					print_half_text("Error: Invalid filepath!")
					return

				included_file = to_inc.copy_file()
				print_half_text("File set.")

			if ("new")
				working_signal = get_free_signal()
				if (included_file)
					//qdel(included_file)
					included_file.dispose()
				print_half_text("Work cleared.")

			if ("help")
				print_half_text("Commands: Add \[Title] \[Data], Line \[line],")
				print_half_text("Load/Save/RecSave \[file], File \[path], New, Remove")
				print_half_text("Help, Quit.")

			if ("quit")
				master.temp = ""
				print_text("Now quitting...")
				master.unload_program(src)
				return

			else
				print_half_text("Unknown command : \"[copytext(strip_html(command), 1, 16)]\"")

		master.add_fingerprint(usr)
		master.updateUsrDialog()
		return

	initialize()
		//Set working lists back to normal...
		text_buffer = new
		working_signal = get_free_signal()
		//Their length should be fixed up by the first print_half_text call
		print_half_text("Signal Crafter 2.0")
		print_half_text("Commands: Add \[Title] \[Data], Line \[line],")
		print_half_text("Load/Save \[file], File \[path], New, Remove, Recsave \[file]")
		print_half_text("Help, Quit.")

	/* new disposing() pattern should handle this. -singh
	Del()
		if (included_file)
			qdel(included_file)
		..()
	*/

	disposing()
		if (included_file)
			included_file.dispose()
			included_file = null

		text_buffer = null
		working_signal = null
		..()

	proc
		print_half_text(var/text) //Print stuff to the screen while keeping the signal info up
			if ((!holder) || (!master) || !text || disposed)
				return TRUE

			if ((!istype(holder)) || (!istype(master)))
				return TRUE

			if (master.stat & (NOPOWER|BROKEN))
				return TRUE

			if (!(holder in master.contents))
				if (master.active_program == src)
					master.active_program = null
				return TRUE

			if (!holder.root)
				holder.root = new /computer/folder
				src.holder.root.holder = src
				holder.root.name = "root"

			if (text_buffer.len >= 6)
				text_buffer -= text_buffer[1]

			text_buffer += text

			selected_line = max(min(selected_line, 8), 1)

			if (!istype(working_signal, /list))
				working_signal = list()

			var/dat = "<center>Current Signal</center><br>"
			for (var/x = 1, x <= WORKING_DISPLAY_LENGTH, x++)
				var/part = "\[UNUSED]"
				if (x <= working_signal.len)
					var/title_text = working_signal[x]
					var/main_text = working_signal[title_text]
					part = " \[[isnull(title_text) ? "Untitled" : title_text]] \[[isnull(main_text) ? "Blank" : copytext(main_text, 1, 25)]]"
				if (selected_line == x)
					dat += ">\[[x]] [part]<br>"
				else
					dat += "|\[[x]] [part]<br>"

			dat += "<hr>"

			for (var/x in text_buffer)
				dat += "[x]<br>"

			master.temp = null
			master.temp_add = "[dat]"
			master.updateUsrDialog()

			return FALSE

#undef WORKING_DISPLAY_LENGTH

/computer/file/terminal_program/disease_research

/computer/file/terminal_program/artifact_research

/computer/file/terminal_program/manifest
	name = "Manifest"
	size = 4


	initialize()

		var/dat = "Crew Manifest<br>Entries cannot be modified from this terminal.<br>"

		for (var/data/record/t in REPO.data_core.general)
			dat += "[t.fields["name"]] - [t.fields["rank"]]<br>"

		master.temp = null
		src.print_text("[dat]Now exiting...")
		master.unload_program(src)

		return

/computer/file/terminal_program/robotics_research

#undef MAX_BACKGROUND_PROGS