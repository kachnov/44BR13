/world
	mob = /mob/new_player
	turf = /turf/space
	area = /area
	view = "15x15"

	// hub stuff
	hub = "Exadv1.spacestation13"
	hub_password = "kMZy3U5jJHSiBQjr"
	name = "4chan Fortnite Battle Royale 13"

//
/world/proc/load_mode()
	var/text = file2text("data/mode.txt")
	if (text)
		var/list/lines = splittext(text, "\n")
		if (lines[1])
			master_mode = lines[1]
			diary << "Saved mode is '[master_mode]'"

/world/proc/save_mode(var/the_mode)
	var/F = file("data/mode.txt")
	fdel(F)
	F << the_mode

/world/proc/load_intra_round_value(var/field) //Currently for solarium effects, could also be expanded to that pickle jar idea.
	var/path = "data/intra_round.sav"

	if (!fexists(path))
		return null

	var/savefile/F = new /savefile(path, -1)
	F["[field]"] >> .

/world/proc/save_intra_round_value(var/field, var/value)
	if (!field || isnull(value))
		return -1

	var/savefile/F = new /savefile("data/intra_round.sav", -1)
	F.Lock(-1)

	F["[field]"] << value
	return FALSE

/world/proc/load_motd()
	join_motd = file2text("config/motd.txt")

/world/proc/load_rules()
	rules = file2text("config/rules.html")
	if (!rules)
		rules = "<html><head><title>Rules</title><body>There are no rules! Go nuts!</body></html>"

/world/proc/load_admins()
	var/text = file2text("config/admins.txt")
	if (!text)
		diary << "Failed to load config/admins.txt\n"
	else
		var/list/lines = splittext(text, "\n")
		for (var/line in lines)
			if (!line)
				continue

			if (copytext(line, 1, 2) == ";")
				continue

			var/pos = findtext(line, " - ", 1, null)
			if (pos)
				var/m_key = copytext(line, 1, pos)
				var/a_lev = copytext(line, pos + 3, length(line) + 1)
				admins[m_key] = a_lev
				diary << ("ADMIN: [m_key] = [a_lev]")

// dsingh for faster create panel loads
/world/proc/precache_create_txt()
	if (!create_mob_html)
		var/mobjs = null
		mobjs = jointext(typesof(/mob), ";")
		create_mob_html = grabResource("html/admin/create_object.html")
		create_mob_html = replacetext(create_mob_html, "null /* object types */", "\"[mobjs]\"")

	if (!create_object_html)
		var/objectjs = null
		objectjs = jointext(typesof(/obj), ";")
		create_object_html = grabResource("html/admin/create_object.html")
		create_object_html = replacetext(create_object_html, "null /* object types */", "\"[objectjs]\"")

	if (!create_turf_html)
		var/turfjs = null
		turfjs = jointext(typesof(/turf), ";")
		create_turf_html = grabResource("html/admin/create_object.html")
		create_turf_html = replacetext(create_turf_html, "null /* object types */", "\"[turfjs]\"")

// drsingh for faster ban panel loads
//Wire note: this has been gutted to only do stuff for jobbans until I get round to converting that system
/world/proc/precache_unban_txt()
	building_jobbans = 1

	global_jobban_cache_built = world.timeofday

	var/buf = ""
	jobban_count = 0
	for (var/t in jobban_keylist) if (t)
		jobban_count++
		buf += text("[t];")

	global_jobban_cache = buf
	global_jobban_cache_rev = 1

	building_jobbans = 0

/world/proc/load_testers()
	var/text = file2text("config/testers.txt")
	if (!text)
		diary << "Failed to load config/testers.txt\n"
	else
		var/list/lines = splittext(text, "\n")
		for (var/line in lines)
			if (!line)
				continue

			if (copytext(line, 1, 2) == ";")
				continue

			var/pos = findtext(line, " - ", 1, null)
			if (pos)
				var/m_key = copytext(line, 1, pos)
				var/a_lev = copytext(line, pos + 3, length(line) + 1)
				admins[m_key] = a_lev

var/f_color_selector_handler/F_Color_Selector = null

/proc/buildMaterialCache()
	//material_cache
	var/materialList = subtypesof(/material)
	for (var/mat in materialList)
		var/material/M = new mat()
		material_cache.Add(M.mat_id)
		material_cache[M.mat_id] = M
	return

/proc/connectDB()
	set background = 1
	/* Old remote-mysql connection stuff
	if (config.sql_enabled)
		dbcon = new()
		var/dbi = "dbi:mysql:[config.sql_database]:[config.sql_hostname]:[config.sql_port]"
		dbcon.Connect(dbi, "[config.sql_username]", "[config.sql_password]")
		if (!dbcon.IsConnected())
			logTheThing("admin", null, null, "<strong>Failed to connect to central database:</strong> [dbcon.ErrorMsg()]")
			logTheThing("diary", null, null, "Failed to connect to central database: [dbcon.ErrorMsg()]", "admin")
		else
			logTheThing("admin", null, null, "<strong>Connected to central database</strong>")
			logTheThing("diary", null, null, "Connected to central database", "admin")
	*/


//Called BEFORE the map loads. Useful for objects that require certain things be set during init
/preMapLoad
/preMapLoad/New()
	config = new /configuration()
	config.load("config/config.txt")

	if (config.server_specific_configs && world.port > 0)
		var/specific_config = "config/config-[world.port].txt"
		if (fexists(specific_config))
			config.load(specific_config)

	// apply some settings from config..
	abandon_allowed = config.respawn
	cdn = config.cdn
	disableResourceCache = config.disableResourceCache


/world/New()
	..()
	
	tick_lag = 0.5
//	loop_checks = 0

	diary = file("data/logs/[time2text(world.realtime, "YYYY/MM-Month/DD-Day")].log")
	diary << ""
	diary << ""
	diary << "Starting up. [time2text(world.timeofday, "hh:mm.ss")]"
	diary << "---------------------"
	diary << ""

	changelog = new /changelog()
	admin_changelog = new /admin_changelog()

	if (!delete_queue)
		delete_queue = new /dynamicQueue(100)

	initLimiter()

	F_Color_Selector = new()
	buildMaterialCache()
	create_named_colors()

	#ifdef DATALOGGER
	game_stats = new
	#endif

	radio_controller = new /controller/radio()

	sun = new /sun()

	vote = new /vote()

	data_core = new /obj/datacore()

	init_vox()
	if (load_intra_round_value("solarium_complete") == 1)
		derelict_mode = 1
		was_eaten = world.load_intra_round_value("somebody_ate_the_fucking_thing")
		save_intra_round_value("solarium_complete", 0)
		save_intra_round_value("somebody_ate_the_fucking_thing", 0)

	// Must go after data_core
	get_all_functional_reagent_ids()
	wagesystem = new /wage_system()
	shippingmarket = new /shipping_market()
	hydro_controls = new /hydroponics_controller()
	job_controls = new /job_controller()
	manuf_controls = new /manufacturing_controller()
	random_events = new /event_controller()
	disease_controls = new /disease_controller()
	mechanic_controls = new /mechanic_controller()
	artifact_controls = new /artifact_controller()
	mining_controls = new /mining_controller()
	actions = new/action_controller()
	explosions = new/explosion_controller()

	if (config.env == "dev") //WIRE TODO: Only do this (fallback to local files) if the coder testing has no internet
		recursiveFileLoader("browserassets/")

	if (config)
		if (config.server_name != null && config.server_region != null)
			config.server_name += " [config.server_region]"

		if (config.server_name != null && config.server_suffix && world.port > 0)
			config.server_name += " [(world.port % 1000) / 100]"

		jobban_loadbanfile()
		jobban_updatelegacybans()

		oocban_loadbanfile()
		oocban_updatelegacybans()

		precache_unban_txt() //Wire: left in for now because jobbans still use the shitty system
		precache_create_txt()

	load_mode()
	load_motd()
	load_rules()
	load_admins()

	//create_random_station() //--Disabled because it's making initial geometry stuff take forever. Feel free to re-enable it if it's just throwing off the time count and not actually adding workload.

	makepowernets()

	materialsResearch = new()
	materialsResearch.setup()

	tele_man = new()
	tele_man.setup()

	for (var/A in (subtypesof(/material_recipe))) //Caching material recipes.
		var/material_recipe/R = new A()
		materialRecipes.Add(R)

	for (var/A in (subtypesof(/achievementReward))) //Caching reward datums.
		var/achievementReward/R = new A()
		rewardDB.Add(R.type)
		rewardDB[R.type] = R

	for (var/A in (subtypesof(/obj/trait))) //Creating trait objects. I hate this.
		var/obj/trait/T = new A( )
		traitList.Add(T.id)
		traitList[T.id] = T

	var/list/bioEffect/tempBioList = subtypesof(/bioEffect)
	for (var/effect in tempBioList)
		var/bioEffect/E = new effect(1)
		bioEffectList[E.id] = E        //Caching instances for easy access to rarity and such. BECAUSE THERES NO PROPER CONSTANTS IN BYOND.
		E.dnaBlocks.GenerateBlocks()     //Generate global sequence for this effect.

	// Set this stupid shit up here because byond's object tree output can't
	// cope with a list initializer that contains "[constant]" keys
	headset_channel_lookup = list("[R_FREQ_RESEARCH]"="Research","[R_FREQ_MEDICAL]"="Medical","[R_FREQ_ENGINEERING]"="Engineering", "[R_FREQ_COMMAND]"="Command","[R_FREQ_SECURITY]"="Security","[R_FREQ_CIVILIAN]"="Civilian")

	//screenOverlayLibrary ov1
	var/overlayList = subtypesof(/overlayComposition)
	for (var/over in overlayList)
		var/overlayComposition/E = new over()
		screenOverlayLibrary.Add(over)
		screenOverlayLibrary[over] = E

	plmaster = new /obj/overlay(  )
	plmaster.icon = 'icons/effects/tile_effects.dmi'
	plmaster.icon_state = "plasma"
	plmaster.layer = FLY_LAYER
	plmaster.mouse_opacity = 0

	slmaster = new /obj/overlay(  )
	slmaster.icon = 'icons/effects/tile_effects.dmi'
	slmaster.icon_state = "sleeping_agent"
	slmaster.layer = FLY_LAYER
	slmaster.mouse_opacity = 0

	/*
	w1master = new /obj/overlay(  )
	w1master.icon = 'icons/effects/tile_effects.dmi'
	w1master.icon_state = "water1"
	w1master.layer = TURF_LAYER + 0.1
	w1master.mouse_opacity = 0

	w2master = new /obj/overlay(  )
	w2master.icon = 'icons/effects/tile_effects.dmi'
	w2master.icon_state = "water2"
	w2master.layer = OBJ_LAYER + 0.5
	w2master.mouse_opacity = 0

	w3master = new /obj/overlay(  )
	w3master.icon = 'icons/effects/tile_effects.dmi'
	w3master.icon_state = "water3"
	w3master.layer = FLY_LAYER
	w3master.mouse_opacity = 0
	*/

	spawn (world.tick_lag)
		processScheduler = new
		processScheduler.deferSetupfor (/controller/process/ticker)
		processSchedulerView = new

		for (var/area/Ar in world)
			Ar.build_sims_score()
			LAGCHECK(50)

		url_regex = new("(https?|byond|www)(\\.|:\\/\\/)", "i")

		processScheduler.setup()

		update_status()

		ircbot.event("serverstart")
		
		round_start_data() //Tell the hub site a round is starting
		if (time2text(world.realtime,"DDD") == "Fri")
			NT |= mentors

	

	spawn (world.tick_lag*30)
		Optimize()
		sleep_offline = 1

		for (var/turf/simulated/wall/supernorn/T in world) // workaround for some strange bug
			T.update_icon()
			LAGCHECK(50)
		RL_Start()

		load_intraround_jars()

		//Local bans db automatic expiry stuff
		var/list/clearResponse = clearTempBansApiFallback() //The remote db keeps itself clean :giggity:
		if (clearResponse["error"])
			logTheThing("debug", null, null, "<strong>Local API Error</strong> - Callback failed in <strong>clearTempBansApiFallback</strong> with message: <strong>[clearResponse["error"]]</strong>")
			logTheThing("diary", null, null, "<strong>Local API Error</strong> - Callback failed in clearTempBansApiFallback with message: [clearResponse["error"]]", "debug")
		var/clearCount = clearResponse["cleared"]
		if (text2num(clearCount) > 0)
			logTheThing("debug", null, null, "<strong>Local Bans</strong>: Cleared [clearCount] expired temporary bans")
			logTheThing("diary", null, null, "Local Bans: Cleared [clearCount] expired temporary ban/s", "debug")

		/*
		var/banParity = bansParityCheck()
		if (banParity)
			logTheThing("debug", null, null, "<strong>Ban DB Parity</strong>: [banParity]")
			logTheThing("diary", null, null, "Ban DB Parity: [banParity]", "debug")
		*/

		if (derelict_mode)
			creepify_station()
			voidify_world()
			solar_flare = 1 // heh
			bust_lights()
			master_mode = "disaster" // heh pt. 2

		//SpyStructures and caches live here
		build_chem_structure()
		build_reagent_cache()
		build_supply_pack_cache()
		build_syndi_buylist_cache()
		build_camera_network()

	return


//Crispy fullban
/proc/Reboot_server()
	processScheduler.stop()

	save_intraround_jars()
	if (ticker && ticker.current_state < GAME_STATE_FINISHED)
		ticker.current_state = GAME_STATE_FINISHED

	spawn (world.tick_lag)
		for (var/mob/M in mobs)
			if (M.client)
			/*
				if (prob(40))
					M << sound(pick('sound/misc/NewRound2.ogg', 'sound/misc/NewRound3.ogg', 'sound/misc/NewRound4.ogg'))
				else*/

				// sick that tony
				M << sound('sound/misc/NewRound.ogg')

				//Tell client browserOutput that a restart is happening RIGHT NOW
				ehjax.send(M.client, "browseroutput", "roundrestart")

	#ifdef DATALOGGER
	spawn (world.tick_lag*2)
		var/playercount = 0
		var/admincount = 0
		for (var/client/C)
			if (C.mob)
				if (C.holder)
					admincount++
				playercount++
		game_stats.SetValue("players", playercount)
		game_stats.SetValue("admins", admincount)
		//game_stats.WriteToFile("data/game_stats.txt")
	#endif

	sleep(50) // wait for sound to play
	if (config.update_check_enabled)
		world.installUpdate()

	world.Reboot()

/world/proc/update_status()
	var/s = ""

	#define NEW_HEADER_BECAUSE_THE_OLD_ONE_DOES_NOT_FIT_FUCKING_BYOND_REE
	#ifdef NEW_HEADER_BECAUSE_THE_OLD_ONE_DOES_NOT_FIT_FUCKING_BYOND_REE
	s += "<big><big><strong><a href=\"https://discord.gg/zrr9wYf\">Fortnite 4chan Battle Royale 13</a></strong> &#8212; </big></big><br>"
	#else
	if (config && config.server_name)
		s += "<strong>[config.server_name]</strong> &#8212; "
	if (ticker && ticker.mode)
		s += "<big><strong>[istype(ticker.mode, /game_mode/construction) ? "Construction Mode" : station_name()]</strong></big>";
	else
		s += "<big><strong>[station_name()]</strong></big>";
	s += " ("
	s += "<a href=\"https://discord.gg/zrr9wYf\">"
	s += "DISCORD"
	s += "</a>"
	s += "): "
	#endif
	#undef NEW_HEADER_BECAUSE_THE_OLD_ONE_DOES_NOT_FIT_FUCKING_BYOND_REE

	var/list/features = list()

	if (!ticker)
		features += "<strong>STARTING</strong>"

	if (ticker && master_mode)
		if (ticker.hide_mode)
			features += "secret"
		else
			features += replacetext(master_mode, "44BR13", "battle royale")

	if (!enter_allowed)
		features += "closed"

	if (abandon_allowed)
		features += "respawn"

	if (config && config.allow_vote_mode)
		features += "vote"

/* this is utterly pointless - Kachnov
	var/n = 0
	for (var/mob/M in mobs)
		if (M.client)
			n++

	features += "[n] player[n != 1 ? "s" : ""]"
*/
	if (!host && config && config.hostedby)
		features += "hosted by <strong>[config.hostedby]</strong>"

	if (features)
		s += jointext(features, ", ")

	s += "<img src = \"https://bit.ly/2z1Dsra\"></img>"

	status = s

/world/proc/installUpdate()
	// Simple check to see if a new dmb exists in the update folder
	logTheThing("diary", null, null, "Checking for updated [config.dmb_filename].dmb...", "admin")
	if (fexists("update/[config.dmb_filename].dmb"))
		logTheThing("diary", null, null, "Updated [config.dmb_filename].dmb found. Updating...", "admin")
		for (var/f in flist("update/"))
			logTheThing("diary", null, null, "\tMoving [f]...", "admin")
			fcopy("update/[f]", "[f]")
			fdel("update/[f]")

		// Delete .dyn.rsc so that stupid shit doesn't happen
		fdel("[config.dmb_filename].dyn.rsc")

		logTheThing("diary", null, null, "Update complete.", "admin")
	else
		logTheThing("diary", null, null, "No update found. Skipping update process.", "admin")

/world/Topic(T, addr, master, key)
	diary << "TOPIC: \"[T]\", from:[addr], master:[master], key:[key]"

	if (T == "ping")
		var/x = 1
		for (var/client/C)
			x++
		return x

	else if (T == "players")
		var/n = 0
		for (var/mob/M in mobs)
			if (M.client)
				n++
		return n

	else if (T == "admins")
		var/list/s = list()
		var/n = 0
		for (var/mob/M in mobs)
			if (M && M.client && M.client.holder && !M.client.stealth)
				s["admin[n]"] = M.client.key
				n++
		s["admins"] = n
		return list2params(s)

	else if (T == "mentors")
		var/list/s = list()
		var/n = 0
		for (var/mob/M in mobs)
			if (M && M.client && !M.client.holder && M.client.mentor == 1)
				s["mentor[n]"] = M.client.key
				n++
		s["mentors"] = n
		return list2params(s)

	else if (T == "status")
		var/list/s = list()
		s["version"] = game_version
		s["mode"] = (ticker && ticker.hide_mode) ? "secret" : master_mode
		s["respawn"] = config ? abandon_allowed : 0
		s["enter"] = enter_allowed
		s["vote"] = config.allow_vote_mode
		s["ai"] = config.allow_ai
		s["host"] = host ? host : null
		s["players"] = list()
		var/shuttle
		if (emergency_shuttle)
			if (emergency_shuttle.location == 1) shuttle = 0 - emergency_shuttle.timeleft()
			else shuttle = emergency_shuttle.timeleft()
		else shuttle = "welp"
		s["shuttle_time"] = shuttle
		var/elapsed
		if (ticker && ticker.current_state < GAME_STATE_FINISHED)
			if (ticker.current_state == GAME_STATE_PREGAME) elapsed = "pre"
			else if (ticker.current_state > GAME_STATE_PREGAME) elapsed = round(ticker.round_elapsed_ticks / 10)
		else if (ticker && ticker.current_state == GAME_STATE_FINISHED) elapsed = "post"
		else elapsed = "welp"
		s["elapsed"] = elapsed
		var/n = 0
		for (var/mob/M in mobs)
			if (M.client)
				s["player[n]"] = "[(M.client.stealth || M.client.alt_key) ? M.client.fakekey : M.client.key]"
				n++
		s["players"] = n
		return list2params(s)

	else // IRC bot communication (or callbacks)
		var/list/plist = params2list(T)
		switch(plist["type"])
			if ("irc")
				var/nick = plist["nick"]
				var/msg = plist["msg"]
				msg = copytext(sanitize(msg), 1, MAX_MESSAGE_LEN)

				logTheThing("ooc", null, null, "IRC OOC: [nick]: [msg]")

				if (nick == "buttbot")
					for (var/obj/machinery/bot/buttbot/B in machines)
						if (B.on)
							B.speak(msg)
					return TRUE

				//This is important.
				else if (nick == "HeadSurgeon")
					for (var/obj/machinery/bot/medbot/head_surgeon/HS in machines)
						if (HS.on)
							HS.speak(msg)
					for (var/obj/item/clothing/suit/cardboard_box/head_surgeon/HS in world)
						HS.speak(msg)
					return TRUE

				return FALSE

			if ("ooc")
				var/nick = plist["nick"]
				var/msg = plist["msg"]

				msg = trim(copytext(sanitize(msg), 1, MAX_MESSAGE_LEN))
				logTheThing("ooc", nick, null, "OOC: [msg]")
				logTheThing("diary", nick, null, ": [msg]", "ooc")
				var/rendered = "<span class=\"adminooc\"><span class=\"prefix\">OOC:</span> <span class=\"name\">[nick]:</span> <span class=\"message\">[msg]</span></span>"

				for (var/client/C)
					if (C.preferences && !C.preferences.listen_ooc)
						continue
					boutput(C, rendered)

				var/ircmsg[] = new()
				ircmsg["msg"] = msg
				return ircbot.response(ircmsg)

			if ("asay")
				var/nick = plist["nick"]
				var/msg = plist["msg"]
				msg = trim(copytext(sanitize(msg), 1, MAX_MESSAGE_LEN))

				logTheThing("admin", null, null, "IRC ASAY: [nick]: [msg]")
				logTheThing("diary", null, null, "IRC ASAY: [nick]: [msg]", "admin")
				var/rendered = "<span class=\"admin\"><span class=\"prefix\">ADMIN IRC:</span> <span class=\"name\">[nick]:</span> <span class=\"message adminMsgWrap\">[msg]</span></span>"

				for (var/mob/M in mobs)
					if (M.client && M.client.holder)
						boutput(M, rendered)

				var/ircmsg[] = new()
				ircmsg["key"] = nick
				ircmsg["msg"] = msg
				return ircbot.response(ircmsg)

			if ("fpm")
				var/server_name = plist["server_name"]
				if (!server_name)
					server_name = "LLJK-???"
				var/nick = plist["nick"]
				var/msg = plist["msg"]
				msg = trim(copytext(sanitize(msg), 1, MAX_MESSAGE_LEN))

				logTheThing("admin", null, null, "[server_name] PM: [nick]: [msg]")
				logTheThing("diary", null, null, "[server_name] PM: [nick]: [msg]", "admin")
				var/rendered = "<span class=\"admin\"><span class=\"prefix\">[server_name] PM:</span> <span class=\"name\">[nick]:</span> <span class=\"message adminMsgWrap\">[msg]</span></span>"

				for (var/mob/M in mobs)
					if (M.client && M.client.holder)
						boutput(M, rendered)

				var/ircmsg[] = new()
				ircmsg["key"] = nick
				ircmsg["msg"] = msg
				return ircbot.response(ircmsg)

			if ("pm")
				var/nick = plist["nick"]
				var/msg = plist["msg"]
				var/who = lowertext(plist["target"])
				var/mob/F
				for (var/mob/M in mobs)
					if (M.ckey && (findtext(M.real_name, who) || findtext(M.ckey, who)))
						if (M.client)
							F = M
							boutput(M, "<span style=\"color:red\" class=\"bigPM\">Admin PM from-<strong><a href=\"byond://?action=priv_msg_irc&nick=[nick]\">[nick]</a> (IRC)</strong>: [msg]</span>")
							logTheThing("admin_help", null, M, "IRC: [nick] PM'd %target%: [msg]")
							logTheThing("diary", null, M, "IRC: [nick] PM'd %target%: [msg]", "ahelp")
							for (var/mob/K in mobs)
								if (K && K.client && K.client.holder && K.key != M.key)
									if (K.client.player_mode && !K.client.player_mode_ahelp)
										continue
									else
										boutput(K, "<font color='blue'><strong>PM: <a href=\"byond://?action=priv_msg_irc&nick=[nick]\">[nick]</a> (IRC) <i class='icon-arrow-right'></em> [key_name(M)]</strong>: [msg]</font>")
							break

				if (F)
					var/ircmsg[] = new()
					ircmsg["key"] = nick
					ircmsg["key2"] = (F.client != null && F.client.key != null) ? F.client.key : "*no client*"
					ircmsg["name2"] = (F.real_name != null) ? F.real_name : ""
					ircmsg["msg"] = html_decode(msg)
					return ircbot.response(ircmsg)
				else
					return FALSE

			if ("mentorpm")
				var/nick = plist["nick"]
				var/msg = plist["msg"]
				var/who = lowertext(plist["target"])
				var/mob/F
				for (var/mob/M in mobs)
					if (M.ckey && (findtext(M.real_name, who) || findtext(M.ckey, who)))
						if (M.client)
							F = M
							boutput(M, "<span style='color:[mentorhelp_text_color]'><strong>MENTOR PM: FROM <a href=\"byond://?action=mentor_msg_irc&nick=[nick]\">[nick]</a> (IRC)</strong>: <span class='message'>[msg]</span></span>")
							logTheThing("admin", null, M, "IRC: [nick] Mentor PM'd %target%: [msg]")
							logTheThing("diary", null, M, "IRC: [nick] Mentor PM'd %target%: [msg]", "admin")
							for (var/mob/K in mobs)
								if (K && K.client && ((K.client.mentor && K.client.see_mentor_pms) || K.client.holder) && K.key != M.key)
									if (K.client.holder)
										if (K.client.player_mode && !K.client.player_mode_mhelp)
											continue
										else
											boutput(K, "<span style='color:[mentorhelp_text_color]'><strong>MENTOR PM: [nick] (IRC) <i class='icon-arrow-right'></em> [key_name(M,0,0,1)][(M.real_name ? "/"+M.real_name : "")] <A HREF='?src=\ref[K.client.holder];action=adminplayeropts;targetckey=[M.ckey]' class='popt'><i class='icon-info-sign'></em></A></strong>: <span class='message'>[msg]</span></span>")
									else
										boutput(K, "<span style='color:[mentorhelp_text_color]'><strong>MENTOR PM: [nick] (IRC) <i class='icon-arrow-right'></em> [key_name(M,0,0,1)]</strong>: <span class='message'>[msg]</span></span>")
							break

				if (F)
					var/ircmsg[] = new()
					ircmsg["key"] = nick
					ircmsg["key2"] = (F.client != null && F.client.key != null) ? F.client.key : "*no client*"
					ircmsg["name2"] = (F.real_name != null) ? F.real_name : ""
					ircmsg["msg"] = html_decode(msg)
					return ircbot.response(ircmsg)
				else
					return FALSE

			if ("whois")
				var/who = plist["target"]
				var/whois = whois(who, 5)
				if (whois)
					var/list/parsedWhois = list()
					var/count = 0
					for (var/mob/M in whois)
						count++
						if (M.name) parsedWhois["name[count]"] = M.name
						if (M.key) parsedWhois["ckey[count]"] = M.key
						if (M.stat == 2) parsedWhois["dead[count]"] = 1
						if (M.mind && M.mind.assigned_role) parsedWhois["role[count]"] = M.mind.assigned_role
						if (checktraitor(M)) parsedWhois["t[count]"] = 1
					parsedWhois["count"] = count
					return ircbot.response(parsedWhois)
				else
					return FALSE
/*
			<ErikHanson> topic call, type=reboot reboots a server.. without a password, or any form of authentication.
			well there, i've fixed it. -drsingh

			if ("reboot")
				var/ircmsg[] = new()
				ircmsg["msg"] = "Attempting to restart now"

				Reboot_server()
				return ircbot.response(ircmsg)
*/
			if ("heal")
				var/nick = plist["nick"]
				var/who = lowertext(plist["target"])
				var/list/found = list()
				for (var/mob/M in mobs)
					if (M.ckey && (findtext(M.real_name, who) || findtext(M.ckey, who)))
						M.full_heal()
						logTheThing("admin", nick, M, "healed / revived %target%")
						logTheThing("diary", nick, M, "healed / revived %target%", "admin")
						message_admins("<span style=\"color:red\">Admin [nick] healed / revived [key_name(M)] from IRC!</span>")

						var/ircmsg[] = new()
						ircmsg["type"] = "heal"
						ircmsg["who"] = who
						ircmsg["msg"] = "Admin [nick] healed / revived [M.ckey]"
						found.Add(ircmsg)

				if (found && found.len > 0)
					return ircbot.response(found)
				else
					return FALSE

			if ("hubCallback")
				//logTheThing("debug", "<strong>Wire Debug:</strong> hubCallback hit from addr: [addr] with auth: [plist["auth"]] calling proc: [plist["proc"]] with data: [plist["data"]]")
				//world.log <<  "<strong>Wire Debug:</strong> hubCallback hit from addr: [addr] with auth: [plist["auth"]] calling proc: [plist["proc"]] with data: [plist["data"]]"

				if (addr != config.extserver_hostname) return FALSE //ip filtering
				var/auth = plist["auth"]
				if (auth != md5(config.extserver_token)) return FALSE //really bad md5 token security
				var/theProc = "/proc/[plist["proc"]]"
				var/list/ldata = parseCallbackData(plist["data"])

				var/rVal = call(theProc)(2, ldata) //calls the second stage of whatever proc specified
				if (rVal)
					logTheThing("debug", null, null, "<strong>Callback Error</strong> - Hub callback failed in <strong>[theProc]</strong> with message: <strong>[rVal]</strong>")
					logTheThing("diary", null, null, "<strong>Callback Error</strong> - Hub callback failed in [theProc] with message: [rVal]", "debug")
					return FALSE
				else
					return TRUE

			if ("roundEnd")
				//if (addr != config.extserver_hostname) return FALSE //ip filtering
				var/server = plist["server"]
				var/address = plist["address"]
				var/mode = plist["mode"]
				var/msg = "<br><div style='text-align: center; font-weight: bold;' class='deadsay'>---------------------<br>"
				msg += "A round just ended on LLJK#[server]<br>"
				msg += "It is running [mode]<br>"
				msg += "<a href='[address]'>Click here to join it</a><br>"
				msg += "---------------------</div><br>"
				for (var/mob/M in mobs)
					if (M.stat == 2)
						boutput(M, msg)

				return TRUE

			if ("mysteryPrint")
				if (addr != config.extserver_hostname) return FALSE //ip filtering
				var/msgTitle = plist["print_title"]
				var/msgFile = "strings/mysteryprint/"+plist["print_file"]
				if (!fexists(msgFile)) return FALSE
				var/msgText = file2text(msgFile)

				//Prints to every networked printer in the world
				for (var/obj/machinery/networked/printer/P in machines)
					P.print_buffer += "[msgTitle]&title;[msgText]"
					P.print()

				return TRUE

			//Tells shitbot what the current AI laws are (if there are any custom ones)
			if ("ailaws")
				if (ticker && ticker.current_state > GAME_STATE_PREGAME)
					var/list/laws = ticker.centralized_ai_laws.format_for_irc()
					return ircbot.response(laws)
				else
					return FALSE

			if ("health")
				var/ircmsg[] = new()
				ircmsg["cpu"] = world.cpu
				ircmsg["queue_len"] = delete_queue ? delete_queue.count() : 0
				var/curtime = world.timeofday
				sleep(10)
				ircmsg["time"] = (world.timeofday - curtime) / 10
				return ircbot.response(ircmsg)

			if ("rev")
				var/ircmsg[] = new()
				ircmsg["msg"] = "[svn_revision] by [svn_author]"
				return ircbot.response(ircmsg)


/// EXPERIMENTAL STUFF
var/opt_inactive = null
/world/proc/Optimize()
	spawn (0)
		if (!opt_inactive) opt_inactive  = world.timeofday

		if (world.timeofday - opt_inactive >= 600 || world.timeofday - opt_inactive < 0)
			KickInactiveClients()
			//if (mysql)
				//mysql.CleanQueries()
			opt_inactive = world.timeofday

		sleep(100)




/world/proc/KickInactiveClients()
	for (var/client/C in clients)
		if (!C.holder && ((C.inactivity/10)/60) >= 15)
			boutput(C, "<span style=\"color:red\">You have been inactive for more than 15 minutes and have been disconnected.</span>")
			del(C)

/// EXPERIMENTAL STUFF
