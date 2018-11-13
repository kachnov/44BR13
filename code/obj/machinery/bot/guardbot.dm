//CONTENTS
//Movement control datum
//Guardbot
//Guardbot tools
//Task datums
//Guardbot parts
//Docking Station
//Old Robuddies (PR-4)

//Robot config constants
#define GUARDBOT_LOWPOWER_ALERT_LEVEL 100
#define GUARDBOT_LOWPOWER_IDLE_LEVEL 10
#define GUARDBOT_POWER_DRAW 1
#define GUARDBOT_RADIO_RANGE 75
#define GUARDBOT_DOCK_RESET_DELAY 40

//movement datum
/guardbot_mover
	var/obj/machinery/bot/guardbot/master = null
	var/delay = 3

	New(var/newmaster)
		..()
		if (istype(newmaster, /obj/machinery/bot/guardbot))
			master = newmaster
		return

	proc/master_move(var/atom/the_target as obj|mob,var/adjacent=0)
		if (!master)
			return TRUE
		if (!isturf(master.loc))
			master.mover = null
			master = null
			return TRUE
		var/target_turf = null
		if (isturf(the_target))
			target_turf = the_target
		else
			target_turf = get_turf(the_target)

		//var/compare_movepath = current_movepath
		spawn (0)
			if (!master)
				return TRUE

			// Same distance cap as the MULE because I'm really tired of various pathfinding issues. Buddy time and docking stations are often way more than 150 steps away.
			// It's 200 something steps alone to get from research to the bar on COG2 for instance, and that's pretty much in a straight line.
			var/list/thePath = AStar(get_turf(master), target_turf, /turf/proc/CardinalTurfsWithAccess, /turf/proc/Distance, 500, master.botcard)
			if (!master)
				return TRUE

			master.path = thePath
			if (adjacent && master.path && master.path.len) //Make sure to check it isn't null!!
				master.path.len-- //Only go UP to the target, not the same tile.
			if (!master.path || !master.path.len || !the_target || (ismob(the_target) && master.path.len >= 21))
				if (master.task)
					master.task.task_input("path_error")

				master.moving = 0
				//dispose()
				master.mover = null
				master = null
				return TRUE

			while (master && master.path && master.path.len && target_turf && master.moving)
//				boutput(world, "[compare_movepath] : [current_movepath]")
				//if (compare_movepath != current_movepath)
				//	break
				if (master.frustration >= 10 || master.stunned || master.idle || !master.on)
					master.frustration = 0
					if (master.task)
						master.task.task_input("path_blocked")
					break
				step_to(master, master.path[1])
				if (master.loc != master.path[1])
					master.frustration++
					sleep(delay+delay)
					continue
				master.path -= master.path[1]
				sleep(delay)

			if (master)
				master.moving = 0
				master.mover = null
				master = null
			//dispose()
			return FALSE

		return FALSE

//The Robot.
/obj/machinery/bot/guardbot
	name = "Guardbuddy"
	desc = "The corporate security model of the popular PR-6 Robuddy."
	icon = 'icons/obj/aibots.dmi'
	icon_state = "robuddy0"
	layer = 5.0 //TODO LAYER
	density = 0
	anchored = 0
	req_access = list(access_heads)
	on = 1
	var/idle = 0 //Sleeping on the job??
	var/stunned = 0 //Are we stunned?
	locked = 1 //Behavior Controls lock

	var/list/path = null
	var/frustration = 0
	var/moving = 0 //Are we currently ON THE MOVE?
	//var/current_movepath = 0 //If we need to switch movement halfway
	var/guardbot_mover/mover = null

	var/emotion = null //How are you feeling, buddy?
	var/computer/file/guardbot_task/task = null //Our current task.
	var/computer/file/guardbot_task/model_task = null
	var/list/tasks = list() //All tasks.  First one is the current.
	var/list/scratchpad = list() //Scratchpad memory for tasks to pass messages.
	emagged = 0 //Not sure what this should do yet.
	health = 25
	var/wakeup_timer = 0 //Are we waiting to exit idle mode?
	var/warm_boot = 0 //Have we already done the full startup procedure?
	var/obj/item/cell/cell //We have limited power! Immersion!!
	var/obj/item/device/guardbot_tool/tool //What weapon do we have?
	var/obj/machinery/guardbot_dock/charge_dock
	var/last_dock_id = null
	var/obj/item/clothing/head/hat = null
	var/hat_shown = 0
	var/hat_icon = 'icons/obj/aibots.dmi'
	var/hat_x_offset = 0
	var/icon_needs_update = 1 //Call update_icon() in process

	var/image/costume_icon = null

	var/bedsheet = 0

	var/flashlight_lum = 2
	var/flashlight_red = 0.1
	var/flashlight_green = 0.4
	var/flashlight_blue = 0.1
	var/light/light

	var/radio_frequency/radio_connection
	var/radio_frequency/beacon_connection
	var/control_freq = 1219		// bot control frequency
	var/beacon_freq = 1445
	var/net_id = null
	var/last_comm = 0 //World time of last transmission
	var/reply_wait = 0
	var/exploding = 0 //So we don't die like five times at once.

	var/botcard_access = "Captain" //Job access for doors.
									//It's not like they can be pushed into airlocks anymore
	var/setup_no_costumes = 0 //no halloween costumes for us!!
	var/setup_unique_name = 0 //Name doesn't need random number appended to it.
	var/setup_spawn_dock = 0 //Spawn a docking station where we are.
	var/setup_charge_maximum = 1500 //Max charge of internal cell.  1500 ~25 minutes
	var/setup_charge_percentage = 90 //Percentage charge of internal cell
	var/setup_default_tool_path = /obj/item/device/guardbot_tool/flash //Starting tool.
	#ifdef HALLOWEEN
	var/setup_default_startup_task = /computer/file/guardbot_task/security/halloween
	#else
	var/setup_default_startup_task = /computer/file/guardbot_task/security //Task to run on startup. Duh.
	#endif

	ranger
		#ifndef HALLOWEEN
		name = "Ol' Harner"
		#else
		name = "Halloween Harner"
		#endif
		desc = "Almost as much the law as Beepsky."
		setup_unique_name = 1
		setup_default_startup_task = /computer/file/guardbot_task/security/patrol
		setup_charge_percentage = 95

		New()
			..()
			hat = new /obj/item/clothing/head/mj_hat(src)
			src.hat.name = "Eldritch shape-shifting hat."
			update_icon()

	safety
		name = "Klaus"
		desc = "Safetybuddy Klaus wants you to mind safety regulations."
		setup_unique_name = 1
		setup_charge_maximum = 4500
		setup_charge_percentage = 100

		New()
			..()
			hat = new /obj/item/clothing/head/helmet/hardhat
			src.hat.name = "Klaus' hardhat"
			update_icon()

	heckler
		name = "Hecklebuddy"
		desc = "A PR-6S Guardbuddy programmed to be sort of a jerk."
		setup_default_startup_task = /computer/file/guardbot_task/bodyguard/heckle

		New()
			..()
			spawn (10)
				for (var/mob/living/carbon/human/H in view(7, src))
					if (!H.stat)
						if (model_task)
							model_task:protected_name = ckey(H.name)
						if (task)
							task:protected_name = ckey(H.name)
						break

	gunner
		name = "Gunbuddy"
		desc = "A PR-6S Guardbuddy, but with a gun."
		setup_default_tool_path = /obj/item/device/guardbot_tool/taser

		vaquero
			name = "El Vaquero"
			desc = "The side label reads 'Fabricado en M�xico'"
			setup_unique_name = 1
			setup_default_startup_task = /computer/file/guardbot_task/security/patrol
			setup_charge_percentage = 98

	syringe
		name = "Wardbuddy"
		desc = "Wardbuddy is currently the CEO of a small internet syringe venture with plans to expand once he figures out how to fit a private jet in his dad's garage."
		setup_default_tool_path = /obj/item/device/guardbot_tool/medicator

	smoke
		name = "Snoozebuddy"
		desc = "Marketed as a riot control solution and sleep aid, the PR-6S2 Snoozebuddy offers a sophisticated gas-release module and a 5-year warranty."
		//setup_default_startup_task = /computer/file/guardbot_task/security/patrol
		setup_default_tool_path = /obj/item/device/guardbot_tool/smoker

	tesla
		name = "Shockbuddy"
		desc = "The PR-6MS Shockbuddy was remarketed under the Guardbuddy line following the establishment of stricter electroconvulsive therapy regulations."
		setup_default_tool_path = /obj/item/device/guardbot_tool/tesla

	bodyguard
		setup_charge_percentage = 98
		setup_default_startup_task = /computer/file/guardbot_task/bodyguard

	//xmas -- See spacemas.dm

	mail
		name = "Mailbuddy"
		desc = "The PR-6PS Mailbuddy is a postal delivery ace.  This may seem like an extremely specialized robot application, but that's just because it is exactly that."
		icon = 'icons/obj/mailbud.dmi'

		New()
			..()
			hat = new /obj/item/clothing/head/mailcap(src)
			update_icon()


	New()
		..()
		if (on)
			warm_boot = 1
		#ifdef HALLOWEEN
		if (!setup_no_costumes)
			costume_icon = image(icon, "bcostume-[pick("xcom","clown","horse","moustache","owl","pirate","skull", "wizard", "wizardred","devil")]", , FLY_LAYER)
			costume_icon.pixel_x = hat_x_offset
			if (costume_icon && costume_icon:icon_state == "bcostume-wizard")
				hat = new /obj/item/clothing/head/wizard
		#endif
		update_icon()

		if (!cell)
			cell = new /obj/item/cell(src)
			cell.maxcharge = setup_charge_maximum
			cell.charge = ((setup_charge_percentage/100) * cell.maxcharge)

		if (!setup_unique_name)
			name += "-[rand(100,999)]"

		light = new /light/point
		light.attach(src)
		light.set_color(flashlight_red, flashlight_green, flashlight_blue)
		light.set_brightness(flashlight_lum / 7)

		spawn (5)
			if (on)
				light.enable()
			botcard = new /obj/item/card/id(src)
			botcard.access = get_access(botcard_access)

			if (setup_default_tool_path && !tool)
				tool = new setup_default_tool_path
				tool.set_loc(src)
				tool.master = src

			if (radio_controller)
				radio_connection = radio_controller.add_object(src, "[control_freq]")
				beacon_connection = radio_controller.add_object(src, "[beacon_freq]")

			net_id = generate_net_id(src)

			var/obj/machinery/guardbot_dock/dock = null
			if (setup_spawn_dock)
				dock = new /obj/machinery/guardbot_dock( get_turf(src) )
				dock.frequency = control_freq
				dock.net_id = generate_net_id(dock)
			else
				dock = locate() in loc
				if (dock && istype(dock))
					if (!dock.net_id)
						dock.net_id = generate_net_id(dock)

			if (setup_default_startup_task && !task)
				if (!model_task)
					model_task = new setup_default_startup_task
					model_task.master = src

			if (dock)
				dock.connect_robot(src,dock.autoeject)
			else
				if (model_task)
					task = model_task.copy_file()
					task.master = src
					tasks.Add(task)

	emag_act(var/mob/user, var/obj/item/card/emag/E)
		if (!user || !E) return FALSE

		if (idle || !on)
			boutput(user, "You show \the [E] to [src]! There is no response.")
		else
			if (E.icon_state == "gold")
				boutput(user, "You show \the [E] to [src]! They are super impressed!")
				spawn (10)
					boutput(user, "Like, really REALLY impressed.  They probably think you're some kind of celebrity or something.")
					sleep(10)
					boutput(user, "Or the president. The president of space.")
			else
				boutput(user, "You show \the [E] to [src]! They are very impressed.")
		return TRUE

	attackby(obj/item/W as obj, mob/user as mob)
		if (istype(W, /obj/item/device/pda2) && W:ID_card)
			W = W:ID_card
		if (istype(W, /obj/item/card/id))
			if (allowed(user, req_only_one_required))
				locked = !locked
				boutput(user, "Controls are now [locked ? "locked." : "unlocked."]")
			else
				boutput(user, "<span style=\"color:red\">Access denied.</span>")
		/*
		else if (istype(W, /obj/item/card/emag))
			if (idle || !on)
				boutput(user, "You show \the [W] to [src]! There is no response.")
			else
				if (W.icon_state == "gold")
					boutput(user, "You show \the [W] to [src]! They are super impressed!")
					spawn (10)
						boutput(user, "Like, really REALLY impressed.  They probably think you're some kind of celebrity or something.")
						sleep(10)
						boutput(user, "Or the president. The president of space.")
				else
					boutput(user, "You show \the [W] to [src]! They are very impressed.")
			return
		*/
		else if (istype(W, /obj/item/screwdriver))
			if (health < initial(health))
				health = initial(health)
				visible_message("<span style=\"color:blue\">[user] repairs [src]!</span>", "<span style=\"color:blue\">You repair [src].</span>")

		else if (istype(W, /obj/item/clothing/head))
			if (hat)
				boutput(user, "<span style=\"color:red\">[src] is already wearing a hat!</span>")
				return
			if (W.icon_state == "fdora")
				boutput(user, "[src] looks [pick("kind of offended","kind of weirded-out","a bit disgusted","mildly bemused")] at your offer and turns it down.")
				return
			if (!(W.icon_state in list("detective","hoscap","hardhat0","hardhat1","hosberet","chef","souschef","captain","centcom","centcom-red","tophat","ptophat","mjhat","plunger","cake0","cake1","butt","santa","yellow","blue","red","green","black","white","psyche","wizard","wizardred","wizardpurple","obcrown","safari","dolan","viking","mailcap","bikercap","paper","apprentice","chavcap","policehelm","captain-fancy","rank-fancy")))
				boutput(user, "<span style=\"color:red\">It doesn't fit!</span>")
				return

			hat = W
			user.drop_item()
			W.set_loc(src)

			update_icon()
			user.visible_message("<strong>[user]</strong> puts a hat on [src]!","You put a hat on [src]!")
			return

		else if (istype(W, /obj/item/clothing/suit/bedsheet))
			if (bedsheet != 0)
				boutput(user, "<span style=\"color:red\">There is already a sheet draped over [src]! Two sheets would be ridiculous!</span>")
				return

			bedsheet = 1
			user.drop_item()
			qdel(W)
			overlays.len = 0
			hat_shown = 0
			update_icon()
			user.visible_message("<strong>[user]</strong> drapes a sheet over [src]!","You cover [src] with a sheet!")
			add_task(new /computer/file/guardbot_task/bedsheet_handler, 1, 0)
			return

		else if (istype(W, /obj/item/reagent_containers/food/snacks/candy))
			if (idle || !on)
				boutput(user, "You try to give [src] [W], but there is no response.")
				return

			user.visible_message("<strong>[user]</strong> gives [W] to [src]!","You give [W] to [src]!")
			user.drop_item()
			qdel(W)
			if (task)
				src.task.task_input("treated")
			return

		else
			switch(W.damtype)
				if ("fire")
					health -= W.force * 0.6
				if ("brute")
					health -= W.force * 0.4
				else
			if (health <= 0)
				..()
				explode()
				return
			else if (W.force && task)
				task.attack_response(user)
			..()

	get_desc(dist)
		..()
		if (on && idle)
			. = "<br><span style=\"color:blue\">[src] appears to be sleeping.</span>"
		if (health < initial(health))
			if (health > 10)
				. += "<br><span style=\"color:red\">[src]'s parts look loose.</span>"
			else
				. += "<br><span style=\"color:red\"><strong>[src]'s parts look very loose!</strong></span>"


	attack_ai(mob/user as mob)
		interact(user)

	attack_hand(mob/user as mob)
		if (..())
			return
		if (user.a_intent == "help" && user.machine != src && (get_dist(user,src) <= 1))
			var/affection = pick("hug","cuddle","snuggle")
			user.visible_message("<span style=\"color:blue\">[user] [affection]s [src]!</span>","<span style=\"color:blue\">You [affection] [src]!</span>")
			if (task)
				src.task.task_input("hugged")
			return

		if (get_dist(user, src) > 1)
			return

		interact(user)

	Topic(href, href_list)
		if (..())
			return
		usr.machine = src
		add_fingerprint(usr)
		if ((href_list["power"]) && (!locked || (allowed(usr, req_only_one_required) && (issilicon(usr) || get_dist(usr, src) < 2))))
			if (on)
				turn_off()
			else
				turn_on()


		updateUsrDialog()
		return

	process()
		if (icon_needs_update)
			update_icon()

		if (!on)
			return
		if (stunned)
			stunned--
			if (stunned <= 0)
				wakeup()
			return

		if ( manage_power() ) //Returns true if we need to halt process
			return				//(ie we are now off or idle)

		if (idle) //Are we idling?
			if (wakeup_timer) //Are we waiting to exit the idle state?
				wakeup_timer--
				if (wakeup_timer <= 0)
					wakeup() //Exit idle state.
			return

		if (charge_dock)
			if (charge_dock.loc == loc)
				if (!idle)
					snooze()
			else
				charge_dock = null
				wakeup()

			return

		if (reply_wait)
			reply_wait--

		if (!tasks.len && (model_task || setup_default_startup_task))
			if (!model_task)
				model_task = new setup_default_startup_task

			add_task(model_task.copy_file(),1)

		if (istype(task))
			src.task.task_act()

		return

	receive_signal(signal/signal, receive_method, receive_param)
		if (!on || stunned)
			return

		if (!signal || signal.encryption)
			return

		var/targaddress = lowertext(signal.data["address_1"])
		if (last_dock_id && targaddress == last_dock_id)
			targaddress = net_id
			last_dock_id = null

		var/is_beacon = (receive_param == "[beacon_freq]")
		if (!is_beacon)
			if ( ((targaddress != net_id) && (signal.data["acc_code"] != netpass_heads) ) || !signal.data["sender"])
				if (signal.data["address_1"] == "ping" && signal.data["sender"])
					post_status(signal.data["sender"],"command","ping_reply","device","PNET_PR6_GUARD","netid",net_id)
				return

			if (signal.data["command"] == "dock_return" && !idle) //Return to dock for new instructions.
				if (!istype(task, /computer/file/guardbot_task/recharge/dock_sync))
					add_task(/computer/file/guardbot_task/recharge/dock_sync, 0, 1)
					speak("Software update requested.")
					set_emotion("update")
				return

			else if (signal.data["command"] == "captain_greet" && !idle && istype(hat, /obj/item/clothing/head/caphat))
				speak(pick("Yes...thank you.", "Hello yes.  I'm...the captain.", "Good day to you too.  A good day from the captain.  Me.  The captain."))
				return

			else if (signal.data["command"] == "wizard_greet" && !idle && istype(hat, /obj/item/clothing/head/wizard))
				var/wizdom = pick("Never eat shredded wheat.", "A stitch in time saves nine.", "The pen is mightier than...a dull thing I guess.  Maybe a string?", "Rome wasn't built in a day.  Actually, a lot of things aren't.  I don't think any city was, to be honest.")
				speak("Um...[wizdom].")
				speak("SO SAYETH THE WIZARD!")
				return

		if (task)
			task.receive_signal(signal, is_beacon)

		return

	bullet_act(var/obj/projectile/P)
		var/damage = 0
		damage = round(((P.power/6)*P.proj_data.ks_ratio), 1.0)


		if (P.proj_data.damage_type == D_KINETIC || P.proj_data.damage_type == D_PIERCING || (P.proj_data.damage_type == D_ENERGY && damage))
			health -= damage
			if (hat && prob(10))
				visible_message("<span style=\"color:red\">[src]'s hat is knocked clean off!</span>")
				hat.set_loc(get_turf(src))
				hat = null
				underlays.len = 0
				set_emotion("sad")

		else if (P.proj_data.damage_type == D_ENERGY) //if it's an energy shot but does no damage, ie. taser rather than laser
			stunned += 5
			if (stunned > 15)
				stunned = 15
			return

		if (health <= 0)
			explode()
			return

		if (ismob(P.shooter))
			if (P && task)
				task.attack_response(P.shooter)
		return

	gib()
		return explode()

	ex_act(severity)
		switch(severity)
			if (1.0)
				explode(0)
				return
			if (2.0)
				health -= 15
				if (health <= 0)
					explode(0)
				else if (hat && prob(10))
					visible_message("<span style=\"color:red\">[src]'s hat is knocked clean off!</span>")
					hat.set_loc(get_turf(src))
					hat = null
					set_emotion("sad")
				return
		return

	meteorhit()
		explode(0)
		return

	blob_act(var/power)
		if (prob(25 * power / 20))
			explode()
		return

	emp_act() //Oh no! We have been hit by an EMP grenade!
		if (!on || prob(10))
			return

		visible_message("<span style=\"color:red\"><strong>[name]</strong> buzzes oddly!</span>")
		qdel(model_task)
		model_task = new /computer/file/guardbot_task/security/crazy
		model_task.master = src

		add_task(model_task, 0, 1)
		if (idle)
			if (charge_dock)
				charge_dock.eject_robot()
			else
				wakeup()
		return

	explode(var/allow_big_explosion=1)
		if (exploding) return
		exploding = 1
		var/death_message = pick("I regret nothing, but I am sorry I am about to leave my friends.","I had a good run.","Es lebe die Freiheit!","It is now safe to shut off your buddy.","System error.","Now I know why you cry.","Stay gold...","Malfunction!","Rosebud...","No regrets!", "Time to die...")
		speak(death_message)
		visible_message("<span style=\"color:red\"><strong>[src] blows apart!</strong></span>")
		var/turf/T = get_turf(src)
		if (mover)
			mover.master = null
			//qdel(mover)
			mover = null
		if (allow_big_explosion && cell && (cell.charge / cell.maxcharge > 0.75) && prob(60))
			invisibility = 100
			var/obj/overlay/Ov = new/obj/overlay(T)
			Ov.anchored = 1
			Ov.name = "Explosion"
			Ov.layer = NOLIGHT_EFFECTS_LAYER_BASE
			Ov.pixel_x = -17
			Ov.icon = 'icons/effects/hugeexplosion.dmi'
			Ov.icon_state = "explosion"

			tool.set_loc(get_turf(src))

			var/obj/item/guardbot_core/core = new /obj/item/guardbot_core(T)
			core.created_name = name
			core.created_default_task = setup_default_startup_task
			core.created_model_task = model_task

			var/list/throwparts = list()
			throwparts += new /obj/item/parts/robot_parts/arm/left(T)
			throwparts += core
			throwparts += tool
			if (hat)
				throwparts += hat
				hat.set_loc(T)
			throwparts += new /obj/item/guardbot_frame(T)
			for (var/obj/O in throwparts) //This is why it is called "throwparts"
				var/edge = get_edge_target_turf(src, pick(alldirs))
				O.throw_at(edge, 100, 4)

			spawn (0) //Delete the overlay when finished with it.
				on = 0
				sleep(15)
				qdel(Ov)
				qdel(src)

			T.hotspot_expose(800,125)
			explosion(src, T, -1, -1, 2, 3)

		else
			if (tool)
				tool.set_loc(T)
			if (prob(50))
				new /obj/item/parts/robot_parts/arm/left(T)
			if (hat)
				hat.set_loc(T)

			new /obj/item/guardbot_frame(T)
			var/obj/item/guardbot_core/core = new /obj/item/guardbot_core(T)
			core.created_name = name
			core.created_default_task = setup_default_startup_task
			core.created_model_task = model_task

			var/effects/system/spark_spread/s = unpool(/effects/system/spark_spread)
			s.set_up(3, 1, src)
			s.start()
			qdel(src)

		return

	proc
		manage_power()
			if (!on) return TRUE
			if (!cell || (cell.charge <= 0) )
				turn_off()
				return TRUE

			var/to_draw = GUARDBOT_POWER_DRAW
			if (idle)
				to_draw = (to_draw / 2)

			cell.use(to_draw)

			if (cell.charge < GUARDBOT_LOWPOWER_IDLE_LEVEL)
				speak("Critical battery.")
				snooze()
				return FALSE

			if (cell.charge < GUARDBOT_LOWPOWER_ALERT_LEVEL && !(locate(/computer/file/guardbot_task/recharge) in tasks) )
				add_task(/computer/file/guardbot_task/recharge,1,0)
				return FALSE

			return FALSE

		wakeup() //Get out of idle state and prepare anything that needs preparing I guess
			if (!on) return
			idle = 0 //Also called after recovery from stunning.
			stunned = 0
			moving = 0
			emotion = null
			icon_needs_update = 1
			light.enable()
			if (bedsheet == 1)
				add_task(new /computer/file/guardbot_task/bedsheet_handler, 1, 0)
				return
			if (tasks.len)
				task = tasks[1]
			return

		snooze(var/timer = 0, var/cleartasks = 1)
			if (idle) return //Already snoozing.
			idle = 1
			set_emotion()
			light.disable()
			wakeup_timer = timer
			//target = null
			moving = 0
			reply_wait = 0
			icon_needs_update = 1
			if (cleartasks)
				tasks.len = 0
				remove_current_task()
				//secondary_targets.len = 0
			else
				if (task)
					src.task.task_input("snooze")

			task = null
			return

		turn_on()
			if (!cell || cell.charge <= 0)
				return
			on = 1
			idle = 0
			moving = 0
			task = null
			wakeup_timer = 0
			last_dock_id = null
			icon_needs_update = 1
			if (!warm_boot)
				scratchpad.len = 0
				speak("Guardbuddy V1.4 Online.")
				if (health < initial(health))
					speak("Self-check indicates [health < (initial(health) / 2) ? "severe" : "moderate"] structural damage!")

				if (!tasks.len && (model_task || setup_default_startup_task))
					if (!model_task)
						model_task = new setup_default_startup_task

					tasks.Add(model_task.copy_file())
				warm_boot = 1
			wakeup()

		turn_off()
			if (!warm_boot) //ugh it's some dude just flicking the switch.
				return
			on = 0
			moving = 0
			task = null
			//target = null
			wakeup_timer = 0
			warm_boot = 0
			reply_wait = 0
			last_dock_id = null
			icon_needs_update = 1
			set_emotion()

		navigate_to(atom/the_target,var/move_delay=3,var/adjacent=0,var/clear_frustration=1)
			if (moving)
				return TRUE
			moving = 1
			if (clear_frustration)
				frustration = 0
			if (mover)
				mover.master = null
				//qdel(mover)
				mover = null
			//boutput(world, "TEST: Navigate to [target]")

			//current_movepath = world.time

			mover = new /guardbot_mover(src)

			// drsingh for cannot modify null.delay
			if (!isnull(mover))
				mover.delay = max(min(move_delay,5),2)
				mover.master_move(the_target,adjacent)

			return FALSE

		bot_attack(var/atom/target as mob|obj, lethal=0)
			if (tool)
				var/is_ranged = get_dist(src, target) > 1
				tool.bot_attack(target, src, is_ranged, lethal)
			return

		post_status(var/target_id, var/key, var/value, var/key2, var/value2, var/key3, var/value3)
			if (!radio_connection)
				return

			var/signal/signal = get_free_signal()
			signal.source = src
			signal.transmission_method = TRANSMISSION_RADIO
			signal.data[key] = value
			if (key2)
				signal.data[key2] = value2
			if (key3)
				signal.data[key3] = value3

			if (target_id)
				signal.data["address_1"] = target_id
			signal.data["sender"] = net_id

			last_comm = world.time
			if (target_id == "!BEACON!")
				beacon_connection.post_signal(src, signal)//, GUARDBOT_RADIO_RANGE)
			else
				radio_connection.post_signal(src, signal, GUARDBOT_RADIO_RANGE)

		add_task(var/computer/file/guardbot_task/newtask, var/high_priority = 0, var/clear_others = 0)
			if (clear_others)
				tasks.len = 0

			if (!newtask)
				return

			if (!istype(newtask))
				if (ispath(newtask))
					newtask = new newtask
				else
					return

			newtask.master = src

			if (clear_others)
				qdel(task)
				task = newtask
				tasks.len = 0
				tasks += task
				return

			if (high_priority)
				tasks.Insert(1, newtask)
				task = newtask
				return

			tasks += newtask
			if (tasks.len == 1)
				task = newtask
			return


		remove_current_task()
			if (!tasks.len) return

			if (!tasks)
				tasks = list()
				return

			tasks.Cut(1,2)

			var/old_task = task
			if (tasks.len)
				task = tasks[1]
			qdel(old_task)
			return

		set_emotion(var/new_emotion=null)
			if (emotion == new_emotion)
				return
			icon_needs_update = 1
			emotion = new_emotion
			if (hat || costume_icon || bedsheet)
				overlays = list((costume_icon ? costume_icon : null), (bedsheet ? image(icon, "bhat-ghost[bedsheet]") : null))
/*
			else
				src.overlays.len = 0 //Clear overlays so it will update on update_icon call
				hat_shown = 0
*/
		interact(mob/user as mob)
			var/dat = "<tt><strong>PR-6S Guardbuddy v1.4</strong></tt><br><br>"

			var/power_readout = null
			var/readout_color = "#000000"
			if (!cell)
				power_readout = "NO CELL"
			else
				var/charge_percentage = round((cell.charge/cell.maxcharge)*100)
				power_readout = "[charge_percentage]%"
				switch(charge_percentage)
					if (0 to 10)
						readout_color = "#F80000"
					if (11 to 25)
						readout_color = "#FFCC00"
					if (26 to 50)
						readout_color = "#CCFF00"
					if (51 to 75)
						readout_color = "#33CC00"
					if (76 to 100)
						readout_color = "#33FF00"

			dat += {"Power: <table border='1' style='background-color:[readout_color]'>
					<tr><td><font color=white>[power_readout]</font></td></tr></table><br>"}

			dat += "Current Tool: [src.tool ? src.tool.tool_id : "NONE"]<br>"

			if (locked)

				dat += "Status: [on ? "On" : "Off"]<br>"

			else

				dat += "Status: <a href='?src=\ref[src];power=1'>[on ? "On" : "Off"]</a><br>"

			dat += "<br>Network ID: <strong>\[[uppertext(net_id)]]</strong><br>"

			user << browse("<head><title>Guardbuddy v1.4 controls</title></head>[dat]", "window=guardbot")
			onclose(user, "guardbot")
			return

		update_icon()
			var/emotion_image = null

			if (!on)
				icon_state = "robuddy0"

			else if (stunned)
				icon_state = "robuddya"

			else if (idle)
				icon_state = "robuddy_idle"

			else
				if (emotion)
					emotion_image = image(icon, "face-[emotion]")
				icon_state = "robuddy1"

			overlays = list( emotion_image, bedsheet ? image(icon, "bhat-ghost[bedsheet]") : null, costume_icon ? costume_icon : null)

			if (hat && !hat_shown)
				var/image/hat_image = image(src.hat_icon, "bhat-[src.hat.icon_state]",,layer = 9.5) //TODO LAYER
				hat_image.pixel_x = hat_x_offset
				underlays = list(hat_image)
				hat_shown = 1

			icon_needs_update = 0
			return



//Robot tools.  Flash boards, batons, etc
/obj/item/device/guardbot_tool
	name = "Tool module"
	desc = "A generic module for a PR-6S Guardbuddy."
	icon = 'icons/obj/module.dmi'
	icon_state = "tool_generic"
	mats = 6
	w_class = 2.0
	var/is_stun = 0 //Can it be non-lethal?
	var/is_lethal = 0 //Can it be lethal?
	var/tool_id = "GENERIC" //Identification ID.
	var/is_gun = 0 //1 Is ranged, 0 is melee.
	var/last_use = 0 //If we want a use delay.

	proc
		bot_attack(var/atom/target as mob|obj, obj/machinery/bot/guardbot/user, ranged=0, lethal=0)
			if (!user || !user.on || user.stunned || user.idle)
				return TRUE

			return FALSE

	//A syringe gun module. Mercy sakes.
	medicator
		name = "Medicator tool module"
		desc = "A 'Medicator' syringe launcher module for PR-6S Guardbuddies. These things are actually outlawed on Earth."
		icon_state = "tool_syringe"
		tool_id = "SYRNG"
		is_gun = 1
		is_stun = 1 //Can be both nonlethal and lethal
		is_lethal = 1 //Depends on reagent load.
		var/projectile/current_projectile = new /projectile/syringe
		var/stun_reagent = "haloperidol"
		var/kill_reagent = "cyanide"

		// Updated for new projectile code (Convair880).
		bot_attack(var/atom/target as mob|obj, obj/machinery/bot/guardbot/user, ranged=0, lethal=0)
			if (..()) return

			if (last_use && world.time < last_use + 60)
				return

			if (ranged)
				var/obj/projectile/P = shoot_projectile_ST_pixel(master, current_projectile, target)
				if (!P)
					return
				if (!P.reagents)
					P.reagents = new /reagents(15)
					P.reagents.my_atom = P
				if (lethal)
					P.reagents.add_reagent(kill_reagent, 10)
				else
					P.reagents.add_reagent(stun_reagent, 15)

				user.visible_message("<span style=\"color:red\"><strong>[master] fires a syringe at [target]!</strong></span>")

			else
				var/obj/projectile/P = initialize_projectile_ST(master, current_projectile, target)
				if (!P)
					return
				if (!P.reagents)
					P.reagents = new /reagents(15)
					P.reagents.my_atom = P
				if (lethal)
					P.reagents.add_reagent(kill_reagent, 10)
				else
					P.reagents.add_reagent(stun_reagent, 15)

				user.visible_message("<span style=\"color:red\"><strong>[master] shoots [target] point-blank with a syringe!</strong></span>")
				P.was_pointblank = 1
				hit_with_existing_projectile(P, target)

			last_use = world.time
			return

	//Short-range smoke riot control module
	smoker
		name = "'Smoker' tool module"
		desc = "A riot-control gas module for PR-6S Guardbuddies."
		icon_state = "tool_smoke"
		tool_id = "SMOKE"
		is_stun = 1
		is_lethal = 1
		var/stun_reagent = "sonambutril"
		var/kill_reagent = "neurotoxin"

		New()
			..()
			var/reagents/R = new/reagents(500)
			reagents = R
			R.my_atom = src
			return

		// Fixed. Was completely non-functional (Convair880).
		bot_attack(var/atom/target as mob|obj, obj/machinery/bot/guardbot/user, ranged=0, lethal=0)
			if (..() || !reagents || ranged) return

			if (last_use && world.time < last_use + 120)
				return

			src.reagents.clear_reagents()
			if (lethal)
				reagents.add_reagent(kill_reagent, 15)
			else
				reagents.add_reagent(stun_reagent, 15)

			smoke_reaction(reagents, 3, get_turf(src))
			user.visible_message("<span style=\"color:red\"><strong>[master] releases a cloud of gas!</strong></span>")

			last_use = world.time
			return

	//Taser tool
	taser
		name = "Taser tool module"
		desc = "A taser module for PR-6S Guardbuddies."
		icon_state = "tool_taser"
		tool_id = "TASER"
		is_stun = 1
		is_gun = 1
		var/projectile/current_projectile = new/projectile/energy_bolt/robust

		// Updated for new projectile code (Convair880).
		bot_attack(var/atom/target as mob|obj, obj/machinery/bot/guardbot/user, ranged=0, lethal=0)
			if (..()) return

			if (last_use && world.time < last_use + 80)
				return

			if (ranged)
				var/obj/projectile/P = shoot_projectile_ST_pixel(master, current_projectile, target)
				if (!P)
					return

				user.visible_message("<span style=\"color:red\"><strong>[master] fires the taser at [target]!</strong></span>")

			else
				var/obj/projectile/P = initialize_projectile_ST(master, current_projectile, target)
				if (!P)
					return

				user.visible_message("<span style=\"color:red\"><strong>[master] shoots [target] point-blank with the taser!</strong></span>")
				P.was_pointblank = 1
				hit_with_existing_projectile(P, target)

			last_use = world.time
			return

	//Flash tool
	flash
		name = "Flash tool module"
		desc = "A flash module for PR-6S Guardbuddies."
		icon_state = "tool_flash"
		is_stun = 1
		tool_id = "FLASH"

		bot_attack(var/atom/target as mob|obj, obj/machinery/bot/guardbot/user, ranged=0, lethal=0)
			if (..()) return

			if (ranged) return

			if (iscarbon(target))

				var/mob/living/carbon/O = target

				if (last_use && world.time < last_use + 80)
					return

				playsound(user.loc, "sound/weapons/flash.ogg", 100, 1)
				flick("robuddy-c", user)
				last_use = world.time

				// We're flashing somebody directly, hence the 100% chance to disrupt cloaking device at the end.
				O.apply_flash(30, 8, 0, 0, 0, rand(0, 2), 0, 0, 100)

			return

	//Electrobolt tool.  Basically, Keelin owns ok
	tesla
		name = "Elektro-Arc tool module"
		desc = "An experimental tesla-coil module for PR-6S Guardbuddies."
		icon_state = "tool_tesla"
		tool_id = "TESLA"
		is_gun = 1
		is_stun = 1 //Can be both nonlethal and lethal
		is_lethal = 1

		bot_attack(var/atom/target as mob|obj, obj/machinery/bot/guardbot/user, ranged=0, lethal=0)
			if (..())
				return

			if (get_dist(user,target) > 4)
				return

			if (last_use && world.time < last_use + 80)
				return

			var/atom/last = user
			var/atom/target_r = target

			var/list/dummies = new/list()

			playsound(src, "sound/effects/elec_bigzap.ogg", 40, 1)

			if (isturf(target))
				target_r = new/obj/elec_trg_dummy(target)

			var/turf/currTurf = get_turf(target_r)
			currTurf.hotspot_expose(2000, 400)

			for (var/count=0, count<4, count++)

				var/list/affected = DrawLine(last, target_r, /obj/line_obj/elec ,'icons/obj/projectiles.dmi',"WholeLghtn",1,1,"HalfStartLghtn","HalfEndLghtn",OBJ_LAYER,1,PreloadedIcon='icons/effects/LghtLine.dmi')

				for (var/obj/O in affected)
					spawn (6) pool(O)

				if (istype(target_r, /mob/living)) //Probably unsafe.
					playsound(target_r:loc, "sound/effects/electric_shock.ogg", 50, 1)
					if (lethal)
						random_burn_damage(target_r, rand(45,60))
					boutput(target_r, "<span style=\"color:red\"><strong>You feel a powerful shock course through your body!</strong></span>")
					target_r:unlock_medal("HIGH VOLTAGE", 1)
					target_r:Virus_ShockCure(target_r, 100)
					target_r:shock_cyberheart(33)
					target_r:weakened += lethal ? 3 : 10
					break

				var/list/next = new/list()
				for (var/atom/movable/AM in orange(3, target_r))
					if (istype(AM, /obj/line_obj/elec) || istype(AM, /obj/elec_trg_dummy) || istype(AM, /obj/overlay/tile_effect) || AM.invisibility)
						continue
					next.Add(AM)

				if (istype(target_r, /obj/elec_trg_dummy))
					dummies.Add(target_r)

				last = target_r
				target_r = pick(next)
				target = target_r

			for (var/d in dummies)
				qdel(d)

			last_use = world.time
			return

	//xmas -- See spacemas.dm

//Task Datums
/computer/file/guardbot_task //Computer datum so it can be transmitted over radio
	name = "idle"
	var/task_id = "IDLE" //Small allcaps id for task
	var/tmp/obj/machinery/bot/guardbot/master = null
	var/tmp/atom/target = null
	var/tmp/list/secondary_targets = list()
	var/oldtarget_name
	var/last_found = 0
	var/handle_beacons = 0 //Can we handle beacon signals?

	proc
		task_act()
			if (!master || master.task != src)
				return TRUE
			if (!master.on || master.stunned)
				return TRUE

			return FALSE

		attack_response(mob/attacker as mob)
			if (!master || master.task != src)
				return TRUE
			if (!master.on || master.stunned || master.idle)
				return TRUE
			if (!istype(attacker))
				return TRUE

			return FALSE

		task_input(var/input)
			if (!master || !input || !master.on) return TRUE

			if (input == "hugged")
				switch(master.emotion)
					if (null)
						master.set_emotion("happy")
					if ("happy","smug")
						master.set_emotion("love")
					if ("joy","love")
						if (prob(25))
							master.visible_message("<span style=\"color:blue\">[master.name] reciprocates the hug!</span>")
				return TRUE

			return FALSE

		next_target() //Return true if there is a new target, false otherwise
			target = null
			if (secondary_targets.len)
				target = secondary_targets[1]
				secondary_targets -= secondary_targets[1]
				return TRUE
			return FALSE

		receive_signal(signal/signal, is_beacon=0)
			if (!master || !signal)
				return TRUE
			if (is_beacon && !handle_beacons)
				return TRUE
			return FALSE

		configure(var/list/confList)
			if (!confList || !confList.len)
				return TRUE

			return FALSE

	//Recharge task
	recharge
		name = "recharge"
		task_id = "RECHARGE"
		var/tmp/announced = 0
		var/dock_return = 0 //If 0: return to recharge, if 1: return for new programming

		dock_sync
			name = "sync"
			task_id = "SYNC"
			dock_return = 1
			announced = 1

		task_input(input)
			if (..()) return

			switch(input)
				if ("path_error","path_blocked")
					if (target)
						src.oldtarget_name = src.target.name
						next_target()
						last_found = world.time
				if ("snooze")
					target = null
					secondary_targets.len = 0

			return

		task_act()
			if (..()) return
			if (!dock_return && master.cell.charge >= (GUARDBOT_LOWPOWER_ALERT_LEVEL * 2))
				master.remove_current_task()
				return

			if (istype(target, /turf/simulated))
				var/obj/machinery/guardbot_dock/dock = locate() in target
				if (dock && dock.loc == master.loc)
					if (!isnull(dock.current) && dock.current != src)
						next_target()
					else
						var/auto_eject = 0
						if (!dock_return && master.tasks.len >= 2)
							auto_eject = 1
						dock.connect_robot(master,auto_eject)
						//master.snooze() //Connect autosnoozes the bot.
					return
				else if (target == master.loc)
					target = null
					last_found = world.time
					next_target()

				if (!master.moving)
					master.navigate_to(target)
			else
				if (!master.last_comm || (world.time >= master.last_comm + 100) )
					master.post_status("recharge","data","[master.cell.charge]")
					master.reply_wait = 2
					if (!announced)
						announced++
						master.speak("Low battery.")
						master.set_emotion("battery")
					else
						announced = 1

			return

		receive_signal(signal/signal)
			if (..()) return
			if (signal.data["command"] == "recharge_src")
				if (!master.reply_wait)
					return
				var/list/L = params2list(signal.data["data"])
				if (!L || !L["x"] || !L["y"]) return
				var/search_x = text2num(L["x"])
				var/search_y = text2num(L["y"])
				var/turf/simulated/new_target = locate(search_x,search_y,master.z)
				if (!new_target)
					return

				if (announced != 2)
					announced = 2
					secondary_targets = list()

					spawn (10)
						if (secondary_targets.len)
							master.reply_wait = 0
							. = INFINITY
							for (var/turf/T in secondary_targets)
								if (!target || (. > get_dist(master, T)))
									target = T
									. = get_dist(master, target)
									continue

							secondary_targets -= target

				secondary_targets += new_target

				//master.reply_wait = 0

			return

		attack_response(mob/attacker as mob)
			if (..())
				return

			var/computer/file/guardbot_task/security/single_use/beatdown = new
			beatdown.arrest_target = attacker
			beatdown.mode = 1
			master.add_task(beatdown, 1, 0)
			return

	//Buddytime task -- Even buddies need to relax sometimes!
	buddy_time
		name = "rumpus"
		handle_beacons = 1
		task_id = "RUMPUS"
		var/tmp/turf/simulated/bar_beacon_turf	//Location of bar beacon
		var/tmp/obj/stool/our_seat = null
		var/tmp/awaiting_beacon = 0
		var/tmp/nav_delay = 0
		var/tmp/beepsky_check_delay = 0
		var/tmp/state = 0
		var/tmp/party_counter = 90
		var/tmp/party_idle_counter = 0
		var/tmp/obj/machinery/bot/secbot/its_beepsky = null

		var/rumpus_emotion = "joy" //Emotion to express during buddytime.
		var/rumpus_location_tag = "buddytime" //Tag of the bar beacon

		task_act()
			if (..()) return

			switch (state)
				if (0)
					master.speak("Break time. Rumpus protocol initiated.")
					state = 1

				if (1)	//Seeking the bar.
					if (awaiting_beacon)
						awaiting_beacon--
						if (awaiting_beacon <= 0)
							master.speak("Error: Bar not found. Break canceled.")
							master.set_emotion("sad")
							master.remove_current_task()
							return

					if (istype(bar_beacon_turf, /turf/simulated))
						if (get_area(master) == get_area(bar_beacon_turf))
							state = 2
							master.moving = 0
							//master.current_movepath = "HEH"

							return

						if (!master.moving)
							if (nav_delay > 0)
								nav_delay--
								return
							master.navigate_to(bar_beacon_turf)
							nav_delay = 5

					else
						if (!master.last_comm || (world.time >= master.last_comm + 100) )
							awaiting_beacon = 10
							master.post_status("!BEACON!", "findbeacon", "patrol")
							master.reply_wait = 2

				if (2)	//Seeking a seat.
					if (!istype(target, /obj/stool))
						secondary_targets.len = 0
						for (var/obj/stool/S in view(7, master))
							secondary_targets += S

						if (secondary_targets.len)
							target = pick(secondary_targets)
						else
							master.speak("Error: No seating available. Break canceled.")
							master.set_emotion("sad")
							master.remove_current_task()
							return

					else
						if (target.loc == master.loc)
							master.set_emotion(rumpus_emotion)
							state = 3
							our_seat = target
							party_idle_counter = rand(4,14)
							if (!its_beepsky)
								locate_beepsky()
							return

						if (!master.moving)
							master.navigate_to(target, 2.5)

					return

				if (3) //IT IS RUMPUS TIME
					if (its_beepsky && (get_area(master) == get_area(its_beepsky)))
						beepsky_check_delay = 8
						state = 4
						master.set_emotion("ugh")
						if (its_beepsky.emagged == 2)
							src.master.speak(pick("Oh, look at the time.", "I need to go.  I have a...dentist appointment.  Yes", "Oh, is the break over already? I better be off.", "I'd best be leaving."))
							master.remove_current_task()
						return

					if (party_counter-- <= 0)
						master.set_emotion()
						master.speak("Break complete.")
						master.remove_current_task()
						return

					if (our_seat && our_seat.loc != master.loc)
						our_seat = null
						state = 2

					if (master.emotion != rumpus_emotion)
						master.set_emotion(rumpus_emotion)

					if (party_idle_counter-- <= 0)
						party_idle_counter = rand(4,14)
						if (prob(50))
							master.speak(pick("Yay!", "Woo-hoo!", "Yee-haw!", "Oh boy!", "Oh yeah!", "My favorite color is probably [pick("red","green","mauve","anti-flash white", "aureolin", "coquelicot")].", "I'm glad we have the opportunity to relax like this.", "Imagine if I had two arms. I could hug twice as much!", "I like [pick("tea","coffee","hot chocolate","soda", "diet soda", "milk", "almond milk", "soy milk", "horchata", "hot cocoa with honey mixed in", "green tea", "black tea")]. I have no digestive system or even a mouth, but I'm pretty sure I would like it.", "Sometimes I wonder what it would be like if I could fly."))

						else
							var/actiontext = pick("does a little dance. It's not very good but there's good effort there.", "slowly rotates around in a circle.", "attempts to do a flip, but is unable to jump.", "hugs an invisible being only it can see.", "rocks back and forth repeatedly.", "tilts side to side.", "claps.  Whaaat.", prob(1);"looks directly at you, the viewer.")
							if (master.hat && prob(8))
								actiontext = "adjusts its hat."
							master.visible_message("<strong>[master.name]</strong> [actiontext]")

				if (4)
					if (beepsky_check_delay-- > 0)
						return

					if (!its_beepsky || get_area(master) != get_area(its_beepsky))
						if (prob(10))
							master.speak(pick("Took long enough.", "Thought he'd never leave.", "Thought he'd never leave.  Too bad it smells like him in here now."))

						master.set_emotion(rumpus_emotion)
						state = 3
						return

					beepsky_check_delay = 8

			return

		task_input(var/input)
			if (..())
				return

			if (input == "path_error")
				master.speak("Error: Destination unreachable. Break canceled.")
				master.set_emotion("sad")
				master.remove_current_task()
				return

		receive_signal(signal/signal)
			if (..())
				return

			var/recv = signal.data["beacon"]
			var/valid = signal.data["patrol"]
			if (!awaiting_beacon || !recv || !valid || nav_delay)
				return

			//boutput(world, "patrol task received")

			if (recv == rumpus_location_tag)	// if the recvd beacon location matches the set destination
										// then we will navigate there
				bar_beacon_turf = get_turf(signal.source)
				awaiting_beacon = 0
				nav_delay = rand(3,5)

		attack_response(mob/attacker as mob)
			if (..())
				return

			var/computer/file/guardbot_task/security/single_use/beatdown = new
			beatdown.arrest_target = attacker
			beatdown.mode = 1
			master.add_task(beatdown, 1, 0)
			return

		proc/locate_beepsky() //Guardbots don't like beepsky. They think he's a jerk. They are right.
			if (its_beepsky) //Huh? We haven't lost him.
				return

			for (var/obj/machinery/bot/secbot/possibly_beepsky in machines)
				if (ckey(possibly_beepsky.name) == "officerbeepsky")
					its_beepsky = possibly_beepsky //Definitely beepsky in this case.
					break

			return

	//Security/Patrol task -- Essentially secbot emulation.
	security
		name = "secure"
		handle_beacons = 1
		task_id = "SECURE"
		var/tmp/new_destination		// pending new destination (waiting for beacon response)
		var/tmp/destination			// destination description tag
		var/tmp/next_destination	// the next destination in the patrol route
		var/tmp/nearest_beacon			// the nearest beacon's tag
		var/tmp/turf/nearest_beacon_loc	// the nearest beacon's location
		var/tmp/awaiting_beacon = 0
		var/tmp/patrol_delay = 0

		var/tmp/mob/living/carbon/arrest_target = null
		var/tmp/mob/living/carbon/hug_target = null
		var/list/target_names = list() //Dudes we are preprogrammed to arrest.
		var/tmp/mode = 0 //0: Patrol, 1: Arresting somebody
		var/tmp/arrest_attempts = 0
		var/tmp/cuffing = 0
		var/tmp/last_cute_action = 0

		var/weapon_access = access_carrypermit //These guys can use guns, ok!
		var/lethal = 0 //Do we use lethal force (if possible) ?
		var/panic = 0 //Martial law! Arrest all kinds!!
		var/no_patrol = 1 //Don't patrol.

		var/tmp/list/arrested_messages = list("Have a secure day!","Your move, creep.", "God made tomorrow for the crooks we don't catch today.","One riot, one ranger.")

#define ARREST_DELAY 2.5 //Delay between movements when chasing a criminal, slightly faster than usual. (2.5 vs 3)
#define TIME_BETWEEN_CUTE_ACTIONS 1800 //Tenths of a second between cute actions

		patrol
			name = "patrol"
			task_id = "PATROL"
			no_patrol = 0

		crazy
			name = "patr#(003~"
			task_id = "ERR0xF00F"
			lethal = 1
			panic = 1
			no_patrol = 0

		single_use
			no_patrol = 1

			drop_arrest_target()
				master.remove_current_task()
				return

			drop_hug_target()
				master.remove_current_task()
				return

		seek
			no_patrol = 0

			look_for_perp()
				if (arrest_target) return //Already chasing somebody
				for (var/mob/living/carbon/C in view(7,master)) //Let's find us a criminal
					if ((C.stat) || (C.handcuffed))
						continue

					if (assess_perp(C))
						master.remove_current_task()
						return

			assess_perp(mob/living/carbon/human/perp as mob)
				if (ckey(perp.name) == master.scratchpad["targetname"])
					return TRUE

				var/obj/item/card/id/perp_id = perp.equipped()
				if (!istype(perp_id))
					perp_id = perp.wear_id

				if (perp_id && ckey(perp_id.registered) == master.scratchpad["targetname"])
					return TRUE

				return FALSE

		task_act()
			if (..()) return

			look_for_perp()

			switch(mode)
				if (0)
					if (hug_target)

						if ((istype(hug_target) && hug_target.stat == 2) || (istype(hug_target, /obj/critter) && hug_target.health <= 0))
							hug_target = null
							master.set_emotion("sad")
							return

						if (get_dist(master, hug_target) <= 1)
							master.visible_message("<strong>[master]</strong> hugs [hug_target]!")
							if (hug_target.reagents)
								hug_target.reagents.add_reagent("hugs", 10)

							if (prob(50) && istype(hug_target) && hug_target.client && hug_target.client.IsByondMember())
								master.speak("You might want a breath mint.")

							drop_hug_target()
							master.set_emotion("love")
							master.moving = 0
							//master.current_movepath = "HEH"
							return

						if ((!(hug_target in view(7,master)) && (!master.mover || !master.moving)) || !master.path || !master.path.len || (4 < get_dist(hug_target,master.path[master.path.len])) )
							//qdel(master.mover)
							if (master.mover)
								master.mover.master = null
								master.mover = null
							master.moving = 0
							master.navigate_to(hug_target,ARREST_DELAY)
							return


						return

					if (patrol_delay)
						patrol_delay--
						return

					if (master.moving || no_patrol)
						return

					if (!master.moving)
						find_patrol_target()
				if (1)
					if (!arrest_target || !master.tool)
						mode = 0
						return

					if (arrest_target)

						if (!arrest_target in view(7,master) && !master.moving)
							//qdel(master.mover)
							master.frustration += 2
							if (master.mover)
								master.mover.master = null
								master.mover = null
							master.navigate_to(arrest_target,ARREST_DELAY, 0, 0)
							return

						else
							var/targdist = get_dist(master, arrest_target)
							if ((targdist <= 1) || (master.tool && master.tool.is_gun))
								if (!isliving(arrest_target) || arrest_target.stat == 2)
									mode = 0
									drop_arrest_target()
									return

								master.bot_attack(arrest_target, lethal)
								if (targdist <= 1 && !cuffing)
									cuffing = 1
									arrest_attempts = 0 //Put in here instead of right after attack so gun robuddies don't get confused
									playsound(master.loc, "sound/weapons/handcuffs.ogg", 30, 1, -2)
									master.visible_message("<span style=\"color:red\"><strong>[master] is trying to put handcuffs on [arrest_target]!</strong></span>")
									var/cuffloc = arrest_target.loc

									spawn (60)
										if (!master)
											return

										if (get_dist(master, arrest_target) <= 1 && arrest_target.loc == cuffloc)

											if (!cuffing)
												return
											if (!master || !master.on || master.idle || master.stunned)
												cuffing = 0
												return
											if (arrest_target.handcuffed || !isturf(arrest_target.loc))
												drop_arrest_target()
												return

											if (ishuman(arrest_target))
												var/mob/living/carbon/human/H = arrest_target
												//if (H.bioHolder.HasEffect("lost_left_arm") || H.bioHolder.HasEffect("lost_right_arm"))
												if (!H.limbs.l_arm || !H.limbs.r_arm)
													drop_arrest_target()
													master.set_emotion("sad")
													return

											if (iscarbon(arrest_target))
												arrest_target.handcuffed = new /obj/item/handcuffs/guardbot(arrest_target)
												boutput(arrest_target, "<span style=\"color:red\">[master] gently handcuffs you!  It's like the cuffs are hugging your wrists.</span>")
												arrest_target:set_clothing_icon_dirty()

											mode = 0
											drop_arrest_target()
											master.set_emotion("smug")

											if (arrested_messages && arrested_messages.len)
												var/arrest_message = pick(arrested_messages)
												master.speak(arrest_message)

										else
											cuffing = 0

									return
							if (!master.path || !master.path.len || (4 < get_dist(arrest_target,master.path[master.path.len])) )
								master.moving = 0
								//master.current_movepath = "HEH" //Stop any current movement.
								master.navigate_to(arrest_target,ARREST_DELAY, 0,0)

					return

			return

		task_input(input)
			if (..()) return

			switch(input)
				if ("snooze")
					patrol_delay = 0
					awaiting_beacon = 0
					next_destination = null
					target = null
					secondary_targets.len = 0
					if (arrest_target)
						arrest_target = null
						last_found = world.time
					arrest_attempts = 0
					cuffing = 0
				if ("path_error","path_blocked")
					arrest_attempts++
					if (arrest_attempts >= 2)
						cuffing = 0
						target = null
						if (arrest_target)
							arrest_target = null
							last_found = world.time
						mode = 0
						arrest_attempts = 0
						master.set_emotion()
				if ("treated")
					return ..("hugged")

			return

		receive_signal(signal/signal)
			if (..())
				return

			if (signal.data["command"] == "configure")
				if (signal.data["command2"])
					signal.data["command"] = signal.data["command2"]

				src.configure(signal.data)
				return

			var/recv = signal.data["beacon"]
			var/valid = signal.data["patrol"]
			if (!awaiting_beacon || !recv || !valid || patrol_delay)
				return

			//boutput(world, "patrol task received")

			if (recv == new_destination)	// if the recvd beacon location matches the set destination
										// then we will navigate there
				destination = new_destination
				target = signal.source.loc
				next_destination = signal.data["next_patrol"]
				awaiting_beacon = 0
				patrol_delay = rand(3,5) //So a patrol group doesn't bunch up on a single tile.

			// if looking for nearest beacon
			else if (new_destination == "__nearest__")
				var/dist = get_dist(master,signal.source.loc)
				if (nearest_beacon)

					// note we ignore the beacon we are located at
					if (dist>1 && dist<get_dist(master,nearest_beacon_loc))
						nearest_beacon = recv
						nearest_beacon_loc = signal.source.loc
						next_destination = signal.data["next_patrol"]
						target = signal.source.loc
						destination = recv
						awaiting_beacon = 0
						patrol_delay = 5
						return
					else
						return
				else if (dist > 1)
					nearest_beacon = recv
					nearest_beacon_loc = signal.source.loc
					next_destination = signal.data["next_patrol"]
					target = signal.source.loc
					destination = recv
					awaiting_beacon = 0
					patrol_delay = 5
			return

		attack_response(mob/attacker as mob)
			if (..())
				return

			if (!arrest_target)
				arrest_target = attacker
				mode = 1
				oldtarget_name = attacker.name
				master.set_emotion("angry")

			return

		configure(var/list/confList)
			if (..())
				return TRUE

			if (confList["patrol"])
				var/patrol_stat = text2num(confList["patrol"])
				if (!isnull(patrol_stat))
					if (patrol_stat)
						no_patrol = 0
					else
						no_patrol = 1

			if (confList["lethal"] && (confList["acc_code"] == netpass_heads))
				var/lethal_stat = text2num(confList["lethal"])
				if (!isnull(lethal_stat))
					if (lethal_stat && !lethal)
						lethal = 1
						if (master)
							master.speak("Notice: Lethal force authorized.")
					else if (lethal)
						lethal = 0
						if (master)
							master.speak("Notice: Lethal force is no longer authorized.")

			if (confList["name"] && !master)
				var/target_name = ckey(confList["name"])
				if (target_name && target_name != "")
					target_names = list(target_name)

			if (confList["command"])
				switch(lowertext(confList["command"]))
					if ("add_target")
						if (confList["acc_code"] != netpass_heads)
							return FALSE
						var/newtarget_name = ckey(confList["data"])
						if (!newtarget_name || newtarget_name == "")
							return FALSE

						if (!(newtarget_name in target_names))
							target_names += newtarget_name
							if (master)
								master.speak("Notice: Criminal database updated.")
						return FALSE
					if ("remove_target")
						if (confList["acc_code"] != netpass_heads)
							return FALSE
						var/seltarget_name = ckey(confList["data"])
						if (!seltarget_name || seltarget_name == "")
							return FALSE

						if (seltarget_name in target_names)
							target_names -= seltarget_name
							if (master)
								if (target_names.len)
									master.speak("Notice: Criminal database updated.")
								else
									master.speak("Notice: Criminal database cleared.")
						return FALSE

					if ("clear_targets")
						if (confList["acc_code"] != netpass_heads)
							return FALSE

						if (target_names.len)
							target_names = list()
							if (master)
								master.speak("Notice: Criminal database cleared.")
						return FALSE

			return FALSE

		proc
			look_for_perp()
				if (arrest_target) return //Already chasing somebody
				for (var/mob/living/carbon/C in view(7,master)) //Let's find us a criminal
					if ((C.stat) || (C.handcuffed))
						continue

					if ((C.name == oldtarget_name) && (world.time < last_found + 60))
						continue

					var/threat = 0
					if (ishuman(C))
						threat = assess_perp(C)
				//	else
				//		if (isalien(C))
				//			threat = 9

					if (threat >= 4)
						arrest_target = C
						oldtarget_name = C.name
						mode = 1
						master.frustration = 0
						master.set_emotion("angry")
						spawn (0)
							master.speak("Level [threat] infraction alert!")
							master.visible_message("<strong>[master]</strong> points at [C.name]!")
					else if (!last_cute_action || ((last_cute_action + TIME_BETWEEN_CUTE_ACTIONS) < world.time))
						if (prob(10))
							last_cute_action = world.time
							switch(rand(1,5))
								if (1)
									master.visible_message("<strong>[master]</strong> waves at [C.name].")
								if (2)
									master.visible_message("<strong>[master]</strong> rotates slowly around in a circle.")
								if (3,4)
									//hugs!!
									master.visible_message("<strong>[master]</strong> points at [C.name]!")
									master.speak( pick("Level [rand(1,32)] hug deficiency alert!", "Somebody needs a hug!", "Cheer up!") )
									hug_target = C
								if (5)
									master.visible_message("<strong>[master]</strong> appears to be having a [pick("great","swell","rad","wonderful")] day!")
									if (prob(50))
										master.speak("Woo!")
					return

			drop_arrest_target()
				arrest_target = null
				last_found = world.time
				cuffing = 0
				master.frustration = 0
				master.set_emotion()
				return

			drop_hug_target()
				hug_target = null
				return

			find_patrol_target()
				if (awaiting_beacon)			// awaiting beacon response
					awaiting_beacon--
					if (awaiting_beacon <= 0)
						find_nearest_beacon()
					return

				if (next_destination)
					set_destination(next_destination)
					if (!master.moving && target && (target != master.loc))
						master.navigate_to(target)
					return
				else
					find_nearest_beacon()
				return

			find_nearest_beacon()
				nearest_beacon = null
				new_destination = "__nearest__"
				master.post_status("!BEACON!", "findbeacon", "patrol")
				awaiting_beacon = 5
				spawn (10)
					if (!master || !master.on || master.stunned || master.idle) return
					if (master.task != src) return
					awaiting_beacon = 0
					if (nearest_beacon && !master.moving)
						master.navigate_to(nearest_beacon_loc)
					else
						patrol_delay = 8
						target = null
						return

			set_destination(var/new_dest)
				new_destination = new_dest
				master.post_status("!BEACON!", "findbeacon", "patrol")
				awaiting_beacon = 5

			assess_perp(mob/living/carbon/human/perp as mob)
				. = 0

				if (panic)
					return 9

				if (ckey(perp.name) in target_names)
					return 7

				var/obj/item/card/id/perp_id = perp.equipped()
				if (!istype(perp_id))
					perp_id = perp.wear_id

				if (perp_id)
					if (ckey(perp_id.registered) in target_names)
						return 7

					if (weapon_access in perp_id.access)
						return FALSE

				if (istype(perp.l_hand))
					. += perp.l_hand.contraband

				if (istype(perp.r_hand))
					. += perp.r_hand.contraband

				if (istype(perp:belt))
					. += perp:belt.contraband * 0.5

				if (istype(perp:wear_suit))
					. += perp:wear_suit.contraband

				if (perp.mutantrace && perp.mutantrace.jerk)
//					if (istype(perp.mutantrace, /mutantrace/zombie))
//						return 5 //Zombies are bad news!

//					threatcount += 2

					return 5


		halloween //Go trick or treating!
			name = "candy"
			task_id = "CANDY"
			no_patrol = 0

			look_for_perp()
				if (hug_target)
					return
				for (var/mob/living/carbon/C in view(7,master)) //Let's get some candy!
					if ((C.stat) || (C.handcuffed))
						continue

					if ((C.name == oldtarget_name) && (world.time < last_found + 60))
						continue

					var/threat = 0
					if (ishuman(C))
						threat = assess_perp(C)
				//	else
				//		if (isalien(C))
				//			threat = 9

					if (threat < 4 && (!last_cute_action || ((last_cute_action + TIME_BETWEEN_CUTE_ACTIONS) < world.time)))
						oldtarget_name = C.name
						if (prob(10))
							hug_target = C
					return

			task_input(var/input)
				if (input == "treated")
					if (..("filler"))
						return TRUE

					master.speak( pick("Yayyy! Thank you!", "Whoohoo, candy!", "Thank you!  I can't actually eat candy, but I enjoy the aesthetic aspect of it.") )
					master.set_emotion("happy")
				else
					if (..())
						return TRUE


			task_act()
				if (master && mode == 0 && hug_target)
					if (hug_target.stat == 2)
						hug_target = null
						master.set_emotion("sad")
						return

					if (get_dist(master, hug_target) <= 1)
						if (prob(2))
							master.speak("Merry Christmas!")
							spawn (10)
								if (master)
									master.speak("Warning: Real-time clock battery low or missing.")
						else
							master.speak("Trick or treat!")
						if (prob(50) && hug_target.client && hug_target.client.IsByondMember())
							master.speak("Oh wait, you're the one who just hands out [pick("religious tracts","pennies", "toothbrushes")].")
						master.set_emotion("love")

						hug_target = null
						master.moving = 0
						//master.current_movepath = "HEH"
						return

					if ((!(hug_target in view(7,master)) && (!master.mover || !master.moving)) || !master.path || !master.path.len || (4 < get_dist(hug_target,master.path[master.path.len])) )
						//qdel(master.mover)
						if (master.mover)
							master.mover.master = null
							master.mover = null
						master.moving = 0
						master.navigate_to(hug_target,ARREST_DELAY)
						return

				else
					return ..()

		purge //Arrest anyone who isn't a DWAINE superuser.
			name = "purge"
			task_id = "PURGE"
			no_patrol = 0
			var/accepted_access = access_dwaine_superuser

			assess_perp(mob/living/carbon/human/perp as mob)
				var/obj/item/card/id/the_id = perp.wear_id
				if (!the_id)
					the_id = perp.equipped()
				if (!istype(the_id) || (the_id && !(accepted_access in the_id.access)) )
					return 9
				else
					return ..()
/*
		klaus //todo
			name = "klaus"
			task_id = "KLAUS"

			look_for_perp()
				. = ..()
				if (arrest_target)
					return
*/

		area_guard
			name = "areaguard"
			task_id = "AREAG"
			no_patrol = 1
			var/area/current_area = null

			look_for_perp()
				current_area = get_area(master)

				return ..()

			assess_perp(mob/living/carbon/human/perp as mob)
				var/area/perp_area = get_area(perp)
				if (perp_area == current_area)
					return ..()

				return FALSE


	//Bodyguard Task -- Guard some dude's personal space
	bodyguard
		name = "bodyguard"
		task_id = "GUARD"

		var/tmp/mob/living/carbon/protected = null
		var/tmp/mob/living/carbon/arrest_target = null
		var/tmp/arrest_attempts = 0
		var/tmp/follow_attempts = 0
		var/tmp/cuffing = 0
		var/tmp/mode = 0 //0: Following protectee, 1: Arresting threat

		var/lethal = 0 //Do we use lethal force (if possible) ?
		var/desired_emotion = "look"
		var/tmp/attacked_by_buddy = 0 //Has our buddy hit us? Buddy abuse is a serious problem.
		var/tmp/buddy_is_dork = 0 //Our buddy kinda sucks :(
		var/tmp/list/arrested_messages = list("Threat neutralized.","Station secure.","Problem resolved.")

		var/protected_name = null //Who are we seeking?

#define SEARCH_EMOTION "look"
#define GUARDING_EMOTION "cool"
#define GUARDING_DORK_EMOTION "coolugh"
#define CHASING_EMOTION "angry"

		task_act()
			if (..())
				return TRUE

			if (master.emotion != desired_emotion)
				master.set_emotion(desired_emotion)

			if (arrest_target) //Priority one: Arrest a jerk who hurt our buddy.
				desired_emotion = CHASING_EMOTION
				master.set_emotion(CHASING_EMOTION)

				handle_arrest_function()
				return

			if (!protected) //Priority two: Assess status of buddy.
				desired_emotion = SEARCH_EMOTION
				look_for_protected()
				return
			else
				desired_emotion = buddy_is_dork ? GUARDING_DORK_EMOTION : GUARDING_EMOTION

				if (check_buddy()) //Should ONLY return true when we pick up a new arrest target.
					master.set_emotion(CHASING_EMOTION)
					handle_arrest_function() //So we don't have to wait for the next process. LIVES ARE ON THE LINE HERE!
					return

				if (!protected in view(7,master) && !master.moving)
					//qdel(master.mover)
					master.frustration++
					if (master.mover)
						master.mover.master = null
						master.mover = null
					master.navigate_to(protected,3,1,1)
					return
				else

					if (protected.stat == 2)
						protected = null
						if (buddy_is_dork && prob(50))
							master.speak(pick("Rest in peace.  I guess", "At least that's over.", "I didn't have the courage to tell you this, but you smelled like rotten ham."))
						else
							master.speak(pick("Rest in peace.","Guard protocol...inactive.","I'm sorry it had to end this way.","It was an honor to serve alongside you."))
						return

					if (!master.path || !master.path.len || (3 < get_dist(protected,master.path[master.path.len])) )
						master.moving = 0
						//qdel(master.mover)
						if (master.mover)
							master.mover.master = null
							master.mover = null
						master.navigate_to(protected,3,1,1)

			return

		task_input(input)
			if (..()) return

			switch(input)
				if ("snooze")
//					arrest_target = null
					protected = null
					arrest_attempts = 0
					follow_attempts = 0
					cuffing = 0
				if ("path_error","path_blocked")

					if (protected)
						if (!(protected in view(7,master)))
							follow_attempts++
							if (follow_attempts >= 2)
								follow_attempts = 0
								protected = null
						return

			return

		attack_response(mob/attacker as mob)
			if (..())
				return

			if (attacker == protected && !attacked_by_buddy)
				attacked_by_buddy = 1
				master.speak(pick("Check your fire!","Watch it!","Friendly fire will not be tolerated!"))
				return

			if (!arrest_target)
				arrest_target = attacker
				if (attacker == protected)
					protected = null

			return

		configure(var/list/confList)
			if (..())
				return TRUE

			if (confList["name"])
				protected_name = ckey(confList["name"])

			return FALSE

		proc
			look_for_protected() //Search for a mob in view with the name we are programmed to guard.
				if (protected) return //We have someone to protect!
				for (var/mob/living/C in view(7,master))
					if (C.stat == 2) //We were too late!
						continue

					var/check_name = C.name
					if (ishuman(C) && C:wear_id)
						check_name = C:wear_id:registered

					if (ckey(check_name) == ckey(protected_name))
						protected = C
						desired_emotion = GUARDING_EMOTION
						C.unlock_medal("Ol' buddy ol' pal", 1)
						buddy_is_dork = (C.client && C.client.IsByondMember())
						spawn (0)
							//if (buddy_is_dork && prob(50))
								//master.speak(pick("I am here to protect...Oh, it's <em>you</em>.", "I have been instructed to guard you. Welp.", "You are now under guard.  I guess."))
							master.speak(pick("I am here to protect you.","I have been instructed to guard you.","You are now under guard.","Come with me if you want to live!"))
							master.visible_message("<strong>[master]</strong> points at [C.name]!")
						break

				return

			drop_arrest_target()
				arrest_target = null
				cuffing = 0
				return

			check_buddy()
				//Out of sight, out of mind.
				if (!(protected in view(7,master)))
					return FALSE
				//Has our buddy been attacked??
				if (protected.lastattacker && (protected.lastattackertime + 40) >= world.time)
					if (protected.lastattacker != protected)
						master.moving = 0
						//qdel(master.mover)
						if (master.mover)
							master.mover.master = null
							master.mover = null
						arrest_target = protected.lastattacker
						follow_attempts = 0
						arrest_attempts = 0
						return TRUE
				return FALSE

			handle_arrest_function()

				var/computer/file/guardbot_task/security/single_use/beatdown = new
				beatdown.arrest_target = arrest_target
				beatdown.mode = 1
				beatdown.arrested_messages = arrested_messages
				arrest_target = null
				master.add_task(beatdown, 1, 0)

				return

	bodyguard/heckle
		name = "heckle"
		task_id = "HECKLE"
		var/global/list/buddy_heckle_phrases = list( "Neeerrd!", "Dork!", "Hey! Hey!  You smell...bad!  Really bad!", "Hey! You have an odor! A grody one!  GRODY NERD ALERT!", "Did you get lost on the way to your anime club?", "Are you as bad at your job as you are at dressing yourself?", "You should probably eat something other than fatty beef jerky for every meal.  Your family is getting worried about you.","I'm sorry they didn't let you wear your fedora to work today.", "CAUTION: Poor impulse control!","That's a, um, really unfortunate choice of uniform.  Maybe you should try something with vertical stripes to de-emphasize the...you know.", "You, uh, should probably wash your hair.  I think if you took a swim, all the seals would die.")
		var/tmp/initial_seek_complete = 0

		task_act()
			if (..())
				return

			if (protected && prob(10))
				master.speak( pick(buddy_heckle_phrases) )
				master.visible_message("<strong>[master]</strong> points at [protected.name]!")

		look_for_protected() //Search for a mob in view with the name we are programmed to guard.
			if (protected) return //We have someone to protect!
			for (var/mob/living/C in view(7,master))
				if (C.stat == 2) //We were too late!
					continue

				var/check_name = C.name
				if (ishuman(C) && C:wear_id)
					check_name = C:wear_id:registered

				if (ckey(check_name) == ckey(protected_name))
					protected = C
					buddy_is_dork = 1
					//desired_emotion = GUARDING_EMOTION
					spawn (0)
						master.speak("Level 9F [pick("dork","nerd","weenie","doofus","loser","dingus","dorkus")] detected!")
						master.visible_message("<strong>[master]</strong> points at [C.name]!")
					return

				if (!initial_seek_complete)
					initial_seek_complete = 1
					master.scratchpad["targetname"] = ckey(protected_name)
					master.add_task(/computer/file/guardbot_task/security/seek, 1, 0)

			return

		check_buddy()
			return FALSE

#undef SEARCH_EMOTION
#undef GUARDING_EMOTION
#undef GUARDING_DORK_EMOTION
#undef CHASING_EMOTION



#define STATE_FINDING_BEACON 0//Byond, enums, lack thereof, etc
#define STATE_PATHING_TO_BEACON 1
#define STATE_AT_BEACON 2
#define STATE_POST_TOUR_IDLE 3

//Neat things we've seen on this trip
#define NT_WIZARD 1
#define NT_CAPTAIN 2
#define NT_JONES 4
#define NT_BEE 8
#define NT_SECBOT 16
#define NT_BEEPSKY 32
#define NT_OTHERBUDDY 64
#define NT_SPACE 128
#define NT_DORK 256
#define NT_CLOAKER 1024
#define NT_GEORGE 2048
#define NT_DRONE 4096
#define NT_AUTOMATON 8192
#define NT_CHEGET 16384
#define NT_GAFFE 32768 //Note: this is the last one the bitfield can fit.  Thanks, byond!!

	tourguide
		name = "tourguide"
		task_id = "TOUR"
		handle_beacons = 1

		var/wait_for_guests = 0		//Wait for people to be around before giving tour dialog?

		var/tmp/state = STATE_FINDING_BEACON
		var/tmp/desired_emotion = "happy"

		var/tmp/list/visited_beacons = list()
		var/tmp/next_beacon_id = "tour0"
		var/tmp/current_beacon_id = null
		var/tmp/turf/current_beacon_loc = null
		var/tmp/awaiting_beacon = 0
		var/tmp/current_tour_text = null
		var/tmp/tour_delay = 0
		var/tmp/neat_things = 0		//Bitfield to mark neat things seen on a tour.
		var/tmp/recent_nav_attempts = 0

#define TOUR_FACE "happy"
#define ANGRY_FACE "angry"

		//Method of operation:
		//Locate starting beacon or last beacon
		//Check name of beacon against list of visited beacons.
		//Interrogate beacon for information string, if any
		//Say information string once our tourgroup (or some random doofus, it doesn't really matter) has arrived.
		//Locate next beacon OR finish if none defined.

		task_act()
			if (..())
				return

			if (master.emotion != desired_emotion)
				master.set_emotion(desired_emotion)

			switch (state)
				if (STATE_FINDING_BEACON)
					if (awaiting_beacon)
						awaiting_beacon--
						return

					if (!next_beacon_id)
						next_beacon_id = initial(next_beacon_id)

					awaiting_beacon = 10

					master.post_status("!BEACON!", "findbeacon", "tour")
					return

				if (STATE_PATHING_TO_BEACON)
					if (!isturf(current_beacon_loc))
						state = STATE_FINDING_BEACON
						return

					if (prob(20))
						look_for_neat_thing()

					if (!master.moving)
						if (awaiting_beacon > 0)
							awaiting_beacon--
							return

						if (current_beacon_loc != master.loc)
							master.navigate_to(current_beacon_loc)
						else
							state = STATE_AT_BEACON
					return

				if (STATE_AT_BEACON)
					if (wait_for_guests && !locate(/mob/living/carbon) in view(master)) //Maybe we shouldn't speak to no-one??
						return	//I realize this doesn't check if they're dead.  Buddies can't always tell, ok!! Maybe if people had helpful power lights too

					if (ckey(current_tour_text))
						if (findtext(current_tour_text, "|p")) //There are pauses present! So, um, pause.
							var/list/tour_text_with_pauses = splittext(current_tour_text, "|p")
							spawn (0)
								sleep(10)
								for (var/tour_line in tour_text_with_pauses)
									if (!ckey(tour_line) || !master)
										break

									master.speak( copytext( html_encode(tour_line), 1, MAX_MESSAGE_LEN ) )
									sleep(10)
						else
							master.speak( copytext(html_encode(current_tour_text), 1, MAX_MESSAGE_LEN))

					if (next_beacon_id)
						state = STATE_FINDING_BEACON
						awaiting_beacon = 3 //This will just serve as a delay so the buddy isn't zipping around at light speed between stops.
					else
						state = STATE_POST_TOUR_IDLE
						tour_delay = 30
						master.speak("And that concludes the tour session.  Please visit the gift shop on your way out.")
					return

				if (STATE_POST_TOUR_IDLE)
					if (tour_delay-- > 0)
						return

					next_beacon_id = initial(next_beacon_id)
					state = STATE_FINDING_BEACON
					neat_things = 0

			return

		attack_response(mob/attacker as mob)
			if (..())
				return

			master.set_emotion(ANGRY_FACE)
			master.speak(pick("Rude!","That is not acceptable behavior!","This is a tour, not a fight factory!","You have been ejected from the tourgroup for: Roughhousing.  Please be aware that tour sessions are non-refundable."))
			var/computer/file/guardbot_task/security/single_use/beatdown = new
			beatdown.arrest_target = attacker
			beatdown.mode = 1
			master.add_task(beatdown, 1, 0)
			return

		task_input(input)
			if (..()) return

			switch(input)
				if ("snooze")
					awaiting_beacon = 0
					next_beacon_id = null

				if ("path_error","path_blocked")
					if (recent_nav_attempts++ > 10)
						recent_nav_attempts = 0
						awaiting_beacon = 10
			return

		receive_signal(signal/signal)
			if (..())
				return

			var/recv = signal.data["beacon"]
			var/valid = signal.data["tour"]
			if (!awaiting_beacon || !recv || !valid || state != STATE_FINDING_BEACON)
				return


			if (recv == next_beacon_id)	// if the recvd beacon location matches the set destination
										// then we will navigate there
				current_beacon_id = next_beacon_id
				current_beacon_loc = signal.source.loc
				next_beacon_id = signal.data["next_tour"]
				awaiting_beacon = 0

				state = STATE_PATHING_TO_BEACON

				if (ckey(signal.data["desc"]))
					current_tour_text = signal.data["desc"]
				else
					current_tour_text = null

			return

		proc/look_for_neat_thing()
			var/area/spaceArea = get_area(master)
			if (!(neat_things & NT_SPACE) && spaceArea && spaceArea.name == "Space" && !istype(get_turf(master), /turf/simulated/shuttle))
				neat_things |= NT_SPACE
				master.speak(pick("While you find yourself surrounded by space, please try to avoid the temptation to inhale any of it.  That doesn't work.",\
				 "Space: the final frontier.  Oh, except for time travel and any other dimensions.  And frontiers on other planets, including other planets in those other dimensions and times.  Maybe I should stick with \"space: a frontier.\"",\
				 "Those worlds in space are as countless as all the grains of sand on all the beaches of the earth. Each of those worlds is as real as ours and every one of them is a succession of incidents, events, occurrences which influence its future. Countless worlds, numberless moments, an immensity of space and time.  This Sagan quote and others like it are available on mugs at the gift shop.",\
				 "Please keep hold of the station at all times while in an exposed area.  The same principle does not apply to your breath without a mask.  Your lungs will pop like bubblegum.  Just a heads up."))
				return

			for (var/atom/movable/AM in view(7, master))
				if (istype(AM, /mob/living/carbon/human))
					var/mob/living/carbon/human/H = AM
					if (!(neat_things & NT_GAFFE) && H.stat != 2 && !H.sight_check(1))
						neat_things |= NT_GAFFE
						master.speak("Ah! As you can see here--")

						spawn (10)
							. = desired_emotion //We're going to make him sad until the end of this spawn, ok.
							desired_emotion = "sad"
							master.set_emotion(desired_emotion)
							master.speak("OH! Sorry! Sorry, [H.name]! I didn't mean it that way!")
							sleep(5)
							var/mob/living/carbon/human/deaf_person = null
							for (var/mob/living/carbon/human/maybe_deaf in view(7, master))
								if (maybe_deaf.stat != 2 && !maybe_deaf.hearing_check(1))
									deaf_person = maybe_deaf
									break

							if (deaf_person)
								master.speak("I'll just narrate things so you can all hear it--")
								sleep(10)
								if (deaf_person == H)
									master.speak("SORRY [H] I DIDN'T MEAN THAT EITHER AAAA")

								else
									master.speak("Oh! Sorry! Sorry, [deaf_person.name]!! I didn't mean that that way eith-wait um.")
									sleep(10)
									master.visible_message("<strong>[master]</strong> begins signing frantically!  Despite, um, robot hands not really being equipped for sign language.")

							sleep(100)
							desired_emotion = .
							master.set_emotion(desired_emotion)

					if (!(neat_things & NT_CLOAKER) && H.invisibility > 0)
						master.speak("As a courtesy to other tourgroup members, you are requested, though not required, to deactivate any cloaking devices, stealth suits, light redirection field packs, and/or unholy blood magic.")
						neat_things |= NT_CLOAKER
						return

					if (!(neat_things & NT_WIZARD) && istype(H.wear_suit, /obj/item/clothing/suit/wizrobe) )
						master.speak( pick("Look, group, a wizard!  Please be careful, space wizards can be dangerous.","Ooh, a real space wizard!  Look but don't touch, folks!","Space wizards are highly secretive, especially regarding the nature of their abilities.  Current speculation is that their \"magic\" is really the application of advanced technologies or artifacts.") )
						neat_things |= NT_WIZARD
						return

					if (!(neat_things & NT_CAPTAIN) && istype(H.head, /obj/item/clothing/head/caphat))
						neat_things |= NT_CAPTAIN
						master.speak("Good day, Captain!  You're looking [pick("spiffy","good","swell","proper","professional","prim and proper", "spiffy", "ultra-spiffy")] today.")
						return

					if (!(neat_things & NT_DORK) && (H.client && H.client.IsByondMember()))// || (H.ckey in Dorks))) //If this is too mean to clarks, remove that part I guess
						neat_things |= NT_DORK

						var/insult = pick("dork","nerd","weenie","doofus","loser","dingus","dorkus")
						var/insultphrase = "And if you look to--[insult] alert!  [pick("Huge","Total","Mega","Complete")] [insult] detected! Alert! Alert! [capitalize(insult)]! "

						insultphrase += copytext(insult,1,2)
						var/i = rand(3,7)
						while (i-- > 0)
							insultphrase += copytext(insult,2,3)
						insultphrase += "[copytext(insult,3)]!!"

						master.speak(insultphrase)

						var/P = new /obj/decal/point(get_turf(H))
						spawn (40)
							qdel(P)

						master.visible_message("<strong>[master]</strong> points to [H]")
						return

				else if (!(neat_things & NT_JONES) && istype(AM, /obj/critter/cat) && AM.name == "Jones")
					neat_things |= NT_JONES
					var/obj/critter/cat/jones = AM
					master.speak("And over here is the ship's cat, J[jones.alive ? "ones! No spacecraft is complete without a cat!" : "-oh mercy, MOVING ON, MOVING ON"]")
					return

				else if (istype(AM, /obj/critter/domestic_bee) && AM:alive && !(neat_things & NT_BEE))
					neat_things |= NT_BEE
					if (istype(AM, /obj/critter/domestic_bee/trauma))
						master.speak("Look, team, a domestic space bee!  This happy creature--oh dear.  Hold on, please.")
						var/computer/file/guardbot_task/security/single_use/emergency_hug = new
						emergency_hug.hug_target = AM
						master.add_task(emergency_hug, 1, 0)
						return


					master.speak("Look, team, a domestic space bee!  This happy creature is the result of decades of genetic research!")

					switch (rand(1,5))
						if (1)
							master.speak("Fun fact: Domestic space bee DNA is [rand(1,17)]% [pick("dog", "human", "cat", "honeybee")]")

						if (2)
							master.speak("Fun fact: Domestic space bees are responsible for over [rand(45,67)]% of all honey production outside of Earth!")

						if (3)
							master.speak("Fun fact: Domestic space bees are very well adapted to accidental space exposure, and can survive in that environment for upwards of [pick("ten hours", "two days", "42 minutes", "three-score ke", "one-and-one-half nychthemeron")].")

						if (4)
							master.speak("Fun fact: Domestic space bee DNA is protected by U.S. patent number [rand(111,999)],[rand(111,999)],[rand(555,789)].")

						if (5)
							master.speak("Fun fact: The average weight of a domestic space bee is about [pick("10 pounds","4.54 kilograms", "25600 drams", "1.42857143 cloves", "145.833333 troy ounces")].")

					return

				else if (istype(AM, /obj/critter/dog/george) && !(neat_things & NT_GEORGE))
					neat_things |= NT_GEORGE
					master.speak("Why, if it isn't beloved station canine, George!  Who's a good doggy?  You are!  Yes, you!")

				else if (istype(AM, /obj/critter/gunbot/drone) && !(neat_things & NT_DRONE))
					neat_things |= NT_DRONE
					src.master.speak( pick("Oh dear, a syndicate autonomous drone!  These nasty things have been shooting up innocent space-folk for a couple of years now.", "Watch out, folks!  That's a syndicate drone, they're nasty buggers!", "Ah, a syhndicate drone!  They're made in a secret factory, one located at--oh dear, we better get hurrying before it becomes upset.", "Watch out, that's a syndicate drone!  They're made in a secret factory. There was a guy who knew where it was on my first tour, but he took the secret...to his grave!!  Literally.  It's with him.  In his crypt.") )

				else if (!(neat_things & NT_AUTOMATON) && istype(AM, /obj/critter/automaton))
					neat_things |= NT_AUTOMATON
					master.speak("This here is some kind of automaton.  This, uh, porcelain-faced, click-clackity metal man.")
					. = "Why [istype(get_area(AM), /area/solarium) ? "am I" : "is this"] here?"
					spawn (20)
						master.speak(.)

				else if (istype(AM, /obj/machinery/bot))
					if (istype(AM, /obj/machinery/bot/secbot))
						if (AM.name == "Officer Beepsky" && !(neat_things & NT_BEEPSKY))
							neat_things |= NT_BEEPSKY
							master.speak("And here comes Officer Beepsky, the proud guard of this station. Proud.")
							master.speak("Not at all terrible.  No Sir.  Not at all.")
							if (prob(10))
								spawn (15)
									master.speak("Well okay, maybe a little.")

							return

						else if (!(neat_things & NT_SECBOT))
							neat_things |= NT_SECBOT
							master.speak("And if you look over now, you'll see a securitron, an ace security robot originally developed \"in the field\" from spare parts in a security office!")

							return

					else if (istype(AM, /obj/machinery/bot/guardbot) && AM != master)
						var/obj/machinery/bot/guardbot/otherBuddy = AM
						if (!(neat_things & NT_CAPTAIN) && istype(otherBuddy.hat, /obj/item/clothing/head/caphat))
							neat_things |= NT_CAPTAIN
							master.speak("Good day, Captain!  You look a little different today, did you get a haircut?")
							var/otherBuddyID = otherBuddy.net_id
							//Notify other buddy
							spawn (10)
								if (master)
									master.post_status("[otherBuddyID]", "command", "captain_greet")
							return

						else if (!(neat_things & NT_WIZARD) && istype(otherBuddy.hat, /obj/item/clothing/head/wizard))
							neat_things |= NT_WIZARD
							master.speak("Look, a space wizard!  Please stand back, I am going to attempt to communicate with it.")
							master.speak("Hello, Mage, Seer, Wizard, Wizzard, or other magic-user.  We mean you no harm!  We ask you humbly for your WIZARDLY WIZ-DOM.")
							if (prob(25))
								master.speak("We hope that we aren't disrupting any sort of wiz-biz or wizness deal.")
							//As before, notify the other buddy
							var/otherBuddyID = otherBuddy.net_id
							spawn (10)
								if (master)
									master.post_status("[otherBuddyID]", "command", "wizard_greet")

						else if (!(neat_things & NT_OTHERBUDDY))
							neat_things |= NT_OTHERBUDDY
							if (istype(otherBuddy, /obj/machinery/bot/guardbot/future))
								master.speak("The PR line of personal robot has been--wait! Hold the phone! Is that a PR-7? Oh man, I feel old!")
								return

							if (istype(otherBuddy, /obj/machinery/bot/guardbot/old/tourguide/lunar))
								src.master.visible_message("<strong>[master]</strong> waves at [otherBuddy].")
								return

							master.speak("The PR line of personal robot has been Thinktronic Data Systems' flagship robot line for over 15 years.  It's easy to see their appeal!")
							switch (rand(1,4))
								if (1)
									master.speak("Buddy Fact: In 2051, Robuddies were conclusively determined to have a[prob(40) ? "t least three-fourths of a" : ""] soul.")
								if (2)
									master.speak("Buddy Fact: Robuddies cannot jump.  We just can't, sorry!")
								if (3)
									master.speak("Buddy Fact: Our hug protocols have been extensively revised through thousands of rounds of testing and simulation to deliver Peak Cuddle.")
								if (4)
									master.speak("Buddy Fact: Robuddies are programmed to be avid fans of hats and similar headgear.")

				else if ((istype(AM, /obj/item/luggable_computer/cheget) || istype(AM, /obj/machinery/computer3/luggable/cheget)) && !(neat_things & NT_CHEGET))
					neat_things |= NT_CHEGET
					master.speak( pick("And over there is--NOTHING.  Not a thing.  Let's continue on with the tour.", "Please ignore the strange briefcase, is what I would say, were there a strange briefcase.  But there is not, and even if there was you should ignore it.","This is just a reminder that station crew are not to handle Soviet materials, per a whole bunch of treaties and negotiations.") )

					AM.visible_message("<strong>[AM]</strong> bloops sadly.")
					playsound(AM.loc, prob(50) ? 'sound/machines/cheget_sadbloop.ogg' : 'sound/machines/cheget_somberbloop.ogg', 50, 1)


			return

//Be kind, undefine...d
#undef STATE_FINDING_BEACON
#undef STATE_PATHING_TO_BEACON
#undef STATE_AT_BEACON
#undef STATE_POST_TOUR_IDLE

#undef TOUR_FACE
#undef ANGRY_FACE

#undef NT_WIZARD
#undef NT_CAPTAIN
#undef NT_JONES
#undef NT_BEE
#undef NT_SECBOT
#undef NT_BEEPSKY
#undef NT_OTHERBUDDY
#undef NT_SPACE
#undef NT_DORK
#undef NT_CLOAKER
#undef NT_GEORGE
#undef NT_DRONE
#undef NT_AUTOMATON
#undef NT_CHEGET
#undef NT_GAFFE

	bedsheet_handler
		name = "confusion"
		task_id = "HUH"
		var/announced = 0
		var/escape_counter = 4

		task_act()
			if (..())
				return

			if (master.bedsheet != 1)
				master.remove_current_task()
				return

			if (!announced)
				announced = 1
				master.speak(pick("Hey, who turned out the lights?","Error: Visual sensor impaired!","Whoa hey, what's the big deal?","Where did everyone go?"))

			if (escape_counter-- > 0)
				flick("robuddy-ghostfumble", master)
				master.visible_message("<span style=\"color:red\">[master] fumbles around in the sheet!</span>")
			else
				master.visible_message("[master] cuts a hole in the sheet!")
				master.speak(pick("Problem solved.","Oh, alright","There we go!"))
				master.bedsheet = 2
				master.overlays.len = 0
				master.hat_shown = 0
				master.update_icon()
				master.remove_current_task()
				return

	threat_scan
		name = "threatscan"
		task_id = "SCAN"
		var/weapon_access = access_carrypermit

		task_act()
			if (..())
				return

			var/mob/living/newThreat = look_for_threat()
			if (istype(newThreat))
				master.scratchpad["threat"] = newThreat
				master.scratchpad["threat_time"] = "[time2text(world.timeofday, "hh:mm:ss")]"

				master.remove_current_task()
				return

			return

		proc
			look_for_threat()
				for (var/mob/living/carbon/C in view(7,master)) //Let's find us a criminal
					if ((C.stat) || (C.handcuffed))
						continue

					var/threat = 0
					if (ishuman(C))
						threat = assess_threat_potential(C)
				//	else
				//		if (isalien(C))
				//			threat = 9

					if (threat >= 4)
						master.scratchpad["threat_level"] = threat
						return C

				return null

			assess_threat_potential(mob/living/carbon/human/potentialThreat as mob)
				var/threatcount = 0


				var/obj/item/card/id/worn_id = potentialThreat.equipped()
				if (!istype(worn_id))
					worn_id = potentialThreat.wear_id

				if (worn_id)
					if (weapon_access in worn_id.access)
						return FALSE

				if (istype(potentialThreat.l_hand, /obj/item/gun) || istype(potentialThreat.l_hand, /obj/item/baton) || istype(potentialThreat.l_hand, /obj/item/sword))
					threatcount += 4

				if (istype(potentialThreat.r_hand, /obj/item/gun) || istype(potentialThreat.r_hand, /obj/item/baton) || istype(potentialThreat.r_hand, /obj/item/sword))
					threatcount += 4

				if (ishuman(potentialThreat))
					if (istype(potentialThreat:belt, /obj/item/gun) || istype(potentialThreat:belt, /obj/item/baton) || istype(potentialThreat:belt, /obj/item/sword))
						threatcount += 2

					if (istype(potentialThreat:wear_suit, /obj/item/clothing/suit/wizrobe))
						threatcount += 4

					if (potentialThreat.mutantrace)
						return 5

				return threatcount

/*
 *	Guardbot Parts
 */

/obj/item/guardbot_core
	name = "Guardbuddy mainboard"
	desc = "The primary circuitry of a PR-6S Guardbuddy."
	icon = 'icons/obj/aibots.dmi'
	icon_state = "robuddy_core-6"
	mats = 6
	w_class = 2.0
	var/created_default_task = null //Default task path of result
	var/computer/file/guardbot_task/created_model_task = null
	var/created_name = "Guardbuddy" //Name of resulting guardbot
	var/buddy_model = 6 //What type of guardbot does this belong to (Default is PR-6, but Murray and Marty are PR-4s)

	attackby(obj/item/W as obj, mob/user as mob)
		if (istype(W, /obj/item/pen))
			if (created_name != initial(created_name))
				boutput(user, "<span style=\"color:red\">This robot has already been named!</span>")
				return

			var/t = input(user, "Enter new robot name", name, created_name) as text
			t = copytext(html_encode(t), 1, MAX_MESSAGE_LEN)
			if (!t)
				return
			if (!in_range(src, usr) && loc != usr)
				return

			created_name = t
		else
			..()

/obj/item/guardbot_frame
	name = "Guardbuddy frame"
	desc = "The external casing of a PR-6S Guardbuddy."
	icon = 'icons/obj/aibots.dmi'
	icon_state = "robuddy_frame-6-1"
	mats = 5
	var/stage = 1
	var/created_name = "Guardbuddy" //Still the name of resulting guardbot
	var/created_default_task = null //Default task path of result
	var/computer/file/guardbot_task/created_model_task = null //Initial model task of result.
	var/obj/created_module = null //Tool module of result.
	var/obj/item/cell/created_cell = null //Energy cell of result.
	var/buddy_model = 6 //What type of guardbot does this belong to (Default is PR-6, but Murray and Marty are PR-4s)
	var/spawned_bot_type = /obj/machinery/bot/guardbot

	New()
		..()
		spawn (6)
			icon_state = "robuddy_frame-[buddy_model]-[stage]"
			if (stage >= 2)
				created_cell = new
				created_cell.charge = 0.9 * created_cell.maxcharge
		return


	//Frame -> Add cell -> Add tool -> Add core -> Add arm -> Done
	attackby(obj/item/W as obj, mob/user as mob)
		if ((istype(W, /obj/item/guardbot_core)))
			if (W:buddy_model != buddy_model)
				boutput(user, "<span style=\"color:red\">That core board is for a different model of robot!</span>")
				return
			if (!created_cell || stage != 2)
				boutput(user, "<span style=\"color:red\">You need to add a power cell first!</span>")
				return
			if (!created_module)
				boutput(user, "<span style=\"color:red\">You need to add a tool module first!</span>")
				return
			stage = 3
			icon_state = "robuddy_frame-[buddy_model]-3"
			if (W:created_name)
				created_name = W:created_name
			if (W:created_default_task)
				created_default_task = W:created_default_task
			if (W:created_model_task)
				created_model_task = W:created_model_task
			boutput(user, "You add the core board to  [src]!")
			qdel(W)

		else if ((istype(W, /obj/item/cell)) && stage == 1 && !created_cell)
			user.drop_item()

			W.set_loc(src)
			created_cell = W
			stage = 2
			icon_state = "robuddy_frame-[buddy_model]-2"
			boutput(user, "You add the power cell to [src]!")

		else if ((istype(W, /obj/item/device/guardbot_tool)) && stage == 2 && !created_module)
			user.drop_item()

			W.set_loc(src)
			created_module = W
			boutput(user, "You add the [W.name] to [src]!")

		else if (istype(W, /obj/item/parts/robot_parts/arm) && stage == 3)
			stage++
			boutput(user, "You add the robot arm to [src]!")
			qdel(W)

			var/obj/machinery/bot/guardbot/newbot = new spawned_bot_type (get_turf(src))
			if (newbot.cell)
				qdel(newbot.cell)
			newbot.cell = created_cell
			newbot.setup_default_tool_path = null
			newbot.cell.set_loc(newbot)

			if (created_default_task)
				newbot.setup_default_startup_task = created_default_task

			if (created_module)
				newbot.tool = created_module
				newbot.tool.set_loc(newbot)
				newbot.tool.master = newbot

			if (created_model_task)
				newbot.model_task = created_model_task
				newbot.model_task.master = newbot
			newbot.name = created_name

			qdel(src)
			return

		else
			..()
		return


//The Docking Station.  Recharge here!
/obj/machinery/guardbot_dock
	name = "docking station"
	desc = "A recharging and command station for PR-6S Guardbuddies."
	icon = 'icons/obj/aibots.dmi'
	icon_state = "robuddycharger0"
	mats = 8
	anchored = 1
	var/panel_open = 0
	var/autoeject = 0 //1: Eject fully charged robots automatically. 2: Eject robot when living carbon mob is in view.
	var/frequency = 1219
	var/net_id = null //What is our network id???
	var/net_number = 0
	var/host_id = null //Who is linked to us?
	var/timeout = 45
	var/timeout_alert = 0
	var/obj/machinery/bot/guardbot/current = null
	var/radio_frequency/radio_connection
	var/obj/machinery/power/data_terminal/data_link = null

	//A reset button is useful for when the system gets all confused.
	var/last_reset = 0 //Last world.time we were manually reset.

	New()
		..()
		spawn (8)
			if (radio_controller)
				radio_connection = radio_controller.add_object(src, "[frequency]")
			if (!net_id)
				net_id = generate_net_id(src)
			if (!data_link)
				var/turf/T = get_turf(src)
				var/obj/machinery/power/data_terminal/test_link = locate() in T
				if (test_link && !test_link.is_valid_master(test_link.master))
					data_link = test_link
					data_link.master = src

		return


	attack_hand(mob/user as mob)
		if (..() || stat & NOPOWER)
			return

		user.machine = src

		var/dat = "<html><head><title>PR-6S Docking Station</title></head><body>"

		var/readout_color = "#000000"
		var/readout = "ERROR"
		if (src.host_id)
			readout_color = "#33FF00"
			readout = "OK CONNECTION"
		else
			readout_color = "#F80000"
			readout = "NO CONNECTION"

		dat += "Host Connection: "
		dat += "<table border='1' style='background-color:[readout_color]'><tr><td><font color=white>[readout]</font></td></tr></table><br>"

		dat += "<a href='?src=\ref[src];reset=1'>Reset Connection</a><br>"

		if (panel_open)
			dat += "<br>Configuration Switches:<br><table border='1' style='background-color:#7A7A7A'><tr>"
			for (var/i = 8, i >= 1, i >>= 1)
				var/styleColor = (net_number & i) ? "#60B54A" : "#CD1818"
				dat += "<td style='background-color:[styleColor]'><a href='?src=\ref[src];dipsw=[i]' style='color:[styleColor]'>##</a></td>"

			dat += "</tr></table>"

		user << browse(dat,"window=guarddock;size=245x282")
		onclose(user,"guarddock")
		return

	Topic(href, href_list)
		if (..())
			return

		usr.machine = src

		if (href_list["reset"])
			if (last_reset && (last_reset + GUARDBOT_DOCK_RESET_DELAY >= world.time))
				return

			if (!host_id)
				return

			last_reset = world.time
			var/rem_host = src.host_id
			src.host_id = null
			post_wire_status(rem_host, "command","term_disconnect")
			spawn (5)
				post_wire_status(rem_host, "command","term_connect","device","PNET_PR6_CHARG")

			updateUsrDialog()
			return

		add_fingerprint(usr)
		return

	receive_signal(signal/signal)
		if (stat & NOPOWER)
			return

		if (!signal || signal.encryption || !signal.data["sender"])
			return

		var/target = signal.data["sender"]
		if (signal.transmission_method == TRANSMISSION_WIRE)
			if ((signal.data["address_1"] == "ping") && ((signal.data["net"] == null) || ("[signal.data["net"]]" == "[net_number]")) && target)
				spawn (5) //Send a reply for those curious jerks
					post_wire_status(target, "command", "ping_reply", "device", "PNET_PR6_CHARG", "netid", net_id, "net", net_number)
				return
			if (signal.data["address_1"] != net_id || !target)
				return

			var/sigcommand = lowertext(signal.data["command"])
			if (!sigcommand || !signal.data["sender"])
				return

			switch(sigcommand)
				if ("term_connect") //Terminal interface stuff.
					if (target == src.host_id)
						src.host_id = null
						post_wire_status(target, "command","term_disconnect")
						return

					timeout = initial(timeout)
					timeout_alert = 0
					src.host_id = target
					if (signal.data["data"] != "noreply")
						post_wire_status(target, "command","term_connect","data","noreply","device","PNET_PR6_CHARG")
					spawn (2) //Sign up with the driver (if a mainframe contacted us)
						post_wire_status(target,"command","term_message","data","command=register&status=[current ? current.net_id : "nobot"]")
					updateUsrDialog()
					return

				if ("term_message","term_file")
					if (target != src.host_id) //Huh, who is this?
						return

					var/list/data = params2list(signal.data["data"])
					if (!data)
						return
					switch(data["command"])
						if ("status") //Status of connected bot.
							var/status = "command=reply"
							if (!current)
								status += "&status=nobot"
							else
								status += "&status=[current.net_id]"
								var/botcharge = null
								if (current.cell)
									botcharge = "[round((current.cell.charge/current.cell.maxcharge)*100)]"
								else
									botcharge = "nocell"
								status += "&charge=[botcharge]"

								var/bottool = null
								if (current.tool)
									bottool = current.tool.tool_id
								else
									bottool = "NONE"
								status += "&tool=[bottool]"

								if (current.model_task)
									status += "&deftask=[current.model_task.task_id]"
								else
									status += "&deftask=NONE"

								if (current.task)
									status += "&curtask=[current.task.task_id]"
								else
									status += "&curtask=NONE"

								//status += "&botid=[current.net_id]"

							post_wire_status(target,"command","term_message","data",status)

							return

						if ("eject") //Eject current bot
							if (!current)
								post_wire_status(target,"command","term_message","data","command=status&status=nobot")
								return

							eject_robot() //eject_robot alerts the host on its own
							return

						if ("upload")
							if (!current)
								post_wire_status(target,"command","term_message","data","command=status&status=nobot")
								return
							var/computer/file/guardbot_task/newtask = signal.data_file
							if (!istype(newtask))
								post_wire_status(target,"command","term_message","data","command=status&status=badtask")
								return

							newtask = newtask.copy_file() //Original one will be deleted with the signal.
							//Clear other tasks?
							var/overwrite = text2num(data["overwrite"])
							if (isnull(overwrite))
								overwrite = 0

							//Replace model (default task)?
							var/model = text2num(data["newmodel"])
							if (isnull(model))
								model = 0

							var/result = upload_task(newtask, overwrite, model)
							if (result)
								post_wire_status(target,"command","term_message","data","command=status&status=upload_success")
							else
								post_wire_status(target,"command","term_message","data","command=status&status=badtask")
								qdel(newtask)
							return

						if ("download")
							if (!current)
								post_wire_status(target,"command","term_message","data","command=status&status=nobot")
								return

							var/computer/file/guardbot_task/task_copy
							if (text2num(data["model"]) != null)
								if (current.model_task)
									task_copy = current.model_task.copy_file()
							else
								if (current.task)
									task_copy = current.task.copy_file()

							if (task_copy)
								var/signal/newsignal = get_free_signal()
								newsignal.source = src
								newsignal.transmission_method = TRANSMISSION_WIRE
								newsignal.data = list("address_1" = target, "command"="term_file", "data", "command=taskfile", "sender" = net_id)

								newsignal.data_file = task_copy

								spawn (2)
									data_link.post_signal(src, newsignal)

							else
								post_wire_status(target, "command", "term_message", "data", "command=status&status=notask")

							return

						if ("taskinq") //Task inquiry.
							if (!current)
								post_wire_status(target,"command","term_message","data","command=status&status=nobot")
								return

							var/task_reply = "command=trep"
							if (current.model_task)
								task_reply += "&deftask=[current.model_task.task_id]"
							else
								task_reply += "&deftask=NONE"

							if (current.task)
								task_reply += "&curtask=[current.task.task_id]"
							else
								task_reply += "&curtask=NONE"

							post_wire_status(target,"command","term_message","data",task_reply)
							return

						if ("wipe") //Clear tasks of current bot
							if (!current)
								post_wire_status(target,"command","term_message","data","command=status&status=nobot")
								return

							current.add_task(null, 0, 1) //No new task, normal priority, wipe all others.
							if (current.model_task)
								qdel(current.model_task)
							if (current.task)
								qdel(current.task)
							post_wire_status(target,"command","term_message","data","command=status&status=wipe_success")
							return

					return

				if ("term_ping")
					if (target != src.host_id)
						return
					if (signal.data["data"] == "reply")
						post_wire_status(target, "command","term_ping")
					timeout = initial(timeout)
					timeout_alert = 0
					return

				if ("term_disconnect")
					if (target == src.host_id)
						src.host_id = null
					timeout = initial(timeout)
					timeout_alert = 0
					return


			return
		else
			if ( (signal.data["address_1"] == "recharge") && !current)
				var/turf/T = get_turf(src)
				if (!T) return

				var/to_send = signal.data["sender"]
				spawn (rand(4,6)) //So robots don't swarm one of the stations.
					post_status(to_send, "command","recharge_src", "data", "x=[T.x]&y=[T.y]")

		return

	MouseDrop_T(obj/O as obj, mob/user as mob)
		if (user.stat || get_dist(user,src)>1)
			return
		if (istype(O, /obj/machinery/bot/guardbot) && !current && !O:charge_dock)
			if (O.loc != loc) return
			connect_robot(O)
			user.visible_message("[user] plugs [O] into the docking station!","You plug [O] into the docking station!")
			//if (!O:idle)
			//	O:snooze()


		return

	process()
		if (current)
			if ((stat & NOPOWER) || !current.cell || (current.loc != loc))
				eject_robot()
				return

			current.cell.give(200 + (current.cell.percent() < 25) ? 50 : 0)
			use_power(275)
			icon_state = "robuddycharger1"

			if ((autoeject == 1) && (current.cell.charge >= current.cell.maxcharge) )
				eject_robot()
			else if ((autoeject == 2) && (current.cell.charge >= current.cell.maxcharge) )
				for (var/mob/living/carbon/M in view(7, src))
					if (M.stat) continue
					eject_robot()
					break


		if (src.host_id)

			if (timeout == 0)
				post_wire_status(host_id, "command","term_disconnect","data","timeout")
				src.host_id = null
				updateUsrDialog()
				timeout = initial(timeout)
				timeout_alert = 0
			else
				timeout--
				if (timeout <= 5 && !timeout_alert)
					timeout_alert = 1
					src.post_wire_status(src.host_id, "command","term_ping","data","reply")


		return

	attackby(obj/item/W as obj, mob/user as mob)
		if (istype(W, /obj/item/screwdriver))
			playsound(loc, "sound/items/Screwdriver.ogg", 50, 1)
			boutput(user, "You [panel_open ? "secure" : "unscrew"] the maintenance panel.")
			panel_open = !panel_open
			updateUsrDialog()
			return
		else
			..()
		return

	disposing()
		if (current)
			current.wakeup()
		current = null
		if (radio_controller)
			radio_controller.remove_object(src, "[frequency]")
		radio_connection = null
		if (data_link)
			data_link.master = null
			data_link = null

		..()
		return

	proc
		eject_robot()
			if (!current) return
			autoeject = 0
			icon_state = "robuddycharger0"
			current.charge_dock = null
			current.last_dock_id = net_id
			current.wakeup()
			if (src.host_id) //Alert system host of this development!!
				src.post_wire_status(src.host_id,"command","term_message","data","command=status&status=ejected&botid=[current.net_id]")
			current = null
			return

		connect_robot(obj/machinery/bot/guardbot/robot,aeject=0)
			if (!istype(robot))
				return FALSE

			current = robot
			robot.charge_dock = src
			autoeject = aeject
			if (!robot.idle)
				robot.snooze()
			if (src.host_id)
				src.post_wire_status(src.host_id,"command","term_message","data","command=status&status=connect&botid=[current.net_id]")

			return TRUE

		upload_task(var/computer/file/guardbot_task/task, clear_others=0, new_model=0)
			if (!current || !current.on || !istype(task))
				return FALSE

			if (new_model)
				if (current.model_task)
					qdel(current.model_task)
				var/computer/file/guardbot_task/model = task.copy_file()
				model.master = current
				current.model_task = model

			current.add_task(task, 0, clear_others)
			if (!current.task)
				current.task = task

			return TRUE

		post_status(var/target_id, var/key, var/value, var/key2, var/value2, var/key3, var/value3)
			if (!radio_connection)
				return

			var/signal/signal = get_free_signal()
			signal.source = src
			signal.transmission_method = TRANSMISSION_RADIO
			signal.data[key] = value
			if (key2)
				signal.data[key2] = value2
			if (key3)
				signal.data[key3] = value3

			if (target_id)
				signal.data["address_1"] = target_id
			signal.data["sender"] = net_id

			radio_connection.post_signal(src, signal, GUARDBOT_RADIO_RANGE)

		post_wire_status(var/target_id, var/key, var/value, var/key2, var/value2, var/key3, var/value3)
			if (!data_link || !target_id)
				return

			var/signal/signal = get_free_signal()
			signal.source = src
			signal.transmission_method = TRANSMISSION_WIRE
			signal.data[key] = value
			if (key2)
				signal.data[key2] = value2
			if (key3)
				signal.data[key3] = value3

			signal.data["address_1"] = target_id
			signal.data["sender"] = net_id

			spawn (2)
				data_link.post_signal(src, signal)

/obj/machinery/computer/tour_console
	name = "Tour Console"
	desc = "A computer console, presumably one relating to tours."
	icon_state = "old2"
	pixel_y = 8
	var/obj/machinery/bot/guardbot/linked_bot = null

	New()
		..()
		spawn (8)
			linked_bot = locate() in orange(1, src)

	attack_ai(mob/user as mob)
		return attack_hand(user)

	attack_hand(mob/user as mob)
		if (..() || (stat & (NOPOWER|BROKEN)))
			return

		user.machine = src
		add_fingerprint(user)

		var/dat = "<center><h4>Tour Monitor</h4></center>"
		if (!linked_bot)
			dat += "<font color=red>No tour guide detected!</font>"
		else
			dat += "<strong>Guide:</strong> <center>\[[linked_bot.name]]</center><br>"

			if ((linked_bot in orange(1, src)) && linked_bot.charge_dock)
				dat += "<center><a href='?src=\ref[src];start_tour=1'>Begin Tour</a></center>"

			else
				var/area/guideArea = get_area(linked_bot)
				dat += "<strong>Current Location:</strong> [istype(guideArea) ? guideArea.name : "<font color=red>Unknown</font>"]"


		user << browse("<head><title>Tour Monitor</title></head>[dat]", "window=tourconsole;size=302x245")
		onclose(user, "tourconsole")
		return

	Topic(href, href_list)
		if (..())
			return
		usr.machine = src
		add_fingerprint(usr)

		if (href_list["start_tour"] && linked_bot && (linked_bot in orange(1, src)) && linked_bot.charge_dock)
			linked_bot.charge_dock.eject_robot()

		updateUsrDialog()
		return

/obj/machinery/bot/guardbot/old
	name = "Robuddy"
	desc = "A PR-4 Robuddy. That's two models back by now! You didn't know any of these were still around."
	icon = 'icons/misc/oldbots.dmi'

	setup_no_costumes = 1
	no_camera = 1
	setup_charge_maximum = 800
	setup_default_tool_path = /obj/item/device/guardbot_tool/flash

	speak(var/message)
		return ..("<font face=Consolas>[uppertext(message)]</font>")

	interact(mob/user as mob)
		var/dat = "<tt><strong>PR-4 Robuddy v0.8</strong></tt><br><br>"

		var/power_readout = null
		var/readout_color = "#000000"
		if (!cell)
			power_readout = "NO CELL"
		else
			var/charge_percentage = round((cell.charge/cell.maxcharge)*100)
			power_readout = "[charge_percentage]%"
			switch(charge_percentage)
				if (0 to 10)
					readout_color = "#F80000"
				if (11 to 25)
					readout_color = "#FFCC00"
				if (26 to 50)
					readout_color = "#CCFF00"
				if (51 to 75)
					readout_color = "#33CC00"
				if (76 to 100)
					readout_color = "#33FF00"


		dat += {"Power: <table border='1' style='background-color:[readout_color]'>
				<tr><td><font color=white>[power_readout]</font></td></tr></table><br>"}

		dat += "Current Tool: [src.tool ? src.tool.tool_id : "NONE"]<br>"

		if (locked)

			dat += "Status: [on ? "On" : "Off"]<br>"

		else

			dat += "Status: <a href='?src=\ref[src];power=1'>[on ? "On" : "Off"]</a><br>"

		dat += "<br>Network ID: <strong>\[[uppertext(net_id)]]</strong><br>"

		user << browse("<head><title>Robuddy v0.8 controls</title></head>[dat]", "window=guardbot")
		onclose(user, "guardbot")
		return

	explode()
		if (exploding) return
		exploding = 1
		var/death_message = pick("It is now safe to shut off your buddy.","I regret nothing, but I am sorry I am about to leave my friends.","Malfunction!","I had a good run.","Es lebe die Freiheit!","Life was worth living.","Time to die...")
		speak(death_message)
		visible_message("<span style=\"color:red\"><strong>[src] blows apart!</strong></span>")
		var/turf/T = get_turf(src)
		if (mover)
			mover.master = null
			qdel(mover)

		invisibility = 100
		var/obj/overlay/Ov = new/obj/overlay(T)
		Ov.anchored = 1
		Ov.name = "Explosion"
		Ov.layer = NOLIGHT_EFFECTS_LAYER_BASE
		Ov.pixel_x = -17
		Ov.icon = 'icons/effects/hugeexplosion.dmi'
		Ov.icon_state = "explosion"

		tool.set_loc(get_turf(src))

		var/obj/item/guardbot_core/old/core = new /obj/item/guardbot_core/old(T)
		core.created_name = name
		core.created_default_task = setup_default_startup_task
		core.created_model_task = model_task

		var/list/throwparts = list()
		throwparts += new /obj/item/parts/robot_parts/arm/left(T)
		throwparts += new /obj/item/device/flash(T)
		throwparts += core
		throwparts += tool
		if (hat)
			throwparts += hat
			hat.set_loc(T)
		throwparts += new /obj/item/guardbot_frame/old(T)
		for (var/obj/O in throwparts) //This is why it is called "throwparts"
			var/edge = get_edge_target_turf(src, pick(alldirs))
			O.throw_at(edge, 100, 4)

		spawn (0) //Delete the overlay when finished with it.
			on = 0
			sleep(15)
			qdel(Ov)
			qdel(src)

		T.hotspot_expose(800,125)
		explosion(src, T, -1, -1, 2, 3)

		return

/obj/item/guardbot_frame/old
	name = "Robuddy frame"
	desc = "The external casing of a PR-4 Robuddy."
	icon_state = "robuddy_frame-4-1"
	spawned_bot_type = /obj/machinery/bot/guardbot/old
	buddy_model = 4

/obj/item/guardbot_core/old
	name = "Robuddy mainboard"
	desc = "The primary circuitry of a PR-4 Robuddy."
	icon_state = "robuddy_core-4"
	buddy_model = 4

//A tourguide for "the crunch"
/obj/machinery/bot/guardbot/old/tourguide
	name = "Marty"
	desc = "A PR-4 Robuddy. These are pretty old, you didn't know there were any still around!  This one has a little name tag on the front labeled 'Marty'"
	setup_default_startup_task = /computer/file/guardbot_task/tourguide
	no_camera = 1
	setup_charge_maximum = 3000
	setup_charge_percentage = 100
	flashlight_lum = 4

	New()
		..()
		hat = new /obj/item/clothing/head/safari(src)
		//hat = new /obj/item/clothing/head/helmet/space/santahat(src)
		update_icon()

/obj/machinery/computer/hug_console
	name = "Hug Console"
	desc = "A hug console? It has a small opening on the top."
	icon = 'icons/obj/stationobjs.dmi'
	icon_state = "holo_console0"


	attackby(obj/item/W as obj, mob/user as mob)
		if (istype(W, /obj/item/token/hug_token))
			user.visible_message("<span style=\"color:red\"><strong>[user]</strong> inserts a [W] into the [src].</span>", "<span style=\"color:red\">You insert a [W] into the [src].</span>")
			qdel(W)

			for (var/obj/machinery/bot/guardbot/buddy in machines)
				if (buddy.z != 1) continue
				if (buddy.charge_dock)
					buddy.charge_dock.eject_robot()
				else if (buddy.idle)
					buddy.wakeup()
				buddy.add_task(/computer/file/guardbot_task/recharge/dock_sync, 1, 0)
				var/computer/file/guardbot_task/security/single_use/tohug = new
				tohug.hug_target = user
				buddy.add_task(tohug, 1, 0)
				buddy.navigate_to(get_turf(user))

/obj/item/token/hug_token
	name = "Hug Token"
	desc = "A Hug Token. Just looking at it makes you feel better."
	icon = 'icons/obj/items.dmi'
	icon_state = "coin"
	item_state = "coin"
	w_class = 1.0

	attack_self(var/mob/user as mob)
		playsound(loc, "sound/misc/coindrop.ogg", 100, 1)
		user.visible_message("<strong>[user]</strong> flips the token","You flip the token")
		spawn (10)
		user.visible_message("It came up Hugs.")

#undef GUARDBOT_DOCK_RESET_DELAY
#undef GUARDBOT_LOWPOWER_ALERT_LEVEL
#undef GUARDBOT_LOWPOWER_IDLE_LEVEL
#undef GUARDBOT_POWER_DRAW
#undef GUARDBOT_RADIO_RANGE