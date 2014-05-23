function OUT = calculator_template(input_1, input_2)
% This function can be used as a template for adapting your
% calculator functions to work in the AARAE environment.
%
% As al alternative function header you may use:
%
%function calculator_template(input_1, input_2)
%
% If your calculator doesn't return any variables but only generates plots
% or tables to be displayed.
%
% AARAE calculators require that given that you do require an output of
% your function this output to be given in the form of a structure type
% variable. You may use 'OUT' as the name of your output structure. You can
% design your function to take as many input arguments as you require, but
% usually, since AARAE doesn't allow to input parameters as if you were
% executing the function from MATLAB's Command Window, these parameters are
% requested upon the functions' call in AARAE through an input dialog
% window (See MATLAB help inputdlg). Nonetheless, it's useful to declare
% the input arguments if you'd like your function to be useful as a
% standalone function in MATLAB.
%
% You can also use these first few lines to write a brief description of
% what your function does. This will be displayed as a tooltip when the
% user hoovers the mouse over the box where your function is displayed in
% AARAE
%
% The next few lines show an example on how you may use MATLAB's built-in
% inputdlg function to allow the user to type in the input arguments your
% function requires to work.

if nargin == 0 % If the function is called within the AARAE environment it
               % won't have any input arguments, this is when the inputdlg
               % function becomes useful.

    param = inputdlg({'Input 1';... % These are the input box titles in the
                      'Input 2'},...% inputdlg window.
                      'Window title',... % This is the dialog window title.
                      [1 30],... % You can define the number of rows per
                      ...        % input box and the number of character
                      ...        % spaces that each box can display at once
                      ...        % per row.
                      {'2';'3'}); % And the preset answers for your dialog.

    param = str2num(char(param)); % Since inputs are usually numbers it's a
                                  % good idea to turn strings into numbers.

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

% Normally calculators do not have audio inputs. If you wish to make a
% calculator that has audio input, first think about whether it would be
% better classified as a processor or analyser. If it is really best as a
% calculator, then audio can be input using AARAE's choose_audio function.
% If you wish to do the same with this function outside
% the AARAE environment (as a stand-alone), then it might be easiest to
% have the input audio as an input argument to the function.
if false % change to true if you wish to enable the following
    
    % Use a menu & dialog box to select a wav file or audio within AARAE
    selection = choose_audio; % call AARAE's choose_audio function
    if ~isempty(selection)
        audio = selection.audio; % audio data
        fs = selection.fs; % sampling rate
        [len, chans, bands] = size(audio); % input audio dimensions
    end
end

% To make your function work as standalone you can check that the user has
% either entered some parameters as inputs or that the inputs have been
% acquired through the input dialog window.
if ~isempty(param) || nargin ~= 0
    % If there are some input parameters to work with then your code can be
    % executed! You may copy and paste some code you've written or write
    % something new in the lines below, such as:

    input_sum = input_1 + input_2;
    input_subtract = input_1 - input_2;
    input_multiply = input_1 * input_2;
    input_divide = input_1 / input_2;
    
    % And once you have your result, you should set it up in an output form
    % that AARAE can understand.
    
    if nargin == 0
        OUT.sum = input_sum;
        OUT.subtract = input_subtract;
        OUT.multiply = input_multiply;
        OUT.divide = input_divide;
    end

    % You may include tables to display your results using AARAE's
    % disptables.m function, this is just an easy way to display the
    % built-in uitable function in MATLAB
    f = figure;
    t = uitable('Data',[input_sum input_subtract input_multiply input_divide],...
                'ColumnName',{'+','-','*','/'},...
                'RowName',{'Results'});
    disptables(f,t);
    % You may want to display your tables as barplots in teh AARAE
    % environment, in order to do this simply use the output of the
    % disptables funtion as follows:
    %       [~,table] = disptables(fig1,table1);
    % And include your table in the output data structure
    %       OUT.tables = table;
    % If you have multiple tables to combine in the figure, you can
    % concatenate them:
    % 
    %       disptables(fig1,[table1 table2 table3]);
    % 
    % You may export these tables to be displayed as bar plots as if you
    % were doing it for a single table:
    %       [~,tables] = disptables(fig1,[table1 table2 table3]);
    %       OUT.tables = tables;
    % The disptables function will take care of allocating each table to a
    % different barplot, there is no need to generate more than one .tables
    % field to display all your tables.
    
    % You may also include figures to display your results as plots.
    f2 = figure;
    plot(peaks)
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