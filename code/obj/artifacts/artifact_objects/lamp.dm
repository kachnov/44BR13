/obj/artifact/lamp
	name = "artifact lamp"
	associated_datum = /artifact/lamp
	var/light_brightness = 1
	var/light_R = 1
	var/light_G = 1
	var/light_B = 1
	var/light/light

	New()
		..()
		light_brightness = max(0.5, (rand(5, 20) / 10))
		light_R = rand(25,100) / 100
		light_G = rand(25,100) / 100
		light_B = rand(25,100) / 100
		light = new /light/point
		light.set_brightness(light_brightness)
		light.set_color(light_R, light_G, light_B)
		light.attach(src)

/artifact/lamp
	associated_object = /obj/artifact/lamp
	rarity_class = 1
	validtypes = list("martian","wizard","precursor")
	validtriggers = list(/artifact_trigger/force,/artifact_trigger/electric,/artifact_trigger/heat,
	/artifact_trigger/radiation,/artifact_trigger/carbon_touch,/artifact_trigger/silicon_touch,
	/artifact_trigger/cold)
	activ_text = "begins to emit a steady light!"
	deact_text = "goes dark and quiet."
	react_xray = list(10,90,90,11,"NONE")

	effect_activate(var/obj/O)
		if (..())
			return
		var/obj/artifact/lamp/L = O
		if (L.light)
			L.light.enable()

	effect_deactivate(var/obj/O)
		if (..())
			return
		var/obj/artifact/lamp/L = O
		if (L.light)
			L.light.disable()