
/obj/storage/closet/syndi
	name = "floor"
	desc = "Something weird about this thing."
	icon_state = "closedf"
	icon_closed = "closedf"
	density = 0
	soundproofing = 15

	close()
		var/turf/T = get_turf(src)
		if (T)
			icon = T.icon
			icon_closed = T.icon_state
			desc = T.desc + " It looks odd."
		else
			icon = 'icons/obj/large_storage.dmi'
			icon_closed = "closedf"
		..()
		return

	open()
		if (welded)
			return
		icon = 'icons/obj/large_storage.dmi'
		..()
		return

	CanPass(atom/movable/mover, turf/target, height=0, air_group=0)
		return TRUE

/obj/storage/closet/syndi/hidden
	anchored = 1
	New()
		..()
		var/turf/T = get_turf(loc)
		if (T)
			icon = T.icon
			icon_closed = T.icon_state
			icon_state = icon_closed
			name = T.name
		else
			icon = 'icons/obj/closet.dmi'
			icon_closed = "closedf"

