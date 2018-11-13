/*
		Oxygen and plasma tank dispenser
*/
/obj/machinery/dispenser
	desc = "A simple yet bulky one-way storage device for gas tanks. Holds 10 plasma and 10 oxygen tanks."
	name = "Tank Storage Unit"
	icon = 'icons/obj/objects.dmi'
	icon_state = "dispenser"
	density = 1
	var/o2tanks = 10.0
	var/pltanks = 10.0
	anchored = 1.0
	mats = 24

/obj/machinery/dispenser/ex_act(severity)
	switch(severity)
		if (1.0)
			//SN src = null
			qdel(src)
			return
		if (2.0)
			if (prob(50))
				//SN src = null
				qdel(src)
				return
		if (3.0)
			if (prob(25))
				while (o2tanks > 0)
					new /obj/item/tank/oxygen( loc )
					o2tanks--
				while (pltanks > 0)
					new /obj/item/tank/plasma( loc )
					pltanks--
		else
	return

/obj/machinery/dispenser/blob_act(var/power)
	if (prob(25 * power / 20))
		while (o2tanks > 0)
			new /obj/item/tank/oxygen( loc )
			o2tanks--
		while (pltanks > 0)
			new /obj/item/tank/plasma( loc )
			pltanks--
		qdel(src)

/obj/machinery/dispenser/meteorhit()
	while (o2tanks > 0)
		new /obj/item/tank/oxygen( loc )
		o2tanks--
	while (pltanks > 0)
		new /obj/item/tank/plasma( loc )
		pltanks--
	qdel(src)
	return

/obj/machinery/dispenser/New()
	..()
	UnsubscribeProcess()

/obj/machinery/dispenser/process()
	return

/obj/machinery/dispenser/attack_ai(mob/user as mob)
	return attack_hand(user)

/obj/machinery/dispenser/attack_hand(mob/user as mob)
	if (stat & BROKEN)
		return
	user.machine = src
	var/dat = text("<TT><strong>Loaded Tank Dispensing Unit</strong><BR><br><FONT color = 'blue'><strong>Oxygen</strong>: []</FONT> []<BR><br><FONT color = 'orange'><strong>Plasma</strong>: []</FONT> []<BR><br></TT>", o2tanks, (o2tanks ? text("<A href='?src=\ref[];oxygen=1'>Dispense</A>", src) : "empty"), pltanks, (pltanks ? text("<A href='?src=\ref[];plasma=1'>Dispense</A>", src) : "empty"))
	user << browse(dat, "window=dispenser")
	onclose(user, "dispenser")
	return

/obj/machinery/dispenser/Topic(href, href_list)
	if (stat & BROKEN)
		return
	if (usr.stat || usr.restrained())
		return
	if (istype(usr, /mob/living/silicon/ai))
		boutput(usr, "<span style=\"color:red\">You are unable to dispense anything, since the controls are physical levers which don't go through any other kind of input.</span>")
		return

	if ((usr.contents.Find(src) || ((get_dist(src, usr) <= 1) && istype(loc, /turf))))
		usr.machine = src
		if (href_list["oxygen"])
			if (text2num(href_list["oxygen"]))
				if (o2tanks > 0)
					use_power(5)
					new /obj/item/tank/oxygen( loc )
					o2tanks--
			if (istype(loc, /mob))
				attack_hand(loc)
		else
			if (href_list["plasma"])
				if (text2num(href_list["plasma"]))
					if (pltanks > 0)
						use_power(5)
						new /obj/item/tank/plasma( loc )
						pltanks--
				if (istype(loc, /mob))
					attack_hand(loc)
		add_fingerprint(usr)
		for (var/mob/M in viewers(1, src))
			if ((M.client && M.machine == src))
				attack_hand(M)
	else
		usr << browse(null, "window=dispenser")
		return
	return

/*
		Disease Dispenser
*/

/*
/obj/machinery/dispenser_disease
	desc = "A machine which you can put test tubes into"
	name = "Chemical Dispensing Unit"
	icon = 'icons/obj/objects.dmi'
	icon_state = "dispenser"
	density = 1
	anchored = 1.0

	var/obj/item/reagent_containers/glass/vial/active_vial = null
	var/obj/item/disk/data/tape/tape = null

	ex_act(severity)
		switch(severity)
			if (1.0)
				//SN src = null
				qdel(src)
				return
			if (2.0)
				if (prob(50))
					//SN src = null
					qdel(src)
					return
			else
		return

	blob_act(var/power)
		if (prob(25))
			qdel(src)

	meteorhit()
		qdel(src)
		return

	New()
		..()
		UnsubscribeProcess()

	process()
		return

	attack_ai(mob/user as mob)
		return attack_hand(user)

	attack_hand(mob/user as mob)
		if (stat & BROKEN)
			return
		user.machine = src

		var/dat = "<TT><strong>Chemical Dispenser Unit</strong><BR><HR><BR>"

		if (tape)
			dat += "Tape Loaded. <A href='?src=\ref[src];etape=1'>Eject</a><br>"
		else
			dat += "<font color=red>No Data Tape Loaded.</font><br>"

		if (active_vial)
			dat += {"Test tube Loaded <A href='?src=\ref[src];eject=1'>(Eject)</A>
					<BR><BR><BR>It contains:<BR>"}

			if (active_vial.reagents.reagent_list.len)
				for (var/current_id in active_vial.reagents.reagent_list)
					var/reagent/current_reagent = active_vial.reagents.reagent_list[current_id]
					dat += "[current_reagent.volume] units of [current_reagent.name]<BR>"
			else
				dat += "Nothing<BR><BR>Pick a disease to dispense to it:<BR>"
				if (tape && tape.root)
					var/count = 0
					for (var/computer/file/disease/D in tape.root.contents)
						count++
						dat += "<BR><A href='?src=\ref[src];disp=\ref[D]'>[D.disease_name]</A>"

					if (!count)
						dat += "<br><font color=red>No VDNA disease profiles on tape!</font><br>"

		else
			dat += "No Test Tube Loaded<BR>"

		user << browse(dat, "window=dis_dispenser")
		onclose(user, "dis_dispenser")
		return

	attackby(obj/item/W, mob/user as mob)
		if (istype(W, /obj/item/reagent_containers/glass/vial))
			if (active_vial)
				boutput(user, "<span style=\"color:blue\">The dispenser already has a test tube in it</span>")
			else
				boutput(user, "<span style=\"color:blue\">You insert the test tube into the dispenser</span>")
				user.drop_vial()
				W.set_loc(src)
				active_vial = W
			updateUsrDialog()
			return

		else if (istype(W, /obj/item/reagent_containers))
			boutput(user, "<span style=\"color:blue\">[W] is too big to fit in!</span>")
			return

		else if (istype(W, /obj/item/disk/data/tape))
			if (!tape)
				user.drop_item()
				W.set_loc(src)
				tape = W
				boutput(user, "You insert [W].")
			else
				boutput(user, "<span style=\"color:red\">There is already a tape loaded!</span>")
			updateUsrDialog()
			return

		..()
		return


	Topic(href, href_list)
		if (stat & BROKEN)
			return
		if (usr.stat || usr.restrained())
			return
		if (istype(usr, /mob/living/silicon/ai))
			boutput(usr, "<span style=\"color:red\">You are unable to dispense anything, since the controls are physical levers which don't go through any other kind of input.</span>")
			return

		if ((usr.contents.Find(src) || ((get_dist(src, usr) <= 1) && istype(loc, /turf))))
			usr.machine = src

			if (href_list["eject"])
				if (active_vial)
					var/log_reagents = ""
					for (var/reagent_id in active_vial.reagents.reagent_list)
						log_reagents += " [reagent_id]"

					logTheThing("combat", usr, null, "ejected a test tube <em>(<strong>Contents:</strong>[log_reagents])</em>)")
					active_vial.set_loc(loc)
					active_vial = null

			if (href_list["etape"])
				if (tape)
					tape.set_loc(loc)
					tape = null

			if (href_list["disp"])
				if (active_vial && tape)
					var/computer/file/disease/D = locate(href_list["disp"])
					if (!istype(D) || D.holder != tape || !D.disease_path)
						return
					// NOOOOOOO
					//var/ailment/disease/new_ailment = new D.disease_path
					//active_vial.contained = new_ailment
					//new_ailment.spread = D.spread
					//new_ailment.cure = D.cure
					//new_ailment.name = D.disease_name
					//new_ailment.stage_prob = D.stage_prob
					//new_ailment.curable = D.curable
					//new_ailment.regress = D.regress
					//new_ailment.vaccine = D.vaccine

					//var/reagent/disease/R = null
					//for (var/A in subtypesof(/reagent/disease))
					//	R = new A()
					//	if (R.id == new_ailment.associated_reagent)
					//		R.Rvaccine = D.vaccine
					//		R.Rcurable = D.curable
					//		R.Rregress = D.regress
					//		R.Rspread = D.spread
					//		R.Rcure = D.cure
					//		R.Rprob = D.stage_prob
					//		break
					//	qdel(R)

					//if (R)
					//	active_vial.reagents.add_reagent_disease(R, 5)
					//	qdel(R)


			add_fingerprint(usr)
			for (var/mob/M in viewers(1, src))
				if ((M.client && M.machine == src))
					attack_hand(M)
		else
			usr << browse(null, "window=dis_dispenser")
			return
		return

*/