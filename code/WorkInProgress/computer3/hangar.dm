#define HANGAR_AREATYPE "/area/hangar"
/computer/file/terminal_program/hangar_control
	name = "HangarControl"
	size = 16
	req_access = list(access_hangar)
	var/tmp/authenticated = null //Are we currently logged in?
	var/computer/file/user_data/account = null
	var/tmp/reply_wait = -1 //How long do we wait for replies? -1 is not waiting.
	var/setup_acc_filepath = "/logs/sysusr"//Where do we look for login data?

	initialize()

		authenticated = null
		master.temp = null
		if (!find_access_file()) //Find the account information, as it's essentially a ~digital ID card~
			src.print_text("<strong>Error:</strong> Cannot locate user file.  Quitting...")
			master.unload_program(src) //Oh no, couldn't find the file.
			return

		if (!check_access(account.access))
			src.print_text("User [src.account.registered] does not have needed access credentials.<br>Quitting...")
			master.unload_program(src)
			return

		reply_wait = -1
		authenticated = account.registered
		var/intro_text = {"<br>Welcome to HangarControl!
		<br>Hangar Management System.
		<br><strong>Commands:</strong>
		<br>(Status) to view current status.
		<br>(ResetPass) to reset a hangar door's password.
		<br>(CloseAll) to close all hangar doors.
		<br>(Toggle) to toggle a hangar door.
		<br>(Clear) to clear the screen.
		<br>(Quit) to exit HangarControl."}
		print_text(intro_text)

	input_text(text)
		if (..())
			return

		var/list/command_list = parse_string(text)
		var/command = command_list[1]
		command_list -= command_list[1] //Remove the command we are now processing.

		switch(lowertext(command))
			if ("status")
				print_status()
			if ("clear")
				master.temp = null
				master.temp_add = "Workspace cleared.<br>"
			if ("closeall")
				close_all()
			if ("toggle")
				var/door_name = ckey(jointext(command_list, " "))
				if (!door_name)
					var/dat = "<strong>Available Hangar Doors:</strong><br>"
					for (var/turf/T in get_area_turfs(HANGAR_AREATYPE))
						for (var/obj/machinery/r_door_control/R in T)
							if (R.open)
								dat+="[R.name]<BR>"
							else
								dat+="[R.name]<BR>"
					print_text(dat)
				else
					for (var/turf/T in get_area_turfs(HANGAR_AREATYPE))
						for (var/obj/machinery/r_door_control/R in T)
							if (cmptext(door_name,R.id))
								if (R.open)
									src.print_text("Closing Door...")
								else
									src.print_text("Opening Door...")
								R.open_door()
								print_text("Done.<BR>")
								master.add_fingerprint(usr)
								master.updateUsrDialog()
								return
					print_text("Invalid Hangar Door!<BR>")
			if ("resetpass")
				var/door_name = ckey(jointext(command_list, " "))
				if (!door_name)
					var/dat = "<strong>Available Hangar Doors:</strong><br>"
					for (var/turf/T in get_area_turfs(HANGAR_AREATYPE))
						for (var/obj/machinery/r_door_control/R in T)
							if (R.open)
								dat+="[R.name]<BR>"
							else
								dat+="[R.name]<BR>"
					print_text(dat)
				else
					for (var/turf/T in get_area_turfs(HANGAR_AREATYPE))
						for (var/obj/machinery/r_door_control/R in T)
							if (cmptext(door_name,R.id))
								R.pass = "[R.id]-[rand(100,999)]"
								print_text("[R.name] New Pass: [R.pass]")
								master.add_fingerprint(usr)
								master.updateUsrDialog()
								return
					print_text("Invalid Hangar Door!<BR>")

			if ("help")
				var/intro_text = {"<br>Welcome to HangarControl!
				<br>Hangar Management System.
				<br><strong>Commands:</strong>
				<br>(Status) to view current status.
				<br>(ResetPass) to reset a hangar door's password.
				<br>(CloseAll) to close all hangar doors.
				<br>(Toggle) to toggle a hangar door.
				<br>(Clear) to clear the screen.
				<br>(Quit) to exit HangarControl."}
				print_text(intro_text)
			if ("quit")
				master.temp = ""
				print_text("Now quitting...")
				master.unload_program(src)
				return
			else
				print_text("Unknown command : \"[copytext(strip_html(command), 1, 16)]\"")


		master.add_fingerprint(usr)
		master.updateUsrDialog()
		return

	proc
		find_access_file() //Look for the whimsical account_data file
			var/computer/folder/accdir = holder.root
			if (master.host_program) //Check where the OS is, preferably.
				accdir = master.host_program.holder.root

			var/computer/file/user_data/target = parse_file_directory(setup_acc_filepath, accdir)
			if (target && istype(target))
				account = target
				return TRUE

			return FALSE
		print_status()
			var/dat="<strong>Status</strong>:<BR>"
			for (var/turf/T in get_area_turfs(HANGAR_AREATYPE))
				for (var/obj/machinery/r_door_control/R in T)
					if (R.open)
						dat+="[R.name] (Open): [R.pass]<BR>"
					else
						dat+="[R.name] (Closed): [R.pass]<BR>"
			print_text(dat)
		close_all()
			src.print_text("Closing All Doors...")
			for (var/turf/T in get_area_turfs(HANGAR_AREATYPE))
				for (var/obj/machinery/r_door_control/R in T)
					if (R.open)
						R.open_door()
			print_text("Done.<BR>")

/computer/file/terminal_program/hangar_research
	name = "HangarHelper"
	size = 16
	req_access = list(access_hangar)
	var/tmp/authenticated = null //Are we currently logged in?
	var/computer/file/user_data/account = null
	var/tmp/reply_wait = -1 //How long do we wait for replies? -1 is not waiting.
	var/setup_acc_filepath = "/logs/sysusr"//Where do we look for login data?

	initialize()

		authenticated = null
		master.temp = null
		if (!find_access_file()) //Find the account information, as it's essentially a ~digital ID card~
			src.print_text("<strong>Error:</strong> Cannot locate user file.  Quitting...")
			master.unload_program(src) //Oh no, couldn't find the file.
			return

		if (!check_access(account.access))
			src.print_text("User [src.account.registered] does not have needed access credentials.<br>Quitting...")
			master.unload_program(src)
			return

		reply_wait = -1
		authenticated = account.registered
		print_research_status()
		var/intro_text = {"<br>HangarHelper
		<br>Bringing You the Latest in Ship Technology!.
		<br><strong>Commands:</strong>
		<br>(Status) to view current progress.
		<br>(Research) to view research topics.
		<br>(Cancel) to halt current research.
		<br>(Complete) to view completed research.
		<br>(Clear) to clear the screen.
		<br>(Quit) to exit HangarHelper"}
		print_text(intro_text)

	proc
		find_access_file() //Look for the whimsical account_data file
			var/computer/folder/accdir = holder.root
			if (master.host_program) //Check where the OS is, preferably.
				accdir = master.host_program.holder.root

			var/computer/file/user_data/target = parse_file_directory(setup_acc_filepath, accdir)
			if (target && istype(target))
				account = target
				return TRUE

			return FALSE

		print_research_status()
			var/dat = "<strong>Tier [robotics_research.tier] Hangar Research</strong><br>"
			if (robotics_research.is_researching)
				var/timeleft = robotics_research.get_research_timeleft()
				var/text = robotics_research.current_research
				dat += "Current Research: [text ? text : "None"]. ETA: [timeleft ? timeleft : "Completed"]."
			else
				dat += "Currently not researching."
			print_text(dat)
			return