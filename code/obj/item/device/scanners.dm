/*
Contains:

-T-ray scanner
-Forensic scanner
-Health analyzer
-Reagent scanner
-Atmospheric analyzer
-Prisoner scanner
*/

//////////////////////////////////////////////// T-ray scanner //////////////////////////////////

/obj/item/device/t_scanner
	name = "T-ray scanner"
	desc = "A terahertz-ray emitter and scanner used to detect underfloor objects such as cables and pipes."
	icon_state = "t-ray0"
	var/on = 0
	flags = FPRINT|ONBELT|TABLEPASS
	w_class = 2
	item_state = "electronic"
	m_amt = 150
	mats = 5
	module_research = list("analysis" = 2, "engineering" = 2, "devices" = 1)
	module_research_type = /obj/item/device/t_scanner

/obj/item/device/t_scanner/attack_self(mob/user)

	on = !on
	icon_state = "t-ray[on]"

	if (on && !(src in processing_items))
		processing_items.Add(src)


/obj/item/device/t_scanner/process()
	if (!on)
		processing_items.Remove(src)
		return null

	for (var/turf/T in range(1, loc) )

		if (!T.intact)
			continue

		for (var/obj/O in T.contents)

			if (O.level != 1)
				continue

			if (O.invisibility == 101)
				O.invisibility = 0
				spawn (10)
					if (O && isturf(O.loc))
						var/turf/U = O.loc
						if (U.intact)
							O.invisibility = 101

		var/mob/living/M = locate() in T
		if (M && M.invisibility == 2)
			M.invisibility = 0
			spawn (6)
				if (M)
					M.invisibility = 2

//////////////////////////////////////// Forensic scanner ///////////////////////////////////

/obj/item/device/detective_scanner
	name = "forensic scanner"
	desc = "Used to scan objects for DNA and fingerprints."
	icon_state = "forensicscanner"
	w_class = 2 // PDA fits in a pocket, so why not the dedicated scanner (Convair880)?
	item_state = "electronic"
	flags = FPRINT | TABLEPASS | ONBELT | CONDUCT | SUPPRESSATTACK
	mats = 3

	attack_self(mob/user as mob)

		add_fingerprint(user)

		var/search = input(user, "Enter name, fingerprint or blood DNA.", "Find record", "") as null|text
		if (!search || user.stat)
			return
		search = copytext(sanitize(search), 1, 200)
		search = lowertext(search)

		for (var/data/record/R in REPO.data_core.general)
			if (search == lowertext(R.fields["dna"]) || search == lowertext(R.fields["fingerprint"]) || search == lowertext(R.fields["name"]))

				var/data = "--------------------------------<br>\
				<font color='blue'>Match found in security records:<strong> [R.fields["name"]]</strong> ([R.fields["rank"]])</font><br>\
				<br>\
				<em>Fingerprint:</em><font color='blue'> [R.fields["fingerprint"]]</font><br>\
				<em>Blood DNA:</em><font color='blue'> [R.fields["dna"]]</font>"

				boutput(user, data)
				return

		user.show_text("No match found in security records.", "red")
		return

	afterattack(atom/A as mob|obj|turf|area, mob/user as mob)

		if (get_dist(A,user) > 1) // Scanning for fingerprints over the camera network is fun, but doesn't really make sense (Convair880).
			return

		user.visible_message("<span style=\"color:red\"><strong>[user]</strong> has scanned [A].</span>")
		boutput(user, scan_forensic(A)) // Moved to scanprocs.dm to cut down on code duplication (Convair880).
		add_fingerprint(user)
		return

///////////////////////////////////// Health analyzer ////////////////////////////////////////

/obj/item/device/healthanalyzer
	name = "health analyzer"
	icon_state = "health-no_up"
	inhand_image_icon = 'icons/mob/inhand/hand_medical.dmi'
	item_state = "healthanalyzer-no_up" // someone made this sprite and then this was never changed to it for some reason???
	desc = "A hand-held body scanner able to distinguish vital signs of the subject."
	flags = FPRINT | ONBELT | TABLEPASS | CONDUCT
	throwforce = 3
	w_class = 1.0
	throw_speed = 5
	throw_range = 10
	m_amt = 200
	mats = 5
	var/disease_detection = 1
	var/reagent_upgrade = 0
	var/reagent_scan = 0
	module_research = list("analysis" = 2, "medicine" = 2, "devices" = 1)
	module_research_type = /obj/item/device/healthanalyzer

	attack_self(mob/user as mob)
		if (!reagent_upgrade)
			boutput(user, "<span style=\"color:red\">No reagent scan upgrade detected!</span>")
			return
		else
			reagent_scan = !(reagent_scan)
			boutput(user, "<span style=\"color:blue\">Reagent scanner [reagent_scan ? "enabled" : "disabled"].</span>")
			return

	attackby(obj/item/W as obj, mob/user as mob)
		if (istype(W, /obj/item/device/healthanalyzer_upgrade))
			if (reagent_upgrade)
				boutput(user, "<span style=\"color:red\">This analyzer already has a reagent scan upgrade!</span>")
				return
			else
				reagent_upgrade = 1
				reagent_scan = 1
				icon_state = "health"
				item_state = "healthanalyzer"
				boutput(user, "<span style=\"color:blue\">Reagent scan upgrade installed.</span>")
				playsound(loc ,"sound/items/Deconstruct.ogg", 80, 0)
				user.u_equip(W)
				qdel(W)
				return
		else
			return ..()

	attack(mob/M as mob, mob/user as mob)
		if ((user.bioHolder.HasEffect("clumsy") || user.get_brain_damage() >= 60) && prob(50))
			user.visible_message("<span style=\"color:red\"><strong>[user]</strong> slips and drops [src]'s sensors on the floor!</span>")
			user.show_message("Analyzing Results for <span style=\"color:blue\">The floor:<br>&emsp; Overall Status: Healthy</span>", 1)
			user.show_message("&emsp; Damage Specifics: <font color='#1F75D1'>[0]</font> - <font color='#138015'>[0]</font> - <font color='#CC7A1D'>[0]</font> - <font color='red'>[0]</font>", 1)
			user.show_message("&emsp; Key: <font color='#1F75D1'>Suffocation</font>/<font color='#138015'>Toxin</font>/<font color='#CC7A1D'>Burns</font>/<font color='red'>Brute</font>", 1)
			user.show_message("<span style=\"color:blue\">Body Temperature: ???</span>", 1)
			return

		user.visible_message("<span style=\"color:red\"><strong>[user]</strong> has analyzed [M]'s vitals.</span>",\
		"<span style=\"color:red\">You have analyzed [M]'s vitals.</span>")
		boutput(user, scan_health(M, reagent_scan, disease_detection))
		update_medical_record(M)

		if (M.stat > 1)
			user.unlock_medal("He's dead, Jim", 1)
		return

/obj/item/device/healthanalyzer/borg
	icon_state = "health"
	reagent_upgrade = 1
	reagent_scan = 1

/obj/item/device/healthanalyzer/vr
	icon = 'icons/effects/VR.dmi'

/obj/item/device/healthanalyzer_upgrade
	name = "health analyzer upgrade"
	desc = "A small upgrade card that allows standard health analyzers to detect reagents present in the patient, and ProDoc Healthgoggles to scan patients' health from a distance."
	icon_state = "health_upgr"
	flags = FPRINT | TABLEPASS | CONDUCT
	throwforce = 0
	w_class = 1.0
	throw_speed = 5
	throw_range = 10
	mats = 2

///////////////////////////////////// Reagent scanner //////////////////////////////

/obj/item/device/reagentscanner
	name = "reagent scanner"
	icon_state = "reagentscan"
	inhand_image_icon = 'icons/mob/inhand/hand_medical.dmi'
	item_state = "reagentscan"
	desc = "A hand-held device that scans and lists the chemicals inside the scanned subject."
	flags = FPRINT | ONBELT | TABLEPASS | CONDUCT
	throwforce = 3
	w_class = 1.0
	throw_speed = 5
	throw_range = 10
	m_amt = 200
	mats = 5
	var/scan_results = null
	module_research = list("analysis" = 2, "science" = 2, "devices" = 1)
	module_research_type = /obj/item/device/reagentscanner

	attack(mob/M as mob, mob/user as mob)
		return

	afterattack(atom/A as mob|obj|turf|area, mob/user as mob)
		user.visible_message("<span style=\"color:blue\"><strong>[user]</strong> scans [A] with [src]!</span>",\
		"<span style=\"color:blue\">You scan [A] with [src]!</span>")

		scan_results = scan_reagents(A)

		if (!isnull(A.reagents))
			if (A.reagents.reagent_list.len > 0)
				icon_state = "reagentscan-results"
			else
				icon_state = "reagentscan-no"
		else
			icon_state = "reagentscan-no"

		if (isnull(scan_results))
			boutput(user, "<span style=\"color:red\">\The [src] encounters an error and crashes!</span>")
		else
			boutput(user, "[scan_results]")

	attack_self(mob/user as mob)
		if (isnull(scan_results))
			boutput(user, "<span style=\"color:blue\">No previous scan results located.</span>")
			return
		boutput(user, "<span style=\"color:blue\">Previous scan's results:<br>[scan_results]</span>")

	get_desc(dist)
		if (dist < 3)
			if (!isnull(scan_results))
				. += "<br><span style=\"color:blue\">Previous scan's results:<br>[scan_results]</span>"

/////////////////////////////////////// Atmos analyzer /////////////////////////////////////

/obj/item/device/analyzer
	desc = "A hand-held environmental scanner which reports current gas levels."
	name = "atmospheric analyzer"
	icon_state = "atmos"
	item_state = "analyzer"
	w_class = 2
	flags = FPRINT | TABLEPASS | CONDUCT | ONBELT
	throwforce = 5
	w_class = 2
	throw_speed = 4
	throw_range = 20
	mats = 3
	module_research = list("analysis" = 2, "atmospherics" = 2, "devices" = 1)
	module_research_type = /obj/item/device/analyzer

	attack_self(mob/user as mob)
		if (user.stat)
			return

		add_fingerprint(user)

		var/turf/location = get_turf(user)
		if (isnull(location))
			user.show_text("Unable to obtain a reading.", "red")
			return

		user.visible_message("<span style=\"color:blue\"><strong>[user]</strong> takes an atmospheric reading of [location].</span>")
		boutput(user, scan_atmospheric(location)) // Moved to scanprocs.dm to cut down on code duplication (Convair880).
		return

	afterattack(atom/A as mob|obj|turf|area, mob/user as mob)
		if (get_dist(A, user) > 1)
			return

		if (istype(A, /obj) || isturf(A))
			user.visible_message("<span style=\"color:blue\"><strong>[user]</strong> takes an atmospheric reading of [A].</span>")
			boutput(user, scan_atmospheric(A))
		add_fingerprint(user)
		return

	is_detonator_attachment()
		return TRUE

	detonator_act(event, var/obj/item/assembly/detonator/det)
		switch (event)
			if ("pulse")
				det.attachedTo.visible_message("<span class='bold' style='color: #B7410E;'>\The [src]'s external display turns off for a moment before booting up again.</span>")
			if ("cut")
				det.attachedTo.visible_message("<span class='bold' style='color: #B7410E;'>\The [src]'s external display turns off.</span>")
				det.attachments.Remove(src)
			if ("leak")
				det.attachedTo.visible_message("<style class='combat bold'>\The [src] picks up the rapid atmospheric change of the canister, and signals the detonator.</style>")
				spawn (0)
					det.detonate()
		return

///////////////////////////////////////////////// Prisoner scanner ////////////////////////////////////

/obj/item/device/prisoner_scanner
	name = "Securotron-5000"
	desc = "Used to scan in prisoners and update their security records."
	icon_state = "forensic0"
	var/mode = 1
	var/data/record/active1 = null
	var/data/record/active2 = null
	w_class = 3.0
	item_state = "electronic"
	flags = FPRINT | TABLEPASS | ONBELT | CONDUCT | EXTRADELAY
	mats = 3

/obj/item/device/prisoner_scanner/attack(mob/living/carbon/human/M as mob, mob/user as mob)
	////General Records
	var/found = 0
	//if ( !istype(get_area(src), /area/security/prison) && !istype(get_area(src), /area/security/main))
	//	boutput(user, "<span style=\"color:red\">Device only works in designated security areas!</span>")
	//	return
	boutput(user, "<span style=\"color:blue\">You scan in [M]</span>")
	boutput(M, "<span style=\"color:red\">[user] scans you with the Securotron-5000</span>")
	for (var/data/record/R in REPO.data_core.general)
		if (lowertext(R.fields["name"]) == lowertext(M.name))
			//Update Information
			R.fields["name"] = M.name
			R.fields["sex"] = M.gender
			R.fields["age"] = M.bioHolder.age
			if (M.gloves)
				R.fields["fingerprint"] = "Unknown"
			else
				R.fields["fingerprint"] = md5(M.bioHolder.Uid)
			R.fields["p_stat"] = "Active"
			R.fields["m_stat"] = "Stable"
			active1 = R
			found = 1

	if (found == 0)
		active1 = new /data/record()
		active1.fields["id"] = text("[]", add_zero(num2hex(rand(1, 1.6777215E7)), 6))
		active1.fields["rank"] = "Unassigned"
		//Update Information
		active1.fields["name"] = M.name
		active1.fields["sex"] = M.gender
		active1.fields["age"] = M.bioHolder.age
		/////Fingerprint record update
		if (M.gloves)
			active1.fields["fingerprint"] = "Unknown"
		else
			active1.fields["fingerprint"] = md5(M.bioHolder.Uid)
		active1.fields["p_stat"] = "Active"
		active1.fields["m_stat"] = "Stable"
		REPO.data_core.general += active1
		found = 0

	////Security Records
	for (var/data/record/E in REPO.data_core.security)
		if (E.fields["name"] == active1.fields["name"])
			if (mode == 1)
				E.fields["criminal"] = "Incarcerated"
			else if (mode == 2)
				E.fields["criminal"] = "Parolled"
			else
				E.fields["criminal"] = "Released"
			return

	active2 = new /data/record()
	active2.fields["name"] = active1.fields["name"]
	active2.fields["id"] = active1.fields["id"]
	active2.name = text("Security Record #[]", active1.fields["id"])
	if (mode == 1)
		active2.fields["criminal"] = "Incarcerated"
	else if (mode == 2)
		active2.fields["criminal"] = "Parolled"
	else
		active2.fields["criminal"] = "Released"
	active2.fields["mi_crim"] = "None"
	active2.fields["mi_crim_d"] = "No minor crime convictions."
	active2.fields["ma_crim"] = "None"
	active2.fields["ma_crim_d"] = "No major crime convictions."
	active2.fields["notes"] = "No notes."
	REPO.data_core.security += active2

	return

/obj/item/device/prisoner_scanner/attack_self(mob/user as mob)

	if (mode == 1)
		mode = 2
		boutput(user, "<span style=\"color:blue\">you switch the record mode to Parolled</span>")
	else if (mode == 2)
		mode = 3
		boutput(user, "<span style=\"color:blue\">you switch the record mode to Released</span>")
	else
		mode = 1
		boutput(user, "<span style=\"color:blue\">you switch the record mode to Incarcerated</span>")

	add_fingerprint(user)
	return