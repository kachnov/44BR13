// the process for mutt and xeno weeds
PROCESS(weeds)
	priority = PROCESS_PRIORITY_WEEDS
	var/list/weeds = null

/controller/process/weeds/setup()
	name = "Xenomorph/Mutt Weeds"
	weeds = global.xenomorph_weeds
	schedule_interval = 2 SECONDS

/controller/process/weeds/doWork()
	var/i = 0

	for (var/weed in weeds)

		// it could be /obj/mutt/weeds too but whatever (yes I know this is bad)
		var/obj/xeno/weeds/W = weed

		if (W)
			W.Life()
			if (!(i++ % 5))
				scheck()
		else 
			weeds -= W