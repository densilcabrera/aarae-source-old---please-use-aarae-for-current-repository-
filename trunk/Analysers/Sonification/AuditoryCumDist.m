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
                      'Parameter: Rms (0), Centroid (1)';...
                      'A-weighting of parameter [0 | 1]';...
                      'Ascending [0] or Descending order [1]';...
                      'Play audio [0 | 1]'},...
                      'Settings',... 
                      [1 60],... 
                      {'0.1';'1';'0';'0';'0';'0'}); % preset answers

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
    
    
    
%     if isfield(IN,'cal') % Get the calibration offset if it exists
%         cal = IN.cal;
%     else
%         % Here is an example of how to exit the function with a warning
%         % message
%         h=warndlg('Calibration data missing - please calibrate prior to calling this function.','AARAE info','modal');
%         uiwait(h)
%         OUT = []; % you need to return an empty output
%         return % get out of here!
%     end
    
    % chanID is a cell array of strings describing each channel
    if isfield(IN,'chanID') % Get the channel ID if it exists
        chanID = IN.chanID;
    end
    
    % bandID is a vector, usually listing the centre frequencies of the
    % bands
    if isfield(IN,'bandID') % Get the band ID if it exists
        bandID = IN.bandID;
    else
        % asssign ordinal band numbers if bandID does not exist (as an
        % example of how to deal with missing data)
        bandID = 1:size(audio,3);
    end
    

    % *********************************************************************
    
    
elseif ~isempty(param) || nargin > 1
                       
    audio = IN;
    
    
end
% *************************************************************************






if ~isempty(audio) && ~isempty(fs) && ~isempty(windowtime) ...
        && ~isempty(timefactor) && ~isempty(method) && ~isempty(doplay)
    
    [len,chans,bands] = size(audio);
    
%     if bands > 1
%         audio = sum(audio,3); % mixdown bands if multiband
%     end
%     
%     if chans > 1
%         audio = mean(audio,2); % mixdown channels
%     end
    
    
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
        case 0 % rms
            value = rms(audiowindows2);
        case 1 % power spectral centroid 
            powspec = abs(fft(audiowindows2)).^2;
            f = fs*((1:winlen)-1)';
            span = floor(winlen/2);
            value = sum(powspec(1:span,:,:,:)...
                .* repmat(f(1:span),[1,chans,bands,nwin])) ...
                ./ sum(powspec(1:span,:,:,:));
        
        otherwise
            value = repmat(1:nwin,[1,chans,bands]);
    end
    value = permute(value,[4,2,3,1]);
    
    % return indices of values in ascending order
    if order == 1
        [~,IX] = sort(value,1,'descend');
    else
        [~,IX] = sort(value,1,'ascend');
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
%      t = ((1:nwin)-1)*offset + 0.5*winlen;
% for ch = 1:chans
%     for b = 1:bands
%       plot(t,value)  
%     end
% end
    
    
    % You may also include figures to display your results as plots.
%     t = linspace(0,duration,length(audio));
%     figure;
%     plot(t,audio);
    % All figures created by your function are stored in the AARAE
    % environment under the results box. If your function outputs a
    % structure in OUT this saved under the 'Results' branch in AARAE and
    % it's treated as an audio signal if it has both .audio and .fs fields,
    % otherwise it's displayed as data.
    % You may want to include your plots as part of the data variable
    % generated by AARAE, in order to do this use the getplotdata function
    % as follows:
    %       OUT.lines.myplot = getplotdata;
    % Use this function for as many charts as you want to include as output
    % from your function. Remember to call the getplotdata function after
    % you have designed your chart. Currently this function only supports
    % barplots and lines. E.g.:
    % 
    %       plot(t,audio)
    %       OUT.lines.thischart = getplotdata;
    
    % And once you have your result, you should set it up in an output form
    % that AARAE can understand.
    if isstruct(IN)
        OUT = IN; % You can replicate the input structure for your output
        OUT.audio = outaudio; % And modify the fields you processed
        % However, for an analyser, you might not wish to output audio (in
        % which case the two lines above might not be wanted.
        %
        % Or simply output the fields you consider necessary after
        % processing the input audio data, AARAE will figure out what has
        % changed and complete the structure. But remember, it HAS TO BE a
        % structure if you're returning more than one field:
        
        
        % (Note that the above outputs might be considered to be redundant
        % if OUT.tables is used, as described above).
        
        % The following outputs are needed so that AARAE can repeat the
        % analysis without user interaction (e.g. for batch processing).
        OUT.funcallback.name = 'AuditoryCumDist.m'; % Provide AARAE
        % with the name of your function 
        OUT.funcallback.inarg = {windowtime, timefactor, method, weight, order, doplay, fs}; 
        % assign all of the 
        % input parameters that could be used to call the function 
        % without dialog box to the output field param (as a cell
        % array) in order to allow batch analysing.
    else
        % You may increase the functionality of your code by allowing the
        % output to be used as standalone and returning individual
        % arguments instead of a structure.
        OUT = outaudio;
    end
    
% The processed audio data will be automatically displayed in AARAE's main
% window as long as your output contains audio stored either as a single
% variable: OUT = audio;, or it's stored in a structure along with any other
% parameters: OUT.audio = audio;
else
    % AARAE requires that in case that the user doesn't input enough
    % arguments to generate audio to output an empty variable.
    OUT = [];
end

%**************************************************************************
% Copyright (c) <YEAR>, <OWNER>
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
%  * Neither the name of the <ORGANISATION> nor the names of its contributors
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