/game_mode/monkey
	name = "monkey"
	config_tag = "monkey"

/game_mode/monkey/announce()
	boutput(world, "<strong>The current game mode is - Monkey!</strong>")
	boutput(world, "<strong>Some of your crew members have been infected by a mutageous virus!</strong>")
	boutput(world, "<strong>Escape on the shuttle but the humans have precedence!</strong>")

/game_mode/monkey/post_setup()
	spawn (50)
		var/list/players = list()
		for (var/mob/living/carbon/human/player in mobs)
			if (player.client)
				players += player

		if (players.len >= 3)
			var/amount = round((players.len - 1) / 3) + 1
			amount = min(4, amount)

			while (amount > 0)
				var/mob/living/carbon/human/player = pick(players)
				player.monkeyize()

				players -= player
				amount--

		for (var/mob/living/carbon/human/rabid_monkey in mobs)
			if (ismonkey(rabid_monkey))
				rabid_monkey.contract_disease(/ailment/disease/jungle_fever,null,null,1)

/game_mode/monkey/check_finished()
	if (emergency_shuttle.location==2)
		return TRUE

	return FALSE

/game_mode/monkey/declare_completion()
	var/area/escape_zone = locate(/area/shuttle/escape/centcom)

	var/monkeywin = 0
	for (var/mob/living/carbon/human/monkey_player in mobs)
		if (!ismonkey(monkey_player))
			continue

		if (monkey_player.stat != 2)
			var/turf/location = get_turf(monkey_player.loc)
			if (location in escape_zone)
				monkeywin = 1
				break

	if (monkeywin)
		for (var/mob/living/carbon/human/human_player in mobs)
			if (ismonkey(human_player))
				continue

			if (human_player.stat != 2)
				var/turf/location = get_turf(human_player.loc)
				if (istype(human_player.loc, /turf))
					if (location in escape_zone)
						monkeywin = 0
						break

	if (monkeywin)
		boutput(world, "<FONT size = 3><strong>The monkies have won!</strong></FONT>")
		for (var/mob/living/carbon/human/monkey_player in mobs)
			if (ismonkey(monkey_player) && monkey_player.client)
				boutput(world, "<strong>[monkey_player.key] was a monkey.</strong>")

	else
		boutput(world, "<FONT size = 3><strong>The Research Staff has stopped the monkey invasion!</strong></FONT>")
		for (var/mob/living/carbon/human/human_player in mobs)
			if (!ismonkey(human_player) && human_player.client)
				boutput(world, "<strong>[human_player.key] was [human_player.real_name].</strong>")

	return TRUE