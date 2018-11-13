/atom/movable/proc/face(var/atom/movable/other)
	dir = get_dir(src, other)
	
// todo, improve this - Kachnov
/atom/movable/proc/forceMove(var/atom/target)
	loc = target