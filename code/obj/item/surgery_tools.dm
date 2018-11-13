/*
CONTAINS:
SCALPEL
CIRCULAR SAW
STAPLE GUN
DEFIBRILLATOR
SUTURE
BANDAGE
BLOOD BAG (unused)
BODY BAG
*/

/* ================================================= */
/* -------------------- Scalpel -------------------- */
/* ================================================= */

/obj/item/scalpel
	name = "scalpel"
	desc = "A surgeon's tool, used to cut precisely into a subject's body."
	icon = 'icons/obj/surgery.dmi'
	icon_state = "scalpel1"
	inhand_image_icon = 'icons/mob/inhand/hand_medical.dmi'
	item_state = "scalpel"
	flags = FPRINT | TABLEPASS | CONDUCT
	hit_type = DAMAGE_CUT
	hitsound = 'sound/weapons/slashcut.ogg'
	force = 3.0
	w_class = 1.0
	throwforce = 5.0
	throw_speed = 3
	throw_range = 5
	m_amt = 10000
	g_amt = 5000
	stamina_damage = 5
	stamina_cost = 5
	stamina_crit_chance = 35
	var/mob/Poisoner = null
	module_research = list("tools" = 3, "medicine" = 3, "weapons" = 0.25)

	New()
		..()
		if (icon_state == "scalpel1")
			icon_state = pick("scalpel1", "scalpel2")
		create_reagents(5)

	attack(mob/living/carbon/M as mob, mob/user as mob)
		if (reagents && reagents.total_volume)
			logTheThing("combat", user, M, "used [src] on %target% (<strong>Intent</strong>: <em>[user.a_intent]</em>) (<strong>Targeting</strong>: <em>[user.zone_sel.selecting]</em>) [log_reagents(src)]")
			reagents.trans_to(M,5)
		else
			logTheThing("combat", user, M, "used [src] on %target% (<strong>Intent</strong>: <em>[user.a_intent]</em>) (<strong>Targeting</strong>: <em>[user.zone_sel.selecting]</em>)")
		if (!scalpel_surgery(M, user))
			return ..()
		else return

	suicide(var/mob/user as mob)
		user.visible_message("<span style=\"color:red\"><strong>[user] slashes \his own throat with [src]!</strong></span>")
		blood_slash(user, 25)
		playsound(user.loc, hitsound, 50, 1)
		user.TakeDamage("head", 150, 0)
		user.updatehealth()
		spawn (100)
			if (user)
				user.suiciding = 0
		return TRUE

/obj/item/scalpel/vr
	icon = 'icons/effects/VR.dmi'
	icon_state = "scalpel"

/* ====================================================== */
/* -------------------- Circular Saw -------------------- */
/* ====================================================== */

/obj/item/circular_saw
	name = "circular saw"
	desc = "A saw used to cut bone with precision."
	icon = 'icons/obj/surgery.dmi'
	icon_state = "saw1"
	inhand_image_icon = 'icons/mob/inhand/hand_medical.dmi'
	item_state = "saw1"
	flags = FPRINT | TABLEPASS | CONDUCT
	hit_type = DAMAGE_CUT
	hitsound = 'sound/weapons/slashcut.ogg'
	force = 3
	w_class = 1.0
	throwforce = 3.0
	throw_speed = 3
	throw_range = 5
	m_amt = 20000
	g_amt = 10000
	stamina_damage = 5
	stamina_cost = 5
	stamina_crit_chance = 35
	var/mob/Poisoner = null
	module_research = list("tools" = 3, "medicine" = 3, "weapons" = 0.25)

	New()
		..()
		if (icon_state == "saw1")
			icon_state = pick("saw1", "saw2", "saw3")
		create_reagents(5)

	attack(mob/living/carbon/M as mob, mob/user as mob)
		if (reagents && reagents.total_volume)
			logTheThing("combat", user, M, "used [src] on %target% (<strong>Intent</strong>: <em>[user.a_intent]</em>) (<strong>Targeting</strong>: <em>[user.zone_sel.selecting]</em>) [log_reagents(src)]")
			reagents.trans_to(M,5)
		else
			logTheThing("combat", user, M, "used [src] on %target% (<strong>Intent</strong>: <em>[user.a_intent]</em>) (<strong>Targeting</strong>: <em>[user.zone_sel.selecting]</em>)")
		if (!saw_surgery(M, user))
			return ..()
		else return

	suicide(var/mob/user as mob)
		user.visible_message("<span style=\"color:red\"><strong>[user] slashes \his own throat with [src]!</strong></span>")
		blood_slash(user, 25)
		playsound(user.loc, hitsound, 50, 1)
		user.TakeDamage("head", 150, 0)
		user.updatehealth()
		spawn (100)
			if (user)
				user.suiciding = 0
		return TRUE

/obj/item/circular_saw/vr
	icon = 'icons/effects/VR.dmi'
	icon_state = "saw"

/* =========================================================== */
/* -------------------- Enucleation Spoon -------------------- */
/* =========================================================== */

/obj/item/surgical_spoon
	name = "enucleation spoon"
	desc = "A surgeon's tool, used to protect the globe of the eye during eye removal surgery, and to lift the eye out of the socket. You could eat food with it too, I guess."
	icon = 'icons/obj/surgery.dmi'
	icon_state = "spoon"
	inhand_image_icon = 'icons/mob/inhand/hand_medical.dmi'
	item_state = "scalpel"
	flags = FPRINT | TABLEPASS | CONDUCT
	hit_type = DAMAGE_STAB
	hitsound = 'sound/effects/bloody_stab.ogg'
	force = 3.0
	w_class = 1.0
	throwforce = 5.0
	throw_speed = 3
	throw_range = 5
	m_amt = 10000
	g_amt = 5000
	stamina_damage = 5
	stamina_cost = 5
	stamina_crit_chance = 35
	var/mob/Poisoner = null
	module_research = list("tools" = 3, "medicine" = 3, "weapons" = 0.25)

	New()
		..()
		create_reagents(5)

	attack(mob/living/carbon/M as mob, mob/user as mob)
		if (reagents && reagents.total_volume)
			logTheThing("combat", user, M, "used [src] on %target% (<strong>Intent</strong>: <em>[user.a_intent]</em>) (<strong>Targeting</strong>: <em>[user.zone_sel.selecting]</em>) [log_reagents(src)]")
			reagents.trans_to(M,5)
		else
			logTheThing("combat", user, M, "used [src] on %target% (<strong>Intent</strong>: <em>[user.a_intent]</em>) (<strong>Targeting</strong>: <em>[user.zone_sel.selecting]</em>)")
		if (!spoon_surgery(M, user))
			return ..()
		else return

	suicide(var/mob/user as mob)
		user.visible_message("<span style=\"color:red\"><strong>[user] jabs [src] straight through \his eye and into \his brain!</strong></span>")
		blood_slash(user, 25)
		playsound(user.loc, hitsound, 50, 1)
		user.TakeDamage("head", 150, 0)
		user.updatehealth()
		spawn (100)
			if (user)
				user.suiciding = 0
		return TRUE

/* ==================================================== */
/* -------------------- Staple Gun -------------------- */
/* ==================================================== */

/obj/item/staple_gun
	name = "staple gun"
	desc = "A medical staple gun for securely reattaching limbs."
	icon = 'icons/obj/gun.dmi'
	icon_state = "staplegun"
	w_class = 1
	throw_speed = 4
	throw_range = 20
	force = 5
	var/projectile/staple = new/projectile/bullet/staple
	var/ammo = 20
	stamina_damage = 15
	stamina_cost = 15
	stamina_crit_chance = 15
	module_research = list("tools" = 1, "medicine" = 1, "weapons" = 1)

	// Every bit of usability helps (Convair880).
	examine()
		desc = "A medical staple gun for securely reattaching limbs. There are [ammo] staples left."
		..()
		return

	attack(mob/living/carbon/M as mob, mob/living/carbon/user as mob)
		if (!istype(M, /mob))
			return

		add_fingerprint(user)

		if (ammo < 1)
			user.show_text("*click* *click*", "red")
			return ..()

		if (user.a_intent != "help" && ishuman(M))
			var/mob/living/carbon/human/H = M
			H.visible_message("<span style=\"color:red\"><strong>[user] shoots [H] point-blank with [src]!</strong></span>")
			hit_with_projectile(user, staple, H)
			ammo--
			if (H && H.stat == 0)
				H.lastgasp()
			return

		if (!(user.zone_sel.selecting in list("l_arm","r_arm","l_leg","r_leg", "head")) || !ishuman(M))
			return ..()

		var/mob/living/carbon/human/H = M

		//Attach butt to head
		if (user.zone_sel.selecting == "head" && istype(H.head, /obj/item/clothing/head/butt))
			var/obj/item/clothing/head/butt/B = H.head
			B.staple()
			if (staple.shot_sound)
				playsound(user, staple.shot_sound, 50, 1)
			if (user == H)
				user.visible_message("<span style=\"color:red\"><strong>[user] staples \the [B.name] to their own head! [prob(10) ? pick("Woah!", "What a goof!", "Wow!", "WHY!?"): null]</span>")
			else
				user.visible_message("<span style=\"color:red\"><strong>[user] staples \the [B.name] to [H.name]'s head!</span>")
			if (H.stat!=2)
				H.emote(pick("cry", "wail", "weep", "sob", "shame", "twitch"))
			ammo--
			logTheThing("combat",user, H, "staples a butt to %target%'s head")
			return

		if (!surgeryCheck(H, user))
			return ..()

		// Marq fix for undefined variable /human_limbs/var/head
		if (user.zone_sel.selecting in H.limbs.vars)
			var/obj/item/parts/surgery_limb = H.limbs.vars[user.zone_sel.selecting]
			if (istype(surgery_limb))
				ammo--
				surgery_limb.surgery(src)
			return

	attackby(obj/item/W, mob/user)
		..()
		if (istype(W,/obj/item/pipebomb/frame))
			var/obj/item/pipebomb/frame/F = W
			if (F.state < 2)
				user.show_text("This might work better if [F] was hollowed out.")
			else if (F.state == 2)
				user.show_text("You combine [F] and [src]. This looks pretty unsafe!")
				user.u_equip(F)
				user.u_equip(src)
				var/turf/T = get_turf(src)
				playsound(T, "sound/items/Deconstruct.ogg", 50, 1)
				new/obj/item/gun/kinetic/zipgun(T)
				qdel(F)
				qdel(src)

			else
				user.show_text("You can't seem to combine these two items this way.")
		return

/* =============================================== */
/* -------------------- Defib -------------------- */
/* =============================================== */

/obj/item/robodefibrilator
	name = "defibrillator"
	desc = "Used to resuscitate critical patients."
	flags = FPRINT | TABLEPASS | CONDUCT
	icon = 'icons/obj/surgery.dmi'
	inhand_image_icon = 'icons/mob/inhand/hand_medical.dmi'
	icon_state = "defib-on"
	item_state = "defib"
	var/icon_base = "defib"
	var/charged = 1
	var/charge_time = 100
	var/emagged = 0
	var/makeshift = 0
	var/obj/item/cell/cell = null
	mats = 10

	emag_act(var/mob/user)
		if (makeshift)
			if (user)
				user.show_text("You prod at [src], but it doesn't do anything.", "red")
			return FALSE
		if (!emagged)
			if (user)
				user.show_text("You short out the on board medical scanner!", "blue")
			desc += " The screen only shows the word KILL flashing over and over."
			emagged = 1
			return TRUE
		else
			if (user)
				user.show_text("This has already been tampered with.", "red")
			return FALSE

	demag(var/mob/user)
		if (!emagged)
			return FALSE
		if (user)
			user.show_text("You reapair the on board medical scanner.", "blue")
			desc = null
			desc = "Used to resuscitate critical patients."
		emagged = 0
		return TRUE

	attack(mob/living/M as mob, mob/user as mob)
		if (!ishuman(M))
			return ..()
		if (charged == 0)
			user.show_text("[src] is still charging!", "red")
			return
		if (defibrillate(M, user, emagged, makeshift, cell))
			charged = 0
			icon_state = "[icon_base]-shock"
			spawn (10)
				icon_state = "[icon_base]-off"
			spawn (charge_time)
				charged = 1
				icon_state = "[icon_base]-on"
				playsound(user.loc, "sound/weapons/flash.ogg", 75, 1)

	disposing()
		..()
		if (cell)
			cell.dispose()
			cell = null

	get_desc(dist)
		..()
		if (istype(cell))
			if (cell.artifact)
				return
			else
				. += "The charge meter reads [round(cell.percent())]%."

/obj/item/robodefibrilator/emagged
	emagged = 1
	desc = "Used to resuscitate critical patients.  The screen only shows the word KILL flashing over and over."

/obj/item/robodefibrilator/vr
	icon = 'icons/effects/VR.dmi'

/obj/item/robodefibrilator/makeshift
	name = "shoddy-looking makeshift defibrilator"
	desc = "It might restart your heart, I guess, or it might barbeque your insides."
	icon_state = "cell-on"
	inhand_image_icon = 'icons/mob/inhand/hand_medical.dmi'
	item_state = "cell"
	icon_base = "cell"
	makeshift = 1

	New(var/location, var/obj/item/cell/newcell)
		..()
		if (!istype(newcell))
			newcell = new /obj/item/cell/charged(src)
		cell = newcell
		newcell.set_loc(src)

/* ================================================ */
/* -------------------- Suture -------------------- */
/* ================================================ */

/obj/item/suture
	name = "suture"
	desc = "A fine, curved needle with a length of absorbable polyglycolide suture thread."
	icon = 'icons/obj/surgery.dmi'
	icon_state = "suture"
	inhand_image_icon = 'icons/mob/inhand/hand_medical.dmi'
	item_state = "suture"
	flags = FPRINT | TABLEPASS | CONDUCT
	hit_type = DAMAGE_STAB
	w_class = 1.0
	force = 1
	throwforce = 1.0
	throw_speed = 4
	throw_range = 20
	m_amt = 5000
	stamina_damage = 1
	stamina_cost = 1
	stamina_crit_chance = 0
	var/in_use = 0

	attack(mob/living/carbon/M as mob, mob/living/carbon/user as mob)
		if (!suture_surgery(M,user))
			if (ishuman(M))
				var/mob/living/carbon/human/H = M
				var/zone = user.zone_sel.selecting
				var/surgery_status = H.get_surgery_status(zone)
				if (surgery_status && H.organHolder)
					H.visible_message("<span style=\"color:red\"><strong>[user]</strong> begins suturing the incisions on [H == user ? "[H.gender == "male" ? "his" : "her"]" : "[H]'s"] [zone_sel2name[zone]] closed with [src].</span>", \
					"<span style=\"color:red\">[H == user ? "You begin" : "<strong>[user]</strong> begins"] suturing the incisions on your [zone_sel2name[zone]] closed with [src].</span>")
					in_use = 1
					if (do_mob(user, H, 20 * surgery_status))
						H.visible_message("<span style=\"color:blue\"><strong>[user]</strong> sutures the incisions on [H == user ? "[H.gender == "male" ? "his" : "her"]" : "[H]'s"] [zone_sel2name[zone]] closed.</span>", \
						"<span style=\"color:blue\">[H == user ? "You suture" : "<strong>[user]</strong> sutures"] the incisions on your [zone_sel2name[zone]] closed.</span>")
						if (zone == "chest")
							if (H.organHolder.heart)
								H.organHolder.heart.op_stage = 0.0
							if (H.butt_op_stage)
								H.butt_op_stage = 0.0
							H.TakeDamage("chest", 2, 0)
						else if (zone == "head")
							if (H.organHolder.head)
								H.organHolder.head.op_stage = 0.0
							if (H.organHolder.skull)
								H.organHolder.skull.op_stage = 0.0
							if (H.organHolder.brain)
								H.organHolder.brain.op_stage = 0.0
						if (H.bleeding)
							repair_bleeding_damage(H, 50, rand(1,3))
						in_use = 0
						return
					else
						user.show_text("<span style=\"color:red\">You were interrupted!</span>", "red")
						in_use = 0
						return
				else if (H.bleeding)
					H.visible_message("<span style=\"color:red\"><strong>[user]</strong> begins suturing [H == user ? "[H.gender == "male" ? "his" : "her"]" : "[H]'s"] wounds closed with [src].</span>", \
					"<span style=\"color:red\">[H == user ? "You begin" : "<strong>[user]</strong> begins"] suturing your wounds closed with [src].</span>")
					in_use = 1
					if (do_mob(user, H, 20 * H.bleeding))
						H.visible_message("<span style=\"color:blue\"><strong>[user]</strong> sutures [H == user ? "[H.gender == "male" ? "his" : "her"]" : "[H]'s"] wounds closed.</span>", \
						"<span style=\"color:blue\">[H == user ? "You suture" : "<strong>[user]</strong> sutures"] your wounds closed.</span>")
						repair_bleeding_damage(M, 100, 10)
						in_use = 0
						return
					else
						user.show_text("<span style=\"color:red\">You were interrupted!</span>", "red")
						in_use = 0
						return
				else
					user.show_text("[H] has no wounds to close!", "red")
					return
		else
			return

	suicide(var/mob/user as mob)
		user.visible_message("<span style=\"color:red\"><strong>[user] rapidly sews \his mouth and nose closed with [src]! Holy shit, how?!</strong></span>")
		user.take_oxygen_deprivation(160)
		user.updatehealth()
		spawn (100)
			if (user)
				user.suiciding = 0
		return TRUE

/obj/item/suture/vr
	icon = 'icons/effects/VR.dmi'

/* ================================================= */
/* -------------------- Bandage -------------------- */
/* ================================================= */

/obj/item/bandage
	name = "bandage"
	desc = "A length of gauze that will help stop bleeding."
	icon = 'icons/obj/surgery.dmi'
	icon_state = "bandage-item-3"
	inhand_image_icon = 'icons/mob/inhand/hand_medical.dmi'
	item_state = "bandage"
	flags = FPRINT | TABLEPASS
	w_class = 1.0
	force = 0
	throwforce = 1.0
	throw_speed = 4
	throw_range = 20
	stamina_damage = 0
	stamina_cost = 0
	stamina_crit_chance = 0
	var/uses = 6
	var/in_use = 0

	get_desc(dist)
		..()
		if (uses >= 0)
			switch (uses)
				if (-INFINITY to 0)
					. += "<span style=\"color:red\">There's none left.</span>"
				if (1) // grhg w/e I'm half asleep this is good enough
					. += "<span style=\"color:red\">There's enough left to bandage about [uses] wound.</span>"
				if (2 to 5)
					. += "<span style=\"color:red\">There's enough left to bandage about [uses] wounds.</span>"
				if (6 to INFINITY)
					. += "None of it's been used."

	attack(mob/living/carbon/M as mob, mob/living/carbon/user as mob)
		if (!uses || icon_state == "bandage-item-0")
			user.show_text("There's nothing left of [src]!", "red")
			return
		if (in_use)
			return
		if (ishuman(M))
			var/mob/living/carbon/human/H = M
			if (H.bleeding)
				H.visible_message("<span style=\"color:red\"><strong>[user]</strong> begins bandaging [H == user ? "[H.gender == "male" ? "his" : "her"]" : "[H]'s"] wounds with [src].</span>", \
				"<span style=\"color:red\">[H == user ? "You begin" : "<strong>[user]</strong> begins"] bandaging your wounds with [src].</span>")
				in_use = 1
				if (do_mob(user, H, 15))
					H.visible_message("<span style=\"color:blue\"><strong>[user]</strong> dresses [H == user ? "[H.gender == "male" ? "his" : "her"]" : "[H]'s"] wounds.</span>", \
					"<span style=\"color:blue\">[H == user ? "You dress" : "<strong>[user]</strong> dresses"] your wounds.</span>")
					repair_bleeding_damage(M, 100, rand(2,5))
					uses --
					in_use = 0
					update_icon()
					var/target = user.zone_sel.selecting
					if (!H.bandaged.Find(target))
						H.bandaged += target
						H.update_body()
				else
					user.show_text("You were interrupted!", "red")
					in_use = 0
					return
			else
				user.show_text("[H] has no wounds to bandage!", "red")
				return
		else
			return ..()

	proc/update_icon()
		switch (uses)
			if (0 to -INFINITY)
				icon_state = "bandage-item-0"
			if (1 to 2)
				icon_state = "bandage-item-1"
			if (3 to 4)
				icon_state = "bandage-item-2"
			if (5 to INFINITY)
				icon_state = "bandage-item-3"

/obj/item/bandage/vr
	icon = 'icons/effects/VR.dmi'

/* =================================================== */
/* -------------------- Blood Bag -------------------- */
/* =================================================== */
/*
/obj/item/bloodbag
	name = "blood bag"
	desc = "A bag filled with donated O- blood. There's a fine needle at the end that can be used to transfer the blood to someone."
	icon = 'icons/obj/surgery.dmi'
	icon_state = "bloodbag-10"
	inhand_image_icon = 'icons/mob/inhand/hand_medical.dmi'
	item_state = "bloodbag"
	flags = FPRINT | TABLEPASS
	w_class = 1.0
	force = 0
	throwforce = 1.0
	throw_speed = 4
	throw_range = 20
	stamina_damage = 0
	stamina_cost = 0
	stamina_crit_chance = 0
	var/volume = 100 // aaa why did they hold SO MUCH BLOOD??  500 IS THE SAME AS A PERSON WHY DID THEY HAVE A PERSON WORTH OF BLOOD IN THEM
	var/in_use = 0

	get_desc(dist)
		..()
		if (volume >= 0)
			switch (volume)
				if (-INFINITY to 0)
					. += "<span style=\"color:red\">It's empty.</span>"
				if (1 to 29)
					. += "<span style=\"color:red\">It's getting low.</span>"
				if (30 to 69)
					. += "Some of it's been used."
				if (70 to 99)
					. += "<span style=\"color:blue\">It's nearly full.</span>"
				if (100 to INFINITY)
					. += "<span style=\"color:blue\">It's full.</span>"

	attack(mob/living/carbon/M as mob, mob/living/carbon/user as mob)
		if (volume <= 0)
			user.show_text("There's nothing left in [src]!", "red")
			return
		if (in_use)
			return
		if (ishuman(M))
			var/mob/living/carbon/human/H = M
			if (H.blood_volume < 500)
				H.tri_message("<span style=\"color:blue\"><strong>[user]</strong> attaches [src]'s needle to [H == user ? </span>"[H.gender == "male" ? "his" : "her"]" : "[H]'s"] arm and begins transferring blood.",\
				user, "<span style=\"color:blue\">You attach [src]'s needle to [H == user ? </span>"your" : "[H]'s"] arm and begin transferring blood.",\
				H, "<span style=\"color:blue\">[H == user ? </span>"You attach" : "<strong>[user]</strong> attaches"] [src]'s needle to your arm and begin transferring blood.")
				in_use = 1
				for (var/i)
					if (H.blood_volume >= 500)
						H.visible_message("<span style=\"color:blue\"><strong>[H]</strong>'s blood transfusion finishes.</span>", \
						"<span style=\"color:blue\">Your blood transfusion finishes.</span>")
						in_use = 0
						break
					if (volume <= 0)
						H.visible_message("<span style=\"color:red\"><strong>[src] runs out of blood!</strong></span>")
						in_use = 0
						break
					if (get_dist(src, H) > 1)
						var/fluff = pick("pulled", "yanked", "ripped")
						H.visible_message("<span style=\"color:red\"><strong>[src]'s needle gets [fluff] out of [H]'s arm!</strong></span>", \
						"<span style=\"color:red\"><strong>[src]'s needle gets [fluff] out of your arm!</strong></span>")
						in_use = 0
						break
					else
						H.blood_volume ++
						volume --
						update_icon()
						if (prob(5))
							var/fluff = pick("better", "a little better", "a bit better", "warmer", "a little warmer", "a bit warmer", "less cold")
							H.visible_message("<span style=\"color:blue\"><strong>[H]</strong> looks [fluff].</span>", \
							"<span style=\"color:blue\">You feel [fluff].</span>")
						sleep(5)
			else
				user.show_text("[H] already has enough blood!", "red")
				return
		else
			return ..()

	attackby(obj/item/W, mob/user)
		if (istype(W, /obj/item/reagent_containers/hypospray) || istype(W, /obj/item/reagent_containers/syringe) || istype(W, /obj/item/reagent_containers/emergency_injector))
			if (W.reagents && W.reagents.has_reagent("blood"))
				var/blood_volume = W.reagents.get_reagent_amount("blood")
				if (blood_volume < W.reagents.total_volume)
					user.show_text("This blood is impure!", "red")
					return
				else
					if (volume > 100 - W:amount_per_transfer_from_this)
						user.show_text("[src] is too full!", "red")
						return
					user.visible_message("<span style=\"color:blue\"><strong>[user]</strong> transfers blood to [src].</span>", \
					"<span style=\"color:blue\">You transfer blood from [W] to [src].</span>")
					W.reagents.remove_reagent("blood", W:amount_per_transfer_from_this)
					volume += W:amount_per_transfer_from_this
					return
		else
			return ..()

	proc/update_icon()
		var/iv_state = max(min(round(volume, 10) / 10, 100), 0)
		icon_state = "bloodbag-[iv_state]"
/*		switch (volume)
			if (90 to INFINITY)
				icon_state = "bloodbag-10"
			if (80 to 89)
				icon_state = "bloodbag-9"
			if (70 to 79)
				icon_state = "bloodbag-8"
			if (60 to 69)
				icon_state = "bloodbag-7"
			if (50 to 59)
				icon_state = "bloodbag-6"
			if (40 to 49)
				icon_state = "bloodbag-5"
			if (30 to 39)
				icon_state = "bloodbag-4"
			if (20 to 29)
				icon_state = "bloodbag-3"
			if (10 to 19)
				icon_state = "bloodbag-2"
			if (1 to 9)
				icon_state = "bloodbag-1"
			if (-INFINITY to 0)
				icon_state = "bloodbag-0"
*/
*/
/* ================================================== */
/* -------------------- Body Bag -------------------- */
/* ================================================== */

/obj/item/body_bag
	name = "body bag"
	desc = "A heavy bag, used for carrying stuff around. The stuff is usually dead bodies. Hence the name."
	icon = 'icons/obj/surgery.dmi'
	icon_state = "bodybag"
	flags = FPRINT | TABLEPASS
	w_class = 1.0
	force = 0
	throwforce = 1.0
	throw_speed = 4
	throw_range = 20
	stamina_damage = 0
	stamina_cost = 0
	stamina_crit_chance = 0
	var/open = 0
	var/image/open_image = null
	var/sound_zipper = 'sound/items/zipper.ogg'

	New()
		..()
		open_image = image(icon, src, "bodybag-open1", EFFECTS_LAYER_BASE)

	disposing()
		for (var/atom/movable/AM in src)
			AM.set_loc(loc)
		..()

	proc/update_icon()
		if (open && open_image)
			overlays += open_image
			icon_state = "bodybag-open"
			w_class = 4.0
		else if (!open)
			overlays -= open_image
			if (contents && contents.len)
				icon_state = "bodybag-closed1"
			else
				icon_state = "bodybag-closed0"
			w_class = 4.0
		else
			overlays -= open_image
			icon_state = "bodybag"
			w_class = 1.0

	attack_self(mob/user as mob)
		if (icon_state == "bodybag" && w_class == 1.0)
			user.visible_message("<strong>[user]</strong> unfolds [src].",\
			"You unfold [src].")
			user.drop_item()
			update_icon()
		else
			return

	attack_hand(mob/user as mob)
		add_fingerprint(user)
		if (icon_state == "bodybag" && w_class == 1.0)
			return ..()
		else
			if (open)
				close()
			else
				open()
			return

	relaymove(mob/user as mob)
		if (user.stat)
			return
		if (prob(75))
			user.show_text("You fuss with [src], trying to find the zipper, but it's no use!", "red")
			for (var/mob/M in hearers(src, null))
				M.show_text("<FONT size=[max(0, 5 - get_dist(src, M))]>...rustle...</FONT>")
			return
		open()
		visible_message("<span style=\"color:red\"><strong>[user]</strong> unzips themselves from [src]!</span>")

	MouseDrop(mob/user as mob)
		..()
		if (!(contents && contents.len) && (usr == user && !usr.restrained() && !usr.stat && in_range(src, usr) && !issilicon(usr)))
			if (icon_state != "bodybag")
				usr.visible_message("<strong>[usr]</strong> folds up [src].",\
				"You fold up [src].")
			overlays -= open_image
			icon_state = "bodybag"
			w_class = 1.0
			attack_hand(usr)

	proc/open()
		playsound(loc, sound_zipper, 100, 1, , 6)
		for (var/obj/O in src)
			O.set_loc(get_turf(src))
		for (var/mob/M in src)
			M.weakened += 2
			spawn (3)
				M.set_loc(get_turf(src))
		open = 1
		update_icon()

	proc/close()
		playsound(loc, sound_zipper, 100, 1, , 6)
		for (var/obj/O in get_turf(src))
			if (O.density || O.anchored || O == src)
				continue
			O.set_loc(src)
		for (var/mob/M in get_turf(src))
			if (!M.lying || M.anchored || M.buckled)
				continue
			M.set_loc(src)
		open = 0
		update_icon()

/* ================================================== */
/* -------------------- Hemostat -------------------- */
/* ================================================== */

/obj/item/hemostat
	name = "hemostat"
	desc = "A surgical tool used for the control and reduction of bleeding during surgery."
	icon = 'icons/obj/surgery.dmi'
	icon_state = "hemostat"
	inhand_image_icon = 'icons/mob/inhand/hand_medical.dmi'
	item_state = "hemostat"
	flags = FPRINT | TABLEPASS | CONDUCT
	hit_type = DAMAGE_STAB
	hitsound = 'sound/effects/bloody_stab.ogg'
	force = 1.5
	w_class = 1.0
	throwforce = 3.0
	throw_speed = 3
	throw_range = 6
	m_amt = 7000
	g_amt = 3500
	stamina_damage = 2
	stamina_cost = 2
	stamina_crit_chance = 15
	module_research = list("tools" = 2, "medicine" = 3, "weapons" = 0.1)

	attack(mob/M as mob, mob/user as mob)
		if (!ishuman(M))
			if (user.a_intent == INTENT_HELP)
				return
			return ..()
		var/mob/living/carbon/human/H = M
		var/surgery_status = H.get_surgery_status(user.zone_sel.selecting)
		if (!surgery_status)
			if (user.a_intent == INTENT_HELP)
				return
			return ..()
		if (!surgeryCheck(H, user))
			if (user.a_intent == INTENT_HELP)
				return
			return ..()
		H.tri_message("<span style=\"color:red\"><strong>[user]</strong> begins clamping the bleeders in [H == user ? "[his_or_her(H)]" : "[H]'s"] incision with [src].</span>",\
		user, "<span style=\"color:red\">You begin clamping the bleeders in [user == H ? "your" : "[H]'s"] incision with [src].</span>",\
		H, "<span style=\"color:red\">[H == user ? "You begin" : "<strong>[user]</strong> begins"] clamping the bleeders in your incision with [src].</span>")

		if (!do_mob(user, H, minmax(surgery_status * 4, 0, 100)))
			user.visible_message("<span style=\"color:red\"><strong>[user]</strong> was interrupted!</span>",\
			"<span style=\"color:red\">You were interrupted!</span>")
			return

		H.tri_message("<span style=\"color:blue\"><strong>[user]</strong> clamps the bleeders in [H == user ? "[his_or_her(H)]" : "[H]'s"] incision with [src].</span>",\
		user, "<span style=\"color:blue\">You clamp the bleeders in [user == H ? "your" : "[H]'s"] incision with [src].</span>",\
		H, "<span style=\"color:blue\">[H == user ? "You clamp" : "<strong>[user]</strong> clamps"] the bleeders in your incision with [src].</span>")

		if (H.bleeding)
			repair_bleeding_damage(H, 50, rand(2,5))
		return
