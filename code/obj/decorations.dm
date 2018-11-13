
/obj/poolwater
	name = "water"
	density = 0
	anchored = 1
	icon = 'icons/obj/stationobjs.dmi'
	icon_state = "poolwater"
	layer = EFFECTS_LAYER_UNDER_3
	mouse_opacity = 0
	New()
		var/reagents/R = new/reagents(10)
		reagents = R
		R.my_atom = src
		R.add_reagent("cleaner",5)
		R.add_reagent("water",5)
	HasEntered(atom/A)
		reagents.reaction(A, TOUCH, 2)
		return

/obj/tree1
	name = "Tree"
	desc = "It's a tree."
	icon = 'icons/effects/96x96.dmi' // changed from worlds.dmi
	icon_state = "tree" // changed from 0.0
	anchored = 1
	layer = EFFECTS_LAYER_UNDER_3
	pixel_x = -20
	density = 1
	opacity = 0 // this causes some of the super ugly lighting issues too

// what the hell is all this and why wasn't it just using a big icon? the lighting system gets all fucked up with this stuff

/*
 	New()
		var/image/tile10 = image('icons/misc/worlds.dmi',null,"1,0",10)
		tile10.pixel_x = 32

		var/image/tile01 = image('icons/misc/worlds.dmi',null,"0,1",10)
		tile01.pixel_y = 32

		var/image/tile11 = image('icons/misc/worlds.dmi',null,"1,1",10)
		tile11.pixel_y = 32
		tile11.pixel_x = 32

		overlays += tile10
		overlays += tile01
		overlays += tile11

		var/image/tile20 = image('icons/misc/worlds.dmi',null,"2,0",10)
		tile20.pixel_x = 64

		var/image/tile02 = image('icons/misc/worlds.dmi',null,"0,2",10)
		tile02.pixel_y = 64

		var/image/tile22 = image('icons/misc/worlds.dmi',null,"2,2",10)
		tile22.pixel_y = 64
		tile22.pixel_x = 64

		var/image/tile21 = image('icons/misc/worlds.dmi',null,"2,1",10)
		tile21.pixel_y = 32
		tile21.pixel_x = 64

		var/image/tile12 = image('icons/misc/worlds.dmi',null,"1,2",10)
		tile12.pixel_y = 64
		tile12.pixel_x = 32

		overlays += tile20
		overlays += tile02
		overlays += tile22
		overlays += tile21
		overlays += tile12 */


/obj/river
	name = "River"
	desc = "Its a river."
	icon = 'icons/misc/worlds.dmi'
	icon_state = "river"
	anchored = 1

/obj/stone
	name = "Stone"
	desc = "Its a stone."
	icon = 'icons/misc/worlds.dmi'
	icon_state = "stone"
	anchored = 1
	density=1

/obj/shrub
	name = "shrub"
	icon = 'icons/misc/worlds.dmi'
	icon_state = "shrub"
	anchored = 1
	density = 0
	layer = EFFECTS_LAYER_UNDER_1
	var/destroyed = 0

/obj/shrub/captainshrub
	name = "\improper Captain's bonsai tree"
	icon = 'icons/misc/worlds.dmi'
	icon_state = "shrub"
	desc = "The Captain's most prized possession. Don't touch it. Don't even look at it."
	anchored = 1
	density = 1
	layer = EFFECTS_LAYER_UNDER_1
	dir = EAST

	// Added ex_act and meteorhit handling here (Convair880).
	proc/update_icon()
		if (!src) return
		dir = NORTHEAST
		destroyed = 1
		density = 0
		desc = "The scattered remains of a once-beautiful bonsai tree."
		playsound(src, "sound/effects/attackblob.ogg", 100, 0)
		return

	attackby(obj/item/W as obj, mob/user as mob)
		if (!W) return
		if (!user) return
		if (destroyed) return
		if ((user.mind && user.mind.assigned_role == "Captain") && istype(W, /obj/item/wirecutters))
			boutput(user, "<span style=\"color:blue\">You carefully and lovingly sculpt your bonsai tree.</span>")
		if ((user.mind && user.mind.assigned_role == "Captain") && (!(istype(W, /obj/item/wirecutters))))
			boutput(user, "<span style=\"color:red\">Why would you ever destroy your precious bonsai tree?</span>")
		else if (istype(W, /obj/item) && (user.mind && user.mind.assigned_role != "Captain"))
			update_icon()
			boutput(user, "<span style=\"color:red\">I don't think the Captain is going to be too happy about this...</span>")
			visible_message(text("<strong><span style=\"color:red\">[] ravages the [] with the [].</span></strong>", user, src, W), 1)
		return

	meteorhit(obj/O as obj)
		visible_message("<strong><span style=\"color:red\">The meteor smashes right through [src]!</span></strong>")
		update_icon()
		return

	ex_act(severity)
		visible_message("<strong><span style=\"color:red\">[src] is ripped to pieces by the blast!</span></strong>")
		update_icon()
		return

/obj/grassplug
	name = "grass"
	icon = 'icons/misc/worlds.dmi'
	icon_state = "grassplug"
	anchored = 1

/obj/window_blinds
	name = "blinds"
	icon = 'icons/obj/decoration.dmi'
	icon_state = "blindsH-o"
	anchored = 1
	density = 0
	opacity = 0
	layer = 30.1 // just above windows
	var/base_state = "blindsH"
	var/open = 1
	var/id = null
	var/obj/blind_switch/mySwitch = null

	attack_hand(mob/user as mob)
		toggle()
		toggle_group()

	attackby(obj/item/W, mob/user)
		toggle()
		toggle_group()

	proc/toggle(var/force_state as null|num)
		if (!isnull(force_state))
			open = force_state
		else
			open = !(open)
		update_icon()

	proc/toggle_group()
		if (istype(mySwitch))
			mySwitch.toggle()

	proc/update_icon()
		if (open)
			icon_state = "[base_state]-c"
			opacity = 1
		else
			icon_state = "[base_state]-o"
			opacity = 0

	left
		icon_state = "blindsH-L-o"
		base_state = "blindsH-L"
	middle
		icon_state = "blindsH-M-o"
		base_state = "blindsH-M"
	right
		icon_state = "blindsH-R-o"
		base_state = "blindsH-R"

	vertical
		icon_state = "blindsV-o"
		base_state = "blindsV"

		left
			icon_state = "blindsV-L-o"
			base_state = "blindsV-L"
		middle
			icon_state = "blindsV-M-o"
			base_state = "blindsV-M"
		right
			icon_state = "blindsV-R-o"
			base_state = "blindsV-R"

	cog2
		icon_state = "blinds_cog2-o"
		base_state = "blinds_cog2"

		left
			icon_state = "blinds_cog2-L-o"
			base_state = "blinds_cog2-L"
		middle
			icon_state = "blinds_cog2-M-o"
			base_state = "blinds_cog2-M"
		right
			icon_state = "blinds_cog2-R-o"
			base_state = "blinds_cog2-R"

/obj/blind_switch
	name = "blind switch"
	desc = "A switch for opening the blinds."
	icon = 'icons/obj/power.dmi'
	icon_state = "light1"
	anchored = 1
	density = 0
	var/on = 0
	var/id = null
	var/list/myBlinds = list()

	New()
		..()
		if (!name || name in list("N blind switch", "E blind switch", "S blind switch", "W blind switch"))//== "N light switch" || name == "E light switch" || name == "S light switch" || name == "W light switch")
			name = "blind switch"
		spawn (5)
			locate_blinds()

	proc/locate_blinds()
		for (var/obj/window_blinds/blind in world)
			if (blind.id == id)
				if (!(blind in myBlinds))
					myBlinds += blind
					blind.mySwitch = src

	proc/toggle()
		on = !(on)
		icon_state = "light[!(on)]"
		if (!islist(myBlinds) || !myBlinds.len)
			return
		for (var/obj/window_blinds/blind in myBlinds)
			blind.toggle(on)

	attack_hand(mob/user as mob)
		toggle()

	attackby(obj/item/W, mob/user)
		toggle()

/obj/blind_switch/north
	name = "N blind switch"
	pixel_y = 24

/obj/blind_switch/east
	name = "E blind switch"
	pixel_x = 24

/obj/blind_switch/south
	name = "S blind switch"
	pixel_y = -24

/obj/blind_switch/west
	name = "W blind switch"
	pixel_x = -24

/obj/blind_switch/area
	locate_blinds()
		var/area/A = get_area(src)
		for (var/obj/window_blinds/blind in A)
			if (!(blind in myBlinds))
				myBlinds += blind
				blind.mySwitch = src

/obj/blind_switch/area/north
	name = "N blind switch"
	pixel_y = 24

/obj/blind_switch/area/east
	name = "E blind switch"
	pixel_x = 24

/obj/blind_switch/area/south
	name = "S blind switch"
	pixel_y = -24

/obj/blind_switch/area/west
	name = "W blind switch"
	pixel_x = -24
