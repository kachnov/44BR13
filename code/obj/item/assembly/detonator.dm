/obj/item/assembly/detonator
	desc = "A failsafe timer, wired in an incomprehensible way to a detonator assembly"
	name = "Detonator Assembly"
	icon_state = "multitool-igniter"
	var/obj/item/device/multitool/part_mt = null
	var/obj/item/device/igniter/part_ig = null
	var/obj/item/tank/plasma/part_t = null
	var/obj/item/device/timer/part_fs = null
	var/obj/item/device/trigger = null

	var/obj/item/device/radio/radio = null
	var/obj/machinery/portable_atmospherics/canister/attachedTo = null
	var/list/WireColors = list()
	var/list/obj/item/attachments = list()
	var/safety = 1
	var/defused = 0
	var/grant = 1
	var/shocked = 0
	var/leaks = 0
	var/det_state = 0
	var/list/WireNames = list()
	var/list/WireFunctions = list()
	var/list/WireStatus = list()
	var/dfcodeSet
	var/dfcode
	var/dfcodeTries = 3 //How many code attempts before *boom*
	var/mob/builtBy = null
	var/note = null

	flags = FPRINT | TABLEPASS | CONDUCT
	force = 1.0
	throwforce = 2.0
	throw_speed = 1
	throw_range = 5
	w_class = 2.0

/obj/item/assembly/detonator/New()
	..()
	var/list/WireFuncs
	WireColors = list("Alabama Crimson", "Antique White", "Burnt Umber", "China Rose", "Dodger Blue", "Field Drab", "Harvest Gold", "Jonquil", "Midori", "Neon Carrot", "Oxford Blue", "Periwinkle", "Purple Pizzazz", "Stil De Grain Yellow", "Toolbox Purple", "Urobilin", "Vivid Tangerine", "Yale Blue")
	WireFuncs = list("detonate", "defuse", "safety", "losetime", "mobility", "leak")
	var/i
	for (i=1, i<=6, i++)
		var/N = pick(WireColors)
		WireColors -= N
		var/F = pick(WireFuncs)
		WireNames += N + " wire"
		WireFunctions += F
		WireFuncs -= F
	for (i=1, i<=9, i++)
		WireStatus += 1

/obj/item/assembly/detonator/proc/setDetState(var/newstate)
	switch (newstate)
		if (0)
			desc = "A multitool wired to the activation switch of an igniter, with a slot that seems to be able to hold a rectangular tank in place."
			name = "Multitool/Igniter Assembly"
			icon_state = "multitool-igniter"
			det_state = 0

		if (1)
			desc = "An igniter and a multitool, with the plasma tank inserted into a slot. Most of the wiring is missing. <br>The plasma tank is not secured to the assembly."
			name = "Multitool/Igniter/Tank Assembly"
			icon_state = "m-i-plasma"
			det_state = 1

		if (2)
			desc = "An igniter and a multitool, with the plasma tank inserted into a slot. Most of the wiring is missing. <br>The plasma tank is firmly secured to the assembly."
			name = "Multitool/Igniter/Tank Assembly"
			icon_state = "m-i-plasma"
			det_state = 2

		if (3)
			desc = "An igniter wired to critically weaken a plasma tank when signalled by the multitool. The failsafe wires are unattached."
			name = "Unfinished Detonator Assembly"
			icon_state = "m-i-p-wire"
			det_state = 3

		if (4)
			desc = "A failsafe timer, wired in an incomprehensible way to a detonator assembly"
			name = "Detonator Assembly"
			icon_state = "m-i-p-w-timer"
			det_state = 4

/obj/item/assembly/detonator/attackby(obj/item/W as obj, mob/user as mob)
	switch (det_state)
		if (0)
			if (istype(W, /obj/item/tank/plasma))
				setDetState(1)
				user.u_equip(W)
				W.loc = src
				W.master = src
				W.layer = initial(layer)
				part_t = W
				add_fingerprint(user)
				user.show_message("<span style=\"color:blue\">You insert the [W.name] into the slot.</span>")
			else if (istype(W, /obj/item/wirecutters))
				part_ig.loc = user.loc
				part_mt.loc = user.loc
				part_ig.master = null
				part_mt.master = null
				part_ig = null
				part_mt = null
				user.u_equip(src)
				del(src)
				user.show_message("<span style=\"color:blue\">You sever the connection between the multitool and the igniter. The assembly falls apart.</span>")
			else
				user.show_message("<span style=\"color:red\">The [W.name] doesn't seem to fit into the slot!</span>")

		if (1)
			if (istype(W, /obj/item/cable_coil))
				user.show_message("<span style=\"color:red\">The plasma tank must be firmly secured to the assembly first.</span>")
			else if (istype(W, /obj/item/crowbar))
				setDetState(0)
				part_t.loc = user.loc
				part_t.master = null
				part_t = null
				user.show_message("<span style=\"color:blue\">You pry the plasma tank out of the assembly.</span>")
			else if (istype(W, /obj/item/screwdriver))
				setDetState(2)
				user.show_message("<span style=\"color:blue\">You secure the plasma tank to the assembly.</span>")

		if (2)
			if (istype(W, /obj/item/cable_coil))
				var/obj/item/cable_coil/C = W
				if (C.amount >= 6)
					C.use(6)
					setDetState(3)
					add_fingerprint(user)
					user.show_message("<span style=\"color:blue\">You add the wiring to the assembly.</span>")
				else
					user.show_message("<span style=\"color:red\">This cable coil isn't long enough!</span>")
			else if (istype(W, /obj/item/crowbar))
				user.show_message("<span style=\"color:red\">The plasma tank is firmly secured to the assembly and won't budge.</span>")
			else if (istype(W, /obj/item/screwdriver))
				setDetState(1)
				user.show_message("<span style=\"color:blue\">You unsecure the plasma tank from the assembly.</span>")

		if (3)
			if (istype(W, /obj/item/device/timer))
				setDetState(4)
				user.u_equip(W)
				W.loc = src
				W.master = src
				W.layer = initial(layer)
				part_fs = W
				part_fs.time = 90 //Minimum det time
				add_fingerprint(user)
				user.show_message("<span style=\"color:blue\">You wire the timer failsafe to the assembly, disabling its external controls.</span>")
			else if (istype(W, /obj/item/wirecutters))
				setDetState(2)
				var/obj/item/cable_coil/C = new /obj/item/cable_coil(user, 6)
				C.loc = user.loc
				user.show_message("<span style=\"color:blue\">You cut the wiring on the assembly.</span>")
		if (4)
			if (istype(W, /obj/item/wirecutters))
				setDetState(3)
				part_fs.loc = user.loc
				part_fs.master = null
				part_fs = null
				if (trigger)
					trigger.loc = user.loc
					trigger.master = null
					trigger = null
					user.show_message("<span style=\"color:red\">The triggering device falls off the assembly.</span>")
				for (var/obj/item/a in attachments)
					a.loc = user.loc
					a.master = null
					a.layer = initial(a.layer)
					clear_attachment(a)
					user.show_message("<span style=\"color:red\">The [a] falls off the assembly.</span>")
				attachments.Cut()
				user.show_message("<span style=\"color:blue\">You disconnect the timer from the assembly, and reenable its external controls.</span>")
			if (istype(W, /obj/item/screwdriver))
				if (!trigger && !attachments.len)
					user.show_message("<span style=\"color:red\">You cannot remove any attachments, as there are none attached.</span>")
					return
				var/list/options = list(trigger)
				options += attachments
				options += "cancel"
				var/target = input("Which device do you want to remove?", "Device to remove", "cancel") in options
				if (target == trigger)
					trigger.loc = user.loc
					trigger.master = null
					trigger = null
					user.show_message("<span style=\"color:blue\">You remove the triggering device from the assembly.</span>")
				else if (target == "cancel")
					return
				else
					var/obj/item/T = target
					T.loc = user.loc
					T.master = null
					T.detonator_act("detach", src)
					clear_attachment(target)
					attachments.Remove(target)
					setDescription()
					user.show_message("<span style=\"color:blue\">You remove the [target] from the assembly.</span>")
				setDescription()
			else if (istype(W, /obj/item/device/radio/signaler))
				if (trigger)
					user.show_message("<span style=\"color:red\">There is a trigger already screwed onto the assembly.</span>")
				else
					W.loc = src
					W.master = src
					W.layer = initial(W.layer)
					user.u_equip(W)
					trigger = W
					user.show_message("<span style=\"color:blue\">You attach the [W.name] to the trigger slot.</span>")
					setDescription()
			else if (istype(W, /obj/item/device/radio))
				if (radio)
					user.show_message("<span style=\"color:red\">There is a radio already screwed onto the assembly.</span>")
				else
					W.loc = src
					W.master = src
					W.layer = initial(W.layer)
					user.u_equip(W)
					radio = W
					user.show_message("<span style=\"color:blue\">You attach the [W.name] to the radio slot.</span>")
			else if (istype(W, /obj/item/paper))
				note = W:info
				W.loc = null
				W.master = null
				W.layer = null
				user.u_equip(W)
				user.show_message("<span style=\"color:blue\">You stick the note onto the detonator assembly.</span>")
				del(W)
			else if (W.is_detonator_attachment())
				if (attachments.len < 3)
					W.loc = src
					W.master = src
					W.layer = initial(W.layer)
					user.u_equip(W)
					attachments += W
					W.detonator_act("attach", src)

					var/N = pick(WireColors)
					WireColors -= N
					N += " wire"
					var/pos = rand(0, WireNames.len)
					WireNames.Insert(pos, N)
					WireFunctions.Insert(pos, W)

					user.show_message("<span style=\"color:blue\">You attach the [W.name] to an attachment slot.</span>")
					setDescription()
				else
					user.show_message("<span style=\"color:red\">There are no more free attachment slots on the device!</span>")
					setDescription()

/obj/item/assembly/detonator/proc/clear_attachment(var/obj/item/T)
	var/pos = WireFunctions.Find(T)
	var/N = copytext(WireNames[pos], 1, -5)
	WireColors += N
	WireNames.Cut(pos, pos+1)
	WireFunctions.Cut(pos, pos+1)

/obj/item/assembly/detonator/proc/detonate()
	if (!attachedTo)
		return

	if (force_dud)
		var/turf/T = get_turf(src)
		message_admins("A canister bomb would have detonated at at [T.loc.name] ([showCoords(T.x, T.y, T.z)]) but was forced to dud!")
		return

	attachedTo.anchored = 0
	attachedTo.light.disable()
	if (defused)
		attachedTo.visible_message("<strong><span style=\"color:red\">The cut detonation wire emits a spark. The detonator signal never reached the detonator unit.</span></strong>")
		return
	if (part_t.air_contents.return_pressure() < 400 || part_t.air_contents.toxins < (4*ONE_ATMOSPHERE)*70/(R_IDEAL_GAS_EQUATION*T20C))
		attachedTo.visible_message("<strong><span style=\"color:red\">A sparking noise is heard as the igniter goes off. The plasma tank fails to explode, merely burning the circuits of the detonator.</span></strong>")
		attachedTo.det = null
		attachedTo.overlay_state = null
		del(src)
		return
	attachedTo.visible_message("<strong><span style=\"color:red\">A sparking noise is heard as the igniter goes off. The plasma tank blows, creating a microexplosion and rupturing the canister.</span></strong>")
	if (attachedTo.air_contents.return_pressure() < 7000)
		attachedTo.visible_message("<strong><span style=\"color:red\">The ruptured canister, due to a serious lack of pressure, fails to explode into shreds and leaks its contents into the air.</span></strong>")
		attachedTo.health = 0
		attachedTo.healthcheck()
		attachedTo.det = null
		attachedTo.overlay_state = null
		del(src)
		return
	if (attachedTo.air_contents.temperature < 100000)
		attachedTo.visible_message("<strong><span style=\"color:red\">The ruptured canister shatters from the pressure, but its temperature isn't high enough to create an explosion. Its contents leak into the air.</span></strong>")
		attachedTo.health = 0
		attachedTo.healthcheck()
		attachedTo.det = null
		attachedTo.overlay_state = null
		del(src)
		return

	var/turf/epicenter = get_turf(loc)
	logTheThing("bombing", null, null, "A canister bomb detonates at [epicenter.loc.name] ([showCoords(epicenter.x, epicenter.y, epicenter.z)])")
	message_admins("A canister bomb detonates at [epicenter.loc.name] ([showCoords(epicenter.x, epicenter.y, epicenter.z)])")
	attachedTo.visible_message("<strong><span style=\"color:red\">The ruptured canister shatters from the pressure, and the hot gas ignites.</span></strong>")

	var/power = min(850 * (attachedTo.air_contents.return_pressure() + attachedTo.air_contents.temperature - 107000) / 233196469.0 + 200, 7000) //the second arg is the max explosion power
	//if (power == 150000) //they reached the cap SOMEHOW? well dang they deserve a medal
		//builtBy.unlock_medal("", 1) //WIRE TODO: make new medal for this
	explosion_new(attachedTo, epicenter, power)

/obj/item/assembly/detonator/proc/setDescription()
	desc = "A failsafe timer, wired in an incomprehensible way to a detonator assembly"

	if (trigger)
		src.desc += "<br><span style=\"color:blue\">There is \an [src.trigger.name] as a detonation trigger.</span>"
	if (radio) //WIRE TODO: roll this into the new attachment system
		desc += "<br><span style=\"color:blue\">There is a radio attached to the timing wire, it will announce the bomb status when primed.</span>"
	for (var/obj/item/a in attachments)
		desc += "<br><span style=\"color:blue\">There is \an [a] wired onto the assembly as an attachment.</span>"

/obj/item/assembly/detonator/proc/failsafe_engage()
	if (part_fs.timing)
		return
	part_fs.timing = 1
	part_fs.c_state(1)
	if (!(src in processing_items))
		processing_items.Add(src)
	if (!(part_fs in processing_items))
		processing_items.Add(part_fs)
	dispatch_event("prime")
	if (radio)
		command_alert("A canister bomb is primed in [get_area(src)]! It is set to go off in [part_fs.time] seconds.")
	logTheThing("bombing", usr, null, "primes a canister bomb at [get_area(master)] ([showCoords(master.x, master.y, master.z)])")
	message_admins("[key_name(usr)] primes a canister bomb at [get_area(master)] ([showCoords(master.x, master.y, master.z)])")
	attachedTo.visible_message("<strong><font color=#FF0000>The detonator's priming process initiates. Its timer shows [part_fs.time] seconds.</font></strong>")

// Legacy.
/obj/item/assembly/detonator/proc/leaking()
	dispatch_event("leak")

/obj/item/assembly/detonator/process()
	dispatch_event("process")

/obj/item/assembly/detonator/proc/dispatch_event(event)
	for (var/obj/item/a in attachments)
		a.detonator_act(event, src)

/obj/item/assembly/detonator/receive_signal(signal/signal)
	if (signal)
		if (signal.source == part_fs)
			attachedTo.visible_message("<strong><font color=#FF0000>The failsafe timer's ticks more rapidly with every passing moment, then suddenly goes quiet.</font></strong>")
			detonate()
		else
			failsafe_engage()

/obj/item/proc/is_detonator_attachment()
	return FALSE

// Possible events: attach, detach, leak, process, prime, detonate, cut, pulse
/obj/item/proc/detonator_act(event, var/obj/item/assembly/detonator/det)
	return


//For testing and I'm too lazy to hand-assemble these whenever I need one =I
/obj/item/assembly/detonator/finished

	New()
		..()
		var/obj/item/tank/plasma/ptank = new /obj/item/tank/plasma(src)
		ptank.air_contents.toxins = 30
		ptank.master = src
		part_t = ptank

		var/obj/item/device/timer/timer = new /obj/item/device/timer(src)
		timer.master = src
		part_fs = timer
		part_fs.time = 90 //Minimum det time

		setDetState(4)
