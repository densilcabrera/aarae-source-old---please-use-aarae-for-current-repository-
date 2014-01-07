function out = audification_simple(in)
% Provides a simple framework for audification of input audio
%
% Audification means 'playing data as if it is sound'. When we audify an
% audio waveform, this can be as trivial as playing it. However, it is also
% possible to do some simple transformations of the audio data so that
% certain features become more audible.
%
% Common transformations that are used in audification include:
% * filtering
% * speeding up or slowing down the wave (resampling it);
% * time-reversing the waveform;
% * doing envelope manipulations;
% * doing spectrum manipulations;
%
% Code by Densil Cabrera
% version 1.0 (12 October 2013)
%
% ABOUT THE SETTINGS
% The default values result in no change in the audio
%
% A high-pass and/or low-pass filter can be applied. The specified
% frequencies refer to the original file (prior to resampling if that is
% done). Filtering is done via fft.
%
% Speed-up (resampling) factor may be used to speed up or slow down the
% audio data. A value of 2 doubles the speed (with a +1 octave frequency
% shift). A value of 0.5 halves the speed (with a -1 octave frequency
% shift).
%
% Time reversal can be set (1) or clear (0, meaning no change).
%
% The envelope dynamic contrast exponent controls the time envelope of the
% audio (via the Hilbert transform):
%   1 creates no change
%   A larger number (e.g. 1) increases dynamic contrast)
%   0 creates a constant envelope (no dynamic contrast)
%   A negative value inverts the dynamic contrast.
%
% The envelope smoothing filter length is the length (in samples) of a
% filter used to smooth the envelope function. It should be a positive
% integer. A value of 1 creates no smoothing.
%
% The spectrum dynamic contrast exponent acts similarly to the envelope
% dynamic contrast exponent, except that it is applied to the spectrum.
%   1 creates no change
%   A greater number (e.g. 2) increases dynamic contrast in the spectrum)
%   0 creates a constant magnitude spectrum (no dynamic contrast)
%   A negative value inverts the magnitude spectrum.
%
% The spectrum smoothign filter works in the same way as the envelope
% smoothing filter, except that it is applied to the spectrum magnitude.



% required field of input structure
out = squeeze(in.audio(:,:,1)); % audio waveform, 2-d max
fs = in.fs; % audio sampling rate
Nyquist  = fs/2;

% dialog box for settings
prompt = {'High cutoff frequency (Hz):', ...
    'Low cutoff frequency (Hz):', ...
    'Speed-up (resampling) factor:', ...
    'Time reversal (0 | 1):', ...
    'Envelope dynamic contrast exponent:', ...
    'Envelope smoothing filter length:', ...
    'Spectrum magnitude contrast exponent:', ...
    'Spectrum smoothing filter length:'};
dlg_title = 'Settings';
num_lines = 1;
def = {num2str(Nyquist),'0','1','0','1','1','1','1'};
answer = inputdlg(prompt,dlg_title,num_lines,def);

if isempty(answer)
    out = [];
    return
else
    hiF = str2num(answer{1,1});
    loF = str2num(answer{2,1});
    speedupfactor = str2num(answer{3,1});
    reverse = str2num(answer{4,1});
    envelopeexp = str2num(answer{5,1});
    envelopesmooth = str2num(answer{6,1});
    spectrumexp = str2num(answer{7,1});
    spectrumsmooth = str2num(answer{8,1});
end
envelopesmooth = abs(round(envelopesmooth-1))+1;
spectrumsmooth = abs(round(spectrumsmooth-1))+1;

% filtering
if ~(hiF == Nyquist) || ~(loF == 0);
    % derive spectrum, even length
    fftlen = 2*ceil(length(out)/2);
    spectrum = fft(in.audio,fftlen);
    
    % lowpass filter
    if (hiF < Nyquist) && (hiF > loF)  && (hiF > 0)
        hicomponent = ceil(hiF / (in.fs / fftlen)) + 1;
        spectrum(hicomponent:fftlen - hicomponent+2,:) = 0;
    end
    
    % hipass filter
    if (loF > 0) && (loF < hiF) && (loF < Nyquist)
        locomponent = floor(loF / (in.fs / fftlen)) + 1;
        spectrum(1:locomponent,:,:) = 0;
        spectrum(fftlen-locomponent+2:fftlen,:) = 0;
    end
    
    % return to time domain
    out = ifft(spectrum);
end


% resampling
if ~(speedupfactor == 1)
    out = resample(out,fs,fs*speedupfactor);
end

% time reversal
if reverse
    out = flipud(out);
end

% envelope contrast and smoothing
if ~(envelopeexp == 1) || ~(envelopesmooth == 1)
    analytic = hilbert(out);
    envelope = abs(analytic) .^ envelopeexp;
    if ~(envelopesmooth == 1)
        b = ones(1,envelopesmooth)/envelopesmooth;  % averaging filter
        envelope = fftfilt(b,envelope);% smooth the envelope
    end
    % adjust output by envelope
    out = envelope .* cos(angle(analytic));
end

% spectrum contrast
if ~(spectrumexp == 1) || ~(spectrumsmooth == 1)
    spectrum = fft(out);
    magnitude = abs(spectrum).^(spectrumexp);
    phase = angle(spectrum);
    %phase = angle(spectrum);
    if ~(spectrumsmooth == 1)
        b = ones(1,spectrumsmooth)/spectrumsmooth;  % averaging filter
        magnitude = fftfilt(b,magnitude);% smooth the envelope
    end
    spectrum = magnitude .* exp(1i * phase);
    out = real(ifft(spectrum));
end

% play
%normalize
out = out ./max(max(abs(out)));

% Loop for replaying, saving and finishing
choice = 0;

% loop until the user presses the 'Done' button
while choice < 3
    choice = menu('What next?', ...
        'Play', ...
        'Save wav file', 'Discard', 'Done');
    switch choice
        
        case 1
            sound(out,fs)
            
        case 2
            [filename, pathname] = uiputfile({'*.wav'},'Save as');
            if ischar(filename)
                audiowrite([pathname,filename], out, fs);
            end
        case 3
            out = [];
    end
end


