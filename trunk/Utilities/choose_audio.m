function out = choose_audio

handles = guidata(findobj('Tag','aarae'));

method = menu('Choose audio',...
              'Choose from AARAE',...
              'Locate file on disc',...
              'Cancel');
switch method
    case 1
        root = handles.root; % Get selected leaf
        root = root(1);
        first = root.getFirstChild;
        nbranches = root.getChildCount;
        branches = cell(nbranches,1);
        branches{1,1} = char(first.getValue);
        nleaves = 0;
        nleaves = nleaves + handles.(genvarname(branches{1,1}))(1).getChildCount;
        next = first.getNextSibling;
        for n = 2:nbranches
            branches{n,1} = char(next.getValue);
            nleaves = nleaves + handles.(genvarname(branches{n,1}))(1).getChildCount;
            next = next.getNextSibling;
        end
        if nleaves == 0, return; end
        leaves = cell(nleaves,1);
        i = 0;
        for n = 1:size(branches,1)
            currentbranch = handles.(genvarname(branches{n,1}));
            if currentbranch.getChildCount ~= 0
                first = currentbranch.getFirstChild;
                data = first(1).handle.UserData;
                if isfield(data,'audio')
                    i = i + 1;
                    %leafnames(i,:) = first.getName;
                    leaves{i,:} = char(first.getValue);
                end
                next = first.getNextSibling;
                if ~isempty(next)
                    data = next(1).handle.UserData;
                    for m = 1:currentbranch.getChildCount-1
                        if isfield(data,'audio')
                            i = i + 1;
                            %leafnames(i,:) = next.getName;
                            leaves{i,:} = char(next.getValue);
                            next = next.getNextSibling;
                            if ~isempty(next)
                                data = next(1).handle.UserData;
                            end
                        end
                    end
                end
            end
        end
        if nleaves ~=0
            %leafnames = char(leafnames);
            [s,ok] = listdlg('PromptString','Select a file:',...
                    'SelectionMode','single',...
                    'ListString',leaves);
            %leaves = char(leaves);
            if ok == 1
                out = handles.(genvarname(leaves{s,1})).handle.UserData;
            else
                out = [];
                warndlg('No signal loaded!','Whoops...!');
            end
        else
            out = [];
        end
    case 2
        [filename,pathname] = uigetfile(...
                    {'*.wav;*.mat','Calibration file (*.wav,*.mat)'});
        [~,~,ext] = fileparts(filename);
        if filename ~= 0
            % Check type of file. First 'if' is for .mat, second is for .wav
            if strcmp(ext,'.mat') || strcmp(ext,'.MAT')
                audio = importdata(fullfile(pathname,filename));
                if ~isstruct(audio)
                    out.audio = audio;
                    out.fs = inputdlg('Sampling frequency',...
                                ['Please specify ' filename ' sampling frequency'],[1 50]);
                    out.fs = str2double(char(out.fs))';
                    if isnan(out.fs) || out.fs <= 0
                        out = [];
                        warndlg('Cannot import file without a valid sampling frequency!','AARAE info')
                    end
                else
                    if isfield(audio,'audio') && isfield(audio,'fs')
                        out = audio;
                    else
                        warndlg('Invalid AARAE file format!','AARAE info')
                    end
                end
            elseif strcmp(ext,'.wav') || strcmp(ext,'.WAV')
                [out.audio,out.fs] = audioread(fullfile(pathname,filename));
            else
                out = [];
            end
        else
            out = [];
        end
    otherwise
        out = [];
        warndlg('File selection canceled!','AARAE info')
end
end