/obj/machinery/portable_atmospherics/canister
	name = "canister"
	icon = 'icons/obj/atmospherics/atmos.dmi'
	density = 1
	var/health = 100.0
	flags = FPRINT | CONDUCT

	var/has_valve = 1
	var/valve_open = 0
	var/release_pressure = ONE_ATMOSPHERE

	var/casecolor = "blue"
	var/filled = 0.5
	pressure_resistance = 7*ONE_ATMOSPHERE
	var/temperature_resistance = 1000 + T0C
	volume = 1000
	desc = "A container which holds a large amount of the labelled gas. It's possible to transfer the gas to a pipe system, the air, or to a tank that you attach to it."
	var/overpressure = 0 // for canister explosions
	var/rupturing = 0
	var/obj/item/assembly/detonator/det = null
	var/overlay_state = null
	var/dialog_update_enabled = 1 //For preventing the DAMNABLE window taking focus when manually inputting pressure
	var/light/light = null

	var/global/image/atmos_dmi = image('icons/obj/atmospherics/atmos.dmi')
	var/global/image/bomb_dmi = image('icons/obj/canisterbomb.dmi')

	onMaterialChanged()
		..()
		if (istype(material))
			temperature_resistance = 400 + T0C + (material.getProperty(PROP_MELTING)) - (material.getProperty(PROP_FLAMMABILITY) * 2)
			temperature_resistance = ((material.getProperty(PROP_FLAMMABILITY) > 75) ? T0C + 50 : temperature_resistance)
		return

	suicide(var/mob/user as mob)
		if (release_pressure < 5*ONE_ATMOSPHERE || air_contents.return_pressure() < 5*ONE_ATMOSPHERE) return FALSE
		user.visible_message("<span style=\"color:red\"><strong>[user] holds \his mouth to the [name]'s release valve and briefly opens it!</strong></span>")
		user.gib()
		return TRUE

/obj/machinery/portable_atmospherics/canister/sleeping_agent
	name = "Canister: \[N2O\]"
	icon_state = "redws"
	casecolor = "redws"
/obj/machinery/portable_atmospherics/canister/nitrogen
	name = "Canister: \[N2\]"
	icon_state = "red"
	casecolor = "red"
/obj/machinery/portable_atmospherics/canister/oxygen
	name = "Canister: \[O2\]"
	icon_state = "blue"
/obj/machinery/portable_atmospherics/canister/toxins
	name = "Canister \[Plasma\]"
	icon_state = "orange"
	casecolor = "orange"
/obj/machinery/portable_atmospherics/canister/carbon_dioxide
	name = "Canister \[CO2\]"
	icon_state = "black"
	casecolor = "black"
/obj/machinery/portable_atmospherics/canister/air
	name = "Canister \[Air\]"
	icon_state = "grey"
	casecolor = "grey"
/obj/machinery/portable_atmospherics/canister/air/large
	name = "High-Volume Canister \[Air\]"
	icon_state = "greyred"
	casecolor = "greyred"
	filled = 2.0
/obj/machinery/portable_atmospherics/canister/empty
	name = "Canister \[Empty\]"
	icon_state = "empty"
	casecolor = "empty"

/obj/machinery/portable_atmospherics/canister/New()
	..()

	light = new /light/point
	light.set_brightness(0.6)
	light.attach(src)

/obj/machinery/portable_atmospherics/canister/update_icon()

	if (destroyed)
		icon_state = "[casecolor]-1"
		ClearAllOverlays()
	else
		icon_state = "[casecolor]"
		if (overlay_state)
			if (det.part_fs.timing && !det.safety && !det.defused)
				if (det.part_fs.time > 5)
					bomb_dmi.icon_state = "overlay_ticking"
					UpdateOverlays(bomb_dmi, "canbomb")
				else
					bomb_dmi.icon_state = "overlay_exploding"
					UpdateOverlays(bomb_dmi, "canbomb")
			else
				bomb_dmi.icon_state = overlay_state
				UpdateOverlays(bomb_dmi, "canbomb")
		else
			UpdateOverlays(null, "canbomb")

		if (holding)
			atmos_dmi.icon_state = "can-oT"
			UpdateOverlays(atmos_dmi, "holding")
		else
			UpdateOverlays(null, "holding")
		var/tank_pressure = air_contents.return_pressure()

		if (tank_pressure < 10)
			atmos_dmi.icon_state = "can-o0"
		else if (tank_pressure < ONE_ATMOSPHERE)
			atmos_dmi.icon_state = "can-o1"
		else if (tank_pressure < 15*ONE_ATMOSPHERE)
			atmos_dmi.icon_state = "can-o2"
		else
			atmos_dmi.icon_state = "can-o3"

		UpdateOverlays(atmos_dmi, "pressure")
	return

/obj/machinery/portable_atmospherics/canister/temperature_expose(gas_mixture/air, exposed_temperature, exposed_volume)
	if (reagents) reagents.temperature_reagents(exposed_temperature, exposed_volume)
	if (exposed_temperature > temperature_resistance)
		health -= 5
		healthcheck()

/obj/machinery/portable_atmospherics/canister/proc/healthcheck()
	if (destroyed)
		return TRUE

	if (health <= 10)
		message_admins("[src] was destructively opened, emptying contents at [log_loc(src)]. See station logs for atmos readout.")
		logTheThing("station", null, null, "[src] [log_atmos(src)] was destructively opened, emptying contents at [log_loc(src)].")

		var/atom/location = loc
		location.assume_air(air_contents)
		air_contents = null

		if (det)
			processing_items.Remove(det)

		destroyed = 1
		playsound(loc, "sound/effects/spray.ogg", 10, 1, -3)
		density = 0
		update_icon()

		if (holding)
			holding.set_loc(loc)
			holding = null
		return TRUE
	else
		return TRUE


/obj/machinery/portable_atmospherics/canister/process()
	if (!loc) return
	if (destroyed) return
	if (contained) return

	..()

	var/gas_mixture/environment

	if (holding)
		environment = holding.air_contents
	else
		environment = loc.return_air()

	if (!environment)
		return

	var/env_pressure = environment.return_pressure()

	if (valve_open)
		var/pressure_delta = min(release_pressure - env_pressure, (air_contents.return_pressure() - env_pressure)/2)
		//Can not have a pressure delta that would cause environment pressure > tank pressure

		var/transfer_moles = 0
		if ((air_contents.temperature > 0) && (pressure_delta > 0))
			transfer_moles = pressure_delta*environment.volume/(air_contents.temperature * R_IDEAL_GAS_EQUATION)

			//Actually transfer the gas
			var/gas_mixture/removed = air_contents.remove(transfer_moles)

			if (holding)
				environment.merge(removed)
			else
				loc.assume_air(removed)

	overpressure = air_contents.return_pressure() / maximum_pressure

	switch(overpressure) // should the canister blow the hell up?

		if (0 to 11)
			if (rupturing) rupturing = 0
		if (12 to 13)
			if (prob(4))
				visible_message("<span style=\"color:red\">[src] hisses!</span>")
				playsound(loc, "sound/machines/hiss.ogg", 50, 1)
		if (14 to 15)
			if (prob(3) && !rupturing)
				rupture()
		if (16 to INFINITY)
			if (!rupturing)
				rupture()

	//Canister bomb grumpy sounds
	if (det && det.part_fs)
		if (det.part_fs.timing) //If it's counting down
			if (det.part_fs.time > 9)
				light.set_color(0.94, 0.94, 0.3)
				light.enable()
				if (prob(15))
					switch(rand(1,10))
						if (1)
							playsound(loc, "sparks", 75, 1, -1)
							var/effects/system/spark_spread/s = unpool(/effects/system/spark_spread)
							s.set_up(3, 1, src)
							s.start()
						if (2)
							playsound(loc, "sound/machines/warning-buzzer.ogg", 50, 1)
						if (3)
							playsound(loc, "sound/machines/hiss.ogg", 50, 1)
						if (4)
							playsound(loc, "sound/machines/bellalert.ogg", 50, 1)
						if (5)
							for (var/obj/machinery/power/apc/theAPC in get_area(src))
								theAPC.lighting = 0
								theAPC.updateicon()
								theAPC.update()
								visible_message("<span style=\"color:red\">The lights mysteriously go out!</span>")
						if (6)
							for (var/obj/machinery/power/apc/theAPC in get_area(src))
								theAPC.lighting = 3
								theAPC.updateicon()
								theAPC.update()

			else if (det.part_fs.time < 10 && det.part_fs.time > 7)  //EXPLOSION IMMINENT
				light.set_color(1, 0.03, 0.03)
				light.enable()
				visible_message("<span style=\"color:red\">[src] flashes and sparks wildly!</span>")
				playsound(loc, "sound/machines/siren_generalquarters.ogg", 50, 1)
				playsound(loc, "sparks", 75, 1, -1)
				var/effects/system/spark_spread/s = unpool(/effects/system/spark_spread)
				s.set_up(3, 1, src)
				s.start()
			else if (det.part_fs.time <= 3)
				playsound(loc, "sound/machines/warning-buzzer.ogg", 50, 1)
		else //Someone might have defused it or the bomb failed
			light.disable()

	if (dialog_update_enabled) updateDialog()
	update_icon()
	return

/obj/machinery/portable_atmospherics/canister/return_air()
	return air_contents

/obj/machinery/portable_atmospherics/canister/blob_act(var/power)
	health -= power / 10
	healthcheck()
	return

/obj/machinery/portable_atmospherics/canister/proc/rupture() // cogwerks- high pressure tank explosions
	if (det)
		del(det) //Otherwise canister bombs detonate after rupture
	if (!destroyed)
		rupturing = 1
		spawn (10)
			visible_message("<span style=\"color:red\">[src] hisses ominously!</span>")
			playsound(loc, "sound/machines/hiss.ogg", 55, 1)
			sleep(50)
			playsound(loc, "sound/machines/hiss.ogg", 60, 1)
			sleep(50)
			visible_message("<span style=\"color:red\">[src] hisses loudly!</span>")
			playsound(loc, "sound/machines/hiss.ogg", 65, 1)
			sleep(50)
			visible_message("<span style=\"color:red\">[src] bulges!</span>")
			playsound(loc, "sound/machines/hiss.ogg", 65, 1)
			sleep(50)
			visible_message("<span style=\"color:red\">[src] cracks!</span>")
			playsound(loc, "sound/effects/bang.ogg", 65, 1)
			playsound(loc, "sound/machines/hiss.ogg", 65, 1)
			sleep(50)
			if (rupturing && !destroyed) // has anyone drained the tank?
				playsound(loc, "explosion", 70, 1)
				visible_message("<span style=\"color:red\">[src] ruptures violently!</span>")
				health = 0
				healthcheck()
				var/T = get_turf(src)

				for (var/obj/window/W in range(4, T)) // smash shit
					if (prob( get_dist(W,T)*6 ))
						continue
					W.health = 0
					W.smash()

				for (var/obj/displaycase/D in range(4,T))
					D.ex_act(1)

				for (var/obj/item/reagent_containers/glass/G in range(4,T))
					G.smash()

				for (var/obj/item/reagent_containers/food/drinks/drinkingglass/G in range(4,T))
					G.smash()

				for (var/atom/movable/A in view(3, T)) // wreck shit
					if (A.anchored) continue
					if (ismob(A))
						var/mob/M = A
						M.weakened += 8
						random_brute_damage(M, 20)
						var/atom/targetTurf = get_edge_target_turf(M, get_dir(src, get_step_away(M, src)))
						M.throw_at(targetTurf, 200, 4)
					else if (prob(50)) // cut down the number of things that get blown around
						var/atom/targetTurf = get_edge_target_turf(A, get_dir(src, get_step_away(A, src)))
						A.throw_at(targetTurf, 200, 4)

/obj/machinery/portable_atmospherics/canister/meteorhit(var/obj/O as obj)
	health = 0
	healthcheck()
	return

/obj/machinery/portable_atmospherics/canister/attackby(var/obj/item/W as obj, var/mob/user as mob)
	if (istype(W, /obj/item/assembly/detonator)) //Wire: canister bomb stuff
		if (holding)
			user.show_message("<span style=\"color:red\">You must remove the currently inserted tank from the slot first.</span>")
		else
			var/obj/item/assembly/detonator/Det = W
			if (Det.det_state != 4)
				user.show_message("<span style=\"color:red\">The assembly is incomplete.</span>")
			else
				Det.loc = src
				Det.master = src
				Det.layer = initial(W.layer)
				user.u_equip(Det)
				overlay_state = "overlay_safety_on"
				det = Det
				det.attachedTo = src
				det.builtBy = usr
				logTheThing("bombing", user, null, "builds a canister bomb [log_atmos(src)] at [log_loc(src)].")
				message_admins("[key_name(user)] builds a canister bomb at [log_loc(src)]. See bombing logs for atmos readout.")
	else if (det && istype(W, /obj/item/tank))
		user.show_message("<span style=\"color:red\">You cannot insert a tank, as the slot is shut closed by the detonator assembly.</span>")
	else if (det && (istype(W, /obj/item/wirecutters) || istype(W, /obj/item/device/multitool)))
		attack_hand(user)

	if (istype(W, /obj/item/cargotele))
		W:cargoteleport(src, user)
		return
	if (istype(W, /obj/item/atmosporter))
		var/canamt = W:contents.len
		if (canamt >= W:capacity) boutput(user, "<span style=\"color:red\">Your [W] is full!</span>")
		else
			user.visible_message("<span style=\"color:blue\">[user] collects the [src].</span>", "<span style=\"color:blue\">You collect the [src].</span>")
			contained = 1
			set_loc(W)
			var/effects/system/spark_spread/s = unpool(/effects/system/spark_spread)
			s.set_up(5, 1, user)
			s.start()
	if (!istype(W, /obj/item/wrench) && !istype(W, /obj/item/tank) && !istype(W, /obj/item/device/analyzer) && !istype(W, /obj/item/device/pda2))
		visible_message("<span style=\"color:red\">[user] hits the [src] with a [W]!</span>")
		logTheThing("combat", user, null, "attacked [src] [log_atmos(src)] with [W] at [log_loc(src)].")
		health -= W.force
		healthcheck()
	..()

/obj/machinery/portable_atmospherics/canister/attack_ai(var/mob/user as mob)
	if (!connected_port && get_dist(src, user) > 7)
		return
	return attack_hand(user)

/obj/machinery/portable_atmospherics/canister/attack_hand(var/mob/user as mob)
	if (destroyed)
		return

	user.machine = src
	var/holding_text = null
	var/safety_text = null
	var/det_text = null
	var/det_attachments_text = null
	var/timer_text = null
	var/trigger_text = null
	var/detonate_text = null
	var/valve_text = null
	var/pressure_text = null
	var/anchor_text = null
	var/wires_text = null
	//var/df_code_text //WIRE TODO: finish det codes
	var/note_text = null
	var/width = 600
	var/height = 300

	if (holding)
		holding_text = {"<strong>Tank Pressure</strong>: [holding.air_contents.return_pressure()] KPa<BR>
							<A href='?src=\ref[src];remove_tank=1'>Remove Tank</A>"}

	if (has_valve)
		valve_text = "Release Valve: <A href='?src=\ref[src];toggle=1'>[valve_open?("Open"):("Closed")]</A>"
		pressure_text = "Release Pressure: <A href='?src=\ref[src];pressure_adj=-100'>-</A> <A href='?src=\ref[src];pressure_adj=-10'>-</A> <A href='?src=\ref[src];setpressure=1'>[release_pressure]</A> <A href='?src=\ref[src];pressure_adj=10'>+</A> <A href='?src=\ref[src];pressure_adj=100'>+</A>"
	else
		valve_text = "Release Valve: The valve is missing. [valve_open?("The canister is leaking."):("The canister is not leaking")]</A>"
		pressure_text = "Without a release valve, the release pressure cannot be controlled."

	if (det) //Wire: canister bomb stuff
		width = 700
		height = 520
		var/i
		for (i = 1, i <= det.WireNames.len, i++)
			wires_text += "[det.WireNames[i]]: "
			if (det.WireStatus[i])
				wires_text += "<A href='?src=\ref[src];cut=[i]'>Cut</A> | <A href='?src=\ref[src];pulse=[i]'>Pulse</A>"
			else
				wires_text += "cut"
			wires_text += "<BR>"

		if (det.defused) //Detonator header
			det_text = {"<strong>A detonator is secured to the canister.</strong><BR><BR>
						Detonator wires:<BR>
						[wires_text]<BR><BR>
						The detonator has been defused. It cannot be detonated anymore."}
		else
			if (det.part_fs.timing) //Timer
				var/second = det.part_fs.time % 60
				var/minute = (det.part_fs.time - second) / 60
				minute = (minute < 10 ? "0[minute]" : "[minute]")
				second = (second < 10 ? "0[second]" : "[second]")
				if (det.part_fs.time < 10 && det.part_fs.time > 0)
					timer_text = "<div class='timer warning'>[minute]:[second]</div>"
				else if (det.part_fs.time < 0) //fuckin byond goes below zero sometimes due to lag/byond being byond
					timer_text = "<div class='timer warning'>[pick("OHGOD", "HELP!", "BZZAP", "OH:NO", "B-Y-E")]</div>"
				else
					timer_text = "<div class='timer counting'>[minute]:[second]</div>"
			else
				timer_text = "<div class='timer'>--:--</div>"
				timer_text += "<A href='?src=\ref[src];timer=1' class='setTime'>Set Timer</A>"

			safety_text = "<strong>Safety: </strong>"
			if (det.safety)
				safety_text += "<A href='?src=\ref[src];safety=1'>Turn Off</A> (Note: This cannot be undone)"
			else
				safety_text += "Off."

			anchor_text = "<strong>Anchor Status: </strong>"
			if (!anchored)
				anchor_text += "<A href='?src=\ref[src];anchor=1'>Anchor</a>"
			else
				anchor_text += "Anchored. There are no controls for undoing this."

			trigger_text = "<strong>Trigger: </strong>"
			if (det.trigger)
				trigger_text += "<A href='?src=\ref[src];trigger=1'>[det.trigger.name]</A>"
			else
				trigger_text += "There is no trigger attached."

			var/det_attachments_list
			for (var/obj/item/a in det.attachments)
				det_attachments_list += "There is \an [a] wired onto the assembly as an attachment.<br>"
				height += 33

			if (det_attachments_list)
				det_attachments_text += "<strong>Attachments: </strong><br>"
				det_attachments_text += det_attachments_list

			detonate_text = "<strong>Arming: </strong>"
			if (det.defused) //Detonator/priming
				detonate_text += "The detonator is defused. You cannot prime the bomb."
			else if (det.safety)
				detonate_text += "The safety is on, therefore, you cannot prime the bomb."
			else if (det.part_fs.timing)
				detonate_text += "<strong><font color=#FF0000>PRIMED</font></strong>"
			else
				detonate_text += "<A href='?src=\ref[src];detonate=1'>Prime</A>"

			/* WIRE TODO: finish det codes
			df_code_text = "<strong>Defusal Code: </strong>"
			if (det.dfcodeSet)
				df_code_text += "<A href='?src=\ref[src];defuseCode=1'>Set Code</A>"
			else
				df_code_text += "<A href='?src=\ref[src];defuseCode=1'>Enter Code</A>"
			*/

			note_text = ""
			if (det.note)
				note_text = "<div class='note'>[det.note]</div>"

			det_text = {"
							<style>
								.det {position: relative;}
								.det .timer {position: absolute; top: 30px; right: 30px; font-size: 2em; font-family: \"Courier New\", Courier, monospace; line-height: 1; background: #111; padding: 5px 10px; color: green;}
								.det .timer.counting {color: orange;}
								.det .timer.warning {color: red;}
								.det a {display: inline-block;}
								.det .note {position: absolute; top: 105px; right: 30px; font-size: 0.75em; max-width: 250px; width: 250px; font-family: \"Courier New\", Courier, monospace; border-bottom: 2px solid black; border-right: 2px solid black; padding: 3px; border-top: 1px solid #888840; border-left: 1px solid #888840; background: #FFFFA5; color: black;}
								.setTime {position: absolute; top: 80px; right: 35px; line-height: 1;}
							</style>
							<hr>
							<strong>A detonator is secured to the canister.</strong><BR><BR>
							Detonator wires:<br>
							[wires_text]<br>
							[anchor_text]<br>
							[trigger_text]<br>
							[safety_text]<br>
							[detonate_text]<br>
							[det_attachments_text]
							[timer_text]
							[note_text]
						"}

	var/output_text = {"<div id="canister">
							<div class="header">
								<strong>[name]</strong><BR>
								Pressure: [air_contents.return_pressure()] KPa<BR>
								Port Status: [(connected_port)?("Connected"):("Disconnected")]<BR>
								[valve_text]<BR>
								[pressure_text]<BR>
								[holding_text]
							</div>
							<div class="det">
								[det_text]
							</div>
							<hr>
							<A href='?action=mach_close&window=canister'>Close</A><BR>
						</div>"}

	user << browse(output_text, "window=canister;size=[width]x[height]")
	onclose(user, "canister")
	return

/obj/machinery/portable_atmospherics/canister/Topic(href, href_list)
	..()
	if (usr.stat || usr.restrained())
		return
	if (((get_dist(src, usr) <= 1) && istype(loc, /turf)))
		usr.machine = src

		if (href_list["toggle"])
			valve_open = !valve_open
			if (!holding && !connected_port)
				logTheThing("station", usr, null, "[valve_open ? "opened [src] into" : "closed [src] from"] the air [log_atmos(src)] at [log_loc(src)].")
				playsound(loc, "sound/machines/hiss.ogg", 50, 1)
				if (valve_open)
					message_admins("[key_name(usr)] opened [src] into the air at [log_loc(src)]. See station logs for atmos readout.")
					if (det)
						det.leaking()

		if (href_list["remove_tank"])
			if (holding)
				holding.set_loc(loc)
				holding = null
				if (valve_open && !connected_port)
					message_admins("[key_name(usr)] removed a tank from [src], opening it into the air at [log_loc(src)]. See station logs for atmos readout.")
					logTheThing("station", usr, null, "removed a tank from [src] [log_atmos(src)], opening it into the air at [log_loc(src)].")

		if (href_list["pressure_adj"])
			var/diff = text2num(href_list["pressure_adj"])
			if (diff > 0)
				release_pressure = min(10*ONE_ATMOSPHERE, release_pressure+diff)
			else
				release_pressure = max(ONE_ATMOSPHERE/10, release_pressure+diff)

		if (href_list["setpressure"])
			dialog_update_enabled = 0
			var/change = input(usr,"Target Pressure (10.1325-1013.25):","Enter target pressure",release_pressure) as num
			dialog_update_enabled = 1
			if (!isnum(change)) return
			release_pressure = min(max(10.1325, change),1013.25)
			updateUsrDialog()
			return

		//Wire: canister bomb stuff start
		if (href_list["anchor"])
			anchored = 1

		if (href_list["trigger"])
			det.trigger.attack_self(usr)

		if (href_list["timer"])
			det.part_fs.attack_self(usr)

		if (href_list["safety"])
			det.safety = 0
			overlay_state = "overlay_safety_off"

		if (href_list["cut"])
			if (!(istype(usr.equipped(), /obj/item/wirecutters)))
				usr.show_message("<span style=\"color:red\">You need to have wirecutters equipped for this.</span>")
			else
				if (det.shocked)
					var/mob/living/carbon/human/H = usr
					H.show_message("<span style=\"color:red\">You tried to cut a wire on the bomb, but got burned by it.</span>")
					H.TakeDamage("chest", 0, 30)
					if (H.stunned < 15)
						H.stunned = 15
					H.UpdateDamage()
					H.UpdateDamageIcon()
				else
					var/index = text2num(href_list["cut"])
					src.visible_message("<strong><font color=#B7410E>[usr.name] cuts the [src.det.WireNames[index]] on the detonator.</font></strong>")
					switch (det.WireFunctions[index])
						if ("detonate")
							playsound(loc, "sound/machines/whistlealert.ogg", 50, 1)
							playsound(loc, "sound/machines/whistlealert.ogg", 50, 1)
							visible_message("<strong><font color=#B7410E>The failsafe timer beeps three times before going quiet forever.</font></strong>")
							spawn (0)
								src.det.detonate()
						if ("defuse")
							playsound(loc, "sound/machines/ping.ogg", 50, 1)
							visible_message("<strong><font color=#32CD32>The detonator assembly emits a sighing, fading beep. The bomb has been disarmed.</font></strong>")
							det.defused = 1
						if ("safety")
							if (!det.safety)
								visible_message("<strong><font color=#B7410E>Nothing appears to happen.</font></strong>")
							else
								playsound(loc, "sound/machines/click.ogg", 50, 1)
								visible_message("<strong><font color=#B7410E>An unsettling click signals that the safety disengages.</font></strong>")
								det.safety = 0
							det.failsafe_engage()
						if ("losetime")
							det.failsafe_engage()
							playsound(loc, "sound/machines/twobeep.ogg", 50, 1)
							if (det.part_fs.time > 7)
								det.part_fs.time -= 7
							else
								det.part_fs.time = 2
							visible_message("<strong><font color=#B7410E>The failsafe beeps rapidly for two moments. The external display indicates that the timer has reduced to [det.part_fs.time] seconds.</font></strong>")
						if ("mobility")
							det.failsafe_engage()
							playsound(loc, "sound/machines/click.ogg", 50, 1)
							if (anchored)
								visible_message("<strong><font color=#B7410E>A faint click is heard from inside the canister, but the effect is not immediately apparent.</font></strong>")
							else
								anchored = 1
								visible_message("<strong><font color=#B7410E>A loud click is heard from the bottom of the canister, securing itself.</font></strong>")
						if ("leak")
							det.failsafe_engage()
							has_valve = 0
							valve_open = 1
							release_pressure = 10 * ONE_ATMOSPHERE
							visible_message("<strong><font color=#B7410E>An electric buzz is heard before the release valve flies off the canister.</font></strong>")
							playsound(loc, "sound/machines/hiss.ogg", 50, 1)
							det.leaking()
						else
							det.failsafe_engage()
							if (det.part_fs.timing)
								var/obj/item/attachment = det.WireFunctions[index]
								attachment.detonator_act("cut", det)

					det.WireStatus[index] = 0

		if (href_list["pulse"])
			if (!(istype(usr.equipped(), /obj/item/device/multitool)))
				usr.show_message("<span style=\"color:red\">You need to have a multitool equipped for this.</span>")
			else
				if (det.shocked)
					var/mob/living/carbon/human/H = usr
					H.show_message("<span style=\"color:red\">You tried to pulse a wire on the bomb, but got burned by it.</span>")
					H.TakeDamage("chest", 0, 30)
					if (H.stunned < 15)
						H.stunned = 15
					H.UpdateDamage()
					H.UpdateDamageIcon()
				else
					var/index = text2num(href_list["pulse"])
					src.visible_message("<strong><font color=#B7410E>[usr.name] pulses the [src.det.WireNames[index]] on the detonator.</font></strong>")
					switch (det.WireFunctions[index])
						if ("detonate")
							if (det.part_fs.timing)
								playsound(loc, "sound/machines/buzz-sigh.ogg", 50, 1)
								if (det.part_fs.time > 7)
									det.part_fs.time = 7
									visible_message("<strong><font color=#B7410E>The failsafe timer buzzes loudly and sets itself to 7 seconds.</font></strong>")
								else
									visible_message("<strong><font color=#B7410E>The failsafe timer buzzes refusingly before going quiet forever.</font></strong>")
									spawn (0)
										src.det.detonate()
							else
								det.failsafe_engage()
								det.part_fs.time = rand(8,14)
								playsound(loc, "sound/machines/pod_alarm.ogg", 50, 1)
								visible_message("<strong><font color=#B7410E>The failsafe timer buzzes loudly and activates. You have [det.part_fs.time] seconds to act.</font></strong>")
						if ("defuse")
							det.failsafe_engage()
							if (det.grant)
								det.part_fs.time += 5
								playsound(loc, "sound/machines/ping.ogg", 50, 1)
								src.visible_message("<strong><font color=#B7410E>The detonator assembly emits a reassuring noise. You notice that the failsafe timer has increased to [src.det.part_fs.time] seconds.</font></strong>")
								det.grant = 0
							else
								playsound(loc, "sound/machines/buzz-two.ogg", 50, 1)
								visible_message("<strong><font color=#B7410E>The detonator assembly emits a sinister noise, but there are no apparent changes visible externally.</font></strong>")
						if ("safety")
							playsound(loc, "sound/machines/twobeep.ogg", 50, 1)
							if (!det.safety)
								visible_message("<strong><font color=#B7410E>The multitool display flashes with no apparent outside effect.</font></strong>")
							else
								visible_message("<strong><font color=#B7410E>An unsettling click signals that the safety disengages.</font></strong>")
								det.safety = 0
						if ("losetime")
							det.failsafe_engage()
							det.shocked = 1
							var/losttime = rand(2,5)
							visible_message("<strong><font color=#B7410E>The bomb buzzes oddly, emitting electric sparks. It would be a bad idea to touch any wires for the next [losttime] seconds.</font></strong>")
							playsound(loc, "sparks", 75, 1, -1)
							var/effects/system/spark_spread/s = unpool(/effects/system/spark_spread)
							s.set_up(3, 1, src)
							s.start()
							spawn (10 * losttime)
								det.shocked = 0
								visible_message("<strong><font color=#B7410E>The buzzing stops, and the countdown continues.</font></strong>")
						if ("mobility")
							det.failsafe_engage()
							playsound(loc, "sound/machines/click.ogg", 50, 1)
							if (anchored)
								anchored = 0
								visible_message("<strong><font color=#B7410E>A loud click is heard from the inside the canister, unsecuring itself.</font></strong>")
							else
								anchored = 1
								visible_message("<strong><font color=#B7410E>A loud click is heard from the bottom of the canister, securing itself.</font></strong>")
						if ("leak")
							det.failsafe_engage()
							playsound(loc, "sound/machines/hiss.ogg", 50, 1)
							if (prob(min(det.leaks * 8, 100)))
								has_valve = 0
								valve_open = 1
								release_pressure = 10 * ONE_ATMOSPHERE
								visible_message("<strong><font color=#B7410E>An electric buzz is heard before the release valve flies off the canister.</font></strong>")
							else
								valve_open = 1
								release_pressure = min(10, det.leaks + 1) * ONE_ATMOSPHERE
								visible_message("<strong><font color=#B7410E>The release valve rumbles a bit, leaking some of the gas into the air.</font></strong>")
							det.leaking()
							det.leaks++
						else
							det.failsafe_engage()
							if (det.part_fs.timing)
								var/obj/item/attachment = det.WireFunctions[index]
								attachment.detonator_act("pulse", det)

		if (href_list["detonate"])
			spawn (0)
				det.failsafe_engage()

		/* WIRE TODO: finish det codes
		if (href_list["defuseCode"])
			if (det.dfcodeSet) //code already programmed in
				var/code = copytext(input(usr, "[det.dfcodeTries] attempts left", "Enter defusal code (4 digits)") as num, 1, 4)
				if (length(code) != 4) return ..()
				if (code == det.dfcode) //defused!
					playsound(loc, "sound/machines/ping.ogg", 50, 1)
					visible_message("<strong><font color=#32CD32>The detonator assembly emits a sighing, fading beep. The bomb has been disarmed.</font></strong>")
					det.defused = 1
				else
					if (det.dfcodeTries >= 1) //still more tries left
						playsound(loc, "sound/machines/buzz-two.ogg", 50, 1)
						src.visible_message("<strong><font color=#B7410E>The detonator bloops an annoyed tone. Wrong code! \[[src.det.dfcodeTries] attempts remaining\]</font></strong>")
						det.dfcodeTries = det.dfcodeTries - 1
					else //uh oh! kaboom!
						playsound(loc, "sound/machines/whistlealert.ogg", 50, 1)
						visible_message("<strong><font color=red>The detonator rumbles menacingly. The timer changes to 3 seconds remaining. Oh dear.</font></strong>")
						det.part_fs.time = 3
			else //still gotta set dat code yo
				var/code = copytext(input(usr, "[det.dfcodeTries] attempts left", "Enter defusal code (4 digits)") as num, 1, 4)
				boutput(world, "[length(code)]")
		*/

		//Wire: canister bomb stuff end

		updateUsrDialog()
		add_fingerprint(usr)
		update_icon()
	else
		usr << browse(null, "window=canister")
		return
	return

/obj/machinery/portable_atmospherics/canister/bullet_act(var/obj/projectile/P)
	var/damage = 0
	damage = round((P.power*P.proj_data.ks_ratio), 1.0)

	if (det)
		src.det.detonate()
		return
	if (material) material.triggerOnAttacked(src, P.shooter, src, (ismob(P.shooter) ? P.shooter:equipped() : P.shooter))
	for (var/atom/A in src)
		if (A.material)
			A.material.triggerOnAttacked(A, P.shooter, src, (ismob(P.shooter) ? P.shooter:equipped() : P.shooter))

	if (P.proj_data.damage_type == D_KINETIC)
		health -= damage
	else if (P.proj_data.damage_type == D_PIERCING)
		health -= (damage * 2)
	else if (P.proj_data.damage_type == D_ENERGY)
		health -= damage
	log_shot(P,src)
	spawn ( 0 )
		healthcheck()
		return
	return

/obj/machinery/portable_atmospherics/canister/toxins/New()

	..()

	src.air_contents.toxins = (src.maximum_pressure*filled)*air_contents.volume/(R_IDEAL_GAS_EQUATION*air_contents.temperature)

	update_icon()
	return TRUE

/obj/machinery/portable_atmospherics/canister/oxygen/New()

	..()

	src.air_contents.oxygen = (src.maximum_pressure*filled)*air_contents.volume/(R_IDEAL_GAS_EQUATION*air_contents.temperature)

	update_icon()
	return TRUE

/obj/machinery/portable_atmospherics/canister/sleeping_agent/New()

	..()

	var/gas/sleeping_agent/trace_gas = new
	if (!air_contents.trace_gases)
		air_contents.trace_gases = list()
	air_contents.trace_gases += trace_gas
	trace_gas.moles = (maximum_pressure*filled)*air_contents.volume/(R_IDEAL_GAS_EQUATION*air_contents.temperature)

	update_icon()
	return TRUE

/obj/machinery/portable_atmospherics/canister/nitrogen/New()

	..()

	air_contents.temperature = 80
	src.air_contents.nitrogen = (src.maximum_pressure*filled)*air_contents.volume/(R_IDEAL_GAS_EQUATION*air_contents.temperature)

	update_icon()
	return TRUE

/obj/machinery/portable_atmospherics/canister/carbon_dioxide/New()

	..()
	src.air_contents.carbon_dioxide = (src.maximum_pressure*filled)*air_contents.volume/(R_IDEAL_GAS_EQUATION*air_contents.temperature)

	update_icon()
	return TRUE


/obj/machinery/portable_atmospherics/canister/air/New()

	..()
	src.air_contents.oxygen = (O2STANDARD*src.maximum_pressure*filled)*air_contents.volume/(R_IDEAL_GAS_EQUATION*air_contents.temperature)
	src.air_contents.nitrogen = (N2STANDARD*src.maximum_pressure*filled)*air_contents.volume/(R_IDEAL_GAS_EQUATION*air_contents.temperature)

	update_icon()
	return TRUE

