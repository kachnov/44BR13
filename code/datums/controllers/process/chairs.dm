var/global/controller/process/chairs/chairs_process = null

/controller/process/chairs
	is_high_priority = TRUE
	var/preparing = FALSE
	var/locked = FALSE
	var/backwards_or_forwards = "forwards"
	var/list/lawnmowers = null
	var/send_time = 2 MINUTES
	var/lock_time = 5 MINUTES
	var/launched = 0

/controller/process/chairs/setup()
	name = "Chair Movement"
	schedule_interval = world.tick_lag
	lawnmowers = global.lawnmowers
	chairs_process = src

/controller/process/chairs/doWork()
	for (var/chair in lawnmowers)
		var/obj/stool/chair/lawnmower/L = chair
		if (L.moving)
			L._Move()

/controller/process/chairs/proc/launch()
	for (var/chair in lawnmowers)
		var/obj/stool/chair/lawnmower/L = chair
		L.moving = TRUE
	backwards_or_forwards = next_in_list(backwards_or_forwards, list("backwards", "forwards"))
	++launched
	
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