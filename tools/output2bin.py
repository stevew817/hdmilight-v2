#!/usr/bin/python

import sys, os

if sys.version_info < (3,):
	def tobyte(x): return chr(x)
else:
	def tobyte(x): return bytes([x])

if sys.platform == 'win32':
	import msvcrt
	msvcrt.setmode(sys.stdout.fileno(), os.O_BINARY)

input = open(sys.argv[1])
for (linenum, line) in enumerate(input):
	line = line[:line.find('#')]
	cols = line.split()
	if len(cols) == 0:
		continue
	
	if len(cols) != 5:
		sys.stderr.write('wrong column count at line %s\n' % linenum)
		sys.exit(1)

	try:
		(index, area, colour, gamma, enabled) = [int(x, 0) for x in cols]
		if enabled != 0:
			enabled = 1
	except ValueError:
		sys.stderr.write('bad value at line %s\n' % linenum)
		sys.exit(1)

	data = (area & 0xff) | ((gamma & 7) << 8) | ((colour & 15) << 11) | (enabled << 15)
	
	os.write(sys.stdout.fileno(), tobyte(data & 0xff))
	os.write(sys.stdout.fileno(), tobyte(data >> 8))
