// WIP bot improvements (Convair880).

////////////////////////////////////////////// Cleanbot assembly ///////////////////////////////////////
/obj/item/bucket_sensor
	desc = "It's a bucket. With a sensor attached."
	name = "proxy bucket"
	icon = 'icons/obj/aibots.dmi'
	icon_state = "bucket_proxy"
	force = 3.0
	throwforce = 10.0
	throw_speed = 2
	throw_range = 5
	w_class = 3.0
	flags = TABLEPASS

	attackby(var/obj/item/parts/robot_parts/P, mob/user as mob)
		if (!istype(P, /obj/item/parts/robot_parts/arm))
			return

		var/obj/machinery/bot/cleanbot/A = new /obj/machinery/bot/cleanbot
		if (user.r_hand == src || user.l_hand == src)
			A.set_loc(get_turf(user))
		else
			A.set_loc(get_turf(src))

		boutput(user, "You add the robot arm to the bucket and sensor assembly! Beep boop!")
		qdel(P)
		qdel(src)
		return

///////////////////////////////////////////////// Cleanbot ///////////////////////////////////////
/obj/machinery/bot/cleanbot
	name = "cleanbot"
	desc = "A little cleaning robot, he looks so excited!"
	icon = 'icons/obj/aibots.dmi'
	icon_state = "cleanbot0"
	layer = 5
	density = 0
	anchored = 0

	on = 1
	locked = 1
	health = 25
	no_camera = 1
	access_lookup = "Janitor"

	var/target // Current target.
	var/list/path = null // Path to current target.
	var/list/targets_invalid = list() // Targets we weren't able to reach.
	var/clear_invalid_targets = 1 // In relation to world time. Clear list periodically.
	var/clear_invalid_targets_interval = 1800 // How frequently?
	var/frustration = 0 // Simple counter. Bot selects new target if current one is too far away.

	var/idle = 1 // In relation to world time. In case there aren't any valid targets nearby.
	var/idle_delay = 300 // For how long?

	var/cleaning = 0 // Are we currently cleaning something?
	var/reagent_normal = "cleaner"
	var/reagent_emagged = "lube"
	var/list/lubed_turfs = list() // So we don't lube the same turf ad infinitum.
	var/light/light

	New()
		..()
		light = new /light/point
		light.attach(src)
		light.set_brightness(0.4)

		spawn (5)
			if (src)
				botcard = new /obj/item/card/id(src)
				botcard.access = get_access(access_lookup)
				clear_invalid_targets = world.time

				var/reagents/R = new /reagents(50)
				reagents = R
				R.my_atom = src

				if (emagged)
					R.add_reagent(reagent_emagged, 50)
				else
					R.add_reagent(reagent_normal, 50)

				toggle_power(1)
		return

	examine()
		set src in view()
		..()

		if (health < initial(health))
			if (health > (initial(health) / 2))
				boutput(usr, text("<span style=\"color:red\">[src]'s parts look loose.</span>"))
			else
				boutput(usr, text("<span style=\"color:red\"><strong>[src]'s parts look very loose!</strong></span>"))
		return

	emag_act(var/mob/user, var/obj/item/card/emag/E)
		if (!emagged)
			if (user && ismob(user))
				emagger = user
				add_fingerprint(user)
				user.show_text("You short out [src]'s waste disposal circuits.", "red")
				for (var/mob/O in hearers(src, null))
					O.show_message("<span style=\"color:red\"><strong>[src] buzzes oddly!</strong></span>", 1)

			emagged = 1
			toggle_power(1)

			if (reagents)
				src.reagents.clear_reagents()
				reagents.add_reagent(reagent_emagged, 50)

			logTheThing("station", emagger, null, "emagged a [name], setting it to spread [reagent_emagged] at [log_loc(src)].")
			return TRUE

		return FALSE

	demag(var/mob/user)
		if (!emagged)
			return FALSE
		if (user)
			user.show_text("You repair [src]'s waste disposal circuits.", "blue")
		emagged = 0
		return TRUE

	emp_act()
		..()
		if (!emagged && prob(75))
			emag_act(usr && ismob(usr) ? usr : null, null)
		else
			explode()
		return

	proc/toggle_power(var/force_on = 0)
		if (!src)
			return

		if (force_on == 1)
			on = 1
		else
			on = !on

		anchored = 0
		target = null
		icon_state = "cleanbot[on]"
		path = null
		targets_invalid = list() // Turf vs decal when emagged, so we gotta clear it.
		lubed_turfs = list()
		clear_invalid_targets = world.time

		if (on)
			light.enable()
		else
			light.disable()

		return

	attack_hand(user as mob)
		add_fingerprint(user)
		var/dat = ""

		dat += "<tt><strong>Automatic Station Cleaner v1.1</strong></tt>"
		dat += "<br>"
		dat += "Status: <A href='?src=\ref[src];start=1'>[on ? "On" : "Off"]</A><br>"

		user << browse(dat, "window=autocleaner")
		onclose(user, "autocleaner")
		return

	attack_ai(mob/user as mob)
		if (on && emagged)
			boutput(user, "[src] refuses your authority!", "red")
			return

		toggle_power(0)
		return

	Topic(href, href_list)
		if (..()) return
		if (usr.stunned || usr.weakened || usr.stat || usr.restrained()) return
		if (!issilicon(usr) && !in_range(src, usr)) return

		add_fingerprint(usr)
		usr.machine = src

		if (href_list["start"])
			toggle_power(0)

		updateUsrDialog()
		return

	attackby(obj/item/W, mob/user as mob)
		if (istype(W, /obj/item/weldingtool))
			var/obj/item/weldingtool/WT = W
			if (!WT.welding)
				return
			if (health < initial(health))
				if (WT.get_fuel() > 2)
					WT.use_fuel(1)
					health = initial(health)
					visible_message("<span style=\"color:red\"><strong>[user]</strong> repairs the damage on [src].</span>")
				else
					user.show_text("Need more welding fuel!", "red")
					return

		else
			..()
			switch(W.damtype)
				if ("fire")
					health -= W.force * 0.75
				if ("brute")
					health -= W.force * 0.5
			if (health <= 0)
				explode()

		return

	process()
		if (!on)
			return

		if (cleaning)
			return

		// We're still idling.
		if (idle && world.time < idle + idle_delay)
			//DEBUG("Sleeping. [log_loc(src)]")
			return

		// Invalid targets may not be unreachable anymore. Clear list periodically.
		if (clear_invalid_targets && world.time > clear_invalid_targets + clear_invalid_targets_interval)
			targets_invalid = list()
			lubed_turfs = list()
			clear_invalid_targets = world.time
			//DEBUG("[emagged ? "(E) " : ""]Cleared target_invalid. [log_loc(src)]")

		if (frustration >= 8)
			//DEBUG("[emagged ? "(E) " : ""]Selecting new target (frustration). [log_loc(src)]")
			if (target && !(target in targets_invalid))
				targets_invalid += target
			frustration = 0
			target = null

		// So nearby bots don't go after the same mess.
		var/list/cleanbottargets = list()
		if (!target || target == null)
			for (var/obj/machinery/bot/cleanbot/bot in machines)
				if (bot != src)
					if (bot.target && !(bot.target in cleanbottargets))
						cleanbottargets += bot.target

		// Let's find us something to clean.
		if (!target || target == null)
			if (emagged)
				for (var/turf/simulated/floor/F in view(7, src))
					if (F in targets_invalid)
						//DEBUG("[emagged ? "(E) " : ""]Acquiring target failed (target_invalid). [F] [log_loc(F)]")
						continue
					if (F in cleanbottargets)
						//DEBUG("[emagged ? "(E) " : ""]Acquiring target failed (other bot target). [F] [log_loc(F)]")
						continue
					if (F in lubed_turfs)
						//DEBUG("[emagged ? "(E) " : ""]Acquiring target failed (lubed). [F] [log_loc(F)]")
						continue
					for (var/atom/A in F.contents)
						if (A.density && !(A.flags & ON_BORDER) && !istype(A, /obj/machinery/door) && !ismob(A))
							if (!(F in targets_invalid))
								//DEBUG("[emagged ? "(E) " : ""]Acquiring target failed (density). [F] [log_loc(F)]")
								targets_invalid += F
							continue

					target = F
					//DEBUG("[emagged ? "(E) " : ""]Target acquired. [F] [log_loc(F)]")
					break
			else
				for (var/obj/decal/cleanable/D in view(7, src))
					if (D in targets_invalid)
						//DEBUG("[emagged ? "(E) " : ""]Acquiring target failed (target_invalid). [D] [log_loc(D)]")
						continue
					if (D in cleanbottargets)
						//DEBUG("[emagged ? "(E) " : ""]Acquiring target failed (other bot target). [D] [log_loc(D)]")
						continue

					target = D
					//DEBUG("[emagged ? "(E) " : ""]Target acquired. [D] [log_loc(D)]")
					break

		// Still couldn't find one? Abort and retry later.
		if (!target || target == null)
			//DEBUG("[emagged ? "(E) " : ""]Acquiring target failed (no valid targets). [log_loc(src)]")
			idle = world.time
			return

		// Let's find us a path to the target.
		if (target && (!path || !path.len))
			spawn (0)
				if (!src)
					return

				var/turf/T = get_turf(target)
				if (!isturf(loc) || !T || !isturf(T) || T.density)
					if (!(target in targets_invalid))
						targets_invalid += target
						//DEBUG("[emagged ? "(E) " : ""]Acquiring target failed (target density). [T] [log_loc(T)]")
					target = null
					return

				if (istype(T, /turf/space))
					if (!(target in targets_invalid))
						targets_invalid += target
						//DEBUG("[emagged ? "(E) " : ""]Acquiring target failed (space tile). [T] [log_loc(T)]")
					target = null
					return

				for (var/atom/A in T.contents)
					if (A.density && !(A.flags & ON_BORDER) && !istype(A, /obj/machinery/door) && !ismob(A))
						if (!(target in targets_invalid))
							targets_invalid += target
							//DEBUG("[emagged ? "(E) " : ""]Acquiring target failed (obstruction). [T] [log_loc(T)]")
						target = null
						return

				path = AStar(get_turf(src), get_turf(target), /turf/proc/CardinalTurfsWithAccess, /turf/proc/Distance, adjacent_param = botcard)

				if (!path) // Woops, couldn't find a path.
					if (!(target in targets_invalid))
						targets_invalid += target
						//DEBUG("[emagged ? "(E) " : ""]Pathfinding failed. [T] [log_loc(T)]")
					target = null
					return

		// Move towards the target.
		if (path && path.len && target && (target != null))
			if (path.len > 8)
				frustration++
			step_to(src, path[1])
			if (loc == path[1])
				path -= path[1]
			else
				frustration++
				sleep (10)

			spawn (3)
				if (src && path && path.len)
					if (path.len > 8)
						frustration++
					step_to(src, path[1])
					if (loc == path[1])
						path -= path[1]
					else
						frustration++
			//DEBUG("[emagged ? "(E) " : ""]Moving towards target. [target] [log_loc(target)]")

		if (target)
			if (loc == get_turf(target))
				clean(target)
				path = null
				target = null
				return

		return

	proc/clean(var/obj/target)
		if (!src || !target)
			return
		var/turf/T = get_turf(target)
		if (!T || !isturf(T))
			return

		anchored = 1
		icon_state = "cleanbot-c"
		visible_message("<span style=\"color:red\">[src] begins to clean the [target.name].</span>")
		cleaning = 1
		//DEBUG("[emagged ? "(E) " : ""]Cleaning target. [target] [log_loc(target)]")

		spawn (50)
			if (src)
				reagents.reaction(T, 1, 10)

				if (emagged)
					if (!(T in lubed_turfs))
						lubed_turfs += T
					reagents.remove_reagent(reagent_emagged, 10)
					if (reagents.get_reagent_amount(reagent_emagged) <= 0)
						reagents.add_reagent(reagent_emagged, 50)
				else
					reagents.remove_reagent(reagent_normal, 10)
					if (reagents.get_reagent_amount(reagent_normal) <= 0)
						reagents.add_reagent(reagent_normal, 50)

				cleaning = 0
				icon_state = "cleanbot[on]"
				anchored = 0
				target = null
				frustration = 0
		return

	ex_act(severity)
		switch (severity)
			if (1.0)
				explode()
				return
			if (2.0)
				health -= 15
				if (health <= 0)
					explode()
				return
		return

	meteorhit()
		explode()
		return

	blob_act(var/power)
		if (prob(25 * power / 20))
			explode()
		return

	explode()
		if (!src)
			return

		on = 0
		for (var/mob/O in hearers(src, null))
			O.show_message("<span style=\"color:red\"><strong>[src] blows apart!</strong></span>", 1)

		var/effects/system/spark_spread/s = unpool(/effects/system/spark_spread)
		s.set_up(3, 1, src)
		s.start()

		var/turf/T = get_turf(src)
		if (T && isturf(T))
			new /obj/item/reagent_containers/glass/bucket(T)
			new /obj/item/device/prox_sensor(T)
			if (prob(50))
				new /obj/item/parts/robot_parts/arm/left(T)

		qdel(src)
		return