
/obj/item/magtractor
	name = "magtractor"
	desc = "A device used to pick up and hold objects via the mysterious power of magnets."
	icon = 'icons/obj/items.dmi'
	inhand_image_icon = 'icons/mob/inhand/hand_tools.dmi'
	icon_state = "magtractor"
	opacity = 0
	density = 0
	anchored = 0.0
	flags = FPRINT | TABLEPASS| CONDUCT | EXTRADELAY
	force = 10.0
	throwforce = 10.0
	throw_speed = 1
	throw_range = 5
	w_class = 3.0
	m_amt = 50000
	mats = 12
	stamina_damage = 15
	stamina_cost = 15
	stamina_crit_chance = 5
	var/working = 0
	var/mob/holder //this is hacky way to get the user without looping through all mobs in process
	var/obj/item/holding
	var/processHeld = 0
	var/highpower = 0 //high power mode (holding during movement)

	var/action/holdAction

	New(mob/user)
		..()
		if (!(src in processing_items))
			processing_items.Add(src)
		if (user)
			holder = user
			verbs |= /obj/item/magtractor/proc/toggleHighPower

	process()
		//power usage here maybe??

		if (!holding && holder && processHeld) //If the item has been consumed somehow
			actions.stopId("magpickerhold", holder)
			processHeld = 0
		return

	pickup(mob/user)
		..()
		holder = user
		verbs |= /obj/item/magtractor/proc/toggleHighPower

	dropped(mob/user)
		..()
		holder = null
		verbs -= /obj/item/magtractor/proc/toggleHighPower

	attackby(obj/item/W as obj, mob/user as mob)
		if (!W) return FALSE

		if (holding)
			out(user, "<span style='color: red;'>The [name] is already holding \the [holding]!</span>")
			return FALSE

		if (W.anchored || W.w_class == 4) //too bulky for backpacks, too bulky for this
			out(user, "<span style='color: blue;'>The [name] can't possibly hold that heavy an item!</span>")
			return FALSE

		if (istype(W, /obj/item/magtractor))
			var/turf/T = get_ranged_target_turf(user, GetOppositeDirection(user.dir), 7)
			playsound(user.loc, "sound/effects/bang.ogg", 50, 1)
			user.visible_message("<span class='combat bold'>\The [src]'s magnets violently repel as they counter a similar magnetic field!</span>")
			user.throw_at(T, 7, 10)
			user.stunned += 2
			return FALSE
		else
			actions.start(new/action/bar/private/icon/magPicker(W, src), user)

		return TRUE

	attack_self(mob/user as mob)
		if (holding)
			//activate held item (if possible)
			holding.attack_self(user)
			updateHeldOverlay(holding) //for items that update icon on activation (e.g. welders)
		else
			return FALSE

	afterattack(atom/A, mob/user as mob)
		if (!A) return FALSE

		if (!holding)
			if (!istype(A, /obj/item)) return FALSE
			var/obj/item/target = A

			if (target.anchored || target.w_class == 4) //too bulky for backpacks, too bulky for this
				out(user, "<span style='color: blue;'>The [name] can't possibly hold that heavy an item!</span>")
				return FALSE

			if (istype(target, /obj/item/magtractor))
				return FALSE

			//pick up item
			user.u_equip(A) //For when holding the item in other hand
			actions.start(new/action/bar/private/icon/magPicker(target, src), user)

		return TRUE

	throw_begin(atom/target)
		..()
		if (holding)
			actions.stopId("magpickerhold", usr)

	dropped(mob/user as mob)
		..()
		if (holding)
			actions.stopId("magpickerhold", usr)

	examine()
		..()
		var/msg = "<span style='color: blue;'>"
		if (highpower)
			msg += "The [src] has HPM enabled!<br>"
		if (holding)
			msg += "\The [holding] is enveloped in the magnetic field.<br>"
		out(usr, "[msg]</span>")

	proc/releaseItem()
		set src in usr
		set name = "Release Item"
		set desc = "Release the item currently held by the magtractor"
		set category = "Local"

		if (!src || !holding || usr.stat || usr.stunned || usr.weakened || usr.paralysis) return FALSE
		actions.stopId("magpickerhold", usr)
		return TRUE

	proc/toggleHighPower()
		set src in usr
		set name = "Toggle HPM (High Power Mode)"
		set desc = "Boosts the magtractor power levels above safe amounts, allowing it to hold onto items during movement"
		set category = "Local"

		if (!src || usr.stat || usr.stunned || usr.weakened || usr.paralysis) return FALSE

		var/image/magField = GetOverlayImage("magField")
		var/msg = "<span style='color: blue;'>You toggle the [src]'s HPM "
		if (highpower)
			if (holdAction) holdAction.interrupt_flags |= INTERRUPT_MOVE
			if (magField) magField.color = "#66ebe0" //blue
			highpower = 0
			msg += "off"
		else
			if (holdAction) holdAction.interrupt_flags &= ~INTERRUPT_MOVE
			if (magField) magField.color = "#FF4A4A" //red
			highpower = 1
			msg += "on"
		if (magField) UpdateOverlays(magField, "magField")
		out(usr, "[msg].</span>")
		return TRUE

	proc/updateHeldOverlay(obj/item/W as obj)
		if (W)
			var/image/heldItem = GetOverlayImage("heldItem")
			if (!heldItem) heldItem = image(W.icon, W.icon_state)
			heldItem.color = W.color
			heldItem.transform *= 0.85
			heldItem.pixel_y = 1
			heldItem.layer = -1
			UpdateOverlays(heldItem, "heldItem")
		else
			UpdateOverlays(null, "heldItem")

	//Called by action_controls.dm, magPicker
	proc/pickupItem(obj/item/W as obj, mob/user as mob)
		if (!W || !user || !istype(W, /obj/item) || !ismob(user) || holding) return FALSE

		working = 1
		user.pulling = null //quit pullin
		user:hud:update_pulling()

		var/atom/oldloc = W.loc
		W.set_loc(src)

		if (istype(oldloc, /obj/item/storage)) //For removing items from containers with the tractor
			var/obj/item/storage/S = oldloc
			S.hud.remove_item(W)
			W.layer = 3 //why is this necessary aaaaa!.

		holding = W
		processHeld = 1
		w_class = 4.0 //bulky
		useInnerItem = 1
		icon_state = "magtractor-active"

		UpdateOverlays(null, "magField")
		var/image/I = image('icons/obj/items.dmi', "magtractor-field")
		I.layer = -2

		if (highpower)
			I.color = "#FF4A4A" //red
		else
			I.color = "#66ebe0" //blue

		UpdateOverlays(I, "magField")
		updateHeldOverlay(W)

		playsound(loc, "sound/machines/ping.ogg", 50, 1)
		//user.visible_message("<span class='bold' style='color: blue;'>[user] pulls \the [W] into the [name]</span>", "<span style='color: blue;'>The [name] pulls \the [W] into it's magnetic field and flickers worryingly.[highpower ? "" : " You must hold still while using this item."]</span>")

		verbs |= /obj/item/magtractor/proc/releaseItem
		working = 0

		return TRUE

	//Called by action_controls.dm, magPickerHold
	proc/dropItem()
		if (working) return FALSE

		holdAction = null
		verbs -= /obj/item/magtractor/proc/releaseItem

		working = 1
		w_class = 3.0 //normal
		useInnerItem = 0
		var/turf/T = get_turf(src)

		var/msg = "<span class='bold' style='color: blue;'>The [name] deactivates it's magnetic field"
		if (holding) //item still exists, dropping
			holding.set_loc(T)
			holding.layer = initial(holding.layer)
			msg += " and lets \the [holding] fall to the floor."
			holding = null
		else //item no longer exists (was used up)
			msg += " with nothing left to hold"
		msg += "</span>"
		T.visible_message(msg)

		icon_state = "magtractor"
		UpdateOverlays(null, "magField")
		updateHeldOverlay()
		//TODO: playsound, de-power thing
		working = 0
		processHeld = 0

		return TRUE
