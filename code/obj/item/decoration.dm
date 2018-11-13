
/obj/item/decoration
	icon = 'icons/obj/decoration.dmi'
	flags = FPRINT | TABLEPASS
	w_class = 2.0

/obj/item/decoration/flower_vase
	name = "flower vase"
	desc = "Some pretty flowers that really brighten up the room."
	icon_state = "vase"

/obj/item/decoration/ashtray
	name = "ashtray"
	icon = 'icons/obj/cigarettes.dmi'
	icon_state = "ashtray"
	w_class = 1.0
	var/butts = 0 // heh

	New()
		..()
		update_icon()

	attack_self(mob/user as mob)
		if (butts)
			user.visible_message("<strong>[user]</strong> tips out [src] onto the floor.",\
			"You tip out [src] onto the floor.")
			var/turf/T = get_turf(src)
			new /obj/decal/cleanable/ash(T)
			for (var/i = 0, i < butts, i++)
				new /obj/item/cigbutt(T)
			butts = 0 // pff
			update_icon()
			overlays = null

	attackby(obj/item/W, mob/user)
		if (istype(W, /obj/item/clothing/mask/cigarette) && W:lit)
			W:put_out(user, "<strong>[user]</strong> puts out [W] in [src].")
			user.u_equip(W)
			qdel(W)
			butts ++ // hehhh
			update_icon()
			overlays = null
			overlays += "ashtray-smoke"
			spawn (800)
				overlays -= "ashtray-smoke"
		else
			return ..()

	proc/update_icon()
		if (butts <= 0)
			icon_state = "ashtray"
		else if (butts == 1)
			icon_state = "ashtray2"
		else if (butts == 2)
			icon_state = "ashtray3"
		else
			icon_state = "ashtray4"
