//CONTENTS
//Mainframe 2 memory core
//Mainframe 2 master tape -- TODO
//Mainframe 2 boot tape
//Mainframe 2 artifact research tape.
//Guardbot configuration tape.
//Boot kit box


/*
 *	Mainframe 2 starting memory
 */
/obj/item/disk/data/memcard/main2
	file_amount = 4096

	New()
		..()
		var/computer/folder/newfolder = new /computer/folder(  )
		newfolder.name = "sys"
		newfolder.metadata["permission"] = COMP_HIDDEN
		root.add_file( newfolder )
		newfolder.add_file( new /computer/file/mainframe_program/os/kernel(src) )
		newfolder.add_file( new /computer/file/mainframe_program/shell(src) )
		newfolder.add_file( new /computer/file/mainframe_program/login(src) )

		var/computer/folder/subfolder = new /computer/folder
		subfolder.name = "drvr" //Driver prototypes.
		newfolder.add_file( subfolder )
		//subfolder.add_file ( new FILEPATH GOES HERE )
		subfolder.add_file( new /computer/file/mainframe_program/driver/mountable/databank(src) )
		subfolder.add_file( new /computer/file/mainframe_program/driver/mountable/printer(src) )
		subfolder.add_file( new /computer/file/mainframe_program/driver/nuke(src) )
		subfolder.add_file( new /computer/file/mainframe_program/driver/mountable/guard_dock(src) )
		subfolder.add_file( new /computer/file/mainframe_program/driver/mountable/radio(src) )
		subfolder.add_file( new /computer/file/mainframe_program/driver/test_apparatus(src) )
		subfolder.add_file( new /computer/file/mainframe_program/driver/mountable/service_terminal(src) )
		subfolder.add_file( new /computer/file/mainframe_program/driver/mountable/user_terminal(src) )
		subfolder.add_file( new /computer/file/mainframe_program/driver/telepad(src) )
		subfolder.add_file( new /computer/file/mainframe_program/driver/mountable/comm_dish(src) )
		subfolder.add_file( new /computer/file/mainframe_program/driver/artifact_console(src) )
		//subfolder.add_file( new /computer/file/mainframe_program/driver/mountable/logreader(src) )
		subfolder.add_file( new /computer/file/mainframe_program/driver/apc(src) )

		subfolder = new /computer/folder
		subfolder.name = "srv"
		newfolder.add_file( subfolder )
		subfolder.add_file( new /computer/file/mainframe_program/srv/email(src) )
		subfolder.add_file( new /computer/file/mainframe_program/srv/print(src) )
		//subfolder.add_file( new /computer/file/mainframe_program/srv/accesslog(src) )
		subfolder.add_file( new /computer/file/mainframe_program/srv/telecontrol(src) )

		newfolder = new /computer/folder
		newfolder.name = "bin" //Applications available to all users.
		newfolder.metadata["permission"] = COMP_ROWNER|COMP_RGROUP|COMP_ROTHER
		root.add_file( newfolder )
		newfolder.add_file( new /computer/file/mainframe_program/utility/cd(src) )
		newfolder.add_file( new /computer/file/mainframe_program/utility/ls(src) )
		newfolder.add_file( new /computer/file/mainframe_program/utility/rm(src) )
		newfolder.add_file( new /computer/file/mainframe_program/utility/cat(src) )
		newfolder.add_file( new /computer/file/mainframe_program/utility/mkdir(src) )
		newfolder.add_file( new /computer/file/mainframe_program/utility/ln(src) )
		newfolder.add_file( new /computer/file/mainframe_program/utility/chmod(src) )
		newfolder.add_file( new /computer/file/mainframe_program/utility/chown(src) )
		newfolder.add_file( new /computer/file/mainframe_program/utility/su(src) )
		newfolder.add_file( new /computer/file/mainframe_program/utility/cp(src) )
		newfolder.add_file( new /computer/file/mainframe_program/utility/mv(src) )
		newfolder.add_file( new /computer/file/mainframe_program/utility/mount(src) )
		//newfolder.add_file( new /computer/file/mainframe_program/utility/grep(src) )
		newfolder.add_file( new /computer/file/mainframe_program/utility/scnt(src) )
		newfolder.add_file( new /computer/file/mainframe_program/utility/getopt(src) )
		newfolder.add_file( new /computer/file/mainframe_program/utility/date(src) )
		newfolder.add_file( new /computer/file/mainframe_program/utility/tar(src) )

		newfolder = new /computer/folder
		newfolder.name = "var"
		newfolder.metadata["permission"] = COMP_ROWNER|COMP_RGROUP|COMP_ROTHER
		root.add_file( newfolder )

		newfolder = new /computer/folder
		newfolder.name = "tmp"
		newfolder.metadata["permission"] = COMP_ALLACC &~(COMP_DOTHER|COMP_DGROUP)
		root.add_file( newfolder )
/*
		subfolder = new /computer/folder
		subfolder.name = "log"
		subfolder.metadata["permission"] = COMP_ROWNER|COMP_RGROUP
		newfolder.add_file( subfolder )
*/
		newfolder = new /computer/folder
		newfolder.name = "etc"
		newfolder.metadata["permission"] = COMP_ROWNER|COMP_RGROUP|COMP_ROTHER
		root.add_file( newfolder )

		subfolder = new /computer/folder
		subfolder.name = "mail"
		newfolder.add_file( subfolder )

		var/computer/file/record/groupRec = new /computer/file/record( )
		groupRec.name = "groups"
		subfolder.add_file( groupRec )

		var/list/randomMails = get_random_email_list()
		var/typeCount = 5
		while (typeCount-- > 0 && randomMails.len)
			var/mailName = pick(randomMails)
			var/computer/file/record/mailfile = new /computer/file/record/random_email(mailName)
			subfolder.add_file(mailfile)
			randomMails -= mailName
/*		var/list/randomMailTypes = subtypesof(/computer/file/record/random_email)
		var/typeCount = 5
		while (typeCount-- > 0 && randomMailTypes.len)
			var/mailType = pick(randomMailTypes)
			var/computer/file/record/mailfile = new mailType
			subfolder.add_file( mailfile )

			randomMailTypes -= mailType*/

		newfolder = new /computer/folder
		newfolder.name = "mnt"
		newfolder.metadata["permission"] = COMP_ROWNER|COMP_RGROUP|COMP_ROTHER
		root.add_file( newfolder )

		newfolder = new /computer/folder
		newfolder.name = "conf"
		newfolder.metadata["permission"] = COMP_ROWNER|COMP_RGROUP|COMP_ROTHER
		root.add_file( newfolder )

		var/computer/file/record/testR = new
		testR.name = "motd"
		testR.fields += "Welcome to DWAINE System VI!"
		testR.fields += pick("Better than System V ever was.","GLUEEEE GLUEEEE GLUEEEEE","Only YOU can prevent lp0 fires!","Please try not to kill yourselves today.", "Please don't set the lab facilities on fire.")
		newfolder.add_file( testR )

		newfolder.add_file( new /computer/file/record/dwaine_help(src) )

		return

/obj/item/disk/data/tape/master
	name = "ThinkTape-'Master Tape'"
	//Not sure what all to put here yet.

	New()
		..()
		//First off, buddy stuff.
		root.add_file( new /computer/file/guardbot_task/security(src) )
		root.add_file( new /computer/file/guardbot_task/security/purge(src) )
		root.add_file( new /computer/file/guardbot_task/bodyguard(src) )
		root.add_file( new /computer/file/guardbot_task/security/area_guard(src) )
		root.add_file( new /computer/file/guardbot_task/bodyguard/heckle(src) )
		root.add_file( new /computer/file/mainframe_program/guardbot_interface(src))
		root.add_file( new /computer/file/record/pr6_readme(src))
		root.add_file( new /computer/file/record/patrol_script(src))
		root.add_file( new /computer/file/record/bodyguard_script(src))
		root.add_file( new /computer/file/record/roomguard_script(src))
		root.add_file( new /computer/file/record/bodyguard_conf(src))

		//Nuke interface, because sometimes the nuke is alround.
		root.add_file( new /computer/file/mainframe_program/nuke_interface(src) )
		//root.add_file( new /computer/file/mainframe_program/srv/telecontrol(src) )

		for (var/computer/file/F in root.contents)
			F.metadata["permission"] = COMP_ROWNER|COMP_RGROUP|COMP_ROTHER

	readonly
		desc = "A reel of magnetic data tape.  The casing has been modified so as to prevent write access."
		icon_state = "r_tape"

		New()
			..()
			read_only = 1

/obj/item/disk/data/tape/boot2
	name = "ThinkTape-'OS Backup'"
	desc = "A reel of magnetic data tape containing operating software.  The casing has been modified so as to prevent write access."
	icon_state = "r_tape"

	New()
		..()
		root.add_file( new /computer/file/mainframe_program/os/kernel(src) )
		root.add_file( new /computer/file/mainframe_program/shell(src) )
		root.add_file( new /computer/file/mainframe_program/login(src) )
		root.add_file( new /computer/file/mainframe_program/driver/mountable/databank(src) )
		root.add_file( new /computer/file/mainframe_program/driver/mountable/printer(src) )
		root.add_file( new /computer/file/mainframe_program/driver/nuke(src) )
		root.add_file( new /computer/file/mainframe_program/driver/mountable/guard_dock(src) )
		root.add_file( new /computer/file/mainframe_program/driver/mountable/radio(src) )
		root.add_file( new /computer/file/mainframe_program/driver/test_apparatus(src) )
		root.add_file( new /computer/file/mainframe_program/driver/mountable/service_terminal(src) )
		root.add_file( new /computer/file/mainframe_program/driver/mountable/user_terminal(src) )
		root.add_file( new /computer/file/mainframe_program/driver/telepad(src) )
		root.add_file( new /computer/file/mainframe_program/driver/mountable/comm_dish(src) )
		//root.add_file( new /computer/file/mainframe_program/driver/mountable/logreader(src) )

		root.add_file( new /computer/file/mainframe_program/utility/cd(src) )
		root.add_file( new /computer/file/mainframe_program/utility/ls(src) )
		root.add_file( new /computer/file/mainframe_program/utility/rm(src) )
		root.add_file( new /computer/file/mainframe_program/utility/cat(src) )
		root.add_file( new /computer/file/mainframe_program/utility/mkdir(src) )
		root.add_file( new /computer/file/mainframe_program/utility/ln(src) )
		root.add_file( new /computer/file/mainframe_program/utility/chmod(src) )
		root.add_file( new /computer/file/mainframe_program/utility/chown(src) )
		root.add_file( new /computer/file/mainframe_program/utility/su(src) )
		root.add_file( new /computer/file/mainframe_program/utility/cp(src) )
		root.add_file( new /computer/file/mainframe_program/utility/mv(src) )
		root.add_file( new /computer/file/mainframe_program/utility/mount(src) )
		//root.add_file( new /computer/file/mainframe_program/utility/grep(src) )
		root.add_file( new /computer/file/mainframe_program/utility/scnt(src) )
		root.add_file( new /computer/file/mainframe_program/utility/getopt(src) )
		root.add_file( new /computer/file/mainframe_program/utility/date(src) )
		root.add_file( new /computer/file/mainframe_program/utility/tar(src) )
		//root.add_file( new /computer/file/mainframe_program/srv/accesslog(src) )
		root.add_file( new /computer/file/mainframe_program/srv/telecontrol(src) )
		root.add_file( new /computer/file/mainframe_program/srv/email(src) )
		root.add_file( new /computer/file/mainframe_program/srv/print(src) )
		read_only = 1

/obj/item/disk/data/tape/test
	name = "ThinkTape-'Test'"
	desc = "A reel of magnetic data tape containing various test files."

	New()
		..()
		root.add_file( new /computer/file/mainframe_program/shell(src) )
		root.add_file( new /computer/file/document(src) )
		root.add_file( new /computer/file/record/c3help(src) )
		root.add_file( new /computer/file/mainframe_program/nuke_interface(src) )
		root.add_file( new /computer/file/mainframe_program/test_interface(src) )

/obj/item/disk/data/tape/guardbot_tools
	name = "ThinkTape-'PR-6S Config'"
	desc = "A reel of magnetic data tape containing configuration and support files for PR-6S Guardbuddies."

	New()
		..()
		root.add_file( new /computer/file/guardbot_task/security(src) )
		root.add_file( new /computer/file/guardbot_task/security/purge(src) )
		root.add_file( new /computer/file/guardbot_task/bodyguard(src) )
		root.add_file( new /computer/file/guardbot_task/security/area_guard(src) )

		root.add_file( new /computer/file/mainframe_program/guardbot_interface(src))
		root.add_file( new /computer/file/record/pr6_readme(src))
		root.add_file( new /computer/file/record/patrol_script(src))
		root.add_file( new /computer/file/record/bodyguard_script(src))
		root.add_file( new /computer/file/record/bodyguard_conf(src))
		for (var/computer/file/F in root.contents)
			F.metadata["permission"] = COMP_ROWNER|COMP_RGROUP|COMP_ROTHER

/obj/item/disk/data/tape/artifact_research
	name = "ThinkTape-'Artifact Research'"
	desc = "A reel of magnetic data tape containing modern research software."

	New()
		..()
		root.add_file( new /computer/file/mainframe_program/test_interface(src)  )
		//root.add_file( new /computer/file/mainframe_program/artifact_research(src) )
		for (var/computer/file/F in root.contents)
			F.metadata["permission"] = COMP_ROWNER|COMP_RGROUP|COMP_ROTHER
