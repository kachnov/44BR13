// handles timed player actions
/controller/process/explosions
	var/explosion_controller/explosion_controller

	setup()
		name = "Explosions"
		schedule_interval = 5

		explosion_controller = explosions

	doWork()
		explosion_controller.process()