/computer/file/pda_program/os
	proc
		receive_os_command(list/command_list)
			if ((!holder) || (!master) || (!command_list) || !(command_list["command"]))
				return TRUE

			if ((!istype(holder)) || (!istype(master)))
				return TRUE

			if (!(holder in master.contents))
				if (master.active_program == src)
					master.active_program = null
				return TRUE

			return FALSE

		pda_message()

//Main os program: Provides old pda interface and four programs including file browser, notes, messenger, and atmos scan
	main_os
		name = "ThinkOS 7"
		size = 8
		var/mode = 0
		//Note vars
		var/note = "Congratulations, your station has chosen the Thinktronic 5150 Personal Data Assistant!"
		var/note_mode = 0 //0 For note editor, 1 for note browser
		var/computer/file/text/note_file = null //If set, save to this file.
		var/computer/folder/note_folder = null //Which folder are we looking in?
		//Messenger vars
		var/list/detected_pdas = list()
		var/message_on = 1
		var/message_silent = 0 //To beep or not to beep, that is the question
		var/message_mode = 0 //0 for pda list, 1 for messages
		var/message_tone = "beep" //Custom ringtone
		var/message_note = null //Current messages in memory (Store as separate file only later??)
		var/message_last = 0 //world.time of last send for both messages and file sending.
		var/last_filereq_id = null //net id of last dude to request a file transfer
		var/target_filereq_id = null //Who are we trying to send a file to?
		//File browser vars
		var/computer/folder/browse_folder = null
		var/computer/file/clipboard = null //Current file to copy


		mess_off //Same as regular but with messaging off
			message_on = 0

		disposing()
			if (detected_pdas)
				detected_pdas.len = 0
				detected_pdas = null

			note_folder = null
			note_file = null
			browse_folder = null
			clipboard = null

			..()

		receive_os_command(list/command_list)
			if (..())
				return

			//boutput(world, "[command_list["command"]]")
			return

		return_text()
			if (..())
				return

			. = return_text_header()

			switch(mode)
				if (0)
					. += "<h2>PERSONAL DATA ASSISTANT</h2>"
					. += "Owner: [master.owner]<br><br>"

					. += "<h4>General Functions</h4>"
					. += "<ul>"
					. += "<li><a href='byond://?src=\ref[src];mode=1'>Notekeeper</a></li>"
					. += "<li><a href='byond://?src=\ref[src];mode=2'>Messenger</a></li>"
					. += "<li><a href='byond://?src=\ref[src];mode=3'>File Browser</a></li>"
					. += "</ul>"

					. += "<h4>Utilities</h4>"
					. += "<ul>"
					. += "<li><a href='byond://?src=\ref[src];mode=4'>Atmospheric Scan</a></li>"
					. += "<li>Scanner: [master.scan_program ? "<a href='byond://?src=\ref[src];scanner=1'>[master.scan_program.name]</a>" : "None loaded"]</li>"
//					. += "<li><a href='byond://?src=\ref[src];flight=1'>[master.fon ? "Disable" : "Enable"] Flashlight</a></li>"

					if (master.module)
						if (master.module.setup_allow_os_config)
							. += "<li><a href='byond://?src=\ref[src];mode=5'>Module Config</a></li>"

						if (master.module.setup_use_menu_badge)
							. += "<li>[master.module.return_menu_badge()]</li>"

					. += "</ul>"

				if (1)
					//Note Program.  Can save/load note files.
					. += "<h4>Notekeeper V2.5</h4>"

					if (!note_mode)
						if ((!isnull(master.uplink)) && (master.uplink.active))
							. += "<a href='byond://?src=\ref[src];note_func=lock'>Lock</a><br>"
						else
							. += "<a href='byond://?src=\ref[src];input=note'>Edit</a>"
							. += " | <a href='byond://?src=\ref[src];note_func=new'>New File</a>"
							. += " | <a href='byond://?src=\ref[src];note_func=save'>Save</a>"
							. += " | <a href='byond://?src=\ref[src];note_func=switchmenu'>Load</a><br>"

						. += note
					else
						. += " <a href='byond://?src=\ref[src];note_func=switchmenu'>Back</a>"
						if ((!note_folder) || !(note_folder.holder in master))
							note_folder = holding_folder

						. += " | \[[note_folder.holder.file_amount - note_folder.holder.file_used]\] Free"
						. += " \[<a href='byond://?src=\ref[src];note_func=drive'>[note_folder.holder == master.hd ? "MAIN" : "CART"]</a>\]<br>"
						. += "<table cellspacing=5>"

						for (var/computer/file/text/T in note_folder.contents)
							. += "<tr><td><a href='byond://?src=\ref[src];target=\ref[T];note_func=load'>[T.name]</a></td>"
							. += "<td>[T.extension]</td>"
							. += "<td>Length: [T.data ? (length(T.data)) : "0"]</td></tr>"

						. += "</table>"

				if (2)
					//Messenger.  Uses Radio.  Is a messenger.
					master.overlays = null //Remove existing alerts
					. += "<h4>SpaceMessenger V4.0.5</h4>"

					if (!message_mode)

						. += "<a href='byond://?src=\ref[src];message_func=ringer'>Ringer: [message_silent == 1 ? "Off" : "On"]</a> | "
						. += "<a href='byond://?src=\ref[src];message_func=on'>Send / Receive: [message_on == 1 ? "On" : "Off"]</a> | "
						. += "<a href='byond://?src=\ref[src];input=tone'>Set Ringtone</a> | "
						. += "<a href='byond://?src=\ref[src];message_mode=1'>Messages</a><br>"

						. += "<font size=2><a href='byond://?src=\ref[src];message_func=scan'>Scan</a></font><br>"
						. += "<strong>Detected PDAs</strong><br>"

						. += "<ul>"

						var/count = 0

						if (message_on)
							for (var/department_id in page_departments)
								. += "<li><a href='byond://?src=\ref[src];input=message;target=[page_departments[department_id]];department=1'>DEPT-[department_id]</a></li>"

							for (var/P_id in detected_pdas)
								var/P_name = detected_pdas[P_id]
								if (!P_name)
									detected_pdas -= P_id
									continue
								else if (P_id == master.net_id) //I guess this can happen if somebody copies the system file.
									detected_pdas -= P_id
									continue

								. += "<li><a href='byond://?src=\ref[src];input=message;target=[P_id]'>PDA-[P_name]</a>"
								. += " (<a href='byond://?src=\ref[src];input=send_file;target=[P_id]'>*Send File*</a>)"


								. += "</li>"
								count++

						. += "</ul>"

						if (count == 0 && !page_departments.len)
							. += "None detected.<br>"

					else
						. += "<a href='byond://?src=\ref[src];message_func=clear'>Clear</a> | "
						. += "<a href='byond://?src=\ref[src];message_mode=0'>Back</a><br>"

						. += "<h4>Messages</h4>"

						. += message_note
						. += "<br>"

				if (3)
					//File Browser.
					//To-do(?): Setting "favorite" programs to access straight from main menu
					//Not sure how needed it is, not like they have to go through 500 subfolders or whatever
					if ((!browse_folder) || !(browse_folder.holder in master))
						browse_folder = holding_folder

					. += " | <a href='byond://?src=\ref[src];target=\ref[browse_folder];browse_func=paste'>Paste</a><br>"

					. += "<strong>Contents of [browse_folder] | Drive ID:\[[src.browse_folder.holder.title]]</strong><br>"
					. += "<strong>Used: \[[browse_folder.holder.file_used]/[browse_folder.holder.file_amount]\]</strong><hr>"

					. += "<table cellspacing=5>"
					for (var/computer/file/F in browse_folder.contents)
						if (F == src)
							. += "<tr><td>System</td><td>Size: [size]</td><td>SYSTEM</td></tr>"
							continue
						. += "<tr><td><a href='byond://?src=\ref[src];target=\ref[F];browse_func=open'>[F.name]</a></td>"
						. +=  "<td>Size: [F.size]</td>"

						. += "<td>[F.extension]</td>"

						. += "<td><a href='byond://?src=\ref[src];target=\ref[F];browse_func=delete'>Del</a></td>"
						. += "<td><a href='byond://?src=\ref[src];target=\ref[F];input=rename'>Rename</a></td>"

						. += "<td><a href='byond://?src=\ref[src];target=\ref[F];browse_func=copy'>Copy</a></td>"

						. += "</tr>"

					. += "</table>"
					var/computer/folder/other_drive_folder
					for (var/obj/item/disk/data/D in master)
						if (D != browse_folder.holder && D.root)
							other_drive_folder = D.root
							break

					if (other_drive_folder)
						. += "<hr><strong>Contents of [other_drive_folder] | Drive ID:\[[other_drive_folder.holder.title]]</strong><br>"
						. += "<strong>Used: \[[other_drive_folder.holder.file_used]/[other_drive_folder.holder.file_amount]\]</strong> | <a href='byond://?src=\ref[src];target=\ref[other_drive_folder];browse_func=paste'>Paste</a><hr>"

						. += "<table cellspacing=5>"
						for (var/computer/file/F in other_drive_folder.contents)
							if (F == src)
								. += "<tr><td>System</td><td>Size: [size]</td><td>SYSTEM</td></tr>"
								continue
							. += "<tr><td><a href='byond://?src=\ref[src];target=\ref[F];browse_func=open'>[F.name]</a></td>"
							. +=  "<td>Size: [F.size]</td>"

							. += "<td>[F.extension]</td>"

							. += "<td><a href='byond://?src=\ref[src];target=\ref[F];browse_func=delete'>Del</a></td>"
							. += "<td><a href='byond://?src=\ref[src];target=\ref[F];input=rename'>Rename</a></td>"

							. += "<td><a href='byond://?src=\ref[src];target=\ref[F];browse_func=copy'>Copy</a></td>"

							. += "</tr>"
						. += "</table>"

				if (4)
					//Atmos Scanner
					. += "<h4>Atmospheric Readings</h4>"

					var/turf/T = get_turf(master)
					if (isnull(T))
						. += "Unable to obtain a reading.<br>"
					else
						. += scan_atmospheric(T, 1) // Replaced with global proc (Convair880).

					. += "<br>"

		Topic(href, href_list)
			if (..())
				return

			if (href_list["mode"])
				var/newmode = text2num(href_list["mode"])
				mode = max(newmode, 0)

//			else if (href_list["flight"])
//				master.toggle_light()

			else if (href_list["scanner"])
				if (master.scan_program)
					master.scan_program = null

			else if (href_list["input"])
				switch(href_list["input"])
					if ("tone")
						var/t = input(usr, "Please enter new ringtone", name, message_tone) as text
						if (!t)
							return

						if (!master || !in_range(master, usr) && master.loc != usr)
							return

						if (!(holder in master))
							return

						if ((master.uplink) && (cmptext(t,master.uplink.lock_code)))
							boutput(usr, "The PDA softly beeps.")
							master.uplink.unlock()
						else
							t = copytext(sanitize(strip_html(t)), 1, 20)
							message_tone = t

					if ("note")
						var/inputtext = html_decode(replacetext(note, "<br>", "\n"))

						var/t = input(usr, "Please enter note", name, inputtext) as message
						if (!t)
							return

						if (!master || !in_range(master, usr) && master.loc != usr)
							return

						if (!(holder in master))
							return
						t = replacetext(t, "\n", "|||")
						t = copytext(adminscrub(t), 1, MAX_MESSAGE_LEN)
						t = replacetext(t, "|||", "<br>")
						note = t


					if ("message")
						if (message_last + 20 > world.time) //Message sending delay
							return

						//var/obj/item/device/pda2/P = locate(href_list["target"])
						//if (!P || !istype(P) || !P.net_id)
							//return

						var/is_department_page = href_list["department"] == "1"
						var/target_id = href_list["target"]
						var/target_name = is_department_page ? target_id : detected_pdas[target_id]
						if (!target_id in detected_pdas)
							return

						var/t = input(usr, "Please enter message", target_name, null) as text
						if (!t)
							return

						pda_message(target_id, target_name, t, is_department_page)

						if (href_list["norefresh"])
							master.add_fingerprint(usr)
							return

					if ("rename")
						var/computer/file/F = locate(href_list["target"])
						if (!F || !istype(F))
							return

						var/t = input(usr, "Please enter new name", name, F.name) as text
						t = copytext(sanitize(strip_html(t)), 1, 16)
						if (!t)
							return
						if (!in_range(master, usr) || !(F.holder in master))
							return
						if (F.holder.read_only)
							return
						F.name = capitalize(lowertext(t))

					if ("send_file") //Give a file send request thing for current copied file.
						if (message_last + 20 > world.time) //File sending delay.
							return

						var/target_id = href_list["target"]
						var/target_name = detected_pdas[target_id]
						if (!target_id in detected_pdas)
							return

						if (!message_on || !clipboard || !(clipboard.holder in master))
							return

						var/signal/signal = get_free_signal()
						signal.data["command"] = "file_send_req"
						signal.data["file_name"] = clipboard.name
						signal.data["file_ext"] = clipboard.extension
						signal.data["file_size"] = clipboard.size
						signal.data["sender_name"] = master.owner
						//signal.data["sender"] = master.net_id
						signal.data["address_1"] = target_id
						post_signal(signal)
						message_note += "<em><strong>&rarr; File Send Request to [target_name]</strong></em><br>"
						target_filereq_id = target_id
						message_last = world.time



			else if (href_list["message_func"]) //Messenger specific topic junk
				switch(href_list["message_func"])
					if ("ringer")
						message_silent = !message_silent
					if ("on")
						message_on = !message_on
					if ("clear")
						message_note = null
					if ("scan")
						if (message_on)
							detected_pdas = list()
							master.pdasay_autocomplete = list()
							var/signal/signal = get_free_signal()
							signal.data["command"] = "report_pda"
							//signal.data["sender"] = master.net_id
							post_signal(signal)
					if ("accfile")
						if (message_on)
							var/signal/newsignal = get_free_signal()
							last_filereq_id = href_list["sender"]

							if (!last_filereq_id) return

							newsignal.data["address_1"] = last_filereq_id
							newsignal.data["command"] = "file_send_acc"
							post_signal(newsignal)


			else if (href_list["note_func"]) //Note program specific topic junk
				switch(href_list["note_func"])
					if ("new")
						note_file = null
						note = null
					if ("save")
						if (isnull(note_file) || !(note_file.holder in master) || note_file.holder.read_only)
							var/computer/file/text/F = new /computer/file/text
							if (!holding_folder.add_file(F))
								//qdel(F)
								F.dispose()
							else
								note_file = F
								F.data = note
						else
							note_file.data = note

					if ("load")
						var/computer/file/text/T = locate(href_list["target"])
						if (!T || !istype(T))
							return

						note_file = T
						note = note_file.data
						note_mode = 0

					if ("switchmenu")
						note_mode = !note_mode

					if ("drive")
						if (note_folder.holder == master.hd && master.cartridge && (master.cartridge.root))
							note_folder = master.cartridge.root
						else
							note_folder = holding_folder

					if ("lock")
						if (master.uplink)
							master.uplink.active = 0
							note = master.uplink.orignote


			else if (href_list["browse_func"]) //File browser specific topic junk
				var/computer/target = locate(href_list["target"])
				switch(href_list["browse_func"])
					if ("drive")
						if (browse_folder.holder == master.hd && master.cartridge && (master.cartridge.root))
							browse_folder = master.cartridge.root
						else
							browse_folder = holding_folder
					if ("open")
						if (!target || !istype(target))
							return
						if (istype(target, /computer/file/pda_program))
							if (istype(target,/computer/file/pda_program/os) && (master.host_program))
								return
							else
								master.run_program(target)
								master.updateSelfDialog()
								return

						else if (istype(target, /computer/file/text))
							if (!isnull(master.uplink) && master.uplink.active)
								return
							else
								note = target:data
								note_file = target
								mode = 1
								master.updateSelfDialog()
								return

					if ("delete")
						if (!target || !istype(target))
							return
						master.delete_file(target)

					if ("copy")
						if (istype(target,/computer/file) && (!target.holder || (target.holder in master.contents)))
							clipboard = target

					if ("paste")
						if (istype(target,/computer/folder))
							if (!clipboard || !clipboard.holder || !(clipboard.holder in master.contents))
								return

							if (!istype(clipboard))
								return

							clipboard.copy_file_to_folder(target)
/*
					if ("install") //Given a file on another system and the other system itself.
						var/obj/item/device/pda2/source = locate(href_list["sender"])
						if (!source || !istype(source) || !target || !istype(target, /computer/file))
							return

						if (!message_on)
							return

						if (!(target.holder in source.contents))
							return

						if (target:copy_file_to_folder(holding_folder))
							message_note += "<strong><em>File Accepted from [source.owner]</strong></em><br>"
*/

			else if (href_list["message_mode"])
				var/newmode = text2num(href_list["message_mode"])
				message_mode = max(newmode, 0)

			master.add_fingerprint(usr)
			master.updateSelfDialog()
			return


		network_hook(signal/signal)

			if (signal.data["command"] == "report_pda")
				if (!message_on || !signal.data["sender"] || signal.data["sender"] == master.net_id)
					return

				var/signal/newsignal = get_free_signal()
				newsignal.data["command"] = "report_reply"
				newsignal.data["address_1"] = signal.data["sender"]
				newsignal.data["owner"] = master.owner
				post_signal(newsignal)

				master.updateSelfDialog()
			return


		receive_signal(signal/signal)
			if (..())
				return

			switch(signal.data["command"])
				if ("text_message")
					if (!message_on || !signal.data["message"])
						return

					if (signal.data["group"]) //Check to see if it's our ~mailgroup~
						if (signal.data["group"] != master.mailgroup)
							return

					var/sender = signal.data["sender_name"]
					if (!sender)
						sender = "!Unknown!"

					if ((length(signal.data["sender"]) == 8) && (ishex(signal.data["sender"])) )
						if (!(signal.data["sender"] in detected_pdas))
							detected_pdas += signal.data["sender"]
							//master.pdasay_autocomplete += sender
						detected_pdas[signal.data["sender"]] = sender
						master.pdasay_autocomplete[sender] = signal.data["sender"]

					//Only add the reply link if the sender is another pda2.

					var/senderstring = "From <a href='byond://?src=\ref[src];input=message;target=[signal.data["sender"]]'>[sender]</a>"

					message_note += "<em><strong>&larr; [senderstring]:</strong></em><br>[signal.data["message"]]<br>"
					var/alert_beep = null //Don't beep if set to silent.
					if (!message_silent)
						alert_beep = message_tone

					if ((signal.data["batt_adjust"] == netpass_syndicate) && (signal.data["address_1"] == master.net_id) && !(master.exploding))
						if (master)
							master.exploding = 1
						spawn (20)
							if (master)
								master.explode()

					master.display_alert(alert_beep)

					if (ismob(master.loc)) //Alert the person holding us.
						var/mob/M = master.loc
						boutput(M, "<em><strong>[bicon(master)] <a href='byond://?src=\ref[src];input=message;norefresh=1;target=[signal.data["sender"]]'>[sender]</a>:</strong></em> [signal.data["message"]]")

					master.updateSelfDialog()

				if ("file_send_req")
					if (!message_on)
						return

					var/filename = signal.data["file_name"]
					var/sender = signal.data["sender"]
					var/sendername = signal.data["sender_name"]
					var/file_ext = signal.data["file_ext"]
					var/filesize = signal.data["file_size"]

					if (!filename || !sender)
						return

					if (!sendername)
						sendername = "!Unknown!"

					if (!(sender in detected_pdas))
						detected_pdas += sender
						//master.pdasay_autocomplete += sendername
					detected_pdas[sender] = sendername
					master.pdasay_autocomplete[sendername] = signal.data["sender"]


					message_note += {"
<em><strong>&larr;File Offer From <a href='byond://?src=\ref[src];input=message;target=[sender]'>[sendername]</a>:</strong></em><br>
<a href='byond://?src=\ref[src];message_func=accfile;sender=[sender]'>[filename]</a>
 | Ext: [file_ext ? file_ext : "NONE"]
 | Size: [filesize ? filesize : "???"]<br>"}

					var/alert_beep = null //Same as with messages
					if (!message_silent)
						alert_beep = message_tone

					last_filereq_id = sender
					master.display_alert(alert_beep)

				if ("file_send_acc")
					if (!message_on)
						return

					if (!target_filereq_id || signal.data["sender"] != target_filereq_id)
						return

					if (!clipboard || !istype(clipboard))
						return

					var/signal/sendsig = new
					sendsig.data_file = clipboard.copy_file()
					sendsig.data["command"] = "file_send"
					sendsig.data["sender_name"] = master.owner
					sendsig.data["address_1"] = signal.data["sender"]
					post_signal(sendsig)


				if ("file_send")
					if (!message_on)
						return

					if (!message_on)
						return

					var/sender = signal.data["sender"]
					if (sender != last_filereq_id)
						return

					var/sender_name = "!UNKNOWN!"
					if (signal.data["sender_name"])
						sender_name = signal.data["sender_name"]

					if (!signal.data_file)
						return

					if (signal.data_file.copy_file_to_folder(holding_folder))
						message_note += "<strong><em>File Accepted from [sender_name]</strong></em><br>"
					return

			// this is now in network_hook
			/*
				if ("report_pda")
					if (!message_on || !signal.data["sender"])
						return

					var/signal/newsignal = get_free_signal()
					newsignal.data["command"] = "report_reply"
					newsignal.data["address_1"] = signal.data["sender"]
					newsignal.data["owner"] = master.owner
					post_signal(newsignal)
			*/
				if ("report_reply")
					if (!detected_pdas)
						detected_pdas = new()

					var/newsender = ckey(copytext(signal.data["sender"], 1, 9))

					if (!newsender)
						return

					var/newowner = signal.data["owner"]
					if (!newowner)
						newowner = "!UNKNOWN!"

					var/sender_name = newowner
					if (!(newsender in detected_pdas))
						detected_pdas += newsender
						//master.pdasay_autocomplete += sender_name

					detected_pdas[newsender] = sender_name
					master.pdasay_autocomplete[sender_name] = newsender

					master.updateSelfDialog()

			return

		return_text_header()
			if (!master)
				return

			. = ""
			if (mode)
				. += " | <a href='byond://?src=\ref[src];mode=0'>Main Menu</a>"
				. += " | <a href='byond://?src=\ref[master];refresh=1'>Refresh</a>"

			else
				if (!isnull(master.cartridge))
					. += " | <a href='byond://?src=\ref[master];eject_cart=1'>Eject [master.cartridge]</a>"
				if (!isnull(master.ID_card))
					. += " | <a href='byond://?src=\ref[master];eject_id_card=1'>Eject [master.ID_card]</a>"

		pda_message(var/target_id, var/target_name, var/message, var/is_department_message)
			if (!master || (!in_range(master, usr) && master.loc != usr))
				return TRUE

			if (!target_id || !target_name || !message)
				return TRUE

			if (!(holder in master))
				return TRUE

			message = copytext(adminscrub(message), 1, 257)

			if (findtext(message, "viagra") != 0 || findtext(message, "erect") != 0 || findtext(message, "pharm") != 0 || findtext(message, "girls") != 0 || findtext(message, "scient") != 0 || findtext(message, "luxury") != 0 || findtext(message, "vid") != 0 || findtext(message, "quality") != 0)
				usr.unlock_medal("Spamhaus", 1)

			var/signal/signal = get_free_signal()
			signal.data["command"] = "text_message"
			signal.data["message"] = message
			signal.data["sender_name"] = master.owner
			//signal.data["sender"] = master.net_id
			if (is_department_message)
				signal.data["group"] = target_id
			else
				signal.data["address_1"] = target_id
			post_signal(signal)
			message_note += "<em><strong>&rarr; To [target_name]:</strong></em><br>[message]<br>"
			message_last = world.time

			logTheThing("pdamsg", null, null, "<em><strong>[master.owner]'s PDA used by [key_name(master.loc)] &rarr; [target_name]:</strong></em> [message]")
			return FALSE
