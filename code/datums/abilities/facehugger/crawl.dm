/targetable/facehugger/crawl
	name = "Crawl"
	cooldown = 7

/targetable/facehugger/crawl/New()
	..()
	var/obj/screen/ability/F = new /obj/screen/ability/facehugger/crawl(null)
	F.icon = icon
	F.icon_state = icon_state
	F.owner = src
	F.name = name
	F.desc = desc
	object = F
	
/targetable/facehugger/crawl/cast()
	// find where to move
	var/turf/target = get_step(usr, usr.dir)
	if (!target || !find_dense_type(target, /atom/movable) || target.density)
		return FALSE
	else if (target)
		for (var/atom in target)
			var/atom/movable/A = atom 
			if (!isdoor(A) && !A.CanPass(src, target))
				return FALSE
	// move then move again if possible
	usr.forceMove(target)
	usr.layer = HIDING_XENO_LAYER
	spawn (3)
		target = get_step(usr, usr.dir)
		if (target && !target.density && !locate(/obj/structure) in target)
			usr.forceMove(target)
		spawn (0.5)
			usr.layer = initial(usr.layer)
	return TRUE

/obj/screen/ability/facehugger/crawl
/obj/screen/ability/facehugger/crawl/clicked(params)

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