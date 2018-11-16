// creates new REPO object with the name ``name`` of type ``type``
#define REPO_OBJECT(name, type) /global_object_repository/var##type/##name = null; \
	/global_object_repository/proc/init_##name(){name = new type;}

// creates a new REPO list with the name ``name`` set to ``value``
#define REPO_LIST(name, value) /global_object_repository/var/list/##name = null; \
	/global_object_repository/proc/init_##name(){name = value;}

// immediately creates a constant REPO variable with the name ``name`` set to ``value``
#define REPO_CONST(name, value) /global_object_repository/var/const/##name = value;

// creates a new REPO process of type ``type`` with the name PSP``type`` (PSP = processSchedulerProcess)
#define PROCESS(type) /var/global/controller/process/##type/PSP##type = null; \
	/global_object_repository/proc/init_PSP##type(){PSP##type = new;} \
	/controller/process/##type

// only thing that should be initialized with a raw new, to avoid init overhead
var/global/global_object_repository/REPO = new

// the actual definition of /global_object_repository, a simple /datum
/global_object_repository

/global_object_repository/New()
	..()
	for (var/_var in vars)
		if (hascall(src, "init_[_var]"))
			call(src, "init_[_var]")()