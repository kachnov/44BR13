/targetable/vampire/radio_jammer
	name = "Radio interference"
	desc = "Temporarily disrupts all radio communication in the immediate vicinity."
	targeted = 0
	cooldown = 1800
	pointCost = 50
	when_stunned = 0
	not_when_handcuffed = 0
	var/duration = 300
	unlock_message = "You have gained radio interference. It temporarily disables all headsets and intercoms close to you."

	cast(mob/target)
		if (!holder)
			return TRUE

		var/mob/living/M = holder.owner
		var/abilityHolder/vampire/H = holder

		if (!M)
			return TRUE

		if (!(radio_controller && istype(radio_controller)))
			boutput(M, __red("Couldn't find the global radio controller. Please report this to a coder."))
			return TRUE

		if (radio_controller.active_jammers.Find(M))
			boutput(M, __red("You're already jamming radio signals."))
			return TRUE

		boutput(M, __blue("<strong>You will disrupt radio signals in your immediate vicinity for the next [duration / 10] seconds.</strong>"))
		radio_controller.active_jammers.Add(M)
		spawn (duration)
			if (M && istype(M) && radio_controller && istype(radio_controller) && radio_controller.active_jammers.Find(M))
				boutput(M, __red("<strong>You no longer disrupt radio signals.</strong>"))
				radio_controller.active_jammers.Remove(M)

		if (istype(H)) H.blood_tracking_output(pointCost)
		logTheThing("combat", M, null, "uses radio interference at [log_loc(M)].")
		return FALSE