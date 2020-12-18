# Computes cosine similarities of gcov profiles per 'module' or subdirectory under each profile (fs, lib, kernel, etc.) for the benchmarks listed in the main procedure.
# Cosine similarities are calculated using the execution count for each source function.
# Assumes gcov profile data is kept under 'data/<benchmark>' for each benchmark, in gcov json output.
# Prints resulting confusion matrix for each directory to terminal and saves it in file <dir>_func_count_out.csv

import os
import json
from pathlib import Path
import numpy as np
from glob import glob


def get_func_map_for_directory(dir_path):
    func_map = {}

    for path in Path(dir_path).rglob('*.json'):
        with open(path) as fd:
            json_data = json.load(fd)

        for file in json_data["files"]:
            for function in file["functions"]:
                if function['execution_count'] > 0:
                    if function['name'] not in func_map:
                        func_map[function['name']] = 0
                    func_map[function['name']] += function['execution_count']


    return func_map



def cos_sim_matrix(f):
    norms = np.expand_dims(np.linalg.norm(f, axis=1), axis=1)
    norm_tile = np.tile(norms,[1, f.shape[1]])
    #print("norm_tile:")
    #print(norm_tile)
    #print(f)
    #print(norm_tile)
    f /= norm_tile
    return f @ f.T

if __name__ == '__main__':
    benchmarks = ['apache', 'leveldb', 'memcached', 'mysql', 'nginx',
        'postgresql', 'redis', 'rocksdb']

    all_dirs_list = [Path(p).parts[2] for p in glob('data/postgresql/*')]

    for dir in all_dirs_list:
        data = [get_func_map_for_directory(Path('data').joinpath(b, dir)) for b in benchmarks]

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

