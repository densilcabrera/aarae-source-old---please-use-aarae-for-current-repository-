function [OUT varargout] = Blind_RT_LoellmannJeub2012(IN, input_1, input_2)
% This function calls Loellmann and Jeub's blind reverberation time
% estimation functions. Use this function to estimate reverberation time
% from reverberant speech (e.g. 60 seconds of speech recording).
%
% Please refer to the following directory for the license and for more
% information on the algorithm:
% Analysers\Reverberation\Release_RT_estimation_MatlabFileExchange
%
% Reference:
% Heinrich W. Löllmann, Emre Yilmaz, Marco Jeub and Peter Vary:
% "An Improved Algorithm for Blind Reverberation Time Estimation"
% International Workshop on Acoustic Echo and Noise Control (IWAENC),
% Tel Aviv, Israel, August 2010.
% (availabel at www.ind.rwth-aachen.de/~bib/loellmann10a)
%
% The algorithm allows to estimate the RT within a range of 0.2s to 1.2s
% and assumes that source and receiver are not within the critical
% distance. A denoising is not performed by this function and has to be
% done in advance.

% Calling function for integration into AARAE by Densil Cabrera
% Version 1.00 (December 2013)

% if nargin ==1 % If the function is called within the AARAE environment it
%               % will have at least one input parameter which is the audio
%               % data structure that your function will process, therefore
%               % you can check that the user has input all input parameters
%               % if you want your function to work as standalone outside the
%               % AARAE environment. You can use this input dialog to request
%               % for the additional parameters that you require for your
%               % function to work if they're not part of the AARAE structure
% 
%     param = inputdlg({'Input 1';... % These are the input box titles in the
%                       'Input 2'},...% inputdlg window.
%                       'Window title',... % This is the dialog window title.
%                       [1 30],... % You can define the number of rows per
%                       ...        % input box and the number of character
%                       ...        % spaces that each box can display at once
%                       ...        % per row.
%                       {'2';'3'}); % And the preset answers for your dialog.
% 
%     param = str2num(char(param)); % Since inputs are usually numbers it's a
%                                   % good idea to turn strings into numbers.
% 
%     if length(param) < 2, param = []; end % You should check that the user 
%                                           % has input all the required
%                                           % fields.
%     if ~isempty(param) % If they have, you can then assign the dialog's
%                        % inputs to your function's input parameters.
%         input_1 = param(1);
%         input_2 = param(2);
%     end
% else
%     param = [];
% end

if isstruct(IN) % You should check that the function is being called within
                % the AARAE environment, if so, you can extract the
                % information you need to run your processor.
    audio = IN.audio; % Extract the audio data
    fs = IN.fs;       % Extract the sampling frequency of the audio data
elseif ~isempty(param) || nargin > 1
                       % If for example you want to enable your function to
                       % run as a standalone MATLAB function, you can use
                       % the IN input argument as an array of type double
                       % and assign it to the audio your function is going
                       % to process.
    audio = IN;
    fs = input_1;
end

% To make your function work as standalone you can check that the user has
% either entered at least an audio variable and it's sampling frequency.
if ~isempty(audio) && ~isempty(fs)
    
    
    simpar.fs = fs;
    simpar.block_size = round(20e-3 * simpar.fs);  % block length
    simpar.overlap = round(simpar.block_size/2);   % overlap
    
    [rt_est,rt_est_mean,rt_est_dbg] = ML_RT_estimation(audio(:,1,1)',simpar);
    
    rt_est_median = median(rt_est);
    
    
    
    
    % output table
    f = figure;
    t = uitable('Data',[rt_est_mean rt_est_median],...
                'ColumnName',{'Mean RT estimate (s)' 'Median RT estimate (s)'},...
                'RowName',{'Results'});
    disptables(f,t);
    
%--------------------------------------------------------------------------
% Plot estimated RT and 'true' RT obtained by Schroeder method
%--------------------------------------------------------------------------
fr2sec_idx = linspace(1,length(audio)/simpar.fs,length(rt_est));
figure('Name','Blind Reverberation Time Estimate')
clf
hold on
plot(fr2sec_idx,rt_est,'-r')
line([0 fr2sec_idx(end)],[rt_est_mean rt_est_mean])
line([0 fr2sec_idx(end)],[rt_est_median rt_est_median],'Color', [0,0.5,0])
grid on,box on
xlabel('Time [s]'),ylabel('RT [s]');
legend('Estimated T60',['Mean Estimate ',num2str(rt_est_mean), ' s'], ...
    ['Median Estimate ',num2str(rt_est_median), ' s'],'location','southeast');

%--------------------------------------------------------------------------

    

    if isstruct(IN)
        OUT.rt_est = rt_est; 
        OUT.rt_est_mean = rt_est_mean; 
        OUT.rt_est_dbg = rt_est_dbg;
    else
        % You may increase the functionality of your code by allowing the
        % output to be used as standalone and returning individual
        % arguments instead of a structure.
        OUT = rt_est;
    end
    varargout{1} = rt_est_mean;
    varargout{2} = rt_est_dbg;

% The processed audio data will be automatically displayed in AARAE's main
% window as long as your output contains audio stored either as a single
% variable: OUT = audio;, or it's stored in a structure along with any other
% parameters: OUT.audio = audio;
else
    % AARAE requires that in case that the user doesn't input enough
    % arguments to generate audio to output an empty variable.
    OUT = [];
end