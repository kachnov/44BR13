/ailment/disability/tourettes
	name = "Tourettes Syndrome"
	max_stages = 1
	cure = "Mutadone"
	reagentcure = list("mutadone")
	recureprob = 5
	affected_species = list("Human")

/ailment/disability/tourettes/stage_act(var/mob/living/affected_mob,var/ailment_data/D)
	if (..())
		return
	var/mob/living/M = D.affected_mob
	var/list/swears = list("FUCK","SHIT","PISS","COCK","DICK","TITS","TWAT","PRICK","BITCH","ARGH","WOOF")
	if (prob(8))
		M.say(pick(swears))
	if (prob(8))
		M.emote("twitch")
	if (prob(6))
		M.visible_message("<span style=\"color:red\"><strong>[M.name]'s</strong> hands shake uncontrollably!</span>")
		var/h = M.hand
		M.hand = 0
		M.drop_item()
		M.hand = 1
		M.drop_item()
		M.hand = h
	if (prob(4))
		M.stunned = max(3, M.stunned)
		M.weakened = max(3, M.weakened)
		M.visible_message("<span style=\"color:red\"><strong>[M.name]</strong> falls to the ground, spasming wildly!</span>")