% DO NOT EDIT THIS INITIALIZATION FUNCTION!!!!!!!!!!!!!!!!!!!!!!!!!!!
function varargout = audio_recorder(varargin)
% AUDIO_RECORDER MATLAB code for audio_recorder.fig
%      AUDIO_RECORDER, by itself, creates a new AUDIO_RECORDER or raises the existing
%      singleton*.
%
%      H = AUDIO_RECORDER returns the handle to a new AUDIO_RECORDER or the handle to
%      the existing singleton*.
%
%      AUDIO_RECORDER('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in AUDIO_RECORDER.M with the given input arguments.
%
%      AUDIO_RECORDER('Property','Value',...) creates a new AUDIO_RECORDER or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before audio_recorder_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to audio_recorder_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help audio_recorder

% Last Modified by GUIDE v2.5 21-Feb-2014 11:37:55

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @audio_recorder_OpeningFcn, ...
                   'gui_OutputFcn',  @audio_recorder_OutputFcn, ...
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


% --- Executes just before audio_recorder is made visible.
function audio_recorder_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to audio_recorder (see VARARGIN)


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
    % Call the 'desktop'
    hMain = getappdata(0,'hMain');
    handles.signaldata = getappdata(hMain,'testsignal');
    handles.recording = [];
    handles.position = get(handles.audio_recorder,'Position');
    handles.OUT_axes_position = get(handles.OUT_axes,'Position');
    UserData.state = false;
    set(handles.stop_btn,'UserData',UserData);
    mainHandles = guidata(handles.main_stage1);
    if isfield(mainHandles,'syscalstats') && ~isempty(mainHandles.syscalstats)
        remember = questdlg('A previous system calibration was found, would you like to reload these settings?','AARAE info','Yes','No','Yes');
        switch remember
            case 'Yes'
                handles.savenewsyscal = 0;
                handles.syscalstats = mainHandles.syscalstats;
                if isfield(handles.syscalstats,'latency')
                    set(handles.delay_chk,'Enable','on','Value',1)
                    set(handles.delaytext,'String',[num2str(handles.syscalstats.latency) ' samples'])
                end
                if isfield(handles.syscalstats,'cal')
                    set(handles.cal_chk,'Enable','on','Value',1)
                    set(handles.caltext,'String',[num2str(handles.syscalstats.cal) ' dB'])
                end
                if isfield(handles.syscalstats,'audio2')
                    set(handles.invfilter_chk,'Enable','on','Value',1)
                    set(handles.invftext,'String','Available')
                end
            case 'No'
                handles.savenewsyscal = 1;
                handles.syscalstats = struct([]);
        end
    else
        handles.savenewsyscal = 1;
        handles.syscalstats = struct([]);
    end
    if ~isempty(handles.signaldata) && ndims(handles.signaldata.audio) < 3 && ~strcmp(handles.signaldata.datatype,'syscal')% If there's a signal loaded in the 'desktop'...
        % Allow visibility of playback option along with the specs of
        % the playback signal
        mainHandles = guidata(handles.main_stage1);
        selectednode = mainHandles.mytree.getSelectedNodes;
        set(handles.pb_enable,'Visible','on','Value',1);
        handles.outputdata = handles.signaldata;
        handles.dur = length(handles.outputdata.audio)/handles.outputdata.fs;
        handles.t = linspace(0,handles.dur,length(handles.outputdata.audio));
        output_settings{1} = ['Playback audio loaded: ' selectednode(1).getName.char];
        output_settings{2} = ['Number of audio channels: ' num2str(size(handles.outputdata.audio,2))];
        output_settings{3} = ['Sampling frequency = ',num2str(handles.outputdata.fs),' samples/s'];
        output_settings{4} = ['Bit depth = ',num2str(handles.outputdata.nbits)];
        output_settings{5} = ['Duration = ',num2str(handles.dur),' s'];
        plot(handles.OUT_axes,handles.t,handles.outputdata.audio)
        set(handles.OUT_axes,'tag','OUT_axes')
        set(handles.output_settings,'String',output_settings);
        set(handles.text1,'String','Add time');
        set(handles.IN_duration,'String','1');
        set(handles.IN_fs,'Enable','off');
        set(handles.IN_fs,'String','-');
        set(handles.IN_nbits,'Enable','off');
        set(handles.IN_nbits,'String','-');
        handles.numchs = str2num(get(handles.IN_numchs,'String'));
        handles.addtime = str2num(get(handles.IN_duration,'String'));
        handles.fs = handles.outputdata.fs;
        handles.nbits = handles.outputdata.nbits;
        xlim(handles.IN_axes,[0 round(handles.dur+handles.addtime)])
        xlim(handles.OUT_axes,[0 round(handles.dur+handles.addtime)])
    else
        % If there's no signal loaded in the desktop just allocate memory
        % space for the signal to be recorded
        set(handles.pb_enable,'Visible','off','Value',0);
        set(handles.output_panel,'Visible','off');
        set(handles.text1,'String','Duration');
        set(handles.IN_duration,'String','10');
        set(handles.IN_fs,'Enable','on');
        set(handles.IN_fs,'String','48000');
        set(handles.IN_nbits,'Enable','on');
        set(handles.IN_nbits,'String','16');
        set(handles.OUT_axes,'Visible','off');
        set(handles.audio_recorder,'Position',handles.position-[0 0 0 handles.OUT_axes_position(4)])
        handles.numchs = str2num(get(handles.IN_numchs,'String'));
        handles.duration = str2num(get(handles.IN_duration,'String'));
        handles.fs = str2num(get(handles.IN_fs,'String'));
        handles.nbits = str2num(get(handles.IN_nbits,'String'));
        xlim(handles.IN_axes,[0 round(handles.duration)])
        xlim(handles.OUT_axes,[0 round(handles.duration)])
    end
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

% UIWAIT makes audio_recorder wait for user response (see UIRESUME)
% uiwait(handles.audio_recorder);


% --- Outputs from this function are returned to the command line.
function varargout = audio_recorder_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

hMain = getappdata(0,'hMain');
if handles.savenewsyscal == 1 && ~isempty(handles.syscalstats)
    setappdata(hMain,'savenewsyscalstats',1);
    setappdata(hMain,'syscalstats',handles.syscalstats)
else
    setappdata(hMain,'savenewsyscalstats',0)
end

% Get default command line output from handles structure
varargout{1} = handles.recording;
delete(hObject);


% --- Executes on selection change in select_input.
function select_input_Callback(hObject, eventdata, handles)
% hObject    handle to select_input (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns select_input contents as cell array
%        contents{get(hObject,'Value')} returns selected item from select_input

% Get input selection from the pop-up menu
selection = get(hObject,'Value');
handles.inputid = handles.ideviceidlist(selection);
guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function select_input_CreateFcn(hObject, eventdata, handles)
% hObject    handle to select_input (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

devinfo = audiodevinfo; % Get available device information
idevicelist = {devinfo.input.Name}; % Populate list
handles.ideviceidlist =  cell2mat({devinfo.input.ID});
handles.inputid = handles.ideviceidlist(1,1);
set(hObject,'String',idevicelist);
guidata(hObject,handles);

% --- Executes on button press in record_btn.
function record_btn_Callback(hObject, eventdata, handles)
% hObject    handle to record_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Call handles from main window
mainHandles = guidata(handles.main_stage1);
set([handles.cancel_btn handles.load_btn handles.preview_btn handles.syscal_btn],'Enable','off')
if get(handles.pb_enable,'Value') == 1
    % Simultaneous playback and record routine
    set(hObject,'Enable','off');
    pause on
    pause(0.000001)
    pause off
    % Set playback object
    handles.hap = dsp.AudioPlayer('SampleRate',handles.outputdata.fs,'QueueDuration',.1,'BufferSizeSource','Property','BufferSize',128);
    % Set record object
    handles.har = dsp.AudioRecorder('SampleRate',handles.outputdata.fs,'OutputDataType','double','NumChannels',handles.numchs,'BufferSizeSource','Property','BufferSize',128);
    % Set playback audio
    handles.hsr1 = dsp.SignalSource;
    handles.hsr1.Signal = [handles.outputdata.audio;zeros(floor((handles.addtime+handles.hap.QueueDuration)*handles.fs),size(handles.outputdata.audio,2))];
    handles.hsr1.SamplesPerFrame = 1024;
    guidata(hObject,handles)
    handles.rec = [];
    set(hObject,'BackgroundColor','red');
    set(handles.stop_btn,'Visible','on');
    % Initialize playback/record routine
    try
        UserData = get(handles.stop_btn,'UserData');
        while (~isDone(handles.hsr1))
           UserData = get(handles.stop_btn,'UserData');
           if UserData.state == false
               audio = step(handles.har);
               step(handles.hap,step(handles.hsr1));
               handles.rec = [handles.rec;audio];
           else
               break
           end
           pause on
           pause(0.000001)
           pause off
        end
    catch sthgwrong
        UserData.state = true;
        handles.rec = [];
        syswarning = sthgwrong.message;
        warndlg(syswarning,'AARAE info')
    end
    % Check recording and adjust for QueueDuration latency
    if ~isempty(handles.rec)
        handles.rec = handles.rec(handles.hap.QueueDuration*handles.fs:end,:);
        if UserData.state == false
            handles.rec = handles.rec(1:(size(handles.outputdata.audio,1)+handles.addtime*handles.fs),:);
        else
            UserData.state = false;
            set(handles.stop_btn,'UserData',UserData);
        end
    % Plot recording
        time = linspace(0,size(handles.rec,1)/handles.fs,length(handles.rec));
        plot(handles.IN_axes,time,handles.rec);
    end
    % Release playback, record and audio data objects
    release(handles.hap)
    release(handles.har)
    release(handles.hsr1)
else
    % Record-only routine
    dur = handles.duration*handles.fs;
    set(hObject,'Enable','off');
    pause on
    pause(0.000001)
    pause off
    % Set record object
    handles.har = dsp.AudioRecorder('SampleRate',handles.fs,'OutputDataType','double','NumChannels',handles.numchs,'BufferSizeSource','Property','BufferSize',128,'QueueDuration',.1);
    guidata(hObject,handles)
    handles.rec = [];
    set(hObject,'BackgroundColor','red');
    set(handles.stop_btn,'Visible','on');
    % Initialize record routine
    try
        UserData = get(handles.stop_btn,'UserData');
        while length(handles.rec) < dur
           UserData = get(handles.stop_btn,'UserData');
           if UserData.state == false
               audio = step(handles.har);
               handles.rec = [handles.rec;audio];
           else
               break
           end
           pause on
           pause(0.000001)
           pause off
        end
    catch sthgwrong
        UserData.state = true;
        handles.rec = [];
        syswarning = sthgwrong.message;
        warndlg(syswarning,'AARAE info')
    end
    % Check recording and adjust for Duration
    if ~isempty(handles.rec)
        if UserData.state == false
            handles.rec = handles.rec(1:dur,:);
        else
            UserData.state = false;
            set(handles.stop_btn,'UserData',UserData);
        end
        % Plot recording
        time = linspace(0,size(handles.rec,1)/handles.fs,length(handles.rec));
        plot(handles.IN_axes,time,handles.rec);
    end
    % Release record object
    release(handles.har)
end
set(handles.record_btn,'BackgroundColor',[0.94 0.94 0.94]);
set(handles.record_btn,'Enable','on');
set(handles.stop_btn,'Visible','off');
set([handles.load_btn handles.preview_btn handles.cancel_btn handles.syscal_btn],'Enable','on')

guidata(hObject,handles);


% --- Executes on button press in load_btn.
function load_btn_Callback(hObject, eventdata, handles)
% hObject    handle to load_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

hMain = getappdata(0,'hMain');
% Obtain handles using GUIDATA with the caller's handle

handles.testsignal = handles.rec;

% Warnings...
if isempty(handles.rec)
    warndlg('No signal recorded!');
    setappdata(hMain,'testsignal',[]);
else
    hMain = getappdata(0,'hMain');
    if get(handles.delay_chk,'Value') == 1, handles.rec = [handles.rec(handles.syscalstats.latency:end,:);zeros(handles.syscalstats.latency,size(handles.rec,2))]; end
    if get(handles.invfilter_chk,'Value') == 1, handles.rec = filter(handles.syscalstats.audio2,1,handles.rec); end
    handles.recording.audio = handles.rec;
    if get(handles.pb_enable,'Value') && isfield(handles.outputdata,'audio2')
        handles.recording.audio2 = handles.outputdata.audio2;
    elseif get(handles.pb_enable,'Value') && ~isfield(handles.outputdata,'audio2')
        handles.recording.audio2 = handles.outputdata.audio;
    else
        handles.recording.audio2 = [];
    end
    handles.recording.fs = handles.fs;
    handles.recording.nbits = handles.nbits;
    handles.recording.chanID = cellstr([repmat('Chan',size(handles.recording.audio,2),1) num2str((1:size(handles.recording.audio,2))')]);
    if get(handles.cal_chk,'Value') == 1, handles.recording.cal = handles.syscalstats.cal; end
    name = get(handles.IN_name,'String');
    if isempty(name), name = 'untitled'; end
    setappdata(hMain,'signalname',name);
end
setappdata(hMain,'syscalstats',handles.syscalstats);
guidata(hObject,handles)
uiresume(handles.audio_recorder);

% --- Executes on button press in cancel_btn.
function cancel_btn_Callback(hObject, eventdata, handles)
% hObject    handle to cancel_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Clear the desktop if recording is canceled
hMain = getappdata(0,'hMain');
setappdata(hMain,'testsignal',[]);

uiresume(handles.audio_recorder);


function IN_numchs_Callback(hObject, eventdata, handles)
% hObject    handle to IN_numchs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of IN_numchs as text
%        str2double(get(hObject,'String')) returns contents of IN_numchs as a double

% Get number of channels
numchs = str2num(get(handles.IN_numchs, 'string'));

% Check user's input
if (isempty(numchs)||numchs<=0)
    set(hObject,'String',num2str(handles.numchs));
    warndlg('All inputs MUST be real positive numbers!');
else
    handles.numchs = numchs;
end
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function IN_numchs_CreateFcn(hObject, eventdata, handles)
% hObject    handle to IN_numchs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function IN_duration_Callback(hObject, eventdata, handles)
% hObject    handle to IN_duration (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of IN_duration as text
%        str2double(get(hObject,'String')) returns contents of IN_duration as a double

% Get duration input
duration = round(str2num(get(handles.IN_duration, 'string')));

% Check user's input
if (isempty(duration)||duration<=0)
    if get(handles.pb_enable,'Value') == 1
        set(hObject,'String',num2str(handles.addtime));
    else
        set(hObject,'String',num2str(handles.duration));
    end
    warndlg('All inputs MUST be real positive numbers!');
else
    set(hObject,'String',num2str(duration))
    handles.duration = duration;
    handles.addtime = duration;
    if get(handles.pb_enable,'Value') == 1
        xlim(handles.IN_axes,[0 round(handles.dur+handles.addtime)])
        xlim(handles.OUT_axes,[0 round(handles.dur+handles.addtime)])
    else
        xlim(handles.IN_axes,[0 round(handles.duration)])
        xlim(handles.OUT_axes,[0 round(handles.duration)])
    end
end
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function IN_duration_CreateFcn(hObject, eventdata, handles)
% hObject    handle to IN_duration (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function IN_fs_Callback(hObject, eventdata, handles)
% hObject    handle to IN_fs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of IN_fs as text
%        str2double(get(hObject,'String')) returns contents of IN_fs as a double

% Get sampling frequency input
fs = str2num(get(handles.IN_fs, 'string'));

% Check user's input
if (isempty(fs)||fs<=0)
    set(hObject,'String',num2str(handles.fs))
    warndlg('All inputs MUST be real positive numbers!');
else
    handles.fs = fs;
end
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function IN_fs_CreateFcn(hObject, eventdata, handles)
% hObject    handle to IN_fs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function IN_nbits_Callback(hObject, eventdata, handles)
% hObject    handle to IN_nbits (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of IN_nbits as text
%        str2double(get(hObject,'String')) returns contents of IN_nbits as a double

% Get bit depth input
nbits = str2num(get(handles.IN_nbits, 'string'));

% Check user's input
if (isempty(nbits)||nbits<=0)
    set(hObject,'String',num2str(handles.nbits))
    warndlg('All inputs MUST be real positive numbers!');
else
    handles.nbits = nbits;
end
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function IN_nbits_CreateFcn(hObject, eventdata, handles)
% hObject    handle to IN_nbits (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes when user attempts to close audio_recorder.
function audio_recorder_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to audio_recorder (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
uiresume(hObject);


% --- Executes on selection change in select_output.
function select_output_Callback(hObject, eventdata, handles)
% hObject    handle to select_output (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

selection = get(hObject,'Value');
handles.outputid = handles.odeviceidlist(selection);
guidata(hObject,handles);
% Hints: contents = cellstr(get(hObject,'String')) returns select_output contents as cell array
%        contents{get(hObject,'Value')} returns selected item from select_output


% --- Executes during object creation, after setting all properties.
function select_output_CreateFcn(hObject, eventdata, handles)
% hObject    handle to select_output (see GCBO)
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
handles.outputid = handles.odeviceidlist(1,1);
set(hObject,'String',odevicelist);
guidata(hObject,handles);



function IN_name_Callback(hObject, eventdata, handles)
% hObject    handle to IN_name (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of IN_name as text
%        str2double(get(hObject,'String')) returns contents of IN_name as a double


% --- Executes during object creation, after setting all properties.
function IN_name_CreateFcn(hObject, eventdata, handles)
% hObject    handle to IN_name (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pb_enable.
function pb_enable_Callback(hObject, eventdata, handles)
% hObject    handle to pb_enable (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of pb_enable
if get(hObject,'Value') == 1
    set(handles.output_panel,'Visible','on');
    set(handles.text1,'String','Add time');
    set(handles.IN_duration,'String','1');
    set(handles.IN_fs,'Enable','off');
    set(handles.IN_fs,'String','-');
    set(handles.IN_nbits,'Enable','off');
    set(handles.IN_nbits,'String','-');
    set(handles.audio_recorder,'Position',handles.position);
    set(handles.OUT_axes,'Visible','on');
    children = get(handles.OUT_axes,'Children');
    set(children,'Visible','on');
    handles.numchs = str2num(get(handles.IN_numchs,'String'));
    handles.addtime = str2num(get(handles.IN_duration,'String'));
    handles.fs = handles.outputdata.fs;
    handles.nbits = handles.outputdata.nbits;
    xlim(handles.IN_axes,[0 round(handles.dur+handles.addtime)])
    xlim(handles.OUT_axes,[0 round(handles.dur+handles.addtime)])
else
    set(handles.output_panel,'Visible','off');
    set(handles.text1,'String','Duration');
    set(handles.IN_duration,'String','10');
    set(handles.IN_fs,'Enable','on');
    set(handles.IN_fs,'String','48000');
    set(handles.IN_nbits,'Enable','on');
    set(handles.IN_nbits,'String','16');
    set(handles.audio_recorder,'Position',handles.position-[0 0 0 handles.OUT_axes_position(4)]);
    set(handles.OUT_axes,'Visible','off');
    children = get(handles.OUT_axes,'Children');
    set(children,'Visible','off');
    handles.numchs = str2num(get(handles.IN_numchs,'String'));
    handles.duration = str2num(get(handles.IN_duration,'String'));
    handles.fs = str2num(get(handles.IN_fs,'String'));
    handles.nbits = str2num(get(handles.IN_nbits,'String'));
    xlim(handles.IN_axes,[0 round(handles.duration)])
    xlim(handles.OUT_axes,[0 round(handles.duration)])
end
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


% --- Executes on button press in syscal_btn.
function syscal_btn_Callback(hObject, eventdata, handles)
% hObject    handle to syscal_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
syscalstats = syscal('audio_recorder', handles.audio_recorder);
if isfield(syscalstats,'audio'), handles.syscalstats(1).audio = syscalstats.audio; end
if isfield(syscalstats,'fs'), handles.syscalstats(1).fs = syscalstats.fs; end
if isfield(syscalstats,'latency') && ~isnan(syscalstats.latency)
    if isfield(handles.syscalstats,'latency')
        if handles.syscalstats.latency ~= syscalstats.latency
             replace_value = questdlg(['The system latency measurement has changed from ' num2str(handles.syscalstats.latency) ' samples to ' num2str(syscalstats.latency) ' samples. Would you like to replace this value?'],...
                                       'AARAE info',...
                                       'Yes', 'No', 'No');
             switch replace_value
                 case 'Yes'
                     handles.savenewsyscal = 1;
                     handles.syscalstats.latency = syscalstats.latency;
             end
        end
    else
        handles.savenewsyscal = 1;
        handles.syscalstats(1).latency = syscalstats.latency;
    end
    set(handles.delay_chk,'Enable','on','Value',1)
    set(handles.delaytext,'String',[num2str(handles.syscalstats.latency) ' samples'])
end
if isfield(syscalstats,'cal') && ~isnan(syscalstats.cal)
    if isfield(handles.syscalstats,'cal')
        if handles.syscalstats.cal ~= syscalstats.cal
             replace_value = questdlg(['The gain calibration measurement has changed from ' num2str(handles.syscalstats.cal) ' dB to ' num2str(syscalstats.cal) ' dB. Would you like to replace this value?'],...
                                       'AARAE info',...
                                       'Yes', 'No', 'No');
             switch replace_value
                 case 'Yes'
                     handles.savenewsyscal = 1;
                     handles.syscalstats.cal = syscalstats.cal;
             end
        end
    else
        handles.savenewsyscal = 1;
        handles.syscalstats(1).cal = syscalstats.cal;
    end
    set(handles.cal_chk,'Enable','on','Value',1)
    set(handles.caltext,'String',[num2str(handles.syscalstats.cal) ' dB'])
end
if isfield(syscalstats,'invfilter') && ~isempty(syscalstats.invfilter)
    if isfield(handles.syscalstats,'invfilter')
        if handles.syscalstats.invfilter ~= syscalstats.invfilter
             replace_value = questdlg('The inverse filter has been modified. Would you like to replace it?',...
                                       'AARAE info',...
                                       'Yes', 'No', 'No');
             switch replace_value
                 case 'Yes'
                     handles.savenewsyscal = 1;
                     handles.syscalstats.audio2 = syscalstats.invfilter;
             end
        end
    else
        handles.savenewsyscal = 1;
        handles.syscalstats(1).audio2 = syscalstats.invfilter;
    end
    set(handles.invfilter_chk,'Enable','on','Value',1)
    set(handles.invftext,'String','Available')
end
guidata(hObject,handles)


% --- Executes on button press in delay_chk.
function delay_chk_Callback(hObject, eventdata, handles)
% hObject    handle to delay_chk (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of delay_chk


% --- Executes on button press in cal_chk.
function cal_chk_Callback(hObject, eventdata, handles)
% hObject    handle to cal_chk (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cal_chk


% --- Executes on button press in invfilter_chk.
function invfilter_chk_Callback(hObject, eventdata, handles)
% hObject    handle to invfilter_chk (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of invfilter_chk


% --- Executes on button press in preview_btn.
function preview_btn_Callback(hObject, eventdata, handles)
% hObject    handle to preview_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%hMain = getappdata(0,'hMain');
% Obtain handles using GUIDATA with the caller's handle

handles.testsignal = handles.rec;

% Warnings...
if isempty(handles.rec)
    warndlg('No signal recorded!');
    setappdata(hMain,'testsignal',[]);
else
%    hMain = getappdata(0,'hMain');
    if get(handles.delay_chk,'Value') == 1, handles.rec = [handles.rec(handles.syscalstats.latency:end,:);zeros(handles.syscalstats.latency-1,size(handles.rec,2))]; end
    if get(handles.invfilter_chk,'Value') == 1, handles.rec = filter(handles.syscalstats.audio2,1,handles.rec); end
    time1 = linspace(0,size(handles.rec,1)/handles.fs,length(handles.rec));
    time2 = linspace(0,size(handles.testsignal,1)/handles.fs,length(handles.testsignal));
    figure
    subplot(2,1,1); plot(time2,handles.testsignal); title('Recorded signal')
    subplot(2,1,2); plot(time1,handles.rec); title('System calibrated recording')
end