/obj/machinery/autolathe
	name = "Autolathe"
	icon_state = "autolathe"
	desc = "A device that can break down various materials and turn them into other objects."
	density = 1
	var/m_amount = 0.0
	var/g_amount = 0.0
	var/operating = 0.0
	var/opened = 0.0
	var/temp = null
	anchored = 1.0
	var/list/L = list()
	var/list/LL = list()
	var/hacked = 0
	var/disabled = 0
	var/shocked = 0
	var/list/wires = list()
	var/hack_wire
	var/disable_wire
	var/shock_wire
	mats = 20


/obj/machinery/autolathe/attackby(var/obj/item/O as obj, var/mob/user as mob)
	if (istype(O, /obj/item/screwdriver))
		if (!opened)
			opened = 1
			icon_state = "autolathef"
		else
			opened = 0
			icon_state = "autolathe"
		return
	if (opened)
		boutput(user, "You can't load the autolathe while it's opened.")
		return
/*
	if (istype(O, /obj/item/grab) && hacked)
		var/obj/item/grab/G = O
		if (prob(25) && G.affecting)
			G.affecting.gib()
			m_amount += 50000
		return
*/
	if (istype(O, /obj/item/sheet/metal))
		if (m_amount < 150000.0)
			spawn (16) {
				flick("autolathe_c",src)
				m_amount += O:height * O:width * O:length * 100000.0
				O:amount--
				if (O:amount < 1)
					qdel(O)
			}
		else
			boutput(user, "The autolathe is full. Please remove metal from the autolathe in order to insert more.")
	else if (istype(O, /obj/item/sheet/glass) || istype(O, /obj/item/sheet/glass/reinforced))
		if (g_amount < 75000.0)
			spawn (16) {
				flick("autolathe_c",src)
				g_amount += O:height * O:width * O:length * 100000.0
				O:amount--
				if (O:amount < 1)
					qdel(O)
			}
		else
			boutput(user, "The autolathe is full. Please remove glass from the autolathe in order to insert more.")

	else if (O.g_amt || O.m_amt)
		spawn (16) {
			flick("autolathe_c",src)
			g_amount += O.g_amt
			m_amount += O.m_amt
			qdel (O)
		}
	else
		boutput(user, "This object does not contain significant amounts of metal or glass, or cannot be accepted by the autolathe due to size or hazardous materials.")

/obj/machinery/autolathe/attack_hand(user as mob)
	var/dat
	if (..())
		return
	if (shocked)
		shock(user)
	if (opened)
		dat += "Autolathe Wires:<BR>"
		var/wire
		for (wire in wires)
			dat += text("[wire] Wire: <A href='?src=\ref[src];wire=[wire];act=wire'>[wires[wire] ? "Mend" : "Cut"]</A> <A href='?src=\ref[src];wire=[wire];act=pulse'>Pulse</A><BR>")

		dat += text("The red light is [disabled ? "off" : "on"].<BR>")
		dat += text("The green light is [shocked ? "off" : "on"].<BR>")
		dat += text("The blue light is [hacked ? "off" : "on"].<BR>")
		user << browse("<HEAD><TITLE>Autolathe Hacking</TITLE></HEAD>[dat]","window=autolathe_hack")
		onclose(user, "autolathe_hack")
		return
	if (disabled)
		boutput(user, "You press the button, but nothing happens.")
		return
	if (temp)
		dat = text("<TT>[]</TT><BR><BR><A href='?src=\ref[];temp=1'>Clear Screen</A>", temp, src)
	else
		dat = text("<strong>Metal Amount:</strong> [m_amount] cm<sup>3</sup> (MAX: 150,000)<BR><br><FONT color = blue><strong>Glass Amount:</strong></FONT> [g_amount] cm<sup>3</sup> (MAX: 75,000)<HR>")
		var/list/objs = list()
		objs += L
		if (hacked)
			objs += LL
		for (var/obj/t in objs)
			dat += text("<A href='?src=\ref[src];make=\ref[t]'>[t.name] ([t.m_amt] cc metal/[t.g_amt] cc glass)<BR>")
	user << browse("<HEAD><TITLE>Autolathe Control Panel</TITLE></HEAD><TT>[dat]</TT>", "window=autolathe_regular")
	onclose(user, "autolathe_regular")
	return

/obj/machinery/autolathe/Topic(href, href_list)
	if (..() || !(usr in range(1)))
		return
	usr.machine = src
	add_fingerprint(usr)
	if (href_list["make"])
		var/obj/template = locate(href_list["make"])
		if (m_amount >= template.m_amt && g_amount >= template.g_amt)
			operating = 1
			m_amount -= template.m_amt
			g_amount -= template.g_amt
			if (m_amount < 0)
				m_amount = 0
			if (g_amount < 0)
				g_amount = 0
			spawn (16)
				flick("autolathe_c",src)
				spawn (16)
					flick("autolathe_o",src)
					spawn (16)
						new template.type(usr.loc)
						operating = 0

	if (href_list["act"])
		if (href_list["act"] == "pulse")
			if (!istype(usr.equipped(), /obj/item/device/multitool))
				boutput(usr, "You need a multitool!")
			else
				if (wires[href_list["wire"]])
					boutput(usr, "You can't pulse a cut wire.")
				else
					if (hack_wire == href_list["wire"])
						hacked = !hacked
						spawn (100) hacked = !hacked
					if (disable_wire == href_list["wire"])
						disabled = !disabled
						shock(usr)
						spawn (100) disabled = !disabled
					if (shock_wire == href_list["wire"])
						shocked = !shocked
						shock(usr)
						spawn (100) shocked = !shocked
		if (href_list["act"] == "wire")
			if (!istype(usr.equipped(), /obj/item/wirecutters))
				boutput(usr, "You need wirecutters!")
			else
				if (hack_wire == href_list["wire"])
					hacked = !hacked
				if (disable_wire == href_list["wire"])
					disabled = !disabled
					shock(usr)
				if (shock_wire == href_list["wire"])
					shocked = !shocked
					shock(usr)

	if (href_list["temp"])
		temp = null

	for (var/mob/M in viewers(1, src))
		if ((M.client && M.machine == src))
			attack_hand(M)
	return

/obj/machinery/autolathe/New()
	..()
	// screwdriver removed
	L += new /obj/item/wirecutters(src)
	L += new /obj/item/wrench(src)
	L += new /obj/item/crowbar(src)
	L += new /obj/item/weldingtool(src)
	L += new /obj/item/clothing/head/helmet/welding(src)
	L += new /obj/item/device/multitool(src)
	L += new /obj/item/device/flashlight(src)
	L += new /obj/item/extinguisher(src)
	L += new /obj/item/sheet/metal(src)
	L += new /obj/item/sheet/glass(src)
	L += new /obj/item/sheet/r_metal(src)
	L += new /obj/item/sheet/glass/reinforced(src)
	L += new /obj/item/rods(src)
	L += new /obj/item/rcd_ammo(src)
	L += new /obj/item/scalpel(src)
	L += new /obj/item/circular_saw(src)
	L += new /obj/item/device/t_scanner(src)
	L += new /obj/item/reagent_containers/food/drinks/cola_bottle(src)
	L += new /obj/item/device/gps(src)
	LL += new /obj/item/flamethrower(src)
	LL += new /obj/item/device/igniter(src)
	LL += new /obj/item/device/timer(src)
	LL += new /obj/item/rcd(src)
	LL += new /obj/item/device/infra(src)
	LL += new /obj/item/device/infra_sensor(src)
	LL += new /obj/item/handcuffs(src)
	LL += new /obj/item/ammo/bullets/a357(src)
	LL += new /obj/item/ammo/bullets/a38(src)
	LL += new /obj/item/ammo/bullets/a12(src)
	wires["Light Red"] = 0
	wires["Dark Red"] = 0
	wires["Blue"] = 0
	wires["Green"] = 0
	wires["Yellow"] = 0
	wires["Black"] = 0
	wires["White"] = 0
	wires["Gray"] = 0
	wires["Orange"] = 0
	wires["Pink"] = 0
	var/list/w = list("Light Red","Dark Red","Blue","Green","Yellow","Black","White","Gray","Orange","Pink")
	hack_wire = pick(w)
	w -= hack_wire
	shock_wire = pick(w)
	w -= shock_wire
	disable_wire = pick(w)
	w -= disable_wire

/obj/machinery/autolathe/proc/get_connection()
	var/turf/T = loc
	if (!istype(T, /turf/simulated/floor))
		return

	for (var/obj/cable/C in T)
		if (C.d1 == 0)
			return C.netnum

	return FALSE

/obj/machinery/autolathe/proc/shock(M as mob)
	return electrocute(M, 50, get_connection())