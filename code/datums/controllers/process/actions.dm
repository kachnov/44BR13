// handles timed player actions
/controller/process/actions
	var/action_controler

	setup()
		name = "Actions"
		schedule_interval = 5

		action_controler = actions

	doWork()
		actions.process()