#!/usr/bin/env python3

f = open("../docs/gxrom-r", "rb")
count=0
filedata = f.read()
f.close()
for b in filedata:
	print("%1x %1x "%(int(b&0x0f),int((b&0xf0)>>4)), end="")
	count += 1
	if count == 8:
		print(end="  ")
	if count == 16:
		print(end="\n")
		count = 0