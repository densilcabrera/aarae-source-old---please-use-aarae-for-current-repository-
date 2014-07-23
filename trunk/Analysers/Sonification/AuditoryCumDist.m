function OUT = AuditoryCumDist(IN, windowtime, timefactor, method, weight, order, doplay, fs)
% This function creates an auditory cumulative distribution graph, loosely
%  based on one of the concepts in
%
% S. Ferguson and D. Cabrera, "Exploratory sound analysis: Sonifying data
% about sound," Proceedings of the 14th International Conference on
% Auditory Display, Paris, France, June 24-27, 2008.
%
% This function breaks the audio into windows, then each window is analysed
% to derive a parameter value, then the windows are sorted in order of the
% parameter values (from lowest to highest value). This is done
% independently for each channel and band (if more than one is input).
%
% This process is most useful for recordings that are not short, and which
% contain somewhat diverse content (e.g., background noise, speech or music
% recordings). It is probably not useful for impulse response analysis.
%
% code by Densil Cabrera
% version 0 (23 July 2014)


if nargin ==1 

    param = inputdlg({'Window duration (s)';... 
                      'Duration compression/expansion factor (s)';
                      'Parameter: Rms (1), Centroid (2), Spectral peak ratio (3)';...
                      'A-weighting of parameter [0 | 1]';...
                      'Ascending [0] or Descending order [1]';...
                      'Play audio [0 | 1]'},...
                      'Settings',... 
                      [1 60],... 
                      {'0.1';'1';'1';'0';'0';'0'}); % preset answers

    param = str2num(char(param)); 

    if length(param) < 5, param = []; end 
    if ~isempty(param) 
        windowtime = param(1);
        timefactor = param(2);
        method = param(3);
        weight = param(4);
        order = param(5);
        doplay = param(6);
    end
else
    param = [];
end


% *************************************************************************
if isstruct(IN) 
    audio = IN.audio; % Extract the audio data
    fs = IN.fs;       % Extract the sampling frequency of the audio data
    
    
    
    if isfield(IN,'cal') % Apply the calibration offset if it exists
        audio = cal_reset_aarae(audio,0,IN.cal);
    end
    
    
    if isfield(IN,'chanID') % Get the channel ID if it exists
        chanID = IN.chanID;
    else
        chanID = cellstr([repmat('Chan',size(data,2),1) num2str((1:size(data,2))')]);
    end
    
   
    if isfield(IN,'bandID') % Get the band ID if it exists
        bandID = IN.bandID;
    else
        bandID = 1:size(audio,3);
    end
    

    % *********************************************************************
    
    
elseif ~isempty(param) || nargin > 1
                       
    audio = IN;
    chanID = cellstr([repmat('Chan',size(data,2),1) num2str((1:size(data,2))')]);
    bandID = 1:size(audio,3);
end
% *************************************************************************






if ~isempty(audio) && ~isempty(fs) && ~isempty(windowtime) ...
        && ~isempty(timefactor) && ~isempty(method) && ~isempty(doplay)
    
    [len,chans,bands] = size(audio);
        
    winlen = round(windowtime*fs);
    offset = floor(0.5 * winlen / timefactor); % hop in samples
    if offset < 1, offset = 1; end
    nwin = floor((len-winlen) / offset); % number of windows
    writeoffset = floor(0.5 * winlen);
    
    % generate matrix of windows
    audiowindows = zeros(winlen,chans,bands,nwin);
    for n = 1:nwin
        startindex = (n-1)*offset+1;
        endindex = startindex + winlen - 1;
        audiowindows(:,:,:,n) = audio(startindex:endindex,:,:);
    end
    
    % apply window function
    winfun = hann(winlen); % Hann window
    % winfun = winfun ./ rms(winfun); % no energy lost
    audiowindows = audiowindows .* repmat(winfun,[1,chans,bands,nwin]);
    
    if weight == 1
        audiowindows2 = Aweight(audiowindows,fs);
    else
        audiowindows2 = audiowindows;
    end
    
    % Measure chosen parameter
    switch method
        case 0 % retain original order
            value = permute(1:nwin,[1,4,3,2]);
            value = repmat(value,[1,chans,bands,1]);
            axislabel = 'Original order [index]';
        case 1 % rms level
            value = 10*log10(mean(audiowindows2.^2));
            axislabel = 'Level [dB]';
        case 2 % power spectral centroid 
            powspec = abs(fft(audiowindows2)).^2;
            f = fs*((1:winlen)-1)';
            span = floor(winlen/2);
            value = sum(powspec(1:span,:,:,:)...
                .* repmat(f(1:span),[1,chans,bands,nwin])) ...
                ./ sum(powspec(1:span,:,:,:));
            axislabel = 'Power spectral centroid [Hz]';
        case 3 % spectral peakiness: max/mean, excluding DC
            % (a quick way of estimating steady state pitch strength)
            powspec = abs(fft(audiowindows2)).^2; 
            span = floor(winlen/2);
            value = 10*log10(max(powspec(2:span,:,:,:)) ./ mean(powspec(2:span,:,:,:)));
            axislabel = 'Spectral peak ratio [dB]';
            
        % ADD MORE METHODS HERE!
        
        otherwise
            % random values
            value = rand(1,chans,bands,nwin);
            axislabel = 'Random order [index]';
    end
    value = permute(value,[4,2,3,1]);
    
    % return indices of values in ascending order
    if order == 1
        [sortedvalues,IX] = sort(value,1,'descend');
    else
        [sortedvalues,IX] = sort(value,1,'ascend');
    end
    
    
    % construct output audio by concatenative synthesis
    outaudio = zeros(ceil(nwin * writeoffset + winlen),chans,bands);
    for n = 1:nwin
        startindex = (n-1)*writeoffset+1;
        endindex = startindex + winlen - 1;
        for ch = 1:chans
            for b = 1:bands
                outaudio(startindex:endindex,ch,b) = ...
                    outaudio(startindex:endindex,ch,b) + ...
                    audiowindows(:,ch,b,IX(n,ch,b));
            end
        end
    end
    
    
    if doplay == 1
        audiomixdown = sum(outaudio,3);
        if chans > 2
            audiomixdown = sum(audiomixdown,2);
        end
        audiomixdown = audiomixdown ./ max(max(abs(audiomixdown)));
        sound(audiomixdown,fs);
%         p=audioplayer(audiomixdown,fs);
%         play(p);
    end
   
    %generate a visualisation of value
     t = (((1:nwin)-1)*offset + 0.5*winlen) ./ fs;
     % Generate the RGB values of colours to be used in the plots
        M = plotcolours(chans, bands);
        figure('Name','Values used for sonification');
        for ch = 1:chans
            for b = 1:bands
                plot(t,sortedvalues(:,ch,b),'Color',squeeze(M(b,ch,:))',...
                    'DisplayName',[char(chanID(ch)),' bnd ',num2str(bandID(b))])
                hold on
            end
        end
        xlabel('Window centre time [s]');
        ylabel(axislabel);
        title('Sonification has been added to Results')
    

    if isstruct(IN)
        OUT = IN; 
        OUT.audio = outaudio; 
        
        OUT.funcallback.name = 'AuditoryCumDist.m'; 
        OUT.funcallback.inarg = {windowtime, timefactor, method, weight, order, doplay, fs}; 
        
    else
        
        OUT = outaudio;
    end
    

else
    
    OUT = [];
end
end

%**************************************************************

function M = plotcolours(chans, bands)
% define plot colours in HSV colour-space
% use Value for channel
% use Hue for band

% Saturation = 1
S = ones(bands,chans);

% Value
maxV = 1;
minV = 0.4;
if chans == 1
    V = minV;
else
    V = minV:(maxV-minV)/(chans-1):maxV;
end
V = repmat(V,[bands,1]);

% Hue
if bands == 1
    H = 0;
else
    H = 0:1/(bands):(1-1/bands);
end
H = repmat(H',[1,chans]);

% convert HSV to RGB
M = hsv2rgb(cat(3,H,S,V));

end % eof

%**************************************************************************
% Copyright (c) 2014, Densil Cabrera & Sam Ferguson
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