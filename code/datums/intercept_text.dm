/intercept_text
	var/text
	var/prob_correct_person_lower = 20
	var/prob_correct_person_higher = 80
	var/prob_correct_job_lower = 20
	var/prob_correct_job_higher = 80
	var/prob_correct_prints_lower = 20
	var/prob_correct_print_higher = 80
	var/prob_correct_objective_lower = 20
	var/prob_correct_objective_higher = 80
	var/list/org_names_1 = list()
	var/list/org_names_2 = list()
	var/list/anomalies = list()
	var/list/SWF_names = list()

/intercept_text/New()
	..()
	org_names_1.Add("Blighted", "Defiled", "Unholy", "Murderous", "Ugly", "French", "Blue", "Psychotic", "Farmer")
	org_names_2.Add("Reapers", "Swarm", "Rogues", "Menace", "Jeff Worshippers", "Drunks", "Strikers", "Creed")
	anomalies.Add("Huge electrical storm", "Photon emitter", "Meson generator", "Blue swirly thing")
	SWF_names.Add("Grand Wizard", "His Most Unholy Master", "The Most Angry", "Bighands", "Tall Hat", "Deadly Sandals")
//
/intercept_text/proc/build(var/mode_type, correct_mob)
	switch(mode_type)
		if ("revolution")
			text = ""
			build_rev(correct_mob)
			return text
		if ("wizard")
			text = ""
			build_wizard(correct_mob)
			return text
		if ("nuke")
			text = ""
			build_nuke(correct_mob)
			return text
		if ("traitor")
			text = ""
			build_traitor(correct_mob)
			return text
		if ("malf")
			text = ""
			build_malf(correct_mob)
			return text
		if ("changeling")
			text = ""
			build_changeling(correct_mob)
			return text
		else
			return null

/intercept_text/proc/pick_mob()
	var/list/dudes = list()
	for (var/mob/living/carbon/human/man in mobs)
		dudes += man
	var/dude = pick(dudes)
	return dude

/intercept_text/proc/pick_fingerprints()
	var/mob/living/carbon/human/dude = pick_mob()
	var/print = "[md5(dude.bioHolder.Uid)]"
	return print

/intercept_text/proc/build_traitor(correct_mob)
	var/name_1 = pick(org_names_1)
	var/name_2 = pick(org_names_2)
	var/fingerprints
	var/traitor_name
	var/prob_right_dude = rand(prob_correct_person_lower, prob_correct_person_higher)
	if (prob(prob_right_dude) && (ticker && ticker.mode && istype(ticker.mode, /game_mode/traitor)))
		if (correct_mob)
			traitor_name = correct_mob:current
	else if (prob(prob_right_dude))
		traitor_name = pick_mob()
	else
		fingerprints = pick_fingerprints()

	text += "<BR><BR>The [name_1] [name_2] implied an undercover operative was acting on their behalf on the station currently.<BR>"
	text += "After some investigation, we "
	if (traitor_name)
		text += "are [prob_right_dude]% sure that [traitor_name] may have been involved, and should be closely observed."
		text += "<BR>Note: This group are known to be untrustworthy, so do not act on this information without proper discourse."
	else
		text += "discovered the following set of fingerprints ([fingerprints]) on sensitive materials, and their owner should be closely observed."
		text += "However, these could also belong to a current Cent. Com employee, so do not act on this without reason."

/intercept_text/proc/build_rev(correct_mob)
	var/name_1 = pick(org_names_1)
	var/name_2 = pick(org_names_2)
	var/traitor_name
	var/traitor_job
	var/prob_right_dude = rand(prob_correct_person_lower, prob_correct_person_higher)
	var/prob_right_job = rand(prob_correct_job_lower, prob_correct_job_higher)
	if (prob(prob_right_job))
		if (correct_mob)
			traitor_job = correct_mob:assigned_role
	else
		var/list/job_tmp = get_all_jobs()
		job_tmp.Remove("Captain", "Security Officer", "Vice Officer", "Detective", "Head Of Security", "Head of Personnel", "Chief Engineer", "Research Director")
		traitor_job = pick(job_tmp)
	if (prob(prob_right_dude) && (ticker && ticker.mode && istype(ticker.mode, /game_mode/revolution)))
		if (correct_mob)
			traitor_name = correct_mob:current
	else
		traitor_name = pick_mob()

	text += "<BR><BR>It has been brought to our attention that the [name_1] [name_2] are attempting to stir unrest on one of our stations in your sector. <BR>"
	text += "Based on our intelligence, we are [prob_right_job]% sure that if true, someone doing the job of [traitor_job] on your station may have been brainwashed "
	text += "at a recent conference, and their department should be closely monitored for signs of mutiny. "
	if (prob(prob_right_dude))
		text += "<BR> In addition, we are [prob_right_dude]% sure that [traitor_name] may have also some in to contact with this "
		text += "organisation."
	text += "<BR>However, if this information is acted on without substantial evidence, those responsible will face severe repercussions."

/intercept_text/proc/build_wizard(correct_mob)
	var/SWF_desc = pick(SWF_names)

	text += "<BR><BR>The evil Space Wizards Federation have recently broke their most feared wizard, known only as \"[SWF_desc]\" out of space jail. "
	text += "He is on the run, last spotted in a system near your present location. If anybody suspicious is located aboard, please "
	text += "approach with EXTREME caution. Cent. Com also recommends that it would be wise to not inform the crew of this, due to it's fearful nature."
	text += "Known attributes include: Brown sandals, a large blue hat, a voluptous white beard, and an inclination to cast spells."

/intercept_text/proc/build_nuke(correct_mob)
	text += "<BR><BR>Cent. Com recently recieved a report of a plot to destroy one of our stations in your area. We believe an elite strike team is "
	text += "preparing to plant and activate a nuclear device aboard one of them. The security department should take all necessary precautions "
	text += "to repel an enemy boarding party if the need arises. As this may cause panic among the crew, all efforts should be made to keep this "
	text += "information a secret from all but the most trusted members."

/intercept_text/proc/build_malf(correct_mob)
	var/a_name = pick(anomalies)
	text += "<BR><BR>A [a_name] was recently picked up by a nearby stations sensors in your sector. If it came into contact with your ship or "
	text += "electrical equipment, it may have had hazardarous and unpredictable effects. Closely observe any non carbon based life forms "
	text += "for signs of unusual behaviour, but keep this information discreet at all times due to this possibly dangerous scenario."

/intercept_text/proc/build_changeling(correct_mob)
	text += "<BR><BR>A mutagenic organism has escaped from a research lab in your sector. "
	text += "This organism is capable of mimicking any carbon based life form and is considered extremely dangerous. "
	text += "The crew should remain alert and report any individuals acting oddly."

/intercept_text/proc/build_vampire(correct_mob)
	text += "<BR><BR>We have intercepted reports that a Space Wizard Federation menagerie facility in your sector has suffered a containment breach. "
	text += "It is possible that a Vampire has escaped from their cells and is likely to have taken refuge on the station. It is likely weak from its "
	text += "extended containment, but it will become increasingly more powerful if allowed to consume human blood. If caught, it must be terminated."