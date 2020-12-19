import os
import json
from pathlib import Path
import numpy as np
from scipy.io import savemat

from common import craw_bench_folder_branch
from common import (cos_sim_matrix, p_norm_sim_matrix,
    get_hot_features, benchmarks)


if __name__ == '__main__':

    # craw files
    #data = [craw_bench_folder_branch(os.path.join('../data', b), 'taken_freq') for b in benchmarks]

    #data_keys = [set(d.keys()) for d in data]
    #all_keys = sorted(list(set.union(*data_keys)))

    #all_data = [[d[k] if k in d.keys() else 0 for k in all_keys] for d in data]
    #np.save('branch_taken_prob.npy', all_data) # save intermediate results

    all_data = np.load('../out/branch_taken_prob.npy') # get intermediate results

    # get hot lines
    # all_data = get_hot_features(all_data)

    score = p_norm_sim_matrix(np.array(all_data), 2, pre_norm=False) / all_data.shape[1]

    data = {"score": score, "bench": np.array(benchmarks, dtype=np.object)}
    print(data)
    savemat("../out/br_taken_l2.mat", data)
