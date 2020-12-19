# Computes cosine similarities of gcov profiles per 'module' or subdirectory under each profile (fs, lib, kernel, etc.) for the benchmarks listed in the main procedure.
# Cosine similarities are calculated using the execution count for each source function.
# Assumes gcov profile data is kept under 'data/<benchmark>' for each benchmark, in gcov json output.
# Prints resulting confusion matrix for each directory to terminal and saves it in file <dir>_func_count_out.csv

import os
import json
from pathlib import Path
import numpy as np
from glob import glob

from common import get_func_map_for_directory, cos_sim_matrix, benchmarks

if __name__ == '__main__':

    all_dirs_list = [Path(p).parts[3] for p in glob('../data/postgresql/*')]

    for dir in all_dirs_list:
        data = [get_func_map_for_directory(Path('../data').joinpath(b, dir)) for b in benchmarks]

        data_keys = [set(d.keys()) for d in data]
        all_keys = sorted(list(set.union(*data_keys)))

        all_data = [[d[k] if k in d.keys() else 0 for k in all_keys] for d in data]

   #     try:
        m = cos_sim_matrix(np.array(all_data))
        #if (np.min(m) > 0.9):
        print(dir)
        print(m)
        np.savetxt(f'{dir}_func_count_out.csv',m, delimiter=',', fmt="%1.2f")

   #     except:
   #         pass
            #print(path)
            #print("Couldn't calculate sim matrix")

