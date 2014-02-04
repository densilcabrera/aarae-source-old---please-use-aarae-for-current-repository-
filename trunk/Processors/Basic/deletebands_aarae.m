function out = deletebands_aarae(in)
% This function allows you to select the bands that you wish to retain,
% and delete the remaining bands

if isfield(in,'bandID')
    param = in.bandID;
else
    param = [];
end

if ~isempty(param)
    [S,ok] = listdlg('Name','Band selection',...
        'PromptString','Delete unselected bands',...
        'ListString',num2str(param'),...
        'ListSize', [160 320]);

    if ok == 1 && ~isempty(S)
        out.audio = in.audio(:,:,S);
        if isfield(in,'bandID')
            out.bandID = in.bandID(S);
        else
            out.bandID = S;
        end
    else
        out = [];
    end
else
    out = [];
    warndlg('No bands available','AARAE info');
end