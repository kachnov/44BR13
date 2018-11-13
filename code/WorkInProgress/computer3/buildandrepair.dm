//Motherboard is just used in assembly/disassembly, doesn't exist in the actual computer object.
/obj/item/motherboard
	name = "Computer mainboard"
	desc = "A computer motherboard."
	icon = 'icons/obj/module.dmi'
	inhand_image_icon = 'icons/mob/inhand/hand_tools.dmi'
	icon_state = "mainboard"
	item_state = "electronic"
	w_class = 2.0
	var/created_name = null //If defined, result computer will have this name.
	var/integrated_floppy = 1 //Does the resulting computer have a built-in disk drive?
	mats = 8

/obj/computer3frame
	density = 1
	anchored = 0
	name = "Computer-frame"
	icon = 'icons/obj/computer_frame.dmi'
	icon_state = "0"
	var/state = 0
	var/obj/item/motherboard/mainboard = null
	var/obj/item/disk/data/fixed_disk/hd = null
	var/max_peripherals = 3
	var/list/peripherals = list()
	var/created_icon_state = "computer_generic"
	var/glass_needed = 2 //How much glass does this need for a screen?
	var/metal_given = 5 //How much metal does this give when destroyed?

	terminal //Light frame
		name = "Terminal-frame"
		desc = "A light micro-computer frame used for terminal systems."
		icon = 'icons/obj/terminal_frame.dmi'
		created_icon_state = "dterm"
		max_peripherals = 2
		metal_given = 3
		glass_needed = 1

	desktop //Those old desktop computers
		name = "Desktop Computer-frame"
		icon = 'icons/obj/computer_frame_desk.dmi'
		created_icon_state = "old"
		max_peripherals = 3
		metal_given = 3
		glass_needed = 1

	blob_act(var/power)
		if (prob(power * 2.5))
			qdel(src)

/obj/computer3frame/meteorhit(obj/O as obj)
	qdel(src)

/obj/computer3frame/attackby(obj/item/P as obj, mob/user as mob)
	switch(state)
		if (0)
			if (istype(P, /obj/item/wrench))
				playsound(loc, "sound/items/Ratchet.ogg", 50, 1)
				if (do_after(user, 20))
					boutput(user, "<span style=\"color:blue\">You wrench the frame into place.</span>")
					anchored = 1
					state = 1
			if (istype(P, /obj/item/weldingtool))
				playsound(loc, "sound/items/Welder.ogg", 50, 1)
				if (do_after(user, 20))
					boutput(user, "<span style=\"color:blue\">You deconstruct the frame.</span>")
					var/obj/item/sheet/A = new /obj/item/sheet( loc )
					if (material)
						A.setMaterial(material)
					else
						var/material/M = getCachedMaterial("steel")
						A.setMaterial(M)
					A.amount = metal_given
					qdel(src)
		if (1)
			if (istype(P, /obj/item/wrench))
				playsound(loc, "sound/items/Ratchet.ogg", 50, 1)
				if (do_after(user, 20))
					boutput(user, "<span style=\"color:blue\">You unfasten the frame.</span>")
					anchored = 0
					state = 0
			if (istype(P, /obj/item/motherboard) && !mainboard)
				playsound(loc, "sound/items/Deconstruct.ogg", 50, 1)
				boutput(user, "<span style=\"color:blue\">You place the mainboard inside the frame.</span>")
				icon_state = "1"
				mainboard = P
				user.drop_item()
				P.set_loc(src)
			if (istype(P, /obj/item/screwdriver) && mainboard)
				playsound(loc, "sound/items/Screwdriver.ogg", 50, 1)
				boutput(user, "<span style=\"color:blue\">You screw the mainboard into place.</span>")
				state = 2
				icon_state = "2"
			if (istype(P, /obj/item/crowbar) && mainboard)
				playsound(loc, "sound/items/Crowbar.ogg", 50, 1)
				boutput(user, "<span style=\"color:blue\">You remove the mainboard.</span>")
				state = 1
				icon_state = "0"
				mainboard.set_loc(loc)
				mainboard = null
			if (istype(P, /obj/item/circuitboard))
				boutput(user, "<span style=\"color:red\">This is the wrong type of frame, it won't fit!</span>")

		if (2)
			if (istype(P, /obj/item/screwdriver) && mainboard && (!peripherals.len))
				playsound(loc, "sound/items/Screwdriver.ogg", 50, 1)
				boutput(user, "<span style=\"color:blue\">You unfasten the mainboard.</span>")
				state = 1
				icon_state = "1"

			if (istype(P, /obj/item/peripheral))
				if (src.peripherals.len < src.max_peripherals)
					user.drop_item()
					peripherals.Add(P)
					P.set_loc(src)
					boutput(user, "<span style=\"color:blue\">You add [P] to the frame.</span>")
				else
					boutput(user, "<span style=\"color:red\">There is no more room for peripheral cards.</span>")

			if (istype(P, /obj/item/crowbar) && peripherals.len)
				playsound(loc, "sound/items/Crowbar.ogg", 50, 1)
				boutput(user, "<span style=\"color:blue\">You remove the peripheral boards.</span>")
				for (var/obj/item/peripheral/W in peripherals)
					W.set_loc(loc)
					peripherals.Remove(W)
					W.uninstalled()

			if (istype(P, /obj/item/cable_coil))
				if (P:amount >= 5)
					playsound(loc, "sound/items/Deconstruct.ogg", 50, 1)
					if (do_after(user, 20))
						if (!P) //Wire: Fix for Cannot read null.amount
							return
						P:amount -= 5
						if (!P:amount) qdel(P)
						boutput(user, "<span style=\"color:blue\">You add cables to the frame.</span>")
						state = 3
						icon_state = "3"
		if (3)
			if (istype(P, /obj/item/wirecutters))
				playsound(loc, "sound/items/Wirecutter.ogg", 50, 1)
				boutput(user, "<span style=\"color:blue\">You remove the cables.</span>")
				state = 2
				icon_state = "2"
				var/obj/item/cable_coil/A = new /obj/item/cable_coil( loc )
				A.amount = 5
				if (hd)
					hd.set_loc(loc)
					hd = null

			if (istype(P, /obj/item/disk/data/fixed_disk) && !hd)
				user.drop_item()
				hd = P
				P.set_loc(src)
				boutput(user, "<span style=\"color:blue\">You connect the drive to the cabling.</span>")

			if (istype(P, /obj/item/crowbar) && hd)
				playsound(loc, "sound/items/Crowbar.ogg", 50, 1)
				boutput(user, "<span style=\"color:blue\">You remove the hard drive.</span>")
				hd.set_loc(loc)
				hd = null

			if (istype(P, /obj/item/sheet))
				var/obj/item/sheet/S = P
				if (S.material && S.material.material_flags & MATERIAL_CRYSTAL)
					if (S.amount >= glass_needed)
						playsound(loc, "sound/items/Deconstruct.ogg", 50, 1)
						if (do_after(user, 20) && S)
							S.amount -= glass_needed
							if (S.amount < 1)
								qdel(S)
							boutput(user, "<span style=\"color:blue\">You put in the glass panel.</span>")
							state = 4
							icon_state = "4"
					else
						boutput(user, "<span style=\"color:red\">There's not enough sheets on the stack.</span>")
				else
					boutput(user, "<span style=\"color:red\">You need sheets of some kind of crystal or glass for this.</span>")
		if (4)
			if (istype(P, /obj/item/crowbar))
				playsound(loc, "sound/items/Crowbar.ogg", 50, 1)
				boutput(user, "<span style=\"color:blue\">You remove the glass panel.</span>")
				state = 3
				icon_state = "3"
				var/obj/item/sheet/glass/A = new /obj/item/sheet/glass(loc)
				A.amount = glass_needed

			if (istype(P, /obj/item/screwdriver))
				playsound(loc, "sound/items/Screwdriver.ogg", 50, 1)
				boutput(user, "<span style=\"color:blue\">You connect the monitor.</span>")
				var/obj/machinery/computer3/C= new /obj/machinery/computer3( loc )
				if (material) C.setMaterial(material)
				C.setup_drive_size = 0
				C.icon_state = created_icon_state
				C.setup_frame_type = type
				if (mainboard.created_name) C.name = mainboard.created_name
				if (mainboard.integrated_floppy) C.setup_has_internal_disk = 1
				//qdel(mainboard)
				mainboard.dispose()
				if (hd)
					C.hd = hd
					hd.set_loc(C)
				for (var/obj/item/peripheral/W in peripherals)
					W.set_loc(C)
					W.installed(C) //Set C as their host, etc
				//dispose()
				dispose()