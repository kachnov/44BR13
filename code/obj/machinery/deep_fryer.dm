/obj/machinery/deep_fryer
	name = "Deep Fryer"
	desc = "An industrial deep fryer.  A big hit at state fairs!"
	icon = 'icons/obj/kitchen.dmi'
	icon_state = "fryer0"
	anchored = 1
	density = 1
	flags = NOSPLASH
	mats = 20
	var/obj/item/fryitem = null
	var/cooktime = 0
	var/frytemp = 185 + T0C //365 F is a good frying temp, right?
	var/max_wclass = 3

	New()
		..()
		UnsubscribeProcess()
		var/reagents/R = new/reagents(50)
		reagents = R
		R.my_atom = src

		R.add_reagent("grease", 25)
		R.set_reagent_temp(frytemp)

	attackby(obj/item/W as obj, mob/user as mob)
		if (fryitem)
			boutput(user, "<span style=\"color:red\">There is already something in the fryer!</span>")
			return
		if (istype(W, /obj/item/reagent_containers/food/snacks/fry_holder))
			boutput(user, "<span style=\"color:red\">Your cooking skills are not up to the legendary Doublefry technique.</span>")
			return

		else if (istype(W, /obj/item/reagent_containers/glass/) || istype(W, /obj/item/reagent_containers/food/drinks))
			if (!W.reagents.total_volume)
				boutput(user, "<span style=\"color:red\">There is nothing in [W] to pour!</span>")

			else
				logTheThing("combat", user, null, "pours chemicals [log_reagents(W)] into the [src] at [log_loc(src)].") // Logging for the deep fryer (Convair880).
				visible_message("<span style=\"color:blue\">[user] pours [W:amount_per_transfer_from_this] units of [W]'s contents into [src].</span>")
				playsound(loc, "sound/effects/slosh.ogg", 100, 1)
				W.reagents.trans_to(src, W:amount_per_transfer_from_this)
				if (!W.reagents.total_volume) boutput(user, "<span style=\"color:red\"><strong>[W] is now empty.</strong></span>")

			return

		else if (istype(W, /obj/item/grab))
			if (!W:affecting) return
			visible_message("<span style=\"color:red\"><strong>[user] is trying to shove [W:affecting] into [src]!</strong></span>")
			if (!do_mob(user, W:affecting) || !W)
				return

			if (ismonkey(W:affecting))
				logTheThing("combat", user, W:affecting, "shoves %target% into the [src] at [log_loc(src)].") // For player monkeys (Convair880).
				visible_message("<span style=\"color:red\"><strong>[user] shoves [W:affecting] into [src]!</strong></span>")
				icon_state = "fryer1"
				cooktime = 0
				fryitem = W:affecting
				SubscribeToProcess()
				W:affecting.set_loc(src)
				W:affecting.death( 0 )
				qdel(W)
				return

			logTheThing("combat", user, W:affecting, "shoves %target%'s face into the [src] at [log_loc(src)].")
			visible_message("<span style=\"color:red\"><strong>[user] shoves [W:affecting]'s face into [src]!</strong></span>")
			reagents.reaction(W:affecting, TOUCH)

			return

		if (W.w_class > max_wclass || istype(W, /obj/item/storage) || istype(W, /obj/item/storage/secure))
			boutput(user, "<span style=\"color:red\">There is no way that could fit!</span>")
			return

		visible_message("<span style=\"color:blue\">[user] loads [W] into the [src].</span>")
		user.u_equip(W)
		W.set_loc(src)
		W.dropped()
		cooktime = 0
		fryitem = W
		icon_state = "fryer1"
		SubscribeToProcess()
		return

	onVarChanged(variable, oldval, newval)
		if (variable == "fryitem")
			if (!oldval && newval)
				SubscribeToProcess()
			else if (oldval && !newval)
				UnsubscribeProcess()

	attack_hand(mob/user as mob)
		if (!fryitem)
			boutput(user, "<span style=\"color:red\">There is nothing in the fryer.</span>")
			return

		if (cooktime < 5)
			boutput(user, "<span style=\"color:red\">Frying things takes time! Be patient!</span>")
			return

		user.visible_message("<span style=\"color:blue\">[user] removes [fryitem] from [src]!</span>", "<span style=\"color:blue\">You remove [fryitem] from [src].</span>")
		eject_food()
		return

	process()
		if (stat & BROKEN)
			UnsubscribeProcess()
			return

		if (!reagents.has_reagent("grease"))
			reagents.add_reagent("grease", 25)

		reagents.set_reagent_temp(frytemp) // I'd love to have some thermostat logic here to make it heat up / cool down slowly but aaaaAAAAAAAAAAAAA (exposing it to the frytemp is too slow)

		if (!fryitem)
			UnsubscribeProcess()
			return

		if (!fryitem.reagents)
			var/reagents/R = new/reagents(50)
			fryitem.reagents = R
			R.my_atom = fryitem


		reagents.trans_to(fryitem, 2)

		if (cooktime < 60)
			cooktime++
			if (cooktime == 30)
				playsound(loc, "sound/machines/ding.ogg", 50, 1)
				visible_message("<span style=\"color:blue\">[src] dings!</span>")
			else if (cooktime == 60) //Welp!
				visible_message("<span style=\"color:red\">[src] emits an acrid smell!</span>")
		else if (cooktime >= 120)
			cooktime++
			if ((cooktime % 5) == 0)
				visible_message("<span style=\"color:red\">[src] sprays burning oil all around it!</span>")
				fireflash(src, 5)

		return

	suicide(var/mob/usr as mob)
		if (fryitem)
			return FALSE
		usr.visible_message("<span style=\"color:red\"><strong>[usr] climbs into the deep fryer! How is that even possible?!</strong></span>")

		usr.set_loc(src)
		cooktime = 0
		fryitem = usr
		icon_state = "fryer1"
		usr.TakeDamage("head", 0, 175)
		usr.updatehealth()
		SubscribeToProcess()
		spawn (100)
			usr.suiciding = 0
		return TRUE

	proc/eject_food()
		if (!fryitem)
			UnsubscribeProcess()
			return

		var/obj/item/reagent_containers/food/snacks/fry_holder/fryholder = new /obj/item/reagent_containers/food/snacks/fry_holder(src)

		if (cooktime >= 60)
			if (istype(fryitem, /mob))
				var/mob/M = fryitem
				M.ghostize()
			else
				for (var/mob/M in fryitem)
					M.ghostize()
			qdel(fryitem)
			fryitem = new /obj/item/reagent_containers/food/snacks/yuckburn (src)
			if (!fryitem.reagents)
				var/reagents/R = new/reagents(50)
				fryitem.reagents = R
				R.my_atom = fryitem

			fryitem.reagents.add_reagent("grease", 50)
			fryholder.desc = "A heavily fried...something.  Who can tell anymore?"

		var/icon/composite = new(fryitem.icon, fryitem.icon_state)//, fryitem.dir, 1)
		for (var/O in fryitem.underlays + fryitem.overlays)
			var/image/I = O
			composite.Blend(icon(I.icon, I.icon_state, I.dir, 1), ICON_OVERLAY)

		switch(cooktime)
			if (0 to 15)
				fryholder.name = "lightly-fried [fryitem.name]"
				fryholder.color = ( rgb(166,103,54) )


			if (16 to 49)
				fryholder.name = "fried [fryitem.name]"
				fryholder.color = ( rgb(103,63,24) )

			if (50 to 59)
				fryholder.name = "deep-fried [fryitem.name]"
				fryholder.color = ( rgb(63, 23, 4) )

			else
				fryholder.color = ( rgb(33,19,9) )

		fryholder.icon = composite
		fryholder.overlays = fryitem.overlays
		fryholder.set_loc(get_turf(src))
		if (istype(fryitem, /mob))
			fryholder.amount = 5
		else
			fryholder.amount = fryitem.w_class
		fryholder.reagents = fryitem.reagents
		fryholder.reagents.my_atom = fryholder

		fryitem.set_loc(fryholder)

		fryitem = null
		icon_state = "fryer0"
		for (var/obj/item/I in src) //Things can get dropped somehow sometimes ok
			I.set_loc(loc)

		UnsubscribeProcess()
		return

	verb/drain()
		set src in oview(1)
		set name = "Drain Oil"
		set desc = "Drain and replenish fryer oils."
		set category = "Local"

		if (reagents)
			if (isobserver(usr) || isintangible(usr)) // Ghosts probably shouldn't be able to take revenge on a traitor chef or whatever (Convair880).
				return
			else
				src.reagents.clear_reagents()
				visible_message("<span style=\"color:red\">[usr] drains and refreshes the frying oil!</span>")

		return