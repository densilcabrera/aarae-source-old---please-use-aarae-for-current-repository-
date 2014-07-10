function out = LevelStats(inputwave,tau,cal,weight)
% This function calculates sound level values from the input audio, taking
% calibration offset into account.
%
% code by Densil Cabrera
% version 1.01 (21 March 2014)

if isstruct(inputwave)
    audio = inputwave.audio;
    fs = inputwave.fs;
    if isfield(inputwave,'bandID')
        bandID = inputwave.bandID;
    end
    if isfield(inputwave,'chanID')
        chanID = inputwave.chanID;
    else
        chanID = cellstr([repmat('Chan',size(audio,2),1) num2str((1:size(audio,2))')]);
    end
    if isfield(inputwave,'cal')
        cal = inputwave.cal;
    else
        cal = zeros(1,size(audio,2));
        disp('This audio signal has not been calibrated.')
    end
    
end

[len,chans,bands] = size(audio);

if ~isreal(audio)
    % inverse Hilbert transform for complex data
    audio = abs(audio).* cos(angle(audio));
end

if nargin < 4, weight = 'z'; end
if nargin < 3, tau = 0.125; end % default temporal integration constant in seconds
if nargin < 2
    param = inputdlg({...
        'Integration time constant (s)'; ...
        'Calibration offset (dB)'; ...
        'Weighting (a,b,c,d,z)'}, ...
        'Analysis parameters',1, ...
        {num2str(tau); num2str(cal); weight});
    if length(param) < 3, param = []; end
    if ~isempty(param) 
        tau = str2num(char(param(1)));
        cal = str2num(char(param(2)));
        weight = char(param(3));
    else
        out = [];
        return
    end
end

% apply calibration
[audio, audio_original]= deal(audio .* repmat(10.^(cal./20),[len,1,bands]));

% apply weighting
audio = weighting(audio,fs,weight);

% square and apply temporal integration
if tau > 0
    % apply temporal integration so that percentiles can be derived
    % FILTER DESIGN
    E = exp(-1/(tau*fs)); % exponential term
    b = 1 - E; % filter numerator (adjusts gain to compensate for denominator)
    a = [1, -E];% filter denominator
    
    % rectify, integrate and square    
    audio=filter(b,a,abs(audio)).^2;
    
else
    % no temporal integration
    audio = audio.^2;
end

out.Lenergy = 10*log10(sum(audio)./fs);
out.Lenergy = permute(out.Lenergy,[3,2,1]);

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

ymax = 10*ceil(max(max(max(10*log10(audio_original.^2))))/10);
ymin = 10*floor(min(min(min(out.L90)))/10)-20;
if isnan(ymin)
    ymin = ymax-100;
end

out.funcallback.name = 'LevelStats.m';
out.funcallback.inarg = {tau,cal,weight};

t = ((1:len)'-1)./fs; % time vector

if isstruct(inputwave)
    if ~ismatrix(10*log10(sort(audio)))
        doresultleaf(10*log10(sort(audio)),'Level [dB]',{'Duration'},...
                     'Duration', t,                's',           true,...
                     'channels', chanID,           'categorical', [],...
                     'bands',    num2cell(bandID), 'Hz',          false,...
                     'name','cumulative_distrib_level');
    else
        doresultleaf(10*log10(sort(audio)),'Level [dB]',{'Duration'},...
                     'Duartion', t,      's',           true,...
                     'channels', chanID, 'categorical', [],...
                     'name','cumulative_distrib_level');
    end
end

for ch = 1:chans
    if exist('chanID','var')
        chanstring = char(chanID(ch));
    else
        chanstring = ['ch ',num2str(ch)];
    end
    for b = 1:bands
        if bands > 1
            if exist('bandID','var')
                figure('Name',...
                    ['Level Statistics, ',chanstring,', ',...
                    num2str(bandID(b))])
            else
                figure('Name',...
                    ['Level Statistics, ',chanstring,', ',num2str(b)])
                
            end
        else
            figure('Name',['Level Statistics, ',chanstring])
        end
        y = sort(audio(:,ch,b));
        plot(t,10*log10(audio_original(:,ch,b).^2),'Color',[0.7 0.9 0.9],...
            'DisplayName','Raw audio')       
        hold on
        plot(t,10*log10(audio(:,ch,b)),'Color',[0 0.5 0],...
            'DisplayName','Processed audio')   
        plot(t,10*log10(y),'r','DisplayName','Cumulative Distribution')
        plot(t(round(length(t)*0.95)),10*log10(y(round(length(t)*0.95))),...
            'r*','DisplayName',['L5: ',num2str(out.L5(b,ch)),' dB'])
        plot(t(round(length(t)*0.9)),10*log10(y(round(length(t)*0.9))),...
            'ro','DisplayName',['L10: ',num2str(out.L10(b,ch)),' dB'])
        plot(t(round(length(t)*0.5)),10*log10(y(round(length(t)*0.5))),...
            'r+','DisplayName',['L50: ',num2str(out.L50(b,ch)),' dB'])
        plot(t(round(length(t)*0.1)),10*log10(y(round(length(t)*0.1))),...
            'rx','DisplayName',['L90: ',num2str(out.L90(b,ch)),' dB'])
        ylabel('Level (dB)')
        xlabel('Duration (s)')
        ylim([ymin ymax])
        text(0.05*(len-1)/fs,ymin+0.9*(ymax-ymin),...
            ['Leq = ',num2str(out.Leq(b,ch)),' dB'])
        text(0.05*(len-1)/fs,ymin+0.8*(ymax-ymin),...
            ['Lenergy = ',num2str(out.Lenergy(b,ch)),' dB'])
        legend('show','Location','EastOutside');
        title(['Integration time constant = ', num2str(tau),' s'])
    end
end
