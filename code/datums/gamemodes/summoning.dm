/game_mode/summoning
	name = "summoning"
	config_tag = "summoning"

	var/bigbad_name = "Dagon" //Name of whatever TERRIBLE DEMON the cultists are trying to spawn
	var/cult_name = "The Order"
	var/list/cultists = list()
	var/list/cult_leaders = list()
	var/mind/sleeper = null //Sleeper agent.

	var/const/waittime_l = 600
	var/const/waittime_h = 1800

	var/const/cultists_max = 5 //Maximum possible number of cultists.

/game_mode/summoning/announce()
	boutput(world, "<strong>The current game mode is - Summoning!</strong>")
	boutput(world, "<strong>A group of nefarious SPACE CULTISTS are trying to summon their dark god into the station!  Stop them!!</strong>")

/game_mode/summoning/post_setup()

	bigbad_name = make_bigbad_name()
	cult_name = make_cult_name()
	return

/game_mode/summoning/proc/equip_cultist(mob/living/carbon/human/cult_mob, leader=0)
	if (!istype(cult_mob))
		return

	//to-do
	if (leader)
		boutput(cult_mob, "<span style=\"color:red\"><strong>You are a leading cultist of [cult_name]!</strong></span>")

	else
		boutput(cult_mob, "<span style=\"color:red\"><strong>You are a loyal cultist of [cult_name]!</strong></span>")
	cult_mob.equip_if_possible(new /obj/item/clothing/suit/cultist(cult_mob), cult_mob.slot_in_backpack)
	return

//Can man name a terror he cannot even comprehend??
//I dunno but this proc sure can
/game_mode/summoning/proc/make_bigbad_name()
	var/list/beginnings = list("Slaa","Kho","Cthu","Vhui","Vorg","Nur","Shub",
								"Aza","Nyar","Dag","Yog","Tze","Mal","Xei","Emn","Staunt")
	var/list/middles = list("-","cor","us","ean","prot","el","e","u","mog","hul")
	var/list/endings = list("rne","gle","rath","reth","nesh","on","thoth","al","tross",
							"neith","nath","bennar","zheri","waufell","nek","voss")

	var/hyphen_flag = 0
	var/genname = pick(beginnings)
	if (prob(25))
		var/middle = pick(middles)
		genname += middle
		if (middle == "-")
			hyphen_flag = 1

	var/the_end = pick(endings)
	if (hyphen_flag)
		the_end = capitalize(the_end)

	genname += the_end
	if (prob(4))
		var/title = pick("Papa ","Mother ","Lord ","Creepy Uncle ")
		genname = title + genname
	boutput(world, "the name: \"[genname]\"")

	return genname

//Who worships this thing??
/game_mode/summoning/proc/make_cult_name()
	var/list/ordertypes = list("Order","Legion","Fellowship","Brotherhood","Triumvirate",
						"Church","Assortment","Grouping","Committee","Foundation","Agglutination",
						"Congress")
	var/list/orderadjs = list("Blissful","Delicious","Hated","Burning","Melodious",
							"Vile","Extensive","Overwhelming","Odious","Unseen",
							"Vicious","Viscous","Merciful","Delighted","Magnificent","Eldritch",
							"Forgotten","Non-Euclidean","Divine","Sacrosanct","Paleogean")
	var/list/ordersubs = list("Agonies","Apostasy","Invocations","Desperation",
							"Discoveries","Realisation","Ruination","Heresies",
							"Desolation","Vigintillion")

	var/cultname = "The [pick(ordertypes)] of [pick(orderadjs)] [pick(ordersubs)]"

	boutput(world, "cult: \"[cultname]\"")
	return cultname