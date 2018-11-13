
// 4 arfur
// xoxo procitizen


/obj/item/clothing/suit/armor/batman/equipped(var/mob/user)
	user.verbs += /client/proc/batsmoke
	user.verbs += /client/proc/batarang
	user.verbs += /mob/proc/batkick
	user.verbs += /mob/proc/batrevive
	user.verbs += /mob/proc/batattack
	user.verbs += /mob/proc/batspinkick
	user.verbs += /mob/proc/batspin
	user.verbs += /mob/proc/batdropkick

/obj/item/clothing/suit/armor/batman/unequipped(var/mob/user)
	user.verbs -= /client/proc/batsmoke
	user.verbs -= /client/proc/batarang
	user.verbs -= /mob/proc/batkick
	user.verbs -= /mob/proc/batrevive
	user.verbs -= /mob/proc/batattack
	user.verbs -= /mob/proc/batspinkick
	user.verbs -= /mob/proc/batspin
	user.verbs -= /mob/proc/batdropkick

/client/proc/batsmoke()
	set category = "Batman"
	set name = "Batsmoke \[Support]"

	var/effects/system/bad_smoke_spread/smoke = new /effects/system/bad_smoke_spread()
	smoke.set_up(10, 0, usr.loc)
	smoke.start()

/client/proc/batarang(mob/T as mob in oview())
	set category = "Batman"
	set name = "Batarang \[Combat]"

	for (var/mob/O in viewers(usr, null))
		O.show_message(text("<span style=\"color:red\">[] tosses a batarang at []!</span>", usr, T), 1)
	var/obj/overlay/A = new /obj/overlay( usr.loc )
	A.icon_state = "batarang"
	A.icon = 'icons/effects/effects.dmi'
	A.name = "a batarang"
	A.anchored = 0
	A.density = 0
	var/i
	for (i=0, i<100, i++)
		step_to(A,T,0)
		if (get_dist(A,T) <= 1)
			T.weakened += 5
			T.stunned += 5
			for (var/mob/O in viewers(T, null))
				O.show_message(text("<span style=\"color:red\">[] was struck by the batarang!</span>", T), 1)
			qdel(A)
		sleep(2)
	qdel(A)
	return

/mob/proc/batkick(mob/T as mob in oview(1))
	set category = "Batman"
	set name = "Bat Kick \[Combat]"
	set desc = "A powerful stunning kick, sending people flying across the room"

	spawn (0)
		if (T)
			for (var/mob/O in viewers(src, null))
				O.show_message(text("<span style=\"color:red\"><strong>[] powerfully kicks []!</strong></span>", usr, T), 1)
			T.weakened += 6
			step_away(T,usr,15)
			sleep(1)
			step_away(T,usr,15)
			sleep(1)
			step_away(T,usr,15)
			playsound(T.loc, "swing_hit", 25, 1, -1)

/mob/proc/batrevive()
	set category = "Batman"
	set name = "Recover \[Support]"
	set desc = "Unstuns you"

	if (!usr.weakened)
		usr.stunned = 0
		for (var/mob/O in viewers(src, null))
			O.show_message(text("<span style=\"color:red\"><strong>[] suddenly recovers!</strong></span>", usr), 1)
	else
		usr.weakened = 0
		usr.stunned = 0
		for (var/mob/O in viewers(src, null))
			O.show_message(text("<span style=\"color:red\"><strong>[] suddenly jumps up!</strong></span>", usr), 1)

/mob/proc/batattack(mob/T as mob in oview(1))
	set category = "Batman"
	set name = "Bat Punch \[Combat]"
	set desc = "Attack, but Batman-like ok"

	if (usr.stat)
		boutput(usr, "<span style=\"color:red\">Not when you're incapped!</span>")
		return
	spawn (0)
		for (var/mob/O in viewers(src, null))
			O.show_message(text("<span style=\"color:red\"><strong>[] punches []!</strong></span>", usr, T), 1)
		var/zone = "chest"
		if (usr.zone_sel)
			zone = usr.zone_sel.selecting
		if ((zone in list( "eyes", "mouth" )))
			zone = "head"
		T.TakeDamage(zone, 4, 0)
		T.stunned += 1
		var/icon/I = icon('icons/effects/effects.dmi',prob(50) ? "batpow" : "batwham")
		T.overlays += I
		spawn (50) T.overlays -= I
		T.updatehealth()

/mob/proc/batspinkick(mob/T as mob in oview(1))
	set category = "Batman"
	set name = "Batkick \[Finisher]"
	set desc = "A spinning kick that drops motherfuckers to the CURB"

	var/icon/I = icon('icons/effects/effects.dmi',"batpow")
	var/icon/R = icon('icons/effects/effects.dmi', "batwham")
	if (usr.stat)
		boutput(usr, "<span style=\"color:red\">Not when you're incapped!</span>")
		return
	spawn (0)
		T.transforming = 1
		transforming = 1
		for (var/mob/O in viewers(src, null))
			O.show_message(text("<span style=\"color:red\"><strong>[] leaps in the air, shocking []!</strong></span>", usr, T), 1)
		for (var/i = 0, i < 5, i++)
			usr.pixel_y += 4
			sleep(2)
		sleep(10)
		for (var/mob/O in viewers(src, null))
			O.show_message(text("<span style=\"color:red\"><strong>[] begins kicking [] in the face rapidly!</strong></span>", usr, T), 1)
		for (var/i = 0, i < 5, i++)
			usr.dir = NORTH
			T.TakeDamage("head", 4, 0)
			T.updatehealth()
			T.overlays -= R
			T.overlays += I
			for (var/mob/O in viewers(src, null))
				O.show_message(text("<span style=\"color:red\"><strong>[] kicks [] in the face!</strong></span>", usr, T), 1)
			playsound(T.loc, "swing_hit", 25, 1, -1)
			sleep(1)
			usr.dir = EAST
			T.TakeDamage("head", 4, 0)
			T.updatehealth()
			T.overlays -= I
			T.overlays += R
			for (var/mob/O in viewers(src, null))
				O.show_message(text("<span style=\"color:red\"><strong>[] kicks [] in the face!</strong></span>", usr, T), 1)
			playsound(T.loc, "swing_hit", 25, 1, -1)
			sleep(1)
			usr.dir = SOUTH
			T.TakeDamage("head", 4, 0)
			T.updatehealth()
			T.overlays -= R
			T.overlays += I
			for (var/mob/O in viewers(src, null))
				O.show_message(text("<span style=\"color:red\"><strong>[] kicks [] in the face!</strong></span>", usr, T), 1)
			playsound(T.loc, "swing_hit", 25, 1, -1)
			sleep(1)
			usr.dir = WEST
			T.TakeDamage("head", 4, 0)
			T.updatehealth()
			T.overlays -= I
			T.overlays += R
			for (var/mob/O in viewers(src, null))
				O.show_message(text("<span style=\"color:red\"><strong>[] kicks [] in the face!</strong></span>", usr, T), 1)
			playsound(T.loc, "swing_hit", 25, 1, -1)
		usr.dir = get_dir(usr, T)
		for (var/mob/O in viewers(src, null))
			O.show_message(text("<span style=\"color:red\"><strong>[] stares deeply at []!</strong></span>", usr, T), 1)
		sleep(50)
		for (var/mob/O in viewers(src, null))
			O.show_message(text("<span style=\"color:red\"><strong>[] unleashes a tremendous kick to the jaw towards []!</strong></span>", usr, T), 1)
		playsound(T.loc, "swing_hit", 25, 1, -1)
		flick("e_flash", T.flash)
		T.transforming = 0
		T.weakened += 6
		step_away(T,usr,15)
		sleep(1)
		step_away(T,usr,15)
		sleep(1)
		step_away(T,usr,15)
		sleep(1)
		step_away(T,usr,15)
		sleep(1)
		step_away(T,usr,15)
		T.TakeDamage("head", 70, 0)
		T.updatehealth()
		for (var/i = 0, i < 5, i++)
			usr.pixel_y += 10
			sleep(1)
		usr.set_loc(T.loc)
		usr.weakened = 10
		usr.transforming = 0
		for (var/i = 0, i < 5, i++)
			usr.pixel_y -= 8
			sleep(1)
		usr.pixel_y = 0
		for (var/mob/O in viewers(src, null))
			O.show_message(text("<span style=\"color:red\"><strong>[] elbow drops [] into oblivion!</strong></span>", usr, T), 1)
		T.gib()

/mob/proc/batspin(mob/T as mob in oview(1))
	set category = "Batman"
	set name = "Bat Spin \[Finisher]"
	set desc = "Grab someone and spin them around until they explode"

	spawn (0)
		for (var/mob/O in viewers(src, null))
			O.show_message(text("<span style=\"color:red\"><strong>[] grabs [] tightly!</strong></span>", usr, T), 1)
		usr.transforming = 1
		T.transforming = 1
		T.u_equip(l_hand)
		T.u_equip(r_hand)
		sleep(30)
		for (var/mob/O in viewers(src, null))
			O.show_message(text("<span style=\"color:red\"><strong>[] starts spinning [] around!</strong></span>", usr, T), 1)
		for (var/i = 0, i < 2, i++)
			T.dir = NORTH
			sleep(5)
			T.dir = EAST
			sleep(5)
			T.dir = SOUTH
			sleep(5)
			T.dir = WEST
			sleep(5)
		for (var/i = 0, i < 1, i++)
			T.dir = NORTH
			sleep(2)
			T.dir = EAST
			sleep(2)
			T.dir = SOUTH
			sleep(2)
			T.dir = WEST
			sleep(2)
		boutput(T, "<span style=\"color:red\">YOU'RE GOING TOO FAST!!!</span>")
		for (var/i = 0, i < 10, i++)
			T.dir = NORTH
			sleep(1)
			T.dir = EAST
			sleep(1)
			T.dir = SOUTH
			sleep(1)
			T.dir = WEST
			sleep(1)
		for (var/mob/O in viewers(src, null))
			O.show_message(text("<span style=\"color:red\"><strong>[] suddenly explodes</strong>!</span>", T), 1)
		T.gib()

/mob/proc/batdropkick(mob/T as mob in oview())
	set category = "Batman"
	set name = "Drop Kick \[Disabler]"
	set desc = "Fall to the ground, leap up and knock a dude out"

	spawn (0)
		for (var/mob/O in viewers(src, null))
			O.show_message(text("<span style=\"color:red\"><strong>[] falls to the ground</strong>!</span>", usr), 1)
		usr.weakened += 760 // lol whatever
		sleep(20)
		for (var/mob/O in viewers(src, null))
			O.show_message(text("<span style=\"color:red\"><strong>[] launches towards []</strong>!</span>", usr, T), 1)
		for (var/i=0, i<100, i++)
			step_to(usr,T,0)
			if (get_dist(usr,T) <= 1)
				T.weakened += 10
				T.stunned += 10
				for (var/mob/O in viewers(src, null))
					O.show_message(text("<span style=\"color:red\"><strong>[] flies at [], slamming \him in the head</strong>!</span>", usr, T), 1)
				usr.weakened = 0
				i=100
			sleep(1)

