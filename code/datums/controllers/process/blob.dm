//Handles blobs without being pissy about it
PROCESS(blob)
	var/list/blobs = list()
	var/tmp/list/detailed_count
	var/tmp/updateQueue/blobUpdateQueue

/controller/process/blob/setup()
	name = "Blob"
	schedule_interval = 31 // 3.1 seconds
	detailed_count = new
	blobUpdateQueue = new

/controller/process/blob/doWork()
	for (var/obj/blob/B in blobs)
		if (B.runOnLife || B.poison)
			B.Life()
			scheck()

	/*var/currentTick = ticks

	for (var/obj/blob/B in blobs)
		if (prob (B.life_prob))
			B.Life()

		detailed_count["[B.type]"]++

		scheck(currentTick)*/

/controller/process/blob/tickDetail()
	if (detailed_count && detailed_count.len)
		var/stats = "<strong>Blob Stats:</strong><br>"
		var/count
		for (var/thing in detailed_count)
			count = detailed_count[thing]
			stats += "[thing] processed [count] times. Total blobs: [blobs.len]<br>"
		boutput(usr, "<br>[stats]")