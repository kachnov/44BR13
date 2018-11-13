// ------
// Tackle
// ------
/targetable/critter/tackle
	name = "Tackle"
	desc = "Tackle a mob, making them fall over."
	cooldown = 150
	targeted = 1
	target_anything = 1

	var/projectile/slam/proj = new

	cast(atom/target)
		if (..())
			return TRUE
		if (isobj(target))
			target = get_turf(target)
		if (isturf(target))
			target = locate(/mob/living) in target
			if (!target)
				boutput(holder.owner, __red("Nothing to tackle there."))
				return TRUE
		if (target == holder.owner)
			return TRUE
		if (get_dist(holder.owner, target) > 1)
			boutput(holder.owner, __red("That is too far away to tackle."))
			return TRUE
		playsound(get_turf(target), "sound/weapons/genhit1.ogg", 50, 1, -1)
		var/mob/MT = target
		MT.weakened += 3
		holder.owner.visible_message(__red("<strong>[holder.owner] tackles [MT]!</strong>"), __red("You tackle [MT]!"))
		return FALSE