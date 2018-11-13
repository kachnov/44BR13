/////////// cogwerks - hideous wendigo beast

/obj/critter/wendigo
	name = "wendigo"
	desc = "Oh god."
	icon_state = "wendigo"
	invisibility = 16
	health = 60
	firevuln = 1
	brutevuln = 0.5
	aggressive = 1
	defensive = 1
	wanderer = 1
	opensdoors = 0
	seekrange = 6
	density = 0
	butcherable = 1
	can_revive = 1
	var/boredom_countdown = 0
	var/spazzing = 0
	var/frenzied = 0
	var/king = 0

	var/left_arm_stage = 0
	var/right_arm_stage = 0
	var/obj/item/parts/human_parts/arm/left/wendigo/left_arm
	var/obj/item/parts/human_parts/arm/right/wendigo/right_arm

	skinresult = /obj/item/material_piece/cloth/wendigohide

	New()
		left_arm = new /obj/item/parts/human_parts/arm/left/wendigo(src)
		right_arm = new /obj/item/parts/human_parts/arm/right/wendigo(src)
		..()

	on_revive()
		if (!left_arm)
			left_arm = new /obj/item/parts/human_parts/arm/left/wendigo(src)
			left_arm_stage = 0
			visible_message("<span style=\"color:red\">[src]'s left arm regrows!</span>")
		if (!right_arm)
			right_arm = new /obj/item/parts/human_parts/arm/right/wendigo(src)
			right_arm_stage = 0
			visible_message("<span style=\"color:red\">[src]'s right arm regrows!</span>")
		..()

	CritterDeath()
		if (alive)
			playsound(loc, "sound/misc/wendigo_cry.ogg", 60, 1)
			visible_message("<strong>[src]</strong> dies!")
			alive = 0
			walk_to(src,0)
			update_dead_icon()
			anchored = 0
			density = 0
			layer = initial(layer)

	seek_target()
		anchored = 0
		if (target)
			task = "chasing"
			return
		for (var/mob/living/C in hearers(seekrange,src))
			if (!istype(C,/mob/living/silicon/robot/) && !istype(C,/mob/living/carbon/human)) continue
			if ((C.name == oldtarget_name) && (world.time < last_found + 100)) continue
			//if (C.stat || C.health < 0) continue

			if (ishuman(C))
				var/mob/living/carbon/human/H = C
				if (!king && iswerewolf(H))
					visible_message("<span style=\"color:red\"><strong>[src] backs away in fear!</strong></span>")
					step_away(src, H, 15)
					dir = get_dir(src, H)
					continue

			boredom_countdown = rand(2,5)
			if (king)
				boredom_countdown = rand(0,1) // king wendigos are pretty much grump elementals
			target = C
			oldtarget_name = C.name
			task = "chasing"
			appear()
			if (king)
				playsound(loc, "sound/misc/wendigo_roar.ogg", 75, 1)
				visible_message("<span style=\"color:red\"><strong>[src] roars!</strong></span>", 1)
			break

	proc/update_dead_icon()
		if (alive)
			return
		. = "wendigo"
		if (!left_arm)
			. += "-l"
		if (!right_arm)
			. += "-r"
		. += "-dead"
		icon_state = .

	attackby(obj/item/W as obj, mob/living/user as mob)
		if (!alive)
			// TODO: tie this into surgery()
			if (istype(W, /obj/item/scalpel))
				if (user.zone_sel.selecting == "l_arm")
					if (left_arm_stage == 0)
						user.visible_message("<span style=\"color:red\">[user] slices through the skin and flesh of [src]'s left arm with [W].</span>", "<span style=\"color:red\">You slice through the skin and flesh of [src]'s left arm with [W].</span>")
						left_arm_stage++
					else if (left_arm_stage == 2)
						user.visible_message("<span style=\"color:red\">[user] cuts through the remaining strips of skin holding [src]'s left arm on with [W].</span>", "<span style=\"color:red\">You cut through the remaining strips of skin holding [src]'s left arm on with [W].</span>")
						left_arm_stage++

						left_arm.quality = (quality + 150) / 350.0
						var/nickname = "king"
						if (quality < 200)
							nickname = quality_name
						if (nickname)
							left_arm.name = "[nickname] [initial(left_arm.name)]"

						var/turf/location = get_turf(src)
						if (location)
							left_arm.set_loc(location)
							left_arm = null
						update_dead_icon()

				else if (user.zone_sel.selecting == "r_arm")
					if (right_arm_stage == 0)
						user.visible_message("<span style=\"color:red\">[user] slices through the skin and flesh of [src]'s right arm with [W].</span>", "<span style=\"color:red\">You slice through the skin and flesh of [src]'s right arm with [W].</span>")
						right_arm_stage++
					else if (right_arm_stage == 2)
						user.visible_message("<span style=\"color:red\">[user] cuts through the remaining strips of skin holding [src]'s right arm on with [W].</span>", "<span style=\"color:red\">You cut through the remaining strips of skin holding [src]'s right arm on with [W].</span>")
						right_arm_stage++

						right_arm.quality = (quality + 100) / 350.0
						var/nickname = "king"
						if (quality < 200)
							nickname = quality_name
						if (nickname)
							right_arm.name = "[nickname] [initial(right_arm.name)]"

						var/turf/location = get_turf(src)
						if (location)
							right_arm.set_loc(location)
							right_arm = null
						update_dead_icon()

			else if (istype(W, /obj/item/circular_saw))
				if (user.zone_sel.selecting == "l_arm")
					if (left_arm_stage == 1)
						user.visible_message("<span style=\"color:red\">[user] saws through the bone of [src]'s left arm with [W].</span>", "<span style=\"color:red\">You saw through the bone of [src]'s left arm with [W].</span>")
						left_arm_stage++
				else if (user.zone_sel.selecting == "r_arm")
					if (right_arm_stage == 1)
						user.visible_message("<span style=\"color:red\">[user] saws through the bone of [src]'s right arm with [W].</span>", "<span style=\"color:red\">You saw through the bone of [src]'s right arm with [W].</span>")
						right_arm_stage++
			else
				..()
			return
		var/attack_force = 0
		var/damage_type = "brute"
		if (istype(W, /obj/item/artifact/melee_weapon))
			var/artifact/melee/ME = W.artifact
			attack_force = ME.dmg_amount
			damage_type = ME.damtype
		else
			attack_force = W.force
			damage_type = W.damtype
		switch(damage_type)
			if ("fire")
				health -= attack_force * firevuln
			if ("brute")
				health -= attack_force * brutevuln
			else
				health -= attack_force * miscvuln
		for (var/mob/O in viewers(src, null))
			O.show_message("<span style=\"color:red\"><strong>[user]</strong> hits [src] with [W]!</span>", 1)
		if (prob(30))
			playsound(loc, "sound/misc/wendigo_cry.ogg", 60, 1)
			visible_message("<span style=\"color:red\"><strong>[src] cries!</strong></span>", 1)
		if (prob(25) && alive) // crowds shouldn't be able to beat the fuck out of a confused wendigo with impunity, fuck that
			target = user
			oldtarget_name = user.name
			task = "chasing"
			playsound(loc, "sound/weapons/genhit1.ogg", 60, 1)
			visible_message("<span style=\"color:red\"><strong>[src]</strong> slams into [target]!</span>")
			target:weakened += 2
			frenzy(target)

		if (alive && health <= 0) CritterDeath()

		//boredom_countdown = rand(5,10)
		target = user
		oldtarget_name = user.name
		task = "chasing"

	attack_hand(var/mob/user as mob)

		if (!alive)
			..()
			return
		if (user.a_intent == INTENT_HARM)
			health -= rand(1,2) * brutevuln
			on_damaged(src)
			for (var/mob/O in viewers(src, null))
				O.show_message("<span style=\"color:red\"><strong>[user]</strong> punches [src]!</span>", 1)
			playsound(loc, "punch", 50, 1)
			if (prob(30))
				playsound(loc, "sound/misc/wendigo_cry.ogg", 60, 1)
				visible_message("<span style=\"color:red\"><strong>[src] cries!</strong></span>", 1)
			if (prob(20) && alive) // crowd beatdown fix
				target = user
				oldtarget_name = user.name
				task = "chasing"
				playsound(loc, "sound/weapons/genhit1.ogg", 50, 1)
				visible_message("<span style=\"color:red\"><strong>[src]</strong> slams into [target]!</span>")
				target:weakened += 20
				frenzy(target)
			if (alive && health <= 0) CritterDeath()

			//boredom_countdown = rand(5,10)
			target = user
			oldtarget_name = user.name
			task = "chasing"
		else
			visible_message("<span style=\"color:red\"><strong>[user]</strong> pets [src]!</span>", 1)
			playsound(loc, "sound/misc/wendigo_laugh.ogg", 60, 1)
			visible_message("<span style=\"color:red\"><strong>[src] laughs!</strong></span>", 1)

	on_sleep()
		..()
		disappear()

	ChaseAttack(mob/M)
		if (prob(10))
			playsound(loc, "sound/misc/wendigo_scream.ogg", 75, 1)
			visible_message("<span style=\"color:red\"><strong>[src] howls!</strong></span>", 1)
			visible_message("<span style=\"color:red\"><strong>[src]</strong> tackles [M]!</span>")
			playsound(loc, "sound/weapons/genhit1.ogg", 50, 1, -1)
			if (ismob(M))
				M.stunned += rand(1,2)
				M.weakened += rand(1,2)

	CritterAttack(mob/M) // nominating this for scariest goddamn critter 2013
		attacking = 1
		var/attack_delay = rand(10,30) // needs to attack more often, changed from 30

		if (istype(M,/mob/living/silicon/robot))
			var/mob/living/silicon/robot/BORG = M
			if (!BORG.part_head)
				visible_message("<span style=\"color:red\"><strong>[src]</strong> sniffs at [BORG.name].</span>")
				sleep(15)
				visible_message("<span style=\"color:red\"><strong>[src]</strong> throws a tantrum and smashes [BORG.name] to pieces!</span>")
				playsound(loc, "sound/misc/wendigo_scream.ogg", 75, 1)
				playsound(loc, "sound/effects/wbreak.wav", 70, 1)
				BORG.gib()
				target = null
				boredom_countdown = 0
			else
				if (BORG.part_head.ropart_get_damage_percentage() >= 85)
					visible_message("<span style=\"color:red\"><strong>[src]</strong> grabs [BORG.name]'s head and wrenches it right off!</span>")
					playsound(loc, "sound/misc/wendigo_laugh.ogg", 70, 1)
					playsound(loc, "sound/effects/wbreak.wav", 70, 1)
					BORG.compborg_lose_limb(BORG.part_head)
					sleep(15)
					visible_message("<span style=\"color:red\"><strong>[src]</strong> ravenously eats the mangled brain remnants out of the decapitated head!</span>")
					playsound(loc, "sound/misc/wendigo_maul.ogg", 80, 1)
					new /obj/decal/cleanable/blood(loc)
					target = null
				else
					visible_message("<span style=\"color:red\"><strong>[src]</strong> pounds on [BORG.name]'s head furiously!</span>")
					playsound(loc, "sound/effects/zhit.ogg", 50, 1)
					BORG.part_head.ropart_take_damage(rand(20,40),0)
					if (prob(33)) playsound(loc, "sound/misc/wendigo_scream.ogg", 75, 1)
					attack_delay = 5
		else
			if (boredom_countdown-- > 0)
				if (prob(70))
					visible_message("<span style=\"color:red\"><strong>[src]</strong> [pick("bites", "nibbles", "chews on", "gnaws on")] [target]!</span>")
					playsound(loc, "sound/effects/bloody_stab.ogg", 50, 1)
					playsound(loc, "sound/items/eatfood.ogg", 50, 1)
					random_brute_damage(target, 10)
					take_bleeding_damage(target, null, 5, DAMAGE_STAB, 1, get_turf(target))
					if (prob(40))
						playsound(loc, "sound/misc/wendigo_laugh.ogg", 70, 1)
						visible_message("<span style=\"color:red\"><strong>[src] laughs!</strong></span>", 1)
				else
					visible_message("<span style=\"color:red\"><strong>[src]</strong> [pick("slashes", "swipes", "claws", "tears")] a chunk out of [target]!</span>")
					playsound(loc, "sound/effects/bloody_stab.ogg", 50, 1)
					random_brute_damage(target, 20)
					take_bleeding_damage(target, null, 10, DAMAGE_CUT, 0, get_turf(target))
					playsound(loc, "sound/effects/splat.ogg", 50, 1)
					playsound(loc, "sound/misc/wendigo_scream.ogg", 75, 1)
					visible_message("<span style=\"color:red\"><strong>[src] howls!</strong></span>", 1)
					if (!M.stat) M.emote("scream") // don't scream while dead/asleep

			else // flip the fuck out
				playsound(loc, "sound/weapons/genhit1.ogg", 50, 1)
				visible_message("<span style=\"color:red\"><strong>[src]</strong> slams into [target]!</span>")
				target:weakened += 3
				frenzy(target)

			if (M.stat == 2) // devour corpses
				visible_message("<span style=\"color:red\"><strong>[src] devours [target]! Holy shit!</strong></span>")
				playsound(loc, "sound/effects/fleshbr1.ogg", 50, 1)
				M.ghostize()
				new /obj/decal/skeleton(M.loc)
				M.gib()
				target = null

		spawn (attack_delay)
			attacking = 0

	proc/appear()
		if (!invisibility)
			return
		icon_state = "wendigo_appear"
		invisibility = 0
		density = 1
		spawn (12)
			if (king)
				icon_state = "wendigoking"
			else
				icon_state = "wendigo"
			playsound(loc, "sound/misc/wendigo_scream.ogg", 85, 1)
			visible_message("<span style=\"color:red\"><strong>[src]</strong> howls!</span>")
		return

	proc/disappear()
		if (invisibility)
			return

		icon_state = "wendigo_melt"
		density = 0
		spawn (12)
			invisibility = 16
			if (king)
				icon_state = "wendigoking"
			else
				icon_state = "wendigo"
		return

	proc/spaz()
		if (spazzing)
			return

		spazzing = 25
		spawn (0)
			while (spazzing-- > 0)
				pixel_x = rand(-2,2) * 2
				pixel_y = rand(-2,2) * 2
				dir = pick(alldirs)
				sleep(4)
			pixel_x = 0
			pixel_y = 0
			if (spazzing < 0)
				spazzing = 0


	// go crazy and make a huge goddamn mess
	proc/frenzy(mob/M)
		if (frenzied)
			return

		spawn (0)
			visible_message("<span style=\"color:red\"><strong>[src] goes [pick("into a frenzy", "into a bloodlust", "berserk", "hog wild", "crazy")]!</strong></span>")
			playsound(loc, "sound/misc/wendigo_maul.ogg", 80, 1)
			if (king)
				playsound(loc, "sound/misc/wendigo_roar.ogg", 80, 1)
				visible_message("<span style=\"color:red\"><strong>[src] roars!</strong></span>")
			spawn (1)
				if (!spazzing) spaz()
			set_loc(M.loc)
			frenzied = 20
			while (target && frenzied && alive && loc == M.loc )
				visible_message("<span style=\"color:red\"><strong>[src] [pick("mauls", "claws", "slashes", "tears at", "lacerates", "mangles")] [target]!</strong></span>")
				random_brute_damage(target, 10)
				take_bleeding_damage(target, null, 5, DAMAGE_CUT, 0, get_turf(target))
				if (prob(33)) // don't make quite so much mess
					bleed(target, 5, 5, get_step(loc, pick(alldirs)), 1)
				if (king && prob(33))
					bleed(target, 5, 5, get_step(loc, pick(alldirs)), 1)
				sleep(4)
				frenzied--
			frenzied = 0

////////////////
//////king wendigo, why not
///////////////

/obj/critter/wendigo/king
	name = "wendigo king"
	desc = "You should run."
	health = 500
	icon_state = "wendigoking"
	king = 1

	skinresult = /obj/item/material_piece/cloth/kingwendigohide

	New()
		..()
		quality = 200 // for the limbs

	CritterDeath()
		playsound(loc, "sound/misc/wendigo_roar.ogg", 75, 1)
		playsound(loc, "sound/misc/wendigo_cry.ogg", 75, 1)
		visible_message("<strong>[src]</strong> collapses in a heap!")
		alive = 0
		walk_to(src,0)
		icon_state = "wendigoking-dead"
		density = 0

////////////////
////// e-egg?
///////////////

/obj/item/reagent_containers/food/snacks/ingredient/egg/critter/wendigo
	name = "wendigo egg"
	desc = "They lay eggs?!"
	critter_type = /obj/critter/wendigo
	warm_count = 100
	critter_reagent = "ice"
