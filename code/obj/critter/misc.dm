/obj/critter/livingobj
	name = ""
	desc = ""
	icon_state = ""
	density = 0
	health = 10
	aggressive = 0
	defensive = 0
	wanderer = 1
	opensdoors = 0
	atkcarbon = 0
	atksilicon = 0
	generic = 0
	butcherable = 1 //Because "toolbox meat" would be hilarious
	var/atck_dmg = 0
	var/stunprob = 0
	layer = 5
	var/obj/original_object = null

	CritterAttack(var/mob/M)
		attacking = 1
		visible_message("<span class='combat'><strong>[src]</strong> slams into [target]!</span>")
		random_brute_damage(target, atck_dmg)
		spawn (25)
			attacking = 0

	attack_hand(mob/user as mob)
		if (alive && (user.a_intent != INTENT_HARM))
			visible_message("<span class='combat'><strong>[user]</strong> pets [src]!</span>")
			return
		..()

	CritterDeath()
		visible_message("<strong>[src]</strong> stops moving!")
		animate_float(src, 1, 5)
		spawn (100) //Give time for people to butcher it if they want.
			if (!disposed && loc && original_object)
				original_object.loc = loc
				original_object = null
				qdel(src)
		return ..()

	ChaseAttack(mob/M)
		visible_message("<span class='combat'><strong>[src]</strong> leaps at [target]!</span>")
		if (prob(stunprob))
			M.weakened += 2
		//playsound(loc, "sound/weapons/genhit1.ogg", 50, 1, -1)

	disposing()
		if (original_object)
			original_object.dispose()
			original_object = null
		..()


/obj/critter/spore
	name = "plasma spore"
	desc = "A barely intelligent colony of organisms. Very volatile."
	icon_state = "spore"
	density = 1
	health = 1
	aggressive = 0
	defensive = 0
	wanderer = 1
	opensdoors = 0
	atkcarbon = 0
	atksilicon = 0
	firevuln = 2
	brutevuln = 2
	flying = 1

	CritterDeath()
		visible_message("<strong>[src]</strong> ruptures and explodes!")
		alive = 0
		var/turf/T = get_turf(loc)
		if (T)
			T.hotspot_expose(700,125)
			explosion(src, T, -1, -1, 2, 3)
		qdel (src)

	ex_act(severity)
		CritterDeath()

	bullet_act(flag, A as obj)
		CritterDeath()

/obj/critter/mimic
	name = "mechanical toolbox"
	desc = null
	icon_state = "mimic_blue1"
	health = 20
	aggressive = 1
	defensive = 1
	wanderer = 0
	atkcarbon = 1
	atksilicon = 1
	brutevuln = 0.5
	seekrange = 1
	angertext = "suddenly comes to life and lunges at"
	death_text = "%src% flops closed, dead!"
	var/toolbox_style = "blue"
	var/list/toolbox_list = list("blue", "red", "yellow", "green")
	var/switcharoo = 10 // set to 0 for mimics that always are mimics and never toolboxes

	New()
		..()
		toolbox_style = pick(toolbox_list)
		update_icon()
		if (prob(switcharoo))
			switch (toolbox_style)
				if ("blue")
					new /obj/item/storage/toolbox/mechanical(loc)
				if ("red")
					new /obj/item/storage/toolbox/emergency(loc)
				if ("yellow")
					new /obj/item/storage/toolbox/electrical(loc)
				if ("green")
					if (prob(1))
						new /obj/item/storage/toolbox/memetic(loc)
					else
						new /obj/item/storage/toolbox/artistic(loc)
			qdel(src)

	ai_think()
		..()
		if (alive)
			switch (task)
				if ("thinking")
					update_icon()
				if ("chasing")
					update_icon()
				if ("attacking")
					update_icon()

	ChaseAttack(mob/M)
		visible_message("<span class='combat'><strong>[src]</strong> hurls itself at [M]!</span>")
		if (prob(33)) M.weakened += rand(3,6)

	CritterAttack(mob/M)
		attacking = 1
		visible_message("<span class='combat'><strong>[src]</strong> bites [target]!</span>")
		random_brute_damage(target, rand(2,4))
		spawn (25)
			attacking = 0

	proc/update_icon()
		if (!toolbox_style)
			toolbox_style = pick(toolbox_list)
			dead_state = "mimic_[toolbox_style]1-dead"
		switch (task)

			if ("thinking")
				icon_state = "mimic_[toolbox_style]1"

				if (toolbox_style == "blue")
					name = "mechanical toolbox"
					desc = "A metal container designed to hold various tools. This variety holds standard construction tools."

				if (toolbox_style == "red")
					name = "emergency toolbox"
					desc = "A metal container designed to hold various tools. This variety holds supplies required for emergencies."

				if (toolbox_style == "yellow")
					name = "electrical toolbox"
					desc = "A metal container designed to hold various tools. This variety holds electrical supplies."

				if (toolbox_style == "green")
					name = "artistic toolbox"
					desc = "It almost hurts to look at that, it's all out of focus."

			if ("chasing")
				icon_state = "mimic_[toolbox_style]2"
				name = "mimic"
				desc = "Oh shit, that's no toolbox at all!"

			if ("attacking")
				icon_state = "mimic_[toolbox_style]2"
				name = "mimic"
				desc = "Oh shit, that's no toolbox at all!"
/*
/obj/critter/mimic_old
	name = "mechanical toolbox"
	desc = null
	icon_state = "mimic1"
	health = 20
	aggressive = 1
	defensive = 1
	wanderer = 0
	atkcarbon = 1
	atksilicon = 1
	brutevuln = 0.5
	seekrange = 1
	angertext = "suddenly comes to life and lunges at"
	death_text = "%src% crumbles to pieces!"

	ai_think()
		..()
		if (alive)
			switch(task)
				if ("thinking")
					icon_state = "mimic1"
					name = "mechanical toolbox"
				if ("chasing")
					icon_state = "mimic2"
					name = "mimic"
				if ("attacking")
					icon_state = "mimic2"
					name = "mimic"

	ChaseAttack(mob/M)
		visible_message("<span class='combat'><strong>[src]</strong> hurls itself at [M]!</span>")
		if (prob(33)) M.weakened += rand(3,6)

	CritterAttack(mob/M)
		attacking = 1
		visible_message("<span class='combat'><strong>[src]</strong> bites [target]!</span>")
		random_brute_damage(target, rand(2,4))
		spawn (25)
			attacking = 0
*/
/obj/critter/wraithskeleton
	name = "skeleton"
	desc = "It looks rather crumbly."
	icon = 'icons/mob/human_decomp.dmi'
	icon_state = "decomp4"
	health = 1
	aggressive = 1
	defensive = 1
	wanderer = 1
	atkcarbon = 1
	atksilicon = 1
	brutevuln = 1
	seekrange = 7

	skinresult = /obj/item/material_piece/bone
	max_skins = 2
	death_text = "%src% vaporizes instantly!"

	ChaseAttack(mob/M)
		if (prob(75))
			visible_message("<span class='combat'><strong>[src]</strong> knocks down [M]!</span>")
			M.weakened += rand(3,6)
		else
			visible_message("<span class='combat'><strong>[src]</strong> tries to knock down [M]!</span>")

	CritterAttack(mob/M)
		attacking = 1
		visible_message("<span class='combat'><strong>[src]</strong> beats [target]!</span>")
		random_brute_damage(target, rand(3,8))
		spawn (25)
			attacking = 0

	CritterDeath()
		..()
		particleMaster.SpawnSystem(new /particleSystem/localSmoke("#000000", 5, locate(x, y, z)))
		qdel(src)

/obj/critter/mimic2
	name = "mechanical toolbox"
	desc = null
	icon_state = "mimic1"
	health = 20
	aggressive = 1
	defensive = 1
	wanderer = 0
	atkcarbon = 1
	atksilicon = 1
	brutevuln = 0.5
	seekrange = 1
	angertext = "suddenly comes to life and lunges at"
	var/objname = "mechanical toolbox" //name when in disguise
	generic = 0
	death_text = "%src% crumbles to pieces!"

	ai_think()
		..()
		if (alive)
			switch(task)
				if ("thinking")
					overlays = null
					name = objname
				if ("chasing")
					overlays += image("icon" = 'icons/misc/critter.dmi', "icon_state" = "mimicface", "layer" = FLOAT_LAYER)
					name = "mimic"
				if ("attacking")
					overlays += image("icon" = 'icons/misc/critter.dmi', "icon_state" = "mimicface", "layer" = FLOAT_LAYER)
					name = "mimic"

	ChaseAttack(mob/M)
		visible_message("<span class='combat'><strong>[src]</strong> hurls itself at [M]!</span>")
		if (prob(33)) M.weakened += rand(3,6)

	CritterAttack(mob/M)
		attacking = 1
		visible_message("<span class='combat'><strong>[src]</strong> bites [target]!</span>")
		random_brute_damage(target, rand(2,4))
		spawn (25)
			attacking = 0

/obj/critter/spirit
	name = "spirit"
	desc = null
	invisibility = 10
	icon_state = "spirit"
	health = 10
	aggressive = 1
	defensive = 1
	wanderer = 0
	atkcarbon = 1
	atksilicon = 1
	brutevuln = 0.5
	opensdoors = 1
	seekrange = 5
	density = 0
	angertext = "suddenly materializes and lunges at"
	flying = 1
	generic = 0
	death_text = "%src% dissipates!"

	ai_think()
		..()
		if (alive)
			switch(task)
				if ("thinking")
					invisibility = 10
				if ("chasing")
					invisibility = 0
				if ("attacking")
					invisibility = 0

	seek_target()
		anchored = 0
		for (var/mob/living/C in hearers(seekrange,src))
			if (target)
				task = "chasing"
				break
			if ((C.name == oldtarget_name) && (world.time < last_found + 100)) continue
			if (iscarbon(C) && !atkcarbon) continue
			if (istype(C, /mob/living/silicon) && !atksilicon) continue
			if (C.health < 0) continue
			if (C in friends) continue
			if (isvampire(C)) continue
			if (C.name == attacker) attack = 1
			if (iscarbon(C) && atkcarbon) attack = 1
			if (istype(C, /mob/living/silicon) && atksilicon) attack = 1

			if (attack)
				target = C
				oldtarget_name = C.name
				visible_message("<span class='combat'><strong>[src]</strong> [angertext] [C.name]!</span>")
				task = "chasing"
				break
			else
				continue

	ChaseAttack(mob/M)
		visible_message("<span class='combat'><strong>[src]</strong> hurls itself at [M]!</span>")
		if (prob(30)) M.weakened += rand(2,4)

	CritterAttack(mob/M)
		attacking = 1
		visible_message("<span class='combat'><strong>[src]</strong> attacks [target]!</span>")
		random_brute_damage(target, rand(2,4))
		spawn (25)
			attacking = 0

	CritterDeath()
		if (!alive)
			return
		..()
		new /obj/item/reagent_containers/food/snacks/ectoplasm(loc)
		qdel(src)

	bullet_act(var/obj/projectile/P)
		if (istype(P, /projectile/energy_bolt_antighost))
			CritterDeath()
			return
		else
			..()

	CanPass(atom/movable/mover, turf/target, height=0, air_group=0)
		if (istype(mover, /obj/projectile))
			var/obj/projectile/proj = mover
			if (istype(proj.proj_data, /projectile/energy_bolt_antighost))
				return FALSE

		return TRUE

/obj/critter/spacebee
	name = "space wasp"
	desc = "A wasp in space."
	icon_state = "spacebee"
	density = 1
	health = 10
	aggressive = 1
	defensive = 1
	wanderer = 1
	opensdoors = 0
	atkcarbon = 1
	atksilicon = 1
	firevuln = 1
	brutevuln = 1
	angertext = "buzzes at"
	butcherable = 1
	flags = NOSPLASH | OPENCONTAINER
	flying = 1
	//var/neurotoxin = 2

	CritterDeath()
		..()
		reagents.add_reagent("toxin", 50, null)
		reagents.add_reagent("histamine", 50, null)
		return

	seek_target()
		anchored = 0
		for (var/mob/living/C in hearers(seekrange,src))
			if ((C.name == oldtarget_name) && (world.time < last_found + 100)) continue
			if (iscarbon(C) && !atkcarbon) continue
			if (istype(C, /mob/living/silicon) && !atksilicon) continue
			if (C.job == "Botanist") continue
			if (C.health < 0) continue
			if (C in friends) continue
			if (iscarbon(C) && atkcarbon) attack = 1
			if (istype(C, /mob/living/silicon) && atksilicon) attack = 1

			if (attack)
				target = C
				oldtarget_name = C.name
				visible_message("<span class='combat'><strong>[src]</strong> charges at [C.name]!</span>")
				task = "chasing"
				break
			else
				continue

	ChaseAttack(mob/M)
		if (!M) return
		visible_message("<span class='combat'><strong>[src]</strong> stings [M]!</span>")
		if (M.reagents)
			M.reagents.add_reagent("histamine", 12)
			M.reagents.add_reagent("toxin", 2)

/obj/item/reagent_containers/food/snacks/ingredient/egg/critter/wasp
	name = "space wasp egg"
	critter_type = /obj/critter/spacebee

/obj/critter/magiczombie
	name = "skeleton"
	desc = "Clak clak, motherfucker."
	icon_state = "skeleton"
	dead_state = "skeleton-dead"
	density = 1
	health = 20 // too strong
	aggressive = 1
	defensive = 0
	wanderer = 1
	opensdoors = 1
	atkcarbon = 1
	atksilicon = 1
	atcritter = 1
	firevuln = 0.25
	brutevuln = 0.5
	var/pixel_y_inc = 0
	skinresult = /obj/item/material_piece/bone
	max_skins = 2

	New()
		..()
		playsound(loc, "sound/items/Scissor.ogg", 50, 0)

	Move()
		playsound(loc, "sound/effects/crystalhit.ogg", 50, 0)
		..()

	attackby(obj/item/W as obj, mob/living/user as mob)

		..()
		if (!alive) return
		if (istype(W, /obj/item/clothing/head))
			if (pixel_y_inc > 20) return
			var/image/I = image('icons/mob/head.dmi', src,  W.icon_state)
			I.pixel_y = pixel_y_inc
			overlays += I
			pixel_y_inc += 3

	seek_target()

		if (!alive) return
		var/mob/living/Cc
		for (var/mob/living/C in hearers(seekrange,src))
			if (iswizard(C))  continue //do not attack our master
			if ((C.name == oldtarget_name) && (world.time < last_found + 100)) continue
			if (iscarbon(C) && !atkcarbon) continue
			if (istype(C, /mob/living/silicon) && !atksilicon) continue
			if (C.stat == 2) continue
			if (iscarbon(C) && atkcarbon) attack = 1
			if (istype(C, /mob/living/silicon) && atksilicon) attack = 1
			Cc = C

		if (attack)
			target = Cc
			oldtarget_name = Cc.name
			visible_message("<span class='combat'><strong>[src]</strong> charges towards [Cc.name]!</span>")
			playsound(loc, "sound/items/Scissor.ogg", 50, 0)
			task = "chasing"
			return

	proc/CustomizeMagZom(var/NM)
		..()

		name = "[capitalize(NM)]'s skeleton"
		desc = "A horrible skeleton, raised from the corpse of [NM] by a wizard."
		return

	ChaseAttack(mob/M)
		if (!alive) return
		M.visible_message("<span class='combat'><strong>[src]</strong> bashes [target]!</span>")
		playsound(M.loc, "punch", 25, 1, -1)
		random_brute_damage(M, rand(5,10))
		if (prob(15)) // too mean before
			M.visible_message("<span class='combat'><strong>[M]</strong> staggers!</span>")
			M.stunned += rand(0,4)
			M.weakened += rand(1,4)

	CritterAttack(mob/M)
		if (!alive) return
		attacking = 1
		if (!M.stat)
			M.visible_message("<span class='combat'><strong>[src]</strong> pummels [target] mercilessly!</span>")
			playsound(loc, "sound/weapons/genhit1.ogg", 50, 1, -1)
			if (prob(10)) // lowered probability slightly
				M.visible_message("<span class='combat'><strong>[M]</strong> staggers!</span>")
				M.stunned += rand(0,2)
				M.weakened += rand(1,2)
			random_brute_damage(M, rand(5,10))
		else
			M.visible_message("<span class='combat'><strong>[src]</strong> hits [target] with a bone!</span>")
			playsound(loc, "punch", 30, 1, -2)
			random_brute_damage(M, rand(10,15))

		spawn (10)
			attacking = 0

/obj/item/reagent_containers/food/snacks/ingredient/egg/critter/skeleton
	name = "skeleton egg"
	desc = "Uh. What?"
	critter_type = /obj/critter/magiczombie
	warm_count = 5
	critter_reagent = "ash"

/obj/critter/golem
	name = "Golem"
	desc = "An elemental being, crafted by local artisans using traditional techniques."
	icon_state = "golem"
	density = 1
	health = 25
	aggressive = 1
	defensive = 0
	wanderer = 1
	opensdoors = 1
	atkcarbon = 1
	atksilicon = 1
	atcritter = 0 // don't bother!
	firevuln = 0.25
	brutevuln = 0.5
	generic = 0
	var/reagent_id = null

	New()
		..()

		var/reagents/R = new/reagents(1000)
		reagents = R
		R.my_atom = src

		spawn (40)
			if (!reagents.total_volume)
				if (all_functional_reagent_ids.len > 0)
					reagent_id = pick(all_functional_reagent_ids)
				else
					reagent_id = "water"

				R.add_reagent(reagent_id, 10)

				var/oldcolor = reagents.get_master_color()
				var/icon/I = new /icon('icons/misc/critter.dmi',"golem")
				I.Blend(oldcolor, ICON_ADD)
				icon = I
				name = "[capitalize(reagents.get_master_reagent_name())]-Golem"

		return

	seek_target()
		anchored = 0
		var/mob/living/Cc
		for (var/mob/living/C in hearers(seekrange,src))
			if (C.ckey == null) continue //do not attack non-threats ie. NPC monkeys and AFK players
			if (iswizard(C)) continue //do not attack our master
			if ((C.name == oldtarget_name) && (world.time < last_found + 100)) continue
			if (iscarbon(C) && !atkcarbon) continue
			if (istype(C, /mob/living/silicon) && !atksilicon) continue
			if (C.stat == 2) continue
			if (iscarbon(C) && atkcarbon) attack = 1
			if (istype(C, /mob/living/silicon) && atksilicon) attack = 1
			Cc = C

		if (attack)
			target = Cc
			oldtarget_name = Cc.name
			visible_message("<span class='combat'><strong>[src]</strong> charges at [Cc.name]!</span>")
			task = "chasing"
			return


	proc/CustomizeGolem(var/reagents/CR) //customise it with the reagents in a container
		..() // ???

		for (var/current_id in CR.reagent_list)
			var/reagent/R = CR.reagent_list[current_id]
			reagents.add_reagent(current_id, min(R.volume * 5, 50))

		var/oldcolor = reagents.get_master_color()
		var/icon/I = new /icon('icons/misc/critter.dmi',"golem")
		I.Blend(oldcolor, ICON_ADD)
		icon = I
		name = "[capitalize(reagents.get_master_reagent_name())]-Golem"
		desc = "An elemental entity composed of [reagents.get_master_reagent_name()], conjured by a wizard."
		return

	CritterAttack(mob/M)
		attacking = 1
		M.visible_message("<span class='combat'><strong>[src]</strong> bashes against [target]!</span>")
		playsound(loc, "sound/weapons/genhit1.ogg", 50, 1, -1)
		random_brute_damage(M, rand(5,10))
		if (M.reagents)
			if (reagents && reagents.total_volume)

				reagents.reaction(M, TOUCH)
				reagents.trans_to(M, 5)
		spawn (10)
			attacking = 0

	CritterDeath()
		if (!alive) return
		..()

		visible_message("<span class='combat'><strong>[src]</strong> bursts into a puff of smoke!</span>")
		var/chemical_reaction/smoke/thesmoke = new
		thesmoke.on_reaction(reagents, 12)
		invisibility = 100
		spawn (50)
			qdel(src)

/obj/critter/townguard
	name = "Town Guard"
	desc = "An angry man dressed in medieval armor."
	icon_state = "townguard"
	density = 1
	health = 100
	aggressive = 1
	defensive = 0
	wanderer = 1
	opensdoors = 1
	atkcarbon = 1
	atksilicon = 1
	atcritter = 1
	firevuln = 0.75
	brutevuln = 0.5
	death_text = "%src% seizes up and falls limp, his eyes dead and lifeless..."

	var/sword_damage_max = 12
	var/sword_damage_min = 6


	seek_target()
		anchored = 0
		for (var/mob/living/C in hearers(seekrange,src))
			if ((C.name == oldtarget_name) && (world.time < last_found + 100)) continue
			if (iscarbon(C) && !atkcarbon) continue
			if (istype(C, /mob/living/silicon) && !atksilicon) continue
			if (C.health < 0) continue
			if (iscarbon(C) && atkcarbon) attack = 1
			if (istype(C, /mob/living/silicon) && atksilicon) attack = 1

			if (attack)
				target = C
				oldtarget_name = C.name
				visible_message("<span class='combat'><strong>[src]</strong> points at [C.name]!</span>")
				for (var/mob/O in hearers(src, null))
					O.show_message("<strong>[src]</strong> says, \"HALT!\"", 2)
				playsound(loc, "sound/voice/guard_halt.ogg", 50, 0)
				task = "chasing"
				return
			else
				continue


		if (!atcritter) return
		for (var/obj/critter/C in view(seekrange,src))
			if (!C.alive) continue
			if (C.health < 0) continue
			if (!istype(C, /obj/critter/townguard)) attack = 1

			if (attack)
				target = C
				oldtarget_name = C.name
				visible_message("<span class='combat'><strong>[src]</strong> points at [C.name]!</span>")
				for (var/mob/O in hearers(src, null))
					O.show_message("<strong>[src]</strong> says, \"HALT!\"", 2)
				playsound(loc, "sound/voice/guard_halt.ogg", 50, 0)
				task = "chasing"
				return

			else continue



	ChaseAttack(mob/M)
		if (iscarbon(M) && prob(15))
			visible_message("<span class='combat'><strong>[src]</strong> tackles [target]!</span>")
			playsound(loc, "sound/weapons/thudswoosh.ogg", 50, 1, -1)
			random_brute_damage(M, rand(0,3))
			M.stunned += rand(0,4)
			M.weakened += rand(1,4)
		else
			visible_message("<span class='combat'><strong>[src]</strong> tries to knock down [target] but misses!</span>", 1)

	CritterAttack(mob/M)
		for (var/mob/O in viewers(src, null))
			O.show_message("<strong>[src]</strong> says, \"HALT!\"", 2)
		playsound(loc, "sound/voice/guard_halt.ogg", 50, 0)
		attacking = 1
		if (istype(M,/obj/critter))
			var/obj/critter/C = M
			for (var/mob/O in hearers(src, null))
				O.show_message("<strong>[src]</strong> says, \"HALT!\"", 2)
			playsound(C.loc, "swing_hit", 50, 1, -1)
			C.health -= 6
			if (C.health <= 0)
				C.CritterDeath()
			spawn (25)
				attacking = 0
			return

		if (M.health > 40 && !M.weakened)
			visible_message("<span class='combat'><strong>[src]</strong> attacks [target] with his sword!</span>")
			playsound(M.loc, "swing_hit", 50, 1, -1)

			var/to_deal = rand(sword_damage_min,sword_damage_max)
			random_brute_damage(M, to_deal)
			if (iscarbon(M))
				if (to_deal > (((sword_damage_max-sword_damage_min)/2)+sword_damage_min) && prob(50))
					visible_message("<span class='combat'><strong>[src] knocks down [M]!</strong></span>")
					M:weakened += 8
			spawn (25)
				attacking = 0
		else
			visible_message("<span class='combat'><strong>[src]</strong> kicks [target]!</span>")
			playsound(loc, "swing_hit", 50, 1, -1)
			random_brute_damage(target, rand(4,8))
			spawn (25)
				attacking = 0
				return

	ai_think()
		if (prob(20))
			if (target)
				for (var/mob/O in viewers(src, null))
					O.show_message("<strong>[src]</strong> says, \"HALT!\"", 2)
				playsound(loc, "sound/voice/guard_halt.ogg", 50, 0)
		return ..()

/obj/item/reagent_containers/food/snacks/ingredient/egg/critter/townguard
	name = "\improper Town Guard egg"
	desc = "This is not how humans reproduce. They do not lay eggs. <em>What the hell is this?</em>"
	critter_type = /obj/critter/townguard
	warm_count = 75

/obj/critter/bloodling
	name = "Bloodling"
	desc = "A force of pure sorrow and evil."
	icon_state = "bling"
	density = 1
	health = 20
	aggressive = 1
	defensive = 0
	wanderer = 1
	opensdoors = 1
	atkcarbon = 1
	atksilicon = 0
	atcritter = 0
	firevuln = 0
	brutevuln = 0
	seekrange = 7
	invisibility = 1
	flying = 1

	generic = 0

	seek_target()
		anchored = 0
		for (var/mob/living/C in hearers(seekrange,src))
			if ((C.name == oldtarget_name) && (world.time < last_found + 100)) continue
			if (iscarbon(C) && !atkcarbon) continue
			if (istype(C, /mob/living/silicon) && !atksilicon) continue
			if (C.health < 0) continue
			if (iscarbon(C) && atkcarbon) attack = 1
			if (istype(C, /mob/living/silicon) && atksilicon) attack = 1

			if (attack)
				target = C
				oldtarget_name = C.name
				task = "chasing"
				return
			else
				continue


	ChaseAttack(mob/M)
		attacking = 1
		if (narrator_mode)
			playsound(loc, 'sound/vox/ghost.ogg', 50, 1, -1)
		else
			playsound(loc, 'sound/effects/ghost.ogg', 50, 1, -1)
		if (iscarbon(M) && prob(50))
			if (M.see_invisible < 2)
				boutput(M, "<span class='combat'><strong>You are forced to the ground by an unseen being!</strong></span>")
			else
				boutput(M, "<span class='combat'><strong>You are forced to the ground by the Bloodling!</strong></span>")
			random_brute_damage(M, rand(0,3))
			M.stunned += rand(0,4)
			M.weakened += rand(1,4)
			attacking = 0
			return


	CritterAttack(mob/M)
		playsound(loc, "sound/effects/ghost2.ogg", 50, 1, -1)
		attacking = 1
		if (iscarbon(M))
			if (prob(50))
				random_brute_damage(M, rand(5,10))
				boutput(M, "<span class='combat'><strong>You feel blood getting drawn out through your skin!</strong></span>")
			else
				boutput(M, "<span class='combat'>You feel uncomfortable.</span>")

		spawn (5)
			attacking = 0


	attackby(obj/item/W as obj, mob/living/user as mob)
		if (!alive)
			return
		else
			if (!W.reagents)
				boutput(user, "<span class='combat'>Hitting it with [W] is ineffective!</span>")
				return
			if (W.reagents.has_reagent("water_holy"))
				boutput(user, "[src] screams!")
				CritterDeath()
				return
			else
				boutput(user, "<span class='combat'>Hitting it with [W] is ineffective!</span>")
				return

	ai_think()
		if (!locate(/obj/decal/cleanable/blood) in loc)
			playsound(loc, "sound/effects/splat.ogg", 50, 1, -1)
			new /obj/decal/cleanable/blood(loc)
		return ..()

/obj/critter/blobman
	name = "mutant"
	desc = "Some sort of horrific, pulsating blob of flesh."
	icon_state = "blobman"
	density = 1
	health = 15
	aggressive = 1
	defensive = 0
	wanderer = 1
	opensdoors = 1
	atkcarbon = 1
	atksilicon = 1
	atcritter = 1
	firevuln = 0.75
	brutevuln = 0.5
	death_text = "%src% collapses into viscera."

	CritterAttack(mob/M)
		attacking = 1
		M.visible_message("<span class='combat'><strong>[src]</strong> flails against [target]!</span>")
		playsound(loc, "sound/weapons/genhit1.ogg", 50, 1, -1)
		random_brute_damage(M, rand(4,8))

		spawn (10)
			attacking = 0

	ChaseAttack(mob/M)
		visible_message("<span class='combat'><strong>[src]</strong> headbutts [M]!</span>")
		if (iscarbon(M))
			if (prob(5)) M.stunned += rand(1,5)
			random_brute_damage(M, rand(2,5))

//A terrible post-human cloud of murder.
/obj/critter/aberration
	name = "transposed particle field"
	desc = "A cloud of particles transposed by some manner of dangerous science, echoing some mannerisms of their previous configuration. In layman's terms, a goddamned science ghost."
	icon_state = "aberration"
	density = 0
	health = 2
	aggressive = 1
	defensive = 1
	wanderer = 1
	opensdoors = 1
	atkcarbon = 1
	atksilicon = 1
	atcritter = 1
	firevuln = 0.01
	brutevuln = 0.25
	flying = 1
	generic = 0
	death_text = "%src% dissipates!"

	CritterDeath()
		..()
		qdel(src)

	CritterAttack(mob/M)
		attacking = 1
		visible_message("<span class='combat'><strong>The [name]</strong> starts to envelop [M]!</span>")

		var/lastloc = M.loc
		spawn (60)
			if (get_dist(src, M) <= 1 && ((M.loc == lastloc)))
				if (istype(M, /mob/living))
					logTheThing("combat", M, null, "was enveloped by [src] at [log_loc(src)].") // Some logging for instakill critters would be nice (Convair880).
					M.ghostize()

					if (iscarbon(M))
						for (var/obj/item/W in M)
							if (istype(W,/obj/item))
								M.u_equip(W)
								if (W)
									W.set_loc(M.loc)
									W.dropped(M)
									W.layer = initial(W.layer)

				visible_message("<span class='combat'><strong>The [name]</strong> completely envelops [M]!</span>")
				playsound(loc, "sound/effects/blobattack.ogg", 50, 1)
				qdel(M)

			attacking = 0

	attack_hand(var/mob/user as mob)
		if (alive)
			boutput(user, "<span class='combat'><strong>Your hand passes right through! It's so cold...</strong></span>")

		return

	attackby(obj/item/W as obj, mob/living/user as mob)
		if (!alive)
			return
		else
			if (istype(W, /obj/item/baton))
				var/obj/item/baton/B = W
				if (B.can_stun(1, 1, user) == 1)
					user.visible_message("<span class='combat'><strong>[user] shocks the [name] with [B]!</strong></span>", "<span class='combat'><strong>While your baton passes through, the [name] appears damaged!</strong></span>")
					B.process_charges(-1, user)
					health--

					if (health <= 0)
						CritterDeath()
					return

			boutput(user, "<span class='combat'><strong>[W] passes right through!</strong></span>")
			return

	seek_target()
		anchored = 0
		for (var/mob/living/C in range(seekrange,src))
			if ((C.name == oldtarget_name) && (world.time < last_found + 100)) continue
			if (iscarbon(C) && !atkcarbon) continue
			if (istype(C, /mob/living/silicon) && !atksilicon) continue
			if (ishuman(C) && istype(C:head, /obj/item/clothing/head/void_crown)) continue
			if (C.health < 0) continue
			if (iscarbon(C) && atkcarbon) attack = 1
			if (istype(C, /mob/living/silicon) && atksilicon) attack = 1

			if (attack)
				target = C
				oldtarget_name = C.name
				task = "chasing"
				return
			else
				continue

	bullet_act(var/obj/projectile/P)
		var/damage = 0
		damage = round((P.power*(1-P.proj_data.ks_ratio)), 1.0)

		if (P.proj_data.damage_type == D_ENERGY)
			health -= damage
		else
			return

		if (health <= 0)
			CritterDeath()

	ChaseAttack(mob/M)
		return

/obj/critter/ancient_thing
	name = "???"
	desc = "What the hell is that?"
	icon_state = "ancientrobot"
	invisibility = 10
	health = 30
	firevuln = 0
	brutevuln = 0.5
	aggressive = 1
	defensive = 1
	wanderer = 0
	opensdoors = 1
	seekrange = 5
	density = 1
	var/boredom_countdown = 0

	CritterDeath()
		visible_message("<strong>[src]</strong> fades away.")
		alive = 0
		walk_to(src,0)
		flick("ancientrobot-disappear",src)
		invisibility = 10
		critters -= src
		dispose()

	seek_target()
		anchored = 0
		if (target)
			task = "chasing"
			return

		for (var/mob/living/carbon/C in view(seekrange,src))
			if ((C.name == oldtarget_name) && (world.time < last_found + 100)) continue
			if (C.stat || C.health < 0) continue

			boredom_countdown = rand(5,10)
			target = C
			oldtarget_name = C.name
			task = "chasing"
			appear()
			break

	attackby(obj/item/W as obj, mob/living/user as mob)

		if (!alive)
			..()
			return
		switch(W.damtype)
			if ("fire")
				health -= W.force * firevuln
			if ("brute")
				health -= W.force * brutevuln

		if (alive && health <= 0) CritterDeath()

		boredom_countdown = rand(5,10)
		target = user
		oldtarget_name = user.name
		task = "chasing"

	attack_hand(var/mob/user as mob)

		if (!alive)
			..()
			return
		if (user.a_intent == "harm")
			health -= rand(1,2) * brutevuln
			for (var/mob/O in viewers(src, null))
				O.show_message("<span class='combat'><strong>[user]</strong> punches [src]!</span>", 1)
			playsound(loc, "punch", 50, 1)
			if (alive && health <= 0) CritterDeath()

			boredom_countdown = rand(5,10)
			target = user
			oldtarget_name = user.name
			task = "chasing"
		else
			visible_message("<span class='combat'><strong>[user]</strong> pets [src]!<br>For some reason! Not like that's weird or anything!</span>", 1)


	ChaseAttack(mob/M)
		return

	CritterAttack(mob/M)
		attacking = 1

		if (boredom_countdown-- > 0)
			visible_message("<span class='combat'><strong>[src]</strong> [pick("measures", "gently pulls at", "examines", "pokes", "gently prods", "feels")] [target]'s [pick("head","neck","shoulders","right arm", "left arm","left leg","right leg")]!</span>")
			if (prob(50))
				boutput(target, "<span class='combat'>You feel [pick("very ",null,"rather ","fairly ","remarkably ")]uncomfortable.</span>")
		else
			var/mob/living/doomedMob = target
			if (!istype(doomedMob))
				return

			visible_message("<span class='combat'><strong>In a whirling flurry of tendrils, [src] rends down [target]! Holy shit!</strong></span>")
			logTheThing("combat", M, null, "was gibbed by [src] at [log_loc(src)].") // Some logging for instakill critters would be nice (Convair880).
			playsound(loc, "sound/effects/fleshbr1.ogg", 50, 1)
			doomedMob.ghostize()
			new /obj/decal/skeleton(doomedMob.loc)
			doomedMob.gib()
			target = null

		spawn (40)
			attacking = 0

	proc/appear()
		if (!invisibility || (icon_state != "ancientrobot"))
			return
		name = pick("something","weird thing","odd thing","whatchamacallit","thing","something weird","old thing")
		icon_state = "ancientrobot-appear"
		invisibility = 0
		spawn (12)
			icon_state = "ancientrobot"
		return

/obj/critter/crunched
	name = "transposed scientist"
	desc = "A fellow who seems to have been shunted between dimensions. Not a good state to be in."
	icon_state = "crunched"
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
			speak( pick("No! Get up! Please, get up!", "Not again! Not again! I need you!", "Please! Please get up! Please!", "I don't want to be alone again!") )
			visible_message("<span style=\"color:blue\">[src] shakes [M] trying to wake them up!</span>")
			boutput(M, "<span class='combat'><strong>It burns!</strong></span>")
			M.TakeDamage("chest", 0, rand(5,15))
		else
			src.speak( pick("Please! Help! I need help!", "Please...help me!", "Are you real? You're real! YOU'RE REAL", "Everything hurts! Everything hurts!", "Please, make the pain stop! MAKE IT STOP!") )
			visible_message("<span class='combat'><strong>[src]</strong> grabs at [M]'s arm!</span>")
			boutput(M, "<span class='combat'><strong>It burns!</strong></span>")
			M.TakeDamage("chest", 0, rand(5,15))

		spawn (60)
			attacking = 0

	ai_think()
		if (task == "thinking" || task == "wandering")
			if (prob(5))
				speak( pick("Cut the power! It's about to go critical, cut the power!","I warned them. I warned them the system wasn't ready.","Shut it down!","It hurts, oh God, oh God.") )
		else
			if (prob(5))
				src.speak( pick("Please...help...it hurts...please", "I'm...sick...help","It went wrong.  It all went wrong.","I didn't mean for this to happen!", "I see everything twice!") )

		return ..()

	CritterDeath()
		speak( pick("There...is...nothing...","It's dark.  Oh god, oh god, it's dark.","Thank you.","Oh wow. Oh wow. Oh wow.") )
		icon_state = "crunched-dead"
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
			src.speak( pick("Hey..you! Help! Help me please!","I need..a doctor...","Someone...new? Help me...please.","Are you real?") )
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

		visible_message("<strong>[name]</strong> says, \"[processedMessage]\"")
		return
