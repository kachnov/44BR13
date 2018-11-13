//MEDBOT
//MEDBOT PATHFINDING
//MEDBOT ASSEMBLY

/obj/machinery/bot/medbot
	name = "Medibot"
	desc = "A little medical robot. He looks somewhat underwhelmed."
	icon = 'icons/obj/medbots.dmi'
	icon_state = "medibot"
	layer = 5.0 //TODO LAYER
	density = 0
	anchored = 0
	luminosity = 2
	req_access = list(access_medical)
	access_lookup = "Medical Doctor"
	flags = NOSPLASH
	on = 1
	health = 20
	var/stunned = 0 //It can be stunned by tasers. Delicate circuits.
	locked = 1

	var/obj/item/reagent_containers/glass/reagent_glass = null //Can be set to draw from this for reagents.
	var/skin = null // options are brute1/2, burn1/2, toxin1/2, brain1/2, O21/2/3/4, berserk1/2/3, and psyche
	var/frustration = 0
	var/list/path = null
	var/mob/living/carbon/patient = null
	var/mob/living/carbon/oldpatient = null
	var/oldloc = null
	var/last_found = 0
	var/last_newpatient_speak = 0 //Don't spam the "HEY I'M COMING" messages
	var/currently_healing = 0
	var/injection_amount = 10 //How much reagent do we inject at a time?
	var/heal_threshold = 15 //Start healing when they have this much damage in a category
	var/use_beaker = 0 //Use reagents in beaker instead of default treatment agents.
	//Setting which reagents to use to treat what by default. By id.
	var/treatment_brute = "saline"
	var/treatment_oxy = "salbutamol"
	var/treatment_fire = "saline"
	var/treatment_tox = "charcoal"
	var/treatment_virus = "spaceacillin"
	var/terrifying = 0 // for making the medbots all super fucked up
	var/light/light

/obj/machinery/bot/medbot/no_camera
	no_camera = 1

/obj/machinery/bot/medbot/mysterious
	name = "Mysterious Medibot"
	desc = "International Medibot of mystery."
	skin = "berserk"

/obj/machinery/bot/medbot/terrifying
	name = "Medibot"
	desc = "You don't recognize this model."
	icon = 'icons/misc/evilreaverstation.dmi'
	health = 50
	density = 1
	emagged = 1
	terrifying = 1
	anchored = 1 // don't drag it into space goddamn jerks
	no_camera = 1

/obj/machinery/bot/medbot/head_surgeon
	name = "Medibot - 'Head Surgeon'"
	desc = "The HS sure looks different today! Maybe he got a haircut?"
	skin = "hs"
	treatment_oxy = "perfluorodecalin"
	access_lookup = "Head Surgeon"
	text2speech = 1

/obj/machinery/bot/medbot/head_surgeon/no_camera
	no_camera = 1

/obj/machinery/bot/medbot/psyche
	name = "Psychedelic Medibot"
	desc = "He's high on a hell of a lot more than life!"
	skin = "psyche"
	treatment_brute = "LSD"
	treatment_oxy = "psilocybin"
	treatment_fire = "LSD"
	treatment_tox = "psilocybin"
	treatment_virus = "loose screws"
	no_camera = 1

/obj/item/firstaid_arm_assembly
	name = "first aid/robot arm assembly"
	desc = "A first aid kit with a robot arm permanently grafted to it."
	icon = 'icons/obj/medbots.dmi'
	icon_state = "medskin-firstaid"
	item_state = "firstaid"
	pixel_y = 4 // so we don't have to have two sets of the skin sprites, we're just gunna bump this up a bit
	var/build_step = 0
	var/created_name = "Medibot" //To preserve the name if it's a unique medbot I guess
	var/skin = null // same as the bots themselves: options are brute1/2, burn1/2, toxin1/2, brain1/2, O21/2/3/4, berserk1/2/3, and psyche
	w_class = 3.0

/obj/item/firstaid_arm_assembly/New()
	..()
	spawn (5)
		if (skin)
			overlays += "medskin-[skin]"
			overlays += "medibot-arm"

/obj/machinery/bot/medbot/proc/update_icon(var/stun = 0, var/heal = 0)
	if (overlays)
		overlays = null

	if (terrifying)
		icon_state = "medibot[on]"
		if (stun)
			overlays += "medibota"
		if (heal)
			overlays += "medibots"
		return

	else
		icon_state = "medibot"
		if (skin)
			overlays += "medskin-[skin]"
		overlays += "medibot-scanner"
		if (heal)
			overlays += "medibot-arm-syringe"
			overlays += "medibot-light-flash"
		else
			overlays += "medibot-arm"
			if (stun)
				overlays += "medibot-light-stun"
			else
				overlays += "medibot-light[on]"
		/*
		if (emagged)
			overlays += "medibot-spark"
		*/
		return

/obj/machinery/bot/medbot/New()
	..()
	light = new /light/point
	light.attach(src)
	light.set_brightness(0.5)

	spawn (5)
		if (src)
			botcard = new /obj/item/card/id(src)
			botcard.access = get_access(access_lookup)
			update_icon()
	return

/obj/machinery/bot/medbot/examine()
	set src in view()
	set category = "Local"
	..()

	if (health < 20)
		if (health > 15)
			boutput(usr, text("<span style=\"color:red\">[src]'s parts look loose.</span>"))
		else
			boutput(usr, text("<span style=\"color:red\"><strong>[src]'s parts look very loose!</strong></span>"))
	return

/obj/machinery/bot/medbot/attack_ai(mob/user as mob)
	return toggle_power()

/obj/machinery/bot/medbot/attack_hand(mob/user as mob)

	if (isxenomorph(user))
		var/mob/living/carbon/human/xenomorph/X = user 
		return X.melee_attack(src)
			
	if (terrifying)
		return

	var/dat
	dat += "<TT><strong>Automatic Medical Unit v1.0</strong></TT><BR><BR>"
	dat += "Status: <A href='?src=\ref[src];power=1'>[on ? "On" : "Off"]</A><BR>"
	dat += "Beaker: "
	if (reagent_glass)
		dat += "<A href='?src=\ref[src];eject=1'>Loaded \[[reagent_glass.reagents.total_volume]/[reagent_glass.reagents.maximum_volume]\]</a>"
	else
		dat += "None Loaded"
	dat += "<br>Behaviour controls are [locked ? "locked" : "unlocked"]<hr>"
	if (!locked)
		dat += "<TT>Healing Threshold: "
		dat += "<a href='?src=\ref[src];adj_threshold=-10'>--</a> "
		dat += "<a href='?src=\ref[src];adj_threshold=-5'>-</a> "
		dat += "[heal_threshold] "
		dat += "<a href='?src=\ref[src];adj_threshold=5'>+</a> "
		dat += "<a href='?src=\ref[src];adj_threshold=10'>++</a>"
		dat += "</TT><br>"

		dat += "<TT>Injection Level: "
		dat += "<a href='?src=\ref[src];adj_inject=-5'>-</a> "
		dat += "[injection_amount] "
		dat += "<a href='?src=\ref[src];adj_inject=5'>+</a> "
		dat += "</TT><br>"

		dat += "Reagent Source: "
		dat += "<a href='?src=\ref[src];use_beaker=1'>[use_beaker ? "Loaded Beaker (When available)" : "Internal Synthesizer"]</a><br>"

	user << browse("<HEAD><TITLE>Medibot v1.0 controls</TITLE></HEAD>[dat]", "window=automed")
	onclose(user, "automed")
	return

/obj/machinery/bot/medbot/Topic(href, href_list)
	if (..())
		return
	usr.machine = src
	add_fingerprint(usr)
	if ((href_list["power"]) && (allowed(usr, req_only_one_required)))
		toggle_power()

	else if ((href_list["adj_threshold"]) && (!locked))
		var/adjust_num = text2num(href_list["adj_threshold"])
		heal_threshold += adjust_num
		if (heal_threshold < 5)
			heal_threshold = 5
		if (heal_threshold > 75)
			heal_threshold = 75

	else if ((href_list["adj_inject"]) && (!locked))
		var/adjust_num = text2num(href_list["adj_inject"])
		injection_amount += adjust_num
		if (injection_amount < 5)
			injection_amount = 5
		if (injection_amount > 15)
			injection_amount = 15

	else if ((href_list["use_beaker"]) && (!locked))
		use_beaker = !use_beaker

	else if (href_list["eject"] && (!isnull(reagent_glass)))
		if (!locked)
			reagent_glass.set_loc(get_turf(src))
			reagent_glass = null
		else
			boutput(usr, "You cannot eject the beaker because the panel is locked!")

	updateUsrDialog()
	return

/obj/machinery/bot/medbot/emag_act(var/mob/user, var/obj/item/card/emag/E)
	if (!emagged)
		if (user)
			boutput(user, "<span style=\"color:red\">You short out [src]'s reagent synthesis circuits.</span>")
		spawn (0)
			for (var/mob/O in hearers(src, null))
				O.show_message("<span style=\"color:red\"><strong>[src] buzzes oddly!</strong></span>", 1)
		patient = null
		oldpatient = user
		currently_healing = 0
		last_found = world.time
		anchored = 0
		emagged = 1
		on = 1
		update_icon()
		return TRUE
	return FALSE


/obj/machinery/bot/medbot/demag(var/mob/user)
	if (!emagged)
		return FALSE
	if (user)
		user.show_text("You repair [src]'s reagent synthesis circuits.", "blue")
	emagged = 0
	patient = null
	oldpatient = user
	currently_healing = 0
	last_found = world.time
	anchored = 0
	update_icon()
	return TRUE

/obj/machinery/bot/medbot/attackby(obj/item/W as obj, mob/user as mob)
	//if (istype(W, /obj/item/card/emag)) // this gets to stay here because it is a good story
		/*
		I caught a fish once, real little feller, it was.
		As I was preparing to throw it back into the lake this gray cat came up to me.
		Without a sound he stands on his hind legs next to me, silently watching what I'm doing.
		He stands like that for several minutes, looking at the fish, then at me, then back at the fish
		Eventually I gave him the fish.
		He followed me home.
		Good catte.

		Also the override is here so you don't thwap the bot with the emag
		*/
		//return
	if (istype(W, /obj/item/device/pda2) && W:ID_card)
		W = W:ID_card
	if (istype(W, /obj/item/card/id))
		if (allowed(user, req_only_one_required))
			locked = !locked
			boutput(user, "Controls are now [locked ? "locked." : "unlocked."]")
			updateUsrDialog()
		else
			boutput(user, "<span style=\"color:red\">Access denied.</span>")

	else if (istype(W, /obj/item/screwdriver))
		if (health < initial(health))
			health = initial(health)
			visible_message("<span style=\"color:blue\">[user] repairs [src]!</span>", "<span style=\"color:blue\">You repair [src].</span>")

	else if (istype(W, /obj/item/reagent_containers/glass))
		if (locked)
			boutput(user, "You cannot insert a beaker because the panel is locked!")
			return
		if (!isnull(reagent_glass))
			boutput(user, "There is already a beaker loaded!")
			return

		user.drop_item()
		W.set_loc(src)
		reagent_glass = W
		boutput(user, "You insert [W].")
		updateUsrDialog()
		return

	else
		switch (W.damtype)
			if ("fire")
				health -= W.force * 0.75
			if ("brute")
				health -= W.force * 0.5
			else
		if (health <= 0)
			explode()
		else if (W.force)
			step_to(src, (get_step_away(src,user)))
		..()

/obj/machinery/bot/medbot/proc/point(var/mob/living/carbon/target) // I stole this from the chefbot <3 u marq ur a beter codr then me
	visible_message("<strong>[src]</strong> points at [target]!")
	if (istype(target, /mob/living/carbon))
		var/D = new /obj/decal/point(get_turf(target))
		spawn (25)
			qdel(D)

/obj/machinery/bot/medbot/process()
	if (!on)
		stunned = 0
		return

	if (stunned)
		update_icon(stun = 1)
		stunned--

		oldpatient = patient
		patient = null
		currently_healing = 0

		if (stunned <= 0)
			stunned = 0
			update_icon()
		return

	if (frustration > 8)
		oldpatient = patient
		patient = null
		currently_healing = 0
		last_found = world.time
		path = null

	if (!patient)
		if (prob(1))
			var/message = pick("Radar, put a mask on!","I'm a doctor.","There's always a catch, and it's the best there is.","I knew it, I should've been a plastic surgeon.","What kind of medbay is this? Everyone's dropping like dead flies.","Delicious!")
			speak(message)

		for (var/mob/living/carbon/C in view(7,src)) //Time to find a patient!
			if ((C.stat == 2) || !istype(C, /mob/living/carbon/human))
				continue

			if ((C == oldpatient) && (world.time < last_found + 100))
				continue

			if (assess_patient(C))
				patient = C
				oldpatient = C
				last_found = world.time
				spawn (0)
					if ((last_newpatient_speak + 100) < world.time) //Don't spam these messages!
						var/message = pick("Hey, you! Hold on, I'm coming.","Wait! I want to help!","You appear to be injured!","Don't worry, I'm trained for this!")
						speak(message)
						last_newpatient_speak = world.time
					point(C.name)
				break
			else
				continue


	if (patient && (get_dist(src,patient) <= 1))
		if (!currently_healing)
			currently_healing = 1
			frustration = 0
			medicate_patient(patient)
		return

	else if (patient && path && path.len && (get_dist(patient,path[path.len]) > 2))
		path = null
		currently_healing = 0
		last_found = world.time

	if (patient && (!path || path.len == 0) && (get_dist(src,patient) > 1))
		spawn (0)
			if (!isturf(loc))
				return
			path = AStar(loc, get_turf(patient), /turf/proc/CardinalTurfsWithAccess, /turf/proc/Distance, adjacent_param = botcard)
			if (!path)
				oldpatient = patient
				patient = null
				currently_healing = 0
				last_found = world.time
		return

	if (path && path.len && patient)
		step_to(src, path[1])
		path -= path[1]
		spawn (3)
			if (path && path.len)
				step_to(src, path[1])
				path -= path[1]

	if (path && path.len > 8 && patient)
		frustration++

	return

/obj/machinery/bot/medbot/proc/toggle_power()
	on = !on
	if (on)
		light.enable()
	else
		light.disable()
	patient = null
	oldpatient = null
	oldloc = null
	path = null
	currently_healing = 0
	last_found = world.time
	update_icon()
	updateUsrDialog()
	return

/obj/machinery/bot/medbot/proc/assess_patient(mob/living/carbon/C as mob)
	//Time to see if they need medical help!
	if (C.stat == 2)
		return FALSE //welp too late for them!

	if (C.suiciding)
		return FALSE //Kevorkian school of robotic medical assistants.

	if (emagged) //Everyone needs our medicine. (Our medicine is toxins)
		return TRUE

	var/brute = C.get_brute_damage()
	var/burn = C.get_burn_damage()
	//If they're injured, we're using a beaker, and don't have one of our WONDERCHEMS.
	if ((reagent_glass) && (use_beaker) && ((brute >= heal_threshold) || (burn >= heal_threshold) || (C.get_toxin_damage() >= heal_threshold) || (C.get_oxygen_deprivation() >= (heal_threshold + 15))))
		for (var/current_id in reagent_glass.reagents.reagent_list)
			if (!C.reagents.has_reagent(current_id))
				return TRUE
			continue

	//They're injured enough for it!
	if ((brute >= heal_threshold) && (!C.reagents.has_reagent(treatment_brute)))
		return TRUE //If they're already medicated don't bother!

	if ((C.get_oxygen_deprivation() >= (15 + heal_threshold)) && (!C.reagents.has_reagent(treatment_oxy)))
		return TRUE

	if ((burn >= heal_threshold) && (!C.reagents.has_reagent(treatment_fire)))
		return TRUE

	if ((C.get_toxin_damage() >= heal_threshold) && (!C.reagents.has_reagent(treatment_tox)))
		return TRUE

	for (var/ailment_data/disease/am in C.ailments)
		if ((am.stage > 1) || (am.spread == "Airborne"))
			if (!C.reagents.has_reagent(treatment_virus))
				return TRUE //STOP DISEASE FOREVER

	return FALSE

/obj/machinery/bot/medbot/proc/medicate_patient(mob/living/carbon/C as mob)
	if (!on)
		return

	if (!istype(C))
		oldpatient = patient
		patient = null
		currently_healing = 0
		last_found = world.time
		return

	if (C.stat == 2)
		var/death_message = pick("No! NO!","Live, damnit! LIVE!","I...I've never lost a patient before. Not today, I mean.")
		speak(death_message)
		oldpatient = patient
		patient = null
		currently_healing = 0
		last_found = world.time
		return

	var/reagent_id = null

	//Use whatever is inside the loaded beaker. If there is one.
	if ((use_beaker) && (reagent_glass) && (reagent_glass.reagents.total_volume))
		reagent_id = "internal_beaker"

	if (terrifying)
		reagent_id = pick("pancuronium","haloperidol")

	if (emagged && !terrifying) //Emagged! Time to poison everybody.
		reagent_id = "pancuronium" // HEH

	if (!reagent_id)
		if (!C.reagents.has_reagent(treatment_virus))
			reagent_id = treatment_virus

	var/brute = C.get_brute_damage()
	var/burn = C.get_burn_damage()

	if (!reagent_id && (brute >= heal_threshold))
		if (!C.reagents.has_reagent(treatment_brute))
			reagent_id = treatment_brute

	if (!reagent_id && (C.get_oxygen_deprivation() >= (15 + heal_threshold)))
		if (!C.reagents.has_reagent(treatment_oxy))
			reagent_id = treatment_oxy

	if (!reagent_id && (burn >= heal_threshold))
		if (!C.reagents.has_reagent(treatment_fire))
			reagent_id = treatment_fire

	if (!reagent_id && (C.get_toxin_damage() >= heal_threshold))
		if (!C.reagents.has_reagent(treatment_tox))
			reagent_id = treatment_tox

	if (!reagent_id) //If they don't need any of that they're probably cured!
		oldpatient = patient
		patient = null
		currently_healing = 0
		last_found = world.time
		var/message = pick("All patched up!","An apple a day keeps me away.","Feel better soon!")
		speak(message)
		return
	else
		update_icon(stun = 0, heal = 1)
		visible_message("<span style=\"color:red\"><strong>[src] is trying to inject [patient]!</strong></span>")
		spawn (30)
			if ((get_dist(src, patient) <= 1) && (on))
				if ((reagent_id == "internal_beaker") && (reagent_glass) && (reagent_glass.reagents.total_volume))
					reagent_glass.reagents.trans_to(patient,injection_amount) //Inject from beaker instead.
					reagent_glass.reagents.reaction(patient, 2)
				else
					patient.reagents.add_reagent(reagent_id,injection_amount)
				visible_message("<span style=\"color:red\"><strong>[src] injects [patient] with the syringe!</strong></span>")

			update_icon()
			currently_healing = 0

			if (terrifying)
				if (prob(20))
					var/message = pick("It will be okay.","You're okay.", "Everything will be alright,","Please remain calm.","Please calm down, sir.","You need to calm down.","CODE BLUE.","You're going to be just fine.","Hold stIll.","Sedating patient.","ALERT.","I think we're losing them...","You're only hurting yourself.","MEM ERR BLK 0  ADDR 30FC500 HAS 010F NOT 0000","MEM ERR BLK 3  ADDR 55005FF HAS 020A NOT FF00","ERROR: Missing or corrupted resource filEs. Plea_-se contact a syst*m administrator.","ERROR: Corrupted kernel. Ple- - a", "This will all be over soon.")
					speak(message)
				else
					visible_message("<strong>[src] [pick("spazzes out","glitches out","tweaks out", "malfunctions", "twitches")]!</strong>")
					var/glitchsound = pick('sound/machines/romhack1.ogg', 'sound/machines/romhack2.ogg', 'sound/machines/romhack3.ogg','sound/machines/glitch1.ogg','sound/machines/glitch2.ogg','sound/machines/glitch3.ogg','sound/machines/glitch4.ogg','sound/machines/glitch5.ogg')
					playsound(loc, glitchsound, 50, 1)
					// let's grustle a bit
					spawn (1)
						pixel_x += rand(-2,2)
						pixel_y += rand(-2,2)
						sleep(1)
						pixel_x += rand(-2,2)
						pixel_y += rand(-2,2)
						sleep(1)
						pixel_x += rand(-2,2)
						pixel_y += rand(-2,2)
						sleep(1)
						pixel_x = 0
						pixel_y = 0

			return

//	speak(reagent_id)
	reagent_id = null
	return

// copied from transposed scientists

#define fontSizeMax 3
#define fontSizeMin -3

/obj/machinery/bot/medbot/terrifying/speak(var/message)
	if ((!on) || (!message))
		return

	var/list/audience = hearers(src, null)
	if (!audience || !audience.len)
		return

	var/fontSize = 1
	var/fontIncreasing = 1
	var/messageLen = length(message)
	var/processedMessage = ""

	for (var/i = 1, i <= messageLen, i++)
		processedMessage += "<font size=[fontSize]>[copytext(message, i, i+1)]</font>"
		if (fontIncreasing)
			fontSize = min(fontSize+1, fontSizeMax)
			if (fontSize >= fontSizeMax)
				fontIncreasing = 0
		else
			fontSize = max(fontSize-1, fontSizeMin)
			if (fontSize <= fontSizeMin)
				fontIncreasing = 1

	for (var/mob/O in audience)
		O.show_message("<span class='game say'><span class='name'>[src]</span> beeps, \"[processedMessage]\"",2)

	return

#undef fontSizeMax
#undef fontSizeMin

/obj/machinery/bot/medbot/bullet_act(var/obj/projectile/P)
	..()
	if (src && (P && istype(P) && P.proj_data.damage_type == D_ENERGY))
		stunned += 5
		if (stunned > 15)
			stunned = 15
	return

/obj/machinery/bot/medbot/ex_act(severity)
	switch(severity)
		if (1.0)
			explode()
			return
		if (2.0)
			health -= 15
			if (health <= 0)
				explode()
			return
	return

/obj/machinery/bot/medbot/emp_act()
	..()
	if (!emagged && prob(75))
		emagged = 1
		visible_message("<span style=\"color:red\"><strong>[src] buzzes oddly!</strong></span>")
		on = 1
	else
		explode()
	return

/obj/machinery/bot/medbot/meteorhit()
	explode()
	return

/obj/machinery/bot/medbot/blob_act(var/power)
	if (prob(25 * power / 20))
		explode()
	return

/obj/machinery/bot/medbot/gib()
	return explode()

/obj/machinery/bot/medbot/explode()
	on = 0
	for (var/mob/O in hearers(src, null))
		O.show_message("<span style=\"color:red\"><strong>[src] blows apart!</strong></span>", 1)
	var/turf/Tsec = get_turf(src)

	new /obj/item/storage/firstaid(Tsec)

	new /obj/item/device/prox_sensor(Tsec)

	new /obj/item/device/healthanalyzer(Tsec)

	if (reagent_glass)
		reagent_glass.set_loc(Tsec)
		reagent_glass = null

	if (prob(50))
		new /obj/item/parts/robot_parts/arm/left(Tsec)

	var/effects/system/spark_spread/s = unpool(/effects/system/spark_spread)
	s.set_up(3, 1, src)
	s.start()
	qdel(src)
	return

/obj/machinery/bot/medbot/Bumped(M as mob|obj)
	spawn (0)
		var/turf/T = get_turf(src)
		M:set_loc(T)

/*
 *	Medbot Assembly -- Can be made out of all three medkits.
 */

/obj/item/storage/firstaid/attackby(var/obj/item/parts/robot_parts/S, mob/user as mob)
	if (!istype(S, /obj/item/parts/robot_parts/arm))
		if (contents.len >= 7)
			return
		if ((S.w_class >= 2 || istype(S, /obj/item/storage)))
			if (!istype(S,/obj/item/storage/pill_bottle))
				return
		..()
		return

	if (contents.len >= 1)
		boutput(user, "<span style=\"color:red\">You need to empty [src] out first!</span>")
		return
	else
		var/obj/item/firstaid_arm_assembly/A = new /obj/item/firstaid_arm_assembly
		if (icon_state != "firstaid") // fart
			A.skin = icon_state // farto
/* all of this is kinda needlessly complicated imo
		if (istype(src, /obj/item/storage/firstaid/fire))
			A.skin = "ointment"
		else if (istype(src, /obj/item/storage/firstaid/toxin))
			A.skin = "tox"
		else if (istype(src, /obj/item/storage/firstaid/oxygen))
			A.skin = "o2"
		else if (istype(src, /obj/item/storage/firstaid/brain))
			A.skin = "red"
		else if (istype(src, /obj/item/storage/firstaid/brute))
			A.skin = "brute"
*/
		user.u_equip(S)
		user.put_in_hand_or_drop(A)
		boutput(user, "You add the robot arm to the first aid kit!")
		qdel(S)
		qdel(src)

/obj/item/firstaid_arm_assembly/attackby(obj/item/W as obj, mob/user as mob)
	if ((istype(W, /obj/item/device/healthanalyzer)) && (!build_step))
		build_step++
		boutput(user, "You add the health sensor to [src]!")
		name = "First aid/robot arm/health analyzer assembly"
		overlays += "medibot-scanner"
		qdel(W)

	else if ((istype(W, /obj/item/device/prox_sensor)) && (build_step == 1))
		build_step++
		boutput(user, "You complete the Medibot! Beep boop.")
		var/obj/machinery/bot/medbot/S = new /obj/machinery/bot/medbot
		S.skin = skin
		S.set_loc(get_turf(src))
		S.name = created_name
		qdel(W)
		qdel(src)

	else if (istype(W, /obj/item/pen))
		var/t = input(user, "Enter new robot name", name, created_name) as text
		t = strip_html(replacetext(t, "'",""))
		t = copytext(t, 1, 45)
		if (!t)
			return
		if (!in_range(src, usr) && loc != usr)
			return

		created_name = t