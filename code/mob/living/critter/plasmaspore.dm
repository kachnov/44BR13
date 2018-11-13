/mob/living/critter/plasmaspore
	name = "plasma spore"
	real_name = "plasma spore"
	desc = "A barely intelligent colony of organisms. Very volatile."
	density = 1
	icon_state = "spore"
	custom_gib_handler = /proc/gibs
	hand_count = 0
	can_throw = 0
	blood_id = "plasma"

	death(var/gibbed)
		visible_message("<strong>[src]</strong> ruptures and explodes!")
		var/turf/T = get_turf(loc)
		if (T)
			T.hotspot_expose(700,125)
			explosion(src, T, -1, -1, 2, 3)
		ghostize()
		qdel(src)

	setup_healths()
		add_hh_flesh(-1, 1, 1)
		add_hh_flesh_burn(-1, 1, 1)