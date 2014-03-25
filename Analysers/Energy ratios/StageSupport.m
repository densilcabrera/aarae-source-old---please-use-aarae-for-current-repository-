function out = StageSupport(data, fs, startthresh, bpo)
% This function calculates stage support parameters from a room impulse 
% response.
%--------------------------------------------------------------------------
% INPUT VARIABLES
%
% IR = .wav impulse response
%
% fs = Sampling frequency
%
% startthresh = Defines beginning of the IR as the first startthresh sample
%               as the maximum value in the IR (e.g if startthresh = -20,
%               the new IR start is the first sample that is >= 20 dB below
%               the maximum
%
% bpo = frequency scale to analyse
%             (1 = octave bands (default); 3 = 1/3 octave bands)
%
% doplot = Output plots (1 = yes; 0 = no)
%

if nargin < 5, doplot = 1; end
if nargin < 4, bpo = 1; end
if nargin < 3
    startthresh = -20;
    %dialog box for settings
    prompt = {'Threshold for IR start detection', ...
        'Bands per octave (1 | 3)', ...
        'Plot (0|1)'};
    dlg_title = 'Settings';
    num_lines = 1;
    def = {'-20','1','1'};
    answer = inputdlg(prompt,dlg_title,num_lines,def);
    
    if ~isempty(answer)
        startthresh = str2num(answer{1,1});
        bpo = str2num(answer{2,1});
        doplot = str2num(answer{3,1});
    end
end
if isstruct(data)
    IR = data.audio;
    fs = data.fs;
else
    IR = data;
    if nargin < 2
        fs = inputdlg({'Sampling frequency [samples/s]'},...
                           'Fs',1,{'48000'});
        fs = str2num(char(fs));
    end
end

if ~isempty(IR) && ~isempty(fs) && ~isempty(startthresh) && ~isempty(bpo)
    %--------------------------------------------------------------------------
    % TRUNCATION
    %--------------------------------------------------------------------------

    % Check the input data dimensions
    [len, chans, bands] = size(IR);
    if bands>1
        warning('The StageSupport function is not suitable for multiband audio.')
        disp('Multiband audio has been mixed down, but results should be interpreted with caution.')
        IR = mean(IR,3);
    end

    if chans > 2
        IR = IR(:,1:2);
        warning('Only the first two channels are analysed')
        chans = 2;
    end

    if len/fs < 1
        warning('The impulse response is not sufficiently long for STLate.')
        disp('Zero padding has been applied, but results should be interpreted with caution.')
        IR = [IR; zeros(round(fs),chans)];
    end

    % Preallocate
    m = zeros(1, chans); % maximum value of the IR
    startpoint = zeros(1, chans); % the auto-detected start time of the IR

    for dim2 = 1:chans
        m(1,dim2) = max(IR(:,dim2).^2); % maximum value of the IR
        startpoint(1,dim2) = find(IR(:,dim2).^2 >= m(1,dim2)./ ...
            (10^(abs(startthresh)/10)),1,'first'); % Define start point

        if startpoint(1,dim2) > 1
            % zero the data before the startpoint
            IR(1:startpoint(1,dim2)-1,dim2) = 0;

            % rotate the zeros to the end (to keep a constant data length)
            IR(:,dim2) = circshift(IR(:,dim2),-(startpoint(1,dim2)-1));
        end
    end

    % Truncate sections of the IR prior to filtering
    Direct10 = IR(1:1+floor(fs*0.01),:); % Truncate first 10 ms
    Early20_100 = IR(1+floor(fs*0.02):1+floor(fs*0.1),:); % 20-100 ms
    Late100_200 = IR(1+floor(fs*0.1):1+floor(fs*0.2),:); % 100-200 ms
    All20_1000 = IR(1+floor(fs*0.02):1+floor(fs*1),:); % 20-1000 ms
    Late100_1000 = IR(1+floor(fs*0.1):1+floor(fs*1),:); % 100-1000 ms


    %--------------------------------------------------------------------------
    % FILTERING
    %--------------------------------------------------------------------------

    % Use inbuilt AARAE filterbank
    if bpo == 3
        bandfc = [100,125,160,200,250,315,400,500,630,800,1000,1250,1600, ...
            2000,2500,3150,4000,5000];
        All_IR = thirdoctbandfilter(IR,fs,bandfc); % IR
        Direct10 = thirdoctbandfilter(Direct10,fs,bandfc); 
        Early20_100 = thirdoctbandfilter(Early20_100,fs,bandfc);
        Late100_200 = thirdoctbandfilter(Late100_200,fs,bandfc);
        All20_1000 = thirdoctbandfilter(All20_1000,fs,bandfc);
        Late100_1000 = thirdoctbandfilter(Late100_1000,fs,bandfc);

    else
        bandfc = [125,250,500,1000,2000,4000];
        All_IR = octbandfilter(IR,fs,bandfc); % IR
        Direct10 = octbandfilter(Direct10,fs,bandfc); 
        Early20_100 = octbandfilter(Early20_100,fs,bandfc);
        Late100_200 = octbandfilter(Late100_200,fs,bandfc);
        All20_1000 = octbandfilter(All20_1000,fs,bandfc);
        Late100_1000 = octbandfilter(Late100_1000,fs,bandfc);

    end

    %--------------------------------------------------------------------------
    % CALCULATE ENERGY PARAMETERS
    %--------------------------------------------------------------------------


    Direct10 = permute(sum(Direct10.^2),[3,2,1]);
    Early20_100 = permute(sum(Early20_100.^2),[3,2,1]);
    Late100_200 = permute(sum(Late100_200.^2),[3,2,1]);
    Late100_1000 = permute(sum(Late100_1000.^2),[3,2,1]);

    ST1 = 10*log10(Early20_100 ./ Direct10); 
    ST2 = 10*log10(Late100_200 ./ Direct10); % C80
    STLate = (Late100_1000 ./ Direct10); % D50

    meanbands = find(bandfc>=200 & bandfc<=2500);
    ST1av = mean(ST1(meanbands,:),1);
    ST2av = mean(ST2(meanbands,:),1);
    STLateav = mean(STLate(meanbands,:),1);


    %--------------------------------------------------------------------------
    % OUTPUT STRUCTURE
    %--------------------------------------------------------------------------

    if chans == 1
        out.ST1 = [bandfc;ST1'];
        out.ST2 = [bandfc;ST2'];
        out.STLate = [bandfc;STLate'];
        out.funcallback.name = 'StageSupport.m';
        out.funcallback.inarg = {fs,startthresh,bpo};

    else %chans == 2
        out.ST1_ch1 = [bandfc;ST1(:,1)'];
        out.ST1_ch2 = [bandfc;ST1(:,2)'];

        out.ST2_ch1 = [bandfc;ST2(:,1)'];
        out.ST2_ch2 = [bandfc;ST2(:,2)'];

        out.STLate_ch1 = [bandfc;STLate(:,1)'];
        out.STLate_ch2 = [bandfc;STLate(:,2)'];

        out.funcallback.name = 'StageSupport.m';
        out.funcallback.inarg = {fs,startthresh,bpo};
    end % if chans


    % OUTPUT TABLE

    if doplot
        for ch = 1:chans
        f = figure('Name',['Stage Support, channel: ', num2str(ch)], ...
                    'Position',[200 200 620 360]);
                %[left bottom width height]
                dat1 = [ST1(:,ch)';ST2(:,ch)';STLate(:,ch)'];
                cnames1 = num2cell(bandfc);
                rnames1 = {'ST1 or ST Early (dB)', 'ST2 (dB)', 'ST Late (dB)'};
                t1 =uitable('Data',dat1,'ColumnName',cnames1,'RowName',rnames1);
                set(t1,'ColumnWidth',{60});

                dat2 = [ST1av(:,ch)';ST2av(:,ch)';STLateav(:,ch)'];
                cnames2 = {'Spectral Average (250 Hz - 2kHz Octave Bands)'};
                rnames2 = {'ST1 or ST Early (dB)','ST2 (dB)', ...
                    'ST Late (dB)'};
                t2 =uitable('Data',dat2,'ColumnName',cnames2,'RowName',rnames2);

                disptables(f,[t2 t1]);
        end
    end
else
    out = [];
end
% eof

