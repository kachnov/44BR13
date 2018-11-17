/targetable/facehugger/leap
	name = "Leap"
	cooldown = 0.5 SECONDS

/targetable/facehugger/leap/New()
	..()
	var/obj/screen/ability/F = new /obj/screen/ability/facehugger/leap(null)
	F.icon = icon
	F.icon_state = icon_state
	F.owner = src
	F.name = name
	F.desc = desc
	object = F
	
/targetable/facehugger/leap/cast()
	var/mob/living/critter/facehugger/facehugger = usr
	var/list/possible_targets = orange_types(1, facehugger, /mob/living)
	
	// first, try to attack someone in our direction
	for (var/living in possible_targets)
		var/mob/living/L = living 
		if (L in get_step(facehugger, facehugger.dir))
			facehugger.hand_attack(L)
			return
			
	// second, turn towards anyone in our direction and attack them
	for (var/living in possible_targets)
		var/mob/living/L = living 
		facehugger.face(L)
		facehugger.hand_attack(L)
		return

/obj/screen/ability/facehugger/leap
/obj/screen/ability/facehugger/leap/clicked(params)

	if (!owner.holder || !owner.holder.owner || usr != owner.holder.owner)
		boutput(usr, "<span style=\"color:red\">You do not own this ability.</span>")
		return FALSE
	
	if (owner.holder.owner.stat)
		usr << "<span style = \"color: red\"><em>You are incapacitated.</span>"
		return FALSE
		
	// we're probably already in a mob
	if (!isturf(owner.holder.owner.loc))
		return FALSE
		
	owner.handleCast()