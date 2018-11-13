/obj/xeno/egg
	desc = "It looks like a weird egg"
	name = "egg"
	icon_state = "egg"
	layer = MOB_LAYER
	density = 1
	anchored = 1

	var/health = 25

	New()
		spawn (900)
			if (health > 0)
				open()

	proc/open()
		spawn (10)
			density = 0
			icon_state = "egg_hatched"
			new /mob/living/critter/facehugger(loc)

	attackby(obj/item/W as obj, mob/user as mob)
		if (health <= 0)
			visible_message("<span style=\"color:red\"><strong>[user] has destroyed the egg!</strong></span>")
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