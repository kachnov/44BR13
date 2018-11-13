/obj/item/ctf_flag
	name = "Flag"
	desc = "Its a flag"
	w_class = 5
	icon = 'icons/misc/flags.dmi'
	icon_state = "flag_neutral"
	item_state = "paper"

/obj/item/ctf_flag/red
	name = "The Red Flag"
	desc = "Catch dat fukken flag"
	icon_state = "flag_red"

/obj/item/ctf_flag/green
	name = "The Green Flag"
	desc = "Catch dat fukken flag"
	icon_state = "flag_green"

/obj/item/ctf_flag/New()
	..()
	spawn (200)
		process()
	return

/obj/item/ctf_flag/process()
	if (istype(src, /obj/item/ctf_flag/green))
		var/obj/L = locate("landmark*Green-Flag")
		if (locate("landmark*Green-Flag", src))
			spawn (200)
				process()
			return
		else if (!check_if_equipped() && L)
			new /obj/item/ctf_flag/green(L.loc)
			qdel(src)
	if (istype(src, /obj/item/ctf_flag/red))
		var/obj/L = locate("landmark*Red-Flag")
		if (locate("landmark*Red-Flag", src))
			spawn (200)
				process()
			return
		else if (!check_if_equipped() && L)
			new /obj/item/ctf_flag/red(L.loc)
			qdel(src)
	return

/obj/item/ctf_flag/proc/check_if_equipped()
	var/equipped = 0
	for (var/mob/M in mobs)
		if (M &&!M.stat)
			var/list/L = M.get_contents()
			if (src in L)
				equipped = 1
				break
	return equipped

/obj/machinery/red_injector
	name = "Red Team Flag Injector"
	desc = "Insert flag here"
	anchored = 1
	density = 1
	var/score = 0
	var/operating = 0
	icon = 'icons/misc/flags.dmi'
	icon_state = "red_injector"
/*
/obj/machinery/red_injector/ex_act(severity)
	return

/obj/machinery/red_injector/attackby(var/obj/item/ctf_flag/C, mob/user)
	if (operating)
		boutput(user, "Cannot put a flag in right now")
		return
	operating = 1
	if (istype(C, /obj/item/ctf_flag/green))
		if (locate("landmark*Red-Flag", /obj/item/ctf_flag/red))
			score++
			boutput(world, "<strong>[user.real_name] has scored for the red team!</strong>")
			if (ticker && ticker.mode && istype(ticker.mode, /game_mode/ctf))
				ticker.red_score++
				var/obj/L = locate("landmark*Green-Flag")
				if (L)
					qdel(C)
					new /obj/item/ctf_flag/green(L.loc)
				else
					boutput(world, "No green flag spawn point detected")
				if (score >= 15)
					boutput(world, "<FONT size = 3><strong>The Red Team has won!</strong></FONT>")
					boutput(world, "<strong>They have scored [score] times with the flag!</strong>")
					sleep(300)
					world.Reboot()
		else
			boutput(user, "<span style=\"color:red\">You need to have your flag in the beginning position!</span>")
	else if (istype(C, /obj/item/ctf_flag/red))
		boutput(world, "<strong>[user.real_name] has tried to score with their own flag! Idiot!</strong>")
	operating = 0
	return
*/
/obj/machinery/green_injector
	name = "Green Team Flag Injector"
	desc = "Insert flag here"
	anchored = 1
	density = 1
	var/operating = 0
	var/score = 0
	icon = 'icons/misc/flags.dmi'
	icon_state = "green_injector"

/obj/machinery/green_injector/ex_act(severity)
	return
/*
/obj/machinery/green_injector/attackby(var/obj/item/ctf_flag/C, mob/user)
	if (operating)
		boutput(user, "Cannot put a flag in right now")
		return
	operating = 1
	if (istype(C, /obj/item/ctf_flag/red))
		if (locate("landmark*Green-Flag", /obj/item/ctf_flag/green))
			score++
			boutput(world, "<strong>[user.real_name] has scored for the green team!</strong>")
			if (ticker && ticker.mode && istype(ticker.mode, /game_mode/ctf))
				ticker.green_score++
				var/obj/L = locate("landmark*Red-Flag")
				if (L)
					qdel(C)
					new /obj/item/ctf_flag/red(L.loc)
				else
					boutput(world, "No red flag spawn point detected")
				if (score >= 15)
					boutput(world, "<FONT size = 3><strong>The Green Team has won!</strong></FONT>")
					boutput(world, "<strong>They have scored [score] times with the flag!</strong>")
					sleep(300)
					world.Reboot()
		else
			boutput(user, "<span style=\"color:red\">You need to have your flag in the beginning position!</span>")
	else if (istype(C, /obj/item/ctf_flag/green))
		boutput(world, "<strong>[user.real_name] has tried to score with their own flag! Idiot!</strong>")
	operating = 0
	return
*/