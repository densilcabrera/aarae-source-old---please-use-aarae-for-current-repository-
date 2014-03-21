function OUT = tilt_spectrum_logf(in, fs, dBperOct, doplay)
% Applies a tilt to the magnitude spectrum of the input. The tilt is linear
% as a function of log(frequency), and is specified in decibels per octave.
%
% The operation is done in the frequency domain, without changing phase.
%
% This can, for example, be used to transform between white and pink noise,
% or assist in the derivation of impulse responses from a logarithmic swept
% sine that is missing its inverse filter.
%
%
% Code by Densil Cabrera
% version 1.0 (19 October 2013)

if nargin < 4, doplay = 0; end
if nargin < 3
    dBperOct = 3;
    %dialog box for settings
    prompt = {'Spectrum tilt (dB/octave)', ...
        'Play and/or display (0|1)'};
    dlg_title = 'Settings';
    num_lines = 1;
    def = {'3', '0'};
    answer = inputdlg(prompt,dlg_title,num_lines,def);
    
    if ~isempty(answer)
        dBperOct = str2num(answer{1,1});
        doplay = str2num(answer{2,1});
    else
        OUT = [];
        return
    end
end

if isstruct(in)
    data = in.audio;
    fs = in.fs;
else
    data = in;
    if nargin < 2
        fs = inputdlg({'Sampling frequency [samples/s]'},...
                           'Fs',1,{'48000'});
        fs = str2num(char(fs));
    end
end

if ~isempty(data) && ~isempty(fs) && ~isempty(dBperOct) && ~isempty(doplay)
    S = size(data); % size of the audio
    ndim = length(S); % number of dimensions
    switch ndim
        case 1
            len = S(1); % number of samples in audio
            chans = 1; % number of channels
            bands = 1; % number of bands
        case 2
            len = S(1); % number of samples in audio
            chans = S(2); % number of channels
            bands = 1; % number of bands
        case 3
            len = S(1); % number of samples in audio
            chans = S(2); % number of channels
            bands = S(3); % number of bands
    end

    nsamples = 2*(len/2); % use an even length fft

    % exponent used to generate magnitude slope
    fexponent = dBperOct/3;

    % magnitude slope of half spectrum not including DC and Nyquist components
    magslope = ((1:nsamples/2-1)./(nsamples/4)).^(fexponent*0.5)';

    % magnitude slope across the whole spectrum
    magslope = [1; magslope; 1; flipud(magslope)];

    % apply the spectrum slope filter
    y = ifft(fft(data,nsamples) .* repmat(magslope,[1,chans,bands]));

    if isstruct(in)
        OUT.audio = y;
        OUT.funcallback.name = 'tilt_spectrum_logf.m';
        OUT.funcallback.inarg = {fs,dBperOct,doplay};
    else
        OUT = y;
    end

    if doplay
        % Loop for replaying, saving and finishing
        choice = 0;

        % loop until the user presses the 'Done' button
        while choice < 4
            choice = menu('What next?', ...
                'Play audio', ...
                'Plot spectrogram', 'Save wav file', 'Discard', 'Done');
            switch choice
                case 1
                    ysumbands = sum(y,3);
                    sound(ysumbands./max(max(abs(ysumbands))),fs)
                case 2
                    spectrogram_simple(y,fs);
                case 3
                    [filename, pathname] = uiputfile({'*.wav'},'Save as');
                    ysumbands = sum(y,3);
                    if max(max(abs(ysumbands)))>1
                        ysumbands = ysumbands./max(max(abs(ysumbands)));
                        disp('Wav data has been normalized to avoid clipping')
                    end
                    if ischar(filename)
                        audiowrite([pathname,filename], ysumbands, fs);
                    end
                case 4
                    y = [];
            end
        end
    end
else
    OUT = [];
end