/targetable/mutt/hivemind
	name = "Hivemind"
	cooldown = 5

/targetable/mutt/hivemind/New()
	..()
	var/obj/screen/ability/F = new /obj/screen/ability/mutt/hivemind(null)
	F.icon = icon
	F.icon_state = icon_state
	F.owner = src
	F.name = name
	F.desc = desc
	object = F
	
/targetable/mutt/hivemind/cast()
	return REPO.mutt_hivemind.display_info(usr)

/obj/screen/ability/mutt/hivemind
/obj/screen/ability/mutt/hivemind/clicked(params)

	if (!owner.holder || !owner.holder.owner || usr != owner.holder.owner)
		boutput(usr, "<span style=\"color:red\">You do not own this ability.</span>")
		return
	
	if (owner.holder.owner.stat)
		usr << "<span style = \"color: red\"><em>You are incapacitated.</span>"
		return TRUE

	owner.handleCast()