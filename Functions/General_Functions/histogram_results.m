function histogram_results(iFig, Var1, Var2, Region, histogram_bins, XLABEL, Var1_Legend, Var2_Legend, TITLE)
% histogram_results - histograms of gradients for declouding work.
%
% Will histogram two variables and annotate the histogram
%
% INPUT
%   iFig - Figure number to use.
%   Var1 - First variable to histogram.
%   Var2 - Second variable to histogram. Assumed to be the same size as Var1.
%   Region - a nx4 element vector deliniating the region to select out of the
%    input variables. [1st element of 1st dimension, 2nd element of 2nd
%    dimension]. If one row, the same region will be used for both variables.
%    If two rows, 1st row for Var1 and secvond row for Var2. If empty will
%    do entire array.
%   histogram_bins - a 3 element vector with the 1st bin, bin size, last bin.
%   XLABEL - label to use for the horizontal axis.
%   Var1_Legend - text to use for the legend of the 1st variable.
%   Var2_Legend - text to use for the legend of the 2nd variable.
%   TITLE - title of histogram.%

figure(iFig)
clf

if isempty(Region)
    Region(1) = 1;
    Region(2) = size(Var1,1);
    Region(3) = 1;
    Region(4) = size(Var1,2);
end

iVar = 1;
if size(Region,1) > 1
    iVar = 2;
end

tt = Var1(Region(1,1):Region(1,2),Region(1,3):Region(1,4));
gm_km = tt(isnan(tt)==0);

tt = Var2(Region(iVar,1):Region(iVar,2),Region(iVar,3):Region(iVar,4));
gm_in_km = tt(isnan(tt)==0);

gr1 = histogram(gm_km, histogram_bins, displaystyle='stairs', normalization='probability', LineWidth=1);
hold on
gr2 = histogram(gm_in_km, histogram_bins, displaystyle='stairs', normalization='probability', LineWidth=1);

% Annotate

set(gca,fontsize=20)
grid on
xlabel(XLABEL)
ylabel('Probability')

legend([gr1, gr2], {Var1_Legend, Var2_Legend})

title(TITLE, fontsize=30)

end