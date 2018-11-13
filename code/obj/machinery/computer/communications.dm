// The communications computer

/obj/machinery/computer/communications
	name = "Communications Console"
	icon_state = "comm"
	req_access = list(access_heads)
	var/prints_intercept = 1
	var/authenticated = 0
	var/list/messagetitle = list()
	var/list/messagetext = list()
	var/currmsg = 0
	var/aicurrmsg = 0
	var/state = STATE_DEFAULT
	var/aistate = STATE_DEFAULT
	var/const
		STATE_DEFAULT = 1
		STATE_CALLSHUTTLE = 2
		STATE_CANCELSHUTTLE = 3
		STATE_MESSAGELIST = 4
		STATE_VIEWMESSAGE = 5
		STATE_DELMESSAGE = 6
		STATE_STATUSDISPLAY = 7

	var/status_display_freq = "1435"
	var/stat_msg1
	var/stat_msg2
	desc = "A computer that allows one to call and recall the emergency shuttle, as well as recieve messages from Centcom."

/obj/machinery/computer/communications/process()
	..()
	if (state != STATE_STATUSDISPLAY)
		updateDialog()

/obj/machinery/computer/communications/Topic(href, href_list)
	if (..())
		return
	usr.machine = src

	if (!href_list["operation"] || (dd_hasprefix(href_list["operation"], "ai-") && !issilicon(usr)))
		return
	switch(href_list["operation"])
		// main interface
		if ("main")
			state = STATE_DEFAULT
		if ("login")
			var/mob/M = usr
			var/obj/item/card/id/I = M.equipped()
			if (I && istype(I))
				if (check_access(I))
					authenticated = 1
		if ("logout")
			authenticated = 0
		if ("nolockdown")
			disablelockdown(usr)
			post_status("alert", "default")
		if ("call-prison")
			call_prison_shuttle(usr)
		if ("callshuttle")
			state = STATE_DEFAULT
			if (authenticated)
				state = STATE_CALLSHUTTLE
		if ("callshuttle2")
			if (authenticated)
				call_shuttle_proc(usr)

				if (emergency_shuttle.online)
					post_status("shuttle")

			state = STATE_DEFAULT
		if ("cancelshuttle")
			state = STATE_DEFAULT
			if (authenticated)
				state = STATE_CANCELSHUTTLE
		if ("cancelshuttle2")
			if (authenticated)
				cancel_call_proc(usr)
			state = STATE_DEFAULT
		if ("messagelist")
			currmsg = 0
			state = STATE_MESSAGELIST
		if ("viewmessage")
			state = STATE_VIEWMESSAGE
			if (!currmsg)
				if (href_list["message-num"])
					currmsg = text2num(href_list["message-num"])
				else
					state = STATE_MESSAGELIST
		if ("delmessage")
			state = (currmsg) ? STATE_DELMESSAGE : STATE_MESSAGELIST
		if ("delmessage2")
			if (authenticated)
				if (currmsg)
					var/title = messagetitle[currmsg]
					var/text  = messagetext[currmsg]
					messagetitle.Remove(title)
					messagetext.Remove(text)
					if (currmsg == aicurrmsg)
						aicurrmsg = 0
					currmsg = 0
				state = STATE_MESSAGELIST
			else
				state = STATE_VIEWMESSAGE
		if ("status")
			state = STATE_STATUSDISPLAY

		// Status display stuff
		if ("setstat")
			switch(href_list["statdisp"])
				if ("message")
					post_status("message", stat_msg1, stat_msg2)
				if ("alert")
					post_status("alert", href_list["alert"])
				else
					post_status(href_list["statdisp"])

		if ("setmsg1")
			stat_msg1 = input("Line 1", "Enter Message Text", stat_msg1) as text|null
			stat_msg1 = copytext(adminscrub(stat_msg1), 1, MAX_MESSAGE_LEN)
			updateDialog()
		if ("setmsg2")
			stat_msg2 = input("Line 2", "Enter Message Text", stat_msg2) as text|null
			stat_msg2 = copytext(adminscrub(stat_msg2), 1, MAX_MESSAGE_LEN)
			updateDialog()

		// AI interface
		if ("ai-main")
			aicurrmsg = 0
			aistate = STATE_DEFAULT
		if ("ai-callshuttle")
			aistate = STATE_CALLSHUTTLE
		if ("ai-callshuttle2")
			call_shuttle_proc(usr)
			aistate = STATE_DEFAULT
		if ("ai-messagelist")
			aicurrmsg = 0
			aistate = STATE_MESSAGELIST
		if ("ai-viewmessage")
			aistate = STATE_VIEWMESSAGE
			if (!aicurrmsg)
				if (href_list["message-num"])
					aicurrmsg = text2num(href_list["message-num"])
				else
					aistate = STATE_MESSAGELIST
		if ("ai-delmessage")
			aistate = (aicurrmsg) ? STATE_DELMESSAGE : STATE_MESSAGELIST
		if ("ai-delmessage2")
			if (aicurrmsg)
				var/title = messagetitle[aicurrmsg]
				var/text  = messagetext[aicurrmsg]
				messagetitle.Remove(title)
				messagetext.Remove(text)
				if (currmsg == aicurrmsg)
					currmsg = 0
				aicurrmsg = 0
			aistate = STATE_MESSAGELIST
		if ("ai-status")
			aistate = STATE_STATUSDISPLAY
	updateUsrDialog()

/proc/disablelockdown(var/mob/usr)
	boutput(world, "<span style=\"color:red\">Lockdown cancelled by [usr.name]!</span>")

	for (var/obj/machinery/firealarm/FA in machines) //deactivate firealarms
		spawn ( 0 )
			if (FA.lockdownbyai == 1)
				FA.lockdownbyai = 0
				FA.reset()
	for (var/obj/machinery/door/airlock/AL) //open airlocks
		spawn ( 0 )
			if (AL.canAIControl() && AL.lockdownbyai == 1)
				AL.open()
				AL.lockdownbyai = 0

/obj/machinery/computer/communications/attackby(I as obj, user as mob)
	if (istype(I, /obj/item/screwdriver))
		playsound(loc, "sound/items/Screwdriver.ogg", 50, 1)
		if (do_after(user, 20))
			if (stat & BROKEN)
				boutput(user, "<span style=\"color:blue\">The broken glass falls out.</span>")
				var/obj/computerframe/A = new /obj/computerframe( loc )
				if (material) A.setMaterial(material)
				new /obj/item/raw_material/shard/glass( loc )
				var/obj/item/circuitboard/communications/M = new /obj/item/circuitboard/communications( A )
				for (var/obj/C in src)
					C.set_loc(loc)
				A.circuit = M
				A.state = 3
				A.icon_state = "3"
				A.anchored = 1
				logTheThing("station", user, null, "disassembles [src] (broken) [log_loc(src)]")
				qdel(src)
			else
				boutput(user, "<span style=\"color:blue\">You disconnect the monitor.</span>")
				var/obj/computerframe/A = new /obj/computerframe( loc )
				if (material) A.setMaterial(material)
				var/obj/item/circuitboard/communications/M = new /obj/item/circuitboard/communications( A )
				for (var/obj/C in src)
					C.set_loc(loc)
				A.circuit = M
				A.state = 4
				A.icon_state = "4"
				A.anchored = 1
				logTheThing("station", user, null, "disassembles [src] [log_loc(src)]")
				qdel(src)

	else
		attack_hand(user)
	return

/obj/machinery/computer/communications/attack_ai(var/mob/user as mob)
	return attack_hand(user)

/obj/machinery/computer/communications/attack_hand(var/mob/user as mob)
	if (..())
		return

	user.machine = src
	var/dat = "<head><title>Communications Console</title></head><body>"
	if (emergency_shuttle.online && emergency_shuttle.location==0)
		var/timeleft = emergency_shuttle.timeleft()
		dat += "<strong>Emergency shuttle</strong><br><BR><br>ETA: [timeleft / 60 % 60]:[add_zero(num2text(timeleft % 60), 2)]<BR>"

	if (istype(user, /mob/living/silicon))
		var/dat2 = interact_ai(user) // give the AI a different interact proc to limit its access
		if (dat2)
			dat +=  dat2
			user << browse(dat, "window=communications;size=400x500")
			onclose(user, "communications")
		return

	switch(state)
		if (STATE_DEFAULT)
			if (authenticated)
				dat += "<BR>\[ <A HREF='?src=\ref[src];operation=logout'>Log Out</A> \]"
//				dat += "<BR>\[ <A HREF='?src=\ref[src];operation=call-prison'>Send Prison Shutle</A> \]"
				dat += "<BR>\[ <A HREF='?src=\ref[src];operation=nolockdown'>Disable Lockdown</A> \]"
				if (emergency_shuttle.location==0)
					if (emergency_shuttle.online)
						dat += "<BR>\[ <A HREF='?src=\ref[src];operation=cancelshuttle'>Cancel Shuttle Call</A> \]"
					else
						dat += "<BR>\[ <A HREF='?src=\ref[src];operation=callshuttle'>Call Emergency Shuttle</A> \]"

				dat += "<BR>\[ <A HREF='?src=\ref[src];operation=status'>Set Status Display</A> \]"
			else
				dat += "<BR>\[ <A HREF='?src=\ref[src];operation=login'>Log In</A> \]"
			dat += "<BR>\[ <A HREF='?src=\ref[src];operation=messagelist'>Message List</A> \]"
		if (STATE_CALLSHUTTLE)
			dat += "Are you sure you want to call the shuttle? \[ <A HREF='?src=\ref[src];operation=callshuttle2'>OK</A> | <A HREF='?src=\ref[src];operation=main'>Cancel</A> \]"
		if (STATE_CANCELSHUTTLE)
			dat += "Are you sure you want to cancel the shuttle? \[ <A HREF='?src=\ref[src];operation=cancelshuttle2'>OK</A> | <A HREF='?src=\ref[src];operation=main'>Cancel</A> \]"
		if (STATE_MESSAGELIST)
			dat += "Messages:"
			for (var/i = 1; i<=messagetitle.len; i++)
				dat += "<BR><A HREF='?src=\ref[src];operation=viewmessage;message-num=[i]'>[messagetitle[i]]</A>"
		if (STATE_VIEWMESSAGE)
			if (currmsg)
				dat += "<strong>[messagetitle[currmsg]]</strong><BR><BR>[messagetext[currmsg]]"
				if (authenticated)
					dat += "<BR><BR>\[ <A HREF='?src=\ref[src];operation=delmessage'>Delete \]"
			else
				state = STATE_MESSAGELIST
				attack_hand(user)
				return
		if (STATE_DELMESSAGE)
			if (currmsg)
				dat += "Are you sure you want to delete this message? \[ <A HREF='?src=\ref[src];operation=delmessage2'>OK</A> | <A HREF='?src=\ref[src];operation=viewmessage'>Cancel</A> \]"
			else
				state = STATE_MESSAGELIST
				attack_hand(user)
				return
		if (STATE_STATUSDISPLAY)
			dat += "Set Status Displays<BR>"
			dat += "\[ <A HREF='?src=\ref[src];operation=setstat;statdisp=blank'>Clear</A> \]<BR>"
			dat += "\[ <A HREF='?src=\ref[src];operation=setstat;statdisp=shuttle'>Shuttle ETA</A> \]<BR>"
			dat += "\[ <A HREF='?src=\ref[src];operation=setstat;statdisp=message'>Message</A> \]"
			dat += "<ul><li> Line 1: <A HREF='?src=\ref[src];operation=setmsg1'>[ stat_msg1 ? stat_msg1 : "(none)"]</A>"
			dat += "<li> Line 2: <A HREF='?src=\ref[src];operation=setmsg2'>[ stat_msg2 ? stat_msg2 : "(none)"]</A></ul><br>"
			dat += "\[ Alert: <A HREF='?src=\ref[src];operation=setstat;statdisp=alert;alert=default'>None</A> |"
			dat += " <A HREF='?src=\ref[src];operation=setstat;statdisp=alert;alert=redalert'>Red Alert</A> |"
			dat += " <A HREF='?src=\ref[src];operation=setstat;statdisp=alert;alert=lockdown'>Lockdown</A> |"
			dat += " <A HREF='?src=\ref[src];operation=setstat;statdisp=alert;alert=biohazard'>Biohazard</A> \]<BR><HR>"


	dat += "<BR>\[ [(state != STATE_DEFAULT) ? "<A HREF='?src=\ref[src];operation=main'>Main Menu</A> | " : ""]<A HREF='?action=mach_close&window=communications'>Close</A> \]"
	user << browse(dat, "window=communications;size=400x500")
	onclose(user, "communications")

/obj/machinery/computer/communications/proc/interact_ai(var/mob/living/silicon/ai/user as mob)
	var/dat = ""
	switch(aistate)
		if (STATE_DEFAULT)
			if (emergency_shuttle.location==0 && !emergency_shuttle.online)
				dat += "<BR>\[ <A HREF='?src=\ref[src];operation=ai-callshuttle'>Call Emergency Shuttle</A> \]"
//			dat += "<BR>\[ <A HREF='?src=\ref[src];operation=call-prison'>Send Prison Shutle</A> \]"
			dat += "<BR>\[ <A HREF='?src=\ref[src];operation=ai-messagelist'>Message List</A> \]"
			dat += "<BR>\[ <A HREF='?src=\ref[src];operation=nolockdown'>Disable Lockdown</A> \]"
			dat += "<BR>\[ <A HREF='?src=\ref[src];operation=ai-status'>Set Status Display</A> \]"
		if (STATE_CALLSHUTTLE)
			dat += "Are you sure you want to call the shuttle? \[ <A HREF='?src=\ref[src];operation=ai-callshuttle2'>OK</A> | <A HREF='?src=\ref[src];operation=ai-main'>Cancel</A> \]"
		if (STATE_MESSAGELIST)
			dat += "Messages:"
			for (var/i = 1; i<=messagetitle.len; i++)
				dat += "<BR><A HREF='?src=\ref[src];operation=ai-viewmessage;message-num=[i]'>[messagetitle[i]]</A>"
		if (STATE_VIEWMESSAGE)
			if (aicurrmsg)
				dat += "<strong>[messagetitle[aicurrmsg]]</strong><BR><BR>[messagetext[aicurrmsg]]"
				dat += "<BR><BR>\[ <A HREF='?src=\ref[src];operation=ai-delmessage'>Delete</A> \]"
			else
				aistate = STATE_MESSAGELIST
				attack_hand(user)
				return null
		if (STATE_DELMESSAGE)
			if (aicurrmsg)
				dat += "Are you sure you want to delete this message? \[ <A HREF='?src=\ref[src];operation=ai-delmessage2'>OK</A> | <A HREF='?src=\ref[src];operation=ai-viewmessage'>Cancel</A> \]"
			else
				aistate = STATE_MESSAGELIST
				attack_hand(user)
				return

		if (STATE_STATUSDISPLAY)
			dat += "Set Status Displays<BR>"
			dat += "\[ <A HREF='?src=\ref[src];operation=setstat;statdisp=blank'>Clear</A> \]<BR>"
			dat += "\[ <A HREF='?src=\ref[src];operation=setstat;statdisp=shuttle'>Shuttle ETA</A> \]<BR>"
			dat += "\[ <A HREF='?src=\ref[src];operation=setstat;statdisp=message'>Message</A> \]"
			dat += "<ul><li> Line 1: <A HREF='?src=\ref[src];operation=setmsg1'>[ stat_msg1 ? stat_msg1 : "(none)"]</A>"
			dat += "<li> Line 2: <A HREF='?src=\ref[src];operation=setmsg2'>[ stat_msg2 ? stat_msg2 : "(none)"]</A></ul><br>"
			dat += "\[ Alert: <A HREF='?src=\ref[src];operation=setstat;statdisp=alert;alert=default'>None</A> |"
			dat += " <A HREF='?src=\ref[src];operation=setstat;statdisp=alert;alert=redalert'>Red Alert</A> |"
			dat += " <A HREF='?src=\ref[src];operation=setstat;statdisp=alert;alert=lockdown'>Lockdown</A> |"
			dat += " <A HREF='?src=\ref[src];operation=setstat;statdisp=alert;alert=biohazard'>Biohazard</A> \]<BR><HR>"


	dat += "<BR>\[ [(aistate != STATE_DEFAULT) ? "<A HREF='?src=\ref[src];operation=ai-main'>Main Menu</A> | " : ""]<A HREF='?action=mach_close&window=communications'>Close</A> \]"
	return dat

/mob/living/silicon/ai/proc/ai_call_shuttle()
	set category = "AI Commands"
	set name = "Call Emergency Shuttle"

	if (usr == src)
		if ((alert(usr, "Are you sure?",,"Yes","No") != "Yes"))
			return

	if (usr.stat == 2)
		boutput(usr, "You can't call the shuttle because you are dead!")
		return
	logTheThing("admin", usr, null, "called the Emergency Shuttle")
	logTheThing("diary", usr, null, "called the Emergency Shuttle", "admin")
	message_admins("<span style=\"color:blue\">[key_name(usr)] called the Emergency Shuttle to the station</span>")
	call_shuttle_proc(src)

	// hack to display shuttle timer
	if (emergency_shuttle.online)
		var/obj/machinery/computer/communications/C = locate() in world
		if (C)
			C.post_status("shuttle")

	return

/proc/call_prison_shuttle(var/mob/usr)
	if ((!(ticker && ticker.mode) || emergency_shuttle.location == 1))
		return
	/*if (istype(ticker.mode, /game_mode/sandbox))
		boutput(usr, "Under directive 7-10, [station_name()] is quarantined until further notice.")
		return*/
	if (istype(ticker.mode, /game_mode/revolution))
		boutput(usr, "Centcom will not allow the shuttle to be called.")
		return
	return


/proc/enable_prison_shuttle(var/mob/user)
	return
/proc/call_shuttle_proc(var/mob/user)
	if ((!( ticker ) || emergency_shuttle.location))
		return TRUE

	if (world.time/10 < 600)
		boutput(user, "Centcom will not allow the shuttle to be called.")
		return TRUE
	/*if (istype(ticker.mode, /game_mode/sandbox))
		boutput(user, "Under directive 7-10, [station_name()] is quarantined until further notice.")
		return TRUE*/
	if (emergency_shuttle.disabled)
		boutput(user, "Centcom will not allow the shuttle to be called.")
		return TRUE
	if (solar_flare)
		boutput(user, "<span style=\"color:red\">Solar Flare activity is preventing contact with the Emergency Shuttle.</span>")
		return TRUE

	emergency_shuttle.incall()
	boutput(world, "<span style=\"color:blue\"><strong>Alert: The emergency shuttle has been called. It will arrive in [round(emergency_shuttle.timeleft()/60)] minutes.</strong></span>")

	return FALSE

/proc/cancel_call_proc(var/mob/user)
	if ((!( ticker ) || emergency_shuttle.location || emergency_shuttle.direction == 0 || emergency_shuttle.timeleft() < 300))
		return TRUE

	if (solar_flare)
		boutput(user, "<span style=\"color:red\">Solar Flare activity is preventing contact with the Emergency Shuttle.</span>")
		return TRUE

	boutput(world, "<span style=\"color:blue\"><strong>Alert: The shuttle is going back!</strong></span>") //marker4

	emergency_shuttle.recall()

	return FALSE

/obj/machinery/computer/communications/proc/post_status(var/command, var/data1, var/data2)

	var/radio_frequency/frequency = radio_controller.return_frequency(status_display_freq)

	if (!frequency) return



	var/signal/status_signal = get_free_signal()
	status_signal.source = src
	status_signal.transmission_method = 1
	status_signal.data["command"] = command

	switch(command)
		if ("message")
			status_signal.data["msg1"] = data1
			status_signal.data["msg2"] = data2
		if ("alert")
			status_signal.data["picture_state"] = data1

	frequency.post_signal(src, status_signal)



	/*
		receive_signal(signal/signal)

		switch(signal.data["command"])
			if ("blank")
				mode = 0

			if ("shuttle")
				mode = 1

			if ("message")
				set_message(signal.data["msg1"], signal.data["msg2"])

			if ("alert")
				set_picture(signal.data["picture_state"])
*/