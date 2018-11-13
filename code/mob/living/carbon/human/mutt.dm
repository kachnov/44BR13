/mob/living/carbon/human/mutt
	icon = 'icons/mob/mutt.dmi'

	var/base_icon_state = null
	var/good_boy_points = 50
	var/caste_name = "Mutt"

	var/static/list/mutt_phrases = list(
		"You betrayed our white race, gramps!",
		"I'm a 100% German huwhite MAGA Pede, based and redpilled!",
		"Brits aren't white, you can tell by looking at Paris. Fucking Euro-poors.",
		"I'm 100% pure Bavarian.",
		"I'm 100% pure Aryan.",
		"I'm 100% pure Swedish."
	)

	var/static/mutts = 0 

	var/mob/living/carbon/human/father = null

/mob/living/carbon/human/mutt/New()
	..()

	set_mutantrace(/mutantrace/mutt)
	update_icon()

	name = "[caste_name] ([++mutts])"
	real_name = name

	// the Mutt is a slow, lumbering beast
	stats.setStat(STAT_SPEED, 0.75)

/mob/living/carbon/human/mutt/Life(controller/process/mobs/parent)
	..(parent)

	if (stat == CONSCIOUS)
	
		// spawn literal shit every 10 seconds or so
		if (prob(20))
			var/turf/T = get_turf(src)
			if (!locate(/obj/mutt/weeds) in T)
				new /obj/mutt/weeds (T)

		// say something every 50 seconds or so
		if (prob(4))
			say(pick(mutt_phrases))

		// reproduce every 100 seconds or so if possible
		if (prob(2))
			for (var/client in global.clients)
				var/client/C = client
				if (C && isobserver(C.mob))
					var/mob/living/carbon/human/mutt/M = new type (get_turf(src))
					C.mob.mind.transfer_to(M)
					break

	update_icon()

#define BASIC_HEAL_AMOUNT 3
/mob/living/carbon/human/mutt/Life(controller/process/mobs/parent)
	. = ..(parent)

	// if we're hurt
	if (health < max_health)
		// heal 9 damage if we're on weeds 
		for (var/obj/mutt/weeds/W in get_turf(src))
			HealDamage("All", BASIC_HEAL_AMOUNT*3, BASIC_HEAL_AMOUNT*3, BASIC_HEAL_AMOUNT*3)
			blood_volume = min(blood_volume, blood_volume + BASIC_HEAL_AMOUNT*3)
			break 
		// heal 3 damage anyway
		if (health < max_health)
			HealDamage("All", BASIC_HEAL_AMOUNT, BASIC_HEAL_AMOUNT, BASIC_HEAL_AMOUNT)
			blood_volume = min(blood_volume, blood_volume + BASIC_HEAL_AMOUNT)
			if (bleeding)
				--bleeding
			if (bleeding_internal)
				--bleeding_internal
			
	update_icon()
#undef BASIC_HEAL_AMOUNT

/mob/living/carbon/human/mutt/get_stam_mod_regen()
	var/weeds = locate(/obj/mutt/weeds) in get_turf(src)
	if (weeds)
		weeds = 2
	else 
		weeds = 1
	return (STAMINA_REGEN * 3) * weeds

// no special icon overlays
/mob/living/carbon/human/mutt/UpdateDamageIcon()
	overlays.Cut()
	icon = initial(icon)

// ouch!
/mob/living/carbon/human/mutt/melee_attack(var/mob/living/target)
	return mutantrace.custom_attack(target)

// self explanatory
/mob/living/carbon/human/mutt/proc/update_icon()
	// fixes hair overlay memes
	UpdateDamageIcon()
	switch (stat)
		if (CONSCIOUS)
			if (lying)
				icon_state = "[base_icon_state]_unconscious"
			else 
				icon_state = base_icon_state
		if (UNCONSCIOUS)
			icon_state = "[base_icon_state]_unconscious"
		if (DEAD)
			icon_state = "[base_icon_state]_dead"
	// reset pixel_x since a lot of things modify it
	pixel_x = initial(pixel_x)

/mob/living/carbon/human/mutt/proc/go_to_mutt_hive()
	set waitfor = FALSE
	nodamage = TRUE
	canmove = FALSE

	// shout something in amerimutt then fly off
	animate_spin(src, T = 0.3 SECONDS)
	say(uppertext(pick(mutt_phrases)))
	sleep(0.5 SECONDS)

	var/turf/target = pick(mutt_noclip_locations)

	while (loc != target)
		if (x < target.x)
			++x
		else if (x > target.x)
			--x
		if (y < target.y)
			++y
		else if (y > target.y)
			--y
		sleep(world.tick_lag)

	animate(transform = null)

	nodamage = FALSE
	canmove = TRUE

/mob/living/carbon/human/mutt/proc/parent_client_check(var/client/parent)
	set waitfor = FALSE 
	sleep(0.5 SECONDS)
	if (!client && parent && isobserver(parent.mob))
		parent.mob.mind.transfer_to(src)

// subtypes
/mob/living/carbon/human/mutt/elmonstruo
	icon_state = "brown"
	base_icon_state = "brown"
	caste_name = "El Monstruo"

/mob/living/carbon/human/mutt/elatrocidad
	icon_state = "black"
	base_icon_state = "black"
	caste_name = "El Atrocidad"

/mob/living/carbon/human/mutt/eldegenrado
	icon_state = "brown"
	base_icon_state = "brown"
	color = "#00FF00"
	caste_name = "El Degenerado"

// mutantrace
/mutantrace/mutt

/mutantrace/mutt/custom_attack(var/mob/living/L)
	if (istype(L))
		mob.visible_message("<span style = \"color:red\"><strong>[mob] smacks [L] with his greasy hands, " + \
			"getting mutt acid on them!</strong></span>")
		random_burn_damage(L, 20)
		if (ishuman(L))
			L.emote("scream")
	else 
		return ..(L)