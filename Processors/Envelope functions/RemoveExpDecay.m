function [OUT, varargout] = RemoveExpDecay(IN, fs, start_time, end_time)
% This function calculates the exponential decay rate of an input audio
% wave (e.g. a room impulse response) and compensates for it.
%
% The decay rate is calculated over the time period between the 'start time'
% and 'end time', and then the whole wave is adjusted accordingly. It may
% be useful to view the waveform using decibels (level) to help decide
% on the values of start and end times.
%
% The decay rate is expressed as an equivalent reverberation time, which is
% displayed in Matlab's Command Window.
%
% This function works with multiple channels and multiple bands.
%
% It can be used to listen to how the spectrum of a room impulse response
% evolves over time.
%
% by Densil Cabrera
% version 0.00 (10 December 2013)

if nargin ==1 

    param = inputdlg({'Start time (s)';... 
                      'End time (s)'},...
                      'Settings',... % This is the dialog window title.
                      [1 30],... 
                      {'0.05';'0.5'}); % Default values.

    param = str2num(char(param)); 

    if length(param) < 2, param = []; end 
    if ~isempty(param) 
        start_time = param(1);
        end_time = param(2);
    end
else
    param = [];
end
if isstruct(IN) 
    audio = IN.audio; % Extract the audio data
    fs = IN.fs;       % Extract the sampling frequency of the audio data
    
    if isfield(IN,'bandID')
        bandID = IN.bandID;
    end
    
    if isfield(IN,'chanID')
        chanID = IN.chanID;
    end
    
elseif ~isempty(param) || nargin > 1
                      
    audio = IN;
    
end



if ~isempty(audio) && ~isempty(fs)
    
    [len, chans, bands] = size(audio);
    
    if ~exist('bandID','var')
        bandID = 1:bands;
    end
    
    if ~exist('chanID','var')
        chanID = 1:chans;
    end
    
    Tend = ceil(end_time * fs);
    if Tend > len, Tend = len; end
    
    Tstart = floor(abs(start_time * fs));
    
    decaycurve = flipdim(10*log10(cumsum(flipdim(audio.^2,1))+1e-300),1);
    decaycurve = decaycurve - repmat(decaycurve(1,:,:),[len,1,1]);
    
    slope = zeros(chans, bands);
    for ch = 1:chans
        for b = 1:bands
            p = polyfit((Tstart:Tend)'./fs, decaycurve(Tstart:Tend,ch,b),1); %linear regression
            slope(ch,b) = p(1);
            
        end
    end
    
    T = -60 ./ slope;
    tau1 = T ./ (log(60));
    tau1 = permute(tau1,[3,1,2]);
     audio_out = audio .* exp((repmat((0:len-1)',[1,chans, bands])./fs)./repmat(tau1,[len,1,1]));
    
    if isstruct(IN)
        OUT = IN; 
        OUT.audio = audio_out;
    else
        
        OUT = audio_out;
    end
    varargout{1} = fs;
    
%     f = figure('Name','Original Reverberation Time Estimates');
%     t = uitable('Data',T,...
%                 'ColumnName',num2cell(bandID),...
%                 'RowName',num2cell(chanID));
%     set(t,'ColumnWidth',{60});
%     disptables(f,t);

% The following needs to be modified to be able to use chanID as a cell (it
% was written when chanID was a vector).
% [r,~] = size(bandID);
% if r > 1
%     bandID = bandID';
% end
% 
% [~,c] = size(chanID);
% if c > 1
%     chanID = chanID';
% end
% 
% display_data = [[0;chanID],[bandID; round(T*100)/100]];
% 
% disp('Estimated reverberation times (in seconds) prior to decay compensation:');
% disp(num2str(display_data));

else
    OUT = [];
end

%**************************************************************************
% Copyright (c) 2013, Densil Cabrera
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