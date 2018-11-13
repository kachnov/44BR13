/obj/item/gun/energy/artifact
	// an energy gun, it shoots things as you might expect
	name = "artifact energy gun"
	icon = 'icons/obj/artifacts/artifactsitem.dmi'
	icon_state = "laser"
	force = 5.0
	artifact = 1
	is_syndicate = 1
	module_research_no_diminish = 1
	mat_changename = 0
	mat_changedesc = 0

	New(var/loc, var/forceartitype)
		var/artifact/energygun/AS = new /artifact/energygun(src)
		if (forceartitype)
			AS.validtypes = list("[forceartitype]")
		artifact = AS
		// The other three are normal for energy gun setup, so proceed as usual i guess
		cell = null

		spawn (0)
			ArtifactSetup()
			var/artifact/A = artifact
			cell = new/obj/item/ammo/power_cell/self_charging/artifact(src,A.artitype)
			ArtifactDevelopFault(15)

			current_projectile = AS.bullet
			projectiles = list(current_projectile)
			cell.max_charge = max(cell.max_charge, current_projectile.cost)

	examine()
		set src in oview()
		boutput(usr, "You have no idea what this thing is!")
		if (!ArtifactSanityCheck())
			return
		var/artifact/A = artifact
		if (istext(A.examine_hint))
			boutput(usr, "[A.examine_hint]")

	UpdateName()
		name = "[name_prefix(null, 1)][real_name][name_suffix(null, 1)]"

	attackby(obj/item/W as obj, mob/user as mob)
		if (Artifact_attackby(W,user))
			..()

	process_ammo(var/mob/user)
		if (istype(user,/mob/living/silicon/robot))
			var/mob/living/silicon/robot/R = user
			if (R.cell)
				if (R.cell.charge >= robocharge)
					R.cell.charge -= robocharge
					return TRUE
			return FALSE
		else
			if (current_projectile)
				if (cell)
					if (cell.use(current_projectile.cost))
						return TRUE
			return FALSE

	shoot(var/target,var/start,var/mob/user)
		if (!ArtifactSanityCheck())
			return
		var/artifact/energygun/A = artifact

		if (!istype(A))
			return

		if (!A.activated)
			return

		..()

		A.ReduceHealth(src)

		ArtifactFaultUsed(user)
		return

/artifact/energygun
	associated_object = /obj/item/gun/energy/artifact
	rarity_class = 2
	validtypes = list("ancient","eldritch","precursor")
	react_elec = list(0.02,0,5)
	react_xray = list(10,75,100,11,"CAVITY")
	var/integrity = 100
	var/integrity_loss = 5
	var/projectile/artifact/bullet = null
	examine_hint = "It seems to have a handle you're supposed to hold it by."
	module_research = list("weapons" = 8, "energy" = 8)
	module_research_insight = 3

	New()
		..()
		bullet = new/projectile/artifact
		bullet.randomise()
		integrity = rand(50, 100)
		integrity_loss = rand(1, 7)
		react_xray[3] = integrity

	proc/ReduceHealth(var/obj/item/gun/energy/artifact/O)
		var/prev_health = integrity
		integrity -= integrity_loss
		if (integrity <= 20 && prev_health > 20)
			O.visible_message("<span style=\"color:red\">[O] emits a terrible cracking noise.</span>")
		if (integrity <= 0)
			O.visible_message("<span style=\"color:red\">[O] crumbles into nothingness.</span>")
			qdel(O)
		react_xray[3] = integrity