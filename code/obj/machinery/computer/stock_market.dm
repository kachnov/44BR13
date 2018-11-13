/obj/machinery/computer/stockexchange
	name = "Stock Exchange"
	icon = 'icons/obj/computer.dmi'
	icon_state = "QMreq"
	var/logged_in = null
	var/vmode = 0

/obj/machinery/computer/stockexchange/proc/balance()
	if (!logged_in)
		return FALSE
	var/data/record/B = FindBankAccountByName(logged_in)
	if (B)
		return B.fields["current_money"]
	return "--- account not found ---"

/obj/machinery/computer/stockexchange/attack_hand(var/mob/user)
	if (..())
		return
	user.machine = src

	var/css={"<style>
.company {
	font-weight: bold;
}
.stable {
	width: 100%
	border: 1px solid black;
	border-collapse: collapse;
}
.stable tr {
	border: none;
}
.stable td, .stable th {
	border-right: 1px solid white;
	border-bottom: 1px solid black;
}
a.updated {
	color: red;
}
</style>"}
	var/dat = "<html><head><title>[station_name()] Stock Exchange</title>[css]</head><body><h2>Stock Exchange</h2>"
	dat += "<em>This is a work in progress. Certain features may not be available.</em><br>"

	if (!logged_in)
		dat += "<span class='user'>Welcome, <strong>NT_Guest</strong></span><br>"
	else
		dat += "<span class='user'>Welcome, <strong>[logged_in]</strong></span> <a href='?src=\ref[src];logout=1'>Log out</a><br><span class='balance'><strong>Your account balance:</strong> [balance()] credits</span><br>"
		for (var/stock/S in stockExchange.last_read)
			var/list/LR = stockExchange.last_read[S]
			if (!(logged_in in LR))
				LR[logged_in] = 0
	dat += "<strong>View mode:</strong> <a href='?src=\ref[src];cycleview=1'>[vmode ? "compact" : "full"]</a>"

	dat += "<h3>Listed stocks</h3>"

	if (vmode == 0)
		for (var/stock/S in stockExchange.stocks)
			var/mystocks = 0
			if (logged_in && (logged_in in S.shareholders))
				mystocks = S.shareholders[logged_in]
			dat += "<hr /><div class='stock'><span class='company'>[S.name]</span> <span class='s_company'>([S.short_name])</span>[S.bankrupt ? " <b style='color:red'>BANKRUPT</strong>" : null]<br>"
			if (S.last_unification)
				dat += "<strong>Unified shares</strong> [(ticker.round_elapsed_ticks - S.last_unification) / 600] minutes ago.<br>"
			dat += "<strong>Current value per share:</strong> [S.current_value] | <a href='?src=\ref[src];viewhistory=\ref[S]'>View history</a><br><br>"
			dat += "You currently own <strong>[mystocks]</strong> shares in this company. There are [S.available_shares] purchasable shares on the market currently.<br>"
			if (S.bankrupt)
				dat += "You cannot buy or sell shares in a bankrupt company!<br><br>"
			else
				dat += "<a href='?src=\ref[src];buyshares=\ref[S]'>Buy shares</a> | <a href='?src=\ref[src];sellshares=\ref[S]'>Sell shares</a><br><br>"
			dat += "<strong>Prominent products:</strong><br>"
			for (var/prod in S.products)
				dat += "<em>[prod]</em><br>"
			dat += "<br><strong>Borrow options:</strong><br>"
			if (S.borrow_brokers.len)
				for (var/borrow/B in S.borrow_brokers)
					dat += "<strong>[B.broker]</strong> offers <em>[B.share_amount] shares</em> for borrowing, for a deposit of <em>[B.deposit * 100]%</em> of the shares' value.<br>"
					dat += "The broker expects the return of the shares after <em>[B.lease_time / 600] minutes</em>, with a grace period of <em>[B.grace_time / 600]</em> minute(s).<br>"
					dat += "<em>This offer expires in [(B.offer_expires - ticker.round_elapsed_ticks) / 600] minutes.</em><br>"
					dat += "<strong>Note:</strong> If you do not return all shares by the end of the grace period, you will lose your deposit and the value of all unreturned shares at current value from your account!<br>"
					dat += "<strong>Note:</strong> You cannot withdraw or transfer money off your account while a borrow is active.<br>"
					dat += "<a href='?src=\ref[src];take=\ref[B]'>Take offer</a> (Estimated deposit: [B.deposit * S.current_value * B.share_amount] credits)<br><br>"
			else
				dat += "<em>No borrow options available</em><br><br>"
			for (var/borrow/B in S.borrows)
				if (B.borrower == logged_in)
					dat += "You are borrowing <em>[B.share_amount] shares</em> from <strong>[B.broker]</strong>.<br>"
					dat += "Your deposit riding on the deal is <em>[B.deposit] credits</em>.<br>"
					if (ticker.round_elapsed_ticks < B.lease_expires)
						dat += "You are expected to return the borrowed shares in [(B.lease_expires - ticker.round_elapsed_ticks) / 600] minutes.<br><br>"
					else
						dat += "The brokering agency is collecting. You still owe them <em>[B.share_debt]</em> shares, which you have [(B.grace_expires - ticker.round_elapsed_ticks) / 600] minutes to present.<br><br>"
			var/news = 0
			if (logged_in)
				var/list/LR = stockExchange.last_read[S]
				var/lrt = LR[logged_in]
				for (var/article/A in S.articles)
					if (A.ticks > lrt)
						news = 1
						break
				if (!news)
					for (var/stockEvent/E in S.events)
						if (E.last_change > lrt && !E.hidden)
							news = 1
							break
			dat += "<a href='?src=\ref[src];archive=\ref[S]'>View news archives</a>[news ? " <span style='color:red'>(updated)</span>" : null]</div>"
	else if (vmode == 1)
		dat += "<strong>Actions:</strong> + Buy, - Sell, (A)rchives, (H)istory<br><br>"
		dat += "<table class='stable'><tr><th>&nbsp;</th><th>Name</th><th>Value</th><th>Owned/Avail</th><th>Actions</th></tr>"
		for (var/stock/S in stockExchange.stocks)
			var/mystocks = 0
			if (logged_in && (logged_in in S.shareholders))
				mystocks = S.shareholders[logged_in]
			dat += "<tr><td>[S.disp_value_change > 0 ? "+" : (S.disp_value_change < 0 ? "-" : "=")]</td><td><span class='company'>[S.name] "
			if (S.bankrupt)
				dat += "<b style='color:red'>B</strong>"
			dat += "</span> <span class='s_company'>([S.short_name])</span></td><td>[S.current_value]</td><td><strong>[mystocks]</strong>/[S.available_shares]</td>"
			var/news = 0
			if (logged_in)
				var/list/LR = stockExchange.last_read[S]
				var/lrt = LR[logged_in]
				for (var/article/A in S.articles)
					if (A.ticks > lrt)
						news = 1
						break
				if (!news)
					for (var/stockEvent/E in S.events)
						if (E.last_change > lrt && !E.hidden)
							news = 1
							break
			dat += "<td>"
			if (S.bankrupt)
				dat += "+ - "
			else
				dat += "<a href='?src=\ref[src];buyshares=\ref[S]'>+</a> <a href='?src=\ref[src];sellshares=\ref[S]'>-</a> "
			dat += "<a href='?src=\ref[src];archive=\ref[S]' class='[news ? "updated" : "default"]'>(A)</a> <a href='?src=\ref[src];viewhistory=\ref[S]'>(H)</a></td></tr>"

	dat += "</body></html>"
	user << browse(dat, "window=computer;size=600x400")
	onclose(user, "computer")
	return

/obj/machinery/computer/stockexchange/attackby(var/obj/item/I as obj, user as mob)
	if (istype(I, /obj/item/card/id))
		var/obj/item/card/id/ID = I
		boutput(user, "<span style=\"color:blue\">You swipe the ID card.</span>")
		var/data/record/account = null
		account = FindBankAccountByName(ID.registered)
		if (account)
			var/enterpin = input(user, "Please enter your PIN number.", "Order Console", 0) as null|num
			if (enterpin == ID.pin)
				boutput(user, "<span style=\"color:blue\">Card authorized.</span>")
				logged_in = ID.registered
			else
				boutput(user, "<span style=\"color:red\">Pin number incorrect.</span>")
				logged_in = null
		else
			boutput(user, "<span style=\"color:red\">No bank account associated with this ID found.</span>")
			logged_in = null
	else attack_hand(user)
	return

/obj/machinery/computer/stockexchange/proc/sell_some_shares(var/stock/S, var/mob/user)
	if (!user || !S)
		return
	var/li = logged_in
	if (!li)
		boutput(user, "<span style='color:red'>No active account on the console!</span>")
		return
	var/b = balance()
	if (!isnum(b))
		boutput(user, "<span style='color:red'>No active account on the console!</span>")
		return
	var/avail = S.shareholders[logged_in]
	if (!avail)
		boutput(user, "<span style='color:red'>This account does not own any shares of [S.name]!</span>")
		return
	var/price = S.current_value
	var/amt = round(input(user, "How many shares? (Have: [avail], unit price: [price])", "Sell shares in [S.name]", 0) as num|null)
	if (!user)
		return
	if (!amt)
		return
	if (!(user in range(1, src)))
		return
	if (li != logged_in)
		return
	b = balance()
	if (!isnum(b))
		boutput(user, "<span style='color:red'>No active account on the console!</span>")
		return
	if (amt > S.shareholders[logged_in])
		boutput(user, "<span style='color:red'>You do not own that many shares!</span>")
		return
	var/total = amt * S.current_value
	if (!S.sellShares(logged_in, amt))
		boutput(user, "<span style='color:red'>Could not complete transaction.</span>")
		return
	boutput(user, "<span style='color:blue'>Sold [amt] shares of [S.name] for [total] credits.</span>")

/obj/machinery/computer/stockexchange/proc/buy_some_shares(var/stock/S, var/mob/user)
	if (!user || !S)
		return
	var/li = logged_in
	if (!li)
		boutput(user, "<span style='color:red'>No active account on the console!</span>")
		return
	var/b = balance()
	if (!isnum(b))
		boutput(user, "<span style='color:red'>No active account on the console!</span>")
		return
	var/avail = S.available_shares
	var/price = S.current_value
	var/canbuy = round(b / price)
	var/amt = round(input(user, "How many shares? (Available: [avail], unit price: [price], can buy: [canbuy])", "Buy shares in [S.name]", 0) as num|null)
	if (!user)
		return
	if (!amt)
		return
	if (!(user in range(1, src)))
		return
	if (li != logged_in)
		return
	b = balance()
	if (!isnum(b))
		boutput(user, "<span style='color:red'>No active account on the console!</span>")
		return
	if (amt > S.available_shares)
		boutput(user, "<span style='color:red'>That many shares are not available!</span>")
		return
	var/total = amt * S.current_value
	if (total > b)
		boutput(user, "<span style='color:red'>Insufficient funds.</span>")
		return
	if (!S.buyShares(logged_in, amt))
		boutput(user, "<span style='color:red'>Could not complete transaction.</span>")
		return
	boutput(user, "<span style='color:blue'>Bought [amt] shares of [S.name] for [total] credits.</span>")

/obj/machinery/computer/stockexchange/proc/do_borrowing_deal(var/borrow/B, var/mob/user)
	if (B.stock.borrow(B, logged_in))
		boutput(user, "<span style='color:blue'>You successfully borrowed [B.share_amount] shares. Deposit: [B.deposit].</span>")
	else
		boutput(user, "<span style='color:red'>Could not complete transaction. Check your account balance.</span>")

/obj/machinery/computer/stockexchange/Topic(href, href_list)
	if (..())
		return TRUE

	if (usr in range(1, src))
		usr.machine = src

	if (href_list["viewhistory"])
		var/stock/S = locate(href_list["viewhistory"])
		if (S)
			S.displayValues(usr)

	if (href_list["logout"])
		logged_in = null

	if (href_list["buyshares"])
		var/stock/S = locate(href_list["buyshares"])
		if (S)
			buy_some_shares(S, usr)

	if (href_list["sellshares"])
		var/stock/S = locate(href_list["sellshares"])
		if (S)
			sell_some_shares(S, usr)

	if (href_list["take"])
		var/borrow/B = locate(href_list["take"])
		if (B && !B.lease_expires)
			do_borrowing_deal(B, usr)

	if (href_list["archive"])
		var/stock/S = locate(href_list["archive"])
		if (logged_in && logged_in != "")
			var/list/LR = stockExchange.last_read[S]
			LR[logged_in] = ticker.round_elapsed_ticks
		var/dat = "<html><head><title>News feed for [S.name]</title></head><body><h2>News feed for [S.name]</h2><div><a href='?src=\ref[src];archive=\ref[S]'>Refresh</a></div>"
		dat += "<div><h3>Events</h3>"
		var/p = 0
		for (var/stockEvent/E in S.events)
			if (E.hidden)
				continue
			if (p > 0)
				dat += "<hr>"
			dat += "<div><b style='font-size:1.25em'>[E.current_title]</strong><br>[E.current_desc]</div>"
			p++
		dat += "</div><hr><div><h3>Articles</h3>"
		p = 0
		for (var/article/A in S.articles)
			if (p > 0)
				dat += "<hr>"
			dat += "<div><b style='font-size:1.25em'>[A.headline]</strong><br><em>[A.subtitle]</em><br><br>[A.article]<br>- [A.author], [A.spacetime] (via <em>[A.outlet]</em>)</div>"
			p++
		dat += "</div></body></html>"
		usr << browse(dat, "window=archive_[S.name];size=600x400")

	if (href_list["cycleview"])
		vmode++
		if (vmode > 1)
			vmode = 0

	add_fingerprint(usr)
	updateUsrDialog()
