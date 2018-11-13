// crates/closets/etc.  this shoulda been combined a while ago, but here we are.

// NOTE:
// Unlike old closets/etc, these things make their contents in the make_my_stuff() proc.
// DO NOT OVERRIDE New() ON THESE OKAY
// PLEASE JUST MAKE A MESS OF make_my_stuff() INSTEAD
// CALL YOUR PARENTS

#define RELAYMOVE_DELAY 50

/obj/storage
	name = "storage"
	desc = "this is a parent item you shouldn't see!!"
	flags = FPRINT | NOSPLASH
	icon = 'icons/obj/large_storage.dmi'
	icon_state = "closed"
	density = 1
	throwforce = 10
	mouse_drag_pointer = MOUSE_ACTIVE_POINTER
	var/secure = 0
	var/personal = 0
	var/registered = null
	var/icon_closed = "closed"
	var/icon_opened = "open"
	var/icon_welded = "welded-closet"
	var/open = 0
	var/welded = 0
	var/locked = 0
	var/emagged = 0
	var/jiggled = 0
	var/legholes = 0
	var/health = 3
	var/can_flip_bust = 0 // Can the trapped mob damage this container by flipping?
	var/obj/item/card/id/scan = null
	var/data/record/account = null
	var/last_relaymove_time
	var/is_short = 0 // can you not stand in it?  ie, crates?
	var/open_fail_prob = 50
	var/crunches_contents = 0 // for the syndicate trashcart & hotdog stand
	var/crunches_deliciously = 0 // :I
	//var/mob/living/carbon/to_crunch = null
	var/owner_ckey = null // owner of the crunchy cart, so they don't get crunched
	var/list/spawn_contents = list() // maybe better than just a bunch of stuff in New()?

	New()
		..()
		spawn (1)
			update_icon()
			make_my_stuff()
			if (!open)		// if closed, any item at src's loc is put in the contents
				for (var/obj/O in loc)
					if (is_acceptable_content(O))
						O.set_loc(src)

	proc/make_my_stuff() // use this rather than overriding the container's New()
		if (!spawn_contents || !islist(spawn_contents) || !spawn_contents.len)
			return
		for (var/thing in spawn_contents)
			var/amt = 1
			if (!ispath(thing))
				continue
			if (isnum(spawn_contents[thing])) //Instead of duplicate entries in the list, let's make them associative
				amt = abs(spawn_contents[thing])
			do new thing(src)	//Two lines! I TOLD YOU I COULD DO IT!!!
			while (--amt > 0)
		return

	proc/update_icon()
		if (open)
			icon_state = icon_opened
		else if (!open)
			icon_state = icon_closed

		if (overlays)
			overlays = list()
		if (welded)
			overlays += icon_welded

	emp_act()
		if (!open && contents.len)
			for (var/atom/A in contents)
				if (ismob(A))
					var/mob/M = A
					M.emp_act()
				if (isitem(A))
					var/obj/item/I = A
					I.emp_act()
		return

	alter_health()
		return get_turf(src)

	relaymove(mob/user as mob)
		if (user.stunned > 0 || user.weakened > 0 || user.paralysis > 0 || user.stat != 0)
			return
		if (world.time < (last_relaymove_time + RELAYMOVE_DELAY))
			return
		last_relaymove_time = world.time

		if (!open())
			if (!is_short && legholes)
				step(src, pick(alldirs))
			if (!jiggled)
				jiggled = 1
				user.show_text("You kick at [src], but it doesn't budge!", "red")
				user.unlock_medal("IT'S A TRAP", 1)
				for (var/mob/M in hearers(src, null))
					M.show_text("<font size=[max(0, 5 - get_dist(src, M))]>THUD, thud!</font>")
				playsound(get_turf(src), "sound/effects/zhit.ogg", 15, 1, -3)
				var/shakes = 5
				while (shakes > 0)
					shakes--
					pixel_x = rand(-5,5)
					pixel_y = rand(-5,5)
					sleep(1)
				pixel_x = 0
				pixel_y = 0
				spawn (5)
					jiggled = 0
			return

		else if (prob(open_fail_prob))
			if (legholes)
				step(src,user.dir)
			user.show_text("You kick at [src], but it doesn't budge!", "red")
			return

		// if all else fails:
		open()
		visible_message("<span style=\"color:red\"><strong>[user]</strong> kicks [src] open!</span>")

	attack_hand(mob/user as mob)
		if (get_dist(user, src) > 1)
			return
		add_fingerprint(user)
		if (welded)
			user.show_text("It won't open!", "red")
			return
		else if (!toggle())
			return attackby(null, user)

	attackby(obj/item/W as obj, mob/user as mob)
		if (istype(W, /obj/item/cargotele))
			var/obj/item/cargotele/CT = W
			CT.cargoteleport(src, user)
			return

		else if (istype(W, /obj/item/satchel))
			var/amt = W:contents.len
			if (amt)
				user.visible_message("<span style=\"color:blue\">[user] dumps out [W]'s contents into [src]!</span>")
				var/amtload = 0
				for (var/obj/item/I in W.contents)
					if (open)
						I.set_loc(loc)
					else
						I.set_loc(src)
					amtload++
				W:satchel_updateicon()
				if (amtload)
					user.show_text("[amtload] [W:itemstring] dumped into [W]!", "blue")
				else
					user.show_text("No [W:itemstring] dumped!", "red")
				return

		if (open)
			if (!is_short && istype(W, /obj/item/weldingtool))
				var/obj/item/weldingtool/welder = W
				if (welder.welding && !legholes)
					if (welder.get_fuel() < 2)
						user.show_text("Need more fuel!", "red")
						return
					welder.use_fuel(1)
					legholes = 1
					visible_message("<span style=\"color:red\">[user] adds some holes to the bottom of [src] with [welder].</span>")
					return
				else if (!issilicon(user))
					if (user.drop_item())
						if (welder)
							welder.set_loc(loc)
					return

			else if (istype(W, /obj/item/wrench))
				var/obj/item/I = new /obj/item/sheet(get_turf(src))
				if (material)
					I.setMaterial(material)
				else
					var/material/M = getCachedMaterial("steel")
					I.setMaterial(M)
				visible_message("<span style=\"color:red\">[user] takes apart [src] with [W].</span>")
				qdel(src)
				return
			else if (!issilicon(user))
				if (istype(W, /obj/item/grab))
					return MouseDrop_T(W:affecting, user)	//act like they were dragged onto the closet
				if (user.drop_item())
					if (W) W.set_loc(loc)
				return

		else if (!open && istype(W, /obj/item/weldingtool))
			var/obj/item/weldingtool/welder = W
			if (welder.welding)
				if (welder.get_fuel() < 2)
					user.show_text("Need more fuel!", "red")
					return
				if (!welded)
					weld(1, welder, user)
					visible_message("<span style=\"color:red\">[user] welds [src] closed with [welder].</span>")
				else
					weld(0, welder, user)
					visible_message("<span style=\"color:red\">[user] unwelds [src] with [welder].</span>")
				return

		if (secure)
			if (emagged)
				user.show_text("It appears to be broken.", "red")
				return
			else if (personal && istype(W, /obj/item/card/id))
				var/obj/item/card/id/I = W
				if (allowed(user, req_only_one_required) || !registered || (istype(W, /obj/item/card/id) && registered == I.registered))
					//they can open all lockers, or nobody owns this, or they own this locker
					locked = !( locked )
					user.visible_message("<span style=\"color:blue\">The locker has been [locked ? null : "un"]locked by [user].</span>")
					update_icon()
					if (!registered)
						registered = I.registered
						name = "[I.registered]'s [name]"
						desc = "Owned by [I.registered]."
					for (var/mob/M in contents)
						log_me(user, M, locked ? "locks" : "unlocks")
					return
			else if (!personal && allowed(user, req_only_one_required))
				if (!open)
					locked = !locked
					user.visible_message("<span style=\"color:blue\">[src] has been [locked ? null : "un"]locked by [user].</span>")
					update_icon()
					for (var/mob/M in contents)
						log_me(user, M, locked ? "locks" : "unlocks")
					return
				else
					close()
					return

			if (secure != 2)
				user.show_text("Access Denied", "red")
			user.unlock_medal("Rookie Thief", 1)
			return
/*
		else if (issilicon(user))
			if (get_dist(src, user) <= 1)
				return attack_hand(user)
*/
		else
			return ..()

	MouseDrop_T(atom/movable/O as mob|obj, mob/user as mob)
		if (!in_range(user, src) || !in_range(user, O) || user.restrained() || user.paralysis || user.sleeping || user.stat || user.lying)
			return

		if (!is_acceptable_content(O))
			return

		if (isitem(O) && (O:cant_drop || (issilicon(user) && O.loc == user))) //For borg held items
			user.show_text("You can't put that in [src] when it's attached to you!", "red")
			return

		add_fingerprint(user)

		if (is_short && O == user)
			var/turf/T = get_turf(src)
			var/no_go = 0
			if (T.density)
				no_go = T
			else
				for (var/obj/thingy in T)
					if (thingy == src)
						continue
					if (istype(thingy, /obj/storage) && thingy:is_short)
						continue
					if (thingy.density)
						no_go = thingy
						break

			if (no_go) // no more scooting around walls and doors okay
				user.visible_message("<span style=\"color:red\"><strong>[user]</strong> scoots around [src], right into [no_go]!</span>",\
				"<span style=\"color:red\">You scoot around [src], right into [no_go]!</span>")
				user.weakened += 4
				if (prob(25))
					user.show_text("You hit your head on [no_go]!", "red")
					user.TakeDamage("head", 0, 10)
				return

			if (iscarbon(O))
				var/mob/living/carbon/M = user
				if (M.bioHolder && M.bioHolder.HasEffect("clumsy") && prob(40))
					user.visible_message("<span style=\"color:red\"><strong>[user]</strong> trips over [src]!</span>",\
					"<span style=\"color:red\">You trip over [src]!</span>")
					playsound(user.loc, 'sound/weapons/genhit2.ogg', 15, 1, -3)
					user.set_loc(loc)
					user.weakened += 10
					return
				else
					user.show_text("You scoot around [src].")
					user.set_loc(loc)
					return
			if (issilicon(O))
				user.show_text("You scoot around [src].")
				user.set_loc(loc)
				return

		if (locked)
			user.show_text("You'll have to unlock [src] first.", "red")
			return

		if (welded)
			user.show_text("[src] is welded shut!", "red")
			return

		if (!open)
			open()

		if (O.loc == user)
			user.u_equip(O)
			O.set_loc(get_turf(user))

		spawn (5)
			if (istype(O, /obj/item/raw_material))
				user.visible_message("<span style=\"color:blue\">[user] begins quickly stuffing materials into [src]!</span>",\
				"<span style=\"color:blue\">You begin quickly stuffing materials into [src]!</span>")
				var/staystill = user.loc
				for (var/obj/item/raw_material/M in view(1,user))
					if (M.material && M.material.getProperty(PROP_RADIOACTIVITY) > 0)
						user.irradiate(round(min(M.material.getProperty(PROP_RADIOACTIVITY) / 2, 20)))
					if (M.loc == src || M.loc == loc) // we're already there!
						continue
					M.set_loc(loc)
					sleep(0.5)
					if (!open)
						break
					if (user.loc != staystill)
						break
				for (var/obj/item/material_piece/M in view(1,user))
					if (M.material && M.material.getProperty(PROP_RADIOACTIVITY) > 0)
						user.irradiate(round(min(M.material.getProperty(PROP_RADIOACTIVITY) / 2, 20)))
					if (M.loc == src || M.loc == loc) // we're already there!
						continue
					M.set_loc(loc)
					sleep(0.5)
					if (!open)
						break
					if (user.loc != staystill)
						break
				user.show_text("You finish stuffing materials into [src]!", "blue")
				spawn (5)
					if (open)
						close()

			else if (istype(O, /obj/item/plant/) || istype(O, /obj/item/reagent_containers/food/snacks))
				user.visible_message("<span style=\"color:blue\">[user] begins quickly stuffing produce into [src]!</span>",\
				"<span style=\"color:blue\">You begin quickly stuffing produce into [src]!</span>")
				var/staystill = user.loc
				for (var/obj/item/plant/P in view(1,user))
					if (P in user)
						continue
					if (P.loc == src || P.loc == loc) // we're already there!
						continue
					P.set_loc(loc)
					sleep(0.5)
					if (!open)
						break
					if (user.loc != staystill)
						break
				for (var/obj/item/reagent_containers/food/snacks/F in view(1,user))
					if (F in user)
						continue
					if (F.loc == src || F.loc == loc) // we're already there!
						continue
					F.set_loc(loc)
					sleep(0.5)
					if (!open)
						break
					if (user.loc != staystill)
						break
				user.show_text("You finish stuffing produce into [src]!", "blue")
				spawn (5)
					if (open)
						close()

			else
				O.set_loc(loc)
				if (user != O)
					user.visible_message("<span style=\"color:red\">[user] stuffs [O] into [src]!</span>",\
					"<span style=\"color:red\">You stuff [O] into [src]!</span>")
				spawn (5)
					if (open)
						close()
		return ..()

	attack_ai(mob/user)
		if (can_reach(user, src) <= 1 && (isrobot(user) || isshell(user)))
			return attack_hand(user)

	alter_health()
		return get_turf(src)

	CanPass(atom/movable/mover, turf/target, height=0, air_group=0)
		if (air_group || (height==0))
			return TRUE
		if (is_short)
			return FALSE
		return open

	ex_act(severity)
		switch (severity)
			if (1)
				for (var/atom/movable/A as mob|obj in src)
					A.set_loc(loc)
					A.ex_act(severity)
				qdel(src)
			if (2)
				if (prob(50))
					for (var/atom/movable/A as mob|obj in src)
						A.set_loc(loc)
						A.ex_act(severity)
					qdel(src)
			if (3)
				if (prob(5))
					for (var/atom/movable/A as mob|obj in src)
						A.set_loc(loc)
						A.ex_act(severity)
					qdel(src)

	blob_act(var/power)
		if (prob(power * 2.5))
			dump_contents()
			qdel(src)

	meteorhit(obj/O as obj)
		if (O && O.icon_state == "flaming")
			dump_contents()
			qdel(src)
			return
		return

	proc/is_acceptable_content(var/atom/A)
		if (!A || !(isobj(A) || ismob(A)))
			return FALSE
		if (istype(A, /obj/decal/skeleton)) // uuuuuuugh
			return TRUE
		if (isobj(A) && ((A.density && !istype(A, /obj/critter)) || A:anchored || A == src || istype(A, /obj/decal) || istype(A, /obj/screen) || istype(A, /obj/storage)))
			return FALSE
		return TRUE

	proc/open()
		if (open)
			return FALSE
		if (!can_open())
			return FALSE
		dump_contents()
		open = 1
		update_icon()
		playsound(loc, 'sound/machines/click.ogg', 15, 1, -3)
		return TRUE

	proc/close()
		if (!open)
			return FALSE
		if (!can_close())
			return FALSE

		open = 0

		for (var/obj/O in get_turf(src))
			if (is_acceptable_content(O))
				O.set_loc(src)

		for (var/mob/M in get_turf(src))
			if (M.anchored || M.buckled || (is_short && !M.lying))
				continue
			#ifdef HALLOWEEN
			if (halloween_mode && prob(5)) //remove the prob() if you want, it's just a little broken if dudes are constantly teleporting
				var/list/obj/storage/myPals = list()
				for (var/obj/storage/O in world)
					if (O.z != z || O.open || !O.can_open())
						continue
					myPals.Add(O)

				var/obj/storage/warp_dest = pick(myPals)
				M.set_loc(warp_dest)
				M.show_text("You are suddenly thrown elsewhere!", "red")
				M.playsound_local(M.loc, "warp", 50, 1)
				continue
			#endif
			if (isobserver(M) || iswraith(M) || isintangible(M) || istype(M, /mob/living/object))
				continue
			if (crunches_contents)
				crunch(M)
			M.set_loc(src)

		update_icon()
		playsound(loc, "sound/machines/click.ogg", 15, 1, -3)
		return TRUE

	proc/can_open()
		if (welded || locked)
			return FALSE
		return TRUE

	proc/can_close()
		for (var/obj/storage/S in get_turf(src))
			if (S != src)
				return FALSE
		return TRUE

	proc/dump_contents()
		var/newloc = get_turf(src)
		for (var/obj/O in src)
			O.set_loc(newloc)

		for (var/mob/M in src)
			M.set_loc(newloc)

	proc/toggle()
		if (open)
			return close()
		return open()

	proc/bust_out()
		if (health)
			visible_message("<span style=\"color:red\">[src] [pick("cracks","bends","shakes","groans")].</span>")
			health--
		if (health <= 0)
			visible_message("<span style=\"color:red\">[src] breaks apart!</span>")
			dump_contents()
			spawn (1)
				var/newloc = get_turf(src)
				new /obj/decal/cleanable/machine_debris(newloc)
				qdel(src)

	proc/weld(var/shut = 0, var/obj/item/weldingtool/W as obj, var/mob/weldman as mob)
		if (shut)
			W.use_fuel(1)
			W.eyecheck(weldman)
			weldman.visible_message("<span style=\"color:red\">[weldman] welds [src] shut.</span>")
			welded = 1
		else
			W.use_fuel(1)
			W.eyecheck(weldman)
			weldman.visible_message("<span style=\"color:red\">[weldman] unwelds [src].</span>") // walt-fuck_you.ogg
			welded = 0
		update_icon()
		for (var/mob/M in contents)
			log_me(weldman, M, welded ? "welds" : "unwelds")
		return

	proc/crunch(var/mob/M as mob)
		if (!M || istype(M, /mob/living/carbon/wall))
			return

		if (M.ckey && (M.ckey == owner_ckey))
			return
		else
			locked = 1
			M.show_text("Is it getting...smaller in here?", "red")
			spawn (50)
				if (!M.loc == src)
					locked = 0
					return
				playsound(loc, 'sound/effects/splat.ogg', 75, 1)
				M.show_text("<strong>OH JESUS CHRIST</strong>", "red")
				bleed(M, 500, 5)
				log_me(usr && ismob(usr) ? usr : null, M, "uses trash compactor")
				var/mob/living/carbon/wall/meatcube/W = M.make_meatcube(rand(10,15), get_turf(src))
				if (crunches_deliciously)
					W.name = "hotdog"
					var/obj/item/reagent_containers/food/snacks/hotdog/syndicate/snoopdog = new /obj/item/reagent_containers/food/snacks/hotdog/syndicate(src)
					snoopdog.victim = W

				for (var/obj/item/I in M)
					if (istype(I, /obj/item/implant))
						I.set_loc(W)
						continue

					I.set_loc(src)

				locked = 0
				open()

	// Added (Convair880).
	proc/log_me(var/mob/user, var/mob/occupant, var/action = "")
		if (!src || !occupant || !ismob(occupant) || !action)
			return

		logTheThing("station", user, occupant, "[action] [src] with %target% inside at [log_loc(src)].")
		return

	verb/toggle_verb()
		set src in oview(1)
		set name = "Open / Close"
		set desc = "Open or close the closet/crate/whatever. Woah!"
		set category = "Local"

		if (usr.stat || !usr.can_use_hands())
			return

		return toggle()

	verb/move_inside()
		set src in oview(1)
		set name = "Move Inside"
		set desc = "Enter the closet/crate/whatever. Wow!"
		set category = "Local"

		if (usr.stat || !usr.can_use_hands() || usr.loc == src)
			return

		if (locked)
			return

		if (open)
			step_towards(usr, src)
			sleep(10)
			if (usr.loc == loc)
				if (is_short)
					usr.lying = 1
				close()
		else if (open())
			step_towards(usr, src)
			sleep(10)
			if (usr.loc == loc)
				if (is_short)
					usr.lying = 1
				close()
		return

/obj/storage/secure
	name = "secure storage"
	icon_state = "secure"
	health = 6
	secure = 1
	locked = 1
	icon_closed = "secure"
	icon_opened = "secure-open"
	var/icon_greenlight = "greenlight"
	var/icon_redlight = "redlight"
	var/icon_sparks = "sparks"
	var/always_display_locks = 0
	var/radio_frequency/radio_control = 1431
	var/net_id

	New()
		..()
		spawn (10)
			if (isnum(radio_control) && radio_controller)
				radio_control = max(1000, min(round(radio_control), 1500))
				net_id = generate_net_id(src)
				radio_controller.add_object(src, "[radio_control]")
				radio_control = radio_controller.return_frequency("[radio_control]")

	update_icon()
		..()
		if (!open)
			icon_state = icon_closed

		if (!open || always_display_locks)
			if (emagged)
				overlays += icon_sparks
			else if (locked)
				overlays += icon_redlight
			else
				overlays += icon_greenlight

	receive_signal(signal/signal)
		if (!radio_control)
			return

		var/sender = signal.data["sender"]
		if (!signal || signal.encryption || !sender)
			return

		if (signal.data["address_1"] == net_id)
			switch (lowertext(signal.data["command"]))
				if ("status")
					var/signal/reply = get_free_signal()
					reply.source = src
					reply.transmission_method = TRANSMISSION_RADIO
					reply.data = list("address_1" = sender, "command" = "lock=[locked]&open=[open]", "sender" = net_id)
					spawn (5)
						radio_control.post_signal(src, reply, 2)

				if ("lock")
					. = 0
					if (signal.data["pass"] == netpass_heads)
						. = 1
						locked = !locked
						visible_message("[src] clicks[open ? "" : " locked"].")
						update_icon()

					var/signal/reply = get_free_signal()
					reply.source = src
					reply.transmission_method = TRANSMISSION_RADIO
					if (.)
						reply.data = list("address_1" = sender, "command" = "ack", "sender" = net_id)
					else
						reply.data = list("address_1" = sender, "command" = "nack", "data" = "badpass", "sender" = net_id)
					spawn (5)
						radio_control.post_signal(src, reply, 2)

				if ("unlock")
					. = 0
					if (signal.data["pass"] == netpass_heads)
						. = 1
						locked = !locked
						visible_message("[src] clicks[open ? "" : " unlocked"].")
						update_icon()

					var/signal/reply = get_free_signal()
					reply.source = src
					reply.transmission_method = TRANSMISSION_RADIO
					if (.)
						reply.data = list("address_1" = sender, "command" = "ack", "sender" = net_id)
					else
						reply.data = list("address_1" = sender, "command" = "nack", "data" = "badpass", "sender" = net_id)

					spawn (5)
						radio_control.post_signal(src, reply, 2)
			return //todo

		else if (signal.data["address_1"] == "ping")
			var/signal/reply = get_free_signal()
			reply.source = src
			reply.transmission_method = TRANSMISSION_RADIO
			reply.data["address_1"] = sender
			reply.data["command"] = "ping_reply"
			reply.data["device"] = "WNET_SECLOCKER"
			reply.data["netid"] = net_id
			spawn (5)
				radio_control.post_signal(src, reply, 2)
			return
		return

	emag_act(var/mob/user, var/obj/item/card/emag/E)
		if (!emagged) // secure crates checked for being locked/welded but so long as you aren't telling the thing to open I don't see why that was needed
			emagged = 1
			locked = 0
			update_icon()
			playsound(loc, 'sound/effects/sparks4.ogg', 75, 1)
			if (user)
				user.show_text("You short out the lock on [src].", "blue")
			return TRUE
		return FALSE

	demag(var/mob/user)
		if (!emagged)
			return FALSE
		else if (emagged)
			emagged = 0
			update_icon()
			if (user)
				user.show_text("You repair the lock on [src].", "blue")
			return TRUE

#undef RELAYMOVE_DELAY