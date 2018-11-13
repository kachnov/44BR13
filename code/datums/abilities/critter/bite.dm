// -----------------
// Simple bite skill
// -----------------
/targetable/critter/bite
	name = "Chomp"
	desc = "Chomp down on a mob, causing damage and a short stun."
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
				boutput(holder.owner, __red("Nothing to bite there."))
				return TRUE
		if (target == holder.owner)
			return TRUE
		if (get_dist(holder.owner, target) > 1)
			boutput(holder.owner, __red("That is too far away to bite."))
			return TRUE
		playsound(target, "sound/weapons/werewolf_attack1.ogg", 50, 1, -1)
		var/mob/MT = target
		MT.TakeDamage("All", 16, 0, 0, DAMAGE_CRUSH)
		MT.stunned += 2
		holder.owner.visible_message(__red("<strong>[holder.owner] bites [MT]!</strong>"), __red("You bite [MT]!"))
		return FALSE