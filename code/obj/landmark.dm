
/obj/landmark
	name = "landmark"
	icon = 'icons/mob/screen1.dmi'
	icon_state = "x2"
	anchored = 1.0

	ex_act()
		return

/obj/landmark/cruiser_entrance

/obj/landmark/alterations
	name = "alterations"

/obj/landmark/miniworld
	name = "worldsetup"
	var/id = 0

/obj/landmark/miniworld/w1

/obj/landmark/miniworld/w2

/obj/landmark/miniworld/w3

/obj/landmark/miniworld/w4


/obj/landmark/New()

	..()
	tag = "landmark*[name]"
	invisibility = 101

	if (name == "shuttle")
		shuttle_z = z
		qdel(src)
/*
	if (name == "airtunnel_stop")
		airtunnel_stop = x

	if (name == "airtunnel_start")
		airtunnel_start = x

	if (name == "airtunnel_bottom")
		airtunnel_bottom = y
*/
	else if (name == "monkey")
		monkeystart += loc
		qdel(src)

	else if (name == "start")
		newplayer_start += loc
		qdel(src)

	else if (name == "wizard")
		wizardstart += loc
		qdel(src)

	else if (name == "predator")
		predstart += loc
		qdel(src)

	else if (name == "Syndicate-Spawn")
		syndicatestart += loc
		qdel(src)

	else if (name == "SR Syndicate-Spawn")
		syndicatestart += loc
		qdel(src)

	else if (name == "JoinLate")
		latejoin += loc
		qdel(src)

	else if (name == "Observer-Start")
		observer_start += loc
		qdel(src)

	else if (name == "shitty_bill")
		spawn (30)
			new /mob/living/carbon/human/biker(loc)
			qdel(src)

	else if (name == "father_jack")
		spawn (30)
			new /mob/living/carbon/human/fatherjack(loc)
			qdel(src)

	else if (name == "don_glab")
		spawn (30)
			new /mob/living/carbon/human/don_glab(loc)
			qdel(src)

	else if (name == "monkeyspawn_normal")
		spawn (60)
			new /mob/living/carbon/human/npc/monkey(loc)
			qdel(src)

	else if (name == "monkeyspawn_albert")
		spawn (60)
			new /mob/living/carbon/human/npc/monkey/albert(loc)
			qdel(src)

	else if (name == "monkeyspawn_rathen")
		spawn (60)
			new /mob/living/carbon/human/npc/monkey/mr_rathen(loc)
			qdel(src)

	else if (name == "monkeyspawn_mrmuggles")
		spawn (60)
			new /mob/living/carbon/human/npc/monkey/mr_muggles(loc)
			qdel(src)

	else if (name == "monkeyspawn_mrsmuggles")
		spawn (60)
			new /mob/living/carbon/human/npc/monkey/mrs_muggles(loc)
			qdel(src)

	else if (name == "monkeyspawn_syndicate")
		spawn (60)
			new /mob/living/carbon/human/npc/monkey/von_braun(loc)
			qdel(src)

	else if (name == "monkeyspawn_horse")
		spawn (60)
			new /mob/living/carbon/human/npc/monkey/horse(loc)
			qdel(src)

	else if (name == "monkeyspawn_krimpus")
		spawn (60)
			new /mob/living/carbon/human/npc/monkey/krimpus(loc)
			qdel(src)

	else if (name == "monkeyspawn_tanhony")
		spawn (60)
			new /mob/living/carbon/human/npc/monkey/tanhony(loc)
			qdel(src)

	else if (name == "Clown")
		clownstart += loc
		//dispose()

	//prisoners
	else if (name == "prisonwarp")
		prisonwarp += loc
		qdel(src)
	//else if (name == "mazewarp")
	//	mazewarp += loc
	else if (name == "tdome1")
		tdome1	+= loc
		
	else if (name == "tdome2")
		tdome2 += loc
	//not prisoners
	else if (name == "prisonsecuritywarp")
		prisonsecuritywarp += loc
		qdel(src)

	else if (name == "blobstart")
		blobstart += loc
		qdel(src)
		
	else if (name == "kudzustart")
		kudzustart += loc
		qdel(src)

	else if (name == "telesci")
		telesci += loc
		qdel(src)

	else if (name == "icefall")
		icefall += loc
		qdel(src)

	else if (name == "deepfall")
		deepfall += loc
		qdel(src)

	else if (name == "ancientfall")
		ancientfall += loc
		qdel(src)

	else if (name == "iceelefall")
		iceelefall += loc
		qdel(src)

	else if (name == "bioelefall")
		bioelefall += loc
		qdel(src)
		
	else if (name == "mutt-noclip")
		mutt_noclip_locations += loc

	return TRUE

var/global/list/job_start_locations = list()

/obj/landmark/start
	name = "start"
	icon = 'icons/mob/screen1.dmi'
	icon_state = "x"
	anchored = 1.0

	New()
		..()
		tag = "start*[name]"
		if (job_start_locations)
			if (!islist(job_start_locations[name]))
				job_start_locations[name] = list()
			job_start_locations[name] += get_turf(src)
		invisibility = 101
		return TRUE

/obj/landmark/start/latejoin
	name = "JoinLate"

/obj/landmark/tutorial_start
	name = "Tutorial Start Marker"

/obj/landmark/asteroid_spawn_blocker //Blocks the creation of an asteroid on this tile, as you would expect
	name = "asteroid blocker"
	icon_state = "x4"

/obj/landmark/magnet_center
	name = "magnet center"
	icon = 'icons/mob/screen1.dmi'
	icon_state = "x"
	anchored = 1.0

/obj/landmark/magnet_shield
	name = "magnet shield"
	icon = 'icons/mob/screen1.dmi'
	icon_state = "x"
	anchored = 1.0
