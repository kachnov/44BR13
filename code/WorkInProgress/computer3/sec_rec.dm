


#define MENU_MAIN 0 //Byond. Enums.  Lacks them. Etc
#define MENU_INDEX 1
#define MENU_IN_RECORD 2
#define MENU_FIELD_INPUT 3
#define MENU_SEARCH_INPUT 4
#define MENU_SETTINGS 5
#define MENU_SELECT_PRINTER 6

#define FIELDNUM_NAME 1
#define FIELDNUM_SEX 2
#define FIELDNUM_AGE 3
#define FIELDNUM_RANK 4
#define FIELDNUM_PRINT 5
#define FIELDNUM_CRIMSTAT 6
#define FIELDNUM_MINCRIM 7
#define FIELDNUM_MINDET 8
#define FIELDNUM_MAJCRIM 9
#define FIELDNUM_MAJDET 10

#define FIELDNUM_DELETE "d"
#define FIELDNUM_NEWREC 99

/computer/file/terminal_program/secure_records
	name = "SecMate"
	size = 12
	req_access = list(access_security)
	var/tmp/menu = MENU_MAIN
	var/tmp/field_input = 0
	var/tmp/authenticated = null //Are we currently logged in?
	var/tmp/computer/file/user_data/account = null
	var/list/record_list = list()  //List of records, for jumping direclty to a specific ID
	var/data/record/active_general = null //General record
	var/data/record/active_secure = null //Security record
	var/log_string = null //Log usage of record system, can be dumped to a text file.
	var/obj/item/peripheral/network/radio/radiocard = null
	var/tmp/last_arrest_report = 0 //When did we last report an arrest?

	var/tmp/connected = 0
	var/tmp/server_netid = null
	var/tmp/potential_server_netid = null
	var/tmp/selected_printer = null
	var/tmp/list/known_printers = list()
	var/tmp/printer_status = "???"

	var/setup_acc_filepath = "/logs/sysusr"//Where do we look for login data?
	var/setup_logdump_name = "seclog" //What name do we give our logdump textfile?
	var/setup_mailgroup = "security" //The PDA mailgroup used when alerting security pdas to an arrest set.
	var/setup_mail_freq = 1149 //Which frequency do we transmit PDA alerts on?

	initialize() //Forms "SECMATE" ascii art. Oh boy.
	/*
		var/title_art = {"<pre> ____________________    _ __________________
\\  ___\\  ___\\  ___\\ -./  \\  __ \\ _  _\\  ___\\
\\ \\___  \\  __\\\\ \\___\\ \\-./\\ \\  __ \\/\\ \\ \\  __\\
 \\/\\_____\\_____\\_____\\ \\_\\ \\ \\ \\_\\ \\ \\ \\ \\_____\\
  \\/_____/_____/_____/_/  \\/_/_/\\/_/\\/_/\\/_____/ </pre>"}
*/
		authenticated = null
		record_list = data_core.general.Copy() //Initial setting of record list.
		master.temp = null
		menu = MENU_MAIN
		field_input = 0
		//print_text(" [title_art]")
		if (!find_access_file()) //Find the account information, as it's essentially a ~digital ID card~
			src.print_text("<strong>Error:</strong> Cannot locate user file.  Quitting...")
			master.unload_program(src) //Oh no, couldn't find the file.
			return

		radiocard = locate() in master.peripherals
		if (!radiocard || !istype(radiocard))
			radiocard = null
			print_text("<strong>Warning:</strong> No radio module detected.")

		if (!check_access(account.access))
			src.print_text("User [src.account.registered] does not have needed access credentials.<br>Quitting...")
			master.unload_program(src)
			return

		authenticated = account.registered
		log_string += "<br><strong>LOGIN:</strong> [authenticated]"

		print_text(mainmenu_text())
		return


	input_text(text)
		if (..())
			return

		var/list/command_list = parse_string(text)
		var/command = command_list[1]
		command_list -= command_list[1]

		switch(menu)
			if (MENU_MAIN)
				switch (command)
					if ("0") //Exit program
						src.print_text("Quitting...")
						master.unload_program(src)
						return

					if ("1") //View records
						record_list = data_core.general

						menu = MENU_INDEX
						print_index()

					if ("2") //Search records
						print_text("Please enter target name, ID, DNA, or fingerprint.")

						menu = MENU_SEARCH_INPUT
						return

					if ("3")
						print_settings()

						menu = MENU_SETTINGS
						return

			if (MENU_SETTINGS)
				switch (command)
					if ("0")
						menu = MENU_MAIN
						master.temp = null
						print_text(mainmenu_text())
						return

					if ("1")
						if (connected)
							disconnect_server()
							connected = 0
							master.temp = null
							print_settings()
							return
						else
							if (server_netid)
								//Attempt to connect to server
								menu = -1
								connect_printserver(server_netid, 1)
								if (connected)
									master.temp = null
									print_text("Connection established to \[[server_netid]]!")
									print_settings()
									menu = MENU_SETTINGS
									return

								menu = MENU_SETTINGS
								print_text("Connection failed.")
								return
							else
								//Attempt to autodetect server & connect
								menu = -1
								src.print_text("Searching for printserver...")
								if (ping_server(1))
									print_text("Unable to detect printserver!")
									menu = MENU_SETTINGS
									return

								src.print_text("Printserver detected at \[[potential_server_netid]]<br>Connecting...")
								connect_printserver(potential_server_netid, 1)

								menu = MENU_SETTINGS
								if (connected)
									master.temp = null
									print_text("Connection established to \[[server_netid]]!")
									print_settings()
									return

								print_text("Connection failed.")
								return

					if ("2")
						menu = -1
						message_server("command=print&args=index")
						sleep(8)
						var/dat = "Known Printers:"
						if (!known_printers || !known_printers.len)
							dat += "<br> \[__] No printers known."

						else
							var/leadingZeroCount = length("[known_printers.len]")
							for (var/kp_index=1, kp_index <= known_printers.len, kp_index++)
								dat += "<br> \[[add_zero("[kp_index]",leadingZeroCount)]] [known_printers[kp_index]]"

						master.temp = null
						print_text("[dat]<br> (0) Return")
						menu = MENU_SELECT_PRINTER
						return

			if (MENU_SELECT_PRINTER)
				var/printerNumber = round(text2num(command))
				if (printerNumber == 0)
					menu = MENU_SETTINGS
					master.temp = null
					print_settings()
					return

				if (printerNumber < 1 || printerNumber > known_printers.len)
					return

				selected_printer = known_printers[printerNumber]
				menu = MENU_SETTINGS
				master.temp = null
				print_text("Printer set.")
				print_settings()


			if (MENU_INDEX)
				var/index_number = round( max( text2num(command), 0) )
				if (index_number == 0)
					menu = MENU_MAIN
					master.temp = null
					print_text(mainmenu_text())
					return

				else if (index_number == 99)
					var/data/record/G = new /data/record(  )
					G.fields["name"] = "New Record"
					G.fields["id"] = "[add_zero(num2hex(rand(1, 1.6777215E7)), 6)]"
					G.fields["rank"] = "Unassigned"
					G.fields["sex"] = "Other"
					G.fields["age"] = "Unknown"
					G.fields["fingerprint"] = "Unknown"
					G.fields["p_stat"] = "Active"
					G.fields["m_stat"] = "Stable"
					active_general = G
					active_secure = null
					log_string += "<br>Log created: [G.fields["id"]]"

					if (print_active_record())
						menu = MENU_IN_RECORD

					return

				if (!istype(record_list) || index_number > record_list.len)
					print_text("Invalid record.")
					return

				var/data/record/check = record_list[index_number]
				if (!check || !istype(check))
					print_text("<strong>Error:</strong> Record Data Invalid.")
					return

				active_general = check
				active_secure = null
				if (data_core.general.Find(check))
					for (var/data/record/E in data_core.security)
						if ((E.fields["name"] == active_general.fields["name"] || E.fields["id"] == active_general.fields["id"]))
							active_secure = E
							break

				log_string += "<br>Log loaded: [active_general.fields["id"]]"

				if (print_active_record())
					menu = MENU_IN_RECORD
				return

			if (MENU_IN_RECORD)
				switch(lowertext(command))
					if ("r")
						print_active_record()
						return
					if ("d")
						print_text("Are you sure? (Y/N)")
						field_input = FIELDNUM_DELETE
						menu = MENU_FIELD_INPUT
						return
					if ("p")

						if ((connected && selected_printer) && !network_print())
							print_text("Print instruction sent.")
						else
							if (local_print())
								print_text("<strong>Error:</strong> No printer detected.")
							else
								print_text("Print instruction sent.")

						return

				var/field_number = round( max( text2num(command), 0) )
				if (field_number == 0)
					menu = MENU_INDEX
					print_index()
					return

				field_input = field_number
				switch(field_number)
					if (FIELDNUM_NAME, FIELDNUM_AGE, FIELDNUM_RANK, FIELDNUM_PRINT, FIELDNUM_MINCRIM, FIELDNUM_MINDET, FIELDNUM_MAJCRIM, FIELDNUM_MAJDET)
						print_text("Please enter new value.")
						menu = MENU_FIELD_INPUT
						return

					if (FIELDNUM_SEX)
						print_text("Please select: (1) Female (2) Male (3) Other (0) Back")
						menu = MENU_FIELD_INPUT
						return

					if (FIELDNUM_CRIMSTAT)
						print_text("Please select: (1) Arrest (2) None (3) Incarcerated<br>(4) Parolled (5) Released (0) Back")
						menu = MENU_FIELD_INPUT
						return

					if (FIELDNUM_NEWREC)
						if (active_secure)
							return

						var/data/record/R = new /data/record(  )
						R.fields["name"] = active_general.fields["name"]
						R.fields["id"] = active_general.fields["id"]
						R.name = "Security Record #[R.fields["id"]]"
						R.fields["criminal"] = "None"
						R.fields["mi_crim"] = "None"
						R.fields["mi_crim_d"] = "No minor crime convictions."
						R.fields["ma_crim"] = "None"
						R.fields["ma_crim_d"] = "No major crime convictions."
						R.fields["notes"] = "No notes."
						data_core.security += R
						active_secure = R

						print_active_record()
						menu = MENU_IN_RECORD
						return

			if (MENU_FIELD_INPUT)
				if (!active_general)
					print_text("<strong>Error:</strong> Record invalid.")
					menu = MENU_INDEX
					return

				var/inputText = strip_html(text)
				switch (field_input)
					if (FIELDNUM_NAME)
						if (ckey(inputText))
							active_general.fields["name"] = copytext(inputText, 1, 26)
						else
							return

					if (FIELDNUM_SEX)
						switch (round( max( text2num(command), 0) ))
							if (1)
								active_general.fields["sex"] = "Female"
							if (2)
								active_general.fields["sex"] = "Male"
							if (3)
								active_general.fields["sex"] = "Other"
							if (0)
								menu = MENU_IN_RECORD
								return
							else
								return

					if (FIELDNUM_AGE)
						var/newAge = round( min( text2num(command), 99) )
						if (newAge < 1)
							print_text("Invalid age value. Please re-enter.")
							return

						active_general.fields["age"] = newAge

					if (FIELDNUM_RANK)
						if (ckey(inputText))
							active_general.fields["rank"] = copytext(inputText, 1, 33)
						else
							return

					if (FIELDNUM_PRINT)
						if (ckey(inputText))
							active_general.fields["fingerprint"] = copytext(inputText, 1, 33)
						else
							return

					if (FIELDNUM_CRIMSTAT)
						if (!active_secure)
							print_text("No security record loaded!")
							menu = MENU_IN_RECORD
							return

						switch (round( max( text2num(command), 0) ))
							if (1)
								if (active_secure.fields["criminal"] != "*Arrest*")
									report_arrest(active_general.fields["name"])
								active_secure.fields["criminal"] = "*Arrest*"
							if (2)
								active_secure.fields["criminal"] = "None"
							if (3)
								active_secure.fields["criminal"] = "Incarcerated"
							if (4)
								active_secure.fields["criminal"] = "Parolled"
							if (5)
								active_secure.fields["criminal"] = "Released"
							if (0)
								menu = MENU_IN_RECORD
								return
							else
								return

					if (FIELDNUM_MINCRIM)
						if (!active_secure)
							print_text("No security record loaded!")
							menu = MENU_IN_RECORD
							return

						if (ckey(inputText))
							active_secure.fields["mi_crim"] = copytext(inputText, 1, MAX_MESSAGE_LEN)
						else
							return

					if (FIELDNUM_MINDET)
						if (!active_secure)
							print_text("No security record loaded!")
							menu = MENU_IN_RECORD
							return

						if (ckey(inputText))
							active_secure.fields["mi_crim_d"] = copytext(inputText, 1, MAX_MESSAGE_LEN)
						else
							return

					if (FIELDNUM_MAJCRIM)
						if (!active_secure)
							print_text("No security record loaded!")
							menu = MENU_IN_RECORD
							return

						if (ckey(inputText))
							active_secure.fields["ma_crim"] = copytext(inputText, 1, MAX_MESSAGE_LEN)
						else
							return

					if (FIELDNUM_MAJDET)
						if (!active_secure)
							print_text("No security record loaded!")
							menu = MENU_IN_RECORD
							return

						if (ckey(inputText))
							active_secure.fields["ma_crim_d"] = copytext(inputText, 1, MAX_MESSAGE_LEN)
						else
							return

					if (FIELDNUM_DELETE)
						switch (ckey(inputText))
							if ("y")
								if (active_secure)
									log_string += "<br>S-Record [active_secure.fields["id"]] deleted."
									data_core.security -= active_secure
									qdel(active_secure)
									print_active_record()
									menu = MENU_IN_RECORD

								else if (active_general)
									data_core.general -= active_general

									log_string += "<br>Record [active_general.fields["id"]] deleted."
									qdel(active_general)
									menu = MENU_INDEX
									print_index()

							if ("n")
								menu = MENU_IN_RECORD
								print_text("Record preserved.")

						return

				print_text("Field updated.")
				menu = MENU_IN_RECORD
				return

			if (MENU_SEARCH_INPUT)
				var/searchText = ckey(strip_html(text))
				if (!searchText)
					return

				var/data/record/result = null
				for (var/data/record/R in data_core.general)
					if ((ckey(R.fields["name"]) == searchText) || (ckey(R.fields["dna"]) == searchText) || (ckey(R.fields["id"]) == searchText) || (ckey(R.fields["fingerprint"]) == searchText))
						result = R
						break

				if (!result)
					print_text("No results found.")
					menu = MENU_MAIN
					return

				active_general = result
				active_secure = null //Time to find the accompanying security record, if it even exists.
				for (var/data/record/E in data_core.security)
					if ((E.fields["name"] == active_general.fields["name"] || E.fields["id"] == active_general.fields["id"]))
						active_secure = E
						break

				menu = MENU_IN_RECORD
				print_active_record()
				return


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

					peripheral_command("transmit", termsignal, "\ref[find_peripheral("NET_ADAPTER")]")

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

						peripheral_command("transmit", termsignal, "\ref[find_peripheral("NET_ADAPTER")]")


		return

	proc
		mainmenu_text()
			var/dat = {"<center>S E C M A T E 7</center><br>
			Welcome to SecMate 7<br>
			<strong>Commands:</strong>
			<br>(1) View security records.
			<br>(2) Search for a record.
			<br>(3) Adjust settings.
			<br>(0) Quit."}

			return dat

		print_active_record()
			if (!active_general)
				print_text("<strong>Error:</strong> General record data corrupt.")
				return FALSE
			master.temp = null

			var/view_string = {"
			\[01]Name: [active_general.fields["name"]] ID: [active_general.fields["id"]]
			<br>\[02]<strong>Sex:</strong> [active_general.fields["sex"]]
			<br>\[03]<strong>Age:</strong> [active_general.fields["age"]]
			<br>\[04]<strong>Rank:</strong> [active_general.fields["rank"]]
			<br>\[05]<strong>Fingerprint:</strong> [active_general.fields["fingerprint"]]
			<br>\[__]<strong>DNA:</strong> [active_general.fields["dna"]]
			<br>\[__]Physical Status: [active_general.fields["p_stat"]]
			<br>\[__]Mental Status: [active_general.fields["m_stat"]]"}

			if ((istype(active_secure, /data/record) && data_core.security.Find(active_secure)))
				view_string +={"
				<br><center><strong>Security Data</strong></center>
				<br>\[06]<strong>Criminal Status:</strong> [active_secure.fields["criminal"]]
				<br>\[07]<strong>Minor Crimes:</strong> [active_secure.fields["mi_crim"]]
				<br>\[08]<strong>Details:</strong> [active_secure.fields["mi_crim_d"]]
				<br>\[09]<strong><br>Major Crimes:</strong> [active_secure.fields["ma_crim"]]
				<br>\[10]<strong>Details:</strong> [active_secure.fields["ma_crim_d"]]
				<br>Important Notes:
				<br>&emsp;[active_secure.fields["notes"]]<br>"}
			else
				view_string += "<br><br><strong>Security Record Lost!</strong>"
				view_string += "<br>\[99] Create New Security Record.<br>"

			view_string += "<br>Enter field number to edit a field<br>(R) Redraw (D) Delete (P) Print (0) Return to index."

			print_text("<strong>Record Data:</strong><br>[view_string]")
			return TRUE

		print_index()
			master.temp = null
			var/dat = ""
			if (!record_list || !record_list.len)
				print_text("<strong>Error:</strong> No records found in database.")
				dat += "<br><strong>\[99]</strong> Create New Record.<br>"

			else
				dat = "Please select a record:"
				var/leadingZeroCount = length("[record_list.len]")
				for (var/x = 1, x <= record_list.len, x++)
					var/data/record/R = record_list[x]
					if (!R || !istype(R))
						dat += "<br><strong>\[[add_zero("[x]",leadingZeroCount)]]</strong><font color=red>ERR: REDACTED</font>"
						continue

					dat += "<br><strong>\[[add_zero("[x]",leadingZeroCount)]]</strong>[R.fields["id"]]: [R.fields["name"]]"

				dat += "<br><strong>\[[add_zero("99",leadingZeroCount)]]</strong> Create New Record.<br>"
			dat += "<br><br>Enter record number, or 0 to return."

			print_text(dat)
			return TRUE

		print_settings()
			var/dat = "Options:"

			if (connected)
				dat += "<br>(1) Disconnect from print server."
				dat += "<br>(2) Select printer."

			else
				dat += "<br>(1) Connect to print server."

			dat += "<br>(0) Back."

			print_text(dat)
			return TRUE

		report_arrest(var/perp_name)
			if (!perp_name || !radiocard)
				return

			if (usr)
				logTheThing("station", usr, null, "[perp_name] is set to arrest by [usr] (using the ID card of [authenticated]) [log_loc(master)]")

			//Unlikely that this would be a problem but OH WELL
			if (last_arrest_report && world.time < (last_arrest_report + 10))
				return

			//Set card frequency if it isn't already.
			if (radiocard.frequency != setup_mail_freq && !radiocard.setup_freq_locked)
				var/signal/freqsignal = get_free_signal()
				//freqsignal.encryption = "\ref[radiocard]"
				peripheral_command("[setup_mail_freq]", freqsignal, "\ref[radiocard]")
				src.log_string += "<br>Adjusting frequency... \[[src.setup_mail_freq]]."

			var/signal/signal = get_free_signal()
			//signal.encryption = "\ref[radiocard]"

			//Create a PDA mass-message string.
			signal.data["command"] = "text_message"
			signal.data["sender_name"] = "SEC-MAILBOT"
			signal.data["group"] = setup_mailgroup //Only security PDAs should be informed.
			signal.data["message"] = "Alert! Crewman \"[perp_name]\" has been flagged for arrest by [authenticated]!"

			log_string += "<br>Arrest notification sent."
			last_arrest_report = world.time
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

		local_print()
			var/obj/item/peripheral/printcard = find_peripheral("LAR_PRINTER")
			if (!printcard)
				return TRUE

			//Okay, let's put together something to print.
			var/info = "<center><strong>Security Record</strong></center><br>"
			if (istype(active_general, /data/record) && data_core.general.Find(active_general))
				info += {"
				Name: [active_general.fields["name"]] ID: [active_general.fields["id"]]
				<br><br>Sex: [active_general.fields["sex"]]
				<br><br>Age: [active_general.fields["age"]]
				<br><br>Rank: [active_general.fields["rank"]]
				<br><br>Fingerprint: [active_general.fields["fingerprint"]]
				<br><br>DNA: [active_general.fields["dna"]]
				<br><br>Physical Status: [active_general.fields["p_stat"]]
				<br><br>Mental Status: [active_general.fields["m_stat"]]"}
			else
				info += "<strong>General Record Lost!</strong><br>"
			if ((istype(active_secure, /data/record) && data_core.security.Find(active_secure)))
				info += {"
				<br><br><center><strong>Security Data</strong></center><br>
				<br>Criminal Status: [active_secure.fields["criminal"]]
				<br><br>Minor Crimes: [active_secure.fields["mi_crim"]]
				<br><br>Details: [active_secure.fields["mi_crim_d"]]
				<br><br><br>Major Crimes: [active_secure.fields["ma_crim"]]
				<br><br>Details: [active_secure.fields["ma_crim_d"]]
				Important Notes:<br>
				<br>&emsp;[active_secure.fields["notes"]]<br>"}

			else
				info += "<br><center><strong>Security Record Lost!</strong></center><br>"
			info += "</tt>"

			var/signal/signal = get_free_signal()
			signal.data["data"] = info
			signal.data["title"] = "Security Record"
			peripheral_command("print",signal, "\ref[printcard]")
			return FALSE

		network_print()
			if (!connected || !selected_printer || !server_netid)
				return TRUE

			var/computer/file/record/printRecord = new
			printRecord.fields += "title=Security Record"
			printRecord.fields += "Security Record"
			if (istype(active_general, /data/record) && data_core.general.Find(active_general))

				printRecord.fields += "Name: [active_general.fields["name"]] ID: [active_general.fields["id"]]"
				printRecord.fields += "Sex: [active_general.fields["sex"]]"
				printRecord.fields += "Age: [active_general.fields["age"]]"
				printRecord.fields += "Rank: [active_general.fields["rank"]]"
				printRecord.fields += "Fingerprint: [active_general.fields["fingerprint"]]"
				printRecord.fields += "DNA: [active_general.fields["dna"]]"
				printRecord.fields += "Physical Status: [active_general.fields["p_stat"]]"
				printRecord.fields += "Mental Status: [active_general.fields["m_stat"]]"
			else
				printRecord.fields += "General Record Lost!"

			if ((istype(active_secure, /data/record) && data_core.security.Find(active_secure)))

				printRecord.fields += "Security Data"
				printRecord.fields += "Criminal Status: [active_secure.fields["criminal"]]"
				printRecord.fields += "Minor Crimes: [active_secure.fields["mi_crim"]]"
				printRecord.fields += "Details: [active_secure.fields["mi_crim_d"]]"
				printRecord.fields += "Major Crimes: [active_secure.fields["ma_crim"]]"
				printRecord.fields += "Details: [active_secure.fields["ma_crim_d"]]"
				printRecord.fields += "Important Notes:"
				printRecord.fields += "[active_secure.fields["notes"]]"

			else
				printRecord.fields += "Security Record Lost!"

			printRecord.name = "printout"

			message_server("command=print&args=print [selected_printer]", printRecord)
			return FALSE

		message_server(var/message, var/computer/file/toSend)
			if (!connected || !server_netid || !message)
				return TRUE

			var/netCard = find_peripheral("NET_ADAPTER")
			if (!netCard)
				return TRUE

			var/signal/termsignal = get_free_signal()

			termsignal.data["address_1"] = server_netid
			termsignal.data["data"] = message
			termsignal.data["command"] = "term_message"
			if (toSend)
				termsignal.data_file = toSend

			peripheral_command("transmit", termsignal, "\ref[netCard]")
			return FALSE

		connect_printserver(var/address, delayCaller=0)
			if (connected)
				return TRUE

			var/netCard = find_peripheral("NET_ADAPTER")
			if (!netCard)
				return TRUE

			var/signal/signal = get_free_signal()

			signal.data["address_1"] = address
			signal.data["command"] = "term_connect"
			signal.data["device"] = "SRV_TERMINAL"
			var/computer/file/user_data/user_data = account
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
			if (!server_netid)
				return TRUE

			var/netCard = find_peripheral("NET_ADAPTER")
			if (!netCard)
				return TRUE

			var/signal/signal = get_free_signal()

			signal.data["address_1"] = server_netid
			signal.data["command"] = "term_disconnect"

			peripheral_command("transmit", signal, "\ref[netCard]")

			return FALSE

		ping_server(delayCaller=0)
			if (connected)
				return TRUE

			var/netCard = find_peripheral("NET_ADAPTER")
			if (!netCard)
				return TRUE

			potential_server_netid = null
			peripheral_command("ping", null, "\ref[netCard]")

			if (delayCaller)
				sleep(8)
				return (potential_server_netid == null)

			return FALSE

#undef MENU_MAIN
#undef MENU_INDEX
#undef MENU_IN_RECORD
#undef MENU_FIELD_INPUT
#undef MENU_SEARCH_INPUT
#undef MENU_SETTINGS
#undef MENU_SELECT_PRINTER

#undef FIELDNUM_NAME
#undef FIELDNUM_SEX
#undef FIELDNUM_AGE
#undef FIELDNUM_RANK
#undef FIELDNUM_PRINT
#undef FIELDNUM_CRIMSTAT
#undef FIELDNUM_MINCRIM
#undef FIELDNUM_MINDET
#undef FIELDNUM_MAJCRIM
#undef FIELDNUM_MAJDET

#undef FIELDNUM_DELETE
#undef FIELDNUM_NEWREC