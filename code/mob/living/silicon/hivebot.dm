/mob/living/silicon/hivebot
	name = "Robot"
	voice_name = "synthesized voice"
	icon = 'icons/mob/hivebot.dmi'
	icon_state = "vegas"
	health = 60
	max_health = 60
	var/self_destruct = 0
	var/beebot = 0
	robot_talk_understand = 2

//HUD
	var/obj/screen/hands = null
	var/obj/screen/cells = null
	var/obj/screen/inv1 = null
	var/obj/screen/inv2 = null
	var/obj/screen/inv3 = null

//3 Modules can be activated at any one time.
	var/obj/item/robot_module/module = null
	var/module_active = null
	var/list/module_states = list(null,null,null)

	var/obj/item/device/radio/radio = null

	req_access = list(access_robotics)
	var/obj/item/cell/cell = null
	//var/energy = 4000
	//var/energy_max = 4000
	var/jetpack = 0

	shell = 1

	sound_fart = 'sound/misc/poo2_robot.ogg'

	var/bruteloss = 0
	var/fireloss = 0

/mob/living/silicon/hivebot/TakeDamage(zone, brute, burn)
	bruteloss += brute
	fireloss += burn

/mob/living/silicon/hivebot/HealDamage(zone, brute, burn)
	bruteloss -= brute
	fireloss -= burn
	bruteloss = max(0, bruteloss)
	fireloss = max(0, fireloss)

/mob/living/silicon/hivebot/get_brute_damage()
	return bruteloss

/mob/living/silicon/hivebot/get_burn_damage()
	return fireloss

/mob/living/silicon/hivebot/eyebot
	name = "Eyebot"
	icon_state = "eyebot"
	jetpack = 1
	health = 40
	self_destruct = 1

	New()
		..()
		bioHolder = new/bioHolder( src )
		spawn (5)
			if (module)
				qdel(module)
			pick_module()
			var/ion_trail = new /effects/system/ion_trail_follow()
			ion_trail:set_up(src)

			//ew
			if (!(src in available_ai_shells))
				available_ai_shells += src

		return

	pick_module()
		if (module)
			return

		if (!ticker)
			module = new /obj/item/robot_module( src )
			return
		if (!ticker.mode)
			module = new /obj/item/robot_module( src )
			return
		if (ticker.mode && istype(ticker.mode, /game_mode/construction))
			module = new /obj/item/robot_module/construction_ai( src )
		else
			module = new /obj/item/robot_module( src )

	movement_delay()
		return -1

	updateicon() // Haine wandered in here and just junked up this code with bees.  I'm so sorry it's so ugly aaaa
		overlays = null

		if (stat == 0)
			if (client)
				if (pixel_y)
					if (beebot == 1)
						icon_state = "eyebot-bee"
					else
						icon_state = "[initial(icon_state)]"
				else
					spawn (0)
						while (pixel_y < 10)
							pixel_y++
							sleep(1)
						if (beebot == 1)
							icon_state = "eyebot-bee"
						else
							icon_state = "[initial(icon_state)]"
					return
			else
				if (beebot == 1)
					icon_state = "eyebot-bee-logout"
				else
					icon_state = "[initial(icon_state)]-logout"
				pixel_y = 0
		else
			if (beebot == 1)
				icon_state = "eyebot-bee-dead"
			else
				icon_state = "[initial(icon_state)]-dead"
			pixel_y = 0
		return

	show_laws()
		var/mob/living/silicon/ai/aiMainframe = mainframe
		if (istype(aiMainframe))
			aiMainframe.show_laws(0, src)
		else
			ticker.centralized_ai_laws.show_laws(src)

		return

	ghostize()
		if (mainframe)
			mainframe.return_to(src)
		else
			return ..()

	handle_regular_hud_updates()
		..()
		if (!ticker)
			return
		if (!ticker.mode)
			return
		if (ticker.mode && istype(ticker.mode, /game_mode/construction))
			see_invisible = 9

/mob/living/silicon/hivebot/drop_item_v()
	return

/mob/living/silicon/hivebot/death(gibbed)
	if (mainframe)
		logTheThing("combat", src, null, "'s AI shell was destroyed at [log_loc(src)].") // Brought in line with carbon mobs (Convair880).
		mainframe.return_to(src)
	stat = 2
	canmove = 0

	vision.set_color_mod("#ffffff") // reset any blindness
	sight |= SEE_TURFS
	sight |= SEE_MOBS
	sight |= SEE_OBJS

	see_in_dark = SEE_DARK_FULL
	see_invisible = 2
	updateicon()
/*
	if (client)
		spawn (0)
			var/key = ckey
			recently_dead += key
			spawn (recently_time) recently_dead -= key
*/
	var/tod = time2text(world.realtime,"hh:mm:ss") //weasellos time of death patch
	store_memory("Time of death: [tod]", 0)

	return ..(gibbed)

/mob/living/silicon/hivebot/emote(var/act, var/voluntary = 0)
	var/param = null
	if (findtext(act, " ", 1, null))
		var/t1 = findtext(act, " ", 1, null)
		param = copytext(act, t1 + 1, length(act) + 1)
		act = copytext(act, 1, t1)
	var/m_type = 1
	var/message = null

	switch(lowertext(act))

		/*if ("shit")
			new /obj/item/rods/(loc)
			playsound(loc, "sound/misc/poo2_robot.ogg", 50, 1)
			message = "<strong>[src]</strong> shits on the floor."
			m_type = 1*/

		if ("help")
			show_text("To use emotes, simply enter \"*(emote)\" as the entire content of a say message. Certain emotes can be targeted at other characters - to do this, enter \"*emote (name of character)\" without the brackets.")
			show_text("For a list of all emotes, use *list. For a list of basic emotes, use *listbasic. For a list of emotes that can be targeted, use *listtarget.")

		if ("list")
			show_text("Basic emotes:")
			show_text("clap, flap, aflap, twitch, twitch_s, scream, birdwell, fart, flip, custom, customv, customh")
			show_text("Targetable emotes:")
			show_text("salute, bow, hug, wave, glare, stare, look, leer, nod, point")

		if ("listbasic")
			show_text("clap, flap, aflap, twitch, twitch_s, scream, birdwell, fart, flip, custom, customv, customh")

		if ("listtarget")
			show_text("salute, bow, hug, wave, glare, stare, look, leer, nod, point")

		if ("salute","bow","hug","wave","glare","stare","look","leer","nod")
			// visible targeted emotes
			if (!restrained())
				var/M = null
				if (param)
					for (var/mob/A in view(null, null))
						if (ckey(param) == ckey(A.name))
							M = A
							break
				if (!M)
					param = null

				act = lowertext(act)
				if (param)
					switch(act)
						if ("bow","wave","nod")
							message = "<strong>[src]</strong> [act]s to [param]."
						if ("glare","stare","look","leer")
							message = "<strong>[src]</strong> [act]s at [param]."
						else
							message = "<strong>[src]</strong> [act]s [param]."
				else
					switch(act)
						if ("hug")
							message = "<strong>[src]</strong> [act]s itself."
						else
							message = "<strong>[src]</strong> [act]s."
			else
				message = "<strong>[src]</strong> struggles to move."
			m_type = 1

		if ("point")
			if (!restrained())
				var/mob/M = null
				if (param)
					for (var/atom/A as mob|obj|turf|area in view(null, null))
						if (ckey(param) == ckey(A.name))
							M = A
							break

				if (!M)
					message = "<strong>[src]</strong> points."
				else
					point(M)

				if (M)
					message = "<strong>[src]</strong> points to [M]."
				else
			m_type = 1

		if ("panic","freakout")
			if (!restrained())
				message = "<strong>[src]</strong> enters a state of hysterical panic!"
			else
				message = "<strong>[src]</strong> starts writhing around in manic terror!"
			m_type = 1

		if ("clap")
			if (!restrained())
				message = "<strong>[src]</strong> claps."
				m_type = 2

		if ("flap")
			if (!restrained())
				message = "<strong>[src]</strong> flaps its wings."
				m_type = 2

		if ("aflap")
			if (!restrained())
				message = "<strong>[src]</strong> flaps its wings ANGRILY!"
				m_type = 2

		if ("custom")
			var/input = sanitize(input("Choose an emote to display."))
			var/input2 = input("Is this a visible or hearable emote?") in list("Visible","Hearable")
			if (input2 == "Visible")
				m_type = 1
			else if (input2 == "Hearable")
				m_type = 2
			else
				alert("Unable to use this emote, must be either hearable or visible.")
				return
			message = "<strong>[src]</strong> [input]"

		if ("customv")
			if (!param)
				return
			message = "<strong>[src]</strong> [param]"
			m_type = 1

		if ("customh")
			if (!param)
				return
			message = "<strong>[src]</strong> [param]"
			m_type = 2

		if ("smile","grin","smirk","frown","scowl","grimace","sulk","pout","blink","nod","shrug","think","ponder","contemplate")
			// basic visible single-word emotes
			message = "<strong>[src]</strong> [act]s."
			m_type = 1

		if ("flipout")
			message = "<strong>[src]</strong> flips the fuck out!"
			m_type = 1

		if ("rage","fury","angry")
			message = "<strong>[src]</strong> becomes utterly furious!"
			m_type = 1

		if ("twitch")
			message = "<strong>[src]</strong> twitches."
			m_type = 1
			spawn (0)
				var/old_x = pixel_x
				var/old_y = pixel_y
				pixel_x += rand(-2,2)
				pixel_y += rand(-1,1)
				sleep(2)
				pixel_x = old_x
				pixel_y = old_y

		if ("twitch_v","twitch_s")
			message = "<strong>[src]</strong> twitches violently."
			m_type = 1
			spawn (0)
				var/old_x = pixel_x
				var/old_y = pixel_y
				pixel_x += rand(-3,3)
				pixel_y += rand(-1,1)
				sleep(2)
				pixel_x = old_x
				pixel_y = old_y

		if ("birdwell", "burp")
			if (emote_check(voluntary, 50))
				message = "<strong>[src]</strong> birdwells."
				playsound(loc, "sound/vox/birdwell.ogg", 50, 1)

		if ("scream")
			if (emote_check(voluntary, 50))
				if (narrator_mode)
					playsound(loc, 'sound/vox/scream.ogg', 50, 1, 0, get_age_pitch())
				else
					playsound(get_turf(src), sound_scream, 80, 0, 0, get_age_pitch())
				message = "<strong>[src]</strong> screams!"

		if ("johnny")
			var/M
			if (param)
				M = adminscrub(param)
			if (!M)
				param = null
			else
				message = "<strong>[src]</strong> says, \"[M], please. He had a family.\" [name] takes a drag from a cigarette and blows its name out in smoke."
				m_type = 2

		if ("flip")
			if (emote_check(voluntary, 50))
				if (narrator_mode)
					playsound(loc, pick('sound/vox/deeoo.ogg', 'sound/vox/dadeda.ogg'), 50, 1)
				else
					playsound(loc, pick(sound_flip1, sound_flip2), 50, 1)
				message = "<strong>[src]</strong> does a flip!"
				if (prob(50))
					animate_spin(src, "R", 1, 0)
				else
					animate_spin(src, "L", 1, 0)

				for (var/mob/living/M in view(1, null))
					if (M == src)
						continue
					message = "<strong>[src]</strong> beep-bops at [M]."
					break

		if ("fart")
			if (emote_check(voluntary))
				m_type = 2
				var/fart_on_other = 0
				for (var/mob/living/M in loc)
					if (M == src || !M.lying)
						continue
					message = "<span style=\"color:red\"><strong>[src]</strong> farts in [M]'s face!</span>"
					fart_on_other = 1
					break
				if (!fart_on_other)
					switch (rand(1, 48))
						if (1) message = "<strong>[src]</strong> lets out a girly little 'toot' from his fart synthesizer."
						if (2) message = "<strong>[src]</strong> farts loudly!"
						if (3) message = "<strong>[src]</strong> lets one rip!"
						if (4) message = "<strong>[src]</strong> farts! It sounds wet and smells like rotten eggs."
						if (5) message = "<strong>[src]</strong> farts robustly!"
						if (6) message = "<strong>[src]</strong> farted! It reminds you of your grandmother's queefs."
						if (7) message = "<strong>[src]</strong> queefed out his metal ass!"
						if (8) message = "<strong>[src]</strong> farted! It reminds you of your grandmother's queefs."
						if (9) message = "<strong>[src]</strong> farts a ten second long fart."
						if (10) message = "<strong>[src]</strong> groans and moans, farting like the world depended on it."
						if (11) message = "<strong>[src]</strong> breaks wind!"
						if (12) message = "<strong>[src]</strong> synthesizes a farting sound."
						if (13) message = "<strong>[src]</strong> generates an audible discharge of intestinal gas."
						if (14) message = "<span style=\"color:red\"><strong>[src]</strong> is a farting motherfucker!!!</span>"
						if (15) message = "<span style=\"color:red\"><strong>[src]</strong> suffers from flatulence!</span>"
						if (16) message = "<strong>[src]</strong> releases flatus."
						if (17) message = "<strong>[src]</strong> releases gas generated in his digestive tract, his stomach and his intestines. <span style=\"color:red\"><strong>It stinks way bad!</strong></span>"
						if (18) message = "<strong>[src]</strong> farts like your mom used to!"
						if (19) message = "<strong>[src]</strong> farts. It smells like Soylent Surprise!"
						if (20) message = "<strong>[src]</strong> farts. It smells like pizza!"
						if (21) message = "<strong>[src]</strong> farts. It smells like George Melons' perfume!"
						if (22) message = "<strong>[src]</strong> farts. It smells like atmos in here now!"
						if (23) message = "<strong>[src]</strong> farts. It smells like medbay in here now!"
						if (24) message = "<strong>[src]</strong> farts. It smells like the bridge in here now!"
						if (25) message = "<strong>[src]</strong> farts like a pubby!"
						if (26) message = "<strong>[src]</strong> farts like a goone!"
						if (27) message = "<strong>[src]</strong> farts so hard he's certain poop came out with it, but dares not find out."
						if (28) message = "<strong>[src]</strong> farts delicately."
						if (29) message = "<strong>[src]</strong> farts timidly."
						if (30) message = "<strong>[src]</strong> farts very, very quietly. The stench is OVERPOWERING."
						if (31) message = "<strong>[src]</strong> farts and says, \"Mmm! Delightful aroma!\""
						if (32) message = "<strong>[src]</strong> farts and says, \"Mmm! Sexy!\""
						if (33) message = "<strong>[src]</strong> farts and fondles his own buttocks."
						if (34) message = "<strong>[src]</strong> farts and fondles YOUR buttocks."
						if (35) message = "<strong>[src]</strong> fart in he own mouth. A shameful [src]."
						if (36) message = "<strong>[src]</strong> farts out pure plasma! <span style=\"color:red\"><strong>FUCK!</strong></span>"
						if (37) message = "<strong>[src]</strong> farts out pure oxygen. What the fuck did he eat?"
						if (38) message = "<strong>[src]</strong> breaks wind noisily!"
						if (39) message = "<strong>[src]</strong> releases gas with the power of the gods! The very station trembles!!"
						if (40) message = "<strong>[src] <span style=\"color:red\">f</span><span style=\"color:blue\">a</span>r<span style=\"color:red\">t</span><span style=\"color:blue\">s</span>!</strong>"
						if (41) message = "<strong>[src] shat his pants!</strong>"
						if (42) message = "<strong>[src] shat his pants!</strong> Oh, no, that was just a really nasty fart."
						if (43) message = "<strong>[src]</strong> is a flatulent whore."
						if (44) message = "<strong>[src]</strong> likes the smell of his own farts."
						if (45) message = "<strong>[src]</strong> doesnt wipe after he poops."
						if (46) message = "<strong>[src]</strong> farts! Now he smells like Tiny Turtle."
						if (47) message = "<strong>[src]</strong> burps! He farted out of his mouth!! That's Showtime's style, baby."
						if (48) message = "<strong>[src]</strong> laughs! His breath smells like a fart."

				if (narrator_mode)
					playsound(loc, 'sound/vox/fart.ogg', 50, 1)
				else
					playsound(loc, sound_fart, 50, 1)
				#ifdef DATALOGGER
				game_stats.Increment("farts")
				#endif
				spawn (10)
					emote_allowed = 1
				for (var/mob/M in viewers(src, null))
					if (!M.stat && M.get_brain_damage() >= 60 && (ishuman(M) || isrobot(M)))
						spawn (10)
							if (prob(20))
								switch(pick(1,2,3))
									if (1)
										M.say("[M == src ? "i" : name] made a fart!!")
									if (2)
										M.emote("giggle")
									if (3)
										M.emote("clap")
		else
			show_text("Invalid Emote: [act]")
			return

	if ((message && stat == 0))
		if (m_type & 1)
			for (var/mob/O in viewers(src, null))
				O.show_message(message, m_type)
		else
			for (var/mob/O in hearers(src, null))
				O.show_message(message, m_type)
	return

/mob/living/silicon/hivebot/examine()
	set src in oview()
	set category = "Local"

	if (isghostdrone(usr))
		return
	boutput(usr, "<span style=\"color:blue\">*---------*</span>")
	boutput(usr, text("<span style=\"color:blue\">This is [bicon(src)] <strong>[name]</strong>!</span>"))
	if (stat == 2)
		boutput(usr, text("<span style=\"color:red\">[name] is powered-down.</span>"))
	if (bruteloss)
		if (bruteloss < 75)
			boutput(usr, text("<span style=\"color:red\">[name] looks slightly dented</span>"))
		else
			boutput(usr, text("<span style=\"color:red\"><strong>[name] looks severely dented!</strong></span>"))
	if (fireloss)
		if (fireloss < 75)
			boutput(usr, text("<span style=\"color:red\">[name] looks slightly burnt!</span>"))
		else
			boutput(usr, text("<span style=\"color:red\"><strong>[name] looks severely burnt!</strong></span>"))
	if (stat == 1)
		boutput(usr, text("<span style=\"color:red\">[name] doesn't seem to be responding.</span>"))
	return

/mob/living/silicon/hivebot/New(loc, mainframe)
	boutput(src, "<span style=\"color:blue\">Your icons have been generated!</span>")
	updateicon()

	if (mainframe)
		dependent = 1
		//real_name = mainframe:name
		name = mainframe:name
	else
		real_name = "Robot [pick(rand(1, 999))]"
		name = real_name

	radio = new /obj/item/device/radio(src)
	ears = radio

	spawn (10)
		if (!cell)
			cell = new /obj/item/cell/shell_cell/charged (src)

	..()
	botcard.access = get_all_accesses()

/mob/living/silicon/hivebot/proc/pick_module()
	if (module)
		return
	var/mod = input("Please, select a module!", "Robot", null, null) in list("Construction", "Engineering", "Mining")
	if (module)
		return
	switch(mod)
//		if ("Combat")
//			module = new /obj/item/hive_module/standard(src)

//		if ("Security")
//			module = new /obj/item/hive_module/security(src)

		if ("Engineering")
			module = new /obj/item/hive_module/engineering(src)

		if ("Construction")
			module = new /obj/item/hive_module/construction(src)

		if ("Mining")
			boutput(src, "You may now fly in space using your Mining Jetpack")
			module = new /obj/item/hive_module/mining(src)
			jetpack = 1

	hands.icon_state = "malf"
	updateicon()


/mob/living/silicon/hivebot/blob_act(var/power)
	if (stat != 2)
		bruteloss += power
		updatehealth()
		return TRUE
	return FALSE

/mob/living/silicon/hivebot/Stat()
	..()
	if (cell)
		stat("Charge Left:", "[cell.charge]/[cell.maxcharge]")
	else
		stat("No Cell Inserted!")

/mob/living/silicon/hivebot/restrained()
	return FALSE

/mob/living/silicon/hivebot/bullet_act(var/obj/projectile/P)
	..()
	log_shot(P,src) // Was missing (Convair880).

/mob/living/silicon/hivebot/ex_act(severity)
	..() // Logs.
	flash(30)

	if (stat == 2 && client)
		gib(1)
		return

	else if (stat == 2 && !client)
		qdel(src)
		return

	var/b_loss = bruteloss
	var/f_loss = fireloss
	switch(severity)
		if (1.0)
			if (stat != 2)
				b_loss += 100
				f_loss += 100
				gib(1)
				return
		if (2.0)
			if (stat != 2)
				b_loss += 60
				f_loss += 60
		if (3.0)
			if (stat != 2)
				b_loss += 30
	bruteloss = b_loss
	fireloss = f_loss
	updatehealth()

/mob/living/silicon/hivebot/meteorhit(obj/O as obj)
	for (var/mob/M in viewers(src, null))
		M.show_message(text("<span style=\"color:red\">[src] has been hit by [O]</span>"), 1)
		//Foreach goto(19)
	if (health > 0)
		bruteloss += 30
		if ((O.icon_state == "flaming"))
			fireloss += 40
		updatehealth()
	return

/mob/living/silicon/hivebot/Bump(atom/movable/AM as mob|obj, yes)
	spawn ( 0 )
		if ((!( yes ) || now_pushing))
			return
		now_pushing = 1
		if (ismob(AM))
			var/mob/tmob = AM
			if (istype(tmob, /mob/living/carbon/human) && tmob.bioHolder.HasEffect("fat"))
				if (prob(20))
					for (var/mob/M in viewers(src, null))
						if (M.client)
							boutput(M, "<span style=\"color:red\"><strong>[src] fails to push [tmob]'s fat ass out of the way.</strong></span>")
					now_pushing = 0
					unlock_medal("That's no moon, that's a GOURMAND!", 1)
					return
		now_pushing = 0


		if (!istype(AM, /atom/movable))
			return
		if (!now_pushing)
			now_pushing = 1
			if (!AM.anchored)
				var/t = get_dir(src, AM)
				step(AM, t)
			now_pushing = null

		if (AM)
			AM.last_bumped = world.timeofday
			AM.Bumped(src)
		return
	return

/mob/living/silicon/hivebot/attackby(obj/item/W as obj, mob/user as mob)
	if (istype(W, /obj/item/weldingtool) && W:welding)
		if (get_brute_damage() < 1)
			boutput(user, "<span style=\"color:red\">[src] has no dents to repair.</span>")
			return
		if (W:get_fuel() > 2)
			W:use_fuel(1)
		else
			boutput(user, "Need more welding fuel!")
			return
		HealDamage("All", 30, 0)
		add_fingerprint(user)
		if (get_brute_damage() < 1)
			bruteloss = 0
			visible_message("<span style=\"color:red\"><strong>[user] fully repairs the dents on [src]!</strong></span>")
		else
			visible_message("<span style=\"color:red\">[user] has fixed some of the dents on [src].</span>")
		updatehealth()

	// Added ability to repair burn-damaged AI shells (Convair880).
	else if (istype(W, /obj/item/cable_coil))
		var/obj/item/cable_coil/coil = W
		add_fingerprint(user)
		if (get_burn_damage() < 1)
			user.show_text("There's no burn damage on [name]'s wiring to mend.", "red")
			return
		coil.use(1)
		HealDamage("All", 0, 30)
		if (get_burn_damage() < 1)
			fireloss = 0
			visible_message("<span style=\"color:red\"><strong>[user.name]</strong> fully repairs the damage to [name]'s wiring.</span>")
		else
			boutput(user, "<span style=\"color:red\"><strong>[user.name]</strong> repairs some of the damage to [name]'s wiring.</span>")
		updatehealth()

	else if (istype(W, /obj/item/clothing/suit/bee))
		boutput(user, "You stuff [src] into [W]! It fits surprisingly well.")
		beebot = 1
		updateicon()
		qdel(W)
		return
	else
		return ..()

/mob/living/silicon/hivebot/attack_hand(mob/user)
	..()
	if (user.a_intent == INTENT_GRAB && beebot == 1)
		var/obj/item/clothing/suit/bee/B = new /obj/item/clothing/suit/bee(loc)
		boutput(user, "You pull [B] off of [src]!")
		beebot = 0
		updateicon()
	return

/mob/living/silicon/hivebot/allowed(mob/M)
	//check if it doesn't require any access at all
	if (check_access(null))
		return TRUE
	return FALSE

/mob/living/silicon/hivebot/check_access(obj/item/I)
	if (!istype(req_access, /list)) //something's very wrong
		return TRUE

	if (istype(I, /obj/item/device/pda2) && I:ID_card)
		I = I:ID_card
	var/list/L = req_access
	if (!L.len) //no requirements
		return TRUE
	if (!I || !istype(I, /obj/item/card/id) || !I:access) //not ID or no access
		return FALSE
	for (var/req in req_access)
		if (!(req in I:access)) //doesn't have this access
			return FALSE
	return TRUE

/mob/living/silicon/hivebot/proc/updateicon()

	overlays = null

//	if (beebot == 1)
//		icon_state = "eyebot-bee"
	if (stat == 0)
		if (beebot == 1)
			icon_state = "eyebot-bee[client ? null : "-logout"]"
		else
			icon_state = "[initial(icon_state)][client ? null : "-logout"]"
	else
		if (beebot == 1)
			icon_state = "eyebot-bee-dead"
		else
			icon_state = "[initial(icon_state)]-dead"


/mob/living/silicon/hivebot/proc/installed_modules()

	if (!module)
		pick_module()
		return
	var/dat = "<HEAD><TITLE>Modules</TITLE><META HTTP-EQUIV='Refresh' CONTENT='10'></HEAD><BODY><br>"
	dat += {"<A HREF='?action=mach_close&window=robotmod'>Close</A>
	<BR>
	<BR>
	<strong>Activated Modules</strong>
	<BR>
	Module 1: [module_states[1] ? "<A HREF=?src=\ref[src];mod=\ref[module_states[1]]>[module_states[1]]<A>" : "No Module"]<BR>
	Module 2: [module_states[2] ? "<A HREF=?src=\ref[src];mod=\ref[module_states[2]]>[module_states[2]]<A>" : "No Module"]<BR>
	Module 3: [module_states[3] ? "<A HREF=?src=\ref[src];mod=\ref[module_states[3]]>[module_states[3]]<A>" : "No Module"]<BR>
	<BR>
	<strong>Installed Modules</strong><BR><BR>"}

	for (var/obj in src.module.modules)
		if (activated(obj))
			dat += text("[obj]: <strong>Activated</strong><BR>")
		else
			dat += text("[obj]: <A HREF=?src=\ref[src];act=\ref[obj]>Activate</A><BR>")
/*
		if (activated(obj))
			dat += text("[obj]: \[<strong>Activated</strong> | <A HREF=?src=\ref[src];deact=\ref[obj]>Deactivate</A>\]<BR>")
		else
			dat += text("[obj]: \[<A HREF=?src=\ref[src];act=\ref[obj]>Activate</A> | <strong>Deactivated</strong>\]<BR>")
*/
	src << browse(dat, "window=robotmod&can_close=0")


/mob/living/silicon/hivebot/Topic(href, href_list)
	..()
	if (href_list["mod"])
		var/obj/item/O = locate(href_list["mod"])
		O.attack_self(src)

	if (href_list["act"])
		var/obj/item/O = locate(href_list["act"])
		if (activated(O))
			boutput(src, "Already activated")
			return
		if (!module_states[1])
			module_states[1] = O
			O.layer = HUD_LAYER
			contents += O
			O.pickup(src) // Handle light datums and the like.
		else if (!module_states[2])
			module_states[2] = O
			O.layer = HUD_LAYER
			contents += O
			O.pickup(src)
		else if (!module_states[3])
			module_states[3] = O
			O.layer = HUD_LAYER
			contents += O
			O.pickup(src)
		else
			boutput(src, "You need to disable a module first!")
		installed_modules()

	if (href_list["deact"])
		var/obj/item/O = locate(href_list["deact"])
		if (activated(O))
			if (module_states[1] == O)
				module_states[1] = null
				contents -= O
				O.dropped(src) // Handle light datums and the like.
			else if (module_states[2] == O)
				module_states[2] = null
				contents -= O
				O.dropped(src)
			else if (module_states[3] == O)
				module_states[3] = null
				contents -= O
				O.dropped(src)
			else
				boutput(src, "Module isn't activated.")
		else
			boutput(src, "Module isn't activated")
		installed_modules()
	return

/mob/living/silicon/hivebot/proc/uneq_active()
	if (isnull(module_active))
		return
	if (isitem(module_active))
		var/obj/item/I = module_active
		I.dropped(src) // Handle light datums and the like.

	if (module_states[1] == module_active)
		if (client)
			client.screen -= module_states[1]
		contents -= module_states[1]
		module_active = null
		module_states[1] = null
		src.inv1.icon_state = "inv1"
	else if (module_states[2] == module_active)
		if (client)
			client.screen -= module_states[2]
		contents -= module_states[2]
		module_active = null
		module_states[2] = null
		src.inv2.icon_state = "inv2"
	else if (module_states[3] == module_active)
		if (client)
			client.screen -= module_states[3]
		contents -= module_states[3]
		module_active = null
		module_states[3] = null
		src.inv3.icon_state = "inv3"


/mob/living/silicon/hivebot/proc/activated(obj/item/O)
	if (module_states[1] == O)
		return TRUE
	else if (module_states[2] == O)
		return TRUE
	else if (module_states[3] == O)
		return TRUE
	else
		return FALSE

/mob/living/silicon/hivebot/proc/radio_menu()
	if (!radio)
		radio = new /obj/item/device/radio(src)
		ears = radio
	var/dat = {"
<TT>
Microphone: [radio.broadcasting ? "<A href='byond://?src=\ref[radio];talk=0'>Engaged</A>" : "<A href='byond://?src=\ref[radio];talk=1'>Disengaged</A>"]<BR>
Speaker: [radio.listening ? "<A href='byond://?src=\ref[radio];listen=0'>Engaged</A>" : "<A href='byond://?src=\ref[radio];listen=1'>Disengaged</A>"]<BR>
Frequency:
<A href='byond://?src=\ref[radio];freq=-10'>-</A>
<A href='byond://?src=\ref[radio];freq=-2'>-</A>
[format_frequency(radio.frequency)]
<A href='byond://?src=\ref[radio];freq=2'>+</A>
<A href='byond://?src=\ref[radio];freq=10'>+</A><BR>
-------
</TT>"}
	src << browse(dat, "window=radio")
	onclose(src, "radio")
	return


/mob/living/silicon/hivebot/Move(a, b, flag)

	if (buckled)
		return

	if (restrained())
		pulling = null

	var/t7 = 1
	if (restrained())
		for (var/mob/M in range(src, 1))
			if ((M.pulling == src && M.stat == 0 && !( M.restrained() )))
				t7 = null
	if ((t7 && (pulling && ((get_dist(src, pulling) <= 1 || pulling.loc == loc) && (client && client.moving)))))
		var/turf/T = loc
		. = ..()

		if (pulling && pulling.loc)
			if (!( isturf(pulling.loc) ))
				pulling = null
				return
			else
				if (Debug)
					diary <<"pulling disappeared? at [__LINE__] in mob.dm - pulling = [pulling]"
					diary <<"REPORT THIS"

		/////
		if (pulling && pulling.anchored)
			pulling = null
			return

		if (!restrained())
			var/diag = get_dir(src, pulling)
			if ((diag - 1) & diag)
			else
				diag = null
			if ((get_dist(src, pulling) > 1 || diag))
				if (ismob(pulling))
					var/mob/M = pulling
					var/ok = 1
					if (locate(/obj/item/grab, M.grabbed_by))
						if (prob(75))
							var/obj/item/grab/G = pick(M.grabbed_by)
							if (istype(G, /obj/item/grab))
								M.visible_message("<span style=\"color:red\">[G.affecting] has been pulled from [G.assailant]'s grip by [src]</span>")
								qdel(G)
						else
							ok = 0
						if (locate(/obj/item/grab, M.grabbed_by.len))
							ok = 0
					if (ok)
						var/t = M.pulling
						M.pulling = null
						step(pulling, get_dir(pulling.loc, T))
						M.pulling = t
				else
					if (pulling)
						step(pulling, get_dir(pulling.loc, T))
	else
		pulling = null
		. = ..()
	if (s_active && !(s_active.master in src))
		detach_hud(s_active)
		s_active = null

/mob/living/silicon/hivebot/verb/cmd_show_laws()
	set category = "Robot Commands"
	set name = "Show Laws"

	show_laws()
	return

/mob/living/silicon/hivebot/verb/open_nearest_door()
	set category = "Robot Commands"
	set name = "Open Nearest Door to..."
	set desc = "Automatically opens the nearest door to a selected individual, if possible."

	open_nearest_door_silicon()
	return

/mob/living/silicon/hivebot/verb/cmd_return_mainframe()
	set category = "Robot Commands"
	set name = "Recall to Mainframe"
	return_mainframe()

/mob/living/silicon/hivebot/proc/return_mainframe()
	if (mainframe)
		mainframe.return_to(src)
		updateicon()
	else
		boutput(src, "<span style=\"color:red\">You lack a dedicated mainframe!</span>")
		return

/mob/living/silicon/hivebot/Life(controller/process/mobs/parent)
	set invisibility = 0
	if (..(parent))
		return TRUE
	if (transforming)
		return

	if (stat != 2)
		use_power()
	else
		if (self_destruct)
			spawn (5)
				gib(src)

	blinded = null

	clamp_values()

	update_icons_if_needed()
	antagonist_overlay_refresh(0, 0)

	handle_regular_status_updates()

	if (client)
		shell = 0
		handle_regular_hud_updates()
		update_items()
		if (dependent)
			mainframe_check()

	update_canmove()


/mob/living/silicon/hivebot

	proc/clamp_values()

		stunned = max(min(stunned, 10),0)
		paralysis = max(min(paralysis, 1), 0)
		weakened = max(min(weakened, 15), 0)
		sleeping = max(min(sleeping, 1), 0)
		bruteloss = max(bruteloss, 0)
		fireloss = max(fireloss, 0)

	proc/use_power()

		if (cell)
			if (cell.charge <= 0)
				//death() no why would it just explode upon running out of power that is absurd
				if (stat == 0)
					sleep(0)
					lastgasp()
				stat = 1
			else if (cell.charge <= 10)
				module_active = null
				module_states[1] = null
				module_states[2] = null
				module_states[3] = null
				cell.charge -=1
			else
				if (module_states[1])
					cell.charge -=1
				if (module_states[2])
					cell.charge -=1
				if (module_states[3])
					cell.charge -=1
				cell.charge -=1
				blinded = 0
				stat = 0
		else
			blinded = 1
			if (stat == 0)
				sleep(0)
				lastgasp() // calling lastgasp() here because we just ran out of power
			stat = 1


	proc/update_canmove()
		if (paralysis || stunned || weakened || buckled)
			canmove = 0
		else
			canmove = 1


	proc/handle_regular_status_updates()

		health = max_health - (fireloss + bruteloss)

		if (health <= 0)
			death()

		if (stat != 2) //Alive.

			if (paralysis || stunned || weakened) //Stunned etc.
				var/setStat = stat
				if (stunned > 0)
					stunned--
					setStat = 0
				if (weakened > 0)
					weakened--
					lying = 1
					setStat = 0
				if (paralysis > 0)
					paralysis--
					blinded = 1
					lying = 1
					setStat = 1
				if (stat == 0 && setStat == 1)
					sleep(0)
					lastgasp() // calling lastgasp() here because we just got knocked out
				stat = setStat
			else	//Not stunned.
				lying = 0
				stat = 0

		else //Dead.
			blinded = 1
			stat = 2

		if (stuttering)
			stuttering = 0

		lying = 0
		density = 1

		if (get_eye_blurry())
			change_eye_blurry(-1)

		if (druggy > 0)
			druggy--
			druggy = max(0, druggy)

		return TRUE

	proc/handle_regular_hud_updates()

		if (stat == 2 || bioHolder.HasEffect("xray"))
			sight |= SEE_TURFS
			sight |= SEE_MOBS
			sight |= SEE_OBJS
			see_in_dark = SEE_DARK_FULL
			see_invisible = 2
		else if (stat != 2)
			sight &= ~SEE_MOBS
			sight &= ~SEE_TURFS
			sight &= ~SEE_OBJS
			see_in_dark = SEE_DARK_FULL
			see_invisible = 2

		if (healths)
			if (stat != 2)
				switch(health)
					if (max_health to INFINITY)
						healths.icon_state = "health0"
					if (max_health*0.80 to max_health)
						healths.icon_state = "health1"
					if (max_health*0.60 to max_health*0.80)
						healths.icon_state = "health2"
					if (max_health*0.40 to max_health*0.60)
						healths.icon_state = "health3"
					if (max_health*0.20 to max_health*0.40)
						healths.icon_state = "health4"
					if (0 to max_health*0.20)
						healths.icon_state = "health5"
					else
						healths.icon_state = "health6"
			else
				healths.icon_state = "health7"

		if (cells)
			if (cell)
				switch(round(100*cell.charge/cell.maxcharge))
					if (75 to INFINITY)
						cells.icon_state = "charge4"
					if (50 to 75)
						cells.icon_state = "charge3"
					if (25 to 50)
						cells.icon_state = "charge2"
					if (1 to 25)
						cells.icon_state = "charge1"
					else
						cells.icon_state = "charge0"
			else
				cells.icon_state = "charge-none"

		switch(get_temp_deviation())
			if (2 to INFINITY)
				bodytemp.icon_state = "temp2"
			if (1 to 2)
				bodytemp.icon_state = "temp1"
			if (-1 to 1)
				bodytemp.icon_state = "temp0"
			if (-2 to -1)
				bodytemp.icon_state = "temp-1"
			else
				bodytemp.icon_state = "temp-2"


		if (pullin)	pullin.icon_state = "pull[pulling ? 1 : 0]"

		if (!sight_check(1) && stat != 2)
			vision.set_color_mod("#000000")
		else
			vision.set_color_mod("#ffffff")
		return TRUE


	proc/update_items()
		if (client)
			client.screen -= contents
			client.screen += contents
		var/obj/item/I = null
		if (module_states[1])
			I = module_states[1]
			I.screen_loc = ui_inv1
		if (module_states[2])
			I = module_states[2]
			I.screen_loc = ui_inv2
		if (module_states[3])
			I = module_states[3]
			I.screen_loc = ui_inv3

	proc/mainframe_check()
		if (mainframe)
			if (mainframe.stat == 2)
				mainframe.return_to(src)
		else
			death()

/mob/living/silicon/hivebot/Login()
	..()

	update_clothing()
	updateicon()

	if (real_name == "Cyborg")
		real_name += " "
		real_name += pick("Alpha", "Beta", "Gamma", "Delta", "Epsilon", "Zeta", "Eta", "Theta", "Iota", "Kappa", "Lambda", "Mu", "Nu", "Xi", "Omicron", "Pi", "Rho", "Sigma", "Tau", "Upsilon", "Phi", "Chi", "Psi", "Omega")
		real_name += "-[pick(rand(1, 99))]"
		name = real_name
	return

/mob/living/silicon/hivebot/Logout()
	..()
	updateicon()
	return

/mob/living/silicon/hivebot/say_understands(var/other)
	if (isAI(other))
		return TRUE
	if (ishuman(other))
		var/mob/living/carbon/human/H = other
		if (!H.mutantrace || !H.mutantrace.exclusive_language)
			return TRUE
		else
			return FALSE
	if (isrobot(other) || isshell(other))
		return TRUE
	return ..()

/mob/living/silicon/hivebot/say_quote(var/text)
	var/ending = copytext(text, length(text))

	if (ending == "?")
		return "queries, \"[text]\"";
	else if (ending == "!")
		return "declares, \"[text]\"";

	return "states, \"[text]\"";

/*-----Shell-Creation---------------------------------------*/

/obj/item/ai_interface
	name = "\improper AI interface board"
	desc = "A board that allows AIs to interface with the robot it's installed in. It features a little blinking LED, but who knows what the LED is trying to tell you? Does it even mean anything? Why is it blinking? WHY?? WHAT DOES IT MEAN?! ??????"
	icon = 'icons/mob/hivebot.dmi'
	icon_state = "ai-interface"
	item_state = "ai-interface"
	w_class = 2.0

//obj/item/cell/shell_cell moved to cells.dm

/obj/item/shell_frame
	name = "AI shell frame"
	desc = "An empty frame for an AI shell."
	icon = 'icons/mob/hivebot.dmi'
	icon_state = "shell-frame"
	item_state = "shell-frame"
	w_class = 2.0
	var/build_step = 0
	var/obj/item/cell/cell = null
	var/has_radio = 0
	var/has_interface = 0

/obj/item/shell_frame/attackby(obj/item/W as obj, mob/user as mob)
	if ((istype(W, /obj/item/sheet)) && (!build_step))
		var/obj/item/sheet/M = W
		if (M.amount >= 1)
			build_step++
			boutput(user, "You add the plating to [src]!")
			playsound(get_turf(src), "sound/weapons/Genhit.ogg", 40, 1)
			icon_state = "shell-plate"
			M.amount -= 1
			if (M.amount < 1)
				user.drop_item()
				qdel(M)
			return
		else
			boutput(user, "<span style=\"color:red\">You need at least one metal sheet to add plating!</span>")
			return

	else if ((istype(W, /obj/item/cable_coil)) && (build_step == 1))
		var/obj/item/cable_coil/coil = W
		if (coil.amount >= 3)
			build_step++
			boutput(user, "You add the cable to [src]!")
			playsound(get_turf(src), "sound/weapons/Genhit.ogg", 40, 1)
			coil.amount -= 3
			icon_state = "shell-cable"
			if (coil.amount < 1)
				user.drop_item()
				qdel(coil)
			return
		else
			boutput(user, "<span style=\"color:red\">You need at least three lengths of cable to install it in [src]!</span>")
			return

	else if (istype(W, /obj/item/cell))
		if (build_step >= 2)
			build_step++
			boutput(user, "You add the [W] to [src]!")
			playsound(get_turf(src), "sound/weapons/Genhit.ogg", 40, 1)
			cell = W
			user.u_equip(W)
			W.set_loc(src)
			return
		else
			boutput(user, "[src] needs[build_step ? "" : " metal plating and"] at least three lengths of cable installed before you can add the cell.")
			return

	else if (istype(W, /obj/item/device/radio))
		if (build_step >= 2)
			build_step++
			boutput(user, "You add the [W] to [src]!")
			playsound(get_turf(src), "sound/weapons/Genhit.ogg", 40, 1)
			icon_state = "shell-radio"
			has_radio = 1
			qdel(W)
			return
		else
			boutput(user, "[src] needs[build_step ? "" : " metal plating and"] at least three lengths of cable installed before you can add the radio.")
			return

	else if (istype(W, /obj/item/ai_interface))
		if (build_step >= 2)
			build_step++
			boutput(user, "You add the [W] to [src]!")
			playsound(get_turf(src), "sound/weapons/Genhit.ogg", 40, 1)
			has_interface = 1
			qdel(W)
			return
		else
			boutput(user, "[src] needs[build_step ? "" : " metal plating and"] at least three lengths of cable installed before you can add the AI interface.")
			return

	else if (istype(W, /obj/item/wrench))
		if (build_step >= 5)
			build_step++
			boutput(user, "You activate the shell!  Beep bop!")
			var/mob/living/silicon/hivebot/eyebot/S = new /mob/living/silicon/hivebot/eyebot(get_turf(src))
			S.cell = cell
			cell.set_loc(S)
			qdel(src)
			return
		else if (build_step >= 2)
			var/still_needed = ""
			if (!cell)
				still_needed += " a power cell,"
			if (!has_radio)
				still_needed += " a station bounced radio,"
			if (!has_interface)
				still_needed += " an AI interface board,"
			if (still_needed)
				still_needed = copytext(still_needed, 1, -1)
			boutput(user, "[src] needs [still_needed] before you can activate it.")
			return
		else
			var/still_needed = ""
			if (!cell)
				still_needed += " a power cell,"
			if (!has_radio)
				still_needed += " a station bounced radio,"
			if (!has_interface)
				still_needed += " an AI interface board,"
			if (still_needed)
				still_needed = copytext(still_needed, 1, -1)
			boutput(user, "[src] needs[build_step ? "" : " metal plating and"] at least three lengths of cable installed and[still_needed] before you can activate it.")
			return
