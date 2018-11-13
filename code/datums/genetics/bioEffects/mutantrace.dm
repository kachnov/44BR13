/bioEffect/mutantrace
	name = "Saurian Genetics"
	desc = "Enables vestigal non-mammal traits in the subject's body."
	id = "lizard"
	mutantrace_option = "Lizard"
	effectType = effectTypeMutantRace
	probability = 33
	msgGain = "Your skin feels oddly dry."
	msgLose = "Your scales fall off."
	mob_exclusive = /mob/living/carbon/human/
	var/mutantrace_path = /mutantrace/lizard
	lockProb = 33
	lockedGaps = 1
	lockedDiff = 4
	lockedChars = list("G","C")
	lockedTries = 8
	curable_by_mutadone = 0

	OnAdd()
		if (istype(owner,/mob/living/carbon/human))
			var/mob/living/carbon/human/H = owner
			for (var/ID in H.bioHolder.effects)
				// clear away any existing mutantraces first
				if (istype(H.bioHolder.GetEffect(ID), /bioEffect/mutantrace) && ID != id)
					H.bioHolder.RemoveEffect(ID)
			H.set_mutantrace(mutantrace_path)
		return

	OnRemove()
		if (istype(owner,/mob/living/carbon/human))
			var/mob/living/carbon/human/H = owner
			if (istype(H.mutantrace,mutantrace_path))
				H.set_mutantrace(null)
		return

	OnLife()
		if (istype(owner,/mob/living/carbon/human))
			var/mob/living/carbon/human/H = owner
			if (!istype(H.mutantrace, mutantrace_path))
				holder.RemoveEffect(id)
		return

/bioEffect/mutantrace/flashy
	name = "Bioluminescent Overdrive"
	desc = "Enables highly bioluminescent cells in the subject's skin."
	id = "flashman"
	mutantrace_option = "Flashy"
	mutantrace_path = /mutantrace/flashy
	msgGain = "Your skin begins flashing!"
	msgLose = "Your flashy glow fades away."

/bioEffect/mutantrace/blank
	name = "Melanin Eraser"
	desc = "Shuts down all melanin production in subject's body, and eradicates all existing melanin."
	id = "blankman"
	mutantrace_option = "Blank"
	mutantrace_path = /mutantrace/blank
	msgGain = "You feel oddly plain."
	msgLose = "You don't feel boring anymore."

/bioEffect/mutantrace/skeleton
	name = "Ossification"
	desc = "Compacts the subject's living tissues into their skeleton. This is somehow not fatal."
	id = "skeleton"
	mutantrace_option = "Skeleton"
	mutantrace_path = /mutantrace/skeleton
	msgGain = "You feel kinda thin."
	msgLose = "You've put on a bit more weight."

/bioEffect/mutantrace/ithillid
	name = "Aquatic Genetics"
	desc = "Re-enables ancient vestigal genes in the subject's body."
	id = "ithillid"
	mutantrace_option = "Squid"
	mutantrace_path = /mutantrace/ithillid
	msgGain = "You feel wet and squishy."
	msgLose = "You feel dry."

/bioEffect/mutantrace/dwarf
	name = "Dwarfism"
	desc = "Greatly reduces the overall size of the subject, resulting in markedly dimished height."
	id = "dwarf"
	mutantrace_option = "Dwarf"
	mutantrace_path = /mutantrace/dwarf
	msgGain = "Did everything just get bigger?"
	msgLose = "You feel tall!"

/bioEffect/mutantrace/roach
	name = "Blattodean Genetics"
	desc = "Re-enables ancient vestigal genes in the subject's body."
	id = "roach"
	mutantrace_option = "Roach"
	mutantrace_path = /mutantrace/roach
	msgGain = "You feel like crawling into somewhere nice and dark."
	msgLose = "You shed your roachy skin!"

/bioEffect/mutantrace/monkey
	name = "Primal Genetics"
	desc = "Enables and exaggerates vestigal ape traits."
	id = "monkey"
	mutantrace_option = "Monkey"
	mutantrace_path = /mutantrace/monkey
	research_level = 3
	msgGain = "You go bananas!"
	msgLose = "You do the evolution."