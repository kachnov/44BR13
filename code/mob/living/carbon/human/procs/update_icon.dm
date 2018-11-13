#define wear_sanity_check(X) if (!X.wear_image) X.wear_image = image(X.wear_image_icon)
#define inhand_sanity_check(X) if (!X.inhand_image) X.inhand_image = image(X.inhand_image_icon)

/mob/living/carbon/human/update_clothing(var/loop_blocker)
	..()

	if (transforming || loop_blocker)
		return

	if (!blood_image)
		blood_image = image('icons/effects/blood.dmi')

	// lol

	var/tmp/head_offset = 0
	var/tmp/hand_offset = 0
	var/tmp/body_offset = 0

	if (mutantrace)
		head_offset = mutantrace.head_offset
		hand_offset = mutantrace.hand_offset
		body_offset = mutantrace.body_offset

	if (buckled)
		if (istype(buckled, /obj/stool/bed))
			lying = 1
		else
			lying = 0

	// If he's wearing magnetic boots anchored = 1, otherwise anchored = 0
	if (istype(shoes, /obj/item/clothing/shoes/magnetic))
		anchored = 1
	else
		anchored = 0
	// Automatically drop anything in store / id / belt if you're not wearing a uniform.
	if (!w_uniform)
		for (var/obj/item/thing in list(r_store, l_store, wear_id, belt))
			if (thing)
				u_equip(thing, 1)

				if (thing)
					thing.set_loc(loc)
					thing.dropped(src)
					thing.layer = initial(thing.layer)

	UpdateOverlays(body_standing, "body")
	UpdateOverlays(hands_standing, "hands")
	UpdateOverlays(damage_standing, "damage")
	UpdateOverlays(head_damage_standing, "head_damage")
	UpdateOverlays(inhands_standing, "inhands")

	UpdateOverlays(fire_standing, "fire")

	if (lying != lying_old)
		lying_old = lying
		animate_rest(src, !lying)

	update_face()
	if (organHolder && organHolder.head)
		if (!mutantrace || !mutantrace.override_eyes)
			UpdateOverlays(image_eyes, "eyes")
		else
			UpdateOverlays(null, "eyes")
		if (!mutantrace || !mutantrace.override_hair)
			UpdateOverlays(image_cust_one, "cust_one")
		else
			UpdateOverlays(null, "cust_one")
		if (!mutantrace || !mutantrace.override_detail)
			UpdateOverlays(image_cust_two, "cust_two")
		else
			UpdateOverlays(null, "cust_two")
		if (!mutantrace || !mutantrace.override_beard)
			UpdateOverlays(image_cust_three, "cust_three")
		else
			UpdateOverlays(null, "cust_three")


	else
		UpdateOverlays(null, "eyes")
		UpdateOverlays(null, "cust_one")
		UpdateOverlays(null, "cust_two")
		UpdateOverlays(null, "cust_three")

	// Uniform
	if (w_uniform)
		if (bioHolder && bioHolder.HasEffect("fat") && !(w_uniform.c_flags & ONESIZEFITSALL))
			boutput(src, "<span style=\"color:red\">You burst out of the [w_uniform.name]!</span>")
			var/obj/item/clothing/c = w_uniform
			u_equip(c)
			if (c)
				c.set_loc(loc)
				c.dropped(src)
				c.layer = initial(c.layer)
		if (istype(w_uniform, /obj/item/clothing/under))
			var/image/suit_image
			if (bioHolder && bioHolder.HasEffect("fat"))
				if (!w_uniform.wear_image_fat) w_uniform.wear_image_fat = image(w_uniform.wear_image_fat_icon)
				suit_image = w_uniform.wear_image_fat
			else
				wear_sanity_check(w_uniform)
				suit_image = w_uniform.wear_image

			suit_image.icon_state = w_uniform.icon_state
			suit_image.layer = MOB_CLOTHING_LAYER
			suit_image.alpha = w_uniform.alpha
			suit_image.color = w_uniform.color
			UpdateOverlays(suit_image, "suit_image")

			if (w_uniform.blood_DNA)
				blood_image.icon_state =  "uniformblood"
				blood_image.layer = MOB_CLOTHING_LAYER+0.1
				UpdateOverlays(blood_image, "suit_image_blood")
			else
				UpdateOverlays(null, "suit_image_blood")
	else
		UpdateOverlays(null, "suit_image")
		UpdateOverlays(null, "suit_image_blood")

	if (wear_id)
		wear_sanity_check(wear_id)
		wear_id.wear_image.icon_state = "id"
		wear_id.wear_image.pixel_y = body_offset
		wear_id.wear_image.layer = MOB_BELT_LAYER
		wear_id.wear_image.color = wear_id.color
		wear_id.wear_image.alpha = wear_id.alpha
		UpdateOverlays(src.wear_id.wear_image, "wear_id")
	else
		UpdateOverlays(null, "wear_id")

	// No blood overlay if we have gloves (e.g. bloody hands visible through clean gloves).
	if (blood_DNA && !gloves)
		if (lying)
			blood_image.pixel_x = hand_offset
			blood_image.pixel_y = 0
		else
			blood_image.pixel_x = 0
			blood_image.pixel_y = hand_offset

		blood_image.layer = MOB_HAND_LAYER2 + 0.1
		if (limbs && limbs.l_arm && !istype(limbs.l_arm, /obj/item/parts/robot_parts))
			blood_image.icon_state = "left_bloodyhands"
			UpdateOverlays(blood_image, "bloody_hands_l")

		if (limbs && limbs.r_arm && !istype(limbs.r_arm, /obj/item/parts/robot_parts))
			blood_image.icon_state = "right_bloodyhands"
			UpdateOverlays(blood_image, "bloody_hands_r")

		blood_image.pixel_x = 0
		blood_image.pixel_y = 0
	else
		UpdateOverlays(null, "bloody_hands_l")
		UpdateOverlays(null, "bloody_hands_r")

	// Gloves
	if (gloves)
		wear_sanity_check(gloves)
		var/icon_name = gloves.item_state
		if (!icon_name)
			icon_name = gloves.icon_state

		gloves.wear_image.layer = MOB_HAND_LAYER2

		if (!gloves.monkey_clothes)
			gloves.wear_image.pixel_x = 0
			gloves.wear_image.pixel_y = hand_offset

		gloves.wear_image.layer = MOB_HAND_LAYER2
		if (limbs && limbs.l_arm && limbs && !istype(limbs.l_arm, /obj/item/parts/robot_parts)) //bioHolder && !bioHolder.HasEffect("robot_left_arm"))
			gloves.wear_image.icon_state = "left_[icon_name]"
			gloves.wear_image.color = gloves.color
			UpdateOverlays(src.gloves.wear_image, "wear_gloves_l")

		if (limbs && limbs.r_arm && limbs && !istype(limbs.r_arm, /obj/item/parts/robot_parts)) //bioHolder && !bioHolder.HasEffect("robot_right_arm"))
			gloves.wear_image.icon_state = "right_[icon_name]"
			gloves.wear_image.color = gloves.color
			gloves.wear_image.alpha = gloves.alpha
			UpdateOverlays(src.gloves.wear_image, "wear_gloves_r")

		if (gloves.blood_DNA)
			if (!gloves.monkey_clothes)
				if (lying)
					blood_image.pixel_x = hand_offset
					blood_image.pixel_y = 0
				else
					blood_image.pixel_x = 0
					blood_image.pixel_y = hand_offset

			blood_image.layer = MOB_HAND_LAYER2 + 0.1
			if (limbs && limbs.l_arm && !istype(limbs.l_arm, /obj/item/parts/robot_parts))
				blood_image.icon_state = "left_bloodygloves"
				UpdateOverlays(blood_image, "bloody_gloves_l")

			if (limbs && limbs.r_arm && !istype(limbs.r_arm, /obj/item/parts/robot_parts))
				blood_image.icon_state = "right_bloodygloves"
				UpdateOverlays(blood_image, "bloody_gloves_r")

			blood_image.pixel_x = 0
			blood_image.pixel_y = 0
		else
			UpdateOverlays(null, "bloody_gloves_l")
			UpdateOverlays(null, "bloody_gloves_r")

	else
		UpdateOverlays(null, "wear_gloves_l")
		UpdateOverlays(null, "wear_gloves_r")
		UpdateOverlays(null, "bloody_gloves_l")
		UpdateOverlays(null, "bloody_gloves_r")

	if (gloves && gloves.uses >= 1)
		gloves.wear_image.icon_state = "stunoverlay"
		UpdateOverlays(gloves.wear_image, "stunoverlay")
	else
		UpdateOverlays(null, "stunoverlay")

	// Shoes
	if (shoes)
		wear_sanity_check(shoes)
		//. = limbs && (!limbs.l_leg || istype(limbs.l_leg, /obj/item/parts/robot_parts) //(bioHolder && bioHolder.HasOneOfTheseEffects("lost_left_leg","robot_left_leg","robot_treads"))
		shoes.wear_image.layer = MOB_CLOTHING_LAYER
		if (limbs && limbs.l_leg && !istype(limbs.l_leg, /obj/item/parts/robot_parts))
			shoes.wear_image.icon_state = "left_[shoes.icon_state]"
			shoes.wear_image.color = shoes.color
			UpdateOverlays(src.shoes.wear_image, "wear_shoes_l")

		if (limbs && limbs.r_leg && !istype(limbs.r_leg, /obj/item/parts/robot_parts))
			shoes.wear_image.icon_state = "right_[shoes.icon_state]"//[!( lying ) ? null : "2"]"
			shoes.wear_image.color = shoes.color
			shoes.wear_image.alpha = shoes.alpha
			UpdateOverlays(src.shoes.wear_image, "wear_shoes_r")

		if (shoes.blood_DNA)
			blood_image.layer = MOB_CLOTHING_LAYER+0.1
			if (limbs && limbs.l_leg && !.)
				blood_image.icon_state = "left_shoesblood"//[!( lying ) ? null : "2"]"
				UpdateOverlays(blood_image, "bloody_shoes_l")
			else
				UpdateOverlays(null, "bloody_shoes_l")

			if (limbs && limbs.r_leg && !.)
				blood_image.icon_state = "right_shoesblood"//[!( lying ) ? null : "2"]"
				UpdateOverlays(blood_image, "bloody_shoes_r")
			else
				UpdateOverlays(null, "bloody_shoes_r")
		else
			UpdateOverlays(null, "bloody_shoes_l")
			UpdateOverlays(null, "bloody_shoes_r")
	else
		UpdateOverlays(null, "bloody_shoes_l")
		UpdateOverlays(null, "bloody_shoes_r")
		UpdateOverlays(null, "wear_shoes_l")
		UpdateOverlays(null, "wear_shoes_r")

	if (wear_suit)
		if (bioHolder && bioHolder.HasEffect("fat") && !(wear_suit.c_flags & ONESIZEFITSALL))
			boutput(src, "<span style=\"color:red\">You burst out of the [wear_suit.name]!</span>")
			var/obj/item/clothing/c = wear_suit
			u_equip(c)
			if (c)
				c.set_loc(loc)
				c.dropped(src)
				c.layer = initial(c.layer)
		else
			wear_sanity_check(wear_suit)
			if (istype(wear_suit, /obj/item/clothing/suit))
				if (wear_suit.over_all)
					wear_suit.wear_image.layer = MOB_OVERLAY_BASE
				else
					wear_suit.wear_image.layer = MOB_ARMOR_LAYER
				wear_suit.wear_image.icon_state = "[wear_suit.icon_state]"//[!( lying ) ? null : "2"]"
				wear_suit.wear_image.color = wear_suit.color
				wear_suit.wear_image.alpha = wear_suit.alpha
				UpdateOverlays(src.wear_suit.wear_image, "wear_suit")

			if (wear_suit.blood_DNA)
				if (istype(wear_suit, /obj/item/clothing/suit/armor/vest || /obj/item/clothing/suit/wcoat || /obj/item/clothing/suit/armor/suicide_bomb))
					blood_image.icon_state = "armorblood"
				else if (istype(wear_suit, /obj/item/clothing/suit/det_suit || /obj/item/clothing/suit/labcoat))
					blood_image.icon_state = "coatblood"
				else
					blood_image.icon_state = "suitblood"
				switch (wear_suit.wear_image.layer)
					if (MOB_OVERLAY_BASE)
						blood_image.layer = MOB_OVERLAY_BASE + 0.1
					if (MOB_ARMOR_LAYER)
						blood_image.layer = MOB_ARMOR_LAYER + 0.1
				UpdateOverlays(blood_image, "wear_suit_bloody")
			else
				UpdateOverlays(null, "wear_suit_bloody")

			if (istype(wear_suit, /obj/item/clothing/suit/straight_jacket))
				if (handcuffed)
					handcuffed.set_loc(loc)
					handcuffed.layer = initial(handcuffed.layer)
					handcuffed = null
				if ((l_hand || r_hand))
					var/h = hand
					hand = 1
					drop_item()
					hand = 0
					drop_item()
					hand = h
	else
		UpdateOverlays(null, "wear_suit")
		UpdateOverlays(null, "wear_suit_bloody")

	if (back)
		wear_sanity_check(back)
		back.wear_image.icon_state = "[back.icon_state]"//[!( lying ) ? null : "2"]"
		back.wear_image.pixel_x = 0
		back.wear_image.pixel_y = body_offset

		back.wear_image.layer = MOB_BACK_LAYER
		back.wear_image.color = back.color
		back.wear_image.alpha = back.alpha
		UpdateOverlays(src.back.wear_image, "wear_back")
		src.back.screen_loc = ui_back
	else
		UpdateOverlays(null, "wear_back")

	// Glasses
	if (glasses)
		wear_sanity_check(glasses)
		glasses.wear_image.icon_state = "[glasses.icon_state]"//[(!( lying ) ? null : "2")]"
		glasses.wear_image.layer = MOB_GLASSES_LAYER
		if (!glasses.monkey_clothes)
			glasses.wear_image.pixel_x = 0
			glasses.wear_image.pixel_y = head_offset
		glasses.wear_image.color = glasses.color
		glasses.wear_image.alpha = glasses.alpha
		UpdateOverlays(src.glasses.wear_image, "wear_glasses")
	else
		UpdateOverlays(null, "wear_glasses")
	// Ears
	if (ears)
		wear_sanity_check(ears)
		ears.wear_image.icon_state = "[ears.icon_state]"//[(!( lying ) ? null : "2")]"
		ears.wear_image.layer = MOB_GLASSES_LAYER
		ears.wear_image.pixel_x = 0
		ears.wear_image.pixel_y = head_offset
		ears.wear_image.color = ears.color
		ears.wear_image.alpha = ears.alpha
		UpdateOverlays(src.ears.wear_image, "wear_ears")
	else
		UpdateOverlays(null, "wear_ears")

	if (wear_mask)
		wear_sanity_check(wear_mask)
		if (istype(wear_mask, /obj/item/clothing/mask))
			wear_mask.wear_image.icon_state = "[wear_mask.icon_state]"//[(!( lying ) ? null : "2")]"
			if (!wear_mask.monkey_clothes)
				wear_mask.wear_image.pixel_x = 0
				wear_mask.wear_image.pixel_y = head_offset
			wear_mask.wear_image.layer = MOB_HEAD_LAYER1
			wear_mask.wear_image.color = wear_mask.color
			wear_mask.wear_image.alpha = wear_mask.alpha
			UpdateOverlays(src.wear_mask.wear_image, "wear_mask")
			if (!istype(wear_mask, /obj/item/clothing/mask/cigarette))
				if (wear_mask.blood_DNA)
					blood_image.icon_state = "maskblood"
					blood_image.layer = MOB_HEAD_LAYER1 + 0.1
					if (!wear_mask.monkey_clothes)
						blood_image.pixel_x = 0
						blood_image.pixel_y = head_offset
					UpdateOverlays(blood_image, "wear_mask_blood")
					blood_image.pixel_x = 0
					blood_image.pixel_y = 0
				else
					UpdateOverlays(null, "wear_mask_blood")
	else
		UpdateOverlays(null, "wear_mask")
		UpdateOverlays(null, "wear_mask_blood")
	// Head
	if (head)
		wear_sanity_check(head)

		head.wear_image.layer = MOB_HEAD_LAYER2
		head.wear_image.icon_state = "[head.icon_state]"
		/* TODO: adapt butts to blend colors properly again
		if (istype(head, /obj/item/clothing/head/butt))
			var/obj/item/clothing/head/butt/B = head
			if (B.s_tone >= 0)
				head_icon.Blend(rgb(B.s_tone, B.s_tone, B.s_tone), ICON_ADD)
			else
				head_icon.Blend(rgb(-B.s_tone,  -B.s_tone,  -B.s_tone), ICON_SUBTRACT)
		*/
		if (!head.monkey_clothes)
			head.wear_image.pixel_x = 0
			src.head.wear_image.pixel_y = head_offset
		head.wear_image.color = head.color
		head.wear_image.alpha = head.alpha
		UpdateOverlays(src.head.wear_image, "wear_head")
		if (head.blood_DNA)
			blood_image.icon_state = "helmetblood"
			blood_image.layer = MOB_HEAD_LAYER2 + 0.1
			if (!head.monkey_clothes)
				blood_image.pixel_x = 0
				blood_image.pixel_y = head_offset
			UpdateOverlays(blood_image, "wear_head_blood")
			blood_image.pixel_x = 0
			blood_image.pixel_y = 0
		else
			UpdateOverlays(null, "wear_head_blood")
	else
		UpdateOverlays(null, "wear_head")
		UpdateOverlays(null, "wear_head_blood")
	// Belt
	if (belt)
		wear_sanity_check(belt)
		var/t1 = belt.item_state
		if (!t1)
			t1 = belt.icon_state
		belt.wear_image.icon_state = "[t1]"
		belt.wear_image.pixel_x = 0
		belt.wear_image.pixel_y = body_offset
		belt.wear_image.layer = MOB_BELT_LAYER
		belt.wear_image.color = belt.color
		belt.wear_image.alpha = belt.alpha
		UpdateOverlays(src.belt.wear_image, "wear_belt")
		src.belt.screen_loc = ui_belt
	else
		UpdateOverlays(null, "wear_belt")

	UpdateName()

//	if (wear_id) //Most of the inventory is now hidden, this is handled by other_update()
//		wear_id.screen_loc = ui_id

	if (l_store)
		l_store.screen_loc = ui_storage1

	if (r_store)
		r_store.screen_loc = ui_storage2

	if (handcuffed)
		pulling = null
		handcuff_img.icon_state = "handcuff1"
		handcuff_img.pixel_x = 0
		handcuff_img.pixel_y = hand_offset
		handcuff_img.layer = MOB_HANDCUFF_LAYER
		UpdateOverlays(handcuff_img, "handcuffs")
	else
		UpdateOverlays(null, "handcuffs")

	var/shielded = 0
	for (var/obj/item/device/shield/S in src)
		if (S.active)
			shielded = 1
			break

	for (var/obj/item/cloaking_device/S in src)
		if (S.active)
			shielded = 2
			break

	if (shielded == 2) invisibility = 2
	else invisibility = 0

	if (shielded)
		UpdateOverlays(shield_image, "shield")
	else
		UpdateOverlays(null, "shield")

	for (var/I in implant_images)
		if (!(I in implant))
			UpdateOverlays(null, "implant--\ref[I]")
			implant_images -= I
	for (var/obj/item/implant/I in implant)
		if (I.implant_overlay && !(I in implant_images))
			UpdateOverlays(I.implant_overlay, "implant--\ref[I]")
			implant_images += I

	for (var/mob/M in viewers(1, src))
		if ((M.client && M.machine == src))
			spawn (0)
				show_inv(M)
				return

	last_b_state = stat

#undef wear_sanity_check
#undef inhand_sanity_check

/mob/living/carbon/human/update_face()
	..()

	if (organHolder && !organHolder.head)
		image_eyes.icon_state = "bald"
		image_cust_one.icon_state = "bald"
		image_cust_two.icon_state = "bald"
		image_cust_three.icon_state = "bald"
		return

	if (!bioHolder)
		return // fuck u

	var/appearanceHolder/aH = bioHolder.mobAppearance
	var/mutantrace/m_race = mutantrace
	if (organHolder && organHolder.head && organHolder.head.donor != src) // gaaaaaaaaaahhhhh
		if (organHolder.head.donor_appearance)
			aH = organHolder.head.donor_appearance
		if (organHolder.head.donor_mutantrace)
			m_race = organHolder.head.donor_mutantrace

	if (!m_race || !m_race.override_eyes)
		image_eyes.icon_state = "eyes"
		image_eyes.color = aH.e_color

	if (!m_race || !m_race.override_hair)
		cust_one_state = customization_styles[aH.customization_first]
		if (!cust_one_state)
			cust_one_state = customization_styles_gimmick[aH.customization_first]
		image_cust_one.icon_state = cust_one_state
		image_cust_one.color = aH.customization_first_color

	if (!m_race || !m_race.override_beard)
		cust_two_state = customization_styles[aH.customization_second]
		if (!cust_two_state)
			cust_two_state = customization_styles_gimmick[aH.customization_second]
		image_cust_two.icon_state = cust_two_state
		image_cust_two.color = aH.customization_second_color

	if (!m_race || !m_race.override_detail)
		cust_three_state = customization_styles[aH.customization_third]
		if (!cust_three_state)
			cust_three_state = customization_styles_gimmick[aH.customization_third]
		image_cust_three.icon_state = cust_three_state
		image_cust_three.color = aH.customization_third_color


/mob/living/carbon/human/update_burning_icon(var/old_burning)

	if (burning > 0)
		var/istate = "fire1"
		if (burning <= 33)
			istate = "fire1"
			//fire_standing = image('icons/mob/human.dmi', "fire1", MOB_EFFECT_LAYER)
			//fire_lying = image('icons/mob/human.dmi', "fire1_l", MOB_EFFECT_LAYER)
		else if (burning > 33 && burning <= 66)
			istate = "fire2"
			//fire_standing = image('icons/mob/human.dmi', "fire2", MOB_EFFECT_LAYER)
			//fire_lying = image('icons/mob/human.dmi', "fire2_l", MOB_EFFECT_LAYER)
		else if (burning > 66)
			istate = "fire3"
			//fire_standing = image('icons/mob/human.dmi', "fire3", MOB_EFFECT_LAYER)
			//fire_lying = image('icons/mob/human.dmi', "fire3_l", MOB_EFFECT_LAYER)
		fire_standing = SafeGetOverlayImage("fire", 'icons/mob/human.dmi', istate, MOB_EFFECT_LAYER)

		//make them light up!
		burning_light.set_brightness(round(0.5 + burning / 150, 0.1))
		burning_light.enable()
	else
		fire_standing = null
		burning_light.disable()

	UpdateOverlays(fire_standing, "fire", 0, 1)

/mob/living/carbon/human/update_inhands()

	inhands_standing.len = 0
	var/image/i_r_hand = null
	var/image/i_l_hand = null

	var/hand_offset = 0
	if (mutantrace)
		hand_offset = mutantrace.hand_offset

	if (limbs)
		if (limbs.r_arm && r_hand)
			if (!istype(limbs.r_arm, /obj/item/parts/human_parts/arm/right/item) && istype(r_hand, /obj/item))
				var/obj/item/I = r_hand
				if (!I.inhand_image)
					I.inhand_image = image(I.inhand_image_icon, "", MOB_INHAND_LAYER)
				I.inhand_image.icon_state = I.item_state ? I.item_state + "-R" : I.icon_state + "-R"

				I.inhand_image.pixel_x = 0
				I.inhand_image.pixel_y = hand_offset
				i_r_hand = I.inhand_image

		if (limbs.l_arm && l_hand)
			if (!istype(limbs.l_arm, /obj/item/parts/human_parts/arm/left/item) && istype(l_hand, /obj/item))
				var/obj/item/I = l_hand
				if (!I.inhand_image)
					I.inhand_image = image(I.inhand_image_icon, "", MOB_INHAND_LAYER)
				I.inhand_image.icon_state = I.item_state ? I.item_state + "-L" : I.icon_state + "-L"

				I.inhand_image.pixel_x = 0
				I.inhand_image.pixel_y = hand_offset
				i_l_hand = I.inhand_image


	UpdateOverlays(i_r_hand, "i_r_hand")
	UpdateOverlays(i_l_hand, "i_l_hand")

/mob/living/carbon/human/proc/update_hair_layer()
	if (wear_suit && head && wear_suit.over_hair && head.seal_hair)
		image_cust_one.layer = MOB_HAIR_LAYER1
		image_cust_two.layer = MOB_HAIR_LAYER1
		image_cust_three.layer = MOB_HAIR_LAYER1
	else
		image_cust_one.layer = MOB_HAIR_LAYER2
		image_cust_two.layer = MOB_HAIR_LAYER2
		image_cust_three.layer = MOB_HAIR_LAYER2


var/list/update_body_limbs = list("r_arm" = "stump_arm_right", "l_arm" = "stump_arm_left", "r_leg" = "stump_leg_right", "l_leg" = "stump_leg_left")

/mob/living/carbon/human/update_body()
	..()

	var/file
	if (!decomp_stage)
		file = 'icons/mob/human.dmi'
	else
		file = 'icons/mob/human_decomp.dmi'

	body_standing = SafeGetOverlayImage("body", file, "blank", MOB_LIMB_LAYER) // image('icons/mob/human.dmi', "blank", MOB_LIMB_LAYER)
	body_standing.overlays.len = 0
	hands_standing = SafeGetOverlayImage("hands", file, "blank", MOB_HAND_LAYER1) //image('icons/mob/human.dmi', "blank", MOB_HAND_LAYER1)
	hands_standing.overlays.len = 0

	/*
	body_standing = image('icons/mob/human_decomp.dmi', "blank", MOB_LIMB_LAYER)
	hands_standing = image('icons/mob/human_decomp.dmi', "blank", MOB_HAND_LAYER1)
	*/
	if (!mutantrace)
		if ((bioHolder && !bioHolder.HasEffect("fat")) || decomp_stage)
			var/gender_t = gender == FEMALE ? "f" : "m"

			var/skin_tone = bioHolder.mobAppearance.s_tone
			human_image.color = rgb(skin_tone + 220, skin_tone + 220, skin_tone + 220)
			human_decomp_image.color = rgb(skin_tone + 220, skin_tone + 220, skin_tone + 220)

			if (!decomp_stage)
				human_image.icon_state = "chest_[gender_t]"
				body_standing.overlays += human_image
				human_image.icon_state = "groin_[gender_t]"
				body_standing.overlays += human_image
				if (organHolder && organHolder.head)
					human_head_image.icon_state = "head"
					if (organHolder.head.donor_mutantrace)
						human_head_image.icon_state = "[organHolder.head.donor_mutantrace.icon_state]"
					else if (organHolder.head.donor_appearance && organHolder.head.donor_appearance.s_tone != skin_tone)
						var/h_skin_tone = organHolder.head.donor_appearance.s_tone
						human_head_image.color = rgb(h_skin_tone + 220, h_skin_tone + 220, h_skin_tone + 220)
					else
						human_head_image.color = rgb(skin_tone + 220, skin_tone + 220, skin_tone + 220)
					body_standing.overlays += human_head_image

			else
				human_decomp_image.icon_state = "body_decomp[decomp_stage]"
				body_standing.overlays += human_decomp_image

			if (limbs)
				for (var/name in update_body_limbs) // this is awful
					var/obj/item/parts/human_parts/limb = limbs.vars[name]
					if (limb)
						body_standing.overlays += limb.getMobIcon(0, decomp_stage)

						var/hand_icon_s = limb.getHandIconState(0, decomp_stage)

						var/part_icon_s = limb.getPartIconState(0, decomp_stage)

						if (limb.decomp_affected && decomp_stage)
							if (hand_icon_s)
								if (limb.skintoned)
									var/oldlayer = human_decomp_image.layer // ugh
									human_decomp_image.layer = MOB_HAND_LAYER1
									human_decomp_image.icon_state = hand_icon_s
									hands_standing.overlays += human_decomp_image
									human_decomp_image.layer = oldlayer
								else
									var/oldlayer = human_untoned_decomp_image.layer // ugh
									human_untoned_decomp_image.layer = MOB_HAND_LAYER1
									human_untoned_decomp_image.icon_state = hand_icon_s
									hands_standing.overlays += human_untoned_decomp_image
									human_untoned_decomp_image.layer = oldlayer


							if (part_icon_s)
								if (limb.skintoned)
									human_decomp_image.icon_state = part_icon_s
									body_standing.overlays += human_decomp_image
								else
									human_untoned_decomp_image.icon_state = part_icon_s
									body_standing.overlays += human_untoned_decomp_image
						else
							if (hand_icon_s)
								if (limb.skintoned)
									var/oldlayer = human_image.layer // ugh
									human_image.layer = MOB_HAND_LAYER1
									human_image.icon_state = hand_icon_s
									hands_standing.overlays += human_image
									human_image.layer = oldlayer
								else
									var/oldlayer = human_untoned_image.layer // ugh
									human_untoned_image.layer = MOB_HAND_LAYER1
									human_untoned_image.icon_state = hand_icon_s
									hands_standing.overlays += human_untoned_image
									human_untoned_image.layer = oldlayer

							if (part_icon_s)
								if (limb.skintoned)
									human_image.icon_state = part_icon_s
									body_standing.overlays += human_image
								else
									human_untoned_image.icon_state = part_icon_s
									body_standing.overlays += human_untoned_image
					else
						var/stump = update_body_limbs[name]
						if (decomp_stage)
							var/decomp = "_decomp[decomp_stage]"
							human_decomp_image.icon_state = "[stump][decomp]"
							body_standing.overlays += human_decomp_image
						else
							human_image.icon_state = "[stump]"
							body_standing.overlays += human_image

			human_image.color = "#fff"

			if (organHolder && organHolder.heart)
				if (organHolder.heart.robotic)
					heart_image.icon_state = "roboheart"
					body_standing.overlays += heart_image

				if (organHolder.heart.emagged)
					heart_emagged_image.layer = FLOAT_LAYER
					heart_emagged_image.icon_state = "roboheart_emagged"
					body_standing.overlays += heart_emagged_image

				if (organHolder.heart.synthetic)
					heart_image.icon_state = "synthheart"
					body_standing.overlays += heart_image

			if (bioHolder.mobAppearance.underwear && decomp_stage < 3)
				undies_image.icon_state = underwear_styles[bioHolder.mobAppearance.underwear]
				undies_image.color = hex2rgb(bioHolder.mobAppearance.u_color)
				body_standing.overlays += undies_image

			if (bandaged.len > 0)
				for (var/part in bandaged)
					bandage_image.icon_state = "bandage-[part]"
					body_standing.overlays += bandage_image

			if (spiders)
				spider_image.icon_state = "spiders"
				body_standing.overlays += spider_image

			if (juggling())
				juggle_image.icon_state = "juggle"
				body_standing.overlays += juggle_image

		else
			var/skin_tone = bioHolder ? bioHolder.mobAppearance.s_tone : 0
			human_image.color = rgb(skin_tone + 220, skin_tone + 220, skin_tone + 220)
			human_image.icon_state = "fatbody"
			body_standing.overlays += human_image
			human_image.color = "#fff"
	else
		body_standing.overlays += image(mutantrace.icon, mutantrace.icon_state, MOB_LIMB_LAYER)

	if (bioHolder)
		bioHolder.OnMobDraw()
	//Also forcing the updates since the overlays may have been modified on the images
	UpdateOverlays(body_standing, "body", 1, 1)
	UpdateOverlays(hands_standing, "hands", 1, 1)
	//if (damage_animation)
		//overlays += damage_animation


/mob/living/carbon/human/UpdateDamageIcon()
	
	if (lastDamageIconUpdate && !(world.time - lastDamageIconUpdate))
		return
		
	..()

	var/brute = get_brute_damage()
	var/burn = get_burn_damage()
	var/brute_state = 0
	var/burn_state = 0
	if (brute > 100)
		brute_state = 3
	else if (brute > 50)
		brute_state = 2
	else if (brute > 25)
		brute_state = 1

	if (burn > 100)
		burn_state = 3
	else if (burn > 50)
		burn_state = 2
	else if (burn > 25)
		burn_state = 1

	var/obj/item/organ/head/HO = organs["head"]
	var/head_damage = null
	if (HO && organHolder && organHolder.head)
		var/head_brute = min(3,round(HO.brute_dam/10))
		var/head_burn = min(3,round(HO.burn_dam/10))
		if (head_brute+head_burn > 0)
			head_damage = "head[head_brute][head_burn]"

	damage_standing = SafeGetOverlayImage("damage", 'icons/mob/dam_human.dmi',"[brute_state][burn_state]")// image('icons/mob/dam_human.dmi', "[brute_state][burn_state]", MOB_DAMAGE_LAYER)
	damage_standing.layer = MOB_DAMAGE_LAYER
	if (head_damage && organHolder && organHolder.head)
		head_damage_standing = SafeGetOverlayImage("head_damage", 'icons/mob/dam_human.dmi', head_damage, MOB_DAMAGE_LAYER) // image('icons/mob/dam_human.dmi', head_damage, MOB_DAMAGE_LAYER)
	else
		head_damage_standing = SafeGetOverlayImage("head_damage", 'icons/mob/dam_human.dmi', "00", MOB_DAMAGE_LAYER)//image('icons/mob/dam_human.dmi', "00", MOB_DAMAGE_LAYER)

	if (burn_state || brute_state)
		UpdateOverlays(damage_standing, "damage")
		UpdateOverlays(head_damage_standing, "head_damage")
	else
		UpdateOverlays(null, "damage",0,1)
		UpdateOverlays(null, "head_damage",0,1)

