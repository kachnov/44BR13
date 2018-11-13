/mob/living/carbon/wall
	name = "living wall"
	real_name = "living wall"
	icon = 'icons/mob/mob.dmi'
	icon_state = "livingwall"
	a_intent = "disarm" // just so they don't swap with help intent users
	health = INFINITY
	anchored = 1
	density = 1
	nodamage = 1
	opacity = 1

	//Life(controller/process/mobs/parent)
		//..(parent)
		//return

	examine()
		set src in view()

		boutput(usr, "<span style=\"color:blue\">*---------*</span>")
		boutput(usr, "<span style=\"color:blue\">This is a [bicon(src)] <strong>[name]</strong>!</span>")
		if (prob(50) && ishuman(usr) && usr.bioHolder.HasEffect("clumsy"))
			boutput(usr, "<span style=\"color:red\">You can't help but laugh at it.</span>")
			usr.emote("laugh")
		else
			boutput(usr, "<span style=\"color:red\">It looks pretty disturbing.</span>")

	say_understands(var/other)
		if (ishuman(other) || isrobot(other) || isAI(other))
			return TRUE
		return ..()

	attack_hand(mob/user as mob)
		boutput(user, "<span style=\"color:blue\">You push the [name] but nothing happens!</span>")
		playsound(loc, "sound/weapons/Genhit.ogg", 25, 1)
		add_fingerprint(user)
		return

	ex_act(severity)
		..() // Logs.
		switch(severity)
			if (1.0)
				gib(1)
				return
			if (2.0)
				if (prob(25))
					gib(1)
			else
		return

	attackby(obj/item/W as obj, mob/user as mob)
		if (istype(W, /obj/item/weldingtool) && W:welding)
			gib(1)
		else
			..()

/mob/living/carbon/wall/meatcube
	name = "meat cube"
	real_name = "meat cube"
	icon_state = "meatcube-squish"
	opacity = 0
	var/life_timer = 10

	Life(controller/process/mobs/parent)
		if (..(parent))
			return TRUE

		if (client)
			antagonist_overlay_refresh(0, 0)

		if (istype(loc, /obj/machinery/deep_fryer))
			return

		if (prob(30))
			visible_message("<span style=\"color:red\"><strong>[src] [pick("quivers","pulsates","squirms","flollops","shudders","twitches","willomies")] [pick("sadly","disgustingly","horrifically","unpleasantly","disturbingly","worryingly","pathetically","floopily")]!</strong></span>")

		if (life_timer-- > 0)
			return

		for (var/i = 3, i > 0, i--)
			var/obj/item/reagent_containers/food/snacks/ingredient/meat/mysterymeat/meat = new /obj/item/reagent_containers/food/snacks/ingredient/meat/mysterymeat(loc)
			meat.name = "cube steak"
			meat.desc = "Grody."

		playsound(loc, "sound/effects/splat.ogg", 75, 1)
		visible_message("<span style=\"color:red\"><strong>The meat cube pops!</strong></span>")
		gib(1)
		return

	say_quote(var/text)
		if (emote_allowed)
			if (!(client && client.holder))
				emote_allowed = 0
			/*
			if (gender == MALE) playsound(get_turf(src), "sound/voice/male_scream.ogg", 100, 0, 0, 0.91)
			else playsound(get_turf(src), "sound/voice/female_scream.ogg", 100, 0, 0, 0.9)
			*/

			if (narrator_mode)
				playsound(loc, 'sound/vox/scream.ogg', 80, 0, 0, get_age_pitch())
			else
				if (gender == MALE) playsound(get_turf(src), 'sound/voice/male_scream.ogg', 80, 0, 0, get_age_pitch())
				else playsound(get_turf(src), 'sound/voice/female_scream.ogg', 80, 0, 0, get_age_pitch())

			spawn (50)
				emote_allowed = 1
			return "screams!"
		else
			return pick("gurgles.","shivers.","twitches.","shakes.","squirms.", "cries.")

	verb/suicide()
		set hidden = 1

		if (stat == 2)
			boutput(src, "You're already dead!")
			return

		if (suiciding)
			boutput(src, "You're already committing suicide! Be patient!")
			return

		suiciding = 1

		var/confirm = alert("Are you sure you want to commit suicide?", "Confirm Suicide", "Yes", "No")

		if (confirm == "Yes")
			logTheThing("combat", src, null, "commits suicide")

			var/obj/machinery/deep_fryer/fryer = locate() in orange(1, src)
			if (istype(fryer) && fryer.suicide(src))
				unlock_medal("Damned", 1)
				suiciding = 0
				return
			else
				visible_message("<span style=\"color:red\"><strong>The meat cube pops!</strong></span>")
				gib(1)
				unlock_medal("Damned", 1)
				suiciding = 0
				return

/mob/living/carbon/wall/meatcube/krampus
	name = "Krampus 2.0"
	life_timer = INFINITY
	icon_state = "krampus2-squish"

	New()
		..()
		real_name = pick("Krampus", "Krampus 2.0", "The Krampmeister", "The Krampster") //For deadchat
		spawn (20) //I do not know where the hell you get a bioholder from =I
			if (bioHolder) bioHolder.age = 110


	attackby(obj/item/W as obj, mob/user as mob)
		user.visible_message("<span class='combat'><strong>[user] pokes [src] with \the [W]!</strong></span>") //No weldergibs. Krampus is truly a fiend.