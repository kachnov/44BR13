#define BUILDING_REQUIRES_RESIN FALSE
// Use in-hand resin to build a wall, membrane, or cocoon. Only usable by Drones.
/targetable/xenomorph/build_resin_structure
	name = "Build Resin Structure"
	#if BUILDING_REQUIRES_RESIN
	cooldown = 0 SECONDS
	#else
	cooldown = 2 SECONDS
	#endif

/targetable/xenomorph/build_resin_structure/New()
	..()
	var/obj/screen/ability/F = new /obj/screen/ability/xenomorph/build_resin_structure(null)
	F.icon = icon
	F.icon_state = icon_state
	F.owner = src
	F.name = name
	F.desc = desc
	object = F
	
/targetable/xenomorph/build_resin_structure/cast()
	var/obj/item/resin/R = usr.equipped()
	var/bypass = !BUILDING_REQUIRES_RESIN

	if (bypass || (R && istype(R)))
		if (bypass || R.can_consume(1))
			#define WALL "Wall"
			#define MEMBRANE "Membrane"
			#define COCOON "Cocoon"
			#define NEST "Nest"
			var/structure = input(usr, "What do you want to build?") as null|anything in list(WALL, MEMBRANE, NEST)
			if (structure)
				switch (structure)
					if (WALL)
						new /obj/xeno/wall(get_turf(usr))
					if (MEMBRANE)
						new /obj/xeno/wall/membrane(get_turf(usr))
					if (COCOON)
						new /obj/xeno/cocoon(get_turf(usr))
					if (NEST)
						new /obj/xeno/nest(get_turf(usr))
				R.consume(1)
				usr.visible_message("<span style = \"color: green\"><strong>[usr]</strong> builds a resin [structure].</span>")
			#undef NEST
			#undef WALL 
			#undef MEMBRANE 
			#undef COCOON
		else 
			boutput(usr, "<span style = \"color: red\">You don't have enough resin to build anything.</span>")
	else 
		boutput(usr, "<span style = \"color: red\">You need resin in your active hand to build.</span>")
				
/obj/screen/ability/xenomorph/build_resin_structure
/obj/screen/ability/xenomorph/build_resin_structure/clicked(params)

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
#undef BUILDING_REQUIRES_RESIN