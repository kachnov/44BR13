/*
CONTAINS:

CUTLERY
MISC KITCHENWARE
*/

/obj/item/kitchen
	icon = 'icons/obj/kitchen.dmi'

/obj/item/kitchen/rollingpin
	name = "rolling pin"
	icon_state = "rolling_pin"
	inhand_image_icon = 'icons/mob/inhand/hand_food.dmi'
	force = 8.0
	throwforce = 10.0
	throw_speed = 2
	throw_range = 7
	w_class = 3.0
	desc = "A wooden tube, used to roll dough flat in order to make various edible objects. It's pretty sturdy."
	stamina_damage = 40
	stamina_cost = 15
	stamina_crit_chance = 2

/obj/item/kitchen/utensil
	inhand_image_icon = 'icons/mob/inhand/hand_food.dmi'
	force = 5.0
	w_class = 1.0
	throwforce = 5.0
	throw_speed = 3
	throw_range = 5
	flags = FPRINT | TABLEPASS | CONDUCT
	stamina_damage = 5
	stamina_cost = 10
	stamina_crit_chance = 15

	New()
		if (prob(60))
			pixel_y = rand(0, 4)
		return

/obj/item/kitchen/utensil/fork
	name = "fork"
	icon_state = "fork"
	hit_type = DAMAGE_STAB
	hitsound = 'sound/effects/bloody_stab.ogg'
	desc = "A multi-pronged metal object, used to pick up objects by piercing them. Helps with eating some foods."

	attack(mob/living/carbon/M as mob, mob/living/carbon/user as mob)
		if (user && user.bioHolder.HasEffect("clumsy") && prob(50))
			user.visible_message("<span style=\"color:red\"><strong>[user]</strong> fumbles [src] and stabs \himself.</span>")
			random_brute_damage(user, 10)
		if (!saw_surgery(M,user)) // it doesn't make sense, no. but hey, it's something.
			return ..()

	suicide(var/mob/user as mob)
		user.visible_message("<span style=\"color:red\"><strong>[user] stabs [src] right into \his heart!</strong></span>")
		blood_slash(user, 25)
		playsound(user.loc, hitsound, 50, 1)
		user.TakeDamage("chest", 150, 0)
		user.updatehealth()
		spawn (100)
			if (user)
				user.suiciding = 0
		return TRUE

/obj/item/kitchen/utensil/knife
	name = "knife"
	icon_state = "knife"
	hit_type = DAMAGE_CUT
	hitsound = 'sound/weapons/slashcut.ogg'
	force = 10.0
	throwforce = 10.0
	desc = "A long bit metal that is sharpened on one side, used for cutting foods. Also useful for butchering dead animals. And live ones."

	attack(mob/living/carbon/M as mob, mob/living/carbon/user as mob)
		if (user && user.bioHolder.HasEffect("clumsy") && prob(50))
			user.visible_message("<span style=\"color:red\"><strong>[user]</strong> fumbles [src] and cuts \himself.</span>")
			random_brute_damage(user, 20)
		if (!scalpel_surgery(M,user))
			return ..()

	suicide(var/mob/user as mob)
		user.visible_message("<span style=\"color:red\"><strong>[user] slashes \his own throat with [src]!</strong></span>")
		blood_slash(user, 25)
		user.TakeDamage("head", 150, 0)
		user.updatehealth()
		spawn (100)
			if (user)
				user.suiciding = 0
		return TRUE

/obj/item/kitchen/utensil/spoon
	name = "spoon"
	desc = "A metal object that has a handle and ends in a small concave oval. Used to carry liquid objects from the container to the mouth."
	icon_state = "spoon"

	attack(mob/living/carbon/M as mob, mob/living/carbon/user as mob)
		if (user && user.bioHolder.HasEffect("clumsy") && prob(50))
			user.visible_message("<span style=\"color:red\"><strong>[user]</strong> fumbles [src] and jabs \himself.</span>")
			random_brute_damage(user, 5)
		if (!spoon_surgery(M,user))
			return ..()

	suicide(var/mob/user as mob)
		user.visible_message("<span style=\"color:red\"><strong>[user] jabs [src] straight through \his eye and into \his brain!</strong></span>")
		blood_slash(user, 25)
		playsound(user.loc, hitsound, 50, 1)
		user.TakeDamage("head", 150, 0)
		user.updatehealth()
		spawn (100)
			if (user)
				user.suiciding = 0
		return TRUE

/obj/item/kitchen/food_box // I came in here just to make donut/egg boxes put the things in your hand when you take one out and I end up doing this instead, kill me. -haine
	name = "food box"
	desc = "A box that can hold food! Well, not this one, I mean. You shouldn't be able to see this one."
	icon = 'icons/obj/foodNdrink/food_related.dmi'
	icon_state = "donutbox"
	amount = 6
	var/box_type = "donutbox"
	var/contained_food = /obj/item/reagent_containers/food/snacks/donut
	var/contained_food_name = "donut"

	donut_box
		name = "donut box"
		desc = "A box for containing and transporting \"dough-nuts\", a popular ethnic food."

	egg_box
		name = "egg carton"
		desc = "A carton that holds a bunch of eggs. What kind of eggs? What grade are they? Are the eggs from space? Space chicken eggs?"
		icon_state = "eggbox"
		amount = 12
		box_type = "eggbox"
		contained_food = /obj/item/reagent_containers/food/snacks/ingredient/egg
		contained_food_name = "egg"

	lollipop
		name = "lollipop bowl"
		desc = "A little bowl of sugar-free lollipops, totally healthy in every way! They're medicinal, after all!"
		icon_state = "lpop8"
		amount = 8
		box_type = "lpop"
		contained_food = /obj/item/reagent_containers/food/snacks/lollipop
		contained_food_name = "lollipop"

	New()
		..()
		spawn (10)
			if (!ispath(contained_food))
				logTheThing("debug", src, null, "has a non-path contained_food, \"[contained_food]\", and is being disposed of to prevent errors")
				qdel(src)
				return

	get_desc(dist)
		if (dist <= 1)
			. += "There's [(amount > 0) ? amount : "no" ] [contained_food_name][s_es(amount)] in \the [src]."

	attackby(obj/item/W as obj, mob/user as mob)
		if (istype(W, contained_food))
			user.drop_item()
			W.set_loc(src)
			amount ++
			boutput(user, "You place \the [contained_food_name] back into \the [src].")
			update()
		else return ..()

	MouseDrop(mob/user as mob) // no I ain't even touchin this mess it can keep doin whatever it's doin
		if ((user == usr && (!( usr.restrained() ) && (!( usr.stat ) && (usr.contents.Find(src) || in_range(src, usr))))))
			if (usr.hand)
				if (!( usr.l_hand ))
					spawn ( 0 )
						attack_hand(usr, 1, 1)
						return
			else
				if (!( usr.r_hand ))
					spawn ( 0 )
						attack_hand(usr, 0, 1)
						return
		return

	attack_hand(mob/user as mob, unused, flag)
		if (flag)
			return ..()
		add_fingerprint(user)
		var/obj/item/reagent_containers/food/snacks/myFood = locate(contained_food) in src
		if (myFood)
			if (amount >= 1)
				amount--
			user.put_in_hand_or_drop(myFood)
			boutput(user, "You take \an [contained_food_name] out of \the [src].")
		else
			if (amount >= 1)
				amount--
				var/obj/item/reagent_containers/food/snacks/newFood = new contained_food(loc)
				user.put_in_hand_or_drop(newFood)
				boutput(user, "You take \an [contained_food_name] out of \the [src].")
		update()

	proc/update()
		icon_state = "[box_type][amount]"
		return

/obj/item/plate
	name = "plate"
	desc = "It's like a frisbee, but more dangerous!"
	icon = 'icons/obj/foodNdrink/food_related.dmi'
	icon_state = "plate"
	item_state = "zippo"
	throwforce = 3.0
	throw_speed = 3
	throw_range = 8
	force = 2
	rand_pos = 0

/obj/item/plate/attack(mob/M as mob, mob/user as mob)
	if (user.a_intent == INTENT_HARM)
		if (M == user)
			boutput(user, "<span style=\"color:red\"><strong>You smash the plate over your own head!</strong></span>")
		else
			M.visible_message("<span style=\"color:red\"><strong>[user] smashes [src] over [M]'s head!</strong></span>")
			logTheThing("combat", user, M, "smashes [src] over %target%'s head! ")
		random_brute_damage(M, force)
		M.weakened += rand(0,2)
		M.updatehealth()
		playsound(src, "shatter", 70, 1)
		var/obj/O = new /obj/item/raw_material/shard/glass(get_turf(M))
		if (material)
			O.setMaterial(copyMaterial(material))
		qdel(src)
	else
		M.visible_message("<span style=\"color:red\">[user] taps [M] over the head with [src].</span>")
		logTheThing("combat", user, M, "taps %target% over the head with [src].")

/obj/item/fish
	throwforce = 3
	force = 5
	icon = 'icons/obj/foodNdrink/food_related.dmi'
	inhand_image_icon = 'icons/mob/inhand/hand_food.dmi'
	w_class = 3
	var/fillet_type = /obj/item/reagent_containers/food/snacks/ingredient/meat/fish

	salmon
		name = "salmon"
		desc = "A commercial saltwater fish prized for its flavor."
		icon_state = "salmon"
		fillet_type = /obj/item/reagent_containers/food/snacks/ingredient/meat/fish/salmon

	carp
		name = "carp"
		desc = "A common run-of-the-mill carp."
		icon_state = "carp"

	bass
		name = "largemouth bass"
		desc = "A freshwater fish native to North America."
		icon_state = "bass"
		fillet_type = /obj/item/reagent_containers/food/snacks/ingredient/meat/fish/white

	red_herring
		name = "peculiarly coloured clupea pallasi"
		desc = "What is this? Why is this here? WHAT IS THE PURPOSE OF THIS?"
		icon_state = "red_herring"

/obj/item/fish/attack(mob/M as mob, mob/user as mob)
	if (user && user.bioHolder.HasEffect("clumsy") && prob(50))
		user.visible_message("<span style=\"color:red\"><strong>[user]</strong> swings [src] and hits \himself in the face!.</span>")
		user.weakened = max(2 * force, user.weakened)
		return
	else
		playsound(loc, pick('sound/weapons/slimyhit1.ogg', 'sound/weapons/slimyhit2.ogg'), 50, 1, -1)
		user.visible_message("<span style=\"color:red\"><strong>[user] slaps [M] with [src]!</strong>.</span>")

/obj/item/fish/attackby(var/obj/item/W as obj, var/mob/user as mob)
	if (istype(W, /obj/item/kitchen/utensil/knife))
		if (fillet_type)
			var/obj/fillet = new fillet_type(loc)
			user.put_in_hand_or_drop(fillet)
			boutput(user, "<span style=\"color:blue\">You skin and gut [src] using your knife.</span>")
			qdel(src)
			return
	..()
	return