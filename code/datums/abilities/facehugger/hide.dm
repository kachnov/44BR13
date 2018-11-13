/targetable/facehugger/hide
	name = "Hide"

/targetable/facehugger/hide/New()
	..()
	var/obj/screen/ability/F = new /obj/screen/ability/facehugger/hide(null)
	F.icon = icon
	F.icon_state = icon_state
	F.owner = src
	F.name = name
	F.desc = desc
	object = F
	
/targetable/facehugger/hide/cast()
	usr.layer = switch_value(usr.layer, initial(usr.layer), HIDING_XENO_LAYER)

/obj/screen/ability/facehugger/hide
/obj/screen/ability/facehugger/hide/clicked(params)

	if (!owner.holder || !owner.holder.owner || usr != owner.holder.owner)
		boutput(usr, "<span style=\"color:red\">You do not own this ability.</span>")
		return
	
	if (owner.holder.owner.stat)
		usr << "<span style = \"color: red\"><em>You are incapacitated.</span>"
		return TRUE
		
	// we're probably in a mob
	if (!isturf(owner.holder.owner.loc))
		return FALSE
		
	owner.handleCast()