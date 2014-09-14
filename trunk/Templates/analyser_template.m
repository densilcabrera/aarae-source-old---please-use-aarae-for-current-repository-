function [OUT, varargout] = analyser_template(IN, input_1, input_2, input_3, input_4)
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
if nargin ==1 % If the function is called within the AARAE environment it
              % will have at least one input parameter which is the audio
              % data structure that your function will process, therefore
              % you can check that the user has input all input parameters
              % if you want your function to work as standalone outside the
              % AARAE environment. You can use this input dialog to request
              % for the additional parameters that you require for your
              % function to work if they're not part of the AARAE structure

    param = inputdlg({'Parameter 1';... % These are the input box titles in the
                      'Parameter 2'},...% inputdlg window.
                      'Window title',... % This is the dialog window title.
                      [1 30],... % You can define the number of rows per
                      ...        % input box and the number of character
                      ...        % spaces that each box can display at once
                      ...        % per row.
                      {'2';'3'}); % And the preset answers for your dialog.

    param = str2num(char(param)); % Since inputs are usually numbers it's a
                                  % good idea to turn strings into numbers.
                                  % Note that str2double does not work
                                  % here.

    if length(param) < 2, param = []; end % You should check that the user 
                                          % has input all the required
                                          % fields.
    if ~isempty(param) % If they have, you can then assign the dialog's
                       % inputs to your function's input parameters.
        input_1 = param(1);
        input_2 = param(2);
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
    
    
    % The following field values might not be needed for your anlyser, but
    % in some cases they are (delete if not needed). Bear in mind that
    % these fields might not be present in the input structure, and so a
    % way of dealing with missing field values might be needed. Options
    % include: using default values, asking for user input via a dialog
    % box, analysing the sound to derive values (probably impractical), and
    % exiting from the function
    if isfield(IN,'cal') % Get the calibration offset if it exists
        cal = IN.cal;
        % Note that the aarae basic processor cal_reset_aarae could be
        % called here. However, in this template it is called later.
    else
        % Here is an example of how to exit the function with a warning
        % message
        h=warndlg('Calibration data missing - please calibrate prior to calling this function.','AARAE info','modal');
        uiwait(h)
        OUT = []; % you need to return an empty output
        return % get out of here!
    end
    
    % chanID is a cell array of strings describing each channel
    if isfield(IN,'chanID') % Get the channel ID if it exists
        chanID = IN.chanID;
    else
        chanID = cellstr([repmat('Chan',size(audio,2),1) num2str((1:size(audio,2))')]);
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
    % Sometimes you may wish to get another audio input
    % The following uses an in-built AARAE function 'choose_audio' to do
    % this for you. If you wish to do the same with this function outside
    % the AARAE environment (as a stand-alone), then it might be easiest to
    % have the additional audio as an input argument to the function.
    if false % change to true if you wish to enable the following
        % Use a menu & dialog box to select a wav file or audio within AARAE 
        selection = choose_audio; % call AARAE's choose_audio function
        if ~isempty(selection)
            auxiliary_audio = selection.audio; % additional audio data
            fs2 = selection.fs; % sampling rate
            if ~(fs2 == fs)
                % match sampling rates if desired
                gcd_fs = gcd(fs,fs2); % greatest common denominator
                auxiliary_audio = resample(auxiliary_audio,fs/gcd_fs,fs2/gcd_fs);
                % note that you can also improve the accuracy of resampling
                % by specifying the filter characteristics (see Matlab's
                % help on resample)
            end
            [len2, chans2, bands2] = size(auxiliary_audio); % new wave dimensions
        end
    end
    % *********************************************************************
    
    
elseif ~isempty(param) || nargin > 1
                       % If for example you want to enable your function to
                       % run as a standalone MATLAB function, you can use
                       % the IN input argument as an array of type double
                       % and assign it to the audio your function is going
                       % to process.
    audio = IN;
    % for the sake of this example, input_3 is being used for fs and
    % input_4 for cal. These values would be provided by an AARAE
    % structure, but need to be provided as additional inputs if the audio
    % is not input as a structure.
    fs = input_3;
    cal = input_4;
end
% *************************************************************************





% To make your function work as standalone you can check that the user has
% either entered at least an audio variable and its sampling frequency, and
% potentially check for other required data.
if ~isempty(audio) && ~isempty(fs) && ~isempty(cal)
    % If the requirements are met, your code can be executed!
    % You may copy and paste some code you've written or write something 
    % new in the lines below, such as:
    
    % the audio's length, number of channels, and number of bands
    [len,chans,bands] = size(audio);
    
    if bands > 1
        audio = sum(audio,3); % mixdown bands if multiband
    end
    
    if chans > 1
        audio = mean(audio,2); % mixdown channels
    end
    
    audio = flipdim(audio,1);
    duration = length(audio)/fs;
    maximum = max(audio);
    minimum = min(audio);
    
    % AARAE has many functions in it, some of which may be particularly
    % useful when writing a processor or analyser. Here are a few examples
    % of potentially useful AARAE functions:
    
    % cal_reset_aarae can be used to simplify the process of applying the
    % calibration offset to your audio. In the following case, gain is
    % applied to the audio waveform such that the cal value is changed to 0
    % dB. The cal_reset_aarae function is in the Processors>Basic folder.
    audio = cal_reset_aarae(audio,0,cal);
    
    % autocropstart_aarae is especially useful for impulse response
    % analysis, when data prior to the impulse response start needs to be
    % cropped (deleted). In the following example, the start of the audio
    % wave that is before the first sample -20 dB below the peak is
    % cropped (as suggested in ISO3382-1). The autocropstart_aarae function
    % is in the Processors>Basic folder.
    audio = autocropstart_aarae(audio,-20,2);
    
    % Aweight, along with similar functions in the Processors>Filters 
    % folder, provides an easy way to implement a weighting filter.
    audio = Aweight(audio,fs);
    
    % octbandfilter_viaFFT is a versatile octave band filterbank. In the
    % example below only the first three input arguments are used, but more
    % can be used if there are particular requirements for the octave band
    % filters' performance. There are other similar functions in the
    % Processors>Filterbanks folder.
    [audio,bandID] = octbandfilter_viaFFT(audio,fs,...
        [125,250,500,1000,2000,4000]);
    
    % You may include tables to display your results using AARAE's
    % disptables.m function - this is just an easy way to display the
    % built-in uitable function in MATLAB. It has several advantages,
    % including:
    %   * automatically sizing the table(s);
    %   * allowing multiple tables to be concatenated;
    %   * allowing concatenated tables to be copied to the clipboard
    %     by clicking on the grey space between the tables in the figure;
    %   * and, if its output is used as described below, returning data to
    %     the AARAE GUI in a format that can be browsed using a bar-plots.
    
    fig1 = figure('Name','My results table');
    table1 = uitable('Data',[duration maximum minimum],...
                'ColumnName',{'Duration','Maximum','Minimum'},...
                'RowName',{'Results'});
    disptables(fig1,table1);
    % You may want to display your tables as barplots in the AARAE
    % environment, in order to do this simply use the output of the
    % disptables funtion as follows:
    %       [~,table] = disptables(fig1,table1);
    % And include your table in the output data structure
    %       OUT.tables = table;
    %
    %
    % If you have multiple tables to combine in the figure, you can
    % concatenate them:
    %       disptables(fig1,[table1 table2 table3]);
    % 
    % You may export these tables to be displayed as bar plots as if you
    % were doing it for a single table:
    %       [~,tables] = disptables(fig1,[table1 table2 table3]);
    %       OUT.tables = tables;
    %
    % The disptables function will take care of allocating each table to a
    % different barplot, there is no need to generate more than one .tables
    % field to display all your tables.
    
    % You may also include figures to display your results as plots.
    t = linspace(0,duration,length(audio));
    figure;
    plot(t,audio);
    % All figures created by your function are stored in the AARAE
    % environment under the results box. If your function outputs a
    % structure in OUT this saved under the 'Results' branch in AARAE and
    % it's treated as an audio signal if it has both .audio and .fs fields,
    % otherwise it's displayed as data.

    % You may output data to be plotted in a variety of charts, including
    % lines, mesh, surf, imagesc, loglog, and others depending on the
    % number of dimensions of your data using the doresultleaf.m function:
    % E.g.:
    %
    doresultleaf(myresultvariable,'Type [units]',{'Time','channels','Frequency'},...
                 'Time',      t,                's',           true,...
                 'channels',  chanID,           'categorical', [],...
                 'Frequency', num2cell(bandfc), 'Hz',          false,...
                 'name','my_results');
    %
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
        OUT = IN; % You can replicate the input structure for your output
        OUT.audio = audio; % And modify the fields you processed
        % However, for an analyser, you might not wish to output audio (in
        % which case the two lines above might not be wanted.
        %
        % Or simply output the fields you consider necessary after
        % processing the input audio data, AARAE will figure out what has
        % changed and complete the structure. But remember, it HAS TO BE a
        % structure if you're returning more than one field:
        
        OUT.duration = duration;
        OUT.maximum = maximum;
        OUT.minimum = minimum;
        % (Note that the above outputs might be considered to be redundant
        % if OUT.tables is used, as described above).
        
        % The following outputs are needed so that AARAE can repeat the
        % analysis without user interaction (e.g. for batch processing).
        OUT.funcallback.name = 'analyser_template.m'; % Provide AARAE
        % with the name of your function 
        OUT.funcallback.inarg = {input_1,input_2,input_3,input_4}; 
        % assign all of the 
        % input parameters that could be used to call the function 
        % without dialog box to the output field param (as a cell
        % array) in order to allow batch analysing.
    else
        % You may increase the functionality of your code by allowing the
        % output to be used as standalone and returning individual
        % arguments instead of a structure.
        OUT = audio;
    end
    varargout{1} = duration;
    varargout{2} = maximum;
    varargout{3} = minimum;
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