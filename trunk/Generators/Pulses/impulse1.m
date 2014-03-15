function OUT = impulse1(duration_pre,duration_post,amplitude, fs)
% Generates a Kronecker delta function with a specified duration of silence
% before and/or after.
if nargin == 0
    param = inputdlg({'Duration of silence before impulse [s]';...
        'Duration of silence after impulse [s]';...
        'Impulse amplitude value';...
        'Sampling frequency [samples/s]'}, ...
        'Impulse input parameters',1,{'0';'0.1';'1';'48000'});
    param = str2num(char(param));
    if length(param) < 4, param = []; end
    if ~isempty(param)
        duration_pre = param(1);
        duration_post = param(2);
        amplitude = param(3);
        fs = param(4);
    end
else
    param = [];
end
if ~isempty(param) || nargin ~= 0
    samples_pre = round(duration_pre * fs);
    samples_post = round(duration_post * fs);
    
    if samples_pre > 0
        wave_pre = zeros(samples_pre,1);
    else
        wave_pre = [];
    end
    
    if samples_post > 0
        wave_post = zeros(samples_post,1);
    else
        wave_post = [];
    end
    
    y = [wave_pre; amplitude; wave_post];
    tag = ['Impulse_' num2str(samples_pre) '_' num2str(samples_post) '_' num2str(amplitude)];
    
    OUT.audio = y;
    OUT.fs = fs;
    OUT.tag = tag;
    OUT.param = {duration_pre,duration_post,amplitude, fs};
else
    OUT = [];
end

end % End of function