/obj/npc/station_trader //separate obj because he has a lot of different behaviours eg. no buying, no set area, no defence systems to activate
	name="Shady Robot"
	icon = 'icons/misc/evilreaverstation.dmi' //temporary
	icon_state = "pr1_b"
	picture = "robot.png"
	var/hiketolerance = 20 //How much they will tolerate price hike
	var/list/droplist = null //What the merchant will drop upon their death
	var/list/goods_sell = new/list() //What products the trader sells
	var/list/shopping_cart = new/list() //What has been bought
	var/obj/item/sell = null //Item to sell
	var/portrait_setup = null
	var/obj/item/sellitem = null
	var/item_name = "--------"
	var/obj/item/card/id/scan = null
	//Trader dialogue
	var/buy_dialogue = null
	var/list/successful_sale_dialogue = null
	var/list/failed_sale_dialogue = null
	var/list/successful_purchase_dialogue = null
	var/list/failed_purchase_dialogue = null
	var/pickupdialogue = null
	var/pickupdialoguefailure = null
	var/list/trader_areas = list(/area/station/maintenance/aftsolar,/area/station/solar/aft,/area/station/maintenance/starboard,/area/station/maintenance/asmaint,/area/station/maintenance/starboardsolar,/area/station/solar/starboard,/area/station/maintenance/aft,/area/station/maintenance/disposal,/area/station/maintenance/apmaint,/area/station/maintenance/portsolar,/area/station/solar/port,/area/station/hallway/secondary/construction,/area/station/maintenance/fpmaint,/area/station/crew_quarters/quartersA,/area/station/crew_quarters/quartersB,/area/station/crew_quarters/observatory,/area/station/wreckage,/area/station/maintenance/fore,/area/station/maintenance/maintcentral)
	var/doing_a_thing = 0

		// This list is in a specific order!!
	// String 1 - player is being dumb and hiked a price up when buying, trader accepted it because they're a dick
	// String 2 - same as above only the trader is being nice about it
	// String 3 - player haggled further than the trader is willing to tolerate
	// String 4 - trader has had enough of your bullshit and is leaving
	var/list/errormsgs = list("...huh. If you say so!",
								"Huh? You want to pay <em>more</em> for my wares than i'm offering?",
								"What the f... umm, no? Make me a serious offer.",
								"Sorry, you're terrible at this. I must be going.")
	// Next list - the last entry will always be used on the trader's final haggling offer
	// otherwise the trader picks randomly from the list including the "final offer" in order to bluff players
	var/list/hagglemsgs = list("Alright, how's this sound?",
								"You drive a hard bargain. How's this price?",
								"You're busting my balls here. How's this?",
								"I'm being more than generous here, I think you'll agree.",
								"This is my final offer. Can't do better than this.")

	//CARD VARS
	var/card_registered = null		//who is the card registered to?
	var/card_assignment = null		//what job does it have?
	var/card_icon_state = "id"		//which icon should we use?
	var/card_icon_price = 0			//how much does that icon cost (flat price)?
	var/card_duration = 60			//how long will the card's access last?
	var/list/card_access = list()	//what access will it have?
	var/card_price = 0				//total card price (calculated when updatecardprice() is called)
	var/card_timer = 0				//does the card display time remaining before its access runs out (costs 1000)?

	//ACCESS LISTS FOR PRICING & SORTING
	var/list/civilian_access_list = list(6, 12, 22, 23, 25, 26, 27, 28, 35, 36)
	var/list/engineering_access_list = list(13, 32, 40, 43, 44, 45, 46, 47, 48)
	var/list/supply_access_list = list(30, 31, 34, 47, 50, 51)
	var/list/research_access_list = list(5, 7, 8, 9, 10, 24, 29, 33)
	var/list/security_access_list = list(1, 2, 3, 4, 37, 38, 39)
	var/list/command_access_list = list(11, 14, 15, 16, 17, 18, 19, 20, 21, 49, 53)
	var/list/special_access_list = list(37)

	//PRODUCTS
	var/list/common_products = list(/commodity/bodyparts/butt,/commodity/contraband/ntso_uniform,/commodity/contraband/ntso_vest,/commodity/contraband/ntso_beret,/commodity/drugs/methamphetamine,/commodity/drugs/crank,/commodity/drugs/catdrugs,/commodity/drugs/morphine,/commodity/drugs/krokodil,/commodity/drugs/lsd,/commodity/drugs/shrooms,/commodity/drugs/cannabis,/commodity/drugs/cannabis_mega,/commodity/drugs/cannabis_white,/commodity/drugs/cannabis_omega,/commodity/produce/special/ghostchili,/commodity/contraband/secheadset,/commodity/medical/strange_reagent,/commodity/drugs/cyberpunk,/commodity/contraband/swatmask,/commodity/contraband/briefcase,/commodity/bodyparts/heart,/commodity/bodyparts/eye)
	var/num_common_products = 13 //how many of these to pick for sale

	var/list/rare_products = list(/commodity/contraband/radiojammer,/commodity/contraband/stealthstorage,/commodity/medical/injectorbelt,/commodity/medical/injectormask,/commodity/junk/voltron,/commodity/laser_gun,/commodity/relics/crown,/commodity/contraband/egun,/commodity/relics/armor,/commodity/contraband/spareid,/commodity/contraband/voicechanger,/commodity/contraband/chamsuit,/commodity/contraband/dnascram)
	var/num_rare_products = 2 //how many of these to pick for sale

	New()
		..()
		teleport()
		process()

		for (var/i = 1 to num_common_products)
			var/commodity/C = pick(common_products)
			goods_sell += new C(src)
			common_products -= C //so we don't get duplicates

		for (var/i = 1 to num_rare_products)
			var/commodity/C = pick(rare_products)
			goods_sell += new C(src)
			rare_products -= C //so we don't get duplicates

	proc/process()
		spawn (300)
			if (prob(20) && !scan)
				teleport()
			process()

	anger()
		for (var/mob/M in AIviewers(src))
			boutput(M, "<span style=\"color:red\"><strong>[name]</strong> becomes angry!</span>")
		desc = "[src] looks angry."
		teleport()
		spawn (rand(1000,3000))
			visible_message("<strong>[name] calms down.</strong>")
			desc = "[src] looks a bit annoyed."
			temp = "[name] has calmed down.<BR><A href='?src=\ref[src];mainmenu=1'>OK</A>"
			angry = 0
		return

	proc/teleport()
		var/area/A = pick(trader_areas)
		var/turf/target = null
		var/list/locs = list()

		for (var/turf/T in A)
			var/dense = 0
			if (T.density)
				dense = 1
			else
				for (var/obj/O in T)
					if (O.density)
						dense = 1
						break
			if (dense == 0) locs += T

		if (!locs.len) return

		target = pick(locs)

		showswirl(loc)
		loc = target
		showswirl(target)

		//reset stuff to default
		card_registered = null
		card_assignment = null
		card_icon_state = "id"
		card_icon_price = 0
		card_duration = 60
		card_access = list()
		card_price = 0
		card_timer = 0

		return

	attack_hand(var/mob/user as mob)
		if (..())
			return
		if (angry)
			boutput(user, "<span style=\"color:red\">[src] is angry and won't trade with anyone right now.</span>")
			return
		user.machine = src
		var/dat = updatemenu()
		if (!temp)
			dat += {"[greeting]<HR>
			<A href='?src=\ref[src];temp_card=1'>Purchase Temporary ID</A><BR>
			<A href='?src=\ref[src];purchase=1'>Purchase Items</A><BR>
			<A href='?src=\ref[src];viewcart=1'>View Cart</A><BR>
			<A href='?src=\ref[src];pickuporder=1'>I'm Ready to Pick Up My Order</A><BR>
			<A href='?action=mach_close&window=trader'>Goodbye</A>"}

		user << browse(dat, "window=trader;size=575x530")
		onclose(user, "trader")
		return

	disposing()
		goods_sell = null
		shopping_cart = null
		..()

	Topic(href, href_list)
		if (..())
			return

		if ((usr.contents.Find(src) || (in_range(src, usr) && istype(loc, /turf))) || (istype(usr, /mob/living/silicon)))
			usr.machine = src
		///////////////////////////////
		///////Generate Purchase List//
		///////////////////////////////
		if (href_list["temp_card"])
			temp = "I can hook you up with a temporary ID, just let me know what you need.<HR><BR>"
			temp = "<strong>Price: [card_price] credits</strong><BR><BR>"
			temp += "Registered: <a href='?src=\ref[src];registered=1'>[card_registered ? card_registered : "--------"]</a><BR>"
			temp += "Assignment: <a href='?src=\ref[src];assignment=1'>[card_assignment ? card_assignment : "--------"]</a><BR>"
			temp += "Duration: <a href='?src=\ref[src];duration=1'>[card_duration ? card_duration : "--------"] seconds</a><BR>"
			if (card_timer)
				temp += "Timer (1000 credits): <strong>Yes</strong>/<a href='?src=\ref[src];timer=0'>No</a><BR>"
			else
				temp += "Timer (1000 credits): <a href='?src=\ref[src];timer=1'>Yes</a>/<strong>No</strong><BR>"

			//Change access to individual areas
			temp += "<br><br><u>Access</u>"
			temp += "<br>Prices are per second."

			//Organised into sections
			var/civilian_access = "<br>Staff (1):"
			var/engineering_access = "<br>Engineering (2):"
			/* Conor12: I removed some unused accesses as the page is large enough, add these if they ever get used:
			41 (access_engineering_storage)
			42 (access_engineering_eva)*/
			var/supply_access = "<br>Supply (2):"
			var/research_access = "<br>Science and Medical (5):"
			var/security_access = "<br>Security (10):"
			var/command_access = "<br>Command (10):"
			var/special_access = "<br>Special (50):"

			for (var/A in access_name_lookup)
				if (access_name_lookup[A] in card_access)
					//Click these to remove access
					if (access_name_lookup[A] in civilian_access_list)
						civilian_access += " <a href='?src=\ref[src];access=[access_name_lookup[A]];allowed=0'><font color=\"red\">[replacetext(A, " ", "&nbsp")]</font></a>"
					if (access_name_lookup[A] in engineering_access_list)
						engineering_access += " <a href='?src=\ref[src];access=[access_name_lookup[A]];allowed=0'><font color=\"red\">[replacetext(A, " ", "&nbsp")]</font></a>"
					if (access_name_lookup[A] in supply_access_list)
						supply_access += " <a href='?src=\ref[src];access=[access_name_lookup[A]];allowed=0'><font color=\"red\">[replacetext(A, " ", "&nbsp")]</font></a>"
					if (access_name_lookup[A] in research_access_list)
						research_access += " <a href='?src=\ref[src];access=[access_name_lookup[A]];allowed=0'><font color=\"red\">[replacetext(A, " ", "&nbsp")]</font></a>"
					if (access_name_lookup[A] in security_access_list)
						security_access += " <a href='?src=\ref[src];access=[access_name_lookup[A]];allowed=0'><font color=\"red\">[replacetext(A, " ", "&nbsp")]</font></a>"
					if (access_name_lookup[A] in command_access_list)
						command_access += " <a href='?src=\ref[src];access=[access_name_lookup[A]];allowed=0'><font color=\"red\">[replacetext(A, " ", "&nbsp")]</font></a>"
				else//Click these to add access
					if (access_name_lookup[A] in civilian_access_list)
						civilian_access += " <a href='?src=\ref[src];access=[access_name_lookup[A]];allowed=1'>[replacetext(A, " ", "&nbsp")]</a>"
					if (access_name_lookup[A] in engineering_access_list)
						engineering_access += " <a href='?src=\ref[src];access=[access_name_lookup[A]];allowed=1'>[replacetext(A, " ", "&nbsp")]</a>"
					if (access_name_lookup[A] in supply_access_list)
						supply_access += " <a href='?src=\ref[src];access=[access_name_lookup[A]];allowed=1'>[replacetext(A, " ", "&nbsp")]</a>"
					if (access_name_lookup[A] in research_access_list)
						research_access += " <a href='?src=\ref[src];access=[access_name_lookup[A]];allowed=1'>[replacetext(A, " ", "&nbsp")]</a>"
					if (access_name_lookup[A] in security_access_list)
						security_access += " <a href='?src=\ref[src];access=[access_name_lookup[A]];allowed=1'>[replacetext(A, " ", "&nbsp")]</a>"
					if (access_name_lookup[A] in command_access_list)
						command_access += " <a href='?src=\ref[src];access=[access_name_lookup[A]];allowed=1'>[replacetext(A, " ", "&nbsp")]</a>"

			if (37 in card_access)
				special_access += " <a href='?src=\ref[src];access=37;allowed=0'><font color=\"red\">Head of Security</font></a>"
			else
				special_access += " <a href='?src=\ref[src];access=37;allowed=1'>Head of Security</a>"

			temp += "[civilian_access][engineering_access][supply_access][research_access][security_access][command_access][special_access]"

			temp += "<br><br><u>Customise ID</u><br>"
			temp += "[card_icon_state == "id" ? "<font color=\"red\">" : ""]<a href='?src=\ref[src];colour=none'>Plain</a>[card_icon_state == "id" ? "</font> " : " "]"
			temp += "[card_icon_state == "id_civ" ? "<font color=\"red\">" : ""]<a href='?src=\ref[src];colour=blue'>Civilian</a>[card_icon_state == "id_civ" ? "</font> " : " "]"
			temp += "[card_icon_state == "id_clown" ? "<font color=\"red\">" : ""]<a href='?src=\ref[src];colour=clown'>Clown</a>[card_icon_state == "id_clown" ? "</font> " : " "]"
			temp += "[card_icon_state == "id_eng" ? "<font color=\"red\">" : ""]<a href='?src=\ref[src];colour=yellow'>Engineering</a>[card_icon_state == "id_eng" ? "</font> " : " "]"
			temp += "[card_icon_state == "id_res" ? "<font color=\"red\">" : ""]<a href='?src=\ref[src];colour=purple'>Research</a>[card_icon_state == "id_res" ? "</font> " : " "]"
			temp += "[card_icon_state == "id_sec" ? "<font color=\"red\">" : ""]<a href='?src=\ref[src];colour=red'>Security</a>[card_icon_state == "id_sec" ? "</font> " : " "]"
			temp += "[card_icon_state == "id_com" ? "<font color=\"red\">" : ""]<a href='?src=\ref[src];colour=green'>Command</a>[card_icon_state == "id_com" ? "</font> " : " "]"
			temp += "[card_icon_state == "gold" ? "<font color=\"red\">" : ""]<a href='?src=\ref[src];colour=gold'>Captain</a>[card_icon_state == "gold" ? "</font>" : ""]"

			temp += "<BR><A href='?src=\ref[src];buycard=1'>Purchase</A>"
			temp += "<BR><A href='?src=\ref[src];mainmenu=1'>Back</A>"

		if (href_list["access"] && href_list["allowed"])
			var/access_type = text2num(href_list["access"])
			var/access_allowed = text2num(href_list["allowed"])

			if (access_type == 37)
				card_access -= access_type
				if (access_allowed == 1)
					card_access += access_type
			else if (access_type in get_all_accesses())
				card_access -= access_type
				if (access_allowed == 1)
					card_access += access_type

			updatecardprice()
			href = "temp_card=1"
			Topic(href, params2list(href))

		if (href_list["timer"])
			card_timer = text2num(href_list["timer"])

			updatecardprice()
			href = "temp_card=1"
			Topic(href, params2list(href))

		if (href_list["colour"])
			var/newcolour = href_list["colour"]
			switch(newcolour)
				if ("none")
					card_icon_state = "id"
					card_icon_price = 0
				if ("blue")
					card_icon_state = "id_civ"
					card_icon_price = 0
				if ("clown")
					card_icon_state = "id_clown"
					card_icon_price = 0
				if ("yellow")
					card_icon_state = "id_eng"
					card_icon_price = 500
				if ("purple")
					card_icon_state = "id_res"
					card_icon_price = 500
				if ("red")
					card_icon_state = "id_sec"
					card_icon_price = 1000
				if ("green")
					card_icon_state = "id_com"
					card_icon_price = 2000
				if ("gold")
					card_icon_state = "gold"
					card_icon_price = 5000

			updatecardprice()
			href = "temp_card=1"
			Topic(href, params2list(href))

		if (href_list["registered"])
			card_registered = input("Registered name?","Temporary ID")

			href = "temp_card=1"
			Topic(href, params2list(href))

		if (href_list["assignment"])
			card_assignment = input("Job title?","Temporary ID")

			href = "temp_card=1"
			Topic(href, params2list(href))

		if (href_list["duration"])
			var/input = input("Duration in seconds (1-600)?","Temporary ID") as num
			if (isnum(input))
				card_duration = min(max(input,1),600)

			updatecardprice()
			href = "temp_card=1"
			Topic(href, params2list(href))

		if (href_list["buycard"])
			if (!scan)
				temp = {"You have to scan a card in first.<BR>
							<BR><A href='?src=\ref[src];mainmenu=1'>OK</A>"}
				updateUsrDialog()
				return
			updatecardprice() //should be updated but just to be sure
			var/data/record/account = null
			account = FindBankAccountByName(scan.registered)
			if (!account)
				temp = {"That's odd I can't seem to find your account
							<BR><A href='?src=\ref[src];purchase=1'>OK</A>"}
			else if (account.fields["current_money"] < card_price)
				temp = {"Sorry [pick("buddy","pal","mate","friend","chief","bud","boss","champ")], you can't afford that!<BR>
							<BR><A href='?src=\ref[src];mainmenu=1'>OK</A>"}
			else
				if (spawncard())
					account.fields["current_money"] -= card_price
					temp = {"There ya go. You've got [card_duration] seconds to abuse that thing before its access is revoked.<BR>
								<BR><A href='?src=\ref[src];mainmenu=1'>OK</A>"}
					//reset to default so people can't go snooping and find out the last ordered card
					card_registered = null
					card_assignment = null
					card_icon_state = "id"
					card_icon_price = 0
					card_duration = 60
					card_access = list()
					card_price = 0
					card_timer = 0

		if (href_list["purchase"])
			temp =buy_dialogue + "<HR><BR>"
			for (var/commodity/N in goods_sell)
				// Have to send the type instead of a reference to the obj because it would get caught by the garbage collector. oh well.
				temp += {"<A href='?src=\ref[src];doorder=\ref[N]'><strong><U>[N.comname]</U></strong></A><BR>
				<strong>Cost:</strong> [N.price] Credits<BR>
				<strong>Description:</strong> [N.desc]<BR>
				<A href='?src=\ref[src];haggleb=\ref[N]'><strong><U>Haggle</U></strong></A><BR><BR>"}
			temp += "<BR><A href='?src=\ref[src];mainmenu=1'>Ok</A>"
		//////////////////////////////////////////////
		///////Handle the buying of a specific item //
		//////////////////////////////////////////////
		else if (href_list["doorder"])
			if (!scan)
				temp = {"You have to scan a card in first.<BR>
							<BR><A href='?src=\ref[src];purchase=1'>OK</A>"}
				updateUsrDialog()
				return
			if (scan.registered in FrozenAccounts)
				boutput(usr, "<span style=\"color:red\">Your account cannot currently be liquidated due to active borrows.</span>")
				return
			var/data/record/account = null
			account = FindBankAccountByName(scan.registered)
			if (account)
				var/quantity = 1
				quantity = input("How many units do you want to purchase? Maximum: 10", "Trader Purchase", null, null) as num
				if (quantity < 1)
					quantity = 0
					return
				else if (quantity >= 10)
					quantity = 10

				////////////
				var/commodity/P = locate(href_list["doorder"])

				if (P)
					if (account.fields["current_money"] >= P.price * quantity)
						account.fields["current_money"] -= P.price * quantity
						while (quantity-- > 0)
							shopping_cart += new P.comtype()
						temp = {"[pick(successful_purchase_dialogue)]<BR>
									<BR><A href='?src=\ref[src];purchase=1'>What other things have you got for sale?</A>
									<BR><A href='?src=\ref[src];pickuporder=1'>I want to pick up my order.</A>
									<BR><A href='?src=\ref[src];mainmenu=1'>I've got some other business.</A>"}
					else
						temp = {"[pick(failed_purchase_dialogue)]<BR>
									<BR><A href='?src=\ref[src];purchase=1'>OK</A>"}
				else
					temp = {"[src] looks bewildered for a second. Seems like they can't find your item.<BR>
								<BR><A href='?src=\ref[src];purchase=1'>OK</A>"}
			else
				temp = {"That's odd I can't seem to find your account
							<BR><A href='?src=\ref[src];purchase=1'>OK</A>"}

		///////////////////////////////////////////
		///Handles haggling for buying ////////////
		///////////////////////////////////////////
		else if (href_list["haggleb"])

			var/askingprice= input(usr, "Please enter your asking price.", "Haggle", 0) as null|num
			if (askingprice)
				var/commodity/N = locate(href_list["haggleb"])
				if (N)
					if (patience == N.haggleattempts)
						temp = "[name] becomes angry and won't trade anymore."
						add_fingerprint(usr)
						updateUsrDialog()
						angry = 1
						anger()
					else
						haggle(askingprice, 1, N)
						temp +="<BR><A href='?src=\ref[src];purchase=1'>Ok</A>"

		///////////////////////////////////
		////////Handle Bank account Set-Up ///////
		//////////////////////////////////
		else if (href_list["card"])
			if (scan) scan = null
			else
				var/obj/item/I = usr.equipped()
				if (istype(I, /obj/item/card/id))
					boutput(usr, "<span style=\"color:blue\">You swipe the ID card in the card reader.</span>")
					var/data/record/account = null
					account = FindBankAccountByName(I:registered)
					if (account)
						var/enterpin = input(usr, "Please enter your PIN number.", "Card Reader", 0) as null|num
						if (enterpin == I:pin)
							boutput(usr, "<span style=\"color:blue\">Card authorized.</span>")
							scan = I
						else
							boutput(usr, "<span style=\"color:red\">Pin number incorrect.</span>")
							scan = null
					else
						boutput(usr, "<span style=\"color:red\">No bank account associated with this ID found.</span>")
						scan = null

		////////////////////////////////////////////////////
		//////View what still needs to be picked up/////////
		///////////////////////////////////////////////////

		else if (href_list["viewcart"])
			temp = "<strong>Current Items in Cart: </strong>"
			for (var/obj/S in shopping_cart)
				temp+= "<BR>[S.name]"
			temp += "<BR><BR><A href='?src=\ref[src];mainmenu=1'>OK</A>"

		////////////////////////////////////////////////////
		/////Pick up the goods ordered from merchant////////
		//////////////////////////////////////////////////////

		else if (href_list["pickuporder"])
			if (shopping_cart.len)
				spawncrate()
				temp = pickupdialogue
			else
				temp = pickupdialoguefailure
			temp += "<BR><BR><A href='?src=\ref[src];mainmenu=1'>OK</A>"

		else if (href_list["mainmenu"])
			temp = null
		add_fingerprint(usr)
		updateUsrDialog()
		return

	/////////////////////////////////////////////
	/////Update the menu with the default items
	////////////////////////////////////////////

	proc/updatemenu()

		var/dat
		dat = portrait_setup
		dat +="<strong>Scanned Card:</strong> <A href='?src=\ref[src];card=1'>([scan])</A><BR>"
		if (scan)
			var/data/record/account = null
			account = FindBankAccountByName(scan.registered)
			if (account)
				dat+="<strong>Current Funds</strong>: [account.fields["current_money"]] Credits<HR>"
			else
				dat+="<HR>"
		else
			dat+="<HR>"
		if (temp)
			dat+=temp
		return dat

	/////////////////////////////////////////////
	/////Update card price
	////////////////////////////////////////////

	proc/updatecardprice()
		var/access_price = 0
		for (var/access in card_access)
			if (access in civilian_access_list)
				access_price += 1
			else if (access in engineering_access_list)
				access_price += 2
			else if (access in supply_access_list)
				access_price += 2
			else if (access in research_access_list)
				access_price += 5
			else if (access in security_access_list)
				access_price += 10
			else if (access in command_access_list)
				access_price += 10
			else if (access in special_access_list)
				access_price += 50

		card_price = card_icon_price + 1000*card_timer + card_duration*access_price

	////////////////////////////////////////
	/////// Spawn the crate or card ////////
	////////////////////////////////////////

	proc/spawncrate()
		var/turf/pickedloc = get_step(loc,dir)
		if (!pickedloc || pickedloc.density)
			var/list/locs = list()
			for (var/turf/T in view(1,src))
				var/dense = 0
				if (T.density)
					dense = 1
				else
					for (var/obj/O in T)
						if (O.density)
							dense = 1
							break
				if (dense == 0) locs += T
			pickedloc = pick(locs)

		if (!pickedloc)
			visible_message("[name] glances around as if confused, then shrugs.")
			teleport()
			return

		var/atom/A = new /obj/storage/crate(pickedloc)
		showswirl(pickedloc)
		A.name = "Goods Crate ([name])"
		for (var/obj/O in shopping_cart)
			O.set_loc(A)
		shopping_cart = new/list()

	proc/spawncard()
		var/turf/pickedloc = get_step(loc,dir)
		if (!pickedloc || pickedloc.density)
			var/list/locs = list()
			for (var/turf/T in view(1,src))
				var/dense = 0
				if (T.density)
					dense = 1
				else
					for (var/obj/O in T)
						if (O.density)
							dense = 1
							break
				if (dense == 0) locs += T
			pickedloc = pick(locs)

		if (!pickedloc)
			visible_message("[name] glances around as if confused, then shrugs.")
			teleport()
			return FALSE

		var/obj/item/card/id/temporary/I = new /obj/item/card/id/temporary(pickedloc)
		showswirl(pickedloc)
		I.name = "[card_registered]'s ID Card ([card_assignment])"
		I.registered = card_registered
		I.assignment = card_assignment
		I.icon_state = card_icon_state
		I.duration = card_duration
		I.access = card_access
		I.timer = card_timer

		return TRUE

	////////////////////////////////////////////////////
	/////////Proc for haggling with dealer ////////////
	///////////////////////////////////////////////////
	proc/haggle(var/askingprice, var/buying, var/commodity/H)
		// if something's gone wrong and there's no input, reject the haggle
		// also reject if there's no change in the price at all
		if (!askingprice) return
		if (askingprice == H.price) return
		// if the player is being dumb and haggling in the wrong direction, tell them (unless the trader is an asshole)

		// we're buying, so we want to pay less per unit
		if (askingprice > H.price)
			temp = errormsgs[2]
			return

		// check if the price increase % of the haggle is more than this trader will tolerate
		var/hikeperc = askingprice - H.price
		hikeperc = (hikeperc / H.price) * 100
		var/negatol = 0 - hiketolerance

		if (hikeperc <= negatol)
			temp = "<strong>Cost:</strong> [H.price] Credits<BR>"
			temp += errormsgs[3]
			H.haggleattempts++
			return

		// now, the actual haggling part! find the middle ground between the two prices
		var/middleground = (H.price + askingprice) / 2
		var/negotiate = abs(H.price-middleground)-1

		H.price =round(middleground + rand(0,negotiate))

		temp = "<strong>New Cost:</strong> [H.price] Credits<BR><HR>"
		H.haggleattempts++
		// warn the player if the trader isn't going to take any more haggling
		if (patience == H.haggleattempts)
			temp += hagglemsgs[hagglemsgs.len]
		else
			temp += pick(hagglemsgs)
