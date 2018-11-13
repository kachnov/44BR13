/obj/beam/custom
	var/obj/item/lens/lens = null


/obj/machinery/industrial_laser
	name = "industrial laser"
	desc = "An industrial laser beam emitter."
	icon = 'icons/obj/machines/fusion.dmi'
	icon_state = "laser-premade"
	var/obj/item/lens/lens = null
	var/obj/beam/custom/beam = null
	var/setup_beam_length = 48

	New ()
		..()
		if (!lens)
			lens = new/obj/item/lens(src)

	disposing()
		if (beam)
			beam.dispose()
			beam = null
		..()

	process()
		if (stat & BROKEN)
			if (beam)
				beam.dispose()
			return
		power_usage = 1000
		..()
		if (stat & NOPOWER)
			if (beam)
				beam.dispose()
			return

		use_power(power_usage)

		if (!beam)
			var/turf/beamTurf = get_step(src, dir)
			if (!istype(beamTurf) || beamTurf.density)
				return
			beam = new /obj/beam/custom(beamTurf, setup_beam_length)
			beam.dir = dir
			beam.lens = lens

			return

		return

	power_change()
		if (powered())
			stat &= ~NOPOWER
			update_icon()
		else
			spawn (rand(0, 15))
				stat |= NOPOWER
				update_icon()

	ex_act(severity)
		switch(severity)
			if (1.0)
				//dispose()
				dispose()
				return
			if (2.0)
				if (prob(50))
					stat |= BROKEN
					update_icon()
			if (3.0)
				if (prob(25))
					stat |= BROKEN
					update_icon()
			else
		return

	proc
		update_icon()
			if (stat & (NOPOWER|BROKEN))
				//icon_state = "heptemitter-p"
				if (beam)
					//qdel(beam)
					beam.dispose()
			//else
				//icon_state = "heptemitter[beam ? "1" : "0"]"
			return



/obj/machinery/beamline
	name = "beamline component"
	desc = "Some sort of heavy machinery for use with a heavy laser setup."
	icon = 'icons/obj/machines/beamline64x32.dmi'
	icon_state = "beamline"


	bullet_act()
		// todo: write in a system for these to react to laser shots
		return

/obj/machinery/beamline/amplifier
	name = "beamline amplifier"
	desc = "Supercharges lasers that pass through it."
	icon = 'icons/obj/machines/beamline64x32.dmi'
	icon_state = "amplifier-0"

/obj/machinery/beamline/spectrometer
	name = "spectrometer"
	desc = "A huge mass spectrometer that works with laser setups."
	icon = 'icons/obj/machines/beamline64x32.dmi'
	icon_state = "spectrometer-0"


