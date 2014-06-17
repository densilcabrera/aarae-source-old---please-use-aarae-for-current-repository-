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

% Last Modified by GUIDE v2.5 13-Jun-2014 19:03:39

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
function aarae_OpeningFcn(hObject, ~, handles, varargin)
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
setappdata(hMain,'audio_recorder_input',1)
setappdata(hMain,'audio_recorder_output',1)
setappdata(hMain,'audio_recorder_numchs',1)
setappdata(hMain,'audio_recorder_duration',1)
setappdata(hMain,'audio_recorder_fs',48000)
%setappdata(hMain,'audio_recorder_nbits',16)
setappdata(hMain,'audio_recorder_qdur',1)
setappdata(hMain,'audio_recorder_buffer',1024)

% Read preferences file
Preferences = [];
if ~isempty(dir([cd '/Preferences.mat']))
    load([cd '/Preferences.mat']);
    handles.Preferences = Preferences;
else
    Preferences.maxtimetodisplay = 10;
    Preferences.frequencylimits = 'Default';
    Preferences.calibrationtoggle = 1;
    handles.Preferences = Preferences;
    save([cd '/Preferences.mat'],'Preferences')
end

if ~isdir([cd '/Log']), mkdir([cd '/Log']); end
if ~isdir([cd '/Utilities/Temp']), mkdir([cd '/Utilities/Temp']); end
% Add folder paths for filter functions and signal analyzers
addpath(genpath(cd));
handles.player = audioplayer(0,48000);
[handles.reference_audio.audio, handles.reference_audio.fs] = audioread('REFERENCE_AUDIO.wav');

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

[handles.mytree,container] = uitree('v0','Root', handles.root,'SelectionChangeFcn',@mySelectFcn);
set(container, 'Parent', hObject);
treeheight_char = get(handles.process_panel,'Position')+get(handles.analysis_panel,'Position')+get(handles.uipanel1,'Position');
treewidth_char = get(handles.analysis_panel,'Position');
set(handles.analysis_panel,'Units','pixels');
treewidth_pix = get(handles.analysis_panel,'Position');
factor = treewidth_pix./treewidth_char;
set(handles.mytree,'Position',[0,treewidth_char(1,2)*factor(1,2),treewidth_char(1,1)*factor(1,1),treeheight_char(1,4)*factor(1,4)]);
handles.mytree.expand(handles.root);
handles.mytree.setSelectedNode(handles.root);
handles.mytree.setMultipleSelectionEnabled(true);

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
handles.defaultaudiopath = [cd '/Audio'];
guidata(hObject, handles);

if ismac
    fontsize
end
% Set waiting flag in appdata
setappdata(handles.aarae,'waiting',1)
% UIWAIT makes aarae wait for user response (see UIRESUME)
uiwait(handles.aarae);


% --- Outputs from this function are returned to the command line.
function varargout = aarae_OutputFcn(~, ~, handles) 
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
function genaudio_btn_Callback(hObject, ~, handles)
% hObject    handle to genaudio_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Call the 'desktop'
hMain = getappdata(0,'hMain');
setappdata(hMain,'testsignal',[]);

% Call the window that allows signal generation 
newleaf = genaudio('main_stage1', handles.aarae);
%set(handles.aarae,'CurrentObject',[])
% Update the tree with the generated signal
handles.mytree.setSelectedNode(handles.root);
if ~isempty(getappdata(hMain,'testsignal'))
    signaldata = getappdata(hMain,'testsignal');
    if isfield(signaldata,'tag'), signaldata = rmfield(signaldata,'tag'); end
    signaldata.datatype = 'testsignals';
    if isfield(signaldata,'audio')
        %signaldata.nbits = 16;
        iconPath = fullfile(matlabroot,'/toolbox/fixedpoint/fixedpointtool/resources/plot.png');
    else
        iconPath = fullfile(matlabroot,'/toolbox/matlab/icons/notesicon.gif');
    end
    leafname = isfield(handles,genvarname(newleaf));
    if leafname == 1
        index = 1;
        % This while cycle is just to make sure no signals are
        % overwriten
        if length(genvarname([newleaf,'_',num2str(index)])) >= namelengthmax, newleaf = newleaf(1:round(end/2)); end
        while isfield(handles,genvarname([newleaf,'_',num2str(index)])) == 1
            index = index + 1;
        end
        newleaf = [newleaf,'_',num2str(index)];
    end
%    if length(signaldata.audio) > 1e6
%        audiodata = signaldata.audio;
%        fileID = fopen([cd '/Utilities/Temp/' newleaf '.dat'],'w');
%        fwrite(fileID,audiodata,'double');
%        fclose(fileID);
%        m = memmapfile([cd '/Utilities/Temp/' newleaf '.dat'],'Format','double');
%        signaldata.audio = m;
%    end
    handles.(genvarname(newleaf)) = uitreenode('v0', newleaf,  newleaf,  iconPath, true);
    handles.(genvarname(newleaf)).UserData = signaldata;
    handles.testsignals.add(handles.(genvarname(newleaf)));
    handles.mytree.reloadNode(handles.testsignals);
    handles.mytree.expand(handles.testsignals);
    handles.mytree.setSelectedNode(handles.(genvarname(newleaf)));
    set([handles.clrall_btn,handles.export_btn],'Enable','on')
    fprintf(handles.fid, [' ' datestr(now,16) ' - Generated ' newleaf ': duration = ' num2str(length(signaldata.audio)/signaldata.fs) 's ; fs = ' num2str(signaldata.fs) 'Hz \n']);
end
guidata(hObject, handles);


% --- Executes when user attempts to close aarae.
function aarae_CloseRequestFcn(hObject,eventdata,handles) %#ok
% hObject    handle to aarae (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if strcmp(get(handles.export_btn,'Enable'),'on')
    choice = questdlg('Are you sure to want to finish this AARAE session? Unexported data will be lost.',...
                      'Exit AARAE',...
                      'Yes','No','Export all & exit','Yes');
    switch choice
        case 'Yes'
            if getappdata(handles.aarae,'waiting')
                % The GUI is still in UIWAIT, so call UIRESUME and return
                uiresume(hObject);
                setappdata(handles.aarae,'waiting',0);
            else
                % The GUI is no longer waiting, so destroy it now.
                delete(hObject);
            end
         %   uiresume(handles.aarae);
        case 'Export all & exit'
            export_btn_Callback(handles.export_btn,eventdata,handles)
            if getappdata(handles.aarae,'waiting')
                % The GUI is still in UIWAIT, so call UIRESUME and return
                uiresume(hObject);
                setappdata(handles.aarae,'waiting',0);
            else
                % The GUI is no longer waiting, so destroy it now.
                delete(hObject);
            end
            %uiresume(handles.aarae);
    end
else
    uiresume(handles.aarae);
end
% Check appdata flag to see if the main GUI is in a wait state
%if getappdata(handles.aarae,'waiting')
    % The GUI is still in UIWAIT, so call UIRESUME and return
%    uiresume(hObject);
%    setappdata(handles.aarae,'waiting',0);
%else
%    % The GUI is no longer waiting, so destroy it now.
%    delete(hObject);
%end


% --- Executes on button press in save_btn.
function save_btn_Callback(hObject, ~, handles)
% hObject    handle to save_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Call the 'desktop'
%hMain = getappdata(0,'hMain');
%audiodata = getappdata(hMain,'testsignal');
selectedNodes = handles.mytree.getSelectedNodes;
for nleafs = 1:length(selectedNodes)
    audiodata = selectedNodes(nleafs).handle.UserData;
    if ~isempty(audiodata) %Check if there's data to save
        name = inputdlg('File name: (Please specify .wav for wave files)','Save as MATLAB File',1,{[char(selectedNodes(nleafs).getName) '.mat']}); %Request file name
        if ~isempty(name)
            %name = name{1,1};
            [~,name{1,1},ext]=fileparts(name{1,1});
            if strcmp(ext,'.mat'), ensave = 1;
            elseif strcmp(ext,'.wav') && ismatrix(audiodata.audio), ensave = 1;
            elseif strcmp(ext,'.wav') && ~ismatrix(audiodata.audio), ensave = 1; ext = '.mat';
            elseif isempty(ext), ensave = 1; 
            else ensave = 0;
            end
        else
            return
        end
        if isempty(name{1,1}) || ensave == 0
            warndlg('No data saved','AARAE info');
            return
        else
            if isempty(ext), ext = '.mat'; end
            if strcmp(ext,'.wav') && (~isfield(audiodata,'audio') || ~isfield(audiodata,'fs')), ext = '.mat'; end
            folder_name = uigetdir(handles.defaultaudiopath,'Save AARAE file');
            handles.defaultaudiopath = folder_name;
            listing = dir([folder_name '/' name{1,1} ext]);
            if isempty(listing)
                if strcmp(ext,'.mat'), save([folder_name '/' name{1,1} ext],'audiodata'); end
                if strcmp(ext,'.wav'), audiowrite([folder_name '/' name{1,1} ext],audiodata.audio,audiodata.fs); end
            else
                index = 1;
                % This while cycle is just to make sure no signals are
                % overwriten
                while isempty(dir([name{1,1},'_',num2str(index),ext])) == 0
                    index = index + 1;
                end
                name{1,1} = [name{1,1},'_',num2str(index),ext];
                if strcmp(ext,'.mat'), save([folder_name '/' name{1,1} ext],'audiodata'); end
                if strcmp(ext,'.wav'), audiowrite(audiodata.audio,audiodata.fs,[folder_name '/' name{1,1}]); end
            end
            %current = cd;
            fprintf(handles.fid, [' ' datestr(now,16) ' - Saved "' char(selectedNodes(nleafs).getName) '" to file "' name{1,1} ext '" in folder "%s"' '\n'],folder_name);
        end
    end
end
guidata(hObject, handles);


% --- Executes on button press in load_btn.
function load_btn_Callback(hObject, ~, handles)
% hObject    handle to load_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get path of the file to load
[filename,handles.defaultaudiopath,filterindex] = uigetfile(...
    {'*.wav;*.mat;.WAV;.MAT','Test Signals (*.wav,*.mat)';...
    '*.wav;*.mat;.WAV;.MAT','Measurement files (*.wav,*.mat)';...
    '*.wav;*.mat;.WAV;.MAT','Processed files (*.wav,*.mat)';...
    '*.wav;*.mat;.WAV;.MAT','Result files (*.wav,*.mat)'},...
    'Select audio file',handles.defaultaudiopath,...
    'MultiSelect','on');

if ~iscell(filename)
    if ischar(filename), filename = cellstr(filename);
    else return
    end
end
for i = 1:length(filename)
    if filename{i} ~= 0
        newleaf = cell(1,1);
        [~,newleaf{1,1},ext] = fileparts(filename{i});
        % Check type of file. First 'if' is for .mat, second is for .wav
        if strcmp(ext,'.mat') || strcmp(ext,'.MAT')
            file = importdata(fullfile(handles.defaultaudiopath,filename{i}));
            if isstruct(file)
                signaldata = file;
            else
                specs = inputdlg('Please specify the sampling frequency','Sampling frequency',1);
                if (isempty(specs))
                    warndlg('Input field is blank, cannot load data!','AARAE info');
                    signaldata = [];
                else
                    fs = str2double(specs{1,1});
                    %nbits = str2double(specs{2,1});
                    if isnan(fs) || fs<=0 % || isnan(nbits) || nbits<=0)
                        warndlg('Input MUST be a real positive number, cannot load data!','AARAE info');
                        signaldata = [];
                    else
                        signaldata = [];
                        signaldata.audio = file;
                        signaldata.fs = fs;
                        %signaldata.nbits = nbits;
                    end
                end
            end
        end
        if strcmp(ext,'.wav') || strcmp(ext,'.WAV')
            signaldata = [];
            [signaldata.audio,signaldata.fs] = audioread(fullfile(handles.defaultaudiopath,filename{i}));
            %signaldata.nbits = 16;
        end;

        % Generate new leaf and update the tree
        if ~isempty(signaldata)
            if ~isfield(signaldata,'chanID') && isfield(signaldata,'audio')
                signaldata.chanID = cellstr([repmat('Chan',size(signaldata.audio,2),1) num2str((1:size(signaldata.audio,2))')]);
            end
            if ~isfield(signaldata,'datatype') || (isfield(signaldata,'datatype') && strcmp(signaldata.datatype,'IR'))
                if filterindex == 1, signaldata.datatype = 'testsignals'; end;
                if filterindex == 2, signaldata.datatype = 'measurements'; end;
                if filterindex == 3, signaldata.datatype = 'processed'; end;
                if filterindex == 4, signaldata.datatype = 'results'; end;
            end
            if isfield(signaldata,'audio') && ~strcmp(signaldata.datatype,'syscal')
                iconPath = fullfile(matlabroot,'/toolbox/fixedpoint/fixedpointtool/resources/plot.png');
            elseif strcmp(signaldata.datatype,'syscal')
                iconPath = fullfile(matlabroot,'/toolbox/matlab/icons/boardicon.gif');
            else
                iconPath = fullfile(matlabroot,'/toolbox/matlab/icons/notesicon.gif');
            end
            leafname = isfield(handles,genvarname(newleaf{1,1}));
            if leafname == 1
                index = 1;
                % This while cycle is just to make sure no duplicate names
                if length(genvarname([newleaf{1,1},'_',num2str(index)])) >= namelengthmax, newleaf{1,1} = newleaf{1,1}(1:round(end/2)); end
                while isfield(handles,genvarname([newleaf{1,1},'_',num2str(index)])) == 1
                    index = index + 1;
                end
                newleaf{1,1} = [newleaf{1,1},'_',num2str(index)];
            end
            handles.(genvarname(newleaf{1,1})) = uitreenode('v0', newleaf{1,1},  newleaf{1,1},  iconPath, true);
            handles.(genvarname(newleaf{1,1})).UserData = signaldata;
            if strcmp(signaldata.datatype,'syscal'), signaldata.datatype = 'measurements'; end
            handles.(genvarname(signaldata.datatype)).add(handles.(genvarname(newleaf{1,1})));
            handles.mytree.reloadNode(handles.(genvarname(signaldata.datatype)));
            handles.mytree.expand(handles.(genvarname(signaldata.datatype)));
            %handles.mytree.setSelectedNode(handles.(genvarname(newleaf{1,1})));
            set([handles.clrall_btn,handles.export_btn],'Enable','on')
            fprintf(handles.fid, [' ' datestr(now,16) ' - Loaded "' filename{i} '" to branch "' char(handles.(genvarname(signaldata.datatype)).getName) '"\n']);
        end
        guidata(hObject, handles);
    end
end
handles.mytree.setSelectedNode(handles.(genvarname(newleaf{1,1})));


% --- Executes on button press in rec_btn.
function rec_btn_Callback(hObject, ~, handles)
% hObject    handle to rec_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Call the 'desktop'
hMain = getappdata(0,'hMain');

%set(handles.datatypetext,'String','No signal loaded');

% Call the audio recorder window
audiodata = audio_recorder('main_stage1', handles.aarae);

% Generate new leaf and update tree with the recording
handles.mytree.setSelectedNode(handles.root);
newleaf = getappdata(hMain,'signalname');
savenewsyscalstats = getappdata(hMain,'savenewsyscalstats');
if savenewsyscalstats == 1
    handles.syscalstats = getappdata(hMain,'syscalstats');
    handles.mytree.setSelectedNode(handles.root);
    iconPath = fullfile(matlabroot,'/toolbox/matlab/icons/boardicon.gif');
    handles.syscalstats.datatype = 'syscal';
    funname = ['System_calibration ' datestr(rem(now,1))];
    leafname = isfield(handles,genvarname(funname));
    if leafname == 1
        index = 1;
        % This while cycle is just to make sure no signals are
        % overwriten
        while isfield(handles,genvarname([funname,'_',num2str(index)])) == 1
            index = index + 1;
        end
        funname = [funname,'_',num2str(index)];
    end
    handles.(genvarname(funname)) = uitreenode('v0', funname,  funname,  iconPath, true);
    handles.(genvarname(funname)).UserData = handles.syscalstats;
    handles.measurements.add(handles.(genvarname(funname)));
    handles.mytree.reloadNode(handles.measurements);
    handles.mytree.expand(handles.measurements);
    handles.mytree.setSelectedNode(handles.(genvarname(funname)));
    set([handles.clrall_btn,handles.export_btn],'Enable','on')
    fprintf(handles.fid, [' ' datestr(now,16) ' - Saved system calibration data ' handles.funname '\n']);
end
if ~isempty(audiodata)
    audiodata.datatype = 'measurements';
    iconPath = fullfile(matlabroot,'/toolbox/fixedpoint/fixedpointtool/resources/plot.png');
    leafname = isfield(handles,genvarname(newleaf));
    if leafname == 1
        index = 1;
        % This while cycle is just to make sure no signals are
        % overwriten
        while isfield(handles,genvarname([newleaf,'_',num2str(index)])) == 1
            index = index + 1;
        end
        newleaf = [newleaf,'_',num2str(index)];
    end
    handles.(genvarname(newleaf)) = uitreenode('v0', newleaf,  newleaf,  iconPath, true);
    handles.(genvarname(newleaf)).UserData = audiodata;
    handles.measurements.add(handles.(genvarname(newleaf)));
    handles.mytree.reloadNode(handles.measurements);
    handles.mytree.expand(handles.measurements);
    handles.mytree.setSelectedNode(handles.(genvarname(newleaf)));
    set([handles.clrall_btn,handles.export_btn],'Enable','on')
    fprintf(handles.fid, [' ' datestr(now,16) ' - Recorded "' newleaf '": duration = ' num2str(length(audiodata.audio)/audiodata.fs) 's\n']);
end
guidata(hObject, handles);


% --- Executes on button press in edit_btn.
function edit_btn_Callback(~, ~, handles)
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
    [xi,xf] = edit_signal('main_stage1', handles.aarae);
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
function export_btn_Callback(hObject, ~, handles)
% hObject    handle to export_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

root = handles.root; % Get selected leaf
root = root(1);
first = root.getFirstChild;
nbranches = root.getChildCount;
branches = cell(nbranches,1);
branches{1,1} = char(first.getValue);
nleaves = 0;
nleaves = nleaves + handles.(genvarname(branches{1,1}))(1).getChildCount;
next = first.getNextSibling;
for n = 2:nbranches
    branches{n,1} = char(next.getValue);
    nleaves = nleaves + handles.(genvarname(branches{n,1}))(1).getChildCount;
    next = next.getNextSibling;
end
if nleaves == 0
    warndlg('Nothing to export!','AARAE info');
else
    leaves = cell(nleaves,1);
    i = 0;
    for n = 1:size(branches,1)
        currentbranch = handles.(genvarname(branches{n,1}));
        if currentbranch.getChildCount ~= 0
            i = i + 1;
            first = currentbranch.getFirstChild;
            %leafnames(i,:) = first.getName;
            leaves{i,1} = char(first.getValue);
            next = first.getNextSibling;
            if ~isempty(next)
                for m = 1:currentbranch.getChildCount-1
                    i = i + 1;
                    %leafnames(i,:) = next.getName;
                    leaves{i,1} = char(next.getValue);
                    next = next.getNextSibling;
                end
            end
        end
    end
    %leafnames = char(leafnames);
    %leaves = char(leaves);
    %folder = inputdlg('Folder name','Export all',[1 60],{'New Project'});
    if ~isdir([cd '/Projects']), mkdir([cd '/Projects']); end
	folder = uigetdir([cd '/Projects'],'Export all');
    if ischar(folder)
        set(hObject,'BackgroundColor','red');
        set(hObject,'Enable','off');
        %leafnames = cellstr(leafnames);
        for i = 1:size(leaves,1)
            current = handles.(genvarname(leaves{i,:}));
            current = current(1);
            data = current.handle.UserData; %#ok : used in save
            if ~exist([folder '/' leaves{i,:} '.mat'],'file')
                save([folder '/' leaves{i,:} '.mat'], 'data');
            else
                button = questdlg(['A file called ' leaves{i,:} '.mat is already in the destination folder, would you like to replace it?'],...
                                  'AARAE info','Yes','No','Append','Append');
                switch button
                    case 'Yes'
                        save([folder '/' leaves{i,:} '.mat'], 'data');
                    case 'Append'
                        index = 1;
                        % This while cycle is just to make sure no signals are
                        % overwriten
                        while exist([folder '/' leaves{i,:} '_' num2str(index) '.mat'],'file')
                            index = index + 1;
                        end
                        save([folder '/' leaves{i,:} '_' num2str(index) '.mat'], 'data');
                end
            end
        end
        if isdir([cd '/Utilities/Temp'])
            nfigs = dir([cd '/Utilities/Temp/*.fig']);
            copyfile([cd '/Utilities/Temp'],[folder '/figures']);
        end
        addpath(genpath([cd '/Projects']))
        fprintf(handles.fid, [' ' datestr(now,16) ' - Exported ' num2str(size(leaves,1)) ' data files and ' num2str(size(nfigs,1)) ' figures to "%s" \n'],folder);
        set(hObject,'BackgroundColor',[0.94 0.94 0.94]);
        set(hObject,'Enable','off');
    else
        addpath(genpath([cd '/Projects']))
    end
end
guidata(hObject,handles)

% --- Executes on button press in finish_btn.
function finish_btn_Callback(~, eventdata, handles) %#ok
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
function delete_btn_Callback(hObject, ~, handles)
% hObject    handle to delete_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Call the 'desktop'
hMain = getappdata(0,'hMain');
delete = questdlg('Current data will be lost, would you like to proceed?',...
    'Warning',...
    'Yes','No','Yes');
switch delete
    case 'Yes'
        % Deletes selected leaf from the tree
        setappdata(hMain,'testsignal',[]);
        selectedNodes = handles.mytree.getSelectedNodes;
        for nleafs = 1:length(selectedNodes)
            audiodata = selectedNodes(nleafs).handle.UserData;
            if strcmp(audiodata.datatype,'syscal')
                handles = rmfield(handles,'syscalstats');
                set(handles.signaltypetext,'String',[])
            end
            if ~isempty(audiodata)
                selectedParent = selectedNodes(nleafs).getParent;
                handles.mytree.remove(selectedNodes(nleafs));
                handles.mytree.reloadNode(selectedParent);
                handles.mytree.setSelectedNode(handles.root);
                handles = rmfield(handles,genvarname(char(selectedNodes(nleafs).getName)));
                fprintf(handles.fid, [' ' datestr(now,16) ' - Deleted "' char(selectedNodes(nleafs).getName) '" from branch "' char(selectedParent.getName) '"\n']);
            end
        end
        guidata(hObject, handles);
    case 'No'
        guidata(hObject, handles);
end


% --- Executes on button press in play_btn.
function play_btn_Callback(hObject, ~, handles) %#ok
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
    testsignal = real(audiodata.audio);
    if size(testsignal,3) > 1, testsignal = sum(testsignal,3); end
    if size(testsignal,2) > 2, testsignal = mean(testsignal,2); end
    testsignal = testsignal./max(max(abs(testsignal)));
    fs = audiodata.fs;
    nbits = 16;
    doesSupport = audiodevinfo(0, handles.odeviceid, fs, nbits, size(testsignal,2));
    if doesSupport && ismatrix(testsignal)
        % Play signal
        handles.player = audioplayer(testsignal,fs,nbits,handles.odeviceid);
        play(handles.player);
        selectedNodes = handles.mytree.getSelectedNodes;
        contents = cellstr(get(handles.device_popup,'String'));
        fprintf(handles.fid, [' ' datestr(now,16) ' - Played "' char(selectedNodes(1).getName) '" using ' contents{get(hObject,'Value')} '\n']);
    else
        warndlg('Device not supported for playback!');
    end
end
guidata(hObject, handles);


% --- Executes on button press in IR_btn.
function IR_btn_Callback(hObject, ~, handles) %#ok
% hObject    handle to IR_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hMain = getappdata(0,'hMain');
audiodata = getappdata(hMain,'testsignal');
S = audiodata.audio;
if ~isequal(size(audiodata.audio),size(audiodata.audio2))
    rmsize = size(audiodata.audio);
    if size(audiodata.audio,2) ~= size(audiodata.audio2,2)
        invS = repmat(audiodata.audio2,[1 rmsize(2:end)]);
    else
        invS = repmat(audiodata.audio2,[1 1 rmsize(3:end)]);
    end
else
    invS = audiodata.audio2;
end
fs = audiodata.fs;
%nbits = audiodata.nbits;
selectedNodes = handles.mytree.getSelectedNodes;

if isfield(audiodata,'properties') && isfield(audiodata.properties,'startflag')
    [method,ok] = listdlg('ListString',{'Synchronous average','Stack IRs in dimension 4','Convolve without separating'},...
                          'PromptString','Select the convolution method',...
                          'Name','AARAE options',...
                          'SelectionMode','single',...
                          'ListSize',[200 100]);
    if ok == 1
        startflag = audiodata.properties.startflag;
        len = startflag(2)-startflag(1);
        switch method
            case 1
                tempS = zeros(startflag(2)-1,size(S,2));
                for j = 1:size(S,2)
                    newS = zeros(startflag(2)-1,length(startflag));
                    for i = 1:length(startflag)
                        newS(:,i) = S(startflag(i):startflag(i)+len-1,j);
                    end
                    tempS(:,j) = mean(newS,2);
                end
                S = tempS;
            case 2
                %IR = [];%audiodata.audio;
                %ladjust = length(IR);
                IR = zeros(startflag(2)-1+length(invS),size(S,2),length(startflag),1);
                for j = 1:size(S,2)
                    newS = zeros(startflag(2)-1,length(startflag));
                    for i = 1:length(startflag)
                        newS(:,i,:) = S(startflag(i):startflag(i)+len-1,j,:);
                    end
                    newrmsize = size(newS);
                    newinvS = repmat(audiodata.audio2(:,j),[1 newrmsize(2:end)]);
                    newS_pad = [newS; zeros(size(newinvS))];
                    invS_pad = [newinvS; zeros(size(newS))];
                    convolve = convolvedemo(newS_pad, invS_pad, 2, fs);
                    convolve = convolve(1:round(end/2),:,:);
                    IR(:,j,:,:) = convolve;%zeros(ladjust-length(convolve),size(newS,2))]; % Calls convolvedemo.m
                end
                IR = permute(IR,[1,2,4,3]);
                if size(IR,2) == 1
                    button = questdlg('Dimension 2 is singleton, stack IRs in dimension 2?','AARAE info','Yes','No','Yes');
                    switch button
                        case 'Yes'
                            IR = permute(IR,[1,4,3,2]);
                    end
                end
                S = newS;
                invS = repmat(invS,1,size(S,2));
        end
    else
        return
    end
else
    method = 1;
end

if method == 1 || method == 3
    S_pad = [S; zeros(size(invS))];
    invS_pad = [invS; zeros(size(S))];
    IR = convolvedemo(S_pad, invS_pad, 2, fs); % Calls convolvedemo.m
    IR = IR(1:length(S_pad),:,:);
end
if method == 1
    if ~ismatrix(IR), tempIR(:,:) = IR(:,1,:); else tempIR = IR; end
    [trimsamp_low,trimsamp_high] = window_signal('main_stage1', handles.aarae,'IR',tempIR); % Calls the trimming GUI window to trim the IR
    %[~, id] = max(abs(IR));
    %trimsamp_low = id-round(IRlength./2);
    %trimsamp_high = trimsamp_low + IRlength -1;
    IR = IR(trimsamp_low:trimsamp_high,:,:);
    IRlength = length(IR);
else
    IRlength = length(IR);
end

% Create new leaf and update the tree
handles.mytree.setSelectedNode(handles.root);
newleaf = ['IR_' selectedNodes(1).getName.char];
leafname = isfield(handles,genvarname(newleaf));
if leafname == 1
    index = 1;
    % This while cycle is just to make sure no signals are
    % overwriten
    if length(genvarname([newleaf,'_',num2str(index)])) >= namelengthmax, newleaf = newleaf(1:round(end/2)); end
    while isfield(handles,genvarname([newleaf,'_',num2str(index)])) == 1
        index = index + 1;
    end
    newleaf = [newleaf,'_',num2str(index)];
end
if ~isempty(getappdata(hMain,'testsignal'))
    signaldata = audiodata;
    signaldata = rmfield(signaldata,'audio2');
    signaldata.audio = IR;
    signaldata.fs = fs;
    %signaldata.nbits = 16;
    signaldata.chanID = cellstr([repmat('Chan',size(signaldata.audio,2),1) num2str((1:size(signaldata.audio,2))')]);
    signaldata.datatype = 'measurements';
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

guidata(hObject, handles);


% --- Executes on selection change in funcat_box.
function funcat_box_Callback(hObject, ~, handles) %#ok
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
function funcat_box_CreateFcn(hObject, ~, handles) %#ok
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
function analyze_btn_Callback(hObject, ~, handles) %#ok
% hObject    handle to analyze_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Analyses the selected leaf using the function selected from fun_box
% Call the 'desktop'
% hMain = getappdata(0,'hMain');
% audiodata = getappdata(hMain,'testsignal');
selectedNodes = handles.mytree.getSelectedNodes;
funcallback = [];
for nleafs = 1:length(selectedNodes)
    handles.nleafs = nleafs;
    guidata(hObject,handles)
    audiodata = selectedNodes(nleafs).handle.UserData;
    % Evaluate selected function for the leaf selected from the tree
    if ~isempty(handles.funname) && ~isempty(audiodata)
        set(hObject,'BackgroundColor','red');
        set(hObject,'Enable','off');
        % Processes the selected leaf using the selected process from proc_box
        %contents = cellstr(get(handles.funcat_box,'String'));
        %category = contents{get(handles.funcat_box,'Value')};
        contents = cellstr(get(handles.fun_box,'String'));
        file = contents(get(handles.fun_box,'Value'));
        %name = selectedNodes(nleafs).getName.char;
        for multi = 1:size(file,1)
            [~,funname] = fileparts(char(file(multi,:)));
            if nargout(funname) == 1 || nargout(funname) == -2
                %out = feval(handles.funname,audiodata);
                if ~isempty(funcallback) && strcmp(funname,funcallback.name)
                    out = feval(funname,audiodata,funcallback.inarg{:});
                else
                    out = feval(funname,audiodata);
                end
                if isfield(out,'funcallback')
                    funcallback = out.funcallback;
                    [~,funcallback.name] = fileparts(funcallback.name);
                end
            else
                out = [];
                feval(funname,audiodata);
            end
            aarae_fig = findobj('Tag','aarae');
            handles = guidata(aarae_fig);
            newleaf = cell(1,1);
            newleaf{1,1} = [char(selectedNodes(nleafs).getName) ' ' funname];
            if ~isempty(out)
                signaldata = out;
                signaldata.datatype = 'results';
                if isfield(signaldata,'audio')
                    iconPath = fullfile(matlabroot,'/toolbox/fixedpoint/fixedpointtool/resources/plot.png');
                else
                    iconPath = fullfile(matlabroot,'/toolbox/matlab/icons/notesicon.gif');
                end
                leafname = isfield(handles,genvarname(newleaf{1,1}));
                if leafname == 1
                    index = 1;
                    % This while cycle is just to make sure no signals are
                    % overwriten
                    if length(genvarname([newleaf{1,1},'_',num2str(index)])) >= namelengthmax, newleaf{1,1} = newleaf{1,1}(1:round(end/2)); end
                    while isfield(handles,genvarname([newleaf{1,1},'_',num2str(index)])) == 1
                        index = index + 1;
                    end
                    newleaf{1,1} = [newleaf{1,1},'_',num2str(index)];
                end
                handles.(genvarname(newleaf{1,1})) = uitreenode('v0', newleaf{1,1},  newleaf{1,1},  iconPath, true);
                handles.(genvarname(newleaf{1,1})).UserData = signaldata;
                handles.results.add(handles.(genvarname(newleaf{1,1})));
                handles.mytree.reloadNode(handles.results);
                handles.mytree.expand(handles.results);
                %handles.mytree.setSelectedNode(handles.(genvarname(newleaf)));
                set([handles.clrall_btn,handles.export_btn],'Enable','on')
            end
            fprintf(handles.fid, [' ' datestr(now,16) ' - Analyzed "' char(selectedNodes(1).getName) '" using ' funname ' in ' handles.funcat '\n']);% In what category???
            
            h = findobj('type','figure','-not','tag','aarae');
            index = 1;
            filename = dir([cd '/Utilities/Temp/' char(selectedNodes(nleafs).getName) funname num2str(index) '.fig']);
            if ~isempty(filename)
                while isempty(dir([cd '/Utilities/Temp/' char(selectedNodes(nleafs).getName) funname num2str(index) '.fig'])) == 0
                    index = index + 1;
                end
            end
            for i = 1:length(h)
                saveas(h(i),[cd '/Utilities/Temp/' char(selectedNodes(nleafs).getName) funname num2str(index) '.fig']);
                index = index + 1;
            end
            results = dir([cd '/Utilities/Temp']);
            set(handles.result_box,'String',[' ';cellstr({results(3:length(results)).name}')]);
            if length(selectedNodes) > 1 || size(file,1) > 1, delete(h); end
        end
        set(hObject,'BackgroundColor',[0.94 0.94 0.94]);
        set(hObject,'Enable','on');
    end
end
%handles.mytree.setSelectedNode(handles.(genvarname(newleaf)));
guidata(hObject,handles)


% --- Executes on selection change in fun_box.
function fun_box_Callback(hObject, ~, handles) %#ok
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
function fun_box_CreateFcn(hObject, ~, ~) %#ok
% hObject    handle to fun_box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in procat_box.
function procat_box_Callback(hObject, ~, handles) %#ok
% hObject    handle to procat_box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns procat_box contents as cell array
%        contents{get(hObject,'Value')} returns selected item from procat_box

% Displays the processes available for the selected process category
%hMain = getappdata(0,'hMain');
%signaldata = getappdata(hMain,'testsignal');

contents = cellstr(get(hObject,'String'));
handles.procat = contents{get(hObject,'Value')};
processes = what([cd '/Processors/' handles.procat]);

if ~isempty(processes.m)
    set(handles.proc_box,'Visible','on','String',[' ';cellstr(processes.m)],'Value',1);
    set(handles.proc_btn,'Visible','off');
else
    set(handles.proc_box,'Visible','off');
    set(handles.proc_btn,'Visible','off');
end
guidata(hObject,handles);


% --- Executes during object creation, after setting all properties.
function procat_box_CreateFcn(hObject, ~, handles) %#ok
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
function proc_box_Callback(hObject, ~, handles) %#ok
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
function proc_box_CreateFcn(hObject, ~, ~) %#ok
% hObject    handle to proc_box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in proc_btn.
function proc_btn_Callback(hObject, ~, handles) %#ok
% hObject    handle to proc_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
selectedNodes = handles.mytree.getSelectedNodes;
funcallback = [];
for nleafs = 1:length(selectedNodes)
    signaldata = selectedNodes(nleafs).handle.UserData;
    if ~isempty(signaldata)
        set(hObject,'BackgroundColor','red');
        set(hObject,'Enable','off');
        % Processes the selected leaf using the selected process from proc_box
%        contents = cellstr(get(handles.procat_box,'String'));
%        category = contents{get(handles.procat_box,'Value')};
        contents = cellstr(get(handles.proc_box,'String'));
        file = contents(get(handles.proc_box,'Value'));
        name = selectedNodes(nleafs).getName.char;
        for multi = 1:size(file,1)
            processed = [];
            [~,~,ext] = fileparts(file{multi,1});
            if strcmp(ext,'.mat')
                warndlg('Option not yet available','AARAE info','modal')
%                content = load([cd '/Processors/' category '/' num2str(signaldata.fs) 'Hz/' char(file(multi,:))]);
%                filterbank = content.filterbank;
%                w = whos('filterbank');
%                if strcmp(w.class,'dfilt.df2sos')
%                    for i = 1:length(filterbank)
%                        for j = 1:min(size(signaldata.audio))
%                            processed(:,j,i) = filter(filterbank(1,i),signaldata.audio(:,j));
%                        end
%                    end
%                    bandID = [];
%                elseif strcmp(w.class,'double')    
%                    processed = filter(filterbank,1,signaldata.audio);
%                end
            elseif strcmp(ext,'.m')
                [~,funname] = fileparts(char(file(multi,:)));
                if ~isempty(funcallback) && strcmp(funname,funcallback.name)
                    processed = feval(funname,signaldata,funcallback.inarg{:});
                else
                    processed = feval(funname,signaldata);
                end
                if isfield(processed,'funcallback')
                    funcallback = processed.funcallback;
                    [~,funcallback.name] = fileparts(funcallback.name);
                end
            else
                processed = [];
            end
            if ~isempty(processed)
                % Generate new leaf and update tree
                newleaf = cell(1,1);
                newleaf{1,1} = [name ' ' char(file(multi,:))];
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
                    leafname = isfield(handles,genvarname(newleaf{1,1}));
                    if leafname == 1
                        index = 1;
                        % This while cycle is just to make sure no signals are
                        % overwriten
                        if length(genvarname([newleaf{1,1},'_',num2str(index)])) >= namelengthmax, newleaf{1,1} = newleaf{1,1}(1:round(end/2)); end
                        while isfield(handles,genvarname([newleaf{1,1},'_',num2str(index)])) == 1
                            index = index + 1;
                        end
                        newleaf{1,1} = [newleaf{1,1},'_',num2str(index)];
                    end
                    handles.(genvarname(newleaf{1,1})) = uitreenode('v0', newleaf{1,1},  newleaf{1,1},  iconPath, true);
                    handles.(genvarname(newleaf{1,1})).UserData = newdata;
                    handles.processed.add(handles.(genvarname(newleaf{1,1})));
                    handles.mytree.reloadNode(handles.processed);
                    handles.mytree.expand(handles.processed);
                    set([handles.clrall_btn,handles.export_btn],'Enable','on')
                end
                fprintf(handles.fid, [' ' datestr(now,16) ' - Processed "' name '" using ' funname ' in ' handles.procat '\n']);
            else
                newleaf{1,1} = [];
            end
        end
    end
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
    if length(selectedNodes) > 1 || size(file,1) > 1, delete(h); end
    set(hObject,'BackgroundColor',[0.94 0.94 0.94]);
    set(hObject,'Enable','on');
    if ~isempty(newleaf{1,1})
        handles.mytree.setSelectedNode(handles.(genvarname(newleaf{1,1})));
    end
end
guidata(hObject,handles);


% --- Executes on selection change in device_popup.
function device_popup_Callback(hObject, ~, handles) %#ok
% hObject    handle to device_popup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns device_popup contents as cell array
%        contents{get(hObject,'Value')} returns selected item from device_popup

selection = get(hObject,'Value');
handles.odeviceid = handles.odeviceidlist(selection);
guidata(hObject,handles);


% --- Executes during object creation, after setting all properties.
function device_popup_CreateFcn(hObject, ~, handles) %#ok
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
function stop_btn_Callback(hObject, ~, handles) %#ok
% hObject    handle to stop_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if isplaying(handles.player)
    stop(handles.player);
end
guidata(hObject,handles);



function IN_nchannel_Callback(hObject, ~, handles) %#ok
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
function IN_nchannel_CreateFcn(hObject, ~, handles) %#ok
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
function aarae_WindowButtonDownFcn(hObject, ~, handles) %#ok
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
        To = floor(str2double(get(handles.To_time,'String'))*signaldata.fs)+1;
        Tf = floor(str2double(get(handles.Tf_time,'String'))*signaldata.fs);
        if Tf > length(signaldata.audio), Tf = length(data); end
        if ~ismatrix(data)
            channel = str2double(get(handles.IN_nchannel,'String'));
            if handles.alternate == 0
                linea(:,:) = data(To:Tf,channel,:);
            else
                linea(:,:) = data(:,channel,:);
            end
            if ndims(data) == 3, cmap = colormap(hsv(size(data,3))); end
            if ndims(data) >= 4, cmap = colormap(copper(size(data,4))); end
        else
            linea = data(To:Tf,:);
            cmap = colormap(lines(size(data,2)));
        end
        if isfield(signaldata,'cal') && handles.Preferences.calibrationtoggle == 1
            if size(linea,2) == length(signaldata.cal)
                signaldata.cal(isnan(signaldata.cal)) = 0;
                linea = linea.*repmat(10.^(signaldata.cal./20),length(linea),1);
            elseif ~ismatrix(signaldata.audio) && size(signaldata.audio,2) == length(signaldata.cal)
                signaldata.cal(isnan(signaldata.cal)) = 0;
                cal = repmat(signaldata.cal(str2double(get(handles.IN_nchannel,'String'))),1,size(linea,2));
                linea = linea.*repmat(10.^(cal./20),length(linea),1);
            end
        end
        t = linspace(To,Tf,length(linea))./signaldata.fs;
        f = signaldata.fs .* ((1:length(linea))-1) ./ length(linea);
        h = figure;
        set(h,'DefaultAxesColorOrder',cmap);
        plottype = get(handles.time_popup,'Value');
        if plottype == 1, linea = real(linea); end
        if plottype == 2, linea = linea.^2; end
        if plottype == 3, linea = 10.*log10(linea.^2); end
        if plottype == 4, linea = abs(hilbert(real(linea))); end
        if plottype == 5, linea = medfilt1(diff([angle(hilbert(real(linea))); zeros(1,size(linea,2))])*signaldata.fs/2/pi, 5); end
        if plottype == 6, linea = abs(linea); end
        if plottype == 7, linea = imag(linea); end
        if plottype == 8, linea = 10*log10(abs(fft(linea).*2.^0.5/length(linea)).^2); end %freq
        if plottype == 9, linea = (abs(fft(linea)).*2.^0.5/length(linea)).^2; end
        if plottype == 10, linea = abs(fft(linea)).*2.^0.5/length(linea); end
        if plottype == 11, linea = real(fft(linea)).*2.^0.5/length(linea); end
        if plottype == 12, linea = imag(fft(linea)).*2.^0.5/length(linea); end
        if plottype == 13, linea = angle(fft(linea)); end
        if plottype == 14, linea = unwrap(angle(fft(linea))); end
        if plottype == 15, linea = angle(fft(linea)) .* 180/pi; end
        if plottype == 16, linea = unwrap(angle(fft(linea))) ./(2*pi); end
        if plottype == 17, linea = -diff(unwrap(angle(fft(linea)))).*length(fft(linea))/(signaldata.fs*2*pi).*1000; end
        if plottype <= 7
            plot(t,real(linea)) % Plot signal in time domain
            xlabel('Time [s]');
            yl = cellstr(get(handles.time_popup,'String'));
            yl = yl{get(handles.time_popup,'Value')};
            ylabel(yl(8:end));
        end
        if plottype >= 8
            if plottype == 8
                smoothfactor = get(handles.smoothtime_popup,'Value');
                if smoothfactor == 2, octsmooth = 1; end
                if smoothfactor == 3, octsmooth = 3; end
                if smoothfactor == 4, octsmooth = 6; end
                if smoothfactor == 5, octsmooth = 12; end
                if smoothfactor == 6, octsmooth = 24; end
                if smoothfactor ~= 1, linea = octavesmoothing(linea, octsmooth, signaldata.fs); end
            end
            %if plottype == 17, 
            plot(f(1:length(linea)),linea)%,'Marker','None'); end
            %if plottype ~= 17, semilogx(f,linea); end % Plot signal in frequency domain
            log_check = get(handles.logtime_chk,'Value');
            xlabel('Frequency [Hz]');
            yl = cellstr(get(handles.time_popup,'String'));
            yl = yl{get(handles.time_popup,'Value')};
            ylabel(yl(9:end));
            if ischar(handles.Preferences.frequencylimits)
                xlim([f(2) signaldata.fs/2])
            else
                xlim(handles.Preferences.frequencylimits)
            end
            if log_check == 1
                set(gca,'XScale','log')
                %set(gca,'XTickLabel',num2str(get(gca,'XTick').'))
            else
                set(gca,'XScale','linear')%,'XTickLabelMode','auto')
                %set(gca,'XTickLabel',num2str(get(gca,'XTick').'))
            end
        end
        if handles.alternate == 0
            if ~ismatrix(data)
                if isfield(signaldata,'bandID')
                    legend(num2str(signaldata.bandID'));
                end
            else
                if isfield(signaldata,'chanID')
                    legend(signaldata.chanID);
                end
            end
        end
        handles.alternate = 0;
    end
    selectedNodes = handles.mytree.getSelectedNodes;
    selectedNodes = selectedNodes(1);
    title(selectedNodes.getName.char)
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
        To = floor(str2double(get(handles.To_freq,'String'))*signaldata.fs)+1;
        Tf = floor(str2double(get(handles.Tf_freq,'String'))*signaldata.fs);
        if Tf > length(signaldata.audio), Tf = length(data); end
        if ~ismatrix(data)
            channel = str2double(get(handles.IN_nchannel,'String'));
            if handles.alternate == 0
                linea(:,:) = data(To:Tf,channel,:);
            else
                linea(:,:) = data(:,channel,:);
            end
            if ndims(data) == 3, cmap = colormap(hsv(size(data,3))); end
            if ndims(data) >= 4, cmap = colormap(copper(size(data,4))); end
        else
            linea = data(To:Tf,:);
            cmap = colormap(lines(size(data,2)));
        end
        if isfield(signaldata,'cal') && handles.Preferences.calibrationtoggle == 1
            if size(linea,2) == length(signaldata.cal)
                signaldata.cal(isnan(signaldata.cal)) = 0;
                linea = linea.*repmat(10.^(signaldata.cal./20),length(linea),1);
            elseif ~ismatrix(signaldata.audio) && size(signaldata.audio,2) == length(signaldata.cal)
                signaldata.cal(isnan(signaldata.cal)) = 0;
                cal = repmat(signaldata.cal(str2double(get(handles.IN_nchannel,'String'))),1,size(linea,2));
                linea = linea.*repmat(10.^(cal./20),length(linea),1);
            end
        end
        t = linspace(To,Tf,length(linea))./signaldata.fs;
        f = signaldata.fs .* ((1:length(linea))-1) ./ length(linea);
        h = figure;
        set(h,'DefaultAxesColorOrder',cmap);
        plottype = get(handles.freq_popup,'Value');
        if plottype == 1, linea = real(linea); end
        if plottype == 2, linea = linea.^2; end
        if plottype == 3, linea = 10.*log10(linea.^2); end
        if plottype == 4, linea = abs(hilbert(real(linea))); end
        if plottype == 5, linea = medfilt1(diff([angle(hilbert(real(linea))); zeros(1,size(linea,2))])*signaldata.fs/2/pi, 5); end
        if plottype == 6, linea = abs(linea); end
        if plottype == 7, linea = imag(linea); end
        if plottype == 8, linea = 10*log10(abs(fft(linea).*2.^0.5/length(linea)).^2); end
        if plottype == 9, linea = (abs(fft(linea)).*2.^0.5/length(linea)).^2; end
        if plottype == 10, linea = abs(fft(linea)).*2.^0.5/length(linea); end
        if plottype == 11, linea = real(fft(linea)).*2.^0.5/length(linea); end
        if plottype == 12, linea = imag(fft(linea)).*2.^0.5/length(linea); end
        if plottype == 13, linea = angle(fft(linea)); end
        if plottype == 14, linea = unwrap(angle(fft(linea))); end
        if plottype == 15, linea = angle(fft(linea)) .* 180/pi; end
        if plottype == 16, linea = unwrap(angle(fft(linea))) ./(2*pi); end
        if plottype == 17, linea = -diff(unwrap(angle(fft(linea)))).*length(fft(linea))/(signaldata.fs*2*pi).*1000; end
        if plottype <= 7
            plot(t,real(linea)) % Plot signal in time domain
            xlabel('Time [s]');
            yl = cellstr(get(handles.freq_popup,'String'));
            yl = yl{get(handles.freq_popup,'Value')};
            ylabel(yl(8:end));
        end
        if plottype >= 8
            if plottype == 8
                smoothfactor = get(handles.smoothfreq_popup,'Value');
                if smoothfactor == 2, octsmooth = 1; end
                if smoothfactor == 3, octsmooth = 3; end
                if smoothfactor == 4, octsmooth = 6; end
                if smoothfactor == 5, octsmooth = 12; end
                if smoothfactor == 6, octsmooth = 24; end
                if smoothfactor ~= 1, linea = octavesmoothing(linea, octsmooth, signaldata.fs); end
            end
            %if plottype == 17, 
            plot(f(1:length(linea)),linea)%,'Marker','None'); end
            %if plottype ~= 17, semilogx(f,linea); end % Plot signal in frequency domain
            xlabel('Frequency [Hz]');
            yl = cellstr(get(handles.freq_popup,'String'));
            yl = yl{get(handles.freq_popup,'Value')};
            ylabel(yl(9:end));
            if ischar(handles.Preferences.frequencylimits)
                xlim([f(2) signaldata.fs/2])
            else
                xlim(handles.Preferences.frequencylimits)
            end
            log_check = get(handles.logfreq_chk,'Value');
            if log_check == 1
                set(gca,'XScale','log')
                %set(gca,'XTickLabel',num2str(get(gca,'XTick').'))
            else
                set(gca,'XScale','linear')%,'XTickLabelMode','auto')
                %set(gca,'XTickLabel',num2str(get(gca,'XTick').'))
            end
        end
        if handles.alternate == 0
            if ~ismatrix(data)
                if isfield(signaldata,'bandID')
                    legend(num2str(signaldata.bandID'));
                end
            else
                if isfield(signaldata,'chanID')
                    legend(signaldata.chanID);
                end
            end
        end
        handles.alternate = 0;
    end
    selectedNodes = handles.mytree.getSelectedNodes;
    selectedNodes = selectedNodes(1);
    title(selectedNodes.getName.char)
end
guidata(hObject,handles)


% --- Executes on button press in cal_btn.
function cal_btn_Callback(hObject, ~, handles) %#ok
% hObject    handle to cal_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hMain = getappdata(0,'hMain');
signaldata = getappdata(hMain,'testsignal');
selectedNodes = handles.mytree.getSelectedNodes;
%selectedNodes = selectedNodes(1);

method = menu('Calibration',...
              'Choose from AARAE',...
              'Locate file on disc',...
              'Input value',...
              'Specify Leq',...
              'Specify weighted Leq',...
              'Cancel');
cal_level = [];
switch method
    case 1
        root = handles.root; % Get selected leaf
        root = root(1);
        first = root.getFirstChild;
        nbranches = root.getChildCount;
        branches = cell(nbranches,1);
        branches{1,1} = char(first.getValue);
        nleaves = 0;
        nleaves = nleaves + handles.(genvarname(branches{1,1}))(1).getChildCount;
        next = first.getNextSibling;
        for n = 2:nbranches
            branches{n,1} = char(next.getValue);
            nleaves = nleaves + handles.(genvarname(branches{n,1}))(1).getChildCount;
            next = next.getNextSibling;
        end
        leaves = cell(nleaves,1);
        i = 0;
        for n = 1:size(branches,1)
            currentbranch = handles.(genvarname(branches{n,1}));
            if currentbranch.getChildCount ~= 0
                i = i + 1;
                first = currentbranch.getFirstChild;
                %leafnames(i,:) = first.getName;
                leaves{i,:} = char(first.getValue);
                next = first.getNextSibling;
                if ~isempty(next)
                    for m = 1:currentbranch.getChildCount-1
                        i = i + 1;
                        %leafnames(i,:) = next.getName;
                        leaves{i,:} = char(next.getValue);
                        next = next.getNextSibling;
                    end
                end
            end
        end
        [s,ok] = listdlg('PromptString','Select a file:',...
                'SelectionMode','single',...
                'ListString',leaves);
        if ok == 1
            caldata = handles.(genvarname(leaves{s,1})).handle.UserData;
            if ~isfield(caldata,'audio')
                warndlg('Incompatible calibration file','Warning!');
            else
                cal_level = 10 .* log10(mean(caldata.audio.^2,1));
                %calibration = 1./(10.^((cal_level)./20));
                %signaldata.audio = signaldata.audio.*calibration;
                if (size(signaldata.audio,2) == size(cal_level,2) || size(cal_level,2) == 1) && ismatrix(caldata.audio)
                    cal_offset = inputdlg('Calibration tone RMS level',...
                                'Calibration value',[1 50],{'0'});
                    if isnan(str2double(char(cal_offset)))
                        return
                    else
                        cal_level = str2double(char(cal_offset)) - cal_level;
                    end
                    if size(cal_level,2) == 1, cal_level = repmat(cal_level,1,size(signaldata.audio,2)); end
                else
                    warndlg('Incompatible calibration file','Warning!');
                end
            end
        else
            warndlg('No signal loaded!','Whoops...!');
        end
    case 2
        [filename,handles.defaultaudiopath] = uigetfile(...
                    {'*.wav;*.mat;.WAV;.MAT','Calibration file (*.wav,*.mat)'},...
                    'Select audio file',handles.defaultaudiopath);
        if ~ischar(filename)
            return
        else
            [~,~,ext] = fileparts(filename);
        end
        if filename ~= 0
            % Check type of file. First 'if' is for .mat, second is for .wav
            if strcmp(ext,'.mat') || strcmp(ext,'.MAT')
                file = importdata(fullfile(handles.defaultaudiopath,filename));
                if isstruct(file)
                    caltone = file.audio;
                else
                    caltone = file;
                end
            elseif strcmp(ext,'.wav') || strcmp(ext,'.WAV')
                caltone = audioread(fullfile(handles.defaultaudiopath,filename));
            else
                caltone = [];
            end
            if size(caltone,1) < size(caltone,2), caltone = caltone'; end
            cal_level = 10 * log10(mean(caltone.^2,1));
            if (size(signaldata.audio,2) == size(cal_level,2) || size(cal_level,2) == 1) && ismatrix(caltone)
                cal_offset = inputdlg('Calibration tone RMS level',...
                            'Calibration value',[1 50],{'0'});
                if isnan(str2double(char(cal_offset)))
                    return
                else
                    cal_level = str2double(char(cal_offset)) - cal_level;
                end
                if size(cal_level,2) == 1, cal_level = repmat(cal_level,1,size(signaldata.audio,2)); end
            else
                warndlg('Incompatible calibration file!','AARAE info');
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
        cal_level = str2num(char(cal_level))'; %#ok to prevent from spaces introduced in the input boxes
        if size(cal_level,1) > size(cal_level,2), cal_level = cal_level'; end
        if isempty(cal_level) || chans ~= size(cal_level,2)
            warndlg('Calibration values mismatch!','AARAE info');
            return
        end
    case 4
        caldata = selectedNodes(1).handle.UserData;
        cal_level = 10 .* log10(mean(caldata.audio.^2,1));
        cal_level = repmat(20*log10(mean(10.^(cal_level./20),2)),1,size(caldata.audio,2));
        cal_offset = inputdlg('Signal RMS level',...
                    'Calibration value',[1 50],cellstr(num2str(zeros(size(cal_level)))));
        if isempty(cal_offset)
            return;
        else
            cal_offset = str2num(char(cal_offset)); %#ok : to allow spaces between calibration values
        end
        if (isequal(size(cal_offset),size(cal_level)) || size(cal_offset,2) == 1) && ismatrix(caldata.audio)
            cal_level = cal_offset - cal_level;
        else
            warndlg('Calibration values mismatch!','AARAE info');
            return
        end
    case 5
        caldata = selectedNodes(1).handle.UserData;
        weights = what([cd '/Processors/Filters']);
        if ~isempty(weights.m)
            [selection,ok] = listdlg('ListString',cellstr(weights.m),'SelectionMode','single');
        else
            warndlg('No weighting filters found!','AARAE info')
            return
        end
        if ok == 1
            [~,funname] = fileparts(weights.m{selection,1});
            caldata = feval(funname,caldata);
            cal_level = 10 .* log10(mean(caldata.audio.^2,1));
            cal_level = repmat(20*log10(mean(10.^(cal_level./20),2)),1,size(caldata.audio,2));
            cal_offset = inputdlg('Signal RMS level',...
                        'Calibration value',[1 50],cellstr(num2str(zeros(size(cal_level)))));
            if isempty(cal_offset)
                return;
            else
                cal_offset = str2num(char(cal_offset)); %#ok : to allow spaces between calibration values
            end
            if (isequal(size(cal_offset),size(cal_level)) || size(cal_offset,2) == 1) && ismatrix(caldata.audio)
                cal_level = cal_offset - cal_level;
            else
                warndlg('Calibration values mismatch!','AARAE info');
                return
            end
        else
            return
        end
    case 6
        return
end
if ~isempty(cal_level)
    for i = 1:length(selectedNodes)
        signaldata = selectedNodes(i).handle.UserData;
        callevel = cal_level;
        if size(signaldata.audio,2) < length(cal_level), callevel = cal_level(1:size(signaldata.audio,2)); end
        if size(signaldata.audio,2) > length(cal_level), callevel = [cal_level NaN(1,size(signaldata.audio,2)-length(cal_level))]; end
        signaldata.cal = callevel;
        selectedNodes(i).handle.UserData = signaldata;
        selectedParent = selectedNodes(i).getParent;
        handles.mytree.reloadNode(selectedParent);
        fprintf(handles.fid, [' ' datestr(now,16) ' - Calibrated "' char(selectedNodes(i).getName) '": adjusted to ' num2str(cal_level) 'dB \n']);
    end
    handles.mytree.setSelectedNodes(selectedNodes)
end
guidata(hObject,handles)


% --- Executes on button press in calc_btn.
function calc_btn_Callback(~, ~, handles)
% hObject    handle to calc_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Call the window that displays calculators
calculator('main_stage1', handles.aarae);

% Handles update is done inside calculator.m


% --- Executes on key press with focus on aarae or any of its controls.
function aarae_WindowKeyPressFcn(hObject, eventdata, handles) %#ok
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
%guidata(hObject,handles)
selectedNodes = handles.mytree.getSelectedNodes;
signaldata = selectedNodes(1).handle.UserData;
if ~isempty(signaldata)
    if strcmp(eventdata.Key,'l') && ~isfield(handles,'legend')
        if ismatrix(signaldata.audio)
            if isfield(signaldata,'chanID')
                handles.legend = legend(handles.axestime,signaldata.chanID);
            end
        end
        if ~ismatrix(signaldata.audio)
            if isfield(signaldata,'bandID')
                handles.legend = legend(handles.axestime,cellstr(num2str(signaldata.bandID')));
            end
        end
    elseif strcmp(eventdata.Key,'l') && isfield(handles,'legend')
        legend(handles.axestime,'off');
        handles = rmfield(handles,'legend');
    end
end
if ~isempty(eventdata.Modifier)
    if strcmp(eventdata.Modifier,'control') == 1
        switch eventdata.Key
            case 'r'
                rec_btn_Callback(hObject, eventdata, handles)
            case 'g'
                genaudio_btn_Callback(hObject, eventdata, handles)
            case 'l'
                load_btn_Callback(hObject, eventdata, handles)
            case 'c'
                calc_btn_Callback(hObject, eventdata, handles)
            case 'e'
                if strcmp(get(handles.tools_panel,'Visible'),'on')
                    edit_btn_Callback(hObject, eventdata, handles)
                end
            case 's'
                if strcmp(get(handles.tools_panel,'Visible'),'on')
                    save_btn_Callback(hObject, eventdata, handles)
                end
            case 'delete'
                if strcmp(get(handles.tools_panel,'Visible'),'on')
                    delete_btn_Callback(hObject, eventdata, handles)
                end
        end
    end
end
guidata(hObject,handles)


% --- Executes on selection change in result_box.
function result_box_Callback(hObject, ~, handles) %#ok
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
function result_box_CreateFcn(hObject, ~, ~) %#ok
% hObject    handle to result_box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in freq_popup.
function freq_popup_Callback(hObject, ~, handles) %#ok
% hObject    handle to freq_popup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns freq_popup contents as cell array
%        contents{get(hObject,'Value')} returns selected item from freq_popup
refreshplots(handles,'freq')
guidata(hObject,handles)

% --- Executes during object creation, after setting all properties.
function freq_popup_CreateFcn(hObject, ~, ~) %#ok
% hObject    handle to freq_popup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in time_popup.
function time_popup_Callback(hObject, ~, handles) %#ok
% hObject    handle to time_popup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns time_popup contents as cell array
%        contents{get(hObject,'Value')} returns selected item from time_popup
contents = cellstr(get(hObject,'String'));
selection = contents{get(hObject,'Value')};
set(handles.compare_btn,'TooltipString',['Compare selected signals in ' selection])
refreshplots(handles,'time')
guidata(hObject,handles)

% --- Executes during object creation, after setting all properties.
function time_popup_CreateFcn(hObject, ~, ~) %#ok
% hObject    handle to time_popup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in playreverse_btn.
function playreverse_btn_Callback(hObject, ~, handles) %#ok
% hObject    handle to playreverse_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

hMain = getappdata(0,'hMain');
audiodata = getappdata(hMain,'testsignal');

if isempty(audiodata)
    warndlg('No signal loaded!');
else
    % Retrieve information from the selected leaf
    testsignal = real(audiodata.audio);
    if size(testsignal,3) > 1, testsignal = sum(testsignal,3); end
    if size(testsignal,2) > 2, testsignal = mean(testsignal,2); end
    testsignal = flipud(testsignal)./max(max(abs(testsignal)));
    fs = audiodata.fs;
    nbits = 16;
    doesSupport = audiodevinfo(0, handles.odeviceid, fs, nbits, size(testsignal,2));
    if doesSupport && ismatrix(testsignal)
        % Play signal
        handles.player = audioplayer(testsignal,fs,nbits,handles.odeviceid);
        play(handles.player);
        selectedNodes = handles.mytree.getSelectedNodes;
        contents = cellstr(get(handles.device_popup,'String'));
        fprintf(handles.fid, [' ' datestr(now,16) ' - Played "' char(selectedNodes(1).getName) '" using ' contents{get(hObject,'Value')} '\n']);
    else
        warndlg('Device not supported for playback!');
    end
end
guidata(hObject, handles);


% --- Executes on button press in randphaseplay_btn.
function randphaseplay_btn_Callback(hObject, ~, handles) %#ok
% hObject    handle to randphaseplay_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hMain = getappdata(0,'hMain');
audiodata = getappdata(hMain,'testsignal');

if isempty(audiodata)
    warndlg('No signal loaded!');
else
    % Retrieve information from the selected leaf
    testsignal = real(audiodata.audio);
    if size(testsignal,3) > 1, testsignal = sum(testsignal,3); end
    if size(testsignal,2) > 2, testsignal = mean(testsignal,2); end
    testsignal = testsignal./max(max(abs(testsignal)));
    len = length(testsignal);
    len = 2 * ceil(len/2);
    spectrum = fft(testsignal,len);
    magnitude = abs(spectrum);
    randphase = rand(len/2-1,1) .* 2 * pi;
    randphase = repmat([0; randphase; 0; flipud(-randphase)],1,size(testsignal,2));
    changed_spectrum = magnitude .* exp(1i * randphase);
    testsignal = ifft(changed_spectrum);
    fs = audiodata.fs;
    nbits = 16;
    doesSupport = audiodevinfo(0, handles.odeviceid, fs, nbits, size(testsignal,2));
    if doesSupport && ismatrix(testsignal)
        % Play signal
        handles.player = audioplayer(testsignal,fs,nbits,handles.odeviceid);
        play(handles.player);
        selectedNodes = handles.mytree.getSelectedNodes;
        contents = cellstr(get(handles.device_popup,'String'));
        fprintf(handles.fid, [' ' datestr(now,16) ' - Played "' char(selectedNodes(1).getName) '" using ' contents{get(hObject,'Value')} '\n']);
    else
        warndlg('Device not supported for playback!');
    end
end
guidata(hObject, handles);


% --- Executes on button press in flatmagplay_btn.
function flatmagplay_btn_Callback(hObject, ~, handles) %#ok
% hObject    handle to flatmagplay_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hMain = getappdata(0,'hMain');
audiodata = getappdata(hMain,'testsignal');

if isempty(audiodata)
    warndlg('No signal loaded!');
else
    % Retrieve information from the selected leaf
    testsignal = real(audiodata.audio);
    if size(testsignal,3) > 1, testsignal = sum(testsignal,3); end
    if size(testsignal,2) > 2, testsignal = mean(testsignal,2); end
    testsignal = testsignal./max(max(abs(testsignal)));
    len = length(testsignal);
    %len = 2 .* ceil(len./2);
    spectrum = fft(testsignal,len);
    phase = angle(spectrum);
    rmsmag = mean(abs(spectrum).^2).^0.5; % root mean square magnitude

    % combine magnitude with phase
    changed_spectrum = ones(len,size(testsignal,2)).*repmat(rmsmag,size(testsignal,1),1) .* exp(1i .* phase);
    changed_spectrum(1) = 0; % make DC zero
    changed_spectrum(ceil(len/2)) = 0; % make Nyquist zero
    testsignal = ifft(changed_spectrum);
    fs = audiodata.fs;
    nbits = 16;
    doesSupport = audiodevinfo(0, handles.odeviceid, fs, nbits, size(testsignal,2));
    if doesSupport && ismatrix(testsignal)
        % Play signal
        handles.player = audioplayer(testsignal,fs,nbits,handles.odeviceid);
        play(handles.player);
        selectedNodes = handles.mytree.getSelectedNodes;
        contents = cellstr(get(handles.device_popup,'String'));
        fprintf(handles.fid, [' ' datestr(now,16) ' - Played "' char(selectedNodes(1).getName) '" using ' contents{get(hObject,'Value')} '\n']);
    else
        warndlg('Device not supported for playback!');
    end
end
guidata(hObject, handles);


% --- Executes on button press in convplay_btn.
function convplay_btn_Callback(hObject, ~, handles) %#ok
% hObject    handle to convplay_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hMain = getappdata(0,'hMain');
audiodata = getappdata(hMain,'testsignal');

if isempty(audiodata)
    warndlg('No signal loaded!');
else
    % Retrieve information from the selected leaf
    testsignal = real(audiodata.audio);
    if size(testsignal,3) > 1, testsignal = sum(testsignal,3); end
    if size(testsignal,2) > 2, testsignal = mean(testsignal,2); end
    testsignal = testsignal./max(max(abs(testsignal)));
    fs = audiodata.fs;
    reference_audio = resample(handles.reference_audio.audio,fs,handles.reference_audio.fs);
    reference_audio = repmat(reference_audio,1,size(testsignal,2));
    len1 = length(testsignal);
    len2 = length(reference_audio);
    outputlength = len1 + len2 - 1;
    testsignal = ifft(fft(testsignal, outputlength) .* fft(reference_audio, outputlength));
    testsignal = testsignal./max(max(max(abs(testsignal))));
    nbits = 16;
    doesSupport = audiodevinfo(0, handles.odeviceid, fs, nbits, size(testsignal,2));
    if doesSupport && ismatrix(testsignal)
        % Play signal
        handles.player = audioplayer(testsignal,fs,nbits,handles.odeviceid);
        play(handles.player);
        selectedNodes = handles.mytree.getSelectedNodes;
        contents = cellstr(get(handles.device_popup,'String'));
        fprintf(handles.fid, [' ' datestr(now,16) ' - Played "' char(selectedNodes(1).getName) '" using ' contents{get(hObject,'Value')} '\n']);
    else
        warndlg('Device not supported for playback!');
    end
end
guidata(hObject, handles);


% --- Executes on button press in clrall_btn.
function clrall_btn_Callback(hObject, ~, handles) %#ok
% hObject    handle to clrall_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
root = handles.root; % Get selected leaf
root = root(1);
first = root.getFirstChild;
nbranches = root.getChildCount;
branches = cell(nbranches,1);
branches{1,1} = char(first.getValue);
nleaves = 0;
nleaves = nleaves + handles.(genvarname(branches{1,1}))(1).getChildCount;
next = first.getNextSibling;
for n = 2:nbranches
    branches{n,1} = char(next.getValue);
    nleaves = nleaves + handles.(genvarname(branches{n,1}))(1).getChildCount;
    next = next.getNextSibling;
end
leaves = cell(nleaves,1);
i = 0;
for n = 1:size(branches,1)
    currentbranch = handles.(genvarname(branches{n,1}));
    if currentbranch.getChildCount ~= 0
        i = i + 1;
        first = currentbranch.getFirstChild;
        %leafnames(i,:) = first.getName;
        leaves{i,:} = char(first.getValue);
        next = first.getNextSibling;
        if ~isempty(next)
            for m = 1:currentbranch.getChildCount-1
                i = i + 1;
                %leafnames(i,:) = next.getName;
                leaves{i,:} = char(next.getValue);
                next = next.getNextSibling;
            end
        end
    end
end
if nleaves == 0
    warndlg('Nothing to delete!','AARAE info');
else
    %leafnames = char(leafnames);
    %leaves = char(leaves);
    delete = questdlg('Current workspace will be cleared, would you like to proceed?',...
        'Warning',...
        'Yes','No','Yes');
    switch delete
        case 'Yes'
        set(hObject,'BackgroundColor','red');
        set(hObject,'Enable','off');
        for i = 1:size(leaves,1)
            current = handles.(genvarname(leaves{i,1}));
            handles.mytree.remove(current);
            handles = rmfield(handles,genvarname(leaves{i,1}));
        end
        handles.mytree.reloadNode(handles.root);
        handles.mytree.setSelectedNode(handles.root);
        rmpath([cd '/Utilities/Temp']);
        rmdir([cd '/Utilities/Temp'],'s');
        mkdir([cd '/Utilities/Temp']);
        addpath([cd '/Utilities/Temp']);
        set(handles.result_box,'String',cell(1,1));
        fprintf(handles.fid, [' ' datestr(now,16) ' - Cleared workspace \n']);
        set(hObject,'BackgroundColor',[0.94 0.94 0.94]);
        set(hObject,'Enable','off');
        set(handles.export_btn,'Enable','off');
    end
end
guidata(hObject,handles)


% --- Executes on selection change in smoothfreq_popup.
function smoothfreq_popup_Callback(hObject, ~, handles) %#ok
% hObject    handle to smoothfreq_popup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns smoothfreq_popup contents as cell array
%        contents{get(hObject,'Value')} returns selected item from smoothfreq_popup
refreshplots(handles,'freq')
guidata(hObject,handles)

% --- Executes during object creation, after setting all properties.
function smoothfreq_popup_CreateFcn(hObject, ~, ~) %#ok
% hObject    handle to smoothfreq_popup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in smoothtime_popup.
function smoothtime_popup_Callback(hObject, ~, handles) %#ok
% hObject    handle to smoothtime_popup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns smoothtime_popup contents as cell array
%        contents{get(hObject,'Value')} returns selected item from smoothtime_popup
refreshplots(handles,'time')
guidata(hObject,handles)

% --- Executes during object creation, after setting all properties.
function smoothtime_popup_CreateFcn(hObject, ~, ~) %#ok
% hObject    handle to smoothtime_popup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in logfreq_chk.
function logfreq_chk_Callback(hObject, ~, handles) %#ok
% hObject    handle to logfreq_chk (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of logfreq_chk
refreshplots(handles,'freq')
guidata(hObject,handles)

% --- Executes on button press in logtime_chk.
function logtime_chk_Callback(hObject, ~, handles) %#ok
% hObject    handle to logtime_chk (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of logtime_chk
refreshplots(handles,'time')
guidata(hObject,handles)


% --- Executes on button press in properties_btn.
function properties_btn_Callback(~, ~, handles) %#ok
% hObject    handle to properties_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
selectedNodes = handles.mytree.getSelectedNodes;
signaldata = selectedNodes(1).handle.UserData;
if isfield(signaldata,'properties')
    properties = signaldata.properties; %#ok : used for evalc
    msgbox([selectedNodes(1).getName.char evalc('properties')],'AARAE info')
end


% --- Executes on button press in compare_btn.
function compare_btn_Callback(~, ~, handles) %#ok
% hObject    handle to compare_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
selectedNodes = handles.mytree.getSelectedNodes;
compplot = figure;
for i = 1:length(selectedNodes)
    linea = [];
    axes = 'time';
    signaldata = selectedNodes(i).handle.UserData;
    if ~isempty(signaldata) && isfield(signaldata,'audio')
        plottype = get(handles.(genvarname([axes '_popup'])),'Value');
        t = linspace(0,length(signaldata.audio),length(signaldata.audio))./signaldata.fs;
        f = signaldata.fs .* ((1:length(signaldata.audio))-1) ./ length(signaldata.audio);
        if ~ismatrix(signaldata.audio)
            if ndims(signaldata.audio) == 3, cmap = colormap(hsv(size(signaldata.audio,3))); end
            if ndims(signaldata.audio) >= 4, cmap = colormap(copper(size(signaldata.audio,4))); end
            try 
                linea(:,:) = signaldata.audio(:,str2double(get(handles.IN_nchannel,'String')),:);
            catch
                linea = zeros(size(t));
            end
        else
            cmap = colormap(lines(size(signaldata.audio,2)));
            linea = signaldata.audio;
        end
        if isfield(signaldata,'cal') && handles.Preferences.calibrationtoggle == 1
            if size(linea,2) == length(signaldata.cal)
                signaldata.cal(isnan(signaldata.cal)) = 0;
                linea = linea.*repmat(10.^(signaldata.cal./20),length(linea),1);
            elseif ~ismatrix(signaldata.audio) && size(signaldata.audio,2) == length(signaldata.cal)
                signaldata.cal(isnan(signaldata.cal)) = 0;
                cal = repmat(signaldata.cal(str2double(get(handles.IN_nchannel,'String'))),1,size(linea,2));
                linea = linea.*repmat(10.^(cal./20),length(linea),1);
            end
        end
        if plottype == 1, linea = real(linea); end
        if plottype == 2, linea = linea.^2; end
        if plottype == 3, linea = 10.*log10(linea.^2); end
        if plottype == 4, linea = abs(hilbert(real(linea))); end
        if plottype == 5, linea = medfilt1(diff([angle(hilbert(real(linea))); zeros(1,size(linea,2))])*signaldata.fs/2/pi, 5); end
        if plottype == 6, linea = abs(linea); end
        if plottype == 7, linea = imag(linea); end
        if plottype == 8, linea = 10*log10(abs(fft(linea)).^2); end %freq
        if plottype == 9, linea = abs(fft(linea)).^2; end
        if plottype == 10, linea = abs(fft(linea)); end
        if plottype == 11, linea = real(fft(linea)); end
        if plottype == 12, linea = imag(fft(linea)); end
        if plottype == 13, linea = angle(fft(linea)); end
        if plottype == 14, linea = unwrap(angle(fft(linea))); end
        if plottype == 15, linea = angle(fft(linea)) .* 180/pi; end
        if plottype == 16, linea = unwrap(angle(fft(linea))) ./(2*pi); end
        if plottype == 17, linea = -diff(unwrap(angle(fft(linea)))).*length(fft(linea))/(signaldata.fs*2*pi).*1000; end
        if strcmp(get(handles.(genvarname(['smooth' axes '_popup'])),'Visible'),'on')
            smoothfactor = get(handles.(genvarname(['smooth' axes '_popup'])),'Value');
            if smoothfactor == 2, octsmooth = 1; end
            if smoothfactor == 3, octsmooth = 3; end
            if smoothfactor == 4, octsmooth = 6; end
            if smoothfactor == 5, octsmooth = 12; end
            if smoothfactor == 6, octsmooth = 24; end
            if smoothfactor ~= 1, linea = octavesmoothing(linea, octsmooth, signaldata.fs); end
        end
        if length(selectedNodes) == 1
            [r, c] = subplotpositions(size(linea,2), 0.5);
            for j = 1:size(linea,2)
                if plottype <= 7
                    subplot(r,c,j);
                    set(gca,'NextPlot','replacechildren','ColorOrder',cmap(j,:))
                    plot(t,real(linea(:,j))) % Plot signal in time domain
                    if ismatrix(signaldata.audio) && isfield(signaldata,'chanID'), title(signaldata.chanID{j,1}); end
                    if ~ismatrix(signaldata.audio) && isfield(signaldata,'bandID'), title(num2str(signaldata.bandID(1,j))); end
                    xlabel('Time [s]');
                end
                if plottype >= 8
                    h = subplot(r,c,j);
                    set(gca,'NextPlot','replacechildren','ColorOrder',cmap(j,:))
                    plot(f(1:length(linea(:,j))),linea(:,j));% Plot signal in frequency domain
                    if ismatrix(signaldata.audio) && isfield(signaldata,'chanID'), title(signaldata.chanID{j,1}); end
                    if ~ismatrix(signaldata.audio) && isfield(signaldata,'bandID'), title(num2str(signaldata.bandID(1,j))); end
                    xlabel('Frequency [Hz]');
                    if ischar(handles.Preferences.frequencylimits)
                        xlim([f(2) signaldata.fs/2])
                    else
                        xlim(handles.Preferences.frequencylimits)
                    end
                    log_check = get(handles.(genvarname(['log' axes '_chk'])),'Value');
                    if log_check == 1
                        set(h,'XScale','log')
                    else
                        set(h,'XScale','linear','XTickLabelMode','auto')
                    end
                end
            end
        else
            if plottype <= 7
                subplot(length(selectedNodes),1,i);
                set(gca,'NextPlot','replacechildren','ColorOrder',cmap)
                plot(t,real(linea)) % Plot signal in time domain
                title(selectedNodes(i).getName.char)
                xlabel('Time [s]');
            end
            if plottype >= 8
                h = subplot(length(selectedNodes),1,i);
                set(gca,'NextPlot','replacechildren','ColorOrder',cmap)
                plot(f(1:length(linea)),linea);% Plot signal in frequency domain
                title(selectedNodes(i).getName.char)
                xlabel('Frequency [Hz]');
                if ischar(handles.Preferences.frequencylimits)
                    xlim([f(2) signaldata.fs/2])
                else
                    xlim(handles.Preferences.frequencylimits)
                end
                log_check = get(handles.(genvarname(['log' axes '_chk'])),'Value');
                if log_check == 1
                    set(h,'XScale','log')
                else
                    set(h,'XScale','linear','XTickLabelMode','auto')
                end
            end
        end
    end
end
iplots = get(compplot,'Children');
if length(iplots) > 1
    xlims = cell2mat(get(iplots,'Xlim'));
    set(iplots,'Xlim',[min(xlims(:,1)) max(xlims(:,2))])
    ylims = cell2mat(get(iplots,'Ylim'));
    set(iplots,'Ylim',[min(ylims(:,1)) max(ylims(:,2))])
    uicontrol('Style', 'pushbutton', 'String', 'Axes limits',...
            'Position', [0 0 65 30],...
            'Callback', 'setaxeslimits');
end


% --- Executes on selection change in ntable_popup.
function ntable_popup_Callback(hObject, eventdata, handles) %#ok
% hObject    handle to ntable_popup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns ntable_popup contents as cell array
%        contents{get(hObject,'Value')} returns selected item from ntable_popup
eventdata.NewValue = get(handles.Xvalues_sel,'SelectedObject');
Xvalues_sel_SelectionChangeFcn(hObject, eventdata, handles)
Yvalues_box_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function ntable_popup_CreateFcn(hObject, ~, ~) %#ok
% hObject    handle to ntable_popup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in Xvalues_box.
function Xvalues_box_Callback(~, ~, ~) %#ok
% hObject    handle to Xvalues_box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns Xvalues_box contents as cell array
%        contents{get(hObject,'Value')} returns selected item from Xvalues_box


% --- Executes during object creation, after setting all properties.
function Xvalues_box_CreateFcn(hObject, ~, ~) %#ok
% hObject    handle to Xvalues_box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in Yvalues_box.
function Yvalues_box_Callback(~, ~, handles)
% hObject    handle to Yvalues_box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns Yvalues_box contents as cell array
%        contents{get(hObject,'Value')} returns selected item from Yvalues_box
selectedNodes = handles.mytree.getSelectedNodes;
data = selectedNodes(1).handle.UserData;
ntable = get(handles.ntable_popup,'Value');
Xvalues = get(handles.Xvalues_sel,'SelectedObject');
Xvalues = get(Xvalues,'tag');
switch Xvalues
    case 'radiobutton1'
        bar(handles.axesdata,data.tables(ntable).Data(:,get(handles.Yvalues_box,'Value')),'FaceColor',[0 0.5 0.5])
        set(handles.axesdata,'Xtick',1:length(data.tables(ntable).RowName),'XTickLabel',data.tables(ntable).RowName)
    case 'radiobutton2'
        bar(handles.axesdata,data.tables(ntable).Data(get(handles.Yvalues_box,'Value'),:),'FaceColor',[0 0.5 0.5])
        set(handles.axesdata,'Xtick',1:length(data.tables(ntable).ColumnName),'XTickLabel',data.tables(ntable).ColumnName)
end

% --- Executes during object creation, after setting all properties.
function Yvalues_box_CreateFcn(hObject, ~, ~) %#ok
% hObject    handle to Yvalues_box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes when selected object is changed in Xvalues_sel.
function Xvalues_sel_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in Xvalues_sel 
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)
selectedNodes = handles.mytree.getSelectedNodes;
data = selectedNodes(1).handle.UserData;
ntable = get(handles.ntable_popup,'Value');
switch get(eventdata.NewValue,'Tag')
    case 'radiobutton1'
        set(handles.Xvalues_box,'String',data.tables(ntable).RowName,'Value',1)
        set(handles.Yvalues_box,'String',data.tables(ntable).ColumnName,'Value',1)
    case 'radiobutton2'
        set(handles.Yvalues_box,'String',data.tables(ntable).RowName,'Value',1)
        set(handles.Xvalues_box,'String',data.tables(ntable).ColumnName,'Value',1)
end
Yvalues_box_Callback(hObject, eventdata, handles)


% --- Executes on selection change in nchart_popup.
function nchart_popup_Callback(hObject, ~, handles) %#ok
% hObject    handle to nchart_popup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns nchart_popup contents as cell array
%        contents{get(hObject,'Value')} returns selected item from nchart_popup
plot(handles.axesdata,0,0)
selectedNodes = handles.mytree.getSelectedNodes;
data = selectedNodes(1).handle.UserData;
contents = cellstr(get(hObject,'String'));
if ~strcmp(contents{get(hObject,'Value')},' ')
    linedata = data.lines.(contents{get(hObject,'Value')}).data;
    axis2 = handles.axesdata;
    for j = 1:length(linedata)
        l1 = [];
        if strcmp(linedata{j,1}.Type,'line'), l1 = line; end
        if strcmp(linedata{j,1}.Type,'surface'), l1 = surface; end
        %if strcmp(linedata{j,1}.Type,'hggroup'), l1 = hggroup; end
        if ~isempty(l1)
            linedata{j,1}.Parent = axis2;
            dif = intersect(fieldnames(linedata{j,1}),fieldnames(set(l1)));
            for i = 1:size(dif,1)
                set(l1,dif{i},linedata{j,1}.(dif{i,1}))
            end
        end
    end
    axesprop = data.lines.(contents{get(hObject,'Value')}).axisproperties;
    xlabel(handles.axesdata,axesprop.xlabel)
    ylabel(handles.axesdata,axesprop.ylabel)
    zlabel(handles.axesdata,axesprop.zlabel)
    propdif = intersect(fieldnames(set(gca)),fieldnames(axesprop));
    propdif = propdif(~strcmp(propdif,'Children'));
    propdif = propdif(~strcmp(propdif,'Parent'));
    propdif = propdif(~strcmp(propdif,'OuterPosition'));
    propdif = propdif(~strcmp(propdif,'Position'));
    propdif = propdif(~strcmp(propdif,'Title'));
    propdif = propdif(~strcmp(propdif,'XLabel'));
    propdif = propdif(~strcmp(propdif,'YLabel'));
    propdif = propdif(~strcmp(propdif,'ZLabel'));
    for i = 1:size(propdif,1)
        set(handles.axesdata,propdif{i},axesprop.(propdif{i,1}))
    end
    %set(handles.axesdata,'XScale',axesprop.xscale)
    %set(handles.axesdata,'YScale',axesprop.yscale)
    %set(handles.axesdata,'ZScale',axesprop.zscale)
end


% --- Executes during object creation, after setting all properties.
function nchart_popup_CreateFcn(hObject, ~, ~) %#ok
% hObject    handle to nchart_popup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in wild_btn.
%function wild_btn_Callback(hObject, eventdata, handles)
% hObject    handle to wild_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%!matlab -nodesktop



function To_freq_Callback(hObject, ~, handles) %#ok : Executed when initial time input box changes above the lower axes
% hObject    handle to To_freq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of To_freq as text
%        str2double(get(hObject,'String')) returns contents of To_freq as a double
To_freq = str2double(get(hObject,'String'));
selectedNodes = handles.mytree.getSelectedNodes;
signaldata = selectedNodes(1).handle.UserData;
if isnan(To_freq) || To_freq < 0 || To_freq == length(signaldata.audio)/signaldata.fs
    %warndlg('Invalid entry','AARAE info','modal')
    set(hObject,'String',num2str(handles.To_freq_IN))
elseif To_freq >= str2double(get(handles.Tf_freq,'String'))
    Tf_freq = To_freq + (handles.Tf_freq_IN - handles.To_freq_IN);
    if Tf_freq > length(signaldata.audio)/signaldata.fs
        Tf_freq = length(signaldata.audio)/signaldata.fs;
    end
    set(handles.Tf_freq,'String',num2str(Tf_freq))
    handles.To_freq_IN = To_freq;
    handles.Tf_freq_IN = Tf_freq;
    refreshplots(handles,'freq')
    guidata(hObject,handles)
else
    handles.To_freq_IN = To_freq;
    refreshplots(handles,'freq')
    guidata(hObject,handles)
end



% --- Executes during object creation, after setting all properties.
function To_freq_CreateFcn(hObject, ~, ~) %#ok : creation of initial time input box for the lower axes
% hObject    handle to To_freq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function Tf_freq_Callback(hObject, ~, handles) %#ok : Executed when final time input box for lower axes changes
% hObject    handle to Tf_freq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Tf_freq as text
%        str2double(get(hObject,'String')) returns contents of Tf_freq as a double
Tf_freq = str2double(get(hObject,'String'));
selectedNodes = handles.mytree.getSelectedNodes;
signaldata = selectedNodes(1).handle.UserData;
if isnan(Tf_freq) || Tf_freq <= str2double(get(handles.To_freq,'String')) || Tf_freq > length(signaldata.audio)/signaldata.fs
    %warndlg('Invalid entry','AARAE info','modal')
    set(hObject,'String',handles.Tf_freq_IN)
    refreshplots(handles,'freq')
    guidata(hObject,handles)
else
    handles.Tf_freq_IN = Tf_freq;
    refreshplots(handles,'freq')
    guidata(hObject,handles)
end


% --- Executes during object creation, after setting all properties.
function Tf_freq_CreateFcn(hObject, ~, ~) %#ok : creation of final time input box for the lower axes
% hObject    handle to Tf_freq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function To_time_Callback(hObject, ~, handles) %#ok : Executed when initial time input box changes above upper axes
% hObject    handle to To_time (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of To_time as text
%        str2double(get(hObject,'String')) returns contents of To_time as a double
To_time = str2double(get(hObject,'String'));
selectedNodes = handles.mytree.getSelectedNodes;
signaldata = selectedNodes(1).handle.UserData;
if isnan(To_time) || To_time < 0 || To_time == length(signaldata.audio)/signaldata.fs
    set(hObject,'String',num2str(handles.To_time_IN))
elseif To_time >= str2double(get(handles.Tf_time,'String'))
    Tf_time = To_time + (handles.Tf_time_IN - handles.To_time_IN);
    if Tf_time > length(signaldata.audio)/signaldata.fs
        Tf_time = length(signaldata.audio)/signaldata.fs;
    end
    set(handles.Tf_time,'String',num2str(Tf_time))
    handles.To_time_IN = To_time;
    handles.Tf_time_IN = Tf_time;
    refreshplots(handles,'time')
    guidata(hObject,handles)
else
    handles.To_time_IN = To_time;
    refreshplots(handles,'time')
    guidata(hObject,handles)
end


% --- Executes during object creation, after setting all properties.
function To_time_CreateFcn(hObject, ~, ~) %#ok : creation of initial time input box for the upper axes
% hObject    handle to To_time (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function Tf_time_Callback(hObject, ~, handles) %#ok : Executed when final time input box for upper axes changes
% hObject    handle to Tf_time (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Tf_time as text
%        str2double(get(hObject,'String')) returns contents of Tf_time as a double
Tf_time = str2double(get(hObject,'String'));
selectedNodes = handles.mytree.getSelectedNodes;
signaldata = selectedNodes(1).handle.UserData;
if isnan(Tf_time) || Tf_time <= str2double(get(handles.To_time,'String')) || Tf_time > length(signaldata.audio)/signaldata.fs
    %warndlg('Invalid entry','AARAE info','modal')
	set(hObject,'String',handles.Tf_time_IN)
    refreshplots(handles,'time')
    guidata(hObject,handles)
else
    handles.Tf_time_IN = Tf_time;
    refreshplots(handles,'time')
    guidata(hObject,handles)
end


% --- Executes during object creation, after setting all properties.
function Tf_time_CreateFcn(hObject, ~, ~) %#ok : creation of final time input box for the upper axes
% hObject    handle to Tf_time (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in preferences_btn.
function preferences_btn_Callback(hObject, ~, handles) %#ok : Executed when Preferences button is clicked
% hObject    handle to preferences_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
Preferences = preferences('main_stage1', handles.aarae);%inputdlg('Maximum time period to display','AARAE preferences',[1 50],{num2str(handles.preferences.maxtimetodisplay)});
if ~isempty(Preferences)
    %newpref = cell2struct(newpref,{'maxtimetodisplay'});
    %newpref.maxtimetodisplay = str2double(newpref.maxtimetodisplay);
    handles.Preferences = Preferences;
    save([cd '/Preferences.mat'],'Preferences')
    guidata(hObject,handles)
    selectedNodes = handles.mytree.getSelectedNodes;
    handles.mytree.setSelectedNode(handles.root);
    handles.mytree.setSelectedNode(selectedNodes(1));
end


function doresultplot(handles)
% hObject    handle to dimsel_IN (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of dimsel_IN as text
%        str2double(get(hObject,'String')) returns contents of dimsel_IN as a double
selectedNodes = handles.mytree.getSelectedNodes;
audiodata = selectedNodes(1).handle.UserData;
chartmenu = cellstr(get(handles.chartfunc_popup,'String'));
chartfunc = chartmenu{get(handles.chartfunc_popup,'Value')};
cattable = get(handles.cattable);
sel = strjoin(cattable.Data(:,2).',',');
if isempty(sel), sel = '[1]'; end
try
    if length(audiodata.datainfo.dimensions) == 1
        Xdata = audiodata.(genvarname(audiodata.datainfo.dimensions{1,1}));
        if ~isequal(size(Xdata),size(audiodata.data))
            eval([chartfunc '(handles.axesdata,Xdata,squeeze(audiodata.data(:,' sel ')))'])
        else
            eval([chartfunc '(handles.axesdata,squeeze(Xdata(:,' sel ')),squeeze(audiodata.data(:,' sel ')))'])
        end
        xlabel(handles.axesdata,[audiodata.datainfo.dimensions{1,1} ' [' audiodata.(genvarname([audiodata.datainfo.dimensions{1,1} 'info'])).units ']'])
    elseif length(audiodata.datainfo.dimensions) == 2
        Xdata = audiodata.(genvarname(audiodata.datainfo.dimensions{1,1})); %#ok : Used in eval function below
        Ydata = audiodata.(genvarname(audiodata.datainfo.dimensions{1,2})); %#ok : Used in eval function below
        eval([chartfunc '(handles.axesdata,Xdata,Ydata,squeeze(audiodata.data(:,:,' sel ')))'])
        xlabel(handles.axesdata,[audiodata.datainfo.dimensions{1,1} ' [' audiodata.(genvarname([audiodata.datainfo.dimensions{1,1} 'info'])).units ']'])
        ylabel(handles.axesdata,[audiodata.datainfo.dimensions{1,2} ' [' audiodata.(genvarname([audiodata.datainfo.dimensions{1,2} 'info'])).units ']'])
    end
catch error
    set(handles.cattable,'Data',handles.tabledata)
    warndlg(error.message,'AARAE info','modal')
end


% --- Executes on selection change in chartfunc_popup.
function chartfunc_popup_Callback(~, eventdata, handles) %#ok : Executed when selection changes in chart selection popup menu
% hObject    handle to chartfunc_popup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns chartfunc_popup contents as cell array
%        contents{get(hObject,'Value')} returns selected item from chartfunc_popup
doresultplot(handles)

% --- Executes during object creation, after setting all properties.
function chartfunc_popup_CreateFcn(hObject, ~, ~) %#ok : creation of chart selection type popup menu
% hObject    handle to chartfunc_popup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes when selected cell(s) is changed in cattable.
function cattable_CellSelectionCallback(hObject, eventdata, handles) %#ok : opens listdlg for changing selection of categorical dimensions
% hObject    handle to cattable (see GCBO)
% eventdata  structure with the following fields (see UITABLE)
%	Indices: row and column indices of the cell(s) currently selecteds
% handles    structure with handles and user data (see GUIDATA)
if size(eventdata.Indices,1) ~= 0 && eventdata.Indices(1,2) == 2
    selectedNodes = handles.mytree.getSelectedNodes;
    audiodata = selectedNodes(1).handle.UserData;
    tabledata = get(hObject,'Data');
    handles.tabledata = tabledata;
    catname = tabledata{eventdata.Indices(1,1),1};
    liststr = audiodata.(genvarname(catname));
    if size(liststr,1) < size(liststr,2), liststr = liststr'; end
    if ~iscellstr(liststr), liststr = cellstr(num2str(cell2mat(liststr))); end
    [sel,ok] = listdlg('ListString',liststr,'InitialValue',str2num(tabledata{eventdata.Indices(1),eventdata.Indices(2)})); %#ok : necessary for getting selection vector
    if ok == 1
        logsel = ['[' num2str(sel) ']'];
        tabledata{eventdata.Indices(1),eventdata.Indices(2)} = logsel(1:end);
    else
        set(hObject,'Data',{''})
    end
    set(hObject,'Data',tabledata)
    guidata(handles.aarae,handles)
    doresultplot(handles)
end
