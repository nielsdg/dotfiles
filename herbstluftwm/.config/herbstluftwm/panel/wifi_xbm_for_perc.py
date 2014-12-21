#!/usr/bin/python2

import sys
import math

perc = float(sys.argv[1])

print("wifi_" + str(int(math.ceil(perc / 20.))) + ".xbm")

