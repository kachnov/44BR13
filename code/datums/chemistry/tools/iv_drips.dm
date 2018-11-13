#define IV_INJECT 1
#define IV_DRAW 0

/* ================================================= */
/* -------------------- IV Drip -------------------- */
/* ================================================= */

/obj/item/reagent_containers/iv_drip
	name = "\improper IV drip"
	desc = "A bag with a fine needle attached at the end, for injecting patients with fluids."
	icon = 'icons/obj/surgery.dmi'
	icon_state = "IV"
	inhand_image_icon = 'icons/mob/inhand/hand_medical.dmi'
	item_state = "IV"
	w_class = 1.0
	flags = FPRINT | TABLEPASS | SUPPRESSATTACK | OPENCONTAINER
	rc_flags = RC_VISIBLE | RC_FULLNESS | RC_SPECTRO
	amount_per_transfer_from_this = 5
	initial_volume = 250//100
	var/image/fluid_image = null
	var/mob/living/carbon/human/patient = null
	var/obj/iv_stand/stand = null
	var/mode = IV_DRAW
	var/in_use = 0

	New()
		..()
		fluid_image = image(icon, "IV-0")
		update_icon()

	on_reagent_change()
		update_icon()
		if (stand)
			stand.update_icon()

	proc/update_icon()
		overlays = null
		if (reagents.total_volume)
			var/iv_state = max(min(round((reagents.total_volume / reagents.maximum_volume) * 100, 10) / 10, 100), 0) //Look away, you fool! Like the sun, this section of code is harmful for your eyes if you look directly at it
			//var/iv_state = max(min(round(reagents.total_volume, 10) / 10, 100), 0)
			fluid_image.icon_state = "IV-[iv_state]"
			var/color/average = reagents.get_average_color()
			fluid_image.color = average.to_rgba()
			overlays += fluid_image
			name = reagents.get_master_reagent_name() == "blood" ? "blood pack" : "[reagents.get_master_reagent_name()] drip"
		else
			fluid_image.icon_state = "IV-0"
			name = "\improper IV drip"
		if (ismob(loc))
			overlays += mode ? "inject" : "draw"

	is_open_container()
		return TRUE

	pickup(mob/user)
		..()
		update_icon()

	dropped(mob/user)
		..()
		update_icon()

	attack_self(mob/user as mob)
		mode = !(mode)
		user.show_text("You switch [src] to [mode ? "inject" : "draw"].")
		update_icon()

	attack(mob/living/carbon/M as mob, mob/living/carbon/user as mob)
		if (!ishuman(M))
			return ..()
		var/mob/living/carbon/human/H = M

		if (in_use && patient)
			if (patient != H)
				user.show_text("[src] is already being used by someone else!", "red")
				return
			else if (patient == H)
				H.tri_message("<span style=\"color:blue\"><strong>[user]</strong> removes [src]'s needle from [H == user ? "[H.gender == "male" ? "his" : "her"]" : "[H]'s"] arm.</span>",\
				user, "<span style=\"color:blue\">You remove [src]'s needle from [H == user ? "your" : "[H]'s"] arm.</span>",\
				H, "<span style=\"color:blue\">[H == user ? "You remove" : "<strong>[user]</strong> removes"] [src]'s needle from your arm.</span>")
				stop_transfusion()
				return
		else
			if (mode == IV_INJECT)
				if (!reagents.total_volume)
					user.show_text("There's nothing left in [src]!", "red")
					return
				if (H.reagents && H.reagents.is_full())
					user.show_text("[H]'s blood pressure seems dangerously high as it is, there's probably no room for anything else!", "red")
					return

			else if (mode == IV_DRAW)
				if (reagents.is_full())
					user.show_text("[src] is full!", "red")
					return
				// Vampires can't use this trick to inflate their blood count, because they can't get more than ~30% of it back.
				// Also ignore that second container of blood entirely if it's a vampire (Convair880).
				if ((isvampire(H) && (H.get_vampire_blood() <= 0)) || (!isvampire(H) && !H.blood_volume))
					user.show_text("[H] doesn't have anything left to give!", "red")
					return

			H.tri_message("<span style=\"color:blue\"><strong>[user]</strong> begins inserting [src]'s needle into [H == user ? "[H.gender == "male" ? "his" : "her"]" : "[H]'s"] arm.</span>",\
			user, "<span style=\"color:blue\">You begin inserting [src]'s needle into [H == user ? "your" : "[H]'s"] arm.</span>",\
			H, "<span style=\"color:blue\">[H == user ? "You begin" : "<strong>[user]</strong> begins"] inserting [src]'s needle into your arm.</span>")
			logTheThing("combat", user, H, "tries to hook up an IV drip [log_reagents(src)] to %target% at [log_loc(user)].")

			if (H != user)
				if (!do_mob(user, H, 50))
					user.show_text("You were interrupted!", "red")
					return
			else if (!do_after(H, 15))
				H.show_text("You were interrupted!", "red")
				return

			patient = H
			H.tri_message("<span style=\"color:blue\"><strong>[user]</strong> inserts [src]'s needle into [H == user ? "[H.gender == "male" ? "his" : "her"]" : "[H]'s"] arm.</span>",\
			user, "<span style=\"color:blue\">You insert [src]'s needle into [H == user ? "your" : "[H]'s"] arm.</span>",\
			H, "<span style=\"color:blue\">[H == user ? "You insert" : "<strong>[user]</strong> inserts"] [src]'s needle into your arm.</span>")
			logTheThing("combat", user, H, "connects an IV drip [log_reagents(src)] to %target% at [log_loc(user)].")
			start_transfusion()
			return

	process(var/mob/living/carbon/human/H as mob)
		if (!patient || !ishuman(patient) || !patient.reagents)
			stop_transfusion()
			return

		if ((!stand && get_dist(src, patient) > 1) || (stand && get_dist(stand, patient) > 1))
			var/fluff = pick("pulled", "yanked", "ripped")
			patient.visible_message("<span style=\"color:red\"><strong>[src]'s needle gets [fluff] out of [patient]'s arm!</strong></span>",\
			"<span style=\"color:red\"><strong>[src]'s needle gets [fluff] out of your arm!</strong></span>")
			stop_transfusion()
			return

		if (mode == IV_INJECT)
			if (patient.reagents.is_full())
				patient.visible_message("<span style=\"color:blue\"><strong>[patient]</strong>'s transfusion finishes.</span>",\
				"<span style=\"color:blue\">Your transfusion finishes.</span>")
				stop_transfusion()
				return
			if (!reagents.total_volume)
				patient.visible_message("<span style=\"color:red\">[src] runs out of fluid!</span>")
				stop_transfusion()
				return

			// the part where shit's actually transferred
			reagents.trans_to(patient, amount_per_transfer_from_this)
			patient.reagents.reaction(patient, INGEST, amount_per_transfer_from_this)
			return

		else if (mode == IV_DRAW)
			if (reagents.is_full())
				patient.visible_message("<span style=\"color:blue\">[src] fills up and stops drawing blood from [patient].</span>",\
				"<span style=\"color:blue\">[src] fills up and stops drawing blood from you.</span>")
				stop_transfusion()
				return
			// Vampires can't use this trick to inflate their blood count, because they can't get more than ~30% of it back.
			// Also ignore that second container of blood entirely if it's a vampire (Convair880).
			if ((isvampire(patient) && (patient.get_vampire_blood() <= 0)) || (!isvampire(patient) && !patient.reagents.total_volume && !patient.blood_volume))
				patient.visible_message("<span style=\"color:red\">[src] can't seem to draw anything more out of [patient]!</span>",\
				"<span style=\"color:red\">Your veins feel utterly empty!</span>")
				stop_transfusion()
				return

			// actual transfer
			transfer_blood(patient, src, amount_per_transfer_from_this)
			return

	proc/start_transfusion()
		in_use = 1
		if (!(src in processing_items))
			processing_items.Add(src)

	proc/stop_transfusion()
		if (src in processing_items)
			processing_items.Remove(src)
		in_use = 0
		patient = null

/* =================================================== */
/* -------------------- Sub-Types -------------------- */
/* =================================================== */

/obj/item/reagent_containers/iv_drip/blood
	desc = "A bag filled with some odd, synthetic blood. There's a fine needle at the end that can be used to transfer it to someone."
	icon_state = "IV-blood"
	mode = IV_INJECT
	New()
		..()
		reagents.add_reagent("blood", initial_volume)

/obj/item/reagent_containers/iv_drip/blood/vr
	icon = 'icons/effects/VR.dmi'

/obj/item/reagent_containers/iv_drip/saline
	desc = "A bag filled with saline. There's a fine needle at the end that can be used to transfer it to someone."
	mode = IV_INJECT
	New()
		..()
		reagents.add_reagent("saline", initial_volume)

/* ================================================== */
/* -------------------- IV Stand -------------------- */
/* ================================================== */

/obj/iv_stand
	name = "\improper IV stand"
	desc = "A metal pole that you can hang IV bags on, which is useful since we aren't animals that go leaving our sanitized medical equipment all over the ground or anything!"
	icon = 'icons/obj/surgery.dmi'
	icon_state = "IVstand"
	anchored = 0
	density = 0
	var/image/fluid_image = null
	var/obj/item/reagent_containers/iv_drip/IV = null
	mats = 10

	New()
		..()
		fluid_image = image(icon, "IVstand1-fluid")

	get_desc()
		if (IV)
			return IV.examine()

	proc/update_icon()
		overlays = null
		if (!IV)
			icon_state = "IVstand"
			name = "\improper IV stand"
			return
		else
			icon_state = "IVstand1"
			name = "\improper IV stand ([IV])"
			if (IV.reagents.total_volume)
				fluid_image.icon_state = "IVstand1-fluid"
				var/color/average = IV.reagents.get_average_color()
				fluid_image.color = average.to_rgba()
				overlays += fluid_image
			return

	attackby(obj/item/W, mob/user)
		if (!IV && istype(W, /obj/item/reagent_containers/iv_drip))
			if (isrobot(user)) // are they a borg? it's probably a mediborg's IV then, don't take that!
				return
			user.visible_message("<span style=\"color:blue\">[user] hangs [W] on [src].</span>",\
			"<span style=\"color:blue\">You hang [W] on [src].</span>")
			user.u_equip(W)
			W.set_loc(src)
			IV = W
			W:stand = src
			update_icon()
			return
		else if (IV)
			//IV.attackby(W, user)
			W.afterattack(IV, user)
			return
		else
			return ..()

	attack_hand(mob/user as mob)
		if (IV && !isrobot(user))
			var/obj/item/reagent_containers/iv_drip/oldIV = IV
			user.visible_message("<span style=\"color:blue\">[user] takes [oldIV] down from [src].</span>",\
			"<span style=\"color:blue\">You take [oldIV] down from [src].</span>")
			user.put_in_hand_or_drop(oldIV)
			oldIV.stand = null
			IV = null
			update_icon()
			return
		else
			return ..()

	MouseDrop(atom/over_object as mob|obj)
		if (usr && !usr.restrained() && !usr.stat && in_range(src, usr) && in_range(over_object, usr))
			if (IV && ishuman(over_object))
				IV.attack(over_object, usr)
				return
			else if (IV && over_object == src)
				IV.attack_self(usr)
				return
			else if (istype(over_object, /obj/stool/bed) || istype(over_object, /obj/stool/chair) || istype(over_object, /obj/machinery/optable))
				if (!(src in over_object.attached_objs))
					mutual_attach(src, over_object)
					set_loc(over_object.loc)
					layer = over_object.layer-1
					pixel_y += 8
					visible_message("[usr] attaches [src] to [over_object].")
					return
				else if (src in over_object.attached_objs)
					mutual_detach(src, over_object)
					layer = initial(layer)
					pixel_y = initial(pixel_y)
					visible_message("[usr] detaches [src] from [over_object].")
					return
			else
				return ..()
		else
			return ..()

#undef IV_INJECT
#undef IV_DRAW