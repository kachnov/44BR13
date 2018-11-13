/obj/machinery/computer/general_air_control
	icon = 'icons/obj/computer.dmi'
	icon_state = "computer_generic"

	name = "Computer"

	var/frequency = 1439
	var/list/sensors = list()

	var/list/sensor_information = list()
	var/radio_frequency/radio_connection

	attack_hand(mob/user)
		user << browse(return_text(),"window=computer")
		user.machine = src
		onclose(user, "computer")

	process()
		..()

		updateDialog()

	attackby(I as obj, user as mob)
		if (istype(I, /obj/item/screwdriver))
			playsound(loc, "sound/items/Screwdriver.ogg", 50, 1)
			if (do_after(user, 20))
				if (stat & BROKEN)
					boutput(user, "<span style=\"color:blue\">The broken glass falls out.</span>")
					var/obj/computerframe/A = new /obj/computerframe( loc )
					if (material) A.setMaterial(material)
					new /obj/item/raw_material/shard/glass( loc )
					var/obj/item/circuitboard/air_management/M = new /obj/item/circuitboard/air_management( A )
					for (var/obj/C in src)
						C.set_loc(loc)
					M.frequency = frequency
					A.circuit = M
					A.state = 3
					A.icon_state = "3"
					A.anchored = 1
					qdel(src)
				else
					boutput(user, "<span style=\"color:blue\">You disconnect the monitor.</span>")
					var/obj/computerframe/A = new /obj/computerframe( loc )
					if (material) A.setMaterial(material)
					var/obj/item/circuitboard/air_management/M = new /obj/item/circuitboard/air_management( A )
					for (var/obj/C in src)
						C.set_loc(loc)
					M.frequency = frequency
					A.circuit = M
					A.state = 4
					A.icon_state = "4"
					A.anchored = 1
					qdel(src)
		else
			attack_hand(user)
		return

	receive_signal(signal/signal)
		if (!signal || signal.encryption) return

		var/id_tag = signal.data["tag"]
		if (!id_tag || !sensors.Find(id_tag)) return

		sensor_information[id_tag] = signal.data

	proc/return_text()
		var/sensor_data
		if (sensors.len)
			for (var/id_tag in sensors)
				var/long_name = sensors[id_tag]
				var/list/data = sensor_information[id_tag]
				var/sensor_part = "<strong>[long_name]</strong>: "

				if (data)
					if (data["pressure"])
						sensor_part += "[data["pressure"]] kPa"
						if (data["temperature"])
							sensor_part += ", [data["temperature"]] K"
						sensor_part += "<BR>"
					else if (data["temperature"])
						sensor_part += "[data["temperature"]] K<BR>"

					if (data["oxygen"]||data["toxins"])
						sensor_part += "<strong>[long_name] Composition</strong>: <BR>"
						if (data["oxygen"])
							sensor_part += "[data["oxygen"]] %O2<BR>"
						if (data["toxins"])
							sensor_part += "[data["toxins"]] %TX<BR>"
						if (data["carbon_dioxide"])
							sensor_part += "[data["carbon_dioxide"]] %CO2<BR>"
						if (data["nitrogen"])
							sensor_part += "[data["nitrogen"]] %N2<BR>"
						if (data["other"])
							sensor_part += "[data["other"]] %OTHER<BR>"


				else
					sensor_part = "<FONT color='red'>[long_name] can not be found!</FONT><BR>"

				sensor_data += sensor_part

		else
			sensor_data = "No sensors connected."

		var/output = {"<strong>[name]</strong><HR>
<strong>Sensor Data: <BR></strong>
[sensor_data]<HR>"}

		return output

	proc
		set_frequency(new_frequency)
			radio_controller.remove_object(src, "[frequency]")
			frequency = new_frequency
			radio_connection = radio_controller.add_object(src, "[frequency]")

	initialize()
		set_frequency(frequency)

	large_tank_control
		icon = 'icons/obj/computer.dmi'
		icon_state = "tank"
		req_access = list(access_engineering_atmos)
		req_access_txt = "46"

		var/input_tag
		var/output_tag

		var/list/input_info
		var/list/output_info

		var/pressure_setting = ONE_ATMOSPHERE * 45

		return_text()
			var/output = ..()

			output += "<strong>Tank Control System</strong><BR>"
			if (input_info)
				var/power = (input_info["power"] == "on")
				var/volume_rate = input_info["volume_rate"]
				output += {"<strong>Input</strong>: [power?("Injecting"):("On Hold")] <A href='?src=\ref[src];in_refresh_status=1'>Refresh</A><BR>
Rate: [volume_rate] L/sec<BR>"}
				output += "Command: <A href='?src=\ref[src];in_toggle_injector=1'>Toggle Power</A><BR>"

			else
				output += "<FONT color='red'>ERROR: Can not find input port</FONT> <A href='?src=\ref[src];in_refresh_status=1'>Search</A><BR>"

			output += "<BR>"

			if (output_info)
				var/power = (output_info["power"] == "on")
				var/output_pressure = output_info["internal"]
				output += {"<strong>Output</strong>: [power?("Open"):("On Hold")] <A href='?src=\ref[src];out_refresh_status=1'>Refresh</A><BR>
Max Output Pressure: [output_pressure] kPa<BR>"}
				output += "Command: <A href='?src=\ref[src];out_toggle_power=1'>Toggle Power</A> <A href='?src=\ref[src];out_set_pressure=1'>Set Pressure</A><BR>"

			else
				output += "<FONT color='red'>ERROR: Can not find output port</FONT> <A href='?src=\ref[src];out_refresh_status=1'>Search</A><BR>"

			output += "Max Output Pressure Set: <A href='?src=\ref[src];adj_pressure=-100'>-</A> <A href='?src=\ref[src];adj_pressure=-1'>-</A> [pressure_setting] kPa <A href='?src=\ref[src];adj_pressure=1'>+</A> <A href='?src=\ref[src];adj_pressure=100'>+</A><BR>"

			return output

		receive_signal(signal/signal)
			if (!signal || signal.encryption) return

			var/id_tag = signal.data["tag"]

			if (input_tag == id_tag)
				input_info = signal.data
			else if (output_tag == id_tag)
				output_info = signal.data
			else
				..(signal)

		Topic(href, href_list)
			if (..())
				return

			if (!allowed(usr))
				boutput(usr, "<span style=\"color:red\">Access Denied!</span>")
				return

			if (href_list["in_refresh_status"])
				input_info = null
				if (!radio_connection)
					return FALSE

				var/signal/signal = get_free_signal()
				signal.transmission_method = 1 //radio signal
				signal.source = src

				signal.data["tag"] = input_tag
				signal.data["status"] = 1
				signal.data["command"] = "refresh"

				radio_connection.post_signal(src, signal)

			if (href_list["in_toggle_injector"])
				input_info = null
				if (!radio_connection)
					return FALSE

				var/signal/signal = get_free_signal()
				signal.transmission_method = 1 //radio signal
				signal.source = src

				signal.data["tag"] = input_tag
				signal.data["command"] = "power_toggle"

				radio_connection.post_signal(src, signal)

			if (href_list["out_refresh_status"])
				output_info = null
				if (!radio_connection)
					return FALSE

				var/signal/signal = get_free_signal()
				signal.transmission_method = 1 //radio signal
				signal.source = src

				signal.data["tag"] = output_tag
				signal.data["status"] = 1
				signal.data["command"] = "refresh"

				radio_connection.post_signal(src, signal)

			if (href_list["out_toggle_power"])
				output_info = null
				if (!radio_connection)
					return FALSE

				var/signal/signal = get_free_signal()
				signal.transmission_method = 1 //radio signal
				signal.source = src

				signal.data["tag"] = output_tag
				signal.data["command"] = "power_toggle"

				radio_connection.post_signal(src, signal)

			if (href_list["out_set_pressure"])
				output_info = null
				if (!radio_connection)
					return FALSE

				var/signal/signal = get_free_signal()
				signal.transmission_method = 1 //radio signal
				signal.source = src

				signal.data["tag"] = output_tag
				signal.data["command"] = "set_internal_pressure"
				signal.data["parameter"] = "[pressure_setting]"

				radio_connection.post_signal(src, signal)

			if (href_list["adj_pressure"])
				var/change = text2num(href_list["adj_pressure"])
				pressure_setting = min(max(0, pressure_setting + change), 50*ONE_ATMOSPHERE)

			spawn (7)
				attack_hand(usr)

	fuel_injection
		icon = 'icons/obj/computer.dmi'
		icon_state = "atmos"


		var/device_tag
		var/list/device_info

		var/automation = 0

		var/cutoff_temperature = 2000
		var/on_temperature = 1200

		attackby(I as obj, user as mob)
			if (istype(I, /obj/item/screwdriver))
				playsound(loc, "sound/items/Screwdriver.ogg", 50, 1)
				if (do_after(user, 20))
					if (stat & BROKEN)
						boutput(user, "<span style=\"color:blue\">The broken glass falls out.</span>")
						var/obj/computerframe/A = new /obj/computerframe( loc )
						if (material) A.setMaterial(material)
						new /obj/item/raw_material/shard/glass( loc )
						var/obj/item/circuitboard/injector_control/M = new /obj/item/circuitboard/injector_control( A )
						for (var/obj/C in src)
							C.set_loc(loc)
						M.frequency = frequency
						A.circuit = M
						A.state = 3
						A.icon_state = "3"
						A.anchored = 1
						qdel(src)
					else
						boutput(user, "<span style=\"color:blue\">You disconnect the monitor.</span>")
						var/obj/computerframe/A = new /obj/computerframe( loc )
						if (material) A.setMaterial(material)
						var/obj/item/circuitboard/injector_control/M = new /obj/item/circuitboard/injector_control( A )
						for (var/obj/C in src)
							C.set_loc(loc)
						M.frequency = frequency
						A.circuit = M
						A.state = 4
						A.icon_state = "4"
						A.anchored = 1
						qdel(src)
			else
				attack_hand(user)
			return

		process()
			if (automation)
				if (!radio_connection)
					return FALSE

				var/injecting = 0
				for (var/id_tag in sensor_information)
					var/list/data = sensor_information[id_tag]
					if (data["temperature"])
						if (data["temperature"] >= cutoff_temperature)
							injecting = 0
							break
						if (data["temperature"] <= on_temperature)
							injecting = 1

				var/signal/signal = get_free_signal()
				signal.transmission_method = 1 //radio signal
				signal.source = src

				signal.data["tag"] = device_tag

				if (injecting)
					signal.data["command"] = "power_on"
				else
					signal.data["command"] = "power_off"

				radio_connection.post_signal(src, signal)

			..()

		return_text()
			var/output = ..()

			output += "<strong>Fuel Injection System</strong><BR>"
			if (device_info)
				var/power = device_info["power"]
				var/volume_rate = device_info["volume_rate"]
				output += {"Status: [power?("Injecting"):("On Hold")] <A href='?src=\ref[src];refresh_status=1'>Refresh</A><BR>
Rate: <A href='?src=\ref[src];change_vol=-10'>--</A> <A href='?src=\ref[src];change_vol=-1'>-</A> [volume_rate] L/sec <A href='?src=\ref[src];change_vol=1'>+</A> <A href='?src=\ref[src];change_vol=10'>++</A><BR>"}

				if (automation)
					output += "Automated Fuel Injection: <A href='?src=\ref[src];toggle_automation=1'>Engaged</A><BR>"
					output += "Injector Controls Locked Out<BR>"
				else
					output += "Automated Fuel Injection: <A href='?src=\ref[src];toggle_automation=1'>Disengaged</A><BR>"
					output += "Injector: <A href='?src=\ref[src];toggle_injector=1'>Toggle Power</A> <A href='?src=\ref[src];injection=1'>Inject (1 Cycle)</A><BR>"

			else
				output += "<FONT color='red'>ERROR: Can not find device</FONT> <A href='?src=\ref[src];refresh_status=1'>Search</A><BR>"

			return output

		receive_signal(signal/signal)
			if (!signal || signal.encryption) return

			var/id_tag = signal.data["tag"]

			if (device_tag == id_tag)
				device_info = signal.data
			else
				..(signal)

		Topic(href, href_list)
			if (..())
				return

			if (href_list["refresh_status"])
				device_info = null
				if (!radio_connection)
					return FALSE

				var/signal/signal = get_free_signal()
				signal.transmission_method = 1 //radio signal
				signal.source = src

				signal.data["tag"] = device_tag
				signal.data["status"] = 1
				signal.data["command"] = "refresh"

				radio_connection.post_signal(src, signal)

			if (href_list["toggle_automation"])
				automation = !automation

			if (href_list["toggle_injector"])
				device_info = null
				if (!radio_connection)
					return FALSE

				var/signal/signal = get_free_signal()
				signal.transmission_method = 1 //radio signal
				signal.source = src

				signal.data["tag"] = device_tag
				signal.data["command"] = "power_toggle"

				radio_connection.post_signal(src, signal)

			if (href_list["injection"])
				if (!radio_connection)
					return FALSE

				var/signal/signal = get_free_signal()
				signal.transmission_method = 1 //radio signal
				signal.source = src

				signal.data["tag"] = device_tag
				signal.data["command"] = "inject"

				radio_connection.post_signal(src, signal)

			if (href_list["change_vol"])
				if (!radio_connection)
					return FALSE
				var/amount = text2num(href_list["change_vol"])
				var/signal/signal = get_free_signal()
				var/volume_rate = device_info["volume_rate"]
				signal.transmission_method = 1 //radio
				signal.source = src
				signal.data["tag"] = device_tag
				signal.data["command"] = "set_volume_rate"
				signal.data["parameter"] = num2text(volume_rate + amount)
				radio_connection.post_signal(src, signal)

/obj/machinery/computer/general_alert
	var/radio_frequency/radio_connection

	initialize()
		set_frequency(receive_frequency)
		radio_controller.add_object(src, "[respond_frequency]")

	receive_signal(signal/signal)
		if (!signal || signal.encryption) return

		//Oh, someone is asking us for data instead of reporting a thing.
		if ((signal.data["command"] == "report_alerts") && signal.data["sender"])
			var/radio_frequency/frequency = radio_controller.return_frequency("[respond_frequency]")
			var/signal/newsignal = get_free_signal()
			newsignal.transmission_method = TRANSMISSION_RADIO

			newsignal.data["address_1"] = signal.data["sender"]
			newsignal.data["command"] = "reply_alerts"
			if (priority_alarms.len)
				newsignal.data["severe_list"] = jointext(priority_alarms, ";")
			if (minor_alarms.len)
				newsignal.data["minor_list"] = jointext(minor_alarms, ";")

			frequency.post_signal(src, newsignal)
			return


		var/zone = signal.data["zone"]
		var/severity = signal.data["alert"]

		if (!zone || !severity) return

		if (severity=="severe")
			priority_alarms -= zone
			priority_alarms += zone
		else
			minor_alarms -= zone
			minor_alarms += zone

	proc
		set_frequency(new_frequency)
			radio_controller.remove_object(src, "[receive_frequency]")
			receive_frequency = new_frequency
			radio_connection = radio_controller.add_object(src, "[receive_frequency]")


	attack_hand(mob/user)
		user << browse(return_text(),"window=computer")
		user.machine = src
		onclose(user, "computer")

	process()
		if (priority_alarms.len)
			icon_state = "alert:2"

		else if (minor_alarms.len)
			icon_state = "alert:1"

		else
			icon_state = "alert:0"

		..()

		updateDialog()

	proc/return_text()
		var/priority_text
		var/minor_text

		if (priority_alarms.len)
			for (var/zone in priority_alarms)
				priority_text += "<FONT color='red'><strong>[zone]</strong></FONT>  <A href='?src=\ref[src];priority_clear=[ckey(zone)]'>X</A><BR>"
		else
			priority_text = "No priority alerts detected.<BR>"

		if (minor_alarms.len)
			for (var/zone in minor_alarms)
				minor_text += "<strong>[zone]</strong>  <A href='?src=\ref[src];minor_clear=[ckey(zone)]'>X</A><BR>"
		else
			minor_text = "No minor alerts detected.<BR>"

		var/output = {"<strong>[name]</strong><HR>
<strong>Priority Alerts:</strong><BR>
[priority_text]
<BR>
<HR>
<strong>Minor Alerts:</strong><BR>
[minor_text]
<BR>"}

		return output

	Topic(href, href_list)
		if (..())
			return

		if (href_list["priority_clear"])
			var/removing_zone = href_list["priority_clear"]
			for (var/zone in priority_alarms)
				if (ckey(zone) == removing_zone)
					priority_alarms -= zone

		if (href_list["minor_clear"])
			var/removing_zone = href_list["minor_clear"]
			for (var/zone in minor_alarms)
				if (ckey(zone) == removing_zone)
					minor_alarms -= zone


#define MAX_PRESSURE 20 * ONE_ATMOSPHERE
/obj/machinery/computer/atmosphere/mixercontrol
	var/obj/machinery/atmospherics/mixer/mixerid
	var/mixer_information
	var/id
	req_access = list(access_engineering_engine, access_tox)
	req_only_one_required = 1

	var/last_change = 0
	var/message_delay = 600

	var/frequency = 1439
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
		updateDialog()

	attackby(I as obj, user as mob)
		if (istype(I, /obj/item/screwdriver))
			playsound(loc, "sound/items/Screwdriver.ogg", 50, 1)
			if (do_after(user, 20))
				if (stat & BROKEN)
					boutput(user, "<span style=\"color:blue\">The broken glass falls out.</span>")
					var/obj/computerframe/A = new /obj/computerframe( loc )
					if (material) A.setMaterial(material)
					new /obj/item/raw_material/shard/glass( loc )
					var/obj/item/circuitboard/air_management/M = new /obj/item/circuitboard/air_management( A )
					for (var/obj/C in src)
						C.set_loc(loc)
					M.frequency = frequency
					A.circuit = M
					A.state = 3
					A.icon_state = "3"
					A.anchored = 1
					qdel(src)
				else
					boutput(user, "<span style=\"color:blue\">You disconnect the monitor.</span>")
					var/obj/computerframe/A = new /obj/computerframe( loc )
					if (material) A.setMaterial(material)
					var/obj/item/circuitboard/air_management/M = new /obj/item/circuitboard/air_management( A )
					for (var/obj/C in src)
						C.set_loc(loc)
					M.frequency = frequency
					A.circuit = M
					A.state = 4
					A.icon_state = "4"
					A.anchored = 1
					qdel(src)
		else
			attack_hand(user)
		return

	receive_signal(signal/signal)
		//boutput(world, "[id] actually can recieve a signal!")
		if (!signal || signal.encryption) return

		var/id_tag = signal.data["tag"]
		if (!id_tag || mixerid != id_tag) return

		//boutput(world, "[id] recieved a signal from [id_tag]!")
		mixer_information = signal.data

	proc/return_text()
		var/mixer_data
		if (mixerid)
			var/long_name = mixerid
			var/list/data = mixer_information
			var/mixer_part = ""

			if (data)
				mixer_part += "<strong>Input 1 Composition</strong>: <BR>"
				if (data["input1o2"])
					mixer_part += "<FONT color='blue'>[data["input1o2"]]% O2</FONT>  "
				if (data["input1p"])
					mixer_part += "<FONT color='red'>[data["input1p"]]% PL</FONT>  "
				if (data["input1co2"])
					mixer_part += "<FONT color='orange'>[data["input1co2"]]% CO2</FONT>  "
				if (data["input1n2"])
					mixer_part += "<FONT color='gray'>[data["input1n2"]]% N2</FONT>  "
				if (data["input1tg"])
					mixer_part += "<FONT color='black'>[data["input1tg"]]% OTHER</FONT>   "
				if (data["input1kpa"] && data["input1temp"])
					mixer_part += "<br>Pressure: [data["input1kpa"]] kPa / Temperature: [data["input1temp"]] &deg;C"
				mixer_part += "<BR>"

				mixer_part += "<strong>Input 2 Composition</strong>: <BR>"
				if (data["input2o2"])
					mixer_part += "<FONT color='blue'>[data["input2o2"]]% O2</FONT>  "
				if (data["input2p"])
					mixer_part += "<FONT color='red'>[data["input2p"]]% PL</FONT>  "
				if (data["input2co2"])
					mixer_part += "<FONT color='orange'>[data["input2co2"]]% CO2</FONT>  "
				if (data["input2n2"])
					mixer_part += "<FONT color='gray'>[data["input2n2"]]% N2</FONT>  "
				if (data["input2tg"])
					mixer_part += "<FONT color='black'>[data["input2tg"]]% OTHER</FONT>   "
				if (data["input2kpa"] && data["input2temp"])
					mixer_part += "<br>Pressure: [data["input2kpa"]] kPa / Temperature: [data["input2temp"]] &deg;C"

				mixer_part += "<hr>"

				mixer_part += "<strong>Output Target Pressure</strong>: <A href='?src=\ref[src];pressure_adj=-100'>-</A> <A href='?src=\ref[src];pressure_adj=-10'>-</A> <A href='?src=\ref[src];pressure_set=1'>[data["target_pressure"]] kPa</A> <A href='?src=\ref[src];pressure_adj=10'>+</A> <A href='?src=\ref[src];pressure_adj=100'>+</A><BR>"
				mixer_part += "<strong>Pump Status</strong>: <A href='?src=\ref[src];toggle_pump=1'>[data["pump_status"]]</A><BR>"
				mixer_part += "<strong>Gas Input Ratio</strong>: <A href='?src=\ref[src];ratio=5'><<</A> <A href='?src=\ref[src];ratio=1'><</A> [data["i1trans"]]% /  [data["i2trans"]]% <A href='?src=\ref[src];ratio=-1'>></A> <A href='?src=\ref[src];ratio=-5'>>></A>"

				mixer_part += "<HR><strong>Resulting Composition</strong>: <BR>"
				if (data["outputo2"])
					mixer_part += "<FONT color='blue'>[data["outputo2"]]% O2</FONT>  "
				if (data["outputp"])
					mixer_part += "<FONT color='red'>[data["outputp"]]% PL</FONT>  "
				if (data["outputco2"])
					mixer_part += "<FONT color='orange'>[data["outputco2"]]% CO2</FONT>  "
				if (data["outputn2"])
					mixer_part += "<FONT color='gray'>[data["outputn2"]]% N2</FONT>  "
				if (data["outputtg"])
					mixer_part += "<FONT color='black'>[data["outputtg"]]% OTHER</FONT>   "
				if (data["outputkpa"] && data["outputtemp"])
					mixer_part += "<br>Pressure: [data["outputkpa"]] kPa / Temperature: [data["outputtemp"]] &deg;C"
				mixer_part += "<BR>"

				mixer_data += mixer_part

			else
				mixer_part = "<FONT color='red'>[long_name] can not be found!<A href='?src=\ref[src];refresh_status'>Search</A></FONT><BR>"

				mixer_data += mixer_part

		else
			mixer_data = "No mixers connected."

		var/output = {"<strong>[name]</strong><HR>
<strong>Mixer Data: <BR></strong>
[mixer_data]<HR>"}

		return output

	Topic(href, href_list)
		if (..())
			return FALSE
		if (!radio_connection)
			return FALSE
		if (!allowed(usr, req_only_one_required))
			boutput(usr, "<span style=\"color:red\">Access denied!</span>")
			return FALSE

		var/signal/signal = get_free_signal()
		if (!signal || !istype(signal))
			return FALSE

		add_fingerprint(usr)
		signal.transmission_method = 1 //radio
		signal.source = src
		signal.data["tag"] = id

		if (href_list["toggle_pump"])
			var/status = mixer_information["pump_status"]
			var/command
			if (status)
				if (status == "Offline")
					command = "power_on"
				else if (status == "Online")
					command = "power_off"

			if (command)
				signal.data["command"] = "toggle_pump"
				signal.data["parameter"] = command

		if (href_list["pressure_adj"] || href_list["pressure_set"])
			var/pressure = mixer_information["target_pressure"]

			var/amount = 0
			if (href_list["pressure_adj"])
				var/diff = text2num(href_list["pressure_adj"])
				amount = max(0, min(pressure + diff, MAX_PRESSURE))

			else if (href_list["pressure_set"])
				var/change = input(usr,"Target Pressure (0 - [MAX_PRESSURE]):", "Enter target pressure", pressure) as num
				if ((get_dist(src, usr) > 1 && !issilicon(usr)) || !isliving(usr) || iswraith(usr) || isintangible(usr))
					return FALSE
				if (usr.stunned > 0 || usr.weakened > 0 || usr.paralysis > 0 || usr.stat != 0 || usr.restrained())
					return FALSE
				if (!allowed(usr, req_only_one_required))
					boutput(usr, "<span style=\"color:red\">Access denied!</span>")
					return FALSE
				if (!isnum(change))
					return FALSE

				amount = max(0, min(change, MAX_PRESSURE))

			signal.data["command"] = "set_pressure"
			signal.data["parameter"] = num2text(amount)

		if (href_list["ratio"])
			var/amount = text2num(href_list["ratio"])
			var/volume_rate = mixer_information["i1trans"]

			signal.data["command"] = "set_ratio"
			signal.data["parameter"] = num2text(volume_rate + amount)

			if (id == "pmix_control")
				if (((last_change + message_delay) <= world.time))
					last_change = world.time
					logTheThing("atmos", usr, null, "has just edited the plasma mixer at [log_loc(src)].")
					message_admins("[key_name(usr)] has just edited the plasma mixer at at [log_loc(src)].")

		if (href_list["refresh_status"])
			signal.data["status"] = 1

		if (radio_connection && signal)
			radio_connection.post_signal(src, signal)

	proc
		set_frequency(new_frequency)
			radio_controller.remove_object(src, "[frequency]")
			frequency = new_frequency
			radio_connection = radio_controller.add_object(src, "[frequency]")

	initialize()
		set_frequency(frequency)
#undef MAX_PRESSURE