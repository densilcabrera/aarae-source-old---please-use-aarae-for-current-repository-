function X = workflow_example3(X)
% This is an example of how an analysis workflow can be written,
% by adapting code that was written to AARAE's log file.
%
% In this example, it is assumed that the user has generated a room impulse
% response (or more than one). They are interested in calculating
% reverberation time and STI using particular settings. The following
% work-flow processes the room impulse response(s), as commented below.

% LOGGING DIRECTLY FROM THIS FUNCTION
% Log file information is automatically written from the output of the
% aarae_workflow_processor function, but you may wish to write additional
% information from within this function (especially if your workflow
% involves several AARAE function calls). The simplest way of doing this is
% to use the AARAE utility logtext, which takes a string as its input
% argument.
logtext('%% Let''s see if this works!.\n');


% USING AARAE's LOGAUDIOLEAFFIELDS FUNCTION
% AARAE's logaudioleaffields is the function that is used in the AARAE
% framework code to log the outputs (and inputs, represented by callback
% values) of AARAE Calculators, Generators, Processors and Analysers. As
% such, it is called after the aarae_workflow_processor has returned an
% output, but it could also be called within this function to log
% intermediate steps.
%             logaudioleaffields(X,callbackaudioin);
% X is the AARAE structure (the output of an AARAE Calculator,
% Generator, Processor or Analyser). callbackaudioin specifies whether the
% input to the function includes an audio input (or not). This is used for
% correctly writing the executable function calls that appear in the log
% file. Generators and Calculators do not have audio input
% (callbackaudioin=0), whereas Procesors and Analysers do
% (callbackaudioin=1). If you wish to use logaudioleaffields, then call it
% immediately after the function that you are interested in logging.

% *************************************************************************
% The following is code adapted from AARAE's log file (as an example)



% Now calculate reverberation time - here we could use custom settings if
% we wanted to. Note that analysers usually remove the audio field from the
% AARAE structure, and so if we are doing more than one analysis we will
% need to preserve the audio field. This is done below by using Y as
% the output (so that X is preserved).
Y = ReverberationTime_IR1(X,48000,-20,1,1,1,0,0,0,125,8000);
% logaudioleaffields(Y,1); % this is how you would call logaudioleaffields
% here

% Now calculate STI for particular speech and noise octave band levels
% Specify the values:
speech = [55         52.9         49.2         43.2         37.2         31.2         25.2];
noise = [30  25  20  15  10  8  5];
% Log the values that you are interested in:
logtext(['Speech spectrum: ',num2str(speech),' dB \n']);
logtext(['Noise spectrum: ',num2str(noise),' dB \n']);
% Run the analysis
X = STI_IR(X,48000,speech,noise,2011,1,1,2,1,0);

% Note that analysers often write a 'tables' field (containing result
% tables). If we wish to preserve these in multiple analyses, then we will
% need to concatenate the tables.  
if isfield(Y,'tables')
    X.tables = [Y.tables X.tables];
end
% These concatenated tables will be written to the log file, and also will
% be available in the GUI.
% Note that if you return a tables field, then the audio field will be
% automatically deleted from the structure.

% Note that if you just want to get the figures generated by the analysers,
% you can return an empty output instead.
% X = [];
% If you wish to write tables data to the log file while returning an
% empty output to the AARAE workspace, then use logaudioleaffields (as
% described above) after each analysis.

% Many analysers generate figures, but if you do not want the figures to be
% preserved, you can call the closefigures utility within the workflow
% function. This closes the figures before AARAE automatically saves
% currently open figures.
% closefigures % close (and forget) all figures
% closefigures('C') % just close (and forget) charts
% closefigures('T') % just close table figures (tables data is still stored
% % in the log file and potentially as an output leaf)

end