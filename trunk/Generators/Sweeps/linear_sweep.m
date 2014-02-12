% Generates a linear sweep and its inverse for IR measurement
%
function OUT = linear_sweep(dur,start_freq,end_freq,fs)


if nargin == 0
    param = inputdlg({'Duration [s]';...
                       'Start frequency [Hz]';...
                       'End frequency [Hz]';...
                       'Sampling Frequency [samples/s]'},...
                       'Sine sweep input parameters',1,{'10';'20';'24000';'48000'});
    param = str2num(char(param));
    if length(param) < 4, param = []; end
    if ~isempty(param)
        dur = param(1);
        start_freq = param(2);
        end_freq = param(3);
        fs = param(4);
    end   
else
    param = [];
end
if ~isempty(param) || nargin ~=0
    if (exist('fs') ~= 1)
       fs = 48000;
    end
    
    if end_freq > fs/2, end_freq = fs/2; end
    
    t = 0:1/fs:(dur-1/fs); %time in seconds
    S = chirp(t,start_freq,(dur-1/fs),end_freq)';
    
    Sinv = flipud(S);

    OUT.audio = S;
    OUT.audio2 = Sinv;
    OUT.fs = fs;
    OUT.tag = ['Sine sweep linear' num2str(dur)];
else
    OUT = [];
end