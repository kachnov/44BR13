/obj/machinery/computer/ordercomp
	name = "Supply Request Console"
	icon = 'icons/obj/computer.dmi'
	icon_state = "QMreq"
	var/temp = null
	var/obj/item/card/id/scan = null
	var/console_location = null

	New()
		..()
		console_location = get_area(src)
		return

/obj/machinery/computer/ordercomp/attackby(I as obj, user as mob)
	return attack_hand(user)

/obj/machinery/computer/ordercomp/attack_ai(var/mob/user as mob)
	boutput(user, "<span style=\"color:red\">AI Interfacing with this computer has been disabled.</span>")
	return

/obj/machinery/computer/ordercomp/attack_hand(var/mob/user as mob)
	if (..())
		return
	user.machine = src
	var/dat
	if (temp)
		dat = temp
	else

		dat += {"<strong>Supply Ordering Console</strong><HR>
		<strong>Shipping Budget:</strong> [wagesystem.shipping_budget] Credits<BR>
		<strong>Scanned Card:</strong> <A href='?src=\ref[src];card=1'>([scan])</A><BR><HR>"}
		if (scan != null)
			var/data/record/account = null
			account = FindBankAccountByName(scan.registered)
			if (account)
				dat += "<strong>Credits on Account:</strong> [account.fields["current_money"]] Credits<BR><HR>"
		dat += {"<A href='?src=\ref[src];viewrequests=1'>View Requests</A><BR>
		<A href='?src=\ref[src];order=1'>Request Items</A><BR>
		<A href='?src=\ref[src];buypoints=1'>Purchase Supply Points</A><BR>
		<A href='?action=mach_close&window=computer'>Close</A>"}
		//<A href='?src=\ref[src];vieworders=1'>View Approved Orders</A><BR><BR> This right here never worked anyway.
	user << browse(dat, "window=computer;size=575x450")
	onclose(user, "computer")
	return

/obj/machinery/computer/ordercomp/attackby(var/obj/item/I as obj, user as mob)
	if (istype(I, /obj/item/card/id))
		boutput(user, "<span style=\"color:blue\">You swipe the ID card.</span>")
		var/data/record/account = null
		account = FindBankAccountByName(I:registered)
		if (account)
			var/enterpin = input(user, "Please enter your PIN number.", "Order Console", 0) as null|num
			if (enterpin == I:pin)
				boutput(user, "<span style=\"color:blue\">Card authorized.</span>")
				scan = I
			else
				boutput(user, "<span style=\"color:red\">Pin number incorrect.</span>")
				scan = null
		else
			boutput(user, "<span style=\"color:red\">No bank account associated with this ID found.</span>")
			scan = null
	else attack_hand(user)
	return

/obj/machinery/computer/ordercomp/Topic(href, href_list)
	if (..())
		return

	if ((usr.contents.Find(src) || (in_range(src, usr) && istype(loc, /turf))) || (istype(usr, /mob/living/silicon)))
		usr.machine = src

	if (href_list["order"])
		var/data/record/account = null
		if (scan) account = FindBankAccountByName(scan.registered)
		if (account)
			temp = "<strong>Credits on Account:</strong> [account.fields["current_money"]] Credits<BR><HR>"
		else
			temp = "<strong>Shipping Budget:</strong> [wagesystem.shipping_budget] Credits<BR><HR>"
		temp += "<strong>Please select the Supply Package you would like to request:</strong><BR><BR>"
		for (var/supply_packs/S in qm_supply_cache)
			if (S.hidden || S.syndicate) continue //Well, let's not emag this.
			temp += {"<A href='?src=\ref[src];doorder=\ref[S]'><strong><U>[S.name]</U></strong></A><BR>
			<strong>Cost:</strong> [S.cost] Credits<BR>
			<strong>Contents:</strong> [S.desc]<BR><BR>"}
		temp += "<BR><A href='?src=\ref[src];mainmenu=1'>OK</A>"

	else if (href_list["doorder"])
		var/data/record/account = null
		if (scan) account = FindBankAccountByName(scan.registered)
		var/supply_order/O = new/supply_order ()
		var/supply_packs/P = locate(href_list["doorder"])
		if (P)
			if (account) //buy it with their money
				if (account.fields["current_money"] < P.cost)
					temp = "Insufficient funds in account. Log out to request purchase using supply budget.<BR>"
				else
					account.fields["current_money"] -= P.cost
					O.object = P
					O.orderedby = usr.name
					O.console_location = console_location
					process_supply_order(O)
					temp = "Your order has been processed and will be delivered shortly.<BR>"
					supply_history += "[O.object.name] ordered by [O.orderedby] for [P.cost] credits from personal account.<BR>"

					// pda alert ////////
					var/radio_frequency/transmit_connection = radio_controller.return_frequency("1149")
					var/signal/pdaSignal = get_free_signal()
					pdaSignal.data = list("address_1"="00000000", "command"="text_message", "sender_name"="CARGO-MAILBOT",  "group"="cargo", "sender"="00000000", "message"="Notification: [O.object] ordered by [O.orderedby] using personal account at [O.console_location].")
					pdaSignal.transmission_method = TRANSMISSION_RADIO
					if (transmit_connection != null)
						transmit_connection.post_signal(src, pdaSignal)
					//////////////////
			else
				O.object = P
				O.orderedby = usr.name
				O.console_location = console_location
				supply_requestlist += O
				temp = "Request sent to Supply Console. The Quartermasters will process your request as soon as possible.<BR>"

				// pda alert ////////
				var/radio_frequency/transmit_connection = radio_controller.return_frequency("1149")
				var/signal/pdaSignal = get_free_signal()
				pdaSignal.data = list("address_1"="00000000", "command"="text_message", "sender_name"="CARGO-MAILBOT",  "group"="cargo", "sender"="00000000", "message"="Notification: [O.object] requested by [O.orderedby] at [O.console_location].")
				pdaSignal.transmission_method = TRANSMISSION_RADIO
				if (transmit_connection != null)
					transmit_connection.post_signal(src, pdaSignal)
				//////////////////
		else
			temp = "Communications error with central supply console. Please notify a Certified Service Technician.<BR>"
		temp += {"<BR><A href='?src=\ref[src];mainmenu=1'>Main Menu</A>
					<BR><A href='?src=\ref[src];order=1'>Back to Order List</A>"}

	else if (href_list["viewrequests"])
		temp = "<strong>Current Requests:</strong><BR><BR>"
		for (var/S in supply_requestlist)
			var/supply_order/SO = S
			temp += "[SO.object.name] requested by [SO.orderedby] from [SO.console_location].<BR>"
		temp += "<BR><A href='?src=\ref[src];mainmenu=1'>OK</A>"

	else if (href_list["card"])
		if (scan) scan = null
		else
			var/obj/item/I = usr.equipped()
			if (istype(I, /obj/item/card/id))
				boutput(usr, "<span style=\"color:blue\">You swipe the ID card.</span>")
				var/data/record/account = null
				account = FindBankAccountByName(I:registered)
				if (account)
					var/enterpin = input(usr, "Please enter your PIN number.", "Order Console", 0) as null|num
					if (enterpin == I:pin)
						boutput(usr, "<span style=\"color:blue\">Card authorized.</span>")
						scan = I
					else
						boutput(usr, "<span style=\"color:red\">Pin number incorrect.</span>")
						scan = null
				else
					boutput(usr, "<span style=\"color:red\">No bank account associated with this ID found.</span>")
					scan = null
			else
				temp = "There is no card scan to log out.<BR>"
				temp += "<BR><A href='?src=\ref[src];mainmenu=1'>OK</A>"

	else if (href_list["buypoints"])

		if (scan)
			var/data/record/account = null
			account = FindBankAccountByName(scan.registered)
			if (!account)
				temp = {"<strong>ERROR:</strong> No bank account associated with this ID card found.<BR>
							<BR><A href='?src=\ref[src];mainmenu=1'>OK</A>"}
			else
				temp = {"<strong>Contribute to Shipping Budget</strong><BR>
							<strong>Shipping Budget:</strong> [wagesystem.shipping_budget] Credits<BR>
							<strong>Credits in Account:</strong> [account.fields["current_money"]] Credits<BR><HR>
							<A href='?src=\ref[src];buy=1'>Make Transaction</A><BR>
							<A href='?src=\ref[src];mainmenu=1'>Cancel Purchase</A>"}
		else
			temp = {"You need to swipe an ID card first!<BR>
						<BR><A href='?src=\ref[src];mainmenu=1'>OK</A>"}

	else if (href_list["buy"])
		if (scan)
			if (scan.registered in FrozenAccounts)
				boutput(usr, "<span style=\"color:red\">Your account cannot currently be liquidated due to active borrows.</span>")
				return
			var/data/record/account = null
			account = FindBankAccountByName(scan.registered)
			if (!account)
				temp = {"<strong>ERROR:</strong> No bank account associated with this ID card found.<BR>
							<BR><A href='?src=\ref[src];mainmenu=1'>OK</A>"}
			var/transaction = input("How much?", "Shipping Budget", null, null)  as null|num
			if (account.fields["current_money"] >= transaction && (transaction > 0))
				account.fields["current_money"] -= transaction
				wagesystem.shipping_budget += transaction
				temp = "Transaction successful. Thank you for your patronage.<BR>"
				////// PDA NOTIFY/////
				var/radio_frequency/transmit_connection = radio_controller.return_frequency("1149")
				var/signal/pdaSignal = get_free_signal()
				pdaSignal.data = list("address_1"="00000000", "command"="text_message", "sender_name"="CARGO-MAILBOT",  "group"="cargo", "sender"="00000000", "message"="Notification: [transaction] credits transfered to shipping budget from [scan.registered].")
				pdaSignal.transmission_method = TRANSMISSION_RADIO
				if (transmit_connection != null)
					transmit_connection.post_signal(src, pdaSignal)
				//////////
				temp += "<BR><A href='?src=\ref[src];mainmenu=1'>OK</A>"
			else
				temp = {"<strong>ERROR:</strong> Insufficient funds. Purchase cancelled.<BR>
							<BR><A href='?src=\ref[src];mainmenu=1'>OK</A>"}
		else
			temp = {"<strong>ERROR:</strong> Login removed mid-transaction. Purchase cancelled.<BR>
							<BR><A href='?src=\ref[src];mainmenu=1'>OK</A>"}

	else if (href_list["mainmenu"])
		temp = null
	add_fingerprint(usr)
	updateUsrDialog()
	return