/mob/proc/make_changeling()
	var/abilityHolder/changeling/O = get_ability_holder(/abilityHolder/changeling)
	if (O)
		return

	if (mind && !mind.is_changeling && (mind.special_role != "omnitraitor"))
		src << browse(grabResource("html/traitorTips/changelingTips.html"),"window=antagTips;titlebar=1;size=600x400;can_minimize=0;can_resize=0")

	var/abilityHolder/changeling/C = add_ability_holder(/abilityHolder/changeling)
	C.addAbility(/targetable/changeling/abomination)
	C.addAbility(/targetable/changeling/absorb)
	C.addAbility(/targetable/changeling/devour)
	C.addAbility(/targetable/changeling/mimic_voice)
	C.addAbility(/targetable/changeling/monkey)
	C.addAbility(/targetable/changeling/regeneration)
	C.addAbility(/targetable/changeling/scream)
	C.addAbility(/targetable/changeling/spit)
	C.addAbility(/targetable/changeling/stasis)
	C.addAbility(/targetable/changeling/sting/neurotoxin)
	C.addAbility(/targetable/changeling/sting/lsd)
	C.addAbility(/targetable/changeling/sting/dna)
	C.addAbility(/targetable/changeling/transform)

	if (mind)
		mind.is_changeling = C

	spawn (25) // Don't remove.
		if (src) assign_gimmick_skull()

	return

/obj/screen/ability/changeling
	clicked(params)
		var/targetable/changeling/spell = owner
		var/abilityHolder/holder = owner.holder

		if (!istype(spell))
			return
		if (!spell.holder)
			return

		if (params["shift"] && params["ctrl"])
			if (owner.waiting_for_hotkey)
				holder.cancel_action_binding()
				return
			else
				owner.waiting_for_hotkey = 1
				updateIcon()
				boutput(usr, "<span style=\"color:blue\">Please press a number to bind this ability to...</span>")
				return

		if (!isturf(owner.holder.owner.loc) && !spell.can_use_in_container)
			boutput(owner.holder.owner, "<span style=\"color:red\">Using that in here will do just about no good for you.</span>")
			return
		if (spell.targeted && usr:targeting_spell == owner)
			usr:targeting_spell = null
			usr.update_cursor()
			return
		if (spell.targeted)
			if (world.time < spell.last_cast)
				return
			owner.holder.owner.targeting_spell = owner
			owner.holder.owner.update_cursor()
		else
			spawn
				spell.handleCast()

/abilityHolder/changeling
	usesPoints = 1
	regenRate = 0
	tabName = "Changeling"
	notEnoughPointsMessage = "<span style=\"color:red\">We are not strong enough to do this.</span>"
	var/list/absorbed_dna = list()
	var/in_fakedeath = 0
	var/absorbtions = 0

	New(var/mob/living/M)
		..()
		var/bioHolder/original = new/bioHolder(M)
		original.CopyOther(M.bioHolder)
		absorbed_dna = list("[M.name]" = original)

	proc/addDna(var/mob/living/M, var/headspider_override = 0)
		var/abilityHolder/changeling/O = M.get_ability_holder(/abilityHolder/changeling)
		if (O)
			boutput(owner, "<span style=\"color:blue\">[M] was a changeling! We have absorbed their entire genetic structure!</span>")
			logTheThing("combat", owner, M, "absorbs %target% as a changeling [log_loc(owner)].")

			if (headspider_override != 1) // Headspiders shouldn't be free.
				src.points += 10 // 10 regular points for their body...
			if (O.points > 0) // ...and then grab their DNA stockpile too.
				points = max(0, points + O.points)

			absorbtions++ // Same principle.
			for (var/D in O.absorbed_dna)
				absorbed_dna[D] = O.absorbed_dna[D]
				absorbtions++

			O.absorbed_dna = list()
			O.points = 0
		else
			var/bioHolder/original = new/bioHolder(M)
			original.CopyOther(M.bioHolder)
			absorbed_dna[M.real_name] = original
			if (headspider_override != 1)
				points += 10
			absorbtions++

	onAbilityStat()
		..()
		//On Changeling tab
		stat("Absorbed DNA:", absorbtions)
		stat("DNA Points:", points)

// ----------------------------------------
// Generic abilities that critters may have
// ----------------------------------------

/targetable/changeling
	icon = 'icons/mob/spell_buttons.dmi'
	icon_state = "template" // No longer ToDo thanks to Sundance420.
	cooldown = 0
	last_cast = 0
	var/abomination_only = 0
	var/human_only = 0
	var/can_use_in_container = 0
	preferred_holder_type = /abilityHolder/changeling

	New()
		var/obj/screen/ability/changeling/B = new /obj/screen/ability/changeling(null)
		B.icon = icon
		B.icon_state = icon_state
		B.owner = src
		B.name = name
		B.desc = desc
		object = B

	updateObject()
		..()
		if (!object)
			object = new /obj/screen/ability/changeling()
			object.icon = icon
			object.owner = src
		if (last_cast > world.time)
			var/pttxt = ""
			if (pointCost)
				pttxt = " \[[pointCost]\]"
			object.name = "[name][pttxt] ([round((last_cast-world.time)/10)])"
			object.icon_state = icon_state + "_cd"
		else
			var/pttxt = ""
			if (pointCost)
				pttxt = " \[[pointCost]\]"
			object.name = "[name][pttxt]"
			object.icon_state = icon_state

	proc/incapacitationCheck()
		var/mob/living/M = holder.owner
		var/abilityHolder/changeling/H = holder
		if (istype(H) && H.in_fakedeath)
			return TRUE
		return M.stat || M.paralysis

	castcheck()
		if (incapacitationCheck())
			boutput(holder.owner, __red("We cannot use our abilities while incapacitated."))
			return FALSE
		if (!human_only && !abomination_only)
			return TRUE
		var/mob/living/carbon/human/H = holder.owner
		if (istype(H))
			if (human_only && !istype(H.mutantrace, /mutantrace/abomination) && !istype(H.mutantrace, /mutantrace/monkey))
				return TRUE
			else if (abomination_only && istype(H.mutantrace, /mutantrace/abomination))
				return TRUE
			else
				boutput(holder.owner, __red("You're not supposed to see this ability! Notify a coder."))
				boutput(holder.owner, __red("Also notify a coder if you see this message when you didn't actually click an ability."))
		return FALSE

	cast(atom/target)
		. = ..()
		actions.interrupt(holder.owner, INTERRUPT_ACT)

	Stat()
		if (!human_only && !abomination_only)
			..()
		var/mob/living/carbon/human/H = holder.owner
		if (istype(H))
			if (human_only && !istype(H.mutantrace, /mutantrace/abomination) && !istype(H.mutantrace, /mutantrace/monkey))
				..()
			else if (abomination_only && istype(H.mutantrace, /mutantrace/abomination))
				..()
