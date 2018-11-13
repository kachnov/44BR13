//CONTENTS:
//Base computerx program datum
//Compx_icon object (Used for GUI system)
//Compxwindow datum (Used for GUI system)


/computer/file/terminalx_program
	name = "program"
	extension = "TPROG"
	var/obj/machinery/computerx/master = null
	var/list/req_access = list()
	var/executable = 1
	var/gui_app = 0
	var/compx_window/temp = null
	var/initialized = 0
	var/list/gui_icons = list()
	var/meta_params = null


	os
		name = "system program"
		extension = "TSYS"
		executable = 0
		var/tmp/setup_string = null

		os_call(var/call_params, var/computer/file/terminal_program/caller, var/computer/file/file)
			if (!master || master.stat & (NOPOWER|BROKEN))
				return TRUE
			if (!caller || !call_params)
				return TRUE

			return FALSE

	New(obj/holding as obj)
		..()
		if (holding)
			holder = holding

			if (istype(holder.loc,/obj/machinery/computerx))
				master = holder.loc

		if (meta_params)
			metadata += params2list(meta_params)

	Del()
		if (master)
			master.processing_programs.Remove(src)
		..()

	Topic(href, href_list)
		if ((!holder) || (!master))
			return TRUE

		if ((!istype(holder)) || (!istype(master)))
			return TRUE

		if (master.stat & (NOPOWER|BROKEN))
			return TRUE

		if ((!usr.contents.Find(master) && (!in_range(master, usr) || !istype(master.loc, /turf))) && (!istype(usr, /mob/living/silicon)))
			return TRUE

		if (!(holder in master.contents) && !(holder.loc in master.contents))
			return TRUE

		usr.machine = master

		return FALSE

	proc
		os_call(var/call_params, var/computer/file/file)
			if (!master || !master.host_program)
				return FALSE

			master.host_program.os_call(call_params, src, file)
			return TRUE

		initialize() //Called when a program starts running.
			if (initialized || !master)
				return TRUE
			return FALSE

		quit()
			if (master)
				master.unload_program(src)
			return

		input_text(var/text, source=0)
			if ((!holder) || (!master) || !text)
				return TRUE

			if ((!istype(holder)) || (!istype(master)))
				return TRUE

			if (master.stat & (NOPOWER|BROKEN))
				return TRUE

			if (!(holder in master.contents) && !(holder.loc in master.contents))
				return TRUE

			if (!holder.root)
				holder.root = new /computer/folder
				src.holder.root.holder = src
				holder.root.name = "root"

			//boutput(world, text)
			return FALSE

		process()
			if ((!holder) || (!master))
				return TRUE

			if ((!istype(holder)) || (!istype(master)))
				return TRUE

			if (!(holder in master.contents) && !(holder.loc in master.contents))
				if (master.host_program == src)
					master.host_program = null
				master.processing_programs.Remove(src)
				return TRUE

			if (!holder.root)
				holder.root = new /computer/folder
				src.holder.root.holder = src
				holder.root.name = "root"

			return FALSE

		receive_command(obj/source, command, computer/file/pfile)
			if ((!holder) || (!master) || (!source) || (source != master))
				return TRUE

			if ((!istype(holder)) || (!istype(master)))
				return TRUE

			if (master.stat & (NOPOWER|BROKEN))
				return TRUE

			if (!(holder in master.contents) && !(holder.loc in master.contents))
				return TRUE

			return FALSE

		peripheral_command(command, computer/file/pfile, target_ref)
			if (master)
				return master.send_command(command, pfile, target_ref)
			else
				qdel(pfile)

			return null

		transfer_holder(obj/item/disk/data/newholder,computer/folder/newfolder)

			if ((newholder.file_used + size) > newholder.file_amount)
				return FALSE

			if (!newholder.root)
				newholder.root = new /computer/folder
				newholder.root.holder = newholder
				newholder.root.name = "root"

			if (!newfolder)
				newfolder = newholder.root

			if ((src.holder && src.holder.read_only) || newholder.read_only)
				return FALSE

			if ((holder) && (holder.root))
				holder.root.remove_file(src)

			newfolder.add_file(src)

			if (istype(newholder.loc,/obj/machinery/computerx))
				master = newholder.loc
			else if (istype(newholder.loc, /obj/item/peripheralx/drive))
				var/obj/item/peripheralx/dx = newholder.loc
				if (dx.host)
					master = dx.host

			//boutput(world, "Setting [holder] to [newholder]")
			holder = newholder
			return TRUE

		disk_inserted(var/obj/item/disk/data/inserted)
			return

		disk_ejected(var/obj/item/disk/data/ejected)
			if (holder == ejected)
				quit()

			return

		get_temp()
			return temp



//This should be used for fancy grid GUI magics!!
/obj/compx_icon
	name = "Icon"
	icon = 'icons/misc/compgui.dmi'
	icon_state = "x"
	var/action_tag = "none" //When clicked, send actiontag = actionarg to our owning program's Topic().
	var/action_arg = 1
	var/computer/file/terminalx_program/owner = null
	var/icon_id = null
	var/grid_x = 0
	var/grid_y = 0
	var/no_drag = 0

	debug
		name = "Finder"
		icon_state = "folder"
		action_tag = "boop"
		action_arg = "beep"

	spacer
		name = ""
		icon_state = null

	New(var/computer/file/terminalx_program/new_owner)
		..()
		if (istype(new_owner))
			owner = new_owner
		icon_id = "G[generate_net_id(src)]"
		return

	Click()
		if (!istype(owner) || !usr)
			return

		usr.Topic("[action_tag]=[action_arg];gid=[icon_id]", list("[action_tag]"="[action_arg]","gid"=icon_id), owner)	// Topic redirection time!
		return

	MouseDrop(obj/O, null, var/src_location, var/control_orig, var/control_new, var/params)
		if (!istype(owner) || !usr || no_drag)
			return

		if (control_orig != control_new) //Dragging icons into the real world/another computer desktop would be weird.
			return

		//boutput(world, "loc: [src_location]<br>co: [control_orig]<br>cn: [control_new]<br>usr: [usr]")
		usr.Topic("drag=[src_location];gid=[icon_id]", list("drag"=src_location,"gid"=icon_id), owner)	// More Topic redirection.
		return

/compx_window
	var/skinbase = "cxwind_console"
	var/computer/file/terminalx_program/owner = null

	New(var/computer/file/terminalx_program/newOwner)
		..()

		if (istype(newOwner))
			owner = newOwner


	grid
		skinbase = "cxwind_grid"

		var/list/gridList = list()

		update(mob/user as mob)
			if (..())
				return

			for (var/gridy = 1, gridy <= compx_gridy_max, gridy++)
				for (var/gridx = 1, gridx <= compx_gridx_max, gridx++)
					if (isnull(gridList[gridx][gridy]))
						user << output(compx_grid_spacer, "compxwindow_\ref[src].grid:[gridx],[gridy]")
					else
						user << output(gridList[gridx][gridy], "compxwindow_\ref[src].grid:[gridx],[gridy]")

			return

	proc/update(mob/user as mob)
		if (!istype(user) || !user.client || !owner)
			return TRUE

		return FALSE