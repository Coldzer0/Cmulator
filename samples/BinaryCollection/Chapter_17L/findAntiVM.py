from idautils import *
from idc import *

heads = Heads(SegStart(ScreenEA()), SegEnd(ScreenEA()))
antiVM = []
for i in heads:
	if (GetMnem(i) == "sidt" or GetMnem(i) == "sgdt" or GetMnem(i) == "sldt" or GetMnem(i) == "smsw" or GetMnem(i) == "str" or GetMnem(i) == "in" or GetMnem(i) == "cpuid"):
		antiVM.append(i)

print "Number of potential Anti-VM instructions: %d" % (len(antiVM))

for i in antiVM:
	SetColor(i, CIC_ITEM, 0x0000ff)
	Message("Anti-VM: %08x\n" % i)