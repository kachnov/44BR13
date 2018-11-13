/* Hello these are the new logs wow gosh look at this isn't it exciting
Some placeholders exist for replacement within text:
	%target% - Replaced by a link + traitor info for the name

Example in-game log call:
		logTheThing("admin", src, M, "shot that nerd %target% at [showCoords(usr.x, usr.y, usr.z)]")
Example out of game log call:
		logTheThing("diary", src, null, "gibbed everyone ever", "admin")
*/
/proc/logTheThing(type, source, target, text, diaryType)
	var/diaryLogging

	if (source)
		source = constructName(source, type)
	else
		if (type != "diary") source = "<span class='blank'>(blank)</span>"

	if (target) //If we have a target we assume the text has a %target% placeholder to shove it in
		if (type == "diary") target = constructName(target, type)
		else target = "<span class='target'>[constructName(target, type)]</span>"
		text =  replacetext(text, "%target%", target)

	var/ingameLog = "<td class='duration'>[round(((world.time / 10) / 60))]M</td><td class='source'>[source]</td><td class='text'>[text]</td>"
	switch(type)
		//These are things we log in-game (accessible via the Secrets menu)
		if ("admin") logs["admin"] += ingameLog
		if ("admin_help") logs["admin_help"] += ingameLog
		if ("mentor_help") logs["mentor_help"] += ingameLog
		if ("say") logs["speech"] += ingameLog
		if ("ooc") logs["ooc"] += ingameLog
		if ("whisper") logs["speech"] += ingameLog
		if ("station") logs["station"] += ingameLog
		if ("combat") logs["combat"] += ingameLog
		if ("telepathy") logs["telepathy"] += ingameLog
		if ("debug") logs["debug"] += ingameLog
		if ("wiredebug") logs["wire_debug"] += ingameLog
		if ("pdamsg") logs["pdamsg"] += ingameLog
		if ("signalers") logs["signalers"] += ingameLog
		if ("bombing") logs["bombing"] += ingameLog
		if ("atmos") logs["atmos"] += ingameLog
		if ("pathology") logs["pathology"] += ingameLog
		if ("deleted") logs["deleted"] += ingameLog
		if ("vehicle") logs["vehicle"] += ingameLog
		if ("diary")
			switch (diaryType)
				//These are things we log in the out of game logs (the diary)
				if ("admin") if (config.log_admin) diaryLogging = 1
				if ("ahelp") if (config.log_say) diaryLogging = 1 //log_ahelp
				if ("mhelp") if (config.log_say) diaryLogging = 1 //log_mhelp
				if ("game") if (config.log_game) diaryLogging = 1
				if ("vote") if (config.log_vote) diaryLogging = 1
				if ("access") if (config.log_access) diaryLogging = 1
				if ("say") if (config.log_say) diaryLogging = 1
				if ("ooc") if (config.log_ooc) diaryLogging = 1
				if ("whisper") if (config.log_whisper) diaryLogging = 1
				if ("station") if (config.log_station) diaryLogging = 1
				if ("combat") if (config.log_combat) diaryLogging = 1
				if ("telepathy") if (config.log_telepathy) diaryLogging = 1
				if ("debug") if (config.log_debug) diaryLogging = 1
				if ("vehicle") if (config.log_vehicles) diaryLogging = 1


	if (diaryLogging)
		diary << "[time2text(world.timeofday, "\[hh:mm:ss\]")] [uppertext(diaryType)]: [source ? "[source] ": ""][text]"

	return

/proc/constructName(ref, type)
	var/name
	var/ckey
	var/key
	var/traitor
	var/online
	var/dead = 1
	var/mobType

	var/mob/mobRef
	if (ismob(ref))
		mobRef = ref
		traitor = checktraitor(mobRef)
		if (mobRef.real_name)
			name = mobRef.real_name
		if (mobRef.key)
			key = mobRef.key
		if (mobRef.ckey)
			ckey = mobRef.ckey
		if (mobRef.client)
			online = 1
		if (mobRef.stat != 2)
			dead = 0
	else if (istype(ref,/client))
		var/client/clientRef = ref
		online = 1
		if (clientRef.mob)
			mobRef = clientRef.mob
			traitor = checktraitor(mobRef)
			if (mobRef.real_name)
				name = clientRef.mob.real_name
			if (mobRef.stat != 2)
				dead = 0
		if (clientRef.key)
			key = clientRef.key
		if (clientRef.ckey)
			ckey = clientRef.ckey
	else
		return ref

	if (mobRef)
		if (ismonkey(mobRef)) mobType = "Monkey"
		else if (isrobot(mobRef)) mobType = "Robot"
		else if (isshell(mobRef)) mobType = "AI Shell"
		else if (isAI(mobRef)) mobType = "AI"
		else if (!ckey) mobType = "NPC"

	var/data
	if (name)
		if (type == "diary")
			data += name
		else
			data += "<span class='name'>[name]</span>"
	if (mobType)
		data += " ([mobType])"
	if (ckey && key)
		if (type == "diary")
			data += "[name ? " (" : ""][key][name ? ")" : ""]"
		else
			data += "[name ? " (" : ""]<a href='?src=%admin_ref%;action=adminplayeropts;targetckey=[ckey]' title='Player Options'>[key]</a>[name ? ")" : ""]"
	if (traitor)
		if (type == "diary")
			data += " \[TRAITOR\]"
		else
			data += " \[<span class='traitorTag'>T</span>\]"
	if (type != "diary" && !online && ckey)
		data += " \[<span class='offline'>OFF</span>\]"
	if (dead && ticker && ticker.current_state && ticker.current_state > GAME_STATE_PREGAME)
		if (type == "diary")
			data += " \[DEAD\]"
		else
			data += " \[<span class='text-red'>DEAD</span>\]"
	return data

/proc/log_shot(var/obj/projectile/P,var/obj/SHOT, var/target_is_immune = 0)
	if (!P || !SHOT)
		return
	var/shooter_data = null
	var/vehicle
	if (P.mob_shooter)
		shooter_data = P.mob_shooter
	else if (ismob(P.shooter))
		var/mob/M = P.shooter
		shooter_data = M
	var/obj/machinery/vehicle/V
	if (istype(P.shooter,/obj/machinery/vehicle))
		V = P.shooter
		if (!shooter_data)
			shooter_data = V.pilot
		vehicle = 1
	//Wire: Added this so I don't get a bunch of logs for fukken drones shooting pods WHO CARES
	if (istype(P.shooter, /obj/critter))
		return
	logTheThing("combat", shooter_data, SHOT, "[vehicle ? "driving [V.name] " : ""]shoots %target%[P.was_pointblank != 0 ? " point-blank" : ""][target_is_immune ? " (immune due to spellshield/nodamage)" : ""] at [log_loc(SHOT)]. <strong>Projectile:</strong> <em>[P.name]</em>[P.proj_data && P.proj_data.type ? ", <strong>Type:</strong> [P.proj_data.type]" :""]")

/proc/log_reagents(var/atom/A as turf|obj|mob)
	var/log_reagents = ""
	// In case we don't get a physical reagent holder. Required for chemSmoke particles (Convair880).
	if (!isnull(A) && istype(A, /reagents))
		var/reagents/R = A
		for (var/current_id in R.reagent_list)
			var/reagent/current_reagent = R.reagent_list[current_id]
			log_reagents += " [current_reagent] ([current_reagent.volume]),"
		if (log_reagents == "") log_reagents = "Nothing "
		var/final_log = copytext(log_reagents, 1, -1)
		return "(<strong>Contents:</strong> <em>[final_log]</em>. <strong>Temp:</strong> <em>[R.total_temperature] K</em>)"
	if (!A)
		return "(<strong>Error:</strong> <em>no source provided</em>)"
	if (!A.reagents)
		return "(<em>[A] has no reagent holder</em>)"
	if (!A.reagents.total_volume)
		return "(<strong>Contents:</strong> <em>nothing</em>)"
	for (var/current_id2 in A.reagents.reagent_list)
		var/reagent/current_reagent2 = A.reagents.reagent_list[current_id2]
		log_reagents += " [current_reagent2] ([current_reagent2.volume]),"
	var/final_log2 = copytext(log_reagents, 1, -1)
	return "(<strong>Contents:</strong> <em>[final_log2]</em>. <strong>Temp:</strong> <em>[A.reagents.total_temperature] K</em>)" // Added temperature. Even non-lethal chems can be harmful at unusually low or high temperatures (Convair880).

/proc/log_loc(var/atom/A as turf|obj|mob)
	if (!istype(A))
		return
	var/turf/our_turf = null
	if (!isturf(A.loc))
		our_turf = get_turf(A)
	return "([our_turf ? "[showCoords(our_turf.x, our_turf.y, our_turf.z)]" : "[showCoords(A.x, A.y, A.z)]"] in [get_area(A)])"

// Does what is says on the tin. We're using the global proc, though (Convair880).
/proc/log_atmos(var/atom/A as turf|obj|mob)
	return scan_atmospheric(A, 0, 1)