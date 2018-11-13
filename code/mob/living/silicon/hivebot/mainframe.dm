/mob/living/silicon/hive_mainframe
	name = "Robot Mainframe"
	voice_name = "synthesized voice"
	icon = 'icons/mob/hivebot.dmi'
	icon_state = "hive_main"
	health = 200
	var/health_max = 200
	robot_talk_understand = 2

	anchored = 1
	var/online = 1
	var/mob/living/silicon/hivebot = null
	var/hivebot_name = null
	var/force_mind = 0

/mob/living/silicon/hive_mainframe/New()
	. = ..()
	Namepick()

/mob/living/silicon/hive_mainframe/Life(controller/process/mobs/parent)
	if (..(parent))
		return TRUE
	if (stat == 2)
		return
	else
		updatehealth()

		if (health <= 0)
			death()
			return

	if (force_mind)
		if (!mind)
			if (client)
				mind = new
				mind.key = key
				mind.current = src
				ticker.minds += mind
		force_mind = 0

	update_icons_if_needed()

/mob/living/silicon/hive_mainframe/death(gibbed)
	stat = 2
	canmove = 0
	vision.set_color_mod("#ffffff") // reset any blindness
	sight |= SEE_TURFS
	sight |= SEE_MOBS
	sight |= SEE_OBJS
	see_in_dark = SEE_DARK_FULL
	see_invisible = 2
	lying = 1
	icon_state = "hive_main-crash"

	var/tod = time2text(world.realtime,"hh:mm:ss") //weasellos time of death patch
	mind.store_memory("Time of death: [tod]", 0)


	return ..(gibbed)


/mob/living/silicon/hive_mainframe/say_understands(var/other)
	if (istype(other, /mob/living/carbon/human) && (!other:mutantrace || !other:mutantrace.exclusive_language))
		return TRUE
	if (istype(other, /mob/living/silicon/robot))
		return TRUE
	if (istype(other, /mob/living/silicon/hivebot))
		return TRUE
	if (istype(other, /mob/living/silicon/ai))
		return TRUE
	return ..()

/mob/living/silicon/hive_mainframe/say_quote(var/text)
	var/ending = copytext(text, length(text))

	if (ending == "?")
		return "queries, \"[text]\"";
	else if (ending == "!")
		return "declares, \"[copytext(text, 1, length(text))]\"";

	return "states, \"[text]\"";


/mob/living/silicon/hive_mainframe/proc/return_to(var/mob/user)
	if (user.mind)
		user.mind.transfer_to(src)
		spawn (20)
			if (user)
				user:shell = 1
				user:real_name = "Robot [pick(rand(1, 999))]"
				user:name = user:real_name


		return

/mob/living/silicon/hive_mainframe/verb/cmd_deploy_to()
	set category = "Mainframe Commands"
	set name = "Deploy to shell."
	deploy_to()

/mob/living/silicon/hive_mainframe/verb/deploy_to()

	if (usr.stat == 2)
		boutput(usr, "You can't deploy because you are dead!")
		return

	var/list/bodies = new/list()

	for (var/mob/living/silicon/hivebot/H in mobs)
		if (H.z == z)
			if (H.shell)
				if (!H.stat)
					bodies += H

	var/target_shell = input(usr, "Which body to control?") as null|anything in bodies

	if (!target_shell)
		return

	else if (mind)
		spawn (30)
			target_shell:mainframe = src
			target_shell:dependent = 1
			target_shell:real_name = name
			target_shell:name = target_shell:real_name
		mind.transfer_to(target_shell)
		return


/client/proc/MainframeMove(n,direct,var/mob/living/silicon/hive_mainframe/user)
	return

/mob/living/silicon/hive_mainframe/Login()
	..()
	update_clothing()
	return



/mob/living/silicon/hive_mainframe/proc/Namepick()
	var/randomname = pick(ai_names)
	var/newname = input(src,"You are the a Mainframe Unit. Would you like to change your name to something else?", "Name change",randomname) as text

	if (length(newname) == 0)
		newname = randomname

	if (newname)
		if (length(newname) >= 26)
			newname = copytext(newname, 1, 26)
		newname = replacetext(newname, ">", "'")
		real_name = newname
		name = newname