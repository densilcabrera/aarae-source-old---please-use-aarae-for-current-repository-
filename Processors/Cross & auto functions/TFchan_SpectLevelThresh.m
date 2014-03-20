function OUT = TFchan_SpectLevelThresh(in,fs,RefChan,Threshold,Duration,doplot)
% Calculates the transfer function between pairs of audio channels, by
% frequency domain division of cross spectrum by the reference autospectrum,
% but removing spectral components for which the
% reference (or input) channel falls below threshold (magnitude relative to
% maximum component magnitude). The output is a time response (derived via
% inverse Fourier transform).
%
% Code by Densil Cabrera
% version 1.0 (10 October 2013)

if nargin < 6, doplot = 0; end
if nargin < 5, Duration = 2; end
if nargin < 4, Threshold = -60; end
if nargin < 3
    RefChan = 1;
    if isstruct(in)
        S = in.audio; % size of the IR
        fs = in.fs;
    else
        S = in;
        if nargin < 2
            fs = inputdlg({'Sampling frequency [samples/s]'},...
                               'Fs',1,{'48000'});
            fs = str2num(char(fs));
        end
    end
    ndim = ndims(S); % number of dimensions
    switch ndim
        case 2
            len = length(S); % number of samples in IR
            chans = size(S,2); % number of channels
            bands = 1; % number of bands
        case 3
            len = length(S); % number of samples in IR
            chans = size(S,2); % number of channels
            bands = size(S,3); % number of bands
    end
    
    maxDuration = floor((len) / in.fs);
    defaultDuration = 2;
    if defaultDuration > maxDuration, defaultDuration = maxDuration; end
    
    %dialog box for settings
    prompt = {'Reference channel', 'Level threshold', 'Output duration', 'Plot (0 | 1)'};
    dlg_title = 'Settings';
    num_lines = 1;
    def = {'1','-60', num2str(defaultDuration),'0'};
    answer = inputdlg(prompt,dlg_title,num_lines,def);

    if ~isempty(answer)
        RefChan = str2num(answer{1,1});
        Threshold = str2num(answer{2,1});
        Duration = str2num(answer{3,1});
        doplot = str2num(answer{4,1});
    end
end
if isstruct(in)
    S = in.audio; % size of the IR
    fs = in.fs;
else
    S = in;
    if nargin < 2
        fs = inputdlg({'Sampling frequency [samples/s]'},...
                           'Fs',1,{'48000'});
        fs = str2num(char(fs));
    end
end
ndim = ndims(S); % number of dimensions
switch ndim
    case 2
        len = length(S); % number of samples in IR
        chans = size(S,2); % number of channels
        bands = 1; % number of bands
    case 3
        len = length(S); % number of samples in IR
        chans = size(S,2); % number of channels
        bands = size(S,3); % number of bands
end

if RefChan > chans, RefChan = 1; end
outlen = floor(Duration * fs)+1;
if outlen > len, outlen = len; end

spectrum = fft(S);

magThreshold = 10.^(Threshold / 20);

TF = zeros(len,chans,bands);
for k = 1:bands
    magnitude_ref = abs(spectrum(:,RefChan,k));
    maxmagnitude_ref = max(magnitude_ref);
    below_threshold = magnitude_ref < maxmagnitude_ref * magThreshold;
    
    Refspectrum = repmat(spectrum(:,RefChan), [1,chans]);
    
    TF(:,:,k) = conj(Refspectrum) .* spectrum(:,:,k) ./ (conj(Refspectrum) .* Refspectrum);
    
    TF(below_threshold,:,k) = 0; % zero all values below input wave threshold
end

% Return to time domain
out = ifft(TF);

% Truncate to the desired length
out = out(1:outlen,:,:);

if isstruct(in)
    OUT.audio = out;
    OUT.funcallback.name = 'TFchan_SpectLevelThresh.m';
    OUT.funcallback.inarg = {fs,RefChan,Threshold,Duration,doplot};
else
    OUT = out;
end

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


