
/////////////////////////////////////////////
//////// Attach a steam trail to an object (eg. a reacting beaker) that will follow it
// even if it's carried of thrown.
/////////////////////////////////////////////

/effects/system/steam_trail_follow
	var/atom/holder
	var/turf/oldposition
	var/processing = 1
	var/on = 1
	var/number

/effects/system/steam_trail_follow/proc/set_up(atom/atom)
	holder = atom
	oldposition = get_turf(atom)

/effects/system/steam_trail_follow/proc/start()
	if (!on)
		on = 1
		processing = 1
	if (processing)
		processing = 0
		spawn (0)
			if (number < 3)
				var/obj/effects/steam/I = unpool(/obj/effects/steam)
				I.set_loc(oldposition)
				number++
				oldposition = get_turf(holder)
				I.dir = holder.dir
				spawn (10)
					if (I && !I.disposed) pool(I)
					number--
				spawn (2)
					if (on)
						processing = 1
						start()
			else
				spawn (2)
					if (on)
						processing = 1
						start()

/effects/system/steam_trail_follow/proc/stop()
	processing = 0
	on = 0