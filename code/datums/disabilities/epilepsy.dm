/ailment/disability/epilepsy
	name = "Epilepsy"
	max_stages = 1
	cure = "Mutadone"
	reagentcure = list("mutadone")
	recureprob = 7
	affected_species = list("Human","Monkey")

/ailment/disability/epilepsy/stage_act(var/mob/living/affected_mob,var/ailment_data/D)
	if (..())
		return
	var/mob/living/M = D.affected_mob
	if (prob(3))
		M.visible_message("<span style=\"color:red\"><strong>[M.name]</strong> has a siezure!</span>")
		M.paralysis = max(3, M.paralysis)
		M.make_jittery(100)