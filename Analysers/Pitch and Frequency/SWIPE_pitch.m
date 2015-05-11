function [OUT, varargout] = SWIPE_pitch(IN,doSWIPEP,hicut,locut,plim,dt,dlog2p,dERBs,sTHR,MIXDOWN,fs)
% 


if nargin ==1 
   
    
    param = inputdlg({'Do SWIPE [0] or SWIPEP [1]?';...
        'Upper frequency limit for pitch estimate (Hz)';...
        'Lower frequency limit for pitch estimate (Hz)';...
        'Time step between windows (s)';...
        'Inverse of Resolution';...
        'ERB scale resolution';...
        'Pitch strength threshold';...
        'Mixdown multichannel audio? [0 | 1]?'},...
        'SWIPE pitch analysis settings',... % This is the dialog window title.
        [1 60],...
        {'1';'5000';'30';'0.01';'96';'0.1';'-inf';'1'}); % And the preset answers for your dialog.
    
    param = str2num(char(param)); 
    
    if length(param) < 8, param = []; end 
    if ~isempty(param) 
        doSWIPEP = param(1);
        hicut = param(2);
        locut = param(3);
        plim = [locut hicut];
        dt = param(4);
        dlog2p = 1/param(5);
        dERBs = param(6);
        sTHR = param(7);
        MIXDOWN = param(8);
    else
        % get out of here if the user presses 'cancel'
        OUT = [];
        return
    end
else
    param = [];
end


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
    
    
    
    % chanID is a cell array of strings describing each channel
    if isfield(IN,'chanID') % Get the channel ID if it exists
        chanID = IN.chanID;
    else
        % or make a chanID using AARAE's utility function
        chanID = makechanID(size(audio,2),0);
    end
    
    
    
    
    
elseif ~isempty(param) || nargin > 1
    
    audio = IN;
    
end
% *************************************************************************





% Check that the required data exists for analysis to run
if ~isempty(audio) && ~isempty(fs) 
    
    
    % the audio's length, number of channels, and number of bands
    [len,chans,bands] = size(audio);
    
    if bands > 1
        audio = sum(audio,3); % mixdown bands if multiband
    end
    

    
    if MIXDOWN
        audio = mean(audio,2);
        chans = 1;
    end
    
    time = (0: dt: len/fs)'; % Times
    [pitch, strength] = deal(zeros(length(time),chans));
    
    for ch = 1:chans
        if ~doSWIPEP
            [pitch(:,ch),~,strength(:,ch)] = swipe(audio(:,ch),fs,plim,dt,dlog2p,dERBs,sTHR);
        else
            [pitch(:,ch),~,strength(:,ch)] = swipep(audio(:,ch),fs,plim,dt,dlog2p,dERBs,sTHR);
        end
    end
    
    
    % Pitch Statistics
    
    
    
    
    % Pitch timeseries
    if doSWIPEP
        figure('Name', 'SWIPEP Pitch Analysis')
    else
        figure('Name', 'SWIPE Pitch Analysis')
    end
    
    subplot(2,1,1)
    for ch = 1:chans
        c = [ch/chans, 1-ch/chans, rem(pi*ch,1)];
        plot(time(:,1),pitch(:,ch),...
            'DisplayName',['Ch',num2str(ch)],...
            'Color',c)
        hold on
        xlabel('Time (s)')
        ylabel('Pitch height (Hz)')
        % Perhaps a log scale would be better
       
    end
    
    
    
    subplot(2,1,2)
    for ch = 1:chans
        c = [ch/chans, 1-ch/chans, rem(pi*ch,1)];
        plot(time(:,1),strength(:,ch),...
            'DisplayName',['Ch',num2str(ch)],...
            'Color',c)
        hold on
        xlabel('Time (s)')
        ylabel('Pitch Strength')
    end
    
    
    % *** CREATING A TABLE OR MULTIPLE TABLES ***
    % You may include tables to display your results using AARAE's
    % disptables.m function - this is just an easy way to display the
    % built-in uitable function in MATLAB. It has several advantages,
    % including:
    %   * automatically sizing the table(s);
    %   * allowing multiple tables to be concatenated;
    %   * allowing concatenated tables to be copied to the clipboard
    %     by clicking on the grey space between the tables in the figure;
    %   * if its output is used as described below, returning data to
    %     the AARAE GUI in a format that can be browsed using a bar-plots.
    %   * and values from tables created this way are written into the log
    %     file for the AARAE session, which provides another way of
    %     accessing the results together with a complete record of the
    %     processing that led to the results.
    
    %     fig1 = figure('Name','My results table');
    %     table1 = uitable('Data',[duration maximum minimum],...
    %                 'ColumnName',{'Duration','Maximum','Minimum'},...
    %                 'RowName',{'Results'});
    %     disptables(fig1,table1); % see below for a better alternative!
    % It is usually a very good idea to return your table(s) data to AARAE
    % as a function output field. Doing this creates a table leaf in the
    % Results section of the GUI, which can be explored as bar plots within
    % the GUI, and also writes the table contents to the log file (as a
    % comma delimited table that can easily be interpreted by a
    % spreadsheet). To do this, simply use the output of the
    % disptables funtion as follows:
    %       [~,table] = disptables(fig1,table1);
    % And include your table in the output data structure
    %       OUT.tables = table;
    %
    %
    % If you have multiple tables to combine in the figure, you can
    % concatenate them:
    %       disptables(fig1,[table3 table2 table1]);
    % (Note that the concatenation is in descending order - i.e. the first
    % listed table in the square brackets will be displayed at the bottom,
    % and the last listed table will be displayed at the top.)
    %
    % You may export these tables to be displayed as bar plots as if you
    % were doing it for a single table:
    %       [~,tables] = disptables(fig1,[table3 table2 table1]);
    %       OUT.tables = tables;
    %
    % The disptables function will take care of allocating each table to a
    % different barplot, there is no need to generate more than one .tables
    % field to display all your tables.
    
    
    
    
    
    % *** CREATING A RESULTS LEAF (FOR BIG NON-AUDIO DATA) ***
    % You may output data to be plotted in a variety of charts, including
    % lines, mesh, surf, imagesc, loglog, and others depending on the
    % number of dimensions of your data using the doresultleaf.m function:
    % E.g.:
    %
    %     doresultleaf(myresultvariable,'Type [units]',{'Time','channels','Frequency'},...
    %                  'Time',      t,                's',           true,...
    %                  'channels',  chanID,           'categorical', [],...
    %                  'Frequency', num2cell(bandfc), 'Hz',          false,...
    %                  'name','my_results');
    %     %
    % Input arguments:
    % #1: Your data variable. It can be multidimensional, make sure you
    %     specify what each dimension is.
    % #2: What is your data variable representing? is it level? is it
    %     reverb time? make sure you label it appropriately and assign
    %     units to it, this second argument is a single string.
    % #3: This is a cell array where each cell contains the name of each
    %     dimension.
    %
    % #4: Name of your first dimension. (String)
    % #5: Matrix that matches your first dimension, in this case time.
    % #6: Units of your first dimension. (String)
    % #7: Can this dimension be used as a category? (true, false, [])
    %
    % Replicate arguments 4 to 7 for as many dimensions as your data
    % variable has.
    %
    % The second last input argument is the string 'name', this helps the
    % function identify that the last input argument is the name that will
    % be displayed in AARAEs categorical tree under the results leaf.
    
    
    
    % And once you have your result, you should set it up in an output form
    % that AARAE can understand.
    if isstruct(IN)
        
        % *** OUTPUTTING AUDIO ***
        % Most analysers do not output audio. If you wish to output audio,
        % first consider whether your analyser should be a processor
        % instead. If it should be an analyser, then audio can be output as
        % follows:
        %         OUT = IN; % You can replicate the input structure for your output
        %         OUT.audio = audio; % And modify the fields you processed
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
        OUT.funcallback.name = 'SWIPE_pitch.m'; % Provide AARAE
        % with the name of your function
        OUT.funcallback.inarg = {doSWIPEP,hicut,locut,plim,dt,dlog2p,dERBs,sTHR,MIXDOWN,fs};
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
        OUT = pitch;
    end
    varargout{1} = time;
    varargout{2} = strength;
    
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