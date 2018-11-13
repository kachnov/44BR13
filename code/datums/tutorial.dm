/tutorial
	var/name = "Tutorial"
	var/mob/owner = null
	var/list/steps = list()
	var/current_step = 0
	var/finished = 0

	New(var/mob/M)
		..()
		owner = M

	proc
		AddStep(var/tutorialStep/T)
			steps += T
			T.tutorial = src

		ShowStep()
			if (!current_step || current_step > steps.len)
				boutput(owner, "<span style=\"color:red\"><strong>Invalid tutorial state, please notify `An Admin`.</strong></span>")
				qdel(src)
				return
			var/tutorialStep/T = steps[current_step]
			boutput(owner, "<span style=\"color:blue\"><strong>Tutorial step #[current_step]: [T.name]</strong></span>")
			boutput(owner, "<span style=\"color:blue\">[T.instructions]</span>")

		Start()
			if (!owner)
				return FALSE
			if (current_step > 0)
				return FALSE
			current_step = 1
			var/tutorialStep/T = steps[current_step]
			ShowStep()
			T.SetUp()
			return TRUE

		Advance()
			if (current_step > steps.len)
				return
			var/tutorialStep/T = steps[current_step]
			T.TearDown()
			current_step++
			if (current_step > steps.len)
				Finish()
				return
			T = steps[current_step]
			ShowStep()
			T.SetUp()

		Finish()
			if (finished)
				return FALSE
			finished = 1
			if (current_step <= steps.len)
				var/tutorialStep/T = steps[current_step]
				T.TearDown()
			boutput(owner, "<span style=\"color:blue\"><strong>The tutorial is finished!</strong></span>")
			return TRUE

		CheckAdvance()
			if (!current_step || current_step > steps.len)
				return
			var/tutorialStep/T = steps[current_step]
			if (T.MayAdvance())
				if (T == steps[current_step])
					Advance()

		PerformAction(var/action, var/context)
			if (!current_step || current_step > steps.len)
				boutput(owner, "<span style=\"color:red\"><strong>Invalid tutorial state, please notify `An Admin`.</strong></span>")
				qdel(src)
				return TRUE
			var/tutorialStep/T = steps[current_step]
			if (T.PerformAction(action, context))
				spawn (0)
					CheckAdvance()
				return TRUE
			else
				ShowStep()
				boutput(owner, "<span style=\"color:red\"><strong>You cannot do that currently.</strong></span>")
				return FALSE

		PerformSilentAction(var/action, var/context)
			if (!current_step || current_step > steps.len)
				boutput(owner, "<span style=\"color:red\"><strong>Invalid tutorial state, please notify `An Admin`.</strong></span>")
				qdel(src)
				return TRUE
			var/tutorialStep/T = steps[current_step]
			if (T.PerformSilentAction(action, context))
				spawn (0)
					CheckAdvance()
				return TRUE
			else
				return FALSE

/tutorialStep
	var/name = "Tutorial Step"
	var/instructions = "Do something"
	var/tutorial/tutorial = null

	proc
		SetUp()
		TearDown()
		PerformAction(var/action, var/context)
			return TRUE
		PerformSilentAction(var/action, var/context)
			return FALSE
		MayAdvance()
			return TRUE
