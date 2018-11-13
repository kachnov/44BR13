/obj/effects/water
	name = "water"
	icon = 'icons/effects/effects.dmi'
	icon_state = "extinguish"
	var/life = 15.0
	flags = TABLEPASS
	mouse_opacity = 0

/obj/effects/water/pooled(var/poolname)
	 life = initial(life)
	 ..()

/obj/effects/water/Move(turf/newloc)
	//var/turf/T = loc
	//if (istype(T, /turf))
	//	T.firelevel = 0 //TODO: FIX
	if (--life < 1)
		//SN src = null
		if (!disposed)
			pool(src)
		return FALSE
	if (newloc.density)
		if (!disposed)
			pool(src)
		return FALSE
	.=..()

/obj/effects/water/proc/spray_at(var/turf/target, var/reagents/R)
	if (!target || !R)
		pool(src)
		return

	reagents = R
	R.my_atom = src
	reagents.trans_to(src,1)
	var/turf/T
	for (var/b=0, b<5, b++)
		T = get_turf(src)
		step_towards(src,target)
		if (!reagents)
			break
		reagents.reaction(T)
		for (var/atom/atm in T)
			reagents.reaction(atm)
		if (loc == target)
			break
		sleep(2)
		if (disposed)
			break

	if (!disposed)
		pool(src)