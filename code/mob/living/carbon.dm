// carbon-based lifeforms

/mob/living/carbon/
	gender = MALE
	var/list/stomach_contents = list()
	var/last_eating = 0

	var/oxyloss = 0
	var/toxloss = 0
	var/brainloss = 0
	//var/brain_op_stage = 0.0
	//var/heart_op_stage = 0.0

	var/stamina = STAMINA_MAX
	var/stamina_max = STAMINA_MAX
	var/stamina_regen = STAMINA_REGEN
	var/stamina_crit_chance = STAMINA_CRIT_CHANCE
	var/list/stamina_mods_regen = list()
	var/list/stamina_mods_max = list()

	infra_luminosity = 4


//PLEASE ONLY EVER USE THESE TO MODIFY STAMINA. NEVER SET IT DIRECTLY.

//Returns current stamina
/mob/proc/get_stamina()
	return FALSE

/mob/living/carbon/get_stamina()
	return stamina

/mob/proc/get_max_stamina()
	return FALSE

/mob/living/carbon/get_max_stamina()
	return stamina_max

//Adds a stamina max modifier with the given key. This uses unique keys to allow for "categories" of max modifiers - so you can only have one food buff etc.
//If you get a buff of a category you already have, nothing will happen.
/mob/proc/add_stam_mod_max(var/key, var/value)
	return FALSE

/mob/living/carbon/add_stam_mod_max(var/key, var/value)
	if (!isnum(value)) return
	if (stamina_mods_max.Find(key)) return FALSE
	stamina_mods_max.Add(key)
	stamina_mods_max[key] = value
	return TRUE

//Removes a stamina max modifier with the given key.
/mob/proc/remove_stam_mod_max(var/key)
	return FALSE

/mob/living/carbon/remove_stam_mod_max(var/key)
	if (!stamina_mods_max.Find(key)) return FALSE
	stamina_mods_max.Remove(key)
	return TRUE

//Returns the total modifier for stamina max
/mob/proc/get_stam_mod_max()
	return FALSE

/mob/living/carbon/get_stam_mod_max()
	var/val = 0
	for (var/x in stamina_mods_max)
		val += stamina_mods_max[x]
	return val

//Adds a stamina regen modifier with the given key. This uses unique keys to allow for "categories" of regen modifiers - so you can only have one food buff etc.
//If you get a buff of a category you already have, nothing will happen.
/mob/proc/add_stam_mod_regen(var/key, var/value)
	return FALSE

/mob/living/carbon/add_stam_mod_regen(var/key, var/value)
	if (!isnum(value)) return
	if (stamina_mods_regen.Find(key)) return FALSE
	stamina_mods_regen.Add(key)
	stamina_mods_regen[key] = value
	return TRUE

//Removes a stamina regen modifier with the given key.
/mob/proc/remove_stam_mod_regen(var/key)
	return FALSE

/mob/living/carbon/remove_stam_mod_regen(var/key)
	if (!stamina_mods_regen.Find(key)) return FALSE
	stamina_mods_regen.Remove(key)
	return TRUE

//Returns the total modifier for stamina regen
/mob/proc/get_stam_mod_regen()
	return FALSE

/mob/living/carbon/get_stam_mod_regen()
	var/val = 0
	for (var/x in stamina_mods_regen)
		val += stamina_mods_regen[x]
	return val

//Restores stamina
/mob/proc/add_stamina(var/x)
	return

/mob/living/carbon/add_stamina(var/x as num)
	if (!isnum(x)) return
	stamina = min(stamina_max, stamina + x)
	if (stamina_bar) stamina_bar.update_value(src)
	return

//Removes stamina
/mob/proc/remove_stamina(var/x)
	return

/mob/living/carbon/remove_stamina(var/x)
	if (!isnum(x)) return
	stamina = max(STAMINA_NEG_CAP, stamina - x)
	if (stamina_bar) stamina_bar.update_value(src)
	return

//Sets stamina
/mob/proc/set_stamina(var/x)
	return

/mob/living/carbon/set_stamina(var/x)
	if (!isnum(x)) return
	stamina = max(min(stamina_max, x), STAMINA_NEG_CAP)
	if (stamina_bar) stamina_bar.update_value(src)
	return

//PLEASE ONLY EVER USE THESE TO MODIFY STAMINA. NEVER SET IT DIRECTLY.


//STAMINA UTILITY PROCS

//Responsible for executing critical hits to stamina
/mob/proc/handle_stamina_crit()
	return

/mob/living/carbon/handle_stamina_crit()
	//playsound(loc, "sound/misc/critpunch.ogg", 50, 1, -1)
	if (stamina >= 1 )
		if (STAMINA_CRIT_DROP)
			set_stamina(min(stamina,STAMINA_CRIT_DROP_NUM))
		else
			set_stamina(round(stamina / STAMINA_CRIT_DIVISOR))
		if (STAMINA_STUN_ON_CRIT)
			stunned = max(stunned, STAMINA_STUN_ON_CRIT_SEV)
	else if (stamina <= 0)
		if (STAMINA_CRIT_DROP)
			set_stamina(min(stamina * 2,STAMINA_CRIT_DROP_NUM))
		else
			set_stamina(round(stamina * STAMINA_CRIT_DIVISOR))
		if (STAMINA_STUN_ON_CRIT)
			stunned = max(stunned, STAMINA_STUN_ON_CRIT_SEV)
		if (STAMINA_NEG_CRIT_KNOCKOUT)
			if (!weakened)
				visible_message("<span style=\"color:red\">[src] collapses!</span>")
			weakened = max(weakened, STAMINA_STUN_TIME * 2)
	stamina_stun() //Just in case.
	return

//Checks if mob should be stunned for being at or below 0 stamina and then does so.
//This is in a proc so we can easily instantly apply the stun from other areas of the game.
//For example: You'd put this on a weapon after it removes stamina to make sure the stun applies
//instantly and not on the next life tick.
/mob/proc/stamina_stun()
	return

/mob/living/carbon/stamina_stun()
	if (stamina <= 0)
		var/chance = STAMINA_SCALING_KNOCKOUT_BASE
		chance += (stamina / STAMINA_NEG_CAP) * STAMINA_SCALING_KNOCKOUT_SCALER
		if (prob(chance))
			if (!weakened)
				visible_message("<span style=\"color:red\">[src] collapses!</span>")
			weakened = max(weakened, STAMINA_STUN_TIME)
	return

//STAMINA UTILITY PROCS


/mob/living/carbon/disposing()
	stomach_contents = null
	..()

/mob/living/carbon/Move(NewLoc, direct)
	. = ..()
	if (.)
		if (nutrition)
			nutrition--
		if (bioHolder && bioHolder.HasEffect("fat") && m_intent == "run")
			bodytemperature += 2

/mob/living/carbon/relaymove(var/mob/user, direction)
	if (user in stomach_contents)
		if (prob(40))
			for (var/mob/M in hearers(4, src))
				if (M.client)
					M.show_message(text("<span style=\"color:red\">You hear something rumbling inside [src]'s stomach...</span>"), 2)
			var/obj/item/I = user.equipped()
			if (I && I.force)
				var/d = rand(round(I.force / 4), I.force)
				TakeDamage("chest", d, 0)
				for (var/mob/M in viewers(user, null))
					if (M.client)
						M.show_message(text("<span style=\"color:red\"><strong>[user] attacks [src]'s stomach wall with the [I.name]!</span>"), 2)
				playsound(user.loc, "sound/effects/attackblob.ogg", 50, 1)

				if (prob(get_brute_damage() - 50))
					gib()

/mob/living/carbon/gib(give_medal)
	for (var/mob/M in src)
		if (M in stomach_contents)
			stomach_contents.Remove(M)
		M.set_loc(loc)
		visible_message("<span style=\"color:red\"><strong>[M] bursts out of [src]!</strong></span>")
	. = ..(give_medal)

/mob/living/carbon/proc/urinate()
	spawn (0)
		var/obj/decal/cleanable/urine/U = new(loc)

		// Flag the urine stain if the pisser is trying to make fake initropidril
		if (reagents.has_reagent("tongueofdog"))
			U.thrice_drunk = 4
		else if (reagents.has_reagent("woolofbat"))
			U.thrice_drunk = 3
		else if (reagents.has_reagent("toeoffrog"))
			U.thrice_drunk = 2
		else if (reagents.has_reagent("eyeofnewt"))
			U.thrice_drunk = 1


		// check for being in sight of a working security camera

		if (seen_by_camera(src) && ishuman(src))

			// determine the name of the perp (goes by ID if wearing one)
			var/perpname = name
			if (src:wear_id && src:wear_id:registered)
				perpname = src:wear_id:registered
			// find the matching security record
			for (var/data/record/R in data_core.general)
				if (R.fields["name"] == perpname)
					for (var/data/record/S in data_core.security)
						if (S.fields["id"] == R.fields["id"])
							// now add to rap sheet

							S.fields["criminal"] = "*Arrest*"
							S.fields["mi_crim"] = "Public urination."

							break



/mob/living/carbon/swap_hand()
	hand = !hand

/mob/living/carbon/lastgasp()
	// making this spawn a new proc since lastgasps seem to be related to the mob loop hangs. this way the loop can keep rolling in the event of a problem here. -drsingh
	spawn (0)
		if (!src || !client) return											// break if it's an npc or a disconnected player
		var/enteredtext = winget(src, "mainwindow.input", "text")				// grab the text from the input bar
		if ((copytext(enteredtext,1,6) == "say \"") && length(enteredtext) > 5)	// check if the player is trying to say something
			winset(src, "mainwindow.input", "text=\"\"")						// clear the player's input bar to register death / unconsciousness
			var/grunt = pick("NGGH","OOF","UGH","ARGH","BLARGH","BLUH","URK")	// pick a grunt to append
			say(copytext(enteredtext,6,0) + "--" + grunt)					// say the thing they were typing and grunt

// cogwerks - fix for soulguard and revive
/mob/living/carbon/proc/remove_ailments()
	if (ailments)
		for (var/ailment_data/disease/D in ailments)
			cure_disease(D)

/mob/living/carbon/full_heal()
	remove_ailments()
	take_toxin_damage(-INFINITY)
	take_oxygen_deprivation(-INFINITY)
	change_misstep_chance(-INFINITY)
	if (reagents)
		src.reagents.clear_reagents()
	..()

/mob/living/carbon/take_brain_damage(var/amount)
	if (..())
		return

	brainloss = max(0,min(brainloss + amount,120))

	if (brainloss >= 120)
		// instant death, we can assume a brain this damaged is no longer able to support life
		visible_message("<span style=\"color:red\"><strong>[name]</strong> goes limp, their facial expression utterly blank.</span>")
		death()
		return

	return

/mob/living/carbon/take_toxin_damage(var/amount)
	if (..())
		return

	if (bioHolder && bioHolder.HasEffect("resist_toxic"))
		return

	toxloss = max(0,toxloss + amount)
	return

/mob/living/carbon/take_oxygen_deprivation(var/amount)
	if (..())
		return

	if (bioHolder && bioHolder.HasEffect("breathless"))
		return

	oxyloss = max(0,oxyloss + amount)
	return

/mob/living/carbon/get_brain_damage()
	return brainloss

/mob/living/carbon/get_toxin_damage()
	return toxloss

/mob/living/carbon/get_oxygen_deprivation()
	return oxyloss