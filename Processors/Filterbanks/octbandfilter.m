function [OUT,varargout] = octbandfilter(IN,fs,param,method)
% method: 1 normal filtering
%         0 filter forwards & backwards (time reversed), linear phase
%        -1 filter time reversed
        if nargin < 4, method = 1; end
        B = 1;
        N = 6;
        ok = 0;
        nominalfreq = [31.5,63,125,250,500,1000,2000,4000,8000,16000];
        if nargin < 3
            param = nominalfreq;
            [S,ok] = listdlg('Name','Octave band filter input parameters',...
                                     'PromptString','Center frequencies [Hz]',...
                                     'ListString',[num2str(param') repmat(' Hz',length(param),1)]);
            param = param(S);
        else
            S = zeros(size(param));
            for i = 1:length(param)
                check = find(nominalfreq == param(i));
                if isempty(check), check = 0; end
                S(i) = check;
            end
            if all(S), param = sort(param,'ascend'); ok = 1; else ok = 0; end;
        end
        if isstruct(IN)
            audio = IN.audio;
            fs = IN.fs;
        elseif ~isempty(param)
            audio = IN;
            if nargin < 2
                fs = inputdlg({'Sampling frequency [samples/s]'},...
                                   'Fs',1,{'48000'});
                fs = str2num(char(fs));
            end
        end
    if ~isempty(param) && ~isempty(fs)
        if fs <= 44100, param = param(param<adjustF0(16000)); end
        if ok == 1 && isdir([cd '/Processors/Filterbanks/' num2str(fs) 'Hz'])
            content = load([cd '/Processors/Filterbanks/' num2str(fs) 'Hz/OctaveBandFilterBank.mat']);
            filterbank = content.filterbank;
            centerf = zeros(size(param));
            filtered = zeros(size(audio,1),size(audio,2),length(param));
            for i = 1:length(param)
                for j = 1:size(audio,2)
                    centerf(i) = param(1,i);
                    switch method
                        case -1
                            % reverse time filter
                            filtered(:,j,i) = ...
                                flipud(filter(filterbank(1,S(1,i)),flipud(audio(:,j))));
                        case 0
                            % double filter reverse & normal time
                            filtered(:,j,i) = ...
                                filter(filterbank(1,S(1,i)),flipud(filter(filterbank(1,S(1,i)),flipud(audio(:,j)))));
                        otherwise
                            % normal filter
                            filtered(:,j,i) = filter(filterbank(1,S(1,i)),audio(:,j));
                    end
                end
            end
        else
            F0 = param;
            centerf = zeros(size(param));
            filtered = zeros(size(audio,1),size(audio,2),length(param));
            for i = 1:length(param)
                for j = 1:size(audio,2)
                    centerf(i) = param(1,i);
                    filterbank = octband(B, N, adjustF0(F0(i)), fs);
                    switch method
                        case -1
                            % reverse time filter
                            filtered(:,j,i) = flipud(filter(filterbank,flipud(audio(:,j))));
                        case 0
                            % double filter
                            filtered(:,j,i) = ...
                            filter(filterbank,flipud(filter(filterbank,flipud(audio(:,j)))));
                        otherwise
                            % normal filter
                            filtered(:,j,i) = filter(filterbank,audio(:,j));
                    end
                end
            end 
        end
    else
        filtered = [];
        centerf = [];
    end
    if isstruct(IN) && ~isempty(filtered)
        OUT = IN;
        OUT.audio = filtered;
        OUT.bandID = centerf;
        OUT.funcallback.name = 'octbandfilter.m';
        OUT.funcallback.inarg = {fs,param,method};
    else
        OUT = filtered;
    end
    varargout{1} = centerf;
end


function Hd = octband(B, N, F0, Fs)
%OCTBANDFILTER Returns a discrete-time filter object.

%
% MATLAB Code
% Generated by MATLAB(R) 7.11 and the Signal Processing Toolbox 6.14.
%
% Generated on: 25-Jul-2013 17:48:28
%
% Default parameters
%B  = 1;      % Bands per octave
%N  = 6;      % Order
%F0 = 1000;   % Center frequency
%Fs = 48000;  % Sampling Frequency

h = fdesign.octave(B, 'Class 0', 'N,F0', N, F0, Fs);

Hd = design(h, 'butter', ...
    'SOSScaleNorm', 'Linf');


end

function validf = adjustF0(f0)
% Modified from:

%GETVALIDCENTERFREQUENCIES   Get the validcenterfrequencies.

%   Author(s): V. Pellissier
%   Copyright 2006 The MathWorks, Inc.
%   $Revision: 1.1.6.1 $  $Date: 2006/10/18 03:26:31 $

% and

%VALIDATE   Validate the specs

%   Author(s): V. Pellissier
%   Copyright 2006 The MathWorks, Inc.
%   $Revision: 1.1.6.2 $  $Date: 2006/11/19 21:45:20 $

b = 1; % BandsPerOctave
G = 10^(3/10);
x = -100:135;
if rem(b,2)
    % b odd
    validcenterfrequencies = 1000*(G.^((x-30)/b));
else
    validcenterfrequencies = 1000*(G.^((2*x-59)/(2*b)));
end
validcenterfrequencies(validcenterfrequencies>20000)=[]; % Upper limit 20 kHz
validcenterfrequencies(validcenterfrequencies<20)=[];    % Lower limit 20 Hz

validFreq = validcenterfrequencies;
if isempty(find(f0 == validFreq, 1)),
    [~, idx] = min(abs(f0-validFreq));
    validf = validFreq(idx);
else
    validf = f0;
end
end
% [EOF]