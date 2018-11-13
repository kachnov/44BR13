/proc/passproc()
#define _pass passproc()
#define subtypesof(x) (typesof(x) - x)
#define default_value(a, b) a ? a : b

/proc/switch_value(value, a, b)
	if (value == a)
		return b
	return a