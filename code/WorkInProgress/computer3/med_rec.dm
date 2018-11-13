


#define MENU_MAIN 0 //Byond. Enums.  Lacks them. Etc
#define MENU_INDEX 1
#define MENU_IN_RECORD 2
#define MENU_FIELD_INPUT 3
#define MENU_SEARCH_INPUT 4
#define MENU_VIRUS_INDEX 5
#define MENU_VIRUS_RECORD 6

#define FIELDNUM_NAME 1
#define FIELDNUM_SEX 2
#define FIELDNUM_AGE 3
#define FIELDNUM_PRINT 4
#define FIELDNUM_DNA 5
#define FIELDNUM_PSTAT 6
#define FIELDNUM_MSTAT 7
#define FIELDNUM_BLOODTYPE 8
#define FIELDNUM_MINDIS 9
#define FIELDNUM_MINDET 10
#define FIELDNUM_MAJDIS 11
#define FIELDNUM_MAJDET 12
#define FIELDNUM_DISEASE 13
#define FIELDNUM_DISDET 14

#define FIELDNUM_DELETE "d"
#define FIELDNUM_NEWREC 99

/computer/file/terminal_program/medical_records
	name = "MedTrak"
	size = 12
	req_access = list(access_medical)
	var/tmp/menu = MENU_MAIN
	var/tmp/field_input = 0
	var/tmp/authenticated = null //Are we currently logged in?
	var/computer/file/user_data/account = null
	var/list/record_list = list()  //List of records, for jumping direclty to a specific ID
	var/data/record/active_general = null //General record
	var/data/record/active_medical = null //Medical record
	var/log_string = null //Log usage of record system, can be dumped to a text file.

	var/setup_acc_filepath = "/logs/sysusr"//Where do we look for login data?
	var/setup_logdump_name = "medlog" //What name do we give our logdump textfile?

	initialize()
/*
		var/title_art = {"<pre>
  __  __        _     _____          _
 |  \\/  |___ __| |___|_   _|_ _ __ _| |__
 | |\\/| / -_) _` |___| | | | '_/ _` | / /
 |_|  |_\\___\\__,_|     |_| |_| \\__,_|_\\_\\</pre>"}
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

					if ("3") //Viral records.

						master.temp = null
						print_text(virusmenu_text())

						menu = MENU_VIRUS_INDEX
						return

			if (MENU_INDEX)
				var/index_number = round( max( text2num(command), 0) )
				if (index_number == 0)
					menu = MENU_MAIN
					master.temp = null
					print_text(mainmenu_text())
					return

				if (!istype(record_list) || index_number > record_list.len)
					print_text("Invalid record.")
					return

				var/data/record/check = record_list[index_number]
				if (!check || !istype(check))
					print_text("<strong>Error:</strong> Record Data Invalid.")
					return

				active_general = check
				active_medical = null
				if (data_core.general.Find(check))
					for (var/data/record/E in data_core.medical)
						if ((E.fields["name"] == active_general.fields["name"] || E.fields["id"] == active_general.fields["id"]))
							active_medical = E
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
						var/obj/item/peripheral/printcard = find_peripheral("LAR_PRINTER")
						if (!printcard)
							print_text("<strong>Error:</strong> No printer detected.")
							return

						//Okay, let's put together something to print.
						var/info = "<center><strong>Medical Record</strong></center><br>"
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
						if ((istype(active_medical, /data/record) && data_core.medical.Find(active_medical)))
							info += {"
							<br><br><center><strong>Medical Data</strong></center><br>
							<br><br>Current Health: [active_medical.fields["h_imp"]]
							<br>Blood Type: [active_medical.fields["bioHolder.bloodType"]]
							<br><br>Minor Disabilities: [active_medical.fields["mi_dis"]]
							<br><br>Details: [active_medical.fields["mi_dis_d"]]
							<br><br><br>Major Disabilities: [active_medical.fields["ma_dis"]]
							<br><br>Details: [active_medical.fields["ma_dis_d"]]
							<br><br><br>Current Diseases: [active_medical.fields["cdi"]] (per disease info placed in log/comment section)
							<br>Details: [active_medical.fields["cdi_d"]]<br><br><br>
							<br>Traits: [active_medical.fields["traits"]]<br><br><br>
							Important Notes:<br>
							<br>&emsp;[active_medical.fields["notes"]]<br>"}

						else
							info += "<br><center><strong>Medical Record Lost!</strong></center><br>"

						var/signal/signal = get_free_signal()
						signal.data["data"] = info
						signal.data["title"] = "Medical Record"
						peripheral_command("print",signal, "\ref[printcard]")

						src.print_text("Printing...")
						return

				var/field_number = round( max( text2num(command), 0) )
				if (field_number == 0)
					menu = MENU_INDEX
					print_index()
					return

				field_input = field_number
				switch(field_number)
					if (FIELDNUM_SEX)
						print_text("Please select: (1) Female (2) Male (3) Other (0) Back")
						menu = MENU_FIELD_INPUT
						return

					if (FIELDNUM_BLOODTYPE)
						print_text("Please select: (1) A+ (2) A- (3) B+ (4) B-<br> (5) AB+ (6) AB- (7) O+ (8) O- (0) Back")
						menu = MENU_FIELD_INPUT
						return

					else
						print_text("Please enter new value.")
						menu = MENU_FIELD_INPUT
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
						return

					if (FIELDNUM_PSTAT)
						if (ckey(inputText))
							active_general.fields["p_stat"] = copytext(inputText, 1, 33)
						else
							return

					if (FIELDNUM_MSTAT)
						if (ckey(inputText))
							active_general.fields["m_stat"] = copytext(inputText, 1, 33)
						else
							return

					if (FIELDNUM_PRINT)
						if (ckey(inputText))
							active_general.fields["fingerprint"] = copytext(inputText, 1, 33)
						else
							return

					if (FIELDNUM_DNA)
						if (ckey(inputText))
							active_general.fields["dna"] = copytext(inputText, 1, 40)
						else
							return


					if (FIELDNUM_BLOODTYPE)
						if (!active_medical)
							print_text("No medical record loaded!")
							menu = MENU_IN_RECORD
							return

						switch (round( max( text2num(command), 0) ))
							if (1)
								active_medical.fields["bioHolder.bloodType"] = "A+"
							if (2)
								active_medical.fields["bioHolder.bloodType"] = "A-"
							if (3)
								active_medical.fields["bioHolder.bloodType"] = "B+"
							if (4)
								active_medical.fields["bioHolder.bloodType"] = "B-"
							if (5)
								active_medical.fields["bioHolder.bloodType"] = "AB+"
							if (6)
								active_medical.fields["bioHolder.bloodType"] = "AB-"
							if (7)
								active_medical.fields["bioHolder.bloodType"] = "O+"
							if (8)
								active_medical.fields["bioHolder.bloodType"] = "O-"
							if (9)
								active_medical.fields["bioHolder.bloodType"] = "Zesty Ranch"
							if (0)
								menu = MENU_IN_RECORD
								return
							else
								return

					if (FIELDNUM_MINDIS)
						if (!active_medical)
							print_text("No medical record loaded!")
							menu = MENU_IN_RECORD
							return

						if (ckey(inputText))
							active_medical.fields["mi_dis"] = copytext(inputText, 1, MAX_MESSAGE_LEN)
						else
							return

					if (FIELDNUM_MINDET)
						if (!active_medical)
							print_text("No medical record loaded!")
							menu = MENU_IN_RECORD
							return

						if (ckey(inputText))
							active_medical.fields["mi_dis_d"] = copytext(inputText, 1, MAX_MESSAGE_LEN)
						else
							return

					if (FIELDNUM_MAJDIS)
						if (!active_medical)
							print_text("No medical record loaded!")
							menu = MENU_IN_RECORD
							return

						if (ckey(inputText))
							active_medical.fields["ma_dis"] = copytext(inputText, 1, MAX_MESSAGE_LEN)
						else
							return

					if (FIELDNUM_MAJDET)
						if (!active_medical)
							print_text("No medical record loaded!")
							menu = MENU_IN_RECORD
							return

						if (ckey(inputText))
							active_medical.fields["ma_dis_d"] = copytext(inputText, 1, MAX_MESSAGE_LEN)
						else
							return

					if (FIELDNUM_DISEASE)
						if (!active_medical)
							print_text("No medical record loaded!")
							menu = MENU_IN_RECORD
							return

						if (ckey(inputText))
							active_medical.fields["cdi"] = copytext(inputText, 1, MAX_MESSAGE_LEN)
						else
							return

					if (FIELDNUM_DISDET)
						if (!active_medical)
							print_text("No medical record loaded!")
							menu = MENU_IN_RECORD
							return

						if (ckey(inputText))
							active_medical.fields["cdi_d"] = copytext(inputText, 1, MAX_MESSAGE_LEN)
						else
							return

					if (FIELDNUM_DELETE)
						switch (ckey(inputText))
							if ("y")
								if (active_medical)
									log_string += "<br>M-Record [active_medical.fields["id"]] deleted."
									data_core.medical -= active_medical
									qdel(active_medical)
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


					if (FIELDNUM_NEWREC)
						if (active_medical)
							return

						var/data/record/R = new /data/record(  )
						R.fields["name"] = active_general.fields["name"]
						R.fields["id"] = active_general.fields["id"]
						R.name = "Medical Record #[R.fields["id"]]"
						R.fields["bioHolder.bloodType"] = "Unknown"
						R.fields["mi_dis"] = "None"
						R.fields["mi_dis_d"] = "No minor disabilities have been declared."
						R.fields["ma_dis"] = "None"
						R.fields["ma_dis_d"] = "No major disabilities have been diagnosed."
						R.fields["alg"] = "None"
						R.fields["alg_d"] = "No allergies have been detected in this patient."
						R.fields["cdi"] = "None"
						R.fields["cdi_d"] = "No diseases have been diagnosed at the moment."
						R.fields["notes"] = "No notes."
						R.fields["h_imp"] = "No health implant detected."
						R.fields["traits"] = "No known traits."
						data_core.medical += R
						active_medical = R

						log_string += "<br>New medical record created."
						print_active_record()
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
				active_medical = null //Time to find the accompanying medical record, if it even exists.
				for (var/data/record/E in data_core.medical)
					if ((E.fields["name"] == active_general.fields["name"] || E.fields["id"] == active_general.fields["id"]))
						active_medical = E
						break

				menu = MENU_IN_RECORD
				print_active_record()
				return

			if (MENU_VIRUS_INDEX)
				var/entrydat = null
				switch (copytext(text, 1,2))
					if ("0")
						menu = MENU_MAIN
						master.temp = null
						print_text(virusmenu_text())
						return
					if ("1")
						entrydat = {"<strong>Name:</strong> GBS
						<br><strong>Number of stages:</strong> 5
						<br><strong>Spread:</strong> Airborne Transmission
						<br><strong>Possible Cure:</strong> Spaceacillin
						<br><strong>Affected Species:</strong> Human
						<br>
						<br><strong>Notes:</strong> If left untreated death will occur.
						<br>
						<br><strong>Severity:</strong> Major"}
					if ("2")
						entrydat = {"<strong>Name:</strong> Common Cold
						<br><strong>Number of stages:</strong> 3
						<br><strong>Spread:</strong> Airborne Transmission
						<br><strong>Possible Cure:</strong> Rest
						<br><strong>Affected Species:</strong> Human
						<br>
						<br><strong>Notes:</strong> If left untreated the subject will contract the flu.
						<br>
						<br><strong>Severity:</strong> Minor"}
					if ("3")
						entrydat = {"<strong>Name:</strong> The Flu
						<br><strong>Number of stages:</strong> 3
						<br><strong>Spread:</strong> Airborne Transmission
						<br><strong>Possible Cure:</strong> Rest
						<br><strong>Affected Species:</strong> Human
						<br>
						<br><strong>Notes:</strong> If left untreated the subject will feel quite unwell.
						<br>
						<br><strong>Severity:</strong> Medium"}

					if ("4")
						entrydat = {"<strong>Name:</strong> Jungle Fever
						<br><strong>Number of stages:</strong> 1
						<br><strong>Spread:</strong> Airborne Transmission
						<br><strong>Possible Cure:</strong> None
						<br><strong>Affected Species:</strong> Monkey
						<br>
						<br><strong>Notes:</strong> Monkies with this disease will bite humans, causing humans to spontaneously to mutate into a monkey.
						<br>
						<br><strong>Severity:</strong> Medium"}

					if ("5")
						entrydat = {"<strong>Name:</strong> Clowning Around
						<br><strong>Number of stages:</strong> 4
						<br><strong>Spread:</strong> Contact Transmission
						<br><strong>Possible Cure:</strong> Spaceacillin
						<br><strong>Affected Species:</strong> Human
						<br>
						<br><strong>Notes:</strong> Subjects are affected by rampant honking and a fondness for shenanigans. They may also spontaneously phase through closed airlocks.
						<br>
						<br><strong>Severity:</strong> Laughable"}

					if ("6")
						entrydat = {"<strong>Name:</strong> Space Rhinovirus
						<br><strong>Number of stages:</strong> 4
						<br><strong>Spread:</strong> Airborne Transmission
						<br><strong>Possible Cure:</strong> Spaceacillin
						<br><strong>Affected Species:</strong> Human
						<br>
						<br><strong>Notes:</strong> This disease transplants the genetic code of the intial vector into new hosts.
						<br>
						<br><strong>Severity:</strong> Medium"}

					if ("7")
						entrydat = {"<strong>Name:</strong> Robot Transformation
						<br><strong>Number of stages:</strong> 5
						<br><strong>Spread:</strong> Infected food
						<br><strong>Possible Cure:</strong> Electric shock.
						<br><strong>Affected Species:</strong> Human
						<br>
						<br><strong>Notes:</strong> This disease, actually acute nanomachine infection, converts the victim into a cyborg.
						<br>
						<br><strong>Severity:</strong> Major"}

					if ("8")
						entrydat = {"<strong>Name:</strong> Teleportitis
						<br><strong>Number of stages:</strong> 1
						<br><strong>Spread:</strong> Unknown
						<br><strong>Possible Cure:</strong> Unknown
						<br><strong>Affected Species:</strong> Human
						<br>
						<br><strong>Notes:</strong> Means of transmission are currently unknown,
						may be related to contents of teleporter emissions.  Causes violent shifts
						in physical position of subject.  Keep patients away from active engines.<br>
						<br><strong>Severity:</strong> Unknown"}

					if ("9")
						entrydat = {"<strong>Name:</strong> Berserker
						<br><strong>Number of stages:</strong> 2
						<br><strong>Spread:</strong> Contact Transmission
						<br><strong>Possible Cure:</strong> Spaceacillin
						<br><strong>Affected Species:</strong> Human
						<br>
						<br><strong>Notes:</strong> This disease causes fits of extreme rage and violence in the victim.
						Due to its ability to spread, it is considered extremely dangerous.
						Do not attempt to reason with infected persons.<br>
						<br><strong>Severity:</strong> Major"}

					else

						return

				master.temp = null
				print_text("[entrydat]<br>Enter 0 to return.")
				menu = MENU_VIRUS_RECORD

			if (MENU_VIRUS_RECORD)
				if (copytext(text, 1,2) == "0")
					master.temp = null
					menu = MENU_MAIN
					print_text(mainmenu_text())
				return

		return


	proc
		mainmenu_text()
			var/dat = {"<center>M E D T R A K</center><br>
			Welcome to Medtrak 5.1<br>
			<strong>Commands:</strong>
			<br>(1) View medical records.
			<br>(2) Search for a record.
			<br>(3) View viral database.
			<br>(0) Quit."}

			return dat

		virusmenu_text()
			var/dat = {"<strong>Known Diseases:</strong><br>
					(01) GBS<br>
					(02) Common Cold<br>
					(03) Flu<br>
					(04) Jungle Fever<br>
					(05) Clowning Around<br>
					(06) Space Rhinovirus<br>
					(07) Robot Transformation<br>
					(08) Teleportitis<br>
					(09) Berserker<br>
					Enter virus number or 0 to return."}

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
			<br>\[__]<strong>Rank:</strong> [active_general.fields["rank"]]
			<br>\[04]<strong>Fingerprint:</strong> [active_general.fields["fingerprint"]]
			<br>\[05]<strong>DNA:</strong> [active_general.fields["dna"]]
			<br>\[06]Physical Status: [active_general.fields["p_stat"]]
			<br>\[07]Mental Status: [active_general.fields["m_stat"]]"}

			if ((istype(active_medical, /data/record) && data_core.medical.Find(active_medical)))
				view_string += {"<br><center><strong>Medical Data:</strong></center>
				<br>\[__]Current Health: [active_medical.fields["h_imp"]]
				<br>\[08]Blood Type: [active_medical.fields["bioHolder.bloodType"]]
				<br>\[09]Minor Disabilities: [active_medical.fields["mi_dis"]]
				<br>\[10]Details: [active_medical.fields["mi_dis_d"]]
				<br>\[11]<br>Major Disabilities: [active_medical.fields["ma_dis"]]
				<br>\[12]Details: [active_medical.fields["ma_dis_d"]]
				<br>\[13]<br>Current Diseases: [active_medical.fields["cdi"]] (per disease info placed in log/comment section)
				<br>\[14]Details: [active_medical.fields["cdi_d"]]
				<br>\[15]Traits: [active_medical.fields["traits"]]
				<br>Important Notes:
				<br>&emsp;[active_medical.fields["notes"]]"}
			else
				view_string += "<br><br><strong>Medical Record Lost!</strong>"
				view_string += "<br>\[99] Create New Medical Record.<br>"

			view_string += "<br>Enter field number to edit a field<br>(R) Redraw (D) Delete (P) Print (0) Return to index."

			print_text("<strong>Record Data:</strong><br>[view_string]")
			return TRUE

		print_index()
			master.temp = null
			var/dat = ""
			if (!record_list || !record_list.len)
				print_text("<strong>Error:</strong> No records found in database.")

			else
				dat = "Please select a record:"
				var/leadingZeroCount = length("[record_list.len]")
				for (var/x = 1, x <= record_list.len, x++)
					var/data/record/R = record_list[x]
					if (!R || !istype(R))
						dat += "<br><strong>\[[add_zero("[x]",leadingZeroCount)]]</strong><font color=red>ERR: REDACTED</font>"
						continue

					dat += "<br><strong>\[[add_zero("[x]",leadingZeroCount)]]</strong>[R.fields["id"]]: [R.fields["name"]]"

			dat += "<br><br>Enter record number, or 0 to return."

			print_text(dat)
			return TRUE

		find_access_file() //Look for the whimsical account_data file
			var/computer/folder/accdir = holder.root
			if (master.host_program) //Check where the OS is, preferably.
				accdir = master.host_program.holder.root

			var/computer/file/user_data/target = parse_file_directory(setup_acc_filepath, accdir)
			if (target && istype(target))
				account = target
				return TRUE

			return FALSE

#undef MENU_MAIN
#undef MENU_INDEX
#undef MENU_IN_RECORD
#undef MENU_FIELD_INPUT
#undef MENU_SEARCH_INPUT
#undef MENU_VIRUS_INDEX
#undef MENU_VIRUS_RECORD

#undef FIELDNUM_NAME
#undef FIELDNUM_SEX
#undef FIELDNUM_AGE
#undef FIELDNUM_PRINT
#undef FIELDNUM_DNA
#undef FIELDNUM_PSTAT
#undef FIELDNUM_MSTAT
#undef FIELDNUM_BLOODTYPE
#undef FIELDNUM_MINDIS
#undef FIELDNUM_MINDET
#undef FIELDNUM_MAJDIS
#undef FIELDNUM_MAJDET
#undef FIELDNUM_DISEASE
#undef FIELDNUM_DISDET

#undef FIELDNUM_DELETE
#undef FIELDNUM_NEWREC