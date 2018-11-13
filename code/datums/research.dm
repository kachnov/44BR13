/research
	//name of the research
	var/name = "generic research"
	//maximum amount of tiers
	var/max_tiers = 0
	//maximum amount of researchable stuff per tier
	var/max_per_list = 0
	//the starting tier, could maybe start at a random tier?
	var/starting_tier = 0
	//tier of research currently at
	var/tier = 1

	//1 if is researching/ 0 if isn't researching
	var/is_researching = 0

	//what is currently being researched
	var/current_research = null
	//in seconds
	//total time research will take
	var/current_research_time = 0.0
////
//For all these lists we'll just be naughty and ignore the 0th component! hehehehe

	//list of items which HAVE been researched and their associated tiers
	var/researched_items
	//list of items which WILL be researched and their associated tiers
	var/items_to_research


	New()
	//Max tiers is the maximum, make sure this is kept whenever research is created
		if (starting_tier > max_tiers)
			starting_tier = max_tiers
		tier = starting_tier
		items_to_research = new/list(max_tiers,max_per_list)
		researched_items = new/list(max_tiers,max_per_list)

	proc/check_if_tier_completed()
		//this is for detecting if we still have things to research in the current tier
		//prevents people from spamming the advance tier button
		//as far as i know the .len for items to research would just return max_per_list
		//hence the reason for the for loop

		//This needs to be re-did for each research. For eg, the variable a has to be a ailment for
		//disease research, though if you're researching objects it needs to be /obj/
		//otherwise it will always return TRUE, as for some reason it counts when you just use var/a

		var/count = 0
		for (var/a in items_to_research[tier])
			count++
		if (!count)
			return TRUE
		return FALSE


	proc/advance_tier()
		if (!check_if_tier_completed()) return FALSE // Dont do anything if they havent finished the tier yet
		if (tier < max_tiers) tier++
		else if (tier >= max_tiers) return FALSE // Don't advance if we're at or above max tiers

		if (tier > max_tiers)
			// If they've somehow advanced when they're already at max, fix it and don't tell everyone about it
			tier = max_tiers
		else if (tier == max_tiers)
			//Let the world know that we've finished our research
			var/cashbonus = max_tiers * 10000
			wagesystem.station_budget += cashbonus
			return command_alert("Centcom congratulates the scientists of the station for reaching the maximum tier of [name]. As a reward for your hard work, we have added $[cashbonus] to the station budget.","Research Announcement")
		else
			//Let everyone know when we have advanced a tier
			return command_alert("Centcom congratulates the scientists of the station for reaching Tier [tier] of [name].","Research Announcement")

	//Starts the research, sets the research item text.
	//Sets time default to 0 so research can be set up without it being time based
	//eg engineering research could be based on collecting items, setting up the engine etc.
	proc/start_research(var/time = 0, var/research_item, var/applytimebonus = 1)
		//already researching
		if (is_researching)
			return FALSE
		//can't find it in in the list of shit we need to research
		var/list/tier_items = items_to_research[tier]
		if (!tier_items.Find(research_item))
			return FALSE
		// apply time bonus
		if (applytimebonus)
			for (var/i = robotics_research.starting_tier, i <= robotics_research.max_tiers, i++)
				for (var/roboresearch/X in robotics_research.researched_items[i])
					if (X.resebonus && X.resemulti != 0 && time != 0) time /= X.resemulti
			if (wagesystem.research_budget >= 5000)
				time /= 2
				wagesystem.research_budget -= 5000
		// start that shit
		is_researching = 1
		current_research = research_item
		//Only if we're considering time
		if (time)
			//when it'll be finished in seconds
			current_research_time = round((world.timeofday + time) / 10, 1)
		return TRUE

	//End research, sets research item to null and updates finished research list
	proc/end_research()
		//already finished or timeleft is not zero
		if (!is_researching)
			boutput(world, "Uh oh, research has fucked up. Line 68, research.dm. Report this to a coder.")
			//this shouldn't happen
			return FALSE
		is_researching = 0
		items_to_research[tier] -= current_research
		researched_items[tier] += current_research
		score_researchdone += 1
		current_research = null
		return TRUE

	// Stops the current research without finishing it
	proc/cancel_research()
		if (!is_researching) return FALSE // No need to cancel if we're not researching anything
		is_researching = 0
		current_research = null
		current_research_time = 0
		return TRUE

	//Returns the time in seconds until researched is finished
	proc/timeleft()
		if (!is_researching)
			return
		//converting timeofday to seconds
		var/timeleft = round(current_research_time - (world.timeofday)/10 ,1)
		if (timeleft <= 0)
			end_research()
			return FALSE
		return timeleft

	//Returns the time, in MM:SS format
	proc/get_research_timeleft()
		var/timeleft = timeleft()
		if (timeleft)
			return "[add_zero(num2text((timeleft / 60) % 60),2)]:[add_zero(num2text(timeleft % 60), 2)]"

	proc/calculate_research_time(var/tier, var/applytimebonus = 1)
		var/time = tier*1000
		var/finaltime = 0
		if (applytimebonus)
			for (var/i = robotics_research.starting_tier, i <= robotics_research.max_tiers, i++)
				for (var/roboresearch/X in robotics_research.researched_items[i]) if (X.resebonus && X.resemulti != 0 && time != 0) time /= X.resemulti
			if (wagesystem.research_budget >= 5000)
				time /= 2
				wagesystem.research_budget -= 5000
		finaltime = round(time / 10, 1)
		return finaltime

//The disease research will be mostly handled by the research/disease computer
/research/disease
	name = "Disease Research"
	max_tiers = 5
	max_per_list = 5
	starting_tier = 1

	var/ailment/disease/cold/tier_one_one = new()
	var/ailment/disease/fake_gbs/tier_one_two = new()

	var/ailment/disease/flu/tier_two_one = new()
	var/ailment/disease/food_poisoning/tier_two_two = new()

	var/ailment/disease/berserker/tier_three_one = new()
	var/ailment/disease/clowning_around/tier_three_two = new()
	var/ailment/disease/jungle_fever/tier_three_three = new()

	var/ailment/disease/teleportitis/tier_four_one = new()
	var/ailment/disease/robotic_transformation/tier_four_three = new()
	var/ailment/disease/plasmatoid/tier_four_four = new()

	var/ailment/disease/gbs/tier_five_one = new()
	var/ailment/disease/space_madness/tier_five_two = new()
	var/ailment/disease/panacaea/tier_five_three = new()

	items_to_research = new/list(5,5)
	researched_items = new/list(5,5)

	New()
		..()
		items_to_research[1] = list(tier_one_one, tier_one_two)
		items_to_research[2] = list(tier_two_one, tier_two_two)
		items_to_research[3] = list(tier_three_one, tier_three_two, tier_three_three)
		//items_to_research[4] = list(tier_four_one, tier_four_two, tier_four_three, tier_four_four, tier_four_five)
		items_to_research[5] = list(tier_five_one, tier_five_two, tier_five_three)

	check_if_tier_completed()
		//this is for detecting if we still have things to research in the current tier
		//prevents people from spamming the advance tier button
		//as far as i know the .len for items to research would just return max_per_list
		//hence the reason for the for loop
		var/count = 0
		for (var/ailment/a in items_to_research[tier])
			count++
		if (!count)
			return TRUE
		return FALSE

/research/weaponry
/research/engineering
/research/gaseous
/research/portal

/research/artifact
	name = "Artifact Research"
	max_tiers = 3
	max_per_list = 7
	starting_tier = 1

	var/artiresearch/ancient1/tier_one_one = new()
	var/artiresearch/martian1/tier_one_two = new()
	var/artiresearch/crystal1/tier_one_three = new()
	var/artiresearch/eldritch1/tier_one_four = new()
	var/artiresearch/precursor1/tier_one_five = new()
	var/artiresearch/general1/tier_one_six = new()
	var/artiresearch/analyser1/tier_one_seven = new()

	var/artiresearch/ancient2/tier_two_one = new()
	var/artiresearch/martian2/tier_two_two = new()
	var/artiresearch/crystal2/tier_two_three = new()
	var/artiresearch/eldritch2/tier_two_four = new()
	var/artiresearch/precursor2/tier_two_five = new()
	var/artiresearch/general2/tier_two_six = new()
	var/artiresearch/analyser2/tier_two_seven = new()

	var/artiresearch/ancient3/tier_three_one = new()
	var/artiresearch/martian3/tier_three_two = new()
	var/artiresearch/crystal3/tier_three_three = new()
	var/artiresearch/eldritch3/tier_three_four = new()
	var/artiresearch/precursor3/tier_three_five = new()
	var/artiresearch/general3/tier_three_six = new()
	var/artiresearch/analyser3/tier_three_seven = new()

	items_to_research = new/list(3,4)
	researched_items = new/list(3,4)

	New()
		..()
		items_to_research[1] = list(tier_one_one, tier_one_two, tier_one_three, tier_one_four, tier_one_five, tier_one_six, tier_one_seven)
		items_to_research[2] = list(tier_two_one, tier_two_two, tier_two_three, tier_two_four, tier_two_five, tier_two_six, tier_two_seven)
		items_to_research[3] = list(tier_three_one, tier_three_two, tier_three_three, tier_three_four, tier_three_five, tier_three_six, tier_three_seven)

	check_if_tier_completed()
		var/count = 0
		for (var/artiresearch/a in items_to_research[tier])
			count++
		if (count <= 2)
			return TRUE
		return FALSE

/research/robotics
	name = "Robotics Research"
	max_tiers = 4
	max_per_list = 5
	starting_tier = 1

	var/roboresearch/manufone/tier_one_one = new()
	var/roboresearch/drones/tier_one_two = new()
	var/roboresearch/implants1/tier_one_three = new()
	var/roboresearch/modules1/tier_one_four = new()
	var/roboresearch/upgrades1/tier_one_five = new()

	var/roboresearch/manuftwo/tier_two_one = new()
	var/roboresearch/resespeedone/tier_two_two = new()
	var/roboresearch/rewriter/tier_two_three = new()
	var/roboresearch/modules2/tier_two_four = new()
	var/roboresearch/upgrades2/tier_two_five = new()

	var/roboresearch/manufthree/tier_three_one = new()
	var/roboresearch/manuffour/tier_three_two = new()
	var/roboresearch/implants2/tier_three_three = new()
	var/roboresearch/upgrades3/tier_three_four = new()

	var/roboresearch/manuffive/tier_four_one = new()
	var/roboresearch/resespeedtwo/tier_four_two = new()

	items_to_research = new/list(5,4)
	researched_items = new/list(5,4)

	New()
		..()
		items_to_research[1] = list(tier_one_one, tier_one_two, tier_one_three, tier_one_four, tier_one_five)
		items_to_research[2] = list(tier_two_one, tier_two_two, tier_two_three, tier_two_four, tier_two_five)
		items_to_research[3] = list(tier_three_one, tier_three_two, tier_three_three, tier_three_four, null)
		items_to_research[4] = list(tier_four_one, tier_four_two, null, null, null)

	check_if_tier_completed()
		var/count = 0
		for (var/roboresearch/a in items_to_research[tier]) count++
		if (count <= 1) return TRUE
		return FALSE

/// Host/Coder Admin verbs for research

/client/proc/cmd_remove_rs_verbs()
	set category = "Debug"
	set name = "Trim Research Debug"
	set desc = "Removes Research Debug verbs."

	verbs -= /client/proc/RS_disease_debug
	verbs -= /client/proc/RS_artifact_debug
	verbs -= /client/proc/RS_robotics_debug
	verbs -= /client/proc/RS_grant_research
	verbs -= /client/proc/RS_revoke_research
	verbs -= /client/proc/RS_grant_tier
	verbs -= /client/proc/RS_revoke_tier

	verbs -= /client/proc/cmd_remove_rs_verbs
	verbs += /client/proc/cmd_claim_rs_verbs

/client/proc/cmd_claim_rs_verbs()
	set category = "Debug"
	set name = "Expand Research Debug"
	set desc = "Gives verbs specific to debugging Research."

	verbs += /client/proc/RS_disease_debug
	verbs += /client/proc/RS_artifact_debug
	verbs += /client/proc/RS_robotics_debug
	verbs += /client/proc/RS_grant_research
	verbs += /client/proc/RS_revoke_research
	verbs += /client/proc/RS_grant_tier
	verbs += /client/proc/RS_revoke_tier

	verbs += /client/proc/cmd_remove_rs_verbs
	verbs -= /client/proc/cmd_claim_rs_verbs

/client/proc/RS_disease_debug()
	set category = "Specialist Debug"
	set name = "Info: Disease"
	set desc = "Displays information about Disease Research."

	var/research/R
	R = disease_research
	var/resetime = R.calculate_research_time(R.tier, 1)
	var/baseresetime = R.calculate_research_time(R.tier, 0)

	var/dat = {"<strong>Research Debug</strong><BR>
				<HR>
				<strong>Research Name:</strong> [R.name]<BR>
				<strong>Tier:</strong> [R.tier]/[R.max_tiers]<BR>
				<strong>Current Research Budget:</strong> [wagesystem.research_budget]<BR>
				<strong>Base Research Time:</strong> [add_zero(num2text((baseresetime / 60) % 60),2)]:[add_zero(num2text(baseresetime % 60), 2)]<BR>
				<strong>Research Time:</strong> [add_zero(num2text((resetime / 60) % 60),2)]:[add_zero(num2text(resetime % 60), 2)]<BR>
				<HR>"}
	if (R.is_researching)
		var/timeleft = R.get_research_timeleft()
		dat += {"<strong>Currently Researching:</strong> [R.current_research]<BR>
		<strong>Time Left:</strong> [timeleft]/[add_zero(num2text((resetime / 60) % 60),2)]:[add_zero(num2text(resetime % 60), 2)]<BR><HR>"}
	else dat += {"Not currently researching.<BR><HR>"}

	dat += {"<strong>Researched Items:</strong><BR>"}
	for (var/i = R.starting_tier, i <= R.max_tiers, i++)
		dat += "<BR><u><em>Tier [i]</em></u><BR>"
		for (var/datum/a in R.researched_items[i])
			dat += "[a:name]<BR>"

	dat += {"<BR><strong>Unresearched Items:</strong><BR>"}
	for (var/i = R.starting_tier, i <= R.max_tiers, i++)
		dat += "<BR><u><em>Tier [i]</em></u><BR>"
		for (var/datum/a in R.items_to_research[i])
			dat += "[a:name]<BR>"

	usr << browse(dat, "window=researchdebug;size=400x400")

/client/proc/RS_artifact_debug()
	set category = "Specialist Debug"
	set name = "Info: Artifact"
	set desc = "Displays information about Artifact Research."

	var/research/R
	R = artifact_research
	var/resetime = R.calculate_research_time(R.tier, 1)
	var/baseresetime = R.calculate_research_time(R.tier, 0)

	var/dat = {"<strong>Research Debug</strong><BR>
				<HR>
				<strong>Research Name:</strong> [R.name]<BR>
				<strong>Tier:</strong> [R.tier]/[R.max_tiers]<BR>
				<strong>Current Research Budget:</strong> [wagesystem.research_budget]<BR>
				<strong>Base Research Time:</strong> [add_zero(num2text((baseresetime / 60) % 60),2)]:[add_zero(num2text(baseresetime % 60), 2)]<BR>
				<strong>Research Time:</strong> [add_zero(num2text((resetime / 60) % 60),2)]:[add_zero(num2text(resetime % 60), 2)]<BR>
				<HR>"}
	if (R.is_researching)
		var/timeleft = R.get_research_timeleft()
		dat += {"<strong>Currently Researching:</strong> [R.current_research]<BR>
		<strong>Time Left:</strong> [timeleft]/[add_zero(num2text((resetime / 60) % 60),2)]:[add_zero(num2text(resetime % 60), 2)]<BR><HR>"}
	else dat += {"Not currently researching.<BR><HR>"}

	dat += {"<strong>Researched Items:</strong><BR>"}
	for (var/i = R.starting_tier, i <= R.max_tiers, i++)
		dat += "<BR><u><em>Tier [i]</em></u><BR>"
		for (var/datum/a in R.researched_items[i])
			dat += "[a:name]<BR>"

	dat += {"<BR><strong>Unresearched Items:</strong><BR>"}
	for (var/i = R.starting_tier, i <= R.max_tiers, i++)
		dat += "<BR><u><em>Tier [i]</em></u><BR>"
		for (var/datum/a in R.items_to_research[i])
			dat += "[a:name]<BR>"

	usr << browse(dat, "window=researchdebug;size=400x400")

/client/proc/RS_robotics_debug()
	set category = "Specialist Debug"
	set name = "Info: Robotics"
	set desc = "Displays information about Robotics Research."

	var/research/R
	R = robotics_research
	var/resetime = R.calculate_research_time(R.tier, 1)
	var/baseresetime = R.calculate_research_time(R.tier, 0)

	var/dat = {"<strong>Research Debug</strong><BR>
				<HR>
				<strong>Research Name:</strong> [R.name]<BR>
				<strong>Tier:</strong> [R.tier]/[R.max_tiers]<BR>
				<strong>Current Research Budget:</strong> [wagesystem.research_budget]<BR>
				<strong>Base Research Time:</strong> [add_zero(num2text((baseresetime / 60) % 60),2)]:[add_zero(num2text(baseresetime % 60), 2)]<BR>
				<strong>Research Time:</strong> [add_zero(num2text((resetime / 60) % 60),2)]:[add_zero(num2text(resetime % 60), 2)]<BR>
				<HR>"}
	if (R.is_researching)
		var/timeleft = R.get_research_timeleft()
		dat += {"<strong>Currently Researching:</strong> [R.current_research]<BR>
		<strong>Time Left:</strong> [timeleft]/[add_zero(num2text((resetime / 60) % 60),2)]:[add_zero(num2text(resetime % 60), 2)]<BR><HR>"}
	else dat += {"Not currently researching.<BR><HR>"}

	dat += {"<strong>Researched Items:</strong><BR>"}
	for (var/i = R.starting_tier, i <= R.max_tiers, i++)
		dat += "<BR><u><em>Tier [i]</em></u><BR>"
		for (var/datum/a in R.researched_items[i])
			dat += "[a:name]<BR>"

	dat += {"<BR><strong>Unresearched Items:</strong><BR>"}
	for (var/i = R.starting_tier, i <= R.max_tiers, i++)
		dat += "<BR><u><em>Tier [i]</em></u><BR>"
		for (var/datum/a in R.items_to_research[i])
			dat += "[a:name]<BR>"

	usr << browse(dat, "window=researchdebug;size=400x400")

/client/proc/RS_grant_research()
	set category = "Specialist Debug"
	set name = "Give Single Research"
	set desc = "Instantly give a research topic."

	var/input = input("Which kind of research?", "Which?", null) as null|anything in list("Disease","Artifact","Robotics")
	var/research/R

	if (input == "Disease") R = disease_research
	else if (input == "Artifact") R = artifact_research
	else if (input == "Robotics") R = robotics_research
	else
		boutput(usr, "<span style=\"color:red\">Invalid Research type.</span>")
		return FALSE

	var/input2 = input("Which tier?", "Which?", null) as num
	if (input2 > R.max_tiers)
		boutput(usr, "<span style=\"color:red\">This research doesn't have that many tiers!</span>")
		return
	if (input2 < 1) return

	var/list/unfinished = list()
	var/count = 0
	for (var/datum/a in R.items_to_research[input2])
		if (a == R.current_research) continue // might shit itself if we swipe an in-progress research out from under them
		count++
		unfinished += a

	if (!count)
		boutput(usr, "<span style=\"color:red\">Nothing left to research in that tier.</span>")
		return
	var/complete = input("Give which research?", "Which?", null) as null|anything in unfinished
	if (!complete) return

	R.researched_items[input2] += complete
	R.items_to_research[input2] -= complete

/client/proc/RS_grant_tier()
	set category = "Specialist Debug"
	set name = "Give Whole Tier"
	set desc = "Instantly give an entire tier of research topics."

	var/input = input("Which kind of research?", "Which?", null) as null|anything in list("Disease","Artifact","Robotics")
	var/research/R

	if (input == "Disease") R = disease_research
	else if (input == "Artifact") R = artifact_research
	else if (input == "Robotics") R = robotics_research
	else
		boutput(usr, "<span style=\"color:red\">Invalid Research type.</span>")
		return FALSE

	var/input2 = input("Which tier?", "Which?", null) as num
	if (input2 > R.max_tiers)
		boutput(usr, "<span style=\"color:red\">This research doesn't have that many tiers!</span>")
		return
	if (input2 < 1) return

	for (var/datum/a in R.items_to_research[input2])
		if (a == R.current_research) continue // might shit itself if we swipe an in-progress research out from under them
		R.researched_items[input2] += a
		R.items_to_research[input2] -= a

/client/proc/RS_revoke_research()
	set category = "Specialist Debug"
	set name = "Revoke Single Research"
	set desc = "Revert a finished research to unresearched."

	var/input = input("Which kind of research?", "Which?", null) as null|anything in list("Disease","Artifact","Robotics")
	var/research/R

	if (input == "Disease") R = disease_research
	else if (input == "Artifact") R = artifact_research
	else if (input == "Robotics") R = robotics_research
	else
		boutput(usr, "<span style=\"color:red\">Invalid Research type.</span>")
		return FALSE

	var/input2 = input("Which tier?", "Which?", null) as num
	if (input2 > R.max_tiers)
		boutput(usr, "<span style=\"color:red\">This research doesn't have that many tiers!</span>")
		return
	if (input2 < 1) return

	var/list/unfinished = list()
	var/count = 0
	for (var/datum/a in R.researched_items[input2])
		count++
		unfinished += a

	if (!count)
		boutput(usr, "<span style=\"color:red\">Nothing has been researched in that tier.</span>")
		return
	var/complete = input("Revoke which research?", "Which?", null) as null|anything in unfinished
	if (!complete) return

	R.researched_items[input2] -= complete
	R.items_to_research[input2] += complete

/client/proc/RS_revoke_tier()
	set category = "Specialist Debug"
	set name = "Revoke Whole Tier"
	set desc = "Instantly revert an entire tier of researched topics to unresearched."

	var/input = input("Which kind of research?", "Which?", null) as null|anything in list("Disease","Artifact","Robotics")
	var/research/R

	if (input == "Disease") R = disease_research
	else if (input == "Artifact") R = artifact_research
	else if (input == "Robotics") R = robotics_research
	else
		boutput(usr, "<span style=\"color:red\">Invalid Research type.</span>")
		return FALSE

	var/input2 = input("Which tier?", "Which?", null) as num
	if (input2 > R.max_tiers)
		boutput(usr, "<span style=\"color:red\">This research doesn't have that many tiers!</span>")
		return
	if (input2 < 1) return

	for (var/datum/a in R.researched_items[input2])
		R.researched_items[input2] -= a
		R.items_to_research[input2] += a