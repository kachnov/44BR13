/obj/xeno/wall/membrane
	name = "Alien membrane wall"
	icon_state = "membrane0"
	base_icon = "membrane"
	health = 50
	opacity = 0

/obj/xeno/wall/membrane/attack_hand(var/mob/user)
	if (isxenomorph(user))
		visible_message("<span style = \"color:red\"><strong>[user] starts to tear down \the [src].</strong></span>")
		if (do_after(user, 5 SECONDS, src))
			visible_message("<span style = \"color:red\"><strong>[user] tears down \the [src].</strong></span>")
			qdel(src)