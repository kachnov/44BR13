// handles only materials research right now.
PROCESS(research)
	priority = PROCESS_PRIORITY_RESEARCH
	var/materialResearchHolder/researchMaster

/controller/process/research/setup()
	name = "Research"
	schedule_interval = 1 SECOND
	researchMaster = materialsResearch

/controller/process/research/doWork()
	researchMaster = materialsResearch
	if (researchMaster)
		for (var/x in researchMaster.research)
			var/materialResearch/R = researchMaster.research[x]
			if (!R.completed)
				R.process()
				if (R.completed)
					researchMaster.completed.Add(R.id)
					researchMaster.completed[R.id] = R