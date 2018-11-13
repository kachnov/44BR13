// Secondary evolution. All castes get it, but only hunters can use it.
/targetable/xenomorph/evolve
	name = "Evolve"

/targetable/xenomorph/evolve/New()
	..()
	var/obj/screen/ability/F = new /obj/screen/ability/xenomorph/evolve(null)
	F.icon = icon
	F.icon_state = icon_state
	F.owner = src
	F.name = name
	F.desc = desc
	object = F
	
/targetable/xenomorph/evolve/cast()
	var/mob/living/carbon/human/xenomorph/X = usr 
	if (!X.attempt_evolution())
		if (X.next_evolution == -1)
			boutput(X, "<span style = \"color:red\">You are at your final evolution already.")
		else
			boutput(X, "<span style = \"color: red\">You must wait <strong>[ceil((X.next_evolution - world.time)/600)]</strong> more minutes to evolve.</span>")
				
/obj/screen/ability/xenomorph/evolve
/obj/screen/ability/xenomorph/evolve/clicked(params)

	if (!owner.holder || !owner.holder.owner || usr != owner.holder.owner)
		boutput(usr, "<span style=\"color:red\">You do not own this ability.</span>")
		return
	
	if (owner.holder.owner.stat)
		usr << "<span style = \"color: red\"><em>You are incapacitated.</span>"
		return TRUE

	owner.handleCast()