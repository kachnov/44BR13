PROCESS(arena)
	var/list/arenas = list()

/controller/process/arena/setup()
	name = "Arena"
	schedule_interval = 8 // 0.8 seconds

	arenas += gauntlet_controller
	arenas += colosseum_controller

/controller/process/arena/doWork()
	for (var/arena/A in arenas)
		A.tick()
				
/controller/process/arena/tickDetail()
	boutput(usr, "No statistics available.")