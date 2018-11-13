/obj/machinery/nuclearbomb
	name = "nuclear bomb"
	desc = "An extremely powerful bomb capable of levelling the whole station."
	icon = 'icons/obj/stationobjs.dmi'
	icon_state = "nuclearbomb"//1"
	density = 1
	anchored = 0
	var/health = 150
	var/armed = 0
	var/det_time = 0
	var/timer_default = 4800 // 8 min.
	var/timer_modifier_disk = 1800 // +3 (crew member) or -3 (nuke ops) min.
	var/motion_sensor_triggered = 0
	var/done = 0
	var/debugmode = 0
	var/hud/nukewires/wirepanel
	var/obj/item/disk/data/floppy/read_only/authentication/disk = null
	flags = FPRINT
	var/image/image_light = null

	New()
		wirepanel = new(src)
		#ifdef XMAS
		icon_state = "nuke_gift[rand(1,2)]"
		#endif
		image_light = image(icon, "nblight1")
		UpdateOverlays(image_light, "light")
		..()

	disposing()
		qdel(wirepanel)
		..()

	process()
		if (done)
			qdel(src)
			return
		if (!armed)
			return

		var/turf/T = get_turf(src)
		if (T && istype(T))
			for (var/obj/shrub/S in T.contents)
				S.visible_message("<span style=\"color:red\">[S] cannot withstand the intense radiation and crumbles to pieces!</span>")
				qdel(S)

		if (det_time && ticker.round_elapsed_ticks >= det_time)
			explode()
		return

	examine()
		..()
		if (usr.client)
			if (armed)
				boutput(usr, "It is currently counting down to detonation. Ohhhh shit.")
				boutput(usr, "The timer reads [get_countdown_timer()].[disk && istype(disk) ? " The authenticaion disk has been inserted." : ""]")
			else
				boutput(usr, "It is not armed. That's a relief.")
				if (disk && istype(disk))
					boutput(usr, "The authenticaion disk has been inserted.")

			if (!anchored)
				boutput(usr, "<br>The floor bolts have been unsecured. The bomb can be moved around.")
			else
				boutput(usr, "<br>It is firmly anchored to the floor by its floor bolts. A screwdriver could undo them.")

			switch(health)
				if (80 to 125)
					boutput(usr, "<span style=\"color:red\">It is a little bit damaged.</span>")
				if (40 to 79)
					boutput(usr, "<span style=\"color:red\">It looks pretty beaten up.</span>")
				if (1 to 39)
					boutput(usr, "<span style=\"color:red\"><strong>It seems to be on the verge of falling apart!</strong></span>")
		return

	// Nuke round development was abandoned for 4 whole months, so I went out of my way to implement some user feedback from that 11 pages long forum thread (Convair880).
	attack_hand(mob/user as mob)
		if (debugmode)
			open_wire_panel(user)
			return
		if (!user.mind || get_dist(src, user) > 1)
			return

		var/game_mode/nuclear/NUKEMODE = null
		var/area/A = get_area(src)

		if (ticker && ticker.mode && istype(ticker.mode, /game_mode/nuclear))
			NUKEMODE = ticker.mode

			if (armed == 0)
				if (user.mind in NUKEMODE.syndicates)
					if ((NUKEMODE.target_location_name && NUKEMODE.target_location_type.len) && (A && istype(A)))
						if (!(A.type in NUKEMODE.target_location_type))
							boutput(user, "<span style=\"color:red\">You need to deploy the bomb in [NUKEMODE.target_location_name].</span>")
						else
							if (alert("Deploy and arm [name] here?", name, "Yes", "No") == "Yes" && !armed && get_dist(src, user) <= 1 && !(user.stunned > 0 || user.weakened > 0 || user.paralysis > 0 || user.stat != 0 || user.restrained()))
								armed = 1
								anchored = 1
								if (!image_light)
									image_light = image(icon, "nblightc")
									UpdateOverlays(image_light, "light")
								else
									image_light.icon_state = "nblightc"
									UpdateOverlays(image_light, "light")
								//icon_state = "nuclearbomb2"
								det_time = ticker.round_elapsed_ticks + timer_default
								command_alert("A nuclear explosive has been armed in [A]. It will detonate in [get_countdown_timer()] min. All personnel must attempt to disarm the bomb immediately.", "Red Alert")
								world << sound('sound/machines/siren_generalquarters.ogg')
								logTheThing("bombing", user, null, "armed [src] at [log_loc(src)].")

					else
						boutput(user, "<span style=\"color:red\">Deployment area definition missing or invalid! Please report this to a coder.</span>")
				else
					boutput(user, "<span style=\"color:red\">It isn't deployed, and you don't know how to deploy it anyway.</span>")
			else
				if (user.mind in NUKEMODE.syndicates)
					boutput(user, "<span style=\"color:blue\">You don't need to do anything else with the bomb.</span>")
				else
					user.visible_message("<span style=\"color:red\"><strong>[user]</strong> kicks [src] uselessly!</span>")
					playsound(loc, "sound/items/grillehit.ogg", 100, 1)
		else
			boutput(user, "<span style=\"color:red\">[name] seems to be completely inert and useless.</span>")

		return

	attackby(obj/item/W as obj, mob/user as mob)
		add_fingerprint(user)

		if (ticker && ticker.mode && istype(ticker.mode, /game_mode/nuclear))
			var/game_mode/nuclear/NUKEMODE = ticker.mode
			if (istype(W, /obj/item/disk/data/floppy/read_only/authentication))
				if (disk && istype(disk))
					boutput(user, "<span style=\"color:red\">There's already something in the [name]'s disk drive.</span>")
					return
				if (armed == 0)
					boutput(user, "<span style=\"color:red\">The [name] isn't armed yet.</span>")
					return

				var/timer_modifier = 0
				if (user.mind in NUKEMODE.syndicates)
					timer_modifier = -timer_modifier_disk
					user.visible_message("<span style=\"color:red\"><strong>[user]</strong> inserts [W.name], shortening the bomb's timer by [timer_modifier_disk / 10] seconds!</span>")
				else
					timer_modifier = timer_modifier_disk
					user.visible_message("<span style=\"color:red\"><strong>[user]</strong> inserts [W.name], extending the bomb's timer by [timer_modifier_disk / 10] seconds!</span>")

				playsound(loc, "sound/machines/ping.ogg", 100, 0)
				logTheThing("bombing", user, null, "inserted [W.name] into [src] at [log_loc(src)], modifying the timer by [timer_modifier / 10] seconds.")
				user.u_equip(W)
				W.set_loc(src)
				disk = W
				det_time += timer_modifier
				return

			if (user.mind in NUKEMODE.syndicates)
				if (armed == 1)
					boutput(user, "<span style=\"color:blue\">You don't need to do anything else with the bomb.</span>")
					return
				else
					boutput(user, "<span style=\"color:red\">Why would you want to damage the nuclear bomb?</span>")
					return

			if (armed && anchored)
				if (istype(W, /obj/item/screwdriver))
					actions.start(new /action/bar/icon/unanchorNuke(src), user)
					return
				//else if (istype(W,/obj/item/wirecutters))
				//	user.visible_message("<strong>[user]</strong> opens up [src]'s wiring panel and takes a look.")
				//	open_wire_panel(user)
				//	return

		if (isobj(W) && !(istype(W, /obj/item/screwdriver/) || istype(W, /obj/item/disk/data/floppy/read_only/authentication) || istype(W,/obj/item/wirecutters)))
			switch (W.force)
				if (0 to 19)
					take_damage(W.force / 4)
				if (20 to 39)
					take_damage(W.force / 5)
				if (40 to 59)
					take_damage(W.force / 6)
				if (60 to INFINITY)
					take_damage(W.force / 7) // Esword has 60 force.

			logTheThing("combat", user, null, "attacks [src] with [W] at [log_loc(src)].")
			playsound(loc, "sound/items/grillehit.ogg", 100, 1)

		..()
		return

	ex_act(severity)
		/*switch(severity) // No more suicide-bombing the nuke.
			if (1)
				take_damage(80)
			if (2)
				take_damage(50)
			if (3)
				take_damage(20)*/
		return

	blob_act(var/power)
		if (!isnum(power) || power < 1) power = 1
		take_damage(power)
		return

	emp_act()
		take_damage(rand(25,35))
		if (armed && det_time)
			det_time += rand(-300,600)

	meteorhit()
		take_damage(rand(30,60))

	bullet_act(var/obj/projectile/P)
		var/damage = 0
		damage = round(((P.power/6)*P.proj_data.ks_ratio), 1.0)

		if (material) material.triggerOnAttacked(src, P.shooter, src, (ismob(P.shooter) ? P.shooter:equipped() : P.shooter))
		for (var/atom/A in src)
			if (A.material)
				A.material.triggerOnAttacked(A, P.shooter, src, (ismob(P.shooter) ? P.shooter:equipped() : P.shooter))

		if (!damage)
			return
		if (P.proj_data.damage_type == D_KINETIC || (P.proj_data.damage_type == D_ENERGY && damage))
			take_damage(damage / 1.7)
		else if (P.proj_data.damage_type == D_PIERCING)
			take_damage(damage)

	proc/open_wire_panel(var/mob/user)
		user.s_active = wirepanel
		wirepanel.update()
		user.attach_hud(wirepanel)

	proc/get_countdown_timer()
		var/timeleft = round((det_time - ticker.round_elapsed_ticks)/10 ,1)
		timeleft = "[(timeleft / 60) % 60]:[add_zero(num2text(timeleft % 60), 2)]"
		return timeleft

	proc/take_damage(var/amount)
		if (!isnum(amount) || amount < 1)
			return
		health = max(0,health - amount)
		if (health < 1)
			visible_message("<strong>[src]</strong> breaks and falls apart into useless pieces!")
			robogibs(loc,null)
			playsound(loc, 'sound/effects/robogib.ogg', 50, 2)
			var/game_mode/nuclear/NUKEMODE = null
			if (ticker && ticker.mode && istype(ticker.mode, /game_mode/nuclear))
				NUKEMODE = ticker.mode
				NUKEMODE.the_bomb = null
				logTheThing("station", null, null, "The nuclear bomb was destroyed at [log_loc(src)].")
				message_admins("The nuclear bomb was destroyed at [log_loc(src)].")
			qdel(src)

	proc/explode()
		sleep(20)
		done = 1
		var/game_mode/nuclear/NUKEMODE = null
		var/turf/nuke_turf = get_turf(src)
		if (nuke_turf.z != 1 && (ticker && ticker.mode && istype(ticker.mode, /game_mode/nuclear)))
			NUKEMODE = ticker.mode
			NUKEMODE.the_bomb = null
			command_alert("A nuclear explosive has been detonated nearby. The station was not in range of the blast.", "Attention")
			explosion(src, loc, 20, 30, 40, 50)
			qdel(src)
			return

		var/hud/cinematic/cinematic = new
		for (var/client/C)
			cinematic.add_client(C)
		cinematic.play("nuke")

		sleep(55)

		enter_allowed = 0
		score_nuked = 1
		for (var/mob/living/carbon/human/nukee in mobs)
			// cogwerks - making the end of nuke more exciting. oh no a nuke went off, let's all... stand around for thirty seconds
			if (!nukee.stat)
				nukee.emote("scream")
			// until we can fix the lag related to deleting mobs we should probably just leave the end of the animation up and kill everyone instead of firegibbing everyone
			nukee.death()//firegib()

		creepify_station()

		if (ticker && ticker.mode && istype(ticker.mode, /game_mode/nuclear))
			ticker.mode:nuke_detonated = 1
			ticker.mode.check_win()
		else
			sleep(10)
			boutput(world, "<strong>Everyone was killed by the nuclear blast! Resetting in 30 seconds!</strong>")

			sleep(300)
			logTheThing("diary", null, null, "Rebooting due to nuclear destruction of station", "game")
			Reboot_server()

/action/bar/icon/unanchorNuke
	duration = 40
	interrupt_flags = INTERRUPT_MOVE | INTERRUPT_ACT | INTERRUPT_STUNNED | INTERRUPT_ACTION
	id = "unanchornuke"
	icon = 'icons/obj/items.dmi'
	icon_state = "screwdriver"
	var/obj/machinery/nuclearbomb/the_bomb = null

	New(Target)
		the_bomb = Target
		..()

	onUpdate()
		..()
		if (get_dist(owner, the_bomb) > 1 || the_bomb == null || owner == null)
			interrupt(INTERRUPT_ALWAYS)
			return

		if (!the_bomb.anchored)
			interrupt(INTERRUPT_ALWAYS)
			return

	onStart()
		..()
		if (get_dist(owner, the_bomb) > 1 || the_bomb == null || owner == null)
			interrupt(INTERRUPT_ALWAYS)
			return

		for (var/mob/O in AIviewers(owner))
			O.show_message("<span style=\"color:red\"><strong>[owner]</strong> begins to unscrew [the_bomb]'s floor bolts.</span>", 1)

	onEnd()
		..()
		if (owner && the_bomb)
			var/timer_modifier = round((the_bomb.det_time - ticker.round_elapsed_ticks) / 2)
			the_bomb.anchored = 0

			for (var/mob/O in AIviewers(owner))
				O.show_message("<span style=\"color:red\"><strong>[owner]</strong> unscrews [the_bomb]'s floor bolts.</span>", 1)

			if (ticker.round_elapsed_ticks < (the_bomb.det_time - timer_modifier) && !the_bomb.motion_sensor_triggered)
				the_bomb.motion_sensor_triggered = 1
				the_bomb.det_time -= timer_modifier
				the_bomb.visible_message("<span style=\"color:red\"><strong>[the_bomb]'s motion sensor was triggered! The countdown has been halved to [the_bomb.get_countdown_timer()]!</strong></span>")
				logTheThing("bombing", owner, null, "unscrews [the_bomb] at [log_loc(the_bomb)], halving the countdown to [the_bomb.get_countdown_timer()].")