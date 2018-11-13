// by request

/obj/machinery/bot/duckbot
	name = "Amusing Duck"
	desc = "Bump'n go action! Ages 3 and up."
	icon = 'icons/obj/aibots.dmi'
	icon_state = "duckbot"
	layer = 5.0 //TODO LAYER
	density = 0
	anchored = 0
	on = 1 // ACTION
	health = 5
	var/eggs = 0
	no_camera = 1

/obj/machinery/bot/duckbot/proc/quack(var/message)
	if (!on || !message || muted)
		return
	visible_message("<span class='game say'><span class='name'>[src]</span> honks, \"[message]\"</span>")
	return

/obj/machinery/bot/duckbot/proc/wakka_wakka()
		var/turf/moveto = locate(x + rand(-1,1),y + rand(-1, 1),z)
		if (isturf(moveto) && !moveto.density) step_towards(src, moveto)

/obj/machinery/bot/duckbot/process()
	if (prob(10) && on == 1)
		spawn (0)
			var/message = pick("wacka", "quack","quacky","gaggle")
			quack(message)
			wakka_wakka()
			if (prob (3) && eggs >= 1)
				var/obj/item/a_gift/easter/duck/E = new /obj/item/a_gift/easter/duck
				E.name = "duck egg"
				eggs--
				E.set_loc(get_turf(src))
				playsound(loc, "sound/misc/eggdrop.ogg", 50, 0)
	if (emagged == 1)
		spawn (0)
			var/message = pick("QUacK", "WHaCKA", "quURK", "bzzACK", "quock", "queck", "WOcka", "wacKY","GOggEL","gugel","goEGL","GeGGal")
			quack(message)
			wakka_wakka()
			if (prob (10) && eggs >= 1)
				var/obj/item/a_gift/easter/duck/E = new /obj/item/a_gift/easter/duck
				E.name = "duck egg"
				eggs--
				E.set_loc(get_turf(src))
				playsound(loc, "sound/misc/eggdrop.ogg", 50, 1)

/obj/machinery/bot/duckbot/Topic(href, href_list)
	if (!(usr in range(1)))
		return
	if (href_list["on"])
		on = !on
	attack_hand(usr)

/obj/machinery/bot/duckbot/attack_hand(mob/user as mob)
	var/dat
	dat += "<TT><strong>AMUSING DUCK</strong></TT><BR>"
	dat += "<strong>toy series with strong sense for playing</strong><BR><BR>"
	dat += "LAY EGG IS: <A href='?src=\ref[src];on=1'>[on ? "TRUE!!!" : "NOT TRUE!!!"]</A><BR><BR>"
	dat += "AS THE DUCK ADVANCING,FLICKING THE PLUMAGE AND YAWNING THE MOUTH GO WITH MUSIC & LIGHT.<BR>"
	dat += "THE DUCK STOP,IT SWAYING TAIL THEN THE DUCK LAY AN EGG AS OPEN IT'S BUTTOCKS,<BR>GO WITH THE DUCK'S CALL"

	user << browse("<HEAD><TITLE>Amusing Duck</TITLE></HEAD>[dat]", "window=ducky")
	onclose(user, "ducky")
	return
/obj/machinery/bot/duckbot/emag_act(var/mob/user, var/obj/item/card/emag/E)
	if (!emagged)
		if (user)
			boutput(user, "<span style=\"color:red\">You short out the horn on [src].</span>")
		spawn (0)
			for (var/mob/O in hearers(src, null))
				O.show_message("<span style=\"color:red\"><strong>[src] quacks loudly!</strong></span>", 1)
				playsound(loc, "sound/misc/amusingduck.ogg", 50, 1)
				eggs = rand(3,9)
		emagged = 1
		return TRUE
	return FALSE

/obj/machinery/bot/duckbot/demag(var/mob/user)
	if (!emagged)
		return FALSE
	if (user)
		user.show_text("You repair [src]'s horn. Thank God.", "blue")
	emagged = 0
	return TRUE

/obj/machinery/bot/duckbot/attackby(obj/item/W as obj, mob/user as mob)
	if (istype(W, /obj/item/card/emag))
		emag_act(user, W)
	else
		visible_message("<span style=\"color:red\">[user] hits [src] with [W]!</span>")
		switch(W.damtype)
			if ("fire")
				health -= W.force * 0.5
			if ("brute")
				health -= W.force * 0.5
			else
		if (health <= 0)
			explode()

/obj/machinery/bot/duckbot/gib()
	return explode()

/obj/machinery/bot/duckbot/explode()
	on = 0
	for (var/mob/O in hearers(src, null))
		O.show_message("<span style=\"color:red\"><strong>[src] blows apart!</strong></span>", 1)
	var/effects/system/spark_spread/s = unpool(/effects/system/spark_spread)
	s.set_up(3, 1, src)
	s.start()
	qdel(src)
	return
