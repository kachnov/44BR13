PROCESS(setup)
	priority = PROCESS_PRIORITY_SETUP
	doWorkAt = 0

/controller/process/setup/setup()
	name = "Server Setup"

	for (var/x in 1 to world.maxx)
		for (var/y in world.maxy to 1 step -1)
			for (var/z in 1 to world.maxz)
				if (!((x-1)%24) && !((world.maxy-y)%24))
					new /obj/fancy_space(locate(x,y,z))
					scheck()