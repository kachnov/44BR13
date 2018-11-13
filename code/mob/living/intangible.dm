/mob/living/intangible
	icon = 'icons/mob/mob.dmi'
	icon_state = "ghost"
	layer = NOLIGHT_EFFECTS_LAYER_BASE
	density = 0
	canmove = 1
	blinded = 0
	anchored = 1

	New()
		. = ..()
		invisibility = 10
		sight |= SEE_TURFS | SEE_MOBS | SEE_OBJS | SEE_SELF
		see_invisible = 15
		see_in_dark = SEE_DARK_FULL

	can_strip()
		return FALSE
	can_use_hands()
		return FALSE
	is_active()
		return FALSE
	say_understands(var/other)
		return TRUE
	CanPass(atom/movable/mover, turf/target, height=0, air_group=0)
		return TRUE

	meteorhit()
		return

	// No log entries for unaffected mobs (Convair880).
	ex_act(severity)
		return

	Move(NewLoc, direct)
		if (!canmove) return

		if (NewLoc && isrestrictedz(z) && !restricted_z_allowed(src, NewLoc) && !(client && client.holder))
			var/OS = observer_start.len ? pick(observer_start) : locate(1, 1, 1)
			if (OS)
				set_loc(OS)
			else
				z = 1
			return

		if (!isturf(loc))
			set_loc(get_turf(src))
		if (NewLoc)
			set_loc(NewLoc)
			return
		if ((direct & NORTH) && y < world.maxy)
			y++
		if ((direct & SOUTH) && y > 1)
			y--
		if ((direct & EAST) && x < world.maxx)
			x++
		if ((direct & WEST) && x > 1)
			x--

/mob/living/intangible/change_eye_blurry(var/amount, var/cap = 0)
	if (amount < 0)
		return ..()
	else
		return TRUE

/mob/living/intangible/take_eye_damage(var/amount, var/tempblind = 0)
	if (amount < 0)
		return ..()
	else
		return TRUE

/mob/living/intangible/take_ear_damage(var/amount, var/tempdeaf = 0)
	if (amount < 0)
		return ..()
	else
		return TRUE