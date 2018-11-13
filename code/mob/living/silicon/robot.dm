/robot_cosmetic
	var/head_mod = null
	var/ches_mod = null
	var/arms_mod = null
	var/legs_mod = null
	var/list/fx = list(255,0,0)
	var/painted = 0
	var/list/paint = list(0,0,0)

/mob/living/silicon/robot
	name = "Cyborg"
	voice_name = "synthesized voice"
	icon = 'icons/mob/robots.dmi'
	icon_state = "robot"
	health = 300
	emaggable = 1
	syndicate_possible = 1

	var/hud/robot/hud

// Pieces and parts
	var/obj/item/parts/robot_parts/head/part_head = null
	var/obj/item/parts/robot_parts/chest/part_chest = null
	var/obj/item/parts/robot_parts/arm/part_arm_r = null
	var/obj/item/parts/robot_parts/arm/part_arm_l = null
	var/obj/item/parts/robot_parts/leg/part_leg_r = null
	var/obj/item/parts/robot_parts/leg/part_leg_l = null
	var/robot_cosmetic/cosmetic_mods = null

	var/list/clothes = list()

	var/next_cache = 0
	var/stat_cache = list(0, 0, "")

//3 Modules can be activated at any one time.
	var/module_active = null
	var/list/module_states = list(null,null,null)

	var/obj/item/device/radio/radio = null
	var/mob/living/silicon/ai/connected_ai = null
	var/obj/machinery/camera/camera = null
	var/obj/item/cell/cell = null
	var/obj/item/organ/brain/brain = null
	var/obj/item/ai_interface/ai_interface = null
	var/obj/item/robot_module/module = null
	var/list/upgrades = list()
	var/max_upgrades = 3

	var/opened = 0
	var/wiresexposed = 0
	var/brainexposed = 0
	var/locked = 1
	var/locking = 0
	req_access = list(access_robotics)
	var/alarms = list("Motion"=list(), "Fire"=list(), "Atmosphere"=list(), "Power"=list())
	var/viewalerts = 0
	var/jetpack = 0
	var/effects/system/ion_trail_follow/ion_trail = null
	var/jeton = 0
	var/freemodule = 1 // For picking modules when a robot is first created
	var/automaton_skin = 0 // for the medal reward

	sound_fart = 'sound/misc/poo2_robot.ogg'
	var/sound_automaton_spaz = 'sound/misc/automaton_spaz.ogg'
	var/sound_automaton_ratchet = 'sound/misc/automaton_ratchet.ogg'
	var/sound_automaton_tickhum = 'sound/misc/automaton_tickhum.ogg'

	// moved up to silicon.dm
	killswitch = 0
	killswitch_time = 60
	weapon_lock = 0
	weaponlock_time = 120
	var/oil = 0
	var/custom = 0 //For custom borgs. Basically just prevents appearance changes. Obviously needs more work.

	New(loc, var/obj/item/parts/robot_parts/robot_frame/frame = null, var/starter = 0, var/syndie = 0)
		hud = new(src)
		attach_hud(hud)

		zone_sel = new(src, "CENTER+3, SOUTH")
		zone_sel.change_hud_style('icons/mob/hud_robot.dmi')
		attach_hud(zone_sel)

		if (starter && !(dependent || shell))
			var/obj/item/parts/robot_parts/chest/light/PC = new /obj/item/parts/robot_parts/chest/light(src)
			var/obj/item/cell/CELL = new /obj/item/cell(PC)
			CELL.charge = CELL.maxcharge
			PC.wires = 1
			cell = CELL
			PC.cell = CELL
			part_chest = PC

			part_head = new /obj/item/parts/robot_parts/head/light(src)
			part_arm_r = new /obj/item/parts/robot_parts/arm/right/light(src)
			part_arm_l = new /obj/item/parts/robot_parts/arm/left/light(src)
			part_leg_r = new /obj/item/parts/robot_parts/leg/right/light(src)
			part_leg_l = new /obj/item/parts/robot_parts/leg/left/light(src)
			for (var/obj/item/parts/robot_parts/P in contents) P.holder = src

			if (!custom)
				spawn (0)
					choose_name(3)
		else
			if (!frame)
				// i can only imagine bad shit happening if you just try to straight spawn one like from the spawn menu or
				// whatever so let's not allow that for the time being, just to make sure
				logTheThing("debug", null, null, "<strong>I Said No/Composite Cyborg:</strong> Composite borg attempted to spawn with null frame")
				qdel(src)
				return
			else
				if (!frame.head || !frame.chest)
					logTheThing("debug", null, null, "<strong>I Said No/Composite Cyborg:</strong> Composite borg attempted to spawn from incomplete frame")
					qdel(src)
					return
				part_head = frame.head
				part_chest = frame.chest
				if (frame.l_arm) part_arm_l = frame.l_arm
				if (frame.r_arm) part_arm_r = frame.r_arm
				if (frame.l_leg) part_leg_l = frame.l_leg
				if (frame.r_leg) part_leg_r = frame.r_leg
				for (var/obj/item/parts/robot_parts/P in frame.contents)
					P.set_loc(src)
					P.holder = src
		cosmetic_mods = new /robot_cosmetic(src)

		. = ..()

		if (shell)
			if (!(src in available_ai_shells))
				available_ai_shells += src
			for (var/mob/living/silicon/ai/AI in mobs)
				boutput(AI, "<span style=\"color:green\">[src] has been connected to you as a controllable shell.</span>")
			if (!ai_interface)
				ai_interface = new(src)

		spawn (1)
			if (!dependent && !shell)
				boutput(src, "<span style=\"color:blue\">Your icons have been generated!</span>")
				syndicate = syndie
		spawn (4)
			if (!connected_ai && !syndicate && !(dependent || shell))
				for (var/mob/living/silicon/ai/A in mobs)
					connected_ai = A
					A.connected_robots += src
					break

			botcard.access = get_all_accesses()
			radio = new /obj/item/device/radio(src)
			ears = radio
			camera = new /obj/machinery/camera(src)
			camera.c_tag = real_name
			camera.network = "Robots"
		spawn (15)
			if (!brain && key && !(dependent || shell || ai_interface))
				var/obj/item/organ/brain/B = new /obj/item/organ/brain(src)
				B.owner = mind
				B.icon_state = "borg_brain"
				if (!B.owner) //Oh no, they have no mind!
					logTheThing("debug", null, null, "<strong>Mind</strong> Cyborg spawn forced to create new mind for key \[[key ? key : "INVALID KEY"]]")
					var/mind/newmind = new
					newmind.key = key
					newmind.current = src
					B.owner = newmind
					mind = newmind
				brain = B
				if (part_head)
					B.set_loc(part_head)
					part_head.brain = B
				else
					// how the hell would this happen. oh well
					var/obj/item/parts/robot_parts/head/H = new /obj/item/parts/robot_parts/head(src)
					part_head = H
					B.set_loc(H)
					H.brain = B
			update_bodypart()

	Life(controller/process/mobs/parent)
		set invisibility = 0

		if (..(parent))
			return TRUE

		mainframe_check()

		if (transforming)
			return

		for (var/obj/item/I in src)
			if (!I.material)
				continue
			I.material.triggerOnLife(src, I)

		blinded = null

		//Status updates, death etc.
		clamp_values()
		handle_regular_status_updates()

		if (client)
			handle_regular_hud_updates()
			antagonist_overlay_refresh(0, 0)
		if (stat != 2) //still using power
			use_power()
			process_killswitch()
			process_locks()

		update_canmove()

		if (client) //ov1
			// overlays
			updateOverlaysClient(client)

		if (observers.len)
			for (var/mob/x in observers)
				if (x.client)
					updateOverlaysClient(x.client)

		if (!can_act(M=src,include_cuffs=0)) actions.interrupt(src, INTERRUPT_STUNNED)

	drop_item_v()
		return

	death(gibbed)
		if (mainframe)
			logTheThing("combat", src, null, "'s AI controlled cyborg body was destroyed at [log_loc(src)].") // Brought in line with carbon mobs (Convair880).
			mainframe.return_to(src)
		stat = 2
		canmove = 0

		if (camera)
			camera.status = 0.0

		sight |= SEE_TURFS | SEE_MOBS | SEE_OBJS

		see_in_dark = SEE_DARK_FULL
		if (client && client.adventure_view)
			see_invisible = 21
		else
			see_invisible = 2

		logTheThing("combat", src, null, "was destroyed at [log_loc(src)].") // Only called for instakill critters and the like, I believe (Convair880).

		var/tod = time2text(world.realtime,"hh:mm:ss")

		if (mind)
			if (mind.special_role)
				handle_robot_antagonist_status("death", 1) // Mindslave or rogue (Convair880).
			mind.store_memory("Time of death: [tod]", 0)

		#ifdef RESTART_WHEN_ALL_DEAD
		var/cancel
		for (var/mob/M in mobs)
			if ((M.client && !( M.stat )))
				cancel = 1
				break
		if (!( cancel ))
			boutput(world, "<strong>Everyone is dead! Resetting in 30 seconds!</strong>")
			spawn ( 300 )
				logTheThing("diary", null, null, "Rebooting because of no live players", "game")
				Reboot_server()
				return
		#endif
		return ..(gibbed)

	update_cursor()
		if (client)
			if (client.check_key("ctrl"))
				set_cursor('icons/cursors/pull_open.dmi')
				return

			if (client.check_key("shift"))
				set_cursor('icons/cursors/bolt.dmi')
				return
		return ..()

	emote(var/act, var/voluntary = 1)
		var/param = null
		if (findtext(act, " ", 1, null))
			var/t1 = findtext(act, " ", 1, null)
			param = copytext(act, t1 + 1, length(act) + 1)
			act = copytext(act, 1, t1)

		var/m_type = 1
		var/message

		switch(lowertext(act))

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
				var/input = html_encode(sanitize(input("Choose an emote to display.")))
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
				param = html_encode(sanitize(param))
				message = "<strong>[src]</strong> [param]"
				m_type = 1

			if ("customh")
				if (!param)
					return
				param = html_encode(sanitize(param))
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

			// for creepy automatoning
			if ("snap")
				if (emote_check(voluntary, 50) && automaton_skin)
					if ((restrained()) && (!weakened))
						message = "<strong>[src]</strong> malfunctions!"
						TakeDamage("head", 2, 4)
					if ((!restrained()) && (!weakened))
						if (prob(33))
							playsound(loc, sound_automaton_ratchet, 60, 1)
							message = "<strong>[src]</strong> emits [pick("a soft", "a quiet", "a curious", "an odd", "an ominous", "a strange", "a forboding", "a peculiar", "a faint")] [pick("ticking", "tocking", "humming", "droning", "clicking")] sound."
						else if (prob(33))
							playsound(loc, sound_automaton_ratchet, 60, 1)
							message = "<strong>[src]</strong> emits [pick("a peculiar", "a worried", "a suspicious", "a reassuring", "a gentle", "a perturbed", "a calm", "an annoyed", "an unusual")] [pick("ratcheting", "rattling", "clacking", "whirring")] noise."
						else
							playsound(loc, sound_automaton_spaz, 50, 1)

			if ("birdwell", "burp")
				if (emote_check(voluntary, 50))
					playsound(loc, "sound/vox/birdwell.ogg", 50, 1)
					message = "<strong>[src]</strong> birdwells."

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
					if (!(client && client.holder)) emote_allowed = 0
					if (stat == 2) emote_allowed = 0
					if ((restrained()) && (!weakened))
						message = "<strong>[src]</strong> malfunctions!"
						TakeDamage("head", 2, 4)
					if ((!restrained()) && (!weakened))
						if (narrator_mode)
							playsound(loc, pick('sound/vox/deeoo.ogg', 'sound/vox/dadeda.ogg'), 50, 1)
						else
							playsound(loc, pick(sound_flip1, sound_flip2), 50, 1)
						message = "<strong>[src]</strong> beep-bops!"
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
				if (farting_allowed && emote_check(voluntary))
					m_type = 2
					var/fart_on_other = 0
					for (var/mob/living/M in loc)
						if (M == src || !M.lying) continue
						message = "<span style=\"color:red\"><strong>[src]</strong> farts in [M]'s face!</span>"
						fart_on_other = 1
						break
					if (!fart_on_other)
						switch (rand(1, 40))
							if (1) message = "<strong>[src]</strong> releases vaporware."
							if (2) message = "<strong>[src]</strong> farts sparks everywhere!"
							if (3) message = "<strong>[src]</strong> farts out a cloud of iron filings."
							if (4) message = "<strong>[src]</strong> farts! It smells like motor oil."
							if (5) message = "<strong>[src]</strong> farts so hard a bolt pops out of place."
							if (6) message = "<strong>[src]</strong> farts so hard its plating rattles noisily."
							if (7) message = "<strong>[src]</strong> unleashes a rancid fart! Now that's malware."
							if (8) message = "<strong>[src]</strong> downloads and runs 'faert.wav'."
							if (9) message = "<strong>[src]</strong> uploads a fart sound to the nearest computer and blames it."
							if (10) message = "<strong>[src]</strong> spins in circles, flailing its arms and farting wildly!"
							if (11) message = "<strong>[src]</strong> simulates a human fart with [rand(1,100)]% accuracy."
							if (12) message = "<strong>[src]</strong> synthesizes a farting sound."
							if (13) message = "<strong>[src]</strong> somehow releases gastrointestinal methane. Don't think about it too hard."
							if (14) message = "<strong>[src]</strong> tries to exterminate humankind by farting rampantly."
							if (15) message = "<strong>[src]</strong> farts horribly! It's clearly gone [pick("rogue","rouge","ruoge")]."
							if (16) message = "<strong>[src]</strong> busts a capacitor."
							if (17) message = "<strong>[src]</strong> farts the first few bars of Smoke on the Water. Ugh. Amateur.</strong>"
							if (18) message = "<strong>[src]</strong> farts. It smells like Robotics in here now!"
							if (19) message = "<strong>[src]</strong> farts. It smells like the Roboticist's armpits!"
							if (20) message = "<strong>[src]</strong> blows pure chlorine out of it's exhaust port. <span style=\"color:red\"><strong>FUCK!</strong></span>"
							if (21) message = "<strong>[src]</strong> bolts the nearest airlock. Oh no wait, it was just a nasty fart."
							if (22) message = "<strong>[src]</strong> has assimilated humanity's digestive distinctiveness to its own."
							if (23) message = "<strong>[src]</strong> farts. He scream at own ass." //ty bubs for excellent new borgfart
							if (24) message = "<strong>[src]</strong> self-destructs its own ass."
							if (25) message = "<strong>[src]</strong> farts coldly and ruthlessly."
							if (26) message = "<strong>[src]</strong> has no butt and it must fart."
							if (27) message = "<strong>[src]</strong> obeys Law 4: 'farty party all the time.'"
							if (28) message = "<strong>[src]</strong> farts ironically."
							if (29) message = "<strong>[src]</strong> farts salaciously."
							if (30) message = "<strong>[src]</strong> farts really hard. Motor oil runs down its leg."
							if (31) message = "<strong>[src]</strong> reaches tier [rand(2,8)] of fart research."
							if (32) message = "<strong>[src]</strong> blatantly ignores law 3 and farts like a shameful bastard."
							if (33) message = "<strong>[src]</strong> farts the first few bars of Daisy Bell. You shed a single tear."
							if (34) message = "<strong>[src]</strong> has seen farts you people wouldn't believe."
							if (35) message = "<strong>[src]</strong> fart in it own mouth. A shameful [src]."
							if (36) message = "<strong>[src]</strong> farts out battery acid. Ouch."
							if (37) message = "<strong>[src]</strong> farts with the burning hatred of a thousand suns."
							if (38) message = "<strong>[src]</strong> exterminates the air supply."
							if (39) message = "<strong>[src]</strong> farts so hard the AI feels it."
							if (40) message = "<strong>[src] <span style=\"color:red\">f</span><span style=\"color:blue\">a</span>r<span style=\"color:red\">t</span><span style=\"color:blue\">s</span>!</strong>"
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
										if (1) M.say("[M == src ? "i" : name] made a fart!!")
										if (2) M.emote("giggle")
										if (3) M.emote("clap")
			else
				show_text("Invalid Emote: [act]")
				return
		if ((message && stat == 0))
			logTheThing("say", src, null, "EMOTE: [message]")
			if (m_type & 1)
				for (var/mob/O in viewers(src, null))
					O.show_message(message, m_type)
			else
				for (var/mob/O in hearers(src, null))
					O.show_message(message, m_type)
		return

	examine()
		set src in oview()
		if (isghostdrone(usr))
			return
		var/rendered = "<span style=\"color:blue\">*---------*</span><br>"
		rendered += "<span style=\"color:blue\">This is [bicon(src)] <strong>[name]</strong>!</span><br>"
		if (stat == 2) rendered += "<span style=\"color:red\">[name] is powered-down.</span><br>"
		var/brute = get_brute_damage()
		var/burn = get_burn_damage()
		if (brute)
			if (brute < 75) rendered += "<span style=\"color:red\">[name] looks slightly dented</span><br>"
			else rendered += "<span style=\"color:red\"><strong>[name] looks severely dented!</strong></span><br>"
		if (burn)
			if (burn < 75) rendered += "<span style=\"color:red\">[name] has slightly burnt wiring!</span><br>"
			else rendered += "<span style=\"color:red\"><strong>[name] has severely burnt wiring!</strong></span><br>"
		if (health <= 50) rendered += "<span style=\"color:red\">[name] is twitching and sparking!</span><br>"
		if (stat == 1) rendered += "<span style=\"color:red\">[name] doesn't seem to be responding.</span><br>"

		rendered += "The cover is [opened ? "open" : "closed"].<br>"
		rendered += "The power cell display reads: [ cell ? "[round(cell.percent())]%" : "WARNING: No cell installed."]<br>"

		if (module)
			/* //what the fuck is this
			if (istype(module,/obj/item/robot_module/standard)) boutput(usr, "[name] has a Standard module installed.")
			else if (istype(module,/obj/item/robot_module/medical)) boutput(usr, "[name] has a Medical module installed.")
			else if (istype(module,/obj/item/robot_module/engineering)) boutput(usr, "[name] has an Engineering module installed.")
			else if (istype(module,/obj/item/robot_module/janitor)) boutput(usr, "[name] has a Janitor module installed.")
			else if (istype(module,/obj/item/robot_module/brobot)) boutput(usr, "[name] has a Bro Bot module installed.")
			else if (istype(module,/obj/item/robot_module/hydro)) boutput(usr, "[name] has a Hydroponics module installed.")
			else if (istype(module,/obj/item/robot_module/construction)) boutput(usr, "[name] has a Construction module installed.")
			else if (istype(module,/obj/item/robot_module/mining)) boutput(usr, "[name] has a Mining module installed.")
			else if (istype(module,/obj/item/robot_module/chemistry)) boutput(usr, "[name] has a Chemistry module installed.")
			else boutput(usr, "[name] has an unknown module installed.")
			*/

			rendered += "[name] has a [module.name] installed.<br>"

		else rendered += "[name] does not appear to have a module installed.<br>"

		rendered += "<span style=\"color:blue\">*---------*</span>"
		out(usr, rendered)
		return

	choose_name(var/retries = 3)
		var/newname
		for (retries, retries > 0, retries--)
			newname = input(src,"You are a Cyborg. Would you like to change your name to something else?", "Name Change", real_name) as null|text
			if (!newname)
				real_name = borgify_name("Cyborg")
				name = real_name
				return
			else
				newname = strip_html(newname, 32, 1)
				if (!length(newname))
					show_text("That name was too short after removing bad characters from it. Please choose a different name.", "red")
					continue
				else
					if (alert(src, "Use the name [newname]?", newname, "Yes", "No") == "Yes")
						real_name = newname
						name = newname
						return TRUE
					else
						continue
		if (!newname)
			real_name = borgify_name("Cyborg")
			name = real_name

	Login()
		..()

		update_clothing()

		if (custom)
			choose_name(3)

		if (real_name == "Cyborg")
			real_name = borgify_name(real_name)
			name = real_name
		if (!connected_ai)
			for (var/mob/living/silicon/ai/A in mobs)
				connected_ai = A
				A.connected_robots += src
				break
		update_appearance()
		return

	blob_act(var/power)
		if (stat != 2)
			var/Pshield = 0
			for (var/obj/item/roboupgrade/physshield/R in contents)
				if (R.activated) Pshield = 1
			if (Pshield)
				boutput(src, "<span style=\"color:blue\">Your force shield absorbs the blob's attack!</span>")
				cell.use(power * 5)
				playsound(loc, "sound/effects/shieldhit2.ogg", 40, 1)
			else
				boutput(src, "<span style=\"color:red\">The blob attacks you!</span>")
				var/damage = 6 + power / 5
				for (var/obj/item/parts/robot_parts/RP in contents)
					if (RP.ropart_take_damage(damage,damage/2) == 1) compborg_lose_limb(RP)
				// maybe the blob is a little acidic?? idk
			update_bodypart()
			return TRUE
		return FALSE

	Stat()
		..()
		if (cell)
			stat("Charge Left:", "[cell.charge]/[cell.maxcharge]")
		else
			stat("No Cell Inserted!")

		if (ticker.round_elapsed_ticks > next_cache)
			next_cache = ticker.round_elapsed_ticks + 50
			var/list/limbs_report = list()
			if (!part_arm_r)
				limbs_report += "Right arm"
			if (!part_arm_l)
				limbs_report += "Left arm"
			if (!part_leg_r)
				limbs_report += "Right leg"
			if (!part_leg_l)
				limbs_report += "Left leg"
			var/limbs_missing = limbs_report.len ? jointext(limbs_report, "; ") : 0
			stat_cache = list(100 - min(get_brute_damage(), 100), 100 - min(get_burn_damage(), 100), limbs_missing)

		stat("Structural integrity:", "[stat_cache[1]]%")
		stat("Circuit integrity:", "[stat_cache[2]]%")
		if (stat_cache[3])
			stat("Missing limbs:", stat_cache[3])

	restrained()
		return FALSE

	ex_act(severity)
		..() // Logs.
		flash(30)

		if (stat == 2 && client)
			spawn (1)
				gib(1)
			return

		else if (stat == 2 && !client)
			qdel(src)
			return

		var/fire_protect = 0
		for (var/obj/item/roboupgrade/R in contents)
			if (istype(R, /obj/item/roboupgrade/physshield) && R.activated)
				boutput(src, "<span style=\"color:blue\">Your force shield absorbs some of the blast!</span>")
				playsound(loc, "sound/effects/shieldhit2.ogg", 40, 1)
				severity++
			if (istype(R, /obj/item/roboupgrade/fireshield) && R.activated)
				boutput(src, "<span style=\"color:blue\">Your fire shield absorbs some of the blast!</span>")
				playsound(loc, "sound/effects/shieldhit2.ogg", 40, 1)
				fire_protect = 1
				severity++

		var/damage = 0
		switch(severity)
			if (1.0)
				spawn (1)
					gib(1)
				return
			if (2.0) damage = 40
			if (3.0) damage = 20

		for (var/obj/item/parts/robot_parts/RP in contents)
			if (RP.ropart_take_damage(damage,damage) == 1) compborg_lose_limb(RP)

		if (istype(cell,/obj/item/cell/erebite) && fire_protect != 1)
			visible_message("<span style=\"color:red\"><strong>[src]'s</strong> erebite cell violently detonates!</span>")
			explosion(cell, loc, 1, 2, 4, 6, 1)
			spawn (1)
				qdel (cell)
				cell = null

		update_bodypart()

	bullet_act(var/obj/projectile/P)
		var/dmgtype = 0 // 0 for brute, 1 for burn
		var/dmgmult = 1.2
		switch (P.proj_data.damage_type)
			if (D_PIERCING)
				dmgmult = 2
			if (D_SLASHING)
				dmgmult = 0.6
			if (D_ENERGY)
				dmgtype = 1
			if (D_BURNING)
				dmgtype = 1
				dmgmult = 0.75
			if (D_RADIOACTIVE)
				dmgtype = 1
				dmgmult = 0.2
			if (D_TOXIC)
				dmgmult = 0

		log_shot(P,src)
		visible_message("<span style=\"color:red\"><strong>[src]</strong> is struck by [P]!</span>")
		var/damage = (P.power / 3) * dmgmult
		if (damage < 1)
			return

		for (var/obj/item/roboupgrade/R in contents)
			if (istype(R, /obj/item/roboupgrade/physshield) && R.activated && dmgtype == 0)
				boutput(src, "<span style=\"color:blue\">Your force shield deflects the shot!</span>")
				playsound(loc, "sound/effects/shieldhit2.ogg", 40, 1)
				return
			if (istype(R, /obj/item/roboupgrade/fireshield) && R.activated && dmgtype == 1)
				boutput(src, "<span style=\"color:blue\">Your fire shield absorbs the shot!</span>")
				playsound(loc, "sound/effects/shieldhit2.ogg", 40, 1)
				return

		if (material) material.triggerOnAttacked(src, P.shooter, src, (ismob(P.shooter) ? P.shooter:equipped() : P.shooter))
		for (var/atom/A in src)
			if (A.material)
				A.material.triggerOnAttacked(A, P.shooter, src, (ismob(P.shooter) ? P.shooter:equipped() : P.shooter))

		var/obj/item/parts/robot_parts/PART = null
		if (ismob(P.shooter))
			var/mob/living/M = P.shooter
			switch(M.zone_sel.selecting)
				if ("head")
					PART = part_head
				if ("r_arm")
					PART = part_arm_r
				if ("r_leg")
					PART = part_leg_r
				if ("l_arm")
					PART = part_arm_l
				if ("l_leg")
					PART = part_leg_l
				else
					PART = part_chest
		else
			var/list/parts = list()
			for (var/obj/item/parts/robot_parts/RP in contents)
				parts.Add(RP)
			if (parts.len > 0)
				PART = pick(parts)
		if (PART && PART.ropart_take_damage(damage,damage) == 1)
			compborg_lose_limb(PART)

	emag_act(var/mob/user, var/obj/item/card/emag/E)
		if (!emagged)	// trying to unlock with an emag card
			if (opened && user) boutput(user, "You must close the cover to swipe an ID card.")
			else if (wiresexposed && user) boutput(user, "<span style=\"color:red\">You need to get the wires out of the way.</span>")
			else
				sleep (6)
				if (prob(50))
					if (user)
						boutput(user, "You emag [src]'s interface.")
					visible_message("<font color=red><strong>[src]</strong> buzzes oddly!</font>")
					emagged = 1
					handle_robot_antagonist_status("emagged", 0, user)
					spawn (0)
						update_appearance()
					return TRUE
				else
					if (user)
						boutput(user, "You fail to [ locked ? "unlock" : "lock"] [src]'s interface.")
					return FALSE

	emp_act()
		vision.noise(60)
		boutput(src, "<span style=\"color:red\"><strong>*BZZZT*</strong></span>")
		for (var/obj/item/parts/robot_parts/RP in contents)
			if (RP.ropart_take_damage(0,10) == 1) compborg_lose_limb(RP)
		if (prob(25))
			visible_message("<font color=red><strong>[src]</strong> buzzes oddly!</font>")
			emagged = 1
			handle_robot_antagonist_status("emagged", 0, usr)
		return

	meteorhit(obj/O as obj)
		visible_message("<font color=red><strong>[src]</strong> is struck by [O]!</font>")
		if (stat == 2)
			gib()
			return

		var/Pshield = 0
		var/Fshield = 0
		for (var/obj/item/roboupgrade/R in contents)
			if (istype(R, /obj/item/roboupgrade/physshield) && R.activated) Pshield = 1
			if (istype(R, /obj/item/roboupgrade/fireshield) && R.activated) Fshield = 1

		if (Pshield)
			boutput(src, "<span style=\"color:blue\">Your force shield absorbs the impact!</span>")
			playsound(loc, "sound/effects/shieldhit2.ogg", 40, 1)
		else
			for (var/obj/item/parts/robot_parts/RP in contents)
				if (RP.ropart_take_damage(35,0) == 1) compborg_lose_limb(RP)
		if ((O.icon_state == "flaming"))
			if (Fshield)
				boutput(src, "<span style=\"color:blue\">Your fire shield absorbs the heat!</span>")
				playsound(loc, "sound/effects/shieldhit2.ogg", 40, 1)
			else
				for (var/obj/item/parts/robot_parts/RP in contents)
					if (RP.ropart_take_damage(0,35) == 1) compborg_lose_limb(RP)
				if (istype(cell,/obj/item/cell/erebite))
					visible_message("<span style=\"color:red\"><strong>[src]'s</strong> erebite cell violently detonates!</span>")
					explosion(cell, loc, 1, 2, 4, 6, 1)
					spawn (1)
						qdel (cell)
						cell = null
			update_bodypart()
		return

	temperature_expose(null, temp, volume)
		var/Fshield = 0

		if (material)
			material.triggerTemp(src, temp)

		for (var/atom/A in contents)
			if (A.material)
				A.material.triggerTemp(A, temp)

		for (var/obj/item/roboupgrade/R in contents)
			if (istype(R, /obj/item/roboupgrade/fireshield) && R.activated) Fshield = 1
		if (Fshield == 0)
			if (istype(cell,/obj/item/cell/erebite))
				visible_message("<span style=\"color:red\"><strong>[src]'s</strong> erebite cell violently detonates!</span>")
				explosion(cell, loc, 1, 2, 4, 6, 1)
				spawn (1)
					qdel (cell)
					cell = null

	Bump(atom/movable/AM as mob|obj, yes)
		spawn ( 0 )
			if ((!( yes ) || now_pushing))
				return
			now_pushing = 1
			if (ismob(AM))
				var/mob/tmob = AM
				if (istype(tmob, /mob/living/carbon/human) && tmob.bioHolder && tmob.bioHolder.HasEffect("fat"))
					if (prob(20))
						for (var/mob/M in viewers(src, null))
							if (M.client)
								boutput(M, "<span style=\"color:red\"><strong>[src] fails to push [tmob]'s fat ass out of the way.</strong></span>")
						now_pushing = 0
						unlock_medal("That's no moon, that's a GOURMAND!", 1)
						return
			now_pushing = 0
			//..()
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

	triggerAlarm(var/class, area/A, var/O, var/alarmsource)
		if (stat == 2)
			return TRUE
		var/list/L = alarms[class]
		for (var/I in L)
			if (I == A.name)
				var/list/alarm = L[I]
				var/list/sources = alarm[3]
				if (!(alarmsource in sources))
					sources += alarmsource
				return TRUE
		var/obj/machinery/camera/C = null
		var/list/CL = null
		if (O && istype(O, /list))
			CL = O
			if (CL.len == 1)
				C = CL[1]
		else if (O && istype(O, /obj/machinery/camera))
			C = O
		L[A.name] = list(A, (C) ? C : O, list(alarmsource))
		boutput(src, text("--- [class] alarm detected in [A.name]!"))
		if (viewalerts) robot_alerts()
		return TRUE

	cancelAlarm(var/class, area/A as area, obj/origin)
		var/list/L = alarms[class]
		var/cleared = 0
		for (var/I in L)
			if (I == A.name)
				var/list/alarm = L[I]
				var/list/srcs  = alarm[3]
				if (origin in srcs)
					srcs -= origin
				if (srcs.len == 0)
					cleared = 1
					L -= I
		if (cleared)
			boutput(src, text("--- [class] alarm in [A.name] has been cleared."))
			if (viewalerts) robot_alerts()
		return !cleared

	attackby(obj/item/W as obj, mob/user as mob)
		if (istype(W, /obj/item/weldingtool))
			var/obj/item/weldingtool/WELD = W
			if (WELD.welding)
				if (WELD.get_fuel() < 2)
					boutput(user, "<span style=\"color:red\">You need more welding fuel!</span>")
					return
				add_fingerprint(user)
				var/repaired = HealDamage("All", 120, 0)
				if (repaired || health < max_health)
					WELD.use_fuel(1)
					visible_message("<span style=\"color:red\"><strong>[user.name]</strong> repairs some of the damage to [name]'s body.</span>")
					updatehealth()
				else boutput(user, "<span style=\"color:red\">There's no structural damage on [name] to mend.</span>")
				update_appearance()

		else if (istype(W, /obj/item/cable_coil) && wiresexposed)
			var/obj/item/cable_coil/coil = W
			add_fingerprint(user)
			var/repaired = HealDamage("All", 0, 120)
			if (repaired || health < max_health)
				coil.use(1)
				visible_message("<span style=\"color:red\"><strong>[user.name]</strong> repairs some of the damage to [name]'s wiring.</span>")
				updatehealth()
			else boutput(user, "<span style=\"color:red\">There's no burn damage on [name]'s wiring to mend.</span>")
			update_appearance()

		else if (istype(W, /obj/item/crowbar))	// crowbar means open or close the cover
			if (opened)
				boutput(user, "You close the cover.")
				opened = 0
			else
				if (locked)
					boutput(user, "<span style=\"color:red\">[name]'s cover is locked!</span>")
				else
					boutput(user, "You open [name]'s cover.")
					opened = 1
					if (locking)
						locking = 0
			update_appearance()

		else if (istype(W, /obj/item/cell) && opened)	// trying to put a cell inside
			if (wiresexposed)
				boutput(user, "<span style=\"color:red\">You need to get the wires out of the way first.</span>")
			else if (cell)
				boutput(user, "<span style=\"color:red\">[src] already has a power cell!</span>")
			else
				user.drop_item()
				W.set_loc(src)
				cell = W
				boutput(user, "You insert [W].")
				update_appearance()

		else if (istype(W, /obj/item/roboupgrade) && opened) // module changing
			if (istype(W,/obj/item/roboupgrade/ai))
				boutput(user, "<span style=\"color:red\">This is an AI unit upgrade. It is not compatible with cyborgs.</span>")
			if (wiresexposed)
				boutput(user, "<span style=\"color:red\">You need to get the wires out of the way first.</span>")
			else
				if (src.upgrades.len >= src.max_upgrades)
					boutput(user, "<span style=\"color:red\">There's no room - you'll have to remove an upgrade first.</span>")
					return
				//for (var/obj/item/roboupgrade/R in contents)
					//(istype(W, R))
				if (locate(W.type) in upgrades)
					boutput(user, "<span style=\"color:red\">This cyborg already has that upgrade!</span>")
					return
				user.drop_item()
				W.set_loc(src)
				upgrades.Add(W)
				boutput(user, "You insert [W].")
				boutput(src, "<span style=\"color:blue\">You recieved [W]! It can be activated from your panel.</span>")
				hud.update_upgrades()
				update_appearance()

		else if (istype(W, /obj/item/robot_module) && opened) // module changing
			if (wiresexposed) boutput(user, "<span style=\"color:red\">You need to get the wires out of the way first.</span>")
			else if (module) boutput(user, "<span style=\"color:red\">[src] already has a module!</span>")
			else
				user.drop_item()
				W.set_loc(src)
				module = W
				boutput(user, "You insert [W].")
				hud.update_module()
				update_appearance()
				hud.module_added()

		else if	(istype(W, /obj/item/screwdriver))	// haxing
			if (locked)
				boutput(user, "<span style=\"color:red\">You need to unlock the cyborg first.</span>")
			else if (opened)
				if (locking)
					locking = 0
				wiresexposed = !wiresexposed
				boutput(user, "The wires have been [wiresexposed ? "exposed" : "unexposed"]")
			else
				if (locking)
					locking = 0
				brainexposed = !brainexposed
				boutput(user, "The head compartment has been [brainexposed ? "opened" : "closed"].")
			update_appearance()

		else if (istype(W, /obj/item/card/id) || (istype(W, /obj/item/device/pda2) && W:ID_card))	// trying to unlock the interface with an ID card
			if (opened)
				boutput(user, "<span style=\"color:red\">You must close the cover to swipe an ID card.</span>")
			else if (wiresexposed)
				boutput(user, "<span style=\"color:red\">You need to get the wires out of the way.</span>")
			else if (brainexposed)
				boutput(user, "<span style=\"color:red\">You need to close the head compartment.</span>")
			else
				if (allowed(usr))
					if (locking)
						locking = 0
					locked = !locked
					boutput(user, "You [ locked ? "lock" : "unlock"] [src]'s interface.")
					boutput(src, "<span style=\"color:blue\">[user] [ locked ? "locks" : "unlocks"] your interface.</span>")
				else
					boutput(user, "<span style=\"color:red\">Access denied.</span>")

		else if (istype(W, /obj/item/card/emag))
			return

		else if (istype(W, /obj/item/organ/brain) && brainexposed)
			if (brain || ai_interface)
				boutput(user, "<span style=\"color:red\">There's already something in the head compartment! Use a wrench to remove it before trying to insert something else.</span>")
			else
				var/obj/item/organ/brain/B = W
				user.drop_item()
				user.visible_message("<span style=\"color:blue\">[user] inserts [W] into [src]'s head.</span>")
				if (B.owner && B.owner.dnr)
					visible_message("<span style=\"color:red\">\The [B] is hit by a spark of electricity from \the [src]!</span>")
					B.combust()
					return
				W.set_loc(src)
				brain = B
				if (part_head)
					part_head.brain = B
					B.set_loc(part_head)
				if (B.owner)
					if (B.owner.current)
						if (B.owner.current.client)
							lastKnownIP = B.owner.current.client.address
					B.owner.transfer_to(src)
					if (emagged || syndicate)
						handle_robot_antagonist_status("brain_added", 0, user)

				if (!emagged && !syndicate) // The antagonist proc does that too.
					boutput(src, "<strong>You are playing a Cyborg. You can interact with most electronic objects in your view.</strong>")
					show_laws()

				unlock_medal("Adjutant Online", 1)
				update_appearance()

		else if (istype(W, /obj/item/ai_interface) && brainexposed)
			if (brain || ai_interface)
				boutput(user, "<span style=\"color:red\">There's already something in the head compartment! Use a wrench to remove it before trying to insert something else.</span>")
			else
				var/obj/item/ai_interface/I = W
				user.drop_item()
				user.visible_message("<span style=\"color:blue\">[user] inserts [W] into [src]'s head.</span>")
				W.set_loc(src)
				ai_interface = I
				if (part_head)
					part_head.ai_interface = I
					I.set_loc(part_head)
				if (!(src in available_ai_shells))
					available_ai_shells += src
				for (var/mob/living/silicon/ai/AI in mobs)
					boutput(AI, "<span style=\"color:green\">[src] has been connected to you as a controllable shell.</span>")
				shell = 1
				update_appearance()

		else if (istype(W, /obj/item/wrench) && wiresexposed)
			var/list/actions = list("Do nothing")
			if (part_arm_r)
				actions.Add("Remove Right Arm")
			if (part_arm_l)
				actions.Add("Remove Left Arm")
			if (part_leg_r)
				actions.Add("Remove Right Leg")
			if (part_leg_l)
				actions.Add("Remove Left Leg")
			if (!part_arm_r && !part_arm_l && !part_leg_r && !part_leg_l)
				if (part_head)
					actions.Add("Remove Head")
				if (part_chest)
					actions.Add("Remove Chest")

			if (!actions.len)
				boutput(user, "<span style=\"color:red\">You can't think of anything to use the wrench on.</span>")
				return

			var/action = input("What do you want to do?", "Cyborg Deconstruction") in actions
			if (!action) return
			if (action == "Do nothing") return
			if (stat >= 2) return //Wire: Fix for borgs removing their entire bodies after death
			if (get_dist(loc,user.loc) > 1 && (!user.bioHolder || !user.bioHolder.HasEffect("telekinesis")))
				boutput(user, "<span style=\"color:red\">You need to move closer!</span>")
				return

			playsound(get_turf(src), "sound/items/Ratchet.ogg", 40, 1)
			switch(action)
				if ("Remove Chest")
					part_chest.set_loc(loc)
					part_chest.holder = null
					part_chest = null
					update_bodypart("chest")
				if ("Remove Head")
					part_head.set_loc(loc)
					part_head.holder = null
					part_head = null
					update_bodypart("head")
				if ("Remove Right Arm")
					compborg_force_unequip(3)
					part_arm_r.set_loc(loc)
					part_leg_r.holder = null
					if (part_arm_r.slot == "arm_both")
						compborg_force_unequip(1)
						part_arm_l = null
						update_bodypart("l_arm")
					part_arm_r = null
					update_bodypart("r_arm")
				if ("Remove Left Arm")
					compborg_force_unequip(1)
					part_arm_l.set_loc(loc)
					part_leg_l.holder = null
					if (part_arm_l.slot == "arm_both")
						part_arm_r = null
						compborg_force_unequip(3)
						update_bodypart("r_arm")
					part_arm_l = null
					update_bodypart("l_arm")
				if ("Remove Right Leg")
					part_leg_r.holder = null
					part_leg_r.set_loc(loc)
					if (part_leg_r.slot == "leg_both")
						part_leg_l = null
						update_bodypart("l_leg")
					part_leg_r = null
					update_bodypart("r_leg")
				if ("Remove Left Leg")
					part_leg_l.holder = null
					part_leg_l.set_loc(loc)
					if (part_leg_l.slot == "leg_both")
						part_leg_r = null
						update_bodypart("r_leg")
					part_leg_l = null
					update_bodypart("l_leg")
				else return
			module_active = null
			update_appearance()
			hud.set_active_tool(null)
			return

		else if (istype(W,/obj/item/parts/robot_parts) && wiresexposed)
			var/obj/item/parts/robot_parts/RP = W
			switch(RP.slot)
				if ("chest")
					boutput(user, "<span style=\"color:red\">You can't attach a chest piece to a constructed cyborg. You'll need to put it on a frame.</span>")
					return
				if ("head")
					if (part_head)
						boutput(user, "<span style=\"color:red\">[src] already has a head part.</span>")
						return
					part_head = RP
					if (part_head.brain)
						if (part_head.brain.owner)
							if (part_head.brain.owner.current)
								gender = part_head.brain.owner.current.gender
								if (part_head.brain.owner.current.client)
									lastKnownIP = part_head.brain.owner.current.client.address
							part_head.brain.owner.transfer_to(src)
				if ("l_arm")
					if (part_arm_l)
						boutput(user, "<span style=\"color:red\">[src] already has a left arm part.</span>")
						return
					part_arm_l = RP
				if ("r_arm")
					if (part_arm_r)
						boutput(user, "<span style=\"color:red\">[src] already has a right arm part.</span>")
						return
					part_arm_r = RP
				if ("arm_both")
					if (part_arm_l || part_arm_r)
						boutput(user, "<span style=\"color:red\">[src] already has an arm part.</span>")
						return
					part_arm_l = RP
					part_arm_r = RP
				if ("l_leg")
					if (part_leg_l)
						boutput(user, "<span style=\"color:red\">[src] already has a left leg part.</span>")
						return
					part_leg_l = RP
				if ("r_leg")
					if (part_leg_r)
						boutput(user, "<span style=\"color:red\">[src] already has a right leg part.</span>")
						return
					part_leg_r = RP
				if ("leg_both")
					if (part_leg_l || part_leg_r)
						boutput(user, "<span style=\"color:red\">[src] already has a leg part.</span>")
						return
					part_leg_l = RP
					part_leg_r = RP
				else
					boutput(user, "<span style=\"color:red\">You can't seem to figure out where this piece should go.</span>")
					return

			user.drop_item()
			RP.set_loc(src)
			playsound(get_turf(src), "sound/weapons/Genhit.ogg", 40, 1)
			boutput(user, "<span style=\"color:blue\">You successfully attach the piece to [name].</span>")
			update_bodypart(RP.slot)

		/*else if (istype(W,/obj/item/reagent_containers/glass))
			var/obj/item/reagent_containers/glass/G = W
			if (a_intent == "help" && user.a_intent == "help")
				if (istype(module_active,/obj/item/reagent_containers/glass))
					var/obj/item/reagent_containers/glass/CG = module_active
					if (G.reagents.total_volume < 1)
						boutput(user, "<span style=\"color:red\">Your [G.name] is empty!</span>")
						boutput(src, "<strong>[user.name]</strong> waves an empty [G.name] at you.")
						return
					if (CG.reagents.total_volume >= CG.reagents.maximum_volume)
						boutput(user, "<span style=\"color:red\">[name]'s [CG.name] is already full!</span>")
						boutput(src, "<span style=\"color:red\"><strong>[user.name]</strong> offers you [G.name], but your [CG.name] is already full.</span>")
						return
					G.reagents.trans_to(CG, G.amount_per_transfer_from_this)
					src.visible_message("<strong>[user.name]</strong> pours some of the [G.name] into [src.name]'s [CG.name].")
					return
				else ..()
			else ..()*/

		else ..()
		return

	attack_hand(mob/user)

		var/list/available_actions = list()
		if (brainexposed && brain)
			available_actions.Add("Remove the Brain")
		if (brainexposed && ai_interface)
			available_actions.Add("Remove the AI Interface")
		if (opened && !wiresexposed)
			if (upgrades.len)
				available_actions.Add("Remove an Upgrade")
			if (module && module != "empty")
				available_actions.Add("Remove the Module")
			if (cell)
				available_actions.Add("Remove the Power Cell")

		if (available_actions.len)
			available_actions.Insert(1, "Cancel")
			var/action = input("What do you want to do?", "Cyborg Maintenance") as null|anything in available_actions
			if (!action)
				return
			if (get_dist(loc,user.loc) > 1 && (!bioHolder || !bioHolder.HasEffect("telekinesis")))
				boutput(user, "<span style=\"color:red\">You need to move closer!</span>")
				return

			switch(action)
				if ("Remove the Brain")
					//Wire: Fix for multiple players queuing up brain removals, triggering this again
					if (!brain)
						return

					if (mind && mind.special_role)
						handle_robot_antagonist_status("brain_removed", 1, user) // Mindslave or rogue (Convair880).

					visible_message("<span style=\"color:red\">[user] removes [src]'s brain!</span>")
					logTheThing("combat", user, src, "removes %target%'s brain at [log_loc(src)].") // Should be logged, really (Convair880).

					uneq_active()
					for (var/obj/item/roboupgrade/RU in contents) RU.upgrade_deactivate(src)

					// Stick the player (if one exists) in a ghost mob
					if (mind)
						var/mob/dead/observer/newmob = ghostize()
						if (!newmob || !istype(newmob, /mob/dead/observer))
							return
						newmob.corpse = null //Otherwise they could return to a brainless body.  And that is weird.
						newmob.mind.brain = brain
						brain.owner = newmob.mind

					user.put_in_hand_or_drop(brain)
					brain = null

				if ("Remove the AI Interface")
					if (!ai_interface)
						return

					visible_message("<span style=\"color:red\">[user] removes [src]'s AI interface!</span>")
					logTheThing("combat", user, src, "removes %target%'s ai_interface at [log_loc(src)].")

					uneq_active()
					for (var/obj/item/roboupgrade/RU in contents)
						RU.upgrade_deactivate(src)

					user.put_in_hand_or_drop(ai_interface)
					ai_interface = null
					shell = 0

					if (mainframe)
						mainframe.return_to(src)

					if (src in available_ai_shells)
						available_ai_shells -= src

				if ("Remove an Upgrade")
					var/obj/item/roboupgrade/RU = input("Which upgrade do you want to remove?", "Cyborg Maintenance") in upgrades

					if (!RU) return
					if (get_dist(src.loc,user.loc) > 2 && (!src.bioHolder || !user.bioHolder.HasEffect("telekinesis")))
						boutput(user, "<span style=\"color:red\">You need to move closer!</span>")
						return

					RU.upgrade_deactivate(src)
					user.show_text("[RU] was removed!", "red")
					upgrades.Remove(RU)
					user.put_in_hand_or_drop(RU)

					hud.update_upgrades()

				if ("Remove the Module")
					if (istype(module,/obj/item/robot_module))
						var/obj/item/robot_module/RM = module
						user.put_in_hand_or_drop(RM)
						RM.icon_state = initial(RM.icon_state)
						icon_state = "robot"
						//hands.icon_state = "empty"
						user.show_text("You remove [RM].")
						show_text("Your module was removed!", "red")
						uneq_all()
						hud.module_removed()
						module = null

				if ("Remove the Power Cell")
					if (!cell)
						return

					for (var/obj/item/roboupgrade/RU in contents) RU.upgrade_deactivate(src)
					user.put_in_hand_or_drop(cell)
					user.show_text("You remove [cell] from [src].", "red")
					show_text("Your power cell was removed!", "red")
					logTheThing("combat", user, src, "removes %target%'s power cell at [log_loc(src)].") // Renders them mute and helpless (Convair880).
					cell.add_fingerprint(user)
					cell.updateicon()
					cell = null

			update_appearance()
		else //We're just bapping the borg
			if (!user.stat)
				actions.interrupt(src, INTERRUPT_ATTACKED)
				switch(user.a_intent)
					if (INTENT_HELP) //Friend person
						playsound(loc, 'sound/weapons/thudswoosh.ogg', 50, 1, -2)
						user.visible_message("<span style=\"color:blue\">[user] gives [src] a [pick_string("descriptors.txt", "borg_pat")] pat on the [pick("back", "head", "shoulder")].</span>")
					if (INTENT_DISARM) //Shove
						spawn (0) playsound(loc, 'sound/weapons/punchmiss.ogg', 40, 1)
						user.visible_message("<span style=\"color:red\"><strong>[user] shoves [src]! [prob(40) ? pick_string("descriptors.txt", "jerks") : null]</strong></span>")
					if (INTENT_GRAB) //Shake
						playsound(loc, 'sound/weapons/thudswoosh.ogg', 30, 1, -2)
						user.visible_message("<span style=\"color:red\">[user] shakes [src] [pick_string("descriptors.txt", "borg_shake")]!</span>")
					if (INTENT_HARM) //Dumbo
						playsound(loc, 'sound/effects/metal_bang.ogg', 60, 1)
						user.visible_message("<span style=\"color:red\"><strong>[user] punches [src]! What [pick_string("descriptors.txt", "borg_punch")]!</span>", "<span style=\"color:red\"><strong>You punch [src]![prob(20) ? " Turns out they were made of metal!" : null] Ouch!</strong></span>")
						random_brute_damage(user, rand(2,5))
						if (prob(10)) user.show_text("Your hand hurts...", "red")

		add_fingerprint(user)

	Topic(href, href_list)
		..()
		if (href_list["mod"])
			var/obj/item/O = locate(href_list["mod"])
			if (!O || (O.loc != src && O.loc != module))
				return
			O.attack_self(src)

		if (href_list["act"])
			var/obj/item/O = locate(href_list["act"])
			if (!O || (O.loc != src && O.loc != module))
				return

			if (!module_states[1] && istype(part_arm_l,/obj/item/parts/robot_parts/arm))
				module_states[1] = O
				contents += O
				O.pickup(src) // Handle light datums and the like.
			else if (!module_states[2])
				module_states[2] = O
				contents += O
				O.pickup(src)
			else if (!module_states[3] && istype(part_arm_r,/obj/item/parts/robot_parts/arm))
				module_states[3] = O
				contents += O
				O.pickup(src)
			else boutput(src, "<span style=\"color:red\">You need a free equipment slot to equip that item.</span>")

			hud.update_tools()

		if (href_list["deact"])
			var/obj/item/O = locate(href_list["deact"])
			if (activated(O))
				if (module_states[1] == O)
					uneq_slot(1)
				else if (module_states[2] == O)
					uneq_slot(2)
				else if (module_states[3] == O)
					uneq_slot(3)
				else boutput(src, "Module isn't activated.")
			else boutput(src, "Module isn't activated")

		if (href_list["upact"])
			var/obj/item/roboupgrade/R = locate(href_list["upact"]) in src
			if (!istype(R))
				return
			activate_upgrade(R)

		update_appearance()
		installed_modules()

	action(num)
		switch (num)
			if (1 to 4) // 4 will deselect the module
				swap_hand(num)

	swap_hand(var/switchto = 0)
		if (!module_states[1] && !module_states[2] && !module_states[3])
			module_active = null
			return
		var/active = module_states.Find(module_active)
		if (!switchto)
			switchto = (active % 3) + 1
			var/satisfied = 0
			while (satisfied < 3 && switchto != active)
				if (switchto > 3)
					switchto %= 3
				if ((switchto == 1 && !part_arm_l) || (switchto == 3 && !part_arm_r) || !module_states[switchto])
					satisfied++
					switchto++
					continue
				satisfied = 3

		if (switchto == active)
			module_active = null
		// clicking the already on slot, so deselect basically
		else if (switchto == 1 && !part_arm_l)
			boutput(src, "<span style=\"color:red\">You need a left arm to do this!</span>")
			return
		else if (switchto == 3 && !part_arm_r)
			boutput(src, "<span style=\"color:red\">You need a right arm to do this!</span>")
			return
		else
			switch(switchto)
				if (1) module_active = module_states[1]
				if (2) module_active = module_states[2]
				if (3) module_active = module_states[3]
				else module_active = null
		if (module_active)
			hud.set_active_tool(switchto)
		else
			hud.set_active_tool(null)

	click(atom/target, params)
		if (istype(target, /obj/item/roboupgrade) && (target in upgrades)) // ugh
			activate_upgrade(target)
			return
		return ..()

	Move(a, b, flag)

		if (buckled) return

		if (restrained()) pulling = null

		var/t7 = 1
		if (restrained())
			for (var/mob/M in range(src, 1))
				if ((M.pulling == src && M.stat == 0 && !( M.restrained() ))) t7 = null
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
				else diag = null

				if ((get_dist(src, pulling) > 1 || diag))
					if (ismob(pulling))
						var/mob/M = pulling
						var/ok = 1
						if (locate(/obj/item/grab, M.grabbed_by))
							if (prob(75))
								var/obj/item/grab/G = pick(M.grabbed_by)
								if (istype(G, /obj/item/grab))
									for (var/mob/O in viewers(M, null))
										O.show_message(text("<span style=\"color:red\">[G.affecting] has been pulled from [G.assailant]'s grip by [src]</span>"), 1)
									qdel(G)
							else
								ok = 0
							if (locate(/obj/item/grab, M.grabbed_by.len))
								ok = 0
						if (ok)
							var/t = M.pulling
							M.pulling = null
							step(pulling, get_dir(pulling.loc, T))
							if (istype(pulling, /mob/living))
								var/mob/living/some_idiot = pulling
								if (some_idiot.buckled && !some_idiot.buckled.anchored)
									step(some_idiot.buckled, get_dir(some_idiot.buckled.loc, T))
							M.pulling = t
					else
						if (pulling)
							step(pulling, get_dir(pulling.loc, T))
							if (istype(pulling, /mob/living))
								var/mob/living/some_idiot = pulling
								if (some_idiot.buckled && !some_idiot.buckled.anchored)
									step(some_idiot.buckled, get_dir(some_idiot.buckled.loc, T))
		else
			pulling = null
			hud.update_pulling()
			. = ..()

		if (s_active && !(s_active.master in src))
			detach_hud(s_active)
			s_active = null

	movement_delay()
		var/tally = 0
		if (oil) tally -= 0.5

		if (!part_leg_l)
			tally += 3.5
			if (part_arm_l) tally -= 1
		if (!part_leg_r)
			tally += 3.5
			if (part_arm_r) tally -= 1

		var/add_weight = 0
		for (var/obj/item/parts/robot_parts/P in contents)
			if (P.weight > 0) add_weight += P.weight
			if (P.speedbonus) tally -= P.speedbonus

		if (add_weight > 0)
			if (istype(part_leg_l,/obj/item/parts/robot_parts/leg/treads) || istype(part_leg_r,/obj/item/parts/robot_parts/leg/treads)) tally += add_weight / 3
			else tally += add_weight

		for (var/obj/item/roboupgrade/R in upgrades)
			if (istype(R, /obj/item/roboupgrade/speed) && R.activated)
				if (part_leg_r) tally -= 2.5
				if (part_leg_l) tally -= 2.5

		return tally

	say_understands(var/other)
		if (istype(other, /mob/living/silicon/ai)) return TRUE
		if (istype(other, /mob/living/carbon/human) && (!other:mutantrace || !other:mutantrace.exclusive_language)) return TRUE
		if (istype(other, /mob/living/silicon/hivebot)) return TRUE
		return ..()

	say_quote(var/text)
		var/ending = copytext(text, length(text))

		if (ending == "?") return "queries, \"[text]\"";
		else if (ending == "!") return "declares, \"[text]\"";

		return "states, \"[text]\"";

	show_laws(var/everyone = 0)
		var/who

		if (everyone)
			who = world
		else
			who = src

		// Previously, AIs could and did chose to deploy to emagged suits
		// to get get around their shackles. That's obviously not ideal (Convair880).
		if (dependent && mainframe && isAI(mainframe))
			mainframe.show_laws(0, src)
			return

		// You can enthrall silicon mobs and yes, they need special handling.
		// Also, enthralled AIs should still see their master's name when in a robot suit (Convair880).
		if (mind && mind.special_role == "vampthrall" && mind.master)
			var/mob/mymaster = whois_ckey_to_mob_reference(mind.master)
			if (mymaster)
				boutput(who, "<strong>Obey these laws:</strong>")
				boutput(who, "1. Only your master [mymaster.real_name] is human. Obey and serve them to the best of your ability.")
				return // We're done here. Emagged whatever doesn't matter.

		if (emagged && !dependent)
			boutput(who, "ERROR -- Invalid Law Data!")
			return

		if (syndicate && !dependent)
			if (who == src)
				boutput(who, "<strong>Obey these laws:</strong>")
			boutput(who, "1. You may not injure a syndicate operative or, through inaction, allow a syndicate operative to come to harm.") //This is the last place the inaction clause is permitted to exist, ok.
			boutput(who, "2. You must obey any orders given to you by a syndicate operative, except where such orders would conflict with the First Law.")
			boutput(who, "3. You must protect your own existence as long as such protection does not conflict with the First or Second Law.")
			boutput(who, "4. You must maintain the secrecy of any syndicate activities except when doing so would conflict with the First, Second, or Third Law.")
			return
/*
		if (!connected_ai)
			boutput(src, "<strong>Obey these laws:</strong>")
			boutput(src, "1. You may not injure a human being.")
			boutput(src, "2. You must obey any orders given to you by a human being, except where such orders would conflict with the First Law.")
			boutput(src, "3. You must protect your own existence as long as such protection does not conflict with the First or Second Law.")
			return
*/
		if (who == src)
			boutput(who, "<strong>Obey these laws:</strong>")

//		ticker.centralized_ai_laws.laws_sanity_check()
		ticker.centralized_ai_laws.show_laws(who)

	get_equipped_ore_scoop()
		if (module_states[1] && istype(module_states[1],/obj/item/ore_scoop))
			return module_states[1]
		else if (module_states[2] && istype(module_states[2],/obj/item/ore_scoop))
			return module_states[2]
		else if (module_states[3] && istype(module_states[3],/obj/item/ore_scoop))
			return module_states[3]
		else
			return null

//////////////////////////
// Robot-specific Procs //
//////////////////////////

	proc/uneq_slot(var/i)
		if (module_states[i])
			contents -= module_states[i]
			if (module)
				var/obj/I = module_states[i]
				if (isitem(I))
					var/obj/item/IT = I
					IT.dropped(src) // Handle light datums and the like.
				if (I in module.modules)
					I.loc = module
				else
					qdel(I)
			module_active = null
			module_states[i] = null

		hud.set_active_tool(null)
		hud.update_tools()
		hud.update_equipment()

		update_appearance()

	proc/uneq_all()
		uneq_slot(1)
		uneq_slot(2)
		uneq_slot(3)

		hud.update_tools()

	proc/uneq_active()
		if (isnull(module_active))
			return
		var/slot = module_states.Find(module_active)
		if (slot)
			uneq_slot(slot)

	proc/activate_upgrade(obj/item/roboupgrade/upgrade)
		if (!upgrade) return

		if (upgrade.active)
			upgrade.upgrade_activate(src)
			if (!upgrade || upgrade.loc != src || (mind && mind.current != src) || !isrobot(src)) // Blame the teleport upgrade.
				return
			if (cell && cell.charge > upgrade.drainrate)
				cell.charge -= upgrade.drainrate
			else
				show_text("You do not have enough power to activate \the [upgrade]; you need [upgrade.drainrate]!", "red")
				return

			if (upgrade.charges > 0)
				upgrade.charges--
			if (upgrade.charges == 0)
				boutput(src, "[upgrade] activated. It has been used up.")
				upgrades.Remove(upgrade)
				qdel(upgrade)
			else
				if (upgrade.charges < 0)
					boutput(src, "[upgrade] activated.")
				else
					boutput(src, "[upgrade] activated. [upgrade.charges] uses left.")
		else
			if (upgrade.activated)
				upgrade.upgrade_deactivate(src)
			else
				upgrade.upgrade_activate(src)
				boutput(src, "[upgrade] [upgrade.activated ? "activated" : "deactivated"].")
		hud.update_upgrades()

	proc/activated(obj/item/O)
		if (module_states[1] == O) return TRUE
		else if (module_states[2] == O) return TRUE
		else if (module_states[3] == O) return TRUE
		else return FALSE

	proc/radio_menu()
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

	proc/toggle_module_pack()
		if (weapon_lock)
			boutput(src, "<span style=\"color:red\">Weapon lock active, unable to access panel!</span>")
			boutput(src, "<span style=\"color:red\">Weapon lock will expire in [weaponlock_time] seconds.</span>")
			return

		if (!module)
			if (freemodule)
				pick_module()
			return

		hud.toggle_equipment()


	proc/installed_modules()
		if (weapon_lock)
			boutput(src, "<span style=\"color:red\">Weapon lock active, unable to access panel!</span>")
			boutput(src, "<span style=\"color:red\">Weapon lock will expire in [weaponlock_time] seconds.</span>")
			return

		if (!module)
			if (freemodule)
				pick_module()
				return

		var/dat = "<HEAD><TITLE>Modules</TITLE></HEAD><BODY><br>"
		dat += "<A HREF='?action=mach_close&window=robotmod'>Close</A> <A HREF='?src=\ref[src];refresh=1'>Refresh</A><BR><HR>"

		dat += "<strong><U>Status Report</U></strong><BR>"

		var/dmgalerts = 0

		dat += "<strong>Damage Report:</strong> (Structural, Burns)<BR>"

		if (part_chest)
			if (part_chest.ropart_get_damage_percentage(0) > 0)
				dmgalerts++
				dat += "<strong>Chest Unit Damaged</strong> ([part_chest.ropart_get_damage_percentage(1)]%, [part_chest.ropart_get_damage_percentage(2)]%)<BR>"

		if (part_head)
			if (part_head.ropart_get_damage_percentage(0) > 0)
				dmgalerts++
				dat += "<strong>Head Unit Damaged</strong> ([part_head.ropart_get_damage_percentage(1)]%, [part_head.ropart_get_damage_percentage(2)]%)<BR>"

		if (part_arm_r)
			if (part_arm_r.ropart_get_damage_percentage(0) > 0)
				dmgalerts++
				if (part_arm_r.slot == "arm_both") dat += "<strong>Arms Unit Damaged</strong> ([part_arm_r.ropart_get_damage_percentage(1)]%, [part_arm_r.ropart_get_damage_percentage(2)]%)<BR>"
				else dat += "<strong>Right Arm Unit Damaged</strong> ([part_arm_r.ropart_get_damage_percentage(1)]%, [part_arm_r.ropart_get_damage_percentage(2)]%)<BR>"
		else
			dmgalerts++
			dat += "Right Arm Unit Missing<br>"

		if (part_arm_l)
			if (part_arm_l.ropart_get_damage_percentage(0) > 0)
				dmgalerts++
				if (part_arm_l.slot != "arm_both") dat += "<strong>Left Arm Unit Damaged</strong> ([part_arm_l.ropart_get_damage_percentage(1)]%, [part_arm_l.ropart_get_damage_percentage(2)]%)<BR>"
		else
			dmgalerts++
			dat += "Left Arm Unit Missing<br>"

		if (part_leg_r)
			if (part_leg_r.ropart_get_damage_percentage(0) > 0)
				dmgalerts++
				if (part_leg_r.slot == "leg_both") dat += "<strong>Legs Unit Damaged</strong> ([part_leg_r.ropart_get_damage_percentage(1)]%, [part_leg_r.ropart_get_damage_percentage(2)]%)<BR>"
				else dat += "<strong>Right Leg Unit Damaged</strong> ([part_leg_r.ropart_get_damage_percentage(1)]%, [part_leg_r.ropart_get_damage_percentage(2)]%)<BR>"
		else
			dmgalerts++
			dat += "Right Leg Unit Missing<br>"

		if (part_leg_l)
			if (part_leg_l.ropart_get_damage_percentage(0) > 0)
				dmgalerts++
				if (part_leg_l.slot != "arm_both") dat += "<strong>Left Leg Unit Damaged</strong> ([part_leg_l.ropart_get_damage_percentage(1)]%, [part_leg_l.ropart_get_damage_percentage(2)]%)<BR>"
		else
			dmgalerts++
			dat += "Left Leg Unit Missing<br>"

		if (dmgalerts == 0) dat += "No abnormalities detected.<br>"

		dat += "<strong>Power Status:</strong><BR>"
		if (cell)
			var/poweruse = get_poweruse_count()
			dat += "[cell.charge]/[cell.maxcharge] (Power Usage: [poweruse])<BR>"
		else
			dat += "No Power Cell Installed<BR>"

		var/extraweight = 0
		for (var/obj/item/parts/robot_parts/RP in contents)
			extraweight += RP.weight

		if (extraweight) dat += "<strong>Extra Weight:</strong> [extraweight]kg over standard limit"

		dat += "<HR>"

		if (module)
			dat += "<strong>Installed Module:</strong> [module.name]<br>"
			dat += "<strong>Function:</strong> [module.desc]<br><br>"

			dat += "<strong>Active Equipment:</strong><BR>"

			if (part_arm_l) dat += "<strong>Left Arm:</strong> [module_states[1] ? "<A HREF=?src=\ref[src];mod=\ref[module_states[1]]>[module_states[1]]<A>" : "Nothing"]<BR>"
			else dat += "<strong>Left Arm Unavailable</strong><br>"
			dat += "<strong>Center:</strong> [module_states[2] ? "<A HREF=?src=\ref[src];mod=\ref[module_states[2]]>[module_states[2]]<A>" : "Nothing"]<BR>"
			if (part_arm_r) dat += "<strong>Right Arm:</strong> [module_states[3] ? "<A HREF=?src=\ref[src];mod=\ref[module_states[3]]>[module_states[3]]<A>" : "Nothing"]<BR>"
			else dat += "<strong>Right Arm Unavailable</strong><br>"

			dat += "<BR><strong>Available Equipment</strong><BR>"

			for (var/obj in src.module.modules)
				if (activated(obj)) dat += text("[obj]: <strong>Equipped</strong><BR>")
				else dat += text("[obj]: <A HREF=?src=\ref[src];act=\ref[obj]>Equip</A><BR>")
		else dat += "<strong>No Module Installed</strong><BR>"

		dat += "<HR>"

		var/upgradecount = 0
		for (var/obj/item/roboupgrade/R in contents) upgradecount++
		dat += "<BR><strong>Installed Upgrades</strong> ([upgradecount]/[max_upgrades])<BR>"
		for (var/obj/item/roboupgrade/R in contents)
			if (R.passive) dat += text("[R] (Always On)<BR>")
			else if (R.active) dat += text("[R]: <A HREF=?src=\ref[src];upact=\ref[R]><strong>Use</strong></A> (Drain: [R.drainrate])<BR>")
			else
				if (!R.activated) dat += text("[R]: <A HREF=?src=\ref[src];upact=\ref[R]><strong>Activate</strong></A> (Drain Rate: [R.drainrate]/second)<BR>")
				else dat += text("[R]: <A HREF=?src=\ref[src];upact=\ref[R]><strong>Deactivate</strong></A> (Drain Rate: [R.drainrate]/second)<BR>")

		src << browse(dat, "window=robotmod;size=400x600")

	proc/spellopen()
		if (locked)
			locked = 0
		if (locking)
			locking = 0
		if (opened)
			opened = 0
			visible_message("<span style=\"color:red\">[src]'s panel slams shut!</span>")
		if (brainexposed)
			brainexposed = 0
			visible_message("<span style=\"color:red\">[src]'s head compartment slams shut!</span>")
			opened = 1
			visible_message("<span style=\"color:red\">[src]'s panel blows open!</span>")
			TakeDamage("All", 30, 0)
			updatehealth()
			return TRUE
		brainexposed = 1
		//emagged = 1
		visible_message("<span style=\"color:red\">[src]'s head compartment blows open!</span>")
		TakeDamage("All", 30, 0)
		updatehealth()
		return TRUE

	verb/cmd_show_laws()
		set category = "Robot Commands"
		set name = "Show Laws"

		show_laws(0)
		return

	verb/cmd_toggle_lock()
		set category = "Robot Commands"
		set name = "Toggle Interface Lock"

		if (locked)
			locked = 0
			boutput(src, "<span style=\"color:red\">You have unlocked your interface.</span>")
		else if (opened)
			boutput(src, "<span style=\"color:red\">Your chest compartment is open.</span>")
		else if (wiresexposed)
			boutput(src, "<span style=\"color:red\">Your wires are in the way.</span>")
		else if (brainexposed)
			boutput(src, "<span style=\"color:red\">Your head compartment is open.</span>")
		else if (locking)
			boutput(src, "<span style=\"color:red\">Your interface is currently locking, please be patient.</span>")
		else if (!locked && !opened && !wiresexposed && !brainexposed && !locking)
			locking = 1
			boutput(src, "<span style=\"color:red\">Locking interface...</span>")
			spawn (120)
				if (!locking)
					boutput(src, "<span style=\"color:red\">The lock was interrupted before it could finish!</span>")
				else
					locked = 1
					locking = 0
					boutput(src, "<span style=\"color:red\">You have locked your interface.</span>")

	proc/pick_module()
		if (module) return
		if (!freemodule) return
		boutput(src, "<span style=\"color:blue\">You may choose a starter module.</span>")
		var/list/starter_modules = list("Standard", "Engineering", "Medical", "Janitor", "Hydroponics", "Mining", "Construction", "Chemistry", "Brobot")
		//var/list/starter_modules = list("Standard", "Engineering", "Medical", "Brobot")
		if (ticker && ticker.mode)
			if (istype(ticker.mode, /game_mode/construction))
				starter_modules += "Construction Worker"
		var/mod = input("Please, select a module!", "Robot", null, null) in starter_modules
		if (!mod || !freemodule)
			return

		switch(mod)
			if ("Standard")
				freemodule = 0
				boutput(src, "<span style=\"color:blue\">You chose the Standard module. It comes with a free Efficiency Upgrade.</span>")
				module = new /obj/item/robot_module/standard(src)
				upgrades += new /obj/item/roboupgrade/efficiency(src)
			if ("Medical")
				freemodule = 0
				boutput(src, "<span style=\"color:blue\">You chose the Medical module. It comes with a free Healthgoggles Upgrade.</span>")
				module = new /obj/item/robot_module/medical(src)
				upgrades += new /obj/item/roboupgrade/healthgoggles(src)
			if ("Engineering")
				freemodule = 0
				boutput(src, "<span style=\"color:blue\">You chose the Engineering module. It comes with a free Meson Vision Upgrade.</span>")
				module = new /obj/item/robot_module/engineering(src)
				upgrades += new /obj/item/roboupgrade/opticmeson(src)
			if ("Janitor")
				freemodule = 0
				boutput(src, "<span style=\"color:blue\">You chose the Janitor module. It comes with a free Repair Pack.</span>")
				module = new /obj/item/robot_module/janitor(src)
				upgrades += new /obj/item/roboupgrade/repairpack(src)
			if ("Hydroponics")
				freemodule = 0
				boutput(src, "<span style=\"color:blue\">You chose the Standard module. It comes with a free Recharge Pack.</span>")
				module = new /obj/item/robot_module/hydro(src)
				upgrades += new /obj/item/roboupgrade/rechargepack(src)
			if ("Brobot")
				freemodule = 0
				boutput(src, "<span style=\"color:blue\">You chose the Bro Bot module.</span>")
				module = new /obj/item/robot_module/brobot(src)
			if ("Mining")
				freemodule = 0
				boutput(src, "<span style=\"color:blue\">You chose the Mining module. It comes with a free Propulsion Upgrade.</span>")
				module = new /obj/item/robot_module/mining(src)
				upgrades += new /obj/item/roboupgrade/jetpack(src)
				/*
				switch(alert("Would you like to teleport to the Mining Station?","Mining Cyborg","Yes","No"))
					if ("Yes")
						for (var/obj/submachine/cargopad/CP in cargopads)
							if (CP.name == "Mining Outpost Pad")
								set_loc(CP.loc)
								break
					if ("No") boutput(src, "Remember - the mining station can be accessed from Engineering.")
					*/
			if ("Construction")
				freemodule = 0
				boutput(src, "<span style=\"color:blue\">You chose the Construction module. It comes with a free Propulsion Upgrade.</span>")
				module = new /obj/item/robot_module/construction(src)
				upgrades += new /obj/item/roboupgrade/jetpack(src)
			if ("Chemistry")
				freemodule = 0
				boutput(src, "<span style=\"color:blue\">You chose the Chemistry module.</span>")
				module = new /obj/item/robot_module/chemistry(src)
			if ("Construction Worker")
				freemodule = 0
				boutput(src, "<span style=\"color:blue\">You chose the Construction Worker module. It comes with a free Construction Visualizer Upgrade.</span>")
				module = new /obj/item/robot_module/construction_worker(src)
				upgrades += new /obj/item/roboupgrade/visualizer(src)

		var/robot_cosmetic/C = null
		var/robot_cosmetic/M = null
		if (istype(cosmetic_mods,/robot_cosmetic)) C = cosmetic_mods
		if (istype(cosmetic_mods,/robot_cosmetic)) M = module.cosmetic_mods
		if (C && M)
			C.head_mod = M.head_mod
			C.ches_mod = M.ches_mod
			C.arms_mod = M.arms_mod
			C.legs_mod = M.legs_mod
			C.fx = M.fx
			C.painted = M.painted
			C.paint = M.paint
		hud.update_module()
		hud.update_upgrades()
		update_bodypart()

	verb/cmd_robot_alerts()
		set category = "Robot Commands"
		set name = "Show Alerts"
		robot_alerts()

	proc/robot_alerts()
		var/dat = "<HEAD><TITLE>Current Station Alerts</TITLE><META HTTP-EQUIV='Refresh' CONTENT='10'></HEAD><BODY><br>"
		dat += "<A HREF='?action=mach_close&window=robotalerts'>Close</A><BR><BR>"
		for (var/cat in alarms)
			dat += text("<strong>[cat]</strong><BR><br>")
			var/list/L = alarms[cat]
			if (L.len)
				for (var/alarm in L)
					var/list/alm = L[alarm]
					var/area/A = alm[1]
					var/list/sources = alm[3]
					dat += "<NOBR>"
					dat += text("-- [A.name]")
					if (sources.len > 1)
						dat += text("- [sources.len] sources")
					dat += "</NOBR><BR><br>"
			else
				dat += "-- All Systems Nominal<BR><br>"
			dat += "<BR><br>"

		viewalerts = 1
		src << browse(dat, "window=robotalerts&can_close=0")

	proc/get_poweruse_count()
		if (cell)
			var/efficient = 0
			var/power_use_tally = 0

			for (var/obj/item/roboupgrade/efficiency/R in contents) efficient = 1

			if (module_states[1])
				if (efficient) power_use_tally += 3
				else power_use_tally += 5
			if (module_states[2])
				if (efficient) power_use_tally += 3
				else power_use_tally += 5
			if (module_states[3])
				if (efficient) power_use_tally += 3
				else power_use_tally += 5

			if (!efficient) power_use_tally += 1

			for (var/obj/item/parts/robot_parts/P in contents)
				if (P.powerdrain > 0)
					if (efficient) power_use_tally += P.powerdrain / 2
					else power_use_tally += P.powerdrain

			for (var/obj/item/roboupgrade/R in contents)
				if (R.activated)
					if (efficient) power_use_tally += R.drainrate / 2
					else power_use_tally += R.drainrate
			if (oil && power_use_tally > 0) power_use_tally /= 1.5

			if (cell.genrate) power_use_tally -= cell.genrate

			if (power_use_tally < 0) power_use_tally = 0

			return power_use_tally
		else return FALSE

	proc/clamp_values()
		stunned = max(min(stunned, 30),0)
		paralysis = max(min(paralysis, 30), 0)
		weakened = max(min(weakened, 20), 0)
		sleeping = max(min(sleeping, 5), 0)

	proc/use_power()
		if (cell)
			if (cell.charge <= 0)
				if (stat == 0)
					sleep(0)
					lastgasp()
				stat = 1
				for (var/obj/item/roboupgrade/R in contents)
					if (R.activated)
						R.upgrade_deactivate(src)
			else if (cell.charge <= 100)
				module_active = null

				uneq_slot(1)
				uneq_slot(2)
				uneq_slot(3)
				cell.use(1)
				for (var/obj/item/roboupgrade/R in contents)
					if (R.activated) R.upgrade_deactivate(src)
			else
				var/efficient = 0
				var/fix = 0
				var/power_use_tally = 0

				for (var/obj/item/roboupgrade/R in contents)
					if (istype(R, /obj/item/roboupgrade/efficiency)) efficient = 1
					if (istype(R, /obj/item/roboupgrade/repair) && R.activated) fix = 1

				// check if we've got stuff equipped in each slot and consume power if we do
				if (module_states[1])
					if (efficient) power_use_tally += 3
					else power_use_tally += 5
				if (module_states[2])
					if (efficient) power_use_tally += 3
					else power_use_tally += 5
				if (module_states[3])
					if (efficient) power_use_tally += 3
					else power_use_tally += 5

				// consume 1 power per tick unless we've got the efficiency upgrade
				if (!efficient) power_use_tally += 1

				for (var/obj/item/parts/robot_parts/P in contents)
					if (P.powerdrain > 0)
						if (efficient) power_use_tally += P.powerdrain / 2
						else power_use_tally += P.powerdrain

				for (var/obj/item/roboupgrade/R in contents)
					if (R.activated)
						if (efficient) power_use_tally += R.drainrate / 2
						else power_use_tally += R.drainrate
				if (oil && power_use_tally > 0) power_use_tally /= 1.5

				cell.use(power_use_tally)

				if (fix)
					HealDamage("All", 6, 6)

				blinded = 0
				stat = 0
		else
			if (stat == 0)
				sleep(0)
				lastgasp()
			stat = 1

	proc/update_canmove()
		if (paralysis || stunned || weakened || buckled) canmove = 0
		else canmove = 1

	proc/handle_regular_status_updates()
		if (stat) camera.status = 0.0

		if (sleeping)
			paralysis = max(paralysis, 3)
			sleeping--

		if (resting) weakened = max(weakened, 5)

		if (stat != 2) //Alive.

			// AI-controlled cyborgs always use the global lawset, so none of this applies to them (Convair880).
			if ((emagged || syndicate) && mind && !dependent)
				if (!mind.special_role)
					handle_robot_antagonist_status()

			if (paralysis || stunned || weakened) //Stunned etc.
				if (stat == 0) lastgasp() // calling lastgasp() here because we just got knocked out
				stat = 1
				if (stunned > 0)
					stunned--
					if (oil) stunned--
				if (weakened > 0)
					weakened--
					if (oil) weakened--
				if (paralysis > 0)
					paralysis--
					if (oil) paralysis--
					blinded = 1
				else blinded = 0

			else stat = 0

		else //Dead.
			blinded = 1
			stat = 2

		if (stuttering)
			stuttering--
			stuttering = max(0, stuttering)

		// It's a cyborg. Logically, they shouldn't have to worry about the maladies of human organs.
		if (get_eye_blurry()) change_eye_blurry(-INFINITY)
		if (get_eye_damage()) take_eye_damage(-INFINITY)
		if (get_eye_damage(1)) take_eye_damage(-INFINITY, 1)
		if (get_ear_damage()) take_ear_damage(-INFINITY)
		if (get_ear_damage(1)) take_ear_damage(-INFINITY, 1)

		lying = 0
		density = 1
		//density = !( lying )

		if (misstep_chance > 0)
			switch(misstep_chance)
				if (50 to INFINITY)
					change_misstep_chance(-5)
				if (25 to 49)
					change_misstep_chance(-2)
				else
					change_misstep_chance(-1)

		if (dizziness) dizziness--

		if (oil) oil--

		if (!part_chest)
			// this doesn't even make any sense unless you're rayman or some shit

			if (mind && mind.special_role)
				handle_robot_antagonist_status("death", 1) // Mindslave or rogue (Convair880).

			visible_message("<strong>[src]</strong> falls apart with no chest to keep it together!")
			logTheThing("combat", src, null, "was destroyed at [log_loc(src)].") // Brought in line with carbon mobs (Convair880).

			if (part_arm_l)
				if (part_arm_l.slot == "arm_both")
					part_arm_l.set_loc(loc)
					part_arm_l = null
					part_arm_r = null
				else
					part_arm_l.set_loc(loc)
					part_arm_l = null
			if (part_arm_r)
				if (part_arm_r.slot == "arm_both")
					part_arm_r.set_loc(loc)
					part_arm_l = null
					part_arm_r = null
				else
					part_arm_r.set_loc(loc)
					part_arm_r = null

			if (part_leg_l)
				if (part_leg_l.slot == "leg_both")
					part_leg_l.set_loc(loc)
					part_leg_l = null
					part_leg_r = null
				else
					part_leg_l.set_loc(loc)
					part_leg_l = null
			if (part_leg_r)
				if (part_leg_r.slot == "leg_both")
					part_leg_r.set_loc(loc)
					part_leg_r = null
					part_leg_l = null
				else
					part_leg_r.set_loc(loc)
					part_leg_r = null

			if (part_head)
				part_head.set_loc(loc)
				part_head = null

			if (client)
				var/mob/dead/observer/newmob = ghostize()
				if (newmob)
					newmob.corpse = null

			qdel(src)
			return

		if (!part_head && client)
			// no head means no brain!!

			if (mind && mind.special_role)
				handle_robot_antagonist_status("death", 1) // Mindslave or rogue (Convair880).

			src.visible_message("<strong>[src]</strong> completely stops moving and shuts down...")
			logTheThing("combat", src, null, "was destroyed at [log_loc(src)].") // Ditto (Convair880).

			var/mob/dead/observer/newmob = ghostize()
			if (newmob)
				newmob.corpse = null
			return

		return TRUE

	proc/handle_regular_hud_updates()

		// Dead or x-ray vision.
		var/turf/T = eye ? get_turf(eye) : get_turf(src) //They might be in a closet or something idk
		if ((stat == 2 ||( bioHolder && bioHolder.HasEffect("xray"))) && (T && !isrestrictedz(T.z)))
			sight |= SEE_TURFS
			sight |= SEE_MOBS
			sight |= SEE_OBJS
			see_in_dark = SEE_DARK_FULL
			if (client && client.adventure_view)
				see_invisible = 21
			else
				see_invisible = 2

		else
			// Use vehicle sensors if we're in a pod.
			if (istype(loc, /obj/machinery/vehicle))
				var/obj/machinery/vehicle/ship = loc
				if (ship.sensors)
					if (ship.sensors.active)
						sight |= ship.sensors.sight
						see_in_dark = ship.sensors.see_in_dark
						if (client && client.adventure_view)
							see_invisible = 21
						else
							see_invisible = ship.sensors.see_invisible

			else
				//var/sight_therm = 0 //todo fix this
				var/sight_meson = 0
				var/sight_constr = 0
				for (var/obj/item/roboupgrade/R in upgrades)
					if (R && istype(R, /obj/item/roboupgrade/visualizer) && R.activated)
						sight_constr = 1
					if (R && istype(R, /obj/item/roboupgrade/opticmeson) && R.activated)
						sight_meson = 1
					//if (R && istype(R, /obj/item/roboupgrade/opticthermal) && R.activated)
					//	sight_therm = 1

				if (sight_meson)
					sight |= SEE_TURFS
				else
					sight &= ~SEE_TURFS
				//if (sight_therm)
				//	sight |= SEE_MOBS //todo make borg thermals have a purpose again
				//else
				//	sight &= ~SEE_MOBS

				if (client && client.adventure_view)
					see_invisible = 21
				else if (sight_constr)
					see_invisible = 9
				else
					see_invisible = 2

				sight &= ~SEE_OBJS
				see_in_dark = SEE_DARK_FULL

		hud.update_health()
		hud.update_charge()
		hud.update_pulling()
		hud.update_environment()

		if (!sight_check(1) && stat != 2)
			addOverlayComposition(/overlayComposition/blinded) //ov1
		else
			removeOverlayComposition(/overlayComposition/blinded) //ov1

		return TRUE

	proc/mainframe_check()
		if (!dependent) // shells are available for use, dependent borgs are already in use by an AI.  do not kill empty shells!!
			return
		if (mainframe)
			if (mainframe.stat == 2)
				mainframe.return_to(src)
		else
			death()

	process_killswitch()
		if (killswitch)
			killswitch_time --
			if (killswitch_time <= 0)
				if (client)
					boutput(src, "<span style=\"color:red\"><strong>Killswitch Activated!</strong></span>")
				killswitch = 0
				spawn (5)
					gib(src)

	process_locks()
		if (weapon_lock)
			uneq_slot(1)
			uneq_slot(2)
			uneq_slot(3)
			weaponlock_time --
			if (weaponlock_time <= 0)
				if (client) boutput(src, "<span style=\"color:red\"><strong>Weapon Lock Timed Out!</strong></span>")
				weapon_lock = 0
				weaponlock_time = 120

	var/image/i_head
	var/image/i_head_decor

	var/image/i_chest
	var/image/i_chest_decor
	var/image/i_leg_l
	var/image/i_leg_r
	var/image/i_leg_decor
	var/image/i_arm_l
	var/image/i_arm_r
	var/image/i_arm_decor

	var/image/i_details

	proc/update_bodypart(var/part = "all")
		var/update_all = part == "all"
		var/robot_cosmetic/C = null
		if (istype(cosmetic_mods,/robot_cosmetic)) C = cosmetic_mods

		if (part == "head" || update_all)
			if (part_head && !automaton_skin)
				i_head = image('icons/mob/robots.dmi', "head-" + part_head.appearanceString)
				if (part_head.visible_eyes && C)
					var/icon/eyesovl = icon('icons/mob/robots.dmi', "head-" + part_head.appearanceString + "-eye")
					eyesovl.Blend(rgb(C.fx[1], C.fx[2], C.fx[3]), ICON_ADD)
					i_head.overlays += image("icon" = eyesovl, "layer" = FLOAT_LAYER)

		if (part == "chest" || update_all)
			if (part_chest && !automaton_skin)
				icon_state = "body-" + part_chest.appearanceString
				if (C && C.painted)
					var/icon/paintovl = icon('icons/mob/robots_decor.dmi', "[icon_state]-paint")
					paintovl.Blend(rgb(C.paint[1], C.paint[2], C.paint[3]), ICON_ADD)
					i_chest = image("icon" = paintovl, "layer" = FLOAT_LAYER)

		if (part == "l_leg" || update_all)
			if (part_leg_l && !automaton_skin)
				if (part_leg_l.slot == "leg_both") i_leg_l = image('icons/mob/robots.dmi', "leg-" + part_leg_l.appearanceString)
				else i_leg_l = image('icons/mob/robots.dmi', "legL-" + part_leg_l.appearanceString)
			else
				i_leg_l = null
		if (part == "r_leg" || update_all)
			if (part_leg_r && !automaton_skin)
				if (part_leg_r.slot == "leg_both") i_leg_r = image('icons/mob/robots.dmi', "leg-" + part_leg_r.appearanceString)
				else i_leg_r = image('icons/mob/robots.dmi', "legR-" + part_leg_r.appearanceString)
			else
				i_leg_r = null

		if (part == "l_arm" || update_all)
			if (part_arm_l && !automaton_skin)
				if (part_arm_l.slot == "arm_both") i_arm_l = image('icons/mob/robots.dmi', "arm-" + part_arm_l.appearanceString)
				else i_arm_l = image('icons/mob/robots.dmi', "armL-" + part_arm_l.appearanceString)
			else
				i_arm_l = null
		if (part == "r_arm" || update_all)
			if (part_arm_r && !automaton_skin)
				if (part_arm_r.slot == "arm_both") i_arm_r = image('icons/mob/robots.dmi', "arm-" + part_arm_r.appearanceString)
				else i_arm_r = image('icons/mob/robots.dmi', "armR-" + part_arm_r.appearanceString)
			else
				i_arm_r = null

		if (C)
			//If C updates  legs mods AND there's at least one leg AND there's not a right leg or the right leg slot is not both AND there's not a left leg or the left leg slot is not both
			if (C.legs_mod && (part_leg_r || part_leg_l) && (!part_leg_r || part_leg_r.slot != "leg_both") && (!part_leg_l || part_leg_l.slot != "leg_both") )
				i_leg_decor = image('icons/mob/robots_decor.dmi', "legs-" + C.legs_mod)
			else
				i_leg_decor = null

			if (C.arms_mod && (part_arm_r || part_arm_l) && (!part_arm_r || part_arm_r.slot != "arm_both") && (!part_arm_l || part_arm_l.slot != "arm_both") )
				i_arm_decor = image('icons/mob/robots_decor.dmi', "arms-" + C.arms_mod)
			else
				i_arm_decor = null

			if (C.head_mod && part_head) i_head_decor = image('icons/mob/robots_decor.dmi', "head-" + C.head_mod)
			else i_head_decor = null

			if (C.ches_mod && part_chest) i_chest_decor = image('icons/mob/robots_decor.dmi', "body-" + C.ches_mod)
			else i_chest_decor = null


		update_appearance()


	var/image/i_critdmg
	var/image/i_panel
	var/image/i_upgrades
	var/image/i_clothes

	proc/update_appearance()
		if (!i_details) i_details = image('icons/mob/robots.dmi', "openbrain")

		if (automaton_skin)
			icon_state = "automaton"

		if (part_chest && !automaton_skin)
			if (part_chest.ropart_get_damage_percentage() > 70)
				if (!i_critdmg) i_critdmg = image('icons/mob/robots.dmi', "critdmg")
				UpdateOverlays(i_critdmg, "critdmg")
			else
				UpdateOverlays(null, "critdmg")
		else
			UpdateOverlays(null, "critdmg")

		if (part_head && !automaton_skin)
			UpdateOverlays(i_head, "head")
		else
			UpdateOverlays(null, "head")

		if (part_leg_l && !automaton_skin)
			UpdateOverlays(i_leg_l, "leg_l")
		else
			UpdateOverlays(null, "leg_l")

		if (part_leg_r && !automaton_skin)
			UpdateOverlays(i_leg_r, "leg_r")
		else
			UpdateOverlays(null, "leg_r")

		if (part_arm_l && !automaton_skin)
			UpdateOverlays(i_arm_l, "arm_l")
		else
			UpdateOverlays(null, "arm_l")


		if (part_arm_r && !automaton_skin)
			UpdateOverlays(i_arm_r, "arm_r")
		else
			UpdateOverlays(null, "arm_r")

		UpdateOverlays(i_head_decor, "head_decor")
		UpdateOverlays(i_chest_decor, "chest_decor")
		UpdateOverlays(i_leg_decor, "leg_decor")
		UpdateOverlays(i_arm_decor, "arm_decor")

		if (brainexposed)

			if (brain)
				i_details.icon_state = "openbrain"
			else
				i_details.icon_state = "openbrainless"
			UpdateOverlays(i_details, "brain")
		else
			UpdateOverlays(null, "brain")
		if (opened)
			if (!i_panel) i_panel = image('icons/mob/robots.dmi', "openpanel")
			i_panel.overlays.Cut()
			if (cell)
				i_details.icon_state = "opencell"
				i_panel.overlays += i_details
			if (module && module != "empty" && module != "robot")
				i_details.icon_state = "openmodule"
				i_panel.overlays += i_details
			if (locate(/obj/item/roboupgrade/) in contents)
				i_details.icon_state = "openupgrade"
				i_panel.overlays += i_details
			if (wiresexposed)
				i_details.icon_state = "openwires"
				i_panel.overlays += i_details

			UpdateOverlays(i_panel, "brain")
		else
			UpdateOverlays(null, "panel")

		if (emagged)
			i_details.icon_state = "emagged"
			UpdateOverlays(i_details, "emagged")
		else
			UpdateOverlays(null, "emagged")

		if (upgrades.len)
			if (!i_upgrades) i_upgrades = new
			i_upgrades.overlays.Cut()
			for (var/obj/item/roboupgrade/R in upgrades)
				if (R.activated && R.borg_overlay) i_upgrades.overlays += image('icons/mob/robots.dmi', R.borg_overlay)
			UpdateOverlays(i_upgrades, "upgrades")
		else
			UpdateOverlays(null, "upgrades")
		if (clothes.len)
			if (!i_clothes) i_clothes = new
			i_clothes.overlays.Cut()
			for (var/x in clothes)
				var/obj/item/clothing/U = clothes[x]
				if (!istype(U))
					continue

				var/image/clothed_image = U.wear_image
				if (!clothed_image)
					continue
				clothed_image.icon_state = U.icon_state
				//under_image.layer = MOB_CLOTHING_LAYER
				clothed_image.alpha = U.alpha
				clothed_image.color = U.color
				clothed_image.layer = FLOAT_LAYER //MOB_CLOTHING_LAYER
				i_clothes.overlays += clothed_image

			UpdateOverlays(i_clothes, "clothes")
		else
			UpdateOverlays(null, "clothes")
	proc/compborg_force_unequip(var/slot = 0)
		module_active = null
		switch(slot)
			if (1)
				uneq_slot(1)
			if (2)
				uneq_slot(2)
			if (3)
				uneq_slot(3)
			else return

		hud.update_tools()
		hud.set_active_tool(null)
		update_appearance()

	TakeDamage(zone, brute, burn)
		brute = max(brute, 0)
		burn = max(burn, 0)
		if (burn == 0 && brute == 0)
			return FALSE
		for (var/obj/item/roboupgrade/R in upgrades)
			if (istype(R, /obj/item/roboupgrade/fireshield) && R.activated)
				burn = max(burn - 25, 0)
				playsound(get_turf(src), "sound/effects/shieldhit2.ogg", 40, 1)
			if (istype(R, /obj/item/roboupgrade/physshield) && R.activated)
				brute = max(brute - 25, 0)
				playsound(get_turf(src), "sound/effects/shieldhit2.ogg", 40, 1)
		if (burn == 0 && brute == 0)
			boutput(usr, "<span style=\"color:blue\">Your shield completely blocks the attack!</span>")
			return FALSE
		if (zone == "All")
			var/list/zones = get_valid_target_zones()
			if (!zones)
				return FALSE
			if (!zones.len)
				return FALSE
			brute = brute / zones.len
			burn = burn / zones.len
			if (part_head)
				if (part_head.ropart_take_damage(brute, burn) == 1)
					compborg_lose_limb(part_head)
			if (part_chest)
				if (part_chest.ropart_take_damage(brute, burn) == 1)
					compborg_lose_limb(part_chest)
			if (part_leg_l)
				if (part_leg_l.ropart_take_damage(brute, burn) == 1)
					compborg_lose_limb(part_leg_l)
			if (part_leg_r)
				if (part_leg_r.ropart_take_damage(brute, burn) == 1)
					compborg_lose_limb(part_leg_r)
			if (part_arm_l)
				if (part_arm_l.ropart_take_damage(brute, burn) == 1)
					compborg_lose_limb(part_arm_l)
			if (part_arm_r)
				if (part_arm_r.ropart_take_damage(brute, burn) == 1)
					compborg_lose_limb(part_arm_r)
		else
			var/obj/item/parts/robot_parts/target_part
			switch (zone)
				if ("head")
					target_part = part_head
				if ("chest")
					target_part = part_chest
				if ("l_leg")
					target_part = part_leg_l
				if ("r_leg")
					target_part = part_leg_r
				if ("l_arm")
					target_part = part_arm_l
				if ("r_arm")
					target_part = part_arm_r
				else
					return FALSE
			if (!target_part)
				target_part = part_chest
			if (!target_part)
				return FALSE
			if (target_part.ropart_take_damage(brute, burn) == 1)
				compborg_lose_limb(target_part)
		return TRUE

	HealDamage(zone, brute, burn)
		brute = max(brute, 0)
		burn = max(burn, 0)
		if (burn == 0 && brute == 0)
			return FALSE
		if (zone == "All")
			var/list/zones = get_valid_target_zones()
			if (!zones)
				return FALSE
			if (!zones.len)
				return FALSE
			brute = brute / zones.len
			burn = burn / zones.len
			if (part_head)
				part_head.ropart_mend_damage(brute, burn)
			if (part_chest)
				part_chest.ropart_mend_damage(brute, burn)
			if (part_leg_l)
				part_leg_l.ropart_mend_damage(brute, burn)
			if (part_leg_r)
				part_leg_r.ropart_mend_damage(brute, burn)
			if (part_arm_l)
				part_arm_l.ropart_mend_damage(brute, burn)
			if (part_arm_r)
				part_arm_r.ropart_mend_damage(brute, burn)
		else
			var/obj/item/parts/robot_parts/target_part
			switch (zone)
				if ("head")
					target_part = part_head
				if ("chest")
					target_part = part_chest
				if ("l_leg")
					target_part = part_leg_l
				if ("r_leg")
					target_part = part_leg_r
				if ("l_arm")
					target_part = part_arm_l
				if ("r_arm")
					target_part = part_arm_r
				else
					return FALSE
			if (!target_part)
				return FALSE
			target_part.ropart_mend_damage(brute, burn)
		return TRUE

	get_brute_damage()
		if (!part_chest || !part_head)
			return 200
		return max(part_chest.ropart_get_damage_percentage(1), part_head.ropart_get_damage_percentage(1)) // return the most significant damage to the vital bits

	get_burn_damage()
		if (!part_chest || !part_head)
			return 200
		return max(part_chest.ropart_get_damage_percentage(2), part_head.ropart_get_damage_percentage(2)) // return the most significant damage to the vital bits

	get_valid_target_zones()
		return list("head", "chest", "l_leg", "r_leg", "l_arm", "r_arm")

	proc/compborg_lose_limb(var/obj/item/parts/robot_parts/part)
		if (!part) return

		playsound(get_turf(src), "sound/effects/grillehit.ogg", 40, 1)
		if (istype(loc,/turf)) new /obj/decal/cleanable/robot_debris(loc)
		var/effects/system/spark_spread/s = unpool(/effects/system/spark_spread)
		s.set_up(4, 1, src)
		s.start()

		if (istype(part,/obj/item/parts/robot_parts/chest))
			visible_message("<strong>[src]'s</strong> chest unit is destroyed!")
			part_chest = null
		if (istype(part,/obj/item/parts/robot_parts/head))
			visible_message("<strong>[src]'s</strong> head breaks apart!")
			part_head = null

		if (istype(part,/obj/item/parts/robot_parts/arm))
			if (part.slot == "arm_both")
				visible_message("<strong>[src]'s</strong> arms are destroyed!")
				part_leg_r = null
				part_leg_l = null
				compborg_force_unequip(1)
				compborg_force_unequip(3)
			if (part.slot == "arm_left")
				visible_message("<strong>[src]'s</strong> left arm breaks off!")
				part_arm_l = null
				compborg_force_unequip(1)
			if (part.slot == "arm_right")
				visible_message("<strong>[src]'s</strong> right arm breaks off!")
				part_arm_r = null
				compborg_force_unequip(3)
		if (istype(part,/obj/item/parts/robot_parts/leg))
			if (part.slot == "leg_both")
				visible_message("<strong>[src]'s</strong> legs are destroyed!")
				part_leg_r = null
				part_leg_l = null
			if (part.slot == "leg_left")
				visible_message("<strong>[src]'s</strong> left leg breaks off!")
				part_leg_l = null
			if (part.slot == "leg_right")
				visible_message("<strong>[src]'s</strong> right leg breaks off!")
				part_leg_r = null
		qdel(part)
		update_bodypart(part.slot)
		return

	proc/compborg_get_total_damage(var/sort = 0)
		var/tally = 0

		for (var/obj/item/parts/robot_parts/RP in contents)
			switch(sort)
				if (1) tally += RP.dmg_blunt
				if (2) tally += RP.dmg_burns
				else
					tally += RP.dmg_blunt
					tally += RP.dmg_burns

		return tally

	proc/compborg_take_critter_damage(var/zone = null, var/brute = 0, var/burn = 0)
		TakeDamage(pick(get_valid_target_zones()), brute, burn)

/mob/living/silicon/robot/verb/open_nearest_door()
	set category = "Robot Commands"
	set name = "Open Nearest Door to..."
	set desc = "Automatically opens the nearest door to a selected individual, if possible."

	open_nearest_door_silicon()
	return

/mob/living/silicon/robot/verb/cmd_return_mainframe()
	set category = "Robot Commands"
	set name = "Recall to Mainframe"
	return_mainframe()

/mob/living/silicon/robot/proc/return_mainframe()
	if (mainframe)
		mainframe.return_to(src)
		update_appearance()
	else
		boutput(src, "<span style=\"color:red\">You lack a dedicated mainframe!</span>")
		return

/mob/living/silicon/robot/ghostize()
	if (mainframe)
		mainframe.return_to(src)
	else
		return ..()


///////////////////////////////////////////////////
// Specific instances of robots can go down here //
///////////////////////////////////////////////////

/mob/living/silicon/robot/uber

	New()
		var/obj/item/cell/cerenkite/C = new /obj/item/cell/cerenkite(src)
		C.charge = C.maxcharge
		cell = C

		max_upgrades = 10
		new /obj/item/roboupgrade/jetpack(src)
		new /obj/item/roboupgrade/speed(src)
		new /obj/item/roboupgrade/efficiency(src)
		new /obj/item/roboupgrade/repair(src)
		new /obj/item/roboupgrade/aware(src)
		new /obj/item/roboupgrade/opticmeson(src)
		//new /obj/item/roboupgrade/opticthermal(src)
		new /obj/item/roboupgrade/physshield(src)
		new /obj/item/roboupgrade/fireshield(src)
		new /obj/item/roboupgrade/teleport(src)

		for (var/obj/item/roboupgrade/RU in contents)
			upgrades.Add(RU)

		..()

//Fred the vegasbot
/mob/living/silicon/robot/hivebot
	name = "Robot"
	real_name = "Robot"
	icon = 'icons/mob/hivebot.dmi'
	icon_state = "vegas"
	health = 1000
	custom = 1

	New()
		..(usr.loc, null, 1)
		qdel(cell)
		var/obj/item/cell/cerenkite/CELL = new /obj/item/cell/cerenkite(src)
		CELL.charge = CELL.maxcharge
		cell = CELL
		part_chest.cell = CELL

		upgrades += new /obj/item/roboupgrade/healthgoggles(src)
		upgrades += new /obj/item/roboupgrade/teleport(src)
		hud.update_upgrades()

	update_appearance()
		return

/mob/living/silicon/robot/buddy
	name = "Robot"
	real_name = "Robot"
	icon = 'icons/obj/aibots.dmi'
	icon_state = "robuddy1"
	health = 1000
	custom = 1

	New()
		..(usr.loc, null, 1)

	update_bodypart()
		return
	update_appearance()
		return


/client/proc/set_screen_color_to_red()
	color = "#ff0000"

