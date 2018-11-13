/geneticsrecipe
	var/list/required_effects = list()
	var/result = null

// Beneficial

/geneticsrecipe/breathless
	required_effects = list("adrenaline","ithillid")
	result = /bioEffect/breathless

/geneticsrecipe/hulk // Discovered
	required_effects = list("strong","radioactive")
	result = /bioEffect/hulk

/geneticsrecipe/xray // Discovered
	required_effects = list("eyebeams","blind")
	result = /bioEffect/xray

/geneticsrecipe/regenerator // Discovered
	required_effects = list("adrenaline","healing_touch")
	result = /bioEffect/regenerator

/geneticsrecipe/toxic_farts
	required_effects = list("farty","stinky")
	result = /bioEffect/toxic_farts

/geneticsrecipe/thermal_res
	required_effects = list("fire_resist","cold_resist")
	result = /bioEffect/thermalres

/geneticsrecipe/fire_resist // Discovered
	required_effects = list("immolate","glowy")
	result = /bioEffect/fireres

/geneticsrecipe/cold_resist // Discovered
	required_effects = list("cryokinesis","glowy")
	result = /bioEffect/coldres

/geneticsrecipe/rad_resist // Discovered
	required_effects = list("radioactive","glowy")
	result = /bioEffect/rad_resist

/geneticsrecipe/alch_resist
	required_effects = list("drunk","detox")
	result = /bioEffect/alcres

/geneticsrecipe/radio_brain
	required_effects = list("psy_resist","loud_voice")
	result = /bioEffect/radio_brain

// Detrimental

/geneticsrecipe/unintelligable // Discovered
	required_effects = list("loud_voice","quiet_voice")
	result = /bioEffect/speech/unintelligable

/geneticsrecipe/unintelligable_two
	required_effects = list("accent_swedish","accent_elvis")
	result = /bioEffect/speech/unintelligable

/geneticsrecipe/vowels
	required_effects = list("accent_swedish","accent_chav")
	result = /bioEffect/speech/vowelitis

/geneticsrecipe/coprolalia
	required_effects = list("accent_chav","accent_tommy")
	result = /bioEffect/coprolalia

/geneticsrecipe/epilepsy
	required_effects = list("bad_eyesight","flashy")
	result = /bioEffect/epilepsy

/geneticsrecipe/blind
	required_effects = list("bad_eyesight","narcolepsy")
	result = /bioEffect/blind

/geneticsrecipe/mute // Discovered
	required_effects = list("quiet_voice","screamer")
	result = /bioEffect/mute

/geneticsrecipe/drunk // Discovered
	required_effects = list("detox","stinky")
	result = /bioEffect/drunk

/geneticsrecipe/radioactive
	required_effects = list("aura","stinky")
	result = /bioEffect/radioactive

/geneticsrecipe/mutagenic_field
	required_effects = list("radioactive","involuntary_teleporting")
	result = /bioEffect/mutagenic_field

/geneticsrecipe/tourettes
	required_effects = list("clumsy","coprolalia")
	result = /bioEffect/tourettes

// Useless

/geneticsrecipe/glowy_one
	required_effects = list("shiny","albinism")
	result = /bioEffect/glowy

/geneticsrecipe/glowy_two
	required_effects = list("shiny","melanism")
	result = /bioEffect/glowy

/geneticsrecipe/glowy_three
	required_effects = list("aura","shiny")
	result = /bioEffect/glowy

/geneticsrecipe/shiny
	required_effects = list("glowy","aura")
	result = /bioEffect/particles

/geneticsrecipe/aura
	required_effects = list("glowy","shiny")
	result = /bioEffect/aura

/geneticsrecipe/fire_aura_one
	required_effects = list("aura","immolate")
	result = /bioEffect/fire_aura

/geneticsrecipe/fire_aura_two
	required_effects = list("aura","fire_breath")
	result = /bioEffect/fire_aura

/geneticsrecipe/strong
	required_effects = list("fat","detox")
	result = /bioEffect/strong

/geneticsrecipe/stinky
	required_effects = list("farty","dead_scan")
	result = /bioEffect/stinky

/geneticsrecipe/bee
	required_effects = list("roach","detox")
	result = /bioEffect/bee

// Powers

/geneticsrecipe/telekinesis // Discovered
	required_effects = list("telepathy","radio_brain")
	result = /bioEffect/power/telekinesis_drag

/geneticsrecipe/eyebeams // Discovered
	required_effects = list("bad_eyesight","glowy")
	result = /bioEffect/power/eyebeams

/geneticsrecipe/superfart // Discovered
	required_effects = list("loud_voice","farty")
	result = /bioEffect/power/superfart

/geneticsrecipe/cryokinesis
	required_effects = list("chime_snaps","fire_resist")
	result = /bioEffect/power

/geneticsrecipe/adrenaline
	required_effects = list("detox","strong")
	result = /bioEffect/power/adrenaline

/geneticsrecipe/jumpy
	required_effects = list("strong","monkey")
	result = /bioEffect/power/jumpy

/geneticsrecipe/telepath
	required_effects = list("psy_resist","quiet_voice")
	result = /bioEffect/power/telepathy

/geneticsrecipe/midas
	required_effects = list("chime_snaps","drunk")
	result = /bioEffect/power/midas

/geneticsrecipe/midas_two // Discovered
	required_effects = list("chime_snaps","shiny")
	result = /bioEffect/power/midas

/geneticsrecipe/healing_touch // Discovered
	required_effects = list("midas","detox")
	result = /bioEffect/power/healing_touch

/geneticsrecipe/dimension_shift // Discovered
	required_effects = list("radio_brain","involuntary_teleporting")
	result = /bioEffect/power/dimension_shift

/geneticsrecipe/fire_breath
	required_effects = list("cough","immolate")
	result = /bioEffect/power/fire_breath

/geneticsrecipe/bigpuke
	required_effects = list("cough","drunk")
	result = /bioEffect/power/bigpuke

/geneticsrecipe/bigpuke_two
	required_effects = list("cough","stinky")
	result = /bioEffect/power/bigpuke

/geneticsrecipe/ink_one
	required_effects = list("ithillid","melanism")
	result = /bioEffect/power/ink

/geneticsrecipe/ink_two
	required_effects = list("ithillid","shiny")
	result = /bioEffect/power/ink

/geneticsrecipe/photokinesis // Discovered
	required_effects = list("glowy","psy_resist")
	result = /bioEffect/power/photokinesis

/geneticsrecipe/photokinesis_two
	required_effects = list("shiny","psy_resist")
	result = /bioEffect/power/photokinesis

/geneticsrecipe/photokinesis_three
	required_effects = list("aura","psy_resist")
	result = /bioEffect/power/photokinesis

/geneticsrecipe/erebokinesis_one
	required_effects = list("cloak_of_darkness","psy_resist")
	result = /bioEffect/power/erebokinesis

/geneticsrecipe/erebokinesis_two
	required_effects = list("chameleon","psy_resist")
	result = /bioEffect/power/erebokinesis

/geneticsrecipe/erebokinesis_three
	required_effects = list("uncontrollable_cloak","psy_resist")
	result = /bioEffect/power/erebokinesis

/geneticsrecipe/brown_note
	required_effects = list("farty","loud_voice")
	result = /bioEffect/power/brown_note

/geneticsrecipe/brown_note_two
	required_effects = list("stinky","loud_voice")
	result = /bioEffect/power/brown_note

/geneticsrecipe/cloak_of_darkness // Discovered
	required_effects = list("uncontrollable_cloak","melanism")
	result = /bioEffect/power/darkcloak

/geneticsrecipe/chameleon // Discovered
	required_effects = list("uncontrollable_cloak","albinism")
	result = /bioEffect/power/chameleon

/geneticsrecipe/chameleon_two
	required_effects = list("uncontrollable_cloak","examine_stopper")
	result = /bioEffect/power/chameleon

// Mutantraces

/geneticsrecipe/seenoevil
	required_effects = list("blind","deaf","mute")
	result = /bioEffect/mutantrace/monkey
	// since the station starts with monkey already researched we dont really need multiple recipes
	// this one's just for comedy's sake =v

/geneticsrecipe/squid // Discovered
	required_effects = list("fat","stinky")
	result = /bioEffect/mutantrace/ithillid

/geneticsrecipe/squid_two
	required_effects = list("fat","melt")
	result = /bioEffect/mutantrace/ithillid

/geneticsrecipe/roach // Discovered
	required_effects = list("stinky","bee")
	result = /bioEffect/mutantrace/roach

/geneticsrecipe/roach_two
	required_effects = list("radioactive","bee")
	result = /bioEffect/mutantrace/roach

/geneticsrecipe/flashy
	required_effects = list("glowy","radioactive")
	result = /bioEffect/mutantrace/flashy

/geneticsrecipe/flashy_two
	required_effects = list("glowy","chameleon")
	result = /bioEffect/mutantrace/flashy

/geneticsrecipe/flashy_three // Discovered
	required_effects = list("glowy","epilepsy")
	result = /bioEffect/mutantrace/flashy

/geneticsrecipe/lizard
	required_effects = list("horns","chameleon")
	result = /bioEffect/mutantrace

/geneticsrecipe/lizard_two
	required_effects = list("horns","fire_resist")
	result = /bioEffect/mutantrace

/geneticsrecipe/dwarf // Discovered
	required_effects = list("strong","resist_alcohol")
	result = /bioEffect/mutantrace/dwarf

/geneticsrecipe/dwarf_two
	required_effects = list("strong","drunk")
	result = /bioEffect/mutantrace/dwarf

/geneticsrecipe/dwarf_three // Discovered
	required_effects = list("strong","fat")
	result = /bioEffect/mutantrace/dwarf

/geneticsrecipe/blank // Discovered
	required_effects = list("albinism","melanism")
	result = /bioEffect/mutantrace/blank

/geneticsrecipe/skeleton // Discovered
	required_effects = list("screamer","dead_scan")
	result = /bioEffect/mutantrace/skeleton

/geneticsrecipe/skeleton_two
	required_effects = list("cloak_of_darkness","dead_scan")
	result = /bioEffect/mutantrace/skeleton

/geneticsrecipe/skeleton_three
	required_effects = list("xray","dead_scan")
	result = /bioEffect/mutantrace/skeleton