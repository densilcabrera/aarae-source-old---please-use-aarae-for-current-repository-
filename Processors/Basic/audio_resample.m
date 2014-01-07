function out = audio_resample(in)
% This function resamples the audio, using Matlab's resample function.
% The .fs field is changed to the new audio sampling rate.
%
% Code by Densil Cabrera
% version 1.0 (5 November 2013)

fs = in.fs;
prompt = {['New sampling rate (current is ',num2str(fs), ' Hz)']};
dlg_title = 'Resample';
num_lines = 1;
def = {num2str(fs)};
answer = inputdlg(prompt,dlg_title,num_lines,def);
newfs = str2double(answer{1,1});
    out.audio = resample(in.audio, newfs, fs);
out.fs = newfs;

end