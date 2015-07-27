function X = workflow_example1(X)
% This function requires a recording of a swept sinusoid (with its inverse
% filter in the audio2 field), and calculates reverberation time and STI
% (with particular input parameters) from this.
%
% This is an example of how a processing and analysis workflow can be written,
% by adapting code that was written to AARAE's log file.
%
% Many of the operations that are done in AARAE are automatically
% documented in the log file for the session, and operations that can be done
% equivalently with simple function calls are written as such (without a %
% comment symbol at the start of the line).
%
% You can use these function calls in a workflow function (which this is an
% example of). That way, a sequence of operations that might involve
% tedious data entry can become streamlined into a single quick operation.
%
% An AARAE workflow function (like this function) is stored in the
% Workflows directory. To run it from the AARAE GUI, use the processor
% called AARAE_workflow_processor, which is in the Processors/Basic
% directory. 
%
% You should give your function an intuitively understandable name, because
% this is what you will see when you browse the Workflows folder. The file
% name and function name must be identical.
%
% An obvious alternative to writing a workflow function is to write your
% own AARAE function and place it within a sub-directory of the Processors
% or Analysers directories. The advantage of that is that it is accessed in
% exactly the same way as any other AARAE analyser or processor. Perhaps
% there are disadvantages to that, such as a build-up of clutter in the
% AARAE Analysers or Processors directories, and potential confusion
% between types of functions - so you need to decide what works best for
% you. The AARAE workflow functions have the advantage of being in an
% obvious and easily accessed directory, and a small amount of
% infrastructure that makes them behave more flexibly than processors or
% analysers.
%
% In this example, it is assumed that the user has generated a sweep test
% signal (e.g. the exponential sweep with default settings), and then has
% used this sweep in one or more sound recordings. The following
% work-flow processes the recording(s), as commented below.

% LOGGING DIRECTLY FROM THIS FUNCTION
% Log file information is automatically written from the output of the
% aarae_workflow_processor function, but you may wish to write additional
% information from within this function (especially if your workflow
% involves several AARAE function calls). The simplest way of doing this is
% to use the AARAE utility logtext, which takes a string as its input
% argument.
logtext('%% This is a test of using fprintf to write to AARAE''s log file.\n');

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
% Let's check if our input is suitable - it must have an audio2 field or we
% can't run this workflow. If there is no audio2 field, then return an
% empty output and abandon the workflow.
if ~isfield(X,'audio2')
    X = [];
    logtext('%% Selected audio does not have an audio2 field, and so it cannot be processed by workflow example 1');
    return
end

% The following is code adapted from AARAE's log file (as an example)

% The assumption is that we have a swept sinusoid measurement, of several
% seconds' duration. Now we derive the impulse response. The following is
% exactly the same as the code written in the log file.
X = convolveaudiowithaudio2(X,1);

% Let's truncate the audio (get rid of the first half, and make it 2 s
% long. The following try-catch avoids an error if the impulse response is
% not long enough for this operation. X.fs is the audio sampling rate of
% the AARAE stucture X.
try
    X.audio = X.audio(round(end/2):round(end/2)+2*X.fs,:,:,:,:,:);
catch
    X.audio = X.audio(round(end/2):end,:,:,:,:,:);
end

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
fprintf(handles.fid,['Speech spectrum: ',num2str(speech),' dB \n']);
fprintf(handles.fid,['Noise spectrum: ',num2str(noise),' dB \n']);
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

% If you do not wish any figures to be preserved (e.g., if you are only
% interested in the values output in the log file), you can get rid of all
% the figures before they are saved by calling the AARAE utility function
% closefigures
% Use no input argument to close all figures.
% closefigures('T')
% Use an input argument of 'T' to only close tables.
% closefigures('C')
% Use an input argiment of 'C' to only close non-tables (charts)

end