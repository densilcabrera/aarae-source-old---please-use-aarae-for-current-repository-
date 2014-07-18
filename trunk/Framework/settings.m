function varargout = settings(varargin)
% SETTINGS MATLAB code for settings.fig
%      SETTINGS, by itself, creates a new SETTINGS or raises the existing
%      singleton*.
%
%      H = SETTINGS returns the handle to a new SETTINGS or the handle to
%      the existing singleton*.
%
%      SETTINGS('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SETTINGS.M with the given input arguments.
%
%      SETTINGS('Property','Value',...) creates a new SETTINGS or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before settings_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to settings_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help settings

% Last Modified by GUIDE v2.5 18-Jul-2014 09:54:14

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @settings_OpeningFcn, ...
                   'gui_OutputFcn',  @settings_OutputFcn, ...
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


% --- Executes just before settings is made visible.
function settings_OpeningFcn(hObject, ~, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to settings (see VARARGIN)
% This next couple of lines checks if the GUI is being called from the main
% window, otherwise it doesn't run.

% Choose default command line output for settings
handles.output = [];

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
   disp('   Settings');
   disp('-----------------------------------------------------');
else
    mainHandles = guidata(handles.main_stage1);
    set(handles.maxtimetodisplay_IN,'String',num2str(mainHandles.Settings.maxtimetodisplay))
    if ischar(mainHandles.Settings.frequencylimits)
        set(handles.flim_popup,'Value',1)
        set(handles.flimtext,'String',[])
    else
        set(handles.flim_popup,'Value',2)
        set(handles.flimtext,'String',['[' num2str(mainHandles.Settings.frequencylimits) ']'])
    end
    set(handles.cal_chk,'Value',mainHandles.Settings.calibrationtoggle)
    colormaps = cellstr(get(handles.colormap_popup,'String'));
    if ischar(mainHandles.Settings.colormap)
        set(handles.colormap_popup,'Value',find(cellfun(@strcmp,colormaps,repmat(cellstr(mainHandles.Settings.colormap),length(colormaps),1))))
    else
        set(handles.colormap_popup,'Value',1)
    end
    handles.output = mainHandles.Settings;
    guidata(hObject, handles);
    uiwait(hObject);
end


% --- Outputs from this function are returned to the command line.
function varargout = settings_OutputFcn(hObject, ~, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
delete(hObject)



function maxtimetodisplay_IN_Callback(hObject, ~, handles) %#ok : Executed when maximum time to diaplay input changes
% hObject    handle to maxtimetodisplay_IN (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of maxtimetodisplay_IN as text
%        str2double(get(hObject,'String')) returns contents of maxtimetodisplay_IN as a double
maxtimetodisplay = str2double(get(hObject,'String'));
if ~isnan(maxtimetodisplay) && maxtimetodisplay > 0
    handles.output.maxtimetodisplay = maxtimetodisplay;
else
    warndlg('Invalid entry!','AARAE info','modal')
end
guidata(hObject,handles)

% --- Executes during object creation, after setting all properties.
function maxtimetodisplay_IN_CreateFcn(hObject, ~, ~) %#ok : Maximum time to display input box creation
% hObject    handle to maxtimetodisplay_IN (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in cal_chk.
function cal_chk_Callback(hObject, ~, handles) %#ok : Executed when apply calibration checkbox changes
% hObject    handle to cal_chk (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cal_chk
handles.output.calibrationtoggle = get(hObject,'Value');
guidata(hObject,handles)

% --- Executes on selection change in flim_popup.
function flim_popup_Callback(hObject, ~, handles) %#ok : Executed when frequency limits popup up menu changes
% hObject    handle to flim_popup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns flim_popup contents as cell array
%        contents{get(hObject,'Value')} returns selected item from flim_popup
contents = cellstr(get(hObject,'String'));
selection = contents{get(hObject,'Value')};
switch selection
    case 'Default'
        handles.output.frequencylimits = selection;
        set(handles.flimtext,'String',[])
    case 'User defined'
        limits = inputdlg({'Lower frequency limit','Upper frequency limit'},'Frequency limits',[1 50],{'20','20000'});
        if isempty(limits)
            set(hObject,'Value',1)
            set(handles.flimtext,'String',[])
            handles.output.frequencylimits = 'Default';
        else
            if isempty(limits{1,1}) || isempty(limits{2,1})
                set(hObject,'Value',1)
                set(handles.flimtext,'String',[])
                handles.output.frequencylimits = 'Default';
            else
                limits = str2double(limits);
                if ~isnan(limits(1,1)) && ~isnan(limits(2,1))
                    handles.output.frequencylimits = limits';
                    set(handles.flimtext,'String',['[' num2str(limits') ']'])
                else
                    set(hObject,'Value',1)
                    set(handles.flimtext,'String',[])
                    handles.output.frequencylimits = 'Default';
                end
            end
        end
end
guidata(hObject,handles)

% --- Executes during object creation, after setting all properties.
function flim_popup_CreateFcn(hObject, ~, ~) %#ok : Frequency limits popup menu creation
% hObject    handle to flim_popup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in ok_btn.
function ok_btn_Callback(~, ~, handles) %#ok : Executed when OK button is clicked
% hObject    handle to ok_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
uiresume(handles.settings)

% --- Executes on button press in cancel_btn.
function cancel_btn_Callback(hObject, ~, handles) %#ok : Executed when Cancel button is clicked
% hObject    handle to cancel_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
mainHandles = guidata(handles.main_stage1);
handles.output = mainHandles.Settings;
guidata(hObject,handles)
uiresume(handles.settings)

% --- Executes when user attempts to close settings.
function settings_CloseRequestFcn(hObject, ~, ~) %#ok : Executed when Preference window is closed
% hObject    handle to settings (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
uiresume(hObject);


% --- Executes on selection change in colormap_popup.
function colormap_popup_Callback(hObject, eventdata, handles)
% hObject    handle to colormap_popup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns colormap_popup contents as cell array
%        contents{get(hObject,'Value')} returns selected item from colormap_popup
contents = cellstr(get(hObject,'String'));
selection = contents{get(hObject,'Value')};
switch selection
    case 'Default'
        aaraecmap = importdata([cd '/Utilities/Custom_colormaps/o2b_bipolar.mat']);
        handles.output.colormap = aaraecmap;
    otherwise
        handles.output.colormap = selection;
end
guidata(hObject,handles)

% --- Executes during object creation, after setting all properties.
function colormap_popup_CreateFcn(hObject, eventdata, handles)
% hObject    handle to colormap_popup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

default_colormaps = {'Jet','HSV','Copper','Autumn','Bone'}.';
custom_colormaps = what([cd '/Utilities/Custom_colormaps']);
custom_colormaps = cellstr(custom_colormaps.mat);
all_colormaps = cat(1,default_colormaps,custom_colormaps);
set(hObject,'String',all_colormaps)
guidata(hObject,handles)