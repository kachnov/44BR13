//CONTENTS
//Turfs
//Areas
//Logs
//Critters
//Decor stuff
//Items
//Clothing
//Lavamoon blowout-esque irradiate event
//THE BOSS
//Puzzle elements

//Turfs
/turf/unsimulated/iomoon/floor
	name = "silicate crust"
	icon = 'icons/turf/floors.dmi'
	icon_state = "iocrust"
	opacity = 0
	density = 0
	carbon_dioxide = 20
	temperature = FIRE_MINIMUM_TEMPERATURE_TO_EXIST-1

/turf/unsimulated/iomoon/crustwall
	name = "silicate crust"
	icon = 'icons/misc/worlds.dmi'
	icon_state = "iowall1"
	opacity = 1
	density = 1
	carbon_dioxide = 20
	temperature = FIRE_MINIMUM_TEMPERATURE_TO_EXIST-1

/turf/unsimulated/iomoon/plating
	name = "charred plating"
	desc = "Any protection this plating once had against the extreme heat appears to have given way."
	icon = 'icons/turf/floors.dmi'
	icon_state = "plating"
	opacity = 0
	density = 0

	carbon_dioxide = 20
	temperature = FIRE_MINIMUM_TEMPERATURE_TO_EXIST-1

	New()
		..()
		if (prob(33))
			icon_state = "panelscorched"

/turf/unsimulated/iomoon/ancient_floor
	name = "Ancient Metal Floor"
	desc = "The floor here is cold and dark.  Far colder than it has any right to be down here."
	icon = 'icons/misc/worlds.dmi'
	icon_state = "ancientfloor"

	opacity = 0
	density = 0

	temperature = 10+T0C

/turf/unsimulated/iomoon/ancient_wall
	name = "strange wall"
	desc = "It is dark, glassy and foreboding."
	icon = 'icons/misc/worlds.dmi'
	icon_state = "ancientwall"

	opacity = 1
	density = 1

	temperature = 10+T0C

var/list/iomoon_exterior_sounds = list('sound/ambience/lavamoon_exterior_fx1.ogg','sound/ambience/lavamoon_exterior_fx2.ogg','sound/ambience/lavamoon_exterior_fx3.ogg','sound/ambience/lavamoon_exterior_fx4.ogg')
var/list/iomoon_powerplant_sounds = list('sound/ambience/lavamoon_exterior_fx2.ogg','sound/ambience/lavamoon_interior_fx3.ogg','sound/ambience/lavamoon_interior_fx5.ogg','sound/ambience/ambipower1.ogg','sound/ambience/ambipower2.ogg',"rustle",)
var/list/iomoon_basement_sounds = list('sound/ambience/lavamoon_interior_fx1.ogg','sound/ambience/lavamoon_interior_fx3.ogg','sound/ambience/lavamoon_interior_fx4.ogg','sound/machines/engine_grump4.ogg','sound/machines/hiss.ogg','sound/vox/smoke.ogg','sound/effects/pump.ogg')
var/list/iomoon_ancient_sounds = list('sound/ambience/lavamoon_ancientarea_fx1.ogg','sound/ambience/lavamoon_ancientarea_fx2.ogg','sound/ambience/lavamoon_ancientarea_fx3.ogg')
var/sound/iomoon_alarm_sound = null

//Areas
/area/iomoon
	name = "Lava Moon Surface"
	icon_state = "red"
	filler_turf = "/turf/unsimulated/floor/lava"
	requires_power = 0
	RL_Lighting = 1
	RL_AmbientRed = 0.45
	RL_AmbientGreen = 0.2
	RL_AmbientBlue = 0.1

	sound_group = "iomoon"

	var/radiation_level = 0.5 //Value to set irradiated to during the mini-blowout.
	var/sound/ambientSound = 'sound/ambience/lavamoon_exterior_amb1.ogg'
	var/list/fxlist = null
	var/list/soundSubscribers = null
	var/use_alarm = 0



	New()
		..()
		fxlist = iomoon_exterior_sounds
		if (ambientSound)

			spawn (60)
				var/sound/S = new/sound()
				S.file = ambientSound
				S.repeat = 0
				S.wait = 0
				S.channel = 123
				S.volume = 60
				S.priority = 255
				S.status = SOUND_UPDATE
				ambientSound = S

				soundSubscribers = list()
				process()

				if (use_alarm && !iomoon_alarm_sound)
					iomoon_alarm_sound = new/sound()
					iomoon_alarm_sound.file = 'sound/machines/lavamoon_alarm1.ogg'
					iomoon_alarm_sound.repeat = 0
					iomoon_alarm_sound.wait = 0
					iomoon_alarm_sound.channel = 122
					iomoon_alarm_sound.volume = 60
					iomoon_alarm_sound.priority = 255
					iomoon_alarm_sound.status = SOUND_UPDATE

	Entered(atom/movable/Obj,atom/OldLoc)
		..()
		if (ambientSound && ismob(Obj))
//			if (Obj:client)
//				ambientSound.status = SOUND_UPDATE
//				Obj << ambientSound
			if (!soundSubscribers:Find(Obj))
				soundSubscribers += Obj

		return
/*
	Exited(atom/movable/Obj)
		if (ambientSound && ismob(Obj))
			if (Obj:client)
//				ambientSound.status = SOUND_PAUSED | SOUND_UPDATE
//				Obj << ambientSound
			if (master && master != src)
				master.soundSubscribers -= Obj
			else if (!master || master == src)
				src.soundSubscribers -= Obj
*/
	proc/process()
		if (!soundSubscribers)
			return

		var/sound/S = null
		var/sound_delay = 0


		while (ticker && ticker.current_state < GAME_STATE_FINISHED)
			sleep(60)

			if (prob(10) && fxlist)
				S = sound(file=pick(fxlist), volume=50)
				sound_delay = rand(0, 50)
			else
				S = null
				continue

			for (var/mob/living/H in soundSubscribers)
				var/area/mobArea = get_area(H)
				if (!istype(mobArea) || mobArea.type != type)
					soundSubscribers -= H
					if (H.client)
						ambientSound.status = SOUND_PAUSED | SOUND_UPDATE
						ambientSound.volume = 0
						H << ambientSound
					continue

				if (H.client)
					ambientSound.status = SOUND_UPDATE
					ambientSound.volume = 60
					H << ambientSound
					if (S)
						spawn (sound_delay)
							H << S

					if (use_alarm && iomoon_blowout_state == 1)
						H << iomoon_alarm_sound



/area/iomoon/base
	name = "Power Plant"
	icon_state = "yellow"
	filler_turf = "/turf/unsimulated/iomoon/floor"
	requires_power = 1
	RL_Lighting = 1
	luminosity = 0
	RL_AmbientRed = 0.3
	RL_AmbientGreen = 0.3
	RL_AmbientBlue = 0.3

	ambientSound = 'sound/ambience/lavamoon_interior_amb1.ogg'
	use_alarm = 1

	New()
		..()
		fxlist = iomoon_powerplant_sounds

/area/iomoon/base/underground
	name = "Power Plant Tunnels"

	ambientSound = 'sound/ambience/lavamoon_interior_amb2.ogg'

	New()
		..()
		fxlist = iomoon_basement_sounds


/area/iomoon/caves
	name = "Magma Cavern"
	filler_turf = "/turf/unsimulated/floor/lava"
	requires_power = 1
	RL_Lighting = 1
	luminosity = 0

	radiation_level = 0.75

	New()
		..()
		fxlist = iomoon_exterior_sounds

/area/iomoon/robot_ruins
	name = "Strange Ruins"
	icon_state = "purple"
	filler_turf = "/turf/unsimulated/iomoon/ancient_floor"
	requires_power = 1
	RL_Lighting = 1
	luminosity = 0

	radiation_level = 0.8
	ambientSound = 'sound/ambience/lavamoon_ancientarea_amb1.ogg'

	New()
		..()
		fxlist = iomoon_ancient_sounds

/area/iomoon/robot_ruins/boss_chamber
	name = "Central Chamber"
	icon_state = "blue"
	radiation_level = 1

	ambientSound = 'sound/ambience/lavamoon_ancientarea_fx2.ogg'

//Logs
/obj/item/audio_tape/iomoon_00
	New()
		..()
		messages = list("...s is Janet Habicht, Operations Manager.",
"Something is very wrong with the plant, stay awa-",
"*static*",
"*static*",
"it's in the caverns, the-",
"*static*")
		speakers = list("Female Voice","Female Voice","Female Voice","Female Voice","Female Voice","Female Voice")

/obj/item/audio_tape/iomoon_01
	New()
		..()
		speakers = list("Female Voice",
		"Female Voice",
		"Female Voice",
		"Female Voice",
		"Female Voice",
		"Female Voice",
		"Female Voice",
		"Female Voice")
		messages = list("*heavy breathing*",
"-hair's falling out...blood's coming up when I cough",
"I can't have long.",
"*heavy breathing, coughing*",
"If you are listening to this, get out. there is nothing but death here.",
"*coughing, labored breathing*",
"*labored breathing*",
"I'm sorry, Amy, I'm so so sorry.  Be good.")

/obj/item/device/audio_log/iomoon_01

	New()
		..()
		tape = new /obj/item/audio_tape/iomoon_01(src)

/obj/machinery/computer3/luggable/personal/iomoon
	name = "Research Laptop"
	desc = "A portable computer used for away team-style research."
	setup_drive_type = /obj/item/disk/data/fixed_disk/iomoon

/obj/item/disk/data/fixed_disk/iomoon

	New()
		..()
		//First off, create the directory for logging stuff
		var/computer/folder/newfolder = new /computer/folder(  )
		newfolder.name = "logs"
		root.add_file( newfolder )
		newfolder.add_file( new /computer/file/record/c3help(src))

		newfolder = new /computer/folder
		newfolder.name = "bin"
		root.add_file( newfolder )
		newfolder.add_file( new /computer/file/terminal_program/writewizard(src))
		//new
		newfolder = new /computer/folder
		newfolder.name = "doc"
		root.add_file( newfolder )
		newfolder.add_file( new /computer/file/record/iomoon_corrupt(src))
		newfolder.add_file( new /computer/file/record/iomoon_04(src))
		newfolder.add_file( new /computer/file/record/iomoon_06(src))
		newfolder.add_file( new /computer/file/record/iomoon_corrupt/iomoon_08(src) )

/obj/item/luggable_computer/personal/iomoon
	name = "Research Laptop"
	desc = "A portable computer used for away team-style research."
	luggable_type = /obj/machinery/computer3/luggable/personal/iomoon

/computer/file/record/iomoon_04
	name = "log04"
	fields = list("|--------------| Log 04 |--------------|",
	"We have now managed to breach the outer ",
	"shell of the obsidian structure. And the",
	"wonders we have found inside! Beyond the",
	"outer surface is a series of chambers.",
	"A base camp is now under construction in",
	"a room near our entry point. In the",
	"coming days, I hope to determine the age",
	"of the structure, map it out, and maybe",
	"begin to discern its purpose.",
	"|--------------------------------------|")

/computer/file/record/iomoon_06
	name = "log06"
	fields = list("|--------------| Log 06 |--------------|",
	"I am as of yet unsure as to the nature",
	"of the floating constructs, but it is",
	"probable that they are some manner of",
	"repair mechanism. After a minor incident",
	"I must stress that physical contact with",
	"the constructs is completely inadvisable.",
	"A shame, really. Whatever mechanism they",
	"use for their flight-the efficiency alone",
	"could revolutionize XG power storage.",
	"",
	"Ambient radiation levels in the chambers",
	"have continued to rise, slowly. They are",
	"fully within the tolerances of our suits,",
	"however.",
	"|--------------------------------------|")

/computer/file/record/iomoon_07
	name = "log07"
	fields = list("|--------------| Log 07 |--------------|",
	"Further ingress into the chambers has",
	"exposed a large magma containment vessel.",
	"This, coupled with the large number of",
	"energetic power conduits, indicates that",
	"this is a power production facility much",
	"like our own, but vastly more advanced!",
	"If only#&!@()(#)",
	"ffj&@____ +_122 )_*#=",
	"|--------------------------------------|")

/computer/file/record/iomoon_corrupt
	name = "log03"
	fields = list("|--------------| ERR 00 |--------------|",
"39293-ff0eKJFIie fjf f f  a a 201-_98*",
"1 ( 1-2 ** _* **_ | /  / _____ffe",
"|--------------------------------------|")

	iomoon_08
		name = "log08"

/obj/machinery/computer3/generic/personal/iomoon
	setup_starting_program = /computer/file/terminal_program/email/iomoon

/computer/file/terminal_program/email/iomoon
	defaultDomain = "XG5"

//Mainframe
/obj/machinery/networked/mainframe/iomoon
	setup_drive_type = /obj/item/disk/data/memcard/iomoon


/obj/item/disk/data/memcard/iomoon
	file_amount = 1024

	New()
		..()
		var/computer/folder/newfolder = new /computer/folder(  )
		newfolder.name = "sys"
		newfolder.metadata["permission"] = COMP_HIDDEN
		root.add_file( newfolder )
		newfolder.add_file( new /computer/file/mainframe_program/os/kernel(src) )
		newfolder.add_file( new /computer/file/mainframe_program/shell(src) )
		newfolder.add_file( new /computer/file/mainframe_program/login(src) )

		var/computer/folder/subfolder = new /computer/folder
		subfolder.name = "drvr" //Driver prototypes.
		newfolder.add_file( subfolder )
		//subfolder.add_file ( new FILEPATH GOES HERE )
		subfolder.add_file( new /computer/file/mainframe_program/driver/mountable/databank(src) )
		subfolder.add_file( new /computer/file/mainframe_program/driver/mountable/printer(src) )
		subfolder.add_file( new /computer/file/mainframe_program/driver/mountable/radio(src) )
		subfolder.add_file( new /computer/file/mainframe_program/driver/mountable/service_terminal(src) )

		subfolder = new /computer/folder
		subfolder.name = "srv"
		newfolder.add_file( subfolder )
		var/computer/file/mainframe_program/srv/email/emailsrv = new /computer/file/mainframe_program/srv/email(src)
		emailsrv.defaultDomain = "XG5"
		subfolder.add_file( emailsrv )
		subfolder.add_file( new /computer/file/mainframe_program/srv/print(src) )

		newfolder = new /computer/folder
		newfolder.name = "bin" //Applications available to all users.
		newfolder.metadata["permission"] = COMP_ROWNER|COMP_RGROUP|COMP_ROTHER
		root.add_file( newfolder )
		newfolder.add_file( new /computer/file/mainframe_program/utility/cd(src) )
		newfolder.add_file( new /computer/file/mainframe_program/utility/ls(src) )
		newfolder.add_file( new /computer/file/mainframe_program/utility/rm(src) )
		newfolder.add_file( new /computer/file/mainframe_program/utility/cat(src) )
		newfolder.add_file( new /computer/file/mainframe_program/utility/mkdir(src) )
		newfolder.add_file( new /computer/file/mainframe_program/utility/ln(src) )
		newfolder.add_file( new /computer/file/mainframe_program/utility/chmod(src) )
		newfolder.add_file( new /computer/file/mainframe_program/utility/chown(src) )
		newfolder.add_file( new /computer/file/mainframe_program/utility/su(src) )
		newfolder.add_file( new /computer/file/mainframe_program/utility/cp(src) )
		newfolder.add_file( new /computer/file/mainframe_program/utility/mv(src) )
		newfolder.add_file( new /computer/file/mainframe_program/utility/mount(src) )
		newfolder.add_file( new /computer/file/mainframe_program/guardbot_interface(src) )

		newfolder = new /computer/folder
		newfolder.name = "mnt"
		newfolder.metadata["permission"] = COMP_ROWNER|COMP_RGROUP|COMP_ROTHER
		root.add_file( newfolder )

		newfolder = new /computer/folder
		newfolder.name = "conf"
		newfolder.metadata["permission"] = COMP_ROWNER|COMP_RGROUP|COMP_ROTHER
		root.add_file( newfolder )

		var/computer/file/record/testR = new
		testR.name = "motd"
		testR.fields += "Welcome to DWAINE System VI!"
		testR.fields += "This System Licensed to Xiang-Geisel Advanced Power Systems"
		newfolder.add_file( testR )

		newfolder.add_file( new /computer/file/record/dwaine_help(src) )

		newfolder = new /computer/folder
		newfolder.name = "etc"
		newfolder.metadata["permission"] = COMP_ROWNER|COMP_RGROUP|COMP_ROTHER
		root.add_file( newfolder )

		subfolder = new /computer/folder
		subfolder.name = "mail"
		newfolder.add_file( subfolder )

		var/computer/file/record/groupRec = new /computer/file/record( )
		groupRec.name = "groups"
		subfolder.add_file( groupRec )

		subfolder.add_file( new /computer/file/record/iomoon_mail/rad_advisory(src) )
		subfolder.add_file( new /computer/file/record/iomoon_mail/flights(src) )
		subfolder.add_file( new /computer/file/record/iomoon_mail/cleanliness(src) )
		subfolder.add_file( new /computer/file/record/iomoon_mail/magma_chamber(src) )

		return

/computer/file/record/iomoon_mail
	New()
		..()
		name = "[copytext("\ref[src]", 4, 12)]GENERIC"

	flights
		New()
			..()
			fields = list("PUBLIC_XG",
			"*ALL",
			"SHIFT_COORDINATOR@CORPORATE.XG",
			"GENERIC@XG5",
			"HIGH",
			"End-shift flight delays",
			"Hello Staff,",
			"In spite of our extensive efforts and much communication with the",
			"shuttle lines, we have been unable to secure transit to bring in",
			"the next shift. We are all deeply sorry for this, and assure you",
			"that you will all be compensated appropriately for the extra",
			"duty time.",
			"Current expectations are no more than a month delay, which",
			"is well within plant operation and supply tolerances.",
			"",
			"Again, we apologize for the wait.  Please bear with us.",
			"Johann Eisenhauer",
			"Xiang-Giesel Advanced Power Systems")

	rad_advisory
		New()
			..()
			fields = list("PUBLIC_XG",
			"*ALL",
			"LOCALHOST",
			"GENERIC@XG5",
			"HIGH",
			"AUTOMATED ALERT",
			"This is an automated alert message sent as part of the XIANG-GEISEL",
			"AUTOMATED HAZARD WARNING SYSTEM. This message has been sent due to",
			"the detection of a critical safety hazard by plant sensors.",
			"",
			"!! CRITICAL RADIATION HAZARD DETECTED !!",
			"All personnel are to evacuate to the landing pad safety area at",
			"once and wait for further instructions.",
			"THIS IS NOT A DRILL")

	cleanliness
		New()
			..()
			fields = list("PUBLIC_XG",
			"*ALL",
			"JHABICHT@XG5",
			"GENERIC@XG5",
			"NORMAL",
			"Plant Cleanliness",
			"Hey folks,",
			"I had really hoped it wouldn't have come to this, but this looks",
			"to be the only way: clean up after yourselves, or the SHAME BOARD",
			"will be trotted back out.",
			"*Keep your work area free of wrappers and other trash.",
			"*Keep the restroom in good condition, there is only one in this",
			" module.  THIS MEANS YOU, GARY.",
			"*The break room doesn't clean itself!  Trash goes in the trash bins!")

	magma_chamber
		New()
			..()
			fields = list("PUBLIC_XG",
			"*ALL",
			"JHABICHT@XG5",
			"GENERIC@XG5",
			"HIGH",
			"Magma Chamber Safety",
			"Believe me, I know that our recent discovery down there is",
			"fascinating, but that's no reason to ignore existing regulations",
			"and safety procedures in place for the magma chamber area.")

//Critters
/obj/critter/lavacrab
	name = "magma crab"
	desc = "A strange beast resembling a crab boulder.  Not to be confused with a rock lobster."
	icon_state = "lavacrab"
	density = 1
	anchored = 1
	health = 30
	aggressive = 1
	defensive = 1
	wanderer = 0
	opensdoors = 0
	atkcarbon = 0
	atksilicon = 0
	firevuln = 0.1
	brutevuln = 0.4
	angertext = "grumbles at"
	butcherable = 0

	CritterAttack(mob/M)
		attacking = 1
		visible_message("<span style=\"color:red\"><strong>[src]</strong> pinches [M] with its claws!</span>")
		random_brute_damage(M, 3)
		if (M.stat || M.paralysis)
			task = "thinking"
			attacking = 0
			return
		spawn (35)
			attacking = 0

	ChaseAttack(mob/M)
		return CritterAttack(M)

	CritterDeath()
		alive = 0
		density = 0
		anchored = 0
		icon_state = "lavacrab-dead"
		walk_to(src,0)
		visible_message("<strong>[src]</strong> flops over dead!")

	ai_think()
		. = ..()
		anchored = alive

/obj/critter/ancient_repairbot
	name = "strange robot"
	desc = "It looks like some sort of floating repair bot or something?"
	icon_state = "ancient_repairbot"
	density = 0
	aggressive = 0
	health = 10
	defensive = 1
	wanderer = 1
	opensdoors = 0
	atkcarbon = 0
	atksilicon = 0
	firevuln = 0.1
	brutevuln = 0.6
	angertext = "beeps at"
	butcherable = 0
	attack_range = 3
	flying = 1
	generic = 0

	grumpy
		aggressive = 1
		atkcarbon = 1
		atksilicon = 1

	New()
		..()
		name = "[pick("strange","weird","odd","bizarre","quirky","antique")] [pick("robot","automaton","machine","gizmo","thingmabob","doodad","widget")]"

	ChaseAttack(mob/M)
		if (prob(33))
			playsound(loc, pick('sound/misc/ancientbot_grump.ogg','sound/misc/ancientbot_grump2.ogg'), 50, 1)
		return

	CritterDeath()
		if (!alive) return
		alive = 0
		walk_to(src,0)
		visible_message("<strong>[src]</strong> blows apart!")

		spawn (0)
			var/effects/system/spark_spread/s = unpool(/effects/system/spark_spread)
			s.set_up(3, 1, src)
			s.start()
			qdel(src)

	process()
		if (prob(7))
			visible_message("<strong>[src] beeps.</strong>")
			playsound(loc,pick('sound/misc/ancientbot_beep1.ogg','sound/misc/ancientbot_beep2.ogg','sound/misc/ancientbot_beep3.ogg'), 50, 1)
		..()
		return


	seek_target()
		..()
		if (task == "chasing" && target)
			playsound(loc, pick('sound/misc/ancientbot_grump.ogg','sound/misc/ancientbot_grump2.ogg'), 50, 1)

	CritterAttack(mob/M)
		attacking = 1
		spawn (35)
			attacking = 0

		var/atom/last = src
		var/atom/target_r = M

		var/list/dummies = new/list()

		playsound(src, "sound/effects/elec_bigzap.ogg", 40, 1)

		if (isturf(M))
			target_r = new/obj/elec_trg_dummy(M)

		var/turf/currTurf = get_turf(target_r)
		currTurf.hotspot_expose(2000, 400)

		for (var/count=0, count<4, count++)

			var/list/affected = DrawLine(last, target_r, /obj/line_obj/elec ,'icons/obj/projectiles.dmi',"WholeLghtn",1,1,"HalfStartLghtn","HalfEndLghtn",OBJ_LAYER,1,PreloadedIcon='icons/effects/LghtLine.dmi')

			for (var/obj/O in affected)
				spawn (6) pool(O)

			if (istype(target_r, /mob/living)) //Probably unsafe.
				playsound(target_r:loc, "sound/effects/electric_shock.ogg", 50, 1)
				target_r:shock(src, 15000, "chest", 1, 1)
				break

			var/list/next = new/list()
			for (var/atom/movable/AM in orange(3, target_r))
				if (istype(AM, /obj/line_obj/elec) || istype(AM, /obj/elec_trg_dummy) || istype(AM, /obj/overlay/tile_effect) || AM.invisibility)
					continue
				next.Add(AM)

			if (istype(target_r, /obj/elec_trg_dummy))
				dummies.Add(target_r)

			last = target_r
			target_r = pick(next)
			target = target_r

		for (var/d in dummies)
			qdel(d)

/obj/critter/ancient_repairbot/security
	name = "stranger robot"
	desc = "It looks rather mean."
	icon_state = "ancient_guardbot"
	aggressive = 1
	health = 15
	atkcarbon = 1
	atksilicon = 1


//Decor

/obj/shrub/dead
	name = "Dead shrub"
	icon = 'icons/misc/worlds.dmi'
	icon_state = "shrub-dead"



//Items
/obj/item/reagent_containers/food/snacks/takeout
	name = "Chinese takeout carton"
	desc = "Purports to contain \"General Zeng's Chicken.\"  How old is this?"
	icon = 'icons/obj/foodNdrink/food_snacks.dmi'
	icon_state = "takeout"
	heal_amt = 1

	New()
		var/reagents/R = new/reagents(60)
		reagents = R
		R.my_atom = src
		R.add_reagent("chickensoup", 10)
		R.add_reagent("salt", 10)
		R.add_reagent("grease", 5)
		R.add_reagent("msg", 2)
		R.add_reagent("VHFCS", 8)
		R.add_reagent("egg",5)

/obj/item/yoyo
	name = "Atomic Yo-Yo"
	desc = "Molded into the transparent neon plastic are the words \"ATOMIC CONTAGION F VIRAL YO-YO.\"  It's as extreme as the 1990s."
	icon = 'icons/obj/items.dmi'
	icon_state = "yoyo"
	item_state = "yoyo"
	inhand_image_icon = 'icons/mob/inhand/hand_general.dmi'

/obj/spawner/ancient_robot_artifact
	name = "robot artifact spawn"
	icon = 'icons/misc/mark.dmi'
	icon_state = "x3"

	New()
		..()
		spawn (10)
			var/spawntype = pick(/obj/item/artifact/activator_key, /obj/item/gun/energy/artifact, /obj/item/ammo/power_cell/self_charging/artifact, /obj/item/artifact/forcewall_wand, /obj/item/artifact)
			new spawntype(loc, "ancient")

			qdel(src)


//Clothing & Associated Equipment
/obj/item/clothing/suit/rad/iomoon
	name = "FB-8 Environment Suit"
	desc = "A rather old-looking suit designed to guard against extreme heat and radiation."
	icon_state = "rad_io"
	item_state = "rad_io"
	heat_transfer_coefficient = 0.05
	protective_temperature = 7500

/obj/item/clothing/head/rad_hood/iomoon
	name = "FB-8 Environment Hood"
	desc = "The paired hood to the FB-8 environment suit. Not in the least stylish."
	icon_state = "radhood"
	item_state = "radhood"

//obj/closet/iomoon
/obj/storage/closet/iomoon
	name = "\improper Thermal Hazard Equipment"
	desc = "A locker intended to carry protective clothing."
	icon_state = "syndicate"
	icon_opened = "syndicate-open"
	icon_closed = "syndicate"
	spawn_contents = list(/obj/item/clothing/suit/rad/iomoon,\
	/obj/item/clothing/head/rad_hood/iomoon)

/obj/machinery/light/small/iomoon
	name = "emergency light"
	light_type = /obj/item/light/bulb/emergency

//Irradiate event.
var/global/iomoon_blowout_state = 0 //0: Hasn't occurred, 1: Moon is irradiated & Boss is alive, 3: Boss killed, radiation over, -1: Something broke, so much for that.
/proc/event_iomoon_blowout()
	if (iomoon_blowout_state)
		return

	iomoon_blowout_state = 1

	message_admins("EVENT: IOMOON mini-blowout event triggered.")
	var/list/iomoon_areas = get_areas(/area/iomoon)
	if (!iomoon_areas.len)
		iomoon_blowout_state = -1
		logTheThing("debug", null, null, "IOMOON: Unable to locate areas for event_iomoon_blowout.")
		return

	for (var/area/iomoon/adjustedArea in iomoon_areas)
		adjustedArea.irradiated = adjustedArea.radiation_level

		for (var/mob/N in adjustedArea)
			N.flash(30)

			spawn (0)
				shake_camera(N, 210, 2)
	//todo: Alarms.  Not the dumb siren, I mean like the power plant's computer systems freaking the fuck out because oh jesus radiation

	var/obj/machinery/networked/mainframe/mainframe = locate("IOMOON_MAINFRAME")
	if (istype(mainframe) && mainframe.hd)
		for (var/computer/folder/folder1 in mainframe.hd.root.contents)
			if (ckey(folder1.name) == "etc")
				for (var/computer/folder/folder2 in folder1.contents)
					if (ckey(folder2.name) == "mail")
						folder2.add_file( new /computer/file/record/iomoon_mail/rad_advisory(src) )
						break

				break

	var/obj/iomoon_boss/core/theBoss = locate("IOMOON_BOSS")
	if (istype(theBoss))
		theBoss.activate()

	return

/proc/end_iomoon_blowout()
	if (iomoon_blowout_state != 1)
		return

	iomoon_blowout_state = -1
	message_admins("EVENT: IOMOON mini-blowout event ending.")
	var/list/iomoon_areas = get_areas(/area/iomoon)
	if (!iomoon_areas.len)
		iomoon_blowout_state = -1
		logTheThing("debug", null, null, "IOMOON: Unable to locate areas for end_iomoon_blowout. Welp!")
		return

	for (var/area/iomoon/adjustedArea in iomoon_areas)
		adjustedArea.irradiated = 0

	var/obj/iomoon_puzzle/ancient_robot_door/prizedoor = locate("IOMOON_PRIZEDOOR")
	if (istype(prizedoor))
		prizedoor.open()

	return

//THE BOSS
#define PREZAP_WAIT 15
#define REZAP_WAIT 10
#define PANIC_HEALTH_LEVEL 30
#define STATE_DEFAULT 0
#define STATE_MARKER_OUT 1
#define STATE_RECHARGING 2

/obj/iomoon_boss
	anchored = 1
	density = 1

	activation_button
		name = "foreboding panel"
		desc = "Pressing this would probably be a bad idea."
		icon = 'icons/misc/worlds.dmi'
		icon_state = "boss_button0"
		layer = OBJ_LAYER
		var/active = 0

		attack_hand(mob/user as mob)
			if (user.stat || user.weakened || get_dist(user, src) > 1 || !user.can_use_hands())
				return

			user.visible_message("<span style=\"color:red\">[user] presses [src].</span>", "<span style=\"color:red\">You press [src].</span>")
			if (active)
				boutput(user, "Nothing happens.")
				return

			active = 1
			flick("boss_button_activate", src)
			icon_state = "boss_button1"

			playsound(loc,"sound/machines/lavamoon_alarm1.ogg", 70,0)
			sleep(50)
			event_iomoon_blowout()

	bot_spawner
		name = "weird assembly"
		desc = "It looks like a tesla coil mated with a crab."
		icon = 'icons/misc/worlds.dmi'
		icon_state = "bot_spawner"
		dir = 2
		var/active = 0
		var/health = 20
		var/max_bots = 5

		attackby(obj/item/I, mob/user as mob)
			if (!I.force || health <= 0)
				return

			user.visible_message("<span style=\"color:red\"><strong>[user] bonks [src] with [I]!</strong></span>","<span style=\"color:red\"><strong>You hit [src] with [I]!</strong></span>")
			if (iomoon_blowout_state == 0)
				playsound(loc,"sound/machines/lavamoon_alarm1.ogg", 70,0)
				event_iomoon_blowout()
				return

			if (I.damtype == "brute")
				health -= I.force * 0.50
			else
				health -= I.force * 0.25


			if (health <= 0 && active != -1)
				dir = 2
				active = -1
				visible_message("<span style=\"color:red\">[src] shuts down. Forever.</span>")
				return



		proc/spawn_bot()
			if (active || (max_bots  < 1))
				return -1

			max_bots--
			active = 1
			dir = 1
			visible_message("<span style=\"color:red\">[src] begins to whirr ominously!</span>")
			spawn (20)
				if (health <= 0)
					dir = 2
					return
				dir = 4
				sleep(10)
				if (health <= 0)
					dir = 2
					return

				if (prob(80))
					new /obj/critter/ancient_repairbot/grumpy (loc)
				else
					new /obj/critter/ancient_repairbot/security (loc)

				visible_message("<span style=\"color:red\">[src] plunks out a robot! Oh dear!</span>")
				active = 0
				dir = 2

			return

	core
		name = "mechanism core"
		desc = "An enormous artifact of some sort. You feel uncomfortable just being near it."
		icon = 'icons/misc/worlds.dmi'
		icon_state = "powercore_core_dead"
		layer = 4.5 // TODO LAYER

		var/active = 0
		var/health = 100
		var/obj/iomoon_boss/rotor/rotors = null
		var/obj/iomoon_boss/base/base = null
		var/obj/iomoon_boss/zap_marker/zapMarker = null
		var/last_state_time = 0
		var/last_noise_time = 0
		var/last_noise_length = 0

		var/list/spawners = list()

		var/state = STATE_DEFAULT
/*
		//DEBUG
		default_click()
			spawn (0)
				activate()
				sleep(200)
				//world << zap_somebody(usr)
				//sleep(50)
				death()
*/
		New()
			..()
			if (!tag)
				tag = "IOMOON_BOSS"

			spawn (10)
				//target_marker = image('icons/misc/worlds.dmi', "boss_marker")
				//target_marker.layer = FLY_LAYER

				rotors = new /obj/iomoon_boss/rotor (locate(x - 2, y - 2, z))
				rotors.core = src

				base = new /obj/iomoon_boss/base (rotors.loc)
				base.core = src

				zapMarker = new /obj/iomoon_boss/zap_marker (src)

				for (var/obj/iomoon_boss/bot_spawner/spawner in range(src, 10))
					spawners += spawner

		attackby(obj/item/I, mob/user as mob)
			if (!I.force || active != 1)
				return

			if (I.damtype == "brute")
				health -= I.force * 0.50
			else
				health -= I.force * 0.25

			user.visible_message("<span style=\"color:red\"><strong>[user] bonks [src] with [I]!</strong></span>","<span style=\"color:red\"><strong>You hit [src] with [I]!</strong></span>")
			if (health <= 0)
				death()
				return

			else if (health <= PANIC_HEALTH_LEVEL)
				if (spawners)
					for (var/obj/iomoon_boss/bot_spawner/aSpawner in spawners)
						aSpawner.spawn_bot()
				if (rotors)
					rotors.icon_state = "powercore_rotors_fast"


		attack_hand(var/mob/user as mob)
			if (active != 1)
				return

			if (user.a_intent == "harm")
				health -= rand(1,2) * 0.5
				user.visible_message("<span style=\"color:red\"><strong>[user]</strong> punches [src]!</span>", "<span style=\"color:red\">You punch [src]![prob(25) ? " It's about as effective as you would expect!" : null]</span>")
				playsound(loc, "punch", 50, 1)


				if (health <= 0)
					death()
					return

				else if (health <= PANIC_HEALTH_LEVEL)
					if (spawners)
						for (var/obj/iomoon_boss/bot_spawner/aSpawner in spawners)
							aSpawner.spawn_bot()
					if (rotors)
						rotors.icon_state = "powercore_rotors_fast"

			else
				visible_message("<span style=\"color:red\"><strong>[user]</strong> pets [src]!  For some reason!</span>")

		bullet_act(var/obj/projectile/P)

			if (active != 1)
				return

			if (P.proj_data.damage_type == D_KINETIC || P.proj_data.damage_type == D_PIERCING)
				health -= round(((P.power/8)*P.proj_data.ks_ratio), 1.0)

			if (health <= 0)
				death()

			else if (health <= PANIC_HEALTH_LEVEL)
				if (spawners)
					for (var/obj/iomoon_boss/bot_spawner/aSpawner in spawners)
						aSpawner.spawn_bot()
				if (rotors)
					rotors.icon_state = "powercore_rotors_fast"

			return

		disposing()
			rotors = null
			base = null
			zapMarker = null
			if (spawners)
				spawners.len = 0

			..()

		proc
			activate()
				if (active)
					return

				active = 1
				icon_state = "powercore_core_startup"
				spawn (6)
					icon_state = "powercore_core"

				if (rotors)
					rotors.icon_state = "powercore_rotors_start"
					spawn (24)
						rotors.icon_state = "powercore_rotors"
					playsound(loc, "sound/machines/lavamoon_rotors_starting.ogg",50, 0)
					last_noise_time = ticker.round_elapsed_ticks
					last_noise_length = 80

				critters += src

			process()
				if (last_noise_time + last_noise_length < ticker.round_elapsed_ticks)
					if (health <= 10)
						playsound(loc, "sound/machines/lavamoon_rotors_fast.ogg", 50, 0)
						last_noise_length = 90
					else
						playsound(loc, "sound/machines/lavamoon_rotors_slow.ogg", 50, 0)
						last_noise_length = 70

					last_noise_time = ticker.round_elapsed_ticks


				switch (state)
					if (STATE_DEFAULT)
						plunk_down_marker()
						if (spawners && spawners.len)
							var/obj/iomoon_boss/bot_spawner/aSpawner = pick(spawners)
							aSpawner.spawn_bot()

					if (STATE_MARKER_OUT)
						if (ticker.round_elapsed_ticks >= (last_state_time + PREZAP_WAIT))
							zap_somebody()

					if (STATE_RECHARGING)
						if (ticker.round_elapsed_ticks >= (last_state_time + REZAP_WAIT))
							state = STATE_DEFAULT

			plunk_down_marker()
				if (!zapMarker)
					zapMarker = new /obj/iomoon_boss/zap_marker(src)

				var/turf/newLoc
				switch (rand(1, 8))
					if (1)
						newLoc = locate(x, y + 4, z)

					if (2)
						newLoc = locate(x + 3, y + 3, z)

					if (3)
						newLoc = locate(x + 4, y, z)

					if (4)
						newLoc = locate(x + 3, y - 3, z)

					if (5)
						newLoc = locate(x, y - 4, z)

					if (6)
						newLoc = locate(x - 3, y - 4, z)

					if (7)
						newLoc = locate(x - 4, y, z)

					if (8)
						newLoc = locate(x - 3, y + 3, z)

				if (newLoc)
					zapMarker.set_loc(newLoc)
					last_state_time = ticker.round_elapsed_ticks
					state = STATE_MARKER_OUT

				return FALSE

			death()
				if (active == -1)
					return

				critters -= src

				active = -1
				if (zapMarker)
					zapMarker.dispose()
					zapMarker = null

				end_iomoon_blowout()
				spawn (0)
					var/effects/system/spark_spread/E = unpool(/effects/system/spark_spread)
					E.set_up(8,0, loc)
					E.start()
					icon_state = "powercore_core_die"
					if (rotors)
						rotors.icon_state = "powercore_rotors_stop"
						playsound(loc, "sound/machines/lavamoon_rotors_stopping.ogg", 50, 1)
					sleep (50)
					if (rotors)
						rotors.icon_state = "powercore_rotors_off"
					sleep(25)
					icon_state = "powercore_core_dead"
					if (base)
						base.icon_state = "powercore_base_off"

					var/obj/overlay/O = new/obj/overlay( loc )
					O.anchored = 1
					O.name = "Explosion"
					O.layer = NOLIGHT_EFFECTS_LAYER_BASE
					O.pixel_x = -20
					O.pixel_y = -20
					O.icon = 'icons/effects/hugeexplosion2.dmi'
					O.icon_state = "explosion"
					playsound(loc, "explosion", 75, 1)
					sleep(25)
					//qdel(rotors)
					invisibility = 100

					var/obj/decal/exitMarker = locate("IOMOON_BOSSDEATH_EXIT")
					if (istype(exitMarker))
						var/obj/perm_portal/portalOut = new
						portalOut.target = exitMarker
						portalOut.icon = 'icons/misc/worlds.dmi'
						portalOut.icon_state = "jitterportal"
						portalOut.layer = 4 // TODO layer
						portalOut.set_loc(loc)

					sleep(10)
					if (O)
						O.dispose()
					qdel(src)

			zap_somebody()
				if (!zapMarker || zapMarker.loc == src)
					return -1

				playsound(src, "sound/effects/elec_bigzap.ogg", 40, 1)

				var/list/lineObjs
				lineObjs = DrawLine(src, zapMarker, /obj/line_obj/elec, 'icons/obj/projectiles.dmi',"WholeLghtn",1,1,"HalfStartLghtn","HalfEndLghtn",FLY_LAYER,1,PreloadedIcon='icons/effects/LghtLine.dmi')

				for (var/mob/living/poorSoul in range(zapMarker, 2))
					lineObjs += DrawLine(zapMarker, poorSoul, /obj/line_obj/elec, 'icons/obj/projectiles.dmi',"WholeLghtn",1,1,"HalfStartLghtn","HalfEndLghtn",FLY_LAYER,1,PreloadedIcon='icons/effects/LghtLine.dmi')

					poorSoul << sound('sound/effects/electric_shock.ogg', volume=50)
					random_burn_damage(poorSoul, 45)
					boutput(poorSoul, "<span style=\"color:red\"><strong>You feel a powerful shock course through your body!</strong></span>")
					poorSoul.unlock_medal("HIGH VOLTAGE", 1)
					poorSoul:Virus_ShockCure(poorSoul, 100)
					poorSoul:shock_cyberheart(100)
					poorSoul:weakened += rand(3,5)
					if (poorSoul.stat == 2 && prob(25))
						poorSoul.gib()

				spawn (6)
					for (var/obj/O in lineObjs)
						pool(O)

				state = STATE_RECHARGING
				last_state_time = ticker.round_elapsed_ticks
				zapMarker.set_loc(src)

				return FALSE


	rotor
		name = "giant rotors"
		desc = "An enormous artifact of some sort. You feel uncomfortable just being near it. Probably because it is a giant piece of dangerous machinery."
		icon = 'icons/effects/160x160.dmi'
		icon_state = "powercore_rotors_off"
		bound_height = 160
		bound_width = 160
		layer = 3.9 // TODO layer
		density = 0

		var/obj/iomoon_boss/core/core = null

	base
		name = "huge contraption"
		desc = "An enormous artifact of some sort. You feel uncomfortable just being near it."
		anchored = 1
		density = 0
		icon = 'icons/effects/160x160.dmi'
		icon_state = "powercore_base"
		bound_height = 160
		bound_width = 160
		layer = 3.7 // TODO layer

		var/obj/iomoon_boss/core/core = null

	zap_marker
		name = "danger zone"
		desc = "Some sort of light phenomena indicating that this area is hazardous.  Do NOT take a highway to it."
		density = 0
		layer = 2.5 // TODO layer
		icon = 'icons/effects/64x64.dmi'
		icon_state = "boss_marker"
		pixel_x = -16
		pixel_y = -16

#undef PREZAP_WAIT
#undef REZAP_WAIT
#undef PANIC_HEALTH_LEVEL
#undef STATE_DEFAULT
#undef STATE_MARKER_OUT
#undef STATE_RECHARGING


/obj/decal/fakeobjects/tallsmes
	name = "large power storage unit"
	desc = "An ultra-high-capacity superconducting magnetic energy storage (SMES) unit."
	icon = 'icons/misc/worlds.dmi'
	icon_state = "tallsmes0"
	anchored = 1
	density = 1

	New()
		..()
		var/image/I = image(icon, icon_state="tallsmes1")
		I.pixel_y = 32
		I.layer = FLY_LAYER
		overlays += I

/obj/ladder
	name = "ladder"
	desc = "A series of parallel bars designed to allow for controlled change of elevation.  You know, by climbing it.  You climb it."
	icon = 'icons/misc/worlds.dmi'
	icon_state = "ladder"
	anchored = 1
	density = 0
	var/id = null

	New()
		..()
		if (!id)
			id = "generic"

		tag = "ladder_[id][icon_state == "ladder" ? 0 : 1]"

	attack_hand(mob/user as mob)
		if (user.stat || user.weakened || get_dist(user, src) > 1)
			return

		var/obj/ladder/otherLadder = locate("ladder_[id][icon_state == "ladder"]")
		if (!istype(otherLadder))
			return

		user.visible_message("", "You climb [icon_state == "ladder" ? "down" : "up"] the ladder.")
		user.set_loc(get_turf(otherLadder))

//Puzzle elements

/obj/iomoon_puzzle
	var/id = null
	proc
		activate()

		deactivate()

//ancient robot door
/obj/iomoon_puzzle/ancient_robot_door
	name = "sealed door"
	desc = "Not only is it one hell of a foreboding door, it's also sealed fast.  It doesn't have any apparent means of opening."
	icon = 'icons/misc/worlds.dmi'
	icon_state = "ancientwall2"
	density = 1
	anchored = 1
	opacity = 1
	var/active = 0
	var/opened = 0
	var/changing_state = 0
	var/default_state = 0 //0: closed, 1: open

	New()
		..()
		spawn (5)
			default_state = opened
			active = 0

	proc
		open()
			if (opened || changing_state == 1)
				return

			opened = 1
			changing_state = 1
			active = (opened != default_state)

			flick("ancientdoor_open",src)
			icon_state = "ancientdoor_opened"
			density = 0
			opacity = 0
			desc = "One hell of a foreboding door. It's not entirely clear how it opened, as the seams did not exist prior..."
			name = "unsealed door"
			spawn (13)
				changing_state = 0
			return


		close()
			if (!opened || changing_state == -1)
				return

			opened = 0
			changing_state = -1
			active = (opened != default_state)

			density = 1
			opacity = 1
			flick("ancientdoor_close",src)
			icon_state = "ancientwall2"
			desc = initial(desc)
			name = initial(name)
			spawn (13)
				changing_state = 0
			return

		toggle()
			if (opened)
				return close()
			else
				return open()

	activate()
		if (active)
			return

		if (opened)
			return close()

		return open()

	deactivate()
		if (!active)
			return

		if (opened)
			return close()

		return open()

/obj/iomoon_puzzle/ancient_robot_door/energy
	name = "energy field"
	desc = "A field of energy!  Some sort of energy.  Probably a really weird one."
	icon = 'icons/misc/worlds.dmi'
	icon_state = "energywall"
	opacity = 0
	var/obj/iomoon_puzzle/ancient_robot_door/energy/next = null
	dir = 4
	var/length = 1
	var/light/light

	New()
		..()
		light = new /light/point
		light.attach(src)
		light.set_color(0.8,1,0)
		light.set_brightness(0.4)


		if (length > 1)
			var/obj/iomoon_puzzle/ancient_robot_door/energy/current = src
			while (length-- > 1)
				current.next = new type ( get_step(current, dir) )
				current.next.dir = current.dir
				current.next.opened = opened
				current = current.next

		spawn (10)
			if (opened)
				invisibility = 100
				density = 0
				light.enable()
			else
				light.disable()

	disposing()
		if (next)
			next.disposing()
			next = null

		..()

	open()
		if (opened || changing_state == 1)
			return

		opened = 1
		changing_state = 1
		active = (opened != default_state)

		playsound(loc, "sound/effects/mag_iceburstimpact.ogg", 25, 1)

		density = 0
		invisibility = 100
		light.disable()
		spawn (13)
			changing_state = 0

		if (next && next != src)
			next.open()

		return

	close()
		if (!opened || changing_state == -1)
			return

		opened = 0
		changing_state = -1
		active = (opened != default_state)

		playsound(loc, "sound/effects/mag_iceburstimpact.ogg", 25, 1)

		density = 1
		invisibility = 0

		light.enable()
		if (next && next != src)
			next.close()

		spawn (13)
			changing_state = 0

/obj/iomoon_puzzle/floor_pad
	name = "curious platform"
	desc = "A slightly elevated floor panel.  It matches the \"creepy ancient shit\" aesthetic pretty well."
	icon = 'icons/misc/worlds.dmi'
	icon_state = "ancient_floorpanel0"
	anchored = 1
	density = 0
	var/pads_required = 1 //Number of total active pads required to open a door, not including this one.  If 0, all pads must be INACTIVE instead.
	var/pads_active = 0
	var/active = 0
	var/changing_state = 0
	var/atom/activator = null

	New()
		..()
		if (findtext(id, ";"))
			id = params2list(id)

		spawn (10)
			for (var/atom/potential_activator in loc)
				if (potential_activator.density)
					Crossed(potential_activator)
					break

	Crossed(var/atom/crosser as mob|obj)
		if (!activator || !(activator in loc))
			//if (crosser.density && !istype(crosser, /mob/living/silicon/hivebot/eyebot))
			if (!istype(crosser, /obj/item) && !istype(crosser, /mob/living/silicon/hivebot/eyebot))
				activator = crosser
				if (!active)
					activate()

		 return

	Uncrossed(var/atom/crosser as mob|obj)
		if (crosser == activator)
			activator = null
			if (active)
				deactivate()

		return

	activate(var/target_only)
		if (!target_only)
			if (active || changing_state == 1)
				return TRUE

			active = 1
			playsound(loc, "sound/effects/stoneshift.ogg", 25, 1)
			flick("ancient_floorpanel_activate",src)
			icon_state = "ancient_floorpanel1"

		if (id)
			if (istype(id, /list))
				for (var/sub_id in id)
					var/obj/iomoon_puzzle/target_element = locate(sub_id)
					if (istype(target_element, /obj/iomoon_puzzle/floor_pad))
						var/obj/iomoon_puzzle/floor_pad/target_pad = target_element
						if (pads_required == 0)
							target_pad.remote_deactivate()
						else if ((pads_active + active) >= pads_required)
							target_pad.remote_activate()

					else if (istype(target_element, /obj/iomoon_puzzle/ancient_robot_door))
						var/obj/iomoon_puzzle/ancient_robot_door/target_door = target_element
						if (pads_required == 0)
							target_door.deactivate()
						else if ((pads_active + active) >= pads_required)
							target_door.activate()

				return FALSE

			var/obj/iomoon_puzzle/target_element = locate(id)
			if (istype(target_element, /obj/iomoon_puzzle/floor_pad))
				var/obj/iomoon_puzzle/floor_pad/target_pad = target_element
				if (pads_required == 0)
					target_pad.remote_deactivate()
				else if ((pads_active + active) >= pads_required)
					target_pad.remote_activate()

			else if (istype(target_element, /obj/iomoon_puzzle/ancient_robot_door))
				var/obj/iomoon_puzzle/ancient_robot_door/target_door = target_element
				if (pads_required == 0)
					target_door.deactivate()
				else if ((pads_active + active) >= pads_required)
					target_door.activate()

		return FALSE

	deactivate(var/target_only)
		if (!target_only)
			if (!active)
				return TRUE

			active = 0

			playsound(loc, "sound/effects/stoneshift.ogg", 25, 1)
			flick("ancient_floorpanel_deactivate",src)
			icon_state = "ancient_floorpanel0"

		if (id)
			if (istype(id, /list))
				for (var/sub_id in id)
					var/obj/iomoon_puzzle/target_element = locate(sub_id)
					if (istype(target_element, /obj/iomoon_puzzle/floor_pad))
						var/obj/iomoon_puzzle/floor_pad/target_pad = target_element
						if (pads_required == 0 && (pads_active + active) == 0)
							target_pad.remote_activate()
						else if ((pads_active + active) < pads_required)
							target_pad.remote_deactivate()

					else if (istype(target_element, /obj/iomoon_puzzle/ancient_robot_door))
						var/obj/iomoon_puzzle/ancient_robot_door/target_door = target_element
						if (pads_required == 0 && (pads_active + active) == 0)
							target_door.activate()
						else if ((pads_active + active) < pads_required)
							target_door.deactivate()

				return FALSE

			var/obj/iomoon_puzzle/target_element = locate(id)
			if (istype(target_element, /obj/iomoon_puzzle/floor_pad))
				var/obj/iomoon_puzzle/floor_pad/target_pad = target_element
				if (pads_required == 0 && (pads_active + active) == 0)
					target_pad.remote_activate()
				else if ((pads_active + active) < pads_required)
					target_pad.remote_deactivate()

			else if (istype(target_element, /obj/iomoon_puzzle/ancient_robot_door))
				var/obj/iomoon_puzzle/ancient_robot_door/target_door = target_element
				if (pads_required == 0 && (pads_active + active) == 0)
					target_door.activate()
				else if ((pads_active + active) < pads_required)
					target_door.deactivate()

		return FALSE

	proc
		remote_activate()
			pads_active++
			if (pads_required == 0)
				return deactivate(1)
			else if ((pads_active + active) >= pads_required)
				return activate(1)

			return TRUE

		remote_deactivate()
			pads_active = max(0, pads_active-1)
			if (pads_required == 0 && (pads_active + active) == 0)
				return activate(1)
			else if ((pads_active + active) < pads_required)
				return deactivate(1)

			return TRUE

/obj/item/iomoon_key
	name = "antediluvian key"
	desc = "This is obviously an ancient unlocking gizmo of some sort.  Clearly."
	icon = 'icons/misc/worlds.dmi'
	icon_state = "robotkey-blue"
	w_class = 2
	var/keytype = 0 //0: blue, 1: red

	red
		name = "chthonic key"
		icon_state = "robotkey-red"
		keytype = 1

/obj/iomoon_puzzle/lock
	name = "daedalean doo-dad"
	desc = "This is clearly some sort of lock in need of a key.  Obviously."
	icon = 'icons/misc/worlds.dmi'
	icon_state = "lock-blue"
	anchored = 1
	density = 1
	var/locktype = 0 //0: blue, 1: red
	var/active = 0
	var/activations = 0
	var/activations_needed = 1

	red
		name = "abstruse gizmo"
		locktype = 1
		icon_state = "lock-red"

	New()
		..()

		if (findtext(id, ";"))
			id = params2list(id)

	attackby(obj/item/iomoon_key/I, mob/user as mob)
		if (istype(I))
			if (icon_state == initial(icon_state) && I.keytype == locktype)
				icon_state += "-active"
				user.visible_message("<span style=\"color:red\">[user] plugs [I] into [src]!</span>", "You pop [I] into [src].")
				playsound(loc, "sound/effects/syringeproj.ogg", 50, 1)
				user.drop_item()
				I.dispose()
				activate()
			else
				boutput(user, "<span style=\"color:red\">It won't fit!</span>")

		else
			..()

	activate()
		if (active)
			return TRUE

		if (++activations >= activations_needed)
			active = 1

			if (id)
				if (istype(id, /list))
					for (var/sub_id in id)
						var/obj/iomoon_puzzle/ancient_robot_door/target_door = locate(sub_id)
						if (istype(target_door))
							target_door.activate()

						else if (istype(target_door, /obj/iomoon_puzzle/lock))
							var/obj/iomoon_puzzle/button/target_lock = target_door
							target_lock.activate()
				else
					var/obj/iomoon_puzzle/ancient_robot_door/target_door = locate(id)
					if (istype(target_door))
						target_door.activate()

					else if (istype(target_door, /obj/iomoon_puzzle/lock))
						var/obj/iomoon_puzzle/button/target_lock = target_door
						target_lock.activate()

/obj/iomoon_puzzle/button
	name = "primordial panel"
	desc = "Some manner of strange panel, built of a strange and foreboding metal."
	icon = 'icons/misc/worlds.dmi'
	icon_state = "ancient_button0"
	anchored = 1
	density = 1
	var/timer = 0 //Seconds to toggle back off after activation.  Zero to just act as a toggle.
	var/active = 0
	var/latching = 0 //Remain on indefinitely.
	var/open_mode = 0 //0 for closed->open, 1 for open->closed

	New()
		..()

		if (findtext(id, ";"))
			id = params2list(id)

	attack_hand(mob/user as mob)
		if (user.stat || user.weakened || get_dist(user, src) > 1 || !user.can_use_hands())
			return

		user.visible_message("<span style=\"color:red\">[user] presses [src].</span>", "<span style=\"color:red\">You press [src].</span>")
		return toggle()

	proc/toggle()
		if (timer)
			if (active)
				return TRUE

			return activate()

		if (active)
			return deactivate()
		else
			return activate()

	activate()
		if (active)
			return TRUE

		playsound(loc, "sound/effects/syringeproj.ogg", 50, 1)
		flick("ancient_button_activate",src)
		icon_state = "ancient_button[++active]"

		if (timer)
			if (timer > 3)
				icon_state = "ancient_button_timer_slow"
				spawn ((timer - 3) * 10)
					icon_state = "ancient_button_timer_fast"
					sleep(30)
					deactivate()

			else
				icon_state = "ancient_button_timer_fast"
				spawn (timer * 10)
					deactivate()

		if (id)
			if (istype(id, /list))
				for (var/sub_id in id)
					var/obj/iomoon_puzzle/ancient_robot_door/target_door = locate(sub_id)
					if (istype(target_door))
						if (open_mode)
							target_door.deactivate()
						else
							target_door.activate()
			else
				var/obj/iomoon_puzzle/ancient_robot_door/target_door = locate(id)
				if (istype(target_door))
					if (open_mode)
						target_door.deactivate()
					else
						target_door.activate()

		return FALSE

	deactivate()
		if (!active || latching)
			return TRUE

		playsound(loc, "sound/effects/syringeproj.ogg", 50, 1)
		flick("ancient_button_deactivate", src)
		icon_state = "ancient_button[--active]"

		if (id)
			if (istype(id, /list))
				for (var/sub_id in id)
					var/obj/iomoon_puzzle/ancient_robot_door/target_door = locate(sub_id)
					if (istype(target_door))
						if (open_mode)
							target_door.activate()
						else
							target_door.deactivate()
			else
				var/obj/iomoon_puzzle/ancient_robot_door/target_door = locate(id)
				if (istype(target_door))
					if (open_mode)
						target_door.activate()
					else
						target_door.deactivate()

		return FALSE


/obj/rack/iomoon
	name = "odd pedestal"
	desc = "Some sort of ancient..platform.  For holding things.  Or maybe it's an oven or something, who knows!"
	icon = 'icons/misc/worlds.dmi'
	icon_state = "pedestal"

	attackby()
		return