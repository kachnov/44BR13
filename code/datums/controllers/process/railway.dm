/controller/process/railway
	var/tmp/list/vehicles

	setup()
		name = "Railways"
		schedule_interval = 5
		vehicles = global.railway_vehicles

	doWork()
		var/c = 0
		for (var/vehicle in global.railway_vehicles)
			var/obj/railway_vehicle/v = vehicle
			v.process()
			if (!(c++ % 10))
				scheck()
