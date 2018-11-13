// handles air processing.
/controller/process/air_system
	setup()
		name = "Atmos"
		schedule_interval = 10 // 2.5 seconds
		
		if (!air_master)
			air_master = new /controller/air_system()
			air_master.setup(src)
		air_master.set_controller(src)

	doWork()
		#define NOAIR
		#ifndef NOAIR
		air_master.process()
		#endif 
		#undef NOAIR
		
	copyStateFrom(var/controller/process/target)
		air_master.set_controller(src)