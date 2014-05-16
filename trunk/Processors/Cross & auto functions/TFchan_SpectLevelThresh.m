function OUT = TFchan_SpectLevelThresh(in,fs,RefChan,Threshold,Duration,doplot)
% Calculates the transfer function between pairs of audio channels, by
% frequency domain division of cross spectrum by the reference autospectrum,
% but removing spectral components for which the
% reference (or input) channel falls below threshold (magnitude relative to
% maximum component magnitude). The output is a time response (derived via
% inverse Fourier transform).
%
% Code by Densil Cabrera
% version 1.01 (16 May 2014)

if nargin < 6, doplot = 0; end
if nargin < 5, Duration = 2; end
if nargin < 4, Threshold = -60; end
if nargin < 3
    RefChan = 1;
    if isstruct(in)
        S = in.audio;
        fs = in.fs;
        if size(S,3)>1
            if isfield(in,'bandID')
                bandID = in.bandID;
            else
                bandID = [];
            end
        end
    else
        S = in;
        if nargin < 2
            fs = inputdlg({'Sampling frequency [samples/s]'},...
                'Fs',1,{'48000'});
            fs = str2num(char(fs));
        end
        bandID = [];
    end
    [len,chans,bands] = size(S);
    
    
    maxDuration = floor((len) / in.fs);
    defaultDuration = 2;
    if defaultDuration > maxDuration, defaultDuration = maxDuration; end
    
    %dialog box for settings
    prompt = {'Reference channel, OR 0 for additional audio input', 'Level threshold (dB)', 'Output duration (s) OR 0 for full duration', 'Plot (0 | 1)'};
    dlg_title = 'Settings';
    num_lines = 1;
    def = {'1','-60', num2str(defaultDuration),'0'};
    answer = inputdlg(prompt,dlg_title,num_lines,def);
    
    if ~isempty(answer)
        RefChan = str2num(answer{1,1});
        Threshold = str2num(answer{2,1});
        Duration = str2num(answer{3,1});
        doplot = str2num(answer{4,1});
    else
        OUT = [];
        return
    end
end

if RefChan == 0
    selection = choose_audio; % call AARAE's choose_audio function
    if ~isempty(selection)
        refaudio = selection.audio; % additional audio data
        fs2 = selection.fs; % sampling rate
        
        if ~(fs2 == fs)
            % match sampling rates
            refaudio = resample(refaudio,fs,fs2);
            disp('Sampling rate mis-match - reference audio has been re-sampled.')
        end
        [len2, chans2, bands2] = size(refaudio); % new wave dimensions
        fftlen = max([len len2]);
    end
    if bands2 > 1
        if bands2 ~= bands
            refaudio = sum(refaudio,3);
            disp('multiband reference audio has been mixed down')
        else
            if isfield(selection,'bandID') && ~isempty(bandID)
                bandID2 = selection.bandID;
                if bandID2 ~= bandID
                    refaudio = sum(refaudio,3);
                    disp('multiband reference audio has been mixed down')
                end
            end
        end
    end
    if (chans2 > 1) %&& chans2 ~= chans
        prompt = {'Reference channel'};
        dlg_title = 'Reference audio settings';
        num_lines = 1;
        def = {'1'};
        answer = inputdlg(prompt,dlg_title,num_lines,def);
        
        if ~isempty(answer)
            RefChan2 = str2num(answer{1,1});
            if RefChan2 > chans2
                disp('Invalid reference channel entered - Channel 1 will be used instead')
                RefChan2 = 1;
            end
            refaudio = refaudio(:,RefChan2,:);
        else
            OUT = [];
            return
        end
    end
else
    if RefChan > chans
        disp('Invalid reference channel entered - Channel 1 will be used instead')
        RefChan = 1;
    end
    refaudio = S(:,RefChan,:);
    fftlen = len;
end


if Duration == 0
    outlen = fftlen;
else
    outlen = floor(Duration * fs)+1;
    if outlen > fftlen, outlen = fftlen; end
end

% if size(refaudio,3)>1
%     disp('reference audio is multiband, so bands have been summed')
%     refaudio = sum(refaudio,3);
%     %bands2 = 1;
% end

spectrum = fft(S,fftlen);
refspectrum = fft(refaudio,fftlen);

magThreshold = 10.^(Threshold / 20);

TF = zeros(len,chans,bands);
if size(refspectrum,3) ==1
    magnitude_ref = abs(refspectrum);
    maxmagnitude_ref = max(magnitude_ref);
    below_threshold = magnitude_ref < maxmagnitude_ref * magThreshold;
    refspectrumk = repmat(refspectrum, [1,chans,bands]);
    TF = conj(refspectrumk) .* spectrum ./ (conj(refspectrumk) .* refspectrumk);
    TF(below_threshold,:,:) = 0; % zero all values below input wave threshold
else
    for k = 1:bands
        magnitude_ref = abs(refspectrum(:,1,k));
        maxmagnitude_ref = max(magnitude_ref);
        below_threshold = magnitude_ref < maxmagnitude_ref * magThreshold;
        
        refspectrumk = repmat(refspectrum(:,1,k), [1,chans,1]);
        
        TF(:,:,k) = conj(refspectrumk) .* spectrum(:,:,k) ./ (conj(refspectrumk) .* refspectrumk);
        
        TF(below_threshold,:,k) = 0; % zero all values below input wave threshold
    end
end

% Return to time domain
out = ifft(TF);

% Truncate to the desired length
out = out(1:outlen,:,:);

if isstruct(in)
    OUT = in; % replicate input structure
    OUT.audio = out;
    OUT.funcallback.name = 'TFchan_SpectLevelThresh.m';
    OUT.funcallback.inarg = {fs,RefChan,Threshold,Duration,doplot};
else
    OUT = out;
end

% these plots are unnecessary within AARAE
if doplot
    figure('Name', 'Transfer Function')
    
    subplot(3,1,1)
    t = ((1:outlen)'-1)/in.fs;
    plot(repmat(t, [1,chans,bands]),out)
    xlabel('Time (s)')
    xlim([0 t(end)])
    ylabel('Amplitude')
    
    subplot(3,1,2)
    plot(repmat(t, [1,chans,bands]),10*log10(out.^2))
    xlabel('Time (s)')
    xlim([0 t(end)])
    ylabel('Level (dB)')
    
    subplot(3,1,3)
    lenTF = length(TF);
    TFhalf = TF(1:ceil(lenTF/2),:,:);
    lenTF_half = length(TFhalf);
    f = in.fs .* ((1:lenTF_half)'-1) ./ lenTF;
    semilogx(repmat(f(2:end),[1,chans, bands]),10*log10(abs(TFhalf(2:end,:,:)).^2))
    xlabel('Frequency (Hz)')
    xlim([20 f(end)])
    ylabel('Gain (dB)')
end


