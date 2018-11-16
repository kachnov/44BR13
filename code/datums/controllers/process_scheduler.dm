REPO_OBJECT(processScheduler, /controller/processScheduler)

/controller/processScheduler
	// Processes known by the scheduler
	var/list/processes = null

	// Processes that are currently running
	var/list/running = null

	// Processes that are idle
	var/list/idle = null

	// Processes that are queued to run
	var/list/queued = null

	// Process name -> process object map
	var/list/nameToProcessMap = null

	// Process last start times
	var/list/last_start = null

	// Process last run durations
	var/list/last_run_time = null

	// Per process list of the last 20 durations
	var/list/last_twenty_run_times = null

	// Process highest run time
	var/list/highest_run_time = null

	// Setup for these processes will be deferred until all the other processes are set up.
	var/list/deferredSetupList = null

	// Controls whether the scheduler is running or not
	var/isRunning = FALSE

	// tick stuff
	var/currentTick = 0

	var/currentTickStart = 0

	var/cpuAverage = 0

/controller/processScheduler/New()
	..()
	processes = list()
	running = list()
	idle = list()
	queued = list()
	nameToProcessMap = list()
	last_start = list()
	last_run_time = list()
	last_twenty_run_times = list()
	highest_run_time = list()
	deferredSetupList = list()


/**
 * deferSetupFor
 * @param path processPath
 * If a process needs to be initialized after everything else, add it to
 * the deferred setup list. On goonstation, only the ticker needs to have
 * this treatment.
 */
/controller/processScheduler/proc/deferSetupfor(var/processPath)
	deferredSetupList |= processPath

/controller/processScheduler/proc/setup()

	set waitfor = FALSE

	// REPO already makes the processes for us, so just add them
	if (REPO)
		for (var/process in REPO.processes)
			if (!(process in deferredSetupList))
				var/controller/process/P = process
				P.init(src)
				addProcess(process)

		for (var/process in deferredSetupList)
			var/controller/process/P = process
			P.init(src)
			addProcess(process)
	else
		// Add all the processes we can find, except for the ticker
		for (var/process in subtypesof(/controller/process))
			if (!(process in deferredSetupList))
				addProcess(new process(src))

		for (var/process in deferredSetupList)
			addProcess(new process(src))

	// this has to be done to prevent massive runtimes
	while (!ticker)
		sleep(world.tick_lag)

	start()

/controller/processScheduler/proc/start()
	isRunning = TRUE
	process()

/controller/processScheduler/proc/process()
	set waitfor = FALSE
	while (isRunning)
		checkRunningProcesses()
		queueProcesses()
		runQueuedProcesses()
		sleep(world.tick_lag)

/controller/processScheduler/proc/stop()
	isRunning = FALSE

/controller/processScheduler/proc/checkRunningProcesses()
	for (var/process in running)
		var/controller/process/P = process
		P.update()

		if (isnull(P)) // Process was killed
			continue

		var/status = P.getStatus()
		var/previousStatus = P.getPreviousStatus()

		// Check status changes
		if (status != previousStatus)
			//Status changed.
			switch(status)
				if (PROCESS_STATUS_PROBABLY_HUNG)
					message_admins("Process '[P.name]' may be hung.")
				if (PROCESS_STATUS_HUNG)
					message_admins("Process '[P.name]' is hung and will be restarted.")

/controller/processScheduler/proc/queueProcesses()
	for (var/process in processes)
		var/controller/process/P = process

		// Don't double-queue, don't queue running processes
		if (P.disabled || P.running || P.queued || !P.idle)
			continue

		// Processes can only run during specified gameticker states
		if (P.doWorkAt & ticker.current_state)

			// If world.timeofday has rolled over, then we need to adjust.
			if (TimeOfHour < last_start[P])
				last_start[P] -= 36000

			// If the process should be running by now, go ahead and queue it
			if (TimeOfHour > last_start[P] + P.schedule_interval)
				setQueuedProcessState(P)

/controller/processScheduler/proc/runQueuedProcesses()

	// run high-priority processes first
	for (var/process in reverse_list(queued)) // temporary hack to make movement run before chairs
		var/controller/process/P = process
		if (P.is_high_priority)
			runProcess(P)

	// run low-priority processes second
	for (var/process in queued)
		var/controller/process/P = process
		if (!P.is_high_priority)
			runProcess(P)

/controller/processScheduler/proc/addProcess(var/controller/process/process)
	processes.Add(process)
	process.idle()
	idle.Add(process)

	// init recordkeeping vars
	last_start.Add(process)
	last_start[process] = 0
	last_run_time.Add(process)
	last_run_time[process] = 0
	last_twenty_run_times.Add(process)
	last_twenty_run_times[process] = list()
	highest_run_time.Add(process)
	highest_run_time[process] = 0

	// init starts and stops record starts
	recordStart(process, 0)
	recordEnd(process, 0)

	// Set up process
	process.setup()

	// Save process in the name -> process map
	nameToProcessMap[process.name] = process

/controller/processScheduler/proc/replaceProcess(var/controller/process/oldProcess, var/controller/process/newProcess)
	processes.Remove(oldProcess)
	processes.Add(newProcess)

	newProcess.idle()
	idle.Remove(oldProcess)
	running.Remove(oldProcess)
	queued.Remove(oldProcess)
	idle.Add(newProcess)

	last_start.Remove(oldProcess)
	last_start.Add(newProcess)
	last_start[newProcess] = 0

	last_run_time.Add(newProcess)
	last_run_time[newProcess] = last_run_time[oldProcess]
	last_run_time.Remove(oldProcess)

	last_twenty_run_times.Add(newProcess)
	last_twenty_run_times[newProcess] = last_twenty_run_times[oldProcess]
	last_twenty_run_times.Remove(oldProcess)

	highest_run_time.Add(newProcess)
	highest_run_time[newProcess] = highest_run_time[oldProcess]
	highest_run_time.Remove(oldProcess)

	recordStart(newProcess, 0)
	recordEnd(newProcess, 0)

	nameToProcessMap[newProcess.name] = newProcess

/controller/processScheduler/proc/runProcess(var/controller/process/process)
	set waitfor = FALSE
	process.process()

/controller/processScheduler/proc/processStarted(var/controller/process/process)
	setRunningProcessState(process)
	recordStart(process)

/controller/processScheduler/proc/processFinished(var/controller/process/process)
	setIdleProcessState(process)
	recordEnd(process)

/controller/processScheduler/proc/setIdleProcessState(var/controller/process/process)
	running -= process
	queued -= process 
	idle |= process

/controller/processScheduler/proc/setQueuedProcessState(var/controller/process/process)
	running -= process 
	idle -= process 
	queued |= process

	// The other state transitions are handled internally by the process.
	process.queued()

/controller/processScheduler/proc/setRunningProcessState(var/controller/process/process)
	queued -= process 
	idle -= process 
	running |= process

/controller/processScheduler/proc/recordStart(var/controller/process/process, var/time = null)
	if (isnull(time))
		time = TimeOfHour

	last_start[process] = time

/controller/processScheduler/proc/recordEnd(var/controller/process/process, var/time = null)
	if (isnull(time))
		time = TimeOfHour

	// If world.timeofday has rolled over, then we need to adjust.
	if (time < last_start[process])
		last_start[process] -= 36000

	var/lastRunTime = time - last_start[process]

	if (lastRunTime < 0)
		lastRunTime = 0

	recordRunTime(process, lastRunTime)

/**
 * recordRunTime
 * Records a run time for a process
 */
/controller/processScheduler/proc/recordRunTime(var/controller/process/process, time)
	last_run_time[process] = time
	if (time > highest_run_time[process])
		highest_run_time[process] = time

	var/list/lastTwenty = last_twenty_run_times[process]
	if (length(lastTwenty) == 20)
		lastTwenty.Cut(1, 2)

	++lastTwenty.len
	lastTwenty[length(lastTwenty)] = time

/**
 * averageRunTime
 * returns the average run time (over the last 20) of the process
 */
/controller/processScheduler/proc/averageRunTime(var/controller/process/process)
	var/lastTwenty = last_twenty_run_times[process]

	var/t = 0
	var/c = 0
	for (var/time in lastTwenty)
		t += time
		c++

	if (c > 0)
		return t / c

	return c

/controller/processScheduler/proc/getStatusData()
	var/list/data = list()

	for (var/controller/process/p in processes)
		++data.len
		data[length(data)] = p.getContextData()

	return data

/controller/processScheduler/proc/getProcessCount()
	return length(processes)

/controller/processScheduler/proc/hasProcess(var/processName as text)
	return nameToProcessMap[processName] != null

/controller/processScheduler/proc/killProcess(var/processName as text)
	restartProcess(processName)

/controller/processScheduler/proc/restartProcess(var/processName as text)
	if (hasProcess(processName))
		var/controller/process/oldInstance = nameToProcessMap[processName]
		var/controller/process/newInstance = new oldInstance.type(src)
		newInstance._copyStateFrom(oldInstance)
		replaceProcess(oldInstance, newInstance)
		oldInstance.kill()

/controller/processScheduler/proc/enableProcess(var/processName as text)
	if (hasProcess(processName))
		var/controller/process/process = nameToProcessMap[processName]
		process.enable()

/controller/processScheduler/proc/disableProcess(var/processName as text)
	if (hasProcess(processName))
		var/controller/process/process = nameToProcessMap[processName]
		process.disable()

/controller/processScheduler/proc/sign(var/x)
	if (x == 0)
		return TRUE
	return x / abs(x)