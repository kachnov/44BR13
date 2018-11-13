// Overhauled the generator to incorporate APC.cell charging.
// It used to in the past, but that feature was reverted for reasons unknown.
// However, it's not a C&P job of the old code (Convair880).
/obj/machinery/power/lgenerator
	name = "Experimental Local Generator"
	desc = "This machine generates power through the combustion of plasma, charging either the local APC or an inserted power cell."
	icon_state = "ggenoff"
	anchored = 0
	density = 1
	layer = FLOOR_EQUIP_LAYER1
	mats = 10
	var/mode = 1 // 1 = charge APC, 2 = charge inserted power cell.
	var/active = 0

	// If either of these values aren't competitive, nobody will bother with the generator.
	// Remember, there's quite a bit of hassle involved when buying (i.e. QM) and using one of these.
	// And you can't even fully recharge a 15000 cell with these parameters and stock plasma tank.
	var/CL_charge_rate = 100 // Units per tick. Comparison: ~20 (APC), 250 (regular cell charger).
	var/P_drain_rate = 0.08 // Per tick. Stock (304 kPa) tank will last about 6 min when charging non-stop.

	var/obj/item/cell/CL = null
	var/obj/item/tank/P = null
	var/obj/machinery/power/apc/our_APC = null // Linked APC if mode == 1.
	var/last_APC_check = 1 // In relation to world time. Ideally, we don't want to run this every tick.
	var/light/light

	New()
		..()
		light = new /light/point
		light.attach(src)
		light.set_brightness(0.8)

	attackby(obj/item/W, mob/user)
		if (istype(W, /obj/item/tank))
			if (P)
				user.show_text("There appears to be a tank loaded already.", "red")
				return
			if (check_tank(W) == 0)
				user.show_text("The tank doesn't contain any plasma.", "red")
				return
			visible_message("<span style=\"color:blue\">[user] loads [W] into the [src].</span>")
			user.u_equip(W)
			W.set_loc(src)
			P = W

		else if (istype(W, /obj/item/cell))
			if (CL)
				user.show_text("There appears to be a power cell inserted already.", "red")
				return
			visible_message("<span style=\"color:blue\">[user] loads [W] into the [src].</span>")
			user.u_equip(W)
			W.set_loc(src)
			CL = W

		else
			..()

		if (user.machine == src) updateUsrDialog()
		return

	proc/update_icon()
		if (active)
			icon_state = "ggen"
			light.enable()
		else
			icon_state = "ggenoff"
			light.disable()
		return

	proc/APC_check()
		if (!src)
			return FALSE

		var/area/A = get_area(src)
		if (!A || !A.requires_power)
			return FALSE

		var/obj/machinery/power/apc/AC = get_local_apc(src)
		if (!AC)
			return FALSE
		if (AC && !AC.cell)
			return 2
		return TRUE

	proc/check_tank(var/obj/item/tank/T)
		if (!src || !T || !T.air_contents)
			return FALSE
		if (T.air_contents.toxins <= 0)
			return FALSE
		return TRUE

	proc/eject_tank()
		if (!src)
			return
		if (P)
			P.set_loc(get_turf(src))
			P = null
			active = 0
			update_icon()
		return

	proc/eject_cell()
		if (!src)
			return
		if (CL)
			CL.set_loc(get_turf(src))
			CL = null
			if (mode == 2) // Generator doesn't need to shut down when in APC mode.
				active = 0
			update_icon()
		return

	process()
		if (!src)
			return

		if (active)
			if (!anchored)
				visible_message("<span style=\"color:red\">[src]'s retention bolts fail, triggering an emergency shutdown!</span>")
				playsound(loc, "sound/machines/buzz-two.ogg", 100, 0)
				active = 0
				update_icon()
				updateDialog()
				return

			if (!istype(loc, /turf/simulated/floor))
				visible_message("<span style=\"color:red\">[src]'s retention bolts fail, triggering an emergency shutdown!</span>")
				playsound(loc, "sound/machines/buzz-two.ogg", 100, 0)
				anchored = 0 // It might have happened, I guess?
				active = 0
				update_icon()
				updateDialog()
				return

			if (check_tank(P) == 0)
				visible_message("<span style=\"color:red\">[src] runs out of fuel and shuts down! [P] is ejected!</span>")
				playsound(loc, "sound/machines/buzz-two.ogg", 100, 0)
				eject_tank()
				updateDialog()
				return

			switch (mode)
				if (1)
					if (!our_APC)
						visible_message("<span style=\"color:red\">[src] doesn't detect a local APC and shuts down!</span>")
						playsound(loc, "sound/machines/buzz-two.ogg", 100, 0)
						active = 0
						our_APC = null
						update_icon()
						updateDialog()
						return
					if (last_APC_check && world.time > last_APC_check + 50)
						if (APC_check() != 1)
							visible_message("<span style=\"color:red\">[src] can't charge the local APC and shuts down!</span>")
							playsound(loc, "sound/machines/buzz-two.ogg", 100, 0)
							active = 0
							our_APC = null
							update_icon()
							updateDialog()
							last_APC_check = world.time
							return

					var/obj/item/cell/APC_cell = our_APC.cell
					if (APC_cell) // Because we don't run the check every tick.
						if (APC_cell.charge < 0)
							APC_cell.charge = 0
						if (APC_cell.charge > APC_cell.maxcharge)
							APC_cell.charge = APC_cell.maxcharge

						// Don't combust plasma if we don't have to.
						if (APC_cell.charge < APC_cell.maxcharge)
							APC_cell.give(CL_charge_rate)
							src.P.air_contents.toxins = max(0, (P.air_contents.toxins - src.P_drain_rate))
							// Call proc to trigger rigged cell and log entries.

				if (2)
					if (!CL)
						visible_message("<span style=\"color:red\">[src] doesn't have a cell to charge and shuts down!</span>")
						playsound(loc, "sound/machines/buzz-two.ogg", 100, 0)
						active = 0
						CL = null
						update_icon()
						updateDialog()
						return

					if (CL.charge < 0)
						CL.charge = 0
					if (CL.charge > CL.maxcharge)
						CL.charge = CL.maxcharge
					if (CL.charge == CL.maxcharge)
						visible_message("<span style=\"color:red\">[CL] is fully charged. [src] ejects the cell and shuts down!</span>")
						playsound(loc, "sound/machines/ding.ogg", 100, 1)
						eject_cell()
						updateDialog()
						return
					if (CL.charge < CL.maxcharge)
						CL.give(CL_charge_rate)
						src.P.air_contents.toxins = max(0, (P.air_contents.toxins - src.P_drain_rate))
						// Call proc to trigger rigged cell and log entries.

		update_icon()
		updateDialog()
		return

	attack_hand(var/mob/user as mob)
		add_fingerprint(user)

		user.machine = src
		var/dat = "<h4>[src]</h4>"

		if (P)
			var/gas_mixture/air = P.return_air()
			dat += "<strong>Tank:</strong> <a href='?src=\ref[src];eject=1'>[P]</a> (Plasma: [air.toxins * R_IDEAL_GAS_EQUATION * air.temperature/air.volume] kPa)<br>"
		else
			dat += "<strong>Tank: --------</strong><br>"

		if (CL)
			dat += "<strong>Cell:</strong> <a href='?src=\ref[src];eject-c=1'>[CL]</a> (Charge: [round(CL.percent())]%)<br>"
		else
			dat += "<strong>Cell: --------</strong><br>"

		var/obj/item/cell/APCC = null
		if (our_APC && our_APC.cell)
			APCC = our_APC.cell
		dat += "<strong>APC connection:</strong> [our_APC ? "Established" : "None"] (<a href='?src=\ref[src];getAPC=1'>Refresh</a>)<br>"
		dat += "<strong>APC charge:</strong> [APCC ? "[round(APCC.percent())]%" : "N/A"]<br>"

		dat += "<hr>"

		dat += "<strong>Generator anchors:</strong> [anchored ? "Secured" : "Unsecured"] (<a href='?src=\ref[src];togglebolts=1'>Toggle</a>)<br>"
		dat += "<strong>Generator mode:</strong> [mode == 1 ? "<u>Charge APC</u> / Charge cell" : "Charge APC / <u>Charge cell</u>"] (<a href='?src=\ref[src];togglemode=1'>Toggle</a>)<br>"
		dat += "<strong>Generator status:</strong> [active ? "Running" : "Off"] (<a href='?src=\ref[src];togglepower=1'>Toggle</a>)<br>"

		user << browse(dat, "window=generator")
		onclose(user, "generator")
		return

	Topic(href, href_list)
		if (!isturf(loc)) return
		if (usr.stunned || usr.weakened || usr.stat || usr.restrained()) return
		if (!issilicon(usr) && !in_range(src, usr)) return

		add_fingerprint(usr)
		usr.machine = src

		if (href_list["eject"])
			if (active)
				usr.show_text("Turn the generator off first!", "red")
				return
			if (P)
				visible_message("<span style=\"color:red\">[usr] ejects [P] from the [src]!</span>")
				eject_tank()
			else
				usr.show_text("There's no tank to eject.", "red")

		if (href_list["eject-c"])
			if (active && mode == 2)
				usr.show_text("Turn the generator off first!", "red")
				return
			if (CL)
				visible_message("<span style=\"color:red\">[usr] ejects [CL] from the [src]!</span>")
				eject_cell()
			else
				usr.show_text("There's no cell to eject.", "red")

		if (href_list["getAPC"])
			switch (APC_check())
				if (0)
					our_APC = null
					usr.show_text("Unable to establish connection to local APC.", "red")
				if (1)
					our_APC = get_local_apc(src)
					usr.show_text("Connection to local APC established.", "blue")
				if (2)
					our_APC = null
					usr.show_text("Local APC doesn't have a power cell to charge.", "red")
				else
					our_APC = null
					usr.show_text("An error occurred, please try again.", "red")

		if (href_list["togglebolts"])
			if (!active)
				if (!istype(loc, /turf/simulated/floor))
					usr.show_text("You can't secure the generator here.", "red")
					anchored = 0 // It might have happened, I guess?
					return
				playsound(loc, "sound/items/Ratchet.ogg", 50, 1)
				if (anchored == 1)
					anchored = 0
					our_APC = null // It's just gonna cause trouble otherwise.
				else
					anchored = 1
				visible_message("<span style=\"color:red\">[usr] [anchored ? "bolts" : "unbolts"] [src] [anchored ? "to" : "from"] the floor.</span>")
			else
				usr.show_text("Turn the generator off first!", "red")
				return

		if (href_list["togglemode"])
			if (mode == 1)
				mode = 2
			else
				mode = 1

		if (href_list["togglepower"])
			if (!anchored)
				usr.show_text("The generator can't be activated when it's not secured to the floor.", "red")
				return
			if (!P)
				usr.show_text("There's nothing powering the generator!", "red")
				return
			switch (mode)
				if (1)
					if (!active)
						if (!our_APC)
							usr.show_text("Please refresh APC connection first.", "red")
							return
						if (!our_APC.cell)
							usr.show_text("Local APC doesn't have a power cell to charge.", "red")
							return
				if (2)
					if (!active)
						if (!CL)
							usr.show_text("There's no cell to charge.", "red")
							return
			active = !active
			visible_message("<span style=\"color:blue\">[usr] [active ? "activates" : "deactivates"] the [src].</span>")

		updateUsrDialog()
		return