/obj/critter/zombie
	name = "Zombie"
	desc = "BraaAAAinnsSSs..."
	icon_state = "zombie"
	density = 1
	health = 20
	aggressive = 1
	defensive = 0
	wanderer = 1
	opensdoors = 1
	atkcarbon = 1
	atksilicon = 1
	atcritter = 1
	firevuln = 0.25
	brutevuln = 0.5
	butcherable = 1

	var/punch_damage_max = 9
	var/punch_damage_min = 3
	var/hulk = 0 //A zombie hulk? Oh god.
	var/eats_brains = 1

	skinresult = /obj/item/material_piece/cloth/leather
	max_skins = 2

	New()
		..()
		playsound(loc, pick('sound/voice/Zgroan1.ogg', 'sound/voice/Zgroan2.ogg', 'sound/voice/Zgroan3.ogg', 'sound/voice/Zgroan4.ogg'), 25, 0)

	seek_target()
		anchored = 0
		for (var/mob/living/C in hearers(seekrange,src))
			if ((C.name == oldtarget_name) && (world.time < last_found + 100)) continue
			if (iscarbon(C) && !atkcarbon) continue
			if (istype(C, /mob/living/silicon) && !atksilicon) continue
			if (C.health < 0) continue
			if (istype(C,/mob/living/carbon/human))
				if (C:mutantrace && istype(C:mutantrace, /mutantrace/zombie)) continue
				if (istype(C:head, /obj/item/clothing/head/void_crown)) continue

			if (iscarbon(C) && atkcarbon) attack = 1
			if (istype(C, /mob/living/silicon) && atksilicon) attack = 1

			if (attack)
				target = C
				oldtarget_name = C.name
				visible_message("<span style=\"color:red\"><strong>[src]</strong> lunges at [C.name]!</span>")
				playsound(loc, pick('sound/voice/Zgroan1.ogg', 'sound/voice/Zgroan2.ogg', 'sound/voice/Zgroan3.ogg', 'sound/voice/Zgroan4.ogg'), 25, 0)
				task = "chasing"
				return
			else
				continue


		if (!atcritter) return
		for (var/obj/critter/C in view(seekrange,src))
			if (!C.alive) continue
			if (C.health < 0) continue
			if (!istype(C, /obj/critter/zombie)) attack = 1

			if (attack)
				target = C
				oldtarget_name = C.name
				visible_message("<span style=\"color:red\"><strong>[src]</strong> lunges at [C.name]!</span>")
				playsound(loc, pick('sound/voice/Zgroan1.ogg', 'sound/voice/Zgroan2.ogg', 'sound/voice/Zgroan3.ogg', 'sound/voice/Zgroan4.ogg'), 25, 0)
				task = "chasing"
				return

			else continue



	ChaseAttack(mob/M)
		if (iscarbon(M) && prob(15))
			visible_message("<span style=\"color:red\"><strong>[src]</strong> slams into [target]!</span>")
			playsound(loc, "sound/weapons/genhit1.ogg", 50, 1, -1)
			random_brute_damage(M, rand(0,3))
			M.stunned += rand(0,4)
			M.weakened += rand(1,4)
		else
			visible_message("<span style=\"color:red\"><strong>[src]</strong> tries to knock down [target] but misses!</span>")

	CritterAttack(mob/living/M)
		attacking = 1
		if (istype(M,/obj/critter))
			var/obj/critter/C = M
			visible_message("<span style=\"color:red\"><strong>[src]</strong> punches [target]!</span>")
			playsound(C.loc, "punch", 25, 1, -1)
			C.health -= 4
			if (C.health <= 0)
				C.CritterDeath()
			spawn (25)
				attacking = 0
			return

		if (M.health > 40 && !M.weakened)
			visible_message("<span style=\"color:red\"><strong>[src]</strong> punches [target]!</span>")
			playsound(M.loc, "punch", 25, 1, -1)

			var/to_deal = rand(punch_damage_min,punch_damage_max)
			random_brute_damage(M, to_deal)
			if (iscarbon(M))
				if (to_deal > (((punch_damage_max-punch_damage_min)/2)+punch_damage_min) && prob(50))
					visible_message("<span style=\"color:red\"><strong>[src] knocks down [M]!</strong></span>")
					M:weakened += 8
		//		if (prob(4) && eats_brains) //Give the gift of being a zombie (unless we eat them too fast)
		//			M.contract_disease(/ailment/disease/necrotic_degeneration, null, null, 1) // path, name, strain, bypass resist
			if (hulk) //TANK!
				spawn (0)
					M:paralysis += 1
					step_away(M,src,15)
					spawn (3) step_away(M,src,15)
			spawn (25)
				attacking = 0
		else
			if (istype(M,/mob/living/carbon/human) && eats_brains) //These only make human zombies anyway!
				visible_message("<span style=\"color:red\"><strong>[src]</strong> starts trying to eat [M]'s brain!</span>")
			else
				visible_message("<span style=\"color:red\"><strong>[src]</strong> attacks [target]!</span>")
				playsound(loc, "sound/weapons/genhit1.ogg", 50, 1, -1)
				random_brute_damage(target, rand(punch_damage_min,punch_damage_max))
				spawn (25)
					attacking = 0
				return
			spawn (60)
				if (get_dist(src, M) <= 1 && ((M:loc == target_lastloc)))
					if (iscarbon(M))
						logTheThing("combat", M, null, "was zombified by [src] at [log_loc(src)].") // Some logging for instakill critters would be nice (Convair880).
						M.death(1)
						visible_message("<span style=\"color:red\"><strong>[src]</strong> slurps up [M]'s brain!</span>")
						playsound(loc, "sound/items/eatfood.ogg", 30, 1, -2)
						M.canmove = 0
						M.icon = null
						M.invisibility = 101
						M:death()
						var/obj/critter/zombie/P = new(M.loc)
						///this little bit of code prevents multiple zombies from the same victim
						if (M == null)
							qdel(P)
							return
						visible_message("<span style=\"color:red\">[M]'s corpse reanimates!</span>")
						//Zombie is all dressed up and no place to go
						var/stealthy = 0 //High enough and people won't even see it's undead right away.
						if (istype(M,/mob/living/carbon/human))
							var/mob/living/carbon/human/H = M
							//Uniform
							if (H.w_uniform)
								if (istype(H.w_uniform, /obj/item/clothing/under))
									P.overlays += image("icon" = 'icons/mob/jumpsuits/worn_js.dmi', "icon_state" = H.w_uniform.icon_state, "layer" = FLOAT_LAYER)
									stealthy += 4
							//Suit
							if (H.wear_suit)
								if (istype(H.wear_suit, /obj/item/clothing/suit))
									P.overlays += image("icon" = 'icons/mob/overcoats/worn_suit.dmi', "icon_state" = H.wear_suit.icon_state, "layer" = FLOAT_LAYER)
									stealthy += 2
							//Back
							if (H.back)
								var/t1 = H.back.icon_state
								P.overlays += image("icon" = 'icons/mob/back.dmi', "icon_state" = t1, "layer" = FLOAT_LAYER)
							//Mask
							if (H.wear_mask)
								if (istype(H.wear_mask, /obj/item/clothing/mask))
									var/t1 = H.wear_mask.icon_state
									P.overlays += image("icon" = 'icons/mob/mask.dmi', "icon_state" = t1, "layer" = FLOAT_LAYER)
									if (H.wear_mask.c_flags & COVERSEYES)
										stealthy += 2
							//Shoes
							if (H.shoes)
								if (istype(H.shoes))
									var/t1 = H.shoes.icon_state
									P.overlays += image("icon" = 'icons/mob/feet.dmi', "icon_state" = t1, "layer" = FLOAT_LAYER)
									stealthy++
							//Gloves.  Zombie boxers??
							if (H.gloves)
								if (istype(H.gloves))
									var/t1 = H.gloves.item_state
									P.overlays += image("icon" = 'icons/mob/hands.dmi', "icon_state" = t1, "layer" = FLOAT_LAYER)
									stealthy++
							//Head
							if (H.head)
								var/t1 = H.head.icon_state
								var/icon/head_icon = icon('icons/mob/head.dmi', "[t1]")
								if (istype(H.head, /obj/item/clothing/head/butt))
									var/obj/item/clothing/head/butt/B = H.head
									if (B.s_tone >= 0)
										head_icon.Blend(rgb(B.s_tone, B.s_tone, B.s_tone), ICON_ADD)
									else
										head_icon.Blend(rgb(-B.s_tone,  -B.s_tone,  -B.s_tone), ICON_SUBTRACT)
								P.overlays += image("icon" = head_icon, "layer" = FLOAT_LAYER)
								if (H.head.c_flags & COVERSEYES)
									stealthy += 2
								if (H.head.c_flags & COVERSMOUTH)
									stealthy += 2

							//Oh no, a tank!
							if (H.bioHolder.HasEffect("hulk"))
								P.hulk = 1
								P.punch_damage_max += 4

						P.health = health
						if (stealthy >= 10)
							P.name = M.real_name
						else
							P.name += " [M.real_name]"

						var/atom/movable/overlay/animation = null
						if (ishuman(M))
							animation = new(loc)
							animation.icon_state = "blank"
							animation.icon = 'icons/mob/mob.dmi'
							animation.master = src
						if (M.client)
							var/mob/dead/observer/newmob
							newmob = new/mob/dead/observer(M)
							M.client:mob = newmob
							M.mind.transfer_to(newmob)
						qdel(M)
						qdel(animation)
						sleeping = 2
						spawn (20) playsound(loc, pick("sound/misc/burp_alien.ogg"), 50, 0)
				else
					visible_message("<span style=\"color:red\"><strong>[src]</strong> gnashes its teeth in fustration!</span>")
				attacking = 0

	CritterDeath()
		alive = 0
		playsound(loc, "sound/effects/splat.ogg", 100, 1)
		var/obj/decal/cleanable/blood/gibs/gib = null
		gib = new /obj/decal/cleanable/blood/gibs(loc)
		if (prob(30))
			gib.icon_state = "gibup1"
		gib.streak(list(NORTH, NORTHEAST, NORTHWEST))
		qdel (src)

/obj/critter/zombie/scientist
	name = "Shambling Scientist"
	desc = "Physician, heal thyself! Welp, so much for that."
	icon_state = "scizombie"
	health = 10
	firevuln = 0.15
	generic = 0

	ChaseAttack(mob/M)
		if (!attacking)
			CritterAttack(M)
		return

/obj/critter/zombie/security
	name = "Undead Guard"
	desc = "Eh, couldn't be any worse than regular security."
	icon_state = "seczombie"
	health = 18
	brutevuln = 0.6
	generic = 0

	ChaseAttack(mob/M)
		if (!attacking)
			CritterAttack(M)
		return

	CritterDeath()
		alive = 0
		playsound(loc, "sound/effects/splat.ogg", 100, 1)
		gibs(loc)
		qdel (src)

/obj/critter/zombie/h7
	name = "Biosuit Shambler"
	desc = "This does not reassure one about biosuit reliability."
	icon_state = "suitzombie"
	health = 10
	brutevuln = 0.6
	atcritter = 0
	eats_brains = 0
	generic = 0

	ChaseAttack(mob/M)
		if (!attacking)
			CritterAttack(M)
		return

	CritterDeath()
		alive = 0
		visible_message("<span style=\"color:red\">Black mist flows from the broken suit!</span>")
		playsound(loc, "sound/machines/hiss.ogg", 50, 1)

		harmless_smoke_puff(loc)

		new /obj/critter/aberration(loc)
		new /obj/item/clothing/suit/bio_suit(loc)
		new /obj/item/clothing/gloves/latex(loc)
		new /obj/item/clothing/head/bio_hood(loc)
		qdel (src)

//It's like the jam mansion is back!
/obj/critter/zombie/hogan
	name = "Zombie Hogan"
	desc = "Hulkamania is shambling wiilllldd in space!"
	icon_state = "hoganzombie"
	health = 25
	firevuln = 0.15
	hulk = 1
	generic = 0

	ChaseAttack(mob/M)
		if (!attacking)
			CritterAttack(M)
		return
