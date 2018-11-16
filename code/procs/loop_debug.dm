////////////////////////////////////////////////////////////////////////////////////
// client procs
//
// these verbs allow admins to monitor and adjust the master controller
// and process loops live during the round


/client/proc/main_loop_context()
	set category = "Debug"
	set name = "Main Loop Context"
	set desc = "Displays the current main loop context information (lastproc: lasttask \[world.timeofday\])"
	if (holder)
		if (!mob)
			return
		processSchedulerView.getContext()

// this is a godawful hack for now, pending cleanup as part of a better main loop control panel. but hey it works
/client/proc/main_loop_tick_detail()
	set category = "Debug"
	set name = "Main Loop Tick Detail"
	set desc = "Displays detailed tick information for the main loops that support it."
	if (holder)
		if (!mob)
			return
		if (holder.rank in list("Coder", "Host"))
			boutput(src, "Dumping detailed tick counters...")
			for (var/controller/process/child in REPO.processScheduler.processes)
				child.tickDetail()
		else
			alert("Fuck off, no crashing dis server")
			return
