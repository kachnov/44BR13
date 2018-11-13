/game_mode/_44BR13
	name = "Fortnite 4chan Battle Royale"
	config_tag = "44BR13"
	crew_shortage_enabled = FALSE
	var/list/facehugger_traitors = list()
	var/list/dead_xenomorph_praetorians = list()

/game_mode/_44BR13/announce()
	boutput(world, "<strong>The current game mode is - <big>[name]</big>!</strong>")
	boutput(world, "<big>Rise and grind, gamers! Fight and kill the other 3 factions on the station!</big>")
	
/game_mode/_44BR13/proc/add_facehugger_traitor(var/mob/facehugger)
	facehugger_traitors += facehugger.ckey
	facehugger << browse(grabResource("html/traitorTips/traitorradiouplinkTips.html"),"window=antagTips;titlebar=1;size=600x400;can_minimize=0;can_resize=0")
