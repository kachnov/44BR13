// handles the game ticker
PROCESS(ticker)
	
/controller/process/ticker/setup()
	name = "Game"
	schedule_interval = 5

	if (!ticker)
		ticker = new /controller/gameticker()

	// start the pregame process
	spawn (1)
		ticker.pregame()

/controller/process/ticker/doWork()
	ticker.process()