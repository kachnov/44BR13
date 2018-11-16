PROCESS(networks)
	var/updateQueue/networkUpdateQueue
	
/controller/process/networks/setup()
	name = "Networks"
	schedule_interval = 1.1 SECONDS
	networkUpdateQueue = list()

/controller/process/networks/doWork()
	for (var/node_network in node_networks)
		var/node_network/N = node_network
		N.update()
		scheck()
		/*
		var/currentTick = ticks
		for (var/node_network/network in node_networks)
			network.update()
			scheck(currentTick)*/