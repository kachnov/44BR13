/mob/dead/hhghost
	icon = 'icons/mob/mob.dmi'
	icon_state = "ghost"
	layer = NOLIGHT_EFFECTS_LAYER_BASE
	density = 0
	canmove = 1
	blinded = 0
	anchored = 1
	var/mob/original = null
	name = "ghost"

/mob/dead/hhghost/disposing()
	original = null
	..()

/mob/dead/hhghost/New()
	. = ..()
	invisibility = 100
	sight |= SEE_TURFS | SEE_MOBS | SEE_OBJS | SEE_SELF
	see_invisible = 0

/mob/dead/hhghost/Login()
	..()
	if (!client) //This could not happen but hey byond and just in case.
		return

	client.images.Cut()

	for (var/image/I in orbicons)
		boutput(src, I)

	spawn (50)
		updateOrbs()
	return

/mob/dead/hhghost/proc/updateOrbs()
	set background = 1
	if (client)
		client.images.Cut()
		for (var/image/I in orbicons)
			boutput(src, I)
	spawn (50)
		updateOrbs()
	return

/mob/dead/hhghost/Logout()
	..()
	if (client)
		client.images.Cut()
	return

/mob/dead/hhghost/Move(var/turf/NewLoc, direct)
	if (!canmove) return
	if (!isturf(loc)) set_loc(get_turf(src))
	if (NewLoc)
		set_loc(NewLoc)
		NewLoc.HasEntered(src)
		for (var/atom/A in NewLoc)
			if (A == src) continue
			A.HasEntered(src)
		return
	if ((direct & NORTH) && y < world.maxy)
		y++
	if ((direct & SOUTH) && y > 1)
		y--
	if ((direct & EAST) && x < world.maxx)
		x++
	if ((direct & WEST) && x > 1)
		x--

/mob/dead/hhghost/can_use_hands()	return FALSE
/mob/dead/hhghost/is_active()		return FALSE

/mob/dead/observer/say_understands(var/other)
	return TRUE