function varargout = comparedata(varargin)
% COMPAREDATA MATLAB code for comparedata.fig
%      COMPAREDATA, by itself, creates a new COMPAREDATA or raises the existing
%      singleton*.
%
%      H = COMPAREDATA returns the handle to a new COMPAREDATA or the handle to
%      the existing singleton*.
%
%      COMPAREDATA('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in COMPAREDATA.M with the given input arguments.
%
%      COMPAREDATA('Property','Value',...) creates a new COMPAREDATA or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before comparedata_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to comparedata_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help comparedata

% Last Modified by GUIDE v2.5 21-Jul-2014 10:59:09

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @comparedata_OpeningFcn, ...
                   'gui_OutputFcn',  @comparedata_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before comparedata is made visible.
function comparedata_OpeningFcn(hObject, ~, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to comparedata (see VARARGIN)

% Choose default command line output for comparedata

% This next couple of lines checks if the GUI is being called from the main
% window, otherwise it doesn't run.
dontOpen = false;
mainGuiInput = find(strcmp(varargin, 'main_stage1'));
if (isempty(mainGuiInput)) ...
    || (length(varargin) <= mainGuiInput) ...
    || (~ishandle(varargin{mainGuiInput+1}))
    dontOpen = true;
else
    % Remember the handle, and adjust our position
    handles.main_stage1 = varargin{mainGuiInput+1};
    if ismac
        fontsize
    end
end

if dontOpen
   disp('-----------------------------------------------------');
   disp('This function is part of the AARAE framework, it is') 
   disp('not a standalone function. To call this function,')
   disp('click on the appropriate calling button on the main');
   disp('Window. E.g.:');
   disp('   Compare selected signals');
   disp('-----------------------------------------------------');
else
    % Do some stuff
    handles.main_stage1 = varargin{mainGuiInput+1};
    mainHandles = guidata(handles.main_stage1);
    handles.axesposition = get(handles.compaxes,'Position');
    selectedNodes = mainHandles.mytree.getSelectedNodes;
    if length(selectedNodes) == 1, selectedNodes(2) = selectedNodes(1); end
    handles.nodeA = selectedNodes(1).handle.UserData;
    handles.nodeB = selectedNodes(2).handle.UserData;
    set(handles.name1txt,'String',selectedNodes(1).getName.char)
    set(handles.name2txt,'String',selectedNodes(2).getName.char)
    filltable(handles.nodeA,handles.cattable1)
    filltable(handles.nodeB,handles.cattable2)
    setplottingoptions(handles)
    doresultplot(handles,handles.compaxes)
    guidata(hObject,guidata(hObject));
    uiwait(hObject);
end


% --- Outputs from this function are returned to the command line.
function varargout = comparedata_OutputFcn(hObject, ~, ~) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = [];
delete(hObject);


% --- Executes on selection change in compfunc_popup.
function compfunc_popup_Callback(~, ~, handles) %#ok : Executed when selection changes in plotting method
% hObject    handle to compfunc_popup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns compfunc_popup contents as cell array
%        contents{get(hObject,'Value')} returns selected item from compfunc_popup
doresultplot(handles,handles.compaxes)

% --- Executes during object creation, after setting all properties.
function compfunc_popup_CreateFcn(hObject, ~, ~) %#ok : Creation of plotting options popup menu
% hObject    handle to compfunc_popup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes when user attempts to close comparedata.
function comparedata_CloseRequestFcn(hObject, ~, ~) %#ok : Executed when comparedata window is closed
% hObject    handle to comparedata (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
uiresume(hObject);

function filltable(audiodata,cattable)
    fields = fieldnames(audiodata);
    fields = fields(3:end-1);
    categories = fields(mod(1:length(fields),2) == 1);
    catdata = cell(size(categories));
    catunits = cell(size(categories));
    catorcont = cell(size(categories));
    for n = 1:length(categories)
        catunits{n,1} = audiodata.(genvarname([categories{n,1} 'info'])).units;
        catorcont{n,1} = audiodata.(genvarname([categories{n,1} 'info'])).axistype;
        if islogical(catorcont{n,1}) && catorcont{n,1} == true
            catdata{n,1} = ':';
        else
            catdata{n,1} = '[1]';
        end
    end
    dat = [categories,catdata,catunits,catorcont];
    set(cattable, 'Data', dat);
% End of function filltable


function doresultplot(handles,haxes)
if strcmp(get(get(haxes,'Parent'),'tag'),'comparedata')
    colorbar('off')
    set(haxes,'Position',handles.axesposition)
    cla(haxes,'reset')
    if isfield(handles,'compaxes2')
        delete(handles.compaxes2);
        handles = rmfield(handles,'compaxes2');
    end
end
handles.tabledata1 = get(handles.cattable1,'Data');
handles.tabledata2 = get(handles.cattable2,'Data');
guidata(handles.comparedata,handles)

chartmenu = cellstr(get(handles.compfunc_popup,'String'));
chartfunc = chartmenu{get(handles.compfunc_popup,'Value')};

nodeA = handles.nodeA;
cattable1 = get(handles.cattable1);
selA = strjoin(cattable1.Data(:,2).',',');
if isempty(selA), selA = '[1]'; end
catorcontA = cattable1.Data(:,4);
if any(cellfun(@isempty,catorcontA)), catorcontA(cellfun(@isempty,catorcontA)) = {false}; end
mainaxA = find([catorcontA{:}] == true);

nodeB = handles.nodeB;
cattable2 = get(handles.cattable2);
selB = strjoin(cattable2.Data(:,2).',',');
if isempty(selB), selB = '[1]'; end
catorcontB = cattable2.Data(:,4);
if any(cellfun(@isempty,catorcontB)), catorcontB(cellfun(@isempty,catorcontB)) = {false}; end
mainaxB = find([catorcontB{:}] == true);

try
    eval(['y1 = squeeze(nodeA.data(' selA '));'])
    eval(['y2 = squeeze(nodeB.data(' selB '));'])
    x1 = nodeA.(genvarname(cattable1.Data{mainaxA,1}));
    if ~isnumeric(x1)
        if iscell(x1), x1 = cell2mat(x1); end
    end
    if isequal(size(x1),size(nodeA.data)), eval(['x1 = squeeze(x1(' selA '));']); end
    x2 = nodeB.(genvarname(cattable2.Data{mainaxB,1}));
    if ~isnumeric(x2)
        if iscell(x2), x2 = cell2mat(x2); end
    end
    if isequal(size(x2),size(nodeB.data)), eval(['x2 = squeeze(x2(' selB '));']); end
    switch chartfunc
        case 'Double axis'
            line(x1,y1,'Parent',haxes)
            set(haxes,'XColor','b','YColor','b')
            xlabel(haxes,strrep([cattable1.Data{mainaxA(1,1),1} ' [' nodeA.(genvarname([cattable1.Data{mainaxA(1,1),1} 'info'])).units ']'],'_',' '),'HandleVisibility','on')
            ylabel(haxes,strrep(nodeA.datainfo.units,'_',' '),'HandleVisibility','on')
            compaxes_pos = get(haxes,'Position');
            if strcmp(get(get(haxes,'Parent'),'tag'),'comparedata')
                handles.compaxes2 = axes(...
                    'Units','characters',...
                    'Position',compaxes_pos,...
                    'XAxisLocation','top',...
                    'YAxisLocation','right',...
                    'Color','none',...
                    'XColor','r',...
                    'YColor','r',...
                    'ColorOrder',colormap(hsv(size(y2,2))),...
                    'Parent',get(haxes,'Parent'));
                line(x2,y2,'Parent',handles.compaxes2)
                xlabel(handles.compaxes2,strrep([cattable2.Data{mainaxB(1,1),1} ' [' nodeB.(genvarname([cattable2.Data{mainaxB(1,1),1} 'info'])).units ']'],'_',' '),'HandleVisibility','on')
                ylabel(handles.compaxes2,strrep(nodeB.datainfo.units,'_',' '),'HandleVisibility','on')
            else
                compaxes2 = axes(...
                    'Units','normalized',...
                    'Position',compaxes_pos,...
                    'XAxisLocation','top',...
                    'YAxisLocation','right',...
                    'Color','none',...
                    'XColor','r',...
                    'YColor','r',...
                    'ColorOrder',colormap(hsv(size(y2,2))),...
                    'Parent',get(haxes,'Parent'));
                line(x2,y2,'Parent',compaxes2)
                xlabel(compaxes2,strrep([cattable2.Data{mainaxB(1,1),1} ' [' nodeB.(genvarname([cattable2.Data{mainaxB(1,1),1} 'info'])).units ']'],'_',' '))
                ylabel(compaxes2,strrep(nodeB.datainfo.units,'_',' '))
            end
            set(handles.name1txt,'ForegroundColor','b')
            set(handles.name2txt,'ForegroundColor','r')
        case 'Two Y axis'
            ax = plotyy(x1,y1,x2,y2);
            xlabel(haxes,strrep(['Units: [' nodeA.(genvarname([cattable1.Data{mainaxA(1,1),1} 'info'])).units ']'],'_',' '))
            ylabel(ax(1),strrep(nodeA.datainfo.units,'_',' '))
            ylabel(ax(2),strrep(nodeB.datainfo.units,'_',' '))
            set(handles.name1txt,'ForegroundColor',get(ax(1),'YColor'))
            set(handles.name2txt,'ForegroundColor',get(ax(2),'YColor'))
        case 'X-Y'
            plot(haxes,y1,y2,'ro')
            xlabel(haxes,['Data 1: ' strrep(nodeA.datainfo.units,'_',' ')],'HandleVisibility','on')
            ylabel(haxes,['Data 2: ' strrep(nodeB.datainfo.units,'_',' ')],'HandleVisibility','on')
            set(handles.name1txt,'ForegroundColor','k')
            set(handles.name2txt,'ForegroundColor','k')
        case 'difference - log10'
            z1 = nodeA.(genvarname(cattable1.Data{mainaxA(1,2),1}));
            if ~isnumeric(z1)
                if iscell(z1), z1 = cell2mat(z1); end
            end
            ydif = real(log10(y2)-log10(y1));
            imagesc(1:length(z1),x1,ydif,'Parent',haxes)
            xlabel(haxes,strrep([cattable1.Data{mainaxA(1,2),1} ' [' nodeA.(genvarname([cattable1.Data{mainaxA(1,2),1} 'info'])).units ']'],'_',' '))
            ylabel(haxes,strrep([cattable1.Data{mainaxA(1,1),1} ' [' nodeA.(genvarname([cattable1.Data{mainaxA(1,1),1} 'info'])).units ']'],'_',' '))
            set(haxes,'XTickLabel',num2str(z1'))
            set(haxes,'YDir','normal')
            cmap = obb_cmap(min(min(ydif(isfinite(ydif)))),max(max(ydif(isfinite(ydif)))));
            colormap(cmap)
            colorbar
        case 'difference - log2'
            z1 = nodeA.(genvarname(cattable1.Data{mainaxA(1,2),1}));
            if ~isnumeric(z1)
                if iscell(z1), z1 = cell2mat(z1); end
            end
            ydif = real(log2(y2)-log2(y1));
            imagesc(1:length(z1),x1,ydif,'Parent',haxes)
            xlabel(haxes,strrep([cattable1.Data{mainaxA(1,2),1} ' [' nodeA.(genvarname([cattable1.Data{mainaxA(1,2),1} 'info'])).units ']'],'_',' '))
            ylabel(haxes,strrep([cattable1.Data{mainaxA(1,1),1} ' [' nodeA.(genvarname([cattable1.Data{mainaxA(1,1),1} 'info'])).units ']'],'_',' '))
            set(haxes,'XTickLabel',num2str(z1'))
            set(haxes,'YDir','normal')
            cmap = obb_cmap(min(min(ydif(isfinite(ydif)))),max(max(ydif(isfinite(ydif)))));
            colormap(cmap)
            colorbar
        case 'difference - 10*log10'
            z1 = nodeA.(genvarname(cattable1.Data{mainaxA(1,2),1}));
            if ~isnumeric(z1)
                if iscell(z1), z1 = cell2mat(z1); end
            end
            ydif = real(10.*log10(y2)-10.*log10(y1));
            imagesc(1:length(z1),x1,ydif,'Parent',haxes)
            xlabel(haxes,strrep([cattable1.Data{mainaxA(1,2),1} ' [' nodeA.(genvarname([cattable1.Data{mainaxA(1,2),1} 'info'])).units ']'],'_',' '))
            ylabel(haxes,strrep([cattable1.Data{mainaxA(1,1),1} ' [' nodeA.(genvarname([cattable1.Data{mainaxA(1,1),1} 'info'])).units ']'],'_',' '))
            set(haxes,'XTickLabel',num2str(z1'))
            set(haxes,'YDir','normal')
            cmap = obb_cmap(min(min(ydif(isfinite(ydif)))),max(max(ydif(isfinite(ydif)))));
            colormap(cmap)
            colorbar
        case 'difference'
            z1 = nodeA.(genvarname(cattable1.Data{mainaxA(1,2),1}));
            if ~isnumeric(z1)
                if iscell(z1), z1 = cell2mat(z1); end
            end
            ydif = real(y2-y1);
            imagesc(1:length(z1),x1,ydif,'Parent',haxes)
            xlabel(haxes,strrep([cattable1.Data{mainaxA(1,2),1} ' [' nodeA.(genvarname([cattable1.Data{mainaxA(1,2),1} 'info'])).units ']'],'_',' '))
            ylabel(haxes,strrep([cattable1.Data{mainaxA(1,1),1} ' [' nodeA.(genvarname([cattable1.Data{mainaxA(1,1),1} 'info'])).units ']'],'_',' '))
            set(haxes,'XTickLabel',num2str(z1'))
            set(haxes,'YDir','normal')
            cmap = obb_cmap(min(min(ydif(isfinite(ydif)))),max(max(ydif(isfinite(ydif)))));
            colormap(cmap)
            colorbar
    end
    guidata(handles.comparedata,handles)
catch error
    cla(haxes,'reset')
    if isfield(handles,'compaxes2')
        delete(handles.compaxes2);
    end
    warndlg(error.message,'AARAE info','modal')
end


% --- Executes when selected cell(s) is changed in cattable1.
function cattable1_CellSelectionCallback(hObject, eventdata, handles) %#ok : Executed when a cell is selected in the upper table
% hObject    handle to cattable1 (see GCBO)
% eventdata  structure with the following fields (see UITABLE)
%	Indices: row and column indices of the cell(s) currently selecteds
% handles    structure with handles and user data (see GUIDATA)
tabledata = get(hObject,'Data');
if size(eventdata.Indices,1) ~= 0 && eventdata.Indices(1,2) == 2
    chkbox = tabledata{eventdata.Indices(1,1),4};
    if isempty(chkbox), chkbox = false; end
    if chkbox == false
        catname = tabledata{eventdata.Indices(1,1),1};
        liststr = handles.nodeA.(genvarname(catname));
        if size(liststr,1) < size(liststr,2), liststr = liststr'; end
        if ~iscellstr(liststr) && ~isnumeric(liststr), liststr = cellstr(num2str(cell2mat(liststr)));
        elseif isnumeric(liststr), liststr = cellstr(num2str(liststr)); end
        [sel,ok] = listdlg('ListString',liststr,'InitialValue',str2num(tabledata{eventdata.Indices(1),eventdata.Indices(2)})); %#ok : necessary for getting selection vector
        if ok == 1
            logsel = ['[' num2str(sel) ']'];
            tabledata{eventdata.Indices(1),eventdata.Indices(2)} = logsel;
        end
        set(hObject,'Data',{''})
        set(hObject,'Data',tabledata)
        guidata(handles.comparedata,handles)
        doresultplot(handles,handles.compaxes)
    else
        % Possible code to truncate 'continuous' selection
    end
end


% --- Executes when selected cell(s) is changed in cattable2.
function cattable2_CellSelectionCallback(hObject, eventdata, handles) %#ok : Executed when a cell is selected in the lower table
% hObject    handle to cattable2 (see GCBO)
% eventdata  structure with the following fields (see UITABLE)
%	Indices: row and column indices of the cell(s) currently selecteds
% handles    structure with handles and user data (see GUIDATA)
tabledata = get(hObject,'Data');
if size(eventdata.Indices,1) ~= 0 && eventdata.Indices(1,2) == 2
    chkbox = tabledata{eventdata.Indices(1,1),4};
    if isempty(chkbox), chkbox = false; end
    if chkbox == false
        catname = tabledata{eventdata.Indices(1,1),1};
        liststr = handles.nodeB.(genvarname(catname));
        if size(liststr,1) < size(liststr,2), liststr = liststr'; end
        if ~iscellstr(liststr) && ~isnumeric(liststr), liststr = cellstr(num2str(cell2mat(liststr)));
        elseif isnumeric(liststr), liststr = cellstr(num2str(liststr)); end
        [sel,ok] = listdlg('ListString',liststr,'InitialValue',str2num(tabledata{eventdata.Indices(1),eventdata.Indices(2)})); %#ok : necessary for getting selection vector
        if ok == 1
            logsel = ['[' num2str(sel) ']'];
            tabledata{eventdata.Indices(1),eventdata.Indices(2)} = logsel;
        end
        set(hObject,'Data',{''})
        set(hObject,'Data',tabledata)
        guidata(handles.comparedata,handles)
        doresultplot(handles,handles.compaxes)
    else
        % Possible code to truncate 'continuous' selection
    end
end


% --- Executes when entered data in editable cell(s) in cattable1.
function cattable1_CellEditCallback(hObject, eventdata, handles) %#ok : Executed when a cell is edited in the upper table
% hObject    handle to cattable1 (see GCBO)
% eventdata  structure with the following fields (see UITABLE)
%	Indices: row and column indices of the cell(s) edited
%	PreviousData: previous data for the cell(s) edited
%	EditData: string(s) entered by the user
%	NewData: EditData or its converted form set on the Data property. Empty if Data was not changed
%	Error: error string when failed to convert EditData to appropriate value for Data
% handles    structure with handles and user data (see GUIDATA)
if size(eventdata.Indices,1) ~= 0 && eventdata.Indices(1,2) == 4
    tabledata = get(hObject,'Data');
    catorcont = tabledata(:,4);
    naxis = length(find([catorcont{:}] == true));
    if naxis < 3 && naxis >=1
        if islogical(catorcont{eventdata.Indices(1,1),1}) && catorcont{eventdata.Indices(1,1),1} == true
            tabledata{eventdata.Indices(1,1),2} = ':';
        else
            tabledata{eventdata.Indices(1,1),2} = '[1]';
        end
        set(hObject,'Data',tabledata);
        setplottingoptions(handles)
        doresultplot(handles,handles.compaxes)
    else
        set(hObject,'Data',handles.tabledata1);
        doresultplot(handles,handles.compaxes)
    end
end


% --- Executes when entered data in editable cell(s) in cattable2.
function cattable2_CellEditCallback(hObject, eventdata, handles) %#ok : Executed when a cell is edited in the lower table
% hObject    handle to cattable2 (see GCBO)
% eventdata  structure with the following fields (see UITABLE)
%	Indices: row and column indices of the cell(s) edited
%	PreviousData: previous data for the cell(s) edited
%	EditData: string(s) entered by the user
%	NewData: EditData or its converted form set on the Data property. Empty if Data was not changed
%	Error: error string when failed to convert EditData to appropriate value for Data
% handles    structure with handles and user data (see GUIDATA)
if size(eventdata.Indices,1) ~= 0 && eventdata.Indices(1,2) == 4
    tabledata = get(hObject,'Data');
    catorcont = tabledata(:,4);
    naxis = length(find([catorcont{:}] == true));
    if naxis < 3 && naxis >=1
        if islogical(catorcont{eventdata.Indices(1,1),1}) && catorcont{eventdata.Indices(1,1),1} == true
            tabledata{eventdata.Indices(1,1),2} = ':';
        else
            tabledata{eventdata.Indices(1,1),2} = '[1]';
        end
        set(hObject,'Data',tabledata);
        setplottingoptions(handles)
        doresultplot(handles,handles.compaxes)
    else
        set(hObject,'Data',handles.tabledata2);
        doresultplot(handles,handles.compaxes)
    end
end

function setplottingoptions(handles)
    cattable1 = get(handles.cattable1,'Data');
    cattable2 = get(handles.cattable2,'Data');
    catorcontA = cattable1(:,4);
    if any(cellfun(@isempty,catorcontA)), catorcontA(cellfun(@isempty,catorcontA)) = {false}; end
    mainaxA = find([catorcontA{:}] == true);
    catorcontB = cattable2(:,4);
    if any(cellfun(@isempty,catorcontB)), catorcontB(cellfun(@isempty,catorcontB)) = {false}; end
    mainaxB = find([catorcontB{:}] == true);
    iunitsA = handles.nodeA.(genvarname([cattable1{mainaxA(1,1),1} 'info'])).units;
    iunitsB = handles.nodeB.(genvarname([cattable2{mainaxB(1,1),1} 'info'])).units;
    if strcmp(iunitsA,iunitsB) && length(handles.nodeA.(genvarname(cattable1{mainaxA(1,1),1}))) == length(handles.nodeB.(genvarname(cattable2{mainaxB(1,1),1})))
        set(handles.compfunc_popup,'String',{'Double axis','Two Y axis','X-Y'},'Value',1)
    elseif strcmp(iunitsA,iunitsB)
        set(handles.compfunc_popup,'String',{'Double axis','Two Y axis'},'Value',1)
    else
        set(handles.compfunc_popup,'String',{'Double axis'},'Value',1)
    end
    if length(mainaxA) == 2 && length(mainaxB) == 2
        iunitsA2 = handles.nodeA.(genvarname([cattable1{mainaxA(1,2),1} 'info'])).units;
        iunitsB2 = handles.nodeB.(genvarname([cattable2{mainaxB(1,2),1} 'info'])).units;
        hasunitsA = strfind(handles.nodeA.datainfo.units,'[');
        if ~isempty(hasunitsA)
            dataunitsA = handles.nodeA.datainfo.units(strfind(handles.nodeA.datainfo.units,'[')+1:strfind(handles.nodeA.datainfo.units,']')-1);
        end
        hasunitsB = strfind(handles.nodeB.datainfo.units,'[');
        if ~isempty(hasunitsB)
            dataunitsB = handles.nodeB.datainfo.units(strfind(handles.nodeB.datainfo.units,'[')+1:strfind(handles.nodeB.datainfo.units,']')-1);
        end
        if strcmp(iunitsA,iunitsB) && strcmp(iunitsA2,iunitsB2) &&...
                isequal(handles.nodeA.(genvarname(cattable1{mainaxA(1,1),1})),handles.nodeB.(genvarname(cattable1{mainaxB(1,1),1}))) &&...
                isequal(handles.nodeA.(genvarname(cattable1{mainaxA(1,2),1})),handles.nodeB.(genvarname(cattable1{mainaxB(1,2),1})))
            if ~isempty(hasunitsA) && ~isempty(hasunitsB) && strcmp(dataunitsA,'dB') && strcmp(dataunitsB,'dB')
                set(handles.compfunc_popup,'String',cat(1,get(handles.compfunc_popup,'String'),{'difference'}))
            else
                set(handles.compfunc_popup,'String',cat(1,get(handles.compfunc_popup,'String'),{'difference - log10';'difference - log2';'difference - 10*log10'}))
            end
        end
    end


% --- Executes on mouse press over figure background, over a disabled or
% --- inactive control, or over an axes background.
function comparedata_WindowButtonDownFcn(hObject, ~, handles) %#ok : Executed when clicking on axis
% hObject    handle to comparedata (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
click = get(hObject,'CurrentObject');
if ~isempty(click) && ((click == handles.compaxes) || (get(click,'Parent') == handles.compaxes) || (click == handles.compaxes2) || (get(click,'Parent') == handles.compaxes2)) && ~strcmp(get(click,'Type'),'text')
    figure;
    haxes = axes;
    doresultplot(handles,haxes)
end
if strcmp(get(click,'Type'),'text')
    if click == get(get(click,'Parent'),'Xlabel')
        if strcmp(get(get(click,'Parent'),'XScale'),'linear')
            set(get(click,'Parent'),'XScale','log')
        else
            set(get(click,'Parent'),'XScale','linear')
        end
    end
    if click == get(get(click,'Parent'),'Ylabel')
        if strcmp(get(get(click,'Parent'),'YScale'),'linear')
            set(get(click,'Parent'),'YScale','log')
        else
            set(get(click,'Parent'),'YScale','linear')
        end
    end
end

function cmap = obb_cmap(cmin,cmax)
if isinf(cmax), cmax = 10^10; end
if isinf(cmin), cmin = -10^10; end
x = linspace(cmin,cmax,64);
r1 = zeros(1,length(x(x<0)));
r2 = 1.7/cmax.*x(x>0 & x<cmax/2);
r3 = 0.3/cmax.*x(x>cmax/2)+0.7;
R = [r1,r2,r3];

g1 = 1.32/cmin.*x(x<cmin/2)-0.52;
g2 = 0.28/cmin.*x(x<0 & x>cmin/2);
g3 = 0.28/cmax.*x(x>0 & x<cmax/2);
g4 = 1.32/cmax.*x(x>cmax/2)-0.52;
G = [g1,g2,g3,g4];

b1 = 0.8/cmin.*x(x<0);
b2 = zeros(1,length(x(x>0)));
B = [b1,b2];

cmap = [R',G',B'];


% --- Executes on button press in compare_btn.
function compare_btn_Callback(~, ~, handles) %#ok : Executed when compare Compare stats button is clicked
% hObject    handle to compare_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

nodeA = handles.nodeA; %#ok : Used in eval function below
cattable1 = get(handles.cattable1);
selA = strjoin(cattable1.Data(:,2).',',');
if isempty(selA), selA = '[1]'; end
eval(['y1 = squeeze(nodeA.data(' selA '));'])

nodeB = handles.nodeB; %#ok : Used in eval function below
cattable2 = get(handles.cattable2);
selB = strjoin(cattable2.Data(:,2).',',');
if isempty(selB), selB = '[1]'; end
eval(['y2 = squeeze(nodeB.data(' selB '));'])

maxdif = [max(max(y1)),max(max(y2))];
mindif = [min(min(y1)),min(min(y2))];
meandif = [mean(mean(y1)),mean(mean(y2))];
mediandif = [median(median(y1)),median(median(y2))];
stddevdif = [std(std(y1)),std(std(y2))];
skewnessdif = [skewness(skewness(y1)),skewness(skewness(y2))];
kurtosisdif = [kurtosis(kurtosis(y1)),kurtosis(kurtosis(y2))];
statsdif = [maxdif;...
            mindif;...
            meandif;...
            mediandif;...
            stddevdif;...
            skewnessdif;...
            kurtosisdif];
figure;bar(statsdif)
for k = 1:7
    % black number above the bar
    text(k-0.15,statsdif(k,1)+0.2, ...
        num2str(round(statsdif(k,1)*1000)/1000),'Color','k','HorizontalAlignment','center')
end
for k = 1:7
    % black number above the bar
    text(k+0.15,statsdif(k,2)+0.2, ...
        num2str(round(statsdif(k,2)*1000)/1000),'Color','k','HorizontalAlignment','center')
end
set(gca,'XTickLabel',{'Maximum','Minimum','Mean','Median','Standard Deviation','Skewness','Kurtosis'})
legend(strrep(get(handles.name1txt,'String'),'_',' '),strrep(get(handles.name2txt,'String'),'_',' '))