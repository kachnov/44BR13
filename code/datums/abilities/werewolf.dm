// Converted everything related to werewolves from client procs to ability holders and used
// the opportunity to do some clean-up as well (Convair880).

//////////////////////////////////////////// Setup //////////////////////////////////////////////////

/mob/proc/make_werewolf()
	if (ishuman(src))
		var/abilityHolder/werewolf/A = get_ability_holder(/abilityHolder/werewolf)
		if (A && istype(A))
			return

		var/abilityHolder/werewolf/W = add_ability_holder(/abilityHolder/werewolf)
		W.addAbility(/targetable/werewolf/werewolf_transform)
		W.addAbility(/targetable/werewolf/werewolf_feast)

		resistances += /ailment/disease/lycanthropy

		if (mind && mind.special_role != "omnitraitor")
			src << browse(grabResource("html/traitorTips/werewolfTips.html"),"window=antagTips;titlebar=1;size=600x400;can_minimize=0;can_resize=0")

	else return

////////////////////////////////////////////// Helper procs //////////////////////////////

// Avoids C&P code for that werewolf disease.
/mob/proc/werewolf_transform(var/source_is_lycanthrophy = 0, var/message_type = 0)
	if (ishuman(src))
		var/mob/living/carbon/human/M = src
		var/which_way = 0

		if (!M.mutantrace || source_is_lycanthrophy == 1)
			M.jitteriness = 0
			M.stunned = 0
			M.weakened = 0
			M.paralysis = 0
			M.slowed = 0
			M.change_misstep_chance(-INFINITY)
			M.stuttering = 0
			M.drowsyness = 0

			if (M.handcuffed)
				M.visible_message("<span style=\"color:red\"><strong>[M] rips apart the handcuffs with pure brute strength!</strong></span>")
				qdel(M.handcuffed)
				M.handcuffed = null
			M.buckled = null

			playsound(M.loc, 'sound/effects/blobattack.ogg', 50, 1, -1)
			spawn (5)
				if (M && M.mutantrace && istype(M.mutantrace, /mutantrace/werewolf))
					M.emote("howl")

			M.visible_message("<span style=\"color:red\"><strong>[M] [pick("metamorphizes", "transforms", "changes")] into a werewolf! Holy shit!</strong></span>")
			if (message_type == 0)
				boutput(M, __blue("<h3>You are now a werewolf.</h3>"))
			else
				boutput(M, __blue("<h3>You are now a werewolf. You can remain in this form indefinitely or change back at any time.</h3>"))

			if (source_is_lycanthrophy == 1 && M.mutantrace)
				qdel(M.mutantrace)
			M.set_mutantrace(/mutantrace/werewolf)
			M.set_face_icon_dirty()
			M.set_body_icon_dirty()
			M.update_clothing()

			which_way = 0

		else
			if (source_is_lycanthrophy == 1) // Werewolf disease is human -> WW only.
				return

			boutput(M, __blue("<h3>You transform back into your human form.</h3>"))

			qdel(M.mutantrace)
			M.set_face_icon_dirty()
			M.set_body_icon_dirty()
			M.update_clothing()

			which_way = 1

		logTheThing("combat", M, null, "[which_way == 0 ? "transforms into a werewolf" : "changes back into human form"] at [log_loc(M)].")
		return

// There used to be more stuff here, most of which was moved to limb datums.
/mob/proc/werewolf_attack(var/mob/target = null, var/attack_type = "")
	if (!iswerewolf(src))
		return FALSE

	var/mob/living/carbon/human/M = src
	if (!ishuman(M))
		return FALSE

	if (!target || !ismob(target))
		return FALSE

	if (target == M)
		return FALSE

	if (check_target_immunity(target) == 1)
		target.visible_message("<span style=\"color:red\"><strong>[M]'s swipe bounces off of [target] uselessly!</strong></span>")
		return FALSE

	var/damage = 0
	var/send_flying = 0 // 1: a little bit | 2: across the room

	switch (attack_type)
		if ("feast") // Only used by the feast ability.
			var/mob/living/carbon/human/HH = target

			if (!HH || !ishuman(HH))
				return FALSE

			var/healing = 0

			if (!HH.canmove)
				damage += rand(5,15)
				healing = damage - 5

				if (prob(40))
					HH.spread_blood_clothes(HH)
					M.spread_blood_hands(HH)

					var/obj/decal/cleanable/blood/gibs/G = null // For forensics.
					G = new /obj/decal/cleanable/blood/gibs(HH.loc)
					if (HH.bioHolder && HH.bioHolder.Uid && HH.bioHolder.bloodType)
						G.blood_DNA = HH.bioHolder.Uid
						G.blood_type = HH.bioHolder.bloodType

					M.visible_message("<span style=\"color:red\"><strong>[M] messily [pick("rips", "tears")] out and [pick("eats", "devours", "wolfs down", "chows on")] some of [HH]'s [pick("guts", "intestines", "entrails")]!</strong></span>")

				else
					HH.spread_blood_clothes(HH)

					M.visible_message("<span style=\"color:red\"><strong>[M] [pick("chomps on", "chews off a chunk of", "gnaws on")] [HH]'s [pick("right arm", "left arm", "head", "right leg", "left leg")]!</strong></span>")

				if (ismonkey(HH) || HH.bioHolder && HH.bioHolder.HasEffect("monkey"))
					boutput(M, __red("Monkey flesh just isn't the real deal..."))
					healing /= 2
				else if (HH.stat == 2)
					boutput(M, __red("Fresh meat would be much preferable to this cadaver..."))
					healing /= 2
				else if (HH.health < -150)
					boutput(M, __red("[target] is pretty mangled. There's not a lot of flesh left..."))
					healing /= 1.5
				else
					if (iscluwne(HH))
						boutput(M, __red("That tasted awful!"))
						healing /= 2
						M.take_toxin_damage(5)
					else if (iswerewolf(HH) || ispredator(HH) || isabomination(HH))
						boutput(M, __blue("That tasted fantastic!"))
						healing *= 2
					else if (HH.nutrition > 100 || HH.bioHolder && HH.bioHolder.HasEffect("fat"))
						boutput(M, __blue("That tasted amazing!"))
						M.unlock_medal("Space Ham", 1)
						healing *= 2
					else if (HH.mind && HH.mind.assigned_role == "Clown")
						boutput(M, __blue("That tasted funny, huh."))
						M.unlock_medal("That tasted funny", 1)
					else
						boutput(M, __blue("That tasted good!"))

				HH.add_fingerprint(M) // Just put 'em on the mob itself, like pulling does. Simplifies forensic analysis a bit.
				M.werewolf_audio_effects(HH, "feast")

				HH.weakened = max(HH.weakened, rand(3,6))
				if (prob(33) && HH.stat != 2)
					HH.emote("scream")

				M.remove_stamina(60) // Werewolves have a very large stamina and stamina regen boost.
				if (healing > 0)
					M.HealDamage("All", healing, healing)
					M.updatehealth()

			else // Can't feast on people if they're moving around too much.
				return FALSE
		else
			return FALSE

	switch (send_flying)
		if (1)
			wrestler_knockdown(M, target)

		if (2)
			wrestler_backfist(M, target)

	if (damage > 0)
		random_brute_damage(target, damage)
		target.updatehealth()
		target.UpdateDamageIcon()
		target.set_clothing_icon_dirty()

	return TRUE

// Also called by limb datums.
/mob/proc/werewolf_audio_effects(var/mob/target = null, var/type = "disarm")
	if (!src || !ismob(src) || !target || !ismob(target))
		return

	var/sound_playing = 0

	switch (type)
		if ("disarm")
			playsound(loc, pick('sound/misc/werewolf_attack1.ogg', 'sound/misc/werewolf_attack2.ogg', 'sound/misc/werewolf_attack3.ogg'), 50, 1)
			spawn (1)
				if (src) playsound(loc, "swing_hit", 50, 1)

		if ("swipe")
			if (prob(50))
				playsound(loc, pick('sound/misc/werewolf_attack1.ogg', 'sound/misc/werewolf_attack2.ogg', 'sound/misc/werewolf_attack3.ogg'), 50, 1)
			else
				playsound(loc, pick('sound/misc/loudcrunch.ogg', 'sound/misc/loudcrunch2.ogg'), 50, 1, -1)

			spawn (1)
				if (src) playsound(loc, "sound/weapons/DSCLAW.ogg", 40, 1, -1)

		if ("feast")
			if (sound_playing == 0) // It's a long audio clip.
				playsound(loc, "sound/misc/wendigo_maul.ogg", 80, 1)
				sound_playing = 1
				spawn (60)
					sound_playing = 0

			playsound(loc, pick('sound/misc/loudcrunch.ogg', 'sound/misc/loudcrunch2.ogg'), 50, 1, -1)
			playsound(loc, "sound/items/eatfood.ogg", 50, 1, -1)
			if (prob(40))
				playsound(target.loc, "sound/effects/splat.ogg", 50, 1)
			spawn (10)
				if (src && ishuman(src) && prob(50))
					emote("burp")

	return

//////////////////////////////////////////// Ability holder /////////////////////////////////////////

/obj/screen/ability/werewolf
	clicked(params)
		var/targetable/werewolf/spell = owner
		if (!istype(spell))
			return
		if (!spell.holder)
			return
		if (!isturf(owner.holder.owner.loc))
			boutput(owner.holder.owner, "<span style=\"color:red\">You can't use this ability here.</span>")
			return
		if (spell.targeted && usr:targeting_spell == owner)
			usr:targeting_spell = null
			usr.update_cursor()
			return
		if (spell.targeted)
			if (world.time < spell.last_cast)
				return
			owner.holder.owner.targeting_spell = owner
			owner.holder.owner.update_cursor()
		else
			spawn
				spell.handleCast()
		return

/abilityHolder/werewolf
	usesPoints = 0
	regenRate = 0
	tabName = "Werewolf"
	notEnoughPointsMessage = "<span style=\"color:red\">You aren't strong enough to use this ability.</span>"
	var/objective/specialist/werewolf/feed/feed_objective = null

	onAbilityStat() // In the 'Werewolf' tab.
		..()

		if (owner.mind && owner.mind.special_role == "werewolf")
			for (var/objective/specialist/werewolf/feed/O in owner.mind.objectives)
				feed_objective = O

			if (feed_objective && istype(feed_objective))
				stat("No. of victims:", feed_objective.feed_count)

		return

/////////////////////////////////////////////// Werewolf spell parent ////////////////////////////

/targetable/werewolf
	icon = 'icons/mob/critter_ui.dmi'
	icon_state = "template"  // No custom sprites yet.
	cooldown = 0
	last_cast = 0
	pointCost = 0
	preferred_holder_type = /abilityHolder/werewolf
	var/when_stunned = 0 // 0: Never | 1: Ignore mob.stunned and mob.weakened | 2: Ignore all incapacitation vars
	var/not_when_handcuffed = 0
	var/werewolf_only = 0

	New()
		var/obj/screen/ability/werewolf/B = new /obj/screen/ability/werewolf(null)
		B.icon = icon
		B.icon_state = icon_state
		B.owner = src
		B.name = name
		B.desc = desc
		object = B
		return

	updateObject()
		..()
		if (!object)
			object = new /obj/screen/ability/werewolf()
			object.icon = icon
			object.owner = src
		if (last_cast > world.time)
			var/pttxt = ""
			if (pointCost)
				pttxt = " \[[pointCost]\]"
			object.name = "[name][pttxt] ([round((last_cast-world.time)/10)])"
			object.icon_state = icon_state + "_cd"
		else
			var/pttxt = ""
			if (pointCost)
				pttxt = " \[[pointCost]\]"
			object.name = "[name][pttxt]"
			object.icon_state = icon_state
		return

	proc/incapacitation_check(var/stunned_only_is_okay = 0)
		if (!holder)
			return FALSE

		var/mob/living/M = holder.owner
		if (!M || !ismob(M))
			return FALSE

		switch (stunned_only_is_okay)
			if (0)
				if (M.stat != 0 || M.stunned > 0 || M.paralysis > 0 || M.weakened > 0)
					return FALSE
				else
					return TRUE
			if (1)
				if (M.stat != 0 || M.paralysis > 0)
					return FALSE
				else
					return TRUE
			else
				return TRUE

	castcheck()
		if (!holder)
			return FALSE

		var/mob/living/carbon/human/M = holder.owner

		if (!M)
			return FALSE

		if (!ishuman(M)) // Only humans use mutantrace datums.
			boutput(M, __red("You cannot use any powers in your current form."))
			return FALSE

		if (M.transforming)
			boutput(M, __red("You can't use any powers right now."))
			return FALSE

		if (werewolf_only == 1 && !iswerewolf(M))
			boutput(M, __red("You must be in your wolf form to use this ability."))
			return FALSE

		if (incapacitation_check(when_stunned) != 1)
			boutput(M, __red("You can't use this ability while incapacitated!"))
			return FALSE

		if (not_when_handcuffed == 1 && M.restrained())
			boutput(M, __red("You can't use this ability when restrained!"))
			return FALSE

		return TRUE

	cast(atom/target)
		. = ..()
		actions.interrupt(holder.owner, INTERRUPT_ACT)
		return