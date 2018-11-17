REPO_LIST(dirs, list(NORTH, SOUTH, EAST, WEST, NORTHEAST, NORTHWEST, SOUTHEAST, SOUTHWEST))
REPO_LIST(ordinals, list(NORTHEAST, NORTHWEST, SOUTHEAST, SOUTHWEST))
REPO_LIST(cardinals, list(NORTH, SOUTH, EAST, WEST))

/proc/opposite_dir(dir)
	switch (dir)
		if (NORTH)
			return SOUTH 
		if (SOUTH)
			return NORTH 
		if (EAST)
			return WEST
		if (WEST)
			return EAST
		if (NORTHEAST)
			return SOUTHWEST
		if (NORTHWEST)
			return SOUTHEAST 
		if (SOUTHEAST)
			return NORTHWEST 
		if (SOUTHWEST)
			return NORTHEAST