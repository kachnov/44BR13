/mob/var/suiciding = 0
var/suicide_list = new/list()

/obj/proc/suicide(var/mob/user)
	return

/mob/living/carbon/human/proc/force_suicide()
	logTheThing("combat", src, null, "commits suicide")

	if (!stat)
		suicide_list += ckey
	if (client) // fix for "Cannot modify null.suicide"
		client.suicide = 1
	suiciding = 1
	unlock_medal("Damned", 1)

	//i'll just chuck this one in here i guess
	if (on_chair)
		visible_message("<span style=\"color:red\"><strong>[src] jumps off of the chair straight onto \his head!</strong></span>")
		TakeDamage("head", 200, 0)
		updatehealth()
		spawn (100)
			if (src)
				src.suiciding = 0

		pixel_y = 0
		anchored = 0
		on_chair = 0
		buckled = null
		return

	if (src.wear_mask && !istype(src.wear_mask,/obj/item/clothing/mask/cursedclown_hat)) //can't stare into the cluwne mask's eyes while wearing it...
		if (wear_mask.suicide(src))
			return

	if (w_uniform)
		if (w_uniform.suicide(src))
			return

	if (!restrained() && !paralysis && !stunned)
		if (l_hand)
			if (l_hand.suicide(src))
				return

		if (r_hand)
			if (r_hand.suicide(src))
				return

		for (var/obj/O in orange(1,src))
			if (O.suicide(src))
				return
/*
	for (var/obj/pool_springboard/O in orange(1,src))
		if (O.suicide(src))
			return

	for (var/obj/machinery/O in orange(1,src))
		if (O.suicide(src))
			return

	for (var/obj/critter/O in orange(1,src))
		if (O.suicide(src))
			return

	for (var/obj/table/O in orange(1,src))
		if (O.suicide(src))
			return

	for (var/obj/reagent_dispensers/O in orange(1,src))
		if (O.suicide(src))
			return
*/
	//instead of killing them instantly, just put them at -175 health and let 'em gasp for a while
	visible_message("<span style=\"color:red\"><strong>[src] is holding \his breath. It looks like \he's trying to commit suicide.</strong></span>")
	take_oxygen_deprivation(175)
	updatehealth()
	spawn (200) //in case they get revived by cryo chamber or something stupid like that, let them suicide again in 20 seconds
		src.suiciding = 0
	return

/mob/living/carbon/human/verb/suicide()
	set hidden = 1

	if (stat == 2)
		boutput(src, "You're already dead!")
		return

	if (!ticker)
		boutput(src, "You can't commit suicide before the game starts!")
		return
/*
//prevent a suicide if the person is infected with the headspider disease.
	for (var/ailment/V in ailments)
		if (istype(V, /ailment/parasite/headspider) || istype(V, /ailment/parasite/alien_embryo))
			boutput(src, "You can't muster the willpower. Something is preventing you from doing it.")
			return
*/

	if (suiciding)
		boutput(src, "You're already committing suicide! Be patient!")
		return

	if (!suicide_allowed)
		boutput(src, "You find yourself unable to go through with killing yourself!")
		return

	var/confirm = alert("Are you sure you want to commit suicide?", "Confirm Suicide", "Yes", "No")

	if (confirm == "Yes")
		suiciding = 1
		unkillable = 0 //Get owned, nerd!
		force_suicide()
		return
	else
		// if they cancelled the prompt
		suiciding = 0
		return

/* will fix this later
		else if (method == "extinguisher")
			viewers(src) << "<span style=\"color:red\"><strong>[src] puts the nozzle of the extinguisher into \his mouth and squeezes the handle.</strong></span>"
			var/succeeds = 0
			for (var/obj/item/extinguisher/E in l_hand)
				if (E.safety == 0 && E.reagents && E.reagents.total_volume >= 5)
					succeeds = 1
					E.reagents.remove_any(5)
			if (!succeeds)
				for (var/obj/item/extinguisher/E in r_hand)
					if (E.safety == 0 && E.reagents && E.reagents.total_volume >= 5)
						succeeds = 1
						E.reagents.remove_any(5)
			if (succeeds) gib()
			else
				viewers(src) << "<span style=\"color:red\"><strong>Nothing happens!</strong></span>"
				spawn (50)
					suiciding = 0*/

/mob/living/silicon/ai/verb/suicide()
	set hidden = 1

	if (stat == 2)
		boutput(src, "You're already dead!")
		return

	if (suiciding)
		boutput(src, "You're already committing suicide! Be patient!")
		return

	if (!suicide_allowed)
		boutput(src, "You find yourself unable to go through with killing yourself!")
		return

	suiciding = 1
	var/confirm = alert("Are you sure you want to commit suicide?", "Confirm Suicide", "Yes", "No")

	if (confirm == "Yes")
		client.suicide = 1
		usr.visible_message("<span style=\"color:red\"><strong>[src] is powering down. It looks like \he's trying to commit suicide.</strong></span>")
		unlock_medal("Damned", 1)
		//put em at -175
		//death_timer = 15 // this shit ain't really workin so bandaid fix for now
		//updatehealth()
		spawn (30)
			death()
		spawn (200)
			suiciding = 0
		return
	suiciding = 0

/mob/living/silicon/robot/verb/suicide()
	set hidden = 1

	if (stat == 2)
		boutput(src, "You're already dead!")
		return

	if (suiciding)
		boutput(src, "You're already committing suicide! Be patient!")
		return

	if (!suicide_allowed)
		boutput(src, "You find yourself unable to go through with killing yourself!")
		return


	suiciding = 1
	var/confirm = alert("Are you sure you want to commit suicide?", "Confirm Suicide", "Yes", "No")

	if (confirm == "Yes")
		client.suicide = 1
		var/mob/living/silicon/robot/R = src
		R.unlock_medal("Damned", 1)
		usr.visible_message("<span style=\"color:red\"><strong>[src] disconnects all its joint moorings!</strong></span>")
		R.part_chest.set_loc(loc)
		R.part_chest = null
		spawn (200)
			R.suiciding = 0
		return
	suiciding = 0
