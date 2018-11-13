// Magnet Stuff

/area/station/quartermaster/magnet
	name = "Magnet Control Room"
	icon_state = "green"
	sound_environment = 10

/area/station/quartermaster/refinery
	name = "Refinery"
	icon_state = "green"
	sound_environment = 10

/obj/machinery/magnet_chassis
	name = "magnet chassis"
	desc = "A strong metal rig designed to hold and link up magnet apparatus with other technology."
	icon = 'icons/obj/64x64.dmi'
	icon_state = "chassis"
	opacity = 0
	density = 1
	anchored = 1
	var/obj/machinery/mining_magnet/linked_magnet = null

	New()
		..()
		spawn (0)
			update_dir()
			for (var/obj/machinery/mining_magnet/MM in range(1,src))
				linked_magnet = MM
				MM.linked_chassis = src
				break

	disposing()
		if (linked_magnet)
			qdel(linked_magnet)
		linked_magnet = null
		..()

	attackby(obj/item/W as obj, mob/user as mob)
		if (istype(W,/obj/item/magnet_parts))
			if (istype(linked_magnet))
				boutput(user, "<span style=\"color:red\">There's already a magnet installed.</span>")
				return
			user.visible_message("<strong>[user]</strong> begins constructing a new magnet.")
			var/turf/T = get_turf(user)
			sleep(240)
			if (user.loc == T && user.equipped() == W && !user.stat)
				var/obj/magnet = new W:constructed_magnet(get_turf(src))
				magnet.dir = dir
				qdel(W)
		else
			..()

	ex_act()
		return

	meteorhit()
		return

	blob_act(var/power)
		return

	bullet_act(var/obj/projectile/P)
		return

	proc/update_dir()
		if (dir & (EAST|WEST))
			bound_height = 64
			bound_width = 32
		else
			bound_height = 32
			bound_width = 64

/obj/item/magnet_parts
	name = "mineral magnet parts"
	desc = "Used to construct a new magnet on a magnet chassis."
	icon = 'icons/obj/electronics.dmi'
	icon_state = "dbox"
	var/constructed_magnet = /obj/machinery/mining_magnet

/obj/item/magnet_parts/construction
	constructed_magnet = /obj/machinery/mining_magnet/construction

	small
		name = "small mineral magnet parts"
		constructed_magnet = /obj/machinery/mining_magnet/construction/small

/obj/magnet_target_marker
	name = "mineral magnet target"
	desc = "Marks the location of an area of asteroid magnetting."
	invisibility = 101
	var/width = 15
	var/height = 15
	var/scan_range = 7
	var/turf/magnetic_center
	alpha = 128

	small
		width = 7
		height = 7
		scan_range = 3

	ex_act()
		return
	meteorhit()
		return
	bullet_act()
		return

	proc/erase_area()
		var/turf/origin = get_turf(src)
		for (var/turf/T in block(origin, locate(origin.x + width - 1, origin.y + height - 1, origin.z)))
			for (var/obj/O in T)
				if (!(O.type in mining_controls.magnet_do_not_erase) && !istype(O, /obj/magnet_target_marker))
					qdel(O)
			T.overlays.len = 0
			if (!istype(T, /turf/space))
				new /turf/space(T)

	proc/generate_walls()
		var/list/walls = list()
		var/turf/origin = get_turf(src)
		for (var/cx = origin.x - 1, cx <= origin.x + width, cx++)
			var/turf/S = locate(cx, origin.y - 1, origin.z)
			if (S)
				var/Q = new /obj/forcefield/mining(S)
				walls += Q
			S = locate(cx, origin.y + width, origin.z)
			if (S)
				var/Q = new /obj/forcefield/mining(S)
				walls += Q
		for (var/cy = origin.y, cy <= origin.y + height - 1, cy++)
			var/turf/S = locate(origin.x - 1, cy, origin.z)
			if (S)
				var/Q = new /obj/forcefield/mining(S)
				walls += Q
			S = locate(origin.x + width, cy, origin.z)
			if (S)
				var/Q = new /obj/forcefield/mining(S)
				walls += Q
		return walls

	proc/check_for_unacceptable_content()
		var/turf/origin = get_turf(src)
		for (var/turf/T in block(locate(origin.x - 1, origin.y - 1, origin.z), locate(origin.x + width, origin.y + height, origin.z)))
			var/mob/living/M = locate() in T
			if (M)
				return TRUE
			var/obj/machinery/vehicle/V = locate() in T
			if (V)
				return TRUE
		return FALSE

	proc/UL()
		var/turf/origin = get_turf(src)
		var/turf/ul = locate(origin.x, origin.y + height - 1, origin.z)
		return ul

	proc/UR()
		var/turf/origin = get_turf(src)
		var/turf/ur = locate(origin.x + width - 1, origin.y + height - 1, origin.z)
		return ur

	proc/DL()
		return get_turf(src)

	proc/DR()
		var/turf/origin = get_turf(src)
		var/turf/dr = locate(origin.x + width - 1, origin.y, origin.z)
		return dr

	proc/construct()
		var/turf/origin = get_turf(src)
		for (var/turf/T in block(origin, locate(origin.x + width - 1, origin.y + height - 1, origin.z)))
			if (!T)
				boutput(usr, "<span style=\"color:red\">Error: magnet area spans over construction area bounds.</span>")
				return FALSE
			if (!istype(T, /turf/space) && !istype(T, /turf/simulated/floor/plating/airless/asteroid) && !istype(T, /turf/simulated/wall/asteroid))
				boutput(usr, "<span style=\"color:red\">Error: [T] detected in [width]x[height] magnet area. Cannot magnetize.</span>")
				return FALSE

		var/borders = list()
		for (var/cx = origin.x - 1, cx <= origin.x + width, cx++)
			var/turf/S = locate(cx, origin.y - 1, origin.z)
			if (!S || istype(S, /turf/space))
				boutput(usr, "<span style=\"color:red\">Error: bordering tile has a gap, cannot magnetize area.</span>")
				return FALSE
			borders += S
			S = locate(cx, origin.y + height, origin.z)
			if (!S || istype(S, /turf/space))
				boutput(usr, "<span style=\"color:red\">Error: bordering tile has a gap, cannot magnetize area.</span>")
				return FALSE
			borders += S

		for (var/cy = origin.y, cy <= origin.y + height - 1, cy++)
			var/turf/S = locate(origin.x - 1, cy, origin.z)
			if (!S || istype(S, /turf/space))
				boutput(usr, "<span style=\"color:red\">Error: bordering tile has a gap, cannot magnetize area.</span>")
				return FALSE
			borders += S
			S = locate(origin.x + width, cy, origin.z)
			if (!S || istype(S, /turf/space))
				boutput(usr, "<span style=\"color:red\">Error: bordering tile has a gap, cannot magnetize area.</span>")
				return FALSE
			borders += S

		magnetic_center = locate(origin.x + round(width/2), origin.y + round(height/2), origin.z)
		for (var/turf/simulated/floor/T in borders)
			T.allows_vehicles = 1
		return TRUE

/obj/item/magnetizer
	name = "Magnetizer"
	desc = "A gun that manipulates the magnetic flux of an area. The designated area can then be activated or deactivated with a mineral magnet."
	icon = 'icons/obj/construction.dmi'
	icon_state = "magnet"
	var/loaded = 0
	force = 0
	var/obj/machinery/mining_magnet/construction/magnet = null

	examine()
		..()
		if (loaded)
			boutput(usr, "<span style=\"color:blue\">The magnetizer is loaded with a plasmastone. Designate the mineral magnet to attach, then designate the lower left tile of the area to magnetize.</span>")
			boutput(usr, "<span style=\"color:blue\">The magnetized area must be a clean shot of space, surrounded by bordering tiles on all sides.</span>")
			boutput(usr, "<span style=\"color:blue\">A small mineral magnet requires an 7x7 area of space, a large one requires a 15x15 area of space.</span>")
		else
			boutput(usr, "<span style=\"color:red\">The magnetizer must be loaded with a chunk of plasmastone to use.</span>")

	attackby(obj/item/W as obj, mob/user as mob)
		if (istype(W, /obj/item/raw_material/plasmastone) && !loaded)
			loaded = 1
			boutput(user, "<span style=\"color:blue\">You charge the magnetizer with the plasmastone.</span>")
			qdel(W)

	afterattack(atom/target as mob|obj|turf|area, mob/user as mob)
		if (!magnet)
			if (istype(target, /obj/machinery/magnet_chassis))
				magnet = target:linked_magnet
			else
				magnet = target
			if (!istype(magnet))
				magnet = null
			else
				if (!loaded)
					boutput(user, "<span style=\"color:red\">The magnetizer needs to be loaded with a plasmastone chunk first.</span>")
					magnet = null
				else if (magnet.target)
					boutput(user, "<span style=\"color:red\">That magnet is already locked onto a location.</span>")
					magnet = null
				else
					boutput(user, "<span style=\"color:blue\">Magnet locked. Designate lower left tile of target area (excluding the borders).</span>")
		else if (istype(target, /turf/space) && magnet)
			if (!loaded)
				boutput(user, "<span style=\"color:red\">The magnetizer needs to be loaded with a plasmastone chunk first.</span>")
			if (magnet.target)
				boutput(user, "<span style=\"color:red\">Magnet target already designated. Unlocking.</span>")
				magnet = null
				return
			var/turf/T = target
			var/obj/magnet_target_marker/M = new magnet.marker_type(T)
			var/turf/A = M.DL()
			var/turf/B = M.DR()
			var/turf/C = M.UL()
			var/turf/D = M.UR()
			var/turf/O = get_turf(magnet)
			var/dist = min(min(get_dist(A, O), get_dist(B, O)), min(get_dist(C, O), get_dist(D, O)))
			if (dist > 10)
				boutput(user, "<span style=\"color:red\">Designation failed: designated tile is outside magnet range.</span>")
				qdel(M)
			else if (!M.construct())
				boutput(user, "<span style=\"color:red\">Designation failed.</span>")
				qdel(M)
			else
				boutput(user, "<span style=\"color:blue\">Designation successful. The magnet is now fully operational.</span>")
				magnet.target = M
				loaded = 0
				magnet = null

/obj/machinery/mining_magnet
	name = "mineral magnet"
	desc = "A piece of machinery able to generate a strong magnetic field to attract mineral sources."
	icon = 'icons/obj/64x64.dmi'
	icon_state = "magnet"
	opacity = 0
	density = 0 // collision is dealt with by the chassis
	anchored = 1
	var/obj/machinery/magnet_chassis/linked_chassis = null
	var/health = 100
	var/attract_time = 300
	var/cooldown_time = 1200
	var/active = 0
	var/last_used = 0
	var/automatic_mode = 0
	var/auto_delay = 100
	var/last_delay = 0
	var/cooldown_override = 0
	var/malfunctioning = 0
	var/rarity_mod = 0

	var/image/active_overlay = null
	var/list/damage_overlays = list()
	var/sound_activate = 'sound/machines/ArtifactAnc1.ogg'
	var/sound_destroyed = 'sound/effects/robogib.ogg'
	var/obj/machinery/power/apc/mining_apc = null

	proc/get_magnetic_center()
		return mining_controls.magnetic_center

	proc/get_scan_range()
		return 6

	proc/check_for_unacceptable_content()
		return mining_controls.magnet_area.check_for_unacceptable_content()

	construction
		var/marker_type = /obj/magnet_target_marker
		var/obj/magnet_target_marker/target = null
		var/list/wall_bits = list()

		get_magnetic_center()
			if (target)
				return target.magnetic_center
			return null

		get_scan_range()
			if (target)
				return target.scan_range
			return FALSE

		check_for_unacceptable_content()
			if (target)
				return target.check_for_unacceptable_content()
			return TRUE

		New()
			..()
			if (mining_apc)
				mining_apc = null // Don't want random apcs across the map going haywire.

		process()
			if (!target)
				return
			if (automatic_mode && last_used < world.time && last_delay < world.time)
				if (target.check_for_unacceptable_content())
					last_delay = world.time + auto_delay
					return
				else
					spawn
						pull_new_source()

		proc/get_encounter(var/rarity_mod)
			return mining_controls.select_encounter(rarity_mod)

		pull_new_source()
			if (!target)
				return

			if (!wall_bits.len)
				wall_bits = target.generate_walls()

			for (var/obj/forcefield/mining/M in wall_bits)
				M.opacity = 1
				M.density = 1
				M.invisibility = 0

			active = 1

			if (last_used > world.time)
				damage(rand(2,6))

			last_used = world.time + cooldown_time
			playsound(loc, sound_activate, 100, 0, 3, 0.25)
			build_icon()

			target.erase_area()

			var/sleep_time = attract_time
			if (sleep_time < 1)
				sleep_time = 20
			sleep_time /= 2

			if (malfunctioning && prob(20))
				do_malfunction()
			sleep(sleep_time)

			var/mining_encounter/MC = get_encounter(rarity_mod)
			MC.generate(target)

			sleep(sleep_time)
			if (malfunctioning && prob(20))
				do_malfunction()

			active = 0
			build_icon()

			for (var/obj/forcefield/mining/M in wall_bits)
				M.opacity = 0
				M.density = 0
				M.invisibility = 101

			updateUsrDialog()
			return

		small
			marker_type = /obj/magnet_target_marker/small
			get_encounter(rarity_mod)
				return mining_controls.select_small_encounter(rarity_mod)

	New()
		..()
		active_overlay = image(icon, "active")
		damage_overlays += image(icon, "damage-1")
		damage_overlays += image(icon, "damage-2")
		damage_overlays += image(icon, "damage-3")
		damage_overlays += image(icon, "damage-4")
		spawn (0)
			for (var/obj/machinery/magnet_chassis/MC in range(1,src))
				linked_chassis = MC
				MC.linked_magnet = src
				break

			for (var/obj/machinery/power/apc/APC in range(20,src))
				var/area/the_area = get_area(APC)
				if (the_area.type == /area/station/quartermaster/magnet)
					mining_apc = APC
					break

	process()
		..()
		if (automatic_mode && last_used < world.time && last_delay < world.time)
			if (mining_controls.magnet_area.check_for_unacceptable_content())
				last_delay = world.time + auto_delay
				return
			else
				spawn (0) //Did you know that if you sleep directly in process() you are the old lady at the mall who only pays in quarters.
					//Do not be quarter lady.
					pull_new_source()

	disposing()
		visible_message("<strong>[src] breaks apart!</strong>")
		robogibs(loc,null)
		playsound(loc, sound_destroyed, 50, 2)
		overlays = list()
		damage_overlays = list()
		linked_chassis = null
		active_overlay = null
		sound_activate = null
		..()

	examine()
		..()
		if (health < 100)
			if (health < 50)
				boutput(usr, "<span style=\"color:red\">It's rather badly damaged. It probably needs some wiring replaced inside.</span>")
			else
				boutput(usr, "<span style=\"color:red\">It's a bit damaged. It looks like it needs some welding done.</span>")

	ex_act(severity)
		switch(severity)
			if (1)
				damage(rand(75,120))
			if (2)
				damage(rand(25,75))
			if (3)
				damage(rand(10,25))

	meteorhit()
		damage(rand(10,25))
		return

	blob_act(var/power)
		return

	bullet_act(var/obj/projectile/P)
		return

	attackby(obj/item/W as obj, mob/user as mob)
		if (active)
			boutput(user, "<span style=\"color:red\">It's way too dangerous to do that while it's active!</span>")
			return

		if (istype(W,/obj/item/weldingtool))
			var/obj/item/weldingtool/WELD = W
			if (health < 50)
				boutput(usr, "<span style=\"color:red\">You need to use wire to fix the cabling first.</span>")
				return
			if (WELD.get_fuel() > 1)
				damage(-10)
				malfunctioning = 0
				WELD.use_fuel(1)
				user.visible_message("<strong>[user]</strong> uses [WELD] to repair some of [src]'s damage.")
				playsound(loc, "sound/items/Welder.ogg", 50, 1)
				if (health >= 100)
					boutput(user, "<span style=\"color:blue\"><strong>[src] looks fully repaired!</strong></span>")
			else
				boutput(user, "<span style=\"color:red\">[WELD] needs more fuel to do that.</span>")

		else if (istype(W,/obj/item/cable_coil))
			var/obj/item/cable_coil/C = W
			if (health > 50)
				boutput(usr, "<span style=\"color:red\">The cabling looks fine. Use a welder to repair the rest of the damage.</span>")
				return
			C.use(1)
			damage(-10)
			user.visible_message("<strong>[user]</strong> uses [C] to repair some of [src]'s cabling.")
			playsound(loc, "sound/items/Deconstruct.ogg", 50, 1)
			if (health >= 50)
				boutput(user, "<span style=\"color:blue\">The wiring is fully repaired. Now you need to weld the external plating.</span>")
				malfunctioning = 0

		else
			..()
			if (W.hitsound)
				playsound(loc, W.hitsound, 50, 1)
			if (W.force)
				var/damage = W.force
				damage /= 3
				if (istype(user,/mob/living/carbon))
					var/mob/living/carbon/C = user
					if (C.bioHolder)
						if (C.bioHolder.HasEffect("hulk"))
							damage *= 4
						if (C.bioHolder.HasEffect("strong"))
							damage *= 2
				if (damage >= 10)
					damage(damage)

	proc/build_icon()
		overlays = list()

		if (damage_overlays.len == 4)
			switch(health)
				if (70 to 94)
					overlays += damage_overlays[1]
				if (40 to 69)
					overlays += damage_overlays[2]
				if (10 to 39)
					overlays += damage_overlays[3]
				if (-INFINITY to 10)
					overlays += damage_overlays[4]

		if (active)
			overlays += active_overlay

	proc/damage(var/amount)
		if (!isnum(amount))
			return

		health -= amount
		health = max(0,min(health,100))

		if (health < 1 && !active)
			qdel(src)
			return

		build_icon()
		if (!prob(health) && amount > 0)
			malfunctioning = 1
		return

	proc/do_malfunction()
		var/picker = rand(1,2)
		switch(picker)
			if (1)
				src.visible_message("<strong>[src] makes a loud bang! That didn't sound too good...</strong>")
				playsound(loc, "sound/misc/meteorimpact.ogg", 50, 1)
				damage(rand(5,10))
			if (2)
				if (istype(mining_apc))
					mining_apc.visible_message("<strong>Magnetic feedback causes [mining_apc] to go haywire!</strong>")
					mining_apc.zapStuff()

	proc/pull_new_source()
		for (var/obj/forcefield/mining/M in mining_controls.magnet_shields)
			M.opacity = 1
			M.density = 1
			M.invisibility = 0

		active = 1

		if (last_used > world.time)
			damage(rand(2,6))

		last_used = world.time + cooldown_time
		playsound(loc, sound_activate, 100, 0, 3, 0.25)
		build_icon()

		for (var/obj/O in mining_controls.magnet_area.contents)
			if (!(O.type in mining_controls.magnet_do_not_erase))
				qdel(O)
		for (var/turf/simulated/T in mining_controls.magnet_area.contents)
			if (!istype(T,/turf/simulated/floor/plating/airless/catwalk))
				qdel(T)
		for (var/turf/space/S in mining_controls.magnet_area.contents)
			S.overlays = list()

		var/sleep_time = attract_time
		if (sleep_time < 1)
			sleep_time = 20
		sleep_time /= 2

		if (malfunctioning && prob(20))
			do_malfunction()
		sleep(sleep_time)

		var/mining_encounter/MC = mining_controls.select_encounter(rarity_mod)
		MC.generate(null)

		sleep(sleep_time)
		if (malfunctioning && prob(20))
			do_malfunction()

		active = 0
		build_icon()

		for (var/obj/forcefield/mining/M in mining_controls.magnet_shields)
			M.opacity = 0
			M.density = 0
			M.invisibility = 101

		updateUsrDialog()
		return

	proc/generate_interface(var/mob/user as mob)
		user.machine = src

		var/dat = "<BR><strong>Magnet Status:</strong><BR>"
		dat += "<u>Condition:</u> "
		switch(health)
			if (95 to INFINITY)
				dat += "Optimal"
			if (70 to 94)
				dat += "Mild Structural Damage"
			if (40 to 69)
				dat += "Heavy Structural Damage"
			if (10 to 39)
				dat += "Extreme Structural Damage"
			if (-INFINITY to 10)
				dat += "Destruction Imminent"

		dat += "<br><u>Status:</u> "
		if (active)
			dat += "Pulling New Mineral Source"
		else
			if (last_used > world.time)
				dat += "Cooling Down: Ready in T-[max(0,round((last_used - world.time) / 10))]"
				if (cooldown_override)
					dat += "<br><em>Cooldown Override Engaged</em>"
			else
				dat += "Idle"

		dat += "<BR><HR>"
		if (active)
			dat += "Magnet Active<BR>"
		else
			if (last_used > world.time)
				if (cooldown_override)
					dat += "<A href='?src=\ref[src];activate_magnet=1'>Activate Magnet</A> (On Cooldown!)<BR>"
				else
					dat += "Magnet Cooling Down<BR>"
			else
				dat += "<A href='?src=\ref[src];activate_magnet=1'>Activate Magnet</A><BR>"
			dat += "<A href='?src=\ref[src];geo_scan=1'>Scan Mining Area</A><BR>"

		var/auto_mode = "Enable Automatic Mode"
		if (automatic_mode)
			auto_mode = "Disable Automatic Mode"
		dat += "<A href='?src=\ref[src];auto_mode=1'>[auto_mode]</A><BR>"

		var/override_text = "Override Cooldown"
		if (cooldown_override)
			override_text = "Disable Cooldown Override"
		dat += "<A href='?src=\ref[src];override_cooldown=1'>[override_text]</A><BR>"
		dat += "<BR><A href='?action=mach_close&window=computer'>Close</A>"
		usr << browse(dat, "window=computer;size=300x400")
		onclose(usr, "computer")
		return null

	Topic(href, href_list)
		if (stat & (NOPOWER|BROKEN))
			boutput(usr, "<span style='color:red'>That machine is not powered.</span>")
			return TRUE
		if (usr.restrained() || usr.lying || usr.stat)
			boutput(usr, "<span style='color:red'>You are currently unable to do that.</span>")
			return TRUE

		var/rangecheck = 0
		if (istype(usr, /mob/living/silicon))
			rangecheck = 1
		if (istype(usr.loc,/obj/machinery/vehicle))
			var/obj/machinery/vehicle/V = usr.loc
			if (istype(V.com_system,/obj/item/shipcomponent/communications/mining) && V.com_system.active)
				rangecheck = 1
		for (var/obj/machinery/computer/magnet/M in range(usr,1))
			rangecheck = 1
			break

		if (!rangecheck)
			boutput(usr, "<span style='color:red'>You aren't in range of the controls.</span>")
			return
		usr.machine = src

		if (!istype(src))
			boutput(usr, "Error. Magnet not detected.")
			updateUsrDialog()
			return

		else if (href_list["activate_magnet"])
			if (ticker.mode && !istype(ticker.mode, /game_mode/construction) && !istype(mining_controls.magnet_area))
				boutput(usr, "Uh oh, something's gotten really fucked up with the magnet system. Please report this to a coder!")
				return

			if (check_for_unacceptable_content())
				visible_message("<strong>[name]</strong> states, \"Safety lock engaged. Please remove all personnel and vehicles from the magnet area.\"")
			else
				spawn (0)
					if (src) pull_new_source()

		else if (href_list["override_cooldown"])
			if (!istype(usr,/mob/living/carbon/human))
				boutput(usr, "<span style=\"color:red\">AI and robotic personnel may not access the override.</span>")
			else
				var/mob/living/carbon/human/H = usr
				if (!allowed(H, req_only_one_required))
					boutput(usr, "<span style=\"color:red\">Access denied. Please contact the Chief Engineer or Captain to access the override.</span>")
				else
					cooldown_override = !cooldown_override

		else if (href_list["auto_mode"])
			automatic_mode = !automatic_mode

		else if (href_list["geo_scan"])
			var/MC = get_magnetic_center()
			if (!MC)
				boutput(usr, "Error. Magnet is not magnetized.")
				updateUsrDialog()
				return

			mining_scan(MC, usr, get_scan_range())

		generate_interface(usr)
		return

/obj/machinery/computer/magnet
	name = "mineral magnet controls"
	icon = 'icons/obj/computer.dmi'
	icon_state = "mmagnet"
	var/temp = null
	var/list/linked_magnets = list()
	var/obj/machinery/mining_magnet/linked_magnet = null
	req_access = list(access_engineering_chief)

	New()
		..()
		spawn (0)
			connection_scan()

	attackby(obj/I as obj, mob/user as mob)
		if (istype(I, /obj/item/screwdriver))
			playsound(loc, "sound/items/Screwdriver.ogg", 50, 1)
			if (do_after(user, 20))
				if (stat & BROKEN)
					user.show_text("The broken glass falls out.", "blue")
					var/obj/computerframe/A = new /obj/computerframe(loc)
					if (material)
						A.setMaterial(material)
					new /obj/item/raw_material/shard/glass(loc)
					var/obj/item/circuitboard/mining_magnet/M = new /obj/item/circuitboard/mining_magnet(A)
					for (var/obj/C in src)
						C.set_loc(loc)
					A.circuit = M
					A.state = 3
					A.icon_state = "3"
					A.anchored = 1
					qdel(src)
				else
					user.show_text("You disconnect the monitor.", "blue")
					var/obj/computerframe/A = new /obj/computerframe(loc)
					if (material)
						A.setMaterial(material)
					var/obj/item/circuitboard/mining_magnet/M = new /obj/item/circuitboard/mining_magnet(A)
					for (var/obj/C in src)
						C.set_loc(loc)
					A.circuit = M
					A.state = 4
					A.icon_state = "4"
					A.anchored = 1
					qdel(src)
		else
			attack_hand(user)
		return

	attack_hand(var/mob/user as mob)
		if (..())
			return
		if (istype(linked_magnet))
			linked_magnet.generate_interface(user)
		else
			user.machine = src
			var/dat = "<strong>Mineral Mining Magnet Terminal</strong><HR>"
			dat += "<A href='?src=\ref[src];scan_for_connection=1'>Scan for Magnets</A><BR><BR>"
			dat += "<strong>Choose linked magnet:</strong><BR>"
			for (var/obj/M in linked_magnets)
				dat += "<a href='?src=\ref[src];choosemagnet=\ref[M]'>[M] at ([M.x], [M.y])</a><BR>"
			dat += "<BR><strong>Selected magnet:</strong><BR>"
			if (linked_magnet)
				dat += "[linked_magnet] at ([linked_magnet.x], [linked_magnet.y])<BR>"
			else
				dat += "None<BR>"

			//dat += "<BR><a href='?src=\ref[src];unlink=1'>Disconnect Terminal from Magnet</a>"

			dat += "<BR><A href='?action=mach_close&window=computer'>Close</A>"
			user << browse(dat, "window=computer;size=300x400")
			onclose(user, "computer")
		return

	Topic(href, href_list)
		if (..())
			return

		if ((usr.contents.Find(src) || (in_range(src, usr) && istype(loc, /turf))) || (istype(usr, /mob/living/silicon)))
			usr.machine = src

		add_fingerprint(usr)

		if (href_list["choosemagnet"])
			linked_magnet = locate(href_list["choosemagnet"])
			if (!linked_magnet)
				linked_magnet = null
				visible_message("<strong>[name]</strong> states, \"Designated magnet is no longer operational.\"")

		else if (href_list["scan_for_connection"])
			switch(connection_scan())
				if (1)
					visible_message("<strong>[name]</strong> states, \"Unoccupied Magnet Chassis located. Please connect magnet system to chassis.\"")
				if (2)
					visible_message("<strong>[name]</strong> states, \"Magnet equipment not found within range.\"")
				else
					visible_message("<strong>[name]</strong> states, \"Magnet equipment located. Link established.\"")

		else if (href_list["unlink"])
			linked_magnet = null

		updateUsrDialog()
		return

	proc/connection_scan()
		linked_magnets = list()
		var/badmagnets = 0
		for (var/obj/machinery/magnet_chassis/MC in range(20,src))
			if (MC.linked_magnet)
				linked_magnets += MC.linked_magnet
			else
				badmagnets++
		if (linked_magnets.len)
			return FALSE
		if (badmagnets)
			return TRUE
		return 2

// Turf Defines

/turf/simulated/wall/asteroid
	name = "asteroid"
	desc = "A free-floating mineral deposit from space."
	icon = 'icons/turf/asteroid.dmi'
	icon_state = "ast1"
	var/stone_color = "#CCCCCC"
	var/hardness = 0
	var/weakened = 0
	var/amount = 2
	var/invincible = 0
	var/quality = 0
	var/default_ore = /obj/item/raw_material/rock
	var/ore/ore = null
	var/ore/event/event = null
	var/list/space_overlays = list()
	RL_Ignore = 1

	ice
		name = "comet chunk"
		desc = "That's some cold stuff right there."
		stone_color = "#D1E6FF"
		default_ore = /obj/item/raw_material/ice

	geode
		name = "compacted stone"
		desc = "This rock looks really hard to dig out."
		stone_color = "#575A5E"
		default_ore = null
		hardness = 10

	New(var/loc,var/do_overlays_now = 1)
		icon_state = pick("ast1","ast2","ast3")
		..()
		if (do_overlays_now)
			space_overlays()

	ex_act(severity)
		switch(severity)
			if (1.0)
				damage_asteroid(7)
			if (2.0)
				damage_asteroid(5)
			if (3.0)
				damage_asteroid(3)
		return

	meteorhit(obj/M as obj)
		damage_asteroid(5)

	blob_act(var/power)
		if (prob(power))
			damage_asteroid(7)

	dismantle_wall()
		return destroy_asteroid()

	get_desc(dist)
		if (dist > 1)
			return
		if (istype(usr, /mob/living/carbon/human))
			if (usr.bioHolder && usr.bioHolder.HasEffect("training_miner"))
				if (istype (ore,/ore/))
					var/ore/O = ore
					. = "It looks like it contains [O.name]."
				else
					. = "Doesn't look like there's any valuable ore here."
				if (src.event)
					. += "<br><span style=\"color:red\">There's something not quite right here...</span>"

	attack_hand(var/mob/user as mob)
		if (istype(user,/mob/living/carbon/human))
			var/mob/living/carbon/human/H = user
			if (istype(H.gloves, /obj/item/clothing/gloves/concussive))
				var/obj/item/clothing/gloves/concussive/C = H.gloves
				dig_asteroid(user,C.tool)
				return
			else if (H.bioHolder && H.bioHolder.HasEffect("hulk"))
				H.visible_message("<span style=\"color:red\"><strong>[H.name] punches [src] with great strength!</span>")
				playsound(H.loc, "sound/misc/meteorimpact.ogg", 100, 1)
				damage_asteroid(3)
				return
		..()

	attackby(obj/item/W as obj, mob/user as mob)
		if (istype(W,/obj/item/mining_tool))
			var/obj/item/mining_tool/T = W
			dig_asteroid(user,T)
			if (T.status)
				T.process_charges(1)

		else if (istype(W, /obj/item/oreprospector))
			var/message = "----------------------------------<br>"
			message += "<strong>Geological Report:</strong><br><br>"
			var/ore/O = ore
			var/ore/event/E = src.event
			if (O)
				message += "This stone contains [O.name].<br>"
				message += "Analysis suggests [amount] units of viable ore are present.<br>"
			else
				message += "This rock contains no known ores.<br>"
			message += "The rock here has a hardness rating of [hardness].<br>"
			if (weakened)
				message += "The rock here has been weakened.<br>"
			if (E)
				if (E.analysis_string)
					message += "<span style=\"color:red\">[E.analysis_string]</span><br>"
			message += "----------------------------------"
			boutput(user, message)

		else
			boutput(user, "<span style=\"color:red\">You hit the [name] with [W], but nothing happens!</span>")
		return

	proc/build_icon(var/wipe_overlays = 0)
		if (wipe_overlays)
			overlays = list()
		var/image/coloration = image(icon,"color_overlay")
		coloration.blend_mode = 4
		coloration.color = stone_color
		overlays += coloration

	proc/space_overlays()
		for (var/turf/space/A in orange(src,1))
			var/image/edge_overlay = image('icons/turf/asteroid.dmi', "edge[GetOppositeDirection(get_dir(src,A))]")
			edge_overlay.layer = layer + 1
			edge_overlay.color = stone_color
			A.overlays += edge_overlay
			space_overlays += edge_overlay

	proc/dig_asteroid(var/mob/living/user, var/obj/item/mining_tool/tool)
		if (!user || !tool) return

		var/ore/event/E = src.event

		if (tool.status)
			playsound(user.loc, tool.hitsound_charged, 50, 1)
		else
			playsound(user.loc, tool.hitsound_uncharged, 50, 1)

		if (tool.weakener)
			weaken_asteroid()

		var/strength = tool.dig_strength
		if (istype(user,/mob/living/carbon))
			var/mob/living/carbon/C = user
			if (C.bioHolder && C.bioHolder.HasOneOfTheseEffects("strong","hulk"))
				strength++

		var/minedifference = hardness - strength

		if (E)
			E.onHit(src)
		//user.visible_message("<span style=\"color:red\">[user.name] strikes [src] with [tool].</span>")

		var/dig_chance = 100
		var/dig_feedback = null

		switch(minedifference)
			if (1)
				dig_chance = 30
				dig_feedback = "This rock is tough. You may need a stronger tool."
			if (2)
				dig_chance = 10
				dig_feedback = "This rock is very tough. You need a stronger tool."
			if (3 to INFINITY)
				dig_chance = 0
				dig_feedback = "You can't even make a dent! You need a stronger tool."

		if (prob(dig_chance))
			destroy_asteroid()
		else
			if (dig_feedback)
				boutput(user, "<span style=\"color:red\">[dig_feedback]</span>")

		return

	proc/weaken_asteroid()
		if (weakened)
			return
		weakened = 1
		if (hardness >= 1)
			hardness /= 2
		else
			hardness = 0
		overlays += image('icons/turf/asteroid.dmi', "weakened")

	proc/damage_asteroid(var/power)
		// use this for stuff that arent mining tools but still attack asteroids
		if (!isnum(power) || power <= 0)
			return
		var/difference = hardness - power

		if (difference <= 0)
			destroy_asteroid()
		else
			if (rand(1,difference) == 1)
				weaken_asteroid()

		return

	proc/destroy_asteroid()
		var/ore/O = ore
		var/ore/event/E = src.event
		if (invincible)
			return
		if (E)
			if (E.excavation_string)
				visible_message("<span style=\"color:red\">[E.excavation_string]</span>")
			E.onExcavate(src)
		var/ore_to_create = default_ore
		if (ispath(ore_to_create))
			if (O)
				ore_to_create = O.output
			var/makeores
			for (makeores = amount, makeores > 0, makeores--)
				var/obj/item/raw_material/MAT = new ore_to_create(src)

				if (MAT.material)
					if (MAT.material.quality != 0) //If it's 0 then that's probably the default, so let's use the asteroids quality only if it's higher. That way materials that have a quality by default will not occur at any quality less than the set one. And materials that do not have a quality by default, use the asteroids quality instead.
						var/newQual = max(MAT.material.quality, quality)
						MAT.material.quality = newQual
						MAT.quality = newQual
					else
						MAT.material.quality = quality
						MAT.quality = quality

				MAT.name = getOreQualityName(MAT.quality) + " [MAT.name]"
				score_oremined += 1
		if (!icon_old)
			icon_old = icon_state
		var/turf/simulated/floor/plating/airless/asteroid/W
		var/old_dir = dir
		var/new_color = stone_color
		W = new /turf/simulated/floor/plating/airless/asteroid(locate(x, y, z))
		W.stone_color = new_color
		W.dir = old_dir
		W.opacity = 1
		W.RL_SetOpacity(0)
		W.levelupdate()
		for (var/turf/simulated/floor/plating/airless/asteroid/A in range(W,1))
			A.update_icon()
		return W

	proc/set_event(var/ore/event/E)
		if (!istype(E))
			return
		src.event = E
		E.onGenerate(src)
		if (E.prevent_excavation)
			invincible = 1
		if (E.nearby_tile_distribution_min > 0 && E.nearby_tile_distribution_max > 0)
			var/distributions = rand(E.nearby_tile_distribution_min,E.nearby_tile_distribution_max)
			var/list/usable_turfs = list()
			for (var/turf/simulated/wall/asteroid/AST in range(E.distribution_range,src))
				if (!isnull(AST.event))
					continue
				usable_turfs += AST

			var/turf/simulated/wall/asteroid/AST
			while (distributions > 0)
				distributions--
				if (usable_turfs.len < 1)
					break
				AST = pick(usable_turfs)
				AST.event = E
				E.onGenerate(AST)
				usable_turfs -= AST

/turf/simulated/floor/plating/airless/asteroid
	name = "asteroid"
	icon = 'icons/turf/asteroid.dmi'
	icon_state = "astfloor1"
	oxygen = 0.01
	nitrogen = 0.01
	temperature = TCMB
	luminosity = 1
	RL_Ignore = 1
	var/sprite_variation = 1
	var/stone_color = null
	var/image/coloration_overlay = null

	New()
		..()
		sprite_variation = rand(1,3)
		icon_state = "astfloor" + "[sprite_variation]"
		coloration_overlay = image(icon,"color_overlay")
		coloration_overlay.blend_mode = 4

	ex_act(severity)
		return

	proc/destroy_asteroid()
		return

	proc/damage_asteroid(var/power)
		return

	proc/weaken_asteroid()
		return

	update_icon()
		overlays = list()
		if (!coloration_overlay)
			coloration_overlay = image(icon, "color_overlay")
		coloration_overlay.color = stone_color
		overlays += coloration_overlay
		for (var/turf/simulated/wall/asteroid/A in orange(src,1))
			apply_edge_overlay(get_dir(src, A))
		for (var/turf/space/A in orange(src,1))
			apply_edge_overlay(get_dir(src, A))

	proc/apply_edge_overlay(var/thedir)
		var/image/dig_overlay = image('icons/turf/asteroid.dmi', "edge[thedir]")
		dig_overlay.color = stone_color
		dig_overlay.layer = layer + 1
		overlays += dig_overlay

// Tool Defines

/obj/item/mining_tool
	name = "pickaxe"
	desc = "A thing to bash rocks with until they become smaller rocks."
	icon = 'icons/obj/mining.dmi'
	icon_state = "pickaxe"
	inhand_image_icon = 'icons/mob/inhand/hand_tools.dmi'
	item_state = "pick"
	w_class = 2
	flags = ONBELT
	force = 7
	var/dig_strength = 1
	var/charges = 0
	var/maximum_charges = 0
	var/status = 0
	var/weakener = 0
	var/image/powered_overlay = null
	var/sound/hitsound_charged = 'sound/effects/pickaxe.ogg'
	var/sound/hitsound_uncharged = 'sound/effects/pickaxe.ogg'
	module_research = list("tools" = 3, "engineering" = 1, "mining" = 1)

	// Seems like a basic bit of user feedback to me (Convair880).
	examine()
		..()
		if (maximum_charges <= 0) return
		if (isrobot(usr)) return // Drains battery instead.
		boutput(usr, "The [name] is turned [status ? "on" : "off"]. There are [charges]/[maximum_charges] charges left!")
		return

	proc/process_charges(var/use)
		if (!isnum(use) || use < 0)
			return FALSE
		if (charges < 1)
			return FALSE
		charges -= use
		charges = max(0,min(charges,maximum_charges))
		if (charges == 0)
			power_down()
			var/turf/T = get_turf(src)
			T.visible_message("<span style=\"color:red\">[src] runs out of charge and powers down!</span>")
		return TRUE

	proc/power_up()
		status = 1
		if (powered_overlay)
			overlays += powered_overlay
		return

	proc/power_down()
		status = 0
		if (powered_overlay)
			overlays = null
		return

/obj/item/clothing/gloves/concussive
	name = "concussion gauntlets"
	desc = "These gloves enable miners to punch through solid rock with their hands instead of using tools."
	icon_state = "cgaunts"
	item_state = "bgloves"
	material_prints = "industrial-grade mineral fibers"
	var/obj/item/mining_tool/tool = null

	New()
		..()
		var/obj/item/mining_tool/T = new /obj/item/mining_tool(src)
		tool = T
		T.name = name
		T.desc = desc
		T.dig_strength = 4
		T.hitsound_charged = 'sound/effects/bang.ogg'
		T.hitsound_uncharged = 'sound/effects/bang.ogg'

/obj/item/mining_tool/power_pick
	name = "power pick"
	desc = "An energised mining tool."
	icon = 'icons/obj/mining.dmi'
	icon_state = "powerpick"
	item_state = "ppick"
	flags = ONBELT
	w_class = 2
	dig_strength = 2
	maximum_charges = 50
	hitsound_charged = 'sound/effects/bang.ogg'
	hitsound_uncharged = 'sound/effects/pickaxe.ogg'
	module_research = list("tools" = 5, "engineering" = 2, "mining" = 3)

	New()
		..()
		powered_overlay = image('icons/obj/mining.dmi', "pp-glow")
		charges = maximum_charges
		power_up()

	attack_self(var/mob/user as mob)
		if (process_charges(0))
			if (!status)
				boutput(user, "<span style=\"color:blue\">You power up [src].</span>")
				power_up()
			else
				boutput(user, "<span style=\"color:blue\">You power down [src].</span>")
				power_down()
		else
			boutput(user, "<span style=\"color:red\">No charge left in [src].</span>")

	attack(target as mob, mob/user as mob)
		if (status)
			process_charges(1)
		..()

	power_up()
		..()
		force = 15
		dig_strength = 2

	power_down()
		..()
		force = 7
		dig_strength = 1

	borg
		process_charges(var/use)
			var/mob/living/silicon/robot/R = usr
			if (istype(R))
				if (R.cell.charge > use * 200)
					R.cell.use(200 * use)
					return TRUE
				return FALSE
			else
				. = ..()

/obj/item/mining_tool/drill
	name = "laser drill"
	desc = "Safe mining tool that doesn't require recharging."
	icon = 'icons/obj/mining.dmi'
	icon_state = "lasdrill"
	inhand_image_icon = 'icons/mob/inhand/hand_tools.dmi'
	item_state = "drill"
	w_class = 2
	flags = ONBELT
	force = 10
	mats = 4
	dig_strength = 2
	hitsound_charged = 'sound/items/Welder.ogg'
	hitsound_uncharged = 'sound/items/Welder.ogg'
	module_research = list("tools" = 5, "engineering" = 3, "mining" = 5)

/obj/item/mining_tool/powerhammer
	name = "power hammer"
	desc = "An energised mining tool."
	icon = 'icons/obj/mining.dmi'
	icon_state = "powerhammer"
	inhand_image_icon = 'icons/mob/inhand/hand_tools.dmi'
	item_state = "hammer"
	w_class = 2
	maximum_charges = 30
	force = 10
	dig_strength = 3
	hitsound_charged = 'sound/effects/bang.ogg'
	hitsound_uncharged = 'sound/effects/pickaxe.ogg'
	module_research = list("tools" = 5, "engineering" = 1, "mining" = 5)

	New()
		..()
		powered_overlay = image('icons/obj/mining.dmi', "ph-glow")
		charges = maximum_charges
		power_up()

	power_up()
		..()
		force = 10
		dig_strength = 3
		weakener = 1

	power_down()
		..()
		force = 20
		dig_strength = 1
		weakener = 0

	attack_self(var/mob/user as mob)
		if (process_charges(0))
			if (!status)
				boutput(user, "<span style=\"color:blue\">You power up [src].</span>")
				power_up()
			else
				boutput(user, "<span style=\"color:blue\">You power down [src].</span>")
				power_down()
		else
			boutput(user, "<span style=\"color:red\">No charge left in [src].</span>")

	attack(target as mob, mob/user as mob)
		..()
		if (status)
			process_charges(1)

	borg
		process_charges(var/use)
			var/mob/living/silicon/robot/R = usr
			if (istype(R))
				if (R.cell.charge > use * 200)
					R.cell.use(200 * use)
					return TRUE
				return FALSE
			else
				. = ..()

/obj/item/breaching_charge/mining
	name = "concussive charge"
	desc = "It is set to detonate in 5 seconds."
	flags = ONBELT
	w_class = 1
	var/emagged = 0
	var/hacked = 0
	expl_devas = 0
	expl_heavy = 1
	expl_light = 2
	expl_flash = 4

	light
		name = "low-yield concussive charge"
		desc = "It is set to detonate in 5 seconds."
		expl_devas = 0
		expl_heavy = 0
		expl_light = 1
		expl_flash = 2

	light/hacked
		hacked = 1
		desc = "It is set to detonate in 5 seconds. The safety light is off."

	hacked
		hacked = 1
		desc = "It is set to detonate in 5 seconds. The safety light is off."

	afterattack(atom/target as mob|obj|turf|area, mob/user as mob)
		if (user.equipped() == src)
			if (!state)
				if (user.bioHolder.HasEffect("clumsy") || emagged)
					if (emagged)
						user.visible_message("<strong>CLICK</strong>")
						boutput(user, "<span style=\"color:red\">The timing mechanism malfunctions!</span>")
					else
						boutput(user, "<span style=\"color:red\">Huh? How does this thing work?!</span>")
					logTheThing("combat", user, null, "accidentally triggers [src] (clumsy bioeffect) at [log_loc(user)].")
					spawn (5)
						concussive_blast()
						qdel (src)
						return
				else
					if (istype(target, /turf/simulated/wall/asteroid) && !hacked)
						boutput(user, "<span style=\"color:red\">You slap the charge on [target], [det_time/10] seconds!</span>")
						user.visible_message("<span style=\"color:red\">[user] has attached [src] to [target].</span>")
						icon_state = "bcharge2"
						user.drop_item()

						// Yes, please (Convair880).
						if (src && hacked)
							logTheThing("combat", user, null, "attaches a hacked [src] to [target] at [log_loc(target)].")

						user.dir = get_dir(user, target)
						user.drop_item()
						var/t = (isturf(target) ? target : target.loc)
						step_towards(src, t)

						spawn ( det_time )
							concussive_blast()
							if (target)
								if (istype(target,/obj/machinery))
									qdel(target)
							qdel(src)
							return
					else if (src.hacked) ..()
					else boutput(user, "<span style=\"color:red\">These will only work on asteroids.</span>")
			return

	emag_act(var/mob/user, var/obj/item/card/emag/E)

		if (!emagged && !hacked)
			if (user)
				boutput(user, "<span style=\"color:blue\">You short out the timing mechanism!</span>")

			desc += " It has been tampered with."
			emagged = 1
			return TRUE
		else
			if (user)
				boutput(user, "<span style=\"color:red\">This has already been tampered with.</span>")
			return FALSE

	demag(var/mob/user)
		if (!emagged)
			return FALSE
		if (user)
			boutput(user, "<span style=\"color:blue\">You repair the timing mechanism!</span>")
		emagged = 0
		desc = null
		desc = "It is set to detonate in 5 seconds."
		return TRUE

	attackby(obj/item/W as obj, mob/user as mob)
		if (istype(W, /obj/item/device/chargehacker))
			if (!emagged && !hacked)
				boutput(user, "<span style=\"color:blue\">You short out the attachment mechanism, removing its restrictions!</span>")
				desc += " It has been tampered with."
				hacked = 1
			else
				boutput(user, "<span style=\"color:red\">This has already been tampered with.</span>")
		else ..()

	proc/concussive_blast()
		playsound(loc, "sound/weapons/flashbang.ogg", 50, 1)
		for (var/turf/simulated/wall/asteroid/A in range(expl_flash,src))
			if (get_dist(src,A) <= expl_heavy)
				A.damage_asteroid(4)
			if (get_dist(src,A) <= expl_light)
				A.damage_asteroid(3)
			if (get_dist(src,A) <= expl_flash)
				A.damage_asteroid(2)

		for (var/mob/living/carbon/C in range(expl_flash, src))
			if (C.stat != 2 && C.client) shake_camera(C, 3, 2)
			if (get_dist(src,C) <= expl_light)
				C.stunned += 8
				C.weakened += 10
				C.stuttering += 15
				boutput(C, "<span style=\"color:red\">The concussive blast knocks you off your feet!</span>")
			if (get_dist(src,C) <= expl_heavy)
				C.TakeDamage("All",rand(15,25),0)
				boutput(C, "<span style=\"color:red\">You are battered by the concussive shockwave!</span>")

/obj/item/cargotele
	name = "cargo transporter"
	desc = "A device for teleporting crated goods."
	icon = 'icons/obj/mining.dmi'
	icon_state = "cargotele"
	var/charges = 10
	var/maximum_charges = 10.0
	var/robocharge = 250
	var/target = null
	w_class = 2
	flags = ONBELT
	mats = 4

	examine()
		..()
		if (isrobot(usr)) return // Drains battery instead.
		boutput(usr, "There are [charges]/[maximum_charges] charges left!")
		return

	attack_self() // Fixed --melon
		if (charges < 1)
			boutput(usr, "<span style=\"color:red\">The transporter is out of charge.</span>")
			return
		if (!cargopads.len) boutput(usr, "<span style=\"color:red\">No receivers available.</span>")
		else
		//here i set up an empty var that can take any object, and tell it to look for absolutely anything in the list
			var/selection = input("Select Cargo Pad Location:", "Cargo Pads", null, null) as null|anything in cargopads
			if (!selection)
				return
			var/turf/T = get_turf(selection)
			//get the turf of the pad itself
			if (!T)
				boutput(usr, "<span style=\"color:red\">Target not set!</span>")
				return
			boutput(usr, "Target set to [T.loc].")
			//blammo! works!
			target = T

	proc/cargoteleport(var/obj/T, var/mob/user)
		if (!target)
			boutput(user, "<span style=\"color:red\">You need to set a target first!</span>")
			return
		if (charges < 1)
			boutput(user, "<span style=\"color:red\">The transporter is out of charge.</span>")
			return
		if (isrobot(user))
			var/mob/living/silicon/robot/R = user
			if (R.cell.charge < robocharge)
				boutput(user, "<span style=\"color:red\">There is not enough charge left in your cell to use this.</span>")
				return

		// Why didn't you implement checks for these in the first place, sigh (Convair880).
		if (ismob(T.loc) && T.loc == user && issilicon(user))
			user.show_text("The [T.name] is securely bolted to your chassis.", "red")
			return

		boutput(user, "<span style=\"color:blue\">Teleporting [T]...</span>")
		playsound(user.loc, "sound/machines/click.ogg", 50, 1)

		if (do_after(user, 50))
			// And these too (Convair880).
			if (ismob(T.loc) && T.loc == user)
				user.u_equip(T)
			if (istype(T.loc, /obj/item/storage))
				var/obj/item/storage/S_temp = T.loc
				var/hud/storage/H_temp = S_temp.hud
				H_temp.remove_object(T)

			// And logs for good measure (Convair880).
			var/is_locked = 0
			var/is_welded = 0
			if (istype(T, /obj/storage)) // Other containers (e.g. prison artifacts) can hold mobs too.
				var/obj/storage/S = T
				if (S.locked) is_locked = 1
				if (S.welded) is_welded = 1

			for (var/mob/M in T.contents)
				if (M)
					logTheThing("station", user, M, "uses a cargo transporter to send [T.name][is_locked ? " (locked)" : ""][is_welded ? " (welded)" : ""] with %target% inside to [log_loc(target)].")

			T.set_loc(target)
			var/effects/system/spark_spread/s = unpool(/effects/system/spark_spread)
			s.set_up(5, 1, src)
			s.start()
			if (istype(user,/mob/living/silicon/robot))
				var/mob/living/silicon/robot/R = user
				R.cell.charge -= robocharge
			else
				charges -= 1
				if (charges < 0)
					charges = 0
				if (charges == 0)
					boutput(user, "<span style=\"color:red\">Transfer successful. The transporter is now out of charge.</span>")
				else
					boutput(user, "<span style=\"color:blue\">Transfer successful. [charges] charges remain.</span>")
		return

/obj/item/cargotele/traitor
	var/list/possible_targets = list()

	New()
		for (var/turf/T in world) //hate to do this but it's only once per spawn vOv
			if (istype(T,/turf/space) && T.z != 1 && !isrestrictedz(T.z))
				possible_targets += T

	attack_self() // Fixed --melon
		return

	cargoteleport(var/obj/T, var/mob/user)
		target = pick(possible_targets)
		if (!target)
			boutput(user, "<span style=\"color:red\">No target found!</span>")
			return
		if (charges < 1)
			boutput(user, "<span style=\"color:red\">The transporter is out of charge.</span>")
			return
		boutput(user, "<span style=\"color:blue\">Teleporting [T]...</span>")
		playsound(user.loc, "sound/machines/click.ogg", 50, 1)

		if (do_after(user, 50))

			// Logs for good measure (Convair880).
			for (var/mob/M in T.contents)
				if (M)
					logTheThing("station", user, M, "uses a Syndicate cargo transporter to send [T.name] with %target% inside to [log_loc(target)].")

			T.set_loc(target)
			if (hasvar(T, "welded")) T:welded = 1
			var/effects/system/spark_spread/s = unpool(/effects/system/spark_spread)
			s.set_up(5, 1, src)
			s.start()
			charges -= 1
			if (charges < 0)
				charges = 0
			if (charges == 0)
				boutput(user, "<span style=\"color:red\">Transfer successful. The transporter is now out of charge.</span>")
			else
				boutput(user, "<span style=\"color:blue\">Transfer successful. [charges] charges remain.</span>")
		return

/obj/item/oreprospector
	name = "geological scanner"
	desc = "A device capable of detecting nearby mineral deposits."
	icon = 'icons/obj/mining.dmi'
	icon_state = "minanal"
	flags = ONBELT
	w_class = 1.0

	attack_self(var/mob/user as mob)
		mining_scan(get_turf(user), user, 6)

/proc/mining_scan(var/turf/T, var/mob/living/L, var/range)
	if (!istype(T) || !istype(L))
		return
	if (!isnum(range) || range < 1)
		range = 6
	var/stone = 0
	var/anomaly = 0
	var/list/ores_found = list()
	var/ore/O
	var/ore/event/E
	for (var/turf/simulated/wall/asteroid/AST in range(T,range))
		stone++
		O = AST.ore
		E = AST.event
		if (O && !(O.name in ores_found))
			ores_found += O.name
		if (E)
			anomaly++
			if (E.scan_decal)
				mining_scandecal(L, AST, E.scan_decal)
	var/found_string = ""
	if (ores_found.len > 0)
		var/list_counter = 1
		for (var/X in ores_found)
			found_string += X
			if (list_counter != ores_found.len)
				found_string += " * "
			list_counter++
	else
		found_string = "None"

	var/rendered = "----------------------------------<br>"
	rendered += "<strong><U>Geological Report:</U></strong><br>"
	rendered += "<strong>Scan Range:</strong> [range] meters<br>"
	rendered += "<strong>M^2 of Mineral in Range:</strong> [stone]<br>"
	rendered += "<strong>Ores Found:</strong> [found_string]<br>"
	rendered += "<strong>Anomalous Readings:</strong> [anomaly]<br>"
	rendered += "----------------------------------"
	boutput(L, rendered)

/proc/mining_scandecal(var/mob/living/user, var/turf/T, var/decalicon)
	if (!user || !T || !decalicon) return
	var/image/O = image('icons/obj/mining.dmi',T,decalicon,AREA_LAYER+1)
	user << O
	spawn (1200)
		del O

/obj/machinery/oreaccumulator
	name = "mineral accumulator"
	desc = "A powerful device for quick ore and salvage collection and movement."
	icon = 'icons/obj/stationobjs.dmi'
	icon_state = "gravgen-off"
	density = 1
	opacity = 0
	anchored = 0
	var/active = 0
	var/cell = null
	var/target = null

	New()
		var/obj/item/cell/P = new/obj/item/cell(src)
		P.charge = P.maxcharge
		cell = P
		..()

	attack_hand(var/mob/user as mob)
		if (!cell) boutput(user, "<span style=\"color:red\">It won't work without a power cell!</span>")
		else
			var/action = input("What do you want to do?", "Mineral Accumulator") in list("Flip the power switch","Change the destination","Remove the power cell")
			if (action == "Remove the power cell")
				var/obj/item/cell/PCEL = cell
				user.put_in_hand_or_drop(PCEL)
				boutput(user, "You remove [cell].")
				PCEL.updateicon()

				cell = null
			else if (action == "Change the destination")
				if (!cargopads.len) boutput(usr, "<span style=\"color:red\">No receivers available.</span>")
				else
					var/selection = input("Select Cargo Pad Location:", "Cargo Pads", null, null) as null|anything in cargopads
					if (!selection)
						return
					var/turf/T = get_turf(selection)
					if (!T)
						boutput(usr, "<span style=\"color:red\">Target not set!</span>")
						return
					boutput(usr, "Target set to [T.loc].")
					target = T
			else if (action == "Flip the power switch")
				if (!active)
					user.visible_message("[user] powers up [src].", "You power up [src].")
					active = 1
					anchored = 1
					icon_state = "gravgen-on"
				else
					user.visible_message("[user] shuts down [src].", "You shut down [src].")
					active = 0
					anchored = 0
					icon_state = "gravgen-off"
			else
				user.visible_message("[user] stares at [src] in confusion!", "You're not sure what that did.")

	attackby(obj/item/W as obj, mob/user as mob)
		if (istype(W,/obj/item/cell))
			if (cell) boutput(user, "<span style=\"color:red\">It already has a power cell inserted!</span>")
			else
				user.drop_item()
				W.set_loc(src)
				cell = W
				user.visible_message("[user] inserts [W] into [src].", "You insert [W] into [src].")
		else ..()

	process()
		var/moved = 0
		if (active)
			if (!cell)
				visible_message("<span style=\"color:red\">[src] instantly shuts itself down.</span>")
				active = 0
				anchored = 0
				icon_state = "gravgen-off"
				return
			var/obj/item/cell/PCEL = cell
			if (PCEL.charge <= 0)
				visible_message("<span style=\"color:red\">[src] runs out of power and shuts down.</span>")
				active = 0
				anchored = 0
				icon_state = "gravgen-off"
				return
			PCEL.charge -= 5
			if (target)
				for (var/obj/item/raw_material/O in orange(1,src))
					if (istype(O,/obj/item/raw_material/rock)) continue
					PCEL.charge -= 2
					O.set_loc(target)
				for (var/obj/item/scrap/S in orange(1,src))
					PCEL.charge -= 2
					S.set_loc(target)
				for (var/obj/decal/cleanable/machine_debris/D in orange(1,src))
					PCEL.charge -= 2
					D.set_loc(target)
				for (var/obj/decal/cleanable/robot_debris/R in orange(1,src))
					PCEL.charge -= 2
					R.set_loc(target)
			for (var/obj/item/raw_material/O in range(6,src))
				if (moved >= 10)
					break
				if (istype(O,/obj/item/raw_material/rock)) continue
				step_towards(O, loc)
				moved++
			for (var/obj/item/scrap/S in range(6,src))
				if (moved >= 10)
					break
				step_towards(S, loc)
				moved++
			for (var/obj/decal/cleanable/machine_debris/D in range(6,src))
				if (moved >= 10)
					break
				step_towards(D, loc)
				moved++
			for (var/obj/decal/cleanable/robot_debris/R in range(6, src))
				if (moved >= 10)
					break
				step_towards(R, loc)
				moved++

var/global/list/cargopads = list()

/obj/submachine/cargopad
	name = "Cargo Pad"
	desc = "Used to receive objects transported by a cargo transporter."
	icon = 'icons/obj/objects.dmi'
	icon_state = "cargopad"
	anchored = 1
	var/active = 1

	podbay
		name = "Pod Bay Pad"
	hydroponic
		name = "Hydroponics Pad"
	robotics
		name = "Robotics Pad"
	artlab
		name = "Artifact Lab Pad"
	engineering
		name = "Engineering Pad"
	mechanics
		name = "Mechanics Pad"
	magnet
		name = "Mineral Magnet Pad"
	miningoutpost
		name = "Mining Outpost Pad"
	qm
		name = "QM Pad"

	New()
		..()
		overlays += image('icons/obj/objects.dmi', "cpad-rec")
		if (name == "Cargo Pad")
			name += " ([rand(100,999)])"
		if (active && !cargopads.Find(src))
			cargopads.Add(src)

	disposing()
		if (cargopads.Find(src))
			cargopads.Remove(src)
		..()

	attack_hand(var/mob/user as mob)
		if (active == 1)
			boutput(user, "You switch the receiver off.")
			overlays = null
			active = 0
			if (cargopads.Find(src))
				cargopads.Remove(src)
		else
			boutput(user, "You switch the receiver on.")
			overlays += image('icons/obj/objects.dmi', "cpad-rec")
			active = 1
			if (!cargopads.Find(src))
				cargopads.Add(src)

/obj/item/satchel/mining
	name = "mining satchel"
	desc = "A leather bag. It holds 0/30 ores."
	icon_state = "miningsatchel"
	allowed = list(/obj/item/raw_material/)
	itemstring = "ores"

	large
		name = "large mining satchel"
		desc = "A leather bag. It holds 0/75 ores."
		maxitems = 75

	compressed
		name = "spatially-compressed mining satchel"
		desc = "A leather bag. It holds 0/500 ores."
		maxitems = 500

/obj/item/ore_scoop
	name = "ore scoop"
	desc = "A device that sucks up ore into a satchel automatically. Just load in a satchel and walk over ore to scoop it up."
	icon = 'icons/obj/mining.dmi'
	icon_state = "scoop"
	inhand_image_icon = 'icons/mob/inhand/hand_tools.dmi'
	item_state = "buildpipe"
	w_class = 2
	mats = 6
	var/obj/item/satchel/mining/satchel = null

	borg
		New()
			..()
			var/obj/item/satchel/mining/large/S = new /obj/item/satchel/mining/large(src)
			satchel = S

	attackby(obj/item/W as obj, mob/user as mob)
		if (istype(W,/obj/item/satchel/mining))
			var/obj/item/satchel/mining/S = W
			if (satchel)
				boutput(user, "<span style=\"color:red\">There's already a satchel hooked up to [src].</span>")
				return
			user.drop_item()
			S.set_loc(src)
			satchel = S
			icon_state = "scoop-bag"
			user.visible_message("[user] inserts [S] into [src].", "You insert [S] into [src].")
		else
			..()
			return

	attack_self(var/mob/user as mob)
		if (!issilicon(user))
			if (satchel)
				user.visible_message("[user] unloads [satchel] from [src].", "You unload [satchel] from [src].")
				satchel.set_loc(get_turf(user))
				satchel = null
				icon_state = "scoop"
			else
				boutput(user, "<span style=\"color:red\">There's no satchel in [src] to unload.</span>")
		else
			boutput(user, "<span style=\"color:red\">The satchel is firmly secured.</span>")

	afterattack(atom/target as mob|obj|turf|area, mob/user as mob, flag)
		if (!isturf(target))
			target = get_turf(target)
		if (!satchel)
			boutput(user, "<span style=\"color:red\">There's no satchel in [src] to dump out.</span>")
			return
		if (satchel.contents.len < 1)
			boutput(user, "<span style=\"color:red\">The satchel in [src] is empty.</span>")
			return
		user.visible_message("[user] dumps out [src]'s satchel contents.", "You dump out [src]'s satchel contents.")
		for (var/obj/item/I in satchel.contents)
			I.set_loc(target)
		satchel.satchel_updateicon()

////// Shit that goes in the asteroid belt, might split it into an exploring.dm later i guess

/turf/simulated/wall/ancient
	name = "strange wall"
	desc = "A weird jet black metal wall indented with strange grooves and lines."
	icon_state = "ancient"

	attackby(obj/item/W as obj, mob/user as mob)
		boutput(usr, "<span class='combat'>You attack [src] with [W] but fail to even make a dent!</span>")
		return

	ex_act(severity)
		if (severity == 1.0)
			if (prob(8))
				opacity = 0
				density = 0
				icon_state = "ancient-b"
				return
		else return

/turf/simulated/floor/ancient
	name = "strange surface"
	desc = "A strange jet black metal floor. There are odd lines carved into it."
	icon_state = "ancient"

	attackby(obj/item/W as obj, mob/user as mob)
		boutput(usr, "<span class='combat'>You attack [src] with [W] but fail to even make a dent!</span>")
		return

	ex_act(severity)
		return

// mining related critters

/obj/critter/rockworm
	name = "rock worm"
	desc = "Tough lithovoric worms."
	icon_state = "rockworm"
	density = 0
	health = 80
	aggressive = 1
	defensive = 0
	wanderer = 1
	opensdoors = 0
	atkcarbon = 0
	atksilicon = 0
	firevuln = 0.1
	brutevuln = 1
	angertext = "hisses at"
	butcherable = 1
	var/eaten = 0

	seek_target()
		anchored = 0
		for (var/obj/item/raw_material/C in view(seekrange,src))
			if (target)
				task = "chasing"
				break
			if ((C.name == oldtarget_name) && (world.time < last_found + 100)) continue
			attack = 1
			if (attack)
				target = C
				oldtarget_name = C.name
				visible_message("<span style=\"color:red\"><strong>[src]</strong> sees [C.name]!</span>")
				task = "chasing"
				break
			else
				continue

	CritterAttack(mob/M)
		attacking = 1

		if (istype(M, /obj/item/raw_material))
			visible_message("<span style=\"color:red\"><strong>[src]</strong> hungrily eats [target]!</span>")
			playsound(loc, "sound/items/eatfood.ogg", 30, 1, -2)
			qdel(target)
			eaten++
			target = null
			task = "thinking"

		attacking = 0
		return

	CritterDeath()
		if (!alive) return
		alive = 0
		target = null
		task = "dead"
		density = 0
		icon_state = "rockworm-dead"
		walk_to(src,0)
		if (eaten >= 10)
			visible_message("<strong>[src]</strong> vomits something up and dies!")
		else
			visible_message("<strong>[src]</strong> dies!")
		var/countstones = 0
		while (eaten)
			countstones++
			if (countstones == 10)
				var/pickgem = rand(1,3)
				switch(pickgem)
					if (1) new /obj/item/raw_material/gemstone(loc)
					if (2) new /obj/item/raw_material/uqill(loc)
					if (3) new /obj/item/raw_material/fibrilith(loc)
				countstones = 0
			eaten--

/obj/critter/fermid
	name = "fermid"
	desc = "Extremely hostile asteroid-dwelling bugs. Best to avoid them wherever possible."
	icon_state = "fermid"
	density = 1
	health = 25
	aggressive = 1
	defensive = 1
	wanderer = 1
	opensdoors = 0
	atkcarbon = 1
	atksilicon = 1
	firevuln = 0.1
	brutevuln = 1
	angertext = "viciously clacks its mandibles at"
	butcherable = 1

	CritterAttack(mob/M)
		if (ismob(M))
			attacking = 1
			if (prob(10) && M.reagents)
				visible_message("<span style=\"color:red\"><strong>[src]</strong> grabs and stings [target]!</span>")
				M.reagents.add_reagent("haloperidol", 10)
				M.reagents.add_reagent("atropine", 10)
			else
				visible_message("<span style=\"color:red\"><strong>[src]</strong> bites [target]!</span>")
				random_brute_damage(target, rand(1,4))
			spawn (8)
				attacking = 0

	ChaseAttack(mob/M)
		if (prob(20))
			visible_message("<span style=\"color:red\"><strong>[src]</strong> dives on [M]!</span>")
			playsound(loc, pick("sound/weapons/thudswoosh.ogg"), 50, 0)
			M.weakened += rand(2,4)
			M.stunned += rand(1,3)
			random_brute_damage(M, rand(2,5))
		else visible_message("<span style=\"color:red\"><strong>[src]</strong> dives at [M], but misses!</span>")


///// MINER TRAITOR ITEM /////

/obj/item/device/chargehacker
	name = "geological scanner"
	desc = "The scanner doesn't look right somehow."
	icon = 'icons/obj/mining.dmi'
	icon_state = "minanal"
	flags = ONBELT
	w_class = 1.0

	attack_self(var/mob/user as mob)
		boutput(user, "The screen is clearly painted on. When you press Scan, a short metal spike extends from the top and sparks brightly before retracting again.")