function varargout = syscal(varargin)
% SYSCAL MATLAB code for syscal.fig
%      SYSCAL, by itself, creates a new SYSCAL or raises the existing
%      singleton*.
%
%      H = SYSCAL returns the handle to a new SYSCAL or the handle to
%      the existing singleton*.
%
%      SYSCAL('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SYSCAL.M with the given input arguments.
%
%      SYSCAL('Property','Value',...) creates a new SYSCAL or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before syscal_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to syscal_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help syscal

% Last Modified by GUIDE v2.5 20-Feb-2014 19:48:07

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @syscal_OpeningFcn, ...
                   'gui_OutputFcn',  @syscal_OutputFcn, ...
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


% --- Executes just before syscal is made visible.
function syscal_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to syscal (see VARARGIN)

% This next couple of lines checks if the GUI is being called from the main
% window, otherwise it doesn't run.
dontOpen = false;
mainGuiInput = find(strcmp(varargin, 'audio_recorder'));
if (isempty(mainGuiInput)) ...
    || (length(varargin) <= mainGuiInput) ...
    || (~ishandle(varargin{mainGuiInput+1}))
    dontOpen = true;
else
    % Remember the handle, and adjust our position
    handles.main_stage1 = varargin{mainGuiInput+1};
end

if dontOpen
    disp('-----------------------------------------------------');
    disp('Improper input arguments. Pass a property value pair') 
    disp('whose name is "changeme_main" and value is the handle')
    disp('to the changeme_main figure, e.g:');
    disp('   x = changeme_main()');
    disp('   changeme_dialog(''changeme_main'', x)');
    disp('-----------------------------------------------------');
else
    handles.mainHandles = guidata(handles.main_stage1);
    handles.hap = dsp.AudioPlayer('SampleRate',handles.mainHandles.fs,'QueueDuration',.1,'BufferSizeSource','Property','BufferSize',128);
    handles.har = dsp.AudioRecorder('SampleRate',handles.mainHandles.fs,'OutputDataType','double','NumChannels',1,'BufferSizeSource','Property','BufferSize',128);
    handles.hsr1 = dsp.SignalSource;
    handles.hsr1.SamplesPerFrame = 1024;
    set(handles.duration_IN,'String','10')
    set(handles.sperframe_IN,'String',num2str(handles.mainHandles.fs*0.1))
    set(handles.percentage_IN,'String','0.4')
    set(handles.threshold_IN,'String','0.2')
    set(handles.tonelevel_IN,'String','94')
    stats{1} = ['Sampling frequency: ' num2str(handles.mainHandles.fs) ' samples/s'];
    set(handles.statstext,'String',stats);
    UserData.state = false;
    set(handles.stop_btn,'UserData',UserData);
    handles.output = struct;
    guidata(hObject, handles);
    uiwait(hObject);
end

% UIWAIT makes syscal wait for user response (see UIRESUME)
% uiwait(handles.syscal);


% --- Outputs from this function are returned to the command line.
function varargout = syscal_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
delete(hObject);


% --- Executes on button press in load_btn.
function load_btn_Callback(hObject, eventdata, handles)
% hObject    handle to load_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[handles.audio,handles.fs] = audioread('0deg_002.wav');
plot(handles.dispaxes,handles.audio)
xlabel(handles.dispaxes,'Time [s]');
set(handles.filter_panel,'Visible','on')
guidata(hObject,handles)


function sperframe_IN_Callback(hObject, eventdata, handles)
% hObject    handle to sperframe_IN (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of sperframe_IN as text
%        str2double(get(hObject,'String')) returns contents of sperframe_IN as a double


% --- Executes during object creation, after setting all properties.
function sperframe_IN_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sperframe_IN (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function percentage_IN_Callback(hObject, eventdata, handles)
% hObject    handle to percentage_IN (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of percentage_IN as text
%        str2double(get(hObject,'String')) returns contents of percentage_IN as a double


% --- Executes during object creation, after setting all properties.
function percentage_IN_CreateFcn(hObject, eventdata, handles)
% hObject    handle to percentage_IN (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function threshold_IN_Callback(hObject, eventdata, handles)
% hObject    handle to threshold_IN (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of threshold_IN as text
%        str2double(get(hObject,'String')) returns contents of threshold_IN as a double


% --- Executes during object creation, after setting all properties.
function threshold_IN_CreateFcn(hObject, eventdata, handles)
% hObject    handle to threshold_IN (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in evalcal_btn.
function evalcal_btn_Callback(hObject, eventdata, handles)
% hObject    handle to evalcal_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(hObject,'BackgroundColor','red');
set(hObject,'Enable','off');
pause on
pause(0.000001)
pause off
if isfield(handles,'filtaudio')
    if ~isempty(handles.filtaudio)
        data = handles.filtaudio;
    else
        data = handles.audio;
    end
else
    data = handles.audio;
end
envelope = abs(hilbert(data));
hsr1 = dsp.SignalSource;
hsr1.Signal = envelope;
hsr1.SamplesPerFrame = str2double(get(handles.sperframe_IN,'String'));
rec = [];
percentage = str2double(get(handles.percentage_IN,'String'));
threshold = str2double(get(handles.threshold_IN,'String'));
tonelevel = str2double(get(handles.tonelevel_IN,'String'));
while (~isDone(hsr1))
    chunk = step(hsr1);
    chunklevel = trimmean(chunk,percentage);
    if chunklevel > threshold
        rec = [rec;ones(length(chunk),1)];
    else
        rec = [rec;zeros(length(chunk),1)];
    end
end

release(hsr1)
trimdata = data.*rec(1:length(data));
plot(handles.dispaxes,data,'c')
xlabel(handles.dispaxes,'Time [s]');
YLim = get(handles.dispaxes,'YLim');
hold on
plot(handles.dispaxes,trimdata,'b')
plot(handles.dispaxes,(rec(1:length(data)).*10)-5,'Color','r','LineWidth',1)
set(handles.dispaxes,'YLim',YLim)
hold off
trim = find(trimdata);
dur = length(trim)/handles.mainHandles.fs;
trimlevel = tonelevel - 10 .* log10(mean(trimdata(trim).^2,1));
stats{1} = ['Sampling frequency: ' num2str(handles.mainHandles.fs) ' samples/s'];
stats{2} = ['Trimmed recording length: ' num2str(dur) ' s'];
stats{3} = ['Trimmed audio level: ' num2str(trimlevel) ' dB'];
set(handles.statstext,'String',stats);
set(hObject,'BackgroundColor',[0.94 0.94 0.94]);
set(hObject,'Enable','on');
handles.output.cal = trimlevel;
guidata(hObject,handles)


function tonelevel_IN_Callback(hObject, eventdata, handles)
% hObject    handle to tonelevel_IN (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of tonelevel_IN as text
%        str2double(get(hObject,'String')) returns contents of tonelevel_IN as a double


% --- Executes during object creation, after setting all properties.
function tonelevel_IN_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tonelevel_IN (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in stimulus_popup.
function stimulus_popup_Callback(hObject, eventdata, handles)
% hObject    handle to stimulus_popup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns stimulus_popup contents as cell array
%        contents{get(hObject,'Value')} returns selected item from stimulus_popup


% --- Executes during object creation, after setting all properties.
function stimulus_popup_CreateFcn(hObject, eventdata, handles)
% hObject    handle to stimulus_popup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in evaldelay_btn.
function evaldelay_btn_Callback(hObject, eventdata, handles)
% hObject    handle to evaldelay_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

set(hObject,'BackgroundColor','red');
set(hObject,'Enable','off');
pause on
pause(0.000001)
pause off
stimulus = get(handles.stimulus_popup,'Value');
switch stimulus
    case 1
        S = impulse1(0,1,1,handles.mainHandles.fs);
        handles.hsr1.Signal = S.audio;
    case 2
        S = linear_sweep(1,20,20000,handles.mainHandles.fs);
        handles.hsr1.Signal = S.audio;
    case 3
        S = noise(-1,1,handles.mainHandles.fs,20,20000,1,1,0);
        handles.hsr1.Signal = S.audio;
end
handles.hsr1.Signal = [handles.hsr1.Signal;zeros(length(handles.hsr1.Signal),1)];
try
    rec = [];
    while (~isDone(handles.hsr1))
       audio = step(handles.har);
       step(handles.hap,step(handles.hsr1));
       rec = [rec;audio];
    end
catch sthgwrong
    syswarning = sthgwrong.message;
    warndlg(syswarning,'AARAE info')
end
if ~isempty(rec)
    Txy = tfestimate(handles.hsr1.Signal,rec(1:length(handles.hsr1.Signal)),[],[],[],handles.mainHandles.fs);
    ixy = ifft(Txy,length(Txy)*2);
    %plot(real(ixy))
    [~,I] = max(abs(ixy));
    I = (I-(handles.mainHandles.fs*handles.hap.QueueDuration));%/handles.mainHandles.fs;
    set(handles.latencytext,'String',['System Latency: ' num2str(I) ' samples']);
    handles.output.latency = I;
    handles.sysIR = ixy;
end
release(handles.hap)
release(handles.har)
release(handles.hsr1)
set(hObject,'BackgroundColor',[0.94 0.94 0.94]);
set([hObject handles.invfdesign_btn handles.invf_popup handles.invfsmooth_popup handles.invfLF_IN handles.invfHF_IN handles.invfIB_IN handles.invfOB_IN handles.invfnfft_IN handles.invflength_IN],'Enable','on');
guidata(hObject,handles)


% --- Executes on button press in done_btn.
function done_btn_Callback(hObject, eventdata, handles)
% hObject    handle to done_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
uiresume(handles.syscal);


% --- Executes on button press in filter_btn.
function filter_btn_Callback(hObject, eventdata, handles)
% hObject    handle to filter_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(hObject,'BackgroundColor','red');
set(hObject,'Enable','off');
pause on
pause(0.000001)
pause off
filter = get(get(handles.filter_panel,'SelectedObject'),'String');
switch filter
    case 'None'
        handles.filtaudio = [];
    case '1 kHz'
        [handles.filtaudio,~] = thirdoctbandfilter(handles.audio,handles.mainHandles.fs,1000);
    case '250 Hz'
        [handles.filtaudio,~] = thirdoctbandfilter(handles.audio,handles.mainHandles.fs,250);
end
if ~isempty(handles.filtaudio)
    plot(handles.dispaxes,handles.filtaudio)
    xlabel(handles.dispaxes,'Time [s]');
else
    plot(handles.dispaxes,handles.audio)
    xlabel(handles.dispaxes,'Time [s]');
end
set(hObject,'BackgroundColor',[0.94 0.94 0.94]);
set(hObject,'Enable','on');
guidata(hObject,handles)


% --- Executes when user attempts to close syscal.
function syscal_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to syscal (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.output = struct;
guidata(hObject,handles)
% Hint: delete(hObject) closes the figure
uiresume(hObject);


% --- Executes on button press in record_btn.
function record_btn_Callback(hObject, eventdata, handles)
% hObject    handle to record_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set([handles.sperframe_IN,handles.percentage_IN,handles.threshold_IN,handles.tonelevel_IN,handles.evalcal_btn,handles.filter_btn],'Enable','off')
dur = str2double(get(handles.duration_IN,'String'))*handles.mainHandles.fs;
set(hObject,'BackgroundColor','red');
set(hObject,'Enable','off');
set(handles.stop_btn,'Visible','on');
pause on
pause(0.000001)
pause off
% Set record object
% handles.har = dsp.AudioRecorder('SampleRate',handles.mainHandles.fs,'OutputDataType','double','NumChannels',handles.numchs,'BufferSizeSource','Property','BufferSize',128,'QueueDuration',.1);
guidata(hObject,handles)
rec = [];
% Initialize record routine
try
    UserData = get(handles.stop_btn,'UserData');
    while length(rec) < dur
       UserData = get(handles.stop_btn,'UserData');
       if UserData.state == false
           audio = step(handles.har);
           rec = [rec;audio];
       else
           break
       end
       pause on
       pause(0.000001)
       pause off
    end
catch sthgwrong
    UserData.state = true;
    rec = [];
    syswarning = sthgwrong.message;
    warndlg(syswarning,'AARAE info')
end
% Check recording and adjust for Duration
if ~isempty(rec)
    if UserData.state == false
        rec = rec(1:dur);
    else
        UserData.state = false;
        set(handles.stop_btn,'UserData',UserData);
    end
    handles.audio = rec;
    % Plot recording
    time = linspace(0,size(handles.audio,1)/handles.mainHandles.fs,length(handles.audio));
    plot(handles.dispaxes,time,handles.audio);
    xlabel(handles.dispaxes,'Time [s]');
end
set(handles.record_btn,'BackgroundColor',[0.94 0.94 0.94]);
set(handles.record_btn,'Enable','on');
set(handles.stop_btn,'Visible','off');
% Release record object
release(handles.har)
set([handles.sperframe_IN,handles.percentage_IN,handles.threshold_IN,handles.tonelevel_IN,handles.evalcal_btn,handles.filter_btn],'Enable','on')
guidata(hObject,handles);

% --- Executes on button press in stop_btn.
function stop_btn_Callback(hObject, eventdata, handles)
% hObject    handle to stop_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
UserData.state = true;
set(hObject,'UserData',UserData);
pause on
pause(0.000001)
pause off
guidata(hObject,handles)


function duration_IN_Callback(hObject, eventdata, handles)
% hObject    handle to duration_IN (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of duration_IN as text
%        str2double(get(hObject,'String')) returns contents of duration_IN as a double
num = str2num(get(hObject,'String'));
if isempty(num) || num <= 0
    warndlg('Invalid entry','AARAE info')
    set(hObject,'String',num2str(handles.dur))
else
    handles.dur = num;
end
guidata(hObject,handles)

% --- Executes during object creation, after setting all properties.
function duration_IN_CreateFcn(hObject, eventdata, handles)
% hObject    handle to duration_IN (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
handles.dur = str2num(get(hObject,'String'));
guidata(hObject,handles)


% --- Executes on selection change in invf_popup.
function invf_popup_Callback(hObject, eventdata, handles)
% hObject    handle to invf_popup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns invf_popup contents as cell array
%        contents{get(hObject,'Value')} returns selected item from invf_popup
set(handles.invftext,'Visible','off')
guidata(hObject,handles)

% --- Executes during object creation, after setting all properties.
function invf_popup_CreateFcn(hObject, eventdata, handles)
% hObject    handle to invf_popup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in invfsmooth_popup.
function invfsmooth_popup_Callback(hObject, eventdata, handles)
% hObject    handle to invfsmooth_popup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns invfsmooth_popup contents as cell array
%        contents{get(hObject,'Value')} returns selected item from invfsmooth_popup
set(handles.invftext,'Visible','off')
guidata(hObject,handles)


% --- Executes during object creation, after setting all properties.
function invfsmooth_popup_CreateFcn(hObject, eventdata, handles)
% hObject    handle to invfsmooth_popup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function invfLF_IN_Callback(hObject, eventdata, handles)
% hObject    handle to invfLF_IN (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of invfLF_IN as text
%        str2double(get(hObject,'String')) returns contents of invfLF_IN as a double
num = str2num(get(hObject,'String'));
if isempty(num) || num <= 0 || num >= handles.invfHF
    warndlg('Invalid entry','AARAE info')
    set(hObject,'String',num2str(handles.invfLF))
else
    handles.invfLF = num;
    set(handles.invftext,'Visible','off')
end
guidata(hObject,handles)

% --- Executes during object creation, after setting all properties.
function invfLF_IN_CreateFcn(hObject, eventdata, handles)
% hObject    handle to invfLF_IN (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
handles.invfLF = str2num(get(hObject,'String'));
guidata(hObject,handles)


function invfHF_IN_Callback(hObject, eventdata, handles)
% hObject    handle to invfHF_IN (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of invfHF_IN as text
%        str2double(get(hObject,'String')) returns contents of invfHF_IN as a double
num = str2num(get(hObject,'String'));
if isempty(num) || num <= 0 || num <= handles.invfLF
    warndlg('Invalid entry','AARAE info')
    set(hObject,'String',num2str(handles.invfHF))
else
    handles.invfHF = num;
    set(handles.invftext,'Visible','off')
end
guidata(hObject,handles)

% --- Executes during object creation, after setting all properties.
function invfHF_IN_CreateFcn(hObject, eventdata, handles)
% hObject    handle to invfHF_IN (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
handles.invfHF = str2num(get(hObject,'String'));
guidata(hObject,handles)


function invfIB_IN_Callback(hObject, eventdata, handles)
% hObject    handle to invfIB_IN (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of invfIB_IN as text
%        str2double(get(hObject,'String')) returns contents of invfIB_IN as a double
num = str2num(get(hObject,'String'));
if isempty(num)
    warndlg('Invalid entry','AARAE info')
    set(hObject,'String',num2str(handles.invfIB))
else
    handles.invfIB = num;
    set(handles.invftext,'Visible','off')
end
guidata(hObject,handles)

% --- Executes during object creation, after setting all properties.
function invfIB_IN_CreateFcn(hObject, eventdata, handles)
% hObject    handle to invfIB_IN (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
handles.invfIB = str2num(get(hObject,'String'));
guidata(hObject,handles)


function invfOB_IN_Callback(hObject, eventdata, handles)
% hObject    handle to invfOB_IN (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of invfOB_IN as text
%        str2double(get(hObject,'String')) returns contents of invfOB_IN as a double
num = str2num(get(hObject,'String'));
if isempty(num)
    warndlg('Invalid entry','AARAE info')
    set(hObject,'String',num2str(handles.invfOB))
else
    handles.invfOB = num;
    set(handles.invftext,'Visible','off')
end
guidata(hObject,handles)

% --- Executes during object creation, after setting all properties.
function invfOB_IN_CreateFcn(hObject, eventdata, handles)
% hObject    handle to invfOB_IN (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
handles.invfOB = str2num(get(hObject,'String'));
guidata(hObject,handles)


% --- Executes on button press in invfdesign_btn.
function invfdesign_btn_Callback(hObject, eventdata, handles)
% hObject    handle to invfdesign_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(hObject,'BackgroundColor','red');
set(hObject,'Enable','off');
pause on
pause(0.000001)
pause off
fs = handles.mainHandles.fs;
f = [str2num(get(handles.invfLF_IN,'String')) str2num(get(handles.invfHF_IN,'String'))];
reg = [str2num(get(handles.invfIB_IN,'String')) str2num(get(handles.invfOB_IN,'String'))];
nfft = str2num(get(handles.invfnfft_IN,'String'));
flength = str2num(get(handles.invflength_IN,'String'));

% Thresholding
if f(1) > 0 && f(2) < fs/2
    freq=(0:fs/(nfft-1):fs/2)'; 
    f1e=f(1)-f(1)/3;
    f2e=f(2)+f(2)/3;
    if f1e < freq(1)
        f1e=f(1);
        f(1)=f(1)+1;
    end
    if f2e > freq(end)
        f2e=f(2)+1;
    end
    % thersholding B with 1/3 octave interpolated transient edges 
    B=interp1([0 f1e f(1) f(2) f2e freq(end)],[reg(2) reg(2) reg(1) reg(1) reg(2) reg(2)],freq,'cubic');
    B=10.^(-B./20); % from dB to linear
    B=vertcat(B,B(end:-1:1)); 
    b=ifft(B,'symmetric');
    b=circshift(b,nfft/2);
    b=0.5*(1-cos(2*pi*(1:nfft)'/(nfft+1))).*b;
    b=minph(b); % make minimum phase thresholding
    B=fft(b,nfft);
else
    B=0;
end
% Inverse filter design
H=abs(fft(handles.sysIR,nfft));
smoothfactor = get(handles.invfsmooth_popup,'Value');
if smoothfactor == 2, octsmooth = 1; end
if smoothfactor == 3, octsmooth = 3; end
if smoothfactor == 4, octsmooth = 6; end
if smoothfactor == 5, octsmooth = 12; end
if smoothfactor == 6, octsmooth = 24; end
if smoothfactor ~= 1, H = octavesmoothing(H, octsmooth, fs); end
iH=conj(H)./((conj(H).*H)+(conj(B).*B)); % calculating regulated spectral inverse
handles.invfilter=circshift(ifft(iH,'symmetric'),nfft/2);
if get(handles.invf_popup,'Value') == 1, handles.invfilter=minph(handles.invfilter); end
handles.output.invfilter = handles.invfilter;
set(handles.invftext,'Visible','on')
set(hObject,'BackgroundColor',[0.94 0.94 0.94]);
set([hObject handles.invfpreview_btn handles.record_btn handles.load_btn handles.duration_IN],'Enable','on');
guidata(hObject,handles)


function [h_min] = minph(h)
n = length(h);
h_cep = real(ifft(log(abs(fft(h(:,1))))));
odd = fix(rem(n,2));
wn = [1; 2*ones((n+odd)/2-1,1) ; ones(1-rem(n,2),1); zeros((n+odd)/2-1,1)];
h_min = zeros(size(h(:,1)));
h_min(:) = real(ifft(exp(fft(wn.*h_cep(:)))));
if size(h,2)==2
    h_cep = real(ifft(log(abs(fft(h(:,2))))));
    odd = fix(rem(n,2));
    wn = [1; 2*ones((n+odd)/2-1,1) ; ones(1-rem(n,2),1); zeros((n+odd)/2-1,1)];
    h_minr = zeros(size(h(:,2)));
    h_minr(:) = real(ifft(exp(fft(wn.*h_cep(:)))));
    h_min=[h_min h_minr];
end


% --- Executes on button press in invfpreview_btn.
function invfpreview_btn_Callback(hObject, eventdata, handles)
% hObject    handle to invfpreview_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(hObject,'BackgroundColor','red');
set(hObject,'Enable','off');
pause on
pause(0.000001)
pause off
sysIRfreq = 20*log10(abs(fft(handles.sysIR,length(handles.invfilter))));
phasesysIRfreq = angle(fft(handles.sysIR,length(handles.invfilter)));
invfilterfreq = 20*log10(abs(fft(handles.invfilter)));
phaseinvfilterfreq = angle(fft(handles.invfilter));
freq=0:44100/(length(handles.invfilter)-1):22050;
figure;
subplot(2,1,1);semilogx(freq,invfilterfreq(1:end/2,1),freq,-sysIRfreq(1:end/2,1));
xlim([str2num(get(handles.invfLF_IN,'String')) str2num(get(handles.invfHF_IN,'String'))])
set(gca,'XTickLabel',num2str(get(gca,'XTick').'))
legend('designed filter','true inverse','Location','SouthWest')
subplot(2,1,2);semilogx(freq,phaseinvfilterfreq(1:end/2,1),freq,phasesysIRfreq(1:end/2,1));
xlim([str2num(get(handles.invfLF_IN,'String')) str2num(get(handles.invfHF_IN,'String'))])
set(gca,'XTickLabel',num2str(get(gca,'XTick').'))
set(hObject,'BackgroundColor',[0.94 0.94 0.94]);
set(hObject,'Enable','on');


function invfnfft_IN_Callback(hObject, eventdata, handles)
% hObject    handle to invfnfft_IN (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of invfnfft_IN as text
%        str2double(get(hObject,'String')) returns contents of invfnfft_IN as a double
num = str2num(get(hObject,'String'));
if isempty(num) || num <= 0
    warndlg('Invalid entry','AARAE info')
    set(hObject,'String',num2str(handles.invfnfft))
else
    if mod(num,2) ~= 0, num = num + 1; set(hObject,'String',num2str(num)); end
    handles.invfnfft = num;
    set(handles.invftext,'Visible','off')
end
if num < handles.invflength
    set(handles.invflength_IN,'String',num2str(num))
    handles.invflength = num;
end
guidata(hObject,handles)

% --- Executes during object creation, after setting all properties.
function invfnfft_IN_CreateFcn(hObject, eventdata, handles)
% hObject    handle to invfnfft_IN (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
handles.invfnfft = str2num(get(hObject,'String'));
guidata(hObject,handles)


function invflength_IN_Callback(hObject, eventdata, handles)
% hObject    handle to invflength_IN (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of invflength_IN as text
%        str2double(get(hObject,'String')) returns contents of invflength_IN as a double
num = str2num(get(hObject,'String'));
if isempty(num) || num <= 0 || num > handles.invfnfft
    warndlg('Invalid entry','AARAE info')
    set(hObject,'String',num2str(handles.invflength))
else
    handles.invflength = num;
    set(handles.invftext,'Visible','off')
end
guidata(hObject,handles)


% --- Executes during object creation, after setting all properties.
function invflength_IN_CreateFcn(hObject, eventdata, handles)
% hObject    handle to invflength_IN (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
handles.invflength = str2num(get(hObject,'String'));
guidata(hObject,handles)