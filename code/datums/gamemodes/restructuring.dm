/game_mode/restructuring
	name = "Corporate Restructuring"
	config_tag = "restructuring"
/*
/game_mode/restructuring/announce()
	boutput(world, "<span style=\"color:red\"><strong>GLOBAL TRANSMISSION FROM HEAD OFFICE: A CORPORATE RESTRUCTURING IS TO TAKE PLACE</strong></span>")
	boutput(world, "<span style=\"color:red\"><strong>Stay tuned for further news; note that we do care for our employees and any layoffs will be dealt with discretion and compassion</strong></span>")


/game_mode/restructuring/post_setup()
	setup_game()
	var/list/mobs = get_mob_list()
	while (mobs.len == 0)
		sleep 30
		mobs = get_mob_list()
	spawn (120)
		pick_target()

/game_mode/restructuring/proc/pick_target(who)
	var/mob/target
	var/mob/target_desc

	if (!who)
		target = pick(get_mob_list())
		target_desc = get_target_desc(target)
		boutput(world, "<span style=\"color:red\"><strong>HEAD OFFICE: [target_desc] is accused of attempting to start a Union and is now considered a threat to the station. Terminate the employee immediately.</strong></span>")
	else
		target = who
		target_desc = get_target_desc(target)
		boutput(world, "<span style=\"color:red\"><strong>HEAD OFFICE: [target_desc] is accused of fornicating with staff of the same sex. Terminate the employee immediately.</strong></span>")
	ticker.target = target

	target.store_memory("Head office has ordered your downsizing. Ruh roh", 0)

	for (var/mob/living/silicon/ai/M in mobs)
		boutput(M, "These are your laws now:")
		M.set_zeroth_law("[target_desc] is not human.")
		M.show_laws()

/game_mode/restructuring/check_win()
	var/list/left_alive = get_mob_list()
	if (left_alive.len == 1)
		var/thewinner = the_winner()
		boutput(world, "<span style=\"color:red\"><strong>HEAD OFFICE: Thanks to his superior brown-nosing abilities, [thewinner] has been promoted to senior management! Congratulations!</span>")
		return TRUE
	else if (left_alive.len == 0)
		boutput(world, "<span style=\"color:red\"><strong>HEAD OFFICE: Cost cutting measures have achieved 100% efficiency. Thank you for understanding our position during this volatile economic downturn.</span>")
		return TRUE
	else
		if (ticker.target.stat != 2)
			return FALSE
		boutput(world, "<span style=\"color:red\"><strong>HEAD OFFICE: It seems we have made a mistake in our paperwork. The previous target for termination was chosen based on race, sex, and/or religious beliefs, which is against company policy. Please cancel previous termination request.</span>")
		pick_target()
		return FALSE

/game_mode/restructuring/proc/get_mob_list()
	var/list/mobs = list()
	for (var/mob/M in mobs)
		if (M.stat<2 && M.client && istype(M, /mob/living/carbon/human))
			mobs += M
	return mobs

/game_mode/restructuring/proc/the_winner()
	for (var/mob/M in mobs)
		if (M.stat<2 && M.client && istype(M, /mob/living/carbon/human))
			return M.name

/game_mode/restructuring/proc/get_target_desc(mob/target) //return a useful string describing the target
	var/targetrank = null
	for (var/data/record/R in REPO.data_core.general)
		if (R.fields["name"] == target.real_name)
			targetrank = R.fields["rank"]
	if (!targetrank)
		return "[target.name]"
	return "[target.name] the [targetrank]"
*/