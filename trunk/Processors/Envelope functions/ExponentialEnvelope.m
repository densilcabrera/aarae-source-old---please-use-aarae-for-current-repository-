function out = ExponentialEnvelope(in, fs)
% This function applies an exponential envelope to the audio.
%
% Use a positive exponent for exponential growth.
% Use a negative exponent for exponential decay.
%
% For equivalent reverberation times, the following can be used:
% RT    | exponent
% 0.5 s | -13.8
% 1 s   | -6.9
% 2 s   | -3.45
%
% In other words, the exponent is equal to -6ln(10) / (2RT)
%
% Code by Densil Cabrera
% version 1.00 (4 November 2013)

if isstruct(in)
    audio = in.audio;
    fs = in.fs;
else
    audio = in;
end

[len, chans, bands] = size(audio);

prompt = {'Exponential growth or decay constant', ...
    'Normalize'};
dlg_title = 'Settings';
num_lines = 1;
def = {'0','1'};
answer = inputdlg(prompt,dlg_title,num_lines,def);
if isempty(answer)
    out = [];
    return
else
    exponent = str2double(answer{1,1});
    normalize = abs(str2double(answer{2,1}));
end

t = (0:(len-1))./fs; % time in s


envelope = exp(exponent.*t)';

audio = audio .* repmat(envelope, [1,chans,bands]);
if normalize
    audio = audio ./ max(max(max(abs(audio))));
end

out.audio = audio;

RT = -3*log(10)/exponent;
disp(['Equivalent reverberation time of exponent is ', num2str(RT), ' s.'])