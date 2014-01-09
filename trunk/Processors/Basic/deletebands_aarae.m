function out = deletebands_aarae(in)
% This function allows you to select the bands that you wish to retain,
% and delete the remaining bands

if isfield(in,'bandID')
    param = in.bandID;
else
    param = 1:size(in.audio,3);
end

[S,ok] = listdlg('Name','Band selection',...
    'PromptString','Delete unselected bands',...
    'ListString',num2str(param'),...
    'ListSize', [160 320]);

if ok == 1
    out.audio = in.audio(:,:,S);
    if isfield(in,'bandID')
        out.bandID = in.bandID(S);
    else
        out.bandID = S;
    end
else
    out = in;
end
end