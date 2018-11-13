/obj/machinery/computer/genetics/portable
	name = "Port-A-Gene"
	desc = "A mobile scanner and computer in one unit for genetics work."
	icon = 'icons/obj/Cryogenic2.dmi'
	icon_state = "PAG_0"
	anchored = 0
	var/mob/occupant = null
	var/locked = 0

	New()
		..()
		genetics_computers += src
		return

	attackby(obj/item/W as obj, mob/user as mob)
		if (istype(W, /obj/item/screwdriver) && (stat & BROKEN))
			playsound(loc, "sound/items/Screwdriver.ogg", 50, 1)
			if (do_after(user, 20))
				boutput(user, "<span style=\"color:blue\">The broken glass falls out.</span>")
				var/obj/computerframe/A = new /obj/computerframe( loc )
				if (material) A.setMaterial(material)
				new /obj/item/raw_material/shard/glass( loc )
				var/obj/item/circuitboard/genetics/M = new /obj/item/circuitboard/genetics( A )
				for (var/obj/C in src)
					C.set_loc(loc)
				A.circuit = M
				A.state = 3
				A.icon_state = "3"
				A.anchored = 1
				qdel(src)

		else if (istype(W, /obj/item/grab))
			var/obj/item/grab/G = W

			if (occupant)
				boutput(user, "<span style=\"color:red\"><strong>The scanner is already occupied!</strong></span>")
				return

			if (locked)
				boutput(usr, "<span style=\"color:red\"><strong>You need to unlock the scanner first.</strong></span>")
				return

			if (!iscarbon(G.affecting))
				boutput(user, "<span style=\"color:blue\"><strong>The scanner supports only carbon based lifeforms.</strong></span>")
				return

			var/mob/M = G.affecting
			if (user.pulling == M)
				user.pulling = null
			go_in(M)

			for (var/obj/O in src)
				O.set_loc(loc)

			add_fingerprint(user)
			qdel(G)
			return
		else
			attack_hand(user)
		return

	power_change()
		return

	verb/eject()
		set name = "Eject Occupant"
		set src in oview(1)
		set category = "Local"

		if (usr.stat != 0)
			return
		if (locked)
			boutput(usr, "<span style=\"color:red\"><strong>The scanner door is locked!</strong></span>")
			return

		go_out()
		add_fingerprint(usr)
		return

	verb/enter()
		set name = "Enter"
		set src in oview(1)
		set category = "Local"

		if (usr.stat != 0)
			return
		if (locked)
			boutput(usr, "<span style=\"color:red\"><strong>The scanner door is locked!</strong></span>")
			return
		if (occupant)
			boutput(usr, "<span style=\"color:red\">It's already occupied.</span>")
			return

		go_in(usr)
		add_fingerprint(usr)
		return

	verb/lock()
		set name = "Scanner Lock"
		set src in oview(1)
		set category = "Local"

		if (usr.stat != 0)
			return
		if (usr == occupant)
			boutput(usr, "<span style=\"color:red\"><strong>You can't reach the scanner lock from the inside.</strong></span>")
			return

		playsound(loc, "sound/machines/click.ogg", 50, 1)
		if (locked)
			locked = 0
			usr.visible_message("<strong>[usr]</strong> unlocks the scanner.")
			if (occupant)
				boutput(occupant, "<span style=\"color:red\">You hear the scanner's lock slide out of place.</span>")
		else
			locked = 1
			usr.visible_message("<strong>[usr]</strong> locks the scanner.")
			if (occupant)
				boutput(occupant, "<span style=\"color:red\">You hear the scanner's lock click into place.</span>")

	proc/go_out()
		if (!occupant)
			return

		if (locked)
			return

		for (var/obj/O in src)
			O.set_loc(loc)

		occupant.set_loc(loc)
		occupant = null
		icon_state = "PAG_0"
		return

	proc/go_in(var/mob/M)
		if (occupant || !M)
			return

		if (locked)
			return

		M.set_loc(src)
		occupant = M
		icon_state = "PAG_1"
		return

	get_scan_subject()
		if (!src)
			return null
		if (occupant)
			return occupant
		else
			return null

	get_scanner()
		if (!src)
			return null
		return src