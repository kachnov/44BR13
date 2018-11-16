#define PIXEL_OFFSETS list("1" = list(0,-32),"2" = list(0,32),"4" = list(-32,0),"8" = list(32,0))

/obj/mutt/weeds/proc/Special_Autojoin(var/typeG)
	var/list/junctions = list(NORTH,SOUTH,EAST,WEST)
	for(var/obj/mutt/weeds/W in range(src,1))
		if(W.type in typesof(typeG))
			if(get_dir(src,W) in junctions)
				junctions -= get_dir(src,W)
	return junctions

/obj/mutt/weeds
	name = "weeds"
	desc = "weird shit-colored weeds"
	icon_state = "weeds"
	icon = 'icons/mob/xeno/xeno.dmi'

	layer = TURF_LAYER+0.125
	anchored = 1
	density = 0

	color = "#593001"
	
	var/original = TRUE 
	var/spawned = 0
	
	var/static/list/cuts = list(/obj/item/axe, /obj/item/circular_saw, 
		/obj/item/kitchen/utensil/knife, /obj/item/scalpel, /obj/item/screwdriver, 
		/obj/item/raw_material/shard, /obj/item/sword, /obj/item/saw, /obj/item/weldingtool,
		/obj/item/wirecutters)

/obj/mutt/weeds/New()
	..()
	if (istype(loc, /turf/space))
		qdel(src)
		return
	spawn(world.tick_lag*2)
		for(var/obj/mutt/weeds/W in range(src,1))
			W.do_Autojoin()
	REPO.xenomorph_weeds += src
		
/obj/mutt/weeds/Del()
	..()
	REPO.xenomorph_weeds -= src

/obj/mutt/weeds/proc/do_Autojoin()
	overlays = list()
	for(var/i in Special_Autojoin(type))
		var/image/G = new()
		G.layer = TURF_LAYER+0.125
		G.icon = 'icons/mob/xeno/xeno.dmi'
		G.icon_state = "weeds_side_[i]"
		G.pixel_x = (PIXEL_OFFSETS["[i]"])[1]
		G.pixel_y = (PIXEL_OFFSETS["[i]"])[2]
		overlays += G


/obj/mutt/weeds/attackby(obj/item/W as obj, mob/user as mob)
	if (W && usr && user)
		if (is_type_in_list(W, cuts))
			visible_message("<span style = \"color: red\">[user] cuts away the weeds.</span>")
			qdel(src)
	..()

/obj/mutt/weeds/proc/Life()
	if (original && spawned < 6)
		var/Vspread = null
		if (prob(50)) 
			Vspread = locate(x + pick(-1,1),y,z)
		else 
			Vspread = locate(x,y + pick(-1,1),z)

		var/grow = istype(Vspread, /turf/simulated/floor)
		for (var/obj/O in Vspread)
			if (istype(O, /obj/window) || istype(O, /obj/forcefield) || istype(O, /obj/blob) || istype(O, /obj/spacevine) || istype(O, /obj/mutt/weeds)) 
				grow = FALSE
			else if (istype(O, /obj/machinery/door))
				var/obj/machinery/door/D = O
				if (!D.p_open && prob(70))
					D.open()
					D.operating = -1
				else
					grow = FALSE
					
		if (grow)
			var/obj/mutt/weeds/W = new /obj/mutt/weeds(Vspread)
			W.original = FALSE
			
		++spawned

/obj/mutt/weeds/ex_act(severity)
	switch(severity)
		if (1.0)
			qdel(src)
		if (2.0)
			if (prob(50))
				qdel(src)
		if (3.0)
			if (prob(5))
				qdel(src)

#undef PIXEL_OFFSETS