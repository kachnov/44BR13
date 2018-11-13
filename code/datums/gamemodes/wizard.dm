/game_mode/wizard
	name = "wizard"
	config_tag = "wizard"
	shuttle_available = 2
	latejoin_antag_compatible = 1
	latejoin_only_if_all_antags_dead = 1
	latejoin_antag_roles = list("changeling", "vampire")

	var/const/wizards_possible = 5
	var/finished = 0

	var/const/waittime_l = 600 //lower bound on time before intercept arrives (in tenths of seconds)
	var/const/waittime_h = 1800 //upper bound on time before intercept arrives (in tenths of seconds)

/game_mode/wizard/announce()
	boutput(world, "<strong>The current game mode is - Wizard!</strong>")
	boutput(world, "<strong>There is a <span style=\"color:red\">SPACE WIZARD</span> on the station. You can't let him achieve his objective!</strong>")

/game_mode/wizard/pre_setup()

	var/num_players = 0
	for (var/mob/new_player/player in mobs)
		if (player.client && player.ready) num_players++

	var/num_wizards = max(1, min(round(num_players / 12), wizards_possible))

	var/list/possible_wizards = get_possible_wizards(num_wizards)

	if (!possible_wizards.len)
		return FALSE

	token_players = antag_token_list()
	for (var/mind/tplayer in token_players)
		if (!token_players.len)
			break
		traitors += tplayer
		token_players.Remove(tplayer)
		logTheThing("admin", tplayer.current, null, "successfully redeemed an antag token.")
		message_admins("[key_name(tplayer.current)] successfully redeemed an antag token.")
		/*--num_wizards
		num_wizards = max(num_wizards, 0)*/

	for (var/j = 0, j < num_wizards, j++)
		var/mind/wizard = pick(possible_wizards)
		traitors += wizard
		possible_wizards.Remove(wizard)

	for (var/mind/wiz_mind in traitors)
		wiz_mind.assigned_role = "MODE"
	return TRUE

/game_mode/wizard/post_setup()

	for (var/mind/wizard in traitors)
		if (!wizard || !istype(wizard))
			traitors.Remove(wizard)
			continue
		if (istype(wizard))
			wizard.special_role = "wizard"
			if (wizardstart.len == 0)
				boutput(wizard.current, "<strong><span style=\"color:red\">A starting location for you could not be found, please report this bug!</span></strong>")
			else
				var/starting_loc = pick(wizardstart)
				wizard.current.set_loc(starting_loc)
			bestow_objective(wizard,/objective/regular/assassinate)
			bestow_objective(wizard,/objective/regular/assassinate)
			bestow_objective(wizard,/objective/regular/assassinate)

			wizard.current.antagonist_overlay_refresh(1, 0)

			equip_wizard(wizard.current)
			boutput(wizard.current, "<strong><span style=\"color:red\">You are a Wizard!</span></strong>")
			boutput(wizard.current, "<strong>The Space Wizards Federation has sent you to perform a ritual on the station:</strong>")

			var/obj_count = 1
			for (var/objective/objective in wizard.objectives)
				boutput(wizard.current, "<strong>Objective #[obj_count]</strong>: [objective.explanation_text]")
				obj_count++
			boutput(wizard.current, "<strong>Complete all steps of the ritual, and the Dark Gods shall have the station! Work together with any partner you may have!</strong>")

	for (var/mind/wizard in traitors)
		var/randomname
		if (wizard.current.gender == "female") randomname = pick(wiz_female)
		else randomname = pick(wiz_male)
		spawn (0)
			var/newname = adminscrub(input(wizard.current,"You are a Wizard. Would you like to change your name to something else?", "Name change",randomname) as text)

			if (length(ckey(newname)) == 0)
				newname = randomname

			if (newname)
				if (length(newname) >= 26) newname = copytext(newname, 1, 26)
				newname = replacetext(newname, ">", "'")
				wizard.current.real_name = newname
				wizard.current.name = newname

	spawn (rand(waittime_l, waittime_h))
		send_intercept()

/game_mode/wizard/proc/get_possible_wizards(minimum_wizards=1)

	var/list/candidates = list()

	for (var/mob/new_player/player in mobs)
		if ((player.client) && (player.ready) && !(player.mind in traitors) && !(player.mind in token_players) && !candidates.Find(player.mind))
			if (player.client.preferences.be_wizard)
				candidates += player.mind

	if (candidates.len < minimum_wizards)
		logTheThing("debug", null, null, "<strong>Enemy Assignment</strong>: Only [candidates.len] players with be_wizard set to yes. We need [minimum_wizards], so including players who don't want to be wizards in the pool.")
		for (var/mob/new_player/player in mobs)
			if ((player.client) && (player.ready) && !(player.mind in traitors) && !(player.mind in token_players) && !candidates.Find(player.mind))
				candidates += player.mind

				if ((minimum_wizards > 1) && (candidates.len >= minimum_wizards))
					break

	if (candidates.len < 1)
		return list()
	else
		return candidates

/game_mode/wizard/send_intercept()
	var/intercepttext = "Cent. Com. Update Requested staus information:<BR>"
	intercepttext += " Cent. Com has recently been contacted by the following syndicate affiliated organisations in your area, please investigate any information you may have:"

	var/list/possible_modes = list()
	possible_modes.Add("revolution", "wizard", "nuke", "traitor", "changeling")
	possible_modes -= "[ticker.mode]"
	var/number = pick(2, 3)
	var/i = 0
	for (i = 0, i < number, i++)
		possible_modes.Remove(pick(possible_modes))
	possible_modes.Insert(rand(possible_modes.len), "[ticker.mode]")

	var/intercept_text/i_text = new /intercept_text
	for (var/A in possible_modes)
		intercepttext += i_text.build(A, pick(traitors))
/*
	for (var/obj/machinery/computer/communications/comm in machines)
		if (!(comm.stat & (BROKEN | NOPOWER)) && comm.prints_intercept)
			var/obj/item/paper/intercept = new /obj/item/paper( comm.loc )
			intercept.name = "paper- 'Cent. Com. Status Summary'"
			intercept.info = intercepttext

			comm.messagetitle.Add("Cent. Com. Status Summary")
			comm.messagetext.Add(intercepttext)
*/
	for (var/obj/machinery/communications_dish/C in machines)
		C.add_centcom_report("Cent. Com. Status Summary", intercepttext)

	command_alert("Summary downloaded and printed out at all communications consoles.", "Enemy communication intercept. Security Level Elevated.")

/game_mode/wizard/proc/get_mob_list()
	var/list/mobs = list()
	for (var/mob/living/player in mobs)
		if (player.client)
			mobs += player
	return mobs

/game_mode/wizard/proc/pick_human_name_except(excluded_name)
	var/list/names = list()
	for (var/mob/living/player in mobs)
		if (player.client && (player.real_name != excluded_name))
			names += player.real_name
	if (!names.len)
		return null
	return pick(names)

/game_mode/wizard/check_finished()

	if (emergency_shuttle.location == 2)
		return TRUE

	if (no_automatic_ending)
		return FALSE

	return FALSE

//	OK fuck this shit
/*	//Latejoin bad guys come now if all the wizards are dead rather than the round ending.

	var/wizcount = 0
	//var/wizdeathcount = 0
	var/wincount = 0

	if (ticker.mode.Agimmicks.len > 0)
		for (var/mind/W in ticker.mode.Agimmicks)
			if (!(W in traitors))
				wizards += W

	for (var/mind/W in wizards)
		wizcount++
		var/objectives_completed = 0
		for (var/objective/objective in W.objectives)
			if (objective.check_completion()) objectives_completed++
		if (objectives_completed == W.objectives.len) wincount++
		//if (!W.current || W.current.stat == 2) wizdeathcount++

	//if (wizcount == wizdeathcount) return TRUE
	if (wizcount == wincount)
		boutput(world, "wizcount [wizcount], wincount [wincount], ending round")
		return TRUE

	else return FALSE*/