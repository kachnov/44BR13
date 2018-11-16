// Process

/controller/process
	/**
	 * State vars
	 */
	// Main controller ref
	var/controller/processScheduler/main = null

	// TRUE if process is not running or queued
	var/idle = TRUE

	// TRUE if process is queued
	var/queued = FALSE

	// TRUE if process is running
	var/running = FALSE

	// TRUE if process is blocked up
	var/hung = FALSE

	// TRUE if process was killed
	var/killed = FALSE

	// Status text var
	var/status = null

	// Previous status text var
	var/previousStatus = null

	// TRUE if process is disabled
	var/disabled = FALSE

	/**
	 * Config vars
	 */
	// Process name
	var/name = "lynch coders"

	// Process schedule interval
	// This controls how often the process would run under ideal conditions.
	// If the process scheduler sees that the process has finished, it will wait until
	// this amount of time has elapsed from the start of the previous run to start the
	// process running again.
	var/schedule_interval = PROCESS_DEFAULT_SCHEDULE_INTERVAL // run every 50 ticks

	// Process tick allowance
	// This controls what percentage a single tick (0 to 100) the process should be
	// allowed to run before sleeping.
	var/tick_allowance = PROCESS_DEFAULT_TICK_ALLOWANCE

	// hang_warning_time - this is the time (in 1/10 seconds) after which the server will begin to show "maybe hung" in the context window
	var/hang_warning_time = PROCESS_DEFAULT_HANG_WARNING_TIME

	// hang_alert_time - After this much time(in 1/10 seconds), the server will send an admin debug message saying the process may be hung
	var/hang_alert_time = PROCESS_DEFAULT_HANG_ALERT_TIME

	// hang_restart_time - After this much time(in 1/10 seconds), the server will automatically kill and restart the process.
	var/hang_restart_time = PROCESS_DEFAULT_HANG_RESTART_TIME

	// How many times in the current run has the process deferred work till the next tick?
	var/cpu_defer_count = 0

	/**
	 * recordkeeping vars
	 */

	// Records the time (1/10s timeofday) at which the process last finished sleeping
	var/last_slept = 0

	// Records the time (1/10s timeofday) at which the process last began running
	var/run_start = 0

	// Records the world.tick_usage (0 to 100) at which the process last began running
	var/tick_start = 0
	
	// Records the total usage of the current run, each 100 = 1 byond tick
	var/current_usage = 0
	
	// Records the total usage of the last run, each 100 = 1 byond tick
	var/last_usage = 0	
	
	// Records the total usage over the life of the process, each 100 = 1 byond tick
	var/total_usage = 0

	// Records the number of times this process has been killed and restarted
	var/times_killed = 0

	// Tick count
	var/ticks = 0

	var/last_task = ""

	var/last_object = null

	// when does the process run
	var/doWorkAt = GAME_STATE_PLAYING|GAME_STATE_FINISHED

	// priority
	var/priority = PROCESS_PRIORITY_LOWEST

/controller/process/New(var/controller/processScheduler/scheduler)
	..()
	if (scheduler)
		init(scheduler)

/controller/process/proc/init(var/controller/processScheduler/scheduler)
	main = scheduler
	previousStatus = "idle"
	idle()
	name = "process"
	schedule_interval = 50
	last_slept = 0
	run_start = 0
	tick_start = 0
	current_usage = 0
	last_usage = 0
	total_usage = 0
	ticks = 0
	last_task = 0
	last_object = null

/controller/process/proc/started()
	// Initialize last_slept so we can record timing information
	last_slept = TimeOfHour

	// Initialize run_start so we can detect hung processes.
	run_start = TimeOfHour

	// Initialize tick_start so we can know when to sleep
	tick_start = world.tick_usage
	
	// Initialize the cpu usage counter
	current_usage = 0

	// Initialize defer count
	cpu_defer_count = 0

	running()
	main.processStarted(src)

	onStart()

/controller/process/proc/finished()
	ticks++
	current_usage += world.tick_usage - tick_start
	last_usage = current_usage
	current_usage = 0
	idle()
	main.processFinished(src)	
	onFinish()

/controller/process/proc/doWork()
	return

/controller/process/proc/setup()
	return 
	
/controller/process/proc/process()
	started()
	doWork()
	finished()

/controller/process/proc/running()
	idle = 0
	queued = 0
	running = 1
	hung = 0
	setStatus(PROCESS_STATUS_RUNNING)

/controller/process/proc/idle()
	queued = 0
	running = 0
	idle = 1
	hung = 0
	setStatus(PROCESS_STATUS_IDLE)

/controller/process/proc/queued()
	idle = 0
	running = 0
	queued = 1
	hung = 0
	setStatus(PROCESS_STATUS_QUEUED)

/controller/process/proc/hung()
	hung = 1
	setStatus(PROCESS_STATUS_HUNG)

/controller/process/proc/handleHung()
	var/datum/lastObj = last_object
	var/lastObjType = "null"
	if (istype(lastObj))
		lastObjType = lastObj.type

	// If world.timeofday has rolled over, then we need to adjust.
	if (TimeOfHour < run_start)
		run_start -= 36000
	var/msg = "[name] process hung at tick #[ticks]. Process was unresponsive for [(TimeOfHour - run_start) / 10] seconds and was restarted. Last task: [last_task]. Last Object Type: [lastObjType]"
	logTheThing("debug", null, null, msg)
	logTheThing("diary", null, null, msg, "debug")
	message_admins(msg)

	main.restartProcess(name)

/controller/process/proc/kill()
	if (!killed)
		var/msg = "[name] process was killed at tick #[ticks]."
		logTheThing("debug", null, null, msg)
		logTheThing("diary", null, null, msg, "debug")
		//finished()

		// Allow inheritors to clean up if needed
		onKill()

		// This should del
		del(src)

/controller/process/proc/scheck()
	if (killed)
		// The kill proc is the only place where killed is set.
		// The kill proc should have deleted this datum, and all sleeping procs that are
		// owned by it.
		CRASH("A killed process is still running somehow...")
	if (hung)
		// This will only really help if the doWork proc ends up in an infinite loop.
		handleHung()
		CRASH("Process [name] hung and was restarted.")

	// For each tick the process defers, it increments the cpu_defer_count so we don't
	// defer indefinitely
	if (world.tick_usage > 90 || world.tick_usage > tick_start + tick_allowance)
		current_usage += world.tick_usage - tick_start
		sleep(world.tick_lag)
		LAGCHECK(90)
		cpu_defer_count++
		last_slept = TimeOfHour
		tick_start = world.tick_usage

		return TRUE

	return FALSE

/controller/process/proc/update()
	// Clear delta
	if (previousStatus != status)
		setStatus(status)

	var/elapsedTime = getElapsedTime()

	if (hung)
		handleHung()
		return
	else if (elapsedTime > hang_restart_time)
		hung()
	else if (elapsedTime > hang_alert_time)
		setStatus(PROCESS_STATUS_PROBABLY_HUNG)
	else if (elapsedTime > hang_warning_time)
		setStatus(PROCESS_STATUS_MAYBE_HUNG)

/controller/process/proc/getElapsedTime()
	if (TimeOfHour < run_start)
		return TimeOfHour - (run_start - 36000)
	return TimeOfHour - run_start

/controller/process/proc/getAverageUsage()
	

/controller/process/proc/tickDetail()
	return

/controller/process/proc/getContext()
	return "<tr><td>[name]</td><td>[main.averageRunTime(src)]</td><td>[main.last_run_time[src]]</td><td>[main.highest_run_time[src]]</td><td>[ticks]</td></tr>\n"

/controller/process/proc/getContextData()
	return list(
	"name" = name,
	"averageRunTime" = main.averageRunTime(src),
	"lastRunTime" = main.last_run_time[src],
	"highestRunTime" = main.highest_run_time[src],
	"ticks" = ticks,
	"schedule" = schedule_interval,
	"status" = getStatusText(),
	"disabled" = disabled
	)

/controller/process/proc/getStatus()
	return status

/controller/process/proc/getStatusText(var/s = 0)
	if (!s)
		s = status
	switch(s)
		if (PROCESS_STATUS_IDLE)
			return "idle"
		if (PROCESS_STATUS_QUEUED)
			return "queued"
		if (PROCESS_STATUS_RUNNING)
			return "running"
		if (PROCESS_STATUS_MAYBE_HUNG)
			return "maybe hung"
		if (PROCESS_STATUS_PROBABLY_HUNG)
			return "probably hung"
		if (PROCESS_STATUS_HUNG)
			return "HUNG"
		else
			return "UNKNOWN"

/controller/process/proc/getPreviousStatus()
	return previousStatus

/controller/process/proc/getPreviousStatusText()
	return getStatusText(previousStatus)

/controller/process/proc/setStatus(var/newStatus)
	previousStatus = status
	status = newStatus

/controller/process/proc/setLastTask(var/task, var/object)
	last_task = task
	last_object = object

/controller/process/proc/_copyStateFrom(var/controller/process/target)
	main = target.main
	name = target.name
	schedule_interval = target.schedule_interval
	last_slept = 0
	run_start = 0
	tick_start = 0	
	last_usage = 0
	total_usage = 0
	times_killed = target.times_killed
	ticks = target.ticks
	last_task = target.last_task
	last_object = target.last_object
	copyStateFrom(target)

/controller/process/proc/copyStateFrom(var/controller/process/target)

/controller/process/proc/onKill()

/controller/process/proc/onStart()
	LAGCHECK(world.tick_usage > 100 - tick_allowance)

/controller/process/proc/onFinish()

/controller/process/proc/disable()
	disabled = 1

/controller/process/proc/enable()
	disabled = 0
