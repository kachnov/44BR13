/obj/machinery/telejam
	name = "teleportation jammer"
	desc = "Generates a force field interferes with teleportation devices."
	icon = 'icons/obj/meteor_shield.dmi'
	icon_state = "shieldgen"
	density = 1
	opacity = 0
	anchored = 0
	mats = 9
	var/obj/item/cell/PCEL = null
	var/coveropen = 0
	var/active = 0
	var/range = 3
	var/image/display_active = null
	var/image/display_battery = null
	var/image/display_panel = null
	var/battery_level = 3
	var/sound/sound_on = 'sound/effects/shielddown.ogg'
	var/sound/sound_off = 'sound/effects/shielddown2.ogg'
	var/sound/sound_battwarning = 'sound/machines/pod_alarm.ogg'

	New()
		PCEL = new /obj/item/cell/supercell(src)
		PCEL.charge = PCEL.maxcharge

		display_active = image('icons/obj/meteor_shield.dmi', "")
		display_battery = image('icons/obj/meteor_shield.dmi', "")
		display_panel = image('icons/obj/meteor_shield.dmi', "")
		..()

	disposing()
		turn_off()
		if (PCEL)
			PCEL.dispose()
		PCEL = null
		display_active = null
		display_battery = null
		sound_on = null
		sound_off = null
		sound_battwarning = null
		..()

	examine()
		..()
		if (usr.client)
			var/charge_percentage = 0
			if (PCEL && PCEL.charge > 0 && PCEL.maxcharge > 0)
				charge_percentage = round((PCEL.charge/PCEL.maxcharge)*100)
				boutput(usr, "It has [PCEL.charge]/[PCEL.maxcharge] ([charge_percentage]%) battery power left.")
				boutput(usr, "The jammer's range is [range] units of distance.")
				boutput(usr, "The unit will consume [5 * range] power a second.")
			else
				boutput(usr, "It seems to be missing a usable battery.")

	process()
		if (active)
			if (!PCEL)
				turn_off()
				return
			PCEL.charge -= 5 * range

			var/charge_percentage = 0
			var/current_battery_level = 0
			if (PCEL && PCEL.charge > 0 && PCEL.maxcharge > 0)
				charge_percentage = round((PCEL.charge/PCEL.maxcharge)*100)
				switch(charge_percentage)
					if (75 to 100)
						current_battery_level = 3
					if (35 to 74)
						current_battery_level = 2
					else
						current_battery_level = 1

			if (current_battery_level != battery_level)
				battery_level = current_battery_level
				build_icon()
				if (battery_level == 1)
					playsound(loc, sound_battwarning, 50, 1)
					visible_message("<span style=\"color:red\"><strong>[src] emits a low battery alarm!</strong></span>")

			if (PCEL.charge < 0)
				visible_message("<strong>[src]</strong> runs out of power and shuts down.")
				turn_off()
				return

	attack_hand(mob/user as mob)
		if (coveropen && PCEL)
			PCEL.set_loc(loc)
			PCEL = null
			boutput(user, "You remove the power cell.")
		else
			if (active)
				turn_off()
				visible_message("<strong>[user.name]</strong> powers down the [src].")
			else
				if (PCEL)
					if (PCEL.charge > 0)
						turn_on()
						visible_message("<strong>[user.name]</strong> powers up the [src].")
					else
						boutput(user, "[src]'s battery light flickers briefly.")
				else
					boutput(user, "Nothing happens.")
		build_icon()

	attackby(obj/item/W as obj, mob/user as mob)
		if (istype(W, /obj/item/screwdriver))
			coveropen = !coveropen
			visible_message("<strong>[user.name]</strong> [coveropen ? "opens" : "closes"] [src]'s cell cover.")

		if (istype(W,/obj/item/cell) && coveropen && !PCEL)
			user.drop_item()
			W.set_loc(src)
			PCEL = W
			boutput(user, "You insert the power cell.")

		else
			..()

		build_icon()

	attack_ai(mob/user as mob)
		return attack_hand(user)

	proc/build_icon()
		overlays = null

		if (coveropen)
			if (istype(PCEL,/obj/item/cell))
				display_panel.icon_state = "panel-batt"
			else
				display_panel.icon_state = "panel-nobatt"
			overlays += display_panel

		if (active)
			display_active.icon_state = "on"
			overlays += display_active
			if (istype(PCEL,/obj/item/cell))
				var/charge_percentage = null
				if (PCEL.charge > 0 && PCEL.maxcharge > 0)
					charge_percentage = round((PCEL.charge/PCEL.maxcharge)*100)
					switch(charge_percentage)
						if (75 to 100)
							display_battery.icon_state = "batt-3"
						if (35 to 74)
							display_battery.icon_state = "batt-2"
						else
							display_battery.icon_state = "batt-1"
				else
					display_battery.icon_state = "batt-3"
				overlays += display_battery

	proc/turn_on()
		if (!PCEL)
			return
		if (PCEL.charge < 0)
			return

		anchored = 1
		active = 1
		playsound(loc, sound_on, 50, 1)
		build_icon()

	proc/turn_off()
		anchored = 0
		active = 0
		playsound(loc, sound_off, 50, 1)
		build_icon()

	active
		New()
			..()
			turn_on()
