#define DESERIALIZE_ERROR 0
#define DESERIALIZE_OK 1
#define DESERIALIZE_NEED_POSTPROCESS 2
#define DESERIALIZE_NOT_IMPLEMENTED 4

/sandbox
	var/list/context = list()

/proc/icon_serializer(var/savefile/F, var/path, var/sandbox/sandbox, var/icon, var/icon_state)
	var/iname = "[icon]"
	F["[path].icon"] << iname
	F["[path].icon_state"] << icon_state
	if (!("icon" in sandbox.context))
		sandbox.context += "icon"
		sandbox.context["icon"] = list()
	if (!(iname in sandbox.context["icon"]))
		sandbox.context["icon"] += iname
		sandbox.context["icon"][iname] = icon
		F["ICONS.[iname]"] << icon

/iconDeserializerData
	var/icon/icon
	var/icon_state

/proc/icon_deserializer(var/savefile/F, var/path, var/sandbox/sandbox, var/defaultIcon, var/defaultState)
	var/iname
	var/iconDeserializerData/IDS = new()
	IDS.icon = defaultIcon
	IDS.icon_state = defaultState
	F["[path].icon"] >> iname
	if (!fexists(iname))
		if ("[defaultIcon]" == iname) // fuck off byond fuck you
			F["[path].icon_state"] >> IDS.icon_state
		else
			if (!("icon_failures" in sandbox.context))
				sandbox.context += "icon_failures"
				sandbox.context["icon_failures"] = list("total" = 0)
			if (!(iname in sandbox.context["icon_failures"]))
				sandbox.context["icon_failures"] += iname
				sandbox.context["icon_failures"][iname] = 0
			sandbox.context["icon_failures"]["total"]++
			sandbox.context["icon_failures"][iname]++

			F["ICONS.[iname]"] >> IDS.icon
			if (!IDS.icon && usr)
				boutput(usr, "<span style=\"color:red\">Fatal error: Saved copy of icon [iname] cannot be loaded. Local loading failed. Falling back to default icon.</span>")
			else if (IDS.icon)
				F["[path].icon_state"] >> IDS.icon_state
	else
		IDS.icon = icon(file(iname))
		F["[path].icon_state"] >> IDS.icon_state
	return IDS

/proc/matrix_serializer(var/savefile/F, var/path, var/sandbox/sandbox, var/name, var/matrix/mx)
	var/base = "[path].[name]"
	F["[base].a"] << mx.a
	F["[base].b"] << mx.b
	F["[base].c"] << mx.c
	F["[base].d"] << mx.d
	F["[base].e"] << mx.e
	F["[base].f"] << mx.f

/proc/matrix_deserializer(var/savefile/F, var/path, var/sandbox/sandbox, var/name, var/matrix/defMx = matrix())
	var
		a
		b
		c
		d
		e
		f

	var/base = "[path].[name]"
	F["[base].a"] >> a
	if (!a)
		return defMx
	F["[base].d"] >> d
	if (!d)
		return defMx
	F["[base].b"] >> b
	F["[base].c"] >> c
	F["[base].e"] >> e
	F["[base].f"] >> f
	return new /matrix(a,b,c,d,e,f)

/atom
	layer = TURF_LAYER
	var/mechanics_holder/mechanics = null
	var/level = 2
	var/flags = FPRINT
	var/fingerprints = null
	var/list/fingerprintshidden = new/list()
	var/fingerprintslast = null
	var/blood_DNA = null
	var/blood_type = null
	var/last_bumped = 0
	var/shrunk = 0
	var/area/last_area = null
	var/texture_size = 0  //Override for the texture size used by setTexture.

/* -------------------- name stuff -------------------- */
	/*
	to change names: either add or remove something with the appropriate proc(s) and then call atom.UpdateName()

	to add to names: call atom.name_prefix(text_to_add) or thing.name_suffix(text_to_add) depending on where you want it
		text_to_add will run strip_html() on the text, which also limits the text to MAX_MESSAGE_LEN

	to remove from names: call atom.remove_prefixes(num) or atom.remove_suffixes(num)
		num can be either a number (obviously) OR text (I had already named the var okay)
		if num is a number it'll remove that many things from the total amount of pre/suffixes, starting from the earliest one
		if num is text, it'll remove that specific text from the list, once
	*/

	New()
		..()
		if (isnull(loc))
			verbs -= /atom/verb/examine

	var/list/name_prefixes = list()
	var/list/name_suffixes = list()
	var/num_allowed_prefixes = 10
	var/num_allowed_suffixes = 5

	proc/name_prefix(var/text_to_add, var/return_prefixes = 0)
		var/prefix = ""
		if (istext(text_to_add) && length(text_to_add) && islist(name_prefixes))
			if (name_prefixes.len >= num_allowed_prefixes)
				remove_prefixes(1)
			name_prefixes += strip_html(text_to_add)
		if (return_prefixes)
			var/amt_prefixes = 0
			for (var/i in name_prefixes)
				if (amt_prefixes >= num_allowed_prefixes)
					prefix += " "
					break
				prefix += i + " "
				amt_prefixes ++
			return prefix

	proc/name_suffix(var/text_to_add, var/return_suffixes = 0)
		var/suffix = ""
		if (istext(text_to_add) && length(text_to_add) && islist(name_suffixes))
			if (name_suffixes.len >= num_allowed_suffixes)
				remove_suffixes(1)
			name_suffixes += strip_html(text_to_add)
		if (return_suffixes)
			var/amt_suffixes = 0
			for (var/i in name_suffixes)
				if (amt_suffixes >= num_allowed_suffixes)
					break
				suffix += " " + i
				amt_suffixes ++
			return suffix

	proc/remove_prefixes(var/num = 1)
		if (!num)
			return
		if (istext(num)) // :v
			name_prefixes -= num
			return
		if (islist(name_prefixes) && name_prefixes.len)
			for (var/i in name_prefixes)
				if (num <= 0 || !name_prefixes.len)
					return
				name_prefixes -= i
				num --

	proc/remove_suffixes(var/num = 1)
		if (!num)
			return
		if (istext(num))
			name_suffixes -= num
			return
		if (islist(name_suffixes) && name_suffixes.len)
			for (var/i in name_suffixes)
				if (num <= 0 || !name_suffixes.len)
					return
				name_suffixes -= i
				num --

	proc/UpdateName()
		name = "[name_prefix(null, 1)][initial(name)][name_suffix(null, 1)]"

/* -------------------- end name stuff -------------------- */

	var/mat_changename = 1 //Change the name of this atom when a material is applied?
	var/mat_changedesc = 1 //Change the desc of this atom when a material is applied?

	var/matrix/_transform

	var/list/attached_objs = list() //List of attached objects. Objects in this list will follow this atom around as it moves.

	var/explosion_resistance = 0
	var/explosion_protection = 0 //Reduces damage from explosions

	///Chemistry.
	var/reagents/reagents = null

	//var/chem_is_open_container = 0
	// replaced by OPENCONTAINER flags and atom/proc/is_open_container()

	disposing()
		material = null
		reagents = null
		fingerprintshidden = null
		tag = null
		..()
	///Chemistry.

	proc/Turn(var/rot)
		transform = matrix(transform, rot, MATRIX_ROTATE)

	proc/Scale(var/scalex = 1, var/scaley = 1)
		transform = matrix(transform, scalex, scaley, MATRIX_SCALE)

	proc/Translate(var/x = 0, var/y = 0)
		transform = matrix(transform, x, y, MATRIX_TRANSLATE)

	proc/assume_air(air_group/giver)
		giver.dispose()
		return null

	proc/remove_air(amount)
		return null

	proc/return_air()
		return null

	proc/grab_smash(obj/item/grab/G as obj, mob/user as mob)
		var/mob/M = G.affecting

		if  (!(ismob(G.affecting)))
			return FALSE

		if (get_dist(src, M) > 1)
			return FALSE

		user.visible_message("<span style=\"color:red\"><strong>[M] has been smashed against [src] by [user]!</strong></span>")
		logTheThing("combat", user, M, "smashes %target% against [src]")

		random_brute_damage(G.affecting, rand(2,3))
		G.affecting.TakeDamage("chest", 0, rand(4,5))
		playsound(G.affecting.loc, "punch", 25, 1, -1)

		user.u_equip(G)
		G.dispose()
		return TRUE

	proc/set_dir(_dir)
		dir = _dir

// Convenience proc to see if a container is open for chemistry handling
// returns true if open
// false if closed
	proc/is_open_container()
		return flags & OPENCONTAINER

	proc/transfer_all_reagents(var/atom/A as turf|obj|mob, var/mob/user as mob)
		// trans from src to A
		if (!reagents || !A.reagents)
			return // what're we gunna do here?? ain't got no reagent holder

		if (!reagents.total_volume) // Check to make sure the from container isn't empty.
			boutput(user, "<span style=\"color:red\">[src] is empty!</span>")
			return
		else if (A.reagents.total_volume == A.reagents.maximum_volume) // Destination Container is full, quit trying to do things what you can't do!
			boutput(user, "<span style=\"color:red\">[A] is full!</span>") // Notify the user, then exit the process.
			return

		var/T //Placeholder for total volume transferred

		if ((A.reagents.total_volume + src.reagents.total_volume) > A.reagents.maximum_volume) // Check to make sure that both containers content's combined won't overfill the destination container.
			T = (A.reagents.maximum_volume - A.reagents.total_volume) // Dump only what fills up the destination container.
			logTheThing("combat", user, null, "transfers chemicals from [src] [log_reagents(src)] to [A] at [log_loc(A)].") // This wasn't logged. Call before trans_to (Convair880).
			src.reagents.trans_to(A, T) // Dump the amount of reagents.
			boutput(user, "<span style=\"color:blue\">You transfer [T] units into [A].</span>") // Tell the user they did a thing.
			return
		else
			T = reagents.total_volume // Just make T the whole dang amount then.
			logTheThing("combat", user, null, "transfers chemicals from [src] [log_reagents(src)] to [A] at [log_loc(A)].") // Ditto (Convair880).
			reagents.trans_to(A, T) // Dump it all!
			boutput(user, "<span style=\"color:blue\">You transfer [T] units into [A].</span>")
			return

	proc/handle_event(var/event) //This is sort of like a version of Topic that is not for browsing.
		return

	//Called AFTER the material of the object was changed.
	proc/onMaterialChanged()
		if (istype(material))
			explosion_resistance = material.hasProperty(PROP_COMPRESSIVE) ? round(material.getProperty(PROP_COMPRESSIVE) / 33) : explosion_resistance
			explosion_protection = material.hasProperty(PROP_COMPRESSIVE) ? round(material.getProperty(PROP_COMPRESSIVE) / 33) : explosion_protection
			if (!(flags & CONDUCT) && (material.getProperty(PROP_ELECTRICAL) / 100) >= 0.45) flags |= CONDUCT
		return

	proc/serialize_icon(var/savefile/F, var/path, var/sandbox/sandbox)
		icon_serializer(F, path, sandbox, icon, icon_state)

	proc/deserialize_icon(var/savefile/F, path, var/sandbox/sandbox)
		var/iconDeserializerData/IDS = icon_deserializer(F, path, sandbox, icon, icon_state)
		icon = IDS.icon
		icon_state = IDS.icon_state

	proc/serialize(var/savefile/F, var/path, var/sandbox/sandbox)
		return

	proc/deserialize(var/savefile/F, var/path, var/sandbox/sandbox)
		return DESERIALIZE_NOT_IMPLEMENTED

	proc/deserialize_postprocess()
		return

/obj
	assume_air(air_group/giver)
		if (loc)
			return loc.assume_air(giver)
		else
			return null

	remove_air(amount)
		if (loc)
			return loc.remove_air(amount)
		else
			return null

	return_air()
		if (loc)
			return loc.return_air()
		else
			return null



/atom/proc/ex_act(var/severity=0,var/last_touched=0)
	return

/atom/proc/reagent_act(var/reagent_id,var/volume)
	if (!istext(reagent_id) || !isnum(volume) || volume < 1)
		return TRUE
	return FALSE

/atom/proc/emp_act()
	return

/atom/proc/emag_act(var/mob/user, var/obj/item/card/emag/E) //This is gonna be fun!
	return FALSE

/atom/proc/demag(var/mob/user) //hail satan full of grace
	return FALSE

/atom/proc/meteorhit(obj/meteor as obj)
	qdel(src)
	return

/atom/proc/allow_drop()
	return TRUE

/atom/proc/CheckExit(atom/mover, turf/target)
	//return !(flags & ON_BORDER) || CanPass(mover, target, 1, 0)
	return TRUE // fuck it

/atom/proc/HasEntered(atom/movable/AM as mob|obj, atom/OldLoc)
	return

/atom/proc/HasExited(atom/movable/AM as mob|obj, atom/NewLoc)
	return

/atom/proc/ProximityLeave(atom/movable/AM as mob|obj)
	return

/atom/proc/HasProximity(atom/movable/AM as mob|obj)
	return
/*
/atom/MouseEntered()
	usr << output("[name]", "atom_label")
*/
/atom/movable/overlay/attackby(a, b)
	if (master)
		return master.attackby(a, b)
	return

/atom/movable/overlay/attack_hand(a, b, c)
	if (master)
		return master.attack_hand(a, b, c)
	return

/atom/movable/overlay/New()
	for (var/x in verbs)
		verbs -= x
	return

/atom/movable/disposing()
	set_loc(null)
	..()

/atom/movable
	layer = OBJ_LAYER
	glide_size = 8
	var/last_move = null
	var/anchored = 0
	// var/elevation = 2    - not used anywhere
	var/move_speed = 10
	var/l_move_time = 1
	var/throwing = 0
	var/throw_speed = 2
	var/throw_range = 7
	var/throwforce = 1
	var/soundproofing = 5

/atom/movable/overlay
	var/atom/master = null
	anchored = 1

/atom/movable/overlay/disposing()
	master = null
	..()

/atom/movable/Move(NewLoc, direct)
	if (direct & (direct - 1))
		if (direct & NORTH)
			if (direct & EAST)
				if (step(src, NORTH))
					step(src, EAST)
				else if (step(src, EAST))
					step(src, NORTH)
			else
				if (step(src, NORTH))
					step(src, WEST)
				else if (step(src, WEST))
					step(src, NORTH)
		else
			if (direct & EAST)
				if (step(src, SOUTH))
					step(src, EAST)
				else if (step(src, EAST))
					step(src, SOUTH)
			else
				if (step(src, SOUTH))
					step(src, WEST)
				else if (step(src, WEST))
					step(src, SOUTH)
		return // this should in turn fire off its own slew of move calls, so don't do anything here

	var/atom/A = loc
	. = ..()
	move_speed = world.timeofday - l_move_time
	l_move_time = world.timeofday
	if ((A != loc && A && A.z == z))
		last_move = get_dir(A, loc)
		for (var/atom/movable/M in attached_objs)
			M.set_loc(loc)
		actions.interrupt(src, INTERRUPT_MOVE)

/atom/movable/verb/pull()
	set name = "Pull"
	set src in oview(1)
	set category = "Local"

	if (!( usr ))
		return

	if (loc == usr)
		return

	// eyebots aint got no arms man, how can they be pulling stuff???????
	if (isshell(usr))
		if (!ticker)
			return
		if (!ticker.mode)
			return
		if (!istype(ticker.mode, /game_mode/construction))
			return
	// no pulling other mobs for ghostdrones (but they can pull other ghostdrones)
	else if (isghostdrone(usr) && (isliving(src) && !isghostdrone(src)))
		return

	if (istype(usr, /mob/living/carbon) || istype(usr, /mob/living/silicon))
		add_fingerprint(usr)

	if (istype(src,/obj/item/old_grenade/light_gimmick))
		boutput(usr, "<span style=\"color:blue\">You feel your hand reach out and clasp the grenade.</span>")
		attack_hand(usr)
		return
	if (!( anchored ))
		usr.pulling = src
		//Wire: Hi this was so dumb. Turns out it isn't only humans that have huds, who woulda thunk!!
		if (usr:hud && usr:hud:pulling) //yes this uses the dreaded ":", deal with it
			usr:hud:update_pulling()
	return

/atom/proc/get_desc(dist)

/atom/verb/examine()
	set name = "Examine"
	set category = "Local"
	set src in view(12)	//make it work from farther away

	var/output = "This is \an [name]."

	// Added for forensics (Convair880).
	if (isitem(src) && blood_DNA)
		output = "<span style=\"color:red\">This is a bloody [name].</span>"
		//boutput(usr, "<span style=\"color:red\">This is a bloody [name].</span>")
		if (desc)
			output += "<br>[desc] It seems to be covered in blood."
			//boutput(usr, "[desc] It seems to be covered in blood.")
	else if (desc)
		output += "<br>[desc]"
		/*boutput(usr, "This is \an [name].")
		if (desc)
			boutput(usr, desc)*/

	var/dist = get_dist(src, usr)
	if (istype(usr, /mob/dead/target_observer))
		dist = get_dist(src, usr:target)
	var/extra = get_desc(dist, usr)
	if (extra)
		output += " [extra]"
		//boutput(usr, extra)

	if (output)
		boutput(usr, output)

/atom/proc/MouseDrop_T()
	return

/atom/proc/attack_hand(mob/user as mob)
	return

/atom/proc/attack_ai(mob/user as mob)
	return

/atom/proc/hitby(atom/movable/AM as mob|obj)
	return

/atom/proc/attackby(obj/item/W as obj, mob/user as mob, params)
	if (user && W && !(W.flags & SUPPRESSATTACK))  //!( istype(W, /obj/item/grab)  || istype(W, /obj/item/spraybottle) || istype(W, /obj/item/card/emag)))
		user.visible_message("<span class='combat'><strong>[user] hits [src] with [W]!</strong></span>")
	return

/atom/proc/add_fingerprint(mob/living/M as mob)
	if (!ismob(M)) return
	if (isnull(M)) return
	if (isnull(M.key)) return
	if (!( flags ) & 256)
		return

	if (ishuman(M))
		var/mob/living/carbon/human/H = M
		var/list/L = params2list(fingerprints)

		if (H.gloves) // Fixed: now adds distorted prints even if 'fingerprintslast == ckey'. Important for the clean_forensic proc (Convair880).
			var/gloveprints = H.gloves.distort_prints(md5(H.bioHolder.Uid), 1)
			if (!isnull(gloveprints))
				L -= gloveprints
				if (L.len >= 6) //Limit fingerprints in the list to 6
					L.Cut(1,2)
				L += gloveprints
				fingerprints = list2params(L)

			if (fingerprintslast != H.key)
				fingerprintshidden += text("(Wearing gloves). Real name: [], Key: []",H.real_name, H.key)
				fingerprintslast = H.key

			return FALSE

		if (!( fingerprints ))
			fingerprints = "[md5(H.bioHolder.Uid)]"
			if (fingerprintslast != H.key)
				fingerprintshidden += "Real name: [H.real_name], Key: [H.key]"
				fingerprintslast = H.key

			return TRUE

		else
			L -= md5(H.bioHolder.Uid)
			while (L.len >= 6) // limit the number of fingerprints to 6, previously 3
				L -= L[1]
			L += md5(H.bioHolder.Uid)
			fingerprints = list2params(L)
			if (fingerprintslast != H.key)
				fingerprintshidden += "Real name: [H.real_name], Key: [H.key]"
				fingerprintslast = H.key

	else
		if (fingerprintslast != M.key)
			fingerprintshidden += "Real name: [M.real_name], Key: [M.key]"
			fingerprintslast = M.key

	return

//This will looks stupid on objects larger than 32x32. Might have to write something for that later. -Keelin
/atom/proc/setTexture(var/texture = "damaged", var/blendMode = BLEND_MULTIPLY, var/key = "texture")
	var/image/I = getTexturedImage(src, texture, blendMode)//, key)
	if (!I)
		return
	UpdateOverlays(I, key)
	return

/proc/getTexturedImage(var/atom/A, var/texture = "damaged", var/blendMode = BLEND_MULTIPLY)//, var/key = "texture")
	if (!A)
		return
	var/icon/tex = null

	//Try to find an appropriately sized icon.
	if (istype(A, /atom/movable))
		var/atom/movable/M = A
		if (A.texture_size == 32 || ((M.bound_height == 32 && M.bound_width == 32) && !A.texture_size))
			tex = icon('icons/effects/atom_textures_32.dmi', texture)
		else if (A.texture_size == 64 || ((M.bound_height == 64 && M.bound_width == 64) && !A.texture_size))
			tex = icon('icons/effects/atom_textures_64.dmi', texture)
		else
			tex = icon('icons/effects/atom_textures_32.dmi', texture)
	else if (isicon(A))
		var/icon/I = A
		if (I.Height() > 32)
			tex = icon('icons/effects/atom_textures_64.dmi', texture)
		else
			tex = icon('icons/effects/atom_textures_32.dmi', texture)
	else
		if (A.texture_size == 32)
			tex = icon('icons/effects/atom_textures_32.dmi', texture)
		else if (A.texture_size == 64)
			tex = icon('icons/effects/atom_textures_64.dmi', texture)
		else
			tex = icon('icons/effects/atom_textures_32.dmi', texture)

	var/icon/mask = null
	mask = new(isicon(A) ? A : A.icon)
	mask.MapColors(1,1,1, 1,1,1, 1,1,1, 1,1,1)
	mask.Blend(tex, ICON_MULTIPLY)
	//mask is now a cut-out of the texture shaped like the object.
	var/image/finished = image(mask,"")
	finished.blend_mode = blendMode
	return finished

// WHAT THE ACTUAL FUCK IS THIS SHIT
// WHO THE FUCK WROTE THIS
/atom/proc/add_blood(mob/living/M as mob, var/amount = 5)
	if (!( istype(M, /mob/living) ) || !M.blood_id)
		return FALSE
	if (!( flags ) & 256)
		return
	var/b_uid = "--unidentified substance--"
	var/b_type = "--unidentified substance--"
	if (M.bioHolder)
		b_uid = M.bioHolder.Uid
		b_type = M.bioHolder.bloodType
	if (!( blood_DNA ))
		if (istype(src, /obj/item))
			var/reagent/R = reagents_cache[M.blood_id]
			var/obj/item/source2 = src
			source2.icon_old = icon
			var/icon/I = new /icon(icon, icon_state)
			I.Blend(new /icon('icons/effects/blood.dmi', "thisisfuckingstupid"),ICON_ADD)
			if (R)
				I.Blend(rgb(R.fluid_r, R.fluid_g, R.fluid_b),ICON_MULTIPLY)
			I.Blend(new /icon('icons/effects/blood.dmi', "itemblood"),ICON_MULTIPLY)
			I.Blend(new /icon(icon, icon_state),ICON_UNDERLAY)
			icon = I
			blood_DNA = b_uid
			blood_type = b_type
		else if (istype(src, /turf/simulated))
			bleed(M, amount, 5)
		else if (istype(src, /mob/living/carbon/human))
			blood_DNA = b_uid
			blood_type = b_type
		else
			return
	else
		var/list/L = params2list(blood_DNA)
		L -= b_uid
		while (L.len >= 6) // Increased from 3 (Convair880).
			L -= L[1]
		L += b_uid
		blood_DNA = list2params(L)
	return

// Was clean_blood. Reworked the proc to take care of other forensic evidence as well (Convair880).
/atom/proc/clean_forensic()
	if (!src)
		return

	if (!( flags ) & 256)
		return

	// The first version accidently looped through everything for every atom. Consequently, cleaner grenades caused horrendous lag on my local server. Woops.
	if (!ismob(src)) // Mobs are a special case.
		if (istype(src, /obj/item) && (fingerprints || blood_DNA || blood_type))
			fingerprints = null
			blood_type = null

			if (blood_DNA)
				var/obj/item/CI = src
				CI.blood_DNA = null
				var/icon/SI = new /icon(CI.icon_old, CI.icon_state)
				CI.icon = SI

		else if (istype(src, /obj/decal/cleanable))
			qdel(src)

		else if (istype(src, /turf))
			//overlays = null
			for (var/obj/decal/cleanable/mess in get_turf(src))
				qdel(mess)

		else // Don't think it should clean doors and the like. Give the detective at least something to work with.
			return

	else
		if (isobserver(src) || isintangible(src) || iswraith(src)) // Just in case.
			return

		if (ishuman(src))
			var/mob/living/carbon/human/M = src
			var/list/gear_to_clean = list(M.r_hand, M.l_hand, M.head, M.wear_mask, M.w_uniform, M.wear_suit, M.belt, M.gloves, M.glasses, M.shoes, M.wear_id, M.back)
			for (var/obj/item/check in gear_to_clean)
				if (check.fingerprints || check.blood_DNA || check.blood_type)
					check.fingerprints = null
					check.blood_type = null
					if (check.blood_DNA)
						check.blood_DNA = null
						var/icon/WI = new /icon(check.icon_old, check.icon_state)
						check.icon = WI

			if (isnull(M.gloves)) // Can't clean your hands when wearing gloves.
				M.blood_DNA = null
				M.blood_type = null

			M.fingerprints = null // Foreign fingerprints on the mob.
			M.gunshot_residue = 0 // Only humans can have residue at the moment.
			M.set_clothing_icon_dirty()

		else

			var/mob/living/L = src // Punching cyborgs does leave fingerprints for instance.
			L.fingerprints = null
			L.blood_DNA = null
			L.blood_type = null
			L.set_clothing_icon_dirty()

	return

/atom/MouseDrop(atom/over_object as mob|obj|turf)
	spawn ( 0 )
		if (istype(over_object, /atom))
			if (usr.stat == 0)
				//To stop ghostdrones dragging people anywhere
				if (isghostdrone(usr) && ismob(src) && src != usr)
					return

				/* This was SUPPOSED to make the innerItem of items act on the mousedrop instead but it doesnt work for no reason
				if (istype(src, /obj/item))
					var/obj/item/W = src
					if (W.useInnerItem && W.contents.len > 0)
						target = pick(W.contents)
				//world.log << "calling mousedrop_t on [over_object] with params: [src], [usr]"
				*/

				over_object.MouseDrop_T(src, usr)
			else
				if (istype(over_object, /obj/machinery)) // For cyborg docking stations (Convair880).
					var/obj/machinery/M = over_object
					if (M.allow_stunned_dragndrop == 1)
						M.MouseDrop_T(src, usr)
		return
	..()
	return

/atom/proc/relaymove()
	return

/atom/proc/on_reagent_change(var/add = 0) // if the reagent container just had something added, add will be 1.
	return

/atom/proc/Bumped(AM as mob|obj)
	return

/atom/movable/Bump(var/atom/A as mob|obj|turf|area, yes)
	spawn ( 0 )
		if ((A && yes)) //wtf
			A.last_bumped = world.timeofday
			A.Bumped(src)
		return
	..()
	return

// bullet_act called when anything is hit buy a projectile (bullet, tazer shot, laser, etc.)
// flag is projectile type, can be:
//PROJECTILE_TASER = 1   		taser gun
//PROJECTILE_LASER = 2			laser gun
//PROJECTILE_BULLET = 3			traitor pistol
//PROJECTILE_PULSE = 4			pulse rifle
//PROJECTILE_BOLT = 5			crossbow
//PROJECTILE_WEAKBULLET = 6		detective's revolver

//Return an atom if you want to make the projectile's effects affect that instead.

/atom/proc/bullet_act(var/obj/projectile/P)
	if (material) material.triggerOnAttacked(src, P.shooter, src, (ismob(P.shooter) ? P.shooter:equipped() : P.shooter))
	for (var/atom/A in src)
		if (A.material)
			A.material.triggerOnAttacked(A, P.shooter, src, (ismob(P.shooter) ? P.shooter:equipped() : P.shooter))
	return


// this handles RL_Lighting for luminous atoms and some child types override it for extra stuff
// like the 2x2 pod camera. fixes that bug where you go through a warp portal but your camera doesn't update
//
// there are lots of old places in the code that set loc directly.
// ignore them they'll be fixed later, please use this proc in the future
/atom/movable/proc/set_loc(var/newloc as turf|mob|obj in world)
	if (loc == newloc)
		return src

	if (ismob(src)) // fuck haxploits
		var/mob/SM = src
		if (!(SM.client && SM.client.holder))
			if (istype(newloc, /turf/unsimulated))
				var/turf/unsimulated/T = newloc
				if (T.density)
					return

	if (isturf(loc))
		loc.Exited(src)

	var/area/my_area = get_area(src)
	var/area/new_area = get_area(newloc)
	if (my_area != new_area && my_area)
		my_area.Exited(src)

	loc = newloc

	if (my_area != new_area && new_area)
		new_area.Entered(src)

	if (isturf(newloc))
		var/turf/nloc = newloc
		nloc.Entered(src)

	for (var/atom/movable/M in attached_objs)
		M.set_loc(loc)

	return src

// standardized damage procs

/atom/proc/damage_blunt(var/amount)

/atom/proc/damage_piercing(var/amount)

/atom/proc/damage_slashing(var/amount)

/atom/proc/damage_corrosive(var/amount)

/atom/proc/damage_electricity(var/amount)

/atom/proc/damage_radiation(var/amount)

/atom/proc/damage_heat(var/amount)

/atom/proc/damage_cold(var/amount)