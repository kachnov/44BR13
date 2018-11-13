var/list/observers = list()

/mob/dead/target_observer
	invisibility = 101
	name = ""
	icon = null
	var/atom/target
	var/mob/corpse = null
	var/mob/dead/observer/my_ghost = null

	New(target)
		..()
		target = target
		loc = null

		observers += src

		set_eye(target)
		var/mob/living/M = target
		if (istype(M))
			M.observers += src
			if (client)
				M.updateOverlaysClient(client)
			for (var/hud/hud in M.huds)
				attach_hud(hud)

	// Observer Life() only runs for admin ghosts (Convair880).
	Life(controller/process/mobs/parent)
		if (..(parent))
			return TRUE
		if (client)
			antagonist_overlay_refresh(0, 0)
		return

	apply_camera(client/C)
		var/mob/living/M = target
		if (istype(M))
			M.apply_camera(C)
		else
			..(C)

	cancel_camera()
		set name = "Cancel Camera View"

		return stop_observing()

	verb
		stop_observing()
			set name = "Stop Observing"
			set category = "Special Verbs"

			if (!my_ghost)
				my_ghost = new(corpse)

				if (!corpse)
					my_ghost.name = name
					my_ghost.real_name = real_name

			if (corpse)
				corpse.ghost = my_ghost
				my_ghost.corpse = corpse

			my_ghost.delete_on_logout = my_ghost.delete_on_logout_reset

			if (client)
				removeOverlaysClient(client)
				client.mob = my_ghost

			if (mind)
				mind.transfer_to(my_ghost)

			var/ASLoc = observer_start.len ? pick(observer_start) : locate(1, 1, 1)
			if (target)
				var/turf/T = get_turf(target)
				if (T && (!isrestrictedz(T.z) || isrestrictedz(T.z) && (restricted_z_allowed(my_ghost, T) || my_ghost.client && my_ghost.client.holder)))
					my_ghost.set_loc(T)
				else
					if (ASLoc)
						my_ghost.set_loc(ASLoc)
					else
						my_ghost.z = 1
			else
				if (ASLoc)
					my_ghost.set_loc(ASLoc)
				else
					my_ghost.z = 1

			observers -= src
			qdel(src)
