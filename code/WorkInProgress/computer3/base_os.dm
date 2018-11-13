/computer/file/terminal_program/os/main_os/no_login
	setup_needs_authentication = 0

/computer/file/terminal_program/os/main_os
	name = "ThinkDOS"
	size = 12
	var/tmp/computer/folder/current_folder = null
	var/tmp/computer/file/clipboard = null
	var/tmp/computer/file/text/command_log = null
	var/tmp/computer/file/record/help_lib = null
	var/tmp/computer/file/user_data/active_account = null
	var/echo_input = 1
	var/log_errors = 1
	var/list/peripherals = list()
	var/authenticated = null //Is anyone logged in?

	var/setup_version_name = "ThinkDOS 0.7.2"
	var/setup_needs_authentication = 1 //Do we need to present an ID to use this?
	//Setup for data logging
#define SETUP_LOG_DIRECTORY "logs"
#define SETUP_LOG_FILENAME "syslog"
	//Setup for help library
#define SETUP_HELP_FILEPATH "/logs/helplib"
	//Where to put user account data.
#define SETUP_ACC_DIRECTORY "logs"
#define SETUP_ACC_FILENAME "sysusr"

	disposing()
		peripherals = null
		current_folder = null
		clipboard = null
		command_log = null
		help_lib = null
		active_account = null

		..()

	input_text(text)
		if (..())
			return

		var/list/command_list = parse_string(text)
		var/command = command_list[1]
		command_list -= command_list[1] //Remove the command we are now processing.

		if (echo_input)
			print_text(strip_html(text))

		print_to_log(text) //print to log strips html as it logs, no need to do it here!!

		if (!current_folder)
			current_folder = holding_folder

		if (!authenticated && setup_needs_authentication)
			switch(lowertext(command))
				if ("login","logon")
					if (issilicon(usr) && !isghostdrone(usr))
						system_login("AIUSR","Station AI", null, 1)
						//print_text("Authorization Accepted.<br>Welcome, AIUSR!<br><strong>Current Folder: [current_folder.name]</strong>")
						//authenticated = "AI"
						//print_to_log("LOGIN: AIUSR | \[Station AI]")
					else
						var/obj/item/peripheral/scanner = find_peripheral("ID_SCANNER")
						if (!scanner)
							print_text("<strong>Error:</strong> No ID scanner detected.")
							return
						var/signal/login_result = peripheral_command("scan_card", null, "\ref[scanner]")
						if (istype(login_result))
							system_login(login_result.data["registered"], login_result.data["assignment"], login_result.data["access"])
						else if (login_result == "nocard")
							print_text("<strong>Error:</strong> No ID card inserted.")

				else
					print_text("Login required.  Please use \"login\" command.")

		else
			switch(lowertext(command))
				if ("cls", "home") //Clear temp var of master computer3
					master.temp = null
					master.temp_add = "Screen cleared.<br>" //Okay perhaps not entirely clear.
					master.updateUsrDialog()

				if ("dir", "catalog", "ls") //Show contents of current folder

					src.print_text("<strong>Files on [current_folder.holder.title] - Used: \[[src.current_folder.holder.file_used]/[src.current_folder.holder.file_amount]\]</strong>")
					print_text("<strong>Current Folder: [current_folder.name]</strong>")

					var/dir_text = null
					for (var/computer/P in current_folder.contents)
						if (P == src)
							dir_text += "[name] -  SYSTEM - \[Size: [size]]<br>"
							continue

						dir_text += "[P.name] - [(istype(P,/computer/folder)) ? "FOLDER" : "[P:extension]"] - \[Size: [P.size]]<br>"

					if (dir_text)
						print_text(dir_text)

				if ("cd", "chdir") //Attempts to set current folder to directory arg1
					var/dir_string = null
					if (command_list.len)
						dir_string = jointext(command_list, " ")
					else
						print_text("<strong>Syntax:</strong> \"cd \[directory string]\" String is relative to current directory.")
						return

					if (dir_string == "/") //If it is seriously just /, act like the root command
						current_folder = current_folder.holder.root
						print_text("<strong>Current Directory is now [current_folder.name]</strong>")
						return

					var/computer/folder/new_dir = parse_directory(dir_string, current_folder)
					if (!new_dir || !istype(new_dir))
						print_error_text("<strong>Error:</strong> Invalid directory or path.")
						return
					else
						current_folder = new_dir
						print_text("<strong>Current Directory is now [new_dir.name]</strong>")

				if ("root") //Sets current folder to root of current drive
					if (current_folder && current_folder.holder.root)
						current_folder = current_folder.holder.root
						print_text("<strong>Current Directory is now [current_folder.name]</strong>")

				if ("run") //Runs /computer/file/terminal_program with name arg1
					var/prog_name = null
					if (command_list.len)
						prog_name = jointext(command_list, " ")
					else
						print_text("<strong>Syntax:</strong> \"run \[program filepath].\" Path is relative to current directory.")
						return

					var/computer/file/terminal_program/to_run = parse_file_directory(prog_name, current_folder)

					if (isnull(to_run) || !istype(to_run) || istype(to_run, /computer/file/terminal_program/os))
						print_error_text("<strong>Error:</strong> Invalid file name or type.")
					else
						master.run_program(to_run)
						master.updateUsrDialog()
						return

				if ("makedir","mkdir") //Creates folder in current directory with name arg1
					var/new_folder_name = strip_html(jointext(command_list, " "))
					new_folder_name = copytext(new_folder_name, 1, 16)

					if (!new_folder_name)
						print_text("<strong>Syntax:</strong> \"makedir \[new directory name]\"")
						return

					if (get_computer_datum(new_folder_name, current_folder))
						print_error_text("<strong>Error:</strong> Directory name in use.")
						return

					if (is_name_invalid(new_folder_name))
						print_error_text("<strong>Error:</strong> Invalid character in name.")
						return

					var/computer/F = new /computer/folder
					F.name = new_folder_name
					if (!current_folder.add_file(F))
						print_error_text("<strong>Error:</strong> Unable to create new directory.")
						//qdel(F)
						F.dispose()
					else
						print_text("New directory created.")

				if ("rename","ren") //Sets name of file arg1 to arg2
					var/to_rename = null
					var/new_name = null
					if (command_list.len >= 2)
						to_rename = command_list[1]
						new_name = command_list[2]
						new_name = copytext(strip_html(new_name), 1, 16)

					if (!to_rename || !new_name)
						print_text("<strong>Syntax:</strong> \"rename \[name of target] \[new name]\"")
						return

					if (is_name_invalid(new_name))
						print_error_text("<strong>Error:</strong> Invalid character in name.")
						return

					var/computer/target = get_computer_datum(to_rename, current_folder)

					if (!target || !istype(target))
						print_error_text("<strong>Error:</strong> File not found.")
						return

					var/computer/check_existing = get_computer_datum(new_name, current_folder)
					if (check_existing && check_existing != target )
						print_error_text("<strong>Error:</strong> Name in use.")
						return

					target.name = new_name
					print_text("Done.")

				if ("title") //Set the title var of the current drive.
					var/new_name = null
					if (command_list.len)
						new_name = strip_html(jointext(command_list, " "))
						new_name = copytext(new_name, 1, 16)
					else
						print_text("<strong>Syntax:</strong> \"title \[title name]\" Set name of active drive to given title.")
						return

					if (current_folder.holder && !current_folder.holder.read_only)
						current_folder.holder.title = new_name
						print_text("Drive title set to <strong>[new_name]</strong>.")
					else
						print_error_text("<strong>Error:</strong> Unable to set title string.")

				if ("delete", "del","era","erase","rm") //Deletes file arg1
					var/file_name = null
					if (command_list.len)
						file_name = ckey(jointext(command_list, " "))
					else
						print_text("<strong>Syntax:</strong> \"del \[file name].\" File must be in current directory.")
						return

					var/computer/target = get_computer_datum(file_name, current_folder)
					if (!target || !istype(target))
						print_error_text("<strong>Error:</strong> File not found.")
						return

					if (target == src)
						print_error_text("<strong>Error:</strong> Access denied.")
						return

					if (master.delete_file(target))
						print_text("File deleted.")
					else
						print_error_text("<strong>Error:</strong> Unable to delete file.")

				if ("copy","cp") //Sets file arg1 to be copied
					var/file_name = null
					if (command_list.len)
						file_name = ckey(jointext(command_list, " "))
					else
						print_text("<strong>Syntax:</strong> \"copy \[file name].\" File must be in current directory.")
						return

					var/computer/target = get_file_name(file_name, current_folder)
					if (!target || !istype(target))
						print_error_text("<strong>Error:</strong> File not found.")
						return

					clipboard = target
					print_text("File marked.")

				if ("paste","ps") //Pastes clipboard file with name arg1
					var/pasted_name = strip_html(jointext(command_list, " "))
					pasted_name = copytext(pasted_name, 1, 16)

					if (!pasted_name)
						print_text("<strong>Syntax:</strong> \"paste \[new file name].\" File is placed in current directory.")
						return

					if (!clipboard || !clipboard.holder || !(clipboard.holder in master.contents))
						print_error_text("<strong>Error:</strong> Unable to locate marked file.")
						return

					if (!istype(clipboard))
						print_error_text("<strong>Error:</strong> Invalid or corrupt file type.")
						return

					if (get_computer_datum(pasted_name, current_folder))
						print_error_text("<strong>Error:</strong> Name in use.")
						return

					if (is_name_invalid(pasted_name))
						print_error_text("<strong>Error:</strong> Invalid character in name.")
						return

					if (clipboard.copy_file_to_folder(current_folder, pasted_name))
						print_text("Done")
					else
						print_error_text("<strong>Error:</strong> Unable to paste file (Drive is full?)")

				if ("drive","drv") //Sets current folder to root of drive arg1
					var/argument1 = null
					if (command_list.len)
						argument1 = command_list[1]

					var/list/drives = get_loaded_drives()

					if (!ckey(argument1))
						var/valid_string = english_list(drives, "None", " ")
						print_text("<strong>Syntax:</strong> \"drive \[drive id].\"<br><strong>Valid IDs:</strong> ([valid_string]).")
						return

					var/obj/item/disk/data/to_load = drives[argument1]
					if (to_load && istype(to_load) && to_load.root)
						current_folder = to_load.root
						print_text("<strong>Current Drive is now [current_folder.holder.title]</strong>")
					else
						print_text("<strong>Error:</strong> Drive invalid.")

				if ("initlogs") //Restart logging if log file is deleted or otherwise lost.
					if (command_log)
						print_error_text("<strong>Error:</strong> Logging is already active.")
					else
						if (initialize_logs())
							print_text("Logging re-initialized.")
						else
							print_error_text("<strong>Error:</strong> Unable to re-initialize logging.")

				if ("help") //Allow access to "helplib" record datum.  Should be kept tup to date with system commands, etc
					if (!help_lib || !istype(help_lib) || help_lib.disposed)
						help_lib = null
						print_error_text("<strong>Error:</strong> Help file missing or corrupt.")
						return
					else
						var/argument1 = "help"
						if (command_list.len)
							argument1 = lowertext(command_list[1])

						var/help_string = help_lib.fields[argument1]
						if (help_string)
							print_text("<strong>[capitalize(argument1)]</strong><br>[help_string]")
						else
							print_error_text("<strong>Error:</strong> Invalid field.")

				if ("periph","p") //Allow some user interactions with peripheral cards.
					var/argument1 = null
					if (command_list.len)
						argument1 = command_list[1]

					switch(argument1)
						if ("view","v") //View installed cards.
							print_text("<strong>Current active peripheral cards:</strong>")
							if (!peripherals.len)
								print_text("<center>None loaded.</center>")
							else
								for (var/x = 1, x <= peripherals.len, x++)
									var/obj/item/peripheral/P = peripherals[x]
									if (istype(P))
										var/statdat = P.return_status_text()
										print_text("<strong>ID: \[[x]] [P.func_tag]</strong><br>Status: [statdat]")
									else
										peripherals -= P
										continue

						if ("command","c")
							var/id = 0
							var/pcommand = null
							var/sig_filename = null

							if (command_list.len >= 3) //These two args are needed for this mode
								id = round(text2num(command_list[2]))
								pcommand = strip_html(command_list[3])

							if (command_list.len >= 4) //Having a signal file is optional, however
								sig_filename = ckey(command_list[4])

							if (!pcommand) //Check for command first, if they skip it they also don't get the id and it complains about that and aaaa
								print_error_text("Error: Command argument required.")
								return

							if ((!id) || (id > peripherals.len) || (id <= 0))
								print_error_text("Error: ID invalid or out of bounds.")
								return

							var/computer/file/signal/sig = null
							if (sig_filename)
								sig = get_file_name(sig_filename, current_folder)
								if (!sig || (!istype(sig) && !istype(sig, /computer/file/record)))
									print_error_text("Error: Signal file missing or invalid.")
									return

							print_text("Command: <strong>ID:</strong> [id] <strong>COM:</strong> [pcommand]")
							var/signal/signal = get_free_signal()//new
							//signal.encryption = "\ref[peripherals[id]]"
							if (sig)
								if (istype(sig,/computer/file/record))
									var/computer/file/record/sigrec = sig
									for (var/entry in sigrec.fields)
										var/equalpos = findtext("=", entry)
										if (equalpos)
											signal.data["[copytext(entry, 1, equalpos)]"] = "[copytext(entry, equalpos)]"
										else
											if (!isnull(sigrec.fields[entry]))
												signal.data["[entry]"] = sigrec.fields[entry]
											else
												signal.data += entry

									if (command_list.len > 4)
										signal.data_file = get_file_name(ckey(command_list[5]), current_folder)
										if (istype(signal.data_file, /computer/file))
											signal.data_file = signal.data_file.copy_file()
										else
											signal.data_file = null

								else
									signal.data = sig.data.Copy()
									if (sig.data_file) //For file transfers!
										var/computer/file/tempfile = sig.data_file.copy_file()
										if (tempfile && istype(tempfile))
											signal.data_file = tempfile
							var/result = peripheral_command(pcommand, signal, "\ref[peripherals[id]]")
							if (result != 0)
								if (result == 1)
									print_text("Error: Command unsuccessful.")
								else if (istext(result))
									print_text("Response: [result]")

						else
							print_text("Syntax: \"periph \[mode] \[ID] \[command] \[signal file]\"<br><strong>Valid modes:</strong> (view, command)")

				if ("backprog", "bp") //Allow the user to manage programs chilling in the background
					var/argument1 = null
					if (command_list.len)
						argument1 = command_list[1]

					switch(argument1)
						if ("view", "v") //View processing programs (other than us)
							print_text("<strong>Current programs in memory:</strong>")
							if (!master.processing_programs.len) //This should never happen as we should be in it.
								print_text("<center>None detected.</center>")
							else
								for (var/x = 1, x <= master.processing_programs.len, x++)
									var/computer/file/terminal_program/T = master.processing_programs[x]
									if (istype(T))
										print_text("<strong>ID: \[[x]]</strong> [(T == src) ? "SYSTEM" : T.name]")

						if ("kill", "k") //Okay now that we know them it is time to BE RID OF THEM
							var/target_id = 0
							if (command_list.len >= 2)
								target_id = round(text2num(command_list[2]))
							else
								print_error_text("Target ID Required.")
								return

							if ((!target_id) || (target_id > master.processing_programs.len) || (target_id <= 0))
								print_error_text("<strong>Error:</strong> ID invalid or out of bounds.")
								return

							var/computer/file/terminal_program/target = master.processing_programs[target_id]
							if (!target || !istype(target) || target == src) //No terminating ourselves!!
								print_error_text("<strong>Error:</strong> Invalid Target.")
								return

							master.unload_program(target)
							print_text("Program killed.")

						if ("switch", "s")
							var/target_id = 0
							if (command_list.len >= 2)
								target_id = round(text2num(command_list[2]))
							else
								print_error_text("Target ID Required.")
								return

							if ((!target_id) || (target_id > master.processing_programs.len) || (target_id <= 0))
								print_error_text("<strong>Error:</strong> ID invalid or out of bounds.")
								return

							var/computer/file/terminal_program/target = master.processing_programs[target_id]
							if (!target || !istype(target) || target == src || istype(target, /computer/file/terminal_program/os)) //No re-running ourselves!!
								print_error_text("<strong>Error:</strong> Invalid Target.")
								return

							src.print_text("Switching to target...")
							master.run_program(target)
							master.updateUsrDialog()
							return


						else
							print_text("<strong>Syntax:</strong> \"backprog \[mode] \[ID]\"<br><strong>Valid modes:</strong> (view, kill, switch)")


				if ("print") //Print text arg1 to screen.
					var/new_text = strip_html(jointext(command_list, " "))
					if (new_text)
						print_text(new_text)
					else
						print_text("<strong>Syntax:</strong> \"print \[text to be printed]\"")

				if ("goonsay") //Display text arg1 along with goonsay ascii
					var/goon = {" __________<br>
								(--\[ .]-\[ .] /<br>
								(_______0__)<br>
								"}

					var/anger_text = "A clown? On a space station? what"
					if (istype(command_list) && (command_list.len > 0))
						anger_text = strip_html(jointext(command_list, " "))

					print_text("<tt>[anger_text]<br>[goon]</tt>")

/*
				if ("echo") //Determine if entered commands are printed to screen
					var/argument1 = null
					if (command_list.len)
						argument1 = command_list[1]

					switch(argument1)
						if ("on","ON")
							echo_input = 1

						if ("off","OFF")
							echo_input = 0

						else
							echo_input = !echo_input

					print_text("Input Echo is now <strong>[echo_input ? "ON" : "OFF"]</strong>")
*/
				if ("user") //Show current user identfication data
					if (!setup_needs_authentication)
						print_error_text("Account system inactive.")
						return

					if (!active_account)
						print_error_text("<strong>Error:</strong> Unable to find account file.")
						return

					print_text("Current User: [active_account.registered]<br>Rank: [active_account.assignment]")

				if ("logout","logoff") //Log out if we are currently logged in.
					if (!setup_needs_authentication || !authenticated)
						print_error_text("Account system inactive.")
						return
					else
						print_to_log("<strong>LOGOUT:</strong> [authenticated]",0)
						authenticated = null
						active_account = null
						master.temp = null
						echo_input = 1

						//Kill off any background programs that may be running.
						for (var/computer/file/terminal_program/T in master.processing_programs)
							if (T == src)
								continue

							master.unload_program(T)

						print_text("Logout complete. Have a secure day.<br><br>Authentication required.<br>Please insert card and \"Login.\"")


				if ("read","type") //Display contents of text file arg1
					var/file_name = null
					if (command_list.len)
						file_name = ckey(jointext(command_list, " "))
					else
						print_text("<strong>Syntax:</strong> \"read \[file name].\" Text file must be in current directory.")
						return

					var/computer/file/text/T = get_file_name(file_name, current_folder)

					if (isnull(T) || !istype(T) || !T.data)
						if (istype(T, /computer/file/record))
							var/print_buffer = null
							var/computer/file/record/R = T
							for (var/i in R.fields)
								if (R.fields[i])
									print_buffer += "[i]: [R.fields[i]]<br>"
								else
									print_buffer += "[i]<br>"
							if (print_buffer)
								print_text(print_buffer)
							else
								print_error_text("<strong>Error:</strong> File is empty.")
							return

						print_error_text("<strong>Error:</strong> Invalid or blank file.")
					else
						print_text(T.data)

				if ("version") //Show the version name.  ~Flavortext~
					print_text("[setup_version_name]<br>Copyright 2047 Thinktronic Systems, LTD.")

				if ("time") //Hello my immersion needs to know the time
					print_text("System time: [time2text(world.realtime, "DDD MMM DD hh:mm:ss")], 2053.")

				else
					//Load the program if they just entered a path I guess
					var/prog_name = jointext(command_list, " ")
					prog_name = command + prog_name

					var/computer/file/terminal_program/to_run = parse_file_directory(prog_name, current_folder)

					if (isnull(to_run) || !istype(to_run) || istype(to_run, /computer/file/terminal_program/os))
						print_text("Syntax Error.")
					else
						master.run_program(to_run)
						master.updateUsrDialog()
						return

		return

	initialize()
		src.print_text("Loading [src.setup_version_name]<br>Scanning for peripheral cards...")

		peripherals = new //Figure out what cards are there now so we can address them later all easy-like
		for (var/obj/item/peripheral/P in master.peripherals)
			if (!(P in peripherals))
				peripherals += P

		src.print_text("Preparing filesystem...")

		command_log = null
		help_lib = null
		authenticated = null

		current_folder = holder.root

		if (initialize_logs()) //Get the logging file ready.
			print_text("<font color=red>Log system failure.</font>")

		if (initialize_help()) //Find the help file so it can help people.
			print_text("<font color=red>Help library not found.</font>")

		if (setup_needs_authentication && initialize_accounts())
			print_text("<font color=red>Unable to start account system.</font>")

		if (setup_needs_authentication)
			print_text("Authentication required.<br>Please insert card and \"Login.\"")

		else
			print_text("Ready.")

		return

	disk_ejected(var/obj/item/disk/data/thedisk)
		if (!thedisk)
			return

		if (current_folder && (current_folder.holder == thedisk))
			current_folder = holding_folder

		if (holder == thedisk)
			print_text("<font color=red><strong>System Error:</strong> Unable to read system file.</font>")
			master.active_program = null
			master.host_program = null
			return

		return
/*
	receive_command(obj/source, command, signal/signal)
		if ((..()))
			return

		if ((command == "card_authed") && signal && (!authenticated) && setup_needs_authentication)

			system_login(signal.data["registered"], signal.data["assignment"], signal.data["access"])
			return

		return
*/

	proc
		//Log this text in the ~system log~ as well as printing it.
		print_error_text(text)
			if (log_errors)
				print_to_log(text, 0)

			return print_text(text)

		initialize_logs() //Man we sure love logging things.  Let's set up a log for our logging.
			var/computer/folder/logdir = parse_directory(SETUP_LOG_DIRECTORY, holder.root)
			if (!logdir || !istype(logdir))
				logdir = new /computer/folder
				if (holder.root.add_file(logdir))
					logdir.name = SETUP_LOG_DIRECTORY
				else
					return -1 //Must be read-only or something if we can't add a folder. Give up.

			var/computer/file/text/the_log = get_file_name(SETUP_LOG_FILENAME, logdir)
			if (the_log && istype(the_log))
				command_log = the_log

			else
				the_log = new /computer/file/text()
				if (logdir.add_file(the_log))
					command_log = the_log
					the_log.name = SETUP_LOG_FILENAME

				else
					return -2

			the_log.data += "<br><strong>STARTUP:</strong> [time2text(world.realtime, "DDD MMM DD hh:mm:ss")], 2053"
			return FALSE

		print_to_log(text, strip_input=1)
			if (!text)
				return FALSE
			if (!command_log || !istype(command_log) || !command_log.holder)
				return FALSE

			if (!(command_log.holder in master.contents))
				return FALSE

			if (strip_input)
				command_log.data += "<br>[strip_html(text)]"
			else
				command_log.data += "<br>[text]"

			return TRUE

		initialize_help() //It's pretty similar to initialize_logs(), but unable to recreate the file if missing.

			var/computer/file/record/target_rec = parse_file_directory(SETUP_HELP_FILEPATH)
			if (target_rec && istype(target_rec))
				help_lib = target_rec
				print_to_log("Help System Initialized.")
				return FALSE

			return -1

		initialize_accounts()
			var/computer/folder/accdir = parse_directory(SETUP_ACC_DIRECTORY, holder.root)
			if (!accdir || !istype(accdir))
				accdir = new /computer/folder
				if (holder.root.add_file(accdir))
					accdir.name = SETUP_ACC_DIRECTORY
				else
					return -1 //Oh welp read only

			var/computer/file/user_data/the_acc = get_file_name(SETUP_ACC_FILENAME, accdir)
			if (the_acc && istype(the_acc))
				active_account = the_acc

			else
				the_acc = new /computer/file/user_data()
				if (accdir.add_file(the_acc))
					active_account = the_acc
					the_acc.name = SETUP_ACC_FILENAME

				else
					return -1

			return FALSE

		system_login(var/acc_name, var/acc_job, var/access_string, all_access=0)
			if (!acc_name || !acc_job)
				return

			if (!active_account && !initialize_accounts()) //Oh welp we can't write it to file
				print_text("<strong>Error:</strong> Unable to write account file.")
				return -1

			authenticated = acc_name
			active_account.access = list()
			active_account.registered = acc_name
			active_account.assignment = acc_job
			current_folder = holder.root

			if (access_string && !all_access)
				var/list/decoding = splittext(access_string, ";")
				for (var/x in decoding)
					active_account.access += text2num(x)

			else if (all_access)
				active_account.access = get_all_accesses()

			print_to_log("<strong>LOGIN:</strong> [acc_name] | \[[acc_job]]", 0)

			print_text("Welcome, [acc_name]!<br><strong>Current Folder: [current_folder.name]</strong>")
			return FALSE

		get_loaded_drives() //Return a list of the drives in the master computer3.
			var/list/drives = list()
			var/drive_num = 0
			if (master.hd)
				drives["hd0"] = master.hd
			if (master.diskette)
				drives["fd0"] = master.diskette

			for (var/obj/item/disk/data/drive in master.contents)
				if (drive == master.hd || drive == master.diskette)
					continue
				drives["sd[drive_num]"] = drive
				drive_num++

			return drives

#undef SETUP_LOG_DIRECTORY
#undef SETUP_LOG_FILENAME
#undef SETUP_HELP_FILEPATH
#undef SETUP_ACC_DIRECTORY
#undef SETUP_ACC_FILENAME