//CONTENTS:
//Computerx-related globals
//Computerx machine object
//Computerx input client verb


var/obj/compx_icon/spacer/compx_grid_spacer = null
var/compx_gridy_max = 8
var/compx_gridx_max = 5

/obj/machinery/computerx
	name = "computer"
	desc = "A computer workstation."
	icon = 'icons/obj/computer.dmi'
	icon_state = "computer_generic"
	density = 1
	anchored = 1.0
	var/base_icon_state = "computer_generic"
	var/computer/file/terminalx_program/os/host_program //Our best pal, the operating system!
	var/list/processing_programs = list()
	var/list/peripherals = list()
	var/restarting = 0 //Are we currently restarting the system?
	var/obj/item/disk/data/fixed_disk/hd =  null
	var/setup_bg_color = "#1B1E1B"
	var/graphic_mode = 0 //0: Default browser 1: the window specified by the program.
	var/override_temp = null

	var/setup_starting_os = /computer/file/terminalx_program/os/main_os
	var/setup_starting_drive = /obj/item/peripheralx/drive //Do we spawn with a disk?
	var/setup_drive_size = 64
	var/setup_drive_type = /obj/item/disk/data/fixed_disk/computer3 //Use this path for the hd
	var/setup_os_string = null
	var/setup_starting_peripheral0 = /obj/item/peripheralx/card_scanner //It is advised that this be a card scanner.
	var/setup_starting_peripheral1 = /obj/item/peripheralx/drive
	var/setup_starting_peripheral2 = /obj/item/peripheralx/drive

	New()
		..()

		if (!compx_grid_spacer)
			compx_grid_spacer = new

		spawn (4)
			if (ispath(setup_starting_drive))
				new setup_starting_drive(src)

			if (ispath(setup_starting_peripheral0))
				new setup_starting_peripheral0(src)

			if (ispath(setup_starting_peripheral1))
				new setup_starting_peripheral1(src) //Peripherals add themselves automatically if spawned inside a computer.

			if (ispath(setup_starting_peripheral2))
				new setup_starting_peripheral2(src)

			if (!hd && (setup_drive_size > 0))
				if (setup_drive_type)
					hd = new setup_drive_type
					hd.set_loc(src)
				else
					hd = new /obj/item/disk/data/fixed_disk(src)
				hd.file_amount = setup_drive_size

			if (ispath(setup_starting_os) && hd)
				var/computer/file/terminalx_program/os/os = new setup_starting_os
				if ((hd.root.size + os.size) >= hd.file_amount)
					hd.file_amount += os.size

				os.setup_string = setup_os_string
				src.host_program = os
				src.host_program.master = src
				src.processing_programs += src.host_program

				hd.root.add_file(os)

			base_icon_state = icon_state

			post_system()
		return


	process()
		if (stat & (NOPOWER|BROKEN))
			return
		use_power(250)

		for (var/computer/file/terminalx_program/P in processing_programs)
			P.process()

		return

	attack_hand(mob/user as mob)
		if (..())
			return

		user.machine = src
		current_user = user

		var/wincheck = winexists(user, "compx_\ref[src]")
		//boutput(world, wincheck)
		if (wincheck != "MAIN")
			winclone(user, "compx", "compx_\ref[src]")
			winset(user, "compx_\ref[src].restart","command=\".compcommand \\\"\ref[src]%restart\"")
			winset(user, "compx_\ref[src].conin","command=\".compconsole \\\"\ref[src]\\\" \\\"")

		var/display_mode = graphic_mode
		var/workingTemp = null
		if (!src.host_program)
			display_mode = 0
		else
			workingTemp = src.host_program.get_temp()

		set_graphic_mode(graphic_mode, user)
		var/display_text = "DISPLAY ERROR -- 0xF8"

		if (display_mode)
			if (istype(workingTemp, /compx_window))
			/*
				for (var/gridy = 1, gridy <= src.host_program.gridy_max, gridy++)
					for (var/gridx = 1, gridx <= src.host_program.gridx_max, gridx++)
						if (isnull(workingTemp[gridx][gridy]))
							user << output(compx_grid_spacer, "compx_\ref[src].grid:[gridx],[gridy]")
						else
							user << output(workingTemp[gridx][gridy], "compx_\ref[src].grid:[gridx],[gridy]")
			*/
				var/compx_window/windowControl = workingTemp
				if (!winexists(user, "compxwindow_\ref[windowControl]"))
					winclone(user, windowControl.skinbase, "compxwindow_\ref[windowControl]")
					winset(user, "compxwindow_\ref[windowControl]", "is-visible=true")
				winset(user, "compx_\ref[src].screenholder","left=compxwindow_\ref[windowControl]")
				windowControl.update(user)
			else
				user << output(user, "compx_\ref[src].grid")

		else
			if (src.host_program && istext(workingTemp))
				display_text = workingTemp
			if (override_temp)
				display_text = override_temp
			user << output("<body bgcolor=[setup_bg_color] scroll=no><font color=#19A319><tt>[display_text]</tt></font>", "compx_\ref[src].screen")

		//Now for the peripheral interfaces.
		var/pcount = 1
		for (var/obj/item/peripheralx/px in peripherals)
			if (pcount > 4)
				break
			if (px.setup_has_badge) //Only put it up if it actually has something to present.
				user << output(px.return_badge(), "compx_\ref[src].periphs:[pcount],1")
				pcount++

		winshow(user,"compx_\ref[src]",1)

		onclose(user,"compx_\ref[src]")
		return

	Topic(href, href_list)
		if (..())
			return

		usr.machine = src

		if ((href_list["conin"]) && src.host_program)
			src.host_program.input_text(href_list["conin"])

		else if (href_list["restart"] && !restarting)
			restart()

		add_fingerprint(usr)
		updateUsrDialog()
		return


	power_change()
		if (stat & BROKEN)
			icon_state = base_icon_state
			icon_state += "b"

		else if (powered())
			icon_state = base_icon_state
			stat &= ~NOPOWER
		else
			spawn (rand(0, 15))
				icon_state = base_icon_state
				icon_state += "0"
				stat |= NOPOWER

	meteorhit(var/obj/O as obj)
		if (stat & BROKEN)	qdel(src)
		set_broken()
		var/effects/system/harmless_smoke_spread/smoke = new /effects/system/harmless_smoke_spread()
		smoke.set_up(5, 0, src)
		smoke.start()
		return

	ex_act(severity)
		switch(severity)
			if (1.0)
				qdel(src)
				return
			if (2.0)
				if (prob(50))
					set_broken()
			if (3.0)
				if (prob(25))
					set_broken()
			else
		return

	blob_act(var/power)
		if (prob(power * 2.5))
			set_broken()
			density = 0

	proc
		set_broken()
			icon_state = base_icon_state
			icon_state += "b"
			stat |= BROKEN

		set_graphic_mode(var/new_mode = 0, mob/user as mob)
			if (!user || !user.client)
				return
			//boutput(world, "The new mode is: [new_mode].")
			if (graphic_mode)
				winset(user, "compx_\ref[src].screen","is-visible=false")
				//winset(user, "compx_\ref[src].conin","is-visible=true")
				//winset(user, "compx_\ref[src].grid","is-visible=false")
			else
				winset(user, "compx_\ref[src].screen","is-visible=true")
				//winset(user, "compx_\ref[src].conin","is-visible=false")
				//winset(user, "compx_\ref[src].grid","is-visible=true")

			graphic_mode = new_mode
			return

		run_program(computer/file/terminalx_program/program)
			if ((!program) || (!program.holder))
				return FALSE

			if (!(program.holder in src) && !(program.holder.loc in src) && hd)
		//		boutput(world, "Not in src")
				program = new program.type
				program.transfer_holder(hd)

			if (program.master != src)
				program.master = src

			if (!src.host_program && istype(program, /computer/file/terminalx_program/os))
				src.host_program = program

			if (!(program in processing_programs))
				processing_programs += program

			program.initialize()
			return TRUE

		//Stop processing a program (Unless it's the OS!!)
		unload_program(computer/file/terminalx_program/program)
			if (!program)
				return FALSE

			if (program == src.host_program)
				return FALSE

			processing_programs -= program
			return TRUE

		delete_file(computer/file/file)
			if ((!file) || (!file.holder) || (file.holder.read_only))
				return FALSE

			//Don't delete the OS you jerk
			if (src.host_program == file)
				return FALSE

			qdel(file)
			return TRUE

		send_command(command, computer/file/pfile, target_ref)
			var/result
			var/obj/item/peripheralx/P = locate(target_ref) in peripherals
			if (istype(P))
				result = P.receive_command(src, command, pfile)

			qdel(pfile)
			return result

		receive_command(obj/source, command, computer/file/pfile)
			if (source in contents)

				for (var/computer/file/terminalx_program/P in processing_programs)
					P.receive_command(src, command, pfile)
				qdel(pfile)

			return

		restart()
			if (restarting)
				return
			restarting = 1
			graphic_mode = 0
			src.override_temp = "Restarting..."
			updateUsrDialog()
			src.host_program = null

			spawn (20)
				//restarting = 0
				post_system()

			return

		post_system()
			src.override_temp = "Initializing system...<br>"

			if (!hd)
				override_temp += "<font color=red>1701 - NO FIXED DISK</font><br>"

			var/computer/file/terminalx_program/to_run = null

			if (src.host_program) //Let the starting programs set up vars or whatever
				src.host_program.initialize()

			else

				for (var/obj/item/peripheralx/drive/DR in peripherals)
					if (!DR.disk)
						continue

					var/computer/file/terminalx_program/os/newos = locate() in DR.disk.root.contents

					if (istype(newos))
						src.override_temp += "Booting from disk \[[DR.label]]...<br>"
						to_run = newos
						break

				if (!to_run && hd && hd.root)
					var/computer/file/terminalx_program/os/newos = locate(/computer/file/terminalx_program/os) in hd.root.contents

					if (newos && istype(newos))
						src.override_temp += "Booting from fixed disk...<br>"
						to_run = newos
					else
						override_temp += "<font color=red>Unable to boot from fixed disk.</font><br>"

			if (to_run)
				src.host_program = to_run
			else
				override_temp += "<font color=red>ERR - BOOT FAILURE</font><br>"

			updateUsrDialog()
			sleep(20)

			restarting = 0
			if (to_run)
				run_program(to_run)

			if (src.host_program)
				override_temp = null

			updateUsrDialog()

			return


/client/verb/compx_command(var/commandstring as text)
	set hidden = 1				// Hidden + no autocomplete
	set name = ".compcommand"

	//boutput(world, "compx command: \"[commandstring]\"")
	var/list/commands = splittext(commandstring,"%")
	if (commands.len < 2)
		return
	var/command = commands[2]
	var/obj/machinery/computerx/compx = locate(commands[1])
	if (istype(compx) && mob)
		usr = mob
		Topic(command, list("[command]"=1), compx)	// Topic redirection time!

	return

/client/verb/compx_console(var/compref as text, var/commandstring as text)
	set hidden = 1
	set name = ".compconsole"

	//boutput(world, "compx: \"[compref]\" command: \"[commandstring]\"")

	var/obj/machinery/computerx/compx = locate(compref)
	if (istype(compx) && mob)
		usr = mob

		Topic("conin", list("conin"=commandstring), compx)
	return