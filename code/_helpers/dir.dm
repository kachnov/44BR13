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