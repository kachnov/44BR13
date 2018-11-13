/obj/machinery/recharge_station
	name = "Cyborg Docking Station"
	icon = 'icons/obj/robot_parts.dmi'
	desc = "A station which allows cyborgs to repair damage, recharge their cells, and have upgrades installed if they are present in the station."
	icon_state = "station"
	density = 1
	anchored = 1.0
	mats = 10
	allow_stunned_dragndrop = 1
	var/chargerate = 400
	var/cabling = 250
	var/list/cells = list()
	var/list/upgrades = list()
	var/list/modules = list()
	var/list/clothes = list()
	var/allow_self_service = 1
	var/conversion_chamber = 0
	var/mob/occupant = null
	power_usage = 50

	var/allow_clothes = 1

	New()
		..()

		var/reagents/R = new/reagents(500)
		reagents = R
		R.maximum_volume = 500
		R.my_atom = src
		R.add_reagent("fuel", 250)

		build_icon()

	process()
		if (!(stat & BROKEN))
			if (occupant)
				power_usage = 500
			else
				power_usage = 50
			..()
		if (stat & (NOPOWER|BROKEN) || !anchored)
			if (occupant)
				boutput(occupant, "<span style=\"color:red\">You are automatically ejected from [src]!</span>")
				go_out()
				build_icon()
			return

		if (occupant)
			process_occupant()
		return TRUE

	allow_drop()
		return FALSE

	relaymove(mob/user as mob)
		if (conversion_chamber && !istype(user,/mob/living/silicon/robot))
			boutput(user, "<span style=\"color:red\">You're trapped inside!</span>")
			return
		//if (user.stat) // Trapping cell-less (thus deaf and mute) robots inside is not fun. It's very easy to rip their cell out, too.
		//	boutput(user, "<span style=\"color:red\">You are incapacitated and cannot currently leave [src].</span>")
		//	return
		go_out()
		return

	ex_act(severity)
		go_out()
		return ..(severity)

	attack_hand(mob/user)
		if (stat & BROKEN)
			boutput(usr, "<span style=\"color:red\">[src] is broken and cannot be used.</span>")
			return
		if (stat & NOPOWER)
			boutput(usr, "<span style=\"color:red\">[src] is out of power and cannot be used.</span>")
			return

		if (!anchored)
			user.show_text("You must attach [src]'s floor bolts before the machine will work.", "red")
			return

		user.machine = src

		var/dat = "<strong>[name]</strong> <A href='?src=\ref[src];refresh=1'>(Refresh)</A><BR><HR>"

		if (!occupant)
			dat += "No occupant detected in [name].<BR><HR>"
		else
			if (istype(occupant,/mob/living/silicon/robot))
				var/mob/living/silicon/robot/R = occupant
				dat += "<u><strong>Occupant Name:</strong></u> [R.name] "
				if (user != occupant) dat += "<A href='?src=\ref[src];rename=1'>(Rename)</A>"
				dat += "<BR>"

				var/mob/living/silicon/robot/RC = occupant
				var/dmgalerts = 0
				dat += "<u><strong>Damage Report:</strong></u><BR>"
				dat += "<A href='?src=\ref[src];repair=1'>Repair Structural Damage</A> | <A href='?src=\ref[src];repair=2'>Repair Burn Damage</A><BR>"
				if (RC.part_chest)
					if (RC.part_chest.ropart_get_damage_percentage(0) > 0)
						dmgalerts++
						dat += "<strong>Chest Unit Damaged</strong> ([RC.part_chest.ropart_get_damage_percentage(1)]%, [RC.part_chest.ropart_get_damage_percentage(2)]%)<BR>"

				if (RC.part_head)
					if (RC.part_head.ropart_get_damage_percentage(0) > 0)
						dmgalerts++
						dat += "<strong>Head Unit Damaged</strong> ([RC.part_head.ropart_get_damage_percentage(1)]%, [RC.part_head.ropart_get_damage_percentage(2)]%)<BR>"

				if (RC.part_arm_r)
					if (RC.part_arm_r.ropart_get_damage_percentage(0) > 0)
						dmgalerts++
						if (RC.part_arm_r.slot == "arm_both") dat += "<strong>Arms Unit Damaged</strong> ([RC.part_arm_r.ropart_get_damage_percentage(1)]%, [RC.part_arm_r.ropart_get_damage_percentage(2)]%)<BR>"
						else dat += "<strong>Right Arm Unit Damaged</strong> ([RC.part_arm_r.ropart_get_damage_percentage(1)]%, [RC.part_arm_r.ropart_get_damage_percentage(2)]%)<BR>"
				else
					dmgalerts++
					dat += "Right Arm Unit Missing<br>"

				if (RC.part_arm_l)
					if (RC.part_arm_l.ropart_get_damage_percentage(0) > 0)
						dmgalerts++
						if (RC.part_arm_l.slot != "arm_both") dat += "<strong>Left Arm Unit Damaged</strong> ([RC.part_arm_l.ropart_get_damage_percentage(1)]%, [RC.part_arm_l.ropart_get_damage_percentage(2)]%)<BR>"
				else
					dmgalerts++
					dat += "Left Arm Unit Missing<br>"

				if (RC.part_leg_r)
					if (RC.part_leg_r.ropart_get_damage_percentage(0) > 0)
						dmgalerts++
						if (RC.part_leg_r.slot == "leg_both") dat += "<strong>Legs Unit Damaged</strong> ([RC.part_leg_r.ropart_get_damage_percentage(1)]%, [RC.part_leg_r.ropart_get_damage_percentage(2)]%)<BR>"
						else dat += "<strong>Right Leg Unit Damaged</strong> ([RC.part_leg_r.ropart_get_damage_percentage(1)]%, [RC.part_leg_r.ropart_get_damage_percentage(2)]%)<BR>"
				else
					dmgalerts++
					dat += "Right Leg Unit Missing<br>"

				if (RC.part_leg_l)
					if (RC.part_leg_l.ropart_get_damage_percentage(0) > 0)
						dmgalerts++
						if (RC.part_leg_l.slot != "arm_both") dat += "<strong>Left Leg Unit Damaged</strong> ([RC.part_leg_l.ropart_get_damage_percentage(1)]%, [RC.part_leg_l.ropart_get_damage_percentage(2)]%)<BR>"
				else
					dmgalerts++
					dat += "Left Leg Unit Missing<br>"

				if (!dmgalerts && occupant.health < occupant.max_health)
					occupant.updatehealth()

				if (dmgalerts == 0) dat += "No abnormalities detected.<br>"

				dat += "<strong>Power Cell:</strong> "
				if (R.cell)
					var/obj/item/cell/C = R.cell
					dat += "[C] - [C.charge]/[C.maxcharge]"
					if (!istype(user,/mob/living/silicon/robot)) dat += "<A HREF=?src=\ref[src];remove=\ref[C]>(Remove)</A>"
				else dat += "None"
				dat += "<BR><BR>"

				dat += "<strong>Module:</strong> "
				if (R.module)
					var/obj/item/robot_module/M = R.module
					dat += "[M.name] <A HREF=?src=\ref[src];remove=\ref[M]>(Remove)</A>"
				else dat += "None"
				dat += "<BR><BR>"

				dat += "<strong>Upgrades:</strong> ([R.upgrades.len]/[R.max_upgrades]) "
				if (R.upgrades.len)
					for (var/obj/item/roboupgrade/U in R.upgrades)
						dat += "<br>[U.name] <A HREF=?src=\ref[src];remove=\ref[U]>(Remove)</A>"
				else dat += "None"

				if (allow_clothes)
					dat += "<BR><BR>"
					dat += "<strong>Clothes:</strong> "
					if (R.clothes.len)
						for (var/A in R.clothes)
							var/obj/O = R.clothes[A]
							dat += "<br>[O.name] <A HREF=?src=\ref[src];remove=\ref[O]>(Remove)</A>"
					else dat += "None"

				if (user != occupant)
					var/mob/living/silicon/robot/C = occupant
					dat += "<BR><strong><U>Occupant is a Mk.2-Type Cyborg.</U></strong><BR>"

					if (istype(C.cosmetic_mods,/robot_cosmetic))
						var/robot_cosmetic/COS = C.cosmetic_mods

						dat += "<strong>Chest Decoration:</strong> <A href='?src=\ref[src];decor=chest'>[COS.ches_mod ? COS.ches_mod : "None"]</A><BR>"
						if (COS.painted) dat += "Paint Options: <A href='?src=\ref[src];paint=change'>Repaint</A> | <A href='?src=\ref[src];paint=remove'>Remove Paint</A><BR>"
						else dat += "Paint Options: <A href='?src=\ref[src];paint=add'>Add Paint</A><BR>"
						dat += "<strong>Head Decoration:</strong> <A href='?src=\ref[src];decor=head'>[COS.head_mod ? COS.head_mod : "None"]</A><BR>"
						dat += "<strong>Arms Decoration:</strong> <A href='?src=\ref[src];decor=arms'>[COS.arms_mod ? COS.arms_mod : "None"]</A><BR>"
						dat += "<strong>Legs Decoration:</strong> <A href='?src=\ref[src];decor=legs'>[COS.legs_mod ? COS.legs_mod : "None"]</A><BR>"
						dat += "<A href='?src=\ref[src];decor=fx'>Change Eye Color</A><BR>"

				dat += "<BR><HR>"

			else
				if (conversion_chamber && ishuman(occupant) )
					var/mob/living/carbon/human/H = occupant
					dat += "Conversion process is [100 - round(100 * H.health / H.max_health)]% complete.<BR><HR>"
				else
					dat += "Cannot interface with occupant of unknown type.<BR><HR>"

		var/fuelamt = reagents.get_reagent_amount("fuel")
		dat += "<strong>Cyborg Self-Service Allowed:</strong> <A href='?src=\ref[src];selfservice=1'>[allow_self_service ? "Yes" : "No"]</A><BR>"
		dat += "<strong>Welding Fuel Available:</strong> [fuelamt]<BR>"
		dat += "<strong>Cable Coil Available:</strong> [cabling]<BR>"

		dat += "<strong>Power Cells Available:</strong> "
		if (cells.len)
			for (var/obj/item/cell/C in cells)
				dat += "<br>[C.name] - [C.charge]/[C.maxcharge]"
				if (istype(occupant,/mob/living/silicon/robot/) && !istype(user,/mob/living/silicon/robot)) dat += "<A HREF=?src=\ref[src];install=\ref[C]> (Install)</A>"
				dat += " <A HREF=?src=\ref[src];eject=\ref[C]>(Eject)</A>"
		else dat += "None"
		dat += "<BR><BR>"

		dat += "<strong>Modules Available:</strong> "
		if (modules.len)
			for (var/obj/item/robot_module/M in modules)
				dat += "<br>[M.name]"
				if (istype(occupant,/mob/living/silicon/robot)) dat += "<A HREF=?src=\ref[src];install=\ref[M]> (Install)</A>"
				dat += " <A HREF=?src=\ref[src];eject=\ref[M]>(Eject)</A>"
		else dat += "None"
		dat += "<BR><BR>"

		dat += "<strong>Upgrades Available:</strong> "
		if (upgrades.len)
			for (var/obj/item/roboupgrade/U in upgrades)
				dat += "<br>[U.name]"
				if (istype(occupant,/mob/living/silicon/robot)) dat += "<A HREF=?src=\ref[src];install=\ref[U]> (Install)</A>"
				dat += " <A HREF=?src=\ref[src];eject=\ref[U]>(Eject)</A>"
		else dat += "None"

		if (allow_clothes) dat += "<BR><BR>"
		else dat += "<BR><HR>"

		if (allow_clothes)
			dat += "<strong>Clothes Available:</strong> "
			if (clothes.len)
				for (var/obj/item/clothing/C in clothes)
					dat += "<br>[C.name]"
					if (istype(occupant,/mob/living/silicon/robot)) dat += "<A HREF=?src=\ref[src];install=\ref[C]> (Install)</A>"
					dat += " <A HREF=?src=\ref[src];eject=\ref[C]>(Eject)</A>"
			else dat += "None"
			dat += "<BR><HR>"

		user << browse(dat, "window=cyberdock;size=400x500")
		onclose(user, "cyberdock")

	Topic(href, href_list)
		if (stat & BROKEN) return
		if (stat & NOPOWER) return

		if (usr.stat || usr.restrained())
			return

		if (!anchored)
			usr.show_text("You must attach [src]'s floor bolts before the machine will work.", "red")
			return

		if ((usr.contents.Find(src) || src.contents.Find(usr) || ((get_dist(src, usr) <= 1) && istype(src.loc, /turf))))
			usr.machine = src

			if (href_list["refresh"])
				updateUsrDialog()
				return

			if (istype(usr,/mob/living/silicon/robot))
				if (usr != occupant)
					boutput(usr, "<span style=\"color:red\">You must be inside the docking station to use the functions.</span>")
					updateUsrDialog()
					return
				else
					if (!allow_self_service)
						boutput(usr, "<span style=\"color:red\">Self-service is disabled at this docking station.</span>")
						updateUsrDialog()
						return
			else
				if (usr == occupant)
					boutput(usr, "<span style=\"color:red\">Non-cyborgs cannot use the docking station functions.</span>")
					updateUsrDialog()
					return

			if (!istype(occupant,/mob/living/silicon/robot))
				if (occupant)
					boutput(usr, "<span style=\"color:red\">The docking station functions are not compatible with non-cyborg occupants.</span>")
					updateUsrDialog()
				return

			if (href_list["rename"])
				if (usr == occupant)
					boutput(usr, "<span style=\"color:red\">You may not rename yourself!</span>")
					updateUsrDialog()
					return
				var/mob/living/silicon/robot/R = occupant
				var/newname = copytext(strip_html(sanitize(input(usr, "What do you want to rename [R]?", "Cyborg Maintenance", R.name) as null|text)), 1, 64)
				if ((!issilicon(usr) && (get_dist(usr, src) > 1)) || usr.stat || !newname)
					return
				if (url_regex && url_regex.Find(newname))
					boutput(usr, "<span style=\"color:blue\"><strong>Web/BYOND links are not allowed in ingame chat.</strong></span>")
					boutput(usr, "<span style=\"color:red\">&emsp;<strong>\"[newname]</strong>\"</span>")
					return
				logTheThing("combat", usr, R, "uses a docking station to rename %target% to [newname].")
				R.name = newname

			if (href_list["selfservice"])
				if (istype(usr,/mob/living/silicon/robot))
					boutput(usr, "<span style=\"color:red\">Cyborgs are not allowed to toggle this option.</span>")
					updateUsrDialog()
					return
				else allow_self_service = !allow_self_service

			if (href_list["repair"])
				if (!istype(occupant,/mob/living/silicon/robot))
					updateUsrDialog()
					return
				var/mob/living/silicon/robot/R = occupant

				var/ops = text2num(href_list["repair"])

				var/mob/living/silicon/robot/C = R
				if (ops == 1 && C.compborg_get_total_damage(1) > 0)
					var/usage = input(usr,"How much welding fuel do you want to use?" ,"Docking Station", 0) as num
					if ((!issilicon(usr) && (get_dist(usr, src) > 1)) || usr.stat)
						return
					if (usage > C.compborg_get_total_damage(1)) usage = C.compborg_get_total_damage(1)
					if (usage < 1) return
					for (var/obj/item/parts/robot_parts/RP in C.contents) RP.ropart_mend_damage(usage,0)
					reagents.remove_reagent("fuel",usage)
				else if (ops == 2 && C.compborg_get_total_damage(2) > 0)
					var/usage = input(usr,"How much wiring do you want to use?" ,"Docking Station", 0) as num
					if ((!issilicon(usr) && (get_dist(usr, src) > 1)) || usr.stat)
						return
					if (usage > C.compborg_get_total_damage(2)) usage = C.compborg_get_total_damage(2)
					if (usage < 1) return
					for (var/obj/item/parts/robot_parts/RP in C.contents) RP.ropart_mend_damage(0,usage)
					cabling -= usage
					if (cabling < 0) cabling = 0
				else boutput(usr, "<span style=\"color:red\">[C] has no damage to repair.</span>")
				R.update_appearance()

			if (href_list["install"])
				if (!istype(occupant,/mob/living/silicon/robot))
					updateUsrDialog()
					return
				var/mob/living/silicon/robot/R = occupant
				var/obj/item/O = locate(href_list["install"])

				//My apologies for this ugly code.
				if (allow_clothes && istype(O, /obj/item/clothing))
					if (istype(O,/obj/item/clothing/under))
						if (R.clothes["under"] != null)
							var/obj/old = R.clothes["under"]
							clothes.Add(old)
							old.set_loc(src)

							R.clothes["under"] = O
							clothes.Remove(O)
							O.set_loc(R)
						else
							R.clothes["under"] = O
							clothes.Remove(O)
							O.set_loc(R)
					else if (istype(O,/obj/item/clothing/suit))
						if (R.clothes["suit"] != null)
							var/obj/old = R.clothes["suit"]
							clothes.Add(old)
							old.set_loc(src)

							R.clothes["suit"] = O
							clothes.Remove(O)
							O.set_loc(R)
						else
							R.clothes["suit"] = O
							clothes.Remove(O)
							O.set_loc(R)
					else if (istype(O,/obj/item/clothing/mask))
						if (R.clothes["mask"] != null)
							var/obj/old = R.clothes["mask"]
							clothes.Add(old)
							old.set_loc(src)

							R.clothes["mask"] = O
							clothes.Remove(O)
							O.set_loc(R)
						else
							R.clothes["mask"] = O
							clothes.Remove(O)
							O.set_loc(R)
					else if (istype(O,/obj/item/clothing/head))
						if (R.clothes["head"] != null)
							var/obj/old = R.clothes["head"]
							clothes.Add(old)
							old.set_loc(src)

							R.clothes["head"] = O
							clothes.Remove(O)
							O.set_loc(R)
						else
							R.clothes["head"] = O
							clothes.Remove(O)
							O.set_loc(R)

				if (istype(O,/obj/item/cell))
					if (R.cell)
						boutput(usr, "<span style=\"color:red\">[R] already has a cell installed!</span>")
					else
						cells.Remove(O)
						O.set_loc(R)
						R.cell = O
						R.hud.update_charge()

				if (istype(O,/obj/item/roboupgrade))
					if (R.upgrades.len >= R.max_upgrades)
						boutput(usr, "<span style=\"color:red\">[R] has no room for further upgrades.</span>")
						updateUsrDialog()
						return
					if (locate(O.type) in R.upgrades)
						boutput(usr, "<span style=\"color:red\">[R] already has that upgrade.</span>")
						updateUsrDialog()
						return
					upgrades.Remove(O)
					R.upgrades.Add(O)
					O.set_loc(R)
					//O.icon_state = null  //What the FUCK
					boutput(R, "<span style=\"color:blue\">You recieved [O]! It can be activated from your panel.</span>")
					R.hud.update_upgrades()
				if (istype(O,/obj/item/robot_module))
					if (R.module)
						boutput(usr, "<span style=\"color:red\">[R] already has a module installed!</span>")
					else
						var/obj/item/robot_module/RM = O
						modules.Remove(RM)
						RM.set_loc(R)
						R.module = RM
						R.hud.update_module()
						R.hud.module_added()
				R.update_appearance()

			if (href_list["remove"])
				if (!istype(occupant,/mob/living/silicon/robot))
					updateUsrDialog()
					return
				var/mob/living/silicon/robot/R = occupant
				var/obj/item/O = locate(href_list["remove"])

				if (istype(O,/obj/item/clothing))
					clothes.Add(O)
					O.set_loc(src)

					for (var/x in R.clothes)
						if (R.clothes[x] == O)
							R.clothes.Remove(x)
							break

					boutput(R, "<span style=\"color:red\">\the [O.name] was removed!</span>")

				if (istype(O,/obj/item/cell))
					cells.Add(O)
					O.set_loc(src)
					R.cell = null
					boutput(R, "<span style=\"color:red\">Your power cell was removed!</span>")
					logTheThing("combat", usr, R, "removes %target%'s power cell at [log_loc(usr)].") // Renders them mute and helpless (Convair880).
					R.hud.update_charge()

				if (istype(O,/obj/item/roboupgrade))
					var/obj/item/roboupgrade/U = O
					if (!U.removable)
						boutput(usr, "<span style=\"color:red\">This upgrade cannot be removed.</span>")
					else
						boutput(R, "<span style=\"color:red\">[U] was removed!</span>")
						U.upgrade_deactivate(R)
						upgrades.Add(U)
						R.upgrades.Remove(U)
						U.set_loc(loc)
						R.hud.update_upgrades()

				if (istype(O,/obj/item/robot_module))
					modules.Add(O)
					O.set_loc(src)
					boutput(R, "<span style=\"color:red\">Your module was removed!</span>")
					R.hud.update_module()
					R.uneq_all()
					R.hud.module_removed()
					R.module = null
				R.update_appearance()

			if (href_list["eject"])
				var/obj/item/O = locate(href_list["eject"])
				if (istype(O,/obj/item/cell)) cells.Remove(O)
				if (istype(O,/obj/item/roboupgrade)) upgrades.Remove(O)
				if (istype(O,/obj/item/robot_module)) modules.Remove(O)
				if (istype(O,/obj/item/clothing)) clothes.Remove(O)
				O.set_loc(loc)

			// composite borg stuff

			if (href_list["decor"])
				var/selection = href_list["decor"]
				var/mob/living/silicon/robot/R = occupant
				var/robot_cosmetic/C = null
				if (R.cosmetic_mods) C = R.cosmetic_mods
				else
					boutput(usr, "<span style=\"color:red\">ERROR: Cannot find cyborg's decorations.</span>")
					updateUsrDialog()
					return
				switch(selection)
					if ("chest")
						var/mod = input("Please select a chest decoration!", "Cyborg Decoration", null, null) in list("Nothing","Medical Insignia","Lab Coat")
						if (!mod) mod = "Nothing"
						if (mod == "Nothing") C.ches_mod = null
						else C.ches_mod = mod
					if ("head")
						var/mod = input("Please select a head decoration!", "Cyborg Decoration", null, null) in list("Nothing","Medical Mirror","Janitor Cap","Hard Hat","Afro and Shades")
						if (!mod) mod = "Nothing"
						if (mod == "Nothing") C.head_mod = null
						else C.head_mod = mod
					if ("arms")
						var/mod = input("Please select an arms decoration!", "Cyborg Decoration", null, null) in list("Nothing")
						if (!mod) mod = "Nothing"
						if (mod == "Nothing") C.arms_mod = null
						else C.arms_mod = mod
					if ("legs")
						var/mod = input("Please select a legs decoration!", "Cyborg Decoration", null, null) in list("Nothing","Disco Flares")
						if (!mod) mod = "Nothing"
						if (mod == "Nothing") C.legs_mod = null
						else C.legs_mod = mod
					if ("fx")
						C.fx[1] = input(usr,"How much red? (0 to 255)" ,"Eye and Glow", 0) as num
						C.fx[1] = max(min(C.fx[1], 255),0)
						C.fx[2] = input(usr,"How much green? (0 to 255)" ,"Eye and Glow", 0) as num
						C.fx[2] = max(min(C.fx[2], 255),0)
						C.fx[3] = input(usr,"How much blue? (0 to 255)" ,"Eye and Glow", 0) as num
						C.fx[3] = max(min(C.fx[3], 255),0)
				R.update_appearance()

			if (href_list["paint"])
				var/selection = href_list["paint"]
				var/mob/living/silicon/robot/R = occupant
				var/robot_cosmetic/C = null
				if (R.cosmetic_mods) C = R.cosmetic_mods
				else
					boutput(usr, "<span style=\"color:red\">ERROR: Cannot find cyborg's decorations.</span>")
					updateUsrDialog()
					return
				switch(selection)
					if ("add")
						C.painted = 1
						C.paint[1] = input(usr,"How much red? (0 to 150)" ,"Paint", 0) as num
						C.paint[1] = max(min(C.paint[1], 150),0)
						C.paint[2] = input(usr,"How much green? (0 to 150)" ,"Paint", 0) as num
						C.paint[2] = max(min(C.paint[2], 150),0)
						C.paint[3] = input(usr,"How much blue? (0 to 150)" ,"Paint", 0) as num
						C.paint[3] = max(min(C.paint[3], 150),0)
					if ("change")
						C.paint[1] = input(usr,"How much red? (0 to 150)" ,"Paint", 0) as num
						C.paint[1] = max(min(C.paint[1], 150),0)
						C.paint[2] = input(usr,"How much green? (0 to 150)" ,"Paint", 0) as num
						C.paint[2] = max(min(C.paint[2], 150),0)
						C.paint[3] = input(usr,"How much blue? (0 to 150)" ,"Paint", 0) as num
						C.paint[3] = max(min(C.paint[3], 150),0)
					if ("remove") C.painted = 0

		updateUsrDialog()
		return

	attackby(obj/item/W as obj, mob/user as mob)
		if (istype(W, /obj/item/clothing) && allow_clothes)
			if (!istype(W, /obj/item/clothing/mask) && !istype(W, /obj/item/clothing/head) && !istype(W, /obj/item/clothing/under) && !istype(W, /obj/item/clothing/suit))
				boutput(user, "<span style=\"color:red\">This type of is not compatible.</span>")
				return
			if (user.contents.Find(W)) user.drop_item()
			if (W in clothes)
				qdel(W)
				return
			W.set_loc(src)
			boutput(user, "You insert [W].")
			clothes.Add(W)
			return
		if (istype(W,/obj/item/robot_module))
			if (user.contents.Find(W)) user.drop_item()
			if (W in modules)
				qdel(W)
				return
			W.set_loc(src)
			boutput(user, "You insert [W].")
			modules.Add(W)
			return
		if (istype(W,/obj/item/roboupgrade))
			if (user.contents.Find(W)) user.drop_item()
			if (W in upgrades)
				qdel(W)
				return
			W.set_loc(src)
			boutput(user, "You insert [W].")
			upgrades.Add(W)
			return
		if (istype(W,/obj/item/cell))
			if (user.contents.Find(W)) user.drop_item()
			//Wire: Fix for clickdrag duplicating power cells in docks
			if (W in cells)
				qdel(W)
				return
			W.set_loc(src)
			boutput(user, "You insert [W].")
			cells.Add(W)
			return
		if (istype(W,/obj/item/cable_coil))
			var/obj/item/cable_coil/C = W
			cabling += C.amount
			boutput(user, "You insert [W]. [src] now has [cabling] cable available.")
			if (user.contents.Find(W)) user.drop_item()
			qdel(W)
			return
		if (istype(W, /obj/item/reagent_containers/glass))
			if (!W.reagents.total_volume)
				boutput(user, "<span style=\"color:red\">There is nothing in [W] to pour!</span>")
				return
			if (!reagents.has_reagent("fuel"))
				boutput(user, "<span style=\"color:red\">There's no fuel in [W]. It would be pointless to pour it in.</span>")
				return
			else
				user.visible_message("<span style=\"color:blue\">[user] pours [W:amount_per_transfer_from_this] units of [W]'s contents into [src].</span>")
				playsound(loc, "sound/effects/slosh.ogg", 100, 1)
				W.reagents.trans_to(src, W:amount_per_transfer_from_this)
				if (!W.reagents.total_volume) boutput(user, "<span style=\"color:red\"><strong>[W] is now empty.</strong></span>")
				reagents.isolate_reagent("fuel")
				return
		..()

	MouseDrop_T(atom/movable/O as mob|obj, mob/user as mob)
		if (get_dist(O,user) > 1 || get_dist(src,user) > 1) return
		if (!isliving(user) || isAI(user)) return

		if (isitem(O) && !user.stat)
			attackby(O, user)
			return

		if (isliving(O) && occupant)
			boutput(user, "<span style=\"color:red\">The cell is already occupied!</span>")
			return

		if (isrobot(O))
			var/mob/living/silicon/robot/R = O
			if (R.stat == 2)
				boutput(user, "<span style=\"color:red\">[R] is dead and cannot enter the docking station.</span>")
				return // Don't want them going in there and then blowing up anyway
			if (user != R)
				if (user.stat == 1) // Allow out-of-charge robots to recharge themselves, but nothing else.
					return
				else
					user.visible_message("<strong>[user]</strong> moves [R] into [src].")
			R.pulling = null
			R.set_loc(src)
			occupant = R
			if (R.client) attack_hand(R)
			add_fingerprint(user)
			build_icon()

		if (isshell(O))
			var/mob/living/silicon/hivebot/H = O
			if (H.stat == 2)
				boutput(user, "<span style=\"color:red\">[H] is dead and cannot enter the docking station.</span>")
				return // Don't want them going in there and then blowing up anyway
			if (user != H)
				if (user.stat == 1) // Allow out-of-charge robots to recharge themselves, but nothing else.
					return
				else
					user.visible_message("<strong>[user]</strong> moves [H] into [src].")
			H.pulling = null
			H.set_loc(src)
			occupant = H
			if (H.client)
				attack_hand(H)
			add_fingerprint(user)
			build_icon()

		else if (ishuman(O) && !user.stat)
			if (!conversion_chamber)
				boutput(user, "<span style=\"color:red\">Humans cannot enter recharging stations.</span>")
			else
				var/mob/living/carbon/human/H = O
				if (H.stat == 2)
					boutput(user, "<span style=\"color:red\">[H] is dead and cannot be forced inside.</span>")
					return
				var/delay = 0
				if (user != H)
					delay = 30
					logTheThing("combat", user, H, "puts %target% into a conversion chamber at [showCoords(x, y, z)]")
					logTheThing("diary", user, H, "puts %target% into a conversion chamber at [showCoords(x, y, z)]", "combat")
				if (delay)
					user.visible_message("<strong>[user]</strong> begins moving [H] into [src].")
					boutput(user, "Both you and [H] will need to remain still for this action to work.")
				var/turf/T1 = get_turf(user)
				var/turf/T2 = get_turf(H)
				spawn (delay)
					/* Who the *FUCK* coded this!?
					if (user.loc != T1 && user.loc != T2)
						return
					*/
					if (user.loc != T1 || H.loc != T2)
						return

					if (user != H)
						user.visible_message("<strong>[user]</strong> moves [H] into [src].")
					else
						user.visible_message("<strong>[user]</strong> climbs into [src].")
					H.pulling = null
					H.set_loc(src)
					occupant = H
					add_fingerprint(user)
					build_icon()

	proc/build_icon()
		overlays = null
		if (stat & BROKEN)
			icon_state = "station-broke"
			return
		if (stat & NOPOWER)
			return
		overlays += image('icons/obj/robot_parts.dmi', "station-pow")
		if (occupant)
			overlays += image('icons/obj/robot_parts.dmi', "station-occu")

	proc/process_occupant()
		if (occupant)
			if (occupant.loc != src)
				go_out()
				return

			if (isrobot(occupant))
				var/mob/living/silicon/robot/R = occupant
				if (!R.cell)
					return
				else if (R.cell.charge >= R.cell.maxcharge)
					R.cell.charge = R.cell.maxcharge
					return
				else
					R.cell.charge += chargerate
					use_power(50)
					return

			else if (isshell(occupant))
				var/mob/living/silicon/hivebot/H = occupant

				if (!H.cell)
					return
				else if (H.cell.charge >= H.cell.maxcharge)
					H.cell.charge = H.cell.maxcharge
					return
				else
					H.cell.charge += chargerate
					use_power(50)
					return

			else if (ishuman(occupant) && conversion_chamber)
				var/mob/living/carbon/human/H = occupant
				if (prob(80))
					playsound(loc, pick('sound/machines/mixer.ogg','sound/misc/automaton_spaz.ogg','sound/misc/automaton_ratchet.ogg','sound/effects/brrp.ogg','sound/effects/clang.ogg','sound/effects/pump.ogg','sound/effects/syringeproj.ogg'), 100, 1)
					if (prob(15)) visible_message("<span style=\"color:red\">[src] [pick("whirs","grinds","rumbles","clatters","clangs")] [pick("horribly","in a grisly manner","horrifyingly","scarily")]!</span>")
					if (prob(25))
						spawn (3)
							playsound(loc, pick('sound/effects/bloody_stab.ogg','sound/effects/attackblob.ogg','sound/effects/blobattack.ogg','sound/effects/fleshbr1.ogg','sound/misc/loudcrunch.ogg','sound/effects/snap.ogg','sound/weapons/genhit1.ogg'), 100, 1)
						spawn (6)
							if (H.gender == "female")
								playsound(loc, "sound/voice/female_scream.ogg", 30, 1)
							else
								playsound(loc, "sound/voice/male_scream.ogg", 30, 1)
							visible_message("<span style=\"color:red\">A muffled scream comes from within [src]!</span>")

				if (H.health <= 2)
					boutput(H, "<span style=\"color:red\">You feel... different.</span>")
					go_out()

					var/bdna = null // For forensics (Convair880).
					var/btype = null
					if (H.bioHolder.Uid && H.bioHolder.bloodType)
						bdna = H.bioHolder.Uid
						btype = H.bioHolder.bloodType
					gibs(loc, null, null, bdna, btype)

					H.Robotize_MK2(1)
					score_cyborgsmade += 1
					build_icon()
					playsound(loc, "sound/machines/ding.ogg", 100, 1)
				else
					H.bioHolder.AddEffect("eaten")
					random_brute_damage(H, 3)
					H.weakened = 5
					if (prob(15))
						boutput(H, "<span style=\"color:red\">[pick("You feel chunks of your flesh being ripped off!","Something cold and sharp skewers you!","You feel your organs being pulped and mashed!","Machines shred you from every direction!")]</span>")

				updateUsrDialog()


	proc/go_out()
		if (!( occupant )) return
		//for (var/obj/O in src)
		//	O.set_loc(loc)
		occupant.set_loc(loc)
		occupant = null
		build_icon()
		return

	verb/move_eject()
		set src in oview(1)
		set category = "Local"
		if (usr.stat == 2)
			return
		if (istype(usr,/mob/living/carbon/human))
			if (conversion_chamber && occupant == usr)
				boutput(usr, "<span style=\"color:red\">You're trapped inside!</span>")
				return
		go_out()
		add_fingerprint(usr)
		return

	verb/move_inside()
		set src in oview(1)
		set category = "Local"
		if (usr.stat == 2 || stat & (NOPOWER|BROKEN))
			return
		if (!istype(usr, /mob/living/silicon) && !conversion_chamber)
			boutput(usr, "<span style=\"color:red\">Only non-organics may enter the recharger!</span>")
			return
		if (occupant)
			boutput(usr, "<span style=\"color:red\">The cell is already occupied!</span>")
			return
		usr.pulling = null
		usr.set_loc(src)
		occupant = usr
		attack_hand(usr)
		/*for (var/obj/O in src)
			O.set_loc(loc)*/
		add_fingerprint(usr)
		build_icon()
		return

/obj/machinery/recharge_station/syndicate
	conversion_chamber = 1
	is_syndicate = 1
	anchored = 0

	attackby(obj/item/W as obj, mob/user as mob)
		if (istype(W, /obj/item/wrench))
			anchored = !anchored
			user.show_text("You [anchored ? "attach" : "release"] \the [src]'s floor clamps", "red")
			playsound(loc, 'sound/items/Ratchet.ogg', 40, 0, 0)
			return
		..()