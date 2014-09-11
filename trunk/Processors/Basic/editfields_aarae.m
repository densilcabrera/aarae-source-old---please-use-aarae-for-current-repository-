function OUT = editfields_aarae(IN)
% This function allows you to edit some of the fields of an audio leaf.
%
% Currently the supported fields are:
% fs
% bandID
% chanID


% Make a list of editable fields
fnames = fieldnames(IN);
numfields = length(fnames);
editablefields = {};
m = 1;
for n = 1:length(fnames)
    if isempty(regexp(char(fnames{n}),'audio','once')) ...
            && isempty(regexp(char(fnames{n}),'funcallback','once')) ...
        && isempty(regexp(char(fnames{n}),'datatype','once'))
        if isempty(regexp(char(fnames{n}),'properties','once'))
            editablefields{m} = fnames{n};
            m = m+1;
        else
            % TO DO: work which properties can be edited (if any)
        end
    end
end


[S,ok] = listdlg('Name','Edit Fields',...
    'PromptString','Select field(s) to edit',...
    'ListString',editablefields);
if ok == 0
    OUT = [];
    return
end
chosenfields = editablefields(S);


for n = 1: length(chosenfields)
    
    
    % fs
    if strcmp(chosenfields{n},'fs')
        
        prompt = {['Current sampling rate is ',...
            num2str(IN.fs),...
            ' Hz. (Note that editing this will not result in resampling of the audio.)']};
        dlg_title = 'Edit Sampling Rate';
        num_lines = 1;
        def = {num2str(IN.fs)};
        answer = inputdlg(prompt,dlg_title,num_lines,def);
        if ~isempty(answer)
            fs = abs(round(str2double(answer)));
            if ~isnan(fs)
                OUT.fs = fs;
            end
        end
    end
    
    
    
    
    
    
    % bandID
    if strcmp(chosenfields{n},'bandID')
        f = figure;
        
        dat = IN.bandID(:);
        columnname = {'bandID'};
        columnformat = {'numeric'};
        columneditable = true;
        t = uitable(f,...
            'Units','normalized',...
            'Position',[0 0 0.5 1],...
            'Data',dat,...
            'ColumnName', columnname,...
            'ColumnFormat', columnformat,...
            'ColumnEditable', columneditable,...
            'Rowname',[]);
        try
            h = uicontrol(f,...
                'Units','normalized',...
                'Position',[0.6 0.1 0.3 0.2],...
                'String','Continue',...
                'Callback','uiresume(gcbf)');
            
            uiwait(gcf);
            % retrieve handle to uitable
            tH = findobj(gcf,'Type','uitable');
            % retrieve data
            answer = get(tH,'Data');
            if length(answer) == size(IN.audio,3)
                OUT.bandID = answer;
            else
                OUT.bandID=IN.bandID;
            end
            close(f);
        catch
            OUT.bandID=IN.bandID;
        end
        
    end
    
    
    
    
    
    
    
    % chanID
    if strcmp(chosenfields{n},'chanID')
        f = figure;
        
        dat = IN.chanID(:);
        columnname = {'chanID'};
        columnformat = {'char'};
        columneditable = true;
        t = uitable(f,...
            'Units','normalized',...
            'Position',[0 0 0.5 1],...
            'Data',dat,...
            'ColumnName', columnname,...
            'ColumnFormat', columnformat,...
            'ColumnEditable', columneditable,...
            'Rowname',[]);
        try
            h = uicontrol(f,...
                'Units','normalized',...
                'Position',[0.6 0.1 0.3 0.2],...
                'String','Continue',...
                'Callback','uiresume(gcbf)');
            
            uiwait(gcf);
            % retrieve handle to uitable
            tH = findobj(gcf,'Type','uitable');
            % retrieve data
            answer = get(tH,'Data');
            if length(answer) == size(IN.audio,2)
                OUT.chanID = answer;
            else
                OUT.chanID=IN.chanID;
            end
            
            close(f);
        catch
            OUT.chanID=IN.chanID;
        end
        
    end
    
    
    % ADD EDITORS FOR PROPERTIES ETC HERE
    
    
    
    
    
end
end % eof
