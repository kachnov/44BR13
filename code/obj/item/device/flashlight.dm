// Note: Hard hat and engineering space helmet can be found in helments.dm, the cake hat in hats.dm.

/obj/item/device/flashlight
	name = "flashlight"
	desc = "A hand-held emergency light."
	icon_state = "flight0"
	var/on = 0
	w_class = 2
	item_state = "flight"
	flags = FPRINT | ONBELT | TABLEPASS | CONDUCT
	m_amt = 50
	g_amt = 20
	mats = 2
	var/col_r = 0.9
	var/col_g = 0.8
	var/col_b = 0.7
	var/light/light
	module_research = list("science" = 1, "devices" = 1)

	New()
		..()
		light = new /light/point
		light.set_brightness(1)
		light.set_color(col_r, col_g, col_b)
		light.attach(src)

	attack_self(mob/user)
		on = !on
		icon_state = "flight[on]"

		if (on)
			light.enable()
		else
			light.disable()

	pickup(mob/user)
		..()
		light.attach(user)

	dropped(mob/user)
		..()
		spawn (0)
			if (loc != user)
				light.attach(src)

/obj/item/device/glowstick // fuck yeah space rave
	icon = 'icons/obj/lighting.dmi'
	icon_state = "glowstick-off"
	name = "emergency glowstick"
	desc = "For emergency use only. Not for use in illegal lightswitch raves."
	var/on = 0

	var/light/light

	New()
		..()
		light = new /light/point
		light.set_brightness(0.5)
		light.set_height(0.75)
		light.set_color(0.0,0.9,0.1)
		light.attach(src)

	pickup(mob/user)
		..()
		light.attach(user)

	dropped(mob/user)
		..()
		spawn (0)
			if (loc != user)
				light.attach(src)

	attack_self(mob/user as mob)
		if (!on)
			boutput(user, "<span style=\"color:blue\">You crack [src].</span>")
			on = 1
			icon_state = "glowstick-on"
			playsound(user.loc, "sound/effects/snap.ogg", 50, 1)
			light.enable()
		else
			if (prob(10))
				user.visible_message("<span style=\"color:blue\"><strong>[user]</strong> breaks [src]! What [pick("a clutz", "a putz", "a chump", "a doofus", "an oaf", "a jerk")]!</span>")
				playsound(user.loc, "sound/effects/snap.ogg", 50, 1)
				user.reagents.add_reagent("radium", 10)
				var/turf/T = get_turf(loc)
				new /obj/decal/cleanable/generic(T)
				new /obj/decal/cleanable/greenglow(T)
				qdel(src)
			else
				user.visible_message("<span style=\"color:blue\"><strong>[user]</strong> [pick("fiddles", "faffs around", "goofs around", "fusses", "messes")] with [src].</span>")

/obj/item/device/candle
	name = "candle"
	desc = "It's a big candle."
	icon = 'icons/effects/alch.dmi'
	icon_state = "candle-off"
	density = 0
	anchored = 0
	opacity = 0
	var/icon_off = "candle-off"
	var/icon_on = "candle"
	var/brightness = 1
	var/col_r = 0.5
	var/col_g = 0.3
	var/col_b = 0.0
	var/lit = 0
	var/light/light

	New()
		..()
		light = new /light/point
		light.set_brightness(brightness)
		light.set_color(col_r, col_g, col_b)
		light.attach(src)

	pickup(mob/user)
		..()
		light.attach(user)

	dropped(mob/user)
		..()
		spawn (0)
			if (loc != user)
				light.attach(src)

	attack_self(mob/user as mob)
		if (lit)
			var/fluff = pick("snuff", "blow")
			user.visible_message("<strong>[user]</strong> [fluff]s out [src].",\
			"You [fluff] out [src].")
			put_out(user)

	attackby(obj/item/W as obj, mob/user as mob)
		if (!lit)
			if (istype(W, /obj/item/weldingtool) && W:welding)
				light(user, "<span style=\"color:red\"><strong>[user]</strong> casually lights [src] with [W], what a badass.</span>")

			else if (istype(W, /obj/item/clothing/head/cakehat) && W:on)
				light(user, "<span style=\"color:red\">Did [user] just light \his [src] with [W]? Holy Shit.</span>")

			else if (istype(W, /obj/item/device/igniter))
				light(user, "<span style=\"color:red\"><strong>[user]</strong> fumbles around with [W]; a small flame erupts from [src].</span>")

			else if (istype(W, /obj/item/zippo) && W:lit)
				light(user, "<span style=\"color:red\">With a single flick of their wrist, [user] smoothly lights [src] with [W]. Damn they're cool.</span>")

			else if ((istype(W, /obj/item/match) || istype(W, /obj/item/device/candle)) && W:lit)
				light(user, "<span style=\"color:red\"><strong>[user] lights [src] with [W].</span>")

			else if (W.burning)
				light(user, "<span style=\"color:red\"><strong>[user]</strong> lights [src] with [W]. Goddamn.</span>")
		else
			return ..()

	process()
		if (lit)
			var/turf/location = loc
			if (ismob(location))
				var/mob/M = location
				if (M.find_in_hand(src))
					location = M.loc
			var/turf/T = get_turf(loc)
			if (T)
				T.hotspot_expose(700,5)

	proc/light(var/mob/user as mob, var/message as text)
		if (!src) return
		if (!lit)
			lit = 1
			damtype = "fire"
			force = 3
			icon_state = icon_on
			light.enable()
			if (!(src in processing_items))
				processing_items.Add(src)
		return

	proc/put_out(var/mob/user as mob)
		if (!src) return
		if (lit)
			lit = 0
			damtype = "brute"
			force = 0
			icon_state = icon_off
			light.disable()
			if (src in processing_items)
				processing_items.Remove(src)
		return

/obj/item/device/candle/spooky
	name = "spooky candle"
	desc = "It's a big candle. It's also floating."
	anchored = 1

	New()
		..()
		var/spookydegrees = rand(5, 20)

		spawn (rand(1, 10))
			animate(src, pixel_y = 32, transform = matrix(spookydegrees, MATRIX_ROTATE), time = 20, loop = -1, easing = SINE_EASING)
			animate(pixel_y = 0, transform = matrix(spookydegrees * -1, MATRIX_ROTATE), time = 20, loop = -1, easing = SINE_EASING)

/obj/item/device/candle/haunted
	name = "haunted candle"
	desc = "As opposed to your more standard spooky candle. It smells horrid."
	edible = 1 // eat a haunted goddamn candle every day
	var/did_thing = 0

	New()
		..()

		if (!reagents)
			var/reagents/R = new /reagents(50)
			reagents = R
			R.my_atom = src

	// yes this is dumb as hell but it makes me laugh a bunch
		reagents.add_reagent("wax", 20)
		reagents.add_reagent("black_goop", 10)
		reagents.add_reagent("yuck", 10)
		reagents.add_reagent("ectoplasm", 10)
		return



	light(var/mob/user as mob, var/message as text)
		..()
		if (lit && !did_thing)
			did_thing = 1
			//what should it do, other than this sound?? i tried a particle system but it didn't work :{
			playsound(get_turf(src), pick('sound/ambience/ambimo1.ogg','sound/ambience/ambimo2.ogg'), 65, 0)

		return

/obj/item/device/candle/small
	name = "small candle"
	desc = "It's a little candle."
	icon = 'icons/obj/decoration.dmi'
	icon_state = "lil_candle0"
	icon_off = "lil_candle0"
	icon_on = "lil_candle1"
	brightness = 0.8
