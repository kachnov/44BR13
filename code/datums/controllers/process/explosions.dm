PROCESS(explosions)
	var/explosion_controller/explosion_controller

/controller/process/explosions/setup()
	name = "Explosions"
	schedule_interval = 5
	explosion_controller = explosions

/controller/process/explosions/doWork()
	explosion_controller.process()