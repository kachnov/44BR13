# Creates the directory "extra/mapbuild/44BR13/code" which contains path types and their icons but nothing else.
# This can be used to map the game, but not run it. Copyright Kachnov.
# ALSO: there are a few compile errors that need to be fixed when you regenerate the mapbuild code!

# imports
from pathlib import Path
import os

# gets the main 44BR13 directory
dir = os.path.abspath(os.path.join(os.getcwd(), os.pardir))

# gets the code folder directory
readdir = dir + "/code"

# go through every file in codedir (recursively)
pathlist = Path(readdir).glob('**/*.dm')
for path in pathlist:
    # because path is an object
	path = str(path)
	file = open(path, "r")
	lines = []
	nlines = []
	# runtimes can break the whole loop without this
	try:
		lines = file.readlines()
	except:
		file.close()
		continue
		
	atomcheck = lambda line: line.startswith("/atom") or line.startswith("/obj") or line.startswith("/mob") or line.startswith("/turf") or line.startswith("/area")
	iconcheck = lambda line: "icon='" in line or "icon= '" in line or "icon_state=\"" in line or "icon_state= \"" in line
	namecheck = lambda line: "	name=" in line or "	name =" in line
	layercheck = lambda line: "layer=" in line or "layer =" in line
	planecheck = lambda line: "plane=" in line or "plane =" in line
	othercheck = lambda line: iconcheck(line) or namecheck(line) or layercheck(line) or planecheck(line)

	index = -1
	allow_metadata_checks = False

	for line in lines:
		index += 1
		if atomcheck(line):
			# not a proc, not a verb, not a list item
			if not "/proc" in line and not "/verb" in line and not "," in line and not line.rstrip().endswith(")"):
				nlines.append(line)
				allow_metadata_checks = True 
			else:
				allow_metadata_checks = False
		# this block is disable because some variables are needed for the map to compile
		#elif not othercheck(line):
			#allow_metadata_checks = False 
		elif not "#" in line:
			if allow_metadata_checks:
				nlines.append(line)
			allow_metadata_checks = False 
			
	file.close()
	
	# where are we writing 
	wpath = path.replace("/code", "/extras/mapbuild/44BR13/code")
	
	# make the current directory if it doesn't exist 
	os.makedirs(os.path.dirname(wpath), exist_ok=True)
	
	# actually rewrite the entire file, with new lines
	if len(nlines):
		file = open(wpath, "w")
		for line in nlines:
			file.write(line)
		file.close()