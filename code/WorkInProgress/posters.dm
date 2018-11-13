/* ._.-'~'-._.-'~'-._.-'~'-._.-'~'-._.-'~'-._.-'~'-._.-'~'-._. */
/*-=-=-=-=-=-=-=-=-=-=-=-+WANTED-POSTER+-=-=-=-=-=-=-=-=-=-=-=-*/
/* '~'-._.-'~'-._.-'~'-._.-'~'-._.-'~'-._.-'~'-._.-'~'-._.-'~' */

// so things don't have to grab a new instance of this every time they need it
var/global/icon/wanted_poster_unknown = icon('icons/obj/decals.dmi', "wanted-unknown")

// admin poster generation thing
/proc/gen_poster(var/target)
	if (!usr)
		return
	var/p_title = input(usr, "Enter title line", "Enter Title") as null|text
	var/p_image
	if (alert(usr, "Include picture of atom in poster?", "Add Image", "Yes", "No") == "Yes")
		if (!target)
			target = input(usr, "Select target", "Select target") as anything in world
		if (target)
			if (ismob(target))
				p_image = target:build_flat_icon()
			else if (isobj(target) || isturf(target) || isarea(target))
				p_image = getFlatIcon(target, SOUTH)
			else
				p_image = wanted_poster_unknown
		else
			p_image = wanted_poster_unknown

	var/p_i_sub = input(usr, "Enter subtitle to appear below image", "Enter Image Subtitle") as null|text
	var/p_l_title = input(usr, "Enter title to appear below image", "Enter Lower Title") as null|text
	var/p_l1 = input(usr, "Line 1 text", "Line 1 text") as null|text
	var/p_l2 = input(usr, "Line 2 text", "Line 2 text") as null|text
	var/p_l3 = input(usr, "Line 3 text", "Line 3 text") as null|text

	var/obj/item/poster/titled_photo/preview_np = new
	if (p_title)
		preview_np.line_title = p_title
	if (p_image)
		preview_np.poster_image = p_image
	if (p_i_sub)
		preview_np.line_photo_subtitle = p_i_sub
	if (p_l_title)
		preview_np.line_below_photo = p_l_title
	if (p_l1)
		preview_np.line_b1 = p_l1
	if (p_l2)
		preview_np.line_b2 = p_l2
	if (p_l3)
		preview_np.line_b3 = p_l3
	preview_np.generate_poster()
	preview_np.show_popup_win(usr)

	var/print_or_place = alert(usr, "Print out at all printers or place on your tile?", "Selection", "Place", "Print")
	if (alert(usr, "Confirm poster creation", "Confirmation", "OK", "Cancel") == "OK")
		if (print_or_place == "Print")
			for (var/obj/machinery/networked/printer/P in world)
				if (P.stat & (NOPOWER|BROKEN))
					continue
				flick("printer-printing",P)
				playsound(P.loc, "sound/machines/printer_dotmatrix.ogg", 50, 1)
				spawn (32)
					var/obj/item/poster/titled_photo/np = new(get_turf(P))
					if (p_title)
						np.line_title = p_title
					if (p_image)
						np.poster_image = p_image
					if (p_i_sub)
						np.line_photo_subtitle = p_i_sub
					if (p_l_title)
						np.line_below_photo = p_l_title
					if (p_l1)
						np.line_b1 = p_l1
					if (p_l2)
						np.line_b2 = p_l2
					if (p_l3)
						np.line_b3 = p_l3
					np.generate_poster()
		else
			var/obj/item/poster/titled_photo/np = new(get_turf(usr))
			if (p_title)
				np.line_title = p_title
			if (p_image)
				np.poster_image = p_image
			if (p_i_sub)
				np.line_photo_subtitle = p_i_sub
			if (p_l_title)
				np.line_below_photo = p_l_title
			if (p_l1)
				np.line_b1 = p_l1
			if (p_l2)
				np.line_b2 = p_l2
			if (p_l3)
				np.line_b3 = p_l3
			np.generate_poster()

		logTheThing("admin", usr, null, "created a poster[print_or_place == "Print" ? " at all printers" : null]")
		message_admins("[key_name(usr)] created a poster[print_or_place == "Print" ? " at all printers" : null]")

// admin wanted poster gen
/proc/gen_wp(var/target)
	if (!usr)
		return
	if (!target)
		target = input(usr, "Enter custom name", "Enter Name") as null|text
	var/w_name
	var/w_image
	var/w_sub
	if (target)
		if (ismob(target))
			w_name = uppertext(target:real_name)
			w_image = target:build_flat_icon()
			w_sub = "FILE PHOTO"
		else if (isobj(target) || isturf(target) || isarea(target))
			w_name = uppertext(target:name)
			w_image = getFlatIcon(target, SOUTH)
			w_sub = "FILE PHOTO"
		else
			w_name = uppertext(target)
			w_image = wanted_poster_unknown
	else
		w_name = "UNKNOWN"
		w_image = wanted_poster_unknown
		w_sub = "FILE PHOTO"

	var/doa = input(usr, "Dead or Alive", "Dead or Alive", "DEAD OR ALIVE") as null|text
	if (doa)
		doa = "WANTED: [uppertext(doa)]"
	var/w_bounty = input(usr, "Bounty", "Bounty", 0) as null|num
	if (w_bounty)
		w_bounty = "<center><strong>[w_bounty] CREDIT REWARD</strong></center>"
	var/w_for = input(usr, "Wanted For", "Wanted For") as null|text
	if (w_for)
		w_for = "<strong>WANTED FOR:</strong> [uppertext(w_for)]"
	var/w_notes = input(usr, "Notes", "Notes") as null|text
	if (w_notes)
		w_notes = "<strong>NOTES:</strong> [uppertext(w_notes)]"

	var/obj/item/poster/titled_photo/preview_wp = new
	if (w_name)
		preview_wp.line_title = w_name
	if (w_image)
		preview_wp.poster_image = w_image
	if (w_sub)
		preview_wp.line_photo_subtitle = w_sub
	if (doa)
		preview_wp.line_below_photo = doa
	if (w_bounty)
		preview_wp.line_b1 = w_bounty
	if (w_for)
		preview_wp.line_b2 = w_for
	if (w_notes)
		preview_wp.line_b3 = w_notes
	preview_wp.generate_poster()
	preview_wp.show_popup_win(usr)

	var/print_or_place = alert(usr, "Print out at all printers or place on your tile?", "Selection", "Place", "Print")
	if (alert(usr, "Confirm poster creation", "Confirmation", "OK", "Cancel") == "OK")
		if (print_or_place == "Print")
			for (var/obj/machinery/networked/printer/P in world)
				if (P.stat & (NOPOWER|BROKEN))
					continue
				flick("printer-printing",P)
				playsound(P.loc, "sound/machines/printer_dotmatrix.ogg", 50, 1)
				spawn (32)
					var/obj/item/poster/titled_photo/wp = new(get_turf(P))
					if (w_name)
						wp.line_title = w_name
					if (w_image)
						wp.poster_image = w_image
					if (w_sub)
						wp.line_photo_subtitle = w_sub
					if (doa)
						wp.line_below_photo = doa
					if (w_bounty)
						wp.line_b1 = w_bounty
					if (w_for)
						wp.line_b2 = w_for
					if (w_notes)
						wp.line_b3 = w_notes
					wp.generate_poster()
		else
			var/obj/item/poster/titled_photo/wp = new(get_turf(usr))
			if (w_name)
				wp.line_title = w_name
			if (w_image)
				wp.poster_image = w_image
			if (w_sub)
				wp.line_photo_subtitle = w_sub
			if (doa)
				wp.line_below_photo = doa
			if (w_bounty)
				wp.line_b1 = w_bounty
			if (w_for)
				wp.line_b2 = w_for
			if (w_notes)
				wp.line_b3 = w_notes
			wp.generate_poster()

		logTheThing("admin", usr, null, "created a wanted poster targeting [w_name][print_or_place == "Print" ? " at all printers" : null]")
		message_admins("[key_name(usr)] created a wanted poster targeting [w_name][print_or_place == "Print" ? " at all printers" : null]")

/mob/proc/build_flat_icon()
	var/icon/comp = getFlatIcon(src, SOUTH)
	if (!comp)
		return
	return comp

/mob/living/carbon/human/build_flat_icon()
	var/icon/return_icon
	if (mutantrace)
		return_icon = new /icon(mutantrace.icon, mutantrace.icon_state)
	else
		return_icon = new /icon('icons/mob/human.dmi', "body_[gender == MALE ? "m" : "f"]")

	if (bioHolder && bioHolder.mobAppearance)
		if (bioHolder.mobAppearance.s_tone >= 0)
			return_icon.Blend(rgb(bioHolder.mobAppearance.s_tone, bioHolder.mobAppearance.s_tone, bioHolder.mobAppearance.s_tone), ICON_ADD)
		else
			return_icon.Blend(rgb(-bioHolder.mobAppearance.s_tone,  -bioHolder.mobAppearance.s_tone,  -bioHolder.mobAppearance.s_tone), ICON_SUBTRACT)

		var/icon/undies = new /icon('icons/mob/human_underwear.dmi', bioHolder.mobAppearance.underwear)
		undies.Blend(hex2rgb(bioHolder.mobAppearance.u_color ? bioHolder.mobAppearance.u_color : "#FFFFFF"), ICON_MULTIPLY)
		return_icon.Blend(undies, ICON_OVERLAY)
		undies = null

	var/icon/comp = getFlatIcon(src)//, SOUTH)
	return_icon.Blend(comp, ICON_OVERLAY)
	return return_icon

/obj/item/poster
	name = "poster"
	desc = null
	icon = 'icons/obj/decals.dmi'
	icon_state = "wall_poster_nt"
	throwforce = 0
	w_class = 1.0
	throw_speed = 3
	throw_range = 15
	layer = OBJ_LAYER+1

	//cogwerks - burning vars (stolen from paper - haine)
	burn_point = 220
	burn_output = 900
	burn_possible = 1
	health = 15

	var/imgw = 400
	var/imgh = 450
	var/pixel_var = 1
	var/popup_win = 1
	var/no_spam = null
	var/can_put_up = 1

	New()
		..()
		if (pixel_var)
			pixel_y = rand(-9,9)
			pixel_x = rand(-8,8)

	examine()
		if (usr.client && popup_win)
			show_popup_win(usr)
		else
			return ..()

	proc/show_popup_win(var/client/C)
		return

	attack_hand(mob/user as mob)
		if (!anchored)
			return ..()
		if (user.a_intent != INTENT_HARM)
			show_popup_win(user.client)
			return
		var/turf/T = loc
		user.visible_message("<span style=\"color:red\"><strong>[user]</strong> rips down [src] from [T]!</span>",\
		"<span style=\"color:red\">You rip down [src] from [T]!</span>")
		var/obj/decal/cleanable/ripped_poster/decal = new(T)
		decal.icon_state = "[icon_state]-rip2"
		decal.pixel_x = pixel_x
		decal.pixel_y = pixel_y
		anchored = 0
		icon_state = "[icon_state]-rip1"
		can_put_up = 0
		user.put_in_hand_or_drop(src)

	afterattack(var/atom/A as mob|obj|turf, var/mob/user as mob)
		if (can_put_up && (istype(A, /turf/simulated/wall) || istype(A, /turf/simulated/shuttle/wall) || istype(A, /turf/unsimulated/wall)))
			user.visible_message("<strong>[user]</strong> attaches [src] to [A].",\
			"You attach [src] to [A].")
			user.u_equip(src)
			set_loc(A)
			anchored = 1
		else
			return ..()

	attack(mob/M as mob, mob/user as mob)
		if (popup_win && (no_spam + 25) <= ticker.round_elapsed_ticks)
			user.tri_message("<span style=\"color:red\"><strong>[user]</strong> shoves [src] in [user == M ? "[his_or_her(user)] own" : "[M]'s"] face!</span>",\
			user, "<span style=\"color:red\">You shove [src] in [user == M ? "your own" : "[M]'s"] face!</span>",\
			M, "<span style=\"color:red\">[M == user ? "You shove" : "<strong>[user]</strong> shoves"] [src] in your[M == user ? " own" : null] face!</span>")
			if (M.client)
				show_popup_win(M.client)
			no_spam = ticker.round_elapsed_ticks
		else
			return // don't attack people with the poster thanks

/obj/item/poster/titled_photo
	icon_state = "wanted"

	var/icon/poster_image = null // for file photos from the database
	var/poster_image_old = null
	var/obj/item/photo/photo = null // other photos - currently unused
	var/line_title = null
	var/poster_HTML = null
	var/line_photo_subtitle = null
	var/line_below_photo = null
	var/line_b1 = null
	var/line_b2 = null
	var/line_b3 = null

	New()
		..()
		spawn (5)
			if (!poster_HTML)
				generate_poster()

	attackby(obj/item/W as obj, mob/living/user as mob)
		if (istype(W, /obj/item/photo))
			var/obj/item/photo/new_p = W
			if (photo)
				user.show_text("You replace [photo] with [new_p].")
				var/obj/item/photo/old_p = photo
				photo = new_p
				user.u_equip(new_p)
				new_p.set_loc(src)
				user.put_in_hand_or_drop(old_p)
				poster_image = new_p.fullIcon
			else
				user.show_text("You stick [new_p] to [src].")
				photo = new_p
				user.u_equip(new_p)
				new_p.set_loc(src)
				poster_image_old = poster_image
				poster_image = new_p.fullIcon
			generate_poster()
		else
			return ..()

	attack_hand(mob/user as mob)
		if (photo)
			if (anchored && user.a_intent == INTENT_HARM)
				return ..()
			user.show_text("You remove [photo] from [src].")
			var/obj/item/photo/old_p = photo
			photo = null
			user.put_in_hand_or_drop(old_p)
			if (poster_image_old)
				poster_image = poster_image_old
			else
				poster_image = null
			generate_poster()
		else
			return ..()

	show_popup_win(var/client/C)
		if (!C || !popup_win || !poster_HTML)
			return
		C << browse_rsc(poster_image, "posterimage.png")
		C << browse(poster_HTML, "window=[line_title]_poster;titlebar=1;size=[imgw]x[imgh];can_resize=0")

	proc/generate_poster()
		poster_HTML = {"<html><head><meta http-equiv=\"X-UA-Compatible\" content=\"IE=8\"/></head><body><title>Poster</title>\
		[line_title ? "<h2><center><strong>[line_title]</strong></center></h2>" : null]<hr>\
		[poster_image ? "<center><img style=\"-ms-interpolation-mode:nearest-neighbor;\" src=posterimage.png height=96 width=96></center><br>" : null]\
		[line_photo_subtitle ? "<center><small><sup>[line_photo_subtitle]</sup></small></center>" : null]<hr>\
		[line_below_photo ? "<strong><big><center>[line_below_photo]</center></big></strong><br>" : null]\
		[line_b1 ? "[line_b1]<br>" : null]\
		[line_b2 ? "[line_b2]<br>" : null]\
		[line_b3 ? "[line_b3]" : null]"}

/obj/decal/cleanable/ripped_poster
	name = "ripped poster"
	desc = "Someone didn't want this here, but a little bit is always left."
	icon = 'icons/obj/decals.dmi'
	icon_state = "wall_poster_nt-rip2"
