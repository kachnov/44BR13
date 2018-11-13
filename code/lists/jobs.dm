/*#define NEWJOBS
var/list/occupations = list(

	#ifndef NEWJOBS
	"Chief Engineer",
	"Mechanic","Mechanic",
	"Engineer","Engineer","Engineer",
	"Miner","Miner","Miner",
	"Security Officer", "Security Officer", "Security Officer",
//	"Vice Officer",
	"Detective",
	"Geneticist",
	"Scientist","Scientist", "Scientist",
	"Medical Doctor", "Medical Doctor",
	"Head of Personnel",
//	"Head of Security",
	"Research Director",
	"Medical Director",
	"Chaplain",
	"Roboticist",
//	"Hangar Mechanic", "Hangar Mechanic",
	"AI",
	"Cyborg", "Cyborg",
	"Barman",
	"Chef",
	"Janitor",
	"Clown",
//	"Chemist","Chemist",
	"Quartermaster","Quartermaster",
	"Botanist","Botanist"
	#else
	"Space Jew",
	"Space Boomer Officer",
	"Space Boomer Soldier",
	#endif 
	
	
	)
//	"Attorney at Space-Law")

var/list/assistant_occupations = list(
	"Staff Assistant")
	*/
	
var/occupations/occupations = new
		
/occupations 
	
	var/list/all_jobs_saved = null

	var/list/boomers = list(
		"Space Jew",
		"Boomer General",
		"Boomer Officer",
		"Boomer MPO",
		"Boomer Soldier"
	)
	var/list/xenomorphs = list(
		"Xenomorph Facehugger"
	)
	var/list/bongs = list(
		"Space Bong",
		"Space Chav",
		"The Queen",
		"Sharia Police"
	)
	var/list/assistant_jobs = list(
	
	)
	
/occupations/proc/get_all_jobs()
	if (!all_jobs_saved)
		all_jobs_saved = boomers+xenomorphs+bongs+assistant_jobs
	return all_jobs_saved
	
//	"Mechanic",
//	"Atmospheric Technician","Atmospheric Technician","Atmospheric Technician",

var/list/job_mailgroup_list = list(
	"Captain" = "command",
	"Head of Personnel" = "command",
	"Head of Security" = "command",
	"Medical Director" = "command",
	"Quartermaster" = "cargo",
	"Botanist" = "botany",
	"Medical Director" = "medresearch",
	"Roboticist" = "medresearch",
	"Geneticist" = "medresearch",
	"Medical Doctor" = "medbay")

//Used for PDA department paging.
var/list/page_departments = list(
	"Command" = "command",
	"Security" = "security",
	"Medbay" = "medbay",
	"Med Research" = "medresearch",
	"Research" = "science",
	"Cargo" = "cargo",
	"Botany" = "botany",
	"Bar / Kitchen" = "kitchen")

/proc/get_all_jobs()
	return list("Assistant", "Detective", "Medical Doctor", "Captain", "Security Officer",
				"Geneticist", "Scientist", "Head of Personnel",
				"Chaplain", "Barman", "Janitor", "Chef", "Roboticist", "Quartermaster",
				"Chief Engineer","Engineer", "Miner", "Mechanic",
				"Research Director", "Medical Director", "Botanist", "Clown")