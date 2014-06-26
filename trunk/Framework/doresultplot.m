function doresultplot(handles,haxes)

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
                eval([chartfunc '(haxes,Xdata,squeeze(audiodata.data(' sel ')))'])
            else
                eval([chartfunc '(haxes,squeeze(Xdata(' sel ')),squeeze(audiodata.data(' sel ')))'])
            end
            xlabel(haxes,strrep([tabledata{axis(1,1),1} ' [' audiodata.(genvarname([tabledata{axis(1,1),1} 'info'])).units ']'],'_',' '))
            ylabel(haxes,strrep(audiodata.datainfo.units,'_',' '))
        else
            cla(haxes,'reset')
            singdim = [];
            catdim = find(cellfun(@isempty,tabledata(:,4)),1);
            if isempty(catdim), catdim = 1; end
            eval(['catdim = length(size(audiodata.data(' sel ')));'])
            if isempty(singdim), singdim = 1; end
            if strcmp(chartfunc,'distributionPlot')
                eval([chartfunc '(haxes,squeeze(audiodata.data(' sel ')),''xNames'',audiodata.(genvarname(cattable.Data{catdim,1}))(' cattable.Data{catdim,2} '))'])
            end
            if strcmp(chartfunc,'boxplot')
                eval([chartfunc '(haxes,squeeze(audiodata.data(' sel ')),''labels'',audiodata.(genvarname(cattable.Data{catdim,1}))(' cattable.Data{catdim,2} '))'])
            end
            xlabel(haxes,strrep([cattable.Data{catdim,1} ' [' audiodata.(genvarname([cattable.Data{catdim,1} 'info'])).units ']'],'_',' '))
            ylabel(haxes,strrep(audiodata.datainfo.units,'_',' '))
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
            eval([chartfunc '(haxes,Xdata,Ydata,data)'])
        else
            eval([chartfunc '(Xdata,Ydata,squeeze(audiodata.data(' sel ')),''Parent'',haxes)'])
            set(haxes,'YDir','normal')
        end
        xlabel(haxes,strrep([tabledata{axis(1,1),1} ' [' audiodata.(genvarname([tabledata{axis(1,1),1} 'info'])).units ']'],'_',' '))
        ylabel(haxes,strrep([tabledata{axis(1,2),1} ' [' audiodata.(genvarname([tabledata{axis(1,2),1} 'info'])).units ']'],'_',' '))
        zlabel(haxes,strrep(audiodata.datainfo.units,'_',' '))
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
    doresultplot(handles,haxes);
    warndlg(error.message,'AARAE info','modal')
end