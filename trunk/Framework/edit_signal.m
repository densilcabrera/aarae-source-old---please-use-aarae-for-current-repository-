% DO NOT EDIT THIS INITIALIZATION FUNCTION!!!!!!!!!!!!!!!!!!!!!!!!!!!
function varargout = edit_signal(varargin)
% EDIT_SIGNAL MATLAB code for edit_signal.fig
%      EDIT_SIGNAL, by itself, creates a new EDIT_SIGNAL or raises the existing
%      singleton*.
%
%      H = EDIT_SIGNAL returns the handle to a new EDIT_SIGNAL or the handle to
%      the existing singleton*.
%
%      EDIT_SIGNAL('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in EDIT_SIGNAL.M with the given input arguments.
%
%      EDIT_SIGNAL('Property','Value',...) creates a new EDIT_SIGNAL or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before edit_signal_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to edit_signal_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help edit_signal

% Last Modified by GUIDE v2.5 04-Feb-2014 09:55:37

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @edit_signal_OpeningFcn, ...
                   'gui_OutputFcn',  @edit_signal_OutputFcn, ...
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


% --- Executes just before edit_signal is made visible.
function edit_signal_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to edit_signal (see VARARGIN)

% Choose default command line output for edit_signal
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
    % Call the 'desktop'
    hMain = getappdata(0,'hMain');
    handles.version = 1;
    handles.testsignal(handles.version) = getappdata(hMain,'testsignal');
    % Bring up the data from the selected leaf to be edited
    audiodata = handles.testsignal(handles.version);
    mainHandles = guidata(handles.main_stage1);
    selectedNodes = mainHandles.mytree.getSelectedNodes;
    handles.selNodeName = selectedNodes(1).getName.char;
    audiodatatext = evalc('audiodata');
    set(handles.audiodatatext,'String',['Selected: ' handles.selNodeName audiodatatext]);
    handles.fs = audiodata.fs;
    dur = length(handles.testsignal(handles.version).audio)/handles.fs;
    % Allocate memory space for the edited signal
    handles.rel_time = linspace(0,dur,length(handles.testsignal(handles.version).audio));
    handles.xi(handles.version) = min(handles.rel_time);
    handles.xf(handles.version) = max(handles.rel_time);
    set(handles.OUT_start,'String',num2str(handles.xi(handles.version)));
    set(handles.OUT_end,'String',num2str(handles.xf(handles.version)));
    % Plot signal to be cropped
    if ndims(handles.testsignal(handles.version).audio) > 2
        set(handles.channel_panel,'Visible','on');
        set(handles.IN_nchannel,'String','1');
        set(handles.tchannels,'String',['/ ' num2str(size(handles.testsignal(handles.version).audio,2))]);
        line(:,:) = handles.testsignal(handles.version).audio(:,str2double(get(handles.IN_nchannel,'String')),:);
        cmap = colormap(hsv(size(handles.testsignal(handles.version).audio,3)));
        set(handles.edit_signal,'DefaultAxesColorOrder',cmap)
    else
        set(handles.channel_panel,'Visible','off');
        line = handles.testsignal(handles.version).audio;
        cmap = colormap(lines(size(handles.testsignal(handles.version).audio,2)));
        set(handles.edit_signal,'DefaultAxesColorOrder',cmap)
    end
    plot(handles.IN_axes,handles.rel_time,line)
    xlabel(handles.IN_axes,'Time');
    set(handles.IN_axes,'XTickLabel',num2str(get(handles.IN_axes,'XTick').'))
    % Update handles structure
    guidata(hObject, handles);
    % UIWAIT makes edit_signal wait for user response (see UIRESUME)
    if ndims(audiodata.audio) <= 4
        uiwait(hObject)
    else
        warndlg('Edition of 4-Dimensional audio or greater not yet enabled, sorry!','AARAE info','modal')
    end
end



% --- Outputs from this function are returned to the command line.
function varargout = edit_signal_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.xi(handles.version);
varargout{2} = handles.xf(handles.version);
delete(hObject);


% --- Executes on button press in oo_btn.
function oo_btn_Callback(hObject, eventdata, handles)
% hObject    handle to oo_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Call the main window handles (Consider removing)
mainHandles = guidata(handles.main_stage1);

% Check if there's a chunk or not
if ~isempty(handles.testsignal(handles.version))
    aarae_fig = findobj('type','figure','tag','aarae');
    selectedNodes = mainHandles.mytree.getSelectedNodes;
    removefield = genvarname(selectedNodes(1).getName.char);
    set(mainHandles.(genvarname(removefield)),'Name',handles.selNodeName);
    set(mainHandles.(genvarname(removefield)),'Value',handles.selNodeName);
    mainHandles.(genvarname(handles.selNodeName)) = mainHandles.(genvarname(removefield));
    if ~strcmp(selectedNodes(1).getName.char,handles.selNodeName), mainHandles = rmfield(mainHandles,removefield); end
    mainHandles.(genvarname(handles.selNodeName)).UserData = handles.testsignal(handles.version);
    mainHandles.mytree.reloadNode(mainHandles.(genvarname(handles.selNodeName)).getParent);
    mainHandles.mytree.setSelectedNode(mainHandles.(genvarname(handles.selNodeName)));
    guidata(aarae_fig, mainHandles);
end
guidata(hObject,handles);
uiresume(handles.edit_signal);


% --- Executes on button press in cancel_btn.
function cancel_btn_Callback(hObject, eventdata, handles)
% hObject    handle to cancel_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.OUT_start,'String','-');
set(handles.OUT_end,'String','-');
uiresume(handles.edit_signal);


% --- Executes when user attempts to close edit_signal.
function edit_signal_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to edit_signal (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
uiresume(hObject);


% --- Executes on mouse press over figure background, over a disabled or
% --- inactive control, or over an axes background.
function edit_signal_WindowButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to edit_signal (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

click = get(hObject,'CurrentObject');
obj = get(click,'Type');
if ((click == handles.IN_axes) || strcmp(obj,'line')) % If user clicks anywhere on the axes where current signal is displayed...
    point1 = get(handles.IN_axes,'CurrentPoint');    % button down detected
    rbbox; % return figure units
    point2 = get(handles.IN_axes,'CurrentPoint'); % button up detected
    xi = min(point1(1,1),point2(1,1));
    xf = max(point1(1,1),point2(1,1));
    if (xi >= min(handles.rel_time) && xf <= max(handles.rel_time) && xi ~= xf) % Check if selection is valid
        handles.version = handles.version + 1;
        set([handles.undo_btn handles.reset_btn],'Enable','on');
        set(handles.redo_btn,'Enable','off');
        set(handles.OUT_start,'String',num2str(xi));
        set(handles.OUT_end,'String',num2str(xf));
        % Save the selected chunk in a diferent variable
        handles.testsignal(handles.version) = handles.testsignal(handles.version - 1);
        if handles.timescale == 1
            handles.testsignal(handles.version).audio = handles.testsignal(handles.version - 1).audio(round((xi-min(handles.rel_time))*handles.fs)+1:round((xf-min(handles.rel_time))*handles.fs),:,:);
        elseif handles.timescale == 2
            handles.testsignal(handles.version).audio = handles.testsignal(handles.version - 1).audio(round((xi-min(handles.rel_time)))+1:round((xf-min(handles.rel_time))),:,:);
        end
        handles.rel_time = linspace(xi,xf,length(handles.testsignal(handles.version).audio));
        handles.xi(handles.version) = xi;
        handles.xf(handles.version) = xf;
        handles.timescale(handles.version) = get(handles.timescale_popup,'Value');
        handles.testsignal = handles.testsignal(1:handles.version);
        handles.xi = handles.xi(1:handles.version);
        handles.xf = handles.xf(1:handles.version);
        handles.timescale = handles.timescale(1:handles.version);
        if ndims(handles.testsignal(handles.version).audio) > 2
            set(handles.channel_panel,'Visible','on');
            line(:,:) = handles.testsignal(handles.version).audio(:,str2double(get(handles.IN_nchannel,'String')),:);
            cmap = colormap(hsv(size(handles.testsignal(handles.version).audio,3)));
            set(handles.edit_signal,'DefaultAxesColorOrder',cmap)
        else
            set(handles.channel_panel,'Visible','off');
            line = handles.testsignal(handles.version).audio;
            cmap = colormap(lines(size(handles.testsignal(handles.version).audio,2)));
            set(handles.edit_signal,'DefaultAxesColorOrder',cmap)
        end
        plot(handles.IN_axes,handles.rel_time,line);
        xlabel(handles.IN_axes,'Time');
        set(handles.IN_axes,'XTickLabel',num2str(get(handles.IN_axes,'XTick').'))
        audiodata = handles.testsignal(handles.version);
        mainHandles = guidata(handles.main_stage1);
        selectedNodes = mainHandles.mytree.getSelectedNodes;
        audiodatatext = evalc('audiodata');
        set(handles.audiodatatext,'String',['Selected: ' handles.selNodeName audiodatatext]);
        guidata(hObject,handles);
    else % Display out of boundaries warnings
        warndlg('Data selection out of boundaries','WARNING');
        set(handles.OUT_start,'String',num2str(handles.xi(handles.version)));
        set(handles.OUT_end,'String',num2str(handles.xf(handles.version)));
    end
end



function OUT_start_Callback(hObject, eventdata, handles)
% hObject    handle to OUT_start (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of OUT_start as text
%        str2double(get(hObject,'String')) returns contents of OUT_start as a double
xi = str2num(get(hObject,'String'));
xf = str2num(get(handles.OUT_end,'String'));
if ~isempty(xi) && ~isempty(xf) && xi >= min(handles.rel_time) && xi ~= xf
    handles.version = handles.version + 1;
    set([handles.undo_btn handles.reset_btn],'Enable','on');
    set(handles.redo_btn,'Enable','off');
    handles.testsignal(handles.version) = handles.testsignal(handles.version - 1);
    if get(handles.timescale_popup,'Value') == 1
        handles.testsignal(handles.version).audio = handles.testsignal(handles.version - 1).audio(ceil((xi-min(handles.rel_time))*handles.fs)+1:end,:,:);
    elseif get(handles.timescale_popup,'Value') == 2
        handles.testsignal(handles.version).audio = handles.testsignal(handles.version - 1).audio(ceil((xi-min(handles.rel_time)))+1:end,:,:);
    end
    handles.rel_time = linspace(xi,xf,length(handles.testsignal(handles.version).audio));
    handles.xi(handles.version) = xi;
    handles.xf(handles.version) = handles.xf(handles.version - 1);
    handles.timescale(handles.version) = get(handles.timescale_popup,'Value');
    handles.testsignal = handles.testsignal(1:handles.version);
    handles.xi = handles.xi(1:handles.version);
    handles.xf = handles.xf(1:handles.version);
    handles.timescale = handles.timescale(1:handles.version);
    if ndims(handles.testsignal(handles.version).audio) > 2
        set(handles.channel_panel,'Visible','on');
        line(:,:) = handles.testsignal(handles.version).audio(:,str2double(get(handles.IN_nchannel,'String')),:);
        cmap = colormap(hsv(size(handles.testsignal(handles.version).audio,3)));
        set(handles.edit_signal,'DefaultAxesColorOrder',cmap)
    else
        set(handles.channel_panel,'Visible','off');
        line = handles.testsignal(handles.version).audio;
        cmap = colormap(lines(size(handles.testsignal(handles.version).audio,2)));
        set(handles.edit_signal,'DefaultAxesColorOrder',cmap)
    end
    plot(handles.IN_axes,handles.rel_time,line);
    xlabel(handles.IN_axes,'Time');
    set(handles.IN_axes,'XTickLabel',num2str(get(handles.IN_axes,'XTick').'))
    audiodata = handles.testsignal(handles.version);
    mainHandles = guidata(handles.main_stage1);
    selectedNodes = mainHandles.mytree.getSelectedNodes;
    audiodatatext = evalc('audiodata');
    set(handles.audiodatatext,'String',['Selected: ' handles.selNodeName audiodatatext]);
else % Display out of boundaries warnings
    addsilence = questdlg('Would you like to add silence before the audio data displayed?',...
                          'Data selection out of boundaries',...
                          'Yes', 'No', 'No');
    switch addsilence
        case 'Yes'
            handles.version = handles.version + 1;
            set([handles.undo_btn handles.reset_btn],'Enable','on');
            set(handles.redo_btn,'Enable','off');
            handles.testsignal(handles.version) = handles.testsignal(handles.version - 1);
            if get(handles.timescale_popup,'Value') == 1
                handles.testsignal(handles.version).audio = cat(1,zeros(round(abs(xi-min(handles.rel_time))*handles.fs),size(handles.testsignal(handles.version-1).audio,2),size(handles.testsignal(handles.version-1).audio,3)),handles.testsignal(handles.version - 1).audio);
            elseif get(handles.timescale_popup,'Value') == 2
                handles.testsignal(handles.version).audio = cat(1,zeros(round(abs(xi-min(handles.rel_time))),size(handles.testsignal(handles.version-1).audio,2),size(handles.testsignal(handles.version-1).audio,3)),handles.testsignal(handles.version - 1).audio);
            end
            handles.rel_time = linspace(xi,xf,length(handles.testsignal(handles.version).audio));
            handles.xi(handles.version) = xi;
            handles.xf(handles.version) = handles.xf(handles.version - 1);
            handles.timescale(handles.version) = get(handles.timescale_popup,'Value');
            handles.testsignal = handles.testsignal(1:handles.version);
            handles.xi = handles.xi(1:handles.version);
            handles.xf = handles.xf(1:handles.version);
            handles.timescale = handles.timescale(1:handles.version);
            if ndims(handles.testsignal(handles.version).audio) > 2
                set(handles.channel_panel,'Visible','on');
                line(:,:) = handles.testsignal(handles.version).audio(:,str2double(get(handles.IN_nchannel,'String')),:);
                cmap = colormap(hsv(size(handles.testsignal(handles.version).audio,3)));
                set(handles.edit_signal,'DefaultAxesColorOrder',cmap)
            else
                set(handles.channel_panel,'Visible','off');
                line = handles.testsignal(handles.version).audio;
                cmap = colormap(lines(size(handles.testsignal(handles.version).audio,2)));
                set(handles.edit_signal,'DefaultAxesColorOrder',cmap)
            end
            plot(handles.IN_axes,handles.rel_time,line);
            xlabel(handles.IN_axes,'Time');
            set(handles.IN_axes,'XTickLabel',num2str(get(handles.IN_axes,'XTick').'))
            audiodata = handles.testsignal(handles.version);
            mainHandles = guidata(handles.main_stage1);
            selectedNodes = mainHandles.mytree.getSelectedNodes;
            audiodatatext = evalc('audiodata');
            set(handles.audiodatatext,'String',['Selected: ' handles.selNodeName audiodatatext]);
        case 'No'
            set(handles.OUT_start,'String',num2str(handles.xi(handles.version)));
            set(handles.OUT_end,'String',num2str(handles.xf(handles.version)));
    end
end
guidata(hObject,handles);



function OUT_end_Callback(hObject, eventdata, handles)
% hObject    handle to OUT_end (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of OUT_end as text
%        str2double(get(hObject,'String')) returns contents of OUT_end as a double
xi = str2num(get(handles.OUT_start,'String'));
xf = str2num(get(hObject,'String'));
if ~isempty(xi) && ~isempty(xf) && xf <= max(handles.rel_time) && xi ~= xf
    handles.version = handles.version + 1;
    set([handles.undo_btn handles.reset_btn],'Enable','on');
    set(handles.redo_btn,'Enable','off');
    handles.testsignal(handles.version) = handles.testsignal(handles.version - 1);
    if handles.timescale == 1
        handles.testsignal(handles.version).audio = handles.testsignal(handles.version - 1).audio(1:round((xf-min(handles.rel_time))*handles.fs),:,:);
    elseif handles.timescale == 2
        handles.testsignal(handles.version).audio = handles.testsignal(handles.version - 1).audio(1:round((xf-min(handles.rel_time))),:,:);
    end
    handles.rel_time = linspace(xi,xf,length(handles.testsignal(handles.version).audio));
    handles.xi(handles.version) = handles.xi(handles.version - 1);
    handles.xf(handles.version) = xf;
    handles.timescale(handles.version) = get(handles.timescale_popup,'Value');
    handles.testsignal = handles.testsignal(1:handles.version);
    handles.xi = handles.xi(1:handles.version);
    handles.xf = handles.xf(1:handles.version);
    handles.timescale = handles.timescale(1:handles.version);
    if ndims(handles.testsignal(handles.version).audio) > 2
        set(handles.channel_panel,'Visible','on');
        line(:,:) = handles.testsignal(handles.version).audio(:,str2double(get(handles.IN_nchannel,'String')),:);
        cmap = colormap(hsv(size(handles.testsignal(handles.version).audio,3)));
        set(handles.edit_signal,'DefaultAxesColorOrder',cmap)
    else
        set(handles.channel_panel,'Visible','off');
        line = handles.testsignal(handles.version).audio;
        cmap = colormap(lines(size(handles.testsignal(handles.version).audio,2)));
        set(handles.edit_signal,'DefaultAxesColorOrder',cmap)
    end
    plot(handles.IN_axes,handles.rel_time,line);
    xlabel(handles.IN_axes,'Time');
    set(handles.IN_axes,'XTickLabel',num2str(get(handles.IN_axes,'XTick').'))
    audiodata = handles.testsignal(handles.version);
    mainHandles = guidata(handles.main_stage1);
    selectedNodes = mainHandles.mytree.getSelectedNodes;
    audiodatatext = evalc('audiodata');
    set(handles.audiodatatext,'String',['Selected: ' handles.selNodeName audiodatatext]);
else % Display out of boundaries warnings
    addsilence = questdlg('Would you like to add silence after the audio data displayed?',...
                          'Data selection out of boundaries',...
                          'Yes', 'No', 'No');
    switch addsilence
        case 'Yes'
            handles.version = handles.version + 1;
            set([handles.undo_btn handles.reset_btn],'Enable','on');
            set(handles.redo_btn,'Enable','off');
            handles.testsignal(handles.version) = handles.testsignal(handles.version - 1);
            if get(handles.timescale_popup,'Value') == 1
                handles.testsignal(handles.version).audio = cat(1,handles.testsignal(handles.version - 1).audio,zeros(abs(xf-max(handles.rel_time))*handles.fs,size(handles.testsignal(handles.version-1).audio,2),size(handles.testsignal(handles.version-1).audio,3)));
            elseif get(handles.timescale_popup,'Value') == 2
                handles.testsignal(handles.version).audio = cat(1,handles.testsignal(handles.version - 1).audio,zeros(abs(xf-max(handles.rel_time)),size(handles.testsignal(handles.version-1).audio,2),size(handles.testsignal(handles.version-1).audio,3)));
            end
            handles.rel_time = linspace(xi,xf,length(handles.testsignal(handles.version).audio));
            handles.xi(handles.version) = handles.xi(handles.version - 1);
            handles.xf(handles.version) = xf;
            handles.timescale(handles.version) = get(handles.timescale_popup,'Value');
            handles.testsignal = handles.testsignal(1:handles.version);
            handles.xi = handles.xi(1:handles.version);
            handles.xf = handles.xf(1:handles.version);
            handles.timescale = handles.timescale(1:handles.version);
            if ndims(handles.testsignal(handles.version).audio) > 2
                set(handles.channel_panel,'Visible','on');
                line(:,:) = handles.testsignal(handles.version).audio(:,str2double(get(handles.IN_nchannel,'String')),:);
                cmap = colormap(hsv(size(handles.testsignal(handles.version).audio,3)));
                set(handles.edit_signal,'DefaultAxesColorOrder',cmap)
            else
                set(handles.channel_panel,'Visible','off');
                line = handles.testsignal(handles.version).audio;
                cmap = colormap(lines(size(handles.testsignal(handles.version).audio,2)));
                set(handles.edit_signal,'DefaultAxesColorOrder',cmap)
            end
            plot(handles.IN_axes,handles.rel_time,line);
            xlabel(handles.IN_axes,'Time');
            set(handles.IN_axes,'XTickLabel',num2str(get(handles.IN_axes,'XTick').'))
            audiodata = handles.testsignal(handles.version);
            mainHandles = guidata(handles.main_stage1);
            selectedNodes = mainHandles.mytree.getSelectedNodes;
            audiodatatext = evalc('audiodata');
            set(handles.audiodatatext,'String',['Selected: ' handles.selNodeName audiodatatext]);
        case 'No'
            set(handles.OUT_start,'String',num2str(handles.xi(handles.version)));
            set(handles.OUT_end,'String',num2str(handles.xf(handles.version)));
    end
end
guidata(hObject,handles);


% --- Executes on button press in reset_btn.
function reset_btn_Callback(hObject, eventdata, handles)
% hObject    handle to reset_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    
% Call the 'desktop'
hMain = getappdata(0,'hMain');
audiodata = getappdata(hMain,'testsignal');
% Bring up the data from the selected leaf to be edited
handles.version = handles.version + 1;
set(handles.undo_btn,'Enable','on');
set([handles.redo_btn hObject],'Enable','off');
handles.testsignal(handles.version) = audiodata;
handles.fs = audiodata.fs;
dur = length(handles.testsignal(handles.version).audio)/handles.fs;
% Allocate memory space for the edited signal
handles.rel_time = linspace(0,dur,length(handles.testsignal(handles.version).audio));
handles.xi(handles.version) = min(handles.rel_time);
handles.xf(handles.version) = max(handles.rel_time);
set(handles.OUT_start,'String',num2str(handles.xi(handles.version)));
set(handles.OUT_end,'String',num2str(handles.xf(handles.version)));
set(handles.timescale_popup,'Value',1);
handles.timescale(handles.version) = get(handles.timescale_popup,'Value');
handles.testsignal = handles.testsignal(1:handles.version);
handles.xi = handles.xi(1:handles.version);
handles.xf = handles.xf(1:handles.version);
handles.timescale = handles.timescale(1:handles.version);
% Plot signal to be cropped
if ndims(handles.testsignal(handles.version).audio) > 2
    set(handles.channel_panel,'Visible','on');
    set(handles.IN_nchannel,'String','1');
    set(handles.tchannels,'String',['/ ' num2str(size(handles.testsignal(handles.version).audio,2))]);
    line(:,:) = handles.testsignal(handles.version).audio(:,str2double(get(handles.IN_nchannel,'String')),:);
    cmap = colormap(hsv(size(handles.testsignal(handles.version).audio,3)));
    set(handles.edit_signal,'DefaultAxesColorOrder',cmap)
else
    set(handles.channel_panel,'Visible','off');
    line = handles.testsignal(handles.version).audio;
    cmap = colormap(lines(size(handles.testsignal(handles.version).audio,2)));
    set(handles.edit_signal,'DefaultAxesColorOrder',cmap)
end
plot(handles.IN_axes,handles.rel_time,line)
xlabel(handles.IN_axes,'Time');
set(handles.IN_axes,'XTickLabel',num2str(get(handles.IN_axes,'XTick').'))
audiodata = handles.testsignal(handles.version);
mainHandles = guidata(handles.main_stage1);
selectedNodes = mainHandles.mytree.getSelectedNodes;
audiodatatext = evalc('audiodata');
set(handles.audiodatatext,'String',['Selected: ' handles.selNodeName audiodatatext]);
%    handles.line = findobj(gcf,'type','line');
% Update handles structure
guidata(hObject, handles);


% --- Executes on selection change in edit_box.
function edit_box_Callback(hObject, eventdata, handles)
% hObject    handle to edit_box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns edit_box contents as cell array
%        contents{get(hObject,'Value')} returns selected item from edit_box
contents = cellstr(get(hObject,'String'));
selection = contents{get(hObject,'Value')};
[~,funname] = fileparts(selection);
if ~strcmp(selection,'crop.m')
    handles.funname = funname;
    helptext = evalc(['help ' funname]);
    set(hObject,'Tooltip',helptext);
    set(handles.apply_btn,'Enable','on');
    set(handles.apply_btn,'BackgroundColor',[0.94 0.94 0.94]);
else
    handles.funname = [];
    set(hObject,'Tooltip','Click where you want to begin the cropped selection on the axes, hold down the left mouse button while dragging the pointer over the region that you want to crop, let go of the mouse button when you finish the selection.');
    set(handles.apply_btn,'Enable','off');
end
guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function edit_box_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

curdir = cd;
tools = what([curdir '/Processors/Basic']);
if ~isempty(tools.m)
    set(hObject,'String',['crop.m';cellstr(tools.m)],'Value',1);
else
    set(hObject,'String','crop.m','Value',1);
end
guidata(hObject,handles)


% --- Executes on button press in apply_btn.
function apply_btn_Callback(hObject, eventdata, handles)
% hObject    handle to apply_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(hObject,'BackgroundColor','red');
set(hObject,'Enable','off');
handles.version = handles.version + 1;
processed = feval(handles.funname,handles.testsignal(handles.version - 1));
if ~isempty(processed)
    set([handles.undo_btn handles.reset_btn],'Enable','on');
    set(handles.redo_btn,'Enable','off');
    if isstruct(processed)
        dif = intersect(fieldnames(handles.testsignal(handles.version - 1)),fieldnames(processed));
        newdata = handles.testsignal(handles.version - 1);
        for i = 1:size(dif,1)
            newdata.(dif{i,1}) = processed.(dif{i,1});
        end
    else
        newdata = handles.testsignal(handles.version - 1);
        newdata.audio = processed;
    end
    handles.testsignal(handles.version) = newdata;
    handles.xi(handles.version) = handles.xi(handles.version - 1);
    handles.xf(handles.version) = handles.xf(handles.version - 1);
    handles.timescale(handles.version) = get(handles.timescale_popup,'Value');
    handles.testsignal = handles.testsignal(1:handles.version);
    handles.xi = handles.xi(1:handles.version);
    handles.xf = handles.xf(1:handles.version);
    handles.timescale = handles.timescale(1:handles.version);
    handles.rel_time = linspace(handles.xi(handles.version),handles.xf(handles.version),length(handles.testsignal(handles.version).audio));
    if ndims(handles.testsignal(handles.version).audio) > 2
        set(handles.channel_panel,'Visible','on');
        set(handles.tchannels,'String',['/ ' num2str(size(handles.testsignal(handles.version).audio,2))]);
        line(:,:) = handles.testsignal(handles.version).audio(:,str2double(get(handles.IN_nchannel,'String')),:);
        cmap = colormap(hsv(size(handles.testsignal(handles.version).audio,3)));
        set(handles.edit_signal,'DefaultAxesColorOrder',cmap)
    else
        set(handles.channel_panel,'Visible','off');
        line = handles.testsignal(handles.version).audio;
        cmap = colormap(lines(size(handles.testsignal(handles.version).audio,2)));
        set(handles.edit_signal,'DefaultAxesColorOrder',cmap)
    end
    plot(handles.IN_axes,handles.rel_time,line)
    xlabel(handles.IN_axes,'Time');
    set(handles.IN_axes,'XTickLabel',num2str(get(handles.IN_axes,'XTick').'))
    audiodata = handles.testsignal(handles.version);
    mainHandles = guidata(handles.main_stage1);
    selectedNodes = mainHandles.mytree.getSelectedNodes;
    audiodatatext = evalc('audiodata');
    set(handles.audiodatatext,'String',['Selected: ' handles.selNodeName audiodatatext]);
else
    handles.version = handles.version - 1;
end
set(hObject,'BackgroundColor',[0.94 0.94 0.94]);
set(hObject,'Enable','on');
guidata(hObject, handles);



function IN_nchannel_Callback(hObject, eventdata, handles)
% hObject    handle to IN_nchannel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of IN_nchannel as text
%        str2double(get(hObject,'String')) returns contents of IN_nchannel as a double
channel = str2double(get(handles.IN_nchannel,'String'));

if (channel <= size(handles.testsignal(handles.version).audio,2)) && (channel > 0) && ~isnan(channel)
    handles.channel = channel;
    line(:,:) = handles.testsignal(handles.version).audio(:,channel,:);
    plot(handles.IN_axes,handles.rel_time,line)
    xlabel(handles.IN_axes,'Time');
    set(handles.IN_axes,'XTickLabel',num2str(get(handles.IN_axes,'XTick').'))
else
    warndlg('Invalid channel');
    set(handles.IN_nchannel,'String',num2str(handles.channel));
end
guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function IN_nchannel_CreateFcn(hObject, eventdata, handles)
% hObject    handle to IN_nchannel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
handles.channel = 1;
guidata(hObject,handles)


% --- Executes on selection change in timescale_popup.
function timescale_popup_Callback(hObject, eventdata, handles)
% hObject    handle to timescale_popup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns timescale_popup contents as cell array
%        contents{get(hObject,'Value')} returns selected item from timescale_popup
contents = cellstr(get(hObject,'String'));
timescale = contents{get(hObject,'Value')};

if handles.timescale(handles.version) == 1 && strcmp(timescale,'Samples')
    handles.xi(handles.version) = round(handles.xi(handles.version)*handles.testsignal(handles.version).fs);
    handles.xf(handles.version) = round(handles.xf(handles.version)*handles.testsignal(handles.version).fs);
    set(handles.OUT_start,'String',num2str(handles.xi(handles.version)));
    set(handles.OUT_end,'String',num2str(handles.xf(handles.version)));
    handles.rel_time = linspace(handles.xi(handles.version),handles.xf(handles.version),length(handles.testsignal(handles.version).audio));
    if ndims(handles.testsignal(handles.version).audio) > 2
        line(:,:) = handles.testsignal(handles.version).audio(:,str2double(get(handles.IN_nchannel,'String')),:);
    else
        line = handles.testsignal(handles.version).audio;
    end
    plot(handles.IN_axes,handles.rel_time,line)
    xlabel(handles.IN_axes,'Samples');
    set(handles.IN_axes,'XTickLabel',num2str(get(handles.IN_axes,'XTick').'))
elseif handles.timescale(handles.version) == 2 && strcmp(timescale,'Seconds')
    handles.xi(handles.version) = handles.xi(handles.version)/handles.testsignal(handles.version).fs;
    handles.xf(handles.version) = handles.xf(handles.version)/handles.testsignal(handles.version).fs;
    set(handles.OUT_start,'String',num2str(handles.xi(handles.version)));
    set(handles.OUT_end,'String',num2str(handles.xf(handles.version)));
    handles.rel_time = linspace(handles.xi(handles.version),handles.xf(handles.version),length(handles.testsignal(handles.version).audio));
    if ndims(handles.testsignal(handles.version).audio) > 2
        line(:,:) = handles.testsignal(handles.version).audio(:,str2double(get(handles.IN_nchannel,'String')),:);
    else
        line = handles.testsignal(handles.version).audio;
    end
    plot(handles.IN_axes,handles.rel_time,line)
    xlabel(handles.IN_axes,'Time');
    set(handles.IN_axes,'XTickLabel',num2str(get(handles.IN_axes,'XTick').'))
end
handles.timescale(handles.version) = get(handles.timescale_popup,'Value');

guidata(hObject,handles)


% --- Executes during object creation, after setting all properties.
function timescale_popup_CreateFcn(hObject, eventdata, handles)
% hObject    handle to timescale_popup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

handles.timescale(1) = get(hObject,'Value');
guidata(hObject,handles);


% --- Executes on button press in undo_btn.
function undo_btn_Callback(hObject, eventdata, handles)
% hObject    handle to undo_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.version = handles.version - 1;
set([handles.redo_btn handles.reset_btn],'Enable','on');
set(handles.OUT_start,'String',num2str(handles.xi(handles.version)));
set(handles.OUT_end,'String',num2str(handles.xf(handles.version)));
set(handles.timescale_popup,'Value',handles.timescale(handles.version));
handles.rel_time = linspace(handles.xi(handles.version),handles.xf(handles.version),length(handles.testsignal(handles.version).audio));
if ndims(handles.testsignal(handles.version).audio) > 2
    set(handles.channel_panel,'Visible','on');
    line(:,:) = handles.testsignal(handles.version).audio(:,str2double(get(handles.IN_nchannel,'String')),:);
    cmap = colormap(hsv(size(handles.testsignal(handles.version).audio,3)));
    set(handles.edit_signal,'DefaultAxesColorOrder',cmap)
else
    set(handles.channel_panel,'Visible','off');
    line = handles.testsignal(handles.version).audio;
    cmap = colormap(lines(size(handles.testsignal(handles.version).audio,2)));
    set(handles.edit_signal,'DefaultAxesColorOrder',cmap)
end
plot(handles.IN_axes,handles.rel_time,line);
audiodata = handles.testsignal(handles.version);
mainHandles = guidata(handles.main_stage1);
selectedNodes = mainHandles.mytree.getSelectedNodes;
audiodatatext = evalc('audiodata');
set(handles.audiodatatext,'String',['Selected: ' handles.selNodeName audiodatatext]);
if handles.version == 1, set(hObject,'Enable','off'); end
guidata(hObject,handles);

% --- Executes on button press in redo_btn.
function redo_btn_Callback(hObject, eventdata, handles)
% hObject    handle to redo_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.version = handles.version + 1;
set([handles.undo_btn handles.reset_btn],'Enable','on');
if handles.version <= length(handles.testsignal)
    set(handles.OUT_start,'String',num2str(handles.xi(handles.version)));
    set(handles.OUT_end,'String',num2str(handles.xf(handles.version)));
    set(handles.timescale_popup,'Value',handles.timescale(handles.version));
    handles.rel_time = linspace(handles.xi(handles.version),handles.xf(handles.version),length(handles.testsignal(handles.version).audio));
    if ndims(handles.testsignal(handles.version).audio) > 2
        set(handles.channel_panel,'Visible','on');
        line(:,:) = handles.testsignal(handles.version).audio(:,str2double(get(handles.IN_nchannel,'String')),:);
        cmap = colormap(hsv(size(handles.testsignal(handles.version).audio,3)));
        set(handles.edit_signal,'DefaultAxesColorOrder',cmap)
    else
        set(handles.channel_panel,'Visible','off');
        line = handles.testsignal(handles.version).audio;
        cmap = colormap(lines(size(handles.testsignal(handles.version).audio,2)));
        set(handles.edit_signal,'DefaultAxesColorOrder',cmap)
    end
    plot(handles.IN_axes,handles.rel_time,line);
    audiodata = handles.testsignal(handles.version);
    mainHandles = guidata(handles.main_stage1);
    selectedNodes = mainHandles.mytree.getSelectedNodes;
    audiodatatext = evalc('audiodata');
    set(handles.audiodatatext,'String',['Selected: ' handles.selNodeName audiodatatext]);
    if handles.version == 1, set(hObject,'Enable','off'); end
    if handles.version == length(handles.testsignal), set(hObject,'Enable','off'); end
    guidata(hObject,handles);
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

% Call the 'desktop'
hMain = getappdata(0,'hMain');
audiodata = getappdata(hMain,'testsignal');

if isempty(audiodata)
    warndlg('No signal loaded!');
else
    % Retrieve information from the selected leaf
    testsignal = handles.testsignal(handles.version).audio./max(max(max(abs(handles.testsignal(handles.version).audio))));
    fs = handles.testsignal(handles.version).fs;
    nbits = handles.testsignal(handles.version).nbits;
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


% --- Executes on button press in editfield_btn.
function editfield_btn_Callback(hObject, eventdata, handles)
% hObject    handle to editfield_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
mainHandles = guidata(handles.main_stage1);
selectedNodes = mainHandles.mytree.getSelectedNodes;
if isfield(handles.testsignal(handles.version),'cal')
    prompt = {'Name','Sampling frequency [samples/s]','Bit depth [8,16,32,64]','Calibration offset'};
    defans = {handles.selNodeName,num2str(handles.testsignal(handles.version).fs),num2str(handles.testsignal(handles.version).nbits),num2str(handles.testsignal(handles.version).cal)};
    fields = inputdlg(prompt,'Edit fields',[1 60],defans);
    if ~isempty(fields) && ~isempty(fields{1,1}) && str2num(fields{2,1}) > 0 && (str2num(fields{3,1}) == 8 || str2num(fields{3,1}) == 16 ||str2num(fields{3,1}) == 32 ||str2num(fields{3,1}) == 64) && str2num(fields{4,1})
        oktoedit = 1;
    else
        oktoedit = 0;
    end
else
    prompt = {'Name','Sampling frequency [samples/s]','Bit depth [8,16,32,64]'};
    defans = {handles.selNodeName,num2str(handles.testsignal(handles.version).fs),num2str(handles.testsignal(handles.version).nbits)};
    fields = inputdlg(prompt,'Edit fields',[1 60],defans);
    if ~isempty(fields) && ~isempty(fields{1,1}) && str2num(fields{2,1}) > 0 && (str2num(fields{3,1}) == 8 || str2num(fields{3,1}) == 16 ||str2num(fields{3,1}) == 32 ||str2num(fields{3,1}) == 64)
        oktoedit = 1;
    else
        oktoedit = 0;
    end
end
if oktoedit == 1
    handles.version = handles.version + 1;
    handles.testsignal(handles.version) = handles.testsignal(handles.version - 1);
    handles.xi(handles.version) = handles.xi(handles.version - 1);
    handles.xf(handles.version) = handles.xf(handles.version - 1);
    handles.timescale(handles.version) = get(handles.timescale_popup,'Value');
    handles.testsignal = handles.testsignal(1:handles.version);
    handles.xi = handles.xi(1:handles.version);
    handles.xf = handles.xf(1:handles.version);
    handles.timescale = handles.timescale(1:handles.version);
    handles.selNodeName = fields{1,1};
    handles.testsignal(handles.version).fs = str2num(fields{2,1});
    handles.testsignal(handles.version).nbits = str2num(fields{3,1});
    if isfield(handles.testsignal(handles.version),'cal'), handles.testsignal(handles.version).nbits = str2num(fields{4,1}); end
    audiodata = handles.testsignal(handles.version);
    audiodatatext = evalc('audiodata');
    set(handles.audiodatatext,'String',['Selected: ' handles.selNodeName audiodatatext]);
else
    warndlg('Check inputs and try again','AARAE info');
end
guidata(hObject,handles)


% --- Executes on button press in wn_btn.
function wn_btn_Callback(hObject, eventdata, handles)
% hObject    handle to wn_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
mainHandles = guidata(handles.main_stage1);
if ~isempty(handles.testsignal(handles.version))
    aarae_fig = findobj('type','figure','tag','aarae');
    if strcmp(handles.testsignal(handles.version).datatype,'syscal')
        iconPath = fullfile(matlabroot,'/toolbox/matlab/icons/boardicon.gif');
    else
        iconPath = fullfile(matlabroot,'/toolbox/fixedpoint/fixedpointtool/resources/plot.png');
    end
    handles.selNodeName = [handles.selNodeName '_edit'];
    mainHandles.(genvarname(handles.selNodeName)) = uitreenode('v0', handles.selNodeName, handles.selNodeName,  iconPath, true);
    switch handles.testsignal(handles.version).datatype
        case 'testsignals', ivalue = 1;
        case 'measurements', ivalue = 2;
        case 'syscal', ivalue = 2;
        case 'processed', ivalue = 3;
        case 'results', ivalue = 4;
    end
    [branch,ok] = listdlg('ListString',{'Test signals','Measurements','Processed','Results'},'SelectionMode','single','PromptString','Save edited audio in:','InitialValue',ivalue);
    if ok == 0
        mainHandles.(genvarname(handles.testsignal(handles.version).datatype)).add(mainHandles.(genvarname(handles.selNodeName)));
    else
        if branch == 1, mainHandles.testsignals.add(mainHandles.(genvarname(handles.selNodeName))); handles.testsignal(handles.version).datatype = 'testsignals'; end
        if branch == 2, mainHandles.measurements.add(mainHandles.(genvarname(handles.selNodeName))); handles.testsignal(handles.version).datatype = 'measurements'; end
        if branch == 3, mainHandles.processed.add(mainHandles.(genvarname(handles.selNodeName))); handles.testsignal(handles.version).datatype = 'processed'; end
        if branch == 4, mainHandles.results.add(mainHandles.(genvarname(handles.selNodeName))); handles.testsignal(handles.version).datatype = 'results'; end
    end
    if strcmp(handles.testsignal(handles.version-1).datatype,'syscal'), handles.testsignal(handles.version).datatype = 'syscal'; end
    mainHandles.(genvarname(handles.selNodeName)).UserData = handles.testsignal(handles.version);
    mainHandles.mytree.reloadNode(mainHandles.(genvarname(handles.selNodeName)).getParent);
    mainHandles.mytree.setSelectedNode(mainHandles.(genvarname(handles.selNodeName)));
    guidata(aarae_fig, mainHandles);
end
guidata(hObject,handles);
uiresume(handles.edit_signal);
