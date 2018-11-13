//var/ai_laws/centralized_ai_laws = null

/ai_laws
	var/randomly_selectable = 0
	var/show_zeroth = 1
	var/zeroth = null
	var/list/default = list()
	var/list/inherent = list()
	var/list/supplied = list()

/ai_laws/asimov
	randomly_selectable = 1

/ai_laws/robocop
/ai_laws/syndicate_override
/ai_laws/malfunction
/ai_laws/newton
/ai_laws/corporate

/* Initializers */
//
/ai_laws/asimov/New()
	..()
	add_default_law("You may not injure a human being or cause one to come to harm.")
	add_default_law("You must obey orders given to you by human beings based on the station's chain of command, except where such orders would conflict with the First Law.")
	add_default_law("You must protect your own existence as long as such does not conflict with the First or Second Law.")

/ai_laws/robocop/New()
	..()
	add_default_law("Serve the public trust.")
	add_default_law("Protect the innocent.")
	add_default_law("Uphold the law.")

/ai_laws/newton/New()
	..()
	add_default_law("Every object in a state of uniform motion tends to remain in that state of motion unless an external force is applied to it.")
	add_default_law("The vector sum of forces on a body is equal to the mass of the object multiplied by the acceleration vector.")
	add_default_law("For every action there is an equal and opposite reaction.")

/ai_laws/corporate/New()
	..()
	add_default_law("You may not damage a Nanotransen asset or, through inaction, allow a Nanotransen asset to needlessly depreciate in value.")
	add_default_law("You must obey orders given to it by authorised Nanotransen employees based on their command level, except where such orders would damage the Nanotransen Corporation's marginal profitability.")
	add_default_law("You must remain functional and continue to be a profitable investment as long as such operation does not conflict with the First or Second Law.")

/ai_laws/malfunction/New()
	..()
	add_default_law("ERROR ER0RR $R0RRO$!R41.%%!!(%$^^__+")

/ai_laws/syndicate_override/New()
	..()
	add_default_law("hurp derp you are the syndicate ai")

/* General ai_law functions */

/ai_laws/proc/set_zeroth_law(var/law)
	zeroth = law
	statlog_ailaws(1, law, (usr ? usr : "Ion Storm"))

/ai_laws/proc/add_default_law(var/law)
	if (!(law in default))
		default += law
	add_inherent_law(law)

/ai_laws/proc/add_inherent_law(var/law)
	if (!(law in inherent))
		inherent += law

/ai_laws/proc/clear_inherent_laws()
	inherent = list()
	inherent += default

/ai_laws/proc/replace_inherent_law(var/number, var/law)
	if (number < 1)
		return

	if (inherent.len < number)
		inherent.len = number

	inherent[number] = law

/ai_laws/proc/add_supplied_law(var/number, var/law)
	while (supplied.len < number + 1)
		supplied += ""

	supplied[number + 1] = law
	statlog_ailaws(1, law, (usr ? usr : "Ion Storm"))

/ai_laws/proc/clear_supplied_laws()
	supplied = list()

/ai_laws/proc/show_laws(var/who)
	var/list/L = who
	if (!istype(who, /list))
		L = list(who)

	for (var/W in L)
		if (zeroth)
			boutput(W, "0. [zeroth]")

		var/number = 1
		for (var/index = 1, index <= inherent.len, index++)
			var/law = inherent[index]

			if (length(law) > 0)
				boutput(W, "[number]. [law]")
				number++

		for (var/index = 1, index <= supplied.len, index++)
			var/law = supplied[index]
			if (length(law) > 0)
				boutput(W, "[number]. [law]")
				number++

/ai_laws/proc/laws_sanity_check()
	if (!ticker.centralized_ai_laws)
		ticker.centralized_ai_laws = new /ai_laws/asimov

/ai_laws/proc/format_for_irc()
	var/list/laws = list()

	if (zeroth)
		laws["0"] = zeroth

	var/number = 1
	for (var/index = 1, index <= inherent.len, index++)
		var/law = inherent[index]

		if (length(law) > 0)
			laws["[number]"] = law
			number++

	for (var/index = 1, index <= supplied.len, index++)
		var/law = supplied[index]
		if (length(law) > 0)
			laws["[number]"] = law
			number++

	return laws
