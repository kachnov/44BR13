/obj/item/device/drone_control
	name = "drone control handset"
	desc = "Allows the user to remotely operate a drone."
	icon_state = "matanalyzer"
	var/signal_tag = "mining"
	flags = FPRINT | TABLEPASS | CONDUCT
	var/list/drone_list = list()

	attack_self(var/mob/user as mob)
		drone_list = list()
		for (var/mob/living/silicon/drone/D in mobs)
			if (D.signal_tag == signal_tag)
				drone_list += D

		if (drone_list.len < 1)
			boutput(user, "<span style=\"color:red\">No usable drones detected.</span>")
			return

		var/mob/living/silicon/drone/which = input("Which drone do you want to control?","Drone Controls") as mob in drone_list
		if (istype(which))
			var/attempt = which.connect_to_drone(user)
			switch(attempt)
				if (1)
					boutput(user, "<span style=\"color:red\">Connection error: Drone not found.</span>")
				if (2)
					boutput(user, "<span style=\"color:red\">Connection error: Drone already in use.</span>")

/mob/living/silicon/drone
	name = "Drone"
	var/base_name = "Drone"
	desc = "A small remote-controlled robot for doing risky work from afar."
	icon = 'icons/mob/drone.dmi'
	icon_state = "base"
	var/health_max = 100
	var/signal_tag = "mining"
	var/hud/drone/hud
	var/mob/controller = null
	var/obj/item/cell/cell = null
	var/obj/item/device/radio/radio = null
	var/obj/item/parts/robot_parts/drone/propulsion/propulsion = null
	var/obj/item/parts/robot_parts/drone/plating/plating = null
	var/list/equipment_slots = list(null, null, null, null, null)
	var/obj/item/active_tool = null
	var/material/mat_chassis = null
	var/material/mat_plating = null
	var/disabled = 0
	var/panelopen = 0
	var/sound_damaged = 'sound/effects/grillehit.ogg'
	var/sound_destroyed = 'sound/effects/robogib.ogg'
	var/list/beeps_n_boops = list('sound/machines/twobeep.ogg','sound/machines/ping.ogg','sound/machines/chime.ogg','sound/machines/buzz-two.ogg','sound/machines/buzz-sigh.ogg')
	var/list/glitchy_noise = list('sound/effects/glitchy1.ogg','sound/effects/glitchy2.ogg','sound/effects/glitchy3.ogg')
	var/list/glitch_con = list("kind of","a little bit","somewhat","a bit","slightly","quite","rather")
	var/list/glitch_adj = list("scary","weird","freaky","crazy","demented","horrible","ghastly","egregious","unnerving")

	New()
		..()
		name = "Drone [rand(1,9)]*[rand(10,99)]"
		base_name = name
		hud = new(src)
		attach_hud(hud)

		var/obj/item/cell/CELL = new /obj/item/cell(src)
		CELL.charge = CELL.maxcharge
		cell = CELL

		radio = new /obj/item/device/radio(src)
		ears = radio

		var/obj/item/mining_tool/drill/D = new /obj/item/mining_tool/drill(src)
		equipment_slots[1] = D
		var/obj/item/ore_scoop/borg/S = new /obj/item/ore_scoop/borg(src)
		equipment_slots[2] = S
		var/obj/item/oreprospector/O = new /obj/item/oreprospector(src)
		equipment_slots[3] = O

		health = health_max
		botcard.access = get_all_accesses()

	Life(controller/process/mobs/parent)
		set invisibility = 0

		if (..(parent))
			return TRUE

		if (transforming)
			return

		//hud.update_health()
		if (hud)
			hud.update_charge()
			hud.update_tools()

		if (observers.len)
			for (var/mob/x in observers)
				if (x.client)
					updateOverlaysClient(x.client)

	examine()
		..()
		if (controller)
			boutput(usr, "It is currently active and being controlled by someone.")
		else
			boutput(usr, "It is currently shut down and not being used.")
		if (health < 100)
			if (health < 50)
				boutput(usr, "<span style=\"color:red\">It's rather badly damaged. It probably needs some wiring replaced inside.</span>")
			else
				boutput(usr, "<span style=\"color:red\">It's a bit damaged. It looks like it needs some welding done.</span>")

	movement_delay()
		var/tally = 0
		for (var/obj/item/parts/robot_parts/drone/DP in contents)
			tally += DP.weight
		if (propulsion && istype(propulsion))
			tally -= propulsion.speed
		return tally

	attackby(obj/item/W as obj, mob/user as mob)
		if (istype(W, /obj/item/weldingtool))
			var/obj/item/weldingtool/WELD = W
			if (user.a_intent == INTENT_HARM)
				if (WELD.welding)
					user.visible_message("<span style=\"color:red\"><strong>[user] burns [src] with [W]!</strong></span>")
					damage_heat(WELD.force)
				else
					user.visible_message("<span style=\"color:red\"><strong>[user] beats [src] with [W]!</strong></span>")
					damage_blunt(WELD.force)
			else
				if (health >= health_max)
					boutput(user, "<span style=\"color:red\">It isn't damaged!</span>")
					return
				if (get_x_percentage_of_y(health,health_max) < 33)
					boutput(user, "<span style=\"color:red\">You need to use wire to fix the cabling first.</span>")
					return
				if (WELD.get_fuel() > 1)
					health = max(1,min(health + 10,health_max))
					WELD.use_fuel(1)
					playsound(loc, "sound/items/Welder.ogg", 50, 1)
					user.visible_message("<strong>[user]</strong> uses [WELD] to repair some of [src]'s damage.")
					if (health == health_max)
						boutput(user, "<span style=\"color:blue\"><strong>[src] looks fully repaired!</strong></span>")
				else
					boutput(user, "<span style=\"color:red\">You need more welding fuel!</span>")

		else if (istype(W,/obj/item/cable_coil))
			if (health >= health_max)
				boutput(user, "<span style=\"color:red\">It isn't damaged!</span>")
				return
			var/obj/item/cable_coil/C = W
			if (get_x_percentage_of_y(health,health_max) >= 33)
				boutput(usr, "<span style=\"color:red\">The cabling looks fine. Use a welder to repair the rest of the damage.</span>")
				return
			C.use(1)
			health = max(1,min(health + 10,health_max))
			user.visible_message("<strong>[user]</strong> uses [C] to repair some of [src]'s cabling.")
			playsound(loc, "sound/items/Deconstruct.ogg", 50, 1)
			if (health >= 50)
				boutput(user, "<span style=\"color:blue\">The wiring is fully repaired. Now you need to weld the external plating.</span>")

		else
			user.visible_message("<span style=\"color:red\"><strong>[user] attacks [src] with [W]!</strong></span>")
			damage_blunt(W.force)

	proc/take_damage(var/amount)
		if (!isnum(amount))
			return

		health = max(0,min(health - amount,100))

		if (amount > 0)
			playsound(loc, sound_damaged, 50, 2)
			if (health == 0)
				visible_message("<span style=\"color:red\"><strong>[name] is destroyed!</strong></span>")
				disconnect_user()
				robogibs(loc,null)
				playsound(loc, sound_destroyed, 50, 2)
				qdel(src)
				return

	damage_blunt(var/amount)
		if (!isnum(amount) || amount <= 0)
			return
		take_damage(amount)

	damage_heat(var/amount)
		if (!isnum(amount) || amount <= 0)
			return
		take_damage(amount)

	swap_hand(var/switchto = 0)
		if (!isnum(switchto))
			active_tool = null
		else
			if (active_tool && isitem(active_tool))
				var/obj/item/I = active_tool
				I.dropped(src) // Handle light datums and the like.
			switchto = max(1,min(switchto,5))
			active_tool = equipment_slots[switchto]
			if (isitem(active_tool))
				var/obj/item/I2 = active_tool
				I2.pickup(src) // Handle light datums and the like.

		hud.set_active_tool(switchto)

	click(atom/target, params)
		if ((!disable_next_click || ismob(target) || (target && target.flags & USEDELAY) || (active_tool && active_tool.flags & USEDELAY)) && world.time < next_click)
			return

		var/inrange = in_range(target, src)
		var/obj/item/W = active_tool
		if ((W && (inrange || (W.flags & EXTRADELAY))))
			target.attackby(W, src)
			if (W)
				W.afterattack(target, src, inrange)

		if (get_dist(src, target) > 0)
			dir = get_dir(src, target)

		if (!disable_next_click || ismob(target) || (target && target.flags & USEDELAY) || (W && W.flags & USEDELAY))
			if (world.time < next_click)
				return next_click - world.time
			next_click = world.time + 5

	Bump(atom/movable/AM as mob|obj, yes)
		spawn ( 0 )
			if ((!( yes ) || now_pushing))
				return
			now_pushing = 1
			if (ismob(AM))
				var/mob/tmob = AM
				if (istype(tmob, /mob/living/carbon/human) && tmob.bioHolder && tmob.bioHolder.HasEffect("fat"))
					visible_message("<span style=\"color:red\"><strong>[src]</strong> can't get past [AM.name]'s fat ass!</span>")
					now_pushing = 0
					unlock_medal("That's no moon, that's a GOURMAND!", 1)
					return
			now_pushing = 0
			..()
			if (!istype(AM, /atom/movable))
				return
			if (!now_pushing)
				now_pushing = 1
				if (!AM.anchored)
					var/t = get_dir(src, AM)
					step(AM, t)
				now_pushing = null
			return
		return

	say(var/message)
		if (!message)
			return

		if (client && client.ismuted())
			boutput(src, "You are currently muted.")
			return

		if (stat == 2)
			message = trim(copytext(sanitize(message), 1, MAX_MESSAGE_LEN))
			return say_dead(message)

		// wtf?
		if (stat)
			return

		if (copytext(message, 1, 2) == "*")
			..()
		else
			visible_message("<strong>[src]</strong> beeps.")
			playsound(loc, beeps_n_boops[1], 30, 1)

	emote(var/act)
		//var/param = null
		if (findtext(act, " ", 1, null))
			var/t1 = findtext(act, " ", 1, null)
			//param = copytext(act, t1 + 1, length(act) + 1)
			act = copytext(act, 1, t1)

		var/message
		var/sound/emote_sound = null

		switch(act)
			if ("help")
				boutput(src, "To use emotes, simply enter \"*(emote)\" as the entire content of a say message. Certain emotes can be targeted at other characters - to do this, enter \"*emote (name of character)\" without the brackets.")
				boutput(src, "For a list of basic emotes, use *listbasic. For a list of emotes that can be targeted, use *listtarget.")
			if ("listbasic")
				boutput(src, "ping, chime, madbuzz, sadbuzz")
			if ("listtarget")
				boutput(src, "Drones do not currently have any targeted emotes.")
			if ("ping")
				emote_sound = beeps_n_boops[2]
				message = "<strong>[src]</strong> pings!"
			if ("chime")
				emote_sound = beeps_n_boops[3]
				message = "<strong>[src]</strong> emits a pleased chime."
			if ("madbuzz")
				emote_sound = beeps_n_boops[4]
				message = "<strong>[src]</strong> buzzes angrily!"
			if ("sadbuzz")
				emote_sound = beeps_n_boops[5]
				message = "<strong>[src]</strong> buzzes dejectedly."
			if ("glitch","malfunction")
				playsound(loc, pick(glitchy_noise), 50, 1)
				visible_message("<span style=\"color:red\"><strong>[src]</strong> freaks the fuck out! That's [pick(glitch_con)] [pick(glitch_adj)]!</span>")
				animate_glitchy_freakout(src)
				return

		if (emote_sound)
			playsound(loc, emote_sound, 50, 1)
		if (message)
			visible_message(message)
		return

	get_equipped_ore_scoop()
		if (equipment_slots[1] && istype(equipment_slots[1],/obj/item/ore_scoop))
			return equipment_slots[1]
		else if (equipment_slots[2] && istype(equipment_slots[2],/obj/item/ore_scoop))
			return equipment_slots[2]
		else if (equipment_slots[3] && istype(equipment_slots[3],/obj/item/ore_scoop))
			return equipment_slots[3]
		else if (equipment_slots[4] && istype(equipment_slots[4],/obj/item/ore_scoop))
			return equipment_slots[4]
		else if (equipment_slots[5] && istype(equipment_slots[5],/obj/item/ore_scoop))
			return equipment_slots[5]
		else
			return null

	proc/connect_to_drone(var/mob/living/L)
		if (!L || !src)
			return TRUE
		if (controller)
			return 2

		boutput(L, "You connect to [name].")
		controller = L
		L.mind.transfer_to(src)
		return FALSE

	proc/disconnect_user()
		if (!controller)
			return

		boutput(controller, "You were disconnected from [name].")
		mind.transfer_to(controller)
		controller = null

// DRONE ITEM/OBJ STUFF, TRANSFER IT ELSEWHERE LATER

/obj/drone_frame
	name = "drone frame"
	desc = "It's a remote-controlled drone in the middle of being constructed."
	icon = 'icons/mob/drone.dmi'
	icon_state = "frame-0"
	opacity = 0
	density = 0
	anchored = 0
	var/construct_stage = 0
	var/obj/item/device/radio/part_radio = null
	var/obj/item/cell/part_cell = null
	var/obj/item/parts/robot_parts/drone/propulsion/part_propulsion = null
	var/obj/item/parts/robot_parts/drone/plating/part_plating = null
	var/obj/item/cable_coil/cable_type = null

	proc/change_stage(var/change_to,var/mob/user,var/obj/item/item_used)
		if (!isnum(change_to))
			return
		playsound(loc, 'sound/items/Deconstruct.ogg', 50, 1)
		if (user && item_used)
			user.drop_item()
			item_used.set_loc(src)

		icon_state = "frame-" + max(0,min(change_to,6))
		overlays = list()
		if (part_propulsion && part_propulsion.drone_overlay)
			overlays += part_propulsion.drone_overlay

	examine()
		..()
		switch(construct_stage)
			if (0)
				boutput(usr, "It's nothing but a pile of scrap right now. Wrench the parts together to build it up or weld it back down to metal sheets.")
			if (1)
				boutput(usr, "It's still a bit rickety. Weld it to make it more secure or wrench it to take it apart.")
			if (2)
				boutput(usr, "It needs cabling. Add some to build it up or take the circuit board out to deconstruct it.")
			if (3)
				boutput(usr, "A radio needs to be added, or you could take the cabling out to deconstruct it.")
			if (4)
				boutput(usr, "A power cell needs to be added, or you could remove the radio to deconstruct it.")
			if (5)
				boutput(usr, "It needs a propulsion system, or you could remove the power cell to deconstruct it.")
			if (6)
				boutput(usr, "It looks almost finished, all that's left to add is extra optional components.")
				boutput(usr, "Wrench it together to activate it, or remove all parts and the power cell to deconstruct it.")

	attack_hand(var/mob/user as mob)
		switch(construct_stage)
			if (3)
				user.put_in_hand_or_drop(cable_type)
				cable_type = null
				change_stage(2)
			if (4)
				user.put_in_hand_or_drop(part_radio)
				part_radio = null
				change_stage(3)
			if (5)
				user.put_in_hand_or_drop(part_cell)
				part_cell = null
				change_stage(4)
			if (6)
				user.put_in_hand_or_drop(part_propulsion)
				part_propulsion = null
				change_stage(5)
			else
				boutput(usr, "You can't figure out what to do with it. Maybe a closer examination is in order.")

	attackby(obj/item/W as obj, mob/user as mob)
		if (istype(W, /obj/item/weldingtool))
			var/obj/item/weldingtool/WELD = W
			if (WELD.get_fuel() > 1)
				switch(construct_stage)
					if (0)
						visible_message("<strong>[user]</strong> welds [src] back down to metal.")
						playsound(loc, 'sound/items/Welder.ogg', 50, 1)
						var/obj/item/sheet/S = new /obj/item/sheet(loc)
						S.amount = 5

						if (material)
							S.setMaterial(material)
						else
							var/material/M = getCachedMaterial("steel")
							S.setMaterial(M)

						qdel(src)
					if (1)
						visible_message("<strong>[user]</strong> welds [src]'s joints together.")
						construct_stage = 2
						WELD.use_fuel(1)
						playsound(loc, 'sound/items/Welder.ogg', 50, 1)
					if (2)
						visible_message("<strong>[user]</strong> disconnects [src]'s welded joints.")
						construct_stage = 1
						WELD.use_fuel(1)
						playsound(loc, 'sound/items/Welder.ogg', 50, 1)
					else
						boutput(user, "<span style=\"color:red\">[user.real_name], there's a time and a place for everything! But not now.</span>")
			else
				boutput(user, "<span style=\"color:red\">Need more welding fuel!</span>")

		else if (istype(W, /obj/item/wrench))
			switch(construct_stage)
				if (0)
					change_stage(1)
					playsound(loc, 'sound/items/Ratchet.ogg', 50, 1)
					visible_message("<strong>[user]</strong> wrenches together [src]'s parts.")
				if (1)
					change_stage(0)
					playsound(loc, 'sound/items/Ratchet.ogg', 50, 1)
					visible_message("<strong>[user]</strong> wrenches [src] apart.")
				if (6)
					var/confirm = alert("Finish and activate the drone?","Drone Assembly","Yes","No")
					if (confirm != "Yes")
						return
					visible_message("<strong>[user]</strong> finishes up and activates [src].")
					playsound(loc, 'sound/items/Ratchet.ogg', 50, 1)
					var/mob/living/silicon/drone/D = new /mob/living/silicon/drone(loc)
					if (part_cell)
						D.cell = part_cell
						part_cell.loc = D
					if (part_radio)
						D.radio = part_radio
						part_radio.loc = D
					if (part_propulsion)
						D.propulsion = part_propulsion
						part_propulsion.loc = D
					if (part_plating)
						D.plating = part_plating
						part_plating.loc = D
					qdel(src)
				else
					boutput(user, "<span style=\"color:red\">There's lots of good times to use a wrench, but this isn't one of them.</span>")

		else if (istype(W, /obj/item/cable_coil) && construct_stage == 2)
			var/obj/item/cable_coil/C = W
			visible_message("<strong>[user]</strong> adds [C] to [src].")
			cable_type = C.take(1, src)
			change_stage(3)

		else if (istype(W, /obj/item/device/radio) && construct_stage == 3)
			visible_message("<strong>[user]</strong> adds [W] to [src].")
			part_radio = W
			change_stage(4,user,W)

		else if (istype(W, /obj/item/cell) && construct_stage == 4)
			visible_message("<strong>[user]</strong> adds [W] to [src].")
			part_cell = W
			change_stage(5,user,W)

		else if (istype(W, /obj/item/parts/robot_parts/drone/propulsion) && construct_stage == 5)
			visible_message("<strong>[user]</strong> adds [W] to [src].")
			part_propulsion = W
			change_stage(6,user,W)

		else
			..()

// DRONE PARTS

/obj/item/parts/robot_parts/drone
	name = "drone part"
	icon = 'icons/mob/drone.dmi'
	desc = "It's a component intended for remote controlled drones. This one happens to be invisible and unusuable. Some things are like that."
	var/image/drone_overlay = null

/obj/item/parts/robot_parts/drone/propulsion
	name = "drone wheels"
	desc = "The most cost-effective movement available for drones. Won't do very good in space, though!"
	var/speed = 0

	New()
		..()
		drone_overlay = image('icons/mob/drone.dmi',"wheels")

/obj/item/parts/robot_parts/drone/plating
	name = "drone plating"
	desc = "Armor for a remote controlled drone."

	New()
		..()
		drone_overlay = image('icons/mob/drone.dmi',"plating-0")