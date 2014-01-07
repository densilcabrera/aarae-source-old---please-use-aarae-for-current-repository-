function out = nlinRT_XiangJASA1995(data, fs, startthresh, bpo, b1, b2, b3, doplot)
% This function calculates ISO 3382-1 reverberation time parameters from an
% impulse response following Xiang's nonlinear regression method, as well
% as related ISO 3382 sound energy parameters (C50, D50, etc.). The
% nonlinear model includes an exponential decay together with
% reverse-integrated background noise, allowing the noise to be removed
% from the reverberation time calculation.
%
% REFERENCE: N. Xiang  (1995) ?Evaluation of reverberation times using a
% nonlinear regression approach,? Journal of the Acoustical Society of
% America, 98(4), 2112-2121
%
% Code by Grant Cuthbert & Densil Cabrera
% Version 1.00 (22 October 2013)


%--------------------------------------------------------------------------
% INPUT VARIABLES
%--------------------------------------------------------------------------
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
% bpo = Frequency scale to analyse (bands per octave)
%       (1 = octave bands (default); 3 = 1/3 octave bands)
%
% b1, b2, b3 = User-defined coefficient estimates (beta0, beta1, beta2)
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
        'Bands per octave (1 | 3)','Plot (0 | 1)'};
    dlg_title = 'Settings';
    num_lines = 1;
    def = {'-20','1','1'};
    answer = inputdlg(prompt,dlg_title,num_lines,def);
    if ~isempty(answer)
        startthresh = str2num(answer{1,1});
        bpo = str2num(answer{2,1});
        doplot = str2num(answer{3,1});
    end
    % nonlinear curve fitting seed coefficients
    b1 = 1;
    b2 = -20;
    b3 = 0;
else
    ir = data;
    if nargin < 8, doplot = 1; end
    if nargin < 5,
        % nonlinear curve fitting seed coefficients
        b1 = 1;
        b2 = -20;
        b3 = 0;
    end
    if nargin < 4, bpo = 1; end
    if nargin < 3, startthresh = -20; end
end
maxloopcount = 5; % maximum number of nonlinear fitting attempts


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

% Preallocate
m = zeros(1, chans); % maximum value of the IR
startpoint = zeros(1, chans); % the auto-detected start time of the IR

for dim2 = 1:chans
    m(1,dim2) = max(ir(:,dim2).^2); % maximum value of the IR
    startpoint(1,dim2) = find(ir(:,dim2).^2 >= m(1,dim2)./ ...
        (10^(abs(startthresh)/10)),1,'first'); % Define start point
    
    if startpoint(1,dim2) >1
        ir(1:startpoint(1,dim2)-1,dim2) = 0; % zero data 0:startpoint
        
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


if multibandIR == 0
    
    f_low = fc./10^(0.15*bandwidth); % low cut-off frequency in Hz
    f_hi = fc.*10^(0.15*bandwidth); % high cut-off frequency in Hz
    nyquist = fs/2; % Nyquist frequency
    b = zeros(halforder*2+1,length(fc)); % pre-allocate filter coefficients
    a = b; % pre-allocate filter coefficients
    
    for k = 1:bands % calculate filter coefficients
        [b(:,k), a(:,k)]=butter(halforder, ...
            [f_low(k)/nyquist f_hi(k)/nyquist]);
    end
    
    % preallocate
    iroct = zeros(len,chans,bands);
    early50oct = zeros(length(early50),chans,bands);
    early80oct = zeros(length(early80),chans,bands);
    late50oct = zeros(length(late50),chans,bands);
    late80oct = zeros(length(late80),chans,bands);
    
    % filter IR and Early/Late
    for chan = 1:chans
        for band = 1:bands
            iroct(:,chan,band) = filter(b(:,band),a(:,band), ir(:,chan)); % IR
            early50oct(:,chan,band) = filter(b(:,band),a(:,band), early50(:,chan)); % Early50
            early80oct(:,chan,band) = filter(b(:,band),a(:,band), early80(:,chan)); % Early80
            late50oct(:,chan,band) = filter(b(:,band),a(:,band), late50(:,chan)); % Late50
            late80oct(:,chan,band) = filter(b(:,band),a(:,band), late80(:,chan)); % Late80
        end
    end
    
    %----------------------------------------------------------------------
    % CALCULATE ENERGY PARAMETERS
    %----------------------------------------------------------------------
    
    early50oct = squeeze(sum(early50oct.^2))';
    early80oct = squeeze(sum(early80oct.^2))';
    late50oct = squeeze(sum(late50oct.^2))';
    late80oct = squeeze(sum(late80oct.^2))';
    alloct = squeeze(sum(iroct.^2))';
    
    if chans == 2
        C50_ch1 = 10*log10(early50oct(:,1) ./ late50oct(:,1))'; % C50
        C50_ch2 = 10*log10(early50oct(:,2) ./ late50oct(:,2))';
        C80_ch1 = 10*log10(early80oct(:,1) ./ late80oct(:,1))'; % C80
        C80_ch2 = 10*log10(early80oct(:,2) ./ late80oct(:,2))';
        D50_ch1 = (early50oct(:,1) ./ alloct(:,1))'; % D50
        D50_ch2 = (early50oct(:,2) ./ alloct(:,2))';
        D80_ch1 = (early80oct(:,1) ./ alloct(:,1))'; % D80
        D80_ch2 = (early80oct(:,2) ./ alloct(:,2))';
        
        % time values of IR in seconds
        tstimes_ch1 = (0:(length(iroct(:,1,:))-1))' ./ fs;
        tstimes_ch2 = (0:(length(iroct(:,2,:))-1))' ./ fs;
        
        Ts_ch1 = (squeeze(sum(iroct(:,1,:).^2 .* ...
            repmat(tstimes_ch1,[1,1,bands])))./alloct(:,1,:))'; % Ts
        Ts_ch2 = (squeeze(sum(iroct(:,2,:).^2 .* ...
            repmat(tstimes_ch2,[1,1,bands])))./alloct(:,2,:))';
        
    elseif chans == 1
        C50 = 10*log10(early50oct ./ late50oct); % C50
        C80 = 10*log10(early80oct ./ late80oct); % C80
        D50 = (early50oct ./ alloct); % D50
        D80 = (early80oct ./ alloct); % D80
        
        % time values of IR in seconds
        tstimes = (0:(length(iroct)-1))' ./ fs;
        
        Ts = (squeeze(sum(iroct.^2 .* ...
            repmat(tstimes,[1,chans,bands])))./alloct')'; % Ts
    end
    
end % if multibandIR == 0
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

if multibandIR == 1
    
    % do not output energy parameters if early/late cannot be filtered
    % separately
    
    if chans == 2
        C50_ch1 = [];
        C50_ch2 = [];
        C80_ch1 = [];
        C80_ch2 = [];
        D50_ch1 = [];
        D50_ch2 = [];
        D80_ch1 = [];
        D80_ch2 = [];
        Ts_ch1 = [];
        Ts_ch2 = [];
        
    elseif chans == 1
        C50 = [];
        C80 = [];
        D50 = [];
        D80 = [];
        Ts = [];
    end
    
    iroct = ir;
    
end % if multibandIR == 1



%--------------------------------------------------------------------------
% REVERBERATION TIME (Reverse Integration, Nonlinear Regression)
%--------------------------------------------------------------------------

%***************************************
% Derive the reverse-integrated decay curve(s)

% Reverse integrate squared IR, and express the result in decibels
levdecay = 10*log10(flipdim(cumsum(flipdim(iroct.^2,1)),1));

for dim2 = 1:chans
    for dim3 = 1:bands
        % Adjust so that the IR starts at 0 dB
        levdecay(:,dim2,dim3) = levdecay(:,dim2,dim3) - levdecay(1,dim2,dim3);
    end
end


% preallocate
t = zeros(len, chans, bands);
o = zeros(3, chans, bands);
p = zeros(3, chans, bands);
q = zeros(3, chans, bands);
levdecaymodelEDT = zeros(len, chans, bands);
levdecaymodelT20 = zeros(len, dim2, dim3);
levdecaymodelT30 = zeros(len, dim2, dim3);
edtmodlen = zeros(1, chans, bands);
t20modlen = zeros(1, chans, bands);
t30modlen = zeros(1, chans, bands);

if chans == 2
    EDT_ch1 = zeros(1, 1, bands);
    EDT_ch2 = zeros(1, 1, bands);
    T20_ch1 = zeros(1, 1, bands);
    T20_ch2 = zeros(1, 1, bands);
    T30_ch1 = zeros(1, 1, bands);
    T30_ch2 = zeros(1, 1, bands);
    EDTr2_ch1 = zeros(1, 1, bands);
    T20r2_ch1 = zeros(1, 1, bands);
    T30r2_ch1 = zeros(1, 1, bands);
    EDTr2_ch2 = zeros(1, 1, bands);
    T20r2_ch2 = zeros(1, 1, bands);
    T30r2_ch2 = zeros(1, 1, bands);
    
elseif chans == 1
    EDT = zeros(1, chans, bands);
    T20 = zeros(1, chans, bands);
    T30 = zeros(1, chans, bands);
    EDTr2 = zeros(1, chans, bands);
    T20r2 = zeros(1, chans, bands);
    T30r2 = zeros(1, chans, bands);
end


%--------------------------------------------------------------------------
% EDT Regression
%--------------------------------------------------------------------------

b = [b1;b2;b3]; % arbitrary coefficients (for EDT, T20 and T30)

for dim2 = 1:chans
    for dim3 = 1:bands
        irstart = find(levdecay(:,dim2,dim3) <= 0, 1, 'first'); % 0 dB
        edtend = find(levdecay(:,dim2,dim3) <= -10, 1, 'first'); % -10 dB
        t(:,dim2,dim3) = ((1:length(levdecay(:,dim2,dim3)))-1)./fs;
        
        irlen = (t(end,dim2,dim3)); % finite length of IR (ULI)
        
        x = t((irstart:edtend),dim2,dim3); % discrete time
        
        % vector of response (dependent variable) values
        y = 10.^(levdecay((irstart:edtend),dim2,dim3)./10);
        
        % decay curve model
        modelfun = @(B,x)(B(1).*exp(-abs(B(2)).*x) + B(3).*(irlen-x));
        
        % derive coefficients
        fitted = 0;
        loopcount = 0;
        while ~fitted
            loopcount = loopcount+1;
            [o(:,dim2,dim3),~,j] = nlinfit(x,y,modelfun,b);
            jflag = min(sum(j.^2));
            if jflag > 1e-9 || loopcount == maxloopcount,
                fitted = 1;
            else
                b = [100*rand;100*rand;rand];
                disp('*')
            end
            
        end
        
        % create acoustic parameter-specific model using coefficients
        levdecaymodelEDT(:,dim2,dim3) = ...
            10*log10(o(1,dim2,dim3).*exp(-abs(o(2,dim2,dim3)).*t(:,dim2,dim3)));
        levdecaymodelEDT(:,dim2,dim3) = ...
            levdecaymodelEDT(:,dim2,dim3)-max(levdecaymodelEDT(:,dim2,dim3));
        
        startmodelEDT = ...
            find(levdecaymodelEDT(:,dim2,dim3) <= 0, 1, 'first'); % 0 dB
        endmodelEDT = ...
            find(levdecaymodelEDT(:,dim2,dim3) <= -10, 1, 'first'); % -10 dB
        
        % length of specific model
        edtmodlen(:,dim2,dim3) = length(t(startmodelEDT:endmodelEDT,dim2,dim3));
        
        if chans == 2
            EDT_ch1(1,1,dim3) = 6.*(edtmodlen(1,1,dim3))./fs; % EDT in seconds
            EDT_ch2(1,1,dim3) = 6.*(edtmodlen(1,2,dim3))./fs;
            
            % correlation coefficient, EDT
            EDTr2_ch1(1,1,dim3) = corr(levdecay(irstart:edtend,1,dim3), ...
                (irstart:edtend)' * o(1,1,dim3) + ...
                o(2,1,dim3)).^2; % correlation coefficient, EDT
            EDTr2_ch2(1,1,dim3) = corr(levdecay(irstart:edtend,2,dim3), ...
                (irstart:edtend)' * o(1,2,dim3) + ...
                o(2,2,dim3)).^2; % correlation coefficient, EDT
        end
        
        if chans == 1
            EDT(1,1,dim3) = 6.*(edtmodlen(1,1,dim3))./fs; % EDT in seconds
            
            EDTr2(1,dim2,dim3) = corr(levdecay(irstart:edtend,dim2,dim3), ...
                (irstart:edtend)' * o(1,dim2,dim3) + ...
                o(2,dim2,dim3)).^2; % correlation coefficient, EDT
        end
        
    end % dim3
end % dim2


%--------------------------------------------------------------------------
% T20 Regression
%--------------------------------------------------------------------------

for dim2 = 1:chans
    for dim3 = 1:bands
        tstart = find(levdecay(:,dim2,dim3) <= -5, 1, 'first'); % -5 dB
        t20end = find(levdecay(:,dim2,dim3) <= -25, 1, 'first'); % -25 dB
        
        irlen = (t(end,dim2,dim3)); % finite length of IR (ULI)
        % (previously) L = length(Ldecay((Tstart:T20end),dim2,dim3));
        
        x = t((tstart:t20end),dim2,dim3); % discrete time
        
        % vector of response (dependent variable) values
        y = 10.^(levdecay((tstart:t20end),dim2,dim3)./10);
        
        % decay curve model
        modelfun = @(B,x)(B(1).*exp(-abs(B(2)).*x) + B(3).*(irlen-x));
        
        % derive coefficients
        fitted = 0;
        loopcount = 0;
        while ~fitted
            loopcount = loopcount+1;
            [p(:,dim2,dim3),~,j] = nlinfit(x,y,modelfun,b);
            jflag = min(sum(j.^2));
            if jflag > 1e-9 || loopcount == maxloopcount,
                fitted = 1;
            else
                b = [100*rand;100*rand;rand];
                disp('*')
            end
            
        end
        
        % create acoustic parameter-specific model using coefficients
        levdecaymodelT20(:,dim2,dim3) = ...
            10*log10(p(1,dim2,dim3).*exp(-abs(p(2,dim2,dim3)).*t(:,dim2,dim3)));
        levdecaymodelT20(:,dim2,dim3) = ...
            levdecaymodelT20(:,dim2,dim3)-max(levdecaymodelT20(:,dim2,dim3));
        
        startmodelT20 = ...
            find(levdecaymodelT20(:,dim2,dim3) <= -5, 1, 'first'); % -5 dB
        endmodelT20 = ...
            find(levdecaymodelT20(:,dim2,dim3) <= -25, 1, 'first'); % -25 dB
        t20modlen(:,dim2,dim3) = length(t(startmodelT20:endmodelT20,dim2,dim3));
        
        
        if chans == 2
            T20_ch1(1,1,dim3) = 3.*(t20modlen(1,1,dim3))./fs; % T20 in seconds
            T20_ch2(1,1,dim3) = 3.*(t20modlen(1,2,dim3))./fs;
            
            % correlation coefficient, T20
            T20r2_ch1(1,1,dim3) = corr(levdecay(tstart:t20end,1,dim3), ...
                (tstart:t20end)'*p(1,1,dim3) + p(2,1,dim3)).^2;
            T20r2_ch2(1,1,dim3) = corr(levdecay(tstart:t20end,2,dim3), ...
                (tstart:t20end)'*p(1,2,dim3) + p(2,2,dim3)).^2;
        end
        if chans == 1
            T20(1,1,dim3) = 3.*(t20modlen(1,1,dim3))./fs; % T20 in seconds
            
            T20r2(1,1,dim3) = corr(levdecay(tstart:t20end,1,dim3), ...
                (tstart:t20end)'*p(1,1,dim3) ...
                + p(2,1,dim3)).^2; % correlation coefficient, T20
        end
    end % dim 3
end % dim 2



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% (for plotting)

if doplot == 1
    
    % preallocate
    levdecayend = zeros(1,chans,bands);
    
    for dim2 = 1:chans
        for dim3 = 1:bands
            % time at last sample
            levdecayend(1,dim2,dim3) = length(levdecay(:,dim2,dim3));
            levdecayend(1,dim2,dim3) = levdecayend(1,dim2,dim3)./fs;
        end
    end
    
    if bpo == 1
        c=3;
    elseif bpo == 3
        c=5;
    end
    
    if chans == 1
        figure('Name','Level Decay and Regression Lines')
    end
    
end % if doplot == 1


if bpo == 3
    bandfc = [100,125,160,200,250,315,400,500,630,800,1000,1250,1600, ...
        2000,2500,3150,4000,5000];
elseif bpo == 1
    bandfc = [125,250,500,1000,2000,4000];
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%--------------------------------------------------------------------------
% T30 regression (if chans == 1)
%--------------------------------------------------------------------------

if chans ==1
    
    for dim3 = 1:bands
        
        irstart = find(levdecay(:,1,dim3) <= 0, 1, 'first'); % 0 dB
        tstart = find(levdecay(:,1,dim3) <= -5, 1, 'first'); % -5 dB
        t20end = find(levdecay(:,1,dim3) <= -25, 1, 'first'); % -25 dB
        t30end = find(levdecay(:,1,dim3) <= -35, 1, 'first'); % -35 dB
        
        irlen = (t(end,1,dim3)); % finite length of IR (ULI)
        
        x = t((tstart:t30end),1,dim3); % discrete time
        
        % vector of response (dependent variable) values
        y = 10.^(levdecay((tstart:t30end),1,dim3)./10);
        
        % decay curve model
        modelfun = @(B,x)(B(1).*exp(-abs(B(2)).*x) + B(3).*(irlen-x));
        
        % derive coefficients
        fitted = 0;
        loopcount = 0;
        while ~fitted
            loopcount = loopcount+1;
            [q(:,1,dim3),~,j] = nlinfit(x,y,modelfun,b);
            jflag = min(sum(j.^2));
            if jflag > 1e-9 || loopcount == maxloopcount,
                fitted = 1;
            else
                b = [100*rand;100*rand;rand];
                disp('*')
            end
            
        end
        
        % create acoustic parameter-specific model using coefficients
        levdecaymodelT30(:,1,dim3) = ...
            10*log10(q(1,1,dim3).*exp(-abs(q(2,1,dim3)).*t(:,1,dim3)));
        levdecaymodelT30(:,1,dim3) = ...
            levdecaymodelT30(:,1,dim3)-max(levdecaymodelT30(:,1,dim3));
        
        startmodelT30 = ...
            find(levdecaymodelT30(:,1,dim3) <= -5, 1, 'first'); % -5 dB
        endmodelT30 = ...
            find(levdecaymodelT30(:,1,dim3) <= -35, 1, 'first'); % -35 dB
        
        % length of specific model
        t30modlen(:,1,dim3) = length(t(startmodelT30:endmodelT30,1,dim3));
        
        T30(1,1,dim3) = 2.*(t30modlen(1,1,dim3))./fs; % T30 in seconds
        
        T30r2(1,1,dim3) = corr(levdecay(tstart:t30end,1,dim3), ...
            (tstart:t30end)'*q(1,1,dim3) ...
            + q(2,1,dim3)).^2; % correlation coefficient, T30
        
        %------------------------------------------------------------------
        % Plotting (if chans == 1)
        %------------------------------------------------------------------
        
        if doplot == 1
            
            if bpo == 1
                subplot(2,3,dim3)
            elseif bpo == 3
                subplot(4,5,dim3)
            end
            
            hold on
            
            plot(t(:,1,dim3),levdecay(:,1,dim3),'Color',[0.5 0.5 0.5], ...
                'LineWidth',0.5,'DisplayName','Level Decay')
            
            plot(t(irstart:edtend,1,dim3),10*log10((o(1,1,dim3).* ...
                exp(-abs(o(2,1,dim3)).*t(irstart:edtend,1,dim3)) + ...
                (o(3,1,dim3).*(t(end,1,dim3)-t(irstart:edtend,1,dim3))))), ...
                'Color',[0.7 0 0],'DisplayName', 'EDT')
            
            plot(t(irstart:edtend,1,dim3), 10*log10(o(1,1,dim3).* ...
                exp(-abs(o(2,1,dim3)).*t(irstart:edtend,1,dim3))),...
                'LineStyle',':','Color',[0.7 0 0],'DisplayName', 'EDT no B3')
            
            plot(t(tstart:t20end,1,dim3),10*log10((p(1,1,dim3).* ...
                exp(-abs(p(2,1,dim3)).*t(tstart:t20end,1,dim3)) + ...
                (p(3,1,dim3).*(t(end,1,dim3)-t(tstart:t20end,1,dim3))))), ...
                'Color',[0 0.7 0],'DisplayName', 'T20')
            
            plot(t(tstart:t20end,1,dim3), 10*log10(p(1,1,dim3).* ...
                exp(-abs(p(2,1,dim3)).*t(tstart:t20end,1,dim3))),...
                'LineStyle',':','Color',[0 0.7 0],'DisplayName', 'T20 no B3')
            
            plot(t(tstart:t30end,1,dim3),10*log10((q(1,1,dim3).* ...
                exp(-abs(q(2,1,dim3)).*t(tstart:t30end,1,dim3)) + ...
                (q(3,1,dim3).*(t(end,1,dim3)-t(tstart:t30end,1,dim3))))), ...
                'Color',[0 0 0.7],'DisplayName', 'T30')
            
            plot(t(tstart:t30end,1,dim3), 10*log10(q(1,1,dim3).* ...
                exp(-abs(q(2,1,dim3)).*t(tstart:t30end,1,dim3))),...
                'LineStyle',':','Color',[0 0 0.7],'DisplayName', 'T30 no B3')
            
            % x axis label (only on the bottom row of subplots)
            if bpo == 1
                if dim3 > c
                    xlabel('Time (s)')
                end
            elseif bpo == 3
                if dim3 > 15
                    xlabel('Time (s)')
                end
            end
            
            % y axis label (only on the left column of subplots)
            if mod(dim3-1, c) == 0
                ylabel('Level (dB)')
            end
            
            xlim([0 t(end,1,dim3)])
            ylim([-65 0])
            
            title([num2str(bandfc(dim3)),' Hz'])
            
        end % if doplot == 1
        
    end % for dim3 = 1:bands
    
    if doplot == 1
        
        if bpo == 1
            legend('Level Decay','EDT','EDT no B3','T20','T20 no B3', ...
                'T30','T30 no B3','Location','SouthEastOutside')
        elseif bpo == 3
            legend('Level Decay','EDT','EDT no B3','T20','T20 no B3', ...
                'T30','T30 no B3','Location','EastOutside')
        end
        
        hold off
        
    end % if doplot == 1
    
    if bpo == 1
        % percentage difference T20 to T30
        T20T30r = (T20./T30)*100;
        
        % Average T30 of 500 Hz and 1 kHz octave bands
        T30mid = mean([T30(:,:,3) T30(:,:,4)]);
    end
    
end % if chans == 1


%--------------------------------------------------------------------------
% T30 Regression - Channel 1 (if chans == 2)
%--------------------------------------------------------------------------

if chans == 2
    
    if doplot == 1
        figure('Name','Level Decay and Regression Lines (Channel 1)')
    end
    
    for dim3 = 1:bands
        
        irstart = find(levdecay(:,1,dim3) <= 0, 1, 'first'); % 0 dB
        tstart = find(levdecay(:,1,dim3) <= -5, 1, 'first'); % -5 dB
        t20end = find(levdecay(:,1,dim3) <= -25, 1, 'first'); % -25 dB
        t30end = find(levdecay(:,1,dim3) <= -35, 1, 'first'); % -35 dB
        t60end = find(levdecay(:,1,dim3) <= -65, 1, 'first'); % -65 dB
        
        irlen = (t(end,1,dim3)); % finite length of IR (ULI)
        
        x = t((tstart:t30end),1,dim3); % discrete time
        
        % vector of response (dependent variable) values
        y = 10.^(levdecay((tstart:t30end),1,dim3)./10);
        
        % decay curve model
        modelfun = @(B,x)(B(1).*exp(-abs(B(2)).*x) + B(3).*(irlen-x));
        
        % derive coefficients
        fitted = 0;
        loopcount = 0;
        while ~fitted
            loopcount = loopcount+1;
            [q(:,1,dim3),~,j] = nlinfit(x,y,modelfun,b);
            jflag = min(sum(j.^2));
            if jflag > 1e-9 || loopcount == maxloopcount,
                fitted = 1;
            else
                b = [100*rand;100*rand;rand];
                disp('*')
            end
            
        end
        
        % create acoustic parameter-specific model using coefficients
        levdecaymodelT30(:,1,dim3) = ...
            10*log10(q(1,1,dim3).*exp(-abs(q(2,1,dim3)).*t(:,1,dim3)));
        levdecaymodelT30(:,1,dim3) = ...
            levdecaymodelT30(:,1,dim3)-max(levdecaymodelT30(:,1,dim3));
        
        startmodelT30 = ...
            find(levdecaymodelT30(:,1,dim3) <= -5, 1, 'first'); % -5 dB
        endmodelT30 = ...
            find(levdecaymodelT30(:,1,dim3) <= -35, 1, 'first'); % -35 dB
        
        % length of specific model
        t30modlen(:,1,dim3) = length(t(startmodelT30:endmodelT30,1,dim3));
        
        T30_ch1(1,1,dim3) = 2.*(t30modlen(1,1,dim3))./fs; % T30 in seconds
        
        % correlation coefficient, T30
        T30r2_ch1(1,1,dim3) = corr(levdecay(tstart:t30end,1,1), ...
            (tstart:t30end)'*q(1,1,dim3) + q(2,1,dim3)).^2;
        
        %------------------------------------------------------------------
        % PLOTTING - Channel 1 (if chans == 2)
        %------------------------------------------------------------------
        
        if doplot == 1
            
            if bpo == 1
                subplot(2,3,dim3)
            elseif bpo == 3
                subplot(4,5,dim3)
            end
            
            hold on
            
            plot(t(:,1,dim3),levdecay(:,1,dim3),'Color',[0.5 0.5 0.5], ...
                'LineWidth',0.5,'DisplayName','Level Decay')
            
            plot(t(irstart:edtend,1,dim3),10*log10((o(1,1,dim3).* ...
                exp(-abs(o(2,1,dim3)).*t(irstart:edtend,1,dim3)) + ...
                (o(3,1,dim3).*(t(end,1,dim3)-t(irstart:edtend,1,dim3))))), ...
                'Color',[0.7 0 0],'DisplayName', 'EDT')
            
            plot(t(irstart:edtend,1,dim3), 10*log10(o(1,1,dim3).* ...
                exp(-abs(o(2,1,dim3)).*t(irstart:edtend,1,dim3))),...
                'LineStyle',':','Color',[0.7 0 0],'DisplayName', 'EDT no B3')
            
            plot(t(tstart:t20end,1,dim3),10*log10((p(1,1,dim3).* ...
                exp(-abs(p(2,1,dim3)).*t(tstart:t20end,1,dim3)) + ...
                (p(3,1,dim3).*(t(end,1,dim3)-t(tstart:t20end,1,dim3))))), ...
                'Color',[0 0.7 0],'DisplayName', 'T20')
            
            plot(t(tstart:t20end,1,dim3), 10*log10(p(1,1,dim3).* ...
                exp(-abs(p(2,1,dim3)).*t(tstart:t20end,1,dim3))),...
                'LineStyle',':','Color',[0 0.7 0],'DisplayName', 'T20 no B3')
            
            plot(t(tstart:t30end,1,dim3),10*log10((q(1,1,dim3).* ...
                exp(-abs(q(2,1,dim3)).*t(tstart:t30end,1,dim3)) + ...
                (q(3,1,dim3).*(t(end,1,dim3)-t(tstart:t30end,1,dim3))))), ...
                'Color',[0 0 0.7],'DisplayName', 'T30')
            
            plot(t(tstart:t30end,1,dim3), 10*log10(q(1,1,dim3).* ...
                exp(-abs(q(2,1,dim3)).*t(tstart:t30end,1,dim3))),...
                'LineStyle',':','Color',[0 0 0.7],'DisplayName', 'T30 no B3')
            
            % x axis label (only on the bottom row of subplots)
            if bpo == 1
                if dim3 > c
                    xlabel('Time (s)')
                end
            elseif bpo == 3
                if dim3 > 15
                    xlabel('Time (s)')
                end
            end
            
            % y axis label (only on the left column of subplots)
            if mod(dim3-1, c) == 0
                ylabel('Level (dB)')
            end
            
            xlim([0 max(t(t60end,1,dim3))])
            ylim([-65 0])
            
            title([num2str(bandfc(dim3)),' Hz'])
            
        end % if doplot == 1
        
    end % for dim3 = 1:bands
    
    
    if doplot == 1
        
        if bpo == 1
            legend('Level Decay','EDT','EDT no B3','T20','T20 no B3', ...
                'T30','T30 no B3','Location','SouthEastOutside')
        elseif bpo == 3
            legend('Level Decay','EDT','EDT no B3','T20','T20 no B3', ...
                'T30','T30 no B3','Location','EastOutside')
        end
        
        hold off
        
    end
    
    if bpo == 1
        % percentage difference T20 to T30
        T20T30r_ch1 = (T20_ch1./T30_ch1)*100;
        
        % Average T30 of 500 Hz and 1 kHz octave bands
        T30mid_ch1 = mean([T30_ch1(:,1,3) T30_ch1(:,1,4)]);
    end
    
end

%--------------------------------------------------------------------------
% T30 Regression - Channel 2 (if chans == 2)
%--------------------------------------------------------------------------

if chans == 2
    
    if doplot == 1
        figure('Name','Level Decay and Regression Lines (Channel 2)')
    end
    
    for dim3 = 1:bands
        
        irstart = find(levdecay(:,2,dim3) <= 0, 1, 'first'); % 0 dB
        tstart = find(levdecay(:,2,dim3) <= -5, 1, 'first'); % -5 dB
        t20end = find(levdecay(:,2,dim3) <= -25, 1, 'first'); % -25 dB
        t30end = find(levdecay(:,2,dim3) <= -35, 1, 'first'); % -35 dB
        t60end = find(levdecay(:,2,dim3) <= -65, 1, 'first'); % -65 dB
        
        irlen = (t(end,2,dim3)); % finite length of IR (ULI)
        
        x = t((tstart:t30end),2,dim3); % discrete time
        
        % vector of response (dependent variable) values
        y = 10.^(levdecay((tstart:t30end),2,dim3)./10);
        
        % decay curve model
        modelfun = @(B,x)(B(1).*exp(-abs(B(2)).*x) + B(3).*(irlen-x));
        
        % derive coefficients
        fitted = 0;
        loopcount = 0;
        while ~fitted
            loopcount = loopcount+1;
            [q(:,2,dim3),~,j] = nlinfit(x,y,modelfun,b);
            jflag = min(sum(j.^2));
            if jflag > 1e-9 || loopcount == maxloopcount,
                fitted = 1;
            else
                b = [100*rand;100*rand;rand];
                disp('*')
            end
            
        end
        
        % create acoustic parameter-specific model using coefficients
        levdecaymodelT30(:,2,dim3) = ...
            10*log10(q(1,2,dim3).*exp(-abs(q(2,2,dim3)).*t(:,2,dim3)));
        levdecaymodelT30(:,2,dim3) = ...
            levdecaymodelT30(:,2,dim3)-max(levdecaymodelT30(:,2,dim3));
        
        startmodelT30 = ...
            find(levdecaymodelT30(:,2,dim3) <= -5, 1, 'first'); % -5 dB
        endmodelT30 = ...
            find(levdecaymodelT30(:,2,dim3) <= -35, 1, 'first'); % -35 dB
        
        % length of specific model
        t30modlen(:,2,dim3) = length(t(startmodelT30:endmodelT30,2,dim3));
        
        T30_ch2(1,1,dim3) = 2.*(t30modlen(1,2,dim3))./fs; % T30 in seconds
        
        % correlation coefficient, T30
        T30r2_ch2(1,1,dim3) = corr(levdecay(tstart:t30end,2,dim3), ...
            (tstart:t30end)'*q(1,2,dim3) + q(2,2,dim3)).^2;
        
        
        %------------------------------------------------------------------
        % Plotting - Channel 2 ( if chans == 2)
        %------------------------------------------------------------------
        
        if doplot == 1
            
            if bpo == 1
                subplot(2,3,dim3)
            elseif bpo == 3
                subplot(4,5,dim3)
            end
            
            hold on
            
            plot(t(:,2,dim3),levdecay(:,2,dim3),'Color',[0.5 0.5 0.5], ...
                'LineWidth',0.5,'DisplayName','Level Decay')
            
            plot(t(irstart:edtend,2,dim3),10*log10((o(1,2,dim3).* ...
                exp(-abs(o(2,2,dim3)).*t(irstart:edtend,2,dim3)) + ...
                (o(3,2,dim3).*(t(end,2,dim3)-t(irstart:edtend,2,dim3))))), ...
                'Color',[0.7 0 0],'DisplayName', 'EDT')
            
            plot(t(irstart:edtend,2,dim3), 10*log10(o(1,2,dim3).* ...
                exp(-abs(o(2,2,dim3)).*t(irstart:edtend,2,dim3))),...
                'LineStyle',':','Color',[0.7 0 0],'DisplayName', 'EDT no B3')
            
            plot(t(tstart:t20end,2,dim3),10*log10((p(1,2,dim3).* ...
                exp(-abs(p(2,2,dim3)).*t(tstart:t20end,2,dim3)) + ...
                (p(3,2,dim3).*(t(end,2,dim3)-t(tstart:t20end,2,dim3))))), ...
                'Color',[0 0.7 0],'DisplayName', 'T20')
            
            plot(t(tstart:t20end,2,dim3), 10*log10(p(1,2,dim3).* ...
                exp(-abs(p(2,2,dim3)).*t(tstart:t20end,2,dim3))),...
                'LineStyle',':','Color',[0 0.7 0],'DisplayName', 'T20 no B3')
            
            plot(t(tstart:t30end,2,dim3),10*log10((q(1,2,dim3).* ...
                exp(-abs(q(2,2,dim3)).*t(tstart:t30end,2,dim3)) + ...
                (q(3,2,dim3).*(t(end,2,dim3)-t(tstart:t30end,2,dim3))))), ...
                'Color',[0 0 0.7],'DisplayName', 'T30')
            
            plot(t(tstart:t30end,2,dim3), 10*log10(q(1,2,dim3).* ...
                exp(-abs(q(2,2,dim3)).*t(tstart:t30end,2,dim3))),...
                'LineStyle',':','Color',[0 0 0.7],'DisplayName', 'T30 no B3')
            
            % x axis label (only on the bottom row of subplots)
            if bpo == 1
                if dim3 > c
                    xlabel('Time (s)')
                end
            elseif bpo == 3
                if dim3 > 15
                    xlabel('Time (s)')
                end
            end
            
            % y axis label (only on the left column of subplots)
            if mod(dim3-1, c) == 0
                ylabel('Level (dB)')
            end
            
            xlim([0 max(t(t60end,1,dim3))])
            ylim([-65 0])
            
            title([num2str(bandfc(dim3)),' Hz'])
            
        end % if doplot == 1
        
    end % for dim3 = 1:bands
    
    if doplot == 1
        
        if bpo == 1
            legend('Level Decay','EDT','EDT no B3','T20','T20 no B3', ...
                'T30','T30 no B3','Location','SouthEastOutside')
        elseif bpo == 3
            legend('Level Decay','EDT','EDT no B3','T20','T20 no B3', ...
                'T30','T30 no B3','Location','EastOutside')
        end
        
        hold off
        
    end % if doplot == 1
    
    if bpo == 1
        % percentage difference T20 to T30
        T20T30r_ch2 = (T20_ch2./T30_ch2)*100;
        
        % Average T30 of 500 Hz and 1 kHz octave bands
        T30mid_ch2 = mean([T30_ch2(:,1,3) T30_ch2(:,1,4)]);
    end
    
end % if chans == 2


%--------------------------------------------------------------------------
% OUTPUT
%--------------------------------------------------------------------------

% Create output structure

out.bandfc = bandfc;

if chans == 2
    out.EDT_ch1 = permute(EDT_ch1,[2,3,1]);
    out.EDT_ch2 = permute(EDT_ch2,[2,3,1]);
    out.T20_ch1 = permute(T20_ch1,[2,3,1]);
    out.T20_ch2 = permute(T20_ch2,[2,3,1]);
    out.T30_ch1 = permute(T30_ch1,[2,3,1]);
    out.T30_ch2 = permute(T30_ch2,[2,3,1]);
    out.C50_ch1 = C50_ch1;
    out.C50_ch2 = C50_ch2;
    out.C80_ch1 = C80_ch1;
    out.C80_ch2 = C80_ch2;
    out.D50_ch1 = D50_ch1;
    out.D50_ch2 = D50_ch2;
    out.D80_ch1 = D80_ch1;
    out.D80_ch2 = D80_ch2;
    out.Ts_ch1 = Ts_ch1;
    out.Ts_ch2 = Ts_ch2;
    out.EDTr2_ch1 = permute(EDTr2_ch1,[2,3,1]);
    out.EDTr2_ch2 = permute(EDTr2_ch2,[2,3,1]);
    out.T20r2_ch1 = permute(T20r2_ch1,[2,3,1]);
    out.T20r2_ch2 = permute(T20r2_ch2,[2,3,1]);
    out.T30r2_ch1 = permute(T30r2_ch1,[2,3,1]);
    out.T30r2_ch2 = permute(T30r2_ch2,[2,3,1]);
    
    if bpo == 1
        out.T20T30r_ch1 = permute(T20T30r_ch1,[2,3,1]);
        out.T20T30r_ch2 = permute(T20T30r_ch2,[2,3,1]);
        out.T30mid_ch1 = permute(T30mid_ch1,[2,3,1]);
        out.T30mid_ch2 = permute(T30mid_ch2,[2,3,1]);
    end
    
end % if chans == 2

if chans == 1
    out.EDT = permute(EDT,[2,3,1]);
    out.T20 = permute(T20,[2,3,1]);
    out.T30 = permute(T30,[2,3,1]);
    out.C50 = C50;
    out.C80 = C80;
    out.D50 = D50;
    out.D80 = D80;
    out.Ts = Ts;
    out.EDTr2 = permute(EDTr2,[2,3,1]);
    out.T20r2 = permute(T20r2,[2,3,1]);
    out.T30r2 = permute(T30r2,[2,3,1]);
    
    if bpo == 1
        out.T20T30r = permute(T20T30r,[2,3,1]);
        out.T30mid = permute(T30mid,[2,3,1]);
    end
    
end % if chans == 1

disp(out)

end % eof


