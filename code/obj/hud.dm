/obj/hud
	name = "hud"
	anchored = 1
	var/mob/mymob = null
	var/list/adding = null
	var/list/other = null
	var/list/intents = null
	var/list/mov_int = null
	var/list/mon_blo = null
	var/list/m_ints = null
	var/list/darkMask = null

	var/h_type = /obj/screen

/obj/hud/New(var/type = 0)
	instantiate(type)
	..()
	return

/obj/hud/var/show_otherinventory = 1
/obj/hud/var/obj/screen/action_intent = null 
/obj/hud/var/obj/screen/move_intent = null

/obj/hud/proc/instantiate(var/type = 0)

	mymob = loc
	ASSERT(istype(mymob, /mob))

	if (istype(mymob, /mob/living/silicon/hivebot))
		hivebot_hud()
		return

	if (istype(mymob, /mob/living/object))
		src.object_hud()
		return