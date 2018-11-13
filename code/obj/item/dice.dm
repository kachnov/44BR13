#define MAX_DICE_GROUP 6
#define ROLL_WAIT_TIME 30

/obj/item/dice
	name = "die"
	desc = "A six-sided die."
	icon = 'icons/obj/items.dmi'
	icon_state = "dice"
	throwforce = 0
	w_class = 1.0
	stamina_damage = 2
	stamina_cost = 2
	var/sides = 6
	var/last_roll = null
	var/last_roll_time = null
	var/list/dicePals = list() // for combined dice rolls, up to 9 in a stack
	var/sound_roll = 'sound/misc/dicedrop.ogg'
	module_research = list("vice" = 5)
	module_research_type = /obj/item/dice
	rand_pos = 1

	get_desc()
		if (last_roll && !dicePals.len)
			if (isnum(last_roll))
				. += "<br>[src] currently shows [get_english_num(last_roll)]."
			else
				. += "<br>[src] currently shows [last_roll]."

	suicide(var/mob/user as mob)
		user.visible_message("<span style=\"color:red\"><strong>[user] attempts to swallow [src] and chokes on it.</strong></span>")
		user.take_oxygen_deprivation(160)
		user.updatehealth()
		spawn (100)
			if (user)
				user.suiciding = 0
		return TRUE

	proc/roll_dat_thang() // fine if I can't use proc/roll() then we'll all just have to suffer this
		if (last_roll_time && world.time < (last_roll_time + ROLL_WAIT_TIME))
			return
		var/roll_total = null

		if (sound_roll)
			playsound(get_turf(src), sound_roll, 100, 1)

		set_loc(get_turf(src))
		pixel_y = rand(-8,8)
		pixel_x = rand(-8,8)

		name = initial(name)
		desc = initial(desc)
		overlays = null

		if (sides && isnum(sides))
			last_roll = rand(1, sides)
			roll_total = last_roll
			visible_message("[src] shows [get_english_num(last_roll)].")

			#ifdef HALLOWEEN
			if (last_roll == 13 && prob(5))
				var/turf/T = get_turf(src)
				for (var/obj/machinery/power/apc/apc in get_area(T))
					apc.overload_lighting()

				playsound(T, 'sound/effects/ghost.ogg', 75, 0)
				new /obj/critter/bloodling(T)
			#endif

		else if (sides && islist(sides) && sides:len)
			last_roll = pick(sides)
			visible_message("[src] shows <em>[last_roll]</em>.")
		else
			last_roll = null
			src.visible_message("[src] shows... um. Something. It hurts to look at. [pick("What the fuck?", "You should probably find the chaplain.")]")

		if (dicePals.len)
			shuffle(dicePals) // so they don't all roll in the same order they went into the pile
			for (var/obj/item/dice/D in dicePals)
				D.set_loc(get_turf(src))
				if (prob(75))
					step_rand(D)
				roll_total += D.roll_dat_thang()
			dicePals = list()
			visible_message("<strong>The total of all the dice is [roll_total < 999999 ? "[get_english_num(roll_total)]" : "[roll_total]"].</strong>")
		return roll_total

	proc/addPal(var/obj/item/dice/Pal, var/mob/user as mob)
		if (!Pal || Pal == src || !istype(Pal, /obj/item/dice) || (src.dicePals.len + Pal.dicePals.len) >= MAX_DICE_GROUP)
			return FALSE
		if (istype(Pal.loc, /obj/item/storage))
			return FALSE

		dicePals += Pal

		if (Pal.dicePals.len)

			for (var/obj/item/dice/D in Pal.dicePals)
				if (istype(D.loc, /obj/item/storage))
					Pal.dicePals -= D
					continue
				if (ismob(D.loc))
					D.loc:u_equip(D)
				D.set_loc(src)

			dicePals |= Pal.dicePals // |= adds things to lists that aren't already present
			Pal.dicePals = list()

		if (ismob(Pal.loc))
			Pal.loc:u_equip(Pal)
		Pal.set_loc(src)

		var/image/die_overlay = image(Pal.icon, Pal.icon_state)
		die_overlay.pixel_y = Pal.pixel_y
		die_overlay.pixel_x = Pal.pixel_x
		overlays += die_overlay
		name = "bunch of dice"
		desc = "Some dice, bunched up together and ready to be thrown."
		return TRUE

	attackby(obj/item/W, mob/user)
		if (istype(W, /obj/item/dice))
			if (addPal(W, user))
				user.show_text("You add [W] to [src].")
		else
			return ..()

	attack_self(mob/user as mob)
		user.u_equip(src)
		roll_dat_thang()

	throw_impact(var/turf/T)
		..()
		roll_dat_thang()

	MouseDrop_T(atom/movable/O as mob|obj, mob/user as mob)
		if (istype(O, /obj/item/dice))
			if (addPal(O, user))
				user.visible_message("<strong>[user]</strong> gathers up some dice.",\
				"You gather up some dice.")
				spawn (2)
					for (var/obj/item/dice/D in range(1, user))
						if (D == src)
							continue
						if (!addPal(D, user))
							break
						else
							sleep(2)
					return
		else
			return ..()

/obj/item/dice/coin // dumb but it helped test non-numeric rolls
	name = "coin"
	desc = "A little coin that will probably vanish into a couch eventually."
	icon_state = "coin-silver"
	sides = list("heads", "tails")
	sound_roll = 'sound/misc/coindrop.ogg'

/obj/item/dice/magic8ball // farte
	name = "magic 8 ball"
	desc = "Think of a yes-or-no question, shake it, and it'll tell you the answer! You probably shouldn't use it for playing an actual game of pool."
	icon_state = "8ball"
	sides = list("It is certain",\
	"It is decidedly so",\
	"Without a doubt",\
	"Yes definitely",\
	"You may rely on it",\
	"As I see it, yes",\
	"Most likely",\
	"Outlook good",\
	"Yes",\
	"Signs point to yes",\
	"Reply hazy try again",\
	"Ask again later",\
	"Better not tell you now",\
	"Cannot predict now",\
	"Concentrate and ask again",\
	"Don't count on it",\
	"My reply is no",\
	"My sources say no",\
	"Outlook not so good",\
	"Very doubtful")
	sound_roll = 'sound/items/liquid_shake.ogg'

	addPal()
		return FALSE

	suicide(var/mob/user as mob)
		user.visible_message("<span style=\"color:red\"><strong>[user] drop kicks the [src], but it barely moves!</strong></span>")
		user.visible_message("[src] shows <em>[pick("Goodbye","You done fucked up now","Time to die","Outlook terrible","That was a mistake","You should not have done that","Foolish","Very well")]</em>.")
		user.u_equip(src)
		set_loc(user.loc)
		spawn (10)
			user.visible_message("<span style=\"color:red\"><strong>[user] is crushed into a bloody ball by an unseen force, and vanishes into nothingness!</strong></span>")
			user.implode()
		return TRUE

/obj/item/dice/d4
	name = "\improper D4"
	desc = "A tetrahedral die informally known as a D4."
	icon_state = "d4"
	sides = 4

/obj/item/dice/d10
	name = "\improper D10"
	desc = "A decahedral die informally known as a D10."
	icon_state = "d20"
	sides = 10

/obj/item/dice/d12
	name = "\improper D12"
	desc = "A dodecahedral die informally known as a D12."
	icon_state = "d20"
	sides = 12

/obj/item/dice/d20
	name = "\improper D20"
	desc = "An icosahedral die informally known as a D20."
	icon_state = "d20"
	sides = 20

/obj/item/dice/d100
	name = "\improper D100"
	desc = "It's not so much a die as much as it is a ball with numbers on it."
	icon_state = "d100"
	sides = 100

/obj/item/dice/d1
	name = "\improper D1"
	desc = "Uh. It has... one side? I guess? Maybe?"
	icon_state = "dice"
	sides = 1

/obj/item/dice_bot
	name = "Probability Cube"
	desc = "A device for the calculation of random probabilities. Especially ones between one and six."
	icon = 'icons/obj/items.dmi'
	icon_state = "dice"
	w_class = 1.0
	var/sides = 6
	var/last_roll = null

	New()
		..()
		name = "[initial(name)] (d[sides])"

	proc/roll_dat_thang()
		playsound(get_turf(src), "sound/misc/dicedrop.ogg", 100, 1)
		if (sides && isnum(sides))
			last_roll = get_english_num(rand(1, sides))
			visible_message("[src] shows [last_roll].")
		else
			last_roll = null
			src.visible_message("[src] shows... um. This isn't a number. It hurts to look at. [pick("What the fuck?", "You should probably find the chaplain.")]")

	attack_self(var/mob/user as mob)
		roll_dat_thang()

	d4
		icon_state = "d4"
		sides = 4
	d10
		icon_state = "d20"
		sides = 10
	d12
		icon_state = "d20"
		sides = 12
	d20
		icon_state = "d20"
		sides = 20
	d100
		icon_state = "d100"
		sides = 100

#undef MAX_DICE_GROUP