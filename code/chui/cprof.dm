#ifdef DEBUG

/cprofiler
	var/static/list/CPROF_STKN = list()
	var/static/list/CPROF_STKT = list()
	var/static/list/CPROF_L = list()
	var/static/list/CPROF_ACTV = list()
	var/static/list/CPROF_STACK = list()

/cprofiler/proc/begin(name)
	CPROF_STACK += list()
		//CPROF_ACTV  =

//TODO; #ifdef BTIME
#define CPROF_GTIME (world.timeofday)
#define CPROF_PRECISION 10//10 GTIME/s

#define CPROF(name) CPROFILER.begin(name)
