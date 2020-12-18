# Computes cosine similarities of gcov profiles for the benchmarks listed in the main procedure.
# Cosine similarities are done using the execution count for each source line
# Assumes gcov profile data is kept under 'data/<benchmark>' for each benchmark, in gcov json output.
# Prints output confusion matrix to terminal and saves it in file line_count_sim.csv

import os
import json
from pathlib import Path
import numpy as np

def craw_bench_folder(root):
    line_map = {}
    for path in Path(root).rglob('*.json'):
        with open(path) as fd:
            json_data = json.load(fd)

        for file in json_data["files"]:
            for line in file["lines"]:
                key = (file['file'], line['line_number'])
                if key not in line_map:
                    line_map[key] = 0
                line_map[key] += line['count']

    return line_map

def cos_sim_matrix(f):
    norms = np.expand_dims(np.linalg.norm(f, axis=1), axis=1)
    norm_tile = np.tile(norms,[1, f.shape[1]])
    f /= norm_tile
    return f @ f.T

if __name__ == '__main__':
    benchmarks = ['apache', 'leveldb', 'memcached', 'mysql', 'nginx',
        'postgresql', 'redis', 'rocksdb']
    
    data = [craw_bench_folder(os.path.join('data', b)) for b in benchmarks]

    data_keys = [set(d.keys()) for d in data]
    all_keys = sorted(list(set.union(*data_keys)))

    all_data = [[d[k] if k in d.keys() else 0 for k in all_keys] for d in data]

    m = cos_sim_matrix(np.array(all_data))
    print(m)
    np.savetxt('line_count_sim.csv',m, delimiter=',')
