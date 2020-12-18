# Computes cosine similarities of gcov profiles per 'module' or subdirectory under each profile (fs, lib, kernel, etc.) for the benchmarks listed in the main procedure.
# Cosine similarities are calculated using the execution count for each source line.
# Assumes gcov profile data is kept under 'data/<benchmark>' for each benchmark, in gcov json output.
# Prints resulting confusion matrix for each directory to terminal and saves it in file <dir>_func_count_out.csv

import os
import json
from pathlib import Path
import numpy as np
from glob import glob

def craw_bench_folder(root):
    func_map = {}
    for path in Path(root).rglob('*.json'):
        with open(path) as fd:
            json_data = json.load(fd)

        for file in json_data["files"]:
            for function in file["functions"]:
                if function['execution_count'] >= 0:
                    if function['name'] not in func_map:
                        func_map[function['name']] = 0
                    func_map[function['name']] += function['execution_count']

    return func_map


def get_line_map_for_directory(dir_path):
    line_map = {}
    total_line_executions = 0

    for path in Path(dir_path).rglob('*.json'):
        with open(path) as fd:
            json_data = json.load(fd)

        for file in json_data["files"]:
            for line in file["lines"]:
                key = (file['file'], line['line_number'])
                if key not in line_map:
                    line_map[key] = 0
                line_map[key] += line['count']
                total_line_executions += line['count']

    return (line_map, total_line_executions)



def cos_sim_matrix(f):
    norms = np.expand_dims(np.linalg.norm(f, axis=1), axis=1)
    norm_tile = np.tile(norms,[1, f.shape[1]])
    #print("norm_tile:")
    #print(norm_tile)
    #print(f)
    #print(norm_tile)
    norm_tile[norm_tile == 0] = 1
    #print(f.dtype)
    #print(norm_tile.dtype)
    f2 = f.astype(np.float64) / norm_tile
    #f /= norm_tile
    return f2 @ f2.T

if __name__ == '__main__':
    benchmarks = ['apache', 'leveldb', 'memcached', 'mysql', 'nginx',
        'postgresql', 'redis', 'rocksdb']

    all_dirs_list = [Path(p).parts[2] for p in glob('data/postgresql/*')]

    counts = {}
    for b in benchmarks:
        counts[b] = {}
        counts[b]['total!'] = 0

    for dir in all_dirs_list:
        data_pairs = [get_line_map_for_directory(Path('data').joinpath(b, dir)) for b in benchmarks]
        data = [p[0] for p in data_pairs]
        ex_counts = [p[1] for p in data_pairs]

        for i in range(0, len(benchmarks)):
            print(f"Benchmark {benchmarks[i]} executed {ex_counts[i]} times in directory {dir}")
            counts[benchmarks[i]][dir] = ex_counts[i]
            counts[benchmarks[i]]['total!'] += ex_counts[i]

        data_keys = [set(d.keys()) for d in data]
        all_keys = sorted(list(set.union(*data_keys)))

        all_data = [[d[k] if k in d.keys() else 0 for k in all_keys] for d in data]

        m = cos_sim_matrix(np.array(all_data))
        print(dir)
        print(m)
        np.savetxt(f'{dir}_line_fixed_norm_out.csv',m, delimiter=',', fmt="%1.2f")

    for (bench, count_map) in counts.items():
        for (dir, count) in count_map.items():
            print(f"Benchmark {bench} executes {count / count_map['total!']} of the time in {dir}")

    ex_data = [counts[b] for b in benchmarks]
    all_ex_data = [[(d[dir] / d['total!']) for dir in all_dirs_list] for d in ex_data]

    print(benchmarks)
    print(all_dirs_list)

    a = np.array(all_ex_data)
    print(a)
    np.savetxt("Line_EXE_PORTIONS.csv", a, delimiter=',', fmt="%1.3f")



