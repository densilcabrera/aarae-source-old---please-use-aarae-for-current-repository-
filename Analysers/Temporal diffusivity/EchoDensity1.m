function [OUT,varargout] = EchoDensity1(IN, fs, WindowTime, OffsetTime)
% This function calculates various indicators of echo density for room
% impulse responses.
%
% Code by David Spargo and Densil Cabrera
% Version 0.00 (13 January 2014) - needs more work!

if nargin < 3
    param = inputdlg({'Duration of window (ms)';... 
                      'Hop between windows (ms)'},...
                      'Settings',... 
                      [1 30],... 
                      {'20';'5'}); % Default values

    param = str2num(char(param)); 

    if length(param) < 2, param = []; end 
    if ~isempty(param) 
        WindowTime = param(1);
        OffsetTime = param(2);
    else
        OUT = [];
        return
    end
end
if isstruct(IN) 
    data = IN.audio; % Extract the audio data
    fs = IN.fs;       % Extract the sampling frequency of the audio data
else                     
    data = IN;
    if nargin < 2
        fs = inputdlg({'Sampling frequency [samples/s]'},...
                           'Fs',1,{'48000'});
        fs = str2num(char(fs));
    end
end

if ~isempty(data) && ~isempty(fs) && ~isempty(WindowTime) && ~isempty(OffsetTime)
    WindowLength = round((WindowTime*fs)/1000);    % Size of the window in samples
    Offset = (OffsetTime*fs)/1000;  % Size of the window offset in samples
    w = hann(WindowLength); % Hann window
    w2 = w/sum(w);  % normalized

    [ED, IndFunc, Kurt, EDt_vec] = ...
        deal(zeros(round((length(data)-WindowLength)/Offset),1));
    %IndFunc = ED;
    %Kurt = ED;
    IRt_vec = zeros(length(data),1);
    %t_vec = 0.001*(1:length(data)) * OffsetTime;  % in ms in a row vector
    EDt_vec = ED;

    % 0.001*(1+(WindowTime/2):length(ED)+(WindowTime/2)) * OffsetTime;


    for n = 1:length(ED);
        start = round((n-1)*Offset + 1);
        finish = start + WindowLength - 1;

        % standard deviation of each window
        ED(n) = std(data(start:finish).*w);

        % normalized echo density of each window
        IndFunc(n)= sum(w2.*(abs(data(start:finish)>ED(n))))/erfc(1/sqrt(2));

        % kurtosis of each window
        Kurt(n) = kurtosis(data(start:finish).*w)-3;
        EDt_vec(n) = ((n-1)*(OffsetTime*0.001))+((WindowTime/2)*0.001);
    end

    IRt_vec = OffsetTime*(1:length(ED))/fs;


    EDn = ED.*(1/max(ED)); % normalise to 1
    IndFuncn = IndFunc.*(1/max(IndFunc)); % normalise to 1
    Kurtn = Kurt.*(1/max(Kurt)); % normalise to 1


    figure('Name', 'Echo Density Indicators')
    
    plot(IRt_vec,EDn,'r')
    hold on
    plot(IRt_vec,IndFuncn,'b')
    plot(IRt_vec,Kurtn,'k')
    
    if isstruct(IN)
        
        OUT.EDn = EDn; 
        OUT.IndFuncn = IndFuncn;
        OUT.Kurtn = Kurtn;
        OUT.funcallback.name = 'EchoDensity1.m';
        OUT.funcallback.inarg = {fs,WindowTime,OffsetTime};
    else
        % You may increase the functionality of your code by allowing the
        % output to be used as standalone and returning individual
        % arguments instead of a structure.
        OUT = audio;
    end
    varargout{1} = EDn;
    varargout{2} = IndFuncn;
    varargout{3} = Kurtn;
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