function OUT = Aweight(IN,fs)
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
        %if isdir([cd '/Processors/Filters/' num2str(fs) 'Hz'])
        if false % bypass this code for now
            content = load([cd '/Processors/Filters/' num2str(fs) 'Hz/A-WeightingFilter.mat']);
            filterbank = content.filterbank;
            processed = filter(filterbank,1,audio);
        
    else
        WT    = 'A';    % Weighting type
        Class = 1;      % Class
        h = fdesign.audioweighting('WT,Class', WT, Class, fs);
        Hd = design(h, 'ansis142', ...
       'SOSScaleNorm', 'Linf');
        processed = filter(Hd,audio);
    end
    if isstruct(IN)
        OUT = IN;
        OUT.audio = processed;
    else
        OUT = processed;
    end
end