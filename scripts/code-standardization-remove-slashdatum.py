# removes all unnecessary instances of /datum
# Copyright Kachnov

# imports
from pathlib import Path
import os
import re

# gets the main 44BR13 directory
dir = os.path.abspath(os.path.join(os.getcwd(), os.pardir)) + "/44BR13"

# gets the code folder directory
codedir = dir + "/code"

# keep a list of every file paired with its lines
file2lines = dict()

# keep a list of all typepaths we need to replace
typepaths = []

# go through every file in codedir (recursively)
pathlist = Path(codedir).glob('**/*.dm')
for path in pathlist:

    # because path is an object
	path = str(path)
	file = open(path, "r") # rU prevents a few files from excepting
	lines = None
	
	# runtimes can break the whole loop without this
	# try to read each file 3x to prevent false-positives
	try:
		lines = file.readlines()
	except:
		file.close()
		continue

	file2lines[path] = []

	for line in lines:
		sline = line.strip()

		linecheck = lambda line : not "(" in line and not ")" in line and not "=" in line and not "\\" in line and not "," in line

		# any /datum definition that is not /datum itself
		if (sline.startswith("/datum/") or sline.startswith("datum/")) and sline != "/datum" and sline != "datum" and linecheck(sline):
			typepaths.append(sline)
			if sline.startswith("/"):
				typepaths.append(sline[1:])

		file2lines[path].append(line)

	file.close()

pathlist = Path(codedir).glob('**/*.dm') # why the fuck is this necessary? who knows
for path in file2lines:

	# because path is an object
	file = open(path, "w")

	nlines = []
	for line in file2lines[path]:
		for typepath in typepaths:
			if typepath in line:
				line = line.replace(typepath, typepath.replace("datum/", ""))
		nlines.append(line)

	for line in nlines:
		file.write(line)

	file.close()