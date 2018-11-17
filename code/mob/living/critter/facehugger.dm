REPO_LIST(facehuggers, list())
/mob/living/critter/facehugger
	icon = 'icons/mob/xeno/xeno.dmi'
	icon_state = "facehugger_sentient"
	icon_state_dead = "facehugger_dead"
	name = "Xenomorph Facehugger"
	real_name = "Xenomorph Facehugger"
	abilityHolder = /abilityHolder/facehugger
	flags = TABLEPASS
	
/mob/living/critter/facehugger/New()
	..()

	// unique names now
	name = "[name] ([++xenomorph_number])"
	real_name = name

	abilityHolder.addAbility(/targetable/facehugger/hivemind)
	abilityHolder.addAbility(/targetable/facehugger/communicate)
	abilityHolder.addAbility(/targetable/facehugger/crawl)
	abilityHolder.addAbility(/targetable/facehugger/hide)
	abilityHolder.addAbility(/targetable/facehugger/leap)
	abilityHolder.addAbility(/targetable/facehugger/scream)

	REPO.facehuggers += src
	spawn (50)
		if (REPO.facehuggers.len >= 3 && src == shuffle(REPO.facehuggers)[1])
			var/game_mode/_44BR13/mode = ticker.mode
			if (!mode.facehugger_traitors.len)
				mode.add_facehugger_traitor(src)
				
	// hivemind message
	REPO.xenomorph_hivemind.announce_after("[name] has been born!", 0.3 SECONDS)

	// hivemind stuff 
	REPO.xenomorph_hivemind.on_birth(src)
	
/mob/living/critter/facehugger/dispose()
	REPO.facehuggers -= src 
	..()

/mob/living/critter/facehugger/death()
	REPO.xenomorph_hivemind.announce("[name] has been slain!")
	REPO.xenomorph_hivemind.on_death(src)
	return ..()
	
/mob/living/critter/facehugger/setup_healths()
	add_hh_flesh(15, 15, 1)

/mob/living/critter/facehugger/hand_attack(var/mob/living/carbon/human/H) // non-special limb attack
	if (prob(60) && istype(H) && H.stat != DEAD && !isxenomorph(H) && !locate(/mob/living/critter/facehugger) in H)
		visible_message("<big><strong><span style = \"color:red\">[src] jumps towards [H] and attaches itself to their face!</span></strong></big>")
		H.emote("scream")
		H.weakened = max(H.weakened, 5)
		H.contract_disease(/ailment/parasite/facehugger)
		loc = H
	else if (H != src && ismob(H))
		visible_message("<big><em><span style = \"color:red\">[src] jumps towards [H], but fails to attach itself!</span></strong></big>")
	else if (istype(H, /obj/machinery/vending/monkey))
		var/obj/machinery/vending/monkey/VM = H
		VM.facehugger_act(src)

/mob/living/critter/facehugger/emote(var/act, var/voluntary = 0)
	switch (lowertext(act))
		if ("scream")
			if (emote_check(voluntary, 50))
				scream()

/mob/living/critter/facehugger/proc/scream()
	playsound(get_turf(src), 'sound/voice/male_scream.ogg', 100, pitch = 3)
	visible_message("<big><span style = \"color: red\">[src] emits a terrifying noise!</span></big>")