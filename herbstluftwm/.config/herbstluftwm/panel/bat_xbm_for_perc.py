#!/usr/bin/python

import sys
import math

perc = float(sys.argv[1])

if perc == 100:
    print("bat_9.xbm")
elif perc == 0:
    print("bat_empty.xbm")
else:
    print("bat_" + str(int(math.ceil(perc / 11.))) + ".xbm")

