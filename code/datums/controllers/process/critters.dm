// handles critters
PROCESS(critters)
	priority = PROCESS_PRIORITY_CRITTERS
	var/list/detailed_count = null
	var/list/critters = null
	var/tick_counter = null

/controller/process/critters/setup()
	name = "Critter"
	schedule_interval = 1.6 SECONDS
	detailed_count = list()
	critters = global.critters

/controller/process/critters/doWork()

	var/i = 0
	for (var/critter in global.critters)
		var/obj/critter/C = critter
		C.process()
		if (!(i++ % 10))
			scheck()

	/*var/currentTick = ticks
	for (var/obj/critter in critters)
		tick_counter = world.timeofday

		critter:process()

		tick_counter = world.timeofday - tick_counter
		if (critter && tick_counter > 0)
			detailed_count["[critter.type]"] += tick_counter

		scheck(currentTick)*/

/controller/process/critters/tickDetail()
	if (detailed_count && detailed_count.len)
		var/stats = "<strong>[name] ticks:</strong>"
		var/count
		for (var/thing in detailed_count)
			count = detailed_count[thing]
			if (count > 4)
				stats += "[thing] used [count] ticks.<br>"
		boutput(usr, "<br>[stats]")