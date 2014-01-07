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
        branches{1,:} = char(first.getValue);
        next = first.getNextSibling;
        for n = 1:root.getChildCount-1
            branches{n+1,:} = char(next.getValue);
            next = next.getNextSibling;
        end
        branches = char(branches);
        
        i = 0;
        for n = 1:size(branches,1)
            currentbranch = handles.(genvarname(branches(n,:)));
            if currentbranch.getChildCount ~= 0
                first = currentbranch.getFirstChild;
                data = first(1).handle.UserData;
                if isfield(data,'audio')
                    i = i + 1;
                    leafnames(i,:) = first.getName;
                    leaves{i,:} = char(first.getValue);
                end
                next = first.getNextSibling;
                if ~isempty(next)
                    data = next(1).handle.UserData;
                    for m = 1:currentbranch.getChildCount-1
                        if isfield(data,'audio')
                            i = i + 1;
                            leafnames(i,:) = next.getName;
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
        if exist('leafnames')
            leafnames = char(leafnames);
            [s,ok] = listdlg('PromptString','Select a file:',...
                    'SelectionMode','single',...
                    'ListString',leafnames);
            leaves = char(leaves);
            if ok == 1
                out = handles.(genvarname(leaves(s,:))).handle.UserData;
            else
                out = [];
                warndlg('No signal loaded!','Whoops...!');
            end
        else
            out = [];
        end
    case 2
        [filename,pathname,filterindex] = uigetfile(...
                    {'*.wav;*.mat','Calibration file (*.wav,*.mat)'});
        if filename ~= 0
            % Check type of file. First 'if' is for .mat, second is for .wav
            if ~isempty(regexp(filename, '.mat', 'once'))
                audio = importdata(fullfile(pathname,filename));
                if ~isstruct(audio)
                    out.audio = audio;
                    out.fs = inputdlg('Sampling frequency',...
                                ['Please specify ' filename ' sampling frequency'],[1 50]);
                    out.fs = str2num(char(out.fs))';
                    if isempty(out.fs) || out.fs <= 0
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
            elseif ~isempty(regexp(filename, '.wav', 'once'))
                [out.audio out.fs] = wavread(fullfile(pathname,filename));
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