/random_event/minor/artifact
	name = "Artifact Spawn"

	event_effect()
		..()
		if (blobstart.len < 1)
			return
		var/turf/T = pick(blobstart)
		Artifact_spawn (T)
		T.visible_message("<span style=\"color:red\"><strong>An artifact suddenly warps into existance!</strong></span>")
		playsound(T,"sound/effects/teleport.ogg",50,1)

		var/obj/decal/teleport_swirl/swirl = unpool(/obj/decal/teleport_swirl)
		swirl.set_loc(T)
		spawn (15)
			pool(swirl)
		return