//node1, air1, network1 correspond to input
//node2, air2, network2 correspond to output
//
/obj/machinery/atmospherics/binary/circulatorTemp
	name = "hot gas circulator"
	desc = "It's the gas circulator of a thermoeletric generator."
	icon = 'icons/obj/atmospherics/pipes.dmi'
	icon_state = "circ1-off"

	var/side = 1 // 1=left 2=right
	var/last_pressure_delta = 0

	anchored = 1.0
	density = 1

	proc/return_transfer_air()
		var/output_starting_pressure = air2.return_pressure()
		var/input_starting_pressure = air1.return_pressure()

		//Calculate necessary moles to transfer using PV = nRT
		var/pressure_delta = abs((input_starting_pressure - output_starting_pressure))/2

		var/transfer_moles = pressure_delta*air2.volume/max((air1.temperature * R_IDEAL_GAS_EQUATION), 1) //Stop annoying runtime errors

		last_pressure_delta = pressure_delta

		//Actually transfer the gas
		var/gas_mixture/removed = air1.remove(transfer_moles)

		if (network1)
			network1.update = 1

		if (network2)
			network2.update = 1

		return removed

	process()
		..()
		update_icon()

	update_icon()
		if (stat & (BROKEN|NOPOWER))
			icon_state = "circ[side]-p"
		else if (last_pressure_delta > 0)
			if (last_pressure_delta > ONE_ATMOSPHERE)
				icon_state = "circ[side]-run"
			else
				icon_state = "circ[side]-slow"
		else
			icon_state = "circ[side]-off"

		return TRUE

/obj/machinery/atmospherics/binary/circulatorTemp/right
	side = 2
	icon_state = "circ2-off"
	name = "cold gas circulator"

/obj/machinery/power/monitor
	name = "Power Monitoring Computer"
	icon = 'icons/obj/computer.dmi'
	icon_state = "power"
	density = 1
	anchored = 1

/obj/machinery/power/generatorTemp
	name = "generator"
	desc = "A high efficiency thermoelectric generator."
	icon_state = "teg"
	anchored = 1
	density = 1
	//var/lightsbusted = 0

	var/obj/machinery/atmospherics/binary/circulatorTemp/circ1
	var/obj/machinery/atmospherics/binary/circulatorTemp/right/circ2

	var/lastgen = 0
	var/lastgenlev = -1
	var/overloaded = 0
	var/running = 0
	var/spam_limiter = 0  // stop the lights and icon updates from spazzing out as much at the threshold between power tiers
	var/efficiency_controller = 52 // cogwerks - debugging/testing var
	var/light/light

	var/boost = 0

	var/grump = 0 // best var 2013
	var/grumping = 0 // is the engine currently doing grumpy things

	var/list/grump_prefix = list("an upsetting", "an unsettling",
	"a scary", "a loud", "a sassy", "a grouchy", "a grumpy",
	"an awful", "a horrible", "a despicable", "a pretty rad", "a godawful")

	var/list/grump_suffix = list("noise", "racket", "ruckus", "sound", "clatter", "fracas", "hubbub")

	var/sound_engine1 = 'sound/machines/tractor_running.ogg'
	var/sound_engine2 = 'sound/machines/engine_highpower.ogg'
	var/sound_tractorrev = 'sound/machines/tractorrev.ogg'
	var/sound_engine_alert1 = 'sound/machines/engine_alert1.ogg'
	var/sound_engine_alert2 = 'sound/machines/engine_alert2.ogg'
	var/sound_engine_alert3 = 'sound/machines/engine_alert3.ogg'
	var/sound_bigzap = 'sound/effects/elec_bigzap.ogg'
	var/sound_bellalert = 'sound/machines/bellalert.ogg'
	var/sound_warningbuzzer = 'sound/machines/warning-buzzer.ogg'

	New()
		..()

		light = new /light/point
		light.attach(src)

		spawn (5)
			circ1 = locate(/obj/machinery/atmospherics/binary/circulatorTemp) in get_step(src,WEST)
			circ2 = locate(/obj/machinery/atmospherics/binary/circulatorTemp/right) in get_step(src,EAST)
			if (!circ1 || !circ2)
				stat |= BROKEN

			updateicon()

	proc/updateicon()

		if (stat & (NOPOWER|BROKEN))
			overlays = null
		else
			overlays = null

			if (lastgenlev != 0)
				overlays += image('icons/obj/power.dmi', "teg-op[lastgenlev]")

			switch (lastgenlev)
				if (0)
					light.disable()
				if (1 to 11)
					light.set_color(1, 1, 1)
					light.set_brightness(0.3)
				if (12 to 15)
					light.set_color(0.30,0.30,0.90)
					light.set_brightness(0.6)
					light.enable()
				if (16 to 17)
					light.set_color(0.90,0.90,0.10)
					light.set_brightness(0.6)
					light.enable()
				if (18 to 22)
					playsound(loc, "sound/effects/elec_bzzz.ogg", 50,0)
					light.set_color(0.90,0.10,0.10)
					light.set_brightness(0.6)
					light.enable()
				if (18 to 25)
					playsound(loc, "sound/effects/elec_bigzap.ogg", 50,0)
					light.set_color(0.90,0.10,0.10)
					light.set_brightness(1)
					light.enable()
				if (26 to INFINITY)
					playsound(loc, "sound/effects/electric_shock.ogg", 50,0)
					light.set_color(0.90,0.00,0.90)
					light.set_brightness(1.5)
					light.enable()
					// this needs a safer lightbust proc

	process()
		if (!circ1 || !circ2)
			return

		var/gas_mixture/hot_air = circ1.return_transfer_air()
		var/gas_mixture/cold_air = circ2.return_transfer_air()

		lastgen = 0

		if (cold_air && hot_air)
			var/cold_air_heat_capacity = cold_air.heat_capacity()
			var/hot_air_heat_capacity = hot_air.heat_capacity()

			var/delta_temperature = hot_air.temperature - cold_air.temperature

			// uncomment to debug
			// logTheThing("debug", null, null, "pre delta, cold temp = [cold_air.temperature], hot temp = [hot_air.temperature]")
			// logTheThing("debug", null, null, "pre prod, delta : [delta_temperature], cold cap [cold_air_heat_capacity], hot cap [hot_air_heat_capacity]")
			if (delta_temperature > 0 && cold_air_heat_capacity > 0 && hot_air_heat_capacity > 0)
				var/efficiency = (1 - cold_air.temperature/hot_air.temperature) * (efficiency_controller * 0.01) //controller expressed as a percentage

				var/energy_transfer = delta_temperature*hot_air_heat_capacity*cold_air_heat_capacity/(hot_air_heat_capacity+cold_air_heat_capacity)

				var/heat = energy_transfer*(1-efficiency)
				lastgen = energy_transfer*efficiency

				hot_air.temperature = hot_air.temperature - energy_transfer/hot_air_heat_capacity
				cold_air.temperature = cold_air.temperature + heat/cold_air_heat_capacity

				// uncomment to debug
				//logTheThing("debug", null, null, "POWER: [lastgen] W generated at [efficiency*100]% efficiency and sinks sizes [cold_air_heat_capacity], [hot_air_heat_capacity]")

				add_avail(lastgen)
		// update icon overlays only if displayed level has changed

		if (hot_air)
			circ1.air2.merge(hot_air)

		if (cold_air)
			circ2.air2.merge(cold_air)
		desc = "Current Output: [engineering_notation(lastgen)]W"
		var/genlev = max(0, min(round(26*lastgen / 4000000), 26)) // raised 2MW toplevel to 3MW, dudes were hitting 2mw way too easily
		if ((genlev != lastgenlev) && !spam_limiter)
			spam_limiter = 1
			lastgenlev = genlev
			updateicon()
			if (!genlev)
				running = 0
			else if (genlev && !running)
				playsound(loc, sound_tractorrev, 55, 0)
				running = 1
			spawn (5)
				spam_limiter = 0
		updateDialog()

// engine looping sounds and hazards
		if (lastgenlev > 0)
			if (grump < 0) // grumpcode
				grump = 0 // no negative grump plz
			grump++ // get grump'd
			if (grump >= 100 && prob(5))
				playsound(loc, pick(sounds_enginegrump), 70, 0)
				visible_message("<span style=\"color:red\">[src] makes [pick(grump_prefix)] [pick(grump_suffix)]!</span>")
				grump -= 5
		switch (lastgenlev)
			if (0)
				return
			if (1 to 2)
				playsound(loc, sound_engine1, 60, 0)
				if (prob(5))
					playsound(loc, pick(sounds_engine), 70, 0)
			if (3 to 11)
				playsound(loc, sound_engine1, 60, 0)
			if (12 to 15)
				playsound(loc, sound_engine2, 60, 0)
			if (16 to 18)
				playsound(loc, sound_bellalert, 60, 0)
				if (prob(5))
					var/effects/system/spark_spread/s = unpool(/effects/system/spark_spread)
					s.set_up(2, 1, (get_turf(src)))
					s.start()
			if (19 to 21)
				playsound(loc, sound_warningbuzzer, 50, 0)
				if (prob(5))
					var/effects/system/bad_smoke_spread/smoke = new /effects/system/bad_smoke_spread()
					smoke.set_up(1, 0, loc)
					smoke.attach(src)
					smoke.start()
					visible_message("<span style=\"color:red\">[src] starts smoking!</span>")
				if (!grumping && grump >= 100 && prob(5))
					grumping = 1
					playsound(loc, "sound/machines/engine_grump1.ogg", 50, 0)
					visible_message("<span style=\"color:red\">[src] erupts in flame!</span>")
					fireflash(src, 1)
					grumping = 0
					grump -= 10
			if (22 to 23)
				playsound(loc, sound_engine_alert1, 55, 0)
				if (prob(5)) zapStuff()
				if (prob(5))
					var/effects/system/bad_smoke_spread/smoke = new /effects/system/bad_smoke_spread()
					smoke.set_up(1, 0, loc)
					smoke.attach(src)
					smoke.start()
					visible_message("<span style=\"color:red\">[src] starts smoking!</span>")
				if (!grumping && grump >= 100 && prob(5))
					grumping = 1
					playsound(loc, "sound/machines/engine_grump1.ogg", 50, 0)
					visible_message("<span style=\"color:red\">[src] erupts in flame!</span>")
					fireflash(src, rand(1,3))
					grumping = 0
					grump -= 30

			if (24 to 25)
				playsound(loc, sound_engine_alert1, 55, 0)
				if (prob(10)) // lowering a bit more
					zapStuff()
				if (prob(5))
					var/effects/system/bad_smoke_spread/smoke = new /effects/system/bad_smoke_spread()
					smoke.set_up(1, 0, loc)
					smoke.attach(src)
					smoke.start()
					visible_message("<span style=\"color:red\">[src] starts smoking!</span>")
				if (!grumping && grump >= 100 && prob(10)) // probably not good if this happens several times in a row
					grumping = 1
					playsound(loc, "sound/weapons/rocket.ogg", 50, 0)
					visible_message("<span style=\"color:red\">[src] explodes in flame!</span>")
					var/firesize = rand(1,4)
					fireflash(src, firesize)
					for (var/atom/movable/M in view(firesize, loc)) // fuck up those jerkbag engineers
						if (M.anchored) continue
						if (ismob(M)) if (hasvar(M,"weakened")) M:weakened += 8
						if (ismob(M)) random_brute_damage(M, 10)
						if (ismob(M))
							var/atom/targetTurf = get_edge_target_turf(M, get_dir(src, get_step_away(M, src)))
							M.throw_at(targetTurf, 200, 4)
						else if (prob(15)) // cut down the number of other junk things that get blown around
							var/atom/targetTurf = get_edge_target_turf(M, get_dir(src, get_step_away(M, src)))
							M.throw_at(targetTurf, 200, 4)
					grumping = 0
					grump -= 30

			if (26 to INFINITY)
				playsound(loc, sound_engine_alert3, 55, 0)
				if (!grumping && grump >= 100 && prob(6))
					grumping = 1
					visible_message("<span style=\"color:red\"><strong>[src] [pick("resonates", "shakes", "rumbles", "grumbles", "vibrates", "roars")] [pick("dangerously", "strangely", "ominously", "frighteningly", "grumpily")]!</strong></span>")
					playsound(loc, "sound/effects/explosionfar.ogg", 65, 1)
					for (var/obj/window/W in range(6, loc)) // smash nearby windows
						if (W.health_max >= 80) // plasma glass or better, no break please and thank you
							continue
						if (prob(get_dist(W,loc)*6))
							continue
						W.health = 0
						W.smash()
					for (var/mob/living/M in range(6, loc))
						shake_camera(M, 3, 2)
						M.weakened++
					for (var/atom/A in range(rand(1,3), loc))
						if (istype(A, /turf/simulated))
							A.pixel_x = rand(-1,1)
							A.pixel_y = rand(-1,1)
					grumping = 0
					grump -= 30

					if (lastgen >= 10000000)
						for (var/turf/T in range(6, src))
							var/T_dist = get_dist(T, src)
							var/T_effect_prob = 100 * (1 - (max(T_dist-1,1) / 5))

							for (var/obj/item/I in T)
								if ( prob(T_effect_prob) )
									animate_float(I, 1, 3)

				if (prob(33)) // lowered because all the DEL procs related to zap are stacking up in the profiler
					zapStuff()
				if (prob(5))
					visible_message("<span style=\"color:red\">[src] [pick("rumbles", "groans", "shudders", "grustles", "hums", "thrums")] [pick("ominously", "oddly", "strangely", "oddly", "worringly", "softly", "loudly")]!</span>")
				else if (prob(2))
					visible_message("<span style=\"color:red\"><strong>[src] hungers!</strong></span>")
				// todo: sorta run happily at this extreme level as long as it gets a steady influx of corpses OR WEED into the furnaces

	proc/zapStuff()
		var/atom/target = null
		var/atom/last = src

		var/list/starts = new/list()
		for (var/atom/movable/M in orange(3, src))
			if (istype(M, /obj/overlay/tile_effect) || M.invisibility) continue
			starts.Add(M)

		if (!starts.len) return

		if (prob(10))
			var/person = null
			person = (locate(/mob/living) in starts)
			if (person)
				target = person
			else
				target = pick(starts)
		else
			target = pick(starts)

		if (isturf(target))
			return //This should not be possible. But byond.

		playsound(target, sound_bigzap, 40, 1)

		for (var/count=0, count<3, count++)

			if (target == null) break

			var/list/affected = DrawLine(last, target, /obj/line_obj/elec ,'icons/obj/projectiles.dmi',"WholeLghtn",1,1,"HalfStartLghtn","HalfEndLghtn",OBJ_LAYER,1,PreloadedIcon='icons/effects/LghtLine.dmi')

			for (var/obj/O in affected)
				spawn (6) pool(O)

			//var/turf/currTurf = get_turf(target)
			//currTurf.hotspot_expose(2000, 400)

			if (istype(target, /mob/living)) //Probably unsafe.
				target:TakeDamage("chest", 0, 20)

			var/list/next = new/list()
			for (var/atom/movable/M in orange(2, target))
				if (istype(M, /obj/overlay/tile_effect) || istype(M, /obj/line_obj/elec) || M.invisibility) continue
				next.Add(M)

			last = target
			target = pick(next)


	attack_ai(mob/user)
		if (stat & (BROKEN|NOPOWER)) return

		interact(user)

	attack_hand(mob/user)

		add_fingerprint(user)

		if (stat & (BROKEN|NOPOWER)) return

		interact(user)

	proc/interact(mob/user)
		if ( (get_dist(src, user) > 1 ) && (!istype(user, /mob/living/silicon/ai)))
			user.machine = null
			user << browse(null, "window=teg")
			return

		user.machine = src

		var/t = "<PRE><strong>Thermo-Electric Generator</strong><HR>"

		t += "Output : [engineering_notation(lastgen)]W<BR><BR>"

		t += "<strong>Hot loop</strong><BR>"
		t += "Temperature Inlet: [round(circ1.air1.temperature, 0.1)] K  Outlet: [round(circ1.air2.temperature, 0.1)] K<BR>"
		t += "Pressure Inlet: [round(circ1.air1.return_pressure(), 0.1)] kPa  Outlet: [round(circ1.air2.return_pressure(), 0.1)] kPa<BR>"

		t += "<strong>Cold loop</strong><BR>"
		t += "Temperature Inlet: [round(circ2.air1.temperature, 0.1)] K  Outlet: [round(circ2.air2.temperature, 0.1)] K<BR>"
		t += "Pressure Inlet: [round(circ2.air1.return_pressure(), 0.1)] kPa  Outlet: [round(circ2.air2.return_pressure(), 0.1)] kPa<BR>"

		t += "<BR><HR><A href='?src=\ref[src];close=1'>Close</A>"

		t += "</PRE>"
		user << browse(t, "window=teg;size=460x300")
		onclose(user, "teg")
		return TRUE

	Topic(href, href_list)
		..()

		if ( href_list["close"] )
			usr << browse(null, "window=teg")
			usr.machine = null
			return FALSE

		return TRUE

	power_change()
		..()
		updateicon()

/obj/machinery/atmospherics/unary/furnace_connector

	icon = 'icons/obj/atmospherics/heat_reservoir.dmi'
	icon_state = "intact_off"
	density = 1

	name = "Furnace Connector"
	desc = "Used to connect a furnace to a pipe network."

	var/current_temperature = T20C
	var/current_heat_capacity = 3000

	update_icon()
		if (node)
			icon_state = "intact_on"
		else
			icon_state = "exposed"
		return

	process()
		..()
		return

	proc/heat()
		var/air_heat_capacity = air_contents.heat_capacity()
		var/combined_heat_capacity = current_heat_capacity + air_heat_capacity
		var/old_temperature = air_contents.temperature

		if (combined_heat_capacity > 0)
			var/combined_energy = current_temperature*current_heat_capacity + air_heat_capacity*air_contents.temperature
			air_contents.temperature = combined_energy/combined_heat_capacity

		if (abs(old_temperature-air_contents.temperature) > 1)
			if (network)
				network.update = 1
		return TRUE

/obj/machinery/power/furnace/thermo
	name = "Furnace"
	desc = "Generates Heat for the thermoelectric generator."
	icon_state = "furnace"
	anchored = 1
	density = 1
	mats = 20

	var/obj/machinery/atmospherics/unary/furnace_connector/f_connector = null

	proc/get_connector()
		for (var/obj/machinery/atmospherics/unary/furnace_connector/C in loc)
			f_connector = C
			break
		return

	New()
		..()
		get_connector()

	process()
		if (!f_connector) get_connector()
		if (!f_connector) return
		..()
/*
		if (active)
			if (fuel)
				var/additional_heat = fuel * 4
				f_connector.current_temperature = T20C + 200 + additional_heat
				f_connector.heat()
				fuel--

			if (!fuel)
				visible_message("<span style=\"color:red\">[src] runs out of fuel and shuts down!</span>")
				overlays = null
				active = 0

		update_icon()

	/*	//Holy lag batman!
		overlays = null
		if (active) overlays +=
		if (fuelperc >= 20) overlays += image('icons/obj/power.dmi', "furn-c1")
		if (fuelperc >= 40) overlays += image('icons/obj/power.dmi', "furn-c2")
		if (fuelperc >= 60) overlays += image('icons/obj/power.dmi', "furn-c3")
		if (fuelperc >= 80) overlays += image('icons/obj/power.dmi', "furn-c4")

	*/
*/
	on_burn()
		var/additional_heat = fuel * 4
		f_connector.current_temperature = T20C + 200 + additional_heat
		f_connector.heat()


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#define PUMP_POWERLEVEL_1 100
#define PUMP_POWERLEVEL_2 500
#define PUMP_POWERLEVEL_3 1000
#define PUMP_POWERLEVEL_4 2500
#define PUMP_POWERLEVEL_5 5000

/pump_infoset
	var/power_status = 0
	var/target_output = 0
	var/id = ""

/obj/machinery/computer/atmosphere/pumpcontrol
	req_access = list() //Change
	req_access_txt = ""

	icon = 'icons/obj/computer.dmi'
	icon_state = "computer_generic"

	name = "Pump control computer"

	var/list/pump_infos = new/list()

	var/last_change = 0
	var/message_delay = 600

	var/frequency = 1225
	var/radio_frequency/radio_connection

	attack_hand(mob/user)
		if (stat & (BROKEN | NOPOWER))
			return
		user << browse(return_text(),"window=computer")
		user.machine = src
		onclose(user, "computer")

	process()
		..()
		if (stat & (BROKEN | NOPOWER))
			return
		//updateDialog()

	attackby(I as obj, user as mob)
			//Readd construction code + boards
		attack_hand(user)
		return

	receive_signal(signal/signal)
		if (!signal || signal.encryption)
			return

		if (signal.data["device"] == "AGP")
			if (!signal.data["tag"] || !signal.data["power"] || !signal.data["target_output"])
				return

			var/pump_infoset/I = new()
			I.id = signal.data["tag"]
			I.power_status = signal.data["power"]
			I.target_output = signal.data["target_output"]

			if (!(signal.source in pump_infos))
				var/area/pump_area = get_area(signal.source)
				if (istype(pump_area))
					var/area_label_position = pump_infos.Find(pump_area.name)
					if (area_label_position)
						while (1)
							area_label_position++
							if (area_label_position > pump_infos.len)
								break
							var/pump_infoset/infoset = pump_infos[ pump_infos[area_label_position] ]
							if (!istype(infoset))
								break

							if (sorttext(I.id, infoset.id) == 1)
								break

						pump_infos.Insert(area_label_position, signal.source)

					else
						pump_infos += pump_area.name
						pump_infos += signal.source

			pump_infos[signal.source] = I

		updateDialog()

	proc/return_text()
		var/pump_html = ""
		//var/count = 1
		for (var/A in pump_infos)
			if (istext(A))
				pump_html += "<center><strong>[A]</strong></center><br>"
				continue

			var/pump_infoset/I = pump_infos[A]
			if (!istype(I))
				continue
			pump_html += "<strong>[I.id] Status</strong>:<BR>"
			//pump_html += "<strong>Pump [count] Status</strong>: <BR>"
			//pump_html += "	Pump Id: [I.id]<BR>"
			pump_html += "	Pump Status: <U><A href='?src=\ref[src];toggle=[I.id]'>[I.power_status == "on" ? "On":"Off"]</A></U><BR>"
			var/current_pump_level = 0
			switch (I.target_output)
				if (1 to PUMP_POWERLEVEL_1)
					current_pump_level = 1
				if (PUMP_POWERLEVEL_1 + 1 to PUMP_POWERLEVEL_2)
					current_pump_level = 2
				if (PUMP_POWERLEVEL_2 + 1 to PUMP_POWERLEVEL_3)
					current_pump_level = 3
				if (PUMP_POWERLEVEL_3 + 1 to PUMP_POWERLEVEL_4)
					current_pump_level = 4
				if (PUMP_POWERLEVEL_4 + 1 to INFINITY)
					current_pump_level = 5
			pump_html += "	Pump Pressure Level: "
			for (var/i =1, i < 6, i++)
				if (current_pump_level == i)
					pump_html += "<strong>[i]</strong> "
				else
					pump_html += "<A href='?src=\ref[src];setoutput=[i]&target=[I.id]'>[i]</A> "

			pump_html += "<BR><BR>"
			//count++

		var/output = "<strong>[name]</strong><BR><A href='?src=\ref[src];refresh=1'>Refresh</A><BR><HR><strong>Pump Data: <BR><BR></strong>[pump_html]<HR>"
		return output

	Topic(href, href_list)
		if (..())
			return
		if (!allowed(usr))
			boutput(usr, "<span style=\"color:red\">Access Denied!</span>")
			return

		if (href_list["toggle"])
			add_fingerprint(usr)
			if (!radio_connection)
				return FALSE
			var/signal/signal = get_free_signal()
			signal.transmission_method = 1 //radio
			signal.source = src
			signal.data["tag"] = href_list["toggle"]
			signal.data["command"] = "power_toggle"
			radio_connection.post_signal(src, signal)

		if (href_list["setoutput"])
			add_fingerprint(usr)
			if (!radio_connection || !href_list["target"])
				return FALSE

			var/new_target = 0
			switch (href_list["setoutput"])
				if ("1")
					new_target = PUMP_POWERLEVEL_1
				if ("2")
					new_target = PUMP_POWERLEVEL_2
				if ("3")
					new_target = PUMP_POWERLEVEL_3
				if ("4")
					new_target = PUMP_POWERLEVEL_4
				if ("5")
					new_target = PUMP_POWERLEVEL_5

			if (!new_target)
				return

			var/signal/signal = get_free_signal()
			signal.transmission_method = 1 //radio
			signal.source = src
			signal.data["tag"] = href_list["target"]
			signal.data["command"] = "set_output_pressure"
			signal.data["parameter"] = new_target
			radio_connection.post_signal(src, signal)

		if (href_list["refresh"])
			add_fingerprint(usr)
			if (!radio_connection)
				return FALSE
			var/signal/signal = get_free_signal()
			signal.transmission_method = 1 //radio
			signal.source = src
			signal.data["command"] = "broadcast_status"
			radio_connection.post_signal(src, signal)
	proc
		set_frequency(new_frequency)
			radio_controller.remove_object(src, "[frequency]")
			frequency = new_frequency
			radio_connection = radio_controller.add_object(src, "[frequency]")

	initialize()
		set_frequency(frequency)

#undef PUMP_POWERLEVEL_1
#undef PUMP_POWERLEVEL_2
#undef PUMP_POWERLEVEL_3
#undef PUMP_POWERLEVEL_4
#undef PUMP_POWERLEVEL_5