/obj/machinery/microwave
	name = "Microwave"
	icon = 'icons/obj/kitchen.dmi'
	desc = "The automatic chef of the future!"
	icon_state = "mw"
	density = 1
	anchored = 1
	var/egg_amount = 0 //Current number of eggs inside
	var/flour_amount = 0 //Current amount of flour inside
	var/water_amount = 0 //Current amount of water inside
	var/monkeymeat_amount = 0
	var/synthmeat_amount = 0
	var/humanmeat_amount = 0
	var/donkpocket_amount = 0
	var/humanmeat_name = ""
	var/humanmeat_job = ""
	var/operating = 0 // Is it on?
	var/dirty = 0 // Does it need cleaning?
	var/broken = 0 // How broken is it???
	var/list/available_recipes = list() // List of the recipes you can use
	var/obj/item/reagent_containers/food/snacks/being_cooked = null // The item being cooked
	var/obj/item/extra_item // One non food item that can be added
	mats = 12

/obj/machinery/microwave/New() // *** After making the recipe in datums\recipes.dm, add it in here! ***
	..()
	available_recipes += new /recipe/donut(src)
	available_recipes += new /recipe/synthburger(src)
	available_recipes += new /recipe/monkeyburger(src)
	available_recipes += new /recipe/humanburger(src)
	available_recipes += new /recipe/waffles(src)
	available_recipes += new /recipe/brainburger(src)
	available_recipes += new /recipe/meatball(src)
	available_recipes += new /recipe/assburger(src)
	available_recipes += new /recipe/roburger(src)
	available_recipes += new /recipe/heartburger(src)
	available_recipes += new /recipe/donkpocket(src)
	available_recipes += new /recipe/donkpocket_warm(src)
	available_recipes += new /recipe/pie(src)
	available_recipes += new /recipe/popcorn(src)


/*******************
*   Item Adding
********************/

/obj/machinery/microwave/attackby(var/obj/item/O as obj, var/mob/user as mob)
	if (broken > 0)
		if (broken == 2 && istype(O, /obj/item/screwdriver)) // If it's broken and they're using a screwdriver
			visible_message("<span style=\"color:blue\">[user] starts to fix part of the microwave.</span>")
			sleep(20)
			visible_message("<span style=\"color:blue\">[user] fixes part of the microwave.</span>")
			broken = 1 // Fix it a bit
		else if (broken == 1 && istype(O, /obj/item/wrench)) // If it's broken and they're doing the wrench
			visible_message("<span style=\"color:blue\">[user] starts to fix part of the microwave.</span>")
			sleep(20)
			visible_message("<span style=\"color:blue\">[user] fixes the microwave!</span>")
			icon_state = "mw"
			broken = 0 // Fix it!
		else
			boutput(user, "It's broken!")
	else if (dirty) // The microwave is all dirty so can't be used!
		if (istype(O, /obj/item/spraybottle)) // If they're trying to clean it then let them
			visible_message("<span style=\"color:blue\">[user] starts to clean the microwave.</span>")
			sleep(20)
			visible_message("<span style=\"color:blue\">[user] has cleaned the microwave!</span>")
			dirty = 0 // It's cleaned!
			icon_state = "mw"
		else //Otherwise bad luck!!
			return
	else if (istype(O, /obj/item/reagent_containers/food/snacks/ingredient/egg)) // If an egg is used, add it
		if (egg_amount < 5)
			visible_message("<span style=\"color:blue\">[user] adds an egg to the microwave.</span>")
			egg_amount++
			qdel(O)
	else if (istype(O, /obj/item/reagent_containers/food/snacks/ingredient/flour)) // If flour is used, add it
		if (flour_amount < 5)
			visible_message("<span style=\"color:blue\">[user] adds some flour to the microwave.</span>")
			flour_amount++
			qdel(O)
	else if (istype(O, /obj/item/reagent_containers/food/snacks/ingredient/meat/monkeymeat))
		if (monkeymeat_amount < 5)
			visible_message("<span style=\"color:blue\">[user] adds some meat to the microwave.</span>")
			monkeymeat_amount++
			qdel(O)
	else if (istype(O, /obj/item/reagent_containers/food/snacks/ingredient/meat/synthmeat))
		if (synthmeat_amount < 5)
			visible_message("<span style=\"color:blue\">[user] adds some meat to the microwave.</span>")
			synthmeat_amount++
			qdel(O)
	else if (istype(O, /obj/item/reagent_containers/food/snacks/ingredient/meat/humanmeat))
		if (humanmeat_amount < 5)
			visible_message("<span style=\"color:blue\">[user] adds some meat to the microwave.</span>")
			humanmeat_name = O:subjectname
			humanmeat_job = O:subjectjob
			humanmeat_amount++
			qdel(O)
	else if (istype(O, /obj/item/reagent_containers/food/snacks/donkpocket_w))
		// Band-aid fix. The microwave code could really use an overhaul (Convair880).
		user.show_text("Syndicate donk pockets don't have to be heated.", "red")
		return
	else if (istype(O, /obj/item/reagent_containers/food/snacks/donkpocket))
		if (donkpocket_amount < 2)
			visible_message("<span style=\"color:blue\">[user] adds a donk-pocket to the microwave.</span>")
			donkpocket_amount++
			qdel(O)
	else
		if (!istype(extra_item, /obj/item)) //Allow one non food item to be added!
			user.u_equip(O)
			extra_item = O
			O.set_loc(src)
			O.dropped(user)
			visible_message("<span style=\"color:blue\">[user] adds [O] to the microwave.</span>")
		else
			boutput(user, "There already seems to be an unusual item inside, so you don't add this one too.") //Let them know it failed for a reason though

/*******************
*   Microwave Menu
********************/

/obj/machinery/microwave/attack_hand(user as mob) // The microwave Menu
	var/dat
	if (broken > 0)
		dat = {"
<TT>Bzzzzttttt</TT>
		"}
	else if (operating)
		dat = {"
<TT>Microwaving in progress!<BR>
Please wait...!</TT><BR>
<BR>
"}
	else if (dirty)
		dat = {"
<TT>This microwave is dirty!<BR>
Please clean it before use!</TT><BR>
<BR>
"}
	else
		dat = {"
<strong>Eggs:</strong>[egg_amount] eggs<BR>
<strong>Flour:</strong>[flour_amount] cups of flour<BR>
<strong>Monkey Meat:</strong>[monkeymeat_amount] slabs of meat<BR>
<strong>Synth-Meat:</strong>[synthmeat_amount] slabs of meat<BR>
<strong>Meat Turnovers:</strong>[donkpocket_amount] turnovers<BR>
<strong>Other Meat:</strong>[humanmeat_amount] slabs of meat<BR><HR>
<BR>
<A href='?src=\ref[src];cook=1'>Turn on!<BR>
<A href='?src=\ref[src];cook=2'>Dispose contents!<BR>
"}

	user << browse("<HEAD><TITLE>Microwave Controls</TITLE></HEAD><TT>[dat]</TT>", "window=microwave")
	onclose(user, "microwave")
	return



/***********************************
*   Microwave Menu Handling/Cooking
************************************/

/obj/machinery/microwave/Topic(href, href_list)
	if (..())
		return

	usr.machine = src
	add_fingerprint(usr)

	if (href_list["cook"])
		if (!operating)
			var/operation = text2num(href_list["cook"])

			var/cook_time = 200 // The time to wait before spawning the item
			var/cooked_item = ""

			if (operation == 1) // If cook was pressed
				visible_message("<span style=\"color:blue\">The microwave turns on.</span>")
				for (var/recipe/R in available_recipes) //Look through the recipe list we made above
					if (egg_amount == R.egg_amount && flour_amount == R.flour_amount && monkeymeat_amount == R.monkeymeat_amount && synthmeat_amount == R.synthmeat_amount && humanmeat_amount == R.humanmeat_amount && donkpocket_amount == R.donkpocket_amount) // Check if it's an accepted recipe
						if (R.extra_item == null || (src.extra_item && src.extra_item.type == R.extra_item)) // Just in case the recipe doesn't have an extra item in it
							egg_amount = 0 // If so remove all the eggs
							flour_amount = 0 // And the flour
							water_amount = 0 //And the water
							monkeymeat_amount = 0
							synthmeat_amount = 0
							humanmeat_amount = 0
							donkpocket_amount = 0
							extra_item = null // And the extra item
							cooked_item = R.creates // Store the item that will be created

				if (cooked_item == "") //Oops that wasn't a recipe dummy!!!
					if (egg_amount > 0 || flour_amount > 0 || water_amount > 0 || monkeymeat_amount > 0 || synthmeat_amount > 0 || humanmeat_amount > 0 || donkpocket_amount > 0 && extra_item == null) //Make sure there's something inside though to dirty it
						operating = 1 // Turn it on
						icon_state = "mw1"
						updateUsrDialog()
						egg_amount = 0 //Clear all the values as this crap is what makes the mess inside!!
						flour_amount = 0
						water_amount = 0
						humanmeat_amount = 0
						monkeymeat_amount = 0
						synthmeat_amount = 0
						donkpocket_amount = 0
						sleep(40) // Half way through
						playsound(loc, "sound/effects/splat.ogg", 50, 1) // Play a splat sound
						icon_state = "mwbloody1" // Make it look dirty!!
						sleep(40) // Then at the end let it finish normally
						playsound(loc, "sound/machines/ding.ogg", 50, 1)
						visible_message("<span style=\"color:red\">The microwave gets covered in muck!</span>")
						dirty = 1 // Make it dirty so it can't be used util cleaned
						icon_state = "mwbloody" // Make it look dirty too
						operating = 0 // Turn it off again aferwards
						// Don't clear the extra item though so important stuff can't be deleted this way and
						// it prolly wouldn't make a mess anyway

					else if (extra_item != null) // However if there's a weird item inside we want to break it, not dirty it
						operating = 1 // Turn it on
						icon_state = "mw1"
						updateUsrDialog()
						egg_amount = 0 //Clear all the values as this crap is gone when it breaks!!
						flour_amount = 0
						water_amount = 0
						humanmeat_amount = 0
						synthmeat_amount = 0
						monkeymeat_amount = 0
						donkpocket_amount = 0
						sleep(60) // Wait a while
						var/effects/system/spark_spread/s = unpool(/effects/system/spark_spread)
						s.set_up(2, 1, src)
						s.start()
						icon_state = "mwb" // Make it look all busted up and shit
						visible_message("<span style=\"color:red\">The microwave breaks!</span>") //Let them know they're stupid
						broken = 2 // Make it broken so it can't be used util fixed
						operating = 0 // Turn it off again aferwards
						extra_item.set_loc(get_turf(src)) // Eject the extra item so important shit like the disk can't be destroyed in there
						extra_item = null

					else //Otherwise it was empty, so just turn it on then off again with nothing happening
						operating = 1
						icon_state = "mw1"
						updateUsrDialog()
						sleep(80)
						icon_state = "mw"
						playsound(loc, "sound/machines/ding.ogg", 50, 1)
						operating = 0

			if (operation == 2) // If dispose was pressed, empty the microwave
				egg_amount = 0
				flour_amount = 0
				water_amount = 0
				humanmeat_amount = 0
				monkeymeat_amount = 0
				synthmeat_amount = 0
				donkpocket_amount = 0
				if (extra_item != null)
					extra_item.set_loc(get_turf(src)) // Eject the extra item so important shit like the disk can't be destroyed in there
					extra_item = null
				boutput(usr, "You dispose of the microwave contents.")

			var/cooking = text2path(cooked_item) // Get the item that needs to be spanwed
			if (!isnull(cooking))
				visible_message("<span style=\"color:blue\">The microwave begins cooking something!</span>")
				operating = 1 // Turn it on so it can't be used again while it's cooking
				icon_state = "mw1" //Make it look on too
				updateUsrDialog()
				being_cooked = new cooking(src)

				spawn (cook_time) //After the cooking time
					if (!isnull(being_cooked))
						playsound(loc, "sound/machines/ding.ogg", 50, 1)
						if (istype(being_cooked, /obj/item/reagent_containers/food/snacks/burger/humanburger))
							being_cooked.name = "[humanmeat_name] [being_cooked.name]"
						if (istype(being_cooked, /obj/item/reagent_containers/food/snacks/donkpocket))
							being_cooked:warm = 1
							being_cooked.name = "warm " + being_cooked.name
							being_cooked:cooltime()
						being_cooked.set_loc(get_turf(src)) // Create the new item
						being_cooked = null // We're done!

					operating = 0 // Turn the microwave back off
					icon_state = "mw"
			else
				return