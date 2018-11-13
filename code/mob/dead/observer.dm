// Observer

/mob/dead/observer
	icon = 'icons/mob/mob.dmi'
	icon_state = "ghost"
	layer = NOLIGHT_EFFECTS_LAYER_BASE
	density = 0
	canmove = 1
	blinded = 0
	anchored = 1	//  don't get pushed around
	var/mob/corpse = null	//	observer mode
	var/observe_round = 0
	var/health_shown = 0
	var/delete_on_logout = 1
	var/delete_on_logout_reset = 1
	var/obj/item/clothing/head/wig/wig = null

/mob/dead/observer/disposing()
	corpse = null
	..()

#define GHOST_LUM	1		// ghost luminosity

/mob/dead/observer/proc/apply_looks_of(var/client/C)
	if (!C.preferences)
		return
	var/preferences/P = C.preferences

	if (!P.AH)
		return

	var/cust_one_state = customization_styles[P.AH.customization_first]
	var/cust_two_state = customization_styles[P.AH.customization_second]
	var/cust_three_state = customization_styles[P.AH.customization_third]

	var/image/hair = image('icons/mob/human_hair.dmi', cust_one_state)
	hair.color = P.AH.customization_first_color
	hair.alpha = 192
	overlays += hair

	wig = new
	wig.mat_changename = 0
	var/material/wigmat = getCachedMaterial("ectofibre")
	wigmat.color = P.AH.customization_first_color
	wig.setMaterial(wigmat)
	wig.name = "ectofibre [name]'s hair"
	wig.icon = 'icons/mob/human_hair.dmi'
	wig.icon_state = cust_one_state
	wig.color = P.AH.customization_first_color
	wig.wear_image_icon = 'icons/mob/human_hair.dmi'
	wig.wear_image = image(wig.wear_image_icon, wig.icon_state)
	wig.wear_image.color = P.AH.customization_first_color


	var/image/beard = image('icons/mob/human_hair.dmi', cust_two_state)
	beard.color = P.AH.customization_second_color
	beard.alpha = 192
	overlays += beard

	var/image/detail = image('icons/mob/human_hair.dmi', cust_three_state)
	detail.color = P.AH.customization_third_color
	detail.alpha = 192
	overlays += detail

//#ifdef HALLOWEEN
/mob/dead/observer/CanPass(atom/movable/mover, turf/target, height=0, air_group=0)
	if (icon_state != "doubleghost" && istype(mover, /obj/projectile))
		var/obj/projectile/proj = mover
		if (istype(proj.proj_data, /projectile/energy_bolt_antighost))
			return FALSE

	return TRUE

/mob/dead/observer/bullet_act(var/obj/projectile/P)
	if (icon_state == "doubleghost")
		return

	icon_state = "doubleghost"
	visible_message("<span style=\"color:red\"><strong>[src] is busted!</strong></span>","<span style=\"color:red\">You are demateralized into a state of further death!</span>")
	corpse = null

	if (wig)
		wig.loc = loc
	new /obj/item/reagent_containers/food/snacks/ectoplasm(get_turf(src))
	overlays.len = 0
	log_shot(P,src)


//#endif

/mob/dead/observer/Life(controller/process/mobs/parent)
	if (..(parent))
		return TRUE
	if (client) //ov1
		// overlays
		//updateOverlaysClient(client)
		antagonist_overlay_refresh(0, 0) // Observer Life() only runs for admin ghosts (Convair880).
	return

/mob/dead/observer/New(mob/corpse)
	. = ..()
	invisibility = 10
	sight |= SEE_TURFS | SEE_MOBS | SEE_OBJS | SEE_SELF
	see_invisible = 16
	see_in_dark = SEE_DARK_FULL

	if (corpse && ismob(corpse))
		corpse = corpse
		set_loc(get_turf(corpse))
		real_name = corpse.real_name
		name = corpse.real_name
		verbs += /mob/dead/observer/proc/reenter_corpse
	#ifdef HALLOWEEN
	sd_SetLuminosity(GHOST_LUM) // comment all of these back out after hallowe'en
	#endif

/mob/living/verb/become_ghost()
	set src = usr
	set name = "Ghost"
	set category = "Commands"
	set desc = "Leave your lifeless body behind and become a ghost."

	if (stat != 2)
		if (prob(5))
			show_text("You strain really hard. I mean, like, really, REALLY hard but you still can't become a ghost!", "blue")
		else
			show_text("You're not dead yet!", "red")
		return
	ghostize()

/mob/proc/ghostize()
	if (key || client)
		var/mob/dead/observer/O = new/mob/dead/observer(src)
		if (isrestrictedz(O.z) && !restricted_z_allowed(O, get_turf(O)) && !(client && client.holder))
			var/OS = observer_start.len ? pick(observer_start) : locate(1, 1, 1)
			if (OS)
				O.set_loc(OS)
			else
				O.z = 1
		if (client && client.holder && stat !=2)
			O.stat = 0
		if (mind)
			mind.transfer_to(O)

		ghost = O
		return O
	return null

/mob/living/carbon/human/ghostize()
	var/mob/dead/observer/O = ..()
	if (!O)
		return null

	. = O

	var/image/hair = image('icons/mob/human_hair.dmi', cust_one_state)
	hair.color = bioHolder.mobAppearance.customization_first_color
	hair.alpha = 192
	O.overlays += hair

	var/image/beard = image('icons/mob/human_hair.dmi', cust_two_state)
	beard.color = bioHolder.mobAppearance.customization_second_color
	beard.alpha = 192
	O.overlays += beard

	var/image/detail = image('icons/mob/human_hair.dmi', cust_three_state)
	detail.color = bioHolder.mobAppearance.customization_third_color
	detail.alpha = 192
	O.overlays += detail

	O.wig = new
	O.wig.mat_changename = 0
	var/material/wigmat = getCachedMaterial("ectofibre")
	wigmat.color = bioHolder.mobAppearance.customization_first_color
	O.wig.setMaterial(wigmat)
	O.wig.name = "[O.name]'s hair"
	O.wig.icon = 'icons/mob/human_hair.dmi'
	O.wig.icon_state = cust_one_state
	O.wig.color = bioHolder.mobAppearance.customization_first_color
	O.wig.wear_image_icon = 'icons/mob/human_hair.dmi'
	O.wig.wear_image = image(O.wig.wear_image_icon, O.wig.icon_state)
	O.wig.wear_image.color = bioHolder.mobAppearance.customization_first_color

	if (glasses)
		var/image/glass = image(glasses.wear_image_icon, glasses.icon_state)
		glass.color = glasses.color
		glass.alpha = glasses.alpha * 0.75
		O.overlays += glass

	return O

/mob/living/silicon/robot/ghostize()
	var/mob/dead/observer/O = ..()
	if (!O)
		return null

	O.icon_state = "borghost"
	return O

/mob/dead/observer/verb/show_health()
	set category = "Toggles"
	set name = "Toggle Health"
	client.images.Remove(health_mon_icons)
	if (!health_shown)
		health_shown = 1
		if (client && client.images)
			for (var/image/I in health_mon_icons)
				if (I && src && I.loc != loc)
					client.images.Add(I)
	else
		health_shown = 0

/mob/dead/observer/Logout()
	..()
	if (last_client)
		last_client.images.Remove(health_mon_icons)


	if (!key && delete_on_logout)
		qdel(src)
	return

/mob/dead/observer/Move(NewLoc, direct)
	if (!canmove) return

	if (NewLoc && isrestrictedz(z) && !restricted_z_allowed(src, NewLoc) && !(client && client.holder))
		var/OS = observer_start.len ? pick(observer_start) : locate(1, 1, 1)
		if (OS)
			set_loc(OS)
		else
			z = 1
		return

	if (!isturf(loc))
		set_loc(get_turf(src))
	if (NewLoc)
		dir = get_dir(loc, NewLoc)
		set_loc(NewLoc)
		return

	dir = direct
	if ((direct & NORTH) && y < world.maxy)
		y++
	if ((direct & SOUTH) && y > 1)
		y--
	if ((direct & EAST) && x < world.maxx)
		x++
	if ((direct & WEST) && x > 1)
		x--

/mob/dead/observer/can_use_hands()	return FALSE
/mob/dead/observer/is_active()		return FALSE

/mob/dead/observer/proc/reenter_corpse()
	set category = "Special Verbs"
	set name = "Re-enter Corpse"
	if (!corpse)
		alert("You don't have a corpse!")
		return
	if (client && client.holder && client.holder.state == 2)
		var/rank = client.holder.rank
		client.clear_admin_verbs()
		client.holder.state = 1
		client.update_admins(rank)
	if (mind)
		mind.transfer_to(corpse)
	qdel(src)

/mob/dead/observer/verb/dead_tele()
	set category = "Special Verbs"
	set name = "Teleport"
	set desc= "Teleport"
	if ((usr.stat != 2) || !istype(usr, /mob/dead))
		boutput(usr, "Not when you're not dead!")
		return
	var/A

	A = input("Area to jump to", "BOOYEA", A) in teleareas
	var/area/thearea = teleareas[A]
	var/list/L = list()
	if (!istype(thearea))
		return

	for (var/turf/T in get_area_turfs(thearea.type))
		if (isrestrictedz(T.z)) //fffffuckk you
			continue
		L+=T
	usr.set_loc(pick(L))

/mob/dead/observer/proc/becomeDrone()
	set name = "Become Drone"
	set category = "Special Verbs"
	set desc = "Enter the queue to become a drone in the mortal realm"
	if ((usr.stat != 2) || !istype(usr, /mob/dead))
		boutput(usr, "Not when you're not dead!")
		return

	//Wire TODO
	//Check queue participation
	//Enter into queue
	//set dnr
	//remember dialogs

/mob/dead/observer/say_understands(var/other)
	return TRUE

/mob/dead/observer/verb/observe()
	set name = "Observe"
	set category = "Special Verbs"

	var/list/names = list()
	var/list/namecounts = list()
	var/list/creatures = list()

	//prefix list with option for alphabetic sorting
	var/const/SORT = "* Sort alphabetically..."
	creatures.Add(SORT)

	// Same thing you could do with the old auth disk. The bomb is equally important
	// and should appear at the top of any unsorted list  (Convair880).
	if (ticker && ticker.mode && istype(ticker.mode, /game_mode/nuclear))
		var/game_mode/nuclear/N = ticker.mode
		if (N.the_bomb && istype(N.the_bomb, /obj/machinery/nuclearbomb))
			var/name = "Nuclear bomb"
			if (name in names)
				namecounts[name]++
				name = "[name] ([namecounts[name]])"
			else
				names.Add(name)
				namecounts[name] = 1
			creatures[name] = N.the_bomb

	for (var/obj/observable/O in world)
		var/name = O.name
		if (name in names)
			namecounts[name]++
			name = "[name] ([namecounts[name]])"
		else
			names.Add(name)
			namecounts[name] = 1
		creatures[name] = O

	for (var/obj/item/ghostboard/GB in world)
		var/name = "Ouija board"
		if (name in names)
			namecounts[name]++
			name = "[name] ([namecounts[name]])"
		else
			names.Add(name)
			namecounts[name] = 1
		creatures[name] = GB

	for (var/obj/item/gnomechompski/G in world)
		var/name = "Gnome Chompski"
		if (name in names)
			namecounts[name]++
			name = "[name] ([namecounts[name]])"
		else
			names.Add(name)
			namecounts[name] = 1
		creatures[name] = G

	for (var/obj/cruiser_camera_dummy/CR in world)
		var/name = CR.name
		if (name in names)
			namecounts[name]++
			name = "[name] ([namecounts[name]])"
		else
			names.Add(name)
			namecounts[name] = 1
		creatures[name] = CR

	for (var/obj/item/reagent_containers/food/snacks/prison_loaf/L in world)
		var/name = L.name
		if (name != "strangelet loaf")
			continue
		if (name in names)
			namecounts[name]++
			name = "[name] ([namecounts[name]])"
		else
			names.Add(name)
			namecounts[name] = 1
		creatures[name] = L

	for (var/obj/machinery/bot/B in machines)
		var/name = "*[B.name]"
		if (name in names)
			namecounts[name]++
			name = "[name] ([namecounts[name]])"
		else
			names.Add(name)
			namecounts[name] = 1
		creatures[name] = B

	for (var/obj/item/storage/toolbox/memetic/HG in world)
		var/name = "His Grace"
		if (name in names)
			namecounts[name]++
			name = "[name] ([namecounts[name]])"
		else
			names.Add(name)
			namecounts[name] = 1
		creatures[name] = HG

	for (var/mob/M in sortmobs())
		if (!istype(M, /mob/living) && !istype(M, /mob/wraith))
			continue
		if (istype(M, /mob/living/carbon/human/secret))
			continue
		var/name = M.name
		if (name in names)
			namecounts[name]++
			name = "[name] ([namecounts[name]])"
		else
			names.Add(name)
			namecounts[name] = 1
		if (M.real_name && M.real_name != M.name)
			name += " \[[M.real_name]\]"
		if (istype(M, /mob/living) && M.stat == 2)
			name += " \[dead\]"
		creatures[name] = M

	/*for (var/mob/wraith/W in world)
		var/name = W.name
		if (name in names)
			namecounts[name]++
			name = "[name] ([namecounts[name]])"
		else
			names.Add(name)
			namecounts[name] = 1
		if (W.real_name && W.real_name != W.name)
			name += " \[[W.real_name]\]"
		creatures[name] = W*/

	var/eye_name = null

	// DOESN'T SEEM TO ADD ANY FUNCTIONALITY SO HEY, WHY WAS THIS EVEN HERE
	// if (is_admin)
	//  	eye_name = input("Please, select a player!", "Admin Observe", null, null) as null|anything in creatures
	// else
	//  	eye_name = input("Please, select a player!", "Observe", null, null) as null|anything in creatures

	eye_name = input("Please, select a target!", "Observe", null, null) as null|anything in creatures

	//sort alphabetically if user so chooses
	if (eye_name == SORT)
		creatures.Remove(SORT)

		for (var/i = 1; i <= creatures.len; i++)
			for (var/j = i+1; j <= creatures.len; j++)
				if (sorttext(creatures[i], creatures[j]) == -1)
					creatures.Swap(i, j)

		//redisplay sorted list
		eye_name = input("Please, select a target!", "Observe (Sorted)", null, null) as null|anything in creatures

	if (!eye_name)
		return

	var/atom/target = creatures[eye_name]

	var/mob/dead/target_observer/newobs = new(target)
	newobs.name = name
	newobs.real_name = real_name
	newobs.corpse = corpse
	newobs.my_ghost = src
	delete_on_logout_reset = delete_on_logout
	delete_on_logout = 0
	if (target.invisibility)
		newobs.see_invisible = target.invisibility
	if (corpse)
		corpse.ghost = newobs
	if (mind)
		mind.transfer_to(newobs)
	else if (client) //Wire: Fix for Cannot modify null.mob.
		client.mob = newobs
	set_loc(newobs)
