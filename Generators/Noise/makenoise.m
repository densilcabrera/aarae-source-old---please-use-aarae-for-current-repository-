function y = makenoise(fexponent, duration, fs, flow, fhigh, nchan, window, display)
% generates simple noise signals defined by spectral slope and bandpass limits
% by densil cabrera
% calculation is done in the frequency domain using random phase and the
% desired magnitude response
% 
% the output, y, is in the form (time, channels)
% the rms level (prior to windowing) is set at -18.618 dB re full scale
% (0.125 of full scale amplitude)
% The sound that is automatically played has a maximum duration of 2 s
% (although the data generated can be much longer)
%
% fexponent is the power spectrum slope exponent
% i.e., the power spectrum slope is proportional to 1/f.^fexponent
% examples of fexponent values:
% -2.666667 is Hoff noise (-5 dB/oct in constant percentage bandwidth analysis)
% -2 is red (or brown or brownian) noise (-3 dB/oct in cpb analysis)
% -1 is pink noise (0 dB/oct in cpb analysis)
% 0 is white noise (+3 dB/oct in cpb analysis)
% 1 is blue noise (+6 dB/oct in cpb analysis)
% 2 is violet noise (+9 dB/oct in cpb analysis)
% i.e., dBperOctave = 3*fexponent + 3
%
% duration is the duration of the signal in seconds
% 
% fs is sampling rate in Hz
%
% flow is the low frequency cut-off of a brick wall bandpass filter
% fhigh is the high frequency cut-off of a brick wall bandpass filter
%
% nchan is the number of channels to generate (incoherent)
%
% window is a number between 0 and 1, which controls the ratio of flat to
% tapered duration of the Tukey window function (to fade-in and fade-out)
% a value of 0 yields a rectangular window (no fade-in or fade-out)
% a value of 1 yields a Hann (or hanning) window
% a value of 0.5 has 50% of the duration constant, with 25% fade-in and 25%
% fade-out
%
% if display == 1, then a pair of charts is displayed, and the sound
% played
%
% example of calling this function:
% y = makenoise(-1,1,48000,100,10000,3,0.5,1);

if nargin < 8, display = 1; end;
if nargin < 7, window = 0; end;
if nargin < 6, nchan = 1; end;

% number of samples of the output wave
nsamples = duration * fs;
% even number of samples
if rem(nsamples,2) == 1, nsamples = nsamples + 1; end

% magnitude slope function (for half spectrum, not including DC and
% Nyquist)
magslope = ((1:nsamples/2-1)./(nsamples/4)).^(fexponent*0.5)';

% bandpass filter
if fhigh < flow
    ftemp = flow;
    flow = fhigh;
    fhigh = ftemp;
end
if flow >= nsamples / fs
    lowcut = floor(flow * nsamples / fs);
    magslope(1:lowcut) = 0;
end
if fhigh <= fs/2 - nsamples / fs
    highcut = ceil(fhigh * nsamples / fs);
    magslope(highcut:end) = 0;
end

% generate noise in the frequency domain, by random phase
noisyslope = repmat(magslope,1,nchan) .* exp(1i*2*pi.*rand(nsamples/2-1,nchan));
clear magslope;

% transform to time domain
y = ifft([zeros(1,nchan);noisyslope;zeros(1,nchan);flipud(conj(noisyslope))]);
clear noisyslope;

% find factor to make rms 0.125
rmsadjust = 0.125 / mean(mean(y.^2)).^0.5;
% adjust rms of wave to 0.125
y = y .* rmsadjust;

% generate window function
windowfunction = tukeywin(nsamples,window);
% apply window function
y = y .* repmat(windowfunction,1,nchan);
clear windowfunction;

% charts and sound
if display == 1
    spectrum = 10*log10(abs(fft(y)).^2)-20*log10(nsamples);
    spectrum = spectrum(1:nsamples/2,:);
    figure
    subplot(2,1,1)
    plot(((1:nsamples)-1)./fs,y);
    xlabel('Time (s)');
    ylabel('Amplitude');
    ylim([-1 1]);
    subplot(2,1,2)
    plot(((1:nsamples/2)-1)./nsamples .* fs, spectrum);
    xlabel('Frequency (Hz)');
    ylabel('Level per component (dB)');

    % maximum duration to play
    maxduration = 2; % max duration in seconds
    endplay = min([fs*maxduration nsamples]);
    % maximum channels to play
    maxchan = min([2 nchan]);
    % play sound
    sound(y(1:endplay,1:maxchan),fs);
end