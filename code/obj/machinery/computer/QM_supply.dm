/cdc_contact_analysis
	var/uid = 0
	var/time_factor = 0
	var/time_done = 0
	var/begun_at = 0
	var/description_available = 0
	var/cure_available = 0
	var/cure_cost = 0
	var/name = ""
	var/desc = ""
	var/pathogen/assoc_pathogen = null

/cdc_contact_controller
	var/list/analysis_by_uid = list()
	var/list/ready_to_analyze = list()
	var/list/completed_analysis = list()
	var/cdc_contact_analysis/current_analysis = null
	var/pathogen/working_on = null
	var/working_on_time_factor = 0
	var/next_cure_batch = 0
	var/batches_left = 0
	var/next_crate = 0
	var/last_switch = 0

	New()
		..()
		processing_items.Add(src)

	proc/process()
		if (next_cure_batch < ticker.round_elapsed_ticks && working_on)
			var/obj/storage/crate/biohazard/B = new
			var/count = rand(3,6)
			for (var/i = 0, i < count, i++)
				new/obj/item/serum_injector(B, working_on, 1, 0)
			B.name = "CDC Pathogen cure crate ([working_on.name])"
			buy_thing(B)
			batches_left--
			if (batches_left)
				next_cure_batch = round(rand(175, 233) / 100 * working_on_time_factor) + ticker.round_elapsed_ticks
			else
				working_on = null

var/global/cdc_contact_controller/QM_CDC = new()

/obj/machinery/computer/supplycomp
	name = "Quartermaster's Console"
	icon = 'icons/obj/computer.dmi'
	icon_state = "QMcom"
	req_access = list(access_cargo)
	var/temp = null
	var/last_cdc_message = null
	var/hacked = 0
	var/tradeamt = 1
	var/in_dialogue_box = 0
	var/obj/item/card/id/scan = null
	var/list/datum/supply_pack

	//These will be used to not update the price list needlessly
	var/last_market_update = -INFINITY
	var/price_list = null



/obj/machinery/computer/supplycomp/attackby(I as obj, user as mob)
	return attack_hand(user)

/obj/machinery/computer/supplycomp/attack_ai(var/mob/user as mob)
	return attack_hand(user)

/obj/machinery/computer/supplycomp/emag_act(var/mob/user, var/obj/item/card/emag/E)
	if (!hacked)
		if (user)
			boutput(user, "<span style=\"color:blue\">Special supplies unlocked.</span>")
		hacked = 1
		return TRUE
	return FALSE

/obj/machinery/computer/supplycomp/demag(var/mob/user)
	if (!hacked)
		return FALSE
	if (user)
		boutput(user, "<span style=\"color:blue\">Treacherous supplies removed.</span>")
	hacked = 0
	return TRUE

/obj/machinery/computer/supplycomp/attackby(I as obj, user as mob)
	if (istype(I,/obj/item/card/emag))
		//I guess you'll wanna put the emag away now instead of getting a massive popup
	else
		return attack_hand(user)

/obj/machinery/computer/supplycomp/attack_hand(var/mob/user as mob)
	if (!allowed(user, req_only_one_required))
		boutput(user, "<span style=\"color:red\">Access Denied.</span>")
		return

	if (..())
		return

	var/timer = shippingmarket.get_market_timeleft()
	user.machine = src
	post_signal("supply")
	var/dat
	if (temp)
		dat = temp
	else
		dat += {"<strong>Quartermaster Console</strong><HR>
		<strong>Shipping Budget:</strong> [wagesystem.shipping_budget] Credits<BR>
		<strong>Next Market Shift:</strong> [timer]<HR>
		<A href='?src=\ref[src];viewrequests=1'>View Requests</A><BR>
		<A href='?src=\ref[src];vieworders=1'>View Order History</A><BR>
		<A href='?src=\ref[src];viewmarket=1'>View Shipping Market</A><BR><BR>
		<A href='?src=\ref[src];order=1'>Order Items</A><BR>"}

		if (!solar_flare)
			dat += "<A href='?src=\ref[src];contact_cdc=1'>Contact CDC</a><BR>"
		else
			dat += "CDC unavailable during solar interference.<BR>"

		if (shippingmarket.active_traders.len && !solar_flare)
			dat += "<A href='?src=\ref[src];trader_list=1'><strong>Call Trader</strong> ([shippingmarket.active_traders.len] available)</A><BR>"
		else
			dat += "No Traders in Communications Range<BR>"
		dat += "<A href='?action=mach_close&window=computer'>Close</A>"

	user << browse(dat, "window=computer;size=575x600")
	onclose(user, "computer")
	return

/obj/machinery/computer/supplycomp/proc/set_cdc()
	temp = "<strong>Center for Disease Control communication line</strong><HR>"
	temp += "<em>Greetings, [station_name]; how can we help you today?</em><BR><BR>"

	if (last_cdc_message)
		temp += "[last_cdc_message]<BR><BR>"

	temp += "<strong>Pathogen analysis services</strong><BR>"
	temp += "To send us pathogen samples, you can <A href='?src=\ref[src];req_biohazard_crate=1'>requisition a biohazardous materials crate</a> from us for 5 credits.<BR>"
	if (!QM_CDC.current_analysis)
		temp += "Our researchers currently have free capacity to analyze pathogen and blood samples for you.<BR>"
		if (length(QM_CDC.ready_to_analyze))
			temp += "We received your packages and are ready to <A href='?src=\ref[src];cdc_analyze=1'>analyze some samples</A>. It will cost you, but hey, you would like to survive, right?<BR>"
		else
			temp += "We have no unanalyzed pathogen samples from your station.<BR>"
	else
		temp += "We're currently analyzing the pathogen sample [QM_CDC.current_analysis.name]. We can <A href='?src=\ref[src];cdc_analyze=1'>analyze something different</A>, if you want."
		if (QM_CDC.current_analysis.description_available > ticker.round_elapsed_ticks)
			temp += "Here's what we have so far: <BR>[QM_CDC.current_analysis.desc]<BR>"
			if (QM_CDC.current_analysis.cure_available > ticker.round_elapsed_ticks)
				temp += "We've also discovered a method to synthesize a cure for this pathogen.<BR>"
				QM_CDC.completed_analysis += QM_CDC.current_analysis
				QM_CDC.current_analysis = null
			else
				var/CA = round((QM_CDC.current_analysis.cure_available - ticker.round_elapsed_ticks) / 600)
				temp += "We're really close to discovering a cure as well. It should be available a few [CA > 0 ? "minutes" : "seconds"].<BR>"
		else
			var/DA = round((QM_CDC.current_analysis.description_available - ticker.round_elapsed_ticks) / 600)
			temp += "We cannot tell you anything about this pathogen so far. Check back in [DA > 1 ? "[DA] minutes" : (DA > 0 ? "1 minute" : "a few seconds")].<BR>"
	temp += "<BR>"
	temp += "<strong>Pathogen cure services</strong><BR>"
	if (length(QM_CDC.working_on))
		temp += "We are currently working on [QM_CDC.batches_left] batch[QM_CDC.batches_left > 1 ? "es" : null] of cures for the [QM_CDC.working_on.name] pathogen. The crate will be delivered soon."
	else if (length(QM_CDC.completed_analysis))
		temp += "We have cures ready to be synthesized for [length(QM_CDC.completed_analysis)] pathogen[length(QM_CDC.completed_analysis) > 1 ? "s" : null].<BR>"
		temp += "You can requisition in batches. The more batches you order, the less time per batch it takes for us to deliver and the less credits per batch it will cost you.<BR>"
		temp += "<table style='width:100%; border:none; cell-spacing: 0px'>"
		for (var/cdc_contact_analysis/analysis in QM_CDC.completed_analysis)
			var/one_cost = analysis.cure_cost
			var/five_cost = analysis.cure_cost * 4
			var/ten_cost = analysis.cure_cost * 7
			temp += "<tr><td><strong>[analysis.assoc_pathogen.name]</strong><td><a href='?src=\ref[src];batch_cure=\ref[analysis];count=1'>1 batch for [one_cost] credits</a></td>td><a href='?src=\ref[src];batch_cure=\ref[analysis];count=5'>5 batches for [five_cost] credits</a></td>td><a href='?src=\ref[src];batch_cure=\ref[analysis];count=10'>10 batches for [ten_cost] credits</a></td></tr>"
			temp += "<tr><td colspan='4' style='font-style:italic'>[analysis.desc]</td></tr>"
			temp += "<tr><td colspan='4'>&nbsp;</td></tr>"
		temp += "</table><BR>"
	else
		temp += "We have no pathogen samples from your station that we can cure, yet.<BR>"
	temp += "<BR>"
	temp += "<A href='?src=\ref[src];mainmenu=1'>Main Menu</A>"

/obj/machinery/computer/supplycomp/Topic(href, href_list)
	if (..())
		return

	if ((usr.contents.Find(src) || (in_range(src, usr) && istype(loc, /turf))) || (istype(usr, /mob/living/silicon)))
		usr.machine = src

	if (href_list["order"])
		temp = {"<strong>Shipping Budget:</strong> [wagesystem.shipping_budget] Credits<BR><HR>
		<A href='?src=\ref[src];mainmenu=1'>Main Menu</A><BR><BR>
		<strong>Please select the Supply Package you would like to request:</strong><BR><BR>
		<table border=1>"}

		var/counter=0
		for (var/supply_packs/S in qm_supply_cache )
			if ((S.syndicate && !hacked) || S.hidden) continue
			if (counter++ % 10 == 0) temp += "<tr><th>Item<th>Cost<BR>(Credits)<th>Contents"
			temp += "<tr><td><A href='?src=\ref[src];doorder=\ref[S]'><strong><U>[S.name]</U></strong></A><td>[S.cost]<td>[S.desc]</tr>"



			/*
			temp += {"<A href='?src=\ref[src];doorder=\ref[S]'><strong><U>[S.name]</U></strong></A><BR>
			<strong>Cost:</strong> [S.cost] Credits<BR>
			<strong>Contents:</strong> [S.desc]<BR><BR>"}
			*/

		temp+="</table>"
		temp += "<BR><A href='?src=\ref[src];mainmenu=1'>Main Menu</A>"

	if (href_list["doorder"])
		if (istype(locate(href_list["doorder"]), /supply_order))
 			//If this is a supply order we came from the request approval form
			var/supply_order/O = locate(href_list["doorder"])
			var/supply_packs/P = O.object
			supply_requestlist -= O
			if (wagesystem.shipping_budget >= P.cost)
				wagesystem.shipping_budget -= P.cost
				O.object = P
				O.orderedby = usr.name
				O.comment = copytext(html_encode(input(usr,"Comment:","Enter comment","")), 1, MAX_MESSAGE_LEN)
				process_supply_order(O)
				supply_history += "[O.object.name] ordered by [O.orderedby] for [P.cost] credits. Comment: [O.comment]<BR>"
				temp = {"Thanks for your order.<BR>
							<BR><A href='?src=\ref[src];mainmenu=1'>Main Menu</A>
							<BR><A href='?src=\ref[src];order=1'>Back to Order List</A>"}
			else
				temp = {"Insufficient funds in Shipping Budget.<BR>
							<BR><A href='?src=\ref[src];mainmenu=1'>Main Menu</A>
							<BR><A href='?src=\ref[src];order=1'>Back to Order List</A>"}
		else
			//Comes from the orderform

			var/supply_order/O = new/supply_order ()
			var/supply_packs/P = locate(href_list["doorder"])
			if (P)
				if (wagesystem.shipping_budget >= P.cost)
					wagesystem.shipping_budget -= P.cost
					O.object = P
					O.orderedby = usr.name
					O.comment = copytext(html_encode(input(usr,"Comment:","Enter comment","")), 1, MAX_MESSAGE_LEN)
					process_supply_order(O)
					supply_history += "[O.object.name] ordered by [O.orderedby] for [P.cost] credits. Comment: [O.comment]<BR>"
					temp = {"Thanks for your order.<BR>
								<BR><A href='?src=\ref[src];mainmenu=1'>Main Menu</A>
								<BR><A href='?src=\ref[src];order=1'>Back to Order List</A>"}
				else
					temp = {"Insufficient funds in Shipping Budget.<BR>
								<BR><A href='?src=\ref[src];mainmenu=1'>Main Menu</A>
								<BR><A href='?src=\ref[src];order=1'>Back to Order List</A>"}

	else if (href_list["vieworders"])
		temp = "<strong>Order History: </strong><BR><BR>"
		for (var/S in supply_history)
			temp += S
		temp += "<BR><A href='?src=\ref[src];mainmenu=1'>OK</A>"

	else if (href_list["viewrequests"])
		temp = "<strong>Current Requests: </strong><BR>"
		for (var/supply_order/SO in supply_requestlist)
			temp += "<BR>[SO.object.name] requested by [SO.orderedby] from [SO.console_location]. <A href='?src=\ref[src];doorder=\ref[SO]'>Approve</A> <A href='?src=\ref[src];rreq=\ref[SO]'>Remove</A>"

		temp += {"<BR><A href='?src=\ref[src];clearreq=1'>Clear list</A>
						<BR><A href='?src=\ref[src];mainmenu=1'>OK</A>"}

	else if (href_list["viewmarket"])
		temp = "<strong>Shipping Market Prices</strong><HR>"
		if (shippingmarket.last_market_update != last_market_update) //Okay, the market has updated and we need a new price list
			last_market_update = shippingmarket.last_market_update
			price_list = ""
			for (var/item_type in shippingmarket.commodities)
				var/commodity/C = shippingmarket.commodities[item_type]
				var/viewprice = C.price
				if (C.indemand) viewprice *= shippingmarket.demand_multiplier

				price_list += "<BR><strong>[C.comname]:</strong> [viewprice] credits per unit "
				if (C.indemand) price_list += " <strong>(High Demand!)</strong>"

		var/timer = shippingmarket.get_market_timeleft()
		temp += {"[price_list]<BR><HR><strong>Next Price Shift:</strong> [timer]<BR>
					<A href='?src=\ref[src];viewmarket=1'>Refresh</A><BR>
					<A href='?src=\ref[src];mainmenu=1'>Main Menu</A>"}

	else if (href_list["contact_cdc"])
		if (solar_flare)
			boutput(usr, "<span style=\"color:red\">Solar flare activity is preventing contact with the CDC.</span>")
			return
		set_cdc()
		last_cdc_message = null

	else if (href_list["req_biohazard_crate"])
		if (solar_flare)
			boutput(usr, "<span style=\"color:red\">Solar flare activity is preventing contact with the CDC.</span>")
			return
		if (ticker.round_elapsed_ticks < QM_CDC.next_crate)
			last_cdc_message = "<span style=\"color:red; font-style: italic\">We are fresh out of crates right now to send you. Check back in [(QM_CDC.next_crate - ticker.round_elapsed_ticks)] seconds!</span>"
		else
			if (wagesystem.shipping_budget < 5)
				last_cdc_message = "<span style=\"color:red; font-style: italic\">You're completely broke. You cannot even afford a crate.</span>"
			else
				wagesystem.shipping_budget -= 5
				last_cdc_message = "<span style=\"color:blue; font-style: italic\">We're delivering the crate right now. It should arrive on your cargo pad shortly.</span>"
				buy_thing(new /obj/storage/crate/biohazard/cdc())
				QM_CDC.next_crate = ticker.round_elapsed_ticks + 300
		set_cdc()

	else if (href_list["cdc_analyze"])
		if (solar_flare)
			boutput(usr, "<span style=\"color:red\">Solar flare activity is preventing contact with the CDC.</span>")
			return
		temp = "<strong>Center for Disease Control communication line</strong><HR>"
		temp += "<em>These are the unanalyzed samples we have from you, [station_name].</em><BR><BR>"
		if (QM_CDC.current_analysis)
			temp += "We are currently researching the sample [QM_CDC.current_analysis.assoc_pathogen.name]. We can start on a new one if you like, but the analysis cost will not be refunded.<BR><BR>"
		temp += "Analysis costs 1000 credits to begin. Choose a pathogen sample to analyze:<BR>"
		for (var/cdc_contact_analysis/C in QM_CDC.ready_to_analyze)
			temp += "<a href='?src=\ref[src];cdc_analyze_me=\ref[C]'>[C.assoc_pathogen.name]</a> ([round(C.time_done / (2 * C.time_factor))]% done)<BR>"
		temp += "<BR><A href='?src=\ref[src];contact_cdc=1'>Back</A><BR><A href='?src=\ref[src];mainmenu=1'>Main Menu</A>"

	else if (href_list["cdc_analyze_me"])
		if (solar_flare)
			boutput(usr, "<span style=\"color:red\">Solar flare activity is preventing contact with the CDC.</span>")
			return
		if (QM_CDC.last_switch > ticker.round_elapsed_ticks - 300)
			last_cdc_message = "<span style=\"color:red; font-style: italic\">We just switched projects. Hold on for a bit.</span>"
		else if (wagesystem.shipping_budget < 1000)
			last_cdc_message = "<span style=\"color:red; font-style: italic\">You cannot afford to start a new analysis.</span>"
		else
			var/cdc_contact_analysis/C = locate(href_list["cdc_analyze_me"])
			if (!(C in QM_CDC.ready_to_analyze))
				last_cdc_message = "<span style=\"color:red; font-style: italic\">That's not ready to analyze right now.</span>"
			else
				last_cdc_message = "<span style=\"color:blue; font-style: italic\">We'll begin the analysis and keep you updated.</span>"
				wagesystem.shipping_budget -= 1000
				if (QM_CDC.current_analysis)
					var/cdc_contact_analysis/A = QM_CDC.current_analysis
					A.time_done += ticker.round_elapsed_ticks - A.begun_at
					if (A.cure_available >= ticker.round_elapsed_ticks)
						QM_CDC.completed_analysis += A
					else
						QM_CDC.ready_to_analyze += A
				QM_CDC.current_analysis = C
				C.begun_at = ticker.round_elapsed_ticks
				C.description_available = C.begun_at + C.time_factor - C.time_done
				C.cure_available = C.description_available + C.time_factor
				QM_CDC.last_switch = C.begun_at

		set_cdc()

	else if (href_list["batch_cure"])
		if (solar_flare)
			boutput(usr, "<span style=\"color:red\">Solar flare activity is preventing contact with the CDC.</span>")
			return
		var/cdc_contact_analysis/C = locate(href_list["batch_cure"])
		if (!(C in QM_CDC.completed_analysis))
			last_cdc_message = "<span style=\"color:red; font-style: italic\">That's not ready to be cured yet.</span>"
		var/count = text2num(href_list["count"])
		var/cost = 0
		switch (count)
			if (1)
				cost = C.cure_cost
			if (5)
				cost = 4 * C.cure_cost
			if (10)
				cost = 7 * C.cure_cost
			else
				last_cdc_message = "<span style=\"color:red; font-style: italic\">No leet haxing, chump.</span>"
		if (cost > 0)
			if (wagesystem.shipping_budget < cost)
				last_cdc_message = "<span style=\"color:red; font-style: italic\">You cannot afford these cures.</span>"
			else
				wagesystem.shipping_budget -= cost
				QM_CDC.working_on = C.assoc_pathogen
				QM_CDC.working_on_time_factor = C.time_factor
				QM_CDC.next_cure_batch = round(rand(175, 233) / 100 * C.time_factor) + ticker.round_elapsed_ticks
				QM_CDC.batches_left = count

		set_cdc()

	else if (href_list["trader_list"])
		if (!shippingmarket.active_traders.len)
			boutput(usr, "<span style=\"color:red\">No traders detected in communications range.</span>")
			return
		if (solar_flare)
			boutput(usr, "<span style=\"color:red\">Solar flare activity is preventing contact with trader vessels.</span>")
			return

		temp = "<strong>Traders Detected in Communications Range:</strong><BR>"
		for (var/trader/T in shippingmarket.active_traders)
			if (!T.hidden)
				temp += "* <A href='?src=\ref[src];trader=\ref[T]'>[T.name]</A><BR>"
		var/timer = shippingmarket.get_market_timeleft()
		temp += {"<BR><HR><strong>Next Market Shift:</strong> [timer]<BR>
					<A href='?src=\ref[src];trader_list=1'>Refresh</A><BR>
					<A href='?src=\ref[src];mainmenu=1'>Main Menu</A>"}

	else if (href_list["trader"])
		var/trader/T = locate(href_list["trader"]) in shippingmarket.active_traders
		if (!trader_sanity_check(T))
			return
		var/timer = shippingmarket.get_market_timeleft()

		temp = {"<strong><u>[T.name]</u></strong><HR>
					<center><img src="[resource("images/traders/[T.picture]")]"></center><BR>
					<center>\"[T.current_message]\"</center><BR><HR><BR>
					<BR><HR><strong>Next Market Shift:</strong> [timer]<BR>
					<A href='?src=\ref[src];trader=\ref[T]'>Refresh</A><BR>"}

		if (T.goods_sell.len)
			temp += "<A href='?src=\ref[src];trader_selling=\ref[T]'>Browse Goods for Sale</A> ([T.goods_sell.len] Items)<BR>"
		if (T.goods_buy.len)
			temp += "<A href='?src=\ref[src];trader_buying=\ref[T]'>Browse Wanted Goods</A> ([T.goods_buy.len] Items)<BR>"
		if (T.shopping_cart.len)
			temp += {"<A href='?src=\ref[src];trader_cart=\ref[T]'>View Shopping Cart</A> ([T.shopping_cart.len] Items)<BR>
							<A href='?src=\ref[src];trader_buy_cart=\ref[T]'>Purchase Items in Cart</A><BR>"}

		temp += {"<A href='?src=\ref[src];trader_list=1'>Trader List</A><BR>
					<A href='?src=\ref[src];mainmenu=1'>Main Menu</A>"}

	else if (href_list["trader_selling"])
		var/trader/T = locate(href_list["trader_selling"]) in shippingmarket.active_traders
		if (!trader_sanity_check(T))
			return

		trader_dialogue_update("selling",T)

	else if (href_list["trader_buying"])
		var/trader/T = locate(href_list["trader_buying"]) in shippingmarket.active_traders
		if (!trader_sanity_check(T))
			return

		trader_dialogue_update("buying",T)

	else if (href_list["trader_cart"])
		var/trader/T = locate(href_list["trader_cart"]) in shippingmarket.active_traders
		if (!trader_sanity_check(T))
			return

		trader_dialogue_update("cart",T)

	else if (href_list["goods_addtocart"])
		var/trader/T = locate(href_list["the_trader"]) in shippingmarket.active_traders
		if (!trader_sanity_check(T))
			return
		var/commodity/C = locate(href_list["goods_addtocart"]) in T.goods_sell
		if (!commodity_sanity_check(C))
			return
		if (in_dialogue_box)
			return

		if (C.amount == 0)
			T.current_message = pick(T.dialogue_out_of_stock)
			updateUsrDialog()
			return

		var/buy_cap = 20
		var/total_stuff_in_cart = 0

		if (shippingmarket && istype(shippingmarket,/shipping_market))
			buy_cap = shippingmarket.max_buy_items_at_once
		else
			logTheThing("debug", null, null, "<strong>ISN/Trader:</strong> Shippingmarket buy cap improperly configured")

		for (var/commodity/cartcom in T.shopping_cart)
			total_stuff_in_cart += cartcom.amount

		if (total_stuff_in_cart >= buy_cap)
			boutput(usr, "<span style=\"color:red\">You may only have a maximum of [buy_cap] items in your shopping cart. You have already reached that limit.</span>")
			return

		in_dialogue_box = 1
		var/howmany = input("How many units do you want to purchase?", "Trader Purchase", null, null) as num
		if (howmany < 1)
			in_dialogue_box = 0
			return
		if (C.amount > 0 && howmany > C.amount)
			howmany = C.amount

		if (howmany + total_stuff_in_cart > buy_cap)
			boutput(usr, "<span style=\"color:red\">You may only have a maximum of [buy_cap] items in your shopping cart. This order would exceed that limit.</span>")
			in_dialogue_box = 0
			return

		var/commodity/trader/incart/newcart = new /commodity/trader/incart(T)
		T.shopping_cart += newcart
		newcart.reference = C
		newcart.comname = C.comname
		newcart.amount = howmany
		newcart.price = C.price
		newcart.comtype = C.comtype
		if (C.amount > 0) C.amount -= howmany
		trader_dialogue_update("selling",T)
		in_dialogue_box = 0

	else if (href_list["goods_haggle_sell"])
		var/trader/T = locate(href_list["the_trader"]) in shippingmarket.active_traders
		if (!trader_sanity_check(T))
			return
		var/commodity/C = locate(href_list["goods_haggle_sell"]) in T.goods_sell
		if (!commodity_sanity_check(C))
			return
		if (in_dialogue_box)
			return

		if (T.patience <= 0)
			// whoops, you've pissed them off and now they're going to fuck off
			temp = {"<center><img src="[resource("images/traders/[T.picture]")]"></center><BR>
						<center>\"[pick(T.dialogue_leave)]\"</center><BR><BR>
						[T.name] has left. You pushed their patience too far!<BR>
						<BR><A href='?src=\ref[src];mainmenu=1'>Ok</A>"}
			updateUsrDialog()
			T.hidden = 1
			return

		in_dialogue_box = 1
		var/haggling = input("Suggest a new lower price.", "Haggle", null, null)  as null|num
		if (haggling < 1)
			// yeah sure let's reduce the barter into negative numbers, herp derp
			boutput(usr, "<span style=\"color:red\">That doesn't even make any sense!</span>")
			in_dialogue_box = 0
			return
		T.haggle(C,haggling,1)
		trader_dialogue_update("selling",T)
		in_dialogue_box = 0

	else if (href_list["goods_haggle_buy"])
		var/trader/T = locate(href_list["the_trader"]) in shippingmarket.active_traders
		if (!trader_sanity_check(T))
			return
		var/commodity/C = locate(href_list["goods_haggle_buy"]) in T.goods_buy
		if (!commodity_sanity_check(C))
			return
		if (in_dialogue_box)
			return

		if (T.patience == 0)
			// whoops, you've pissed them off and now they're going to fuck off
			// unless they've got negative patience in which case haggle all you like
			temp = {"<center><img src="[resource("images/traders/[T.picture]")]"></center><BR>
						<center>\"[pick(T.dialogue_leave)]\"</center><BR><BR>
						[T.name] has left. You pushed their patience too far!<BR>
						<BR><A href='?src=\ref[src];mainmenu=1'>Ok</A>"}
			updateUsrDialog()
			T.hidden = 1
			return

		in_dialogue_box = 1
		var/haggling = input("Suggest a new higher price.", "Haggle", null, null)  as null|num
		if (haggling < 1)
			// yeah sure let's reduce the barter into negative numbers, herp derp
			boutput(usr, "<span style=\"color:red\">That doesn't even make any sense!</span>")
			in_dialogue_box = 0
			return
		T.haggle(C,haggling,0)
		trader_dialogue_update("buying",T)
		in_dialogue_box = 0

	else if (href_list["goods_removefromcart"])
		var/trader/T = locate(href_list["the_trader"]) in shippingmarket.active_traders
		if (!trader_sanity_check(T))
			return
		var/commodity/trader/incart/C = locate(href_list["goods_removefromcart"]) in T.shopping_cart
		if (!commodity_sanity_check(C))
			return

		var/howmany = input("Remove how many units?", "Remove from Cart", null, null) as num
		if (howmany < 1)
			return
		howmany = max(0,min(howmany,C.amount))

		C.amount -= howmany

		if (C.reference && istype(C.reference,/commodity/trader))
			if (C.reference.amount > -1)
				C.reference.amount += howmany

		if (C.amount < 1)
			T.shopping_cart -= C
			qdel (C)
		trader_dialogue_update("cart",T)

	else if (href_list["trader_buy_cart"])
		var/trader/T = locate(href_list["trader_buy_cart"]) in shippingmarket.active_traders
		if (!trader_sanity_check(T))
			return

		if (!T.shopping_cart.len)
			boutput(usr, "<span style=\"color:red\">There's nothing in the shopping cart to buy!</span>")
			return

		var/cart_cost = 0
		var/total_cart_amount = 0
		for (var/commodity/C in T.shopping_cart)
			cart_cost += C.price * C.amount
			total_cart_amount += C.amount

		var/buy_cap = 20

		if (shippingmarket && istype(shippingmarket,/shipping_market))
			buy_cap = shippingmarket.max_buy_items_at_once
		else
			logTheThing("debug", null, null, "<strong>ISN/Trader:</strong> Shippingmarket buy cap improperly configured")

		if (total_cart_amount > buy_cap)
			boutput(usr, "<span style=\"color:red\">There are too many items in the cart. You may only order [buy_cap] items at a time.</span>")
		else
			if (wagesystem.shipping_budget < cart_cost)
				T.current_message = pick(T.dialogue_cant_afford_that)
			else
				T.current_message = pick(T.dialogue_purchase)
				buy_from_trader(T)
		trader_dialogue_update("cart",T)

	else if (href_list["trader_clr_cart"])
		var/trader/T = locate(href_list["trader_clr_cart"]) in shippingmarket.active_traders
		if (!trader_sanity_check(T))
			return

		T.wipe_cart()
		trader_dialogue_update("cart",T)

	else if (href_list["rreq"])
		supply_requestlist -= locate(href_list["rreq"])
		temp = {"Request removed.<BR>
					<BR><A href='?src=\ref[src];viewrequests=1'>OK</A>"}

	else if (href_list["clearreq"])
		supply_requestlist = null
		supply_requestlist = new/list()
		temp = {"List cleared.<BR>
					<BR><A href='?src=\ref[src];mainmenu=1'>OK</A>"}

	else if (href_list["mainmenu"])
		temp = null

	add_fingerprint(usr)
	updateUsrDialog()
	return

/obj/machinery/computer/supplycomp/proc/trader_dialogue_update(var/dialogue,var/trader/T)
	if (!dialogue || !T)
		return

	temp = {"<strong><u>[T.name]</u></strong><HR>
				<center><img src="[resource("images/traders/[T.picture]")]"></center><BR>
				<center>\"[T.current_message]\"</center><BR><HR>"}

	switch(dialogue)
		if ("cart")
			if (!T.shopping_cart.len)
				temp += "There is nothing in your shopping cart with this trader!"
			else if (T.currently_selling)
				temp += "Your order is now being processed!"
			else
				var/cart_price = 0
				temp += "<strong>You are considering purchase of the following goods:</strong><BR>"
				for (var/commodity/C in T.shopping_cart)
					temp += "[C.amount] units of [C.comname], [C.price * C.amount] credits <A href='?src=\ref[src];goods_removefromcart=\ref[C];the_trader=\ref[T]'>(Remove)</A><BR>"
					cart_price += C.price * C.amount
				temp += "<BR><strong>The total price of this purchase is [cart_price] credits.</strong>"
			var/timer = shippingmarket.get_market_timeleft()
			temp +=  {"<BR><HR>
						<strong>Next Market Shift:</strong> [timer]<BR>
						<strong>Shipping Budget:</strong> [wagesystem.shipping_budget] Credits<BR><BR>"}

			if (T.shopping_cart.len && !T.currently_selling)
				temp += {"<A href='?src=\ref[src];trader_buy_cart=\ref[T]'>Purchase</A><BR>
							<A href='?src=\ref[src];trader_clr_cart=\ref[T]'>Empty Shopping Cart</A><BR>"}
			//temp += "<A href='?src=\ref[src];trader_cart=\ref[T]'>Refresh</A><BR>"
			temp += {"<A href='?src=\ref[src];trader=\ref[T]'>Back</A><BR>
						<A href='?src=\ref[src];trader_list=1'>Trader List</A><BR>
						<A href='?src=\ref[src];mainmenu=1'>Main Menu</A>"}
		if ("buying")
			temp += "<strong>The trader would like to purchase the following goods:</strong><BR>"
			for (var/commodity/trader/C in T.goods_buy)
				if (C.hidden)
					continue
				temp += "* [C.listed_name]<BR>"
				temp += " ([C.price] per unit)"
				if (C.amount >= 0)
					temp += " ([C.amount] units left)"
				temp += " <BR><A href='?src=\ref[src];goods_haggle_buy=\ref[C];the_trader=\ref[T]'>(Haggle Price)</A></em><BR><BR>"
			var/timer = shippingmarket.get_market_timeleft()

			temp += {"To sell goods to this trader, label a crate <strong>trader</strong> with a barcode label and fire it out of the sale mass driver.<BR>
						Load no more than 50 items into a crate at once, or the trader's cargo computer may not be able to keep up!
						<BR><HR>"
						<strong>Next Market Shift:</strong> [timer]<BR>
						<strong>Shipping Budget:</strong> [wagesystem.shipping_budget] Credits<BR><BR>
						<A href='?src=\ref[src];trader=\ref[T]'>Back</A><BR>
						<A href='?src=\ref[src];trader_list=1'>Trader List</A><BR>
						<A href='?src=\ref[src];mainmenu=1'>Main Menu</A>"}
		if ("selling")
			temp += "<strong>The trader has the following goods for sale:</strong><BR>"
			for (var/commodity/trader/C in T.goods_sell)
				if (C.hidden)
					continue
				temp += "* [C.listed_name]<BR>"
				temp += "([C.price] credits per unit)"
				if (C.amount >= 0)
					temp += " ([C.amount] units left)"
				temp += " <em><A href='?src=\ref[src];goods_addtocart=\ref[C];the_trader=\ref[T]'>(Add to Cart)</A> <A href='?src=\ref[src];goods_haggle_sell=\ref[C];the_trader=\ref[T]'>(Haggle Price)</A></em><BR><BR>"

			var/timer = shippingmarket.get_market_timeleft()
			temp += {"<HR>
						<strong>Next Market Shift:</strong> [timer]<BR>
						<strong>Shipping Budget:</strong> [wagesystem.shipping_budget] Credits<BR><BR>
						<A href='?src=\ref[src];trader=\ref[T]'>Back</A><BR>
						<A href='?src=\ref[src];trader_list=1'>Trader List</A><BR>
						[T.shopping_cart.len ? "<A href='?src=\ref[src];trader_cart=\ref[T]'>View Shopping Cart</A> ([T.shopping_cart.len] Items)<BR>" : null]
						<A href='?src=\ref[src];mainmenu=1'>Main Menu</A>"}

/obj/machinery/computer/supplycomp/proc/trader_sanity_check(var/trader/T)
	if (!T)
		temp = {"Error contacting trader. They may have departed from communications range.<BR>
					<A href='?src=\ref[src];mainmenu=1'>Main Menu</A>"}
		return FALSE
	if (!istype(T,/trader))
		temp = {"Error contacting trader. They may have departed from communications range.<BR>
					<A href='?src=\ref[src];mainmenu=1'>Main Menu</A>"}
		return FALSE
	if (T.hidden)
		temp = {"Error contacting trader. They may have departed from communications range.<BR>
					<A href='?src=\ref[src];mainmenu=1'>Main Menu</A>"}
		return FALSE
	if (solar_flare)
		temp = {"Solar flare activity is preventing contact with [T.name].<BR>
					<A href='?src=\ref[src];mainmenu=1'>Main Menu</A>"}
		return FALSE
	return TRUE

/obj/machinery/computer/supplycomp/proc/commodity_sanity_check(var/commodity/C)
	if (!C)
		boutput(usr, "<span style=\"color:red\">Something has gone wrong trying to access this commodity! Report this please!</span>")
		return FALSE
	if (!istype(C,/commodity))
		boutput(usr, "<span style=\"color:red\">Something has gone wrong trying to access this commodity! Report this please!</span>")
		return FALSE
	return TRUE

/obj/machinery/computer/supplycomp/proc/post_signal(var/command)

	var/radio_frequency/frequency = radio_controller.return_frequency("1435")

	if (!frequency) return

	var/signal/status_signal = get_free_signal()
	status_signal.source = src
	status_signal.transmission_method = 1
	status_signal.data["command"] = command

	frequency.post_signal(src, status_signal)