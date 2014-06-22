function doresultplot(handles)

selectedNodes = handles.mytree.getSelectedNodes;
audiodata = selectedNodes(1).handle.UserData;
chartmenu = cellstr(get(handles.chartfunc_popup,'String'));
chartfunc = chartmenu{get(handles.chartfunc_popup,'Value')};
cattable = get(handles.cattable);
sel = strjoin(cattable.Data(:,2).',',');
if isempty(sel), sel = '[1]'; end
try
    tabledata = get(handles.cattable,'Data');
    catorcont = tabledata(:,4);
    if any(cellfun(@isempty,catorcont)), catorcont(cellfun(@isempty,catorcont)) = {false}; end
    naxis = length(find([catorcont{:}] == true));
    if naxis < 2
        if ~strcmp(chartfunc,'distributionPlot') && ~strcmp(chartfunc,'boxplot')
            axis = find([catorcont{:}] == true);
            Xdata = audiodata.(genvarname(tabledata{axis(1,1),1}));
            if ~isnumeric(Xdata)
                if iscell(Xdata), Xdata = cell2mat(Xdata); end
            end
            if ~isequal(size(Xdata),size(audiodata.data))
                eval([chartfunc '(handles.axesdata,Xdata,squeeze(audiodata.data(' sel ')))'])
            else
                eval([chartfunc '(handles.axesdata,squeeze(Xdata(' sel ')),squeeze(audiodata.data(' sel ')))'])
            end
            xlabel(handles.axesdata,[tabledata{axis(1,1),1} ' [' audiodata.(genvarname([tabledata{axis(1,1),1} 'info'])).units ']'])
        else
            cla(handles.axesdata,'reset')
            singdim = [];
            eval(['singdim = min(find(size(audiodata.data(' sel ')) == 1));'])
            if isempty(singdim), singdim = 1; end
            if strcmp(chartfunc,'distributionPlot')
                eval([chartfunc '(handles.axesdata,squeeze(audiodata.data(' sel ')),''xNames'',audiodata.(genvarname(cattable.Data{singdim,1}))(' cattable.Data{singdim,2} '))'])
            end
            if strcmp(chartfunc,'boxplot')
                eval([chartfunc '(handles.axesdata,squeeze(audiodata.data(' sel ')),''labels'',audiodata.(genvarname(cattable.Data{singdim,1}))(' cattable.Data{singdim,2} '))'])
            end
            xlabel(handles.axesdata,[cattable.Data{singdim,1} ' [' audiodata.(genvarname([cattable.Data{singdim,1} 'info'])).units ']'])
        end
        handles.tabledata = tabledata;
        guidata(handles.aarae,handles)
    elseif naxis == 2
        axis = find([catorcont{:}] == true);
        Xdata = audiodata.(genvarname(tabledata{axis(1,1),1})); 
        Ydata = audiodata.(genvarname(tabledata{axis(1,2),1}));
        if ~isnumeric(Xdata)
            if iscell(Xdata), Xdata = cell2mat(Xdata); end
        end
        if ~isnumeric(Ydata)
            if iscell(Ydata), Ydata = cell2mat(Ydata); end
        end
        if ~strcmp(chartfunc,'imagesc')
            eval(['data = squeeze(audiodata.data(' sel '));'])
            if ~isequal([length(Ydata),length(Xdata)],size(data)), data = data'; end %#ok : Used in line above
            eval([chartfunc '(handles.axesdata,Xdata,Ydata,data)'])
        else
            eval([chartfunc '(Xdata,Ydata,squeeze(audiodata.data(' sel ')),''Parent'',handles.axesdata)'])
            eval(['figure;' chartfunc '(Xdata,Ydata,squeeze(audiodata.data(' sel ')),''Clipping'',''off'')'])
            set(handles.axesdata,'YDir','normal')
        end
        xlabel(handles.axesdata,[tabledata{axis(1,1),1} ' [' audiodata.(genvarname([tabledata{axis(1,1),1} 'info'])).units ']'])
        ylabel(handles.axesdata,[tabledata{axis(1,2),1} ' [' audiodata.(genvarname([tabledata{axis(1,2),1} 'info'])).units ']'])
        colormap('Jet')
        handles.tabledata = tabledata;
        guidata(handles.aarae,handles)
    else
        set(handles.cattable,'Data',handles.tabledata)
        warndlg('Cannot display plots with more than 2 main axis defined!','AARAE info','modal')
    end
catch error
    set(handles.cattable,'Data',handles.tabledata)
    catorcont = handles.tabledata(:,4);
    if any(cellfun(@isempty,catorcont)), catorcont(cellfun(@isempty,catorcont)) = {false}; end
    naxis = length(find([catorcont{:}] == true));
    switch naxis
        case 0
            set(handles.chartfunc_popup,'String',{'distributionPlot','boxplot'},'Value',1)
        case 1
            set(handles.chartfunc_popup,'String',{'plot','semilogx','semilogy','loglog','distributionPlot','boxplot'},'Value',1)
        case 2
            set(handles.chartfunc_popup,'String',{'mesh','surf','imagesc'},'Value',1)
        otherwise
            set(handles.chartfunc_popup,'String',{[]},'Value',1)
    end
    %if ~ischar(Xdata) && ~ischar(Ydata), doresultplot(handles); end
    warndlg(error.message,'AARAE info','modal')
end