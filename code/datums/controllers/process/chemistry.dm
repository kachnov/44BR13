PROCESS(chemistry)
	priority = PROCESS_PRIORITY_CHEMISTRY
	var/updateQueue/chemistryUpdateQueue = null

/controller/process/chemistry/setup()
	name = "Chemistry"
	schedule_interval = 1 SECOND
	chemistryUpdateQueue = list()

/controller/process/chemistry/doWork()
	for (var/reagents in active_reagent_holders)
		var/reagents/R = reagents
		R.process_reactions()
		scheck()
