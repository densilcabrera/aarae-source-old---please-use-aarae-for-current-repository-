function OUT = audio2hoa(IN, fs, mic_coords, cropIR , max_order)

if nargin < 5, max_order = 4; end
if nargin < 4, cropIR = 0; end
if nargin < 3, mic_coords = importdata([cd '/Processors/Beamforming/Microphones/visisonics_mic_loc.mat']); end
if isstruct(IN)
    IRs = IN.audio;
    fs = IN.fs;
    if nargin < 4
        param = inputdlg({'Maximum order','Apply autocropstart_aarae.m'},...
                       'Input parameters',1,...
                      {num2str(max_order),num2str(cropIR)});
        if isempty(param) || isempty(param{1,1}) || isempty(param{2,1})
            OUT = [];
            return;
        else
            max_order = str2double(param{1,1});
            cropIR = str2double(param{2,1});
            if isnan(max_order) || isnan(cropIR), OUT = []; return; end
        end
    end
    if nargin < 3
        mics = what([cd '/Processors/Beamforming/Microphones']);
        if isempty(mics.mat), warndlg('No microphone coordinates available. To add new mic coordinate files (*.mat) go to /Processors/Beamforming/Microphones','AARAE info','modal'); OUT = []; return; end
        [S,ok] = listdlg('Name','Microphones',...
                         'PromptString','Select microphone coordinates',...
                         'ListString',mics.mat);
        if isempty(S), warndlg('No microphone coordinates selected. To add new mic coordinate files (*.mat) go to /Processors/Beamforming/Microphones','AARAE info','modal'); OUT = []; return; end
        mic_coords = importdata([cd '/Processors/Beamforming/Microphones/' mics.mat{S,1}]);
        if size(IRs,2) ~= size(mic_coords,1), warndlg('The selected microphone coordinates do not match the number of calculated IRs.','AARAE info','modal'); OUT = []; return; end
    end
else
    if nargin < 2
        fs = inputdlg({'Sampling frequency [samples/s]'},...
                           'Fs',1,{'48000'});
        fs = str2double(char(fs));
    end
    IRs = IN;
end

% Pre-treatment IRs
if cropIR == 1,
    trimmedIRs = autocropstart_aarae(IRs,-20,2);
else
    trimmedIRs = IRs;
end
%[~, firstarrivalall] = max(IRs);

%firstarrival = min(firstarrivalall);

%preroll = round((100./1000).*fs);

%if firstarrival-preroll < 0;
%    preroll = 0;
%end

%lengthIRs_after_arrival = round(analysis_length.*fs);

%if firstarrival+lengthIRs_after_arrival > size(IRs,1);
%    lengthIRs_after_arrival = size(IRs,1) - firstarrival;
%    disp('Analysis length too long - trimmed to end of file');
%end

%trimmedIRs = IRs((firstarrival-preroll):(firstarrival+lengthIRs_after_arrival),:);

%trimmedIRs = trimmedIRs./max(max(trimmedIRs)); % Normalize to direct sound

%clear IRs

% Mic setup

if size(mic_coords,2) ~= 3;
    error('Mic coordinates are three columns with spherical coordinates');
end

micFmt = GenerateMicFmt({'sphCoord',mic_coords,'micType','omni'});

% HOA Signals

hoaFmt = GenerateHoaFmt('res2d',max_order,'res3d',max_order) ;

mic2HoaOpt.sampFreq      = fs;
mic2HoaOpt.filterType    = 'firMatrix' ;
mic2HoaOpt.filterLength  = 256 ;
mic2HoaOpt.limiterMethod = 'tikh' ;
mic2HoaOpt.limiterLevel  = 6 ;
mic2HoaOpt.higherOrders  = false ;
mic2HoaOpt.subArrayFilt  = false ;
mic2HoaOpt.highFreqEq    = false ;
mic2HoaOpt.lowPassFreq   = 22000 ;

mic2HoaCfg = Mic2HoaEncodingFilters(hoaFmt,micFmt,mic2HoaOpt);

hoaSignals = zeros(length(trimmedIRs),hoaFmt.nbComp);

for I = 1:size(trimmedIRs,2);
    for J = 1:hoaFmt.nbComp;
        % revisar si se puede hacer matricial
        hoaSignals(:,J) = hoaSignals(:,J) + fftfilt(mic2HoaCfg.filters.firMatrix(:,J,I),trimmedIRs(:,I));
        
    end
end

if isstruct(IN)
    OUT.audio = hoaSignals;
    OUT.fs = fs;
    OUT.chanID = cellstr(num2str(hoaFmt.index));
    OUT.funcallback.name = 'audio2hoa.m';
    OUT.funcallback.inarg = {fs, mic_coords, cropIR, max_order};
else
    OUT = hoaSignals;
end