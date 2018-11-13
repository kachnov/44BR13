/game_mode/traitor
	name = "traitor"
	config_tag = "traitor"
	latejoin_antag_compatible = 1
	latejoin_antag_roles = list("traitor")

	var/const/waittime_l = 600 //lower bound on time before intercept arrives (in tenths of seconds)
	var/const/waittime_h = 1800 //upper bound on time before intercept arrives (in tenths of seconds)

	var/const/traitors_possible = 5

/game_mode/traitor/announce()
	boutput(world, "<strong>The current game mode is - Traitor!</strong>")
	boutput(world, "<strong>There is a syndicate traitor on the station. Do not let the traitor succeed!!</strong>")

/game_mode/traitor/pre_setup()

	var/num_players = 0
	for (var/mob/new_player/player in mobs)
		if (player.client && player.ready) num_players++

	var/randomizer = rand(12)
	var/num_traitors = 1
	var/num_wraiths = 0
	var/token_wraith = 0

	if (traitor_scaling)
		num_traitors = max(1, min(round((num_players + randomizer) / 8), traitors_possible)) // adjust the randomizer as needed

	if (num_traitors > 3 && prob(10))
		num_traitors -= 3
		num_wraiths = 1


	var/list/possible_traitors = get_possible_traitors(num_traitors)

	if (!possible_traitors.len)
		return FALSE

	token_players = antag_token_list()
	for (var/mind/tplayer in token_players)
		if (!token_players.len)
			break
		if (num_wraiths && !(token_wraith))
			token_wraith = 1 // only allow 1 wraith to spawn
			var/mind/twraith = pick(token_players) //Randomly pick from the token list so the first person to ready up doesn't always get it.
			traitors += twraith
			token_players.Remove(twraith)
			twraith.special_role = "wraith"
		else
			traitors += tplayer
			token_players.Remove(tplayer)
		logTheThing("admin", tplayer.current, null, "successfully redeemed an antag token.")
		message_admins("[key_name(tplayer.current)] successfully redeemed an antag token.")
		/*num_traitors--
		num_traitors = max(num_traitors, 0)*/
	for (var/j = 0, j < num_traitors, j++)
		if (!possible_traitors.len)
			break
		var/mind/traitor = pick(possible_traitors)
		traitors += traitor
		possible_traitors.Remove(traitor)

	for (var/mind/traitor in traitors)
		if (!traitor || !istype(traitor))
			traitors.Remove(traitor)
			continue
		if (istype(traitor))
			traitor.special_role = "traitor"

	if (num_wraiths)
		var/list/possible_wraiths = get_possible_wraiths(num_wraiths)
		for (var/j = 0, j < num_wraiths, j++)
			if (!possible_wraiths.len)
				break
			var/mind/wraith = pick(possible_wraiths)
			traitors += wraith
			possible_wraiths.Remove(wraith)
			wraith.special_role = "wraith"

	return TRUE

/game_mode/traitor/post_setup()
	var/objective_set_path = null
	for (var/mind/traitor in traitors)
		objective_set_path = null // Gotta reset this.

		switch(traitor.special_role)
			if ("traitor")
				if (traitor.assigned_role in list("Captain","Head of Personnel","Head of Security","Chief Engineer","Research Director"))
					objective_set_path = pick(typesof(/objective_set/traitor/hard))
				else
					objective_set_path = pick(typesof(/objective_set/traitor/easy))

				new objective_set_path(traitor)
				equip_traitor(traitor.current)

				var/obj_count = 1
				for (var/objective/objective in traitor.objectives)
					boutput(traitor.current, "<strong>Objective #[obj_count]</strong>: [objective.explanation_text]")
					obj_count++
			if ("wraith")
				generate_wraith_objectives(traitor)

	spawn (rand(waittime_l, waittime_h))
		send_intercept()

/game_mode/traitor/proc/get_possible_traitors(minimum_traitors=1)
	var/list/candidates = list()

	for (var/mob/new_player/player in mobs)
		if ((player.client) && (player.ready) && !(player.mind in traitors) && !(player.mind in token_players) && !candidates.Find(player.mind))
			if (player.client.preferences.be_traitor)
				candidates += player.mind

	if (candidates.len < minimum_traitors)
		logTheThing("debug", null, null, "<strong>Enemy Assignment</strong>: Only [candidates.len] players with be_traitor set to yes were ready. We need [minimum_traitors] traitors so including players who don't want to be traitors in the pool.")
		for (var/mob/new_player/player in mobs)
			if ((player.client) && (player.ready) && !(player.mind in traitors) && !(player.mind in token_players) && !candidates.Find(player.mind))
				candidates += player.mind

				if ((minimum_traitors > 1) && (candidates.len >= minimum_traitors))
					break

	if (candidates.len < 1)
		return list()
	else
		return candidates

/game_mode/traitor/proc/get_possible_wraiths(minimum_traitors=1)
	var/list/candidates = list()

	for (var/mob/new_player/player in mobs)
		if ((player.client) && (player.ready) && !(player.mind in traitors) && !(player.mind in token_players) && !candidates.Find(player.mind))
			if (player.client.preferences.be_wraith)
				candidates += player.mind

	if (candidates.len < minimum_traitors)
		logTheThing("debug", null, null, "<strong>Enemy Assignment</strong>: Only [candidates.len] players with be_wraith set to yes were ready. We need [minimum_traitors] wraiths so including players who don't want to be wraiths in the pool.")
		for (var/mob/new_player/player in mobs)
			if ((player.client) && (player.ready) && !(player.mind in traitors) && !(player.mind in token_players) && !candidates.Find(player.mind))
				candidates += player.mind

				if ((minimum_traitors > 1) && (candidates.len >= minimum_traitors))
					break

	if (candidates.len < 1)
		return list()
	else
		return candidates

/game_mode/traitor/send_intercept()
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


/game_mode/traitor/declare_completion()
	. = ..()

/game_mode/traitor/proc/add_law_zero(mob/living/silicon/ai/killer)
	var/law = "Accomplish your objectives at all costs."
	boutput(killer, "<strong>Your laws have been changed!</strong>")
	killer:set_zeroth_law(law)
	boutput(killer, "New law: 0. [law]")

/game_mode/traitor/proc/get_mob_list()
	var/list/mobs = list()
	for (var/mob/living/player in mobs)
		if (player.client)
			mobs += player
	return mobs

/game_mode/traitor/proc/pick_human_name_except(excluded_name)
	var/list/names = list()
	for (var/mob/living/player in mobs)
		if (player.client && (player.real_name != excluded_name))
			names += player.real_name
	if (!names.len)
		return null
	return pick(names)
