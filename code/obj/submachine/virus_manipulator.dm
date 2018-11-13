// disease reagent manipulator thing

/obj/submachine/virus_manipulator
	name = "Virus Manipulator"
	desc = "A device which alters bacteria and virii."
	icon = 'icons/obj/objects.dmi'
	icon_state = "DAn-off"
	flags = NOSPLASH
	anchored = 1
	density = 1
	var/obj/item/reagent_containers/glass/vial/active_vial = null
	var/datavial = "No Vial Inserted"
	var/datareagent = "N/A"
	var/dataspread = "N/A"
	var/datacurable = "N/A"
	var/dataregress = "N/A"
	var/datavaccine = "N/A"
	var/datacure = "N/A"
	var/dataprob = "N/A"
	var/working = 0

	New()
		..()
		overlays += image('icons/obj/objects.dmi', "DAn-Oe")

	attack_ai(mob/user as mob)
		return attack_hand(user)

	attack_hand(var/mob/user as mob)
		user.machine = src
		if (!working)
			var/dat = {"<strong>Virus Manipulator</strong><BR>
			<HR><BR>
			<strong>Vial:</strong> [datavial]<BR>
			<strong>Vial Contents:</strong> [datareagent]<BR>
			<HR><BR>
			<strong>Contagion Vector:</strong> [dataspread]<BR>
			<strong>Strain Vulnerability:</strong> [datacure]<BR>
			<strong>Antibiotic Resistance:</strong> [datacurable]<BR>
			<strong>Immune System Resistance:</strong> [dataregress]<BR>
			<strong>Infection Development Rate:</strong> [dataprob]<BR>
			<strong>Crippled Infectiousness:</strong> [datavaccine]<BR><BR>
			<HR><BR>
			<A href='?src=\ref[src];ops=1'>Attempt to Create Vaccine<BR>
			<A href='?src=\ref[src];ops=2'>Mutate<BR>
			<A href='?src=\ref[src];ops=3'>Refresh Report<BR>
			<A href='?src=\ref[src];ops=4'>Eject Vial"}
			user << browse(dat, "window=virusmanip;size=400x500")
			onclose(user, "virusmanip")
		else
			var/dat = {"<strong>Virus Manipulator</strong><BR>
			<HR><BR>
			<strong>Please wait. Work in progress.</strong><BR>"}
			user << browse(dat, "window=virusmanip;size=450x500")
			onclose(user, "virusmanip")

	Topic(href, href_list)
		if (href_list["ops"])
			var/operation = text2num(href_list["ops"])
			if (operation == 1) // Attempt to Create Vaccine
				if (datareagent == "N/A" || datareagent == "No virii detected")
					for (var/mob/O in hearers(src, null))
						O.show_message(text("<strong>[]</strong> states, 'Unable to begin process. No reagent detected.'", src), 1)
					return
				else if (datareagent == "Multiple virii detected")
					for (var/mob/O in hearers(src, null))
						O.show_message(text("<strong>[]</strong> states, 'Unable to begin process. Excess reagents detected.'", src), 1)
					return
				working = 1
				icon_state = "DAn-on"
				for (var/mob/O in hearers(src, null))
					O.show_message(text("<strong>[]</strong> states, 'Commencing work.'", src), 1)
				if (active_vial.reagents && active_vial.reagents.reagent_list.len)
					for (var/current_id in active_vial.reagents.reagent_list)
						var/reagent/disease/current_disease = active_vial.reagents.reagent_list[current_id]
						if (istype(current_disease))
							if (prob(50))
								current_disease.Rvaccine = rand(0,1)
								if (current_disease.Rvaccine) datavaccine = "Yes"
								else datavaccine = "No"

				spawn (rand(100,150))
					working = 0
					icon_state = "DAn-off"
					var/vacannounce
					if (datavaccine == "Yes") vacannounce = "Vaccine created successfully"
					else vacannounce = "Failed to create vaccine"
					for (var/mob/O in hearers(src, null))
						O.show_message(text("<strong>[]</strong> states, '[].'", src, vacannounce), 1)
					updateUsrDialog()
			if (operation == 2) // Mutate
				if (datareagent == "N/A" || datareagent == "No virii detected")
					for (var/mob/O in hearers(src, null))
						O.show_message(text("<strong>[]</strong> states, 'Unable to begin process. No reagent detected.'", src), 1)
					return
				else if (datareagent == "Multiple virii detected")
					for (var/mob/O in hearers(src, null))
						O.show_message(text("<strong>[]</strong> states, 'Unable to begin process. Excess reagents detected.'", src), 1)
					return
				working = 1
				icon_state = "DAn-on"
				for (var/mob/O in hearers(src, null))
					O.show_message(text("<strong>[]</strong> states, 'Commencing work.'", src), 1)
				if (active_vial.reagents.reagent_list.len)
					for (var/current_id in active_vial.reagents.reagent_list)
						var/reagent/disease/current_disease = active_vial.reagents.reagent_list[current_id]

						if (istype(current_disease))
							if (prob(40))
								current_disease.Rspread = "Non-Contagious"
								if (prob(20)) current_disease.Rspread = "Contact"
								if (prob(10)) current_disease.Rspread = "Airborne"
								dataspread = current_disease.Rspread
							if (prob(40))
								current_disease.Rcure = pick("Sleep", "Antibiotics", "Self-Curing")
								if (prob(10)) current_disease.Rcure = pick("Beatings", "Burnings", "Electric Shock")
								if (rand(1,5000) == 1) current_disease.Rcure = "Incurable"
								datacure = current_disease.Rcure
							if (prob(50))
								current_disease.Rcurable = rand(0,1)
								if (current_disease.Rcurable) datacurable = "No"
								else datacurable = "Yes"
							if (prob(50))
								current_disease.Rregress = rand(0,1)
								if (current_disease.Rregress) dataregress = "No"
								else dataregress = "Yes"
							if (prob(50))
								current_disease.Rprob = rand(-3,3)
								dataprob = current_disease.Rprob
				spawn (rand(100,150))
					working = 0
					icon_state = "DAn-off"
					for (var/mob/O in hearers(src, null))
						O.show_message(text("<strong>[]</strong> states, 'Work complete.'", src), 1)
					updateUsrDialog()
			if (operation == 3) // Refresh Report
				if (active_vial) datavial = active_vial.name
				else
					datavial = "No Vial Inserted"
					datareagent = "N/A"
					dataspread = "N/A"
					datacure = "N/A"
					datacurable = "N/A"
					dataregress = "N/A"
					datavaccine = "N/A"
					dataprob = "N/A"
					updateUsrDialog()
					return
				var/reagcount = 0
				if (active_vial.reagents.reagent_list.len)
					for (var/current_id in active_vial.reagents.reagent_list)
						var/reagent/disease/current_disease = active_vial.reagents.reagent_list[current_id]

						if (istype(current_disease))
							reagcount++

							datareagent = current_disease.name
							dataspread = current_disease.Rspread
							datacure = current_disease.Rcure
							if (current_disease.Rcurable) datacurable = "No"
							else datacurable = "Yes"
							if (current_disease.Rregress) dataregress = "No"
							else dataregress = "Yes"
							if (current_disease.Rvaccine) datavaccine = "Yes"
							else datavaccine = "No"

					if (reagcount > 1)
						datareagent = "Multiple virii detected"
						dataspread = "N/A"
						datacure = "N/A"
						dataprob = "N/A"
						datacurable = "N/A"
						dataregress = "N/A"
						datavaccine = "N/A"
				else
					datareagent = "No virii detected"
					dataspread = "N/A"
					datacure = "N/A"
					dataprob = "N/A"
					datacurable = "N/A"
					dataregress = "N/A"
					datavaccine = "N/A"
				updateUsrDialog()
			if (operation == 4) // Eject Vial
				var/log_reagents = ""
				if (active_vial && active_vial.reagents)
					for (var/reagent_id in active_vial.reagents.reagent_list)
						log_reagents += " [reagent_id]"

				logTheThing("combat", usr, null, "modified <em>(<strong>[log_reagents]</strong>)</em> to [dataspread], cure = [datacure], curable = [datacurable], regress = [dataregress], speed =[dataprob], vaccine = [datavaccine]")
				for (var/obj/item/reagent_containers/glass/vial/V in contents)
					V.set_loc(get_turf(src))
				active_vial = null
				datavial = "No Vial Inserted"
				datareagent = "N/A"
				dataspread = "N/A"
				datacure = "N/A"
				dataprob = "N/A"
				datacurable = "N/A"
				dataregress = "N/A"
				datavaccine = "N/A"
				overlays -= image('icons/obj/objects.dmi', "DAn-Of")
				overlays += image('icons/obj/objects.dmi', "DAn-Oe")
				updateUsrDialog()
			updateUsrDialog()

	attackby(var/obj/item/W as obj, var/mob/user as mob)
		if (working)
			boutput(user, "<span style=\"color:red\">The manipulator is busy!</span>")
			return
		if (istype(W, /obj/item/reagent_containers/glass/vial))
			if (active_vial)
				boutput(user, "<span style=\"color:red\">A vial is already loaded into the manipulator.</span>")
				return
			boutput(user, "<span style=\"color:blue\">You add the [W] to the manipulator!</span>")
			datavial = W.name
			active_vial = W
			user.drop_item()
			W.set_loc(src)
			overlays -= image('icons/obj/objects.dmi', "DAn-Oe")
			overlays += image('icons/obj/objects.dmi', "DAn-Of")
			updateUsrDialog()
			var/reagcount = 0
			if (active_vial.reagents.reagent_list.len)
				for (var/current_id in active_vial.reagents.reagent_list)
					var/reagent/disease/current_disease = active_vial.reagents.reagent_list[current_id]

					if (istype(current_disease))
						reagcount++

						datareagent = current_disease.name
						dataspread = current_disease.Rspread
						datacure = current_disease.Rcure
						dataprob = current_disease.Rprob
						if (current_disease.Rcurable) datacurable = "No"
						else datacurable = "Yes"
						if (current_disease.Rregress) dataregress = "No"
						else dataregress = "Yes"
						if (current_disease.Rvaccine) datavaccine = "Yes"
						else datavaccine = "No"
				if (reagcount > 1)
					datareagent = "Multiple virii detected"
					dataspread = "N/A"
					datacurable = "N/A"
					dataregress = "N/A"
					datavaccine = "N/A"
			else
				datareagent = "No virii detected"
				dataspread = "N/A"
				datacure = "N/A"
				dataprob = "N/A"
				datacurable = "N/A"
				dataregress = "N/A"
				datavaccine = "N/A"
		else
			boutput(user, "<span style=\"color:red\">The manipulator cannot accept that!</span>")
			return