/*
Contains:
- Uplink parent
- Generic Syndicate uplink
- Integrated uplink (PDA & headset)
- Wizard's spellbook

Note: Add new traitor items to syndicate_buylist.dm, not here.
      Every type of Syndicate uplink now includes support for job- and objective-specific items.
*/

/////////////////////////////////////////// Uplink parent ////////////////////////////////////////////

/obj/item/uplink
	name = "uplink"
	stamina_damage = 25
	stamina_cost = 25
	stamina_crit_chance = 10

	var/uses = 12 // Amount of telecrystals.
	var/list/syndicate_buylist/items_general = list() // See setup().
	var/list/syndicate_buylist/items_job = list()
	var/list/syndicate_buylist/items_objective = list()
	var/is_VR_uplink = 0
	var/lock_code = null
	var/lock_code_autogenerate = 0
	var/locked = 0

	var/use_default_GUI = 0 // Use the parent's HTML interface (less repeated code).
	var/temp = null
	var/selfdestruct = 0
	var/can_selfdestruct = 0
	var/syndicate_buylist/reading_about = null

	// Spawned uplinks for which setup() wasn't called manually only get the standard (generic) items.
	New()
		spawn (10)
			if (src && istype(src) && (!items_general.len && !items_job.len && !items_objective.len))
				setup()
		return

	proc/generate_code()
		if (!src || !istype(src))
			return

		var/code = "[rand(100,999)] [pick("Alpha","Bravo","Delta","Omega","Gamma","Zeta")]"
		return code

	proc/setup(var/mind/ownermind, var/obj/item/device/master)
		if (!src || !istype(src))
			return

		if (!islist(items_general))
			items_general = list()
		if (!islist(items_job))
			items_job = list()
		if (!islist(items_objective))
			items_objective = list()

		for (var/syndicate_buylist/S in syndi_buylist_cache)
			var/blocked = 0
			if (ticker && ticker.mode && S.blockedmode && islist(S.blockedmode) && S.blockedmode.len)
				for (var/V in S.blockedmode)
					if (ispath(V) && istype(ticker.mode, V) && !is_VR_uplink) // No meta by checking VR uplinks.
						blocked = 1
						break

			if (blocked == 0)
				if (istype(S, /syndicate_buylist/surplus))
					continue
				if (istype(S, /syndicate_buylist/generic) && !items_general.Find(S))
					items_general.Add(S)

				if (ownermind || istype(ownermind))
					if (ownermind.special_role != "nukeop" && istype(S, /syndicate_buylist/traitor))
						if (!S.objective && !S.job && !items_general.Find(S))
							items_general.Add(S)

					if (S.objective)
						if (ownermind.objectives)
							var/has_objective = 0
							for (var/objective/O in ownermind.objectives)
								if (istype(O, S.objective))
									has_objective = 1
							if (has_objective && !items_objective.Find(S))
								items_objective.Add(S)

					if (S.job)
						for (var/allowedjob in S.job)
							if (ownermind.assigned_role && ownermind.assigned_role == allowedjob && !items_job.Find(S))
								items_job.Add(S)

		// Sort alphabetically by item name.
		var/list/names = list()
		var/list/namecounts = list()

		if (items_general.len)
			var/list/sort1 = list()

			for (var/syndicate_buylist/S1 in items_general)
				var/name = S1.name
				if (name in names) // Should never, ever happen, but better safe than sorry.
					namecounts[name]++
					name = text("[] ([])", name, namecounts[name])
				else
					names.Add(name)
					namecounts[name] = 1

				sort1[name] = S1

			items_general = sortList(sort1)

		if (items_job.len)
			var/list/sort2 = list()

			for (var/syndicate_buylist/S2 in items_job)
				var/name = S2.name
				if (name in names)
					namecounts[name]++
					name = text("[] ([])", name, namecounts[name])
				else
					names.Add(name)
					namecounts[name] = 1

				sort2[name] = S2

			items_job = sortList(sort2)

		if (items_objective.len)
			var/list/sort3 = list()

			for (var/syndicate_buylist/S3 in items_objective)
				var/name = S3.name
				if (name in names)
					namecounts[name]++
					name = text("[] ([])", name, namecounts[name])
				else
					names.Add(name)
					namecounts[name] = 1

				sort3[name] = S3

			items_objective = sortList(sort3)

		return

	proc/vr_check(var/mob/user)
		if (!src || !istype(src) || !user || !ismob(user))
			return FALSE
		if (is_VR_uplink == 0)
			return TRUE

		var/area/A = get_area(user)
		if (!A || !istype(A, /area/sim))
			return FALSE
		else
			return TRUE

	proc/explode()
		if (!src || !istype(src))
			return

		if (can_selfdestruct == 1)
			var/turf/location = get_turf(loc)
			if (location && isturf(location))
				location.hotspot_expose(700,125)
				explosion(src, location, 0, 0, 2, 4)
			qdel(src)

		return

	attack_self(mob/user as mob)
		if (vr_check(user) != 1)
			user.show_text("This uplink only works in virtual reality.", "red")
		else if (use_default_GUI == 1)
			user.machine = src
			generate_menu()
		return

	proc/generate_menu()
		if (uses < 0)
			uses = 0
		if (use_default_GUI == 0)
			return

		var/dat
		if (selfdestruct)
			dat = "Self Destructing..."

		else if (locked && !isnull(lock_code))
			dat = "The uplink is locked. <A href='byond://?src=\ref[src];unlock=1'>Enter password</A>.<BR>"

		else if (reading_about)
			var/item_about = "<strong>Error:</strong> We're sorry, but there is no current entry for this item!<br>For full information on Syndicate Tools, call 1-555-SYN-DKIT."
			if (reading_about.desc) item_about = "[reading_about.desc]"
			dat += "<strong>Extended Item Information:</strong><hr>[item_about]<hr><A href='byond://?src=\ref[src];back=1'>Back</A>"

		else
			if (temp)
				dat = "[temp]<BR><BR><A href='byond://?src=\ref[src];temp=1'>Clear</A>"
			else
				if (is_VR_uplink)
					dat = "<strong><U>Syndicate Simulator 2053!</U></strong><BR>"
					dat += "Buy the Cat Armor DLC today! Only 250 Credits!"
					dat += "<HR>"
					dat += "<strong>Sandbox mode - Spawn item:</strong><BR><table cellspacing=5>"
				else
					dat = "<strong>Syndicate Uplink Console:</strong><BR>"
					dat += "Tele-Crystals left: [uses]<BR>"
					dat += "<HR>"
					dat += "<strong>Request item:</strong><BR>"
					dat += "<em>Each item costs a number of tele-crystals as indicated by the number following their name.</em><BR><table cellspacing=5>"

				if (items_general && islist(items_general) && items_general.len)
					for (var/G in items_general)
						var/syndicate_buylist/I1 = items_general[G]
						dat += "<tr><td><A href='byond://?src=\ref[src];spawn=\ref[items_general[G]]'>[I1.name]</A> ([I1.cost])</td><td><A href='byond://?src=\ref[src];about=\ref[items_general[G]]'>About</A></td>"
				if (items_job && islist(items_job) && items_job.len)
					dat += "</table><strong>Job specific:</strong><BR><table cellspacing=5>"
					for (var/J in items_job)
						var/syndicate_buylist/I2 = items_job[J]
						dat += "<tr><td><A href='byond://?src=\ref[src];spawn=\ref[items_job[J]]'>[I2.name]</A> ([I2.cost])</td><td><A href='byond://?src=\ref[src];about=\ref[items_job[J]]'>About</A></td>"
				if (items_objective && islist(items_objective) && items_objective.len)
					dat += "</table><strong>Objective specific:</strong><BR><table cellspacing=5>"
					for (var/O in items_objective)
						var/syndicate_buylist/I3 = items_objective[O]
						dat += "<tr><td><A href='byond://?src=\ref[src];spawn=\ref[items_objective[O]]'>[I3.name]</A> ([I3.cost])</td><td><A href='byond://?src=\ref[src];about=\ref[items_objective[O]]'>About</A></td>"

				dat += "</table>"
				var/do_divider = 1

				if (istype(src, /obj/item/uplink/integrated/radio))
					var/obj/item/uplink/integrated/radio/RU = src
					if (!isnull(RU.origradio) && istype(RU.origradio, /obj/item/device/radio))
						dat += "<HR><A href='byond://?src=\ref[src];lock=1'>Lock</A><BR>"
						do_divider = 0
				else if (is_VR_uplink == 0 && !isnull(lock_code))
					dat += "<HR><A href='byond://?src=\ref[src];lock=1'>Lock</A><BR>"
					do_divider = 0

				if (can_selfdestruct == 1)
					dat += "[do_divider == 1 ? "<HR>" : ""]<A href='byond://?src=\ref[src];selfdestruct=1'>Self-Destruct</A>"

		usr << browse(dat, "window=radio")
		onclose(usr, "radio")
		return

#define CHECK1 (get_dist(src, usr) > 1 || !usr.contents.Find(src) || !isliving(usr) || iswraith(usr) || isintangible(usr))
#define CHECK2 (usr.stunned > 0 || usr.weakened > 0 || usr.paralysis > 0 || usr.stat != 0 || usr.restrained())
	Topic(href, href_list)
		..()
		if (uses < 0)
			uses = 0
		if (use_default_GUI == 0)
			return
		if (CHECK1)
			return
		if (CHECK2)
			return
		if (vr_check(usr) != 1)
			usr.show_text("This uplink only works in virtual reality.", "red")
			return

		usr.machine = src

		if (href_list["unlock"] && locked && !isnull(lock_code))
			var/the_code = adminscrub(input(usr, "Please enter the password.", "Unlock Uplink", null))
			if (!src || !istype(src) || !usr || !ismob(usr) || CHECK1 || CHECK2)
				return
			if (isnull(the_code) || !cmptext(the_code, lock_code))
				usr.show_text("Incorrect password.", "red")
				return

			locked = 0
			usr.show_text("The uplink beeps softly and unlocks.", "blue")

		else if (href_list["lock"])
			if (istype(src, /obj/item/uplink/integrated/radio))
				var/obj/item/uplink/integrated/radio/RU = src
				if (!isnull(RU.origradio) && istype(RU.origradio, /obj/item/device/radio))
					usr.machine = null
					usr << browse(null, "window=radio")
					var/obj/item/device/radio/T = RU.origradio
					RU.set_loc(T)
					T.set_loc(usr)
					usr.u_equip(RU)
					usr.put_in_hand_or_drop(T)
					RU.set_loc(T)
					T.set_frequency(initial(T.frequency))
					T.attack_self(usr)
					return

			else if (locked == 0 && is_VR_uplink == 0)
				locked = 1
				usr.show_text("The uplink is now locked.", "blue")

		else if (href_list["spawn"])
			var/syndicate_buylist/I = locate(href_list["spawn"])
			if (!I || !istype(I))
				usr.show_text("Something went wrong (invalid syndicate_buylist reference). Please try again and contact a coder if the problem persists.", "red")
				return

			if (is_VR_uplink == 0)
				if (uses < I.cost)
					boutput(usr, "<span style=\"color:red\">The uplink doesn't have enough telecrystals left for that!</span>")
					return
				uses = max(0, uses - I.cost)
				if (usr.mind)
					usr.mind.purchased_traitor_items += I

			if (I.item)
				var/obj/item = new I.item(get_turf(src))
				I.run_on_spawn (item, usr)
				if (is_VR_uplink == 0)
					statlog_traitor_item(usr, I.name, I.cost)
			if (I.item2)
				new I.item2(get_turf(src))
			if (I.item3)
				new I.item3(get_turf(src))

		else if (href_list["about"])
			reading_about = locate(href_list["about"])

		else if (href_list["back"])
			reading_about = null

		else if (href_list["selfdestruct"] && can_selfdestruct == 1)
			selfdestruct = 1
			spawn (100)
				if (src)
					explode()

		else if (href_list["temp"])
			temp = null

		attack_self(usr)
		return
#undef CHECK1
#undef CHECK2

/////////////////////////////////////////////// Syndicate uplink ////////////////////////////////////////////

/obj/item/uplink/syndicate
	name = "station bounced radio"
	icon = 'icons/obj/device.dmi'
	icon_state = "radio"
	flags = FPRINT | TABLEPASS | CONDUCT | ONBELT
	w_class = 2.0
	item_state = "radio"
	throw_speed = 4
	throw_range = 20
	m_amt = 100
	use_default_GUI = 1
	can_selfdestruct = 1

	setup(var/mind/ownermind, var/obj/item/device/master)
		..()
		if (lock_code_autogenerate == 1)
			lock_code = generate_code()
			locked = 1

		return

/obj/item/uplink/syndicate/virtual
	name = "Syndicate Simulator 2053"
	desc = "Pretend you are a space terrorist! Harmless VR fun for all the family!"
	uses = INFINITY
	is_VR_uplink = 1
	can_selfdestruct = 0

	explode()
		temp = "Bang! Just kidding."
		return

///////////////////////////////////////////////// Integrated uplinks (PDA & headset) //////////////////////////////////

/obj/item/uplink/integrated
	name = "uplink module"
	desc = "An electronic uplink system of unknown origin."
	icon = 'icons/obj/module.dmi'
	icon_state = "power_mod"
	can_selfdestruct = 0

	explode()
		return

/obj/item/uplink/integrated/pda
	lock_code_autogenerate = 1
	var/obj/item/device/pda2/hostpda = null
	var/orignote = null //Restore original notes when locked.
	var/active = 0 //Are we currently active??
	var/menu_message = ""

	setup(var/mind/ownermind, var/obj/item/device/master)
		..()
		if (master && istype(master))
			if (istype(master, /obj/item/device/pda2))
				var/obj/item/device/pda2/P = master
				P.uplink = src
				if (lock_code_autogenerate == 1)
					lock_code = generate_code()
				src.hostpda = P
		return

	proc/unlock()
		if ((isnull(src.hostpda)))
			return

		if (active)
			src.hostpda.host_program:mode = 1
			return

		if (istype(src.hostpda.host_program, /computer/file/pda_program/os/main_os))

			src.orignote = src.hostpda.host_program:note
			active = 1
			src.hostpda.host_program:mode = 1 //Switch right to the notes program

		generate_menu()
		print_to_host(menu_message)
		return

	//Communicate with traitor through the PDA's note function.
	proc/print_to_host(var/text)
		if (isnull(src.hostpda))
			return

		if (!istype(src.hostpda.host_program, /computer/file/pda_program/os/main_os))
			return
		src.hostpda.host_program:note = text

		for (var/mob/M in viewers(1, src.hostpda.loc))
			if (M.client && M.machine == src.hostpda)
				src.hostpda.attack_self(M)

		return

	//Let's build a menu!
	generate_menu()
		if (uses < 0)
			uses = 0
		if (vr_check(usr) != 1)
			menu_message = "This uplink only works in virtual reality."
			return

		menu_message = "<strong>Syndicate Uplink Console:</strong><BR>"
		menu_message += "Tele-Crystals left: [uses]<BR>"
		menu_message += "<HR>"
		menu_message += "<strong>Request item:</strong><BR>"
		menu_message += "<em>Each item costs a number of tele-crystals as indicated by the number following their name.</em><BR><table cellspacing=5>"

		if (items_general && islist(items_general) && items_general.len)
			for (var/G in items_general)
				var/syndicate_buylist/I1 = items_general[G]
				menu_message += "<tr><td><A href='byond://?src=\ref[src];buy_item=\ref[items_general[G]]'>[I1.name]</A> ([I1.cost])</td><td><A href='byond://?src=\ref[src];abt_item=\ref[items_general[G]]'>About</A></td>"
		if (items_job && islist(items_job) && items_job.len)
			menu_message += "</table><strong>Job specific:</strong><BR><table cellspacing=5>"
			for (var/J in items_job)
				var/syndicate_buylist/I2 = items_job[J]
				menu_message += "<tr><td><A href='byond://?src=\ref[src];buy_item=\ref[items_job[J]]'>[I2.name]</A> ([I2.cost])</td><td><A href='byond://?src=\ref[src];abt_item=\ref[items_job[J]]'>About</A></td>"
		if (items_objective && islist(items_objective) && items_objective.len)
			menu_message += "</table><strong>Objective specific:</strong><BR><table cellspacing=5>"
			for (var/O in items_objective)
				var/syndicate_buylist/I3 = items_objective[O]
				menu_message += "<tr><td><A href='byond://?src=\ref[src];buy_item=\ref[items_objective[O]]'>[I3.name]</A> ([I3.cost])</td><td><A href='byond://?src=\ref[src];abt_item=\ref[items_objective[O]]'>About</A></td>"

		menu_message += "</table><HR>"
		return

	Topic(href, href_list)
		if (uses < 0)
			uses = 0
		if (isnull(src.hostpda) || !src.active)
			return
		if (get_dist(src.hostpda, usr) > 1 || !usr.contents.Find(src.hostpda) || !isliving(usr) || iswraith(usr) || isintangible(usr))
			return
		if (usr.stunned > 0 || usr.weakened > 0 || usr.paralysis > 0 || usr.stat != 0 || usr.restrained())
			return
		if (vr_check(usr) != 1)
			usr.show_text("This uplink only works in virtual reality.", "red")
			return

		if (href_list["buy_item"])
			var/syndicate_buylist/I = locate(href_list["buy_item"])
			if (!I || !istype(I))
				usr.show_text("Something went wrong (invalid syndicate_buylist reference). Please try again and contact a coder if the problem persists.", "red")
				return

			if (is_VR_uplink == 0)
				if (uses < I.cost)
					boutput(usr, "<span style=\"color:red\">The uplink doesn't have enough telecrystals left for that!</span>")
					return
				uses = max(0, uses - I.cost)
				if (usr.mind)
					usr.mind.purchased_traitor_items += I

			if (I.item)
				var/obj/item = new I.item(get_turf(src.hostpda))
				I.run_on_spawn (item, usr)
				if (is_VR_uplink == 0)
					statlog_traitor_item(usr, I.name, I.cost)
			if (I.item2)
				new I.item2(get_turf(src.hostpda))
			if (I.item3)
				new I.item3(get_turf(src.hostpda))

		else if (href_list["abt_item"])
			var/syndicate_buylist/I = locate(href_list["abt_item"])
			var/item_about = "<strong>Error:</strong> We're sorry, but there is no current entry for this item!<br>For full information on Syndicate Tools, call 1-555-SYN-DKIT."
			if (I.desc) item_about = I.desc

			print_to_host("<strong>Extended Item Information:</strong><hr>[item_about]<hr><A href='byond://?src=\ref[src];back=1'>Back</A>")
			return

		/*else if (href_list["back"])
			generate_menu()
			print_to_host(menu_message)
			return*/

		generate_menu()
		print_to_host(menu_message)
		return

/obj/item/uplink/integrated/radio
	lock_code_autogenerate = 1
	use_default_GUI = 1
	var/obj/item/device/radio/origradio = null

	generate_code()
		if (!src || !istype(src))
			return

		var/freq = 1441
		var/list/freqlist = list()
		while (freq <= 1489)
			if (freq < 1451 || freq > 1459)
				freqlist += freq
			freq += 2
			if ((freq % 2) == 0)
				freq += 1
		freq = freqlist[rand(1, freqlist.len)]
		return freq

	setup(var/mind/ownermind, var/obj/item/device/master)
		..()
		if (master && istype(master))
			if (istype(master, /obj/item/device/radio))
				var/obj/item/device/radio/R = master
				R.traitorradio = src
				if (lock_code_autogenerate == 1)
					R.traitor_frequency = generate_code()
				R.protected_radio = 1
				name = R.name
				icon = R.icon
				icon_state = R.icon_state
				origradio = R
		return

///////////////////////////////////////// Wizard's spellbook ///////////////////////////////////////////////////

/obj/item/SWF_uplink
	name = "Spellbook"
	icon = 'icons/obj/wizard.dmi'
	icon_state = "spellbook"
	item_state = "spellbook"
	var/wizard_key = ""
	var/temp = null
	var/uses = 4
	var/selfdestruct = 0
	var/traitor_frequency = 0
	var/obj/item/device/radio/origradio = null
	var/list/spells = list()
	flags = FPRINT | ONBELT | TABLEPASS
	throwforce = 5
	w_class = 2
	throw_speed = 4
	throw_range = 20
	m_amt = 100

	New()
		..()
		spells += new /SWFuplinkspell/soulguard(src)
		spells += new /SWFuplinkspell/staffofcthulhu(src)
		spells += new /SWFuplinkspell/fireball(src)
		spells += new /SWFuplinkspell/shockingtouch(src)
		spells += new /SWFuplinkspell/iceburst(src)
		spells += new /SWFuplinkspell/blind(src)
		spells += new /SWFuplinkspell/clownsrevenge(src)
		spells += new /SWFuplinkspell/rathensecret(src)
		spells += new /SWFuplinkspell/forcewall(src)
		spells += new /SWFuplinkspell/blink(src)
		spells += new /SWFuplinkspell/teleport(src)
		spells += new /SWFuplinkspell/warp(src)
		spells += new /SWFuplinkspell/spellshield(src)
		spells += new /SWFuplinkspell/doppelganger(src)
		spells += new /SWFuplinkspell/knock(src)
		spells += new /SWFuplinkspell/empower(src)
		spells += new /SWFuplinkspell/summongolem(src)
		spells += new /SWFuplinkspell/animatedead(src)
		spells += new /SWFuplinkspell/pandemonium(src)
		//spells += new /SWFuplinkspell/shockwave(src)
		spells += new /SWFuplinkspell/bull(src)

/SWFuplinkspell
	var/name = "Spell"
	var/eqtype = "Spell"
	var/desc = "This is a spell."
	var/cost = 1
	var/cooldown = null
	var/assoc_spell = null
	var/obj/item/assoc_item = null

	proc/SWFspell_CheckRequirements(var/mob/living/carbon/human/user,var/obj/item/SWF_uplink/book)
		if (!user || !book)
			return 999 // unknown error
		if (book.uses < cost)
			return TRUE // ran out of points
		if (assoc_spell)
			if (user.abilityHolder.getAbility(assoc_spell))
				return 2

	proc/SWFspell_Purchased(var/mob/living/carbon/human/user,var/obj/item/SWF_uplink/book)
		if (!user || !book)
			return
		if (assoc_spell)
			user.abilityHolder.addAbility(assoc_spell)
		if (assoc_item)
			var/obj/item/I = new assoc_item(usr.loc)
			if (istype(I, /obj/item/staff) && usr.mind)
				var/obj/item/staff/S = I
				S.wizard_key = usr.mind.key
		book.uses -= cost

/SWFuplinkspell/soulguard
	name = "Soulguard"
	eqtype = "Enchantment"
	desc = "Soulguard is basically a one-time do-over that teleports you back to the wizard shuttle and restores your life in the event that you die. However, the enchantment doesn't trigger if your body has been gibbed or otherwise destroyed. Also note that you will respawn completely naked."

	SWFspell_CheckRequirements(var/mob/living/carbon/human/user,var/obj/item/SWF_uplink/book)
		. = ..()
		if (user.spell_soulguard) return 2

	SWFspell_Purchased(var/mob/living/carbon/human/user,var/obj/item/SWF_uplink/book)
		..()
		user.spell_soulguard = 1

/SWFuplinkspell/staffofcthulhu
	name = "Staff of Cthulhu"
	eqtype = "Equipment"
	desc = "The crew will normally steal your staff and run off with it to cripple your casting abilities, but that doesn't work so well with this version. Any non-wizard dumb enough to touch or pull the Staff of Cthulhu takes massive brain damage and is knocked down for quite a while, and hiding the staff in a closet or somewhere else is similarly ineffective given that you can summon it to your active hand at will. It also makes a much better bludgeoning weapon than the regular staff, hitting harder and occasionally inflicting brain damage."
	assoc_spell = /targetable/spell/summon_staff
	assoc_item = /obj/item/staff/cthulhu

/SWFuplinkspell/bull
	name = "Bull's Charge"
	eqtype = "Offensive"
	desc = "Records your movement for 4 seconds, after which a massive bull charges along the recorded path, smacking anyone unfortunate to get in its way (excluding yourself) and dealing a significant amount of brute damage in the process. Watch your head for loose items, they are thrown around too."
	cooldown = 15
	assoc_spell = /targetable/spell/bullcharge

/SWFuplinkspell/shockwave
	name = "Shockwave"
	eqtype = "Offensive"
	desc = "This spell will violently throw back any nearby objects or people.<br>Cooldown:"
	cooldown = 40
	assoc_spell = /targetable/spell/shockwave

/SWFuplinkspell/fireball
	name = "Fireball"
	eqtype = "Offensive"
	desc = "This spell allows you to fling a fireball at a nearby target of your choice. The fireball will explode, knocking down and burning anyone too close, including you."
	cooldown = 20
	assoc_spell = /targetable/spell/fireball
/*
/SWFuplinkspell/shockinggrasp
	name = "Shocking Grasp"
	eqtype = "Offensive"
	desc = "This spell cannot be used on a moving target due to the need for a very short charging sequence, but will instantly kill them, destroy everything they're wearing, and vaporize their body."
	cooldown = 60
	assoc_spell = /targetable/spell/kill
*/
/SWFuplinkspell/shockingtouch
	name = "Shocking Touch"
	eqtype = "Offensive"
	desc = "This spell cannot be used on a moving target due to the need for a very short charging sequence, but will instantly put them in critical condition, and shock and stun anyone close to them."
	cooldown = 80
	assoc_spell = /targetable/spell/shock

/SWFuplinkspell/iceburst
	name = "Ice Burst"
	eqtype = "Offensive"
	desc = "This spell fires freezing cold projectiles that will temporarily freeze the floor beneath them, and slow down targets on contact."
	cooldown = 20
	assoc_spell = /targetable/spell/iceburst

/SWFuplinkspell/blind
	name = "Blind"
	eqtype = "Offensive"
	desc = "This spell temporarily blinds and stuns a target of your choice."
	cooldown = 10
	assoc_spell = /targetable/spell/blind

/SWFuplinkspell/clownsrevenge
	name = "Clown's Revenge"
	eqtype = "Offensive"
	desc = "This spell turns an adjacent target into an obese, idiotic, horrible, and useless clown."
	cooldown = 125
	assoc_spell = /targetable/spell/cluwne

/SWFuplinkspell/rathensecret
	name = "Rathen's Secret"
	eqtype = "Offensive"
	desc = "This spell summons a shockwave that rips the arses off of your foes. If you're lucky, the shockwave might even sever an arm or leg."
	cooldown = 50
	assoc_spell = /targetable/spell/rathens

/*/SWFuplinkspell/lightningbolt
	name = "Lightning Bolt"
	eqtype = "Offensive"
	desc = "Fires a bolt of electricity in a cardinal direction. Causes decent damage, and can go through thin walls and solid objects. You need special HAZARDOUS robes to cast this!"
	cooldown = 20
	assoc_verb = */

/SWFuplinkspell/forcewall
	name = "Forcewall"
	eqtype = "Defensive"
	desc = "This spell creates an unbreakable wall from where you stand that extends to your sides. It lasts for 30 seconds."
	cooldown = 10
	assoc_spell = /targetable/spell/forcewall

/SWFuplinkspell/blink
	name = "Blink"
	eqtype = "Defensive"
	desc = "This spell teleports you a short distance forwards. Useful for evasion or getting into areas."
	cooldown = 10
	assoc_spell = /targetable/spell/blink

/SWFuplinkspell/teleport
	name = "Teleport"
	eqtype = "Defensive"
	desc = "This spell teleports you to an area of your choice, but requires a short time to charge up."
	cooldown = 45
	assoc_spell = /targetable/spell/teleport

/SWFuplinkspell/warp
	name = "Warp"
	eqtype = "Defensive"
	desc = "This spell teleports a visible foe away from you."
	cooldown = 10
	assoc_spell = /targetable/spell/warp

/SWFuplinkspell/spellshield
	name = "Spell Shield"
	eqtype = "Defensive"
	desc = "This spell encases you in a magical shield that protects you from melee attacks and projectiles for 10 seconds. It also absorbs some of the blast of explosions."
	cooldown = 30
	assoc_spell = /targetable/spell/magshield

/SWFuplinkspell/doppelganger
	name = "Doppelganger"
	eqtype = "Defensive"
	desc = "This spell projects a decoy in the direction you were moving while rendering you invisible and capable of moving through solid matter for a few moments."
	cooldown = 30
	assoc_spell = /targetable/spell/doppelganger

/SWFuplinkspell/knock
	name = "Knock"
	eqtype = "Utility"
	desc = "This spell opens all doors, lockers, and crates up to five tiles away. It also blows open cyborg head compartments, damaging them and exposing their brains."
	cooldown = 10
	assoc_spell = /targetable/spell/knock

/SWFuplinkspell/empower
	name = "Empower"
	eqtype = "Utility"
	desc = "This spell causes you to turn into a hulk, and gain telekinesis for a short while."
	cooldown = 40
	assoc_spell = /targetable/spell/mutate

/SWFuplinkspell/summongolem
	name = "Summon Golem"
	eqtype = "Utility"
	desc = "This spell allows you to turn a reagent you currently hold (in a jar, bottle or other container) into a golem. Golems will attack your enemies, and release their contents as chemical smoke when destroyed."
	cooldown = 50
	assoc_spell = /targetable/spell/golem

/SWFuplinkspell/animatedead
	name = "Animate Dead"
	eqtype = "Utility"
	desc = "This spell infuses an adjacent human corpse with necromantic energy, creating a durable skeleton minion that seeks to pummel your enemies into oblivion."
	cooldown = 85
	assoc_spell = /targetable/spell/animatedead

/SWFuplinkspell/pandemonium
	name = "Pandemonium"
	eqtype = "Miscellaneous"
	desc = "This spell causes random effects to happen. Best used only by skilled wizards."
	cooldown = 40
	assoc_spell = /targetable/spell/pandemonium

/obj/item/SWF_uplink/proc/explode()
	var/turf/location = get_turf(loc)
	location.hotspot_expose(700, 125)

	explosion(src, location, 0, 0, 2, 4)

	qdel(master)
	qdel(src)
	return

/obj/item/SWF_uplink/attack_self(mob/user as mob)
	if (!user.mind || (user.mind && user.mind.key != wizard_key))
		boutput(user, "<span style=\"color:red\"><strong>The spellbook is magically attuned to someone else!</strong></span>")
		return
	user.machine = src
	var/dat
	if (selfdestruct)
		dat = "Self Destructing..."
	else
		if (temp)
			dat = "[temp]<BR><BR><A href='byond://?src=\ref[src];temp=1'>Clear</A>"
		else
			dat = "<strong>The Book of Spells</strong><BR>"
			dat += "Magic Points left: [uses]<BR>"
			dat += "<HR>"
			dat += "<strong>Request item:</strong><BR>"
			for (var/SWFuplinkspell/SP in spells)
				dat += "<A href='byond://?src=\ref[src];buyspell=\ref[SP]'><strong>[SP.name]</strong></A> ([SP.eqtype]) <A href='byond://?src=\ref[src];aboutspell=\ref[SP]'>(?)</A><br>"
			dat += "<HR>"
/*
			if (origradio)
				dat += "<A href='byond://?src=\ref[src];lock=1'>Lock</A><BR>"
				dat += "<HR>"
			dat += "<A href='byond://?src=\ref[src];selfdestruct=1'>Self-Destruct</A>"
*/
	user << browse(dat, "window=radio")
	onclose(user, "radio")
	return

/obj/item/SWF_uplink/Topic(href, href_list)
	..()
	if (usr.stat || usr.restrained())
		return
	var/mob/living/carbon/human/H = usr
	if (!( istype(H, /mob/living/carbon/human)))
		return TRUE
	if ((usr.contents.Find(src) || (in_range(src,usr) && istype(loc, /turf))))
		usr.machine = src

		if (href_list["buyspell"])
			var/SWFuplinkspell/SP = locate(href_list["buyspell"])
			switch(SP.SWFspell_CheckRequirements(usr,src))
				if (1) boutput(usr, "<span style=\"color:red\">You have no more magic points to spend.</span>")
				if (2) boutput(usr, "<span style=\"color:red\">You already have this spell.</span>")
				if (999) boutput(usr, "<span style=\"color:red\">Unknown Error.</span>")
				else
					SP.SWFspell_Purchased(usr,src)

		else if (href_list["aboutspell"])
			var/SWFuplinkspell/SP = locate(href_list["aboutspell"])
			temp = "[SP.desc]"
			if (SP.cooldown)
				temp += "<BR>It takes [SP.cooldown] seconds to recharge after use."

		else if (href_list["lock"] && origradio)
			// presto chango, a regular radio again! (reset the freq too...)
			usr.machine = null
			usr << browse(null, "window=radio")
			var/obj/item/device/radio/T = origradio
			var/obj/item/SWF_uplink/R = src
			R.set_loc(T)
			T.set_loc(usr)
			// R.layer = initial(R.layer)
			R.layer = 0
			usr.u_equip(R)
			usr.put_in_hand_or_drop(T)
			R.set_loc(T)
			T.set_frequency(initial(T.frequency))
			T.attack_self(usr)
			return

		else if (href_list["selfdestruct"])
			temp = "<A href='byond://?src=\ref[src];selfdestruct2=1'>Self-Destruct</A>"

		else if (href_list["selfdestruct2"])
			selfdestruct = 1
			spawn (100)
				explode()
				return
		else
			if (href_list["temp"])
				temp = null

		if (istype(loc, /mob))
			attack_self(loc)
		else
			for (var/mob/M in viewers(1, src))
				if (M.client)
					attack_self(M)

	//if (istype(H.wear_suit, /obj/item/clothing/suit/wizrobe))
	//	H.wear_suit.check_abilities()
	return