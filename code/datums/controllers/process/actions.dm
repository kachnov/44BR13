// handles timed player actions
PROCESS(actions)
	var/action_controller

/controller/process/actions/setup()
	name = "Actions"
	schedule_interval = 5
	action_controller = actions

/controller/process/actions/doWork()
	actions.process()