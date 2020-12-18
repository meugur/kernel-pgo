# Basic utility for collecting data for gcov json output file.
# Prints execution count for each source line found
# Prints execution count for each source function found
# Builds map for function name to execution count

import json
import sys

if len(sys.argv) < 2:
    print("Please provide filename")
    quit()

with open(sys.argv[1]) as f:
    json_data = json.load(f)

func_map = {}

for file in json_data["files"]:
    print(file["file"])
    for line in file["lines"]:
        print(f"{line['line_number']}: {line['count']}")
    for function in file["functions"]:
        print(f"{function['name']}: {function['execution_count']}")
        if function['name'] not in func_map:
            func_map[function['name']] = 0
        func_map[function['name']] += function['execution_count']

print(func_map)


