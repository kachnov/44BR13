/targetable/changeling/abomination
	name = "Horror Form"
	desc = "Become something much more powerful."
	icon_state = "horror"
	cooldown = 0
	targeted = 0
	target_anything = 0
	can_use_in_container = 1

	cast(atom/target)
		if (..())
			return TRUE

		var/mob/living/carbon/human/H = holder.owner
		if (H.mutantrace)
			if (istype(H.mutantrace, /mutantrace/abomination))
				if (alert("Are we sure?","Exit Horror Form?","Yes","No") != "Yes")
					return TRUE
				H.revert_from_horror_form()
			else if (istype(H.mutantrace, /mutantrace/monkey))
				boutput(H, "We cannot transform in this form.")
				return TRUE
			else
				boutput(H, "We cannot transform in this form.")
				return TRUE
		else
			if (holder.points < 15)
				boutput(holder.owner, __red("We're not strong enough to maintain the form."))
				return TRUE
			if (alert("Are we sure?","Enter Horror Form?","Yes","No") != "Yes")
				return TRUE
			H.set_mutantrace(/mutantrace/abomination)
			H.stat = 0
			H.real_name = "Shambling Abomination"
			H.name = "Shambling Abomination"
			H.update_face()
			H.update_body()
			H.update_clothing()
			logTheThing("combat", H, null, "enters horror form as a changeling, [log_loc(H)].")
			return FALSE

/mob/proc/revert_from_horror_form()
	if (ishuman(src))
		var/mob/living/carbon/human/H = src
		qdel(H.mutantrace)
		H.set_mutantrace(null)
		var/abilityHolder/changeling/C = H.get_ability_holder(/abilityHolder/changeling)
		if (!C || C.points < 15)
			boutput(H, __red("You weren't strong enough to change back safely and blacked out!"))
			H.paralysis += 8
		else
			boutput(H, __red("You revert back to your original form. It leaves you weak."))
			H.weakened += 5
		if (C)
			C.points = max(C.points - 15, 0)
			var/D = pick(C.absorbed_dna)
			H.real_name = D
			H.name = D
			H.bioHolder.CopyOther(C.absorbed_dna[D])
		H.update_face()
		H.update_body()
		H.update_clothing()
		logTheThing("combat", H, null, "voluntarily leaves horror form as a changeling, [log_loc(H)].")
		return FALSE

/targetable/changeling/scream
	name = "Horrific Scream"
	desc = "A terrorizing scream that causes everyone nearby to become flustered."
	icon_state = "scream"
	cooldown = 100
	targeted = 0
	target_anything = 0
	pointCost = 1
	abomination_only = 1

	cast(atom/target)
		if (..())
			return TRUE
		holder.owner.visible_message(__red("<strong>[holder.owner] screeches loudly! The very noise fills you with dread!</strong>"))
		logTheThing("combat", holder.owner, null, "screeches as a changeling in horror form [log_loc(holder.owner)].")
		playsound(holder.owner.loc, 'sound/voice/creepyshriek.ogg', 80, 1) // cogwerks - using ISN's scary goddamn shriek here

		for (var/mob/living/O in viewers(holder.owner, null))
			if (O == holder.owner)
				continue
			O.apply_sonic_stun(0, 0, 0, 10, 35, rand(0, 2))

		return FALSE