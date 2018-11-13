#include "macros.dm"

/admins
	var/name = "admins"
	var/rank = null
	var/client/owner = null
	var/state = 1
	//state = 1 for playing : default
	//state = 2 for observing
	var/extratoggle = 0
	var/popuptoggle = 0
	var/servertoggles_toggle = 0
	var/animtoggle = 1
	var/attacktoggle = 1
	var/auto_stealth = 0
	var/auto_stealth_name = null
	var/auto_alt_key = 0
	var/auto_alt_key_name = null
	var/level = 0
	var/drunk = 0 //I find adding this var pretty hilarious in itself really
	var/hear_prayers = 0 //Ok
	var/priorRank = null
	var/list/active_monitor_datums = list()

	New()
		..()
		spawn (1)
			if (owner)
				var/client/C = owner
				C.chatOutput.getContextFlag()
				load_admin_prefs()

	proc/show_pref_window(mob/user)
		var/HTML = "<html><head><title>Admin Preferences</title></head><body>"
		HTML += "<a href='?src=\ref[src];action=refresh_admin_prefs'>Refresh</a></strong><br>"
		HTML += "<strong>Automatically Set Alternate Key?: <a href='?src=\ref[src];action=toggle_auto_alt_key'>[(auto_alt_key ? "Yes" : "No")]</a></strong><br>"
		HTML += "<strong>Auto Alt Key: <a href='?src=\ref[src];action=set_auto_alt_key_name'>[(auto_alt_key_name ? "[auto_alt_key_name]" : "N/A")]</a></strong><br>"
		HTML += "<strong>Automatically Set Stealth Mode?: <a href='?src=\ref[src];action=toggle_auto_stealth'>[(auto_stealth ? "Yes" : "No")]</a></strong><br>"
		HTML += "<strong>Auto Stealth Name: <a href='?src=\ref[src];action=set_auto_stealth_name'>[(auto_stealth_name ? "[auto_stealth_name]" : "N/A")]</a></strong><br>"
		HTML += "<em>Note: Auto Stealth will override Auto Alt Key settings on load</em><br>"
		//if (owner:holder:level >= LEVEL_CODER)
			//HTML += "<strong>Hide Extra Verbs?: <a href='?src=\ref[src];action=toggle_extra_verbs'>[(extratoggle ? "Yes" : "No")]</a></strong><br>"
		HTML += "<strong>Hide Popup Verbs?: <a href='?src=\ref[src];action=toggle_popup_verbs'>[(popuptoggle ? "Yes" : "No")]</a></strong><br>"
		HTML += "<strong>Hide Server Toggles Tab?: <a href='?src=\ref[src];action=toggle_server_toggles_tab'>[(servertoggles_toggle ? "Yes" : "No")]</a></strong><br>"
		if (owner.holder.level >= LEVEL_PA)
			HTML += "<strong>Hide Atom Verbs?: <a href='?src=\ref[src];action=toggle_atom_verbs'>[(animtoggle ? "Yes" : "No")]</a></strong><br>"
		HTML += "<strong>Hide Attack Alerts?: <a href='?src=\ref[src];action=toggle_attack_messages'>[(attacktoggle ? "Yes" : "No")]</a></strong><br>"
		HTML += "<strong>See Prayers?: <a href='?src=\ref[src];action=toggle_hear_prayers'>[(hear_prayers ? "Yes" : "No")]</a></strong><br>"
		HTML += "<br><strong><a href='?src=\ref[src];action=load_admin_prefs'>LOAD</a></strong> | <strong><a href='?src=\ref[src];action=save_admin_prefs'>SAVE</a></strong>"
		HTML += "</body></html>"

		user << browse(HTML,"window=aprefs")

	proc/load_admin_prefs()
		if (!owner)
			return
		var/savefile/AP = new /savefile("data/AdminPrefs.sav")
		var/ckey = owner:ckey
		if (!ckey)
			return
/*
		var/saved_extratoggle
		AP["[ckey]_extratoggle"] >> saved_extratoggle
		if (isnull(saved_extratoggle))
			saved_extratoggle = 0
		if (saved_extratoggle == 1 && extratoggle != 1)
			owner:toggle_extra_verbs()
		extratoggle = saved_extratoggle
*/
		var/saved_popuptoggle
		AP["[ckey]_popuptoggle"] >> saved_popuptoggle
		if (isnull(saved_popuptoggle))
			saved_popuptoggle = 0
		if (saved_popuptoggle == 1 && popuptoggle != 1)
			owner:toggle_popup_verbs()
		popuptoggle = saved_popuptoggle

		var/saved_servertoggles_toggle
		AP["[ckey]_servertoggles_toggle"] >> saved_servertoggles_toggle
		if (isnull(saved_servertoggles_toggle))
			saved_servertoggles_toggle = 0
		if (saved_servertoggles_toggle == 1 && servertoggles_toggle != 1)
			owner:toggle_server_toggles_tab()
		servertoggles_toggle = saved_servertoggles_toggle

		var/saved_animtoggle
		AP["[ckey]_animtoggle"] >> saved_animtoggle
		if (isnull(saved_animtoggle))
			saved_animtoggle = 1
		if (saved_animtoggle == 0 && animtoggle != 0)
			owner:toggle_atom_verbs()
		animtoggle = saved_animtoggle

		var/saved_attacktoggle
		AP["[ckey]_attacktoggle"] >> saved_attacktoggle
		if (isnull(saved_attacktoggle))
			saved_attacktoggle = 1
		if (saved_attacktoggle == 0 && attacktoggle != 0)
			owner:toggle_attack_messages()
		attacktoggle = saved_attacktoggle

		var/saved_auto_stealth
		var/saved_auto_stealth_name
		AP["[ckey]_auto_stealth"] >> saved_auto_stealth
		AP["[ckey]_auto_stealth_name"] >> saved_auto_stealth_name
		if (isnull(saved_auto_stealth) || !isnum(saved_auto_stealth))
			saved_auto_stealth = 0
			saved_auto_stealth_name = null
		if (saved_auto_stealth == 1 && auto_stealth != 1 && !isnull(saved_auto_stealth_name))
			auto_stealth = 1
			set_stealth_mode(saved_auto_stealth_name, 1)
		auto_stealth = saved_auto_stealth
		auto_stealth_name = saved_auto_stealth_name

		var/saved_auto_alt_key
		var/saved_auto_alt_key_name
		AP["[ckey]_auto_alt_key"] >> saved_auto_alt_key
		AP["[ckey]_auto_alt_key_name"] >> saved_auto_alt_key_name
		if (isnull(saved_auto_alt_key) || !isnum(saved_auto_alt_key))
			saved_auto_alt_key = 0
			saved_auto_alt_key_name = null
		if (!auto_stealth && saved_auto_alt_key == 1 && auto_alt_key != 1 && !isnull(saved_auto_alt_key_name))
			auto_alt_key = 1
			set_alt_key(saved_auto_alt_key_name, 1)
		auto_alt_key = saved_auto_alt_key
		auto_alt_key_name = saved_auto_alt_key_name

		var/saved_hear_prayers
		AP["[ckey]_hear_prayers"] >> saved_hear_prayers
		if (isnull(saved_hear_prayers))
			saved_hear_prayers = 0
		hear_prayers = saved_hear_prayers

		if (usr)
			boutput(usr, "<span style=\"color:blue\">Admin preferences loaded.</span>")

	proc/save_admin_prefs()
		if (!owner)
			return
		var/savefile/AP = new /savefile("data/AdminPrefs.sav")
		var/ckey = owner:ckey
		if (!ckey)
			return
		//AP["[ckey]_extratoggle"] << extratoggle
		AP["[ckey]_popuptoggle"] << popuptoggle
		AP["[ckey]_servertoggles_toggle"] << servertoggles_toggle
		AP["[ckey]_animtoggle"] << animtoggle
		AP["[ckey]_attacktoggle"] << attacktoggle
		AP["[ckey]_auto_stealth"] << auto_stealth
		AP["[ckey]_auto_stealth_name"] << auto_stealth_name
		AP["[ckey]_auto_alt_key"] << auto_alt_key
		AP["[ckey]_auto_alt_key_name"] << auto_alt_key_name
		AP["[ckey]_hear_prayers"] << hear_prayers

		if (usr)
			boutput(usr, "<span style=\"color:blue\">Admin preferences saved.</span>")

/client/proc/change_admin_prefs()
	set category = "Admin"
	set name = "Change Admin Preferences"
	ADMIN_CHECK(src)

	holder.show_pref_window(mob)

/proc/admin_key(var/client/C, var/return_administrator = 0)
	if (!C)
		return "Administrator"
	if (C.stealth)
		if (return_administrator)
			return "Administrator"
		else
			return C.fakekey
	if (C.alt_key)
		return C.fakekey
	else
		return C.key
