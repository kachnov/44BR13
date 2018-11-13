/simsMotive
	var/name = "motive"
	var/icon = 'icons/mob/hud_human_new.dmi'
	var/icon_state
	var/value = 100
	var/last_life_value = 100
	var/simsHolder/holder
	var/warning_cooldown = 10
	var/depletion_rate = 0.2
	var/image/image_meter = null
	var/image/image_change = null

	//Multipliers for how much the motive is drained by certain things and for how much it is gained
	//High drain rate - higher reduction of motive when explicitly modified
	//High gain rate - higher gain of motive when explicitly modified

	//var/affection_rate = 1
	var/gain_rate = 1
	var/drain_rate = 1

	var/obj/screen/hud/hud = new

	New(var/is_control = 0)
		..()
		spawn (0)
			if (holder)
				var/icon/hud_style = hud_style_selection[get_hud_style(holder.owner)]
				if (isicon(hud_style))
					icon = hud_style
			hud.name = name
			hud.icon = icon
			hud.icon_state = icon_state
			hud.layer = HUD_LAYER

			updateHud()
			if (!is_control)
				var/simsMotive/M = simsController.motives[type]
				if (M && istype(M))
					depletion_rate = M.depletion_rate
					gain_rate = M.gain_rate
					drain_rate = M.drain_rate

			simsController.register_motive(src)

	dispose()
		if (hud)
			qdel(hud)
			hud = null
		simsController.simsMotives -= src
		..()

	Del()
		if (hud)
			qdel(hud)
		..()

	proc/updateHud()
		var/change = 0
		if (value > last_life_value)
			change = min(1 + round((value - last_life_value) / 5), 3)
		if (value < last_life_value)
			change = -min(1 + round((last_life_value - value) / 5), 3)
		if (change)
			if (!image_change)
				image_change = image(icon, "change[change]", layer = HUD_LAYER+2)
			else
				image_change.icon_state = "change[change]"
			hud.UpdateOverlays(image_change, "change")
		else
			hud.UpdateOverlays(null, "change")
		var/a_change = value - last_life_value
		hud.name = "[initial(name)] ([value] / 100) \[[a_change > 0 ? "+" : null][a_change]\]"
		var/ratio = value / 100
		if (!image_meter)
			image_meter = image(icon, "[icon_state]-o", layer = HUD_LAYER+1)
		image_meter.color = rgb((1 - ratio) * 255, ratio * 255, 0)
		hud.UpdateOverlays(image_meter, "meter")

	proc/updateHudIcon(var/icon/I)
		if (!I || !hud)
			return
		icon = I
		hud.icon = I
		if (image_change)
			hud.UpdateOverlays(null, "change")
			image_change.icon = I
			hud.UpdateOverlays(image_change, "change")
		if (image_meter)
			image_meter.icon = I
			updateHud()

	proc/showOwner(var/msg)
		boutput(holder.owner, msg)

	proc/modifyValue(var/amt)
		var/prev_value = value
		var/affection_mod = amt < 0 ? drain_rate : gain_rate //Negative change, use drain modifier, positive, use gain modifier

		value = max(min(value + (amt * affection_mod), 100), 0)
		if (prev_value < 100 && value >= 100)
			onFill()
		else if (prev_value > 0 && value <= 0)
			onDeplete()
		if (prev_value != value)
			onChange()
			if (prev_value < value)
				onIncrease()
			else
				onDecrease()

	proc/Life()
		updateHud()
		last_life_value = value
		if (mayStandardDeplete())
			modifyValue(-depletion_rate)
		if (warning_cooldown <= 0)
			var/warning = getWarningMessage()
			if (warning)
				showOwner(warning)
				warning_cooldown = 20
		else
			warning_cooldown--
		onLife()

	proc/mayStandardDeplete()
		return TRUE

	proc/getWarningMessage()
	proc/onLife()
	proc/onDeplete()
	proc/onFill()
	proc/onChange()
	proc/onIncrease()
	proc/onDecrease()

	hunger
		name = "hunger"
		icon_state = "hunger"
		depletion_rate = 0.23
		var/starve_message = "<span style=\"color:red\">You are starving to death!</span>"

		var/starving = 0

		onDeplete()
			if (!starving)
				showOwner(starve_message)
				starving++

		onFill()
			starving = 0

		getWarningMessage()
			if (value < 25)
				return pick("<span style=\"color:red\">You are [pick("utterly", "absolutely", "positively", "completely", "extremely", "perfectly")] [pick("starving", "unfed", "ravenous", "famished")]!</span>", "<span style=\"color:red\">You feel like you could [pick("die of [pick("hunger", "starvation")] any moment now", "eat a [pick("donkey", "horse", "whale", "moon", "planet", "star", "galaxy", "universe", "multiverse")]")]!</span>")
			else if (value < 50)
				return "<span style=\"color:red\">You feel [pick("hungry", "peckish", "ravenous", "undernourished", "famished", "esurient")]!</span>"
			else if (value < 75)
				return "<span style=\"color:red\">You feel [pick("a bit", "slightly", "somewhat", "a little", "faintly")] [pick("hungry", "peckish", "famished")]!</span>"
			else
				return null

		onLife()
			if (starving && value < 25)
				starving++
				if (!(starving % 10))
					showOwner(starve_message)
				if (starving > 30 && prob(10))
					holder.owner.death()
			else if (starving && value > 50)
				starving--

		thirst
			name = "thirst"
			icon_state = "thirst"
			starve_message = "<span style=\"color:red\">You are dying of thirst!</span>"
			depletion_rate = 0.33
			drain_rate = 0.8

			getWarningMessage()
				if (value < 25)
					return pick("<span style=\"color:red\">You are [pick("utterly", "absolutely", "positively", "completely", "extremely", "perfectly")] dry!</span>", "<span style=\"color:red\">You feel [pick("like you could die of thirst any moment now", "as dry as [pick("sand", "the moon", "solid carbon dioxyde", "bones")]")]!</span>")
				else if (value < 50)
					return "<span style=\"color:red\">You feel [pick("thirsty", "dry")]!</span>"
				else if (value < 75)
					return "<span style=\"color:red\">You feel [pick("a bit", "slightly", "somewhat", "a little", "faintly")] [pick("thirsty", "dry")]!</span>"
				else
					return null


	social
		name = "social"
		icon_state = "social"
		depletion_rate = 0.18
		var/criminal = -1 //-1 unset, 0 law-abiding citizen, 1 traitor

		mayStandardDeplete()
			if (!ticker || !ticker.mode)
				return FALSE

			//Let's save the results of this so we're not doing a bunch of thingy in list every life cycle
			if (criminal > 0)
				return FALSE
			else if (criminal < 0 || prob(5)) //But let's refresh it once / 20 cycles or so
				criminal = (holder.owner.mind in ticker.mode.traitors) || (holder.owner.mind in ticker.mode.Agimmicks)
				return !criminal

			return TRUE

		getWarningMessage()
			if (value < 25)
				return "<span style=\"color:red\">You really feel like talking to someone, or you might [pick("go crazy", "go insane", "go nuts", "become unhinged", "become a lunatic", "become totally gaga", "go loco", "go bonkers", "go stark mad", "go mad")]!</span>"
			else if (value < 50)
				return "<span style=\"color:red\">You feel [pick("rather ", "quite ", "moderately ", "kind of ", "pretty ", null)]socially deprived!</span>"
			else if (value < 75)
				return "<span style=\"color:red\">You could go for a [pick("good", "nice", "long", "short", "great", "pleasant", "delightful", "friendly")] [pick("conversation", "chat", "discussion", "talk", "social exchange", "banter", "head-to-head", trim("t[ascii2text(234)]te-[ascii2text(224)]-t[ascii2text(234)]te"))] right now.</span>"
			else
				return null

		onDeplete()
			holder.owner.contract_disease(/ailment/disease/space_madness, null, null, 1)
			if (ishuman(holder.owner))
				var/mob/living/carbon/human/H = holder.owner
				if (!H.pathogens.len)
					holder.owner.infected(ez_pathogen(/pathogeneffects/malevolent/serious_paranoia))

		onLife()
			if (value < 10 && prob((10 - value) * 10))
				onDeplete()

	hygiene
		name = "hygiene"
		icon_state = "hygiene"
		depletion_rate = 0.09

		var/protection = 20

		mayStandardDeplete()
			if (protection > 0)
				protection--
				return FALSE
			else
				return TRUE

		onIncrease()
			protection = round(value / 5)

		onLife()
			if (value < 15 && prob(33))
				if (holder.owner.bioHolder && !(holder.owner.bioHolder.HasEffect("sims_stinky")))
					holder.owner.bioHolder.AddEffect("sims_stinky")
			if (value < 10 && prob((10 - value) * 1.5))
				for (var/mob/living/carbon/human/H in viewers(2, holder.owner))
					if (H != holder.owner && prob(30 - value) * 2)
						//H.stunned = max(holder.owner.stunned, 1) <- Let's not punish others for our poor choices in life - unrealistic but more fun
						H.visible_message("<span style=\"color:red\">[H] throws up all over \himself. Gross!</span>")
						playsound(H.loc, "sound/effects/splat.ogg", 50, 1)
						boutput(H, "<span style=\"color:red\">You are [pick("disgusted", "revolted", "repelled", "sickened", "nauseated")] by [holder.owner]'s [pick("smell", "odor", "body odor", "scent", "fragrance", "bouquet", "savour", "tang", "whiff")]!</span>")
						new /obj/decal/cleanable/vomit(H.loc)
				holder.owner.stunned = max(holder.owner.stunned, 1)
				holder.owner.visible_message("<span style=\"color:red\">[holder.owner] throws up all over \himself. Gross!</span>")
				playsound(holder.owner.loc, "sound/effects/splat.ogg", 50, 1)
				new /obj/decal/cleanable/vomit(holder.owner.loc)
				showOwner("<span style=\"color:red\">You are [pick("disgusted", "revolted", "repelled", "sickened", "nauseated")] by your own [pick("smell", "odor", "body odor", "scent", "fragrance", "bouquet", "savour", "tang", "whiff")]!</span>")
			if (value < 5 && prob(1))
				var/pathogen/P = unpool(/pathogen)
				P.create_weak()
				holder.owner.infected(P)
				showOwner("<span style=\"color:red\">You don't feel well.</span>")

		getWarningMessage()
			if (value < 25)
				return pick("<span style=\"color:red\">You [pick("smell", "stink", "reek")]!</span>", "<span style=\"color:red\">You are [pick("absolutely", "utterly", "completely")] [pick("disgusting", "revolting", "repellent", "sickening", "nauseating", "stomach-churning", "gross")]!</span>", "<span style=\"color:red\"><strong>Take a [pick("shower", "bath")]!</strong></span>")
			else if (value < 50)
				return "<span style=\"color:red\">You feel [pick("smelly", "stinky", "unclean", "filthy", "dirty", "a bit disgusting", "grimy", "mucky", "foul", "unwashed", "begrimed", "tainted")]!</span>"
			else if (value < 75)
				return "<span style=\"color:red\">You feel [pick("a bit", "slightly", "somewhat", "a little", "faintly")] [pick("unclean", "dirty", "filthy", "stinky", "smelly")].</span>"
			else
				return null

	bladder
		name = "bladder"
		icon_state = "bladder"
		depletion_rate = 0.53
		drain_rate = 0.8
		gain_rate = 0.8

		getWarningMessage()
			var/list/urination = list("urinate", "piss", "pee", "answer the call of nature", "wee-wee", "spend a penny", "have a leak", "take a leak", "relieve yourself", "have a Jimmy", "have a whizz", "have a piddle", "pass water", "empty the tank", "flush the buffers", "lower the water level", "pay the water bill", "park your breakfast", "make your bladder gladder", "release the pressure", "put out the fire", "visit the urination station", "drain the tank")
			var/to_urinate = pick(urination)
			if (value < 25)
				return "<span style=\"color:red\">You feel like you could [pick("wet", "piss", "pee", "urinate into", "leak into")] your pants any minute now!</span>"
			else if (value < 50)
				return "<span style=\"color:red\">You feel a [pick("serious", "pressing", "critical", "dire", "burning")] [pick("inclination", "desire", "need", "call", "urge", "motivation")] to [to_urinate]!</span>"
			else if (value < 75)
				return "<span style=\"color:red\">You feel a [pick("slight", "tiny", "faint", "distant", "minimal", "little")] [pick("inclination", "desire", "need", "urge", "call", "motivation")] to [to_urinate].</span>"
			else
				return null

		onDeplete()
			showOwner("<span style=\"color:red\"><strong>You piss all over yourself!</strong></span>")
			modifyValue(100)
			holder.affectMotive("hygiene", -100)
			holder.owner.stunned = max(holder.owner.stunned, 2)
			if (ishuman(holder.owner))
				var/mob/living/carbon/human/H = holder.owner
				if (H.w_uniform)
					var/obj/item/U = H.w_uniform
					U.name = "piss-soaked [initial(U.name)]"
				else if (H.wear_suit)
					var/obj/item/U = H.wear_suit
					U.name = "piss-soaked [initial(U.name)]"
			new /obj/decal/cleanable/urine(holder.owner.loc)

	comfort
		name = "comfort"
		icon_state = "comfort"
		depletion_rate = 0.25
		gain_rate = 1.5

		mayStandardDeplete()
			if (holder.owner.buckled)
				return FALSE
			if (locate(/obj/stool/chair) in holder.owner.loc)
				return FALSE
			if (holder.owner.lying && (locate(/obj/stool/bed) in holder.owner.loc))
				return FALSE
			return TRUE

		getWarningMessage()
			if (value < 25)
				return "<span style=\"color:red\">You really [pick("need", "require", "feel the need for", "are in need of")] the [pick("hug", "feeling", "embrace", "comfort")] of a soft [pick("sofa", "bed", "chair", "pillow")]!</span>"
			else if (value < 50)
				return "<span style=\"color:red\">You feel like [pick("sitting down", "lying down", "you need a bit of comfort")]!</span>"
			else if (value < 75)
				return "<span style=\"color:red\">You feel [pick("slightly", "minimally", "a tiny bit", "a little", "just a bit")] uncomfortable.</span>"
			else
				return null

		onLife()
			if (holder.owner.lying && (locate(/obj/stool/bed) in holder.owner.loc))
				modifyValue(5)
				return
			var/obj/stool/chair/the_chair = locate(/obj/stool/chair) in holder.owner.loc
			if (the_chair)
				modifyValue(the_chair.comfort_value)

	fun
		name = "fun"
		icon_state = "fun"
		depletion_rate = 0.25

		mayStandardDeplete()
			if (isrestrictedz(holder.owner.z))
				return FALSE
			if (!ticker || !ticker.mode)
				return FALSE
			if ((holder.owner.mind in ticker.mode.traitors) || (holder.owner.mind in ticker.mode.Agimmicks))
				return FALSE
			return TRUE

		getWarningMessage()
			if (value < 25)
				return "<span style=\"color:red\">You are [pick("<strong>so</strong>", "so very", "painfully", "extremely", "excruciatingly", "rather uncomfortably")] bored![prob(25)? " You'd rather die!" : null]</span>"
			else if (value < 50)
				return "<span style=\"color:red\">You're [pick("quite", "rather", "super", "really", "pretty", "moderately", "very")] bored!</span>"
			else if (value < 75)
				return pick("<span style=\"color:red\">You feel like doing something fun.</span>", "<span style=\"color:red\">You feel a bit bored.</span>")
			else
				return null

		onDeplete()
			if (prob(10))
				showOwner("<span style=\"color:red\"><strong>You can't take being so bored anymore!</strong></span>")
				if (ishuman(holder.owner))
					var/mob/living/carbon/human/H = holder.owner
					H.force_suicide()
					modifyValue(50)

		onLife()
			if (value < 10)
				onDeplete()

	room
		name = "room"
		icon_state = "room"
		depletion_rate = 0

		mayStandardDeplete()
			return FALSE

		getWarningMessage()
			var/a_mess = pick("mess", "clusterfuck", "disorder", "disarray", "clutter", "landfill", "dump")
			if (value < 25)
				return "<span style=\"color:red\">This place is a [pick("fucking", "complete", "total", "downright", "consummate", "veritable", "proper")] [a_mess].</span>"
			else if (value < 50)
				return "<span style=\"color:red\">This place is a [a_mess]!</span>"
			else if (value < 75)
				return "<span style=\"color:red\">This place is a [pick("bit of a mess", "bit messy", "little messy")].</span>"
			else
				return null

		onLife()
			var/area/Ar = get_area(holder.owner)
			if (Ar)
				value = Ar.sims_score
			else
				value = 0

	energy
		name = "energy"
		icon_state = "energy"
		depletion_rate = 0.28

		gain_rate = 1.5

		var/forced_sleep = 0

		mayStandardDeplete()
			// JFC fuck mobs
			if (holder.owner.asleep)
				return FALSE
			if (holder.owner.weakened)
				return FALSE
			if (holder.owner.paralysis)
				return FALSE
			if (holder.owner.lying)
				return FALSE
			if (holder.owner.sleeping)
				return FALSE
			if (holder.owner.resting)
				return FALSE
			return TRUE

		onLife()
			var/mob/living/L = holder.owner
			if (forced_sleep)
				if (value < 100)
					if (!L.asleep)
						showOwner("<span style=\"color:red\">You overworked yourself and cannot wake up until you are rested!</span>")
					L.asleep = 1
					L.sleeping += 1
				else
					forced_sleep = 0
					L.asleep = 0
					L.sleeping = 0
			if (L.asleep)
				var/sm = 1
				if (forced_sleep)
					sm *= 0.5
				if (locate(/obj/stool/bed) in holder.owner.loc)
					sm *= 2
				modifyValue(sm * 4)
			if (L.asleep || L.lying)
				if (locate(/obj/poolwater) in get_turf(L))
					showOwner("<span style=\"color:red\">You are drowning!</span>")
					L.losebreath++
					L.take_oxygen_deprivation(5)

		onDeplete()
			showOwner("<span style=\"color:red\"><strong>You cannot stay awake anymore!</strong></span>")
			forced_sleep = 1
			modifyValue(5)

		getWarningMessage()
			if (value < 25)
				return "<span style=\"color:red\">You're [pick("extremely", "seriously", "incredibly", "tremendously", "overwhelmingly")] [pick("tired", "exhausted", "weary", "fatigued", "drowsy", "spent", "drained", "jaded")].</span>"
			else if (value < 50)
				return "<span style=\"color:red\">You feel [pick("rather", "quite", "very", "pretty", "really")] [pick("tired", "sleepy", "drowsy")]!</span>"
			else if (value < 75)
				return "<span style=\"color:red\">You feel [pick("somewhat", "a bit", "slightly", "a little", "a little bit", "a tiny bit")] tired.</span>"
			else
				return null

/simsControl
	var/list/motives = list()
	var/list/simsHolder/simsHolders = list()
	var/list/simsMotive/simsMotives = list()


	var/provide_plumbobs = 1

	New()
		..()
		spawn (10) //Give it some time to finish creating the simsController because fak
			for (var/T in subtypesof(/simsMotive))
				motives[T] = new T(1)

	Topic(href, href_list)
		if (href_list["mot"])
			var/simsMotive/M = locate(href_list["mot"])
			if (!istype(M) || M != motives[M.type])
				return
			if (href_list["rate"])
				var/dep = input("Enter new depletion rate.", "Depletion rate", M.depletion_rate) as null|num
				if (isnull(dep))
					return
				set_global_sims_var(M,"depletion_rate", dep)

			else if (href_list["gain"])
				var/gain = input("Enter new gain rate.", "Gain rate", M.gain_rate) as null|num
				if (isnull(gain))
					return
				set_global_sims_var(M, "gain_rate", gain)
			else if (href_list["drain"])
				var/drain = input("Enter new drain rate.", "Drain rate", M.drain_rate) as null|num
				if (isnull(drain))
					return
				set_global_sims_var(M, "drain_rate", drain)

			showControls(usr)
		else if (href_list["profile"])
			var/mod = text2num(href_list["profile"])
			if (!isnum(mod))
				return
			set_multiplier(mod)
			showControls(usr)
		else if (href_list["toggle_plum"])
			toggle_plumbobs()
			showControls(usr)
		else
			return

	proc/toggle_plumbobs()
		provide_plumbobs = !provide_plumbobs
		for (var/simsHolder/SH in simsHolders)
			if (SH.plumbob)
				qdel(SH.plumbob)

	proc/register_motive(var/simsMotive/SM)
		if (!(SM in simsMotives))
			simsMotives += SM

	proc/register_simsHolder(var/simsHolder/SH)
		if (!(SH in simsHolders))
			simsHolders += SH

	proc/set_multiplier(var/mult) //Set a profile on all simsMotives
		if (!isnum(mult)) return
		for (var/simsMotive/SM in simsMotives)
			SM.gain_rate = initial(SM.gain_rate) * mult
			SM.drain_rate = initial(SM.drain_rate) * mult
			SM.depletion_rate = initial(SM.depletion_rate) * mult

	proc/set_global_sims_var(var/simsMotive/M, var/var_name, var/new_value) //Change one value on every simsHolder
		if (!var_name in M.vars)
			logTheThing("debug", null, null, "<strong>SpyGuy/Sims:</strong> Tried to set \"[var_name]\" var on simsMotive [M] but could not find it in vars list.")
			return
		for (var/simsMotive/SM in simsMotives)
			if (SM.type == M.type)
				SM.vars[var_name] = new_value

	proc/showControls(var/mob/user)
		var/o = "<html><head><title>Motive Controls</title><style>"
		o += "</style></head><body>"

		o += {"<a href='?src=\ref[src];toggle_plum=1'>Plumbobs: [provide_plumbobs ? "On" : "Off"]</a><br>

				<h3>Profiles</h3>
				<table><tr>
				<td><a href='?src=\ref[src];profile=0.1'>RP</a></td>
				<td><a href='?src=\ref[src];profile=0.2'>V. Low</a></td>
				<td><a href='?src=\ref[src];profile=0.4'>Low</a></td>
				<td><a href='?src=\ref[src];profile=0.6'>Med-low</a></td>
				<td><a href='?src=\ref[src];profile=1'>Standard</a></td>
				<td><a href='?src=\ref[src];profile=1.5'>High</a></td>
				<td><a href='?src=\ref[src];profile=2'>Very High</a></td>
				<td><a href='?src=\ref[src];profile=4'>Doom</a></td>
				</tr></table>"}
		o += "<table><tr><td><strong>Name</strong></td><td><strong>Standard depletion rate</strong></td><td><strong>Gain rate</strong></td><td>Drain rate</td></tr>"
		for (var/T in motives)
			var/simsMotive/M = motives[T]
			o += {"<tr>
				<td><strong>[M.name]</strong></td>
				<td><a href='?src=\ref[src];mot=\ref[M];rate=1'>[M.depletion_rate]</a>% per second</td>
				<td><a href='?src=\ref[src];mot=\ref[M];gain=1'>[M.gain_rate]</a> ([M.gain_rate * 100]%)</td>
				<td><a href='?src=\ref[src];mot=\ref[M];drain=1'>[M.drain_rate]</a> ([M.drain_rate * 100]%)</td>
				</tr>"}

		o += "</table>"
		o += "</body></html>"
		user << browse(o, "window=sims_controller;size=500x400")


var/global/simsControl/simsController = new()

/simsHolder
	var/list/motives = list()
	var/mob/living/owner
	var/obj/effect/plumbob/plumbob = null
	var/base_mood_value = 1.35

	human
		New()
			..()
			addMotive(/simsMotive/hunger)
			addMotive(/simsMotive/hunger/thirst)
			addMotive(/simsMotive/social)
			addMotive(/simsMotive/hygiene)
			addMotive(/simsMotive/bladder)
			addMotive(/simsMotive/comfort)
			addMotive(/simsMotive/fun)
			addMotive(/simsMotive/energy)
			addMotive(/simsMotive/room)
			if (owner && ishuman(owner))
				var/SY = 3
				var/mob/living/carbon/human/H = owner
				for (var/name in motives)
					var/simsMotive/M = motives[name]
					var/obj/screen/hud/hud = M.hud
					hud.screen_loc = "NORTH-[SY],EAST"
					SY++
					H.hud.add_screen(hud)

	destiny
		New()
			..()
			addMotive(/simsMotive/hunger)
			addMotive(/simsMotive/hunger/thirst)
			addMotive(/simsMotive/hygiene)
			addMotive(/simsMotive/bladder)
			addMotive(/simsMotive/energy)
			if (owner && ishuman(owner))
				var/SY = 5
				var/mob/living/carbon/human/H = owner
				for (var/name in motives)
					var/simsMotive/M = motives[name]
					var/obj/screen/hud/hud = M.hud
					hud.screen_loc = "NORTH-[SY],EAST"
					SY++
					H.hud.add_screen(hud)

	New(var/mob/living/L)
		owner = L
		simsController.register_simsHolder(src)

	proc/cleanup()
		if (owner && ishuman(owner))
			var/mob/living/carbon/human/H = owner
			for (var/name in motives)
				var/simsMotive/M = motives[name]
				var/obj/screen/hud/hud = M.hud
				H.hud.remove_screen(hud)
			if (plumbob)
				H.attached_objs -= plumbob
				plumbob.loc = null
		if (plumbob)
			qdel(plumbob)
			plumbob = null
		for (var/name in motives)
			qdel(motives[name])
		motives.len = 0
		simsController.simsHolders -= src

	Del()
		cleanup()
		..()

	dispose()
		cleanup()
		..()

	proc/updateHudIcons(var/icon/I)
		if (!I || !motives.len)
			return
		for (var/name in motives)
			var/simsMotive/M = motives[name]
			if (M)
				M.updateHudIcon(I)

	proc/getMoodActionMultiplier()
		if (!motives || !motives.len)
			return TRUE
		if (!base_mood_value)
			base_mood_value = 1
		var/mv = motives.len * 100
		var/cv = 0
		for (var/motive in motives)
			var/simsMotive/M = motives[motive]
			cv += M.value
		return cv / mv * base_mood_value

	proc/addMotive(var/mt)
		var/simsMotive/M = new mt
		if (initial(M.name) in motives)
			return
		motives[initial(M.name)] = M
		M.holder = src

	proc/getValue(var/name)
		if (name in motives)
			var/simsMotive/M = motives[name]
			return M.value

	proc/affectMotive(var/name, var/affection)
		if (name in motives)
			var/simsMotive/M = motives[name]
			M.modifyValue(affection)

	proc/Life()
		if (disposed)
			return
		for (var/name in motives)
			var/simsMotive/M = motives[name]
			M.Life()

		if (!base_mood_value)
			base_mood_value = 1
		var/color_t = getMoodActionMultiplier() / base_mood_value

		if (simsController && simsController.provide_plumbobs)
			if (!plumbob)
				attach_plum(owner)

			plumbob.color = rgb((1 - color_t) * 255, color_t * 255, 0)
			plumbob.light.set_color(1 - color_t, color_t, 0)

/obj/effect/plumbob
	name = "plumbob"
	icon = 'icons/obj/junk.dmi'
	icon_state = "plum-desat"
	mouse_opacity = 0
	anchored = 1.0
	pixel_y = 32
	var/mob/living/owner
	var/light/light

	New()
		..()
		animate_bumble(src, Y1 = 32, Y2 = 30, slightly_random = 0)
		light = new /light/point
		light.attach(src)
		light.set_brightness(0.5)
		light.enable()

	// relay procs
	attackby(obj/item/W as obj, mob/user as mob)
		if (owner)
			owner.attackby(W, user)

	attack_hand(mob/user as mob)
		if (owner)
			owner.attack_hand(user)

	attack_ai(mob/user as mob)
		if (owner)
			owner.attack_ai(user)

/proc/attach_plum(var/mob/M as mob in world)
	if (!M)
		M = input("Please, select a player!", "Attach Plumbob") as null|anything in mobs
	var/obj/effect/plumbob/P = new(get_turf(M))
	M.attached_objs += P
	P.owner = M
	if (ishuman(M))
		var/mob/living/carbon/human/H = M
		if (H.sims)
			H.sims.plumbob = P
