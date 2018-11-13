/obj/critter/alien/larva
	name = "alien larva"
	icon_state = "larva" // icon_state = "larva_l" - dead
	dead_state = "larva_l"
	health = 10
	aggressive = 0
	defensive = 1
	var/amount_grown = 0
	desc = "You know, it'd be kind of cute if it wasn't trying to eat you."

	process() //overriding default sleeping behavior
		if (!alive) // and completely ruining their ability to die by not including some very important bits I guess
			return FALSE
		check_health()

		amount_grown++

		if (amount_grown >= 100)
			new /obj/critter/alien/humanoid( loc )

			qdel(src)

		else
			ai_think()

/obj/critter/alien/humanoid
	density = 1

/obj/critter/alien
	name = "Alien"
	desc = "An alien."
	icon_state = "alien"
	density = 1
	anchored = 0
	health = 40
	aggressive = 1
	defensive = 0
	wanderer = 1
	opensdoors = 1
	atkcarbon = 1
	atksilicon = 1
	firevuln = 1
	brutevuln = 1
	atcritter = 1

	seek_target()
		if (!alive) return
		anchored = 0
		for (var/mob/living/C in hearers(seekrange,src))
			if ((C.name == oldtarget_name) && (world.time < last_found + 100)) continue
			if (iscarbon(C) && !atkcarbon) continue
			//if (isalien(C)) continue
			if (istype(C, /mob/living/silicon) && !atksilicon) continue
			if (C.health < 0) continue
			if (C.name == attacker) attack = 1
			if (iscarbon(C) && atkcarbon) attack = 1
			if (istype(C, /mob/living/silicon) && atksilicon) attack = 1

			if (attack)
				target = C
				oldtarget_name = C.name
				visible_message("<span class='combat'><strong>[src]</strong> charges at [C:name]!</span>")
				task = "chasing"
				return
			else
				continue

		if (!atcritter) return
		for (var/obj/critter/C in view(seekrange,src))
			if (!C.alive) continue
			if (C.health < 0) continue
			if (!istype(C, /obj/critter/alien)) attack = 1

			if (attack)
				target = C
				oldtarget_name = C.name
				visible_message("<span class='combat'><strong>[src]</strong> lunges at [C.name]!</span>")

				task = "chasing"
				return

			else continue

	CritterAttack(mob/M)
		attacking = 1
		if (istype(M,/obj/critter))
			var/obj/critter/C = M
			visible_message("<span class='combat'><strong>[src]</strong> claws [target]!</span>")
			playsound(C.loc, "punch", 25, 1, -1)
			C.health -= 10
			if (C.health <= 0)
				C.CritterDeath()
			spawn (15)
				attacking = 0
			return

		visible_message("<span class='combat'><strong>[src]</strong> claws at [target]!</span>")
		random_brute_damage(target, rand(5,10))
		spawn (10)
			attacking = 0

	ChaseAttack(mob/M)
		visible_message("<span class='combat'><strong>[src]</strong> jumps at [M]!</span>")
		if (iscarbon(M))
			if (prob(60)) M.stunned += rand(1,5)
			random_brute_damage(M, rand(2,5))