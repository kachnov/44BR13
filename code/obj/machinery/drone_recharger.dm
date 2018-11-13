
/obj/machinery/drone_recharger
	name = "Drone Recharger"
	icon = 'icons/obj/32x64.dmi'
	desc = "A wall-mounted station for drones to recharge at. Automatically activated on approach."
	icon_state = "drone-charger-idle"
	density = 0
	anchored = 1
	mats = 10
	power_usage = 50
	var/chargerate = 400
	var/mob/living/silicon/ghostdrone/occupant = null
	var/transition = 0 //For when closing

	New()
		..()

	process()
		if (!(stat & BROKEN))
			if (occupant)
				power_usage = 500
			else
				power_usage = 50
			..()
		if (stat & (NOPOWER|BROKEN) || !anchored)
			if (occupant)
				turnOff("nopower")
			return

		if (occupant)
			if (!occupant.cell)
				return
			else if (occupant.cell.charge >= occupant.cell.maxcharge) //fully charged yo
				occupant.cell.charge = occupant.cell.maxcharge
				turnOff("fullcharge")
				return
			else
				occupant.cell.charge += chargerate
				use_power(50)
				return
		return TRUE

	HasEntered(atom/movable/AM as mob|obj, atom/OldLoc)
		..()
		if (!occupant && isghostdrone(AM) && !transition)
			turnOn(AM)

	ProximityLeave(atom/movable/AM as mob|obj)
		..()
		if (AM.loc != loc && occupant == AM && isghostdrone(AM))
			turnOff()

	examine()
		..()
		var/msg = "<span style='color: blue;'>"
		if (occupant)
			msg += "[occupant] is currently using it."
		out(usr, "[msg]</span>")

	proc/turnOn(mob/living/silicon/ghostdrone/G)
		if (!G) return FALSE

		out(G, "<span style='color: blue;'>The [src] grabs you as you float by and begins charging your power cell.</span>")
		density = 1
		G.canmove = 0

		//Do opening thing
		icon_state = "drone-charger-open"
		spawn (7) //Animation is 6 ticks, 1 extra for byond
			occupant = G
			updateSprite()
			G.charging = 1
			G.dir = SOUTH
			G.updateSprite()
			G.canmove = 1

		return TRUE

	proc/turnOff(reason)
		if (!occupant || occupant.newDrone) return FALSE

		var/msg = "<span style='color: blue;'>"
		if (reason == "nopower")
			msg += "The [src] spits you out seconds before running out of power."
		else if (reason == "fullcharge")
			msg += "The [src] beeps happily and disengages. You are full."
		else
			msg += "The [src] disengages, allowing you to float [pick("serenely", "hurriedly", "briskly", "lazily")] away."
		out(occupant, "[msg]</span>")

		occupant.charging = 0
		occupant.setFace(occupant.faceType, occupant.faceColor)
		occupant.updateHoverDiscs(occupant.faceColor)
		occupant.updateSprite()
		occupant = null

		//Do closing thing
		icon_state = "drone-charger-close"
		transition = 1
		spawn (7)
			density = 0
			transition = 0
			updateSprite()

		return TRUE

	proc/updateSprite()
		if (occupant)
			icon_state = "drone-charger-charging"
		else
			icon_state = "drone-charger-idle"

		return TRUE


	ex_act(severity)

	blob_act(var/power)

	meteorhit()

	emp_act()

	bullet_act(var/obj/projectile/P)

	power_change()

	attack_hand(var/mob/user as mob)

	emag_act(var/mob/user, var/obj/item/card/emag/E)

	attackby(obj/item/W as obj, mob/user as mob)


/obj/machinery/drone_recharger/factory
	mats = 0

	HasEntered(atom/movable/AM as mob|obj, atom/OldLoc)
		if (!occupant && istype(AM, /obj/item/ghostdrone_assembly) && !transition)
			createDrone(AM)
		..()

	proc/createDrone(var/obj/item/ghostdrone_assembly/G)
		if (!istype(G))
			return FALSE
		var/mob/living/silicon/ghostdrone/GD = new(loc)
		if (GD)
			pool(G)
			GD.newDrone = 1
			available_ghostdrones += GD
			turnOn(GD)
			if (ghostdrone_factory_working)
				ghostdrone_factory_working = 0
			return TRUE
		return FALSE
