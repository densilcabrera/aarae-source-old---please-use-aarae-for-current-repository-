function OUT = narrowbandfilterbank(IN,fs,fftdur,flo,fhi,componentsperband,orderout,phasemode)
% This filterbank is based on an fft and ifft of the input signal. The
% filters are specified in relation to the spectrum components
%
% Note that it is possible for this filterbank to return many many bands


if isstruct(IN)
    audio = IN.audio;
    fs = IN.fs;
else
    audio = IN;
end

[len,chans,bands,dim4,dim5,dim6] = size(audio);

% if the input is already multiband, then mixdown first
if bands > 1
    audio = sum(audio,3);
    bands = 1;
    disp('Multi-band audio has been mixed-down prior to octave band filtering')
end

if nargin < 3
    param = inputdlg({'FFT window duration (s), or use 0 to make it equal to the input wave duration';...
        'Lowest centre frequency (Hz)';...
        'Highest centre frequency (Hz)';...
        'Number of spectrum components within each filter bandwidth (odd number >= 3, includes half-power cutoff components)';...
        'Filter out-of-band order';...
        'Zero phase [0], Minimum phase [1] or Maximum phase [-1]'},...
        'Filterbank settings',...
        [1 60],...
        {'0';'20';'200';'3';'12';'0'});
    if isempty(param)
        OUT = [];
        return
    end
    param = str2num(char(param));
    fftdur = param(1);
    flo = param(2);
    fhi = param(3);
    componentsperband = param(4);
    orderout = param(5);
    phasemode = param(6);
else
    if ~exist('fs','var'),fs = 48000; end
    if ~exist('fftdur','var'),fftdur = 0; end
    if ~exist('flo','var'),flo = 20; end
    if ~exist('fhi','var'),fhi = 200; end
    if ~exist('componentsperband','var'),componentsperband = 3; end
    if ~exist('orderout','var'),orderout = 12; end
    if ~exist('phasemode','var'),phasemode = 0; end
end

if fftdur == 0, fftdur = len/fs; end
if phasemode ~= 0 || phasemode ~=10
    fftdur = 2*fftdur;
end
fftlen = 2*ceil(fftdur*fs/2); % even length fft
f = fs*((1:fftlen)'-1)./fftlen; % list of frequencies
indlo = find(abs(f(1:end/2)-flo) == min(abs(f(1:end/2)-flo)),1,'first');
indhi = find(abs(f(1:end/2)-fhi) == min(abs(f(1:end/2)-fhi)),1,'first');

if componentsperband < 3, componentsperband = 3; end
if rem(componentsperband,2) == 0, componentsperband=componentsperband+1; end

audio = fft(audio,fftlen);

bandfiltered = zeros(fftlen,chans,bands,dim4,dim6,dim6);

findex = indlo:componentsperband-2:indhi;
bands = length(findex);
for b = 1:bands
    % magnitude envelope
    mag = zeros(fftlen,1);
    lowcutoff = findex(b) - floor(componentsperband/2);
    hicutoff = findex(b) + floor(componentsperband/2);
    mag(lowcutoff+1:hicutoff-1) = 1; % 0 dB
    [mag(lowcutoff), mag(hicutoff)] = deal(1/2^0.5); % -3 dB
    mag(2:lowcutoff-1) = ...
        (f(2:lowcutoff-1)./ f(lowcutoff) ).^(orderout) ./2.^0.5;
    mag(hicutoff+1:fftlen/2+1) = ...
        (f(hicutoff+1:fftlen/2+1) ./ f(hicutoff)).^(-orderout) ./ 2.^0.5;
    mag(fftlen/2+2:end) = flipud(mag(2:fftlen/2));
    
    % complex coefficients for phase processing
    if (phasemode == 1) || (phasemode == 11)
        % convert mag to min phase complex coefficients
        mag = minphasefreqdomain(mag);
    elseif (phasemode == -1) || (phasemode == -11)
        % convert mag to max phase complex coefficients
        mag = conj(minphasefreqdomain(mag));
    end
    
    if (phasemode == -11) || (phasemode == 10) || (phasemode == 11)
        % zero the upper half of the spectrum for quadrature (complex) filters
        mag(fftlen/2:end) = 0;
    end
    
    if (phasemode == 0) || (phasemode == 10)
        bandfiltered(:,:,b,:,:,:) = ifft(repmat(mag,[1,chans,1,dim4,dim5,dim6]) .* audio);
    elseif (phasemode == -1) || (phasemode == 1)
        % real output only for min phase and max phase
        bandfiltered(:,:,b,:,:,:) = real(ifft(repmat(mag,[1,chans,1,dim4,dim5,dim6]) .* audio));
    elseif (phasemode == -11) || (phasemode == 11)
        % quadrature min and max phase
        bandfiltered(:,:,b,:,:,:) = ifft(repmat(mag,[1,chans,1,dim4,dim5,dim6]) .* audio);
    else
        disp('Phasemode value not recognized');
        OUT = [];
        return
    end
    
end

if phasemode ~= 0 || phasemode ~=10
    bandfiltered = bandfiltered(1:round(end/2),:,:,:,:,:);
end

clear audio

if isstruct(IN)
    OUT = IN;
    OUT.audio = bandfiltered;
    OUT.bandID = f(findex);
    OUT.funcallback.name = 'narrowbandfilterbank.m';
    OUT.funcallback.inarg = {fs,fftdur,flo,fhi,componentsperband,orderout,phasemode};
else
    OUT = bandfiltered;
end