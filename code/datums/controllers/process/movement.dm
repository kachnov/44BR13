REPO_LIST(movement_queue, list())

PROCESS(movement)
	is_high_priority = TRUE
	var/list/clients = null

/controller/process/movement/setup()
	name = "Client Movement"
	schedule_interval = world.tick_lag
	clients = REPO.movement_queue

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

/controller/process/movement/proc/checkTurf(var/turf/T, var/client/C)

	// turf doesn't exist 
	if (!istype(T))
		return FALSE

	// muh grace walls (extra () because fuck BYOND)
	else if ((locate(/obj/chair_path_helper/wall) in T) && !PSPchairs.launched)
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