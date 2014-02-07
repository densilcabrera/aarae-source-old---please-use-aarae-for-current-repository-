function out = linRT(data, fs, startthresh, bpo, doplot,filterstrength,phasemode,noisecomp,autotrunc)
% This function calculates reverberation time and related ISO 3382
% sound energy parameters (C50, D50, etc.) from an impulse response in
% a linear least squares sense.
%
% Code by Grant Cuthbert & Densil Cabrera
% Version 1.02 (7 February 2014)
%
%--------------------------------------------------------------------------
% INPUT VARIABLES
%--------------------------------------------------------------------------
%
% data = impulse response
%
% fs = Sampling frequency
%
% startthresh = Defines beginning of the IR as the first startthresh sample
%               as the maximum value in the IR (e.g if startthresh = -20,
%               the new IR start is the first sample that is >= 20 dB below
%               the maximum
%
% bpo = frequency scale to analyse (bands per octave)
%       (1 = octave bands (default); 3 = 1/3 octave bands)
%
% doplot = Output plots (1 = yes; 0 = no)
%
%--------------------------------------------------------------------------
% OUTPUT VARIABLES
%--------------------------------------------------------------------------
%
% EDT = Decay curve time interval from 0 dB to -10 dB, in seconds,
%       multiplied by 6
% T20 = Decay curve time interval from -5 dB to -25 dB, in seconds,
%       multiplied by 3
% T30 = Decay curve time interval from -5 dB to -35 dB, in seconds,
%       multiplied by 2
%
% EDTr2 = EDT reverse-integrated decay curve to EDT linear regression line
% T20r2 = T20 reverse-integrated decay curve to T20 linear regression line
% T30r2 = T30 reverse-integrated decay curve to T30 linear regression line
% T20T30r = T20 to T30 difference, as a percentage
% T30mid = T30 average of 500 Hz and 1000 Hz octave bands
%
% C50 = Early (<50 ms) to late energy ratio, in decibals
% C80 = Early (<80 ms) to late energy ratio, in decibals
% D50 = Early (<50 ms) to total energy ratio, as a percentage
% D80 = Early (<80 ms) to total energy ratio, as a percentage
% Ts = Time of the centre of gravity of the squared IR, in seconds
%
%--------------------------------------------------------------------------

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2013, Grant Cuthbert and Densil Cabrera
% All rights reserved.
%
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions are
% met:
%
%  * Redistributions of source code must retain the above copyright notice,
%    this list of conditions and the following disclaimer.
%  * Redistributions in binary form must reproduce the above copyright
%    notice, this list of conditions and the following disclaimer in the
%    documentation and/or other materials provided with the distribution.
%  * Neither the name of the University of Sydney nor the names of its
%    contributors may be used to endorse or promote products derived from
%    this software without specific prior written permission.
%
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
% "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
% TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
% PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER
% OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
% EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
% PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
% PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
% LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
% NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
% SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if isstruct(data)
    ir = data.audio;
    fs = data.fs;
    
    % Dialog box for settings
    prompt = {'Threshold for IR start detection', ...
        'Bands per octave (1 | 3)', ...
        'Filter strength', ...
        'Zero phase (0), Maximum phase (-1) or Minimum phase (1) filters',...
        'Noise compensation: None (0), Chu (1)', ...
        'Automatic truncation: No (0), NOT IMPLEMENTED YET',...
        'Plot (0|1)'};
    dlg_title = 'Settings';
    num_lines = 1;
    def = {'-20','1','1','0','0','0','1'};
    answer = inputdlg(prompt,dlg_title,num_lines,def);
    
    if ~isempty(answer)
        startthresh = str2num(answer{1,1});
        bpo = str2num(answer{2,1});
        filterstrength = str2num(answer{3,1});
        phasemode = str2num(answer{4,1});
        noisecomp = str2num(answer{5,1});
        autotrunc = str2num(answer{6,1});
        doplot = str2num(answer{7,1});
    end
    
else
    
    ir = data;
    if nargin < 9, autotrunc = 0; end
    if nargin < 8, noisecomp = 0; end
    if nargin < 7, phasemode = 0; end
    if nargin < 6, filterstrength = 1; end
    if nargin < 5, doplot = 1; end
    if nargin < 4, bpo = 1; end
    if nargin < 3, startthresh = -20; end
    
end

%--------------------------------------------------------------------------
% TRUNCATION
%--------------------------------------------------------------------------

% Check the input data dimensions
s = size(ir); % size of the IR
ndim = length(s); % number of dimensions
switch ndim
    case 1
        len = s(1); % number of samples in IR
        chans = 1; % number of channels
        multibandIR = 0; % single band IR
    case 2
        len = s(1); % number of samples in IR
        chans = s(2); % number of channels
        multibandIR = 0; % single band IR
    case 3
        len = s(1); % number of samples in IR
        chans = s(2); % number of channels
        multibandIR = 1; % multiband IR (do not filter; do not output ...
        % energy parameters
end

% Get last 10 % for Chu noise compensation if set
if noisecomp == 1
    ir_end10 = ir(round(0.9*len):end,:,:);
end

% Preallocate
m = zeros(1, chans); % maximum value of the IR
startpoint = zeros(1, chans); % the auto-detected start time of the IR

for dim2 = 1:chans
    m(1,dim2) = max(ir(:,dim2).^2); % maximum value of the IR
    startpoint(1,dim2) = find(ir(:,dim2).^2 >= m(1,dim2)./ ...
        (10^(abs(startthresh)/10)),1,'first'); % Define start point
    
    if startpoint(1,dim2) >1
        
        % zero the data before the startpoint
        ir(1:startpoint(1,dim2)-1,dim2) = 0;
        
        % rotate the zeros to the end (to keep a constant data length)
        ir(:,dim2) = circshift(ir(:,dim2),-(startpoint(1,dim2)-1));
        
    end % if startpoint
    
end % for dim2

early50 = ir(1:1+floor(fs*0.05),:); % Truncate Early80
early80 = ir(1:1+floor(fs*0.08),:); % Truncate Early80
late50 = ir(ceil(fs*0.05):end,:); % Truncate Late50
late80 = ir(ceil(fs*0.08):end,:); % Truncate Late80

%--------------------------------------------------------------------------
% FILTERING
%--------------------------------------------------------------------------

if bpo == 3
    bandnumber = 20:37; % filter band numbers (1/3 octaves 100 Hz - 5 kHz)
    bandwidth = 1/3;
    halforder = 2; % half of the filter order
else
    bandnumber = 21:3:36; % filter band numbers (octave bands 125 Hz - 4 kHz)
    bandwidth = 1;
    halforder = 3; % half of the filter order
end

fc = 10.^(bandnumber./10); % filter centre frequencies in Hz
bands = length(fc);

% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
if multibandIR == 0
    
    iroct = zeros(len,chans,bands);
    early50oct = zeros(length(early50),chans,bands);
    early80oct = zeros(length(early80),chans,bands);
    late50oct = zeros(length(late50),chans,bands);
    late80oct = zeros(length(late80),chans,bands);
    
    
    % use AARAE's fft-based filters
    fcnom = exact2nom_oct(fc);
    if bpo == 1
        order = [12,12]*filterstrength;
        iroct = octbandfilter_zerominmax_phase(ir,fs,fcnom,order,0,1000,0,phasemode);
        early50oct = octbandfilter_zerominmax_phase(early50,fs,fcnom,order,0,1000,0,phasemode);
        early80oct = octbandfilter_zerominmax_phase(early80,fs,fcnom,order,0,1000,0,phasemode);
        late50oct = octbandfilter_zerominmax_phase(late50,fs,fcnom,order,0,1000,0,phasemode);
        late80oct = octbandfilter_zerominmax_phase(late80,fs,fcnom,order,0,1000,0,phasemode);
        if noisecomp == 1
            ir_end10oct = octbandfilter_zerominmax_phase(ir_end10,fs,fcnom,order,0,1000,0,phasemode);
        end
        
    else
        order = [36,24] * filterstrength;
        iroct = thirdoctbandfilter_linphase(ir,fs,fcnom,order);
        early50oct = thirdoctbandfilter_linphase(early50,fs,fcnom,order);
        early80oct = thirdoctbandfilter_linphase(early80,fs,fcnom,order);
        late50oct = thirdoctbandfilter_linphase(late50,fs,fcnom,order);
        late80oct = thirdoctbandfilter_linphase(late80,fs,fcnom,order);
        if noisecomp == 1
            ir_end10oct = thirdoctbandfilter_zerominmax_phase(ir_end10,fs,fcnom,order,0,1000,0,phasemode);
        end
    end
    
    
    %----------------------------------------------------------------------
    % CALCULATE ENERGY PARAMETERS
    %----------------------------------------------------------------------
    
    early50oct = sum(early50oct.^2);
    early80oct = sum(early80oct.^2);
    late50oct = sum(late50oct.^2);
    late80oct = sum(late80oct.^2);
    alloct = sum(iroct.^2);
    
   
    C50 = 10*log10(early50oct ./ late50oct); % C50
    C80 = 10*log10(early80oct ./ late80oct); % C80
    D50 = (early50oct ./ alloct); % D50
    D80 = (early80oct ./ alloct); % D80
    
    % time values of IR in seconds
    tstimes = (0:(length(iroct)-1))' ./ fs;
    
    Ts = (sum(iroct.^2 .* ...
        repmat(tstimes,[1,chans,bands])))./alloct; % Ts
    %     end
    
    % mean square of last 10%
    if noisecomp == 1
        ir_end10oct = mean(ir_end10oct.^2);
    else
        ir_end10oct = zeros(1,chans,bands);
    end
    
    
end % if multibandIR == 0
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

if multibandIR == 1
    
  
    C50 = [];
    C80 = [];
    D50 = [];
    D80 = [];
    Ts = [];
   
    iroct = ir;
    
end % if multibandIR == 1


%--------------------------------------------------------------------------
% REVERBERATION TIME (Reverse Integration, Linear Regression)
%--------------------------------------------------------------------------

%***************************************
% Derive the reverse-integrated decay curve(s)

% square and correct for background noise (Chu method) if set
iroct2 = iroct.^2 - repmat(ir_end10oct,[len,1,1]);
iroct2(iroct2<0) = 1e-99; % almost zero
% Reverse integrate squared IR, and express the result in decibels
levdecay = 10*log10(flipdim(cumsum(flipdim(iroct2,1)),1));

for dim2 = 1:chans
    for dim3 = 1:bands
        % Adjust so that the IR starts at 0 dB
        levdecay(:,dim2,dim3) = levdecay(:,dim2,dim3) - levdecay(1,dim2,dim3);
    end
end

%***************************************
% Derive decay times, via linear regressions over the appropriate
% evaluation ranges

% preallocate

o = zeros(2, chans, bands);
p = zeros(2, chans, bands);
q = zeros(2, chans, bands);




EDT = zeros(1, chans, bands);
T20 = zeros(1, chans, bands);
T30 = zeros(1, chans, bands);
EDTr2 = zeros(1, chans, bands);
T20r2 = zeros(1, chans, bands);
T30r2 = zeros(1, chans, bands);


for dim2 = 1:chans
    for dim3 = 1:bands
        
        % find the indices for the relevant start and end samples
        irstart = find(levdecay(:,dim2,dim3) <= 0, 1, 'first'); % 0 dB
        tstart = find(levdecay(:,dim2,dim3) <= -5, 1, 'first'); % -5 dB
        edtend = find(levdecay(:,dim2,dim3) <= -10, 1, 'first'); % -10 dB
        t20end = find(levdecay(:,dim2,dim3) <= -25, 1, 'first'); % -25 dB
        t30end = find(levdecay(:,dim2,dim3) <= -35, 1, 'first'); % -35 dB
        
        %******************************************************************
        % linear regression for EDT
        
        o(:,dim2,dim3) = polyfit((irstart:edtend)', ...
            levdecay(irstart:edtend,dim2,dim3),1)';
        
        
        
        EDT(1,dim2,dim3) = 6*((o(2,dim2,dim3)-10)/o(1,dim2,dim3) ...
            -(o(2,dim2,dim3)-0)/o(1,dim2,dim3))/fs; % EDT
        EDTr2(1,dim2,dim3) = corr(levdecay(irstart:edtend,dim2,dim3), ...
            (irstart:edtend)' * o(1,dim2,dim3) + ...
            o(2,dim2,dim3)).^2; % correlation coefficient, EDT
        
        
        %******************************************************************
        % linear regression for T20
        
        p(:,dim2,dim3) = polyfit((tstart:t20end)', ...
            levdecay(tstart:t20end,dim2,dim3),1)';
        
        
        
        T20(1,dim2, dim3) = 3*((p(2,dim2,dim3)-25)/p(1,dim2,dim3) ...
            -(p(2,dim2,dim3)-5)/ ...
            p(1,dim2,dim3))/fs; % reverberation time, T20
        T20r2(1,dim2, dim3) = corr(levdecay(tstart:t20end,dim2,dim3), ...
            (tstart:t20end)'*p(1,dim2,dim3) ...
            + p(2,dim2,dim3)).^2; % correlation coefficient, T20
        
        
        
        %******************************************************************
        % linear regression for T30
        
        q(:,dim2,dim3) = polyfit((tstart:t30end)', ...
            levdecay(tstart:t30end,dim2,dim3),1)'; % linear regression
        
        
        
        T30(1,dim2, dim3) = 2*((q(2,dim2,dim3)-35)/q(1,dim2,dim3) ...
            -(q(2,dim2,dim3)-5)/ ...
            q(1,dim2,dim3))/fs; % reverberation time, T30
        T30r2(1,dim2, dim3) = corr(levdecay(tstart:t30end,dim2,dim3), ...
            (tstart:t30end)'*q(1,dim2,dim3) ...
            + q(2,dim2,dim3)).^2; % correlation coefficient, T30
        
        
        
    end % dim3
end % dim2

%--------------------------------------------------------------------------


if  bpo == 1
    
    % percentage difference T20 to T30
    T20T30r = (T20./T30)*100;
    
    % Average T30 of 500 Hz and 1 kHz octave bands NEED TO FIX THIS SO OTHER FREQ CAN BE USED!
    T30mid = mean([T30(:,:,3) T30(:,:,4)]);
end

if  bpo == 3
    
    T20T30r = [];
    
    T30mid = [];
end


%--------------------------------------------------------------------------
% OUTPUT
%--------------------------------------------------------------------------


if bpo == 3
    bandfc = [100,125,160,200,250,315,400,500,630,800,1000,1250,1600, ...
        2000,2500,3150,4000,5000];
elseif bpo == 1
    bandfc = [125,250,500,1000,2000,4000];
end


% Create output structure

out.bandfc = bandfc;


out.EDT = permute(EDT,[2,3,1]);
out.T20 = permute(T20,[2,3,1]);
out.T30 = permute(T30,[2,3,1]);
out.C50 = permute(C50,[2,3,1]);
out.C80 = permute(C80,[2,3,1]);
out.D50 = permute(D50,[2,3,1]);
out.D80 = permute(D80,[2,3,1]);
out.Ts = permute(Ts,[2,3,1]);
out.EDTr2 = permute(EDTr2,[2,3,1]);
out.T20r2 = permute(T20r2,[2,3,1]);
out.T30r2 = permute(T30r2,[2,3,1]);

if bpo == 1
    out.T20T30ratio = permute(T20T30r,[2,3,1]);
    out.T30mid = permute(T30mid,[2,3,1]);
end



if chans == 1
    disp(out)
else
    disp(['bandfc:' ,num2str(out.bandfc), ' Hz'])
    disp('Early Decay Time (s):')
    disp(out.EDT)
    disp('Reverberation Time T20 (s):')
    disp(out.T20)
    disp('Reverberation Time T30 (s):')
    disp(out.T30)
    disp('Clarity Index C50 (dB):')
    disp(out.C50)
    disp('Clarity Index C80 (dB):')
    disp(out.C80)
    disp('Definition D50:')
    disp(out.D50)
    disp('Definition D80:')
    disp(out.D80)
    disp('Centre Time (s):')
    disp(out.Ts)
    disp('EDT squared correlation coefficient:')
    disp(out.EDTr2)
    disp('T20 squared correlation coefficient:')
    disp(out.T20r2)
    disp('T30 squared correlation coefficient:')
    disp(out.T30r2)
    if bpo ==1
        disp('Ratio of T20 to T30 (%):')
        disp(out.T20T30ratio)
        disp('Mid-frequency T30 (s):')
        disp(out.T30mid)
    end
end

%--------------------------------------------------------------------------
% AARAE TABLE
%--------------------------------------------------------------------------

if isstruct(data)
    for ch = 1:chans
        f = figure('Name','Reverberation Parameters', ...
        'Position',[200 200 620 360]);
        dat1 = [out.EDT(ch,:);out.T20(ch,:);out.T30(ch,:);out.C50(ch,:);...
            out.C80(ch,:);out.D50(ch,:); ...
            out.D80(ch,:);out.Ts(ch,:); ...
            out.EDTr2(ch,:);out.T20r2(ch,:);out.T30r2(ch,:)];
        cnames1 = num2cell(bandfc);
        rnames1 = {'Early decay time (s)',...
            'Reverberation time T20 (s)',...
            'Reverberation time T30 (s)',...
            'Clarity index C50 (dB)',...
            'Clarity index C80 (dB)',...
            'Definition D50',...
            'Definition D80',...
            'Centre time Ts (s)',...
            'Correlation coefficient EDT r^2',...
            'Correlation coefficient T20 r^2',...
            'Correlation coefficient T30 r^2'};
        t1 =uitable('Data',dat1,'ColumnName',cnames1,'RowName',rnames1);
        set(t1,'ColumnWidth',{60});
        
        if bpo == 1
            dat2 = [out.T20T30ratio(ch,:)];
            cnames2 = num2cell(bandfc);
            rnames2 = {'Ratio of T20 to T30 ch1'};
            t2 =uitable('Data',dat2,'ColumnName',cnames2,'RowName',rnames2);
            set(t2,'ColumnWidth',{60});
            disptables(f,[t1 t2]);
        else
            disptables(f,t1);
        end
        
    end
    
    %--------------------------------------------------------------------------
    % PLOTTING
    %--------------------------------------------------------------------------
    
    if doplot
        % Define number of rows and columns (for y axis labelling)
        if bpo == 1
            r=2;
            c=3;
        elseif bpo == 3
            r=4;
            c=5;
        end
        
        % preallocate
        levdecayend = zeros(1,chans, bands);
        
        for dim2 = 1:chans
            for dim3 = 1:bands
                irstart(1,dim2,dim3) = find(levdecay(:,dim2,dim3) <= 0, 1, 'first'); % 0 dB
                tstart(1,dim2,dim3) = find(levdecay(:,dim2,dim3) <= -5, 1, 'first'); % -5 dB
                edtend(1,dim2,dim3) = find(levdecay(:,dim2,dim3) <= -10, 1, 'first'); % -10 dB
                t20end(1,dim2,dim3) = find(levdecay(:,dim2,dim3) <= -25, 1, 'first'); % -25 dB
                t30end(1,dim2,dim3) = find(levdecay(:,dim2,dim3) <= -35, 1, 'first'); % -35 dB
                levdecayend(1,dim2,dim3) = length(levdecay(:,dim2,dim3)); % time at last sample
                levdecayend(1,dim2,dim3) = levdecayend(1,dim2,dim3)./fs;
            end
        end
        
        
        if chans == 1
            
            figure('Name','Level Decay and Regression Lines')
            
            for band = 1:bands
                
                if bpo == 1
                    subplot(2,3,band)
                elseif bpo == 3
                    subplot(4,5,band)
                end
                
                hold on
                
                % plot the level decay(s) on a single subplot
                plot(((1:len)-1)./fs, levdecay(:,1,band),'Color',[0.2 0.2 0.2], ...
                    'LineStyle',':','DisplayName','Level Decay')
                
                % linear regression for EDT
                plot(((irstart(1,1,band):edtend(1,1,band))./fs), ...
                    (irstart(1,1,band):edtend(1,1,band)).* ...
                    o(1,1,band)+o(2,1,band), ...
                    'Color',[0.9 0 0],'DisplayName','EDT')
                
                % linear regression for T20
                plot(((tstart(1,1,band):t20end(1,1,band))./fs), ...
                    (tstart(1,1,band):t20end(1,1,band)).* ...
                    p(1,1,band)+p(2,1,band), ...
                    'Color',[0 0.6 0],'DisplayName','T20')
                
                % linear regression for T30
                plot(((tstart(1,1,band):t30end(1,1,band))./fs), ...
                    (tstart(1,1,band):t30end(1,1,band)).* ...
                    q(1,1,band)+q(2,1,band), ...
                    'Color',[0 0 0.6],'DisplayName', 'T30')
                
                % x axis label (only on the bottom row of subplots)
                if band > (c*r - c)
                    xlabel('Time (s)')
                end
                
                % y axis label (only on the left column of subplots)
                if mod(band-1, c) == 0
                    ylabel('Level (dB)')
                end
                
                xlim([0 levdecayend(1,1,band)])
                ylim([-65 0])
                
                title([num2str(bandfc(band)),' Hz'])
                
            end % for band
            
            
            if bpo == 1
                legend('Level Decay','EDT','T20','T30', 'Location', ...
                    'EastOutside')
            elseif bpo == 3
                legend('Level Decay','EDT','T20','T30', 'Location', ...
                    'EastOutside')
            end
            
            hold off
            
            
            %----------------------------------------------------------------------
        elseif chans == 2
            
            figure('Name','Channel 1 - Level Decay and Regression Lines')
            
            for band = 1:bands
                
                if bpo == 1
                    subplot(2,3,band)
                elseif bpo == 3
                    subplot(4,5,band)
                end
                
                hold on
                
                % plot the level decay(s) on a single subplot
                plot(((1:len)-1)./fs, levdecay(:,1,band),'Color',[0.2 0.2 0.2], ...
                    'LineStyle',':','DisplayName','Level Decay')
                
                % linear regression for EDT
                plot(((irstart(1,1,band):edtend(1,1,band))./fs), ...
                    (irstart(1,1,band):edtend(1,1,band)).* ...
                    o(1,1,band)+o(2,1,band), ...
                    'Color',[0.9 0 0],'DisplayName','EDT')
                
                % linear regression for T20
                plot(((tstart(1,1,band):t20end(1,1,band))./fs), ...
                    (tstart(1,1,band):t20end(1,1,band)).* ...
                    p(1,1,band)+p(2,1,band), ...
                    'Color',[0 0.6 0],'DisplayName','T20')
                
                % linear regression for T30
                plot(((tstart(1,1,band):t30end(1,1,band))./fs), ...
                    (tstart(1,1,band):t30end(1,1,band)).* ...
                    q(1,1,band)+q(2,1,band), ...
                    'Color',[0 0 0.6],'DisplayName', 'T30')
                
                % x axis label (only on the bottom row of subplots)
                if band > (c*r - c)
                    xlabel('Time (s)')
                end
                
                % y axis label (only on the left column of subplots)
                if mod(band-1, c) == 0
                    ylabel('Level (dB)')
                end
                
                xlim([0 levdecayend(1,1,band)])
                ylim([-65 0])
                
                title([num2str(bandfc(band)),' Hz'])
                
            end % for band
            
            if bpo == 1
                legend('Level Decay','EDT','T20','T30', 'Location', ...
                    'SouthEastOutside')
            elseif bpo == 3
                legend('Level Decay','EDT','T20','T30', 'Location', ...
                    'EastOutside')
            end
            
            hold off
            
            
            figure('Name','Channel 2 - Level Decay and Regression Lines')
            
            for band = 1:bands
                
                if bpo == 1
                    subplot(2,3,band)
                elseif bpo == 3
                    subplot(4,5,band)
                end
                
                hold on
                
                % plot the level decay(s) on a single subplot
                plot(((1:len)-1)./fs, levdecay(:,2,band),'Color',[0.2 0.2 0.2], ...
                    'LineStyle',':','DisplayName','Level Decay')
                
                % linear regression for EDT
                plot(((irstart(1,2,band):edtend(1,2,band))./fs), ...
                    (irstart(1,2,band):edtend(1,2,band)).* ...
                    o(1,2,band)+o(2,2,band), ...
                    'Color',[0.9 0 0],'DisplayName','EDT')
                
                % linear regression for T20
                plot(((tstart(1,2,band):t20end(1,2,band))./fs), ...
                    (tstart(1,2,band):t20end(1,2,band)).* ...
                    p(1,2,band)+p(2,2,band), ...
                    'Color',[0 0.6 0],'DisplayName','T20')
                
                % linear regression for T30
                plot(((tstart(1,2,band):t30end(1,2,band))./fs), ...
                    (tstart(1,2,band):t30end(1,2,band)).* ...
                    q(1,2,band)+q(2,2,band), ...
                    'Color',[0 0 0.6],'DisplayName', 'T30')
                
                % x axis label (only on the bottom row of subplots)
                if band > (c*r - c)
                    xlabel('Time (s)')
                end
                
                % y axis label (only on the left column of subplots)
                if mod(band-1, c) == 0
                    ylabel('Level (dB)')
                end
                
                xlim([0 levdecayend(1,2,band)])
                ylim([-65 0])
                
                title([num2str(bandfc(band)),' Hz'])
                
            end % for band
            
            if bpo == 1
                legend('Level Decay','EDT','T20','T30', 'Location', ...
                    'SouthEastOutside')
            elseif bpo == 3
                legend('Level Decay','EDT','T20','T30', 'Location', ...
                    'EastOutside')
            end
            
            hold off
            
        end % if chans == 1 / elseif chans == 2
        
    end % if doplot
    
end % eof

