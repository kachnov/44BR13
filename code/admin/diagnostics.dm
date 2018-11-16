/client/proc
	map_debug_panel()
		set category = "Debug"

		var/area_txt = "<strong>APC LOCATION REPORT</strong><HR>"
		var/apc_count = 0
		var/list/apcs = new()
		for (var/area/area in world)
			if (!area.requires_power)
				continue

			for (var/obj/machinery/power/apc/current_apc in area)
				if (!apcs.Find(current_apc)) apcs += current_apc

			apc_count = apcs.len
			if (apc_count != 1)
				area_txt += "[area.name] [area.type] has [apc_count] APCs.<br>"
			apcs.len = 0

		usr << browse(area_txt,"window=mapdebugpanel")


	general_report()
		set category = "Debug"

		if (!REPO.processScheduler)
			usr << alert("Process Scheduler not found.")

		var/mobs = 0
		for (var/mob/M in mobs)
			mobs++

		var/output = {"<strong>GENERAL SYSTEMS REPORT</strong><HR>
<strong>General Processing Data</strong><BR>
<strong># of Machines:</strong> [machines.len + atmos_machines.len]<BR>
<strong># of Pipe Networks:</strong> [pipe_networks.len]<BR>
<strong># of Processing Items:</strong> [processing_items.len]<BR>
<strong># of Power Nets:</strong> [powernets.len]<BR>
<strong># of Mobs:</strong> [mobs]<BR>
"}

		usr << browse(output,"window=generalreport")

	air_report()
		set category = "Debug"

		if (!REPO.processScheduler || !air_master)
			alert(usr,"processScheduler or air_master not found.","Air Report")
			return FALSE

		var/active_groups = 0
		var/inactive_groups = 0
		var/active_tiles = 0
		for (var/air_group/group in air_master.air_groups)
			if (group.group_processing)
				active_groups++
			else
				inactive_groups++
				active_tiles += group.members.len

		var/hotspots = 0
		for (var/obj/hotspot/hotspot in world)
			hotspots++

		var/output = {"<strong>AIR SYSTEMS REPORT</strong><HR>
<strong>General Processing Data</strong><BR>
<strong># of Groups:</strong> [air_master.air_groups.len]<BR>
---- <em>Active:</em> [active_groups]<BR>
---- <em>Inactive:</em> [inactive_groups]<BR>
-------- <em>Tiles:</em> [active_tiles]<BR>
<strong># of Active Singletons:</strong> [air_master.active_singletons.len]<BR>
<BR>
<strong>Total # of Gas Mixtures In Existence: </strong>[total_gas_mixtures]<BR>
<strong>Special Processing Data</strong><BR>
<strong>Hotspot Processing:</strong> [hotspots]<BR>
<strong>High Temperature Processing:</strong> [air_master.active_super_conductivity.len]<BR>
<strong>High Pressure Processing:</strong> [air_master.high_pressure_delta.len] (not yet implemented)<BR>
<BR>
<strong>Geometry Processing Data</strong><BR>
<strong>Group Rebuild:</strong> [air_master.groups_to_rebuild.len]<BR>
<strong>Tile Update:</strong> [air_master.tiles_to_update.len]<BR>
[air_histogram()]
"}

		usr << browse(output,"window=airreport")

	air_histogram()
	
		var/html = "<pre>"
		var/list/ghistogram = new
		var/list/ughistogram = new
		var/p
		
		for (var/air_group/g in air_master.air_groups)
			if (g.group_processing)
				for (var/turf/simulated/member in g.members)
					p = round(max(-1, member.air.return_pressure()), 10)/10 + 1
					if (p > ghistogram.len)
						ghistogram.len = p
					ghistogram[p]++
			else
				for (var/turf/simulated/member in g.members)
					p = round(max(-1, member.air.return_pressure()), 10)/10 + 1
					if (p > ughistogram.len)
						ughistogram.len = p
					ughistogram[p]++
				
		html += "Group processing tiles pressure histogram data:\n"
		for (var/i=1,i<=ghistogram.len,i++)
			html += "[10*(i-1)]\t\t[ghistogram[i]]\n"
		html += "Non-group processing tiles pressure histogram data:\n"
		for (var/i=1,i<=ughistogram.len,i++)
			html += "[10*(i-1)]\t\t[ughistogram[i]]\n"
		return html
				
	air_status(turf/target as turf)
		set category = "Debug"
		set name = "Air Status"

		if (!isturf(target))
			return

		var/gas_mixture/GM = target.return_air()
		var/burning = 0
		if (istype(target, /turf/simulated))
			var/turf/simulated/T = target
			if (T.active_hotspot)
				burning = 1

		boutput(usr, "<span style=\"color:blue\">@[target.x],[target.y] ([GM.group_multiplier]): O:[GM.oxygen] T:[GM.toxins] N:[GM.nitrogen] C:[GM.carbon_dioxide] w [GM.temperature] Kelvin, [GM.return_pressure()] kPa [(burning)?("<span style=\"color:red\">BURNING</span>"):(null)]</span>")

		if (GM.trace_gases)
			for (var/gas/trace_gas in GM.trace_gases)
				boutput(usr, "[trace_gas.type]: [trace_gas.moles]")

	fix_next_move()
		set category = "Debug"
		set name = "Press this if everybody freezes up"
		var/largest_click_time = 0
		var/mob/largest_click_mob = null
		if (disable_next_click)
			boutput(usr, "<span style=\"color:red\">next_click is disabled and therefore so is this command!</span>")
			return
		for (var/mob/M in mobs)
			if (!M.client)
				continue
			if (M.next_click >= largest_click_time)
				largest_click_mob = M
				if (M.next_click > world.time)
					largest_click_time = M.next_click - world.time
				else
					largest_click_time = 0
			logTheThing("admin", M, null, "lastDblClick = [M.next_click]  world.time = [world.time]")
			logTheThing("diary", M, null, "lastDblClick = [M.next_click]  world.time = [world.time]", "admin")
			M.next_click = 0
		message_admins("[key_name(largest_click_mob, 1)] had the largest click delay with [largest_click_time] frames / [largest_click_time/10] seconds!")
		message_admins("world.time = [world.time]")
		return
