/obj/item/satchel
	name = "satchel"
	desc = "A leather bag. It holds 0/20 items."
	icon = 'icons/obj/items.dmi'
	icon_state = "satchel"
	flags = ONBELT
	w_class = 1
	var/maxitems = 30
	var/list/allowed = list(/obj/item/)
	var/itemstring = "items"

	New()
		overlays += image('icons/obj/items.dmi', "satcounter0")
		..()

	attackby(obj/item/W as obj, mob/user as mob)
		var/proceed = 0
		for (var/check_path in allowed)
			if (istype(W, check_path))
				proceed = 1
				break
		if (!proceed)
			boutput(user, "<span style=\"color:red\">[src] cannot hold that kind of item!</span>")
			return

		if (contents.len < maxitems)
			user.u_equip(W)
			W.set_loc(src)
			W.dropped()
			boutput(user, "<span style=\"color:blue\">You put [W] in [src].</span>")
			var/itemamt = contents.len
			desc = "A leather bag. It holds [itemamt]/[maxitems] [itemstring]."
			if (itemamt == maxitems) boutput(user, "<span style=\"color:blue\">[src] is now full!</span>")
			satchel_updateicon()
		else boutput(user, "<span style=\"color:red\">[src] is full!</span>")

	attack_self(var/mob/user as mob)
		if (contents.len)
			var/turf/T = user.loc
			for (var/obj/item/I in contents)
				I.set_loc(T)
			boutput(user, "<span style=\"color:blue\">You empty out [src].</span>")
			desc = "A leather bag. It holds 0/[maxitems] [itemstring]."
			satchel_updateicon()
		else ..()

	MouseDrop_T(atom/movable/O as obj, mob/user as mob)
		var/proceed = 0
		for (var/check_path in allowed)
			if (istype(O, check_path))
				proceed = 1
				break
		if (!proceed)
			boutput(user, "<span style=\"color:red\">[src] cannot hold that kind of item!</span>")
			return

		if (contents.len < maxitems)
			user.visible_message("<span style=\"color:blue\">[user] begins quickly filling [src]!</span>")
			var/staystill = user.loc
			var/amt
			for (var/obj/item/I in view(1,user))
				if (!istype(I, O)) continue
				if (I in user)
					continue
				I.set_loc(src)
				amt = contents.len
				desc = "A leather bag. It holds [amt]/[maxitems] [itemstring]."
				satchel_updateicon()
				sleep(2)
				if (user.loc != staystill) break
				if (contents.len >= maxitems)
					boutput(user, "<span style=\"color:blue\">[src] is now full!</span>")
					break
			boutput(user, "<span style=\"color:blue\">You finish filling [src]!</span>")
		else boutput(user, "<span style=\"color:red\">[src] is full!</span>")

	proc/satchel_updateicon()
		var/perc
		if (contents.len > 0 && maxitems > 0)
			perc = (contents.len / maxitems) * 100
		else
			perc = 0
		overlays = null
		switch(perc)
			if (-INFINITY to 0)
				overlays += image('icons/obj/items.dmi', "satcounter0")
			if (1 to 24)
				overlays += image('icons/obj/items.dmi', "satcounter1")
			if (25 to 49)
				overlays += image('icons/obj/items.dmi', "satcounter2")
			if (50 to 74)
				overlays += image('icons/obj/items.dmi', "satcounter3")
			if (75 to 99)
				overlays += image('icons/obj/items.dmi', "satcounter4")
			if (100 to INFINITY)
				overlays += image('icons/obj/items.dmi', "satcounter5")

/obj/item/satchel/hydro
	name = "produce satchel"
	desc = "A leather bag. It holds 0/50 items of produce."
	icon_state = "hydrosatchel"
	maxitems = 50
	allowed = list(/obj/item/seed,
	/obj/item/plant,
	/obj/item/reagent_containers/food,
	/obj/item/organ,
	/obj/item/clothing/head/butt,
	/obj/item/parts/human_parts/arm,
	/obj/item/parts/human_parts/leg,
	/obj/item/raw_material/cotton)
	itemstring = "items of produce"