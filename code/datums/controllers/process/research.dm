// handles only materials research right now.
/controller/process/research
	var/materialResearchHolder/researchMaster

	setup()
		name = "Research"
		schedule_interval = 10
		researchMaster = materialsResearch

	doWork()
		researchMaster = materialsResearch
		if (researchMaster)
			for (var/x in researchMaster.research)
				var/materialResearch/R = researchMaster.research[x]
				if (!R.completed)
					R.process()
					if (R.completed)
						researchMaster.completed.Add(R.id)
						researchMaster.completed[R.id] = R