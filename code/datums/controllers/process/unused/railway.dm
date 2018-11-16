PROCESS(railway)
	var/list/vehicles

/controller/process/railway/setup()
	name = "Railways"
	schedule_interval = 0.5 SECONDS
	vehicles = global.railway_vehicles

/controller/process/railway/doWork()
	var/c = 0
	for (var/vehicle in vehicles)
		var/obj/railway_vehicle/v = vehicle
		v.process()
		if (!(c++ % 10))
			scheck()
