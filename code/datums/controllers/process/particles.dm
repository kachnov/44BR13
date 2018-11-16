PROCESS(particles)
	priority = PROCESS_PRIORITY_PARTICLES
	var/particleMaster/master

/controller/process/particles/setup()
	name = "Particles"
	schedule_interval = 1.2 SECONDS
	
	// putting this in a var so main loop varedit can get into the particleMaster
	master = particleMaster
		
/controller/process/particles/doWork()		
	// TODO roll the "loop" code from particleMaster back into this system
	master.Tick()
	
// regular timing doesn't really apply since particles abuse the shit out of spawn and sleep
/controller/process/particles/tickDetail()
	return "particle types: [master.particleTypes.len], particle systems: [master.particleSystems.len]<br>"

