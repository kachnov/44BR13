/obj/xeno/wall/proc/Autojoin(var/smooth_icon)
	var/junction = 0 //will be used to determine from which side the wall is connected to other walls
	for(var/obj/xeno/wall/W in orange(src,1))
		if(W.type in typesof(type))
			if(abs(x-W.x)-abs(y-W.y))
				junction += get_dir(src,W)
	icon_state = "[smooth_icon][junction]"

/obj/xeno/wall
	density = 1
	anchored = 1
	opacity = 1
	icon = 'icons/mob/xeno/xeno.dmi'
	layer = TURF_LAYER + 0.25
	name = "Resin wall"
	icon_state = "wall0"
	var/base_icon = "wall"
	var/health = 100

/obj/xeno/wall/attackby(obj/item/W as obj, mob/user as mob)
	if (!W) return
	if (!user) return
	health -= W.force*0.5
	if(health < 0)
		qdel(src)
		return
	..()

/obj/xeno/wall/attack_hand(var/mob/user)
	if (isxenomorph(user))
		visible_message("<span style = \"color:red\"><strong>[user] starts to tear down \the [src].</strong></span>")
		if (do_after(user, 5 SECONDS, src))
			visible_message("<span style = \"color:red\"><strong>[user] tears down \the [src].</strong></span>")
			qdel(src)

/obj/xeno/wall/bullet_act(var/obj/projectile/P)
	switch (P.proj_data.damage_type)
		if (D_KINETIC,D_PIERCING,D_SLASHING)
			health -= 20
		if (D_ENERGY)
			health -= 5
		if (D_BURNING)
			health -= 40
		if (D_RADIOACTIVE)
			health -= 2.5
	if(health < 0)
		qdel(src)
		return
	..()

/obj/xeno/wall/ex_act(severity)
	switch(severity)
		if (1.0)
			qdel(src)
		if (2.0)
			if (prob(50))
				qdel(src)
		if (3.0)
			if (prob(5))
				qdel(src)

/obj/xeno/wall/New()
	..()
	spawn(world.tick_lag*2)
		for(var/obj/xeno/wall/W in range(src,1))
			W.Autojoin(base_icon)