function out = resample_aarae(in)
% This function resamples the audio, using Matlab's resample function.
% The .fs field is changed to the new audio sampling rate.
%
% Code by Densil Cabrera & Daniel Jimenez
% version 1.0 (5 November 2013)

fs = in.fs;
prompt = {['New sampling rate (current is ',num2str(fs), ' Hz)']};
dlg_title = 'Resample';
num_lines = 1;
def = {num2str(fs)};
answer = inputdlg(prompt,dlg_title,num_lines,def);
if ~isempty(answer)
    newfs = str2double(answer{1,1});
    numtracks = 0;
    tracks = strfind(fieldnames(in),'audio');
    for t = 1:length(tracks)
        if tracks{t,1} == 1
            numtracks = numtracks + 1;
        end
    end
    for i = 1:size(in.audio,2)
        for j = 1:size(in.audio,3)
            out.audio(:,i,j) = resample(in.audio(:,i,j), newfs, fs);
        end
    end
    if numtracks > 1
        for tracknum = 2:numtracks
            for i = 1:size(in.(genvarname(['audio' num2str(tracknum)])),2)
                for j = 1:size(in.(genvarname(['audio' num2str(tracknum)])),3)
                    out.(genvarname(['audio' num2str(tracknum)]))(:,i,j) = resample(in.(genvarname(['audio' num2str(tracknum)]))(:,i,j), newfs, fs);
                end
            end
        end
    end
    out.fs = newfs;
else
    out = [];
end

end