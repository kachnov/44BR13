/obj/machinery/meter
	name = "meter"
	icon = 'icons/obj/meter.dmi'
	icon_state = "meterX"
	var/obj/machinery/atmospherics/pipe/target = null
	anchored = 1.0
	var/frequency = 0
	var/id
	var/noiselimiter = 0

/obj/machinery/meter/New()
	..()
	spawn (10)
		target = locate(/obj/machinery/atmospherics/pipe) in loc

	return TRUE

/obj/machinery/meter/process()
	if (!target)
		icon_state = "meterX"
		return FALSE

	if (stat & (BROKEN|NOPOWER))
		icon_state = "meter0"
		return FALSE

	use_power(5)

	var/gas_mixture/environment = target.return_air()
	if (!environment)
		icon_state = "meterX"
		return FALSE

	var/env_pressure = environment.return_pressure()
	if (env_pressure <= 0.15*ONE_ATMOSPHERE)
		icon_state = "meter0"
	else if (env_pressure <= 1.8*ONE_ATMOSPHERE)
		var/val = round(env_pressure/(ONE_ATMOSPHERE*0.3) + 0.5)
		icon_state = "meter1_[val]"
	else if (env_pressure <= 30*ONE_ATMOSPHERE)
		var/val = round(env_pressure/(ONE_ATMOSPHERE*5)-0.35) + 1
		icon_state = "meter2_[val]"
	else if (env_pressure <= 59*ONE_ATMOSPHERE)
		var/val = round(env_pressure/(ONE_ATMOSPHERE*5) - 6) + 1
		icon_state = "meter3_[val]"
	else
		icon_state = "meter4"
		if (!noiselimiter)
			if (prob(50))
				playsound(loc, "sound/machines/hiss.ogg", 50, 1)
				noiselimiter = 1
				spawn (60)
				noiselimiter = 0


	if (frequency)
		var/radio_frequency/radio_connection = radio_controller.return_frequency("[frequency]")

		if (!radio_connection) return

		var/signal/signal = get_free_signal()
		signal.source = src
		signal.transmission_method = 1

		signal.data["tag"] = id
		signal.data["device"] = "AM"
		signal.data["pressure"] = round(env_pressure)

		radio_connection.post_signal(src, signal)

/obj/machinery/meter/examine()
	set src in oview(1)
	set category = "Local"

	var/t = "A gas flow meter. "
	if (target)
		var/gas_mixture/environment = target.return_air()
		if (environment)
			t += text("The pressure gauge reads [] kPa", round(environment.return_pressure(), 0.1))
		else
			t += "The sensor error light is blinking."
	else
		t += "The connect error light is blinking."

	boutput(usr, t)



/obj/machinery/meter/Click()

	if (stat & (NOPOWER|BROKEN))
		return

	var/t = null
	if (get_dist(usr, src) <= 3 || istype(usr, /mob/living/silicon/ai))
		if (target)
			var/gas_mixture/environment = target.return_air()
			if (environment)
				t = text("<strong>Pressure:</strong> [] kPa", round(environment.return_pressure(), 0.1))
			else
				t = "<span style=\"color:red\"><strong>Results: Sensor Error!</strong></span>"
		else
			t = "<span style=\"color:red\"><strong>Results: Connection Error!</strong></span>"
	else
		boutput(usr, "<span style=\"color:blue\"><strong>You are too far away.</strong></span>")

	boutput(usr, t)
	return
