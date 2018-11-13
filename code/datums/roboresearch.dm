// Robot Research Datums

/roboresearch/
	var/name = "robotics research"
	var/list/schematics = list() // What blueprints does this research allow Robotics Fabricators to download?
	var/manubonus = 0  // Does this research give a bonus to manufacturing unit efficiency?
	var/timebonus = 0  // Manufacturing time has this subtracted from it
	var/multiplier = 1 // Manufacturing time is divided by this (unless it's zero, we dont want to crash)
	var/powbonus = 0   // How much manufacturing unit power usage is reduced by (base of 1500/tick while in use)
	var/resebonus = 0  // Does this research give a bonus to research time?
	var/resemulti = 1  // Research time is divided by this

// T1

/roboresearch/manufone
	name = "Improved Manufacturing Units"
	manubonus = 1
	timebonus = 2
	multiplier = 0
	powbonus = 100

/roboresearch/drones
	name = "Basic Drone Schematics"

	New()
		..()
		schematics += new /manufacture/secbot(src)
		schematics += new /manufacture/medbot(src)
		schematics += new /manufacture/firebot(src)
		schematics += new /manufacture/floorbot(src)
		schematics += new /manufacture/cleanbot(src)

/roboresearch/implants1
	name = "Sensory Prostheses"

	New()
		..()
		schematics += new /manufacture/visor(src)
		schematics += new /manufacture/deafhs(src)

/roboresearch/modules1
	name = "Improved Cyborg Modules"

/roboresearch/upgrades1
	name = "Basic Cyborg Upgrades"

	New()
		..()
		schematics += new /manufacture/robup_jetpack(src)
		schematics += new /manufacture/robup_recharge(src)
		schematics += new /manufacture/robup_repairpack(src)
		schematics += new /manufacture/robup_speed(src)
		schematics += new /manufacture/robup_meson(src)

// T2

/roboresearch/manuftwo
	name = "Superior Manufacturing Units"
	manubonus = 1
	timebonus = 3
	multiplier = 0
	powbonus = 150

/roboresearch/rewriter
	name = "Improved Rewriting & Recharging"

/roboresearch/resespeedone
	name = "Improved Development Algorithms"
	resebonus = 1
	resemulti = 1.25

/roboresearch/modules2
	name = "Superior Cyborg Modules"

/roboresearch/upgrades2
	name = "Improved Cyborg Upgrades"

	New()
		..()
		schematics += new /manufacture/robup_aware(src)
		schematics += new /manufacture/robup_physshield(src)
		schematics += new /manufacture/robup_fireshield(src)
		schematics += new /manufacture/robup_teleport(src)
//		schematics += new /manufacture/robup_thermal(src) // shit don't work
		//schematics += new /manufacture/robup_chargexpand(src)

// T3

/roboresearch/manufthree
	name = "Efficient Manufacturing Units"
	manubonus = 1
	timebonus = 0
	multiplier = 0
	powbonus = 500

/roboresearch/manuffour
	name = "Rapid Manufacturing Units"
	manubonus = 1
	timebonus = 1.5
	multiplier = 0
	powbonus = 0

/roboresearch/upgrades3
	name = "Superior Cyborg Upgrades"

	New()
		..()
		schematics += new /manufacture/robup_efficiency(src)
		schematics += new /manufacture/robup_repair(src)
		//schematics += new /manufacture/robup_expand(src)

/roboresearch/implants2
	name = "Improved Implants"

	New()
		..()
		schematics += new /manufacture/implant_robotalk(src)
//		schematics += new /manufacture/implant_bloodmonitor(src) // does nothing

// T4

/roboresearch/manuffive
	name = "Advanced Manufacturing Units"
	manubonus = 1
	timebonus = 5
	multiplier = 2
	powbonus = 500

/roboresearch/resespeedtwo
	name = "Advanced Development Algorithms"
	resebonus = 1
	resemulti = 2

