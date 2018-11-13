/obj/item/assembly/shock_kit
	name = "Shock Kit"
	icon_state = "shock_kit"
	var/obj/item/clothing/head/helmet/part1 = null
	var/obj/item/device/radio/electropack/part2 = null
	status = 0.0
	w_class = 5.0
	flags = FPRINT | TABLEPASS| CONDUCT

/obj/item/assembly/shock_kit/New()
	spawn (20)
		if (src)
			if (!(part1 && istype(part1)))
				part1 = new /obj/item/clothing/head/helmet(src)
				part1.master = src
			if (!(part2 && istype(part2)))
				part2 = new /obj/item/device/radio/electropack(src)
				part2.master = src
	return

/obj/item/assembly/shock_kit/disposing()
	if (part1)
		qdel(part1)
		part1 = null
	if (part2)
		qdel(part2)
		part2 = null
	..()
	return

/obj/item/assembly/shock_kit/attackby(obj/item/W as obj, mob/user as mob)
	add_fingerprint(user)

	if (istype(W, /obj/item/wrench))
		var/turf/T = get_turf(src)
		if (part1)
			part1.set_loc(T)
			part1.master = null
			part1 = null
		if (part2)
			part2.set_loc(T)
			part2.master = null
			part2 = null
		qdel(src)
		return

	else return ..()

/obj/item/assembly/shock_kit/attack_self(mob/user as mob)
	part1.attack_self(user, status)
	part2.attack_self(user, status)
	add_fingerprint(user)
	return

/obj/item/assembly/shock_kit/receive_signal()
	if (master && istype(master, /obj/stool/chair/e_chair))
		var/obj/stool/chair/e_chair/C = master
		if (C.buckled_guy)
			logTheThing("signalers", usr, C.buckled_guy, "signalled an electric chair (setting: [C.lethal ? "lethal" : "non-lethal"]), shocking %target% at [log_loc(C)].") // Added (Convair880).
		C.shock()
	return