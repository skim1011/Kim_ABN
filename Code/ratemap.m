% generate ratemap
% Original code from Douglas GoodSmith
binsize = 10;
rate_of_speed = 2;
num_of_mazes = 8;
mazenum = 8 % Number of mazes
cellnum = 6 % Number of cells
nrand = 100; %number of the random sampling
randinfo = zeros(nrand,1);
yres=round(480/binsize);%matlab indices are rows(y) by columns(x)
xres=round(640/binsize);
mask = zeros(yres,xres); % size of the mask for occupancy/rate map
occupancyV2up = mask;
Pixel_ratio = 0.1458;
gx = -7:1:7; %smooth over 33ms(1frame) * 15 = 495ms,
sigma = 3; %wider sigma
gaussfilt = 1/sqrt(2*pi*(sigma^2)) * exp(-gx.^2/(2*sigma^2));

for current_cell = 1:cellnum
    for current_maze = 1:mazenum

        if ~isempty(mazelist{current_cell, current_maze})
        pos = strfind(mazelist{current_cell, current_maze}, '\');
        cd(mazelist{current_cell, current_maze}(1:pos(end-1)));
        filename2 = sprintf('%s\\Pos.p.ascii', mazelist{current_cell, current_maze}(1:pos(end-1)));
        fid  = fopen(filename2,'r');
        frames = cell2mat(textscan(fid,'%f%f%f%f','Delimiter',',','HeaderLines',24));
        frames(:,2) = frames(:, 2) .*64/72;
        fid = fclose(fid);
        fr = frames; 
        fid1 = fopen('events.txt', 'r');
        event_file = textscan(fid1, ...
        '%f64 %f64 %f64 %f64 %f64 %f64 %f64 %f64 %f64 %f64 %f64 %f64 %f64 %f64 %f64 %f64 %f64 %s', ...
        'delimiter', ',', 'headerlines', 1);
        fclose(fid1);
        clear fid1
        %removes unwanted columns of cell
        event_file(:,1:3) = [];
        event_file(:,2:14) = [];
        timestamps = event_file{:,1};
        events = event_file{:,2};

        label_start = sprintf('start b%d', current_maze); 
        label_end = sprintf('stop b%d', current_maze);
    
    for index2 = 1:size(events,1)
        tmp_event_label = events{index2,1};
        if(strncmpi(tmp_event_label,label_start, 8)==1)
            starttime(current_maze) = timestamps(index2,1);
            
        end
        if(strncmpi(tmp_event_label,label_end, 7)==1)
            stoptime(current_maze) = timestamps(index2, 1);
        end
    end

randmin = 33000000; %microseconds 
randscalefactor = stoptime(current_maze) - starttime(current_maze) - 2*randmin; 
   
cell_temp = [];
 filename = mazelist{current_cell, current_maze};
           try
 unit = importdata(filename, ',', 13);
           catch
               pos2 = strfind(filename, '-b');
               filename2 = sprintf('%s%s%s', filename(1:pos2), 'b',  filename(pos2+2:end)) 
               unit = importdata(filename2, ',', 13);
           end
            
            try
            unitdata = unit.data;
            unitposX = unitdata(:, 16); 
            unitposY = unitdata(:, 17);
            allspikes = unitdata(:,18);
            catch
            vel_filt_rmap{current_cell, current_maze} = 'no spikes';
                meanrate(current_cell, current_maze) = 0;
                continue
            end
            if size(allspikes, 1)./((stoptime(current_maze) - starttime(current_maze))/1000000) > 10
                %disp('IN')
                vel_filt_rmap{current_cell, current_maze} = 'IN';
                meanrate(current_cell, current_maze) = size(allspikes, 1)./((stoptime(current_maze) - starttime(current_maze))/1000000);
                continue
            else
               
            meanrate(current_cell, current_maze) = size(allspikes, 1)./((stoptime(current_maze) - starttime(current_maze))/1000000);     
             
            sftimes = find((frames(:,1)>=starttime(current_maze)-33333)&(frames(:,1)<=stoptime(current_maze)));
            peri_sessionframes = frames((sftimes(1)) : (sftimes(end)),:);
            
            sessionframes = peri_sessionframes(8:end-7,:);
            sessionframes(:,2:4) = floor(sessionframes(:,2:4)/binsize)+1;%resampling x and y positions in (480/binsize)*(640/binsize) grid & starting at 1 instead of 0
            disp(:,1) = peri_sessionframes(2:end,2)- peri_sessionframes(1:end-1,2); %x_displacement
            disp(:,2) = peri_sessionframes(2:end,3)- peri_sessionframes(1:end-1,3); %y_displacement
            disp = [[0 0];disp]; %align displacement frames to video frames
            disp(:,3) = sqrt(disp(:,1).^2 + disp(:,2).^2); %total displacement
            smoothdisp(:,1) = conv(disp(:,1),gaussfilt);%remember this convolution adds length(gx)-1 extra points
            smoothdisp(:,2) = conv(disp(:,2),gaussfilt);
            smoothdisp(:,3) = sqrt(smoothdisp(:,1).^2 + smoothdisp(:,2).^2); %speed calculation.
            Tdisp = (peri_sessionframes(2:end,1)-peri_sessionframes(1:end-1,1)); %get actual frame duration, rather than assuming it to be 30ms. (also takes care of missing frames.
            Tdisp = [0;Tdisp];
            Tds = [Tdisp Tdisp Tdisp]; %this is just to simplify dividing xdisp, ydisp and disp by the duration of the frame in next line
            vel = disp*(Pixel_ratio*10/binsize).*(1000000./Tds); %estimated 0.34cm per pixel in m1 to m6, ~0.352cm per pixel in m7(using binsize of 9.65) 30Hz frame rate (exact duration of each frame = 1000000./Tdisp): 1frame*pixels*(cm/pixels)*(frames/sec) gives the units of cm/sec
            sTdisp = [zeros(gx(end),1);Tdisp;zeros(gx(end),1)]; %padding to compensate for length of smoothing covolution
            sTds = [sTdisp sTdisp sTdisp];
            smoothvel = smoothdisp*(Pixel_ratio*10/binsize).*(1000000./sTds); %estimated 0.34cm per pixel in m1 to m6, ~0.352cm per pixel in m7(using binsize of 9.65) 30Hz frame rate (exact duration of each frame = 1000000./Tdisp): 1frame*pixels*(cm/pixels)*(frames/sec) gives the units of cm/sec
            smoothvel = smoothvel(gx(end)+1+7:length(smoothvel)-gx(end)-7,:);%get rid of extra frames added for smoothing
            vel = vel(8:end-7,:);
            count_removed_spikes = 1;
            count_unremoved_spikes = 1;
            allspkmapsV0to2 = zeros(yres,xres);
            allspkmapsV2up = allspkmapsV0to2;
            occupancyV2up = allspkmapsV2up;
            for j = 2:size(sessionframes,1)
                infrspks = find(allspikes(:,1)>=sessionframes((j-1),1)& allspikes(:,1)<sessionframes(j,1));
                ypos = floor(sessionframes(j,3)); %matlab indices are rows(y) by columns(x)
                xpos = floor(sessionframes(j,2));
                xpos2 = peri_sessionframes(j,2);
                ypos2 = peri_sessionframes(j,3);
               
                if (xpos>1) && (xpos<=xres) && (ypos>1) && (ypos<=yres)
                    
                    %ratemaps filtered by speed
                    speed  = smoothvel(j,3); %speed - third colum of disp/smoothdisp/vel etc is speed.
                    if speed <= rate_of_speed
                        
                        if infrspks
                            for ins = 1 : length(infrspks)
                                count_removed_spikes = count_removed_spikes + 1;

                            end
                        end
                    else
                        occupancyV2up(ypos,xpos) = occupancyV2up(ypos,xpos) + 1;
                        if infrspks
                            for ins = 1 : length(infrspks)
                                count_unremoved_spikes = count_unremoved_spikes + 1;

                                allspkmapsV2up(ypos, xpos) = allspkmapsV2up(ypos, xpos)+1;
                                
                            end
                        end
                    end
                    
                end
            end
            
            occupancyV2up(1,1) = 0;
            occV2up = occupancyV2up; %need occupancy without -ve numbers for adaptive binning.
            A = calcadaptivesac(allspkmapsV2up, occV2up);
            A1 = A;
            A2 = A1==-99;
            A1(A2) = NaN;
            vel_filt_rmap{current_cell, current_maze} = A1;
            spinfo(current_cell, current_maze) = computeInfo(A);
            info = computeInfo(A);
            peakrates(current_cell, current_maze) = max(max(A1));
            session_time = stoptime(current_maze) - starttime(current_maze);
            session_time_sec = session_time /1000000;
           meanrate(current_cell, current_maze) = count_unremoved_spikes/session_time_sec;
           spkt = allspikes;
      
            randspkt = repmat(spkt,1,nrand);
                                    randoffset = randmin+(randscalefactor*rand(1,nrand));
                                    randrep = repmat(randoffset,length(spkt),1);
                                    randspkt = randspkt+randrep; %add same random offset to each spike in a column
                                    clear randrep spkt; %sac 2/22/10 space issues for interneurons with > 39000 spikes/session.
                                    randspkt(randspkt>stoptime(current_maze)) = randspkt(randspkt>stoptime(current_maze))+starttime(current_maze)-stoptime(current_maze);%loop back spikes with spike times > stoptime to start at starttime
                                   
                                    
                                    try
                                    parfor pari = 1:nrand
                                    [randinfo(pari)] = parrandinf(yres,xres,sessionframes,occV2up,randspkt(:,pari));
                                     end 
           
            infop(current_cell, current_maze) = sum(randinfo>info)/nrand;
                                    catch
                                        infop(current_cell, current_maze) = NaN;
                                        continue
                                    end
            clear peri_sessionframes sessionframes smoothdisp smoothvel disp vel Tds Tdisp sTdisp sTds A A1 A2 allspkmapsV2up occV2up occupancyV2up randscaelfactor
            end
        end
        close all
    end
end
