/obj/npc
	name = "NPC"
	icon = 'icons/misc/critter.dmi'
	var/stat = 0
	var/mob/current_user = null
	anchored = 1
	density = 1
	var/health = 100 //how much health the npc has
	var/angry = 0 //Is the npc aggressive
	var/tradedir= 0 //What direction the npc drops items
	var/greeting = "Hello" //Greeting text when player first interacts with npc
	var/picture = "lizardman.png" //The name of the npc portrait
	var/alive = 1
	var/temp = null
	var/needstoprocess = 0 //Does the NPC need to process something
	var/patience = 6

/obj/npc/disposing()
	current_user = null
	..()
//Handles what happens when the NPC dies
/obj/npc/proc/death()
	alive = 0
	icon_state = icon_state + "-dead"
	density = 0
	desc= "[src] looks dead."
//Handles what happens when the npc becomes aggresive
/obj/npc/proc/anger()
	for (var/mob/M in AIviewers(src))
		boutput(M, "<span style=\"color:red\"><strong>[name]</strong> becomes angry!</span>")
	desc = "[src] looks angry"
	spawn (rand(1000,3000))
		visible_message("<strong>[name] calms down.</strong>")
		desc = "[src] looks a bit annoyed."
		angry = 0
	return

//What did you think traders wouldn't have protection?
/obj/npc/proc/activatesecurity()
	return
// New() and Del() add and remove machines from the global "machines" list
// This list is used to call the process() proc for all machines ~1 per second during a round

/obj/npc/proc/gib(atom/location)
	var/obj/decal/cleanable/blood/gibs/gib = null

	// NORTH
	gib = new /obj/decal/cleanable/blood/gibs(location)
	if (prob(30))
		gib.icon_state = "gibup1"
	gib.streak(list(NORTH, NORTHEAST, NORTHWEST))

	// SOUTH
	gib = new /obj/decal/cleanable/blood/gibs(location)
	if (prob(30))
		gib.icon_state = "gibdown1"
	gib.streak(list(SOUTH, SOUTHEAST, SOUTHWEST))

	// WEST
	gib = new /obj/decal/cleanable/blood/gibs(location)
	gib.streak(list(WEST, NORTHWEST, SOUTHWEST))

	// EAST
	gib = new /obj/decal/cleanable/blood/gibs(location)
	gib.streak(list(EAST, NORTHEAST, SOUTHEAST))

/obj/npc/ex_act(severity)
	// Called when an object is in an explosion
	// Higher "severity" means the object was further from the centre of the explosion
	switch(severity)
		if (1.0)
			gib(loc)
			qdel(src)
			return
		if (2.0)
			health = health -50
		if (3.0)
			health = health -25
		else
	if (health <=0)
		death()
	return

/obj/npc/blob_act(var/power)
	// Called when attacked by a blob
	if (prob(power * 1.25))
		qdel(src)

/obj/npc/bullet_act(var/obj/projectile/P)
	var/damage = 0
	damage = round((P.power*P.proj_data.ks_ratio), 1.0)
	if (!angry)
		angry =1
		activatesecurity()
		anger()

	if (material) material.triggerOnAttacked(src, P.shooter, src, (ismob(P.shooter) ? P.shooter:equipped() : P.shooter))
	for (var/atom/A in src)
		if (A.material)
			A.material.triggerOnAttacked(A, P.shooter, src, (ismob(P.shooter) ? P.shooter:equipped() : P.shooter))

	switch(P.proj_data.damage_type)
		if (D_KINETIC,D_PIERCING,D_SLASHING)
			health -= damage
		if (D_ENERGY)
			health -= damage
		if (D_BURNING)
			health -= damage
		if (D_RADIOACTIVE)
			health -= 1
		if (D_TOXIC)
			health -= 1

	if (health <=0)
		death()

/obj/npc/attackby(obj/item/W as obj, mob/living/user as mob)
/*	if (!alive)
		..()
		return
	if (W.force)
		..()
		health -= W.force
		if (health <= 0)
			death()
			return
		if (angry!=2)
			angry = 2
			anger()
			activatesecurity()

	else
		for (var/mob/M in AIviewers(src))
			boutput(M, "<span style=\"color:red\"><strong>[user]</strong> pokes [src] with [W.name]!</span>")

		if (angry!=2)
			if (prob(25))
				angry = 2
				anger()
				activatesecurity()
		*/
	visible_message("<span style=\"color:red\"><strong>[user]</strong> pokes [src] with [W.name].</span>")
	return