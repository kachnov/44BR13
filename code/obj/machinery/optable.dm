/obj/machinery/optable
	name = "Operating Table"
	icon = 'icons/obj/surgery.dmi'
	icon_state = "table2-idle"
	desc = "A table that allows qualified professionals to perform delicate surgeries."
	density = 1
	anchored = 1.0
	mats = 25

	var/mob/living/carbon/human/victim = null
	var/strapped = 0.0

	var/obj/machinery/computer/operating/computer = null
	var/id = 0.0

/obj/machinery/optable/New()
	..()
	spawn (5)
		computer = locate(/obj/machinery/computer/operating, orange(2,src))

/obj/machinery/optable/ex_act(severity)

	switch(severity)
		if (1.0)
			//SN src = null
			qdel(src)
			return
		if (2.0)
			if (prob(50))
				//SN src = null
				qdel(src)
				return
		if (3.0)
			if (prob(25))
				density = 0
		else
	return

/obj/machinery/optable/blob_act(var/power)
	if (prob(power * 2.5))
		qdel(src)

/obj/machinery/optable/attack_hand(mob/user as mob)
	if (usr.bioHolder.HasEffect("hulk"))
		user.visible_message("<span style=\"color:red\">[user] destroys the table.</span>")
		density = 0
		qdel(src)
	return



/obj/machinery/optable/CanPass(atom/movable/O as mob|obj, target as turf)
	if (!O)
		return FALSE
	if ((O.flags & TABLEPASS || istype(O, /obj/newmeteor)))
		return TRUE
	else
		return FALSE
	return

/obj/machinery/optable/proc/check_victim()
	if (locate(/mob/living/carbon/human, loc))
		var/mob/M = locate(/mob/living/carbon/human, loc)
		if (M.resting)
			victim = M
			icon_state = "table2-active"
			return TRUE
	victim = null
	icon_state = "table2-idle"
	return FALSE

/obj/machinery/optable/process()
	check_victim()

/obj/machinery/optable/attackby(obj/item/W as obj, mob/user as mob)
	if (istype(user,/mob/living/silicon)) return
	if (istype(W, /obj/item/electronics/scanner)) return // hack
	if (istype(W, /obj/item/grab))
		if (ismob(W:affecting))
			var/mob/M = W:affecting
			M.resting = 1
			M.set_loc(loc)
			visible_message("<span style=\"color:red\">[M] has been laid on the operating table by [user].</span>")
			for (var/obj/O in src)
				O.set_loc(loc)
			add_fingerprint(user)
			icon_state = "table2-active"
			victim = M
			qdel(W)
			return
	user.drop_item()
	if (W && W.loc)
		W.set_loc(loc)
	return

/obj/machinery/optable/MouseDrop_T(atom/movable/O as mob|obj, mob/user as mob)
	if (!istype(user,/mob/living))
		boutput(user, "<span style=\"color:red\">You're dead! What the hell could surgery possibly do for you NOW, dumbass?!</span>")
		return
	if (!ismob(O))
		boutput(user, "<span style=\"color:red\">You can't put that on the operating table!</span>")
		return
	if (!ishuman(O))
		boutput(user, "<span style=\"color:red\">You can only put carbon lifeforms on the operating table.</span>")
		return
	if (get_dist(user,src) > 1)
		boutput(user, "<span style=\"color:red\">You need to be closer to the operating table.</span>")
		return
	if (get_dist(user,O) > 1)
		boutput(user, "<span style=\"color:red\">Your target needs to be near you to put them on the operating table.</span>")
		return

	var/mob/living/carbon/C = O
	if (user == C)
		visible_message("<span style=\"color:red\"><strong>[user.name]</strong> lies down on [src].</span>")
		user.resting = 1
		user.set_loc(loc)
		victim = user
	else
		visible_message("<span style=\"color:red\"><strong>[user.name]</strong> starts to move [C.name] onto the operating table.</span>")
		if (do_mob(user,C,30))
			C.resting = 1
			C.set_loc(loc)
			victim = C
		else
			boutput(user, "<span style=\"color:red\">You were interrupted!</span>")
	return