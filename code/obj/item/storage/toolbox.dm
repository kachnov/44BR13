
/* -------------------- Standard Toolboxes -------------------- */

/obj/item/storage/toolbox
	name = "toolbox"
	icon = 'icons/obj/storage.dmi'
	inhand_image_icon = 'icons/mob/inhand/hand_tools.dmi'
	icon_state = "red"
	item_state = "toolbox_red"
	flags = FPRINT | TABLEPASS | CONDUCT | NOSPLASH
	force = 5.0
	throwforce = 10.0
	throw_speed = 1
	throw_range = 7
	w_class = 4.0
	max_wclass = 3

	//cogwerks - burn vars
	burn_point = 4500
	burn_output = 4800
	burn_type = 1
	stamina_damage = 40
	stamina_cost = 30
	stamina_crit_chance = 10

	New()
		..()
		if (type == /obj/item/storage/toolbox)
			message_admins("BAD: [src] ([type]) spawned at [showCoords(x, y, z)]")
			qdel(src)

	suicide(var/mob/user as mob)
		user.visible_message("<span style=\"color:red\"><strong>[user] slams the toolbox closed on \his head repeatedly!</strong></span>")
		user.TakeDamage("head", 150, 0)
		user.updatehealth()
		spawn (100)
			if (user)
				user.suiciding = 0
		return TRUE

/obj/item/storage/toolbox/emergency
	name = "emergency toolbox"
	icon_state = "red"
	item_state = "toolbox_red"
	desc = "A metal container designed to hold various tools. This variety holds supplies required for emergencies."
	spawn_contents = list(/obj/item/crowbar,\
	/obj/item/extinguisher,\
	/obj/item/device/flashlight,\
	/obj/item/device/radio)

/obj/item/storage/toolbox/mechanical
	name = "mechanical toolbox"
	icon_state = "blue"
	item_state = "toolbox_blue"
	desc = "A metal container designed to hold various tools. This variety holds standard construction tools."
	spawn_contents = list(/obj/item/screwdriver,\
	/obj/item/wrench,\
	/obj/item/weldingtool,\
	/obj/item/crowbar,\
	/obj/item/device/analyzer,\
	/obj/item/wirecutters)

/obj/item/storage/toolbox/electrical
	name = "electrical toolbox"
	icon_state = "yellow"
	item_state = "toolbox_yellow"
	desc = "A metal container designed to hold various tools. This variety holds electrical supplies."
	spawn_contents = list(/obj/item/screwdriver,\
	/obj/item/wirecutters,\
	/obj/item/device/t_scanner,\
	/obj/item/crowbar,\
	/obj/item/cable_coil = 3)

	// The extra items (scanner and soldering iron) take up precious space in the backpack.
	mechanic_spawn
		spawn_contents = list(/obj/item/screwdriver,\
		/obj/item/wirecutters,\
		/obj/item/device/t_scanner,\
		/obj/item/crowbar,\
		/obj/item/electronics/scanner,\
		/obj/item/electronics/soldering,\
		/obj/item/cable_coil)

/obj/item/storage/toolbox/artistic
	name = "artistic toolbox"
	desc = "A metal container designed to hold various tools. This variety holds art supplies."
	icon_state = "green"
	item_state = "toolbox_green"
	spawn_contents = list(/obj/item/paint_can/random = 7)

/* -------------------- Memetic Toolbox -------------------- */

/obj/item/storage/toolbox/memetic
	name = "artistic toolbox"
	desc = "His Grace."
	icon_state = "green"
	item_state = "toolbox_green"
	var/list/servantlinks = list()
	var/hunger = 0
	var/hunger_message_level = 0
	var/original_owner = null
	cant_other_remove = 1

	examine()
		set src in view()
		var/mob/living/carbon/human/H = usr
		if (!istype(H))
			boutput(H, "It almost hurts to look at that, it's all out of focus.")
			return
		if (H.find_ailment_by_type(/ailment/disability/memetic_madness))
			..()
			return
		else
			H.contract_memetic_madness(src)
			if (!original_owner)
				original_owner = H
		return

	MouseDrop(over_object, src_location, over_location)
		if (!ishuman(usr) || !usr:find_ailment_by_type(/ailment/disability/memetic_madness))
			boutput(usr, "<span style=\"color:red\">You can't seem to find the latch. Maybe you need to examine it more thoroughly?</span>")
			return
		return ..()

	attack_hand(mob/user as mob)
		if (loc == user)
			if (!ishuman(user) || !user:find_ailment_by_type(/ailment/disability/memetic_madness))
				boutput(user, "<span style=\"color:red\">You can't seem to find the latch. Maybe you need to examine it more thoroughly?</span>")
				return
		return ..()

	attackby(obj/item/W as obj, mob/user as mob)
		if (!ishuman(user) || !user:find_ailment_by_type(/ailment/disability/memetic_madness))
			boutput(user, "<span style=\"color:red\">You can't seem to find the latch to open this. Maybe you need to examine it more thoroughly?</span>")
			return
		if (contents.len >= 7)
			return
		if (((istype(W, /obj/item/storage) && W.w_class > 2) || loc == W))
			return
		if (istype(W, /obj/item/grab))	// It will devour people! It's an evil thing!
			var/obj/item/grab/G = W
			if (!G.affecting) return
			if (!G.affecting.stat && !G.affecting.restrained() && !G.affecting.weakened)
				boutput(user, "<span style=\"color:red\">They're moving too much to feed to His Grace!</span>")
				return
			user.visible_message("<span style=\"color:red\"><strong>[user] is trying to feed [G.affecting] to [src]!</strong></span>")
			if (!do_mob(user, G.affecting, 30)) return
			G.affecting.set_loc(src)
			user.visible_message("<span style=\"color:red\"><strong>[user] has fed [G.affecting] to [src]!</strong></span>")

			consume(G.affecting, G)

			boutput(user, "<em><strong><font face = Tempus Sans ITC>You have done well...</font></strong></em>")
			force += 5
			throwforce += 5
			return

		return ..()

	proc/consume(mob/M as mob, var/obj/item/grab/G)
		if (!M)
			return

		hunger = 0
		hunger_message_level = 0
		playsound(loc, pick("sound/misc/burp_alien.ogg"), 50, 0)
		//Neatly sort everything they have into handy little boxes.
		var/obj/item/storage/box/per_person = new
		per_person.set_loc(src)
		var/obj/item/storage/box/Gcontents = new
		Gcontents.set_loc(per_person)
		per_person.name = "Box-'[M.real_name]'"
		for (var/obj/item/looted in M)
			if (Gcontents.contents.len >= 7)
				Gcontents = new
				Gcontents.set_loc(per_person)
			if (istype(looted, /obj/item/implant)) continue
			M.u_equip(looted)
			if (looted == src)
				layer = initial(layer)
				set_loc(get_turf(M))
				continue

			if (looted)
				looted.set_loc(Gcontents)
				looted.layer = initial(looted.layer)
				looted.dropped(M)

		M.ghostize()
		var/we_need_to_die = (M == original_owner)
		var/mob/dead_jerk = M
		spawn (5)
			if (dead_jerk)
				qdel(dead_jerk)
			if (G)
				qdel(G)
			if (we_need_to_die)
				new /obj/item/storage/toolbox/emergency {name = "artistic toolbox"; desc = "It looks a lot duller than it used to."; icon_state = "green"; item_state = "toolbox_green";} (get_turf(src))
				qdel(src)

		return

	disposing()
		for (var/mob/M in src) //Release trapped dudes...
			M.set_loc(get_turf(src))
			visible_message("<span style=\"color:red\">[M] bursts out of [src]!</span>")

		for (var/ailment_data/A in src.servantlinks) //Remove the plague...
			if (istype(A.master,/ailment/disability/memetic_madness))
				A.dispose()
				break

		if (servantlinks)
			servantlinks.len = 0
		servantlinks = null

		visible_message("<span style=\"color:red\"><strong>[src]</strong> screams!</span>")
		playsound(loc,"sound/effects/screech.ogg", 100, 1)

		..()
		return

	hear_talk(var/mob/living/carbon/speaker, messages, real_name, lang_id)
		if (!speaker || !messages)
			return
		if (loc != speaker) return
		for (var/ailment_data/A in servantlinks)
			var/mob/living/M = A.affected_mob
			if (!M || M == speaker)
				continue

			boutput(M, "<em><strong><font color=blue face = Tempus Sans ITC>[messages[1]]</font></strong></em>")

		return

/mob/living/proc/contract_memetic_madness(var/obj/item/storage/toolbox/memetic/newprogenitor)
	if (find_ailment_by_type(/ailment/disability/memetic_madness))
		return

	resistances -= /ailment/disability/memetic_madness
	// just going to have to set it up manually i guess
	var/ailment_data/memetic_madness/AD = new /ailment_data/memetic_madness

	if (istype(newprogenitor,/obj/item/storage/toolbox/memetic))
		AD.progenitor = newprogenitor
		ailments += AD
		AD.affected_mob = src
		newprogenitor.servantlinks.Add(AD)
		newprogenitor.force += 4
		newprogenitor.throwforce += 4
	else
		qdel(AD)
		return

	var/acount = 0
	var/amax = rand(10,15)
	var/screamstring = null
	var/asize = 1
	while (acount <= amax)
		screamstring += "<font size=[asize]>a</font>"
		if (acount > (amax/2))
			asize--
		else
			asize++
		acount++
	playsound_local(loc,"sound/effects/screech.ogg", 100, 1)
	shake_camera(src, 20, 1)
	boutput(src, "<font color=red>[screamstring]</font>")
	boutput(src, "<em><strong><font face = Tempus Sans ITC>His Grace accepts thee, spread His will! All who look close to the Enlightened may share His gifts.</font></strong></em>")
	return

/*
 *	MEMETIC DISEASE
 */

/ailment_data/memetic_madness
	var/obj/item/storage/toolbox/memetic/progenitor = null
	stage_prob = 8

	New()
		master = get_disease_from_path(/ailment/disability/memetic_madness)

	stage_act()
		if (!istype(master,/ailment) || !progenitor)
			affected_mob.ailments -= src
			qdel(src)
			return

		if (stage > master.max_stages)
			stage = master.max_stages

		if (prob(stage_prob) && stage < master.max_stages)
			stage++

		master.stage_act(affected_mob,src,progenitor)

		return

/ailment/disability/memetic_madness
	name = "Memetic Kill Agent"
	cure = "Unknown"
	affected_species = list("Human")
	max_stages = 4
	stage_prob = 8

	stage_act(var/mob/living/affected_mob,var/ailment_data/D,var/obj/item/storage/toolbox/memetic/progenitor)
		if (..())
			return
		if (progenitor in affected_mob.contents)
			if (affected_mob.get_oxygen_deprivation())
				affected_mob.take_oxygen_deprivation(-5)
			affected_mob:HealDamage("All", 12, 12)
			if (affected_mob.get_toxin_damage())
				affected_mob.take_toxin_damage(-5)
			if (affected_mob:stunned) affected_mob:stunned = 0
			if (affected_mob:weakened) affected_mob:weakened = 0
			if (affected_mob:paralysis) affected_mob:paralysis = 0
			affected_mob.dizziness = max(0,affected_mob.dizziness-10)
			affected_mob:drowsyness = max(0,affected_mob:drowsyness-10)
			affected_mob:sleeping = 0
			D.stage = 1
			switch (progenitor.hunger)
				if (10 to 60)
					if (progenitor.hunger_message_level < 1)
						progenitor.hunger_message_level = 1
						boutput(affected_mob, "<em><strong><font face = Tempus Sans ITC>Feed Me the unclean ones...They will be purified...</font></strong></em>")
				if (61 to 120)
					if (progenitor.hunger_message_level < 2)
						progenitor.hunger_message_level = 2
						boutput(affected_mob, "<em><strong><font face = Tempus Sans ITC>I hunger for the flesh of the impure...</font></strong></em>")
				if (121 to 210)
					if (prob(10) && progenitor.hunger_message_level < 3)
						progenitor.hunger_message_level = 3
						boutput(affected_mob, "<em><strong><font face = Tempus Sans ITC>The hunger of Your Master grows with every passing moment.  Feed Me at once.</font></strong></em>")
				if (230 to 399)
					if (progenitor.hunger_message_level < 4)
						progenitor.hunger_message_level = 4
						boutput(affected_mob, "<em><strong><font face = Tempus Sans ITC>His Grace starves in your hands.  Feed Me the unclean or suffer.</font></strong></em>")
				if (300 to INFINITY)
					affected_mob.visible_message("<span style=\"color:red\"><strong>[progenitor] consumes [affected_mob] whole!</strong></span>")
					progenitor.consume(affected_mob)
					return

			progenitor.hunger += min(max((progenitor.force / 10), 1), 10)

		else if (D.stage == 4)
			if (get_dist(get_turf(progenitor),src) <= 7)
				D.stage = 1
				return
			if (prob(4))
				boutput(affected_mob, "<span style=\"color:red\">We are too far from His Grace...</span>")
				affected_mob.take_toxin_damage(5)
				affected_mob.updatehealth()
			else if (prob(6))
				boutput(affected_mob, "<span style=\"color:red\">You feel weak.</span>")
				random_brute_damage(affected_mob, 5)

			if (ismob(progenitor.loc))
				progenitor.hunger++

		return

	/*
	disposing()
		if (affected_mob)
			affected_mob.playsound_local(affected_mob.loc,'sound/effects/screech.ogg', 100, 1)
			boutput(affected_mob, "<em><strong><font face = Tempus Sans ITC>NOOOO</font></strong></em>")
			affected_mob.paralysis = 10
			if (affected_mob.ailments)
				affected_mob.ailments -= src
			affected_mob = null
			progenitor = null
		..()
	*/

/*
 *	His Grace for Dummies
 */

/obj/item/paper/memetic_manual
	name = "paper- 'So You Want to Worship His Grace'"
	info = {"<center><h4>Worship QuickStart</h4></center><ol>
	<li>Gaze into His Grace. Observe His magnificence. Examine the quality of His form.</li>
	<li>Carry His Grace. Show the unbelievers the power of Him.  Know that all who gaze upon the splendor of His Chosen will know of Him.</li>
	<li>His Grace hungers! Take the unworthy ones in your hands and place them inside Him!</li>
	<li>After every nourishment, His Grace will hold their spoils. Remove these from Him and make great use of them, as gifts.</li>
	<li>Know that the His might will grow with every new Chosen and, in turn, the power of the Chosen carrying Him. But be warned! As He grows in strength, so doth His appetite!</li>
	</ol>
	"}