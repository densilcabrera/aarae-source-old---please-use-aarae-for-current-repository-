function X = workflow_example3(X)
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
% involves several AARAE function calls). If you wish to write directly to
% the log file, you will need the file identifier fid, which can be found
% from
handles = guidata(findobj('Tag','aarae'));
% the file identifier is handles.fid, which can be used, for example, as
% follows:
fprintf(handles.fid,['%% This is a test of using fprintf to write to the log file.','\n']);

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

% The assumption is that we have a swept sinusoid measurement, of several
% seconds' duration. Now we derive the impulse response. The following is
% exactly the same as the code written in the log file.
%X = convolveaudiowithaudio2(X,1);

% Let's truncate the audio (get rid of the first half, and make it 2 s
% long. The following try-catch avoids an error if the impulse response is
% not long enough for this operation. X.fs is the audio sampling rate of
% the AARAE stucture X.
% try
%     X.audio = X.audio(round(end/2):round(end/2)+2*X.fs,:,:,:,:,:);
% catch
%     X.audio = X.audio(round(end/2):end,:,:,:,:,:);
% end

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
% be available in the GUI if you don't return an audio field in the output.
% Note that if you return a tables field, then the audio field will be
% automatically deleted from the structure.

% Note that if you just want to get the figures generated by the analysers,
% you can return an empty output instead.
% X = [];
% If you wish to write tables data to the log file while returning an
% empty output to the AARAE workspace, then use logaudioleaffields (as
% described above) after each analysis.

closefigures('C')

end