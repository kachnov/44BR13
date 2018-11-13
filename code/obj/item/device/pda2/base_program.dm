
//base pda program

/computer/file/pda_program
	name = "blank program"
	extension = "PPROG"
	var/obj/item/device/pda2/master = null
	var/id_tag = null
	var/setup_use_process = 0 //Does the master PDA need to be on the processing item list?

	os
		name = "blank system program"
		extension = "PSYS"

	scan
		name = "blank scan program"
		extension = "PSCAN"

	New(obj/holding as obj)
		if (holding)
			holder = holding

			if (istype(holder.loc,/obj/item/device/pda2))
				master = holder.loc

	proc
		return_text()
			if ((!holder) || (!master))
				return TRUE

			if ((!istype(holder)) || (!istype(master)))
				return TRUE

			if (!(holder in master.contents))
				//boutput(world, "Holder [holder] not in [master] of prg:[src]")
				if (master.active_program == src)
					master.active_program = null
				return TRUE

			return FALSE

		build_grid(mob/user as mob, theGrid)
			if (!istype(holder) || !istype(master))
				return TRUE

			if (!user || !theGrid)
				return TRUE

			if (!(holder in master.contents))
				return TRUE

			return FALSE

		process()
			if ((!holder) || (!master))
				return TRUE

			if ((!istype(holder)) || (!istype(master)))
				return TRUE

			if (!(holder in master.contents))
				if (master.active_program == src)
					master.active_program = null
				return TRUE

			if (!holder.root)
				holder.root = new /computer/folder
				src.holder.root.holder = src
				holder.root.name = "root"

			return FALSE

		//maybe remove this, I haven't found a good use for it yet
		send_os_command(list/command_list)
			if (!master || !holder || master.host_program || !command_list)
				return TRUE

			if (!istype(master.host_program) || master.host_program == src)
				return TRUE

			master.host_program.receive_os_command()

			return FALSE

		return_text_header()
			if (!master || !holder)
				return

			. = " | <a href='byond://?src=\ref[src];quit=1'>Main Menu</a>"
			. += " | <a href='byond://?src=\ref[master];refresh=1'>Refresh</a>"


		post_signal(signal/signal, newfreq)
			if (master)
				master.post_signal(signal, newfreq)
			//else
				//qdel(signal)

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

			if (istype(newholder.loc,/obj/item/device/pda2))
				master = newholder.loc

			//boutput(world, "Setting [holder] to [newholder]")
			holder = newholder
			return TRUE


		receive_signal(signal/signal, rx_method, rx_freq)
			if ((!holder) || (!master))
				return TRUE

			if ((!istype(holder)) || (!istype(master)))
				return TRUE

			if (!(holder in master.contents))
				if (master.active_program == src)
					master.active_program = null
				return TRUE

			return FALSE

		// called when a program is run
		init()
			return

		// to allow promiscuous mode
		network_hook()
			return


	Topic(href, href_list)
		if ((!holder) || (!master))
			return TRUE

		if ((!istype(holder)) || (!istype(master)))
			return TRUE

		if (master.active_program != src)
			return TRUE

		if ((!usr.contents.Find(master) && (!in_range(master, usr) || !istype(master.loc, /turf))) && (!istype(usr, /mob/living/silicon)))
			return TRUE

		if (usr.stat || usr.restrained())
			return TRUE

		if (!(holder in master.contents))
			if (master.active_program == src)
				master.active_program = null
			return TRUE

		usr.machine = master

		if (href_list["close"])
			usr.machine = null
			usr << browse(null, "window=pda2_\ref[src]")
			return FALSE

		if (href_list["quit"])
//			master.processing_programs.Remove(src)
			master.unload_active_program()
			return TRUE

		return FALSE