function [OUT, varargout] = trimmean_dim4(IN, domain, operation, percent,fs)
% This function reduces audio that is stacked in the 4th dimension to 3 (or
% less) dimensions using a variety of methods including:
% * just use the top layer
% * mean of dimension 4
% * trim-mean of dimension 4
% * median of dimension 4
%
% These operations can be done in the time domain, frequency domain or
% quefrency domain.

if nargin ==1 
    
    param = inputdlg({'Domain: time [0], frequency [1], quefrency [2]';... 
        'Top layer [0], Mean [1], Trim-mean [2], Median [3]';...
        'Trim-mean percent [0:100]'},...
        'Window title',... 
        [1 60],... 
        {'0';'2';'50'}); 
    
    param = str2num(char(param)); 
    
    if length(param) < 3, param = []; end 
    if ~isempty(param) 
        domain = param(1);
        operation = param(2);
        percent = param(3);
    end
else
    param = [];
end
if isstruct(IN) 
    audio = IN.audio; % Extract the audio data
    fs = IN.fs;       % Extract the sampling frequency of the audio data
    

elseif ~isempty(param) || nargin > 1   
    audio = IN;
end

if ~isempty(audio) && ~isempty(fs)
    [~,chans,bands,stacksize] = size(audio);

if operation == 0
    % take only the first layer of the stack - discard the rest.
    % no need to consider domains in this case
    audio = audio(:,:,:,1);
else
    
    % Transfrom to appropriate domain if necessary
    if domain == 1
        % frequency domain
        audio = fft(audio);
    elseif domain == 2
        % quefrency domain
        for ch = 1:chans
            for b = 1:bands
                for s = 1:stacksize
                    audio = cceps(audio(:,ch,b,s));
                end
            end
        end
        % otherwise time domain
    end
    
    if operation == 1
        % average the stack
        audio = mean(audio,4);
    elseif operation == 2
        % trimmean
        audio = trimmean(audio,percent,'weighted',4);
    elseif operation == 3
        % median
        audio = median(audio,4);
    end
    
    % Go back to time domain if necessary
    if domain == 1
        % frequency domain
        audio = ifft(audio);
    elseif domain == 2
        % quefrency domain
        for ch = 1:chans
            for b = 1:bands
                for s = 1:stacksize
                    audio = icceps(audio(:,ch,b,s));
                end
            end
        end
        % otherwise time domain
    end
end
    
    if isstruct(IN)
        OUT = IN; 
        OUT.audio = audio; 
    else
        
        OUT = audio;
    end
    varargout{1} = fs;
    
else
    
    OUT = [];
end

