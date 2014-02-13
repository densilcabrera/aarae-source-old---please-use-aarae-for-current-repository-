function [OUT, varargout] = Golay_process(IN, fs, audio2)
% This function is used to analyse signals that were recorded using the
% Golay generator within AARAE. The output is an implulse response.
%
% code by Densil Cabrera
% version 1.00 (13 February 2014)
    

if isstruct(IN) 
    audio = IN.audio; 
    
    fs = IN.fs;       
    
    if isfield(IN,'audio2')
        audio2 = IN.audio2;
    else
        disp('The original Golay test signal is required to be in audio2 - not found')
        OUT = [];
        return
    end
    

elseif ~isempty(param) || nargin > 1

    audio = IN;
end

% To make your function work as standalone you can check that the user has
% either entered at least an audio variable and it's sampling frequency.
if ~isempty(audio) && ~isempty(fs)
   
    % find the relevent indices from audio2 - the original test signal
    lasta = find(audio2 == 0,1,'first')-1;
    firstb = find(abs(audio2(lasta+1:end)) > 0.1,1,'first')+lasta;
    lastb = length(audio2);
    
    a = audio2(1:lasta);
    b = audio2(firstb:end);

    
    % It is often important to know the dimensions of your audio
    [len,chans,bands] = size(audio);
    
if len < lastb
    disp('Recorded audio is too short for Golay processing')
    OUT = [];
    return
end

aa = audio(1:lasta,:,:);
bb = audio(firstb:lastb,:,:);

% cross correlate, sum and scale
ir = ifft(conj(fft(a)) .* fft(aa) + conj(fft(b)) .* fft(bb)) ./ (2*lasta);

    
    if isstruct(IN)
        OUT = IN; 
        OUT.audio = ir; 
    else
        
        OUT = ir;
    end
    varargout{1} = fs;
    
else
    
    OUT = [];
end

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
%  * Neither the name of the University of Sydney nor the names of its contributors
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