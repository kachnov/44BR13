// i think its slightly faster to do this with compiler macros instead of procs. i might be a moron, not sure - drsingh
// it is. no comment on the moron bit. -- marq

#define isdatum(x) istype(x, /datum)
#define isclient(x) istype(x, /client)
#define ismob(x) istype(x, /mob)
#define isnewplayer(x) istype(x, /mob/new_player)
#define isobserver(x) istype(x, /mob/dead)
#define isadminghost(x) x.client && x.client.holder && rank_to_level(x.client.holder.rank) >= LEVEL_MOD && (istype(x, /mob/dead/observer) || istype(x, /mob/dead/target_observer)) // For antag overlays.

#define isliving(x) istype(x, /mob/living)
#define iscarbon(x) istype(x, /mob/living/carbon)
#define ismonkey(x) (istype(x, /mob/living/carbon/human) && istype(x:mutantrace, /mutantrace/monkey))
#define ishuman(x) istype(x, /mob/living/carbon/human)
#define iscritter(x) istype(x, /mob/living/critter)

#define issilicon(x) istype(x, /mob/living/silicon)
#define isrobot(x) istype(x, /mob/living/silicon/robot)
#define ishivebot(x) istype(x, /mob/living/silicon/hivebot)
#define ismainframe(x) istype(x, /mob/living/silicon/hive_mainframe)
#define isAI(x) istype(x, /mob/living/silicon/ai)
#define isshell(x) istype(x, /mob/living/silicon/hivebot/eyebot)//istype(x, /mob/living/silicon/shell)
#define isdrone(x) istype(x, /mob/living/silicon/hivebot/drone)
#define isghostdrone(x) istype(x, /mob/living/silicon/ghostdrone)

#define isbot(x) istype(x, /obj/machinery/bot)
#define issecbot(x) istype(x, /obj/machinery/bot/secbot)
#define isdoor(x) istype(x, /obj/machinery/door)

// I'm grump that we don't already have these so I'm adding them.  will we use all of them? probably not.  but we have them. - Haine
// Hi, Marquesas here. Eliminating all ':' would be nice. Can we do that somehow? Thanks.

// Macros with abilityHolder or mutantrace defines are used for more than antagonist checks, so don't replace them with mind.special_role.
#define istraitor(x) (istype(x, /mob/living/carbon/human) && x:mind && x:mind:special_role == "traitor")
#define ischangeling(x) (istype(x, /mob/living/carbon/human) && x:get_ability_holder(/abilityHolder/changeling) != null)
#define isabomination(x) (istype(x, /mob/living/carbon/human) && x:mutantrace && istype(x:mutantrace, /mutantrace/abomination))
#define isnukeop(x) (istype(x, /mob/living/carbon/human) && x:mind && x:mind:special_role == "nukeop")
#define isvampire(x) ((istype(x, /mob/living/carbon/human) || istype(x, /mob/living/critter)) && x:get_ability_holder(/abilityHolder/vampire) != null)
#define iswizard(x) ((istype(x, /mob/living/carbon/human) || istype(x, /mob/living/critter)) && x:get_ability_holder(/abilityHolder/wizard) != null)
#define ispredator(x) (istype(x, /mob/living/carbon/human) && x:mutantrace && istype(x:mutantrace, /mutantrace/predator))
#define iswerewolf(x) (istype(x, /mob/living/carbon/human) && x:mutantrace && istype(x:mutantrace, /mutantrace/werewolf))
#define iswrestler(x) ((istype(x, /mob/living/carbon/human) || istype(x, /mob/living/critter)) && x:get_ability_holder(/abilityHolder/wrestler) != null)
#define iswraith(x) istype(x, /mob/wraith)
#define isintangible(x) istype(x, /mob/living/intangible)

// Why the separate mask check? NPCs don't use assigned_role and we still wanna play the cluwne-specific sound effects.
#define iscluwne(x) (istype(x, /mob/living/carbon/human) && ((x:mind && x:mind.assigned_role && x:mind:assigned_role == "Cluwne") || istype(x:wear_mask, /obj/item/clothing/mask/cursedclown_hat)))

#define isrestrictedz(z) ((z) == 2 || (z) == 4)

#define islist(x) istype(x, /list)
#define isitem(x) istype(x, /obj/item)

#define isxenomorph(x) istype(x, /mob/living/carbon/human/xenomorph)
#define isxenomorphdrone(x) istype(x, /mob/living/carbon/human/xenomorph/drone)
#define isxenomorphcrafter(x) istype(x, /mob/living/carbon/human/xenomorph/crafter)
#define isxenomorphhunter(x) istype(x, /mob/living/carbon/human/xenomorph/hunter)
#define isxenomorphpraetorian(x) istype(x, /mob/living/carbon/human/xenomorph/praetorian)
#define isxenomorphqueen(x) istype(x, /mob/living/carbon/human/xenomorph/queen)
#define isxenomorphlarva(x) istype(x, /mob/living/critter/xenomorph_larva)
#define isfacehugger(x) istype(x, /mob/living/critter/facehugger)
#define ismutt(x) istype(x, /mob/living/carbon/human/mutt)

/proc/is_type_in_list(thing, list)
	for (var/path in list)
		if (istype(thing, path) || ispath(thing, path))
			return TRUE 
	return FALSE

// pick strings from cache-- code/procs/string_cache.dm
#define pick_string(filename, key) pick(strings(filename, key))

#define DEBUG_MESSAGE(x) if (debug_messages) message_coders(x)
#define __red(x) text("<span style='color:red'>[]</span>", x)
#define __blue(x) text("<span style='color:blue'>[]</span>", x)
#define __green(x) text("<span style='color:green'>[]</span>", x)

#ifdef PRECISE_TIMER_AVAILABLE
var/global/__btime__lastTimeOfHour = 0
var/global/__btime__callCount = 0
var/global/__btime__lastTick = 0
#define TimeOfHour __btime__timeofhour()
#define __extern__timeofhour text2num(call("btime.[world.system_type==MS_WINDOWS?"dll":"so"]", "gettime")())
/proc/__btime__timeofhour()
	if (!(__btime__callCount++ % 50))
		if (world.time > __btime__lastTick)
			__btime__callCount = 0
			__btime__lastTick = world.time
		global.__btime__lastTimeOfHour = __extern__timeofhour
	return global.__btime__lastTimeOfHour
#else
#define TimeOfHour world.timeofday % 36000
#endif

#define CLAMP(V, MN, MX) max(MN, min(MX, V))

#define LAGCHECK(x) while (world.tick_usage > x) sleep(world.tick_lag)