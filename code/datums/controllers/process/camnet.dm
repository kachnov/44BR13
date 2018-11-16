PROCESS(camnets)

/controller/process/camnets/setup()
	name = "Camera Networks"
	schedule_interval = 3 SECONDS

/controller/process/camnets/doWork()
	rebuild_camera_network() //Will only actually do something if it needs to.