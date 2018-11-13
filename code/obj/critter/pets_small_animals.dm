/obj/critter/floateye
	name = "floating thing"
	desc = "You have never seen something like this before."
	icon_state = "floateye"
	health = 10
	aggressive = 0
	defensive = 0
	wanderer = 1
	opensdoors = 0
	atkcarbon = 0
	atksilicon = 0
	butcherable = 1
	flying = 1

/obj/critter/roach
	name = "cockroach"
	desc = "An unpleasant insect that lives in filthy places."
	icon_state = "roach"
	density = 0
	health = 10
	aggressive = 0
	defensive = 0
	wanderer = 1
	opensdoors = 0
	atkcarbon = 0
	atksilicon = 0
	butcherable = 1

	attack_hand(mob/user as mob)
		if (alive && (user.a_intent != INTENT_HARM))
			visible_message("<span class='combat'><strong>[user]</strong> pets [src]!</span>")
			return
		if (prob(95))
			visible_message("<span class='combat'><strong>[user] stomps [src], killing it instantly!</strong></span>")
			CritterDeath()
			return
		..()

/obj/critter/mouse/remy
	name = "Remy"
	desc = "A rat.  In space... wait, is it wearing a chefs hat?"
	icon_state = "remy"
	health = 33
	aggressive = 0

/obj/critter/mouse
	name = "space-mouse"
	desc = "A mouse.  In space."
	icon_state = "mouse"
	density = 0
	health = 2
	aggressive = 1
	defensive = 1
	wanderer = 1
	opensdoors = 0
	atkcarbon = 0
	atksilicon = 0
	firevuln = 1
	brutevuln = 1
	butcherable = 1
	chases_food = 1
	health_gain_from_food = 2
	feed_text = "squeaks happily!"
	var/diseased = 0

	skinresult = /obj/item/material_piece/cloth/leather //YEP
	max_skins = 1

	New()
		..()
		if (prob(10))
			diseased = 1
		atkcarbon = diseased

	CritterAttack(mob/living/M)
		attacking = 1
		visible_message("<span class='combat'><strong>[src]</strong> bites [target]!</span>")
		random_brute_damage(target, 1)
		spawn (10)
			attacking = 0
		if (iscarbon(M))
			if (diseased && prob(10))
				if (prob(50))
					M.contract_disease(/ailment/disease/berserker, null, null, 1) // path, name, strain, bypass resist
				else
					M.contract_disease(/ailment/disease/space_madness, null, null, 1) // path, name, strain, bypass resist

/*	seek_target()
		if (target)
			task = "chasing"
			return
		var/list/visible = new()
		for (var/obj/item/reagent_containers/food/snacks/S in view(seekrange,src))
			visible.Add(S)
		if (food_target && visible.Find(food_target))
			task = "chasing food"
			return
		else task = "thinking"
		if (visible.len)
			food_target = visible[1]
			task = "chasing food"
		..()

	ai_think()
		if (task == "chasing food")
			if (food_target == null)
				task = "thinking"
			else if (get_dist(src, food_target) <= attack_range)
				task = "eating"
			else
				walk_to(src, food_target,1,4)
		else if (task == "eating")
			if (get_dist(src, food_target) > attack_range)
				task = "chasing food"
			else
				visible_message("<strong>[src]</strong> nibbles at [food_target].")
				playsound(loc,"sound/items/eatfood.ogg", rand(10,50), 1)
				if (food_target.reagents.total_volume > 0 && src.reagents.total_volume < 30)
					food_target.reagents.trans_to(src, 5)
				food_target.amount--
				spawn (25)
				if (food_target != null && food_target.amount <= 0)
					qdel(food_target)
					task = "thinking"
					food_target = null
		return ..()
*/
/obj/critter/opossum
	name = "space opossum"
	desc = "A possum that came from space. Or maybe went to space. Who knows how it got here?"
	icon_state = "possum"
	density = 1
	health = 15
	aggressive = 1
	defensive = 1
	wanderer = 1
	opensdoors = 0
	atkcarbon = 0
	atksilicon = 0
	firevuln = 1
	brutevuln = 1
	butcherable = 1
	pet_text = list("gently baps", "pets", "cuddles")

	skinresult = /obj/item/material_piece/cloth/leather
	max_skins = 1

	on_revive()
		..()
		visible_message("<span style=\"color:blue\"><strong>[src]</strong> stops playing dead and gets back up!</span>")
		alive = 1
		density = 1
		health = initial(health)
		icon_state = living_state ? living_state : initial(icon_state)
		target = null
		task = "wandering"
		return

	CritterDeath()
		..()
		spawn (rand(200,800))
			if (src)
				on_revive()
		return

/obj/critter/opossum/morty
	name = "Morty"
	generic = 0

var/list/cat_names = list("Gary", "Mittens", "Mr. Jingles", "Rex", "Jasmine", "Litterbox",
"Reginald", "Poosycat", "Dr. Purrsworthy", "Lt. Scratches", "Michael Catson",
"Fluffy", "Mr. Purrfect", "Lord Furstooth", "Lion-O", "Johnathan", "Gary Catglitter",
"Kitler", "Benito Mewssolini", "Chat de Gaulle", "Ratbag",
"Baron Fuzzykins, Defiler of Carpets", "Robert Meowgabe", "Chairman Meow", "Bacon",
"Prunella", "Poonella", "SEXCOPTER", "Fat, Lazy Piece of Shit", "Jones Mk. II",
"Jones Mk. III", "Jones Mk. IV", "Jones Mk.V", "Mr. Meowgi",
"Furrston von Purringsworth", "Garfadukecliff", "SyndiCat", "Rosa Fluffemberg",
"Karl Meowx", "Margaret Scratcher", "Marcel Purroust", "Franz Katka", "Das Katpital",
"Proletaricat", "Perestroikat", "Mewy P. Newton", "Fidel Catstro", "George Lucats",
"Lin Miao", "Felix Purrzhinsky", "Pol Pet", "Piggy", "Long Kitty")

// hi I added my childhood cats' names to the list cause I miss em, they aren't really funny names but they were great cats
// remove em if you want I guess
// - Haine

/obj/critter/cat
	name = "space-cat"
	desc = "A cat. In space."
	icon_state = "cat1"
	density = 0
	health = 10
	aggressive = 1
	defensive = 1
	wanderer = 1
	opensdoors = 0
	atkcarbon = 0
	atksilicon = 0
	firevuln = 1
	brutevuln = 1
	angertext = "hisses at"
	butcherable = 2
	var/cattype = 1
	var/randomize_cat = 1
	var/catnip = 0

	New()
		..()
		if (randomize_cat)
			name = pick(cat_names)

			#ifdef HALLOWEEN
			cattype = 3 //Black cats for halloween.
			icon_state = "cat[cattype]"
			#else
			cattype = rand(2,9)
			icon_state = "cat[cattype]"
			#endif

	seek_target()
		anchored = 0
		for (var/obj/critter/mouse/C in view(seekrange,src))
			if (target)
				task = "chasing"
				break
			if ((C.name == oldtarget_name) && (world.time < last_found + 100)) continue
			if (C.health < 0) continue

			attack = 1

			if (attack)
				target = C
				oldtarget_name = C.name
				visible_message("<span class='combat'><strong>[src]</strong> [angertext] [C.name]!</span>")
				task = "chasing"
				break
			else
				continue

	attackby(obj/item/W as obj, mob/living/user as mob)
		if (alive && istype(W, /obj/item/plant/herb/catnip))
			user.visible_message("<strong>[user]</strong> gives [name] the [W]!","You give [name] the [W].")
			catnip_effect()
			qdel(W)
		else
			..()

	CritterAttack(mob/M)
		if (ismob(M))
			attacking = 1
			var/attackCount = (catnip ? rand(4,8) : 1)
			while (attackCount-- > 0)
				visible_message("<span class='combat'><strong>[src]</strong> bites [target]!</span>")
				random_brute_damage(target, 2)
				sleep(2)

			spawn (10)
				attacking = 0

		else if (istype(M, /obj/critter/mouse)) //robust cat simulation.
			attacking = 1
			visible_message("<span class='combat'><strong>[src]</strong> bites [target]!</span>")
			target:health -= 2
			if (target:health <= 0 && target:alive)
				target:CritterDeath()
				attacking = 0

		return

	ChaseAttack(mob/M)
		visible_message("<span class='combat'><strong>[src]</strong> pounces on [M]!</span>")
		playsound(loc, "sound/weapons/genhit1.ogg", 50, 1, -1)

		if (ismob(M))
			M.stunned += rand(0,2)
			M.weakened += rand(0,1)

	attack_hand(mob/user as mob)
		if (alive && (user.a_intent != INTENT_HARM))
			visible_message("<span class='combat'><strong>[user]</strong> pets [src]!</span>")
			if (prob(10))
				for (var/mob/O in hearers(src, null))
					O.show_message("[src] purrs!",2)
			return
		else
			..()

		return

	CritterDeath()
		alive = 0
		density = 0
		icon_state = "cat[cattype]-dead"
		walk_to(src,0)
		visible_message("<strong>[src]</strong> dies!")
		if (prob(5))
			spawn (30)
				visible_message("<strong>[src]</strong> comes back to life, good thing he has 9 lives!")
				alive = 1
				density = 1
				health = 10
				icon_state = "cat[cattype]"
				return

	process()
		if (!..())
			return FALSE
		if (alive && catnip)

			spawn (0)
				var/x = rand(2,4)
				while (x-- > 0)
					pixel_x = rand(-6,6)
					pixel_y = rand(-6,6)
					sleep(2)

			if (prob(10))
				visible_message("[name] [pick("purrs","frolics","rolls about","does a cute cat thing of some sort")]!")

			if (catnip-- < 1)
				visible_message("[name] calms down.")

	proc/catnip_effect()
		if (catnip)
			return
		catnip = 45
		visible_message("[name]'s eyes dilate.")

	HasEntered(mob/living/carbon/M as mob)
		..()
		if (sleeping || !alive)
			return
		else if (ishuman(M) && prob(33))
			visible_message("<span class='combat'>[src] weaves around [M]'s legs and trips [him_or_her(M)]!</span>")
			M:weakened += 2
		return

/obj/critter/cat/jones
	name = "Jones"
	desc = "Jones the cat."
	icon_state = "cat1"
	health = 30
	randomize_cat = 0
	generic = 0

	emag_act(var/mob/user, var/obj/item/card/emag/E)
		if (!alive || (cattype == 7))
			return FALSE
		icon_state = "cat-emagged"
		cattype = 7
		if (user)
			user.show_text("You swipe down [src]'s back in a petting motion...")
		return TRUE

	attackby(obj/item/W as obj, mob/living/user as mob)
		if (istype(W, /obj/item/card/emag))
			emag_act(usr, W)
		else
			..()

/obj/critter/cat/goddamnittobba
	aggressive = 1
	New()
		..()
		catnip = rand(50,250)

	CritterAttack(mob/M)
		if (ismob(M))
			attacking = 1
			var/attackCount = (catnip ? rand(4,8) : 1)
			while (attackCount-- > 0)
				visible_message("<span class='combat'><strong>[src]</strong> claws at [target]!</span>")
				random_brute_damage(target, 6)
				sleep(2)

			spawn (10)
				attacking = 0

/obj/critter/dog/george
	name = "George"
	desc = "Good dog."
	icon_state = "george"
	var/doggy = "george"
	density = 1
	health = 100
	aggressive = 1
	defensive = 1
	wanderer = 1
	opensdoors = 0
	atkcarbon = 0
	atksilicon = 0 //set to 1 for robots as space cars
	firevuln = 1
	brutevuln = 1
	angertext = "growls at"
	butcherable = 0
	generic = 0
/*
	seek_target()
		anchored = 0
		for (var/obj/critter/cat/C in view(seekrange,src))
			if (target)
				task = "chasing"
				break
			if ((C.name == oldtarget_name) && (world.time < last_found + 100)) continue
			if (C.health < 0) continue

			attack = 1

			if (attack)
				target = C
				oldtarget_name = C.name
				visible_message("<span class='combat'><strong>[src]</strong> [angertext] [C.name]!</span>")
				task = "chasing"
				break
			else
				continue
*/
	CritterAttack(mob/M)
		if (ismob(M))
			attacking = 1
			visible_message("<span class='combat'><strong>[src]</strong> bites [target]!</span>")
			random_brute_damage(target, 2)
			spawn (10)
				attacking = 0

	/*	else if (istype(M, /obj/critter/cat)) //uncomment for robust dog simulation.
			attacking = 1
			visible_message("<span class='combat'><strong>[src]</strong> bites [target]!</span>")
			target:health -= 2
			if (target:health <= 0 && target:alive)
				target:CritterDeath()
				attacking = 0 */

		return

	ChaseAttack(mob/M)
		visible_message("<span class='combat'><strong>[src]</strong> jumps on [M]!</span>")
		playsound(loc, "sound/weapons/genhit1.ogg", 50, 1, -1)

		if (ismob(M))
			M.stunned += rand(0,2)
			M.weakened += rand(0,1)

	attack_hand(mob/user as mob)
		if (alive && (user.a_intent != INTENT_HARM))
			visible_message("<span class='combat'><strong>[user]</strong> pets [src]!</span>")
			if (prob(30))
				icon_state = "[doggy]-lying"
				for (var/mob/O in hearers(src, null))
					O.show_message("<span style=\"color:blue\"><strong>[src]</strong> flops on his back! Scratch that belly!</span>",2)
				spawn (30)
					icon_state = "[doggy]"
		else
			..(user)

	CritterDeath()
		alive = 0
		density = 0
		icon_state = "[doggy]-lying"
		walk_to(src,0)
		for (var/mob/O in hearers(src, null))
			O.show_message("<span class='combat'><strong>[src]</strong> [pick("tires","tuckers out","gets pooped")] and lies down!</span>")
		spawn (600)
			for (var/mob/O in hearers(src, null))
				O.show_message("<span style=\"color:blue\"><strong>[src]</strong> wags his tail and gets back up!</span>")
			alive = 1
			density = 1
			health = 100
			icon_state = "[doggy]"
		return

	proc/howl()
		if (prob(60))
			for (var/mob/O in hearers(src, null))
				O.show_message("<span class='combat'><strong>[src]</strong> [pick("howls","bays","whines","barks","croons")] to the music! He thinks he's singing!</span>")
				spawn (3)
				playsound(loc, pick("sound/misc/howl1.ogg","sound/misc/howl2.ogg","sound/misc/howl3.ogg","sound/misc/howl4.ogg","sound/misc/howl5.ogg","sound/misc/howl6.ogg"), 100, 0)

/obj/critter/dog/george/blair
	name = "Blair"
	icon_state = "pug"
	doggy = "pug"

/obj/critter/pig
	name = "space-pig"
	desc = "A pig. In space."
	icon_state = "pig"
	density = 1
	health = 15
	aggressive = 0
	defensive = 1
	wanderer = 1
	opensdoors = 0
	atkcarbon = 0
	atksilicon = 0
	firevuln = 1
	brutevuln = 1
	angertext = "oinks at"
	butcherable = 1
	meat_type = /obj/item/reagent_containers/food/snacks/ingredient/meat/bacon
	name_the_meat = 0

	skinresult = /obj/item/material_piece/cloth/leather
	max_skins = 2

	CritterDeath()
		..()
		reagents.add_reagent("beff", 50, null)
		return

	seek_target()
		anchored = 0
		for (var/obj/critter/mouse/C in view(seekrange,src))
			if (target)
				task = "chasing"
				break
			if ((C.name == oldtarget_name) && (world.time < last_found + 100)) continue
			if (C.health < 0) continue

			attack = 1

			if (attack)
				target = C
				oldtarget_name = C.name
				visible_message("<span class='combat'><strong>[src]</strong> [angertext] [C.name]!</span>")
				task = "chasing"
				break
			else
				continue

	CritterAttack(mob/M)
		if (ismob(M))
			attacking = 1
			visible_message("<span class='combat'><strong>[src]</strong> bites [target]!</span>")
			random_brute_damage(target, 2)
			spawn (10)
				attacking = 0
		return

	ChaseAttack(mob/M)
		visible_message("<span class='combat'><strong>[src]</strong> bites [M]!</span>")
		playsound(loc, "sound/weapons/genhit1.ogg", 50, 1, -1)

		if (ismob(M))
			M.stunned += rand(0,2)
			M.weakened += rand(0,1)

	on_pet()
		if (prob(10))
			for (var/mob/O in hearers(src, null))
				O.show_message("[src] purrs!",2)

/obj/critter/clownspider
	name = "clownspider"
	desc = "Holy shit, that's fucking creepy."
	icon_state = "clownspider"
	health = 5
	aggressive = 0
	defensive = 1
	wanderer = 1
	opensdoors = 0
	atkcarbon = 1
	atksilicon = 1
	butcherable = 0
	angertext = "honks angrily at"
	var/sound_effect = 'sound/items/bikehorn.ogg'
	var/item_shoes = /obj/item/clothing/shoes/clown_shoes
	var/item_mask = /obj/item/clothing/mask/clown_hat

	cluwne
		name = "cluwnespider"
		desc = "Oh my god, what is this thing?"
		icon_state = "cluwnespider"
		sound_effect = 'sound/voice/cluwnelaugh3.ogg'
		item_shoes = /obj/item/clothing/shoes/cursedclown_shoes
		item_mask = /obj/item/clothing/mask/cursedclown_hat

	attack_hand(mob/user as mob)
		if (alive && (user.a_intent != INTENT_HARM))
			visible_message("<span class='combat'><strong>[user]</strong> [pet_text] [src]!</span>")
			return
		if (prob(50))
			visible_message("<span class='combat'><strong>[user] stomps [src], killing it instantly!</strong></span>")
			CritterDeath()
			return
		..()

	CritterAttack(mob/M)
		if (ismob(M))
			attacking = 1
			visible_message("<span class='combat'><strong>[src]</strong> kicks [target] with its shoes!</span>")
			playsound(loc, "swing_hit", 30, 0)
			if (prob(10))
				playsound(loc, sound_effect, 50, 0)
			random_brute_damage(target, rand(0,1))
			spawn (10)
				attacking = 0

	ChaseAttack(mob/M)
		visible_message("<span class='combat'><strong>[src]</strong> [angertext] [M]!</span>")
		playsound(loc, sound_effect, 50, 0)
		M.stunned += rand(0,1)
		if (prob(25))
			M.weakened += rand(1,2)
			random_brute_damage(M, rand(1,2))

	CritterDeath()
		alive = 0
		playsound(loc, "sound/effects/splat.ogg", 75, 1)
		var/obj/decal/cleanable/blood/gibs/gib = null
		gib = new /obj/decal/cleanable/blood/gibs(loc)
		new item_shoes(loc)
		if (prob(25))
			new item_mask(loc)
		gib.streak(list(NORTH, NORTHEAST, NORTHWEST))
		qdel (src)

/obj/critter/owl
	name = "space owl"
	desc = "Did you know? By 2063, it is expected that there will be more owls on Earth than human beings."
	icon_state = "smallowl"
	density = 1
	health = 10
	aggressive = 1
	defensive = 1
	wanderer = 1
	opensdoors = 0
	atkcarbon = 0
	atksilicon = 0
	firevuln = 1
	brutevuln = 1
	angertext = "hoots at"
	butcherable = 2
	flying = 1

	attackby(obj/item/W as obj, mob/M as mob)
		if (istype(W,/obj/item/clothing/head/void_crown))
			var/data[] = new()
			data["ckey"] = M.ckey
			data["compID"] = M.computer_id
			data["ip"] = M.lastKnownIP
			data["reason"] = "Get out you nerd. Also, stop abusing your access to the commit messages."
			data["mins"] = 1440
			data["akey"] = "NERDBANNER"
			boutput(M, "<span style=\"color:red\"><BIG><strong>WELP, GUESS YOU SHOULDN'T BELIEVE EVERYTHING YOU READ!</strong></BIG></span>")
			addBan(1, data)
			del(M.client)
		else
			return ..(W, M)

	CritterAttack(mob/M)
		if (ismob(M))
			attacking = 1
			visible_message("<span class='combat'><strong>[src]</strong> pecks at [target]!</span>")
			random_brute_damage(target, 2)
			spawn (10)
				attacking = 0

		return

	ChaseAttack(mob/M)
		visible_message("<span class='combat'><strong>[src]</strong> swoops down upon [M]!</span>")
		playsound(loc, "sound/weapons/genhit1.ogg", 50, 1, -1)
		random_brute_damage(target, 1)

		return

/obj/item/reagent_containers/food/snacks/ingredient/egg/critter/owl
	name = "owl egg"
	critter_type = /obj/critter/owl

/obj/critter/goose
	name = "space goose"
	desc = "An offshoot species of <em>branta canadensis</em> adapted for space."
	icon_state = "goose"
	density = 1
	health = 20
	aggressive = 1
	defensive = 1
	wanderer = 1
	opensdoors = 1
	atkcarbon = 0
	atksilicon = 0
	firevuln = 1
	brutevuln = 1
	angertext = "hisses angrily at"
	butcherable = 1
	death_text = "%src% collapses and stops moving!"

	ai_think()
		..()
		if (task == "thinking" || task == "wandering")
			if (prob(20))
				if (!muted)
					visible_message("<strong>[src]</strong> honks!")
				playsound(loc, "sound/effects/goose.ogg", 70, 1)
		else
			if (prob(20))
				flick("goose2", src)
				playsound(loc, "sound/effects/cat_hiss.ogg", 50, 1)

	seek_target()
		..()
		if (target)
			flick("goose2", src)
			visible_message("<span class='combat'><strong>[src]</strong> [angertext] [target]!</span>")
			playsound(loc, "sound/effects/cat_hiss.ogg", 50, 1)

	CritterAttack(mob/M)
		if (ismob(M))
			attacking = 1
			flick("goose2", src)
			visible_message("<span class='combat'><strong>[src]</strong> bites [target]!</span>")
			playsound(loc, "swing_hit", 30, 0)
			random_brute_damage(target, 2)
			spawn (rand(1,10))
				attacking = 0
		return

	ChaseAttack(mob/M)
		flick("goose2", src)
		visible_message("<span class='combat'><strong>[src]</strong> tackles [M]!</span>")
		playsound(loc, "sound/weapons/genhit1.ogg", 50, 1, -1)

		if (ismob(M))
			M.stunned += rand(0,2)
			M.weakened += rand(0,1)

	on_pet()
		if (prob(10))
			visible_message("<strong>[src]</strong> honks!",2)
			playsound(loc, "sound/effects/goose.ogg", 50, 1)

/obj/item/reagent_containers/food/snacks/ingredient/egg/critter/goose
	name = "goose egg"
	critter_type = /obj/critter/goose

#define PARROT_MAX_WORDS 64		// may as well try and be careful I guess
#define PARROT_MAX_PHRASES 32	// doesn't hurt, does it?

/obj/critter/parrot // if you didn't want me to make a billion dumb parrot things you shouldn't have let me anywhere near the code so this is YOUR FAULT NOT MINE - Haine
	name = "space parrot"
	desc = "A spacefaring species of parrot."
	icon = 'icons/misc/bird.dmi'
	icon_state = "parrot"
	dead_state = "parrot-dead"
	density = 0
	health = 15
	aggressive = 0
	defensive = 1
	wanderer = 1
	opensdoors = 0 // this was funny for a while but now is less so
	atkcarbon = 0
	atksilicon = 0
	firevuln = 1
	brutevuln = 1
	angertext = "squawks angrily at"
	death_text = "%src% lets out a final weak squawk and keels over."
	butcherable = 1
	flying = 1
	health_gain_from_food = 2
	feed_text = "chirps happily!"
	var/species = "parrot"
	var/obj/item/treasure = null
	var/list/learned_words = list()
	var/list/learned_phrases = list()
	var/learn_words_chance = 33
	var/learn_phrase_chance = 10
	var/chatter_chance = 2
	var/obj/item/new_treasure = null
	var/turf/treasure_loc = null
	var/find_treasure_chance = 2
	var/destroys_treasure = 0
	var/impatience = 0
	var/can_fussle = 1

	get_desc()
		..()
		if (treasure)
			. += "<br>[src] is holding \a [treasure]."

	hear_talk(mob/M as mob, messages, heardname, lang_id)
		if (!alive || sleeping || !text)
			return
		var/m_id = (lang_id == "english" || lang_id == "") ? 1 : 2
		if (prob(learn_words_chance))
			learn_stuff(messages[m_id])
		if (prob(learn_phrase_chance))
			learn_stuff(messages[m_id], 1)

	proc/learn_stuff(var/message, var/learn_phrase = 0)
		if (!message)
			return
		if (!learn_phrase && learned_words.len >= PARROT_MAX_WORDS)
			return
		if (learn_phrase && learned_phrases.len >= PARROT_MAX_PHRASES)
			return

		if (learn_phrase)
			learned_phrases += message
		var/list/heard_stuff = splittext(message, " ")
		for (var/word in heard_stuff)
			if (copytext(word, -1) in list(".", ","))
				word = copytext(word, 1, -1)
			if (word in learned_words)
				continue
			if (!length(word)) // idk how things were ending up with blank words but um
				continue // hopefully this will stop that??
			learned_words += word
			//boutput(world, word)
			heard_stuff -= word

	proc/chatter()
		if (learned_phrases.len && prob(20))
			var/my_phrase = pick(learned_phrases)
			var/my_verb = pick("chatters", "chirps", "squawks", "mutters", "cackles", "mumbles")
			visible_message("<span class='game say'><span class='name'>[src]</span> [my_verb], \"[my_phrase]\"</span>")
		else if (learned_words.len)
			var/my_word = pick(learned_words) // :monocle:
			var/my_verb = pick("chatters", "chirps", "squawks", "mutters", "cackles", "mumbles")
			visible_message("<span class='game say'><span class='name'>[src]</span> [my_verb], \"[capitalize(my_word)]!\"</span>")

	proc/take_stuff()
		if (treasure)
			if (prob(2))
				visible_message("<span style=\"color:blue\"><strong>[src]</strong> drops its [treasure]!</span>")
				treasure.set_loc(loc)
				treasure = null
				impatience = 0
				walk_to(src, 0)
			else
				return
		if (new_treasure && treasure_loc)
			if ((get_dist(src, treasure_loc) <= 1) && (new_treasure.loc == treasure_loc))
				visible_message("<span class='combat'><strong>[src]</strong> picks up [new_treasure]!</span>")
				new_treasure.set_loc(src)
				treasure = new_treasure
				new_treasure = null
				treasure_loc = null
				impatience = 0
				walk_to(src, 0)
				return
			else if (new_treasure.loc == treasure_loc)
				if (get_dist(src, treasure_loc) > 4 || impatience > 8)
					new_treasure = null
					treasure_loc = null
					impatience = 0
					walk_to(src, 0)
					return
				else
					walk_to(src, treasure_loc)
					impatience ++

			else if (new_treasure.loc != treasure_loc)
				if (get_dist(new_treasure, src) > 4 || impatience > 8 || !isturf(new_treasure.loc))
					new_treasure = null
					treasure_loc = null
					impatience = 0
					walk_to(src, 0)
					return
				else
					walk_to(src, treasure_loc)
					impatience ++

	proc/find_stuff()
		var/list/stuff_near_me = list()
		for (var/obj/item/I in view(4, src))
			if (!isturf(I.loc))
				continue
			if (I.anchored || I.density)
				continue
			stuff_near_me += I
		if (stuff_near_me.len)
			new_treasure = pick(stuff_near_me)
			treasure_loc = get_turf(new_treasure.loc)
		else
			new_treasure = null
			treasure_loc = null

	proc/fussle()
		if (!can_fussle)
			return
		if (treasure && prob(10))
			if (!muted)
				visible_message("<span style=\"color:blue\"><strong>[src]</strong> [pick("fusses with", "picks at", "pecks at", "throws around", "waves around", "nibbles on", "chews on", "tries to pry open")] [treasure].</span>")
			if (prob(5))
				visible_message("<span style=\"color:blue\"><strong>[src]</strong> drops its [treasure]!</span>")
				treasure.set_loc(loc)
				treasure = null
				return
			else if (destroys_treasure && prob(1))
				visible_message("<span class='combat'><strong>[treasure] breaks!</strong></span>")
				new /obj/decal/cleanable/machine_debris(loc)
				qdel(treasure)
				treasure = null
				return
		else if (!treasure && new_treasure)
			take_stuff()
			return
		else if (!treasure && !new_treasure && prob(find_treasure_chance))
			find_stuff()
			if (new_treasure)
				take_stuff()
			return

	CritterDeath()
		..()
		if (treasure)
			treasure.set_loc(loc)
			treasure = null

	ai_think()
		if (task == "thinking" || task == "wandering")
			fussle()
			if (prob(chatter_chance) && !muted)
				chatter()
			if (prob(5) && !muted)
				visible_message("<span style=\"color:blue\"><strong>[src]</strong> [pick("chatters", "chirps", "squawks", "mutters", "cackles", "mumbles", "fusses", "preens", "clicks its beak", "fluffs up", "poofs up")]!</span>")
			if (prob(15))
				flick("[species]-flaploop", src)
		return ..()

	seek_target()
		..()
		if (target)
			flick("[species]-flaploop", src)

	CritterAttack(mob/M as mob)
		attacking = 1
		flick("[species]-flaploop", src)
		if (iscarbon(M))
			if (prob(60)) //Go for the eyes!
				visible_message("<span class='combat'><strong>[src]</strong> pecks [M] in the eyes!</span>")
				playsound(loc, "sound/effects/bloody_stabOLD.ogg", 30, 1)
				M.take_eye_damage(rand(2,10)) //High variance because the bird might not hit well
				if (prob(75) && !M.stat)
					M.emote("scream")
			else
				visible_message("<span class='combat'><strong>[src]</strong> bites [M]!</span>")
				playsound(loc, "swing_hit", 30, 0)
				random_brute_damage(M, 3)
		else if (isrobot(M))
			if (prob(10))
				visible_message("<span class='combat'><strong>[src]</strong> bites [M] and snips an important-looking cable!</span>")
				M:compborg_take_critter_damage(null, 0 ,rand(40,70))
				M.emote("scream")
			else
				visible_message("<span class='combat'><strong>[src]</strong> bites [M]!</span>")
				M:compborg_take_critter_damage(null, rand(1,5),0)

		spawn (rand(1,10))
			attacking = 0

	ChaseAttack(mob/M)
		visible_message("<span class='combat'><strong>[src]</strong> flails into [M]!</span>")
		playsound(loc, "sound/weapons/genhit1.ogg", 50, 1, -1)

		if (ismob(M))
			M.stunned += rand(0,2)
			M.weakened += rand(0,1)

	attack_ai(mob/user as mob)
		if (get_dist(user, src) < 2)
			return attack_hand(user)
		else
			return ..()

	attack_hand(mob/user as mob)
		if (alive)
			if (user.a_intent == INTENT_HARM)
				return ..()

			else if (user.a_intent == "disarm")
				user.visible_message ("<strong>[user]</strong> puts their hand up to [src] and says, \"Step up!\"")
				if (task == "attacking" && target)
					visible_message("<strong>[user]</strong> can't get [src]'s attention!")
					return
				if (prob(25))
					visible_message("[src] [pick("ignores","pays no attention to","warily eyes","turns away from")] [user]!")
					return
				else
					user.pulling = src
					wanderer = 0
					if (task == "wandering")
						task = "thinking"
					wrangler = user
					visible_message("[src] steps onto [user]'s hand!")
			else if (user.a_intent == "grab" && treasure)
				if (prob(25))
					visible_message("<span class='combat'><strong>[user]</strong> [pick("takes", "wrestles", "grabs")] [treasure] from [src]!</span>")
					user.put_in_hand_or_drop(treasure)
					treasure = null
				else
					visible_message("<span class='combat'><strong>[user]</strong> tries to [pick("take", "wrestle", "grab")] [treasure] from [src], but [src] won't let go!</span>")
			else
				visible_message("<strong>[user]</strong> [pick("gives [src] a scritch", "pets [src]", "cuddles [src]", "snuggles [src]")]!")
				if (prob(15))
					visible_message("<span style=\"color:blue\"><strong>[src]</strong> chirps happily!</span>")
				return
		else
			..()
		return

/*	attackby(obj/item/W as obj, mob/living/user as mob)
		if (!alive || sleeping)
			return ..()
		if (istype(W, /obj/item/reagent_containers/food/snacks) || istype(W, /obj/item/seed))
			user.visible_message("<strong>[user]</strong> feeds [W] to [src]!","You feed [W] to [src].")
			visible_message("<strong>[src]</strong> chirps happily!", 1)
			health = min(initial(health), health+10)
			qdel(W)
		else
			return ..()
*/
	proc/dance_response()
		if (!alive || sleeping)
			return
		if (prob(20))
			visible_message("<span style=\"color:blue\"><strong>[src]</strong> responds with a dance of its own!</span>")
			dance()
		else
			visible_message("<span style=\"color:blue\"><strong>[src]</strong> flaps and bobs [pick("to the beat", "in tune", "approvingly", "happily")].</span>")

	proc/dance()
		if (!alive || sleeping)
			return
		icon_state = "[species]-flap"
		spawn (38)
			icon_state = species
		return

/obj/critter/parrot/eclectus
	name = "space eclectus"
	desc = "A spacefaring species of <em>eclectus roratus</em>."
	species = null

	New()
		..()
		if (!species)
			species = pick("eclectus", "eclectusf")
			icon_state = species
			dead_state = "[species]-dead"

/obj/critter/parrot/eclectus/male
	icon_state = "eclectus"
	dead_state = "eclectus-dead"
	species = "eclectus"

/obj/critter/parrot/eclectus/female
	icon_state = "eclectusf"
	dead_state = "eclectusf-dead"
	species = "eclectusf"

/obj/critter/parrot/grey
	name = "space grey"
	desc = "A spacefaring species of <em>psittacus erithacus</em>."
	icon_state = "agrey"
	dead_state = "agrey-dead"
	species = "agrey"

/obj/critter/parrot/caique
	name = "space caique"
	desc = "A spacefaring species of parrot from the <em>pionites</em> genus."
	species = null

	New()
		..()
		if (!species)
			species = pick("bcaique", "wcaique")
			icon_state = species
			dead_state = "[species]-dead"
			switch (species)
				if ("bcaique")
					desc = "A spacefaring species of <em>pionites melanocephalus</em>."
				if ("wcaique")
					desc = "A spacefaring species of <em>pionites leucogaster</em>."

/obj/critter/parrot/caique/black
	desc = "A spacefaring species of <em>pionites melanocephalus</em>."
	icon_state = "bcaique"
	dead_state = "bcaique-dead"
	species = "bcaique"

/obj/critter/parrot/caique/white
	desc = "A spacefaring species of <em>pionites leucogaster</em>."
	icon_state = "wcaique"
	dead_state = "wcaique-dead"
	species = "wcaique"

/obj/critter/parrot/budgie
	name = "space budgerigar"
	desc = "A spacefaring species of <em>melopsittacus undulatus</em>."
	species = null

	New()
		..()
		if (!species)
			species = pick("gbudge", "bbudge", "bgbudge")
			icon_state = species
			dead_state = "[species]-dead"

/obj/critter/parrot/cockatiel
	name = "space cockatiel"
	desc = "A spacefaring species of <em>nymphicus hollandicus</em>."
	species = null

	New()
		..()
		if (!species)
			species = pick("tiel", "wtiel", "luttiel", "blutiel")
			icon_state = species
			dead_state = "[species]-dead"

/obj/critter/parrot/cockatoo
	name = "space cockatoo"
	desc = "A spacefaring species of parrot from the <em>cacatua</em> genus."
	species = null

	New()
		..()
		if (!species)
			species = pick("too", "utoo", "mtoo")
			icon_state = species
			dead_state = "[species]-dead"
			switch (species)
				if ("too")
					desc = "A spacefaring species of <em>cacatua galerita</em>."
				if ("utoo")
					desc = "A spacefaring species of <em>cacatua alba</em>."
				if ("mtoo")
					desc = "A spacefaring species of <em>lophochroa leadbeateri</em>."

/obj/critter/parrot/kea
	name = "space kea" // and its swedish brother space ikea
	desc = "A spacefaring species of <em>nestor notabillis</em>, also known as the 'space mountain parrot,' originating from Space Zealand."
	icon_state = "kea"
	dead_state = "kea-dead"
	species = "kea"
	find_treasure_chance = 15
	destroys_treasure = 1

/obj/critter/parrot/random
	species = null
	New()
		..()
		if (!parrot_species)
			logTheThing("debug", null, null, "One of haine's stupid parrot things is broken because var/list/parrot_species doesn't exist or something, go whine at her until she fixes it")
			return
		var/chosen_species = pick(parrot_species)
		if (chosen_species)
			species = chosen_species
			icon_state = chosen_species
			dead_state = "[chosen_species]-dead"
			if (islist(parrot_species[chosen_species]))
				var/list/stop_the_runtimes_please = parrot_species[chosen_species]
				name = "[quality_name ? "[quality_name] " : null][stop_the_runtimes_please[1]]"
				desc = stop_the_runtimes_please[2]

var/list/parrot_species = list(\
	"eclectus" = list(1 = "space eclectus", 2 = "A spacefaring species of <em>eclectus roratus</em>."),\
	"eclectusf" = list(1 = "space eclectus", 2 = "A spacefaring species of <em>eclectus roratus</em>."),\
	"agrey" = list(1 = "space grey", 2 = "A spacefaring species of <em>psittacus erithacus</em>."),\
	"bcaique" = list(1 = "space caique", 2 = "A spacefaring species of <em>pionites melanocephalus</em>."),\
	"wcaique" = list(1 = "space caique", 2 = "A spacefaring species of <em>pionites leucogaster</em>."),\
	"gbudge" = list(1 = "space budgerigar", 2 = "A spacefaring species of <em>melopsittacus undulatus</em>."),\
	"bbudge" = list(1 = "space budgerigar", 2 = "A spacefaring species of <em>melopsittacus undulatus</em>."),\
	"bgbudge" = list(1 = "space budgerigar", 2 = "A spacefaring species of <em>melopsittacus undulatus</em>."),\
	"tiel" = list(1 = "space cockatiel", 2 = "A spacefaring species of <em>nymphicus hollandicus</em>."),\
	"wtiel" = list(1 = "space cockatiel", 2 = "A spacefaring species of <em>nymphicus hollandicus</em>."),\
	"luttiel" = list(1 = "space cockatiel", 2 = "A spacefaring species of <em>nymphicus hollandicus</em>."),\
	"blutiel" = list(1 = "space cockatiel", 2 = "A spacefaring species of <em>nymphicus hollandicus</em>."),\
	"too" = list(1 = "space cockatoo", 2 = "A spacefaring species of <em>cacatua galerita</em>."),\
	"utoo" = list(1 = "space cockatoo", 2 = "A spacefaring species of <em>cacatua alba</em>."),\
	"mtoo" = list(1 = "space cockatoo", 2 = "A spacefaring species of <em>lophochroa leadbeateri</em>."),\
	"kea" = list(1 = "space kea", 2 = "A spacefaring species of <em>nestor notabillis</em>, also known as the 'space mountain parrot,' originating from Space Zealand.")\
	)

/obj/critter/parrot/random/testing
	learn_words_chance = 100
	learn_phrase_chance = 100
	chatter_chance = 100
	find_treasure_chance = 100

/obj/item/reagent_containers/food/snacks/ingredient/egg/critter/parrot
	name = "parrot egg"
	critter_type = /obj/critter/parrot/random
	critter_reagent = "flaptonium"

/obj/critter/seagull
	name = "space gull"
	desc = "A spacefaring species of bird from the <em>Laridae</em> family."
	icon_state = "gull"
	dead_state = "gull-dead"
	density = 0
	health = 15
	aggressive = 0
	defensive = 1
	wanderer = 1
	opensdoors = 0
	atkcarbon = 0
	atksilicon = 0
	firevuln = 1
	brutevuln = 1
	angertext = "caws angrily at"
	death_text = "%src% lets out a final weak caw and keels over."
	butcherable = 1
	flying = 1
	chases_food = 1
	health_gain_from_food = 2
	feed_text = "caws happily!"

/obj/critter/boogiebot
	name = "Boogiebot"
	desc = "A robot that looks ready to get down at any moment."
	icon_state = "boogie"
	density = 1
	health = 20
	aggressive = 1
	defensive = 1
	wanderer = 1
	opensdoors = 0
	atkcarbon = 0
	atksilicon = 0
	firevuln = 1
	brutevuln = 1
	angertext = "wonks angrily at"
	generic = 0
	var/dance_forever = 0
	death_text = "%src% stops dancing forever."

	proc/do_a_little_dance()
		if (icon_state == "boogie")
			if (!muted)
				var/msg = pick("beeps and boops","does a little dance","gets down tonight","is feeling funky","is out of control","gets up to get down","busts a groove","begins clicking and whirring","emits an excited bloop","can't contain itself","can dance if it wants to")
				visible_message("<strong>[src]</strong> [msg]!",2)
			icon_state = pick("boogie-d1","boogie-d2","boogie-d3")
			// maybe later make it ambient play a short chiptune here later or at least some new sound effect
			spawn (200)
				if (src) icon_state = "boogie"

	ai_think()
		..()
		if (task == "thinking" || task == "wandering")
			if (dance_forever || prob(2)) do_a_little_dance()

	seek_target()
		..()
		if (target)
			visible_message("<span class='combat'><strong>[src]</strong> [angertext] [target]!</span>")
			playsound(loc, "sound/vox/bizwarn.ogg", 50, 1)

	CritterAttack(mob/M)
		if (ismob(M))
			attacking = 1
			visible_message("<span class='combat'><strong>[src]</strong> bashes itself into [target]!</span>")
			playsound(loc, "swing_hit", 30, 0)
			random_brute_damage(target, 2)
			spawn (rand(1,10))
				attacking = 0
		return

	ChaseAttack(mob/M)
		visible_message("<span class='combat'><strong>[src]</strong> boogies right into [M]!</span>")
		playsound(loc, "sound/weapons/genhit1.ogg", 50, 1, -1)

		if (ismob(M))
			M.stunned += rand(0,2)
			M.weakened += rand(0,1)

	attack_hand(mob/user as mob)
		if (alive && (user.a_intent != INTENT_HARM))
			visible_message("<span class='combat'><strong>[user]</strong> pets [src]!</span>")
			if (prob(10)) do_a_little_dance()
			return
		else
			. = ..()