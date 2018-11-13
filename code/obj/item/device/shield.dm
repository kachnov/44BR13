/obj/item/device/shield
	name = "shield"
	icon_state = "shield0"
	var/active = 0.0
	flags = FPRINT | TABLEPASS| CONDUCT
	item_state = "electronic"
	throwforce = 5.0
	throw_speed = 1
	throw_range = 5
	w_class = 2.0
	mats = 10
	module_research = list("energy" = 10, "efficiency" = 10, "protection" = 10)

/obj/item/device/shield/attack_self(mob/user as mob)
	active = !( active )
	if (active)
		boutput(user, "<span style=\"color:blue\">The shield is now active.</span>")
		icon_state = "shield1"
		user.update_inhands()
	else
		boutput(user, "<span style=\"color:blue\">The shield is now inactive.</span>")
		icon_state = "shield0"
		user.update_inhands()
	add_fingerprint(user)
	return
