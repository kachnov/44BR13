# Changes variables set to null implicity (var/example) to set to null explicitly (var/example = null)
# Copyright Kachnov
# Note: this file doesn't work as intended right now; it places the "= null" on another line. Also, there are a few false positives. 
# It's more useful for identifying the issue, not fixing it.

# imports
from pathlib import Path
import os

# gets the main 44BR13 directory
dir = os.path.abspath(os.path.join(os.getcwd(), os.pardir))

# gets the code folder directory
codedir = dir + "/code"
	
# go through every file in codedir (recursively)
pathlist = Path(codedir).glob('**/*.dm')
for path in pathlist:
    # because path is an object
	path = str(path)
	file = open(path, "r")
	lines = []
	
	# runtimes can break the whole loop without this
	try:
		lines = file.readlines()
	except:
		file.close()
		continue
		
	curindex = -1
	for line in lines:
		curindex += 1
		if "var/" in line and not "=" in line:
			split_line = line.split("/")
			for i in range(len(split_line)):
				part = split_line[i]
				if part == "var":
					try:
						ii = i
						part = split_line[ii]
						cont = True
						# the "var" or "datum" in var/datum/D
						while "{}/".format(part) in line:
							ii += 1
							try:
								part = split_line[ii]
							except:
								cont = False
								break
						if cont:
							lines[curindex] += " = null"
					except:
						break
		
	file.close()
	
	# actually rewrite the entire file, with new lines
	file = open(path, "w")
	for line in lines:
		file.write(line)
	file.close()