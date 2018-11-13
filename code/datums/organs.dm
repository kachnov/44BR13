/*
/organ
	var/name = "organ"
	var/mob/owner = null
	var/organ_id = "organ"
	var/brute_dam = 0
	var/burn_dam = 0
	var/tox_dam = 0

/organ/proc/process()
	return

// could probably use this with reagents
//organ/proc/receive_chem(reagent/R)
//	return

/organ/proc/take_damage(brute, burn, tox, disallow_limb_loss)
	if (brute <= 0 && burn <= 0 && tox <= 0)
		return FALSE
	brute_dam += brute
	burn_dam += burn
	tox_dam += tox

	if (ismob(owner))
		var/mob/M = owner
		M.hit_twitch()
		M.UpdateDamage()
	return TRUE

/organ/proc/heal_damage(brute, burn, tox)
	if (brute_dam <= 0 && burn_dam <= 0 && tox_dam <= 0)
		return FALSE
	brute_dam = max(0, brute_dam - brute)
	burn_dam = max(0, burn_dam - burn)
	tox_dam = max(0, tox_dam - tox)
	return TRUE

/organ/proc/get_damage()	//returns total damage
	return brute_dam + burn_dam	+ tox_dam //could use health?

/obj/item/organ
	name = "external"
	organ_id = "organ"
	var/icon_name = null
	var/bone/bones = null

	New()
		..()
		if (owner)
			bones = new /bone(src)
			bones.donor = owner

	take_damage(brute, burn, tox, disallow_limb_loss)
		. = ..()
		if (bones && brute > 30 && prob(brute - 30))
			bones.take_damage()

/obj/item/organ/chest
	name = "chest"
	icon_name = "chest"
	organ_id = "chest"

/obj/item/organ/head
	name = "head"
	icon_name = "head"
	organ_id = "head"

/obj/item/organ/limb
	name = "limb"
	organ_id = "limb"
	var/obj/item/parts/limb_item = null

	take_damage(brute, burn, tox, disallow_limb_loss)
		. = ..()
		if (brute > 30 && prob(brute - 30) && !disallow_limb_loss)
			if (ishuman(owner) && istype(limb_item))
				limb_item.sever()

/obj/item/organ/limb/l_arm
	name = "left arm"
	icon_name = "l_arm"
	organ_id = "l_arm"

	New()
		..()
		if (ishuman(owner))
			var/mob/living/carbon/human/H = owner
			if (H.limbs && H.limbs.l_arm)
				limb_item = H.limbs.l_arm

/obj/item/organ/limb/l_leg
	name = "left leg"
	icon_name = "l_leg"
	organ_id = "l_leg"

	New()
		..()
		if (ishuman(owner))
			var/mob/living/carbon/human/H = owner
			if (H.limbs && H.limbs.l_leg)
				limb_item = H.limbs.l_leg

/obj/item/organ/limb/r_arm
	name = "right arm"
	icon_name = "r_arm"
	organ_id = "r_arm"

	New()
		..()
		if (ishuman(owner))
			var/mob/living/carbon/human/H = owner
			if (H.limbs && H.limbs.r_arm)
				limb_item = H.limbs.r_arm

/obj/item/organ/limb/r_leg
	name = "right leg"
	icon_name = "r_leg"
	organ_id = "r_leg"

	New()
		..()
		if (ishuman(owner))
			var/mob/living/carbon/human/H = owner
			if (H.limbs && H.limbs.r_leg)
				limb_item = H.limbs.r_leg

/organ/internal
	name = "internal"

/organ/internal/brain
	name = "brain"
	organ_id = "brain"

/organ/internal/heart
	name = "heart"
	organ_id = "heart"

/organ/internal/lungs
	name = "lungs"
	organ_id = "lungs"

/organ/internal/stomach
	name = "stomach"
	organ_id = "stomach"

/organ/internal/liver
	name = "liver"
	organ_id = "liver"

/organ/internal/intestines
	name = "intestines"
	organ_id = "intestines"
*/