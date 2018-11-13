#define MAX_QUEUE_LENGTH 20

/obj/machinery/manufacturer
	name = "Manufacturing Unit"
	desc = "A standard fabricator unit capable of producing certain items from various materials."
	icon = 'icons/obj/manufacturer.dmi'
	icon_state = "fab"
	var/icon_base = null
	density = 1
	anchored = 1
	mats = 20
	flags = NOSPLASH
	var/health = 100
	var/mode = "ready"
	var/error = null
	var/speed = 3
	var/repeat = 0
	var/timeleft = 0
	var/manual_stop = 0
	var/panelopen = 0
	var/powconsumption = 0
	var/hacked = 0
	var/malfunction = 0
	var/electrified = 0
	var/accept_blueprints = 1
	var/page = 0 // temporary measure, i want a better UI for this =(
	var/retain_output_internally = -1
	var/dismantle_stage = 0
	var/output_cap = 20
	// 0 is =>, 1 is ==
	var/base_material_class = /obj/item/material_piece/
	var/obj/item/reagent_containers/glass/beaker = null
	var/list/cuttings = list()
	var/area_name = null
	var/output_target = null
	var/list/materials_in_use = list()
	var/list/available = list()
	var/list/download = list()
	var/list/hidden = list()
	var/list/queue = list()
	var/last_queue_op = 0

	var/category = null
	var/list/categories = list("Tool","Clothing","Resource","Component","Machinery","Miscellaneous", "Downloaded")
	var/search = null
	var/wires = 15
	var/image/work_display = null
	var/image/activity_display = null
	var/image/panel_sprite = null
	var/list/free_resources = list()
	var/free_resource_amt = 0
	var/list/nearby_turfs = list()
	var/sound_happy = 'sound/machines/chime.ogg'
	var/sound_grump = 'sound/machines/buzz-two.ogg'
	var/sound_beginwork = 'sound/machines/computerboot_pc.ogg'
	var/sound_damaged = 'sound/effects/grillehit.ogg'
	var/sound_destroyed = 'sound/effects/robogib.ogg'
	power_usage = 200
	var/static/list/sounds_malfunction = list('sound/machines/engine_grump1.ogg','sound/machines/engine_grump2.ogg','sound/machines/engine_grump3.ogg',
	'sound/machines/glitch1.ogg','sound/machines/glitch2.ogg','sound/machines/glitch3.ogg','sound/effects/clang.ogg','sound/effects/bang.ogg','sound/machines/romhack1.ogg','sound/machines/romhack3.ogg')
	var/static/list/text_flipout_adjective = list("an awful","a terrible","a loud","a horrible","a nasty","a horrendous")
	var/static/list/text_flipout_noun = list("noise","racket","ruckus","clatter","commotion","din")
	var/list/text_bad_output_adjective = list("janky","crooked","warped","shoddy","shabby","lousy","crappy","shitty")

#define WIRE_EXTEND 1
#define WIRE_POWER 2
#define WIRE_MALF 3
#define WIRE_SHOCK 4

	New()
		..()
		src.area_name = src.loc.loc.name

		if (istype(manuf_controls,/manufacturing_controller))
			set_up_schematics()
			manuf_controls.manufacturing_units += src

		for (var/turf/T in view(5,src))
			nearby_turfs += T

		var/reagents/R = new/reagents(1000)
		reagents = R
		R.maximum_volume = 1000
		R.my_atom = src

		work_display = image('icons/obj/manufacturer.dmi', "")
		activity_display = image('icons/obj/manufacturer.dmi', "")
		panel_sprite = image('icons/obj/manufacturer.dmi', "")
		spawn (0)
			build_icon()

	disposing()
		manuf_controls.manufacturing_units -= src
		work_display = null
		activity_display = null
		panel_sprite = null
		output_target = null
		beaker = null
		available = list()
		download = list()
		hidden = list()
		queue = list()
		nearby_turfs = list()
		sound_happy = null
		sound_grump = null
		sound_beginwork = null
		sound_damaged = null
		sound_destroyed = null

		for (var/obj/O in contents)
			O.loc = loc
		for (var/mob/M in contents)
			// unlikely as this is to happen we might as well make sure everything is purged
			M.loc = loc

		..()

	examine()
		..()
		if (health < 100)
			if (health < 50)
				boutput(usr, "<span style=\"color:red\">It's rather badly damaged. It probably needs some wiring replaced inside.</span>")
			else
				boutput(usr, "<span style=\"color:red\">It's a bit damaged. It looks like it needs some welding done.</span>")
		if	(stat & BROKEN)
			boutput(usr, "<span style=\"color:red\">It seems to be damaged beyond the point of operability.</span>")
		if	(stat & NOPOWER)
			boutput(usr, "<span style=\"color:red\">It seems to be offline.</span>")
		switch(dismantle_stage)
			if (1)
				boutput(usr, "<span style=\"color:red\">It's partially dismantled. To deconstruct it, use a crowbar. To repair it, use a wrench.</span>")
			if (2)
				boutput(usr, "<span style=\"color:red\">It's partially dismantled. To deconstruct it, use wirecutters. To repair it, add reinforced metal.</span>")
			if (3)
				boutput(usr, "<span style=\"color:red\">It's partially dismantled. To deconstruct it, use a wrench. To repair it, add some cable.</span>")

	process()
		if (stat & NOPOWER)
			return

		power_usage = powconsumption + 200
		..()
		if (mode == "working")
			if (malfunction && prob(8))
				flip_out()
			timeleft -= speed * 2
			use_power(powconsumption)
			if (timeleft < 1)
				output_loop(queue[1])
				spawn (0)
					if (queue.len < 1)
						manual_stop = 0
						playsound(loc, sound_happy, 50, 1)
						visible_message("<span style=\"color:blue\">[src] finishes its production queue.</span>")
						mode = "ready"
						build_icon()

		if (electrified > 0)
			electrified--

	ex_act(severity)
		switch(severity)
			if (1.0)
				for (var/atom/movable/A as mob|obj in src)
					A.set_loc(loc)
					A.ex_act(severity)
				take_damage(rand(100,120))
			if (2.0)
				take_damage(rand(40,80))
			if (3.0)
				take_damage(rand(20,40))
		return

	blob_act(var/power)
		take_damage(rand(power * 0.5, power * 1.5))

	meteorhit()
		take_damage(rand(15,45))

	emp_act()
		take_damage(rand(5,10))
		malfunction = 1
		flip_out()

	bullet_act(var/obj/projectile/P)
		// swiped from guardbot.dm
		var/damage = 0
		damage = round(((P.power/6)*P.proj_data.ks_ratio), 1.0)

		if (material) material.triggerOnAttacked(src, P.shooter, src, (ismob(P.shooter) ? P.shooter:equipped() : P.shooter))
		for (var/atom/A in src)
			if (A.material)
				A.material.triggerOnAttacked(A, P.shooter, src, (ismob(P.shooter) ? P.shooter:equipped() : P.shooter))

		if (!damage)
			return
		if (P.proj_data.damage_type == D_KINETIC || (P.proj_data.damage_type == D_ENERGY && damage))
			take_damage(damage / 2)
		else if (P.proj_data.damage_type == D_PIERCING)
			take_damage(damage)

	power_change()
		if (stat & BROKEN)
			build_icon()
		else
			if (powered() && dismantle_stage < 3)
				stat &= ~NOPOWER
				build_icon()
			else
				spawn (rand(0, 15))
					stat |= NOPOWER
					build_icon()

	attack_hand(var/mob/user as mob)
		if (electrified != 0)
			if (!(stat & NOPOWER || stat & BROKEN))
				if (manuf_zap(user, 33))
					return

		user.machine = src
		var/dat = "<strong>[name]</strong>"
		//dat += "<A href='?src=\ref[src];shake=0'>(shake)</A>"

		if (panelopen)
			var/list/manuwires = list(
			"Amber" = 1,
			"Teal" = 2,
			"Indigo" = 3,
			"Lime" = 4,
			)
			var/pdat = "<strong>[src] Maintenance Panel</strong><hr>"
			for (var/wiredesc in manuwires)
				var/is_uncut = wires & APCWireColorToFlag[manuwires[wiredesc]]
				pdat += "[wiredesc] wire: "
				if (!is_uncut)
					pdat += "<a href='?src=\ref[src];cutwire=[manuwires[wiredesc]]'>Mend</a>"
				else
					pdat += "<a href='?src=\ref[src];cutwire=[manuwires[wiredesc]]'>Cut</a> "
					pdat += "<a href='?src=\ref[src];pulsewire=[manuwires[wiredesc]]'>Pulse</a> "
				pdat += "<br>"

			pdat += "<br>"
			if (stat & BROKEN || stat & NOPOWER)
				pdat += "The yellow light is off.<BR>"
				pdat += "The blue light is off.<BR>"
				pdat += "The white light is off.<BR>"
				pdat += "The red light is off.<BR>"
			else
				pdat += "The yellow light is [(electrified == 0) ? "off" : "on"].<BR>"
				pdat += "The blue light is [malfunction ? "flashing" : "on"].<BR>"
				pdat += "The white light is [hacked ? "on" : "off"].<BR>"
				pdat += "The red light is on.<BR>"

			user << browse(pdat, "window=manupanel")
			onclose(user, "manupanel")

		if (stat & BROKEN || stat & NOPOWER)
			dat = "The screen is blank."
			user << browse(dat, "window=manufact;size=400x500")
			onclose(user, "manufact")
			return

		if (error)
			dat += "<br><font face=\"fixedsys\" size=\"2\" color=\"#FF0000\"><strong>ERROR: [error]</strong></font>"
		if (mode == "halt")
			dat += "<br><A href='?src=\ref[src];continue=1'><u><strong>Resume Production</strong></u></a>"
		else if (mode == "working")
			var/manufacture/M = queue[1]
			if (istype(M,/manufacture))
				var/TL = timeleft
				if (speed != 0)
					TL = round(TL / speed)
				dat += "<br><small>Current: [M.name] (ETC: [TL]) | <A href='?src=\ref[src];pause=1'><u><strong>Pause</strong></u></a></small>"

		dat += build_control_panel()
		dat += "<br>"
		dat += build_material_list()

		dat += "</small><HR>"

		if (!page)
			dat += "<strong>Available Schematics</strong><br>"
			if (istext(search))
				dat += " <small>(Search: \"[html_encode(search)]\")</small>"
			if (istext(category))
				dat += " <small>(Filter: \"[html_encode(category)]\")</small>"

			dat += "<small>"
			if (category != "Downloaded")
				for (var/manufacture/A in available)
					if (istext(search) && !findtext(A.name, search, 1, null))
						continue
					else if (istext(category) && category != A.category)
						continue
					dat += "<BR><A href='?src=\ref[src];disp=\ref[A]'><strong><u>[A.name]</u></strong></A> "
					if (istext(A.category))
						dat += "([A.category])"
					dat += "<br>"
					var/list_count = 1
					for (var/X in A.item_paths)
						if (list_count != 1) dat += ", "
						dat += "[A.item_amounts[list_count]] [A.item_names[list_count]]"
						list_count++
					if (A.time == 0 || speed == 0)
						dat += "<br><strong>Time:</strong> ERROR<br>"
					else
						dat += "<br><strong>Time:</strong> [round((A.time / speed))] Seconds<br>"

				if (hacked)
					for (var/manufacture/A in hidden)
						if (istext(search) && !findtext(A.name, search, 1, null))
							continue
						else if (istext(category) && category != A.category)
							continue
						dat += "<BR><A href='?src=\ref[src];disp=\ref[A]'><strong><u>[A.name]</u></strong></A> "
						if (istext(A.category))
							dat += "([A.category]) "
						dat += "(Secret)<br>"
						var/list_count = 1
						for (var/X in A.item_paths)
							if (list_count != 1) dat += ", "
							dat += "[A.item_amounts[list_count]] [A.item_names[list_count]]"
							list_count++
						if (A.time == 0 || speed == 0)
							dat += "<br><strong>Time:</strong> ERROR<br>"
						else
							dat += "<br><strong>Time:</strong> [round((A.time / speed))] Seconds<br>"

			for (var/manufacture/A in download)
				if (istext(search) && !findtext(A.name, search, 1, null))
					continue
				else if (istext(category))
					if (category != "Downloaded" && category != A.category)
						continue
				dat += "<BR><A href='?src=\ref[src];disp=\ref[A]'><strong><u>[A.name]</u></strong></A> "
				if (istext(A.category))
					dat += "([A.category]) "
				dat += "(Downloaded)<br>"
				var/list_count = 1
				for (var/X in A.item_paths)
					if (list_count != 1) dat += ", "
					dat += "[A.item_amounts[list_count]] [A.item_names[list_count]]"
					list_count++
				if (A.time == 0 || speed == 0)
					dat += "<br><strong>Time:</strong> ERROR<br>"
				else
					dat += "<br><strong>Time:</strong> [round((A.time / speed))] Seconds<br>"
			dat += "</small>"


		else if (page == 1)
			dat += "<strong>Production Queue</strong> <A href='?src=\ref[src];clearQ=1'>(Clear)</A>"
			if (queue.len > 0)
				var/queue_num = 1
				var/cumulative_time = 0
				var/_timeleft = timeleft
				var/manufacture/M = queue[1]
				if (istype(M,/manufacture) && speed != 0 && _timeleft != 0)
					_timeleft = round(_timeleft / speed)
				cumulative_time = _timeleft
				for (var/manufacture/A in queue)
					if (queue_num == 1)
						dat += "<BR><small><strong><u>Current Production: [A.name] (ETC: [_timeleft])</strong></u></A>"
						if (mode != "working")
							dat += " <A href='?src=\ref[src];removefromQ=[queue_num]'>(Remove)</A>"
					else
						if (speed != 0)
							cumulative_time += round(A.time / speed)
						else
							cumulative_time += A.time
						dat += "<BR>[queue_num]) [A.name] (ETC: [cumulative_time]) <A href='?src=\ref[src];removefromQ=[queue_num]'>(Remove)</A>"
					queue_num++
			else
				dat += "<BR>Queue is empty."

		dat += "<hr>"

		user << browse(dat, "window=manufact;size=450x500")
		onclose(user, "manufact")

	Topic(href, href_list)

		if (!(href_list["cutwire"] || href_list["pulsewire"]))
			if (stat & BROKEN || stat & NOPOWER)
				return

		if (usr.stat || usr.restrained())
			return

		if (electrified != 0)
			if (!(stat & NOPOWER || stat & BROKEN))
				if (manuf_zap(usr, 10))
					return

		if ((usr.contents.Find(src) || ((get_dist(src, usr) <= 1) && istype(loc, /turf))))
			usr.machine = src

			if (malfunction && prob(10))
				flip_out()

			//if (href_list["shake"])
			//	flip_out()

			if (href_list["eject"])
				if (mode != "ready")
					boutput(usr, "<span style=\"color:red\">You cannot eject materials while the unit is working.</span>")
				else
					var/mat_name = href_list["eject"]
					var/ejectamt = 0
					var/turf/ejectturf = get_turf(usr)
					for (var/obj/item/O in contents)
						if (O.material && O.material.mat_id == mat_name)
							if (!ejectamt)
								ejectamt = input(usr,"How many units do you want to eject?","Eject Materials") as num
								if (ejectamt <= 0 || mode != "ready" || get_dist(src, usr) > 1)
									break
							if (!ejectturf)
								break
							O.set_loc(get_output_location(O,1))
							ejectamt--
							if (ejectamt <= 0)
								break

			if (href_list["speed"])
				if (mode == "working")
					boutput(usr, "<span style=\"color:red\">You cannot alter the speed setting while the unit is working.</span>")
				else
					var/upperbound = 3
					if (hacked)
						upperbound = 5
					var/newset = input(usr,"Enter from 1 to [upperbound]. Higher settings consume more power","Manufacturing Speed") as num
					newset = max(1,min(newset,upperbound))
					speed = newset

			if (href_list["clearQ"])
				var/Qcounter = 1
				for (var/manufacture/M in queue)
					if (Qcounter == 1 && mode == "working") continue
					queue -= queue[Qcounter]
				if (mode == "halt")
					manual_stop = 0
					error = null
					mode = "ready"
					build_icon()

			if (href_list["removefromQ"])
				var/operation = text2num(href_list["removefromQ"])
				if (!isnum(operation) || queue.len < 1 || operation > queue.len)
					boutput(usr, "<span style=\"color:red\">Invalid operation.</span>")
					return

				if (world.time < last_queue_op + 5) //Anti-spam to prevent people lagging the server with autoclickers
					return
				else
					last_queue_op = world.time

				queue -= queue[operation]
				if (queue.len == 0)
					manual_stop = 0
					error = null
					mode = "ready"
					build_icon()

			if (href_list["page"])
				var/operation = text2num(href_list["page"])
				page = operation

			if (href_list["repeat"])
				repeat = !repeat

			if (href_list["internalize"])
				if (retain_output_internally < 0)
					boutput(usr, "<span style=\"color:red\">This unit does not feature that function.</span>")
				else
					retain_output_internally = !retain_output_internally

			if (href_list["search"])
				search = input("Enter text to search for in schematics.","Manufacturing Unit") as null|text
				if (lentext(search) == 0)
					search = null

			if (href_list["category"])
				category = input("Select which category to filter by.","Manufacturing Unit") as null|anything in categories

			if (href_list["continue"])
				if (queue.len < 1)
					boutput(usr, "<span style=\"color:red\">Cannot find any items in queue to continue production.</span>")
					return
				if (isnull(material_check(queue[1])))
					boutput(usr, "<span style=\"color:red\">Insufficient usable materials to manufacture first item in queue.</span>")
				else
					begin_work(0)

			if (href_list["pause"])
				mode = "halt"
				build_icon()

			if (href_list["disp"])
				var/manufacture/I = locate(href_list["disp"])
				if (!istype(I,/manufacture))
					return
				if (world.time < last_queue_op + 5) //Anti-spam to prevent people lagging the server with autoclickers
					return
				else
					last_queue_op = world.time

				if (isnull(material_check(I)))
					boutput(usr, "<span style=\"color:red\">Insufficient usable materials to manufacture that item.</span>")
				else if (queue.len >= MAX_QUEUE_LENGTH)
					boutput(usr, "<span style=\"color:red\">Manufacturer queue length limit reached.</span>")
				else
					queue += I
					if (mode == "ready")
						begin_work(1)
						updateUsrDialog()

				if (queue.len > 0 && mode == "ready")
					begin_work(1)
					updateUsrDialog()
					return

			/*if (href_list["delete"])
				var/manufacture/I = locate(href_list["disp"])
				if (!istype(I,/manufacture/mechanics))
					boutput(usr, "<span style=\"color:red\">Cannot delete this schematic.</span>")
					return
				download -= I*/

			if (href_list["ejectbeaker"])
				var/obj/item/reagent_containers/glass/beaker/B = locate(href_list["ejectbeaker"])
				if (!istype(B,/obj/item/reagent_containers/glass/beaker))
					return
				beaker.set_loc(get_output_location(B,1))
				beaker = null

			if (href_list["transto"])
				// reagents are going into beaker
				var/obj/item/reagent_containers/glass/beaker/B = locate(href_list["transto"])
				if (!istype(B,/obj/item/reagent_containers/glass/beaker))
					return
				var/howmuch = input("Transfer how much to [B]?","[name]",B.reagents.maximum_volume - B.reagents.total_volume) as null|num
				if (!howmuch || !B || B != beaker )
					return
				reagents.trans_to(B,howmuch)

			if (href_list["transfrom"])
				// reagents are being drawn from beaker
				var/obj/item/reagent_containers/glass/beaker/B = locate(href_list["transfrom"])
				if (!istype(B,/obj/item/reagent_containers/glass/beaker))
					return
					return
				var/howmuch = input("Transfer how much from [B]?","[name]",B.reagents.total_volume) as null|num
				if (!howmuch)
					return
				B.reagents.trans_to(src,howmuch)

			if (href_list["flush"])
				var/the_reagent = href_list["flush"]
				if (!istext(the_reagent))
					return
				var/howmuch = input("Flush how much [the_reagent]?","[name]",0) as null|num
				if (!howmuch)
					return
				reagents.remove_reagent(the_reagent,howmuch)

			if ((href_list["cutwire"]) && (panelopen))
				if (electrified)
					if (manuf_zap(usr, 100))
						return
				var/twire = text2num(href_list["cutwire"])
				if (!( istype(usr.equipped(), /obj/item/wirecutters) ))
					boutput(usr, "You need wirecutters!")
					return
				else if (isWireColorCut(twire))
					mend(twire)
				else
					cut(twire)
				build_icon()

			if ((href_list["pulsewire"]) && (panelopen))
				var/twire = text2num(href_list["pulsewire"])
				if (!istype(usr.equipped(), /obj/item/device/multitool))
					boutput(usr, "You need a multitool!")
					return
				else if (isWireColorCut(twire))
					boutput(usr, "You can't pulse a cut wire.")
					return
				else
					pulse(twire)
				build_icon()

			updateUsrDialog()
		return

	emag_act(var/mob/user, var/obj/item/card/emag/E)
		if (!hacked)
			hacked = 1
			if (user)
				boutput(user, "<span style=\"color:blue\">You remove the [src]'s product locks!</span>")
			return TRUE
		return FALSE

	attackby(obj/item/W as obj, mob/user as mob)
		if (electrified)
			if (manuf_zap(usr, 33))
				return

		if (istype(W, /obj/item/paper/manufacturer_blueprint))
			if (!accept_blueprints)
				boutput(user, "<span style=\"color:red\">This manufacturer unit does not accept blueprints.</span>")
				return
			var/obj/item/paper/manufacturer_blueprint/BP = W
			if (malfunction && prob(75))
				visible_message("<span style=\"color:red\">[src] emits a [pick(text_flipout_adjective)] [pick(text_flipout_noun)]!</span>")
				playsound(loc, pick(sounds_malfunction), 50, 1)
				boutput(user, "<span style=\"color:red\">The manufacturer mangles and ruins the blueprint in the scanner! What the fuck?</span>")
				qdel(BP)
				return
			if (!BP.blueprint)
				visible_message("<span style=\"color:red\">[src] emits a grumpy buzz!</span>")
				playsound(loc, sound_grump, 50, 1)
				boutput(user, "<span style=\"color:red\">The manufacturer rejects the blueprint. Is something wrong with it?</span>")
				return
			for (var/manufacture/M in (available + download))
				if (BP.blueprint.name == M.name)
					visible_message("<span style=\"color:red\">[src] emits an irritable buzz!</span>")
					playsound(loc, sound_grump, 50, 1)
					boutput(user, "<span style=\"color:red\">The manufacturer rejects the blueprint, as it already knows it.</span>")
					return
			BP.dropped()
			download += BP.blueprint
			visible_message("<span style=\"color:red\">[src] emits a pleased chime!</span>")
			playsound(loc, sound_happy, 50, 1)
			boutput(user, "<span style=\"color:blue\">The manufacturer accepts and scans the blueprint.</span>")
			qdel(BP)
			return

		else if (istype(W, /obj/item/satchel))
			user.visible_message("<span style=\"color:blue\">[user] uses [src]'s automatic loader on [W]!</span>", "<span style=\"color:blue\">You use [src]'s automatic loader on [W].</span>")
			var/amtload = 0
			for (var/obj/item/M in W.contents)
				if (!istype(M,base_material_class))
					continue
				load_item(M)
				amtload++
			W:satchel_updateicon()
			if (amtload) boutput(user, "<span style=\"color:blue\">[amtload] materials loaded from [W]!</span>")
			else boutput(user, "<span style=\"color:red\">No materials loaded!</span>")

		else if (istype(W, /obj/item/screwdriver))
			if (!panelopen)
				panelopen = 1
			else
				panelopen = 0
			boutput(user, "You [panelopen ? "open" : "close"] the maintenance panel.")
			build_icon()

		else if (istype(W,/obj/item/weldingtool))
			var/obj/item/weldingtool/WELD = W
			var/do_action = 0
			if (istype(WELD,base_material_class) && accept_loading(user))
				if (alert(user,"What do you want to do with [WELD]?","[name]","Repair","Load it in") == "Load it in")
					do_action = 1
			if (do_action == 1)
				user.visible_message("<span style=\"color:blue\">[user] loads [WELD] into the [src].</span>", "<span style=\"color:blue\">You load [WELD] into the [src].</span>")
				load_item(WELD,user)
			else
				if (health < 50)
					boutput(user, "<span style=\"color:red\">It's too badly damaged. You'll need to replace the wiring first.</span>")
				else
					if (WELD.get_fuel() > 1)
						take_damage(-10)
						WELD.use_fuel(1)
						user.visible_message("<strong>[user]</strong> uses [WELD] to repair some of [src]'s damage.")
						playsound(loc, "sound/items/Welder.ogg", 50, 1)
						if (health == 100)
							boutput(user, "<span style=\"color:blue\"><strong>[src] looks fully repaired!</strong></span>")
					else
						boutput(user, "<span style=\"color:red\">[WELD] needs more fuel to do that.</span>")

		else if (istype(W,/obj/item/cable_coil) && panelopen)
			var/obj/item/cable_coil/C = W
			var/do_action = 0
			if (istype(C,base_material_class) && accept_loading(user))
				if (alert(user,"What do you want to do with [C]?","[name]","Repair","Load it in") == "Load it in")
					do_action = 1
			if (do_action == 1)
				user.visible_message("<span style=\"color:blue\">[user] loads [C] into the [src].</span>", "<span style=\"color:blue\">You load [C] into the [src].</span>")
				load_item(C,user)
			else
				if (health >= 50)
					boutput(user, "<span style=\"color:red\">The wiring is fine. You need to weld the external plating to do further repairs.</span>")
				else
					C.use(1)
					take_damage(-10)
					user.visible_message("<strong>[user]</strong> uses [C] to repair some of [src]'s cabling.")
					playsound(loc, "sound/items/Deconstruct.ogg", 50, 1)
					if (health >= 50)
						boutput(user, "<span style=\"color:blue\">The wiring is fully repaired. Now you need to weld the external plating.</span>")

		else if (istype(W,/obj/item/wrench))
			var/do_action = 0
			if (istype(W,base_material_class) && accept_loading(user))
				if (alert(user,"What do you want to do with [W]?","[name]","Dismantle/Construct","Load it in") == "Load it in")
					do_action = 1
			if (do_action == 1)
				user.visible_message("<span style=\"color:blue\">[user] loads [W] into the [src].</span>", "<span style=\"color:blue\">You load [W] into the [src].</span>")
				load_item(W,user)
			else
				playsound(loc, "sound/items/Ratchet.ogg", 50, 1)
				if (dismantle_stage == 0)
					user.visible_message("<strong>[user]</strong> loosens [src]'s external plating bolts.")
					dismantle_stage = 1
				else if (dismantle_stage == 1)
					user.visible_message("<strong>[user]</strong> fastens [src]'s external plating bolts.")
					dismantle_stage = 0
				else if (dismantle_stage == 3)
					user.visible_message("<strong>[user]</strong> dismantles [src]'s mechanisms.")
					new /obj/item/sheet/steel/reinforced(loc)
					qdel(src)
					return
				build_icon()

		else if (istype(W,/obj/item/crowbar) && dismantle_stage == 1)
			user.visible_message("<strong>[user]</strong> pries off [src]'s plating.")
			playsound(loc, "sound/items/Crowbar.ogg", 50, 1)
			dismantle_stage = 2
			new /obj/item/sheet/steel/reinforced(loc)
			build_icon()

		else if (istype(W,/obj/item/wirecutters) && dismantle_stage == 2)
			if (!(stat & NOPOWER))
				if (manuf_zap(user,100))
					return
			user.visible_message("<strong>[user]</strong> disconnects [src]'s cabling.")
			playsound(loc, "sound/items/Wirecutter.ogg", 50, 1)
			dismantle_stage = 3
			stat |= NOPOWER
			var/obj/item/cable_coil/cut/C = new /obj/item/cable_coil/cut(loc)
			C.amount = 1
			build_icon()

		else if (istype(W,/obj/item/sheet/steel/reinforced) && dismantle_stage == 2)
			user.visible_message("<strong>[user]</strong> adds plating to [src].")
			dismantle_stage = 1
			qdel(W)
			build_icon()

		else if (istype(W,/obj/item/cable_coil) && dismantle_stage == 3)
			user.visible_message("<strong>[user]</strong> adds cabling to [src].")
			dismantle_stage = 2
			qdel(W)
			stat &= ~NOPOWER
			manuf_zap(user,100)
			build_icon()

		else if (istype(W,/obj/item/reagent_containers/glass))
			if (beaker)
				boutput(user, "<span style=\"color:red\">There's already a receptacle in the machine. You need to remove it first.</span>")
			else
				boutput(user, "<span style=\"color:blue\">You insert [W].</span>")
				W.set_loc(src)
				beaker = W
				if (user && W)
					user.u_equip(W)
					W.dropped()

		else if (istype(W, base_material_class) && accept_loading(user))
			user.visible_message("<span style=\"color:blue\">[user] loads [W] into the [src].</span>", "<span style=\"color:blue\">You load [W] into the [src].</span>")
			load_item(W,user)

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
				if (damage >= 5)
					take_damage(damage)

		updateUsrDialog()

	MouseDrop(over_object, src_location, over_location)
		if (!istype(usr,/mob/living))
			boutput(usr, "<span style=\"color:red\">Only living mobs are able to set the manufacturer's output target.</span>")
			return

		if (get_dist(over_object,src) > 1)
			boutput(usr, "<span style=\"color:red\">The manufacturing unit is too far away from the target!</span>")
			return

		if (get_dist(over_object,usr) > 1)
			boutput(usr, "<span style=\"color:red\">You are too far away from the target!</span>")
			return

		if (istype(over_object,/obj/storage/crate))
			var/obj/storage/crate/C = over_object
			if (C.locked || C.welded)
				boutput(usr, "<span style=\"color:red\">You can't use a currently unopenable crate as an output target.</span>")
			else
				output_target = over_object
				boutput(usr, "<span style=\"color:blue\">You set the manufacturer to output to [over_object]!</span>")

		else if (istype(over_object,/obj/machinery/manufacturer))
			var/obj/machinery/manufacturer/M = over_object
			if (M.stat & BROKEN || M.stat & NOPOWER || M.dismantle_stage > 0)
				boutput(usr, "<span style=\"color:red\">You can't use a non-functioning manufacturer as an output target.</span>")
			else
				output_target = M
				boutput(usr, "<span style=\"color:blue\">You set the manufacturer to output to [over_object]!</span>")

		else if (istype(over_object,/obj/table/) && istype(over_object,/obj/rack))
			var/obj/O = over_object
			output_target = O.loc
			boutput(usr, "<span style=\"color:blue\">You set the manufacturer to output on top of [O]!</span>")

		else if (istype(over_object,/turf/simulated/floor))
			output_target = over_object
			boutput(usr, "<span style=\"color:blue\">You set the manufacturer to output to [over_object]!</span>")

		else
			boutput(usr, "<span style=\"color:red\">You can't use that as an output target.</span>")
		return

	MouseDrop_T(atom/movable/O as mob|obj, mob/user as mob)
		if (!O || !user)
			return

		if (!istype(user,/mob/living))
			boutput(user, "<span style=\"color:red\">Only living mobs are able to use the manufacturer's quick-load feature.</span>")
			return

		if (!istype(O,/obj))
			boutput(user, "<span style=\"color:red\">You can't quick-load that.</span>")
			return

		if (get_dist(O,user) > 1)
			boutput(user, "<span style=\"color:red\">You are too far away!</span>")
			return


		if (istype(O, /obj/item/paper/manufacturer_blueprint))
			attackby(O, user)
		else if (istype(O, /obj/storage/crate) && accept_loading(user,1))
			if (O:welded || O:locked)
				boutput(user, "<span style=\"color:red\">You cannot load from a crate that cannot open!</span>")
				return

			user.visible_message("<span style=\"color:blue\">[user] uses [src]'s automatic loader on [O]!</span>", "<span style=\"color:blue\">You use [src]'s automatic loader on [O].</span>")
			var/amtload = 0
			for (var/obj/item/M in O.contents)
				if (!istype(M,base_material_class))
					continue
				load_item(M)
				amtload++
			if (amtload) boutput(user, "<span style=\"color:blue\">[amtload] materials loaded from [O]!</span>")
			else boutput(user, "<span style=\"color:red\">No material loaded!</span>")

		else if (istype(O, /obj/item) && accept_loading(user,1))
			user.visible_message("<span style=\"color:blue\">[user] begins quickly stuffing materials into [src]!</span>")
			var/staystill = user.loc
			for (var/obj/item/M in view(1,user))
				if (!O)
					continue
				if (!istype(M,O.type))
					continue
				if (!istype(M,base_material_class))
					continue
				if (O.loc == user)
					continue
				if (O in user.contents)
					continue
				load_item(M)
				sleep(0.5)
				if (user.loc != staystill) break
			boutput(user, "<span style=\"color:blue\">You finish stuffing materials into [src]!</span>")

		else ..()

		updateUsrDialog()

	proc/accept_loading(var/mob/user,var/allow_silicon = 0)
		if (!user)
			return FALSE
		if (stat & BROKEN || stat & NOPOWER)
			return FALSE
		if (dismantle_stage > 0)
			return FALSE
		if (!istype(user, /mob/living))
			return FALSE
		if (istype(user, /mob/living/silicon) && !allow_silicon)
			return FALSE
		var/mob/living/L = user
		if (L.stat || L.transforming)
			return FALSE
		return TRUE

	proc/isWireColorCut(var/wireColor)
		var/wireFlag = APCWireColorToFlag[wireColor]
		return ((wires & wireFlag) == 0)

	proc/isWireCut(var/wireIndex)
		var/wireFlag = APCIndexToFlag[wireIndex]
		return ((wires & wireFlag) == 0)

	proc/cut(var/wireColor)
		var/wireFlag = APCWireColorToFlag[wireColor]
		var/wireIndex = APCWireColorToIndex[wireColor]
		wires &= ~wireFlag
		switch(wireIndex)
			if (WIRE_EXTEND)
				hacked = 0
			if (WIRE_SHOCK)
				electrified = -1
			if (WIRE_MALF)
				malfunction = 1
			if (WIRE_POWER)
				if (!(stat & BROKEN || stat & NOPOWER))
					manuf_zap(usr,100)
					stat |= NOPOWER

	proc/mend(var/wireColor)
		var/wireFlag = APCWireColorToFlag[wireColor]
		var/wireIndex = APCWireColorToIndex[wireColor] //not used in this function
		wires |= wireFlag
		switch(wireIndex)
			if (WIRE_SHOCK)
				electrified = 0
			if (WIRE_MALF)
				malfunction = 0
			if (WIRE_POWER)
				if (!(stat & BROKEN) && (stat & NOPOWER))
					manuf_zap(usr,100)
					stat &= ~NOPOWER

	proc/pulse(var/wireColor)
		var/wireIndex = APCWireColorToIndex[wireColor]
		switch(wireIndex)
			if (WIRE_EXTEND)
				hacked = !hacked
			if (WIRE_SHOCK)
				electrified = 30
			if (WIRE_MALF)
				malfunction = !malfunction
			if (WIRE_POWER)
				if (!(stat & BROKEN || stat & NOPOWER))
					manuf_zap(usr,100)

	proc/manuf_zap(mob/user, prb)
		if (istype(user, /mob/living/silicon))
			return FALSE
		if (!prob(prb))
			return FALSE
		if (stat & (BROKEN|NOPOWER))
			return FALSE
		if (istype(user, /mob/living/carbon/human))
			if (istype(user:gloves, /obj/item/clothing/gloves/yellow))
				return FALSE

		var/netnum = 0
		for (var/turf/T in range(1, user))
			for (var/obj/cable/C in T.contents)
				netnum = C.netnum
				break
			if (netnum) break

		if (!netnum) return FALSE

		if (electrocute(user,prb,netnum))
			return TRUE
		else
			return FALSE

	proc/add_schematic(var/schematic_path,var/add_to_list = "available")
		if (!ispath(schematic_path))
			return

		var/manufacture/S = get_schematic_from_path(schematic_path)
		if (!istype(S,/manufacture))
			return

		switch(add_to_list)
			if ("hidden")
				hidden += S
			if ("download")
				download += S
			else
				available += S

	proc/set_up_schematics()
		for (var/X in available)
			if (ispath(X))
				add_schematic(X)
				available -= X

		for (var/X in hidden)
			if (ispath(X))
				add_schematic(X,"hidden")
				hidden -= X

	proc/match_material_pattern(pattern, material/mat)
		if (!mat) // Marq fix for various cannot read null. runtimes
			return FALSE

		if (pattern == "ALL") // anything at all
			return TRUE
		else if (copytext(pattern, 4, 5) == "-") // wildcard
			var/firstpart = copytext(pattern, 1, 4)
			var/secondpart = copytext(pattern, 5)
			switch(firstpart)
				// this was kind of thrown together in a panic when i felt shitty so if its horrible
				// go ahead and clean it up a bit
				if ("MET")
					if (mat.material_flags & MATERIAL_METAL)
						// maux hardness = 15
						// bohr hardness = 33
						switch(secondpart)
							if (2)
								return mat.getProperty(PROP_HARDNESS) >= 15
							if (3 to INFINITY)
								return mat.getProperty(PROP_HARDNESS) >= 30
							else
								return TRUE
				if ("CRY")
					return (mat.material_flags & MATERIAL_CRYSTAL) == MATERIAL_CRYSTAL
				if ("CON")
					switch(secondpart)
						if (2)
							return (mat.getProperty(PROP_ELECTRICAL) >= 75)  || (mat.material_flags & MATERIAL_METAL)
						else
							return (mat.getProperty(PROP_ELECTRICAL) >= 50) || (mat.material_flags & MATERIAL_METAL)
				if ("INS")
					switch(secondpart)
						if (2)
							return mat.getProperty(PROP_ELECTRICAL) <= 20 || (mat.material_flags & MATERIAL_CLOTH ) || (mat.material_flags & MATERIAL_RUBBER)
						else
							return mat.getProperty(PROP_ELECTRICAL) <= 47 || (mat.material_flags & MATERIAL_CLOTH) || (mat.material_flags & MATERIAL_RUBBER)
				if ("DEN")
					return mat.getProperty(PROP_HARDNESS) >= 30   || (mat.material_flags & MATERIAL_CRYSTAL)
				if ("POW")
					if (mat.material_flags & MATERIAL_ENERGY)
						switch(secondpart)
							if (2)
								return mat.getProperty(PROP_ENERGY) >= 10
							else
								return TRUE
				if ("FAB")
					return mat.material_flags & MATERIAL_CLOTH || mat.material_flags & MATERIAL_RUBBER || mat.material_flags & MATERIAL_ORGANIC
		else if (pattern == mat.mat_id) // specific material id
			return TRUE
		return FALSE

	proc/material_check(manufacture/M)
		var/list/usable = contents
		var/list/materials = list()
		var/list/usable_materials = cuttings.Copy()
		materials.len = M.item_paths.len
		for (var/obj/item/I in usable)
			if (istype(I, base_material_class) && I.material)
				usable_materials[I.material.mat_id] += 10

		for (var/i = 1; i <= M.item_paths.len; i++)
			var/pattern = M.item_paths[i]
			var/amount = M.item_amounts[i]
			if (ispath(pattern))
				for (var/j = 0; j < amount; j++)
					var/obj/O = locate(pattern) in usable
					if (O)
						usable -= O
					else
						return
			else
				var/found = 0
				for (var/mat_id in usable_materials)
					var/available = usable_materials[mat_id]
					if (available < amount)
						continue
					var/material/mat = getCachedMaterial(mat_id)
					if (match_material_pattern(pattern, mat))
						materials[i] = mat_id
						found = 1
						break
				if (!found)
					return
		return materials


	proc/add_and_get_similar_materials(var/obj/item/material_piece/M,var/amount_needed)
		if (!istype(M) || !M.material || !isnum(amount_needed))
			return list()

		var/list/mats = list()
		mats += M
		amount_needed++
		for (var/obj/O in contents)
			if (mats.len >= amount_needed)
				break
			if (O == M)
				continue
			if (O.name == M.name)
				mats += O

		return mats

	proc/begin_work(var/new_production = 1)
		if (stat & NOPOWER || stat & BROKEN)
			return
		if (!queue.len)
			manual_stop = 0
			mode = "ready"
			build_icon()
			updateUsrDialog()
			return
		if (!istype(queue[1],/manufacture))
			mode = "halt"
			error = "Corrupted entry purged from production queue."
			queue -= queue[1]
			visible_message("<span style=\"color:red\">[src] emits an angry buzz!</span>")
			playsound(loc, sound_grump, 50, 1)
			build_icon()
			return

		var/manufacture/M = queue[1]
		//Wire: Fix for href exploit creating arbitrary items
		if (!(M in available + hidden + download))
			mode = "halt"
			error = "Corrupted entry purged from production queue."
			queue -= queue[1]
			visible_message("<span style=\"color:red\">[src] emits an angry buzz!</span>")
			playsound(loc, sound_grump, 50, 1)
			build_icon()
			return

		error = null

		if (malfunction && prob(40))
			flip_out()

		if (new_production)
			var/list/mats_used = material_check(M)
			if (isnull(mats_used))
				mode = "halt"
				error = "Insufficient usable materials to continue queue production."
				visible_message("<span style=\"color:red\">[src] emits an angry buzz!</span>")
				playsound(loc, sound_grump, 50, 1)
				build_icon()
				return

			if (mats_used && mats_used.len)
				materials_in_use = mats_used
				//for (var/obj/item/O in mats_used)
				//	del O

			powconsumption = 1500
			powconsumption *= speed * 1.5
			timeleft = M.time
			if (malfunction)
				powconsumption += 3000
				timeleft += rand(2,6)
				timeleft *= 1.5
		playsound(loc, sound_beginwork, 50, 1, 0, 3)
		mode = "working"
		build_icon()

	proc/output_loop(var/manufacture/M)

		if (!istype(M,/manufacture))
			return

		if (M.item_outputs.len <= 0)
			return
		var/mcheck = material_check(M)
		if (mcheck)
			var/make = max(0,min(M.create,output_cap))
			switch(M.randomise_output)
				if (1) // pick a new item each loop
					while (make > 0)
						dispense_product(pick(M.item_outputs),M)
						make--
				if (2) // get a random item from the list and produce it
					var/to_make = pick(M.item_outputs)
					while (make > 0)
						dispense_product(to_make,M)
						make--
				else // produce every item in the list once per loop
					while (make > 0)
						for (var/X in M.item_outputs)
							dispense_product(X,M)
						make--

			for (var/i = 1; i <= M.item_paths.len; i++)
				var/pattern = M.item_paths[i]
				var/amount = M.item_amounts[i]
				if (ispath(pattern))
					for (var/j = 0; j < amount; j++)
						var/obj/O = locate(pattern) in src
						contents -= O
						qdel(O)

			for (var/i = 1; i <= materials_in_use.len; i++)
				if (i > materials_in_use.len)
					break
				var/mat_id = materials_in_use[i]
				if (!M.item_amounts[i]) //Wire: Fix for list index out of bounds
					continue
				var/amount = M.item_amounts[i]
				if (!mat_id)
					continue
				var/cutting_amount = cuttings[mat_id]
				if (cutting_amount)
					var/used = min(cutting_amount, amount)
					cuttings[mat_id] -= used
					amount -= used
				if (amount == 0)
					continue
				for (var/obj/item/I in src)
					if (I.material && istype(I, base_material_class) && I.material.mat_id == mat_id)
						contents -= I
						qdel(I)
						if (amount < 10)
							cuttings[mat_id] += 10 - amount
							amount = 0
							break
						else
							amount -= 10

		if (repeat)
			if (!mcheck)
				queue -= M
		else
			queue -= M
		begin_work(1)
		return

	proc/dispense_product(var/product,var/manufacture/M)
		if (ispath(product))
			if (istype(M,/manufacture))
				var/atom/movable/A = new product(src)
				if (istype(A,/obj/item))
					var/obj/item/I = A
					M.modify_output(src, I, materials_in_use)
					I.set_loc(get_output_location(I))
				else
					A.set_loc(get_output_location(A))
			else
				new product(get_output_location())

		else if (istext(product) || isnum(product))
			if (istext(product) && copytext(product,1,8) == "reagent")
				var/the_reagent = copytext(product,9,length(product) + 1)
				if (M.create != 0)
					reagents.add_reagent(the_reagent,M.create / 10)
			else
				visible_message("<strong>[name]</strong> says, \"[product]\"")

		else if (isicon(product)) // adapted from vending machine code
			var/icon/welp = icon(product)
			if (welp.Width() > 32 || welp.Height() > 32)
				welp.Scale(32, 32)
				product = welp
			var/obj/dummy = new /obj/item(get_turf(src))
			dummy.name = "strange thing"
			dummy.desc = "The fuck is this?"
			dummy.icon = welp

		else if (isfile(product)) // adapted from vending machine code
			var/S = sound(product)
			if (S)
				playsound(loc, S, 50, 0)

		else if (isobj(product))
			var/obj/X = product
			X.set_loc(get_output_location())

		else if (ismob(product))
			var/mob/X = product
			X.set_loc(get_output_location())

		else
			return

	proc/flip_out()
		if (stat & BROKEN || stat & NOPOWER || !malfunction)
			return
		animate_shake(src,5,rand(3,8),rand(3,8))
		visible_message("<span style=\"color:red\">[src] makes [pick(text_flipout_adjective)] [pick(text_flipout_noun)]!</span>")
		playsound(loc, pick(sounds_malfunction), 50, 2)
		if (prob(15) && contents.len > 4 && mode != "working")
			var/to_throw = rand(1,4)
			var/obj/item/X = null
			while (to_throw > 0)
				if (!nearby_turfs.len) //SpyGuy for RTE "pick() from empty list"
					break
				X = pick(contents)
				X.set_loc(loc)
				X.throw_at(pick(nearby_turfs), 16, 3)
				to_throw--
		if (queue.len > 1 && prob(20))
			var/list_counter = 0
			for (var/manufacture/X in queue)
				list_counter++
				if (list_counter == 1)
					continue
				if (prob(33))
					queue -= X
		if (mode == "working")
			if (prob(5))
				mode = "halt"
				build_icon()
			else
				if (prob(10))
					powconsumption *= 2
		if (prob(10))
			speed = rand(1,8)
		if (prob(5))
			if (!electrified)
				electrified = 5

	proc/build_icon()
		icon_state = "fab[icon_base ? "-[icon_base]" : null]"

		if (stat & BROKEN)
			UpdateOverlays(null, "work")
			UpdateOverlays(null, "activity")
			icon_state = "[icon_base]-broken"
		else if (dismantle_stage >= 2)
			UpdateOverlays(null, "work")
			UpdateOverlays(null, "activity")
			icon_state = "fab-noplate"

		if (!(stat & NOPOWER) && !(stat & BROKEN))
			if (malfunction && prob(50))
				switch  (rand(1,4))
					if (1) activity_display.icon_state = "light-ready"
					if (2) activity_display.icon_state = "light-halt"
					if (3) activity_display.icon_state = "light-working"
					else activity_display.icon_state = "light-malf"
			else
				activity_display.icon_state = "light-[mode]"

			var/animspeed = speed
			if (animspeed < 1 || animspeed > 5 || (malfunction && prob(50)))
				animspeed = "malf"

			if (mode == "working")
				work_display.icon_state = "fab-work[animspeed]"
			else
				work_display.icon_state = ""

			UpdateOverlays(work_display, "work")
			UpdateOverlays(activity_display, "activity")

		if (panelopen)
			panel_sprite.icon_state = "fab-panel"
			UpdateOverlays(panel_sprite, "panel")
		else
			UpdateOverlays(null, "panel")

	proc/build_material_list()
		var/dat = "<strong>Available Materials & Reagents:</strong><small><br>"
		var/list/mat_amts = list()
		for (var/obj/item/O in contents)
			if (istype(O,/obj/item/reagent_containers/glass/beaker))
				if (O == beaker)
					continue
			if (istype(O,base_material_class) && O.material)
				mat_amts[O.material.name] += 10
		for (var/mat_id in cuttings)
			var/amount = cuttings[mat_id]
			var/material/mat = getCachedMaterial(mat_id)
			mat_amts[mat.name] += amount

		if (mat_amts.len)
			for (var/mat_type in mat_amts)
				dat += "<A href='?src=\ref[src];eject=[mat_type]'><strong>[mat_type]:</strong></A> [mat_amts[mat_type]]<br>"
		else
			dat += "No materials currently loaded.<br>"

		var/reag_list = ""
		for (var/current_id in reagents.reagent_list)
			var/reagent/current_reagent = reagents.reagent_list[current_id]
			dat += "[reag_list ? "<br>" : " "][current_reagent.volume] units of <A href='?src=\ref[src];flush=[current_reagent.name]'>[current_reagent.name]</a><br>"

		dat += reag_list
		dat += "</small>"

		return dat

	proc/build_control_panel()
		var/dat = "<small>"

		if (page == 1)
			dat += "<br><u><A href='?src=\ref[src];page=0'>Production List</A> | <strong>Queue:</strong> [queue.len]</u>"
		else
			dat += "<br><u><strong>Production List</strong> | <A href='?src=\ref[src];page=1'>Queue:</A> [queue.len]</u>"

		if (mode == "working" && queue.len > 0)
			dat += "<br><strong>Current Production:</strong> <u>[queue[1]]</u>"
		else
			dat += "<br><strong>Current Production:</strong> None"

		dat += "<HR>"

		dat += "<strong><A href='?src=\ref[src];speed=1'>Speed:</A></strong> [speed]"

		if (repeat == 1)
			dat += " | <A href='?src=\ref[src];repeat=1'><strong>Repeat: On</strong></A>"
		else
			dat += " | <A href='?src=\ref[src];repeat=1'><strong>Repeat: Off</strong></A>"

		dat += "<br>"

		if (retain_output_internally >= 0)
			if (retain_output_internally == 1)
				dat += "<A href='?src=\ref[src];internalize=1'><strong>Store outputs internally: Yes</strong></A>"
			else
				dat += "<A href='?src=\ref[src];internalize=1'><strong>Store outputs internally: No</strong></A>"

		dat += "<br>"

		if (beaker)
			dat += "<A href='?src=\ref[src];ejectbeaker=\ref[src.beaker]'><strong>Receptacle:</strong></a> [src.beaker.name]"
			if (beaker.reagents.total_volume < beaker.reagents.maximum_volume)
				dat += " <A href='?src=\ref[src];transto=\ref[beaker]'>(Transfer to Receptacle)</a>"
			if (beaker.reagents.total_volume > 0)
				dat += " <A href='?src=\ref[src];transfrom=\ref[beaker]'>(Transfer to Unit)</a>"
		else
			dat += "No reagent receptacle inserted."

		dat += "<br>"

		if (!page)
			dat += "<A href='?src=\ref[src];category=1'>Filter</A> | <A href='?src=\ref[src];search=1'>Search</A>"

		dat += "</small>"

		return dat

	proc/load_item(var/obj/item/O,var/mob/living/user)
		if (!O)
			return
		O.set_loc(src)
		if (user && O)
			user.u_equip(O)
			O.dropped()

	proc/take_damage(var/damage_amount = 0)
		if (!damage_amount)
			return
		health -= damage_amount
		health = max(0,min(health,100))
		if (damage_amount > 0)
			playsound(loc, sound_damaged, 50, 2)
			if (health == 0)
				visible_message("<span style=\"color:red\"><strong>[name] is destroyed!</strong></span>")
				robogibs(loc,null)
				playsound(loc, sound_destroyed, 50, 2)
				qdel(src)
				return
			if (health <= 70 && !malfunction && prob(33))
				malfunction = 1
				flip_out()
			if (malfunction && prob(40))
				flip_out()
			if (health <= 25 && !(stat & BROKEN))
				visible_message("<span style=\"color:red\"><strong>[name] breaks down and stops working!</strong></span>")
				stat |= BROKEN
		else
			if (health >= 60 && stat & BROKEN)
				visible_message("<span style=\"color:red\"><strong>[name] looks like it can function again!</strong></span>")
				stat &= ~BROKEN

		build_icon()

	proc/claim_free_resources()
		if (free_resources.len && free_resource_amt > 0)
			var/looper = free_resource_amt

			while (looper > 0)
				looper--
				for (var/X in free_resources)
					if (ispath(X))
						new X(src)

	proc/get_output_location(var/atom/A,var/ejection = 0)
		if (!output_target)
			return loc

		if (get_dist(output_target,src) > 1)
			output_target = null
			return loc

		if (istype(output_target,/obj/storage/crate))
			var/obj/storage/crate/C = output_target
			if (C.locked || C.welded)
				output_target = null
				return loc
			else
				if (C.open)
					return C.loc
				else
					return C

		else if (istype(output_target,/obj/machinery/manufacturer))
			var/obj/machinery/manufacturer/M = output_target
			if (M.stat & BROKEN || M.stat & NOPOWER || M.dismantle_stage > 0)
				output_target = null
				return loc
			if (A && istype(A,M.base_material_class))
				return M
			else
				return M.loc

		else if (istype(output_target,/turf/simulated/floor))
			return output_target

		else
			return loc

// Blueprints

/obj/item/paper/manufacturer_blueprint
	name = "Manufacturer Blueprint"
	desc = "It's a blueprint to allow a manufacturing unit to build something."
	info = "There's all manner of confusing diagrams and instructions on here. It's meant for a machine to read."
	icon = 'icons/obj/electronics.dmi'
	icon_state = "blueprint"
	item_state = "sheet"
	var/manufacture/blueprint = null

	New(var/loc,var/schematic = null)
		if (!schematic)
			if (ispath(blueprint))
				blueprint = get_schematic_from_path(blueprint)
			else
				qdel(src)
				return FALSE
		else
			if (istext(schematic))
				blueprint = get_schematic_from_name(schematic)
			else if (ispath(schematic))
				blueprint = get_schematic_from_path(schematic)

		if (!blueprint)
			qdel(src)
			return FALSE

		name = "Manufacturer Blueprint: [blueprint.name]"
		src.desc = "This blueprint will allow a manufacturer unit to build [src.blueprint.name]"

		pixel_x = rand(-4,4)
		pixel_y = rand(-4,4)

		return TRUE

// Fabricator Defines

/obj/machinery/manufacturer/general
	name = "General Manufacturer"
	desc = "A manufacturing unit calibrated to produce tools and general purpose items."
	free_resource_amt = 5
	free_resources = list(/obj/item/material_piece/mauxite,/obj/item/material_piece/pharosium,/obj/item/material_piece/molitz)
	available = list(/manufacture/screwdriver,/manufacture/wirecutters,/manufacture/wrench,/manufacture/crowbar,
/manufacture/extinguisher,/manufacture/welder,/manufacture/soldering,/manufacture/flashlight,/manufacture/weldingmask,
/manufacture/multitool,/manufacture/metal,/manufacture/metalR,/manufacture/glass,
/manufacture/glassR,/manufacture/atmos_can,/manufacture/circuit_board,
/manufacture/cable,/manufacture/powercell,/manufacture/powercellE,/manufacture/powercellC,
/manufacture/light_bulb,/manufacture/red_bulb,/manufacture/yellow_bulb,/manufacture/green_bulb,
/manufacture/cyan_bulb,/manufacture/blue_bulb,/manufacture/purple_bulb,/manufacture/blacklight_bulb,
/manufacture/light_tube,/manufacture/red_tube,/manufacture/yellow_tube,/manufacture/green_tube,
/manufacture/cyan_tube,/manufacture/blue_tube,/manufacture/purple_tube,/manufacture/blacklight_tube,
/manufacture/jumpsuit,/manufacture/shoes,/manufacture/breathmask,/manufacture/patch)
	hidden = list(/manufacture/RCDammo,/manufacture/RCDammolarge,/manufacture/bottle,/manufacture/vuvuzela,/manufacture/harmonica,
/manufacture/bikehorn,/manufacture/stunrounds,/manufacture/bullet_22,/manufacture/bullet_smoke,/manufacture/stapler)

/obj/machinery/manufacturer/robotics
	name = "Robotics Fabricator"
	desc = "A manufacturing unit calibrated to produce robot-related equipment."
	icon_state = "fab-robotics"
	icon_base = "robotics"
	free_resource_amt = 5
	free_resources = list(/obj/item/material_piece/mauxite,
	/obj/item/material_piece/pharosium,
	/obj/item/material_piece/molitz)

	available = list(/manufacture/robo_frame,
	/manufacture/full_cyborg_standard,
	/manufacture/full_cyborg_light,
	/manufacture/robo_head,
	/manufacture/robo_chest,
	/manufacture/robo_arm_r,
	/manufacture/robo_arm_l,
	/manufacture/robo_leg_r,
	/manufacture/robo_leg_l,
	/manufacture/robo_head_light,
	/manufacture/robo_chest_light,
	/manufacture/robo_arm_r_light,
	/manufacture/robo_arm_l_light,
	/manufacture/robo_leg_r_light,
	/manufacture/robo_leg_l_light,
	/manufacture/robo_leg_treads,
	/manufacture/robo_stmodule,
	/manufacture/cyberheart,
	/manufacture/cybereye,
	/manufacture/cybereye_meson,
	/manufacture/cybereye_spectro,
	/manufacture/cybereye_prodoc,
	/manufacture/cybereye_camera,
	/manufacture/shell_frame,
	/manufacture/ai_interface,
	/manufacture/shell_cell,
	/manufacture/cable,
	/manufacture/powercell,
	/manufacture/powercellE,
	/manufacture/powercellC,
	/manufacture/crowbar,
	/manufacture/wrench,
	/manufacture/scalpel,
	/manufacture/circular_saw,
	/manufacture/stapler,
	/manufacture/surgical_spoon,
	/manufacture/suture,
	/manufacture/implanter,
	/manufacture/secbot,
	/manufacture/medbot,
	/manufacture/firebot,
	/manufacture/floorbot,
	/manufacture/cleanbot,
	/manufacture/visor,
	/manufacture/deafhs,
	/manufacture/robup_jetpack,
	/manufacture/robup_healthgoggles,
	/manufacture/robup_recharge,
	/manufacture/robup_repairpack,
	/manufacture/robup_speed,
	/manufacture/robup_meson,
	/manufacture/robup_aware,
	/manufacture/robup_physshield,
	/manufacture/robup_fireshield,
	/manufacture/robup_teleport,
	/manufacture/robup_visualizer,
	/*/manufacture/robup_thermal,*/
	/manufacture/robup_efficiency,
	/manufacture/robup_repair,
	/manufacture/implant_robotalk,
	/manufacture/implant_health,
	/manufacture/rods2,
	/manufacture/metal,
	/manufacture/glass)

	hidden = list(/manufacture/flash,
	/manufacture/cybereye_thermal,
	/manufacture/cyberbutt)

/obj/machinery/manufacturer/medical
	name = "Medical Fabricator"
	desc = "A manufacturing unit calibrated to produce medical equipment."
	icon_state = "fab-med"
	icon_base = "med"
	free_resource_amt = 2
	free_resources = list(/obj/item/material_piece/mauxite,
	/obj/item/material_piece/cloth/cottonfabric,
	/obj/item/material_piece/pharosium,
	/obj/item/material_piece/molitz)

	available = list(/manufacture/scalpel,
	/manufacture/circular_saw,
	/manufacture/suture,
	/manufacture/stapler,
	/manufacture/surgical_spoon,
	/manufacture/prodocs,
	/manufacture/visor,
	/manufacture/deafhs,
	/manufacture/hypospray,
	/manufacture/patch,
	/manufacture/scrubs_white,
	/manufacture/scrubs_teal,
	/manufacture/scrubs_maroon,
	/manufacture/scrubs_blue,
	/manufacture/surgical_mask,
	/manufacture/surgical_shield,
	/manufacture/implanter,
	/manufacture/implant_health,
	/manufacture/crowbar,
	/manufacture/extinguisher,
	/manufacture/rods2,
	/manufacture/metal,
	/manufacture/glass)

	hidden = list(/manufacture/cyberheart,
	/manufacture/cybereye)

/obj/machinery/manufacturer/mining
	name = "Mining Fabricator"
	desc = "A manufacturing unit calibrated to produce mining related equipment."
	icon_state = "fab-mining"
	icon_base = "mining"
	free_resource_amt = 2
	free_resources = list(/obj/item/material_piece/mauxite,/obj/item/material_piece/pharosium,/obj/item/material_piece/molitz)
	available = list(/manufacture/pick,/manufacture/powerpick,/manufacture/blastchargeslite,/manufacture/blastcharges,
/manufacture/powerhammer,/manufacture/drill,/manufacture/conc_gloves,/manufacture/jumpsuit,/manufacture/shoes,
/manufacture/breathmask,/manufacture/engspacesuit,/manufacture/industrialarmor,/manufacture/industrialboots,
/manufacture/powercell,/manufacture/powercellE,/manufacture/powercellC,/manufacture/oresatchel,/manufacture/oresatchelL,
/manufacture/jetpack,/manufacture/geoscanner,/manufacture/eyes_meson,/manufacture/flashlight,/manufacture/ore_accumulator,
/manufacture/rods2,/manufacture/metal,/manufacture/mining_magnet)
	hidden = list(/manufacture/RCD,/manufacture/RCDammo,/manufacture/RCDammolarge)

/obj/machinery/manufacturer/hangar
	name = "Ship Component Fabricator"
	desc = "A manufacturing unit calibrated to produce parts for ships."
	icon_state = "fab-hangar"
	icon_base = "hangar"
	free_resource_amt = 2
	free_resources = list(/obj/item/material_piece/mauxite,/obj/item/material_piece/pharosium,/obj/item/material_piece/molitz)
	available = list(/manufacture/putt/engine,/manufacture/putt/boards,/manufacture/putt/control,/manufacture/putt/parts,/manufacture/pod/engine,/manufacture/pod/boards,/manufacture/pod/armor_light,/manufacture/pod/armor_heavy,
/manufacture/pod/armor_industrial,/manufacture/pod/control,/manufacture/pod/parts,/manufacture/cargohold,
/manufacture/conclave,/manufacture/pod/weapon/mining,/manufacture/pod/weapon/ltlaser,/manufacture/engine2,
/manufacture/engine3,/manufacture/pod/lock)

/obj/machinery/manufacturer/uniform // add more stuff to this as needed, but it should be for regular uniforms the HoP might hand out, not tons of gimmicks. -cogwerks
	name = "Uniform Manufacturer"
	desc = "A manufacturing unit calibrated to produce workplace uniforms."
	icon_state = "fab-jumpsuit"
	icon_base = "jumpsuit"
	free_resource_amt = 5
	free_resources = list(/obj/item/material_piece/cloth/cottonfabric)
	accept_blueprints = 0
	available = list(/manufacture/shoes,
	/manufacture/shoes_brown,
	/manufacture/shoes_white,
	/manufacture/jumpsuit,
	/manufacture/jumpsuit_white,
	/manufacture/jumpsuit_red,
	/manufacture/jumpsuit_yellow,
	/manufacture/jumpsuit_green,
	/manufacture/jumpsuit_pink,
	/manufacture/jumpsuit_blue,
	/manufacture/jumpsuit_brown,
	/manufacture/jumpsuit_black,
	/manufacture/jumpsuit_orange,
	/manufacture/suit_black,
	/manufacture/hat_black,
	/manufacture/hat_white,
	/manufacture/hat_blue,
	/manufacture/hat_yellow,
	/manufacture/hat_red,
	/manufacture/hat_green,
	/manufacture/hat_tophat)

/// cogwerks - a gas extractor for the engine

/obj/machinery/manufacturer/gas
	name = "Gas Extractor"
	desc = "A manufacturing unit that can produce gas canisters from certain ores."
	icon_state = "fab-mining"
	icon_base = "mining"
	accept_blueprints = 0
	available = list(/manufacture/atmos_can,/manufacture/o2_can,/manufacture/co2_can,/manufacture/plasma_can)

// a blank manufacturer for mechanics

/obj/machinery/manufacturer/mechanic
	name = "Reverse-Engineering Fabricator"
	desc = "A manufacturing unit designed to create new things from blueprints."
	icon_state = "fab-hangar"
	icon_base = "hangar"
	free_resource_amt = 2
	free_resources = list(/obj/item/material_piece/mauxite,/obj/item/material_piece/pharosium,/obj/item/material_piece/molitz)

#undef WIRE_EXTEND
#undef WIRE_POWER
#undef WIRE_MALF
#undef WIRE_SHOCK
#undef MAX_QUEUE_LENGTH