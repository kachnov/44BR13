// Use in-hand resin to craft various items. Only usable by Crafters, obviously.
/targetable/xenomorph/craft
	name = "Craft Resin Item"
	var/static/list/items = list()

/targetable/xenomorph/craft/New()
	..()
	var/obj/screen/ability/F = new /obj/screen/ability/xenomorph/craft(null)
	F.icon = icon
	F.icon_state = icon_state
	F.owner = src
	F.name = name
	F.desc = desc
	object = F
	
/targetable/xenomorph/craft/cast()
	var/obj/item/resin/R = usr.equipped()
	if (R && istype(R))
		if (R.can_consume(1))
			if (!items.len)
				items["Resin Revolver"] = /obj/item/gun/kinetic/revolver 
				items["Resin Derringer"] = /obj/item/gun/kinetic/derringer
				items["Resin Riot Gun"] = /obj/item/gun/kinetic/riotgun
				items["Resin AK47"] = /obj/item/gun/kinetic/ak47
				items["Resin Hunting Rifle"] = /obj/item/gun/kinetic/hunting_rifle
				items["Resin Silenced 22"] = /obj/item/gun/kinetic/silenced_22
				items["Resin Riot Launcher"] = /obj/item/gun/kinetic/riot40mm
				items["Resin Russian Revolver"] = /obj/item/gun/russianrevolver
			var/buildname = input(usr, "What do you want to build?") as null|anything in items
			if (buildname)
				var/buildpath = items[buildname]
				var/obj/item/I = new buildpath(default_value(get_step(usr, usr.dir), get_turf(usr)))
				I.resinize()
				R.consume(1)
		else 
			boutput(usr, "<span style = \"color: red\">You don't have enough resin to craft anything.</span>")
	else 
		boutput(usr, "<span style = \"color: red\">You need resin in your active hand to build.</span>")
				
/obj/screen/ability/xenomorph/craft
/obj/screen/ability/xenomorph/craft/clicked(params)

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