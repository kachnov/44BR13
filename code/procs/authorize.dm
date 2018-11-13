/client/proc/authorize()
	set name = "Authorize"

	if (admins.Find(ckey))
//		boutput(src, "<span class='ooc adminooc'>Admin IRC - #ss13centcom #ss13admin on irc.synirc.net</span>")
		if (!NT.Find(ckey))
			NT.Add(ckey)
			//mentor = 1
			return
		return

	if (NT.Find(ckey) || mentors.Find(ckey))
		mentor = 1
		mentor_authed = 1
		boutput(src, "<span class='ooc mentorooc'>You are a mentor!</span>")
		if (!holder)
			verbs += /client/proc/toggle_mentorhelps
		return

/client/proc/set_mentorhelp_visibility(var/set_as = null)
	if (!isnull(set_as))
		mentor = set_as
		see_mentor_pms = set_as
	else
		mentor = !(mentor)
		see_mentor_pms = mentor
	boutput(src, "<span class='ooc mentorooc'>You will [mentor ? "now" : "no longer"] see Mentorhelps [mentor ? "and" : "or"] show up as a Mentor.</span>")

/client/proc/toggle_mentorhelps()
	set name = "Toggle Mentorhelps"
	set category = "Toggles"
	set desc = "Show or hide mentorhelp messages. You will also no longer show up as a mentor in OOC and via the Who command if you disable mentorhelps."

	if (!mentor_authed && !holder)
		boutput(src, "<span style='color:red'>Only mentors may use this command.</span>")
		verbs -= /client/proc/toggle_mentorhelps // maybe?
		return

	set_mentorhelp_visibility()

/*
/proc/proxy_check(address)
	if (address)
		var/result = world.Export("http://autisticpowers.info/ss13/check_ip.php?ip=[address]")
		if ("STATUS" in result && lowertext(result["STATUS"]) == "200 ok")
			var/using_proxy = text2num(file2text(result["CONTENT"]))
			if (using_proxy)
				return TRUE
	return FALSE
*/