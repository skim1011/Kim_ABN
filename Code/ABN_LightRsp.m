% Import event file from user-defined folder and transform into matlab
% matrix, further transform the timestamps into time values.
% NOTE: This program cites Neurolynx utility Nlx2MatEv.
% original code from Wei Huang

% User select Event file
[Event, EventPath, filterindex] = uigetfile('*.nev', 'Select Event File');
EventFile = strcat(EventPath,Event);
[Event_TimeStamps,  TTLs, EventStrings, Header] = Nlx2MatEV(EventFile,[1 0 1 0 1], 1,1,[] );

% Define the first timestamp
FirstTimestamp = Event_TimeStamps(1);

% User define the episode to analyze
light_on = input('What is your light-on timestamp?\n');
light_off = input('What is your light-off timestamp?\n');
duration = (light_off-light_on)/1000000;

% Extract the event timestamps for the episode defined by the user
lighton = find (Event_TimeStamps-light_on == 0);
lightoff = find (Event_TimeStamps-light_off == 0);
[SelectTimeStamps, SelectTTLs, SelectStrings, Header] = Nlx2MatEV(EventFile,[1 0 1 0 1], 1,2,[lighton, lightoff]);

% Extract the timestamps for light onset.
light_onset = find(SelectTTLs);
light_timestamps = SelectTimeStamps(light_onset)';

% Timestamp conversion
EventTimestampSubtract = ((SelectTimeStamps - FirstTimestamp))/1000000';
LightTimestampSubtract = ((light_timestamps - FirstTimestamp))/1000000;


%Select sorted unit files from user-defined folder and assemble all the
%spike timestamps into a struct named AllUnits;
%NOTE: this program can only work with mulitple units, not with single
%unit. This is due to the parameter setting ('MultiSelect') in unigetfile function.

[UnitName, DataPath, filterindex] = uigetfile('*.*', 'Select Sorted Units', 'MultiSelect', 'on');
s = size(UnitName);
UnitNumber = s(2);
AllUnits = struct([]);
for i = 1: UnitNumber
    unittimestamps = zeros(1);    
    unit = struct([]);
    unitdata = zeros(1, 1);
    
    unitpath = strcat(DataPath,UnitName(i));
    unitfile = char(unitpath);
    unit = importdata(unitfile,',',13);
    unitdata = unit.data;
    unittimestamps = unitdata(:, 18);
    %Timestamp conversion
    UnitTimestampSubtract = (unittimestamps - FirstTimestamp)/1000000;
    %Assign to structure
    AllUnits(i).index = i;
    AllUnits(i).timestamps = unittimestamps;
    AllUnits(i).time = UnitTimestampSubtract;
end


[Spike, SpikePath, filterindex] = uigetfile('*.ntt', 'Select Spike File');
SpikeFile = strcat(SpikePath, Spike);

[Spike_Timestamps, Features, Spike_Samples] = Nlx2MatSpike( SpikeFile, [1 0 0 1 1 0], 0, 1);

for ii = 1: UnitNumber
    spikes = zeros(32, 4, 1);
    timestamps = zeros(1);
    spikeindex = zeros(1);
    
    timestamps = AllUnits(ii).timestamps;
    for j = 1: length(timestamps)
        spikeindex(j) = find(Spike_Timestamps == timestamps(j));
    end
    
    spikes = Spike_Samples(:, :, spikeindex);
    AllUnits(ii).spikes = spikes;
end

Xmax = input('Specify Xmax (ms):\n');
Xmin = 15-Xmax;
NumberTrials = length(LightTimestampSubtract);
LightTime = LightTimestampSubtract;

bin_size = input('Specify bin size (ms):\n');
Number_bins = (Xmax-Xmin)/bin_size;
psthSize = Number_bins+1;
graph_edges = [Xmin:bin_size:Xmax]';

UName = cell(1);
data = zeros(UnitNumber, 5);

for ii = 1: UnitNumber
    t = zeros(1);
    t = AllUnits(ii).time; % Spike timings in iith unit
    name = char(UnitName(ii));
    
    ax = figure;
    
    rst = subplot(6, 7, [5, 6, 7, 12, 13, 14, 19, 20, 21]);  % post-light raster plot
    hist = subplot(6, 7, [26, 27, 28, 33, 34, 35, 40, 41, 42]); % post-light histogram
    
    timestamps = zeros(1);
    timestamps = AllUnits(ii).timestamps;
    
    spikes = zeros(32, 4, 1);
    spikes = AllUnits(ii).spikes;
       
    
    %% Plot raster plot
    subplot(rst);
    line([0 0],[0 NumberTrials],'Color','c');
    axis ([Xmin, Xmax, 0, NumberTrials+0.5]);
    nspikes = numel(t); % number of spikes
    
    lightcount = 0;
    latency = zeros(1);
    uni = 1;
    multi = 0;
    
    all_spike = NaN(NumberTrials, nspikes); 
    
    for jj = 1:NumberTrials
        light = LightTime(jj);
        sensmulti = 0;
        for kk = 1:nspikes % for every spike
            tick = (t(kk)-light)*1000;
            if tick <= Xmax 
                if tick >= Xmin
                    line([tick tick],[jj-0.5 jj+0.5],'Color','k');
                    all_spike(jj,kk) = tick; 
                end
                if tick > 0
                                       
                    if sensmulti == 1    % check whether there are multiple l-r spike events in given light stimuli
                        multi = multi + 1
                    end
                    
                    if sensmulti > 0
                        sensmulti = sensmulti + 1;
                        break;
                    end
                    
                    latency(uni) = tick;
                    lightcount = lightcount + 1;
                    sensmulti = sensmulti + 1;
                    uni = uni + 1;
                    
                end
            end
        end
    end
    ylabel('Trial number');
    title (['Unit:', UnitName(ii)], 'FontSize',9);

    %% Plot histogram
    
    [no_row no_col] = size(all_spike);
    no_whole = no_row*no_col
    all_spike_sk = reshape(all_spike,[no_whole,1]);

    A = all_spike_sk;
    A(~any(~isnan(A), 2),:)=[]; 
    psth_sk = zeros(psthSize,1);
    
    for mm = 1:25
        
    f_boundary = mm-6;
    r_boundary = mm-5;
    number_l = size(find(A> f_boundary & A< r_boundary),1);
    
    psth_sk(mm,1) = number_l;
    clear number_l;
    
    end
    
    subplot(hist);
    bar(graph_edges,psth_sk,'histc');
    set(hist,'YLim');
    xlim([Xmin, Xmax]);
    %legend(['Bin: ',num2str(bin_size),' ms']);
    xlabel('Time (ms)'); % Time is in millisecond
    clear psth_sk;
    
    %% Save figure
    namea = strrep(name, '.', '0');
    savefig([namea,'.fig']);
    saveas(ax, [namea,'.tif']);
    %% Calculate parameters
    
    frequency = length(t)/duration;
    latencyavg = mean(latency);
    latencystd = std(latency);
    fidelity = lightcount/NumberTrials*100;
    AllUnits(ii).frequency = frequency;
    AllUnits(ii).latencyavg = latencyavg;
    AllUnits(ii).latency = latency;
    AllUnits(ii).fidelity = fidelity;
    AllUnits(ii).multi = multi;
    data(ii, :) = [frequency, latencyavg, latencystd, fidelity, multi];
    nameb = strrep(name, 'cl-', '');
    UName(ii) = cellstr(nameb);

end

%% Create a table of parameters
bx = figure;
annotation('textbox', [0.2, 0.9, 0.1, 0.1], 'String', ['Unit: ', name], 'FontSize', 10);
para = {'Firing frequency (Hz)', 'Mean light response latency (ms)', 'Variation (ms)', 'Light response fidelity (%)', 'Multievents with one stimulus'};
tab = uitable('Data', data, 'RowName', UName, 'ColumnName', para);
tab.Position(3) = tab.Extent(3);
tab.Position(4) = tab.Extent(4);
savefig(['parameter.fig']); % Save table figure
saveas(bx, ['parameter.tif']);
