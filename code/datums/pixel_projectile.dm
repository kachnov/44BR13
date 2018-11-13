
/*
	Written by: FIREking
*/
//Have a look in demo.dm to see how to use /pixel_projectile!
/*

//////////////////////////////////////
//				Defines				//
//////////////////////////////////////

#define WORLD_ICON_SIZE 32
#define WORLD_HALF_ICON_SIZE 16
#define WORLD_ICON_MULTIPLY 0.03125 //This is  1 / WORLD_ICON_SIZE
#define WORLD_MAX_PX 6400 //This is the size of your map in tiles + 1 times world_icon_size
#define WORLD_MAX_PY 6400 //This is the size of your map in tiles + 1 times world_icon_size

//////////////////////////////////////
//			Utility Stuff			//
//////////////////////////////////////
/proc/get_speed_delay(n)
	return (world.icon_size * world.tick_lag) / (!n ? 1 : n)

/proc/get_dir_adv(atom/ref, atom/target)
	//Written by Lummox JR
	//Returns the direction between two atoms more accurately than get_dir()

    if (target.z > ref.z) return UP
    if (target.z < ref.z) return DOWN

    . = get_dir(ref, target)
    if (. & . - 1)        // diagonal
        var/ax = abs(ref.x - target.x)
        var/ay = abs(ref.y - target.y)
        if (ax >= (ay << 1))      return . & (EAST | WEST)   // keep east/west (4 and 8)
        else if (ay >= (ax << 1)) return . & (NORTH | SOUTH) // keep north/south (1 and 2)
    return .

/atom/movable/proc/set_pos_px(px, py)
	//this sets the atom's x, y and the atom's pixel_x, pixel_y from absolute pixel coordinates
	x = px * WORLD_ICON_MULTIPLY
	y = py * WORLD_ICON_MULTIPLY
	pixel_x = px % WORLD_ICON_SIZE - WORLD_HALF_ICON_SIZE
	pixel_y = py % WORLD_ICON_SIZE - WORLD_HALF_ICON_SIZE

//////////////////////////////////////
//			pixel_projectile		//
//////////////////////////////////////

/obj/pixel_projectile
	animate_movement = NO_STEPS
	var/tmp
		angle
		px //the true pixel location of the projectile
		py
		last_x //the last x/y coordinate of the tile we were in
		last_y
		velocity //speed of the projectile
		atom/owner
		projectile/projectile

		vx //vector px (movement increment)
		vy //vector py (movement increment)

	unpooled(var/poolname)
		angle = 0
		px = 0
		py = 0
		last_x = 0
		last_y = 0
		velocity = 12
		owner = null
		projectile = null
		vx = 0
		vy = 0
		..()

	proc/setup(var/location, vel)
		if (vel) velocity = vel
		set_loc(location)
		//ok now the real important stuff, initial position and vector calculation

	disposing()
		//garbage collector stuff
		owner = null
		projectile = null
		..()

	proc/fire(projectile/projectile, var/atom/owner, var/atom/target)
		if (!projectile || !owner || !target)
			die()
			return

		projectile = projectile
		owner = owner

		icon = projectile.icon
		icon_state = projectile.icon_state
		set_loc(get_turf(owner))

		//set initial position
		px = x * WORLD_ICON_SIZE + WORLD_HALF_ICON_SIZE
		py = y * WORLD_ICON_SIZE + WORLD_HALF_ICON_SIZE

		if (!check_bounds())
			die()
			return

		var/tmp
			dx = 0 //delta x
			dy = 0 //delta y
			dr = 0 //delta root

		//delta x,y is absolute pixel x minus the starting absolute pixel x
		dx = (target.x * WORLD_ICON_SIZE) + WORLD_HALF_ICON_SIZE - px
		dy = (target.y * WORLD_ICON_SIZE) + WORLD_HALF_ICON_SIZE - py
		//root
		dr = sqrt(dx * dx + dy * dy)
		//vector x (amount to move x,y each frame)
		vx = dx / dr * velocity
		vy = dy / dr * velocity

		dir = get_dir_adv(src, target)

		//that's it

		//begin!
		spawn update()

	Cross(atom/movable/a)
		//if something happens to cross this tile while we're sitting in it before moving to next tile
		//we should check for collide!
		if (can_collide(a)) collide(a)
		return ..()

	proc/die()
		var/self = src
		src = null
		spawn (0)
			if (self) pool(self)

	proc/update()
		//update position

		while (!disposed)
			if (!loc || !projectile)
				die()
				return

			px += vx
			py += vy

			if (!check_bounds())
				die()
				return

			//update x, y, pixel_x, pixel_y to reflect new location
			set_pos_px(px, py)

			//did we enter a new tile?
			if (last_x != x || last_y != y)
				last_x = x
				last_y = y

				if (loc) loc:collide_here(src)
				//using colon operator assuming the projectile's loc will always be a turf

			sleep(world.tick_lag)

	proc/check_bounds()
		//checks to see if a pixel is in bounds of the map
		//if (px > WORLD_ICON_SIZE && py > WORLD_ICON_SIZE && px <= WORLD_MAX_PX && py <= WORLD_MAX_PY)
		if ((px in WORLD_ICON_SIZE to WORLD_MAX_PX) && (py in WORLD_ICON_SIZE to WORLD_MAX_PY))
			return TRUE
		return FALSE

	proc/collide(atom/a)
		projectile.on_hit(a, dir)
		if (a)
			a.bullet_act(projectile)
			if (istype(a,/turf))
				for (var/obj/O in a)
					O.bullet_act(projectile)
		spawn (get_speed_delay(velocity) - 1)
			die()

	proc/can_collide(atom/a)
		if (a.density || ismob(a))
			return TRUE
		return FALSE

//the collidables list allows us to avoid having to generate lists per tile update per projectile
//just make sure to remove your atom from this list at garbage collection!
/turf/var/tmp/list/collidables = null

/atom/disposing()
	if (isturf(loc)) loc:collidable_change(src, 0)
	..()

/turf/New()
	..()
	spawn (1)
		for (var/A in contents)
			collidable_change(A, 1)

/turf/disposing()
	if (collidables)
		collidables.len = 0
	collidables = null
	..()

/turf/Entered(atom/a)
	collidable_change(a, 1)
	..()

/turf/Exited(atom/a)
	collidable_change(a, 0)
	..()

// call with A as the atom involved, entered as boolean for add or remove from list
/turf/proc/collidable_change(var/atom/A, var/entered)
	if (entered)
		if (A.density || ismob(A))
			if (!collidables) collidables = list()
			collidables += A
	else
		if (!collidables) return
		collidables -= A
		if (!collidables.len) collidables = null

/turf/proc/collide_here(var/obj/pixel_projectile/p)
	if (p.can_collide(src))
		p.collide(src)
	if (collidables)
		for (var/atom/a in collidables)
			if (p.can_collide(a))
				p.collide(a)

// pixel guns here for now

/obj/item/pixel_gun
	name = "experimental gun"
	icon = 'icons/obj/gun.dmi'
	inhand_icon = 'icons/mob/inhand/hand_weapons.dmi'
	flags =  FPRINT | TABLEPASS | CONDUCT | ONBELT | EXTRADELAY
	item_state = "gun"
	m_amt = 2000
	force = 10.0
	throwforce = 5
	w_class = 3.0
	throw_speed = 4
	throw_range = 6
	contraband = 0
	artifact = 1


	var/projectile/current_projectile = null
	var/list/projectiles = null
	var/current_projectile_num = 1

	New()
		return

/obj/item/pixel_gun/attack(mob/M as mob, mob/user as mob)

	user.lastattacked = M
	M.lastattacker = user
	M.lastattackertime = world.time

	if (user.a_intent != "help" && istype(M,/mob/living))
		if (!canshoot())
			M.visible_message("<span style=\"color:red\"><strong>[user] tries to fire [src] at [M] pointblank, but it was empty!</strong></span>")
			return
		for (var/mob/O in AIviewers(M, null))
			if (O.client)	O.show_message("<span style=\"color:red\"><strong>[M] has been shot pointblank with [src] by [user]!</strong></span>", 1, "<span style=\"color:red\">You hear someone fall.</span>", 2)
		if (M.stunned < 5) M.stunned = 5
		M.lying = 1
		var/mob/living/carbon/C = 0
		var/mob/living/silicon/S = 0
		if (iscarbon(M))
			C = M
		if (istype(M, /mob/living/silicon))
			S = M
		if (C && C.stat == 0) C.lastgasp()
		if (S && S.stat == 0) S.lastgasp()
		if (M.stat != 2)	M.stat = 1
		if (M.stuttering < 5) M.stuttering = 5
		M.set_clothing_icon_dirty()
	else
		..()

		#ifdef DATALOGGER
		game_stats.Increment("violence")
		#endif
		return

/obj/item/pixel_gun/attack_self(mob/user as mob)

	if (projectiles && projectiles.len > 1)
		current_projectile_num = ((current_projectile_num) % projectiles.len) + 1

//		if (current_projectile_num < projectiles.len)
//			current_projectile_num += 1
//		else
//			current_projectile_num = 1

		current_projectile = projectiles[current_projectile_num]
		boutput(user, "<span style=\"color:blue\">you set the output to [current_projectile.sname].</span>")
	return

/obj/item/pixel_gun/afterattack(atom/target as mob|obj|turf|area, mob/user as mob, flag)
	add_fingerprint(user)
	if (flag)
		return

	// drsingh fix for Cannot read null.shot_number
	if (check_valid_shot(target,user) && !isnull(current_projectile))
		shoot(target,user)

/obj/item/pixel_gun/proc/check_valid_shot(atom/target as mob|obj|turf|area, mob/user as mob)
	var/turf/T = get_turf(user)
	var/turf/U = get_turf(target)
	if ((!( U ) || !( T )))
		return FALSE
	if (!istype(T,/turf) && !istype(U,/turf))
		return FALSE
	if (U == T)
		user.bullet_act(current_projectile)
		return FALSE
	return TRUE

/obj/item/pixel_gun/proc/shoot(var/atom/target,var/mob/user)
	//Check ammo
	if (!process_ammo(user))
		boutput(user, "<span style=\"color:red\">*click* *click*</span>")
		return
	//Update that icon, having it here means we dont need it in each process_ammo proc
	update_icon()
	//Play a sound if we have one
	if (current_projectile.shot_sound)
		playsound(user, current_projectile.shot_sound, 50)
	//Don't even create the new projectile if the target isn't turf
	var/obj/pixel_projectile/P = unpool(/obj/pixel_projectile)
	P.setup( get_turf(user) , 10 ) // number is velocity
	//Give it the info datum and shoooot
	P.fire(current_projectile, user, target)

/obj/item/pixel_gun/proc/canshoot()
	return FALSE

/obj/item/pixel_gun/examine()
	set src in usr
	set category = "Local"

	if (artifact)
		boutput(usr, "You have no idea what the hell this thing is!")
		return

	..()
	return

/obj/item/pixel_gun/proc/update_icon()
	return FALSE

/obj/item/pixel_gun/proc/process_ammo(var/mob/user)
	boutput(user, "<span style=\"color:red\">*click* *click*</span>")
	return FALSE

/obj/item/pixel_gun/energy
	name = "experimental energy weapon"
	icon = 'icons/obj/gun.dmi'
	icon_state = "energy"
	item_state = "gun"
	m_amt = 2000
	g_amt = 1000
	mats = 16
	//1 = no cell change, use a recharger
	var/rechargeable = 1
	var/robocharge = 800
	var/obj/item/ammo/power_cell/cell = null

	New()
		cell = new/obj/item/ammo/power_cell/med_power
		current_projectile = new/projectile/energy_bolt
		projectiles = list(current_projectile,new/projectile/laser)
		..()

	update_icon()
		if (cell)
			var/ratio = cell.charge / cell.max_charge
			ratio = round(ratio, 0.25) * 100
			icon_state = "energy[ratio]"

	examine()
		set src in usr
		if (cell)
			desc = "There are [cell.charge]/[cell.max_charge] PUs left!"
		else
			desc = "There is no cell loaded!"
		if (current_projectile)
			desc += " Each shot will currently use [current_projectile.cost] PUs!"
		else
			desc += "<span style=\"color:red\">*ERROR* No output selected!</span>"
		..()
		return

	canshoot()
		if (cell && cell:charge && current_projectile)
			if (cell:charge >= current_projectile:cost)
				return TRUE
		return FALSE

	process_ammo(var/mob/user)
		if (istype(user,/mob/living/silicon/robot))
			var/mob/living/silicon/robot/R = user
			if (R.cell)
				if (R.cell.charge >= robocharge)
					R.cell.charge -= robocharge
					return TRUE
			return FALSE
		else
			if (cell && current_projectile)
				if (cell.use(current_projectile.cost))
					return TRUE
			boutput(user, "<span style=\"color:red\">*click* *click*</span>")
			return FALSE

	attackby(obj/item/b as obj, mob/user as mob)
		if (istype(b, /obj/item/ammo/power_cell) && !rechargeable)
			if (cell)
				if (b:swap(src))
					boutput(user, "<span style=\"color:blue\">You change the cell in the [src]!</span>")
			else
				cell = b
				user.drop_item()
				b.set_loc(src)
				boutput(user, "<span style=\"color:blue\">You load the [src]!</span>")
		else
			..()

	attack_hand(mob/user as mob)
		if ((user.r_hand == src || user.l_hand == src) && contents && contents.len)
			if (cell&&!rechargeable)
				user.put_in_hand_or_drop(cell)
				cell = null
				update_icon()
				add_fingerprint(user)
		else
			return ..()
		return
*/
