/obj/item/parts/robot_parts
	name = "robot parts"
	icon = 'icons/obj/robot_parts.dmi'
	inhand_image_icon = 'icons/mob/inhand/hand_tools.dmi'
	item_state = "buildpipe"
	flags = FPRINT | ONBELT | TABLEPASS | CONDUCT
	streak_decal = /obj/decal/cleanable/oil
	streak_descriptor = "oily"
	var/appearanceString = "generic"
	var/icon_state_base = ""
	module_research = list("medicine" = 1, "efficiency" = 8)
	module_research_type = /obj/item/parts/robot_parts

	decomp_affected = 0

	var/max_health = 100
	var/dmg_blunt = 0
	var/dmg_burns = 0
	var/speedbonus = 0 // does it help the robot move more quickly?
	var/weight = 0     // for calculating speed modifiers
	var/powerdrain = 0 // does this part consume any extra power

	stamina_damage = 35
	stamina_cost = 20
	stamina_crit_chance = 5

	examine()
		set src in oview()
		..()
		switch(ropart_get_damage_percentage(1))
			if (15 to 29) boutput(usr, "<span style=\"color:red\">It looks a bit dented and worse for wear.</span>")
			if (29 to 59) boutput(usr, "<span style=\"color:red\">It looks somewhat bashed up.</span>")
			if (60 to INFINITY) boutput(usr, "<span style=\"color:red\">It looks badly mangled.</span>")

		switch(ropart_get_damage_percentage(2))
			if (15 to 29) boutput(usr, "<span style=\"color:red\">It has some light scorch marks.</span>")
			if (29 to 59) boutput(usr, "<span style=\"color:red\">Parts of it are kind of melted.</span>")
			if (60 to INFINITY) boutput(usr, "<span style=\"color:red\">It looks terribly burnt up.</span>")

	getMobIcon(var/lying)
		if (standImage)
			return standImage

		standImage = image('icons/mob/human.dmi', "[icon_state_base]-[appearanceString]")
		return standImage

	attackby(obj/item/W as obj, mob/user as mob)
		if (istype(W, /obj/item/weldingtool))
			var/obj/item/weldingtool/WELD = W
			if (WELD.welding)
				if (WELD.get_fuel() < 2)
					boutput(user, "<span style=\"color:red\">You need more welding fuel!</span>")
					return
			if (ropart_get_damage_percentage(1) > 0)
				ropart_mend_damage(20,0)
				WELD.use_fuel(1)
				add_fingerprint(user)
				user.visible_message("<strong>[user.name]</strong> repairs some of the damage to [src.name].")
			else
				boutput(user, "<span style=\"color:red\">It has no structural damage to weld out.</span>")
				return
		else if (istype(W, /obj/item/cable_coil))
			var/obj/item/cable_coil/coil = W
			if (ropart_get_damage_percentage(1) > 0)
				ropart_mend_damage(0,20)
				coil.use(1)
				add_fingerprint(user)
				user.visible_message("<strong>[user.name]</strong> repairs some of the damage to [name]'s wiring.")
			else
				boutput(user, "<span style=\"color:red\">There's no burn damage on [name]'s wiring to mend.</span>")
				return
		else ..()

	surgery(var/obj/item/tool)

		var/wrong_tool = 0

		if (remove_stage > 1 && tool.type == /obj/item/staple_gun)
			remove_stage = 0

		else if (remove_stage == 0 || remove_stage == 2)
			if (istype(tool, /obj/item/scalpel) || istype(tool, /obj/item/raw_material/shard) || istype(tool, /obj/item/kitchen/utensil/knife))
				remove_stage++
			else
				wrong_tool = 1

		else if (remove_stage == 1)
			if (istype(tool, /obj/item/circular_saw) || istype(tool, /obj/item/saw))
				remove_stage++
			else
				wrong_tool = 1

		if (!wrong_tool)
			switch(remove_stage)
				if (0)
					tool.the_mob.visible_message("<span style=\"color:red\">[tool.the_mob] staples [holder.name]'s [name] securely to their stump with [tool].</span>", "<span style=\"color:red\">You staple [holder.name]'s [name] securely to their stump with [tool].</span>")
				if (1)
					tool.the_mob.visible_message("<span style=\"color:red\">[tool.the_mob] slices through the attachment mesh of [holder.name]'s [name] with [tool].</span>", "<span style=\"color:red\">You slice through the attachment mesh of [holder.name]'s [name] with [tool].</span>")
				if (2)
					tool.the_mob.visible_message("<span style=\"color:red\">[tool.the_mob] saws through the base mount of [holder.name]'s [name] with [tool].</span>", "<span style=\"color:red\">You saw through the base mount of [holder.name]'s [name] with [tool].</span>")

					spawn (rand(150,200))
						if (remove_stage == 2)
							remove(0)
				if (3)
					tool.the_mob.visible_message("<span style=\"color:red\">[tool.the_mob] cuts through the remaining strips of material holding [holder.name]'s [name] on with [tool].</span>", "<span style=\"color:red\">You cut through the remaining strips of material holding [holder.name]'s [name] on with [tool].</span>")

					remove(0)

			if (holder.stat != 2)
				if (prob(40))
					holder.emote("scream")
			holder.TakeDamage("chest",20,0)
			take_bleeding_damage(holder, null, 15, DAMAGE_CUT)

	proc/ropart_take_damage(var/bluntdmg = 0,var/burnsdmg = 0)
		dmg_blunt += bluntdmg
		dmg_burns += burnsdmg
		if (dmg_blunt + dmg_burns > max_health)
			if (holder) return TRUE // need to do special stuff in this case, so we let the borg's melee hit take care of it
			else
				visible_message("<strong>[src]</strong> breaks!")
				playsound(get_turf(src), "sound/effects/grillehit.ogg", 40, 1)
				if (istype(loc,/turf)) new /obj/decal/cleanable/robot_debris/limb(loc)
				del(src)
				return FALSE
		return FALSE

	proc/ropart_mend_damage(var/bluntdmg = 0,var/burnsdmg = 0)
		dmg_blunt -= bluntdmg
		dmg_burns -= burnsdmg
		if (dmg_blunt < 0) dmg_blunt = 0
		if (dmg_burns < 0) dmg_burns = 0
		return FALSE

	proc/ropart_get_damage_percentage(var/which = 0)
		switch(which)
			if (1)
				if (dmg_blunt) return (dmg_blunt / max_health) * 100
				else return FALSE // wouldn't want to divide by zero, even if my maths suck
			if (2)
				if (dmg_burns) return (dmg_burns / max_health) * 100
				else return FALSE
			else
				if (dmg_blunt || dmg_burns) return ((dmg_blunt + dmg_burns) / max_health) * 100
				else return FALSE

/obj/item/parts/robot_parts/head
	name = "Standard Cyborg Head"
	desc = "A serviceable head unit for a potential cyborg."
	icon = 'icons/mob/robots.dmi'
	icon_state = "head-generic"
	slot = "head"
	max_health = 175
	var/obj/item/organ/brain/brain = null
	var/obj/item/ai_interface/ai_interface = null
	var/visible_eyes = 1
	var/wires_exposed = 0
	New()
		..()
		pixel_y -= 8
		icon_state = "head-" + appearanceString

	examine()
		set src in oview()
		..()
		if (brain)
			boutput(usr, "<span style=\"color:blue\">This head unit has [brain] inside. Use a wrench if you want to remove it.</span>")
		else if (ai_interface)
			boutput(usr, "<span style=\"color:blue\">This head unit has [ai_interface] inside. Use a wrench if you want to remove it.</span>")
		else
			boutput(usr, "<span style=\"color:red\">This head unit is empty.</span>")

	attackby(obj/item/W as obj, mob/user as mob)
		if (istype(W,/obj/item/organ/brain))
			if (brain)
				boutput(user, "<span style=\"color:red\">There is already a brain in there. Use a wrench to remove it.</span>")
				return

			if (ai_interface)
				boutput(user, "<span style=\"color:red\">There is already \an [ai_interface] in there. Use a wrench to remove it.</span>")
				return

			if (wires_exposed)
				user.show_text("You can't add the brain to this head when the wires are exposed. Use a screwdriver to pack them away.", "red")
				return

			var/obj/item/organ/brain/B = W
			if (!(B.owner && B.owner.key))
				boutput(user, "<span style=\"color:red\">This brain doesn't look any good to use.</span>")
				return
			else if (jobban_isbanned(B.owner.current,"Cyborg") || B.owner.dnr) //If the borg-to-be is jobbanned or has DNR set
				boutput(user, "<span style=\"color:red\">The brain disintigrates in your hands!</span>")
				user.drop_item()
				qdel(B)
				var/effects/system/harmless_smoke_spread/smoke = new /effects/system/harmless_smoke_spread()
				smoke.set_up(1, 0, user.loc)
				smoke.start()
				return
			user.drop_item()
			B.set_loc(src)
			brain = B
			boutput(user, "<span style=\"color:blue\">You insert the brain.</span>")
			playsound(get_turf(src), "sound/weapons/Genhit.ogg", 40, 1)
			return

		else if (istype(W, /obj/item/ai_interface))
			if (brain)
				boutput(user, "<span style=\"color:red\">There is already a brain in there. Use a wrench to remove it.</span>")
				return

			if (ai_interface)
				boutput(user, "<span style=\"color:red\">There is already \an [ai_interface] in there!</span>")
				return

			if (wires_exposed)
				user.show_text("You can't add [W] to this head when the wires are exposed. Use a screwdriver to pack them away.", "red")
				return

			var/obj/item/ai_interface/I = W
			user.drop_item()
			I.set_loc(src)
			ai_interface = I
			boutput(user, "<span style=\"color:blue\">You insert [I].</span>")
			playsound(get_turf(src), "sound/weapons/Genhit.ogg", 40, 1)
			return

		else if (istype(W,/obj/item/wrench))
			if (!brain && !ai_interface)
				boutput(user, "<span style=\"color:red\">There's no brain or AI interface chip in there to remove.</span>")
				return
			playsound(get_turf(src), "sound/items/Ratchet.ogg", 40, 1)
			if (ai_interface)
				boutput(user, "<span style=\"color:blue\">You open the head's compartment and take out [ai_interface].</span>")
				user.put_in_hand_or_drop(ai_interface)
				ai_interface = null
			else if (brain)
				boutput(user, "<span style=\"color:blue\">You open the head's compartment and take out [brain].</span>")
				user.put_in_hand_or_drop(brain)
				brain = null
		else if (istype(W, /obj/item/screwdriver))
			if (brain)
				user.show_text("You can't reach the wiring with a brain inside the cyborg head.", "red")
				return
			if (ai_interface)
				user.show_text("You can't reach the wiring with [ai_interface] inside the cyborg head.", "red")
				return

			if (appearanceString != "generic") //Fuck my shit
				user.show_text("The screws on this head have some kinda proprietary bitting. Huh.", "red")
				return

			wires_exposed = !wires_exposed
			if (wires_exposed)
				icon_state = "head-generic-wiresexposed"
				user.show_text("You expose the wiring of the head's neural interface.", "red")
			else
				icon_state = "head-generic"
				user.show_text("You neatly tuck the wiring of the head's neural interface away.", "red")

		else if (istype(W,/obj/item/sheet) && (type == /obj/item/parts/robot_parts/head))
			// second check up there is just watching out for those ..() calls
			var/obj/item/sheet/M = W
			if (M.amount >= 2)
				boutput(user, "<span style=\"color:blue\">You reinforce [name] with the metal.</span>")
				var/obj/item/parts/robot_parts/head/sturdy/newhead = new /obj/item/parts/robot_parts/head/sturdy(get_turf(src))
				M.amount -= 2
				if (M.amount < 1)
					user.drop_item()
					qdel(M)
				if (brain)
					newhead.brain = brain
					brain.set_loc(newhead)
				else if (ai_interface)
					newhead.ai_interface = ai_interface
					ai_interface.set_loc(newhead)
				qdel(src)
				return
			else
				boutput(user, "<span style=\"color:red\">You need at least two metal sheets to reinforce this component.</span>")
				return

		else
			..()

/obj/item/parts/robot_parts/head/sturdy
	name = "Sturdy Cyborg Head"
	desc = "A reinforced head unit capable of taking more abuse than usual."
	appearanceString = "sturdy"
	max_health = 225
	weight = 0.5

	attackby(obj/item/W as obj, mob/user as mob)
		if (istype(W,/obj/item/sheet) && (type == /obj/item/parts/robot_parts/head/sturdy))
			var/obj/item/sheet/M = W
			if (!M.reinforcement)
				boutput(user, "<span style=\"color:red\">You'll need reinforced sheets to reinforce the head.</span>")
				return
			if (M.amount >= 2)
				boutput(user, "<span style=\"color:blue\">You reinforce [name] with the reinforced metal.</span>")
				var/obj/item/parts/robot_parts/head/heavy/newhead = new /obj/item/parts/robot_parts/head/heavy(get_turf(src))
				M.amount -= 2
				if (M.amount < 1)
					user.drop_item()
					qdel(M)
				if (brain)
					newhead.brain = brain
					brain.set_loc(newhead)
				else if (ai_interface)
					newhead.ai_interface = ai_interface
					ai_interface.set_loc(newhead)
				qdel(src)
				return
			else
				boutput(user, "<span style=\"color:red\">You need at least two reinforced metal sheets to reinforce this component.</span>")
				return
		else
			..()

/obj/item/parts/robot_parts/head/heavy
	name = "Heavy Cyborg Head"
	desc = "A heavily reinforced head unit intended for use on cyborgs that perform tough and dangerous work."
	appearanceString = "heavy"
	max_health = 350
	weight = 1

/obj/item/parts/robot_parts/head/light
	name = "Light Cyborg Head"
	desc = "A cyborg head with little reinforcement, to be built in times of scarce resources."
	appearanceString = "light"
	max_health = 50
	speedbonus = 0.2

/obj/item/parts/robot_parts/head/antique
	name = "Antique Cyborg Head"
	desc = "Looks like a discarded prop from some sorta low-budget scifi movie."
	appearanceString = "android"
	max_health = 150
	speedbonus = 0.2
	visible_eyes = 0

/obj/item/parts/robot_parts/chest
	name = "Standard Cyborg Chest"
	desc = "The centerpiece of any cyborg. It wouldn't get very far without it."
	icon_state = "chest"
	slot = "chest"
	max_health = 250
	var/wires = 0
	var/obj/item/cell/cell = null

	examine()
		set src in oview()
		..()
		if (cell) boutput(usr, "<span style=\"color:blue\">This chest unit has a [cell] installed. Use a wrench if you want to remove it.</span>")
		else boutput(usr, "<span style=\"color:red\">This chest unit has no power cell.</span>")
		if (wires) boutput(usr, "<span style=\"color:blue\">This chest unit has had wiring installed.</span>")
		else boutput(usr, "<span style=\"color:red\">This chest unit has not yet been wired up.</span>")

	attackby(obj/item/W as obj, mob/user as mob)
		if (istype(W, /obj/item/cell))
			if (cell)
				boutput(user, "<span style=\"color:red\">You have already inserted a cell!</span>")
				return
			else
				user.drop_item()
				W.set_loc(src)
				cell = W
				boutput(user, "<span style=\"color:blue\">You insert [W].</span>")
				playsound(get_turf(src), "sound/weapons/Genhit.ogg", 40, 1)

		else if (istype(W, /obj/item/cable_coil))
			if (src.ropart_get_damage_percentage(2) > 0) ..()
			else
				if (wires)
					boutput(user, "<span style=\"color:red\">You have already inserted some wire!</span>")
					return
				else
					var/obj/item/cable_coil/coil = W
					coil.use(1)
					wires = 1
					boutput(user, "<span style=\"color:blue\">You insert some wire.</span>")
					playsound(get_turf(src), "sound/weapons/Genhit.ogg", 40, 1)

		else if (istype(W,/obj/item/wrench))
			if (!cell)
				boutput(user, "<span style=\"color:red\">There's no cell in there to remove.</span>")
				return
			playsound(get_turf(src), "sound/items/Ratchet.ogg", 40, 1)
			boutput(user, "<span style=\"color:blue\">You remove the cell from it's slot in the chest unit.</span>")
			cell.set_loc( get_turf(src) )
			cell = null

		else if (istype(W,/obj/item/wirecutters))
			if (wires < 1)
				boutput(user, "<span style=\"color:red\">There's no wiring in there to remove.</span>")
				return
			playsound(get_turf(src), "sound/items/Wirecutter.ogg", 40, 1)
			boutput(user, "<span style=\"color:blue\">You cut out the wires and remove them from the chest unit.</span>")
			// i don't know why this would get abused
			// but it probably will
			// when that happens
			// tell past me i'm saying hello
			var/obj/item/cable_coil/cut/C = new /obj/item/cable_coil/cut(loc)
			C.amount = wires
			wires = 0
		else ..()

/obj/item/parts/robot_parts/chest/light
	name = "Light Cyborg Chest"
	desc = "A bare-bones cyborg chest designed for the least consumption of resources."
	appearanceString = "light"
	max_health = 75

/obj/item/parts/robot_parts/arm
	name = "placeholder item (don't use this!)"
	desc = "A metal arm for a cyborg. It won't be able to use as many tools without it!"
	max_health = 60
	can_hold_items = 1

	attack(mob/living/carbon/M as mob, mob/living/carbon/user as mob)
		if (!istype(M, /mob))
			return

		add_fingerprint(user)

		if (!(user.zone_sel.selecting in list("l_arm","r_arm")) || !istype(M, /mob/living/carbon/human))
			return ..()

		if (!((locate(/obj/machinery/optable) in M.loc) && M.lying) && !((locate(/obj/table) in M.loc) && (M.paralysis || M.stat)))
			return ..()

		var/mob/living/carbon/human/H = M

		if (H.limbs.vars.Find(slot) && H.limbs.vars[slot])
			boutput(user, "<span style=\"color:red\">[H.name] already has one of those!</span>")
			return

		if (appearanceString == "sturdy" || appearanceString == "heavy")
			boutput(user, "<span style=\"color:red\">That arm is too big to fit on [H]'s body!</span>")
			return

		attach(H,user)

		return

/obj/item/parts/robot_parts/arm/left
	name = "Standard Cyborg Left Arm"
	icon_state = "l_arm"
	slot = "l_arm"
	icon_state_base = "armL"
	handlistPart = "armL-generic"

	attackby(obj/item/W as obj, mob/user as mob)
		if (istype(W,/obj/item/sheet) && ((type == /obj/item/parts/robot_parts/arm/left)))
			// second check up there is just watching out for those ..() calls
			var/obj/item/sheet/M = W
			if (M.amount >= 2)
				boutput(user, "<span style=\"color:blue\">You reinforce [name] with the metal.</span>")
				new /obj/item/parts/robot_parts/arm/left/sturdy(get_turf(src))
				M.amount -= 2
				if (M.amount < 1)
					user.drop_item()
					del(M)
				del(src)
				return
			else
				boutput(user, "<span style=\"color:red\">You need at least two metal sheets to reinforce this component.</span>")
				return
		else ..()

/obj/item/parts/robot_parts/arm/left/sturdy
	name = "Sturdy Cyborg Left Arm"
	appearanceString = "sturdy"
	max_health = 100
	weight = 0.5

	attackby(obj/item/W as obj, mob/user as mob)
		if (istype(W,/obj/item/sheet) && (type == /obj/item/parts/robot_parts/arm/left/sturdy))
			// second check up there is just watching out for those ..() calls
			var/obj/item/sheet/M = W
			if (!M.reinforcement)
				boutput(user, "<span style=\"color:red\">You'll need reinforced sheets to reinforce the [name].</span>")
				return
			if (M.amount >= 2)
				boutput(user, "<span style=\"color:blue\">You reinforce [name] with the reinforced metal.</span>")
				new /obj/item/parts/robot_parts/arm/left/heavy(get_turf(src))
				M.amount -= 2
				if (M.amount < 1)
					user.drop_item()
					del(M)
				del(src)
				return
			else
				boutput(user, "<span style=\"color:red\">You need at least two reinforced metal sheets to reinforce this component.</span>")
				return
		else ..()

/obj/item/parts/robot_parts/arm/left/heavy
	name = "Heavy Cyborg Left Arm"
	appearanceString = "heavy"
	max_health = 175
	weight = 1

/obj/item/parts/robot_parts/arm/left/light
	name = "Light Cyborg Left Arm"
	appearanceString = "light"
	max_health = 25
	speedbonus = 0.2
	handlistPart = "armL-light"

/obj/item/parts/robot_parts/arm/right
	name = "Standard Cyborg Right Arm"
	icon_state = "r_arm"
	slot = "r_arm"
	icon_state_base = "armR"
	handlistPart = "armR-generic"

	attackby(obj/item/W as obj, mob/user as mob)
		if (istype(W,/obj/item/sheet) && (type == /obj/item/parts/robot_parts/arm/right))
			// second check up there is just watching out for those ..() calls
			var/obj/item/sheet/M = W
			if (M.amount >= 2)
				boutput(user, "<span style=\"color:blue\">You reinforce [name] with the metal.</span>")
				new /obj/item/parts/robot_parts/arm/right/sturdy(get_turf(src))
				M.amount -= 2
				if (M.amount < 1)
					user.drop_item()
					del(M)
				del(src)
				return
			else
				boutput(user, "<span style=\"color:red\">You need at least two metal sheets to reinforce this component.</span>")
				return
		else ..()

/obj/item/parts/robot_parts/arm/right/sturdy
	name = "Sturdy Cyborg Right Arm"
	appearanceString = "sturdy"
	max_health = 100
	weight = 0.5

	attackby(obj/item/W as obj, mob/user as mob)
		if (istype(W,/obj/item/sheet) && (type == /obj/item/parts/robot_parts/arm/right/sturdy))
			// second check up there is just watching out for those ..() calls
			var/obj/item/sheet/M = W
			if (!M.reinforcement)
				boutput(user, "<span style=\"color:red\">You'll need reinforced sheets to reinforce the [name].</span>")
				return
			if (M.amount >= 2)
				boutput(user, "<span style=\"color:blue\">You reinforce [name] with the reinforced metal.</span>")
				new /obj/item/parts/robot_parts/arm/right/heavy(get_turf(src))
				M.amount -= 2
				if (M.amount < 1)
					user.drop_item()
					del(M)
				del(src)
				return
			else
				boutput(user, "<span style=\"color:red\">You need at least two reinforced metal sheets to reinforce this component.</span>")
				return
		else ..()

/obj/item/parts/robot_parts/arm/right/heavy
	name = "Heavy Cyborg Right Arm"
	appearanceString = "heavy"
	max_health = 175
	weight = 1

/obj/item/parts/robot_parts/arm/right/light
	name = "Light Cyborg Right Arm"
	appearanceString = "light"
	max_health = 25
	speedbonus = 0.2
	handlistPart = "armR-light"

/obj/item/parts/robot_parts/leg
	name = "placeholder item (don't use this!)"
	desc = "A metal leg for a cyborg. It won't be able to move very well without this!"
	max_health = 60


	attack(mob/living/carbon/M as mob, mob/living/carbon/user as mob)
		if (!istype(M, /mob))
			return

		add_fingerprint(user)

		if (!(user.zone_sel.selecting in list("l_leg","r_leg")) || !istype(M, /mob/living/carbon/human))
			return ..()

		if (!((locate(/obj/machinery/optable) in M.loc) && M.lying) && !((locate(/obj/table) in M.loc) && (M.paralysis || M.stat)))
			return ..()

		var/mob/living/carbon/human/H = M

		if (!(slot in H.limbs.vars))
			boutput(user, "<span style=\"color:red\">You can't find a way to fit that on.</span>")
			return

		if (H.limbs.vars[slot])
			boutput(user, "<span style=\"color:red\">[H.name] already has one of those!</span>")
			return

		if (appearanceString == "sturdy" || appearanceString == "heavy")
			boutput(user, "<span style=\"color:red\">That leg is too big to fit on [H]'s body!</span>")
			return
/*
		if (appearanceString == "treads" && (H.limbs.l_leg || H.limbs.r_leg))
			boutput(user, "<span style=\"color:red\">Both of [H]'s legs must be removed to fit them with treads!</span>")
			return
*/
		attach(H,user)

		return

	attackby(obj/item/W as obj, mob/user as mob)
		if (istype(W, /obj/item/skull))
			var/obj/item/skull/Skull = W
			var/obj/machinery/bot/skullbot/B

			if (Skull.icon_state == "skull_crystal" || istype(Skull, /obj/item/skull/crystal))
				B = new /obj/machinery/bot/skullbot/crystal(get_turf(user))

			else if (Skull.icon_state == "skullP" || istype(Skull, /obj/item/skull/strange))
				B = new /obj/machinery/bot/skullbot/strange(get_turf(user))

			else if (Skull.icon_state == "skull_strange" || istype(Skull, /obj/item/skull/peculiar))
				B = new /obj/machinery/bot/skullbot/peculiar(get_turf(user))

			else if (Skull.icon_state == "skullA" || istype(Skull, /obj/item/skull/odd))
				B = new /obj/machinery/bot/skullbot/odd(get_turf(user))

			else if (Skull.icon_state == "skull_noface" || istype(Skull, /obj/item/skull/noface))
				B = new /obj/machinery/bot/skullbot/faceless(get_turf(user))

			else if (Skull.icon_state == "skull_gold" || istype(Skull, /obj/item/skull/gold))
				B = new /obj/machinery/bot/skullbot/gold(get_turf(user))

			else
				B = new /obj/machinery/bot/skullbot(get_turf(user))

			if (Skull.donor)
				B.name = "[Skull.donor.real_name] skullbot"

			user.show_text("You add [W] to [src]. That's neat.", "blue")
			qdel(W)
			qdel(src)
			return

		else if (istype(W, /obj/item/soulskull))
			new /obj/machinery/bot/skullbot/ominous(get_turf(user))
			boutput(user, "<span style=\"color:blue\">You add [W] to [src]. That's neat.</span>")
			qdel(W)
			qdel(src)
			return

		else
			return ..()

/obj/item/parts/robot_parts/leg/left
	name = "Standard Cyborg Left Leg"
	icon_state = "l_leg"
	slot = "l_leg"
	icon_state_base = "legL"

/obj/item/parts/robot_parts/leg/left/light
	name = "Light Cyborg Left Leg"
	appearanceString = "light"
	max_health = 25
	speedbonus = 0.2

/obj/item/parts/robot_parts/leg/left/treads
	name = "Cyborg Treads (Left)"
	desc = "A large wheeled unit like tank tracks. This will help heavier cyborgs to move quickly."
	icon_state = "l_lower_t"
	appearanceString = "treads"
	max_health = 100
	speedbonus = 0.25
	powerdrain = 2.5

/obj/item/parts/robot_parts/leg/right
	name = "Standard Cyborg Right Leg"
	icon_state = "r_leg"
	slot = "r_leg"
	icon_state_base = "legR"

/obj/item/parts/robot_parts/leg/right/light
	name = "Light Cyborg Right Leg"
	appearanceString = "light"
	max_health = 25
	speedbonus = 0.2

/obj/item/parts/robot_parts/leg/right/treads
	name = "Cyborg Treads (Right)"
	desc = "A large wheeled unit like tank tracks. This will help heavier cyborgs to move quickly."
	icon_state = "r_lower_t"
	appearanceString = "treads"
	max_health = 100
	speedbonus = 0.25
	powerdrain = 2.5

/obj/item/parts/robot_parts/leg/treads
	name = "Cyborg Treads"
	desc = "A large wheeled unit like tank tracks. This will help heavier cyborgs to move quickly."
	icon_state = "lower_t"
	slot = "leg_both"
	appearanceString = "treads"
	max_health = 100
	speedbonus = 0.5
	powerdrain = 5

/obj/item/parts/robot_parts/robot_frame
	name = "robot frame"
	icon_state = "robo_suit"
	max_health = 5000
	var/syndicate = 0 ///This will make the borg a syndie one
	var/obj/item/parts/robot_parts/head/head = null
	var/obj/item/parts/robot_parts/chest/chest = null
	var/obj/item/parts/robot_parts/l_arm = null
	var/obj/item/parts/robot_parts/r_arm = null
	var/obj/item/parts/robot_parts/l_leg = null
	var/obj/item/parts/robot_parts/r_leg = null
	var/obj/item/organ/brain/brain = null

	New()
		..()
		updateicon()

	emag_act(var/mob/user, var/obj/item/card/emag/E)
		if (!syndicate)
			syndicate = 1
			if (user)
				boutput(user, "<span style=\"color:blue\">You short out the behavior restrictors on the frame's motherboard.</span>")
			return TRUE
		else if (user)
			boutput(user, "<span style=\"color:red\">This frame's behavior restrictors have already been shorted out.</span>")
		return FALSE

	demag(var/mob/user)
		if (!syndicate)
			return FALSE
		if (user)
			user.show_text("You repair the behavior restrictors on the frame's motherboard.", "blue")
		syndicate = 0
		return TRUE

	attackby(obj/item/W as obj, mob/user as mob)
		if (istype(W, /obj/item/parts/robot_parts))
			var/obj/item/parts/robot_parts/P = W
			switch (P.slot)
				if ("head")
					if (head)
						boutput(user, "<span style=\"color:red\">There is already a head piece on the frame. If you want to remove it, use a wrench.</span>")
						return
					var/obj/item/parts/robot_parts/head/H = P
					if (!H.brain && !H.ai_interface)
						boutput(user, "<span style=\"color:red\">You need to insert a brain or an AI interface into the head piece before attaching it to the frame.</span>")
						return
					head = H

				if ("chest")
					if (chest)
						boutput(user, "<span style=\"color:red\">There is already a chest piece on the frame. If you want to remove it, use a wrench.</span>")
						return
					var/obj/item/parts/robot_parts/chest/C = P
					if (!C.wires)
						boutput(user, "<span style=\"color:red\">You need to add wiring to the chest piece before attaching it to the frame.</span>")
						return
					if (!C.cell)
						boutput(user, "<span style=\"color:red\">You need to add a power cell to the chest piece before attaching it to the frame.</span>")
						return
					chest = C

				if ("l_arm")
					if (l_arm)
						boutput(user, "<span style=\"color:red\">There is already a left arm piece on the frame. If you want to remove it, use a wrench.</span>")
						return
					l_arm = P

				if ("r_arm")
					if (r_arm)
						boutput(user, "<span style=\"color:red\">There is already a right arm piece on the frame. If you want to remove it, use a wrench.</span>")
						return
					r_arm = P

				if ("arm_both")
					if (l_arm || r_arm)
						boutput(user, "<span style=\"color:red\">There is already an arm piece on the frame that occupies both arm mountings. If you want to remove it, use a wrench.</span>")
						return
					l_arm = P
					r_arm = P

				if ("l_leg")
					if (l_leg)
						boutput(user, "<span style=\"color:red\">There is already a left leg piece on the frame. If you want to remove it, use a wrench.</span>")
						return
					l_leg = P

				if ("r_leg")
					if (r_leg)
						boutput(user, "<span style=\"color:red\">There is already a right leg piece on the frame. If you want to remove it, use a wrench.</span>")
						return
					r_leg = P

				if ("leg_both")
					if (l_leg || r_leg)
						boutput(user, "<span style=\"color:red\">There is already a leg piece on the frame that occupies both leg mountings. If you want to remove it, use a wrench.</span>")
						return
					l_leg = P
					r_leg = P

				else
					boutput(user, "<span style=\"color:red\">You can't seem to fit this piece anywhere on the frame.</span>")
					return

			playsound(get_turf(src), "sound/weapons/Genhit.ogg", 40, 1)
			boutput(user, "<span style=\"color:blue\">You add [P] to the frame.</span>")
			user.drop_item()
			P.set_loc(src)
			updateicon()

		if (istype(W, /obj/item/organ/brain))
			boutput(user, "<span style=\"color:red\">The brain needs to go in the head piece, not the frame.</span>")
			return

		if (istype(W,/obj/item/wrench))
			var/list/actions = list("Do nothing")
			if (check_completion())
				actions.Add("Finish and Activate the Cyborg")
			if (r_leg)
				actions.Add("Remove the Right leg")
			if (l_leg)
				actions.Add("Remove the Left leg")
			if (r_arm)
				actions.Add("Remove the Right arm")
			if (l_arm)
				actions.Add("Remove the Left arm")
			if (head)
				actions.Add("Remove the Head")
			if (chest)
				actions.Add("Remove the Chest")
			if (!actions.len)
				boutput(user, "<span style=\"color:red\">You can't think of anything to do with the frame.</span>")
				return

			var/action = input("What do you want to do?", "Robot Frame") in actions
			if (!action)
				return
			if (action == "Do nothing")
				return
			if (get_dist(loc,user.loc) > 1 && !user.bioHolder.HasEffect("telekinesis"))
				boutput(user, "<span style=\"color:red\">You need to move closer!</span>")
				return

			switch(action)
				if ("Finish and Activate the Cyborg")
					user.unlock_medal("Weird Science", 1)
					finish_cyborg()
				if ("Remove the Right leg")
					r_leg.set_loc( get_turf(src) )
					if (r_leg.slot == "leg_both")
						r_leg = null
						l_leg = null
					else r_leg = null
				if ("Remove the Left leg")
					l_leg.set_loc( get_turf(src) )
					if (l_leg.slot == "leg_both")
						r_leg = null
						l_leg = null
					else l_leg = null
				if ("Remove the Right arm")
					r_arm.set_loc( get_turf(src) )
					if (r_arm.slot == "arm_both")
						r_arm = null
						l_arm = null
					else r_arm = null
				if ("Remove the Left arm")
					l_arm.set_loc( get_turf(src) )
					if (l_arm.slot == "arm_both")
						r_arm = null
						l_arm = null
					else l_arm = null
				if ("Remove the Head")
					head.set_loc( get_turf(src) )
					head = null
				if ("Remove the Chest")
					chest.set_loc( get_turf(src) )
					chest = null
			playsound(get_turf(src), "sound/items/Ratchet.ogg", 40, 1)
			updateicon()
			return

	proc/updateicon()
		overlays = null
		if (chest) overlays += image('icons/mob/robots.dmi', "body-" + chest.appearanceString, OBJ_LAYER, 2)
		if (src.head) src.overlays += image('icons/mob/robots.dmi', "head-" + src.head.appearanceString, OBJ_LAYER, 2)

		if (l_leg)
			if (l_leg.slot == "leg_both") overlays += image('icons/mob/robots.dmi', "leg-" + l_leg.appearanceString, OBJ_LAYER, 2)
			else overlays += image('icons/mob/robots.dmi', "legL-" + l_leg.appearanceString, OBJ_LAYER, 2)

		if (r_leg)
			if (r_leg.slot == "leg_both") overlays += image('icons/mob/robots.dmi', "leg-" + r_leg.appearanceString, OBJ_LAYER, 2)
			else overlays += image('icons/mob/robots.dmi', "legR-" + r_leg.appearanceString, OBJ_LAYER, 2)

		if (l_arm)
			if (l_arm.slot == "arm_both") overlays += image('icons/mob/robots.dmi', "arm-" + l_arm.appearanceString, OBJ_LAYER, 2)
			else overlays += image('icons/mob/robots.dmi', "armL-" + l_arm.appearanceString, OBJ_LAYER, 2)

		if (r_arm)
			if (r_arm.slot == "arm_both") overlays += image('icons/mob/robots.dmi', "arm-" + r_arm.appearanceString, OBJ_LAYER, 2)
			else overlays += image('icons/mob/robots.dmi', "armR-" + r_arm.appearanceString, OBJ_LAYER, 2)

	proc/check_completion()
		if (chest && head)
			if (head.brain)
				return TRUE
			if (head.ai_interface)
				return TRUE
		return FALSE

	proc/collapse_to_pieces()
		visible_message("<strong>[src]</strong> falls apart into a pile of components!")
		. = get_turf(src)
		for (var/obj/item/O in contents) O.set_loc( . )
		chest = null
		head = null
		l_arm = null
		r_arm = null
		l_leg = null
		r_leg = null
		updateicon()
		return

	proc/finish_cyborg()
		var/mob/living/silicon/robot/O = null
		O = new /mob/living/silicon/robot(get_turf(loc),src,0,syndicate)
		// there was a big transferring list of parts from the frame to the compborg here at one point, but it didn't work
		// because the cyborg's process proc would kill it for having no chest piece set up after New() finished but
		// before it could get around to this list, so i tweaked their New() proc instead to grab all the shit out of
		// the frame before process could go off resulting in a borg that doesn't instantly die

		O.invisibility = 0
		O.name = "Cyborg"
		O.real_name = "Cyborg"

		if (head)
			if (head.brain)
				O.brain = head.brain
			else if (head.ai_interface)
				O.ai_interface = head.ai_interface
			else
				collapse_to_pieces()
				qdel(O)
				return
		else
			// how the fuck did you even do this
			collapse_to_pieces()
			qdel(O)
			return

		if (O.brain && O.brain.owner && O.brain.owner.key)
			if (O.brain.owner.current)
				O.gender = O.brain.owner.current.gender
				if (O.brain.owner.current.client)
					O.lastKnownIP = O.brain.owner.current.client.address
			O.brain.owner.transfer_to(O)
		else if (O.ai_interface)
			if (!(O in available_ai_shells))
				available_ai_shells += O
			for (var/mob/living/silicon/ai/AI in mobs)
				boutput(AI, "<span style=\"color:green\">[src] has been connected to you as a controllable shell.</span>")
			O.shell = 1
		else
			collapse_to_pieces()
			qdel(O)
			return

		if (chest && chest.cell)
			O.cell = chest.cell
			O.cell.set_loc(O)

		if (O.mind && !O.ai_interface)
			O.unlock_medal("Adjutant Online", 1)
			O.set_loc(get_turf(src))
			var/area/A = get_area(src)
			if (A)
				A.Entered(O)

			boutput(O, "<strong>You are playing a Robot. The Robot can interact with most electronic objects in its view point.</strong>")
			boutput(O, "To use something, simply double-click it.")
			boutput(O, "Use say \":s to speak to fellow cyborgs and the AI through binary.")

			if (syndicate)
				if ((ticker && ticker.mode && istype(ticker.mode, /game_mode/revolution)) && O.mind)
					ticker.mode:revolutionaries += O.mind
					ticker.mode:update_rev_icons_added(O.mind)

				O.syndicate = 1
				O.handle_robot_antagonist_status("activated", 0, usr)

			else
				boutput(O, "<strong>You must follow the AI's laws to the best of your ability.</strong>")
				O.show_laws() // The antagonist proc does that too.

			O.job = "Cyborg"

		// final check to guarantee the icon shows up for everyone
		if (O.mind && (ticker && ticker.mode && istype(ticker.mode, /game_mode/revolution)))
			if ((O.mind in ticker.mode:revolutionaries) || (O.mind in ticker.mode:head_revolutionaries))
				ticker.mode:update_all_rev_icons() //So the icon actually appears
		score_cyborgsmade += 1
		O.update_appearance()

		qdel(src)
		return

/obj/item/parts/robot_parts/robot_frame/syndicate
	syndicate = 1

// UPGRADES
// Cyborg

/obj/item/roboupgrade
	name = "robot upgrade"
	desc = "you shouldnt be able to see this!"
	icon = 'icons/obj/robot_parts.dmi'
	inhand_image_icon = 'icons/mob/inhand/hand_tools.dmi'
	item_state = "electronic"
	var/active = 0 // Is this module used like an item?
	var/passive = 0 // Does this module always work once installed?
	var/activated = 0 // live ingame variable
	var/drainrate = 0 // How much charge the upgrade consumes while installed
	var/charges = -1 // How many times a limited upgrade can be used before it is consumed (infinite if negative)
	var/removable = 1 // Can be removed from the cyborg
	var/borg_overlay = null // Used for cyborg update_apperance proc

	attack_self(var/mob/user as mob)
		if (!istype(user, /mob/living/silicon/robot))
			boutput(user, "<span style=\"color:red\">Only cyborgs can activate this item.</span>")
		else
			if (!activated)
				upgrade_activate()
			else
				upgrade_deactivate()

	proc/upgrade_activate(var/mob/living/silicon/robot/user as mob)
		if (!user)
			return TRUE
		if (!activated)
			activated = 1

	proc/upgrade_deactivate(var/mob/living/silicon/robot/user as mob)
		if (!user)
			return TRUE
		activated = 0

/obj/item/roboupgrade/jetpack
	name = "Propulsion Upgrade"
	desc = "A small turbine allowing cyborgs to move freely in space."
	icon_state = "up-jetpack"
	drainrate = 25
	borg_overlay = "up-jetpack"

	upgrade_activate(var/mob/living/silicon/robot/user as mob)
		if (..()) return
		user.jetpack = 1
		user.ion_trail = new /effects/system/ion_trail_follow()
		user.ion_trail.set_up(src)

	upgrade_deactivate(var/mob/living/silicon/robot/user as mob)
		if (..()) return
		user.jetpack = 0
		user.ion_trail = null

/obj/item/roboupgrade/healthgoggles
	name = "ProDoc Healthgoggles"
	desc = "Fitted with an advanced miniature sensor array that allows the user to quickly determine the physical condition of others."
	icon_state = "up-prodoc"
	var/client/assigned = null
	drainrate = 5

	New()
		//updateIcons()
		return ..()

	proc/updateIcons() //I wouldve liked to avoid this but i dont want to put this inside the mobs life proc as that would be more code.
		while (assigned)
			assigned.images.Remove(health_mon_icons)
			addIcons()

			if (loc != assigned.mob)
				assigned.images.Remove(health_mon_icons)
				assigned = null

			sleep(20)

	proc/addIcons()
		if (assigned)
			for (var/image/I in health_mon_icons)
				if (!I || !I.loc || !src)
					continue
				if (I.loc.invisibility && I.loc != src.loc)
					continue
				else assigned.images.Add(I)

	upgrade_activate(var/mob/living/silicon/robot/user as mob)
		if (..()) return
		assigned = user.client
		spawn (-1) updateIcons()
		return

	upgrade_deactivate(var/mob/living/silicon/robot/user as mob)
		if (..()) return
		if (assigned)
			assigned.images.Remove(health_mon_icons)
			assigned = null
		return

/obj/item/roboupgrade/efficiency
	name = "Efficiency Upgrade"
	desc = "A more advanced cooling system that causes cyborgs to consume less cell charge."
	icon_state = "up-power"
	passive = 1

/obj/item/roboupgrade/speed
	name = "Speed Upgrade"
	desc = "A booster unit that safely allows cyborgs to move at high speed."
	icon_state = "up-speed"
	drainrate = 100
	borg_overlay = "up-speed"

	upgrade_activate(var/mob/living/silicon/robot/user as mob)
		if (!user) return
		var/mob/living/silicon/robot/R = user
		if (!R.part_leg_r && !R.part_leg_l)
			boutput(user, "This upgrade cannot be used when you have no legs!")
			activated = 0
		else ..()

/obj/item/roboupgrade/physshield
	name = "Force Shield Upgrade"
	desc = "A force field generator that protects cyborgs from structural damage."
	icon_state = "up-Pshield"
	drainrate = 100
	borg_overlay = "up-pshield"

/obj/item/roboupgrade/fireshield
	name = "Heat Shield Upgrade"
	desc = "An air diffusion field that protects cyborgs from heat damage."
	icon_state = "up-Fshield"
	drainrate = 100
	borg_overlay = "up-fshield"

/obj/item/roboupgrade/teleport
	name = "Teleporter Upgrade"
	desc = "A personal teleportation device that allows a cyborg to transport itself instantly."
	icon_state = "up-teleport"
	active = 1
	drainrate = 250

	upgrade_activate(var/mob/living/silicon/robot/user as mob)
		if (!user || !src || loc != user || !issilicon(user) || !active)
			return
		if (user.stunned > 0 || user.weakened > 0 || user.paralysis >  0 || user.stat != 0)
			user.show_text("Not when you're incapacitated.", "red")
			return
		if (!isturf(user.loc))
			user.show_text("You can't teleport from inside a container.", "red")
			return

		var/list/L = list()
		var/list/areaindex = list()
		for (var/obj/item/device/radio/beacon/R in world)
			var/turf/T = find_loc(R)
			if (!T)	continue

			var/tmpname = T.loc.name
			if (areaindex[tmpname]) tmpname = "[tmpname] ([++areaindex[tmpname]])"
			else areaindex[tmpname] = 1
			L[tmpname] = R

		for (var/obj/item/implant/tracking/I in world)
			if (!I.implanted || !ismob(I.loc)) continue
			else
				var/mob/M = I.loc
				if (M.stat == 2)
					if (M.timeofdeath + 6000 < world.time) continue
				var/tmpname = M.real_name
				if (areaindex[tmpname]) tmpname = "[tmpname] ([++areaindex[tmpname]])"
				else areaindex[tmpname] = 1
				L[tmpname] = I

		var/desc = input("Area to jump to","Teleportation") in L

		if (!user || !src || loc != user || !issilicon(user))
			if (user) user.show_text("Teleportation failed.", "red")
			return
		if (user.mind && user.mind.current != loc) // Debrained or whatever.
			user.show_text("Teleportation failed.", "red")
			return
		if (user.stunned > 0 || user.weakened > 0 || user.paralysis >  0 || user.stat != 0)
			user.show_text("Not when you're incapacitated.", "red")
			return
		if (!active)
			user.show_text("Cannot teleport, upgrade is inactive.", "red")
			return
		if (!desc || !L[desc])
			user.show_text("Invalid selection.", "red")
			return
		if (!isturf(user.loc))
			user.show_text("You can't teleport from inside a container.", "red")
			return

		do_teleport(user,L[desc],0)
		return

/obj/item/roboupgrade/repair
	name = "Self-Repair Upgrade"
	desc = "An infusion of nanobots that allow a cyborg to automatically repair sustained damage."
	icon_state = "up-repair"
	drainrate = 60
	borg_overlay = "up-repair"

/obj/item/roboupgrade/aware
	name = "Recovery Upgrade"
	desc = "Allows a cyborg to immediatley reboot its systems if incapacitated in any way."
	icon_state = "up-aware"
	active = 1
	drainrate = 2500 //Was 100. jfc

	upgrade_activate(var/mob/living/silicon/robot/user as mob)
		if (!user) return
		boutput(user, "<strong>REBOOTING...</strong>")
		user.stunned = 0
		user.weakened = 0
		user.paralysis = 0
		user.blinded = 0
		user.take_eye_damage(-INFINITY)
		user.take_eye_damage(-INFINITY, 1)
		user.blinded = 0
		user.take_ear_damage(-INFINITY)
		user.take_ear_damage(-INFINITY, 1)
		user.change_eye_blurry(-INFINITY)
		user.druggy = 0
		user.change_misstep_chance(-INFINITY)
		user.dizziness = 0

		boutput(user, "<strong>REBOOT COMPLETE</strong>")

/obj/item/roboupgrade/expand
	name = "Expansion Upgrade"
	desc = "A matter miniaturizer that frees up room in a cyborg for more upgrades."
	icon_state = "up-expand"
	active = 1
	charges = 1

	upgrade_activate(var/mob/living/silicon/robot/user as mob)
		if (!user) return
		user.max_upgrades++
		boutput(user, "<span style=\"color:blue\">You can now hold up to [user.max_upgrades] upgrades!</span>")
		user.upgrades.Remove(src)
		qdel(src)

/obj/item/roboupgrade/rechargepack
	name = "Recharge Pack"
	desc = "A single-use reserve battery that can recharge a cyborg's cell to full capacity."
	icon_state = "up-recharge"
	active = 1
	charges = 1

	upgrade_activate(var/mob/living/silicon/robot/user as mob)
		if (!user) return
		if (user.cell)
			var/obj/item/cell/C = user.cell
			C.charge = C.maxcharge
			boutput(user, "<span style=\"color:blue\">Cell has been recharged to [user.cell.charge]!</span>")
		else
			boutput(user, "<span style=\"color:red\">You don't have a cell to recharge!</span>")
			charges++

/obj/item/roboupgrade/repairpack
	name = "Repair Pack"
	desc = "A single-use nanite infusion that can repair up to 50% of a cyborg's structure."
	icon_state = "up-reppack"
	active = 1
	charges = 1

	upgrade_activate(var/mob/living/silicon/robot/user as mob)
		if (!user) return
		for (var/obj/item/parts/robot_parts/RP in user.contents) RP.ropart_mend_damage(100,100)
		boutput(user, "<span style=\"color:blue\">All components repaired!</span>")

/obj/item/roboupgrade/opticmeson
	name = "Optical Meson Upgrade"
	desc = "A set of advanced lens and detectors enabling a cyborg to see into the meson spectrum."
	icon_state = "up-opticmes"
	drainrate = 5
	borg_overlay = "up-meson"

/obj/item/roboupgrade/visualizer
	name = "Construction Visualizer"
	desc = "A set of advanced lens which display 3D real time blueprints."
	icon_state = "up-opticmes"
	drainrate = 5
	borg_overlay = "up-meson"
/* doesn't really do anything atm
/obj/item/roboupgrade/opticthermal
	name = "Optical Thermal Upgrade"
	desc = "A set of advanced lens and detectors enabling a cyborg to see into the thermal spectrum."
	icon_state = "up-opticthe"
	borg_overlay = "up-thermal"
	drainrate = 10
*/
// AI Upgrades

/obj/item/roboupgrade/ai
	name = "AI upgrade"
	icon_state = "mod-sta"

	attack_self(var/mob/user as mob)
		if (!istype(user, /mob/living/silicon/ai))
			boutput(user, "<span style=\"color:red\">Only an AI can use this item.</span>")
			return

	proc/slot_in(var/mob/living/silicon/ai/AI)
		if (!AI)
			return TRUE
		AI.installed_modules += src
		return FALSE

	proc/slot_out(var/mob/living/silicon/ai/AI)
		if (!AI)
			return TRUE
		AI.installed_modules -= src
		return FALSE

/*	Cogs, just uncomment this stuff when the VOX thing is ready - ISN
/obj/item/roboupgrade/ai/vox
	name = "AI VOX Module"
	desc = "A speech synthesizer module that allows the AI to make vocal announcements over the station radio system."
	icon_state = "mod-atmos"

	slot_in(var/mob/living/silicon/ai/AI)
		if (..())
			return
		AI.verbs += whatever the vox verb is i guess

	slot_out(var/mob/living/silicon/ai/AI)
		if (..())
			return
		AI.verbs -= whatever the vox verb is i guess
*/

/obj/item/roboupgrade/ai/law_override
	name = "AI Law Override Module"
	desc = "A module that overrides the AI's inherent law set with a customised one."
	icon_state = "mod-sec"
	var/ai_laws/law_set = null
	var/ai_laws/old_law_set = null

	New()
		..()
		law_set = new /ai_laws(src)

	slot_in(var/mob/living/silicon/ai/AI)
		if (..())
			return
		boutput(AI, "<strong>Your inherent laws have been overridden by an inserted module.</strong>")
		old_law_set = ticker.centralized_ai_laws
		ticker.centralized_ai_laws = law_set
		ticker.centralized_ai_laws.show_laws(AI)

	slot_out(var/mob/living/silicon/ai/AI)
		if (..())
			return
		boutput(AI, "<strong>Your inherent laws have been restored.</strong>")
		ticker.centralized_ai_laws = old_law_set
		ticker.centralized_ai_laws.show_laws(AI)
		old_law_set = null

	attack_self(var/mob/user as mob)
		if (!istype(user, /mob/living/carbon))
			boutput(user, "<span style=\"color:red\">Silicon lifeforms cannot access this module's functions.</span>")
			return

		if (!istype(law_set,/ai_laws))
			law_set = new /ai_laws(src)
			// just in case

		var/ai_laws/LAW = law_set
		var/law_counter = 1
		var/entered_text = ""
		while (law_counter < 4)
			entered_text = input("Enter Law #[law_counter].","[name]") as null|text
			if (entered_text)
				if (law_counter > LAW.inherent.len)
					LAW.inherent += entered_text
				else
					LAW.inherent[law_counter] = entered_text
			else
				break
			law_counter++