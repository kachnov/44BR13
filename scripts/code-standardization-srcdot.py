# removes "src." wherever possible (ie whenever it wouldn't cause a conflict due to variables with the same name)
# Copyright Kachnov
# first applied on Aug 17, 2018. # instances of "src." from 51430 to 1359.

# imports
from pathlib import Path
import os
import re

# gets the main 44BR13 directory
dir = os.path.abspath(os.path.join(os.getcwd(), os.pardir))

# gets the code folder directory
codedir = dir + "/code"

# get the directory of global.dm
globalsdir = codedir + "/global.dm"

# create a list of (most) global vars 
global_variables = []
with open(globalsdir, "r") as file:
	lines = file.readlines()
	recording = False
	for line in lines:
		if line.startswith("// -------------------- GLOBAL VARS --------------------"):
			recording = True
		elif line.startswith("// end global variable definitions"):
			break
		elif not line.startswith("var/global") and "".join(e for e in line if e.isalnum()) != "":
			line_stripped = line.strip()
			if recording and line_stripped != "":
				line_split = line_stripped.split(" = ")
				line_variable = line_split[0]
				if not "\"" in line_variable and not "#" in line_variable and not ")" in line_variable and not "(" in line_variable and not "//" in line_variable:
					line_variable_split = line_variable.split("/")
					line_variable = line_variable_split[len(line_variable_split)-1]
					global_variables.append(line_variable)
	
# go through every file in codedir (recursively)
pathlist = Path(codedir).glob('**/*.dm')
for path in pathlist:
    # because path is an object
	path = str(path)
	file = open(path, "r")
	lines = []
	local_global_variables = []
	
	# runtimes can break the whole loop without this
	try:
		lines = file.readlines()
	except:
		file.close()
		continue
		
	curindex = -1
	for line in lines:
		curindex += 1
		if "var/" in line:
			line_split = line.split("/")
			for i in range(len(line_split)):
				if line_split[i] == "var":
					ii = i+1
					variable = line_split[ii]
					# if this is the "var" or "datum" in var/datum/D
					while (not "{} =".format(variable) in line and not "{}=".format(variable) in line and not "{}/".format(variable) in line):
						ii += 1
						try:
							variable = line_split[ii+1]
						except:
							break
					if not variable in local_global_variables and "".join(e for e in variable if (e.isalnum() or e == "_")) != "":
						local_global_variables.append(variable)
					break
		if "src." in line:
			
			cont = True
			
			# don't modify this line if a var is in global variables
			for variable in global_variables:
				if "src.{}".format(variable) in line:
					cont = False
					break 
					
			# don't modify this line if a var is in local global variables
			if cont:
				for variable in local_global_variables:
					if "src.{}".format(variable) in line:
						cont = False
						break 
				
			# if we have something like "varname = src.varname", don't replace
			if cont:
				splitline = line.split(".")
				for i in range(len(splitline)):
					badvar = splitline[i]
					
					# line without src.badvar, global.badvar, etc
					linetest = line.replace("src.{}".format(badvar), "")
					linetest = linetest.replace("global.{}".format(badvar), "")
					linetest = linetest.replace("M.{}".format(badvar), "")
					linetest = linetest.replace("H.{}".format(badvar), "")
					
					c1 = badvar in linetest
					c2 = "src.{}".format(badvar) in line 
					c3 = "global.{}".format(badvar) in line 
					if (c1 and c2) or (c2 and c3) or (c1 and c3):
						cont = False 
							
			if cont:
				line = line.replace("src.", "")
				lines[curindex] = line
	
	file.close()
	
	# actually rewrite the entire file, with new lines
	file = open(path, "w")
	for line in lines:
		file.write(line)
	file.close()
			
	local_global_variables = []