/*

Shield and graivty well generators

*/

/obj/shieldgen
		name = "shield generator"
		desc = "Used to seal minor hull breaches."
		icon = 'icons/obj/objects.dmi'
		icon_state = "shieldoff"

		density = 1
		opacity = 0
		anchored = 0
		pressure_resistance = 2*ONE_ATMOSPHERE

		var/active = 0
		var/health = 100
		var/malfunction = 0



/obj/shieldgen/disposing()
	for (var/obj/shield/shield_tile in deployed_shields)
		shield_tile.dispose()

	..()

/obj/shieldgen/var/list/obj/shield/deployed_shields = null

/obj/shieldgen/proc
	shields_up()
		if (active) return FALSE

		for (var/turf/target_tile in range(2, src))
			if (istype(target_tile,/turf/space) && !(locate(/obj/shield) in target_tile))
				if (malfunction && prob(33) || !malfunction)
					deployed_shields += new /obj/shield(target_tile)

		anchored = 1
		active = 1
		icon_state = malfunction ? "shieldonbr":"shieldon"

		spawn process()

	shields_down()
		if (!active) return FALSE

		for (var/obj/shield/shield_tile in deployed_shields)
			qdel(shield_tile)

		anchored = 0
		active = 0
		icon_state = malfunction ? "shieldoffbr":"shieldoff"

/obj/shieldgen/proc/process()
	if (active)
		icon_state = malfunction ? "shieldonbr":"shieldon"

		if (malfunction)
			while (prob(10))
				qdel(pick(deployed_shields))

		spawn (30)
			process()
	return

/obj/shieldgen/proc/checkhp()
	if (health <= 30)
		malfunction = 1
	if (health <= 10 && prob(75))
		qdel(src)
	if (active)
		icon_state = malfunction ? "shieldonbr":"shieldon"
	else
		icon_state = malfunction ? "shieldoffbr":"shieldoff"
	return

/obj/shieldgen/meteorhit(obj/O as obj)
	health -= 25
	if (prob(5))
		malfunction = 1
	checkhp()
	return

/obj/shield/meteorhit(obj/O as obj)
	playsound(loc, "sound/effects/shieldhit2.ogg", 50, 1)
	return

/obj/shieldgen/ex_act(severity)
	switch(severity)
		if (1.0)
			health -= 75
			checkhp()
		if (2.0)
			health -= 30
			if (prob(15))
				malfunction = 1
			checkhp()
		if (3.0)
			health -= 10
			checkhp()
	return

/obj/shield/ex_act(severity)
	switch(severity)
		if (1.0)
			if (prob(75))
				qdel(src)
		if (2.0)
			if (prob(50))
				qdel(src)
		if (3.0)
			if (prob(25))
				qdel(src)
	return

/obj/shieldgen/attack_hand(mob/user as mob)
	if (active)
		visible_message("<font color='blue'>[bicon(src)] [user] deactivated the shield generator.</font>")

		shields_down()

	else
		visible_message("<font color='blue'>[bicon(src)] [user] activated the shield generator.</font>")

		shields_up()

/obj/shield
		name = "shield"
		desc = "An energy shield."
		icon = 'icons/effects/effects.dmi'
		icon_state = "shieldsparkles"
		density = 1
		opacity = 0
		anchored = 1

/obj/shieldwall
		name = "shield"
		desc = "An energy shield."
		icon = 'icons/effects/effects.dmi'
		icon_state = "test"
		density = 1
		opacity = 0
		anchored = 1

/obj/shield
	New()
		dir = pick(1,2,3,4)

		..()

		update_nearby_tiles(need_rebuild=1)

	disposing()
		update_nearby_tiles()

		..()

	CanPass(atom/movable/mover, turf/target, height, air_group)
		if (!height || air_group) return FALSE
		else return ..()

	proc/update_nearby_tiles(need_rebuild)
		var/turf/simulated/source = loc
		if (istype(source))
			return source.update_nearby_tiles(need_rebuild)

		return TRUE

/obj/gravity_well_generator
		name = "gravity well generator"
		desc = "A complex piece of machinery that alters gravity."
		icon = 'icons/obj/stationobjs.dmi'
		icon_state = "gravgen-off"
		mats = 14

		density = 1
		opacity = 0
		anchored = 0
		pressure_resistance = 2*ONE_ATMOSPHERE

		var/active = 0
		var/strength = 144		//strength is basically G if you know your newton law of gravitation

/obj/gravity_well_generator

	meteorhit(obj/O as obj)
		if (prob(75))
			qdel(src)
			return

	ex_act(severity)
		switch(severity)
			if (1.0)
				if (prob(75))
					qdel(src)
			if (2.0)
				if (prob(50))
					qdel(src)
			if (3.0)
				if (prob(25))
					qdel(src)
		return

	attack_hand(mob/user as mob)
		if (active)
			visible_message("<font color='blue'>[bicon(src)] [user] deactivated the gravity well.</font>")

			icon_state = "gravgen-off"
			anchored = 0
			active = 0

		else
			visible_message("<font color='blue'>[bicon(src)] [user] activated the gravity well.</font>")

			icon_state = "gravgen-on"
			active = 1
			anchored = 1
			Life()

	proc/Life()

		if (!active)
			return

		//Computer the range
		var/range = round(sqrt(strength))

		for (var/atom/X in orange(range,src))
			//Skip if they're right beside the thing
			if (get_dist(src,X) <= 1)
				continue
			//Get the distance
			var/dist = get_dist(src,X)

			//Adjust probability accordingly
			if ((istype(X,/obj) || istype(X,/mob/living)) && prob(100/dist))
				//Skip if wearing magnetic shoes
				if (istype(X,/mob/living/carbon/human) && istype(X:shoes, /obj/item/clothing/shoes/magnetic) )
					continue
				//If not achored make them move towards it
				if (!X:anchored)
					step_towards(X,src)

		spawn (17)
			Life()

