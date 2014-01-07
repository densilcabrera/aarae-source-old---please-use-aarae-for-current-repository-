% % % The ear has a non-flat frequency response. This means that tones played 
% % % at the same volume with different frequencies can sound like they are 
% % % being played at different volume levels. So you can hear some tones 
% % % easier than others just based on the way the ear is made and its response 
% % % to vibrations at different frequencies.
% % % 
% % % This program assists you in measuring the frequency response of your ear. 
% % % You may test each ear individually and compare them.
% % % 
% % % The result plot illustrates the "Threshold of Hearing", the minimum loudness 
% % % required for you to hear a tone.
% % % 
% % % 1. Lower the volume on your computer until the tone prduced by the first 
% % %      push button is no longer audible. Headphones are recommended.
% % % 2. Click "begin test", and click the third push button whenever you hear a tone.
% % % 3. You can save the plot and data for comparison with others later on.
% % % 
% % % Disclaimer:  The results are relative, since the program has not been calibrated.
% % % If you suspect a hearing problem, you should be tested by a professional.
% % % 
% % % Reference:
% % % http://www.engr.uky.edu/~donohue/audio/fsear.html
% % % (This program operates as described on that website)
% % % 
% % % Samir Rawashdeh, sar@ieee.org
% % % 



function varargout = eartest(varargin)
% EARTEST M-file for eartest.fig
%      EARTEST, by itself, creates a new EARTEST or raises the existing
%      singleton*.
%
%      H = EARTEST returns the handle to a new EARTEST or the handle to
%      the existing singleton*.
%
%      EARTEST('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in EARTEST.M with the given input arguments.
%
%      EARTEST('Property','Value',...) creates a new EARTEST or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before eartest_OpeningFunction gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to eartest_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Copyright 2002-2003 The MathWorks, Inc.

% Edit the above text to modify the response to help eartest

% Last Modified by GUIDE v2.5 25-Aug-2007 22:30:38

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @eartest_OpeningFcn, ...
                   'gui_OutputFcn',  @eartest_OutputFcn, ...
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


% --- Executes just before eartest is made visible.
function eartest_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to eartest (see VARARGIN)

% Choose default command line output for eartest
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes eartest wait for user response (see UIRESUME)
% uiwait(handles.figure1);
clear
%clc
warning off

% --- Outputs from this function are returned to the command line.
function varargout = eartest_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in pushbutton1.
function pushbutton1_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global heard
%% pressed when tone is heard
heard = 1;
%%disp('heard!')

guidata(hObject, handles);


% --- Executes on button press in pushbutton2.
function pushbutton2_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%% begin test

global heard

freqs = [40,60,100,200,300,400,500,600,700,800,900,1000,1200,2000,3000,3500,4000,5000,6000,7000,8000,9000,10000,11000,12000,13000,14000,15000,16000];
amps = 10./(10.^((3/20)*(0:25)));

handles.response = zeros(1,29);

for f = 1:length(freqs)    
    for a = 1:length(amps)
        
        if(f>1 && a < handles.response(f-1)-6) 
            handles.response(f)=handles.response(f-1);
            continue; 
        end
        
        heard = 0;
        plot(freqs,handles.response)
        
        pause(0.2+rand*0.7)  %% wait for duration of tone
        tone(freqs(f),amps(a))
        
        for wait = 1:20
            pause(2/20)        %% wait 2 seconds in total
            if(heard == 1)
                handles.response(f)=a;
                break;
            end
        end
        if(heard == 0) break; end

    end

end

response_3500 = handles.response(find(freqs == 3500));
response_db = 3*(response_3500-handles.response)-4;     %% threshold of hearing plot

set(handles.text2,'string',['At 3.5 kHz, you heard upto level ' num2str(response_3500)])

%%semilogx(freqs,response_db)  %%without polinomial fit

[P,S] = POLYFIT(freqs,response_db,7);

 handles.smooth_response_x = 10:10:16000;
 handles.smooth_response_y = POLYVAL(P,handles.smooth_response_x);

semilogx(handles.smooth_response_x,handles.smooth_response_y)
xlabel('Frequency (Hz)')
ylabel('Threshold of Heading (dB)')
grid on


guidata(hObject, handles);


% --- Executes on button press in pushbutton3.
function pushbutton3_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%% adjust volume, until the following tone becomes inaudible

amps = 10./(10.^((3/20)*(0:25)));
tone(3500,amps(22))


% --- Executes on button press in pushbutton4.
function pushbutton4_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%% to save plot
saveas(gcf,get(handles.edit1,'string'), 'bmp')

X = handles.smooth_response_x;
Y = handles.smooth_response_y;

filename = [get(handles.edit1,'string'), '.mat'];

save filename X Y

function edit1_Callback(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit1 as text
%        str2double(get(hObject,'String')) returns contents of edit1 as a double


% --- Executes during object creation, after setting all properties.
function edit1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function tone(w,amp)

fs=40000;  %sample freq in Hz

t = [0:1/fs:.5]; 

wave=amp*sin(2*pi*w*t); 
envilope = sin(pi*t/t(length(t)));

wave = wave .* envilope;

%play sound
sound(wave,fs);

