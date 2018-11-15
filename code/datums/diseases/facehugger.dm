/ailment/parasite/facehugger
	name = "Unidentified Foreign Body"
	max_stages = 4
	affected_species = list("Human", "Monkey")
	cure = "Surgery"
	stage_prob = 13

// surgery
/ailment/parasite/facehugger/surgery(var/mob/living/surgeon, var/mob/living/affected_mob, var/ailment_data/D)
	if (D.disposed)
		return FALSE
	var/outcome = rand(90)
	if (surgeon.bioHolder.HasEffect("training_medical"))
		outcome += 10
	var/numb = affected_mob.reagents.has_reagent("morphine") || affected_mob.sleeping
	switch (outcome)
		if (0 to 5)
			// im doctor
			surgeon.visible_message("<span style=\"color:red\"><strong>[surgeon] cuts open [affected_mob] in all the wrong places!</strong></span>", "You dig around in [affected_mob]'s chest and accidentally snip something important looking!")
			affected_mob.show_message("<span style=\"color:red\"><strong>You feel a [numb ? "numb" : "sharp"] stabbing pain in your chest!</strong></span>")
			affected_mob.TakeDamage("chest", numb ? 37.5 : 75, 0, DAMAGE_CUT)
			affected_mob.updatehealth()
			return FALSE
		if (6 to 15)
			surgeon.visible_message("<span style=\"color:red\"><strong>[surgeon] clumsily cuts open [affected_mob]!</strong></span>", "You dig around in [affected_mob]'s chest and accidentally snip something not so important looking!")
			affected_mob.show_message("<span style=\"color:red\"><strong>You feel a [numb ? "mild " : " "]stabbing pain in your chest!</strong></span>")
			affected_mob.TakeDamage("chest", numb ? 20 : 40, 0, 0, DAMAGE_CUT)
			affected_mob.updatehealth()
			return FALSE
		if (16 to INFINITY)
			surgeon.visible_message("<span style=\"color:blue\"><strong>[surgeon] cuts open [affected_mob] and removes the larva.</strong></span>", "<span style=\"color:blue\">You remove the larva from [affected_mob].</span>")
			if (!numb)
				affected_mob.show_message("<span style=\"color:red\"><strong>You feel a mild stabbing pain in your chest!</strong></span>")
				affected_mob.TakeDamage("chest", 10, 0, 0, DAMAGE_STAB)
				affected_mob.updatehealth()
			return TRUE

/ailment/parasite/facehugger/stage_act(var/mob/living/affected_mob,var/ailment_data/parasite/D)
	if (..())
		return

	switch(D.stage)
		if (2)
			if (prob(15))
				if (affected_mob.canmove && isturf(affected_mob.loc))
					step(affected_mob, pick(cardinal))
			if (prob(3))
				affected_mob.emote("twitch")
			if (prob(3))
				affected_mob.emote("twitch_v")
			if (prob(2))
				boutput(affected_mob, "<span style=\"color:red\">You feel strange.</span>")
				affected_mob.change_misstep_chance(5)
		if (3)
			if (prob(50))
				if (affected_mob.canmove && isturf(affected_mob.loc))
					step(affected_mob, pick(cardinal))
			if (prob(5))
				affected_mob.emote("twitch")
			if (prob(5))
				affected_mob.emote("twitch_v")
			if (prob(5))
				boutput(affected_mob, "<span style=\"color:red\">You feel very strange.</span>")
				affected_mob.change_misstep_chance(10)
			if (prob(2))
				boutput(affected_mob, "<span style=\"color:red\">Your stomach hurts.</span>")
				affected_mob.emote("groan")
		if (4)
			for (var/mob/living/critter/facehugger/facehugger in affected_mob)
				if (facehugger.mind && facehugger.client)
					boutput(affected_mob, "<span style=\"color:red\">You feel something pushing at your spine...</span>")
					var/atom/larva = new /mob/living/critter/xenomorph_larva (get_turf(affected_mob))
					facehugger.mind.transfer_to(larva)
					xenomorph_hivemind.on_death(facehugger)
					qdel(facehugger)
					larva.visible_message("<span style = \"color:red\"><big>[larva] bursts out of [affected_mob]!</big></span>")
					affected_mob.gib()
					break
