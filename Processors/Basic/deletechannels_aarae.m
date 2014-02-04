function out = deletechannels_aarae(in)
% This function allows you to select the channels that you wish to retain,
% and delete the remaining channels

if isfield(in,'chanID')
    param = in.chanID;
else
    param = [];
end

if ~isempty(param)
[S,ok] = listdlg('Name','Channel selection',...
    'PromptString','Delete unselected channels',...
    'ListString',param,...
    'ListSize', [160 320]);

    if ok == 1 && ~isempty(S)
        out.audio = in.audio(:,S,:);
        if isfield(in,'chanID')
            out.chanID = in.chanID(S);
        else
            out.chanID = S;
        end
    else
        out = [];
    end
else
    out = [];
    warndlg('Audio has a single channel','AARAE info');
end
end