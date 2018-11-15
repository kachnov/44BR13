PROCESS(chemistry)
	var/updateQueue/chemistryUpdateQueue

/controller/process/chemistry/setup()
	name = "Chemistry"
	schedule_interval = 10
	chemistryUpdateQueue = new

/controller/process/chemistry/doWork()
	for (var/reagents in active_reagent_holders)
		var/reagents/R = reagents
		R.process_reactions()
		scheck()
