/targetable/vampire/plague_touch
	name = "Diseased touch"
	desc = "Infects the target with a deadly, non-contagious disease."
	targeted = 1
	target_nodamage_check = 1
	max_range = 1
	cooldown = 1800
	pointCost = 50
	when_stunned = 0
	not_when_handcuffed = 1
	unlock_message = "You have gained diseased touch, which inflicts someone with a deadly, non-contagious disease."

	cast(mob/target)
		if (!holder)
			return TRUE

		var/mob/living/M = holder.owner
		var/abilityHolder/vampire/H = holder

		if (!M || !target || !ismob(target))
			return TRUE

		if (M == target)
			boutput(M, __red("Why would you want to infect yourself?"))
			return TRUE

		if (get_dist(M, target) > max_range)
			boutput(M, __red("[target] is too far away."))
			return TRUE

		if (target.stat == 2)
			boutput(M, __red("It would be a waste of time to infect the dead."))
			return TRUE

		if (!iscarbon(target))
			boutput(M, __red("[target] is immune to the disease."))
			return TRUE

		var/mob/living/L = target

		playsound(M.loc, 'sound/weapons/thudswoosh.ogg', 50, 1, -1)
		M.visible_message("<span style=\"color:blue\">[M] shakes [L], trying to wake them up!</span>")
		L.add_fingerprint(M) // Why not leave some forensic evidence?
		if (!(L.bioHolder && L.bioHolder.HasEffect("training_chaplain")))
			L.contract_disease(/ailment/disease/vamplague, null, null, 1) // path, name, strain, bypass resist

		if (istype(H)) H.blood_tracking_output(pointCost)
		logTheThing("combat", M, L, "uses diseased touch on %target% at [log_loc(M)].")
		return FALSE