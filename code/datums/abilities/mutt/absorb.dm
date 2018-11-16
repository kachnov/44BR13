/targetable/mutt/absorb
	name = "Absorb"
	cooldown = 11 SECONDS

/targetable/mutt/absorb/New()
	..()
	var/obj/screen/ability/F = new /obj/screen/ability/mutt/absorb(null)
	F.icon = icon
	F.icon_state = icon_state
	F.owner = src
	F.name = name
	F.desc = desc
	object = F
	
/targetable/mutt/absorb/cast()
	for (var/mob/living/carbon/human/H in get_turf(usr))
		if (isxenomorph(H) || !ismutt(H))
			usr.visible_message("<span style = \"color:#593001\"><big><strong>[usr] starts to absorb [H]...</strong></big></span>")
			if (do_mob(usr, H, cooldown - (1 SECOND)))
				usr.visible_message("<span style = \"color:#593001\"><big><strong>[usr] has absorbed [H]!</strong></big></span>")
				H.gib()
				var/mob/living/carbon/human/mutt/M = usr
				M.upgrade()
			break 

/obj/screen/ability/mutt/absorb
/obj/screen/ability/mutt/absorb/clicked(params)

	if (!owner.holder || !owner.holder.owner || usr != owner.holder.owner)
		boutput(usr, "<span style=\"color:red\">You do not own this ability.</span>")
		return
	
	if (owner.holder.owner.stat)
		usr << "<span style = \"color: red\"><em>You are incapacitated.</span>"
		return TRUE

	owner.handleCast()