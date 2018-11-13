/plant/contusine
	name = "Contusine"
	category = "Herb"
	seedcolor = "#DD00AA"
	crop = /obj/item/plant/herb/contusine
	starthealth = 20
	growtime = 30
	harvtime = 100
	cropsize = 5
	harvests = 1
	isgrass = 1
	endurance = 0
	nectarlevel = 10
	genome = 3
	assoc_reagents = list("salicylic_acid")
	mutations = list(/plantmutation/contusine/shivering,/plantmutation/contusine/quivering)

/plant/nureous
	name = "Nureous"
	category = "Herb"
	seedcolor = "#226600"
	crop = /obj/item/plant/herb/nureous
	starthealth = 20
	growtime = 30
	harvtime = 100
	cropsize = 5
	harvests = 1
	isgrass = 1
	endurance = 0
	nectarlevel = 10
	genome = 3
	mutations = list(/plantmutation/nureous/fuzzy)
	commuts = list(/plant_gene_strain/immunity_radiation,/plant_gene_strain/damage_res/bad)
	assoc_reagents = list("anti_rad")

/plant/asomna
	name = "Asomna"
	seedcolor = "#00AA77"
	crop = /obj/item/plant/herb/asomna
	starthealth = 20
	growtime = 30
	harvtime = 100
	cropsize = 5
	harvests = 1
	isgrass = 1
	endurance = 0
	nectarlevel = 15
	genome = 3
	assoc_reagents = list("ephedrine")
	mutations = list(/plantmutation/asomna/robust)

/plant/commol
	name = "Commol"
	category = "Herb"
	seedcolor = "#559900"
	crop = /obj/item/plant/herb/commol
	starthealth = 20
	growtime = 30
	harvtime = 100
	cropsize = 5
	harvests = 1
	isgrass = 1
	endurance = 0
	genome = 16
	nectarlevel = 5
	commuts = list(/plant_gene_strain/resistance_drought,/plant_gene_strain/yield/stunted)
	assoc_reagents = list("silver_sulfadiazine")
	mutations = list(/plantmutation/commol/burning)

/plant/venne
	name = "Venne"
	category = "Herb"
	seedcolor = "#DDFF99"
	crop = /obj/item/plant/herb/venne
	starthealth = 20
	growtime = 30
	harvtime = 100
	cropsize = 5
	harvests = 1
	isgrass = 1
	endurance = 0
	nectarlevel = 5
	genome = 1
	assoc_reagents = list("charcoal")
	mutations = list(/plantmutation/venne/toxic,/plantmutation/venne/curative)

/plant/cannabis
	name = "Cannabis"
	category = "Herb"
	seedcolor = "#66DD66"
	crop = /obj/item/plant/herb/cannabis
	starthealth = 10
	growtime = 30
	harvtime = 80
	cropsize = 6
	harvests = 1
	endurance = 0
	isgrass = 1
	vending = 2
	nectarlevel = 5
	genome = 2
	assoc_reagents = list("THC")
	mutations = list(/plantmutation/cannabis/rainbow,/plantmutation/cannabis/death,
	/plantmutation/cannabis/white,/plantmutation/cannabis/ultimate)
	commuts = list(/plant_gene_strain/resistance_drought,/plant_gene_strain/yield/stunted)

/plant/catnip
	name = "Nepeta Cataria"
	category = "Herb"
	seedcolor = "#00CA70"
	crop = /obj/item/plant/herb/catnip
	starthealth = 10
	growtime = 30
	harvtime = 80
	cropsize = 6
	harvests = 1
	endurance = 0
	isgrass = 1
	vending = 2
	genome = 1
	assoc_reagents = list("catonium")