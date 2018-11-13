/*/obj/silo_phantom
	color = "#404040"

/atom
	var/list/obj/silo_phantom/phantoms

	proc
		create_phantoms()
			phantom = new
			var/image/I = image(src)
			I.layer = layer * 0.01
			phantom.overlays += I

/turf/simulated/floor/phantom_test
	RL_Ignore = 1

	New()
		..()
		create_phantom()
		phantom.loc = locate(x+16, y, z)

	Entered(atom/movable/A, turf/OldLoc)
		..()
		if (istype(A, /obj/overlay/tile_effect))
			return
		if (!A.phantom)
			A.create_phantom()
		A.phantom.loc = locate(x+16, y, z)
		A.phantom.dir = A.dir

/turf/simulated/floor/phantom_test2
	RL_Ignore = 1
	icon = null*/

/obj/grille/catwalk/dubious
	name = "rusty catwalk"
	desc = "This one looks even less safe than usual."
	var/collapsing = 0

	New()
		health = rand(5, 10)
		update_icon()

	HasEntered(atom/movable/A)
		if (ismob(A))
			collapsing++
			spawn (10)
				collapse_timer()
				if (collapsing)
					playsound(loc, 'sound/ambience/creaking_metal.ogg', 25, 1)

	proc/collapse_timer()
		var/still_collapsing = 0
		for (var/mob/M in loc)
			collapsing++
			still_collapsing = 1
		if (!still_collapsing)
			collapsing--

		if (collapsing >= 5)
			playsound(loc, 'sound/effects/grillehit.ogg', 50, 1)
			for (var/mob/M in AIviewers(src, null))
				boutput(M, "[src] collapses!")
			qdel(src)

		if (collapsing)
			spawn (10)
				collapse_timer()
