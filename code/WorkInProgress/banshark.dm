/client/proc/sharkban(mob/sharktarget as mob in world)
	set category = null
	set name = "Shark Ban"
	set popup_menu = 0
	var/startx = 1
	var/starty = 1
//	var/startside = pick(cardinal)
//	var/pickstarter = null
	if (!holder)
		boutput(src, "Only administrators may use this command.")
		return
	else
		switch(alert("Temporary Ban?",,"Yes","No"))
			if ("Yes")
				var/sharkmins = input(usr,"How long (in minutes)?","Ban time",1440) as num
				if (!sharkmins)
					return
				if (sharkmins >= 2441) sharkmins = 2440
				var/reason = input(usr,"Reason?","reason","Griefer") as text
				if (!reason)
					return
				var/speed = input(usr,"How fast is the shark? Lower is faster.","speed","5") as num
				if (!speed)
					return
				var/time = input(usr,"How long until it gives up and cheats? No relation to real time.","time","4") as num
				if (!time)
					return
//				switch(startside)
//					if (NORTH)
//						starty = world.maxy-2
//						startx = rand(2, world.maxx-2)
//					if (EAST)
//						starty = rand(2,world.maxy-2)
//						startx = world.maxx-2
//					if (SOUTH)
//						starty = 2
//						startx = rand(2, world.maxx-2)
//					if (WEST)
//						starty = rand(2, world.maxy-2)
//						startx = 2
				boutput(sharktarget, "Uh oh.")
				sharktarget << sound('sound/misc/jaws.ogg')
				sleep(200)
				startx = sharktarget.x - rand(-11, 11)
				starty = sharktarget.y - rand(-11, 11)
//				pickedstarter = get_turf(pick(sharktarget:range(10)))
				var/turf/pickedstart = locate(startx, starty, sharktarget.z)
				var/obj/banshark/Q = new /obj/banshark(pickedstart)
				Q.sharkmins2 = sharkmins
				Q.sharktarget2 = sharktarget
				Q.caller = usr
				Q.sharkreason = reason
				Q.timelimit = time
				Q.sharkspeed = speed
//				boutput(sharktarget, "<span style=\"color:red\"><BIG><strong>You have been banned by [usr.client.ckey].<br>Reason: [reason].</strong></BIG></span>")
//				boutput(sharktarget, "<span style=\"color:red\">This is a temporary ban, it will be removed in [sharkmins] minutes.</span>")
//				logTheThing("admin", usr, sharktarget, "has sharked %target%. Reason: [reason]. This will be removed in [sharkmins] minutes.")
				logTheThing("diary", usr, sharktarget, "has sharked %target%. Reason: [reason]. This will be removed in [sharkmins] minutes.", "admin")
//				message_admins("<span style=\"color:blue\">[usr.client.ckey] has banned [sharktarget.ckey].<br>Reason: [reason]<br>This will be removed in [sharkmins] minutes.</span>")

/client/proc/sharkgib(mob/sharktarget as mob in world)
	set category = null
	set name = "Shark Gib"
	set popup_menu = 0
	var/startx = 1
	var/starty = 1
//	var/startside = pick(cardinal)
//	var/pickstarter = null
	if (!holder)
		boutput(src, "Only administrators may use this command.")
		return

	var/speed = input(usr,"How fast is the shark? Lower is faster.","speed","5") as num
	if (!speed)
		return
//				switch(startside)
//					if (NORTH)
//						starty = world.maxy-2
//						startx = rand(2, world.maxx-2)
//					if (EAST)
//						starty = rand(2,world.maxy-2)
//						startx = world.maxx-2
//					if (SOUTH)
//						starty = 2
//						startx = rand(2, world.maxx-2)
//					if (WEST)
//						starty = rand(2, world.maxy-2)
//						startx = 2
	boutput(sharktarget, "Uh oh.")
	sharktarget << sound('sound/misc/jaws.ogg')
	sleep(200)
	startx = sharktarget.x - rand(-11, 11)
	starty = sharktarget.y - rand(-11, 11)
//				pickedstarter = get_turf(pick(sharktarget:range(10)))
	var/turf/pickedstart = locate(startx, starty, sharktarget.z)
	var/obj/gibshark/Q = new /obj/gibshark(pickedstart)
	Q.sharktarget2 = sharktarget
	Q.caller = usr
	Q.sharkspeed = speed
//				boutput(sharktarget, "<span style=\"color:red\"><BIG><strong>You have been banned by [usr.client.ckey].<br>Reason: [reason].</strong></BIG></span>")
//				boutput(sharktarget, "<span style=\"color:red\">This is a temporary ban, it will be removed in [sharkmins] minutes.</span>")
//				logTheThing("admin", usr, sharktarget, "has sharked %target%.<br>Reason: [reason]<br>This will be removed in [sharkmins] minutes.")
//				logTheThing("diary", usr, sharktarget, "has sharked %target%.<br>Reason: [reason]<br>This will be removed in [sharkmins] minutes.", "admin")
//				message_admins("<span style=\"color:blue\">[usr.client.ckey] has banned [sharktarget.ckey].<br>Reason: [reason]<br>This will be removed in [sharkmins] minutes.</span>")


/obj/banshark/
	name = "banshark"
	desc = "This is the most terrifying thing you've ever laid eyes on."
	icon = 'icons/misc/banshark.dmi'
	icon_state = "banshark1"
	layer = EFFECTS_LAYER_2
	density = 1
	anchored = 0
	var/mob/sharktarget2 = null
	var/sharkmins2 = null
	var/caller = null
	var/sharkreason = null
	var/sharkcantreach = 0
	var/timelimit = 6
	var/sharkspeed = 1

	New()
		spawn (0) process()
		..()

	Bump(M as turf|obj|mob)
		M:density = 0
		spawn (4)
			M:density = 1
		sleep(1)
		var/turf/T = get_turf(M)
		x = T.x
		y = T.y

	proc/process()
		while (!disposed)
			if (sharkcantreach >= timelimit)
				if (sharkcantreach >= 20)
					qdel(src)
					return
				x = sharktarget2.x
				y = sharktarget2.y
				z = sharktarget2.z
				banproc()
				return
			else if (get_dist(src, sharktarget2) <= 1)
				for (var/mob/O in AIviewers(src, null))
					O.show_message("<span style=\"color:red\"><strong>[src]</strong> bites [sharktarget2]!</span>", 1)
				sharktarget2.weakened += 10
				sharktarget2.stunned += 10
				playsound(loc, 'sound/effects/bang.ogg', 50, 1, -1)
				banproc()
				return
			else
				walk_towards(src, sharktarget2, sharkspeed)
				sleep(10)
				sharkcantreach++

	proc/banproc()
		// drsingh for various cannot read null.
		for (var/mob/O in AIviewers(src, null))
			O.show_message("<span style=\"color:red\"><strong>[src]</strong> bans [sharktarget2] in one bite!</span>", 1)
		playsound(loc, 'sound/items/eatfood.ogg', 30, 1, -2)
		if (sharktarget2 && sharktarget2.client)
			if (sharktarget2.client.holder)
				boutput(sharktarget2, "Here is where you'd get banned.")
				qdel(src)
				return
			var/addData[] = new()
			addData["ckey"] = sharktarget2.ckey
			addData["compID"] =  sharktarget2.computer_id
			addData["ip"] = sharktarget2.client.address
			addData["reason"] = sharkreason
			addData["akey"] = caller:ckey
			addData["mins"] = sharkmins2
			addBan(1, addData)
			boutput(sharktarget2, "<span style=\"color:red\"><BIG><strong>You have been sharked by [usr.client.ckey].<br>Reason: [sharkreason] and he couldn't escape the shark.</strong></BIG></span>")
			boutput(sharktarget2, "<span style=\"color:red\">This is a temporary sharkban, it will be removed in [sharkmins2] minutes.</span>")
			logTheThing("admin", caller:client, sharktarget2, "has sharkbanned %target%. Reason: [sharkreason] and he couldn't escape the shark. This will be removed in [sharkmins2] minutes.")
			logTheThing("diary", caller:client, sharktarget2, "has sharkbanned %target%. Reason: [sharkreason] and he couldn't escape the shark. This will be removed in [sharkmins2] minutes.", "admin")
			message_admins("<span style=\"color:blue\">[caller:client.ckey] has sharkbanned [sharktarget2.ckey].<br>Reason: [sharkreason] and he couldn't escape the shark.<br>This will be removed in [sharkmins2] minutes.</span>")
			del(sharktarget2.client)
			sharktarget2.gib()
//			if (ishuman(sharktarget2))
//				animation = new(loc)
//				animation.icon_state = "blank"
//				animation.icon = 'icons/mob/mob.dmi'
//				animation.master = src
//			if (sharktarget2:client)
		playsound(loc, pick('sound/misc/burp_alien.ogg'), 50, 0)
		qdel(src)

/obj/gibshark/
	name = "gibshark"
	desc = "This is the second most terrifying thing you've ever laid eyes on."
	icon = 'icons/misc/banshark.dmi'
	icon_state = "banshark1"
	layer = EFFECTS_LAYER_2
	density = 1
	anchored = 0
	var/mob/sharktarget2 = null
	var/sharkspeed = 1
	var/caller = null

	New()
		spawn (0) process()
		..()

	Bump(M as turf|obj|mob)
		M:density = 0
		spawn (4)
			M:density = 1
		sleep(1)
		var/turf/T = get_turf(M)
		x = T.x
		y = T.y

	proc/process()
		while (!disposed)
			if (get_dist(src, sharktarget2) <= 1)
				for (var/mob/O in AIviewers(src, null))
					O.show_message("<span style=\"color:red\"><strong>[src]</strong> bites [sharktarget2]!</span>", 1)
				sharktarget2.weakened += 10
				sharktarget2.stunned += 10
				playsound(loc, 'sound/effects/bang.ogg', 50, 1, -1)
				gibproc()
				return
			else
				walk_towards(src, sharktarget2, sharkspeed)
				sleep(10)

	proc/gibproc()
		// drsingh for various cannot read null.
		sleep(15)
		if (get_dist(src, sharktarget2) <= 1)
			for (var/mob/O in AIviewers(src, null))
				O.show_message("<span style=\"color:red\"><strong>[src]</strong> gibs [sharktarget2] in one bite!</span>", 1)
			playsound(loc, 'sound/items/eatfood.ogg', 30, 1, -2)
			if (sharktarget2 && sharktarget2.client)
				logTheThing("admin", caller:client, sharktarget2, "sharkgibbed %target%")
				logTheThing("diary", caller:client, sharktarget2, "sharkgibbed %target%", "admin")
				message_admins("<span style=\"color:blue\">[caller:client.ckey] has sharkgibbed [sharktarget2.ckey].</span>")
				sharktarget2.gib()
			sleep(5)
			playsound(loc, pick('sound/misc/burp_alien.ogg'), 50, 0)
			sleep(5)
			qdel(src)
		else
			process()