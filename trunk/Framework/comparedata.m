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

% Last Modified by GUIDE v2.5 10-Jul-2014 10:03:44

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
    selectedNodes = mainHandles.mytree.getSelectedNodes;
    handles.nodeA = selectedNodes(1).handle.UserData;
    handles.nodeB = selectedNodes(2).handle.UserData;
    set(handles.name1txt,'String',selectedNodes(1).getName.char)
    set(handles.name2txt,'String',selectedNodes(2).getName.char)
    filltable(handles.nodeA,handles.cattable1)
    filltable(handles.nodeB,handles.cattable2)
    setplottingoptions(handles)
    doresultplot(handles)
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
doresultplot(handles)

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


function doresultplot(handles)
cla(handles.compaxes,'reset')
if isfield(handles,'compaxes2')
    delete(handles.compaxes2);
    handles = rmfield(handles,'compaxes2');
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
            line(x1,y1,'Parent',handles.compaxes)
            set(handles.compaxes,'XColor','b','YColor','b')
            compaxes_pos = get(handles.compaxes,'Position');
            handles.compaxes2 = axes(...
                'Units','characters',...
                'Position',compaxes_pos,...
                'XAxisLocation','top',...
                'YAxisLocation','right',...
                'Color','none',...
                'XColor','r',...
                'YColor','r',...
                'ColorOrder',colormap(hsv(size(y2,2))),...
                'Parent',handles.comparedata);
            line(x2,y2,'Parent',handles.compaxes2)
            xlabel(handles.compaxes,strrep([cattable1.Data{mainaxA(1,1),1} ' [' nodeA.(genvarname([cattable1.Data{mainaxA(1,1),1} 'info'])).units ']'],'_',' '))
            xlabel(handles.compaxes2,strrep([cattable2.Data{mainaxB(1,1),1} ' [' nodeB.(genvarname([cattable2.Data{mainaxB(1,1),1} 'info'])).units ']'],'_',' '))
            ylabel(handles.compaxes,strrep(nodeA.datainfo.units,'_',' '))
            ylabel(handles.compaxes2,strrep(nodeB.datainfo.units,'_',' '))
            set(handles.name1txt,'ForegroundColor','b')
            set(handles.name2txt,'ForegroundColor','r')
        case 'Two Y axis'
            ax = plotyy(x1,y1,x2,y2);
            xlabel(handles.compaxes,strrep(['Units: [' nodeA.(genvarname([cattable1.Data{mainaxA(1,1),1} 'info'])).units ']'],'_',' '))
            ylabel(ax(1),strrep(nodeA.datainfo.units,'_',' '))
            ylabel(ax(2),strrep(nodeB.datainfo.units,'_',' '))
            set(handles.name1txt,'ForegroundColor',get(ax(1),'YColor'))
            set(handles.name2txt,'ForegroundColor',get(ax(2),'YColor'))
        case 'X-Y'
            plot(handles.compaxes,y1,y2,'ro')
            xlabel(handles.compaxes,strrep(nodeA.datainfo.units,'_',' '))
            ylabel(handles.compaxes,strrep(nodeB.datainfo.units,'_',' '))
            set(handles.name1txt,'ForegroundColor','k')
            set(handles.name2txt,'ForegroundColor','k')
    end
    guidata(handles.comparedata,handles)
catch error
    cla(handles.compaxes,'reset')
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
        doresultplot(handles)
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
        doresultplot(handles)
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
        doresultplot(handles)
    else
        set(hObject,'Data',handles.tabledata1);
        doresultplot(handles)
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
        doresultplot(handles)
    else
        set(hObject,'Data',handles.tabledata2);
        doresultplot(handles)
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
