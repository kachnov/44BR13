/*********************************
Procs for handling ircbot connectivity and data transfer
*********************************/


var/global/ircbot/ircbot = new /ircbot()

/ircbot
	var/interface = null
	var/apikey = null
	var/loaded = 0
	var/loadTries = 0
	var/list/queue = list()
	var/debugging = 0

	New()
		if (!load())
			spawn (10)
				if (!loaded)
					load()

	proc
		//Load the config variables necessary for connections
		load()
			if (config)
				interface = config.irclog_url
				apikey = config.ircbot_api
				loaded = 1

				if (queue && queue.len > 0)
					if (debugging)
						logDebug("Load success, flushing queue: [json_encode(queue)]")
					for (var/x = 1, x <= src.queue.len, x++) //Flush queue
						export(queue[x]["iface"], queue[x]["args"])

				queue = null
				return TRUE
			else
				loadTries++
				if (loadTries >= 5)
					logTheThing("debug", null, null, "<strong>IRCBOT:</strong> Reached 5 failed config load attempts")
					logTheThing("diary", null, null, "<strong>IRCBOT:</strong> Reached 5 failed config load attempts", "debug")
				return FALSE


		//Shortcut proc for event-type exports
		event(type, data)
			if (!type) return FALSE
			var/list/eventArgs = list("type" = type)
			if (data) eventArgs["data"] = data
			return export("event", eventArgs)


		//Send a message to an irc bot! Yay!
		export(iface, args)
			if (debugging)
				logDebug("Export called with <strong>iface:</strong> [iface]. <strong>args:</strong> [list2params(args)]. <strong>interface:</strong> [interface]. <strong>loaded:</strong> [loaded]")

			if (!config || !loaded)
				queue += list(list("iface" = iface, "args" = args))

				if (debugging)
					logDebug("Export, message queued due to unloaded config")

				spawn (10)
					if (!loaded)
						load()
				return "queued"
			else
				if (config.env == "dev") return FALSE

				args = (args == null ? list() : args)
				args["server_name"] = (config.server_name ? replacetext(config.server_name, "#", "") : null)
				args["server"] = (world.port % 1000) / 100
				args["api_key"] = (apikey ? apikey : null)

				if (debugging)
					logDebug("Export, final args: [list2params(args)]. Final route: [interface]/[iface]?[list2params(args)]")

				var/http[] = world.Export("[interface]/[iface]?[list2params(args)]")
				if (!http || !http["CONTENT"])
					logTheThing("debug", null, null, "<strong>IRCBOT:</strong> No return data from export. <strong>iface:</strong> [iface]. <strong>args</strong> [list2params(args)]")
					return FALSE

				var/content = file2text(http["CONTENT"])

				if (debugging)
					logDebug("Export, returned data: [content]")

				//Handle the response
				var/list/contentJson = json_decode(content)
				if (!contentJson["status"])
					logTheThing("debug", null, null, "<strong>IRCBOT:</strong> Object missing status parameter in export response: [list2params(contentJson)]")
					return FALSE
				if (contentJson["status"] == "error")
					var/log = ""
					if (contentJson["errormsg"])
						log = "Error returned from export: [contentJson["errormsg"]][(contentJson["error"] ? ". Error code: [contentJson["error"]]": "")]"
					else
						log = "An unknown error was returned from export: [list2params(contentJson)]"
					logTheThing("debug", null, null, "<strong>IRCBOT:</strong> [log]")
				return TRUE


		//Format the response to an irc request juuuuust right
		response(args)
			if (debugging)
				logDebug("Response called with args: [list2params(args)]")

			args = (args == null ? list() : args)
			args["api_key"] = (apikey ? apikey : null)

			if (config && config.server_name)
				args["server_name"] = replacetext(config.server_name, "#", "")
				args["server"] = replacetext(config.server_name, "#", "") //TEMP FOR BACKWARD COMPAT WITH SHITFORMANT

			if (debugging)
				logDebug("Response, final args: [list2params(args)]")

			return list2params(args)


		toggleDebug(client/C)
			if (!C) return FALSE
			debugging = !debugging
			out(C, "IRCBot Debugging [(debugging ? "Enabled" : "Disabled")]")
			if (debugging)
				var/log = "Debugging Enabled. Datum variables are: "
				for (var/x = 1, x <= vars.len, x++)
					var/theVar = vars[x]
					if (theVar == "vars") continue
					var/contents
					if (islist(vars[theVar]))
						contents = list2params(vars[theVar])
					else
						contents = vars[theVar]
					log += "<strong>[theVar]:</strong> [contents] "
				logDebug(log)
			return TRUE


		logDebug(log)
			if (!log) return FALSE
			logTheThing("debug", null, null, "<strong>IRCBOT DEBUGGING:</strong> [log]")
			return TRUE


/client/proc/toggleIrcbotDebug()
	set name = "Toggle IRCBot Debug"
	set desc = "Enables in-depth logging of all IRC Bot exports and returns"
	set category = "Toggles"

	ADMIN_CHECK(src)

	ircbot.toggleDebug(src)
	return TRUE


/client/verb/linkNick(ircNick as text)
	set name = "Link IRC"
	set category = "Special Verbs"
	set desc = "Links your Byond username with your IRC nickname"
	set popup_menu = 0

	if (!ircNick)
		ircNick = input(src, "Please enter your IRC nickname", "Link IRC") as null|text

	if (ircbot.debugging)
		ircbot.logDebug("linkNick verb called. <strong>ckey:</strong> [ckey]. <strong>ircNick:</strong> [ircNick]")

	if (!ircNick || !ckey) return FALSE

	var/ircmsg[] = new()
	ircmsg["key"] = key
	ircmsg["ckey"] = ckey
	ircmsg["nick"] = ircNick
	var/res = ircbot.export("link", ircmsg)

	if (res)
		alert(src, "Linked Byond username: [key] with IRC nickname: [ircNick]. Please return to IRC and use !verify in #goonstation to continue.")
		return TRUE
	else
		alert(src, "An unknown internal error occurred. Please report this.")
		return FALSE
