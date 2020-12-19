function csv_heatmap(filename, sufx)
    
    data = readmatrix(filename);
    apps = categorical({'apache', ...
            'leveldb', ...
            'memcached', ...
            'mysql', ...
            'nginx', ...
            'postgresql', ...
            'redis', ...
            'rocksdb'});
    
    h = [linspace(0,0,100),linspace(120,120,100)] / 360;
    s = [linspace(1,0,100), linspace(0,1,100)];
    v = linspace(1,1,200);
    cmap = squeeze(hsv2rgb(cat(3,h,s,v)));
   
    f = figure();
    h = heatmap(apps, apps, data, 'colormap', cmap);
    h.CellLabelFormat = '%0.2f';
    
    caxis([0, 1]);
    %title(['Line Frequency Cosine Similarity - ', sufx]);
    
    ax = gca();
    ax.FontSize=14;
    
    [~, basename, ~] = fileparts(filename);
    print(f, ['eecs582_', basename], '-dpng')

end
