/obj/item/artifact/forcewall_wand
	name = "artifact forcewall wand"
	icon = 'icons/obj/artifacts/artifactsitem.dmi'
	artifact = 1
	associated_datum = /artifact/wallwand
	module_research_no_diminish = 1

	afterattack(atom/target, mob/user , flag)
		if (!ArtifactSanityCheck())
			return
		var/artifact/A = artifact
		if (A.activated)
			var/turf/T = get_turf(target)
			A.effect_click_tile(src,user,T)
			ArtifactFaultUsed(user)

/artifact/wallwand
	associated_object = /obj/item/artifact/forcewall_wand
	rarity_class = 2
	validtypes = list("ancient","wizard","eldritch","precursor")
	react_xray = list(10,60,92,11,"COMPLEX")
	var/wall_duration = 5
	var/wall_size = 1
	var/icon_state = "shieldsparkles"
	var/sound/wand_sound = 'sound/effects/mag_forcewall.ogg'
	examine_hint = "It seems to have a handle you're supposed to hold it by."
	module_research = list("energy" = 10, "weapons" = 3, "miniaturization" = 5, "engineering" = 3, "tools" = 3)
	module_research_insight = 3

	New()
		..()
		wall_duration = rand(3,30)
		wall_size = rand(1,4)
		if (prob(10))
			wall_size += rand(3,6)
		if (prob(5))
			wall_duration *= rand(2,5)
		icon_state = pick("shieldsparkles","empdisable","greenglow","enshield","energyorb","forcewall","meteor_shield")
		wand_sound = pick('sound/effects/mag_forcewall.ogg','sound/effects/mag_golem.ogg','sound/effects/mag_iceburstlaunch.ogg','sound/effects/bamf.ogg','sound/weapons/ACgun2.ogg')

	effect_click_tile(var/obj/O,var/mob/living/user,var/turf/T)
		if (..())
			return
		if (!T)
			return
		var/wallloc
		playsound(user.loc, wand_sound, 50, 1, -1)
		if (user.dir == NORTH || user.dir == SOUTH)
			for (wallloc = T.x - (wall_size - 1),wallloc < T.x + wall_size,wallloc++)
				var/obj/forcefield/wand/FW = new /obj/forcefield/wand(locate(wallloc,T.y,T.z),wall_duration,icon_state)
				FW.icon_state = icon_state
		else
			for (wallloc = T.y - (wall_size - 1),wallloc < T.y + wall_size,wallloc++)
				var/obj/forcefield/wand/FW = new /obj/forcefield/wand(locate(T.x,wallloc,T.z),wall_duration,icon_state)
				FW.icon_state = icon_state

/obj/forcefield/wand
	name = "force field"
	icon = 'icons/effects/effects.dmi'
	icon_state = "shieldsparkles"
	desc = "Some kind of strange energy barrier. You can't get past it."
	New(var/loc,var/duration,var/wallsprite)
		icon_state = wallsprite
		if (duration > 0)
			spawn (duration * 10)
				qdel(src)