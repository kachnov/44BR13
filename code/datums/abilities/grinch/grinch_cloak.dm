/targetable/grinch/grinch_cloak
	name = "Activate cloak (temp.)"
	desc = "Activates a cloaking ability for a limited amount of time."
	targeted = 0
	target_anything = 0
	target_nodamage_check = 0
	max_range = 0
	cooldown = 3600
	start_on_cooldown = 0
	pointCost = 0
	when_stunned = 0
	not_when_handcuffed = 0
	var/cloak_duration = 120

	cast(mob/target)
		if (!holder)
			return TRUE

		var/mob/living/M = holder.owner

		if (!M)
			return TRUE

		if (iscritter(M)) // Placeholder because only humans use bioeffects at the moment.
			if (M.invisibility != 0)
				boutput(M, __red("You are already invisible."))
				return TRUE

			M.invisibility = 2
			M.UpdateOverlays(image('icons/mob/mob.dmi', "icon_state" = "shield"), "shield")
			boutput(M, __blue("<strong>Your cloak will remain active for the next [cloak_duration / 60] minutes.</strong>"))

			spawn (cloak_duration * 10)
				if (M && iscritter(M))
					M.invisibility = 0
					M.UpdateOverlays(null, "shield")
					boutput(M, __red("<strong>You are no longer invisible.</strong>"))

		else if (ishuman(M))
			var/mob/living/carbon/human/MM = M
			if (!MM.bioHolder)
				boutput(MM, __red("You can't use this ability in your current form."))
				return TRUE

			if (MM.bioHolder.HasEffect("chameleon"))
				boutput(M, __red("You are already invisible."))
				return TRUE
			else
				var/bioEffect/power/chameleon/CC = MM.bioHolder.AddEffect("chameleon", 0, cloak_duration)
				if (CC && istype(CC))
					CC.active = 1 // Important!
					MM.set_body_icon_dirty()
					boutput(M, __blue("<strong>Your chameleon cloak is available for the next [cloak_duration / 60] minutes. Stand still to become invisible.</strong>"))

		return FALSE