function out = deletechannels_aarae(in,S)
% This function allows you to select the channels that you wish to retain,
% and delete the remaining channels

%if isfield(in,'chanID')
%    param = in.chanID;
%else
%    param = [];
%end
if isstruct(in)
    data = in.audio;
else
    data = in;
end
param = cellstr([repmat('Chan',size(data,2),1) num2str((1:size(data,2))')]);

if ~isempty(param)
    if nargin < 2
        [S,ok] = listdlg('Name','Channel selection',...
            'PromptString','Delete unselected channels',...
            'ListString',param,...
            'ListSize', [160 320]);
    end

    if ok == 1 && ~isempty(S)
        try
            out.audio = in.audio(:,S,:);
            if isfield(in,'chanID') && length(in.chanID) == size(in.audio,2)
                out.chanID = in.chanID(S);
                if isfield(in,'cal')
                    out.cal = in.cal(S);
                end
            else
                out.chanID = num2cell(S);
            end
            out.funcallback.name = 'deletechannels_aarae.m';
            out.funcallback.inarg = {S};
        catch
            out = [];
        end
    else
        out = [];
    end
else
    out = [];
    h = warndlg('Audio has a single channel','AARAE info','modal');
    uiwait(h)
end
end