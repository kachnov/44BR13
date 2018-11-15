REPO_OBJECT(mutt_hivemind, /mutt_hivemind)

/mutt_hivemind

/mutt_hivemind/New()
	..()
	REPO.mutt_hivemind = src

/mutt_hivemind/proc/communicate(x)
	for (var/mutt in REPO.amerimutts)
		var/mob/living/carbon/human/mutt/M = mutt 
		if (istype(M) && M.stat == CONSCIOUS && M.client)
			boutput(M, "<span style = \"color:#593001\">[x]</span>")

/mutt_hivemind/proc/announce(x)
	return communicate("<big><strong>La Mente: [x]</strong></big>")

/mutt_hivemind/proc/announce_after(x, time)
	set waitfor = FALSE 
	sleep(time)
	return announce(x)