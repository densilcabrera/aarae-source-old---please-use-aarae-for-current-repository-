% --- Writes verbose data to the log file for an audio leaf
function logaudioleaffields(signaldata,callbackaudioin)
% This function is called from aarae.m, to write to the log file
% The third input argument callbackaudioin should be 0 if the function call
% back does not have audio in, or 1 (default) if it does.

if ~exist('callbackaudioin','var')
    callbackaudioin = 1;
end

handles = guidata(findobj('Tag','aarae'));

% Generate the function callback (if possible) and write to log file




if isfield(signaldata,'funcallback')
    if isfield(signaldata.funcallback,'name')
        callbackstring = signaldata.funcallback.name;
        if ~callbackaudioin
            callbackstring = ['OUT = ',callbackstring(1:end-2),'('];
        else
            callbackstring = ['OUT = ',callbackstring(1:end-2),'(IN'];
        end
    end
    if isfield(signaldata.funcallback,'inarg')
        if ~isempty(signaldata.funcallback.inarg)
            if callbackaudioin ==1
                callbackstring = [callbackstring,','];
            end
            for inargcount = 1:length(signaldata.funcallback.inarg)
                try
                    if numel(signaldata.funcallback.inarg{inargcount})>1000
                        callbackstring = [callbackstring,'''DATA_TOO_BIG_TO_LOG'''];
                    elseif ischar(signaldata.funcallback.inarg{inargcount})
                        callbackstring = [callbackstring,'''',signaldata.funcallback.inarg{inargcount},''''];
                    elseif iscell(signaldata.funcallback.inarg{inargcount})
                        callbackstring = [callbackstring,'''CELL_INPUT_NOT_INTERPRETED'''];
                    else
                        if length(signaldata.funcallback.inarg{inargcount}) == 1
                            callbackstring = [callbackstring,num2str(signaldata.funcallback.inarg{inargcount})];
                        else
                            if length(size(signaldata.funcallback.inarg{inargcount})) <= 2
                                callbackstring = [callbackstring,'['];
                                for rw = 1:size(signaldata.funcallback.inarg{inargcount},1)
                                    callbackstring = [callbackstring,num2str(signaldata.funcallback.inarg{inargcount}(rw,:))];
                                    if rw <size(signaldata.funcallback.inarg{inargcount},1)
                                        callbackstring = [callbackstring,';'];
                                    end
                                end
                                callbackstring = [callbackstring,']'];
                            else
                                callbackstring = [callbackstring,'''MULTIDIMENSIONAL_INPUT_NOT_INTERPRETED'''];
                            end
                        end
                    end
                catch
                    %fprintf(handles.fid,['%%  ','input argument ', num2str(inargcount),': format not interpreted for logging \n']);
                    callbackstring = [callbackstring,'''INPUT_NOT_INTERPRETED'''];
                end
                if inargcount < length(signaldata.funcallback.inarg)
                    callbackstring = [callbackstring,','];
                end
            end
        end
    end
    callbackstring = [callbackstring,');'];
    fprintf(handles.fid,[callbackstring,'\n']);
end

% Deal with partial selection in processors
if isfield(handles,'partialselindices')
    indices = handles.partialselindices;
    selectionstring = [];
            for i = 1:length(indices)
                dimstring = char(indices{i});
                if ~isempty(regexp(dimstring,',','once')) || ~isempty(regexp(dimstring,' ','once'))
                    dimstring = ['[', dimstring, ']'];
                end
                if i<length(indices)
                    selectionstring = [selectionstring, dimstring,','];
                else
                    selectionstring = [selectionstring, dimstring,')'];
                end
            end
        selectionstring = ['COMPLETE.audio(',selectionstring,' = OUT.audio;\n'];
            fprintf(handles.fid,'OUT.audio = COMPLETE.audio;\n');
            fprintf(handles.fid,'clear COMPLETE\n\n');
    handles = rmfield(handles,'partialselindices');
    guidata(findobj('Tag','aarae'),handles); % maybe this is dangerous!
else
    fprintf(handles.fid,'\n');
end



% describe audio
if isfield(signaldata,'audio')
    fprintf(handles.fid,['%%  audio field size: ',num2str(size(signaldata.audio)),'\n']);
else
    fprintf(handles.fid,'%%  No audio field\n');
end
if isfield(signaldata,'fs')
    fprintf(handles.fid,['%%  fs: ',num2str(signaldata.fs),' Hz\n']);
end

% Log of chan, band and audio2 fields if they exist
if isfield(signaldata,'audio2')
    fprintf(handles.fid,['%%  audio2 field size: ',num2str(size(signaldata.audio2)),'\n']);
end
if isfield(signaldata,'cal')
    fprintf(handles.fid,['%%  ','Channel calibration offset (dB): ', num2str(signaldata.cal(:)'),'\n']);
end
if isfield(signaldata,'chanID')
    fprintf(handles.fid,['%%  ','ChanID: ']);
    for ch = 1:length(signaldata.chanID)
        fprintf(handles.fid,[' ',signaldata.chanID{ch},'; ']);
    end
    fprintf(handles.fid,'\n');
end
if isfield(signaldata,'bandID')
    fprintf(handles.fid,['%%  ','BandID: ', num2str(signaldata.bandID(:)'),'\n']);
end





% Log of properties subfields
if isfield(signaldata,'properties')
    fnamesprop = fieldnames(signaldata.properties);
    for fpropcount = 1:length(fnamesprop)
        dat = signaldata.properties.(fnamesprop{fpropcount});
        try
            if length(size(dat)) <=2 || numel(dat)<=100 % filter out multidimensional and big data
                if ischar(dat)
                    fprintf(handles.fid,['%%  ','properties.',fnamesprop{fpropcount}, ': ', dat,'\n']);
                elseif iscell(dat)
                    for rw=1:size(dat,1)
                        if rw == 1
                            fprintf(handles.fid,['%%  ','properties.',fnamesprop{fpropcount}, ': ', dat{rw,:},'\n']);
                        else
                            fprintf(handles.fid,['%%                ', dat{rw,:},'\n']);
                        end
                    end
                else
                    if min(size(dat)) == 1, dat = dat(:)'; end
                    for rw=1:size(dat,1)
                        if rw == 1
                            fprintf(handles.fid,['%%  ','properties.',fnamesprop{fpropcount}, ': ', num2str(dat(rw,:)),'\n']);
                        else
                            fprintf(handles.fid,['%%                ',num2str(dat(rw,:)),'\n']);
                        end
                    end
                end
            else
                fprintf(handles.fid,['%%  ','properties.',fnamesprop{fpropcount}, ': data is large or multidimensional \n']);
            end
        catch
            fprintf(handles.fid,['%%  ','properties.',fnamesprop{fpropcount}, ': format not interpreted for logging \n']);
        end
    end
end
fprintf(handles.fid,'\n');
