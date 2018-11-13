// Plant weeds to help fellow xenos regenerate faster. Only usable by drones.
/targetable/xenomorph/plant_weeds
	name = "Plant Weeds"
	cooldown = 30

/targetable/xenomorph/plant_weeds/New()
	..()
	var/obj/screen/ability/F = new /obj/screen/ability/xenomorph/plant_weeds(null)
	F.icon = icon
	F.icon_state = icon_state
	F.owner = src
	F.name = name
	F.desc = desc
	object = F
	
/targetable/xenomorph/plant_weeds/cast()
	new /obj/xeno/weeds(usr.loc, 1)
	usr.visible_message("<span style = \"color: blue\">[usr] shits out weeds.</span>")
				
/obj/screen/ability/xenomorph/plant_weeds
/obj/screen/ability/xenomorph/plant_weeds/clicked(params)

	if (!owner.holder || !owner.holder.owner || usr != owner.holder.owner)
		boutput(usr, "<span style=\"color:red\">You do not own this ability.</span>")
		return
	
	if (owner.holder.owner.stat)
		usr << "<span style = \"color: red\"><em>You are incapacitated.</span>"
		return TRUE
		
	if (!isturf(usr.loc))
		boutput(usr, "<span style = \"color: red\"><em>You cannot use this ability in your current location.</em></span>")
		return
		
	for (var/obj/xeno/weeds/W in usr.loc)
		boutput(usr, "<span style = \"color: red\">There are already weeds here.</span>")
		return

	owner.handleCast()