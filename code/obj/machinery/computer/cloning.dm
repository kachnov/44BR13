//Cloning revival method.
//The pod handles the actual cloning while the computer manages the clone profiles

/obj/machinery/computer/cloning
	name = "Cloning console"
	icon = 'icons/obj/computer.dmi'
	icon_state = "dna"
	req_access = list(access_heads) //Only used for record deletion right now.
	var/obj/machinery/clone_scanner/scanner = null //Linked scanner. For scanning.
	var/obj/machinery/clonepod/pod1 = null //Linked cloning pod.
	var/temp = "Initializing System..."
	var/menu = 1 //Which menu screen to display
	var/list/records = list()
	var/data/record/active_record = null
	var/obj/item/disk/data/floppy/diskette = null //Mostly so the geneticist can steal somebody's identity while pretending to give them a handy backup profile.
	var/held_credit = 5000 // one free clone

	var/allow_dead_scanning = 0 //Can the dead be scanned in the cloner?
	var/portable = 0 //override new() proc and proximity check, for port-a-clones

	old
		icon_state = "old2"
		desc = "With the price of cloning pods nowadays it's not unexpected to skimp on the controller."

		power_change()

			if (stat & BROKEN)
				icon_state = "old2b"
			else
				if ( powered() )
					icon_state = initial(icon_state)
					stat &= ~NOPOWER
				else
					spawn (rand(0, 15))
						icon_state = "old20"
						stat |= NOPOWER

/obj/item/cloner_upgrade
	name = "NecroScan II cloner upgrade module"
	desc = "A circuit module designed to improve cloning machine scanning capabilities to the point where even the deceased may be scanned."
	icon = 'icons/obj/module.dmi'
	icon_state = "cloner_upgrade"
	w_class = 1
	throwforce = 1

/obj/machinery/computer/cloning/New()
	..()
	spawn (5)
		if (portable) return
		scanner = locate(/obj/machinery/clone_scanner, orange(2,src))
		pod1 = locate(/obj/machinery/clonepod, orange(4,src))

		temp = ""
		if (isnull(scanner))
			temp += " <font color=red>SCNR-ERROR</font>"
		if (isnull(pod1))
			temp += " <font color=red>POD1-ERROR</font>"
		else
			pod1.connected = src

		if (temp == "")
			temp = "System ready."
		return
	return

/obj/machinery/computer/cloning/attackby(obj/item/W as obj, mob/user as mob)
	if (wagesystem.clones_for_cash && istype(W, /obj/item/spacecash))
		var/obj/item/spacecash/cash = W
		held_credit += cash.amount
		cash.amount = 0
		user.show_text("<span style=\"color:blue\">You add [cash] to the credit in [src].</span>")
		user.u_equip(W)
		qdel(W)
	else if (istype(W, /obj/item/disk/data/floppy))
		if (!diskette)
			user.drop_item()
			W.set_loc(src)
			diskette = W
			boutput(user, "You insert [W].")
			updateUsrDialog()
			return

	else if ((istype(W, /obj/item/screwdriver)) && ((stat & BROKEN) || !pod1 || !scanner))
		playsound(loc, "sound/items/Screwdriver.ogg", 50, 1)
		if (do_after(user, 20))
			boutput(user, "<span style=\"color:blue\">The broken glass falls out.</span>")
			var/obj/computerframe/A = new /obj/computerframe( loc )
			if (material) A.setMaterial(material)
			new /obj/item/raw_material/shard/glass( loc )
			var/obj/item/circuitboard/cloning/M = new /obj/item/circuitboard/cloning( A )
			for (var/obj/C in src)
				C.set_loc(loc)
			M.records = records
			if (allow_dead_scanning)
				new /obj/item/cloner_upgrade (loc)
			A.circuit = M
			A.state = 3
			A.icon_state = "3"
			A.anchored = 1
			qdel(src)

	else if (istype(W, /obj/item/cloner_upgrade))
		if (allow_dead_scanning)
			boutput(user, "<span style=\"color:red\">There is already an upgrade card installed.</span>")
			return

		user.visible_message("[user] installs [W] into [src].", "You install [W] into [src].")
		allow_dead_scanning = 1
		user.drop_item()
		qdel(W)

	else
		attack_hand(user)
	return

/obj/machinery/computer/cloning/attack_ai(mob/user as mob)
	return attack_hand(user)

/obj/machinery/computer/cloning/attack_hand(mob/user as mob)
	user.machine = src
	add_fingerprint(user)

	if (stat & (BROKEN|NOPOWER))
		return

	var/dat = {"<h3>Cloning System Control</h3>
	<font size=-1><a href='byond://?src=\ref[src];refresh=1'>Refresh</a></font>
	<br><tt>[temp]</tt><br><hr>"}

	switch(menu)
		if (1) //Scan someone
			dat += "<h4>Scanner Functions</h4>"

			if (isnull(scanner))
				dat += "No scanner connected!"
			else
				if (scanner.occupant)
					dat += "<a href='byond://?src=\ref[src];scan=1'>Scan - [scanner.occupant]</a>"
				else
					dat += "Scanner unoccupied"

				dat += "<br>Lock status: <a href='byond://?src=\ref[src];lock=1'>[scanner.locked ? "Locked" : "Unlocked"]</a><BR>"

			dat += {"<h4>Cloning Pod Functions</h4>
					<a href='byond://?src=\ref[src];menu=5'>Genetic Analysis Mode</a><br>
					Status: <strong>[pod1 && pod1.gen_analysis ? "Enabled" : "Disabled"]</strong>
					<h4>Database Functions</h4>
					<a href='byond://?src=\ref[src];menu=2'>View Records</a><br>"}
			if (diskette)
				dat += "<a href='byond://?src=\ref[src];disk=eject'>Eject Disk</a>"


		if (2) //Viewing records
			dat += {"<h4>Current records</h4>
					<a href='byond://?src=\ref[src];menu=1'>Back</a><br><br>"}
			for (var/data/record/R in records)
				dat += "<a href='byond://?src=\ref[src];view_rec=\ref[R]'>[R.fields["id"]]-[R.fields["name"]]</a><br>"

		if (3) //Viewing details of record
			dat += {"<h4>Selected Record</h4>
					<a href='byond://?src=\ref[src];menu=2'>Back</a><br>"}

			if (!active_record)
				dat += "<font color=red>ERROR: Record not found.</font>"
			else
				dat += {"<br><font size=1><a href='byond://?src=\ref[src];del_rec=1'>Delete Record</a></font><br>
						<strong>Name:</strong> [active_record.fields["name"]]<br>"}

				var/obj/item/implant/health/H = locate(active_record.fields["imp"])

				if ((H) && (istype(H)))
					dat += "<strong>Health:</strong> [H.sensehealth()]<br>"
				else
					dat += "<font color=red>Unable to locate implant.</font><br>"

				if (!isnull(diskette))
					dat += {"<a href='byond://?src=\ref[src];disk=load'>Load from disk.</a>
							 | Save: <a href='byond://?src=\ref[src];save_disk=holder'>Complete</a>
							<br>"}
				else
					dat += "<br>" //Keeping a line empty for appearances I guess.

				if (wagesystem.clones_for_cash)
					dat += "Current machine credit: [held_credit]<br>"
				dat += {"<a href='byond://?src=\ref[src];clone=\ref[active_record]'>Clone</a><br>"}

		if (4) //Deleting a record
			if (!active_record)
				menu = 2
			dat = {"[temp]<br>
					<h4>Confirm Record Deletion</h4>
					<strong><a href='byond://?src=\ref[src];del_rec=1'>Yes</a></strong><br>
					<strong><a href='byond://?src=\ref[src];menu=3'>No</a></strong>"}

		if (5) //Advanced genetics analysis
			dat += {"<h4>Advanced Genetic Analysis</h4>
					<a href='byond://?src=\ref[src];menu=1'>Back</a><br>
					<strong>Notice:</strong> Enabling this feature will prompt the attached clone pod to analyze the genetic makeup of the subject during cloning.
					Data will then be sent to any nearby GeneTek scanners and be used to improve their efficiency. The cloning process will be slightly slower as a result.<BR><BR>"}

			if (!pod1.operating)
				if (pod1.gen_analysis)
					dat += {"Enabled<BR>
							<a href='byond://?src=\ref[src];set_analysis=0'>Disable</A><BR>"}
				else
					dat += {"<a href='byond://?src=\ref[src];set_analysis=1'>Enable</A><BR>
							Disabled<BR>"}
			else
				dat += {"Cannot toggle while cloning pod is active. <BR>
						AGA: <strong>[pod1.gen_analysis ? "Enabled" : "Disabled"]</strong>"}

	user << browse(dat, "window=cloning")
	onclose(user, "cloning")
	return

/obj/machinery/computer/cloning/Topic(href, href_list)
	if (..())
		return

	if ((href_list["scan"]) && (!isnull(scanner)))
		scan_mob(scanner.occupant)

		//No locking an open scanner.
	else if ((href_list["lock"]) && (!isnull(scanner)))
		if ((!scanner.locked) && (scanner.occupant))
			scanner.locked = 1
		else
			scanner.locked = 0

	else if (href_list["view_rec"])
		active_record = locate(href_list["view_rec"])
		if ((isnull(active_record.fields["ckey"])) || (active_record.fields["ckey"] == ""))
			qdel(active_record)
			temp = "ERROR: Record Corrupt"
		else
			menu = 3

	else if (href_list["del_rec"])
		if ((!active_record) || (menu < 3))
			return
		if (menu == 3) //If we are viewing a record, confirm deletion
			temp = "Delete record?"
			menu = 4

		else if (menu == 4)
			records.Remove(active_record)
			qdel(active_record)
			temp = "Record deleted."
			menu = 2
/*
			var/obj/item/card/id/C = usr.equipped()
			if (istype(C))
				if (check_access(C))
					records.Remove(active_record)
					qdel(active_record)
					temp = "Record deleted."
					menu = 2
				else
					temp = "Access Denied."
*/
	else if (href_list["disk"]) //Load or eject.
		switch(href_list["disk"])
			if ("load")
				if ((isnull(diskette)) || (diskette.data == ""))
					temp = "Load error."
					updateUsrDialog()
					return

				if (isnull(active_record))
					temp = "Record error."
					menu = 1
					updateUsrDialog()
					return

				if (diskette.data_type == "holder")
					active_record.fields["holder"] = diskette.data
					if (diskette.ue)
						active_record.fields["name"] = diskette.owner

				temp = "Load successful."
			if ("eject")
				if (!isnull(diskette))
					diskette.set_loc(loc)
					diskette = null

	else if (href_list["save_disk"]) //Save to disk!
		if ((isnull(diskette)) || (diskette.read_only) || (isnull(active_record)))
			temp = "Save error."
			updateUsrDialog()
			return

		switch(href_list["save_disk"]) //Save as Ui/Ui+Ue/Se
			if ("holder")
				diskette.data = active_record.fields["holder"]
				diskette.ue = 1
				diskette.data_type = "holder"
		diskette.owner = active_record.fields["name"]
		diskette.name = "data disk - '[diskette.owner]'"
		temp = "Save \[[href_list["save_disk"]]\] successful."

	else if (href_list["refresh"])
		updateUsrDialog()

	else if (href_list["clone"])
		var/data/record/C = locate(href_list["clone"])
		//Look for that player! They better be dead!
		if (!istype(C))
			temp = "Record association error."
			return
		var/mob/selected = find_dead_player("[C.fields["ckey"]]")

//Can't clone without someone to clone.  Or a pod.  Or if the pod is busy. Or full of gibs.
		if (!selected)
			temp = "Unable to initiate cloning cycle." // most helpful error message in THE HISTORY OF THE WORLD
		else if (!pod1)
			temp = "No pod connected."
		else if (pod1.occupant)
			temp = "Pod already in use."
		else if (pod1.mess)
			temp = "Abnormal readings from pod."

		else if (wagesystem.clones_for_cash)
			var/data/record/Ba = FindBankAccountByName(C.fields["name"])
			if (Ba && Ba.fields["current_money"] >= wagesystem.clone_cost)
				if (pod1.growclone(selected, C.fields["name"], C.fields["mind"], C.fields["holder"], C.fields["abilities"] , C.fields["traits"]))
					Ba.fields["current_money"] -= wagesystem.clone_cost
					temp = "[wagesystem.clone_cost] credits removed from [C.fields["name"]]'s account. Cloning cycle activated."
					records.Remove(C)
					qdel(C)
					menu = 1
			else if (held_credit >= wagesystem.clones_for_cash)
				if (pod1.growclone(selected, C.fields["name"], C.fields["mind"], C.fields["holder"], C.fields["abilities"] , C.fields["traits"]))
					held_credit -= wagesystem.clone_cost
					temp = "[wagesystem.clone_cost] credits removed from machine credit. Cloning cycle activated."
					records.Remove(C)
					qdel(C)
					menu = 1
			else
				temp = "Isufficient funds to begin clone cycle."

		else if (pod1.growclone(selected, C.fields["name"], C.fields["mind"], C.fields["holder"], C.fields["abilities"] , C.fields["traits"]))
			temp = "Cloning cycle activated."
			records.Remove(C)
			qdel(C)
			menu = 1

	else if (href_list["menu"])
		menu = text2num(href_list["menu"])
	else if (href_list["set_analysis"])
		pod1.gen_analysis = text2num(href_list["set_analysis"])

	add_fingerprint(usr)
	updateUsrDialog()
	return

/obj/machinery/computer/cloning/proc/scan_mob(mob/living/carbon/human/subject as mob)
	if ((isnull(subject)) || (!istype(subject, /mob/living/carbon/human)))
		temp = "Error: Unable to locate valid genetic data."
		return
	if (!allow_dead_scanning && subject.decomp_stage)
		temp = "Error: Failed to read genetic data from subject.<br>Necrosis of tissue has been detected."
		return
	if (!subject.bioHolder || subject.bioHolder.HasEffect("husk"))
		temp = "Error: Extreme genetic degredation present."
		return

	var/mind/subjMind = subject.mind
	if ((!subjMind) || (!subjMind.key))
		if (subject.ghost && subject.ghost.mind && subject.ghost.mind.key)
			subjMind = subject.ghost.mind
		else
			temp = "Error: Mental interface failure."
			return
	if (!isnull(find_record(ckey(subjMind.key))))
		temp = "Subject already in database."
		return

	var/data/record/R = new /data/record(  )
	R.fields["ckey"] = ckey(subjMind.key)
	R.fields["name"] = subject.real_name
	R.fields["id"] = copytext(md5(subject.real_name), 2, 6)

	var/bioHolder/H = new/bioHolder(null)
	H.CopyOther(subject.bioHolder)

	R.fields["holder"] = H

	R.fields["abilities"] = null
	if (subject.abilityHolder)
		var/abilityHolder/A = subject.abilityHolder.deepCopy()
		R.fields["abilities"] = A

	R.fields["traits"] = list()
	if (subject.traitHolder && subject.traitHolder.traits.len)
		R.fields["traits"] = subject.traitHolder.traits.Copy()

	//Add an implant if needed
	var/obj/item/implant/health/imp = locate(/obj/item/implant/health, subject)
	if (isnull(imp))
		imp = new /obj/item/implant/health(subject)
		imp.implanted = 1
		imp.owner = subject
		subject.implant.Add(imp)
//		imp.implanted = subject // this isn't how this works with new implants sheesh
		R.fields["imp"] = "\ref[imp]"
	//Update it if needed
	else
		R.fields["imp"] = "\ref[imp]"

	if (!isnull(subjMind)) //Save that mind so traitors can continue traitoring after cloning.
		R.fields["mind"] = subjMind

	records += R
	temp = "Subject successfully scanned."

//Find a specific record by key.
/obj/machinery/computer/cloning/proc/find_record(var/find_key)
	var/selected_record = null
	for (var/data/record/R in records)
		if (R.fields["ckey"] == find_key)
			selected_record = R
			break
	return selected_record

/obj/machinery/computer/cloning/power_change()

	if (stat & BROKEN)
		icon_state = "commb"
	else
		if ( powered() )
			icon_state = initial(icon_state)
			stat &= ~NOPOWER
		else
			spawn (rand(0, 15))
				icon_state = "c_unpowered"
				stat |= NOPOWER


//New loading/storing records is a todo while I determine how it should work.
/obj/machinery/computer/cloning/proc
	load_record()
		if (!diskette || !diskette.root)
			return -1


		return FALSE

	save_record()
		if (!diskette || !diskette.root)
			return -1



		return FALSE


//Find a dead mob with a brain and client.
/proc/find_dead_player(var/find_key, needbrain=0)
	if (isnull(find_key))
		return

	var/mob/selected = null
	for (var/mob/M in mobs)
		//Dead people only thanks!
		if ((M.stat != 2) || (!M.client))
			continue
		//They need a brain!
		if (needbrain && ishuman(M) && !M:brain)
			continue

		if (M.ckey == find_key)
			selected = M
			break
	return selected

/obj/machinery/clone_scanner
	name = "Cloning machine scanner"
	icon = 'icons/obj/Cryogenic2.dmi'
	icon_state = "scanner_0"
	density = 1
	mats = 15
	var/locked = 0.0
	var/mob/occupant = null
	anchored = 1.0
	soundproofing = 10

	allow_drop()
		return FALSE

	verb/move_inside()
		set src in oview(1)
		set category = "Local"

		if (usr.stat != 0)
			return

		if (occupant)
			boutput(usr, "<span style=\"color:blue\"><strong>The scanner is already occupied!</strong></span>")
			return

		usr.pulling = null
		usr.set_loc(src)
		occupant = usr
		icon_state = "scanner_1"

		for (var/obj/O in src)
			qdel(O)

		add_fingerprint(usr)
		return

	attackby(var/obj/item/grab/G as obj, user as mob)
		if ((!( istype(G, /obj/item/grab) ) || !( ismob(G.affecting) )))
			return

		if (occupant)
			boutput(user, "<span style=\"color:blue\"><strong>The scanner is already occupied!</strong></span>")
			return

		var/mob/M = G.affecting
		M.set_loc(src)
		occupant = M
		icon_state = "scanner_1"

		for (var/obj/O in src)
			O.set_loc(loc)

		add_fingerprint(user)
		qdel(G)
		return

	verb/eject()
		set src in oview(1)
		set category = "Local"

		if (usr.stat != 0)
			return

		go_out()
		add_fingerprint(usr)
		return

	proc/go_out()
		if ((!( occupant ) || locked))
			return

		for (var/obj/O in src)
			O.set_loc(loc)

		occupant.set_loc(loc)
		occupant = null
		icon_state = "scanner_0"
		return