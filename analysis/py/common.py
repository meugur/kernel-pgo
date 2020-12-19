import os
import json
from pathlib import Path
import numpy as np
from scipy.io import savemat

# ------------------------------------------------------------------------------
# craw (every folder) in the benchmark for one application

# craw for function count, return a map of function -> execution count
def craw_bench_folder_func(root):
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

# craw for line count, return a map of line -> execution count
def craw_bench_folder_line(root):
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

# craw for branch count, return a map of branch
# -> execution count or branch taken frequuency
def craw_bench_folder_branch(root, metric):
    line_map = {}
    for path in Path(root).rglob('*.json'):
        with open(path) as fd:
            json_data = json.load(fd)

        for file in json_data["files"]:
            for line in file["lines"]:
                bt = 0 # branch taken
                ft = 0 # fallthrough

                for br in line['branches']:
                    if br['fallthrough']:
                        ft += br['count']
                    else:
                        bt += br['count']

                key = (file['file'], line['line_number'])
                if ft + bt > 0:
                    if key not in line_map:
                        line_map[key] = (ft, bt)
                    else:
                        prev = line_map[key]
                        line_map[key] = (prev[0] + ft, prev[1] + bt)
    if metric == 'count':
        for k in line_map.keys():
            line_map[k] = (line_map[k][0] + line_map[k][1])
    elif metric == 'taken_freq':
        for k in line_map.keys():
            line_map[k] = line_map[k][1] / (line_map[k][0] + line_map[k][1])

    return line_map

# ------------------------------------------------------------------------------
# craw each folder in linux source code top level for one application

# craw for function exec count
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

# craw for line exec count
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

# ------------------------------------------------------------------------------
# metrics: similarity matrices

def get_hot_features(all_data):
    ct_per_line = all_data.sum(axis=0)
    idx = np.argsort(ct_per_line)[::-1]
    keep = np.logical_not(np.cumsum(ct_per_line[idx]) >= np.sum(ct_per_line) * .8)
    return all_data[:,idx][:,keep]

def cos_sim_matrix(f):
    norms = np.expand_dims(np.linalg.norm(f, axis=1), axis=1)
    norm_tile = np.tile(norms,[1, f.shape[1]])
    norm_tile[norm_tile == 0] = 1
    f = f.astype(np.float64) / norm_tile
    return f @ f.T

def p_norm_sim_matrix(f, p, pre_norm=True):
    if pre_norm:
        norms = np.expand_dims(np.linalg.norm(f, ord=p, axis=1), axis=1)
        norm_tile = np.tile(norms,[1, f.shape[1]])
        norm_tile[norm_tile == 0] = 1
        f = f.astype(np.float64) / norm_tile
    return np.mat([[np.linalg.norm(ff - fff, ord=p) for ff in f] for fff in f])

benchmarks = ['apache', 'leveldb', 'memcached', 'mysql', 'nginx',
        'postgresql', 'redis', 'rocksdb']
