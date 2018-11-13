/targetable/predator/predator_gearspawn
	name = "Order hunting gear"
	desc = "Teleports hunting gear to your location."
	targeted = 0
	target_nodamage_check = 0
	max_range = 0
	cooldown = 0
	pointCost = 0
	when_stunned = 1
	not_when_handcuffed = 0
	predator_only = 0

	cast(mob/target)
		if (!holder)
			return TRUE

		var/mob/living/M = holder.owner

		if (!M || !ishuman(M))
			return TRUE

		actions.start(new/action/bar/private/icon/predator_transform(src), M)
		return FALSE

/action/bar/private/icon/predator_transform
	duration = 50
	interrupt_flags = INTERRUPT_MOVE | INTERRUPT_ACT | INTERRUPT_ACTION
	id = "predator_transform"
	icon = 'icons/mob/screen1.dmi'
	icon_state = "grabbed"
	var/targetable/predator/predator_gearspawn/transform

	New(Transform)
		transform = Transform
		..()

	onStart()
		..()

		var/mob/living/M = owner

		if (M == null || !ishuman(M) || M.stat != 0 || M.paralysis > 0 || !transform)
			interrupt(INTERRUPT_ALWAYS)
			return

		boutput(M, __red("<strong>Request acknowledged. You must stand still.</strong>"))

	onUpdate()
		..()

		var/mob/living/M = owner

		if (M == null || !ishuman(M) || M.stat != 0 || M.paralysis > 0 || !transform)
			interrupt(INTERRUPT_ALWAYS)
			return

	onEnd()
		..()

		var/mob/living/carbon/human/M = owner
		var/abilityHolder/H = transform.holder

		if (M.predator_transform() != 1)
			boutput(M, __red("Gearspawn failed. Make sure you're a human and try again later."))
		else
			H.removeAbility(/targetable/predator/predator_gearspawn)

	onInterrupt()
		..()

		var/mob/living/M = owner
		boutput(M, __red("You were interrupted!"))