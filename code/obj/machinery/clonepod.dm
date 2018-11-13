 #define MEAT_NEEDED_TO_CLONE	16
#define MAXIMUM_MEAT_LEVEL		100
#define MEAT_USED_PER_TICK		0.6

#define MEAT_LOW_LEVEL	MAXIMUM_MEAT_LEVEL * 0.15

#define MAX_FAILED_CLONE_TICKS 200 // vOv

/obj/machinery/clonepod
	anchored = 1
	name = "cloning pod"
	desc = "An electronically-lockable pod for growing organic tissue."
	density = 1
	icon = 'icons/obj/cloning.dmi'
	icon_state = "pod_0_lowmeat"
	req_access = list(access_medlab) //For premature unlocking.
	mats = 15
	var/mob/living/occupant
	var/heal_level = 90 //The clone is released once its health reaches this level.
	var/locked = 0
	var/obj/machinery/computer/cloning/connected = null //So we remember the connected clone machine.
	var/mess = 0 //Need to clean out it if it's full of exploded clone.
	var/attempting = 0 //One clone attempt at a time thanks
	var/eject_wait = 0 //Don't eject them as soon as they are created fuckkk
	var/previous_heal = 0
	var/portable = 0 //Are we part of a port-a-clone?
	var/operating = 0 //Are we currently cloning some duder?

	var/gen_analysis = 1 //Are we analysing the genes while reassembling the duder? (read: Do we work faster or do we give a material bonus?)
	var/gen_bonus = 1 //Normal generation speed
	power_usage = 200

	var/failed_tick_counter = 0 // goes up while someone is stuck in there and there's not enough meat to clone them, after so many ticks they'll get dumped out

	var/message = null
	var/mailgroup = "medbay"
	var/mailgroup2 = "medresearch"
	var/net_id = null
	var/pdafrequency = 1149
	var/radio_frequency/pda_connection

	var/meat_level = MAXIMUM_MEAT_LEVEL / 4

	New()
		..()
		var/reagents/R = new/reagents(100)
		reagents = R
		R.my_atom = src

		update_icon()
		genResearch.clonepods.Add(src) //This will be used for genetics bonuses when cloning

		spawn (100)
			if (radio_controller)
				pda_connection = radio_controller.add_object(src, "[pdafrequency]")
			if (!net_id)
				net_id = generate_net_id(src)

	Del()
		genResearch.clonepods.Remove(src) //Bye bye
		..()

	proc/send_pda_message(var/msg)
		if (!msg && message)
			msg = message
		else if (!msg)
			return

		if (msg && mailgroup && pda_connection)
			var/signal/newsignal = get_free_signal()
			newsignal.source = src
			newsignal.transmission_method = TRANSMISSION_RADIO
			newsignal.data["command"] = "text_message"
			newsignal.data["sender_name"] = "CLONEPOD-MAILBOT"
			newsignal.data["message"] = "[msg]"

			newsignal.data["address_1"] = "00000000"
			newsignal.data["group"] = mailgroup
			newsignal.data["sender"] = net_id

			pda_connection.post_signal(src, newsignal)

		if (msg && mailgroup2 && pda_connection)
			var/signal/newsignal = get_free_signal()
			newsignal.source = src
			newsignal.transmission_method = TRANSMISSION_RADIO
			newsignal.data["command"] = "text_message"
			newsignal.data["sender_name"] = "CLONEPOD-MAILBOT"
			newsignal.data["message"] = "[msg]"

			newsignal.data["address_1"] = "00000000"
			newsignal.data["group"] = mailgroup2
			newsignal.data["sender"] = net_id

			pda_connection.post_signal(src, newsignal)

/obj/machinery/clonepod/attack_ai(mob/user as mob)
	return attack_hand(user)

/obj/machinery/clonepod/attack_hand(mob/user as mob)
	if (stat & NOPOWER)
		return

	if ((!isnull(occupant)) && (occupant.stat != 2))
		var/completion = (100 * ((occupant.health + 100) / (heal_level + 100)))
		boutput(user, "Current clone cycle is [round(completion)]% complete.")

	boutput(user, "Biomatter reserves are [round( 100 * (meat_level / MAXIMUM_MEAT_LEVEL) )]% full.")

	if (meat_level <= 0)
		boutput(user, "<span style=\"color:red\">Alert: Biomatter reserves depleted.</span>")
	else if (meat_level <= MEAT_LOW_LEVEL)
		boutput(user, "<span style=\"color:red\">Alert: Biomatter reserves low.</span>")

	return

/obj/machinery/clonepod/is_open_container()
	return 2

/obj/machinery/clonepod/proc/update_icon()
	if (portable) // no need here
		return
	if (mess)
		icon_state = "pod_g"
	else
		icon_state = "pod_[occupant ? "1" : "0"][meat_level ? "" : "_lowmeat"]"

//Start growing a human clone in the pod!
/obj/machinery/clonepod/proc/growclone(mob/ghost as mob, var/clonename, var/mind/mindref, var/bioHolder/oldholder, var/abilityHolder/oldabilities, var/list/traits)
	if (((!ghost) || (!ghost.client)) || mess || attempting)
		return FALSE

	if (meat_level < MEAT_NEEDED_TO_CLONE)
		connected_message("Insufficient biomatter to begin.")
		return FALSE

	if (ghost.mind.dnr)
		connected_message("Ephemereal conscience detected, seance protocols reveal this corpse cannot be cloned.")
		return FALSE

	attempting = 1 //One at a time!!
	locked = 1
	failed_tick_counter = 0 // make sure we start here

	eject_wait = 1
	spawn (30)
		eject_wait = 0

	occupant = new /mob/living/carbon/human(src)

	if (istype(oldholder))
		oldholder.clone_generation++
		occupant.bioHolder.CopyOther( oldholder )
	else
		logTheThing("debug", null, null, "<strong>Cloning:</strong> growclone([english_list(args)]) with invalid holder.")

	if (istype(oldabilities))
		occupant.abilityHolder = oldabilities // This should already be a copy.

	if (traits && traits.len && occupant.traitHolder)
		occupant.traitHolder.traits = traits
		if (occupant.traitHolder.hasTrait("puritan"))
			mess = 1

	ghost.client.mob = occupant

	update_icon()
	//Get the clone body ready
	spawn (5) //Organs may not exist yet if we call this right away.
		random_brute_damage(occupant, 90, 1)
	occupant.take_toxin_damage(50)
	occupant.take_oxygen_deprivation(40)
	occupant.take_brain_damage(90)
	occupant.paralysis += 4
	occupant.bioHolder.AddEffect("premature_clone")
	if (occupant.bioHolder.clone_generation > 1)
		occupant.max_health -= (occupant.bioHolder.clone_generation - 1) * 15 //Genetic degradation! Oh no!!
	//Here let's calculate their health so the pod doesn't immediately eject them!!!
	occupant.health = (occupant.get_brute_damage() + occupant.get_toxin_damage() + occupant.get_oxygen_deprivation())

	boutput(occupant, "<span style=\"color:blue\"><strong>Clone generation process initiated.</strong></span>")
	boutput(occupant, "<span style=\"color:blue\">This will take a moment, please hold.</span>")

	if (clonename)
		if (prob(10))
			occupant.real_name = "[pick("Almost", "Sorta", "Mostly", "Kinda", "Nearly", "Pretty Much", "Roughly", "Not Quite")] [clonename]"
		else
			occupant.real_name = clonename
	else
		occupant.real_name = "clone"  //No null names!!

	if ((mindref) && (istype(mindref))) //Move that mind over!!
		mindref.transfer_to(occupant)
	else //welp
		logTheThing("debug", null, null, "<strong>Mind</strong> Clonepod forced to create new mind for key \[[occupant.key ? occupant.key : "INVALID KEY"]]")
		occupant.mind = new /mind(  )
		occupant.mind.key = occupant.key
		occupant.mind.transfer_to(occupant)
		ticker.minds += occupant.mind

	// -- Mode/mind specific stuff goes here

		if ((ticker && ticker.mode && istype(ticker.mode, /game_mode/revolution)) && ((occupant.mind in ticker.mode:revolutionaries) || (occupant.mind in ticker.mode:head_revolutionaries)))
			ticker.mode:update_all_rev_icons() //So the icon actually appears

	// -- End mode specific stuff

	if (istype(ghost, /mob/dead))
		qdel(ghost) //Don't leave ghosts everywhere!!

	if (reagents && reagents.total_volume)
		reagents.reaction(occupant, 2, 1000)
		reagents.trans_to(occupant, 1000)

	previous_heal = occupant.health
	attempting = 0
	operating = 1
	gen_bonus = healing_multiplier()
	return TRUE

//Grow clones to maturity then kick them out.  FREELOADERS
/obj/machinery/clonepod/process()
	if (occupant && meat_level)
		power_usage = 7500
	else
		power_usage = 200
	..()
	if (stat & NOPOWER) //Autoeject if power is lost
		if (occupant)
			locked = 0
			go_out()
		return

	var/abort = 0
	if ((occupant) && (occupant.loc == src) && occupant.traitHolder && occupant.traitHolder.hasTrait("puritan"))
		abort = 1
		occupant.take_toxin_damage(300)
		occupant.death()

	if ((occupant) && (occupant.loc == src))
		if ((occupant.stat == 2) || (occupant.suiciding) || abort)  //Autoeject corpses and suiciding dudes.
			locked = 0
			go_out()
			connected_message("Clone Rejected: Deceased.")
			send_pda_message("Clone Rejected: Deceased")
			return

		else if (failed_tick_counter >= MAX_FAILED_CLONE_TICKS) // you been in there too long, get out
			locked = 0
			go_out()
			connected_message("Clone Ejected: Low Biomatter.")
			send_pda_message("Clone Ejected: Low Biomatter")
			return

		else if (!meat_level)
			failed_tick_counter ++
			if (failed_tick_counter == (MAX_FAILED_CLONE_TICKS / 2)) // halfway to ejection
				send_pda_message("Low Biomatter: Preparing to Eject Clone")
			update_icon()
			use_power(200)
			return

		else if (occupant.health < heal_level)
			failed_tick_counter = 0

			occupant.paralysis = 4

			 //Slowly get that clone healed and finished.
			occupant.HealDamage("All", 1 * gen_bonus, 1 * gen_bonus)

			//At this rate one clone takes about 95 seconds to produce.(with heal_level 90)
			occupant.take_toxin_damage(-0.5 * gen_bonus)

			//Premature clones may have brain damage.
			occupant.take_brain_damage(-2 * gen_bonus)

			//So clones don't die of oxy damage in a running pod.
			if (occupant.reagents.get_reagent_amount("perfluorodecalin") < 6) // cogwerks: changed from epinephrine
				occupant.reagents.add_reagent("perfluorodecalin", 2)

			if (occupant.reagents.get_reagent_amount("epinephrine") < 8) // lowering this but keeping it in a fully value range
				occupant.reagents.add_reagent("epinephrine", 4)

			if (occupant.reagents.get_reagent_amount("saline") < 10) // cogwerks: adding this because it'll be funny when someone gets scanned
				occupant.reagents.add_reagent("saline", 4)

			if (occupant.reagents.get_reagent_amount("synthflesh") < 50) // cogwerks: adding this because it'll be funny when someone gets scanned
				occupant.reagents.add_reagent("synthflesh", 10)

			//Also heal some oxy ourselves because epinephrine is so bad at preventing it!!
			occupant.take_oxygen_deprivation(-10) // cogwerks: speeding this up too

			meat_level = max( 0, meat_level - MEAT_USED_PER_TICK)
			if (!meat_level)
				connected_message("Additional biomatter required to continue.")
				send_pda_message("Low Biomatter")
				visible_message("<span style=\"color:red\">[src] emits an urgent boop!</span>")
				playsound(loc, "sound/machines/buzz-two.ogg", 50, 0)
				failed_tick_counter ++

			use_power(7500) //This might need tweaking.

			var/heal_delta = (occupant.health - previous_heal)
			previous_heal = occupant.health
			if (heal_delta <= 0 && occupant.health > 50 && !eject_wait)
				connected_message("Cloning Process Complete.")
				send_pda_message("Cloning Process Complete")
				locked = 0
				go_out()
			else // go_out() updates icon too, so vOv
				update_icon()
			return

		else if ((occupant.health >= heal_level) && (!eject_wait))
			connected_message("Cloning Process Complete.")
			send_pda_message("Cloning Process Complete")
			locked = 0
			go_out()
			return

	else
		occupant = null
		operating = 0 //Welp. Where did you go? Jerk.
		failed_tick_counter = 0
		if (locked)
			locked = 0
		if (!mess)
			update_icon()
		use_power(200)
		return

	return

/obj/machinery/clonepod/emag_act(var/mob/user, var/obj/item/card/emag/E)
	if (isnull(occupant))
		return FALSE
	if (user)
		boutput(user, "You force an emergency ejection.")
	locked = 0
	go_out()
	return TRUE

//Let's unlock this early I guess.
/obj/machinery/clonepod/attackby(obj/item/W as obj, mob/user as mob)
	if (istype(W, /obj/item/device/pda2) && W:ID_card)
		W = W:ID_card
	if (istype(W, /obj/item/card/id))
		if (!check_access(W))
			boutput(user, "<span style=\"color:red\">Access Denied.</span>")
			return
		if ((!locked) || (isnull(occupant)))
			return
		if ((occupant.health < -20) && (occupant.stat != 2))
			boutput(user, "<span style=\"color:red\">Access Refused.</span>")
			return
		else
			locked = 0
			boutput(user, "System unlocked.")
	else if (istype(W, /obj/item/card/emag))	//This is needed to suppress the SYNDI CAT HITS CLONING POD message *cry
		return
	else if (istype(W, /obj/item/reagent_containers/glass))
		return

	else
		..()

var/list/clonepod_accepted_reagents = list("blood"=0.5,"synthflesh"=1,"beff"=0.75,"pepperoni"=0.5,"meat_slurry"=1,"bloodc"=0.5)
/obj/machinery/clonepod/on_reagent_change()
	for (var/reagent_id in reagents.reagent_list)
		if (reagent_id in clonepod_accepted_reagents)
			var/reagent/theReagent = reagents.reagent_list[reagent_id]
			if (theReagent)
				meat_level = min(meat_level + (theReagent.volume * clonepod_accepted_reagents[reagent_id]), MAXIMUM_MEAT_LEVEL)
				reagents.del_reagent(reagent_id)

	if (occupant)
		src.reagents.reaction(src.occupant, 1000) // why was there a 2 here? it was injecting ice cold reagents that burn people
		reagents.trans_to(occupant, 1000)

//Put messages in the connected computer's temp var for display.
/obj/machinery/clonepod/proc/connected_message(var/msg)
	if ((isnull(connected)) || (!istype(connected, /obj/machinery/computer/cloning)))
		return FALSE
	if (!msg)
		return FALSE

	connected.temp = msg
	connected.updateUsrDialog()
	return TRUE

/obj/machinery/clonepod/verb/eject()
	set src in oview(1)
	set category = "Local"

	if (usr.stat != 0)
		return
	go_out()
	add_fingerprint(usr)
	return

/obj/machinery/clonepod/proc/go_out()
	if (locked)
		return
	operating = 0 //Welp
	failed_tick_counter = 0

	if (mess) //Clean that mess and dump those gibs!
		mess = 0
		gibs(get_turf(src)) // we don't need to do if/else things just to say "put gibs on this thing's turf"
		update_icon()
		for (var/obj/O in src)
			O.set_loc(get_turf(src))
			if (prob(33))
				step_rand(O) // cogwerks - let's spread that mess instead of having a pile! bahaha
		return

	if (!(occupant))
		return

	for (var/obj/O in src)
		O.set_loc(get_turf(src))

	if ((occupant.health >= heal_level - 50) && occupant.bioHolder) // this seems to often not work right, changing 20 to 50
		occupant.bioHolder.RemoveEffect("premature_clone")
		occupant.update_face()
		occupant.update_body()
		occupant.update_clothing()
	if (occupant.get_oxygen_deprivation())
		occupant.take_oxygen_deprivation(-INFINITY)
		occupant.updatehealth()

	if (occupant.losebreath) // STOP FUCKING SUFFOCATING GOD DAMN
		occupant.losebreath = 0

	if (iscarbon(occupant))
		var/mob/living/carbon/C = occupant
		C.remove_ailments() // no more cloning with heart failure

	occupant.set_loc(get_turf(src))
	update_icon()
	eject_wait = 0 //If it's still set somehow.
	occupant = null
	return

/obj/machinery/clonepod/proc/malfunction()
	if (occupant)
		connected_message("Critical Error!")
		send_pda_message("Critical Error")
		mess = 1
		failed_tick_counter = 0
		update_icon()
		occupant.ghostize()
		spawn (5)
			qdel(occupant)
	return

/obj/machinery/clonepod/proc/operating_nominally()
	return operating && meat_level && gen_analysis //Only operate nominally for non-shit cloners

/obj/machinery/clonepod/proc/healing_multiplier()
	if (wagesystem.clones_for_cash)
		return 2 + (!gen_analysis * 0.15)
	else
		return TRUE + (!gen_analysis * 0.15) //If the analysis feature is disabled, then generate the clone slightly faster

/obj/machinery/clonepod/relaymove(mob/user as mob)
	if (user.stat)
		return
	go_out()
	return

/obj/machinery/clonepod/ex_act(severity)
	switch(severity)
		if (1.0)
			for (var/atom/movable/A as mob|obj in src)
				A.set_loc(loc)
				A.ex_act(severity)
			qdel(src)
			return
		if (2.0)
			if (prob(50))
				for (var/atom/movable/A as mob|obj in src)
					A.set_loc(loc)
					A.ex_act(severity)
				qdel(src)
				return
		if (3.0)
			if (prob(25))
				for (var/atom/movable/A as mob|obj in src)
					A.set_loc(loc)
					A.ex_act(severity)
				qdel(src)
				return
		else
	return

//SOME SCRAPS I GUESS
/* EMP grenade/spell effect
		if (istype(A, /obj/machinery/clonepod))
			A:malfunction()
*/

//WHAT DO YOU WANT FROM ME(AT)
/obj/machinery/clonegrinder
	name = "enzymatic reclaimer"
	desc = "A tank resembling a rather large blender, designed to recover biomatter for use in cloning."
	icon = 'icons/obj/cloning.dmi'
	icon_state = "grinder0"
	anchored = 1
	density = 1
	mats = 10
	var/process_timer = 0
	var/mob/living/occupant = null
	var/list/meats = list() //Meat that we want to reclaim.
	var/max_meat = 4 //To be honest, I added the meat reclamation thing in part because I wanted a "max_meat" var.
	var/emagged = 0

	New()
		..()
		UnsubscribeProcess()
		var/reagents/R = new/reagents(100)
		reagents = R
		R.my_atom = src
		update_icon(1)

	verb/eject()
		set src in oview(1)
		set category = "Local"

		if (usr.stat != 0) return
		if (process_timer > 0) return
		go_out()
		add_fingerprint(usr)
		return

	relaymove(mob/user as mob)
		go_out()
		return

	proc/go_out()
		if (!occupant)
			return
		for (var/obj/O in src)
			O.set_loc(loc)
		occupant.set_loc(loc)
		occupant = null
		return

	process()
		if (process_timer-- < 1)
			UnsubscribeProcess()
			update_icon(1)

			var/list/pods = list()
			for (var/obj/machinery/clonepod/pod in orange(4, src))
				pods += pod
			if (pods.len)
				for (var/obj/machinery/clonepod/pod in pods)
					src.reagents.trans_to(pod, (src.reagents.total_volume / max(pods.len, 1))) // give an equal amount of reagents to each pod that happens to be around
			//var/obj/machinery/clonepod/nearbyPod = locate(/obj/machinery/clonepod) in orange(1, src)
			//if (istype(nearbyPod))
				//reagents.trans_to(nearbyPod, 1000)

			return

		reagents.add_reagent("blood", 2)
		reagents.add_reagent("meat_slurry", 2)
		if (prob(2))
			reagents.add_reagent("beff", 1)

		return

	on_reagent_change()
		update_icon(0)

	emag_act(var/mob/user, var/obj/item/card/emag/E)
		if (!emagged)
			if (user)
				boutput(user, "<span style=\"color:blue\">You override the reclaimer's safety mechanism.</span>")
			emagged = 1
			return TRUE
		else
			if (user)
				boutput(user, "The safety mechanism's already burnt out!")
			return FALSE

	demag(var/mob/user)
		if (!emagged)
			return FALSE
		emagged = 0
		if (user)
			boutput(user, "<span style =\"color:blue\">You repair the reclaimer's safety mechanism.</span>")
		return TRUE

	attack_hand(mob/user as mob)
		if (process_timer > 0)
			boutput(user, "<span style=\"color:red\">The [name] is already running!</span>")
			return

		if (!meats.len && !occupant)
			boutput(user, "<span style=\"color:red\">There is nothing loaded to reclaim!</span>")
			return

		user.visible_message("<strong>[user]</strong> activates [src]!", "You activate [src].")
		if (istype(occupant))
			logTheThing("combat", user, occupant, "activated [name] with %target% ([occupant.stat == 2 ? "dead" : "alive"]) inside at [log_loc(src)].")
			if (occupant.stat != 2)
				message_admins("[key_name(user)] activated [name] with [key_name(occupant, 1)] ([occupant.stat == 2 ? "dead" : "alive"]) inside at [log_loc(src)].")
			occupant.death(1)

			var/humanOccupant = ishuman(occupant)
			var/decomp = humanOccupant ? occupant:decomp_stage : 0
			if (occupant.mind)
				occupant.ghostize()
				qdel(occupant)
			else
				qdel(occupant)

			process_timer = (humanOccupant ? 2 : 1) * (rand(4,8) - (2 * decomp))

		if (meats.len)
			for (var/obj/item/theMeat in meats)
				if (theMeat.reagents)
					theMeat.reagents.trans_to(src, 5)

				qdel(theMeat)
				process_timer += 2

			meats.len = 0

		update_icon(1)
		SubscribeToProcess()
		return

	attackby(obj/item/grab/G as obj, mob/user as mob)
		if (process_timer > 0)
			boutput(user, "<span style=\"color:red\">The [name] is still running, hold your horses!</span>")
			return
		if (istype(G, /obj/item/reagent_containers/food/snacks/ingredient/meat) || (istype(G, /obj/item/reagent_containers/food) && (findtext(G.name, "meat")||findtext(G.name,"bacon"))) || (istype(G, /obj/item/parts/human_parts)) || istype(G, /obj/item/clothing/head/butt) || istype(G, /obj/item/organ) || istype(G,/obj/item/raw_material/martian))
			if (meats.len >= max_meat)
				boutput(user, "<span style=\"color:red\">There is already enough meat in there! You should not exceed the maximum safe meat level!</span>")
				return

			meats += G
			user.u_equip(G)
			G.set_loc(src)
			user.visible_message("<strong>[user]</strong> loads [G] into [src].","You load [G] into [src]")
			return

		else if (istype(G, /obj/item/reagent_containers/glass))
			return

		else if (!istype(G) || !iscarbon(G.affecting))
			boutput(user, "<span style=\"color:red\">This item is not suitable for the [name].</span>")
			return
		if (occupant)
			boutput(user, "<span style=\"color:red\">There is already somebody in there.</span>")
			return

		else if (G && G.affecting && !emagged && G.affecting.stat != 2 && !ismonkey(G.affecting))
			user.visible_message("<span style=\"color:red\">[user] tries to stuff [G.affecting] into the [name], but it beeps angrily as the safety overrides engage!</span>")
			return

		user.visible_message("<span style=\"color:red\">[user] starts to put [G.affecting] into the [name]!</span>")
		add_fingerprint(user)
		sleep(30)
		if (G && G.affecting)
			user.visible_message("<span style=\"color:red\">[user] stuffs [G.affecting] into the [name]!</span>")
			logTheThing("combat", user, G.affecting, "forced %target% ([G.affecting.stat == 2 ? "dead" : "alive"]) into a [name] at [log_loc(src)].")
			if (G.affecting.stat != 2)
				message_admins("[key_name(user)] forced [key_name(G.affecting, 1)] ([G.affecting.stat == 2 ? "dead" : "alive"]) into a [name] at [log_loc(src)].")
			var/mob/M = G.affecting
			M.unequip_all()
			M.set_loc(src)
			occupant = M
			qdel(G)
		return

	proc/update_icon(var/update_grindpaddle=0)
		var/fluid_level = ((reagents.total_volume >= (reagents.maximum_volume * 0.6)) ? 2 : (reagents.total_volume >= (reagents.maximum_volume * 0.2) ? 1 : 0))

		icon_state = "grinder[fluid_level]"

		if (update_grindpaddle)
			overlays = null
			overlays += "grindpaddle[process_timer > 0 ? 1 : 0]"

			overlays += "grindglass[fluid_level]"
		return

	ex_act(severity)
		switch(severity)
			if (1.0)
				for (var/atom/movable/A as mob|obj in src)
					A.set_loc(loc)
					A.ex_act(severity)
				qdel(src)
				return
			if (2.0)
				if (prob(50))
					for (var/atom/movable/A as mob|obj in src)
						A.set_loc(loc)
						A.ex_act(severity)
					qdel(src)
					return
			if (3.0)
				if (prob(25))
					stat |= BROKEN
					icon_state = "grinderb"
			else
		return

	is_open_container()
		return -1

	suicide(var/mob/M as mob)
		if (process_timer > 0)
			return FALSE

		viewers(M) << "<span style=\"color:red\"><strong>[M] climbs into the [name] and turns it on!</strong></span>"

		M.unequip_all()
		M.set_loc(src)
		occupant = M

		occupant.death(1)

		var/humanOccupant = ishuman(occupant)
		var/decomp = humanOccupant ? occupant:decomp_stage : 0
		if (occupant.mind)
			occupant.ghostize()
			qdel(occupant)
		else
			qdel(occupant)

		process_timer = (humanOccupant ? 2 : 1) * (rand(4,8) - (2 * decomp))

		if (meats.len)
			for (var/obj/item/reagent_containers/theMeat in meats)
				if (istype(theMeat) && theMeat.reagents)
					theMeat.reagents.trans_to(src, 5)

				qdel(theMeat)
				process_timer += 2

			meats.len = 0

		update_icon(1)
		SubscribeToProcess()
		return


		spawn (100)
			usr.suiciding = 0
		return TRUE


#undef MEAT_NEEDED_TO_CLONE
#undef MAXIMUM_MEAT_LEVEL
#undef MEAT_USED_PER_TICK

#undef MEAT_LOW_LEVEL
