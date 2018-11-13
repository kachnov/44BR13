/obj/item/parts
	name = "body part"
	icon = 'icons/obj/robot_parts.dmi'
	inhand_image_icon = 'icons/mob/inhand/hand_tools.dmi'
	item_state = "buildpipe"
	flags = FPRINT | ONBELT | TABLEPASS
	override_attack_hand = 0
	var/slot = null // which part of the person or robot suit does it go on???????
	var/streak_decal = /obj/decal/cleanable/blood // what streaks everywhere when it's cut off?
	var/streak_descriptor = "bloody" //bloody, oily, etc
	var/limb/limb_data = null // used by arms for attack_hand overrides
	var/limb_type = /limb // the type of limb_data
	var/obj/item/remove_object = null //set to create an item when severed rather than removing the arm itself
	var/side = "left" //used for streak direction
	var/remove_stage = 0 //2 will fall off, 3 is removed
	var/no_icon = 0 //if the only icon is above the clothes layer ie. in the handlistPart list
	var/skintoned = 1 // is this affected by human skin tones?

	var/decomp_affected = 1 // set to 1 if this limb has decomposition icons
	var/current_decomp_stage_l = -1
	var/current_decomp_stage_s = -1

	var/mob/living/holder = null

	var/image/standImage
	var/image/lyingImage
	var/partIcon = 'icons/mob/human.dmi'
	var/partDecompIcon = 'icons/mob/human_decomp.dmi'
	var/handlistPart
	var/partlistPart
	var/bone/bones = null // for medical crap
	var/brute_dam = 0
	var/burn_dam = 0
	var/tox_dam = 0

	New()
		limb_data = new limb_type(src)

	proc/remove(var/show_message = 1)
		var/obj/item/object = src
		if (remove_object)
			object = remove_object
			object.set_loc(loc)
			object.cant_drop = initial(object.cant_drop)
		else
			remove_stage = 3
		object.loc = holder.loc
		if (hasvar(object,"skin_tone"))
			object:skin_tone = holder.bioHolder.mobAppearance.s_tone

		object.name = "[holder.real_name]'s [initial(object.name)]"

		if (show_message) holder.visible_message("<span style=\"color:red\">[object.name] falls off!</span>")

		if (ishuman(holder))
			var/mob/living/carbon/human/H = holder
			H.limbs.vars[slot] = null
			if (remove_object)
				remove_object = null
				qdel(src)
			H.set_body_icon_dirty()
		else if (remove_object)
			remove_object = null
			qdel(src)

		return

	proc/sever(var/mob/user)
		if (!holder) // fix for Cannot read null.loc, hopefully - haine
			if (remove_object)
				remove_object = null
				holder = null
				qdel(src)
			return

		if (user)
			logTheThing("admin", user, holder, "severed %target%'s limb, [src] (<em>type: [type], side: [side]</em>)")

		var/obj/item/object = src
		if (remove_object)
			object = remove_object
			object.set_loc(loc)
			object.layer = initial(object.layer)
		else
			remove_stage = 3

		object.loc = holder.loc
		var/direction = holder.dir
		if (hasvar(object,"skin_tone"))
			object:skin_tone = holder.bioHolder.mobAppearance.s_tone

		object.name = "[holder.real_name]'s [initial(object.name)]" //Luis Smith's Dr. Kay's Luis Smith's Sailor Dave's Left Arm

		holder.visible_message("<span style=\"color:red\">[object.name] flies off in a [streak_descriptor] arc!</span>")

		switch(direction)
			if (NORTH)
				direction = WEST
			if (EAST)
				direction = NORTH
			if (SOUTH)
				direction = EAST
			if (WEST)
				direction = SOUTH

		if (side != "left")
			direction = turn(direction,180)

		if (istype(object, /obj/item))
			object.streak(direction, streak_decal)

		if (prob(60)) holder.emote("scream")

		if (ishuman(holder))
			var/mob/living/carbon/human/H = holder
			holder = null
			H.limbs.vars[slot] = null
			if (remove_object)
				remove_object = null
				qdel(src)
			H.set_body_icon_dirty()

		else if (remove_object)
			remove_object = null
			holder = null
			qdel(src)

		return

	//for humans
	attach(var/mob/living/carbon/human/attachee,var/mob/attacher,var/both_legs = 0)
		if (!both_legs) attachee.limbs.vars[slot] = src
		else
			attachee.limbs.l_leg = src
			attachee.limbs.r_leg = src
		holder = attachee
		attacher.remove_item(src)
		layer = initial(layer)
		screen_loc = ""
		set_loc(attachee)
		remove_stage = 2

		for (var/mob/O in AIviewers(attachee, null))
			if (O == (attacher || attachee))
				continue
			if (attacher == attachee)
				O.show_message("<span style=\"color:red\">[attacher] attaches [src] to \his own stump[both_legs? "s" : ""]!</span>", 1)
			else
				O.show_message("<span style=\"color:red\">[attachee] has [src] attached to \his stump[both_legs? "s" : ""] by [attacher].</span>", 1)

		if (attachee != attacher)
			boutput(attachee, "<span style=\"color:red\">[attacher] attaches [src] to your stump[both_legs? "s" : ""]. It doesn't look very secure!</span>")
			boutput(attacher, "<span style=\"color:red\">You attach [src] to [attachee]'s stump[both_legs? "s" : ""]. It doesn't look very secure!</span>")
		else
			boutput(attacher, "<span style=\"color:red\">You attach [src] to your own stump[both_legs? "s" : ""]. It doesn't look very secure!</span>")

		attachee.set_body_icon_dirty()
		spawn (rand(150,200))
			if (remove_stage == 2) remove()

		return

	proc/surgery(var/obj/item/I) //placeholder
		return

	proc/getMobIcon(var/lying, var/decomp_stage = 0)
		if (no_icon) return FALSE
		var/decomp = ""
		if (decomp_affected && decomp_stage)
			decomp = "_decomp[decomp_stage]"
		var/used_icon = getAttachmentIcon(decomp_stage)

		if (lying)
			if (lyingImage && ((decomp_affected && current_decomp_stage_l == decomp_stage) || !decomp_affected))
				return lyingImage
			//boutput(world, "Attaching lying limb [slot][decomp]_l on decomp stage [decomp_stage].")
			current_decomp_stage_l = decomp_stage
			lyingImage = image(used_icon, "[slot][decomp]_l")
			return lyingImage

		else
			if (standImage && ((decomp_affected && current_decomp_stage_s == decomp_stage) || !decomp_affected))
				return standImage
			//boutput(world, "Attaching standing limb [slot][decomp]_s on decomp stage [decomp_stage].")
			current_decomp_stage_s = decomp_stage
			standImage = image(used_icon, "[slot][decomp]")
			return standImage

	proc/getAttachmentIcon(var/decomp_stage = 0)
		if (decomp_affected && decomp_stage)
			return partDecompIcon
		return partIcon

	proc/getHandIconState(var/lying, var/decomp_stage = 0)
		var/decomp = ""
		if (decomp_affected && decomp_stage)
			decomp = "_decomp[decomp_stage]"

		//boutput(world, "Attaching standing hand [slot][decomp]_s on decomp stage [decomp_stage].")
		return "[handlistPart][decomp]"

	proc/getPartIconState(var/lying, var/decomp_stage = 0)
		var/decomp = ""
		if (decomp_affected && decomp_stage)
			decomp = "_decomp[decomp_stage]"

		//boutput(world, "Attaching standing part [slot][decomp]_s on decomp stage [decomp_stage].")
		return "[partlistPart][decomp]"

/obj/item/proc/streak(var/direction, var/streak_splatter) //stolen from gibs
	spawn (0)
		if (istype(direction, /list))
			direction = pick(direction)
		for (var/i = 0, i < rand(1,3), i++)
			sleep(3)
			if (i > 0 && ispath(streak_splatter))
				new streak_splatter(loc)
			if (!step_to(src, get_step(src, direction), 0))
				break