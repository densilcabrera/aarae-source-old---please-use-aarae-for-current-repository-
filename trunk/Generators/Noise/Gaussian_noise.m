function OUT = Gaussian_noise(duration, chans, fs)
% Generates Gaussian noise with a standard deviation of 0.1

if nargin == 0
    param = inputdlg({'Duration of the wave [s]';...
        'Number of channels';...
        'Sampling frequency [samples/s]'}, ...
        'Input parameters',1,{'1';'1';'48000'});
    param = str2num(char(param));
    if length(param) < 3, param = []; end
    if ~isempty(param)
        duration = param(1);
        chans = param(2);
        fs = param(3);
    end
else
    param = [];
end
if ~isempty(param) || nargin ~= 0
y = randn(round(duration*fs),chans)/10;

    tag = ['Gaussian' num2str(duration)];
    
    OUT.audio = y;
    OUT.audio2 = flipud(y);
    OUT.fs = fs;
    OUT.tag = tag;
    OUT.param = {duration, chans, fs};
else
    OUT = [];
end

end % End of function