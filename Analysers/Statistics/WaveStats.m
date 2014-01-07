function WS = WaveStats(inputwave)
% returns simple overall statistics of the input wave(s)
if isstruct(inputwave)
    inputwave = inputwave.audio;
    if isfield(inputwave,'bandID')
        bandID = inputwave.bandID;
    end
        if isfield(inputwave,'chanID')
        chanID = inputwave.chanID;
    end
end
% maximum value
WS.max = max(inputwave);

% minimum value
WS.min = min(inputwave);

% range
WS.range = WS.max - WS.min;

% maximum absolute value
WS.maxabs = max(abs(inputwave));

% median value
WS.median = median(inputwave);

% median absolute value
WS.medianabs = median(abs(inputwave));

% mean
WS.mean =  mean(inputwave);

% standard deviation
WS.std = std(inputwave);

% kurtosis (need statistics toolbox for this)
WS.kurt = kurtosis(inputwave);

% root mean square
WS.rms = mean(inputwave.^2).^0.5;

% crest factor
WS.crestfactor = max(abs(inputwave)) ./ WS.rms;

% peak to average power ratio
WS.papr = max(abs(inputwave)).^2 ./ WS.rms.^2;

% output
[~,chans,bands] = size(inputwave);
if bands > 1 && ~exist('bandID','var')
        bandID = 1:bands;
end
if  ~exist('chanID','var')
        chanID = 1:chans;
end



if bands > 1
    for ch = 1:chans
        f = figure('Name',['Wave statistics, channel: ', num2str(chanID(ch))], ...
            'Position',[200 200 620 360]);
        %[left bottom width height]
        dat1 = [permute(WS.max(1,ch,:),[1,3,2]); ...
            permute(WS.min(1,ch,:),[1,3,2]); ...
            permute(WS.range(1,ch,:),[1,3,2]); ...
            permute(WS.maxabs(1,ch,:),[1,3,2]); ...
            permute(WS.median(1,ch,:),[1,3,2]); ...
            permute(WS.medianabs(1,ch,:),[1,3,2]); ...
            permute(WS.mean(1,ch,:),[1,3,2]); ...
            permute(WS.std(1,ch,:),[1,3,2]); ...
            permute(WS.kurt(1,ch,:),[1,3,2]); ...
            permute(WS.rms(1,ch,:),[1,3,2]); ...
            permute(WS.crestfactor(1,ch,:),[1,3,2]); ...
            permute(WS.papr(1,ch,:),[1,3,2])];
        cnames1 = num2cell(bandID);
        rnames1 = {'Maximum', 'Minimum', 'Range', 'Maximum absolute value', ...
            'Median', 'Median absolute value', 'Mean', 'Standard deviation', ...
            'Kurtosis', 'Root mean square', 'Crest factor', ...
            'Peak to average power ratio'};
        t1 =uitable('Data',dat1,'ColumnName',cnames1,'RowName',rnames1);
        set(t1,'ColumnWidth',{60});
        disptables(f,t1);
    end
    

else
    f = figure('Name','Wave statistics', ...
            'Position',[200 200 620 360]);
        %[left bottom width height]
        dat1 = [WS.max; ...
            WS.min; ...
            WS.range; ...
            WS.maxabs; ...
            WS.median; ...
            WS.medianabs; ...
            WS.mean; ...
            WS.std; ...
            WS.kurt; ...
            WS.rms; ...
            WS.crestfactor; ...
            WS.papr];
        cnames1 = num2cell(1:chans);
        rnames1 = {'Maximum', 'Minimum', 'Range', 'Maximum absolute value', ...
            'Median', 'Median absolute value', 'Mean', 'Standard deviation', ...
            'Kurtosis', 'Root mean square', 'Crest factor', ...
            'Peak to average power ratio'};
        t1 =uitable('Data',dat1,'ColumnName',cnames1,'RowName',rnames1);
        set(t1,'ColumnWidth',{60});
        disptables(f,t1);
    
end