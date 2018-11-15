// handles various global init and the position of the sun.
PROCESS(world)
	var/shuttle

/controller/process/world/setup()
	name = "World"
	schedule_interval = 23

	setupgenetics()
	if (genResearch) genResearch.setup()

	setup_radiocodes()

	emergency_shuttle = new /shuttle_controller/emergency_shuttle()
	shuttle = emergency_shuttle

	generate_access_name_lookup()

/controller/process/world/doWork()
	sun.calc_position()

	if (genResearch) genResearch.progress()

	for (var/byondkey in muted_keys)
		var/value = muted_keys[byondkey]
		if (value > 1)
			muted_keys[byondkey] = value - 1
		else if (value == 1 || value == 0)
			muted_keys -= byondkey