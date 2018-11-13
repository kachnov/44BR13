#define DRONE_LUM 2

/mob/living/silicon/ghostdrone
	icon = 'icons/mob/ghost_drone.dmi'
	icon_state = "drone-dead"

	max_health = 10 //weak as fuk
	density = 0 //no bumping into people, basically
	robot_talk_understand = 0 //we arent proper robots

	sound_fart = 'sound/misc/poo2_robot.ogg'
	flags = NODRIFT

	punchMessage = "whaps"
	kickMessage = "bonks"

	var/hud/ghostdrone/hud
	var/obj/item/cell/cell
	var/obj/item/device/radio/radio = null

	var/obj/item/active_tool = null
	var/list/obj/item/tools = list()

	//state tracking
	var/faceColor
	var/faceType
	var/charging = 0
	var/newDrone = 0

	var/jetpack = 1 //fuck whoever made this
	var/effects/system/ion_trail_follow/ion_trail = null
	var/jeton = 0

	var/light/light

	//gimmicky things
	var/obj/item/clothing/head/hat = null
	var/obj/item/clothing/suit/bedsheet/bedsheet = null

	var/removeStunEffects = 0
	var/hasStunEffects = 0


	New()
		..()
		ghost_drones += src
		name = "Drone [rand(1,9)]*[rand(10,99)]"
		real_name = name
		hud = new(src)
		attach_hud(hud)

		var/obj/item/cell/cerenkite/charged/CELL = new /obj/item/cell/cerenkite/charged(src)
		cell = CELL

		light = new /light/point
		light.set_brightness(0.5)
		light.attach(src)

		health = max_health
		botcard.access = list(access_maint_tunnels)
		radio = new /obj/item/device/radio(src)
		ears = radio
		//zone_sel = new(src)
		//attach_hud(zone_sel)
		ion_trail = new /effects/system/ion_trail_follow()
		ion_trail.set_up(src)

		//Attach shit to tools
		tools = list(
			new /obj/item/magtractor(src),
			new /obj/item/rcd(src),
			new /obj/item/crowbar(src),
			new /obj/item/screwdriver(src),
			new /obj/item/device/t_scanner(src),
			new /obj/item/device/multitool(src),
			new /obj/item/electronics/soldering(src),
			new /obj/item/wrench(src),
			new /obj/item/weldingtool(src),
			new /obj/item/wirecutters(src),
			new /obj/item/device/flashlight(src),
		)

		//Make all the tools un-drop-able (to closets/tables etc)
		for (var/obj/item/O in tools)
			O.cant_drop = 1

		spawn (0)
			out(src, "<strong>Use \"say ; (message)\" to speak to fellow drones through the spooky power of spirits within machines.</strong>")
			show_laws_drone()

	Life(controller/process/mobs/parent)
		set invisibility = 0

		if (..(parent))
			return

		if (transforming)
			return

		for (var/obj/item/I in src)
			if (!I.material) continue
			I.material.triggerOnLife(src, I)

		if (stat != 2) //alive
			use_power()

			if (stat != 2) //still alive after power usage
				if (paralysis || stunned || weakened) //Stunned etc.
					if (stat == 0) lastgasp() // calling lastgasp() here because we just got knocked out
					stat = 1
					if (get_eye_blurry())
						change_eye_blurry(-1)
					if (dizziness)
						dizziness--
					if (stunned > 0)
						stunned--
						if (stunned <= 0)
							removeStunEffects = 1
						setStunnedEffects()
					if (weakened > 0)
						weakened--
					if (paralysis > 0)
						paralysis--
						blinded = 1
					else blinded = 0

				if (hud)
					hud.update_environment()
					hud.update_health()
					hud.update_tools()

				if (client)
					updateStatic()
					updateOverlaysClient(client)
					antagonist_overlay_refresh(0, 0)

		if (observers.len)
			for (var/mob/x in observers)
				if (x.client)
					updateOverlaysClient(x.client)

	proc/updateStatic()
		if (!client)
			return
		client.images.Remove(mob_static_icons)
		for (var/image/I in mob_static_icons)
			if (!I || !I.loc || !src)
				continue
			if (I.loc.invisibility && I.loc != src.loc)
				continue
			else
				client.images.Add(I)

	death(gibbed)
		logTheThing("combat", src, null, "was destroyed at [log_loc(src)].")
		stat = 2
		ghost_drones -= src
		if (client)
			client.images.Remove(mob_static_icons)

			var/mob/dead/observer/ghost = ghostize()
			ghost.icon = 'icons/mob/ghost_drone.dmi'
			ghost.icon_state = "drone-ghost"

			//This stuff is hacky but I don't feel like messing with observer New code so fuck it
			if (!oldmob) //Prevents re-entering a ghostdrone corpse
				ghost.verbs -= /mob/dead/observer/proc/reenter_corpse
			ghost.name = (oldname ? oldname : real_name)
			ghost.real_name = (oldname ? oldname : real_name)

		//So the drone cant pick up an item and then die, sending the item ~to the void~
		var/obj/item/magtractor/mag = locate(/obj/item/magtractor) in tools
		var/obj/item/magHeld = mag.holding ? mag.holding : null
		if (magHeld) magHeld.set_loc(get_turf(src))

		if (gibbed)
			visible_message("<span class='combat'>[name] explodes in a shower of lost hopes and dreams.</span>")
			var/turf/T = get_ranged_target_turf(src, pick(alldirs), 3)
			if (magHeld) magHeld.throw_at(T, 3, 1) //flying...anything
			if (hat) takeoffHat(pick(alldirs)) //flying hats
			if (bedsheet) //flying bedsheets
				bedsheet.set_loc(get_turf(src))
				bedsheet.throw_at(T, 3, 1)
			..(1)
		else
			lastgasp()
			var/msg
			switch(rand(1,3))
				if (1)
					msg = "[name] [pick("falls", "crashes", "sinks")] to the ground, ghost-less."
				if (2)
					msg = "The spirit powering [name] packs up and leaves."
				if (3)
					msg = "[name]'s scream's gain echo and lose their electronic modulation as it's soul is ripped monstrously from the cold metal body it once inhabited."

			visible_message("<span class='combat'>[msg]</span>")
			if (hat) takeoffHat()
			updateSprite()
			..()

	dispose()
		..()
		if (src in ghost_drones)
			ghost_drones -= src
		if (src in available_ghostdrones)
			available_ghostdrones -= src

	Del()
		if (src in ghost_drones)
			ghost_drones -= src
		if (src in available_ghostdrones)
			available_ghostdrones -= src
		..()

	//Apparently leaving this on made the parent updatehealth set health to max_health in all cases, because there's no such thing as bruteloss and
	// so on with this mob
	updatehealth()
		return

	full_heal()
		var/before = stat
		..()
		if (before == 2 && stat < 2) //if we were dead, and now arent
			updateSprite()

	TakeDamage(zone, brute, burn)
		if (nodamage) return //godmode
		health -= max(0, brute)
		if (stat != 2 && health <= 0) //u ded
			if (brute >= max_health)
				gib()
			else
				death()
		return

	examine()
		..()
		var/msg = "*---------*<br>"

		if (stat == 2)
			msg += "<span style'color:red'>It looks dead and lifeless</span><br>"
			msg += "*---------*"
			return out(usr, msg)

		msg += "<span style='color: blue;'>"
		if (active_tool)
			msg += "[src] is holding a little [bicon(active_tool)] [active_tool]"
			if (istype(active_tool, /obj/item/magtractor) && active_tool:holding)
				msg += ", containing \an [active_tool:holding]"
			msg += "<br>"
		msg += "[src] has a power charge of [bicon(cell)] [cell.charge]/[cell.maxcharge]<br>"
		msg += "</span>"

		if (health < max_health)
			if (health < (max_health / 2))
				msg += "<span style='color:red'>It's rather badly damaged. It probably needs some wiring replaced inside.</span><br>"
			else
				msg += "<span style='color:red'>It's a bit damaged. It looks like it needs some welding done.</span><br>"

		msg += "*---------*"
		out(usr, msg)

	Login()
		..()
		if (stat == 0)
			visible_message("<span style='color: blue'>[name] comes online.</span>", "<span style='color: blue'>You come online!</span>")
			updateSprite()

	Logout()
		..()
		updateSprite()

	proc/setStunnedEffects()
		if (!stunned || removeStunEffects)
			setFace(faceType, faceColor)
			UpdateOverlays(null, "dizzy")
			removeStunEffects = 0
			hasStunEffects = 0
			return

		else if (!hasStunEffects)
			var/image/myFace = SafeGetOverlayImage("face", icon, "drone-dizzy", MOB_OVERLAY_BASE)
			if (myFace)
				if (myFace.color != faceColor)
					myFace.color = faceColor
				UpdateOverlays(myFace, "face")

			var/image/dizzyStars = SafeGetOverlayImage("dizzy", icon, "dizzy", MOB_OVERLAY_BASE+1)
			if (dizzyStars)
				UpdateOverlays(dizzyStars, "dizzy")
			hasStunEffects = 1

	//Change that faaaaace
	proc/setFace(type = "happy", color = "#7fc5ed")
		if (charging || stunned) //Save state but don't apply changes if charging or stunned
			faceType = type
			faceColor = color
			return TRUE

		if (bedsheet) //No overlays or lumin for drones under a sheet
			UpdateOverlays(null, "face")
			icon_state = "g_drone-[type]"
			return TRUE

		/*var/image/newFace = GetOverlayImage("face")
		var/forceNew = 0
		if (!newFace)
			forceNew = 1
			newFace = image(icon, "drone-[type]")
		newFace.layer = MOB_OVERLAY_BASE

		if (type != faceType) //Type is new
			faceType = type
			newFace.icon_state = "drone-[type]"*/

		var/image/newFace = SafeGetOverlayImage("face", icon, "drone-[type]", MOB_OVERLAY_BASE)
		if (!newFace) // this should never be the case but let's be careful anyway!!
			faceType = type
			faceColor = color
			return TRUE

		if (color != faceColor || newFace.color != color)//forceNew) //Color is new
			faceColor = color
			newFace.color = color
			updateHoverDiscs(color) //ok we're also gonna color hoverdiscs too because hell yeah kickin rad

		if (length(color) == 7) //Set our luminosity color, if valid
			var/colors = GetColors(faceColor)
			colors[1] = colors[1] / 255
			colors[2] = colors[2] / 255
			colors[3] = colors[3] / 255
			light.set_color(colors[1], colors[2], colors[3])

		light.enable()
		UpdateOverlays(newFace, "face")
		return TRUE

	proc/setFaceDialog()
		var/newFace = input(usr, "Select your faceplate", "Drone", faceType) as null|anything in list("Happy", "Sad", "Mad")
		if (!newFace) return FALSE
		var/newColor = input(usr, "Select your faceplate color", "Drone", faceColor) as null|color
		if (!newFace && !newColor) return FALSE
		newFace = (newFace ? lowertext(newFace) : faceType)
		newColor = (newColor ? newColor : faceColor)
		setFace(type = newFace, color = newColor)
		return TRUE

	proc/updateHoverDiscs(color = "#7fc5ed")
		var/image/newHover = GetOverlayImage("hoverDiscs")
		if (!newHover) newHover = image('icons/effects/effects.dmi', "hoverdiscs")

		newHover.color = color
		newHover.pixel_y = -5
		newHover.layer = MOB_EFFECT_LAYER

		UpdateOverlays(newHover, "hoverDiscs")
		return TRUE

	proc/updateSprite()
		if (stat == 2 || !client || charging || newDrone)
			light.disable()
			if (!bedsheet)
				if (newDrone)
					icon_state = "drone-idle"
				else if (charging)
					icon_state = "drone-charging"
				else // dead or no client
					icon_state = "drone-dead"
			else
				icon_state = "g_drone-dead"
			if (stat != 2)
				light.set_color(0.94, 0.88, 0.12) //yellow
				light.enable()
/*			if (stat == 2 || !client)
				if (bedsheet)
					icon_state = "g_drone-dead"
				else
					icon_state = "drone-dead"
			else //Being charged or newdrone
				if (!bedsheet) //Until we get a bedsheet charging icon
					if (charging)
						icon_state = "drone-charging"
					else if (newDrone)
						icon_state = "drone-idle"

				light.set_color(0.94, 0.88, 0.12) //yellow
				light.enable()
*/
			UpdateOverlays(null, "face")
			UpdateOverlays(null, "hoverDiscs")
			animate(src) //stop bumble animation
		else if (client)
			//New drone stuff
			if (!faceType)
				setFace(type = "happy", color = "#7fc5ed") //defaults

			if (health >= 0)
				animate_bumble(src, floatspeed = 15, Y1 = 2, Y2 = -2) //yayyyyy bumble anim
				if (bedsheet)
					icon_state = "g_drone-[faceType]"
				else
					icon_state = "drone"

				//damage states to go here

	hand_attack(atom/target, params)
		//A thing to stop drones interacting with pick-up-able things by default
		if (target && istype(target, /obj/item))
			var/obj/item/I = target
			if (!I.anchored)
				return FALSE

		..()

	click(atom/target, params)
		if (params["alt"])
			target.examine() // in theory, usr should be us, this is shit though
			return

		if (in_point_mode)
			point(target)
			toggle_point_mode()
			return

		var/obj/item/item = target
		if (istype(item) && item == equipped())
			if (!disable_next_click && world.time < next_click)
				return
			item.attack_self(src)
			return

		if (params["ctrl"])
			var/atom/movable/movable = target
			if (istype(movable))
				movable.pull()
			return

		if (get_dist(src, target) > 0) // temporary fix for cyborgs turning by clicking
			dir = get_dir(src, target)

		var/obj/item/W = equipped()
		//if (W.useInnerItem && W.contents.len > 0)
		//	W = pick(W.contents)

		if ((!disable_next_click || ismob(target) || (target && target.flags & USEDELAY) || (W && W.flags & USEDELAY)) && world.time < next_click)
			return next_click - world.time

		var/reach = can_reach(src, target)
		if (reach || (W && (W.flags & EXTRADELAY))) //Fuck you, magic number prickjerk
			if (!disable_next_click || ismob(target))
				next_click = world.time + 10
			if (W && istype(W))
				weapon_attack(target, W, reach, params)
			else if (!W)
				hand_attack(target, params)
		else if (!reach && W)
			if (!disable_next_click || ismob(target))
				next_click = world.time + 10
			var/pixelable = isturf(target)
			if (!pixelable)
				if (istype(target, /atom/movable) && isturf(target:loc))
					pixelable = 1
			if (pixelable)
				W.pixelaction(target, params, src, 0)
		else if (!W)
			hand_range_attack(target, params)

	Stat()
		..()
		if (cell)
			stat("Charge Left:", "[cell.charge]/[cell.maxcharge]")
		else
			stat("No Cell Inserted!")

	Bump(atom/movable/AM as mob|obj, yes)
		spawn ( 0 )
			if ((!( yes ) || now_pushing))
				return
			now_pushing = 1
			if (ismob(AM))
				var/mob/tmob = AM
				if (istype(tmob, /mob/living/carbon/human) && tmob.bioHolder && tmob.bioHolder.HasEffect("fat"))
					if (prob(20))
						for (var/mob/M in viewers(src, null))
							if (M.client)
								boutput(M, "<span style=\"color:red\"><strong>[src] fails to push [tmob]'s fat ass out of the way.</strong></span>")
						now_pushing = 0
						unlock_medal("That's no moon, that's a GOURMAND!", 1)
						return
			now_pushing = 0
			//..()
			if (!istype(AM, /atom/movable))
				return
			if (!now_pushing)
				now_pushing = 1
				if (!AM.anchored)
					var/t = get_dir(src, AM)
					step(AM, t)
				now_pushing = null
			if (AM)
				AM.last_bumped = world.timeofday
				AM.Bumped(src)
			return
		return

	//Four very important procs follow
	proc/putonHat(obj/item/clothing/head/W as obj, mob/user as mob)
		hat = W
		W.set_loc(src)

		UpdateOverlays(null, "hat")
		var/image/hatImage = image(icon = W.icon, icon_state = W.icon_state, layer = MOB_OVERLAY_BASE)
		hatImage.pixel_y = 5
		hatImage.transform *= 0.85
		hatImage.layer = EFFECTS_LAYER_4
		UpdateOverlays(hatImage, "hat")
		return TRUE

	proc/takeoffHat(forcedDir = null)
		UpdateOverlays(null, "hat")
		hat.set_loc(get_turf(src))
		if (forcedDir)
			var/turf/T = get_ranged_target_turf(src, forcedDir, 3)
			hat.throw_at(T, 3, 1)

		hat = null
		return TRUE

	proc/putonSheet(obj/item/clothing/suit/bedsheet/W as obj, mob/user as mob)
		W.set_loc(src)
		bedsheet = W
		setFace(type = faceType, color = faceColor) //removes face overlay and lumin (also sets icon)
		return TRUE

	proc/takeoffSheet()
		bedsheet.set_loc(get_turf(src))
		bedsheet = null
		if (stat == 0) //alive
			setFace(type = faceType, color = faceColor) //to re-init face overlay and lumin
			icon_state = "drone"
		else //dead
			icon_state = "drone-dead"
		return TRUE

	attackby(obj/item/W as obj, mob/user as mob)
		if (stat != 0) return
		if (istype(W, /obj/item/weldingtool))
			var/obj/item/weldingtool/WELD = W
			if (user.a_intent == INTENT_HARM)
				if (WELD.welding)
					user.visible_message("<span style=\"color:red\"><strong>[user] burns [src] with [W]!</strong></span>")
					damage_heat(WELD.force)
				else
					user.visible_message("<span style=\"color:red\"><strong>[user] beats [src] with [W]!</strong></span>")
					damage_blunt(WELD.force)
			else
				if (health >= max_health)
					boutput(user, "<span style=\"color:red\">It isn't damaged!</span>")
					return
				if (get_x_percentage_of_y(health,max_health) < 33)
					boutput(user, "<span style=\"color:red\">You need to use wire to fix the cabling first.</span>")
					return
				if (WELD.get_fuel() > 1)
					health = max(1,min(health + 10,max_health))
					WELD.use_fuel(1)
					playsound(loc, "sound/items/Welder.ogg", 50, 1)
					user.visible_message("<strong>[user]</strong> uses [WELD] to repair some of [src]'s damage.")
					if (health == max_health)
						boutput(user, "<span style=\"color:blue\"><strong>[src] looks fully repaired!</strong></span>")
				else
					boutput(user, "<span style=\"color:red\">You need more welding fuel!</span>")

		else if (istype(W,/obj/item/cable_coil))
			if (health >= max_health)
				boutput(user, "<span style=\"color:red\">It isn't damaged!</span>")
				return
			var/obj/item/cable_coil/C = W
			if (get_x_percentage_of_y(health,max_health) >= 33)
				boutput(usr, "<span style=\"color:red\">The cabling looks fine. Use a welder to repair the rest of the damage.</span>")
				return
			C.use(1)
			health = max(1,min(health + 10,max_health))
			user.visible_message("<strong>[user]</strong> uses [C] to repair some of [src]'s cabling.")
			playsound(loc, "sound/items/Deconstruct.ogg", 50, 1)
			if (health >= 50)
				boutput(user, "<span style=\"color:blue\">The wiring is fully repaired. Now you need to weld the external plating.</span>")

		else if (istype(W, /obj/item/clothing/head))
			if (hat)
				boutput(user, "<span style=\"color:red\">[src] is already wearing a hat!</span>")
				return

			user.drop_item()
			putonHat(W, user)
			if (user == src)

			else
				user.visible_message("<strong>[user]</strong> gently places a hat on [src]!", "You gently place a hat on [src]!")
			return

		else if (istype(W, /obj/item/clothing/suit/bedsheet))
			if (bedsheet)
				boutput(user, "<span style=\"color:red\">There is already a sheet draped over [src]! Two sheets would be ridiculous!</span>")
				return

			user.drop_item()
			putonSheet(W, user)
			user.visible_message("<strong>[user]</strong> drapes a sheet over [src]!", "You cover [src] with a sheet!")
			return

		else
			return ..(W, user)

	attack_hand(mob/user)
		if (!user.stat)
			switch(user.a_intent)
				if (INTENT_HELP) //Friend person
					playsound(loc, 'sound/weapons/thudswoosh.ogg', 50, 1, -2)
					user.visible_message("<span style=\"color:blue\">[user] gives [src] a [pick_string("descriptors.txt", "borg_pat")] pat on the [pick("back", "head", "shoulder")].</span>")
				if (INTENT_DISARM) //Shove
					spawn (0) playsound(loc, 'sound/weapons/punchmiss.ogg', 40, 1)
					user.visible_message("<span style=\"color:red\"><strong>[user] shoves [src]! [prob(40) ? pick_string("descriptors.txt", "jerks") : null]</strong></span>")
					if (hat)
						user.visible_message("<strong>[user]</strong> knocks \the [hat] off [src]!", "You knock the hat off [src]!")
						takeoffHat()
					else if (bedsheet)
						user.visible_message("<strong>[user]</strong> pulls the sheet off [src]!", "You pull the sheet off [src]!")
						takeoffSheet()
				if (INTENT_GRAB) //Shake
					playsound(loc, 'sound/weapons/thudswoosh.ogg', 30, 1, -2)
					user.visible_message("<span style=\"color:red\">[user] shakes [src] [pick_string("descriptors.txt", "borg_shake")]!</span>")
				if (INTENT_HARM) //Dumbo
					playsound(loc, 'sound/effects/metal_bang.ogg', 60, 1)
					user.visible_message("<span style=\"color:red\"><strong>[user] punches [src]! What [pick_string("descriptors.txt", "borg_punch")]!</span>", "<span style=\"color:red\"><strong>You punch [src]![prob(20) ? " Turns out they were made of metal!" : null] Ouch!</strong></span>")
					random_brute_damage(user, rand(2,5))
					if (prob(10)) user.show_text("Your hand hurts...", "red")

			add_fingerprint(user)

	weapon_attack(atom/target, obj/item/W, reach, params)
		//Prevents drones attacking other people hahahaaaaaaa
		if (isliving(target) && !isghostdrone(target))
			out(src, "<span class='combat bold'>Your internal law subroutines kick in and prevent you from using [W] on [target]!</span>")
			return
		else
			..(target, W, reach, params)

	proc/store_active_tool()
		if (!active_tool)
			return
		active_tool.dropped(src) // Handle light datums and the like.
		active_tool = null
		hud.set_active_tool(0)
		hud.update_tools()

	equipped()
		if (!active_tool)
			return null
		return active_tool

	proc/uneq_slot()
		if (active_tool)
			if (istype(active_tool, /obj/item/magtractor) && active_tool:holding)
				actions.stopId("magpickerhold", src)
			if (isitem(active_tool))
				active_tool.dropped(src) // Handle light datums and the like.
		active_tool = null
		hud.set_active_tool(null)
		hud.update_tools()
		hud.update_equipment()

	proc/use_power()
		if (cell)
			if (cell.charge <= 0)
				if (stat == 0)
					out(src, "<span class='combat bold'>You have run out of power!</span>")
					death()
			else if (cell.charge <= 100)
				active_tool = null

				uneq_slot()
				cell.use(1)
			else
				var/power_use_tally = 2
				if (active_tool)
					power_use_tally += 3
					if (istype(active_tool, /obj/item/magtractor) && active_tool:highpower)
						power_use_tally += 15
				cell.use(power_use_tally)
				blinded = 0
				stat = 0
		else //This basically should never happen with ghostdrones
			if (stat == 0)
				death()

		hud.update_charge()

	Move(a, b, flag)
		if (buckled) return

		if (restrained()) pulling = null

		var/t7 = 1
		if (restrained())
			for (var/mob/M in range(src, 1))
				if ((M.pulling == src && M.stat == 0 && !( M.restrained() ))) t7 = null
		if ((t7 && (pulling && ((get_dist(src, pulling) <= 1 || pulling.loc == loc) && (client && client.moving)))))
			var/turf/T = loc
			. = ..()

			if (pulling && pulling.loc)
				if (!( isturf(pulling.loc) ))
					pulling = null
					return
				else
					if (Debug)
						diary <<"pulling disappeared? at [__LINE__] in mob.dm - pulling = [pulling]"
						diary <<"REPORT THIS"

			if (pulling && pulling.anchored)
				pulling = null
				return

			if (!restrained())
				var/diag = get_dir(src, pulling)
				if ((diag - 1) & diag)
				else diag = null

				if ((get_dist(src, pulling) > 1 || diag))
					if (ismob(pulling))
						var/mob/M = pulling
						var/ok = 1
						if (locate(/obj/item/grab, M.grabbed_by))
							if (prob(75))
								var/obj/item/grab/G = pick(M.grabbed_by)
								if (istype(G, /obj/item/grab))
									for (var/mob/O in viewers(M, null))
										O.show_message(text("<span style=\"color:red\">[G.affecting] has been pulled from [G.assailant]'s grip by [src]</span>"), 1)
									qdel(G)
							else
								ok = 0
							if (locate(/obj/item/grab, M.grabbed_by.len))
								ok = 0
						if (ok)
							var/t = M.pulling
							M.pulling = null
							step(pulling, get_dir(pulling.loc, T))
							if (istype(pulling, /mob/living))
								var/mob/living/some_idiot = pulling
								if (some_idiot.buckled && !some_idiot.buckled.anchored)
									step(some_idiot.buckled, get_dir(some_idiot.buckled.loc, T))
							M.pulling = t
					else
						if (pulling)
							step(pulling, get_dir(pulling.loc, T))
							if (istype(pulling, /mob/living))
								var/mob/living/some_idiot = pulling
								if (some_idiot.buckled && !some_idiot.buckled.anchored)
									step(some_idiot.buckled, get_dir(some_idiot.buckled.loc, T))
		else
			pulling = null
			hud.update_pulling()
			. = ..()

		if (s_active && !(s_active.master in src))
			detach_hud(s_active)
			s_active = null

	drop_item_v()
		return

	emote(var/act, var/voluntary = 1)
		var/param = null
		if (findtext(act, " ", 1, null))
			var/t1 = findtext(act, " ", 1, null)
			param = copytext(act, t1 + 1, length(act) + 1)
			act = copytext(act, 1, t1)

		var/m_type = 1
		var/m_anim = 0
		var/message

		switch(lowertext(act))
			if ("help")
				show_text("To use emotes, simply enter \"*(emote)\" as the entire content of a say message. Certain emotes can be targeted at other characters - to do this, enter \"*emote (name of character)\" without the brackets.")
				show_text("For a list of all emotes, use *list. For a list of basic emotes, use *listbasic. For a list of emotes that can be targeted, use *listtarget.")

			if ("list")
				show_text("Basic emotes:")
				show_text("clap, flap, aflap, twitch, twitch_s, scream, birdwell, fart, flip, custom, customv, customh")
				show_text("Targetable emotes:")
				show_text("salute, bow, hug, wave, glare, stare, look, leer, nod, point")

			if ("listbasic")
				show_text("clap, flap, aflap, twitch, twitch_s, scream, birdwell, fart, flip, custom, customv, customh")

			if ("listtarget")
				show_text("salute, bow, hug, wave, glare, stare, look, leer, nod, point")

			if ("salute","bow","hug","wave","glare","stare","look","leer","nod")
				// visible targeted emotes
				if (!restrained())
					var/M = null
					if (param)
						for (var/mob/A in view(null, null))
							if (ckey(param) == ckey(A.name))
								M = A
								break
					if (!M)
						param = null

					act = lowertext(act)
					if (param)
						switch(act)
							if ("bow","wave","nod")
								message = "<strong>[src]</strong> [act]s to [param]."
							if ("glare","stare","look","leer")
								message = "<strong>[src]</strong> [act]s at [param]."
							else
								message = "<strong>[src]</strong> [act]s [param]."
					else
						switch(act)
							if ("hug")
								message = "<strong>[src]</strong> [act]s itself."
							else
								message = "<strong>[src]</strong> [act]s."
				else
					message = "<strong>[src]</strong> struggles to move."
				m_type = 1

			if ("point")
				if (!restrained())
					var/mob/M = null
					if (param)
						for (var/atom/A as mob|obj|turf|area in view(null, null))
							if (ckey(param) == ckey(A.name))
								M = A
								break

					if (!M)
						message = "<strong>[src]</strong> points."
					else
						point(M)

					if (M)
						message = "<strong>[src]</strong> points to [M]."
					else
				m_type = 1

			if ("panic","freakout")
				if (!restrained())
					message = "<strong>[src]</strong> enters a state of hysterical panic!"
				else
					message = "<strong>[src]</strong> starts writhing around in manic terror!"
				m_type = 1

			if ("clap")
				if (!restrained())
					message = "<strong>[src]</strong> claps."
					m_type = 2

			if ("flap")
				if (!restrained())
					message = "<strong>[src]</strong> flaps its wings."
					m_type = 2

			if ("aflap")
				if (!restrained())
					message = "<strong>[src]</strong> flaps its wings ANGRILY!"
					m_type = 2

			if ("custom")
				var/input = sanitize(input("Choose an emote to display."))
				var/input2 = input("Is this a visible or hearable emote?") in list("Visible","Hearable")
				if (input2 == "Visible")
					m_type = 1
				else if (input2 == "Hearable")
					m_type = 2
				else
					alert("Unable to use this emote, must be either hearable or visible.")
					return
				message = "<strong>[src]</strong> [input]"

			if ("customv")
				if (!param)
					return
				message = "<strong>[src]</strong> [param]"
				m_type = 1

			if ("customh")
				if (!param)
					return
				message = "<strong>[src]</strong> [param]"
				m_type = 2

			if ("smile","grin","smirk","frown","scowl","grimace","sulk","pout","blink","nod","shrug","think","ponder","contemplate")
				// basic visible single-word emotes
				message = "<strong>[src]</strong> [act]s."
				m_type = 1

			if ("flipout")
				message = "<strong>[src]</strong> flips the fuck out!"
				m_type = 1

			if ("rage","fury","angry")
				message = "<strong>[src]</strong> becomes utterly furious!"
				m_type = 1

			if ("twitch")
				message = "<strong>[src]</strong> twitches."
				m_type = 1
				spawn (0)
					var/old_x = pixel_x
					var/old_y = pixel_y
					pixel_x += rand(-2,2)
					pixel_y += rand(-1,1)
					sleep(2)
					pixel_x = old_x
					pixel_y = old_y

			if ("twitch_v","twitch_s")
				message = "<strong>[src]</strong> twitches violently."
				m_type = 1
				spawn (0)
					var/old_x = pixel_x
					var/old_y = pixel_y
					pixel_x += rand(-3,3)
					pixel_y += rand(-1,1)
					sleep(2)
					pixel_x = old_x
					pixel_y = old_y

			if ("birdwell", "burp")
				if (emote_check(voluntary, 50))
					message = "<strong>[src]</strong> birdwells."
					playsound(loc, "sound/vox/birdwell.ogg", 50, 1)

			if ("scream")
				if (emote_check(voluntary, 50))
					if (narrator_mode)
						playsound(loc, 'sound/vox/scream.ogg', 50, 1, 0, get_age_pitch())
					else
						playsound(get_turf(src), sound_scream, 80, 0, 0, get_age_pitch())
					message = "<strong>[src]</strong> screams!"

			if ("johnny")
				var/M
				if (param)
					M = adminscrub(param)
				if (!M)
					param = null
				else
					message = "<strong>[src]</strong> says, \"[M], please. He had a family.\" [name] takes a drag from a cigarette and blows its name out in smoke."
					m_type = 2

			if ("flip")
				if (emote_check(voluntary, 50))
					if (narrator_mode)
						playsound(loc, pick('sound/vox/deeoo.ogg', 'sound/vox/dadeda.ogg'), 50, 1)
					else
						playsound(loc, pick(sound_flip1, sound_flip2), 50, 1)
					message = "<strong>[src]</strong> does a flip!"
					m_anim = 1
					if (prob(50))
						animate_spin(src, "R", 1, 0)
					else
						animate_spin(src, "L", 1, 0)

					for (var/mob/living/M in view(1, null))
						if (M == src)
							continue
						message = "<strong>[src]</strong> beep-bops at [M]."
						break

			if ("fart")
				if (emote_check(voluntary))
					m_type = 2
					var/fart_on_other = 0
					for (var/mob/living/M in loc)
						if (M == src || !M.lying)
							continue
						message = "<span style=\"color:red\"><strong>[src]</strong> farts in [M]'s face!</span>"
						fart_on_other = 1
						break
					if (!fart_on_other)
						switch (rand(1, 48))
							if (1) message = "<strong>[src]</strong> lets out a girly little 'toot' from his fart synthesizer."
							if (2) message = "<strong>[src]</strong> farts loudly!"
							if (3) message = "<strong>[src]</strong> lets one rip!"
							if (4) message = "<strong>[src]</strong> farts! It sounds wet and smells like rotten eggs."
							if (5) message = "<strong>[src]</strong> farts robustly!"
							if (6) message = "<strong>[src]</strong> farted! It reminds you of your grandmother's queefs."
							if (7) message = "<strong>[src]</strong> queefed out his metal ass!"
							if (8) message = "<strong>[src]</strong> farted! It reminds you of your grandmother's queefs."
							if (9) message = "<strong>[src]</strong> farts a ten second long fart."
							if (10) message = "<strong>[src]</strong> groans and moans, farting like the world depended on it."
							if (11) message = "<strong>[src]</strong> breaks wind!"
							if (12) message = "<strong>[src]</strong> synthesizes a farting sound."
							if (13) message = "<strong>[src]</strong> generates an audible discharge of intestinal gas."
							if (14) message = "<span style=\"color:red\"><strong>[src]</strong> is a farting motherfucker!!!</span>"
							if (15) message = "<span style=\"color:red\"><strong>[src]</strong> suffers from flatulence!</span>"
							if (16) message = "<strong>[src]</strong> releases flatus."
							if (17) message = "<strong>[src]</strong> releases gas generated in his digestive tract, his stomach and his intestines. <span style=\"color:red\"><strong>It stinks way bad!</strong></span>"
							if (18) message = "<strong>[src]</strong> farts like your mom used to!"
							if (19) message = "<strong>[src]</strong> farts. It smells like Soylent Surprise!"
							if (20) message = "<strong>[src]</strong> farts. It smells like pizza!"
							if (21) message = "<strong>[src]</strong> farts. It smells like George Melons' perfume!"
							if (22) message = "<strong>[src]</strong> farts. It smells like atmos in here now!"
							if (23) message = "<strong>[src]</strong> farts. It smells like medbay in here now!"
							if (24) message = "<strong>[src]</strong> farts. It smells like the bridge in here now!"
							if (25) message = "<strong>[src]</strong> farts like a pubby!"
							if (26) message = "<strong>[src]</strong> farts like a goone!"
							if (27) message = "<strong>[src]</strong> farts so hard he's certain poop came out with it, but dares not find out."
							if (28) message = "<strong>[src]</strong> farts delicately."
							if (29) message = "<strong>[src]</strong> farts timidly."
							if (30) message = "<strong>[src]</strong> farts very, very quietly. The stench is OVERPOWERING."
							if (31) message = "<strong>[src]</strong> farts and says, \"Mmm! Delightful aroma!\""
							if (32) message = "<strong>[src]</strong> farts and says, \"Mmm! Sexy!\""
							if (33) message = "<strong>[src]</strong> farts and fondles his own buttocks."
							if (34) message = "<strong>[src]</strong> farts and fondles YOUR buttocks."
							if (35) message = "<strong>[src]</strong> fart in he own mouth. A shameful [src]."
							if (36) message = "<strong>[src]</strong> farts out pure plasma! <span style=\"color:red\"><strong>FUCK!</strong></span>"
							if (37) message = "<strong>[src]</strong> farts out pure oxygen. What the fuck did he eat?"
							if (38) message = "<strong>[src]</strong> breaks wind noisily!"
							if (39) message = "<strong>[src]</strong> releases gas with the power of the gods! The very station trembles!!"
							if (40) message = "<strong>[src] <span style=\"color:red\">f</span><span style=\"color:blue\">a</span>r<span style=\"color:red\">t</span><span style=\"color:blue\">s</span>!</strong>"
							if (41) message = "<strong>[src] shat his pants!</strong>"
							if (42) message = "<strong>[src] shat his pants!</strong> Oh, no, that was just a really nasty fart."
							if (43) message = "<strong>[src]</strong> is a flatulent whore."
							if (44) message = "<strong>[src]</strong> likes the smell of his own farts."
							if (45) message = "<strong>[src]</strong> doesnt wipe after he poops."
							if (46) message = "<strong>[src]</strong> farts! Now he smells like Tiny Turtle."
							if (47) message = "<strong>[src]</strong> burps! He farted out of his mouth!! That's Showtime's style, baby."
							if (48) message = "<strong>[src]</strong> laughs! His breath smells like a fart."

					if (narrator_mode)
						playsound(loc, 'sound/vox/fart.ogg', 50, 1)
					else
						playsound(loc, sound_fart, 50, 1)
					#ifdef DATALOGGER
					game_stats.Increment("farts")
					#endif
			else
				show_text("Invalid Emote: [act]")
				return

		if ((message && stat == 0))
			logTheThing("say", src, null, "EMOTE: [message]")
			if (m_type & 1)
				for (var/mob/living/silicon/ghostdrone/O in viewers(src, null))
					O.show_message(message, m_type)
			else
				for (var/mob/living/silicon/ghostdrone/O in hearers(src, null))
					O.show_message(message, m_type)

			if (m_anim) //restart our passive animation
				spawn (10)
					animate_bumble(src, floatspeed = 15, Y1 = 2, Y2 = -2)

		return

	/*
	//No hearing any other talk ok
	say_understands(mob/other, forced_language)
		if (istype(other, /mob/living/silicon/ghostdrone))
			return TRUE
		else
			return FALSE
	*/

	say_quote(message)
		var/speechverb = pick("beeps", "boops", "buzzes", "bloops", "transmits")
		return "[speechverb], \"[message]\""

	proc/nohear_message()
		return pick("beeps", "boops", "warbles incomprehensibly", "beeps sadly", "beeeeeeeeeps")

	proc/drone_talk(message)
		message = html_encode(say_quote(message))
		var/rendered = "<span class='game ghostdronesay'>"
		rendered += "<span class='name' data-ctx='\ref[mind]'>[name]</span> "
		rendered += "<span class='message'>[message]</span>"
		rendered += "</span>"

		var/nohear = "<span class='game say'><span class='name' data-ctx='\ref[mind]'>[name]</span> <span class='message'>[nohear_message()]</span></span>"

		for (var/mob/M in mobs)
			if (istype(M, /mob/new_player))
				continue

			if (M.client && (M in hearers(src) || M.client.holder))
				var/thisR = rendered
				if (istype(M, /mob/living/silicon/ghostdrone) || M.client.holder)
					if (M.client.holder && mind)
						thisR = "<span class='adminHearing' data-ctx='[M.client.chatOutput.ctxFlag]'>[rendered]</span>"
				else
					thisR = nohear

				M.show_message(thisR, 2)

	proc/drone_broadcast(message)
		message = html_encode(say_quote(message))
		var/rendered = "<span class='game ghostdronesay broadcast'>"
		rendered += "<span class='prefix'>DRONE:</span> "
		rendered += "<span class='name text-normal' data-ctx='\ref[mind]'>[name]</span> "
		rendered += "<span class='message'>[message]</span>"
		rendered += "</span>"

		var/nohear = "<span class='game say'><span class='name' data-ctx='\ref[mind]'>[name]</span> <span class='message'>[nohear_message()]</span></span>"

		for (var/mob/M in mobs)
			if (istype(M, /mob/new_player))
				continue

			if (M.client)
				var/thisR = rendered
				if (istype(M, /mob/living/silicon/ghostdrone) || M.client.holder)
					if (M.client.holder && mind)
						thisR = "<span class='adminHearing' data-ctx='[M.client.chatOutput.ctxFlag]'>[rendered]</span>"
					M.show_message(thisR, 2)
				else if (M in hearers(src))
					thisR = nohear
					M.show_message(thisR, 2)

	say(message = "")
		message = trim(copytext(sanitize(message), 1, MAX_MESSAGE_LEN))
		if (!message)
			return

		if (client && client.ismuted())
			boutput(src, "You are currently muted and may not speak.")
			return

		if (stat == 2)
			return say_dead(message)

		// emotes
		if (dd_hasprefix(message, "*") && !stat)
			return emote(copytext(message, 2),1)

		UpdateOverlays(speech_bubble, "speech_bubble")
		spawn (15)
			UpdateOverlays(null, "speech_bubble")

		var/broadcast = 0
		if (length(message) >= 2)
			if (dd_hasprefix(message, ";"))
				message = trim(copytext(message, 2, MAX_MESSAGE_LEN))
				broadcast = 1

		if (broadcast)
			return drone_broadcast(message)
		else
			return drone_talk(message)

	proc/show_laws_drone() //A new proc because it's handled very differently from normal laws
		//custom laws detailing just how much the drone cannot hurt people or grief or whatever
		//var/laws = "<span class='bold' style='color: blue;'>"
		//laws += "Your laws:<br>"
		//laws += "1. Avoid interaction with any living or silicon lifeforms where possible. except where the lifeform is also a drone.<br>"
		//laws += "2. Maintain, repair and improve the station wherever possible.<br>"
		//laws += "</span>"
		var/laws = {"<span class='bold' style='color:blue'>Your laws:<br>
		1. Avoid interaction with any living or silicon lifeforms where possible, with the exception of other drones.<br>
		2. Do not willingly damage the station in any shape or form.<br>
		3. Maintain, repair and improve the station.<br></span>"}
		out(src, laws)
		return

	verb/cmd_show_laws()
		set category = "Drone Commands"
		set name = "Show Laws"

		show_laws_drone()
		return

	bullet_act(var/obj/projectile/P)
		var/dmgtype = 0 // 0 for brute, 1 for burn
		var/dmgmult = 1.2
		switch (P.proj_data.damage_type)
			if (D_PIERCING)
				dmgmult = 2
			if (D_SLASHING)
				dmgmult = 0.6
			if (D_ENERGY)
				dmgtype = 1
			if (D_BURNING)
				dmgtype = 1
				dmgmult = 0.75
			if (D_RADIOACTIVE)
				dmgtype = 1
				dmgmult = 0.2
			if (D_TOXIC)
				dmgmult = 0

		log_shot(P,src)
		visible_message("<span style=\"color:red\"><strong>[src]</strong> is struck by [P]!</span>")
		var/damage = (P.power / 3) * dmgmult

		if (hat) //For hats getting shot off
			UpdateOverlays(null, "hat")
			hat.set_loc(get_turf(src))
			//get target turf
			var/x = round(P.xo * 4)
			var/y = round(P.yo * 4)
			var/turf/target = get_offset_target_turf(src, x, y)

			visible_message("<span class='combat'>[src]'s [hat] goes flying!</span>")
			takeoffHat(target)

		if (damage < 1)
			return

		if (material) material.triggerOnAttacked(src, P.shooter, src, (ismob(P.shooter) ? P.shooter:equipped() : P.shooter))
		for (var/atom/A in src)
			if (A.material)
				A.material.triggerOnAttacked(A, P.shooter, src, (ismob(P.shooter) ? P.shooter:equipped() : P.shooter))

		if (!dmgtype) //brute only
			TakeDamage("All", damage)

	//Items being dropped ONTO this mob
	MouseDrop_T(atom/movable/O as mob|obj, mob/user as mob)
		return

	canRideMailchutes()
		return TRUE

	restrained()
		return FALSE

	emag_act(var/mob/user, var/obj/item/card/emag/E)

	ex_act(severity)

	blob_act(var/power)

	emp_act()

	meteorhit(obj/O as obj)

	temperature_expose(null, temp, volume)
		if (material)
			material.triggerTemp(src, temp)

		for (var/atom/A in contents)
			if (A.material)
				A.material.triggerTemp(A, temp)

	get_static_image()
		return

/proc/droneize(target = null, pickNew = 1)
	if (!target) return FALSE

	var/mob/M
	if (istype(target, /client))
		var/client/C = target
		if (!C.mob) return FALSE
		M = C.mob

	if (istype(target, /mind))
		var/mind/Mind = target
		if (!Mind.current) return FALSE
		M = Mind.current

	if (ismob(target))
		M = target

	if (M.transforming) return FALSE

	var/mob/living/silicon/ghostdrone/G
	if (pickNew && islist(available_ghostdrones) && available_ghostdrones.len)
		for (var/mob/living/silicon/ghostdrone/T in available_ghostdrones)
			if (T.newDrone)
				G = T
				break
			else // why are you in this list
				available_ghostdrones -= T
		if (!G)
			//no free drones to spare
			return FALSE
		else
			available_ghostdrones -= G
			G.newDrone = 0
	else
		G = new /mob/living/silicon/ghostdrone(M.loc)
		G.set_loc(M.loc)

	if (ishuman(target))
		M.unequip_all()
		for (var/t in M.organs) qdel(M.organs[text("[t]")])

	M.transforming = 1
	M.canmove = 0
	M.icon = null
	M.invisibility = 101

	if (isobserver(M) && M:corpse)
		G.oldmob = M:corpse

	if (M.client)
		G.lastKnownIP = M.client.address
		M.client.mob = G

	if (M.ghost)
		if (M.ghost.mind)
			M.ghost.mind.transfer_to(G)
	else if (M.mind)
		M.mind.transfer_to(G)

/*	var/msg = "Your laws:<br>"
	msg += "<strong>1. Do not interfere, harm, or interact in any way with living or previously living lifeforms.</strong><br>"
	msg += "<strong>2. Do not willingly damage the station in any shape or form.</strong><br>"
	msg += "<strong>3. Assist in repairs to the station and expansion plans.</strong><br>"
	msg += "Use \"say ; (message)\" to speak to fellow drones through the spooky power of spirits within machines."

	G.show_laws_drone()
*/
	var/msg = "<span class='bold' style='color:red;font-size:150%'>You have become a drone!</span>"
	boutput(G, msg)

	G.job = "Ghostdrone"
	G.mind.assigned_role = "Ghostdrone"
	G.mind.dnr = 1
	G.oldname = M.real_name

	qdel(M)
	return G
