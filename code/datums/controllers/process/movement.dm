/controller/process/movement
	is_high_priority = TRUE
	var/list/clients = null

/controller/process/movement/setup()
	name = "Client Movement"
	schedule_interval = world.tick_lag
	clients = global.clients

/controller/process/movement/doWork()
	for (var/client in clients)
		triggerMove(client)

/controller/process/movement/proc/triggerMove(var/client/C)
	set waitfor = FALSE
	if (C && C.mob && C.moving_in_dir)
		var/turf/target = get_step(C.mob, C.moving_in_dir)
		if (checkTurf(target, C))
			C.Move(target, C.moving_in_dir)

/controller/process/movement/proc/checkTurf(var/turf/T, var/client/C)

	// turf doesn't exist 
	if (!istype(T))
		return FALSE

	// muh grace walls (extra () because fuck BYOND)
	else if ((locate(/obj/chair_path_helper/wall) in T) && !chairs_process.launched)
		boutput(C, "<span style = \"color:red\">You cannot move there until the lawnmowers have been sent by the Jews.</span>")
		return FALSE

	// all good
	return TRUE