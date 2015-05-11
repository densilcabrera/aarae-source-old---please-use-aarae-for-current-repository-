function OUT = Tonality_thirdoctmethod(IN,fs)
% This function can be used as a template for adapting your audio
% analysing functions to work in the AARAE environment.
%
% AARAE analysers take the audio information stored in the AARAE tree
% display and process the input to produce an output. Unlike generator and
% calculator functions in AARAE, analyser functions require an input in
% the form of a structure type variable (IN) and will output a structure
% type variable with the analysis result (OUT). The input structure will
% ALWAYS have at least the fields .audio, .fs and .datatype that you can
% use to analyse the audio. Analysers may as well include additional
% fields to the output structure in the .properies field (structure type)
%
% You can also use these first few lines to write a brief description of
% what your function does. This will be displayed as a tooltip when the
% user hoovers the mouse over the box where your function is displayed in
% AARAE
%

% *************************************************************************
% The next few lines show an example on how you may use MATLAB's built-in
% inputdlg function to allow the user to type in the input arguments your
% function requires to work.
% if nargin ==1 % If the function is called within the AARAE environment it
%               % will have at least one input parameter which is the audio
%               % data structure that your function will process, therefore
%               % you can check that the user has input all input parameters
%               % if you want your function to work as standalone outside the
%               % AARAE environment. You can use this input dialog to request
%               % for the additional parameters that you require for your
%               % function to work if they're not part of the AARAE structure
%
%     param = inputdlg({'Parameter 1';... % These are the input box titles in the
%                       'Parameter 2'},...% inputdlg window.
%                       'Window title',... % This is the dialog window title.
%                       [1 30],... % You can define the number of rows per
%                       ...        % input box and the number of character
%                       ...        % spaces that each box can display at once
%                       ...        % per row.
%                       {'2';'3'}); % And the preset answers for your dialog.
%
%     param = str2num(char(param)); % Since inputs are usually numbers it's a
%                                   % good idea to turn strings into numbers.
%                                   % Note that str2double does not work
%                                   % here.
%
%     if length(param) < 2, param = []; end % You should check that the user
%                                           % has input all the required
%                                           % fields.
%     if ~isempty(param) % If they have, you can then assign the dialog's
%                        % inputs to your function's input parameters.
%         input_1 = param(1);
%         input_2 = param(2);
%     else
%         % get out of here if the user presses 'cancel'
%         OUT = [];
%         return
%     end
% else
%     param = [];
% end


% *************************************************************************
if isstruct(IN) % You should check that the function is being called within
    % the AARAE environment, if so, you can extract the
    % information you need to run your processor. Audio in
    % AARAE is in a Matlab structure (hence the isstruct test).
    
    % AARAE audio data can have up to 6 dimension, but most analysers cannot
    % handle all of those dimensions. The following utility function call
    % reduces the number of dimensions in the audio field of the input
    % structure if they are greater than the second input argument (3 in
    % the example below). For further information see the comments in
    % choose_from_higher_dimensions in AARAE's utilities directory. Unless
    % there is a reason not to, it is usually a good idea to support
    % analysis of the first three dimensions.
    IN = choose_from_higher_dimensions(IN,3,1);
    
    audio = IN.audio; % Extract the audio data
    fs = IN.fs;       % Extract the sampling frequency of the audio data
    
    
    % Calibration is unnecessary in this algorithm
    %     if isfield(IN,'cal') % Get the calibration offset if it exists
    %         cal = IN.cal;
    %         % Note that the aarae basic processor cal_reset_aarae could be
    %         % called here. However, in this template it is called later.
    %     else
    %         % Here is an example of how to exit the function with a warning
    %         % message
    %         h=warndlg('Calibration data missing - please calibrate prior to calling this function.','AARAE info','modal');
    %         uiwait(h)
    %         OUT = []; % you need to return an empty output
    %         return % get out of here!
    %     end
    if isfield(IN,'cal')
        audio = cal_reset_aarae(audio, 0, IN.cal);
    end
    
    % chanID is a cell array of strings describing each channel
    if isfield(IN,'chanID') % Get the channel ID if it exists
        chanID = IN.chanID;
    else
        % or make a chanID using AARAE's utility function
        chanID = makechanID(size(audio,2),0);
    end
    
    
    
    
    
elseif ~isempty(param) || nargin > 1
    % If for example you want to enable your function to
    % run as a standalone MATLAB function, you can use
    % the IN input argument as an array of type double
    % and assign it to the audio your function is going
    % to process.
    audio = IN;
end
% *************************************************************************





% Check that the required data exists for analysis to run
if ~isempty(audio) && ~isempty(fs) 
    % If the requirements are met, your code can be executed!
    % You may copy and paste some code you've written or write something
    % new in the lines below, such as:
    
    % the audio's length, number of channels, and number of bands
    bands = size(audio,3);
    
    if bands > 1
        audio = sum(audio,3); % mixdown bands if multiband
    end
    
    
    % Aweight, along with similar functions in the Processors>Filters
    % folder, provides an easy way to implement a weighting filter.
    audio = Aweight(audio,fs);
    
    % Apply 1/3-octave band filterbank
    frequencies = [25,31.5,40,50,63,80,100,125,160,200,250,315,400,...
        500,630,800,1000,1250,1600,2000,2500,3150,4000,5000,6300,8000,10000];
    
    audio = thirdoctbandfilter(audio,fs,frequencies,1);
    
    L = 10*log10(mean(mean(audio.^2,1),2));
    L = permute(L,[1,3,2]);
    
    
    
    % ****************** Start Paul's Code
    
    % According to AS/NZS 2107:2000,if the ....
    Low_band = L(1:8);
    Mid_band = L(9:13);
    High_band = L(14:27);
    [~,locs_low] = findpeaks(Low_band,'Threshold',15);
    [~,locs_mid] = findpeaks(Mid_band,'Threshold',8);
    [~,locs_high] = findpeaks(High_band,'Threshold',5);
    
    % This section will nevigate whether the first and the last values are
    %higher than the second value(more than 15 dB in low frequency band)
    % if so, the first value and the last valus should also be considered as
    % peaks
    First_low = L(1)-L(2);
    if First_low>=15
        Final_locs_low(1) = 1;
        
        for ii=2:size(locs_low,2)+1
            Final_locs_low(ii) = locs_low(ii-1);
        end
    else
        Final_locs_low=locs_low;
    end
    
    %if the last is higher than the previous one
    
    Last_low = L(8)-L(7);
    if Last_low>=15
        Final_locs_low(size(Final_locs_low,2)+1)=8;
    else
        Final_locs_low=locs_low;
    end
    %
    if ~isempty(Final_locs_low)
    Final_pks_low = L(Final_locs_low);
    Final_lowpeak_frequency = frequencies (Final_locs_low);
    else
        Final_pks_low = [];
        Final_lowpeak_frequency = [];
    end
        
    
    % 
    %  Low_peak = [Final_pks_low;Final_lowpeak_frequency];
    
    
    
    
    
    % mid
    
    First_mid = L(9)-L(10);
    if First_mid>=8
        Final_locs_mid(1) = 9;
        
        for ii=2:size(locs_mid,2)+1
            Final_locs_mid(ii) = locs_mid(ii-1)+8;
        end
    else
        Final_locs_mid=locs_mid+8;
    end
    
    %if the last is higher than the previous one
    
    Last_mid = L(13)-L(12);
    if Last_mid>=8
        Final_locs_mid(size(Final_locs_mid,2)+1)=13;
    else
        Final_locs_mid=locs_mid+8;
    end
    %
    if ~isempty(Final_locs_mid)
    Final_pks_mid = L(Final_locs_mid);
    Final_midpeak_frequency = frequencies (Final_locs_mid);
    else
        Final_pks_mid = [];
    Final_midpeak_frequency = [];
    end
    %
    % Mid_peak = [Final_pks_mid;Final_midpeak_frequency];
    
    
    % high
    
    First_high = L(14)-L(15);
    if First_high>=5
        Final_locs_high(1) = 14;
        
        for ii=2:size(locs_high,2)+1
            Final_locs_high(ii) = locs_high(ii-1)+13;
        end
    else
        Final_locs_high = locs_high+13;
    end
    
    %if the last is higher than the previous one
    
    Last_high = L(27)-L(26);
    if Last_high>=5
        Final_locs_high(size(Final_locs_high,2)+1)=27;
    else
        Final_locs_high=locs_high+13;
    end
    %
    if ~isempty(Final_locs_high)
        Final_pks_high = L(Final_locs_high);
        Final_highpeak_frequency = frequencies (Final_locs_high);
    else
        Final_pks_high = [];
        Final_highpeak_frequency = [];
    end
    % 
    % High_peak = [Final_pks_high;Final_highpeak_frequency];
    
    Final_pks = [Final_pks_low Final_pks_mid Final_pks_high];
    Final_frequency = [Final_lowpeak_frequency Final_midpeak_frequency Final_highpeak_frequency];
    Final_locs = [Final_locs_low Final_locs_mid Final_locs_high];
    
    
    % ****************** End Paul's Code
    
    
    
           figure('name', '1/3-Octave Band Tonality Analyisis')
           
           ymax = 10*ceil(max(L+5)/10);
            ymin = 10*floor(min(L)/10);

            width = 0.5;
            

        

            
            
            
            
            
            bar(1:length(frequencies),L,width,'FaceColor',[0,0.7,0],...
                'EdgeColor',[0,0,0],'DisplayName', 'Leq','BaseValue',ymin);
            
            hold on
            
            peakbars = nan(1,length(frequencies));

            for k = 1:length(frequencies)
                if ~isempty(find(Final_locs==k, 1))
                    peakbars(k) = L(k);
                end
            end
            
            bar(1:length(frequencies),peakbars,width,'stacked','FaceColor',[1,0,0], ...
                'EdgeColor',[0,0,0],'DisplayName', 'Peaks','BaseValue',ymin);
            
            
            
            %hold on

            % x-axis
            set(gca,'XTick',1:length(frequencies),'XTickLabel',num2cell(frequencies))

            xlabel('1/3-Octave Band Centre Frequency (Hz)')


            % y-axis
            
            
            ylabel('Level (dB)')
            ylim([ymin ymax])


            legend 'off'
            

            for k = 1:length(frequencies)
                if ~isempty(find(Final_locs==k, 1))
                text(k-0.25,ymax-(ymax-ymin)*0.025, ...
                    num2str(round(L(k)*10)/10),'Color',[1,0,0])
                else
                    text(k-0.25,ymax-(ymax-ymin)*0.025, ...
                    num2str(round(L(k)*10)/10),'Color',[0,0.7,0])
                end
            end
    
    
            
    
    
    
    if isstruct(IN)
        
        % *** OUTPUTTING AUDIO ***
        % Most analysers do not output audio. If you wish to output audio,
        % first consider whether your analyser should be a processor
        % instead. If it should be an analyser, then audio can be output as
        % follows:
        %OUT = IN; % You can replicate the input structure for your output
        %OUT.audio = audio; % And modify the fields you processed
        % However, for an analyser, you might not wish to output audio (in
        % which case the two lines above might not be wanted.
        
        
        
        % *** OUTPUTTING NEW FIELDS ***
        % Or simply output the fields you consider necessary after
        % processing the input audio data, AARAE will figure out what has
        % changed and complete the structure. But remember, it HAS TO BE a
        % structure if you're returning more than one field:
        

        % The advantages of providing outputs as subfields of properties
        % are that AARAE has a button that opens a window to display
        % properties, and that properties are also written to the log file
        % of the AARAE session. Outputing fields without making them
        % subfields of properties is possible, but this makes the output
        % data harder to access.
        % Note that the above outputs might be considered to be redundant
        % if OUT.tables is used, as described above. Generally the
        % properties fields output is suitable for small data only (e.g.
        % single values). Tables is best for small and medium data, while a
        % results leaf is is best for big data.
        
        
        
        % *** FUNCTION CALLBACKS ***
        % The following outputs are required so that AARAE can repeat the
        % analysis without user interaction (e.g. for batch processing),
        % and for writing the log file.
        OUT.funcallback.name = 'Tonality_thirdoctmethod.m'; % Provide AARAE
        % with the name of your function
        OUT.funcallback.inarg = {};
        % assign all of the input parameters that could be used to call the
        % function without dialog box to the output field param (as a cell
        % array) in order to allow batch analysing. Do not include the
        % first (audio) input here. If there are no input arguments (apart
        % from the audio input), then use:
        % OUT.funcallback.inarg = {};
        
        
        
        % AARAE will only display the output in the main GUI if it includes
        % tables, audio or other fields. It will not display if only
        % function callbacks are returned. Result leaves are not created by
        % the functions main output, but instead are created by calling
        % AARAE's doresultleaf as described above, and these will be
        % displayed in AARAE's main GUI regardless of the function's main
        % outputs.
    else
        % You may increase the functionality of your code by allowing the
        % output to be used as standalone and returning individual
        % arguments instead of a structure.
        %OUT = audio;
        OUT = [];
    end
    
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