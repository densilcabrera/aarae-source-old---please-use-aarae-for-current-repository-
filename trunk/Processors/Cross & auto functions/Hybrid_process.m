function [OUT, varargout] = Hybrid_process(IN, fs, audio2)
% This function is used to analyse signals that were recorded using the
% Hybrid generator within AARAE. The output is an impulse response.
%
% Code by Densil Cabrera
% Version 0 (beta) (11 May 2014)

if nargin == 1 
    
    param = inputdlg({'Mean [0], Trimmean [0<x<1], Median [1], Minimum [2], Maximum [3], or Stack in dimension 4 [4]';...
        'Time domain [0] or Frequency domain [1]'},...
        'Combination method',... 
        [1 60],... 
        {'0';'0'}); 
    
    param = str2num(char(param)); 
    
    if length(param) < 2, param = []; end 
    if ~isempty(param) 
        method = param(1);
        domain = param(2);
    end
else
    param = [];
end

if isfield(IN,'funcallback') && strcmp(IN.funcallback.name,'hybrid_test_signal.m')
    if isstruct(IN)
        audioin = IN.audio;
        
        fs = IN.fs;
        if isfield(IN,'audio2')
            audio2in = IN.audio2;
        else
            disp('Audio2 not found')
            OUT = [];
            return
        end
        
        
    elseif ~isempty(param) || nargin > 1
        
        audioin = IN;
        audio2in = audio2;
    end
    
    
    if ~isempty(audioin) && ~isempty(fs) && ~isempty(audio2in)
        
        signallist = [ones(1,IN.properties.signals(1)),...
            2*ones(1,IN.properties.signals(2)),...
            3*ones(1,IN.properties.signals(3)),...
            4*ones(1,IN.properties.signals(4)),...
            5*ones(1,IN.properties.signals(5))];
        
        outlen = ceil(max(diff(IN.properties.hybridindex))./2);
        
        for n = 1:sum(IN.properties.signals)
            audio = audioin(IN.properties.hybridindex(n)...
                :IN.properties.hybridindex(n+1)-1,:,:);
            audio2 = audio2in(IN.properties.hybridindex2(n)...
                :IN.properties.hybridindex2(n+1)-1,:,:);
            
            [len,chans,bands] = size(audio);
            
            
            
            if signallist(n) ~= 5
                % convolution of audio with audio2
                fftlen = len + length(audio2);
                ir = ifft(fft(audio,fftlen)...
                    .* repmat(fft(audio2,fftlen),[1,chans,bands]));
                ir = ir(floor(length(audio2)):end);
                
%                 figure
%                 plot(10*log10(ir.^2),'Color',rand(1,3));
%                 hold on
                
            else
                % Golay processing
                % find the relevent indices from audio2 - the original test signal
                lasta = find(audio2 == 0,1,'first')-1;
                firstb = find(audio2(lasta+1:end) ~= 0,1,'first')+lasta;
                lastb = length(audio2);
                
                if len < lastb
                    disp('Recorded audio is too short for Golay processing')
                    disp('It must be at least the same duration as the test signal')
                    OUT = [];
                    return
                end
                
                if ~isempty(lasta) && ~isempty(firstb)
                    a = audio2(1:lasta);
                    b = audio2(firstb:end);
                else
                    disp('Audio 2 is not in the required format')
                    disp('This function should be used with test signals that were generated by the ''Golay'' generator in AARAE')
                    OUT = [];
                    return
                end
                
                if length(a) ~= length(b)
                    disp('Audio 2 is not in the required format')
                    disp('This function should be used with test signals that were generated by the ''Golay'' generator in AARAE')
                    OUT = [];
                    return
                end
                
                aa = audio(1:lasta,:,:);
                bb = audio(firstb:lastb,:,:);
                
                
                % cross-spectrum, sum and scale
                ir = ifft(repmat(conj(fft(a)),[1,chans,bands]) .* fft(aa) ...
                    + repmat(conj(fft(b)),[1,chans,bands]) .* fft(bb)) ...
                    ./ (2*lasta);
                
                
            end
            
            
            if length(ir)>outlen
                    ir = ir(1:outlen);
            elseif length(ir)<outlen
                ir = [ir;zeros(outlen-length(ir),1)];
            end
            
            IRset(:,:,:,n) = ir;
        end
        
        % Normalize
        for n = 1:sum(IN.properties.signals)
            IRset(:,:,:,n) = IRset(:,:,:,n)./ ...
                max(max(max(IRset(:,:,:,n),[],3),[],2),[],1);
        end
        
%         figure('Name','Hybrid test signal impulse response')
%         t = (1:size(IRset,1))-1 ./fs;
        
        
        
        if domain == 1
            IRset = fft(IRset,size(IRset*2,1));
        end
        
        if method == 0
            IRset = mean(IRset,4);
        elseif (method > 0) && (method < 1)
            IRset = trimmean(IRset, 100*method, 'round', 4);
        elseif method == 1
            IRset = median(IRset, 4);
        elseif method == 2
            [~,ind] = min(abs(IRset), [], 4);
            IRset = IRset(ind); % THIS IS WRONG - NEED TO FIX!
        elseif method == 3
            [~,ind] = max(abs(IRset),[], 4);
            IRset = IRset(ind); % THIS IS WRONG - NEED TO FIX!
        end
        
        if domain == 1
            IRset = ifft(IRset,size(IRset*2,1));
        end
        
        
 
        
        
        
        
        if isstruct(IN)
            OUT = IN;
            OUT.audio = IRset;
            OUT.funcallback.name = 'Hybrid_process.m';
            OUT.funcallback.inarg = {};
        else
            OUT = IRset;
        end
        varargout{1} = fs;
    else
        OUT = [];
    end
else
    OUT = [];
    warndlg('The audio to be processed was not recorded from a signal generated using the Golay generator within AARAE.','AARAE info')
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