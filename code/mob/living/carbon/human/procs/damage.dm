
/mob/living/carbon/human/bullet_act(var/obj/projectile/P)

	log_shot(P,src)
	
	if (isliving(P.shooter))

		// stupid stuff
		var/mob/living/M = P.shooter
		if (P.name != "energy bolt" && M && M.mind)
			M.mind.violated_hippocratic_oath = 1

		// anti-FF mechanic
		if (ishuman(P.shooter))
			var/mob/living/carbon/human/S = P.shooter

			var/S_faction = null 
			var/src_faction = null

			if (S.job)
				var/job/S_job = find_job_in_controller_by_string(S.job)
				S_faction = S_job.faction

			if (job)
				var/job/src_job = find_job_in_controller_by_string(job)
				src_faction = src_job.faction 

			// see projectile_parent.dm for why we return -1
			if (S_faction && src_faction && S_faction == src_faction)
				return -1
			else if (isxenomorph(S) && isxenomorph(src))
				return -1
			else if (ismutt(S) && ismutt(src))
				return -1

	if (nodamage) return
	if (spellshield)
		visible_message("<span style=\"color:red\">[src]'s shield deflects the shot!</span>")
		return
	for (var/obj/item/device/shield/S in src)
		if (S.active)
			if (P.proj_data.damage_type == D_KINETIC)
				visible_message("<span style=\"color:red\">[src]'s shield deflects the shot!</span>")
				return
			S.active = 0
			S.icon_state = "shield0"

	if (material) material.triggerOnAttacked(src, P.shooter, src, (ismob(P.shooter) ? P.shooter:equipped() : P.shooter))
	for (var/atom/A in src)
		if (A.material)
			A.material.triggerOnAttacked(A, P.shooter, src, (ismob(P.shooter) ? P.shooter:equipped() : P.shooter))

	if (!P.proj_data)
		return

	if (locate(/obj/item/grab, src))
		var/mob/hostage = null
		var/obj/item/grab/G = find_in_hands(/obj/item/grab)
		if (G && G.affecting && G.state >= 2)
			hostage = G.affecting
			if (prob(10)) //This should probably not be bulletproof, har har
				hostage.visible_message("<span class='combat bold'>[hostage] is knocked out of [src]'s grip by the force of the shot!</span>")
				qdel(G)
		if (hostage)
			hostage.bullet_act(P)
			return hostage
	if (!P.proj_data.silentshot)
		visible_message("<span style=\"color:red\">[src] is hit by the [P.name]!</span>", "<span style=\"color:red\">You are hit by the [P.name]!</span>")

	for (var/mob/V in viewers(world.view, src))
		if (prob(8) && V.traitHolder && V.traitHolder.hasTrait("nervous"))
			if (src != V)
				V.emote("scream")
				V.stunned += 3

// ahhhh fuck this im just making every shot be a chest shot for now -drsingh

	var/damage = 0
	damage = round((P.power*P.proj_data.ks_ratio), 1.0)
	var/stun = 0
	stun = round((P.power*(1.0-P.proj_data.ks_ratio)), 1.0)
	var/armor_value_bullet = 1

	if (wear_suit)
		var/obj/item/clothing/suit/S = wear_suit
		if (S.armor_value_bullet)
			armor_value_bullet = S.armor_value_bullet

	switch(P.proj_data.damage_type)
		if (D_KINETIC)
			remove_stamina(min(round(stun/armor_value_bullet) * 30, 125)) //thanks to the odd scaling i have to cap this.
			stamina_stun()

			if (wear_suit && armor_value_bullet > 1)
				show_message("<span style=\"color:red\">Your [wear_suit] softens the hit!</span>", 4)
				TakeDamage("chest", (damage/armor_value_bullet), 0, 0, DAMAGE_BLUNT)
			else
				TakeDamage("chest", damage, 0, 0, DAMAGE_BLUNT)
				set_clothing_icon_dirty()
//				take_bleeding_damage(src, damage, DAMAGE_BLUNT) // im haine

			if (stat==0) lastgasp()

			if (wear_suit && armor_value_bullet >= 2)
				return

			else

				if (P.implanted)
					if (istext(P.implanted))
						P.implanted = text2path(P.implanted)
						if (!P.implanted)
							return
					var/obj/item/implant/projectile/implanted
					if (ispath(P.implanted))
						implanted = new P.implanted
					else
						implanted = P.implanted
					implanted.set_loc(src)
					if (istype(implanted))
						implanted.owner = src
						if (P.forensic_ID)
							implanted.forensic_ID = P.forensic_ID
						implant += implanted
						if (P.proj_data.material)
							implanted.setMaterial(P.proj_data.material)
						implanted.implanted(src, null, 60)
						//implanted.implanted(src, null, min(20, max(0, round(damage / 10) ) ))
		if (D_PIERCING)
			remove_stamina(min(round(stun/armor_value_bullet) * 30, 125)) //thanks to the odd scaling i have to cap this.
			stamina_stun()

			//bleed
			if (wear_suit && armor_value_bullet > 1)
				show_message("<span style=\"color:red\">[P] pierces through your [wear_suit]!</span>", 4)
				TakeDamage("chest", damage/max((armor_value_bullet/3), 1), 0, 0, DAMAGE_STAB)

			else
				TakeDamage("chest", damage / 2, 0, 0, DAMAGE_STAB)

//			take_bleeding_damage(src, damage, DAMAGE_STAB) // im stupid

			if (stat==0) lastgasp()

			if (P.implanted)
				if (istext(P.implanted))
					P.implanted = text2path(P.implanted)
					if (!P.implanted)
						return
				var/obj/item/implant/projectile/implanted
				if (ispath(P.implanted))
					implanted = new P.implanted
				else
					implanted = P.implanted
				implanted.set_loc(src)
				if (istype(implanted))
					implanted.owner = src
					implant += implanted
					if (P.forensic_ID)
						implanted.forensic_ID = P.forensic_ID
					if (P.proj_data.material)
						implanted.setMaterial(P.proj_data.material)
					implanted.implanted(src, null, 100)
					//implanted.implanted(src, null, min(20, max(0, round(damage / 10) ) ))

		if (D_SLASHING)
			remove_stamina(min(round(stun/armor_value_bullet) * 30, 125)) //thanks to the odd scaling i have to cap this.
			stamina_stun()
			//bleed
			if (wear_suit && armor_value_bullet > 1)
				show_message("<span style=\"color:red\">Your [wear_suit] softens the hit!</span>", 4)
				TakeDamage("chest", (damage/armor_value_bullet), 0, 0, DAMAGE_BLUNT)
			else
				TakeDamage("chest", (damage*2), 0, 0, DAMAGE_CUT)
//				take_bleeding_damage(src, damage, DAMAGE_CUT) // im coder

		if (D_ENERGY)

			remove_stamina(min(round(stun/armor_value_bullet) * 30, 125)) //thanks to the odd scaling i have to cap this.
			stamina_stun()

			if (stat==0) lastgasp()
			if (stat!=2) stat = 1

			//set_clothing_icon_dirty()

			if (stuttering < stun)
				stuttering = stun

			if (wear_suit && armor_value_bullet > 1)
				show_message("<span style=\"color:red\">Your [wear_suit] softens the hit!</span>", 4)
				TakeDamage("chest", 0, (damage/armor_value_bullet), 0, DAMAGE_BURN)

			else
				TakeDamage("chest", 0, damage, 0, DAMAGE_BURN)

		if (D_BURNING)
			remove_stamina(min(round(stun/armor_value_bullet) * 30, 125)) //thanks to the odd scaling i have to cap this.
			stamina_stun()

			if (is_heat_resistant())
				// fire resistance should probably not let you get hurt by welders
				visible_message("<span style=\"color:red\"><strong>[src] seems unaffected by fire!</strong></span>")
				return

			if (wear_suit && armor_value_bullet > 1)
				show_message("<span style=\"color:red\">Your [wear_suit] softens the hit!</span>", 4)
				TakeDamage("chest", 0, (damage/armor_value_bullet), 0, DAMAGE_BURN)
				update_burning(damage/armor_value_bullet)
			else
				TakeDamage("chest", 0, damage, 0, DAMAGE_BURN)
				update_burning(damage)

		if (D_RADIOACTIVE)
			remove_stamina(min(round(stun/armor_value_bullet) * 30, 125)) //thanks to the odd scaling i have to cap this.

			irradiate(damage)
			if (add_stam_mod_regen("projectile", -5))
				spawn (300)
					remove_stam_mod_regen("projectile")

			stamina_stun()

		if (D_TOXIC)
			remove_stamina(min(round(stun/armor_value_bullet) * 30, 125)) //thanks to the odd scaling i have to cap this.
			stamina_stun()

			if (P.proj_data.reagent_payload)
				if (wear_suit && armor_value_bullet > 1)
					show_message("<span style=\"color:red\">Your [wear_suit] softens the hit!</span>", 4)
					TakeDamage("chest", (damage/armor_value_bullet), 0, 0, DAMAGE_STAB)
				else
					TakeDamage("chest", damage, 0, 0, DAMAGE_STAB)

				if (stat==0) lastgasp()

				if (P.implanted)
					if (istext(P.implanted))
						P.implanted = text2path(P.implanted)
						if (!P.implanted)
							return
					var/obj/item/implant/projectile/implanted = new P.implanted
					implanted.set_loc(src)
					if (istype(implanted))
						implanted.owner = src
						implant += implanted
						implanted.setMaterial(P.proj_data.material)
						implanted.implanted(src, null, 0)
					reagents.add_reagent(P.proj_data.reagent_payload, 15/armor_value_bullet)

			else
				take_toxin_damage(damage)

	if (ismob(P.shooter))
		if (P.shooter)
			lastattacker = P.shooter
			lastattackertime = world.time

	return


/mob/living/carbon/human/ex_act(severity)
	..() // Logs.
	if (nodamage) return
	// there used to be mining radiation check here which increases severity by one
	// this needs to be derived from material properties instead and is disabled for now
	flash(30)

	if (stat == 2 && client)
		spawn (1)
			gib(1)
		return

	else if (stat == 2 && !client)
		var/list/virus = ailments

		var/bdna = null // For forensics (Convair880).
		var/btype = null
		if (bioHolder.Uid && bioHolder.bloodType)
			bdna = bioHolder.Uid
			btype = bioHolder.bloodType
		gibs(loc, virus, null, bdna, btype)

		qdel(src)
		return

	var/shielded = 0
	var/spellshielded = 0
	for (var/obj/item/device/shield/S in src)
		if (S.active)
			shielded = 1
			break

	var/reduction = 0
	if (energy_shield) reduction = energy_shield.protect()
	if (spellshield)
		reduction += 30
		spellshielded = 1
		boutput(src, "<span style=\"color:red\"><strong>Your Spell Shield absorbs some blast!</strong></span>")
	if (wear_suit && istype(wear_suit, /obj/item/clothing/suit/armor/EOD))
		reduction += rand(10,40)
		severity++ // let's make this function like mining armor
		boutput(src, "<span style=\"color:red\"><strong>Your armor absorbs some of the blast!</span>")
		if (head && istype(head, /obj/item/clothing/head/helmet/EOD))
			reduction += rand(5,20) // buffed a bit - cogwerks
			severity++
	else if (wear_suit && wear_suit.armor_value_explosion)
		var/sevmod = max(0,round(wear_suit.armor_value_explosion / 4))
		severity += sevmod
		reduction = rand(wear_suit.armor_value_explosion, wear_suit.armor_value_explosion * 4)
		boutput(src, "<span style=\"color:red\"><strong>Your armor absorbs some of the blast!</span>")
	else if (w_uniform && w_uniform.armor_value_explosion)
		var/sevmod = max(0,round(w_uniform.armor_value_explosion / 4))
		severity += sevmod
		reduction = rand(w_uniform.armor_value_explosion, w_uniform.armor_value_explosion * 4)
		boutput(src, "<span style=\"color:red\"><strong>Your jumpsuit absorbs some of the blast!</span>")

	var/b_loss = null
	var/f_loss = null

	if (spellshielded)
		severity++

	switch (severity)
		if (1.0)
			b_loss += max(500 - reduction, 0)
			spawn (1)
				gib(1)
			return

		if (2.0)
			if (!shielded)
				b_loss += max(60 - reduction, 0)

			f_loss += max(60 - reduction, 0)
			apply_sonic_stun(0, 0, 0, 0, 0, 30, 30)

			var/curprob = 30

			if (traitHolder && traitHolder.hasTrait("explolimbs"))
				curprob = round(curprob / 2)

			for (var/limb in list("l_arm","r_arm","l_leg","r_leg"))
				if (prob(curprob))
					sever_limb(limb)
					curprob -= 20 // let's not get too crazy

		if (3.0)
			b_loss += max(30 - reduction, 0)
			if (prob(50) && !shielded && !reduction)
				paralysis += 7

			apply_sonic_stun(0, 0, 0, 0, 0, 15, 15)
			var/curprob = 10

			if (traitHolder && traitHolder.hasTrait("explolimbs"))
				curprob = round(curprob / 2)

			for (var/limb in list("l_arm","r_arm","l_leg","r_leg"))
				if (prob(curprob))
					sever_limb(limb)
					curprob -= 10 // let's not get too crazy

		if (4.0 to INFINITY)
			boutput(src, "<span style=\"color:red\"><strong>Your armor shields you from the blast!</strong></span>")

	TakeDamage(zone="All", brute=b_loss, burn=f_loss, tox=0, damage_type=0, disallow_limb_loss=1)

	/*
	for (var/organ in organs)
		var/obj/item/temp = organs["[organ]"]
		if (istype(temp, /obj/item))
			switch(temp.name)
				if ("head")
					temp.take_damage(b_loss * 0.2, f_loss * 0.2)
				if ("chest")
					temp.take_damage(b_loss * 0.4, f_loss * 0.4)
				if ("l_arm")
					temp.take_damage(b_loss * 0.05, f_loss * 0.05)
				if ("r_arm")
					temp.take_damage(b_loss * 0.05, f_loss * 0.05)
				if ("l_leg")
					temp.take_damage(b_loss * 0.05, f_loss * 0.05)
				if ("r_leg")
					temp.take_damage(b_loss * 0.05, f_loss * 0.05)
	*/
	UpdateDamageIcon()

/mob/living/carbon/human/blob_act(var/power)
	logTheThing("combat", src, null, "is hit by a blob")
	if (stat == 2 || nodamage)
		return
	var/shielded = 0
	for (var/obj/item/device/shield/S in src)
		if (S.active)
			shielded = 1
	if (spellshield)
		shielded = 1

	var/modifier = power / 20
	var/damage = null
	if (stat != 2)
		damage = rand(modifier, 12 + 8 * modifier)

	if (shielded)
		damage /= 4

		//paralysis += 1

	show_message("<span style=\"color:red\">The blob attacks you!</span>")

	if (spellshield)
		boutput(src, "<span style=\"color:red\"><strong>Your Spell Shield absorbs some damage!</strong></span>")

	var/list/zones = list("head", "chest", "l_arm", "r_arm", "l_leg", "r_leg")

	var/zone = pick(zones)

	var/obj/item/temp = organs[zone]

	switch(zone)
		if ("head")
			if ((((head && head.body_parts_covered & HEAD) || (wear_mask && wear_mask.body_parts_covered & HEAD)) && prob(99)))
				if (prob(45))
					temp.take_damage(damage, 0)
				else
					show_message("<span style=\"color:red\">You have been protected from a hit to the head.</span>")
				return
			if (damage > 4.9)
				if (weakened < 10)
					weakened = rand(10, 15)
				for (var/mob/O in viewers(src, null))
					O.show_message("<span style=\"color:red\"><strong>The blob has weakened [src]!</strong></span>", 1, "<span style=\"color:red\">You hear someone fall.</span>", 2)
			temp.take_damage(damage, 0)
		if ("chest")
			if ((((wear_suit && wear_suit.body_parts_covered & TORSO) || (w_uniform && w_uniform.body_parts_covered & TORSO)) && prob(70)))
				show_message("<span style=\"color:red\">You have been protected from a hit to the chest.</span>")
				return
			if (damage > 4.9)
				if (prob(50))
					if (weakened < 5)
						weakened = 5
					for (var/mob/O in viewers(src, null))
						O.show_message("<span style=\"color:red\"><strong>The blob has knocked down [src]!</strong></span>", 1, "<span style=\"color:red\">You hear someone fall.</span>", 2)
				else
					if (stunned < 5)
						stunned = 5
					for (var/mob/O in viewers(src, null))
						if (O.client)	O.show_message("<span style=\"color:red\"><strong>The blob has stunned [src]!</strong></span>", 1)
				if (stat == 0)
					sleep(0)
					lastgasp() // calling lastgasp() here because we just got knocked out
				if (stat != 2)	stat = 1
			temp.take_damage(damage, 0)

		if ("l_arm")
			temp.take_damage(damage, 0)
			if (prob(20) && equipped())
				visible_message("<span style=\"color:red\"><strong>The blob has knocked [equipped()] out of [src]'s hand!</strong></span>")
				drop_item()
		if ("r_arm")
			temp.take_damage(damage, 0)
			if (prob(20) && equipped())
				visible_message("<span style=\"color:red\"><strong>The blob has knocked [equipped()] out of [src]'s hand!</strong></span>")
				drop_item()
		if ("l_leg")
			temp.take_damage(damage, 0)
			if (prob(5))
				visible_message("<span style=\"color:red\"><strong>The blob has knocked [src] off-balance!</strong></span>")
				drop_item()
				if (prob(50))
					weakened = max(weakened, 1)
		if ("r_leg")
			temp.take_damage(damage, 0)
			if (prob(5))
				visible_message("<span style=\"color:red\"><strong>The blob has knocked [src] off-balance!</strong></span>")
				drop_item()
				if (prob(50))
					weakened = max(weakened, 1)

	UpdateDamageIcon()
	return

/mob/living/carbon/human/TakeDamage(zone, brute, burn, tox, damage_type, disallow_limb_loss)
	if (nodamage) return

	if (traitHolder && traitHolder.hasTrait("deathwish"))
		brute *= 2
		burn *= 2
		//tox *= 2

	if (mutantrace)
		brute *= mutantrace.brutevuln
		burn *= mutantrace.firevuln

	if (is_heat_resistant())
		burn = 0

	//if (bioHolder && bioHolder.HasEffect("resist_toxic"))
		//tox = 0

	brute = max(0, brute)
	burn = max(0, burn)
	//tox = max(0, burn)

	if (brute + burn + tox <= 0) return

	if (is_heat_resistant())
		burn = 0 //mostly covered by individual procs that cause burn damage, but just in case

	if (zone == "All")
		var/organCount = 0
		for (var/organName in organs)
			var/obj/item/extOrgan = organs["[organName]"]
			if (istype(extOrgan))
				organCount++
		if (!organCount)
			return
		brute = brute / organCount
		burn = burn / organCount
		var/update = 0
		for (var/organName in organs)
			var/obj/item/extOrgan = organs["[organName]"]
			if (istype(extOrgan))
				if (extOrgan.take_damage(brute, burn, 0/*tox*/, damage_type))
					update = 1

		if (update)
			UpdateDamageIcon()
			UpdateDamage()
	else
		var/obj/item/E = organs[zone]
		if (istype(E, /obj/item))
			if (E.take_damage(brute, burn, 0/*tox*/, damage_type))
				UpdateDamageIcon()
				UpdateDamage()
			hit_twitch()
		else
			return FALSE
		return

/mob/living/carbon/human/TakeDamageAccountArmor(zone, brute, burn, tox, damage_type)
	var/armor_mod = 0
	var/z_name = zone
	var/a_zone = zone
	if (a_zone in list("l_leg", "r_arm", "l_leg", "r_leg"))
		a_zone = "chest"
	switch (a_zone)
		if ("head")
			armor_mod = get_head_armor_modifier()
		if ("chest")
			armor_mod = get_chest_armor_modifier()

	switch (zone)
		if ("l_arm")
			z_name = "left arm"
		if ("r_arm")
			z_name = "right arm"
		if ("l_leg")
			z_name = "left leg"
		if ("r_leg")
			z_name = "right leg"

	brute = max(0, brute - armor_mod)
	burn = max(0, burn - armor_mod)
	if (brute + burn == 0)
		show_message("<span style='color:blue'>You have been completely protected from damage on your [z_name]!</span>")
	else if (armor_mod != 0)
		show_message("<span style='color:blue'>You have been partly protected from damage on your [z_name]!</span>")
	TakeDamage(zone, max(brute, 0), max(burn, 0), 0, damage_type)

/mob/living/carbon/human/HealDamage(zone, brute, burn, tox)
	if (zone == "All")
		var/bruteOrganCount = 0 	//How many organs have brute damage?
		var/burnOrganCount = 0		//How many organs have burn damage?
		var/toxOrganCount = 0		// gurbage

		//Let's find out
		for (var/organName in organs)
			var/obj/item/extOrgan = organs["[organName]"]
			if (istype(extOrgan, /obj/item/organ))
				var/obj/item/organ/O = extOrgan
				if (O.brute_dam > 0)
					bruteOrganCount ++
				if (O.burn_dam > 0)
					burnOrganCount ++
				if (O.tox_dam > 0)
					toxOrganCount ++
			else if (istype(extOrgan, /obj/item/parts))
				var/obj/item/parts/O = extOrgan
				if (O.brute_dam > 0)
					bruteOrganCount ++
				if (O.burn_dam > 0)
					burnOrganCount ++
				if (O.tox_dam > 0)
					toxOrganCount ++

		if (!bruteOrganCount && !burnOrganCount && !toxOrganCount) //No damage
			return

		//This is ugly, but necessary
		if (bruteOrganCount > 0)
			brute = brute / bruteOrganCount
		else
			brute = 0

		if (burnOrganCount > 0)
			burn = burn / burnOrganCount
		else
			burn = 0

		if (toxOrganCount > 0)
			tox = tox / toxOrganCount
		else
			tox = 0


		var/update = 0
		for (var/organName in organs)
			var/obj/item/extOrgan = organs["[organName]"]
			if (istype(extOrgan, /obj/item/organ))
				var/obj/item/organ/O = extOrgan
				if ((O.brute_dam > 0 && brute > 0) || (O.burn_dam > 0 && burn > 0) || (O.tox_dam > 0 && tox > 0))
					if (O.heal_damage(brute, burn, tox))
						update = 1
			else if (istype(extOrgan, /obj/item/parts))
				var/obj/item/parts/O = extOrgan
				if ((O.brute_dam > 0 && brute > 0) || (O.burn_dam > 0 && burn > 0) || (O.tox_dam > 0 && tox > 0))
					if (O.heal_damage(brute, burn, tox))
						update = 1

		if (update)
			UpdateDamageIcon()
			UpdateDamage()
		return TRUE
	else
		var/obj/item/E = organs["[zone]"]
		if (istype(E, /obj/item))
			if (E.heal_damage(brute, burn, tox))
				UpdateDamageIcon()
				UpdateDamage()
				return TRUE
		else
			return FALSE
	return

/mob/living/carbon/human/take_eye_damage(var/amount, var/tempblind = 0, var/side)
	if (!src || !ishuman(src) || (!isnum(amount) || amount == 0))
		return FALSE

	var/eyeblind = 0
	if (tempblind == 0)
		if (organHolder)
			var/organHolder/O = organHolder
			if (side == "right")
				if (O.right_eye)
					O.right_eye.brute_dam = max(0, O.right_eye.brute_dam + amount)
			else if (side == "left")
				if (O.left_eye)
					O.left_eye.brute_dam = max(0, O.left_eye.brute_dam + amount)
			else
				if (O.right_eye && O.left_eye)
					O.right_eye.brute_dam = max(0, O.right_eye.brute_dam + (amount/2))
					O.left_eye.brute_dam = max(0, O.left_eye.brute_dam + (amount/2))
				else if (O.right_eye)
					O.right_eye.brute_dam = max(0, O.right_eye.brute_dam + amount)
				else if (O.left_eye)
					O.left_eye.brute_dam = max(0, O.left_eye.brute_dam + amount)
		else
			eye_damage = max(0, eye_damage + amount)
	else
		eyeblind = amount

	// Modify eye_damage or eye_blind if prompted, but don't perform more than we absolutely have to.
	var/blind_bypass = 0
	if (bioHolder && bioHolder.HasEffect("blind"))
		blind_bypass = 1

	if (amount > 0 && tempblind == 0 && blind_bypass == 0) // so we don't enter the damage switch thing if we're healing damage
		var/eye_dam = get_eye_damage()
		switch (eye_dam)
			if (10 to 12)
				change_eye_blurry(rand(3,6))

			if (12 to 15)
				show_text("Your eyes hurt.", "red")
				change_eye_blurry(rand(6,9))

			if (15 to 25)
				show_text("Your eyes are really starting to hurt.", "red")
				change_eye_blurry(rand(12,16))

				if (prob(eye_dam - 15 + 1))
					show_text("Your eyes are badly damaged!", "red")
					eyeblind = 5
					change_eye_blurry(5)
					bioHolder.AddEffect("bad_eyesight")
					spawn (100)
						bioHolder.RemoveEffect("bad_eyesight")

			if (25 to INFINITY)
				show_text("<strong>Your eyes hurt something fierce!</strong>", "red")

				if (prob(eye_dam - 25 + 1))
					show_text("You go blind!", "red")
					bioHolder.AddEffect("blind")
				else
					change_eye_blurry(rand(12,16))

	if (eyeblind != 0)
		eye_blind = max(0, eye_blind + eyeblind)

	//DEBUG("Eye damage applied: [amount]. Tempblind: [tempblind == 0 ? "N" : "Y"]")
	return TRUE

/mob/living/carbon/human/get_brute_damage()
	var/brute = 0
	for (var/organName in organs)
		var/obj/item/externalOrgan = organs["[organName]"]
		if (istype(externalOrgan, /obj/item/organ))
			var/obj/item/organ/O = externalOrgan
			brute += O.brute_dam
		else if (istype(externalOrgan, /obj/item/parts))
			var/obj/item/parts/O = externalOrgan
			brute += O.brute_dam
	return brute

/mob/living/carbon/human/get_burn_damage()
	var/burn = 0
	for (var/organName in organs)
		var/obj/item/externalOrgan = organs["[organName]"]
		if (istype(externalOrgan, /obj/item/organ))
			var/obj/item/organ/O = externalOrgan
			burn += O.burn_dam
		else if (istype(externalOrgan, /obj/item/parts))
			var/obj/item/parts/O = externalOrgan
			burn += O.burn_dam
	return burn

/mob/living/carbon/human/get_toxin_damage()
	var/tox = toxloss
	for (var/organName in organs)
		var/obj/item/externalOrgan = organs["[organName]"]
		if (istype(externalOrgan, /obj/item/organ))
			var/obj/item/organ/O = externalOrgan
			tox += O.tox_dam
		else if (istype(externalOrgan, /obj/item/parts))
			var/obj/item/parts/O = externalOrgan
			tox += O.tox_dam
	return tox

/mob/living/carbon/human/get_eye_damage(var/tempblind = 0, var/side)
	if (tempblind == 0)
		var/eye_dam = 0
		if (organHolder)
			var/organHolder/O = organHolder
			if (O.right_eye && side != "left")
				eye_dam += O.right_eye.brute_dam + O.right_eye.burn_dam + O.right_eye.tox_dam
			if (O.left_eye && side != "right")
				eye_dam += O.left_eye.brute_dam + O.left_eye.burn_dam + O.left_eye.tox_dam
		else
			eye_dam = eye_damage

		return eye_dam
	else
		return eye_blind