/targetable/facehugger/scream
	name = "Scream"
	cooldown = 10

/targetable/facehugger/scream/New()
	..()
	var/obj/screen/ability/F = new /obj/screen/ability/facehugger/scream(null)
	F.icon = icon
	F.icon_state = icon_state
	F.owner = src
	F.name = name
	F.desc = desc
	object = F
	
/targetable/facehugger/scream/cast()
	var/mob/living/critter/facehugger/FH = usr
	FH.scream()
	
/obj/screen/ability/facehugger/scream
/obj/screen/ability/facehugger/scream/clicked(params)

	if (!owner.holder || !owner.holder.owner || usr != owner.holder.owner)
		boutput(usr, "<span style=\"color:red\">You do not own this ability.</span>")
		return
	
	if (owner.holder.owner.stat)
		usr << "<span style = \"color: red\"><em>You are incapacitated.</span>"
		return TRUE

	owner.handleCast()