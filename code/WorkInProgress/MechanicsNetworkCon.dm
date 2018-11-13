//This is a big messy copy & paste job of several things and thus has been banished to its own file.
//Shouldve probably done it like ibm and have based it on a networked thing instead of duplicating it all here.
//im coder

/obj/item/mechanics/networkcomp
	name = "Powernet-networking component"
	desc = ""
	icon = 'icons/obj/networked.dmi'
	icon_state = "generic-p"

	var/net_id = null
	var/host_id = null //Who are we connected to? (If we have a single host)
	var/old_host_id = null //Were we previously connected to someone?  Do we care?
	var/obj/machinery/power/data_terminal/data_link = null
	var/device_tag = "PNET_MECHNET"

	var/last_reset = 0 //Last world.time we were manually reset.
	var/net_number = 0 //A cute little bitfield (0-3 exposed) to allow multiple networks on one wirenet.  Differentiate between intended hosts, if they care

	var/self_only = 1

	var/ready = 1

	New()
		. = ..()
		net_id = generate_net_id(src)
		verbs -= /obj/item/mechanics/verb/setvalue
		mechanics.addInput("send packet", "spacket")

	verb/togglenwcomps()
		set src in view(1)
		set name = "\[Toggle Self-only messages\]"
		set desc = "Sets whether the component only listens to messages adressed to it."

		if (!istype(usr, /mob/living))
			return
		if (usr.stat)
			return
		if (!mechanics.allowChange(usr))
			boutput(usr, "<span style=\"color:red\">[MECHFAILSTRING]</span>")
			return

		self_only = !self_only
		boutput(usr, "[self_only ? "Now only processing messages adressed at us.":"Now processing all messages recieved."]")
		return

	proc/spacket(var/mechanicsMessage/input)
		if (!ready) return
		ready = 0
		spawn (20) ready = 1
		post_raw(input.signal)
		return

	proc/post_raw(var/rawstring)
		if (!data_link)
			return

		var/signal/signal = get_free_signal()
		signal.source = src
		signal.transmission_method = TRANSMISSION_WIRE

		var/list/inputlist = params2list(rawstring)

		for (var/x in inputlist)
			signal.data[x] = inputlist[x]

		data_link.post_signal(src, signal)

	proc/post_status(var/target_id, var/key, var/value, var/key2, var/value2, var/key3, var/value3, var/key4, var/value4)
		if (!data_link || !target_id)
			return

		var/signal/signal = get_free_signal()
		signal.source = src
		signal.transmission_method = TRANSMISSION_WIRE
		signal.data[key] = value
		if (key2)
			signal.data[key2] = value2
		if (key3)
			signal.data[key3] = value3
		if (key4)
			signal.data[key4] = value4

		signal.data["address_1"] = target_id
		signal.data["sender"] = net_id

		data_link.post_signal(src, signal)

		//command=term_message&data=command=trigger&data=yoursignal&adress_1=targetId&sender=senderId

	proc/sendRaw(var/signal/S)
		var/dataStr = ""//list2params(S.data)  Using list2params() will result in weird glitches if the data already contains a set of params, like in terminal comms
		for (var/i in S.data)
			dataStr += "[i][isnull(S.data[i]) ? ";" : "=[S.data[i]];"]"
		var/mechanicsMessage/msg = mechanics.newSignal(dataStr)
		mechanics.fireOutgoing(msg)
		animate_flash_color_fill(src,"#00AA00",1, 1)
		return

	proc/post_file(var/target_id, var/key, var/value, var/file)
		if (!data_link || !target_id)
			return

		var/signal/signal = get_free_signal()
		signal.source = src
		signal.transmission_method = TRANSMISSION_WIRE
		signal.data[key] = value
		if (file)
			var/computer/file/F = file
			signal.data_file = F.copy_file()

		signal.data["address_1"] = target_id
		signal.data["command"] = "term_file"
		signal.data["sender"] = net_id

		data_link.post_signal(src, signal)

	disposing()
		if (data_link)
			data_link.master = null
			data_link = null

		..()

	attackby(obj/item/W as obj, mob/user as mob)
		if (..(W, user))
			if (level == 1) //wrenched down
				var/turf/T = get_turf(src)
				var/obj/machinery/power/data_terminal/test_link = locate() in T
				icon_state = "generic0"
				if (test_link && !test_link.is_valid_master(test_link.master))
					data_link = test_link
					data_link.master = src
					icon_state = "generic1"
			else if (level == 2) //loose
				resetConnection()
				icon_state = "generic-p"
				if (data_link)
					data_link.master = null
					data_link = null
		return

	proc/resetConnection()
		if (!host_id)
			return

		var/rem_host = src.host_id ? src.host_id : src.old_host_id
		src.host_id = null
		old_host_id = null
		post_status(rem_host, "command","term_disconnect")
		spawn (5)
			post_status(rem_host, "command","term_connect","device",device_tag)
		return

	receive_signal(signal/signal)
		if (!data_link)
			return

		if (!signal || !net_id || signal.encryption || (signal.source == src))
			return

		if (signal.transmission_method != TRANSMISSION_WIRE) //No radio for us thanks
			return

		var/target = signal.data["sender"]

		if ((signal.data["address_1"] != net_id))
			if ((signal.data["address_1"] == "ping") && ((signal.data["net"] == null) || ("[signal.data["net"]]" == "[net_number]")) && signal.data["sender"])
				spawn (5)
					post_status(target, "command", "ping_reply", "device", device_tag, "netid", net_id, "net", "[net_number]")

			if (self_only) return

		sendRaw(signal)

		var/sigcommand = lowertext(signal.data["command"])
		if (sigcommand && signal.data["sender"])
			switch(sigcommand)
				if ("term_connect") //Terminal interface stuff.
					if (target == src.host_id)
						//WHAT IS THIS, HOW COULD THIS HAPPEN??
						src.host_id = null
						updateUsrDialog()
						spawn (3)
							post_status(target, "command","term_disconnect")
						return

					if (src.host_id)
						return

					src.host_id = target
					old_host_id = target
					if (signal.data["data"] != "noreply")
						post_status(target, "command","term_connect","data","noreply","device",device_tag)
					updateUsrDialog()
					spawn (2) //Sign up with the driver (if a mainframe contacted us)
						post_status(target,"command","term_message","data","command=register&data=MECHNET")
					return

				if ("term_ping")
					if (target != src.host_id)
						return
					if (signal.data["data"] == "reply")
						post_status(target, "command","term_ping")
					return

				if ("term_disconnect")
					if (target == src.host_id)
						src.host_id = null
					return

		return