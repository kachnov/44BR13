/obj/item/resin
	var/amt = 1
	name = "piece of resin"
	icon_state = "resin" // placeholder
	
/obj/item/resin/New(_loc, _amt)
	..(_loc)
	amt = max(_amt, 1)
	
/obj/item/resin/proc/add(_amt)
	amt += _amt
	
/obj/item/resin/proc/consume(_amt)
	if (amt < _amt)
		if (!amt)
			qdel(src)
		return FALSE 
	amt -= _amt 
	if (!amt)
		if (ismob(loc))
			var/mob/M = loc 
			if (src == M.equipped())
				M.drop_item()
		qdel(src)
	return TRUE
	
/obj/item/resin/proc/can_consume(_amt)
	return amt >= _amt