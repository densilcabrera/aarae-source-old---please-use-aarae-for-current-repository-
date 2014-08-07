function OUT = stepped_tone_response(IN,noiseadjust,highestharmonic,plottype,normalizeplots,useMatlabs)
% This function is used to analyse the response of a system from the a
% signal generated by AARAE's stepped_tone_log generator. This provides a
% direct method of measuring harmonic distortion and noise parameters THD,
% SNR and SINAD.
%
% To prepare a signal for measurement it is best to include a 'silent
% cycle' (assuming that noise is steady state). Typically a test signal
% would may also include non-silent cycles at various gains, to test the
% change in noise and distortion parameters as a function of the gain of
% the input to the system. Tones of various frequencies (e.g. octave-spaced
% or 1/3-octave spaced) can be tested from a single test signal using
% AARAE's stepped_tone_log generator together with this analyser. Note that
% the generator only permits tone frequencies that have an integer number
% of samples in their period, so greater precision will be achieved by
% using a higher sampling rate (which also allows higher harmonics to be
% used in the distortion analysis).
%
% This function implements two calculations of THD, SNR and SINAD:
%   1. The first method is native to this analyser: 
%        *  The noise measurement is taken from the silent cycle, if
%           present. If there is no silent cycle, then SNR and SINAD cannot
%           be calculated using this method.
%        *  Each tone is evaluated by averaging a series of FFTs that have
%           a period equal to that of the test signal's frequency. This
%           means that (apart from the 0 Hz component), the spectrum
%           components are exactly in tune with the harmonic distortion
%           frequencies.
%       *   The noise is analysed in exactly the same way as the tones, and
%           its power spectrum can be subtracted from the tones' power
%           spectra (so that the tone's power spectra represent distortion
%           only, without noise). Obviously this will only work to the 
%           extent that the noise is steady state. This operation can be
%           omitted using the first dialog box field (or second input
%           argument).
%       *   The tones' power spectra can be limited to a specified number
%           of harmonics.
%       *   THD, SNR and SINAD are calculated from these data.
%   2. The second method uses Matlab's inbuilt THD, SNR and SINAD
%      functions (see Matlab's help for more information on these). In this
%      case the entire recording of each tone is analysed, and the noise is
%      not derived from the silent cycle, but instead is derived from the
%      same spectrum as the harmonic distortion. Also the fundamental
%      frequency is calculated from the signal, rather than being
%      determined from the generator's propertes.flist output field.
% Note that Matlab releases prior to 2013b do not include these inbuilt
% functions, so you can run this function without calling them (otherwise
% the function will crash).
%
% Code by Densil Cabrera
% version 1.00 (7 August 2014)


if nargin ==1
    
    param = inputdlg({'If silent cycle present: make no noise adjustment [0]; subtract noise [1]';...
        'Highest harmonic [2+, or 0 for all]';...
        'Type of plot: ribbon [0], line [1], or both [2]';...
        'Normalize plots to fundamental [0 | 1]';...
        'Use Matlab''s own THD SNR and SINAD functions too (compatible with R2013b and later) [0 | 1]'},....
        'Stepped Tone Response',...
        [1 60],...
        {'1';'0';'0';'0';'0'});
    
    param = str2num(char(param));
    
    if length(param) < 5,
        OUT = [];
        return 
    end
    if ~isempty(param)
        noiseadjust = param(1);
        highestharmonic = param(2);
        plottype = param(3);
        normalizeplots = param(4);
        useMatlabs = param(5);
    else
        OUT = [];
        return
    end
end

numF0cycles = 1; % could be a user input, but removed from the dialog box because it did not seem to achieve anything useful


% *************************************************************************
if isstruct(IN)
    audio = IN.audio; % Extract the audio data
    fs = IN.fs;       % Extract the sampling frequency of the audio data
    
    if isfield(IN,'audio2')
        audio2 = IN.audio2; % get the original test signal
    end
    
    if isfield(IN,'properties')
        
        % THE FOLLOWING PROPERTIES COME FROM THE SIGNAL GENERATOR
        if isfield(IN.properties,'flist')
            flist = IN.properties.flist;
        else
            h=warndlg('Required properties fields not found','AARAE info','modal');
            uiwait(h)
            OUT = []; % you need to return an empty output
            return % get out of here!
            % it would still be possible to use inbuilt functions - to
            % do...
        end
        if isfield(IN.properties,'startindex')
            startindex = IN.properties.startindex;
        else
            h=warndlg('Required properties fields not found','AARAE info','modal');
            uiwait(h)
            OUT = []; % you need to return an empty output
            return % get out of here!
            % it would be possible to do onset/offset detection
        end
        if isfield(IN.properties,'endindex')
            endindex = IN.properties.endindex;
        else
            h=warndlg('Required properties fields not found','AARAE info','modal');
            uiwait(h)
            OUT = []; % you need to return an empty output
            return % get out of here!
            % it would be possible to do onset/offset detection
        end
        
        
        % THE FOLLOWING PROPERTIES COME FROM AARAE'S MULTIPLE CYCLE MODE
        % FOR GENERATORS - THEY ARE NOT NEEDED IF ONLY ONE CYCLE IS USED
        if isfield(IN.properties,'relgain')
            relgain = IN.properties.relgain;
        else
            relgain = 0; % assume only one cycle, 0 dB by definition
        end
        
        if isfield(IN.properties,'startflag')
            startflag = IN.properties.startflag;
        else
            startflag = 1; % assume only one cycle, sample 1 by definition
        end
        
    else
        h=warndlg('Required properties fields not found','AARAE info','modal');
        uiwait(h)
        OUT = []; % you need to return an empty output
        return % get out of here!
    end
    
    
    if isfield(IN,'cal') % Get the calibration offset if it exists
        cal = IN.cal;
    else
        cal = 0;
    end
    % cal might not be necessary, but included in case it becomes of some
    % use
    
    
    if isfield(IN,'chanID') % Get the channel ID if it exists
        chanID = IN.chanID;
    end
    
    % no need for bandID because we will mixdown bands
    
    
    % *********************************************************************
    
    
else
    disp('Currently this function requires an AARAE audio structure as input')
    OUT = [];
    return
end
% *************************************************************************






if ~isempty(audio) && ~isempty(fs) && ~isempty(cal)
    
    
    % the audio's length, number of channels, and number of bands
    [len,chans,bands,dim4,dim5,dim6] = size(audio);
    
    if dim6 > 1
        audio = mean(audio,6); % mixdown dim6
    end
    
    if dim5 > 1
        audio = mean(audio,5); % mixdown dim5
    end
    
    if dim4 > 1
        audio = mean(audio,4); % mixdown dim4
    end
    
    if bands > 1
        audio = sum(audio,3); % mixdown bands if multiband
    end
    
    % Automatically align audio with audio2 by crosscorrelating envelopes
    if isinf(relgain(1))
        firstseq = 2;
    else
        firstseq = 1;
    end
    
    if length(startflag)>1
        len2 = startflag(2)-startflag(1);
    else
        len2 = len;
    end
    
    startsamp = startflag(firstseq);
    endsamp = startsamp+len2-1;
    if endsamp>len, endsamp = len; end
    for ch = 1:chans
        % crosscorrelate envelopes
        [X,lags] = xcorr(audio(startsamp:endsamp,ch).^2,...
            audio2.^2);
        peaklag = find(X==max(X),1,'first');
        %shift audio to align
        audio(:,ch) = circshift(audio(:,ch),-lags(peaklag));
    end
    
    
    % If the audio is multicycle, then stack in dimension 3 (since we have
    % got rid of bands already)
    if length(startflag) > 1
        dim3 = length(startflag);
        
        audiotemp = zeros(len2,chans,dim3);
        for d=1:dim3
            audiotemp(:,:,d) = ...
                audio(startflag(d):startflag(d)+len2-1,:);
        end
        audio = audiotemp;
        clear audiotemp
    else
        dim3=1;
    end
    
    % apply calibration offset value (might not be necessary but it should
    % do no harm - and maybe it will have a use in a future revision of this
    % function).
    audio = cal_reset_aarae(audio,0,cal);
    
    [THD1, SNR1, SINAD1] = deal(zeros(1,chans,dim3,length(flist)));
    tonelen = endindex(1)-startindex(1);
    % TONE ANALYSIS LOOP
    for n = 1:length(flist)
        nfft = numF0cycles*fs/flist(n); % should be an integer!
        if nfft/round(nfft) > 1.0001 || nfft/round(nfft) < 0.9999
            disp(['non-integer sample period for ' num2str(flist(n)) ' Hz!'])
        end
        nfft = round(nfft);
        
        % maximum index of spectrum below or equal to the Nyquist frequency
        maxfidx = floor(nfft/2);
        
        % preallocate main result matrix
        if ~exist('spectrum','var')
            spectrum = zeros(maxfidx,chans,dim3,length(flist));
        end
        
        audiotemp = audio(startindex(n):endindex(n),:,:);
        nwin = floor(tonelen/nfft);
        
        % Calculate Matlab's inbuilt THD, SNR and SINAD
        for ch = 1:chans
            if isinf(relgain(1))
                d1 = 2;
            else
                d1 = 1;
            end
            if highestharmonic > 2
                nharm = highestharmonic;
            else
                nharm = 100;
            end
            if useMatlabs == 1
                for d = d1:dim3
                    if d1 == 1
                        THD1(1,ch,d,n) = thd(audiotemp(:,ch,d),fs,nharm);
                        SNR1(1,ch,d,n) = snr(audiotemp(:,ch,d),fs,nharm);
                        SINAD1(1,ch,d,n) = sinad(audiotemp(:,ch,d),fs);
                    else
                        THD1(1,ch,d-1,n) = thd(audiotemp(:,ch,d),fs,nharm);
                        SNR1(1,ch,d-1,n) = snr(audiotemp(:,ch,d),fs,nharm);
                        SINAD1(1,ch,d-1,n) = sinad(audiotemp(:,ch,d),fs);
                    end
                end
            end
        end
        
        powspectrumtemp = zeros(nfft,chans,dim3,nwin);
        for m = 1:nwin
            powspectrumtemp(:,:,:,m) = abs(fft(audiotemp(1+(m-1)*nfft:(m-1)*nfft+nfft,...
                :,:))./nfft).^2;
        end
        
        % take the trimmean
        powspectrumtemp = trimmean(powspectrumtemp,25,4);
        spectrum(1:maxfidx,:,:,n) = powspectrumtemp(1:maxfidx,:,:);
        
        
        % get rid of non-harmonic data, and data beyond the highest
        % harmonic
        if highestharmonic > 1
            harmonicindices = 1+(1:highestharmonic+1)*numF0cycles;
            % index 1 is 0 Hz, so we add 1
        else
            harmonicindices = 1+(1:1000)*numF0cycles;
        end
        harmonicindices(harmonicindices>maxfidx) = [];
        
        % make logical vector
        spectrumind = zeros(maxfidx,1);
        spectrumind(harmonicindices) = 1;
        
        % Apart from the silent cycle, the spectrum consists only of
        % harmonic components (other components, including DC are zeroed).
        % If a silent cycle is used for noise measurement, all of its
        % components are preserved.
        spectrum(1:maxfidx,:,firstseq:dim3,n) =...
            spectrum(1:maxfidx,:,firstseq:dim3,n)...
            .* repmat(spectrumind,[1,chans,dim3-(firstseq-1),1]);
    end
    
    if isinf(relgain(1)) % detect silent cycle
        relgain = relgain(2:end);
        noisespectrum = spectrum(:,:,1,:);
        spectrum = spectrum(:,:,2:end,:);
        dim3 = size(spectrum,3);
        if noiseadjust == 1 || noiseadjust == 3
            % subtract noise from signal (will only work if noise is
            % really steady)
            spectrum = spectrum - repmat(noisespectrum,[1,1,dim3,1]);
            spectrum(spectrum<0)=1e-99;
            
        end
%         SNR = 10*log10(spectrum ./ repmat(noisespectrum,[1,1,dim3,1]));
%         if noiseadjust == 2 || noiseadjust == 3
%             % apply SNR threshold
%             spectrum(SNR < SNRthresh) = 1e-99;
%         end
    else
        noisespectrum = 0;
    end
    
    % SUMMARY VALUES
    SIGNALPOW = spectrum(numF0cycles+1,:,:,:);
    DISTORTIONPOW = sum(spectrum(numF0cycles+2:end,:,:,:));
    NOISEPOW = repmat(sum(noisespectrum),[1,1,dim3,1]);
    
    THD2 = 10*log10( DISTORTIONPOW ./ SIGNALPOW );
    SNR2 = 10*log10( SIGNALPOW ./ NOISEPOW);
    SINAD2 = 10*log10( SIGNALPOW ./ (DISTORTIONPOW + NOISEPOW));
    
    % THD: ratio of harmonic power to F0 power
%     if highestharmonic <2 % all harmonics
%         THD = 10*log10(sum(spectrum((numF0cycles*2+1):numF0cycles:end,:,:,:))./spectrum(numF0cycles+1,:,:,:));
%     else
%         hiharmindex = min([(numF0cycles*2+1)+numF0cycles*highestharmonic, maxfidx]);
%         THD = 10*log10(sum(spectrum((numF0cycles*2+1):numF0cycles:hiharmindex,:,:,:))./spectrum(numF0cycles+1,:,:,:));
%     end


    
    % limit the range of output values
    THD2(THD2<-200)=-inf;
    SNR2(SNR2>200)=inf;
    SINAD2(SINAD2>200)=inf;
    
    % the following values should be unlikely
    THD2(THD2>200)=inf;
    SNR2(SNR2<-200)=-inf;
    SINAD2(SINAD2<-200)=-inf;
    

    
    for ch = 1:chans
        for c = dim3:-1:1
            if plottype == 1 || plottype ==2
            % Create figure
            figure('Name',[char(chanID(ch)) ' ' num2str(relgain(c)) ' dB']);
                    if highestharmonic< 2
                        % limit to 10 harmonics for this type of plot
                        % unless otherwise specified
                        z = permute(10*log10(spectrum(2:11,ch,c,:)),[1,4,2,3]);
                    else
                        z = permute(10*log10(spectrum(2:highestharmonic+1,ch,c,:)),[1,4,2,3]);
                    end
                    if normalizeplots == 1
                        z = z - repmat(z(1,:),[size(z,1),1]);
                    end
                    colors = [[0 0 0];flipud(pmkmp(size(z,1)-1,'CubicL'))];
                    for p = 1:size(z,1)
                        plot(flist,z(p,:),'DisplayName',...
                            ['f' num2str(p)],...
                            'Color',colors(p,:))
                        hold on
                    end
                    if sum(noisespectrum)~=0
                        if normalizeplots == 1
                            plot(flist,10*log10(permute(mean(noisespectrum),[1,4,2,3]))-permute(10*log10(spectrum(2,ch,c,:)),[1,4,2,3]),':r','DisplayName','Noise')
                        else
                            plot(flist,10*log10(squeeze(mean(noisespectrum))),':r','DisplayName','Noise')
                        end
                    end
                    set(gca,'Xscale','log')
                    if normalizeplots == 1
                        ylim([-100 10])
                    end
                    xlabel('Excitation frequency (Hz)')
                    ylabel('Level (dB)')
                    legend('Show','Location','EastOutside')
                    hold off
            end
            
            if plottype==0 || plottype==2
                % Create figure
            figure1 = figure('Name',[char(chanID(ch)) ' ' num2str(relgain(c)) ' dB']);
                    % Create axes
                    %             axes1 = axes('Parent',figure1,'XScale','log','XMinorTick','on',...
                    %                 'XMinorGrid','on');
                    axes1 = axes('Parent',figure1,'XScale','lin','XMinorTick','on',...
                        'XMinorGrid','on');
                    %view(axes1,[-119.5 34]);
                    grid(axes1,'on');
                    hold(axes1,'all');
                    if highestharmonic< 2
                        z = permute(10*log10(spectrum(:,ch,c,:)),[1,4,2,3]);
                    else
                        z = permute(10*log10(spectrum(1:highestharmonic,ch,c,:)),[1,4,2,3]);
                    end
                    if normalizeplots == 1
                        z = z - repmat(z(1,:),[size(z,1),1]);
                    end
                    z(z<max(max(z))-120) = NaN; % defines the range of z vals
                    %mesh(flist, ((1:size(spectrum,1))-1)/numF0cycles,z);
                    %imagesc(flist, ((1:size(spectrum,1))-1)/numF0cycles,z);
                    ribbon(z);
                    view(axes1,[114 26]);
                    title([char(chanID(ch)), ', ', num2str(c)]);
                    ylabel('Harmonic number')
                    xlabel('Fundamental frequency (Hz)')
                    set(gca,'XTick',1:length(flist),'XTickLabel',num2cell(flist))
            end
        end
    end
    
    % plot linear response (ref audio2)?
    % plot harmonic levels - separate plot for each cycle
    % plot THD for all cyles
    
    
    

        

    
    
    fig1 = figure('Name','Distortion and Noise Values');
    tables = [];

    for ch = 1:chans
        for d3 = dim3:-1:1
            table1 = uitable('Data',[permute(THD2(1,ch,d3,:),[4,1,2,3]),...
                permute(SNR2(1,ch,d3,:),[4,1,2,3]),...
                permute(SINAD2(1,ch,d3,:),[4,1,2,3]),...
                permute(THD1(1,ch,d3,:),[4,1,2,3]),...
                permute(SNR1(1,ch,d3,:),[4,1,2,3]),...
                permute(SINAD1(1,ch,d3,:),[4,1,2,3])],...
                'ColumnName',{['THD ' char(chanID(ch)) ' ' num2str(relgain(d3)) ' dB'],...
                ['SNR ' char(chanID(ch)) ' ' num2str(relgain(d3)) ' dB'],...
                ['SINAD ' char(chanID(ch)) ' ' num2str(relgain(d3)) ' dB'],...
                ['THD* ' char(chanID(ch)) ' ' num2str(relgain(d3)) ' dB'],...
                ['SNR* ' char(chanID(ch)) ' ' num2str(relgain(d3)) ' dB'],...
                ['SINAD* ' char(chanID(ch)) ' ' num2str(relgain(d3)) ' dB']},...
                'RowName',num2cell(flist));
            tables = [tables table1];
        end
    end
    [~,tables] = disptables(fig1,tables);
    OUT.tables = tables;
    
    
    OUT.funcallback.name = 'stepped_tone_response.m'; % Provide AARAE
    
    OUT.funcallback.inarg = {noiseadjust,highestharmonic,plottype,normalizeplots,useMatlabs};
    
else
    OUT = [];
end

%**************************************************************************
% Copyright (c) 2014, Densil Cabrera
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