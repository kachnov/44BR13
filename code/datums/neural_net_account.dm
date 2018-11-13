/neural_net_account
	var/static/id = 0
	var/name = ""
	var/agent = ""
	var/points = 0
	var/mutts = 0
	var/mob/living/carbon/human/owner = null

/neural_net_account/New(_owner)
	..()
	if (!id)
		id = rand(1000,9000)
	name = "NPC #[id++]"
	agent = "[pick("Ben", "Schlomo", "Ruth", "Abraham", "Adam")] [pick("Rothschild", "Goldstein", "Goldberg", "Shapiro")]"
	owner = _owner

/neural_net_account/proc/Stat()

	. = list()
	.["Agent"] = agent
	.["Door Access"] = "All"
	.["Good Boy Points"] = points 
	.["Mutts Fathered"] = mutts

/neural_net_account/proc/conceived_mutt(var/mob/living/carbon/human/mutt/M)
	var/_points = M.good_boy_points
	boutput(owner, "Congratulations on fathering a new [M.caste_name], [name]! Your agent, <strong>[agent]</strong> " + \
		"has deposited [_points] GBP into your account.")
	points += _points
	++mutts
	
// subtypes
/neural_net_account/boomer_soldier
/neural_net_account/boomer_mpo
/neural_net_account/boomer_officer
/neural_net_account/boomer_general

/neural_net_account/jew
	var/static/num = 0
	var/static/lawnmower_authorizations = 0
	var/static/list/jews = list()

/neural_net_account/jew/New(_owner)
	..(_owner)
	// name is our actual name
	name = owner.name
	// no agent
	agent = "N/A"
	// plenty of GBP
	points = 500
	// increment the number of jews
	++num
	// and add the owner to the jews list 
	jews += owner

/neural_net_account/jew/proc/send_lawnmowers()

	if (chairs_process.preparing)
		boutput(owner, "<span style = \"color:red\"><strong>The lawnmowers are already fueling up.</strong></span>")
	else if (chairs_process.locked)
		boutput(owner, "<span style = \"color:red\"><strong>The lawnmowers are not ready to move again yet.</strong></span>")
	else

		++lawnmower_authorizations
		for (var/jew in jews)
			if (jew)
				var/auths_left = number_of_jews_to_send() - lawnmower_authorizations
				boutput(jew, "<big>[owner.real_name] has authorized the Lawnmowers to be sent " + \
					"[chairs_process.backwards_or_forwards]. [auths_left] more " + \
					"authorization[auths_left != 1 ? "s" : ""] are needed.</big>")
			else
				jews -= jew

		if (lawnmower_authorizations >= number_of_jews_to_send())
			boutput(world, "<big>The Jews have authorized the sending of the lawnmowers! The lawnmowers will be sent " + \
				 "[chairs_process.backwards_or_forwards] in [chairs_process.time_desc()]!")
			chairs_process.prepare()
			lawnmower_authorizations = 0

/neural_net_account/jew/proc/number_of_jews_to_send()
	return max(1, round(length(jews)/2))