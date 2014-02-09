function out = steadystate(in,fs,duration)
% Steady state rendering of audio (which can be useful for sonification).
%
% This is achieved by adding random phase offsets to the spectrum 
% (interchannel phase difference is preserved).
%
% Code by Densil Cabrera
% version 1.01 (10 February 2014)
%
% INPUT ARGUMENTS
% in is audio data, or a structure containing audio data (.audio) and 
% sampling rate (.fs) . If it is a structure, then the other input
% arguments are not used.
% fs is sampling rate in Hz
% duration is the duration of the sonification in seconds

if isstruct(in)
    out = in; % replicate fields
    data = in.audio;
    fs = in.fs;
    
    % dialog box for settings
prompt = {'Output audio duration (s):'};
dlg_title = 'Settings';
num_lines = 1;
def = {'1'};
answer = inputdlg(prompt,dlg_title,num_lines,def);

if isempty(answer)
    y = [];
    return
else
    duration = str2num(answer{1,1});
end
else
    data = in;
end

% discard 3rd dimension if it exists
data = squeeze(data(:,:,1));

% check number of channels
[~, chan] = size(data);

% ensure fft length is positive and even
fftlen = 2*ceil(abs(duration*fs)/2); 

% do fft of BIR with zero-padding
spectrum = fft(data,fftlen); 

% operate from DC to Nyquist frequency
halfspec = spectrum(1:fftlen/2+1,:); 

% random phase offsets, evenly distributed between –pi and pi
% (don't change phase of DC or Nyquist!)
randphases = rand(length(halfspec)-2,1).*2*pi;
% same random phase offsets on ch 2 preserves interchannel phase difference
if chan == 2, randphases(:,2) = randphases(:,1); end
% add random phase offsets
halfspec(2:end-1,:) = abs(halfspec(2:end-1,:)).*...
    exp(1i.*(randphases + angle(halfspec(2:end-1,:))));

% return to time domain
y = ifft([halfspec; conj(flipud(halfspec(2:end-1,:)))]);

% 10 ms fade-in & fade-out
windfunc = tukeywin(fftlen, 0.01/duration); 
if chan == 2, windfunc(:,2) = windfunc(:,1); end
y = y .* windfunc;

% Write to output
if isstruct(in)
    out.audio = y;
else
    out = y;
end

% Loop for replaying, saving and finishing
choice = 0;

% loop until the user presses the 'Done' button
while choice < 3
    choice = menu('What next?', ...
        'Play', ...
        'Save wav file', 'Discard', 'Done');
    switch choice
        
        case 1
            sound(y./max(max(abs(y))),fs)
            
        case 2
            [filename, pathname] = uiputfile({'*.wav'},'Save as');
            if ischar(filename)
                audiowrite([pathname,filename], y./max(max(abs(y))), fs);
            end
        case 3
            y = [];
    end
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
