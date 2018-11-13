//CONTENTS:
//Primary OS for Computerx


/computer/file/terminalx_program/os/main_os
	name = "System"
	gui_app = 1

	var/tmp/mode = 1
	var/list/known_drives = list()
	var/tmp/computer/file/terminalx_program/application = null
	var/tmp/computer/folder/current_folder = null

	var/const
		setup_taskbar_y = 1
		setup_titlestring_x = 3

	Del()
		clear_icons()
		..()
		return
/*
	get_temp()
		if (istype(application))
			return application.get_temp()

		return temp
*/
	proc

		add_compicon(var/obj/compx_icon/new_compicon, gx=1, gy=1)
			if (!istype(new_compicon) || !istype(temp, /compx_window/grid))
				return

			var/compx_window/grid/gridwind = temp

			if (gx <= 0 || gy <= 0)
				return

			gridwind.gridList[gx][gy] = new_compicon
			gui_icons[new_compicon.icon_id] = new_compicon
			new_compicon.grid_x = gx
			new_compicon.grid_y = gy
			return

		clear_icons()
			for (var/i in gui_icons)
				var/obj/compx_icon/killme = gui_icons[i]
				qdel(killme)

			gui_icons.len = 0
			return

		set_mode(var/new_mode=0)
			mode = new_mode
			if (new_mode > 0)

				if (!istype(temp, /compx_window/grid))
					temp = new /compx_window/grid(src)
					qdel(temp:gridList)
					temp:gridList = new /list(compx_gridx_max, compx_gridy_max)


				//temp = new /list(gridx_max, gridy_max)
				clear_icons()

				var/obj/compx_icon/temp_icon = new /obj/compx_icon(src)
				temp_icon.action_tag = "menu"
				temp_icon.action_arg = "main"
				temp_icon.icon_state = "menu-main"
				temp_icon.name = ""
				temp_icon.no_drag = 1

				add_compicon(temp_icon, 1, setup_taskbar_y)

				//temp = new /compx_window/grid(src)
				master.graphic_mode = 1

			switch(new_mode)
				if (0) //Text console mode.
					//TO-DO
					master.graphic_mode = 0
					if (istype(temp))
						qdel(temp)



					return

				if (1) //Desktop display mode.
					if (!istype(temp, /compx_window/grid))
						return

					var/compx_window/grid/gridTemp = temp
					//Let's go back up a folder!
					var/obj/compx_icon/temp_icon
					if (current_folder != current_folder.holder.root)
						temp_icon = new /obj/compx_icon(src)
						temp_icon.action_tag = "system"
						temp_icon.action_arg = "root"
						temp_icon.icon_state = "arrow"
						temp_icon.dir = 1
						temp_icon.name = ""
						temp_icon.no_drag = 1

						add_compicon(temp_icon, compx_gridx_max-1, setup_taskbar_y)

					//Drive switching button
					temp_icon = new /obj/compx_icon(src)
					temp_icon.action_tag = "system"
					temp_icon.action_arg = "drive"
					if (!current_folder)
						current_folder = holding_folder
					temp_icon.icon_state = "disk-[istype(current_folder.holder, /obj/item/disk/data/fixed_disk) ? "hd" : "fd"]"
					temp_icon.name = ""
					temp_icon.no_drag = 1

					add_compicon(temp_icon, compx_gridx_max, setup_taskbar_y)

					gridTemp.gridList[setup_titlestring_x][setup_taskbar_y] = "<strong>[current_folder.holder.title]</strong>"

					var/i = ( (compx_gridy_max - 1) * (compx_gridx_max) )
					var/ix = 0
					var/iy = setup_taskbar_y + 1
					for (var/computer/C in current_folder.contents)
						i--
						if (i <= 0)
							break

						ix++
						if (ix > compx_gridx_max)
							ix = 0
							iy++

						var/obj/compx_icon/file_icon = new /obj/compx_icon(src)
						file_icon.name = copytext(C.name, 1, 10)
						if (istype(C, /computer/folder))
							file_icon.icon_state = "folder"
						else
							if (C.metadata["ico"])
								file_icon.icon_state = C.metadata["ico"]
							else
								file_icon.icon_state = "file-generic"
						file_icon.action_tag = "file"
						file_icon.action_arg = "\ref[C]"

						add_compicon(file_icon, ix, iy)

			master.updateUsrDialog()
			return

		detect_drives()
			if (!master)
				return
			known_drives.len = 0
			if (master.hd)
				known_drives += master.hd

			for (var/obj/item/peripheralx/drive/DR in master.peripherals)
				if (DR.disk)
					known_drives += DR.disk

			return

		run_program(computer/file/terminalx_program/program)
			if (!master.run_program(program))
				return FALSE

			if (!program.gui_app)
				set_mode(0)

			application = program
			return TRUE


	initialize()
		if (..())
			return

		detect_drives()
		current_folder = holder.root

		set_mode(1)
		return

	Topic(href, href_list)
		if (..())
			return

		if (href_list["drag"])
			if (!istype(temp, /compx_window/grid))
				return

			var/compx_window/grid/window = temp
			//If everything works out here, coords[1] should be x and coords[2] should be y of the new grid location.
			var/list/coords = splittext(href_list["drag"], ",")
			if (coords.len != 2)
				return

			var/new_x = text2num(coords[1])
			var/new_y = text2num(coords[2])
			if (!isnum(new_x) || !isnum(new_y))
				return

			//boutput(world, "New-X: [new_x]<br>New-Y: [new_y]")
			if (new_x <= 0 || new_x > compx_gridx_max || new_y <= 1 || new_y > compx_gridy_max)
				//boutput(world, "new coords out of bounds")
				return

			var/obj/compx_icon/calling_icon = gui_icons[href_list["gid"]]
			if (!istype(calling_icon))
				return

			var/new_loc_check = window.gridList[new_x][new_y]
			if (!isnull(new_loc_check))
				return

			window.gridList[new_x][new_y] = calling_icon
			window.gridList[calling_icon.grid_x][calling_icon.grid_y] = null
			calling_icon.grid_x = new_x
			calling_icon.grid_y = new_y

			master.updateUsrDialog()
			return

		else if (href_list["system"])
			switch(href_list["system"])
				if ("root")
					if (istype(current_folder.holding_folder))
						current_folder = current_folder.holding_folder
					else
						current_folder = current_folder.holder.root
					set_mode(1)
				if ("drive")
					var/pick_next = 0
					var/loop_around = 1
					for (var/obj/item/disk/data/D in known_drives)
						if (D == current_folder.holder)
							pick_next = 1
							continue

						if (pick_next)
							current_folder = D.root
							loop_around = 0
							break

					if (loop_around && known_drives.len > 1)
						var/obj/item/disk/data/tempD = known_drives[1]
						if (istype(tempD))
							current_folder = tempD.root

					set_mode(1)

		else if (href_list["menu"])
			switch(href_list["menu"])
				if ("main")
					if (mode != 2)
						set_mode(2)
					else
						set_mode(1)
			return

		else if (href_list["file"])
			var/computer/C = locate(href_list["file"]) in current_folder.contents
			if (!istype(C))
				return

			//To-Do
			//boutput(world, "[istype(C, /computer/file) ? "<strong>File</strong> Folder" : "File <strong>Folder</strong>"]: <strong>Name:</strong> \"[C.name]\"")
			if (istype(C, /computer/folder))
				current_folder = C
				set_mode(1)

			if (istype(C, /computer/file/terminalx_program) && C:executable && !(C in master.processing_programs))
				run_program(C)

			return

		//boutput(world, "Topic Input: \"[href]\"")
		return

	disk_inserted(var/obj/item/disk/data/inserted)
		if (!(inserted in known_drives))
			known_drives += inserted

		return

	disk_ejected(var/obj/item/disk/data/ejected)
		if (holder == ejected)
			clear_icons()

			master.override_temp = "<font color=red><strong>Fatal Error:</strong> Unable to read system file.</font>"
			master.graphic_mode = 0
			master.updateUsrDialog()

			quit()
			return

		if (current_folder && current_folder.holder == ejected)
			current_folder = holder.root

		detect_drives()
		if (mode > 0)
			set_mode(mode)
		return

	input_text(var/text, source=0)
		if (..())
			return

		master.visible_message("<strong>[master]</strong> <em>beeps</em>, \"[text]\"")
		return


/obj/item/disk/data/floppy/computerxboot
	name = "data disk-'ThinkOS/2'"

	New()
		..()
		root.add_file( new /computer/file/terminalx_program/os/main_os(src))
		var/computer/folder/newfolder = new /computer/folder(  )
		newfolder.name = "logs"
		root.add_file( newfolder )
		newfolder.add_file( new /computer/file/record/c3help(src))
		newfolder = new /computer/folder
		newfolder.name = "bin"
		root.add_file( newfolder )
		//newfolder.add_file( new /computer/file/terminal_program/writewizard(src))
