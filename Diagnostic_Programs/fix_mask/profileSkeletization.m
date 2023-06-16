% Outcome on my Cedric's machine:
% Connected to parallel pool with 32 workers.
% Time sequential bwskel : 61.65s
% Time sequential bwmorph : 3.49s
% Time parfor with bwskel on 5478 inputs : 44.09s
% Time parfor with bwmorph on 5478 inputs : 0.36s


% Initialize.
clear ;

nPages = 4 ;   % # pages for visual comparison.


%% Part 1 - Skeletize using bwskel and bwmorph, sequentially or in parallel.

% Load inputs for skeletization.
load('skelInputs.mat') ;

parpoolArg = "threads" ;
%parpoolArg = 32 ;

nInputs = numel(skelInputs) ;
minBranchLength = 0 ;

% Shutdown parallel pool if exists. This is to guarantee that we have the
% pool that we want when we change the args during the test phase. In the
% production setup, we create the pool once and for all and we leave it
% open.
if ~isempty(gcp('nocreate'))
    delete(gcp) ;
end
pp = parpool(parpoolArg) ;
nWorkers = pp.NumWorkers ;


% Time sequential processing with bwskel.
tic ;
bwskelOutputs = cell(nInputs, 1) ;
for skIx = 1 : nInputs
    bwskelOutputs{skIx} = bwskel(logical(skelInputs{skIx}),'MinBranchLength', minBranchLength) ;
end
fprintf('Time sequential bwskel : %.2fs\n', toc) ;


% Time sequential processing with bwmorph.
tic ;
bwmorphOutputs = cell(nInputs, 1) ;
for skIx = 1 : nInputs
    bwmorphOutputs{skIx} = bwmorph(logical(skelInputs{skIx}), 'skel', Inf) ;
end
fprintf('Time sequential bwmorph : %.2fs\n', toc) ;


% Time parallel processing iterating over inputs with bwskel.
tic ;
bwskelOutputs = cell(nInputs, 1) ;
parfor skIx = 1 : nInputs
    bwskelOutputs{skIx} = bwskel(logical(skelInputs{skIx}),'MinBranchLength', minBranchLength) ;
end
fprintf('Time parfor with bwskel on %d inputs : %.2fs\n', nInputs, toc) ;


% Time parallel processing iterating over inputs with bwmorph.
tic ;
bwmorphOutputs = cell(nInputs, 1) ;
parfor skIx = 1 : nInputs
    bwmorphOutputs{skIx} = bwmorph(logical(skelInputs{skIx}), 'skel', Inf) ;
end
fprintf('Time parfor with bwmorph on %d inputs : %.2fs\n', nInputs, toc) ;


% Less performant than iterating over inputs when using thread pool.
% % Time parallel processing iterating over blocks of inputs.
% tic ;
% blockSize = ceil(nInputs/nWorkers);
% nBlocks = ceil(nInputs/blockSize) ;
% blockSizes = diff([1 : blockSize : nInputs, nInputs+1]) ;
% inputBlocks = mat2cell(bwskelInputs, blockSizes) ;
% bwskelBlocks = cell(nBlocks, 1) ;
% parfor bIx = 1 : nBlocks
%     bwskelBlocks{bIx} = cell(blockSizes(bIx), 1) ;
%     for skIx = 1 : blockSizes(bIx)
%         skelBlocks{bIx}{skIx} = bwskel(logical(inputBlocks{bIx}{skIx}),'MinBranchLength', minBranchLength) ;
%     end
% end
% bwskelOutputs = vertcat(bwskelBlocks{:}) ;
% fprintf('Time parfor on %d blocks : %.2fs\n', nBlocks, toc) ;


%% Part 2 - Display inputs and outputs of bwskel and bwmorph.

close all ;

% Set up page content specs.
nRowsPerCol = 8 ;
nCols = 5 ;
colWidth = 1/nCols ;
wGap = 0.05 * colWidth ;
wTextAxes = colWidth/12 ;
wImgAxes = (colWidth - wTextAxes - 2*wGap)/3 * 0.8 ;
rowHeight = 0.99/nRowsPerCol ;
hAxes = 0.95*rowHeight ;

for skIx = 1 : min(nPages*nRowsPerCol*nCols, numel(skelInputs))
    rowIx = mod(skIx-1, nRowsPerCol) + 1 ;
    colIx = mod(floor((skIx-1)/nRowsPerCol), nCols) + 1 ;
    
    if colIx == 1 && rowIx == 1
        % Create/initialize new figure.
        figure('Units', 'normalized', 'Position', [0.05, 0.05, 0.9, 0.85], 'Color', 'white') ;
        axes('Position', [0,0.95,1,0.05], 'XColor', 'none', 'YColor', 'none', 'Color', 'none') ;
        ylim([0, 1]) ;
        for k = 1 : nCols
            x0 = 0.01 + (k-1)*colWidth + wTextAxes + wGap + wImgAxes/2 ;
            text(x0, 1, 'INPUT', 'VerticalAlignment', 'top', 'HorizontalAlignment','center', 'Color', [0,0,0.5]) ;
            text(x0 + wImgAxes+wGap, 1, 'BWSKEL', 'VerticalAlignment', 'top', 'HorizontalAlignment','center', 'Color', [0,0,0.5]) ;
            text(x0 + 2*(wImgAxes+wGap), 1, 'BWMORPH', 'VerticalAlignment', 'top', 'HorizontalAlignment','center', 'Color', [0,0,0.5]) ;
        end
    end

    y = 0.99 - rowIx*rowHeight ;
    x0 = 0.01 + (colIx-1)*colWidth ;
    
    axes('Position', [x0,y,wTextAxes,hAxes], 'XColor', 'none', 'YColor', 'none', 'Color', 'white') ;
    ylim([0,1]) ;
    sz = size(skelInputs{skIx}) ;
    text(0, 0.7, sprintf('%d', skIx), 'VerticalAlignment', 'middle', 'HorizontalAlignment', 'left', 'FontWeight','bold') ;
    text(0, 0.5, sprintf('h=%d', sz(1)), 'VerticalAlignment', 'middle') ;
    text(0, 0.3, sprintf('w=%d', sz(2)), 'VerticalAlignment', 'middle') ;
    
    x = x0 + wTextAxes + wGap ;
    axes('Position', [x,y,wImgAxes,hAxes], 'XColor', 'none', 'YColor', 'none', 'Color', 'white') ;
    imshow(skelInputs{skIx}) ;

    x = x + wImgAxes + wGap ;
    axes('Position', [x,y,wImgAxes,hAxes], 'XColor', 'none', 'YColor', 'none', 'Color', 'white') ;
    imshow(bwskelOutputs{skIx}) ;

    x = x + wImgAxes + wGap ;
    axes('Position', [x,y,wImgAxes,hAxes], 'XColor', 'none', 'YColor', 'none', 'Color', 'white') ;
    imshow(bwmorphOutputs{skIx}) ;

end
