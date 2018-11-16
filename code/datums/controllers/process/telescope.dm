// handles telescope signals and whatnot
PROCESS(telescope)
	var/telescope_manager/manager

/controller/process/telescope/setup()
	name = "Telescope"
	schedule_interval = 10 SECONDS

/controller/process/telescope/doWork()
	if (tele_man)
		if (!manager) manager = tele_man
		tele_man.tick()