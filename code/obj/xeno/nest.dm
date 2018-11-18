/obj/xeno/nest
	name = "resin nest"
	desc = "a strange resin nest of some sort."
	density = FALSE
	anchored = TRUE
	icon = 'icons/mob/xeno/xeno.dmi'
	icon_state = "nest"
	var/health = 10
	var/static/obj/overlay = null

/obj/xeno/nest/New()
	..()
	if (!overlay)
		overlay = new /obj
		overlay.icon = 'icons/mob/xeno/xeno.dmi'
		overlay.icon_state = "nest_overlay"
		overlay.layer = MOB_LAYER + 0.01

/obj/xeno/nest/MouseDrop_T(var/mob/M, var/mob/user)
	if ((!( istype(M, /mob) ) || get_dist(src, user) > 1 || user.restrained() || usr.stat))
		return
	for (var/mob/O in viewers(user, null))
		if ((O.client && !( O.blinded )))
			boutput(O, text("<span style=\"color:blue\">[M] is absorbed by the nest!</span>"))
	M.anchored = TRUE
	if (ishuman(M))
		var/mob/living/carbon/human/H = M
		H.forced_lie = TRUE
		H.handle_stuns_lying()
	M.buckled = src
	M.set_loc(loc)
	M.vis_contents += overlay
	add_fingerprint(user)

/obj/xeno/nest/attack_hand(var/mob/user)
	..(user)
	if (isxenomorph(user))
		free(user)

/obj/xeno/nest/attackby(var/obj/item/W, var/mob/user)

	switch(W.damtype)
		if ("fire")
			health -= (W.force * 0.75)
		else
			health -= (W.force * 0.10)

	if (health <= 0)
		visible_message("<span style=\"color:red\"><strong>[user] has destroyed the nest.</strong></span>")
		death()

	return ..()

/obj/xeno/nest/proc/free(var/mob/user)
	for (var/mob/M in loc)
		if (M.buckled)
			visible_message("<span style=\"color:blue\">[M] is released from the nest.</span>")
			M.vis_contents -= overlay
			M.anchored = FALSE
			if (ishuman(M))
				var/mob/living/carbon/human/H = M
				H.forced_lie = FALSE
			M.buckled = null
			if (user)
				add_fingerprint(user)

/obj/xeno/nest/proc/death()
	free(null)
	qdel(src)