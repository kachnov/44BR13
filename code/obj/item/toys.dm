
/obj/item/toy/sword
	name = "toy sword"
	icon = 'icons/obj/weapons.dmi'
	icon_state = "sword1"
	inhand_image_icon = 'icons/mob/inhand/hand_cswords.dmi'
	desc = "A sword made of cheap plastic. Contains a colored LED. Collect all five!"
	throwforce = 1
	w_class = 1.0
	throw_speed = 4
	throw_range = 5
	contraband = 3
	stamina_damage = 1
	stamina_cost = 3
	stamina_crit_chance = 1
	var/sound_attackM1 = 'sound/weapons/male_toyattack.ogg'
	var/sound_attackM2 = 'sound/weapons/male_toyattack2.ogg'
	var/sound_attackF1 = 'sound/weapons/female_toyattack.ogg'
	var/sound_attackF2 = 'sound/weapons/female_toyattack2.ogg'

	New()
		..()
		var/selected_color = pick("R","O","Y","G","C","B","P","Pi","W")
		if (prob(1))
			selected_color = null
		icon_state = "sword1-[selected_color]"
		item_state = "sword1-[selected_color]"

	attack(target as mob, mob/user as mob)
		..()
		if (ishuman(user))
			var/mob/living/carbon/human/U = user
			if (U.gender == MALE)
				playsound(get_turf(U), pick(sound_attackM1, sound_attackM2), 100, 0, 0, U.get_age_pitch())
			else
				playsound(get_turf(U), pick(sound_attackF1, sound_attackF2), 100, 0, 0, U.get_age_pitch())

/obj/item/toy/figure
	name = "collectable figure"
	desc = "<strong><span style=\"color:red\">WARNING:</span> CHOKING HAZARD</strong> - Small parts. Not for children under 3 years."
	icon = 'icons/obj/figures.dmi'
	icon_state = "fig-"
	w_class = 1.0
	throwforce = 1
	throw_speed = 4
	throw_range = 7
	stamina_damage = 1
	stamina_cost = 1
	stamina_crit_chance = 1
	//mat_changename = 0
	rand_pos = 1
	var/figure_info/info = null

	New(loc, var/figure_info/newInfo)
		..()
		if (istype(newInfo))
			info = new newInfo(src)
		else if (!istype(info))
			var/figure_info/randomInfo
			if (prob(10))
				randomInfo = pick(figure_high_rarity)
			else
				randomInfo = pick(figure_low_rarity)
			info = new randomInfo(src)
		name = "[info.name] figure"
		icon_state = "fig-[info.icon_state]"
		if (info.rare_varieties.len && prob(5))
			icon_state = "fig-[pick(info.rare_varieties)]"
		else if (info.varieties.len)
			icon_state = "fig-[pick(info.varieties)]"

		if (prob(1)) // rarely give a different material
			if (prob(1)) // VERY rarely give a super-fancy material
				var/list/rare_material_varieties = list("gold", "spacelag", "diamond", "ruby", "garnet", "topaz", "citrine", "peridot", "emerald", "jade", "aquamarine",
				"sapphire", "iolite", "amethyst", "alexandrite", "uqill", "uqillglass", "telecrystal", "miracle", "starstone", "flesh", "blob", "bone", "beeswax", "carbonfibre")
				setMaterial(getCachedMaterial(pick(rare_material_varieties)))
			else // silly basic "rare" varieties of things that should probably just be fancy paintjobs or plastics, but whoever made these things are idiots and just made them out of the actual stuff.  I guess.
				var/list/material_varieties = list("steel", "glass", "silver", "quartz", "rosequartz", "plasmaglass", "onyx", "jasper", "malachite", "lapislazuli")
				setMaterial(getCachedMaterial(pick(material_varieties)))

	suicide(var/mob/user as mob)
		user.visible_message("<span style=\"color:red\"><strong>[user] shoves [src] down their throat and chokes on it!</strong></span>")
		user.take_oxygen_deprivation(175)
		user.updatehealth()
		spawn (100)
			if (user)
				user.suiciding = 0
		qdel(src)
		return TRUE

	UpdateName()
		if (istype(info))
			name = "[name_prefix(null, 1)][info.name] figure[name_suffix(null, 1)]"
		else
			return ..()

var/list/figure_low_rarity = list(\
/figure_info/assistant,\
/figure_info/chef,\
/figure_info/chaplain,\
/figure_info/barman,\
/figure_info/botanist,\
/figure_info/janitor,\
/figure_info/doctor,\
/figure_info/geneticist,\
/figure_info/roboticist,\
/figure_info/scientist,\
/figure_info/security,\
/figure_info/detective,\
/figure_info/engineer,\
/figure_info/mechanic,\
/figure_info/miner,\
/figure_info/qm,\
/figure_info/monkey)

var/list/figure_high_rarity = list(\
/figure_info/captain,\
/figure_info/hos,\
/figure_info/hop,\
/figure_info/md,\
/figure_info/rd,\
/figure_info/ce,\
/figure_info/boxer,\
/figure_info/lawyer,\
/figure_info/barber,\
/figure_info/mailman,\
/figure_info/tourist,\
/figure_info/vice,\
/figure_info/clown,\
/figure_info/traitor,\
/figure_info/changeling,\
/figure_info/nukeop,\
/figure_info/wizard,\
/figure_info/wraith,\
/figure_info/cluwne,\
/figure_info/macho,\
/figure_info/cyborg,\
/figure_info/ai,\
/figure_info/blob,\
/figure_info/werewolf,\
/figure_info/omnitraitor,\
/figure_info/shitty_bill,\
/figure_info/don_glabs,\
/figure_info/father_jack,\
/figure_info/inspector,\
/figure_info/coach,\
/figure_info/sous_chef,\
/figure_info/waiter,\
/figure_info/apiarist,\
/figure_info/journalist,\
/figure_info/diplomat,\
/figure_info/musician,\
/figure_info/salesman,\
/figure_info/union_rep,\
/figure_info/vip,\
/figure_info/actor,\
/figure_info/regional_director,\
/figure_info/pharmacist,\
/figure_info/test_subject)

/figure_info
	var/name = "staff assistant"
	var/icon_state = "assistant"
	var/list/varieties = list() // basic versions that should always be picked between (ex: hos hat/hos beret)
	var/list/rare_varieties = list() // rare versions to be picked sometimes
	var/list/alt_names = list()

	New()
		..()
		if (alt_names.len)
			name = pick(alt_names)

	assistant
		rare_varieties = list("assistant2")

	chef
		name = "chef"
		icon_state = "chef"

	chaplain
		name = "chaplain"
		icon_state = "chaplain"

	barman
		name = "barman"
		icon_state = "barman"

	botanist
		name = "botanist"
		icon_state = "botanist"

	janitor
		name = "janitor"
		icon_state = "janitor"

	clown
		name = "clown"
		icon_state = "clown"

	boxer
		name = "boxer"
		icon_state = "boxer"

	lawyer
		name = "lawyer"
		icon_state = "lawyer"

	barber
		name = "barber"
		icon_state = "barber"

	mailman
		name = "mailman"
		icon_state = "mailman"

	atmos
		name = "atmos technician"
		icon_state = "atmos"

	tourist
		name = "tourist"
		icon_state = "tourist"

	vice
		name = "vice officer"
		icon_state = "vice"

	inspector
		name = "inspector"
		icon_state = "inspector"

	coach
		name = "coach"
		icon_state = "coach"

	sous_chef
		name = "sous-chef"
		icon_state = "sous"

	waiter
		name = "waiter"
		icon_state = "waiter"

	apiarist
		name = "apiarist"
		icon_state = "apiarist"
		alt_names = list("apiarist", "apiculturalist")

	journalist
		name = "journalist"
		icon_state = "journalist"

	diplomat
		name = "diplomat"
		icon_state = "diplomat"
		varieties = list("diplomat", "diplomat2", "diplomat3", "diplomat4")
		alt_names = list("diplomat", "ambassador")

	musician
		name = "musician"
		icon_state = "musician"

	salesman
		name = "salesman"
		icon_state = "salesman"
		alt_names = list("salesman", "merchant")

	union_rep
		name = "union rep"
		icon_state = "union"
		alt_names = list("union rep", "assistants union rep", "cyborgs union rep", "security union rep", "doctors union rep", "engineers union rep", "miners union rep")

	vip
		name = "\improper VIP"
		icon_state = "vip"
		alt_names = list("senator", "president", "\improper CEO", "board member", "mayor", "vice-president", "governor")

	actor
		name = "\improper Hollywood actor"
		icon_state = "actor"

	regional_director
		name = "regional director"
		icon_state = "regd"

	pharmacist
		name = "pharmacist"
		icon_state = "pharma"

	test_subject
		name = "test subject"
		icon_state = "testsub"

	doctor
		name = "medical doctor"
		icon_state = "doctor"

	geneticist
		name = "geneticist"
		icon_state = "geneticist"

	roboticist
		name = "roboticist"
		icon_state = "roboticist"

	scientist
		name = "scientist"
		icon_state = "scientist"
		varieties = list("scientist", "scientist2")

	security
		name = "security officer"
		icon_state = "security"

	detective
		name = "detective"
		icon_state = "detective"

	engineer
		name = "engineer"
		icon_state = "engineer"

	mechanic
		name = "mechanic"
		icon_state = "mechanic"

	miner
		name = "miner"
		icon_state = "miner"
		rare_varieties = list("miner2")

	qm
		name = "quartermaster"
		icon_state = "qm"

	captain
		name = "captain"
		icon_state = "captain"
		rare_varieties = list("captain2")//, "captain3")

	hos
		name = "head of security"
		icon_state = "hos"

	hop
		name = "head of personnel"
		icon_state = "hop"

	md
		name = "medical director"
		icon_state = "md"

	rd
		name = "research director"
		icon_state = "rd"

	ce
		name = "chief engineer"
		icon_state = "ce"

	cyborg
		name = "cyborg"
		icon_state = "borg"
		rare_varieties = list("borg2", "borg3")

	ai
		name = "\improper AI"
		icon_state = "ai"

	traitor
		name = "traitor"
		icon_state = "traitor"

	changeling
		name = "shambling abomination"
		icon_state = "changeling"

	vampire
		name = "vampire"
		icon_state = "vampire"

	nukeop
		name = "syndicate operative"
		icon_state = "nukeop"

	wizard
		name = "wizard"
		icon_state = "wizard"
		rare_varieties = list("wizard2", "wizard3")

	wraith
		name = "wraith"
		icon_state = "wraith"

	blob
		name = "blob"
		icon_state = "blob"

	werewolf
		name = "werewolf"
		icon_state = "werewolf"

	omnitraitor
		name = "omnitraitor"
		icon_state = "omnitraitor"

	cluwne
		name = "cluwne"
		icon_state = "cluwne"

	macho
		name = "macho man"
		icon_state = "macho"
		New()
			..()
			name = pick("\improper M", "m") + pick("a", "ah", "ae") + pick("ch", "tch", "tz") + pick("o", "oh", "oe") + " " + pick("M","m") + pick("a","ae","e") + pick("n","nn")

	monkey
		name = "monkey"
		icon_state = "monkey"

	shitty_bill
		name = "\improper Shitty Bill"
		icon_state = "bill"

	don_glabs
		name = "\improper Donald \"Don\" Glabs"
		icon_state = "don"

	father_jack
		name = "\improper Father Jack"
		icon_state = "jack"

/obj/item/item_box/figure_capsule
	name = "capsule"
	desc = "A little plastic ball for keeping stuff in. Woah! We're truly in the future with technology like this."
	icon = 'icons/obj/figures.dmi'
	icon_state = "cap-y"
	contained_item = /obj/item/toy/figure
	item_amount = 1
	max_item_amount = 1
	//reusable = 0
	rand_pos = 1
	var/ccolor = "y"
	var/image/cap_image = null

	New()
		..()
		ccolor = pick("y", "r", "g", "b")
		update_icon()

	update_icon()
		if (icon_state != "cap-[ccolor]")
			icon_state = "cap-[ccolor]"
		if (!cap_image)
			cap_image = image(icon, "cap-cap[item_amount ? 1 : 0]")
		if (open)
			if (item_amount)
				cap_image.icon_state = "cap-fig"
				UpdateOverlays(cap_image, "cap")
			else
				UpdateOverlays(null, "cap")
		else
			cap_image.icon_state = "cap-cap[item_amount ? 1 : 0]"
			UpdateOverlays(cap_image, "cap")

/obj/machinery/vending/capsule
	name = "capsule machine"
	desc = "A little figure in every capsule, guaranteed*!"
	pay = 1
	vend_delay = 15
	icon = 'icons/obj/figures.dmi'
	icon_state = "machine1"
	icon_panel = "machine-panel"
	var/sound_vend = 'sound/machines/capsulebuy.ogg'
	var/image/capsule_image = null

	New()
		..()
		//Products
		product_list += new/data/vending_product("/obj/item/item_box/figure_capsule", 26, cost=100)
		icon_state = "machine[rand(1,6)]"
		capsule_image = image(icon, "m_caps26")
		UpdateOverlays(capsule_image, "capsules")

	prevend_effect()
		playsound(loc, sound_vend, 80, 1)
		spawn (10)
			var/data/vending_product/R = product_list[1]
			capsule_image.icon_state = "m_caps[R.product_amount]"
			UpdateOverlays(capsule_image, "capsules")

	powered()
		return

	use_power()
		return

	power_change()
		return
