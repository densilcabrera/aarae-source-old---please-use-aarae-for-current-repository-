function [OUT, varargout] = Monocycle_pulse(fs,T,edge,hifreq,lofreq,dispersion,wind,modF)
% This function generates a monocycle pulse.
%
% It calls a the function 'pulsegen' (by Philip, 2011). This function, and
% a visualisation tool, are in the Generators\Pulses\pulsegen directory of
% AARAE. The visualisation tool, pulsegen_vis, provides a very useful
% interface for exploring the range of pulses that can be generated by
% pulsegen.



if nargin == 0 % If the function is called within the AARAE environment it
               % won't have any input arguments, this is when the inputdlg
               % function becomes useful.

    param = inputdlg({'Audio sampling rate (Hz)';... % These are the input box titles in the
                      'Duration (s)' ;...
                      'Edge (>0)' ;...
                      'High cut-off frequency (Hz)';...
                      'Low cut-off frequency (Hz)'; ...
                      'Dispersion (-1:1)';...
                      'Window (0:1)';...
                      'Modulation (Hz)'},...% inputdlg window.
                      'Input parameters',... % This is the dialog window title.
                      [1 60],... % You can define the number of rows per
                      ...        % input box and the number of character
                      ...        % spaces that each box can display at once
                      ...        % per row.
                      {'48000';'1';'1';'24000';'0';'0';'0';'0'}); % And the preset answers for your dialog.

    param = str2num(char(param)); % Since inputs are usually numbers it's a
                                  % good idea to turn strings into numbers.

    if length(param) < 8, param = []; end % You should check that the user 
                                          % has input all the required
                                          % fields.
    if ~isempty(param) % If they have, you can then assign the dialog's
                       % inputs to your function's input parameters.
        fs = param(1);
        T = param(2);
        edge = param(3);
        hifreq = param(4);
        lofreq = param(5);
        dispersion = param(6);
        wind = param(7);
        modF = param(8);
    end

% To make your function work as standalone you can check that the user has
% either entered some parameters as inputs or that the inputs have been
% acquired through the input dialog window.
if ~isempty(param) || nargin ~= 0
    hif = hifreq/(0.5*fs);
    lof = lofreq/(0.5*fs);
    % call pulsegen
    audio=pulsegen(fs,T,edge,'monocycle','window',wind,'modulation',modF,'low_pass',hif,'high_pass',lof,'dispersion',dispersion);
    
    if nargin == 0
        OUT.audio = audio'; % You NEED to provide the audio you generated.
        %OUT.audio2 = ?;     You may provide additional audio derived from your function.
        OUT.fs = fs;       % You NEED to provide the sampling frequency of your audio.
        OUT.tag = 'MonocyclePulse';
        OUT.properties.T = T;
        OUT.properties.edge = edge;
        OUT.properties.hifreq = hifreq;
        OUT.properties.lofreq = lofreq;
        OUT.properties.dispersion = dispersion;
        OUT.properties.wind = wind;
        OUT.funcallback.name = 'Monocycle_pulse.m';
        OUT.funcallback.inarg = {fs,T,edge,hifreq,lofreq,dispersion,wind,modF};
    end
    
    % You may choose to increase the functionality of your code by allowing
    % it to operate outside the AARAE environment you may want to output
    % independent variables instead of a structure...
    if nargin ~= 0
        OUT = audio;
        varargout{1} = fs;
        
    end
else
    % AARAE requires that in case that the user doesn't input enough
    % arguments to generate audio to output an empty variable.
    OUT = [];
end

end % End of function