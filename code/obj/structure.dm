/obj/structure
	icon = 'icons/obj/structures.dmi'

	girder
		icon_state = "girder"
		anchored = 1
		density = 1
		var/state = 0
		desc = "A metal support for an incomplete wall. Metal could be added to finish the wall, reinforced metal could make the girders stronger, or it could be pried to displace it."

		displaced
			name = "displaced girder"
			icon_state = "displaced"
			anchored = 0
			desc = "An unsecured support for an incomplete wall. A screwdriver would seperate the metal into sheets, or adding metal or reinforced metal could turn it into fake wall that could opened by hand."

		reinforced
			icon_state = "reinforced"
			state = 2
			desc = "A reinforced metal support for an incomplete wall. Reinforced metal could turn it into a reinforced wall, or it could be disassembled with various tools."

	blob_act(var/power)
		if (power < 30)
			return
		if (prob(power - 29))
			qdel(src)

	meteorhit(obj/O as obj)
		qdel(src)

/obj/structure/ex_act(severity)
	switch(severity)
		if (1.0)
			qdel(src)
			return
		if (2.0)
			if (prob(50))
				qdel(src)
				return
		if (3.0)
			return
	return

/obj/structure/girder/attackby(obj/item/W as obj, mob/user as mob)
	if (istype(W, /obj/item/wrench) && state == 0 && anchored && !istype(src,/obj/structure/girder/displaced))
		playsound(loc, "sound/items/Ratchet.ogg", 100, 1)
		var/turf/T = get_turf(user)
		boutput(user, "<span style=\"color:blue\">Now disassembling the girder</span>")
		sleep(40)
		if (get_turf(user) == T)
			boutput(user, "<span style=\"color:blue\">You dissasembled the girder!</span>")
			var/atom/A = new /obj/item/sheet(get_turf(src))
			if (material)
				A.setMaterial(material)
			else
				var/material/M = getCachedMaterial("steel")
				A.setMaterial(M)
			qdel(src)

	else if (istype(W, /obj/item/screwdriver) && state == 2 && istype(src,/obj/structure/girder/reinforced))
		playsound(loc, "sound/items/Screwdriver.ogg", 100, 1)
		var/turf/T = get_turf(user)
		boutput(user, "<span style=\"color:blue\">Now unsecuring support struts</span>")
		sleep(40)
		if (get_turf(user) == T)
			boutput(user, "<span style=\"color:blue\">You unsecured the support struts!</span>")
			state = 1

	else if (istype(W, /obj/item/wirecutters) && istype(src,/obj/structure/girder/reinforced) && state == 1)
		playsound(loc, "sound/items/Wirecutter.ogg", 100, 1)
		var/turf/T = get_turf(user)
		boutput(user, "<span style=\"color:blue\">Now removing support struts</span>")
		sleep(40)
		if (get_turf(user) == T)
			boutput(user, "<span style=\"color:blue\">You removed the support struts!</span>")
			var/atom/A = new/obj/structure/girder( loc )
			if (material) A.setMaterial(material)
			qdel(src)

	else if (istype(W, /obj/item/crowbar) && state == 0 && anchored )
		playsound(loc, "sound/items/Crowbar.ogg", 100, 1)
		var/turf/T = get_turf(user)
		boutput(user, "<span style=\"color:blue\">Now dislodging the girder</span>")
		sleep(40)
		if (get_turf(user) == T)
			boutput(user, "<span style=\"color:blue\">You dislodged the girder!</span>")
			var/atom/A = new/obj/structure/girder/displaced( loc )
			if (material) A.setMaterial(material)
			qdel(src)

	else if (istype(W, /obj/item/wrench) && state == 0 && !anchored )
		if (!istype(loc, /turf/simulated/floor))
			boutput(user, "<span style=\"color:red\">Not sure what this floor is made of but you can't seem to wrench a hole for a bolt in it.</span>")
			return
		playsound(loc, "sound/items/Ratchet.ogg", 100, 1)
		var/turf/T = get_turf(user)
		boutput(user, "<span style=\"color:blue\">Now securing the girder</span>")
		sleep(40)
		if (!istype(loc, /turf/simulated/floor))
			boutput(user, "<span style=\"color:red\">You feel like your body is being ripped apart from the inside. Maybe you shouldn't try that again. For your own safety, I mean.</span>")
			return
		if (get_turf(user) == T)
			boutput(user, "<span style=\"color:blue\">You secured the girder!</span>")
			var/atom/A = new/obj/structure/girder( loc )
			if (material) A.setMaterial(material)
			qdel(src)

	else if (istype(W, /obj/item/sheet))
		var/obj/item/sheet/S = W
		if (S.amount < 2)
			boutput(user, "<span style=\"color:red\">You need at least two sheets on the stack to do this.</span>")
			return

		var/turf/T = get_turf(user)

		if (icon_state != "reinforced" && S.reinforcement)
			user.visible_message("<strong>[user]</strong> begins reinforcing [src].")
			sleep(60)
			if (user.loc == T)
				boutput(user, "You finish reinforcing the girder.")
				var/atom/A = new/obj/structure/girder/reinforced( loc )
				if (W.material)
					A.setMaterial(material)
				else
					var/material/M = getCachedMaterial("steel")
					A.setMaterial(M)
				qdel(src)
				return
			else
				boutput(user, "<span style=\"color:red\">You'll need to stand still while reinforcing the girder.</span>")
				return

		else
			user.visible_message("<strong>[user]</strong> begins adding plating to [src].")
			sleep(20)
			// it was a good run, finishing all those walls with a sheet of 2 metal, but this is now causing runtimes
			// so i'm going to be hitler yet again -- marquesas
			if (get_turf(user) == T && W && user.equipped() == W && S.amount >= 2 && istype(loc, /turf/simulated/floor))
				boutput(user, "You finish building the wall.")
				logTheThing("station", user, null, "builds a Wall in [user.loc.loc] ([showCoords(user.x, user.y, user.z)])")
				var/turf/Tsrc = get_turf(src)
				var/turf/simulated/wall/WALL
				if (S.reinforcement)
					WALL = Tsrc.ReplaceWithRWall()
				else
					WALL = Tsrc.ReplaceWithWall()
				if (material)
					WALL.setMaterial(material)
				else
					var/material/M = getCachedMaterial("steel")
					WALL.setMaterial(M)
				// drsingh attempted fix for Cannot read null.amount
				if (S != null)
					S.amount -= 2
					if (S.amount <= 0)
						qdel(W)
				qdel(src)
		return

	else
		..()

/obj/structure/girder/displaced/attackby(obj/item/W as obj, mob/user as mob)
	if (istype(W, /obj/item/sheet))
		if (!istype(loc, /turf/simulated/floor))
			boutput(user, "<span style=\"color:red\">You can't build a false wall there.</span>")
			return

		var/obj/item/sheet/S = W
		var/turf/simulated/floor/T = loc

		var/FloorIcon = T.icon
		var/FloorState = T.icon_state
		var/FloorIntact = T.intact
		var/FloorBurnt = T.burnt
		var/FloorName = T.name
		var/oldmat = material

		var/atom/A = new /turf/simulated/wall/false_wall(loc)
		if (oldmat)
			A.setMaterial(oldmat)
		else
			var/material/M = getCachedMaterial("steel")
			A.setMaterial(M)

		var/turf/simulated/wall/false_wall/FW = A

		FW.setFloorUnderlay(FloorIcon, FloorState, FloorIntact, 0, FloorBurnt, FloorName)
		FW.known_by += user
		if (S.reinforcement)
			FW.icon_state = "rdoor1"
		S.amount--
		if (S.amount < 1)
			qdel(S)
		boutput(user, "You finish building the false wall.")
		logTheThing("station", user, null, "builds a False Wall in [user.loc.loc] ([showCoords(user.x, user.y, user.z)])")
		qdel(src)
		return

	else if (istype(W, /obj/item/screwdriver))
		var/obj/item/sheet/S = new /obj/item/sheet(loc)
		if (material)
			S.setMaterial(material)
		else
			var/material/M = getCachedMaterial("steel")
			S.setMaterial(M)
		playsound(loc, "sound/items/Screwdriver.ogg", 75, 1)
		qdel(src)
		return
	else
		return ..()

/obj/structure/woodwall
	name = "wooden barricade"
	desc = "This was thrown up in a hurry."
	icon = 'icons/obj/structures.dmi'
	icon_state = "woodwall"
	anchored = 1
	density = 1
	opacity = 1
	var/health = 30
	var/builtby = null

	virtual
		icon = 'icons/effects/VR.dmi'

	proc/checkhealth()
		if (health <= 30)
			icon_state = "woodwall"
		if (health <= 20)
			icon_state = "woodwall2"
		if (health <= 10)
			icon_state = "woodwall3"
			opacity = 0
		if (health <= 5)
			icon_state = "woodwall4"
		if (health <= 0)
			visible_message("<span style=\"color:red\"><strong>[src] collapses!</strong></span>")
			playsound(loc, "sound/effects/wbreak.wav", 100, 1)
			qdel(src)

	attack_hand(mob/user as mob)
		if (istype(user, /mob/living/carbon/human))
			visible_message("<span style=\"color:red\"><strong>[user]</strong> bashes [src]!</span>")
			playsound(loc, "sound/effects/zhit.ogg", 100, 1)
			health -= rand(1,3)
			checkhealth()
			return
		else
			return
	attackby(var/obj/item/W as obj)
		..()
		playsound(loc, "sound/effects/zhit.ogg", 100, 1)
		health -= W.force
		checkhealth()
		return