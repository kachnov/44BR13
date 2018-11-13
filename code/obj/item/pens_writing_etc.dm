/* ---------- WHAT'S HERE ---------- */
/*
 - Pens
 - Markers
 - Crayons
 - Infrared Pens (not "infared", jfc mport)
 - Hand labeler
 - Clipboard
*/
/* --------------------------------- */

/obj/item/pen
	desc = "It's a normal black ink pen."
	name = "pen"
	icon = 'icons/obj/writing.dmi'
	inhand_image_icon = 'icons/mob/inhand/hand_tools.dmi'
	icon_state = "pen"
	flags = FPRINT | ONBELT | TABLEPASS
	throwforce = 0
	w_class = 1.0
	throw_speed = 7
	throw_range = 15
	m_amt = 60
	var/font = "Georgia" // custom pens
	var/webfont = null // atm this is used to add things to paper's font list. see /obj/item/pen/fancy and /obj/item/paper/attackby()
	var/font_color = "black"
	var/uses_handwriting = 0
	stamina_damage = 3
	stamina_cost = 1
	rand_pos = 1
	var/in_use = 0

	proc/write_on_turf(var/turf/T as turf, var/mob/user as mob)
		if (!T || !user || in_use || get_dist(T, user) > 1)
			return
		in_use = 1
		var/t = input(user, "What do you want to write?", null, null) as null|text
		if (!t || get_dist(T, user) > 1)
			in_use = 0
			return
		var/obj/decal/cleanable/writing/G = new /obj/decal/cleanable/writing(T)
		logTheThing("station", user, null, "writes on [T] with [src] at [showCoords(T.x, T.y, T.z)]: [t]")
		t = copytext(html_encode(t), 1, MAX_MESSAGE_LEN)
		if (font_color)
			G.color = font_color
		if (uses_handwriting && user && user.mind && user.mind.handwriting)
			G.font = user.mind.handwriting
			G.webfont = 1
		else if (font)
			G.font = font
			if (webfont)
				G.webfont = 1
		G.words = "[t]"
		in_use = 0

	suicide(var/mob/user as mob)
		user.visible_message("<span style=\"color:red\"><strong>[user] gently pushes the end of the [name] into \his nose, then leans forward until \he falls to the floor face first!</strong></span>")
		user.TakeDamage("head", 175, 0)
		user.updatehealth()
		spawn (100)
			if (user)
				user.suiciding = 0
		qdel(src)
		return TRUE

/obj/item/pen/fancy
	name = "fancy pen"
	desc = "A pretty swag pen."
	icon_state = "pen_fancy"
	//color = "blue"
	font_color = "blue"
	font = "Dancing Script, cursive"//"Vivaldi"
	webfont = "Dancing Script"
	uses_handwriting = 1

/obj/item/pen/odd
	name = "odd pen"
	desc = "There's something strange about this pen."
	font = "Wingdings"

/obj/item/pen/pencil
	name = "pencil"
	desc = "The core is graphite, not lead, don't worry!"
	icon_state = "pencil-y"
	//color = "blue"
	font_color = "#808080"
	font = "Dancing Script, cursive"//"Vivaldi"
	webfont = "Dancing Script"
	uses_handwriting = 1

	New()
		..()
		if (prob(25))
			icon_state = pick("pencil-b", "pencil-g")

/obj/item/pen/marker
	name = "felt marker"
	desc = "Try not to sniff it too much. Weirdo."
	icon_state = "marker"
	color = "#333333"
	font = "Permanent Marker, cursive"
	webfont = "Permanent Marker"

	red
		name = "red marker"
		color = "#FF0000"
		font_color = "#FF0000"

	orange
		name = "orange marker"
		color = "#FFAA00"
		font_color = "#FFAA00"

	yellow
		name = "yellow marker"
		color = "#FFFF00"
		font_color = "#FFFF00"

	green
		name = "green marker"
		color = "#00FF00"
		font_color = "#00FF00"

	aqua
		name = "aqua marker"
		color = "#00FFFF"
		font_color = "#00FFFF"

	blue
		name = "blue marker"
		color = "#0000FF"
		font_color = "#0000FF"

	purple
		name = "purple marker"
		color = "#AA00FF"
		font_color = "#AA00FF"

	pink
		name = "pink marker"
		color = "#FF00FF"
		font_color = "#FF00FF"

	random
		New()
			..()
			color = random_color_hex()
			font_color = color
			name = "[hex2color_name(color)] marker"

/obj/item/pen/crayon
	name = "crayon"
	desc = "Don't shove it up your nose, no matter how good of an idea that may seem to you.  You might not get it back."
	icon_state = "crayon"
	color = "#333333"
	font = "Comic Sans MS"
	var/color_name = "black"

	white
		name = "white crayon"
		color = "#FFFFFF"
		font_color = "#FFFFFF"
		color_name = "white"

	red
		name = "red crayon"
		color = "#FF0000"
		font_color = "#FF0000"
		color_name = "red"

	orange
		name = "orange crayon"
		color = "#FFAA00"
		font_color = "#FFAA00"
		color_name = "orange"

	yellow
		name = "yellow crayon"
		color = "#FFFF00"
		font_color = "#FFFF00"
		color_name = "yellow"

	green
		name = "green crayon"
		color = "#00FF00"
		font_color = "#00FF00"
		color_name = "green"

	aqua
		name = "aqua crayon"
		color = "#00FFFF"
		font_color = "#00FFFF"
		color_name = "aqua"

	blue
		name = "blue crayon"
		color = "#0000FF"
		font_color = "#0000FF"
		color_name = "blue"

	purple
		name = "purple crayon"
		color = "#AA00FF"
		font_color = "#AA00FF"
		color_name = "purple"

	pink
		name = "pink crayon"
		color = "#FF00FF"
		font_color = "#FF00FF"
		color_name = "pink"

	random
		New()
			..()
			color = random_color_hex()
			font_color = color
			color_name = hex2color_name(color)
			name = "[color_name] crayon"

	rainbow
		name = "strange crayon"
		color = "#FFFFFF"
		New()
			..()
			if (!ticker) // trying to avoid pre-game-start runtime bullshit
				spawn (30)
					font_color = random_saturated_hex_color(1)
					color_name = hex2color_name(font_color)
			else
				font_color = random_saturated_hex_color(1)
				color_name = hex2color_name(font_color)

		write_on_turf(var/turf/T as turf, var/mob/user as mob)
			if (!T || !user || in_use || get_dist(T, user) > 1)
				return
			font_color = random_saturated_hex_color(1)
			color_name = hex2color_name(font_color)
			..()

	suicide(var/mob/user as mob)
		user.visible_message("<span style=\"color:red\"><strong>[user] jams [src] up [his_or_her(user)] nose!</strong></span>")
		spawn (5) // so we get a moment to think before we die
			user.take_brain_damage(120)
		user.u_equip(src)
		set_loc(user) // SHOULD be redundant but you never know.
		user.updatehealth()
		spawn (100)
			if (user)
				user.suiciding = 0
		return TRUE

	write_on_turf(var/turf/T as turf, var/mob/user as mob)
		if (!T || !user || in_use || get_dist(T, user) > 1)
			return
		in_use = 1
		var/t = input(user, "What do you want to write?", null, null) as null|anything in list(\
		"A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z",\
		"0", "1", "2", "3", "4", "5", "6", "7", "8", "9",\
		"Exclamation Point", "Question Mark", "Ampersand", "Dollar", "Percent",\
		"Plus", "Minus", "Times", "Divided", "Equals",\
		"Arrow North", "Arrow East", "Arrow South", "Arrow West", "Square", "Circle", "Triangle", "Heart", "Star", "Smile", "Frown", "Neutral Face", "Bee", "Pentagram")
		if (!t || get_dist(T, user) > 1)
			in_use = 0
			return
		var/obj/decal/cleanable/writing/G = new /obj/decal/cleanable/writing(T)
		logTheThing("station", user, null, "writes on [T] with [src] at [showCoords(T.x, T.y, T.z)]: [t]")
		G.icon_state = "c[t]"
		if (font_color && color_name)
			G.color = font_color
			G.name = "[color_name] [t]"
		G.words = "[color_name] [t]"
		G.pixel_x = rand(-4,4)
		G.pixel_y = rand(-4,4)
		in_use = 0

/obj/item/pen/infrared
	desc = "A pen that can write in infrared."
	name = "infrared pen"
	color = "#FFEE44" // color var owns
	font_color = "#D20040"

	write_on_turf(var/turf/T as turf, var/mob/user as mob)
		if (!T || !user || in_use || get_dist(T, user) > 1)
			return
		in_use = 1
		var/t = input(user, "What do you want to write?", null, null) as null|text
		if (!t || get_dist(T, user) > 1)
			in_use = 0
			return
		var/obj/decal/cleanable/writing/infrared/G = new /obj/decal/cleanable/writing/infrared(T)
		logTheThing("station", user, null, "writes on [T] with [src] at [showCoords(T.x, T.y, T.z)]: [t]")
		t = copytext(html_encode(t), 1, MAX_MESSAGE_LEN)
		if (font_color)
			G.color = font_color
		if (uses_handwriting && user && user.mind && user.mind.handwriting)
			G.font = user.mind.handwriting
			G.webfont = 1
		else if (font)
			G.font = font
			if (webfont)
				G.webfont = 1
		G.words = "[t]"
		in_use = 0

/obj/item/hand_labeler
	name = "hand labeler"
	icon = 'icons/obj/writing.dmi'
	icon_state = "labeler"
	item_state = "flight"
	var/label = null
	var/labels_left = 10
	flags = FPRINT | TABLEPASS | SUPPRESSATTACK
	rand_pos = 1

	get_desc()
		if (!label || !length(label))
			. += "<br>It doesn't have a label set."
		else
			. += "<br>Its label is set to \"[label]\"."

	attack(mob/M, mob/user as mob)
		if (!istype(M, /mob)) // do this via afterattack()
			return
		if (!labels_left)
			boutput(user, "<span style=\"color:red\">No labels left.</span>")
			return
		if (!label || !length(label))
			if (islist(M.name_suffixes) && M.name_suffixes.len)
				M.remove_suffixes(1)
				M.UpdateName()
				user.visible_message("<span style=\"color:blue\"><strong>[user]</strong> removes the label from [M].</span>",\
				"<span style=\"color:blue\">You remove the label from [M].</span>")
				return
			else
				return

		Label(M, user)

	afterattack(atom/A, mob/user as mob)
		if (istype(A, /mob)) // do this via attack()
			return
		if (!labels_left)
			boutput(user, "<span style=\"color:red\">No labels left.</span>")
			return
		if (!label || !length(label))
			if (islist(A.name_suffixes) && A.name_suffixes.len)
				A.remove_suffixes(1)
				A.UpdateName()
				user.visible_message("<span style=\"color:blue\"><strong>[user]</strong> removes the label from [A].</span>",\
				"<span style=\"color:blue\">You remove the label from [A].</span>")
				return
			else
				return

		Label(A, user)

	attack_self()
		var/str = copytext(html_encode(input(usr,"Label text?","Set label","") as null|text), 1, 32)
		if (!str || !length(str))
			boutput(usr, "<span style=\"color:blue\">Label text cleared.</span>")
			label = null
			return
		if (length(str) > 30)
			boutput(usr, "<span style=\"color:red\">Text too long.</span>")
			return
		label = "([str])"
		boutput(usr, "<span style=\"color:blue\">You set the text to '[str]'.</span>")

	proc/Label(var/atom/A, var/mob/user, var/no_message = 0)
		if (user && !no_message)
			user.visible_message("<span style=\"color:blue\"><strong>[user]</strong> puts a label on [A].</span>",\
			"<span style=\"color:blue\">You put a label on [A].</span>")
		A.name_suffix(label)
		A.UpdateName()
		if (user && !no_message)
			logTheThing("combat", user, A, "puts a label on %target%, \"[label]\"")
		else if (!no_message)
			logTheThing("combat", A, null, "has a label applied to them, \"[label]\"")

	suicide(var/mob/user as mob)
		user.visible_message("<span style=\"color:red\"><strong>[user] labels \himself \"DEAD\"!</strong></span>")
		label = "(DEAD)"
		Label(user,user,1)

		user.TakeDamage("chest", 300, 0) //they have to die fast or it'd make even less sense
		user.updatehealth()
		spawn (100)
			if (user)
				user.suiciding = 0
		return TRUE

/obj/item/clipboard
	name = "clipboard"
	icon = 'icons/obj/writing.dmi'
	icon_state = "clipboard00"
	var/obj/item/pen/pen = null
	item_state = "clipboard"
	throwforce = 0
	w_class = 3.0
	throw_speed = 3
	throw_range = 10
	desc = "You can put paper on it. Ah, technology!"
	stamina_damage = 5
	stamina_cost = 5
	stamina_crit_chance = 5

	attack_self(mob/user as mob)
		var/dat = "<strong>Clipboard</strong><BR>"
		if (pen)
			dat += "<A href='?src=\ref[src];pen=1'>Remove Pen</A><BR><HR>"
		for (var/obj/item/paper/P in src)
			dat += "<A href='?src=\ref[src];read=\ref[P]'>[P.name]</A> <A href='?src=\ref[src];write=\ref[P]'>Write</A> <A href='?src=\ref[src];title=\ref[P]'>Title</A> <A href='?src=\ref[src];remove=\ref[P]'>Remove</A><BR>"

		for (var/obj/item/photo/P in src) //Todo: make it actually show the photo.  Currently, using [bicon()] just makes an egg image pop up (??)
			dat += "<A href='?src=\ref[src];remove=\ref[P]'>[P.name]</A><br>"

		user << browse(dat, "window=clipboard")
		onclose(user, "clipboard")
		return

	Topic(href, href_list)
		..()
		if ((usr.stat || usr.restrained()))
			return
		if (usr.contents.Find(src))
			usr.machine = src
			if (href_list["pen"])
				if (pen)
					usr.put_in_hand_or_drop(pen)
					pen = null
					add_fingerprint(usr)
					update()
			else if (href_list["remove"])
				var/obj/item/P = locate(href_list["remove"])
				if (P && P.loc == src)
					usr.put_in_hand_or_drop(P)
					add_fingerprint(usr)
					update()
			else if (href_list["write"])
				var/obj/item/P = locate(href_list["write"])
				if ((P && P.loc == src))
					if (istype(usr.r_hand, /obj/item/pen))
						P.attackby(usr.r_hand, usr)
					else
						if (istype(usr.l_hand, /obj/item/pen))
							P.attackby(usr.l_hand, usr)
						else
							if (istype(pen, /obj/item/pen))
								P.attackby(pen, usr)
				add_fingerprint(usr)
			else if (href_list["read"])
				var/obj/item/paper/P = locate(href_list["read"])
				if ((P && P.loc == src))
					if (!( istype(usr, /mob/living/carbon/human) ))
						usr << browse(text("<HTML><HEAD><TITLE>[]</TITLE></HEAD><BODY><TT>[]</TT></BODY></HTML>", P.name, stars(P.info)), text("window=[]", P.name))
						onclose(usr, "[P.name]")
					else
						usr << browse(text("<HTML><HEAD><TITLE>[]</TITLE></HEAD><BODY><TT>[]</TT></BODY></HTML>", P.name, P.info), text("window=[]", P.name))
						onclose(usr, "[P.name]")
			else if (href_list["title"])
				var/obj/item/P = locate(href_list["title"])
				if (P && P.loc == src)
					P.attack_self(usr)

				add_fingerprint(usr)

			if (ismob(loc))
				var/mob/M = loc
				if (M.machine == src)
					spawn ( 0 )
						attack_self(M)
						return
		return

	attack_hand(mob/user as mob)
		if (!user.equipped() && (user.l_hand == src || user.r_hand == src))
			var/obj/item/paper/P = locate() in src
			if (P)
				user.put_in_hand_or_drop(P)
				update()
			add_fingerprint(user)
		else
			/*
			if (user.contents.Find(src))
				spawn ( 0 )
					attack_self(user)
					return
			else
			*/
			return ..()
		return

	attackby(obj/item/P as obj, mob/user as mob)

		if (istype(P, /obj/item/paper) || istype(P, /obj/item/photo))
			if (contents.len < 15)
				user.drop_item()
				P.set_loc(src)
			else
				boutput(user, "<span style=\"color:blue\">Not enough space!!!</span>")
		else
			if (istype(P, /obj/item/pen))
				if (!pen)
					user.drop_item()
					P.set_loc(src)
					pen = P
			else
				return
		update()
		spawn (0)
			attack_self(user)
			return
		return

	proc/update()
		icon_state = "clipboard[(locate(/obj/item/paper) in src) ? "1" : "0"][pen ? "1" : "0"]"
		return

/obj/item/clipboard/with_pen

	New()
		..()
		pen = new /obj/item/pen(src)
		return