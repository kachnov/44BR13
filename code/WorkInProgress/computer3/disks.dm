//CONTENTS
//Base disk
//Base fixed disk
//Base memcard
//Base tape reel (HEH)
//Base "read only" floppy.
//Computer3 boot floppy
//Network tools floppy
//Medical program floppy
//Security program floppy
//Research programs floppy
//Computer3-formatted fixed disk.
//Box of tapes


/obj/item/disk/data
	name = "data disk"
	icon = 'icons/obj/cloning.dmi'
	icon_state = "datadisk0" //Gosh I hope syndies don't mistake them for the nuke disk.
	item_state = "card-id"
	w_class = 1.0
	//DNA machine vars
	var/data = ""
	var/ue = 0
	var/data_type = "ui" //ui|se
	var/owner = "Farmer Jeff"
	var/read_only = 0 //Well,it's still a floppy disk
	//Filesystem vars
	var/computer/folder/root = null
	var/file_amount = 32
	var/file_used = 0
	var/portable = 1
	var/title = "Data Disk"
	New()
		root = new /computer/folder
		root.holder = src
		src.root.name = "root"

	disposing()
		if (root)
			root.dispose()
			root = null

		data = null
		..()

	clone()
		var/obj/item/disk/data/D = ..()
		if (!D)
			return

		D.data = data
		D.ue = ue
		D.data_type = data_type
		D.owner = owner
		D.read_only = read_only

		D.title = title
		D.file_amount = file_amount
		if (root)
			D.root = src.root.copy_folder()
			D.root.holder = D

		return D

/obj/item/disk/data/floppy
	var/random_color = 1

/obj/item/disk/data/floppy/New()
	..()
	if (random_color)
		var/diskcolor = pick(0,1,2)
		icon_state = "datadisk[diskcolor]"

/obj/item/disk/data/floppy/attack_self(mob/user as mob)
	read_only = !read_only
	boutput(user, "You flip the write-protect tab to [read_only ? "protected" : "unprotected"].")

/obj/item/disk/data/floppy/examine()
	set src in oview(5)
	..()
	boutput(usr, text("The write-protect tab is set to [read_only ? "protected" : "unprotected"]."))
	return

/obj/item/disk/data/floppy/demo
	name = "data disk - 'Farmer Jeff'"
	data = "0C80C80C80C80C80C8000000000000161FBDDEF"
	ue = 1
	read_only = 1

/obj/item/disk/data/floppy/monkey
	name = "data disk - 'Mr. Muggles'"
	data_type = "se"
	data = "0983E840344C39F4B059D5145FC5785DC6406A4FFF"
	read_only = 1

/obj/item/disk/data/fixed_disk
	name = "Storage Drive"
	icon_state = "harddisk"
	title = "Storage Drive"
	file_amount = 80
	portable = 0

/obj/item/disk/data/memcard
	name = "Memory Board"
	icon_state = "memcard"
	desc = "A large board of non-volatile memory."
	title = "MEMCORE"
	file_amount = 640
	portable = 0

	attackby(obj/item/W as obj, mob/user as mob)
		if (istype(W, /obj/item/device/multitool))
			user.visible_message("<span style=\"color:red\"><strong>[user] begins to clear the [src]!</strong></span>","You begin to clear the [src].")
			if (do_after(user, 30))
				user.visible_message("<span style=\"color:red\"><strong>[user] clears the [src]!</strong></span>","You clear the [src].")
				//qdel(root)
				if (root)
					root.dispose()

				root = new /computer/folder
				root.holder = src
				src.root.name = "root"
			return

/obj/item/disk/data/tape
	name = "ThinkTape"
	desc = "A form of proprietary magnetic data tape used by Thinktronic Data Systems, LLC."
	title = "MAGTAPE"
	icon_state = "tape"
	item_state = "paper"
	file_amount = 128
	portable = 0

	New()
		..()
		root.gen = 99 //No subfolders!!
		return

	attackby(obj/item/W as obj, mob/user as mob)
		if (istype(W, /obj/item/pen))
			var/t = input(user, "Enter new tape label", name, null) as text
			t = copytext(strip_html(t), 1, 36)
			if (!in_range(src, usr) && loc != usr)
				return
			if (!t)
				name = "ThinkTape"
				return

			name = "ThinkTape-'[t]'"
		else
			..()
		return

//Floppy disks that are read-only ONLY.
//It's good to have a more permanent source of programs when somebody deletes everything (until they space all the disks)
//Remember to actually set them as read only after adding files in New()
/obj/item/disk/data/floppy/read_only
	name = "Permafloppy"

	attack_self(mob/user as mob)
		boutput(user, "<span style=\"color:red\">You can't flip the write-protect tab, it's held in place with glue or something!</span>")
		return

/obj/item/disk/data/floppy/computer3boot
	name = "data disk-'ThinkDOS'"

	New()
		..()
		root.add_file( new /computer/file/terminal_program/os/main_os(src))
		var/computer/folder/newfolder = new /computer/folder(  )
		newfolder.name = "logs"
		root.add_file( newfolder )
		newfolder.add_file( new /computer/file/record/c3help(src))
		newfolder = new /computer/folder
		newfolder.name = "bin"
		root.add_file( newfolder )
		newfolder.add_file( new /computer/file/terminal_program/writewizard(src))

/obj/item/disk/data/floppy/read_only/network_progs
	name = "data disk-'Network Tools'"
	desc = "A collection of network management tools."
	title = "Network Help"

	New()
		..()
		root.add_file( new /computer/file/terminal_program/background/ping(src))
		root.add_file( new /computer/file/terminal_program/background/signal_catcher(src))
		root.add_file( new /computer/file/terminal_program/file_transfer(src))
		//root.add_file( new /computer/file/terminal_program/sigcrafter(src))
		root.add_file( new /computer/file/terminal_program/sigpal(src))
		root.add_file( new /computer/file/terminal_program/email(src))
		read_only = 1

/obj/item/disk/data/floppy/read_only/medical_progs
	name = "data disk-'Med-Trak 4'"
	desc = "The future of professional medical record management"
	title = "Med-Trak 4"

	New()
		..()
		root.add_file( new /computer/file/terminal_program/medical_records(src))
		read_only = 1

/obj/item/disk/data/floppy/read_only/security_progs
	name = "data disk-'SecMate 6'"
	desc = "It manages security records.  It is the law."
	title = "SecMate 6"

	New()
		..()
		root.add_file( new /computer/file/terminal_program/secure_records(src))
		root.add_file( new /computer/file/terminal_program/manifest(src))
		read_only = 1

/obj/item/disk/data/floppy/read_only/research_progs
	name = "data disk-'AutoMate'"
	desc = "A disk containing a popular robotics research application."
	title = "Research"

	New()
		..()
		root.add_file( new /computer/file/terminal_program/robotics_research(src))
		read_only = 1

/obj/item/disk/data/floppy/read_only/ext_research_progs
	name = "data disk-'Research Suite'"
	desc = "A disk of research programs."
	title = "Research"

	New()
		..()
		root.add_file( new /computer/file/terminal_program/artifact_research(src))
		root.add_file( new /computer/file/terminal_program/disease_research(src))
		root.add_file( new /computer/file/terminal_program/robotics_research(src))
		read_only = 1

/obj/item/disk/data/floppy/read_only/terminal_os
	name = "data disk-'TermOS B'"
	desc = "A boot-disk for terminal systems."
	title = "TermOS"

	New()
		..()
		root.add_file( new /computer/file/terminal_program/os/terminal_os(src))
		read_only = 1

/obj/item/disk/data/floppy/read_only/communications
	name = "data disk-'COMMaster'"
	desc = "A disk for station communication programs."
	title = "COMMaster"

	New()
		..()
		root.add_file( new /computer/file/terminal_program/communications(src))
		root.add_file( new /computer/file/terminal_program/manifest(src))
		read_only = 1
#ifdef SINGULARITY_TIME
/obj/item/disk/data/floppy/read_only/engine_prog
	name = "data disk-'EngineMaster'"
	desc = "A disk with an engine startup program."
	title = "EngineDisk"

	New()
		..()
		root.add_file( new /computer/file/terminal_program/engine_control(src))
		read_only = 1
#endif

/obj/item/disk/data/floppy/read_only/authentication
	name = "Authentication Disk"
	desc = "Capable of storing entire kilobytes of information, this disk carries activation codes for various secure things that aren't nuclear bombs."
	icon = 'icons/obj/items.dmi'
	icon_state = "nucleardisk"
	item_state = "card-id"
	w_class = 1.0
	mats = 15
	random_color = 0
	file_amount = 32.0

	New()
		..()
		spawn (10) //Give time to actually generate network passes I guess.
			//root.add_file( new /computer/file/nuclear_auth(src))
			var/computer/file/record/authrec = new /computer/file/record {name = "GENAUTH";} (src)
			authrec.fields = list("HEADS"="[netpass_heads]",
								"SEC"="[netpass_security]",
								"MED"="[netpass_medical]")

			root.add_file( authrec )
			root.add_file( new /computer/file/terminal_program/communications(src))
			read_only = 1

/obj/item/disk/data/floppy/devkit
	name = "data disk-'Development'"
	title = "T-DISK"

//A fixed disk with some structure already set up for the main os I guess
/obj/item/disk/data/fixed_disk/computer3
	New()
		..()
		//First off, create the directory for logging stuff
		var/computer/folder/newfolder = new /computer/folder(  )
		newfolder.name = "logs"
		root.add_file( newfolder )
		newfolder.add_file( new /computer/file/record/c3help(src))
		//This is the bin folder. For various programs I guess sure why not.
		newfolder = new /computer/folder
		newfolder.name = "bin"
		root.add_file( newfolder )
		//newfolder.add_file( new /computer/file/terminal_program/sigcrafter(src))
		newfolder.add_file( new /computer/file/terminal_program/sigpal(src))
		newfolder.add_file( new /computer/file/terminal_program/background/signal_catcher(src))
		if (prob(75))
			newfolder.add_file( new /computer/file/terminal_program/writewizard(src))
		else
			newfolder.add_file( new /computer/file/terminal_program/file_transfer(src))
