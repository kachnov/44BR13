/obj/machinery/computer/research

/obj/machinery/computer/research/disease
	name = "Disease Database"
	icon_state = "resdis"
	req_access = list(access_tox)
	var/obj/item/card/id/scan = null
	var/authenticated = null
	var/rank = null
	var/screen = null
	var/data/record/active1 = null
	var/data/record/active2 = null
	var/a_id = null
	var/temp = null
	var/printing = null

/obj/machinery/computer/research/disease/attack_ai(user as mob)
	return attack_hand(user)

/obj/machinery/computer/research/disease/attack_hand(mob/user as mob)
	if (..())
		return

	user.machine = src

	var/dat
	if (temp)
		dat = {"
<TT>[temp]</TT><BR><BR><A href='?src=\ref[src];temp=1'>Clear Screen</A>
"}
	else
		dat = {"
Confirm Identity: <A href='?src=\ref[src];scan=1'>[src.scan ? src.scan.name : "----------"]</A><HR>
"}
		if (authenticated)
			switch(screen)
				if (1.0)
					dat += {"
<strong>Tier [disease_research.tier] Disease Research</strong>
<HR>
"}
					if (disease_research.is_researching)
						var/timeleft = disease_research.get_research_timeleft()
						var/text = disease_research.current_research
						dat += "<BR>Current Research: [text ? text : "None"]. ETA: [timeleft ? timeleft : "Completed"]."
					else
						dat += {"<BR>Currently not researching."}
					dat += {"
<BR><BR><A href='?src=\ref[src];screen=2'>Research</A>
<BR>
<BR><A href='?src=\ref[src];screen=3'>Researched Items</A>
<BR>
<BR><A href='?src=\ref[src];logout=1'>{Log Out}</A><BR>
"}

//


				if (2.0)
					dat += {"
<strong>Research List</strong>:<HR><BR>"}

					if (disease_research.check_if_tier_completed() && (disease_research.tier < disease_research.max_tiers))
						dat += "<A href='?src=\ref[src];advt=1'>Advance Research Tier</A>"
					else if (disease_research.check_if_tier_completed())
						dat += "No more research can be conducted<BR>"
					else
						for (var/ailment/a in disease_research.items_to_research[disease_research.tier])
							dat += {"<A href='?src=\ref[src];res=\ref[a]'>[a.name]</A><BR>"}

					dat += {"<HR><A href='?src=\ref[src];screen=1'>Back</A>"}

				if (3.0)
					dat += {"
<strong>Items Researched</strong>:<HR>"}
					for (var/i = disease_research.starting_tier, i <= disease_research.max_tiers, i++)
						dat += {"
<BR><BR><strong>Tier: [i]</strong>
"}
						for (var/a in disease_research.researched_items[i])
							dat += {"
<BR><A href='?src=\ref[src];read=\ref[a]'>[a]</A>
"}
					dat += {"
<HR><BR><A href='?src=\ref[src];screen=1'>Back</A>
"}

				else
		else
			dat += text("<A href='?src=\ref[src];login=1'>{Log In}</A>")
	user << browse(text("<HEAD><TITLE>Disease Research</TITLE></HEAD><TT>[]</TT>", dat), "window=dis_res")
	onclose(user, "dis_res")
	return

/obj/machinery/computer/research/disease/Topic(href, href_list)
	if (..())
		return
	if (!( data_core.general.Find(active1) ))
		active1 = null
	if (!( data_core.medical.Find(active2) ))
		active2 = null
	if ((usr.contents.Find(src) || (in_range(src, usr) && istype(loc, /turf))) || (istype(usr, /mob/living/silicon)))
		usr.machine = src
		if (href_list["temp"])
			temp = null
		if (href_list["scan"])
			if (scan)
				scan.set_loc(loc)
				scan = null
			else
				var/obj/item/I = usr.equipped()
				if (istype(I, /obj/item/card/id))
					usr.drop_item()
					I.set_loc(src)
					scan = I
		else if (href_list["logout"])
			authenticated = null
			screen = null
			active1 = null
			active2 = null
		else if (href_list["login"])
			if (issilicon(usr) && !isghostdrone(usr))
				active1 = null
				active2 = null
				authenticated = 1
				rank = "AI"
				screen = 1
			else if (istype(scan, /obj/item/card/id))
				active1 = null
				active2 = null
				if (check_access(scan))
					authenticated = scan.registered
					rank = scan.assignment
					screen = 1
		if (authenticated)
			if (href_list["screen"])
				screen = text2num(href_list["screen"])
				if (screen < 1)
					screen = 1

				active1 = null
				active2 = null

		if (href_list["advt"])
			disease_research.advance_tier()

		if (href_list["res"])
			var/ailment/researched_item = locate(href_list["res"])
			if (disease_research.start_research(disease_research.tier*1000, researched_item))
				boutput(usr, "<span style=\"color:blue\">Commencing research</span>")
			else
				boutput(usr, "<span style=\"color:blue\">Could not start research</span>")

//		if (href_list["read"])

	add_fingerprint(usr)
	updateUsrDialog()
	return

