/cookingrecipe
	var/item1 = null
	var/item2 = null
	var/item3 = null
	var/item4 = null
	var/amt1 = 1
	var/amt2 = 1
	var/amt3 = 1
	var/amt4 = 1
	var/cookbonus = null // how much cooking it needs to get a healing bonus
	var/output = null // what you get from this recipe
	var/useshumanmeat = 0 // used for naming of human meat dishes after their victims

	proc/specialOutput(var/obj/submachine/ourCooker)
		return null //If returning an object, that is used as the output

/cookingrecipe/humanburger
	item1 = /obj/item/reagent_containers/food/snacks/ingredient/dough
	item2 = /obj/item/reagent_containers/food/snacks/ingredient/meat/humanmeat
	cookbonus = 13
	output = /obj/item/reagent_containers/food/snacks/burger/humanburger
	useshumanmeat = 1

/cookingrecipe/monkeyburger
	item1 = /obj/item/reagent_containers/food/snacks/ingredient/dough
	item2 = /obj/item/reagent_containers/food/snacks/ingredient/meat/monkeymeat
	cookbonus = 13
	output = /obj/item/reagent_containers/food/snacks/burger/monkeyburger

/cookingrecipe/fishburger
	item1 = /obj/item/reagent_containers/food/snacks/ingredient/dough
	item2 = /obj/item/reagent_containers/food/snacks/ingredient/meat/fish
	cookbonus = 14
	output = /obj/item/reagent_containers/food/snacks/burger/fishburger

/cookingrecipe/synthburger
	item1 = /obj/item/reagent_containers/food/snacks/ingredient/dough
	item2 = /obj/item/reagent_containers/food/snacks/ingredient/meat/synthmeat
	cookbonus = 13
	output = /obj/item/reagent_containers/food/snacks/burger/synthburger

/cookingrecipe/mysteryburger
	item1 = /obj/item/reagent_containers/food/snacks/ingredient/dough
	item2 = /obj/item/reagent_containers/food/snacks/ingredient/meat/mysterymeat
	cookbonus = 13
	output = /obj/item/reagent_containers/food/snacks/burger/mysteryburger

/cookingrecipe/cheeseburger
	item1 = /obj/item/reagent_containers/food/snacks/ingredient/dough
	item2 = /obj/item/reagent_containers/food/snacks/ingredient/meat/
	item3 = /obj/item/reagent_containers/food/snacks/ingredient/cheese
	cookbonus = 14
	output = /obj/item/reagent_containers/food/snacks/burger/cheeseburger

/cookingrecipe/cheeseburger_m
	item1 = /obj/item/reagent_containers/food/snacks/ingredient/dough
	item2 = /obj/item/reagent_containers/food/snacks/ingredient/meat/monkeymeat
	item3 = /obj/item/reagent_containers/food/snacks/ingredient/cheese
	cookbonus = 14
	output = /obj/item/reagent_containers/food/snacks/burger/cheeseburger_m

/cookingrecipe/assburger
	item1 = /obj/item/reagent_containers/food/snacks/ingredient/dough
	item2 = /obj/item/clothing/head/butt
	cookbonus = 15
	output = /obj/item/reagent_containers/food/snacks/burger/assburger

/cookingrecipe/heartburger
	item1 = /obj/item/reagent_containers/food/snacks/ingredient/dough
	item2 = /obj/item/organ/heart
	cookbonus = 15
	output = /obj/item/reagent_containers/food/snacks/burger/heartburger

/cookingrecipe/brainburger
	item1 = /obj/item/reagent_containers/food/snacks/ingredient/dough
	item2 = /obj/item/organ/brain
	cookbonus = 15
	output = /obj/item/reagent_containers/food/snacks/burger/brainburger

/cookingrecipe/roburger
	item1 = /obj/item/reagent_containers/food/snacks/ingredient/dough
	item2 = /obj/item/parts/robot_parts/head
	cookbonus = 15
	output = /obj/item/reagent_containers/food/snacks/burger/roburger

/cookingrecipe/baconburger
	item1 = /obj/item/reagent_containers/food/snacks/ingredient/dough
	item2 = /obj/item/reagent_containers/food/snacks/ingredient/meat/bacon
	cookbonus = 13
	output = /obj/item/reagent_containers/food/snacks/burger/baconburger

/cookingrecipe/baconator
	item1 = /obj/item/reagent_containers/food/snacks/ingredient/dough
	item2 = /obj/item/reagent_containers/food/snacks/ingredient/meat
	amt2 = 2
	item3 = /obj/item/reagent_containers/food/snacks/ingredient/cheese
	cookbonus = 14
	output = /obj/item/reagent_containers/food/snacks/burger/bigburger

/cookingrecipe/monster
	item1 = /obj/item/reagent_containers/food/snacks/burger/bigburger
	amt1 = 4
	cookbonus = 20
	output = /obj/item/reagent_containers/food/snacks/burger/monsterburger

/cookingrecipe/swede_mball
	item1 = /obj/item/reagent_containers/food/snacks/meatball
	amt1 = 2
	item2 = /obj/item/reagent_containers/food/snacks/ingredient/flour
	item3 = /obj/item/reagent_containers/food/snacks/ingredient/egg
	cookbonus = 10
	output = /obj/item/reagent_containers/food/snacks/swedishmeatball

/cookingrecipe/donkpocket
	item1 = /obj/item/reagent_containers/food/snacks/ingredient/dough
	item2 = /obj/item/reagent_containers/food/snacks/meatball
	cookbonus = 10
	output = /obj/item/reagent_containers/food/snacks/donkpocket/warm

/cookingrecipe/donkpocket2
	item1 = /obj/item/reagent_containers/food/snacks/donkpocket
	cookbonus = 10
	output = /obj/item/reagent_containers/food/snacks/donkpocket/warm

/cookingrecipe/donut
	item1 = /obj/item/reagent_containers/food/snacks/ingredient/dough
	item2 = /obj/item/reagent_containers/food/snacks/ingredient/sugar
	cookbonus = 6
	output = /obj/item/reagent_containers/food/snacks/donut

/cookingrecipe/ice_cream_cone
	item1 = /obj/item/reagent_containers/food/snacks/ingredient/dough_s
	item2 = /obj/item/reagent_containers/food/snacks/ingredient/sugar
	cookbonus = 6
	output = /obj/item/reagent_containers/food/snacks/ice_cream_cone

/cookingrecipe/nougat
	item1 = /obj/item/reagent_containers/food/snacks/ingredient/honey
	item2 = /obj/item/reagent_containers/food/snacks/ingredient/sugar
	cookbonus = 5
	output = /obj/item/reagent_containers/food/snacks/candy/nougat

/cookingrecipe/waffles
	item1 = /obj/item/reagent_containers/food/snacks/ingredient/dough
	item2 = /obj/item/reagent_containers/food/snacks/ingredient/dough_s
	cookbonus = 10
	output = /obj/item/reagent_containers/food/snacks/waffles

/cookingrecipe/spaghetti_p
	item1 = /obj/item/reagent_containers/food/snacks/ingredient/spaghetti
	cookbonus = 16
	output = /obj/item/reagent_containers/food/snacks/spaghetti

/cookingrecipe/spaghetti_t
	item1 = /obj/item/reagent_containers/food/snacks/ingredient/spaghetti
	item2 = /obj/item/reagent_containers/food/snacks/condiment/ketchup
	cookbonus = 16
	output = /obj/item/reagent_containers/food/snacks/spaghetti/sauce

/cookingrecipe/spaghetti_s
	item1 = /obj/item/reagent_containers/food/snacks/ingredient/spaghetti
	item2 = /obj/item/reagent_containers/food/snacks/condiment/hotsauce
	cookbonus = 16
	output = /obj/item/reagent_containers/food/snacks/spaghetti/spicy

/cookingrecipe/spaghetti_m
	item1 = /obj/item/reagent_containers/food/snacks/ingredient/spaghetti
	item2 = /obj/item/reagent_containers/food/snacks/meatball
	cookbonus = 16
	output = /obj/item/reagent_containers/food/snacks/spaghetti/meatball

/cookingrecipe/spooky_bread
	item1 = /obj/item/reagent_containers/food/snacks/ingredient/dough
	item3 = /obj/item/reagent_containers/food/snacks/ectoplasm
	cookbonus = 8
	output = /obj/item/reagent_containers/food/snacks/breadloaf/spooky

/cookingrecipe/elvis_bread
	item1 = /obj/item/reagent_containers/food/snacks/ingredient/dough
	item2 = /obj/item/reagent_containers/food/snacks/plant/banana
	item3 = /obj/item/reagent_containers/food/snacks/ingredient/peanutbutter
	cookbonus = 8
	output = /obj/item/reagent_containers/food/snacks/breadloaf/elvis

/cookingrecipe/banana_bread
	item1 = /obj/item/reagent_containers/food/snacks/ingredient/dough
	item2 = /obj/item/reagent_containers/food/snacks/plant/banana
	item3 = /obj/item/reagent_containers/food/snacks/ingredient/sugar
	cookbonus = 8
	output = /obj/item/reagent_containers/food/snacks/breadloaf/banana

/cookingrecipe/banana_bread_alt
	item1 = /obj/item/reagent_containers/food/snacks/ingredient/dough_s
	item2 = /obj/item/reagent_containers/food/snacks/plant/banana
	cookbonus = 8
	output = /obj/item/reagent_containers/food/snacks/breadloaf/banana

/cookingrecipe/cornbread1
	item1 = /obj/item/reagent_containers/food/snacks/ingredient/dough
	item2 = /obj/item/reagent_containers/food/snacks/plant/corn
	cookbonus = 6
	output = /obj/item/reagent_containers/food/snacks/breadloaf/corn

/cookingrecipe/cornbread2
	item1 = /obj/item/reagent_containers/food/snacks/ingredient/dough_s
	item2 = /obj/item/reagent_containers/food/snacks/plant/corn
	cookbonus = 6
	output = /obj/item/reagent_containers/food/snacks/breadloaf/corn/sweet

/cookingrecipe/cornbread3
	item1 = /obj/item/reagent_containers/food/snacks/ingredient/dough
	item2 = /obj/item/reagent_containers/food/snacks/plant/corn
	item3 = /obj/item/reagent_containers/food/snacks/ingredient/sugar
	cookbonus = 6
	output = /obj/item/reagent_containers/food/snacks/breadloaf/corn/sweet

/cookingrecipe/cornbread4
	item1 = /obj/item/reagent_containers/food/snacks/ingredient/dough
	item2 = /obj/item/reagent_containers/food/snacks/plant/corn
	item3 = /obj/item/reagent_containers/food/snacks/ingredient/honey
	cookbonus = 6
	output = /obj/item/reagent_containers/food/snacks/breadloaf/corn/sweet/honey

/cookingrecipe/pumpkin_bread
	item1 = /obj/item/reagent_containers/food/snacks/ingredient/dough
	item2 = /obj/item/reagent_containers/food/snacks/plant/pumpkin
	cookbonus = 8
	output = /obj/item/reagent_containers/food/snacks/breadloaf/pumpkin

/cookingrecipe/bread
	item1 = /obj/item/reagent_containers/food/snacks/ingredient/dough
	cookbonus = 8
	output = /obj/item/reagent_containers/food/snacks/breadloaf

/cookingrecipe/honeywheat_bread
	item1 = /obj/item/reagent_containers/food/snacks/ingredient/dough
	item2 = /obj/item/reagent_containers/food/snacks/ingredient/honey
	cookbonus = 8
	output = /obj/item/reagent_containers/food/snacks/breadloaf/honeywheat

/cookingrecipe/brain_bread
	item1 = /obj/item/reagent_containers/food/snacks/breadloaf
	item2 = /obj/item/organ/brain
	cookbonus = 4
	output = /obj/item/reagent_containers/food/snacks/breadloaf/brain

/cookingrecipe/toast
	item1 = /obj/item/reagent_containers/food/snacks/breadslice
	cookbonus = 5
	output = /obj/item/reagent_containers/food/snacks/breadslice/toastslice

/cookingrecipe/toast_banana
	item1 = /obj/item/reagent_containers/food/snacks/breadslice/banana
	cookbonus = 5
	output = /obj/item/reagent_containers/food/snacks/breadslice/toastslice/banana

/cookingrecipe/toast_brain
	item1 = /obj/item/reagent_containers/food/snacks/breadslice/brain
	cookbonus = 5
	output = /obj/item/reagent_containers/food/snacks/breadslice/toastslice/brain

/cookingrecipe/toast_elvis
	item1 = /obj/item/reagent_containers/food/snacks/breadslice/elvis
	cookbonus = 5
	output = /obj/item/reagent_containers/food/snacks/breadslice/toastslice/elvis

/cookingrecipe/toast_spooky
	item1 = /obj/item/reagent_containers/food/snacks/breadslice/spooky
	cookbonus = 5
	output = /obj/item/reagent_containers/food/snacks/breadslice/toastslice/spooky

/cookingrecipe/sandwich_m_h
	item1 = /obj/item/reagent_containers/food/snacks/breadslice
	amt1 = 2
	item2 = /obj/item/reagent_containers/food/snacks/ingredient/meat/humanmeat
	cookbonus = 7
	output = /obj/item/reagent_containers/food/snacks/sandwich/meat_h
	useshumanmeat = 1

/cookingrecipe/sandwich_m_m
	item1 = /obj/item/reagent_containers/food/snacks/breadslice
	amt1 = 2
	item2 = /obj/item/reagent_containers/food/snacks/ingredient/meat/monkeymeat
	cookbonus = 7
	output = /obj/item/reagent_containers/food/snacks/sandwich/meat_m

/cookingrecipe/sandwich_m_s
	item1 = /obj/item/reagent_containers/food/snacks/breadslice
	amt1 = 2
	item2 = /obj/item/reagent_containers/food/snacks/ingredient/meat/synthmeat
	cookbonus = 7
	output = /obj/item/reagent_containers/food/snacks/sandwich/meat_s

/cookingrecipe/sandwich_c
	item1 = /obj/item/reagent_containers/food/snacks/breadslice
	amt1 = 2
	item2 = /obj/item/reagent_containers/food/snacks/ingredient/cheese
	cookbonus = 7
	output = /obj/item/reagent_containers/food/snacks/sandwich/cheese

/cookingrecipe/sandwich_p
	item1 = /obj/item/reagent_containers/food/snacks/breadslice
	amt1 = 2
	item2 = /obj/item/reagent_containers/food/snacks/ingredient/peanutbutter
	cookbonus = 7
	output = /obj/item/reagent_containers/food/snacks/sandwich/pb

/cookingrecipe/sandwich_p_h
	item1 = /obj/item/reagent_containers/food/snacks/breadslice
	amt1 = 2
	item2 = /obj/item/reagent_containers/food/snacks/ingredient/peanutbutter
	item3 = /obj/item/reagent_containers/food/snacks/ingredient/honey
	cookbonus = 7
	output = /obj/item/reagent_containers/food/snacks/sandwich/pbh

/cookingrecipe/elviswich_m_h
	item1 = /obj/item/reagent_containers/food/snacks/breadslice/elvis
	amt1 = 2
	item2 = /obj/item/reagent_containers/food/snacks/ingredient/meat/humanmeat
	cookbonus = 7
	output = /obj/item/reagent_containers/food/snacks/sandwich/elvis_meat_h
	useshumanmeat = 1

/cookingrecipe/elviswich_m_m
	item1 = /obj/item/reagent_containers/food/snacks/breadslice/elvis
	amt1 = 2
	item2 = /obj/item/reagent_containers/food/snacks/ingredient/meat/monkeymeat
	cookbonus = 7
	output = /obj/item/reagent_containers/food/snacks/sandwich/elvis_meat_m

/cookingrecipe/elviswich_m_s
	item1 = /obj/item/reagent_containers/food/snacks/breadslice/elvis
	amt1 = 2
	item2 = /obj/item/reagent_containers/food/snacks/ingredient/meat/synthmeat
	cookbonus = 7
	output = /obj/item/reagent_containers/food/snacks/sandwich/elvis_meat_s

/cookingrecipe/elviswich_c
	item1 = /obj/item/reagent_containers/food/snacks/breadslice/elvis
	amt1 = 2
	item2 = /obj/item/reagent_containers/food/snacks/ingredient/cheese
	cookbonus = 7
	output = /obj/item/reagent_containers/food/snacks/sandwich/elvis_cheese

/cookingrecipe/elviswich_p
	item1 = /obj/item/reagent_containers/food/snacks/breadslice/elvis
	amt1 = 2
	item2 = /obj/item/reagent_containers/food/snacks/ingredient/peanutbutter
	cookbonus = 7
	output = /obj/item/reagent_containers/food/snacks/sandwich/elvis_pb

/cookingrecipe/elviswich_p_h
	item1 = /obj/item/reagent_containers/food/snacks/breadslice/elvis
	amt1 = 2
	item2 = /obj/item/reagent_containers/food/snacks/ingredient/peanutbutter
	item3 = /obj/item/reagent_containers/food/snacks/ingredient/honey
	cookbonus = 7
	output = /obj/item/reagent_containers/food/snacks/sandwich/elvis_pbh

/cookingrecipe/scarewich_c
	item1 = /obj/item/reagent_containers/food/snacks/breadslice/spooky
	amt1 = 2
	item2 = /obj/item/reagent_containers/food/snacks/ingredient/cheese
	cookbonus = 7
	output = /obj/item/reagent_containers/food/snacks/sandwich/spooky_cheese

/cookingrecipe/scarewich_p
	item1 = /obj/item/reagent_containers/food/snacks/breadslice/spooky
	amt1 = 2
	item2 = /obj/item/reagent_containers/food/snacks/ingredient/peanutbutter
	cookbonus = 7
	output = /obj/item/reagent_containers/food/snacks/sandwich/spooky_pb

/cookingrecipe/scarewich_p_h
	item1 = /obj/item/reagent_containers/food/snacks/breadslice/spooky
	amt1 = 2
	item2 = /obj/item/reagent_containers/food/snacks/ingredient/peanutbutter
	item3 = /obj/item/reagent_containers/food/snacks/ingredient/honey
	cookbonus = 7
	output = /obj/item/reagent_containers/food/snacks/sandwich/spooky_pbh

/cookingrecipe/scarewich_h
	item1 = /obj/item/reagent_containers/food/snacks/breadslice/spooky
	amt1 = 2
	item2 = /obj/item/reagent_containers/food/snacks/ingredient/meat/humanmeat
	cookbonus = 7
	output = /obj/item/reagent_containers/food/snacks/sandwich/spooky_meat_h
	useshumanmeat = 1

/cookingrecipe/scarewich_m
	item1 = /obj/item/reagent_containers/food/snacks/breadslice/spooky
	amt1 = 2
	item2 = /obj/item/reagent_containers/food/snacks/ingredient/meat/monkeymeat
	cookbonus = 7
	output = /obj/item/reagent_containers/food/snacks/sandwich/spooky_meat_m

/cookingrecipe/scarewich_s
	item1 = /obj/item/reagent_containers/food/snacks/breadslice/spooky
	amt1 = 2
	item2 = /obj/item/reagent_containers/food/snacks/ingredient/meat/synthmeat
	cookbonus = 7
	output = /obj/item/reagent_containers/food/snacks/sandwich/spooky_meat_s

/cookingrecipe/sandwich_mb
	item1 = /obj/item/reagent_containers/food/snacks/meatball
	item2 = /obj/item/reagent_containers/food/snacks/breadloaf
	item3 = /obj/item/reagent_containers/food/snacks/ingredient/cheese
	item4 = /obj/item/reagent_containers/food/snacks/condiment/ketchup
	cookbonus = 12
	output = /obj/item/reagent_containers/food/snacks/sandwich/meatball

/cookingrecipe/sandwich_custom
	item1 = /obj/item/reagent_containers/food/snacks/breadslice
	amt1 = 2
	cookbonus = 12
	output = null

	specialOutput(obj/submachine/ourCooker)
		if (!ourCooker)
			return null

		var/obj/item/reagent_containers/food/snacks/sandwich/customSandwich = new /obj/item/reagent_containers/food/snacks/sandwich (ourCooker)
		customSandwich.reagents = new /reagents(100)
		customSandwich.reagents.my_atom = customSandwich

		var/obj/item/reagent_containers/food/snacks/breadslice/slice1
		var/obj/item/reagent_containers/food/snacks/breadslice/slice2
		var/list/fillings = list()
		var/list/fillingColors = list()
		var/onBreadText = ""
		var/extraSlices = 0

		var/i = 1
		for (var/obj/item/reagent_containers/food/snacks/snack in ourCooker)
			if (snack == customSandwich)
				continue

			else if (istype(snack, /obj/item/reagent_containers/food/snacks/breadslice))
				if (slice1 && slice2)
					extraSlices++

					if (snack.reagents)
						snack.reagents.trans_to(customSandwich, 25)

					//fillings += snack.name
					if (snack.food_color)
						if (fillingColors.len % 2 || fillingColors.len < (i*2))
							fillingColors += "B[snack.food_color]"
						else
							fillingColors.Insert((i++*2), "B[snack.food_color]")
					qdel(snack)

				else if (slice1)
					slice2 = snack
					if (slice1.real_name != snack.real_name)
						onBreadText += " and [snack.real_name == "bread" ? "plain" : snack.real_name]"
				else
					slice1 = snack
					onBreadText = "on [snack.real_name == "bread" ? "plain bread" : snack.real_name]"
			else
				if (snack.reagents)
					snack.reagents.trans_to(customSandwich, 25)

				fillings += snack.name
				if (snack.food_color && !istype(snack, /obj/item/reagent_containers/food/snacks/ingredient) && prob(50))
					fillingColors += snack.food_color
				else
					var/obj/transformedFilling = image(snack.icon, snack.icon_state)
					transformedFilling.transform = matrix(0.75, MATRIX_SCALE)
					fillingColors += transformedFilling

				qdel(snack)

		if (!fillings.len)
			customSandwich.name = "wish"
			customSandwich.desc = "So named because you 'wish' you had something to put between the slices of bread. Ha.  ha.  Ha..."
		else
			var/fillingText = copytext(html_encode(english_list(fillings)), 1, 512)
			customSandwich.name = fillingText
			customSandwich.desc = "A sandwich filled with [fillingText]."

		switch (extraSlices)
			if (0)
				customSandwich.name += " sandwich"

			if (1)
				customSandwich.name += " club"

			if (2)
				customSandwich.name += " double-decker sandwich"

			if (3)
				customSandwich.name += " dagwood"

		customSandwich.name += " [onBreadText]"

		var/obj/sandwichIcon
		customSandwich.icon = 'icons/obj/foodNdrink/food_meals.dmi'
		if (slice1)
			sandwichIcon = image('icons/obj/foodNdrink/food_meals.dmi', "sandwich-bread")//, 1, 1)
			//sandwichIcon.Blend(slice1.food_color, ICON_ADD)
			sandwichIcon.color = slice1.food_color

			customSandwich.overlays += sandwichIcon
			//qdel(slice1)

		var/fillingOffset = 2
		var/obj/newFilling
		while (fillingColors.len)
			if (istype(fillingColors[fillingColors.len], /image))
				newFilling = fillingColors[fillingColors.len]

			else if (copytext(fillingColors[fillingColors.len],1,2) == "B")
				newFilling = image('icons/obj/foodNdrink/food_meals.dmi', "sandwich-bread")
				fillingColors[fillingColors.len] = copytext(fillingColors[fillingColors.len], 2)

			else
				newFilling = image('icons/obj/foodNdrink/food_meals.dmi', "sandwich-filling[rand(1,4)]")//, 1, 1)
			//newFilling.Blend(fillingColors[fillingColors.len], ICON_ADD)
			newFilling.pixel_y = fillingOffset
			newFilling.color = fillingColors[fillingColors.len]
			fillingColors.len--
			fillingOffset += 2

			customSandwich.overlays += newFilling


		if (slice2)
			newFilling = image('icons/obj/foodNdrink/food_meals.dmi', "sandwich-bread")//, 1, 1)
			//newFilling.Blend( slice2.food_color, ICON_ADD)
			newFilling.color = slice2.food_color
			newFilling.pixel_y = fillingOffset

			//qdel(slice2)

			customSandwich.overlays += newFilling

		return customSandwich



/cookingrecipe/cheesetoast
	item1 = /obj/item/reagent_containers/food/snacks/breadslice
	item2 = /obj/item/reagent_containers/food/snacks/ingredient/cheese
	cookbonus = 5
	output = /obj/item/reagent_containers/food/snacks/toastcheese

/cookingrecipe/bacontoast
	item1 = /obj/item/reagent_containers/food/snacks/breadslice
	item2 = /obj/item/reagent_containers/food/snacks/ingredient/meat/bacon
	cookbonus = 5
	output = /obj/item/reagent_containers/food/snacks/toastbacon

/cookingrecipe/elvischeesetoast
	item1 = /obj/item/reagent_containers/food/snacks/breadslice/elvis
	item2 = /obj/item/reagent_containers/food/snacks/ingredient/cheese
	cookbonus = 5
	output = /obj/item/reagent_containers/food/snacks/toastcheese/elvis

/cookingrecipe/elvisbacontoast
	item1 = /obj/item/reagent_containers/food/snacks/breadslice/elvis
	item2 = /obj/item/reagent_containers/food/snacks/ingredient/meat/bacon
	cookbonus = 5
	output = /obj/item/reagent_containers/food/snacks/toastbacon/elvis

/cookingrecipe/breakfast
	item1 = /obj/item/reagent_containers/food/snacks/ingredient/meat/bacon
	amt1 = 2
	item2 = /obj/item/reagent_containers/food/snacks/ingredient/egg
	amt2 = 2
	cookbonus = 16
	output = /obj/item/reagent_containers/food/snacks/breakfast

/cookingrecipe/wonton_wrapper
	item1 = /obj/item/reagent_containers/food/snacks/ingredient/egg
	item2 = /obj/item/reagent_containers/food/snacks/ingredient/flour
	cookbonus = 1
	output = /obj/item/reagent_containers/food/snacks/wonton_spawner

/cookingrecipe/taco_shell
	item1 = /obj/item/reagent_containers/food/snacks/ingredient/tortilla
	cookbonus = 6
	output = /obj/item/reagent_containers/food/snacks/taco

/cookingrecipe/eggnog
	item1 = /obj/item/reagent_containers/food/drinks/milk
	item2 = /obj/item/reagent_containers/food/snacks/ingredient/egg
	amt2 = 3
	cookbonus = 3
	output = /obj/item/reagent_containers/food/drinks/eggnog

//Cookies
/cookingrecipe/cookie
	item1 = /obj/item/reagent_containers/food/snacks/ingredient/dough_cookie
	cookbonus = 4
	output = /obj/item/reagent_containers/food/snacks/cookie

/cookingrecipe/cookie_iron
	item1 = /obj/item/reagent_containers/food/snacks/ingredient/dough_cookie
	item2 = /obj/item/reagent_containers/food/snacks/condiment/ironfilings
	cookbonus = 4
	output = /obj/item/reagent_containers/food/snacks/cookie/metal

/cookingrecipe/cookie_chocolate_chip
	item1 = /obj/item/reagent_containers/food/snacks/ingredient/dough_cookie
	item2 = /obj/item/reagent_containers/food/snacks/condiment/chocchips
	cookbonus = 4
	output = /obj/item/reagent_containers/food/snacks/cookie/chocolate_chip

/cookingrecipe/cookie_oatmeal
	item1 = /obj/item/reagent_containers/food/snacks/ingredient/dough_cookie
	item2 = /obj/item/reagent_containers/food/snacks/ingredient/oatmeal
	cookbonus = 4
	output = /obj/item/reagent_containers/food/snacks/cookie/oatmeal

/cookingrecipe/cookie_bacon
	item1 = /obj/item/reagent_containers/food/snacks/ingredient/dough_cookie
	item2 = /obj/item/reagent_containers/food/snacks/ingredient/meat/bacon
	cookbonus = 4
	output = /obj/item/reagent_containers/food/snacks/cookie/bacon

/cookingrecipe/cookie_jaffa
	item1 = /obj/item/reagent_containers/food/snacks/ingredient/dough_cookie
	item2 = /obj/item/reagent_containers/food/snacks/plant/orange
	item3 = /obj/item/reagent_containers/food/snacks/candy
	cookbonus = 4
	output = /obj/item/reagent_containers/food/snacks/cookie/jaffa

/cookingrecipe/cookie_spooky
	item1 = /obj/item/reagent_containers/food/snacks/ingredient/dough_cookie
	item2 = /obj/item/reagent_containers/food/snacks/ectoplasm
	cookbonus = 4
	output = /obj/item/reagent_containers/food/snacks/cookie/spooky

//Moon pies!
/cookingrecipe/moon_pie
	item1 = /obj/item/reagent_containers/food/snacks/cookie
	amt1 = 2
	item2 = /obj/item/reagent_containers/food/snacks/condiment/cream
	cookbonus = 5
	output = /obj/item/reagent_containers/food/snacks/moon_pie

/cookingrecipe/moon_pie_iron
	item1 = /obj/item/reagent_containers/food/snacks/cookie/metal
	amt1 = 2
	item2 = /obj/item/reagent_containers/food/snacks/condiment/cream
	cookbonus = 5
	output = /obj/item/reagent_containers/food/snacks/moon_pie/metal

/cookingrecipe/moon_pie_chips
	item1 = /obj/item/reagent_containers/food/snacks/cookie/chocolate_chip
	amt1 = 2
	item2 = /obj/item/reagent_containers/food/snacks/condiment/cream
	cookbonus = 5
	output = /obj/item/reagent_containers/food/snacks/moon_pie/chocolate_chip

/cookingrecipe/moon_pie_oatmeal
	item1 = /obj/item/reagent_containers/food/snacks/cookie/oatmeal
	amt1 = 2
	item2 = /obj/item/reagent_containers/food/snacks/condiment/cream
	cookbonus = 5
	output = /obj/item/reagent_containers/food/snacks/moon_pie/oatmeal

/cookingrecipe/moon_pie_bacon
	item1 = /obj/item/reagent_containers/food/snacks/cookie/bacon
	amt1 = 2
	item2 = /obj/item/reagent_containers/food/snacks/condiment/cream
	cookbonus = 5
	output = /obj/item/reagent_containers/food/snacks/moon_pie/bacon

/cookingrecipe/moon_pie_jaffa
	item1 = /obj/item/reagent_containers/food/snacks/cookie/jaffa
	amt1 = 2
	item2 = /obj/item/reagent_containers/food/snacks/condiment/cream
	cookbonus = 5
	output = /obj/item/reagent_containers/food/snacks/moon_pie/jaffa

/cookingrecipe/moon_pie_spooky
	item1 = /obj/item/reagent_containers/food/snacks/cookie/spooky
	amt1 = 2
	item2 = /obj/item/reagent_containers/food/snacks/condiment/cream
	cookbonus = 5
	output = /obj/item/reagent_containers/food/snacks/moon_pie/spooky

/cookingrecipe/moon_pie_chocolate
	item1 = /obj/item/reagent_containers/food/snacks/cookie/chocolate_chip
	amt1 = 2
	item2 = /obj/item/reagent_containers/food/snacks/condiment/cream
	item3 = /obj/item/reagent_containers/food/snacks/candy
	cookbonus = 6
	output = /obj/item/reagent_containers/food/snacks/moon_pie/chocolate

/cookingrecipe/fries
	item1 = /obj/item/reagent_containers/food/snacks/ingredient/chips
	cookbonus = 7
	output = /obj/item/reagent_containers/food/snacks/fries

/cookingrecipe/bakedpotato
	item1 = /obj/item/reagent_containers/food/snacks/plant/potato
	cookbonus = 16
	output = /obj/item/reagent_containers/food/snacks/bakedpotato

/cookingrecipe/hotdog
	item1 = /obj/item/reagent_containers/food/snacks/meatball
	amt1 = 2
	cookbonus = 6
	output = /obj/item/reagent_containers/food/snacks/hotdog

/cookingrecipe/steak_h
	item1 = /obj/item/reagent_containers/food/snacks/ingredient/meat/humanmeat
	cookbonus = 10
	output = /obj/item/reagent_containers/food/snacks/steak_h
	useshumanmeat = 1

/cookingrecipe/steak_m
	item1 = /obj/item/reagent_containers/food/snacks/ingredient/meat/monkeymeat
	cookbonus = 10
	output = /obj/item/reagent_containers/food/snacks/steak_m

/cookingrecipe/steak_s
	item1 = /obj/item/reagent_containers/food/snacks/ingredient/meat/synthmeat
	cookbonus = 10
	output = /obj/item/reagent_containers/food/snacks/steak_s

/cookingrecipe/steak_s
	item1 = /obj/item/reagent_containers/food/snacks/ingredient/meat/synthmeat
	cookbonus = 10
	output = /obj/item/reagent_containers/food/snacks/steak_s

/cookingrecipe/fish_fingers
	item1 = /obj/item/reagent_containers/food/snacks/ingredient/meat/fish
	cookbonus = 10
	output = /obj/item/reagent_containers/food/snacks/fish_fingers

/cookingrecipe/bacon
	item1 = /obj/item/reagent_containers/food/snacks/ingredient/meat/bacon/raw
	cookbonus = 8
	output = /obj/item/reagent_containers/food/snacks/ingredient/meat/bacon

/cookingrecipe/pie_apple
	item1 = /obj/item/reagent_containers/food/snacks/ingredient/dough_s
	item2 = /obj/item/reagent_containers/food/snacks/plant/apple
	cookbonus = 12
	output = /obj/item/reagent_containers/food/snacks/pie/apple

/cookingrecipe/pie_lime
	item1 = /obj/item/reagent_containers/food/snacks/ingredient/dough_s
	item2 = /obj/item/reagent_containers/food/snacks/plant/lime
	cookbonus = 12
	output = /obj/item/reagent_containers/food/snacks/pie/lime

/cookingrecipe/pie_lemon
	item1 = /obj/item/reagent_containers/food/snacks/ingredient/dough_s
	item2 = /obj/item/reagent_containers/food/snacks/plant/lemon
	cookbonus = 12
	output = /obj/item/reagent_containers/food/snacks/pie/lemon

/cookingrecipe/pie_slurry
	item1 = /obj/item/reagent_containers/food/snacks/ingredient/dough_s
	item2 = /obj/item/reagent_containers/food/snacks/plant/slurryfruit
	cookbonus = 12
	output = /obj/item/reagent_containers/food/snacks/pie/slurry

/cookingrecipe/pie_pumpkin
	item1 = /obj/item/reagent_containers/food/snacks/ingredient/dough_s
	item2 = /obj/item/reagent_containers/food/snacks/plant/pumpkin
	cookbonus = 12
	output = /obj/item/reagent_containers/food/snacks/pie/pumpkin

/cookingrecipe/pie_strawberry
	item1 = /obj/item/reagent_containers/food/snacks/ingredient/dough_s
	item2 = /obj/item/reagent_containers/food/snacks/plant/strawberry
	amt2 = 2
	cookbonus = 12
	output = /obj/item/reagent_containers/food/snacks/pie/strawberry

/cookingrecipe/pie_cream
	item1 = /obj/item/reagent_containers/food/snacks/ingredient/dough_s
	item2 = /obj/item/reagent_containers/food/snacks/condiment/cream
	cookbonus = 4
	output = /obj/item/reagent_containers/food/snacks/pie/cream

	specialOutput(var/obj/submachine/ourCooker)
		if (!ourCooker)
			return null

		var/obj/item/reagent_containers/food/snacks/custom_pie_food
		for (var/obj/item/reagent_containers/food/snacks/S in ourCooker.contents)
			if (S.type == item1 || S.type == item2)
				continue

			custom_pie_food = S
			break

		if (!custom_pie_food)
			return null

		var/obj/item/reagent_containers/food/snacks/pie/cream/custom_pie = new
		custom_pie_food.reagents.trans_to(custom_pie, 50)
		if (custom_pie.real_name)
			custom_pie.name = "[custom_pie_food.real_name] cream pie"

		else
			custom_pie.name = "[custom_pie_food.name] cream pie"

		var/icon/I = new /icon('icons/obj/foodNdrink/food_dessert.dmi',"creampie")
		I.Blend(custom_pie_food.food_color, ICON_ADD)
		custom_pie.icon = I

		return custom_pie

/cookingrecipe/pie_anything
	item1 = /obj/item/reagent_containers/food/snacks/ingredient/dough_s
	item2 = /obj/item/reagent_containers/food/snacks/ingredient/egg
	cookbonus = 4
	output = /obj/item/reagent_containers/food/snacks/pie/anything

	specialOutput(var/obj/submachine/ourCooker)
		if (!ourCooker)
			return null

		var/obj/item/reagent_containers/food/snacks/anItem
		var/obj/item/reagent_containers/food/snacks/pie/anything/custom_pie = new
		var/pieDesc
		var/pieName
		var/contentAmount = ourCooker.contents.len - 2
		var/count = 1
		for (var/obj/item/T in ourCooker.contents)
			if (T.type == item1 || T.type == item2)
				continue

			anItem = T
			anItem.set_loc(custom_pie)
			if (count == contentAmount && contentAmount > 1)
				pieDesc += "and a "
			else
				pieDesc += "a "

			if (custom_pie.real_name)
				pieDesc += lowertext(anItem.real_name)
				pieName += lowertext(anItem.real_name)
			else
				pieDesc += lowertext(anItem.name)
				pieName += lowertext(anItem.name)

			if (count < contentAmount)
				if (count == (contentAmount - 1))
					pieDesc += " "
				else
					pieDesc += ", "
				pieName += " "

			custom_pie.w_class = max(custom_pie.w_class, T.w_class) //Well, that huge thing you put into it isn't going to shrink, you know

			count++

//		if (!anItem)
//			return null

		custom_pie.name = pieName + " pie"
		custom_pie.desc = "A pie containing [pieDesc]. Well alright then."

		var/icon/I = new /icon('icons/obj/foodNdrink/food_dessert.dmi',"pie")
		var/random_color = rgb(rand(1,255), rand(1,255), rand(1,255))
		I.Blend(random_color, ICON_ADD)
		custom_pie.icon = I

		return custom_pie

/cookingrecipe/pie_custard
	item1 = /obj/item/reagent_containers/food/snacks/ingredient/dough_s
	item2 = /obj/item/reagent_containers/food/snacks/condiment/custard
	cookbonus = 4
	output = /obj/item/reagent_containers/food/snacks/pie/custard

/cookingrecipe/pie_bacon
	item1 = /obj/item/reagent_containers/food/snacks/ingredient/dough_s
	item2 = /obj/item/reagent_containers/food/snacks/ingredient/meat/bacon
	cookbonus = 15
	output = /obj/item/reagent_containers/food/snacks/pie/bacon

/cookingrecipe/pie_ass
	item1 = /obj/item/reagent_containers/food/snacks/ingredient/dough_s
	item2 = /obj/item/clothing/head/butt
	cookbonus = 15
	output = /obj/item/reagent_containers/food/snacks/pie/ass

/cookingrecipe/custard
	item1 = /obj/item/reagent_containers/food/drinks/milk
	item2 = /obj/item/reagent_containers/food/snacks/ingredient/egg
	cookbonus = 6
	output = /obj/item/reagent_containers/food/snacks/condiment/custard

/cookingrecipe/gruel
	item1 = /obj/item/reagent_containers/food/snacks/yuck
	amt1 = 3
	cookbonus = 10
	output = /obj/item/reagent_containers/food/snacks/soup/gruel

/cookingrecipe/oatmeal
	item1 = /obj/item/reagent_containers/food/snacks/ingredient/oatmeal
	cookbonus = 10
	output = /obj/item/reagent_containers/food/snacks/soup/oatmeal

/cookingrecipe/tomsoup
	item1 = /obj/item/reagent_containers/food/snacks/plant/tomato
	amt1 = 2
	cookbonus = 8
	output = /obj/item/reagent_containers/food/snacks/soup/tomato

/cookingrecipe/chili
	item1 = /obj/item/reagent_containers/food/snacks/ingredient/meat/
	item2 = /obj/item/reagent_containers/food/snacks/plant/chili
	cookbonus = 14
	output = /obj/item/reagent_containers/food/snacks/soup/chili

/cookingrecipe/queso
	item1 = /obj/item/reagent_containers/food/snacks/ingredient/cheese
	item2 = /obj/item/reagent_containers/food/snacks/plant/chili
	cookbonus = 14
	output = /obj/item/reagent_containers/food/snacks/soup/queso

/cookingrecipe/superchili
	item1 = /obj/item/reagent_containers/food/snacks/ingredient/meat/
	item2 = /obj/item/reagent_containers/food/snacks/plant/chili
	item3 = /obj/item/reagent_containers/food/snacks/condiment/hotsauce
	amt3 = 2
	cookbonus = 16
	output = /obj/item/reagent_containers/food/snacks/soup/superchili

/cookingrecipe/ultrachili
	item1 = /obj/item/reagent_containers/food/snacks/soup/chili
	item2 = /obj/item/reagent_containers/food/snacks/soup/superchili
	item3 = /obj/item/reagent_containers/food/snacks/plant/chili
	item4 = /obj/item/reagent_containers/food/snacks/condiment/hotsauce
	cookbonus = 20
	output = /obj/item/reagent_containers/food/snacks/soup/ultrachili

/cookingrecipe/salad
	item1 = /obj/item/reagent_containers/food/snacks/plant/lettuce
	amt1 = 2
	cookbonus = 4
	output = /obj/item/reagent_containers/food/snacks/salad

//Delightful Halloween Recipes
/cookingrecipe/candy_apple
	item1 = /obj/item/reagent_containers/food/snacks/plant/apple/stick
	item2 = /obj/item/reagent_containers/food/snacks/ingredient/sugar
	cookbonus = 6
	output = /obj/item/reagent_containers/food/snacks/candy/candy_apple

//Cakes!
/cookingrecipe/cake_batter
	item1 = /obj/item/reagent_containers/food/snacks/ingredient/dough_s
	item2 = /obj/item/reagent_containers/food/snacks/ingredient/egg
	amt2 = 2
	cookbonus = 10
	output = /obj/item/reagent_containers/food/snacks/cake/batter

/cookingrecipe/cake_cream
	item1 = /obj/item/reagent_containers/food/snacks/cake/batter
	item2 = /obj/item/reagent_containers/food/snacks/condiment/cream
	cookbonus = 14
	output = /obj/item/reagent_containers/food/snacks/cake/cream

/cookingrecipe/cake_chocolate
	item1 = /obj/item/reagent_containers/food/snacks/cake/batter
	item2 = /obj/item/reagent_containers/food/snacks/candy
	cookbonus = 14
	output = /obj/item/reagent_containers/food/snacks/cake/chocolate

/cookingrecipe/cake_meat
	item1 = /obj/item/reagent_containers/food/snacks/cake/batter
	item2 = /obj/item/reagent_containers/food/snacks/ingredient/meat/
	cookbonus = 14
	output = /obj/item/reagent_containers/food/snacks/cake/meat

/cookingrecipe/cake_bacon
	item1 = /obj/item/reagent_containers/food/snacks/cake/batter
	item2 = /obj/item/reagent_containers/food/snacks/ingredient/meat/bacon
	amt2 = 3
	cookbonus = 14
	output = /obj/item/reagent_containers/food/snacks/cake/bacon

/cookingrecipe/cake_downs
	item1 = /obj/item/reagent_containers/food/snacks/cake/batter
	item2 = /obj/item/organ/brain
	cookbonus = 14
	output = /obj/item/reagent_containers/food/snacks/cake/downs

/cookingrecipe/cake_custom
	item1 = /obj/item/reagent_containers/food/snacks/cake/batter
	cookbonus = 14
	output = null

	specialOutput(var/obj/submachine/ourCooker)
		if (!ourCooker)
			return null

		var/obj/item/reagent_containers/food/snacks/cake/batter/docakeitem = locate() in ourCooker.contents
		if (!istype( docakeitem ))
			return null

		var/obj/item/reagent_containers/food/snacks/S = docakeitem.custom_item
		var/obj/item/reagent_containers/food/snacks/cake/custom/B = new /obj/item/reagent_containers/food/snacks/cake/custom(ourCooker)
		B.food_color = S ? S.food_color : "#F0F0F0"
		B.update_icon(0)
		if (S)
			S.reagents.trans_to(B, 50)
			if (S.real_name)
				B.name = "[S.real_name] cake"

			else
				B.name = "[S.name] cake"
		else
			B.name = "[rand(50) ? "yellow" : "white"] cake"

		B.desc = "Mmm! A delicious-looking [B.name]!"

		return B


/cookingrecipe/cake_custom_item
	item1 = /obj/item/reagent_containers/food/snacks/cake/cream
	cookbonus = 14
	output = null

	specialOutput(var/obj/submachine/ourCooker)
		if (!ourCooker)
			return null

		var/obj/item/cake_item/B = new /obj/item/cake_item(ourCooker)
		for (var/obj/item/I in ourCooker.contents)
			if (istype(I,/obj/item/cake_item))
				continue
			I.set_loc(B)
			break

		return B

/cookingrecipe/mix_cake_custom
	item1 = /obj/item/reagent_containers/food/snacks/cake/batter
	amt1 = 1
	output = null

	specialOutput(var/obj/submachine/ourCooker)
		if (!ourCooker)
			return null

		for (var/obj/item/I in ourCooker.contents)
			if (istype(I, item1))
				continue
			else if (istype(I,/obj/item/reagent_containers/food/snacks))
				/*
				var/obj/item/reagent_containers/food/snacks/S = I
				var/obj/item/reagent_containers/food/snacks/cake/custom/B = new /obj/item/reagent_containers/food/snacks/cake/custom(loc)
				B.food_color = S.food_color
				B.update_icon(0)
				S.reagents.trans_to(B, 50)
				if (S.real_name)
					B.name = "[S.real_name] cake"

				else
					B.name = "[S.name] cake"
				B.desc = "Mmm! A delicious-looking [B.name]!"
				*/
				var/obj/item/reagent_containers/food/snacks/cake/batter/batter = new

				batter.custom_item = I
				I.set_loc(batter)
				batter.name = "uncooked [I:real_name ? I:real_name : I.name] cake"
				for (var/obj/M in ourCooker.contents)
					qdel(M)

				return batter

		return null


/cookingrecipe/omelette
	item1 = /obj/item/reagent_containers/food/snacks/ingredient/egg
	amt1 = 2
	item2 = /obj/item/reagent_containers/food/snacks/ingredient/meat/
	item3 = /obj/item/reagent_containers/food/snacks/ingredient/cheese
	cookbonus = 12
	output = /obj/item/reagent_containers/food/snacks/omelette

/cookingrecipe/omelette_bee
	item1 = /obj/item/reagent_containers/food/snacks/ingredient/egg/bee
	amt1 = 2
	item2 = /obj/item/reagent_containers/food/snacks/ingredient/meat/
	item3 = /obj/item/reagent_containers/food/snacks/ingredient/cheese
	cookbonus = 12
	output = /obj/item/reagent_containers/food/snacks/omelette/bee

/cookingrecipe/pancake_batter
	item1 = /obj/item/reagent_containers/food/snacks/ingredient/dough_s
	item2 = /obj/item/reagent_containers/food/drinks/milk
	item3 = /obj/item/reagent_containers/food/snacks/ingredient/egg
	amt3 = 2
	cookbonus = 4
	output = /obj/item/reagent_containers/food/snacks/ingredient/pancake_batter

/cookingrecipe/pancake
	item1 = /obj/item/reagent_containers/food/snacks/ingredient/pancake_batter
	cookbonus = 11
	output = /obj/item/reagent_containers/food/snacks/pancake

/cookingrecipe/mashedpotatoes
	item1 = /obj/item/reagent_containers/food/snacks/plant/potato
	amt1 = 3
	cookbonus = 10
	output = /obj/item/reagent_containers/food/snacks/mashedpotatoes

/cookingrecipe/mashedbrains
	item1 = /obj/item/organ/brain
	cookbonus = 10
	output = /obj/item/reagent_containers/food/snacks/mashedbrains

/cookingrecipe/creamofmushroom
	item1 = /obj/item/reagent_containers/food/snacks/mushroom
	item2 = /obj/item/reagent_containers/food/drinks/milk
	cookbonus = 5
	output = /obj/item/reagent_containers/food/snacks/soup/creamofmushroom

/cookingrecipe/creamofmushroom/amanita
	item1 = /obj/item/reagent_containers/food/snacks/mushroom/amanita
	output = /obj/item/reagent_containers/food/snacks/soup/creamofmushroom/amanita

/cookingrecipe/creamofmushroom/psilocybin
	item1 = /obj/item/reagent_containers/food/snacks/mushroom/psilocybin
	output = /obj/item/reagent_containers/food/snacks/soup/creamofmushroom/psilocybin

/cookingrecipe/meatpaste
	item1 =  /obj/item/reagent_containers/food/snacks/ingredient/meat/
	cookbonus = 4
	output = /obj/item/reagent_containers/food/snacks/ingredient/meatpaste/

/cookingrecipe/sloppyjoe
	item1 = /obj/item/reagent_containers/food/snacks/ingredient/meatpaste
	item2 = /obj/item/reagent_containers/food/snacks/ingredient/dough
	cookbonus = 13
	output = /obj/item/reagent_containers/food/snacks/burger/sloppyjoe

/cookingrecipe/meatloaf
	item1 = /obj/item/reagent_containers/food/snacks/ingredient/meatpaste
	cookbonus = 8
	output = /obj/item/reagent_containers/food/snacks/meatloaf

/cookingrecipe/cereal_honey
	item1 = /obj/item/reagent_containers/food/snacks/cereal_box
	item2 = /obj/item/reagent_containers/food/snacks/ingredient/honey
	cookbonus = 4
	output = /obj/item/reagent_containers/food/snacks/cereal_box/honey

/cookingrecipe/granola_bar
	item1 = /obj/item/reagent_containers/food/snacks/ingredient/honey
	item2 = /obj/item/reagent_containers/food/snacks/ingredient/oatmeal
	cookbonus = 6
	output = /obj/item/reagent_containers/food/snacks/granola_bar