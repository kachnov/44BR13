/obj/effects/expl_particles
	name = "fire"
	icon = 'icons/effects/effects.dmi'
	icon_state = "explosion_particle"
	opacity = 0
	anchored = 1
	mouse_opacity = 0

/obj/effects/expl_particles/New()
	..()
	spawn (15)
		dispose()
	return

/obj/effects/expl_particles/Move()
	..()
	return

/effects/system/expl_particles
	var/number = 10
	var/turf/location
	var/total_particles = 0

/effects/system/expl_particles/proc/set_up(n = 10, loca)
	number = n
	if (istype(loca, /turf)) location = loca
	else location = get_turf(loca)

/effects/system/expl_particles/proc/start()
	var/i = 0
	for (i=0, i<number, i++)
		spawn (0)
			var/obj/effects/expl_particles/expl = new /obj/effects/expl_particles(location)
			var/direct = pick(alldirs)
			for (i=0, i<pick(1;25,2;55,3,4;200), i++)
				sleep(1)
				step(expl,direct)

/obj/effects/explosion
	name = "fire"
	icon = 'icons/effects/hugeexplosion2.dmi'
	icon_state = "explosion"
	opacity = 0
	anchored = 1
	mouse_opacity = 0
	pixel_x = -24
	pixel_y = -24
	layer = NOLIGHT_EFFECTS_LAYER_BASE

	dangerous // cogwerks testing thing, use with caution. a spreading infestation of this is FUCKING AWESOME to watch

		New()
			..()
			spawn (rand(0,1))
				explosion(src, loc, -1,0,1,1)
			return

/obj/effects/explosion/New()
	..()
	spawn (30)
		dispose()
	return

/effects/system/explosion
	var/turf/location
	var/atom/source

/effects/system/explosion/proc/set_up(loca)
	if (istype(loca, /turf)) location = loca
	else location = get_turf(loca)
	source = loca	

/effects/system/explosion/proc/start()
	var/obj/effects/explosion/E = new/obj/effects/explosion( location )
	E.fingerprintslast = source.fingerprintslast
	var/effects/system/expl_particles/P = new/effects/system/expl_particles()
	P.set_up(10,location)
	P.start()
	spawn (30)
		var/effects/system/harmless_smoke_spread/S = new/effects/system/harmless_smoke_spread()
		S.set_up(3,0,location,null)
		S.start()