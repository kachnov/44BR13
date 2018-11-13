// ----------------------------------
// Grow into a bigger form of critter
// ----------------------------------
/targetable/critter/grow
	name = "Grow"
	desc = "Use this to grow into a bigger, better, robuster form."
	var/newtype = null
	cooldown = 6000
	start_on_cooldown = 1

	cast(atom/target)
		if (..())
			return TRUE
		if (!newtype)
			return TRUE
		var/mob/ow = holder.owner
		if (!ow.mind && !ow.client)
			return TRUE
		var/mob/nw = new newtype(get_turf(ow))
		if (ow.mind)
			ow.mind.transfer_to(nw)
		else if (ow.client)
			var/client/cli = ow.client
			cli.mob = nw
			nw.mind = new /mind()
			ticker.minds += nw.mind
			nw.mind.key = cli.key
			nw.mind.current = nw
		boutput(nw, __blue("You grow into <strong>[nw]</strong>!"))
		qdel(ow)

//	spiderbaby	
//		newtype = /mob/living/critter/spider