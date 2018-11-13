
/obj/health_scanner
	icon = 'icons/obj/device.dmi'
	anchored = 1
	var/reagent_upgrade = 0
	var/reagent_scan = 0
	var/id = 0.0 // who are we?
	var/list/partners = list() // who do we know?
	var/partner_range = 3 // how far away should we look?
	var/find_in_range = 1

	New()
		..()
		spawn (5)
			find_partners(find_in_range)

	attackby(obj/item/W as obj, mob/user as mob)
		if (istype(W, /obj/item/device/multitool))
			var/new_id = input(user, "Please enter new ID", name, id) as null|text
			if (!new_id || new_id == id)
				return
			id = new_id
			boutput(user, "You change [src]'s ID to [new_id].")
			find_partners()
		else if (istype(W, /obj/item/device/healthanalyzer_upgrade))
			update_reagent_scan()
			if (reagent_upgrade)
				boutput(user, "<span style=\"color:red\">This system already has a reagent scan upgrade!</span>")
				return
			else
				reagent_upgrade = 1
				reagent_scan = 1
				update_reagent_scan()
				boutput(user, "<span style=\"color:blue\">Reagent scan upgrade installed.</span>")
				playsound(loc ,"sound/items/Deconstruct.ogg", 80, 0)
				qdel(W)
				return
		else
			return ..()

	proc/find_partners(var/in_range = 0)
		return // dummy proc that the scanner and screen will define themselves

	proc/accept_partner(var/obj/health_scanner/H)
		if (!H)
			return
		if (locate(H) in partners)
			return
		partners += H

	proc/update_reagent_scan()
		if (!partners || !partners.len)
			return
		for (var/obj/health_scanner/myPartner in partners)
			if (reagent_upgrade && !myPartner.reagent_upgrade)
				myPartner.reagent_upgrade = 1
			else if (myPartner.reagent_upgrade && !reagent_upgrade)
				reagent_upgrade = 1
			if (reagent_scan && !myPartner.reagent_scan)
				myPartner.reagent_scan = 1
			else if (myPartner.reagent_scan && !reagent_scan)
				reagent_scan = 1

/obj/health_scanner/wall
	name = "health status screen"
	desc = "A screen that shows health information recieved from connected floor scanners."
	icon_state = "wallscan1"

	find_partners(var/in_range = 0)
		partners = list()
		if (in_range)
			for (var/obj/health_scanner/floor/possible_partner in orange(partner_range, src))
				if (locate(possible_partner) in partners)
					continue
				partners += possible_partner
				possible_partner.accept_partner(src)
		for (var/obj/health_scanner/floor/possible_partner in world)
			if (locate(possible_partner) in partners)
				continue
			if (possible_partner.id == id)
				partners += possible_partner
				possible_partner.accept_partner(src)

	proc/scan()
		if (!partners || !partners.len)
			return "<font color='red'>ERROR: NO CONNECTED SCANNERS</font>"
		var/data = null
		for (var/obj/health_scanner/floor/myPartner in partners)
			for (var/mob/M in get_turf(myPartner))
				data += "<br>[scan_health(M, reagent_scan)]"
		return data

	get_desc(dist)
		if (dist > 2 && !issilicon(usr))
			. += "<br>It's too far away to see what it says.[prob(10) ? " Who decided the text should be <em>that</em> small?!" : null]"
		else
			var/data = scan()
			if (data)
				. += "<br>It says:[data]"
			else
				. += "<br>It says:<br><font color='red'>ERROR: NO SUBJECT(S) DETECTED</font>"

	attack_hand(mob/user as mob)
		return examine()

	attack_ai(mob/user as mob)
		return examine()

/obj/health_scanner/floor
	name = "health scanner"
	desc = "An in-floor health scanner that sends its data to connected status screens."
	icon_state = "floorscan1"

	find_partners(var/in_range = 0)
		partners = list()
		if (in_range)
			for (var/obj/health_scanner/wall/possible_partner in orange(partner_range, src))
				if (locate(possible_partner) in partners)
					continue
				partners += possible_partner
				possible_partner.accept_partner(src)
		for (var/obj/health_scanner/wall/possible_partner in world)
			if (locate(possible_partner) in partners)
				continue
			if (possible_partner.id == id)
				partners += possible_partner
				possible_partner.accept_partner(src)
