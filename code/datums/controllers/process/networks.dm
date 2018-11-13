/controller/process/networks
	var/tmp/updateQueue/networkUpdateQueue
	
	setup()
		name = "Networks"
		schedule_interval = 11
		networkUpdateQueue = new

	doWork()
		for (var/node_network in node_networks)
			var/node_network/N = node_network
			N.update()
			scheck()
		/*
		var/currentTick = ticks
		for (var/node_network/network in node_networks)
			network.update()
			scheck(currentTick)*/