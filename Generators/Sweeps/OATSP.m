% Generates a linear sweep (Optimized Aoshima Time Streteched Pulse)
% and its inverse filter for impulse response measurement,
% based on the concepts in:
% 
% Yôiti Suzuki, Futoshi Asano, Hack-Yoon Kim, Toshio Sone (1995)
% "An optimum computer-generated pulse signal suitable for the measurement 
% of very long impulse responses"
% Journal of the Acoustical Society of America 97(2):1119-1123
%
% The sweep bandwidth is always 0 Hz to the Nyquist frequency.
%
% code by Densil Cabrera & Daniel Jimenez
% version 1.00 (13 March 2013)

function OUT = OATSP(dur,mratio,fs)


if nargin == 0
    param = inputdlg({'Duration [s]';...
                       'Ratio of main sweep duration to remaining duration [between 0 and 1]';...
                       'Sampling rate [Hz]'},...
                       'OATSP input parameters',1,{'1';'0.5';'48000'});
    param = str2num(char(param));
    if length(param) < 3, param = []; end
    if ~isempty(param)
        dur = param(1);
        mratio = param(2);
        fs = param(3);
    end   
else
    param = [];
end
if ~isempty(param) || nargin ~=0
    if ~exist('fs','var')
       fs = 48000;
    end
    if ~exist('mratio','var')
       mratio = 0.5;
    end
    
    N = 2*ceil(dur * fs/2);
    m = round((N*mratio)/2);
    k = (0:N/2)';
    Hlow = exp(1i * 4 * m * pi * k.^2 ./ N.^2);
    H = [Hlow;conj(flipud(Hlow(2:end)))];
    Sinv = ifft(H);
    Sinv = circshift(Sinv,-round(N/2-m));
    
    S = flipud(Sinv);

    OUT.audio = S;
    OUT.audio2 = Sinv;
    OUT.fs = fs;
    OUT.tag = ['OATSP_',num2str(mratio),'_', num2str(dur)];
else
    OUT = [];
end

%**************************************************************************
% Copyright (c) 2014, Densil Cabrera & Daniel Jimenez
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