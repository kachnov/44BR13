var/list/matrixPool = list()
var/matrixPoolHitCount = 0
var/matrixPoolMissCount = 0

/matrix
	proc/Reset()
		a = 1
		b = 0
		c = 0
		d = 0
		e = 1
		f = 0
		disposed = 0