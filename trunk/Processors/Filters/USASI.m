function OUT = USASI(IN,fs)
% Noise simulating long-term programme material spectrum from [7],[8].
% The level is such that the power is 0dB over an infinite bandwidth
% [7]   NRSC AM Reemphasis, Deemphasize, and Broadcast Audio Transmission Bandwidth Specifications,
%       EIA-549 Standard, Electronics Industries Association , July 1988.
% [8]   NRSC AM Reemphasis, Deemphasize, and Broadcast Audio Transmission Bandwidth Specifications,
%       NRSC-1-A Standard, Sept 2007, Online: http://www.nrscstandards.org/SG/NRSC-1-A.pdf 
% using filter from Mike Brookes' Voicebox
processed = [];
if nargin < 2
    if isstruct(IN)
        audio = IN.audio;
        fs = IN.fs;
    else
        audio = IN;
        fs = inputdlg({'Sampling frequency [samples/s]'},...
            'Fs',1,{'48000'});
        fs = str2num(char(fs));
    end
end
if ~isempty(audio) && ~isempty(fs)
    %if isdir([cd '/Processors/Filters/' num2str(fs) 'Hz'])
    if false % bypass ths code
        content = load([cd '/Processors/Filters/' num2str(fs) 'USASIFilter.mat']);
        filterbank = content.filterbank;
        processed = filter(filterbank,1,audio);
        
    else
        % use stdspectrum.m from voicebox
        [b,a] = stdspectrum(9,'z',fs);
        processed = filter(b,a,audio);
    end
    if isstruct(IN)
        OUT = IN;
        OUT.audio = processed;
        OUT.funcallback.name = 'USASI.m';
        OUT.funcallback.inarg = {};
    else
        OUT = processed;
    end
end