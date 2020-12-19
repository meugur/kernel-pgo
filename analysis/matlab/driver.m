plot_heatmap('../out/func_freq_cos.mat', '', false)
plot_heatmap('../out/func_freq_p1.mat', '', true)
plot_heatmap('../out/func_freq_p2.mat', '', true)

plot_heatmap('../out/line_freq_cos.mat', '', false)
plot_heatmap('../out/line_freq_p1.mat', '', true)
plot_heatmap('../out/line_freq_p2.mat', '', true)

plot_heatmap('../out/br_count_cos.mat', '', false)

plot_heatmap('../out/br_taken_l0.mat', '', true)
plot_heatmap('../out/br_taken_l1.mat', '', true)
plot_heatmap('../out/br_taken_l2.mat', '', true)

csv_heatmap('../out/fs_line_fixed_norm_out.csv', 'File System')
csv_heatmap('../out/mm_line_fixed_norm_out.csv', 'Memory Management')
csv_heatmap('../out/net_line_fixed_norm_out.csv', 'Net')

plot_histogram('../out/Line_EXE_PORTIONS.csv')

plot_heatmap('../out/hot_line_cos.mat', '', false)