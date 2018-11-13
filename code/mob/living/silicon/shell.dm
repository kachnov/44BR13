/mob/living/silicon/shell
	icon = 'icons/mob/hivebot.dmi'
	icon_state = "eyebot-logout"

	health = 40
	max_health = 40

	var/mob/living/silicon/ai/controller
	var/inactive_name = "Shell"
	var/hud/shell/hud
	var/obj/item/cell/cell

	var/active_tool = 0
	var/list/obj/item/active_tools = list(null, null, null)
	var/list/obj/item/tools = list()

	New()
		..()
		bioHolder = new(src)

		inactive_name = "Shell-[rand(111, 999)]"
		name = inactive_name

		cell = new /obj/item/cell(src)
		cell.charge = cell.maxcharge
		tools = list(new /obj/item/device/flashlight(src), new /obj/item/crowbar(src), new /obj/item/device/multitool(src), new /obj/item/screwdriver(src))

		hud = new(src)

	death(gibbed)
	//	if (controller)
	//		controller.leave_shell()
		update_icon()
		density = 0
		..()

	click(atom/target, list/params)
		if ((target in tools) && !(target in active_tools))
			equip_tool(target)
			return
		..()

	proc/update_icon()
		if (stat)
			icon_state = "eyebot-dead"
		else if (controller)
			icon_state = "eyebot"
		else
			icon_state = "eyebot-logout"

	show_message(msg, type, alt, alt_type)
		if (controller)
			boutput(controller, msg)
		..()

	Life(controller/process/mobs/parent)
		..(parent)
		
		if (controller)
			hud.update_charge()

	updatehealth()
		..()
		if (health < 0 && stat != 2)
			stat = 2
			death(0)

	swap_hand(tool)
		if (isnull(tool))
			tool = (active_tool%3)+1
		if (tool > 3)
			return
		if (tool == active_tool) // trying to select the same tool deselects
			active_tool = 0
		else
			active_tool = tool

		if (active_tool > 0 && isnull(active_tools[active_tool]))
			active_tool = 0
		hud.update_active_tool()

	proc/equip_tool(obj/item/tool)
		if (isnull(active_tools[1]))
			active_tools[1] = tool
			hud.update_tool_selector()
		else if (isnull(active_tools[2]))
			active_tools[2] = tool
		else if (isnull(active_tools[3]))
			active_tools[3] = tool
		hud.update_tool_selector()
		hud.update_tools()

	proc/store_active_tool()
		if (active_tool < 1)
			return
		active_tools[active_tool] = null
		active_tool = 0
		hud.update_active_tool()
		hud.update_tools()
		hud.update_tool_selector()

	equipped()
		if (active_tool < 1)
			return null
		return active_tools[active_tool]

	Bump(atom/movable/AM as mob|obj, yes)
		spawn ( 0 )
			if ((!( yes ) || now_pushing))
				return
			now_pushing = 1
			if (ismob(AM))
				var/mob/tmob = AM
				if (istype(tmob, /mob/living/carbon/human) && tmob.bioHolder.HasEffect("fat"))
					if (prob(20))
						for (var/mob/M in viewers(src, null))
							if (M.client)
								boutput(M, "<span style=\"color:red\"><strong>[src] fails to push [tmob]'s fat ass out of the way.</strong></span>")
						now_pushing = 0
						unlock_medal("That's no moon, that's a GOURMAND!", 1)
						return
			now_pushing = 0
			..()
			if (!istype(AM, /atom/movable))
				return
			if (!now_pushing)
				now_pushing = 1
				if (!AM.anchored)
					var/t = get_dir(src, AM)
					step(AM, t)
				now_pushing = null
			return
		return