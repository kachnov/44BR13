/obj/item/genetics_injector
	name = "genetics injector"
	desc = "A special injector designed to interact with one's genetic structure."
	icon = 'icons/obj/syringe.dmi'
	inhand_image_icon = 'icons/mob/inhand/hand_medical.dmi'
	item_state = "syringe_0"
	icon_state = "b10"
	force = 3
	throwforce = 3
	var/uses = 1

	attack(mob/M as mob, mob/user as mob)
		if (!M || !user)
			return

		if (uses < 1)
			boutput(user, "<span style=\"color:red\">The injector is expended and has no more uses.</span>")
			return

		if (M == user)
			user.visible_message("<span style=\"color:red\"><strong>[user.name] injects [himself_or_herself(user)] with [src]!</strong></span>")
			injected(user,user)
		else
			actions.start(new/action/bar/icon/genetics_injector(M,src), user)

	proc/injected(var/mob/living/carbon/user,var/mob/living/carbon/target)
		if (!istype(user) || !istype(target))
			return TRUE
		if (!istype(target.bioHolder))
			return TRUE
		logTheThing("combat", user, target, "injects %target% with [name]")
		return FALSE

	proc/update_appearance()
		if (uses < 1)
			icon_state = "b0"
			desc = "A [src] that has been used up. It should be recycled or disposed of."
			name = "expended " + name

	dna_scrambler
		name = "dna scrambler"
		desc = "An illegal retroviral genetic serum designed to randomize the user's identity."

		injected(var/mob/living/carbon/user,var/mob/living/carbon/target)
			if (..())
				return
			if (ishuman(target))
				boutput(target, "<span style=\"color:red\">Your body changes! You feel completely different!</span>")
				randomize_look(target)
				uses--
				update_appearance()

	dna_injector
		name = "dna injector"
		desc = "A syringe designed to safely insert or remove genetic structures to and from a living organism."
		var/bioEffect/BE = null

		injected(var/mob/living/carbon/user,var/mob/living/carbon/target)
			if (..())
				return

			target.bioHolder.AddEffectInstance(BE,1)
			uses--
			update_appearance()

	dna_activator
		name = "dna activator"
		desc = "A syringe designed to safely stimulate a living organism's genes into activation."
		var/gene_to_activate = null
		var/expended_properly = 0

		injected(var/mob/living/carbon/user,var/mob/living/carbon/target)
			if (..())
				return

			var/bioEffect/BE
			for (var/X in target.bioHolder.effectPool)
				BE = target.bioHolder.effectPool[X]
				if (BE.id == gene_to_activate)
					target.bioHolder.ActivatePoolEffect(BE,overrideDNA = 1,grant_research = 0)
					if (!ismonkey(target))
						expended_properly = 1
					break
			uses--
			update_appearance()

		update_appearance()
			if (uses < 1)
				if (expended_properly)
					icon_state = "10"
					desc = "A [src] that has been filled with useful genetic information."
					name = "filled " + name
				else
					icon_state = "b0"
					desc = "A [src] that has been used up. It should be disposed of."
					name = "expended " + name

/action/bar/icon/genetics_injector
	duration = 20
	interrupt_flags = INTERRUPT_MOVE | INTERRUPT_ACT | INTERRUPT_STUNNED | INTERRUPT_ACTION
	id = "genetics_injector"
	icon = 'icons/obj/syringe.dmi'
	icon_state = "b10"
	var/mob/living/carbon/target = null
	var/obj/item/genetics_injector/injector = null

	New(Target,Injector)
		target = Target
		injector = Injector
		..()

	onUpdate()
		..()
		if (get_dist(owner, target) > 1 || target == null || owner == null || injector == null)
			interrupt(INTERRUPT_ALWAYS)
			return
		var/mob/living/ownerMob = owner
		if (ownerMob.r_hand != injector && ownerMob.l_hand != injector)
			interrupt(INTERRUPT_ALWAYS)
			return

	onStart()
		..()
		if (get_dist(owner, target) > 1 || target == null || owner == null || injector == null)
			interrupt(INTERRUPT_ALWAYS)
			return
		var/mob/living/ownerMob = owner
		if (ownerMob.r_hand != injector && ownerMob.l_hand != injector)
			interrupt(INTERRUPT_ALWAYS)
			return
		owner.visible_message("<span style=\"color:red\"><strong>[owner.name] begins to inject [target.name] with [injector]!</strong></span>")

	onEnd()
		..()
		owner.visible_message("<span style=\"color:red\"><strong>[owner.name] injects [target.name] with [injector].</strong></span>")
		injector.injected(owner,target)

// Traitor item
/obj/item/speed_injector
	name = "screwdriver"
	desc = "A hollow tool used to turn slotted screws and other slotted objects."
	icon = 'icons/obj/items.dmi'
	inhand_image_icon = 'icons/mob/inhand/hand_tools.dmi'
	icon_state = "screwdriver"
	flags = FPRINT | TABLEPASS | CONDUCT
	w_class = 0
	var/obj/item/genetics_injector/dna_injector/payload = null

	attack_self(var/mob/user as mob)
		if (istype(payload))
			boutput(user, "You unload [payload].")
			payload.set_loc(get_turf(user))
			payload = null
		return

	attackby(obj/item/W as obj, mob/user as mob)
		if (istype(W, /obj/item/genetics_injector/dna_injector))
			if (payload)
				boutput(user, "<span style=\"color:red\">The injector is already loaded.</span>")
				return
			var/obj/item/genetics_injector/dna_injector/DI = W
			if (!istype(DI.BE) || DI.uses < 1)
				boutput(user, "<span style=\"color:red\">The injector is rejecting [DI]. It mustn't be usable.</span>")
				return
			user.drop_item()
			DI.set_loc(src)
			payload = DI
			DI.BE.msgGain = ""
			DI.BE.msgLose = ""
			DI.BE.add_delay = 100
			boutput(user, "You slot [DI] into the injector.")
		else
			..()
		return

	attack(mob/M, mob/user as mob)
		if (!istype(M,/mob/living/carbon))
			return
		if (payload)
			boutput(user, "<span style=\"color:red\">You stab [M], injecting them.</span>")
			logTheThing("combat", user, M, "stabs %target% with the speed injector (<strong>Payload:</strong> [payload.name]).")
			payload.injected(user,M)
			qdel(payload)
			payload = null
		else
			boutput(user, "<span style=\"color:red\">You stab [M], but nothing happens.</span>")
		return