/obj/machinery/portableowl //Owl version of the portable flasher
	name = "Portable Owl"
	desc = "A portable flashing... device? Hoot."
	icon = 'icons/obj/hooty.dmi'
	icon_state = "owl"
	var/base_state = "owl"
	anchored = 0
	density = 1
	var/last_flash = 0
	var/flash_prob = 80

	proc/flash()
		if (last_flash && world.time < last_flash + 10)
			return

		playsound(loc, "sound/misc/hoot.ogg", 100, 1)
		flick("[base_state]_flash", src)
		last_flash = world.time

	HasProximity(atom/movable/AM as mob|obj)
		if (last_flash && world.time < last_flash + 10)
			return

		if (iscarbon(AM))
			var/mob/living/carbon/M = AM
			if ((M.m_intent != "walk") && (anchored))
				if (M.client) // I can't take it anymore I can't take the destiny owls reacting to the monkey it's driving me mad
					if (prob(flash_prob))
						flash()

	attackby(obj/item/W as obj, mob/user as mob)
		if (istype(W, /obj/item/wrench))
			add_fingerprint(user)
			anchored = !anchored

			if (!anchored)
				user.show_message(text("<span style=\"color:red\">[src] can now be moved.</span>"))

			else if (anchored)
				user.show_message(text("<span style=\"color:red\">[src] is now secured.</span>"))

	attack_hand(user)
		if (anchored)
			if (last_flash && world.time < last_flash + 10)
				return

			flash()

/obj/machinery/portableowl/attached
	anchored = 1

/obj/machinery/portableowl/judgementowl
	name = "Hooty McJudgementowl"
	desc = "A grumpy looking owl."
	icon_state = "judgementowl1"
	base_state = "judgementowl1"
	anchored = 1

	New()
		..()
		base_state = "judgementowl[rand(1,32)]"
		icon_state = base_state

	process()
		..()
		if (prob(10)) // I stole this from the automaton because I am a dirty code frankenstein
			var/list/mobsnearby = list()
			for (var/mob/M in view(7,src))
				if (iswraith(M) || isintangible(M))
					continue
				mobsnearby.Add("[M.name]")
			var/mob/M1 = null
			if (mobsnearby.len > 0)
				M1 = pick(mobsnearby)
			if (M1 && prob(50))
				visible_message("<span style=\"color:red\"><strong>[src]</strong> frowns at [M1].</span>")