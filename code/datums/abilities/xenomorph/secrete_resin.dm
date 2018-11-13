// Shit out resin, adding to any resin already on the tile. Only usable by drones.
/targetable/xenomorph/secrete_resin
	name = "Secrete Resin"
	cooldown = 10

/targetable/xenomorph/secrete_resin/New()
	..()
	var/obj/screen/ability/F = new /obj/screen/ability/xenomorph/secrete_resin(null)
	F.icon = icon
	F.icon_state = icon_state
	F.owner = src
	F.name = name
	F.desc = desc
	object = F
	
/targetable/xenomorph/secrete_resin/cast()
	for (var/obj/item/resin/R in usr.loc)
		R.add(1)
		return TRUE 
	new /obj/item/resin(usr.loc, 1)
	usr.visible_message("<span style = \"color: blue\">[usr] shits out resin.</span>")
				
/obj/screen/ability/xenomorph/secrete_resin
/obj/screen/ability/xenomorph/secrete_resin/clicked(params)

	if (!owner.holder || !owner.holder.owner || usr != owner.holder.owner)
		boutput(usr, "<span style=\"color:red\">You do not own this ability.</span>")
		return
	
	if (owner.holder.owner.stat)
		usr << "<span style = \"color: red\"><em>You are incapacitated.</span>"
		return TRUE
		
	if (!isturf(usr.loc))
		boutput(usr, "<span style = \"color: red\"><em>You cannot use this ability in your current location.</em></span>")
		return

	owner.handleCast()