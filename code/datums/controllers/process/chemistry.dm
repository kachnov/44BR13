/controller/process/chemistry
	var/tmp/updateQueue/chemistryUpdateQueue

	setup()
		name = "Chemistry"
		schedule_interval = 10
		chemistryUpdateQueue = new

	doWork()
		for (var/reagents in active_reagent_holders)
			var/reagents/R = reagents
			R.process_reactions()
			scheck()
