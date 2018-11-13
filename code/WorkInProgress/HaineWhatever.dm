// hey look at me I'm changing a file

/* ._.-'~'-._.-'~'-._.-'~'-._.-'~'-._.-'~'-._.-'~'-._.-'~'-._. */
/*-=-=-=-=-=-=-=-=-=-=-=-=-ADMIN-STUFF-=-=-=-=-=-=-=-=-=-=-=-=-*/
/* '~'-._.-'~'-._.-'~'-._.-'~'-._.-'~'-._.-'~'-._.-'~'-._.-'~' */

/atom/proc/add_star_effect(var/remove = 0)
	if (remove)
		if (particleMaster.CheckSystemExists(/particleSystem/warp_star, src))
			particleMaster.RemoveSystem(/particleSystem/warp_star, src)
	else if (!particleMaster.CheckSystemExists(/particleSystem/warp_star, src))
		particleMaster.SpawnSystem(new /particleSystem/warp_star(src))

/proc/toggle_clones_for_cash()
	if (!wagesystem)
		return
	wagesystem.clones_for_cash = !(wagesystem.clones_for_cash)
	logTheThing("admin", usr, null, "toggled monetized cloning [wagesystem.clones_for_cash ? "on" : "off"].")
	logTheThing("diary", usr, null, "toggled monetized cloning [wagesystem.clones_for_cash ? "on" : "off"].", "admin")
	message_admins("[key_name(usr)] toggled monetized cloning [wagesystem.clones_for_cash ? "on" : "off"]")
	boutput(world, "<strong>Cloning now [wagesystem.clones_for_cash ? "requires" : "does not require"] money.</strong>")

/area/haine_party_palace
	name = "haine's rad hangout place"
	icon_state = "purple"
	requires_power = 0
	sound_environment = 4

var/global/debug_messages = 0
var/global/narrator_mode = 0
var/global/disable_next_click = 0

/client/proc/toggle_next_click()
	set name = "Toggle next_click"
	set desc = "Removes most click delay. Don't know what this is? Probably shouldn't touch it."
	set category = "Toggles (Server)"
	ADMIN_CHECK(src)

	disable_next_click = !(disable_next_click)
	logTheThing("admin", usr, null, "toggled next_click [disable_next_click ? "off" : "on"].")
	logTheThing("diary", usr, null, "toggled next_click [disable_next_click ? "off" : "on"].", "admin")
	message_admins("[key_name(usr)] toggled next_click [disable_next_click ? "off" : "on"]")

/client/proc/debug_messages()
	set desc = "Toggle debug messages."
	set name = "HDM" // debug ur haines
	set hidden = 1
	ADMIN_CHECK(src)

	debug_messages = !(debug_messages)
	logTheThing("admin", usr, null, "toggled debug messages [debug_messages ? "on" : "off"].")
	logTheThing("diary", usr, null, "toggled debug messages [debug_messages ? "on" : "off"].", "admin")
	message_admins("[key_name(usr)] toggled debug messages [debug_messages ? "on" : "off"]")

/client/proc/narrator_mode()
	set name = "Narrator Mode"
	set desc = "Toggle narrator mode on or off."
	ADMIN_CHECK(src)

	narrator_mode = !(narrator_mode)

	logTheThing("admin", usr, null, "toggled narrator mode [narrator_mode ? "on" : "off"].")
	logTheThing("diary", usr, null, "toggled narrator mode [narrator_mode ? "on" : "off"].", "admin")
	message_admins("[key_name(usr)] toggled narrator mode [narrator_mode ? "on" : "off"]")

/* ._.-'~'-._.-'~'-._.-'~'-._.-'~'-._.-'~'-._.-'~'-._.-'~'-._. */
/*-=-=-=-=-=-=-=-=-=-=-=-=-GHOST-DRONE-=-=-=-=-=-=-=-=-=-=-=-=-*/
/* '~'-._.-'~'-._.-'~'-._.-'~'-._.-'~'-._.-'~'-._.-'~'-._.-'~' */

/obj/machinery/ghost_catcher
	name = "ghost catcher"
	desc = "it catches ghosts!! read the name gosh I shouldn't have to explain everything to you"
	anchored = 1
	density = 1
	icon = 'icons/mob/ghost_drone.dmi'
	icon_state = "ghostcatcher0"
	mats = 0
	var/id = "ghostdrone"

	Crossed(atom/movable/O)
		if (!istype(O, /mob/dead/observer))
			return ..()
		var/mob/dead/observer/G = O
		if (available_ghostdrones.len)
			G.visible_message("[src] scoops up [G]!",\
			"You feel yourself being torn away from the afterlife and into [src]!")
			droneize(G, 1)
		else
			G.show_text("There are currently no empty drones available for use, please wait for another to be built.", "red")
			return ..()

	process()
		..()
		if (available_ghostdrones.len)
			icon_state = "ghostcatcher1"
			var/list/ghost_candidates = list()
			for (var/mob/dead/observer/O in get_turf(src))
				if (assess_ghostdrone_eligibility(O))
					ghost_candidates += O
			if (ghost_candidates.len)
				var/mob/dead/observer/O = pick(ghost_candidates)
				if (O)
					O.visible_message("[src] scoops up [O]!",\
					"You feel yourself being torn away from the afterlife and into [src]!")
					droneize(O, 1)
		else
			icon_state = "ghostcatcher0"

/proc/assess_ghostdrone_eligibility(var/mob/dead/observer/G)
	if (!istype(G))
		return FALSE
	if (!G.client)
		return FALSE
	if (G.mind && G.mind.dnr)
		return FALSE
	return TRUE

#define GHOSTDRONE_BUILD_INTERVAL 3000
var/global/ghostdrone_factory_working = 0
var/global/last_ghostdrone_build_time = 0
var/global/list/available_ghostdrones = list()

/obj/machinery/ghostdrone_factory
	name = "drone factory"
	desc = "A slightly mysterious looking factory that spits out weird looking drones every so often. Why not."
	anchored = 1
	density = 0
	icon = 'icons/mob/ghost_drone.dmi'
	icon_state = "factory10"
	layer = 5 // above mobs hopefully
	mats = 0
	var/factory_section = 1 // can be 1 to 3
	var/id = "ghostdrone" // the belts through the factory should be set to the same as the factory pieces so they can control them
	var/obj/item/ghostdrone_assembly/current_assembly = null
	var/list/conveyors = list()
	var/working = 0 // are we currently doing something to a drone piece?
	var/work_time = 50 // how long do_work()'s animation and sound effect loop runs
	var/worked_time = 0 // how long the current work cycle has run

	New()
		..()
		icon_state = "factory[factory_section][working]"
		spawn (10)
			update_conveyors()

	proc/update_conveyors()
		if (conveyors.len)
			for (var/obj/machinery/conveyor/C in conveyors)
				if (C.id != id)
					conveyors -= C
		for (var/obj/machinery/conveyor/C in machines)
			if (C.id == id)
				if (C in conveyors)
					continue
				conveyors += C

	disposing()
		..()
		if (current_assembly)
			pool(current_assembly)
		if (conveyors.len)
			conveyors.len = 0

	Cross(atom/movable/O)
		if (!istype(O, /obj/item/ghostdrone_assembly))
			return ..()
		if (current_assembly) // we're full
			return FALSE // thou shall not pass
		else // we're not full
			return TRUE // thou shall pass

	Crossed(atom/movable/O)
		if (factory_section == 1 || !istype(O, /obj/item/ghostdrone_assembly))
			return ..()
		var/obj/item/ghostdrone_assembly/G = O
		if (G.stage != (factory_section - 1) || current_assembly)
			return ..()
		start_work(G)

	process()
		..()
		if (working && current_assembly)
			worked_time ++
			if (work_time - worked_time <= 0)
				stop_work()
				return

			if (prob(40))
				shake(rand(4,6))
				playsound(get_turf(src), pick("sound/effects/zhit.ogg", "sound/effects/bang.ogg"), 30, 1, -3)
			if (prob(40))
				var/list/sound_list = pick(ghostly_sounds, sounds_engine, sounds_enginegrump, sounds_sparks)
				if (!sound_list.len)
					return
				var/chosen_sound = pick(sound_list)
				if (!chosen_sound)
					return
				playsound(get_turf(src), chosen_sound, rand(20,40), 1)

		else if (!ghostdrone_factory_working)
			if (factory_section == 1)
				if (!ticker) // game ain't started
					return
				if (world.timeofday >= (last_ghostdrone_build_time + GHOSTDRONE_BUILD_INTERVAL))
					start_work()
			else
				var/obj/item/ghostdrone_assembly/G = locate() in get_turf(src)
				if (G && G.stage == (factory_section - 1))
					start_work(G)

	proc/start_work(var/obj/item/ghostdrone_assembly/G)
		var/emptySpot = 0
		for (var/obj/machinery/drone_recharger/factory/C in machines)
			if (!C.occupant)
				emptySpot = 1
				break
		if (!emptySpot)
			return

		if (G && !current_assembly && G.stage == (factory_section - 1))
			visible_message("[src] scoops up [G]!")
			G.set_loc(src)
			current_assembly = G
			working = 1
			icon_state = "factory[factory_section]1"

		else if (factory_section == 1 && !ghostdrone_factory_working && !current_assembly)
			current_assembly = unpool(/obj/item/ghostdrone_assembly)
			if (!current_assembly)
				current_assembly = new(src)
			current_assembly.set_loc(src)
			ghostdrone_factory_working = current_assembly // if something happens to the assembly, for whatever, reason this should become null, I guess?
			working = 1
			icon_state = "factory[factory_section]1"
			last_ghostdrone_build_time = world.timeofday

		if (!current_assembly)
			working = 0
			icon_state = "factory[factory_section]0"
			return

		for (var/obj/machinery/conveyor/C in conveyors)
			C.operating = 0
			C.setdir()

	proc/stop_work()
		worked_time = 0
		working = 0
		icon_state = "factory[factory_section]0"

		if (current_assembly)
			current_assembly.stage = factory_section
			current_assembly.icon_state = "drone-stage[factory_section]"
			current_assembly.set_loc(get_turf(src))
			playsound(get_turf(src), "sound/machines/warning-buzzer.ogg", 50, 1)
			visible_message("[src] ejects [current_assembly]!")
			current_assembly = null

		for (var/obj/machinery/conveyor/C in conveyors)
			C.operating = 1
			C.setdir()

	proc/shake(var/amt = 5)
		var/orig_x = pixel_x
		var/orig_y = pixel_y
		for (amt, amt>0, amt--)
			pixel_x = rand(-2,2)
			pixel_y = rand(-2,2)
			sleep(1)
		pixel_x = orig_x
		pixel_y = orig_y
		return TRUE

/obj/machinery/ghostdrone_factory/part2
	icon_state = "factory20"
	factory_section = 2

/obj/machinery/ghostdrone_factory/part3
	icon_state = "factory30"
	factory_section = 3

/obj/item/ghostdrone_assembly
	name = "drone assembly"
	desc = "an incomplete floaty robot"
	icon = 'icons/mob/ghost_drone.dmi'
	icon_state = "drone-stage1"
	mats = 0
	var/stage = 1

	pooled()
		..()
		if (ghostdrone_factory_working == src)
			ghostdrone_factory_working = 0
		stage = 1

	unpooled()
		..()
		icon_state = "drone-stage[stage]"

/* ._.-'~'-._.-'~'-._.-'~'-._.-'~'-._.-'~'-._.-'~'-._.-'~'-._. */
/*-=-=-=-=-=-=-=-=-=-=-=-=-=-DESTINY-=-=-=-=-=-=-=-=-=-=-=-=-=-*/
/* '~'-._.-'~'-._.-'~'-._.-'~'-._.-'~'-._.-'~'-._.-'~'-._.-'~' */

var/global/list/valid_target_arrival_pads = list()

/proc/get_random_station_turf()
	var/list/areas = get_areas(/area/station)
	if (!areas.len)
		return
	var/area/A = pick(areas)
	if (!A)
		return
	var/list/turfs = get_area_turfs(A, 1)
	if (!turfs.len)
		return
	var/turf/T = pick(turfs)
	if (!T)
		return
	return T

/obj/dummy_pad
	name = "teleport pad"
	icon = 'icons/obj/stationobjs.dmi'
	icon_state = "pad0"
	anchored = 1
	density = 0

	New()
		..()
		valid_target_arrival_pads += src

/obj/arrivals_pad
	name = "teleport pad"
	desc = "Click me to teleport to the station!"
	icon = 'icons/obj/stationobjs.dmi'
	icon_state = "pad0"
	anchored = 1
	density = 0
	var/HTML = null
	var/obj/dummy_pad/target_pad = null
	var/emergency = 0 // turned on if there's nothing in valid_target_arrival_pads or it isn't a list

	Topic(href, href_list[])
		if (..() || !usr)
			return

		if (href_list["set_target"])
			var/obj/dummy_pad/D = locate(href_list["set_target"])
			if (!istype(D))
				return
			target_pad = D
			display_window(usr)
			return

		else if (href_list["teleport"])
			if (usr.loc != get_turf(src))
				boutput(usr, "<span style='color:red'>You have to be standing on [src] to teleport!</span>")
				return
			if (!target_pad && !emergency)
				boutput(usr, "<span style='color:red'>No target specified to teleport to!</span>")
				return
			else if (emergency)
				//teleport to somewhere (hopefully with air?)
				var/turf/T = get_random_station_turf()
				if (!istype(T) || T.z != 1)
					for (var/i=3, i>0, i--)
						T = get_random_station_turf()
						if (istype(T) && T.z == 1)
							break
				if (T)
					if (get_turf(usr) != get_turf(src))
						boutput(usr, "<span style='color:red'>You have to be standing on [src] to teleport!</span>")
						return
					teleport_user(usr, T)
				return
			else if (target_pad && alert(usr, "Teleport to [target_pad.x],[target_pad.y],[target_pad.x] in [get_area(target_pad)]?", "Confirmation", "Yes", "No") == "Yes")
				if (get_turf(usr) != get_turf(src))
					boutput(usr, "<span style='color:red'>You have to be standing on [src] to teleport!</span>")
					return
				teleport_user(usr, get_turf(target_pad))
				return

	proc/teleport_user(var/mob/user, var/turf/target)
		if (!user || !target)
			return
		if (!isturf(target))
			target = get_turf(target)
		showswirl(target)
		leaveresidual(target)
		showswirl(get_turf(src))
		leaveresidual(get_turf(src))
		boutput(usr, "<span style='color:green'>Now teleporting to [target.x],[target.y],[target.x] in [get_area(target)].</span>")
		user.set_loc(target)
		user << browse(null, "window=[src]")
		if (map_setting == "DESTINY")
			if (user.mind && user.mind.assigned_role)
				for (var/obj/machinery/computer/announcement/A in machines)
					if (!A.stat && A.announces_arrivals)
						A.announce_arrival(user.real_name, user.mind.assigned_role)

	proc/generate_html()
		HTML = ""
		if (!islist(valid_target_arrival_pads) || !valid_target_arrival_pads.len)
			emergency = 1
			HTML += "<center><span style='color:red;font-weight:bold'>ERROR: EMERGENCY MODE (No valid targets available)</span></center>"
			HTML += "<center><a href='?src=\ref[src];teleport=1'>\[Emergency Teleport\]</a></center>"
		else
			emergency = 0
			HTML += "<strong>TARGET</strong>:<br>"
			if (target_pad)
				HTML += "[target_pad.x],[target_pad.y],[target_pad.x] in [get_area(target_pad)]<br>"
				HTML += "<strong>Scan Results</strong>:<br>[scan_atmospheric(get_turf(target_pad), 0, 1)]<br>"
				HTML += "<a href='?src=\ref[src];teleport=1'>\[Teleport\]</a><hr>"
			else
				HTML += "<span style='color:red'>No Target Specified</span><hr>"
			HTML += "<strong>Available Targets</strong>:<br>"
			for (var/obj/dummy_pad/D in valid_target_arrival_pads)
				HTML += "<br>[D.x],[D.y],[D.z] in [get_area(D)]: <a href='?src=\ref[src];set_target=\ref[D]'>\[Select\]</a>"

	proc/display_window(var/mob/user)
		if (!user)
			return
		generate_html()
		user << browse(HTML, "window=[src];size=400x480")

	attack_hand(mob/user)
		display_window(user)

	attackby(obj/item/W, mob/user)
		display_window(user)

/client/proc/cmd_rp_rules()
	set name = "RP Rules"
	set category = "Commands"

	Browse( {"<center><h2>44BR13 RP Server Guidelines and Rules - Test Drive Edition</h2></center><hr>
	Welcome to the NSS Destiny! Now, since as this server is intended for roleplay, there are some guidelines, rules and tips to make your time fun for everyone!<hr>
	<ul style='list-style-type:disc'>
		<li>Roleplay and have fun!
			<ul style='list-style-type:circle'>
				<li>Try to have fun with other players too, and try not to be too much of a jerk if you're not a traitor. Accidents may happen, but do not intentionally damage or destroy the station as a non-traitor, the game should be fun for all!</li>
				<li>In the end, we want people to get into character and just try to have fun pretending to be a farty spaceman on a weird ship. This won't be "no silliness allowed" or anything, you don't have to have a believable irl person as a character. Just try to play along with things and have fun interacting and talking to the people around you, create some drama, instead of trying to figure out how to most efficiently win the round, or whatever. If someone is clearly an antag, threatening the ship with a bomb, play along with them instead of trying to immediately beat their face in. Things like that.</li>
			</ul>
		</li>
		<li>If you are a traitor, you make the fun!
			<ul style='list-style-type:circle'>
				<li>Treat your role as an interesting challenge and not an excuse to destroy other peoples' game experience. Your actions should make the game more fun, more exciting and more enjoyable for everyone, don't try to go on a homicidal rampage unless your objectives require you to do so! Try a fun new gimmick, or ask one of the admins!</li>
				<li>You should try to have a plan for something that will be fun for you and your victims. At the very least, interaction between antags and non-antags should be more than a c-saber being applied to the face repeatedly! Some of the objectives already come with added gimmick ideas/suggestions, try using them!</li>
			</ul>
		</li>
		<li>Don't be an awful person.
			<ul style='list-style-type:circle'>
				<li>Hate speech, bigoted language, discrimination, harassment, or sexual content such as, but not limited to ERP and sexual assault will not be tolerated at all and may be considered grounds for immediate banning.</li>
				<li>We're all here to have a good time! Going out of your way to seriously negatively impact or end the round for someone with little to no justification is against the rules. Legitimate conflicts where people get upset do happen however, these conflicts should escalate properly and retribution must be proportionate, roleplaying someone with a mental illness is not a legitimate reason.</li>
			</ul>
		</li>
		<li>Remember that this game relies on trickery, sneakiness, and some suspension of disbelief.
			<ul style='list-style-type:circle'>
				<li>Do not cheat by using multiple accounts or by coordinating with other players through out-of-game communication means</li>
			</ul>
		</li>
		<li>Play out your role believably.
			<ul style='list-style-type:circle'>
				<li>Don't exploit glitches, out-of-character (OOC) knowledge, or knowledge of the game system to give your character advantages that they would not possess otherwise (e.g: a Security Guard probably knows basic first aid, but they wouldn't know how to perform advanced surgery, etc.) you will be expected to try and do your jobs, This won't be so strict that, if a botanist wanders out of hydroponics, they'll get in trouble for being out-of-character, or anything like that. Just that you should be trying to play a character to some degree, and trying to stick to doing what you were presumably on the ship to do.</li>
				<li>Chain-of-command and security are important. The head of your department is your boss and they can fire you, security officers can arrest you for stealing or breaking into places. The preference would be that unless they're doing something unreasonable, such as spacing you for writing on the walls, you shouldn't freak out over being punished for doing something that would, in reality, get you fired or arrested.</li>
				<li><strong><em>When you aren't a traitor, you should respect the chain of command, respect Security, and avoid vigilantism!</em></strong></li>
			</ul>
		</li>
		<li>Keep IC and OOC separate.
			<ul style='list-style-type:circle'>
				<li>Do not use the OOC channel to spoil IC (In character) events, like the identity of a traitor/changeling. Likewise, do not treat IC chat like OOC (saying things like ((this round sucks)) over radio, etc)</li>
			</ul>
		</li>
		<li>Listen to the administrators.
			<ul style='list-style-type:circle'>
				<li>If an admin asks you to explain your actions or asks you to stop doing something, you probably ought to do so. If you think someone is breaking the rules or ruining the game for everyone else somehow, use the <strong>ADMINHELP</strong> verb to give us a shout. If you just want tips on how to play the game, try <strong>MENTORHELP</strong>. Do not log out when an admin is speaking with you.</li>
			</ul>
		</li>
		<li>Real life takes precedence!
			<ul style='list-style-type:circle'>
				<li>If you are the AI or a head position and have to log off, PLEASE adminhelp a quick message. You do not need to wait for a response, but it really helps to know as it can seriously hamstring the station if you just disappear or go AFK.</li>
			</ul>
		</li>
	</ul>"}, "window=rprules;title=RP+Rules;fade_in=1" )

/obj/item/paper/book/space_law
	name = "Space Law"
	desc = "A book explaining the laws of space. Well, this section of space, at least."
	icon_state = "book7"
	info = {"<center><h2>Frontier Justice on the NSS Destiny: A Treatise on Space Law</h2></center>
	<h3>A Brief Summary of Space Law</h3><hr>
	As a Security Officer, the zeroth Space Law that you should probably always obey is to use your common sense. If it is a crime in real life, then it is a crime in this video game. Remember to use your best judgement when arresting criminals, and don't get discouraged if they complain.<br><br>
	For certain crimes, the accused's intent is important. The difference between Assault and Attempted Murder can be very hard to ascertain, and, when in doubt, you should default to the less serious crime. It is important to note though, that Assault and Attempted Murder are mutually exclusive. You cannot be charged with Assault and Attempted Murder from the same crime as the intent of each is different. Likewise, 'Assault With a Deadly Weapon' and 'Assaulting an Officer' are also crimes that exclude others. Pay careful attention to the requirements of each law and select the one that best fits the crime when deciding sentence.<br><br>
	Security roles and their superiors can read the Miranda warning to suspects by using the Recite Miranda Rights verb or *miranda emote. The wording is also customizable via Set Miranda Rights.<br><br>
	Additionally: It is <strong><em>highly illegal</em></strong> for Nanotrasen personnel to make use of Syndicate devices. Do not use traitor gear as a non-traitor, even to apprehend traitors.<hr>
	Here's a guideline for how you should probably treat suspects by each particular crime.
	<h4>Minor Crimes:</h4>
	<em>No suspect may be sentenced for more than five minutes in the Brig for Minor Crimes. Minor Crime sentences are not cumulative (e.g: max five minutes for committing multiple Minor Crimes).</em>
	<ul style='list-style-type:disc'>
		<li>Assault
			<ul style='list-style-type:circle'>
				<li>To use physical force against someone without the apparent intent to kill them.</li>
			</ul>
		</li>
		<li>Theft
			<ul style='list-style-type:circle'>
				<li>To take items from areas one does not have access to or to take items belonging to others or the ship as a whole.</li>
			</ul>
		</li>
		<li>Fraud</li>
		<li>Breaking and Entering
			<ul style='list-style-type:circle'>
				<li>To deliberately damage the ship without malicious intent.</li>
				<li>To be in an area which a person does not have access to. This counts for general areas of the ship, and trespass in restricted areas is a more serious crime.</li>
			</ul>
		</li>
		<li>Resisting Arrest
			<ul style='list-style-type:circle'>
				<li>To not cooperate with an officer who attempts a proper arrest.</li>
			</ul>
		</li>
		<li>Escaping from the Brig
			<ul style='list-style-type:circle'>
				<li>To escape from a brig cell, or custody.</li>
			</ul>
		</li>
		<li>Assisting or Abetting Criminals
			<ul style='list-style-type:circle'>
				<li>To act as, or knowingly aid, an enemy of Nanotrasen.</li>
			</ul>
		</li>
		<li>Drug Possession
			<ul style='list-style-type:circle'>
				<li>To possess space drugs or other narcotics by unauthorized personnel.</li>
			</ul>
		</li>
		<li>Narcotics Distribution
			<ul style='list-style-type:circle'>
				<li>To distribute narcotics and other controlled substances.</li>
			</ul>
		</li>
	</ul>
	<h4>Major Crime:</h4>
	<em>For Major Crimes, a suspect may be sentenced for more than five minutes, but no more than fifteen. Like above, multiple Major Crime sentences are not cumulative.</em><br>
	<ul style='list-style-type:disc'>
		<li>Murder
			<ul style='list-style-type:circle'>
				<li>To maliciously kill someone.</li>
				<li><strong><em>Unauthorised executions are classed as Murder.</em></strong></li>
			</ul>
		</li>
		<li>Manslaughter
			<ul style='list-style-type:circle'>
				<li>To unintentionally kill someone through negligent, but not malicious, actions.</li>
				<li>Intent is important. Accidental deaths caused by negligent actions, such as creating workplace hazards (e.g. gas leaks), tampering with equipment, excessive force, and confinement in unsafe conditions are examples of Manslaughter.</li>
			</ul>
		</li>
		<li>Sabotage
			<ul style='list-style-type:circle'>
				<li>To engage in maliciously destructive actions, seriously threatening crew or ship.</li>
				<li>Bombing, arson, releasing viruses, deliberately exposing areas to space, physically destroying machinery or electrifying doors all count as Grand Sabotage.</li>
			</ul>
		</li>
		<li>Enemy of Nanotrasen
			<ul style='list-style-type:circle'>
				<li>To act as, or knowingly aid, an enemy of Nanotrasen.</li>
			</ul>
		</li>
		<li>Creating a Workplace Hazard
			<ul style='list-style-type:circle'>
				<li>To endanger the crew or ship through negligent or irresponsible, but not deliberately malicious, actions.</li>
				<li>Possession of Explosives</li>
			</ul>
		</li>
	</ul>
	<em>Suspects guilty of committing Major Crimes might also be sentenced to death, or perma-brigging, under specific circumstances listed below.</em><br>
	Execution, permabrigging, poisoning, or anything else resulting in death or massive frustration requires:
	<ol type="1">
		<li>Solid evidence of a major crime</li>
		<li>Permission of the following Heads:
			<ol type="i">
				<li>the Head of Security</li>
				<li>the Captain</li>
				<li>the Head of Personnel</li>
			</ol>
		</li>
	</ol>
	Please note that the ruling of the HoS supercedes that of the Captain in criminal matters, and likewise, the Captain with the HoP. Execution should only be used in grievous circumstances.<bt>
	<strong><em>The execution of criminals without Command authority, or evidence, is tantamount to murder.</em></strong>
	<h3>Standard Security Operating Practice</h3><hr>
	As a Security Officer, you are expected to practice a modicum of due process in detaining, searching, and arresting people. Suspects still have rights, and treating people like scum will usually just turn into more crime and bring about a swift end to your existence. Never use lethal force when nonlethal force will do!<br>
	<ul style='list-style-type:disc'>
		<li>Detain the suspect with minimum force.</li>
		<li>Handcuff the suspect and restrain them by pulling them. If their crime requires a brig time, bring them into the office, preferably via Port-a-Brig.</li>
		<li>In the brig, tell them you're going to search them before doing so. Empty their pockets and remove their backpack. Look through everything. Be sure to open containers inside containers, such as boxes inside backpacks. Be sure to replace all items in the containers when you're done. <strong><em>Don't strip them in the hallways!</em></strong></li>
		<li>If you need to brig them you can feed them into the little chute next to the brig. Remember to set the timer!</li>
		<li>Confiscate any contraband and/or stolen items, as well as any tools that may be used for future crimes, these need to be placed in a proper evidence locker, or crate and should not be left on the brig floor, or used for personal use, if stolen, return the items to their rightful owners.</li>
		<li>Update their security record if needed.</li>
	</ul>
	"}

/obj/machinery/shield_generator
	name = "shield generator"
	desc = "Some kinda thing what generates a big ol' shield around everything."
	//icon = 'icons/obj/meteor_shield.dmi'
	icon = 'icons/obj/32x96.dmi'
	icon_state = "shieldgen0"
	anchored = 1
	density = 1
	bound_height = 96
	var/obj/machinery/power/data_terminal/data_link = null
	var/net_id = null
	var/list/shields = list()
	var/active = 0
	var/image/image_active = null
	var/image/image_shower_dir = null
	//var/last_noise_time = 0
	//var/last_noise_length = 0
	//var/sound_loop_interrupt = 0
	var/sound_startup = 'sound/machines/shieldgen_startup.ogg' // 40
	//var/sound_loop = 'sound/machines/shieldgen_mainloop.ogg' // 75
	var/sound_shutoff = 'sound/machines/shieldgen_shutoff.ogg' // 35

	New()
		..()
		update_icon()
		spawn (6)
			if (!data_link)
				var/turf/T = get_turf(src)
				var/obj/machinery/power/data_terminal/test_link = locate() in T
				if (test_link && !test_link.is_valid_master(test_link.master))
					data_link = test_link
					data_link.master = src
			net_id = generate_net_id(src)

	proc/update_icon()
		if (stat & (NOPOWER|BROKEN))
			icon_state = "shieldgen0"
			UpdateOverlays(null, "top_lights")
			UpdateOverlays(null, "meteor_dir1")
			UpdateOverlays(null, "meteor_dir2")
			UpdateOverlays(null, "meteor_dir3")
			UpdateOverlays(null, "meteor_dir4")
			return

		if (active)
			icon_state = "shieldgen-anim"
			if (!image_active)
				image_active = image(icon, "shield-top_anim")
			UpdateOverlays(image_active, "top_lights")
		else
			icon_state = "shieldgen1"
			UpdateOverlays(null, "top_lights")

		if (meteor_shower_active)
			if (!image_shower_dir)
				image_shower_dir = image(icon, "shield-D[meteor_shower_active]")
			image_shower_dir.icon_state = "shield-D[meteor_shower_active]"
			UpdateOverlays(image_shower_dir, "meteor_dir[meteor_shower_active]")
		else
			UpdateOverlays(null, "meteor_dir1")
			UpdateOverlays(null, "meteor_dir2")
			UpdateOverlays(null, "meteor_dir3")
			UpdateOverlays(null, "meteor_dir4")

	process()
		//update_icon()
		if (stat & BROKEN)
			deactivate()
			return
		..()
		if (stat & NOPOWER)
			deactivate()
			return
		use_power(250)
		if (shields.len)
			use_power(5*shields.len)
/*
	proc/sound_loop()
		if (sound_loop_interrupt)
			sound_loop_interrupt = 0
			return
		if (active && (last_noise_time + last_noise_length <= ticker.round_elapsed_ticks))
			playsound(loc, sound_loop, 30)
			last_noise_length = 75
			last_noise_time = ticker.round_elapsed_ticks
		sleep(2)
		sound_loop()
*/
	disposing()
		remove_shield()
		data_link = null
		image_active = null
		image_shower_dir = null
		..()

	receive_signal(signal/signal)
		if (stat & (NOPOWER|BROKEN) || !data_link)
			return
		if (!signal || !net_id || signal.encryption)
			return

		if (signal.transmission_method != TRANSMISSION_WIRE) //No radio for us thanks
			return

		var/target = signal.data["sender"]

		//They don't need to target us specifically to ping us.
		//Otherwise, ff they aren't addressing us, ignore them
		if (signal.data["address_1"] != net_id)
			if ((signal.data["address_1"] == "ping") && signal.data["sender"])
				spawn (5) //Send a reply for those curious jerks
					post_status(target, "command", "ping_reply", "device", "PNET_SHIELD_GEN", "netid", net_id)
			return

		var/sigcommand = lowertext(signal.data["command"])
		if (!sigcommand || !signal.data["sender"])
			return

		switch (sigcommand)
			if ("activate")
				if (active)
					post_reply("SGEN_ACT", target)
					return
				activate()
				post_reply("SGEN_ACTVD", target)

			if ("deactivate")
				if (!active)
					post_reply("SGEN_NACT", target)
					return
				deactivate()
				post_reply("SGEN_DACTVD", target)

	// for testing atm
	attack_hand(mob/user as mob)
		user.show_text("You flip the switch on [src].")
		if (active)
			deactivate()
		else
			activate()
		message_admins("<span style=\"color:blue\">[key_name(user)] [active ? "activated" : "deactivated"] shields</span>")
		logTheThing("station", null, null, "[key_name(user)] [active ? "activated" : "deactivated"] shields")

	proc/post_status(var/target_id, var/key, var/value, var/key2, var/value2, var/key3, var/value3)
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

		data_link.post_signal(src, signal)

	proc/post_reply(error_text, target_id)
		if (!error_text || !target_id)
			return
		spawn (3)
			post_status(target_id, "command", "device_reply", "status", error_text)
		return

	proc/create_shield()
		var/area/shield_loc = locate(/area/station/shield_zone)
		for (var/turf/T in shield_loc)
			if (!(locate(/obj/forcefield/meteorshield) in T))
				var/obj/forcefield/meteorshield/MS = new /obj/forcefield/meteorshield(T)
				MS.deployer = src
				shields += MS

	proc/remove_shield()
		for (var/obj/forcefield/meteorshield/MS in shields)
			MS.deployer = null
			shields -= MS
			qdel(MS)

	proc/activate()
		if (active)
			return
		active = 1
		create_shield()
		update_icon()
		playsound(loc, sound_startup, 75)
		//last_noise_length = 40
		//last_noise_time = ticker.round_elapsed_ticks
		//src.sound_loop_interrupt = 0
		//sound_loop()

	proc/deactivate()
		if (!active)
			return
		active = 0
		remove_shield()
		update_icon()
		playsound(loc, sound_shutoff, 75)
		//src.last_noise_length = 0
		//last_noise_time = ticker.round_elapsed_ticks
		//sound_loop_interrupt = 1

/obj/machinery/computer3/generic/shield_control
	name = "shield control computer"
	icon_state = "engine"
	base_icon_state = "engine"
	setup_drive_size = 48

	setup_starting_peripheral1 = /obj/item/peripheral/network/powernet_card
	//setup_starting_peripheral2 = /obj/item/peripheral/network/radio/locked/pda
	setup_starting_program = /computer/file/terminal_program/shield_control

/computer/file/terminal_program/shield_control
	name = "ShieldControl"
	size = 10
	req_access = list(access_engineering_engine)
	var/tmp/authenticated = null //Are we currently logged in?
	var/computer/file/user_data/account = null
	var/obj/item/peripheral/network/powernet_card/pnet_card = null
	var/tmp/gen_net_id = null //The net id of our linked generator
	var/tmp/reply_wait = -1 //How long do we wait for replies? -1 is not waiting.

	var/setup_acc_filepath = "/logs/sysusr"//Where do we look for login data?

	initialize()
		authenticated = null
		master.temp = null
		if (!find_access_file()) //Find the account information, as it's essentially a ~digital ID card~
			src.print_text("<strong>Error:</strong> Cannot locate user file.  Quitting...")
			master.unload_program(src) //Oh no, couldn't find the file.
			return

		pnet_card = locate() in master.peripherals
		if (!pnet_card || !istype(pnet_card))
			pnet_card = null
			print_text("<strong>Warning:</strong> No network adapter detected.")

		if (!check_access(account.access))
			src.print_text("User [src.account.registered] does not have needed access credentials.<br>Quitting...")
			master.unload_program(src)
			return

		reply_wait = -1
		authenticated = account.registered

		var/intro_text = {"<strong>ShieldControl</strong>
		<br>Emergency Defense Shield System
		<br><strong>Commands:</strong>
		<br>(Link) to link with a shield generator.
		<br>(Activate) to activate shields.
		<br>(Deactivate) to deactivate shields.
		<br>(Clear) to clear the screen.
		<br>(Quit) to exit ShieldControl."}
		print_text(intro_text)

	input_text(text)
		if (..())
			return

		var/list/command_list = parse_string(text)
		var/command = command_list[1]
		command_list -= command_list[1] //Remove the command we are now processing.

		switch (lowertext(command))

			if ("link")
				if (!pnet_card) //can't do this ~fancy network stuff~ without a network card.
					print_text("<strong>Error:</strong> Network card required.")
					master.add_fingerprint(usr)
					return

				src.print_text("Now scanning for shield generator...")
				detect_generator()

			if ("activate")
				if (!pnet_card)
					print_text("<strong>Error:</strong> Network card required.")
					master.add_fingerprint(usr)
					return

				if (!gen_net_id)
					detect_generator()
					sleep(8)
					if (!gen_net_id)
						print_text("<strong>Error:</strong> Unable to detect generator.  Please check network cabling.")
						return
				else
					src.print_text("Transmitting activation request...")
					generate_signal(gen_net_id, "command", "activate")

			if ("deactivate")
				if (!pnet_card)
					print_text("<strong>Error:</strong> Network card required.")
					master.add_fingerprint(usr)
					return

				if (!gen_net_id)
					detect_generator()
					sleep(8)
					if (!gen_net_id)
						print_text("<strong>Error:</strong> Unable to detect generator.  Please check network cabling.")
						return
				else
					src.print_text("Transmitting deactivation request...")
					generate_signal(gen_net_id, "command", "deactivate")

			if ("help")
				var/help_text = {"<br><strong>ShieldControl</strong>
				<br>Emergency Defense Shield System
				<br><strong>Commands:</strong>
				<br>(Link) to link with a shield generator.
				<br>(Activate) to activate shields.
				<br>(Deactivate) to deactivate shields.
				<br>(Clear) to clear the screen.
				<br>(Quit) to exit ShieldControl."}
				print_text(help_text)

			if ("clear")
				master.temp = null
				master.temp_add = "Workspace cleared.<br>"

			if ("quit")
				master.temp = ""
				print_text("Now quitting...")
				master.unload_program(src)
				return

			else
				print_text("Unknown command : \"[copytext(strip_html(command), 1, 16)]\"")

		master.add_fingerprint(usr)
		master.updateUsrDialog()
		return

	process()
		if (..())
			return

		if (reply_wait > 0)
			reply_wait--
			if (reply_wait == 0)
				print_text("Timed out on generator. Please rescan and retry.")
				gen_net_id = null

	receive_command(obj/source, command, signal/signal)
		if ((..()) || (!signal))
			return

		//If we don't have a generator net_id to use, set one.
		switch (signal.data["command"])
			if ("ping_reply")
				if (gen_net_id)
					return
				if ((signal.data["device"] != "PNET_SHIELD_GEN") || !signal.data["netid"])
					return

				gen_net_id = signal.data["netid"]
				print_text("Shield generator detected.")

			if ("device_reply")
				if (!gen_net_id || signal.data["sender"] != gen_net_id)
					return

				reply_wait = -1

				switch (lowertext(signal.data["status"]))
					if ("sgen_act")
						print_text("<strong>Alert:</strong> Shield generator is already active.")

					if ("sgen_nact")
						print_text("<strong>Alert:</strong> Shield generator is already inactive.")

					if ("sgen_actvd")
						print_text("<strong>Alert:</strong> Shield generator activated.")
						if (master && master.current_user)
							message_admins("<span style=\"color:blue\">[key_name(master.current_user)] activated shields</span>")
							logTheThing("station", null, null, "[key_name(master.current_user)] activated shields")

					if ("sgen_dactvd")
						print_text("<strong>Alert:</strong> Shield generator deactivated.")
						if (master && master.current_user)
							message_admins("<span style=\"color:blue\">[key_name(master.current_user)] deactivated shields</span>")
							logTheThing("station", null, null, "[key_name(master.current_user)] deactivated shields")
				return
		return

	proc/find_access_file() //Look for the whimsical account_data file
		var/computer/folder/accdir = holder.root
		if (master.host_program) //Check where the OS is, preferably.
			accdir = master.host_program.holder.root

		var/computer/file/user_data/target = parse_file_directory(setup_acc_filepath, accdir)
		if (target && istype(target))
			account = target
			return TRUE

		return FALSE

	proc/detect_generator() //Send out a ping signal to find a comm dish.
		if (!pnet_card)
			return //The card is kinda crucial for this.

		var/signal/newsignal = get_free_signal()
		//newsignal.encryption = "\ref[pnet_card]"

		gen_net_id = null
		reply_wait = -1
		peripheral_command("ping", newsignal, "\ref[pnet_card]")

	proc/generate_signal(var/target_id, var/key, var/value, var/key2, var/value2, var/key3, var/value3)
		if (!pnet_card || !gen_net_id)
			return

		var/signal/signal = get_free_signal()
		//signal.encryption = "\ref[pnet_card]"
		signal.data["address_1"] = target_id
		signal.data[key] = value
		if (key2)
			signal.data[key2] = value2
		if (key3)
			signal.data[key3] = value3

		reply_wait = 5
		peripheral_command("transmit", signal, "\ref[pnet_card]")

/area/station/shield_zone
	icon_state = "shield_zone"

/area/station/aviary
	name = "Aviary"
	icon_state = "aviary"
	sound_environment = 15

/area/station/medical/medbay/cloner
	name = "Cloning"
	icon_state = "cloner"

/area/station/medical/medbay/pharmacy
	name = "Pharmacy"
	icon_state = "chem"

/area/station/medical/medbay/treatment1
	name = "Treatment Room 1"
	icon_state = "treat1"

/area/station/medical/medbay/treatment2
	name = "Treatment Room 2"
	icon_state = "treat2"

/area/station/bridge/captain
	name = "Captain's Office"
	icon_state = "CAPN"

/area/station/bridge/hos
	name = "Head of Personnel's Office"
	icon_state = "HOP"

/area/station/crew_quarters/hos
	name = "Head of Security's Quarters"
	icon_state = "HOS"
	sound_environment = 4

/area/station/crew_quarters/md
	name = "Medical Director's Quarters"
	icon_state = "MD"
	sound_environment = 4

/area/station/crew_quarters/ce
	name = "Chief Engineer's Quarters"
	icon_state = "CE"
	sound_environment = 4

/area/station/engine/engineering/ce
	name = "Chief Engineer's Office"
	icon_state = "CE"

/area/station/crew_quarters/quarters_fore
	name = "Fore Crew Quarters"
	icon_state = "crewquarters"
	sound_environment = 3

/area/station/crew_quarters/quarters_port
	name = "Port Crew Quarters"
	icon_state = "crewquarters"
	sound_environment = 3

/area/station/crew_quarters/quarters_star
	name = "Starboard Crew Quarters"
	icon_state = "crewquarters"
	sound_environment = 3

/area/station/crew_quarters/lounge
	name = "Crew Lounge"
	icon_state = "crew_lounge"
	sound_environment = 2

/area/station/crew_quarters/lounge_port
	name = "Port Crew Lounge"
	icon_state = "crew_lounge"
	sound_environment = 2

/area/station/crew_quarters/lounge_starboard
	name = "Starboard Crew Lounge"
	icon_state = "crew_lounge"
	sound_environment = 2

/area/station/mining
	name = "Mining"
	icon_state = "mining"
	sound_environment = 10

/area/station/mining/refinery
	name = "Mining Refinery"
	icon_state = "miningg"

/area/station/mining/magnet
	name = "Mining Magnet Control Room"
	icon_state = "miningp"

/*
/obj/airlock_door
	icon = 'icons/obj/doors/destiny.dmi'
	icon_state = "gen-left"
	density = 0
	opacity = 0
	var/obj/machinery/door/door = null

	attackby(obj/item/W, mob/M)
		if (door)
			door.attackby(W, M)

	attack_hand(mob/M)
		if (door)
			door.attack_hand(M)

	attack_ai(mob/user)
		if (door)
			door.attack_ai(user)

/obj/machinery/door/airlock/gannets
	icon = 'icons/obj/doors/destiny.dmi'
	icon_state = "track"
	var/obj/airlock_door/d_left = null
	var/d_left_state = "gen-left"
	var/obj/airlock_door/d_right = null
	var/d_right_state = "right"

	New()
		..()
		d_right = new(loc)
		d_right.icon_state = d_right_state
		d_right.door = src
		// make left after right so it's on top
		d_left = new(loc)
		d_left.icon_state = d_left_state
		d_left.door = src

	update_icon()
		icon_state = "track"
		return
/*
		if (density)
			if (locked)
				icon_state = "[icon_base]_locked"
			else
				icon_state = "[icon_base]_closed"
			if (p_open)
				if (!panel_image)
					panel_image = image(icon, panel_icon_state)
				UpdateOverlays(panel_image, "panel")
			else
				UpdateOverlays(null, "panel")
			if (welded)
				if (!welded_image)
					welded_image = image(icon, welded_icon_state)
				UpdateOverlays(welded_image, "weld")
			else
				UpdateOverlays(null, "weld")
		else
			UpdateOverlays(null, "panel")
			UpdateOverlays(null, "weld")
			icon_state = "[icon_base]_open"
		return
*/
	play_animation(animation)
		switch (animation)
			if ("opening")
				animate(d_left, time = operation_time, pixel_x = -18, easing = BACK_EASING)
				animate(d_right, time = operation_time, pixel_x = 18, easing = BACK_EASING)
			if ("closing")
				animate(d_left, time = operation_time, pixel_x = 0, easing = ELASTIC_EASING)
				animate(d_right, time = operation_time, pixel_x = 0, easing = ELASTIC_EASING)
			if ("spark")
				flick("[d_left_state]_spark", d_left)
				flick("[d_right_state]_spark", d_right)
			if ("deny")
				flick("[d_left_state]_deny", d_left)
				flick("[d_right_state]_deny", d_right)
		return
*/
// TODO:
// - mailputt
// - mailputt pickup port

/* ._.-'~'-._.-'~'-._.-'~'-._.-'~'-._.-'~'-._.-'~'-._.-'~'-._. */
/*-=-=-=-=-=-=-=-=-=-=-=-=-=PAINTBALL=-=-=-=-=-=-=-=-=-=-=-=-=-*/
/* '~'-._.-'~'-._.-'~'-._.-'~'-._.-'~'-._.-'~'-._.-'~'-._.-'~' */
/*
/obj/item/gun/kinetic/paintball
	name = "kinetic weapon"
	item_state = "paintball-"
	m_amt = 2000
	ammo = null
	max_ammo_capacity = 10

	auto_eject = 0
	casings_to_eject = 0

	add_residue = 0

/projectile/special/paintball
	name = "red paintball"
	icon_state = "paintball-r"
	icon_turf_hit = "paint-r"
	power = 1
	cost = 1
	dissipation_rate = 1
	dissipation_delay = 0
	ks_ratio = 1.0
	sname = "red"
	shot_sound = 'sound/weapons/Genhit.ogg'
	shot_number = 1
	damage_type = D_KINETIC
	hit_type = DAMAGE_BLUNT
	hit_ground_chance = 50

/obj/item/ammo/bullets/paintball
	sname = "paintball"
	name = "paintball jug"
	icon_state = "357-2"
	amount_left = 4.0
	max_amount = 4.0
	ammo_type = new/projectile/special/paintball
	caliber = 42069
	icon_dynamic = 1
	icon_short = "paintball"
	icon_empty = "paintball-0"

	update_icon()
		if (amount_left < 0)
			amount_left = 0

		desc = "There are [amount_left] paintball\s left!"

		if (amount_left > 0)
			if (icon_dynamic && icon_short)
				icon_state = "[icon_short]1"
		else
			if (icon_empty)
				icon_state = icon_empty
		return
*/
/* ._.-'~'-._.-'~'-._.-'~'-._.-'~'-._.-'~'-._.-'~'-._.-'~'-._. */
/*-=-=-=-=-=-=-=-=-=-=-=-=-=BLACKJACK=-=-=-=-=-=-=-=-=-=-=-=-=-*/
/* '~'-._.-'~'-._.-'~'-._.-'~'-._.-'~'-._.-'~'-._.-'~'-._.-'~' */
/*
/obj/submachine/blackjack
	name = "blackjack machine"
	desc = "Gambling for the antisocial."
	icon = 'icons/obj/objects.dmi'
	icon_state = "BJ1"
	anchored = 1
	density = 1
	mats = 9
	var/on = 1
	var/plays = 0
	var/working = 0
	var/current_bet = 10
	var/obj/item/card/id/ID = null

	var/list/cards = list() // cards in the deck
	var/list/removed_cards = list() // cards already used, to be moved back to cards on a new round
	var/list/hand_player = list()
	var/list/hand_dealer = list()

	var/image/overlay_light = null
	var/image/overlay_id = null

	New()
		..()
		var/playing_card/Card
		var/list/card_suits = list("hearts", "diamonds", "clubs", "spades")
		var/list/card_numbers = list("ace" = 1, "two" = 2, "three" = 3, "four" = 4, "five" = 5, "six" = 6, "seven" = 7, "eight" = 8, "nine" = 9, "ten" = 10, "jack" = 10, "queen" = 10, "king" = 10)

		for (var/suit in card_suits)
			for (var/num in card_numbers)
				Card = new()
				Card.card_name = "[num] of [suit]"
				Card.card_face = "large-[suit]-[num]"
				Card.card_data = card_numbers[num]
				cards += Card
		cards = shuffle(cards)

	proc/deal()
		var/playing_card/Card = pick(cards)
		cards -= Card
		return Card

	proc/reset_cards()
		for (var/playing_card/Card in removed_cards)
			cards += Card
			removed_cards -= Card
		for (var/playing_card/Card in hand_player)
			cards += Card
			hand_player -= Card
		for (var/playing_card/Card in hand_dealer)
			cards += Card
			hand_dealer -= Card
		cards = shuffle(cards)

	proc/update_icon()
		if (!overlay_light)
			overlay_light = image('icons/obj/objects.dmi', "BJ-light")
		overlays -= overlay_light
		overlays -= overlay_id
		if (ID && ID.icon_state)
			overlay_id = image(icon, "BJ-[ID.icon_state]")
			overlays += overlay_id
		if (on)
			if (working)
				icon_state = "BJ-card2"
			else
				icon_state = "BJ-card1"
		else
			icon_state = "BJ0"
*/
/* ._.-'~'-._.-'~'-._.-'~'-._.-'~'-._.-'~'-._.-'~'-._.-'~'-._. */
/*-=-=-=-=-=-=-=-=-=-=-=-=-+BARTENDER+-=-=-=-=-=-=-=-=-=-=-=-=-*/
/* '~'-._.-'~'-._.-'~'-._.-'~'-._.-'~'-._.-'~'-._.-'~'-._.-'~' */

/mob/living/carbon/human/npc/diner_bartender
	var/im_mad = 0
	var/obj/machinery/chem_dispenser/alcohol/booze = null
	var/obj/machinery/chem_dispenser/soda/soda = null
	var/last_dispenser_search = null
	var/list/glassware = list()

	New()
		..()
		spawn (0)
			randomize_look(src)
			equip_if_possible(new /obj/item/clothing/shoes/black(src), slot_shoes)
			equip_if_possible(new /obj/item/clothing/under/rank/bartender(src), slot_w_uniform)
			equip_if_possible(new /obj/item/clothing/suit/wcoat(src), slot_wear_suit)
			equip_if_possible(new /obj/item/clothing/glasses/thermal/orange, slot_glasses)
			equip_if_possible(new /obj/item/gun/kinetic/riotgun(src), slot_in_backpack)
			equip_if_possible(new /obj/item/storage/box/glassbox(src), slot_in_backpack)
			for (var/obj/item/reagent_containers/food/drinks/drinkingglass/glass in src)
				glassware += glass
			// add a random accent
			var/my_mutation = pick("accent_elvis", "stutter", "accent_chav", "accent_swedish", "accent_tommy", "unintelligable", "slurring")
			bioHolder.AddEffect(my_mutation)

	was_harmed(var/mob/M as mob, var/obj/item/weapon as obj)
		protect_from(M, null, weapon)

	proc/protect_from(var/mob/M as mob, var/mob/customer as mob, var/obj/item/weapon as obj)
		if (!M)
			return

		if (weapon) // someone got hit by something that hurt
			im_mad += 50
			if (!customer || customer == src) // they're doing shit to us
				im_mad += 50 // we're double mad

		else if (M.a_intent == INTENT_DISARM) // they're shoving someone around
			im_mad += 5
			if (!customer || customer == src) // they're doing shit to us
				im_mad += 5 // we're double mad

		else if (M.a_intent == INTENT_GRAB) // they're grabbin' up on someone
			im_mad += 20
			ai_check_grabs()
			if (!customer || customer == src) // they're doing shit to us
				im_mad += 20 // we're double mad

		else if (M.a_intent == INTENT_HARM)
			im_mad += 50
			if (!customer || customer == src) // they're doing shit to us
				im_mad += 50 // we're double mad

		spawn (rand(10, 30))
			yell_at(M, customer)

	proc/yell_at(var/mob/M as mob, var/mob/customer as mob) // blatantly stolen from NPC assistants and then hacked up
		if (!M)
			return
		var/tmp/target_name = M.name
		var/area/current_loc = get_area(src)
		var/tmp/where_I_am = "here"
		if (copytext(current_loc.name, 1, 6) == "Diner")
			where_I_am = "my bar"
		var/tmp/complaint
		if (im_mad < 100)
			var/tmp/insult = pick("fucker", "fuckhead", "shithead", "shitface", "shitass", "asshole")
			var/tmp/targ = pick("", ", [target_name]", ", [insult]", ", you [insult]")
			complaint = pick("Hey[targ]!", "Knock it off[targ]!", "What d'you think you're doing[targ]?", "Fuck off[targ]!", "Go fuck yourself[targ]!", "Cut that shit out[targ]!")

			if (customer && (customer != src)  && prob(10))
				complaint += " [customer.name] is [pick("my best customer", "a good customer", "a fucking [pick("idiot", "asshole")], but I still like 'em better than your stupid ass")][pick(", and I ain't lettin' no shithead like you fuck with 'em", "")]!"

		else if (im_mad >= 100 && M.health > 0)
			complaint = pick("[target_name], [pick("", "you [pick("better", "best")] ")]get [pick("your ass ", "your ugly [pick("face", "mug")] ", "")]the fuck out of [where_I_am][pick("", " before I make you")]!",\
			"I don't put up with this [pick("", "kinda ")][pick("", "horse", "bull")][pick("shit", "crap")] in [where_I_am], [target_name]!",\
			"I hope you don't like how your face looks, [target_name], cause it's about to get rearranged!",\
			"I told you to [pick("stop that shit", "cut that shit out")], and you [pick("ain't", "didn't", "didn't listen")]! [pick("So now", "It's time", "And now", "Ypu best not be suprised that")] you're gunna [pick("reap what you sewed", "get it", "get what's yours", "get what's comin' to you")]!")
			target = M
			ai_state = 2
			ai_threatened = world.timeofday
			ai_target = M
			im_mad = 0

			if (customer && (customer != src) && prob(75))
				complaint += " [customer.name] is [pick("my best customer", "a good customer", "a fucking [pick("idiot", "asshole")], but I still like 'em better than your [pick("stupid ass", "ugly [pick("face", "mug")]")]")][pick(", and I ain't lettin' no shithead like you fuck with 'em", "")]!"

		say(complaint)

	proc/done_with_you(var/mob/M as mob)
		if (!M)
			return FALSE

		var/tmp/target_name = M.name
		var/area/current_loc = get_area(src)
		var/tmp/where_I_am = "here"
		if (copytext(current_loc.name, 1, 6) == "Diner")
			where_I_am = "my bar"

		if (M.health <= 10)
			var/tmp/insult = pick("fucker", "fuckhead", "shithead", "shitface", "shitass", "asshole")
			var/tmp/targ = pick("", ", [target_name]", ", [insult]", ", you [insult]")
			var/tmp/punct = pick(".", "!")

			var/tmp/kicked_their_ass = pick("Damn right, you stay down[targ][punct]",\
			"Try it again[targ], and next time you'll be hurting even more[punct]",\
			"Goddamn [insult][punct]")
			say(kicked_their_ass)

			target = null
			ai_state = 0
			ai_target = null
			im_mad = 0
			walk_towards(src,null)
			return TRUE

		else if (health <= 10)
			var/tmp/kicked_my_ass = pick("Get away from me!",\
			"I give, leave me [pick("", "the hell ", "the fuck ")]alone!",\
			"Fuck, stop!",\
			"No more!",\
			"Enough, please!")
			say(kicked_my_ass)

			target = null
			ai_state = 0
			ai_target = null
			im_mad = 0
			walk_towards(src,null)
			return TRUE

		else if (get_dist(src, M) >= 5)
			var/tmp/insult = pick("fucker", "fuckhead", "shithead", "shitface", "shitass", "asshole")
			var/tmp/targ = pick("", ", [target_name]", ", [insult]", ", you [insult]")

			var/tmp/got_away = pick("Yeah, get the fuck outta [where_I_am][targ]!",\
			"Don't [pick("bother coming back", "[pick("", "ever ")]show your [pick("", "ugly ", "stupid ")][pick("face", "mug")] in [where_I_am] again")]",\
			"If I ever catch you in [where_I_am] again, you[pick("'ll regret it", "'ll be diggin' your own grave", "'d best stop by that fancy cloner you fuckers got, first", " won't be leaving in one piece")]!")
			say(got_away)

			target = null
			ai_state = 0
			ai_target = null
			im_mad = 0
			walk_towards(src,null)
			return TRUE
		else
			return FALSE

	ai_action()
		ai_check_grabs()
		if (ai_state == 2 && done_with_you(ai_target))
			return
		else
			return ..()

	proc/ai_check_grabs()
		for (var/mob/living/carbon/human/H in all_viewers(7, src))
			var/obj/item/grab/G = H.find_type_in_hand(/obj/item/grab)
			if (!G)
				return FALSE
/*
			if (G.affecting in npc_protected_mobs)
				if (G.state == 1)
					im_mad += 5
				else if (G.state == 2)
					im_mad += 20
				else if (G.state == 3)
					im_mad += 50
				return TRUE
*/
			if (G.affecting == src) // we won't put up with shit being done to us nearly as much as we'll put up with it for others
				if (G.state == 1)
					im_mad += 20
				else if (G.state == 2)
					im_mad += 60
				else if (G.state == 3)
					im_mad += 100
				return TRUE

			return FALSE
/*
	proc/ai_find_my_bar()
		if (booze && soda)
			return
		if (ticker.elapsed_ticks < (last_dispenser_search + 50))
			return
		last_dispenser_search = ticker.elapsed_ticks
		if (!booze)
			var/obj/machinery/chem_dispenser/alcohol/new_booze = locate() in view(7, src)
			if (new_booze)
				booze = new_booze
		if (!soda)
			var/obj/machinery/chem_dispenser/soda/new_soda = locate() in view(7, src)
			if (new_soda)
				soda = new_soda

	proc/ai_tend_bar() // :D
		if (!booze || !soda) // we don't have a place to make drinks  :(
			ai_find_my_bar() // look for some dispensers
			if (!booze || !soda) // we didn't find any!  <:(
				return FALSE // let's give up I guess (for now)  :'(
		if (booze && soda)
*/
/*
/mob/living/carbon/human/attack_hand(mob/M)
	if (protected_by_npcs)
		..()
		if (M.a_intent in list(INTENT_HARM,INTENT_DISARM,INTENT_GRAB))
			for (var/mob/living/carbon/human/npc/diner_bartender/BT in all_viewers(7, src))
				BT.protect_from(M, src)
	else
		..()

/mob/living/carbon/human/attackby(obj/item/W, mob/M)
	if (protected_by_npcs)
		var/tmp/oldbloss = get_brute_damage()
		var/tmp/oldfloss = get_burn_damage()
		..()
		var/tmp/damage = ((get_brute_damage() - oldbloss) + (get_burn_damage() - oldfloss))
		if ((damage > 0) || W.force)
			for (var/mob/living/carbon/human/npc/diner_bartender/BT in all_viewers(7, src))
				BT.protect_from(M, src)
	else
		..()
*/
/* ._.-'~'-._.-'~'-._.-'~'-._.-'~'-._.-'~'-._.-'~'-._.-'~'-._. */
/*-=-=-=-=-=-=-=-=-=-=-=-=-+MISCSTUFF+-=-=-=-=-=-=-=-=-=-=-=-=-*/
/* '~'-._.-'~'-._.-'~'-._.-'~'-._.-'~'-._.-'~'-._.-'~'-._.-'~' */
/*
/reagent/medical/heparin
	name = "heparin"
	id = "heparin"
	description = "An anticoagulant used in heart surgeries, and in the treatment of thrombosis."
	reagent_state = LIQUID
	fluid_r = 252
	fluid_g = 252
	fluid_b = 224
	transparency = 80
	depletion_rate = 0.2
*/
/*
/obj/item // if I accidentally commit this uncommented PLEASE KILL ME tia <3
	var/adj1 = 1
	var/adj2 = 100

/obj/item/scalpel
	attack_self(mob/user as mob)
		..()
		var/new_adj1 = input(user, "adj1", "adj1", adj1) as null|num
		var/new_adj2 = input(user, "adj2", "adj2", adj2) as null|num
		if (new_adj1)
			adj1 = new_adj1
		if (new_adj2)
			adj2 = new_adj2

/obj/item/circular_saw
	attack_self(mob/user as mob)
		..()
		var/new_adj1 = input(user, "adj1", "adj1", adj1) as null|num
		var/new_adj2 = input(user, "adj2", "adj2", adj2) as null|num
		if (new_adj1)
			adj1 = new_adj1
		if (new_adj2)
			adj2 = new_adj2
*/
/*
	var/num1 = "#FFFFFF"
	var/hexnum = copytext(num1, 2)
	var/num2 = num2hex(hex2num(hexnum) - 554040)
*/

/turf/simulated/floor/plating/random
	New()
		..()
		if (prob(20))
			icon_state = pick("panelscorched", "platingdmg1", "platingdmg2", "platingdmg3")
		if (prob(10))
			new /obj/decal/cleanable/dirt(src)
		else if (prob(2))
			var/obj/C = pick(/obj/decal/cleanable/paper, /obj/decal/cleanable/fungus, /obj/decal/cleanable/dirt, /obj/decal/cleanable/ash,\
			/obj/decal/cleanable/molten_item, /obj/decal/cleanable/machine_debris, /obj/decal/cleanable/oil, /obj/decal/cleanable/rust)
			new C (src)
		else if ((locate(/obj) in src) && prob(3))
			var/obj/C = pick(/obj/item/cable_coil/cut/small, /obj/item/brick, /obj/item/cigbutt, /obj/item/scrap, /obj/item/raw_material/scrap_metal,\
			/obj/item/spacecash, /obj/item/tile/steel, /obj/item/weldingtool, /obj/item/screwdriver, /obj/item/wrench, /obj/item/wirecutters, /obj/item/crowbar)
			new C (src)
		else if (prob(1) && prob(2)) // really rare. not "three space things spawn on destiny during first test with just prob(1)" rare.
			var/obj/C = pick(/obj/item/space_thing, /obj/item/sticker/gold_star, /obj/item/sticker/banana, /obj/item/sticker/heart,\
			/obj/item/reagent_containers/vending/bag/random, /obj/item/reagent_containers/vending/vial/random, /obj/item/clothing/mask/cigarette/random)
			new C (src)
		return

/turf/simulated/floor/plating/airless/random
	New()
		..()
		if (prob(20))
			icon_state = pick("panelscorched", "platingdmg1", "platingdmg2", "platingdmg3")

/turf/simulated/floor/grass/random
	name = "grass"
	icon_state = "grass1"
	var/list/random_icons = list("grass1", "grass2", "grass3", "grass4")
	New()
		..()
		icon_state = pick(random_icons)

/turf/simulated/tempstuff
	name = "floor"
	icon = 'icons/misc/HaineSpriteDump.dmi'
	icon_state = "gooberything_small"

/obj/item/postit_stack
	name = "stack of sticky notes"
	desc = "A little stack of notepaper that you can stick to things."
	icon = 'icons/obj/writing.dmi'
	icon_state = "postit_stack"
	force = 1
	throwforce = 1
	w_class = 1
	amount = 10
	burn_point = 220
	burn_output = 200
	burn_possible = 1
	health = 2

	afterattack(var/atom/A as mob|obj|turf, var/mob/user as mob)
		if (!A)
			return
		if (isarea(A))
			return
		if (amount < 0)
			qdel(src)
			return
		var/turf/T = get_turf(A)
		var/obj/decal/cleanable/writing/postit/P = new (T)
		user.visible_message("<strong>[user]</strong> sticks a sticky note to [T].",\
		"You stick a sticky note to [T].")
		var/obj/item/pen/pen = user.find_type_in_hand(/obj/item/pen)
		if (pen)
			P.attackby(pen, user)
		amount --
		if (amount < 0)
			qdel(src)
			return

/obj/item/blessed_ball_bearing
	name = "blessed ball bearing" // fill claymores with them for all your nazi-vampire-protection needs
	desc = "How can you tell it's blessed? Well, just look at it! It's so obvious!"
	icon = 'icons/misc/HaineSpriteDump.dmi'
	icon_state = "ballbearing"
	w_class = 1
	force = 7
	throwforce = 5
	stamina_damage = 25
	stamina_cost = 15
	stamina_crit_chance = 5
	rand_pos = 1

	attack(mob/M as mob, mob/user as mob) // big ol hackery here
		if (M && isvampire(M))
			force = (force * 2)
			stamina_damage = (stamina_damage * 2)
			stamina_crit_chance = (stamina_crit_chance * 2)
			..(M, user)
			force = (force / 2)
			stamina_damage = (stamina_damage / 2)
			stamina_crit_chance = (stamina_crit_chance / 2)
		else
			return ..()

	throw_impact(atom/hit_atom)
		if (hit_atom && isvampire(hit_atom))
			force = (force * 2)
			stamina_damage = (stamina_damage * 2)
			stamina_crit_chance = (stamina_crit_chance * 2)
			..(hit_atom)
			force = (force / 2)
			stamina_damage = (stamina_damage / 2)
			stamina_crit_chance = (stamina_crit_chance / 2)
		else
			return ..()

/obj/item/space_thing
	name = "space thing"
	desc = "Some kinda thing, from space. In space. A space thing."
	icon = 'icons/obj/stationobjs.dmi'
	icon_state = "thing"
	flags = FPRINT | CONDUCT | TABLEPASS
	w_class = 1.0
	force = 10
	throwforce = 7
	mats = 50
	contraband = 1
	stamina_damage = 40
	stamina_cost = 30
	stamina_crit_chance = 10

/obj/test_knife_switch_switch
	name = "knife switch switch"
	desc = "This is an object that's just for testing the knife switch art. Don't use it!"
	icon = 'icons/obj/knife_switch.dmi'
	icon_state = "knife_switch1-throw"
	anchored = 1

	verb/change_icon()
		set name = "Change Switch Icon"
		set category = "Debug"
		set src in oview(1)

		var/list/switch_icons = list("switch1", "switch2", "switch3", "switch4", "switch5")

		var/switch_select = input("Switch Icon") as null|anything in switch_icons

		if (!switch_select)
			return
		icon_state = "[switch_select]-throw"

	attack_hand(mob/user as mob)
		change_icon()
		return

/obj/test_knife_switch_board
	name = "knife switch board"
	desc = "This is an object that's just for testing the knife switch art. Don't use it!"
	icon = 'icons/obj/knife_switch.dmi'
	icon_state = "knife_base1"
	anchored = 1

	verb/change_icon()
		set name = "Change Board Icon"
		set category = "Debug"
		set src in oview(1)

		var/list/board_icons = list("board1", "board2", "board3", "board4", "board5")

		var/board_select = input("Board Icon") as null|anything in board_icons

		if (!board_select)
			return
		icon_state = "[board_select]"

	attack_hand(mob/user as mob)
		change_icon()
		return

// tOt I ain't agree to no universal corgi ban
// and no one's gunna get it if they just see George and Blair okay!!
// and I can't just rename the pug!!!
/obj/critter/dog/george/orwell
	name = "Orwell"
	icon_state = "corgi"
	doggy = "corgi"

/* ._.-'~'-._.-'~'-._.-'~'-._.-'~'-._.-'~'-._.-'~'-._.-'~'-._. */
/*-=-=-=-=-=-=-=-=-=-=-=-=-=+KALI-MA+=-=-=-=-=-=-=-=-=-=-=-=-=-*/
/* '~'-._.-'~'-._.-'~'-._.-'~'-._.-'~'-._.-'~'-._.-'~'-._.-'~' */
// shit be all janky and broken atm, gunna come back to it later
/*
Bali Mangthi Kali Ma.
Sacrifice is what Mother Kali desires.
Shakthi Degi Kali Ma.
Power is what Mother Kali will grant.
Kali ma...
Mother Kali...
Kali ma...
Mother Kali...
Kali ma, shakthi deh!
Mother Kali, give me power!
Ab, uski jan meri mutti me hai! AB, USKI JAN MERI MUTTI ME HAI!
Now, his life is in my fist! NOW, HIS LIFE IS IN MY FIST!

/obj/item/clothing/under/mola_ram
	name = "mola ram thing"
	desc = "kali ma motherfuckers"
	icon = 'icons/obj/clothing/overcoats/item_suit_gimmick.dmi'
	inhand_image_icon = 'icons/mob/inhand/jumpsuit/hand_js_gimmick.dmi'
	wear_image_icon = 'icons/mob/jumpsuits/worn_js_gimmick.dmi'
	icon_state = "bedsheet"
	item_state = "bedsheet"
	body_parts_covered = TORSO|LEGS|ARMS
	contraband = 8

	equipped(var/mob/user)
		user.verbs += /mob/proc/kali_ma

	unequipped(var/mob/user)
		user.verbs -= /mob/proc/kali_ma
		user.verbs -= /mob/proc/kali_ma_placeholder

/mob/proc/kali_ma_placeholder(var/mob/living/M in grabbing())
	set category = "Sacrifice"
	set name = "Throw (c)"
	set desc = "Spin a grabbed opponent around and throw them."

	boutput(usr, "<span style=\"color:red\">Kali Ma is appeased for the moment!</span>")
	return

/mob/proc/kali_ma(var/mob/living/M in grabbing())
	set category = "Sacrifice"
	set name = "Throw"
	set desc = "Spin a grabbed opponent around and throw them."

	spawn (0)

		if (!stat && !transforming && M)
			if (paralysis > 0 || weakened > 0 || stunned > 0)
				boutput(src, "You can't do that while incapacitated!")
				return

			if (restrained())
				boutput(src, "You can't do that while restrained!")
				return

			else
				for (var/obj/item/grab/G in src)

					if (!G)
						boutput(src, "You must be grabbing someone for this to work!")
						return
					if (istype(G.affecting, /mob/living))
						verbs += /mob/proc/kali_ma_placeholder
						verbs -= /mob/proc/kali_ma
						say("Bali Mangthi Kali Ma.")
						sleep(10)
						var/mob/living/H = G.affecting
						if (H.lying)
							H.lying = 0
							H.paralysis = 0
							H.weakened = 0
							H.set_clothing_icon_dirty()
						H.transforming = 1
						transforming = 1
						dir = get_dir(src, H)
						H.dir = get_dir(H, src)
						visible_message("<span style=\"color:red\"><strong>[src] menacingly grabs [H] by the neck!</strong></span>")
						say("Shakthi Degi Kali Ma.")
						var/dir_offset = get_dir(src, H)
						switch(dir_offset)
							if (NORTH)
								H.pixel_y = -24
								H.layer = layer - 1
							if (SOUTH)
								H.pixel_y = 24
								H.layer = layer + 1
							if (EAST)
								H.pixel_x = -24
								H.layer = layer - 1
							if (WEST)
								H.pixel_x = 24
								H.layer = layer - 1
						for (var/i = 0, i < 5, i++)
							H.pixel_y += 2
							sleep(3)
						src.say("Kali Ma...")
						sleep(20)
						src.say("Kali Ma...")
						sleep(20)
						if (istype(H,/mob/living/carbon/human))
							var/mob/living/carbon/human/HU = H
							visible_message("<span style=\"color:red\"><strong>[src] shoves \his hand into [H]'s chest!</strong></span>")
							say("Kali ma, shakthi deh!")
							if (HU.heart_op_stage <= 3.0)
								HU:heart_op_stage = 4.0
								HU.contract_disease(/ailment/disease/noheart,null,null,1)
								var/obj/item/organ/heart/heart = new /obj/item/organ/heart(loc)
								heart.donor = HU
								playsound(loc, "sound/misc/loudcrunch2.ogg", 75)
								HU.emote("scream")
								sleep(20)
								say("Ab, uski jan meri mutti me hai! AB, USKI JAN MERI MUTTI ME HAI!")
							else
								playsound(loc, "sound/misc/loudcrunch2.ogg", 75)
								HU.emote("scream")
								visible_message("<span style=\"color:red\"><strong>[src] finds no heart in [H]'s chest! [src] looks kinda [pick(</span>"embarassed", "miffed", "annoyed", "confused", "baffled")]!</strong>")
								sleep(20)
							HU.stunned += 10
							HU.weakened += 12
							var/turf/target = get_edge_target_turf(src, dir)
							spawn (0)
								playsound(loc, "swing_hit", 40, 1)
								visible_message("<span style=\"color:red\"><strong>[src] casually tosses [H] away!</strong></span>")
								HU.throw_at(target, 10, 2)
							HU.pixel_x = 0
							HU.pixel_y = 0
							HU.transforming = 0

						var/cooldown = max(100,(300-jitteriness))
						spawn (cooldown)
							verbs -= /mob/proc/kali_ma_placeholder
							if (istype(src:w_uniform, /obj/item/clothing/under/mola_ram))
								verbs += /mob/proc/kali_ma
								boutput(src, "<span style=\"color:red\">Kali Ma desires more!</span>")

						return
*/

/* ._.-'~'-._.-'~'-._.-'~'-._.-'~'-._.-'~'-._.-'~'-._.-'~'-._. */
/*-=-=-=-=-=-=-=-=-=-=-=-=-=+COCAINE+=-=-=-=-=-=-=-=-=-=-=-=-=-*/
/* '~'-._.-'~'-._.-'~'-._.-'~'-._.-'~'-._.-'~'-._.-'~'-._.-'~' */
/*
// http://en.wikipedia.org/wiki/Cocaine
// http://en.wikipedia.org/wiki/Cocaine_paste
// http://en.wikipedia.org/wiki/Crack_cocaine

/overlayComposition/cocaine
	New()
		var/overlayDefinition/zero = new()
		zero.d_icon_state = "beamout"
		zero.d_blend_mode = 2 //add
		zero.customization_third_color = "#08BFC2"
		zero.d_alpha = 50
		definitions.Add(zero)
/*		var/overlayDefinition/spot = new()
		spot.d_icon_state = "knockout"
		spot.d_blend_mode = 3 //sub
		definitions.Add(spot) */
		return ..()

/overlayComposition/cocaine_minor_od
	New()
		var/overlayDefinition/zero = new()
		zero.d_icon_state = "beamout"
		zero.d_blend_mode = 2
		zero.customization_third_color = "#FFFFFF"
		zero.d_alpha = 50
		definitions.Add(zero)
/*		var/overlayDefinition/spot = new()
		spot.d_icon_state = "knockout"
		spot.d_blend_mode = 3 //sub
		definitions.Add(spot) */
		return ..()

/overlayComposition/cocaine_major_od
	New()
		var/overlayDefinition/zero = new()
		zero.d_icon_state = "beamout"
		zero.d_blend_mode = 2
		zero.customization_third_color = "#C20B08"
		zero.d_alpha = 50
		definitions.Add(zero)
/*		var/overlayDefinition/spot = new()
		spot.d_icon_state = "knockout"
		spot.d_blend_mode = 3 //sub
		definitions.Add(spot) */
		return ..()

/reagent/drug/cocaine_paste
	name = "cocaine paste"
	id = "cocaine_paste"
	description = "A close precursor to cocaine, produced from the leaves of the coca plant. It's not very good for you. Cocaine isn't either, I mean, but at least it's better than this stuff."
	reagent_state = SOLID
	fluid_r = 210
	fluid_g = 220
	fluid_b = 210
	transparency = 255
	addiction_prob = 80
	overdose = 5
	var/remove_buff = 0

/reagent/drug/cocaine
	name = "cocaine"
	id = "cocaine"
	description = "A powerful, dangerous stimulant produced from leaves of the coca plant. It's a fine white powder."
	reagent_state = SOLID
	fluid_r = 250
	fluid_g = 250
	fluid_b = 250
	transparency = 255
	addiction_prob = 75
	overdose = 15
	var/remove_buff = 0

// highly addictive, excellent stimulant.  makes you feel awesome, on top of the world, euphoric, etc.  numbs you a bit.
// as it leaves your system: paranoia, anxiety, restlessness.
// minor OD: paranoid delusions, itching, hallucinations, tachycardia
// major OD: hyperthermia, tremors, convulsions, arrythmia, and sudden cardiac death
// bubs idea (bubdea): medal for injecting someone with epinephrine while they have coke in their system, "Mrs. Wallace"
// <bubs> put the leaves in a thing with some welding fuel
// <bubs> and something analogous to paint thinner
// <bubs> to get cocaine paste
// <bubs> then combine the cocaine paste with sulfuric acid
// <bubs> then for additional fun combine it with baking soda in the kitchen
// <bubs> baking soda, dropper, cocaine in oven makes crack

	on_add()
		if (istype(holder) && istype(holder.my_atom) && hascall(holder.my_atom,"add_stam_mod_regen"))
			holder.my_atom:add_stam_mod_regen("consumable_good", 200)
		if (hascall(holder.my_atom,"addOverlayComposition"))
			holder.my_atom:addOverlayComposition(/overlayComposition/cocaine)
		return
	on_remove()
		if (remove_buff)
			if (istype(holder) && istype(holder.my_atom) && hascall(holder.my_atom,"remove_stam_mod_regen"))
				holder.my_atom:remove_stam_mod_regen("consumable_good")
		if (hascall(holder.my_atom,"removeOverlayComposition"))
			holder.my_atom:removeOverlayComposition(/overlayComposition/cocaine)
			holder.my_atom:removeOverlayComposition(/overlayComposition/cocaine_minor_od)
			holder.my_atom:removeOverlayComposition(/overlayComposition/cocaine_major_od)
		return

// grabbing shit from meth, crank and bathsalts for now, cause they do some stuff close to what I want

	on_mob_life(var/mob/M)
		if (!M) M = holder.my_atom
		M.drowsyness = max(M.drowsyness-15, 0)
		if (M.paralysis) M.paralysis-=3
		if (M.stunned) M.stunned-=3
		if (M.weakened) M.weakened-=3
		if (M.sleeping) M.sleeping = 0
		if (prob(15)) M.emote(pick("grin", "smirk", "blink", "blink_r", "nod", "twitch", "twitch_v", "laugh", "chuckle", "stare", "leer", "scream"))
		if (prob(10))
			boutput(M, pick("<span style=\"color:red\"><strong>You [pick(</span>"feel", "are")] [pick("", "totally ", "utterly ", "completely ", "absolutely ")]fucking [pick("awesome", "rad", "great")]!</strong>", "<span style=\"color:red\"><strong>[pick(</span>"Fuck", "Fucking", "Hell")] [pick("yeah", "yes")]!</strong>", "<span style=\"color:red\"><strong>[pick(</span>"Yes", "YES")]!</strong>", "<span style=\"color:red\"><strong>You've got this shit in the BAG!</strong></span>", "<span style=\"color:red\"><strong>I said god DAMN!!!</strong></span>"))
			M.emote(pick("grin", "smirk", "nod", "laugh", "chuckle", "scream"))
/*		if (prob(6))
			boutput(M, "<span style=\"color:red\"><strong>You feel warm.</strong></span>")
			M.bodytemperature += rand(1,10)
		if (prob(4))
			boutput(M, "<span style=\"color:red\"><strong>You feel kinda awful!</strong></span>")
			M.take_toxin_damage(1)
			M.updatehealth()
			M.make_jittery(30)
			M.emote(pick("groan", "moan")) */
		..(M)
		return

	do_overdose(var/severity, var/mob/M)
		var/effect = ..(severity, M)
		if (severity == 1)
			if (hascall(holder.my_atom,"removeOverlayComposition"))
				holder.my_atom:removeOverlayComposition(/overlayComposition/cocaine)
				holder.my_atom:removeOverlayComposition(/overlayComposition/cocaine_major_od)
			if (hascall(holder.my_atom,"addOverlayComposition"))
				holder.my_atom:addOverlayComposition(/overlayComposition/cocaine_minor_od)
			if (effect <= 2)
				M.visible_message("<span style=\"color:red\"><strong>[M.name]</strong> looks confused!</span>", "<span style=\"color:red\"><strong>Fuck, what was that?!</strong></span>")
				M.change_misstep_chance(33)
				M.make_jittery(20)
				M.emote(pick("blink", "blink_r", "twitch", "twitch_v", "stare", "leer"))
			else if (effect <= 4)
				M.visible_message("<span style=\"color:red\"><strong>[M.name]</strong> is all sweaty!</span>", "<span style=\"color:red\"><strong>Did it get way fucking hotter in here?</strong></span>")
				M.bodytemperature += rand(10,30)
				M.brainloss++
				M.take_toxin_damage(1)
				M.updatehealth()
			else if (effect <= 7)
				M.make_jittery(30)
				M.emote(pick("blink", "blink_r", "twitch", "twitch_v", "stare", "leer"))
		else if (severity == 2)
			if (hascall(holder.my_atom,"removeOverlayComposition"))
				holder.my_atom:removeOverlayComposition(/overlayComposition/cocaine)
				holder.my_atom:removeOverlayComposition(/overlayComposition/cocaine_minor_od)
			if (hascall(holder.my_atom,"addOverlayComposition"))
				holder.my_atom:addOverlayComposition(/overlayComposition/cocaine_major_od)
			if (effect <= 2)
				M.visible_message("<span style=\"color:red\"><strong>[M.name]</strong> is sweating like a pig!</span>", "<span style=\"color:red\"><strong>Fuck, someone turn on the AC!</strong></span>")
				M.bodytemperature += rand(20,100)
				M.take_toxin_damage(5)
				M.updatehealth()
			else if (effect <= 4)
				M.visible_message("<span style=\"color:red\"><strong>[M.name]</strong> starts freaking the fuck out!</span>", "<span style=\"color:red\"><strong>Holy shit, what the fuck was that?!</strong></span>")
				M.make_jittery(100)
				M.take_toxin_damage(2)
				M.brainloss += 8
				M.updatehealth()
				M.weakened += 3
				M.change_misstep_chance(40)
				M.emote("scream")
			else if (effect <= 7)
				M.emote("scream")
				M.visible_message("<span style=\"color:red\"><strong>[M.name]</strong> nervously scratches at their skin!</span>", "<span style=\"color:red\"><strong>Fuck, so goddamn itchy!</strong></span>")
				M.make_jittery(10)
				random_brute_damage(M, 5)
				M.emote(pick("blink", "blink_r", "twitch", "twitch_v", "stare", "leer"))


/* ----------Info from wikipedia----------
Cocaine is a powerful nervous system stimulant.
Its effects can last from fifteen to thirty minutes, to an hour.
That is all depending on the amount of the intake dosage and the route of administration.
Cocaine can be in the form of fine white powder, bitter to the taste.
When inhaled or injected, it causes a numbing effect.
"Crack" cocaine is a smokeable form of cocaine made into small "rocks" by processing cocaine with sodium bicarbonate (baking soda) and water.

Cocaine increases alertness, feelings of well-being and euphoria, energy and motor activity, feelings of competence and sexuality.
Anxiety, paranoia and restlessness can also occur, especially during the comedown.
With excessive dosage, tremors, convulsions and increased body temperature are observed.
Severe cardiac adverse events, particularly sudden cardiac death, become a serious risk at high doses due to cocaine's blocking effect on cardiac sodium channels.

With excessive or prolonged use, the drug can cause itching, tachycardia, hallucinations, and paranoid delusions.
Overdoses cause hyperthermia and a marked elevation of blood pressure, which can be life-threatening, arrhythmias, and death.
   --------------------------------------- */
*/
/* ._.-'~'-._.-'~'-._.-'~'-._.-'~'-._.-'~'-._.-'~'-._.-'~'-._. */
/*-=-=-=-=-=-=-=-=-=-=-=-MEDICALPROBLEMS-=-=-=-=-=-=-=-=-=-=-=-*/
/* '~'-._.-'~'-._.-'~'-._.-'~'-._.-'~'-._.-'~'-._.-'~'-._.-'~' */
/*
From Ali0en's thread here: http://forum.ss13.co/viewtopic.php?f=6&t=4732
note: I'm gunna dump a bunch more info than needed in here so it's gunna SOUND like I want to simulate all of these to hell and back
I don't though, simplification of this stuff is important for goonstation, I just like having the info around because I'm a mild medical nerd (fyi (I kno u r shoked))

- Seizures: Makes people flop around like a fish or, in minor cases, stare off into space

- Aneurisms: Some chems to relax veins or surgery to install shunts/grafts. Causes internal bleeding, vomiting, and seizures

- Embolisms: Cause blood problems due to poor circulation

- Internal bleeding: Bleeding inside

- Strokes: Disables use of one side of the body (arms and leg, just as if amputated) until remedied, can be temporary and rather harmless or lethal. Bad cases should give players the mutant face to simulate facial droop
http://en.wikipedia.org/wiki/Stroke
http://en.wikipedia.org/wiki/Transient_ischemic_attack
"Stroke, also known as cerebrovascular accident (CVA), cerebrovascular insult (CVI), or brain attack" lol
two kinds:
	ischemic, due to lack of blood to the brain (due to thromboses, embolisms, general decrease in blood in the body - ex shock)
		types:
			total anterior (TACI)
			partial anterior (PACI)
			lacunar (LACI)
			posterior (POCI)
			all of which have similar but slightly different symptoms
		"Users of stimulant drugs such as cocaine and methamphetamine are at a high risk for ischemic strokes."
	hemorrhagic, due to too much blood accumulating in one place (usually due to injuries to the head)
		major types:
			intra-axial (cerebral hemorrhage/hematoma) (blood in the brain tissue itself)
			extra-axial (intracranial hemorrhage) (blood within the skull, outside the brain)
				epidural (between skull and dura mater)
				subdural (between dura mater and brain)
				subarachnoid (between arachnoid mater and pia mater) (may be considered a subtype of subdural?  may not, not entirely clear on this)
				(I'm sure there's all sorts of combos of meninges for these things but these are the notable ones, apparently)
		"Anticoagulant therapy, as well as disorders with blood clotting can heighten the risk that an intracranial hemorrhage will occur."
		"Factors increasing the risk of a subdural hematoma include very young or very old age."
		"Other risk factors for subdural bleeds include taking blood thinners (anticoagulants), long-term alcohol abuse, and dementia."
"The main risk factor for stroke is high blood pressure."
"Other risk factors include tobacco smoking, obesity, high blood cholesterol, diabetes, previous TIA, and atrial fibrillation among others."
symptoms:
	inability to move or feel on one side of the body
	problems understanding or speaking
	feeling like the world is spinning
	loss of one vision to one side
thoughts: a old-style disease with some vars to determine the kind - ischemic/hemorrhagic, which side it affects, etc.
	don't need to get real involved with the types or anything but maybe minor differences in symptoms
treatments:
	ischemic: aspirin (salicylic acid in our case) helps break down clots, if caused by lack of blood in general a transfusion would help
	hemorrhagic: surgery to drain the blood seems to be about it

- Congestive heart failure: Vomiting blood (or pink vomit) and oxy damage. Requires a new heart (I think something like that is already in but expand on it)

- Type 1 Diabetes: Patient needs insulin injections whenever they eat, make some pumps for advanced robotics stuff

- Pacemakers: Make them implants that auto-defib someone for a limited time, or at a weak amount
*/