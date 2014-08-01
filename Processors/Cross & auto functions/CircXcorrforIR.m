function OUT = CircXcorrforIR(IN, offset, combinehalves, d2stack, cycles, n)
% This function is used to analyse signals that were recorded using the IRS
% generator within AARAE, and other generators that have test signals
% designed for deriving an impulse response via circular cross-correlation.
% The output is an impulse response.
%
% Signals generated by AARAE's mls generator should NOT be analysed by this
% processor, but insted by MLS_process.
%
% Requirements for a test signal that can be analysed by this function
% include:
%   * The signal's autocorrelation function should be a delta function, or
%     a pair of delta functions with the second inverted;
%   * The signal must be repeated (without any gap) a number of times;
%   * Silence equal in length or longer than 1 cycle should be included in
%     the test signal (but this function has a work-around if that is not
%     done);
%   * One cycle of the time reversed signal must be in the audio2 field;
%   * The properties.cycles field should be used to state the number of
%     cycles used for the test signal (otherwise is estimated from the
%     length of the audio, which may lead to errors);
%
%
% SETTINGS
%   Offset: Provides a circlar shift in samples (default = 0).
%
%   combinehalves: An impulse response generated using IRS yields two
%   impulse responses, where the second is an inversion of the first. If
%   combinehalves == 1, then these two halves are combined (by
%   subtraction). Other test signals  might not benefit from combining
%   halves (and they may be degraded), and so this should not be done for
%   them.
%
%   IR stack in dimension 2 (if available): in AARAE, dimenson 2 is used
%   for channels, and if it is singleton, then multiple IRs can be stacked
%   in dimension 2 instead of in dimension 4. If d2stack == 1, then this
%   will be done; otherwise IRs are always stacked in dimension 4.
%   
% code by Densil Cabrera
% version 0 (1 August 2014)

if isstruct(IN)
    audio = IN.audio;
%     fs = IN.fs;
        if isfield(IN,'audio2')
            audio2 = IN.audio2;
            len2 = length(audio2);
        else
            disp('Audio2 is required for CircXcorrforIR to process with CircXcorrforIR')
            OUT = [];
            return
        end
    if isfield(IN,'properties')
        if isfield(IN.properties,'combinehalves')
            combinehalvesdefault = IN.properties.combinehalves;
        end
        if isfield(IN.properties,'cycles') 
            cycles = IN.properties.cycles;
        else
            % estimate cycles
            cycles = floor(size(audio,1)/len2)-1;
            % alternatively this could be done by linear cross-correlation
            % (to do)
            if cycles < 2
                disp('Unable to find enough cycles for CircXcorrforIR processing')
                OUT = [];
                return
            end
        end
    else
        disp('Required properties fields not found')
        OUT = [];
        return
    end
    OUT = IN;
else
    audio = IN;
end


% Dialog box parameters
if nargin ==1
    if ~exist('combinehalvesdefault','var')
        combinehalvesdefault = 0;
    end
    param = inputdlg({'Offset in samples';... 
        'Combine the two halves of the IR [0 | 1]';
        'IR stack in dimension 2 if available [0 | 1]'},...
        'IRS process settings',...
        [1 60],...
        {'0';num2str(combinehalvesdefault);'1'});
    param = str2num(char(param));
    if length(param) < 3, param = []; end
    if ~isempty(param)
        offset = param(1);
        combinehalves = param(2);
        d2stack = param(3);
    else
        OUT=[];
        return
    end
else
    param = [];
end

[len, chans, bands, dim4] = size(audio);

% Stack IRs in dimension 4 if AARAE's multi-cycle mode was used
if isfield(IN,'properties')
    if isfield(IN.properties,'startflag') && dim4==1
        startflag = IN.properties.startflag;
        dim4 = length(startflag);
        audiotemp = zeros((cycles+1)*(2^n-1),chans,bands,dim4);
        for d=1:dim4
            audiotemp(:,:,:,d) = ...
                audio(startflag(d):startflag(d)+(cycles+1)*(2^n-1)-1,:,:);
        end
    end
end

if exist('audiotemp','var')
    audio = audiotemp;
end

if d2stack == 1 && chans == 1 && dim4 > 1
    audio = permute(audio,[1,4,3,2]);
    chans = dim4;
    dim4 = 1;
end

% apply offset
audio = circshift(audio,offset);


% join first and last cycle (for circular convolution)
endindextail = len2 * (cycles+1);
startindextail = 1 + endindextail - len2;
if endindextail <= len 
    audio(startindextail:endindextail,:,:,:) = ...
        audio(startindextail:endindextail,:,:,:) +...
        audio(1:len2,:,:,:);
elseif cycles > 2
    % remove 1 cycle because audio is too short
    cycles = cycles-1;
else
    % zero pad end (not a great solution)
    audio = [audio;zeros(len,chans,bands,dim4)];
end

invfiltspect = repmat(fft(audio2),[1,chans,bands,dim4]);
ir = zeros(len2,chans,bands,dim4);
cyclecount = 0;
for n = 2:cycles
    endindex = len2 * n;
    startindex = 1 + endindex - len2;
    if startindex >= 1 && endindex <= len
        ir = ir + (ifft(fft(audio(startindex:endindex,:,:,:)) ...
            .* invfiltspect));
        cyclecount = cyclecount+1;
    end
end
if cyclecount > 1
    ir = ir ./ cyclecount;
elseif cyclecount == 0
    disp('audio recording is too short for CircXcorrforIR')
    OUT = [];
    return
end

ir=circshift(ir,1);

if combinehalves == 1
    ir(1:end/2,:,:,:) = ir(1:end/2,:,:,:) - ir(end/2+1:end,:,:,:);
    ir = ir(1:end/2,:,:,:);
end

if isstruct(IN)
    OUT.audio = ir;
    OUT.funcallback.name = 'CircXcorrforIR.m';
    OUT.funcallback.inarg = {offset, combinehalves, d2stack, cycles, n};
else
    OUT = ir;
end