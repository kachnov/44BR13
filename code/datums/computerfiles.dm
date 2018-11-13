//CONTENTS:
//Base computer datum
//Base Folder
//Base File
//Text files
//Records
//Signal files
//Archive files
//Folder link


//File permission flags
#define COMP_ROWNER 1
#define COMP_WOWNER 2
#define COMP_DOWNER 4
#define COMP_RGROUP 8
#define COMP_WGROUP 16
#define COMP_DGROUP 32
#define COMP_ROTHER 64
#define COMP_WOTHER 128
#define COMP_DOTHER 256

#define COMP_HIDDEN 0
#define COMP_ALLACC 511

/computer
	var/name
	var/size = 4
	var/tmp/obj/item/disk/data/holder = null
	var/tmp/computer/folder/holding_folder = null
	var/tmp/list/metadata = list()

	New()
		..()
		metadata = list("date" = world.realtime, "owner"=null,"group"=null, "permission"=COMP_ALLACC)

		return

	folder
		name = "Folder"
		size = 0
		var/gen = 0
		var/list/computer/contents = list()
		var/tmp/list/linkers = list()
		/* commented by singh, new disposing() pattern should handle this. if i broke everything sorry IBM, SORRY
		Del()
			for (var/computer/F in contents)
				qdel(F)

			for (var/computer/folder/link/L in linkers)
				L.contents = list()

			..()
		*/
		disposing()
			for (var/computer/F in contents)
				F.dispose()

			for (var/computer/folder/link/L in linkers)
				L.contents.len = 0

			..()

		proc
			add_file(computer/R)
				if (!holder || holder.read_only || !R)
					return FALSE
				if (istype(R,/computer/folder) && (gen>=10))
					return FALSE
				if ((holder.file_used + R.size) <= holder.file_amount)
					contents.Add(R)
					R.holder = holder
					R.holding_folder = src
					if (gen)
						if (isnull(R.metadata["owner"]))
							R.metadata["owner"] = metadata["owner"]
						if (isnull(R.metadata["group"]))
							R.metadata["group"] = metadata["group"]
						if (isnull(R.metadata["permission"]) || R.metadata["permission"] == COMP_ALLACC)
							R.metadata["permission"] = metadata["permission"]
					holder.file_used -= size
					size += R.size
					holder.file_used += size
					if (istype(R,/computer/folder))
						R:gen = (gen+1)
					return TRUE

				return FALSE

			remove_file(computer/R)
				if (holder && !holder.read_only && R)
//					boutput(world, "Removing file [R]. File_used: [holder.file_used]")
					contents.Remove(R)
					holder.file_used -= size
					size -= R.size
					holder.file_used += size
					holder.file_used = max(holder.file_used, 0)
//					boutput(world, "Removed file [R]. File_used: [holder.file_used]")
					return TRUE
				return FALSE

			can_add_file(computer/R)
				if (!holder || holder.read_only || !R)
					return FALSE
				if (istype(R,/computer/folder) && (gen>=10))
					return FALSE
				return ((holder.file_used + R.size) <= holder.file_amount)

			copy_folder(var/depth = 0)
				if (depth >= 8)
					return null
				var/computer/folder/F = new type()
				F.name = name
				F.holder = holder
				for (var/computer/C in contents)
					if (istype(C, /computer/file))
						F.add_file(C:copy_file())
					else if (istype(C, /computer/folder))
						F.add_file(C:copy_folder(depth + 1))
				return F


	file
		name = "File"
		var/extension = "FILE" //Differentiate between types of files, why not

		asText()
			return corruptText(pick("Error: Unknown filetype for '[name]'", "Imagine four balls on the edge of a cliff.  Time works the same way.","Packet five loss packet six echo loss packet nine loss packet ten loss gain signal."),60)

		proc
			copy_file_to_folder(computer/folder/newfolder, var/newname)
				if (!newfolder || (!istype(newfolder)) || (!newfolder.holder) || (newfolder.holder.read_only))
					return FALSE

				if ((newfolder.holder.file_used + size) <= newfolder.holder.file_amount)
					var/computer/file/newfile = copy_file()
					if (newname)
						newfile.name = newname

					if (!newfolder.add_file(newfile))
						qdel(newfile)

					return TRUE

				return FALSE

			copy_file() //Just make a replica of self
				var/computer/file/copy = new type

				for (var/V in vars)
					if (issaved(vars[V]))// && V != "holder")
						copy.vars[V] = vars[V]

				if (!copy.metadata)
					copy.metadata = list()
				if (metadata)
					copy.metadata["owner"] = metadata["owner"]
					copy.metadata["permission"] = metadata["permission"]
					copy.metadata["group"] = metadata["group"]

				return copy

			writable()
				if (holder && holder.read_only)
					return FALSE

				return TRUE

	proc/asText() //Convert contents to text, if possible
		return null

	Del()
		if (Debug2)
			logTheThing("debug", null, null, "<strong>Computer Datum:</strong> Del() called on [type] \ref[src] [name]")
		// same as above, XOXOXO. -singh
		//if (holder && holding_folder)
		//	holding_folder.remove_file(src)
		..()

	disposing()
		if (Debug2)
			logTheThing("debug", null, null, "<strong>Computer Datum:</strong> dispose() called on [type] \ref[src] [name]")
		if (holding_folder)
			holding_folder.remove_file(src)
			holding_folder = null

		holder = null
		metadata = null
		..()

/computer/file/text
	name = "text"
	extension = "TXT"
	size = 2
	var/data = null

	asText()
		return "[data]|n"

/computer/file/record
	name = "record"
	extension = "REC"
	size = 2

	var/list/fields = list(  )

	disposing()
		fields = null
		..()

	asText()
		for (var/x in fields)
			. += "[x]"
			if (isnull(fields[x]))
				. += "|n"
			else
				. += ": [fields[x]]|n"

/computer/file/signal
	name = "signal"
	extension = "SIG"
	size = 2

	var/list/data = list()
	var/encryption
	var/computer/file/data_file = null

	disposing()
		data = null
		encryption = null
		if (data_file)
			data_file.dispose()
			data_file = null

		..()

	asText()
		for (var/x in data)
			. += "\[[x]]"
			if (isnull(data[x]))
				. += " = NULL|n"
			else
				. += " = [data[x]]|n"

/computer/file/archive
	name = "archive"
	extension = "FAR"
	size = 8

	var/uncompressed_size = 0 //Size of files stored within.
	var/list/contained_files = list() //Generally assumed that all contained files will be expendable copies
	var/max_contained_size = 48

	proc/add_file(computer/R)
		if (!R || (R.size + uncompressed_size) > max_contained_size)
			return FALSE

		if (istype(R, /computer/file/archive))
			return FALSE

		contained_files += R
		uncompressed_size += R.size
		return TRUE

	copy_file() //Just make a replica of self
		var/computer/file/archive/copy = new type

		for (var/V in vars)
			if (issaved(vars[V]) && V != "contained_files")
				copy.vars[V] = vars[V]

		if (!copy.contained_files)
			copy.contained_files = list()

		for (var/computer/F in contained_files)
			if (istype(F, /computer/file))
				copy.contained_files += F:copy_file()
			else if (istype(F, /computer/folder))
				var/computer/folder/fcopy = F:copy_folder()
				if (fcopy)
					copy.contained_files += fcopy

		return copy

	disposing()
		if (contained_files)
			for (var/computer/C in contained_files)
				C.dispose()

			contained_files.len = 0
			contained_files = null
		..()

/computer/folder/link
	name = "symlink"
	gen = 10
	var/computer/folder/target = null

	New(var/computer/folder/newtarget)
		..()
		if (gen != 10) gen = 10
		if (istype(newtarget))
			if (istype(newtarget, /computer/folder/link))
				newtarget = newtarget:target
				if (!newtarget)
					return
			//qdel(metadata)
			contents = newtarget.contents
			//metadata = newtarget.metadata
			newtarget.linkers += src
			target = newtarget
		return

	/* same as above, XOXOXO. -singh
	Del()
		contents = null
		if (target)
			target.linkers -= src
			target = null
		..()
	*/

	disposing()
		contents = null
		if (target)
			target.linkers -= src
			target = null
		..()

	add_file(computer/R, misc)
		if (!target || target.holder != holder)
			return FALSE

		return target.add_file(R, misc)

	can_add_file(computer/R, misc)
		if (!target || target.holder != holder)
			return FALSE

		return target.can_add_file(R, misc)

	remove_file(computer/R, misc)
		if (!target || target.holder != holder)
			return FALSE

		return target.remove_file(R, misc)

	copy_folder(var/depth = 0)
		if (!target || target.holder != holder)
			return FALSE

		return target.copy_folder(depth)

/computer/file/image
	extension = "IMG"
	size = 8
	var/image/ourImage = null
	var/asciiVersion = null

	asText()
		if (asciiVersion)
			return asciiVersion

		if (!ourImage || !ourImage.icon)
			return ""

		asciiVersion = ""
		var/icon/sourceIcon = icon(ourImage.icon)
		for (var/py = 32, py > 0, py--)
			for (var/px = 1, px <= 32, px++)
				. = sourceIcon.GetPixel(px, py)
				if (.)
					. = hex2num(copytext(.,2))
					switch (.)
						if (0 to 5592405)
							asciiVersion += "."

						if (5592406 to 11184810)
							asciiVersion += "+"

						if (11184811 to INFINITY)
							asciiVersion += "@"
				else
					asciiVersion += "."

			asciiVersion += "|n"

		return asciiVersion