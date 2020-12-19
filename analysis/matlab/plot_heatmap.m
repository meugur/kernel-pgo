function plot_heatmap(filename, title_in, flip_cmap)
    data = load(filename);

    h = [linspace(0,0,100),linspace(120,120,100)] / 360;
    s = [linspace(1,0,100), linspace(0,1,100)];
    v = linspace(1,1,200);
    cmap = squeeze(hsv2rgb(cat(3,h,s,v)));

    f = figure();

    if flip_cmap
        cmap = flipud(cmap);
    end

    h = heatmap(data.bench, data.bench, data.score, 'colormap', cmap);

    h.CellLabelFormat = '%0.2f';

    caxis([0, max(max(data.score(:)),1)]);
    %title(title_in)

    ax = gca();
    ax.FontSize=14;

    [~, basename, ~] = fileparts(filename);
    print(f, ['eecs582_', basename], '-dpng')

end
