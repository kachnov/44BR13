/obj/critter/gunbot
	name = "Robot"
	desc = "A Security Robot, something seems a bit off."
	icon = 'icons/mob/robots.dmi'
	icon_state = "syndibot"
	density = 1
	health = 50
	aggressive = 1
	defensive = 0
	wanderer = 1
	opensdoors = 1
	atkcarbon = 1
	atksilicon = 0
	atcritter = 1
	firevuln = 0.5
	brutevuln = 1
	is_syndicate = 1
	mats = 8

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

				visible_message("<span style=\"color:red\"><strong>[src]</strong> fires at [target]!</span>")


				playsound(loc, "sound/weapons/Gunshot.ogg", 50, 1)
				var/tturf = get_turf(target)
				spawn (1)
					Shoot(tturf, loc, src)
				spawn (4)
					Shoot(tturf, loc, src)
				spawn (6)
					Shoot(tturf, loc, src)

				attack = 0
				return
			else continue

		if (!atcritter) return
		for (var/obj/critter/C in view(seekrange,src))
			if (!C.alive) break
			if (C.health < 0) continue
			if (C.name == attacker) attack = 1
			if (!istype(C, /obj/critter/gunbot)) attack = 1

			if (attack)

				target = C
				oldtarget_name = C.name

				visible_message("<span style=\"color:red\"><strong>[src]</strong> fires at [target]!</span>")

				playsound(loc, "sound/weapons/Gunshot.ogg", 50, 1)
				var/tturf = get_turf(target)
				spawn (1)
					Shoot(tturf, loc, src)
				spawn (4)
					Shoot(tturf, loc, src)
				spawn (6)
					Shoot(tturf, loc, src)

				attack = 0
				return
			else continue
		task = "thinking"

	CritterDeath()
		if (!alive) return
		..()
		if (get_area(src) != colosseum_controller.colosseum)
			var/turf/Ts = get_turf(src)
			var/obj/item/drop1 = pick(/obj/item/electronics/battery,/obj/item/electronics/board,/obj/item/electronics/buzzer,/obj/item/electronics/frame,/obj/item/electronics/resistor,/obj/item/electronics/screen,/obj/item/electronics/relay, /obj/item/parts/robot_parts/arm/left, /obj/item/parts/robot_parts/arm/right)
			var/obj/item/drop2 = pick(/obj/item/electronics/battery,/obj/item/electronics/board,/obj/item/electronics/buzzer,/obj/item/electronics/frame,/obj/item/electronics/resistor,/obj/item/electronics/screen,/obj/item/electronics/relay, /obj/item/parts/robot_parts/arm/left, /obj/item/parts/robot_parts/arm/right)

			new /obj/decal/cleanable/robot_debris(Ts)
			new drop1(Ts)
			new /obj/decal/cleanable/robot_debris(Ts)
			new drop2(Ts)
			new /obj/decal/cleanable/robot_debris(Ts)

		spawn ()
			var/effects/system/spark_spread/s = unpool(/effects/system/spark_spread)
			s.set_up(3, 1, src)
			s.start()
			qdel(src)