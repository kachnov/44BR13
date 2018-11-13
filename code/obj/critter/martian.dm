/obj/item/clothing/head/tinfoil_hat
	name = "tinfoil hat"
	desc = "Protects the wearer from mindcontrol and, apparently, weak martian psychic blasts which do not involve the liquification of brains."
	icon_state = "tinfoil"
	item_state = "tinfoil"

/obj/critter/martian
	name = "martian"
	desc = "Genocidal monsters from Mars."
	icon_state = "martian"
	density = 1
	health = 20
	aggressive = 0
	defensive = 1
	wanderer = 1
	opensdoors = 1
	atkcarbon = 1
	atksilicon = 1
	firevuln = 1.5
	brutevuln = 1
	butcherable = 1
	flying = 1

	on_damaged(mob/user)
		if (alive && defensive && prob(10))
			MartianPsyblast(user)
			if (!(src in gauntlet_controller.gauntlet))
				visible_message("<span style=\"color:red\"><strong>[src]</strong> teleports away!</span>")
				CritterTeleport(8, 1, 0)

	on_pet()
		for (var/mob/O in hearers(src, null))
			O.show_message("<strong>[src]</strong> screeches, 'KXBQUB IJFDQVW??'", 1)


	proc/MartianPsyblast(mob/target as mob)
		for (var/mob/O in hearers(src, null))
			O.show_message("<strong>[src]</strong> screeches, 'GBVQW UVQWIBJZ PKDDR!!!'", 1)
		if (!ishuman(target))
			return
		playsound(target.loc, "sound/effects/ghost2.ogg", 100, 1)
		var/mob/living/carbon/human/H = target
		if (istype(H.head, /obj/item/clothing/head/tinfoil_hat))
			boutput(H, "<span style=\"color:blue\">Your tinfoil hat protects you from the psyblast!</span>")
		else
			boutput(H, "<span style=\"color:red\">You are blasted by psychic energy!</span>")
			H.paralysis += 5
			H.stuttering += 60
			H.take_brain_damage(20)
			H.TakeDamage("head", 0, 5)

	proc/CritterTeleport(var/telerange, var/dospark, var/dosmoke)
		if (!alive) return
		var/list/randomturfs = new/list()
		for (var/turf/T in orange(src, telerange))
			if (istype(T, /turf/space) || T.density) continue
			randomturfs.Add(T)
		set_loc(pick(randomturfs))
		if (dospark)
			spawn ()
				var/effects/system/spark_spread/s = unpool(/effects/system/spark_spread)
				s.set_up(5, 1, src)
				s.start()
		if (dosmoke)
			var/effects/system/harmless_smoke_spread/smoke = new /effects/system/harmless_smoke_spread()
			smoke.set_up(10, 0, loc)
			smoke.start()
		task = "thinking"

/obj/critter/martian/soldier
	name = "martian soldier"
	icon_state = "martianS"
	health = 35
	aggressive = 1
	seekrange = 7

	dead
		icon_state = "martianS-dead"
		health = 0
		New()
			..()
			CritterDeath()
			icon_state = initial(icon_state)

	seek_target()
		anchored = 0
		for (var/mob/living/C in hearers(seekrange,src))
			if (!alive) break
			if (C.health < 0) continue
			if (C.name == attacker) attack = 1
			if (iscarbon(C) && atkcarbon) attack = 1
			if (istype(C, /mob/living/silicon) && atksilicon) attack = 1

			if (attack)
				target = C
				oldtarget_name = C.name
				visible_message("<span style=\"color:red\"><strong>[src]</strong> shoots at [C.name]!</span>")
				playsound(loc, "sound/weapons/lasermed.ogg", 100, 1)
				if (prob(66))
					C.TakeDamage("chest", 0, rand(3,5))
					spawn ()
						var/effects/system/spark_spread/s = unpool(/effects/system/spark_spread)
						s.set_up(3, 1, C)
						s.start()
				else boutput(target, "<span style=\"color:red\">The shot missed!</span>")
				attack = 0
				sleeping = 1
				return
			else
				continue
		task = "thinking"

/obj/critter/martian/psychic
	name = "martian mutant"
	icon_state = "martianP"
	health = 10
	aggressive = 1
	seekrange = 4
	var/gib_delay = 55
	var/do_stun = 1
	var/max_gib_distance = 6
	var/gib_counter = 0

	dead
		icon_state = "martianP-dead"
		health = 0
		New()
			..()
			CritterDeath()
			icon_state = initial(icon_state)

	seek_target()
		anchored = 0
		for (var/mob/living/C in hearers(seekrange,src))
			if (!alive) break
			if (C.health < 0) continue
			if (C.name == attacker) attack = 1
			if (iscarbon(C) && atkcarbon) attack = 1
			if (istype(C, /mob/living/silicon) && atksilicon) attack = 1

			if (attack)
				target = C
				oldtarget_name = C.name
				visible_message("<span style=\"color:red\"><strong>[src]</strong> stares at [C.name]!</span>")
				playsound(loc, "sound/weapons/phaseroverload.ogg", 100, 1)
				boutput(C, "<span style=\"color:red\">You feel a horrible pain in your head!</span>")
				gib_counter = 0
				if (do_stun)
					C.stunned += rand(1,2)
				spawn (0)
					for (var/i = 0, i <= round(gib_delay / 10), i++)
						if ((get_dist(src, C) <= max_gib_distance) && alive)
							if (gib_counter == gib_delay)
								C.visible_message("<span style=\"color:red\"><strong>[C.name]'s</strong> head explodes!</span>")
								logTheThing("combat", C, null, "was gibbed by [src] at [log_loc(src)].") // Some logging for instakill critters would be nice (Convair880).
								C.gib()
						else
							C.show_message("<span style=\"color:red\">You no longer feel the [name]'s psychic glare.</span>")
							break
						if (gib_delay - gib_counter >= 10)
							gib_delay += 10
							sleep(10)
						else
							var/slp = gib_delay - gib_counter
							gib_delay = gib_counter
							sleep(slp)
				attack = 0
				sleeping = 7
				return
			else continue

		task = "thinking"

/obj/critter/martian/psychic/weak
	name = "martian mutant initiate"
	gib_delay = 55
	do_stun = 0
	seekrange = 3
	max_gib_distance = 4

/obj/critter/martian/warrior
	name = "martian warrior"
	icon_state = "martianW"
	health = 35
	aggressive = 1
	seekrange = 7

	dead
		icon_state = "martianW-dead"
		health = 0
		New()
			..()
			CritterDeath()
			icon_state = initial(icon_state)

	ChaseAttack(mob/M)
		for (var/mob/O in viewers(src, null))
			O.show_message("<span style=\"color:red\"><strong>[src]</strong> grabs at [M]!</span>", 1)
		if (prob(33)) M.weakened += rand(2,4)
		spawn (25)
			if (get_dist(src, M) <= 1)
				visible_message("<span style=\"color:red\"><strong>[src]</strong> starts strangling [M]!</span>")

	CritterAttack(mob/M)
		attacking = 1
		if (prob(95))
			if (prob(10))
				visible_message("<span style=\"color:red\"><strong>[src]</strong> wraps its tentacles around [M]'s neck!</span>")
			M.take_oxygen_deprivation(2)
			M.weakened += 1
		else
			visible_message("<span style=\"color:red\"><strong>[src]'s</strong> grip slips!</span>")
			M.stunned = 0
			sleeping = 1
			spawn (10)
				for (var/mob/O in hearers(src, null))
					O.show_message("<span style=\"color:red\"><strong>[src]</strong> screeches, 'KBWKB WVYPGD!!'</span>", 1)
			task = "thinking"
			attacking = 0

/obj/critter/martian/sapper
	name = "martian sapper"
	icon_state = "martianSP"
	health = 10
	aggressive = 0
	defensive = 0
	atkcarbon = 0
	atksilicon = 0
	task = "wandering"

	ai_think()
		switch(task)
			if ("thinking")
				var/obj/machinery/martianbomb/B = new(loc)
				B.icon_state = "mbomb-timing"
				B.active = 1
				visible_message("<span style=\"color:red\"><strong>[src]</strong> plants a bomb and teleports away!</span>")
				qdel(src)
			else
				patrol_step()
				sleeping = 1

/obj/machinery/martianbomb
	name = "martian bomb"
	desc = "You'd best destroy this thing fast."
	icon = 'icons/misc/critter.dmi'
	icon_state = "mbomb-off"
	anchored = 1
	density = 1
	var/health = 100
	var/active = 0
	var/timeleft = 300

	process()
		if (active)
			icon_state = "mbomb-timing"
			timeleft -= 1
			if (timeleft <= 30) icon_state = "mbomb-det"
			if (timeleft == 0)
				explosion_new(src, loc, 62)
				qdel (src)
			//proc/explosion(turf/epicenter, devastation_range, heavy_impact_range, light_impact_range, flash_range)
		else
			icon_state = "mbomb-off"

	ex_act(severity)
		if (severity)
			visible_message("<span style=\"color:blue\"><strong>[src]</strong> crumbles away into dust!</span>")
			qdel (src)
		return

	bullet_act(var/obj/projectile/P)
		var/damage = 0
		damage = round((P.power*P.proj_data.ks_ratio), 1.0)

		if (material) material.triggerOnAttacked(src, P.shooter, src, (ismob(P.shooter) ? P.shooter:equipped() : P.shooter))
		for (var/atom/A in src)
			if (A.material)
				A.material.triggerOnAttacked(A, P.shooter, src, (ismob(P.shooter) ? P.shooter:equipped() : P.shooter))

		if (P.proj_data.damage_type == D_KINETIC)
			if (damage >= 20)
				health -= damage
			else
				damage = 0
		else if (P.proj_data.damage_type == D_PIERCING)
			health -= (damage*2)
		else if (P.proj_data.damage_type == D_ENERGY)
			health -= damage
		else
			damage = 0

		if (damage >= 15)
			if (active && timeleft > 10)
				for (var/mob/O in hearers(src, null))
					O.show_message("<span style=\"color:red\"><strong>[src]</strong> begins buzzing loudly!</span>", 1)
				timeleft = 10

		if (health <= 0)
			visible_message("<span style=\"color:blue\"><strong>[src]</strong> crumbles away into dust!</span>")
			qdel (src)

	attackby(obj/item/W as obj, mob/user as mob)
		..()
		health -= W.force
		if (active && timeleft > 10)
			for (var/mob/O in hearers(src, null))
				O.show_message("<span style=\"color:red\"><strong>[src]</strong> begins buzzing loudly!</span>", 1)
			timeleft = 10
		if (health <= 0)
			visible_message("<span style=\"color:blue\"><strong>[src]</strong> crumbles away into dust!</span>")
			qdel (src)