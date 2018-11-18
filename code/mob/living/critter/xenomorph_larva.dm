#define MIN_MAX_PROGRESS 45
#define MAX_MAX_PROGRESS 55
REPO_LIST(xenomorph_larvae, list())
/mob/living/critter/xenomorph_larva
	icon = 'icons/mob/xeno/xeno.dmi'
	icon_state = "larva0"
	icon_state_dead = "larva0_dead"
	name = "Xenomorph Larva"
	real_name = "Xenomorph Larva"
	abilityHolder = /abilityHolder/xenomorph_larva
	flags = TABLEPASS
	
	var/progress = 0
	var/evolution = null
	var/may_redo_evolution = FALSE
	var/static/queen_picked = FALSE
	
/mob/living/critter/xenomorph_larva/New()
	..()

	name = "Xenomorph Larva ([++xenomorph_number])"
	real_name = name
	
	// if we have a client, decide evolution after 2 seconds. Otherwise, let the first client who takes control of us decide.
	spawn (20)
		if (client)
			decide_evolution(0)
		else 
			may_redo_evolution = TRUE 
			
	REPO.xenomorph_larvae += src
	
	nodamage = TRUE 
	spawn (5 SECONDS)
		nodamage = FALSE
		
	abilityHolder.addAbility(/targetable/xenomorph_larva/hivemind)
	abilityHolder.addAbility(/targetable/xenomorph_larva/communicate)
	abilityHolder.addAbility(/targetable/xenomorph_larva/crawl)
	abilityHolder.addAbility(/targetable/xenomorph_larva/hide)
	
	// hivemind message
	REPO.xenomorph_hivemind.announce_after("[name] has been born!", 0.3 SECONDS)

	// hivemind stuff 
	REPO.xenomorph_hivemind.on_birth(src)

/mob/living/critter/xenomorph_larva/dispose()
	REPO.xenomorph_larvae -= src 
	..()
	
/mob/living/critter/xenomorph_larva/setup_healths()
	add_hh_flesh(35, 35, 1)
	add_hh_flesh_burn(35, 35, 1)

/mob/living/critter/xenomorph_larva/Life(controller/process/mobs/parent)
	. = ..(parent)
	if (stat == CONSCIOUS && evolution)
		++progress
		switch (progress)
			if (10 to 24)
				icon_state = "larva1"
				icon_state_dead = "larva1_dead"
			if (25 to INFINITY)
				icon_state = "larva2"
				icon_state_dead = "larva2_dead"
		if (mind && evolution && progress >= pick(MIN_MAX_PROGRESS, MAX_MAX_PROGRESS))
		
			// because our mind reference gets fucked
			var/mind/oldmind = mind
		
			// transfer the mind to a new xenomorph
			switch (evolution)
				if ("Builder")
					mind.transfer_to((new /mob/living/carbon/human/xenomorph/builder(get_turf(src))))
				if ("Crafter")
					mind.transfer_to((new /mob/living/carbon/human/xenomorph/crafter(get_turf(src))))
				if ("Hunter")
					mind.transfer_to((new /mob/living/carbon/human/xenomorph/hunter(get_turf(src))))

			// we no longer exist so yeah
			REPO.xenomorph_hivemind.on_death(src)
					
			// if the larva was a traitor, add our objective
			var/game_mode/_44BR13/mode = ticker.mode
			if (mode.facehugger_traitors.Find(oldmind.current.key))
				oldmind.special_role = "traitor"
				new /objective_set/traitor/xeno/regicide(oldmind)
				
			// begone thot (funny because all xenos are female!1)
			qdel(src)

/mob/living/critter/xenomorph_larva/death()
	REPO.xenomorph_hivemind.announce("[name] has been slain!")
	REPO.xenomorph_hivemind.on_death(src)
	return ..()
					
/mob/living/critter/xenomorph_larva/hand_attack(var/mob/living/L)
	if (istype(L) && !isxenomorph(L) && !isxenomorphlarva(L))
		visible_message("<big><strong><span style = \"color:red\">[src] bites [L]!</span></strong></big>")
		random_brute_damage(L, rand(4,5))
		
/mob/living/critter/xenomorph_larva/Login()
	. = ..()
	// so this doesn't occur twice
	if (!evolution && may_redo_evolution)
		decide_evolution(20)
	
/mob/living/critter/xenomorph_larva/Logout()
	if (!evolution)
		may_redo_evolution = TRUE 
	. = ..()

/mob/living/critter/xenomorph_larva/proc/decide_evolution(after = 20)
	set waitfor = FALSE 
	sleep(after)
	if (client)
		evolution = input(src, "Evolve to what type of Xenomorph?", "Evolution") in list("Builder", "Crafter", "Hunter")
		name = replacetext(name, "Larva", "[evolution] Larva")
		real_name = name
		boutput(src, "You will become a <strong>Xenomorph [evolution]</strong> when you have grown. " + \
			"Click on the health button to see your progress.")
		return TRUE 
	return FALSE

/mob/living/critter/xenomorph_larva/proc/evolution_progress()
	switch (progress/MIN_MAX_PROGRESS)
		if (0 to 0.3)
			return "Far from complete."
		if (0.3 to 0.6)
			return "Partially complete."
		if (0.6 to 0.9)
			return "Nearly complete."
		if (0.9 to INFINITY)
			return "Practically complete."
#undef MIN_MAX_PROGRESS
#undef MAX_MAX_PROGRESS