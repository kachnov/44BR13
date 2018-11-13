#define STAT_SPEED "speed"
#define STAT_STRENGTH "strength"
#define STAT_IQ "iq"

#define OK_SPEED_THRESHOLD 0.7 
#define GREAT_SPEED_THRESHOLD 1.5

#define OK_STRENGTH_THRESHOLD 0.7  
#define GREAT_STRENGTH_THRESHOLD 1.5 

#define PILL_BOTTLE_IQ_REQUIREMENT 65

/statHolder
	var/mob/owner = null
	var/stats = list(
		STAT_SPEED = 1.00,
		STAT_STRENGTH = 1.00,
		STAT_IQ = 100.0
	)
	
/statHolder/New(_owner)
	..()
	owner = _owner
	
/statHolder/proc/setStat(name, val)
	stats[name] = val
	
/statHolder/proc/getStat(n)
	return stats[n]
	
/statHolder/proc/getResistTimeDivisor()
	. = getStat(STAT_STRENGTH)
	if (owner && isxenomorph(owner))
		. *= 10