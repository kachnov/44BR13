/targetable/changeling/spit
	name = "Toxic Spit"
	desc = "Spit homing acid at a target, melting their headgear (if any) or burning their face."
	icon_state = "acid"
	cooldown = 900
	targeted = 1
	target_anything = 1
	sticky = 1

	cast(atom/target)
		if (..())
			return TRUE
		if (isobj(target))
			target = get_turf(target)
		if (isturf(target))
			target = locate(/mob/living) in target
			if (!target)
				boutput(holder.owner, __red("We cannot spit without a target."))
				return TRUE
		if (target == holder.owner)
			return TRUE
		var/mob/MT = target
		holder.owner.visible_message(__red("<strong>[holder.owner] spits acid towards [target]!</strong>"))
		logTheThing("combat", holder.owner, MT, "spits acid at %target% as a changeling [log_loc(holder.owner)].")
		spawn (0)
			var/obj/overlay/A = new /obj/overlay( holder.owner.loc )
			A.icon_state = "cbbolt"
			A.icon = 'icons/obj/projectiles.dmi'
			A.name = "acid"
			A.anchored = 0
			A.density = 0
			A.layer = EFFECTS_LAYER_UNDER_1
			A.flags += TABLEPASS
			A.reagents = new /reagents(10)
			A.reagents.my_atom = A
			A.reagents.add_reagent("pacid", 10)

			var/obj/overlay/B = new /obj/overlay( A.loc )
			B.icon_state = "cbbolt"
			B.icon = 'icons/obj/projectiles.dmi'
			B.name = "acid"
			B.anchored = 1
			B.density = 0
			B.layer = OBJ_LAYER

			for (var/i=0, i<20, i++)
				B.loc = A.loc

				step_to(A,MT,0)
				if (get_dist(A,MT) == 0)
					for (var/mob/O in AIviewers(MT, null))
						O.show_message(__red("<strong>[MT.name] is hit by the acid spit!</strong>"), 1)
					A.reagents.reaction(MT)
					MT.lastattacker = src
					MT.lastattackertime = world.time
					qdel(A)
					qdel(B)
					return
				sleep(5)
			qdel(A)
			qdel(B)
