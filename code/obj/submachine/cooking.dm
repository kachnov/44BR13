/obj/submachine/chef_sink
	name = "kitchen sink"
	desc = "A water-filled unit intended for cookery purposes."
	icon = 'icons/obj/kitchen.dmi'
	icon_state = "sink"
	anchored = 1
	density = 1
	mats = 12
	flags = NOSPLASH

	attackby(obj/item/W as obj, mob/user as mob)
		if (istype(W, /obj/item/reagent_containers/food/snacks/ingredient/flour))
			user.show_text("You add water to the flour to make dough!", "blue")
			new /obj/item/reagent_containers/food/snacks/ingredient/dough(loc)
			qdel (W)
		else if (istype(W, /obj/item/reagent_containers/glass/) || istype(W, /obj/item/reagent_containers/food/drinks/) || istype(W, /obj/item/reagent_containers/balloon))
			var/fill = W.reagents.maximum_volume
			if (fill == W.reagents.total_volume)
				user.show_text("[W] is too full already.", "red")
			else
				fill -= W.reagents.total_volume
				W.reagents.add_reagent("water", fill)
				user.show_text("You fill [W] with water.", "blue")
				playsound(loc, "sound/misc/pourdrink.ogg", 100, 1)
		else if (istype(W, /obj/item/mop)) // dude whatever
			var/fill = W.reagents.maximum_volume
			if (fill == W.reagents.total_volume)
				user.show_text("[W] is too wet already.", "red")
			else
				fill -= W.reagents.total_volume
				W.reagents.add_reagent("water", fill)
				user.show_text("You wet [W].", "blue")
				playsound(loc, "sound/effects/slosh.ogg", 100, 1)
		else
			user.visible_message("<span style=\"color:blue\">[user] cleans [W].</span>")
			W.clean_forensic() // There's a global proc for this stuff now (Convair880).
			if (istype(W, /obj/item/device/key/skull))
				W.icon_state = "skull"
			if (W.reagents)
				W.reagents.clear_reagents()		// avoid null error

	attack_hand(var/mob/user as mob)
		if (ishuman(user))
			var/mob/living/carbon/human/H = user
			playsound(loc, "sound/effects/slosh.ogg", 100, 1)
			if (H.gloves)
				user.visible_message("<span style=\"color:blue\">[user] cleans [his_or_her(user)] gloves.</span>")
				H.gloves.clean_forensic() // Ditto (Convair880).
				H.set_clothing_icon_dirty()
			else
				user.visible_message("<span style=\"color:blue\">[user] washes [his_or_her(user)] hands.</span>")
				if (H.sims)
					H.sims.affectMotive("hygiene", 2)
				H.blood_DNA = null // Don't want to use it here, though. The sink isn't a shower (Convair880).
				H.blood_type = null
				H.set_clothing_icon_dirty()
		..()

/obj/submachine/ice_cream_dispenser
	name = "Ice Cream Dispenser"
	desc = "A machine designed to dispense space ice cream."
	icon = 'icons/obj/kitchen.dmi'
	icon_state = "ice_creamer0"
	anchored = 1
	density = 1
	mats = 18
	flags = NOSPLASH
	var/list/flavors = list("chocolate","vanilla","coffee")
	var/obj/item/reagent_containers/glass/beaker = null
	var/obj/item/reagent_containers/food/snacks/ice_cream_cone/cone = null
	var/doing_a_thing = 0

	attack_hand(var/mob/user as mob)
		user.machine = src
		var/dat = "<strong>Ice Cream-O-Mat 9900</strong><br>"
		if (cone)
			dat += "<a href='?src=\ref[src];eject=cone'>Eject Cone</a><br>"
			dat += "<strong>Select a Flavor:</strong><br><ul>"
			for (var/flavor in flavors)
				dat += "<li><a href='?src=\ref[src];flavor=[flavor]'>[capitalize(flavor)]</a></li>"
			if (beaker)
				dat += "<li><a href='?src=\ref[src];flavor=beaker'>From Beaker</a></li>"
			dat += "</ul><br>"

		else
			dat += "<strong>No Cone Inserted!</strong><br>"

		if (beaker)
			dat += "<a href='?src=\ref[src];eject=beaker'>Eject Beaker</a><br>"

		user << browse(dat, "window=icecream;size=400x500")
		onclose(user, "icecream")
		return

	Topic(href, href_list)
		if (istype(loc, /turf) && (( get_dist(src, usr) <= 1) || issilicon(usr) ))
			if (!isliving(usr) || iswraith(usr) || isintangible(usr))
				return
			if (usr.stunned > 0 || usr.weakened > 0 || usr.paralysis > 0 || usr.stat != 0 || usr.restrained())
				return

			add_fingerprint(usr)
			usr.machine = src

			if (href_list["eject"])
				switch(href_list["eject"])
					if ("beaker")
						if (beaker)
							beaker.set_loc(loc)
							beaker = null
							update_icon()

					if ("cone")
						if (cone)
							cone.set_loc(loc)
							cone = null
							update_icon()

			else if (href_list["flavor"])
				if (doing_a_thing)
					updateUsrDialog()
					return
				if (!cone)
					boutput(usr, "<span style=\"color:red\">There is no cone loaded!</span>")
					updateUsrDialog()
					return

				var/the_flavor = href_list["flavor"]
				if (the_flavor == "beaker")
					if (!beaker)
						boutput(usr, "<span style=\"color:red\">There is no beaker loaded!</span>")
						updateUsrDialog()
						return

					if (!beaker.reagents.total_volume)
						boutput(usr, "<span style=\"color:red\">The beaker is empty!</span>")
						updateUsrDialog()
						return

					doing_a_thing = 1
					qdel(cone)
					var/obj/item/reagent_containers/food/snacks/ice_cream/newcream = new
					beaker.reagents.trans_to(newcream,40)
					newcream.set_loc(loc)

				else
					if (the_flavor in flavors)
						doing_a_thing = 1
						qdel(cone)
						var/obj/item/reagent_containers/food/snacks/ice_cream/newcream = new
						newcream.reagents.add_reagent(the_flavor,40)
						newcream.set_loc(loc)
					else
						boutput(usr, "<span style=\"color:red\">Unknown flavor!</span>")

				doing_a_thing = 0
				update_icon()

			updateUsrDialog()
		return

	attackby(obj/item/W as obj, mob/user as mob)
		if (istype(W, /obj/item/reagent_containers/food/snacks/ice_cream_cone))
			if (cone)
				boutput(user, "There is already a cone loaded.")
				return
			else
				user.drop_item()
				W.set_loc(src)
				cone = W
				boutput(user, "<span style=\"color:blue\">You load the cone into [src].</span>")

			update_icon()
			updateUsrDialog()

		else if (istype(W, /obj/item/reagent_containers/glass/) || istype(W, /obj/item/reagent_containers/food/drinks))
			if (beaker)
				boutput(user, "There is already a beaker loaded.")
				return
			else
				user.drop_item()
				W.set_loc(src)
				beaker = W
				boutput(user, "<span style=\"color:red\">You load [W] into [src].</span>")

			update_icon()
			updateUsrDialog()
		else ..()

	proc/update_icon()
		if (beaker)
			overlays += image(icon, "ice_creamer_beaker")
		else
			overlays.len = 0

		icon_state = "ice_creamer[cone ? "1" : "0"]"

		return

/// COOKING RECODE ///

var/list/oven_recipes = list()

/obj/submachine/chef_oven
	name = "oven"
	desc = "A multi-cooking unit featuring a hob, grill, oven and more."
	icon = 'icons/obj/kitchen.dmi'
	icon_state = "oven_off"
	anchored = 1
	density = 1
	mats = 18
	flags = NOSPLASH
	var/working = 0
	var/time = 5
	var/heat = "Low"
	var/list/recipes = null
	//var/allowed = list(/obj/item/reagent_containers/food/, /obj/item/parts/robot_parts/head, /obj/item/clothing/head/butt, /obj/item/organ/brain/obj/item)
	var/allowed = list(/obj/item)

	attack_hand(var/mob/user as mob)
		if (!working)
			user.machine = src
			var/dat = {"<strong>Cookomatic Multi-Oven</strong><BR>
			<HR>
			<strong>Contents:</strong><BR>"}
			for (var/obj/item/I in contents)
				dat += "[I]<BR>"
			dat += {"<HR>
			<strong>Time:</strong> [time]<BR>
			<strong>Heat:</strong> [heat]<BR>
			<HR>
			<A href='?src=\ref[src];cook=1'>Cook!</A><BR>
			Time: <A href='?src=\ref[src];time=1'>-</A> <A href='?src=\ref[src];time=2'>+</A><BR>
			Heat: <A href='?src=\ref[src];heat=1'>-</A> <A href='?src=\ref[src];heat=2'>+</A><BR>
			<A href='?src=\ref[src];eject=1'>Eject Contents</A>"}
			user << browse(dat, "window=oven;size=400x500")
			onclose(user, "oven")
		else
			user.machine = src
			var/dat = {"<strong>Cookomatic Multi-Oven</strong><BR>
			<HR><BR>
			Cooking! Please wait!"}
			user << browse(dat, "window=oven;size=400x500")
			onclose(user, "oven")

	New()
	// Note - The order these are placed in matters! Put more complex recipes before simpler ones, or the way the
	//        oven checks through the recipe list will make it pick the simple recipe and finish the cooking proc
	//        before it even gets to the more complex recipe, wasting the ingredients that would have gone to the
	//        more complicated one and pissing off the chef by giving something different than what he wanted!

		recipes = oven_recipes
		if (!recipes)
			recipes = list()

		if (!recipes.len)
			recipes += new /cookingrecipe/omelette_bee(src)
			recipes += new /cookingrecipe/omelette(src)
			recipes += new /cookingrecipe/monster(src)
			recipes += new /cookingrecipe/scarewich_h(src)
			recipes += new /cookingrecipe/scarewich_p_h(src)
			recipes += new /cookingrecipe/scarewich_p(src)
			recipes += new /cookingrecipe/scarewich_s(src)
			recipes += new /cookingrecipe/scarewich_m(src)
			recipes += new /cookingrecipe/scarewich_c(src)
			recipes += new /cookingrecipe/elviswich_m_h(src)
			recipes += new /cookingrecipe/elviswich_m_m(src)
			recipes += new /cookingrecipe/elviswich_m_s(src)
			recipes += new /cookingrecipe/elviswich_c(src)
			recipes += new /cookingrecipe/elviswich_p_h(src)
			recipes += new /cookingrecipe/elviswich_p(src)
			recipes += new /cookingrecipe/sandwich_mb(src)
			//recipes += new /cookingrecipe/sandwich_m_h(src)
			//recipes += new /cookingrecipe/sandwich_m_m(src)
			//recipes += new /cookingrecipe/sandwich_m_s(src)
			//recipes += new /cookingrecipe/sandwich_c(src)
			//recipes += new /cookingrecipe/sandwich_p_h(src)
			//recipes += new /cookingrecipe/sandwich_p(src)
			recipes += new /cookingrecipe/sandwich_custom(src)
			recipes += new /cookingrecipe/ultrachili(src)
			recipes += new /cookingrecipe/baconator(src)
			recipes += new /cookingrecipe/cheeseburger_m(src)
			recipes += new /cookingrecipe/cheeseburger(src)
			recipes += new /cookingrecipe/humanburger(src)
			recipes += new /cookingrecipe/monkeyburger(src)
			recipes += new /cookingrecipe/synthburger(src)
			recipes += new /cookingrecipe/baconburger(src)
			recipes += new /cookingrecipe/mysteryburger(src)
			recipes += new /cookingrecipe/assburger(src)
			recipes += new /cookingrecipe/heartburger(src)
			recipes += new /cookingrecipe/brainburger(src)
			recipes += new /cookingrecipe/fishburger(src)
			recipes += new /cookingrecipe/sloppyjoe(src)
			recipes += new /cookingrecipe/superchili(src)
			recipes += new /cookingrecipe/chili(src)
			recipes += new /cookingrecipe/queso(src)
			recipes += new /cookingrecipe/roburger(src)
			recipes += new /cookingrecipe/swede_mball(src)
			recipes += new /cookingrecipe/donkpocket(src)
			recipes += new /cookingrecipe/donkpocket2(src)
			recipes += new /cookingrecipe/cornbread4(src)
			recipes += new /cookingrecipe/cornbread3(src)
			recipes += new /cookingrecipe/cornbread2(src)
			recipes += new /cookingrecipe/cornbread1(src)
			recipes += new /cookingrecipe/elvis_bread(src)
			recipes += new /cookingrecipe/banana_bread(src)
			recipes += new /cookingrecipe/pumpkin_bread(src)
			recipes += new /cookingrecipe/spooky_bread(src)
			recipes += new /cookingrecipe/banana_bread_alt(src)
			recipes += new /cookingrecipe/honeywheat_bread(src)
			recipes += new /cookingrecipe/eggnog(src)
			recipes += new /cookingrecipe/brain_bread(src)
			recipes += new /cookingrecipe/donut(src)
			recipes += new /cookingrecipe/ice_cream_cone(src)
			recipes += new /cookingrecipe/waffles(src)
			recipes += new /cookingrecipe/spaghetti_m(src)
			recipes += new /cookingrecipe/spaghetti_s(src)
			recipes += new /cookingrecipe/spaghetti_t(src)
			recipes += new /cookingrecipe/spaghetti_p(src)
			recipes += new /cookingrecipe/breakfast(src)
			recipes += new /cookingrecipe/elvischeesetoast(src)
			recipes += new /cookingrecipe/elvisbacontoast(src)
			recipes += new /cookingrecipe/cheesetoast(src)
			recipes += new /cookingrecipe/bacontoast(src)
			/*
			recipes += new /cookingrecipe/pizza_mushpoison(src)
			recipes += new /cookingrecipe/pizza_mushdrug(src)
			recipes += new /cookingrecipe/pizza_mushnorm(src)
			recipes += new /cookingrecipe/pizza_meat(src)
			recipes += new /cookingrecipe/pizza_plain(src)
			*/
			recipes += new /cookingrecipe/nougat(src)
			recipes += new /cookingrecipe/cereal_honey(src)

			recipes += new /cookingrecipe/bakedpotato(src)
			recipes += new /cookingrecipe/pie_apple(src)
			recipes += new /cookingrecipe/pie_lime(src)
			recipes += new /cookingrecipe/pie_lemon(src)
			recipes += new /cookingrecipe/pie_slurry(src)
			recipes += new /cookingrecipe/pie_pumpkin(src)
			recipes += new /cookingrecipe/pie_custard(src)
			recipes += new /cookingrecipe/pie_cream(src)
			recipes += new /cookingrecipe/pie_strawberry(src)
			recipes += new /cookingrecipe/pie_anything(src)
			recipes += new /cookingrecipe/pie_bacon(src)
			recipes += new /cookingrecipe/pie_ass(src)
			recipes += new /cookingrecipe/candy_apple(src)
			recipes += new /cookingrecipe/cake_bacon(src)
			recipes += new /cookingrecipe/cake_downs(src)
			recipes += new /cookingrecipe/cake_meat(src)
			recipes += new /cookingrecipe/cake_chocolate(src)
			recipes += new /cookingrecipe/cake_cream(src)
			recipes += new /cookingrecipe/cake_custom(src)
			recipes += new /cookingrecipe/hotdog(src)
			recipes += new /cookingrecipe/cookie_spooky(src)
			recipes += new /cookingrecipe/cookie_jaffa(src)
			recipes += new /cookingrecipe/cookie_bacon(src)
			recipes += new /cookingrecipe/cookie_oatmeal(src)
			recipes += new /cookingrecipe/cookie_chocolate_chip(src)
			recipes += new /cookingrecipe/cookie_iron(src)
			recipes += new /cookingrecipe/cookie(src)
			recipes += new /cookingrecipe/moon_pie_spooky(src)
			recipes += new /cookingrecipe/moon_pie_jaffa(src)
			recipes += new /cookingrecipe/moon_pie_bacon(src)
			recipes += new /cookingrecipe/moon_pie_chocolate(src)
			recipes += new /cookingrecipe/moon_pie_oatmeal(src)
			recipes += new /cookingrecipe/moon_pie_chips(src)
			recipes += new /cookingrecipe/moon_pie_iron(src)
			recipes += new /cookingrecipe/moon_pie(src)
			recipes += new /cookingrecipe/granola_bar(src)
			// Put all single-ingredient recipes after this point
			recipes += new /cookingrecipe/cake_custom_item(src)
			recipes += new /cookingrecipe/pancake(src)
			recipes += new /cookingrecipe/bread(src)
			recipes += new /cookingrecipe/oatmeal(src)
			recipes += new /cookingrecipe/salad(src)
			recipes += new /cookingrecipe/tomsoup(src)
			recipes += new /cookingrecipe/toast_brain(src)
			recipes += new /cookingrecipe/toast_banana(src)
			recipes += new /cookingrecipe/toast_elvis(src)
			recipes += new /cookingrecipe/toast_spooky(src)
			recipes += new /cookingrecipe/toast(src)
			recipes += new /cookingrecipe/fries(src)
			recipes += new /cookingrecipe/taco_shell(src)
			recipes += new /cookingrecipe/bacon(src)
			recipes += new /cookingrecipe/steak_h(src)
			recipes += new /cookingrecipe/steak_m(src)
			recipes += new /cookingrecipe/steak_s(src)
			recipes += new /cookingrecipe/fish_fingers(src)
			recipes += new /cookingrecipe/meatloaf(src)

	Topic(href, href_list)
		if ((get_dist(src, usr) > 1 && !issilicon(usr)) || !isliving(usr) || iswraith(usr) || isintangible(usr))
			return
		if (usr.stunned > 0 || usr.weakened > 0 || usr.paralysis > 0 || usr.stat != 0 || usr.restrained())
			return
		if (href_list["cook"])
			if (working)
				boutput(usr, "<span style=\"color:red\">It's already working.</span>")
				return
			var/amount = contents.len
			if (!amount)
				boutput(usr, "<span style=\"color:red\">There's nothing in the oven to cook.</span>")
				return
			var/output = null
			var/cook_amt = time
			var/bonus = 0
			var/derivename = 0
			var/recipebonus = 0
			var/recook = 0
			if (heat == "High") cook_amt *= 2
			for (var/cookingrecipe/R in recipes)
				if (R.item1)
					if (!OVEN_checkitem(R.item1, R.amt1)) continue
				if (R.item2)
					if (!OVEN_checkitem(R.item2, R.amt2)) continue
				if (R.item3)
					if (!OVEN_checkitem(R.item3, R.amt3)) continue
				if (R.item4)
					if (!OVEN_checkitem(R.item4, R.amt4)) continue

				output = R.specialOutput(src)
				if (isnull(output))
					output = R.output

				score_meals += 1
				if (R.useshumanmeat) derivename = 1
				recipebonus = R.cookbonus
				if (cook_amt == R.cookbonus) bonus = 1
				else if (cook_amt == R.cookbonus + 1) bonus = 1
				else if (cook_amt == R.cookbonus - 1) bonus = 1
				else if (cook_amt <= R.cookbonus - 5) bonus = -1
				else if (cook_amt >= R.cookbonus + 5)
					output = /obj/item/reagent_containers/food/snacks/yuckburn
					bonus = 0
				break

			if (isnull(output))
				output = /obj/item/reagent_containers/food/snacks/yuck

			if (amount == 1 && output == /obj/item/reagent_containers/food/snacks/yuck)
				for (var/obj/item/reagent_containers/food/snacks/F in src)
					if (F.quality < 1)
						recook = 1
						if (cook_amt == F.quality) F.quality = 1.5
						else if (cook_amt == F.quality + 1) F.quality = 1
						else if (cook_amt == F.quality - 1) F.quality = 1
						else if (cook_amt <= F.quality - 5) F.quality = 0.5
						else if (cook_amt >= F.quality + 5)
							output = /obj/item/reagent_containers/food/snacks/yuckburn
							bonus = 0
			working = 1
			icon_state = "oven_bake"
			updateUsrDialog()
			spawn (cook_amt * 10)

				if (recook && bonus !=0)
					for (var/obj/item/reagent_containers/food/snacks/F in src)
						if (bonus == 1)
							if (F.quality != 1)
								F.quality = 1
						else if (bonus == -1)
							if (F.quality > 0.5)
								F.quality = 0.5
							F.heal_amt = 0
						F.set_loc(loc)
				else
					var/obj/item/reagent_containers/food/snacks/F
					if (ispath(output))
						F = new output(loc)
					else
						F = output
						F.set_loc( get_turf(src) )

					if (bonus == 1)
						F.quality = 5
					else if (bonus == -1)
						F.quality = recipebonus - cook_amt
						F.heal_amt = 0
					if (derivename)
						var/foodname = F.name
						for (var/obj/item/reagent_containers/food/snacks/ingredient/meat/humanmeat/M in contents)
							F.name = "[M.subjectname] [foodname]"
							F.desc += " It sort of smells like [M.subjectjob ? M.subjectjob : "pig"]s."
							if (M.subjectjob && M.subjectjob == "Clown" && isnull(F.unlock_medal_when_eaten))
								F.unlock_medal_when_eaten = "That tasted funny"
				icon_state = "oven_off"
				working = 0
				playsound(loc, "sound/machines/ding.ogg", 50, 1)
				for (var/atom/movable/I in contents)
					qdel(I)
				updateUsrDialog()
				return

		if (href_list["time"])
			if (working)
				boutput(usr, "<span style=\"color:red\">It's already working.</span>")
				return
			var/operation = text2num(href_list["time"])
			if (operation == 1 && time > 1) time -= 1
			if (operation == 2 && time < 10) time += 1
			updateUsrDialog()
			return

		if (href_list["heat"])
			if (working)
				boutput(usr, "<span style=\"color:red\">The dials are locked! THIS IS HOW OVENS WORK OK</span>")
				return
			var/operation = text2num(href_list["heat"])
			if (operation == 1 && heat == "High") heat = "Low"
			if (operation == 2 && heat == "Low") heat = "High"
			updateUsrDialog()
			return

		if (href_list["eject"])
			if (working)
				boutput(usr, "<span style=\"color:red\">Too late! It's already cooking, ejecting the food would ruin everything forever!</span>")
				return
			for (var/obj/item/I in contents)
				I.set_loc(loc)
			updateUsrDialog()
			return

	suicide(var/mob/user as mob)
		user.visible_message("<span style=\"color:red\"><strong>[user] shoves \his head in the oven and turns it on.</strong></span>")
		icon_state = "oven_bake"
		user.TakeDamage("head", 0, 150)
		sleep(50)
		icon_state = "oven_off"
		sleep(50)
		user.suiciding = 0
		return TRUE

	attackby(obj/item/W as obj, mob/user as mob)
		if (working)
			boutput(usr, "<span style=\"color:red\">It's already on! Putting a new thing in could result in a collapse of the cooking waveform into a really lousy eigenstate, like a vending machine chili dog.</span>")
			return
		var/amount = contents.len
		if (amount >= 8)
			boutput(user, "<span style=\"color:red\">The oven cannot hold any more items.</span>")
			return
		var/proceed = 0
		for (var/check_path in allowed)
			if (istype(W, check_path))
				proceed = 1
				break
		if (amount == 1)
			var/cakecount
			for (var/obj/item/reagent_containers/food/snacks/cake/cream/C in contents) cakecount++
			if (cakecount == 1) proceed = 1
		if (!proceed)
			boutput(user, "<span style=\"color:red\">You can't put that in the oven!</span>")
			return
		user.visible_message("<span style=\"color:blue\">[user] loads [W] into the [src].</span>")
		user.u_equip(W)
		W.set_loc(src)
		W.dropped()
		updateUsrDialog()

	proc/OVEN_checkitem(var/recipeitem, var/recipecount)
		if (!locate(recipeitem) in contents) return FALSE
		var/count = 0
		for (var/obj/item/I in contents)
			if (istype(I, recipeitem))
				count++
		if (count < recipecount)
			return FALSE
		return TRUE

/obj/submachine/foodprocessor
	name = "Processor"
	desc = "Refines various food substances into different forms."
	icon = 'icons/obj/kitchen.dmi'
	icon_state = "processor-off"
	anchored = 1
	density = 1
	mats = 18
	var/working = 0
	var/allowed = list(/obj/item/reagent_containers/food/, /obj/item/plant/, /obj/item/organ/brain, /obj/item/clothing/head/butt)

	attack_hand(var/mob/user as mob)
		if (contents.len < 1)
			boutput(user, "<span style=\"color:red\">There is nothing in the processor!</span>")
			return
		if (working == 1)
			boutput(user, "<span style=\"color:red\">The processor is busy!</span>")
			return
		icon_state = "processor-on"
		working = 1
		visible_message("The [src] begins processing its contents.")
		sleep(rand(30,70))
		// Dispense processed stuff
		for (var/obj/item/P in contents)
			switch( P.type )
				if (/obj/item/reagent_containers/food/snacks/ingredient/meat/humanmeat)
					var/obj/item/reagent_containers/food/snacks/meatball/F = new(loc)
					F.name = P:subjectname + " meatball"
					F.desc = "Meaty balls taken from the station's finest [P:subjectjob]."
					qdel( P )
				if (/obj/item/reagent_containers/food/snacks/ingredient/meat/monkeymeat)
					var/obj/item/reagent_containers/food/snacks/meatball/F = new(loc)
					F.name = "monkey meatball"
					F.desc = "Welcome to Space Station 13, where you too can eat a rhesus macaque's balls."
					qdel( P )
				if (/obj/item/organ/brain)
					var/obj/item/reagent_containers/food/snacks/meatball/F = new(loc)
					F.name = "brain meatball"
					F.desc = "Oh jesus, brain meatballs? That's just nasty."
					qdel( P )
				if (/obj/item/clothing/head/butt)
					var/obj/item/reagent_containers/food/snacks/meatball/F = new(loc)
					F.name = "buttball"
					F.desc = "The best you can hope for is that the meat was lean..."
					qdel( P )
				if (/obj/item/reagent_containers/food/snacks/ingredient/meat/synthmeat)
					var/obj/item/reagent_containers/food/snacks/meatball/F = new(loc)
					F.name = "synthetic meatball"
					F.desc = "Let's be honest, this is probably as good as these things are going to get."
					qdel( P )
				if (/obj/item/reagent_containers/food/snacks/ingredient/meat/mysterymeat)
					var/obj/item/reagent_containers/food/snacks/meatball/F = new(loc)
					F.name = "mystery meatball"
					F.desc = "A meatball of even more dubious quality than usual."
					qdel( P )
				if (/obj/item/plant/wheat/metal)
					new/obj/item/reagent_containers/food/snacks/condiment/ironfilings/(loc)
					qdel( P )
				if (/obj/item/plant/wheat)
					new/obj/item/reagent_containers/food/snacks/ingredient/flour/(loc)
					qdel( P )
				if (/obj/item/reagent_containers/food/snacks/plant/tomato)
					new/obj/item/reagent_containers/food/snacks/condiment/ketchup(loc)
					qdel( P )
				if (/obj/item/reagent_containers/food/snacks/plant/peanuts)
					new/obj/item/reagent_containers/food/snacks/ingredient/peanutbutter(loc)
					qdel( P )
				if (/obj/item/reagent_containers/food/snacks/ingredient/egg)
					new/obj/item/reagent_containers/food/snacks/condiment/mayo(loc)
					qdel( P )
				if (/obj/item/reagent_containers/food/snacks/plant/chili/chilly)
					var/plantgenes/DNA = P:plantgenes
					var/obj/item/reagent_containers/food/snacks/condiment/coldsauce/F = new(loc)
					F.reagents.add_reagent("cryostylane", DNA.potency)
					qdel( P )
				if (/obj/item/reagent_containers/food/snacks/plant/chili/ghost_chili)
					var/plantgenes/DNA = P:plantgenes
					var/obj/item/reagent_containers/food/snacks/condiment/hotsauce/ghostchilisauce/F = new(loc)
					F.reagents.add_reagent("ghostchilijuice", 5 + DNA.potency)
					qdel( P )
				if (/obj/item/reagent_containers/food/snacks/plant/chili)
					var/plantgenes/DNA = P:plantgenes
					var/obj/item/reagent_containers/food/snacks/condiment/hotsauce/F = new(loc)
					F.reagents.add_reagent("capsaicin", DNA.potency)
					qdel( P )
				if (/obj/item/plant/sugar)
					var/obj/item/reagent_containers/food/snacks/ingredient/sugar/F = new(loc)
					F.reagents.add_reagent("sugar", 20)
					qdel( P )
				if (/obj/item/reagent_containers/food/drinks/milk)
					new/obj/item/reagent_containers/food/snacks/condiment/cream(loc)
					qdel( P )
				if (/obj/item/reagent_containers/food/drinks/milk/soy)
					new/obj/item/reagent_containers/food/snacks/condiment/cream(loc)
					qdel( P )
				if (/obj/item/reagent_containers/food/drinks/milk/rancid)
					new/obj/item/reagent_containers/food/snacks/yoghurt(loc)
					qdel( P )
				if (/obj/item/reagent_containers/food/snacks/candy)
					new/obj/item/reagent_containers/food/snacks/condiment/chocchips(loc)
					qdel( P )
				if (/obj/item/reagent_containers/food/snacks/plant/corn)
					new/obj/item/reagent_containers/food/snacks/popcorn(loc)
					qdel( P )
				if (/obj/item/reagent_containers/food/snacks/plant/avocado)
					new/obj/item/reagent_containers/food/snacks/soup/guacamole(loc)
					qdel( P )
				if (/obj/item/reagent_containers/food/snacks/plant/soy)
					new/obj/item/reagent_containers/food/drinks/milk/soy(loc)
					qdel( P )
		// Wind down
		for (var/obj/item/S in contents)
			S.set_loc(get_turf(src))
		working = 0
		icon_state = "processor-off"
		playsound(loc, "sound/machines/ding.ogg", 100, 1)
		return

	attackby(obj/item/W as obj, mob/user as mob)
		if (istype(W, /obj/item/satchel))
			var/obj/item/satchel/S = W
			if (S.contents.len < 1) boutput(usr, "<span style=\"color:red\">There's nothing in the satchel!</span>")
			else
				user.visible_message("<span style=\"color:blue\">[user] loads [S]'s contents into [src]!</span>")
				var/amtload = 0
				for (var/obj/item/reagent_containers/food/F in S.contents)
					F.set_loc(src)
					amtload++
				for (var/obj/item/plant/P in S.contents)
					P.set_loc(src)
					amtload++
				W:satchel_updateicon()
				boutput(user, "<span style=\"color:blue\">[amtload] items loaded from satchel!</span>")
				S.desc = "A leather bag. It holds [S.contents.len]/[S.maxitems] [S.itemstring]."
			return
		else
			var/proceed = 0
			for (var/check_path in allowed)
				if (istype(W, check_path))
					proceed = 1
					break
			if (!proceed)
				boutput(user, "<span style=\"color:red\">You can't put that in the processor!</span>")
				return
			user.visible_message("<span style=\"color:blue\">[user] loads [W] into the [src].</span>")
			user.u_equip(W)
			W.set_loc(src)
			W.dropped()
			return

	MouseDrop(over_object, src_location, over_location)
		..()
		if (get_dist(src, usr) > 1 || !isliving(usr) || iswraith(usr) || isintangible(usr))
			return
		if (usr.stunned > 0 || usr.weakened > 0 || usr.paralysis > 0 || usr.stat != 0 || usr.restrained())
			return
		if (over_object == usr && (in_range(src, usr) || usr.contents.Find(src)))
			for (var/obj/item/P in contents)
				P.set_loc(get_turf(src))
			for (var/mob/O in AIviewers(usr, null))
				O.show_message("<span style=\"color:blue\">[usr] empties the [src].</span>")
			return

	MouseDrop_T(atom/movable/O as mob|obj, mob/user as mob)
		if (get_dist(src, user) > 1 || !isliving(user) || iswraith(user) || isintangible(user))
			return
		if (user.stunned > 0 || user.weakened > 0 || user.paralysis > 0 || user.stat != 0 || user.restrained())
			return

		if (istype(O, /obj/storage))
			if (O:locked)
				boutput(user, "<span style=\"color:red\">You need to unlock it first!</span>")
				return
			user.visible_message("<span style=\"color:blue\">[user] loads [O]'s contents into [src]!</span>")
			var/amtload = 0
			for (var/obj/item/reagent_containers/food/M in O.contents)
				M.set_loc(src)
				amtload++
			for (var/obj/item/plant/P in O.contents)
				P.set_loc(src)
				amtload++
			if (amtload) boutput(user, "<span style=\"color:blue\">[amtload] items of food loaded from [O]!</span>")
			else boutput(user, "<span style=\"color:red\">No food loaded!</span>")
		else if (istype(O, /obj/item/reagent_containers/food/) || istype(O, /obj/item/plant))
			user.visible_message("<span style=\"color:blue\">[user] begins quickly stuffing food into [src]!</span>")
			var/staystill = user.loc
			for (var/obj/item/reagent_containers/food/M in view(1,user))
				M.set_loc(src)
				sleep(3)
				if (user.loc != staystill) break
			for (var/obj/item/plant/P in view(1,user))
				P.set_loc(src)
				sleep(3)
				if (user.loc != staystill) break
			boutput(user, "<span style=\"color:blue\">You finish stuffing food into [src]!</span>")
		else ..()
		updateUsrDialog()

var/list/mixer_recipes = list()

/obj/submachine/mixer
	name = "KitchenHelper"
	desc = "A food Mixer."
	icon = 'icons/obj/kitchen.dmi'
	icon_state = "blender"
	density = 1
	anchored = 1
	mats = 15
	var/list/recipes = null
	var/list/to_remove = list()
	var/allowed = list(/obj/item/reagent_containers/food/, /obj/item/parts/robot_parts/head, /obj/item/clothing/head/butt, /obj/item/organ/brain)
	var/working = 0

	New()
		recipes = mixer_recipes
		if (!recipes)
			recipes = list()

		if (!recipes.len)
			recipes += new /cookingrecipe/mix_cake_custom(src)
			recipes += new /cookingrecipe/pancake_batter(src)
			recipes += new /cookingrecipe/cake_batter(src)
			recipes += new /cookingrecipe/custard(src)
			recipes += new /cookingrecipe/creamofmushroom/amanita(src)
			recipes += new /cookingrecipe/creamofmushroom/psilocybin(src)
			recipes += new /cookingrecipe/creamofmushroom(src)
			recipes += new /cookingrecipe/mashedpotatoes(src)
			recipes += new /cookingrecipe/mashedbrains(src)
			recipes += new /cookingrecipe/gruel(src)
			recipes += new /cookingrecipe/meatpaste(src)
			recipes += new /cookingrecipe/wonton_wrapper(src)

		update_icon()
		return

	attackby(obj/item/W as obj, mob/user as mob)
		var/amount = contents.len
		if (amount >= 4)
			boutput(user, "<span style=\"color:red\">The mixer is full.</span>")
			return
		var/proceed = 0
		for (var/check_path in allowed)
			if (istype(W, check_path))
				proceed = 1
				break
		if (!proceed)
			boutput(user, "<span style=\"color:red\">You can't put that in the mixer!</span>")
			return
		user.visible_message("<span style=\"color:blue\">[user] puts [W] into the [src].</span>")
		user.u_equip(W)
		W.set_loc(src)
		W.dropped()

	attack_hand(var/mob/user as mob)
		if (!working)
			user.machine = src
			var/dat = {"<strong>KitchenHelper Mixer</strong><BR>
			<HR>
			<strong>Contents:</strong><BR>"}
			for (var/obj/item/I in contents)
				dat += "[I]<BR>"
			dat += {"<HR>
			<A href='?src=\ref[src];mix=1'>Mix!</A><BR>
			<A href='?src=\ref[src];eject=1'>Eject Contents</A>"}
			user << browse(dat, "window=mixer;size=400x500")
			onclose(user, "mixer")
		else
			user.machine = src
			var/dat = {"<strong>KitchenHelper Mixer</strong><BR>
			<HR><BR>
			Mixing! Please wait!"}
			user << browse(dat, "window=mixer;size=400x500")
			onclose(user, "mixer")

	Topic(href, href_list)
		if ((get_dist(src, usr) > 1 && !issilicon(usr)) || !isliving(usr) || iswraith(usr) || isintangible(usr))
			return
		if (usr.stunned > 0 || usr.weakened > 0 || usr.paralysis > 0 || usr.stat != 0 || usr.restrained())
			return

		if (href_list["mix"])
			if (working)
				boutput(usr, "<span style=\"color:red\">It's already working.</span>")
				return
			mix()
		if (href_list["eject"])
			for (var/obj/item/I in contents)
				I.set_loc(loc)
			updateUsrDialog()
			return

	proc/bowl_checkitem(var/recipeitem, var/recipecount)
		if (!locate(recipeitem) in contents) return FALSE
		var/count = 0
		for (var/obj/item/I in contents)
			if (istype(I, recipeitem))
				count++
				to_remove += I

		if (count < recipecount)
			return FALSE
		return TRUE

	proc/mix()
		var/amount = contents.len
		if (!amount)
			boutput(usr, "<span style=\"color:red\">There's nothing in the mixer.</span>")
			return
		working = 1
		update_icon()
		updateUsrDialog()
		playsound(loc, "sound/machines/mixer.ogg", 50, 1)
		var/output = null // /obj/item/reagent_containers/food/snacks/yuck
		var/derivename = 0
		for (var/cookingrecipe/R in recipes)
			to_remove.len = 0
			if (R.item1)
				if (!bowl_checkitem(R.item1, R.amt1)) continue
			if (R.item2)
				if (!bowl_checkitem(R.item2, R.amt2)) continue
			if (R.item3)
				if (!bowl_checkitem(R.item3, R.amt3)) continue
			if (R.item4)
				if (!bowl_checkitem(R.item4, R.amt4)) continue
			output = R.specialOutput(src)
			if (!output)
				output = R.output
			score_meals += 1
			if (R.useshumanmeat)
				derivename = 1
			break
		spawn (20)

			if (!isnull(output))
				var/obj/item/reagent_containers/food/snacks/F
				if (ispath(output))
					F = new output(get_turf(src))
				else
					F = output
					F.set_loc(get_turf(src))

				if (derivename)
					var/foodname = F.name
					for (var/obj/item/reagent_containers/food/snacks/ingredient/meat/humanmeat/M in contents)
						F.name = "[M.subjectname] [foodname]"
						F.desc += " It sort of smells like [M.subjectjob ? M.subjectjob : "pig"]s."
						if (M.subjectjob && M.subjectjob == "Clown" && isnull(F.unlock_medal_when_eaten))
							F.unlock_medal_when_eaten = "That tasted funny"
				for (var/obj/item/I in to_remove)
					qdel(I)

			for (var/obj/I in contents)
				I.set_loc(loc)
				visible_message("<span style=\"color:red\">[I] is tossed out of [src]!</span>")
				var/edge = get_edge_target_turf(src, pick(alldirs))
				I.throw_at(edge, 25, 4)

			working = 0
			update_icon()
			updateUsrDialog()
			return

	proc/update_icon()
		if (!src || !istype(src))
			return

		if (working != 0)
			icon_state = "blender_on"
		else
			icon_state = "blender"

		return