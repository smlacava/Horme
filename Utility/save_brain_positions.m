%% save_brain_positions
% This function is able to produce a single image containing the brain
% represented in various positions (top, left, right, front and back).
%
% save_brain_positions(imageDir, imageName, chanlocs, highlight, ...
%        second_highlight, labels_check, links, intensities)
%
% Input:
%   imageDir is the name of the directory in which the image has to be
%       saved (note that during the process 5 images, named aux_front.jpg,
%       aux_top.jpg, aux_back.jpg, aux_right.jpg and aux_left.jpg, will be
%       created and deleted, so avoid having some images having the same
%       name within the chosen directory or they will be deleted as well)
%   imageName is the name of the image (without extension)
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
function save_brain_positions(imageDir, imageName, chanlocs, highlight, ...
    second_highlight, show_labels, links, intensities)

    if nargin < 3
        chanlocs = [];
    end
    if nargin < 4 | isempty(highlight)
        highlight = [];
    end
    if nargin < 5 | isempty(second_highlight)
        second_highlight = [];
    end
    if nargin < 6 | isempty(show_labels)
        show_labels = 0;
    end
    if nargin < 7
        links = [];
    end
    if nargin < 8
        intensities = [];
    end
    
    coordinates = {[180, 5], [180, 90], [0, 5], [90, 0], [-90, 0]};
    positions = {'front', 'top', 'back', 'right', 'left'};
    nPos = length(coordinates);
    aux = split(imageDir, filesep);
    imageDir = '';
    for i = 1:length(aux)
        imageDir = strcat(imageDir, aux{i}, filesep);
    end

    brain3D(chanlocs, highlight, second_highlight, show_labels, links, ...
        intensities)
    for n = 1:nPos
        view(coordinates{n})
        delete(findall(gcf,'Type','light'))
        l = light();
        camlight(l, 'headlight')
        drawnow
        set(gca,'LooseInset',get(gca,'TightInset'));
        saveas(gcf,strcat(imageDir, 'aux_', positions{n}, '.jpg'))
    end
    close(gcf)
    
    f = figure('Color', 'w');
    subplot(2, 3, [2, 5])
    data = imread(strcat(imageDir, 'aux_', positions{2}, '.jpg'));
    imshow(data);
    subplot(2, 3, 1)
    data = imread(strcat(imageDir, 'aux_', positions{1}, '.jpg'));
    imshow(data);
    subplot(2, 3, 3)
    data = imread(strcat(imageDir, 'aux_', positions{3}, '.jpg'));
    imshow(data);
    subplot(2, 3, 4)
    data = imread(strcat(imageDir, 'aux_', positions{4}, '.jpg'));
    imshow(data);
    subplot(2, 3, 6)
    data = imread(strcat(imageDir, 'aux_', positions{5}, '.jpg'));
    imshow(data);
    
    ha=get(gcf, 'children');
    set(ha(1),'position',[.66 .05 .33 .45])
    set(ha(2),'position',[.0 .05 .33 .45])
    set(ha(3),'position',[.66 .5 .33 .45])
    set(ha(4),'position',[.0 .5 .33 .45])
    set(ha(5),'position',[.25 .05 .5 .9])
    saveas(gcf, strcat(imageDir, imageName, '.jpg'));
    close all
    
    for n = 1:nPos
        eval(strcat("delete ", imageDir, 'aux_', positions{n}, '.jpg'))
    end
end