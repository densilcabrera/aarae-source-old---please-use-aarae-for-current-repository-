function OUT = ReverbTime_InterruptedNoise(IN,fs,filteriterations,avmethod,lowestband,highestband,bpo,threshold)
% This function is designed to be used with signals generated from AARAE's
% interrupted noise generator, for the measurement of reverberation time
% and related parameters.
%
% The interrupted noise generator creates an additional field to be used
% in the analysis: 'audio3' is used to identify the decay periods. 
%
% A smoothing filter is required to smooth the decay envelopes, and the
% number of filter iterations can be set (this is half the filter's order).
% If the decay envelopes are not sufficiently smoothed, this can result in
% an error (try a larger number of filter iterations). However, in the case
% of short reverberation times, the smoothing filter might artificially
% increase the calculated reverberation parameters.
%
% Code by Densil Cabrera & Grant Cuthbert
% version 1.00 (17 December 2013)
if nargin < 8, threshold = 0.2; end
if nargin < 7, bpo = 1; end
if nargin < 6, highestband = 8000; end
if nargin < 5, lowestband = 125; end
if nargin < 4, avmethod = 1; end
if nargin < 3, 
    %filteriterations = 2; 
    param = inputdlg({'Bands per octave (1 | 3)';...
        'Highest centre frequency (Hz)';...
        'Lowest centre frequency (Hz)';...
        'Averaging method: p^2 (1), RT (2)';...
        'Number of iterations of the smoothing filter';...
        'Burst start detection threshold (relative to RMS)'},...
        'Settings',...
        [1 30],...
        {'1';'8000';'125';'1';'2';'0.2'}); % Defaults
    
    param = str2num(char(param));
    if length(param) < 6, param = []; end
    if ~isempty(param)
        bpo = param(1);
        highestband = param(2);
        lowestband = param(3);
        avmethod = param(4);
        filteriterations = param(5);
        threshold = param(6);
    else
        OUT = [];
        return
    end
else
    param = [];
end

if isstruct(IN)
    IN = choose_from_higher_dimensions(IN,3,1); 
    audio = IN.audio; % Extract the audio data
    fs = IN.fs;       % Extract the sampling frequency of the audio data
%     if isfield(IN,'audio3')
%         audio3 = IN.audio3;
%     end
    if isfield(IN.properties,'burstindices')   
        burstindices = IN.properties.burstindices;
    end
    if isfield(IN,'bandID')
        flist = IN.bandID;
    end
    if isfield(IN,'chanID')
        chanID = IN.chanID;
    else
        chanID = cellstr([repmat('Chan',size(IN.audio,2),1) num2str((1:size(IN.audio,2))')]);
    end
elseif ~isempty(param) || nargin > 1
    audio = IN;
    % this probably won't work!
end


if ~isempty(audio) && ~isempty(fs) && ~isempty(filteriterations) && ~isempty(avmethod) && ~isempty(lowestband) && ~isempty(highestband) && ~isempty(bpo)
    [~, chans, bands] = size(audio);
    
    % -------------------------------------------------------------------------
    % Use burstindices to break up audio into decays & check latence &
    % length
    % -------------------------------------------------------------------------
    
    if exist('burstindices','var')
        % find indices for starts and ends of decay periods
        decaystart = burstindices(:,2)+1;
        decayend = burstindices(:,3);
        numberofdecays = length(burstindices);
    else
        OUT.error = 'burstindices not found!';
        warndlg('Please use test signals generated from AARAE''s interrupted noise generator','AARAE info')
        return
        % or work out some other way of finding decay period indices!!!
    end
    
    audiorms = mean(audio.^2).^0.5;
    % this is the simplest approach to latency checking - other approaches
    % might be more robust
    burststartinex = find(abs(audio)>=audiorms*threshold,1,'first');
    audio = audio(burststartinex:end,:,:); % remove audio before start of first burst
    if size(audio,1)< decayend(end)
        disp('Audio seems to be too short for an analysis of the final decay')
        if numberofdecays == 1
            OUT = [];
            return
        end
        decaystart = decaystart(1:end-1);
        decayend = decayend(1:end-1);
        numberofdecays = numberofdecays(1:end-1);
    end
    
    decayend = decayend - round((decayend-decaystart)*0.1); % 10% safety margin
    
    % -------------------------------------------------------------------------
    % Process decays
    % -------------------------------------------------------------------------
    
    % Determine frequencies of filters
    if bands == 1
        hiband = round(10*log10(highestband));
        if hiband > 42, hiband = 42; end
        loband = round(10*log10(lowestband));
        if loband <15, loband = 15; end
        if hiband > loband
            if bpo == 3
                flist = 10.^((loband:hiband)./10);
            else
                flist = 10.^((loband:3:hiband)./10);
            end
        else
            flist = 10.^(hiband./10);
        end
        % convert exact frequencies to nominal
        flist = exact2nom_oct(flist);
    else
        if ~exist('flist', 'var')
            flist = 1:bands;
        end
    end
    
    
    
    
    decay = zeros(1+decayend(1)-decaystart(1), chans, length(flist), numberofdecays);
    for d = 1:numberofdecays
        % Filter and square each decay
        if bands == 1
            if bpo == 3
                % 1/3-octave band filterbank
                decay(:,:,:,d) = thirdoctbandfilter(audio(decaystart(d):decayend(d),:),fs,flist);
            else
                % octave band filterbank
                decay(:,:,:,d) = octbandfilter(audio(decaystart(d):decayend(d),:),fs,flist);
            end
        else
            % no need to filter for multiband audio input
            decay(:,:,:,d) = audio(decaystart(d):decayend(d),:,:);
        end
    end
    
    % mix the decays and square
    if avmethod == 0
        % sum pressures (not recommended - included only to demonstrate the point)
        decaymix = sum(decay,4).^2;
    else
        % sum squared pressures (recommended)
        decaymix = sum(decay.^2,4);
    end
    
    decay = decay.^2;
    
    
    
    % -------------------------------------------------------------------------
    % Smooth the decay functions, convert to decibels and normalize
    % -------------------------------------------------------------------------
    
    if (flist(end) ~= length(flist)) && exist('filterperiods','var')
        for bnd = 1:length(flist)
            % lowpass filter the squared decay functions, using a smoothing
            % filter inversely proportional in length to each band's centre
            % frequency
            cutoff = flist(bnd)/10; % lo-pass filter cutoff frequency in Hz
            Wn = cutoff/(fs*0.5); % normalized cutoff frequency of lo-pass filter
            order = 1; % filter order 
            [b,a] = butter(order,Wn,'low');
            
            for d = 1:numberofdecays
                for ff = 1:filteriterations
                    decay(:,:,bnd,d) = filtfilt(b,a,decay(:,:,bnd,d));
                end
            end
            for ff = 1:filteriterations
                decaymix(:,:,bnd) = filtfilt(b,a,decay(:,:,bnd));
            end
        end
    else
        % in this case we do not know the filter frequencies, and so the
        % filter is a cutoff frequency
        cutoff = 50; % lo-pass filter cutoff frequency in Hz
        Wn = cutoff/(fs*0.5); % normalized cutoff frequency of lo-pass filter
        order = 1; % filter order 
        [b,a] = butter(order,Wn,'low');
        for d = 1:numberofdecays
            for ff = 1:filteriterations
                decay(:,:,:,d) = filtfilt(b,a,decay(:,:,:,d));
            end
        end
        for ff = 1:filteriterations
            decaymix = filtfilt(b,a,decaymix);
        end
        
    end
    
    % Get rid of zeros and negatives
    decay(decay<=0) = 1e-999;
    decaymix(decaymix<=0) = 1e-999;
    
    len = size(decaymix,1);
    
    levdecaymix = 10*log10(decaymix);
    levdecaymix = levdecaymix - repmat(max(levdecaymix), [len,1,1]);
    
    % individual decays are also prepared for processing
    levdecay = 10*log10(decay);
    levdecay = levdecay - repmat(max(levdecay), [len,1,1,1]);
    
    clear decay decaymix
    
    
    
    
    % -------------------------------------------------------------------------
    % Calculate reverberation parameters
    % -------------------------------------------------------------------------
    
    % pre-allocate
    bands = length(flist);
    o = zeros(2,chans,bands,numberofdecays);
    EDT = zeros(1,chans,bands,numberofdecays);
    %EDTr2 = zeros(1,chans,bands,numberofdecays);
    
    p = zeros(2,chans,bands,numberofdecays);
    T20 = zeros(1,chans,bands,numberofdecays);
    %T20r2 = zeros(1,chans,bands,numberofdecays);
    
    q = zeros(2,chans,bands,numberofdecays);
    T30 = zeros(1,chans,bands,numberofdecays);
    %T30r2 = zeros(1,chans,bands,numberofdecays);
    
    oo = zeros(2,chans,bands);
    EDTmix = zeros(1,chans,bands);
    EDTr2mix = zeros(1,chans,bands);
    
    pp = zeros(2,chans,bands);
    T20mix = zeros(1,chans,bands);
    T20r2mix = zeros(1,chans,bands);
    
    qq = zeros(2,chans,bands);
    T30mix = zeros(1,chans,bands);
    T30r2mix = zeros(1,chans,bands);
    
    irstart1 = zeros(chans,bands);
    tstart1 = zeros(chans,bands);
    edtend1 = zeros(chans,bands);
    t20end1 = zeros(chans,bands);
    t30end1 = zeros(chans,bands);
    
    for dim2 = 1:chans
        for dim3 = 1:length(flist)
            for dim4 = 1:numberofdecays
                % find the indices for the relevant start and end samples
                irstart = find(levdecay(:,dim2,dim3,dim4) == 0, 1, 'first'); % 0 dB
                tstart = find(levdecay(irstart:end,dim2,dim3,dim4) <= -5, 1, 'first'); % -5 dB
                edtend = find(levdecay(irstart:end,dim2,dim3,dim4) <= -10, 1, 'first'); % -10 dB
                t20end = find(levdecay(irstart:end,dim2,dim3,dim4) <= -25, 1, 'first'); % -25 dB
                t30end = find(levdecay(irstart:end,dim2,dim3,dim4) <= -35, 1, 'first'); % -35 dB
                
                
                %******************************************************************
                % linear regression for EDT
                
                o(:,dim2,dim3,dim4) = polyfit((irstart:edtend)', ...
                    levdecay(irstart:edtend,dim2,dim3,dim4),1)';
                
                EDT(1,dim2,dim3,dim4) = 6*((o(2,dim2,dim3,dim4)-10)/o(1,dim2,dim3,dim4) ...
                    -(o(2,dim2,dim3,dim4)-0)/o(1,dim2,dim3,dim4))/fs; % EDT
                
                %                 EDTr2(1,dim2,dim3,dim4) = corr(levdecay(irstart:edtend,dim2,dim3,dim4), ...
                %                     (irstart:edtend)' * o(1,dim2,dim3,dim4) + ...
                %                     o(2,dim2,dim3,dim4)).^2; % correlation coefficient, EDT
                
                %******************************************************************
                % linear regression for T20
                
                p(:,dim2,dim3,dim4) = polyfit((tstart:t20end)', ...
                    levdecay(tstart:t20end,dim2,dim3,dim4),1)';
                
                T20(1,dim2, dim3,dim4) = 3*((p(2,dim2,dim3,dim4)-25)/p(1,dim2,dim3,dim4) ...
                    -(p(2,dim2,dim3,dim4)-5)/ ...
                    p(1,dim2,dim3,dim4))/fs; % reverberation time, T20
                
                %                 T20r2(1,dim2, dim3,dim4) = corr(levdecay(tstart:t20end,dim2,dim3,dim4), ...
                %                     (tstart:t20end)'*p(1,dim2,dim3,dim4) ...
                %                     + p(2,dim2,dim3,dim4)).^2; % correlation coefficient, T20
                
                %******************************************************************
                % linear regression for T30
                
                q(:,dim2,dim3,dim4) = polyfit((tstart:t30end)', ...
                    levdecay(tstart:t30end,dim2,dim3,dim4),1)'; % linear regression
                
                T30(1,dim2, dim3,dim4) = 2*((q(2,dim2,dim3,dim4)-35)/q(1,dim2,dim3,dim4) ...
                    -(q(2,dim2,dim3,dim4)-5)/ ...
                    q(1,dim2,dim3,dim4))/fs; % reverberation time, T30
                
                %                 T30r2(1,dim2, dim3,dim4) = corr(levdecay(tstart:t30end,dim2,dim3,dim4), ...
                %                     (tstart:t30end)'*q(1,dim2,dim3,dim4) ...
                %                     + q(2,dim2,dim3,dim4)).^2; % correlation coefficient, T30
                
            end
            irstart1(dim2,dim3) = find(levdecay(:,dim2,dim3) == 0, 1, 'first'); % 0 dB
            tstart1(dim2,dim3) = find(levdecaymix(irstart1(dim2,dim3):end,dim2,dim3) <= -5, 1, 'first'); % -5 dB
            edtend1(dim2,dim3) = find(levdecaymix(irstart1(dim2,dim3):end,dim2,dim3) <= -10, 1, 'first'); % -10 dB
            t20end1(dim2,dim3) = find(levdecaymix(irstart1(dim2,dim3):end,dim2,dim3) <= -25, 1, 'first'); % -25 dB
            t30end1(dim2,dim3) = find(levdecaymix(irstart1(dim2,dim3):end,dim2,dim3) <= -35, 1, 'first'); % -35 dB
            
            %******************************************************************
            % linear regression for EDT
            
            oo(:,dim2,dim3) = polyfit((irstart1(dim2,dim3):edtend1(dim2,dim3))', ...
                levdecaymix(irstart1(dim2,dim3):edtend1(dim2,dim3),dim2,dim3),1)';
            
            EDTmix(1,dim2,dim3) = 6*((oo(2,dim2,dim3)-10)/oo(1,dim2,dim3) ...
                -(oo(2,dim2,dim3)-0)/oo(1,dim2,dim3))/fs; % EDT
            
            EDTr2mix(1,dim2,dim3) = corr(levdecaymix(irstart1(dim2,dim3):edtend1(dim2,dim3),dim2,dim3), ...
                (irstart1(dim2,dim3):edtend1(dim2,dim3))' * oo(1,dim2,dim3) + ...
                oo(2,dim2,dim3)).^2; % correlation coefficient, EDT
            
            %******************************************************************
            % linear regression for T20
            
            pp(:,dim2,dim3) = polyfit((tstart1(dim2,dim3):t20end1(dim2,dim3))', ...
                levdecay(tstart1(dim2,dim3):t20end1(dim2,dim3),dim2,dim3),1)';
            
            T20mix(1,dim2, dim3) = 3*((pp(2,dim2,dim3)-25)/pp(1,dim2,dim3) ...
                -(pp(2,dim2,dim3)-5)/ ...
                pp(1,dim2,dim3))/fs; % reverberation time, T20
            
            T20r2mix(1,dim2, dim3) = corr(levdecay(tstart1(dim2,dim3):t20end1(dim2,dim3),dim2,dim3), ...
                (tstart1(dim2,dim3):t20end1(dim2,dim3))'*pp(1,dim2,dim3) ...
                + pp(2,dim2,dim3)).^2; % correlation coefficient, T20
            
            %******************************************************************
            % linear regression for T30
            
            qq(:,dim2,dim3) = polyfit((tstart1(dim2,dim3):t30end1(dim2,dim3))', ...
                levdecay(tstart1(dim2,dim3):t30end1(dim2,dim3),dim2,dim3),1)'; % linear regression
            
            T30mix(1,dim2, dim3) = 2*((qq(2,dim2,dim3)-35)/qq(1,dim2,dim3) ...
                -(qq(2,dim2,dim3)-5)/ ...
                qq(1,dim2,dim3))/fs; % reverberation time, T30
            
            T30r2mix(1,dim2, dim3) = corr(levdecay(tstart1(dim2,dim3):t30end1(dim2,dim3),dim2,dim3), ...
                (tstart1(dim2,dim3):t30end1(dim2,dim3))'*qq(1,dim2,dim3) ...
                + qq(2,dim2,dim3)).^2; % correlation coefficient, T30
            
        end
    end
    
    
    % -------------------------------------------------------------------------
    % Average the reverberation time across individual decays
    % -------------------------------------------------------------------------
    
    avEDT = mean(EDT,4);
    avT20 = mean(T20,4);
    avT30 = mean(T30,4);
    
    
    stdEDT = std(EDT,0,4);
    stdT20 = std(T20,0,4);
    stdT30 = std(T30,0,4);
    
    

    
    % -------------------------------------------------------------------------
    % Create output structure
    % -------------------------------------------------------------------------
    
    OUT.EDT = permute(EDTmix,[2,3,1]);
    OUT.T20 = permute(T20mix,[2,3,1]);
    OUT.T30 = permute(T30mix,[2,3,1]);
    OUT.EDTr2 = permute(EDTr2mix,[2,3,1]);
    OUT.T20r2 = permute(T20r2mix,[2,3,1]);
    OUT.T30r2 = permute(T30r2mix,[2,3,1]);
    OUT.avEDT = permute(avEDT,[2,3,1]);
    OUT.avT20 = permute(avT20,[2,3,1]);
    OUT.avT30 = permute(avT30,[2,3,1]);
    OUT.stdEDT = permute(stdEDT,[2,3,1]);
    OUT.stdT20 = permute(stdT20,[2,3,1]);
    OUT.stdT30 = permute(stdT30,[2,3,1]);
    OUT.frequencies = flist;
    if exist('latency', 'var')
        OUT.latency = latency;
    end
    OUT.funcallback.name = 'ReverbTime_InterruptedNoise.m';
    OUT.funcallback.inarg = {fs,filteriterations,avmethod,lowestband,highestband,bpo,threshold};
    
    % -------------------------------------------------------------------------
    % Create table & plots
    % -------------------------------------------------------------------------
    
    % Table of results
    fig1 = figure('Name','Reverberation Parameters');
    table1 = uitable('Data',[OUT.T30;OUT.T30r2;OUT.avT30;OUT.stdT30],...
        'ColumnName',num2cell(flist),...
        'RowName',{[repmat('T30 derived from averaged decays      ',[chans,1]);...
        repmat('T30 r^2 (from averaged decays)        ',[chans,1]);...
        repmat('Average of T30 derived from each decay',[chans,1]);...
        repmat('St dev. of T30 derived from each decay',[chans,1])]});
    set(table1,'ColumnWidth',{60});
    
    table2 = uitable('Data',[OUT.T20;OUT.T20r2;OUT.avT20;OUT.stdT20],...
        'ColumnName',num2cell(flist),...
        'RowName',{[repmat('T20 derived from averaged decays      ',[chans,1]);...
        repmat('T20 r^2 (from averaged decays)        ',[chans,1]);...
        repmat('Average of T20 derived from each decay',[chans,1]);...
        repmat('St dev. of T20 derived from each decay',[chans,1])]});
    set(table2,'ColumnWidth',{60});
    
    table3 = uitable('Data',[OUT.EDT;OUT.EDTr2;OUT.avEDT;OUT.stdEDT],...
        'ColumnName',num2cell(flist),...
        'RowName',{[repmat('EDT derived from averaged decays      ',[chans,1]);...
        repmat('EDT r^2 (from averaged decays)        ',[chans,1]);...
        repmat('Average of EDT derived from each decay',[chans,1]);...
        repmat('St dev. of EDT derived from each decay',[chans,1])]});
    set(table3,'ColumnWidth',{60});
    
    
    [~,tables] = disptables(fig1,[table1 table2 table3],{'T30','T20','EDT'});
    OUT.tables = tables;
    
    
    % Plots of decays
    t = ((1:len)-1)./fs;
    for ch = 1:chans
        if exist('chanID','var')
            chanstring = char(chanID(ch));
        else
            chanstring = ['ch ',num2str(ch)];
        end
        
        figure('Name', ['Decays from Interrupted Noise, ', chanstring])

        
        [r, c] = subplotpositions(bands, 0.5);
        for bnd = 1:bands
            subplot(r,c,bnd)
            plot(t,permute(levdecay(:,ch,bnd,:),[1,4,2,3]),...
                'Color',[0.7, 0.7, 0.7])
            hold on
            plot(t,levdecaymix(:,ch,bnd),'Color',[1, 0, 0],'LineWidth',1.5)
            
            plot(t(irstart1(ch,bnd):edtend1(ch,bnd)), ...
                (irstart1(ch,bnd):edtend1(ch,bnd)) * oo(1,ch,bnd) + ...
                oo(2,ch,bnd), 'LineWidth',1,'LineStyle','--','Color', [0.6 0.6 0])
            
            plot(t(tstart1(ch,bnd):t20end1(ch,bnd)), ...
                (tstart1(ch,bnd):t20end1(ch,bnd)) * pp(1,ch,bnd) + ...
                pp(2,ch,bnd), 'LineWidth',1,'LineStyle','--','Color', [0 0.6 0])
            
            plot(t(tstart1(ch,bnd):t30end1(ch,bnd)), ...
                (tstart1(ch,bnd):t30end1(ch,bnd)) * qq(1,ch,bnd) + ...
                qq(2,ch,bnd), 'LineWidth',1,'LineStyle','--','Color', [0 0.6 0.6])
            
            text(t(edtend1(ch,bnd))+0.1, -5, ...
                ['EDT: ', num2str(round(10*OUT.EDT(ch,bnd))/10), ' s'], ...
                'Color', [0.6 0.6 0])
            
            text(t(t20end1(ch,bnd))+0.1, -25, ...
                ['T20: ', num2str(round(10*OUT.T20(ch,bnd))/10), ' s'], ...
                'Color', [0 0.6 0])
            
            text(t(t30end1(ch,bnd))+0.1, -35, ...
                ['T30: ', num2str(round(10*OUT.T30(ch,bnd))/10), ' s'], ...
                'Color', [0 0.6 0.6])
            
            %grid on
            
            xlabel('Time (s)')
            ylabel('Level (dB)')
            title([num2str(flist(bnd)), ' Hz'])
            ylim([-60 0])
        end
    end
    
    if isstruct(IN)
        doresultleaf(levdecaymix,'Level [dB]',{'Time'},...
                     'Time',     t,               's',           true,...
                     'channels', chanID,          'categorical', [],...
                     'bands',    num2cell(flist), 'Hz',          false,...
                     'name','Reverb_time_IN');
    end
else
    OUT = [];
end

%**************************************************************************
% Copyright (c) 2013, Densil Cabrera and Grant Cuthbert
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
%  * Neither the name of the University of Sydney nor the names of its contributors
%    may be used to endorse or promote products derived from this software
%    without specific prior written permission.
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
%**************************************************************************