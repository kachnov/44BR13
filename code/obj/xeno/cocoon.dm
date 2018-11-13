/*

Better way to do this might be to make it a verb on a person and to cocoon the person in some kind of resin
If they're next to a wall this would change their pixel and attach them to the wall, otherwise it'd cause
Them to lie down and attach them to the floor, this could be easily done by changing the bed code.

This would mean having a variable affected_mob or something that we could keep the person stunned/alive while
they're trapped
*/
/obj/xeno/cocoon
	name = "cocoon"
	desc = "a strange... something..."
	density = 1.0
	anchored = 1.0
	icon = 'icons/obj/objects.dmi'
	icon_state = "toilet"

	var/health = 10

	MouseDrop_T(mob/M as mob, mob/user as mob)
		if (!ticker)
			boutput(user, "You can't buckle anyone in before the game starts.")
			return
		if ((!( istype(M, /mob) ) || get_dist(src, user) > 1 || user.restrained() || usr.stat))
			return
		for (var/mob/O in viewers(user, null))
			if ((O.client && !( O.blinded )))
				boutput(O, text("<span style=\"color:blue\">[M] is absorbed by the cocoon!</span>"))
		M.anchored = 1
		M.buckled = src
		M.set_loc(loc)
		add_fingerprint(user)
		return

	attack_hand(mob/user as mob)
		if (health <= 0)
			for (var/mob/M in loc)
				if (M.buckled)
					visible_message("<span style=\"color:blue\">[M] appears from the cocoon.</span>")
		//			boutput(world, "[M] is no longer buckled to [src]")
					M.anchored = 0
					M.buckled = null
					add_fingerprint(user)
		return

	attackby(obj/item/W as obj, mob/user as mob)
		if (health <= 0)
			visible_message("<span style=\"color:red\"><strong>[user] has destroyed the cocoon.</strong></span>")
			death()
			return

		switch(W.damtype)
			if ("fire")
				health -= W.force * 0.75
			if ("brute")
				health -= W.force * 0.1
			else
		..()

	proc/death()
		icon_state = "egg_destroyed"	//need an icon for this
		density = 0