function [OUT, varargout] = ExponentiallyDecayingTones(tpo, flow,fhigh,duration,fs,T)
% This function generates exponentially decaying tones for testing
% impulse response analysis functions - such as reverberation time etc.
%
% Tones are octave spaced, or 1/3-octave spaced.
%
% The low frequency entered is an exact frequency and the remaining
% frequencies are calculated from it, using base 2 octaves (or 1/3
% octaves). However, for display purposes, the dialog box shows nominal
% frequencies.
%
% Tones are sine functions, and so they start at maximum positive
% amplitude. The wave is normalized to 1.
%
% The reverberation time of each tone is user-specified - and it is
% possible to vary this greatly between adjacent tones (e.g., for testing 
% the effect of bandpass filter selectivity).
%
% code by Densil Cabrera
% version 1.00 (6 February 2013)

if nargin == 0
    param = inputdlg({'Tones per octave [1 | 3]';...
        'Exact lowest frequency (Hz)';...
        'Highest frequency (Hz)';...
        'Duration (s)';...
        'Sampling rate (Hz)'},...
        'Settings 1',... % dialog window title.
        [1 60],...
        {'1';'125';'8000';'2';'48000'}); % preset answers for dialog.
    
    param = str2num(char(param));
    
    if length(param) < 5, param = []; end
    if ~isempty(param)
        tpo = param(1);
        flow = param(2);
        fhigh = param(3);
        duration = param(4);
        fs = param(5);
    end
else
    param = [];
end

noctaves = log2(fhigh/flow);
if tpo == 1
    freq = flow .* 2.^(0:round(noctaves));
else
    freq = flow .* 2.^(0:1/3:round(3*noctaves)/3);
end
freqnom = exact2nom_oct(freq);
nfreq = length(freqnom);

% DIALOG BOX FOR REVERBERATION TIMES
if ~exist('T','var')
    T = zeros(1,nfreq);
    for n = 1:nfreq
        freqcell{n} = num2str(freqnom(n));
        defaultcell{n} = '1';
    end
    
    maxfield = 15;
    
    if nfreq >= maxfield
        freqcell1 = freqcell(1:maxfield);
        defaultcell1 = defaultcell(1:maxfield);
        freqcell2 = freqcell(maxfield+1:end);
        defaultcell2 = defaultcell(maxfield+1:end);
    else
        freqcell1 = freqcell;
        defaultcell1 = defaultcell;
    end
    param = inputdlg(freqcell1,...
        'Reverberation Times',... % dialog window title.
        [1 60],...
        defaultcell1); % preset answers for dialog.
    
    param = str2num(char(param));
    
    if length(param) < min([nfreq,maxfield]), param = []; end
    if ~isempty(param)
        if nfreq > maxfield
            T(1:maxfield) = param;
        else
            T = param;
        end
    end
    if nfreq>=maxfield
        param = inputdlg(freqcell2,...
        'Reverberation Times',... % dialog window title.
        [1 60],...
        defaultcell2); % preset answers for dialog.
    
    param = str2num(char(param));

    if length(param) < (nfreq-maxfield), param = []; end
    if ~isempty(param)
        T(maxfield+1:end) = param;
    end
    end
end



if (~isempty(param) && ~isempty(T)) || nargin ~= 0
    
    
    tau = 2*T / log(1e6); % decay constant
    
    IR = zeros(round(fs*duration),1);
    t = ((1:length(IR))-1)' ./ fs;
    for k = 1:length(freq)
        IR = IR + sin(2*pi*freq(k).*t)./ exp(t./tau(k));
    end
    IR = IR ./max(abs(IR)); % normalize
    
    
    
    % And once you have your result, you should set it up in an output form
    % that AARAE can understand.
    
    if nargin == 0
        OUT.audio = IR; % You NEED to provide the audio you generated.
        %OUT.audio2 = ?;     You may provide additional audio derived from your function.
        OUT.fs = fs;       % You NEED to provide the sampling frequency of your audio.
        %OUT.tag = tag;      You may assign it a name to be identified in AARAE.
    end
    
    % You may choose to increase the functionality of your code by allowing
    % it to operate outside the AARAE environment you may want to output
    % independent variables instead of a structure...
    if nargin ~= 0
        OUT = IR;
        varargout{1} = fs;
        %varargout{2} = ?;
    end
else
    % AARAE requires that in case that the user doesn't input enough
    % arguments to generate audio to output an empty variable.
    OUT = [];
end

end % End of function

%**************************************************************************
% Copyright (c) 2014, Densil Cabrera
% All rights reserved.
%
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions are
% met:
%
%  * Redistributions of source code must retain the above copyright notice,
%    this list of conditions and the following disclaimer.
%  * Redistributions in binary form must reproduce the above copyright
%    notice, this list of conditions and the following disclaimer in the
%    documentation and/or other materials provided with the distribution.
%  * Neither the name of The University of Sydney nor the names of its contributors
%    may be used to endorse or promote products derived from this software
%    without specific prior written permission.
%
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
% "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
% TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
% PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER
% OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
% EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
% PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
% PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
% LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
% NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
% SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
%**************************************************************************