function [OUT, varargout] = spect_moments(IN)
% SPECT_MOMENTS calculates the statistical spectral moments from a signal's
% spectrum.
% m = spect_moments(x, fs) calculates the first 4 spectral moments:
% centroid / bandwidth (variance) / skewness / kurtosis
% FFT is used as the method of calculation 
% Inputs:
% x - one/two channels signal
% fs - sampling frequency
% Outputs:
% 1st moment - centroid | derived from the frequency-weighted mean of the 
% critical band distribution, associated with ?brightness?. 
% 2nd moment - bandwidth | derived from the dispersion centred at the 
% spectral centroid, how wide or narrow the spectrum is. 
% 3rd moment - skewness | a measure of asymmetry in the distribution.
% 4th moment - kurtosis | a measure of the width of the peaks in the 
% distribution (?peakedness?). 

% *************************************************************************
if isstruct(IN) % You should check that the function is being called within
                % the AARAE environment, if so, you can extract the
                % information you need to run your processor.
    audio = IN.audio; % Extract the audio data
    fs = IN.fs;       % Extract the sampling frequency of the audio data
    
    
    % The following field values might not be needed for your anlyser, but
    % in some cases they are (delete if not needed). Bear in mind that
    % these fields might not be present in the input structure, and so a
    % way of dealing with missing field values might be needed. Options
    % include: using default values, asking for user input via a dialog
    % box, analysing the sound to derive values (probably impractical), and
    % exiting from the function
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
    
%     % chanID is a cell array of strings describing each channel
    if isfield(IN,'chanID') % Get the channel ID if it exists
        chanID = IN.chanID;
    end
%     
%     % bandID is a vector, usually listing the centre frequencies of the
%     % bands
%     if isfield(IN,'bandID') % Get the band ID if it exists
%         bandID = IN.bandID;
%     else
%         % asssign ordinal band numbers if bandID does not exist (as an
%         % example of how to deal with missing data)
%         bandID = 1:size(audio,3);
%     end
    
% *************************************************************************    
    
% To make your function work as standalone you can check that the user has
% either entered at least an audio variable and its sampling frequency, and
% potentially check for other required data.
% if ~isempty(audio) && ~isempty(fs) && ~isempty(cal)
    % If the requirements are met, your code can be executed!
    % You may copy and paste some code you've written:
    
if length(audio) ~= size(audio,1)
  audio = audio';
end

NFFT = 2 ^ nextpow2(length(audio));

chans = size(audio,2);

w = hamming(length(audio));
MXtmp = abs(fft(audio.*repmat(w,[1,chans]),NFFT));
NumUniquePts = ceil((NFFT+1)/2);
MXtmp = MXtmp(1:end/2,:);
MXtmp = (mean(MXtmp.^2,2)).^0.5; % power spectra of signal 

MXtmp = MXtmp / length(audio);
MXtmp = MXtmp .^ 2; % scale properly
MXtmp = MXtmp * 2;  % Account for throwing out second half of FFTX above
MXtmp(1) = MXtmp(1) / 2;                            % Account for DC uniqueness
if ~rem(NFFT,2)
  MXtmp(length(MXtmp)) = MXtmp(length(MXtmp)) / 2;  % Account for Nyquist uniqueness
end
c_freq = (1:NumUniquePts-1) * fs / NFFT;

f_n = c_freq;
x_n = MXtmp;

f_n = f_n';

centroid = sum(f_n .* x_n) ./ sum(x_n);
bandwidth = sum((f_n - centroid).^2 .* x_n) ./ sum(x_n);
bandwidth = sqrt(bandwidth);
skewness = sum((f_n - centroid).^3 .* x_n) ./ sum(x_n);
skewness = skewness / bandwidth.^3; 
kurtosis = sum((f_n - centroid).^4 .* x_n) ./ sum(x_n);
kurtosis = kurtosis /  bandwidth.^4;
    
    
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
    table1 = uitable('Data',[centroid bandwidth skewness kurtosis],...
                'ColumnName',{'Centroid','Bandwidth','Skewness','Kurtosis'},...
                'RowName',{'Results'});
    [~,tables] = disptables(fig1,table1);
    
    
    
    % And once you have your result, you should set it up in an output form
    % that AARAE can understand.
    if isstruct(IN)
        % OUT = IN; % You can replicate the input structure for your output
        % OUT.audio = audio; % And modify the fields you processed
        % However, for an analyser, you might not wish to output audio (in
        % which case the two lines above might not be wanted.
        %
        % Or simply output the fields you consider necessary after
        % processing the input audio data, AARAE will figure out what has
        % changed and complete the structure. But remember, it HAS TO BE a
        % structure if you're returning more than one field:
        
%         OUT.centroid = centroid;
%         OUT.bandwidth = bandwidth;
%         OUT.skewness = skewness;
%         OUT.kurtosis = kurtosis;
        OUT.tables = tables;
        % (Note that the above outputs might be considered to be redundant
        % if OUT.tables is used, as described above).
        
        % The following outputs are needed so that AARAE can repeat the
        % analysis without user interaction (e.g. for batch processing).
        OUT.funcallback.name = 'spect_moments.m'; % Provide AARAE
        % with the name of your function 
        OUT.funcallback.inarg = {}; 
        % assign all of the 
        % input parameters that could be used to call the function 
        % without dialog box to the output field param (as a cell
        % array) in order to allow batch analysing.
    %else
        % You may increase the functionality of your code by allowing the
        % output to be used as standalone and returning individual
        % arguments instead of a structure.
        % OUT = audio;
    end
    
% The processed audio data will be automatically displayed in AARAE's main
% window as long as your output contains audio stored either as a single
% variable: OUT = audio;, or it's stored in a structure along with any other
% parameters: OUT.audio = audio;
% else
    % AARAE requires that in case that the user doesn't input enough
    % arguments to generate audio to output an empty variable.
else
    OUT = [];
    varargout{1} = centroid;
    varargout{2} = bandwidth;
    varargout{3} = skewness;
    varargout{4} = kurtosis;
end

%**************************************************************************
% Copyright (c) <2014>, <Ella Manor ella.manor@sydney.edu.au>
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