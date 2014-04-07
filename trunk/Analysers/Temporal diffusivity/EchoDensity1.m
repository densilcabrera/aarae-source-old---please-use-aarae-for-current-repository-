function [OUT,varargout] = EchoDensity1(IN, WindowTime, OffsetTime, DoWindow, fs)
% This function calculates some indicators of echo density for room
% impulse responses. These are calculated in individual time windows (e.g.
% 20 ms windows) over the course of the impulse response.
%
% Indicators are:
% Standard deviation of the waveform in each window;
% Kurtosis of the waveform in each window; and
% Normalized Echo Density, based on:
%  J.S. Abel & P. Huang
%  "A simple, robust measure of reverberation echo density,"
%  121st Audio Engineering Society Convention, San Francisco USA, 2006.
%
% Code by David Spargo and Densil Cabrera
% Version 0.00 (13 January 2014) - needs more work!

if nargin == 1
    param = inputdlg({'Duration of window (ms)';...
        'Hop between windows (ms)';...
        'Rectangular window [0] or Hann window [1]'},...
        'Settings',...
        [1 30],...
        {'20';'1';'1'}); % Default values
    
    param = str2num(char(param));
    
    if length(param) < 3, param = []; end
    if ~isempty(param)
        WindowTime = param(1);
        OffsetTime = param(2);
        DoWindow = param(3);
    else
        OUT = [];
        return
    end
end
if isstruct(IN)
    data = IN.audio; % Extract the audio data
    fs = IN.fs;       % Extract the sampling frequency of the audio data
    if isfield(IN,'bandID')
        bandID = IN.bandID;
    end
    if isfield(IN,'chanID')
        chanID = IN.chanID;
    end
else
    data = IN;
    if ~exist('fs','var')
        fs = inputdlg({'Sampling frequency [samples/s]'},...
            'Fs',1,{'48000'});
        fs = str2double(char(fs));
    end
    if ~exist('DoWindow','var')
        DoWindow = 1;
    end
    if ~exist('OffsetTime','var')
        OffsetTime = 1;
    end
    if ~exist('WindowTime','var')
        WindowTime = 20;
    end
end

if ~isempty(data) && ~isempty(fs) %&& ~isempty(WindowTime) && ~isempty(OffsetTime)
    WindowLength = round((WindowTime*fs)/1000);    % Size of the window in samples
    Offset = (OffsetTime*fs)/1000;  % Size of the window offset in samples
    if DoWindow == 1
        w = hann(WindowLength); % Hann window
        w2 = w/sum(w);  % normalized
    else
        w2 =ones(WindowLength,1) ./ WindowLength; % Rectangular window
    end
    
    [len,chans,bands] = size(data);
    
    nwin = round((len-WindowLength)/Offset); % number of windows
    
    % preallocate
    [SD, Kurt, ED] = ...
        deal(zeros(nwin,chans,bands));
    
    
    for n = 1:nwin;
        start = round((n-1)*Offset + 1);
        finish = start + WindowLength - 1;
        
        truncdata = data(start:finish,:,:);
        windata = truncdata.*repmat(w2,[1,chans,bands]);
        
        % standard deviation of each window
        SD(n,:,:) = std(windata);
        
        % kurtosis of each window
        Kurt(n,:,:) = kurtosis(windata,0);
        
        % normalized echo density of each window
        % Abel & Huang equations 3 and 4
        for ch = 1:chans
            for b = 1:bands
                ED(n,ch,b) = ...
                    sum(w2.*(abs(truncdata(:,ch,b)> ...
                    (sum(w2.*truncdata(:,ch,b).^2)).^0.5)))...
                    ./erfc(1/sqrt(2));
            end
        end
    end
    
    IRt_vec = 0.001*(OffsetTime*((1:nwin)-1)...
        +0.5*WindowTime); % window times
   
    
    SDn = SD./repmat(max(SD),[nwin,1,1]); % normalise to 1
    EDn = ED./repmat(max(ED),[nwin,1,1]); % normalise to 1
    Kurtn = Kurt./repmat(max(Kurt),[nwin,1,1]); % normalise to 1
    
    for ch = 1:chans
        if exist('chanID','var')
            chanstring = char(chanID(ch));
        else
            chanstring = ['ch ',num2str(ch)];
        end
        for b = 1:bands
            
            if bands > 1
                if exist('bandID','var')
                    figure('Name', ['Echo Density Indicators', chanstring,', ',...
                        num2str(bandID(b))])
                else
                    figure('Name', ['Echo Density Indicators', chanstring,', ',num2str(b)])
                end
            else
                figure('Name', ['Echo Density Indicators', chanstring])
            end
            
            plot((0:len-1)./fs,abs(data(:,ch,b))./max(abs(data(:,ch,b))),...
                'Color',[0.6 0.6 0.6],'DisplayName','Rectified waveform')
            hold on
            
            plot(IRt_vec,SDn(:,ch,b),'r','DisplayName','Standard Deviation')
            plot(IRt_vec,EDn(:,ch,b),'b','DisplayName','Echo Density')
            plot(IRt_vec,Kurtn(:,ch,b),'Color',[0,0.5,0],...
                'DisplayName','Kurtosis')
            xlabel('Time (s)')
            ylabel('Normalized values')
            legend('show','Location','EastOutside');
        end
    end
    
    if isstruct(IN)
        
        OUT.EDn = EDn;
        OUT.SDn = SDn;
        OUT.Kurtn = Kurtn;
        OUT.funcallback.name = 'EchoDensity1.m';
        OUT.funcallback.inarg = {WindowTime,OffsetTime,DoWindow};
    else
        OUT = EDn;
    end
    varargout{1} = SDn;
    varargout{2} = Kurtn;
    
else
    % AARAE requires that in case that the user doesn't input enough
    % arguments to generate audio to output an empty variable.
    OUT = [];
end

%**************************************************************************
% Copyright (c) 2013-2014, David Spargo & Densil Cabrera
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