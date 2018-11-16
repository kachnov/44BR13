// handles timed player actions
PROCESS(actions)
	priority = PROCESS_PRIORITY_ACTIONS
	var/action_controller

/controller/process/actions/setup()
	name = "Actions"
	schedule_interval = 0.5 SECONDS
	action_controller = actions

/controller/process/actions/doWork()
	actions.process()