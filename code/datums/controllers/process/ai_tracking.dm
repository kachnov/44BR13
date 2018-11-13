/controller/process/ai_tracking

	setup()
		name = "AI Tracking"
		schedule_interval = 10

	doWork()
		for (var/ai_camera_tracker/T in global.tracking_list)
			T.process()

			scheck()
