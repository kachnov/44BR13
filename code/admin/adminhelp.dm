#define ADMINHELP_DELAY 30 // 3 seconds
////////////////////////////////
/mob/verb/adminhelp()
	set category = "Commands"
	set name = "adminhelp"

	if (IsGuestKey(key))
		boutput(src, "You are not authorized to communicate over these channels.")
		gib(src)
		return

	if (client.last_adminhelp > (world.timeofday - ADMINHELP_DELAY))
		if (abs(world.timeofday - client.last_adminhelp) < 1000) // some midnight rollover protection b/c byond is fucking stupid
			boutput(src, "You must wait [round((client.last_adminhelp + ADMINHELP_DELAY - world.timeofday)/10)] seconds before requesting help again.")
			return

	var/msg = input("Please enter your help request to admins:") as null|text

	msg = copytext(strip_html(msg), 1, MAX_MESSAGE_LEN)

	if (!msg)
		return

//	for_no_raisin(usr, msg)

	client.last_adminhelp = world.timeofday

	for (var/mob/M in mobs)
		if (M.client && M.client.holder)
			if (M.client.player_mode && !M.client.player_mode_ahelp)
				continue
			else
				boutput(M, "<span style=\"color:blue\"><font size='3'><strong><span style='color: red'>HELP: </span>[key_name(src,0,0)][(real_name ? "/"+real_name : "")] <A HREF='?src=\ref[M.client.holder];action=adminplayeropts;targetckey=[client.ckey]' class='popt'><i class='icon-info-sign'></em></A></strong>: [msg]</font></span>")

	#ifdef DATALOGGER
	game_stats.Increment("adminhelps")
	game_stats.ScanText(msg)
	#endif
	boutput(usr, "<span style=\"color:blue\"><font size='3'><strong><span style='color: red'>HELP: </span> You</strong>: [msg]</font></span>")
	logTheThing("admin_help", src, null, "HELP: [msg]")
	logTheThing("diary", src, null, "HELP: [msg]", "ahelp")
	var/ircmsg[] = new()
	ircmsg["key"] = key
	ircmsg["name"] = real_name
	ircmsg["msg"] = html_decode(msg)
	ircbot.export("help", ircmsg)

/mob/verb/mentorhelp()
	set category = "Commands"
	set name = "mentorhelp"

	if (IsGuestKey(key))
		boutput(src, "You are not authorized to communicate over these channels.")
		gib(src)
		return

	if (client.last_adminhelp > (world.timeofday - ADMINHELP_DELAY))
		if (abs(world.timeofday - client.last_adminhelp) < 1000) // some midnight rollover protection b/c byond is fucking stupid
			boutput(src, "You must wait [round((client.last_adminhelp + ADMINHELP_DELAY - world.timeofday)/10)] seconds before requesting help again.")
			return

	var/msg = input("Please enter your help request to mentors:") as null|text

	msg = copytext(strip_html(msg), 1, MAX_MESSAGE_LEN)

	if (!msg)
		return

	if (usr.client && usr.client.ismuted())
		return

	client.last_adminhelp = world.timeofday

	for (var/mob/M in mobs)
		if (M.client && M.client.holder)
			if (M.client.player_mode && !M.client.player_mode_mhelp)
				continue
			else
				boutput(M, "<span style='color:[mentorhelp_text_color]'><strong>MENTORHELP: [key_name(src,0,0,1)][(real_name ? "/"+real_name : "")] <A HREF='?src=\ref[M.client.holder];action=adminplayeropts;targetckey=[client.ckey]' class='popt'><i class='icon-info-sign'></em></A></strong>: <span class='message'>[msg]</span></span>")
		else if (M.client && M.client.mentor && M.client.see_mentor_pms)
			boutput(M, "<span style='color:[mentorhelp_text_color]'><strong>MENTORHELP: [key_name(src,0,0,1)]</strong>: <span class='message'>[msg]</span></span>")

	boutput(usr, "<span style='color:[mentorhelp_text_color]'><strong>MENTORHELP: You</strong>: [msg]</span>")
	logTheThing("mentor_help", src, null, "MENTORHELP: [msg]")
	logTheThing("diary", src, null, "MENTORHELP: [msg]", "mhelp")
	var/ircmsg[] = new()
	ircmsg["key"] = key
	ircmsg["name"] = real_name
	ircmsg["msg"] = html_decode(msg)
	ircbot.export("mentorhelp", ircmsg)

/mob/living/verb/pray()
	set category = "Commands"
	set name = "pray"
	set desc = "Attempt to gain the attention of a divine being. Note that it's not necessarily the kind of attention you want."
	if (IsGuestKey(key))
		boutput(src, "You are not authorized to communicate over these channels.")
		gib(src)
		return

	if (client.last_adminhelp > (world.timeofday - ADMINHELP_DELAY))
		if (abs(world.timeofday - client.last_adminhelp) < 1000) // some midnight rollover protection b/c byond is fucking stupid
			boutput(src, "You must wait [round((client.last_adminhelp + ADMINHELP_DELAY - world.timeofday)/10)] seconds before requesting help again.")
			return

	var/msg = input("Please enter your prayer to any gods that may be listening - be careful what you wish for as the gods may be the vengeful sort!") as null|text

	msg = copytext(strip_html(msg), 1, MAX_MESSAGE_LEN)

	if (!msg)
		return

	client.last_adminhelp = world.timeofday
	boutput(src, "<strong>You whisper a silent prayer,</strong> <em>\"[msg]\"</em>")
	logTheThing("admin_help", src, null, "PRAYER: [msg]")
	logTheThing("diary", src, null, "PRAYER: [msg]", "ahelp")
	for (var/mob/M in mobs)
		if (M.client && M.client.holder)
			if (!M.client.holder.hear_prayers)
				continue
			else
				boutput(M, "<span style=\"color:blue\"><strong>PRAYER: </strong><a href='?src=\ref[M.client.holder];action=subtlemsg&targetckey=[usr.ckey]'>[usr.key]</a> / [usr.real_name ? usr.real_name : usr.name] <A HREF='?src=\ref[M.client.holder];action=adminplayeropts;targetckey=[client.ckey]' class='popt'><i class='icon-info-sign'>: <em>[msg]</em></span>")