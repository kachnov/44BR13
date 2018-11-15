# removes all immediate relative paths by checking levels of tabs
# /datum
#	subtype
# Copyright Kachnov
# this is incomplete and does not work

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

	searching = False
	procmode = False
	varmode = False

	for line in lines:

		defcheck = lambda line: line.startswith("/") and not line.startswith("//") and not line.startswith("/*")
		comcheck = lambda line: line.startswith("//") or line.startswith("/*") or line.startswith("*/")
		linecheck = lambda line : not "(" in line and not ")" in line and not "=" in line and not "\\" in line and not "," in line
		procargscheck = lambda line: "(" in line and ")" in line and line.rfind(")") > line.rfind("=")

		sline = line.strip()

		tabcount = line.count("\t")
		if searching and defcheck(sline) and tabcount == 0:
			searching = False

		if searching == False:
			# we found a /datum definition, now start searching beneath it
			if defcheck(sline) and linecheck(sline):
				searching = sline
				# remove comments
				while "//" in searching:
					searching = searching[:len(searching)-2] # two characters at a time
				searching = searching.strip() # remove the trailing space
				# remove any trailing slash
				if searching.endswith("/"):
					searching = searching[:len(searching)-1]
				searching = searching.strip() # remove the trailing space
		else:
			# probably a subtype (that doesn't start with /) or a proc definition/override
			# no vars allowed
			if (tabcount == 0 or tabcount == 1) and (sline[:1].isalpha() or sline[:1] == "_"):

				# spaces can fuck off
				if tabcount == 0:
					line = "\t{}".format(sline)

				# since var/ absolute pathing is ok, these cases are completely ignored.
				if not sline.startswith("var/"):

					if (not "=" in line) or procargscheck(sline):

						if not sline in ["var", "proc"]:

							procmode = False
							varmode = False

							# remove one tab 
							line = line.replace("\t", "", 1)
							# make the line absolutely pathed
							line = searching+"/"+line

						else:

							if sline == "proc":
								line = ""
								procmode = True
							else:
								line = ""
								varmode = True

			# something in the definition
			elif tabcount > 1:
				if procmode:
					if tabcount == 2:
						# remove all tabs
						line = line.replace("\t", "")
						# make the line absolutely pathed
						line = searching+"/proc/"+line
					else:
						# remove two tabs
						line = line.replace("\t", "", 2)
				elif varmode:
					#remove one tab
					line = line.replace("\t", "", 1)
					# make the line absolutely pathed
					line = "var/"+line
				else:
					# remove one tab
					line = line.replace("\t", "", 1)

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