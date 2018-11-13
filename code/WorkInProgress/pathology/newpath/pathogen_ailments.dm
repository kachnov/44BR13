/proc/generate_cold_pathogen()
	var/pathogen/P = unpool(/pathogen)
	P.forced_microbody = /microbody/virus
	P.curable_by_suppression = 7
	P.setup(2, null, 0)
	P.add_symptom(pathogen_controller.path_to_symptom[/pathogeneffects/malevolent/coughing])
	P.add_symptom(pathogen_controller.path_to_symptom[/pathogeneffects/malevolent/indigestion])
	return P

/proc/generate_flu_pathogen()
	var/pathogen/P = unpool(/pathogen)
	P.forced_microbody = /microbody/virus
	P.curable_by_suppression = 4
	P.setup(2, null, 0)
	P.add_symptom(pathogen_controller.path_to_symptom[/pathogeneffects/malevolent/coughing])
	P.add_symptom(pathogen_controller.path_to_symptom[/pathogeneffects/malevolent/sneezing])
	P.add_symptom(pathogen_controller.path_to_symptom[/pathogeneffects/malevolent/muscleache])
	return P

/proc/generate_indigestion_pathogen()
	var/pathogen/P = unpool(/pathogen)
	P.curable_by_suppression = 18
	P.setup(2, null, 0)
	P.add_symptom(pathogen_controller.path_to_symptom[/pathogeneffects/malevolent/indigestion])
	return P
