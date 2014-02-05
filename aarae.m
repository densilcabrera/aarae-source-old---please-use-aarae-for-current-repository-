% DO NOT EDIT THIS INITIALIZATION FUNCTION!!!!!!!!!!!!!!!!!!!!!!!!!!!
function varargout = aarae(varargin)
% AARAE MATLAB code for aarae.fig
%      AARAE, by itself, creates a new AARAE or raises the existing
%      singleton*.
%
%      H = AARAE returns the handle to a new AARAE or the handle to
%      the existing singleton*.
%
%      AARAE('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in AARAE.M with the given input arguments.
%
%      AARAE('Property','Value',...) creates a new AARAE or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before aarae_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to aarae_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help aarae

% Last Modified by GUIDE v2.5 04-Feb-2014 10:49:56

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @aarae_OpeningFcn, ...
                   'gui_OutputFcn',  @aarae_OutputFcn, ...
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


% --- Executes just before aarae is made visible.
function aarae_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to aarae
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to aarae (see VARARGIN)

% Choose default command line output for aarae
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% Setup the 'desktop'
setappdata(0, 'hMain', gcf);
hMain = getappdata(0,'hMain');
setappdata(hMain,'testsignal',[]);

% In case there are multiple main windows (currently unused until line 81)
mainGuiInput = find(strcmp(varargin, 'data'));
if isempty(mainGuiInput) == 0
    data = varargin{mainGuiInput+1};
    if isempty(data.testsignal) == 0
        hMain = getappdata(0,'hMain');
        setappdata(hMain,'testsignal',data.testsignal);
        setappdata(hMain,'fs',data.fs);
        setappdata(hMain,'nbits',data.nbits);
        setappdata(hMain,'datatype',data.datatype);
        %set(handles.datatypetext,'String',data.datatype);
        t = linspace(0,length(data.testsignal),length(data.testsignal))./data.fs;
        plot(t,data.testsignal);
    end
end
mkdir([cd '/Utilities/Temp']);
% Add folder paths for filter functions and signal analyzers
addpath(genpath(cd));
handles.player = [];
[handles.reference_audio.audio, handles.reference_audio.fs] = wavread('REFERENCE_AUDIO.wav');

% Setup for Densil's tree
iconPath = fullfile(matlabroot,'/toolbox/matlab/icons/matlabicon.gif');
handles.root = uitreenode('v0', 'project', 'My project', iconPath, false);

iconPath = fullfile(matlabroot,'/toolbox/matlab/icons/foldericon.gif');
handles.testsignals = uitreenode('v0', 'testsignals', 'Test signals', iconPath, false);
handles.measurements = uitreenode('v0', 'measurements', 'Measurements', iconPath, false);
handles.processed = uitreenode('v0', 'processed', 'Processed', iconPath, false);
handles.results = uitreenode('v0', 'results', 'Results', iconPath, false);

handles.root.add(handles.testsignals);
handles.root.add(handles.measurements);
handles.root.add(handles.processed);
handles.root.add(handles.results);

[handles.mytree container] = uitree('v0','Root', handles.root,'SelectionChangeFcn',@mySelectFcn);
set(container, 'Parent', hObject);
treeheight_char = get(handles.process_panel,'Position')+get(handles.analysis_panel,'Position')+get(handles.uipanel1,'Position');
treewidth_char = get(handles.analysis_panel,'Position');
set(handles.analysis_panel,'Units','pixels');
treewidth_pix = get(handles.analysis_panel,'Position');
factor = treewidth_pix./treewidth_char;
set(handles.mytree,'Position',[0,treewidth_char(1,2)*factor(1,2),treewidth_char(1,1)*factor(1,1),treeheight_char(1,4)*factor(1,4)]);
handles.mytree.expand(handles.root);
handles.mytree.setSelectedNode(handles.root);

% Generate activity log 
activity = dir([cd '/Log' '/activity log.txt']);
if isempty(activity)
    activitylog = '/activity log.txt';
    handles.fid = fopen([cd '/Log' activitylog], 'w');
else
    index = 1;
    % This while cycle is just to make sure no files are overwriten
    while isempty(dir([cd '/Log' '/activity log ',num2str(index),'.txt'])) == 0
        index = index + 1;
    end
    activitylog = ['/activity log ',num2str(index),'.txt'];
    handles.fid = fopen([cd '/Log' activitylog], 'w');
end
handles.alternate = 0;
fprintf(handles.fid, ['Acoustic processing app started ' datestr(now) ' \n\n']);
guidata(hObject, handles);

% Set waiting flag in appdata
setappdata(handles.aarae,'waiting',1)
% UIWAIT makes aarae wait for user response (see UIRESUME)
uiwait(handles.aarae);


% --- Outputs from this function are returned to the command line.
function varargout = aarae_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to aarae
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Clean up the mess after closing the GUI
rmappdata(0,'hMain');
rmpath(genpath(cd));
rmdir([cd '/Utilities/Temp'],'s');
fprintf(handles.fid, ['\n- End of file - ' datestr(now)]);
fclose('all');
if ~isempty(handles.aarae)
    delete(handles.aarae);
end
% Get default command line output from handles structure
varargout{1} = [];


% --- Executes on button press in genaudio_btn.
function genaudio_btn_Callback(hObject, eventdata, handles)
% hObject    handle to genaudio_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Call the 'desktop'
hMain = getappdata(0,'hMain');
setappdata(hMain,'testsignal',[]);

% Call the window that allows signal generation 
newleaf = genaudio('main_stage1', handles.aarae);

% Update the tree with the generated signal
handles.mytree.setSelectedNode(handles.root);
if ~isempty(getappdata(hMain,'testsignal'))
    signaldata = getappdata(hMain,'testsignal');
    if isfield(signaldata,'tag'), signaldata = rmfield(signaldata,'tag'); end
    signaldata.datatype = 'testsignals';
    if isfield(signaldata,'audio')
        signaldata.nbits = 16;
        iconPath = fullfile(matlabroot,'/toolbox/fixedpoint/fixedpointtool/resources/plot.png');
    else
        iconPath = fullfile(matlabroot,'/toolbox/matlab/icons/notesicon.gif');
    end
    leafname = isfield(handles,genvarname(newleaf));
    if leafname == 1
        index = 1;
        % This while cycle is just to make sure no signals are
        % overwriten
        while isfield(handles,genvarname([newleaf,'_',num2str(index)])) == 1
            index = index + 1;
        end
        newleaf = [newleaf,' ',num2str(index)];
    end
    handles.(genvarname(newleaf)) = uitreenode('v0', newleaf,  newleaf,  iconPath, true);
    handles.(genvarname(newleaf)).UserData = signaldata;
    handles.testsignals.add(handles.(genvarname(newleaf)));
    handles.mytree.reloadNode(handles.testsignals);
    handles.mytree.expand(handles.testsignals);
    handles.mytree.setSelectedNode(handles.(genvarname(newleaf)));
    set([handles.clrall_btn,handles.export_btn],'Enable','on')
    fprintf(handles.fid, [' ' datestr(now,16) ' - Generated ' newleaf ': duration = ' num2str(length(signaldata.audio)/signaldata.fs) 's ; fs = ' num2str(signaldata.fs) 'Hz ; bit depth = ' num2str(signaldata.nbits) '\n']);
end
guidata(hObject, handles);


% --- Executes when user attempts to close aarae.
function aarae_CloseRequestFcn(hObject,eventdata,handles)
% hObject    handle to aarae (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Check appdata flag to see if the main GUI is in a wait state
if getappdata(handles.aarae,'waiting')
    % The GUI is still in UIWAIT, so call UIRESUME and return
    uiresume(hObject);
    setappdata(handles.aarae,'waiting',0);
else
    % The GUI is no longer waiting, so destroy it now.
    delete(hObject);
end


% --- Executes on button press in save_btn.
function save_btn_Callback(hObject, eventdata, handles)
% hObject    handle to save_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Call the 'desktop'
%hMain = getappdata(0,'hMain');
%audiodata = getappdata(hMain,'testsignal');
selectedNodes = handles.mytree.getSelectedNodes;
audiodata = selectedNodes(1).handle.UserData;

if isempty(audiodata) %Check if there's data to save
    warndlg('No signal loaded!');
else
    name = inputdlg('File name: (Please specify .wav for wave files)','Save as MATLAB File'); %Request file name
    if ~isempty(name)
        name = name{1,1};
        [~,name,ext]=fileparts(name);
        if strcmp(ext,'.mat'), ensave = 1;
        elseif strcmp(ext,'.wav'), ensave = 1;
        elseif isempty(ext), ensave = 1; 
        else ensave = 0;
        end
    end
    if isempty(name) || ensave == 0
        warndlg('No data saved');
    else
        if isempty(ext), ext = '.mat'; end
        if strcmp(ext,'.wav') && (~isfield(audiodata,'audio') || ~isfield(audiodata,'fs')), ext = '.mat'; end
        listing = dir([name ext]);
        if isempty(listing)
            if strcmp(ext,'.mat'), save(name,'audiodata'); end
            if strcmp(ext,'.wav'), wavwrite(audiodata.audio,audiodata.fs,name); end
        else
            index = 1;
            % This while cycle is just to make sure no signals are
            % overwriten
            while isempty(dir([name,' ',num2str(index),ext])) == 0
                index = index + 1;
            end
            name = [name,' ',num2str(index),ext];
            if strcmp(ext,'.mat'), save(name,'audiodata'); end
            if strcmp(ext,'.wav'), wavwrite(audiodata.audio,audiodata.fs,name); end
        end
        selectedNodes = handles.mytree.getSelectedNodes;
        selectedNodes = selectedNodes(1);
        current = cd;
        fprintf(handles.fid, [' ' datestr(now,16) ' - Saved "' char(selectedNodes.getName) '" to file "' name ext '" in folder "%s"' '\n'],current);
    end
end
guidata(hObject, handles);


% --- Executes on button press in load_btn.
function load_btn_Callback(hObject, eventdata, handles)
% hObject    handle to load_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get path of the file to load
[filename,pathname,filterindex] = uigetfile(...
    {'*.wav;*.mat','Test Signals (*.wav,*.mat)';...
    '*.wav;*.mat','Measurement files (*.wav,*.mat)';...
    '*.wav;*.mat','Processed files (*.wav,*.mat)';...
    '*.wav;*.mat','Result files (*.wav,*.mat)'});

if filename ~= 0
    % Check type of file. First 'if' is for .mat, second is for .wav
    if ~isempty(regexp(filename, '.mat', 'once'))
        file = importdata(fullfile(pathname,filename));
        % First part of this if could be used for calling personalized
        % extension app files
        if isstruct(file)
            signaldata = file;
%            testsignal = file.audio;
%            audio2 = file.audio2;
%            fs = file.fs;
%            nbits = file.nbits;
        else
            % Until here
            specs = inputdlg({'Please specify the sampling frequency','Please specify the bit depth'},'Sampling frequency',2);
            if (isempty(specs))
                w = warndlg('Input field is blank, cannot load data!');
                signaldata = [];
%                testsignal = [];
            else
                fs = str2num(specs{1,1});
                nbits = str2num(specs{2,1});
                if (isempty(fs) || fs<=0 || isempty(nbits) || nbits<=0)
                    warndlg('Input MUST be a real positive number, cannot load data!');
                    signaldata = [];
%                    testsignal = [];
                else
                    signaldata.audio = file;
                    signaldata.fs = fs;
                    signaldata.nbits = nbits;
%                    testsignal = file;
%                    audio2 = [];                
                end
            end
        end
    end
    if ~isempty(regexp(filename, '.wav', 'once'))
        [signaldata.audio,signaldata.fs,signaldata.nbits] = wavread(fullfile(pathname,filename));
    end;
    
    % Generate new leaf and update the tree
    newleaf = filename;
    if ~isempty(signaldata)
%        signaldata = struct;
%        signaldata.audio = testsignal;
%        signaldata.audio2 = audio2;
%        signaldata.fs = fs;
%        signaldata.nbits = nbits;
        if ~isfield(signaldata,'datatype')
            if filterindex == 1, signaldata.datatype = 'testsignals'; end;
            if filterindex == 2, signaldata.datatype = 'measurements'; end;
            if filterindex == 3, signaldata.datatype = 'processed'; end;
            if filterindex == 4, signaldata.datatype = 'results'; end;
        end
        if isfield(signaldata,'audio')
            iconPath = fullfile(matlabroot,'/toolbox/fixedpoint/fixedpointtool/resources/plot.png');
        else
            iconPath = fullfile(matlabroot,'/toolbox/matlab/icons/notesicon.gif');
        end
        handles.(genvarname(newleaf)) = uitreenode('v0', newleaf,  newleaf,  iconPath, true);
        handles.(genvarname(newleaf)).UserData = signaldata;
        handles.(genvarname(signaldata.datatype)).add(handles.(genvarname(newleaf)));
        handles.mytree.reloadNode(handles.(genvarname(signaldata.datatype)));
        handles.mytree.expand(handles.(genvarname(signaldata.datatype)));
        handles.mytree.setSelectedNode(handles.(genvarname(newleaf)));
        set([handles.clrall_btn,handles.export_btn],'Enable','on')
        fprintf(handles.fid, [' ' datestr(now,16) ' - Loaded "' filename '" to branch "' char(handles.(genvarname(signaldata.datatype)).getName) '"\n']);
    end
    guidata(hObject, handles);
end



% --- Executes on button press in rec_btn.
function rec_btn_Callback(hObject, eventdata, handles)
% hObject    handle to rec_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Call the 'desktop'
hMain = getappdata(0,'hMain');

%set(handles.datatypetext,'String','No signal loaded');

% Call the audio recorder window
audio_recorder('main_stage1', handles.aarae);

% Generate new leaf and update tree with the recording
handles.mytree.setSelectedNode(handles.root);
newleaf = getappdata(hMain,'signalname');
if ~isempty(getappdata(hMain,'testsignal'))
    signaldata = struct;
    signaldata.audio = getappdata(hMain,'testsignal');
    if ~isempty(getappdata(hMain,'invtestsignal')), signaldata.audio2 = getappdata(hMain,'invtestsignal'); end
    signaldata.fs = getappdata(hMain,'fs');
    signaldata.nbits = getappdata(hMain,'nbits');
    signaldata.datatype = 'measurements';
    iconPath = fullfile(matlabroot,'/toolbox/fixedpoint/fixedpointtool/resources/plot.png');
    leafname = isfield(handles,genvarname(newleaf));
    if leafname == 1
        index = 1;
        % This while cycle is just to make sure no signals are
        % overwriten
        while isfield(handles,genvarname([newleaf,'_',num2str(index)])) == 1
            index = index + 1;
        end
        newleaf = [newleaf,' ',num2str(index)];
    end
    handles.(genvarname(newleaf)) = uitreenode('v0', newleaf,  newleaf,  iconPath, true);
    handles.(genvarname(newleaf)).UserData = signaldata;
    handles.measurements.add(handles.(genvarname(newleaf)));
    handles.mytree.reloadNode(handles.measurements);
    handles.mytree.expand(handles.measurements);
    handles.mytree.setSelectedNode(handles.(genvarname(newleaf)));
    set([handles.clrall_btn,handles.export_btn],'Enable','on')
    fprintf(handles.fid, [' ' datestr(now,16) ' - Recorded "' newleaf '": duration = ' num2str(length(signaldata.audio)/signaldata.fs) 's\n']);
end
guidata(hObject, handles);


% --- Executes on button press in edit_btn.
function edit_btn_Callback(hObject, eventdata, handles)
% hObject    handle to edit_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Call the 'desktop'
hMain = getappdata(0,'hMain');
signaldata = getappdata(hMain,'testsignal');

if isempty(signaldata), warndlg('No signal loaded!','Whoops...!');
%elseif ndims(signaldata.audio) > 2, warndlg('Cannot edit file!','Whoops...!');
else
    % Call editing window
    [xi xf] = edit_signal('main_stage1', handles.aarae);
    % Update tree with edited signal
    if ~isempty(xi) && ~isempty(xf)
        selectedNodes = handles.mytree.getSelectedNodes;
        selectedNodes = selectedNodes(1);
        fprintf(handles.fid, [' ' datestr(now,16) ' - Edited "' char(selectedNodes.getName) '": cropped from %fs to %fs; new duration = ' num2str(length(signaldata.audio)/signaldata.fs) 's\n'],xi,xf);
    else
        handles.mytree.setSelectedNode(handles.root);
    end
end


% --- Executes on button press in export_btn.
function export_btn_Callback(hObject, eventdata, handles)
% hObject    handle to export_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

root = handles.root; % Get selected leaf
root = root(1);
first = root.getFirstChild;
branches{1,:} = char(first.getValue);
next = first.getNextSibling;
for n = 1:root.getChildCount-1
    branches{n+1,:} = char(next.getValue);
    next = next.getNextSibling;
end
branches = char(branches);

i = 0;
for n = 1:size(branches,1)
    currentbranch = handles.(genvarname(branches(n,:)));
    if currentbranch.getChildCount ~= 0
        i = i + 1;
        first = currentbranch.getFirstChild;
        leafnames(i,:) = first.getName;
        leaves{i,:} = char(first.getValue);
        next = first.getNextSibling;
        if ~isempty(next)
            for m = 1:currentbranch.getChildCount-1
                i = i + 1;
                leafnames(i,:) = next.getName;
                leaves{i,:} = char(next.getValue);
                next = next.getNextSibling;
            end
        end
    end
end
if ~exist('leafnames')
    warndlg('Nothing to export!','AARAE info');
else
    leafnames = char(leafnames);
    leaves = char(leaves);
    folder = inputdlg('Folder name','Export all',[1 60],{'New Project'});
    [~,mess,~] = mkdir('Projects',char(folder));
    if ~isempty(mess)
        warndlg(mess,'AARAE info');
    else
        set(hObject,'BackgroundColor','red');
        set(hObject,'Enable','off');
        for i = 1:size(leafnames,1)
            current = handles.(genvarname(leaves(i,:)));
            current = current(1);
            data = current.handle.UserData;
            save([cd '/Projects/' char(folder) '/' leafnames(i,:) '.mat'], 'data');
        end
        if isdir([cd '/Utilities/Temp'])
            nfigs = dir([cd '/Utilities/Temp/*.fig']);
            copyfile([cd '/Utilities/Temp'],[cd '/Projects/' char(folder) '/figures']);
        end
        current = [cd '/Projects/' char(folder)];
        addpath(genpath([cd '/Projects']))
        fprintf(handles.fid, [' ' datestr(now,16) ' - Exported ' num2str(size(leafnames,1)) ' data files and ' num2str(size(nfigs,1)) ' figures to "%s" \n'],current);
        set(hObject,'BackgroundColor',[0.94 0.94 0.94]);
        set(hObject,'Enable','off');
    end
end
guidata(hObject,handles)

% --- Executes on button press in finish_btn.
function finish_btn_Callback(hObject, eventdata, handles)
% hObject    handle to finish_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if strcmp(get(handles.export_btn,'Enable'),'on')
    choice = questdlg('Are you sure to want to finish this AARAE session? Unexported data will be lost.',...
                      'Exit AARAE',...
                      'Yes','No','Export all & exit','Yes');
    switch choice
        case 'Yes'
            uiresume(handles.aarae);
        case 'Export all & exit'
            export_btn_Callback(handles.export_btn,eventdata,handles)
            uiresume(handles.aarae);
    end
else
    uiresume(handles.aarae);
end


% --- Executes on button press in delete_btn.
function delete_btn_Callback(hObject, eventdata, handles)
% hObject    handle to delete_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Call the 'desktop'
hMain = getappdata(0,'hMain');
delete = questdlg('Current data will be lost, would you like to proceed?',...
    'Warning',...
    'Yes','No','No');
switch delete
    case 'Yes'
        % Deletes selected leaf from the tree
        setappdata(hMain,'testsignal',[]);
        set(handles.IR_btn, 'Visible', 'off');
        selectedNodes = handles.mytree.getSelectedNodes;
        selectedParent = selectedNodes(1).getParent;
        handles.mytree.remove(selectedNodes(1));
        handles.mytree.reloadNode(selectedParent);
        handles.mytree.setSelectedNode(handles.root);
        handles = rmfield(handles,genvarname(char(selectedNodes(1).getName)));
        fprintf(handles.fid, [' ' datestr(now,16) ' - Deleted "' char(selectedNodes(1).getName) '" from branch "' char(selectedParent.getName) '"\n']);
        guidata(hObject, handles);
    case 'No'
        guidata(hObject, handles);
end


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
    testsignal = audiodata.audio./max(max(max(abs(audiodata.audio))));
    fs = audiodata.fs;
    nbits = audiodata.nbits;
    doesSupport = audiodevinfo(0, handles.odeviceid, fs, nbits, size(testsignal,2));
    if doesSupport && ndims(testsignal) < 3
        % Play signal
        handles.player = audioplayer(testsignal,fs,nbits,handles.odeviceid);
        play(handles.player);
        set(handles.stop_btn,'Visible','on');
        selectedNodes = handles.mytree.getSelectedNodes;
        contents = cellstr(get(handles.device_popup,'String'));
        fprintf(handles.fid, [' ' datestr(now,16) ' - Played "' char(selectedNodes(1).getName) '" using ' contents{get(hObject,'Value')} '\n']);
    else
        warndlg('Device not supported for playback!');
    end
end
guidata(hObject, handles);


% --- Executes on button press in IR_btn.
function IR_btn_Callback(hObject, eventdata, handles)
% hObject    handle to IR_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hMain = getappdata(0,'hMain');
audiodata = getappdata(hMain,'testsignal');
S = audiodata.audio;
invS = audiodata.audio2;
fs = audiodata.fs;
nbits = audiodata.nbits;
selectedNodes = handles.mytree.getSelectedNodes;

% Get the lines below in a function
% Maybe more alternatives to processing IRs should be implemented
S_pad = [S; zeros(size(invS))];
invS_pad = [invS; zeros(size(S))];
IR = convolvedemo(S_pad, invS_pad, 2, fs); % Calls convolvedemo.m
IRlength = window_signal('main_stage1', handles.aarae,'IR',IR); % Calls the trimming GUI window to trim the IR
[~, id] = max(abs(IR));
trimsamp_low = id-round(IRlength./2);
trimsamp_high = trimsamp_low + IRlength -1;
IR = IR(trimsamp_low:trimsamp_high,:);
% Add calibration?

% Create new leaf and update the tree
handles.mytree.setSelectedNode(handles.root);
newleaf = 'IR';
if ~isempty(getappdata(hMain,'testsignal'))
    signaldata = struct;
    signaldata.audio = IR;
    signaldata.fs = fs;
    signaldata.nbits = nbits;
    signaldata.datatype = 'IR';
    iconPath = fullfile(matlabroot,'/toolbox/fixedpoint/fixedpointtool/resources/plot.png');
    handles.(genvarname(newleaf)) = uitreenode('v0', newleaf,  newleaf,  iconPath, true);
    handles.(genvarname(newleaf)).UserData = signaldata;
    handles.measurements.add(handles.(genvarname(newleaf)));
    handles.mytree.reloadNode(handles.measurements);
    handles.mytree.expand(handles.measurements);
    handles.mytree.setSelectedNode(handles.(genvarname(newleaf)));
    set([handles.clrall_btn,handles.export_btn],'Enable','on')
    fprintf(handles.fid, [' ' datestr(now,16) ' - Processed "' char(selectedNodes(1).getName) '" to generate an impulse response of ' num2str(IRlength) ' points\n']);
end
set(handles.IR_btn, 'Visible', 'off');

guidata(hObject, handles);


% --- Executes on selection change in funcat_box.
function funcat_box_Callback(hObject, eventdata, handles)
% hObject    handle to funcat_box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns funcat_box contents as cell array
%        contents{get(hObject,'Value')} returns selected item from funcat_box

% Displays the available analysers for the selected processing category
contents = cellstr(get(hObject,'String'));
handles.funcat = contents{get(hObject,'Value')};
analyzers = what([cd '/Analysers/' handles.funcat]);
if ~isempty(cellstr(analyzers.m))
    set(handles.fun_box,'Visible','on','String',[' ';cellstr(analyzers.m)],'Value',1,'Tooltip','');
    set(handles.analyze_btn,'Visible','off');
else
    set(handles.fun_box,'Visible','off');
    set(handles.analyze_btn,'Visible','off');
end
guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function funcat_box_CreateFcn(hObject, eventdata, handles)
% hObject    handle to funcat_box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% Populate function box with the function available in the folder 'Analysers'
curdir = cd;
analyzers = dir([curdir '/Analysers']);
set(hObject,'String',[' ';cellstr({analyzers(3:length(analyzers)).name}')]);
handles.funname = [];
guidata(hObject,handles)


% --- Executes on button press in analyze_btn.
function analyze_btn_Callback(hObject, eventdata, handles)
% hObject    handle to analyze_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Analyses the selected leaf using the function selected from fun_box
% Call the 'desktop'
hMain = getappdata(0,'hMain');
audiodata = getappdata(hMain,'testsignal');
selectedNodes = handles.mytree.getSelectedNodes;
% Evaluate selected function for the leaf selected from the tree
if ~isempty(handles.funname) && ~isempty(audiodata)
    set(hObject,'BackgroundColor','red');
    set(hObject,'Enable','off');
    if nargout(handles.funname) == 1
        out = feval(handles.funname,audiodata);
    else
        out = [];
        feval(handles.funname,audiodata);
    end
    set(hObject,'BackgroundColor',[0.94 0.94 0.94]);
    set(hObject,'Enable','on');
    h = findobj('type','figure','-not','tag','aarae');
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
    set(handles.result_box,'String',[' ';cellstr({results(3:length(results)).name}')]);
    
    handles.mytree.setSelectedNode(handles.root);
    newleaf = [char(selectedNodes(1).getName) ' ' handles.funname];
    if ~isempty(out)
        signaldata = out;
        signaldata.datatype = 'results';
        if isfield(signaldata,'audio')
            iconPath = fullfile(matlabroot,'/toolbox/fixedpoint/fixedpointtool/resources/plot.png');
        else
            iconPath = fullfile(matlabroot,'/toolbox/matlab/icons/notesicon.gif');
        end
        leafname = isfield(handles,genvarname(newleaf));
        if leafname == 1
            index = 1;
            % This while cycle is just to make sure no signals are
            % overwriten
            while isfield(handles,genvarname([newleaf,'_',num2str(index)])) == 1
                index = index + 1;
            end
            newleaf = [newleaf,' ',num2str(index)];
        end
        handles.(genvarname(newleaf)) = uitreenode('v0', newleaf,  newleaf,  iconPath, true);
        handles.(genvarname(newleaf)).UserData = signaldata;
        handles.results.add(handles.(genvarname(newleaf)));
        handles.mytree.reloadNode(handles.results);
        handles.mytree.expand(handles.results);
        handles.mytree.setSelectedNode(handles.(genvarname(newleaf)));
        set([handles.clrall_btn,handles.export_btn],'Enable','on')
    end
    fprintf(handles.fid, [' ' datestr(now,16) ' - Analyzed "' char(selectedNodes(1).getName) '" using ' handles.funname ' in ' handles.funcat '\n']);% In what category???
    %result = msgbox(evalc('out'),'Result');
end
guidata(hObject,handles)


% --- Executes on selection change in fun_box.
function fun_box_Callback(hObject, eventdata, handles)
% hObject    handle to fun_box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns fun_box contents as cell array
%        contents{get(hObject,'Value')} returns selected item from fun_box

% Allows 'help' display when mouse is hoovered over fun_box
contents = cellstr(get(hObject,'String'));
selection = contents{get(hObject,'Value')};
[~,funname] = fileparts(selection);
if ~strcmp(selection,' ')
    handles.funname = funname;
    helptext = evalc(['help ' funname]);
    set(hObject,'Tooltip',helptext);
    set(handles.analyze_btn,'Visible','on');
    set(handles.analyze_btn,'BackgroundColor',[0.94 0.94 0.94]);
    set(handles.analyze_btn,'Enable','on');
else
    handles.funname = [];
    set(hObject,'Tooltip','');
    set(handles.analyze_btn,'Visible','off');
end
guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function fun_box_CreateFcn(hObject, eventdata, handles)
% hObject    handle to fun_box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in procat_box.
function procat_box_Callback(hObject, eventdata, handles)
% hObject    handle to procat_box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns procat_box contents as cell array
%        contents{get(hObject,'Value')} returns selected item from procat_box

% Displays the processes available for the selected process category
hMain = getappdata(0,'hMain');
signaldata = getappdata(hMain,'testsignal');

contents = cellstr(get(hObject,'String'));
handles.procat = contents{get(hObject,'Value')};
processes = what([cd '/Processors/' handles.procat]);
%prebuilt = what([cd '/Processors/' handles.procat '/' num2str(signaldata.fs) 'Hz']); % Check for prebuilt filterbanks for the specified smapling frequency
%if ~isempty(prebuilt)
%    prebuilt = prebuilt.mat;
%else
%    prebuilt = [];
%end
if ~isempty(processes.m)% || ~isempty(prebuilt)
    %set(handles.proc_box,'Visible','on','String',[' ';cellstr([processes.m;prebuilt])],'Value',1);
    set(handles.proc_box,'Visible','on','String',[' ';cellstr(processes.m)],'Value',1);
    set(handles.proc_btn,'Visible','off');
else
    set(handles.proc_box,'Visible','off');
    set(handles.proc_btn,'Visible','off');
end
guidata(hObject,handles);


% --- Executes during object creation, after setting all properties.
function procat_box_CreateFcn(hObject, eventdata, handles)
% hObject    handle to procat_box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% Displays the process categories available in the Processors folder

curdir = cd;
processes = dir([curdir '/Processors']);
set(hObject,'String',[' ';cellstr({processes(3:length(processes)).name}')]);
handles.funname = [];
guidata(hObject,handles)

% --- Executes on selection change in proc_box.
function proc_box_Callback(hObject, eventdata, handles)
% hObject    handle to proc_box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns proc_box contents as cell array
%        contents{get(hObject,'Value')} returns selected item from proc_box
contents = cellstr(get(hObject,'String'));
selection = contents{get(hObject,'Value')};
[~,funname] = fileparts(selection);
if ~strcmp(selection,' ')
    handles.funname = funname;
    helptext = evalc(['help ' funname]);
    set(hObject,'Tooltip',helptext);
    set(handles.proc_btn,'Visible','on');
    set(handles.proc_btn,'BackgroundColor',[0.94 0.94 0.94]);
    set(handles.proc_btn,'Enable','on');
else
    handles.funname = [];
    set(hObject,'Tooltip','');
    set(handles.proc_btn,'Visible','off');
end
guidata(hObject,handles);


% --- Executes during object creation, after setting all properties.
function proc_box_CreateFcn(hObject, eventdata, handles)
% hObject    handle to proc_box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in proc_btn.
function proc_btn_Callback(hObject, eventdata, handles)
% hObject    handle to proc_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hMain = getappdata(0,'hMain');
signaldata = getappdata(hMain,'testsignal');
set(hObject,'BackgroundColor','red');
set(hObject,'Enable','off');
% Processes the selected leaf using the selected process from proc_box
contents = cellstr(get(handles.procat_box,'String'));
category = contents{get(handles.procat_box,'Value')};
contents = cellstr(get(handles.proc_box,'String'));
file = contents(get(handles.proc_box,'Value'));
name = handles.mytree.getSelectedNodes;
name = name(1).getName.char;
for multi = 1:size(file,1)
    processed = [];
    [~,~,ext] = fileparts(file{multi,1});
    if strcmp(ext,'.mat')
        content = load([cd '/Processors/' category '/' num2str(signaldata.fs) 'Hz/' char(file(multi,:))]);
        filterbank = content.filterbank;
        w = whos('filterbank');
        if strcmp(w.class,'dfilt.df2sos')
            for i = 1:length(filterbank)
                for j = 1:min(size(signaldata.audio))
                    processed(:,j,i) = filter(filterbank(1,i),signaldata.audio(:,j));
                end
            end
            bandID = [];
        elseif strcmp(w.class,'double')    
            processed = filter(filterbank,1,signaldata.audio);
        end
    elseif strcmp(ext,'.m')
        [~,funname] = fileparts(char(file(multi,:)));
        processed = feval(funname,signaldata);
        h = findobj('type','figure','-not','tag','aarae');
        if ~isempty(h)
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
            set(handles.result_box,'String',[' ';cellstr({results(3:length(results)).name}')]);
        end
    else
        processed = [];
    end
    if ~isempty(processed)
        % Generate new leaf and update tree
        newleaf = [name ' ' char(file(multi,:))];
        if ~isempty(signaldata)
            if isstruct(processed)
                dif = intersect(fieldnames(signaldata),fieldnames(processed));
                newdata = signaldata;
                for i = 1:size(dif,1)
                    newdata.(dif{i,1}) = processed.(dif{i,1});
                end
                newfields = setxor(fieldnames(signaldata),fieldnames(processed));
                for i = 1:size(newfields,1)
                    if ~isfield(newdata,newfields{i,1})
                        newdata.(newfields{i,1}) = processed.(newfields{i,1});
                    end
                end
            else
                newdata = signaldata;
                newdata.audio = processed;
            end
            newdata.datatype = 'processed';
            iconPath = fullfile(matlabroot,'/toolbox/fixedpoint/fixedpointtool/resources/plot.png');
            leafname = isfield(handles,genvarname(newleaf));
            if leafname == 1
                index = 1;
                % This while cycle is just to make sure no signals are
                % overwriten
                while isfield(handles,genvarname([newleaf,'_',num2str(index)])) == 1
                    index = index + 1;
                end
                newleaf = [newleaf,' ',num2str(index)];
            end
            handles.(genvarname(newleaf)) = uitreenode('v0', newleaf,  newleaf,  iconPath, true);
            handles.(genvarname(newleaf)).UserData = newdata;
            handles.processed.add(handles.(genvarname(newleaf)));
            handles.mytree.reloadNode(handles.processed);
            handles.mytree.expand(handles.processed);
            set([handles.clrall_btn,handles.export_btn],'Enable','on')
        end
        fprintf(handles.fid, [' ' datestr(now,16) ' - Processed "' name '" using ' funname ' in ' handles.procat '\n']);
    else
        newleaf = [];
    end
end
set(hObject,'BackgroundColor',[0.94 0.94 0.94]);
set(hObject,'Enable','on');
if ~isempty(newleaf)
    handles.mytree.setSelectedNode(handles.(genvarname(newleaf)));
end
guidata(hObject,handles);


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



% --- Executes on button press in stop_btn.
function stop_btn_Callback(hObject, eventdata, handles)
% hObject    handle to stop_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if isplaying(handles.player)
    stop(handles.player);
end
guidata(hObject,handles);



function IN_nchannel_Callback(hObject, eventdata, handles)
% hObject    handle to IN_nchannel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of IN_nchannel as text
%        str2double(get(hObject,'String')) returns contents of IN_nchannel as a double
hMain = getappdata(0,'hMain');
signaldata = getappdata(hMain,'testsignal'); % Get leaf contents from the 'desktop'
channel = str2double(get(handles.IN_nchannel,'String'));

if (channel <= size(signaldata.audio,2)) && (channel > 0) && ~isnan(channel)
    refreshplots(handles,'time')
    refreshplots(handles,'freq')
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
guidata(hObject,handles);


% --- Executes on mouse press over figure background, over a disabled or
% --- inactive control, or over an axes background.
function aarae_WindowButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to aarae (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
click = get(hObject,'CurrentObject');
if (click == handles.axestime) || (get(click,'Parent') == handles.axestime)
    hMain = getappdata(0,'hMain');
    signaldata = getappdata(hMain,'testsignal');
    if ~isempty(signaldata)
        if handles.alternate == 1 && isfield(signaldata,'audio2')
            data = signaldata.audio2;
        else
            data = signaldata.audio;
        end
        t = linspace(0,length(data),length(data))./signaldata.fs;
        f = signaldata.fs .* ((1:length(data))-1) ./ length(data);
        if ndims(data) > 2
            channel = str2double(get(handles.IN_nchannel,'String'));
            line(:,:) = data(:,channel,:);
            cmap = colormap(hsv(size(signaldata.audio,3)));
        else
            line = data;
            cmap = colormap(lines(size(signaldata.audio,2)));
        end
        h = figure;
        set(h,'DefaultAxesColorOrder',cmap);
        plottype = get(handles.time_popup,'Value');
        if plottype == 2, line = 10.*log10(line.^2); end
        if plottype == 3, line = abs(hilbert(line)); end
        if plottype == 2, line = line.^2; end
        if plottype == 3, line = 10.*log10(line.^2); end
        if plottype == 4, line = abs(hilbert(line)); end
        if plottype == 5, line = medfilt1(diff([angle(hilbert(line)); zeros(1,size(line,2))])*signaldata.fs/2/pi, 5); end
        if plottype == 6, line = real(line); end
        if plottype == 7, line = imag(line); end
        if plottype == 8, line = 10*log10(abs(fft(line)).^2); end %freq
        if plottype == 9, line = abs(fft(line)).^2; end
        if plottype == 10, line = abs(fft(line)); end
        if plottype == 11, line = real(fft(line)); end
        if plottype == 12, line = imag(fft(line)); end
        if plottype == 13, line = angle(fft(line)); end
        if plottype == 14, line = unwrap(angle(fft(line))); end
        if plottype == 15, line = angle(fft(line)) .* 180/pi; end
        if plottype == 16, line = unwrap(fft(line)) ./(2*pi); end
        if plottype <= 7
            plot(t,line) % Plot signal in time domain
            xlabel('Time [s]');
        end
        if plottype >= 8
            if plottype == 8
                smoothfactor = get(handles.smoothtime_popup,'Value');
                if smoothfactor == 2, octsmooth = 1; end
                if smoothfactor == 3, octsmooth = 3; end
                if smoothfactor == 4, octsmooth = 6; end
                if smoothfactor == 5, octsmooth = 12; end
                if smoothfactor == 6, octsmooth = 24; end
                if smoothfactor ~= 1, line = octavesmoothing(line, octsmooth, signaldata.fs); end
            end
            log_check = get(handles.logtime_chk,'Value');
            if log_check == 1
                semilogx(f,line) % Plot signal in frequency domain
            else
                plot(f,line)
            end
            xlabel('Frequency [Hz]');
            xlim([f(2) signaldata.fs/2])
        end
        handles.alternate = 0;
    end
end
if (click == handles.axesfreq) || (get(click,'Parent') == handles.axesfreq)
    hMain = getappdata(0,'hMain');
    signaldata = getappdata(hMain,'testsignal');
    if ~isempty(signaldata)
        if handles.alternate == 1 && isfield(signaldata,'audio2')
            data = signaldata.audio2;
        else
            data = signaldata.audio;
        end
        t = linspace(0,length(data),length(data))./signaldata.fs;
        f = signaldata.fs .* ((1:length(data))-1) ./ length(data);
        if ndims(data) > 2
            channel = str2double(get(handles.IN_nchannel,'String'));
            line(:,:) = data(:,channel,:);
            cmap = colormap(hsv(size(signaldata.audio,3)));
        else
            line = data;
            cmap = colormap(lines(size(signaldata.audio,2)));
        end

        h = figure;
        set(h,'DefaultAxesColorOrder',cmap);
        plottype = get(handles.freq_popup,'Value');
        if plottype == 2, line = 10.*log10(line.^2); end
        if plottype == 3, line = abs(hilbert(line)); end
        if plottype == 2, line = line.^2; end
        if plottype == 3, line = 10.*log10(line.^2); end
        if plottype == 4, line = abs(hilbert(line)); end
        if plottype == 5, line = medfilt1(diff([angle(hilbert(line)); zeros(1,size(line,2))])*signaldata.fs/2/pi, 5); end
        if plottype == 6, line = real(line); end
        if plottype == 7, line = imag(line); end
        if plottype == 8, line = 10*log10(abs(fft(line)).^2); end %freq
        if plottype == 9, line = abs(fft(line)).^2; end
        if plottype == 10, line = abs(fft(line)); end
        if plottype == 11, line = real(fft(line)); end
        if plottype == 12, line = imag(fft(line)); end
        if plottype == 13, line = angle(fft(line)); end
        if plottype == 14, line = unwrap(angle(fft(line))); end
        if plottype == 15, line = angle(fft(line)) .* 180/pi; end
        if plottype == 16, line = unwrap(fft(line)) ./(2*pi); end
    if plottype <= 7
        plot(t,line) % Plot signal in time domain
        xlabel('Time [s]');
    end
    if plottype >= 8
        if plottype == 8
            smoothfactor = get(handles.smoothfreq_popup,'Value');
            if smoothfactor == 2, octsmooth = 1; end
            if smoothfactor == 3, octsmooth = 3; end
            if smoothfactor == 4, octsmooth = 6; end
            if smoothfactor == 5, octsmooth = 12; end
            if smoothfactor == 6, octsmooth = 24; end
            if smoothfactor ~= 1, line = octavesmoothing(line, octsmooth, signaldata.fs); end
        end
        log_check = get(handles.logfreq_chk,'Value');
        if log_check == 1
            semilogx(f,line) % Plot signal in frequency domain
        else
            plot(f,line)
        end
        xlabel('Frequency [Hz]');
        xlim([f(2) signaldata.fs/2])
    end
        handles.alternate = 0;
    end
end
guidata(hObject,handles)


% --- Executes on button press in cal_btn.
function cal_btn_Callback(hObject, eventdata, handles)
% hObject    handle to cal_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hMain = getappdata(0,'hMain');
signaldata = getappdata(hMain,'testsignal');
selectedNodes = handles.mytree.getSelectedNodes;
selectedNodes = selectedNodes(1);

method = menu('Calibration',...
              'Choose from AARAE',...
              'Locate file on disc',...
              'Input value',...
              'Cancel');
switch method
    case 1
        root = handles.root; % Get selected leaf
        root = root(1);
        first = root.getFirstChild;
        branches{1,:} = char(first.getValue);
        next = first.getNextSibling;
        for n = 1:root.getChildCount-1
            branches{n+1,:} = char(next.getValue);
            next = next.getNextSibling;
        end
        branches = char(branches);
        
        i = 0;
        for n = 1:size(branches,1)
            currentbranch = handles.(genvarname(branches(n,:)));
            if currentbranch.getChildCount ~= 0
                i = i + 1;
                first = currentbranch.getFirstChild;
                leafnames(i,:) = first.getName;
                leaves{i,:} = char(first.getValue);
                next = first.getNextSibling;
                if ~isempty(next)
                    for m = 1:currentbranch.getChildCount-1
                        i = i + 1;
                        leafnames(i,:) = next.getName;
                        leaves{i,:} = char(next.getValue);
                        next = next.getNextSibling;
                    end
                end
            end
        end
        leafnames = char(leafnames);
        [s,ok] = listdlg('PromptString','Select a file:',...
                'SelectionMode','single',...
                'ListString',leafnames);
        leaves = char(leaves);
        if ok == 1
            caldata = handles.(genvarname(leaves(s,:))).handle.UserData;
            if ~isfield(caldata,'audio')
                warndlg('Incompatible calibration file','Warning!');
            else
                cal_level = 10 .* log10(mean(caldata.audio.^2,1));
                %calibration = 1./(10.^((cal_level)./20));
                %signaldata.audio = signaldata.audio.*calibration;
                if (size(signaldata.audio,2) == size(cal_level,2) || size(cal_level,2) == 1) && ndims(caldata.audio) < 3
                    cal_offset = inputdlg('Calibration tone RMS level',...
                                'Calibration value',[1 50],{'0'});
                    cal_level = str2num(char(cal_offset)) - cal_level;
                    if size(cal_level,2) == 1, cal_level = repmat(cal_level,1,size(signaldata.audio,2)); end
                    signaldata.cal = cal_level;
                    selectedNodes.handle.UserData = signaldata;
                    selectedParent = selectedNodes.getParent;
                    handles.mytree.reloadNode(selectedParent);
                    handles.mytree.setSelectedNode(selectedNodes);
                    fprintf(handles.fid, [' ' datestr(now,16) ' - Calibrated "' char(selectedNodes.getName) '": adjusted to ' num2str(cal_level) 'dB using ' leafnames(s,:) '\n']);
                else
                    warndlg('Incompatible calibration file','Warning!');
                end
            end
        else
            warndlg('No signal loaded!','Whoops...!');
        end
    case 2
        [filename,pathname,filterindex] = uigetfile(...
                    {'*.wav;*.mat','Calibration file (*.wav,*.mat)'});
        if filename ~= 0
            % Check type of file. First 'if' is for .mat, second is for .wav
            if ~isempty(regexp(filename, '.mat', 'once'))
                file = importdata(fullfile(pathname,filename));
                if isstruct(file)
                    caltone = file.audio;
                else
                    caltone = file;
                end
            elseif ~isempty(regexp(filename, '.wav', 'once'))
                caltone = wavread(fullfile(pathname,filename));
            else
                caltone = [];
            end
            if size(caltone,1) < size(caltone,2), caltone = caltone'; end
            cal_level = 10 * log10(mean(caltone.^2,1));
            if (size(signaldata.audio,2) == size(cal_level,2) || size(cal_level,2) == 1) && ndims(caltone) < 3
                cal_offset = inputdlg('Calibration tone RMS level',...
                            'Calibration value',[1 50],{'0'});
                cal_level = str2num(char(cal_offset)) - cal_level;
                if size(cal_level,2) == 1, cal_level = repmat(cal_level,1,size(signaldata.audio,2)); end
                signaldata.cal = cal_level;
                selectedNodes.handle.UserData = signaldata;
                selectedParent = selectedNodes.getParent;
                handles.mytree.reloadNode(selectedParent);
                handles.mytree.setSelectedNode(selectedNodes);
                fprintf(handles.fid, [' ' datestr(now,16) ' - Calibrated "' char(selectedNodes.getName) '": adjusted to ' num2str(cal_level) 'dB\n']);
            else
                warndlg('Incompatible calibration file','Warning!');
            end
        end
    case 3
        chans = size(signaldata.audio,2);
        if isfield(signaldata,'cal')
            def = cellstr(num2str(signaldata.cal'));
        else
            def = cellstr(num2str(zeros(chans,1)));
        end
        cal_level = inputdlg(cellstr([repmat('channel ',chans,1) num2str((1:chans)')]),...
                    'Calibration value',[1 60],def);
        cal_level = str2num(char(cal_level))';
        if chans == size(cal_level,2)
                signaldata.cal = cal_level;
                selectedNodes.handle.UserData = signaldata;
                selectedParent = selectedNodes.getParent;
                handles.mytree.reloadNode(selectedParent);
                handles.mytree.setSelectedNode(selectedNodes);
                fprintf(handles.fid, [' ' datestr(now,16) ' - Calibrated "' char(selectedNodes.getName) '": adjusted to ' num2str(cal_level) 'dB\n']);
        else
            warndlg('Incompatible calibration','Warning!');
        end
    case 4
        warndlg('Calibration canceled!','AARAE info')
end
guidata(hObject,handles)


% --- Executes on button press in calc_btn.
function calc_btn_Callback(hObject, eventdata, handles)
% hObject    handle to calc_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Call the window that displays calculators
calculator('main_stage1', handles.aarae);

% Handles update is done inside calculator.m


% --- Executes on key press with focus on aarae or any of its controls.
function aarae_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to aarae (see GCBO)
% eventdata  structure with the following fields (see FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)

if strcmp(eventdata.Modifier,'shift')
    handles.alternate = 1;
else
    handles.alternate = 0;
end
guidata(hObject,handles)


% --- Executes on selection change in result_box.
function result_box_Callback(hObject, eventdata, handles)
% hObject    handle to result_box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns result_box contents as cell array
%        contents{get(hObject,'Value')} returns selected item from result_box
get(handles.aarae,'SelectionType');
if strcmp(get(handles.aarae,'SelectionType'),'open')
    contents = cellstr(get(hObject,'String'));
    file = contents{get(hObject,'Value')};
    [~,~,ext] = fileparts(file);
    if ~strcmp(file,' ')
        switch ext
            case '.fig'
                openfig(file);
            otherwise
                open(file)
        end
    end
end

% --- Executes during object creation, after setting all properties.
function result_box_CreateFcn(hObject, eventdata, handles)
% hObject    handle to result_box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in freq_popup.
function freq_popup_Callback(hObject, eventdata, handles)
% hObject    handle to freq_popup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns freq_popup contents as cell array
%        contents{get(hObject,'Value')} returns selected item from freq_popup
refreshplots(handles,'freq')
guidata(hObject,handles)

% --- Executes during object creation, after setting all properties.
function freq_popup_CreateFcn(hObject, eventdata, handles)
% hObject    handle to freq_popup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in time_popup.
function time_popup_Callback(hObject, eventdata, handles)
% hObject    handle to time_popup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns time_popup contents as cell array
%        contents{get(hObject,'Value')} returns selected item from time_popup
refreshplots(handles,'time')
guidata(hObject,handles)

% --- Executes during object creation, after setting all properties.
function time_popup_CreateFcn(hObject, eventdata, handles)
% hObject    handle to time_popup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in playreverse_btn.
function playreverse_btn_Callback(hObject, eventdata, handles)
% hObject    handle to playreverse_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

hMain = getappdata(0,'hMain');
audiodata = getappdata(hMain,'testsignal');

if isempty(audiodata)
    warndlg('No signal loaded!');
else
    % Retrieve information from the selected leaf
    testsignal = flipud(audiodata.audio)./max(max(max(abs(audiodata.audio))));
    fs = audiodata.fs;
    nbits = audiodata.nbits;
    doesSupport = audiodevinfo(0, handles.odeviceid, fs, nbits, size(testsignal,2));
    if doesSupport && ndims(testsignal) < 3
        % Play signal
        handles.player = audioplayer(testsignal,fs,nbits,handles.odeviceid);
        play(handles.player);
        set(handles.stop_btn,'Visible','on');
        selectedNodes = handles.mytree.getSelectedNodes;
        contents = cellstr(get(handles.device_popup,'String'));
        fprintf(handles.fid, [' ' datestr(now,16) ' - Played "' char(selectedNodes(1).getName) '" using ' contents{get(hObject,'Value')} '\n']);
    else
        warndlg('Device not supported for playback!');
    end
end
guidata(hObject, handles);


% --- Executes on button press in randphaseplay_btn.
function randphaseplay_btn_Callback(hObject, eventdata, handles)
% hObject    handle to randphaseplay_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hMain = getappdata(0,'hMain');
audiodata = getappdata(hMain,'testsignal');

if isempty(audiodata)
    warndlg('No signal loaded!');
else
    % Retrieve information from the selected leaf
    testsignal = audiodata.audio;
    len = length(testsignal);
    len = 2 * ceil(len/2);
    spectrum = fft(testsignal,len);
    magnitude = abs(spectrum);
    randphase = rand(len/2-1,1) .* 2 * pi;
    randphase = repmat([0; randphase; 0; flipud(-randphase)],1,size(testsignal,2));
    changed_spectrum = magnitude .* exp(1i * randphase);
    testsignal = ifft(changed_spectrum);
    fs = audiodata.fs;
    nbits = audiodata.nbits;
    doesSupport = audiodevinfo(0, handles.odeviceid, fs, nbits, size(testsignal,2));
    if doesSupport && ndims(testsignal) < 3
        % Play signal
        handles.player = audioplayer(testsignal,fs,nbits,handles.odeviceid);
        play(handles.player);
        set(handles.stop_btn,'Visible','on');
        selectedNodes = handles.mytree.getSelectedNodes;
        contents = cellstr(get(handles.device_popup,'String'));
        fprintf(handles.fid, [' ' datestr(now,16) ' - Played "' char(selectedNodes(1).getName) '" using ' contents{get(hObject,'Value')} '\n']);
    else
        warndlg('Device not supported for playback!');
    end
end
guidata(hObject, handles);


% --- Executes on button press in flatmagplay_btn.
function flatmagplay_btn_Callback(hObject, eventdata, handles)
% hObject    handle to flatmagplay_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hMain = getappdata(0,'hMain');
audiodata = getappdata(hMain,'testsignal');

if isempty(audiodata)
    warndlg('No signal loaded!');
else
    % Retrieve information from the selected leaf
    testsignal = audiodata.audio;
    len = length(testsignal);
    len = 2 .* ceil(len./2);
    spectrum = fft(testsignal,len);
    phase = angle(spectrum);
    rmsmag = mean(abs(spectrum).^2).^0.5; % root mean square magnitude

    % combine magnitude with phase
    changed_spectrum = ones(len,size(testsignal,2)).*repmat(rmsmag,size(testsignal,1),1) .* exp(1i .* phase);
    changed_spectrum(1) = 0; % make DC zero
    changed_spectrum(len/2+1) = 0; % make Nyquist zero
    testsignal = ifft(changed_spectrum);
    fs = audiodata.fs;
    nbits = audiodata.nbits;
    doesSupport = audiodevinfo(0, handles.odeviceid, fs, nbits, size(testsignal,2));
    if doesSupport && ndims(testsignal) < 3
        % Play signal
        handles.player = audioplayer(testsignal,fs,nbits,handles.odeviceid);
        play(handles.player);
        set(handles.stop_btn,'Visible','on');
        selectedNodes = handles.mytree.getSelectedNodes;
        contents = cellstr(get(handles.device_popup,'String'));
        fprintf(handles.fid, [' ' datestr(now,16) ' - Played "' char(selectedNodes(1).getName) '" using ' contents{get(hObject,'Value')} '\n']);
    else
        warndlg('Device not supported for playback!');
    end
end
guidata(hObject, handles);


% --- Executes on button press in convplay_btn.
function convplay_btn_Callback(hObject, eventdata, handles)
% hObject    handle to convplay_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hMain = getappdata(0,'hMain');
audiodata = getappdata(hMain,'testsignal');

if isempty(audiodata)
    warndlg('No signal loaded!');
else
    % Retrieve information from the selected leaf
    testsignal = audiodata.audio;
    fs = audiodata.fs;
    reference_audio = resample(handles.reference_audio.audio,fs,handles.reference_audio.fs);
    reference_audio = repmat(reference_audio,1,size(testsignal,2));
    len1 = length(testsignal);
    len2 = length(reference_audio);
    outputlength = len1 + len2 - 1;
    testsignal = ifft(fft(testsignal, outputlength) .* fft(reference_audio, outputlength));
    testsignal = testsignal./max(max(max(abs(testsignal))));
    nbits = audiodata.nbits;
    doesSupport = audiodevinfo(0, handles.odeviceid, fs, nbits, size(testsignal,2));
    if doesSupport && ndims(testsignal) < 3
        % Play signal
        handles.player = audioplayer(testsignal,fs,nbits,handles.odeviceid);
        play(handles.player);
        set(handles.stop_btn,'Visible','on');
        selectedNodes = handles.mytree.getSelectedNodes;
        contents = cellstr(get(handles.device_popup,'String'));
        fprintf(handles.fid, [' ' datestr(now,16) ' - Played "' char(selectedNodes(1).getName) '" using ' contents{get(hObject,'Value')} '\n']);
    else
        warndlg('Device not supported for playback!');
    end
end
guidata(hObject, handles);


% --- Executes on button press in clrall_btn.
function clrall_btn_Callback(hObject, eventdata, handles)
% hObject    handle to clrall_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
root = handles.root; % Get selected leaf
root = root(1);
first = root.getFirstChild;
branches{1,:} = char(first.getValue);
next = first.getNextSibling;
for n = 1:root.getChildCount-1
    branches{n+1,:} = char(next.getValue);
    next = next.getNextSibling;
end
branches = char(branches);

i = 0;
for n = 1:size(branches,1)
    currentbranch = handles.(genvarname(branches(n,:)));
    if currentbranch.getChildCount ~= 0
        i = i + 1;
        first = currentbranch.getFirstChild;
        leafnames(i,:) = first.getName;
        leaves{i,:} = char(first.getValue);
        next = first.getNextSibling;
        if ~isempty(next)
            for m = 1:currentbranch.getChildCount-1
                i = i + 1;
                leafnames(i,:) = next.getName;
                leaves{i,:} = char(next.getValue);
                next = next.getNextSibling;
            end
        end
    end
end
if ~exist('leafnames')
    warndlg('Nothing to delete!','AARAE info');
else
    leafnames = char(leafnames);
    leaves = char(leaves);
    delete = questdlg('Current workspace will be cleared, would you like to proceed?',...
        'Warning',...
        'Yes','No','Yes');
    switch delete
        case 'Yes'
        set(hObject,'BackgroundColor','red');
        set(hObject,'Enable','off');
        for i = 1:size(leafnames,1)
            current = handles.(genvarname(leaves(i,:)));
            handles.mytree.remove(current);
            handles = rmfield(handles,genvarname(leaves(i,:)));
        end
        handles.mytree.reloadNode(handles.root);
        handles.mytree.setSelectedNode(handles.root);
        rmpath([cd '/Utilities/Temp']);
        rmdir([cd '/Utilities/Temp'],'s');
        mkdir([cd '/Utilities/Temp']);
        addpath([cd '/Utilities/Temp']);
        set(handles.result_box,'String',[]);
        fprintf(handles.fid, [' ' datestr(now,16) ' - Cleared workspace \n']);
        set(hObject,'BackgroundColor',[0.94 0.94 0.94]);
        set(hObject,'Enable','off');
        set(handles.export_btn,'Enable','off');
    end
end
guidata(hObject,handles)


% --- Executes on selection change in smoothfreq_popup.
function smoothfreq_popup_Callback(hObject, eventdata, handles)
% hObject    handle to smoothfreq_popup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns smoothfreq_popup contents as cell array
%        contents{get(hObject,'Value')} returns selected item from smoothfreq_popup
refreshplots(handles,'freq')
guidata(hObject,handles)

% --- Executes during object creation, after setting all properties.
function smoothfreq_popup_CreateFcn(hObject, eventdata, handles)
% hObject    handle to smoothfreq_popup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in smoothtime_popup.
function smoothtime_popup_Callback(hObject, eventdata, handles)
% hObject    handle to smoothtime_popup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns smoothtime_popup contents as cell array
%        contents{get(hObject,'Value')} returns selected item from smoothtime_popup
refreshplots(handles,'time')
guidata(hObject,handles)

% --- Executes during object creation, after setting all properties.
function smoothtime_popup_CreateFcn(hObject, eventdata, handles)
% hObject    handle to smoothtime_popup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in logfreq_chk.
function logfreq_chk_Callback(hObject, eventdata, handles)
% hObject    handle to logfreq_chk (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of logfreq_chk
refreshplots(handles,'freq')
guidata(hObject,handles)

% --- Executes on button press in logtime_chk.
function logtime_chk_Callback(hObject, eventdata, handles)
% hObject    handle to logtime_chk (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of logtime_chk
refreshplots(handles,'time')
guidata(hObject,handles)