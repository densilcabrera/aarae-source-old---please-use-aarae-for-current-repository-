function out = invertspectrum_simple(in,fs)
% This function derives a kind of 'inverse filter' of a waveform by 
% inverting its spectrum. While this is almost certainly not a useful way 
% to derive an inverse filter, it demonstrates the limitations of this
% simple and naive approach.
%
% Function settings are set via dialog box.
%
% A threshold (in dB) is applied to avoid dividing by numbers approaching 
% zero. Set it extremely low (e.g. -9999) if you with to make it
% ineffective.
%
% A high-pass and/or low-pass filter can also be applied.
%
% The input wave can be zero-padded, which changes the resolution of the
% spectrum.
%
% Optionally, an operation a little similar to Weiner deconvolution can be 
% used togenerate the inverse filter. However, this is not the same as 
% Weiner deconvolution because it has no knowledge of the signal and noise 
% levels that would ultimately be used for deconvolution. Instead the user 
% can choose a noise-to-signal ratio (in dB) which is used for all 
% frequencies. This is only included to allow experimentation.
% Use 'n' if you do not want to use this method.
%
% The filter can be rotated (so the ends shift to the middle, and the
% middle shifts to the ends). This is done using ifftshift().
%
% Code by Densil Cabrera
% version 0.0 (15 October 2013)


% INPUT ARGUMENTS
%
% The first input argument can either be a structure, containing the fields
% .audio (the waveform) and .fs (the sampling rate, or else it can be a 
% vector or matrix containing just the audio waveform (in which case
% fs is specified by the second argument). 


if isstruct(in)
    audio = in.audio;
    fs = in.fs;
else
    audio = in;
end
Nyquist = fs/2;

S = size(audio); % size of the IR
ndim = length(S); % number of dimensions
switch ndim
    case 1
        %len = S(1); % number of samples in IR
        chans = 1; % number of channels
        bands = 1; % number of bands
    case 2
        %len = S(1); % number of samples in IR
        chans = S(2); % number of channels
        bands = 1; % number of bands
    case 3
        %len = S(1); % number of samples in IR
        chans = S(2); % number of channels
        bands = S(3); % number of bands
end



%dialog box for settings
prompt = {'Level threshold', 'High cutoff frequency (Hz)', ...
    'Low cutoff frequency (Hz)', 'zero pad (samples)',...
    'pseudo-Wiener N/S ratio (dB)', ...
    'Rotate inverse filter via ifftshift (0 | 1)', 'Plot (0 | 1)'};
dlg_title = 'Settings';
num_lines = 1;


def = {'-60', num2str(Nyquist), '0', '0', 'n', '0', '1'};
answer = inputdlg(prompt,dlg_title,num_lines,def);

if ~isempty(answer)
    Threshold = str2num(answer{1,1});
    hiF = str2num(answer{2,1});
    loF = str2num(answer{3,1});
    zeropad = str2num(answer{4,1});
    doweiner = answer{5,1};
    rotateinv = str2num(answer{6,1});
    doplot = str2num(answer{7,1});
end

if doweiner == 'n'
    doweiner = false;
else
    doweiner = true;
    weiner = str2num(answer{5,1});
end

if zeropad >0
    audio = [audio; zeros(zeropad,chans,bands)];
end

len = 2*(ceil(length(audio)/2)); % make len even
invfilter = fft(audio, len);


magThreshold = 10.^(Threshold / 20);

magnitude_max = repmat(max(abs(invfilter)), [len, 1,1]);
below_threshold = magnitude_max < magnitude_max * magThreshold;

if doweiner
    invfilter = invfilter ./ (invfilter.^2 - 10.^(weiner/20));
else
invfilter = 1 ./ invfilter;
end

invfilter(below_threshold) = 0;

% lowpass filter
if (hiF < Nyquist) && (hiF > loF)  && (hiF > 0)
    hicomponent = ceil(hiF / (fs / len)) + 1;
    invfilter(hicomponent:len - hicomponent+2,:,:) = 0;
end

% hipass filter
if (loF > 0) && (loF < hiF) && (loF < Nyquist)
    locomponent = floor(loF / (fs / len)) + 1;
    invfilter(1:locomponent,:,:) = 0;
    invfilter(len-locomponent+2:len,:,:) = 0;
end

% get rid of NaN and inf if there are any
invfilter(isnan(invfilter)) = 0;
invfilter(isinf(invfilter)) = 0;

% Return to time domain
out = ifft(invfilter);

if rotateinv ==1
    out = ifftshift(out);
end


% Performance test: convolve the inverse filter with the original
zeropad = zeros(length(out),1);
errorcheck = zeros(length(audio)+length(zeropad),chans,bands);
for ch = 1:chans
    for k = 1:bands
errorcheck = filter(out(:,ch,k), 1,[audio(:,ch,k);zeropad]);
    end
end


if doplot
    figure('Name', 'Spectrum inversion of a waveform')
    
    % plot original
     subplot(3,3,1)
    t = ((1:length(audio))'-1)/fs;
    plot(repmat(t, [1,chans,bands]),audio)
    xlabel('Time (s)')
    xlim([0 t(end)])
    ylabel('Amplitude')
    title('ORIGINAL')
    
    subplot(3,3,4)
    plot(repmat(t, [1,chans,bands]),10*log10(audio.^2))
    xlabel('Time (s)')
    xlim([0 t(end)])
    ylabel('Level (dB)')
    
    subplot(3,3,7)
    spectrum = fft(audio);
    lenSpectrum = length(spectrum);
    Spectrumhalf = spectrum(1:ceil(lenSpectrum/2),:,:);
    lenES_half = length(Spectrumhalf);
    f = fs .* ((1:lenES_half)'-1) ./ lenSpectrum;
    semilogx(repmat(f(2:end),[1,chans, bands]), ...
        10*log10(abs(Spectrumhalf(2:end,:,:)).^2))
    xlabel('Frequency (Hz)')
    xlim([20 f(end)])
    ylabel('Magnitude (dB)')
    
    
        % plot inverse
    subplot(3,3,2)
    t = ((1:len)'-1)/fs;
    plot(repmat(t, [1,chans,bands]),out)
    xlabel('Time (s)')
    xlim([0 t(end)])
    ylabel('Amplitude')
    title('INVERSE')
    
    subplot(3,3,5)
    plot(repmat(t, [1,chans,bands]),10*log10(out.^2))
    xlabel('Time (s)')
    xlim([0 t(end)])
    ylabel('Level (dB)')
    
    subplot(3,3,8)
    lenSpectrum = length(invfilter);
    Spectrumhalf = invfilter(1:ceil(lenSpectrum/2),:,:);
    lenES_half = length(Spectrumhalf);
    f = fs .* ((1:lenES_half)'-1) ./ lenSpectrum;
    semilogx(repmat(f(2:end),[1,chans, bands]), ...
        10*log10(abs(Spectrumhalf(2:end,:,:)).^2))
    xlabel('Frequency (Hz)')
    xlim([20 f(end)])
    ylabel('Gain (dB)')
    
    
    
    % plot error check
    subplot(3,3,3)
    t = ((1:length(errorcheck))'-1)/fs;
    plot(repmat(t, [1,chans,bands]),errorcheck)
    xlabel('Time (s)')
    xlim([0 t(end)])
    ylabel('Amplitude')
    title('ORIGINAL FILTERED')
    
    subplot(3,3,6)
    plot(repmat(t, [1,chans,bands]),10*log10(errorcheck.^2))
    xlabel('Time (s)')
    xlim([0 t(end)])
    ylabel('Level (dB)')
    
    subplot(3,3,9)
    spectrum = fft(errorcheck);
    lenSpectrum = length(spectrum);
    Spectrumhalf = spectrum(1:ceil(lenSpectrum/2),:,:);
    lenES_half = length(Spectrumhalf);
    f = fs .* ((1:lenES_half)'-1) ./ lenSpectrum;
    semilogx(repmat(f(2:end),[1,chans, bands]), ...
        10*log10(abs(Spectrumhalf(2:end,:,:)).^2))
    xlabel('Frequency (Hz)')
    xlim([20 f(end)])
    ylabel('Magnitude (dB)')
    
    
    % Loop for replaying, saving and finishing
choice = 0;

% loop until the user presses the 'Done' button
while choice < 5
    choice = menu('What next?', ...
        'Play original', ...
        'Play inverse', ...
        'Play filtered', ...
        'Save wav file', 'Discard', 'Done');
    switch choice
        
        case 1
            sound(audio ./ max(max(abs(audio))),fs)
            
            case 2
            sound(out ./ max(max(abs(out))),fs)
            case 3
            sound(errorcheck ./ max(max(abs(errorcheck))),fs)
            
        case 4
            [filename, pathname] = uiputfile({'*.wav'},'Save as');
            if ischar(filename)
                if max(max(abs(out))) <= 1
                    audiowrite([pathname,filename], out, fs);
                else
                    audiowrite([pathname,filename], out./ max(max(abs(out))), fs);
                    disp('The saved audio has been normalized to prevent clipping.')
                end
            end
        
            
        case 5
            out = [];
    end
end
end