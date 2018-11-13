/obj/item/attackdummy
	name = "attack dummy"
	damtype = "brute"
	force = 5
	throwforce = 5

/mob/living/object
	name = "living object"
	var/obj/item/item
	var/mob/owner
	var/obj/item/attackdummy/dummy
	var/obj/screen/release/release
	density = 0
	canmove = 1
	var/canattack = 0
	blinded = 0
	anchored = 0
	a_intent = "disarm" // todo: This should probably be selectable. Cyborg style - help/harm.
	health = 50
	max_health = 50

	New(var/atom/loc as mob|obj|turf, var/mob/controller)
		..()
		message_admins("[key_name(controller)] possessed [loc] at [showCoords(loc.x, loc.y, loc.z)].")
		var/obj/item/possessed
		if (!istype(loc, /obj/item))
			if (isobj(loc))
				possessed = loc
				set_loc(get_turf(possessed))
				canattack = 0
				dummy = new /obj/item/attackdummy(src)
				dummy.name = loc.name
			else
				possessed = new /obj/item/paper()
				logTheThing("admin", usr, null, "living object mob created with no item.")
				var/turf/T = get_turf(loc)
				if (!T)
					logTheThing("admin", usr, null, "additionally, no turf could be found at creation loc [loc]")
					var/ASLoc = pick(latejoin)
					if (ASLoc)
						set_loc(ASLoc)
					else
						set_loc(locate(1, 1, 1))
				else
					set_loc(T)
				canattack = 1
		else
			canattack = 1
			possessed = loc
			set_loc(get_turf(possessed))

		if (!canattack)
			density = 1
			opacity = possessed.opacity
		possessed.set_loc(src)
		name = "living [possessed.name]"
		real_name = name
		desc = "[possessed.desc]"
		icon = possessed.icon
		icon_state = possessed.icon_state
		pixel_x = possessed.pixel_x
		pixel_y = possessed.pixel_y
		dir = possessed.dir
		color = possessed.color
		overlays = possessed.overlays
		item = possessed
		sight |= SEE_SELF
		density = possessed.density
		opacity = possessed.opacity

		release = new()
		release.owner = src

		owner = controller
		if (owner)
			owner.set_loc(src)
			if (!owner.mind)
				owner.mind = new /mind(  )
				owner.mind.key = owner.key
				owner.mind.current = owner
				ticker.minds += owner.mind
			//if (owner.client)
				// owner.client.mob = src
			owner.mind.transfer_to(src)

		visible_message("<span style=\"color:red\"><strong>[possessed] comes to life!</strong></span>") // was [src] but: "the living space thing comes alive!"
		animate_levitate(src, -1, 20, 1)

	equipped()
		if (canattack)
			return item
		else
			return dummy

	examine()
		..()
		boutput(usr, "<span style=\"color:red\">It seems to be alive.</span>")
		if (health < 25)
			boutput(usr, "<span style=\"color:blue\">The ethereal grip on this object appears to be weak.</span>")

	meteorhit(var/obj/O as obj)
		death(1)
		return

	restrained()
		return FALSE

	updatehealth()
		return

	Life(controller/process/mobs/parent)
		if (..(parent))
			return TRUE
		updatehealth()

		if (owner)
			if (owner.abilityHolder)
				if (owner.abilityHolder.usesPoints)
					owner.abilityHolder.generatePoints()

		weakened = 0
		paralysis = 0
		stunned = 0
		slowed = 0
		sleeping = 0
		change_misstep_chance(-INFINITY)
		drowsyness = 0.0
		dizziness = 0
		is_dizzy = 0
		is_jittery = 0
		jitteriness = 0

		if (!item)
			death(0)

		if (item.loc != src)
			if (isturf(item.loc))
				item.loc = src
			else
				death(0)

		for (var/atom/A as obj|mob in src)
			if (A != item && A != dummy && A != owner && !istype(A, /obj/screen) && !istype(A, /obj/hud))
				if (isobj(A) || ismob(A)) // what the heck else would this be?
					A:set_loc(loc)

		density = item.density
		item.dir = dir
		icon = item.icon
		icon_state = item.icon_state
		color = item.color
		overlays = item.overlays

	bullet_act(var/obj/projectile/P)
		var/damage = 0
		damage = round((P.power*P.proj_data.ks_ratio), 1.0)

		switch (P.proj_data.damage_type)
			if (D_KINETIC)
				TakeDamage(null, damage, 0)
			if (D_PIERCING)
				TakeDamage(null, damage / 2.0, 0)
			if (D_SLASHING)
				TakeDamage(null, damage, 0)
			if (D_BURNING)
				TakeDamage(null, 0, damage)
			if (D_ENERGY)
				TakeDamage(null, 0, damage)

		if (!P.proj_data.silentshot)
			visible_message("<span style=\"color:red\">[src] is hit by the [P]!</span>")

	attack_hand(mob/user as mob)
		if (user.a_intent == "help")
			user.visible_message("<span style=\"color:red\">[user] pets [src]!</span>")
		else
			user.visible_message("<span style=\"color:red\">[user] punches [src]!</span>")
			TakeDamage(null, rand(4, 7), 0)

	TakeDamage(zone, brute, burn)
		health -= burn
		health -= brute
		health = min(max_health, health)
		if (health <= 0)
			death(0)

	HealDamage(zone, brute, burn)
		TakeDamage(zone, -brute, -burn)

	change_eye_blurry(var/amount, var/cap = 0)
		if (amount < 0)
			return ..()
		else
			return TRUE

	take_eye_damage(var/amount, var/tempblind = 0)
		if (amount < 0)
			return ..()
		else
			return TRUE

	take_ear_damage(var/amount, var/tempdeaf = 0)
		if (amount < 0)
			return ..()
		else
			return TRUE

	click(atom/target, params)
		if (target == src)
			if (canattack)
				item.attack_self(src)
			else
				if (!istype(item, /obj/item))
					item.attack_hand(src)
				else //This shouldnt ever happen.
					item.attackby(item, src)
		else
			if (a_intent == INTENT_GRAB && istype(target, /atom/movable) && get_dist(src, target) <= 1)
				var/atom/movable/M = target
				if (ismob(target) || !M.anchored)
					visible_message("<span style=\"color:red\">[src] grabs [target]!</span>")
					M.set_loc(loc)
			else
				. = ..()
			if (item.loc != src)
				if (isturf(item.loc))
					item.loc = src
				else
					death(0)

		//To reflect updates of the items appearance etc caused by interactions.
		name = "living [item.name]"
		real_name = name
		desc = "[item.desc]"
		item.dir = dir
		icon = item.icon
		icon_state = item.icon_state
		//pixel_x = item.pixel_x
		//pixel_y = item.pixel_y
		color = item.color
		overlays = item.overlays
		density = item.density
		opacity = item.opacity

	death(gibbed)
		if (owner)
			owner.set_loc(get_turf(src))
			visible_message("<span style=\"color:red\"><strong>[src] is no longer possessed.</strong></span>")

			if (mind)
				mind.transfer_to(owner)
			else if (client)
				client.mob = owner
		else
			if (mind || client)
				var/mob/dead/observer/O = new/mob/dead/observer(get_turf(src))
				if (isrestrictedz(z) && !restricted_z_allowed(src, get_turf(src)) && !(client && client.holder))
					var/OS = observer_start.len ? pick(observer_start) : locate(1, 1, 1)
					if (OS)
						O.set_loc(OS)
					else
						O.z = 1
				if (client)
					client.mob = O
				O.name = name
				O.real_name = real_name
				if (mind)
					mind.transfer_to(O)

		if (item)
			if (!gibbed)
				item.dir = dir
				if (item.loc == src)
					item.set_loc(get_turf(src))
			else
				qdel(item)
		qdel(src)
		..(gibbed)

	movement_delay()
		return 4

	put_in_hand(obj/item/I, hand)
		return FALSE

	swap_hand()
		return FALSE

	drop_item_v()
		return FALSE

	item_attack_message(var/mob/T, var/obj/item/S, var/d_zone)
		if (d_zone)
			return "<span style=\"color:red\"><strong>[src] attacks [T] in the [d_zone]!</strong></span>"
		else
			return "<span style=\"color:red\"><strong>[src] attacks [T]!</strong></span>"