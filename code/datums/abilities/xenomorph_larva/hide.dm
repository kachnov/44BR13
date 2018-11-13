/targetable/xenomorph_larva/hide
	name = "Hide"

/targetable/xenomorph_larva/hide/New()
	..()
	var/obj/screen/ability/F = new /obj/screen/ability/xenomorph_larva/hide(null)
	F.icon = icon
	F.icon_state = icon_state
	F.owner = src
	F.name = name
	F.desc = desc
	object = F
	
/targetable/xenomorph_larva/hide/cast()
	usr.layer = switch_value(usr.layer, initial(usr.layer), HIDING_XENO_LAYER)

/obj/screen/ability/xenomorph_larva/hide
/obj/screen/ability/xenomorph_larva/hide/clicked(params)

	if (!owner.holder || !owner.holder.owner || usr != owner.holder.owner)
		boutput(usr, "<span style=\"color:red\">You do not own this ability.</span>")
		return
	
	if (owner.holder.owner.stat)
		usr << "<span style = \"color: red\"><em>You are incapacitated.</span>"
		return TRUE
		
	owner.handleCast()