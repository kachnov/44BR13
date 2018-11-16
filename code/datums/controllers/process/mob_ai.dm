// handles critters
PROCESS(mob_ai)
	priority = PROCESS_PRIORITY_MOB_AI

/controller/process/mob_ai/setup()
	name = "Mob AI"
	schedule_interval = 1.6 SECONDS

/controller/process/mob_ai/doWork()
	for (var/mob/living/carbon/human/H in mobs)
		H.ai_process()
		scheck()

	/*var/currentTick = ticks
	for (var/obj/critter in critters)
		tick_counter = world.timeofday

		critter:process()

		tick_counter = world.timeofday - tick_counter
		if (critter && tick_counter > 0)
			detailed_count["[critter.type]"] += tick_counter

		scheck(currentTick)*/