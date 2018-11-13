//Xmas presents/ETC
//CONTAINS:
// * Setup and helper procs
// * Bootleg Guardbuddy Toy
// * Xmas Guardbuddy
// * Xmas Guardbuddy Module - Snowball launcher!
// * Seal Pup + walrus
// * Christmas Tree
// * Snow tiles
// * Christmas decoration
// * Grinch graffiti
// * Santa Claus stuff
// * Krampus 1.0 stuff

var/global/christmas_cheer = 60
var/global/xmas_respawn_lock = 0
var/global/santa_spawned = 0
var/global/krampus_spawned = 0

var/static/list/santa_snacks = list(/obj/item/reagent_containers/food/drinks/eggnog,/obj/item/reagent_containers/food/snacks/cookie,
/obj/item/reagent_containers/food/snacks/ice_cream/random,/obj/item/reagent_containers/food/snacks/pie/apple,/obj/item/reagent_containers/food/snacks/snack_cake,
/obj/item/reagent_containers/food/snacks/yoghurt/frozen,/obj/item/reagent_containers/food/snacks/granola_bar,/obj/item/reagent_containers/food/snacks/candy/chocolate)

/proc/modify_christmas_cheer(var/mod)
	if (!mod || !isnum(mod))
		return
	#ifdef XMAS
	christmas_cheer += mod
	christmas_cheer = max(0,min(christmas_cheer,100))

	if (!xmas_respawn_lock)
		if (christmas_cheer >= 80 && !santa_spawned)
			spawn (0) // Might have been responsible for locking up the mob loop via human Life() -> death() -> modify_christmas_cheer() -> santa_krampus_spawn ().
				santa_krampus_spawn (0)
		if (christmas_cheer <= 10 && !krampus_spawned && map_setting != "DESTINY")
			spawn (0)
				santa_krampus_spawn (1)
	#endif
	return

// Might as well tweak Santa/Krampus respawn to make it use the universal player selection proc I wrote (Convair880).
/proc/santa_krampus_spawn (var/which_one = 0, var/confirmation_delay = 1200)
	if (xmas_respawn_lock != 0)
		return
	if (!isnum(confirmation_delay) || confirmation_delay < 0)
		message_admins("Couldn't set up [which_one == 0 ? "Santa Claus" : "Krampus"] respawn (setup failed).")
		return

	xmas_respawn_lock = 1

	// Setup.
	var/list/text_messages = list()
	if (confirmation_delay > 0) // These are irrelevant when player selection is instantaneous (confirmation_delay == 0).
		text_messages.Add("Would you like to respawn as [which_one == 0 ? "Santa Claus" : "Krampus"]? Your name will be added to the list of eligible candidates and may be selected at random by the game.")
		text_messages.Add("You are eligible to be respawned as [which_one == 0 ? "Santa Claus" : "Krampus"]. You have [confirmation_delay / 10] seconds to respond to the offer.")

		message_admins("[which_one == 0 ? "Santa Claus" : "Krampus"] respawn is sending offer to eligible ghosts. They have [confirmation_delay / 10] seconds to respond.")

	// Select player.
	var/list/mind/candidates = dead_player_list(1, confirmation_delay, text_messages)
	if (!islist(candidates) || candidates.len <= 0)
		message_admins("Couldn't set up [which_one == 0 ? "Santa Claus" : "Krampus"] respawn (no eligible candidates found).")
		xmas_respawn_lock = 0
		return

	var/mind/M = pick(candidates)
	if (!(M && istype(M) && M.current))
		message_admins("Couldn't set up [which_one == 0 ? "Santa Claus" : "Krampus"] respawn (candidate selection failed).")
		xmas_respawn_lock = 0
		return

	// Respawn player.
	var/mob/L
	var/ASLoc = latejoin.len ? pick(latejoin) : null // picking from an empty list causes a runtime
	var/WSLoc = wizardstart.len ? pick(wizardstart) : null

	if (!ASLoc)
		message_admins("Couldn't set up [which_one == 0 ? "Santa Claus" : "Krampus"] respawn (no late-join landmark found).")
		xmas_respawn_lock = 0
		return

	if (which_one == 0)
		L = new /mob/living/carbon/human/santa
		if (!(L && ismob(L)))
			message_admins("Couldn't set up [which_one == 0 ? "Santa Claus" : "Krampus"] respawn (new mob couldn't be created).")
			xmas_respawn_lock = 0
			return

		if (!WSLoc)
			L.set_loc(ASLoc)
		else
			L.set_loc(WSLoc)

		M.dnr = 1
		M.transfer_to(L)
		boutput(L, "<span style=\"color:blue\"><strong>You have been respawned as Santa Claus!</strong></span>")
		boutput(L, "Go to the station and reward the crew for their high faith in Christmas. Use your christmas magic!")
		boutput(L, "<strong>Do not reference anything that happened during your past life!</strong>")
		santa_spawned = 1

		spawn (0)
			L.choose_name(3, "Santa Claus", "Santa Claus")

	else
		L = new /mob/living/carbon/wall/meatcube/krampus
		if (!(L && ismob(L)))
			message_admins("Couldn't set up [which_one == 0 ? "Santa Claus" : "Krampus"] respawn (new mob couldn't be created).")
			xmas_respawn_lock = 0
			return

		L.set_loc(ASLoc)
		M.dnr = 1
		M.transfer_to(L)
		boutput(L, "<span style=\"color:blue\"><strong>You have been respawned as Krampus 2.0! <font color=red>Now better than ever!</font></strong></span>")
		boutput(L, "The station has been very naughty. <strong>FUCK. UP. EVERYTHING.</strong>")
		boutput(L, "Be on the lookout for grinches. Do not harm them!")
		boutput(L, "<strong>Do not reference anything that happened during your past life!</strong>")
		krampus_spawned = 1

	message_admins("[which_one == 0 ? "Santa Claus" : "Krampus"] respawn completed successfully for player [L.mind.key] at [log_loc(L)].")
	logTheThing("admin", L, null, "respawned as [which_one == 0 ? "Santa Claus" : "Krampus"] at [log_loc(L)].")
	xmas_respawn_lock = 0
	return

// Grandma, no! you picked the wrong one!
/obj/machinery/bot/guardbot/bootleg
	name = "Super Protector Friend III"
	desc = "The label on the back reads 'New technology! Blinking light action!'."
	icon = 'icons/misc/xmas.dmi'

	speak(var/message)
		var/fontmode = rand(1,4)
		switch(fontmode)
			if (1) return ..("<font face='Comic Sans MS' size=3>[uppertext(message)]!!</font>")
			if (2) return ..("<font face='Curlz MT'size=3>[uppertext(message)]!!</font>")
			if (3) return ..("<font face='System'size=3>[uppertext(message)]!!</font>")
			else
				var/honk = pick("WACKA", "QUACK","QUACKY","GAGGLE")
				playsound(loc, "sound/misc/amusingduck.ogg", 50, 0)
				return ..("<font face='Comic Sans MS' size=3>[honk]!!</font>")
	Move()
		if (..())
			pixel_x = rand(-6, 6)
			pixel_y = rand(-6, 6)
			if (prob(5) && limiter.canIspawn (/obj/effects/sparks))
				var/obj/sparks = unpool(/obj/effects/sparks)
				sparks.set_loc(loc)
				spawn (20) if (sparks) pool(sparks)

/obj/machinery/bot/guardbot/xmas
	name = "Jinglebuddy"
	desc = "Festive!"
	icon = 'icons/misc/xmas_buddy.dmi'
	setup_default_tool_path = /obj/item/device/guardbot_tool/xmas

	speak(var/message)
		return ..("<font face='Segoe Script'><em><strong>[message]</strong></em></font>")

	explode()
		if (exploding) return
		exploding = 1
		var/death_message = pick("I'll be back again some day!", "And to all a good night!", "A buddy is never truly happy until it is loved by a child. ", "I guess Christmas isn't coming this year.", "Ho ho hFATAL ERROR")
		speak(death_message)
		visible_message("<span class='combat'><strong>[src] blows apart!</strong></span>")
		var/turf/T = get_turf(src)
		if (mover)
			mover.master = null
			qdel(mover)

		invisibility = 100
		var/obj/overlay/Ov = new/obj/overlay(T)
		Ov.anchored = 1
		Ov.name = "Explosion"
		Ov.layer = NOLIGHT_EFFECTS_LAYER_BASE
		Ov.pixel_x = -17
		Ov.icon = 'icons/effects/hugeexplosion.dmi'
		Ov.icon_state = "explosion"

		tool.set_loc(get_turf(src))

		var/list/throwparts = list()
		throwparts += new /obj/item/parts/robot_parts/arm/left(T)
		throwparts += new /obj/item/device/flash(T)
		//throwparts += core
		throwparts += tool
		if (hat)
			throwparts += hat
			hat.set_loc(T)

		for (var/obj/O in throwparts) //This is why it is called "throwparts"
			var/edge = get_edge_target_turf(src, pick(alldirs))
			O.throw_at(edge, 100, 4)

		spawn (0) //Delete the overlay when finished with it.
			on = 0
			sleep(15)
			qdel(Ov)
			qdel(src)

		T.hotspot_expose(800,125)
		explosion(src, T, -1, -1, 2, 3)

		return

/obj/item/device/guardbot_tool/xmas
	name = "Snowballer XL tool module"
	desc = "An exotic module for PR-6S Guardbuddies designed to fire snowballs."
	icon_state = "tool_xmas"
	tool_id = "SNOW"
	is_stun = 1
	is_gun = 1
	var/projectile/current_projectile = new/projectile/snowball

	// Updated for new projectile code (Convair880).
	bot_attack(var/atom/target as mob|obj, obj/machinery/bot/guardbot/user, ranged=0, lethal=0)
		if (..()) return

		if (last_use && world.time < last_use + 80)
			return

		if (ranged)
			var/obj/projectile/P = shoot_projectile_ST_pixel(master, current_projectile, target)
			if (!P)
				return

			user.visible_message("<span style=\"color:red\"><strong>[master] throws a snowball at [target]!</strong></span>")

		else
			var/obj/projectile/P = initialize_projectile_ST(master, current_projectile, target)
			if (!P)
				return

			user.visible_message("<span style=\"color:red\"><strong>[master] beans [target] point-blank with the snowball!</strong></span>")
			P.was_pointblank = 1
			hit_with_existing_projectile(P, target)

		last_use = world.time
		return

/projectile/snowball
	name = "snowball"
	icon = 'icons/misc/xmas.dmi'
	icon_state = "snowball"
	power = 10
	cost = 25
	dissipation_rate = 2
	dissipation_delay = 4
	ks_ratio = 0.0
	sname = "stun"
	shot_sound = 'sound/effects/pop.ogg'
	shot_number = 1
	damage_type = 0
	hit_ground_chance = 0
	window_pass = 0

	on_hit(atom/hit)
		if (!iscarbon(hit))
			return

		var/mob/living/carbon/O = hit
		if (!O.lying)
			O.lying = 1
			O.visible_message("<span class='combat'><strong>[O] is knocked down by the snowball!</strong></span>")
			modify_christmas_cheer(1)
			boutput(O, "Brrr!")

		if (O.weakened < 10 && !O.bioHolder.HasEffect("hulk"))
			O.weakened = 10

		O.bodytemperature = max(0, O.bodytemperature - 5)

		O.set_clothing_icon_dirty()
		return

/obj/critter/sealpup
	name = "space seal pup"
	desc = "A seal pup, in space, aww."
	icon_state = "seal"
	density = 0
	health = 10
	aggressive = 0
	defensive = 0
	wanderer = 1
	opensdoors = 0
	atkcarbon = 0
	atksilicon = 0
	firevuln = 1
	brutevuln = 1
	butcherable = 2

	New()
		..()
		name = pick("Fluffles","Ronan","Selena","Selkie","Ukog","Ategev","Puffles","Boop","Akiak","Willy","Aga","Snuffles","Tonaph","Suortin","Anana","Ananas","Pineapple","Munchkin","Asiaq","Niko","Roman","Chu","Corazon")


	CritterDeath()
		if (!alive) return
		icon_state += "-dead"
		alive = 0
		anchored = 0
		density = 0
		desc = "The lifeless corpse of [name], why would anyone do such a thing?"
		walk_to(src,0)
		visible_message("<strong>[src]</strong> dies!")
		modify_christmas_cheer(-20)
		name = "dead space seal pup"
		for (var/obj/critter/sealpup/S in view(7,src))
			if (S.alive)
				S.visible_message("<strong>[S.name]</strong> [pick("groans","yelps")]!", 1)
				walk_away(S,src,20,1)
				spawn (10) walk(S,0)
		///Killing seals pisses off walruses!! uh oh.
		for (var/obj/critter/walrus/W in view(7,src))
			if (W.alive)
				W.aggressive = 1
				spawn (7)
				W.aggressive = 0



	attack_hand(var/mob/user as mob)
		if (!alive)
			return
		if (user.a_intent == "harm")
			health -= rand(1,2) * brutevuln
			for (var/mob/O in viewers(src, null))
				O.show_message("<span class='combat'><strong>[user]</strong> punches [src]!</span>", 1)
			playsound(loc, "punch", 50, 1)
			if (alive && health <= 0) CritterDeath()
			if (defensive)
				target = user
				oldtarget_name = user.name
				visible_message("<span class='combat'><strong>[src]</strong> [angertext] [user.name]!</span>")
				task = "chasing"
			if (!defensive)
				visible_message("<strong>[src]</strong> [pick("groans","yelps")]!", 1)
				walk_away(src,user,10,1)
				spawn (7) walk(src,0)
		else
			visible_message("<strong>[user]</strong> [pick("hugs","pets","caresses","boops","squeezes")] [src]!", 1)
			if (prob(80))
				visible_message("<strong>[src]</strong> [pick("coos","purrs","mewls","chirps","arfs","arps","urps")].", 1)
			else
				visible_message("<strong>[src]</strong> hugs <strong>[user]</strong> back!", 1)
				if (user.reagents)
					user.reagents.add_reagent("hugs", 10)
				playsound(loc, "sound/misc/babynoise.ogg", 50, 10,10)

	attackby(obj/item/W as obj, mob/living/user as mob)
		..()
		if (!alive) return
		if (istype(W, /obj/item/reagent_containers/food/snacks))
			if (findtext(W.name,"seal")) // for you, spacemarine9
				visible_message("<strong>[src]</strong> [pick("groans","yelps")]!", 1)
				visible_message("<strong>[src]</strong> gets frightened by [W]!", 1)
				walk_away(src,user,10,1)
				spawn (10) walk(src,0)
				return

			if (prob(5))
				visible_message("<strong>[src]</strong> gives [W] back to <strong>[user]</strong> as if they wanted to share!", 1)
				playsound(loc, "sound/misc/babynoise.ogg", 50, 10,10)
			user.visible_message("<strong>[user]</strong> feeds [W] to [src]!","You feed [W] to [src].")
			visible_message("<strong>[src]</strong> [pick("coos","purrs","mewls","chirps","arfs","arps","urps")].", 1)
			modify_christmas_cheer(1)
			health += 10
			qdel(W)
		else
			visible_message("<strong>[src]</strong> [pick("groans","yelps")]!", 1)
			walk_away(src,user,10,1)
			spawn (4) walk(src,0)
			..()

/obj/critter/walrus
	name = "space walrus"
	desc = "A walrus, in space."
	icon_state = "walrus"
	density = 1
	health = 30
	aggressive = 0
	defensive = 1
	wanderer = 1
	atkcarbon = 1
	atksilicon = 1
	atcritter = 1
	firevuln = 0.5
	brutevuln = 0.5
	butcherable = 1


	seek_target()
		anchored = 0
		for (var/mob/living/C in view(seekrange,src))
			if ((C.name == oldtarget_name) && (world.time < last_found + 100)) continue
			if (iscarbon(C) && !atkcarbon) continue
			if (istype(C, /mob/living/silicon) && !atksilicon) continue
			if (C.health < 0) continue
			if (C.name == attacker) attack = 1
			if (iscarbon(C) && atkcarbon) attack = 1
			if (istype(C, /mob/living/silicon) && atksilicon) attack = 1

			if (attack)
				target = C
				oldtarget_name = C.name
				visible_message("<span class='combat'><strong>[src]</strong> roars at [C:name]!</span>")
				playsound(loc, "sound/voice/MEraaargh.ogg", 50, 0)
				task = "chasing"
				break
			else
				continue


	CritterAttack(mob/M)
		attacking = 1
		M.visible_message("<span class='combat'><strong>[src]</strong> drives its tusks through [target]!</span>")
		random_brute_damage(M, rand(8,16))
		spawn (20) attacking = 0


	ChaseAttack(mob/M)
		visible_message("<span class='combat'><strong>[src]</strong> lunges upon [M]!</span>")
		if (iscarbon(M))
			if (prob(50)) M.stunned += rand(2,4)
		random_brute_damage(M, rand(4,8))


// Throughout December the icon will change!
/obj/xmastree
	name = "Spacemas tree"
	desc = "O Spacemas tree, O Spacemas tree, Much p- Huh, there's a note here with 'http://forum.ss13.co/viewtopic.php?f=5&t=6074' written on it."
	icon = 'icons/effects/160x160.dmi'
	icon_state = "xmastree_2015"
	anchored = 1
	layer = NOLIGHT_EFFECTS_LAYER_BASE
	pixel_x = -64

	density = 1
	var/on_fire = 0
	var/image/fire_image = null

	New()
		fire_image = image('icons/effects/160x160.dmi', "")

	verb/extinguish()
		set src in oview(1)
		set category = "Local"
		if (!on_fire)
			return
		visible_message("<span class='combat'>[usr] attempts to extinguish the fire!</span>")
		if (prob(2))
			change_fire_state(0)
		else
			boutput(usr, "You couldn't get the fire out. Keep trying!")

	proc/change_fire_state(var/burning = 0)
		if (on_fire && burning == 0)
			on_fire = 0
			visible_message("<span style=\"color:blue\">[src] is extinguished. Phew!</span>")
		else if (!on_fire && burning == 1)
			visible_message("<span class='combat'><strong>[src] catches on fire! Oh shit!</strong></span>")
			on_fire = 1
			spawn (600)
				if (on_fire)
					visible_message("<span class='combat'>[src] burns down and collapses into a sad pile of ash. <strong><em>Spacemas is ruined!!!</em></strong></span>")
					for (var/turf/simulated/floor/T in range(1,src))
						new /obj/decal/cleanable/ash(T)
					modify_christmas_cheer(-33)
					qdel(src)
					return
		update_icon()

	proc/update_icon()
		//overlays = null
		if (on_fire)
			if (!fire_image)
				fire_image = image('icons/effects/160x160.dmi', "xmastree_2014_burning")
			fire_image.icon_state = "xmastree_2014_burning" // it didn't need to change from 2014 to 2015 so I just left it as this one
			//overlays += fire_image
			UpdateOverlays(fire_image, "fire")
		else
			UpdateOverlays(null, "fire")

/turf/simulated/floor/snow
	name = "snow"
	icon_state = "snow1"

	New()
		..()
		icon_state = "snow[pick(1,1,1,2,2,3)]"
		if (prob(5)) icon_state = "snow4"

/turf/simulated/floor/snowball
	name = "snow"
	icon_state = "snow1"
	var/last_gather_time

	New()
		..()
		//icon_state = "snow[pick(1,1,1,2,2,3)]"
		if (prob(50))
			icon_state = "snow2"
		else if (prob(25))
			icon_state = "snow3"
		else if (prob(5))
			icon_state = "snow4"
			dir = pick(cardinal)

	attack_hand(mob/user)
		if ((last_gather_time + 40) >= world.time)
			return
		else
			user.visible_message("<strong>[user]</strong> gathers up some snow and rolls it into a snowball!",\
			"You gather up some snow and roll it into a snowball!")
			var/obj/item/reagent_containers/food/snacks/snowball/S = new /obj/item/reagent_containers/food/snacks/snowball(user.loc)
			user.put_in_hand_or_drop(S)
			last_gather_time = world.time
			return

/obj/item/reagent_containers/food/snacks/snowball
	name = "snowball"
	desc = "A snowball. Made of snow."
	icon = 'icons/misc/xmas.dmi'
	icon_state = "snowball"
	amount = 2
	w_class = 1.0
	throwforce = 1
	doants = 0
	food_color = "#FFFFFF"

	New()
		..()
		spawn (rand(100,500))
			visible_message("\The [src] melts!")
			new /obj/decal/cleanable/water(get_turf(src))
			qdel(src)

	heal(var/mob/living/M)
		if (!M || !isliving(M))
			return
		M.bodytemperature -= rand(1, 10)
		M.show_text("That was chilly!", "blue")

	proc/hit(var/mob/living/M as mob, var/message = 1)
		if (!M || !istype(M, /mob/living))
			return
		M.stunned += rand(0,1)
		M.take_eye_damage(rand(0, 2))
		M.change_eye_blurry(25)
		M.make_dizzy(rand(0, 5))
		M.stuttering += rand(0, 1)
		M.bodytemperature -= rand(1, 10)
		if (message)
			M.visible_message("<span style='color:red'><strong>[M]</strong> is hit by [src]!</span>",\
			"<span style='color:red'>You get hit by [src]![pick("", " Brr!", " Ack!", " Cold!")]</span>")
		amount -= rand(1, 2)

	attack(mob/M as mob, mob/user as mob)
		if (user.bioHolder.HasEffect("clumsy") && prob(50))
			user.visible_message("<span style='color:red'>[user] plasters the snowball over [his_or_her(user)] face.</span>",\
			"<span style='color:red'>You plaster the snowball over your face.</span>")
			hit(user, 0)
			return

		add_fingerprint(user)

		if (amount <= 0)
			visible_message("[src] collapses into a poof of snow!")
			qdel(src)
			return

		else if (user.a_intent == "harm")
			if (M == user)
				M.visible_message("<span style='color:red'><strong>[user] smushes [src] into [his_or_her(user)] own face!</strong></span>",\
				"<span style='color:red'><strong>You smush [src] into your own face!</strong></span>")
			else if ((user != M && iscarbon(M)))
				M.tri_message("<span style='color:red'><strong>[user] smushes [src] into [M]'s face!</strong></span>",\
				user, "<span style='color:red'><strong>You smush [src] into [M]'s face!</strong></span>",\
				M, "<span style='color:red'><strong>[user] smushes [src] in your face!</strong></span>")
			hit(M, 0)

		else return ..()

	throw_impact(atom/A)
		if (ismob(A))
			hit(A)
		if (amount <= 0)
			visible_message("[src] collapses into a poof of snow!")
			qdel(src)
			return

/obj/decal/garland
	name = "garland"
	icon = 'icons/misc/xmas.dmi'
	icon_state = "garland"
	anchored = 1

/obj/decal/tinsel
	name = "tinsel"
	icon = 'icons/misc/xmas.dmi'
	icon_state = "tinsel-silver"
	anchored = 1

/obj/decal/xmas_lights
	name = "spacemas lights"
	icon = 'icons/misc/xmas.dmi'
	icon_state = "lights1"
	anchored = 1
	var/light/light

	New()
		..()
		light = new /light/point
		light.set_color(0.20, 0.60, 0.90)
		light.set_brightness(0.3)
		light.attach(src)
		light.enable()

	proc/light_pattern(var/pattern as num)
		if (!pattern)
			icon_state = "lights0"
			light.disable()
			return
		if (isnum(pattern) && pattern > 0)
			icon_state = "lights[pattern]"
			light.enable()
			return

	verb/change_light_pattern()
		set src in oview(1)
		set category = "Local"

		var/pattern = input(usr, "Type number from 0 to 4", "Enter Number", 1) as null|num
		if (isnull(pattern))
			return
		pattern = minmax(pattern, 0, 4)
		light_pattern(pattern)

// Grinch Stuff

/obj/decal/cleanable/grinch_graffiti
	name = "un-jolly graffiti"
	desc = "Wow, rude."
	icon = 'icons/effects/graffiti.dmi'
	random_icon_states = list("grinch1","grinch2","grinch3","grinch4","grinch5","grinch6")

	disposing()
		modify_christmas_cheer(1)
		..()

// Santa Stuff

/obj/item/card/id/captains_spare/santa
	name = "Christmas Card"
	registered = "Santa Claus"
	assignment = "Christmas Spirit"

/mob/living/carbon/human/santa
	New()
		..()
		spawn (0)
			bioHolder.mobAppearance.customization_first = "Balding"
			bioHolder.mobAppearance.customization_second = "Full Beard"
			bioHolder.mobAppearance.customization_third = "Eyebrows"
			bioHolder.mobAppearance.customization_first_color = "#FFFFFF"
			bioHolder.mobAppearance.customization_second_color = "#FFFFFF"
			bioHolder.mobAppearance.customization_third_color = "#FFFFFF"

			spawn (10)
				bioHolder.mobAppearance.UpdateMob()

			real_name = "Santa Claus"
			desc = "Father Christmas! Santa Claus! Old Nick! ..wait, not that last one. I hope."
			gender = "male"

			equip_if_possible(new /obj/item/clothing/under/shorts/red(src), slot_w_uniform)
			equip_if_possible(new /obj/item/clothing/suit/space/santa(src), slot_wear_suit)
			equip_if_possible(new /obj/item/clothing/shoes/black(src), slot_shoes)
			equip_if_possible(new /obj/item/clothing/glasses/regular(src), slot_glasses)
			equip_if_possible(new /obj/item/clothing/head/helmet/space/santahat(src), slot_head)
			equip_if_possible(new /obj/item/storage/backpack(src), slot_back)
			equip_if_possible(new /obj/item/device/radio/headset(src), slot_ears)
			equip_if_possible(new /obj/item/card/id/captains_spare/santa(src), slot_wear_id)

	death()
		modify_christmas_cheer(-60)
		..()

	Del()
		modify_christmas_cheer(-30)
		..()
	verb
		santa_heal()
			set name = "Holiday Healing"
			set desc = "Heal everyone around you."
			set category = "Festive Fun"

			if (stat || transforming)
				boutput(src, "<span style=\"color:red\">You can't do that while you're incapacitated.</span>")
				return

			verbs -= /mob/living/carbon/human/santa/verb/santa_heal
			playsound(loc, "sound/effects/heavenly.ogg", 100, 1, 0)
			visible_message("<span style=\"color:red\"><strong>[src] calls on the power of Christmas to heal everyone!</strong></span>")
			for (var/mob/living/M in view(src,5))
				M.HealDamage("All", 30, 30)
			spawn (600)
				boutput(src, "<span style=\"color:blue\">You may now use your healing spell again.</span>")
				verbs += /mob/living/carbon/human/santa/verb/santa_heal

		santa_gifts()
			set name = "Christmas Presents"
			set desc = "Summon a whole bunch of Christmas presents!"
			set category = "Festive Fun"

			if (stat || transforming)
				boutput(src, "<span style=\"color:red\">You can't do that while you're incapacitated.</span>")
				return

			verbs -= /mob/living/carbon/human/santa/verb/santa_gifts
			visible_message("<span style=\"color:red\"><strong>[src] throws out a bunch of Christmas presents from nowhere!</strong></span>")
			playsound(usr.loc, "sound/machines/fortune_laugh.ogg", 25, 1, -1)
			transforming = 1
			var/to_throw = rand(3,12)

			var/list/nearby_turfs = list()

			for (var/turf/T in view(5,src))
				nearby_turfs += T

			while (to_throw > 0)
				var/obj/item/a_gift/festive/X = new /obj/item/a_gift/festive(loc)
				X.throw_at(pick(nearby_turfs), 16, 3)
				to_throw--
				sleep(2)
			transforming = 0

			spawn (1200)
				boutput(src, "<span style=\"color:blue\">You may now summon gifts again.</span>")
				verbs += /mob/living/carbon/human/santa/verb/santa_gifts

		santa_food()
			set name = "Christmas Goodies"
			set desc = "Summon a whole bunch of festive snacks!"
			set category = "Festive Fun"

			if (stat || transforming)
				boutput(src, "<span style=\"color:red\">You can't do that while you're incapacitated.</span>")
				return

			verbs -= /mob/living/carbon/human/santa/verb/santa_food
			visible_message("<span style=\"color:red\"><strong>[src] casts out a whole shitload of snacks from nowhere!</strong></span>")
			playsound(usr.loc, "sound/machines/fortune_laugh.ogg", 25, 1, -1)
			transforming = 1
			var/to_throw = rand(6,18)

			var/list/nearby_turfs = list()

			for (var/turf/T in view(5,src))
				nearby_turfs += T

			var/snack
			while (to_throw > 0)
				snack = pick(santa_snacks)
				var/obj/item/X = new snack(loc)
				X.throw_at(pick(nearby_turfs), 16, 3)
				to_throw--
				sleep(1)
			transforming = 0

			spawn (800)
				boutput(src, "<span style=\"color:blue\">You may now summon snacks again.</span>")
				verbs += /mob/living/carbon/human/santa/verb/santa_food

		santa_warmth()
			set name = "Winter Hearth"
			set desc = "Gives everyone near you temporary cold resistance."
			set category = "Festive Fun"

			if (stat || transforming)
				boutput(src, "<span style=\"color:red\">You can't do that while you're incapacitated.</span>")
				return

			verbs -= /mob/living/carbon/human/santa/verb/santa_warmth
			playsound(loc, "sound/effects/MagShieldUp.ogg", 100, 1, 0)
			visible_message("<span style=\"color:red\"><strong>[src] summons the warmth of a nice toasty fireplace!</strong></span>")
			for (var/mob/living/M in view(src,5))
				if (M.bioHolder)
					M.bioHolder.AddEffect("cold_resist", 0, 60)
			spawn (800)
				boutput(src, "<span style=\"color:blue\">You may now use your warmth spell again.</span>")
				verbs += /mob/living/carbon/human/santa/verb/santa_warmth

		santa_teleport()
			set name = "Christmas Warp"
			set desc = "Warp to somewhere else via the power of Christmas."
			set category = "Festive Fun"

			if (stat || transforming)
				boutput(src, "<span style=\"color:red\">You can't do that while you're incapacitated.</span>")
				return

			verbs -= /mob/living/carbon/human/santa/verb/santa_teleport
			var/A
			A = input("Area to jump to", "TELEPORTATION", A) in teleareas
			var/area/thearea = teleareas[A]

			visible_message("<span style=\"color:red\"><strong>[src] poofs away in a puff of cold, snowy air!</strong></span>")
			playsound(usr.loc, "sound/effects/bamf.ogg", 25, 1, -1)
			playsound(usr.loc, "sound/machines/fortune_laugh.ogg", 25, 1, -1)
			var/effects/system/harmless_smoke_spread/smoke = new /effects/system/harmless_smoke_spread()
			smoke.set_up(1, 0, usr.loc)
			smoke.attach(usr)
			smoke.start()
			var/list/L = list()
			for (var/turf/T in get_area_turfs(thearea.type))
				if (!T.density)
					var/clear = 1
					for (var/obj/O in T)
						if (O.density)
							clear = 0
							break
					if (clear)
						L+=T
			loc = pick(L)

			spawn (300)
				boutput(src, "<span style=\"color:blue\">You may now teleport again.</span>")
				verbs += /mob/living/carbon/human/santa/verb/santa_teleport

		santa_banish()
			set name = "Banish Krampus"
			set desc = "Get rid of Krampus. He may return if Christmas Cheer goes too low again though."
			set category = "Festive Fun"

			if (stat || transforming)
				boutput(src, "<span style=\"color:red\">You can't do that while you're incapacitated.</span>")
				return

			var/effects/system/harmless_smoke_spread/smoke = new /effects/system/harmless_smoke_spread()
			for (var/mob/living/carbon/wall/meatcube/krampus/K in view(7,src))
				visible_message("<span style=\"color:red\"><strong>[src] makes a stern gesture at [K]!</strong></span>")
				boutput(K, "<span style=\"color:red\">You have been banished by Santa Claus!</span>")
				playsound(usr.loc, "sound/effects/bamf.ogg", 25, 1, -1)
				smoke.set_up(1, 0, K.loc)
				smoke.attach(K)
				smoke.start()
				K.gib()
				krampus_spawned = 0


// Krampus Stuff

/mutantrace/krampus
	name = "krampus"
	icon_state = "predator"
	human_compatible = 0
	uses_human_clothes = 0
	voice_message = "bellows"
	jerk = 1

	sight_modifier()
		mob.sight |= SEE_MOBS
		mob.see_in_dark = SEE_DARK_FULL
		mob.see_invisible = 1

	movement_delay()
		return -2

/mob/living/carbon/human/krampus
	New()
		..()
		spawn (0)

			bioHolder.mobAppearance.customization_first = "None"
			bioHolder.mobAppearance.customization_second = "None"
			bioHolder.mobAppearance.customization_third = "None"
			spawn (10)
				bioHolder.mobAppearance.UpdateMob()

			mind = new
			real_name = "Krampus"
			desc = "Oh shit! Have you been naughty?!"

			if (!reagents)
				var/reagents/R = new/reagents(1000)
				reagents = R
				R.my_atom = src

			set_mutantrace(/mutantrace/krampus)
			reagents.add_reagent("stimulants", 50)
			gender = "male"
			bioHolder.AddEffect("loud_voice")
			bioHolder.AddEffect("cold_resist")

	Bump(atom/movable/AM, yes)
		if (stance == "krampage")
			if ((!( yes ) || now_pushing))
				return
			now_pushing = 1
			var/attack_strength = 2
			var/attack_text = "furiously pounds"
			var/attack_volume = 60
			if (health <= 80)
				attack_strength = 3
				attack_text = "pounds"
				attack_volume = 30
			else if (health < 50)
				attack_strength = 4
				attack_text = "weakly pounds"
				attack_volume = 5
			if (ismob(AM))
				var/mob/M = AM
				for (var/mob/C in viewers(src))
					shake_camera(C, 8, 3)
					C.show_message("<span style=\"color:red\"><strong>[src] tramples right over [M]!</strong></span>", 1)
				M.stunned = 8
				M.weakened = 5
				random_brute_damage(M, 10)
				M.take_brain_damage(rand(5,10))
				playsound(M.loc, "fleshbr1.ogg", attack_volume, 1, -1)
				playsound(M.loc, "loudcrunch2.ogg", attack_volume, 1, -1)
				if (istype(M.loc,/turf))
					loc = M.loc
			else if (isobj(AM))
				var/obj/O = AM
				if (O.density)
					playsound(O.loc, "sound/effects/bang.ogg", attack_volume, 1, 0, 0.4)
					for (var/mob/C in viewers(src))
						shake_camera(C, 8, 3)
						C.show_message("<span style=\"color:red\"><strong>[src] [attack_text] on [O]!</strong></span>", 1)
					if (istype(O, /obj/window) || istype(O, /obj/grille) || istype(O, /obj/machinery/door) || istype(O, /obj/structure/girder) || istype(O, /obj/foamedmetal))
						qdel(O)
					else
						O.ex_act(attack_strength)
			else if (isturf(AM))
				var/turf/T = AM
				if (T.density && istype(T,/turf/simulated/wall))
					for (var/mob/C in viewers(src))
						shake_camera(C, 8, 3)
						C.show_message("<span style=\"color:red\"><strong>[src] [attack_text] on [T]!</strong></span>", 1)
					playsound(T.loc, "sound/effects/bang.ogg", attack_volume, 1, 0, 0.4)
					T.ex_act(attack_strength)

			now_pushing = 0
		else
			..()
			return

	verb
		krampus_rampage()
			set name = "Krampage"
			set desc = "Go on a rampage, crushing everything in your path."
			set category = "Festive Fury"

			if (stat || transforming)
				boutput(src, "<span style=\"color:red\">You can't do that while you're incapacitated.</span>")
				return

			stance = "krampage"
			playsound(loc, "sound/effects/bull.ogg", 80, 1, 0, 0.4)
			visible_message("<span style=\"color:red\"><strong>[src] goes completely apeshit!</strong></span>")
			verbs -= /mob/living/carbon/human/krampus/verb/krampus_rampage
			spawn (300)
				stance = "normal"
				boutput(src, "<span style=\"color:red\">Your rage burns out for a while.</span>")
			spawn (1800)
				boutput(src, "<span style=\"color:blue\">You feel ready to rampage again.</span>")
				verbs += /mob/living/carbon/human/krampus/verb/krampus_rampage

		krampus_leap(var/mob/living/M as mob in oview(7))
			set name = "Krampus Leap"
			set desc = "Leap onto someone near you, crushing them underfoot."
			set category = "Festive Fury"

			if (stat || transforming)
				boutput(src, "<span style=\"color:red\">You can't do that while you're incapacitated.</span>")
				return

			var/turf/target
			if (isturf(M.loc))
				target = M.loc
			else
				return
			verbs -= /mob/living/carbon/human/krampus/verb/krampus_leap
			transforming = 1
			playsound(loc, "sound/misc/rustle5.ogg", 100, 1, 0, 0.3)
			visible_message("<span style=\"color:red\"><strong>[src] leaps high into the air, heading right for [M]!</strong></span>")
			animate_fading_leap_up(src)
			sleep(25)
			loc = target
			playsound(loc, "sound/effects/bull.ogg", 50, 1, 0, 0.8)
			animate_fading_leap_down(src)
			spawn (0)
				playsound(M.loc, "Explosion1.ogg", 50, 1, -1)
				for (var/mob/C in viewers(src))
					shake_camera(C, 10, 6)
					C.show_message("<span style=\"color:red\"><strong>[src] slams down onto the ground!</strong></span>", 1)
				for (var/turf/T in range(src,3))
					animate_shake(T,5,rand(3,8),rand(3,8))
				for (var/mob/living/X in range(src,1))
					if (X == src)
						continue
					X.ex_act(3)
					playsound(X.loc, "fleshbr1.ogg", 50, 1, -1)
				transforming = 0

			spawn (600)
				boutput(src, "<span style=\"color:blue\">You may now leap again.</span>")
				verbs += /mob/living/carbon/human/krampus/verb/krampus_leap

		krampus_stomp()
			set name = "Krampus Stomp"
			set desc = "Stomp everyone around you with your mighty feet."
			set category = "Festive Fury"

			if (stat || transforming)
				boutput(src, "<span style=\"color:red\">You can't do that while you're incapacitated.</span>")
				return

			verbs -= /mob/living/carbon/human/krampus/verb/krampus_stomp
			if (!stat && !transforming)
				for (var/mob/C in viewers(src))
					shake_camera(C, 10, 6)
					C.show_message("<span style=\"color:red\"><strong>[src] stomps the ground with \his huge feet!</strong></span>", 1)
				playsound(loc, "meteorimpact.ogg", 80, 1, 1, 0.6)
				for (var/mob/living/M in view(src,2))
					if (M == src)
						continue
					playsound(M.loc, "fleshbr1.ogg", 40, 1, -1)
					M.ex_act(3)
				for (var/turf/T in range(src,3))
					animate_shake(T,5,rand(3,8),rand(3,8))

				spawn (600)
					boutput(src, "<span style=\"color:blue\">You may now stomp again.</span>")
					verbs += /mob/living/carbon/human/krampus/verb/krampus_stomp

		krampus_teleport()
			set name = "Krampus Poof"
			set desc = "Warp to somewhere else via the power of Christmas."
			set category = "Festive Fury"

			if (stat || transforming)
				boutput(src, "<span style=\"color:red\">You can't do that while you're incapacitated.</span>")
				return

			verbs -= /mob/living/carbon/human/krampus/verb/krampus_teleport
			var/A
			A = input("Area to jump to", "TELEPORTATION", A) in teleareas
			var/area/thearea = teleareas[A]

			visible_message("<span style=\"color:red\"><strong>[src] poofs away in a puff of cold, snowy air!</strong></span>")
			playsound(usr.loc, "sound/effects/bamf.ogg", 25, 1, -1)
			var/effects/system/harmless_smoke_spread/smoke = new /effects/system/harmless_smoke_spread()
			smoke.set_up(1, 0, usr.loc)
			smoke.attach(usr)
			smoke.start()
			var/list/L = list()
			for (var/turf/T in get_area_turfs(thearea.type))
				if (!T.density)
					var/clear = 1
					for (var/obj/O in T)
						if (O.density)
							clear = 0
							break
					if (clear)
						L+=T
			loc = pick(L)

			usr.set_loc(pick(L))
			smoke.start()
			spawn (1800)
				boutput(src, "<span style=\"color:blue\">You may now teleport again.</span>")
				verbs += /mob/living/carbon/human/krampus/verb/krampus_teleport

		krampus_snatch(var/mob/living/M as mob in oview(1))
			set name = "Krampus Snatch"
			set desc = "Grab someone nearby you instantly."
			set category = "Festive Fury"

			if (stat || transforming)
				boutput(src, "<span style=\"color:red\">You can't do that while you're incapacitated.</span>")
				return

			if (istype(M))
				for (var/obj/item/grab/G in src)
					if (G.affecting == M)
						return
				visible_message("<span style=\"color:red\"><strong>[src] snatches up [M] in \his huge claws!</strong></span>")
				var/obj/item/grab/G = new /obj/item/grab( src )
				G.assailant = src
				usr.put_in_hand_or_drop(G)
				G.affecting = M
				M.grabbed_by += G
				M.stunned = max(10, M.stunned)
				G.state = 1
				G.update_icon()
				dir = get_dir(src, M)
				playsound(loc, "sound/misc/werewolf_attack3.ogg", 65, 1, 0, 0.5)
				playsound(loc, "sound/weapons/thudswoosh.ogg", 65, 1)

		krampus_crush()
			set name = "(G) Krampus Crush"
			set desc = "Gradually crush someone you have held in your claws."
			set category = "Festive Fury"

			if (stat || transforming)
				boutput(src, "<span style=\"color:red\">You can't do that while you're incapacitated.</span>")
				return

			for (var/obj/item/grab/G in src)
				if (ishuman(G.affecting))
					verbs -= /mob/living/carbon/human/krampus/verb/krampus_crush
					var/mob/living/carbon/human/H = G.affecting
					visible_message("<span style=\"color:red\"><strong>[src] begins squeezing [H] in \his hand!</strong></span>")
					H.loc = loc
					while (H.stat != 2)
						if (stat || transforming || get_dist(src,H) > 1)
							boutput(src, "<span style=\"color:red\">Your victim escaped! Curses!</span>")
							qdel(G)
							verbs += /mob/living/carbon/human/krampus/verb/krampus_crush
							return
						random_brute_damage(H, 10)
						H.stunned = 8
						H.weakened = 5
						if (H.health < 0)
							visible_message("<span style=\"color:red\"><strong>[H] bursts like a ripe melon! Holy shit!</strong></span>")
							H.gib()
							qdel(G)
							verbs += /mob/living/carbon/human/krampus/verb/krampus_crush
							return
						playsound(loc, "sound/misc/loudcrunch.ogg", 75, 0.7)
						H.UpdateDamage()
						H.UpdateDamageIcon()
						sleep(15)
				else
					playsound(loc, "sound/effects/splat.ogg", 75, 1)
					visible_message("<span style=\"color:red\"><strong>[src] crushes [G.affecting] like a bug!</strong></span>")
					G.affecting.gib()
					qdel(G)
					verbs += /mob/living/carbon/human/krampus/verb/krampus_crush
				break

		krampus_devour()
			set name = "(G) Krampus Devour"
			set desc = "Eat someone you have held in your claws, healing yourself a little."
			set category = "Festive Fury"

			if (stat || transforming)
				boutput(src, "<span style=\"color:red\">You can't do that while you're incapacitated.</span>")
				return

			for (var/obj/item/grab/G in src)
				if (ishuman(G.affecting))
					var/mob/living/carbon/human/H = G.affecting
					visible_message("<span style=\"color:red\"><strong>[src] raises [H] up to \his mouth! Oh shit!</strong></span>")
					H.loc = loc
					sleep(60)
					if (stat || transforming || get_dist(src,H) > 1)
						boutput(src, "<span style=\"color:red\">Your prey escaped! Curses!</span>")
					else
						visible_message("<span style=\"color:red\"><strong>[src] devours [H] whole!</strong></span>")
						playsound(loc, "sound/items/eatfood.ogg", 30, 1, -2)
						H.death(1)
						H.ghostize()
						qdel(H)
						qdel(G)
						HealDamage("All", 15, 15)
						sleep(10)
						playsound(loc, pick("sound/misc/burp_alien.ogg"), 50, 1, 0 ,0.5)