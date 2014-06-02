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

% Last Modified by GUIDE v2.5 08-May-2014 16:22:38

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
function genaudio_OpeningFcn(hObject, ~, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to genaudio (see VARARGIN)


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

% Initialize signal parameters
handles.cycles = 1;
handles.signaldata = [];
handles.newleaf = [];
axis([0 10 -1 1]); xlabel('Time [s]');
% Update handles structure
guidata(hObject, handles);

if dontOpen
   disp('-----------------------------------------------------');
   disp('This function is part of the AARAE framework, it is') 
   disp('not a standalone function. To call this function,')
   disp('click on the appropriate calling button on the main');
   disp('Window. E.g.:');
   disp('   New signal');
   disp('-----------------------------------------------------');
else
   uiwait(hObject);
end


% --- Outputs from this function are returned to the command line.
function varargout = genaudio_OutputFcn(hObject, ~, handles) 
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
function gen_btn_Callback(hObject, ~, handles) %#ok : Executed when Generate button is clicked
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
    silence_check = get(handles.silence_chk','Value');
    if handles.cycles > 1 || silence_check == 1
        numchannels = size(handles.signaldata.audio,2);
        levelrange = linspace(abs(str2double(get(handles.levelrange_IN,'String'))).*-1,0,handles.cycles);
        cycles = handles.cycles;
        scdur = length(handles.signaldata.audio) + handles.signaldata.fs;
        handles.signaldata.properties.startflag = ((0:cycles-1)*scdur)+1;
        audio = zeros(scdur*cycles,numchannels);
        for i = 1:cycles
            chunk = [handles.signaldata.audio;zeros(handles.signaldata.fs,numchannels)];
            audio(handles.signaldata.properties.startflag(i):handles.signaldata.properties.startflag(i)+length(chunk)-1,:) = chunk.*10.^(levelrange(i)/20);
        end
        if silence_check == 1
            cycles = cycles + 1;
            levelrange = [-Inf levelrange];
            audio = [zeros(scdur,numchannels);audio];
            handles.signaldata.properties.startflag = ((0:cycles-1)*scdur)+1;
        end
        handles.signaldata.audio = audio;
        handles.signaldata.properties.relgain = levelrange(1,:);
    end
    if ~isfield(handles.signaldata,'chanID')
        handles.signaldata.chanID = cellstr([repmat('Chan',size(handles.signaldata.audio,2),1) num2str((1:size(handles.signaldata.audio,2))')]);
    end
    duration = length(handles.signaldata.audio)/handles.signaldata.fs;
    time = linspace(0,duration,length(handles.signaldata.audio));
    pixels = get_axes_width(gca);
    line = real(handles.signaldata.audio);
    [time, line] = reduce_to_width(time', line, pixels, [-inf inf]);
    plot(time,line); % Plot the generated signal
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
function OK_Btn_Callback(hObject, ~, handles) %#ok : Executed when OK button is clicked
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
function Cancel_Btn_Callback(~, ~, handles) %#ok : Executed when Cancel button is clicked
% hObject    handle to Cancel_Btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
uiresume(handles.genaudio);


% --- Executes when user attempts to close genaudio.
function genaudio_CloseRequestFcn(hObject, ~, ~) %#ok : Executed upon window close request
% hObject    handle to genaudio (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
uiresume(hObject);


function IN_cycles_Callback(hObject, ~, handles) %#ok : Executed when number of cycles input box changes
% hObject    handle to IN_cycles (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get number of cycles input
cycles = str2double(get(handles.IN_cycles, 'string'));

% Check user's input
if (isnan(cycles)||cycles<=0)
    set(hObject,'String',num2str(handles.cycles));
    warndlg('All inputs MUST be real positive numbers!');
else
    handles.cycles = cycles;
    if cycles > 1
        set([handles.levelrange_IN,handles.text15,handles.text16],'Visible','on')
    else
        set([handles.levelrange_IN,handles.text15,handles.text16],'Visible','off')
    end
end
guidata(hObject, handles);
% Hints: get(hObject,'String') returns contents of IN_cycles as text
%        str2double(get(hObject,'String')) returns contents of IN_cycles as a double


% --- Executes during object creation, after setting all properties.
function IN_cycles_CreateFcn(hObject, ~, ~) %#ok : Number of cycles input box creation
% hObject    handle to IN_cycles (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in signalcat_box.
function signalcat_box_Callback(hObject, ~, handles) %#ok : Executed when category box selection changes
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
function signalcat_box_CreateFcn(hObject, ~, handles) %#ok : Signal generator categories selection box creation
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
function signal_box_Callback(hObject, ~, handles) %#ok : Executed when selection changes in the signal selection box
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
function signal_box_CreateFcn(hObject, ~, ~) %#ok : Signal selection box creation
% hObject    handle to signal_box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in device_popup.
function device_popup_Callback(hObject, ~, handles) %#ok : Executed when output device selection changes
% hObject    handle to device_popup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns device_popup contents as cell array
%        contents{get(hObject,'Value')} returns selected item from device_popup

selection = get(hObject,'Value');
handles.odeviceid = handles.odeviceidlist(selection);
guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function device_popup_CreateFcn(hObject, ~, handles) %#ok : Output device selection menu creation
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
function play_btn_Callback(hObject, ~, handles) %#ok : Executed when play button is clicked
% hObject    handle to play_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if isempty(handles.signaldata)
    warndlg('No signal loaded!');
else
    % Retrieve information from the selected leaf
    testsignal = real(handles.signaldata.audio);
    if size(testsignal,2) > 2, testsignal = mean(testsignal,2); end
    if size(testsignal,3) > 1, testsignal = sum(testsignal,3); end
    testsignal = testsignal./max(abs(testsignal));
    fs = handles.signaldata.fs;
    nbits = 16;
    doesSupport = audiodevinfo(0, handles.odeviceid, fs, nbits, size(testsignal,2));
    if doesSupport && ismatrix(testsignal)
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
function stop_btn_Callback(hObject, ~, handles) %#ok : Executed when stop button in clicked
% hObject    handle to stop_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if isplaying(handles.player)
    stop(handles.player);
end
guidata(hObject,handles);



function levelrange_IN_Callback(~, ~, ~) %#ok : Executed when level range input box changes
% hObject    handle to levelrange_IN (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of levelrange_IN as text
%        str2double(get(hObject,'String')) returns contents of levelrange_IN as a double


% --- Executes during object creation, after setting all properties.
function levelrange_IN_CreateFcn(hObject, ~, ~) %#ok : Level range input box creation
% hObject    handle to levelrange_IN (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in silence_chk.
function silence_chk_Callback(~, ~, ~) %#ok : Executed when add silence cycle checkbox changes
% hObject    handle to silence_chk (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of silence_chk
