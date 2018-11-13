from pathlib import Path 
import os

# record number of lines of DM in the code
pathlist = Path(os.getcwd()).glob('**/*.dm')
lines = 0
for path in pathlist:
	with open(str(path), "r") as file:
		try:
			for line in file.readlines():
				lines += 1
			file.close()
		except:
			pass
print(lines)