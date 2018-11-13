/action/bar/icon/abominationDevour
	duration = 50
	interrupt_flags = INTERRUPT_MOVE | INTERRUPT_ACT | INTERRUPT_STUNNED | INTERRUPT_ACTION
	id = "abom_devour"
	icon = 'icons/mob/critter_ui.dmi'
	icon_state = "devour_over"
	var/mob/living/target
	var/targetable/changeling/devour/devour

	New(Target, Devour)
		target = Target
		devour = Devour
		..()

	onUpdate()
		..()

		if (get_dist(owner, target) > 1 || target == null || owner == null || !devour)
			interrupt(INTERRUPT_ALWAYS)
			return

		var/mob/ownerMob = owner
		var/obj/item/grab/G = ownerMob.equipped()

		if (!istype(G) || G.affecting != target || G.state < 1)
			interrupt(INTERRUPT_ALWAYS)
			return

	onStart()
		..()
		if (get_dist(owner, target) > 1 || target == null || owner == null || !devour)
			interrupt(INTERRUPT_ALWAYS)
			return

		var/mob/ownerMob = owner
		ownerMob.show_message("<span style=\"color:blue\">We must hold still for a moment...</span>", 1)

	onEnd()
		..()

		var/mob/ownerMob = owner
		if (owner && ownerMob && target && get_dist(owner, target) <= 1 && devour)
			var/abilityHolder/changeling/C = devour.holder
			if (istype(C))
				C.addDna(target)
			boutput(ownerMob, "<span style=\"color:blue\">We devour [target]!</span>")
			ownerMob.visible_message(text("<span style=\"color:red\"><strong>[ownerMob] hungrily devours [target]!</strong></span>"))
			playsound(ownerMob.loc, 'sound/misc/burp_alien.ogg', 50, 1)
			logTheThing("combat", ownerMob, target, "devours %target% as a changeling in horror form [log_loc(owner)].")

			target.ghostize()
			qdel(target)

	onInterrupt()
		..()
		boutput(owner, "<span style=\"color:red\">Our feasting on [target] has been interrupted!</span>")

/targetable/changeling/devour
	name = "Devour"
	desc = "Almost instantly devour a human for DNA."
	icon_state = "devour"
	abomination_only = 1
	cooldown = 0
	targeted = 0
	target_anything = 0
	restricted_area_check = 2

	cast(atom/target)
		if (..())
			return TRUE
		var/mob/living/C = holder.owner

		var/obj/item/grab/G = grab_check(null, 1, 1)
		if (!G || !istype(G))
			return TRUE
		var/mob/living/carbon/human/T = G.affecting

		if (!istype(T))
			boutput(C, "<span style=\"color:red\">This creature is not compatible with our biology.</span>")
			return TRUE
		if (istype(T.mutantrace, /mutantrace/monkey))
			boutput(C, "<span style=\"color:red\">Our hunger will not be satisfied by this lesser being.</span>")
			return TRUE
		if (T.bioHolder.HasEffect("husk"))
			boutput(usr, "<span style=\"color:red\">This creature has already been drained...</span>")
			return TRUE

		actions.start(new/action/bar/icon/abominationDevour(T, src), C)
		return FALSE

/action/bar/private/icon/changelingAbsorb
	duration = 250
	interrupt_flags = INTERRUPT_MOVE | INTERRUPT_ACT | INTERRUPT_STUNNED | INTERRUPT_ACTION
	id = "change_absorb"
	icon = 'icons/mob/critter_ui.dmi'
	icon_state = "devour_over"
	var/mob/living/target
	var/targetable/changeling/absorb/devour
	var/last_complete = 0

	New(Target, Devour)
		target = Target
		devour = Devour
		..()

	onUpdate()
		..()

		if (get_dist(owner, target) > 1 || target == null || owner == null || !devour || !devour.cooldowncheck())
			interrupt(INTERRUPT_ALWAYS)
			return

		var/mob/ownerMob = owner
		var/obj/item/grab/G = ownerMob.equipped()

		if (!istype(G) || G.affecting != target || G.state != 3)
			interrupt(INTERRUPT_ALWAYS)
			return

		var/done = world.time - started
		var/complete = max(min((done / duration), 1), 0)
		if (complete >= 0.2 && last_complete < 0.2)
			boutput(ownerMob, "<span style=\"color:blue\">We extend a proboscis.</span>")
			ownerMob.visible_message(text("<span style=\"color:red\"><strong>[ownerMob] extends a proboscis!</strong></span>"))

		if (complete > 0.6 && last_complete <= 0.6)
			boutput(ownerMob, "<span style=\"color:blue\">We stab [target] with the proboscis.</span>")
			ownerMob.visible_message(text("<span style=\"color:red\"><strong>[ownerMob] stabs [target] with the proboscis!</strong></span>"))
			boutput(target, "<span style=\"color:red\"><strong>You feel a sharp stabbing pain!</strong></span>")
			random_brute_damage(target, 40)

		last_complete = complete

	onStart()
		..()
		if (get_dist(owner, target) > 1 || target == null || owner == null || !devour || !devour.cooldowncheck())
			interrupt(INTERRUPT_ALWAYS)
			return

		var/mob/ownerMob = owner
		ownerMob.show_message("<span style=\"color:blue\">We must hold still...</span>", 1)

	onEnd()
		..()

		var/mob/ownerMob = owner
		if (owner && ownerMob && target && get_dist(owner, target) <= 1 && devour)
			var/abilityHolder/changeling/C = devour.holder
			if (istype(C))
				C.addDna(target)
			boutput(ownerMob, "<span style=\"color:blue\">We have absorbed [target]!</span>")
			ownerMob.visible_message(text("<span style=\"color:red\"><strong>[ownerMob] sucks the fluids out of [target]!</strong></span>"))
			logTheThing("combat", ownerMob, target, "absorbs %target% as a changeling [log_loc(owner)].")

			target.death(0)
			target.real_name = "Unknown"
			target.bioHolder.AddEffect("husk")

	onInterrupt()
		..()
		boutput(owner, "<span style=\"color:red\">Our absorbtion of [target] has been interrupted!</span>")

/targetable/changeling/absorb
	name = "Absorb DNA"
	desc = "Suck the DNA out of a target."
	icon_state = "absorb"
	human_only = 1
	cooldown = 0
	targeted = 0
	target_anything = 0
	restricted_area_check = 2

	cast(atom/target)
		if (..())
			return TRUE
		var/mob/living/C = holder.owner

		var/obj/item/grab/G = grab_check(null, 3, 1)
		if (!G || !istype(G))
			return TRUE
		var/mob/living/carbon/human/T = G.affecting

		if (!istype(T))
			boutput(C, "<span style=\"color:red\">This creature is not compatible with our biology.</span>")
			return TRUE
		if (istype(T.mutantrace, /mutantrace/monkey))
			boutput(C, "<span style=\"color:red\">Our hunger will not be satisfied by this lesser being.</span>")
			return TRUE
		if (T.bioHolder.HasEffect("husk"))
			boutput(usr, "<span style=\"color:red\">This creature has already been drained...</span>")
			return TRUE

		actions.start(new/action/bar/private/icon/changelingAbsorb(T, src), C)
		return FALSE