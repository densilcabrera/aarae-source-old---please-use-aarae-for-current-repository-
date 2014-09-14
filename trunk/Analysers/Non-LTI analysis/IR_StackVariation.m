function OUT = IR_StackVariation(IN, autocropthresh, calval, scaling, domain, fs, cal)
% This function is designed to analyse an impulse response stack - either
% in dimension 4 or dimension 2. The purpose of such an analysis would
% probably be to assess time variance in a system.
%
% You can create an IR stack in the following steps:
% * Using AARAE's Generator GUI, choose measurement signal such as a swept
%   sinusoid, MLS or even an impulse (impuse1).
% * Before generating the signal, choose the number of cycles (>1), and
%   include a silent cycle if you wish to also assess background noise.
% * Generate the test signal
% * Play and record the test signal through the system
% * For signals such as swept sinusoids and the impulse1, create and IR
%   stack by using the '*' (convolve audio with audio2) button. If the
%   audio is single channel, you can choose to stack in dimension 2 or in
%   dimension 4; if the audio is multichannel you can only stack in
%   dimension 4.
% * For MLS signals and some others, you will need to use the appropriate
%   processor to derive an impulse response. Not all processors support the
%   generation of IR stacks.
%
% Currently this function outputs a results leaf (but no plot or table).
%
% Code by Densil Cabrera
% Version 0 beta (1 August 2014)



if nargin ==1 

    param = inputdlg({'Autocrop start threshold [-ve dB, or 0 to omit autocrop]';... 
                      'Reference calibration level [dB]';...
                      'Amplitude [1],Power [2],Level [3]';...
                      'Time domain wave [0] Time domain envelope [1] or Frequency domain [2]'},...
                      'IR stack variation analysis',... 
                      [1 30],... 
                      {'-20';'0';'1';'0'}); 

    param = str2num(char(param)); 

    if length(param) < 4, param = []; end 
    if ~isempty(param) 
        autocropthresh = param(1);
        calval = param(2);
        scaling = param(3);
        domain = param(4);
    else
        OUT=[];
        return
    end
else
    param = [];
end


% *************************************************************************
if isstruct(IN) 
    IN = choose_from_higher_dimensions(IN,4,1); 
    audio = IN.audio; % Extract the audio data
    fs = IN.fs;       % Extract the sampling frequency of the audio data
    
    if isfield(IN,'cal') % Get the calibration offset if it exists
        cal = IN.cal;
    else
        cal = 0;
    end
    
    % chanID is a cell array of strings describing each channel
    if isfield(IN,'chanID') % Get the channel ID if it exists
        chanID = IN.chanID;
    elseif size(audio,4) > 1
        chanID = {1:size(audio,2)};
    else
        chanID = {'chan 1'};
    end
    % in this analyser, dim2 might be being used for the IRstack, rather
    % than for channels - in which case it probably won't have a chanID
    
    % bandID is a vector, usually listing the centre frequencies of the
    % bands
    if isfield(IN,'bandID') % Get the band ID if it exists
        bandID = IN.bandID;
    else
        % asssign ordinal band numbers if bandID does not exist
        bandID = 1:size(audio,3);
    end
    

    % *********************************************************************
    
    
elseif ~isempty(param) || nargin > 1
                      
    audio = IN;
   
    fs = input_3;
    cal = input_4;
end
% *************************************************************************






if ~isempty(audio) && ~isempty(fs) && ~isempty(cal)

    [len,chans,bands,dim4] = size(audio);
    if dim4 > 1
        % assume IR stack is in dimension 4
        stackdim = 4;
    elseif chans > 1
        % assume IR stack is in dimension 2
        stackdim = 2;
    else
        disp('IR stack not found in dimensions 2 or 4 - unable to analyse')
        OUT = [];
        return
    end
    
    if exist('cal','var')
        % typically use calval of 0 dB, or 94 dB for Pa if appropriately calibrated
        audio = cal_reset_aarae(audio,calval,cal);
    end
    
    if autocropthresh ~=0
        audio = autocropstart_aarae(audio,autocropthresh,2);
        len = size(audio,1);
    end
    
    % frequency domain
    switch domain 
        case 2
            audio = abs(fft(audio));
            audio = audio(1:ceil(end/2),:,:,:);
            xval = fs * ((1:length(audio))-1)./len; % frequencies
            xstring = 'Frequency';
            xunit = 'Hz';
        case 1
            audio = abs(audio);
            xval = ((1:len)-1)./fs; % times
            xstring = 'Time';
            xunit = 's';
        otherwise
            xval = ((1:len)-1)./fs; % times
            xstring = 'Time';
            xunit = 's';
    end
    
    if scaling ~=1
        if scaling < 3
            audio = audio.^scaling;
        else
            audio = 10*log10(abs(audio).^2);
        end
    end
    
    % main calculations
    % written for quick editing of the values and their order (rather than
    % for optimised speed)
    Datastack = [];
    ValNames = {};
    
    val = mean(audio,stackdim);
    ValNames = [ValNames, 'mean'];
    if stackdim == 4
        Datastack = cat(4,Datastack,val);
    else
        Datastack = cat(2,Datastack,val);
    end
    
    val = std(audio,[],stackdim);
    ValNames = [ValNames, 'std'];
    if stackdim == 4
        Datastack = cat(4,Datastack,val);
    else
        Datastack = cat(2,Datastack,val);
    end

    
    val = skewness(audio,[],stackdim);
    ValNames = [ValNames, 'skewness'];
    if stackdim == 4
        Datastack = cat(4,Datastack,val);
    else
        Datastack = cat(2,Datastack,val);
    end

    
    val = kurtosis(audio,[],stackdim);
    ValNames = [ValNames, 'kurtosis'];
    if stackdim == 4
        Datastack = cat(4,Datastack,val);
    else
        Datastack = cat(2,Datastack,val);
    end    
    
    val = max(audio,[],stackdim);
    ValNames = [ValNames, 'max'];
    if stackdim == 4
        Datastack = cat(4,Datastack,val);
    else
        Datastack = cat(2,Datastack,val);
    end
    
    val = min(audio,[],stackdim);
    ValNames = [ValNames, 'min'];
    if stackdim == 4
        Datastack = cat(4,Datastack,val);
    else
        Datastack = cat(2,Datastack,val);
    end
          
    val = std(audio,[],stackdim)./mean(audio,stackdim);
    ValNames = [ValNames, 'coefvar'];
    if stackdim == 4
        Datastack = cat(4,Datastack,val);
    else
        Datastack = cat(2,Datastack,val);
    end
    
    val = rms(audio,stackdim);
    ValNames = [ValNames, 'rms'];
    if stackdim == 4
        Datastack = cat(4,Datastack,val);
    else
        Datastack = cat(2,Datastack,val);
    end    
    
    
    val = std(audio,[],stackdim)./rms(audio,stackdim);
    ValNames = [ValNames, 'stdonrms'];
    if stackdim == 4
        Datastack = cat(4,Datastack,val);
    else
        Datastack = cat(2,Datastack,val);
    end
    
    if stackdim == 4
        doresultleaf(Datastack, 'Value', {xstring},...
            xstring,        xval,       xunit,         true,...
            'channels',     chanID,     'categorical', [],...
            'bands',        num2cell(bandID), 'Hz',    false,...
            'statistic',    ValNames,      'categorical',        [],...
            'name','IR_Stack_Stats');
    else
        doresultleaf(Datastack, 'Value', {xstring},...
            xstring,        xval,       xunit,         true,...
            'statistic',    ValNames,      'categorical',        [],...
            'bands',        num2cell(bandID), 'Hz',    false,...
            'name','IR_Stack_Stats');
    end
    
   

    if isstruct(IN)
        
       
        OUT.funcallback.name = 'IR_StackVariation.m';
        OUT.funcallback.inarg = {autocropthresh, calval, scaling, domain, fs, cal}; 
       
    else
       
        OUT = Datastack;
    end

else
    
    OUT = [];
end

%**************************************************************************
% Copyright (c) 2014, Densil Cabrera
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
%  * Neither the name of the University of Sydney nor the names of its contributors
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