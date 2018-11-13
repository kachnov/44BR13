/data
	var/name = "data"
	var/size = 1.0
	//name = null
/data/function
	name = "function"
	size = 2.0
/data/function/data_control
	name = "data control"
/data/function/id_changer
	name = "id changer"
/data/record
	name = "record"
	size = 5.0
//
	var/list/fields = list(  )
//
/data/text
	name = "text"
	var/data = null

/station_state
	var/floor = 0
	var/wall = 0
	var/r_wall = 0
	var/window = 0
	var/door = 0
	var/grille = 0
	var/mach = 0

/powernet
	var/list/cables = list()	// all cables & junctions
	var/list/nodes = list()		// all APCs & sources
	var/list/data_nodes = list()// all networked machinery

	var/newload = 0
	var/load = 0
	var/_newavail = 0
	var/_avail = 0

	var/viewload = 0

	var/number = 0

	var/perapc = 0			// per-apc avilability

	var/netexcess = 0

/powernet/proc/get_avail()
	return 100000

/debug
	var/list/debuglist