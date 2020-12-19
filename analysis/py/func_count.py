# Computes cosine similarities of gcov profiles for the benchmarks listed in the main procedure.
# Cosine similarities are done using the execution count for each called function
# Assumes gcov profile data is kept under 'data/<benchmark>' for each benchmark, in gcov json output.
# Prints output confusion matrix to terminal and saves it in file func_count_sim.csv

import os
import json
from pathlib import Path
import numpy as np

from common import craw_bench_folder_func as craw_bench_folder
from common import cos_sim_matrix, benchmarks

if __name__ == '__main__':
    data = [craw_bench_folder(os.path.join('../data', b)) for b in benchmarks]

    data_keys = [set(d.keys()) for d in data]
    all_keys = sorted(list(set.union(*data_keys)))

    all_data = [[d[k] if k in d.keys() else 0 for k in all_keys] for d in data]

    m = cos_sim_matrix(np.array(all_data))
    print(m)
    np.set_printoptions(suppress=True)
    np.set_printoptions(precision=3)
    np.savetxt('../out/func_count_sim.csv',m, delimiter=',', fmt="%1.2f")
