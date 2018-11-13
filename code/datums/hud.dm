/obj/screen
	anchored = 1

/obj/screen/hud
	var/hud/master
	var/id = ""
	var/tooltipTheme

	clicked(list/params)
		if (master && (!master.click_check || (usr in master.mobs)))
			master.clicked(id, usr, params)

	//WIRE TOOLTIPS
	MouseEntered(location, control, params)
		if (tooltipTheme)
			usr.client.tooltip.show(src, params, title = src.name, content = (src.desc ? src.desc : null), theme = src.tooltipTheme)

	MouseExited()
		usr.client.tooltip.hide()

/hud
	var/list/mob/living/mobs = list()
	var/list/client/clients = list()
	var/list/obj/screen/hud/objects = list()
	var/click_check = 1

	disposing()
		for (var/mob/M in src.mobs)
			M.detach_hud(src)
		for (var/client/C in src.clients)
			remove_client(C)

	proc/add_client(client/C)
		for (var/atom/A in objects)
			C.screen += A
		src.clients += C

	proc/remove_client(client/C)
		src.clients -= C
		for (var/atom/A in objects)
			C.screen -= A

	proc/create_screen(id, name, icon, state, loc, layer = HUD_LAYER, dir = SOUTH, tooltipTheme = null)
		var/obj/screen/hud/S = new
		S.name = name
		S.id = id
		S.master = src
		S.icon = icon
		S.icon_state = state
		S.screen_loc = loc
		S.layer = layer
		S.dir = dir
		S.tooltipTheme = tooltipTheme
		objects += S
		for (var/client/C in src.clients)
			C.screen += S
		return S

	proc/add_object(atom/movable/A, layer = HUD_LAYER, loc)
		if (loc)
			A.screen_loc = loc
		A.layer = layer
		if (!objects.Find(A))
			objects += A
			for (var/client/C in src.clients)
				C.screen += A

	proc/remove_object(atom/movable/A)
		objects -= A
		for (var/client/C in src.clients)
			C.screen -= A

	proc/add_screen(obj/screen/S)
		if (!objects.Find(S))
			objects += S
			for (var/client/C in src.clients)
				C.screen += S

	proc/remove_screen(obj/screen/S)
		objects -= S
		for (var/client/C in src.clients)
			C.screen -= S

	proc/clicked(id)
