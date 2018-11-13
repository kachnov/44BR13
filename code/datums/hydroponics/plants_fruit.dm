/plant/tomato
	name = "Tomato" // You want to capitalise this, it shows up in the seed vendor and plant pot
	category = "Fruit" // This is either Fruit, Vegetable, Herb or Miscellaneous
	seedcolor = "#CC0000" // Hex string for color. Don't forget the hash!
	crop = /obj/item/reagent_containers/food/snacks/plant/tomato
	starthealth = 20
	growtime = 75
	harvtime = 110
	cropsize = 3
	harvests = 3
	endurance = 3
	nectarlevel = 5
	genome = 18
	assoc_reagents = list("juice_tomato")
	commuts = list(/plant_gene_strain/splicing,/plant_gene_strain/quality/inferior)

	HYPinfusionP(var/obj/item/seed/S,var/reagent)
		..()
		var/plantgenes/DNA = S.plantgenes
		if (!DNA) return
		switch(reagent)
			if ("napalm","infernite","thalmerite","sorium")
				if (prob(50))
					DNA.mutation = HY_get_mutation_from_path(/plantmutation/tomato/explosive)
			if ("strange_reagent")
				if (prob(50))
					DNA.mutation = HY_get_mutation_from_path(/plantmutation/tomato/killer)

/plant/grape
	name = "Grape"
	category = "Fruit"
	seedcolor = "#8800CC"
	crop = /obj/item/reagent_containers/food/snacks/plant/grape
	starthealth = 5
	growtime = 40
	harvtime = 120
	cropsize = 5
	harvests = 2
	endurance = 0
	genome = 20
	nectarlevel = 10
	mutations = list(/plantmutation/grapes/green)
	commuts = list(/plant_gene_strain/metabolism_fast,/plant_gene_strain/seedless)

/plant/orange
	name = "Orange"
	category = "Fruit"
	seedcolor = "#FF8800"
	crop = /obj/item/reagent_containers/food/snacks/plant/orange
	starthealth = 20
	growtime = 60
	harvtime = 100
	cropsize = 2
	harvests = 3
	endurance = 3
	genome = 21
	nectarlevel = 10
	mutations = list(/plantmutation/orange/blood, /plantmutation/orange/clockwork)
	commuts = list(/plant_gene_strain/splicing,/plant_gene_strain/damage_res/bad)
	assoc_reagents = list("juice_orange")

/plant/melon
	name = "Melon"
	category = "Fruit"
	seedcolor = "#33BB00"
	crop = /obj/item/reagent_containers/food/snacks/plant/melon
	starthealth = 80
	growtime = 120
	harvtime = 200
	cropsize = 2
	harvests = 5
	endurance = 5
	genome = 19
	assoc_reagents = list("water")
	nectarlevel = 15
	mutations = list(/plantmutation/melon/george)
	commuts = list(/plant_gene_strain/immortal,/plant_gene_strain/seedless)

/plant/chili
	name = "Chili"
	category = "Fruit"
	seedcolor = "#FF0000"
	crop = /obj/item/reagent_containers/food/snacks/plant/chili
	starthealth = 20
	growtime = 60
	harvtime = 100
	cropsize = 3
	harvests = 3
	endurance = 3
	genome = 17
	assoc_reagents = list("capsaicin")
	mutations = list(/plantmutation/chili/chilly,/plantmutation/chili/ghost)
	commuts = list(/plant_gene_strain/immunity_toxin,/plant_gene_strain/growth_slow)

	HYPinfusionP(var/obj/item/seed/S,var/reagent)
		..()
		var/plantgenes/DNA = S.plantgenes
		if (!DNA) return
		switch(reagent)
			if ("cryostylane")
				if (prob(80))
					DNA.mutation = HY_get_mutation_from_path(/plantmutation/chili/chilly)
			if ("cryoxadone")
				if (prob(40))
					DNA.mutation = HY_get_mutation_from_path(/plantmutation/chili/chilly)
			if ("el_diablo")
				if (prob(60))
					DNA.mutation = HY_get_mutation_from_path(/plantmutation/chili/ghost)
			if ("napalm")
				if (prob(95))
					DNA.mutation = HY_get_mutation_from_path(/plantmutation/chili/ghost)

/plant/apple
	name = "Apple"
	category = "Fruit"
	seedcolor = "#00AA00"
	crop = /obj/item/reagent_containers/food/snacks/plant/apple
	starthealth = 40
	growtime = 200
	harvtime = 260
	cropsize = 3
	harvests = 10
	endurance = 5
	genome = 19
	commuts = list(/plant_gene_strain/quality,/plant_gene_strain/unstable)

/plant/banana
	name = "Banana"
	category = "Fruit"
	seedcolor = "#CCFF99"
	crop = /obj/item/reagent_containers/food/snacks/plant/banana
	starthealth = 15
	growtime = 120
	harvtime = 160
	cropsize = 5
	harvests = 4
	endurance = 3
	genome = 15
	assoc_reagents = list("potassium")
	commuts = list(/plant_gene_strain/immortal,/plant_gene_strain/growth_slow)

/plant/lime
	name = "Lime"
	category = "Fruit"
	seedcolor = "#00FF00"
	crop = /obj/item/reagent_containers/food/snacks/plant/lime
	starthealth = 30
	growtime = 30
	harvtime = 100
	cropsize = 3
	harvests = 3
	endurance = 3
	genome = 21
	commuts = list(/plant_gene_strain/photosynthesis,/plant_gene_strain/splicing/bad)
	assoc_reagents = list("juice_lime")

/plant/lemon
	name = "Lemon"
	category = "Fruit"
	seedcolor = "#FFFF00"
	crop = /obj/item/reagent_containers/food/snacks/plant/lemon
	starthealth = 30
	growtime = 100
	harvtime = 130
	cropsize = 3
	harvests = 3
	endurance = 3
	genome = 21
	assoc_reagents = list("juice_lemon")

/plant/pumpkin
	name = "Pumpkin"
	category = "Fruit"
	seedcolor = "#DD7733"
	crop = /obj/item/reagent_containers/food/snacks/plant/pumpkin
	starthealth = 60
	growtime = 100
	harvtime = 175
	cropsize = 2
	harvests = 4
	endurance = 10
	genome = 19
	commuts = list(/plant_gene_strain/damage_res,/plant_gene_strain/stabilizer)

/plant/avocado
	name = "Avocado"
	category = "Fruit"
	seedcolor = "#00CC66"
	crop = /obj/item/reagent_containers/food/snacks/plant/avocado
	starthealth = 20
	growtime = 65
	harvtime = 110
	cropsize = 3
	harvests = 2
	endurance = 4
	genome = 18

/plant/eggplant
	name = "Eggplant"
	category = "Fruit"
	seedcolor = "#CCCCCC"
	crop = /obj/item/reagent_containers/food/snacks/plant/eggplant
	starthealth = 25
	growtime = 70
	harvtime = 110
	cropsize = 4
	harvests = 2
	endurance = 2
	genome = 18
	commuts = list(/plant_gene_strain/mutations,/plant_gene_strain/terminator)
	mutations = list(/plantmutation/eggplant/literal)
	assoc_reagents = list("nicotine")

	HYPinfusionP(var/obj/item/seed/S,var/reagent)
		..()
		var/plantgenes/DNA = S.plantgenes
		if (!DNA) return
		if (reagent == "eggnog" && prob(80))
			DNA.mutation = HY_get_mutation_from_path(/plantmutation/eggplant/literal)

/plant/strawberry
	name = "Strawberry"
	category = "Fruit"
	seedcolor = "#FF2244"
	crop = /obj/item/reagent_containers/food/snacks/plant/strawberry
	starthealth = 10
	growtime = 60
	harvtime = 120
	cropsize = 2
	harvests = 3
	endurance = 1
	genome = 18
	nectarlevel = 10
	assoc_reagents = list("juice_strawberry")