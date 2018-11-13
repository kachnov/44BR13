// -----------------------------------
// Devour using an action as the timer
// -----------------------------------

/action/bar/icon/devourAbility
	duration = 40
	interrupt_flags = INTERRUPT_MOVE | INTERRUPT_ACT | INTERRUPT_STUNNED | INTERRUPT_ACTION
	id = "critter_devour"
	icon = 'icons/mob/critter_ui.dmi' 
	icon_state = "devour_over"
	var/mob/living/target
	var/targetable/critter/devour/devour

	New(Target, Devour)
		target = Target
		devour = Devour
		..()

	onUpdate()
		..()

		if (get_dist(owner, target) > 1 || target == null || owner == null || !devour || !devour.cooldowncheck())
			interrupt(INTERRUPT_ALWAYS)
			return

	onStart()
		..()
		if (get_dist(owner, target) > 1 || target == null || owner == null || !devour || !devour.cooldowncheck())
			interrupt(INTERRUPT_ALWAYS)
			return

		for (var/mob/O in AIviewers(owner))
			O.show_message("<span style=\"color:red\"><strong>[owner] attempts to devour [target]!</strong></span>", 1)

	onEnd()
		..()
		var/mob/ownerMob = owner
		if (owner && ownerMob && target && get_dist(owner, target) <= 1 && devour && devour.cooldowncheck())
			logTheThing("combat", ownerMob, target, "devours %target%.")
			for (var/mob/O in AIviewers(ownerMob))
				O.show_message("<span style=\"color:red\"><strong>[owner] devours [target]!</strong></span>", 1)
			playsound(get_turf(ownerMob), pick("sound/misc/burp_alien.ogg"), 50, 0)
			ownerMob.health = ownerMob.max_health
			if (target == owner)
				boutput(owner, "<span class='color:green'>Good. Job.</span>")
			target.ghostize()
			devour.actionFinishCooldown()
			qdel(target)

/targetable/critter/devour
	name = "Devour"
	desc = "After a short delay, instantly devour a mob. Both you and the target must stand still for this."
	cooldown = 0
	var/actual_cooldown = 200
	targeted = 1
	target_anything = 1

	proc/actionFinishCooldown()
		cooldown = actual_cooldown
		doCooldown()
		cooldown = initial(cooldown)

	cast(atom/target)
		if (..())
			return TRUE
		if (isobj(target))
			target = get_turf(target)
		if (isturf(target))
			target = locate(/mob/living) in target
			if (!target)
				boutput(holder.owner, __red("Nothing to devour there."))
				return TRUE
		if (!istype(target, /mob/living))
			boutput(holder.owner, __red("Invalid target."))
			return TRUE
		if (get_dist(holder.owner, target) > 1)
			boutput(holder.owner, __red("That is too far away to devour."))
			return TRUE
		actions.start(new/action/bar/icon/devourAbility(target, src), holder.owner)
		return FALSE