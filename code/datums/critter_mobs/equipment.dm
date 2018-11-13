/equipmentHolder
	var/name = "head"							// designation of the
	var/offset_x = 0							// pixel offset on the x axis for mob overlays
	var/offset_y = 0							// pixel offset on the x axis for mob overlays

	var/armor_coverage = 0
	var/icon/icon = 'icons/mob/hud_human.dmi'	// the icon of the HUD object
	var/icon_state = "hair"						// the icon state of the HUD object
	var/obj/item/item							// the item being worn in this slot

	var/list/type_filters = list()				// a list of parent types whose subtypes are equippable
	var/obj/screen/hud/screenObj				// ease of life

	var/mob/holder = null

	var/equipment_layer = MOB_CLOTHING_LAYER

	New(var/mob/M)
		..()
		holder = M

	proc/can_equip(var/obj/item/I)
		for (var/T in type_filters)
			if (istype(I, T))
				return TRUE
		return FALSE

	proc/equip(var/obj/item/I)
		if (item || !can_equip(I))
			return FALSE
		if (screenObj)
			I.screen_loc = screenObj.screen_loc
		item = I
		item.loc = holder
		holder.update_clothing()
		on_equip()
		return TRUE

	proc/drop(var/force = 0)
		if (!item)
			return FALSE
		if ((item.cant_drop || item.cant_other_remove) && !force)
			return FALSE
		item.loc = get_turf(holder)
		item.master = null
		item.layer = initial(item.layer)
		item = null
		holder.update_clothing()
		on_unequip()
		return TRUE

	proc/remove()
		if (!item)
			return FALSE
		if (item.cant_self_remove)
			return FALSE
		if (!holder.put_in_hand(item))
			return FALSE
		item = null
		on_unequip()
		return TRUE

	proc/on_update()
	proc/on_equip()
	proc/on_unequip()
	proc/after_setup(var/hud)

	head
		name = "head"
		type_filters = list(/obj/item/clothing/head)
		icon = 'icons/mob/hud_human.dmi'
		icon_state = "hair"
		armor_coverage = HEAD

		skeleton
			var/equipmentHolder/head/skeleton/next
			var/equipmentHolder/head/skeleton/prev
			on_update()
				var/o = 0
				var/equipmentHolder/head/skeleton/c = prev
				while (c)
					if (c.item)
						o += 3
					c = c.prev
				offset_y = o

			proc/spawn_next()
				next = new /equipmentHolder/head/skeleton(holder)
				next.prev = src
				return next

	suit
		name = "suit"
		type_filters = list(/obj/item/clothing/suit)
		icon = 'icons/mob/hud_human.dmi'
		icon_state = "armor"
		armor_coverage = TORSO

	ears
		name = "ears"
		type_filters = list(/obj/item/device/radio)
		icon = 'icons/mob/hud_human.dmi'
		icon_state = "ears"

		on_equip()
			holder.ears = item

		on_unequip()
			holder.ears = null

		intercom
			after_setup(var/hud/hud)
				equip(new /obj/item/device/radio/intercom(holder))
				if (item)
					hud.add_object(item, HUD_LAYER+1, screenObj.screen_loc)