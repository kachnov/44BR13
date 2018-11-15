var/global/xenomorph_hivemind/xenomorph_hivemind = new

/xenomorph_hivemind
	var/list/alive = list()
	var/total_facehuggers = 0
	var/total_larvae = 0
	var/total_xenomorphs = 0

/xenomorph_hivemind/New()
	..()
	xenomorph_hivemind = src

/xenomorph_hivemind/proc/communicate(x)
	for (var/xenomorph in facehuggers|xenomorph_larvae|grown_xenomorphs)
		var/mob/living/xeno = xenomorph 
		if (istype(xeno) && xeno.stat == CONSCIOUS && xeno.client)
			boutput(xeno, "<span style = \"color:purple\">[x]</span>")

/xenomorph_hivemind/proc/announce(x)
	return communicate("<big><strong>Hivemind: [x]</strong></big>")

/xenomorph_hivemind/proc/announce_after(x, time)
	set waitfor = FALSE 
	sleep(time)
	return announce(x)

/xenomorph_hivemind/proc/display_info(H)
	// this works nicely because length(null) evaluates to 0
	boutput(H, "<span style = \"color:purple\"><big><big><strong>Hivemind Status:</strong></big></big><br>")
	boutput(H, "<span style = \"color:purple\"><big>Living Facehuggers: [length(alive[facehuggers])]/[total_facehuggers]</big></span>")
	boutput(H, "<span style = \"color:purple\"><big>Living Larvae: [length(alive[xenomorph_larvae])]/[total_larvae]</big></span>")
	boutput(H, "<span style = \"color:purple\"><big>Living Xenomorphs: [length(alive[grown_xenomorphs])]/[total_xenomorphs]</big></span>")

/xenomorph_hivemind/proc/on_birth(var/mob/living/L)
	if (isfacehugger(L))
		if (isnull(alive[facehuggers]))
			alive[facehuggers] = list()
		alive[facehuggers] += L
		++total_facehuggers
	else if (isxenomorphlarva(L))
		if (isnull(alive[xenomorph_larvae]))
			alive[xenomorph_larvae] = list()
		alive[xenomorph_larvae] += L
		++total_larvae
	else if (isxenomorph(L))
		if (isnull(alive[grown_xenomorphs]))
			alive[grown_xenomorphs] = list()
		alive[grown_xenomorphs] += L
		++total_xenomorphs

/xenomorph_hivemind/proc/on_death(var/mob/living/L)
	if (isfacehugger(L) && alive[facehuggers])
		alive[facehuggers] -= L
	else if (isxenomorphlarva(L) && alive[xenomorph_larvae])
		alive[xenomorph_larvae] -= L
	else if (isxenomorph(L) && alive[grown_xenomorphs])
		alive[grown_xenomorphs] -= L