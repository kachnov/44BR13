/obj/screen/ability/topBar/cruiser
	clicked(params)
		var/targetable/cruiser/spell = owner
		var/abilityHolder/holder = owner.holder


		if (params["left"] && params["ctrl"])
			if (owner.waiting_for_hotkey)
				holder.cancel_action_binding()
			else
				owner.waiting_for_hotkey = 1
				boutput(usr, "<span style=\"color:blue\">Please press a number to bind this ability to...</span>")
		else if (params["left"])
			if (!istype(spell))
				return
			if (!spell.holder)
				return
			if (spell.targeted && usr:targeting_spell == owner)
				usr:targeting_spell = null
				usr.update_cursor()
				return
			if (spell.targeted)
				if (world.time < spell.last_cast)
					return
				usr:targeting_spell = owner
				usr.update_cursor()
				return
			else
				spawn
					spell.handleCast()

		owner.holder.updateButtons()

/abilityHolder/cruiser
	topBarRendered = 1
	usesPoints = 0
	regenRate = 0
	tabName = "Cruiser Controls"

// ----------------------------------------
// Controls for the cruiser ships.
// ----------------------------------------

/targetable/cruiser
	icon = 'icons/mob/cruiser_ui.dmi'
	icon_state = ""
	cooldown = 0
	last_cast = 0
	check_range = 0
	var/disabled = 0
	var/toggled = 0
	var/is_on = 0   // used if a toggle ability
	preferred_holder_type = /abilityHolder/cruiser
	ignore_sticky_cooldown = 1

	New()
		var/obj/screen/ability/topBar/cruiser/B = new /obj/screen/ability/topBar/cruiser(null)
		B.icon = icon
		B.icon_state = icon_state
		B.owner = src
		B.name = name
		B.desc = desc
		object = B

	updateObject()
		..()
		if (!object)
			object = new /obj/screen/ability/topBar/cruiser()
			object.icon = icon
			object.owner = src
		if (disabled)
			object.name = "[name] (unavailable)"
			object.icon_state = icon_state + "_cd"
		else if (last_cast > world.time)
			object.name = "[name] ([round((last_cast-world.time)/10)])"
			object.icon_state = icon_state + "_cd"
		else if (toggled)
			if (is_on)
				object.name = "[name] (on)"
				object.icon_state = icon_state
			else
				object.name = "[name] (off)"
				object.icon_state = icon_state + "_cd"
		else
			object.name = name
			object.icon_state = icon_state

	proc/incapacitationCheck()
		var/mob/living/M = holder.owner
		return M.restrained() || M.stat || M.paralysis || M.stunned || M.weakened

	castcheck()
		if (incapacitationCheck())
			boutput(holder.owner, __red("Not while incapacitated."))
			return FALSE
		if (disabled)
			boutput(holder.owner, __red("You cannot use that ability at this time."))
			return FALSE
		return TRUE

	doCooldown()
		if (!holder)
			return
		last_cast = world.time + cooldown
		holder.updateButtons()
		spawn (cooldown + 5)
			holder.updateButtons()

	cast(atom/target)
		. = ..()
		actions.interrupt(holder.owner, INTERRUPT_ACT)