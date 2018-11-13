/obj/npc/trader
	name="Trader"
	var/bullshit =0
	var/hiketolerance = 20 //How much they will tolerate price hike
	var/list/droplist = null //What the merchant will drop upon their death
	var/list/goods_sell = new/list() //What products the trader sells
	var/list/goods_buy = new/list() //what products the merchant buys
	var/list/shopping_cart = new/list() //What has been bought
	var/obj/item/sell = null //Item to sell
	var/portrait_setup = null
	var/obj/item/sellitem = null
	var/item_name = "--------"
	var/obj/item/card/id/scan = null
	//Trader dialogue
	var/sell_dialogue = null
	var/buy_dialogue = null
	var/list/successful_sale_dialogue = null
	var/list/failed_sale_dialogue = null
	var/list/successful_purchase_dialogue = null
	var/list/failed_purchase_dialogue = null
	var/pickupdialogue = null
	var/pickupdialoguefailure = null
	var/list/trader_area = "/area/trade_outpost/martian"
	var/doing_a_thing = 0

		// This list is in a specific order!!
	// String 1 - player is being dumb and hiked a price up when buying, trader accepted it because they're a dick
	// String 2 - same as above only the trader is being nice about it
	// String 3 - same as string 1 except we're selling
	// String 4 - same as string 3 except with a nice trader
	// String 5 - player haggled further than the trader is willing to tolerate
	// String 6 - trader has had enough of your bullshit and is leaving
	var/list/errormsgs = list("...huh. If you say so!",
								"Huh? You want to pay <em>more</em> for my wares than i'm offering?",
								"Wha.. well, okay! I'm not gonna complain!",
								"Wait, what? You want me to pay you <em>less</em> for your wares?",
								"What the f... umm, no? Make me a serious offer.",
								"Sorry, you're terrible at this. I must be going.")
	// Next list - the last entry will always be used on the trader's final haggling offer
	// otherwise the trader picks randomly from the list including the "final offer" in order to bluff players
	var/list/hagglemsgs = list("Alright, how's this sound?",
								"You drive a hard bargain. How's this price?",
								"You're busting my balls here. How's this?",
								"I'm being more than generous here, I think you'll agree.",
								"This is my final offer. Can't do better than this.")



	anger()
		for (var/mob/M in AIviewers(src))
			boutput(M, "<span style=\"color:red\"><strong>[name]</strong> becomes angry!</span>")
		desc = "[src] looks angry"
		spawn (rand(1000,3000))
			visible_message("<strong>[name] calms down.</strong>")
			desc = "[src] looks a bit annoyed."
			temp = "[name] has calmed down.<BR><A href='?src=\ref[src];mainmenu=1'>OK</A>"
			angry = 0
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
			<A href='?src=\ref[src];purchase=1'>Purchase Items</A><BR>
			<A href='?src=\ref[src];sell=1'>Sell Items</A><BR>
			<A href='?src=\ref[src];viewcart=1'>View Cart</A><BR>
			<A href='?src=\ref[src];pickuporder=1'>I'm Ready to Pick Up My Order</A><BR>
			<A href='?action=mach_close&window=trader'>Goodbye</A>"}

		user << browse(dat, "window=trader;size=575x530")
		onclose(user, "trader")
		return

	disposing()
		goods_sell = null
		goods_buy = null
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


		/////////////////////////////////////////////
		///////Generate list of items user can sell//
		/////////////////////////////////////////////
		else if (href_list["sell"])
			temp = "[sell_dialogue]<HR><BR>"
			for (var/commodity/N in goods_buy)
				if (N.hidden)
					continue
				else
					temp+={"<strong>[N.comname] for [N.price] Credits:</strong> [N.indemand ? N.desc_buy_demand : N.desc_buy]<BR>
							<A href='?src=\ref[src];haggles=[N]'><strong><U>Haggle</U></strong></A><BR><BR>"}
			if (sellitem)
				item_name = sellitem.name
			else
				item_name = "--------"
			temp += {"<HR>What do you wish to sell? <a href='?src=\ref[src];sellitem=1'>[item_name]</a><br>
						<BR><A href='?src=\ref[src];selltheitem=1'>Sell Item</A>
						<BR><A href='?src=\ref[src];mainmenu=1'>Ok</A>"}

		///////////////////////////////////////////
		///Haggle for selling /////////////////////
		///////////////////////////////////////////
		else if (href_list["haggles"])

			var/askingprice= input(usr, "Please enter your asking price.", "Haggle", 0) as null|num
			if (askingprice)
				var/commodity/N = locate(href_list["haggles"])
				if (N)
					if (patience == N.haggleattempts)

						temp = "[name] becomes angry and won't trade anymore."
						add_fingerprint(usr)
						updateUsrDialog()
						angry = 1
						anger()
					else
						haggle(askingprice, 0, N)
						temp +="<BR><A href='?src=\ref[src];sell=1'>Ok</A>"

		////////////////////////////////////////
		////////Slot holder for the current item///
		///////////////////////////////////////
		else if (href_list["sellitem"])
			if (sellitem)
				sellitem.set_loc(loc)
				sellitem = null
			else
				var/obj/item/I = usr.equipped()
				if (!I)
					return
				usr.drop_item()
				// in case dropping the item somehow deletes it?? idk there was a runtime error still
				if (!I)
					return
				I.set_loc(src)
				sellitem = I
				item_name = I.name
			temp = "[sell_dialogue]<HR><BR>"
			for (var/commodity/N  in goods_buy)
				if (N.hidden)
					continue
				else
					temp+="<strong>[N.comname] for [N.price] Credits:</strong> [N.indemand ? N.desc_buy_demand : N.desc_buy]<BR><BR>"
			if (sellitem)
				item_name = sellitem.name
			else
				item_name = "--------"
			temp += {"<HR>What do you wish to sell? <a href='?src=\ref[src];sellitem=1'>[item_name]</a><br>
							<BR><A href='?src=\ref[src];selltheitem=1'>Sell Item</A>
							<BR><A href='?src=\ref[src];mainmenu=1'>Ok</A>
							<BR><em>To sell large quantities at once, clickdrag a crate onto [src].</em>"}

		///////////////////////////////////////////
		/////////Actually Sell the item //////////
		//////////////////////////////////////////
		else if (href_list["selltheitem"])
			if (!sellitem)
				updateUsrDialog()
				return
			if (doing_a_thing)
				updateUsrDialog()
				return
			if (!scan)
				temp = {"You have to scan a card in first.<BR>
							<BR><A href='?src=\ref[src];sell=1'>OK</A>"}
				updateUsrDialog()
				return
			if (ispath(sellitem, /obj/item/reagent_containers/food/snacks/ingredient/meat))
				sellitem = /obj/item/reagent_containers/food/snacks/ingredient/meat
			if (ispath(sellitem, /obj/item/reagent_containers/food/snacks/plant))
				sellitem = /obj/item/reagent_containers/food/snacks/plant
			if (ispath(sellitem, /obj/item/electronics))
				sellitem = /obj/item/electronics
			if (ispath(sellitem, /obj/item/parts/robot_parts))
				sellitem = /obj/item/parts/robot_parts
			for (var/commodity/N in goods_buy)
				if (N.comtype == sellitem.type)
					var/data/record/account = null
					account = FindBankAccountByName(scan.registered)
					if (!account)
						temp = {" [src] looks slightly agitated when he realizes there is no bank account associated with the ID card.<BR>
									<BR><A href='?src=\ref[src];sell=1'>OK</A>"}
						add_fingerprint(usr)
						updateUsrDialog()
						return
					else
						doing_a_thing = 1
						account.fields["current_money"] += N.price
						temp = pick(successful_sale_dialogue) + "<BR>"
						temp += "<BR><A href='?src=\ref[src];sell=1'>OK</A>"
						qdel (sellitem)
						add_fingerprint(usr)
						updateUsrDialog()
						doing_a_thing = 0
						return
			temp = {"[pick(failed_sale_dialogue)]<BR>
						<BR><A href='?src=\ref[src];sell=1'>OK</A>"}

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
	///////////////////////////////////////
	///////Spawn the crates full of goods///
	////////////////////////////////////////
	proc/spawncrate()
		var/list/markers = new/list()
		var/pickedloc = 0
		var/found = 0

		var/list/area_turfs = get_area_turfs(trader_area)
		if (!area_turfs || !area_turfs.len)
			area_turfs = get_area_turfs( get_area(src) )

		for (var/turf/T in area_turfs)
			for (var/obj/marker/supplymarker/D in T)
				markers += D

		for (var/C in markers)
			if (locate(/obj/storage/crate) in get_turf(C))
				continue
			found = 1
			pickedloc = get_turf(C)
		if (!found)
			if (islist(markers) && markers.len)
				pickedloc = get_turf(pick(markers))
			else
				pickedloc = get_turf(src) // put it SOMEWHERE

		var/obj/storage/crate/A = new /obj/storage/crate(pickedloc)
		showswirl(pickedloc)
		A.name = "Goods Crate ([name])"
		for (var/obj/O in shopping_cart)
			O.set_loc(A)
		shopping_cart = new/list()

	////////////////////////////////////////////////////
	/////////Proc for haggling with dealer ////////////
	///////////////////////////////////////////////////
	proc/haggle(var/askingprice, var/buying, var/commodity/H)
		// if something's gone wrong and there's no input, reject the haggle
		// also reject if there's no change in the price at all
		if (!askingprice) return
		if (askingprice == H.price) return
		// if the player is being dumb and haggling in the wrong direction, tell them (unless the trader is an asshole)
		if (buying == 1)
			// we're buying, so we want to pay less per unit
			if (askingprice > H.price)
				if (bullshit >= 5)
					temp = errormsgs[1]
					H.price = askingprice
					return
				else
					temp = errormsgs[2]
					return
		else
			// we're selling, so we want to be paid MORE per unit
			if (askingprice < H.price)
				if (bullshit >= 5)
					H.price = askingprice
					temp = "<strong>Cost:</strong> [H.price] Credits<BR>"
					temp += errormsgs[3]
					return
				else
					temp = "<strong>Cost:</strong> [H.price] Credits<BR>"
					temp += errormsgs[4]
					return
		// check if the price increase % of the haggle is more than this trader will tolerate
		var/hikeperc = askingprice - H.price
		hikeperc = (hikeperc / H.price) * 100
		var/negatol = 0 - hiketolerance
		if (buying == 1) // we're buying, so price must be checked for negative
			if (hikeperc <= negatol)
				temp = "<strong>Cost:</strong> [H.price] Credits<BR>"
				temp += errormsgs[5]
				H.haggleattempts++
				return
		else
			if (hikeperc >= hiketolerance) // we're selling, so check hike for positive
				temp = errormsgs[5]
				H.haggleattempts++
				return
		// now, the actual haggling part! find the middle ground between the two prices
		var/middleground = (H.price + askingprice) / 2
		var/negotiate = abs(H.price-middleground)-1
		if (buying == 1)
			H.price =round(middleground + rand(0,negotiate))
		else
			if (middleground-H.price <= 0.5)
				H.price = round(middleground + 1)
			else
				H.price = round(middleground - rand(0,negotiate))

		temp = "<strong>New Cost:</strong> [H.price] Credits<BR><HR>"
		H.haggleattempts++
		// warn the player if the trader isn't going to take any more haggling
		if (patience == H.haggleattempts)
			temp += hagglemsgs[hagglemsgs.len]
		else
			temp += pick(hagglemsgs)


	///////////////////////////////////
	////// batch selling - cogwerks ///
	///////////////////////////////////

	MouseDrop_T(atom/movable/O as obj, mob/user as mob)
		if (get_dist(O,user) > 1) return
		if (!istype(user,/mob/living)) return
		if (!scan)
			boutput(user, "<span style=\"color:red\">You have to scan your ID first!</span>")
			return
		if (angry)
			boutput(user, "<span style=\"color:red\">[src] is angry and won't trade with anyone right now.</span>")
			return
		if (!alive)
			boutput(user, "<span style=\"color:red\">[src] is dead!</span>")
			return
		var/data/record/account = null
		account = FindBankAccountByName(scan.registered)
		if (!account)
			boutput(user, "<span style=\"color:red\">[src]There is no account registered with this card!</span>")
			return
		/*if (istype(O, /obj/item))
			user.visible_message("<span style=\"color:blue\">[src] rummages through [user]'s goods.</span>")
			var/staystill = user.loc
			for (var/commodity/N in goods_buy)
				if (N.comtype == O.type)
					user.visible_message("<span style=\"color:blue\">[src] is willing to buy all of [O].</span>")
					for (N.comtype in view(1,user))
						account.fields["current_money"] += N.price
						qdel(N.comtype)
						sleep(2)
						if (user.loc != staystill) break*/
		if (istype(O, /obj/storage/crate))
			if (O:locked)
				user.show_text("[src] stares at the locked [O], unamused. Maybe you should make sure the thing's open, first.", "red")
				return
			spawn (1)
				user.visible_message("<span style=\"color:blue\">[src] rummages through [user]'s [O].</span>")
				playsound(loc, "rustle", 60, 1)
				var/cratevalue = null
				for (var/obj/M in O.contents)
					//boutput(world, "<span style=\"color:blue\">HELLO I AM [M]</span>")
					//boutput(world, "<span style=\"color:blue\">AND MY TYPE PATH IS [M.type]</span>")
					for (var/commodity/N in goods_buy)
						if (M) // fuck the hell off you dirty null.type errors
							if (N.comtype == M.type)
								//boutput(world, "<strong>MY ASSOCIATED DATUM IS [N]</strong>")
								//boutput(world, "<span style=\"color:blue\">[M] IS GOING TO SELL FOR [N.price] HOT BALLS</span>")
								//boutput(world, "<span style=\"color:blue\">UPDATING CRATE VALUE TO [cratevalue] OR FUCKING ELSE</span>")
								cratevalue += N.price
								qdel( M )
				if (cratevalue)
					boutput(user, "<span style=\"color:blue\">[src] takes what they want from [O]. [cratevalue] credits have been transferred to your account.</span>")
					account.fields["current_money"] += cratevalue
				else
					boutput(user, "<span style=\"color:blue\">[src] finds nothing of interest in [O].</span>")

/////////////////////////////////////////////////////
///////////////THE TRADERS ///////////////////////////
//////////////////////////////////////////////////////

//////Generic Randomized visitor
/obj/npc/trader/random
	icon_state = "welder"
	picture = "generic.png"
	trader_area = "/area/shuttle/merchant_shuttle/left"

	New()
		..()
		icon_state = pick("martian","martianP","martianW","martianSP","mars_bot","welder","petbee","lavacrab","boogie","walrus","owl","goose","possum","bumblespider","big_spide[pick("","-red","-blue","-green")]")

		var/pickprename = pick("Honest","Fair","Merchant","Trader","Kosher","Real Deal","Dealer", "Old", "Ol'", "Zesty", "Sassy", "Bargain", "Discount", "Uncle", "Big", "Little")
		//var/pickfirstname = pick(first_names)
		var/picklastname = pick(last_names)
		name = "[pickprename] [picklastname]"

		greeting= {"WELL HI THERE, STEP RIGHT UP AND BUY MY STUFF!"}

		portrait_setup = "<img src='[resource("images/traders/[picture]")]'><HR><strong>[name]</strong><HR>"

		sell_dialogue = "Ah, an entepreneur after my own heart!  I have a few friends who are looking for things to buy!"

		buy_dialogue = "YES, COME RIGHT UP AND BUY MY FRIEND!"

		successful_purchase_dialogue = list("ANOTHER SATISFIED CUSTOMER!",
			"Thank you and HAVE A NICE DAY!",
			"SOLD, TO THE PERSON IN THE FUNNY JUMPSUIT!")

		failed_sale_dialogue = list("Don't waste my time, kid, I can't buy that!",
			"I've got nobody who wants to buy that junk!",
			"What, do you think I'm stupid?!?  Get out of here!",
			"Haha, nice try kid, but I've been in the business longer than that.")

		successful_sale_dialogue = list("Thank you very much!",
			"I'll take it!",
			"Come back anytime!")

		failed_purchase_dialogue = list("Come back when you can afford this stuff!",
			"You ain't got the cash, kid!",
			"Might want to check your account, 'cause I don't see the money in it!")

		pickupdialogue = "THANK YOU!"

		pickupdialoguefailure = "You need to BUY things before you pick them up!"

		hiketolerance = rand(2,4)
		hiketolerance *= 10

		var/items_for_sale = rand(5,8)
		var/items_wanted = rand(2,5)

		var/list/commercetypes = list(/commodity/ore,
		/commodity/podparts,
		/commodity/drugs,
		/commodity/contraband,
		/commodity/salvage,
		/commodity/junk,
		/commodity/diner,
		/commodity/bodyparts,
		/commodity/medical,
		/commodity/synthmodule)

		var/list/selltypes = typesof(pick(commercetypes))
		var/list/buytypes = typesof(pick(commercetypes))

		while (selltypes.len > 0 && goods_sell.len < items_for_sale)
			var/pickedselltype = pick(selltypes)
			var/commodity/sellitem = new pickedselltype(src)
			selltypes -= pickedselltype
			if (sellitem.comtype != null)
				goods_sell += sellitem

		while (buytypes.len > 0 && goods_buy.len < items_wanted)
			var/pickedbuytype = pick(buytypes)
			var/commodity/buyitem = new pickedbuytype(src)
			buytypes -= pickedbuytype
			if (buyitem.comtype != null)
				goods_buy += buyitem

	activatesecurity()
		for (var/mob/M in AIviewers(src))
			boutput(M, "<strong>[name]</strong> yells, \"Get 'em boys!\"")
		for (var/turf/T in get_area_turfs( get_area(src) ))
			for (var/obj/decal/fakeobjects/teleport_pad/D in T)
				var/N = pick(1,2)
				var/obj/critter/martian/P = null
				if (N == 1)
					P = new /obj/critter/martian/soldier
				else
					P = new /obj/critter/martian/warrior
				P.set_loc(D.loc)
				showswirl(P.loc)


//////Martian
/obj/npc/trader/martian
	icon_state = "martianP"
	picture = "martian.png"
	trader_area = "/area/martian_trader"
	New()
		..()
		goods_sell += new /commodity/ore/uqill(src) // cogwerks - changed from molitz, who the hell ever needs that
		goods_sell += new /commodity/ore/plasmastone(src) // no guns, no, bad
		goods_sell += new /commodity/ore/bohrum(src)
		goods_sell += new /commodity/ore/cerenkite(src)
		goods_sell += new /commodity/ore/telecrystal(src)

		goods_buy += new /commodity/laser_gun(src)
		goods_buy += new /commodity/relics/skull(src)
		goods_buy += new /commodity/relics/relic(src)
		goods_buy += new /commodity/relics/gnome(src)
		goods_buy += new /commodity/relics/crown(src)
		goods_buy += new /commodity/relics/armor(src)





		name = pick( "L'zeurk Xin", "Norzamed Bno", "Kleptar Sde", "Z'orrel Ryvc")
		greeting= {"As you approach the martian, thoughts begins to enter your head.
			<em>\"Greetings Human, unlike most martians, I am quite friendly. All I desire is to sell my wares\"</em>.
			<strong>[name]</strong> gestures towards his goods and awaits for you to make your choice."}

		portrait_setup = "<img src='[resource("images/traders/[picture]")]'><HR><strong>[name]</strong><HR>"

		sell_dialogue = "You recieve visions of various indviuals who are looking to purchase something, and get the feeling that <strong>[name]</strong> will act as the middle man."

		buy_dialogue = "You hear a voice in your head,<em>\"Please select what you would like to buy\".</em>"

		successful_sale_dialogue = list("<em>A wave of joy washes over you upon the completion of the sale.</em>",
			"In your head you hear a voice say, <em>\"Thank you for your business. Perhaps we shouldn't wipe you all out.\"</em>",
			"[name] quickly begans putting his new merchandise away. Despite that, you somehow know that the martian is grateful for the sale")

		failed_sale_dialogue = list("<em>You feel an intense feeling of irritation come over you</em>. A foreign thought enters your head, <em>\"Please don't waste my time. I have better things to do than to look at worthless junk.\"</em>",
			"[src] telepathically communicates to you, <em>\"I'm sorry I currently have no interest in that item, perhaps you should try another trader.\"",
			"You suddenly and unnaturally feel incredibly stupid and embarassed about your mistake. You hang your head in shame.",
			"The martian pats you gently on the head, and shakes it head. It seems [src] feels sorry for you")

		successful_purchase_dialogue = list("[name] communicates to you, <em>\"Thank you for your business\"</em>.",
			"A thought enters your head, <em>\"An excellent choice. Tell me when you are ready to pick it up\".</em>")

		failed_purchase_dialogue = list("[name] communicates to you, <em>\"I am sorry, but you currenty do not have enough funds to purchase this.\"</em>",
			"[name] communicates to you, <em>\"Are you trying to pull a trick on me because I am a martian? You don't have enough credits to purchase this.\"</em>")

		pickupdialogue = "A foreign thought enters your head, <em>\"Thank you for your business. Please come again\"</em>"

		pickupdialoguefailure = "[name] checks something on a strange device. <em>\"I'm sorry, but you don't have anything to pick up\"</em>."

	activatesecurity()
		for (var/mob/M in AIviewers(src))
			boutput(M, "<strong>[name]</strong> yells, \"mortigi c^iujn!\"")
		for (var/turf/T in get_area_turfs( get_area(src) ))
			for (var/obj/decal/fakeobjects/teleport_pad/D in T)
				var/obj/critter/martian/soldier/P = new /obj/critter/martian/soldier
				P.set_loc(D.loc)
				showswirl(P.loc)

////////Robot
/obj/npc/trader/robot
	icon = 'icons/misc/evilreaverstation.dmi' // changed from the ancient robot sprite to pr1
	icon_state = "pr1_b"
	picture = "robot.png"
	trader_area = "/area/turret_protected/robot_trade_outpost"
	var/productset = 0 // 0 is robots and salvage, 1 is podparts and drugs, 2 is produce. 3 is syndicate junk, 4 is medical stuff
	var/illegal = 0 // maybe trading with illegal bots could flag the user's criminal record for smuggling

	New()
		..()
		switch(productset)
			if (1) // drugs and pod stuff
				goods_sell += new /commodity/podparts/engine(src)
				goods_sell += new /commodity/podparts/laser(src)
				goods_sell += new /commodity/podparts/asslaser(src)
				goods_sell += new /commodity/podparts/blackarmor(src)
				goods_sell += new /commodity/podparts/skin_stripe_r(src)
				goods_sell += new /commodity/podparts/skin_stripe_b(src)
				goods_sell += new /commodity/podparts/skin_flames(src)
				goods_sell += new /commodity/contraband/ntso_uniform(src)
				goods_sell += new /commodity/contraband/ntso_beret(src)
				goods_sell += new /commodity/contraband/ntso_vest(src)
				goods_sell += new /commodity/drugs/methamphetamine(src)
				goods_sell += new /commodity/drugs/crank(src)
				//goods_sell += new /commodity/drugs/bathsalts(src)
				goods_sell += new /commodity/drugs/catdrugs(src)
				goods_sell += new /commodity/drugs/morphine(src)
				goods_sell += new /commodity/drugs/krokodil(src)
				goods_sell += new /commodity/drugs/lsd(src)
				goods_sell += new /commodity/pills/uranium(src)

				goods_buy += new /commodity/drugs/shrooms(src)
				goods_buy += new /commodity/drugs/cannabis(src)
				goods_buy += new /commodity/drugs/cannabis_mega(src)
				goods_buy += new /commodity/drugs/cannabis_white(src)
				goods_buy += new /commodity/drugs/cannabis_omega(src)

			if (2) // diner attendant
				goods_sell += new /commodity/diner/mysteryburger(src)
				goods_sell += new /commodity/diner/monster(src)
				goods_sell += new /commodity/diner/sloppyjoe(src)
				goods_sell += new /commodity/diner/mashedpotatoes(src)
				goods_sell += new /commodity/diner/waffles(src)
				goods_sell += new /commodity/diner/pancake(src)
				goods_sell += new /commodity/diner/meatloaf(src)
				goods_sell += new /commodity/diner/slurrypie(src)
				goods_sell += new /commodity/diner/daily_special(src)

				goods_buy += new /commodity/produce/special/gmelon(src)
				goods_buy += new /commodity/produce/special/greengrape(src)
				goods_buy += new /commodity/produce/special/ghostchili(src)
				goods_buy += new /commodity/produce/special/chilly(src)
				goods_buy += new /commodity/produce/special/lashberry(src)
				goods_buy += new /commodity/produce/special/purplegoop(src)
				goods_buy += new /commodity/produce/special/glowfruit(src)

			if (3) // syndicate bot
				goods_sell += new /commodity/contraband/command_suit(src)
				goods_sell += new /commodity/contraband/swatmask(src)
				goods_sell += new /commodity/contraband/radiojammer(src)
				goods_sell += new /commodity/contraband/stealthstorage(src)
				goods_sell += new /commodity/contraband/disguiser(src)
				goods_sell += new /commodity/contraband/birdbomb(src)
				goods_sell += new /commodity/contraband/flare(src)
				goods_sell += new /commodity/contraband/eguncell_highcap(src)
				goods_sell += new /commodity/podparts/cloak(src)
				goods_sell += new /commodity/podparts/redarmor(src)
				goods_sell += new /commodity/podparts/ballistic(src)
				goods_sell += new /commodity/podparts/artillery(src)
				goods_sell += new /commodity/contraband/artillery_ammo(src)

				goods_buy += new /commodity/contraband/egun(src)
				goods_buy += new /commodity/contraband/secheadset(src)
				goods_buy += new /commodity/contraband/hosberet(src)
				goods_buy += new /commodity/contraband/spareid(src)
				goods_buy += new /commodity/contraband/captainid(src)
				goods_buy += new /commodity/goldbar(src)

			if (4) // medical
				goods_sell += new /commodity/medical/injectorbelt(src)
				goods_sell += new /commodity/medical/strange_reagent(src)
				goods_sell += new /commodity/medical/firstaidR(src)
				goods_sell += new /commodity/medical/firstaidBr(src)
				goods_sell += new /commodity/medical/firstaidB(src)
				goods_sell += new /commodity/medical/firstaidT(src)
				goods_sell += new /commodity/medical/firstaidO(src)
				goods_sell += new /commodity/medical/firstaidN(src)
				goods_sell += new /commodity/synthmodule/bacteria(src)
				goods_sell += new /commodity/synthmodule/virii(src)
				goods_sell += new /commodity/synthmodule/fungi(src)
				goods_sell += new /commodity/synthmodule/parasite(src)
				goods_sell += new /commodity/synthmodule/gmcell(src)
				goods_sell += new /commodity/synthmodule/vaccine(src)
				goods_sell += new /commodity/pathogensample(src)

				goods_sell += new /commodity/bodyparts/cyberheart(src)
				goods_sell += new /commodity/bodyparts/cyberbutt(src)
				goods_sell += new /commodity/bodyparts/cybereye(src)
				goods_sell += new /commodity/bodyparts/cybereye_sunglass(src)
				goods_sell += new /commodity/bodyparts/cybereye_thermal(src)
				goods_sell += new /commodity/bodyparts/cybereye_meson(src)
				goods_sell += new /commodity/bodyparts/cybereye_spectro(src)
				goods_sell += new /commodity/bodyparts/cybereye_prodoc(src)
				goods_sell += new /commodity/bodyparts/cybereye_camera(src)
				goods_sell += new /commodity/bodyparts/cybereye_ecto(src)

				goods_buy += new /commodity/bodyparts/armL(src)
				goods_buy += new /commodity/bodyparts/armR(src)
				goods_buy += new /commodity/bodyparts/legL(src)
				goods_buy += new /commodity/bodyparts/legR(src)
				goods_buy += new /commodity/bodyparts/brain(src)
				goods_buy += new /commodity/bodyparts/synthbrain(src)
				goods_buy += new /commodity/bodyparts/aibrain(src)
				goods_buy += new /commodity/bodyparts/butt(src)
				goods_buy += new /commodity/bodyparts/synthbutt(src)
				goods_buy += new /commodity/bodyparts/heart(src)
				goods_buy += new /commodity/bodyparts/synthheart(src)
				goods_buy += new /commodity/bodyparts/eye(src)
				goods_buy += new /commodity/bodyparts/syntheye(src)
				goods_buy += new /commodity/bodyparts/lung(src)

			else // salvage goods
				goods_sell += new /commodity/fuel(src)
				goods_sell += new /commodity/junk/horsemask(src)
				goods_sell += new /commodity/junk/batmask(src)
				goods_sell += new /commodity/junk/johnny(src)
				goods_sell += new /commodity/junk/buddy(src)
				goods_sell += new /commodity/junk/cowboy_boots(src)
				goods_sell += new /commodity/junk/cowboy_hat(src)
				goods_sell += new /commodity/medical/injectormask(src)
				goods_sell += new /commodity/contraband/briefcase(src)
				goods_sell += new /commodity/boogiebot(src)
				goods_sell += new /commodity/junk/voltron(src)
				goods_sell += new /commodity/junk/cloner_upgrade(src)
				goods_sell += new /commodity/podparts/goldarmor(src)

				goods_buy += new /commodity/salvage/scrap(src)
				goods_buy += new /commodity/salvage/machinedebris(src)
				goods_buy += new /commodity/salvage/robotdebris(src)
				goods_buy += new /commodity/relics/gnome(src)
				goods_buy += new /commodity/goldbar(src)

		//name = pick( "Unit DX-495E", "Unit DX-495H", "Unit DX-575E", "Unit DX-485F", "Unit DX-385D", "Sketchy D", "Skeevy D")

		greeting= {"[name]'s eyes light up, and he states, \"Salutations organic, welcome to my shop. Please browse my wares.\""}

		portrait_setup = "<img src='[resource("images/traders/[picture]")]'><HR><strong>[name]</strong><HR>"

		sell_dialogue = "[name] states, \"There are several individuals in my database that are looking to procure goods."

		buy_dialogue = "[name] states,\"Please select what you would like to buy\"."

		successful_sale_dialogue = list("[name] states, \"Thank you for the business organic.\"",
			"[name], \"I am adding you to the Good Customer Database.\"")

		failed_sale_dialogue = list("[name] states, \"<ERROR> Item not in purchase database.\"",
			"[name] states, \"I'm sorry I currently have no interest in that item, perhaps you should try another trader.\"",
			"[name] starts making a loud and irritating noise. [name] states, \"Fatal Exception Error: Cannot locate item\"",
			"[name] states, \"Invalid Input\"")

		successful_purchase_dialogue = list("[name] states, \"Thank you for your business\".",
			"[name] states, \"My logic drives calculate that was a wise purchase\".")

		failed_purchase_dialogue = list("[name] states, \"I am sorry, but you currenty do not have enough funds to purchase this.\"",
			"[name] states, \"Is this organic unit malfunctioning? You do not have enough funds to buy this\"")

		pickupdialogue = "[name] states, \"Thank you for your business. Please come again\"."

		pickupdialoguefailure = "[name] states, \"I'm sorry, but you don't have anything to pick up\"."

	activatesecurity()
		for (var/mob/M in AIviewers(src))
			boutput(M, "<strong>[name]</strong> exclaims, \"SECURITY SYSTEM COMING ONLINE\"")
		for (var/turf/T in get_area_turfs( get_area(src) ))
			for (var/obj/machinery/bot/guardbot/G in T)
				G.turn_on()


/// BZZZZZZZZZZZ

/obj/npc/trader/bee
	icon = 'icons/obj/trader.dmi'
	icon_state = "bee"
	picture = "bee.png"
	name = "Bombini" // like the tribe of bumblebees
	trader_area = "/area/bee_trader"

	New()
		..()
		/////////////////////////////////////////////////////////
		//// sell list //////////////////////////////////////////
		/////////////////////////////////////////////////////////
		goods_sell += new /commodity/guardbot_kit(src)
		goods_sell += new /commodity/guardbot_medicator(src)
		goods_sell += new /commodity/guardbot_flash(src)
		goods_sell += new /commodity/guardbot_taser(src)
		goods_sell += new /commodity/guardbot_smoker(src)
		goods_sell += new /commodity/royaljelly(src)
		goods_sell += new /commodity/beeegg(src)
		goods_sell += new /commodity/b33egg(src)
		goods_sell += new /commodity/bee_kibble(src)
		/////////////////////////////////////////////////////////
		//// buy list ///////////////////////////////////////////
		/////////////////////////////////////////////////////////
		goods_buy += new /commodity/honey(src)
		goods_buy += new /commodity/contraband/spareid/bee(src)
		goods_buy += new /commodity/contraband/captainid/bee(src)
		goods_buy += new /commodity/goldbar(src)
		/////////////////////////////////////////////////////////

		greeting= {"[name] buzzes cheerfully."}

		portrait_setup = "<img src='[resource("images/traders/[picture]")]'><HR><strong>[name]</strong><HR>"

		sell_dialogue = "[name] bumbles a bit."

		buy_dialogue = "[name] buzzes inquisitively."

		successful_sale_dialogue = list("[name] does a little dance. He looks pretty pleased.")

		failed_sale_dialogue = list("[name] grumbles.",
			"[name] buzzes grumpily.",
			"[name] grumpily bumbles.",
			"[name] looks sad. Look what you've gone and done.")

		successful_purchase_dialogue = list("[name] grustles.",
			"[name] buzzes happily. You feel happier too.")

		failed_purchase_dialogue = list("[name] gives a somber little buzz.",
			"[name] pouts. You feel pretty bad about yourself.")

		pickupdialogue = "[name] bumbles a bunch."

		pickupdialoguefailure = "[name] grumps."

	activatesecurity()
		for (var/mob/M in AIviewers(src))
			boutput(M, "<strong>[name]</strong> exclaims, \"BZZZZZZZZZZZ!\"")
		for (var/turf/T in get_area_turfs( get_area(src) ))
			for (var/obj/critter/domestic_bee/B in T)
				B.aggressive = 1 // be, aggressive. bee be aggressive
				B.atkcarbon = 1

// Hon- I mean, hello sir.

/obj/npc/trader/exclown
	icon = 'icons/obj/trader.dmi'
	icon_state = "exclown"
	picture = "exclown.png"
	name = "Geoff Honkington"
	trader_area = "/area/hallway/secondary/entry"

	New()
		..()
		/////////////////////////////////////////////////////////
		//// sell list //////////////////////////////////////////
		/////////////////////////////////////////////////////////
		goods_sell += new /commodity/costume/bee(src)
		goods_sell += new /commodity/costume/monkey(src)
		goods_sell += new /commodity/costume/robuddy(src)
		goods_sell += new /commodity/costume/waltwhite(src)
		goods_sell += new /commodity/costume/spiderman(src)
		goods_sell += new /commodity/costume/wonka(src)
		goods_sell += new /commodity/costume/light_borg(src)
		goods_sell += new /commodity/costume/utena(src)
		goods_sell += new /commodity/balloons(src)
		/////////////////////////////////////////////////////////
		//// buy list ///////////////////////////////////////////
		/////////////////////////////////////////////////////////
		goods_buy += new /commodity/goldbar(src)
		/////////////////////////////////////////////////////////

		greeting= {"Psst, I've got what you need HON- Ahem, disregard that."}

		portrait_setup = "<img src='[resource("images/traders/[picture]")]'><HR><strong>[name]</strong><HR>"

		sell_dialogue = "Waddya have to sell?"

		buy_dialogue = "Feel free to browse my wares, but you better hurry!"

		successful_purchase_dialogue = list("Another satisfied customer.",
			"Thank you.",
			"It's been a pleasure doing business with you.")

		failed_sale_dialogue = list("Don't waste my time, kid, I can't buy that!",
			"I've got nobody who wants to buy that junk!",
			"What, do you think I'm stupid?!?  Get out of here!",
			"Haha, nice try kid, but I've been in the business longer than that.")

		successful_sale_dialogue = list("Thank you very much!",
			"I'll take it!",
			"Come back anytime!")

		failed_purchase_dialogue = list("Come back when you can afford this stuff!",
			"You ain't got the cash, kid!",
			"Might want to check your account, 'cause I don't see the money in it!")

		pickupdialogue = "Thank you very mhHHHONK- Uh, nothing."

		pickupdialoguefailure = "You need to BUY things before you pick them up!"