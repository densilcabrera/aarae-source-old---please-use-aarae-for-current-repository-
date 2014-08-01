function  OUT = irs(n,cycles,fs)
% This function is used to generate an inverse repeated repeated sequence
% (IRS), made from a maximum length sequence signal (mls), which can be
% used to measure impulse responses.
%
% The IRS signal consists of an MLS signal followed by its inversion, which
% can be helpful in reducing distortion artefacts in the derivation of an
% impulse response. The n input argument (or first field of the dialog box)
% determines the bit length of the MLS signal (note that the IRS signal is
% double the length of the MLS signal used). The number of samples in one
% cycle of the IRS signal is 2*(2^n-1). 
%
% This function also allows the first input argument to be used in
% alternative ways: if a value greater than 24 is used, then this is the
% length (in samples) of flat spectrum random phase noise (generated in the
% frequency domain) which is used in place of the MLS signal. If a value
% of 1 (or less) is used, then audio can be imported, its spectrum
% flattened, and then used in place of the MLS signal. These alternative
% approaches are mainly included for experimentation, rather than for
% serious measurement.
%
% This function calls code by M.R.P. Thomas  - please refer to
% the following folder AARAE/Generators/Noise/mls, which contains his code,
% documentation and license.
%
% The function outputs the IRS sequence (in the audio field), together with
% the time-reversed IRS signal (as audio2). The signal is time reversed for
% compatability with the general use of audio2 as an inverse filter.
% However, you should not normally use AARAE's '*' button (which convolves
% audio with audio2) to obtain the impulse response, although it will
% probably still work to an extent, because it does linear convolution
% rather than the required circular convolution (or cross-correlation with
% the non-reversed signal). Instead use the processor CircXcorrforIR to
% derive the impulse response, which is in AARAE's Cross & auto functions
% folder (in Processors).
%
% code by Densil Cabrera
% Version 1 (1 August 2014)


if nargin == 0
    param = inputdlg({'Bit length of MLS [2-24], or length of random-phase white noise [>24], or make IRS from flattened-spectrum imported audio [1]';...
                       'Number of cycles [2 or more]';...
                       'Sampling frequency [Hz]'},...
                       'IRS input parameters',1,{'16';'2';'48000'});
    param = str2num(char(param));
    if length(param) < 3, param = []; end
    if ~isempty(param)
        n = round(param(1));
        cycles = round(param(2));
        if cycles < 2, cycles = 2; end
        fs = param(3);
    end
else
    param = [];
end
if ~isempty(param) || nargin ~= 0
    
    if n >=2 && n <=24
    %inefficient, but avoids any need to edit Thomas' code
    [~, mls] = GenerateMLSSequence(2, n, 0); 
    irs = [mls'; -mls'];
    elseif n > 24
    % generate flat spectrum random phase noise   
        if rem(n,2) == 0
             % even length spectrum
            halfspectrum = ones(n/2-1,1).* exp(1i*2*pi.*rand(n/2-1,1));
            y = ifft([0;halfspectrum;0;flipud(conj(halfspectrum))]);
        else
            % odd length spectrum
            halfspectrum = ones(floor(n/2),1).* exp(1i*2*pi.*rand(floor(n/2),1));
            y = ifft([0;halfspectrum;flipud(conj(halfspectrum))]);
        end
        irs = [y;-y];
    else
        % Import audio and flatten spectrum (apart from DC and Nyquist).
        % This method is here mainly for experimentation with the concept
        % rather than as a serious measurement tool
        selection = choose_audio; % call AARAE's choose_audio function
        if ~isempty(selection)
            audioin = selection.audio; % get audio data
            fs = selection.fs; %  overwrite previous sampling rate
            audioin = sum(sum(audioin,3),2); % mix bands and channels if >1
            audioin = fft(audioin);
            if rem(length(audioin),2) == 0
                audioin = ifft([0;ones(length(audioin)/2-1,1);0;ones(length(audioin)/2-1,1)] ...
                    .* exp(1i*2*pi.*angle(audioin))); % just keep the phase
            else
                audioin = ifft([0;ones(floor(length(audioin)/2),1);ones(floor(length(audioin)/2),1)] ...
                    .* exp(1i*2*pi.*angle(audioin))); % just keep the phase
            end
            irs = [audioin;-audioin];
        else
            OUT = [];
            return
        end
    end

    OUT.audio = [repmat(irs,[cycles,1]);zeros(size(irs))];
    OUT.audio2 = flipud(irs);
    OUT.fs = fs;
    OUT.tag = ['IRS' num2str(n)];
    OUT.properties.n = n;
    OUT.properties.combinehalves = 1; % used to set dialog box default in CircXcorrforIR
    OUT.properties.cycles = cycles;
    OUT.funcallback.name = 'irs.m';
    OUT.funcallback.inarg = {n,cycles,fs};
else
    OUT = [];
end
end % End of function