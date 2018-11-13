/////////////////////////////////////// General Announcement Computer

/obj/machinery/computer/announcement
	name = "Announcement Computer"
	icon_state = "comm"
	var/last_announcement = 0
	var/announcement_delay = 1200
	var/obj/item/card/id/ID = null
	var/unlocked = 0
	var/status = "Insert Card"
	var/message = ""
	var/inhibit_updates = 0
	var/announces_arrivals = 0
	var/arrival_announcements_enabled = 1
	var/say_language = "english"
	var/arrivalalert = "$NAME has signed up as $JOB."
	var/obj/item/device/radio/intercom/announcement_radio = null
	var/voice_message = "broadcasts"
	req_access = list(access_heads)

	New()
		..()
		if (announces_arrivals)
			announcement_radio = new(src)

	process()
		if (!inhibit_updates) updateUsrDialog()

	attack_hand(mob/user)
		if (..()) return
		user.machine = src
		var/dat = {"
			<body>
				<h1>Announcement Computer</h1>
				<hr>
				Status: [status]<BR>
				Card: <a href='?src=\ref[src];card=1'>[ID ? ID.name : "--------"]</a><br>
				Broadcast delay: [nice_timer()]<br>
				<br>
				Message: "<a href='?src=\ref[src];edit_message=1'>[message ? message : "___________"]</a>" <a href='?src=\ref[src];clear_message=1'>(Clear)</a><br>
				<br>
				<strong><a href='?src=\ref[src];send_message=1'>Transmit</a></strong>
			"}
		if (announces_arrivals)
			dat += "<hr>[arrival_announcements_enabled ? "Arrival Announcement Message: \"[arrivalalert]\"<br><br><strong><a href='?src=\ref[src];set_arrival_message=1'>Change</a></strong><br><strong><a href='?src=\ref[src];toggle_arrival_message=1'>Disable</a></strong>" : "Arrival Announcements Disabled<br><br><strong><a href='?src=\ref[src];toggle_arrival_message=1'>Enable</a></strong>"]"
		dat += "</body>"
		user << browse(dat, "window=announcementcomputer")
		onclose(user, "announcementcomputer")

	Topic(href, href_list[])
		if (..()) return

		if (href_list["card"])
			if (ID)
				ID.set_loc(loc)
				ID = null
				unlocked = 0
			else
				var/obj/item/I = usr.equipped()
				if (istype(I, /obj/item/card/id))
					usr.drop_item()
					I.set_loc(src)
					ID = I
					unlocked = check_access(ID, 1)

		else if (href_list["edit_message"])
			inhibit_updates = 1
			message = copytext( html_decode(trim(strip_html(html_decode(input("Select what you wish to announce.", "Announcement."))))), 1, 140 )
			if (url_regex && url_regex.Find(message)) message = ""
			inhibit_updates = 0

		else if (href_list["clear_message"])
			message = ""

		else if (href_list["send_message"])
			send_message(usr)

		else if (href_list["set_arrival_message"])
			inhibit_updates = 1
			set_arrival_alert(usr)
			inhibit_updates = 0

		else if (href_list["toggle_arrival_message"])
			arrival_announcements_enabled = !(arrival_announcements_enabled)
			boutput(usr, "Arrival announcements [arrival_announcements_enabled ? "en" : "dis"]abled.")

		update_status()
		updateUsrDialog()

	proc/update_status()
		if (!ID)
			status = "Insert Card"
		else if (!unlocked)
			status = "Insufficient Access"
		else if (!message)
			status = "Input message."
		else if (get_time() > 0)
			status = "Broadcast delay in effect."
		else
			status = "Ready to transmit!"

	proc/send_message(var/mob/user)
		if (!message || !unlocked || get_time() > 0) return
		var/area/A = get_area(src)

		logTheThing("say", user, null, "created a command report: [message]")
		logTheThing("diary", user, null, "created a command report: [message]", "say")

		command_announcement(message, "[A.name] Announcement by [ID.registered] ([ID.assignment])")
		last_announcement = world.timeofday
		message = ""

	proc/nice_timer()
		if (world.timeofday < last_announcement)
			last_announcement = 0
		var/time = get_time()
		if (time < 0)
			return "--:--"
		else
			var/seconds = time % 60
			var/minutes = round((time - seconds) / 60)
			minutes = minutes < 10 ? "0[minutes]" : "[minutes]"
			seconds = seconds < 10 ? "0[seconds]" : "[seconds]"

			return "[minutes][seconds % 2 == 0 ? ":" : " "][seconds]"

	proc/get_time()
		return max(((last_announcement + announcement_delay) - world.timeofday ) / 10, 0)

	proc/set_arrival_alert(var/mob/user)
		if (!user)
			return
		var/newalert = input(user,"Please enter a new arrival alert message. Valid tokens: $NAME, $JOB, $STATION", "Custom Arrival Alert", arrivalalert) as null|text
		if (!newalert)
			return
		if (!findtext(newalert, "$NAME"))
			user.show_text("The alert needs at least one $NAME token.", "red")
			return
		if (!findtext(newalert, "$JOB"))
			user.show_text("The alert needs at least one $JOB token.", "red")
			return
		arrivalalert = sanitize(adminscrub(newalert, 200))
		logTheThing("station", user, src, "sets the arrival announcement on %target% to \"[arrivalalert]\"")
		user.show_text("Arrival alert set to '[newalert]'", "blue")
		return

	proc/say_quote(var/text)
		return "[voice_message], \"[text]\""

	proc/process_language(var/message)
		var/language/L = languages.language_cache[say_language]
		if (!L)
			L = languages.language_cache["english"]
		return L.get_messages(message)

	proc/announce_arrival(var/name, var/rank)
		if (!announces_arrivals)
			return TRUE
		if (!announcement_radio)
			announcement_radio = new(src)

		var/message = replacetext(replacetext(replacetext(arrivalalert, "$STATION", "[station_name()]"), "$JOB", rank), "$NAME", name)

		var/list/messages = process_language(message)
		announcement_radio.talk_into(src, messages, 0, name, say_language)
		logTheThing("station", src, null, "ANNOUNCES: [message]")
		return TRUE
