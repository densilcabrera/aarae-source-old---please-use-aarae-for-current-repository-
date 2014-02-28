% DO NOT EDIT THIS INITIALIZATION FUNCTION!!!!!!!!!!!!!!!!!!!!!!!!!!!
function varargout = genaudio(varargin)
% GENAUDIO MATLAB code for genaudio.fig
%      GENAUDIO, by itself, creates a new GENAUDIO or raises the existing
%      singleton*.
%
%      H = GENAUDIO returns the handle to a new GENAUDIO or the handle to
%      the existing singleton*.
%
%      GENAUDIO('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in GENAUDIO.M with the given input arguments.
%
%      GENAUDIO('Property','Value',...) creates a new GENAUDIO or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before genaudio_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to genaudio_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help genaudio

% Last Modified by GUIDE v2.5 04-Feb-2014 09:49:56

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @genaudio_OpeningFcn, ...
                   'gui_OutputFcn',  @genaudio_OutputFcn, ...
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


% --- Executes just before genaudio is made visible.
function genaudio_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to genaudio (see VARARGIN)

axis([0 10 -1 1]); xlabel('Time [s]');
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
        aarae = findobj('tag','aarae');
        aaraechildren = get(aarae,'Children');
        for i = 1:length(aaraechildren)
            if ~isempty(get(aaraechildren(i),'tag'))
                set(aaraechildren(i),'FontSize',10)
            end
        end
    end
end

% Initialize signal parameters
handles.cycles = 1;
handles.signaldata = [];
handles.newleaf = [];
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
function varargout = genaudio_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
if ~isempty(handles.signaldata)
    if isfield(handles.signaldata,'tag')
        handles.newleaf = handles.signaldata.tag;
    else
        handles.newleaf = 'Audio signal';
    end
end
varargout{1} = handles.newleaf;
delete(hObject);


% --- Executes on button press in gen_btn.
function gen_btn_Callback(hObject, eventdata, handles)
% hObject    handle to gen_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

set(hObject,'BackgroundColor','red');
set(hObject,'Enable','off');
handles.signaldata = feval(handles.funname);
set(hObject,'BackgroundColor',[0.94 0.94 0.94]);
set(hObject,'Enable','on');

if ~isempty(handles.signaldata)
    set(handles.OK_Btn,'Enable','on')
    if handles.cycles > 1
        handles.signaldata.audio = [handles.signaldata.audio;zeros(handles.signaldata.fs,1)];
        handles.signaldata.audio = repmat(handles.signaldata.audio,handles.cycles,1);
    end
    if ~isfield(handles.signaldata,'chanID')
        handles.signaldata.chanID = cellstr([repmat('Chan',size(handles.signaldata.audio,2),1) num2str((1:size(handles.signaldata.audio,2))')]);
    end
    duration = length(handles.signaldata.audio)/handles.signaldata.fs;
    time = linspace(0,duration,length(handles.signaldata.audio));
    plot(time,handles.signaldata.audio); % Plot the generated signal
    xlabel('Time [s]');
    set(handles.axes1,'XTickLabel',num2str(get(handles.axes1,'XTick').'))
    set(handles.play_btn,'Enable','on')
else
    plot(0,0)
    xlabel('Time [s]');
    axis([0 10 -1 1]);
    set(handles.axes1,'XTickLabel',num2str(get(handles.axes1,'XTick').'))
end
guidata(hObject, handles);

% --- Executes on button press in OK_Btn.
function OK_Btn_Callback(hObject, eventdata, handles)
% hObject    handle to OK_Btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Call the 'desktop'
hMain = getappdata(0,'hMain');
% Check if there was a signal generated
if isempty(handles.signaldata)
    warndlg('No signal generated!');
else
    % Save the generated signal to the desktop
    setappdata(hMain,'testsignal',handles.signaldata);
    if isfield(handles.signaldata,'audio2')
        h = msgbox('Companion signal loaded into audio2','AARAE info','modal');
        uiwait(h);
    end
end
guidata(hObject,handles);
uiresume(handles.genaudio);


% --- Executes on button press in Cancel_Btn.
function Cancel_Btn_Callback(hObject, eventdata, handles)
% hObject    handle to Cancel_Btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
uiresume(handles.genaudio);


% --- Executes when user attempts to close genaudio.
function genaudio_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to genaudio (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
uiresume(hObject);


function IN_cycles_Callback(hObject, eventdata, handles)
% hObject    handle to IN_cycles (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get number of cycles input
cycles = str2num(get(handles.IN_cycles, 'string'));

% Check user's input
if (isempty(cycles)||cycles<=0)
    set(hObject,'String',num2str(handles.cycles));
    warndlg('All inputs MUST be real positive numbers!');
else
    handles.cycles = cycles;
end
guidata(hObject, handles);
% Hints: get(hObject,'String') returns contents of IN_cycles as text
%        str2double(get(hObject,'String')) returns contents of IN_cycles as a double


% --- Executes during object creation, after setting all properties.
function IN_cycles_CreateFcn(hObject, eventdata, handles)
% hObject    handle to IN_cycles (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in signalcat_box.
function signalcat_box_Callback(hObject, eventdata, handles)
% hObject    handle to signalcat_box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns signalcat_box contents as cell array
%        contents{get(hObject,'Value')} returns selected item from signalcat_box

% Displays the available analysers for the selected processing category
contents = cellstr(get(hObject,'String'));
signalcat = contents{get(hObject,'Value')};
signals = what([cd '/Generators/' signalcat]);
if ~isempty(cellstr(signals.m))
    set(handles.signal_box,'Visible','on','String',[' ';cellstr(signals.m)],'Value',1,'Tooltip','');
    set(handles.gen_btn,'Visible','off');
else
    set(handles.signal_box,'Visible','off');
    set(handles.gen_btn,'Visible','off');
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

% Populate function box with the function available in the folder 'Analysis'
curdir = cd;
signals = dir([curdir '/Generators']);
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
    set(handles.gen_btn,'Visible','on');
else
    handles.funname = [];
    set(hObject,'Tooltip','');
    set(handles.gen_btn,'Visible','off');
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


% --- Executes on selection change in device_popup.
function device_popup_Callback(hObject, eventdata, handles)
% hObject    handle to device_popup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns device_popup contents as cell array
%        contents{get(hObject,'Value')} returns selected item from device_popup

selection = get(hObject,'Value');
handles.odeviceid = handles.odeviceidlist(selection);
guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function device_popup_CreateFcn(hObject, eventdata, handles)
% hObject    handle to device_popup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

devinfo = audiodevinfo; % Get available device information
odevicelist = {devinfo.output.Name}; % Populate list
handles.odeviceidlist =  cell2mat({devinfo.output.ID});
handles.odeviceid = handles.odeviceidlist(1,1);
set(hObject,'String',odevicelist);
guidata(hObject,handles);


% --- Executes on button press in play_btn.
function play_btn_Callback(hObject, eventdata, handles)
% hObject    handle to play_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if isempty(handles.signaldata)
    warndlg('No signal loaded!');
else
    % Retrieve information from the selected leaf
    testsignal = handles.signaldata.audio;
    if size(testsignal,2) > 2, testsignal = mean(testsignal,2); end
    if size(testsignal,3) > 1, testsignal = sum(testsignal,3); end
    testsignal = testsignal./max(abs(testsignal));
    fs = handles.signaldata.fs;
    nbits = 16;
    doesSupport = audiodevinfo(0, handles.odeviceid, fs, nbits, size(testsignal,2));
    if doesSupport && ndims(testsignal) < 3
        % Play signal
        handles.player = audioplayer(testsignal,fs,nbits,handles.odeviceid);
        play(handles.player);
        set(handles.stop_btn,'Visible','on');
    else
        warndlg('Device not supported for playback!');
    end
end
guidata(hObject, handles);

% --- Executes on button press in stop_btn.
function stop_btn_Callback(hObject, eventdata, handles)
% hObject    handle to stop_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if isplaying(handles.player)
    stop(handles.player);
end
guidata(hObject,handles);
