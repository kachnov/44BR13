// human

/mob/living/carbon/human
	name = "human"
	voice_name = "human"
	icon = 'icons/mob/mob.dmi'
	icon_state = "blank"

	var/dump_contents_chance = 20
	var/last_move_trigger = 0

	var/image/health_mon = null

	var/pin = null
	var/obj/item/clothing/suit/wear_suit = null
	var/obj/item/clothing/under/w_uniform = null
//	var/obj/item/device/radio/w_radio = null
	var/obj/item/clothing/shoes/shoes = null
	var/obj/item/belt = null
	var/obj/item/clothing/gloves/gloves = null
	var/obj/item/clothing/glasses/glasses = null
	var/obj/item/clothing/head/head = null
	//var/obj/item/card/id/wear_id = null
	var/obj/item/wear_id = null
	var/obj/item/r_store = null
	var/obj/item/l_store = null

	var/image/body_standing = null
	var/image/fire_standing = null
	//var/image/face_standing = null
	var/image/hands_standing = null
	var/image/damage_standing = null
	var/image/head_damage_standing = null
	var/list/inhands_standing = list()

	var/image/image_eyes = null
	var/image/image_cust_one = null
	var/image/image_cust_two = null
	var/image/image_cust_three = null

	var/last_b_state = 1.0

	var/list/implant = list()
	var/list/implant_images = list()

	var/cust_one_state = "short"
	var/cust_two_state = "None"
	var/cust_three_state = "none"

	var/can_bleed = 1
	blood_id = "blood"
	var/blood_volume = 500
	var/blood_color = DEFAULT_BLOOD_COLOR
	var/bleeding = 0
	var/bleeding_internal = 0
	var/blood_absorption_rate = 1 // amount of blood to absorb from the reagent holder per Life()
	var/list/bandaged = list()
	var/being_staunched = 0 // is someone currently putting pressure on their wounds?

	var/organHolder/organHolder
	var/ignore_organs = 0 // set to 1 to basically skip the handle_organs() proc

	var/on_chair = 0
	var/simple_examine = 0

	var/last_cluwne_noise = 0 // used in /proc/process_accents() to keep cluwnes from making constant fucking noise

	var/in_throw_mode = 0

	var/decomp_stage = 0 // 1 = bloat, 2 = decay, 3 = advanced decay, 4 = skeletonized
	var/next_decomp_time = 0

	var/mutantrace/mutantrace = null
	var/mimic = 0

	var/emagged = 0 //What the hell is wrong with me?
	var/spiders = 0 // SPIDERS

	var/gunshot_residue = 0 // Fire a kinetic firearm and get forensic evidence all over you (Convair880).

	var/hud/human/hud
	var/mini_health_hud = 0

	//The spooky UNKILLABLE MAN
	var/unkillable = 0

	// TODO: defensive/offensive stance intents for combat
	var/stance = "normal"

	var/mob/living/carbon/target = null
	var/ai_aggressive = 0
	var/ai_default_intent = INTENT_DISARM
	var/ai_calm_down = 0 // do we chill out after a while?
	var/ai_picking_pocket = 0

	max_health = 100

	//april fools stuff
	var/blinktimer = 0
	var/blinkstate = 0
	var/breathtimer = 0
	var/breathstate = 0

	var/light/burning_light

	//dismemberment stuff
	var/human_limbs/limbs = null

	var/static/image/human_image = image('icons/mob/human.dmi')
	var/static/image/human_head_image = image('icons/mob/human_head.dmi')
	var/static/image/human_untoned_image = image('icons/mob/human.dmi')
	var/static/image/human_decomp_image = image('icons/mob/human_decomp.dmi')
	var/static/image/human_untoned_decomp_image = image('icons/mob/human.dmi')
	var/static/image/undies_image = image('icons/mob/human_underwear.dmi') //, layer = MOB_UNDERWEAR_LAYER)
	var/static/image/bandage_image = image('icons/obj/surgery.dmi', "layer" = EFFECTS_LAYER_UNDER_1-1)
	var/static/image/blood_image = image('icons/effects/blood.dmi', "layer" = EFFECTS_LAYER_UNDER_1-1)
	var/static/image/handcuff_img = image('icons/mob/mob.dmi')
	var/static/image/shield_image = image('icons/mob/mob.dmi', "icon_state" = "shield")
	var/static/image/heart_image = image('icons/mob/human.dmi')
	var/static/image/heart_emagged_image = image('icons/mob/human.dmi', "layer" = EFFECTS_LAYER_UNDER_1-1)
	var/static/image/spider_image = image('icons/mob/human.dmi', "layer" = EFFECTS_LAYER_UNDER_1-1)

	var/static/image/juggle_image = image('icons/mob/human.dmi', "layer" = EFFECTS_LAYER_UNDER_1-1)
	var/list/juggling = list()
	var/can_juggle = 0

	// preloaded sounds moved up to /mob/living

	var/list/sound_list_scream = null
	var/list/sound_list_laugh = null
	var/list/sound_list_flap = null

	var/list/pathogens = list()
	var/list/immunities = list()

	var/simsHolder/sims = null

	var/list/random_emotes = list("drool", "blink", "yawn", "burp", "twitch", "twitch_v",\
	"cough", "sneeze", "shiver", "shudder", "shake", "hiccup", "sigh", "flinch", "blink_r", "nosepick")

	var/has_custom_lying_death_icons = FALSE

	// stats
	var/statHolder/stats = null

	// neural net memes (its normal for this to be null for non-Boomers)
	var/neural_net_account/neural_net_account = null

	// xd
	var/schlong = null
	var/nut = 0

/mob/living/carbon/human/New()
	. = ..()

	// xd
	schlong = pick("fat", "tiny", "humungous")

	image_eyes = image('icons/mob/human_hair.dmi', layer = MOB_FACE_LAYER)
	image_cust_one = image('icons/mob/human_hair.dmi', layer = MOB_HAIR_LAYER2)
	image_cust_two = image('icons/mob/human_hair.dmi', layer = MOB_HAIR_LAYER2)
	image_cust_three = image('icons/mob/human_hair.dmi', layer = MOB_HAIR_LAYER2)

	var/reagents/R = new/reagents(330)
	reagents = R
	R.my_atom = src

	hud = new(src)
	attach_hud(hud)
	zone_sel = new(src)
	attach_hud(zone_sel)
	stamina_bar = new(src)
	hud.add_object(stamina_bar, HUD_LAYER+1, "EAST-1, NORTH")

	if (global_sims_mode) // IF YOU ARE HERE TO DISABLE SIMS MODE, DO NOT TOUCH THIS. LOOK IN GLOBAL.DM
		if (map_setting == "DESTINY")
			sims = new /simsHolder/destiny(src)
		else
			sims = new /simsHolder/human(src)

	stats = new(src)

	health_mon = image('icons/effects/healthgoggles.dmi',src,"100",10)
	health_mon_icons.Add(health_mon)

	burning_light = new /light/point
	burning_light.attach(src)
	burning_light.set_color(0.94, 0.69, 0.27)

	organHolder = new(src)

	if (!bioHolder)
		bioHolder = new/bioHolder(src)
	if (!abilityHolder)
		abilityHolder = new /abilityHolder/composite(src)
	else if (ispath(abilityHolder))
		abilityHolder = new abilityHolder(src)

	spawn (1)
		if (disposed)
			return

		limbs = new /human_limbs(src)

		organs["chest"] = organHolder.chest
		organs["head"] = organHolder.head
		organs["l_arm"] = limbs.l_arm
		organs["r_arm"] = limbs.r_arm
		organs["l_leg"] = limbs.l_leg
		organs["r_leg"] = limbs.r_leg

		update_body()
		update_face()
		UpdateDamageIcon()


/human_limbs
	var/mob/living/carbon/human/holder = null

	var/obj/item/parts/l_arm = null
	var/obj/item/parts/r_arm = null
	var/obj/item/parts/l_leg = null
	var/obj/item/parts/r_leg = null

	var/l_arm_bleed = 0
	var/r_arm_bleed = 0
	var/l_leg_bleed = 0
	var/r_leg_bleed = 0

	New(mob/new_holder)
		..()
		holder = new_holder
		if (holder) create()

	dispose()
		if (l_arm)
			l_arm.holder = null
		if (r_arm)
			r_arm.holder = null
		if (l_leg)
			l_leg.holder = null
		if (r_leg)
			r_leg.holder = null
		holder = null
		..()

	proc/create()
		if (!l_arm) l_arm = new /obj/item/parts/human_parts/arm/left(holder)
		if (!r_arm) r_arm = new /obj/item/parts/human_parts/arm/right(holder)
		if (!l_leg) l_leg = new /obj/item/parts/human_parts/leg/left(holder)
		if (!r_leg) r_leg = new /obj/item/parts/human_parts/leg/right(holder)

		spawn (50)
			if (holder && !l_arm || !r_arm || !l_leg || !r_leg)
				logTheThing("debug", holder, null, "<strong>SpyGuy/Limbs:</strong> [src] is missing limbs after creation for some reason - recreating.")
				create()
				if (holder)
					// fix for "Cannot execute null.update body()".when mob is deleted too quickly after creation
					holder.update_body()
					if (holder.client)
						holder.client.move_delay = world.time + 7
						//Fix for not being able to move after you got new limbs.

	proc/mend(var/howmany = 4)
		if (!holder)
			return

		if (!l_arm && howmany > 0)
			l_arm = new /obj/item/parts/human_parts/arm/left(holder)
			l_arm.holder = holder
			boutput(holder, "<span style=\"color:blue\">Your left arm regrows!</span>")
			l_arm:original_holder = holder
			l_arm:set_skin_tone()
			howmany--

		if (!r_arm && howmany > 0)
			r_arm = new /obj/item/parts/human_parts/arm/right(holder)
			r_arm.holder = holder
			boutput(holder, "<span style=\"color:blue\">Your right arm regrows!</span>")
			r_arm:original_holder = holder
			r_arm:set_skin_tone()
			howmany--

		if (!l_leg && howmany > 0)
			l_leg = new /obj/item/parts/human_parts/leg/left(holder)
			l_leg.holder = holder
			boutput(holder, "<span style=\"color:blue\">Your left leg regrows!</span>")
			l_leg:original_holder = holder
			l_leg:set_skin_tone()
			howmany--

		if (!r_leg && howmany > 0)
			r_leg = new /obj/item/parts/human_parts/leg/right(holder)
			r_leg.holder = holder
			boutput(holder, "<span style=\"color:blue\">Your right leg regrows!</span>")
			r_leg:original_holder = holder
			r_leg:set_skin_tone()
			howmany--

		if (holder.client) holder.client.move_delay = world.time + 7 //Fix for not being able to move after you got new limbs.

	proc/reset_stone() // reset skintone to whatever the holder's s_tone is
		if (l_arm && istype(l_arm, /obj/item/parts/human_parts))
			l_arm:set_skin_tone()
		if (r_arm && istype(r_arm, /obj/item/parts/human_parts))
			r_arm:set_skin_tone()
		if (l_leg && istype(l_leg, /obj/item/parts/human_parts))
			l_leg:set_skin_tone()
		if (r_leg && istype(r_leg, /obj/item/parts/human_parts))
			r_leg:set_skin_tone()

	proc/sever(var/target = "all", var/mob/user)
		if (!target)
			return FALSE
		if (istext(target))
			var/list/limbs_to_sever = list()
			switch (target)
				if ("all")
					limbs_to_sever += list(l_arm, r_arm, l_leg, r_leg)
				if ("both_arms")
					limbs_to_sever += list(l_arm, r_arm)
				if ("both_legs")
					limbs_to_sever += list(l_leg, r_leg)
				if ("l_arm")
					limbs_to_sever += list(l_arm)
				if ("r_arm")
					limbs_to_sever += list(r_arm)
				if ("l_leg")
					limbs_to_sever += list(l_leg)
				if ("r_leg")
					limbs_to_sever += list(r_leg)
			if (limbs_to_sever.len)
				for (var/obj/item/parts/P in limbs_to_sever)
					P.sever(user)
				return TRUE
		else if (istype(target, /obj/item/parts))
			var/obj/item/parts/P = target
			P.sever(user)
			return TRUE

	proc/replace_with(var/target, var/new_type, var/mob/user)
		if (!target || !new_type || !holder)
			return FALSE
		if (istext(target) && ispath(new_type))
			if (target == "both_arms" || target == "l_arm")
				if (ispath(new_type, /obj/item/parts/human_parts/arm) || ispath(new_type, /obj/item/parts/robot_parts/arm))
					qdel(l_arm)
					l_arm = new new_type(holder)
				else // need to make an item arm
					qdel(l_arm)
					l_arm = new /obj/item/parts/human_parts/arm/left/item(holder, new new_type(holder))
				holder.show_message("<span style=\"color:blue\"><strong>Your left arm [pick("magically ", "weirdly ", "suddenly ", "grodily ", "")]becomes [l_arm]!</strong></span>")
				if (user)
					logTheThing("admin", user, holder, "replaced %target%'s left arm with [new_type]")
				. ++

			if (target == "both_arms" || target == "r_arm")
				if (ispath(new_type, /obj/item/parts/human_parts/arm) || ispath(new_type, /obj/item/parts/robot_parts/arm))
					qdel(r_arm)
					r_arm = new new_type(holder)
				else // need to make an item arm
					qdel(r_arm)
					r_arm = new /obj/item/parts/human_parts/arm/right/item(holder, new new_type(holder))
				holder.show_message("<span style=\"color:blue\"><strong>Your right arm [pick("magically ", "weirdly ", "suddenly ", "grodily ", "")]becomes [r_arm]!</strong></span>")
				if (user)
					logTheThing("admin", user, holder, "replaced %target%'s right arm with [new_type]")
				. ++

			if (target == "both_legs" || target == "l_leg")
				if (ispath(new_type, /obj/item/parts/human_parts/leg) || ispath(new_type, /obj/item/parts/robot_parts/leg))
					qdel(l_leg)
					l_leg = new new_type(holder)
					holder.show_message("<span style=\"color:blue\"><strong>Your left leg [pick("magically ", "weirdly ", "suddenly ", "grodily ", "")]becomes [l_leg]!</strong></span>")
					if (user)
						logTheThing("admin", user, holder, "replaced %target%'s left leg with [new_type]")
					. ++

			if (target == "both_legs" || target == "r_leg")
				if (ispath(new_type, /obj/item/parts/human_parts/leg) || ispath(new_type, /obj/item/parts/robot_parts/leg))
					qdel(r_leg)
					r_leg = new new_type(holder)
					holder.show_message("<span style=\"color:blue\"><strong>Your right leg [pick("magically ", "weirdly ", "suddenly ", "grodily ", "")]becomes [r_leg]!</strong></span>")
					if (user)
						logTheThing("admin", user, holder, "replaced %target%'s right leg with [new_type]")
					. ++
			if (.)
				holder.set_body_icon_dirty()
			return
		return FALSE

/mob/living/carbon/human/proc/is_changeling()
	return get_ability_holder(/abilityHolder/changeling)

/mob/living/carbon/human/proc/is_vampire()
	return get_ability_holder(/abilityHolder/vampire)

/mob/living/carbon/human/disposing()
	if (mutantrace)
		mutantrace.dispose()
		mutantrace = null
	target = null
	if (limbs)
		limbs.dispose()
		limbs = null
	if (organHolder)
		organHolder.dispose()
		organHolder = null
	..()

// death

/mob/living/carbon/human/Del()
	for (var/obj/item/parts/HP in src)
		HP.holder = null
	for (var/obj/item/organ/O in src)
		O.donor = null
	for (var/obj/item/implant/I in src)
		I.implanted = null
		I.owner = null
		I.former_implantee = null
	..()

/mob/living/carbon/human/death(gibbed)
	if (stat == 2)
		return

	if (healths)
		healths.icon_state = "health5"

	if (health_mon)
		health_mon.icon_state = "-1"

	need_update_item_abilities = 1
	stat = 2
	dizziness = 0
	jitteriness = 0

	remove_ailments()

	// kill our facehugger
	for (var/mob/living/critter/facehugger/F in contents)
		F.death()
		break

	for (var/obj/item/implant/health/H in implant)
		if (istype(H) && !H.reported_death)
			DEBUG_MESSAGE("[src] calling to report death")
			H.death_alert()

	#ifdef DATALOGGER
	game_stats.Increment("deaths")
	#endif

	//The unkillable man just respawns nearby! Oh no!
	if (unkillable || spell_soulguard)
		if (unkillable && mind.dnr) //Unless they have dnr set in which case rip for good
			logTheThing("combat", src, null, "was about to be respawned (Unkillable) but had DNR set.")
			if (!gibbed)
				gib()
			boutput(src, "<span style=\"color:red\">The shield hisses and buzzes grumpily! It's almost as if you have some sort of option set that prevents you from coming back to life. Fancy that.</span>")
			var/obj/item/unkill_shield/U = new /obj/item/unkill_shield
			U.set_loc(loc)
		else
			logTheThing("combat", src, null, "respawns ([spell_soulguard ? "Soul Guard" : "Unkillable"])")
			unkillable_respawn ()

	if (traitHolder.hasTrait("soggy"))
		unequip_all()
		gib()
		return

	//Zombies just rise again (after a delay)! Oh my!
	if (mutantrace && mutantrace.onDeath())
		return

	if (bioHolder && bioHolder.HasEffect("revenant"))
		var/bioEffect/hidden/revenant/R = bioHolder.GetEffect("revenant")
		R.RevenantDeath()

	if (!gibbed)
		var/abilityHolder/changeling/C = get_ability_holder(/abilityHolder/changeling)
	//Changelings' heads pop off and crawl away - but only if they're not gibbed and have some spare DNA points. Oy vey!
		if (C)
			if (C.points >= 10)
				var/mind/M = mind
				emote("deathgasp")
				visible_message("<span style=\"color:red\"><strong>[src]</strong> begins to grow another head!</span>")
				src.show_text("<strong>We begin to grow a headspider...</strong>", "blue")
				sleep(200)
				if (M && M.current)
					M.current.show_text("<strong>We released a headspider, using up some of our DNA reserves.</strong>", "blue")
				visible_message("<span style=\"color:red\"><strong>[src]</strong> grows a head, which sprouts legs and wanders off, looking for food!</span>")
				//make a headspider, have it crawl to find a host, give the host the disease, hand control to the player again afterwards
				var/obj/critter/headspider/HS = new /obj/critter/headspider(get_turf(src))
				C.points = max(0, C.points - 10) // This stuff isn't free, you know.
				HS.owner = M //In case we ghosted ourselves then the body won't hold the mind. Bad times.
				HS.changeling = C
				remove_ability_holder(/abilityHolder/changeling/)
				spawn (0)
					if (client) ghostize()

				logTheThing("combat", src, null, "became a headspider at [log_loc(src)].")

				HS.process() //A little kickstart to get you out into the big world (and some chump), li'l guy! O7

				return

			else boutput(src, "You try to release a headspider but don't have enough DNA points (requires 10)!")

		emote("deathgasp") //let the world KNOW WE ARE DEAD

		if (!mutantrace) // wow fucking racist
			modify_christmas_cheer(-7)

		canmove = 0
		lying = 1
		var/h = hand
		hand = 0
		drop_item()
		hand = 1
		drop_item()
		set_clothing_icon_dirty()
		hand = h

		if (istype(wear_suit, /obj/item/clothing/suit/armor/suicide_bomb))
			var/obj/item/clothing/suit/armor/suicide_bomb/A = wear_suit
			A.trigger(src)

		next_decomp_time = world.time + rand(480,900)*10

	var/tod = time2text(world.realtime,"hh:mm:ss") //weasellos time of death patch

	if (mind) // I think this is kinda important (Convair880).
		if (src.mind.special_role == "mindslave")
			remove_mindslave_status(src, "mslave", "death")
		else if (mind.special_role == "vampthrall")
			remove_mindslave_status(src, "vthrall", "death")
		else if (mind.master)
			remove_mindslave_status(src, "otherslave", "death")
		mind.store_memory("Time of death: [tod]", 0)
	logTheThing("combat", src, null, "dies at [log_loc(src)].")
	//icon_state = "dead"

	if (!suiciding)
		if (emergency_shuttle.location == 1)
			unlock_medal("HUMANOID MUST NOT ESCAPE", 1)

		if (handcuffed)
			unlock_medal("Fell down the stairs", 1)

		if (ticker && ticker.mode && istype(ticker.mode, /game_mode/revolution))
			var/game_mode/revolution/R = ticker.mode
			if (mind && (mind in R.revolutionaries)) // maybe add a check to see if they've been de-revved?
				unlock_medal("Expendable", 1)

		if (burning > 66)
			unlock_medal("Black and Blue", 1)

	ticker.mode.check_win()

	#ifdef RESTART_WHEN_ALL_DEAD
	var/cancel
	for (var/mob/M in mobs)
		if (M.client && !M.stat)
			cancel = 1
			break

	if (!cancel && !abandon_allowed)
		spawn (50)
			cancel = 0
			for (var/mob/M in mobs)
				if (M.client && !M.stat)
					cancel = 1
					break

			if (!cancel && !abandon_allowed)
				boutput(world, "<strong>Everyone is dead! Resetting in 30 seconds!</strong>")

				spawn (300)
					logTheThing("diary", null, null, "Rebooting because of no live players", "game")
					Reboot_server()
	#endif
	return ..(gibbed)

//Unkillable respawn proc, also used by soulguard now
// Also for removing antagonist status. New mob required to get rid of old-style, mob-specific antagonist verbs (Convair880).
/mob/living/carbon/human/proc/unkillable_respawn (var/antag_removal = 0)
	if (!antag_removal && bioHolder && bioHolder.HasEffect("revenant"))
		return

	var/turf/reappear_turf = get_turf(src)
	if (!antag_removal)
		for (var/turf/simulated/floor/S in orange(7))
			if (S == reappear_turf) continue
			if (prob(50)) //Try to appear on a turf other than the one we die on.
				reappear_turf = S
				break

	if (!antag_removal && spell_soulguard)
		boutput(src, "<span style=\"color:blue\">Your Soulguard enchantment activates and saves you...</span>")
		reappear_turf = pick(wizardstart)

	////////////////Set up the new body./////////////////

	var/mob/living/carbon/human/newbody = new()
	newbody.set_loc(reappear_turf)

	newbody.real_name = real_name

	// These necessities (organs/limbs/inventory) are bad enough. I don't care about specific damage values etc.
	// Antag status removal doesn't happen very often (Convair880).
	if (antag_removal)
		transfer_mob_inventory(src, newbody, 1, 1, 1) // There's a spawn (20) in that proc.
		if (stat == 2)
			newbody.stat = 2

	if (!antag_removal) // We don't want changeling etc ability holders (Convair880).
		newbody.abilityHolder = abilityHolder
		if (newbody.abilityHolder)
			newbody.abilityHolder.transferOwnership(newbody)
	abilityHolder = null

	if (!antag_removal && unkillable) // Doesn't work properly for half the antagonist types anyway (Convair880).
		newbody.unkillable = 1

	if (bioHolder)
		newbody.bioHolder.CopyOther(src.bioHolder)
		if (!antag_removal && spell_soulguard)
			newbody.bioHolder.RemoveAllEffects()

	// Prone to causing runtimes, don't enable.
/*	if (mutantrace && !spell_soulguard)
		newbody.mutantrace = new src.mutantrace.type(newbody)*/

	if (mind) //Mind transfer also handles key transfer.
		if (antag_removal)
			// Ugly but necessary until I can figure out a better to do this or every antagonist has been moved to ability holders.
			// Transfering it directly to the new mob DOESN'T dispose of certain antagonist-specific verbs (Convair880).
			var/mob/dead/observer/O_temp = new/mob/dead/observer(src)
			mind.transfer_to(O_temp)
			O_temp.mind.transfer_to(newbody)
			qdel(O_temp)
		else
			mind.transfer_to(newbody)
	else //Oh welp, still need to move that key!
		newbody.key = key

	////////////Now play the degibbing animation and move them to the turf.////////////////

	if (!antag_removal)
		var/atom/movable/overlay/animation = new(reappear_turf)
		animation.icon = 'icons/mob/mob.dmi'
		animation.master = src
		animation.icon_state = "ungibbed"
		unkillable = 0 //Don't want this lying around to repeatedly die or whatever.
		spell_soulguard = 0 // clear this as well
		src = null //Detach this, what if we get deleted before the animation ends??
		spawn (7) //Length of animation.
			newbody.set_loc(animation.loc)
			qdel(animation)
	else
		unkillable = 0
		spell_soulguard = 0
		invisibility = 20
		spawn (22) // Has to at least match the organ/limb replacement stuff (Convair880).
			if (src) qdel(src)

	return

// emote

/mob/living/carbon/human/emote(var/act, var/voluntary = 0)
	var/param = null

	for (var/uid in pathogens)
		var/pathogen/P = pathogens[uid]
		if (P.onemote(act))
			return

	if (!bioHolder) bioHolder = new/bioHolder( src )

	if (bioHolder.HasEffect("revenant"))
		visible_message("<span style=\"color:red\">[src] makes [pick("a rude", "an eldritch", "a", "an eerie", "an otherworldly", "a netherly", "a spooky")] gesture!</span>")
		return

	if (findtext(act, " ", 1, null))
		var/t1 = findtext(act, " ", 1, null)
		param = copytext(act, t1 + 1, length(act) + 1)
		act = copytext(act, 1, t1)

	var/muzzled = istype(wear_mask, /obj/item/clothing/mask/muzzle)
	var/m_type = 1

	for (var/obj/item/implant/I in src)
		if (I.implanted)
			I.trigger(act, src)

	var/message = null
	if (mutantrace)
		message = mutantrace.emote(act)
	if (!message)
		switch (lowertext(act))
			if ("custom")
				if (client)
					var/input = sanitize(html_encode(input("Choose an emote to display.")))
					var/input2 = input("Is this a visible or audible emote?") in list("Visible","Audible")
					if (input2 == "Visible") m_type = 1
					else if (input2 == "Audible") m_type = 2
					else
						alert("Unable to use this emote, must be either audible or visible.")
						return
					message = "<strong>[src]</strong> [input]"

			if ("customv")
				if (!param)
					return
				param = sanitize(html_encode(param))
				message = "<strong>[src]</strong> [param]"
				m_type = 1

			if ("customh")
				if (!param)
					return
				param = sanitize(html_encode(param))
				message = "<strong>[src]</strong> [param]"
				m_type = 2

			if ("me")
				if (!param)
					return
				param = sanitize(html_encode(param))
				message = "<strong>[src]</strong> [param]"
				m_type = 1 // default to visible

			if ("give")
				if (!restrained())
					if (!emote_check(voluntary, 50))
						return
					var/obj/item/thing = equipped()
					if (!thing)
						if (l_hand)
							thing = l_hand
						else if (r_hand)
							thing = r_hand

					if (thing)
						var/mob/living/carbon/human/H = null
						if (param)
							for (var/mob/living/carbon/human/M in view(1, src))
								if (ckey(param) == ckey(M.name))
									H = M
									break
						else
							var/list/possible_recipients = list()
							for (var/mob/living/carbon/human/M in view(1, src))
								possible_recipients += M
							if (possible_recipients.len)
								H = input(src, "Who would you like to hand your [thing] to?", "Choice") as null|anything in possible_recipients

						if (!istype(H))
							return

						if (alert(H, "[src] offers [his_or_her(src)] [thing] to you. Do you accept it?", "Choice", "Yes", "No") == "Yes")
							if (!thing || !H || !(get_dist(src, H) <= 1) || thing.loc != src || restrained())
								return
							if (bioHolder && bioHolder.HasEffect("clumsy") && prob(50))
								message = "<strong>[src]</strong> tries to hand [thing] to [H], but [src] drops it!"
								u_equip(thing)
								thing.set_loc(loc)
							else if (H.bioHolder && H.bioHolder.HasEffect("clumsy") && prob(50))
								message = "<strong>[src]</strong> tries to hand [thing] to [H], but [H] drops it!"
								u_equip(thing)
								thing.set_loc(H.loc)
							else if (H.put_in_hand(thing))
								message = "<strong>[src]</strong> hands [thing] to [H]."
								u_equip(thing)
								H.update_clothing()
							else
								message = "<strong>[src]</strong> tries to hand [thing] to [H], but [H]'s hands are full!"
						else
							show_text("[H] declines your offer.")
				else
					message = "<strong>[src]</strong> struggles to move."
				m_type = 1

			if ("help")
				show_text("To use emotes, simply enter 'me (emote)' in the input bar. Certain emotes can be targeted at other characters - to do this, enter 'me (emote) (name of character)' without the brackets.")
				show_text("For a list of all emotes, use 'me list'. For a list of basic emotes, use 'me listbasic'. For a list of emotes that can be targeted, use 'me listtarget'.")

			if ("listbasic")
				show_text("smile, grin, smirk, frown, scowl, grimace, sulk, pout, blink, drool, shrug, tremble, quiver, shiver, shudder, shake, \
				think, ponder, clap, flap, aflap, laugh, chuckle, giggle, chortle, guffaw, cough, hiccup, sigh, mumble, grumble, groan, moan, sneeze, \
				sniff, snore, whimper, yawn, choke, gasp, weep, sob, wail, whine, gurgle, gargle, blush, flinch, blink_r, eyebrow, shakehead, shakebutt, \
				pale, flipout, rage, shame, raisehand, crackknuckles, stretch, rude, cry, retch, raspberry, tantrum, gesticulate, wgesticulate, smug, \
				nosepick, flex, facepalm, panic, snap, airquote, twitch, twitch_v, faint, deathgasp, signal, wink, collapse, dance, scream, \
				burp, fart, monologue, contemplate, custom")

			if ("listtarget")
				show_text("salute, bow, hug, wave, glare, stare, look, leer, nod, tweak, flipoff, doubleflip, shakefist, handshake, daps, slap, boggle")

			if ("suicide")
				show_text("Suicide is a command, not an emote.  Please type 'suicide' in the input bar at the bottom of the game window to kill yourself.", "red")

	//april fools start

			if ("inhale")
				if (!manualbreathing)
					show_text("You are already breathing!")
					return
				if (breathstate)
					show_text("You just breathed in, try breathing out next dummy!")
					return
				show_text("You breathe in.")
				breathtimer = 0
				breathstate = 1

			if ("exhale")
				if (!manualbreathing)
					show_text("You are already breathing!")
					return
				if (!breathstate)
					show_text("You just breathed out, try breathing in next silly!")
					return
				show_text("You breathe out.")
				breathstate = 0

			if ("closeeyes")
				if (!manualblinking)
					show_text("Why would you want to do that?")
					return
				if (blinkstate)
					show_text("You just closed your eyes, try opening them now dumbo!")
					return
				show_text("You close your eyes.")
				blinkstate = 1
				blinktimer = 0

			if ("openeyes")
				if (!manualblinking)
					show_text("Your eyes are already open!")
					return
				if (!blinkstate)
					show_text("Your eyes are already open, try closing them next moron!")
					return
				show_text("You open your eyes.")
				blinkstate = 0

	//april fools end

			if ("birdwell")
				if ((client && client.holder) && emote_check(voluntary, 50))
					message = "<strong>[src]</strong> birdwells."
					playsound(loc, "sound/vox/birdwell.ogg", 50, 1)
				else
					show_text("Unusable emote '[act]'. 'Me help' for a list.", "blue")
					return

			if ("uguu")
				if (istype(wear_mask, /obj/item/clothing/mask/anime) && !stat)

					message = "<strong>[src]</strong> uguus!"
					m_type = 2
					if (narrator_mode)
						playsound(get_turf(src), 'sound/vox/uguu.ogg', 80, 0, 0, get_age_pitch())
					else
						playsound(get_turf(src), 'sound/misc/uguu.ogg', 80, 0, 0, get_age_pitch())
					spawn (10)
						gib()
						new /obj/item/clothing/mask/anime(loc)
						return
				else
					show_text("You just don't feel kawaii enough to uguu right now!", "red")
					return

			if ("twirl", "spin", "juggle")
				if (!restrained())
					if (emote_check(voluntary, 25))
						m_type = 1

						// clown juggling
						if ((mind && mind.assigned_role == "Clown") || can_juggle)
							var/obj/item/thing = equipped()
							if (!thing)
								if (l_hand)
									thing = l_hand
								else if (r_hand)
									thing = r_hand
							if (thing)
								if (juggling())
									if (prob(src.juggling.len * 5)) // might drop stuff while already juggling things
										drop_juggle()
									else
										add_juggle(thing)
								else
									add_juggle(thing)
							else
								message = "<strong>[src]</strong> wiggles \his fingers a bit.[prob(10) ? " Weird." : null]"

						// everyone else
						else
							var/obj/item/thing = equipped()
							if (!thing)
								if (l_hand)
									thing = l_hand
								else if (r_hand)
									thing = r_hand
							if (thing)
								if ((bioHolder && bioHolder.HasEffect("clumsy") && prob(50)) || (reagents && prob(reagents.get_reagent_amount("ethanol") / 2)) || prob(5))
									message = "<strong>[src]</strong> [pick("spins", "twirls")] [thing] around in [his_or_her(src)] hand, and drops it right on the ground.[prob(10) ? " What an oaf." : null]"
									u_equip(thing)
									thing.set_loc(loc)
								else
									message = "<strong>[src]</strong> [pick("spins", "twirls")] [thing] around in [his_or_her(src)] hand."
									thing.on_spin_emote(src)
							else
								message = "<strong>[src]</strong> wiggles [his_or_her(src)] fingers a bit.[prob(10) ? " Weird." : null]"
				else
					message = "<strong>[src]</strong> struggles to move."

			if ("tip")
				if (!restrained() && !stat)
					if (istype(head, /obj/item/clothing/head/fedora))
						var/obj/item/clothing/head/fedora/hat = head
						message = "<strong>[src]</strong> tips \his [hat] and [pick("winks", "smiles", "grins", "smirks")].<br><strong>[src]</strong> [pick("says", "states", "articulates", "implies", "proclaims", "proclamates", "promulgates", "exclaims", "exclamates", "extols", "predicates")], &quot;M'lady.&quot;"
						spawn (10)
							hat.set_loc(loc)
							head = null
							gib()
					else if (istype(head, /obj/item/clothing/head) && !istype(head, /obj/item/clothing/head/fedora))
						show_text("This hat just isn't [pick("fancy", "suave", "manly", "sexerific", "majestic", "euphoric")] enough for that!", "red")
						return
					else
						show_text("You can't tip a hat you don't have!", "red")
						return

			if ("hatstomp", "stomphat")
				if (!restrained())
					var/obj/item/clothing/head/helmet/HoS/hat = find_type_in_hand(/obj/item/clothing/head/helmet/HoS)
					var/hat_or_beret = null
					var/already_stomped = null // store the picked phrase in here
					var/on_head = 0

					if (!hat) // if the find_type_in_hand() returned 0 earlier
						if (istype(head, /obj/item/clothing/head/helmet/HoS)) // maybe it's on our head?
							hat = head
							on_head = 1
						else // if not then never mind
							return
					if (hat.icon_state == "hosberet" || hat.icon_state == "hosberet-smash") // does it have one of the beret icons?
						hat_or_beret = "beret" // call it a beret
					else // otherwise?
						hat_or_beret = "hat" // call it a hat. this should cover cases where the hat somehow doesn't have either hosberet or hoscap
					if (hat.icon_state == "hosberet-smash" || hat.icon_state == "hoscap-smash") // has it been smashed already?
						already_stomped = pick(" That [hat_or_beret] has seen better days.", " That [hat_or_beret] is looking pretty shabby.", " How much more abuse can that [hat_or_beret] take?", " It looks kinda ripped up now.") // then add some extra flavor text

					// the actual messages are generated here
					if (on_head)
						message = "<strong>[src]</strong> yanks \his [hat_or_beret] off \his head, throws it on the floor and stomps on it![already_stomped]\
						<br><strong>[src]</strong> grumbles, \"<em>rasmn frasmn grmmn[prob(1) ? " dick dastardly" : null]</em>.\""
					else
						message = "<strong>[src]</strong> throws \his [hat_or_beret] on the floor and stomps on it![already_stomped]\
						<br><strong>[src]</strong> grumbles, \"<em>rasmn frasmn grmmn</em>.\""

					if (hat_or_beret == "beret")
						hat.icon_state = "hosberet-smash" // make sure it looks smushed!
					else
						hat.icon_state = "hoscap-smash"
					drop_from_slot(hat) // we're done here, drop that hat!

				else
					message = "<strong>[src]</strong> tries to move \his arm and grumbles."
				m_type = 1

			if ("handpuppet")
				message = "<strong>[src]</strong> throws their voice, badly, as they flap their thumb and index finger like some sort of lips.[prob(50) ? "  Perhaps they're off their meds?" : null]"
				m_type = 1

			if ("smile","grin","smirk","frown","scowl","grimace","sulk","pout","blink","drool","shrug","tremble","quiver","shiver","shudder","shake","think","ponder","contemplate","grump")
				// basic visible single-word emotes
				message = "<strong>[src]</strong> [act]s."
				m_type = 1

			if (":)")
				message = "<strong>[src]</strong> smiles."
				m_type = 1

			if (":(")
				message = "<strong>[src]</strong> frowns."
				m_type = 1

			if (":d", ">:)") // the switch is lowertext()ed so this is what :D would be
				message = "<strong>[src]</strong> grins."
				m_type = 1

			if ("d:", "dx") // same as above for D: and DX
				message = "<strong>[src]</strong> grimaces."
				m_type = 1

			if (">:(")
				message = "<strong>[src]</strong> scowls."
				m_type = 1

			if (":j")
				message = "<strong>[src]</strong> smirks."
				m_type = 1

			if (":i")
				message = "<strong>[src]</strong> grumps."
				m_type = 1

			if (":|")
				message = "<strong>[src]</strong> stares."
				m_type = 1

			if ("xd")
				message = "<strong>[src]</strong> laughs."
				m_type = 1

			if (":c")
				message = "<strong>[src]</strong> pouts."
				m_type = 1

			if ("clap")
				// basic visible single-word emotes - unusable while restrained
				if (!restrained())
					message = "<strong>[src]</strong> [lowertext(act)]s."
				else
					message = "<strong>[src]</strong> struggles to move."
				m_type = 1

			if ("cough","hiccup","sigh","mumble","grumble","groan","moan","sneeze","sniff","snore","whimper","yawn","choke","gasp","weep","sob","wail","whine","gurgle","gargle")
				// basic audible single-word emotes
				if (!muzzled)
					if (lowertext(act) == "sigh" && prob(1)) act = "singh" //1% chance to change sigh to singh. a bad joke for drsingh fans.
					message = "<strong>[src]</strong> [act]s."
				else
					message = "<strong>[src]</strong> tries to make a noise."
				m_type = 2

			if ("laugh","chuckle","giggle","chortle","guffaw","cackle")
				if (!muzzled)
					message = "<strong>[src]</strong> [act]s."
					if (sound_list_laugh && sound_list_laugh.len)
						playsound(loc, pick(sound_list_laugh), 80, 0, 0, get_age_pitch())
				else
					message = "<strong>[src]</strong> tries to make a noise."
				m_type = 2

			if ("salute","bow","hug","wave","glare","stare","look","leer","nod")
				// visible targeted emotes
				if (!restrained())
					var/M = null
					if (param)
						for (var/mob/A in view(null, null))
							if (ckey(param) == ckey(A.name))
								M = A
								break
					if (!M)
						param = null

					act = lowertext(act)
					if (param)
						switch(act)
							if ("bow","wave","nod")
								message = "<strong>[src]</strong> [act]s to [param]."
							if ("glare","stare","look","leer")
								message = "<strong>[src]</strong> [act]s at [param]."
							else
								message = "<strong>[src]</strong> [act]s [param]."
					else
						switch(act)
							if ("hug")
								message = "<strong>[src]</strong> [act]s \himself."
							else
								message = "<strong>[src]</strong> [act]s."
				else
					message = "<strong>[src]</strong> struggles to move."
				m_type = 1

			// basic emotes that change the wording a bit

			if ("blush")
				message = "<strong>[src]</strong> blushes."
				m_type = 1

			if ("flinch")
				message = "<strong>[src]</strong> flinches."
				m_type = 1

			if ("blink_r")
				message = "<strong>[src]</strong> blinks rapidly."
				m_type = 1

			if ("eyebrow","raiseeyebrow")
				message = "<strong>[src]</strong> raises an eyebrow."
				m_type = 1

			if ("shakehead","smh")
				message = "<strong>[src]</strong> shakes \his head."
				m_type = 1

			if ("shakebutt","shakebooty","shakeass","twerk")
				message = "<strong>[src]</strong> shakes \his ass!"
				m_type = 1

				spawn (5)
					var/beeMax = 15
					for (var/obj/critter/domestic_bee/responseBee in range(5, src))
						if (!responseBee.alive)
							continue

						if (beeMax-- < 0)
							break

						if (prob(75))
							responseBee.visible_message("<strong>[responseBee]</strong> buzzes [pick("in a confused manner", "perplexedly", "in a perplexed manner")].")
						else
							responseBee.visible_message("<strong>[responseBee]</strong> can't understand [src]'s accent!")

			if ("pale")
				message = "<strong>[src]</strong> goes pale for a second."
				m_type = 1

			if ("flipout")
				message = "<strong>[src]</strong> flips the fuck out!"
				m_type = 1

			if ("rage","fury","angry")
				message = "<strong>[src]</strong> becomes utterly furious!"
				m_type = 1

			if ("shame","hanghead")
				message = "<strong>[src]</strong> hangs \his head in shame."
				m_type = 1

			// basic emotes with alternates for restraints

			if ("flap")
				if (!restrained())
					message = "<strong>[src]</strong> flaps \his arms!"
					if (sound_list_flap && sound_list_flap.len)
						playsound(loc, pick(sound_list_flap), 80, 0, 0, get_age_pitch())
				else
					message = "<strong>[src]</strong> writhes!"
				m_type = 1

			if ("aflap")
				if (!restrained())
					message = "<strong>[src]</strong> flaps \his arms ANGRILY!"
					if (sound_list_flap && sound_list_flap.len)
						playsound(loc, pick(sound_list_flap), 80, 0, 0, get_age_pitch())
				else
					message = "<strong>[src]</strong> writhes angrily!"
				m_type = 1

			if ("raisehand")
				if (!restrained()) message = "<strong>[src]</strong> raises a hand."
				else message = "<strong>[src]</strong> tries to move \his arm."
				m_type = 1

			if ("crackknuckles","knuckles")
				if (!restrained()) message = "<strong>[src]</strong> cracks \his knuckles."
				else message = "<strong>[src]</strong> irritably shuffles around."
				m_type = 1

			if ("stretch")
				if (!restrained()) message = "<strong>[src]</strong> stretches."
				else message = "<strong>[src]</strong> writhes around slowly."
				m_type = 1

			if ("rude")
				if (!restrained()) message = "<strong>[src]</strong> makes a rude gesture."
				else message = "<strong>[src]</strong> tries to move \his arm."
				m_type = 1

			if ("cry")
				if (!muzzled) message = "<strong>[src]</strong> cries."
				else message = "<strong>[src]</strong> makes an odd noise. A tear runs down \his face."
				m_type = 2

			if ("retch","gag")
				if (!muzzled) message = "<strong>[src]</strong> retches in disgust!"
				else message = "<strong>[src]</strong> makes a strange choking sound."
				m_type = 2

			if ("raspberry")
				if (!muzzled) message = "<strong>[src]</strong> blows a raspberry."
				else message = "<strong>[src]</strong> slobbers all over \himself."
				m_type = 2

			if ("tantrum")
				if (!restrained()) message = "<strong>[src]</strong> throws a tantrum!"
				else message = "<strong>[src]</strong> starts wriggling around furiously!"
				m_type = 1

			if ("gesticulate")
				if (!restrained()) message = "<strong>[src]</strong> gesticulates."
				else message = "<strong>[src]</strong> wriggles around a lot."
				m_type = 1

			if ("wgesticulate")
				if (!restrained()) message = "<strong>[src]</strong> gesticulates wildly."
				else message = "<strong>[src]</strong> enthusiastically wriggles around a lot!"
				m_type = 1

			if ("smug")
				if (!restrained()) message = "<strong>[src]</strong> folds \his arms and smirks broadly, making a self-satisfied \"heh\"."
				else message = "<strong>[src]</strong> shuffles a bit and smirks broadly, emitting a rather self-satisfied noise."
				m_type = 1

			if ("nosepick","picknose")
				if (!restrained()) message = "<strong>[src]</strong> picks \his nose."
				else message = "<strong>[src]</strong> sniffs and scrunches \his face up irritably."
				m_type = 1

			if ("flex","flexmuscles")
				if (!restrained())
					var/roboarms = limbs && istype(limbs.r_arm, /obj/item/parts/robot_parts) && istype(limbs.l_arm, /obj/item/parts/robot_parts)
					if (roboarms) message = "<strong>[src]</strong> flexes \his powerful robotic muscles."
					else message = "<strong>[src]</strong> flexes \his muscles."
				else message = "<strong>[src]</strong> tries to stretch \his arms."
				m_type = 1

			if ("facepalm")
				if (!restrained()) message = "<strong>[src]</strong> places \his hand on \his face in exasperation."
				else message = "<strong>[src]</strong> looks rather exasperated."
				m_type = 1

			if ("panic","freakout")
				if (!restrained()) message = "<strong>[src]</strong> enters a state of hysterical panic!"
				else message = "<strong>[src]</strong> starts writhing around in manic terror!"
				m_type = 1

			// targeted emotes

			if ("tweak","tweaknipples","tweaknips","nippletweak")
				if (!restrained())
					var/M = null
					if (param)
						for (var/mob/A in view(1, src))
							if (ckey(param) == ckey(A.name))
								M = A
								break
					if (!M)
						param = null

					if (param)
						message = "<strong>[src]</strong> tweaks [param]'s nipples."
					else
						message = "<strong>[src]</strong> tweaks \his nipples."
				m_type = 1

			if ("flipoff","flipbird","middlefinger")
				m_type = 1
				if (!restrained())
					var/M = null
					if (param)
						for (var/mob/A in view(null, null))
							if (ckey(param) == ckey(A.name))
								M = A
								break
					if (M) message = "<strong>[src]</strong> flips off [M]."
					else message = "<strong>[src]</strong> raises \his middle finger."
				else message = "<strong>[src]</strong> scowls and tries to move \his arm."

			if ("doubleflip","doubledeuce","doublebird","flip2")
				m_type = 1
				if (!restrained())
					var/M = null
					if (param)
						for (var/mob/A in view(null, null))
							if (ckey(param) == ckey(A.name))
								M = A
								break
					if (M) message = "<strong>[src]</strong> gives [M] the double deuce!"
					else message = "<strong>[src]</strong> raises both of \his middle fingers."
				else message = "<strong>[src]</strong> scowls and tries to move \his arms."

			if ("boggle")
				m_type = 1
				var/M = null
				if (param)
					for (var/mob/A in view(null, null))
						if (ckey(param) == ckey(A.name))
							M = A
							break
				if (M) message = "<strong>[src]</strong> boggles at [M]'s stupidity."
				else message = "<strong>[src]</strong> boggles at the stupidity of it all."

			if ("shakefist")
				m_type = 1
				if (!restrained())
					var/M = null
					if (param)
						for (var/mob/A in view(null, null))
							if (ckey(param) == ckey(A.name))
								M = A
								break
					if (M) message = "<strong>[src]</strong> angrily shakes \his fist at [M]!"
					else message = "<strong>[src]</strong> angrily shakes \his fist!"
				else message = "<strong>[src]</strong> tries to move \his arm angrily!"

			if ("handshake","shakehand","shakehands")
				m_type = 1
				if (!restrained() && !r_hand)
					var/mob/M = null
					if (param)
						for (var/mob/A in view(1, null))
							if (ckey(param) == ckey(A.name))
								M = A
								break
					if (M == src) M = null

					if (M)
						if (M.canmove && !M.r_hand && !M.restrained()) message = "<strong>[src]</strong> shakes hands with [M]."
						else message = "<strong>[src]</strong> holds out \his hand to [M]."

			if ("daps","dap")
				m_type = 1
				if (!restrained())
					var/M = null
					if (param)
						for (var/mob/A in view(1, null))
							if (ckey(param) == ckey(A.name))
								M = A
								break
					if (M) message = "<strong>[src]</strong> gives daps to [M]."
					else message = "<strong>[src]</strong> sadly can't find anybody to give daps to, and daps \himself. Shameful."
				else message = "<strong>[src]</strong> wriggles around a bit."

			if ("slap","bitchslap","smack")
				m_type = 1
				if (!restrained())
					if (emote_check(voluntary))
						if (bioHolder.HasEffect("chime_snaps"))
							sound_snap = 'sound/misc/glass_step.ogg'
						var/M = null
						if (param)
							for (var/mob/A in view(1, null))
								if (ckey(param) == ckey(A.name))
									M = A
									break
						if (M) message = "<strong>[src]</strong> slaps [M] across the face! Ouch!"
						else
							message = "<strong>[src]</strong> slaps \himself!"
							TakeDamage("head", 0, 4, 0, DAMAGE_BURN)
						playsound(loc, sound_snap, 100, 1)
				else message = "<strong>[src]</strong> lurches forward strangely and aggressively!"

			// emotes that do STUFF! or are complex in some way i guess

			if ("snap","snapfingers","fingersnap","click","clickfingers")
				if (!restrained())
					if (emote_check(voluntary))
						if (bioHolder.HasEffect("chime_snaps"))
							sound_fingersnap = 'sound/machines/chime_5.ogg'
							sound_snap = 'sound/misc/glass_step.ogg'
						if (prob(5))
							message = "<font color=red><strong>[src]</strong> snaps \his fingers RIGHT OFF!</font>"
							/*
							if (bioHolder)
								bioHolder.AddEffect("[hand ? "left" : "right"]_arm")
							else
							*/
							random_brute_damage(src, 20)
							if (narrator_mode)
								playsound(loc, 'sound/vox/break.ogg', 100, 1)
							else
								playsound(loc, sound_snap, 100, 1)
						else
							message = "<strong>[src]</strong> snaps \his fingers."
							if (narrator_mode)
								playsound(loc, 'sound/vox/deeoo.ogg', 50, 1)
							else
								playsound(loc, sound_fingersnap, 50, 1)

			if ("airquote","airquotes")
				if (param)
					param = strip_html(param, 200)
					message = "<strong>[src]</strong> sneers, \"Ah yes, \"[param]\". We have dismissed that claim.\""
					m_type = 2
				else
					message = "<strong>[src]</strong> makes air quotes with \his fingers."
					m_type = 1

			if ("twitch")
				message = "<strong>[src]</strong> twitches."
				m_type = 1
				spawn (0)
					var/old_x = pixel_x
					var/old_y = pixel_y
					pixel_x += rand(-2,2)
					pixel_y += rand(-1,1)
					sleep(2)
					pixel_x = old_x
					pixel_y = old_y

			if ("twitch_v","twitch_s")
				message = "<strong>[src]</strong> twitches violently."
				m_type = 1
				spawn (0)
					var/old_x = pixel_x
					var/old_y = pixel_y
					pixel_x += rand(-3,3)
					pixel_y += rand(-1,1)
					sleep(2)
					pixel_x = old_x
					pixel_y = old_y

			if ("faint")
				message = "<strong>[src]</strong> faints."
				sleeping = 1
				m_type = 1

			if ("deathgasp")
				if (prob(15) && !is_changeling() && stat != 2) message = "<strong>[src]</strong> seizes up and falls limp, peeking out of one eye sneakily."
				else message = "<strong>[src]</strong> seizes up and falls limp, \his eyes dead and lifeless..."
				m_type = 1

			if ("johnny")
				var/M
				if (param) M = adminscrub(param)
				if (!M) param = null
				else
					message = "<strong>[src]</strong> says, \"[M], please. He had a family.\" [name] takes a drag from a cigarette and blows \his name out in smoke."
					m_type = 2

			if ("point")
				if (!restrained())
					var/mob/M = null
					if (param)
						for (var/atom/A as mob|obj|turf|area in view(null, null))
							if (ckey(param) == ckey(A.name))
								M = A
								break

					if (!M)
						message = "<strong>[src]</strong> points."
					else
						point(M)

					if (M)
						message = "<strong>[src]</strong> points to [M]."
					else
				m_type = 1

			if ("signal")
				if (!restrained())
					var/t1 = min( max( round(text2num(param)), 1), 10)
					if (isnum(t1))
						if (t1 <= 5 && (!r_hand || !l_hand))
							message = "<strong>[src]</strong> raises [t1] finger\s."
						else if (t1 <= 10 && (!r_hand && !l_hand))
							message = "<strong>[src]</strong> raises [t1] finger\s."
				m_type = 1

			if ("wink")
				for (var/obj/item/clothing/C in get_equipped_items())
					if ((locate(/obj/item/gun/kinetic/derringer) in C) != null)
						var/obj/item/gun/kinetic/derringer/D = (locate(/obj/item/gun/kinetic/derringer) in C)
						var/drophand = (hand == 0 ? slot_r_hand : slot_l_hand)
						drop_item()
						D.set_loc(src)
						equip_if_possible(D, drophand)
						visible_message("<span style=\"color:red\"><strong>[src] pulls a derringer out of \the [C]!</strong></span>")
						playsound(loc, "rustle", 60, 1)
						break

				message = "<strong>[src]</strong> winks."
				m_type = 1

			if ("collapse")
				if (!paralysis)
					paralysis += 2
				message = "<strong>[src]</strong> collapses!"
				m_type = 2

			if ("dance", "boogie")
				if (emote_check(voluntary, 50))
					if (iswizard(src) && prob(10))
						message = pick("<span style=\"color:red\"><strong>[src]</strong> breaks out the most unreal dance move you've ever seen!</span>", "<span style=\"color:red\"><strong>[src]'s</strong> dance move borders on the goddamn diabolical!</span>")
						say("GHET DAUN!")
						animate_flash_color_fill(src,"#5C0E80", 1, 10)
						animate_levitate(src, 1, 10)
						spawn (0) // some movement to make it look cooler
							for (var/i = 0, i < 10, i++)
								dir = turn(dir, 90)
								sleep(2)

						var/effects/system/spark_spread/s = unpool(/effects/system/spark_spread)
						s.set_up(3, 1, src)
						s.start()

					else
						if (!restrained())
							message = "<strong>[src]</strong> pulls both arms outwards in front of their chest and pumps them behind their back, then repeats this motion in a smaller range of motion down to their hips two times once more all while sliding their legs in a faux walking motion, claps their hands together in front of them while both their knees knock together, pumps their arms downward, pronating their wrists and abducting their fingers outward while crossing their legs back and forth, repeats this motion again two times while keeping their shoulders low and hunching over, proceeding to finger gun with right hand with left hand bent on their hip while looking directly forward and putting their left leg forward then crossing their arms and leaning back a little while bending their knees at an angle."
							playsound(get_turf(src), 'sound/effects/defaultdance.ogg', 100)
							spawn (0)
								for (var/v in 1 to 4)
									canmove = FALSE
									for (var/i = 0, i < 4, i++)
										pixel_x+= 2
										dir = turn(dir, 90)
										sleep(0.2 SECONDS)
									for (var/i = 0, i < 4, i++)
										pixel_x-= 2
										dir = turn(dir, 90)
										sleep(0.2 SECONDS)
									canmove = TRUE

							spawn (5)
								var/beeMax = 15
								for (var/obj/critter/domestic_bee/responseBee in range(7, src))
									if (!responseBee.alive)
										continue

									if (beeMax-- < 0)
										break

									responseBee.dance_response()

							spawn (5)
								var/parrotMax = 15
								for (var/obj/critter/parrot/responseParrot in range(7, src))
									if (!responseParrot.alive)
										continue
									if (parrotMax-- < 0)
										break
									responseParrot.dance_response()

							if (reagents)
								if (reagents.has_reagent("ants") && reagents.has_reagent("mutagen"))
									var/ant_amt = reagents.get_reagent_amount("ants")
									var/mut_amt = reagents.get_reagent_amount("mutagen")
									reagents.del_reagent("ants")
									reagents.del_reagent("mutagen")
									reagents.add_reagent("spiders", ant_amt + mut_amt)
									boutput(src, "<span style=\"color:blue\">The ants arachnify.</span>")
									playsound(get_turf(src), "sound/effects/bubbles.ogg", 80, 1)

			if ("flip")
				if (emote_check(voluntary, 50) && !shrunk)

					//TODO: space flipping
					//if ((!restrained()) && (!lying) && (istype(loc, /turf/space)))
					//	message = "<strong>[src]</strong> does a flip!"
					//	if (prob(50))
					//		animate(src, transform = turn(GetPooledMatrix(), 90), time = 1, loop = -1)
					//		animate(transform = turn(GetPooledMatrix(), 180), time = 1, loop = -1)
					//		animate(transform = turn(GetPooledMatrix(), 270), time = 1, loop = -1)
					//		animate(transform = turn(GetPooledMatrix(), 360), time = 1, loop = -1)
					//	else
					//		animate(src, transform = turn(GetPooledMatrix(), -90), time = 1, loop = -1)
					//		animate(transform = turn(GetPooledMatrix(), -180), time = 1, loop = -1)
					//		animate(transform = turn(GetPooledMatrix(), -270), time = 1, loop = -1)
					//		animate(transform = turn(GetPooledMatrix(), -360), time = 1, loop = -1)
					if (istype(loc,/obj))
						var/obj/container = loc
						boutput(src, "<span style=\"color:red\">You leap and slam your head against the inside of [container]! Ouch!</span>")
						paralysis += 2
						weakened += 4
						container.visible_message("<span style=\"color:red\"><strong>[container]</strong> emits a loud thump and rattles a bit.</span>")
						playsound(loc, "sound/effects/bang.ogg", 50, 1)
						var/wiggle = 6
						while (wiggle > 0)
							wiggle--
							container.pixel_x = rand(-3,3)
							container.pixel_y = rand(-3,3)
							sleep(1)
						container.pixel_x = 0
						container.pixel_y = 0
						if (prob(33))
							if (istype(container, /obj/storage))
								var/obj/storage/C = container
								if (C.can_flip_bust == 1)
									boutput(src, "<span style=\"color:red\">[C] [pick("cracks","bends","shakes","groans")].</span>")
									C.bust_out()

					if (!iswrestler(src))
						if (stamina <= STAMINA_FLIP_COST || (stamina - STAMINA_FLIP_COST) <= 0)
							boutput(src, "<span style=\"color:red\">You fall over, panting and wheezing.</span>")
							message = "<span style=\"color:red\"><strong>[src]</strong> falls over, panting and wheezing.</span>"
							weakened += 2
							set_stamina(min(1, stamina))
							emote_allowed = 0
							goto showmessage

					for (var/mob/living/M in oview(3))
						if (M == src)
							continue
						if (on_chair == 1)
							var/found_chair = 0
							for (var/obj/stool/chair/C in loc.contents)
								found_chair = 1
							if (!found_chair)
								pixel_y = 0
								anchored = 0
								on_chair = 0
								buckled = null
								break
							if (!istype(usr.equipped(), /obj/item/grab))
								//set_loc(M.loc)
								pixel_y = 0
								buckled = null
								anchored = 0
								. = 1
								if (M && M.loc != loc) // just in case, so the user doesn't fall into nullspace if they fly at a person mid-gibbing or whatever
									var/list/flipLine = getline(src, M)
									for (var/turf/T in flipLine)
										if (!istype(loc, /turf) || T.density || LinkBlockedWithAccess(loc, T))
											message = "<span style=\"color:red\"><strong>[src]</strong> does a flying flip...into the ground.  Like a big doofus.</span>"
											weakened = 5
											. = 0
											break
										else
											set_loc(T)

								emote("scream")
								on_chair = 0

								if (!iswrestler(src) && traitHolder && !traitHolder.hasTrait("glasscannon"))
									remove_stamina(STAMINA_FLIP_COST)
									stamina_stun()

								if (.)
									playsound(loc, "sound/effects/fleshbr1.ogg", 75, 1)
									message = "<span style=\"color:red\"><strong>[src]</strong> does a flying flip into [M]!</span>"
									logTheThing("combat", src, M, "[src] chairflips into %target%, [showCoords(M.x, M.y, M.z)].")
									M.lastattacker = src
									M.lastattackertime = world.time

									if (iswrestler(src))
										if (prob(33))
											M.ex_act(3)
										else
											random_brute_damage(M, 25)
											M.weakened = max(M.weakened, 3)
											M.stunned = max(M.stunned, 5)
									else
										random_brute_damage(M, 10)
										M.weakened = max(M.weakened, 2)
										M.stunned = max(M.stunned, 3)
										weakened = max(weakened, 1)
										stunned = max(weakened, 2)

							if (!reagents.has_reagent("fliptonium"))
								if (prob(50))
									animate_spin(src, "R", 1, 0)
								else
									animate_spin(src, "L", 1, 0)

						break
					if ((!istype(loc, /turf/space)) && (!on_chair))
						if (!lying)
							if ((restrained()) || (reagents && reagents.get_reagent_amount("ethanol") > 30) || (bioHolder.HasEffect("clumsy")))
								message = pick("<strong>[src]</strong> tries to flip, but stumbles!", "<strong>[src]</strong> slips!")
								weakened += 4
								TakeDamage("head", 8, 0, 0, DAMAGE_BLUNT)
							if (bioHolder.HasEffect("fat"))
								message = pick("<strong>[src]</strong> tries to flip, but stumbles!", "<strong>[src]</strong> collapses under their own weight!")
								weakened += 2
								TakeDamage("head", 4, 0, 0, DAMAGE_BLUNT)
							else
								message = "<strong>[src]</strong> does a flip!"
							if (!reagents.has_reagent("fliptonium"))
								if (prob(50))
									animate_spin(src, "R", 1, 0)
								else
									animate_spin(src, "L", 1, 0)
							for (var/obj/table/T in oview(1, null))
								if ((!istype(usr.equipped(), /obj/item/grab)) && (dir == get_dir(src, T)))
									if (iswrestler(src))
										T.density = 0
										if (LinkBlockedWithAccess(loc, T.loc))
											T.density = 1
											continue
										T.density = 1
										var/turf/newloc = T.loc
										set_loc(newloc)
										message = "<strong>[src]</strong> flips onto [T]!"
							for (var/mob/living/M in view(1, null))
								var/obj/item/grab/G = usr.equipped()
								if (M == src)
									continue
								if (istype(usr.equipped(), /obj/item/grab))
									if (G.state >= 1)
										var/turf/newloc = loc
										G.affecting.set_loc(newloc)
										if (!G.affecting.reagents.has_reagent("fliptonium"))
											if (prob(50))
												animate_spin(G.affecting, "R", 1, 0)
											else
												animate_spin(G.affecting, "R", 1, 0)

										if (!iswrestler(src) && traitHolder && !traitHolder.hasTrait("glasscannon"))
											remove_stamina(STAMINA_FLIP_COST)
											stamina_stun()

										emote("scream")
										message = "<span style=\"color:red\"><strong>[src]</strong> suplexes [G.affecting]!</span>"
										logTheThing("combat", src, G.affecting, "suplexes %target%")
										M.lastattacker = src
										M.lastattackertime = world.time
										if (iswrestler(src))
											if (prob(50))
												M.ex_act(3) // this is hilariously overpowered, but WHATEVER!!!
											else
												G.affecting.stunned += 4
												G.affecting.weakened += 4
												G.affecting.TakeDamage("head", 10, 0, 0, DAMAGE_BLUNT)
											playsound(loc, "sound/effects/fleshbr1.ogg", 75, 1)
/*										if (bioHolder.HasEffect("hulk"))
											playsound(loc, "sound/effects/splat.ogg", 75, 1)
											G.affecting.gib()
*/
										else
											if (!iswrestler(src))
												weakened += 3
											G.affecting.weakened += 4
											G.affecting.TakeDamage("head", 10, 0, 0, DAMAGE_BLUNT)
											playsound(loc, "sound/effects/fleshbr1.ogg", 75, 1)
									if (G.state < 1)
										var/turf/oldloc = loc
										var/turf/newloc = G.affecting.loc
										set_loc(newloc)
										G.affecting.set_loc(oldloc)
										message = "<strong>[src]</strong> flips over [G.affecting]!"
								else if (reagents && reagents.get_reagent_amount("ethanol") > 10)
									if (!iswrestler(src) && traitHolder && !traitHolder.hasTrait("glasscannon"))
										remove_stamina(STAMINA_FLIP_COST)
										stamina_stun()

									message = "<span style=\"color:red\"><strong>[src]</strong> flips into [M]!</span>"
									logTheThing("combat", src, M, "flips into %target%")
									weakened += 4
									TakeDamage("head", 4, 0, 0, DAMAGE_BLUNT)
									M.weakened += 2
									M.TakeDamage("head", 2, 0, 0, DAMAGE_BLUNT)
									playsound(loc, pick(sounds_punch), 100, 1)
									var/turf/newloc = M.loc
									set_loc(newloc)
								else
									message = "<strong>[src]</strong> flips in [M]'s general direction."
								break
					if (lying)
						message = "<strong>[src]</strong> flops on the floor like a fish."

			if ("scream")
				if (emote_check(voluntary, 50))
					if (!muzzled)
						message = "<strong>[src]</strong> screams!"
						m_type = 2
						if (narrator_mode)
							playsound(loc, 'sound/vox/scream.ogg', 80, 0, 0, get_age_pitch())
						else if (sound_list_scream && sound_list_scream.len)
							playsound(loc, pick(sound_list_scream), 80, 0, 0, get_age_pitch())
						else
							if (gender == MALE)
								playsound(get_turf(src), sound_malescream, 80, 0, 0, get_age_pitch())
							else
								playsound(get_turf(src), sound_femalescream, 80, 0, 0, get_age_pitch())
						spawn (5)
							var/possumMax = 15
							for (var/obj/critter/opossum/responsePossum in range(4, src))
								if (!responsePossum.alive)
									continue
								if (possumMax-- < 0)
									break
								responsePossum.CritterDeath() // startled into playing dead!
					else
						message = "<strong>[src]</strong> makes a very loud noise."
						m_type = 2

			if ("burp")
				if (emote_check(voluntary))
					if ((charges >= 1) && (!muzzled))
						for (var/mob/O in viewers(src, null))
							O.show_message("<strong>[src]</strong> burps.")
						for (var/mob/M in oview(1))
							var/effects/system/spark_spread/s = unpool(/effects/system/spark_spread)
							s.set_up(3, 1, src)
							s.start()
							boutput(M, "<span style=\"color:blue\">BZZZZZZZZZZZT!</span>")
							M.TakeDamage("chest", 0, 20, 0, DAMAGE_BURN)
							charges -= 1
							if (narrator_mode)
								playsound(loc, "sound/vox/bloop.ogg", 100, 0, 0, get_age_pitch())
							else
								playsound(get_turf(src), sound_burp, 100, 0, 0, get_age_pitch())
							return
					else if ((charges >= 1) && (muzzled))
						for (var/mob/O in viewers(src, null))
							O.show_message("<strong>[src]</strong> vomits in \his own mouth a bit.")
						TakeDamage("head", 0, 50, 0, DAMAGE_BURN)
						charges -=1
						return
					else if ((charges < 1) && (!muzzled))
						message = "<strong>[src]</strong> burps."
						m_type = 2
						if (narrator_mode)
							playsound(loc, "sound/vox/bloop.ogg", 100, 0, 0, get_age_pitch())
						else
							playsound(get_turf(src), sound_burp, 100, 0, 0, get_age_pitch())
					else
						message = "<strong>[src]</strong> vomits in \his own mouth a bit."
						m_type = 2

			if ("fart")
				if (emote_check(voluntary) && farting_allowed && (!reagents || !reagents.has_reagent("anti_fart")))
					if (organHolder && !organHolder.butt)
						m_type = 1
						message = "<strong>[src]</strong> grunts for a moment. Nothing happens."
					else
						m_type = 2
						var/fart_on_other = 0
						for (var/mob/living/M in loc)
							if (M == src || !M.lying)
								continue
							message = "<span style=\"color:red\"><strong>[src]</strong> farts in [M]'s face!</span>"
							if (sims)
								sims.affectMotive("fun", 4)
							fart_on_other = 1
							break
						for (var/obj/item/storage/bible/B in loc)
							B.suicide(src)
							fart_on_other = 1
							break
						for (var/obj/item/book_kinginyellow/K in loc)
							K.suicide(src)
							fart_on_other = 1
							break
						if (!fart_on_other)
							switch(rand(1, 42))
								if (1) message = "<strong>[src]</strong> lets out a girly little 'toot' from \his butt."
								if (2) message = "<strong>[src]</strong> farts loudly!"
								if (3) message = "<strong>[src]</strong> lets one rip!"
								if (4) message = "<strong>[src]</strong> farts! It sounds wet and smells like rotten eggs."
								if (5) message = "<strong>[src]</strong> farts robustly!"
								if (6) message = "<strong>[src]</strong> farted! It smells like something died."
								if (7) message = "<strong>[src]</strong> farts like a muppet!"
								if (8) message = "<strong>[src]</strong> defiles the station's air supply."
								if (9) message = "<strong>[src]</strong> farts a ten second long fart."
								if (10) message = "<strong>[src]</strong> groans and moans, farting like the world depended on it."
								if (11) message = "<strong>[src]</strong> breaks wind!"
								if (12) message = "<strong>[src]</strong> expels intestinal gas through the anus."
								if (13) message = "<strong>[src]</strong> release an audible discharge of intestinal gas."
								if (14) message = "<strong>[src]</strong> is a farting motherfucker!!!"
								if (15) message = "<strong>[src]</strong> suffers from flatulence!"
								if (16) message = "<strong>[src]</strong> releases flatus."
								if (17) message = "<strong>[src]</strong> releases methane."
								if (18) message = "<strong>[src]</strong> farts up a storm."
								if (19) message = "<strong>[src]</strong> farts. It smells like Soylent Surprise!"
								if (20) message = "<strong>[src]</strong> farts. It smells like pizza!"
								if (21) message = "<strong>[src]</strong> farts. It smells like George Melons' perfume!"
								if (22) message = "<strong>[src]</strong> farts. It smells like the kitchen!"
								if (23) message = "<strong>[src]</strong> farts. It smells like medbay in here now!"
								if (24) message = "<strong>[src]</strong> farts. It smells like the bridge in here now!"
								if (25) message = "<strong>[src]</strong> farts like a pubby!"
								if (26) message = "<strong>[src]</strong> farts like a goone!"
								if (27) message = "<strong>[src]</strong> sharts! That's just nasty."
								if (28) message = "<strong>[src]</strong> farts delicately."
								if (29) message = "<strong>[src]</strong> farts timidly."
								if (30) message = "<strong>[src]</strong> farts very, very quietly. The stench is OVERPOWERING."
								if (31) message = "<strong>[src]</strong> farts egregiously."
								if (32) message = "<strong>[src]</strong> farts voraciously."
								if (33) message = "<strong>[src]</strong> farts cantankerously."
								if (34) message = "<strong>[src]</strong> fart in \he own mouth. A shameful [src]."
								if (35) message = "<strong>[src]</strong> farts out pure plasma! <span style=\"color:red\"><strong>FUCK!</strong></span>"
								if (36) message = "<strong>[src]</strong> farts out pure oxygen. What the fuck did \he eat?"
								if (37) message = "<strong>[src]</strong> breaks wind noisily!"
								if (38) message = "<strong>[src]</strong> releases gas with the power of the gods! The very station trembles!!"
								if (39) message = "<strong>[src] <span style=\"color:red\">f</span><span style=\"color:blue\">a</span>r<span style=\"color:red\">t</span><span style=\"color:blue\">s</span>!</strong>"
								if (40) message = "<strong>[src]</strong> laughs! \His breath smells like a fart."
								if (41) message = "<strong>[src]</strong> farts. You can faintly hear a harmonica..."
								if (42) message = "<strong>[src]</strong> farts. It might have been the Citizen Kane of farts."
						if (bioHolder && bioHolder.HasEffect("toxic_farts"))
							message = "<span style=\"color:red\"><strong>[src] [pick("unleashes","rips","blasts")] \a [pick("truly","utterly","devastatingly","shockingly")] [pick("hideous","horrendous","horrific","heinous","horrible")] fart!</strong></span>"
							spawn (0)
								new /obj/effects/fart_cloud(get_turf(src),src)
						if (iscluwne(src))
							playsound(loc, 'sound/misc/Poo.ogg', 50, 1)
						else if (organHolder && organHolder.butt && istype(organHolder.butt, /obj/item/clothing/head/butt/cyberbutt))
							playsound(loc, 'sound/misc/poo2_robot.ogg', 100, 1, 0, get_age_pitch())
						else
							if (narrator_mode)
								playsound(loc, 'sound/vox/fart.ogg', 100, 0, 0, get_age_pitch())
							else
								playsound(get_turf(src), sound_fart, 100, 0, 0, get_age_pitch())

						for (var/mob/living/carbon/human/M in viewers(src, null))
							if (!M.stat && M.get_brain_damage() >= 60)
								spawn (10)
									if (prob(20))
										switch(pick(1,2,3))
											if (1)
												M.say("[M == src ? "i" : name] made a fart!!")
											if (2)
												M.emote("giggle")
											if (3)
												M.emote("clap")

						remove_stamina(STAMINA_DEFAULT_FART_COST)
						stamina_stun()
						#ifdef DATALOGGER
						game_stats.Increment("farts")
						#endif

			if ("pee", "piss", "urinate")
				if (emote_check(voluntary))
					if (sims)
						var/bladder = sims.getValue("bladder")
						var/obj/item/storage/toilet/toilet = locate() in loc
						if (bladder > 75)
							boutput(src, "<span style=\"color:blue\">You don't need to go right now.</span>")
							return
						else if (bladder > 50)
							if (!toilet)
								if (wear_suit || w_uniform)
									boutput(src, "<span style=\"color:red\">You don't feel desperate enough to piss into your [w_uniform ? "uniform" : "suit"].</span>")
								else
									boutput(src, "<span style=\"color:red\">You don't feel desperate enough to piss on the floor.</span>")
								return
							else
								if (wear_suit || w_uniform)
									message = "<strong>[src]</strong> unzips their pants and pees in the toilet."
								else
									message = "<strong>[src]</strong> pees in the toilet."
								toilet.clogged += 0.10
								sims.affectMotive("bladder", 100)
								sims.affectMotive("hygiene", -5)
						else if (bladder > 25)
							if ((wear_suit || w_uniform) && !toilet)
								boutput(src, "<span style=\"color:red\">You don't feel desperate enough to piss into your [w_uniform ? "uniform" : "suit"].</span>")
								return
							else if (toilet)
								if (wear_suit || w_uniform)
									message = "<strong>[src]</strong> unzips their pants and pees in the toilet."
								else
									message = "<strong>[src]</strong> pees in the toilet."
								toilet.clogged += 0.10
								sims.affectMotive("bladder", 100)
								sims.affectMotive("hygiene", -5)
							else
								message = "<strong>[src]</strong> pisses all over the floor!"
								urinate()
								sims.affectMotive("bladder", 100)
								sims.affectMotive("hygiene", -50)
						else
							if (toilet)
								if (wear_suit || w_uniform)
									message = "<strong>[src]</strong> unzips their pants and pees in the toilet."
								else
									message = "<strong>[src]</strong> pees in the toilet."
								toilet.clogged += 0.10
								sims.affectMotive("bladder", 100)
								sims.affectMotive("hygiene", -5)
							else
								if (wear_suit || w_uniform)
									message = "<strong>[src]</strong> pisses all over themselves!"
									sims.affectMotive("bladder", 100)
									sims.affectMotive("hygiene", -100)
									if (w_uniform)
										w_uniform.name = "piss-soaked [initial(w_uniform.name)]"
									else
										wear_suit.name = "piss-soaked [initial(wear_suit.name)]"
								else
									message = "<strong>[src]</strong> pisses all over the floor!"
									urinate()
									sims.affectMotive("bladder", 100)
									sims.affectMotive("hygiene", -50)
					else if (urine < 1)
						message = "<strong>[src]</strong> pees themselves a little bit."
					else if ((locate(/obj/item/storage/toilet) in loc) && (buckled != null) && (urine >= 2))
						for (var/obj/item/storage/toilet/T in loc)
							message = pick("<strong>[src]</strong> unzips their pants and pees in the toilet.", "<strong>[src]</strong> empties their bladder.", "<span style=\"color:blue\">Ahhh, sweet relief.</span>")
							urine = 0
							T.clogged += 0.10
							break
					else
						message = pick("<strong>[src]</strong> unzips their pants and pees on the floor.", "<strong>[src]</strong> pisses all over the floor!", "<strong>[src]</strong> makes a big piss puddle on the floor.")
						urine--
						urinate()
					for (var/mob/living/carbon/human/M in viewers(src, null))
						if (!M.stat && M.get_brain_damage() >= 60)
							spawn (10)
								if (prob(20))
									switch(pick(1,2,3))
										if (1) M.say("[M == src ? "i" : name] made pee pee, heeheeheeeeeeee!")
										if (2) M.emote("giggle")
										if (3) M.emote("clap")

			if ("poo", "poop", "shit", "crap")
				if (emote_check(voluntary))
					message = "<strong>[src]</strong> grunts for a moment. [prob(1) ? "Something" : "Nothing"] happens."

			if ("monologue")
				m_type = 2
				if (mind && mind.assigned_role == "Detective")
					if (istype(l_hand, /obj/item/grab))
						if (istype(l_hand:affecting, /mob/living/carbon/human))
							message = "<strong>[src]</strong> says, \"I'll stare the bastard in the face as he screams to God, and I'll laugh harder when he whimpers like a baby. And when [l_hand:affecting]'s eyes go dead, the hell I send him to will seem like heaven after what I've done to him.\""
					else if (istype(r_hand, /obj/item/grab))
						if (istype(r_hand:affecting, /mob/living/carbon/human))
							message = "<strong>[src]</strong> says, \"I'll stare the bastard in the face as he screams to God, and I'll laugh harder when he whimpers like a baby. And when [r_hand:affecting]'s eyes go dead, the hell I send him to will seem like heaven after what I've done to him.\""
					else if (istype(src.loc.loc, /area/station/security/detectives_office))
						message = "<strong>[src]</strong> says, \"As I looked out the door of my office, I realised it was a night when you didn't know your friends but strangers looked familiar. A night like this, the smartest thing to do is nothing: stay home. It was like the wind carried people along with it. But I had to get out there.\""
					else if (istype(src.loc.loc, /area/station/maintenance))
						message = "<strong>[src]</strong> says, \"The dark maintenance corridoors of this place were always the same, home to the most shady characters you could ever imagine. Walk down the right back alley in [station_name()], and you can find anything.\""
					else if (istype(src.loc.loc, /area/station/hydroponics))
						message = "<strong>[src]</strong> says, \"A gang of space farmers growing psilocybin mushrooms, cannabis, and of course those goddamned george melons. A shady bunch, whose wiles had earned them the trust of many. The Chef. The Barman. But not me. No, their charms don't work on a man of values and principles.\""
					else if (istype(src.loc.loc, /area/station/mailroom))
						message = "<strong>[src]</strong> says, \"The post office, an unused room habited by a brainless monkey, a cynical postman, and now, me. I've never trusted postal workers, with their crisp blue suits and their peaked caps. There's never any mail sent, excepting the ticking packages I gotta defuse up in the bridge.\""
					else if (istype(src.loc.loc, /area/centcom))
						message = "<strong>[src]</strong> says, \"Central Command. I was tired as hell but I could afford to be tired now... I needed it to be morning. I wanted to hear doors opening, cars start, and human voices talking about the Space Olympics. I wanted to make sure there were still folks out there facing life with nothing up their sleeves but their arms. They didn't know it yet, but they had a better shot at happiness and a fair shake than they did yesterday.\""
					else if (istype(src.loc.loc, /area/station/chapel))
						message = "<strong>[src]</strong> says, \"The self-pontificating bastard who calls himself our chaplain conducts worship here. If you can call the summoning of an angry god who pelts us with toolboxes, bolts of lightning, and occasionally rips our bodies in twain 'worship'.\""
					else if (istype(src.loc.loc, /area/station/bridge))
						message = "<strong>[src]</strong> says, \"The bridge. The home of the Captain and Head of Personnel. I tried to tell myself I was the sturdy leg in our little triangle. I was worried it was true.\""
					else if (istype(src.loc.loc, /area/station/security/main))
						message = "<strong>[src]</strong> says, \"I had dreams of being security before I got into the detective game. I wanted to meet stimulating and interesting people of an ancient space culture, and kill them. I wanted to be the first kid on my ship to get a confirmed kill.\""
					else if (istype(src.loc.loc, /area/station/crew_quarters/bar))
						message = "<strong>[src]</strong> says, \"The station bar, full of the best examples of lowlifes and drunks I'll ever find. I need a drink though, and there are no better places to find a beer than here.\""
					else if (istype(src.loc.loc, /area/station/medical))
						message = "<strong>[src]</strong> says, \"Medical. In truth it's full of the biggest bunch of cut throats on the station, most would rather cut you up than sow you up, but if I've got a slug in my ass, I don't have much choice.\""
					else if (istype(src.loc.loc, /area/station/hallway/primary))
						message = "<strong>[src]</strong> says, \"The halls of the station assault my nostrils like a week old meal left festering in the sink. A thug around every corner, and reason enough themselves to keep my gun in my hand.\""
					else if (istype(src.loc.loc, /area/station/hallway/secondary/exit))
						message = "<strong>[src]</strong> says, \"The only way off this hellhole and it's the one place I don't want to be, but sometimes you have to show your friends that you're worth a damn. Sometimes that means dying, sometimes it means killing a whole lot of people to escape alive.\""
					else if (istype(src.loc.loc, /area/station/hallway/secondary/entry))
						message = "<strong>[src]</strong> says, \"The entrance to [station_name()]. You will never find a more wretched hive of scum and villainy. I must be cautious.\""
					else if (istype(src.loc.loc, /area/station/engine))
						message = "<strong>[src]</strong> says, \"The churning, hellish heart of the station that just can't help missing the beat. Full of the dregs of society, and not the right place to be caught unwanted. I better watch my back.\""
					else if (istype(src.loc.loc, /area/station/maintenance/disposal))
						message = "<strong>[src]</strong> says, \"Disposal. Usually bloodied, full of grey-suited corpses and broken windows. Down here, you can hear the quiet moaning of the station itself. It's like it's mourning. Mourning better days long gone, like assistants through these pipes.\""
					else if (istype(src.loc.loc, /area/station/crew_quarters/cafeteria))
						message = "<strong>[src]</strong> says, \"A place to eat, but not an appealing one. I've heard rumours about this place, and if there's one thing I know, it's that it's not normal to eat people.\""
					else if (istype(wear_mask, /obj/item/clothing/mask/cigarette))
						message = "<strong>[src]</strong> takes a drag on \his cigarette, surveying the scene around them carefullly."
					else
						message = "<strong>[src]</strong> looks uneasy, like [gender == MALE ? "" : "s"]he's missing a vital part of h[gender == MALE ? "im" : "er"]self. [gender == MALE ? "H" : "Sh"]e needs a smoke badly."

				else
					message = "<strong>[src]</strong> tries to say something clever, but just can't pull it off looking like that."

			if ("miranda")
				if (emote_check(voluntary, 50))
					if (mind && (mind.assigned_role in list("Captain", "Head of Personnel", "Head of Security", "Security Officer", "Detective", "Vice Officer", "Regional Director", "Inspector")))
						recite_miranda()
			else
				show_text("Unusable emote '[act]'. 'Me help' for a list.", "blue")
				return

	showmessage
	if (message)
		logTheThing("say", src, null, "EMOTE: [message]")
		if (m_type & 1)
			for (var/mob/O in viewers(src, null))
				O.show_message(message, m_type)
		else if (m_type & 2)
			for (var/mob/O in hearers(src, null))
				O.show_message(message, m_type)
		else if (!isturf(loc))
			var/atom/A = loc
			for (var/mob/O in A.contents)
				O.show_message(message, m_type)

/mob/living/carbon/human/get_desc()

	if (bioHolder && bioHolder.HasEffect("examine_stopper"))
		return "<br><span style=\"color:red\">You can't seem to make yourself look at [name] long enough to observe anything!</span>"

	if (simple_examine || isghostdrone(usr))
		return

	. = ""
	if (usr.stat == 0)
		. += "<br><span style=\"color:blue\">You look closely at <strong>[name]</strong>.</span>"
		var/distance = get_dist(usr, src)
		sleep(distance + 1)
	if (!istype(usr, /mob/dead/target_observer))
		if (get_dist(usr, src) > 7 && (!usr.client || !usr.client.holder || usr.client.holder.state != 2))
			return "[.]<br><span style=\"color:red\"><strong>[name]</strong> is too far away to see clearly.</span>"


	. +=  "<br><span style=\"color:blue\">*---------*</span>"
	//. +=  "<br><span style=\"color:blue\">This is <strong>[name]</strong>!</span>"

	// crappy hack because you can't do \his[src] etc
	var/t_his = his_or_her(src)
	var/t_him = him_or_her(src)
/*	if (gender == MALE)
		t_his = "his"
		t_him = "him"
	else if (gender == FEMALE)
		t_his = "her"
		t_him = "her"
*/
	var/ailment_data/found = find_ailment_by_type(/ailment/disability/memetic_madness)
	if (found)
		if (!ishuman(usr))
			. += "<br><span style=\"color:red\">You can't focus on [t_him], it's like looking through smoked glass.</span>"
			return
		else
			var/mob/living/carbon/human/H = usr
			var/ailment_data/memetic_madness/MM = H.find_ailment_by_type(/ailment/disability/memetic_madness)
			if (istype(MM) && istype(MM.master,/ailment/disability/memetic_madness))
				H.contract_memetic_madness(MM.progenitor)
				return

			. += "<br><span style=\"color:blue\">A servant of His Grace...</span>"

	if (w_uniform)
		if (w_uniform.blood_DNA)
			. += "<br><span style=\"color:red\">[name] is wearing a[w_uniform.blood_DNA ? " bloody " : " "][bicon(w_uniform)] [w_uniform.name]!</span>"
		else
			. += "<br><span style=\"color:blue\">[src.name] is wearing a [bicon(src.w_uniform)] [src.w_uniform.name].</span>"

	if (handcuffed)
		. +=  "<br><span style=\"color:blue\">[name] is [bicon(handcuffed)] handcuffed!</span>"

	if (wear_suit)
		if (wear_suit.blood_DNA)
			. += "<br><span style=\"color:red\">[name] has a[wear_suit.blood_DNA ? " bloody " : " "][bicon(wear_suit)] [wear_suit.name] on!</span>"
		else
			. += "<br><span style=\"color:blue\">[name] has a [bicon(wear_suit)] [wear_suit.name] on.</span>"

	if (ears)
		. += "<br><span style=\"color:blue\">[name] has a [bicon(ears)] [ears.name] by [t_his] mouth.</span>"

	if (head)
		if (head.blood_DNA)
			. += "<br><span style=\"color:red\">[src.name] has a[src.head.blood_DNA ? " bloody " : " "][bicon(src.head)] [src.head.name] on [t_his] head!</span>"
		else
			. += "<br><span style=\"color:blue\">[src.name] has a [bicon(src.head)] [src.head.name] on [t_his] head.</span>"

	if (wear_mask)
		if (wear_mask.blood_DNA)
			. += "<br><span style=\"color:red\">[name] has a[wear_mask.blood_DNA ? " bloody " : " "][bicon(wear_mask)] [wear_mask.name] on [t_his] face!</span>"
		else
			. += "<br><span style=\"color:blue\">[name] has a [bicon(wear_mask)] [wear_mask.name] on [t_his] face.</span>"

	if (glasses)
		if (((wear_mask && wear_mask.see_face) || !wear_mask) && ((head && head.see_face) || !head))
			if (glasses.blood_DNA)
				. += "<br><span style=\"color:red\">[name] has a[glasses.blood_DNA ? " bloody " : " "][bicon(wear_mask)] [glasses.name] on [t_his] face!</span>"
			else
				. += "<br><span style=\"color:blue\">[name] has a [bicon(glasses)] [glasses.name] on [t_his] face.</span>"

	if (l_hand)
		if (l_hand.blood_DNA)
			. += "<br><span style=\"color:red\">[name] has a[l_hand.blood_DNA ? " bloody " : " "][bicon(l_hand)] [l_hand.name] in [t_his] left hand!</span>"
		else
			. += "<br><span style=\"color:blue\">[name] has a [bicon(l_hand)] [l_hand.name] in [t_his] left hand.</span>"

	if (r_hand)
		if (r_hand.blood_DNA)
			. += "<br><span style=\"color:red\">[name] has a[r_hand.blood_DNA ? " bloody " : " "][bicon(r_hand)] [r_hand.name] in [t_his] right hand!</span>"
		else
			. += "<br><span style=\"color:blue\">[name] has a [bicon(r_hand)] [r_hand.name] in [t_his] right hand.</span>"

	if (belt)
		if (belt.blood_DNA)
			. += "<br><span style=\"color:red\">[src.name] has a[src.belt.blood_DNA ? " bloody " : " "][bicon(src.belt)] [src.belt.name] on [t_his] belt!</span>"
		else
			. += "<br><span style=\"color:blue\">[src.name] has a [bicon(src.belt)] [src.belt.name] on [t_his] belt.</span>"

	if (gloves)
		if (gloves.blood_DNA)
			. += "<br><span style=\"color:red\">[name] has bloody [bicon(gloves)] [gloves.name] on [t_his] hands!</span>"
		else
			. += "<br><span style=\"color:blue\">[name] has [bicon(gloves)] [gloves.name] on [t_his] hands.</span>"
	else if (blood_DNA)
		. += "<br><span style=\"color:red\">[name] has[blood_DNA ? " bloody " : " "]hands!</span>"

	if (back)
		. += "<br><span style=\"color:blue\">[src.name] has a [bicon(src.back)] [src.back.name] on [t_his] back.</span>"

	if (wear_id)
		if (istype(wear_id, /obj/item/card/id))
			if (wear_id:registered != real_name && in_range(src, usr) && prob(10))
				. += "<br><span style=\"color:red\">[name] is wearing [bicon(wear_id)] [wear_id.name] yet doesn't seem to be that person!!!</span>"
			else
				. += "<br><span style=\"color:blue\">[src.name] is wearing [bicon(src.wear_id)] [src.wear_id.name].</span>"
		else if (istype(wear_id, /obj/item/device/pda2) && wear_id:ID_card)
			if (wear_id:ID_card:registered != real_name && in_range(src, usr) && prob(10))
				. += "<br><span style=\"color:red\">[name] is wearing [bicon(wear_id)] [wear_id.name] with [bicon(wear_id:ID_card)] [wear_id:ID_card:name] in it yet doesn't seem to be that person!!!</span>"
			else
				. += "<br><span style=\"color:blue\">[name] is wearing [bicon(wear_id)] [wear_id.name] with [bicon(wear_id:ID_card)] [wear_id:ID_card:name] in it.</span>"

	if (is_jittery)
		switch(jitteriness)
			if (300 to INFINITY)
				. += "<br><span style=\"color:red\">[src] is violently convulsing.</span>"
			if (200 to 300)
				. += "<br><span style=\"color:red\">[src] looks extremely jittery.</span>"
			if (100 to 200)
				. += "<br><span style=\"color:red\">[src] is twitching ever so slightly.</span>"
	if (organHolder)
		var/organHolder/oH = organHolder
		if (oH.brain)
			if (oH.brain.op_stage > 0.0)
				. += "<br><span style=\"color:red\"><strong>[name] has an open incision on [t_his] head!</strong></span>"
		else if (!oH.brain && oH.skull && oH.head)
			. += "<br><span style=\"color:red\"><strong>[name]'s head has been cut open and [t_his] brain is gone!</strong></span>"
		else if (!oH.skull && oH.head)
			. += "<br><span style=\"color:red\"><strong>[name] no longer has a skull in [t_his] head, [t_his] face is just empty skin mush!</strong></span>"
		else if (!oH.head)
			. += "<br><span style=\"color:red\"><strong>[name] has been decapitated!</strong></span>"

		if (oH.head)
			if (((wear_mask && wear_mask.see_face) || !wear_mask) && ((head && head.see_face) || !head))
				if (!oH.right_eye)
					. += "<br><span style=\"color:red\"><strong>[name]'s right eye is missing!</strong></span>"
				if (!oH.left_eye)
					. += "<br><span style=\"color:red\"><strong>[name]'s left eye is missing!</strong></span>"

		if (organHolder.heart)
			if (organHolder.heart.op_stage > 0.0)
				. += "<br><span style=\"color:red\"><strong>[name] has an open incision on [t_his] chest!</strong></span>"
		else
			. += "<br><span style=\"color:red\"><strong>[name]'s chest is cut wide open; [t_his] heart has been removed!</strong></span>"

		if (butt_op_stage > 0)
			if (butt_op_stage >= 4)
				. += "<br><span style=\"color:red\"><strong>[name]'s butt seems to be missing!</strong></span>"
			else
				. += "<br><span style=\"color:red\"><strong>[name] has an open incision on [t_his] butt!</strong></span>"

		if (limbs)
			if (!limbs.l_arm)
				. += "<br><span style=\"color:red\"><strong>[name]'s left arm is completely severed!</strong></span>"
			else if (istype(limbs.l_arm, /obj/item/parts/human_parts/arm/left/item))
				if (limbs.l_arm:remove_object)
					. += "<br><span style=\"color:blue\">[name] has [limbs.l_arm.remove_object] attached as a left arm!</span>"
			if (!limbs.r_arm)
				. += "<br><span style=\"color:red\"><strong>[name]'s right arm is completely severed!</strong></span>"
			else if (istype(limbs.r_arm, /obj/item/parts/human_parts/arm/right/item))
				if (limbs.r_arm:remove_object)
					. += "<br><span style=\"color:blue\">[name] has [limbs.r_arm.remove_object] attached as a right arm!</span>"
			if (!limbs.l_leg)
				. += "<br><span style=\"color:red\"><strong>[name]'s left leg is completely severed!</strong></span>"
			if (!limbs.r_leg)
				. += "<br><span style=\"color:red\"><strong>[name]'s right leg is completely severed!</strong></span>"

	if (bleeding && stat != 2)
		switch (bleeding)
			if (1 to 2)
				. += "<br><span style=\"color:red\">[name] is bleeding a little bit.</span>"
			if (3 to 5)
				. += "<br><span style=\"color:red\"><strong>[name] is bleeding!</strong></span>"
			if (6 to 8)
				. += "<br><span style=\"color:red\"><strong>[name] is bleeding a lot!</strong></span>"
			if (9 to INFINITY)
				. += "<br><span style=\"color:red\"><strong>[name] is bleeding very badly!</strong></span>"

	if (!isvampire(src) && (blood_volume < 500)) // Added a check for vampires (Convair880).
		switch (blood_volume)
			if (-INFINITY to 100)
				. += "<br><span style=\"color:red\"><strong>[name] is extremely pale!</strong></span>"
			if (101 to 300)
				. += "<br><span style=\"color:red\"><strong>[name] is pale!</strong></span>"
			if (301 to 400)
				. += "<br><span style=\"color:red\">[name] is a little pale.</span>"

	var/changeling_fakedeath = 0
	var/abilityHolder/changeling/C = get_ability_holder(/abilityHolder/changeling)
	if (C && C.in_fakedeath)
		changeling_fakedeath = 1

	if ((stat == 2 /*&& !reagents.has_reagent("montaguone") && !reagents.has_reagent("montaguone_extra")*/) || changeling_fakedeath || (reagents.has_reagent("capulettium") && paralysis) || (reagents.has_reagent("capulettium_plus") && weakened))
		if (!decomp_stage)
			. += "<br><span style=\"color:red\">[src] is limp and unresponsive, a dull lifeless look in [t_his] eyes.</span>"
	else
		var/brute = get_brute_damage()
		if (brute)
			if (brute < 30)
				. += "<br><span style=\"color:red\">[name] looks slightly injured!</span>"
			else
				. += "<br><span style=\"color:red\"><strong>[name] looks severely injured!</strong></span>"

		var/burn = get_burn_damage()
		if (burn)
			if (burn < 30)
				. += "<br><span style=\"color:red\">[name] looks slightly burned!</span>"
			else
				. += "<br><span style=\"color:red\"><strong>[name] looks severely burned!</strong></span>"

		if (stat > 0)// && reagents.has_reagent("montaguone")))
			. += "<br><span style=\"color:red\">[name] doesn't seem to be responding to anything around [t_him], [t_his] eyes closed as though asleep.</span>"
		else
			if (get_brain_damage() >= 60)
				. += "<br><span style=\"color:red\">[name] has a stupid expression on [his_or_her(src)] face.</span>"

			if (!client)
				. += "<br>[name] seems to be staring blankly into space."

	switch (decomp_stage)
		if (1)
			. += "<br><span style=\"color:red\">[src] looks bloated and smells a bit rotten!</span>"
		if (2)
			. += "<br><span style=\"color:red\">[src]'s flesh is starting to rot away from [t_his] bones!</span>"
		if (3)
			. += "<br><span style=\"color:red\">[src]'s flesh is almost completely rotten away, revealing parts of [t_his] skeleton!</span>"
		if (4)
			. += "<br><span style=\"color:red\">[src]'s remains are completely skeletonized.</span>"

	if (usr.traitHolder && (usr.traitHolder.hasTrait("observant") || istype(usr, /mob/dead/observer)))
		if (traitHolder && traitHolder.traits.len)
			. += "<br><span style=\"color:blue\">[src] has the following traits:</span>"
			for (var/X in traitHolder.traits)
				var/obj/trait/T = getTraitById(X)
				. += "<br><span style=\"color:blue\">[T.cleanName]</span>"
		else
			. += "<br><span style=\"color:blue\">[src] does not appear to possess any special traits.</span>"

	if (juggling())
		var/items = ""
		var/count = 0
		for (var/obj/O in juggling)
			count ++
			if (juggling.len > 1 && count == juggling.len)
				items += " and [O]"
				continue
			items += ", [O]"
		items = copytext(items, 3)
		. += "<br><span style=\"color:blue\">[src] is juggling [items]!</span>"

	. += "<br><span style=\"color:blue\">*---------*</span>"

	if (get_dist(usr, src) < 4 && ishuman(usr))
		var/mob/living/carbon/human/H = usr
		if (istype(H.glasses, /obj/item/clothing/glasses/healthgoggles))
			var/obj/item/clothing/glasses/healthgoggles/G = H.glasses
			if (G.scan_upgrade && G.health_scan)
				. += "<br><span style='color: red'>Your ProDocs analyze [src]'s vitals.</span><br>[scan_health(src, 0, 0)]"
			update_medical_record(src)

/mob/living/carbon/human/movement_delay()
	var/tally = 0

	if (slowed)
		tally += 10
	if (reagents && reagents.has_reagent("methamphetamine"))
		if (!bioHolder || !bioHolder.HasEffect("revenant"))
			return -1
	if (nodamage)
		return -1

	// health_deficiency is now relative since aliens have a lot more health - Kachnov
	var/health_deficiency = (max_health - health) / (max_health/100)// cogwerks // let's treat this like pain
	if (reagents)
		if (reagents.has_reagent("morphine"))
			health_deficiency -= 50
		if (reagents.has_reagent("salicylic_acid"))
			health_deficiency -= 25
	if (health_deficiency >= 30) tally += (health_deficiency / 25)

	if (wear_suit)
		switch(wear_suit.type)
			if (/obj/item/clothing/suit/straight_jacket)
				tally += 15
			if (/obj/item/clothing/suit/fire)	//	firesuits slow you down a bit
				tally += 1.3
			if (/obj/item/clothing/suit/fire/heavy)	//	firesuits slow you down a bit
				tally += 1.7
			if (/obj/item/clothing/suit/space)
				if (!istype(loc, /turf/space))		//	space suits slow you down a bit unless in space;
					tally += 0.7
			if (/obj/item/clothing/suit/space/captain)
				tally -=0.1
			if (/obj/item/clothing/suit/armor/heavy)
				tally += 3.5
			if (/obj/item/clothing/suit/armor/EOD)
				tally += 2
			if (/obj/item/clothing/suit/armor/ancient) // cogwerks - new evil armor thing
				tally += 2
			if (/obj/item/clothing/suit/space/emerg)
				if (!istype(loc, /turf/space))
					tally += 3.0 // cogwerks - lowered this from 10
			if (/obj/item/clothing/suit/space/suv)
				tally += 1.0

	var/missing_legs = 0
	if (limbs && !limbs.l_leg) missing_legs++
	if (limbs && !limbs.r_leg) missing_legs++
	switch(missing_legs)
		if (0)

			// we aren't meant to wear shoes
			// so give us - 1.0 slowdown either way
			if (ismutt(src) || isxenomorph(src))
				tally -= 1.0
			else
				if (istype(shoes, /obj/item/clothing/shoes))
					if (shoes.chained)
						tally += 15
					else if (istype(src.shoes.type,/obj/item/clothing/shoes/industrial)) // miner boots, split off from the suit
						tally -= 4.0
					else
						tally -= 1.0
				else
					if (shoes)
						tally -= 1.0
		if (1)
			tally += 7

			// we aren't meant to wear shoes
			// so give us - 0.5 slowdown either way
			if (ismutt(src) || isxenomorph(src))
				tally -= 0.5
			else
				if (istype(shoes, /obj/item/clothing/shoes))
					if (istype(src.shoes.type,/obj/item/clothing/shoes/industrial)) // miner boots, split off from the suit
						tally -= 2.0 //less effect if there's only one i guess
					else
						tally -= 0.5
		if (2)
			tally += 15
			var/missing_arms = 0
			if (limbs && !limbs.l_arm) missing_arms++
			if (limbs && !limbs.r_arm) missing_arms++
			switch(missing_arms)
				if (1)
					tally += 15 //can't pull yourself along too well
				if (2)
					tally += 300 //haha good luck

	// effect of our mutantrace
	if (mutantrace)
		tally += mutantrace.movement_delay()

	// divide the movement delay by our STAT_SPEED
	if (stats)
		tally += stats.getSpeedTallyIncrease()

	if (bioHolder)
		if (bioHolder.HasEffect("fat"))
			tally += 1.5
		if (bodytemperature < base_body_temp - (temp_tolerance * 2) && !is_cold_resistant())
			tally += min( ((((base_body_temp - (temp_tolerance * 2)) - bodytemperature) / 10) * 1.75), 10)


		if (limbs && istype(limbs.l_leg, /obj/item/parts/robot_parts/leg/left/treads) && istype(limbs.r_leg, /obj/item/parts/robot_parts/leg/right/treads)) //Treads speed you up a bunch
			tally -= 0.5

		else if (limbs && istype(limbs.l_leg, /obj/item/parts/robot_parts/leg) && istype(limbs.r_leg, /obj/item/parts/robot_parts/leg)) //robot legs speed you up a little
			tally -= 0.4

	for (var/obj/item/I in get_equipped_items())
		tally += I.movement_speed_mod

	if (reagents)
		if (reagents.has_reagent("energydrink"))
			if (tally > 6)
				tally /= 2
			else
				tally -= 3

	if (bioHolder && bioHolder.HasEffect("revenant"))
		tally = max(tally, 3)

	return tally

/mob/living/carbon/human/Stat()
	..()
	statpanel("Status")
	if (client.statpanel == "Status")
		if (client)
			stat("Time Until Payday:", wagesystem.get_banking_timeleft())

		stat(null, " ")
		if (mind)
			if (mind.objectives && istype(mind.objectives, /list))
				for (var/objective/O in mind.objectives)
					if (istype(O, /objective/specialist/stealth))
						stat("Stealth Points:", "[O:score] / [O:min_score]")

		if (internal)
			if (!internal.air_contents)
				qdel(internal)
			else
				stat("Internal Atmosphere Info:", internal.name)
				stat("Tank Pressure:", internal.air_contents.return_pressure())
				stat("Distribution Pressure:", internal.distribute_pressure)

		if (neural_net_account)
			stat(null, " ")
			stat(null, "Neural Net ([neural_net_account.name])")
			stat(null, " ")
			var/list/stuff = neural_net_account.Stat()
			for (var/field in stuff)
				stat(field, stuff[field])

/mob/living/carbon/human/u_equip(obj/item/W as obj)
	if (!W)
		return

	hud.remove_item(W) // eh
	if (W == wear_suit)
		wear_suit = null
		W.unequipped(src)
		update_clothing()
		update_hair_layer()
	else if (W == w_uniform)
		W.unequipped(src)
		W = r_store
		if (W)
			u_equip(W)
			if (W)
				W.set_loc(loc)
				W.dropped(src)
				W.layer = initial(W.layer)
		W = l_store
		if (W)
			u_equip(W)
			if (W)
				W.set_loc(loc)
				W.dropped(src)
				W.layer = initial(W.layer)
		W = wear_id
		if (W)
			u_equip(W)
			if (W)
				W.set_loc(loc)
				W.dropped(src)
				W.layer = initial(W.layer)
		W = belt
		if (W)
			u_equip(W)
			if (W)
				W.set_loc(loc)
				W.dropped(src)
				W.layer = initial(W.layer)
		w_uniform = null
		update_clothing()
	else if (W == gloves)
		W.unequipped(src)
		gloves = null
		update_clothing()
	else if (W == glasses)
		W.unequipped(src)
		glasses = null
		update_clothing()
	else if (W == head)
		W.unequipped(src)
		head = null
		update_clothing()
		update_hair_layer()
	else if (W == ears)
		W.unequipped(src)
		ears = null
		update_clothing()
	else if (W == shoes)
		W.unequipped(src)
		shoes = null
		update_clothing()
	else if (W == belt)
		W.unequipped(src)
		belt = null
		update_clothing()
	else if (W == wear_mask)
		W.unequipped(src)
		if (internal)
			if (internals)
				internals.icon_state = "internal0"
			for (var/obj/ability_button/tank_valve_toggle/T in internal.ability_buttons)
				T.icon_state = "airoff"
			internal = null
		wear_mask = null
		update_clothing()
	else if (W == wear_id)
		W.unequipped(src)
		wear_id = null
		update_clothing()
	else if (W == r_store)
		r_store = null
	else if (W == l_store)
		l_store = null
	else if (W == back)
		W.unequipped(src)
		back = null
		update_clothing()
	else if (W == handcuffed)
		handcuffed = null
		update_clothing()
	else if (W == r_hand)
		r_hand = null
		W.dropped(src)
		update_inhands()
	else if (W == l_hand)
		l_hand = null
		W.dropped(src)
		update_inhands()

/mob/living/carbon/human/action(num)
	if (abilityHolder)
		if (!abilityHolder.actionKey(num)) //If none of the keys were used as ability hotkeys, use it for intents instead.
			switch (num)
				if (1)
					a_intent = INTENT_HELP
					hud.update_intent()
				if (2)
					a_intent = INTENT_DISARM
					hud.update_intent()
				if (3)
					a_intent = INTENT_GRAB
					hud.update_intent()
				if (4)
					a_intent = INTENT_HARM
					hud.update_intent()

///mob/living/carbon/human/click(atom/target, params)

///mob/living/carbon/human/Stat()

/mob/living/carbon/human/proc/toggle_throw_mode()
	if (in_throw_mode)
		throw_mode_off()
	else
		throw_mode_on()

/mob/living/carbon/human/proc/throw_mode_off()
	in_throw_mode = 0
	update_cursor()
	hud.update_throwing()

/mob/living/carbon/human/proc/throw_mode_on()
	in_throw_mode = 1
	update_cursor()
	hud.update_throwing()

/mob/living/carbon/human/proc/throw_item(atom/target)
	throw_mode_off()
	if (usr.stat)
		return

	var/atom/movable/item = equipped()

	if (istype(item, /obj/item) && item:cant_self_remove)
		return

	if (!item) return

	if (istype(item, /obj/item/grab))
		var/obj/item/grab/grab = item
		var/mob/M = grab.affecting
		if (istype(M))
			if (grab.state < 1 && !(M.paralysis || M.weakened || M.stat))
				visible_message("<span style=\"color:red\">[M] stumbles a little!</span>")
				u_equip(grab)
				return
			M.lastattacker = src
			M.lastattackertime = world.time
			u_equip(grab)
			item = M

	u_equip(item)

	item.set_loc(loc)

	// u_equip() already calls item.dropped()
	//if (istype(item, /obj/item))
		//item:dropped(src) // let it know it's been dropped

	//actually throw it!
	if (item)
		item.layer = initial(item.layer)
		visible_message("<span style=\"color:red\">[src] throws [item].</span>")
		if (iscarbon(item))
			var/mob/living/carbon/C = item
			logTheThing("combat", src, C, "throws %target% at [log_loc(src)].")
			if ( ishuman(C) )
				C.weakened = max(weakened, 1)
		else
			// Added log_reagents() call for drinking glasses. Also the location (Convair880).
			logTheThing("combat", src, null, "throws [item] [item.is_open_container() ? "[log_reagents(item)]" : ""] at [log_loc(src)].")
		if (istype(loc, /turf/space)) //they're in space, move em one space in the opposite direction
			inertia_dir = get_dir(target, src)
			step(src, inertia_dir)
		if (istype(item.loc, /turf/space) && istype(item, /mob))
			var/mob/M = item
			M.inertia_dir = get_dir(src,target)
		item.throw_at(target, item.throw_range, item.throw_speed)

/mob/living/carbon/human/click(atom/target, list/params)
	if (in_throw_mode || params.Find("shift"))
		throw_item(target)
		return
	return ..()

/mob/living/carbon/human/update_cursor()
	if ((client && client.check_key("shift")) || in_throw_mode)
		set_cursor('icons/cursors/throw.dmi')
		return
	return ..()
/*
/mob/living/carbon/human/key_down(key)
	if (key == "shift")
		update_cursor()
	..()

/mob/living/carbon/human/key_up(key)
	if (key == "shift")
		update_cursor()
	..()
*/
/mob/living/carbon/human/meteorhit(O as obj)
	if (stat == 2) gib()
	visible_message("<span style=\"color:red\">[src] has been hit by [O]</span>")
	if (nodamage) return
	if (health > 0)
		var/dam_zone = pick("chest", "head")
		if (istype(organs[dam_zone], /obj/item/organ))
			var/obj/item/organ/temp = organs[dam_zone]

			var/reduction = 0
			if (energy_shield) reduction = energy_shield.protect()
			if (spellshield)
				reduction = 30
				boutput(src, "<span style=\"color:red\"><strong>Your Spell Shield absorbs some damage!</strong></span>")

			temp.take_damage((istype(O, /obj/newmeteor/small) ? max(15-reduction,0) : max(25-reduction,0)), max(20-reduction,0))
			UpdateDamageIcon()
		updatehealth()
	else if (prob(20))
		gib()

	return

/mob/living/carbon/human/deliver_move_trigger(ev)
	for (var/obj/O in contents)
		if (O.move_triggered)
			O.move_trigger(src, ev)

/mob/living/carbon/human/Move(a, b, flag)
	if (buckled && buckled.anchored)
		return

	if (traitHolder && prob(5) && traitHolder.hasTrait("leftfeet") && !handcuffed)
		spawn (10)
			if (src)
				step(src,pick(turn(b, 90),turn(b, -90)))

	if (restrained() && pulling)
		pulling = null
		hud.update_pulling()

	var/t7 = 1
	if (restrained())
		for (var/mob/M in range(src, 1))
			if ((M.pulling == src && M.stat == 0 && !( M.restrained() )))
				t7 = null

	if (last_move_trigger + 10 <= ticker.round_elapsed_ticks)
		last_move_trigger = ticker.round_elapsed_ticks
		deliver_move_trigger(m_intent)

	if ((t7 && (pulling && ((get_dist(src, pulling) <= 1 || pulling.loc == loc) && (client && client.moving)))))
		var/turf/T = loc
		. = ..()

		if (pulling && pulling.loc)
			if (!( isturf(pulling.loc) ))
				pulling = null
				hud.update_pulling()
				return
			else
				if (Debug)
					diary <<"pulling disappeared? at [__LINE__] in mob.dm - pulling = [pulling]"
					diary <<"REPORT THIS"

		/////
		if (pulling && pulling.anchored)
			pulling = null
			return

		if (!restrained())
			var/diag = get_dir(src, pulling)
			if ((diag - 1) & diag)
			else
				diag = null
			if ((get_dist(src, pulling) > 1 || diag))
				if (ismob(pulling))
					var/mob/M = pulling
					var/ok = 1
					if (locate(/obj/item/grab, M.grabbed_by))
						if (prob(75))
							var/obj/item/grab/G = pick(M.grabbed_by)
							if (istype(G, /obj/item/grab))
								M.visible_message("<span style=\"color:red\">[G.affecting] has been pulled from [G.assailant]'s grip by [src]</span>")
								//G = null
								qdel(G)
						else
							ok = 0
						if (locate(/obj/item/grab, M.grabbed_by.len))
							ok = 0
					if (ok)
						var/t = M.pulling
						M.pulling = null
						if (emergency_shuttle.location == 1)
							var/shuttle = locate(/area/shuttle/escape/station)
							var/loc = pulling.loc
							if ( (M.stat == 2) && ( loc in shuttle ) )
								unlock_medal("Leave no man behind!", 1)


						step(pulling, get_dir(pulling.loc, T))
						if (istype(pulling, /mob/living))
							var/mob/living/some_idiot = pulling
							if (some_idiot.buckled && !some_idiot.buckled.anchored)
								step(some_idiot.buckled, get_dir(some_idiot.buckled.loc, T))
						M.pulling = t
				else
					if (pulling)
						step(pulling, get_dir(pulling.loc, T))
						if (istype(pulling, /mob/living))
							var/mob/living/some_idiot = pulling
							if (some_idiot.buckled && !some_idiot.buckled.anchored)
								step(some_idiot.buckled, get_dir(some_idiot.buckled.loc, T))
	else
		pulling = null
		hud.update_pulling()
		. = ..()

/mob/living/carbon/human/UpdateName()
	if ((wear_mask && !(wear_mask.see_face)) || (head && !(head.see_face))) // can't see the face
		if (istype(wear_id) && wear_id:registered)
			name = "[name_prefix(null, 1)][wear_id:registered][name_suffix(null, 1)]"
		else
			unlock_medal("Suspicious Character", 1)
			name = "[name_prefix(null, 1)]Unknown[name_suffix(null, 1)]"
	else
		if (istype(wear_id) && wear_id:registered != real_name)
			if (decomp_stage > 2)
				name = "[name_prefix(null, 1)]Unknown (as [wear_id:registered])[name_suffix(null, 1)]"
			else
				name = "[name_prefix(null, 1)][real_name] (as [wear_id:registered])[name_suffix(null, 1)]"
		else
			if (decomp_stage > 2)
				name = "[name_prefix(null, 1)]Unknown[wear_id ? " (as [wear_id:registered])" : ""][name_suffix(null, 1)]"
			else
				name = "[name_prefix(null, 1)][real_name][name_suffix(null, 1)]"

/mob/living/carbon/human/find_in_equipment(var/eqtype)
	if (istype(w_uniform, eqtype))
		return w_uniform
	if (istype(wear_id, eqtype))
		return wear_id
	if (istype(gloves, eqtype))
		return gloves
	if (istype(shoes, eqtype))
		return shoes
	if (istype(wear_suit, eqtype))
		return wear_suit
	if (istype(back, eqtype))
		return back
	if (istype(glasses, eqtype))
		return glasses
	if (istype(ears, eqtype))
		return ears
	if (istype(wear_mask, eqtype))
		return wear_mask
	if (istype(head, eqtype))
		return head
	if (istype(belt, eqtype))
		return belt
	if (istype(l_store, eqtype))
		return l_store
	if (istype(r_store, eqtype))
		return r_store
	return null

/mob/living/carbon/human/find_in_hands(var/eqtype)
	if (istype(l_hand, eqtype))
		return l_hand
	if (istype(r_hand, eqtype))
		return r_hand
	return null

/mob/living/carbon/human/is_in_hands(var/obj/O)
	if (l_hand == O || r_hand == O)
		return TRUE
	return FALSE


// Marquesas: I'm literally adding an extra parameter here so I don't have to port a metric shitton of code elsewhere.
// These calculations really should be doable via another proc.
/mob/living/carbon/human/attack_hand(mob/living/carbon/human/M as mob)
	if (!M || !src) //Apparently M could be a meatcube and this causes HELLA runtimes.
		return

	if (!ticker)
		boutput(M, "You cannot interact with other people before the game has started.")
		return

	actions.interrupt(src, INTERRUPT_ATTACKED)

	if (!ishuman(M))
		if (hascall(M, "melee_attack_human"))
			call(M, "melee_attack_human")(src)
		return

	M.viral_transmission(src,"Contact",1)

	if (M.gloves && M.gloves.material)
		M.gloves.material.triggerOnAttack(M.gloves, M, src)
		for (var/atom/A in src)
			if (A.material)
				A.material.triggerOnAttacked(A, M, src, M.gloves)

	switch(M.a_intent)
		if (INTENT_HELP)
			var/limb/L = M.equipped_limb()
			if (!L)
				return
			L.help(src, M)

		if (INTENT_DISARM)
			if (M.is_mentally_dominated_by(src))
				boutput(M, "<span style=\"color:red\">You cannot harm your master!</span>")
				return

			var/limb/L = M.equipped_limb()
			if (!L)
				return
			L.disarm(src, M)

		if (INTENT_GRAB)
			if (M == src)
				M.grab_self()
				return
			var/limb/L = M.equipped_limb()
			if (!L)
				return
			L.grab(src, M)
			message_admin_on_attack(M, "grabs")

		if (INTENT_HARM)
			if (M.is_mentally_dominated_by(src))
				boutput(M, "<span style=\"color:red\">You cannot harm your master!</span>")
				return

			M.violate_hippocratic_oath()
			message_admin_on_attack(M, "punches")
			if (shrunk == 2)
				M.visible_message("<span style=\"color:red\">[M] squashes [src] like a bug.</span>")
				gib()
				return

			if (M.gloves && (M.gloves.can_be_charged && M.gloves.stunready && M.gloves.uses >= 1))
				M.stun_glove_attack(src)
				return

			M.melee_attack(src)

	return

/mob/living/carbon/human/restrained()
	if (handcuffed)
		return TRUE
	if (istype(wear_suit, /obj/item/clothing/suit/straight_jacket))
		return TRUE
	if (limbs && (hand ? !limbs.l_arm : !limbs.r_arm))
		return TRUE
	/*if (src.limbs && (src.hand ? !src.limbs.l_arm:can_hold_items : !src.limbs.r_arm:can_hold_items)) // this was fucking stupid and broke item limbs, I mean really, how do you restrain someone whos arm is a goddamn CHAINSAW
		return TRUE*/



/mob/living/carbon/human/var/co2overloadtime = null
/mob/living/carbon/human/var/temperature_resistance = T0C+75

/obj/equip_e/human/process()
	if (item)
		item.add_fingerprint(source)
	if (!item)
		switch(place)
			if ("mask")
				if (!( target.wear_mask ) || !target.wear_mask.handle_other_remove(source, target))
					//SN src = null
					qdel(src)
					return
			if ("l_hand")
				if (!( target.l_hand ) || !(target.l_hand.handle_other_remove(source, target)))
					//SN src = null
					qdel(src)
					return
				/* TODO - DONE
				else if (istype(target.l_hand, /obj/item/staff) && prob(75))
					source.show_message(text("<span style=\"color:red\">The [target.l_hand] is too slippery to hold on to!</span>"), 1)
					qdel(src)
					return
				*/
			if ("r_hand")
				if (!( target.r_hand ) || !(target.r_hand.handle_other_remove(source, target)))
					//SN src = null
					qdel(src)
					return
				/* TODO - DONE
				else if (istype(target.r_hand, /obj/item/staff) && prob(75))
					source.show_message(text("<span style=\"color:red\">The [target.r_hand] is too slippery to hold on to!</span>"), 1)
					qdel(src)
					return
				*/
			if ("suit")
				if (!( target.wear_suit ) || !target.wear_suit.handle_other_remove(source, target))
					//SN src = null
					qdel(src)
					return
				/* TODO - DONE
				else if (istype(target.wear_suit, /obj/item/clothing/suit/wizrobe) && prob(75))
					source.show_message(text("<span style=\"color:red\">The [target.wear_suit] writhes in your hands as though it is alive!</span>"), 1)
					qdel(src)
					return
				*/
			if ("uniform")
				if (!( target.w_uniform ) || !target.w_uniform.handle_other_remove(source, target))
					//SN src = null
					qdel(src)
					return
			if ("back")
				if (!( target.back ) || !target.back.handle_other_remove(source, target))
					//SN src = null
					qdel(src)
					return
			if ("handcuff")
				if (!target.handcuffed )
					//SN src = null
					if (!istype(source, /mob/living/silicon/robot))
						qdel(src)
					return
			if ("id")
				if ((!( target.wear_id ) || !( target.w_uniform ) || !( target.wear_id.handle_other_remove(source, target) )))
					//SN src = null
					qdel(src)
					return
			if ("internal")
				if ((!( (istype(target.wear_mask, /obj/item/clothing/mask) && istype(target.back, /obj/item/tank) && !( target.internal )) ) && !( target.internal )))
					//SN src = null
					qdel(src)
					return
			if ("gloves")
				if (!( target.gloves ) || !target.gloves.handle_other_remove(source, target))
					//SN src = null
					qdel(src)
					return
			if ("shoes")
				if (!( target.shoes ) || !target.shoes.handle_other_remove(source, target))
				//SN src = null
					qdel(src)
					return
				/* TODO - DONE
				else if (istype(target.shoes, /obj/item/clothing/shoes/sandal) && prob(75))
					source.show_message(text("<span style=\"color:red\">The [target.shoes] seem to be part of the feet!</span>"), 1)
					qdel(src)
					return
				*/
			if ("head")
				if (!( target.head ) || !target.head.handle_other_remove(source, target))
					qdel(src)
					return
				/* TODO - DONE
				else if (istype(target.head, /obj/item/clothing/head/wizard) && prob(75))
					source.show_message(text("<span style=\"color:red\">The [target.shoes] won't come off!</span>"), 1)
					qdel(src)
					return
				*/
				/* TODO - DONE
				else if (istype(target.head, /obj/item/clothing/head/butt) && target.head:stapled )
					source.show_message(text("<span style=\"color:red\"><strong>[source.name] rips out the staples from \the [target.head.name]!</strong></span>"), 1)
					target.head:unstaple()
					new /obj/decal/cleanable/blood(target.loc)
					playsound(target.loc, "sound/effects/splat.ogg", 50, 1)
					target.emote("scream")
					target.TakeDamage("head", rand(8, 16), 0)
				*/
	var/list/L = list( "syringe", "pill", "drink", "dnainjector", "fuel")
	if (istype(target) && istype(target.mutantrace, /mutantrace/abomination))
		target.visible_message("<span style=\"color:red\"><strong>[source] is trying to put \a [item] on [target], and is failing miserably!</strong></span>")
		return
	if ((item && !( L.Find(place) )))
		target.visible_message("<span style=\"color:red\"><strong>[source] is trying to put \a [item] on [target]</strong></span>")
	else
		if (place == "syringe")
			target.visible_message("<span style=\"color:red\"><strong>[source] is trying to inject [target]!</strong></span>")
		else
			if (place == "pill")
				target.visible_message("<span style=\"color:red\"><strong>[source] is trying to force [target] to swallow [item]!</strong></span>")
			else
				if (place == "fuel")
					target.visible_message("<span style=\"color:red\">[source] is trying to force [target] to eat the [item:content]!</span>")
				else
					if (place == "drink")
						target.visible_message("<span style=\"color:red\"><strong>[source] is trying to force [target] to swallow a gulp of [item]!</strong></span>")
					else
						if (place == "dnainjector")
							target.visible_message("<span style=\"color:red\"><strong>[source] is trying to inject [target] with the [item]!</strong></span>")
						else
							var/message = null
							switch(place)
								if ("mask")
									message = "<span style=\"color:red\"><strong>[source] is trying to take off \a [target.wear_mask] from [target]'s head!</strong></span>"
								if ("l_hand")
									message = "<span style=\"color:red\"><strong>[source] is trying to take off \a [target.l_hand] from [target]'s left hand!</strong></span>"
								if ("r_hand")
									message = "<span style=\"color:red\"><strong>[source] is trying to take off \a [target.r_hand] from [target]'s right hand!</strong></span>"
								if ("gloves")
									message = "<span style=\"color:red\"><strong>[source] is trying to take off the [target.gloves] from [target]'s hands!</strong></span>"
								if ("eyes")
									message = "<span style=\"color:red\"><strong>[source] is trying to take off the [target.glasses] from [target]'s eyes!</strong></span>"
								if ("ears")
									message = "<span style=\"color:red\"><strong>[source] is trying to take off the [target.ears] from [target]'s ears!</strong></span>"
								if ("head")
									message = "<span style=\"color:red\"><strong>[source] is trying to take off the [target.head] from [target]'s head!</strong></span>"
								if ("shoes")
									message = "<span style=\"color:red\"><strong>[source] is trying to take off the [target.shoes] from [target]'s feet!</strong></span>"
								if ("belt")
									message = "<span style=\"color:red\"><strong>[source] is trying to take off the [target.belt] from [target]'s belt!</strong></span>"
								if ("suit")
									message = "<span style=\"color:red\"><strong>[source] is trying to take off \a [target.wear_suit] from [target]'s body!</strong></span>"
								if ("back")
									message = "<span style=\"color:red\"><strong>[source] is trying to take off \a [target.back] from [target]'s back!</strong></span>"
								if ("handcuff")
									message = "<span style=\"color:red\"><strong>[source] is trying to unhandcuff [target]!</strong></span>"
								if ("uniform")
									message = "<span style=\"color:red\"><strong>[source] is trying to take off \a [target.w_uniform] from [target]'s body!</strong></span>"
								if ("pockets")
									for (var/obj/item/mousetrap/MT in  list(target.l_store, target.r_store))
										if (MT.armed)
											for (var/mob/O in AIviewers(target, null))
												if (O == source)
													O.show_message("<span style=\"color:red\"><strong>You reach into the [target]'s pockets, but there was a live mousetrap in there!</strong></span>", 1)
												else
													O.show_message("<span style=\"color:red\"><strong>[source] reaches into [target]'s pockets and sets off a hidden mousetrap!</strong></span>", 1)
											target.u_equip(MT)
											MT.set_loc(source.loc)
											MT.triggered(source, source.hand ? "l_hand" : "r_hand")
											MT.layer = OBJ_LAYER
											return
									message = "<span style=\"color:red\"><strong>[source] is trying to empty [target]'s pockets!!</strong></span>"
								if ("id")
									message = "<span style=\"color:red\"><strong>[source] is trying to take off [target.wear_id] from [target]'s uniform!</strong></span>"
								if ("internal")
									if (target.internal)
										message = "<span style=\"color:red\"><strong>[source] is trying to remove [target]'s internals</strong></span>"
									else
										message = "<span style=\"color:red\"><strong>[source] is trying to set on [target]'s internals.</strong></span>"
								else
							target.visible_message(message)
	if (do_mob(source, target, 40))
		done()
	return

/obj/equip_e/human/done()
	#define equip_e_slot(slot_name) var/obj/item/W = target.get_slot(target.slot_name); if (W) { if (!W.handle_other_remove(source, target)) return; target.u_equip(W); if (W) { W.set_loc(target.loc); W.dropped(target); W.layer = initial(W.layer); W.add_fingerprint(source) } } else if (target.can_equip(item, target.slot_name)) { source.u_equip(item); target.force_equip(item, target.slot_name) }
	if (!source || !target)						return
	if (source.loc != s_loc)						return
	if (target.loc != t_loc)						return
	if (LinkBlocked(s_loc,t_loc))				return
	if (!istype(source, /mob/living/silicon/robot))
		if (item && source.equipped() != item)	return
	if ((source.restrained() || source.stat))	return
	switch(place)
		if ("mask")
			equip_e_slot(slot_wear_mask)
		if ("gloves")
			equip_e_slot(slot_gloves)
		if ("eyes")
			equip_e_slot(slot_glasses)
		if ("belt")
			equip_e_slot(slot_belt)
		if ("head")
			equip_e_slot(slot_head)
		if ("ears")
			equip_e_slot(slot_ears)
		if ("shoes")
			equip_e_slot(slot_shoes)
		if ("l_hand")
			equip_e_slot(slot_l_hand)
		if ("r_hand")
			equip_e_slot(slot_r_hand)
		if ("uniform")
			equip_e_slot(slot_w_uniform)
		if ("suit")
			equip_e_slot(slot_wear_suit)
		if ("id")
			equip_e_slot(slot_wear_id)
		if ("back")
			equip_e_slot(slot_back)
		if ("handcuff")
			logTheThing("combat", source, target, "handcuffs %target%")
			if (target.handcuffed)
				var/obj/item/W = target.handcuffed
				target.u_equip(W)
				actions.stopId("handcuffs", target)
				if (istype(W,/obj/item/handcuffs/tape))
					qdel(W)
				if (W)
					W.set_loc(target.loc)
					W.dropped(target)
					W.layer = initial(W.layer)
					W.add_fingerprint(source)
			else if (istype(item, /obj/item/handcuffs/tape_roll))
				target.drop_from_slot(target.r_hand)
				target.drop_from_slot(target.l_hand)
				target.drop_juggle()
				item:amount -= 1
				if (item:amount <=0)
					source.drop_item()
					qdel(item)
				var/obj/item/handcuffs/tape/C = new/obj/item/handcuffs/tape()
				target.handcuffed = C
				C.set_loc(target)
			else if (istype(item, /obj/item/handcuffs))
				target.drop_from_slot(target.r_hand)
				target.drop_from_slot(target.l_hand)
				source.drop_item()
				target.drop_juggle()
				target.handcuffed = item
				item.set_loc(target)
		if ("pockets")
			if (target.l_store)
				var/obj/item/W = target.l_store
				target.u_equip(W)
				if (W)
					W.set_loc(target.loc)
					W.dropped(target)
					W.layer = initial(W.layer)
				W.add_fingerprint(source)
			if (target.r_store)
				var/obj/item/W = target.r_store
				target.u_equip(W)
				if (W)
					W.set_loc(target.loc)
					W.dropped(target)
					W.layer = initial(W.layer)
				W.add_fingerprint(source)
		if ("internal")
			logTheThing("combat", source, target, "switches %target%'s internals")
			if (target.internal)
				target.internal.add_fingerprint(source)
				for (var/obj/ability_button/tank_valve_toggle/T in target.internal.ability_buttons)
					T.icon_state = "airoff"
				target.internal = null
			else
				if (target.internal)
					target.internal = null
					for (var/obj/ability_button/tank_valve_toggle/T in target.internal.ability_buttons)
						T.icon_state = "airoff"
				if (!( istype(target.wear_mask, /obj/item/clothing/mask) ))
					return
				else
					if (istype(target.back, /obj/item/tank))
						target.internal = target.back
						for (var/obj/ability_button/tank_valve_toggle/T in target.internal.ability_buttons)
							T.icon_state = "airon"

						for (var/mob/M in AIviewers(target, 1))
							M.show_message(text("[] is now running on internals.", target), 1)
						target.internal.add_fingerprint(source)
		else
	if (source)
		source.set_clothing_icon_dirty()
	if (target)
		target.set_clothing_icon_dirty()
	//SN src = null
	qdel(src)
	return
	#undef equip_e_slot

// new damage icon system
// now constructs damage icon for each organ from mask * damage field


/mob/living/carbon/human/proc/show_inv(mob/user as mob)
	user.machine = src
	var/dat = {"
	<strong><HR><FONT size=3>[name]</FONT></strong>
	<BR><HR>
	<strong>Head:</strong> <A href='?src=\ref[src];varname=head;slot=[slot_head];item=head'>[(head ? head : "Nothing")]</A>
	<BR><strong>Mask:</strong> <A href='?src=\ref[src];varname=wear_mask;slot=[slot_wear_mask];item=mask'>[(wear_mask ? wear_mask : "Nothing")]</A>
	<BR><strong>Eyes:</strong> <A href='?src=\ref[src];varname=glasses;slot=[slot_glasses];item=eyes'>[(glasses ? glasses : "Nothing")]</A>
	<BR><strong>Ears:</strong> <A href='?src=\ref[src];varname=ears;slot=[slot_ears];item=ears'>[(ears ? ears : "Nothing")]</A>
	<BR><strong>Left Hand:</strong> <A href='?src=\ref[src];varname=l_hand;slot=[slot_l_hand];item=l_hand'>[(l_hand ? l_hand  : "Nothing")]</A>
	<BR><strong>Right Hand:</strong> <A href='?src=\ref[src];varname=r_hand;slot=[slot_r_hand];item=r_hand'>[(r_hand ? r_hand : "Nothing")]</A>
	<BR><strong>Gloves:</strong> <A href='?src=\ref[src];varname=gloves;slot=[slot_gloves];item=gloves'>[(gloves ? gloves : "Nothing")]</A>
	<BR><strong>Shoes:</strong> <A href='?src=\ref[src];varname=shoes;slot=[slot_shoes];item=shoes'>[(shoes ? shoes : "Nothing")]</A>
	<BR><strong>Belt:</strong> <A href='?src=\ref[src];varname=belt;slot=[slot_belt];item=belt'>[(belt ? belt : "Nothing")]</A>
	<BR><strong>Uniform:</strong> <A href='?src=\ref[src];varname=w_uniform;slot=[slot_w_uniform];item=uniform'>[(w_uniform ? w_uniform : "Nothing")]</A>
	<BR><strong>Outer Suit:</strong> <A href='?src=\ref[src];varname=wear_suit;slot=[slot_wear_suit];item=suit'>[(wear_suit ? wear_suit : "Nothing")]</A>
	<BR><strong>Back:</strong> <A href='?src=\ref[src];varname=back;slot=[slot_back];item=back'>[(back ? back : "Nothing")]</A> [((istype(wear_mask, /obj/item/clothing/mask) && istype(back, /obj/item/tank) && !( internal )) ? text(" <A href='?src=\ref[];item=internal;slot=internal'>Set Internal</A>", src) : "")]
	<BR><strong>ID:</strong> <A href='?src=\ref[src];varname=wear_id;slot=[slot_wear_id];item=id'>[(wear_id ? wear_id : "Nothing")]</A>
	<BR><strong>Left Pocket:</strong> <A href='?src=\ref[src];varname=l_store;slot=[slot_l_store];item=pockets'>[(l_store ? "Something" : "Nothing")]</A>
	<BR><strong>Right Pocket:</strong> <A href='?src=\ref[src];varname=r_store;slot=[slot_r_store];item=pockets'>[(r_store ? "Something" : "Nothing")]</A>
	<BR>[(handcuffed ? text("<A href='?src=\ref[src];slot=handcuff;item=handcuff'>Handcuffed</A>") : text("<A href='?src=\ref[src];item=handcuff;slot=handcuff'>Not Handcuffed</A>"))]
	<BR>[(internal ? text("<A href='?src=\ref[src];slot=internal;item=internal'>Remove Internal</A>") : "")]
	<BR><A href='?action=mach_close&window=mob[name]'>Close</A>
	<BR>"}
	user << browse(dat, text("window=mob[name];size=340x480"))
	onclose(user, "mob[name]")
	return
	//	<BR><A href='?src=\ref[src];item=pockets'>Empty Pockets</A>

/mob/living/carbon/human/MouseDrop(mob/M as mob)
	..()
	if (M != usr) return
	if (usr == src) return
	if (get_dist(usr,src) > 1) return
	if (!M.can_strip()) return
	if (LinkBlocked(usr.loc,loc)) return
	show_inv(usr)

// called when something steps onto a human
// this could be made more general, but for now just handle mulebot
/mob/living/carbon/human/HasEntered(var/atom/movable/AM)
	var/obj/machinery/bot/mulebot/MB = AM
	if (istype(MB))
		MB.RunOver(src)

/mob/living/carbon/human/Topic(href, href_list)
	if (istype(usr.loc,/obj/dummy/spell_invis) || istype(usr, /mob/living/silicon/ghostdrone))
		return
	if (!usr.stat && usr.canmove && !usr.restrained() && in_range(src, usr) && ticker && usr.can_strip())
		if (href_list["slot"] == "handcuff")
			actions.start(new/action/bar/icon/handcuffRemovalOther(src), usr)
		else if (href_list["slot"] == "internal")
			actions.start(new/action/bar/icon/internalsOther(src), usr)
		else if (href_list["item"])
			actions.start(new/action/bar/icon/otherItem(usr, src, usr.equipped(), text2num(href_list["slot"])) , usr)

	return //HURP DURP OLD CODE PATH BELOW

/*	if (href_list["item"] && !usr.stat && usr.canmove && !usr.restrained() && in_range(src, usr) && ticker)
		var/obj/equip_e/human/O = new /obj/equip_e/human(  )
		O.source = usr
		O.target = src
		O.item = usr.equipped()
		O.s_loc = usr.loc
		O.t_loc = loc
		O.place = href_list["item"]
		spawn ( 0 )
			O.process()
			return
	..()
	return*/

/mob/living/carbon/human/get_valid_target_zones()
	var/list/ret = list()
	for (var/organName in organs)
		if (istype(organs[organName], /obj/item))
			ret += organName
	return ret

/proc/random_brute_damage(var/mob/themob, var/damage, var/disallow_limb_loss) // do brute damage to a random organ
	if (!themob || !ismob(themob))
		return FALSE//???
	var/list/zones = themob.get_valid_target_zones()
	if (!zones || !zones.len)
		themob.TakeDamage("All", damage, 0, 0, DAMAGE_BLUNT)
	else
		if (prob(100 / zones.len + 1))
			themob.TakeDamage("All", damage, 0, 0, DAMAGE_BLUNT)
		else
			themob.TakeDamage(pick(zones), damage, 0, 0, DAMAGE_BLUNT)
	return TRUE

/proc/random_burn_damage(var/mob/themob, var/damage) // do burn damage to a random organ
	if (!themob || !ismob(themob))
		return //???
	var/list/zones = themob.get_valid_target_zones()
	if (!zones || !zones.len)
		themob.TakeDamage("All", 0, damage, 0, DAMAGE_BURN)
	else
		if (prob(100 / zones.len + 1))
			themob.TakeDamage("All", 0, damage, 0, DAMAGE_BURN)
		else
			themob.TakeDamage(pick(zones), 0, damage, 0, DAMAGE_BURN)

/* ----------------------------------------------------------------------------------------------------------------- */

/mob/living/carbon/human
	var/life_context = "begin"

/mob/living/carbon/human/Life(controller/process/mobs/parent)
	set invisibility = 0
	if (..(parent))
		return TRUE

	if (transforming)
		return

	if (nut < 0)
		++nut

	if (!bioHolder)
		bioHolder = new/bioHolder(src)

	parent.setLastTask("update_item_abilities", src)
	update_item_abilities()

	parent.setLastTask("update_item_abilities", src)
	update_objectives()

	// Jewel's attempted fix for: null.return_air()
	// These objects should be garbage collected the next tick, so it's not too bad if it's not breathing I think? I might be totallly wrong here.
	if (loc)
		var/gas_mixture/environment = loc.return_air()

		if (stat != 2) //still breathing

			parent.setLastTask("handle_material_triggers", src)
			for (var/obj/item/I in src)
				if (!I.material) continue
				I.material.triggerOnLife(src, I)

			//Chemicals in the body
			parent.setLastTask("handle_chemicals_in_body", src)
			handle_chemicals_in_body()

			//Mutations and radiation
			parent.setLastTask("handle_mutations_and_radiation", src)
			handle_mutations_and_radiation()

			//special (read: stupid) manual breathing stuff. weird numbers are so that messages don't pop up at the same time as manual blinking ones every time
			if (manualbreathing)
				breathtimer++
				switch(breathtimer)
					if (34)
						boutput(src, "<span style=\"color:red\">You need to breathe!</span>")
					if (35 to 51)
						if (prob(5)) emote("gasp")
					if (52)
						boutput(src, "<span style=\"color:red\">Your lungs start to hurt. You really need to breathe!</span>")
					if (53 to 61)
						hud.update_oxy_indicator(1)
						take_oxygen_deprivation(breathtimer/12)
					if (62)
						hud.update_oxy_indicator(1)
						boutput(src, "<span style=\"color:red\">Your lungs are burning and the need to take a breath is almost unbearable!</span>")
						take_oxygen_deprivation(10)
					if (63 to INFINITY)
						hud.update_oxy_indicator(1)
						take_oxygen_deprivation(breathtimer/6)

			//First, resolve location and get a breath

			if (air_master.current_cycle%2==1 && breathtimer < 15)
				//Only try to take a breath every 4 seconds, unless suffocating
				parent.setLastTask("breathe", src)
				spawn (0) breathe()

			else //Still give containing object the chance to interact
				if (istype(loc, /obj))
					parent.setLastTask("handle_internal_lifeform", src)
					var/obj/location_as_object = loc
					location_as_object.handle_internal_lifeform(src, 0)

		else if (stat == 2)
			parent.setLastTask("handle_decomposition", src)
			handle_decomposition()

		//Apparently, the person who wrote this code designed it so that
		//blinded get reset each cycle and then get activated later in the
		//code. Very ugly. I dont care. Moving this stuff here so its easy
		//to find it.
		blinded = null

		parent.setLastTask("handle_mutantrace_life", src)
		if (mutantrace) mutantrace.onLife()
		//Disease Check
		parent.setLastTask("handle_virus_updates", src)
		handle_virus_updates()

		//Handle temperature/pressure differences between body and environment
		parent.setLastTask("handle_environment", src)
		handle_environment(environment)

		//stuff in the stomach
		parent.setLastTask("handle_stomach", src)
		handle_stomach()

		//Disabilities
		parent.setLastTask("handle_disabilities", src)
		handle_disabilities()

	handle_burning()
	//Status updates, death etc.
	clamp_values()
	parent.setLastTask("handle_regular_status_updates", src)
	handle_regular_status_updates(parent)

	parent.setLastTask("handle_stuns_lying", src)
	handle_stuns_lying(parent)

	if (stat != 2) // Marq was here, breaking everything.
		parent.setLastTask("handle_blood", src)
		handle_blood()

		parent.setLastTask("handle_organs", src)
		handle_organs()

		parent.setLastTask("sims", src)
		if (sims)
			sims.Life()

		if (prob(1) && prob(5))
			parent.setLastTask("handle_random_emotes", src)
			handle_random_emotes()

	parent.setLastTask("handle pathogens", src)
	handle_pathogens()

	if (client)
		parent.setLastTask("handle_regular_hud_updates", src)
		handle_regular_hud_updates()
		parent.setLastTask("handle_regular_sight_updates", src)
		handle_regular_sight_updates()

	//Being buckled to a chair or bed
	parent.setLastTask("check_if_buckled", src)
	check_if_buckled()

	// Yup.
	parent.setLastTask("update_canmove", src)
	update_canmove()

	clamp_values()

	if (health_mon)
		var/health_prc = (health / max_health) * 100
		if (bioHolder && bioHolder.HasEffect("dead_scan"))
			health_mon.icon_state = "-1"
		else
			switch(health_prc)
				if (98 to 100) //100
					health_mon.icon_state = "100"
				if (81 to 97) //80
					health_mon.icon_state = "80"
				if (75 to 80) //75
					health_mon.icon_state = "75"
				if (50 to 74) //50
					health_mon.icon_state = "50"
				if (25 to 49) //25
					health_mon.icon_state = "25"
				if (1 to 24) //10
					health_mon.icon_state = "10"
				if (-1000 to 0) //0
					if (stat == 1 || stat == 0)
						health_mon.icon_state = "0"
					else if (stat == 2)
						health_mon.icon_state = "-1"

	//Regular Trait updates
	if (traitHolder)
		for (var/T in traitHolder.traits)
			var/obj/trait/O = getTraitById(T)
			O.onLife(src)

	// Icons
	parent.setLastTask("update_icons", src)
	update_icons_if_needed()

	if (client) //ov1
		// overlays
		parent.setLastTask("update_screen_overlays", src)
		updateOverlaysClient(client)
		antagonist_overlay_refresh(0, 0)

	if (observers.len)
		for (var/mob/x in observers)
			if (x.client)
				updateOverlaysClient(x.client)

	// Grabbing
	for (var/obj/item/grab/G in src)
		parent.setLastTask("obj/item/grab.process() for [G]")
		G.process()

	if (!can_act(M=src,include_cuffs=0)) actions.interrupt(src, INTERRUPT_STUNNED)

/mob/living/carbon/human
	proc/clamp_values()

		stunned = max(min(stunned, 15),0)
		paralysis = max(min(paralysis, 20), 0)
		weakened = max(min(weakened, 15), 0)
		slowed = max(min(slowed, 15), 0)
		sleeping = max(min(sleeping, 20), 0)
		stuttering = max(stuttering, 0)
		losebreath = max(min(losebreath,25),0) // stop going up into the thousands, goddamn
		burning = max(min(burning, 100),0)
//		bleeding = max(min(bleeding, 10),0)
//		blood_volume = max(blood_volume, 0)

	proc/handle_burning()
		if (burning)
			var/damage = 0
			//Normal equip gives you around ~212. Spacesuits ~362. Firesuits ~863.
			var/damage_reduction = (round(add_fire_protection(0) / 100) - 2) //normal equip = 0, spacesuits = 1, firesuits = 6
			if (burning <= 33)
				damage = max(3-damage_reduction,0.75)
			else if (burning > 33 && burning <= 66)
				damage = max(4-damage_reduction,1.50)
			else if (burning > 66)
				damage = max(5-damage_reduction,2.00)

			if (isturf(loc))
				var/turf/location = loc
				location.hotspot_expose(T0C + 100 + burning * 3, 400)

			for (var/atom/A in contents)
				if (A.material)
					A.material.triggerTemp(A, T0C + 100 + burning * 3)

			if (!is_heat_resistant())
				TakeDamage("chest", 0, damage, 0, DAMAGE_BURN)

			if (traitHolder && traitHolder.hasTrait("burning"))
				if (prob(50)) update_burning(-1)
			else
				update_burning(-1)

	proc/handle_decomposition()
		var/turf/T = get_turf_loc(src)
		if (!T) return
		if (stat != 2 || mutantrace || reagents.has_reagent("formaldehyde"))
			return

		var/env_temp = 0
		if (istype(loc, /obj/machinery/atmospherics/unary/cryo_cell))
			return
		if (istype(loc, /obj/morgue))
			return
		// cogwerks note: both the cryo cell and morgue things technically work, but the corpse rots instantly when removed
		// if it has been in there longer than the next decomp time that was initiated before the corpses went in. fuck!
		// will work out a fix for that soon, too tired right now
		else
			var/gas_mixture/environment = T.return_air()
			env_temp = environment.temperature
		next_decomp_time -= min(30, max(round((env_temp - T20C)/10), -60))
		if (world.time > next_decomp_time) // advances every 4-10 game minutes
			decomp_stage = min(decomp_stage + 1, 4)
			update_body()
			update_face()
			next_decomp_time = world.time + rand(240,600)*10

	proc/stink()
		if (prob(15))
			for (var/mob/living/carbon/C in view(6,get_turf(src)))
				if (C == src || !C.client)
					continue
				boutput(C, "<span style=\"color:red\">[stinkString()]</span>")
				if (prob(30))
					new/obj/decal/cleanable/vomit(C.loc)
					C.stunned += 2
					boutput(C, "<span style=\"color:red\">[stinkString()]</span>")

	proc/handle_disabilities()

		// moved drowsy, confusion and such from handle_chemicals because it seems better here
		if (drowsyness)
			drowsyness--
			change_eye_blurry(2)
			if (prob(5))
				sleeping = 1
				paralysis = 5

		if (misstep_chance > 0)
			switch(misstep_chance)
				if (50 to INFINITY)
					change_misstep_chance(-2)
				else
					change_misstep_chance(-1)

		// The value at which this stuff is capped at can be found in mob.dm
		if (resting)
			dizziness = max(0, dizziness - 5)
			jitteriness = max(0, jitteriness - 5)
		else
			dizziness = max(0, dizziness - 2)
			jitteriness = max(0, jitteriness - 2)

		if (!isnull(mind) && isvampire(src))
			if (istype(get_area(src), /area/station/chapel) && check_vampire_power(3) != 1)
				if (prob(33))
					boutput(src, "<span style=\"color:red\">The holy ground burns you!</span>")
				TakeDamage("chest", 0, 10, 0, DAMAGE_BURN)
			if (loc && istype(loc, /turf/space))
				if (prob(33))
					boutput(src, "<span style=\"color:red\">The starlight burns you!</span>")
				TakeDamage("chest", 0, 2, 0, DAMAGE_BURN)

		if (src.loc && isarea(src.loc.loc))
			if (src.loc.loc:irradiated)
				if (wear_suit && wear_suit:radproof)
					if (istype(wear_suit, /obj/item/clothing/suit/rad) && prob(33))
						boutput(src, "<span style=\"color:red\">Your geiger counter ticks...</span>")
					return
				else
					src.irradiate(src.loc.loc:irradiated * 10)
					return

		//GENETIC INSTABILITY FUN STUFF
		if (is_changeling())
			return

		var/genetic_stability = 100
		if (bioHolder)
			genetic_stability = bioHolder.genetic_stability

		if (reagents && reagents.has_reagent("mutadone"))
			genetic_stability = 100

		if (traitHolder && traitHolder.hasTrait("robustgenetics"))
			genetic_stability += 20

		if (genetic_stability < 51)
			if (prob(1) && genetic_stability < 16) //Oh no!
				visible_message("<span style=\"color:red\"><strong>[name] bubbles and degenerates into a pile of living slop!</strong></span>")
				transforming = 1
				invisibility = 101

				var/bdna = null // For forensics (Convair880).
				var/btype = null
				if (bioHolder.Uid && bioHolder.bloodType)
					bdna = bioHolder.Uid
					btype = bioHolder.bloodType
				gibs(get_turf(src), null, null, bdna, btype)

				var/obj/critter/blobman/sucker = new (get_turf(src))
				sucker.name = real_name
				sucker.desc = "Science really HAS gone too far this time!"
				if (prob(30))
					sucker.atkcarbon = 0
					sucker.atksilicon = 0

				ghostize()
				qdel(src)
				return
				//make_meatcube(60)

			if (prob(5) && genetic_stability < 31)
				boutput(src, "<span style=\"color:red\">Some of your skin bubbles right off. Eugh!</span>")
				TakeDamage("chest", 10, 0, 0, DAMAGE_BURN)
			if (prob(5) && genetic_stability < 31)
				boutput(src, "<span style=\"color:red\">Some of your skin melts off. Gross!</span>")
				bleed(src, rand(8,14), 5)
			if (prob(2) && genetic_stability < 31)
				boutput(src, "<span style=\"color:red\">You feel grody as hell!</span>")
				take_toxin_damage(5)

		//	if (prob(2))                 //maybe let's not bake in something that makes people go blind if they're fat
		//		boutput(src, "<span style=\"color:red\">Your flesh bubbles and writhes!</span>")
		//		bioHolder.RandomEffect("bad",1)
			if (prob(5))
				take_toxin_damage(1)
			if (prob(5))
				take_brain_damage(1)

	proc/update_objectives()
		if (!mind)
			return
		if (!mind.objectives)
			return
		if (!istype(mind.objectives, /list))
			return
		for (var/objective/O in mind.objectives)
			spawn (0)
				if (istype(O, /objective/specialist/stealth))
					var/turf/T = get_turf_loc(src)
					if (T && isturf(T) && (istype(T, /turf/space) || T.loc.name == "Space" || T.z != 1))
						O:score = max(0, O:score - 1)
						if (prob(20))
							boutput(src, "<span style=\"color:red\"><strong>Being away from the station is making you lose your composure...</strong></span>")
						src << sound('sound/effects/env_damage.ogg')
						continue
					if (T && isturf(T) && T.RL_GetBrightness() < 0.2)
						O:score++
					else
						var/spotted_by_mob = 0
						for (var/mob/living/M in oviewers(src, 5))
							if (M.client && M.sight_check(1))
								O:score = max(0, O:score - 5)
								spotted_by_mob = 1
								break
						if (!spotted_by_mob)
							O:score++


	proc/handle_pathogens()
		if (stat == 2)
			if (pathogens.len)
				for (var/uid in pathogens)
					if (prob(5))
						cured(pathogens[uid])
			return
		for (var/uid in pathogens)
			var/pathogen/P = pathogens[uid]
			P.disease_act()

	proc/handle_mutations_and_radiation()
		if (radiation)
			switch(radiation)
				if (1 to 49)
					irradiate(-1)
					if (prob(25))
						take_toxin_damage(1)
						TakeDamage("chest", 0, 1, 0, DAMAGE_BURN)
						updatehealth()

				if (50 to 74)
					irradiate(-2)
					take_toxin_damage(1)
					TakeDamage("chest", 0, 1, 0, DAMAGE_BURN)
					if (prob(5))
						radiation -= 5
						if (bioHolder && !bioHolder.HasEffect("revenant"))
							weakened = 3
							boutput(src, "<span style=\"color:red\">You feel weak.</span>")
							emote("collapse")
					updatehealth()

				if (75 to 100)
					irradiate(-2)
					take_toxin_damage(2)
					TakeDamage("chest", 0, 2, 0, DAMAGE_BURN)
					var/mutChance = 2
					if (traitHolder && traitHolder.hasTrait("stablegenes"))
						mutChance = 1
					if (prob(mutChance) && (bioHolder && !bioHolder.HasEffect("revenant")))
						boutput(src, "<span style=\"color:red\">You mutate!</span>")
						src:bioHolder:RandomEffect("bad")
					updatehealth()

				if (101 to 150)
					irradiate(-3)
					take_toxin_damage(2)
					TakeDamage("chest", 0, 3, 0, DAMAGE_BURN)
					var/mutChance = 4
					if (traitHolder && traitHolder.hasTrait("stablegenes"))
						mutChance = 2
					if (prob(mutChance) && (bioHolder && !bioHolder.HasEffect("revenant")))
						boutput(src, "<span style=\"color:red\">You mutate!</span>")
						src:bioHolder:RandomEffect("bad")
					updatehealth()

				if (151 to INFINITY)
					// only goes up to 200 but we might as well catch exceptions just in case
					irradiate(-3)
					take_toxin_damage(2)
					TakeDamage("chest", 0, 3, 0, DAMAGE_BURN)
					var/mutChance = 6
					if (traitHolder && traitHolder.hasTrait("stablegenes"))
						mutChance = 3
					if (bioHolder && !bioHolder.HasEffect("revenant"))
						drowsyness = max(drowsyness, 5)
						if (prob(mutChance))
							boutput(src, "<span style=\"color:red\">You mutate!</span>")
							src:bioHolder:RandomEffect("bad")
					updatehealth()

		if (bioHolder) bioHolder.OnLife()

		if (bomberman == 1)
			spawn (10)
				new /obj/bomberman(get_turf(src))

	proc/breathe()
		if (!loc)
			return
		if (reagents)
			if (reagents.has_reagent("lexorin")) return
		if (istype(loc, /mob/living/object)) return // no breathing inside possessed objects
		if (istype(loc, /obj/machinery/atmospherics/unary/cryo_cell)) return
		//if (istype(loc, /obj/machinery/clonepod)) return
		if (bioHolder && bioHolder.HasEffect("breathless")) return

		// Changelings generally can't take OXY/LOSEBREATH damage...except when they do.
		// And because they're excluded from the breathing procs, said damage didn't heal
		// on its own, making them essentially mute and perpetually gasping for air.
		// Didn't seem like a feature to me (Convair880).
		if (is_changeling())
			if (losebreath)
				losebreath = 0
			if (get_oxygen_deprivation())
				take_oxygen_deprivation(-50)
			return

		var/gas_mixture/environment = loc.return_air()
		var/air_group/breath
		// HACK NEED CHANGING LATER
		//if (oxymax == 0 || (breathtimer > 15))
		if (breathtimer > 15)
			losebreath++

		if (losebreath>0) //Suffocating so do not take a breath
			losebreath--
			if (prob(75)) //High chance of gasping for air
				spawn emote("gasp")
			if (istype(loc, /obj))
				var/obj/location_as_object = loc
				location_as_object.handle_internal_lifeform(src, 0)
		else
			//First, check for air from internal atmosphere (using an air tank and mask generally)
			breath = get_breath_from_internal(BREATH_VOLUME)

			//No breath from internal atmosphere so get breath from location
			if (!breath)
				if (istype(loc, /obj))
					var/obj/location_as_object = loc
					breath = location_as_object.handle_internal_lifeform(src, BREATH_VOLUME)
				else if (istype(loc, /turf))
					var/breath_moles = environment.total_moles()*BREATH_PERCENTAGE

					breath = loc.remove_air(breath_moles)

			else //Still give containing object the chance to interact
				if (istype(loc, /obj))
					var/obj/location_as_object = loc
					location_as_object.handle_internal_lifeform(src, 0)

		handle_breath(breath)

		if (breath)
			loc.assume_air(breath)


	proc/get_breath_from_internal(volume_needed)
		if (internal)
			if (!contents.Find(internal))
				internal = null
			if (!wear_mask || !(wear_mask.c_flags & MASKINTERNALS) )
				internal = null
			if (internal)
				if (internals)
					internals.icon_state = "internal1"
				for (var/obj/ability_button/tank_valve_toggle/T in internal.ability_buttons)
					T.icon_state = "airon"
				return internal.remove_air_volume(volume_needed)
			else
				if (internals)
					internals.icon_state = "internal0"
		return null

	proc/update_canmove()
		if (paralysis || stunned || weakened)
			canmove = 0
			return

		var/abilityHolder/changeling/C = get_ability_holder(/abilityHolder/changeling)
		if (C && C.in_fakedeath)
			canmove = 0
			return

		if (buckled && buckled.anchored)
			canmove = 0
			return

		canmove = 1

	proc/handle_breath(gas_mixture/breath)
		if (nodamage) return

		// Looks like we're in space
		// or with recent atmos changes, in a room that's had a hole in it for any amount of time, so now we check loc
		if (!breath || (breath.total_moles() == 0))
			if (istype(loc, /turf/space))
				take_oxygen_deprivation(10)
			else
				take_oxygen_deprivation(5)
			hud.update_oxy_indicator(1)

			return FALSE

		if (health < 0) //We aren't breathing.
			return FALSE

		var/safe_oxygen_min = 17 // Minimum safe partial pressure of O2, in kPa
		//var/safe_oxygen_max = 140 // Maximum safe partial pressure of O2, in kPa (Not used for now)
		var/safe_co2_max = 9 // Yes it's an arbitrary value who cares?
		var/safe_toxins_max = 0.4
		var/SA_para_min = 1
		var/SA_sleep_min = 5
		var/oxygen_used = 0
		var/breath_pressure = (breath.total_moles()*R_IDEAL_GAS_EQUATION*breath.temperature)/BREATH_VOLUME

		//Partial pressure of the O2 in our breath
		var/O2_pp = (breath.oxygen/breath.total_moles())*breath_pressure
		// Same, but for the toxins
		var/Toxins_pp = (breath.toxins/breath.total_moles())*breath_pressure
		// And CO2, lets say a PP of more than 10 will be bad (It's a little less really, but eh, being passed out all round aint no fun)
		var/CO2_pp = (breath.carbon_dioxide/breath.total_moles())*breath_pressure

		if (O2_pp < safe_oxygen_min) 			// Too little oxygen
			if (prob(20))
				spawn (0) emote("gasp")
			if (O2_pp > 0)
				var/ratio = round(safe_oxygen_min/(O2_pp + 0.1))
				take_oxygen_deprivation(min(5*ratio, 5)) // Don't fuck them up too fast (space only does 7 after all!)
				oxygen_used = breath.oxygen*ratio/6
			else
				take_oxygen_deprivation(5)
			hud.update_oxy_indicator(1)
		else 									// We're in safe limits
			take_oxygen_deprivation(-5)
			oxygen_used = breath.oxygen/6
			hud.update_oxy_indicator(0)

		breath.oxygen -= oxygen_used
		breath.carbon_dioxide += oxygen_used

		if (CO2_pp > safe_co2_max)
			if (!co2overloadtime) // If it's the first breath with too much CO2 in it, lets start a counter, then have them pass out after 12s or so.
				co2overloadtime = world.time
			else if (world.time - co2overloadtime > 120)
				paralysis = max(paralysis, 3)
				take_oxygen_deprivation(5) // Lets hurt em a little, let them know we mean business
				if (world.time - co2overloadtime > 300) // They've been in here 30s now, lets start to kill them for their own good!
					take_oxygen_deprivation(15)
			if (prob(20)) // Lets give them some chance to know somethings not right though I guess.
				spawn (0) emote("cough")

		else
			co2overloadtime = 0

		if (Toxins_pp > safe_toxins_max) // Too much toxins
			var/ratio = breath.toxins/safe_toxins_max
			take_toxin_damage(ratio * 325,15)
			hud.update_tox_indicator(1)
		else
			hud.update_tox_indicator(0)

		if (breath.trace_gases && breath.trace_gases.len)	// If there's some other shit in the air lets deal with it here.
			for (var/gas/sleeping_agent/SA in breath.trace_gases)
				var/SA_pp = (SA.moles/breath.total_moles())*breath_pressure
				if (SA_pp > SA_para_min) // Enough to make us paralysed for a bit
					paralysis = max(paralysis, 3) // 3 gives them one second to wake up and run away a bit!
					if (SA_pp > SA_sleep_min) // Enough to make us sleep as well
						sleeping = max(sleeping, 2)
				else if (SA_pp > 0.01)	// There is sleeping gas in their lungs, but only a little, so give them a bit of a warning
					if (prob(20))
						spawn (0) emote(pick("giggle", "laugh"))
			for (var/gas/rad_particles/RV in breath.trace_gases)
				irradiate(RV.moles/10,1)

		if (breath.temperature > (T0C+66) && !is_heat_resistant()) // Hot air hurts :(
			if (prob(20))
				boutput(src, "<span style=\"color:red\">You feel a searing heat in your lungs!</span>")
			TakeDamage("chest", 0, min((breath.temperature - (T0C+66)) / 3,10) + 6, 0, DAMAGE_BURN)
			hud.update_fire_indicator(1)
			if (prob(4))
				boutput(src, "<span style=\"color:red\">Your lungs hurt like hell! This can't be good!</span>")
				//contract_disease(new/ailment/disability/cough, 1, 0) // cogwerks ailment project - lung damage from fire
		else
			hud.update_fire_indicator(0)


		//Temporary fixes to the alerts.

		return TRUE

	proc/handle_environment(gas_mixture/environment)
		if (!environment)
			return
		var/environment_heat_capacity = environment.heat_capacity()
		var/loc_temp = T0C
		if (istype(loc, /turf/space))
			environment_heat_capacity = loc:heat_capacity
			loc_temp = 2.7
		else if (istype(loc, /obj/machinery/vehicle))
			var/obj/machinery/vehicle/ship = loc
			if (ship.life_support)
				if (ship.life_support.active)
					loc_temp = ship.life_support.tempreg
				else
					loc_temp = environment.temperature
		// why am i repeating this shit?
		else if (istype(loc, /obj/vehicle))
			var/obj/vehicle/V = loc
			if (V.sealed_cabin)
				loc_temp = T20C // hardcoded honkytonk nonsense
		else if (istype(loc, /obj/machinery/atmospherics/unary/cryo_cell))
			loc_temp = loc:air_contents.temperature
		else if (istype(loc, /obj/machinery/colosseum_putt))
			loc_temp = T20C
		else
			loc_temp = environment.temperature

		var/thermal_protection
		if (stat < 2)
			bodytemperature = adjustBodyTemp(bodytemperature,base_body_temp,1,thermoregulation_mult)
		if (loc_temp < base_body_temp) // a cold place -> add in cold protection
			if (is_cold_resistant())
				return
			thermal_protection = get_cold_protection()
		else // a hot place -> add in heat protection
			if (is_heat_resistant())
				return
			thermal_protection = get_heat_protection()
		var/thermal_divisor = (100 - thermal_protection) * 0.01
		bodytemperature = adjustBodyTemp(bodytemperature,loc_temp,thermal_divisor,innate_temp_resistance)

		if (istype(loc, /obj/machinery/atmospherics/unary/cryo_cell))
			return

		// lets give them a fair bit of leeway so they don't just start dying
		//as that may be realistic but it's no fun
		if ((bodytemperature > base_body_temp + (temp_tolerance * 2) && environment.temperature > base_body_temp + (temp_tolerance * 2)) || (bodytemperature < base_body_temp - (temp_tolerance * 2) && environment.temperature < base_body_temp - (temp_tolerance * 2)))
			var/transfer_coefficient

			transfer_coefficient = 1
			if (head && (head.body_parts_covered & HEAD) && (environment.temperature < head.protective_temperature))
				transfer_coefficient *= head.heat_transfer_coefficient
			if (wear_mask && (wear_mask.body_parts_covered & HEAD) && (environment.temperature < wear_mask.protective_temperature))
				transfer_coefficient *= wear_mask.heat_transfer_coefficient
			if (wear_suit && (wear_suit.body_parts_covered & HEAD) && (environment.temperature < wear_suit.protective_temperature))
				transfer_coefficient *= wear_suit.heat_transfer_coefficient

			handle_temperature_damage(HEAD, environment.temperature, environment_heat_capacity*transfer_coefficient)

			transfer_coefficient = 1
			if (wear_suit && (wear_suit.body_parts_covered & TORSO) && (environment.temperature < wear_suit.protective_temperature))
				transfer_coefficient *= wear_suit.heat_transfer_coefficient
			if (w_uniform && (w_uniform.body_parts_covered & TORSO) && (environment.temperature < w_uniform.protective_temperature))
				transfer_coefficient *= w_uniform.heat_transfer_coefficient

			handle_temperature_damage(TORSO, environment.temperature, environment_heat_capacity*transfer_coefficient)

			transfer_coefficient = 1
			if (wear_suit && (wear_suit.body_parts_covered & LEGS) && (environment.temperature < wear_suit.protective_temperature))
				transfer_coefficient *= wear_suit.heat_transfer_coefficient
			if (w_uniform && (w_uniform.body_parts_covered & LEGS) && (environment.temperature < w_uniform.protective_temperature))
				transfer_coefficient *= w_uniform.heat_transfer_coefficient

			handle_temperature_damage(LEGS, environment.temperature, environment_heat_capacity*transfer_coefficient)

			transfer_coefficient = 1
			if (wear_suit && (wear_suit.body_parts_covered & ARMS) && (environment.temperature < wear_suit.protective_temperature))
				transfer_coefficient *= wear_suit.heat_transfer_coefficient
			if (w_uniform && (w_uniform.body_parts_covered & ARMS) && (environment.temperature < w_uniform.protective_temperature))
				transfer_coefficient *= w_uniform.heat_transfer_coefficient

			handle_temperature_damage(ARMS, environment.temperature, environment_heat_capacity*transfer_coefficient)

			for (var/atom/A in contents)
				if (A.material)
					A.material.triggerTemp(A, environment.temperature)

		// decoupled this from environmental temp - this should be more for hypothermia/heatstroke stuff
		//if (bodytemperature > base_body_temp || bodytemperature < base_body_temp)

		//Account for massive pressure differences
		return //TODO: DEFERRED

	proc/get_cold_protection()
		// calculate 0-100% insulation from cold environments
		if (!src)
			return FALSE

		// Sealed space suit? If so, consider it to be full protection
		if (protected_from_space())
			return 100

		var/thermal_protection = 10 // base value

		// Resistance from Bio Effects
		if (bioHolder)
			if (bioHolder.HasEffect("fat"))
				thermal_protection += 10
			if (bioHolder.HasEffect("dwarf"))
				thermal_protection += 10

		// Resistance from Clothing
		for (var/obj/item/clothing/C in get_equipped_items())
			thermal_protection += C.cold_resistance

		// Resistance from covered body parts
		if (w_uniform && (w_uniform.body_parts_covered & TORSO))
			thermal_protection += 10

		if (wear_suit)
			if (wear_suit.body_parts_covered & TORSO)
				thermal_protection += 10
			if (wear_suit.body_parts_covered & LEGS)
				thermal_protection += 10
			if (wear_suit.body_parts_covered & ARMS)
				thermal_protection += 10

		thermal_protection = max(0,min(thermal_protection,100))
		return thermal_protection

	proc/get_heat_protection()
		// calculate 0-100% insulation from cold environments
		if (!src)
			return FALSE

		var/thermal_protection = 10 // base value

		// Resistance from Bio Effects
		if (bioHolder)
			if (bioHolder.HasEffect("dwarf"))
				thermal_protection += 10

		// Resistance from Clothing
		for (var/obj/item/clothing/C in get_equipped_items())
			thermal_protection += C.heat_resistance

		// Resistance from covered body parts
		if (w_uniform && (w_uniform.body_parts_covered & TORSO))
			thermal_protection += 10

		if (wear_suit)
			if (wear_suit.body_parts_covered & TORSO)
				thermal_protection += 10
			if (wear_suit.body_parts_covered & LEGS)
				thermal_protection += 10
			if (wear_suit.body_parts_covered & ARMS)
				thermal_protection += 10

		thermal_protection = max(0,min(thermal_protection,100))
		return thermal_protection

	proc/add_fire_protection(var/temp)
		var/fire_prot = 0
		if (head)
			if (head.protective_temperature > temp)
				fire_prot += (head.protective_temperature/10)
		if (wear_mask)
			if (wear_mask.protective_temperature > temp)
				fire_prot += (wear_mask.protective_temperature/10)
		if (glasses)
			if (glasses.protective_temperature > temp)
				fire_prot += (glasses.protective_temperature/10)
		if (ears)
			if (ears.protective_temperature > temp)
				fire_prot += (ears.protective_temperature/10)
		if (wear_suit)
			if (wear_suit.protective_temperature > temp)
				fire_prot += (wear_suit.protective_temperature/10)
		if (w_uniform)
			if (w_uniform.protective_temperature > temp)
				fire_prot += (w_uniform.protective_temperature/10)
		if (gloves)
			if (gloves.protective_temperature > temp)
				fire_prot += (gloves.protective_temperature/10)
		if (shoes)
			if (shoes.protective_temperature > temp)
				fire_prot += (shoes.protective_temperature/10)

		return fire_prot

	proc/handle_temperature_damage(body_part, exposed_temperature, exposed_intensity)
		if (exposed_temperature > base_body_temp && is_heat_resistant())
			return
		if (exposed_temperature < base_body_temp && is_cold_resistant())
			return
		var/discomfort = min(abs(exposed_temperature - bodytemperature)*(exposed_intensity)/2000000, 1)

		switch(body_part)
			if (HEAD)
				TakeDamage("head", 0, 2.5*discomfort, 0, DAMAGE_BURN)
			if (TORSO)
				TakeDamage("chest", 0, 2.5*discomfort, 0, DAMAGE_BURN)
			if (LEGS)
				TakeDamage("l_leg", 0, 0.6*discomfort, 0, DAMAGE_BURN)
				TakeDamage("r_leg", 0, 0.6*discomfort, 0, DAMAGE_BURN)
			if (ARMS)
				TakeDamage("l_arm", 0, 0.4*discomfort, 0, DAMAGE_BURN)
				TakeDamage("r_arm", 0, 0.4*discomfort, 0, DAMAGE_BURN)

	proc/handle_chemicals_in_body()
		if (nodamage) return

//			var/reagent/blood/blood = null
		if (reagents)
			reagents.temperature_reagents(bodytemperature-30, 100)
			if (blood_system && reagents.get_reagent("blood"))
				var/blood2absorb = min(blood_absorption_rate, reagents.get_reagent_amount("blood"))
				reagents.remove_reagent("blood", blood2absorb)
				if (blood_volume <= (500 - blood2absorb))
					blood_volume += blood2absorb
			reagents.metabolize(src)
//				blood = reagents.get_reagent("blood")

		if (nutrition > 0)
			nutrition--

		updatehealth()

		return //TODO: DEFERRED

	proc/handle_blood() // hopefully this won't cause too much lag?
		if (!blood_system) // I dunno if this'll do what I want but hopefully it will
			return

		if (stat == 2 || nodamage || !can_bleed || isvampire(src)) // if we're dead or immortal or have otherwise been told not to bleed, don't bother
			if (bleeding)
				bleeding = 0 // also stop bleeding if we happen to be doing that
			return

		if (blood_volume < 500 && blood_volume > 0) // if we're full or empty, don't bother v
			if (prob(66))
				blood_volume ++ // maybe get a little blood back ^

		if (bleeding)
			var/fluff = pick("better", "like they're healing a bit", "a little better", "itchy", "less tender", "less painful", "like they're closing", "like they're closing up a bit", "like they're closing up a little")
			if (bleeding <= 3 && prob(2)) // blood does clot and all, but we want bleeding to maybe not stop entirely on its own TOO easily
				bleeding --
				boutput(src, "<span style=\"color:blue\">Your wounds feel [fluff].</span>")
			else if (bleeding >= 4 && bleeding <= 7 && prob(5)) // higher bleeding gets a better chance to drop down
				bleeding --
				boutput(src, "<span style=\"color:blue\">Your wounds feel [fluff].</span>")
			else if (bleeding >= 8 && prob(2)) // but there's only so much clotting can do when all your blood is falling out at once
				bleeding --
				boutput(src, "<span style=\"color:blue\">Your wounds feel [fluff].</span>")

		if (!bleeding && get_surgery_status())
			bleeding ++

		if (bleeding && blood_volume)

			var/final_bleed = minmax(bleeding, 0, 10) // still don't want this above 10

			if (prob(max(0, min(final_bleed, 10)) * 5)) // up to 50% chance to make a big bloodsplatter
				bleed(src, final_bleed, 5)

			else
				switch (bleeding)
					if (1 to 2)
						bleed(src, final_bleed, 1) // this proc creates a bloodsplatter on src's tile
					if (3 to 4)
						bleed(src, final_bleed, 2) // it takes care of removing blood, and transferring reagents, color and ling status to the blood
					if (5 to 7)
						bleed(src, final_bleed, 3) // see blood_system.dm for the proc
					if (8 to 10)
						bleed(src, final_bleed, 4)

		if (!is_changeling())

			switch (blood_volume)

				if (-INFINITY to 0)
					take_oxygen_deprivation(1)
					take_brain_damage(2)
					losebreath ++
					drowsyness = max(drowsyness, 4)
					if (prob(10))
						change_misstep_chance(3)
					if (prob(10))
						emote(pick("faint", "collapse", "pale", "shudder", "shiver", "gasp", "moan"))
					if (prob(18))
						var/extreme = pick("", "really ", "very ", "extremely ", "terribly ", "insanely ")
						boutput(src, "<span style=\"color:red\"><strong>You feel [pick("[extreme]ill", "[extreme]sick", "[extreme]numb", "[extreme]cold", "[extreme]dizzy", "[extreme]out of it", "[extreme]confused", "[extreme]off-balance", "[extreme]terrible", "[extreme]awful", "like death", "like you're dying", "[extreme]tingly", "like you're going to pass out", "[extreme]faint")]!</strong></span>")
						weakened +=4
					contract_disease(/ailment/disease/shock, null, null, 1) // if you have no blood you're gunna be in shock

				if (1 to 100)
					take_oxygen_deprivation(1)
					take_brain_damage(1)
					losebreath ++
					drowsyness = max(drowsyness, 3)
					if (prob(6))
						change_misstep_chance(2)
					if (prob(8))
						emote(pick("faint", "collapse", "pale", "shudder", "shiver", "gasp", "moan"))
					if (prob(14))
						var/extreme = pick("", "really ", "very ", "extremely ", "terribly ", "insanely ")
						boutput(src, "<span style=\"color:red\"><strong>You feel [pick("[extreme]ill", "[extreme]sick", "[extreme]numb", "[extreme]cold", "[extreme]dizzy", "[extreme]out of it", "[extreme]confused", "[extreme]off-balance", "[extreme]terrible", "[extreme]awful", "like death", "like you're dying", "[extreme]tingly", "like you're going to pass out", "[extreme]faint")]!</strong></span>")
						weakened +=3
					if (prob(25))
						contract_disease(/ailment/disease/shock, null, null, 1)

				if (101 to 200)
					drowsyness = max(drowsyness, 2)
					if (prob(4))
						change_misstep_chance(1)
					if (prob(6))
						emote(pick("faint", "collapse", "pale", "shudder", "shiver"))
					if (prob(10))
						var/extreme = pick("", "really ", "very ", "extremely ", "terribly ", "insanely ")
						boutput(src, "<span style=\"color:red\"><strong>You feel [pick("[extreme]ill", "[extreme]sick", "[extreme]numb", "[extreme]cold", "[extreme]dizzy", "[extreme]out of it", "[extreme]confused", "[extreme]off-balance", "[extreme]terrible", "[extreme]awful", "like death", "like you're dying", "[extreme]tingly", "like you're going to pass out", "[extreme]faint")]!</strong></span>")
						weakened +=2
					if (prob(25))
						contract_disease(/ailment/disease/shock, null, null, 1)

				if (201 to 300)
					drowsyness = max(drowsyness, 1)
					if (prob(4))
						emote(pick("pale", "shudder", "shiver"))
					if (prob(7))
						var/extreme = pick("", "really ", "very ", "quite ", "sorta ")
						boutput(src, "<span style=\"color:red\"><strong>You feel [pick("[extreme]ill", "[extreme]sick", "[extreme]numb", "[extreme]cold", "[extreme]dizzy", "[extreme]out of it", "[extreme]confused", "[extreme]off-balance", "[extreme]tingly", "[extreme]faint")]!</strong></span>")
						weakened +=1
					if (prob(10))
						contract_disease(/ailment/disease/shock, null, null, 1)

				if (301 to 400)
					if (prob(2))
						emote(pick("pale", "shudder", "shiver"))
					if (prob(5))
						var/extreme = pick("", "kinda ", "a little ", "sorta ", "a bit ")
						boutput(src, "<span style=\"color:red\"><strong>You feel [pick("[extreme]ill", "[extreme]sick", "[extreme]numb", "[extreme]cold", "[extreme]dizzy", "[extreme]out of it", "[extreme]confused", "[extreme]off-balance", "[extreme]tingly", "[extreme]faint")]!</strong></span>")
					if (prob(5))
						contract_disease(/ailment/disease/shock, null, null, 1)

	proc/handle_organs() // is this even where this should go???  ??????  haine gud codr

		if (ignore_organs)
			return

		if (!organHolder)
			organHolder = new(src)
			sleep(10)

		if (!organHolder.head && !nodamage)
			death()

		if (!organHolder.skull && !nodamage) // look okay it's close enough to an organ and there's no other place for it right now shut up
			if (organHolder.head)
				death()
				visible_message("<span style=\"color:red\"><strong>[src]</strong>'s head collapses into a useless pile of skin mush with no skull to keep it in its proper shape!</span>",\
				"<span style=\"color:red\">Your head collapses into a useless pile of skin mush with no skull to keep it in its proper shape!</span>")
		else
			if (organHolder.skull.loc != src)
				organHolder.skull = null

		if (!organHolder.brain && !nodamage)
			/*var/obj/item/organ/brain/myBrain = locate(/obj/item/organ/brain) in src
			if (myBrain)
				brain = myBrain
			else*/
			death()
		else
			if (organHolder.brain.loc != src)
				organHolder.brain = null

		if (!organHolder.heart && !nodamage)
			/*var/obj/item/organ/heart/myHeart = locate(/obj/item/organ/heart) in src
			if (myHeart)
				heart = myHeart
			else */
			if (!is_changeling())
				if (get_oxygen_deprivation())
					take_brain_damage(3)
				else if (prob(10))
					take_brain_damage(1)

				weakened = max(weakened, 5)
				losebreath += 20
				take_oxygen_deprivation(20)
				updatehealth()
		else
			if (organHolder.heart.loc != src)
				organHolder.heart = null
			else if (organHolder.heart.robotic && organHolder.heart.emagged && !organHolder.heart.broken)
				drowsyness = max (drowsyness - 8, 0)
				if (paralysis) paralysis -= 2
				if (stunned) stunned -= 2
				if (weakened) weakened -= 2
				if (sleeping) sleeping = 0
			else if (organHolder.heart.robotic && !organHolder.heart.broken)
				drowsyness = max (drowsyness - 4, 0)
				if (paralysis) paralysis -= 1
				if (stunned) stunned -= 1
				if (weakened) weakened -= 1
				if (sleeping) sleeping = 0
			else if (organHolder.heart.broken)
				if (get_oxygen_deprivation())
					take_brain_damage(3)
				else if (prob(10))
					take_brain_damage(1)

				weakened = max(weakened, 5)
				losebreath += 20
				take_oxygen_deprivation(20)
				updatehealth()

		// lungs are skipped until they can be removed/whatever
		if (!organHolder.left_eye && organHolder.right_eye) // we have no left eye, but we also don't have the blind overlay (presumably)
			if (!hasOverlayComposition(/overlayComposition/blinded))
				addOverlayComposition(/overlayComposition/blinded_l_eye)
				removeOverlayComposition(/overlayComposition/blinded_r_eye)

		else if (!organHolder.right_eye && organHolder.left_eye) // we have no right eye, but we also don't have the blind overlay (presumably)
			if (!hasOverlayComposition(/overlayComposition/blinded))
				addOverlayComposition(/overlayComposition/blinded_r_eye)
				removeOverlayComposition(/overlayComposition/blinded_l_eye)

		else
			removeOverlayComposition(/overlayComposition/blinded_r_eye)
			removeOverlayComposition(/overlayComposition/blinded_l_eye)

	proc/handle_regular_status_updates(controller/process/mobs/parent)

		health = max_health - (get_oxygen_deprivation() + get_toxin_damage() + get_burn_damage() + get_brute_damage())

		// I don't think the revenant needs any of this crap - Marq
		if (bioHolder && bioHolder.HasEffect("revenant") || stat == 2) //You also don't need to do a whole lot of this if the dude's dead.
			return

		if (stamina == STAMINA_NEG_CAP)
			paralysis = max(paralysis, 10)

		//maximum modifiers.
		stamina_max = max((STAMINA_MAX + get_stam_mod_max()), 0)
		stamina = min(stamina, stamina_max)

		//Modify stamina.
		var/final_mod = (stamina_regen + get_stam_mod_regen())
		if (final_mod > 0)
			add_stamina(abs(final_mod))
		else if (final_mod < 0)
			remove_stamina(abs(final_mod))

		parent.setLastTask("status_updates implant check", src)
		for (var/obj/item/implant/I in implant)
			if (istype(I, /obj/item/implant/robust))
				var/obj/item/implant/robust/R = I
				if (health < 0)
					R.inactive = 1
					reagents.add_reagent("salbutamol", 20) // changed this from dexP // cogwerks
					reagents.add_reagent("inaprovaline", 15)
					reagents.add_reagent("omnizine", 25)
					reagents.add_reagent("teporone", 20)
					if (mind) boutput(src, "<span style=\"color:blue\">Your Robusttec-Implant uses all of its remaining energy to save you and deactivates.</span>")
					implant -= I
				else if (health < 40 && !R.inactive)
					if (!reagents.has_reagent("omnizine", 10))
						reagents.add_reagent("omnizine", 10)
					R.inactive = 1
					spawn (300) R.inactive = 0

			if (istype(I, /obj/item/implant/health))
				if (!mini_health_hud)
					mini_health_hud = 1
				var/obj/item/implant/health/H = I
				var/data/record/probably_my_record = null
				for (var/data/record/R in data_core.medical)
					if (R.fields["name"] == real_name)
						probably_my_record = R
						break
				if (probably_my_record)
					probably_my_record.fields["h_imp"] = "[H.sensehealth()]"
				if (health <= 0 && !H.reported_health)
					DEBUG_MESSAGE("[src] calling to report crit")
					H.health_alert()

				if (health > 0 && H.reported_health) // we're out of crit, let our implant alert people again
					H.reported_health = 0
				if (stat != 2 && H.reported_death) // we're no longer dead, let our implant alert people again
					H.reported_death = 0

		//parent.setLastTask("status_updates max value calcs", src)

		parent.setLastTask("status_updates sleep and paralysis calcs", src)
		if (asleep) sleeping = 4

		if (sleeping)
			paralysis = max(paralysis, 3)
			if (prob(10) && (health > 0)) spawn (0) emote("snore")
			if (!asleep) sleeping--

		if (resting)
			weakened = max(weakened, 2)

		parent.setLastTask("status_updates health calcs", src)
		var/is_chg = is_changeling()
		//if (brain_op_stage == 4.0) // handled above in handle_organs() now
			//death()
		if (get_brain_damage() >= 120 || (health + (get_oxygen_deprivation() / 2)) <= -500) //-200) a shitty test here // let's lower the weight of oxy
			if (!is_chg)
				death()
			else if (suiciding)
				death()

		if (get_brain_damage() >= 100) // braindeath
			if (!is_chg)
				losebreath+=10
				weakened = 30
		if (health <= -100)
			var/deathchance = min(99, ((get_brain_damage() * -5) + (health + (get_oxygen_deprivation() / 2))) * -0.01)
			if (prob(deathchance))
				death()

		/////////////////////////////////////////////
		//// cogwerks - critical health rewrite /////
		/////////////////////////////////////////////
		//// goal: make crit a medical emergency ////
		//// instead of game over black screen time /
		/////////////////////////////////////////////


		if (health < 0 && stat != 2)
			if (prob(5))
				emote(pick("faint", "collapse", "cry","moan","gasp","shudder","shiver"))
			if (stuttering <= 5)
				stuttering+=5
			if (get_eye_blurry() <= 5)
				change_eye_blurry(5)
			if (prob(7))
				change_misstep_chance(2)
			if (prob(5))
				paralysis = max(paralysis, 2)
			switch(health)
				if (-INFINITY to -100)
					take_oxygen_deprivation(1)
					/*if (reagents)
						if (!reagents.has_reagent("inaprovaline"))
							take_oxygen_deprivation(1)*/
					if (prob(health * -0.1))
						contract_disease(/ailment/disease/flatline,null,null,1)
						//boutput(world, "\b LOG: ADDED FLATLINE TO [src].")
					if (prob(health * -0.2))
						contract_disease(/ailment/disease/heartfailure,null,null,1)
						//boutput(world, "\b LOG: ADDED HEART FAILURE TO [src].")
					if (stat == 0)
						sleep(0)
						if (src && mind)
							lastgasp() // if they were ok before dropping below zero health, call lastgasp() before setting them unconscious
					if (stat != 2)
						stat = 1
					//paralysis = max(paralysis, 5)
					// losebreath can handle this part
				if (-99 to -80)
					take_oxygen_deprivation(1)
					/*if (reagents)
						if (!reagents.has_reagent("inaprovaline"))
							take_oxygen_deprivation(1)*/
					if (prob(4))
						boutput(src, "<span style=\"color:red\"><strong>Your chest hurts...</strong></span>")
						paralysis++
						contract_disease(/ailment/disease/heartfailure,null,null,1)
				if (-79 to -51)
					/*if (reagents)
						if (!reagents.has_reagent("inaprovaline")) take_oxygen_deprivation(1)*/
					if (prob(10)) // shock added back to crit because it wasn't working as a bloodloss-only thing
						contract_disease(/ailment/disease/shock,null,null,1)
						//boutput(world, "\b LOG: ADDED SHOCK TO [src].")
					if (prob(health * -0.08))
						contract_disease(/ailment/disease/heartfailure,null,null,1)
						//boutput(world, "\b LOG: ADDED HEART FAILURE TO [src].")
					if (prob(6))
						boutput(src, "<span style=\"color:red\"><strong>You feel [pick("horrible pain", "awful", "like shit", "absolutely awful", "like death", "like you are dying", "nothing", "warm", "sweaty", "tingly", "really, really bad", "horrible")]</strong>!</span>")
						weakened +=3
					if (prob(3))
						paralysis++
				if (-50 to 0)
					take_oxygen_deprivation(1)
					/*if (reagents)
						if (!reagents.has_reagent("inaprovaline") && prob(50))
							take_oxygen_deprivation(1)*/
					if (prob(3))
						contract_disease(/ailment/disease/shock,null,null,1)
						//boutput(world, "\b LOG: ADDED SHOCK TO [src].")
					if (prob(5))
						boutput(src, "<span style=\"color:red\"><strong>You feel [pick("terrible", "awful", "like shit", "sick", "numb", "cold", "sweaty", "tingly", "horrible")]!</strong></span>")
						weakened +=3

		parent.setLastTask("status_updates blindness checks", src)
		if (istype(glasses, /obj/item/clothing/glasses))
			var/obj/item/clothing/glasses/G = glasses
			if (G.block_vision)
				blinded = 1

		//A ghost costume without eyeholes is a bad idea.
		if (istype(wear_suit, /obj/item/clothing/suit/bedsheet))
			var/obj/item/clothing/suit/bedsheet/B = wear_suit
			if (!B.eyeholes && !B.cape)
				blinded = 1

		else if (istype(wear_suit, /obj/item/clothing/suit/cardboard_box))
			var/obj/item/clothing/suit/cardboard_box/B = wear_suit
			if (!B.eyeholes)
				blinded = 1

		if (manualblinking)
			var/showmessages = 1
			var/tempblind = get_eye_damage(1)

			if (find_ailment_by_type(/ailment/disability/blind))
				showmessages = 0

			blinktimer++
			switch(blinktimer)
				if (20)
					if (showmessages) boutput(src, "<span style=\"color:red\">Your eyes feel slightly uncomfortable!</span>")
				if (30)
					if (showmessages) boutput(src, "<span style=\"color:red\">Your eyes feel quite dry!</span>")
				if (40)
					if (showmessages) boutput(src, "<span style=\"color:red\">Your eyes feel very dry and uncomfortable, it's getting difficult to see!</span>")
					change_eye_blurry(3, 3)
				if (41 to 59)
					change_eye_blurry(3, 3)
				if (60)
					if (showmessages) boutput(src, "<span style=\"color:red\">Your eyes are so dry that you can't see a thing!</span>")
					take_eye_damage(max(0, min(3, 3 - tempblind)), 1)
				if (61 to 99)
					take_eye_damage(max(0, min(3, 3 - tempblind)), 1)
				if (100) //blinking won't save you now, buddy
					if (showmessages) boutput(src, "<span style=\"color:red\">You feel a horrible pain in your eyes. That can't be good.</span>")
					contract_disease(/ailment/disability/blind,null,null,1)

			if (blinkstate) take_eye_damage(max(0, min(1, 1 - tempblind)), 1)

		if (get_eye_damage(1)) // Temporary blindness.
			take_eye_damage(-1, 1)
			blinded = 1

		// drsingh :wtc: why was there a runtime error about comparing "" to 50 here? varedit or something?
		// welp thisll fix it
		parent.setLastTask("status_updates disability checks", src)
		stuttering = isnum(stuttering) ? min(stuttering, 50) : 0
		if (stuttering) stuttering--

		if (get_ear_damage(1)) // Temporary deafness.
			take_ear_damage(-1, 1)

		if (get_ear_damage() && (get_ear_damage() <= get_ear_damage_natural_healing_threshold()))
			take_ear_damage(-0.05)

		if (get_eye_blurry())
			change_eye_blurry(-1)

		if (druggy > 0)
			druggy--
			druggy = max(0, druggy)

		if (nodamage)
			parent.setLastTask("status_updates nodamage reset", src)
			HealDamage("All", 10000, 10000)
			take_toxin_damage(-5000)
			take_oxygen_deprivation(-5000)
			take_brain_damage(-120)
			irradiate(-100)
			paralysis = 0
			weakened = 0
			stunned = 0
			stuttering = 0
			take_ear_damage(-INFINITY)
			take_ear_damage(-INFINITY, 1)
			change_eye_blurry(-INFINITY)
			druggy = 0
			blinded = null

		return TRUE

	proc/handle_stuns_lying(controller/process/mobs/parent)
		parent.setLastTask("status_updates lying/standing checks")
		var/tmp/lying_old = lying
		var/cant_lie = (limbs && istype(limbs.l_leg, /obj/item/parts/robot_parts/leg/left/treads) && istype(limbs.r_leg, /obj/item/parts/robot_parts/leg/right/treads) && !locate(/obj/table, loc) && !locate(/obj/machinery/optable, loc))

		var/must_lie = (!cant_lie && src.limbs && !src.limbs.l_leg && !src.limbs.r_leg) //hasn't got a leg to stand on... haaa

		var/changeling_fakedeath = 0
		var/abilityHolder/changeling/C = get_ability_holder(/abilityHolder/changeling)
		if (C && C.in_fakedeath)
			changeling_fakedeath = 1

		if (stat != 2) //Alive.
			if (paralysis || stunned || weakened || changeling_fakedeath || slowed) //Stunned etc.
				parent.setLastTask("status_updates lying/standing checks stun calcs")
				var/setStat = stat
				var/oldStat = stat
				if (stunned > 0)
					stunned--
					setStat = 0
				if (slowed > 0)
					slowed--
					setStat = 0
				if (weakened > 0 && !fakedead)
					weakened--
					if (!cant_lie) lying = 1
					setStat = 0
				if (paralysis > 0)
					paralysis--
					blinded = 1
					if (!cant_lie) lying = 1
					setStat = 1
				if (stat == 0 && setStat == 1)
					parent.setLastTask("status_updates lying/standing checks last gasp")
					sleep(0)
					if (src && mind) lastgasp() // calling lastgasp() here because we just got knocked out
				if (must_lie)
					lying = 1

				stat = setStat

				parent.setLastTask("status_updates lying/standing checks item dropping")
				var/h = hand
				hand = 0
				drop_item()
				hand = 1
				drop_item()
				hand = h
				if (juggling())
					drop_juggle()

				parent.setLastTask("status_updates lying/standing checks recovery checks")
				if (world.time - last_recovering_msg >= 60 || last_recovering_msg == 0)
					if ( ((paralysis && paralysis <= 3) && stunned <= paralysis && weakened <= paralysis) || ((stunned && stunned <= 3) && paralysis <= stunned && weakened <= stunned) || ((weakened && weakened <= 3) && paralysis <= weakened && stunned <= weakened) )
						last_recovering_msg = world.time
						if (mind && !asleep)
							if (resting)
								boutput(src, "<span style=\"color:green\">You are resting. Click 'rest' to toggle back to stand.</span>")
							else
								boutput(src, "<span style=\"color:green\">You begin to recover.</span>")
				//		for (var/mob/V in viewers(7,src))
				//			boutput(V, "<span style=\"color:red\">[name] begins to recover.</span>")
				else if ((oldStat == 1) && (!paralysis && !stunned && !weakened && !changeling_fakedeath))
					parent.setLastTask("status updates lying/standing checks wakeup ogg")
					src << sound('sound/misc/molly_revived.ogg', volume=50)

			else	//Not stunned.
				if (must_lie) lying = 1
				else lying = 0
				stat = 0

		else //Dead.
			if ((reagents && reagents.has_reagent("montaguone_extra")) || cant_lie) lying = 0
			else lying = 1
			blinded = 1
			stat = 2

		if (lying != lying_old)
			// Update clothing - Taken out of Life() to reduce icon overhead
			parent.setLastTask("status_updates lying/standing checks update clothing")
			update_clothing()
			density = !( lying )


	proc/handle_regular_sight_updates()

////Mutrace and normal sight
		if (stat != 2)
			sight &= ~SEE_TURFS
			sight &= ~SEE_MOBS
			sight &= ~SEE_OBJS

			if (mutantrace)
				mutantrace.sight_modifier()
			else
				if (traitHolder && traitHolder.hasTrait("cateyes"))
					see_in_dark = SEE_DARK_HUMAN + 2
				else
					see_in_dark = SEE_DARK_HUMAN
				see_invisible = 0

			if (isvampire(src))
				var/turf/T = get_turf(src)
				if (check_vampire_power(2) == 1 && (T && !isrestrictedz(T.z)))
					sight |= SEE_MOBS
					sight |= SEE_TURFS
					sight |= SEE_OBJS
					see_in_dark = SEE_DARK_FULL
					see_invisible = 2

				else
					if (check_vampire_power(1) == 1 && !isrestrictedz(z))
						sight |= SEE_MOBS
						see_invisible = 2

////Dead sight
		var/turf/T = eye ? get_turf(eye) : get_turf(src) //They might be in a closet or something idk
		if ((stat == 2 ||( bioHolder && bioHolder.HasEffect("xray"))) && (T && !isrestrictedz(T.z)))
			sight |= SEE_TURFS
			sight |= SEE_MOBS
			sight |= SEE_OBJS
			see_in_dark = SEE_DARK_FULL
			if (client && client.adventure_view)
				see_invisible = 21
			else
				see_invisible = 2
			return

////Ship sight
		if (istype(loc, /obj/machinery/vehicle))
			var/obj/machinery/vehicle/ship = loc
			if (ship.sensors)
				if (ship.sensors.active)
					sight |= ship.sensors.sight
					see_in_dark = ship.sensors.see_in_dark
					if (client && client.adventure_view)
						see_invisible = 21
					else
						see_invisible = ship.sensors.see_invisible
					return

		if (traitHolder && traitHolder.hasTrait("infravision"))
			if (see_infrared < 1)
				see_infrared = 1

////Glasses
		if ((istype(glasses, /obj/item/clothing/glasses/meson) || eye_istype(/obj/item/organ/eye/cyber/meson)) && !isrestrictedz(T.z))
			sight |= SEE_TURFS
			if (see_in_dark < initial(see_in_dark) + 1)
				see_in_dark++
			if (see_invisible < 1)
				see_invisible = 1
			if (see_infrared < 1)
				see_infrared = 1

		else if (istype(glasses, /obj/item/clothing/glasses/construction) && !isrestrictedz(T.z))
			if (see_in_dark < initial(see_in_dark) + 1)
				see_in_dark++
			if (see_invisible < 8)
				see_invisible = 8

		else if ((istype(glasses, /obj/item/clothing/glasses/thermal) || eye_istype(/obj/item/organ/eye/cyber/thermal)) && !isrestrictedz(T.z))
			//sight |= SEE_MOBS
			if (see_in_dark < initial(see_in_dark) + 4)
				see_in_dark += 4
			if (see_invisible < 2)
				see_invisible = 2
			if (see_infrared < 1)
				see_infrared = 1

		else if (istype(wear_mask, /obj/item/clothing/mask/predator) && !isrestrictedz(T.z))
			sight |= SEE_MOBS // Predators kinda need proper thermal vision, I've found in playtesting (Convair880).
			if (see_in_dark < SEE_DARK_FULL)
				see_in_dark = SEE_DARK_FULL
			if (see_invisible < 2)
				see_invisible = 2

		else if (istype(glasses, /obj/item/clothing/glasses/regular/ecto) || eye_istype(/obj/item/organ/eye/cyber/ecto))
			if (see_in_dark != 1)
				see_in_dark = 1
			if (see_invisible < 15)
				see_invisible = 15

////Reagents
		if (reagents.has_reagent("green_goop") && !isrestrictedz(T.z))
			if (see_in_dark != 1)
				see_in_dark = 1
			if (see_invisible < 15)
				see_invisible = 15

		if (client && client.adventure_view)
			see_invisible = 21

	proc/handle_regular_hud_updates()
		if (stamina_bar) stamina_bar.update_value(src)
		//hud.update_indicators()
		hud.update_health_indicator()
		hud.update_temp_indicator()
		hud.update_blood_indicator()
		hud.update_pulling()

		var/color_mod_r = 255
		var/color_mod_g = 255
		var/color_mod_b = 255
		if (istype(glasses, /obj/item/clothing/glasses/thermal) || eye_istype(/obj/item/organ/eye/cyber/thermal))
			color_mod_g *= 0.8 // red tint
			color_mod_b *= 0.8
		if (istype(wear_mask, /obj/item/clothing/mask/gas))
			color_mod_r *= 0.8 // green tint
			color_mod_b *= 0.8
		if (istype(glasses, /obj/item/clothing/glasses/sunglasses) || eye_istype(/obj/item/organ/eye/cyber/sunglass))
			color_mod_r *= 0.95 // darken a little
			color_mod_g *= 0.95
			color_mod_b *= 0.9
		if (istype(head, /obj/item/clothing/head/helmet/welding) && !head:up)
			color_mod_r *= 0.3 // darken
			color_mod_g *= 0.3
			color_mod_b *= 0.3
		if (druggy)
			vision.animate_color_mod(rgb(rand(0, 255), rand(0, 255), rand(0, 255)), 15)
		else
			vision.set_color_mod(rgb(color_mod_r, color_mod_g, color_mod_b))

		if (istype(glasses, /obj/item/clothing/glasses/visor))
			vision.set_scan(1)
		else
			vision.set_scan(0)

		if (istype(glasses, /obj/item/clothing/glasses/healthgoggles))
			var/obj/item/clothing/glasses/healthgoggles/G = glasses
			if (client && !(G.assigned || G.assigned == client))
				G.assigned = client
				if (!(G in processing_items))
					processing_items.Add(G)
				//G.updateIcons()

		else if (organHolder && istype(organHolder.left_eye, /obj/item/organ/eye/cyber/prodoc))
			var/obj/item/organ/eye/cyber/prodoc/G = organHolder.left_eye
			if (client && !(G.assigned || G.assigned == client))
				G.assigned = client
				if (!(G in processing_items))
					processing_items.Add(G)
				//G.updateIcons()
		else if (organHolder && istype(organHolder.right_eye, /obj/item/organ/eye/cyber/prodoc))
			var/obj/item/organ/eye/cyber/prodoc/G = organHolder.right_eye
			if (client && !(G.assigned || G.assigned == client))
				G.assigned = client
				if (!(G in processing_items))
					processing_items.Add(G)
				//G.updateIcons()

		if (!sight_check(1) && stat != 2)
			addOverlayComposition(/overlayComposition/blinded) //ov1
		else
			removeOverlayComposition(/overlayComposition/blinded) //ov1
		vision.animate_dither_alpha(get_eye_blurry() / 10 * 255, 15) // animate it so that it doesnt "jump" as much
		return TRUE

	proc/handle_random_events()
		if (prob(1) && prob(2))
			spawn (0)
				emote("sneeze")
				return

	proc/handle_virus_updates()
		if (prob(40))
			for (var/mob/living/carbon/M in oviewers(4, src))
				M.viral_transmission(src,"Airborne",0)

			for (var/obj/decal/cleanable/blood/B in view(4, src))
				for (var/ailment_data/disease/virus in B.diseases)
					if (virus.spread == "Airborne")
						contract_disease(null,null,virus,0)
		if (prob(40))
			for (var/mob/living/carbon/M in oviewers(6, src))
				if (prob(10))
					M.viral_transmission(src, "Sight", 0)

		if (stat != 2)
			for (var/ailment_data/am in ailments)
				am.stage_act()

	proc/check_if_buckled()
		if (buckled)
			if (buckled.loc != loc)
				buckled = null
				return
			lying = istype(buckled, /obj/stool/bed) || istype(buckled, /obj/machinery/conveyor)
			if (lying)
				drop_item()
			density = 1
		else
			density = !lying

	proc/handle_stomach()
		spawn (0)
			for (var/mob/M in stomach_contents)
				if (M.loc != src)
					stomach_contents.Remove(M)
					continue
				if (iscarbon(M) && stat != 2)
					if (M.stat == 2)
						M.death(1)
						stomach_contents.Remove(M)
						if (M.client)
							var/mob/dead/observer/newmob = new(M)
							M:client:mob = newmob
							M.mind.transfer_to(newmob)
						qdel(M)
						emote("burp")
						playsound(loc, "sound/misc/burp.ogg", 50, 1)
						continue
					if (air_master.current_cycle%3==1)
						if (!M.nodamage)
							M.TakeDamage("chest", 5, 0)
						nutrition += 10

	proc/handle_random_emotes()
		if (!islist(random_emotes) || !random_emotes.len || stat)
			return
		var/emote2do = pick(random_emotes)
		emote(emote2do)

/mob/living/carbon/human/Login()
	..()

	update_clothing()

	if (ai_active)
		ai_active = 0
	if (organHolder && organHolder.brain && mind)
		organHolder.brain.setOwner(mind)
	return

/mob/living/carbon/human/Logout()
	..()
	if (!ai_active && is_npc)
		ai_active = 1
	return

/mob/living/carbon/human/get_heard_name()
	var/alt_name = ""
	if (name != real_name)
		if (wear_id && wear_id:registered && wear_id:registered != real_name)
			alt_name = " (as [wear_id:registered])"
		else if (!wear_id)
			alt_name = " (as Unknown)"

	var/rendered
	if (is_npc)
		rendered = "<span class='name'>"
	else
		rendered = "<span class='name' data-ctx='\ref[mind]'>"
	if (wear_mask && wear_mask.vchange)//(istype(wear_mask, /obj/item/clothing/mask/gas/voice))
		if (wear_id)
			rendered += "[wear_id:registered]</span>"
		else
			rendered += "Unknown</span>"
	else
		rendered += "[real_name]</span>[alt_name]"

	return rendered

/mob/living/carbon/human/say(var/message)
	if (mutantrace && mutantrace.override_language)
		say_language = mutantrace.override_language

	message = copytext(message, 1, MAX_MESSAGE_LEN)

	if (fakedead)
		var/the_verb = pick("wails","moans","laments")
		boutput(src, "<span class='game deadsay'><span class='prefix'>DEAD:</span> [get_heard_name()] [the_verb], <span class='message'>\"[message]\"</span></span>")
		return

	if (dd_hasprefix(message, "*") || stat == 2)
		..(message)
		return

	if (bioHolder.HasEffect("revenant"))
		visible_message("<span style=\"color:red\">[src] makes some [pick("eldritch", "eerie", "otherworldly", "netherly", "spooky", "demonic", "haunting")] noises!</span>")
		return

	if (stamina < STAMINA_WINDED_SPEAK_MIN)
		emote(pick("gasp", "choke", "cough"))
		//boutput(src, "<span style=\"color:red\">You are too exhausted to speak.</span>")
		return


	if (robot_talk_understand)
		if (length(message) >= 2)
			if (copytext(lowertext(message), 1, 3) == ":s")
				message = copytext(message, 3)
				robot_talk(message)
				return

	message = process_accents(src,message)

	for (var/uid in pathogens)
		var/pathogen/P = pathogens[uid]
		P.onsay(src, message)

	..(message)

/*/mob/living/carbon/human/say_understands(var/other)
	if (mutantrace)
		return mutantrace.say_understands(other)
	if (istype(other, /mob/living/silicon/ai))
		return TRUE
	if (istype(other, /mob/living/silicon/robot))
		return TRUE
	if (istype(other, /mob/living/silicon/hivebot))
		return TRUE
	if (istype(other, /mob/living/silicon/hive_mainframe))
		return TRUE
	if (ishuman(other) && (!other:mutantrace || !other:mutantrace.exclusive_language))
		return TRUE*/

/mob/living/carbon/human/say_quote(var/text)
	if (mutantrace)
		if (mutantrace.voice_message)
			voice_name = mutantrace.voice_name
			voice_message = mutantrace.voice_message
		if (text == "" || !text)
			return mutantrace.say_verb()
		return "[mutantrace.say_verb()], \"[text]\""
	else
		voice_name = initial(voice_name)
		voice_message = initial(voice_message)

	return ..(text)

//Lallander was here
/mob/living/carbon/human/whisper(message as text)
	if (bioHolder.HasEffect("revenant"))
		return say(message)
	var/message_mode = null
	var/secure_headset_mode = null
	if (get_brain_damage() >= 60 && prob(50))
		message_mode = "headset"
	// Special message handling
	else if (copytext(message, 1, 2) == ";")
		message_mode = "headset"
		message = copytext(message, 2)

	if (stamina < STAMINA_WINDED_SPEAK_MIN)
		emote(pick("gasp", "choke", "cough"))
		//boutput(src, "<span style=\"color:red\">You are too exhausted to speak.</span>")
		return

	if (oxyloss > 10)
		emote("gasp")
		return

	else if ((length(message) >= 2) && (copytext(message,1,2) == ":"))
		switch (lowertext( copytext(message,2,4) ))
			if ("rh")
				message_mode = "right hand"
				message = copytext(message, 4)

			if ("lh")
				message_mode = "left hand"
				message = copytext(message, 4)

			if ("in")
				message_mode = "intercom"
				message = copytext(message, 4)

			else
				if (ishuman(src))
					message_mode = "secure headset"
					secure_headset_mode = lowertext(copytext(message,2,3))
				message = copytext(message, 3)

	message = trim(copytext(sanitize(message), 1, MAX_MESSAGE_LEN))

	if (!message)
		return

	logTheThing("diary", src, null, "(WHISPER): [message]", "whisper")
	logTheThing("whisper", src, null, "SAY: [message] (Whispered)")

	if (client && !client.holder && url_regex && url_regex.Find(message))
		boutput(src, "<span style=\"color:blue\"><strong>Web/BYOND links are not allowed in ingame chat.</strong></span>")
		boutput(src, "<span style=\"color:red\">&emsp;<strong>\"[message]</strong>\"</span>")
		return

	if (client && client.ismuted())
		boutput(src, "You are currently muted and may not speak.")
		return

	if (stat == 2)
		return say_dead(message)

	if (stat)
		return

	var/alt_name = ""
	if (ishuman(src) && name != real_name)
		if (src:wear_id && src:wear_id:registered && src:wear_id:registered != real_name)
			alt_name = " (as [src:wear_id:registered])"
		else if (!src:wear_id)
			alt_name = " (as Unknown)"

	// Mute disability
	if (bioHolder.HasEffect("mute"))
		boutput(src, "<span style=\"color:red\">You seem to be unable to speak.</span>")
		return

	if (istype(wear_mask, /obj/item/clothing/mask/muzzle))
		boutput(src, "<span style=\"color:red\">Your muzzle prevents you from speaking.</span>")
		return

	var/italics = 1
	var/message_range = 1
	var/forced_language = null
	forced_language = get_special_language(secure_headset_mode)

	message = process_accents(src,message)
	var/list/messages = process_language(message, forced_language)
	var/lang_id = get_language_id(forced_language)

	switch (message_mode)
		if ("headset", "secure headset", "right hand", "left hand")
			talk_into_equipment(message_mode, messages, secure_headset_mode, lang_id)
			message_range = 0
			italics = 1

		if ("intercom")
			for (var/obj/item/device/radio/intercom/I in view(1, null))
				I.talk_into(src, messages, null, real_name, lang_id)

			message_range = 0
			italics = 1

	var/list/eavesdropping = hearers(2, src)
	eavesdropping -= src
	var/list/watching  = viewers(5, src)
	watching -= src
	watching -= eavesdropping

	var/list/heard_a = list() // understood us
	var/list/heard_b = list() // didn't understand us

	var/rendered = null

	if (message_range)
		var/heardname = real_name
		for (var/obj/O in view(message_range, src))
			spawn (0)
				if (O)
					O.hear_talk(src, messages, heardname, lang_id)

		var/list/listening = all_hearers(message_range, src)
		eavesdropping -= listening

		for (var/mob/M in listening)
			if (M.say_understands(src))
				heard_a += M
			else
				heard_b += M

	for (var/mob/M in watching)
		if (M.say_understands(src))
			rendered = "<span class='game say'><span class='name'>[name]</span> whispers something.</span>"
		else
			rendered = "<span class='game say'><span class='name'>[voice_name]</span> whispers something.</span>"
		M.show_message(rendered, 2)

	var/list/olocs = list()
	var/thickness = 0
	if (!isturf(loc))
		olocs = obj_loc_chain(src)
		for (var/atom/movable/AM in olocs)
			thickness += AM.soundproofing
	var/list/processed = list()

	if (length(heard_a))
		processed = saylist(messages[1], heard_a, olocs, thickness, italics, processed)

	if (length(heard_b))
		processed = saylist(messages[2], heard_b, olocs, thickness, italics, processed, 1)

	message = messages[1]
	for (var/mob/M in eavesdropping)
		if (M.say_understands(src, lang_id))
			var/message_c = stars(message)

			if (!istype(src, /mob/living/carbon/human))
				rendered = "<span class='game say'><span class='name'>[name]</span> whispers, <span class='message'>\"[message_c]\"</span></span>"
			else
				if (wear_mask && wear_mask.vchange)//(istype(wear_mask, /obj/item/clothing/mask/gas/voice))
					if (wear_id)
						rendered = "<span class='game say'><span class='name'>[wear_id:registered]</span> whispers, <span class='message'>\"[message_c]\"</span></span>"
					else
						rendered = "<span class='game say'><span class='name'>Unknown</span> whispers, <span class='message'>\"[message_c]\"</span></span>"
				else
					rendered = "<span class='game say'><span class='name'>[real_name]</span>[alt_name] whispers, <span class='message'>\"[message_c]\"</span></span>"

		else
			rendered = "<span class='game say'><span class='name'>[voice_name]</span> whispers something.</span>"

		M.show_message(rendered, 2)

	if (italics)
		message = "<em>[message]</em>"

	if (!istype(src, /mob/living/carbon/human))
		rendered = "<span class='game say'><span class='name'>[name]</span> <span class='message'>[message]</span></span>"
	else
		if (src.wear_mask && src.wear_mask.vchange)//(istype(src:wear_mask, /obj/item/clothing/mask/gas/voice))
			if (wear_id)
				rendered = "<span class='game say'><span class='name'>[wear_id:registered]</span> <span class='message'>[message]</span></span>"
			else
				rendered = "<span class='game say'><span class='name'>Unknown</span> <span class='message'>[message]</span></span>"
		else
			rendered = "<span class='game say'><span class='name'>[real_name]</span>[alt_name] <span class='message'>[message]</span></span>"

	for (var/mob/M in mobs)
		if (istype(M, /mob/new_player))
			continue
		if (M.stat > 1 && !(M in heard_a) && !istype(M, /mob/dead/target_observer))
			M.show_message(rendered, 2)

/mob/living/carbon/human/var/const
	slot_back = 1
	slot_wear_mask = 2
	slot_l_hand = 4
	slot_r_hand = 5
	slot_belt = 6
	slot_wear_id = 7
	slot_ears = 8
	slot_glasses = 9
	slot_gloves = 10
	slot_head = 11
	slot_shoes = 12
	slot_wear_suit = 13
	slot_w_uniform = 14
	slot_l_store = 15
	slot_r_store = 16
//	slot_w_radio = 17
	slot_in_backpack = 18
	slot_in_belt = 19

/mob/living/carbon/human/put_in_hand(obj/item/I, which)
	if (!istype(I))
		return FALSE
	if (equipped() && istype(equipped(), /obj/item/magtractor))
		var/obj/item/magtractor/M = equipped()
		if (M.pickupItem(I, src))
			actions.start(new/action/magPickerHold(M), src)
			return TRUE
		return FALSE
	if (isnull(which))
		if (put_in_hand(I, hand))
			return TRUE
		if (put_in_hand(I, !hand))
			return TRUE
		return FALSE
	else
		if (which)
			if (!l_hand)
				if (I == r_hand && I.cant_self_remove)
					return FALSE
				if (limbs && (!limbs.l_arm || istype(limbs.l_arm, /obj/item/parts/human_parts/arm/left/item)))
					return FALSE
				l_hand = I
				I.pickup(src)
				I.add_fingerprint(src)
				I.set_loc(src)
				update_inhands()
				hud.add_object(I, HUD_LAYER+2, ui_lhand)
				return TRUE
			else
				return FALSE
		else
			if (!r_hand)
				if (I == l_hand && I.cant_self_remove)
					return FALSE
				if (limbs && (!limbs.r_arm || istype(limbs.r_arm, /obj/item/parts/human_parts/arm/right/item)))
					return FALSE
				r_hand = I
				I.pickup(src)
				I.add_fingerprint(src)
				I.set_loc(src)
				update_inhands()
				hud.add_object(I, HUD_LAYER+2, ui_rhand)
				return TRUE
			else
				return FALSE

/mob/living/carbon/human/proc/get_slot(slot)
	switch(slot)
		if (slot_back)
			return back
		if (slot_wear_mask)
			return wear_mask
		if (slot_l_hand)
			return l_hand
		if (slot_r_hand)
			return r_hand
		if (slot_belt)
			return belt
		if (slot_wear_id)
			return wear_id
		if (slot_ears)
			return ears
		if (slot_glasses)
			return glasses
		if (slot_gloves)
			return gloves
		if (slot_head)
			return head
		if (slot_shoes)
			return shoes
		if (slot_wear_suit)
			return wear_suit
		if (slot_w_uniform)
			return w_uniform
		if (slot_l_store)
			return l_store
		if (slot_r_store)
			return r_store

/mob/living/carbon/human/proc/force_equip(obj/item/I, slot)
	//warning: icky code
	var/equipped = 0
	switch(slot)
		if (slot_back)
			if (!back)
				back = I
				hud.add_object(I, HUD_LAYER+2, ui_back)
				I.equipped(src, "back")
				equipped = 1
		if (slot_wear_mask)
			if (!wear_mask && organHolder && organHolder.head)
				wear_mask = I
				hud.add_other_object(I, ui_mask)
				I.equipped(src, "mask")
				equipped = 1
		if (slot_l_hand)
			equipped = put_in_hand(I, 1)
		if (slot_r_hand)
			equipped = put_in_hand(I, 0)
		if (slot_belt)
			if (!belt)
				belt = I
				hud.add_object(I, HUD_LAYER+2, ui_belt)
				I.equipped(src, "belt")
				equipped = 1
		if (slot_wear_id)
			if (!wear_id)
				wear_id = I
				hud.add_other_object(I, ui_id)
				I.equipped(src, "id")
				equipped = 1
		if (slot_ears)
			if (!ears && organHolder && organHolder.head)
				ears = I
				hud.add_other_object(I, ui_ears)
				I.equipped(src, "ears")
				equipped = 1
		if (slot_glasses)
			if (!glasses && organHolder && organHolder.head)
				glasses = I
				hud.add_other_object(I, ui_glasses)
				I.equipped(src, "eyes")
				equipped = 1
		if (slot_gloves)
			if (!gloves)
				gloves = I
				hud.add_other_object(I, ui_gloves)
				I.equipped(src, "gloves")
				equipped = 1
		if (slot_head)
			if (!head && organHolder && organHolder.head)
				head = I
				hud.add_other_object(I, ui_head)
				I.equipped(src, "head")
				equipped = 1
				update_hair_layer()
		if (slot_shoes)
			if (!shoes)
				shoes = I
				hud.add_other_object(I, ui_shoes)
				I.equipped(src, "shoes")
				equipped = 1
		if (slot_wear_suit)
			if (!wear_suit)
				wear_suit = I
				hud.add_other_object(I, ui_suit)
				I.equipped(src, "o_clothing")
				equipped = 1
				update_hair_layer()
		if (slot_w_uniform)
			if (!w_uniform)
				w_uniform = I
				hud.add_other_object(I, ui_clothing)
				I.equipped(src, "i_clothing")
				equipped = 1
		if (slot_l_store)
			if (!l_store)
				l_store = I
				hud.add_object(I, HUD_LAYER+2, ui_storage1)
				equipped = 1
		if (slot_r_store)
			if (!r_store)
				r_store = I
				hud.add_object(I, HUD_LAYER+2, ui_storage2)
				equipped = 1
		if (slot_in_backpack)
			if (back && istype(back, /obj/item/storage))
				I.set_loc(back)
				equipped = 1
		if (slot_in_belt)
			if (belt && istype(belt, /obj/item/storage))
				I.set_loc(belt)
				equipped = 1

	if (equipped)
		if (slot != slot_in_backpack && slot != slot_in_belt)
			I.set_loc(src)
		if (I.ability_buttons.len)
			I.set_mob(src)
			if (slot != slot_in_backpack && slot != slot_in_belt)
				I.show_buttons()
		update_clothing()

/mob/living/carbon/human/proc/can_equip(obj/item/I, slot)
	switch (slot)
		if (slot_l_store, slot_r_store)
			if (I.w_class <= 2 && w_uniform)
				return TRUE
		if (slot_l_hand, slot_r_hand)
			return TRUE
		if (slot_belt)
			if ((I.flags & ONBELT) && w_uniform)
				return TRUE
		if (slot_wear_id)
			if (istype(I, /obj/item/card/id) && w_uniform)
				return TRUE
			if (istype(I, /obj/item/device/pda2) && I:ID_card && w_uniform)
				return TRUE
		if (slot_back)
			if (I.flags & ONBACK)
				return TRUE
		if (slot_wear_mask) // It's not pretty, but the mutantrace check will do for the time being (Convair880).
			if (istype(I, /obj/item/clothing/mask))
				var/obj/item/clothing/M = I
				if ((mutantrace && !mutantrace.uses_human_clothes && !M.compatible_species.Find(mutantrace.name)) || (!ismonkey(src) && M.monkey_clothes))
					//DEBUG("[src] can't wear [I].")
					return FALSE
				else
					return TRUE
		if (slot_ears)
			if (istype(I, /obj/item/clothing/ears) || istype(I,/obj/item/device/radio/headset))
				return TRUE
		if (slot_glasses)
			if (istype(I, /obj/item/clothing/glasses))
				return TRUE
		if (slot_gloves)
			if (istype(I, /obj/item/clothing/gloves))
				return TRUE
		if (slot_head)
			if (istype(I, /obj/item/clothing/head))
				var/obj/item/clothing/H = I
				if ((mutantrace && !mutantrace.uses_human_clothes && !H.compatible_species.Find(mutantrace.name)) || (!ismonkey(src) && H.monkey_clothes))
					//DEBUG("[src] can't wear [I].")
					return FALSE
				else
					return TRUE
		if (slot_shoes)
			if (istype(I, /obj/item/clothing/shoes))
				var/obj/item/clothing/SH = I
				if ((mutantrace && !mutantrace.uses_human_clothes && !SH.compatible_species.Find(mutantrace.name)) || (!ismonkey(src) && SH.monkey_clothes))
					//DEBUG("[src] can't wear [I].")
					return FALSE
				else
					return TRUE
		if (slot_wear_suit)
			if (istype(I, /obj/item/clothing/suit))
				var/obj/item/clothing/SU = I
				if ((mutantrace && !mutantrace.uses_human_clothes && !SU.compatible_species.Find(mutantrace.name)) || (!ismonkey(src) && SU.monkey_clothes))
					//DEBUG("[src] can't wear [I].")
					return FALSE
				else
					return TRUE
		if (slot_w_uniform)
			if (istype(I, /obj/item/clothing/under))
				var/obj/item/clothing/U = I
				if ((mutantrace && !mutantrace.uses_human_clothes && !U.compatible_species.Find(mutantrace.name)) || (!ismonkey(src) && U.monkey_clothes))
					//DEBUG("[src] can't wear [I].")
					return FALSE
				else
					return TRUE
		if (slot_in_backpack) // this slot is stupid
			if (back && istype(back, /obj/item/storage))
				var/obj/item/storage/S = back
				if (S.contents.len < 7 && I.w_class <= 3)
					return TRUE
		if (slot_in_belt) // this slot is also stupid
			if (belt && istype(belt, /obj/item/storage))
				var/obj/item/storage/S = belt
				if (S.contents.len < 7 && I.w_class <= 3)
					return TRUE
	return FALSE

/mob/living/carbon/human/proc/equip_if_possible(obj/item/I, slot)
	if (can_equip(I, slot))
		force_equip(I, slot)
		return TRUE
	else
		return FALSE

/mob/living/carbon/human/swap_hand(var/specify=-1)
	if (specify >= 0)
		hand = specify
	else
		hand = !hand
	hud.update_hands()

/mob/living/carbon/human/emp_act()
	boutput(src, "<span style=\"color:red\"><strong>Your equipment malfunctions.</strong></span>")

	if (organHolder && organHolder.heart && organHolder.heart.robotic)
		organHolder.heart.broken = 1
		boutput(src, "<span style=\"color:red\"><strong>Your cyberheart malfunctions and shuts down!</strong></span>")
		contract_disease(/ailment/disease/flatline,null,null,1)

	var/list/L = get_all_items_on_mob()
	if (L && L.len)
		for (var/obj/O in L)
			O.emp_act()
	boutput(src, "<span style=\"color:red\"><strong>BZZZT</strong></span>")

/mob/living/carbon/human/verb/consume(mob/M as mob in oview(0))
	set hidden = 1
	var/mob/living/carbon/human/H = M
	if (!istype(H))
		return

	if (!H.stat)
		boutput(usr, "You can't eat [H] while they are conscious!")
		return

	if (H.bioHolder.HasEffect("consumed"))
		boutput(usr, "There's nothing left to consume!")
		return

	if (emote_check(1, 50, 0))	//spam prevention
		usr.visible_message("<span style=\"color:red\">[usr] starts [pick("taking bites out of","chomping","chewing","biting","eating","gnawing")] [H]. [pick("What a [pick("psychopath","freak","weirdo","lunatic","creep","rude dude","nutter","jerk","nerd")]!","Holy shit!","What the [pick("hell","fuck","christ","shit","heck")]?","Oh [pick("no","dear","god")]!")]</span>")

		var/loc = usr.loc

		spawn (50)
			if (usr.loc != loc || H.loc != loc)
				boutput(usr, "<span style=\"color:red\">Your consumption of [H] was interrupted!</span>")
				return

			usr.visible_message("<span style=\"color:red\">[usr] finishes [pick("taking bites out of","chomping","chewing","biting","eating","gnawing")] [H]. That was [pick("gross","horrific","disturbing","weird","horrible","funny","strange","odd","creepy","bloody","gory","shameful","awkward","unusual")]!</span>")

			if (prob(10) && !H.mutantrace)
				usr.reagents.add_reagent("prions", 10)
				spawn (rand(20,50)) boutput(usr, "<span style=\"color:red\">You don't feel so good.</span>")

			H.TakeDamage("chest", rand(30,50), 0, 0, DAMAGE_STAB)
			if (H.stat != 2 && prob(50))
				H.emote("scream")
			H.bioHolder.AddEffect("consumed")
			take_bleeding_damage(H, null, rand(15,30), DAMAGE_STAB)
	else
		show_text("You're not done eating the last piece yet.", "red")

/mob/living/carbon/human/verb/numbers()
	set name = "7848(2)9(1)"
	set hidden = 1

	boutput(src, "<span style=\"color:red\">You have no idea what to do with that.</span>")
	boutput(src, "<span style=\"color:red\">This statement is universally true because if you did you probably wouldn't be desperate enough to see this message.</span>")

/mob/living/carbon/human/full_heal()
	blinded = 0
	bleeding = 0
	blood_volume = 500

	if (!limbs)
		limbs = new /human_limbs(src)
	limbs.mend()
	if (!organHolder)
		organHolder = new(src)
	organHolder.create_organs()

	if (get_stamina() != (STAMINA_MAX + get_stam_mod_max()))
		set_stamina(STAMINA_MAX + get_stam_mod_max())

	..()

	if (bioHolder)
		bioHolder.RemoveAllEffects(effectTypeDisability)
	if (implant)
		for (var/obj/item/implant/I in implant)
			if (istype(I, /obj/item/implant/projectile))
				boutput(src, "[I] falls out of you!")
				I.on_remove(src)
				implant.Remove(I)
				//del(I)
				I.set_loc(get_turf(src))
				continue

	update_body()
	update_face()
	return

/mob/living/carbon/human/get_equipped_ore_scoop()
	if (istype(l_hand,/obj/item/ore_scoop))
		return l_hand
	else if (istype(r_hand,/obj/item/ore_scoop))
		return r_hand
	else
		return null

/mob/living/carbon/human/infected(var/pathogen/P)
	if (stat == 2)
		return
	if (ischangeling(src) || isvampire(src)) // Vampires were missing here. They're immune to old-style diseases too (Convair880).
		return FALSE
	if (P.pathogen_uid in immunities)
		return FALSE
	if (!(P.pathogen_uid in pathogens))
		var/pathogen/Q = unpool(/pathogen)
		Q.setup(0, P, 1)
		pathogen_controller.mob_infected(Q, src)
		pathogens += Q.pathogen_uid
		pathogens[Q.pathogen_uid] = Q
		Q.infected = src
		logTheThing("pathology", src, null, "is infected by [Q].")
		return TRUE
	else
		var/pathogen/C = pathogens[P.pathogen_uid]
		if (C.generation < P.generation)
			var/pathogen/Q = unpool(/pathogen)
			Q.setup(0, P, 1)
			logTheThing("pathology", src, null, "'s pathogen mutation [C] is replaced by mutation [Q] due to a higher generation number.")
			pathogen_controller.mob_infected(Q, src)
			Q.stage = min(C.stage, Q.stages)
			pool(C)
			pathogens[Q.pathogen_uid] = Q
			Q.infected = src
			return TRUE
	return FALSE

/mob/living/carbon/human/cured(var/pathogen/P)
	if (P.pathogen_uid in pathogens)
		pathogen_controller.mob_cured(pathogens[P.pathogen_uid], src)
		var/pathogen/Q = pathogens[P.pathogen_uid]
		var/pname = Q.name
		pathogens -= P.pathogen_uid
		var/microbody/M = P.body_type
		if (M.auto_immunize)
			immunity(P)
		pool(Q)
		logTheThing("pathology", src, null, "is cured of [pname].")

/mob/living/carbon/human/remission(var/pathogen/P)
	if (stat == 2)
		return
	if (P.pathogen_uid in pathogens)
		var/pathogen/Q = pathogens[P.pathogen_uid]
		Q.remission()
		logTheThing("pathology", src, null, "'s pathogen [Q] enters remission.")

/mob/living/carbon/human/immunity(var/pathogen/P)
	if (stat == 2)
		return
	if (!(P.pathogen_uid in immunities))
		immunities += P.pathogen_uid
		logTheThing("pathology", src, null, "gains immunity to pathogen [P].")

/mob/living/carbon/human/shock(var/atom/origin, var/wattage, var/zone = "chest", var/stun_multiplier = 1, var/ignore_gloves = 0)
	if (!wattage)
		return FALSE
	var/prot = 1
	var/obj/item/clothing/gloves/G = gloves
	if (G && !ignore_gloves)
		prot = G.siemens_coefficient
	if (prot == 0)
		return FALSE

	var/shock_damage = 0
	if (wattage > 7500)
		shock_damage = (max(rand(10,20), round(wattage * 0.00004)))*prot
	else if (wattage > 5000)
		shock_damage = 15 * prot
	else if (wattage > 2500)
		shock_damage = 5 * prot
	else
		shock_damage = 1 * prot

	for (var/uid in pathogens)
		var/pathogen/P = pathogens[uid]
		shock_damage = P.onshocked(shock_damage, wattage)
		if (!shock_damage)
			return FALSE

	if (bioHolder.HasEffect("resist_electric") == 2)
		var/healing = 0
		healing = shock_damage / 3
		HealDamage("All", healing, healing)
		take_toxin_damage(0 - healing)
		boutput(src, "<span style=\"color:blue\">You absorb the electrical shock, healing your body!</span>")
		return FALSE
	else if (bioHolder.HasEffect("resist_electric") == 1)
		boutput(src, "<span style=\"color:blue\">You feel electricity course through you harmlessly!</span>")
		return FALSE

	switch(shock_damage)
		if (0 to 25)
			playsound(loc, "sound/effects/electric_shock.ogg", 50, 1)
		if (26 to 59)
			playsound(loc, "sound/effects/elec_bzzz.ogg", 50, 1)
		if (60 to 99)
			playsound(loc, "sound/effects/elec_bigzap.ogg", 50, 1)  // begin the fun arcflash
			boutput(src, "<span style=\"color:red\"><strong>[origin] discharges a violent arc of electricity!</strong></span>")
			apply_flash(60, 0, 10)
			if (istype(src, /mob/living/carbon/human))
				var/mob/living/carbon/human/H = src
				H.cust_one_state = pick("xcom","bart","zapped")
				H.set_face_icon_dirty()
		if (100 to INFINITY)  // cogwerks - here are the big fuckin murderflashes
			playsound(loc, "sound/effects/elec_bigzap.ogg", 50, 1)
			playsound(loc, "explosion", 50, 1)
			flash(60)
			if (istype(src, /mob/living/carbon/human))
				var/mob/living/carbon/human/H = src
				H.cust_one_state = pick("xcom","bart","zapped")
				H.set_face_icon_dirty()

			var/turf/T = get_turf(src)
			if (T)
				T.hotspot_expose(5000,125)
				explosion(origin, T, -1,-1,1,2)
			if (istype(src, /mob/living/carbon/human))
				if (prob(20))
					boutput(src, "<span style=\"color:red\"><strong>[origin] vaporizes you with a lethal arc of electricity!</strong></span>")
					if (shoes)
						drop_from_slot(shoes)
					new /obj/decal/cleanable/ash(loc)
					spawn (1)
						elecgib()
				else
					boutput(src, "<span style=\"color:red\"><strong>[origin] blasts you with an arc flash!</strong></span>")
					if (shoes)
						drop_from_slot(shoes)
					var/atom/targetTurf = get_edge_target_turf(src, get_dir(src, get_step_away(src, origin)))
					throw_at(targetTurf, 200, 4)
	shock_cyberheart(shock_damage)
	TakeDamage(zone, 0, shock_damage, 0, DAMAGE_BURN)
	updatehealth()
	boutput(src, "<span style=\"color:red\"><strong>You feel a [wattage > 7500 ? "powerful" : "slight"] shock course through your body!</strong></span>")
	unlock_medal("HIGH VOLTAGE", 1)
	Virus_ShockCure(min(wattage / 500, 100))
	sleep(1)
	if (stunned < 12)
		stunned = min((shock_damage/5), 12) * stun_multiplier
	if (weakened < 8)
		weakened = min((shock_damage/6), 8) * prot * stun_multiplier

	return shock_damage

/mob/living/carbon/human/emag_act(mob/user, obj/item/card/emag/E)

	if (prob(1)) //Magnet healing!
		HealDamage("All", 3, 3)
		src.show_text("The electromagnetic field seems to make your joints feel less stiff! Maybe...", "blue")
		if (user) user.show_text("You pass \the [E] over [src]'s body, thinking positive thoughts. They look a little better. <BR><strong>You have the gift!</strong>", "blue")
		return TRUE
	else
		if (user && user != src && E)
			user.show_text("You poke [src] with \the [E].", "red")
			show_text("<strong>[user]</strong> pokes you with \an [E]. [prob(25)?"What a weirdo.":null]", "red")
		else if (user)
			if (!emagged)
				emagged = 1
				user.show_text("You poke yourself with \the [E]! [pick_string("descriptors.txt","emag_self")]", "red")
			else
				user.show_text("You poke yourself with \the [E]! It does nothing. What did you expect?","red")
	return FALSE

/mob/living/carbon/human/proc/resist()
	if (last_resist > world.time)
		if (burning) dir = pick(NORTH, SOUTH, EAST, WEST)
		return
	last_resist = world.time + 20
	if (!stat && lying)
		if (burning)
			last_resist = world.time + 25
			for (var/mob/O in AIviewers(src))
				O.show_message("<span style=\"color:red\"><strong>[src] rolls around on the floor, trying to extinguish the flames.</strong></span>", 1)

			unlock_medal("Through the fire and flames", 1)
			dir = pick(NORTH, SOUTH, EAST, WEST)
			if (traitHolder && traitHolder.hasTrait("burning")) update_burning(-8)
			else update_burning(-4)

	// Added this here (Convair880).
	if (!stat && !restrained() && (shoes && shoes.chained))
		if (ishuman(src))
			var/obj/item/clothing/shoes/SH = shoes
			if (ischangeling(src))
				u_equip(SH)
				SH.set_loc(get_turf(src))
				update_clothing()
				show_text("You briefly shrink your legs to remove the shackles.", "blue")
			else if (bioHolder.HasEffect("hulk") || ispredator(src) || iswerewolf(src))
				visible_message("<span style=\"color:red\">[src] rips apart the shackles with pure brute strength!</strong></span>", "<span style=\"color:blue\">You rip apart the shackles.</span>")
				var/obj/item/clothing/shoes/NEW = new SH.type
				// Fallback if type is chained by default. Don't think we can check without spawning a pair first.
				if (NEW.chained)
					qdel(NEW)
					NEW = new /obj/item/clothing/shoes/brown
				u_equip(SH)
				equip_if_possible(NEW, slot_shoes)
				update_clothing()
				qdel(SH)
			else if (limbs && (istype(limbs.l_leg, /obj/item/parts/robot_parts) && !istype(limbs.l_leg, /obj/item/parts/robot_parts/leg/left/light)) && (istype(limbs.r_leg, /obj/item/parts/robot_parts) && !istype(limbs.r_leg, /obj/item/parts/robot_parts/leg/right/light))) // Light cyborg legs don't count.
				visible_message("<span style=\"color:red\">[src] rips apart the shackles with pure machine-like strength!</strong></span>", "<span style=\"color:blue\">You rip apart the shackles.</span>")
				var/obj/item/clothing/shoes/NEW2 = new SH.type
				if (NEW2.chained)
					qdel(NEW2)
					NEW2 = new /obj/item/clothing/shoes/brown
				u_equip(SH)
				equip_if_possible(NEW2, slot_shoes)
				update_clothing()
				qdel(SH)
			else
				last_resist = world.time + 100
				var/time = 450
				if (stats)
					time = round(time/stats.getResistTimeDivisor())
				show_text("You attempt to remove your shackles. (This will take around [round(time / 10)] seconds and you need to stand still.)", "red")
				actions.start(new/action/bar/private/icon/shackles_removal(time), src)

	if (!stat && canmove && !restrained())
		for (var/obj/item/grab/G in grabbed_by)
			if (G.state == 0)
				qdel(G)
			else
				if (G.state == 1)
					if (prob(25))
						for (var/mob/O in AIviewers(src, null))
							O.show_message(text("<span style=\"color:red\">[] has broken free of []'s grip!</span>", src, G.assailant), 1)
						qdel(G)
				else
					if (G.state == 2)
						if (prob(5))
							for (var/mob/O in AIviewers(src, null))
								O.show_message(text("<span style=\"color:red\">[] has broken free of []'s headlock!</span>", src, G.assailant), 1)
							qdel(G)
		for (var/mob/O in AIviewers(src, null))
			O.show_message(text("<span style=\"color:red\"><strong>[] resists!</strong></span>", src), 1)

	if (handcuffed)
		if (ishuman(src))
			if (is_changeling())
				boutput(src, "<span style=\"color:blue\">You briefly shrink your hands to remove your handcuffs.</span>")
				handcuffed:set_loc(loc)
				handcuffed.unequipped(src)
				handcuffed = null
				update_clothing()
				return
			if (ispredator(src) || iswerewolf(src))
				for (var/mob/O in AIviewers(src))
					O.show_message(text("<span style=\"color:red\"><strong>[] rips apart the handcuffs with pure brute strength!</strong></span>", src), 1)
				boutput(src, "<span style=\"color:blue\">You rip apart your handcuffs.</span>")

				if (handcuffed:material) //This is a bit hacky.
					handcuffed:material:triggerOnAttacked(handcuffed, src, src, handcuffed)

				qdel(handcuffed)
				handcuffed = null
				update_clothing()
				return
		if (bioHolder.HasEffect("hulk"))
			for (var/mob/O in AIviewers(src))
				O.show_message(text("<span style=\"color:red\"><strong>[] rips apart the handcuffs with pure brute strength!</strong></span>", src), 1)
			boutput(src, "<span style=\"color:blue\">You rip apart your handcuffs.</span>")

			if (handcuffed:material) //This is a bit hacky.
				handcuffed:material:triggerOnAttacked(handcuffed, src, src, handcuffed)
				qdel(handcuffed)
			handcuffed = null
			update_clothing()
		else if ( limbs && (istype(limbs.l_arm, /obj/item/parts/robot_parts) && !istype(limbs.l_arm, /obj/item/parts/robot_parts/arm/left/light)) && (istype(limbs.r_arm, /obj/item/parts/robot_parts) && !istype(limbs.r_arm, /obj/item/parts/robot_parts/arm/right/light))) //Gotta be two standard borg arms
			for (var/mob/O in AIviewers(src))
				O.show_message(text("<span style=\"color:red\"><strong>[] rips apart the handcuffs with machine-like strength!</strong></span>", src), 1)
			boutput(src, "<span style=\"color:blue\">You rip apart your handcuffs.</span>")

			if (handcuffed:material) //This is a bit hacky.
				handcuffed:material:triggerOnAttacked(handcuffed, src, src, handcuffed)

			qdel(handcuffed)
			handcuffed = null
			update_clothing()
		else
			last_resist = world.time + 100
			var/calcTime = handcuffed.material ? max((handcuffed.material.getProperty(PROP_HARDNESS) + handcuffed.material.getProperty(PROP_TOUGHNESS)) * 10, 200) : (canmove ? rand(400,500) : rand(600,750))
			if (stats)
				calcTime = round(calcTime/stats.getResistTimeDivisor())
			boutput(src, "<span style=\"color:red\">You attempt to remove your handcuffs. (This will take around [round(calcTime / 10)] seconds and you need to stand still)</span>")
			if (handcuffed:material) //This is a bit hacky.
				handcuffed:material:triggerOnAttacked(handcuffed, src, src, handcuffed)
			actions.start(new/action/bar/private/icon/handcuffRemoval(calcTime), src)

	return FALSE

/mob/living/carbon/human/proc/spidergib()
	if (istype(src, /mob/dead))
		var/list/virus = ailments
		gibs(loc, virus)
		return
	#ifdef DATALOGGER
	game_stats.Increment("violence")
	#endif

	death(1)
	var/atom/movable/overlay/animation = null
	transforming = 1
	canmove = 0
	icon = null
	invisibility = 101

	if (ishuman(src))
		animation = new(loc)
		animation.icon_state = "blank"
		animation.icon = 'icons/mob/mob.dmi'
		animation.master = src
		flick("spidergib", animation)
		visible_message("<span style=\"color:red\"><font size=4><strong>A swarm of spiders erupts from [src]'s mouth and devours them! OH GOD!</strong></font></span>", "<span style=\"color:red\"><font size=4><strong>A swarm of spiders erupts from your mouth! OH GOD!</strong></font></span>", "<span style=\"color:red\">You hear a vile chittering sound.</span>")
		playsound(loc, 'sound/effects/blobattack.ogg', 100, 1)
		spawn (10)
			new /obj/decal/cleanable/vomit/spiders(loc)
			for (var/I = 0, I < 4, I++)
				new /obj/critter/spider/baby(loc)



	if (mind || client)
		ghostize()

	spawn (15)
		qdel(src)

/mob/living/carbon/human/get_equipped_items()
	. = ..()
	if (belt) . += belt
	if (glasses) . += glasses
	if (gloves) . += gloves
	if (head) . += head
	if (shoes) . += shoes
	if (wear_id) . += wear_id
	if (wear_suit) . += wear_suit
	if (w_uniform) . += w_uniform

/mob/living/carbon/human/protected_from_space()
	var/space_suit = 0
	if (wear_suit && (wear_suit.c_flags & SPACEWEAR))
		space_suit++
	if (w_uniform && (w_uniform.c_flags & SPACEWEAR))
		space_suit++
	if (head && (head.c_flags & SPACEWEAR))
		space_suit++
	//if (wear_mask && (wear_mask.c_flags & SPACEWEAR))
		//space_suit++

	if (space_suit >= 2)
		return TRUE
	else
		return FALSE

/mob/living/carbon/human/list_ejectables()
	var/list/ret = list()
	var/list/processed = list()
	if (limbs)
		if (limbs.l_arm && prob(75) && limbs.l_arm.loc == src)
			ret += limbs.l_arm
			processed += limbs.l_arm
		if (limbs.r_arm && prob(75) && limbs.r_arm.loc == src)
			ret += limbs.r_arm
			processed += limbs.r_arm
		if (limbs.l_leg && prob(75) && limbs.l_leg.loc == src)
			ret += limbs.l_leg
			processed += limbs.l_leg
		if (limbs.r_leg && prob(75) && limbs.r_leg.loc == src)
			ret += limbs.r_leg
			processed += limbs.r_leg
	if (organHolder)
		if (organHolder.chest)
			processed += organHolder.chest
		if (organHolder.heart)
			processed += organHolder.heart
			if (prob(50) && organHolder.heart.loc == src)
				ret += organHolder.heart
		if (organHolder.skull)
			processed += organHolder.skull
		if (organHolder.brain)
			processed += organHolder.brain
		if (organHolder.head)
			processed += organHolder.head
		if (prob(40))
			if (prob(15) && organHolder.head && organHolder.head.loc == src)
				ret += organHolder.drop_organ("head", src)
			else
				if (organHolder.skull && organHolder.skull.loc == src)
					ret += organHolder.skull
				if (prob(15) && organHolder.brain && organHolder.brain.loc == src)
					ret += organHolder.brain
		if (organHolder.left_eye)
			processed += organHolder.left_eye
			if (prob(25) && organHolder.left_eye.loc == src)
				ret += organHolder.left_eye
		if (organHolder.right_eye)
			processed += organHolder.right_eye
			if (prob(25) && organHolder.right_eye.loc == src)
				ret += organHolder.right_eye
		if (organHolder.left_lung)
			processed += organHolder.left_lung
			if (prob(25) && organHolder.left_lung.loc == src)
				ret += organHolder.left_lung
		if (organHolder.right_lung)
			processed += organHolder.right_lung
			if (prob(25) && organHolder.right_lung.loc == src)
				ret += organHolder.right_lung
		if (prob(50))
			var/obj/item/clothing/head/wig/W = create_wig()
			if (W)
				processed += W
				ret += W
		if (organHolder.butt)
			processed += organHolder.butt
			if (prob(50) && organHolder.butt.loc == src)
				ret += organHolder.butt

	for (var/atom/movable/A in contents)
		if (A in processed)
			continue
		if (istype(A, /obj/screen)) // maybe people will stop gibbing out their stamina bars now  :|
			continue
		if (prob(dump_contents_chance))
			ret += A
	return ret

/mob/living/carbon/human/proc/create_wig()
	if (!bioHolder || !bioHolder.mobAppearance)
		return null
	var/obj/item/clothing/head/wig/W = new(src)
	W.name = "[real_name]'s hair"
/* commenting this out and making it an overlay to fix issues with colors stacking
	W.icon = 'icons/mob/human_hair.dmi'
	W.icon_state = cust_one_state
	W.color = bioHolder.mobAppearance.customization_first_color
	W.wear_image_icon = 'icons/mob/human_hair.dmi'
	W.wear_image = image(W.wear_image_icon, W.icon_state)
	W.wear_image.color = bioHolder.mobAppearance.customization_first_color*/

	if (bioHolder.mobAppearance.customization_first != "None")
		var/image/h_image = image('icons/mob/human_hair.dmi', cust_one_state)
		h_image.color = bioHolder.mobAppearance.customization_first_color
		W.overlays += h_image
		W.wear_image.overlays += h_image

	if (bioHolder.mobAppearance.customization_second != "None")
		var/image/f_image = image('icons/mob/human_hair.dmi', cust_two_state)
		f_image.color = bioHolder.mobAppearance.customization_second_color
		W.overlays += f_image
		W.wear_image.overlays += f_image

	if (bioHolder.mobAppearance.customization_third != "None")
		var/image/d_image = image('icons/mob/human_hair.dmi', cust_three_state)
		d_image.color = bioHolder.mobAppearance.customization_third_color
		W.overlays += d_image
		W.wear_image.overlays += d_image
	return W


/mob/living/carbon/human/set_eye()
	..()
	handle_regular_sight_updates()

/mob/living/carbon/human/heard_say(var/mob/other)
	if (!sims)
		return
	if (other != src)
		sims.affectMotive("social", 5)

/mob/living/carbon/human/proc/lose_limb(var/limb)
	if (!limbs)
		return
	if (!limb in list("l_arm","r_arm","l_leg","r_leg")) return

	//not exactly elegant, but fuck it, vars[limb].remove() didn't want to work :effort:
	if (limb == "l_arm" && limbs.l_arm) limbs.l_arm.remove()
	else if (limb == "r_arm" && limbs.r_arm) limbs.r_arm.remove()
	else if (limb == "l_leg" && limbs.l_leg) limbs.l_leg.remove()
	else if (limb == "r_leg" && limbs.r_leg) limbs.r_leg.remove()

/mob/living/carbon/human/proc/sever_limb(var/limb)
	if (!limbs)
		return
	if (!limb in list("l_arm","r_arm","l_leg","r_leg")) return

	//not exactly elegant, but fuck it, vars[limb].sever() didn't want to work :effort:
	if (limb == "l_arm" && limbs.l_arm) limbs.l_arm.sever()
	else if (limb == "r_arm" && limbs.r_arm) limbs.r_arm.sever()
	else if (limb == "l_leg" && limbs.l_leg) limbs.l_leg.sever()
	else if (limb == "r_leg" && limbs.r_leg) limbs.r_leg.sever()

/mob/living/carbon/human/proc/has_limb(var/limb)
	if (!limbs)
		return
	if (!limb in list("l_arm","r_arm","l_leg","r_leg")) return

	if (limb == "l_arm" && limbs.l_arm) return TRUE
	else if (limb == "r_arm" && limbs.r_arm) return TRUE
	else if (limb == "l_leg" && limbs.l_leg) return TRUE
	else if (limb == "r_leg" && limbs.r_leg) return TRUE

/mob/living/carbon/human/hand_attack(atom/target)
	if (mutantrace && mutantrace.override_attack)
		mutantrace.custom_attack(target)
	else
		var/obj/item/parts/arm = null
		if (limbs) //Wire: fix for null.r_arm and null.l_arm
			arm = hand ? limbs.l_arm : limbs.r_arm // I'm so sorry I couldent kill all this shitcode at once
		if (arm)
			arm.limb_data.attack_hand(target, src, can_reach(src, target))

/mob/living/carbon/human/proc/was_harmed(var/mob/M as mob, var/obj/item/weapon as obj)
	return

/mob/living/carbon/human/attack_hand(mob/M)
	..()
	if (M.a_intent in list(INTENT_HARM,INTENT_DISARM,INTENT_GRAB))
		was_harmed(M)

/mob/living/carbon/human/attackby(obj/item/W, mob/M)
	var/tmp/oldbloss = get_brute_damage()
	var/tmp/oldfloss = get_burn_damage()
	..()
	var/tmp/newbloss = get_brute_damage()
	var/tmp/damage = ((newbloss - oldbloss) + (get_burn_damage() - oldfloss))
	if (reagents)
		reagents.physical_shock((newbloss - oldbloss) * 0.15)
	if ((damage > 0) || W.force)
		was_harmed(M, W)

/mob/living/carbon/human/understands_language(var/langname)
	if (mutantrace)
		if ((langname == "" || langname == "english") && !mutantrace.override_language)
			. = 1
		else if (mutantrace.override_language == langname)
			. = 1
		else if (langname in mutantrace.understood_languages)
			. = 1
		else
			. = 0
	else
		. = ..()
	if ((langname == "silicon" || langname == "binary") && (locate(/obj/item/implant/robotalk) in implant || traitHolder.hasTrait("roboears")))
		return TRUE
	return .

/mob/living/carbon/human/get_special_language(var/secure_mode)
	if (secure_mode == "s" && (locate(/obj/item/implant/robotalk) in implant || traitHolder.hasTrait("roboears")))
		return "silicon"
	return null

/mob/living/carbon/human/HealBleeding(var/amt)
	bleeding = max(bleeding - amt, 0)

/mob/living/carbon/human/proc/juggling()
	if (islist(juggling) && juggling.len)
		return TRUE
	return FALSE

/mob/living/carbon/human/proc/drop_juggle()
	if (!juggling())
		return
	visible_message("<span style=\"color:red\"><strong>[src]</strong> drops everything they were juggling!</span>")
	for (var/obj/O in juggling)
		O.set_loc(loc)
		O.layer = initial(O.layer)
		if (prob(25))
			O.throw_at(get_step(src, pick(alldirs)), 1, 1)
		juggling -= O
	drop_from_slot(r_hand)
	drop_from_slot(l_hand)
	update_body()
	logTheThing("combat", src, null, "drops the items they were juggling")

/mob/living/carbon/human/proc/add_juggle(var/obj/thing as obj)
	if (!thing || stat)
		return
	if (istype(thing, /obj/item/grab))
		return
	u_equip(thing)
	if (thing.loc != src)
		thing.set_loc(src)
	if (juggling())
		var/items = ""
		var/count = 0
		for (var/obj/O in juggling)
			count ++
			if (juggling.len > 1 && count == juggling.len)
				items += " and [O]"
				continue
			items += ", [O]"
		items = copytext(items, 3)
		visible_message("<strong>[src]</strong> adds [thing] to the [items] [he_or_she(src)]'s already juggling!")
	else
		visible_message("<strong>[src]</strong> starts juggling [thing]!")
	juggling += thing
	if (isitem(thing))
		var/obj/item/i = thing
		i.on_spin_emote(src)
	update_body()
	logTheThing("combat", src, null, "juggles [thing]")

/mob/living/carbon/human/does_it_metabolize()
	return TRUE

/mob/living/carbon/human/canRideMailchutes()
	if (ismonkey(src)) // Why not, I guess?
		return TRUE
	else if (w_uniform && istype(w_uniform, /obj/item/clothing/under/misc/mail/syndicate))
		return TRUE
	else
		return FALSE

/mob/living/carbon/human/choose_name(var/retries = 3, var/what_you_are = null, var/default_name = null)
	var/newname
	for (retries, retries > 0, retries--)
		newname = input(src, "[what_you_are ? "You are \a [what_you_are]. " : null]Would you like to change your name to something else?", "Name Change", default_name ? default_name : real_name) as null|text
		if (!newname)
			return
		else
			newname = strip_html(newname, 32, 1)
			if (!length(newname) || copytext(newname,1,2) == " ")
				show_text("That name was too short after removing bad characters from it. Please choose a different name.", "red")
				continue
			else
				if (alert(src, "Use the name [newname]?", newname, "Yes", "No") == "Yes")
					var/data/record/B = FindBankAccountByName(real_name)
					if (B && B.fields["name"])
						B.fields["name"] = newname

					if (istype(wear_id, /obj/item/card/id))
						var/obj/item/card/id/ID = wear_id
						ID.registered = newname
						ID.update_name()
					else if (istype(wear_id, /obj/item/device/pda2) && wear_id:ID_card)
						wear_id:registered = newname
						wear_id:ID_card:registered = newname
					for (var/obj/item/device/pda2/PDA in contents)
						PDA.owner = real_name
						PDA.name = "PDA-[real_name]"
					real_name = newname
					name = newname
					return TRUE
				else
					continue
	if (!newname)
		if (default_name)
			real_name = default_name
		else if (client && client.preferences && client.preferences.real_name)
			real_name = client.preferences.real_name
		else
			real_name = random_name(gender)
		name = real_name


/mob/living/carbon/human/set_mutantrace(var/mutantrace_type)

	//Clean up the old mutantrace
	if (organHolder && organHolder.head && organHolder.head.donor == src)
		organHolder.head.donor_mutantrace = null
	mutantrace = null

	if (ispath(mutantrace_type, /mutantrace) )	//Set a new mutantrace only if passed one
		mutantrace = new mutantrace_type(src)
		. = 1

	if (.) //If the mutantrace was changed do all the usual icon updates
		if (organHolder && organHolder.head && organHolder.head.donor == src)
			organHolder.head.donor_mutantrace = mutantrace
			organHolder.head.update_icon()
		set_face_icon_dirty()
		set_body_icon_dirty()
		update_clothing()

/mob/living/carbon/human/verb/change_hud_style()
	set name = "Change HUD Style"
	set desc = "Selects what style HUD you would like to use."
	set category = "Commands"

	if (!hud) // uh?
		return show_text("<strong>Somehow you have no HUD! Please alert a coder!</strong>", "red")

	var/selection = input(usr, "What style HUD style would you like?", "Selection") as null|anything in hud_style_selection
	if (!selection)
		return

	force_hud_style(selection)

/mob/living/carbon/human/proc/force_hud_style(var/selection)
	if (!selection)
		return

	if (client && client.preferences) // there's bits and bobs that are created/destroyed that check prefs to see how they should look
		client.preferences.hud_style = selection

	var/icon/new_style = hud_style_selection[selection]

	src.hud.change_hud_style(new_style)

	if (zone_sel)
		zone_sel.change_hud_style(new_style)

	var/obj/item/R = find_type_in_hand(/obj/item/grab, "right") // same with grabs
	if (R)
		R.icon = new_style

	var/obj/item/L = find_type_in_hand(/obj/item/grab, "left") // same for the other hand
	if (L)
		L.icon = new_style

	if (sims) // saaaaame with sims motives
		sims.updateHudIcons(new_style)
	return

// hack until I get custom span classes working, reee
#define SPANSEX "<span style = \"color: #FF69B4; font-size: 115%;\">"
#define SPANSEX2 "<span style = \"color: #FF69B4; font-size: 130%;\">"
// lmao
/mob/living/carbon/human/verb/breed()
	set category = "Local"
	set name = "Breed"

	if (gender == MALE && stat == CONSCIOUS)

		if (nut >= 0)
			for (var/mob/living/carbon/human/xenomorph/X in get_step(src, dir))
				visible_message("[SPANSEX][src] [pick("shoves", "thrusts", "pushes", "forces")] his [schlong] [pick("schlong", "weiner", "dong")] into [X]'s pussy!</span>")
				X.weakened = max(X.weakened, min(4, X.weakened+1))
				if (++nut >= rand(10,20))
					visible_message("[SPANSEX2]<strong>[src] busts a fat nut in [X]'s pussy!</strong></span>")
					X.contract_disease(/ailment/parasite/mutt)
					X.babydaddy = src
					nut = -50
				break
		else
			boutput(src, "<span style = \"color:red\">You can't nut for [-nut] more ticks.</span>")

#undef SPANSEX
#undef SPANSEX2