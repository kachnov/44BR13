//Parent admin proc, if they have this then they have admin status
//client.holder will be modified to contain this

/admin
	var/name = "admin"

	var/rank = "default"

	var/admin/power/list/powers = list()
//
//Powers contained within parent proc, with an id attributed to each
//Each admin command will be verbs in a subset of powers, that means they
//should be automatically given to the player
/admin/power
	var/id = null

//Coder powers
/admin/power/debug
	name = "debug powers"
	id = 1

//Ban, job ban etc
/admin/power/ban
	name = "banning powers"
	id = 2

//Any jump related procs
/admin/power/teleport
	name = "teleportation powers"
	id = 3

//prison etc
/admin/power/low_admin
	name = "low level admin powers"
	id = 4

//Force say, abusable admin powers
/admin/power/high_admin
	name = "high level admin powers"
	id = 5

//Spawn items, turfs, mobs
/admin/power/spawn_panel
	name = "spawn powers"
	id = 6

//Misc highly abuseable powers
/admin/power/misc_high
	name = "misc high powers"
	id = 7

//Misc low abuse powers
/admin/power/misc_low
	name = "misc low powers"
	id = 8

//Edit/view variables
/admin/power/variables
	name = "variable powers"
	id = 9
