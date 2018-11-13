////////// cogwerks - stuff for the precursor ruins and some other various solarium-related puzzles ///////
///////////////////////////////////////////////////////////////////////////////////////////////////////////
/////// contents:
/////// --------
/////// horrible saxophone thing
/////// orb-teleporter
/////// sound-reactive doors
/////// sound-reactive artifacts
////////////////////////////////





/obj/item/hell_sax
	name = "curious instrument"
	desc = "It appears to be a musical instrument of some sort."
	icon = 'icons/obj/artifacts/artifactsitem.dmi'
	icon_state = "precursor-1" // temp
	inhand_image_icon = 'icons/mob/inhand/hand_general.dmi'
	item_state = "precursor" // temp
	w_class = 3
	force = 1
	throwforce = 5
	var/spam_flag = 0
	var/pitch = 0
	module_research = list("audio" = 20, "precursor" = 3)

/obj/item/hell_sax/attack_self(mob/user as mob)
	if (spam_flag == 0)
		spam_flag = 1

		var/usernum = round(input("Select a note to play: 0-12?") as null|num)
		if (isnull(usernum))
			return
		if (usernum < 0) usernum = 0
		if (usernum > 12) usernum = 12
		if (!usernum) usernum = 0
		pitch = usernum

		if (!(src in user.contents)) // did they drop it while the input was up
			spam_flag = 0
			return

		user.visible_message("<span style=\"color:red\"><strong>[user]</strong> blasts out [pick("a grody", "a horrifying", "an eldritch","a hideous","a jazzy","a funky","a terrifying","an awesome","a deathly")] note on [src]!</span>")
		var/horn_note = 'sound/items/hellhorn_0.ogg'

		switch(pitch) // heh
			if (0)
				horn_note = 'sound/items/hellhorn_0.ogg'
			if (1)
				horn_note = 'sound/items/hellhorn_1.ogg'
			if (2)
				horn_note = 'sound/items/hellhorn_2.ogg'
			if (3)
				horn_note = 'sound/items/hellhorn_3.ogg'
			if (4)
				horn_note = 'sound/items/hellhorn_4.ogg'
			if (5)
				horn_note = 'sound/items/hellhorn_5.ogg'
			if (6)
				horn_note = 'sound/items/hellhorn_6.ogg'
			if (7)
				horn_note = 'sound/items/hellhorn_7.ogg'
			if (8)
				horn_note = 'sound/items/hellhorn_8.ogg'
			if (9)
				horn_note = 'sound/items/hellhorn_9.ogg'
			if (10)
				horn_note = 'sound/items/hellhorn_10.ogg'
			if (11)
				horn_note = 'sound/items/hellhorn_11.ogg'
			if (12)
				horn_note = 'sound/items/hellhorn_12.ogg'

		playsound(get_turf(src), horn_note, 50, 0)
		for (var/atom/A in range(user, 5))
			if (istype(A, /obj/critter/dog/george))
				var/obj/critter/dog/george/G = A
				if (prob(60))
					G.howl()
			if (istype(A, /mob/living/carbon/human))
				var/mob/living/carbon/human/H = A
				H.emote(pick("shiver","shudder"))
				H.change_misstep_chance(5)
				shake_camera(H, 25, 2)
			if (istype(A, /obj/precursor_puzzle/glowing_door))
				var/obj/precursor_puzzle/glowing_door/D = A
				if (pitch == D.pitch)
					D.toggle()
			if (istype(A, /obj/precursor_puzzle/machine))
				var/obj/precursor_puzzle/machine/M = A
				if (pitch in M.pitches)
					if (M.active)
						M.deactivate()
					if (!M.active)
						M.activate()

		add_fingerprint(user)
		spawn (60)
			spam_flag = 0
	return


// pedestal for STUFF ///


/obj/rack/precursor
	name = "cold pedestal"
	desc = "It holds stuff. And things."
	icon = 'icons/obj/artifacts/artifacts.dmi'
	icon_state = "precursor-1"
	var/id = 1

	ex_act(severity)
		return

	attackby(obj/item/W as obj, mob/user as mob)
	/*	if (istype(W,/obj/item/skull)) // placeholder
			playsound(loc, "sound/machines/ArtifactPre1.ogg", 50, 1)
			visible_message("<span style=\"color:blue\"><strong>Something activates inside [src]!</strong></span>")

			if (id)
				if (istype(id, /list))
					for (var/sub_id in id)
						var/obj/precursor_puzzle/glowing_door/target_door = locate(sub_id)
						if (istype(target_door))
							target_door.toggle()
				else
					var/obj/iomoon_puzzle/ancient_robot_door/target_door = locate(id)
					if (istype(target_door))
						target_door.toggle()

			if (!overlays.len)
				overlays += icon('icons/obj/artifacts/artifacts.dmi',"precursor-1fx")*/
		if (istype(user,/mob/living/silicon/robot)) return
		user.drop_item()
		if (W && W.loc)	W.set_loc(loc)
		return

/obj/item/chilly_orb // borb
	name = "chilly orb"
	desc = "Neat."
	icon = 'icons/obj/artifacts/puzzles.dmi'
	icon_state = "orb"
	var/id = "ENTRY" // default

/obj/precursor_puzzle/orb_stand
	name = "cold device"
	icon = 'icons/obj/artifacts/puzzles.dmi'
	icon_state = "orb_holder"
	desc = "It seems to be missing something."
	density = 1
	anchored = 1
	var/id = 1
	var/target_id = 1
	var/assembled = 0
	var/ready = 0

	New()
		..()
		if (assembled)
			icon_state = "orb_activated"
			desc = "Whatever it is, it seems to be active."
			ready = 1 // just in case, i guess
		else
			icon_state = "orb_holder"
			desc = "It seems to be missing something."
			ready = 0 // precautionary

		if (!id)
			id = "generic"

		tag = "orb_stand_[id]"

	attack_hand(mob/user as mob)
		if (user.stat || user.weakened || get_dist(user, src) > 1)
			return

		if (!assembled)
			boutput(user, "<span style=\"color:blue\">[src] is missing something.</span>")
			return

		if (!ready)
			boutput(user, "<span style=\"color:blue\">[src] isn't ready yet.</span>")
			return

		var/obj/precursor_puzzle/orb_stand/other = locate("orb_stand_[target_id]")
		if (!istype(other))
			return

		spawn (1)
			ready = 0 // disable momentarily to prevent spamming
			user.visible_message("<span style=\"color:red\"><strong>[user] is warped away by [src]! Holy shit!</strong></span>")
			var/otherside = get_turf(other)
			user.set_loc(otherside)
			explosion(src,loc,-1,-1,1,2)
			playsound(loc, "explosion", 60, 1)
			explosion(src,otherside,-1,-1,1,2)
			if (ishuman(user))
				var/mob/living/carbon/human/H = user
				H:update_burning(5) // this isn't a safe way to travel at all!!!
			sleep(50)
			ready = 1

	attackby(obj/item/W as obj, mob/user as mob)
		if (ready || assembled)
			..()
			return

		if (istype(W, /obj/item/chilly_orb))
			var/obj/item/chilly_orb/O = W
			if (O.id == id)
				boutput(user, "<span style=\"color:blue\"><strong>[O] attaches neatly to [src]. Oh dear.</span>")
				playsound(loc, "sound/items/Deconstruct.ogg", 60, 1)
				user.drop_item(O)
				O.set_loc(src)
				icon_state = "orb_activated"
				assembled = 1
				sleep(5)
				visible_message("<span style=\"color:blue\"><strong>[src] makes a strange noise!</strong></span>")
				playsound(loc, "sound/machines/ArtifactPre1.ogg", 60, 1)
				ready = 1
				return
			else
				boutput(user, "<span style=\"color:blue\"><strong>[src] don't seem to quite fit together with [O].</span>")

		else if (istype(W, /obj/item/basketball) && !assembled) // sailor dave thinks the bball is the orb, this will really fuck with his day
			user.visible_message("<span style=\"color:blue\"><strong>[user] slams [W] down onto [src]'s central spike.</strong></span>")
			sleep(1)
			user.visible_message("<span style=\"color:red\"><strong>[W] violently pops! Way to go, jerk!</span>")
			user.drop_item(W)
			playsound(loc, "sound/effects/bang.ogg", 75, 1)
			playsound(loc, "sound/machines/hiss.ogg", 75, 1)
			explosion(src, loc, -1,-1,1,1)
			user:emote("scream")
			qdel(W)


		else
			..()
			return

/obj/precursor_puzzle/glowing_door
	name = "glowing edifice"
	desc = "You can faintly make out a pattern of fissures and seams along the surface."
	icon = 'icons/misc/worlds.dmi'
	icon_state = "bluedoor_1"
	density = 1
	anchored = 1
	opacity = 1
	var/active = 0
	var/opened = 0
	var/changing_state = 0
	var/default_state = 0 //0: closed, 1: open
	var/pitch = 0

	New()
		..()
		spawn (5)
			default_state = opened
			active = 0
			pitch = rand(0,12)

	attackby(obj/item/W as obj, mob/user as mob)
		if (istype(W, /obj/item/hell_sax) && !opened)
			..()
			user.visible_message("<span style=\"color:blue\"><strong>[src] [pick("rings", "dings", "chimes","vibrates","oscillates")] [pick("faintly", "softly", "loudly", "weirdly", "scarily", "eerily")].</strong></span>")
			var/door_note = 'sound/machines/chime_0.ogg'

			switch(pitch) // heh
				if (0)
					door_note = 'sound/machines/chime_0.ogg'
				if (1)
					door_note = 'sound/machines/chime_1.ogg'
				if (2)
					door_note = 'sound/machines/chime_2.ogg'
				if (3)
					door_note = 'sound/machines/chime_3.ogg'
				if (4)
					door_note = 'sound/machines/chime_4.ogg'
				if (5)
					door_note = 'sound/machines/chime_5.ogg'
				if (6)
					door_note = 'sound/machines/chime_6.ogg'
				if (7)
					door_note = 'sound/machines/chime_7.ogg'
				if (8)
					door_note = 'sound/machines/chime_8.ogg'
				if (9)
					door_note = 'sound/machines/chime_9.ogg'
				if (10)
					door_note = 'sound/machines/chime_10.ogg'
				if (11)
					door_note = 'sound/machines/chime_11.ogg'
				if (12)
					door_note = 'sound/machines/chime_12.ogg'
			playsound(loc, door_note, 60, 0)
			return

		else
			..()
			return

	proc
		open()
			if (opened || changing_state == 1)
				return

			opened = 1
			changing_state = 1
			active = (opened != default_state)
			playsound(loc, "sound/effects/rockscrape.ogg", 50, 1)
			visible_message("<strong>[src] slides open.</strong>")
			flick("bluedoor_opening",src)
			icon_state = "bluedoor_0"
			density = 0
			opacity = 0
			spawn (13)
				changing_state = 0
			return


		close()
			if (!opened || changing_state == -1)
				return

			opened = 0
			changing_state = -1
			active = (opened != default_state)

			density = 1
			opacity = 1
			playsound(loc,"sound/effects/rockscrape.ogg", 50, 1)
			visible_message("<strong>[src] slides shut.</strong>")
			flick("bluedoor_closing",src)
			icon_state = "bluedoor_1"
			spawn (13)
				changing_state = 0
			return

		toggle()
			if (opened)
				return close()
			else
				return open()

		activate()
			if (active)
				return

			if (opened)
				return close()

			return open()

		deactivate()
			if (!active)
				return

			if (opened)
				return close()

			return open()


/obj/precursor_puzzle/machine
	name = "peculiar machine"
	desc = "You're not really sure of what this does."
	icon = 'icons/obj/artifacts/artifacts.dmi'
	icon_state = "precursor-2"
	density = 1
	anchored = 1
	opacity = 1
	var/active = 0
	var/list/pitches = list()
	var/icon/effect_icon = null
	var/function = "projectile"
	var/obj/linked_object = null
	var/projectile/plaser = new/projectile/laser/precursor
	var/id = 1
	var/light/light

	New()
		..()
		name = "[pick("quirky","wierd","strange","cold","odd","janky","metallic","smooth","oblong","swag")] [pick("device","doodad","gizmo","machine","emitter","statue","thingmabob")]"
		effect_icon = icon(icon, "[icon_state]fx") // figure out what to flick ahead of time


		pitches += rand(0,3)
		pitches += rand(4,8)
		pitches += rand(9,12)

		light = new /light/point
		light.attach(src)
		light.set_color(0.3,0.6,0.8)
		light.set_brightness(0.4)

		if (active) // does it start on?
			activate()

		if (function == "electrical")
			spawn (40)
				linked_object = locate("sphere_[id]")

		return

	proc
		activate()
			if (active) return

			switch(function)
				if ("projectile" || null) // copied from singularity emitter code
					animate_effect()
					shoot_projectile_DIR(src, plaser, dir)
					visible_message("<span style=\"color:red\"><strong>[src]</strong> fires a bolt of energy!</span>")

					if (prob(35))
						var/effects/system/spark_spread/s = unpool(/effects/system/spark_spread)
						s.set_up(5, 1, src)
						s.start()

				if ("electrical")
					if (!linked_object)
						return
					light.enable()
					animate_effect()
					playsound(loc, "sound/effects/warp1.ogg", 65, 1)
					visible_message("<span style=\"color:red\"><strong>[src]</strong> charges up!</span>")
					sleep(5)
					playsound(src, "sound/effects/elec_bigzap.ogg", 40, 1)

					var/list/lineObjs
					lineObjs = DrawLine(src, linked_object, /obj/line_obj/elec, 'icons/obj/projectiles.dmi',"WholeLghtn",1,1,"HalfStartLghtn","HalfEndLghtn",FLY_LAYER,1,PreloadedIcon='icons/effects/LghtLine.dmi')

					for (var/mob/living/poorSoul in range(linked_object, 3))
						//lineObjs += DrawLine(linked_object, poorSoul, /obj/line_obj/elec, 'icons/obj/projectiles.dmi',"WholeLghtn",1,1,"HalfStartLghtn","HalfEndLghtn",FLY_LAYER,1,PreloadedIcon='icons/effects/LghtLine.dmi')

						arcFlash(src, poorSoul, 15000)
						/*poorSoul << sound('sound/effects/electric_shock.ogg', volume=50)
						random_burn_damage(poorSoul, 15) // let's not be too mean
						boutput(poorSoul, "<span style=\"color:red\"><strong>You feel a powerful shock course through your body!</strong></span>")
						poorSoul.unlock_medal("HIGH VOLTAGE", 1)
						poorSoul:Virus_ShockCure(poorSoul, 100)
						poorSoul:shock_cyberheart(100)
						poorSoul:weakened += rand(1,2)*/
						if (poorSoul.stat == 2 && prob(15))
							poorSoul.gib()

					spawn (6)
						for (var/obj/O in lineObjs)
							pool(O)
						light.disable()





			sleep(5)
			active = 0

		animate_effect()
			if (overlays.len)
				return
			overlays += effect_icon
			sleep(15)
			overlays -= effect_icon

		deactivate()
			if (!active) return
			if (overlays.len)
				overlays = null
			active = 0


/obj/precursor_puzzle/rotator
	name = "peculiar machine"
	desc = "It looks like it can be moved somehow."
	icon = 'icons/obj/artifacts/artifacts.dmi'
	icon_state = "precursor-6"
	density = 1
	anchored = 1
	opacity = 1
	dir = 4 // facing right or left
	var/active = 0
	var/id = 1
	var/obj/precursor_puzzle/controller/linked_controller = null
	var/setting = "blue"
	var/setting_red = 0
	var/setting_green = 0
	var/setting_blue = 1

	New()
		..()
		name = "[pick("ominous","tall","bulky","chilly","pointy","spinny","metallic","smooth","oblong","dapper")] [pick("device","doodad","gizmo","machine","column","thing","thingmabob")]"
		//boutput(world, "[src] is checking for controller")
		spawn (10) // wait for the game to get started, then set up linkages with the controller object
			linked_controller = locate("controller_[id]")
			if (linked_controller)
				if (linked_controller) // just in case
					switch(dir)
						if (1)
							if (!linked_controller.effector_NE)
								linked_controller.effector_NE = src
						if (2)
							if (!linked_controller.effector_SW)
								linked_controller.effector_SW = src
						if (4) // if the rotator is facing right, it's sitting along the left wall
							if (!linked_controller.effector_SE)
								linked_controller.effector_SE = src
						if (8)
							if (!linked_controller.effector_NW)
								linked_controller.effector_NW = src
						else
							return // oh good you set it up wrong IDIOT


	attack_hand(mob/user as mob)
		if (active)	return
		active = 1

		visible_message("<span style=\"color:blue\"><strong>[user] turns [src].</strong></span>")
		playsound(loc, "sound/effects/stoneshift.ogg", 60, 1)
		icon = 'icons/obj/artifacts/puzzles.dmi'
		icon_state = "column_spin"
		sleep(10)
		icon = 'icons/obj/artifacts/artifacts.dmi'
		icon_state = "precursor-6"
		playsound(loc, "sound/machines/click.ogg", 60, 1)

		switch(setting) // roll to next color
			if ("red")
				setting = "green"
				setting_red = 0
				setting_green = 0.25
				setting_blue = 0
			if ("green")
				setting = "blue"
				setting_red = 0
				setting_green = 0
				setting_blue = 0.25
			if ("blue")
				setting = "off"
				setting_red = 0
				setting_green = 0
				setting_blue = 0
			else
				setting = "red"
				setting_red = 0.25
				setting_green = 0
				setting_blue = 0



		update_controller()

		active = 0

		return

	proc
		update_controller()
			if (linked_controller)
				linked_controller.update()
			return



/obj/precursor_puzzle/controller
	name = "peculiar panel"
	desc = "It looks like it's some sort of relay device, maybe."
	icon = 'icons/obj/artifacts/puzzles.dmi'
	icon_state = "controller_on"
	density = 1
	anchored = 1
	opacity = 1
	var/active = 0
	var/id = 1
	var/list/linked_shields = list()
	var/obj/precursor_puzzle/rotator/effector_NE = null
	var/obj/precursor_puzzle/rotator/effector_NW = null
	var/obj/precursor_puzzle/rotator/effector_SE = null
	var/obj/precursor_puzzle/rotator/effector_SW = null
	var/target_red = 0
	var/target_green = 0
	var/target_blue = 0
	////////////////////////////

	New()
		..()
		name = "[pick("little","odd","shiny","janky","quirky","swag")] [pick("indicator","relay","panel","trinket","fixture","whatsit")]"
		tag = "controller_[id]"

		// total value across r g b cannot exceed 1 point or the color will be unmixable
		// the goal is to use the four effector columns to reach the target values
		// each effector can assign 0.25 to one color channel, or be off


		var/limit_left = 4
		target_red = rand(1, prob(50) ? 4 : 3)
		limit_left -= target_red
		target_red *= 0.25

		target_green = (limit_left) ? rand(1, limit_left) : 0
		limit_left -= target_green
		target_green *= 0.25


		target_blue = (limit_left) ? rand(1, limit_left) : 0
		limit_left -= target_blue
		target_blue *= 0.25

		var/limit_check = target_red + target_green + target_blue

		while (limit_check > 1)
			target_red = pick(0,0.25,0.50,0.75,1)
			target_green = pick(0,0.25,0.50,0.75,1)
			target_blue = pick(0,0.25,0.50,0.75,1)
			limit_check = target_red + target_green + target_blue

			// this probably isn't the smartest way to deal with the problem
			// rerolling the results until they are at a safe value


		spawn (10) // set up linkages to the shields
			for (var/obj/precursor_puzzle/shield/S in range(src,7))
				if (S.id == id)
					linked_shields += S
				else
					return

	proc
		update()
			if (active) return
			active = 1
			spawn (5)
				active = 0

			var/setting_red = effector_NE.setting_red + effector_SE.setting_red + effector_SW.setting_red + effector_NW.setting_red
			var/setting_green = effector_NE.setting_green + effector_SE.setting_green + effector_SW.setting_green + effector_NW.setting_green
			var/setting_blue = effector_NE.setting_blue + effector_SE.setting_blue + effector_SW.setting_blue + effector_NW.setting_blue

			if (linked_shields.len)
				if (setting_red == target_red)
					visible_message("<span style=\"color:blue\"><strong>[src]</strong> beeps oddly.</span>")
					playsound(loc,"sound/machines/twobeep.ogg",50,1)
				sleep(2)
				if (setting_green == target_green)
					visible_message("<span style=\"color:blue\"><strong>[src]</strong> beeps strangely.</span>")
					playsound(loc,"sound/machines/twobeep.ogg",50,1)
				sleep(2)
				if (setting_blue == target_blue)
					visible_message("<span style=\"color:blue\"><strong>[src] beeps curiously.</span>")
					playsound(loc,"sound/machines/twobeep.ogg",50,1)
				sleep(2)
				if (setting_red == target_red && setting_green == target_green && setting_blue == target_blue)
					for (var/obj/precursor_puzzle/shield/S in linked_shields)
						S.update_color(setting_red,setting_green,setting_blue)
						if (S.active)
							S.deactivate()
				else
					for (var/obj/precursor_puzzle/shield/S in linked_shields)
						S.update_color(setting_red,setting_green,setting_blue)
						if (!S.active)
							S.activate()


			return


/obj/precursor_puzzle/shield
	name = "energy barrier"
	desc = "It's pretty solid, somehow."
	icon = 'icons/effects/effects.dmi'
	icon_state = "shield1"
	density = 1
	anchored = 1
	opacity = 0
	var/active = 0
	var/id = 1
	var/changing_state = 0
	var/light/light

	New()
		..()
		light = new /light/point
		light.set_brightness(0.5)
		light.attach(src)
		if (!active)
			activate()

	proc

		update_color(var/setting_red = 1, var/setting_green = 1, var/setting_blue = 1)
			light.set_color(setting_red,setting_green,setting_blue)


		activate()
			if (changing_state)
				return
			if (!active)
				active = 1
				density = 1
				invisibility = 0
				changing_state = 1
				playsound(loc, "sound/effects/shielddown.ogg", 60, 1)
				visible_message("<span style=\"color:blue\"><strong>[src] powers up!</strong></span>")
				light.enable()

				spawn (4)
					changing_state = 0
			return

		deactivate()
			if (changing_state)
				return
			if (active)
				active = 0
				density = 0
				invisibility = 100
				playsound(loc, "sound/effects/shielddown2.ogg", 60, 1)
				visible_message("<span style=\"color:blue\"><strong>[src] powers down!</strong></span>")
				changing_state = 1
				light.disable()

				spawn (4)
					changing_state = 0
			return

/obj/precursor_puzzle/sphere
	name = "energy sphere"
	desc = "That doesn't look very safe at all."
	icon = 'icons/obj/artifacts/puzzles.dmi'
	icon_state = "sphere"
	anchored = 1
	density = 1
	opacity = 0
	var/id = 1
	var/light/light

	New()
		..()
		tag = "sphere_[id]"
		light = new /light/point
		light.attach(src)
		light.set_color(0.8,0.9,1)
		light.set_brightness(0.9)

	HasProximity(atom/movable/AM as mob|obj)
		if (iscarbon(AM) && prob(20))
			var/mob/living/carbon/user = AM
			shock(user)

	Bump(atom/movable/AM as mob)
		if (iscarbon(AM))
			var/mob/living/carbon/user = AM
			shock(user)

	proc/shock(var/mob/living/user as mob)
		if (user)
			var/effects/system/spark_spread/s = unpool(/effects/system/spark_spread)
			s.set_up(5, 1, user.loc)
			s.start()
			var/shock_damage = rand(10,15)

			if (user.bioHolder.HasEffect("resist_electric") == 2)
				var/healing = 0
				if (shock_damage)
					healing = shock_damage / 3
				user.HealDamage("All", shock_damage, shock_damage)
				user.take_toxin_damage(0 - healing)
				boutput(user, "<span style=\"color:blue\">You absorb the electrical shock, healing your body!</span>")
				return
			else if (user.bioHolder.HasEffect("resist_electric") == 1)
				boutput(user, "<span style=\"color:blue\">You feel electricity course through you harmlessly!</span>")
				return

			user.TakeDamage(user.hand == 1 ? "l_arm" : "r_arm", 0, shock_damage)
			user.updatehealth()
			boutput(user, "<span style=\"color:red\"><strong>You feel a powerful shock course through your body sending you flying!</strong></span>")
			user.unlock_medal("HIGH VOLTAGE", 1)
			user.Virus_ShockCure(user, 100)
			user:shock_cyberheart(100)
			user.stunned+=2
			user.weakened++
			var/atom/target = get_edge_target_turf(user, get_dir(src, get_step_away(user, src)))
			user.throw_at(target, 200, 4)
			for (var/mob/M in AIviewers(src))
				if (M == user)	continue
			user.show_message("<span style=\"color:red\">[user.name] was shocked by the [name]!</span>", 3, "<span style=\"color:red\">You hear a heavy electrical crack</span>", 2)

//// collecting some junk together for the ice moon


//computer

/obj/machinery/computer3/generic/icemooon
	name = "Computer Console"
	setup_starting_peripheral1 = /obj/item/peripheral/network/powernet_card
	setup_starting_peripheral2 = /obj/item/peripheral/printer
	setup_drive_type = /obj/item/disk/data/fixed_disk/icemoon_rdrive

/obj/item/disk/data/fixed_disk/icemoon_rdrive
	title = "VR_HDD"

	New()
		..()
		//First off, create the directory for logging stuff
		var/computer/folder/newfolder = new /computer/folder(  )
		newfolder.name = "logs"
		root.add_file( newfolder )
		newfolder.add_file( new /computer/file/record/c3help(src))
		newfolder = new /computer/folder
		newfolder.name = "bin"
		root.add_file( newfolder )
		newfolder.add_file( new /computer/file/terminal_program/writewizard(src))

		root.add_file( new /computer/file/text/icemoon_log1(src))
		root.add_file( new /computer/file/text/icemoon_log2(src))
		root.add_file( new /computer/file/text/icemoon_log3(src))
		root.add_file( new /computer/file/text/icemoon_log4(src))

// these aren't precursor things but fuck it, i don't feel like making another dm file right now

/obj/portrait_sneaky
	name = "crooked portrait"
	anchored = 1
	icon = 'icons/obj/decals.dmi'
	icon_state = "portrait"
	desc = "A portrait of a man wearing a ridiculous merchant hat. That must be Discount Dan."

	attack_hand(var/mob/user as mob)
		boutput(user, "<span style=\"color:blue\"><strong>You try to straighten [src], but it won't quite budge.</strong></span>")
		..()
		return

	attackby(obj/item/W as obj, mob/user as mob)
		if (istype(W, /obj/item/crowbar))
			playsound(loc, "sound/items/Crowbar.ogg", 50, 1)
			boutput(user, "<span style=\"color:blue\"><strong>You pry [src] off the wall, destroying it! You jerk!</strong></span>")
			new /obj/decal/woodclutter(loc)
			new /obj/item/storage/secure/ssafe/martian(loc)
			playsound(loc, "sound/effects/wbreak.wav", 70, 1)
			spawn (1)
			qdel(src)
			return
		else
			..()
			return

/obj/critter/shade
	name = "darkness"
	desc = "Oh god."
	icon_state = "shade"
	health = 10
	brutevuln = 0.5
	firevuln = 0
	aggressive = 1
	generic = 0


	attack_hand(var/mob/user as mob)
		if (user.a_intent == "help")
			return

		..()

	ChaseAttack(mob/M)
		return

	CritterAttack(mob/M)
		if (!ismob(M))
			return

		attacking = 1

		if (M.lying)
			src.speak( pick("me-�m ina men-an-uras-a?", "e-z� ina gu-sum... e-z� ina g�-ri-ta!", "e-z� n�-gig, e-z� n�-d�m-d�m-ma, e-z� �u...bar ina libir lugar!", "namlugallu-zu-ne-ne inim-dirig, namgallu-zu-ne-ne inim-b�r-ra, izi te-en ina an!", "ri azag, ri azag, ri azag, ri �rim, ri e-z�!", "e-z�, �rim diir-da...nu-me-a.") )
			// where is the crown of heaven and earth // you are from the writing... you are from the other side // you abominations, created creatures, you let loose the ancient king
			// mankind's hubris, mankind's breach of treaty extinguished the heavens // banish the taboo, banish the taboo, banish you // you, enemy, without a god
			visible_message("<span style=\"color:red\"><strong>[src]</strong> takes hold of [M]!</span>")
			boutput(M, "<span style=\"color:red\"><strong>It burns!</strong></span>")
			M.TakeDamage("chest", 0, rand(5,15))
		else
			speak( pick("an-z�, bar ina k�, ina k�! ina k�-bar-ra!", "hul-�l. l��r-l�-ene ina im-dugud-ene. n-ene. e-z�.", "ki-lul-la, ki-in-dar, �-a-nir-ra: urudu e-re-s�-ki-in ina �mun, en-nu-�a-ak ina l��r-l�-ene", "l�-k�r-ra! l�-n�-zuh! l�-ru-g�!", "nu-me-en-na-ta, na!") )
			// where heaven ends, the gate, the gate! the outer door! // the evil ones, the butchers on the lumps of stone. humans. you. // in the place of murder, in the crevice, in the house of mourning: the copper servant formed of thought guards against the butchers //
			// stranger! thief! recalcitrant one! // you don't exist, human!
			visible_message("<span style=\"color:red\"><strong>[src]</strong> reaches for [M]!</span>")
			boutput(M, "<span style=\"color:red\"><strong>It burns!</strong></span>")
			M.TakeDamage("chest", 0, rand(5,15))

		spawn (60)
			attacking = 0

	ai_think()
		if (task == "thinking" || task == "wandering")
			if (prob(5))
				src.speak( pick("namlugallu ha-lam ina lugal-�a�-l�-s�...","� da-r�-s� �e�...","�-e-me-en �ri-z�-er igi-bad!","inim...k� ina ki-dul, ina e-�r, ina ki-bad-r�, h�-�m-me-�m...", "�ri-k�r...d�b, �ri...ar, e-z�...", "galam, gamar ganzer, g�bil p�ri! ul, ul! s�kud...") )
				// mankind destroyed the merciful king // sleep forever, brethren // i am one who lost my footing and opened my eyes // to seek or find the right words, the armor, the secret point, the distant places, that is our wish // to ascend, overwhelming darkness, burning bright! shine! shine! shine brightly!
		else
			if (prob(5))
				src.speak( pick("ina urudu e-re-s�-ki-in kala libir arza ina S�KUD ZAL.", "i.menden ina nam-ab-ba issa, nam-nu-tar  nam-diir, i.menden l�n�-�a...","bar...gub ina b�d-�ul-hi...","�idim ak ina libir i�gal, diir ak ina agrun, ul-��r-ra, z�-m�!", "�ru p�d g�g, ina gidim niin!") )
				// the copper servant mends the rights of the FLASH OF DAWN // we are the elder shades, ill-fated divinities, we are the temple servants...// step outside the outer wall
				// architect of the ancient throne, god of the inner sanctuary, jubilation, praise! // watchfire reveals night, the darkened monstrosity
				//
				//
		return ..()

	CritterDeath()
		speak( pick("��r...�a ina ��r-kug z�h-bi!", "�d, �d, �u...bar...", "n�-nam-nu-kal...", "lugal-me taru, lugal-me galam!", "me-li-e-a...") )
		// sing the sacred song to the bitter end // go out, exit, release // nothing is precious // our king will return, our king will ascend // woe is me
		alive = 0
		spawn (15)
			qdel(src)

	seek_target()
		anchored = 0
		if (target)
			task = "chasing"
			return

		for (var/mob/living/carbon/C in view(seekrange,src))
			if ((C.name == oldtarget_name) && (world.time < last_found + 100)) continue
			if (C.stat || C.health < 0) continue

			target = C
			oldtarget_name = C.name
			task = "chasing"
			src.speak( pick("siskur, siskur ina na sukkal...","�ra ina g�g, �� ina ur zal...","l�-�rim! l�-�rim!","� �-zi-ga...bal, na, e-z� ha-lam ina � si-ga...") )
			// sacrifice, sacrifice the human envoy! // praise the night, kill the servant of light // enemy! enemy! // cursed with violence, human, you ruin the quiet house
			break

	proc/speak(var/message)
		if (!message)
			return

		var/fontSize = 1
		var/fontIncreasing = 1
		var/fontSizeMax = 3
		var/fontSizeMin = -3
		var/messageLen = length(message)
		var/processedMessage = ""

		for (var/i = 1, i <= messageLen, i++)
			processedMessage += "<font size=[fontSize]>[copytext(message, i, i+1)]</font>"
			if (fontIncreasing)
				fontSize = min(fontSize+1, fontSizeMax)
				if (fontSize >= fontSizeMax)
					fontIncreasing = 0
			else
				fontSize = max(fontSize-1, fontSizeMin)
				if (fontSize <= fontSizeMin)
					fontIncreasing = 1

		visible_message("<strong>the [name]</strong> whispers, \"[processedMessage]\"")
		playsound(loc, pick('sound/voice/creepywhisper_1.ogg', 'sound/voice/creepywhisper_2.ogg', 'sound/voice/creepywhisper_3.ogg'), 50, 1)
		return

/obj/effects/ydrone_summon //WIP
	invisibility = 101
	anchored = 1
	var/range = 5
	var/end_float_effect = 0

	New(spawnloc)
		..()

		range += rand(-1,2)
		spawn (0)
			summon()


	proc/summon()

		var/temp_effect_limiter = 10
		for (var/turf/T in view(range, src))
			var/T_dist = get_dist(T, src)
			var/T_effect_prob = 100 * (1 - (max(T_dist-1,1) / range))
			if (prob(8) && limiter.canIspawn (/obj/effects/sparks))
				var/obj/sparks = unpool(/obj/effects/sparks)
				sparks.set_loc(T)
				spawn (20) if (sparks) pool(sparks)

			for (var/obj/item/I in T)
				if ( prob(T_effect_prob) )
					animate_float(I, 5, 10)
/*
					spawn (rand(0,30))

						var/n = 1
						var/n2 = 0
						var/pixel_y_mod = 0
						var/old_pixel_y = I.pixel_y
						while (I && !end_float_effect)
							if (pixel_y_mod < 24)
								I.pixel_y += 2
								pixel_y_mod += 2
								sleep(pixel_y_mod < 12 ? 6 : 3)
								continue

							n2 = n++ % 18
							if (n2 > 9)
								n2 = 9 - (n2 - 9)
							I.pixel_y = old_pixel_y + pixel_y_mod + n2 - 1
							sleep(4)

						while (I && I.pixel_y > old_pixel_y)
							I.pixel_y--
							sleep(2)
*/
			if (prob(T_effect_prob))
				spawn (rand(80, 100))
					if (T)
						playsound(T, pick('sound/effects/elec_bigzap.ogg', 'sound/effects/elec_bzzz.ogg', 'sound/effects/electric_shock.ogg'), 50, 0)
						var/obj/somesparks = unpool(/obj/effects/sparks)
						somesparks.set_loc(T)
						spawn (20) if (somesparks) pool(somesparks)
						var/list/tempEffect
						if (temp_effect_limiter-- > 0)
							tempEffect = DrawLine(src, somesparks, /obj/line_obj/elec, 'icons/obj/projectiles.dmi',"WholeLghtn",1,1,"HalfStartLghtn","HalfEndLghtn",FLY_LAYER,1,PreloadedIcon='icons/effects/LghtLine.dmi')

						if (T.density)
							for (var/atom/A in T)
								A.ex_act(1)

							if (istype(T, /turf/simulated/wall))
								T.ex_act(1)
							else
								qdel(T)
						else
							T.ex_act( max(1, T_dist) )
							for (var/atom/A in T)
								A.ex_act(max(1, T_dist))

						sleep(6)
						for (var/obj/O in tempEffect)
							pool(O)


		sleep (100)
		new /obj/critter/gunbot/drone/iridium( locate(x-1, y-1, z) ) //Still needs a fancy spawn-in effect.
		end_float_effect = 0
		sleep (50)
		qdel(src)


		return


/projectile/laser/precursor/sphere // for precursor traps
	name = "energy sphere"
	icon = 'icons/obj/artifacts/puzzles.dmi'
	icon_state = "sphere"
	power = 75
	cost = 75
	sname = "energy bolt"
	dissipation_delay = 15
	shot_sound = 'sound/machines/ArtifactPre1.ogg'
	color_red = 0.1
	color_green = 0.3
	color_blue = 1
	ks_ratio = 0.8

	on_hit(atom/hit)
		if (istype(hit, /turf))
			hit.ex_act(1 + prob(50))

		return


/obj/projectile/precursor_sphere
	var/homing = 1

	New()
		..()
		homing += rand(0,3)

	process()
		spawn (0)
			..()
		sleep(homing)
		elec_zap()

	proc/elec_zap()
		playsound(src, "sound/effects/elec_bigzap.ogg", 40, 1)

		var/list/lineObjs
		for (var/mob/living/poorSoul in range(src, 5))
			lineObjs += DrawLine(src, poorSoul, /obj/line_obj/elec, 'icons/obj/projectiles.dmi',"WholeLghtn",1,1,"HalfStartLghtn","HalfEndLghtn",FLY_LAYER,1,PreloadedIcon='icons/effects/LghtLine.dmi')

			poorSoul << sound('sound/effects/electric_shock.ogg', volume=50)
			random_burn_damage(poorSoul, 45)
			boutput(poorSoul, "<span style=\"color:red\"><strong>You feel a powerful shock course through your body!</strong></span>")
			poorSoul.unlock_medal("HIGH VOLTAGE", 1)
			poorSoul:Virus_ShockCure(poorSoul, 100)
			poorSoul:shock_cyberheart( 100)
			poorSoul:weakened += rand(3,5)
			if (poorSoul.stat == 2 && prob(25))
				poorSoul.gib()

		for (var/obj/machinery/vehicle/poorPod in range(src, 4))
			lineObjs += DrawLine(src, poorPod, /obj/line_obj/elec, 'icons/obj/projectiles.dmi',"WholeLghtn",1,1,"HalfStartLghtn","HalfEndLghtn",FLY_LAYER,1,PreloadedIcon='icons/effects/LghtLine.dmi')

			playsound(poorPod.loc, "sound/effects/elec_bigzap.ogg", 40, 0)
			poorPod.bullet_act(src)


		spawn (6)
			for (var/obj/O in lineObjs)
				pool(O)

			dispose()


	die()
		pool(src)

/obj/ydrone_panel
	name = "access panel"
	desc = "It seems to be part of the satellite. The interface is locked. You see a small circular port below the keypad."
	icon = 'icons/obj/airtunnel.dmi'
	icon_state = "airbr0"
	anchored = 1
	pixel_y = 32
	var/activated = 0

	attackby(obj/item/W as obj, mob/user as mob)
		if (istype(W, /obj/item/device/dongle))
			if (activated)
				boutput(user, "<span style=\"color:red\">There's already one plugged in!</span>")
				return

			user.visible_message("<span style=\"color:red\"><strong>[user]</strong> plugs [W] into [src].</span>")
			qdel (W)

			summon_drone()
		else
			return ..()

	proc/summon_drone()
		icon_state = "airbr-alert"
		var/turf/spawn_turf = get_turf(src)
		for (var/obj/overlay/overlay in orange(5,src))
			if (findtext(overlay.name, "relay"))
				spawn_turf = get_turf(overlay)
				break

		new /obj/effects/ydrone_summon( spawn_turf )


/obj/item/device/dongle
	name = "syndicate security dongle"
	desc = "A form of secure, electronic identification with a round port connector and a funny name."
	w_class = 2
	icon_state = "rfid"


////////// graveyard stuff


/obj/item/shovel
	name = "rusty old shovel"
	desc = "It's seen better days."
	icon = 'icons/obj/items.dmi'
	icon_state = "shovel"
	inhand_image_icon = 'icons/mob/inhand/hand_tools.dmi'
	item_state = "pick"
	w_class = 3
	flags = ONBELT
	force = 15
	hitsound = 'sound/weapons/smash.ogg'


/obj/graveyard/lightning_trigger
	icon = 'icons/misc/mark.dmi'
	icon_state = "ydn"
	invisibility = 101
	anchored = 1
	density = 0
	var/active = 0
	HasEntered(atom/movable/AM as mob|obj)
		if (active) return
		if (ismob(AM))
			if (AM:client)
				if (prob(15))
					active = 1
					spawn (50) active = 0
					playsound(get_turf(AM), pick('sound/effects/thunder.ogg','sound/ambience/rain_fx1.ogg'), 75, 1)

					for (var/mob/M in view(src, 5))
						M.flash(30)

/obj/graveyard/loose_rock
	icon = 'icons/misc/worlds.dmi'
	icon_state = "rockwall"
	dir = 4
	density = 1
	opacity = 1
	anchored = 1
	desc = "These rocks are riddled with small cracks and fissures. A cold draft lingers around them."
	name = "Rock Wall"
	var/id = "alchemy"

	New()
		..()
		if (!id)
			id = "generic"

		tag = "loose_rock_[id]"
		return


	proc/crumble()
		visible_message("<span style=\"color:red\"><strong>[src] crumbles!</strong></span>")
		playsound(loc, "sound/effects/stoneshift.ogg", 50, 1)
		var/obj/effects/bad_smoke/smoke = unpool(/obj/effects/bad_smoke)
		smoke.name = "dust cloud"
		smoke.set_loc(loc)
		icon_state = "rubble"
		density = 0
		opacity = 0
		src = null
		spawn (180)
			if ( smoke )
				smoke.name = initial(smoke.name)
				pool(smoke)
		return


/obj/item/device/sat_crash_caller
	name = "satellite transceiver"
	desc = "A hand-held device for communicating with some sort of satellite."
	icon = 'icons/obj/device.dmi'
	icon_state = "satcom"
	w_class = 1

	attack_self(mob/user as mob)
		if (..())
			return

		if (satellite_crash_event_status != -1)
			boutput(user, "<span style=\"color:red\">The [name] emits a sad beep.</span>")
			playsound(loc, "sound/machines/whistlebeep.ogg", 50, 1)
			return

		var/area/crypt/graveyard/ourArea = get_area(user)
		if (!istype(ourArea))
			boutput(user, "<span style=\"color:red\">The [name] emits a rude beep! It appears to have no signal.</span>")
			playsound(loc, "sound/machines/whistlebeep.ogg", 50, 1)
			return

		for (var/turf/T in range(user, 1))
			if (T.density)
				boutput(user, "<span style=\"color:red\">The [name] gives off a grumpy beep! Looks like the signals are reflecting off of walls or something.  Maybe move?</span>")
				playsound(loc, "sound/machines/whistlealert.ogg", 50, 1)
				return

		satellite_crash_event_status = 0
		user.visible_message("<span style=\"color:red\">[user] pokes some buttons on [src]!</span>", "You activate [src].  Apparently.")
		playsound(user.loc, "sound/machines/signal.ogg", 60, 1)
		new /obj/effects/sat_crash(get_turf(src))

		return

var/satellite_crash_event_status = -1
/obj/effects/sat_crash
	name = ""
	anchored = 1
	density = 0
	icon = 'icons/effects/64x64.dmi'
	icon_state = "impact_marker"
	layer = FLOOR_EQUIP_LAYER1
	pixel_y = -16
	pixel_x = -16

	New()
		..()

		if (satellite_crash_event_status != 0)
			del src
			return

		satellite_crash_event_status = 1
		spawn (0)
			satellite_crash_event()

	proc/satellite_crash_event()
		var/obj/decal/satellite = new /obj/decal (loc)
		satellite.pixel_y = 600
		satellite.pixel_x = -16
		satellite.icon = 'icons/effects/64x64.dmi'
		satellite.icon_state = "syndsat"
		satellite.anchored = 1
		satellite.bound_width = 64
		satellite.bound_height = 64
		satellite.name = "Syndicate TeleRelay Satellite"
		satellite.desc = "An example of a syndicate teleportation relay satellite.  The tech on these is experimental, cheaply implemented, and has a history of leaving parts....behind."
		var/light/light = new /light/point
		light.set_color(0.9, 0.7, 0.5)
		light.set_brightness(0.7)
		light.attach(satellite)
		light.enable()
		playsound(loc, "sound/machines/satcrash.ogg", 50, 0)

		sleep(50)
		if (!satellite)
			satellite_crash_event_status = -1
			return

		invisibility = 100
		var/particle_count = rand(8,16)
		while (particle_count--)
			var/obj/effects/expl_particles/EP = new /obj/effects/expl_particles {pixel_y = 600; name = "space debris";} (pick(orange(src,3)))
			animate(EP, pixel_y = 0, time=15, easing = SINE_EASING, transform = matrix(rand(-180, 180), MATRIX_ROTATE))

		sleep(15)
		var/oldTransform = satellite.transform
		animate(satellite, pixel_y = 0, time = 10, easing = SINE_EASING, transform = matrix(rand(5, 30), MATRIX_ROTATE))
		sleep(10)
		var/effects/system/explosion/explode = new /effects/system/explosion
		explode.set_up( loc )
		explode.start()
		playsound(loc, "sound/effects/kaboom.ogg", 90, 1)
		spawn (1)
			fireflash(loc, 4)
		for (var/mob/living/L in range(loc, 2))
			L.ex_act(get_dist(loc, L))

		sleep(5)
		satellite.icon_state = "syndsat-crashed"
		satellite.density = 1
		satellite.transform = oldTransform
		satellite.color = "#FFFFFF"
		light.disable()
		light.detach()
		sleep(45)
		qdel(explode)

		var/image/projection = image('icons/effects/64x64.dmi', "syndsat-projection")
		projection.pixel_x = 32
		projection.pixel_y = -32
		projection.layer = satellite.layer + 1
		satellite.overlays += projection

		var/obj/perm_portal/portal = new /obj/perm_portal {name="rift in space and time"; desc = "uh...huhh"; pixel_x = 16;} (locate(satellite.x+1,satellite.y-1, satellite.z))
		for (var/obj/O in portal.loc)
			if (O.density && O.anchored && O != portal)
				qdel(O)

		var/area/drone/zone/drone_zone = locate()
		if (istype(drone_zone))
			var/obj/decal/fakeobjects/teleport_pad/pad = locate() in drone_zone.contents
			if (istype(pad))
				portal.target = pad
			else
				portal.target = pick( drone_zone.contents )

			var/obj/perm_portal/portal2 = new /obj/perm_portal {name="rift in space and time"; desc = "uh...huhh";} (get_turf(portal.target))
			portal2.target = portal

		satellite_crash_event_status = 2
		qdel(src)


// it's about time this was an object I think
var/global/the_sun = null
/obj/the_sun
	name = "Sol"
	desc = "It's goddamn bright. Should you even be looking at this?"
	icon = 'icons/effects/160x160.dmi'
	icon_state = "sun"
	layer = EFFECTS_LAYER_UNDER_4
	luminosity = 5
	var/light/light

	New()
		..()
		light = new /light/point
		light.attach(src, 2.5, 2.5)
		light.set_brightness(4)
		light.set_height(3)
		light.set_color(0.9, 0.5, 0.3)
		light.enable()
		spawn (10)
			if (!the_sun)
				the_sun = src

	disposing()
		if (the_sun == src)
			the_sun = null
		..()

	Del()
		if (the_sun == src)
			the_sun = null
		..()

	attackby(obj/item/O as obj, mob/user as mob)
		if (istype(O, /obj/item/clothing/mask/cigarette))
			if (!O:lit)
				O:light(user, "<span style=\"color:red\"><strong>[user]</strong> lights [O] on [src] and casually takes a drag from it. Wow.</span>")
				if (!user.is_heat_resistant())
					spawn (10)
						user.visible_message("<span style=\"color:red\"><strong>[user]</strong> burns away into ash! It's almost as though being that close to a star wasn't a great idea!</span>",\
						"<span style=\"color:red\"><strong>You burn away into ash! It's almost as though being that close to a star wasn't a great idea!</strong></span>")
						user.firegib()
				else
					user.unlock_medal("Helios", 1)

var/global/server_kicked_over = 0
var/global/it_is_okay_to_do_the_endgame_thing = 0
var/global/was_eaten = 0
var/global/derelict_mode = 0
//congrats you won
/obj/the_server_ingame_whoa
	name = "server rack"
	desc = "This looks kinda important.  You can barely hear farting and honking coming from a speaker inside.  Weird."
	icon = 'icons/obj/networked.dmi'
	icon_state = "server"
	anchored = 1
	density = 1

	New()
		..()

		if (!it_is_okay_to_do_the_endgame_thing)
			del src
			return

		if (world.name)
			name = world.name

	attackby(obj/item/O as obj, mob/user as mob)
		..()
		if (server_kicked_over && istype(O, /obj/item/clothing/mask/cigarette))
			if (!O:lit)
				O:light(user, "<span style=\"color:red\">[user] lights the [O] with [src]. That's pretty meta.</span>")
				user.unlock_medal("Nero", 1)

		if (!O || !O.force)
			return

		breakdown()

	bullet_act(var/obj/projectile/P)
		if (P && P.proj_data.ks_ratio > 0)
			breakdown()

	proc/eaten(var/mob/living/carbon/human/that_asshole)
		if (server_kicked_over)
			boutput(that_asshole, "<span style=\"color:red\">Frankly, it doesn't look as tasty when it's broken. You have no appetite for that.</span>")
			return
		visible_message("<span style=\"color:red\"><strong>[that_asshole] devours the server!<br>OH GOD WHAT</strong></span>")
		loc = null
		world.save_intra_round_value("somebody_ate_the_fucking_thing", 1)
		breakdown()
		spawn (50)
			boutput(that_asshole, "<span style=\"color:red\"><strong>IT BURNS!</strong></span>")

	proc/breakdown()
		if (server_kicked_over)
			return

		server_kicked_over = 1
		sleep(10)
		icon_state = "serverf"
		visible_message("<span style=\"color:red\"><strong>[src] bursts into flames!</strong><br>UHHHHHHHH</span>")
		spawn (0)
			var/area/the_solarium = get_area(src)
			for (var/mob/living/M in the_solarium)
				if (M.stat == 2)
					continue

				M.unlock_medal("Newton's Crew", 1)
			world.save_intra_round_value("solarium_complete", 1)
			//var/obj/overlay/the_sun = locate("the_sun")
			//if (istype(the_sun))
			if (the_sun)
				qdel(the_sun)
			for (var/turf/space/space in world)
				space.icon_state = "howlingsun"
				space.icon = 'icons/misc/worlds.dmi'
			world << sound('sound/machines/lavamoon_plantalarm.ogg')
			spawn (1)
				for (var/mob/living/carbon/human/H in mobs)
					H.flash(30)
					shake_camera(H, 210, 2)
					spawn (rand(1,10))
						H.bodytemperature = 1000
						H.update_burning(50)
					spawn (rand(50,90))
						H.emote("scream")
			creepify_station() // creep as heck
			sleep(125)
			var/hud/cinematic/cinematic = new
			for (var/client/C)
				cinematic.add_client(C)
			cinematic.play("sadbuddy")
			sleep(10)
			boutput(world, "<tt>BUG: CPU0 on fire!</tt>")

			sleep(150)
			logTheThing("diary", null, null, "Rebooting due to completion of solarium quest.", "game")
			Reboot_server()

/proc/voidify_world()
	var/turf/unsimulated/wall/the_ss13_screen = locate("the_ss13_screen")
	if (istype(the_ss13_screen))
		the_ss13_screen.icon_state = "title_broken"
	spawn (30)
		for (var/turf/space/space in world)
			if (was_eaten)
				if (space.icon_state != "acid_floor")
					space.icon_state = "acid_floor"
					space.icon = 'icons/misc/meatland.dmi'
					space.name = "stomach acid"
					if (space.z == 1)
						new /obj/stomachacid(space)
			else
				if (space.icon_state != "darkvoid")
					space.icon_state = "darkvoid"
					space.icon = 'icons/turf/floors.dmi'
					space.name = "void"
		//var/obj/overlay/the_sun = locate("the_sun")
		//if (istype(the_sun))
		if (the_sun)
			var/obj/Sun = the_sun
			Sun.icon_state = "sun_red"
			Sun.desc = "Uhhh...."
			Sun.blend_mode = 2 // heh
		//var/obj/critter/the_automaton = locate("the_automaton")
		//if (istype(the_automaton))
		if (the_automaton)
			var/obj/critter/Automaton = the_automaton
			Automaton.aggressive = 1
			Automaton.atkcarbon = 1
			Automaton.atksilicon = 1
		world << sound('sound/ambience/precursorambi.ogg')
	return

var/global/list/scarysounds = list('sound/machines/engine_alert3.ogg',
'sound/ambience/creaking_metal.ogg',
'sound/machines/glitch1.ogg',
'sound/machines/glitch2.ogg',
'sound/machines/glitch3.ogg',
'sound/misc/automaton_tickhum.ogg',
'sound/misc/automaton_ratchet.ogg',
'sound/misc/automaton_spaz.ogg',
'sound/effects/gong_rumble.ogg',
'sound/ambience/precursorfx1.ogg',
'sound/ambience/precursorfx2.ogg',
'sound/ambience/precursorfx3.ogg',
'sound/ambience/precursorfx4.ogg',
'sound/ambience/precursorambi.ogg',
'sound/ambience/lavamoon_ancientarea_fx1.ogg',
'sound/ambience/lavamoon_ancientarea_fx2.ogg',
'sound/ambience/lavamoon_ancientarea_fx3.ogg',
'sound/ambience/lavamoon_ancientarea_amb1.ogg',
'sound/machines/romhack1.ogg',
'sound/machines/romhack2.ogg',
'sound/machines/romhack3.ogg',
'sound/ambience/lavamoon_interior_fx3.ogg',
'sound/ambience/lavamoon_interior_fx4.ogg',
'sound/ambience/lavamoon_interior_fx5.ogg',
'sound/ambience/evilr_d_ambi.ogg',
'sound/ambience/voidambi.ogg',
'sound/ambience/voidfx1.ogg',
'sound/ambience/voidfx2.ogg',
'sound/ambience/voidfx3.ogg',
'sound/ambience/voidfx4.ogg')


/obj/machinery/computer3/generic/dronelab
	name = "Design Office Console"
	setup_starting_peripheral1 = /obj/item/peripheral/network/powernet_card
	setup_starting_peripheral2 = /obj/item/peripheral/printer
	setup_drive_type = /obj/item/disk/data/fixed_disk/dronelab

/obj/item/disk/data/fixed_disk/dronelab
	title = "DRONE_HDD"

	New()
		..()
		//First off, create the directory for logging stuff
		var/computer/folder/newfolder = new /computer/folder(  )
		newfolder.name = "logs"
		root.add_file( newfolder )
		newfolder.add_file( new /computer/file/record/c3help(src))
		//This is the bin folder. For various programs I guess sure why not.
		newfolder = new /computer/folder
		newfolder.name = "bin"
		root.add_file( newfolder )
		newfolder.add_file( new /computer/file/terminal_program/writewizard(src))

		root.add_file( new /computer/file/record/dronefact_log1(src))
		root.add_file( new /computer/file/record/dronefact_log2(src))
		root.add_file( new /computer/file/record/dronefact_log3(src))

//stupid WIP shit here
/obj/beam/sine
	name = "strange energy"
	desc = "A glowing beam of something.  Neat."
	icon = 'icons/obj/projectiles.dmi'
	icon_state = "sinebeam1"
	density = 0
	var/harmonic = 1

	Crossed(atom/movable/Obj)
		if (istype(Obj))
			if (dir == NORTH || dir == SOUTH)
				animate(Obj, pixel_x=8, time = 8 - (2 * harmonic), loop=-1, easing = SINE_EASING)
				animate(pixel_x = -8, time = 8 - (2 * harmonic), loop=-1, easing = SINE_EASING)
			else
				animate(Obj, pixel_y=8, time = 8 - (2 * harmonic), loop=-1, easing = SINE_EASING)
				animate(pixel_y = -8, time = 8 - (2 * harmonic), loop=-1, easing = SINE_EASING)

		return ..()

	Uncrossed(atom/movable/Obj)
		if (istype(Obj))
			animate(Obj)
			Obj.pixel_x = initial(Obj.pixel_x)
			Obj.pixel_y = initial(Obj.pixel_y)

		return ..()

#define MAX_BONES 10 //Max Bones, skeleton P.I.
/obj/critter/bone_king
	name = "Bone King"
	generic = 0

	icon_state = "bone_king"
	var/list/bones = list()

	New()
		..()

		animate(src, pixel_y = 16, time = 6, loop=-1, easing = SINE_EASING)
		animate(pixel_y = -16, time = 6, loop=-1, easing = SINE_EASING)

#undef MAX_BONES
