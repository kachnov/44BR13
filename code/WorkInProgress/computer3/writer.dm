//CONTENTS
//Writing/printing program


#define MODE_EDIT 0
#define MODE_CONFIG 1
#define MODE_SELECT_PRINTER 2

//Text editor program
/computer/file/terminal_program/writewizard
	name = "WizWrite"
	size = 2
	var/tmp/mode = 0
	var/tmp/connected = 0
	var/tmp/server_netid = null
	var/tmp/potential_server_netid = null
	var/tmp/obj/item/peripheral/network/netCard = null
	var/list/notelist = list()
	var/tmp/working_line = 0
	var/tmp/selected_printer = null
	var/tmp/list/known_printers = list()
	var/tmp/printer_status = "???"

	var/setup_acc_filepath = "/logs/sysusr"//Where do we look for login data?

	initialize()
		print_text("WizWrite V3.0")
		connected = 0
		mode = 0
		server_netid = null
		netCard = find_peripheral("NET_ADAPTER")
		if (known_printers)
			known_printers.len = 0
		else
			known_printers = list()

		//print_text("Commands: !view to view note, !new to start new note, !del to remove current line<br>!load to load file, !save to save file.<br>!\[line number] to set current line, !print to print. !quit to quit.<br>Anything else to type a line.")
		print_text(get_help_text())
		return

	input_text(text)
		if (..())
			return

		var/list/command_list = parse_string(text)
		var/command = command_list[1]
		command_list -= command_list[1]

		if (mode != MODE_EDIT)
			switch(mode)
				if (MODE_CONFIG)
					switch(lowertext(copytext(command,1,2)))
						if ("0")
							mode = MODE_EDIT
							print_text("Now editing.  !help to list commands.")
						if ("1")
							if (connected)
								disconnect_server()
								connected = 0
								master.temp = null
								print_text(get_config_menu())
								return
							else
								if (server_netid)
									//Attempt to connect to server
									mode = -1
									connect_printserver(server_netid, 1)
									if (connected)
										master.temp = null
										print_text("Connection established to \[[server_netid]]!<br>[get_config_menu()]")
										mode = MODE_CONFIG
										return

									print_text("Connection failed.")
									return
								else
									//Attempt to autodetect server & connect
									mode = -1
									src.print_text("Searching for printserver...")
									if (ping_server(1))
										print_text("Unable to detect printserver!")
										mode = MODE_CONFIG
										return

									src.print_text("Printserver detected at \[[potential_server_netid]]<br>Connecting...")
									connect_printserver(potential_server_netid, 1)

									mode = MODE_CONFIG
									if (connected)
										master.temp = null
										print_text("Connection established to \[[server_netid]]!<br>[get_config_menu()]")
										return

									print_text("Connection failed.")
									return
						if ("2")
							mode = -1
							message_server("command=print&args=index")
							sleep(8)
							var/dat = "Known Printers:"
							if (!known_printers || !known_printers.len)
								dat += "<br> \[__] No printers known."

							else
								var/leadingZeroCount = length("[known_printers.len]")
								for (var/kp_index=1, kp_index <= known_printers.len, kp_index++)
									dat += "<br> \[[add_zero("[kp_index]",leadingZeroCount)]] [known_printers[kp_index]]"
								dat += "<br> \[A] Print to All."

							master.temp = null
							print_text("[dat]<br> (0) Return")
							mode = MODE_SELECT_PRINTER
							return

				if (MODE_SELECT_PRINTER)
					if (lowertext(command) == "a")
						selected_printer = "!all!"
					else
						var/printerNumber = round(text2num(command))
						if (printerNumber == 0)
							mode = MODE_CONFIG
							master.temp = null
							print_text(get_config_menu())
							return

						if (printerNumber < 1 || printerNumber > known_printers.len)
							return

						selected_printer = known_printers[printerNumber]

					mode = MODE_CONFIG
					master.temp = null
					print_text("Printer set.<br>[get_config_menu()]")
					return

			return

		if (dd_hasprefix(command, "!"))
			switch(lowertext(command))
				if ("!view","!v")
					if (notelist.len)
						var/to_print = null
						for (var/t=1, t <= notelist.len, t++)
							to_print += "\[[add_zero("[t]",3)]] [notelist[t]] [notelist[ notelist[t] ] ? "=[notelist[ notelist[t] ]]": null]<br>"
						print_text(to_print)
					else
						print_text("No document loaded.")
				if ("!new","!n")
					notelist = new
					print_text("Current note cleared")

				if ("!del","!d")
					if (working_line && working_line < notelist.len)
						notelist.Cut(working_line,working_line+1)
						print_text("Line [working_line] removed.")
					else
						print_text("Line [notelist.len] removed.")
						notelist.len--
					working_line = 0

				if ("!load","!l")
					var/file_name = ckey(jointext(command_list, " "))

					if (!file_name)
						print_text("Syntax: \"!load \[file name]\"")
						return

					var/computer/file/record/to_load = get_file_name(file_name, holding_folder)
					if (!to_load || (!istype(to_load) && !istype(to_load, /computer/file/text)))
						print_text("Error: File not found (Or invalid).")
						return

					if (istype(to_load, /computer/file/text))
						var/computer/file/text/loadText = to_load
						notelist = splittext(loadText.data, "<br>")
					else
						notelist = to_load.fields.Copy()

					print_text("Load successful.")

				if ("!save", "!s")
					var/new_name = strip_html(jointext(command_list, " "))
					new_name = copytext(new_name, 1, 16)

					if (!new_name)
						print_text("Syntax: \"!save \[file name]\"")
						return

					var/computer/file/record/saved = get_file_name(new_name, holding_folder)
					if (saved && !istype(saved) || get_folder_name(new_name, holding_folder))
						print_text("Error: Name in use.")
						return

					if (is_name_invalid(new_name))
						print_text("Error: Invalid character in name.")
						return

					if (saved && istype(saved))
						saved.fields = notelist.Copy()
					else
						saved = new /computer/file/record
						saved.name = new_name
						saved.fields = notelist.Copy()
						if (!holding_folder.add_file(saved))
							//qdel(saved)
							saved.dispose()
							print_text("Error: Cannot save to disk.")
							return

					print_text("File saved.")

				if ("!help", "!h")
					print_text(get_help_text())

				if ("!print", "!p")
					var/print_name = strip_html(jointext(command_list, " "))
					print_name = copytext(print_name, 1, 16)

					var/networked = (connected && selected_printer)

					if (!print_name && !networked)
						print_text("<strong>Syntax:</strong> \"!print \[title].\" Prints current loaded document")
						return

					if (!notelist.len)
						print_text("<strong>Error:</strong> No document loaded.")

					else
						if (networked && !network_print(print_name))
							print_text("Print instruction sent.")
						else
							if (local_print(print_name))
								print_text("<strong>Error:</strong> No printer detected.")
							else
								print_text("Print instruction sent.")

				if ("!config","!c","!conf")
					mode = MODE_CONFIG
					master.temp = null
					print_text("[get_config_menu()]")

					return

				if ("!quit","!q")
					src.print_text("Quitting...")
					if (connected)
						connected = 0
						disconnect_server()
					master.unload_program(src)
					return

				else
					var/line_num = round( text2num( copytext(command, 2) ) )
					if (isnull(line_num))
						print_text("Unknown command.")
						return
					if (line_num <= 0)
						working_line = 0
						print_text("Now working from end of document.")
						return

					if (line_num > notelist.len)
						print_text("Line outside of document scope.")
						return

					working_line = line_num
					print_text("\[[add_zero("[working_line]",3)]] [notelist[working_line]]")
					return

		else
			var/adding = strip_html(text)
			var/adding_associative = null
			print_text("\[[add_zero("[working_line == 0 ? notelist.len+1 : working_line]",3)]] [adding]")
			//oldnote = note
			var/split_point = findtext(adding, "=")
			if (split_point)
				adding_associative = copytext(adding, split_point+1)
				adding = copytext(adding, 1, split_point)

			adding = copytext(adding, 1, 256)
			if (working_line && working_line <= notelist.len)
				notelist[working_line] = "[adding]"
				if (adding_associative)
					notelist["[adding]"] = adding_associative
				working_line++
				if (working_line > notelist.len)
					working_line = 0
			else
				notelist += "[adding]"
				if (adding_associative)
					notelist["[adding]"] = adding_associative

		master.add_fingerprint(usr)
		master.updateUsrDialog()
		return

	receive_command(obj/source, command, signal/signal)
		if ((..()) || (!signal))
			return

		if (!connected)
			if (signal.data["command"] == "ping_reply" && !potential_server_netid)

				if (signal.data["device"] == "PNET_MAINFRAME" && signal.data["sender"] && ishex(signal.data["sender"]))
					potential_server_netid = signal.data["sender"]
					return

			else if (signal.data["command"] == "term_connect")
				server_netid = ckey(signal.data["sender"])
				connected = 1
				potential_server_netid = null
				if (signal.data["data"] != "noreply")
					var/signal/termsignal = get_free_signal()

					termsignal.data["address_1"] = signal.data["sender"]
					termsignal.data["command"] = "term_connect"
					termsignal.data["device"] = "SRV_TERMINAL"
					termsignal.data["data"] = "noreply"

					peripheral_command("transmit", termsignal, "\ref[netCard]")

			return
		else
			if (signal.data["sender"] != server_netid)
				return

			if (!server_netid)
				connected = 0
				return

			switch(lowertext(signal.data["command"]))
				if ("term_message","term_file")
					var/list/data = params2list(signal.data["data"])
					if (!data || !data["command"])
						return

					var/list/commandList = splittext(data["command"], "|n")
					if (!commandList || !commandList.len)
						return

					switch (commandList[1])
						if ("print_index")
							if (commandList.len > 1)
								known_printers = commandList.Copy(2)
							else
								known_printers = list()

						if ("print_status")
							if (commandList.len > 1)
								printer_status = commandList[2]
							else
								printer_status = "???"
					return

				if ("term_disconnect")
					connected = 0
					server_netid = null
					print_text("Connection closed by printserver.")

				if ("term_ping")
					if (signal.data["data"] == "reply")
						var/signal/termsignal = get_free_signal()

						termsignal.data["address_1"] = signal.data["sender"]
						termsignal.data["command"] = "term_ping"

						peripheral_command("transmit", termsignal, "\ref[netCard]")


		return

	proc
		connect_printserver(var/address, delayCaller=0)
			if (connected || !netCard)
				return TRUE

			var/signal/signal = get_free_signal()

			signal.data["address_1"] = address
			signal.data["command"] = "term_connect"
			signal.data["device"] = "SRV_TERMINAL"
			var/computer/file/user_data/user_data = get_user_data()
			var/computer/file/record/udat = null
			if (istype(user_data))
				udat = new

				var/userid = format_username(user_data.registered)

				udat.fields["userid"] = userid
				udat.fields["access"] = list2params(user_data.access)
				if (!udat.fields["access"] || !udat.fields["userid"])
//					qdel(udat)
					udat.dispose()
					return TRUE

				udat.fields["service"] = "print"

			if (udat)
				signal.data_file = udat

			peripheral_command("transmit", signal, "\ref[netCard]")
			if (delayCaller)
				sleep(8)
				return FALSE

			return FALSE

		disconnect_server()
			if (!server_netid || !netCard)
				return TRUE

			var/signal/signal = get_free_signal()

			signal.data["address_1"] = server_netid
			signal.data["command"] = "term_disconnect"

			peripheral_command("transmit", signal, "\ref[netCard]")

			return FALSE

		ping_server(delayCaller=0)
			if (connected || !netCard)
				return TRUE

			potential_server_netid = null
			peripheral_command("ping", null, "\ref[netCard]")

			if (delayCaller)
				sleep(8)
				return (potential_server_netid == null)

			return FALSE

		message_server(var/message, var/computer/file/toSend)
			if (!connected || !server_netid || !netCard || !message)
				return TRUE

			var/signal/termsignal = get_free_signal()

			termsignal.data["address_1"] = server_netid
			termsignal.data["data"] = message
			termsignal.data["command"] = "term_message"
			if (toSend)
				termsignal.data_file = toSend

			peripheral_command("transmit", termsignal, "\ref[netCard]")
			return FALSE

		network_print(var/print_title = "Printout")
			if (!connected || !netCard || !selected_printer || !server_netid || !notelist || !notelist.len)
				return TRUE

			var/computer/file/record/printRecord = new
			printRecord.fields = notelist.Copy()
			if (print_title)
				printRecord.fields.Insert(1, "title=[print_title]")
			printRecord.name = "printout"

			if (selected_printer == "!all!")
				message_server("command=print&args=printall", printRecord)
			else
				message_server("command=print&args=print [selected_printer]", printRecord)
			return FALSE

		local_print(var/print_title = "Printout")
			var/obj/item/peripheral/printcard = find_peripheral("LAR_PRINTER")
			if (!printcard || !notelist || !notelist.len)
				return TRUE

			var/signal/signal = get_free_signal()
			signal.data["data"] = jointext(notelist, "<br>")
			signal.data["title"] = print_title
			peripheral_command("print",signal, "\ref[printcard]")
			return FALSE

		get_user_data()
			var/computer/folder/accdir = holder.root
			if (master.host_program) //Check where the OS is, preferably.
				accdir = master.host_program.holder.root

			var/computer/file/user_data/target = parse_file_directory(setup_acc_filepath, accdir)
			if (target && istype(target))
				return target

			return null

		get_config_menu()
			if (connected && server_netid)
				var/confText = "Currently connected to printserver \[[server_netid]]"
				confText += "<br> (1) Disconnect"
				confText += "<br> (2) Select Printer"
				confText += "<br> (0) Back"
				return confText

			return "No printserver connection<br> (1) Connect<br> (0) Back"

		get_help_text()

			var/help_text = {"Commands:
	<br> \"!view\" to view note
	<br> \"!del\" to remove current line
	<br> \"!\[integer]" to set current line
	<br> \"!save \[name]\" to save note
	<br> \"!load \[name]\" to load note
	<br> \"!print\" to print current note.
	<br> \"!config\" to configure network printing.
	<br> Anything else to type."}
			return help_text

#undef MODE_EDIT
#undef MODE_CONFIG
#undef MODE_SELECT_PRINTER