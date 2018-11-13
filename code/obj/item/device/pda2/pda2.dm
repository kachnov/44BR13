//The advanced pea-green monochrome lcd of tomorrow.

/obj/item/disk/data/cartridge
	name = "Cart 2.0"
	desc = "A data cartridge for portable microcomputers."
	icon = 'icons/obj/pda.dmi'
	icon_state = "cart"
	item_state = "electronic"
	file_amount = 32
	title = "ROM Cart"


/obj/item/device/pda2
	name = "PDA"
	desc = "A portable microcomputer by Thinktronic Systems, LTD. Functionality determined by an EEPROM cartridge."
	icon = 'icons/obj/pda.dmi'
	icon_state = "pda"
	item_state = "pda"
	w_class = 2.0
	rand_pos = 0
	flags = FPRINT | TABLEPASS | ONBELT
	module_research = list("science" = 1, "miniaturization" = 5, "devices" = 5, "efficiency" = 3)
	module_research_type = /obj/item/device/pda2
	var/obj/item/card/id/ID_card = null // slap an ID card into that thang
	var/registered = null // so we don't need to replace all the dang checks for ID cards
	var/assignment = null
	var/access = list()
	var/image/ID_image = null

	var/owner = null
	var/obj/item/disk/data/cartridge/cartridge = null //current cartridge
	var/computer/file/pda_program/active_program = null
	var/computer/file/pda_program/os/host_program = null
	var/computer/file/pda_program/scan/scan_program = null
	var/obj/item/disk/data/fixed_disk/hd = null
	var/closed = 1 //Can we insert a module now?
	var/obj/item/uplink/integrated/pda/uplink = null
	var/obj/item/device/pda_module/module = null
	var/frequency = 1149
	var/bot_freq = 1447 //Bot control frequency
	var/beacon_freq = 1445 //Beacon frequency for locating beacons (I love beacons)
	var/radio_frequency/radio_connection
	var/net_id = null //Hello dude intercepting our radio transmissions, here is a number that is not just \ref

	var/tmp/list/pdasay_autocomplete = list()

	var/bg_color = "6F7961"
	var/link_color = "000000"
	var/linkbg_color = "565D4B"
	var/graphic_mode = 0

	var/setup_default_cartridge = null //Cartridge contains job-specific programs
	var/setup_drive_size = 24 //PDAs don't have much work room at all, really.
	var/setup_system_os_path = /computer/file/pda_program/os/main_os //Needs an operating system to...operate!!
	var/setup_scanner_on = 1 //Do we search the cart for a scanprog to start loaded?
	var/setup_default_module = /obj/item/device/pda_module/flashlight //Module to have installed on spawn.
	var/mailgroup = "staff" //What special mail group the PDA is part of.
	var/bombproof = 0 // can't be destroyed with detomatix
	var/exploding = 0
/*
 *	Types of pda, for the different jobs and stuff
 */
/obj/item/device/pda2
	captain
		icon_state = "pda-c"
		setup_default_cartridge = /obj/item/disk/data/cartridge/captain
		setup_drive_size = 32
		mailgroup = "command"

	heads
		icon_state = "pda-h"
		setup_default_cartridge = /obj/item/disk/data/cartridge/head
		setup_drive_size = 32
		mailgroup = "command"

	hos
		icon_state = "pda-hos"
		setup_default_cartridge = /obj/item/disk/data/cartridge/hos
		setup_drive_size = 32
		mailgroup = "security" // should be merged with command

	ai
		icon_state = "pda-h"
		setup_default_cartridge = /obj/item/disk/data/cartridge/ai
		setup_drive_size = 1024
		bombproof = 1
		mailgroup = "silicon"

	cyborg
		icon_state = "pda-h"
		setup_default_cartridge = /obj/item/disk/data/cartridge/cyborg
		setup_drive_size = 1024
		bombproof = 1
		mailgroup = "silicon"

	research_director
		icon_state = "pda-rd"
		setup_default_cartridge = /obj/item/disk/data/cartridge/research_director
		setup_drive_size = 32
		mailgroup = "science" // merge with command

	medical_director
		icon_state = "pda-md"
		setup_default_cartridge = /obj/item/disk/data/cartridge/medical_director
		setup_drive_size = 32
		mailgroup = "medresearch" // merge with command

	medical
		icon_state = "pda-m"
		setup_default_cartridge = /obj/item/disk/data/cartridge/medical
		mailgroup = "medbay"

		robotics
			mailgroup = "medresearch"

	security
		icon_state = "pda-s"
		setup_default_cartridge = /obj/item/disk/data/cartridge/security
		mailgroup = "security"

	forensic
		icon_state = "pda-s"
		setup_default_cartridge = /obj/item/disk/data/cartridge/forensic
		mailgroup = "security"

	toxins
		icon_state = "pda-tox"
		setup_default_cartridge = /obj/item/disk/data/cartridge/toxins
		mailgroup = "science"

	genetics
		icon_state = "pda-gen"
		setup_default_cartridge = /obj/item/disk/data/cartridge/genetics
		mailgroup = "medresearch"

	quartermaster
		icon_state = "pda-q"
		setup_default_cartridge = /obj/item/disk/data/cartridge/quartermaster
		mailgroup = "cargo"

	clown
		icon_state = "pda-clown"
		desc = "A portable microcomputer by Thinktronic Systems, LTD. The surface is coated with polytetrafluoroethylene and banana drippings."
		setup_default_cartridge = /obj/item/disk/data/cartridge/clown

		HasEntered(AM as mob|obj) //Clown PDA is slippery.
			if (istype(loc, /turf/space))
				return
			if (iscarbon(AM))
				var/mob/M =	AM
				if (!M.can_slip(thing = src))
					return

				M.pulling = null
				boutput(M, "<span style=\"color:blue\">You slipped on the PDA!</span>")
				playsound(loc, "sound/misc/slip.ogg", 50, 1, -3)
				if (M.bioHolder.HasEffect("clumsy"))
					M.stunned = 8
					M.weakened = 5
				else
					M.weakened = 2

	janitor
		icon_state = "pda-j"
		setup_default_cartridge = /obj/item/disk/data/cartridge/janitor
		mailgroup = "janitor"

	chaplain
		icon_state = "pda-holy"
		mailgroup = "chaplain"

	atmos
		icon_state = "pda-a"
		setup_default_cartridge = /obj/item/disk/data/cartridge/atmos

	engine
		icon_state = "pda-e"
		mailgroup = "engineer"

	mining
		icon_state = "pda-e"
		mailgroup = "mining"

	chef
		mailgroup = "kitchen"

	barman
		mailgroup = "kitchen"

	mechanic
		icon_state = "pda-a"
		setup_default_module = /obj/item/device/pda_module/tray
		setup_default_cartridge = /obj/item/disk/data/cartridge/mechanic
		mailgroup = "mechanic"

	botanist
		icon_state = "pda-hydro"
		setup_default_cartridge = /obj/item/disk/data/cartridge/botanist
		mailgroup = "botany"

	syndicate
		icon_state = "pda-syn"
		name = "Military PDA"
		owner = "John Doe"
		setup_default_cartridge = /obj/item/disk/data/cartridge/nuclear
		setup_system_os_path = /computer/file/pda_program/os/main_os/mess_off

/obj/item/device/pda2/pickup(mob/user)
	if (module)
		module.relay_pickup(user)

/obj/item/device/pda2/dropped(mob/user)
	if (module)
		module.relay_drop(user)

/obj/item/device/pda2/New()
	..()
	if (!ID_image)
		ID_image = image(icon, "blank")

	spawn (5)
		hd = new /obj/item/disk/data/fixed_disk(src)
		hd.file_amount = setup_drive_size
		hd.name = "Minidrive"
		hd.title = "Minidrive"

		if (setup_system_os_path)
			src.host_program = new src.setup_system_os_path
			src.active_program = src.host_program

			src.hd.file_amount = max(src.hd.file_amount, src.host_program.size)

			src.host_program.transfer_holder(src.hd)

			hd.root.add_file(new /computer/file/text/pda2manual)
			hd.root.add_file(new /computer/file/pda_program/robustris)
			hd.root.add_file(new /computer/file/pda_program/emergency_alert)
			hd.root.add_file(new /computer/file/pda_program/cargo_request(src))

		net_id = format_net_id("\ref[src]")

		if (radio_controller)
			radio_controller.add_object(src, "[frequency]")

		if (setup_default_cartridge)
			cartridge = new setup_default_cartridge(src)

		if (setup_scanner_on && cartridge)
			var/computer/file/pda_program/scan/scan = locate() in cartridge.root.contents
			if (scan && istype(scan))
				scan_program = scan

		if (setup_default_module)
			module = new setup_default_module(src)

/obj/item/device/pda2/disposing()
	if (cartridge)
		cartridge.dispose()
		cartridge = null

	active_program = null
	src.host_program = null
	scan_program = null

	if (hd)
		hd.dispose()
		hd = null

	if (uplink)
		uplink.dispose()
		uplink = null

	if (module)
		module.dispose()
		module = null

	if (radio_connection)
		radio_connection.devices -= src
		radio_connection = null

	var/mob/living/ourHolder = loc
	if (istype(ourHolder))
		ourHolder.u_equip(src)


	..()

/obj/item/device/pda2/attack_self(mob/user as mob)
	user.machine = src

	var/wincheck = winexists(user, "pda2_\ref[src]")
	//boutput(world, wincheck)
	if (wincheck != "MAIN")
		winclone(user, "pda2", "pda2_\ref[src]")

	var/display_mode = graphic_mode
	if (!src.host_program || !owner)
		display_mode = 0

	if (display_mode)
		winset(user, "pda2_\ref[src].texto","is-visible=false")
		winset(user, "pda2_\ref[src].grido","is-visible=true")

		if (active_program)
			active_program.build_grid(user, "pda2_\ref[src].grido")
		else
			if (src.host_program)
				src.run_program(src.host_program)
				active_program.build_grid(user, "pda2_\ref[src].grido")


	else
		winset(user, "pda2_\ref[src].texto","is-visible=true")
		winset(user, "pda2_\ref[src].grido","is-visible=false")

		var/dat = {"<html><head>
		<style type="text/css">
		hr
		{
			color:#000;
			background-color:#000;
			height:2px;
			border-width:0;
		}
		body
		{
			background-color:#[bg_color]
		}

		a:link {background-color:#[linkbg_color];color:#[link_color];text-decoration:none}
		a:visited {background-color:#[linkbg_color];color:#[bg_color]}
		a:active {background-color:#[linkbg_color];color:#[bg_color]}
		a:hover {background-color:#[link_color];color:#[bg_color]}

		</style>
		</head>
		<body vlink='#[link_color]' alink='#[link_color]'>"}

		dat += "<a href='byond://?src=\ref[src];close=1'>Close</a>"

		if (!owner)
			if (cartridge)
				dat += " | <a href='byond://?src=\ref[src];eject_cart=1'>Eject [cartridge]</a>"
			if (ID_card)
				dat += " | <a href='byond://?src=\ref[src];eject_id_card=1'>Eject [ID_card]</a>"
			dat += "<br>Warning: No owner information entered.  Please swipe card.<br><br>"
			dat += "<a href='byond://?src=\ref[src];refresh=1'>Retry</a>"
		else
			if (active_program)
				dat += active_program.return_text()
			else
				if (src.host_program)
					src.run_program(src.host_program)
					dat += active_program.return_text()
				else
					if (cartridge)
						dat += " | <a href='byond://?src=\ref[src];eject_cart=1'>Eject [cartridge]</a><br>"
					if (ID_card)
						dat += " | <a href='byond://?src=\ref[src];eject_id_card=1'>Eject [ID_card]</a>"
					dat += "<center><font color=red>Fatal Error 0x17<br>"
					dat += "No System Software Loaded</font></center>"

		user << output(dat, "pda2_\ref[src].texto")


	winshow(user,"pda2_\ref[src]",1)

	onclose(user,"pda2_\ref[src]")
	return

/obj/item/device/pda2/Topic(href, href_list)
	..()

	if (usr.contents.Find(src) || usr.contents.Find(master) || (istype(loc, /turf) && get_dist(src, usr) <= 1))
		if (usr.stat || usr.restrained())
			return

		add_fingerprint(usr)
		usr.machine = src

		if (href_list["return_to_host"])
			if (src.host_program)
				src.active_program = src.host_program
				src.host_program = null

		else if (href_list["eject_cart"])
			eject_cartridge()

		else if (href_list["eject_id_card"])
			eject_id_card(usr ? usr : null)

		else if (href_list["refresh"])
			updateSelfDialog()

		else if (href_list["close"])
			usr << browse(null, "window=pda2_\ref[src]")
			usr.machine = null

		updateSelfDialog()
		return

/obj/item/device/pda2/attackby(obj/item/C as obj, mob/user as mob)
	if (istype(C, /obj/item/disk/data/cartridge) && isnull(cartridge))
		user.drop_item()
		C.set_loc(src)
		boutput(user, "<span style=\"color:blue\">You insert [C] into [src].</span>")
		cartridge = C
		updateSelfDialog()

	else if (istype(C, /obj/item/device/pda_module))
		if (closed)
			boutput(user, "<span style=\"color:red\">The casing is closed!</span>")
			return

		if (module)
			boutput(user, "<span style=\"color:red\">There is already a module installed!</span>")
			return

		user.drop_item()
		C.set_loc(src)
		module = C
		C:install(src)
		updateSelfDialog()
		return

	else if (istype(C, /obj/item/screwdriver))
		playsound(user.loc, "sound/items/Screwdriver.ogg", 50, 1)
		closed = !closed
		boutput(user, "You [closed ? "secure" : "unscrew"] the cover.")

	else if (istype(C, /obj/item/crowbar))
		if (!module)
			return

		if (closed)
			boutput(user, "<span style=\"color:red\">The casing is closed!</span>")
			return

		module.set_loc(get_turf(src))
		module.uninstall()
		module = null
		boutput(user, "You pry the module out.")
		updateSelfDialog()

	else if (istype(C, /obj/item/card/id))
		var/obj/item/card/id/ID = C
		if (!ID.registered)
			boutput(user, "<span style=\"color:red\">This ID isn't registered to anyone!</span>")
			return
		if (!owner)
			owner = ID.registered
			name = "PDA-[owner]"
			boutput(user, "<span style=\"color:blue\">Card scanned.</span>")
			updateSelfDialog()
		else
			if (ID_card)
				boutput(user, "<span style=\"color:blue\">You swap [ID] and [ID_card].</span>")
				eject_id_card(user)
				insert_id_card(ID, user)
				return
			else if (!ID_card)
				insert_id_card(ID, user)
				boutput(user, "<span style=\"color:blue\">You insert [ID] into [src].</span>")

/obj/item/device/pda2/examine()
	..()
	boutput(usr, "The back cover is [closed ? "closed" : "open"].")
	if (ID_card)
		boutput(usr, "[ID_card] has been inserted into it.")
	return

/obj/item/device/pda2/receive_signal(signal/signal, rx_method, rx_freq)
	if (!signal || signal.encryption || !owner) return

	if (src.host_program)
		src.host_program.network_hook(signal, rx_method, rx_freq)

	if (src.active_program && (src.active_program != src.host_program))
		active_program.network_hook(signal, rx_method, rx_freq)


	if (signal.data["address_1"] && signal.data["address_1"] != net_id)

		// special programs can receive all signals
		if ((signal.data["address_1"] == "ping") && signal.data["sender"])
			var/signal/pingreply = new
			pingreply.source = src
			pingreply.data["device"] = "NET_PDA_51XX"
			pingreply.data["netid"] = net_id
			pingreply.data["address_1"] = signal.data["sender"]
			pingreply.data["command"] = "ping_reply"
			pingreply.data["data"] = owner
			spawn (5)
				post_signal(pingreply)

			return

		else if (!mailgroup || (signal.data["group"] != mailgroup))
			return

	if (src.host_program)
		src.host_program.receive_signal(signal, rx_method, rx_freq)

	if (src.active_program && (src.active_program != src.host_program))
		active_program.receive_signal(signal, rx_method, rx_freq)

	return

/obj/item/device/pda2/attack(mob/M as mob, mob/user as mob)
	if (scan_program)
		return
	else
		..()

/obj/item/device/pda2/afterattack(atom/A as mob|obj|turf|area, mob/user as mob)
	var/scan_dat = null
	if (scan_program && istype(scan_program))
		scan_dat = scan_program.scan_atom(A)
	else
		scan_dat = scan_atmospheric(A) // Replaced with global proc (Convair880).

	if (scan_dat)
		A.visible_message("<span style=\"color:red\">[user] has scanned [A]!</span>")
		user.show_message(scan_dat, 1)

	return

/obj/item/device/pda2/process()
	if (active_program)
		active_program.process()

	else
		if (src.host_program && src.host_program.holder && (src.host_program.holder in src.master.contents))
			src.run_program(src.host_program)
		else
			processing_items.Remove(src)

	return

/obj/item/device/pda2/MouseDrop(atom/over_object, src_location, over_location)
	..()
	if (over_object == usr && loc == usr && isliving(usr) && !usr.stat)
		attack_self(usr)

/obj/item/device/pda2/verb/pdasay(var/target in pdasay_autocomplete, var/message as text)
	set name = "PDAsay"
	set desc = "Send a PDA message to somebody (You may need to scan for other PDAs first)."
	set src in usr

	if (!target || !message)
		return

	if (usr:paralysis || usr:stunned || usr:weakened || usr:stat)
		return

	if (istype(src.host_program))
		src.host_program.pda_message(pdasay_autocomplete[target], target, message)

/obj/item/device/pda2

	proc/post_signal(signal/signal,var/newfreq)
		spawn (0)
			if (!signal)
				return
			var/freq = newfreq
			if (!freq)
				freq = frequency

			signal.source = src
			signal.data["sender"] = net_id

			var/radio_frequency/frequency2 = radio_controller.return_frequency("[freq]")

			signal.transmission_method = TRANSMISSION_RADIO
			if (frequency2)
				return frequency2.post_signal(src, signal)
			//else
				//qdel(signal)

	proc/eject_cartridge()
		if (cartridge)
			var/turf/T = get_turf(src)

			if (active_program && (active_program.holder == cartridge))
				active_program = null

			if (src.host_program && (src.host_program.holder == src.cartridge))
				src.host_program = null

			if (scan_program && (scan_program.holder == cartridge))
				scan_program = null

			cartridge.set_loc(T)
			cartridge = null

		return

	proc/eject_id_card(var/mob/user as mob)
		if (ID_card)
			registered = null
			assignment = null
			access = null
			underlays -= ID_image
			if (istype(user))
				user.put_in_hand_or_drop(ID_card)
			else
				var/turf/T = get_turf(src)
				ID_card.set_loc(T)
			ID_card = null
			return

	proc/insert_id_card(var/obj/item/card/id/ID as obj, var/mob/user as mob)
		if (!istype(ID))
			return
		if (ID_card)
			eject_id_card(istype(user) ? user : null)
		ID_card = ID
		if (user)
			user.u_equip(ID)
		ID.set_loc(src)
		registered = ID.registered
		assignment = ID.assignment
		access = ID.access
		ID_image = ID_card.icon_state
		underlays += ID_image
		updateSelfDialog()
/*
	//Toggle the built-in flashlight
	toggle_light()
		fon = (!fon)

		if (ismob(loc))
			if (fon)
				loc.sd_SetLuminosity(loc.luminosity + f_lum)
			else
				loc.sd_SetLuminosity(loc.luminosity - f_lum)
		else
			sd_SetLuminosity(fon * f_lum)

		updateSelfDialog()
*/
	proc/display_alert(var/alert_message) //Add alert overlay and beep
		if (alert_message)
			playsound(get_turf(src), "sound/machines/twobeep.ogg", 50, 1)
			for (var/mob/O in hearers(3, loc))
				O.show_message(text("[bicon(src)] *[alert_message]*"))

		overlays = null
		overlays += image('icons/obj/pda.dmi', "pda-r")
		return

	proc/run_program(computer/file/pda_program/program)
		if ((!program) || (!program.holder))
			return FALSE

		if (!(program.holder in src))
	//		boutput(world, "Not in src")
			program = new program.type
			program.transfer_holder(hd)

		if (program.master != src)
			program.master = src

		if (!src.host_program && istype(program, /computer/file/pda_program/os))
			src.host_program = program

		if (istype(program, /computer/file/pda_program/scan))
			if (program == scan_program)
				scan_program = null
			else
				scan_program = program
			return TRUE

		active_program = program
		program.init()

		if (program.setup_use_process && !(src in processing_items))
			processing_items.Add(src)

		return TRUE

	proc/unload_active_program()
		if (src.active_program == src.host_program)
			return TRUE

		if (src.active_program.setup_use_process && !src.host_program.setup_use_process)
			processing_items.Remove(src)

		if (src.host_program && src.host_program.holder && (src.host_program.holder in src.contents))
			src.run_program(src.host_program)
		else
			active_program = null

		updateSelfDialog()
		return TRUE

	proc/delete_file(computer/file/theFile)
		//boutput(world, "Deleting [file]...")
		if ((!theFile) || (!theFile.holder) || (theFile.holder.read_only))
			//boutput(world, "Cannot delete :(")
			return FALSE

		//Don't delete the running program you jerk
		if (src.active_program == theFile || src.host_program == theFile)
			active_program = null

		//boutput(world, "Now calling del on [file]...")
		//qdel(file)
		theFile.dispose()
		return TRUE

	proc/explode()
		if (bombproof)
			if (ismob(loc))
				boutput(loc, "<span style=\"color:red\"><strong>ALERT:</strong> An attempt to run malicious explosive code on your PDA has been blocked.</span>")
			return

		if (src in bible_contents)
			for (var/obj/item/storage/bible/B in world)
				var/turf/T = get_turf(B.loc)
				if (T)
					T.hotspot_expose(700,125)
					explosion(src, T, -1, -1, 2, 3)
			bible_contents.Remove(src)
			//dispose()
			//dispose()
			qdel(src)
			return

		var/turf/T = get_turf(loc)

		if (ismob(loc))
			var/mob/M = loc
			M.show_message("<span style=\"color:red\">Your [src] explodes!</span>", 1)

		if (T)
			T.hotspot_expose(700,125)

			explosion(src, T, -1, -1, 2, 3)

		//dispose()
		//dispose()
		qdel(src)
		return


/*
 *	PDA 2 ~help file~
 */

/computer/file/text/pda2manual
	name = "Readme"

	data = {"
Thinktronic 5150 Personal Data Assistant Manual<br>
Operating System: ThinkOS 7<hr>
ThinkOS 7 comes with several useful applications built in, these include:<br>
<em><ul>
<li>Notetaker: Load, edit, and save text files just like this one!</li>
<li>Messenger: Send messages between all enabled PDAs.  Can also send the current file in the clipboard.</li>
<li>File Browser: Manage and execute programs in the internal drive or loaded cartridge.</li>
<li>Atmos Scanner: Using patented AirScan technology.</li>
<li>Modules: Light up your life with a flashlight, or see right through the floor with a T-Scanner! The choice is yours!</li>
</ul></em>
<strong>To send a file with the messenger:</strong><br>
Enter the file browser and copy the file you want to send.  Now enter the messenger and select *send file*.<br>
<br>
ThinkOS 7 supports a wide variety of software solutions, ranging from robot interface systems to forensic and medical scanners.<br>
<font size=1>This technology produced by Thinktronic Systems, LTD for the NanoTrasen Corporation</font>
"}
