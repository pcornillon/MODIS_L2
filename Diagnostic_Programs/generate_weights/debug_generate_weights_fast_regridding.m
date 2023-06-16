disp([' Below 3: '])
disp(['   1 to print weights, '])
disp(['   2 to plot points, '])
disp(['   3 to print contributors to a new grid point, '])
disp(['   4 to plot triange, and ']);
disp(['   5 to print locations of points on the input grid contributing to nn(kk), and '])
disp(['   6 to load a mess of weights and print them out for an output location.'])
disp(['   7 to plot weight stuff.'])
disp(['   8 to plot weights and locations for selected scan lines.'])
disp([' '])
what_to_do = input('Make your selection: ');

if exist('nn') == 0
    load ~/Desktop/temp_generate_weights
end

switch what_to_do
    case 1
        new_weight = zeros(size(weight_temp));
        
        for i=1t:10
            for jt=1:11
                fprintf('weight_temp(%i, %i) nn: %10.4f\n', it, jt, weight_temp{it,jt})
            end
        end
        
        % clf
        % imagesc(new_weight)
        
    case 2
        figure(2)
        clf
        
        srows = input('Row to start displaying: ');
        erows = input('Row to end displaying: ');
        
        %     scolumns = input('Column to start displaying: ');
        %     eColumns = input('Column to end displaying: ');
        
        iSel = input('Enter the row: ');
        jSel = input('Enter the column: ');
        
        plot(x_coor(srows:erows,:),y_coor(srows:erows,:),'.k',markersize=10)
        set(gca, fontsize=20)
        hold on
        
        for it=srows:erows
            for jt=1:11
                text(x_coor(it,jt)+.002, y_coor(it,jt)+0.001, ['(' num2str(it) ', ' num2str(jt) ')'])
            end
        end
        
        title(['vin(' num2str(iSel) ', ' num2str(jSel) ')'], fontsize=32)
        
        plot(x_coor(iSel,jSel),y_coor(iSel,jSel),'.k', markersize=20)
        
        if exist('weight_temp')
            nnt = weight_temp{iSel,jSel}
        else
            nnt = nn;
        end
        [It, Jt] = ind2sub(size(vout), nnt);
        fprintf('%4i %4i\n', [It, Jt]')
        
        % % %     % Remove guys on the other end of the scan line.
        % % %
        % % %     ii = find(nn==2708);
        % % %     if isempty(ii) == 0
        % % %         disp(['Removed ' 2708 ' from this vector.'])
        % % %         nn = nn(find(nn~=2708));
        % % %     end
        
        [It, Jt] = ind2sub(size(vout), nnt);
        
        plot(new_x_coor(nnt), new_y_coor(nnt), '.m', markersize=15)
        for it=1:length(It)
            text(new_x_coor(It(it),Jt(it))-.01, new_y_coor(It(it),Jt(it)), ['(' num2str(It(it)) ', ' num2str(Jt(it)) ')'], color='m')
        end
        %         text(x_coor(iSel,jSel)+0.002, y_coor(iSel,jSel)+0.001, ['(' num2str(iSel) ', ' num2str(jSel) ')'], color='c')
        text(new_x_coor(iSel,jSel)+0.002, new_y_coor(iSel,jSel)+0.001, ['(' num2str(iSel) ', ' num2str(jSel) ')'], color='c')
        
        plot(new_x_coor(srows:erows,:), new_y_coor(srows:erows,:),'.r',markersize=10)
        % for it=1:3
        %     for jt=1:11
        %         text(new_x_coor(it,jt)-.05, new_y_coor(it,jt), ['(' num2str(i)
        %           ', ' num2str(jt) ')'], color='r')
        %     end
        % end
        
        axis equal
        grid on
        
    case 3
        new_weight = zeros(size(weight_temp));
        
        iSel = input('Enter the row of the new coordinate point to search for: ');
        % jSel = input('Enter the column of the new coordinate point to search for: ');
        
        for jSel=1:11
            ijt = sub2ind(size(weight_temp), iSel, jSel);
            
            
            fprintf('\nSearching for %i\n', ij)
            
            for it=1:10
                for jt=1:11
                    nnt = weight_temp{it,jt};
                    if isempty(find(nn==ijt)) == 0
                        fprintf('MODIS grid location (%i, %i) contributed to regridded location (%i, %i) \n', it, jt, iSel, jSel)
                    end
                end
            end
        end
        
        % Plot triangles
    case 4
        
        pts(1,:) = input('Enter the row & column of 1st point [# #]: ');
        pts(2,:) = input('Enter the row & column of 2nd point [# #]: ');
        pts(3,:) = input('Enter the row & column of 3rd point [# #]: ');
        plot([x_coor(pts(1,1), pts(1,2)), x_coor(pts(2,1), pts(2,2))], [y_coor(pts(1,1), pts(1,2)), y_coor(pts(2,1), pts(2,2))], 'r', linewidth=2)
        plot([x_coor(pts(3,1), pts(3,2)), x_coor(pts(2,1), pts(2,2))], [y_coor(pts(3,1), pts(3,2)), y_coor(pts(2,1), pts(2,2))], 'r', linewidth=2)
        plot([x_coor(pts(1,1), pts(1,2)), x_coor(pts(3,1), pts(3,2))], [y_coor(pts(1,1), pts(1,2)), y_coor(pts(3,1), pts(3,2))], 'r', linewidth=2)
        
        % Print locations of points on the input grid contributing to nn(kk)
    case 5
        if exist('nn_to_use') == 0
            nn_to_use = nn;
            special_nn = nn(k);
        end
        
        for i=1:length(nn_to_use)
            eval(['tt(i) = weights' num2str(i) '(special_nn);']);
            eval(['qq(i) = locations' num2str(i) '(special_nn);']);
            [Iqq(i), Jqq(i)] = ind2sub(size(vout), qq(i));
            fprintf('weights %i: %i, locations%i: %i, I=%i, J=%i\n', i, tt(i), i, qq(i), Iqq(i), Jqq(i))
        end
        disp(' ')
        
        % Plot locations of input grid and write scan line and pixel numbers.
        
        srows = input('Row to start displaying input grid: ');
        erows = input('Row to end displaying input grid: ');
        
        figure(5)
        clf
        
        plot(x_coor(srows:erows,:),y_coor(srows:erows,:),'.k',markersize=10)
        set(gca, fontsize=20)
        hold on
        
        for it=srows:erows
            for jt=1:11
                text(x_coor(it,jt)+.002+(jt-1)*0.003, y_coor(it,jt)+0.001, ['(' num2str(it) ', ' num2str(jt) ')'])
            end
        end
        
        % Plot the new grid location of interest.
        
        [iSel, jSel] = ind2sub(size(vout), special_nn);
        plot(new_x_coor(iSel,jSel),new_y_coor(iSel,jSel),'.c', markersize=20)
        
        text(new_x_coor(iSel,jSel)+0.002, new_y_coor(iSel,jSel)+0.001, ['(' num2str(iSel) ', ' num2str(jSel) ')'], color='c')
        
        % Plot the input grid locations contributing to the point of interest.
        
        plot(x_coor(qq), y_coor(qq), '.m', markersize=15)
        for it=1:length(qq)
            text(x_coor(Iqq(it),Jqq(it))+.002+(Jqq(it)-1)*0.003, y_coor(Iqq(it),Jqq(it))+0.001, ['(' num2str(Iqq(it)) ', ' num2str(Jqq(it)) ')'], color='m')
        end
        
        % Finally plot the new grid locations for the same range as the input grid.
        
        plot(new_x_coor(srows:erows,:), new_y_coor(srows:erows,:),'.r',markersize=10)
        
        % Annotate
        
        title(['vout(' num2str(iSel) ', ' num2str(jSel) ')'], fontsize=32)
        axis equal
        grid on
        
        % Here to load a mess of weights and print them out for an output location.
    case 6
        iElement = input('Enter the element number for the pixel of interest: ');
        iScan = input('Enter the line number for the pixel of interest: ');
        
        filelist = dir('/Volumes/Aqua-1/Fronts/MODIS_Aqua_L2/SupportingFiles/Weights/weights_*');
        numfiles = length(filelist);
        
        weights = nan(numfiles,6);
        locations = zeros(numfiles,6);
        
        % Print weights for this point first.
        
        for iFile=1:numfiles
            datain{iFile} = load([filelist(iFile).folder '/' filelist(iFile).name]);
            
            wt = datain{iFile}.weights(:,iElement,iScan);
            weights(iFile,1:length(wt)) = wt;
            
            fprintf('w%i:   %.4f   %.4f   %.4f   %.4f   %.4f   %.4f \n', iFile, weights(iFile,:))
        end
        disp([' '])
        
        % Now print locations for this point.
        
        for iFile=1:numfiles
            lt = datain{iFile}.locations(:,iElement,iScan);
            
            locations(iFile,1:length(lt)) = lt;
            
            [Il(iFile,:), Jl(iFile,:)] = ind2sub( [1354, 11], locations(iFile,:));
            
            
            fprintf('w%i:   (%i,%i)   (%i,%i)   (%i,%i)   (%i,%i)   (%i,%i)   (%i,%i) \n', iFile, ...
                Il(iFile,1), Jl(iFile,1), ...
                Il(iFile,2), Jl(iFile,2), ...
                Il(iFile,3), Jl(iFile,3), ...
                Il(iFile,4), Jl(iFile,4), ...
                Il(iFile,5), Jl(iFile,5), ...
                Il(iFile,6), Jl(iFile,6))
        end
        
        Color = {'r' 'k' 'g' 'b' 'm' 'c' 'r' 'k' 'g' 'b' 'm' 'c' 'r' 'k' 'g' 'b' 'm' 'c' 'r' 'k' ...
            'r' 'k' 'g' 'b' 'm' 'c' 'r' 'k' 'g' 'b' 'm' 'c' 'r' 'k' 'g' 'b' 'm' 'c' 'r' 'k'...
            'r' 'k' 'g' 'b' 'm' 'c' 'r' 'k' 'g' 'b' 'm' 'c' 'r' 'k' 'g' 'b' 'm' 'c' 'r' 'k'...
            'r' 'k' 'g' 'b' 'm' 'c' 'r' 'k' 'g' 'b' 'm' 'c' 'r' 'k' 'g' 'b' 'm' 'c' 'r' 'k'};
        figure(6)
        clf
        
        for iFile=1:numfiles
            for iCont=1:6
                if Il(iFile,iCont)~=0 & Jl(iFile,iCont)~=0
                    plot3( x_coor(Il(iFile,iCont), Jl(iFile,iCont)), y_coor(Il(iFile,iCont), Jl(iFile,iCont)), iFile, 'ok', markerfacecolor=Color{iFile});
                    hold on
                end
            end
        end
        grid on
        
        % Weights
    case 7
        
        figure(71)
        clf
        
        max_num = 3;
        
        aa = load(['/Volumes/Aqua-1/Fronts/MODIS_Aqua_L2/SupportingFiles/Weights/weights_11001.mat']);
        augmented_weights_11001 = zeros(max_num, size(aa.weights,2), nSegs*size(aa.weights,3));
        augmented_locations_11001  = zeros(max_num, size(aa.weights,2), nSegs*size(aa.weights,3));
        for iSegs=1:nSegs
            augmented_weights_11001 (:,:,10*(iSegs-1)+1:10*(iSegs-1)+10) = aa.weights(:,:,1:10);
            augmented_locations_11001 (:,:,10*(iSegs-1)+1:10*(iSegs-1)+10) = jlower-1 + (iSegs-1)*10 + aa.locations(:,:,1:10);
        end
        for i=1:3
            subplot(3,1,i)
            imagesc(squeeze(augmented_weights_11001(i,:,:))')
            caxis([0 1])
            colorbar
        end
        
        figure(72)
        clf
        
        aa = load(['/Volumes/Aqua-1/Fronts/MODIS_Aqua_L2/SupportingFiles/Weights/weights_31001.mat']);
        augmented_weights_31001  = zeros(max_num, size(aa.weights,2), nSegs*size(aa.weights,3));
        augmented_locations_31001 = zeros(max_num, size(aa.weights,2), nSegs*size(aa.weights,3));
        for iSegs=1:nSegs
            augmented_weights_31001(:,:,10*(iSegs-1)+1:10*(iSegs-1)+10) = aa.weights(:,:,1:10);
            augmented_locations_31001(:,:,10*(iSegs-1)+1:10*(iSegs-1)+10) = jlower-1 + (iSegs-1)*10 + aa.locations(:,:,1:10);
        end
        for i=1:3
            subplot(3,1,i)
            imagesc(squeeze(augmented_weights_31001(i,:,:))')
            caxis([0 1])
            colorbar
        end
        
        wd = augmented_weights_11001 - augmented_weights_31001;
        
        figure(73)
        clf
        
        for i=1:3
            subplot(3,1,i)
            imagesc(squeeze(wd(i,:,:))')
            caxis([0 0.5])
            colorbar
        end
        
        fprintf('\n WEIGHT STATS \n Weight difference between scan lines 31001 and 11001: %4f to %4f \n', min(wd,[],'all'), max(wd,[],'all'))
        fprintf('Third weight difference for scan lines 11001: %4f to %4f \n', min(augmented_weights_11001(3,:,:),[],'all'), max(augmented_weights_11001(3,:,:),[],'all'))
        
        figure(74)
        clf
        
        for i=1:3
            subplot(3,1,i)
            histogram(augmented_weights_11001(i,1:677,:),[0:0.01:1])
            hold on
            histogram(augmented_weights_11001(i,678:end,:),[0:0.01:1],FaceColor='r')
        end
        set(gca, fontsize=20)
        sgtitle('11001 Elements 1:677 vs 678')
        legend('1:677','678:end')
        
        figure(75)
        clf
        
        for i=1:3
            subplot(3,1,i)
            histogram(augmented_weights_11001(i,1:677,:),[0:0.01:1])
            hold on
            histogram(augmented_weights_31001(i,1:677,:),[0:0.01:1],FaceColor='r')
        end
        set(gca, fontsize=20)
        sgtitle('Scans 11001 vs 31001 Elements 1:677')
        
        legend('11001','31001')
        figure(76)
        clf
        
        for i=1:3
            subplot(3,1,i)
            histogram(augmented_weights_11001(i,678:end,:),[0:0.01:1])
            hold on
            histogram(augmented_weights_31001(i,678:end,:),[0:0.01:1],FaceColor='r')
        end
        set(gca, fontsize=20)
        sgtitle('Scans 11001 vs 31001 Elements 678:end')
        legend('11001','31001')
        
        % Compare locations of weighted pixels
    case 8
        jfig = 80;
        
        for sl=[31001 19001 19501 20001 20501 21001 21501 25001]
            sls = num2str(sl);
            
            jfig = jfig + 1;
            
            figure(jfig)
            clf
            
            aa = load(['/Volumes/Aqua-1/Fronts/MODIS_Aqua_L2/SupportingFiles/Weights/weights_' sls '.mat']);
            
            [Nloc, Iloc, Jloc] = ind2sub(size(aa.locations), aa.locations);
            for i=1:3
                subplot(3,3,(i-1)*3+1)
                imagesc(squeeze(aa.weights(i,:,:))')
                caxis([0 1])
                colorbar
                set(gca, fontsize=20)
                
                subplot(3,3,(i-1)*3+2)
                imagesc(squeeze(Iloc(i,:,:))')
                colorbar
                set(gca, fontsize=20)
                
                
                subplot(3,3,(i-1)*3+3)
                imagesc(squeeze(Jloc(i,:,:))')
                colorbar
                set(gca, fontsize=20)
            end
            sgtitle(['Scans Weights - Element - Scan line ' sls])
        end
        
        % Can't recall what the rest of these do; they were in generate_weights...
    case 9
        for i=1:4
            for j=1:4
                k = 10*(i-1) + j;
                figure(k)
                xlim([0 300])
            end
        end
        
    case 10
        jfig = 101;
        figure(jfig)
        clf
        imagesc(x_coor')
        set(gca, fontsize=24)
        title(['x_coor starting at ' jlowers])
        
        jfig = jfig + 1;
        figure(jfig)
        clf
        imagesc(y_coor')
        set(gca, fontsize=24)
        title(['y_coor starting at ' jlowers])
        
        jfig = jfig + 1;
        figure(jfig)
        clf
        imagesc(new_x_coor')
        set(gca, fontsize=24)
        title(['new_x_coor starting at ' jlowers])
        
        jfig = jfig + 1;
        figure(jfig)
        clf
        imagesc(new_y_coor')
        set(gca, fontsize=24)
        title(['new_y_coor starting at ' jlowers])
        
        jfig = jfig + 1;
        figure(jfig)
        ddy_coor = new_y_coor - y_coor;
        imagesc(ddy_coor')
        colorbar
        set(gca, fontsize=24)
        title(['new_y_coor-y_coor starting at ' jlowers])
        
    case 11
        is = '11191'; js = '12191';
        eval(['w' is ' = load(''~/Dropbox/Data/Fronts_test/MODIS_Aqua_L2/Original/2010/weights_' is '.mat'');'])
        eval(['w' js ' = load(''~/Dropbox/Data/Fronts_test/MODIS_Aqua_L2/Original/2010/weights_' js '.mat'');'])
        
        for k=1:3
            ks = num2str(k);
            eval(['w' is '_' js ' = w' is '.locations' ks ' - w' js '.locations' ks ';']);
            eval(['minmax(w' is '_' js '(:)'')'])
        end
        
end