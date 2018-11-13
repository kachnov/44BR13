/targetable/mutt/communicate
	name = "Communicate"
	cooldown = 5

/targetable/mutt/communicate/New()
	..()
	var/obj/screen/ability/F = new /obj/screen/ability/mutt/communicate(null)
	F.icon = icon
	F.icon_state = icon_state
	F.owner = src
	F.name = name
	F.desc = desc
	object = F
	
/targetable/mutt/communicate/cast()
	var/x = trim(copytext(sanitize(input(usr, "Say what?") as text), 1, MAX_MESSAGE_LEN))
	if (x)
		mutt_hivemind.communicate("<em><strong>[usr.name]</strong>: [x]</em>")

/obj/screen/ability/mutt/communicate
/obj/screen/ability/mutt/communicate/clicked(params)

	if (!owner.holder || !owner.holder.owner || usr != owner.holder.owner)
		boutput(usr, "<span style=\"color:red\">You do not own this ability.</span>")
		return
	
	if (owner.holder.owner.stat)
		usr << "<span style = \"color: red\"><em>You are incapacitated.</span>"
		return TRUE

	owner.handleCast()