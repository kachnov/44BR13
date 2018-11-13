var/explosion_controller/explosions = null

/explosion_controller
	var/list/queued = list()

	proc/queue(atom/source, turf/epicenter, power, brisance = 1)
		queued += new/explosion(source, epicenter, power, brisance)

	proc/process()
		if (queued.len)
			var/explosion/E = queued[1]
			queued -= E
			E.fire()

/explosion
	var/atom/source
	var/turf/epicenter
	var/power
	var/brisance

	New(atom/source, turf/epicenter, power, brisance)
		source = source
		epicenter = epicenter
		power = power
		brisance = brisance

	proc/fire()
		handle_queued_explosion_dont_call_this_one_directly_fucknuts(source, epicenter, power, brisance)

