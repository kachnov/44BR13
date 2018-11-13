
/hud/zone_sel
	var/obj/screen/hud/background
	var/obj/screen/hud/head
	var/obj/screen/hud/chest
	var/obj/screen/hud/l_arm
	var/obj/screen/hud/r_arm
	var/obj/screen/hud/l_leg
	var/obj/screen/hud/r_leg
	var/obj/screen/hud/selection

	var/slocation = "CENTER+4, SOUTH"

	var/selecting = "chest"

	var/mob/master
	var/icon/icon_hud = 'icons/mob/hud_human_new.dmi'

	New(M, var/sloc, var/icon/I)
		master = M
		if (sloc)
			slocation = sloc
		spawn (0)
			if (istype(I))
				icon_hud = I
			else
				var/icon/hud_style = hud_style_selection[get_hud_style(master)]
				if (isicon(hud_style))
					icon_hud = hud_style

			background = create_screen("background", "Zone Selection", icon_hud, "zone_sel", slocation, HUD_LAYER)
			head = create_screen("head", "Target Head", icon_hud, "sel-head", slocation, HUD_LAYER+1)
			chest = create_screen("chest", "Target Chest", icon_hud, "sel-chest", slocation, HUD_LAYER+1)
			l_arm = create_screen("l_arm", "Target Left Arm", icon_hud, "sel-l_arm", slocation, HUD_LAYER+1)
			r_arm = create_screen("r_arm", "Target Right Arm", icon_hud, "sel-r_arm", slocation, HUD_LAYER+1)
			l_leg = create_screen("l_leg", "Target Left Leg", icon_hud, "sel-l_leg", slocation, HUD_LAYER+1)
			r_leg = create_screen("r_leg", "Target Right Leg", icon_hud, "sel-r_leg", slocation, HUD_LAYER+1)
			selection = create_screen("selection", "Current Target ([capitalize(zone_sel2name[selecting])])", icon_hud, selecting, slocation, HUD_LAYER+2)

	clicked(id, mob/user, list/params)
		if (!id || id == "background" || id == "selection")
			return
		select_zone(id)

	proc/select_zone(var/zone)
		if (!zone)
			return
		selecting = zone
		selection.name = "Current Target ([capitalize(zone_sel2name[zone])])"
		selection.icon_state = zone
		out(master, "Now targeting the [zone_sel2name[zone]].")

	proc/change_hud_style(var/icon/new_file)
		if (new_file)
			icon_hud = new_file
			if (background) background.icon = new_file
			if (head) head.icon = new_file
			if (chest) chest.icon = new_file
			if (l_arm) l_arm.icon = new_file
			if (r_arm) r_arm.icon = new_file
			if (l_leg) l_leg.icon = new_file
			if (r_leg) r_leg.icon = new_file
			if (selection) selection.icon = new_file
