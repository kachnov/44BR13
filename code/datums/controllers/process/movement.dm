REPO_LIST(movement_queue, list())

PROCESS(movement)
	is_high_priority = TRUE
	var/list/clients = null
	var/list/footsteps = null

/controller/process/movement/setup()
	name = "Client Movement"
	schedule_interval = world.tick_lag
	clients = REPO.movement_queue

	// local lists are superior to REPO lists ok?
	footsteps = list(

		"carpet" = list(
			'sound/effects/footsteps/carpet1.ogg',
			'sound/effects/footsteps/carpet2.ogg',
			'sound/effects/footsteps/carpet3.ogg',
			'sound/effects/footsteps/carpet4.ogg',
			'sound/effects/footsteps/carpet5.ogg'
		),

		"wood" = list(
			'sound/effects/footsteps/wood1.ogg',
			'sound/effects/footsteps/wood2.ogg',
			'sound/effects/footsteps/wood3.ogg',
			'sound/effects/footsteps/wood4.ogg',
			'sound/effects/footsteps/wood5.ogg'
		),

		"plating" = list(
			'sound/effects/footsteps/plating1.ogg',
			'sound/effects/footsteps/plating2.ogg',
			'sound/effects/footsteps/plating3.ogg',
			'sound/effects/footsteps/plating4.ogg',
			'sound/effects/footsteps/plating5.ogg'
		),

		"floor" = list(
			'sound/effects/footsteps/floor1.ogg',
			'sound/effects/footsteps/floor2.ogg',
			'sound/effects/footsteps/floor3.ogg',
			'sound/effects/footsteps/floor4.ogg',
			'sound/effects/footsteps/floor5.ogg'
		),

		"grass" = list(
			'sound/effects/footsteps/grass1.ogg',
			'sound/effects/footsteps/grass2.ogg',
			'sound/effects/footsteps/grass3.ogg',
			'sound/effects/footsteps/grass4.ogg'
		)
	)

/controller/process/movement/doWork()
	for (var/client in clients)
		triggerMove(client)

/controller/process/movement/proc/triggerMove(var/client/C)
	set waitfor = FALSE
	if (C && C.mob && C.moving_in_dir)
		var/turf/target = get_step(C.mob, C.moving_in_dir)
		if (checkTurf(target, C))
			C.Move(target, C.moving_in_dir)
			if (ishuman(C.mob) && C.mob.loc == target)
				var/mob/living/carbon/human/H = C.mob
				makeWaddle(H)
				doMovementSound(H)

/controller/process/movement/proc/checkTurf(var/turf/T, var/client/C)

	// turf doesn't exist 
	if (!istype(T))
		return FALSE

	// muh grace walls (extra () because fuck BYOND)
	else if ((locate(/obj/chair_path_helper/wall) in T) && PSPchairs && !PSPchairs.launched)
		boutput(C, "<span style = \"color:red\">You cannot move there until the lawnmowers have been sent by the Jews.</span>")
		return FALSE

	// all good
	return TRUE

/controller/process/movement/proc/getMatrixFromPool(angle = 0)
	var/textangle = num2text(angle)
	var/static/matrices = list()
	if (!matrices[textangle])
		matrices[textangle] = angle ? turn(matrix(), angle) : matrix()
	return matrices[textangle]

#define WADDLE_TIME 0.20 SECONDS
/controller/process/movement/proc/makeWaddle(var/mob/living/carbon/human/H)
	set waitfor = FALSE
	var/static/list/animation_locked = list()
	if (!animation_locked[H])
		animation_locked[H] = TRUE
		animate(H, pixel_z = 6, time = 0 SECONDS)
		animate(pixel_z = 0, transform = getMatrixFromPool(nextWaddle(H)), time = WADDLE_TIME)
		animate(pixel_z = 0, transform = getMatrixFromPool(0), time = 0 SECONDS)
		sleep(WADDLE_TIME)
		animation_locked[H] = FALSE
#undef WADDLE_TIME

/controller/process/movement/proc/nextWaddle(var/mob/living/carbon/human/H)
	var/static/waddles = list()
	if (!waddles[H])
		waddles[H] = -16
	else
		waddles[H] = next_in_list(waddles[H], list(-16, 16))
	return waddles[H]

/controller/process/movement/proc/doMovementSound(var/mob/living/carbon/human/H)

	var/static/list/steps = list()
	
	if (H.m_intent == "walk" || isnull(steps[H]) || !(steps[H] % 2))

		var/turf/T = get_turf(H)
		var/sound = null

		if (T)
			if (istype(T, /turf/simulated/floor/carpet))
				sound = pick(footsteps["carpet"])
			else if (istype(T, /turf/simulated/floor/wood))
				sound = pick(footsteps["wood"])
			else if (istype(T, /turf/simulated/floor/plating))
				sound = pick(footsteps["plating"])
			else if (istype(T, /turf/simulated/floor))
				sound = pick(footsteps["floor"])
			else if (istype(T, /turf/simulated/grass))
				sound = pick(footsteps["grass"])
			else // /turf/simulated/bar
				sound = pick(footsteps["floor"])

		if (sound)
			playsound(T, sound, 100, 1)

		if (isnull(steps[H]))
			steps[H] = 0

	++steps[H]