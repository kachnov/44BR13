var/list/genetics_computers = list()

/obj/machinery/computer/genetics
	name = "genetics console"
	icon = 'icons/obj/computer.dmi'
	icon_state = "scanner"
	req_access = list(access_heads) //Only used for record deletion right now.
	var/obj/machinery/genetics_scanner/scanner = null //Linked scanner. For scanning.
	var/list/equipment = list(0,0,0,0)
	// Injector, Analyser, Emitter, Reclaimer
	var/list/saved_mutations = list()
	var/list/saved_chromosomes = list()
	var/list/combining = list()
	var/dna_chromosome/to_splice = null
	var/bioEffect/currently_browsing = null
	var/geneticsResearchEntry/tracked_research = null

	var/botbutton_html = ""
	var/info_html = ""
	var/topbotbutton_html = ""

	var/print = 0
	var/printlabel = null
	var/backpage = null

/obj/machinery/computer/genetics/New()
	..()
	genetics_computers += src
	spawn (5)
		scanner = locate(/obj/machinery/genetics_scanner, orange(1,src))
		return
	return

/obj/machinery/computer/genetics/disposing()
	genetics_computers -= src
	..()

/obj/machinery/computer/genetics/attackby(obj/item/W as obj, mob/user as mob)
	if ((istype(W, /obj/item/screwdriver)) && ((stat & BROKEN) || !scanner))
		playsound(loc, "sound/items/Screwdriver.ogg", 50, 1)
		if (do_after(user, 20))
			boutput(user, "<span style=\"color:blue\">The broken glass falls out.</span>")
			var/obj/computerframe/A = new /obj/computerframe( loc )
			if (material) A.setMaterial(material)
			new /obj/item/raw_material/shard/glass( loc )
			var/obj/item/circuitboard/genetics/M = new /obj/item/circuitboard/genetics( A )
			for (var/obj/C in src)
				C.set_loc(loc)
			A.circuit = M
			A.state = 3
			A.icon_state = "3"
			A.anchored = 1
			qdel(src)
	else if (istype(W,/obj/item/genetics_injector/dna_activator))
		var/obj/item/genetics_injector/dna_activator/DNA = W
		if (DNA.expended_properly)
			user.drop_item()
			qdel(DNA)

			if (genResearch.time_discount < 0.75)
				genResearch.time_discount += 0.025
			if (genResearch.cost_discount < 0.75)
				genResearch.cost_discount += 0.025

			var/rewardpicker = rand(1,3)
			switch(rewardpicker)
				if (1)
					boutput(user, "<strong>SCANNER ALERT:</strong> Recycled genetic info has yielded materials.")
					genResearch.researchMaterial += 40
				if (2)
					boutput(user, "<strong>SCANNER ALERT:</strong> Recycled genetic info has yielded the ability to break one encryption automatically.")
					genResearch.lock_breakers += 1
				if (3)
					boutput(user, "<strong>SCANNER ALERT:</strong> Recycled genetic info has yielded a new chromosome.")
					var/type_to_make = pick(typesof(/dna_chromosome))
					var/dna_chromosome/C = new type_to_make(src)
					saved_chromosomes += C

		else
			attack_hand(user)
	else
		attack_hand(user)
	return

/obj/machinery/computer/genetics/attack_ai(mob/user as mob)
	return attack_hand(user)

/obj/machinery/computer/genetics/attack_hand(mob/user as mob)
	if (stat & (BROKEN|NOPOWER))
		return

	var/basicinfo = {"<strong>Materials:</strong> [genResearch.researchMaterial] (+[genResearch.checkMaterialGenerationRate()]) * "}

	botbutton_html = "<p><small>"
	var/mob/living/subject = get_scan_subject()
	if (subject)
		basicinfo += {"<strong>Scanner Occupant:</strong> [subject.name] - Health: [subject.health] - Stability: [subject.bioHolder.genetic_stability]"}
		botbutton_html += {"* <a href='?src=\ref[src];menu=potential'>Potential</a>"}
		botbutton_html += {" * <a href='?src=\ref[src];menu=mutations'>Mutations</a>"}
		if (istype(subject,/mob/living/carbon/human))
			var/mob/living/carbon/human/H = subject
			if (!istype(H.mutantrace))
				botbutton_html += {" * <a href='?src=\ref[src];menu=appearance'>Appearance</a>"}
			botbutton_html += {" * <a href='?src=\ref[src];menu=mutantrace'>Body</a>  "}
	else
		basicinfo += {"<strong>Scanner Occupant:</strong> None"}
	if (genResearch.debug_mode)
		if (get_scan_subject())
			botbutton_html += {"<a href='?src=\ref[src];debug_erase=1'>Erase Occupant</a>  "}
		else
			botbutton_html += {"<a href='?src=\ref[src];debug_create=1'>Create Occupant</a>  "}
	botbutton_html += "<br>"
	if (backpage)
		botbutton_html += "<a href='?src=\ref[src];menu=[backpage]'><strong>\<</strong></a> "
	botbutton_html += {"<a href='?src=\ref[src];menu=research'>Research Menu</a>  "}

	if (genResearch.isResearched(/geneticsResearchEntry/checker))
		botbutton_html += {"<img alt="Analyser Cooldown" src="[resource("images/genetics/eqAnalyser.png")]" style="border-style: none">: [max(0,round((equipment[2] - world.time) / 10))] "}
	if (genResearch.isResearched(/geneticsResearchEntry/rademitter))
		botbutton_html += {"<img alt="Emitter Cooldown" src="[resource("images/genetics/eqEmitter.png")]" style="border-style: none">: [max(0,round((equipment[3] - world.time) / 10))] "}
	if (genResearch.isResearched(/geneticsResearchEntry/reclaimer))
		botbutton_html += {"<img alt="Reclaimer Cooldown" src="[resource("images/genetics/eqReclaimer.png")]" style="border-style: none">: [max(0,round((equipment[4] - world.time) / 10))] "}
	botbutton_html += {"<img alt="Injector Cooldown" src="[resource("images/genetics/eqInjector.png")]" style="border-style: none">: [max(0,round((equipment[1] - world.time) / 10))] "}
	if (tracked_research)
		botbutton_html += {"<img alt="[tracked_research.name]" src="[resource("images/genetics/eqResearch.png")]" style="border-style: none">: [max(0,round((tracked_research.finishTime - world.time) / 10))] "}

	botbutton_html += "<br>[basicinfo]"

	botbutton_html += "</small></p>"

	var/html = {"<html><head><title>GeneTek</title>
				<STYLE type=text/css>
				A:link {COLOR: #EAFDE6}
				A:visited {COLOR: #88C425}
				A:hover{COLOR: #BEF202}
				A {font-family:"Arial", sans-serif; font-size:14px; COLOR: #EAFDE6;}
				P {font-family:"Arial", sans-serif; font-size:14px; COLOR: #EAFDE6;}
				</STYLE>
				</head>
				<body style="overflow: hidden; background-color: rgb(27, 103, 107); font-family:"Arial", sans-serif; font-size:14px; COLOR: #800080;">
				<span></span>
				<big style="font-family: Helvetica,Arial,sans-serif; color: rgb(234, 253, 230); font-style: italic;">GeneTek Console v1</big>
				<table style="text-align: left; background-color: rgb(27, 103, 107); width: 700px; height: 335px;" border="0" cellpadding="0" cellspacing="0">
				<tbody><tr><td style="width: 183px;">
				<img style="width: 182px; height: 300px;" alt="" src="[resource("images/genetics/DNAorbit.gif")]"></td>
				<td><table style="text-align: left; width: 100%; height: 100%;" border="0" cellpadding="0" cellspacing="0"><tbody>
				<tr><td style="vertical-align: middle; height: 20%;">[topbotbutton_html]</td></tr>
				<tr><td valign="middle"><div style="overflow:auto;width:517px; height:240px; padding:0px 0px 0px 0px; margin:0px 0 0px 0;margin:0 auto;">[info_html]</div></td></tr>
				</tbody></table></td></tr>
				<tr><td valign="middle" align="middle"><a href='?src=\ref[src];print=1'><img alt="" src="[resource("images/genetics/gprint.png")]" style="border-style: none"></a><br>
				<a href='?src=\ref[src];printlabel=1'><small>Label: [printlabel ? "[printlabel]" : "No Label"]</small></a></td>
				<td style="vertical-align: middle; height: 40px;">[botbutton_html]</td></tr>
				</tbody></table>
				<span></span></body></html>
				"}

	user.machine = src
	add_fingerprint(user)

	if (print == 1) //Hilariously hacky temporary print thing.
		print = -1
		spawn (15)
			print = 0

		var/temp_html = {"
		<script language='javascript' type='text/javascript'>
		window.onload = function() {
    	var anchors = document.getElementsByTagName("a");
    	for (var i = 0; i < anchors.length; i++)
    	{
        	anchors\[i\].onclick = function() {return(false);};
        }
        };
        </script>
        "} + html

		temp_html = replacetext(temp_html, "DNAorbit.gif", "DNAorbitstatic.png")

		playsound(loc, "sound/machines/printer_dotmatrix.ogg", 50, 1)
		var/obj/item/paper/p = new (loc)
		p.sizex = 730
		p.sizey = 415
		if (printlabel)
			p.name = printlabel
		else
			p.name = "Genetics Console Paper"
		p.info = temp_html

	user << browse(html, "window=genetics;size=730x415;can_resize=0;can_minimize=0")
	onclose(user, "genetics")
	return

/obj/machinery/computer/genetics/proc/bioEffect_sanity_check(var/bioEffect/E,var/occupant_check = 1)
	var/mob/living/carbon/human/H = get_scan_subject()
	if (occupant_check)
		if (!istype(H))
			info_html = "<p>Operation error: Invalid subject.</p>"
			updateUsrDialog()
			return TRUE
		if (!H.bioHolder)
			info_html = "<p>Operation error: Invalid genetic structure.</p>"
			updateUsrDialog()
			return TRUE
		//if (H.bioHolder.HasEffectInEither(E.id))
		//	info_html = "<p>Operation error: Gene already present in subject's DNA.</p>"
		//	updateUsrDialog()
		//	return TRUE
	if (!istype(E,/bioEffect))
		info_html = "<p>Operation error: Unrecognized gene.</p>"
		updateUsrDialog()
		return TRUE
	return FALSE

/obj/machinery/computer/genetics/proc/sample_sanity_check(var/computer/file/genetics_scan/S)
	if (!istype(S,/computer/file/genetics_scan))
		info_html = "<p>Unable to scan DNA Sample. The sample may be corrupt.</p>"
		updateUsrDialog()
		return TRUE
	return FALSE

/obj/machinery/computer/genetics/proc/research_sanity_check(var/geneticsResearchEntry/R)
	if (!istype(R,/geneticsResearchEntry))
		info_html = "<p>Invalid research article.</p>"
		updateUsrDialog()
		return TRUE
	return FALSE

/obj/machinery/computer/genetics/Topic(href, href_list)
	if (!can_reach(usr,src))
		boutput(usr, "<span style=\"color:red\">You can't reach the computer from there.</span>")
		return

	if (href_list["viewpool"])
		var/bioEffect/E = locate(href_list["viewpool"])
		if (bioEffect_sanity_check(E)) return

		backpage = null
		currently_browsing = E
		topbotbutton_html = ui_build_clickable_genes("pool")

		var/bioEffect/GBE = E.get_global_instance()

		info_html = {"<p><strong>[GBE.research_level >= 2 ? E.name : "Unknown Mutation"]</strong>"}
		if (GBE.research_level >= 2)
			if (equipment_available("precision_emitter",E))
				info_html += " <a href='?src=\ref[src];Prademitter=\ref[E]'><small>(Scramble)</small></a>"
			if (equipment_available("reclaimer",E))
				info_html += " <a href='?src=\ref[src];reclaimer=\ref[E]'><small>(Reclaim)</small></a>"
		info_html += "</p><br>"

		info_html += ui_build_mutation_research(E)

		info_html += "<p> Sequence: <br>"
		var/list/build = ui_build_sequence(E,"pool")
		info_html += "[build[1]]<br>[build[2]]<br>[build[3]]</p><br>"

		info_html += "<p><small>"
		if (E.dnaBlocks.sequenceCorrect())
			info_html += "* <a href='?src=\ref[src];activatepool=\ref[E]'>Activate</a>"
		else
			if (GBE.research_level >= 3)
				info_html += " * <a href='?src=\ref[src];autocomplete=\ref[E]'>Autocomplete</a>"
		if (equipment_available("activator",E) && GBE.research_level >= 2)
			info_html += " * <a href='?src=\ref[src];make_activator=\ref[E]'>Create Activator</a>"
		if (equipment_available("analyser"))
			info_html += " * <a href='?src=\ref[src];checkstability=\ref[E]'>Check Stability</a>"
		info_html += "</small></p>"

	else if (href_list["sample_viewpool"])
		var/bioEffect/E = locate(href_list["sample_viewpool"])
		if (bioEffect_sanity_check(E,0)) return
		var/computer/file/genetics_scan/sample = locate(href_list["sample_to_viewpool"])
		if (sample_sanity_check(sample)) return

		backpage = "dna_samples"
		currently_browsing = E
		topbotbutton_html = ui_build_clickable_genes("sample_pool",sample)

		var/bioEffect/GBE = E.get_global_instance()

		info_html = {"<p><strong>[GBE.research_level >= 2 ? E.name : "Unknown Mutation"]</strong></p><br>"}

		info_html += ui_build_mutation_research(E,sample)

		info_html += "<p> Sequence : <br>"
		var/list/build = ui_build_sequence(E,"sample_pool")
		info_html += "[build[1]]<br>[build[2]]<br>[build[3]]</p><br>"

		if (equipment_available("activator",E) && GBE.research_level >= 2)
			info_html += " <p><small><a href='?src=\ref[src];make_activator=\ref[E]'>Create Activator</a></small></p>"

	else if (href_list["researched_mutation"])

		var/bioEffect/E = locate(href_list["researched_mutation"])
		if (bioEffect_sanity_check(E,0)) return

		backpage = "mutresearch"
		currently_browsing = E

		if (E.research_level >= 3 && E.researched_desc)
			info_html = {"<p><strong>[E.name]</strong><br>[E.researched_desc]</p>"}
		else
			info_html = {"<p><strong>[E.name]</strong><br>[E.desc]</p>"}

		if (E.research_level >= 3)
			info_html += "<p> Sequence : <br>"
			var/list/build = ui_build_sequence(E,"active")
			info_html += "[build[1]]<br>[build[2]]<br>[build[3]]</p><br>"
		else
			info_html += "<p> This mutation needs to be activated at least once to see the sequence.</p>"

		if (equipment_available("activator",E) && E.research_level >= 2)
			info_html += " <p><small><a href='?src=\ref[src];make_activator=\ref[E]'>Create Activator</a></small></p>"

	else if (href_list["vieweffect"])
		var/bioEffect/E = locate(href_list["vieweffect"])
		if (bioEffect_sanity_check(E)) return

		backpage = null
		var/bioEffect/globalInstance = bioEffectList[E.id]
		currently_browsing = E
		topbotbutton_html = ui_build_clickable_genes("active")

		if (globalInstance != null)
			var/name_string = "Unknown Mutation"
			var/desc_string = "Research on a non-active instance of this gene is required."
			if (globalInstance.research_level == 3)
				name_string = globalInstance.name
				desc_string = globalInstance.desc
			else if (globalInstance.research_level == 2)
				name_string = E.name
				desc_string = E.desc
			else if (globalInstance.research_level == 1)
				desc_string = "Research on this gene is currently in progress."

			info_html = "<p><strong>[name_string]</strong><br>[desc_string]</p>"

			info_html += "<p> Sequence : <br>"
			var/list/build = ui_build_sequence(E,"active")
			info_html += "[build[1]]<br>[build[2]]<br>[build[3]]</p><br>"

			info_html += "<p><small>"
			if (equipment_available("injector",E))
				info_html += " * <a href='?src=\ref[src];make_injector=\ref[E]'>Create Injector</a>"
			if (equipment_available("activator",E))
				info_html += " * <a href='?src=\ref[src];make_activator=\ref[E]'>Create Activator</a>"
			if (to_splice)
				info_html += " * <a href='?src=\ref[src];splice_chromosome=\ref[E]'>Splice Chromosome</a>"
			if (equipment_available("saver",E))
				info_html += " * <a href='?src=\ref[src];genesaver=\ref[E]'>Store</a>"
			info_html += "</small></p>"
		else
			info_html = "<p>Error attempting to read gene.</p>"

	else if (href_list["stored_mut"])
		var/bioEffect/E = locate(href_list["stored_mut"])
		if (bioEffect_sanity_check(E,0)) return

		backpage = "storedmuts"
		var/bioEffect/globalInstance = bioEffectList[E.id]
		currently_browsing = E

		if (globalInstance != null)
			var/name_string = "Unknown Mutation"
			var/desc_string = "Research on a non-active instance of this gene is required."
			if (globalInstance.research_level == 3)
				name_string = globalInstance.name
				desc_string = globalInstance.desc
			else if (globalInstance.research_level == 2)
				name_string = E.name
				desc_string = E.desc
			else if (globalInstance.research_level == 1)
				desc_string = "Research on this gene is currently in progress."

			info_html = "<p><strong>[name_string]</strong><br>[desc_string]</p>"

			info_html += "<p> Sequence : <br>"
			var/list/build = ui_build_sequence(E,"active")
			info_html += "[build[1]]<br>[build[2]]<br>[build[3]]</p><br>"

			var/mob/living/subject = get_scan_subject()
			info_html += "<p><small>* <a href='?src=\ref[src];delete_stored_mut=\ref[E]'>Delete</a>"
			if (subject)
				info_html += " * <a href='?src=\ref[src];add_stored_mut=\ref[E]'>Add to Occupant</a>"
			if (equipment_available("injector",E))
				info_html += " * <a href='?src=\ref[src];make_injector=\ref[E]'>Create Injector</a>"
			if (equipment_available("activator",E))
				info_html += " * <a href='?src=\ref[src];make_activator=\ref[E]'>Create Activator</a>"
			if (to_splice)
				info_html += " * <a href='?src=\ref[src];splice_chromosome=\ref[E]'>Splice Chromosome</a>"
			info_html += "</small></p>"
		else
			info_html = "<p>Error attempting to read gene.</p>"

	else if (href_list["stored_chromosome"])
		var/dna_chromosome/E = locate(href_list["stored_chromosome"])
		if (!istype(E)) return
		backpage = "chromosomes"

		info_html = "<p><strong>[E.name]</strong><br>[E.desc]</p>"
		if (to_splice != E)
			info_html += "<small><a href='?src=\ref[src];splice_stored_chromosome=\ref[E]'>Mark for Splicing</a>"
		info_html += " <a href='?src=\ref[src];delete_stored_chromosome=\ref[E]'>Delete</a></small>"

	else if (href_list["splice_chromosome"])
		var/bioEffect/E = locate(href_list["splice_chromosome"])
		if (bioEffect_sanity_check(E,0)) return
		if (!to_splice) return
		var/dna_chromosome/C = to_splice

		var/result = C.apply(E)
		if (istext(result))
			boutput(usr, "<span style=\"color:red\"><strong>SCANNER ALERT:</strong> Splice failed: [result]</span>")
		else
			boutput(usr, "<span style=\"color:blue\"><strong>SCANNER ALERT:</strong> Splice successful.</span>")
			saved_chromosomes -= C
			qdel(C)
			to_splice = null
		usr << link("byond://?src=\ref[src];menu=research")

	else if (href_list["splice_stored_chromosome"])
		var/dna_chromosome/E = locate(href_list["splice_stored_chromosome"])
		if (!istype(E)) return
		to_splice = E
		boutput(usr, "<strong>SCANNER ALERT:</strong> Chromosome marked for splicing.")
		usr << link("byond://?src=\ref[src];stored_chromosome=\ref[E]")

	else if (href_list["delete_stored_mut"])
		var/bioEffect/E = locate(href_list["delete_stored_mut"])
		if (bioEffect_sanity_check(E,0)) return
		backpage = "research"

		saved_mutations -= E
		qdel(E)
		boutput(usr, "<strong>SCANNER ALERT:</strong> Mutation deleted.")
		usr << link("byond://?src=\ref[src];menu=storedmuts")

	else if (href_list["delete_stored_chromosome"])
		var/dna_chromosome/E = locate(href_list["delete_stored_chromosome"])
		if (!istype(E)) return
		backpage = "chromosomes"

		if (E == to_splice)
			to_splice = null
		saved_chromosomes -= E
		qdel(E)
		boutput(usr, "<strong>SCANNER ALERT:</strong> Chromosome deleted.")
		usr << link("byond://?src=\ref[src];menu=chromosomes")

	else if (href_list["add_stored_mut"])
		var/bioEffect/E = locate(href_list["add_stored_mut"])
		if (bioEffect_sanity_check(E)) return
		backpage = null
		var/mob/living/subject = get_scan_subject()
		if (!subject)
			boutput(usr, "<span style=\"color:red\"><strong>SCANNER ALERT:</strong> Subject not found.</span>")
			return

		log_me(subject, "mutation added", E)

		subject.bioHolder.AddEffectInstance(E)
		saved_mutations -= E
		boutput(usr, "<strong>SCANNER ALERT:</strong> Mutation successfully added to occupant.")
		usr << link("byond://?src=\ref[src];menu=mutations")

	else if (href_list["mark_for_combination"])
		var/bioEffect/E = locate(href_list["mark_for_combination"])
		if (bioEffect_sanity_check(E,0)) return

		if (E in combining)
			combining -= E
		else
			combining += E

		usr << link("byond://?src=\ref[src];menu=combinemuts")

	else if (href_list["do_combine"])
		var/matches = 0
		for (var/geneticsrecipe/GR in genResearch.combinationrecipes)
			matches = 0
			if (GR.required_effects.len != combining.len)
				continue
			var/list/temp = GR.required_effects.Copy()
			for (var/bioEffect/BE in combining)
				if (BE.wildcard)
					matches++
				if (BE.id in temp)
					temp -= BE.id
					matches++
			if (matches == GR.required_effects.len)
				var/bioEffect/NEWBE = new GR.result(src)
				saved_mutations += NEWBE
				var/bioEffect/GBE = NEWBE.get_global_instance()
				GBE.research_level = max(GBE.research_level,3) // counts as researching it
				for (var/X in combining)
					saved_mutations -= X
					combining -= X
					qdel(X)
				boutput(usr, "<strong>SCANNER ALERT:</strong> Combination successful. New [NEWBE.name] mutation created.")
				usr << link("byond://?src=\ref[src];menu=storedmuts")
				return

		boutput(usr, "<span style=\"color:red\"><strong>SCANNER ALERT:</strong> Combination unsuccessful.</span>")
		combining = list()
		usr << link("byond://?src=\ref[src];menu=storedmuts")
		return

	else if (href_list["cancel_combine"])
		backpage = "research"
		combining = list()
		usr << link("byond://?src=\ref[src];menu=storedmuts")

	else if (href_list["make_injector"])
		if (!genResearch.isResearched(/geneticsResearchEntry/injector))
			return

		var/bioEffect/E = locate(href_list["make_injector"])
		if (bioEffect_sanity_check(E,0)) return
		if (!equipment_available("injector",E))
			boutput(usr, "<span style=\"color:red\"><strong>SCANNER ALERT:</strong> That equipment is on cooldown.</span>")
			return

		var/price = genResearch.injector_cost
		if (genResearch.researchMaterial < price)
			boutput(usr, "<span style=\"color:red\"><strong>SCANNER ALERT:</strong> Not enough research materials to manufacture an injector.</span>")
			return
		if (!E.can_make_injector)
			boutput(usr, "<span style=\"color:red\"><strong>SCANNER ALERT:</strong> Cannot make an injector using this gene.</span>")
			return

		equipment_cooldown(1,400)

		genResearch.researchMaterial -= price
		var/obj/item/genetics_injector/dna_injector/I = new /obj/item/genetics_injector/dna_injector(loc)
		I.name = "dna injector - [E.name]"
		var/bioEffect/NEW = new E.type(I)
		copy_datum_vars(E,NEW)
		I.BE = NEW // valid. still, wtf

		spawn (0)
			if (backpage == "storedmuts")
				usr << link("byond://?src=\ref[src];stored_mut=\ref[E]")
			else
				usr << link("byond://?src=\ref[src];vieweffect=\ref[E]")

	else if (href_list["make_activator"])
		var/bioEffect/E = locate(href_list["make_activator"])
		if (bioEffect_sanity_check(E,0)) return
		if (!equipment_available("activator",E))
			boutput(usr, "<span style=\"color:red\"><strong>SCANNER ALERT:</strong> That equipment is on cooldown.</span>")
			return

		if (!E.can_make_injector)
			boutput(usr, "<span style=\"color:red\"><strong>SCANNER ALERT:</strong> Cannot make an activator using this gene.</span>")
			return
		equipment_cooldown(1,200)

		var/obj/item/genetics_injector/dna_activator/I = new /obj/item/genetics_injector/dna_activator(loc)
		I.name = "dna activator - [E.name]"
		I.gene_to_activate = E.id
		updateUsrDialog()
		return

	else if (href_list["genesaver"])
		if (!genResearch.isResearched(/geneticsResearchEntry/saver))
			return

		var/bioEffect/E = locate(href_list["genesaver"])
		if (bioEffect_sanity_check(E)) return
		var/mob/living/subject = get_scan_subject()

		if (saved_mutations.len >= genResearch.max_save_slots)
			boutput(usr, "<span style=\"color:red\"><strong>SCANNER ALERT:</strong> No more room in this scanner for stored mutations.</span>")
			return

		log_me(subject, "mutation removed", E)

		saved_mutations += E
		subject.bioHolder.RemoveEffect(E.id)
		E.owner = null
		E.holder = null
		boutput(usr, "<strong>SCANNER ALERT:</strong> Mutation stored successfully.")
		usr << link("byond://?src=\ref[src];menu=mutations")

	else if (href_list["checkstability"])
		if (!equipment_available("analyser"))
			return

		var/bioEffect/E = locate(href_list["checkstability"])
		if (bioEffect_sanity_check(E)) return

		for (var/i=0, i < E.dnaBlocks.blockListCurr.len, i++)
			var/basePair/bp = E.dnaBlocks.blockListCurr[i+1]
			var/basePair/bpc = E.dnaBlocks.blockList[i+1]
			if (bp.marker == "locked")
				continue
			if (bp.bpp1 == bpc.bpp1 && bp.bpp2 == bpc.bpp2)
				bp.marker = "blue"
			else
				bp.marker = "red"
		equipment_cooldown(2,200)

		usr << link("byond://?src=\ref[src];viewpool=\ref[E]")

	else if (href_list["rademitter"])
		topbotbutton_html = ""
		var/mob/living/subject = get_scan_subject()
		if (!subject)
			boutput(usr, "<strong>SCANNER ALERT:</strong> Subject has absconded.")
			return
		if (subject.health <= 0)
			boutput(usr, "<strong>SCANNER ALERT:</strong> Emitter cannot be used on dead or dying patients.")
			return

		log_me(subject, "DNA scrambled")

		subject.bioHolder.RemoveAllEffects()
		subject.bioHolder.BuildEffectPool()
		if (genResearch.emitter_radiation > 0)
			subject.irradiate(genResearch.emitter_radiation)
		if (prob(genResearch.emitter_radiation * 0.5) && ismonkey(subject) && !subject:ai_active)
			subject:ai_init()

		equipment_cooldown(3,1200)

		boutput(usr, "<strong>SCANNER:</strong> Genes successfully scrambled.")

		usr << link("byond://?src=\ref[src];menu=potential")

	else if (href_list["Prademitter"])
		var/bioEffect/E = locate(href_list["Prademitter"])
		if (bioEffect_sanity_check(E)) return
		if (!equipment_available("precision_emitter",E))
			return

		var/mob/living/subject = get_scan_subject()
		if (!subject)
			boutput(usr, "<strong>SCANNER ALERT:</strong> Subject has absconded.")
			return
		if (subject.stat)
			boutput(usr, "<strong>SCANNER ALERT:</strong> Emitter cannot be used on dead or dying patients.")
			return

		log_me(subject, "DNA scrambled")

		topbotbutton_html = ""

		if (genResearch.emitter_radiation > 0)
			subject.irradiate(genResearch.emitter_radiation)
		subject.bioHolder.RemovePoolEffect(E)
		subject.bioHolder.AddRandomNewPoolEffect()

		equipment_cooldown(3,600)

		boutput(usr, "<strong>SCANNER ALERT:</strong> Gene successfully scrambled.")
		usr << link("byond://?src=\ref[src];menu=potential")

	else if (href_list["reclaimer"])
		var/bioEffect/E = locate(href_list["reclaimer"])
		if (bioEffect_sanity_check(E)) return
		if (!equipment_available("reclaimer",E))
			return

		var/mob/living/subject = get_scan_subject()
		if (!subject)
			boutput(usr, "<strong>SCANNER ALERT:</strong> Subject has absconded.")
			return

		var/reclamation_cap = genResearch.max_material * 1.5
		if (prob(E.reclaim_fail))
			boutput(usr, "<strong>SCANNER:</strong> Reclamation failed.")
		else
			var/waste = (E.reclaim_mats + genResearch.researchMaterial) - reclamation_cap
			if (waste == E.reclaim_mats)
				boutput(usr, "<strong>SCANNER ALERT:</strong> Nothing would be gained from reclamation due to material capacity limit. Reclamation aborted.")
				return
			else
				genResearch.researchMaterial = min(genResearch.researchMaterial + E.reclaim_mats, reclamation_cap)
				if (waste > 0)
					boutput(usr, "<strong>SCANNER:</strong> Reclamation successful. [E.reclaim_mats] materials gained. Material count now at [genResearch.researchMaterial]. [waste] units of material wasted due to material capacity limit.")
				else
					boutput(usr, "<strong>SCANNER:</strong> Reclamation successful. [E.reclaim_mats] materials gained. Material count now at [genResearch.researchMaterial].")
				subject.bioHolder.RemovePoolEffect(E)

		equipment_cooldown(4,600)
		currently_browsing = null
		usr << link("byond://?src=\ref[src];menu=potential")

	else if (href_list["print"] && print != -1)
		print = 1

	else if (href_list["printlabel"])
		var/label = input("Automatically label printouts as what?","[name]",printlabel) as null|text
		label = copytext(html_encode(label), 1, 65)
		if (!label)
			printlabel = null
		else
			printlabel = label

	else if (href_list["setseq"])

		var/bioEffect/E = locate(href_list["setseq"])
		if (bioEffect_sanity_check(E)) return

		var/mob/living/subject = get_scan_subject()
		if (!subject)
			boutput(usr, "<strong>SCANNER ALERT:</strong> Subject has absconded.")
			return

		E = subject.bioHolder.GetEffectFromPool(E.id)
		if (E)
			if (istext(E.req_mut_research) && GetBioeffectResearchLevelFromGlobalListByID(E.id) < 2)
				boutput(usr, "<span style=\"color:red\"><strong>SCANNER ERROR:</strong> Genetic structure unknown. Cannot alter mutation.</span>")
				return
			if (href_list["setseq1"])
				var/basePair/bp = E.dnaBlocks.blockListCurr[text2num(href_list["setseq1"])]
				if (!bp || bp.marker == "locked")
					boutput(usr, "<span style=\"color:red\"><strong>SCANNER ERROR:</strong> Cannot alter encrypted base pairs. Click lock to attempt decryption.</span>")
					return
			else if (href_list["setseq2"])
				var/basePair/bp = E.dnaBlocks.blockListCurr[text2num(href_list["setseq2"])]
				if (!bp || bp.marker == "locked")
					boutput(usr, "<span style=\"color:red\"><strong>SCANNER ERROR:</strong> Cannot alter encrypted base pairs. Click lock to attempt decryption.</span>")
					return

		var/input = input(usr, "Select:", "[name]","Swap") as null|anything in list("Swap","G","C","A","T","G>C","C>G","A>T","T>A")
		if (!input)
			return

		if (!subject)
			boutput(usr, "<strong>SCANNER ALERT:</strong> Subject has absconded.")
			return

		var/temp_holder = null

		if (subject.bioHolder.HasEffectInPool(E.id)) //Change this to occupant and check if empty aswell.
			var/basePair/bp
			var/clicked = 1

			if (href_list["setseq1"])
				clicked = 1
				bp = E.dnaBlocks.blockListCurr[text2num(href_list["setseq1"])]
			else if (href_list["setseq2"])
				clicked = 2
				bp = E.dnaBlocks.blockListCurr[text2num(href_list["setseq2"])]

			if (input == "Swap")
				temp_holder = bp.bpp1
				bp.bpp1 = bp.bpp2
				bp.bpp2 = temp_holder
			else if (findtext(input,">"))
				bp.bpp1 = copytext(input,1,2)
				bp.bpp2 = copytext(input,3,4)
			else
				if (clicked == 1) bp.bpp1 = input
				else bp.bpp2 = input

		if (E.dnaBlocks.sequenceCorrect())
			E.dnaBlocks.ChangeAllMarkers("white")

		usr << link("byond://?src=\ref[src];viewpool=\ref[E]")
		//OH MAN LOOK AT THIS CRAP. FUCK BYOND. (This refreshes the page)
		return

	else if (href_list["marker"])
		var/bioEffect/E = locate(href_list["marker"])
		if (bioEffect_sanity_check(E)) return
		var/mob/living/subject = get_scan_subject()
		if (!subject)
			boutput(usr, "<strong>SCANNER ALERT:</strong> Subject has absconded.")
			return
		var/basePair/bp = E.dnaBlocks.blockListCurr[text2num(href_list["themark"])]
		if (istext(E.req_mut_research) && GetBioeffectResearchLevelFromGlobalListByID(E.id) < 2)
			boutput(usr, "<span style=\"color:red\"><strong>SCANNER ERROR:</strong> Genetic structure unknown. Cannot alter mutation.</span>")
			return

		if (bp.marker == "locked")
			boutput(usr, "<span style=\"color:blue\"><strong>SCANNER ALERT:</strong> Encryption is a [E.lockedDiff]-character code.</span>")
			var/characters = ""
			for (var/X in E.lockedChars)
				characters += "[X] "
			boutput(usr, "<span style=\"color:blue\">Possible characters in this code: [characters]</span>")
			if (genResearch.lock_breakers > 0)
				boutput(usr, "<span style=\"color:blue\">[genResearch.lock_breakers] auto-decryptions available. Enter UNLOCK as the code to expend one.</span>")
			var/code = input("Enter decryption code.","Genetic Decryption") as null|text
			if (!code)
				return
			code = uppertext(code)
			if (code == "UNLOCK")
				if (genResearch.lock_breakers > 0)
					genResearch.lock_breakers--
					var/basePair/bpc = E.dnaBlocks.blockList[text2num(href_list["themark"])]
					bp.bpp1 = bpc.bpp1
					bp.bpp2 = bpc.bpp2
					bp.marker = "green"
					boutput(usr, "<span style=\"color:blue\"><strong>SCANNER ALERT:</strong> Base pair unlocked.</span>")
					if (E.dnaBlocks.sequenceCorrect())
						E.dnaBlocks.ChangeAllMarkers("white")
					usr << link("byond://?src=\ref[src];viewpool=\ref[E]")
					return
				else
					boutput(usr, "<span style=\"color:red\"><strong>SCANNER ALERT:</strong> No automatic decryptions available.</span>")
					return

			if (lentext(code) != lentext(bp.lockcode))
				boutput(usr, "<span style=\"color:red\"><strong>SCANNER ALERT:</strong> Invalid code length.</span>")
				return
			if (code == bp.lockcode)
				var/basePair/bpc = E.dnaBlocks.blockList[text2num(href_list["themark"])]
				bp.bpp1 = bpc.bpp1
				bp.bpp2 = bpc.bpp2
				bp.marker = "green"
				boutput(usr, "<span style=\"color:blue\"><strong>SCANNER ALERT:</strong> Decryption successful. Base pair unlocked.</span>")
				if (E.dnaBlocks.sequenceCorrect())
					E.dnaBlocks.ChangeAllMarkers("white")
			else
				if (bp.locktries <= 1)
					bp.lockcode = ""
					for (var/c = E.lockedDiff, c > 0, c--)
						bp.lockcode += pick(E.lockedChars)
					bp.locktries = E.lockedTries
					boutput(usr, "<span style=\"color:red\"><strong>SCANNER ALERT:</strong> Decryption failed. Base pair encryption code has mutated.</span>")
				else
					bp.locktries--
					var/length = lentext(bp.lockcode)

					var/list/lockcode_list = list()
					for (var/i=0,i < length,i++)
						lockcode_list["[copytext(bp.lockcode,i+1,i+2)]"]++

					var/correct_full = 0
					var/correct_char = 0
					var/current
					var/seek = 0
					for (var/i=0,i < length,i++)
						current = copytext(code,i+1,i+2)
						if (current == copytext(bp.lockcode,i+1,i+2))
							correct_full++
						seek = lockcode_list.Find(current)
						if (seek)
							correct_char++
							lockcode_list[current]--
							if (lockcode_list[current] <= 0)
								lockcode_list -= current

					boutput(usr, "<span style=\"color:red\"><strong>SCANNER ALERT:</strong> Decryption code \"[code]\" failed.</span>")
					boutput(usr, "<span style=\"color:red\">[correct_char]/[length] correct characters in entered code.</span>")
					boutput(usr, "<span style=\"color:red\">[correct_full]/[length] characters in correct position.</span>")
					boutput(usr, "<span style=\"color:red\">Attempts remaining: [bp.locktries].</span>")
		else
			switch(bp.marker)
				if ("green")
					bp.marker = "red"
				if ("red")
					bp.marker = "blue"
				if ("blue")
					bp.marker = "green"
		usr << link("byond://?src=\ref[src];viewpool=\ref[E]") // i hear ya buddy =(
		return

	else if (href_list["activatepool"])
		var/bioEffect/E = locate(href_list["activatepool"])
		if (bioEffect_sanity_check(E)) return
		if (!E.dnaBlocks.sequenceCorrect())
			return
		var/mob/living/subject = get_scan_subject()

		log_me(subject, "mutation activated", E)

		subject.bioHolder.ActivatePoolEffect(E)
		usr << link("byond://?src=\ref[src];menu=mutations")
		//send them to the mutations page.
		return

	else if (href_list["autocomplete"])
		var/bioEffect/E = locate(href_list["autocomplete"])
		if (bioEffect_sanity_check(E)) return
		var/mob/living/subject = get_scan_subject()
		if (!subject)
			return
		var/basePair/current
		var/basePair/correct
		for (var/i=0, i < E.dnaBlocks.blockListCurr.len, i++)
			current = E.dnaBlocks.blockListCurr[i+1]
			correct = E.dnaBlocks.blockList[i+1]
			if (current.marker == "locked")
				continue
			current.bpp1 = correct.bpp1
			current.bpp2 = correct.bpp2
			current.marker = "white"
		usr << link("byond://?src=\ref[src];viewpool=\ref[E]")
		return

	else if (href_list["viewopenres"])
		var/geneticsResearchEntry/E = locate(href_list["viewopenres"])
		if (research_sanity_check(E)) return
		backpage = "resopen"

		topbotbutton_html = ""
		info_html = {"
		<p>[E.name]<br><br>
		[E.desc]</p><br><br>
		<a href='?src=\ref[src];research=\ref[E]'>Research now</a>"}

	else if (href_list["researchmut"])
		var/bioEffect/E = locate(href_list["researchmut"])
		if (bioEffect_sanity_check(E)) return

		topbotbutton_html = ""
		if (!genResearch.addResearch(E))
			boutput(usr, "<strong>SCANNER ERROR: Unable to begin research.</strong>")
		else
			boutput(usr, "<strong>SCANNER:</strong> Research initiated successfully.")
		usr << link("byond://?src=\ref[src];viewpool=\ref[E]")
		return

	else if (href_list["researchmut_sample"])
		var/bioEffect/E = locate(href_list["researchmut_sample"])
		if (bioEffect_sanity_check(E,0)) return
		var/computer/file/genetics_scan/sample = locate(href_list["sample_to_research"])
		if (sample_sanity_check(sample)) return

		if (!genResearch.addResearch(E))
			boutput(usr, "<span style=\"color:red\"><strong>SCANNER ERROR:</strong> Unable to begin research.</span>")
		else
			boutput(usr, "<strong>SCANNER:</strong> Research initiated successfully.")

		usr << link("byond://?src=\ref[src];sample_viewpool=\ref[E];sample_to_viewpool=\ref[sample]")
		return

	else if (href_list["research"])
		var/geneticsResearchEntry/E = locate(href_list["research"])
		if (research_sanity_check(E)) return

		topbotbutton_html = ""
		if (genResearch.addResearch(E))
			boutput(usr, "<strong>SCANNER:</strong> Research initiated successfully.")
			usr << link("byond://?src=\ref[src];menu=resopen")
		else
			boutput(usr, "<span style=\"color:red\"><strong>SCANNER ERROR:</strong> Unable to begin research.</span>")
		return

	else if (href_list["track_research"])
		var/geneticsResearchEntry/R = locate(href_list["track_research"])
		if (!istype(R,/geneticsResearchEntry))
			return
		tracked_research = R
		usr << link("byond://?src=\ref[src];menu=resrunning")
		return

	else if (href_list["debug_erase"])
		if (!genResearch.debug_mode)
			return

		var/mob/subject = get_scan_subject()
		if (scanner)
			scanner.go_out()
		else if (istype(src,/obj/machinery/computer/genetics/portable))
			var/obj/machinery/computer/genetics/portable/please = src
			please.go_out()
		spawn (0)
			qdel(subject)

	else if (href_list["debug_create"])
		if (!genResearch.debug_mode)
			return

		if (get_scan_subject())
			return
		var/mob/subject

		if (scanner)
			subject = new /mob/living/carbon/human(get_turf(src))
			scanner.go_in(subject)
		else if (istype(src,/obj/machinery/computer/genetics/portable))
			var/obj/machinery/computer/genetics/portable/please = src
			subject = new /mob/living/carbon/human(get_turf(src))
			please.go_in(subject)
		else
			return

	else if (href_list["menu"])
		switch(href_list["menu"])
			if ("potential")
				var/mob/living/subject = get_scan_subject()
				if (!subject)
					boutput(usr, "<strong>SCANNER ALERT:</strong> Subject has absconded.")
					return
				topbotbutton_html = ""
				backpage = null

				topbotbutton_html = ui_build_clickable_genes("pool")

				info_html = "<p><strong>Occupant</strong>: [subject ? "[subject.name]" : "None"]</p><br>"
				info_html += "<p>Showing potential mutations</p><br>"
				if (equipment_available("emitter"))
					info_html += "<a href='?src=\ref[src];rademitter=1'>Scramble DNA</a>"

			if ("sample_potential")
				topbotbutton_html = ""

				var/computer/file/genetics_scan/sample = locate(href_list["sample_to_view_potential"])
				if (sample_sanity_check(sample)) return

				topbotbutton_html = ui_build_clickable_genes("sample_pool",sample)

				info_html = "<p><strong>Sample</strong>: [sample.subject_name] <small>([sample.subject_uID])</small></p><br>"
				info_html += "<p>Showing potential mutations <small><a href='?src=\ref[src];menu=dna_samples'>(Back)</a></small></p><br>"

			if ("mutations")
				var/mob/living/subject = get_scan_subject()
				if (!subject)
					boutput(usr, "<strong>SCANNER ALERT:</strong> Subject has absconded.")
					return
				topbotbutton_html = ""
				backpage = null

				topbotbutton_html = ui_build_clickable_genes("active")

				info_html = "<p><strong>Occupant</strong>: [subject ? "[subject.name]" : "None"]</p><br>"
				info_html += "<p>Showing active mutations</p>"

			if ("research")
				backpage = null
				topbotbutton_html = "<p><strong>Research Menu</strong><br>"
				topbotbutton_html += "<strong>Research Material:</strong> [genResearch.researchMaterial]/[genResearch.max_material]<br>"
				topbotbutton_html += "<strong>Research Budget:</strong> [wagesystem.research_budget] Credits<br>"
				topbotbutton_html += "<strong>Mutations Researched:</strong> [genResearch.mutations_researched]<br>"
				if (genResearch.isResearched(/geneticsResearchEntry/saver))
					topbotbutton_html += "<strong>Mutations Stored:</strong> [saved_mutations.len]/[genResearch.max_save_slots]</p>"

				info_html = "<br>"
				info_html += "<a href='?src=\ref[src];menu=buymats'>Purchase Additional Materials</a><br>"
				info_html += "<a href='?src=\ref[src];menu=resopen'>Available Research</a><br>"
				info_html += "<a href='?src=\ref[src];menu=resrunning'>Research in Progress</a><br>"
				info_html += "<a href='?src=\ref[src];menu=mutresearch'>Researched Mutations</a><br>"
				if (genResearch.isResearched(/geneticsResearchEntry/saver))
					info_html += "<a href='?src=\ref[src];menu=storedmuts'>Stored Mutations</a><br>"
				info_html += "<a href='?src=\ref[src];menu=chromosomes'>Stored Chromosomes</a><br>"
				info_html += "<a href='?src=\ref[src];menu=dna_samples'>View DNA Samples</a><br>"
				info_html += "<a href='?src=\ref[src];menu=resfin'>Finished Research</a><br>"

			if ("resopen")
				backpage = "research"
				topbotbutton_html = "<p><strong>Available Research</strong> - ([genResearch.researchMaterial] Research Materials)</p>"
				var/lastTier = -1
				info_html = ""
				for (var/R in genResearch.researchTreeTiered)
					if (text2num(R) == 0) continue
					var/list/tierList = genResearch.researchTreeTiered[R]
					if (text2num(R) != lastTier)
						info_html += "[info_html ? "<br>" : ""]<p><strong>Tier [text2num(R)]:</strong></p>"

					for (var/geneticsResearchEntry/C in tierList)
						if (!C.meetsRequirements())
							continue

						var/research_cost = C.researchCost
						if (genResearch.cost_discount)
							research_cost -= round(research_cost * genResearch.cost_discount)
						var/research_time = C.researchTime
						if (genResearch.time_discount)
							research_time -= round(research_time * genResearch.time_discount)
						if (research_time)
							research_time = round(research_time / 10)

						info_html += "<a href='?src=\ref[src];viewopenres=\ref[C]'>� [C.name] (Cost: [research_cost] * Time: [research_time] sec)</a><br>"

			if ("resrunning")
				backpage = "research"
				topbotbutton_html = "<p><strong>Research in Progress</strong></p>"
				info_html = "<p>"
				for (var/geneticsResearchEntry/R in genResearch.currentResearch)
					info_html += "� [R.name] - [round((R.finishTime - world.time) / 10)] seconds left."
					if (R != tracked_research)
						info_html += " <small><a href='?src=\ref[src];track_research=\ref[R]'>(Track)</a></small>"
					info_html += "<br>"
				info_html += "</p>"

			if ("buymats")
				var/amount = input("50 credits per 1 point.","Buying Materials") as null|num
				if (amount + genResearch.researchMaterial > genResearch.max_material)
					amount = genResearch.max_material - genResearch.researchMaterial
					boutput(usr, "You cannot exceed [genResearch.max_material] research materials with this option.")
				if (!amount || amount <= 0)
					return

				var/cost = amount * 50
				if (cost > wagesystem.research_budget)
					info_html = "<p>Insufficient research budget to make that transaction.</p>"
				else
					info_html = "<p>Transaction successful.</p>"
					wagesystem.research_budget -= cost
					genResearch.researchMaterial += amount

			if ("mutresearch")
				topbotbutton_html = "<p><strong>Mutation Research</strong></p>"

				backpage = "research"
				info_html = "<p>"
				var/bioEffect/BE
				for (var/X in bioEffectList)
					BE = bioEffectList[X]
					if (!BE.scanner_visibility || BE.research_level < 2)
						continue
					if (BE.research_level == 2)
						info_html += "- <a href='?src=\ref[src];researched_mutation=\ref[BE]'>[BE.name]</a><br>"
					else if (BE.research_level == 3)
						info_html += "* <a href='?src=\ref[src];researched_mutation=\ref[BE]'>[BE.name]</a><br>"
				info_html += "</p>"

			if ("storedmuts")
				topbotbutton_html = "<p><strong>Stored Mutations: [saved_mutations.len]/[genResearch.max_save_slots]</strong></p>"

				backpage = "research"
				info_html = "<p><a href='?src=\ref[src];menu=combinemuts'>Combine Mutations</a><br><br>"
				var/slot = 1
				for (var/bioEffect/BE in saved_mutations)
					info_html += "<a href='?src=\ref[src];stored_mut=\ref[BE]'><strong>Slot [slot]:</strong> [BE.name]</a><br>"
					slot++
				info_html += "</p>"

			if ("chromosomes")
				topbotbutton_html = "<p><strong>Stored Chromosomes</strong></p>"

				backpage = "research"
				info_html = ""
				var/slot = 1
				for (var/dna_chromosome/C in saved_chromosomes)
					info_html += "<a href='?src=\ref[src];stored_chromosome=\ref[C]'><strong>[slot]:</strong> [C.name]</a><br>"
					slot++
				info_html += "</p>"

			if ("combinemuts")
				topbotbutton_html = "<p><strong>Combine Mutations: [saved_mutations.len]/[genResearch.max_save_slots]</strong></p>"

				backpage = "storedmuts"
				info_html = "<p>"
				var/slot = 1
				info_html += "<a href='?src=\ref[src];do_combine=1'>Combine Marked Mutations</a><br>"
				info_html += "<a href='?src=\ref[src];cancel_combine=1'>Cancel</a><br><br>"

				for (var/bioEffect/BE in saved_mutations)
					info_html += "<a href='?src=\ref[src];mark_for_combination=\ref[BE]'><strong>Slot [slot]:</strong> [BE.name]</a>"
					if (BE in combining)
						info_html += " *"
					info_html += "<br>"
					slot++

				info_html += "</p>"

			if ("resfin")
				topbotbutton_html = "<p><strong>Finished Research</strong></p>"
				var/lastTier = -1
				backpage = "research"
				info_html = "<p>"
				for (var/R in genResearch.researchTreeTiered)
					if (text2num(R) == 0) continue
					var/list/tierList = genResearch.researchTreeTiered[R]
					if (text2num(R) != lastTier)
						info_html += "[info_html ? "<br>" : ""]<strong>Tier [text2num(R)]:</strong><br>"

					for (var/geneticsResearchEntry/C in tierList)
						if (C.isResearched == 0 || C.isResearched == -1) continue
						info_html += "� [C.name]<br>"
				info_html += "</p>"

			if ("dna_samples")
				backpage = "research"
				topbotbutton_html = "<p><strong>DNA Samples</strong></p>"

				info_html = "<p>"
				var/computer/file/genetics_scan/S = null
				for (var/data/record/R in data_core.medical)
					S = R.fields["dnasample"]
					if (!istype(S))
						continue
					info_html += "* <a href='?src=\ref[src];menu=sample_potential;sample_to_view_potential=\ref[S]'>[S.subject_name]</a><br>"
				info_html += "</p>"

			if ("appearance")
				topbotbutton_html = ""
				var/mob/living/subject = get_scan_subject()
				if (!subject)
					boutput(usr, "<strong>SCANNER ALERT:</strong> Subject has absconded.")
					return
				if (istype(subject, /mob/living/carbon/human))
					if (hasvar(subject, "mutantrace"))
						if (subject:mutantrace)
							topbotbutton_html = ""
							info_html = "<p>Can not change appearance of mutants.</p>"
						else

							log_me(subject, "appearance modifier accessed")

							new/genetics_appearancemenu(usr.client, subject)
							usr << browse(null, "window=genetics")
							usr.machine = null
				else
					topbotbutton_html = ""
					info_html = "<p>Can not change appearance of non-humans.</p>"

			if ("mutantrace")
				topbotbutton_html = ""
				var/mob/living/subject = get_scan_subject()
				if (!subject)
					boutput(usr, "<strong>SCANNER ALERT:</strong> Subject has absconded.")
					return
				var/list/options = list("Human")

				var/bioEffect/BE
				for (var/X in bioEffectList)
					BE = bioEffectList[X]
					if (BE.effectType == effectTypeMutantRace && BE.research_level >= 2 && BE.mutantrace_option)
						options += BE
					else continue

				if (istype(subject, /mob/living/carbon/human))
					var/mob/living/carbon/human/H = subject
					var/racepick = input(usr,"Change to which body type?","[name]") as null|anything in options
					if (racepick == "Human")

						if (!isnull(H.mutantrace))
							log_me(H, "mutantrace removed")

						H.set_mutantrace(null)
					else if (istype(racepick,/bioEffect/mutantrace) && H.bioHolder)
						var/bioEffect/mutantrace/MR = racepick
						//H.bioHolder.AddEffect(MR.id)
						H.set_mutantrace(MR.mutantrace_path)

						log_me(H, "mutantrace added", MR)

					else
						return

				else
					topbotbutton_html = ""
					info_html = "<p>Can not change body type of non-humans.</p>"

			if ("saveload")
				topbotbutton_html = ""
				//info_html = "<p>Temporary : </p><a href='?src=\ref[src];copyself=1'>Copy Occupant to Self</a>" Disabled due to shitlords

	add_fingerprint(usr)
	updateUsrDialog()
	return

/obj/machinery/computer/genetics/proc/equipment_available(var/equipment = "analyser",var/bioEffect/E)
	if (genResearch.debug_mode)
		return TRUE
	var/mob/living/subject = get_scan_subject()
	var/bioEffect/GBE
	if (istype(E))
		GBE = E.get_global_instance()
	switch(equipment)
		if ("analyser")
			if (genResearch.isResearched(/geneticsResearchEntry/checker) && world.time >= equipment[2])
				return TRUE
		if ("emitter")
			if (!istype(subject,/mob/living/carbon))
				return FALSE
			if (genResearch.isResearched(/geneticsResearchEntry/rademitter) && world.time >= equipment[3])
				return TRUE
		if ("precision_emitter")
			if (!istype(subject,/mob/living/carbon))
				//boutput(world, "failed carbon check")
				return FALSE
			if (!E)
				//boutput(world, "failed E check")
				return FALSE
			if (!GBE)
				//boutput(world, "failed GBE check")
				return FALSE
			if (GBE.research_level < 2)
				//boutput(world, "failed GBE level check")
				return FALSE
			if (E.can_scramble)
				if (genResearch.isResearched(/geneticsResearchEntry/rad_precision) && world.time >= equipment[3])
					return TRUE
		if ("reclaimer")
			if (E && GBE && GBE.research_level >= 2 && E.can_reclaim)
				if (genResearch.isResearched(/geneticsResearchEntry/reclaimer) && world.time >= equipment[4])
					return TRUE
		if ("injector")
			if (genResearch.researchMaterial < genResearch.injector_cost)
				return FALSE
			if (E && GBE && GBE.research_level >= 2 && E.can_make_injector)
				if (genResearch.isResearched(/geneticsResearchEntry/injector) && world.time >= equipment[1])
					if (genResearch.researchMaterial >= genResearch.injector_cost)
						return TRUE
		if ("activator")
			if (E && GBE && GBE.research_level >= 2 && E.can_make_injector)
				if (world.time >= equipment[1])
					return TRUE
		if ("saver")
			if (E && GBE && GBE.research_level >= 2)
				if (genResearch.isResearched(/geneticsResearchEntry/saver) && saved_mutations.len < genResearch.max_save_slots)
					return TRUE

	return FALSE

/obj/machinery/computer/genetics/proc/equipment_cooldown(var/equipment_num,var/time)
	if (genResearch.debug_mode)
		return
	if (!isnum(equipment_num) || !isnum(time))
		return
	if (equipment_num < 1 || equipment_num > src.equipment.len)
		return
	// Equipment Numbers:
	// 1) Injectors
	// 2) Analyser/Checker
	// 3) Emitters
	// 4) Reclaimer
	time *= genResearch.checkCooldownBonus()

	equipment[equipment_num] = world.time + time

/obj/machinery/computer/genetics/proc/ui_build_mutation_research(var/bioEffect/E,var/computer/file/genetics_scan/sample = null)
	if (!E)
		return null

	var/research_cost = genResearch.mut_research_cost
	if (genResearch.cost_discount)
		research_cost -= round(research_cost * genResearch.cost_discount)

	var/build = ""
	var/bioEffect/global_BE = E.get_global_instance()
	if (!global_BE)
		info_html += "<p>Genetic structure unknown. Research currently impossible.</p>"
		return

	switch(global_BE.research_level)
		if (0)
			if (E.can_research)
				if (istext(E.req_mut_research) && GetBioeffectResearchLevelFromGlobalListByID(E.id) < 2)
					info_html += "<p>Genetic structure unknown. Research currently impossible.</p>"
				else
					if (sample)
						info_html += "<p><a href='?src=\ref[src];researchmut_sample=\ref[E];sample_to_research=\ref[sample]'>Research required.</a>"
					else
						info_html += "<p><a href='?src=\ref[src];researchmut=\ref[E]'>Research required.</a>"
					if (research_cost > genResearch.researchMaterial)
						info_html += " <em>Material: [research_cost]/[genResearch.researchMaterial]</em></p>"
					else
						info_html += " Material: [research_cost]/[genResearch.researchMaterial]</p>"
			else
				info_html += "<p>Manual Research required.</p>"
		if (1)
			info_html += "<p>Currently under research.</p>"
		else
			info_html += "<p>[E.desc]</p>"

	return build

/obj/machinery/computer/genetics/proc/ui_build_sequence(var/bioEffect/E, var/screen = "pool")
	if (!E)
		return list("ERROR","ERROR","ERROR")

	var/list/build = list()

	var/top = ""
	var/mid = ""
	var/bot = ""

	switch(screen)
		if ("pool")
			for (var/i=0, i < E.dnaBlocks.blockListCurr.len, i++)
				var/blockEnd = (((i+1) % 4) == 0 ? 1 : 0)
				var/basePair/bp = E.dnaBlocks.blockListCurr[i+1]
				top += {"<a href='?src=\ref[src];setseq=\ref[E];setseq1=[i+1]'><img alt="" src="[resource("images/genetics/bp[bp.bpp1].png")]" style="border-style: none"></a>  [blockEnd ? {"<img alt="" src="[resource("images/genetics/bpSpacer.png")]">"} : ""]"}
				mid += {"<a href='?src=\ref[src];marker=\ref[E];themark=[i+1]'><img alt="" src="[resource("images/genetics/bpSep-[bp.marker].png")]" border=0></a>  [blockEnd ? {"<img alt="" src="[resource("images/genetics/bpSpacer.png")]" style="border-style: none">"} : ""]"}
				bot += {"<a href='?src=\ref[src];setseq=\ref[E];setseq2=[i+1]'><img alt="" src="[resource("images/genetics/bp[bp.bpp2].png")]" style="border-style: none"></a>  [blockEnd ? {"<img alt="" src="[resource("images/genetics/bpSpacer.png")]">"} : ""]"}
		if ("sample_pool")
			for (var/i=0, i < E.dnaBlocks.blockListCurr.len, i++)
				var/blockEnd = (((i+1) % 4) == 0 ? 1 : 0)
				var/basePair/bp = E.dnaBlocks.blockListCurr[i+1]
				top += {"<img alt="" src="[resource("images/genetics/bp[bp.bpp1].png")]" style="border-style: none">  [blockEnd ? {"<img alt="" src="[resource("images/genetics/bpSpacer.png")]">"} : ""]"}
				mid += {"<img alt="" src="[resource("images/genetics/bpSep-[bp.marker].png")]">  [blockEnd ? {"<img alt="" src="[resource("images/genetics/bpSpacer.png")]" style="border-style: none">"} : ""]"}
				bot += {"<img alt="" src="[resource("images/genetics/bp[bp.bpp2].png")]" style="border-style: none">  [blockEnd ? {"<img alt="" src="[resource("images/genetics/bpSpacer.png")]">"} : ""]"}
		if ("active")
			var/bioEffect/globalInstance = bioEffectList[E.id]
			for (var/i=0, i < globalInstance.dnaBlocks.blockList.len, i++)
				var/blockEnd = (((i+1) % 4) == 0 ? 1 : 0)
				var/basePair/bp = globalInstance.dnaBlocks.blockList[i+1]
				top += {"<img alt="" src="[resource("images/genetics/bp[bp.bpp1].png")]" style="border-style: none">  [blockEnd ? {"<img alt="" src="[resource("images/genetics/bpSpacer.png")]">"} : ""]"}
				mid += {"<img alt="" src="[resource("images/genetics/bpSep-[bp.marker].png")]">  [blockEnd ? {"<img alt="" src="[resource("images/genetics/bpSpacer.png")]" style="border-style: none">"} : ""]"}
				bot += {"<img alt="" src="[resource("images/genetics/bp[bp.bpp2].png")]" style="border-style: none">  [blockEnd ? {"<img alt="" src="[resource("images/genetics/bpSpacer.png")]">"} : ""]"}

	build += top
	build += mid
	build += bot

	return build

/obj/machinery/computer/genetics/proc/ui_build_clickable_genes(var/screen = "pool",var/computer/file/genetics_scan/sample)
	if (screen == "sample_pool")
		if (!sample)
			return
	else
		var/mob/living/carbon/human/subject = get_scan_subject()
		if (!subject)
			boutput(usr, "<strong>SCANNER ALERT:</strong> Subject has absconded.")
			return

	var/build = ""
	var/gene_icon_status = "mutGrey.png"
	var/bioEffect/GBE
	switch(screen)
		if ("sample_pool")
			for (var/bioEffect/E in sample.dna_pool)
				GBE = E.get_global_instance()
				if (GBE.secret && !genResearch.see_secret)
					continue
				switch(GBE.research_level)
					if (0,null)
						gene_icon_status = "mutGrey.png"
					if (1)
						gene_icon_status = "mutGrey2.png"
					if (2)
						gene_icon_status = "mutYellow.png"
					if (3)
						gene_icon_status = "mutGreen.png"
				build += {"<a href='?src=\ref[src];sample_viewpool=\ref[E];sample_to_viewpool=\ref[sample]'>"}
				build += {"<img style="border: [E == currently_browsing ? "solid 1px #00FFFF" : "dotted 1px #88C425"]" src="[resource("images/genetics/[gene_icon_status]")]" alt="[GBE.research_level >= 2  ? E.name : "???"]" width="43" height="39"></a>"}

		if ("pool")
			var/mob/living/subject = get_scan_subject()
			var/bioEffect/E
			for (var/ID in subject.bioHolder.effectPool)
				E = subject.bioHolder.GetEffectFromPool(ID)
				GBE = E.get_global_instance()
				if (GBE.secret && !genResearch.see_secret)
					continue
				switch(GBE.research_level)
					if (0,null)
						gene_icon_status = "mutGrey.png"
					if (1)
						gene_icon_status = "mutGrey2.png"
					if (2)
						gene_icon_status = "mutYellow.png"
					if (3)
						gene_icon_status = "mutGreen.png"
				build += {"<a href='?src=\ref[src];viewpool=\ref[E]'>"}
				build += {"<img style="border: [E == currently_browsing ? "solid 1px #00FFFF" : "dotted 1px #88C425"]" src="[resource("images/genetics/[gene_icon_status]")]" alt="[GBE.research_level >= 2  ? E.name : "???"]" width="43" height="39"></a>"}

		if ("active")
			var/mob/living/subject = get_scan_subject()
			var/bioEffect/E
			for (var/ID in subject.bioHolder.effects)
				E = subject.bioHolder.GetEffect(ID)
				GBE = E.get_global_instance()
				if (GBE.secret && !genResearch.see_secret)
					continue
				if (!E.scanner_visibility)
					continue
				switch(GBE.research_level)
					if (0,null)
						gene_icon_status = "mutGrey.png"
					if (1)
						gene_icon_status = "mutGrey2.png"
					if (2)
						gene_icon_status = "mutYellow.png"
					if (3)
						gene_icon_status = "mutGreen.png"
				build += {"<a href='?src=\ref[src];vieweffect=\ref[E]'>"}
				build += {"<img style="border: [E == currently_browsing ? "solid 1px #00FFFF" : "dotted 1px #88C425"]" src="[resource("images/genetics/[gene_icon_status]")]" alt="[GBE.research_level >= 2  ? E.name : "???"]" width="43" height="39"></a>"}

	return build

/obj/machinery/computer/genetics/proc/get_scan_subject()
	if (!src)
		return null
	if (scanner && scanner.occupant)
		return scanner.occupant
	else
		return null

/obj/machinery/computer/genetics/proc/get_scanner()
	if (!src)
		return null
	if (scanner)
		return scanner
	return null

/obj/machinery/computer/genetics/power_change()
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

// There weren't any (Convair880)!
/obj/machinery/computer/genetics/proc/log_me(var/mob/M, var/action = "", var/bioEffect/BE)
	if (!src || !M || !ismob(M) || !action)
		return

	logTheThing("station", usr, M, "uses [name] on %target%[M.bioHolder ? " (Genetic stability: [M.bioHolder.genetic_stability])" : ""] at [log_loc(src)]. Action: [action][BE && istype(BE, /bioEffect) ? ". Gene: [BE] (Stability impact: [BE.stability_loss])" : ""]")
	return