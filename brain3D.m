%% brain3D
% This function provides a 3D view of the brain and of the electrodes,
% either cortical or on the scalp, eventually highlighting some of them
% with two different highlight colors (red or blue), allowing to link pairs 
% of electrodes.
%
% brain3D(chanlocs, highlight, second_highlight, show_labels, links, ...
%         intensities)
%
% Input:
%    chanlocs is the channels structure, contianing at least the XYZ
%        coordinates (empty by default, if empty no channels will be shown)
%    highlight is the channels structure, contianing at least the XYZ
%        coordinates of the channels which have to be highlighted in red 
%        (empty by default)
%    second_highlight is the channels structure, contianing at least the
%        XYZ coordinates of the channels which have to be highlighted in 
%        blue (empty by default)
%    show_labels has to be 1 in order to show the label associated to each
%        electrode, 0 otherwise (0 by default)
%    links is the (N x 2) string matrix containing the pairs of names
%       related to the channels which have to be linked on each row (empty
%       by default)
%    intensities is an array containing the intensities for each link,
%       which will be mapped between the blue (lower negative) to the red
%       (highest positive), passing through the green (black lines if 
%       empty, empty by default)

function brain3D(chanlocs, highlight, second_highlight, show_labels, ...
    links, intensities)

    if nargin < 1
        chanlocs = [];
    end
    if nargin < 2 | isempty(highlight)
        highlight = [];
    end
    if nargin < 3 | isempty(second_highlight)
        second_highlight = [];
    end
    if nargin < 4 | isempty(show_labels)
        show_labels = 0;
    end
    if nargin < 5
        links = [];
    end
    if nargin < 6
        intensities = [];
    end
    
    plot_brain();
    dim = 30;  %electrodes size
    hdim = 20; %inner highlight size
    
    N = length(chanlocs);
    labels = strings(N, 1);
    for i = 1:N
        labels(i) = string(chanlocs(i).labels);
    end
    
    if not(isempty(chanlocs))
        if show_labels == 1
            plot_channels(adjust_coordinates(chanlocs), 'k', ...
                'markersize', dim, 'showlabels', labels, ...
                'scatterarg', {'filled'});
        else
            plot_channels(adjust_coordinates(chanlocs), 'k', ...
                'markersize', dim, 'scatterarg', {'filled'});
        end
        if not(isempty(links))
            plot_links(labels, adjust_coordinates(chanlocs), links, ...
                intensities)
        end
        if not(isempty(highlight))
            plot_channels(adjust_coordinates(highlight), 'k', ...
                'markersize', hdim, 'scatterarg', ...
                {'MarkerFaceColor', 'r'});
        end
        if not(isempty(second_highlight))
            plot_channels(adjust_coordinates(second_highlight), ...
                'k', 'markersize', hdim, 'scatterarg', ...
                {'MarkerFaceColor', 'b'});
        end
    end
    hold on
    try
        set(gcf,'WindowButtonMotionFcn', @fix_light);
    catch
        warning('Light cannot be fixed')
    end
    hold off
end


%% adjust_coordinates
% This function adjusts the coordinates of the electrodes in order to
% provide a qualitatively better view with respect to the shown brain.
%
% coordinates = adjust_coordinates(chanlocs)
%
% Input:
%   chanlocs is the structure containing at least the X, Y and Z fields
%       for each element representing a single electrode, and containing 
%       the related coordinates
%
% Output:
%   coordinates it the (N*3) matrix containing the the X, Y and Z adjusted
%       coordinates and N electrodes

function coordinates = adjust_coordinates(chanlocs)
    coordinates = [[chanlocs(:).Y]', [chanlocs(:).X]', [chanlocs(:).Z]'-1];
    coordinates(:, 2) = coordinates(:, 2)*1.2-20;
end


%% plot_brain
% This function plots the 3D brain image.
%
% plot_brain()

function plot_brain()
    load('brain_data');
    figure('Color', 'w');
    plot_hemisphere(brain_data.right);
    plot_hemisphere(brain_data.left);
    set(gcf, 'Name', '3D Brain');
    rotate3d on;
end


%% plot_hemisphere
% This function plots a 3D hemisphere of the brain (This function is 
% partially based on Edden M. Gerber, 2021: Anatomical data visualization 
% toolfbox for fMRI/ECoG).
% 
% handle = plot_hemisphere(hemi_mesh)
%
% Input:
%   hemi_mesh is the input structure providing the vertexes and the faces
%       of the 3D image representing the hemisphere
%
% Output:
%   handle is the handle to the 3D figure

function handle = plot_hemisphere(hemi_mesh)
    brain_color = [0.85 0.85 0.85]; % Light gray
    transparency = 0;
    view_position = [0 0];
    
    color_map = jet(64);
    color_map = [interp1(1:2:63,color_map(33:64,1), 1:63)', ...
        interp1(1:2:63,color_map(33:64,2), 1:63)', ...
        interp1(1:2:63,color_map(33:64,3), 1:63)'];
    color_map = [brain_color ; color_map];
    
    vertex_color_values = zeros(length(hemi_mesh.vertices), 1);
    handle = trisurf(hemi_mesh.faces, hemi_mesh.vertices(:, 1), ...
        hemi_mesh.vertices(:, 2), hemi_mesh.vertices(:,3),...
        'FaceLighting','gouraud');
    set(handle, 'FaceVertexCData', vertex_color_values);
    colormap(color_map);
    set(handle,'FaceAlpha', 1-transparency);
    shading('interp');
    material('dull');
    axis('xy');
    axis('tight');
    axis('equal');
    axis('off');
    hold('all');
    view(view_position);
    l = light();
    camlight(l, 'headlight');
    cameratoolbar('Show');
    if all(vertex_color_values==0)
        caxis([0 1]);
    end 
end


%% fix_light
% This function fixes the light_source of the figure.
%
% fix_light(fig_handle, varagin)
%
% Input:
%   fig_handle is the handle of the figure

function fix_light(fig_handle, varargin)
    if nargin<1
        fig_handle = gcf;
    end
    l_handle = findobj(fig_handle, 'Type', 'light');
    if isempty(l_handle)
        l_handle = light;
    end
    if length(l_handle) > 1
        l_handle = l_handle(end);
    end
    camlight(l_handle,'headlight');
end


%% plot_channels
% This function plots the electrodes in the mesh 3D figure, eventually
% showing the related labels and choosing the color of the shown points
% representing the electrodes.
%
% plot_channels(coordinates, varargin)
%
% Input:
%   coordinates is the (N*3) matrix representing the XYZ coordinates for
%       each of the N channels which have to be shown
%   varargin is the variable size cell array containing various parameters,
%       which can be single parameters as well as name-value pairs, among
%       'showlabels' (to show the electrodes' labels, in this case the
%       following parameter has to be the string array for each electrode)
%       and the related string array, 'markersize' (to define the size of
%       each point representing an electrode, in this case the following
%       parameter has to be the number representing that size) and the
%       related value, 'scatterarg' (to add an argument for the 3D scatter
%       plotting, in this case the following argument must be the scatter
%       argument) and the related scatter argument, and the marker color
%       (which is black by default)

function plot_channels(coordinates, varargin)
    marker_size = 50;
    show_labels = false;
    marker_color = 'k';
    scatter_arg = {};
    narg = size(varargin, 2);
    arg = 1;
    
    while arg <= narg
        param = varargin{arg};
        if ischar(param)
            if strcmpi(param, 'showlabels')
                labels = varargin{arg+1};
            	show_labels = true;
                arg = arg+2;
            elseif strcmpi(param, 'markersize')
                marker_size = varargin{arg+1};
                arg = arg+2;
            elseif strcmpi(param, 'scatterarg')
                scatter_arg = varargin{arg+1};
                arg = arg+2;
            else
                marker_color = varargin{arg};
                arg = arg+1;
            end    
        end
    end
    
    scatter3(coordinates(:, 1), coordinates(:, 2), coordinates(:, 3), ...
        marker_size, marker_color, scatter_arg{:});
    
    if show_labels
        fixed_coordinates = coordinates*1.05;
        for i = 1:size(coordinates, 1)
            text(fixed_coordinates(i, 1), fixed_coordinates(i, 2), ...
                fixed_coordinates(i, 3), labels(i));
        end
    end
end


%% plot_links
% This function is used for showing the links among different channels.
%
% plot_links(labels, coordinates, links, intensities)
%
% Input:
%   labels is the string array of channel names
%   coordinates is the (N x 3) matrix containing the xyz coordinates
%   links is the (N x 2) string matrix containing the pairs of names of
%       channels which have to be linked
%   intensities is an array containing the intensities for each link,
%       which will be mapped between the blue (lower negative) to the red
%       (highest positive), passing through the green (black lines if 
%       empty)

function plot_links(labels, coordinates, links, intensities)
    nChans = length(labels);
    nLinks = size(links, 1);
    if isempty(intensities)
        intensities = zeros(nLinks, 3);
    else
        intensities = values_mapping(intensities);
    end  
    for i = 1:nLinks
        idxs = [0 0];
        for ch = 1:2
            for lbl = 1:nChans
                if strcmp(labels{lbl}, links(i, ch))
                    idxs(ch) = lbl;
                end
            end
        end
        if idxs(1) > 0 & idxs(2) > 0
            plot3(coordinates(idxs, 1), coordinates(idxs, 2), ...
                coordinates(idxs, 3), 'Color', intensities(i, :))
        end
    end
end
         

%% values_mapping
% This function returns the values mapped on the color map, centered the
% map on the zero value.
%
% mapped = values_mapping(values)
%
% Input:
%   values is the array of single values which has to be mapped into the
%       corresponding RGB values
%
% Output:
%   mapped is the array of RGB values

function mapped = values_mapping(values)
    N = length(values);
    mapped = zeros(N, 3);
    cmp = color_function();
    range = size(cmp, 1)/2;
    cmp = [cmp(1, :); cmp; cmp(end, :)]; %avoid errors in boudaries
    values = values/max(abs(values));
    values = values*range+range+1;
    for i = 1:N
        int_val = floor(values(i));
        frac_val = values(i)-int_val;
        mapped(i, :) = frac_val*cmp(int_val+1, :)+(1-frac_val)*cmp(int_val, :);
    end
end

%% color_function
% This function provides the color map.
%
% cmp = color_function()
%
% Output:
%   cmp is the (64 x 3) array representing the color map as rgb values

function cmp = color_function()
    cmp = [0, 0, 0.5625; 0, 0, 0.625; 0, 0, 0.6875; 0, 0, 0.75; ...
        0, 0, 0.8125; 0, 0, 0.875; 0, 0, 0.9375; 0, 0, 1; 0, 0.0625, 1; ...
        0, 0.125, 1; 0, 0.1875, 1; 0, 0.25, 1; 0, 0.3125, 1; ...
        0, 0.375, 1; 0, 0.4375, 1; 0, 0.5, 1; 0, 0.5625, 1; ...
        0, 0.625, 1; 0, 0.6875, 1; 0, 0.75, 1; 0, 0.8125, 1; ...
        0, 0.875, 1; 0, 0.9375, 1; 0, 1, 1; 0.0625, 1, 0.9375; ...
        0.125, 1, 0.875; 0.1875, 1, 0.8125; 0.25, 1, 0.75; ...
        0.3125, 1, 0.6875; 0.375, 1, 0.625; 0.4375, 1, 0.5625; ...
        0.5, 1, 0.5; 0.5625, 1, 0.4375; 0.625, 1, 0.375; ...
        0.6875, 1, 0.3125; 0.75, 1, 0.25; 0.8125, 1, 0.1875; ...
        0.875, 1, 0.125; 0.9375, 1, 0.0625; 1, 1, 0; 1, 0.9375, 0; ...
        1, 0.875, 0; 1, 0.8125, 0; 1, 0.75, 0; 1, 0.6875, 0; ...
        1, 0.625, 0; 1, 0.5625, 0; 1, 0.5, 0; 1, 0.4375, 0; ...
        1, 0.375, 0; 1,0.3125, 0; 1, 0.25, 0; 1, 0.1875, 0; ...
        1, 0.125, 0; 1, 0.0625, 0; 1, 0, 0; 0.9375, 0, 0; 0.875, 0, 0; ...
        0.8125, 0, 0; 0.75, 0, 0; 0.6875, 0, 0; 0.625, 0, 0; ...
        0.5625, 0, 0; 0.5, 0, 0];
end