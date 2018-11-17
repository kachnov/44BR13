REPO_LIST(amerimutts, list())
REPO_LIST(mutt_upgrades, list(MUTT_UPGRADE_AZUL, MUTT_UPGRADE_SSj, MUTT_UPGRADE_BLANCO, MUTT_UPGRADE_GRANDE))

/mob/living/carbon/human/mutt
	icon = 'icons/mob/mutt.dmi'
	abilityHolder = /abilityHolder/mutt
	has_custom_lying_death_icons = TRUE

	var/base_icon_state = null
	var/good_boy_points = 50
	var/caste_name = "Mutt"

	var/static/list/mutt_phrases = list(
		"You betrayed our white race, gramps!",
		"I'm a 100% white based and redpilled MAGA Pede!",
		"Brits aren't white, you can tell by looking at Paris. Fucking Euro-poors.",
		"I'm 100% pure Bavarian.",
		"I'm 100% pure Aryan.",
		"I'm 100% pure Swedish."
	)

	var/static/mutts = 0 

	var/list/upgrades = list()

	var/mob/living/carbon/human/father = null

	var/grande = FALSE

/mob/living/carbon/human/mutt/New()
	..()

	set_mutantrace(/mutantrace/mutt)
	update_icon()

	name = "[caste_name] ([++mutts])"
	real_name = name

	// the Mutt is a slow, lumbering beast
	stats.setStat(STAT_SPEED, 0.75)

	// WIP 
	stats.setStat(STAT_IQ, 60)

	REPO.amerimutts += src

	REPO.mutt_hivemind.announce_after("[name] has been born.", 0.3 SECONDS)

	abilityHolder.addAbility(/targetable/mutt/hivemind)
	abilityHolder.addAbility(/targetable/mutt/communicate)
	abilityHolder.addAbility(/targetable/mutt/absorb)

/mob/living/carbon/human/mutt/dispose()
	REPO.amerimutts -= src 
	..()

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
			blood_volume = min(max_blood_volume, blood_volume + BASIC_HEAL_AMOUNT*3)
			break 
		// heal 3 damage anyway
		if (health < max_health)
			HealDamage("All", BASIC_HEAL_AMOUNT, BASIC_HEAL_AMOUNT, BASIC_HEAL_AMOUNT)
			blood_volume = min(max_blood_volume, blood_volume + BASIC_HEAL_AMOUNT)
			if (bleeding)
				--bleeding
			if (bleeding_internal)
				--bleeding_internal
			
	update_icon()
#undef BASIC_HEAL_AMOUNT

/mob/living/carbon/human/mutt/death()
	REPO.mutt_hivemind.announce("[name] has been slain.")
	return ..()
	
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
	say("[uppertext(pick(mutt_phrases))]")
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

	// stop spinning
	animate_spin(src, T = 0.3 SECONDS, looping = 1)

	nodamage = FALSE
	canmove = TRUE

/mob/living/carbon/human/mutt/proc/parent_client_check(var/client/parent)
	set waitfor = FALSE 
	sleep(0.2 SECONDS)
	if (!client && parent && isobserver(parent.mob))
		parent.mob.mind.transfer_to(src)

/mob/living/carbon/human/mutt/proc/upgrade()

	// if we don't already have all upgrades
	if (upgrades.len < REPO.mutt_upgrades.len)
		var/upgrade = pick(REPO.mutt_upgrades)
		while (upgrades.Find(upgrade))
			upgrade = pick(REPO.mutt_upgrades)
		upgrades += upgrade
		switch (upgrade)
			if (MUTT_UPGRADE_AZUL)
				visible_message("<big><strong>[name]</strong> turns blue!")
				name = "[name] Azul"
				real_name = name
				color = "#00FFFF"

				// generous boost to all stats
				stats.incStat(STAT_SPEED, 0.33)
				stats.incStat(STAT_STRENGTH, 0.33)
				stats.incStat(STAT_IQ, 15)

			if (MUTT_UPGRADE_SSj)
				visible_message("<big><strong>[name]</strong> turns into a Super Saiyan!")
				name = "SSj [name]"
				real_name = name
				color = "#FFD700"

				// bigger boost to str/speed
				stats.incStat(STAT_SPEED, 0.50)
				stats.incStat(STAT_STRENGTH, 0.50)

			if (MUTT_UPGRADE_BLANCO)
				visible_message("<big><strong>[name]</strong> turns white!")
				name = "[name] Blanco"
				real_name = name
				color = "#f8f8ff"

				// generous boost to all stats
				stats.incStat(STAT_SPEED, 0.33)
				stats.incStat(STAT_STRENGTH, 0.33)
				stats.incStat(STAT_IQ, 15)

			if (MUTT_UPGRADE_GRANDE)
				visible_message("<big><strong>[name]</strong> grows bigger!")
				name = "Grande [name]"
				real_name = name
				grande = TRUE

				// major boost to strength
				stats.incStat(STAT_STRENGTH, 0.75)

				// make us bloatmaxx
				transform *= 1.50

	// we have all upgrades already
	else
		stats.incStat(STAT_SPEED, 0.10)
		stats.incStat(STAT_STRENGTH, 0.10)
		stats.incStat(STAT_IQ, 5)
		boutput(src, "<big>You feel stronger, faster, and smarter.</big>")

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
	var/mob/living/carbon/human/mutt/M = mob
	if (istype(L))
		mob.visible_message("<span style = \"color:red\"><strong>[mob] smacks [L] with his greasy hands, " + \
			"getting mutt acid on them!</strong></span>")
		random_burn_damage(L, 20 * M.stats.getStat("strength"))
		if (ishuman(L))
			L.emote("scream")
	else 
		return ..(L)
