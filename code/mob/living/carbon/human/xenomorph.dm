#define NO_ABILITIES 0
#define ABILITY_REGENERATION 1
#define ABILITY_PLANT_WEEDS 2
#define ABILITY_SECRETE_RESIN 4 
#define ABILITY_BUILD_RESIN 8
#define ABILITY_CRAFT_RESIN 16

REPO_LIST(grown_xenomorphs, list())

/mob/living/carbon/human/xenomorph 
	max_health = 175
	blood_color = "#00FF00"
	icon = 'icons/mob/xeno/xeno.dmi'
	icon_state = null
	abilityHolder = /abilityHolder/xenomorph
	has_custom_lying_death_icons = TRUE 
	gender = FEMALE
	var/base_icon_state = null
	var/caste_name = "Xenomorph"
	var/abilities = 0
	var/next_evolution = -1
	var/mob/living/carbon/human/babydaddy = null 
	var/slash_strength = 1.00

/mob/living/carbon/human/xenomorph/New()
	..()
	name = "[caste_name] ([++xenomorph_number])"
	real_name = name
	REPO.grown_xenomorphs += src
	// add EPIC abilities
	abilityHolder.addAbility(/targetable/xenomorph/hivemind)
	abilityHolder.addAbility(/targetable/xenomorph/communicate)
	if (abilities & ABILITY_PLANT_WEEDS)
		abilityHolder.addAbility(/targetable/xenomorph/plant_weeds)
	if (abilities & ABILITY_SECRETE_RESIN)
		abilityHolder.addAbility(/targetable/xenomorph/secrete_resin)
	if (abilities & ABILITY_BUILD_RESIN)
		abilityHolder.addAbility(/targetable/xenomorph/build_resin_structure)
	if (abilities & ABILITY_CRAFT_RESIN)
		abilityHolder.addAbility(/targetable/xenomorph/craft)
	abilityHolder.addAbility(/targetable/xenomorph/evolve)
	update_icon()

	// hivemind message
	REPO.xenomorph_hivemind.announce_after("[name] has evolved!", 0.3 SECONDS)

	// hivemind stuff 
	REPO.xenomorph_hivemind.on_birth(src)
	
/mob/living/carbon/human/xenomorph/dispose()
	REPO.grown_xenomorphs -= src 
	..()

#define BASIC_HEAL_AMOUNT 3
/mob/living/carbon/human/xenomorph/Life(controller/process/mobs/parent)
	. = ..(parent)

	// if we're hurt
	if (health < max_health && (abilities & ABILITY_REGENERATION))
		// heal 9 damage if we're on weeds 
		for (var/obj/xeno/weeds/W in get_turf(src))
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

/mob/living/carbon/human/xenomorph/death()
	REPO.xenomorph_hivemind.announce("[name] has been slain!")
	REPO.xenomorph_hivemind.on_death(src)
	return ..()

// regenerate stamina 3x as fast as a normal human (6x as fast on weeds)
/mob/living/carbon/human/xenomorph/get_stam_mod_regen()
	var/weeds = locate(/obj/xeno/weeds) in get_turf(src)
	if (weeds)
		weeds = 2
	else 
		weeds = 1
	return (STAMINA_REGEN * 3) * weeds

// no special icon overlays
/mob/living/carbon/human/xenomorph/UpdateDamageIcon()
	overlays.Cut()
	icon = initial(icon)
	
// no hitting the queen
/mob/living/carbon/human/xenomorph/is_mentally_dominated_by(M)
	return !isxenomorphqueen(src) && isxenomorphqueen(M)
	
// ouch!
/mob/living/carbon/human/xenomorph/melee_attack(var/mob/living/target)
	visible_message("<span style = \"color:red\"><strong>[src]</strong> slashes [target]!</span>")
	playsound(target, 'sound/weapons/slashcut.ogg', 100, 1)

	if (!random_brute_damage(target, slash_strength * rand(12,15)))
		if (isbot(target))
			var/obj/machinery/bot/B = target
			B.explode()
	else
		target.emote("scream")
		target.weakened = min(5, max(target.weakened+pick(0,1), 1))
		take_bleeding_damage(target, null, slash_strength * 5, DAMAGE_STAB, 1, get_turf(target))

// self explanatory
/mob/living/carbon/human/xenomorph/proc/update_icon()
	// fixes hair overlay memes
	UpdateDamageIcon()
	switch (stat)
		if (CONSCIOUS)
			if (lying)
				icon_state = "[base_icon_state]_sleep"
			else 
				icon_state = base_icon_state
		if (UNCONSCIOUS)
			icon_state = "[base_icon_state]_unconscious"
		if (DEAD)
			icon_state = "[base_icon_state]_dead"
	// reset pixel_x since a lot of things modify it
	pixel_x = initial(pixel_x)
	
/mob/living/carbon/human/xenomorph/proc/attempt_evolution()
	if (next_evolution != -1 && world.time >= next_evolution)
		evolve()
		return TRUE 
	return FALSE
		
/mob/living/carbon/human/xenomorph/proc/evolve()
	switch (type)
		if (/mob/living/carbon/human/xenomorph/hunter)
			mind.transfer_to((new /mob/living/carbon/human/xenomorph/praetorian(get_turf(src))))
	REPO.xenomorph_hivemind.on_death(src)
	--REPO.xenomorph_hivemind.total_xenomorphs
	qdel(src)

/mob/living/carbon/human/xenomorph/proc/spawn_mutt()

	switch (stats.getStat(STAT_IQ)+(babydaddy?babydaddy.stats.getStat(STAT_IQ):100))
		if (-INFINITY to INFINITY)

			var/mob/living/carbon/human/mutt/M = null 

			switch(rand(1,3))
				if (1)
					M = new /mob/living/carbon/human/mutt/elmonstruo (get_turf(src))
				if (2)
					M = new /mob/living/carbon/human/mutt/elatrocidad (get_turf(src))
				if (3)
					M = new /mob/living/carbon/human/mutt/eldegenrado (get_turf(src))

			M.father = babydaddy

			if (M.father && M.father.neural_net_account)
				M.father.neural_net_account.conceived_mutt(M)

			for (var/client in global.clients)
				var/client/C = client
				if (C && isobserver(C.mob))
					C.mob.mind.transfer_to(M)
					break

			M.go_to_mutt_hive()

			// we get to play as our own mutt after we gib, provided there weren't any other candidates
			M.parent_client_check(client)

	gib()

// types of Xenomorphs 
	
/mob/living/carbon/human/xenomorph/builder 
	icon_state = "aliend"
	base_icon_state = "aliend"
	caste_name = "Xenomorph Builder"
	abilities = ABILITY_REGENERATION|ABILITY_PLANT_WEEDS|ABILITY_SECRETE_RESIN|ABILITY_BUILD_RESIN
	max_health = 225
	slash_strength = 1.10 // 10% stronger than the crafter but nothing special

/mob/living/carbon/human/xenomorph/builder/New()
	..()
	stats.setStat(STAT_SPEED, 0.9)
	stats.setStat(STAT_STRENGTH, 1.5)
	stats.setStat(STAT_IQ, 50)
	
/mob/living/carbon/human/xenomorph/crafter
	icon_state = "aliens"
	base_icon_state = "aliens"
	caste_name = "Xenomorph Crafter"
	abilities = ABILITY_REGENERATION|ABILITY_CRAFT_RESIN
	max_health = 200
	// default slash_strength - weakest ayy
	
/mob/living/carbon/human/xenomorph/crafter/New()
	..()
	stats.setStat(STAT_SPEED, 0.8)
	stats.setStat(STAT_STRENGTH, 1.4)
	stats.setStat(STAT_IQ, 60)
	
/mob/living/carbon/human/xenomorph/hunter
	icon_state = "alienh"
	base_icon_state = "alienh"
	caste_name = "Xenomorph Hunter"
	abilities = ABILITY_REGENERATION
	max_health = 275
	slash_strength = 1.40 // far stronger than crafters and drones

/mob/living/carbon/human/xenomorph/hunter/New()
	..()
	// 15 minutes
	next_evolution = world.time + 9000
	// stats
	stats.setStat(STAT_SPEED, 1.5)
	stats.setStat(STAT_STRENGTH, 1.9)
	stats.setStat(STAT_IQ, 55)
	
/mob/living/carbon/human/xenomorph/praetorian
	icon = 'icons/mob/xeno/queen.dmi'
	icon_state = "alienp"
	base_icon_state = "alienp"
	caste_name = "Xenomorph Praetorian"
	abilities = ABILITY_REGENERATION
	pixel_x = -16
	max_health = 325
	slash_strength = 1.60 // considerably stronger than the hunter

/mob/living/carbon/human/xenomorph/praetorian/New()
	..()
	stats.setStat(STAT_SPEED, 1.3)
	stats.setStat(STAT_STRENGTH, 2.2)
	stats.setStat(STAT_IQ, 60)

/mob/living/carbon/human/xenomorph/praetorian/death()
	. = ..()
	var/game_mode/_44BR13/mode = ticker.mode
	++mode.dead_xenomorph_praetorians
	
/mob/living/carbon/human/xenomorph/queen
	icon = 'icons/mob/xeno/queen.dmi'
	icon_state = "alienq"
	base_icon_state = "alienq"
	caste_name = "Xenomorph Queen"
	abilities = ABILITY_REGENERATION|ABILITY_PLANT_WEEDS|ABILITY_SECRETE_RESIN|ABILITY_BUILD_RESIN
	pixel_x = -16
	max_health = 400
	slash_strength = 1.30 // a bit weaker than the hunter

#undef ABILITY_CRAFT_RESIN
#undef ABILITY_BUILD_RESIN
#undef ABILITY_SECRETE_RESIN
#undef ABILITY_PLANT_WEEDS
#undef ABILITY_REGENERATION
#undef NO_ABILITIES