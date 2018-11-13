/obj/atmos_field
	name = "atmospheric force field"
	desc = "Keeps gases in but lets metallic objects pass through. Contact with organic materials is discouraged."
	icon = 'icons/obj/stationobjs.dmi'
	icon_state = "atmos_field"
	layer = OBJ_LAYER+0.5

	New()
		..()
		update_nearby_tiles()

	disposing()
		..()
		update_nearby_tiles()

	CanPass(atom/movable/mover, turf/target)
		if (!mover)
			return FALSE // completely opaque to air
		return TRUE

	HasEntered(atom/A, turf/OldLoc)
		if (istype(A, /mob/living/carbon/human) && !locate(/obj/atmos_field, OldLoc)) // stepping around in the field while you're already inside it is fine
			var/mob/living/carbon/human/M = A
			if (prob(50))
				M.shock(src, 10000, "chest", 1, 1)
				M.lying = 1 // prevent them from running into the field multiple times
				M.throw_at(get_edge_target_turf(M, get_dir(M, OldLoc)), 25, 4)

	proc/update_nearby_tiles(need_rebuild)
		var/turf/simulated/source = loc
		if (istype(source))
			return source.update_nearby_tiles(need_rebuild)

		return TRUE

/obj/machinery/atmos_field_generator
	name = "atmospheric field generator"
	desc = "Generates a field designed to hold air in. Does not perform well under power failures."
	icon = 'icons/obj/stationobjs.dmi'
	icon_state = "atmos_field_gen_off"
	var/obj/machinery/atmos_field_generator/other
	var/list/obj/atmos_field/fields = list()
	layer = OBJ_LAYER+0.6

	New()
		..()
		updateicon()

	process()
		if (!other)
			var/checked = 0
			var/turf/T = get_step(src, dir)
			while (checked < 7 && !T.density)
				var/obj/machinery/atmos_field_generator/other = locate() in T
				if (other && other.dir == turn(dir, 180))
					other = other
					src.other.other = src
					create_field()
					updateicon()
					other.updateicon()
					return
				T = get_step(T, dir)
				checked++
		else
			use_power(250*fields.len)

	power_change()
		..()
		if (stat & NOPOWER && other)
			break_field()

	proc
		create_field()
			if (!other)
				return
			var/turf/target = get_turf(other)
			var/dir = get_dir(src, target)
			var/turf/T = get_turf(src)
			var/sanity = 0
			while (sanity < 10)
				var/obj/atmos_field/field = new(T)
				field.dir = dir
				fields += field
				if (T == target)
					break
				T = get_step(T, dir)
				sanity++

		break_field()
			other.fields.len = 0
			src.other.other = null
			other = null
			for (var/obj/field in fields)
				qdel(field)
			fields.len = 0
			updateicon()

		updateicon()
			if (stat & (NOPOWER|BROKEN))
				icon_state = "atmos_field_gen_off"
			else if (other)
				icon_state = "atmos_field_gen_on"
			else
				icon_state = "atmos_field_gen_fail"