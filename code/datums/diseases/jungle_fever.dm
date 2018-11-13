/ailment/disease/jungle_fever
	name = "Jungle Fever"
	max_stages = 1
	cure = "Incurable"
	associated_reagent = "banana peel"
	affected_species = list("Monkey")

	stage_act(var/mob/living/carbon/human/affected_mob,var/ailment_data/D)
		if (..() || !istype(affected_mob))
			return TRUE


		if (!affected_mob:mutantrace)
			affected_mob:monkeyize()

		return FALSE