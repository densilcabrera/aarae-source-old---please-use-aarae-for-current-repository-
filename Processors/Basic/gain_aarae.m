function out = gain_aarae(in)
% This function applies gain to the audio.
% Gain is specified in dB, where:
% 0 dB means no change
% a positive value amplifies the waveform
% a negative value attenuates the waveform
% 
% The default value normalizes the audio, whilst preserving the amplitude
% relationships between the channels and bands (where relevant)
%
% Inputting 'n' normalizes each data column individually
%
% Code by Densil Cabrera
% version 1.0 (14 October 2013)

Lmax = 20*log10(max(max(max(abs(in.audio)))));
prompt = {['Gain (dB) or ''n'' (max is ',num2str(Lmax), ' dBFS)']};
dlg_title = 'Gain';
num_lines = 1;
def = {num2str(-Lmax)};
answer = inputdlg(prompt,dlg_title,num_lines,def);
gain = answer{1,1};
if ischar(gain)
    % normalize column channel individually
    maxval = max(abs(in.audio));
    out = in.audio ./ repmat(maxval,[length(in.audio),1,1]);
else
    gain = str2num(gain);
    out = in.audio * 10.^(gain/20);
end

end