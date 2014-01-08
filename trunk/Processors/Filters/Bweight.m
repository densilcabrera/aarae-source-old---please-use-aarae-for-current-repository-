function OUT = Bweight(IN,fs)
processed = [];
if nargin < 2
    if isstruct(IN)
        audio = IN.audio;
        fs = IN.fs;
    else
        audio = IN;
        fs = inputdlg({'Sampling frequency [samples/s]'},...
                           'Fs',1,{'48000'});
        fs = str2num(char(fs));
    end
end
    if ~isempty(audio) && ~isempty(fs)
        if isdir([cd '/Processors/Weighting/' num2str(fs) 'Hz'])
            content = load([cd '/Processors/Weighting/' num2str(fs) 'Hz/B-WeightingFilter.mat']);
            filterbank = content.filterbank;
            processed = filter(filterbank,1,audio);
        end
    else
        % Insert alternative code for weighting filters
    end
    if isstruct(IN)
        OUT = IN;
        OUT.audio = processed;
    else
        OUT = processed;
    end
end