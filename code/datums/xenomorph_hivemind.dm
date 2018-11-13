var/global/xenomorph_hivemind/xenomorph_hivemind = new

/xenomorph_hivemind

/xenomorph_hivemind/New()
	..()
	xenomorph_hivemind = src

/xenomorph_hivemind/proc/communicate(x)
	for (var/xenomorph in facehuggers|xenomorph_larvae|grown_xenomorphs)
		boutput(xenomorph, "<span style = \"color:purple\">[x]</span>")

/xenomorph_hivemind/proc/announce(x)
	return communicate("<big><strong>Hivemind: [x]</strong></big>")