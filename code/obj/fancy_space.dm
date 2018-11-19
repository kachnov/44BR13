/obj/fancy_space
	mouse_opacity = 0
	plane = -2
	anchored = TRUE
	icon = 'icons/fancy_space736x736.dmi'
	icon_state = "space"
	appearance_flags = TILE_BOUND
	screen_loc = "1,1"

/mob/Login()
	..()
	if (client && !list_find_type(client.screen, /obj/fancy_space))
		client.screen += new /obj/fancy_space

/mob/Move()
	..()
	if (client && !list_find_type(client.screen, /obj/fancy_space))
		client.screen += new /obj/fancy_space

/mob/forceMove()
	..()
	if (client && !list_find_type(client.screen, /obj/fancy_space))
		client.screen += new /obj/fancy_space
