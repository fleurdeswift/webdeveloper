#!/usr/bin/python

import sys
import os

def bytesFromFile(filename, chunksize=16):
    with open(filename, "rb") as f:
        while True:
            chunk = f.read(chunksize)
            if chunk:
                yield chunk
            else:
                break

for fileName in sys.argv[1:]:
	symbol = os.path.basename(fileName).replace(".", "_")
	size = 0
	print "const unsigned char %s[] = {" % symbol
	
	for data in bytesFromFile(fileName):
		line = "    "
		size += len(data)
		for byte in data:
			line += hex(ord(byte)) + ", "
		print line

	print "    0 };"
	print "const unsigned int %s_len = %i;\n" % (symbol, size)
