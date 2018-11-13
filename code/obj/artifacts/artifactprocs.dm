// Artifact Infrastructure Procs

/obj/landmark/artifact
	name = "artifact spawner"
	icon = 'icons/mob/screen1.dmi'
	icon_state = "x3"
	anchored = 1.0
	var/spawnchance = 100 // prob chance out of 100 to spawn artifact at game start
	var/spawnpath = null  // if you want a landmark to spawn a specific artifact rather than a random one

/obj/landmark/artifact/seed
	name = "artifact seed spawner"
	spawnpath = /obj/item/seed/alien

/obj/landmark/artifact/cannabis_seed
	name = "cannabis seed spawner"
	spawnpath = /obj/item/seed/cannabis
	// not actually an artifact but eh seeds are behaving oddly

/proc/Artifact_spawn (var/atom/T,var/forceartitype)
	if (!T)
		return
	if (!istype(T,/turf/) && !istype(T,/obj))
		return

	var/rarityroll = 1

	switch(rand(1,100))
		if (63 to 88)
			rarityroll = 2
			// 1 in 25
		if (89 to 99)
			rarityroll = 3
			// 1 in 10
		if (100)
			rarityroll = 4
			// 1 in 100
		else
			rarityroll = 1
			// 1 in 62

	var/list/selection_pool = list()

	for (var/artifact/A in artifact_controls.artifact_types)
		if (A.rarity_class != rarityroll)
			continue
		if (istext(forceartitype) && !forceartitype in A.validtypes)
			continue
		selection_pool += A

	if (selection_pool.len < 1)
		return

	var/artifact/picked = pick(selection_pool)
	if (!istype(picked,/artifact))
		return

	if (istext(forceartitype))
		new picked.associated_object(T,forceartitype)
	else
		new picked.associated_object(T)

/obj/proc/ArtifactSanityCheck()
	// This proc is called in any other proc or thing that uses the new artifact shit. If there was an improper artifact variable
	// involved when trying to do the new shit, it would probably spew errors fucking everywhere and generally be horrible so if
	// the sanity check detects that an artifact doesn't have the proper shit set up it'll just wipe out the artifact and stop
	// the rest of the proc from occurring.
	// This proc should be called in an if statement at the start of every artifact proc, since it returns 0 or 1.
	if (!artifact)
		return FALSE
	// if the artifact var isn't set at all, it's probably not an artifact so don't bother continuing
	if (!istype(artifact,/artifact))
		logTheThing("debug", null, null, "<strong>I Said No/Artifact:</strong> Invalid artifact variable in [type] at [showCoords(x, y, z)]")
		qdel(src) // wipes itself out since if it's processing it'd be calling procs it can't use again and again
		return FALSE // uh oh, we've got a poorly set up artifact and now we need to stop the proc that called it!
	else
		return TRUE // give the all clear

/obj/proc/ArtifactSetup()
	// This proc gets called in every artifact's New() proc, after artifact is turned from a 1 into its appropriate datum.
	//It scrambles the name and appearance of the artifact so we can't tell what it is on sight or cursory examination.
	// Could potentially go in /obj/New(), but...
	if (!ArtifactSanityCheck())
		return
	var/artifact/A = artifact
	A.holder = src

	var/artifact_origin/AO = artifact_controls.get_origin_from_string(pick(A.validtypes))
	if (!istype(AO,/artifact_origin))
		qdel(src)
		return
	A.artitype = AO
	// Refers to the artifact datum's list of origins it's allowed to be from and selects one at random. This way we can avoid
	// stuff that doesn't make sense like ancient robot plant seeds or eldritch healing devices

	var/artifact_origin/appearance = artifact_controls.get_origin_from_string(AO.name)
	if (prob(A.scramblechance))
		appearance = null
	// rare-ish chance of an artifact appearing to be a different origin, just to throw things off

	if (!istype(appearance,/artifact_origin))
		var/list/all_origin_names = list()
		for (var/artifact_origin/O in artifact_controls.artifact_origins)
			all_origin_names += O.name
		appearance = artifact_controls.get_origin_from_string(pick(all_origin_names))

	var/name1 = pick(appearance.adjectives)
	var/name2 = "thingy"
	if (istype(src,/obj/item))
		name2 = pick(appearance.nouns_small)
	else
		name2 = pick(appearance.nouns_large)

	name = "[name1] [name2]"
	src:real_name = "[name1] [name2]"
	desc = "You have no idea what this thing is!"
	A.touch_descriptors |= appearance.touch_descriptors

	icon_state = appearance.name + "-[rand(1,appearance.max_sprites)]"
	if (istype(src,/obj/item))
		var/obj/item/I = src
		I.item_state = appearance.name

	A.fx_image = image(icon, icon_state + "fx")
	A.fx_image.color = rgb(rand(AO.fx_red_min,AO.fx_red_max),rand(AO.fx_green_min,AO.fx_green_max),rand(AO.fx_blue_min,AO.fx_blue_max))

	A.react_mpct[1] = AO.impact_reaction_one
	A.react_mpct[2] = AO.impact_reaction_two
	A.react_heat[1] = AO.heat_reaction_one
	A.activ_sound = pick(AO.activation_sounds)
	A.fault_types |= AO.fault_types
	A.internal_name = AO.generate_name()

	ArtifactDevelopFault(10)

	if (A.automatic_activation)
		ArtifactActivated()
	else
		var/list/valid_triggers = A.validtriggers
		var/trigger_amount = rand(A.min_triggers,A.max_triggers)
		var/selection = null
		while (trigger_amount > 0)
			trigger_amount--
			selection = pick(valid_triggers)
			if (ispath(selection))
				var/artifact_trigger/AT = new selection
				A.triggers += AT
				valid_triggers -= selection

	artifact_controls.artifacts += src
	A.post_setup()

/obj/proc/ArtifactActivated()
	if (!src)
		return
	if (!ArtifactSanityCheck())
		return TRUE
	var/artifact/A = artifact
	if (A.activated)
		return TRUE
	if (A.triggers.len < 1 && !A.automatic_activation)
		return TRUE // can't activate these ones at all by design
	if (!A.may_activate(src))
		return TRUE
	if (A.activ_sound)
		playsound(loc, A.activ_sound, 100, 1)
	if (A.activ_text)
		var/turf/T = get_turf(src)
		T.visible_message("<strong>[src] [A.activ_text]</strong>")
	A.activated = 1
	overlays += A.fx_image
	A.effect_activate(src)

/obj/proc/ArtifactDeactivated()
	if (!ArtifactSanityCheck())
		return
	var/artifact/A = artifact
	if (A.deact_sound)
		playsound(loc, A.deact_sound, 100, 1)
	if (A.deact_text)
		var/turf/T = get_turf(src)
		T.visible_message("<strong>[src] [A.deact_text]</strong>")
	A.activated = 0
	overlays = null
	A.effect_deactivate(src)

/obj/proc/Artifact_attackby(obj/item/W as obj, mob/user as mob)
	if (istype(W, /obj/item/cargotele)) // Re-added (Convair880).
		var/obj/item/cargotele/CT = W
		CT.cargoteleport(src, user)
		return

	if (istype(user,/mob/living/silicon/robot))
		ArtifactStimulus("silitouch", 1)

	if (istype(W,/obj/item/artifact/activator_key))
		var/obj/item/artifact/activator_key/ACT = W
		if (!ArtifactSanityCheck())
			return
		if (!W.ArtifactSanityCheck())
			return
		var/artifact/A = artifact
		var/artifact/K = ACT.artifact

		if (K.activated)
			if (ACT.universal || A.artitype == K.artitype)
				if (ACT.activator && !A.activated)
					ArtifactActivated()
				else if (!ACT.activator && A.activated)
					ArtifactDeactivated()
				else
					..()

	if (istype(W,/obj/item/weldingtool))
		var/obj/item/weldingtool/WELD = W
		if (WELD.welding)
			WELD.eyecheck(user)
			ArtifactStimulus("heat", 800)
			playsound(loc, "sound/items/Welder.ogg", 100, 1)
			visible_message("<span style=\"color:red\">[user.name] burns the artifact with [WELD]!</span>")
			return FALSE

	if (istype(W,/obj/item/zippo))
		var/obj/item/zippo/ZIP = W
		if (ZIP.lit)
			ArtifactStimulus("heat", 400)
			visible_message("<span style=\"color:red\">[user.name] burns the artifact with [ZIP]!</span>")
			return FALSE

	if (istype(W,/obj/item/baton))
		var/obj/item/baton/BAT = W
		if (BAT.can_stun(1, 1, user) == 1)
			ArtifactStimulus("force", BAT.force)
			ArtifactStimulus("elec", 1500)
			playsound(loc, "sound/weapons/Egloves.ogg", 100, 1)
			visible_message("<span style=\"color:red\">[user.name] beats the artifact with [BAT]!</span>")
			BAT.process_charges(-1, user)
			return FALSE

	if (W.force)
		ArtifactStimulus("force", W.force)
	return TRUE

/obj/proc/ArtifactFaultUsed(var/mob/user)
	// This is for a tool/item artifact that you can use. If it has a fault, whoever is using it is basically rolling the dice
	// every time the thing is used (a check to see if rand(1,faultcount) hits 1 most of the time) and if they're unlucky, the
	// thing will deliver it's payload onto them.
	// There's also no reason this can't be used whoever the artifact is being used *ON*, also!
	if (!ArtifactSanityCheck())
		return

	var/artifact/A = artifact

	if (!A.faults.len)
		return // no faults, so dont waste any more time
	if (!A.activated)
		return // doesn't make a lot of sense for an inert artifact to go haywire
	var/halt = 0
	for (var/artifact_fault/F in A.faults)
		if (prob(F.trigger_prob))
			if (F.halt_loop)
				halt = 1
			F.deploy(src,user)
		if (halt)
			break

/obj/proc/ArtifactStimulus(var/stimtype, var/strength = 0)
	// This is what will be used for most of the testing equipment stuff. Stimtype is what kind of stimulus the artifact is being
	// exposed to (such as brute force, high temperatures, electricity, etc) and strength is how powerful the stimulus is. This
	// one here is intended as a master proc with individual items calling back to this one and then rolling their own version of
	// it alongside this. This one mainly deals with accidentally damaging an artifact due to hitting it with a poor choice of
	// stimulus, such as hitting crystals with brute force and so forth.
	if (!stimtype)
		return
	if (!ArtifactSanityCheck())
		return
	var/turf/T = get_turf(src)

	var/artifact/A = artifact

	// Possible stimuli = force, elec, radiate, heat
	switch(A.artitype)
		if ("martian") // biotech, so anything that'd probably kill a living thing works on them too
			if (stimtype == "force")
				if (strength >= 30)
					T.visible_message("<span style=\"color:red\">[src] bruises from the impact!</span>")
					playsound(loc, "sound/effects/attackblob.ogg", 100, 1)
					ArtifactDevelopFault(33)
					ArtifactTakeDamage(strength / 1.5)
			if (stimtype == "elec")
				if (strength >= 3000) // max you can get from the electrobox is 5000
					if (prob(10))
						T.visible_message("<span style=\"color:red\">[src] seems to quiver in pain!</span>")
					ArtifactTakeDamage(strength / 1000)
			if (stimtype == "radiate")
				if (strength >= 6)
					ArtifactDevelopFault(50)
					if (strength >= 9)
						ArtifactDevelopFault(75)
					ArtifactTakeDamage(strength * 1.25)
		if ("wizard") // these are big crystals, thus you probably shouldn't smack them around too hard!
			if (stimtype == "force")
				if (strength >= 20)
					T.visible_message("<span style=\"color:red\">[src] cracks and splinters!</span>")
					playsound(loc, "sound/misc/glass_step.ogg", 100, 1)
					ArtifactDevelopFault(80)
					ArtifactTakeDamage(strength * 1.5)

	if (!src || !A)
		return

	if (!A.activated)
		for (var/artifact_trigger/AT in A.triggers)
			if (A.activated)
				break
			if (AT.stimulus_required == stimtype)
				if (AT.do_amount_check)
					if (AT.stimulus_type == ">=" && strength >= AT.stimulus_amount)
						ArtifactActivated()
					else if (AT.stimulus_type == "<=" && strength <= AT.stimulus_amount)
						ArtifactActivated()
					else if (AT.stimulus_type == "==" && strength == AT.stimulus_amount)
						ArtifactActivated()
					else
						if (istext(A.hint_text))
							if (strength >= AT.stimulus_amount - AT.hint_range && strength <= AT.stimulus_amount + AT.hint_range)
								if (prob(AT.hint_prob))
									T.visible_message("<strong>[src]</strong> [A.hint_text]")
				else
					ArtifactActivated()

/obj/proc/ArtifactTouched(mob/user as mob)
	if (istype(user,/mob/living/silicon/ai))
		return
	if (istype(user,/mob/dead))
		return

	var/artifact/A = artifact
	if (istype(A,/artifact))
		if (istype(user,/mob/living/carbon))
			ArtifactStimulus("carbtouch", 1)
		if (istype(user,/mob/living/silicon))
			ArtifactStimulus("silitouch", 1)
		ArtifactStimulus("force", 1)
		user.visible_message("<strong>[user.name]</strong> touches [src].")
		if (istype(artifact,/artifact))
			if (A.touch_descriptors.len > 0)
				boutput(user, "[pick(A.touch_descriptors)]")
			else
				boutput(user, "You can't really tell how it feels.")
		if (A.activated)
			A.effect_touch(src,user)
	return

/obj/proc/ArtifactTakeDamage(var/dmg_amount)
	if (!ArtifactSanityCheck() || !isnum(dmg_amount))
		return

	var/artifact/A = artifact

	A.health -= dmg_amount
	A.health = max(0,min(A.health,100))

	if (A.health <= 0)
		ArtifactDestroyed()
	return

/obj/proc/ArtifactDestroyed()
	// Call this rather than straight Del() on an artifact if you want to destroy it. This way, artifacts can have their own
	// version of this for ones that will deliver a payload if broken.
	if (!ArtifactSanityCheck())
		return

	var/artifact/A = artifact

	ArtifactLogs(usr, null, src, "destroyed", null, 0)

	artifact_controls.artifacts -= src

	var/turf/T = get_turf(src)
	if (istype(T,/turf))
		switch(A.artitype)
			if ("ancient")
				T.visible_message("<span style=\"color:red\"><strong>[src] sparks and sputters violently before falling apart!</strong></span>")
			if ("martian")
				T.visible_message("<span style=\"color:red\"><strong>[src] bursts open, and rapidly liquefies!</strong></span>")
			if ("wizard")
				T.visible_message("<span style=\"color:red\"><strong>[src] shatters and disintegrates!</strong></span>")
			if ("eldritch")
				T.visible_message("<span style=\"color:red\"><strong>[src] warps in on itself and vanishes!</strong></span>")
			if ("precursor")
				T.visible_message("<span style=\"color:red\"><strong>[src] implodes, crushing itself into dust!</strong></span>")

	qdel(src)
	return

/obj/proc/ArtifactDevelopFault(var/faultprob)
	// This proc is used for randomly giving an artifact a fault. It's usually used in the New() proc of an artifact so that
	// newly spawned artifacts have a chance of being faulty by default, though this can also be called whenever an artifact is
	// damaged or otherwise poorly handled, so you could potentially turn a good artifact into a dangerous piece of shit if you
	// abuse it too much.
	// I'm probably going to change this one up to use a list of fault datum rather than some kind of variable, that way multiple
	// faults can be on one artifact.
	if (!isnum(faultprob))
		return
	if (!ArtifactSanityCheck())
		return
	var/artifact/A = artifact

	if (A.artitype == "eldritch")
		faultprob *= 2 // eldritch artifacts fucking hate you and are twice as likely to go faulty
	faultprob = max(0,min(faultprob,100))

	if (prob(faultprob) && A.fault_types.len)
		var/new_fault = pick(A.fault_types)
		if (ispath(new_fault))
			var/artifact_fault/F = new new_fault(A)
			F.holder = A
			A.faults += F

// Added. Very little related to artifacts was logged (Convair880).
/proc/ArtifactLogs(var/mob/user, var/mob/target, var/obj/O, var/type_of_action, var/special_addendum, var/trigger_alert = 0)
	if (!O || !istype(O.artifact, /artifact) || !type_of_action)
		return

	var/artifact/A = O.artifact

	if ((target && ismob(target)) && type_of_action == "weapon")
		logTheThing("combat", user, target, "attacks %target% with an active artifact ([A.type])[special_addendum ? ", [special_addendum]" : ""] at [log_loc(target)].")
	else
		logTheThing(type_of_action == "detonated" ? "bombing" : "station", user, target, "an artifact ([A.type]) was [type_of_action] [special_addendum ? "([special_addendum])" : ""] at [target && isturf(target) ? "[log_loc(target)]" : "[log_loc(O)]"].[type_of_action == "detonated" ? " Last touched by: [O.fingerprintslast ? "[O.fingerprintslast]" : "*null*"]" : ""]")

	if (trigger_alert)
		message_admins("An artifact ([A.type]) was [type_of_action] [special_addendum ? "([special_addendum])" : ""] at [log_loc(O)]. Last touched by: [O.fingerprintslast ? "[O.fingerprintslast]" : "*null*"]")

	return