/targetable/facehugger/communicate
	name = "Communicate"
	cooldown = 5

/targetable/facehugger/communicate/New()
	..()
	var/obj/screen/ability/F = new /obj/screen/ability/facehugger/communicate(null)
	F.icon = icon
	F.icon_state = icon_state
	F.owner = src
	F.name = name
	F.desc = desc
	object = F
	
/targetable/facehugger/communicate/cast()
	var/x = trim(copytext(sanitize(input(usr, "Say what?") as text), 1, MAX_MESSAGE_LEN))
	if (x)
		xenomorph_hivemind.communicate("<em><strong>[usr.name]</strong>: [x]</em>")

/obj/screen/ability/facehugger/communicate
/obj/screen/ability/facehugger/communicate/clicked(params)

	if (!owner.holder || !owner.holder.owner || usr != owner.holder.owner)
		boutput(usr, "<span style=\"color:red\">You do not own this ability.</span>")
		return
	
	if (owner.holder.owner.stat)
		usr << "<span style = \"color: red\"><em>You are incapacitated.</span>"
		return TRUE

	owner.handleCast()