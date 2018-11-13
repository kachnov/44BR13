#include "macros.dm"

var/global/admin_sound_channel = 660

/client/proc/play_sound(S as sound, var/vol as num)
	set category = "Special Verbs"
	set name = "Play Sound"

	ADMIN_CHECK(src)

	if (!config.allow_admin_sounds)
		alert("Admin sounds disabled")
		return

	var/sound/uploaded_sound = new()
	uploaded_sound.file = S
	uploaded_sound.priority = 0

	if (sound_waiting)
		uploaded_sound.channel = 160
		uploaded_sound.wait = 1
	else uploaded_sound.wait = 0
	vol = max(min(vol, 100), 0)
	#ifdef PLAYSOUND_LIMITER
	if (holder.rank == "Host" || holder.rank == "Coder" || holder.rank == "Shit Person")
		logTheThing("admin", src, null, "played sound [S]")
		logTheThing("diary", src, null, "played sound [S]", "admin")
		message_admins("[key_name(src)] played sound [S]")
		sleep(-1)
		for (var/client/C in clients)
			C.verbs += /client/verb/stop_the_music
			C << sound(uploaded_sound,volume=vol,wait=0,channel=admin_sound_channel)
			DEBUG_MESSAGE("Playing sound for [C] on channel [admin_sound_channel]")
		if (djmode)
			if (stealth) boutput(world, "<span class=\"medal\"><strong>Now Playing:</strong></span> <span style=\"color:blue\">[S]</span>")
			else boutput(world, "<span class=\"medal\"><strong>[alt_key ? "[fakekey]" : "[key]"] played:</strong></span> <span style=\"color:blue\">[S]</span>")
	else
		if (usr.client.canplaysound)
			usr.client.canplaysound = 0
			logTheThing("admin", src, null, "played sound [S]")
			logTheThing("diary", src, null, "played sound [S]", "admin")
			message_admins("[key_name(src)] played sound [S]")
			sleep(-1)
			for (var/client/C in clients)
				C << sound(uploaded_sound,volume=vol,wait=0,channel=admin_sound_channel)
				DEBUG_MESSAGE("Playing sound for [C] on channel [admin_sound_channel]")
			if (djmode)
				/*if (stealth) boutput(world, "<span class=\"medal\"><strong>Now Playing:</strong></span> <span style=\"color:blue\">[S]</span>")
				else */
				boutput(world, "<span class=\"medal\"><strong>[admin_key(src, 1)] Played:</strong></span> <span style=\"color:blue\">[S]</span>")
		else
			boutput(usr, "You already used up your jukebox monies this round!")
			qdel(uploaded_sound)
	#else
	logTheThing("admin", src, null, "played sound [S]")
	logTheThing("diary", src, null, "played sound [S]", "admin")
	message_admins("[key_name(src)] played sound [S]")
	sleep(-1)
	for (var/client/C in clients)
		C.verbs += /client/verb/stop_the_music
		C << sound(uploaded_sound,volume=vol,wait=0,channel=admin_sound_channel)
		DEBUG_MESSAGE("Playing sound for [C] on channel [admin_sound_channel]")
	move_admin_sound_channel()
	if (djmode)
		if (stealth) boutput(world, "<span class=\"medal\"><strong>Now Playing (your volume: [vol]):</strong></span> <span style=\"color:blue\">[S]</span>")
		else boutput(world, "<span class=\"medal\"><strong>[alt_key ? "[fakekey]" : "[key]"] played (your volume: [vol]):</strong></span> <span style=\"color:blue\">[S]</span>")
	#endif

/client/proc/play_ambient_sound(S as sound)
	set category = "Special Verbs"
	set name = "play ambient sound"

	ADMIN_CHECK(src)

	if (!config.allow_admin_sounds)
		alert("Admin sounds disabled")
		return


	if (holder.rank == "Host" || holder.rank == "Coder" || holder.rank == "Shit Person")
		logTheThing("admin", src, null, "played ambient sound [S]")
		logTheThing("diary", src, null, "played ambient sound [S]", "admin")
		message_admins("[key_name(src)] played ambient sound [S]")
		playsound(get_turf_loc(mob), S, 50, 1)
	else
		if (usr.client.canplaysound)
			usr.client.canplaysound = 0
			logTheThing("admin", src, null, "played ambient sound [S]")
			logTheThing("diary", src, null, "played ambient sound [S]", "admin")
			message_admins("[key_name(src)] played ambient sound [S]")
			playsound(get_turf_loc(mob), S, 50, 1)
		else
			boutput(usr, "You already used up your jukebox monies this round!")
			qdel(S)

/client/proc/play_music_real(S as sound)
	if (!config.allow_admin_sounds)
		alert("Admin sounds disabled")
		return FALSE

	var/sound/uploaded_sound = new()
	uploaded_sound.file = S
	uploaded_sound.priority = 255
	uploaded_sound.channel = 999
	uploaded_sound.wait = 1

	spawn (0)
		for (var/client/C in clients)
			C.verbs += /client/verb/stop_the_music
			var/vol = C.preferences.admin_music_volume
			if (vol == 0)
				if (djmode || non_admin_dj)
					boutput(C, "<span class=\"medal\"><strong>[key] played (your volume: 0):</strong></span> <span style=\"color:blue\">[S]</span>")
				continue
			C << sound(uploaded_sound,wait=0,channel=admin_sound_channel,volume=vol)
			DEBUG_MESSAGE("Playing sound for [C] on channel [admin_sound_channel]")
			if (djmode || non_admin_dj)
				boutput(C, "<span class=\"medal\"><strong>[key] played (your volume: [vol]):</strong></span> <span style=\"color:blue\">[S]</span>")
			sleep(1)
		move_admin_sound_channel()
	logTheThing("admin", src, null, "started loading music [S]")
	logTheThing("diary", src, null, "started loading music [S]", "admin")
	message_admins("[key_name(src)] started loading music [S]")
	return TRUE

/client/proc/play_music(S as sound)
	set category = "Special Verbs"
	set name = "Play Music"

	ADMIN_CHECK(src)
	play_music_real(S)

/mob/verb/adminmusicvolume()
	set desc = "Toggle whether you can hear all chat while dead or just local chat"
	set name = "Alter Music Volume"

	if (!usr.client) //How could this even happen?
		return

	var/vol = input("Goes from 0-100.","Admin Music Volume") as num
	vol = max(0,min(vol,100))
	usr.client.preferences.admin_music_volume = vol

// for giving non-admins the ability to play music
/client/proc/non_admin_dj(S as sound)
	set category = "Special Verbs"
	set name = "Play Music"

	if (play_music_real(S))
		boutput(src, "<span style=\"color:blue\">Loading music [S]...</span>")

/client/proc/give_dj(mob/M as mob in world)
	set category = null
	set name = "Give or Remove DJ"
	set desc = "Give or remove a non-admin's ability to play music."
	set popup_menu = 0
	ADMIN_CHECK(src)

	if (!M.client)
		return

	if (!M.client.non_admin_dj)
		M.client.non_admin_dj = 1
		M.client.verbs += /client/proc/non_admin_dj
		M.client.verbs += /client/proc/cmd_dectalk

		logTheThing("admin", src, M, "has given %target% the ability to play music and use dectalk.")
		logTheThing("diary", src, M, "has given %target% the ability to play music and use dectalk.", "admin")
		message_admins("[key_name(src)] has given [key_name(M)] the ability to play music and use dectalk.")

		boutput(M, "<span style=\"color:red\"><strong>You can now play music with 'Play Music' and use text2speech with 'Dectalk' commands under 'Special Verbs'.</strong></span>")
		return
	else
		M.client.non_admin_dj = 0
		M.client.verbs -= /client/proc/non_admin_dj
		M.client.verbs -= /client/proc/cmd_dectalk

		logTheThing("admin", src, M, "has removed %target%'s ability to play music and use dectalk.")
		logTheThing("diary", src, M, "has removed %target%'s ability to play music and use dectalk.", "admin")
		message_admins("[key_name(src)] has removed [key_name(M)]'s ability to play music and use dectalk.")

		boutput(M, "<span style=\"color:red\"><strong>You can no longer play music.</strong></span>")
		return

/client/verb/stop_the_music()
	set category = "Commands"
	set name = "Stop the Music!"
	set desc = "Is there music playing? Do you hate it? Press this to make it stop!"
	set popup_menu = 0

	ehjax.send(src, "browseroutput", "stopaudio") //For client-side audio

	verbs -= /client/verb/stop_the_music
	var/mute_channel = 660
	for (var/i=0, i<11, i++)
		DEBUG_MESSAGE("Muting sound channel [mute_channel] for [src]")
		src << sound(null,channel=mute_channel)
		mute_channel ++
	spawn (50)
		verbs += /client/verb/stop_the_music

/proc/move_admin_sound_channel()
	if (admin_sound_channel <= 669)
		DEBUG_MESSAGE("Increasing admin_sound_channel from [admin_sound_channel] to [(admin_sound_channel+1)]")
		admin_sound_channel ++
		DEBUG_MESSAGE("admin_sound_channel now [admin_sound_channel]")
	else
		DEBUG_MESSAGE("Resetting admin_sound_channel from [admin_sound_channel]")
		admin_sound_channel = 660
		DEBUG_MESSAGE("admin_sound_channel now [admin_sound_channel]")