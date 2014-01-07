function out = autoconvolve_spectexponent(in)
% Performs n-th power autoconvolution by raising the signal's spectrum to
% an exponent. 
%
% Use an exponent of 2 for first order autoconvolution.
% Higher integers yield more extreme results (and longer duration output).
% -1 inverts the spectrum.
% 0 yields an impulse.
% 1 yields the original (notwithstanding rounding errors).
% Note that fractional exponents will yield complex-valued
% signals.
%
% The output is normalized by default (but this can be bypassed).
% An optional lowpass and/or highpass filter can be applied.
%
% Code by Densil Cabrera.
% version 1.0 (11 October 2013)
%
% INPUT AND OUTPUT ARGUMENTS
% The input argument is a structure with the following fields required:
% in.audio: contains the audio data (dim1 is time, dim2 is chans, dim3 is
%   bands in the case of pre-filtered signals).
% in.fs: is the audio sampling rate in Hz.
%
% The output waveform retains the same dim2 and dim3 configuration as the
% input, and has the same sampling rate, but will probably be a different 
% length.

Nyquist = in.fs/2;
% dialog box to get user settings
prompt = {'Exponent','Normalize (0 | 1)', 'High cutoff frequency (Hz)', ...
    'Low cutoff frequency', 'Play audio (0 | 1)'};
dlg_title = 'Settings';
num_lines = 1;
def = {num2str(2),num2str(1),num2str(Nyquist),num2str(0),num2str(1)};
answer = inputdlg(prompt,dlg_title,num_lines,def);
if ~isempty(answer)
    exponent = str2num(answer{1,1});
    normalize = str2num(answer{2,1});
    hiF = str2num(answer{3,1});
    loF = str2num(answer{4,1});
    audioplay = str2num(answer{5,1});
end

% fft must be long enough to avoid circular autoconvolution
len = length(in.audio);
fftlen = len * abs(exponent);
if fftlen < len, fftlen = len; end
fftlen = 2*(ceil(fftlen/2)); % even length to simplify filtering

% derive spectrum and apply exponent
spectrum = fft(in.audio,fftlen).^exponent;

% lowpass filter
if (hiF < Nyquist) && (hiF > loF)  && (hiF > 0)
    hicomponent = ceil(hiF / (in.fs / fftlen)) + 1;
    spectrum(hicomponent:fftlen - hicomponent+2,:,:) = 0;
end

% hipass filter
if (loF > 0) && (loF < hiF) && (loF < Nyquist)
    locomponent = floor(loF / (in.fs / fftlen)) + 1;
    spectrum(1:locomponent,:,:) = 0;
    spectrum(fftlen-locomponent+2:fftlen,:,:) = 0;
end

% return to time domain
out = ifft(spectrum);

% normalization
if normalize
    out = out / max(max(max(abs(abs(out)))));
end

if audioplay
    if ~isreal(out)
        wavout = abs(out);
        disp('Autoconvolution output is complex.')
    else
        wavout = out;
    end
    
    sound(wavout, in.fs)
        
    % Loop for replaying, saving and finishing
    choice = 'x'; % create a string
    
    % loop until the user presses the 'Done' button
    while ~strcmp(choice,'Done')
        choice = questdlg('What next?', ...
            'Autoconvolution', ...
            'Play again', 'Save audio', 'Done','Done');
        switch choice
            case 'Play again'
                sound(wavout, in.fs)
            case 'Save audio'
                [filename, pathname] = uiputfile({'*.wav'},'Save as');
                if ~filename == 0
                    audiowrite([pathname,filename],wavout,in.fs);
                end
        end % switch
    end % while
end
