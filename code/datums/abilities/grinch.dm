// Converted everything related to grinches from client procs to ability holders and used
// the opportunity to do some clean-up as well (Convair880).

//////////////////////////////////////////// Setup //////////////////////////////////////////////////

/mob/proc/make_grinch()
	if (ishuman(src) || iscritter(src))
		if (ishuman(src))
			var/abilityHolder/grinch/A = get_ability_holder(/abilityHolder/grinch)
			if (A && istype(A))
				return

			var/abilityHolder/grinch/G = add_ability_holder(/abilityHolder/grinch)
			G.addAbility(/targetable/grinch/vandalism)
			G.addAbility(/targetable/grinch/poison)
			G.addAbility(/targetable/grinch/instakill)
			G.addAbility(/targetable/grinch/grinch_cloak)

			spawn (25) // Don't remove.
				if (src) assign_gimmick_skull()

		else if (iscritter(src))
			var/mob/living/critter/C = src

			if (isnull(C.abilityHolder)) // They do have a critter AH by default...or should.
				var/abilityHolder/grinch/A2 = C.add_ability_holder(/abilityHolder/grinch)
				if (!A2 || !istype(A2, /abilityHolder))
					return

			C.abilityHolder.addAbility(/targetable/grinch/vandalism)
			C.abilityHolder.addAbility(/targetable/grinch/poison)
			C.abilityHolder.addAbility(/targetable/grinch/instakill)
			C.abilityHolder.addAbility(/targetable/grinch/grinch_cloak)

		if (mind && mind.special_role != "omnitraitor")
			src << browse(grabResource("html/traitorTips/grinchTips.html"),"window=antagTips;titlebar=1;size=600x400;can_minimize=0;can_resize=0")

	else return

//////////////////////////////////////////// Ability holder /////////////////////////////////////////

/obj/screen/ability/grinch
	clicked(params)
		var/targetable/grinch/spell = owner
		if (!istype(spell))
			return
		if (!spell.holder)
			return
		if (!isturf(owner.holder.owner.loc))
			boutput(owner.holder.owner, "<span style=\"color:red\">You can't use this ability here.</span>")
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
		return

/abilityHolder/grinch
	usesPoints = 0
	regenRate = 0
	tabName = "Grinch"
	notEnoughPointsMessage = "<span style=\"color:red\">You aren't strong enough to use this ability.</span>"

/////////////////////////////////////////////// Grinch spell parent ////////////////////////////

/targetable/grinch
	icon = 'icons/mob/critter_ui.dmi'
	icon_state = "template"  // No custom sprites yet.
	cooldown = 0
	last_cast = 0
	pointCost = 0
	preferred_holder_type = /abilityHolder/grinch
	var/when_stunned = 0 // 0: Never | 1: Ignore mob.stunned and mob.weakened | 2: Ignore all incapacitation vars
	var/not_when_handcuffed = 0

	New()
		var/obj/screen/ability/grinch/B = new /obj/screen/ability/grinch(null)
		B.icon = icon
		B.icon_state = icon_state
		B.owner = src
		B.name = name
		B.desc = desc
		object = B
		return

	updateObject()
		..()
		if (!object)
			object = new /obj/screen/ability/grinch()
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
		return

	proc/incapacitation_check(var/stunned_only_is_okay = 0)
		if (!holder)
			return FALSE

		var/mob/living/M = holder.owner
		if (!M || !ismob(M))
			return FALSE

		switch (stunned_only_is_okay)
			if (0)
				if (M.stat != 0 || M.stunned > 0 || M.paralysis > 0 || M.weakened > 0)
					return FALSE
				else
					return TRUE
			if (1)
				if (M.stat != 0 || M.paralysis > 0)
					return FALSE
				else
					return TRUE
			else
				return TRUE

	castcheck()
		if (!holder)
			return FALSE

		var/mob/living/M = holder.owner

		if (!M)
			return FALSE

		if (!(ishuman(M) || iscritter(M)))
			boutput(M, __red("You cannot use any powers in your current form."))
			return FALSE

		if (M.transforming)
			boutput(M, __red("You can't use any powers right now."))
			return FALSE

		if (incapacitation_check(when_stunned) != 1)
			boutput(M, __red("You can't use this ability while incapacitated!"))
			return FALSE

		if (not_when_handcuffed == 1 && M.restrained())
			boutput(M, __red("You can't use this ability when restrained!"))
			return FALSE

		return TRUE

	cast(atom/target)
		. = ..()
		actions.interrupt(holder.owner, INTERRUPT_ACT)
		return