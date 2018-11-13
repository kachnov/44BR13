//#define MAX_MINIONS_PER_SPAWN 3

var/list/snd_macho_rage = list('sound/voice/macho/macho_alert13.ogg', 'sound/voice/macho/macho_alert16.ogg', 'sound/voice/macho/macho_alert24.ogg',\
'sound/voice/macho/macho_become_alert54.ogg', 'sound/voice/macho/macho_become_alert56.ogg', 'sound/voice/macho/macho_rage_55.ogg', 'sound/voice/macho/macho_shout07.ogg',\
'sound/voice/macho/macho_rage_58.ogg', 'sound/voice/macho/macho_rage_61.ogg', 'sound/voice/macho/macho_rage_64.ogg', 'sound/voice/macho/macho_rage_68.ogg',\
'sound/voice/macho/macho_rage_71.ogg', 'sound/voice/macho/macho_rage_72.ogg', 'sound/voice/macho/macho_rage_73.ogg', 'sound/voice/macho/macho_rage_78.ogg',\
'sound/voice/macho/macho_rage_79.ogg', 'sound/voice/macho/macho_rage_80.ogg', 'sound/voice/macho/macho_rage_81.ogg', 'sound/voice/macho/macho_rage_54.ogg',\
'sound/voice/macho/macho_rage_55.ogg')

var/list/snd_macho_idle = list('sound/voice/macho/macho_alert16.ogg', 'sound/voice/macho/macho_alert22.ogg',\
'sound/voice/macho/macho_breathing01.ogg', 'sound/voice/macho/macho_breathing13.ogg', 'sound/voice/macho/macho_breathing18.ogg',\
'sound/voice/macho/macho_idle_breath_01.ogg', 'sound/voice/macho/macho_mumbling04.ogg', 'sound/voice/macho/macho_moan03.ogg',\
'sound/voice/macho/macho_mumbling05.ogg', 'sound/voice/macho/macho_mumbling07.ogg', 'sound/voice/macho/macho_shout08.ogg')

/mob/living/carbon/human/machoman
	New()
		..()
		spawn (0)
			if (bioHolder && bioHolder.mobAppearance)
				bioHolder.mobAppearance.customization_first = "Dreadlocks"
				bioHolder.mobAppearance.customization_second = "Full Beard"

				spawn (10)
					bioHolder.mobAppearance.UpdateMob()

			//mind = new
			gender = "male"
			real_name = pick("M", "m") + pick("a", "ah", "ae") + pick("ch", "tch", "tz") + pick("o", "oh", "oe") + " " + pick("M","m") + pick("a","ae","e") + pick("n","nn")

			if (!reagents)
				var/reagents/R = new/reagents(1000)
				reagents = R
				R.my_atom = src

			reagents.add_reagent("stimulants", 200)

			equip_if_possible(new /obj/item/clothing/shoes/macho(src), slot_shoes)
			equip_if_possible(new /obj/item/clothing/under/gimmick/macho(src), slot_w_uniform)
			equip_if_possible(new /obj/item/clothing/suit/armor/vest/macho(src), slot_wear_suit)
			equip_if_possible(new /obj/item/clothing/glasses/macho(src), slot_glasses)
			equip_if_possible(new /obj/item/clothing/head/helmet/macho(src), slot_head)
			equip_if_possible(new /obj/item/storage/belt/macho_belt(src), slot_belt)
			equip_if_possible(new /obj/item/device/radio/headset(src), slot_ears)

	Life(controller/process/mobs/parent)
		if (..(parent))
			return TRUE
		if (stat == CONSCIOUS && prob(6))
			visible_message("<strong>[src]</strong> mutters to himself.")
			playsound(loc, pick(snd_macho_idle), 50, 0, 0, get_age_pitch())

//	movement_delay()
//		return ..() - 10

	show_inv(mob/user)
		if (stance == "defensive")
			macho_parry(user)
			return
		..()
		return

	attack_hand(mob/user)
		if (stance == "defensive")
			visible_message("<span style=\"color:red\"><strong>[user] attempts to attack [src]!</strong></span>")
			playsound(loc, "sound/weapons/punchmiss.ogg", 50, 1)
			sleep(2)
			macho_parry(user)
			return
		..()
		return

	attackby(obj/item/W, mob/user)
		if (stance == "defensive")
			visible_message("<span style=\"color:red\"><strong>[user] swings at [src] with the [W.name]!</strong></span>")
			playsound(loc, "sound/weapons/punchmiss.ogg", 50, 1)
			sleep(2)
			macho_parry(user, W)
			return
		..()
		return

	Bump(atom/movable/AM, yes)
		if (stance == "offensive")
			if ((!( yes ) || now_pushing))
				return
			now_pushing = 1
			if (ismob(AM))
				var/mob/M = AM
				boutput(src, "<span style=\"color:red\"><strong>You power-clothesline [M]!</strong></span>")
				for (var/mob/C in oviewers(src))
					shake_camera(C, 8, 3)
					C.show_message("<span style=\"color:red\"><strong>[src] clotheslines [M] into oblivion!</strong></span>", 1)
				M.stunned = 8
				M.weakened = 5
				var/turf/target = get_edge_target_turf(src, dir)
				spawn (0)
					M.throw_at(target, 10, 2)
				playsound(loc, "swing_hit", 40, 1)
			else if (isobj(AM))
				var/obj/O = AM
				if (O.density)
					playsound(loc, "sound/misc/meteorimpact.ogg", 40, 1)
					if (istype(O, /obj/machinery/door))
						var/obj/machinery/door/D = O
						if (D.open())
							boutput(src, "<span style=\"color:red\"><strong>You forcefully kick open [D]!</strong></span>")
							for (var/mob/C in oviewers(D))
								shake_camera(C, 8, 3)
								C.show_message("<span style=\"color:red\"><strong>[src] forcefully kicks open [D]!</strong></span>", 1)
						else
							boutput(src, "<span style=\"color:red\"><strong>You forcefully kick [D]!</strong></span>")
							for (var/mob/C in oviewers(src))
								shake_camera(C, 8, 3)
								C.show_message("<span style=\"color:red\"><strong>[src] forcefully kicks [D]!</strong></span>", 1)
							if (prob(33))
								qdel(D)
					else
						boutput(src, "<span style=\"color:red\"><strong>You crash into [O]!</strong></span>")
						for (var/mob/C in oviewers(src))
							shake_camera(C, 8, 3)
							C.show_message("<span style=\"color:red\"><strong>[src] crashes into [O]!</strong></span>", 1)
						if (istype(O, /obj/window) || istype(O, /obj/grille) || istype(O, /obj/machinery/door) || istype(O, /obj/structure/girder) || istype(O, /obj/foamedmetal))
							qdel(O)
						else
							var/turf/target = get_edge_target_turf(src, dir)
							O.throw_at(target, 10, 2)
			now_pushing = 0
		else
			..()
			return

	proc/macho_parry(mob/M, obj/item/W)
		if (M)
			dir = get_dir(src, M)
			if (W)
				W.cant_self_remove = 0
				W.set_loc(src)
				M.u_equip(W)
				W.layer = HUD_LAYER
				put_in_hand_or_drop(W)
				visible_message("<span style=\"color:red\"><strong>[src] grabs the [W.name] out of [M]'s hands, shoving [M] to the ground!</strong></span>")
			else
				visible_message("<span style=\"color:red\"><strong>[src] parries [M]'s attack, knocking them to the ground!</strong></span>")
			M.weakened = max(10, M.weakened)
			playsound(loc, "sound/weapons/thudswoosh.ogg", 65, 1)
			spawn (20)
				playsound(loc, pick(snd_macho_rage), 60, 0, 0, get_age_pitch())
		return

	verb/macho_offense()
		set name = "Stance - Offensive"
		set desc = "Take an offensive stance and tackle people in your way"
		set category = "Macho Moves"
		if (!stat && !transforming)
			stance = "offensive"

	verb/macho_defense()
		set name = "Stance - Defensive"
		set desc = "Take a defensive stance and counter any attackers"
		set category = "Macho Moves"
		if (!stat && !transforming)
			stance = "defensive"

	verb/macho_normal()
		set name = "Stance - Normal"
		set desc = "We all know this stance is for boxing the hell out of dudes."
		set category = "Macho Moves"
		if (!stat && !transforming)
			stance = "normal"

	verb/macho_grasp(var/mob/living/M as mob in oview(1))
		set name = "Macho Grasp"
		set desc = "Instantly grab someone in a headlock"
		set category = "Macho Moves"
		if (istype(M) && !stat && !transforming)
			for (var/obj/item/grab/G in src)
				if (G.affecting == M)
					return
			playsound(loc, pick(snd_macho_rage), 50, 0, 0, get_age_pitch())
			visible_message("<span style=\"color:red\"><strong>[src] aggressively grabs [M]!</strong></span>")
			var/obj/item/grab/G = new /obj/item/grab( src )
			G.assailant = src
			put_in_hand(G, hand)
			G.affecting = M
			M.grabbed_by += G
			M.stunned = max(10, M.stunned)
			G.state = 2
			G.update_icon()
			dir = get_dir(src, M)
			playsound(loc, "sound/weapons/thudswoosh.ogg", 65, 1)

	verb/macho_headcrunch()
		set name = "Grapple - Headcruncher"
		set desc = "Pulverize the head of a dude you grabbed"
		set category = "Macho Moves"
		if (!stat && !transforming)
			for (var/obj/item/grab/G in src)
				if (ishuman(G.affecting))
					var/mob/living/carbon/human/H = G.affecting
					var/obj/item/affecting = H.organs["head"]
					playsound(loc, "sound/effects/fleshbr1.ogg", 75, 1)
					visible_message("<span style=\"color:red\"><strong>[src] crushes [H]'s skull like a grape!</strong></span>")
					affecting.take_damage(50, 0)
					H.take_brain_damage(60)
					H.stunned = 8
					H.weakened = 5
					H.UpdateDamage()
					H.UpdateDamageIcon()
					qdel(G)
				else
					playsound(loc, "sound/effects/splat.ogg", 75, 1)
					visible_message("<span style=\"color:red\"><strong>[src] crushes [G.affecting]'s body into bits!</strong></span>")
					G.affecting.gib()
					qdel(G)
				spawn (20)
					playsound(loc, pick(snd_macho_rage), 50, 0, 0, get_age_pitch())
					visible_message("<span style=\"color:red\"><strong>[src]</strong> lets out an angry warcry!</span>")
				break

	verb/macho_chestcrunch()
		set name = "Grapple - Ribcracker"
		set desc = "Pulverize the ribcage of a dude you grabbed"
		set category = "Macho Moves"
		if (!stat && !transforming)
			for (var/obj/item/grab/G in src)
				if (ishuman(G.affecting))
					var/mob/living/carbon/human/H = G.affecting
					var/obj/item/affecting = H.organs["chest"]
					playsound(loc, "sound/effects/fleshbr1.ogg", 75, 1)
					visible_message("<span style=\"color:red\"><strong>[src] crushes [H]'s ribcage open like a bag of chips!</strong></span>")
					affecting.take_damage(500, 0)
					H.stunned = 8
					H.weakened = 5
					H.UpdateDamage()
					H.UpdateDamageIcon()
					qdel(G)
				else
					playsound(loc, "sound/effects/splat.ogg", 75, 1)
					visible_message("<span style=\"color:red\"><strong>[src] crushes [G.affecting]'s body into bits!</strong></span>")
					G.affecting.gib()
					qdel(G)
				spawn (20)
					playsound(loc, pick(snd_macho_rage), 50, 0, 0, get_age_pitch())
					visible_message("<span style=\"color:red\"><strong>[src]</strong> lets out an angry warcry!</span>")
				break

	verb/macho_leap(var/area/A as area in world)
		set name = "Macho Leap"
		set category = "Macho Moves"
		if (!stat && !transforming)
			transforming = 1
			verbs -= /mob/living/carbon/human/machoman/verb/macho_leap
			var/mob/living/H = null
			var/obj/item/grab/G = null
			for (G in src)
				if (istype(G.affecting, /mob/living))
					H = G.affecting
			if (H)
				if (H.lying)
					H.lying = 0
					H.paralysis = 0
					H.weakened = 0
					H.set_clothing_icon_dirty()
				H.transforming = 1
				H.density = 0
				H.set_loc(loc)
			else
				visible_message("<span style=\"color:red\">[src] closes his eyes for a moment.</span>")
				playsound(loc, "sound/voice/macho/macho_breathing18.ogg", 50, 0, 0, get_age_pitch())
				sleep(40)
			density = 0
			if (H)
				dir = get_dir(src, H)
				H.dir = get_dir(H, src)
				animate_flip(H, 3)
				/*
				var/icon/composite = icon(H.icon, H.icon_state, null, 1)
				composite.Turn(180)
				for (var/O in H.overlays)
					var/image/I = O
					var/icon/Ic = icon(I.icon, I.icon_state)
					Ic.Turn(180)
					composite.Blend(Ic, ICON_OVERLAY)
				H.overlays = null
				H.icon = composite
				*/
				visible_message("<span style=\"color:red\"><strong>[src] grabs [H] and flies through the ceiling!</strong></span>")
			else
				visible_message("<span style=\"color:red\">[src] flies through the ceiling!</span>")
			playsound(loc, "sound/effects/bionic_sound.ogg", 50)
			playsound(loc, "sound/voice/macho/macho_become_enraged01.ogg", 50, 0, 0, get_age_pitch())
			for (var/i = 0, i < 20, i++)
				pixel_y += 15
				dir = turn(dir, 90)
				if (H)
					H.pixel_y += 15
					H.dir = turn(H.dir, 90)
					switch(dir)
						if (NORTH)
							H.pixel_x = pixel_x
							H.layer = layer - 1
						if (SOUTH)
							H.pixel_x = pixel_x
							H.layer = layer + 1
						if (EAST)
							H.pixel_x = pixel_x - 8
							H.layer = layer - 1
						if (WEST)
							H.pixel_x = pixel_x + 8
							H.layer = layer - 1
				sleep(1)
			set_loc(pick(get_area_turfs(A, 1)))
			if (H)
				visible_message("<span style=\"color:red\">[src] suddenly descends from the ceiling with [H]!</span>")
				H.set_loc(loc)
			else
				visible_message("<span style=\"color:red\">[src] suddenly descends from the ceiling!</span>")
			playsound(loc, "sound/effects/bionic_sound.ogg", 50)
			for (var/i = 0, i < 20, i++)
				pixel_y -= 15
				dir = turn(dir, 90)
				if (H)
					H.pixel_y -= 15
					H.dir = turn(H.dir, 90)
					switch(dir)
						if (NORTH)
							H.pixel_x = pixel_x
							H.layer = layer - 1
						if (SOUTH)
							H.pixel_x = pixel_x
							H.layer = layer + 1
						if (EAST)
							H.pixel_x = pixel_x - 8
							H.layer = layer - 1
						if (WEST)
							H.pixel_x = pixel_x + 8
							H.layer = layer - 1
				sleep(1)
			if (G)
				qdel(G)
			playsound(loc, "explosion", 50)
			playsound(loc, pick(snd_macho_rage), 50, 0, 0, get_age_pitch())
			for (var/mob/M in viewers(src, 5))
				if (M != src)
					M.weakened = max(M.weakened, 8)
				spawn (0)
					shake_camera(M, 4, 2)
			if (istype(loc, /turf/simulated/floor))
				loc:break_tile()
			if (H)
				visible_message("<span style=\"color:red\"><strong>[src] ultra atomic piledrives [H]!!</strong></span>")
				var/obj/overlay/O = new/obj/overlay(get_turf(src))
				O.anchored = 1
				O.name = "Explosion"
				O.layer = NOLIGHT_EFFECTS_LAYER_BASE
				O.pixel_x = -17
				O.icon = 'icons/effects/hugeexplosion.dmi'
				O.icon_state = "explosion"
				spawn (35) qdel(O)
				random_brute_damage(H, 50)
				H.weakened = max(H.weakened, 10)
				H.pixel_x = 0
				H.pixel_y = 0
				H.transforming = 0
				H.density = 1
			pixel_x = 0
			pixel_y = 0
			transforming = 0
			density = 1
			spawn (5)
				verbs += /mob/living/carbon/human/machoman/verb/macho_leap
		/*
			transforming = 1
			verbs -= /mob/living/carbon/human/machoman/verb/macho_leap
			visible_message("<span style=\"color:red\">[src] closes his eyes for a moment.</span>")
			playsound(loc, "sound/voice/macho/macho_breathing18.ogg", 50)
			sleep(40)
			visible_message("<span style=\"color:red\">[src] flies through the ceiling!</span>")
			playsound(loc, "sound/effects/bionic_sound.ogg", 50)
			playsound(loc, "sound/voice/macho/macho_become_enraged01.ogg", 50)
			layer = 10
			density = 0
			for (var/i = 0, i < 20, i++)
				pixel_y += 15
				dir = turn(dir, 90)
				sleep(1)
			set_loc(pick(get_area_turfs(A, 1)))
			visible_message("<span style=\"color:red\">[src] suddenly descends from the ceiling!</span>")
			playsound(loc, "sound/effects/bionic_sound.ogg", 50)
			for (var/i = 0, i < 20, i++)
				pixel_y -= 15
				dir = turn(dir, 90)
				sleep(1)
			if (istype(loc, /turf/simulated/floor))
				loc:break_tile()
			for (var/mob/M in viewers(src, 5))
				if (M != src)
					M.weakened = max(M.weakened, 8)
				spawn (0)
					shake_camera(M, 4, 2)
			playsound(loc, "explosion", 40, 1)
			playsound(loc, pick(snd_macho_rage), 50)
			layer = MOB_LAYER
			density = 1
			transforming = 0
			spawn (5)
				verbs += /mob/living/carbon/human/machoman/verb/macho_leap
			*/
	verb/macho_rend()
		set name = "Macho Rend"
		set desc = "Tears a target limb from limb"
		set category = "Macho Moves"
		if (!stat && !transforming)
			for (var/obj/item/grab/G in src)
				if (istype(G.affecting, /mob/living))
					verbs -= /mob/living/carbon/human/machoman/verb/macho_rend
					var/mob/living/H = G.affecting
					if (H.lying)
						H.lying = 0
						H.paralysis = 0
						H.weakened = 0
						H.set_clothing_icon_dirty()
					H.transforming = 1
					transforming = 1
					dir = get_dir(src, H)
					H.dir = get_dir(H, src)
					visible_message("<span style=\"color:red\"><strong>[src] menacingly grabs [H] by the chest!</strong></span>")
					playsound(loc, pick(snd_macho_rage), 50, 0, 0, get_age_pitch())
					var/dir_offset = get_dir(src, H)
					switch(dir_offset)
						if (NORTH)
							H.pixel_y = -24
							H.layer = layer - 1
						if (SOUTH)
							H.pixel_y = 24
							H.layer = layer + 1
						if (EAST)
							H.pixel_x = -24
							H.layer = layer - 1
						if (WEST)
							H.pixel_x = 24
							H.layer = layer - 1
					for (var/i = 0, i < 5, i++)
						H.pixel_y += 2
						sleep(3)
					if (istype(H,/mob/living/carbon/human))
						var/mob/living/carbon/human/HU = H
						visible_message("<span style=\"color:red\"><strong>[src] begins tearing [H] limb from limb!</strong></span>")
						var/original_age = HU.bioHolder.age
						if (HU.limbs.l_arm)
							HU.limbs.l_arm.sever()
							playsound(loc, "sound/misc/loudcrunch2.ogg", 75)
							HU.emote("scream")
							HU.bioHolder.age += 10
							sleep(10)
						if (HU.limbs.r_arm)
							HU.limbs.r_arm.sever()
							playsound(loc, "sound/misc/loudcrunch2.ogg", 75)
							HU.emote("scream")
							HU.bioHolder.age += 10
							sleep(10)
						if (HU.limbs.l_leg)
							HU.limbs.l_leg.sever()
							playsound(loc, "sound/misc/loudcrunch2.ogg", 75)
							HU.emote("scream")
							HU.bioHolder.age += 10
							sleep(10)
						if (HU.limbs.r_leg)
							HU.limbs.r_leg.sever()
							playsound(loc, "sound/misc/loudcrunch2.ogg", 75)
							HU.emote("scream")
							sleep(10)
						HU.bioHolder.age = original_age
						HU.stunned += 10
						HU.weakened += 12
						var/turf/target = get_edge_target_turf(src, dir)
						spawn (0)
							playsound(loc, "swing_hit", 40, 1)
							visible_message("<span style=\"color:red\"><strong>[src] casually punts [H] away!</strong></span>")
							HU.throw_at(target, 10, 2)
						HU.pixel_x = 0
						HU.pixel_y = 0
						HU.transforming = 0
					else
						visible_message("<span style=\"color:red\"><strong>[src] shreds [H] to ribbons with his bare hands!</strong></span>")
						H.transforming = 0
						H.gib()
					transforming = 0
					verbs += /mob/living/carbon/human/machoman/verb/macho_rend
					spawn (20)
						playsound(loc, pick(snd_macho_rage), 50, 0, 0, get_age_pitch())
						visible_message("<span style=\"color:red\"><strong>[src]</strong> gloats and boasts!</span>")

	verb/macho_touch()
		set name = "Macho Touch"
		set desc = "Transmutes a living target into gold"
		set category = "Macho Moves"
		if (!stat && !transforming)
			for (var/obj/item/grab/G in src)
				if (istype(G.affecting, /mob/living))
					verbs -= /mob/living/carbon/human/machoman/verb/macho_touch
					var/mob/living/H = G.affecting
					if (H.lying)
						H.lying = 0
						H.paralysis = 0
						H.weakened = 0
						H.set_clothing_icon_dirty()
					H.transforming = 1
					transforming = 1
					dir = get_dir(src, H)
					H.dir = get_dir(H, src)
					visible_message("<span style=\"color:red\"><strong>[src] picks up [H] by the throat!</strong></span>")
					playsound(loc, pick(snd_macho_rage), 50, 0, 0, get_age_pitch())
					var/dir_offset = get_dir(src, H)
					switch(dir_offset)
						if (NORTH)
							H.pixel_y = -24
							H.layer = layer - 1
						if (SOUTH)
							H.pixel_y = 24
							H.layer = layer + 1
						if (EAST)
							H.pixel_x = -24
							H.layer = layer - 1
						if (WEST)
							H.pixel_x = 24
							H.layer = layer - 1
					for (var/i = 0, i < 5, i++)
						H.pixel_y += 2
						sleep(3)
					transforming = 0
					bioHolder.AddEffect("fire_resist")
					transforming = 1
					playsound(loc, "sound/effects/chanting.ogg", 75, 0, 0, get_age_pitch())
					visible_message("<span style=\"color:red\">[src] begins radiating with dark energy!</span>")
					sleep(40)
					for (var/mob/N in viewers(src, null))
						N.flash(30)
						if (N.client)
							shake_camera(N, 6, 4)
							N.show_message(text("<span style=\"color:red\"><strong>A blinding light envelops [src]!</strong></span>"), 1)

					playsound(loc, "sound/weapons/flashbang.ogg", 50, 1)
					qdel(G)
					transforming = 0
					bioHolder.RemoveEffect("fire_resist")
					verbs += /mob/living/carbon/human/machoman/verb/macho_touch
					spawn (0)
						if (H)
							H.desc = "A really dumb looking statue. Very shiny, though."
							H.become_gold_statue()
							H.transforming = 0

/*	verb/macho_minions()
		set name = "Macho Minions"
		set desc = "Summons a horde of micro men"
		set category = "Macho Moves"
		if (!stat && !transforming)
			verbs -= /mob/living/carbon/human/machoman/verb/macho_minions
			bioHolder.AddEffect("fire_resist")
			transforming = 1
			visible_message("<span style=\"color:red\"><strong>[src] begins glowing with ominous power!</strong></span>")
			playsound(loc, "sound/effects/chanting.ogg", 75, 0, 0, get_age_pitch())
			sleep(40)
			for (var/mob/N in viewers(src, null))
				N.flash(30)
				if (N.client)
					shake_camera(N, 6, 4)
					N.show_message(text("<span style=\"color:red\"><strong>A blinding light envelops [src]!</strong></span>"), 1)
			playsound(loc, "sound/weapons/flashbang.ogg", 50, 1)
			visible_message("<span style=\"color:red\"><strong>A group of micro men suddenly materializes!</strong></span>")
			var/made_minions = 0
			for (var/turf/T in orange(1))
				var/obj/critter/microman/micro = new(T)
				made_minions ++
				micro.friends += src
				micro.dir = dir
				if (made_minions >= MAX_MINIONS_PER_SPAWN)
					break
			transforming = 0
			bioHolder.RemoveEffect("fire_resist")
			playsound(loc, pick(snd_macho_rage), 50, 0, 0, get_age_pitch())
			spawn (1200) // holy shit the micro man spam from ONE macho man is awful
				verbs += /mob/living/carbon/human/machoman/verb/macho_minions
*/
	verb/macho_piledriver()
		set name = "Atomic Piledriver"
		set desc = "Piledrive a target"
		set category = "Macho Moves"
		if (!stat && !transforming)
			for (var/obj/item/grab/G in src)
				if (istype(G.affecting, /mob/living))
					verbs -= /mob/living/carbon/human/machoman/verb/macho_piledriver
					var/mob/living/H = G.affecting
					if (H.lying)
						H.lying = 0
						H.paralysis = 0
						H.weakened = 0
						H.set_clothing_icon_dirty()
					H.transforming = 1
					transforming = 1
					density = 0
					H.density = 0
					H.set_loc(loc)
					dir = get_dir(src, H)
					H.dir = get_dir(H, src)
					animate_flip(H, 3)
					/*
					var/icon/composite = icon(H.icon, H.icon_state, null, 1)
					composite.Turn(180)
					for (var/O in H.overlays)
						var/image/I = O
						var/icon/Ic = icon(I.icon, I.icon_state)
						Ic.Turn(180)
						composite.Blend(Ic, ICON_OVERLAY)
					H.overlays = null
					H.icon = composite
					*/
					visible_message("<span style=\"color:red\"><strong>[src] grabs [H] and spins in the air!</strong></span>")
					playsound(loc, "sound/effects/bionic_sound.ogg", 50)
					for (var/i = 0, i < 15, i++)
						pixel_y += 6
						H.pixel_y += 6
						dir = turn(dir, 90)
						H.dir = turn(H.dir, 90)
						switch(dir)
							if (NORTH)
								H.pixel_x = pixel_x
								H.layer = layer - 1
							if (SOUTH)
								H.pixel_x = pixel_x
								H.layer = layer + 1
							if (EAST)
								H.pixel_x = pixel_x - 8
								H.layer = layer - 1
							if (WEST)
								H.pixel_x = pixel_x + 8
								H.layer = layer - 1
						sleep(1)
					pixel_x = 0
					pixel_y = 0
					transforming = 0
					H.pixel_x = 0
					H.pixel_y = 0
					H.transforming = 0
					density = 1
					H.density = 1
					qdel(G)
					playsound(loc, "explosion", 50)
					visible_message("<span style=\"color:red\"><strong>[src] atomic piledrives [H]!</strong></span>")
					var/obj/overlay/O = new/obj/overlay(get_turf(src))
					O.anchored = 1
					O.name = "Explosion"
					O.layer = NOLIGHT_EFFECTS_LAYER_BASE
					O.pixel_x = -17
					O.icon = 'icons/effects/hugeexplosion.dmi'
					O.icon_state = "explosion"
					spawn (35) qdel(O)
					random_brute_damage(H, 50)
					H.weakened = max(H.weakened, 10)
					verbs += /mob/living/carbon/human/machoman/verb/macho_piledriver

	verb/macho_superthrow()
		set name = "Macho Throw"
		set desc = "Throw someone super hard"
		set category = "Macho Moves"
		if (!stat && !transforming)
			for (var/obj/item/grab/G in src)
				if (istype(G.affecting, /mob/living))
					verbs -= /mob/living/carbon/human/machoman/verb/macho_superthrow
					var/mob/living/H = G.affecting
					if (H.lying)
						H.lying = 0
						H.paralysis = 0
						H.weakened = 0
						H.set_clothing_icon_dirty()
					H.transforming = 1
					transforming = 1
					density = 0
					H.density = 0
					H.set_loc(loc)
					step(H, dir)
					H.dir = get_dir(H, src)
					visible_message("<span style=\"color:red\"><strong>[src] starts spinning around [H]!</strong></span>")
					playsound(loc, "sound/effects/bionic_sound.ogg", 50)
					for (var/i = 0, i < 80, i++)
						var/delay = 5
						switch(i)
							if (50 to INFINITY)
								delay = 0.25
							if (40 to 50)
								delay = 0.5
							if (30 to 40)
								delay = 1
							if (10 to 30)
								delay = 2
							if (0 to 10)
								delay = 3
						dir = turn(dir, 90)
						H.set_loc(get_step(src, dir))
						H.dir = get_dir(H, src)
						sleep(delay)
					pixel_x = 0
					pixel_y = 0
					transforming = 0
					H.pixel_x = 0
					H.pixel_y = 0
					density = 1
					qdel(G)
					playsound(loc, "sound/weapons/rocket.ogg", 50)
					visible_message("<span style=\"color:red\"><strong>[src] flings [H] with all of his might!</strong></span>")
					var/target_dir = get_dir(src, H)
					spawn (0)
						if (H)
							walk(H, target_dir, 1)
							sleep(15)
							playsound(loc, "explosion", 50)
							var/obj/overlay/O = new/obj/overlay(get_turf(H))
							O.anchored = 1
							O.name = "Explosion"
							O.layer = NOLIGHT_EFFECTS_LAYER_BASE
							O.pixel_x = -17
							O.icon = 'icons/effects/hugeexplosion.dmi'
							O.icon_state = "explosion"
							O.fingerprintslast = key
							spawn (35) qdel(O)
							explosion(O, H.loc, 1, 2, 3, 4, 1)
							H.gib()
					verbs += /mob/living/carbon/human/machoman/verb/macho_superthrow

	verb/macho_soulsteal()
		set name = "Macho Soul Steal"
		set desc = "Steals a target's soul to restore health"
		set category = "Macho Moves"
		if (!stat && !transforming)
			for (var/obj/item/grab/G in src)
				if (istype(G.affecting, /mob/living))
					verbs -= /mob/living/carbon/human/machoman/verb/macho_soulsteal
					var/mob/living/H = G.affecting
					if (H.lying)
						H.lying = 0
						H.paralysis = 0
						H.weakened = 0
						H.set_clothing_icon_dirty()
					H.transforming = 1
					transforming = 1
					dir = get_dir(src, H)
					H.dir = get_dir(H, src)
					visible_message("<span style=\"color:red\"><strong>[src] picks up [H] by the throat!</strong></span>")
					playsound(loc, pick(snd_macho_rage), 50, 0, 0, get_age_pitch())
					var/dir_offset = get_dir(src, H)
					switch(dir_offset)
						if (NORTH)
							H.pixel_y = -24
							H.layer = layer - 1
						if (SOUTH)
							H.pixel_y = 24
							H.layer = layer + 1
						if (EAST)
							H.pixel_x = -24
							H.layer = layer - 1
						if (WEST)
							H.pixel_x = 24
							H.layer = layer - 1
					for (var/i = 0, i < 5, i++)
						H.pixel_y += 2
						sleep(3)
					transforming = 0
					bioHolder.AddEffect("fire_resist")
					transforming = 1
				//	var/icon/composite = icon(icon, icon_state, null, 1)
				//	composite.MapColors(-1,0,0, 0,-1,0, 0,0,-1, 1,1,1)
				//	for (var/O in overlays)
				//		var/image/I = O
				//		var/icon/Ic = icon(I.icon, I.icon_state)
				//		Ic.MapColors(-1,0,0, 0,-1,0, 0,0,-1, 1,1,1)
				//		composite.Blend(Ic, ICON_OVERLAY)
				//	overlays = null
				//	icon = composite
					playsound(loc, "sound/effects/chanting.ogg", 75, 0, 0, get_age_pitch())
					visible_message("<span style=\"color:red\"><strong>[src] begins radiating with evil energies!</strong></span>")
					sleep(40)
					for (var/mob/N in viewers(src, null))
						N.flash(30)
						if (N.client)
							shake_camera(N, 6, 4)
							N.show_message(text("<span style=\"color:red\"><strong>A blinding light envelops [src]!</strong></span>"), 1)

					playsound(loc, "sound/weapons/flashbang.ogg", 50, 1)
					qdel(G)
					transforming = 0
					bioHolder.RemoveEffect("fire_resist")
					verbs += /mob/living/carbon/human/machoman/verb/macho_soulsteal
					for (var/A in organs)
						var/obj/item/affecting = null
						if (!organs[A])    continue
						affecting = organs[A]
						if (!istype(affecting, /obj/item))
							continue
						affecting.heal_damage(50, 50) //heals 50 burn, 50 brute from all organs
					take_toxin_damage(-INFINITY)
					UpdateDamageIcon()
					updatehealth()
					if (H)
						H.pixel_x = 0
						H.pixel_y = 0
						H.take_toxin_damage(5000)
						H.transforming = 0
						if (ishuman(H))
							H.set_mutantrace(/mutantrace/skeleton)
							H.set_body_icon_dirty()
	verb/macho_heal()
		set name = "Macho Healing"
		set desc = "Sacrifice your health to heal someone else"
		set category = "Macho Moves"
		if (!stat && !transforming)
			for (var/obj/item/grab/G in src)
				if (istype(G.affecting, /mob/living))
					verbs -= /mob/living/carbon/human/machoman/verb/macho_heal
					var/mob/living/H = G.affecting
					if (H.lying)
						H.lying = 0
						H.paralysis = 0
						H.weakened = 0
						H.set_clothing_icon_dirty()
					H.transforming = 1
					transforming = 1
					dir = get_dir(src, H)
					H.dir = get_dir(H, src)
					visible_message("<span style=\"color:red\"><strong>[src] gently picks up [H]!</strong></span>")
					playsound(loc, pick(snd_macho_rage), 50, 0, 0, get_age_pitch())
					var/dir_offset = get_dir(src, H)
					switch(dir_offset)
						if (NORTH)
							H.pixel_y = -24
							H.layer = layer - 1
						if (SOUTH)
							H.pixel_y = 24
							H.layer = layer + 1
						if (EAST)
							H.pixel_x = -24
							H.layer = layer - 1
						if (WEST)
							H.pixel_x = 24
							H.layer = layer - 1
					for (var/i = 0, i < 5, i++)
						H.pixel_y += 2
						sleep(3)
					transforming = 0
					bioHolder.AddEffect("fire_resist")
					transforming = 1
					playsound(loc, "sound/effects/heavenly.ogg", 75)
					visible_message("<span style=\"color:red\"><strong>[src] closes \his eyes in silent macho prayer!</strong></span>")
					sleep(40)
					for (var/mob/N in viewers(src, null))
						N.flash(30)
						if (N.client)
							shake_camera(N, 6, 4)
							N.show_message(text("<span style=\"color:red\"><strong>A blinding light envelops [src]!</strong></span>"), 1)

					playsound(loc, "sound/weapons/flashbang.ogg", 50, 1)
					qdel(G)
					transforming = 0
					bioHolder.RemoveEffect("fire_resist")
					verbs += /mob/living/carbon/human/machoman/verb/macho_heal
					random_brute_damage(src, 25)
					UpdateDamageIcon()
					updatehealth()
					spawn (0)
						if (H)
							H.pixel_x = 0
							H.pixel_y = 0
							H.transforming = 0
							H.full_heal()
	verb/macho_stare()
		set name = "Macho Stare"
		set desc = "Stares deeply at a victim, causing them to explode"
		set category = "Macho Moves"
		if (!stat && !transforming)
			for (var/obj/item/grab/G in src)
				if (istype(G.affecting, /mob/living))
					verbs -= /mob/living/carbon/human/machoman/verb/macho_stare
					var/mob/living/H = G.affecting
					if (H.lying)
						H.lying = 0
						H.paralysis = 0
						H.weakened = 0
						H.set_clothing_icon_dirty()
					H.jitteriness = 0
					H.transforming = 1
					transforming = 1
					dir = get_dir(src, H)
					H.dir = get_dir(H, src)
					visible_message("<span style=\"color:red\"><strong>[src] picks up [H] by the throat!</strong></span>")
					playsound(loc, pick(snd_macho_rage), 50, 0, 0, get_age_pitch())
					var/dir_offset = get_dir(src, H)
					switch(dir_offset)
						if (NORTH)
							H.pixel_y = -24
							H.layer = layer - 1
						if (SOUTH)
							H.pixel_y = 24
							H.layer = layer + 1
						if (EAST)
							H.pixel_x = -24
							H.layer = layer - 1
						if (WEST)
							H.pixel_x = 24
							H.layer = layer - 1
					for (var/i = 0, i < 5, i++)
						H.pixel_y += 2
						sleep(3)
					transforming = 0
					bioHolder.AddEffect("fire_resist")
					transforming = 1
					playsound(loc, "sound/weapons/phaseroverload.ogg", 100)
					visible_message("<span style=\"color:red\"><strong>[src] begins intensely staring [H] in the eyes!</strong></span>")
					boutput(H, "<span style=\"color:red\">You feel a horrible pain in your head!</span>")
					sleep(5)
					H.make_jittery(1000)
					H.visible_message("<span style=\"color:red\"><strong>[H] starts violently convulsing!</strong></span>")
					sleep(40)
					playsound(loc, "sound/effects/splat.ogg", 50, 1)
					qdel(G)
					var/location = get_turf(H)
					transforming = 0
					bioHolder.RemoveEffect("fire_resist")
					verbs += /mob/living/carbon/human/machoman/verb/macho_stare
					if (H.client)
						var/mob/dead/observer/newmob
						newmob = new/mob/dead/observer(H)
						H:client:mob = newmob
						H.mind.transfer_to(newmob)
						newmob.corpse = null
					H.visible_message("<span style=\"color:red\"><strong>[H] instantly vaporizes into a cloud of blood!</strong></span>")
					for (var/mob/N in viewers(src, null))
						if (N.client)
							shake_camera(N, 6, 4)
					qdel(H)
					spawn (0)
						//alldirs
						var/icon/overlay = icon('icons/effects/96x96.dmi',"smoke")
						overlay.Blend(rgb(200,0,0,200),ICON_MULTIPLY)
						var/image/I = image(overlay)
						I.pixel_x = -32
						I.pixel_y = -32
						/*
						var/the_dir = NORTH
						for (var/i=0, i<8, i++)
						*/
						var/reagents/bloodholder = new /reagents(25)
						bloodholder.add_reagent("blood", 25)
						smoke_reaction(bloodholder, 4, location)
						particleMaster.SpawnSystem(new /particleSystem/chemSmoke(location, bloodholder, 100))
						//the_dir = turn(the_dir,45)

	verb/macho_heartpunch(var/mob/living/M in oview(1))
		set name = "Macho Heartpunch"
		set desc = "Punches a guy's heart. Right out of their body."
		set category = "Macho Moves"

		var/did_it = 0
		verbs -= /mob/living/carbon/human/machoman/verb/macho_heartpunch
		var/direction = get_dir(src,M)
		if (ishuman(M))
			var/mob/living/carbon/human/H = M
			if (H.organHolder && H.organHolder.heart)
				//PUNCH THE HEART! YEAH!
				visible_message("<span style=\"color:red\"><strong>[src] punches out [H]'s heart!</strong></span>")
				playsound(src, 'sound/effects/fleshbr1.ogg', 50, 1)

				var/obj/item/organ/heart/heart_to_punt = H.organHolder.drop_organ("heart")

				for (var/I = 1, I <= 5 && heart_to_punt && step(heart_to_punt,direction, 1), I++)
//						new D(heart_to_punt.loc)
					bleed(H, 25, 5)
					playsound(heart_to_punt,'sound/effects/splat.ogg', 50, 1)

				H.emote("scream")
				did_it = 1
			else
				show_text("Man, this poor sucker ain't got a heart to punch, whatta chump.", "blue")
				spawn (20)
					if (!stat)
						emote("sigh")

		else if (isrobot(M)) //Extra mean to borgs.

			var/mob/living/silicon/robot/R = M
			if (R.part_chest)
				visible_message("<span style=\"color:red\"><strong>[src] punches off [R]'s chest!</strong></span>")
				playsound(src, 'sound/effects/grillehit.ogg', 50, 1)
				R.emote("scream")
				var/obj/item/parts/robot_parts/chest/chestpunt = new R.part_chest.type(R.loc)
				chestpunt.name = "[R.name]'s [chestpunt.name]"
				R.compborg_lose_limb(R.part_chest)

				for (var/I = 1, I <= 5 && chestpunt && step(chestpunt ,direction, 1), I++)
					new/obj/decal/cleanable/oil(chestpunt.loc)
					playsound(chestpunt,'sound/effects/splat.ogg', 50, 1)

				did_it = 1

			else //Uh?
				show_text("Man, this poor sucker ain't even got a chest to punch, whatta chump.", "blue")
				spawn (20)
					if (!stat)
						emote("sigh")

		else
			show_text("You're not entirely sure where the heart is on this thing. Better leave it alone.", "blue")
			spawn (20)
				if (!stat)
					emote("sigh")

		if (did_it)
			spawn (rand(2,4) * 10)
				playsound(loc, pick(snd_macho_rage), 50, 0, 0, get_age_pitch())
				visible_message("<span style=\"color:red\"><strong>[src]</strong> gloats and boasts!</span>")

		verbs += /mob/living/carbon/human/machoman/verb/macho_heartpunch
/*
	verb/macho_meteor()
		set name = "Macho Meteors"
		set desc = "Summon a wave of meteors with dark macho magic"
		set category = "Macho Moves"
		if (!stat && !transforming)
			bioHolder.AddEffect("fire_resist")
			transforming = 1
			mouse_opacity = 0
			verbs -= /mob/living/carbon/human/machoman/verb/macho_meteor
			visible_message("<span style=\"color:red\">[src] pauses and curses for a moment.</span>")
			playsound(loc, "sound/voice/macho/macho_alert26.ogg", 50)
			sleep(40)
			visible_message("<span style=\"color:red\">[src] begins to hover mysteriously above the ground!</span>")
			playsound(loc, "sound/effects/bionic_sound.ogg", 50)
			playsound(loc, "sound/voice/macho/macho_moan07.ogg", 50)
			layer = 10
			density = 0
			for (var/i = 0, i < 20, i++)
				pixel_y += 1
				dir = turn(dir, 90)
				sleep(1)
			dir = SOUTH
			var/sound/siren = sound('sound/misc/airraid_loop.ogg')
			var/list/masters = new()
			for (var/area/subs in world)
				if (subs.master && !(subs.master in masters))
					masters += subs.master

			for (var/area/A in masters)
				if (A.type == /area) continue
				for (var/area/R in A.related)
					spawn (0)
						R.eject = 1
						R.updateicon()
			siren.repeat = 1
			siren.channel = 5
			boutput(world, siren)
			randomevent_meteorshower(16)
			sleep(300)
			visible_message("<span style=\"color:red\">[src] falls back to the ground!</span>")
			for (var/i = 0, i < 20, i++)
				pixel_y -= 1
				dir = turn(dir, -90)
				sleep(1)
			if (istype(loc, /turf/simulated/floor))
				loc:break_tile()
			for (var/mob/M in viewers(src, 5))
				if (M != src)
					M.weakened = max(M.weakened, 8)
				spawn (0)
					shake_camera(M, 4, 2)
			playsound(loc, "explosion", 40, 1)
			playsound(loc, pick(snd_macho_rage), 50)
			layer = MOB_LAYER
			density = 1
			transforming = 0
			bioHolder.RemoveEffect("fire_resist")
			mouse_opacity = 1
			spawn (600)
				if (siren)
					siren.repeat = 0
					siren.status = SOUND_UPDATE
					siren.channel = 5
					boutput(world, siren)
				for (var/area/A in masters)
					if (A.type == /area) continue
					for (var/area/R in A.related)
						spawn (0)
							R.eject = 0
							R.updateicon()
				verbs += /mob/living/carbon/human/machoman/verb/macho_meteor
*/
	emote(var/act)
		switch(act)
			if ("scream")
				playsound(loc, pick(snd_macho_rage), 75, 0, 0, get_age_pitch())
				visible_message("<span style=\"color:red\"><strong>[src] yells out a battle cry!</strong></span>")
			else
				..()

/obj/critter/microman
	name = "Micro Man"
	desc = "All the macho madness you'd ever need, shrunk down to pocket size."
	icon_state = "microman"
	health = 25
	aggressive = 1
	defensive = 1
	wanderer = 1
	opensdoors = 1
	atkcarbon = 1
	atksilicon = 1
	atcritter = 1
	density = 0
	angertext = "rages at"

	New()
		..()
		if (prob(50))
			playsound(loc, pick(snd_macho_rage), 50, 1, 0, 1.75)

	ai_think()
		..()
		if (prob(10))
			playsound(loc, pick(snd_macho_idle), 50, 1, 0, 1.75)

	attack_hand(mob/user as mob)
		if (alive && (user.a_intent != INTENT_HARM))
			visible_message("<span style=\"color:red\"><strong>[user]</strong> pets [src]!</span>")
			return
		..()

	CritterAttack(mob/M)
		if (ismob(M))
			attacking = 1
			var/attack_message = ""
			switch(rand(1,3))
				if (1)
					attack_message = "<strong>[src]</strong> punches [target] in the stomach!"
				if (2)
					attack_message = "<strong>[src]</strong> kicks [target] with his shoes!"
				if (3)
					attack_message = "<strong>[src]</strong> headbutts [target]!"
			for (var/mob/O in viewers(src, null))
				O.show_message("<span style=\"color:red\">[attack_message]</span>", 1)
			playsound(loc, "swing_hit", 30, 0)
			if (prob(10))
				playsound(loc, pick(snd_macho_rage), 50, 1, 0, 1.75)
			random_brute_damage(target, rand(0,1))
			spawn (rand(1,3))
				attacking = 0

	ChaseAttack(mob/M)
		for (var/mob/O in viewers(src, null))
			O.show_message("<span style=\"color:red\"><strong>[src]</strong> charges at [M]!</span>", 1)
		if (prob(50))
			playsound(loc, pick(snd_macho_rage), 50, 1, 0, 1.75)
		M.stunned += rand(0,1)
		if (prob(25))
			M.weakened += rand(1,2)
			random_brute_damage(M, rand(1,2))
	CritterDeath()
		alive = 0
		playsound(loc, "sound/effects/splat.ogg", 75, 1)
		var/obj/decal/cleanable/blood/gibs/gib = null
		gib = new /obj/decal/cleanable/blood/gibs(loc)
		gib.streak(list(NORTH, NORTHEAST, NORTHWEST))
		qdel(src)


/obj/item/clothing/under/gimmick/macho
	name = "wrestling pants"
	desc = "Official pants of the Space Wrestling Federation."
	icon_state = "machopants"
	item_state = "machopants"

/obj/item/clothing/suit/armor/vest/macho
	name = "tiger stripe vest"
	desc = "A flamboyant showman's vest."
	icon = 'icons/obj/clothing/overcoats/item_suit_gimmick.dmi'
	wear_image_icon = 'icons/mob/overcoats/worn_suit_gimmick.dmi'
	icon_state = "machovest"
	item_state = "machovest"

/obj/item/clothing/glasses/macho
	name = "Yellow Shades"
	desc = "A snazzy pair of shades."
	icon_state = "machoglasses"
	item_state = "glasses"

/obj/item/clothing/head/helmet/macho
	name = "Macho Man Doo-Rag"
	desc = "'To my perfect friend' - signed, Mr. Perfect"
	icon_state = "machohat"

/obj/item/storage/belt/macho_belt
	name = "Championship Belt"
	desc = "Awarded to the best space wrestler of the year."
	icon = 'icons/obj/belts.dmi'
	icon_state = "machobelt"
	item_state = "machobelt"
	flags = FPRINT | TABLEPASS | ONBELT | NOSPLASH

/obj/item/clothing/shoes/macho
	name = "Wrestling boots"
	desc = "Cool pair of boots."
	icon_state = "machoboots"

/obj/item/macho_coke
	name = "unmarked white bag"
	desc = "Contains columbian sugar."
	icon = 'icons/obj/items.dmi'
	icon_state = "cokebag"
	item_state = "chefhat" // lol
	w_class = 1

	attack(mob/target as mob)
		if (istype(target, /mob/living/carbon/human/machoman))
			target.visible_message("<span style=\"color:red\">[target] shoves \his face deep into [src] and breathes deeply!</span>")
			playsound(target.loc, "sound/voice/macho/macho_breathing02.ogg", 50, 1)
			sleep(25)
			playsound(target.loc, "sound/voice/macho/macho_freakout.ogg", 50, 1)
			target.visible_message("<span style=\"color:red\">[target] appears visibly stronger!</span>")
			if (target.reagents)
				target.reagents.add_reagent("stimulants", 100)
			if (istype(target, /mob/living/carbon/human))
				var/mob/living/carbon/human/machoman/H = target
				for (var/A in H.organs)
					var/obj/item/affecting = null
					if (!H.organs[A])    continue
					affecting = H.organs[A]
					if (!istype(affecting, /obj/item))
						continue
					affecting.heal_damage(50, 50) //heals 50 burn, 50 brute from all organs
				H.UpdateDamageIcon()
				target.updatehealth()
				H.bodytemperature = H.base_body_temp
		else
			target.visible_message("<span style=\"color:red\">[target] shoves \his face deep into [src]!</span>")
			spawn (25)
			target.visible_message("<span style=\"color:red\">[target]'s pupils dilate.</span>")
			target.stunned += 100

/obj/item/reagent_containers/food/snacks/slimjim
	name = "Space Jim"
	desc = "It's a stick of mechanically-separated mystery meat."
	icon = 'icons/obj/foodNdrink/food_snacks.dmi'
	icon_state = "slimjim"
	item_state = "stamp"
	heal_amt = 2
	amount = 5
	New()
		var/reagents/R = new/reagents(50)
		reagents = R
		R.my_atom = src
		R.add_reagent("capsaicin", 20)
		R.add_reagent("porktonium", 30)
	attack(var/mob/M, var/mob/user, def_zone)
		if (istype(M, /mob/living/carbon/human/machoman) && M == user)
			playsound(user.loc, "sound/effects/snap.ogg", 75, 1)
			playsound(user.loc, "sound/voice/macho/macho_slimjim.ogg", 60)
			for (var/mob/O in viewers(user))
				O.show_message("<span style=\"color:red\"><strong>[user] snaps into a Space Jim!!</strong></span>", 1)
			sleep(rand(10,20))
			var/turf/T = get_turf(M)
			playsound(user.loc, "explosion", 100, 1)
			spawn (0)
				var/obj/overlay/O = new/obj/overlay(T)
				O.anchored = 1
				O.name = "Explosion"
				O.layer = NOLIGHT_EFFECTS_LAYER_BASE
				O.pixel_x = -32
				O.pixel_y = -32
				O.icon = 'icons/effects/hugeexplosion2.dmi'
				O.icon_state = "explosion"
				spawn (35) qdel(O)
				for (var/mob/N in viewers(user))
					shake_camera(N, 8, 3)
			spawn (0)
				var/obj/item/old_grenade/emp/temp_nade = new(user.loc)
				temp_nade.prime()
			spawn (0)
				for (var/atom/A in range(user.loc, 4))
					if (ismob(A) && A != user)
						var/mob/N = A
						N.weakened = max(N.weakened, 8)
						step_away(N, user)
						step_away(N, user)
					else if (isobj(A) || isturf(A))
						A.ex_act(3)
		else
			..()

/mob/living/proc/become_gold_statue()
	var/obj/overlay/goldman = new /obj/overlay(get_turf(src))
	pixel_x = 0
	pixel_y = 0
	set_loc(goldman)
	goldman.name = "golden statue of [name]"
	goldman.desc = desc
	goldman.anchored = 0
	goldman.density = 1
	goldman.layer = MOB_LAYER
	goldman.dir = dir

	var/ist = "body_f"
	if (gender == "male")
		ist = "body_m"
	var/icon/composite = icon('icons/mob/human.dmi', ist, null, 1)
	for (var/O in overlays)
		var/image/I = O
		composite.Blend(icon(I.icon, I.icon_state, null, 1), ICON_OVERLAY)
	composite.ColorTone( rgb(255,215,0) ) // gold
	goldman.icon = composite
	take_toxin_damage(9999)
	ghostize()

//#undef MAX_MINIONS_PER_SPAWN