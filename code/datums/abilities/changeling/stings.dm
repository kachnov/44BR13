/targetable/changeling/sting
	name = "Sting"
	desc = "Transfer some toxins into your target."
	var/stealthy = 1
	var/venom_id = "toxin"
	var/inject_amount = 50
	cooldown = 900
	targeted = 1
	target_anything = 1
	sticky = 1

	cast(atom/target)
		if (..())
			return TRUE
		if (isobj(target))
			target = get_turf(target)
		if (isturf(target))
			target = locate(/mob/living) in target
			if (!target)
				boutput(holder.owner, __red("We cannot sting without a target."))
				return TRUE
		if (target == holder.owner)
			return TRUE
		if (get_dist(holder.owner, target) > 1)
			boutput(holder.owner, __red("We cannot reach that target with our stinger."))
			return TRUE
		var/mob/MT = target
		if (!MT.reagents)
			boutput(holder.owner, __red("That does not hold reagents, apparently."))
		if (!stealthy)
			holder.owner.visible_message(__red("<strong>[holder.owner] stings [target]!</strong>"))
		else
			holder.owner.show_message(__blue("We stealthily sting [target]."))
		MT.reagents.add_reagent(venom_id, inject_amount)
		logTheThing("combat", holder.owner, MT, "stings %target% with [name] as a changeling [log_loc(holder.owner)].")

	neurotoxin
		name = "Neurotoxic Sting"
		desc = "Transfer some neurotoxin into your target."
		icon_state = "stingneuro"
		venom_id = "neurotoxin"

	lsd
		name = "Hallucinogenic Sting"
		desc = "Transfer some LSD into your target."
		icon_state = "stinglsd"
		venom_id = "LSD"
		inject_amount = 30

	dna
		name = "DNA Sting"
		desc = "Injects stable mutagen and the blood of the selected victim into your target."
		icon_state = "stingdna"
		venom_id = "dna_mutagen"
		inject_amount = 15
		pointCost = 4
		var/targetable/changeling/dna_target_select/targeting = null

		New()
			..()

		onAttach(var/abilityHolder/H)
			targeting = H.addAbility(/targetable/changeling/dna_target_select)
			targeting.sting = src
			if (H.owner)
				object.suffix = "\[[holder.owner.name]\]"

		cast(atom/target)
			if (..())
				return TRUE
			var/mob/MT = target
			MT.reagents.add_reagent("blood", 15, targeting.dna_sting_target)
			return FALSE

/targetable/changeling/dna_target_select
	name = "Select DNA Sting target"
	desc = "Select target for DNA sting"
	icon_state = "stingdna"
	cooldown = 0
	targeted = 0
	target_anything = 0
	copiable = 0
	dont_lock_holder = 1
	ignore_holder_lock = 1
	var/bioHolder/dna_sting_target = null
	var/targetable/changeling/sting = null
	sticky = 1

	onAttach(var/abilityHolder/G)
		var/abilityHolder/changeling/H = G
		if (istype(H))
			dna_sting_target = H.absorbed_dna[H.absorbed_dna[1]]

	cast(atom/target)
		if (..())
			return TRUE

		var/abilityHolder/changeling/H = holder
		if (!istype(H))
			boutput(holder.owner, __red("That ability is incompatible with our abilities. We should report this to a coder."))
			return TRUE

		var/target_name = input("Select new DNA sting target!", "DNA Sting Target", null) as null|anything in H.absorbed_dna
		if (!target_name)
			boutput(holder.owner, __blue("We change our mind."))
			return TRUE

		dna_sting_target = H.absorbed_dna[target_name]
		if (sting)
			sting.object.suffix = "\[[target_name]\]"

		return FALSE
