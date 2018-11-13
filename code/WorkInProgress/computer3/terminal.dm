

/computer/file/terminal_program/os/terminal_os
	name = "TermOS B"
	size = 6
	var/computer/folder/current_folder = null
	var/net_number = null
	var/tmp/serv_id = null //NetID of connected server
	var/tmp/attempt_id = null //Are we attempting to connect to something?
	var/tmp/last_serv_id = null //Last valid serv_id.
	var/obj/item/peripheral/network/netcard = null
	var/tmp/disconnect_wait = -1 //Are we waiting to disconnect?
	var/tmp/ping_wait = 0 //Are we waiting for a ping reply?
	var/tmp/computer/file/temp_file = null //Temp folder from our server
	var/auto_accept = 1 //Do we automatically accept connection attempts?
	//var/tmp/service_mode = 0

	input_text(text)
		if (..())
			return

		var/list/command_list = parse_string(text)
		var/command = lowertext(command_list[1])
		command_list -= command_list[1] //Remove the command that we are now processing.

		print_text(">[strip_html(text)]")

		if (!current_folder)
			current_folder = holding_folder

		if (disconnect_wait > 0)
			print_text("Alert: System busy, please hold.")
			return

		if (command == "help" && !serv_id)
			var/help_message = {"<strong>Terminal Commands:</strong><br>
term_status - View current status of terminal.<br>
term_accept - Toggle connection auto-accept.<br>
term_login - Transmit login file (ID Required)<br>
term_ping - Scan network for terminal devices.<br>
term_break - Send break signal to host.<br>
<strong>Connection Commands:</strong><br>
connect \[Net ID] - Connect to a specified device.<br>
reconnect - Connect to last valid address<br>
disconnect - Disconnect from current device.<br>
<strong>File Commands</strong><br>
file_status - View status of loaded file.<br>
file_send - Transmit loaded file.<br>
file_print - Print contents of file.<br>
file_load - Load file from local disk.
file_save - Save file to local disk."}
			print_text(help_message)
			return

		switch(command)
			if ("term_status")
				if (netcard)
					var/statdat = netcard.return_status_text()
					print_text("<strong>[netcard.func_tag]</strong><br>Status: [statdat]")
				else
					print_text("No network card detected.")

				print_text("Current Server Address: [serv_id ? serv_id : "NONE"]<br>Auto-accept connections is <strong>[auto_accept ? "ON" : "OFF"]</strong><br>Toggle this with \"term_accept\"")//[service_mode ? "<br>Service mode active." : ""]")

			if ("term_accept")
				auto_accept = !auto_accept
				print_text("Auto-Accept is now <strong>[auto_accept ? "ON" : "OFF"]</strong>")

			if ("term_break")
				if (!serv_id || !netcard)
					return

				var/signal/termsignal = get_free_signal()
				//termsignal.encryption = "\ref[netcard]"
				termsignal.data["address_1"] = serv_id
				termsignal.data["command"] = "term_break"

				peripheral_command("transmit", termsignal, "\ref[netcard]")

			if ("term_ping")
				if (serv_id)
					print_text("Alert: Cannot ping while connected.")
					return

				if (!netcard)
					print_text("Alert: No network card detected.")
					return

				if (command_list.len)
					if (ckey(command_list[1]) == "all")
						net_number = null
					else
						var/new_net_number = round( text2num(command_list[1]) )
						if (new_net_number != null && new_net_number >= 0 && new_net_number <= 16)
							net_number = new_net_number

					peripheral_command("subnet[net_number]", null, "\ref[netcard]")

				ping_wait = 4

				src.print_text("Pinging [src.net_number == null ? "All Subnetworks" : "Subnetwork [src.net_number]"]...")
				peripheral_command("ping[net_number]", null, "\ref[netcard]")

			if ("term_login")
				var/obj/item/peripheral/scanner = find_peripheral("ID_SCANNER")
				if (!scanner)
					print_text("Error: No ID scanner detected.")
					return
				if (!netcard)
					print_text("Alert: No network card detected.")
					return
				if (!serv_id)
					print_text("Alert: Connection required.")
					return
				ping_wait = 2
				if (issilicon(usr))
					var/signal/newsig = new
					newsig.data["registered"] = istype(usr, /mob/living/silicon/ai) ? "AI" : "CYBORG"
					newsig.data["assignment"] = "AI"
					newsig.data["access"] = "0"

					spawn (4)
						switch( receive_command(master, "card_authed", newsig) )
							if ("nocard")
								print_text("Please insert a card first.")

							if ("noreg")
								print_text("Notice: No name on card.")

							if ("noassign")
								print_text("Notice: No assignment on card.")

					return
				else
					peripheral_command("scan_card",null,"\ref[scanner]")
/*
			if ("term_service")
				if (serv_id)
					print_text("Alert: Cannot switch mode while connected.")
					return

				service_mode = !service_mode
				print_text("Service mode [service_mode ? "" : "de"]activated.")
*/
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

				var/signal/termsignal = get_free_signal()
				//termsignal.encryption = "\ref[netcard]"
				termsignal.data["address_1"] = argument1
				termsignal.data["command"] = "term_connect"
				termsignal.data["device"] = "HUI_TERMINAL"
				//termsignal.data["device"] = "[service_mode ? "SRV" : "HUI"]_TERMINAL"
				disconnect_wait = 4

				src.print_text("Attempting to connect...")
				peripheral_command("transmit", termsignal, "\ref[netcard]")

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
				termsignal.data["device"] = "HUI_TERMINAL"
				//termsignal.data["device"] = "[service_mode ? "SRV" : "HUI"]_TERMINAL"
				disconnect_wait = 4

				src.print_text("Attempting to reconnect to \[[src.attempt_id]]...")
				peripheral_command("transmit", termsignal, "\ref[netcard]")


			if ("disconnect")
				if (serv_id)
					var/signal/termsignal = get_free_signal()
					//termsignal.encryption = "\ref[netcard]"
					termsignal.data["address_1"] = serv_id
					termsignal.data["command"] = "term_disconnect"
					serv_id = null

					peripheral_command("transmit", termsignal, "\ref[netcard]")
					print_text("<strong>Connection Closed.</strong>")
					disconnect_wait = -1

			//Tempfile usage commands.
			if ("file_status")
				if (!temp_file || !istype(temp_file))
					print_text("Alert: No file loaded.")
					return

				var/file_info = "[temp_file.name] - [temp_file.extension] - \[Size: [temp_file.size]]<br>Enter command \"file_save\" to save to external disk."
				if (istype(temp_file, /computer/file/text))
					file_info += "<br>Enter command \"file_print\" to print."
				else if (istype(temp_file, /computer/file/terminal_program/termapp))
					file_info += "<br>Enter command \"file_run\" to execute."
				else
					file_info += "<br>Unknown filetype."

				print_text(file_info)

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

/*
			if ("file_read")
				if (!temp_file || !istype(temp_file, /computer/file/text))
					print_text("Alert: File invalid or missing.")
					return

				master.temp = "<strong>File Contents:</strong><br>"
				print_text(temp_file:data)
*/
			if ("file_load")
				var/toLoadName = "temp"
				if (command_list.len)
					toLoadName = jointext(command_list, "")

				var/computer/file/loadedFile = null
				for (var/obj/item/disk/data/drive in master.contents)
					if (drive == holder)
						continue

					loadedFile = get_file_name(toLoadName, drive.root)
					if (istype(loadedFile))
						print_text("File loaded.")
						temp_file = loadedFile
						return

					continue

				if (master.hd && master.hd.root)
					loadedFile = get_file_name(toLoadName, master.hd.root)

				if (istype(loadedFile))
					print_text("File loaded.")
					temp_file = loadedFile
					return

				print_text("Alert: File not found (or invalid).")
				return

			if ("file_save")
				if (!temp_file)
					print_text("Alert: No file to save.")
					return

				var/toSaveName = "temp"
				if (command_list.len)
					toSaveName = jointext(command_list, "")

				for (var/obj/item/disk/data/drive in master.contents)
					if (drive == holder || !drive.root)
						continue

					if (temp_file.holder == drive)
						print_text("Alert: File already saved to this drive.")
						return

					var/computer/file/oldFile = get_file_name(toSaveName, drive.root)
					if (oldFile)
						if (istype(oldFile, temp_file.type))
							oldFile.dispose()

						else
							print_text("Alert: File name taken, unable to overwrite.")
							return

					temp_file.name = toSaveName
					if (drive.root.add_file(temp_file.copy_file()))
						print_text("File saved.")
						return

					print_text("Alert: Unable to write to disk.")
					return

				print_text("Alert: No valid destination drive found.")
				return

			if ("file_print")
				if (!temp_file || (!istype(temp_file, /computer/file/text) && !istype(temp_file, /computer/file/record)))
					print_text("Alert: File invalid or missing.")
					return

				var/to_print = null
				if (istype(temp_file, /computer/file/record))
					for (var/a in temp_file:fields)
						if (temp_file:fields[a])
							to_print += "[a]=[temp_file:fields[a]]<br>"
						else
							to_print += "[a]<br>"
				else
					to_print = temp_file:data
				src.print_text("Sending print command...")
				var/signal/printsig = new
				//printsig.encryption = "\ref[netcard]"
				printsig.data["data"] = to_print
				printsig.data["title"] = "Printout"

				peripheral_command("print",printsig, "\ref[netcard]")

			if ("file_run") //to-do
				print_text("Command currently inoperative.")

			else
				send_term_message(text)

		return

	initialize()
		//service_mode = 0
		print_text("Loading TermOS, Revision C<br>Copyright 2046-2053 Thinktronic Systems, LTD.")

		if (serv_id) //I guess some jerk rebooted us
			var/signal/termsignal = get_free_signal()
			//termsignal.encryption = "\ref[netcard]"
			termsignal.data["address_1"] = serv_id
			termsignal.data["command"] = "term_disconnect"

			peripheral_command("transmit", termsignal, "\ref[netcard]")

		ping_wait = 0
		disconnect_wait = 0
		attempt_id = null
		serv_id = null
		netcard = find_peripheral("NET_ADAPTER")
		if (!netcard || !istype(netcard))
			netcard = find_peripheral("RAD_ADAPTER")
			if (istype(netcard))
				peripheral_command("mode_net", null, "\ref[netcard]")
				print_text("Network card detected.<br>Ready.")
			else
				netcard = null
				print_text("<font color=red>Error: No network card detected.</font><br>Ready.")
		else
			print_text("Network card detected.<br>Ready.")

		current_folder = holder.root
		if (setup_string && netcard) //Use setup string as tag for startup server.
			var/target_tag = setup_string
			var/maybe_netnum = findtext(target_tag, "|")
			if (maybe_netnum)
				net_number = text2num( copytext(target_tag, maybe_netnum+1) )
				target_tag = copytext(target_tag, 1, maybe_netnum)
				peripheral_command("subnet[net_number]", null, "\ref[netcard]")

			setup_string = null

			var/obj/target_serv = locate(target_tag)
			if (istype(target_serv) && hasvar(target_serv,"net_id"))
				spawn (100)
					if (target_serv)
						input_text("connect [target_serv:net_id]")

		return

	disk_ejected(var/obj/item/disk/data/thedisk)
		if (!thedisk)
			return

		if (current_folder && (current_folder.holder == thedisk))
			current_folder = holding_folder

		if (holder == thedisk)
			print_text("<font color=red>System Error: Unable to read system file.</font>")
			master.active_program = null
			master.host_program = null
			return

		if (temp_file && (temp_file.holder == thedisk))
			temp_file = null

		return

	proc/send_term_message(var/message, send_file=0)
		if (!message || !serv_id || !netcard)
			return

		message = strip_html(message)

		var/signal/termsignal = get_free_signal()
		//termsignal.encryption = "\ref[netcard]"
		termsignal.data["address_1"] = serv_id
		termsignal.data["data"] = message
		termsignal.data["command"] = "term_[send_file ? "file" : "message"]"
		if (send_file && temp_file)
			termsignal.data_file = temp_file.copy_file()

		peripheral_command("transmit", termsignal, "\ref[netcard]")
		return

	restart()
		attempt_id = null
		if (serv_id) //I guess some jerk rebooted us
			var/signal/termsignal = get_free_signal()
			//termsignal.encryption = "\ref[netcard]"
			termsignal.data["address_1"] = serv_id
			termsignal.data["command"] = "term_disconnect"

			peripheral_command("transmit", termsignal, "\ref[netcard]")
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

	receive_command(obj/source, command, signal/signal)
		if ((..()) || (!signal))
			return

		if (command == "card_authed" && ping_wait && serv_id)

			var/computer/file/record/udat = new
			udat.fields["registered"] = signal.data["registered"]
			udat.fields["assignment"] = signal.data["assignment"]
			udat.fields["access"] = signal.data["access"]
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

			peripheral_command("transmit", termsignal, "\ref[netcard]")
			return


		if (!serv_id || signal.data["sender"] != serv_id)
			if (signal.data["command"] == "ping_reply" && ping_wait)
				if (!signal.data["device"] || !signal.data["netid"])
					return

				var/reply_device = signal.data["device"]
				var/reply_id = signal.data["netid"]

				print_text("<strong>P:</strong> \[[reply_id]]-TYPE: [reply_device]")

			//oh, somebody trying to connect!
			else if (signal.data["command"] == "term_connect" && !serv_id)
				if (!attempt_id && signal.data["sender"] && auto_accept)
					serv_id = signal.data["sender"]
					disconnect_wait = -1
					print_text("Connection established to [serv_id]!")
					//well okay but now they need to know we've accepted!
					if (signal.data["data"] != "noreply")
						var/signal/termsignal = get_free_signal()
						//termsignal.encryption = "\ref[netcard]"
						termsignal.data["address_1"] = signal.data["sender"]
						termsignal.data["command"] = "term_connect"
						termsignal.data["data"] = "noreply"

						peripheral_command("transmit", termsignal, "\ref[netcard]")


				else if (signal.data["sender"] == attempt_id)
					attempt_id = null
					serv_id = signal.data["sender"]
					last_serv_id = serv_id
					disconnect_wait = -1
					print_text("Connection to [serv_id] successful.")

		if (signal.data["sender"] == serv_id)
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

					//Will it fit? Check before clearing out our old temp file!
					if ((holder.file_used + signal.data_file.size) > holder.file_amount)
						print_text("Alert: Unable to accept file transfer, disk is full!")
						return

					if (temp_file)
						//qdel(temp_file) //Clear our old temp file!
						temp_file.dispose()

					temp_file = signal.data_file.copy_file()
					temp_file.name = "temp"
					print_text("Alert: File received from remote host!<br>Valid commands: file_status, file_print")

				if ("term_ping")
					if (signal.data["data"] == "reply")
						var/signal/termsignal = get_free_signal()
						//termsignal.encryption = "\ref[netcard]"
						termsignal.data["address_1"] = signal.data["sender"]
						termsignal.data["command"] = "term_ping"

						peripheral_command("transmit", termsignal, "\ref[netcard]")
					return

				if ("term_disconnect")
					serv_id = null
					attempt_id = null

					print_text("<strong>Connection closed by remote host.</strong>")
					return

		return