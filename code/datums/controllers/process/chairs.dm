REPO_LIST(lawnmowers, list())

PROCESS(chairs)
	priority = PROCESS_PRIORITY_CHAIRS
	var/preparing = FALSE
	var/locked = FALSE
	var/backwards_or_forwards = "forwards"
	var/list/lawnmowers = null
	var/list/rlawnmowers = null
	var/send_time = 2 MINUTES
	var/lock_time = 5 MINUTES
	var/launched = 0

/controller/process/chairs/setup()
	name = "Chair Movement"
	schedule_interval = world.tick_lag
	lawnmowers = REPO.lawnmowers
	rlawnmowers = reverse_list(lawnmowers)

/controller/process/chairs/doWork()
	for (var/chair in get_lawnmowers())
		var/obj/stool/chair/lawnmower/L = chair
		var/L_loc = L.loc
		if (L.moving)
			L._Move()
			if (L.loc == L_loc)
				L.moving = FALSE

/controller/process/chairs/proc/launch()
	backwards_or_forwards = next_in_list(backwards_or_forwards, list("backwards", "forwards"))
	++launched

	for (var/chair in get_lawnmowers())
		var/obj/stool/chair/lawnmower/L = chair
		L.moving = TRUE
	
/controller/process/chairs/proc/prepare()
	set waitfor = FALSE
	locked = TRUE
	preparing = TRUE
	sleep(send_time)
	launch()
	preparing = FALSE
	sleep(lock_time)
	locked = FALSE

/controller/process/chairs/proc/time_desc()
	return "[send_time/(1 MINUTE)] minutes"

/controller/process/chairs/proc/get_lawnmowers()
	switch (backwards_or_forwards)
		if ("backwards")
			return rlawnmowers
		if ("forwards")
			return lawnmowers