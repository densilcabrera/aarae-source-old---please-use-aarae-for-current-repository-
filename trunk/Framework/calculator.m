% DO NOT EDIT THIS INITIALIZATION FUNCTION!!!!!!!!!!!!!!!!!!!!!!!!!!!
function varargout = calculator(varargin)
% CALCULATOR MATLAB code for calculator.fig
%      CALCULATOR, by itself, creates a new CALCULATOR or raises the existing
%      singleton*.
%
%      H = CALCULATOR returns the handle to a new CALCULATOR or the handle to
%      the existing singleton*.
%
%      CALCULATOR('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in CALCULATOR.M with the given input arguments.
%
%      CALCULATOR('Property','Value',...) creates a new CALCULATOR or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before calculator_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to calculator_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help calculator

% Last Modified by GUIDE v2.5 01-Nov-2013 14:38:55

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @calculator_OpeningFcn, ...
                   'gui_OutputFcn',  @calculator_OutputFcn, ...
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


% --- Executes just before calculator is made visible.
function calculator_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to calculator (see VARARGIN)


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
end


% Update handles structure
guidata(hObject, handles);

if dontOpen
   disp('-----------------------------------------------------');
   disp('Improper input arguments. Pass a property value pair') 
   disp('whose name is "changeme_main" and value is the handle')
   disp('to the changeme_main figure, e.g:');
   disp('   x = changeme_main()');
   disp('   changeme_dialog(''changeme_main'', x)');
   disp('-----------------------------------------------------');
else
   uiwait(hObject);
end


% --- Outputs from this function are returned to the command line.
function varargout = calculator_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = [];
delete(hObject);


% --- Executes on button press in calc_btn.
function calc_btn_Callback(hObject, eventdata, handles)
% hObject    handle to calc_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

mainHandles = guidata(handles.main_stage1);
set(hObject,'BackgroundColor','red');
set(hObject,'Enable','off');
if nargout(handles.funname) == 1
    signaldata = feval(handles.funname);
    if ~isempty(signaldata)
        mainHandles.mytree.setSelectedNode(mainHandles.root);
        if isfield(signaldata,'audio')
            signaldata.nbits = 16;
            iconPath = fullfile(matlabroot,'/toolbox/fixedpoint/fixedpointtool/resources/plot.png');
        else
            iconPath = fullfile(matlabroot,'/toolbox/matlab/icons/notesicon.gif');
        end
        signaldata.datatype = 'results';
        mainHandles.(genvarname(handles.funname)) = uitreenode('v0', handles.funname,  handles.funname,  iconPath, true);
        mainHandles.(genvarname(handles.funname)).UserData = signaldata;
        mainHandles.results.add(mainHandles.(genvarname(handles.funname)));
        mainHandles.mytree.reloadNode(mainHandles.results);
        mainHandles.mytree.expand(mainHandles.results);
        mainHandles.mytree.setSelectedNode(mainHandles.(genvarname(handles.funname)));
        fprintf(mainHandles.fid, [' ' datestr(now,16) ' - Used calculator ' handles.funname '\n']);
    end
else
    feval(handles.funname);
end
set(hObject,'BackgroundColor',[0.94 0.94 0.94]);
set(hObject,'Enable','on');
h = findobj('type','figure','-not','tag','aarae','-not','tag','calculators');
aarae_fig = findobj('type','figure','tag','aarae');
index = 1;
filename = dir([cd '/Utilities/Temp/' handles.funname num2str(index) '.fig']);
if ~isempty(filename)
    while isempty(dir([cd '/Utilities/Temp/' handles.funname num2str(index) '.fig'])) == 0
        index = index + 1;
    end
end
for i = 1:length(h)
    saveas(h(i),[cd '/Utilities/Temp/' handles.funname num2str(index) '.fig']);
    index = index + 1;
end
results = dir([cd '/Utilities/Temp']);
set(mainHandles.result_box,'String',[' ';cellstr({results(3:length(results)).name}')]);
guidata(aarae_fig, mainHandles);
guidata(hObject, handles);


% --- Executes on button press in close_btn.
function close_btn_Callback(hObject, eventdata, handles)
% hObject    handle to close_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
uiresume(handles.calculators);


% --- Executes when user attempts to close calculator.
function calculators_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to calculator (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
uiresume(hObject);


% --- Executes on selection change in signalcat_box.
function signalcat_box_Callback(hObject, eventdata, handles)
% hObject    handle to signalcat_box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns signalcat_box contents as cell array
%        contents{get(hObject,'Value')} returns selected item from signalcat_box

% Displays the available calculators for the selected processing category
contents = cellstr(get(hObject,'String'));
calccat = contents{get(hObject,'Value')};
calculators = what([cd '/Calculators/' calccat]);
if ~isempty(cellstr(calculators.m))
    set(handles.signal_box,'Visible','on','String',[' ';cellstr(calculators.m)],'Value',1,'Tooltip','');
    set(handles.calc_btn,'Visible','off');
else
    set(handles.signal_box,'Visible','off');
    set(handles.calc_btn,'Visible','off');
end
guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function signalcat_box_CreateFcn(hObject, eventdata, handles)
% hObject    handle to signalcat_box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% Populate function box with the function available in the folder 'Calculators'
curdir = cd;
signals = dir([curdir '/Calculators']);
set(hObject,'String',[' ';cellstr({signals(3:length(signals)).name}')]);
handles.funname = [];
guidata(hObject,handles)


% --- Executes on selection change in signal_box.
function signal_box_Callback(hObject, eventdata, handles)
% hObject    handle to signal_box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns signal_box contents as cell array
%        contents{get(hObject,'Value')} returns selected item from signal_box
% Allows 'help' display when mouse is hoovered over fun_box
contents = cellstr(get(hObject,'String'));
selection = contents{get(hObject,'Value')};
[~,funname] = fileparts(selection);
if ~strcmp(selection,' ')
    handles.funname = funname;
    helptext = evalc(['help ' funname]);
    set(hObject,'Tooltip',helptext);
    set(handles.calc_btn,'Visible','on');
else
    handles.funname = [];
    set(hObject,'Tooltip','');
    set(handles.calc_btn,'Visible','off');
end
guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function signal_box_CreateFcn(hObject, eventdata, handles)
% hObject    handle to signal_box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
