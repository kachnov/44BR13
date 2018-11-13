////////////////// MISC BULLSHIT //////////////////

/mob/proc/fake_damage(var/amount,var/seconds)
	if (!amount || !seconds)
		return

	fakeloss += amount

	spawn (seconds * 10)
		fakeloss -= amount

/mob/proc/false_death(var/seconds)
	if (!seconds)
		return

	fakedead = 1
	boutput(src, "<strong>[src]</strong> seizes up and falls limp, [his_or_her(src)] eyes dead and lifeless...")
	weakened = 5

	spawn (seconds * 10)
		fakedead = 0
		weakened = 0

/proc/get_mobs_of_type_at_point_blank(var/atom/object,var/mob_path)
	var/list/returning_list = list()
	if (!object || !mob_path)
		return returning_list

	if (istype(object,/area))
		return returning_list

	for (var/mob/L in range(1,object))
		if (istype(L,mob_path))
			returning_list += L

	return returning_list

/proc/get_mobs_of_type_in_view(var/atom/object,var/mob_path)
	var/list/returning_list = list()
	if (!object || !mob_path)
		return returning_list

	if (istype(object,/area))
		return returning_list

	for (var/mob/L in view(7,object))
		if (istype(L,mob_path))
			returning_list += L

	return returning_list

/mob/proc/get_current_active_item()
	return null

/mob/living/carbon/human/get_current_active_item()
	if (hand)
		return r_hand
	else
		return l_hand

/mob/living/silicon/robot/get_current_active_item()
	return module_active

/mob/proc/get_temp_deviation()
	var/tempdiff = bodytemperature - base_body_temp
	var/tol = temp_tolerance
	var/ntl = 0 - temp_tolerance // these are just to make the switch a bit easier to look at

	if (tempdiff > tol*4)
		return 4 // some like to be on fire
	else if (tempdiff < ntl*4)
		return -4 // i think my ears just froze off oh god
	else if (tempdiff > tol*3)
		return 3 // some like it too hot
	else if (tempdiff < ntl*3)
		return -3 // too chill
	else if (tempdiff > tol*2)
		return 2 // some like it hot
	else if (tempdiff < ntl*2)
		return -2 // pretty chill
	else if (tempdiff > tol*1)
		return TRUE // some like it warm
	else if (tempdiff < ntl*1)
		return -1 // a little bit chill
	else
		return FALSE // I'M APOLLO JUSTICE AND I'M FINE

/mob/proc/is_cold_resistant()
	if (!src)
		return FALSE
	if (bioHolder && bioHolder.HasOneOfTheseEffects("cold_resist","thermal_resist"))
		return TRUE
	if (get_ability_holder(/abilityHolder/changeling))
		return TRUE
	if (nodamage)
		return TRUE
	return FALSE

/mob/proc/is_heat_resistant()
	if (!src)
		return FALSE
	if (bioHolder && bioHolder.HasOneOfTheseEffects("fire_resist","thermal_resist"))
		return TRUE
	if (nodamage)
		return TRUE
	return FALSE

// Hallucinations

/mob/living/proc/hallucinate_fake_melee_attack()
	var/list/PB_mobs = get_mobs_of_type_at_point_blank(src,/mob/living/)
	var/mob/living/H = pick(PB_mobs)
	if (H.stat)
		return
	var/obj/item/I = H.get_current_active_item()

	if (istype(I))
		boutput(src, "<span style=\"color:red\"><strong>[H.name] attacks [name] with [I]!</strong></span>")
		if (I.hitsound)
			playsound_local(loc, I.hitsound, 50, 1)
		fake_damage(I.force,100)
	else
		if (!istype(H,/mob/living/carbon/human))
			return
		if (!canmove)
			playsound_local(loc, 'sound/weapons/genhit1.ogg', 25, 1, -1)
			boutput(src, "<span style=\"color:red\"><strong>[H.name] kicks [name]!</strong></span>")
		else
			var/list/punches = list('sound/weapons/punch1.ogg','sound/weapons/punch2.ogg','sound/weapons/punch3.ogg','sound/weapons/punch4.ogg')
			playsound_local(loc, pick(punches), 25, 1, -1)
			boutput(src, "<span style=\"color:red\"><strong>[H.name] punches [name]!</strong></span>")
		fake_damage(rand(2,9),100)
	hit_twitch()

///////////////
// Anomalies //
///////////////

/obj/anomaly
	name = "anomaly"
	desc = "swirly thing alert!!!!"
	icon = 'icons/obj/objects.dmi'
	icon_state = "anom"
	density = 1
	opacity = 0
	anchored = 1
	var/has_processing_loop = 0

	New()
		..()
		if (has_processing_loop)
			global.processing_items.Add(src)
		return FALSE

	proc/process()
		return FALSE

/obj/anomaly/test
	name = "boing anomaly"
	desc = "it goes boing and does stuff"
	has_processing_loop = 1

	process()
		playsound(loc, 'sound/effects/chanting.ogg', 100, 0, 5, 0.5)