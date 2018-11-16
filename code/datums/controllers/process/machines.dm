// handles machines
PROCESS(machines)
	priority = PROCESS_PRIORITY_MACHINES
	var/list/machines
	var/list/pipe_networks
	var/list/powernets
	var/list/atmos_machines

/controller/process/machines/setup()
	name = "Machine"
	schedule_interval = 3.3 SECONDS
	Station_VNet = new /v_space/v_space_network()

/controller/process/machines/doWork()
	src.atmos_machines = global.atmos_machines
	var/c = 0
	for (var/obj/machinery/atmospherics/machine in atmos_machines)
		#ifdef MACHINE_PROCESSING_DEBUG
		var/t = world.time
		#endif
		machine.process()
		#ifdef MACHINE_PROCESSING_DEBUG
		register_machine_time(machine, world.time - t)
		#endif

		if (!(c++ % 100))
			scheck()

	pipe_networks = global.pipe_networks
	for (var/pipe_network/network in pipe_networks)
		#ifdef MACHINE_PROCESSING_DEBUG
		var/t = world.time
		#endif
		network.process()
		#ifdef MACHINE_PROCESSING_DEBUG
		register_machine_time(network, world.time - t)
		#endif
		if (!(c++ % 100))
			scheck()

	src.powernets = global.powernets
	for (var/powernet/PN in src.powernets)
		#ifdef MACHINE_PROCESSING_DEBUG
		var/t = world.time
		#endif
		PN.reset()
		#ifdef MACHINE_PROCESSING_DEBUG
		register_machine_time(PN, world.time - t)
		#endif
		if (!(c++ % 100))
			scheck()

	src.machines = global.machines
	for (var/obj/machinery/machine in src.machines)
		#ifdef MACHINE_PROCESSING_DEBUG
		var/t = world.time
		#endif
		machine.process()
		#ifdef MACHINE_PROCESSING_DEBUG
		register_machine_time(machine, world.time - t)
		#endif
		if (!(c++ % 100))
			scheck()


#ifdef MACHINE_PROCESSING_DEBUG
/proc/register_machine_time(var/datum/machine, var/time)
	if (!machine) return
	var/list/mtl = detailed_machine_timings[machine.type]
	if (!mtl)
		mtl = list()
		mtl.len = 2
		mtl[1] = 0	//The amount of time spent processing this machine in total
		mtl[2] = 0	//The amount of times this machine has been processed
		detailed_machine_timings[machine.type] = mtl

	mtl[1] += time
	mtl[2]++
#endif