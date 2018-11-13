/* ================================================= */
/* -------------------- Dropper -------------------- */
/* ================================================= */

#define TO_SELF 0
#define TO_TARGET 1
/obj/item/reagent_containers/dropper
	name = "dropper"
	desc = "A dropper. Transfers 5 units."
	icon = 'icons/obj/chemical.dmi'
	inhand_image_icon = 'icons/mob/inhand/hand_medical.dmi'
	icon_state = "dropper0"
	initial_volume = 5
	amount_per_transfer_from_this = 5
	rc_flags = RC_SCALE | RC_VISIBLE | RC_SPECTRO
	var/icon_empty = "dropper0"
	var/icon_filled = "dropper1"
	var/image/fluid_image
	var/customizable_settings_available = 0
	var/transfer_amount = 5.0
	var/transfer_mode = TO_SELF

	New()
		..()
		fluid_image = image('icons/obj/chemical.dmi', "dropper1-fluid")

	on_reagent_change()
		underlays = null
		if (reagents.total_volume)
			var/color/average = reagents.get_average_color()
			fluid_image.color = average.to_rgba()
			underlays += fluid_image

		update_icon()
		return

	proc/update_icon()
		if (!src || !istype(src))
			return

		if (reagents.total_volume)
			icon_state = icon_filled
		else
			icon_state = icon_empty

		return

	afterattack(obj/target, mob/user, flag)
		if (!reagents || !target.reagents)
			return

		if ((customizable_settings_available && transfer_mode == TO_SELF) || (!customizable_settings_available && !reagents.total_volume))
			var/t = min(transfer_amount, target.reagents.total_volume) // Can't draw more than THEY have.
			t = min(transfer_amount, reagents.maximum_volume - reagents.total_volume)
			if (t <= 0) return

			if (target.is_open_container() != 1 && !istype(target, /obj/reagent_dispensers))
				boutput(user, "<span style=\"color:red\">You cannot directly remove reagents from [target].</span>")
				return
			if (!target.reagents.total_volume)
				boutput(user, "<span style=\"color:red\">[target] is empty.</span>")
				return

			target.reagents.trans_to(src, t)
			boutput(user, "<span style=\"color:blue\">You fill the dropper with [t] units of the solution.</span>")
			update_icon()

		else if ((customizable_settings_available && transfer_mode == TO_TARGET) || (!customizable_settings_available && reagents.total_volume))
			if (reagents.total_volume)
				var/t = min(transfer_amount, reagents.total_volume) // Can't drop more than you have.

				if (target.reagents.total_volume >= target.reagents.maximum_volume)
					boutput(user, "<span style=\"color:red\">[target] is full.</span>")
					return
				if (target.is_open_container() != 1 && !ismob(target) && !istype(target, /obj/item/reagent_containers/food)) // You can inject humans and food but you can't remove the shit.
					boutput(user, "<span style=\"color:red\">You cannot directly fill this object.</span>")
					return

				if (ismob(target))
					if (target != user)
						for (var/mob/O in AIviewers(world.view, user))
							O.show_message(text("<span style=\"color:red\"><strong>[] is trying to drip something onto []!</strong></span>", user, target), 1)
						log_me(user, target, 1)

						if (!do_mob(user, target, 15))
							if (user && ismob(user))
								user.show_text("You were interrupted!", "red")
							return
						if (!reagents || !reagents.total_volume)
							user.show_text("[src] doesn't contain any reagents.", "red")
							return

					for (var/mob/O in AIviewers(world.view, user))
						O.show_message(text("<span style=\"color:red\"><strong>[] drips something onto []!</strong></span>", user, target), 1)
					reagents.reaction(target, TOUCH, -(reagents.total_volume - t)) // Modify it so that the reaction only happens with the actual transferred amount.

				log_me(user, target)
				spawn (5)
					if (src && reagents && target && target.reagents)
						reagents.trans_to(target, t)

				user.show_text("You transfer [t] units of the solution.", "blue")
				update_icon()
			else
				user.show_text("The [src] is empty!", "red")

		return

	attack_self(mob/user)
		if (customizable_settings_available == 0)
			return

		var/t = {"<TT><h1>Mechanical dropper</h><br><hr>
				<table header="Wheel" border=1 width=300>
					<tr>
						<td>
							<center><strong><font size=+1>Wheel</font></strong></center>
					<tr>
						<td>
							<center><a href='?src=\ref[src];action=decr_int'>&#60;&#60;</a> <a href='?src=\ref[src];action=decr_dec'>&#60;</a> [transfer_amount] <a href='?src=\ref[src];action=incr_dec'>&#62;</a> <a href='?src=\ref[src];action=incr_int'>&#62;&#62;</a></center>
					<tr>
						<td>
							<center><strong><font size=+1>Mode</font></strong></center>
					<tr>
						<td>
							<center><a href='?src=\ref[src];action=toggle_mode'>[transfer_mode == TO_SELF ? "DRAW":"DROP"]</a></center>
				</table>"}

		user << browse(t,"window=mechdropper")
		onclose(user, "mechdropper")
		return

	Topic(href, href_list)
		if (get_dist(src, usr) > 1 || !isliving(usr) || iswraith(usr) || isintangible(usr))
			return
		if (usr.stunned > 0 || usr.weakened > 0 || usr.paralysis > 0 || usr.stat != 0 || usr.restrained())
			return

		..()

		switch(href_list["action"])
			//Decrease transfer amount
			if ("decr_int") modify_transfer_amt(-1)

			if ("decr_dec") modify_transfer_amt(-0.1)

			//increase it
			if ("incr_int") modify_transfer_amt(1)

			if ("incr_dec") modify_transfer_amt(0.1)

			if ("toggle_mode") transfer_mode = !transfer_mode

		if (usr) attack_self(usr)

	proc/modify_transfer_amt(var/diff)
		transfer_amount += diff
		transfer_amount = min(max(transfer_amount, 0.1), 10) // Sanity check.
		amount_per_transfer_from_this = transfer_amount
		return

	proc/log_me(var/user, var/target, var/delayed = 0)
		if (!src || !istype(src) || !user|| !target)
			return

		logTheThing("combat", user, target, "[delayed == 0 ? "drips" : "tries to drip"] chemicals [log_reagents(src)] from a dropper onto %target% at [log_loc(user)].")
		return

#undef TO_SELF
#undef TO_TARGET

/* ============================================================ */
/* -------------------- Mechanical Dropper -------------------- */
/* ============================================================ */

/obj/item/reagent_containers/dropper/mechanical
	name = "mechanical dropper"
	desc = "Allows you to transfer reagents in precise measurements."
	icon = 'icons/obj/chemical.dmi'
	icon_state = "ppipette-empty"
	initial_volume = 10
	icon_empty = "ppipette-empty"
	icon_filled = "ppipette-filled"
	fluid_image = null
	customizable_settings_available = 1

	New()
		..()
		fluid_image = image('icons/obj/chemical.dmi', "ppipette-fluid")