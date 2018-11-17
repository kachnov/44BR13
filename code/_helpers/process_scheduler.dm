// Process Scheduler defines
// Process status defines
#define PROCESS_STATUS_IDLE 1
#define PROCESS_STATUS_QUEUED 2
#define PROCESS_STATUS_RUNNING 3
#define PROCESS_STATUS_MAYBE_HUNG 4
#define PROCESS_STATUS_PROBABLY_HUNG 5
#define PROCESS_STATUS_HUNG 6

// Process time thresholds
#define PROCESS_DEFAULT_HANG_WARNING_TIME 	3000 // 300 seconds
#define PROCESS_DEFAULT_HANG_ALERT_TIME 	6000 // 600 seconds
#define PROCESS_DEFAULT_HANG_RESTART_TIME 	9000 // 900 seconds
#define PROCESS_DEFAULT_SCHEDULE_INTERVAL 	50  // 50 ticks
#define PROCESS_DEFAULT_TICK_ALLOWANCE		66	// 66% of one tick

// process priorities
#define PROCESS_PRIORITY_LOWEST 0
#define PROCESS_PRIORITY_AIR 1
#define PROCESS_PRIORITY_GARBAGE 2
#define PROCESS_PRIORITY_WORLD 3
#define PROCESS_PRIORITY_TICKER 4
#define PROCESS_PRIORITY_STOCK_MARKET 5
#define PROCESS_PRIORITY_CAMNET 6
#define PROCESS_PRIORITY_RESEARCH 7 
#define PROCESS_PRIORITY_TELESCOPE 8
#define PROCESS_PRIORITY_NETWORKS 9
#define PROCESS_PRIORITY_BLOB 10
#define PROCESS_PRIORITY_MACHINES 11
#define PROCESS_PRIORITY_ITEMS 12
#define PROCESS_PRIORITY_WEEDS 13
#define PROCESS_PRIORITY_EXPLOSIONS 14
#define PROCESS_PRIORITY_CHEMISTRY 15
#define PROCESS_PRIORITY_CRITTERS 16
#define PROCESS_PRIORITY_MOB_AI 17
#define PROCESS_PRIORITY_MOBS 18
#define PROCESS_PRIORITY_ACTIONS 19
#define PROCESS_PRIORITY_PARTICLES 20
#define PROCESS_PRIORITY_CHAIRS 21
#define PROCESS_PRIORITY_MOVEMENT 22