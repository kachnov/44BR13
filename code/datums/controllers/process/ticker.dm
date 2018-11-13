// handles the game ticker
/controller/process/ticker
	setup()
		name = "Game"
		schedule_interval = 5

		if (!ticker)
			ticker = new /controller/gameticker()

		// start the pregame process
		spawn (1)
			ticker.pregame()
	doWork()
		ticker.process()