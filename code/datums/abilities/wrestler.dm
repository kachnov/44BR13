// Converted everything related to wrestlers from client procs to ability holders and used
// the opportunity to do some clean-up as well (Convair880).

//////////////////////////////////////////// Setup //////////////////////////////////////////////////

/mob/proc/make_wrestler(var/make_inherent = 0, var/belt_check = 0, var/remove_powers = 0)
	if (ishuman(src) || iscritter(src))
		if (iscritter(src))
			var/mob/living/critter/C = src

			if (remove_powers == 1)
				var/abilityHolder/wrestler/A = C.get_ability_holder(/abilityHolder/wrestler)
				if (A && istype(A))
					C.remove_ability_holder(/abilityHolder/wrestler)
				else
					C.abilityHolder.removeAbility(/targetable/wrestler/kick)
					C.abilityHolder.removeAbility(/targetable/wrestler/strike)
					C.abilityHolder.removeAbility(/targetable/wrestler/drop)
					C.abilityHolder.removeAbility(/targetable/wrestler/throw)
					C.abilityHolder.removeAbility(/targetable/wrestler/slam)

				return

			else
				if (belt_check == 1) // They don't have belts.
					return

				if (isnull(C.abilityHolder)) // But they do have a critter AH by default...or should.
					var/abilityHolder/wrestler/A2 = C.add_ability_holder(/abilityHolder/wrestler)
					if (!A2 || !istype(A2, /abilityHolder))
						return

				C.abilityHolder.addAbility(/targetable/wrestler/kick)
				C.abilityHolder.addAbility(/targetable/wrestler/strike)
				C.abilityHolder.addAbility(/targetable/wrestler/drop)
				C.abilityHolder.addAbility(/targetable/wrestler/throw)
				C.abilityHolder.addAbility(/targetable/wrestler/slam)

		if (ishuman(src))
			var/mob/living/carbon/human/H = src

			if (remove_powers == 1)
				var/abilityHolder/wrestler/A3 = H.get_ability_holder(/abilityHolder/wrestler)
				if (A3 && istype(A3))
					if (belt_check == 1 && A3.is_inherent == 1) // Wrestler/omnitraitor vs wrestling belt.
						return
					H.remove_ability_holder(/abilityHolder/wrestler)
				else
					if (!isnull(H.abilityHolder))
						H.abilityHolder.removeAbility(/targetable/wrestler/kick)
						H.abilityHolder.removeAbility(/targetable/wrestler/strike)
						H.abilityHolder.removeAbility(/targetable/wrestler/drop)
						H.abilityHolder.removeAbility(/targetable/wrestler/throw)
						H.abilityHolder.removeAbility(/targetable/wrestler/slam)

				return

			else
				if (belt_check == 1 && !(H.belt && istype(H.belt, /obj/item/storage/belt/wrestling)))
					return

				var/abilityHolder/wrestler/A4 = H.get_ability_holder(/abilityHolder/wrestler)
				if (A4 && istype(A4))
					return

				var/abilityHolder/wrestler/A5 = H.add_ability_holder(/abilityHolder/wrestler)
				A5.addAbility(/targetable/wrestler/kick)
				A5.addAbility(/targetable/wrestler/strike)
				A5.addAbility(/targetable/wrestler/drop)
				A5.addAbility(/targetable/wrestler/throw)
				A5.addAbility(/targetable/wrestler/slam)

				if (make_inherent == 1)
					A5.is_inherent = 1

		if (belt_check != 1 && (mind && mind.special_role != "omnitraitor"))
			src << browse(grabResource("html/traitorTips/wrestlerTips.html"),"window=antagTips;titlebar=1;size=600x400;can_minimize=0;can_resize=0")

	else return

//////////////////////////////////////////// Ability holder /////////////////////////////////////////

/obj/screen/ability/wrestler
	clicked(params)
		var/targetable/wrestler/spell = owner
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

		var/use_targeted = do_target_selection_check()
		if (use_targeted == 2)
			return
		if (spell.targeted || use_targeted == 1)
			if (world.time < spell.last_cast)
				return
			owner.holder.owner.targeting_spell = owner
			owner.holder.owner.update_cursor()
		else
			spawn
				spell.handleCast()
		return

/abilityHolder/wrestler
	usesPoints = 0
	regenRate = 0
	tabName = "Wrestler"
	notEnoughPointsMessage = "<span style=\"color:red\">You aren't strong enough to use this ability.</span>"
	var/is_inherent = 0 // Are we a wrestler as opposed to somebody with a wrestling belt?

/////////////////////////////////////////////// Wrestler spell parent ////////////////////////////

/targetable/wrestler
	icon = 'icons/mob/critter_ui.dmi'
	icon_state = "template"  // No custom sprites yet.
	cooldown = 0
	start_on_cooldown = 1 // So you can't bypass the cooldown by taking off your belt and re-equipping it.
	last_cast = 0
	pointCost = 0
	preferred_holder_type = /abilityHolder/wrestler
	var/when_stunned = 0 // 0: Never | 1: Ignore mob.stunned and mob.weakened | 2: Ignore all incapacitation vars
	var/not_when_handcuffed = 0

	New()
		var/obj/screen/ability/wrestler/B = new /obj/screen/ability/wrestler(null)
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
			object = new /obj/screen/ability/wrestler()
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
		var/abilityHolder/wrestler/H = holder

		if (!M)
			return FALSE

		// The HUD autoequip code doesn't call unequipped() when it should, naturally.
		if (ishuman(M) && (istype(H) && H.is_inherent != 1))
			var/mob/living/carbon/human/HH = M
			if (!(HH.belt && istype(HH.belt, /obj/item/storage/belt/wrestling)))
				boutput(HH, __red("You have to wear the wrestling belt for this."))
				HH.make_wrestler(0, 1, 1)
				return FALSE

		if (!(ishuman(M) || iscritter(M))) // Not all critters have arms to grab people with, but whatever.
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
		return FALSE

	proc/calculate_cooldown()
		if (!holder)
			return FALSE

		var/mob/living/M = holder.owner

		if (!M || !istype(M))
			return FALSE

		var/CD = cooldown
		var/ST_mod_max = M.get_stam_mod_max()
		var/ST_mod_regen = M.get_stam_mod_regen()

		// Balanced for 200/12 and 200/13 drugs (e.g. epinephrine or meth), so stamina regeneration
		// buffs are prioritized over total stamina modifiers.
		var/R = cooldown - (((ST_mod_max / 3 ) + (ST_mod_regen * 2)) * 10)
		if (R > (cooldown * 2.5))
			R = cooldown * 2.5 // Chems with severe stamina penalty exist, so this should be capped.
		CD = max((cooldown / 2.5), R) // About the same minimum as the old wrestling belt procs.

		//DEBUG("Default CD: [cooldown]. Modifier: [R]. Actual CD: [CD].")
		return CD

	doCooldown()
		last_cast = world.time + calculate_cooldown()

		if (!holder.owner || !ismob(holder.owner))
			return

		// Why isn't this in afterCast()? Well, failed attempts to use an abililty call it too.
		spawn (rand(200, 900))
			if (holder && holder.owner && ismob(holder.owner))
				holder.owner.emote("flex")

		return