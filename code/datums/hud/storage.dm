#define CREATE_BOXES if (isnull(boxes)) boxes = create_screen("boxes", "Storage", 'icons/mob/screen1.dmi', "block", "1,8 to 1,1")
#define CREATE_CLOSE if (isnull(close)) close = create_screen("close", "Close", 'icons/mob/screen1.dmi', "x", "1,1", HUD_LAYER+1)
/hud/storage
	var/obj/screen/hud/boxes = null
	var/obj/screen/hud/close = null
	var/obj/item/storage/master = null

/hud/storage/New(_master)
	master = _master
	update()

/hud/storage/clicked(id, mob/user)
	switch (id)
		if ("close")
			user.detach_hud(src)
			user.s_active = null

/hud/storage/proc/update()
	CREATE_BOXES
	CREATE_CLOSE
	
	var x = 1, y = 8, sx = 1, sy = 8
	if (master && isturf(master.loc) && !istype(master, /obj/item/storage/bible)) // goddamn BIBLES (prevents conflicting positions within different bibles)
		x = 7
		y = 8
		sx = 4
		sy = 2

	if (ishuman(usr))
		var/mob/living/carbon/human/player = usr
		var/icon/hud_style = hud_style_selection[get_hud_style(player)]
		if (isicon(hud_style) && boxes.icon != hud_style)
			boxes.icon = hud_style

	boxes.screen_loc = "[x],[y] to [x+sx-1],[y-sy+1]"
	close.screen_loc = "[x+sx-1],[y-sy+1]"
	
	if (master)
		var/i = 0
		for (var/obj/item/I in master.get_contents())
			if (!(I in objects)) // ugh
				add_object(I, HUD_LAYER+1)
			I.screen_loc = "[x+(i%sx)],[y-round(i/sx)]"
			++i

/hud/storage/proc/add_item(obj/item/I)
	update()

/hud/storage/proc/remove_item(obj/item/I)
	remove_object(I)
	update()
#undef CREATE_BOXES
#undef CREATE_CLOSE