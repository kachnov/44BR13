/targetable/grinch/instakill
	name = "Murder"
	desc = "Induces instant cardiac arrest in a target."
	targeted = 1
	target_anything = 0
	target_nodamage_check = 1
	max_range = 1
	cooldown = 4800
	start_on_cooldown = 0
	pointCost = 0
	when_stunned = 0
	not_when_handcuffed = 1

	cast(mob/target)
		if (!holder)
			return TRUE

		var/mob/living/M = holder.owner

		if (!M || !target || !ismob(target))
			return TRUE

		if (M == target)
			boutput(M, __red("Why would you want to kill yourself?"))
			return TRUE

		if (get_dist(M, target) > max_range)
			boutput(M, __red("[target] is too far away."))
			return TRUE

		if (target.stat == 2)
			boutput(M, __red("It would be a waste of time to murder the dead."))
			return TRUE

		if (!iscarbon(target))
			boutput(M, __red("[target] is immune to the disease."))
			return TRUE

		var/mob/living/L = target

		playsound(M.loc, 'sound/misc/loudcrunch.ogg', 75, 1, -1)
		M.visible_message("<span style=\"color:red\"><strong>[M] shrinks [L]'s heart down two sizes too small!</strong></span>")
		L.add_fingerprint(M) // Why not leave some forensic evidence?
		L.contract_disease(/ailment/disease/flatline, null, null, 1) // path, name, strain, bypass resist

		logTheThing("combat", M, L, "uses the murder ability to induce cardiac arrest on %target% at [log_loc(M)].")
		return FALSE