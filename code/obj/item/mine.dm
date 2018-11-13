// Cleaned up the ancient code that used to be here (Convair880).
/obj/item/mine
	name = "land mine (parent)"
	desc = "You shouldn't be able to see this!"
	w_class = 3
	density = 0
	anchored = 1
	layer = OBJ_LAYER
	icon = 'icons/obj/weapons.dmi'
	icon_state = "mine"
	is_syndicate = 1
	mats = 6
	var/suppress_flavourtext = 0
	var/armed = 0
	var/used_up = 0
	var/obj/item/device/timer/our_timer = null

	New()
		..()
		if (armed)
			update_icon()

		if (!our_timer || !istype(our_timer))
			our_timer = new /obj/item/device/timer(src)
			our_timer.master = src

		return

	examine()
		..()
		if (suppress_flavourtext != 1)
			boutput(usr, "It appears to be [armed == 1 ? "armed" : "disarmed"].")
		return

	attack_hand(mob/user as mob)
		add_fingerprint(user)

		if (prob(50) && armed && used_up != 1)
			if (suppress_flavourtext != 1)
				visible_message("<font color='red'><strong>[user] fumbles with the [name], accidentally setting it off!</strong></span>")
			triggered(user)
			return

		..()
		return

	attackby(obj/item/W as obj, mob/user as mob)
		if (prob(50) && armed && used_up != 1)
			if (suppress_flavourtext != 1)
				visible_message("<font color='red'><strong>[user] fumbles with the [name], accidentally setting it off!</strong></span>")
			triggered(user)
			return

		..()
		return

	attack_self(mob/user as mob)
		add_fingerprint(user)

		if (used_up != 0)
			user.show_text("The [name] has already been triggered and is no longer functional.", "red")
			return

		if (armed)
			armed = 0
			update_icon()
			user.show_text("You disarm the [name].", "blue")
			logTheThing("bombing", user, null, "has disarmed the [name] at [log_loc(user)].")

		if (our_timer && istype(our_timer))
			our_timer.attack_self(user)

		return

	receive_signal()
		if (used_up != 0)
			return

		playsound(loc, "sound/weapons/armbomb.ogg", 100, 1)
		armed = 1
		update_icon()
		return

	// Timer process() expects this to be here. Could be used for dynamic icon_states updates.
	proc/c_state()
		return

	ex_act(severity)
		if (used_up != 0 || !armed)
			return
		if (suppress_flavourtext != 1)
			visible_message("<font color='red'><strong>The explosion sets off the [name]!</strong></span>")
		triggered()
		return

	emp_act()
		if (used_up != 0 || !armed)
			return
		if (suppress_flavourtext != 1)
			visible_message("<font color='red'><strong>The electromagnetic pulse sets off the [name]!</strong></span>")
		triggered()
		return

	emag_act(var/mob/user, var/obj/item/card/emag/E)
		if (used_up != 0 || !armed)
			return FALSE
		if (suppress_flavourtext != 1)
			visible_message("<font color='red'><strong>The electric charge sets off the [name]!</strong></span>")
		triggered(user)
		return TRUE

	HasEntered(AM as mob|obj)
		if (AM == src || !(istype(AM, /obj/vehicle) || istype(AM, /obj/machinery/bot) || ismob(AM)))
			return
		if (ismob(AM) && (!isliving(AM) || isintangible(AM) || iswraith(AM)))
			return
		if (used_up != 0)
			return
		if (!armed)
			return

		if (suppress_flavourtext != 1)
			visible_message("<font color='red'><strong>[AM] triggers the [name]!</strong></span>")
		triggered(AM)
		return

	proc/update_icon()
		if (!src || !istype(src))
			return

		if (armed)
			icon_state = "mine_armed"
		else
			icon_state = "mine"

		return

	// Special effects handled by every type of mine.
	proc/custom_stuff(var/atom/M)
		return

	proc/triggered(var/atom/M)
		if (!src || !istype(src))
			return

		if (used_up != 0)
			qdel(src)
			return
		used_up = 1

		var/effects/system/spark_spread/s = unpool(/effects/system/spark_spread)
		s.set_up(3, 1, src)
		s.start()

		custom_stuff(M)
		log_me(M)

		qdel(src)
		return

	// For bioeffects or stuns, basically everything that should affect all mobs located on loc when triggered.
	proc/get_mobs_on_turf(var/radius = 0)
		var/list/mobs = list()

		if (!src || !istype(src))
			return mobs

		var/turf/T = get_turf(src)
		if (T && istype(T))
			for (var/mob/living/L in T.contents)
				if (!istype(L) || isintangible(L) || iswraith(L))
					continue
				if (!(L in mobs))
					mobs.Add(L)

		if (radius > 0)
			for (var/mob/living/L2 in range(src, radius))
				if (!istype(L2) || isintangible(L2) || iswraith(L2))
					continue
				if (!(L2 in mobs))
					mobs.Add(L2)

		return mobs

	proc/log_me(var/atom/M, var/mob/T)
		if (!src || !istype(src))
			return

		logTheThing("bombing", M && ismob(M) ? M : null, T && ismob(T) ? T : null, "The [name] was triggered at [log_loc(src)][T && ismob(T) ? ", affecting %target%." : "."] Last touched by: [fingerprintslast ? "[fingerprintslast]" : "*null*"]")
		return

/obj/item/mine/radiation
	name = "land mine (radiation)"
	desc = "An anti-personnel mine."

	armed
		armed = 1

	custom_stuff(var/atom/M)
		if (!src || !istype(src))
			return

		var/list/mobs = get_mobs_on_turf()
		if (M && isliving(M) && !(M in mobs))
			mobs.Add(M)
		if (mobs.len)
			for (var/mob/living/L in mobs)
				if (istype(L))
					L.irradiate(80)
					if (L.bioHolder)
						L.bioHolder.RandomEffect("bad")
					if (L != M)
						log_me(null, L)

		playsound(loc, 'sound/weapons/ACgun2.ogg', 50, 1)
		return

/obj/item/mine/incendiary
	name = "land mine (incendiary)"
	desc = "An anti-personnel mine."

	armed
		armed = 1

	custom_stuff(var/atom/M)
		if (!src || !istype(src))
			return

		fireflash_sm(get_turf(src), 3, 3000, 500)
		playsound(loc, 'sound/effects/bamf.ogg', 50, 1)
		return

/obj/item/mine/stun
	name = "land mine (stun)"
	desc = "An anti-personnel mine."

	armed
		armed = 1

	custom_stuff(var/atom/M)
		if (!src || !istype(src))
			return

		var/list/mobs = get_mobs_on_turf(1)
		if (M && isliving(M) && !(M in mobs))
			mobs.Add(M)
		if (mobs.len)
			for (var/mob/living/L in mobs)
				if (istype(L))
					L.weakened += 15
					L.stuttering += 15
					if (L != M)
						log_me(null, L)

		playsound(loc, 'sound/weapons/flashbang.ogg', 50, 1)
		return

/obj/item/mine/blast
	name = "land mine (blast)"
	desc = "An anti-personnel mine."

	armed
		armed = 1

	custom_stuff(var/atom/M)
		if (!src || !istype(src))
			return

		explosion(src, loc, 0, 1, 2, 3)
		return

/obj/item/mine/gibs
	name = "pustule"
	desc = "Some kind of weird little meat balloon."
	icon = 'icons/misc/meatland.dmi'
	icon_state = "meatmine"
	suppress_flavourtext = 1
	is_syndicate = 0
	mats = 0

	armed
		armed = 1

	update_icon()
		return

	custom_stuff(var/atom/M)
		if (!src || !istype(src))
			return

		visible_message("<span style=\"color:red\">[src] bursts[pick(" like an overripe melon!", " like an impacted bowel!", " like a balloon filled with blood!", "!", "!")]</span>")
		gibs(loc)
		playsound(loc, "sound/effects/fleshbr1.ogg", 50, 1)

		return