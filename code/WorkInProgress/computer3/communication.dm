/computer/file/terminal_program/communications
	name = "COMMaster"
	size = 16
	req_access = list(access_heads)
	var/tmp/authenticated = null //Are we currently logged in?
	var/computer/file/user_data/account = null
	var/obj/item/peripheral/network/radio/radiocard = null
	var/obj/item/peripheral/network/powernet_card/pnet_card = null
	var/tmp/comm_net_id = null //The net id of our linked ~comm dish~
	var/tmp/reply_wait = -1 //How long do we wait for replies? -1 is not waiting.

	var/setup_acc_filepath = "/logs/sysusr"//Where do we look for login data?

	initialize()

		authenticated = null
		master.temp = null
		if (!find_access_file()) //Find the account information, as it's essentially a ~digital ID card~
			src.print_text("<strong>Error:</strong> Cannot locate user file.  Quitting...")
			master.unload_program(src) //Oh no, couldn't find the file.
			return

		radiocard = locate() in master.peripherals
		if (!radiocard || !istype(radiocard))
			radiocard = null
			print_text("<strong>Warning:</strong> No radio module detected.")

		pnet_card = locate() in master.peripherals
		if (!pnet_card || !istype(pnet_card))
			pnet_card = null
			print_text("<strong>Warning:</strong> No network adapter detected.")

		if (!check_access(account.access))
			src.print_text("User [src.account.registered] does not have needed access credentials.<br>Quitting...")
			master.unload_program(src)
			return

		reply_wait = -1
		authenticated = account.registered

		print_shuttle_status()
		var/intro_text = {"<br>Welcome to COMMaster!
		<br>InterStation Communication System.
		<br><strong>Commands:</strong>
		<br>(Status) to view current status.
		<br>(Link) to link with a comm array.
		<br>(Call) to call shuttle.
		<br>(Recall) to recall shuttle.
		<br>(Clear) to clear the screen.
		<br>(Quit) to exit COMMaster."}
		print_text(intro_text)


	input_text(text)
		if (..())
			return

		var/list/command_list = parse_string(text)
		var/command = command_list[1]
		command_list -= command_list[1] //Remove the command we are now processing.

		switch(lowertext(command))

			if ("status")
				print_shuttle_status()

			if ("link")
				if (!pnet_card) //can't do this ~fancy network stuff~ without a network card.
					print_text("<strong>Error:</strong> Network card required.")
					master.add_fingerprint(usr)
					return

				src.print_text("Now scanning for communications array...")
				detect_comm_dish()

			if ("call")
				if (!pnet_card)
					print_text("<strong>Error:</strong> Network card required.")
					master.add_fingerprint(usr)
					return

				if (!comm_net_id)
					detect_comm_dish()
					sleep(8)
					if (!comm_net_id)
						print_text("<strong>Error:</strong> Unable to detect comm dish.  Please check network cabling.")
						return

				if (solar_flare)
					print_text("Solar Flare activity is preventing contact with the Emergency Shuttle.")
				else
					src.print_text("Transmitting call request...")
					generate_signal(comm_net_id, "command", "call", "shuttle_id", "emergency", "acc_code", netpass_heads)

			if ("recall")
				if (!pnet_card)
					print_text("<strong>Error:</strong> Network card required.")
					master.add_fingerprint(usr)
					return

				if (istype(usr, /mob/living/silicon/ai) || authenticated == "AIUSR")
					print_text("<strong>Error:</strong> Shuttle recall from AIUSR blocked by Central Command.")
					return

				if (!comm_net_id)
					detect_comm_dish()
					sleep(8)
					if (!comm_net_id)
						print_text("<strong>Error:</strong> Unable to detect comm dish.  Please check network cabling.")
						return

				if (solar_flare)
					print_text("Solar Flare activity is preventing contact with the Emergency Shuttle.")
				else
					src.print_text("Transmitting recall request...")
					generate_signal(comm_net_id, "command", "recall", "shuttle_id", "emergency", "acc_code", netpass_heads)

			if ("help")
				var/help_text = {"<strong>Commands:</strong>
				<br>(Status) to view current status.
				<br>(Link) to link with a comm array.
				<br>(Call) to call shuttle.
				<br>(Recall) to recall shuttle.
				<br>(Clear) to clear the screen.
				<br>(Quit) to exit COMMaster."}
				print_text(help_text)

			if ("clear")
				master.temp = null
				master.temp_add = "Workspace cleared.<br>"

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

	process()
		if (..())
			return

		if (reply_wait > 0)
			reply_wait--
			if (reply_wait == 0)
				print_text("Timed out on Dish. Please rescan and retry.")
				comm_net_id = null

	receive_command(obj/source, command, signal/signal)
		if ((..()) || (!signal))
			return

		//If we don't have a comm dish net_id to use, set one.
		switch(signal.data["command"])
			if ("ping_reply")
				if (comm_net_id)
					return
				if ((signal.data["device"] != "PNET_COM_ARRAY") || !signal.data["netid"])
					return

				comm_net_id = signal.data["netid"]
				print_text("Communications array detected.")
			if ("device_reply")
				if (!comm_net_id || signal.data["sender"] != comm_net_id)
					return

				reply_wait = -1

				switch(lowertext(signal.data["status"]))
					if ("shutl_e_dis")
						print_text("<strong>Alert:</strong> Shuttle command request rejected!")

					if ("shutl_e_sen")
						print_text("<strong>Alert:</strong> The Emergency Shuttle has been called.")
						if (master && master.current_user)
							message_admins("<span style=\"color:blue\">[key_name(master.current_user)] called the Emergency Shuttle to the station</span>")
							logTheThing("station", null, null, "[key_name(master.current_user)] called the Emergency Shuttle to the station")

					if ("shutl_e_ret")
						print_text("<strong>Alert:</strong> The Emergency Shuttle has been recalled.")
						if (master && master.current_user)
							message_admins("<span style=\"color:blue\">[key_name(master.current_user)] recalled the Emergency Shuttle</span>")
							logTheThing("station", null, null, "[key_name(master.current_user)] recalled the Emergency Shuttle")

				return


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

		detect_comm_dish() //Send out a ping signal to find a comm dish.
			if (!pnet_card)
				return //The card is kinda crucial for this.

			var/signal/newsignal = get_free_signal()
			//newsignal.encryption = "\ref[pnet_card]"

			comm_net_id = null
			reply_wait = -1
			peripheral_command("ping", newsignal, "\ref[pnet_card]")

		generate_signal(var/target_id, var/key, var/value, var/key2, var/value2, var/key3, var/value3)
			if (!pnet_card || !comm_net_id)
				return

			var/signal/signal = get_free_signal()
			//signal.encryption = "\ref[pnet_card]"
			signal.data["address_1"] = target_id
			signal.data[key] = value
			if (key2)
				signal.data[key2] = value2
			if (key3)
				signal.data[key3] = value3

			reply_wait = 5
			peripheral_command("transmit", signal, "\ref[pnet_card]")



		print_shuttle_status()
			var/dat = "<strong>Status</strong>: "
			if (emergency_shuttle.online && emergency_shuttle.location==0)
				var/timeleft = emergency_shuttle.timeleft()
				dat += "<strong>Emergency shuttle</strong><br>ETA: [timeleft / 60 % 60]:[add_zero(num2text(timeleft % 60), 2)]"
			else
				dat += "No shuttles currently en route."

			print_text(dat)

			return
