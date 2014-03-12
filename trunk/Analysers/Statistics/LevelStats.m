function out = LevelStats(inputwave)
% This function calculates sound level values from the input audio, taking
% calibration offset into account.
%
% code by Densil Cabrera
% version 0 (12 March 2014)
% plots and tables need more work!
if isstruct(inputwave)
    audio = inputwave.audio;
    fs = inputwave.fs;
    if isfield(inputwave,'bandID')
        bandID = inputwave.bandID;
    end
    if isfield(inputwave,'chanID')
        chanID = inputwave.chanID;
    end
    if isfield(inputwave,'cal')
        cal = inputwave.cal;
    else
        cal = 0;
        disp('This audio signal has not been calibrated.')
    end
    
end

[len,chans,bands,dim4,dim5,dim6] = size(audio);


%dosubplots = 0; % default setting for multichannel plotting
tau = 0.125; % default temporal integration constant in seconds
showpercentiles = 1;
weight = 'z';

param = inputdlg({...
    'Integration time constant (s)'; ...
    'Calibration offset (dB)'; ...
    'Weighting (a,b,c,d,z)'}, ...
    'Analysis parameters',1, ...
    {num2str(tau); num2str(cal);weight});
%param = str2num(char(param));
if length(param) < 3, param = []; end
if ~isempty(param) 
    tau = str2num(char(param(1)));
    cal = str2num(char(param(2)));
    weight = char(param(3));
end

% apply weighting
audio = weighting(audio,fs,weight);

% square and apply temporal integration
if tau > 0
    % apply temporal integration so that percentiles can be derived
    % FILTER DESIGN
    E = exp(-1/(tau*fs)); % exponential term
    b = 1 - E; % filter numerator (adjusts gain to compensate for denominator)
    a = [1 -E];% filter denominator
    % rectify, integrate and convert to decibels
    
    audio=filter(b,a,abs(audio)).^2;
    
else
    % no temporal integration
    audio = audio.^2;
end

% apply calibration
if length(cal) > 1
    for k = 1:chans
        audio(:,k,:,:,:,:) = 10.^((10*log10(audio(:,k,:,:,:,:)) + cal(k))./10);
    end
else
    audio = 10.^((10*log10(audio) + cal)./10);
end

out.Leq = 10*log10(mean(audio));
out.Leq = permute(out.Leq,[3,2,1]);

out.Lmax = 10*log10(max(audio));
out.Lmax = permute(out.Lmax,[3,2,1]);

out.L5 = 10*log10(prctile(audio,95));
out.L5 = permute(out.L5,[3,2,1]);

out.L10 = 10*log10(prctile(audio,90));
out.L10 = permute(out.L10,[3,2,1]);

out.L50 = 10*log10(median(audio));
out.L50 = permute(out.L50,[3,2,1]);

out.L90 = 10*log10(prctile(audio,10));
out.L90 = permute(out.L90,[3,2,1]);

ymax = 10*ceil(max(max(out.Lmax+5))/10);
ymin = 10*floor(min(min(out.L90))/10)-20;


% Still need to write output tables and good figures

for ch = 1:chans
    for b = 1:bands
        figure('Name','Cumulative Distribution')
        plot(((1:len)'-1)./fs,10*log10(sort(audio(:,ch,b))))
        hold on
        ylabel('Level (dB)')
        xlabel('Duration (s)')
        ylim([ymin ymax])
        text(0.7*(len-1)/fs,ymin+0.5*(ymax-ymin),...
            ['Leq = ',num2str(out.Leq(ch,b)),' dB'])
    end
end
