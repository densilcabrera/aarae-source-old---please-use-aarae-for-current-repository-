% DO NOT EDIT THIS INITIALIZATION FUNCTION!!!!!!!!!!!!!!!!!!!!!!!!!!!
function varargout = window_signal(varargin)
% WINDOW_SIGNAL MATLAB code for window_signal.fig
%      WINDOW_SIGNAL, by itself, creates a new WINDOW_SIGNAL or raises the existing
%      singleton*.
%
%      H = WINDOW_SIGNAL returns the handle to a new WINDOW_SIGNAL or the handle to
%      the existing singleton*.
%
%      WINDOW_SIGNAL('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in WINDOW_SIGNAL.M with the given input arguments.
%
%      WINDOW_SIGNAL('Property','Value',...) creates a new WINDOW_SIGNAL or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before window_signal_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to window_signal_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help window_signal

% Last Modified by GUIDE v2.5 02-Apr-2014 10:45:25

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @window_signal_OpeningFcn, ...
                   'gui_OutputFcn',  @window_signal_OutputFcn, ...
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


% --- Executes just before window_signal is made visible.
function window_signal_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to window_signal (see VARARGIN)

axis([0 10 -1 1]);
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
    disp('Improper input arguments. Pass a property value pair') 
    disp('whose name is "changeme_main" and value is the handle')
    disp('to the changeme_main figure, e.g:');
    disp('   x = changeme_main()');
    disp('   changeme_dialog(''changeme_main'', x)');
    disp('-----------------------------------------------------');
else
    % Find the IR signal being sent to window
    impulse = find(strcmp(varargin, 'IR'));
    handles.IR = varargin{impulse+1};
    t = linspace(0,size(handles.IR,1),size(handles.IR,1));
    plot(handles.IN_axes,t,handles.IR)
    xlabel(handles.IN_axes,'Samples');
    set(handles.IN_axes,'XTickLabel',num2str(get(handles.IN_axes,'XTick').'))
    [~, id] = max(abs(handles.IR));
    IRlength = max(id);
    %handles.IRlength = IRlength;
    %set(handles.IN_length, 'string',num2str(max(id))); % Get the IR length from input
    trimsamp_low = max(id)-round(IRlength./2);
    trimsamp_high = trimsamp_low + IRlength -1;
    handles.slow = trimsamp_low;
    handles.shigh = trimsamp_high;
    set(handles.trimlow,'String',num2str(trimsamp_low))
    set(handles.trimhigh,'String',num2str(trimsamp_high))
    B=interp1([0 trimsamp_low trimsamp_low+1 trimsamp_high-1 trimsamp_high t(end)],[0 0 max(handles.IR(:)) max(handles.IR(:)) 0 0],t,'linear');
    hold(handles.IN_axes,'on')
    handles.win = plot(handles.IN_axes,B,'r');
    hold(handles.IN_axes,'off')
    trimIR = handles.IR(trimsamp_low:trimsamp_high,:); % Crop IR
    plot(handles.OUT_axes,trimIR) % Plot cropped IR
    xlabel(handles.OUT_axes,'Samples');
    set(handles.OUT_axes,'XTickLabel',num2str(get(handles.OUT_axes,'XTick').'))
    guidata(hObject, handles);
    uiwait(hObject);
end

% UIWAIT makes window_signal wait for user response (see UIRESUME)
% uiwait(handles.window_signal);


% --- Outputs from this function are returned to the command line.
function varargout = window_signal_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.slow;
varargout{2} = handles.shigh;
delete(hObject);


% --- Executes on button press in done_btn.
function done_btn_Callback(hObject, eventdata, handles)
% hObject    handle to done_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
uiresume(handles.window_signal);


% --- Executes when user attempts to close window_signal.
function window_signal_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to window_signal (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
uiresume(hObject);


function trimlow_Callback(hObject, eventdata, handles)
% hObject    handle to trimlow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of trimlow as text
%        str2double(get(hObject,'String')) returns contents of trimlow as a double

trimsamp_low = round(str2num(get(hObject,'String')));
% Check user's input
if isempty(trimsamp_low) || trimsamp_low <= 0
    set(hObject,'String',num2str(handles.slow))
    warndlg('Invalid lower limit!','AARAE info');
else
    delete(handles.win)
    handles = rmfield(handles,'win');
    trimsamp_high = round(str2num(get(handles.trimhigh,'String')));
    handles.slow = trimsamp_low;
    t = linspace(0,size(handles.IR,1),size(handles.IR,1));
    B=interp1([0 trimsamp_low trimsamp_low+1 trimsamp_high-1 trimsamp_high t(end)],[0 0 max(handles.IR(:)) max(handles.IR(:)) 0 0],t,'linear');
    hold(handles.IN_axes,'on')
    handles.win = plot(handles.IN_axes,B,'r');
    hold(handles.IN_axes,'off')
    trimIR = handles.IR(trimsamp_low:trimsamp_high,:);
    plot(handles.OUT_axes,trimIR)
    xlabel(handles.OUT_axes,'Samples');
    set(handles.OUT_axes,'XTickLabel',num2str(get(handles.OUT_axes,'XTick').'))
end
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function trimlow_CreateFcn(hObject, eventdata, handles)
% hObject    handle to trimlow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function trimhigh_Callback(hObject, eventdata, handles)
% hObject    handle to trimhigh (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of trimhigh as text
%        str2double(get(hObject,'String')) returns contents of trimhigh as a double

trimsamp_high = round(str2num(get(hObject,'String')));
% Check user's input
if isempty(trimsamp_high) || trimsamp_high >= length(handles.IR)
    set(hObject,'String',num2str(handles.shigh))
    warndlg('Invalid upper limit!','AARAE info');
else
    delete(handles.win)
    handles = rmfield(handles,'win');
    trimsamp_low = round(str2num(get(handles.trimlow,'String')));
    handles.shigh = trimsamp_high;
    t = linspace(0,size(handles.IR,1),size(handles.IR,1));
    B=interp1([0 trimsamp_low trimsamp_low+1 trimsamp_high-1 trimsamp_high t(end)],[0 0 max(handles.IR(:)) max(handles.IR(:)) 0 0],t,'linear');
    hold(handles.IN_axes,'on')
    handles.win = plot(handles.IN_axes,B,'r');
    hold(handles.IN_axes,'off')
    trimIR = handles.IR(trimsamp_low:trimsamp_high,:);
    plot(handles.OUT_axes,trimIR)
    xlabel(handles.OUT_axes,'Samples');
    set(handles.OUT_axes,'XTickLabel',num2str(get(handles.OUT_axes,'XTick').'))
end
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function trimhigh_CreateFcn(hObject, eventdata, handles)
% hObject    handle to trimhigh (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
