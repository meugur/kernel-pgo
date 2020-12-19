#!/usr/bin/python3

import os
import sys

DATA_DIR="/home/meugur/dev/eecs/eecs582/profile-output"
TEST_DIR=sys.argv[1]
PATH="{}/{}/".format(DATA_DIR, TEST_DIR)
OUTPUT_DIR="{}/{}/".format(DATA_DIR, TEST_DIR + '-results')

if not os.path.exists(OUTPUT_DIR):
    os.mkdir(OUTPUT_DIR)

unique = set()
files = os.listdir(PATH)
for f in files:
    h = f.split('_')[0]
    unique.add(h)

for u in unique:
    execution = 0

    f1 = open("{}{}_1.log".format(PATH, u))
    lines = []
    for l in f1.readlines():
        l = l.strip()
        if l:
            lines.append(l)
    f1.close()
    lines = lines[2:]

    cycles = lines[0].split()[0]
    cycles_k = lines[1].split()[0]
    instructions = lines[2].split()[0]
    instructions_per_cycle = lines[2].split()[3]
    instructions_k = lines[3].split()[0]
    instructions_per_cycle_k = lines[3].split()[3]
    execution += float(lines[4].split()[0])

    f2 = open("{}{}_2.log".format(PATH, u))
    lines = []
    for l in f2.readlines():
        l = l.strip()
        if l:
            lines.append(l)
    f2.close()
    lines = lines[2:]

    l1_cache = lines[0].split()[0]
    l1_cache_k = lines[1].split()[0]
    itlb = lines[2].split()[0]
    itlb_k = lines[3].split()[0]

    execution += float(lines[4].split()[0])
    execution /= 2

    #print(cycles)
    #print(cycles_k)
    #print(instructions)
    #print(instructions_k)
    #print(l1_cache)
    #print(l1_cache_k)
    #print(itlb)
    #print(itlb_k)
    #print(execution)
    #print(instructions_per_cycle)
    #print(instructions_per_cycle_k)


    f = open("{}/{}.csv".format(OUTPUT_DIR, u), "w")
    f.write(str(execution).replace(',', '') + ",,,,,")
    f.write(str(cycles).replace(',', '') + ",")
    f.write(str(instructions).replace(',', '') + ",")
    f.write(str(l1_cache).replace(',', '') + ",")
    f.write(str(itlb).replace(',', '') + ",")
    f.write(str(cycles_k).replace(',', '') + ",")
    f.write(str(instructions_k).replace(',', '') + ",")
    f.write(str(l1_cache_k).replace(',', '') + ",")
    f.write(str(itlb_k).replace(',', '') + ",")
    f.write(str(instructions_per_cycle).replace(',', '') + ",")
    f.write(str(instructions_per_cycle_k).replace(',', '') + ",")