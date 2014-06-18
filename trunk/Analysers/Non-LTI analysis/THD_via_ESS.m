function OUT = THD_via_ESS(IN,nh,ave_or_reg,w,amp,mw,ir_plot,indv_harmonic,ampl_norm,plot_TF)

% This function calculates total harmonic distortion (f) from a matrix 
% of impulse responses generated in AARAE. For more information, please 
% see the tutorial: Measuring Total Harmonic Distortion in AARAE Using 
% an Impulse Response Generated from an Exponential Sinusoidal Sweep.
%
% Adam Opsata 2014
% version 0.00 beta (18 June 2014) - mostly works but needs some clean-up
% to improve AARAE integration.


if nargin ==1 
    
    param = inputdlg({...
        'Highest Harmonic Order to Evaluate';... % These are the input box titles in the
        'Average THD Over Frequency Bands? 1=Yes 0=No';...
        'Frequency Bands Per Octave (If THD is Averaged)';...
        'Amplify Noise by' ;...
        'Window Size for Noise Floor Comparison (samples)';...
        'Plot Each Trimmed Pseudo-IR?';...
        'Plot the Transfer Function of Each Harmonic? 1=Yes 0=No';...
        'Amplitude Normalisation? 1=Yes 0=No';...
        'Plot Transfer Function of DUT? 1=Yes 0=No'},...% inputdlg window.
        'User Input Parameters',... % This is the dialog window title.
        [1 30],... % 
        ...        % 
        ...        % 
        ...        % 
        {'6';'0';'24';'1000'; '300'; '0';'0';'1';'0'}); % The preset answers for the dialog.
    
    param = str2num(char(param)); % Since inputs are usually numbers it's a
    % good idea to turn strings into numbers.
    
    if length(param) < 9, param = []; end %Check that the user
    % has input all the required
    % fields.
    if ~isempty(param) % Assign the dialog's inputs to your function's input parameters.
        nh = param(1); %Number of harmonics to be evaluated
        ave_or_reg = param(2); % if==1 the THD will be calculated based on 
                               % harmonics whose levels are averaged over the specified frequency band. If=0 the THD will be calculated directly
        w = param(3); % Width of the frequency band that each harmonic's levels are averaged over.
        amp = param(4); % Adjusting the amplitude of the silent signal when comparing the IRs to the noise floor. Increasing amp truncates the psuedo IRs.
        mw = param(5);     %The size of the window used to evaluate the power of the signal compared to the noise floor.
        ir_plot= param(6); %if==1 the windowed IR or each harmonic is plotted, so the user can validate they are trimmed appropriately.
        indv_harmonic=param(7); %if==1 the transfer function of each harmonic is plotted
        ampl_norm=param(8); %if==1 the THD results will be amplitude normalised. This is preferred, however many other methods do not employ it.
        plot_TF=param(9); %if==1 the linear transfer function of the DUT is plotted
    end
    
    %param = [8;1;6;1;30;300;0;1;1];
end

if isstruct(IN) % Check that the function is being called within
    % the AARAE environment, and can extract the
    % information to run the anyliser.
    IR = IN.audio; % Extract the audio data
    fs = IN.fs;       % Extract the sampling frequency of the audio data
    T=IN.properties.dur;% Extract the length of the sweep.
    freqs=IN.properties.freq; %Extract the highest and lowest frequencies in the sweep
    relgain=IN.properties.relgain; % Extract the relative gain of the sweeps
    
    calcheck=isfield(IN,'cal');
    if calcheck==1
    calbrtion=IN.cal; %Extract the calibration 
    IR=IR*calbrtion; %scaling the audio signal
    end
    
end
 

 %Colours
    c = [127, 0, 255; % violet     
        0, 0, 0; ... % black
        255, 0, 0; ... % red
        255, 128, 0; ... % orange
        204, 204, 0; ... % dark yellow
        0, 204, 0; ... % mid green
        0, 204, 204; ... % dark cyan
        0, 0, 255]; ... % blue
        
    c = c / 255; % rescale to 0-1 range


% To make your function work as standalone you can check that the user has
% either entered at least an audio variable and it's sampling frequency.
if ~isempty(IR) && ~isempty(fs) && ~isempty(T) && ~isempty(freqs)&& ~isempty(relgain)
    
    if relgain(1,1) ~= -inf
        disp('Silent Sweep Too Noisy or Not Existent');
    end
    
    [irlen,~,~,nswps]=size(IR); %length of IR and number of sweeps
    big_mat=irlen; % A very large matrix to to hold all the linear and pseudo IRs. Its size will be appropriately reduced later.
    wzero=freqs(1,1); %Lowest Frequency in the exponential  sweep
    vzero=ceil(wzero/.975); %Lowest Valid Frequency in the exponential sweep (compensates for sweep fade-in)
    wone=freqs(1,2); %Highest Frequency in the exponential sweep
    vone=ceil(wone*.975); %Highest Valid Frequency in the exponential sweep (compensates for sweep fade-out)
    
    
    %%%% DETERMINING A REASONABLE LOCATION FOR THE LINEAR IR's PEAK %%%
    
    en=1./T.*log10(wone./wzero); % equation from Abel, to locate pseudo IRs
    sec_offset_2nd=(((log10(2))./en)); %the location offset for the 2nd IR
    samp_offset_2nd=ceil(sec_offset_2nd.*fs); %the location offset in samples
    
    mp=round(irlen./2); %midpoint
    gd_lnr_wndwb=mp-samp_offset_2nd; %a good place for the linear Ir to be after
    gd_lnr_wndwe=mp+samp_offset_2nd; %a good place for the linear Ir to be before
    %If the bigest peak is outside this area a warning will be displayed
    
    %%%Preallocating
    Harmonic_Seg=zeros(big_mat,nh,nswps);
    matlens=zeros(nh,nswps);
    strt=zeros(nh,nswps);
    stp=zeros(nh,nswps);
    
    
    %Finding the pseudo-IRs, trimming them based on their amplitude compared to background noise, and putting
    %them in a matrix.
    
    for sn=2:nswps;
        thissweep=IR(:,1,1,sn);
        [~,dirac]=max(abs(thissweep)); % the location of the Linear Impulse Response
        if dirac<(gd_lnr_wndwb) % if the maximum point in the full IR falls outside this range, there is most likely an error.
            disp('Warning: Highly Distorting or Noisy System, Can Not Analyse');
        end
        if dirac>(gd_lnr_wndwe)
            disp('Warning: Highly Distorting or Noisy System, Can Not Analyse');
        end
        for p=1:nh; %Looking at all linear and pseudo IRs.
            
            sec_offset=(((log10(p))./en)); %the location offset for the sought harmonic IR in seconds LOG BASE 10 WORKS, NOT LN!!
            samp_offset=ceil(sec_offset.*fs); %the location offset for the sought harmonic IR in samples
            
            %%%%%% Finding a good start point for the trimmed IR by comparing it to the silent sweep
            
            tsf=1; %Times this loop has searched forward.
            strt(p,sn)=dirac-(samp_offset+(mw.*tsf)); %buffer to search before of IR
            winltlf=IR(strt(p,sn):strt(p,sn)+mw,1,1,sn); %a small window before the dirac
            winnoif=IR(strt(p,sn):strt(p,sn)+mw,1,1,1);  %a corresponding small window in the quiet sweep
            
            pwrltlf=mean((winltlf.^2)); %The power of a section of the Ir signal
            pwrnoif=amp*mean((winnoif.^2)); %The power of the noise signal with an amplitude adjustment
            
            while pwrltlf > pwrnoif %Keep searching forward until the power of the adjusted noise is greater than the power of the signal.
                
                tsf=tsf+1; %Times this loop has searched forward.
                strt(p,sn)=dirac-(samp_offset+(mw.*tsf)); %buffer to search before the IR
                winltlf=IR(strt(p,sn):strt(p,sn)+mw,1,1,sn); %a small window before the dirac
                winnoif=IR(strt(p,sn):strt(p,sn)+mw,1,1,1);  %a corresponding small window in the quiet sweep
                
                pwrltlf=mean(winltlf.^2); %the power of a section of the IR signal
                pwrnoif=amp*mean(winnoif.^2);  %power of the noise signal with an amplitude adjustment
                
            end
            
            %%%%%% Find a good place to trim the end of the IRs
            
            tsa=1; %times this loop has searched after the peak.
            stp(p,sn)=dirac-samp_offset+(mw*(tsa-1)); %buffer to search after the IR
            winltla=IR((stp(p,sn):(stp(p,sn)+mw)),1,1,sn); %a small window after the dirac
            winnoia=IR((stp(p,sn):(stp(p,sn)+mw)),1,1,1);  %a corresponding small window in the quiet sweep
            
            pwrltla=mean((winltla.^2)); %The power of a section of the Ir signal
            pwrnoia=amp*mean((winnoia.^2)); % the power of the noise signal with an amplitude adjustment
            
            while pwrltla > pwrnoia %Keep looking after the dirac until the power of the adjusted noise is greater than the power of the signal.
                
                tsa=tsa+1;%times this loop has searched after the peak.
                stp(p,sn)=dirac-samp_offset+(mw*(tsa-1)); %buffer to search after the IR
                winltla=IR((stp(p,sn):(stp(p,sn)+mw)),1,1,sn); %a small window after the dirac
                winnoia=IR((stp(p,sn):(stp(p,sn)+mw)),1,1,1);  %a corresponding small window in the quiet sweep
                
                pwrltla=mean((winltla.^2)); %the power of a section of the Ir signal
                pwrnoia=amp*mean((winnoia.^2)); % the power of the noise signal with an amplitude adjustment
                
            end
            
            if ir_plot==1 % PLOT EACH TRIMMED PSEUDO IRs
     
                sseg=(IR(strt(p,sn):stp(p,sn),1,1,sn));
                nseg=(IR(strt(p,sn):stp(p,sn),1,1,1));
                
                lll=length(sseg);
                
                chanstring = [',   Sweep no. ',num2str(sn-1)];
                pstring=[',   Harmonic no. ',num2str(p)];
                figure('Name', ['IR Windows, ', chanstring ,  pstring ]);
                title(['Total Harmonic Distortion from ESS, Sweep Number ' ,num2str(sn-1)]);
                
                plot(sseg);
                xlim([0 lll]);
                xlabel('Samples');
                ylabel('Amplitude');
                title(['Impulse Response ', chanstring, pstring]);
                hold on
                plot(nseg,'r');
                hold off
            end
            
            if p>1 %checking to see if any of the pseudo-IRs overlap
                if stp(p,sn)>strt(p-1,sn)
                    disp('Warning: Pseudo-IR Windows Overlap, result inaccurate due to noise or reverberation. Amplify Noise or decrease Noise Floor Comparison Window Size.');
                end
            end
            
            matlens(p,sn)=stp(p,sn)-strt(p,sn)+1; %the length of the linear portion of the IR likely to be the longest
            
            % the code below places each Ir or pseudo-IR in the middle of a
            % large vector to zero pad it.
            seglens=stp(p,sn)-strt(p,sn)+1; %the length of this segment
            olens=big_mat-seglens;
            if olens>2;
                inlens=round((olens)/2)+1;
            else
                inlens=1;
            end
            
            %%% make a matrix of distortion IRs
            if tsf>1 && tsa>1 % If the initial window does not exceed the noise threshold the pseudo-IR is not evaluated
                
                Harmonic_Seg(inlens:(seglens+inlens-1),p,sn)=IR(strt(p,sn):stp(p,sn),1,1,sn); % make a matrix of IRs at each overtone.
                Harmonic_Seg(inlens:(seglens+inlens-1),p,1)=IR(strt(p,sn):stp(p,sn),1,1,1); % make a matrix of IRs at each fundamental.
                
            else
                Harmonic_Seg(:,p,sn)=zeros; % If the initial window does not exceed the noise threshold the pseudo-IR is set to zero
            end
        end
        hold off
    end
    
    %Trimming the matrix of IRs to a more manageable size.
    max_Ir_len=max(max(matlens));
    if max_Ir_len>200000
        mid_mat=max_Ir_len+1000; % at least 1000 samples longer than the longest linear IR
    else 
        mid_mat=200000; % or 200000 samples at minimum
    end
      
    mat_in=ceil((big_mat-mid_mat)/2); 
    mat_out=big_mat-mat_in-1;
    
    Harmonic_Seg=Harmonic_Seg(mat_in:mat_out,:,:); %resizing the matrix
    
    %create a frequencies vector to normalise each harmonic to it's
    %excitation frequency
    fft_frequencies_vector=zeros(mid_mat,nh);
    for p=1:nh
        fft_frequencies_vector(:,p) = (linspace(0, fs,mid_mat)')./p; %each pseudo IR has a unique frequency vector in order to plot it by the excitation frequency
    end
    nyq=floor(mid_mat/2); %the nyquist index
    
    % Preallocating
    linear_TF=zeros(mid_mat,nswps);
    linear_TF_dB=zeros(mid_mat,nswps);
    harmonic_fft=zeros(mid_mat,nh,nswps);
    harmonic_mags=zeros(mid_mat,nh,nswps);
    harmonic_db_mags=zeros(mid_mat,nh,nswps);
    cl=zeros(1,nh);
    ch=zeros(1,nh);
    maxve=zeros(1,nh);
    minve=zeros(1,nh);
    
    
    if ampl_norm==1 %Calculating the transfer function of each IR with amplitude normalisation
        for sn=2:nswps;
            for p=1 
                
                linear_TF(:,sn)=abs(fft(Harmonic_Seg(:,p,sn).*tukeywin(mid_mat))); %the non-normalised TF of the linear IR is used to normalise the harmonics
                linear_TF_dB(:,sn)=20.* log10((linear_TF(:,sn))); % Used to plot the DUT's frequency response
                harmonic_fft(:,p,sn) = 1; % The linear Transfer Function will always normalise to 1
                harmonic_mags(:,p,sn)= 1;
                harmonic_db_mags(:,p,sn)= 0;
                
            end
            for p=2:nh
                harmonic_mags(:,p,sn) = abs(fft(Harmonic_Seg(:,p,sn).*tukeywin(mid_mat)))./(linear_TF(:,sn)); % into freq. domain with magnitude normalised by the linear IR
                harmonic_db_mags(:,p,sn) = 20.* log10(harmonic_mags(:,p,sn));  %each magnitude normalised IR on a DB scale
            end
        end
        
    else if ampl_norm==0 %Calculating the transfer function of each IR without using amplitude normalisation
            for sn=2:nswps;
                for p=1:nh
                    harmonic_mags(:,p,sn) = abs((fft(Harmonic_Seg(:,p,sn).*tukeywin(mid_mat)))); % into freq. domain, no magnitude normalisation
                    harmonic_db_mags(:,p,sn) = 20.* log10(harmonic_mags(:,p,sn));  %each magnitude normalised IR on a DB scale
                end
                linear_TF_dB(:,sn)=harmonic_db_mags(:,1,sn);
            end
        end
    end
    
    %Finding valid frequency limits for each Harmonic
    cl(p)=vzero; %  low cut: lowest valid frequency in the harmonic
    for p=1:nh
        ch(p)=vone/p;% high cut: highest valid frequency in the harmonic
        [ve,~]=find((cl(p))<fft_frequencies_vector(:,p) & fft_frequencies_vector(:,p)<(ch(p))); %find the valid portion of each IR, by looking at valid frequencies in each frequency vector
        maxve(p)=max(ve);
        minve(p)=min(ve);
    end
    
    %%%Calculation and plotting with no averaging of levels
    if ave_or_reg==0
        
        %calculating the amplitude of individual harmonics and frequency
        %normalising them
        amp_indv_h=zeros(mid_mat,p,nswps);
        for sn=2:nswps;
            for p=1:nh
                for d=1:mid_mat
                    pd=p*d;
                    oheff=p*fft_frequencies_vector(d,1);
                    if oheff<(vone)
                        amp_indv_h(d,p,sn)=harmonic_mags(pd,p,sn);                        
                    end
                end
            end
        end
        
        Thdf_all=zeros(mid_mat,nswps); %calculating THDf
        for sn=2:nswps
            for d=1:mid_mat
                Thdf_all(d,sn)=sqrt(sum((amp_indv_h(d,2:nh,sn).^2)))./amp_indv_h(d,1,sn);
            end
        end
        
        Thdf_all_db=20*log10(Thdf_all);
        Thdf_all_db(:,1)=0;
        
        if indv_harmonic==1 %Plotting the levels of each harmonic for each sweep. No averaging.

            for sn=2:nswps;
                figure
                for p=1:nh
                    
                    m=mod(p,8)+1;
                    semilogx(fft_frequencies_vector(minve(p):maxve(p),p),harmonic_db_mags(minve(p):maxve(p),p,sn), ... %plotting each normalised IR, now frequecy normilesd
                        'Color',c(m,:),...
                        'DisplayName',['Harmonic',num2str(p)]); %same as plotted Plot the TF of each IR on a dB scale
                    xlabel('Excitation Frequency (Hz)')
                    ylabel('Level (dB)')
                    title(['Total Harmonic Distortion from ESS, Sweep Number ' ,num2str(sn-1)])
                    xlim([vzero vone]);
                    hold on
                end
                legend('Show','Location','EastOutside')
                hold off
            end
        end
        
        %Plotting the THD of each sweep on the same plot. No averaging.
        figure
        for sn=2:nswps;
                    
            m=mod((sn-1)*3,8);                 
            semilogx(fft_frequencies_vector(:,1),Thdf_all_db(:,sn), ...
                'Color',c(m,:),...
                'DisplayName',['Sweep ', num2str(sn-1)]); 
            xlabel('Excitation Frequency (Hz)')
            ylabel('Level (dB)')
            title(['Total Harmonic Distortion']);
            xlim([vzero vone]);
            hold on
            
        end
        legend('Show','Location','EastOutside')
        plot(fft_frequencies_vector(:,1),Thdf_all_db(:,1),'w') %setting ymax to 0
        hold off
        
    end

    %Calculating THD based on mean levels in each frequency band.
    if ave_or_reg==1

        %Defining the frequency band centre frequencies and upper and lower
        %limits
        nobs=20*w;% number of octave bands total
        obfs=zeros(nobs,3);
        obfs(1,1)=vzero; %1/3 octave band frequencies, starting at 20Hz
        for n=2:nobs
            obfs(n,1)=2.^(1/w).*(obfs(n-1,1));% 1/3 octave band centre frequencies
        end
        for n=1:nobs;
            obfs(n,2)=obfs(n,1)./(2.^(1/(w*2))); % 1/3 octave band lowest  frequencies
            obfs(n,3)=obfs(n,1).*(2.^(1/(w*2))); % 1/3 octave band highest frequencies
        end
        
        NY=vone; 
        [ny,~,]=find(obfs(:,3)<NY); %find it in the matrix of 1/3 octave band highest frequencies
        nyi=max(ny); % the location of the nyquist in the 1/3 octave band matrix
        %go up to a stable octave band
        
        fbfv=obfs(1:nyi,1); % frequency bands frequency vector;
        
        mean_ampl=zeros(nyi,nh,nswps); %mean amplitude of the normalised pseudo IRs over specified frequency bands
        mxthrd=zeros(nyi,nh,nswps);
        mnthrd=zeros(nyi,nh,nswps);
        
        % I know this can be made more efficient by making calculations
        % for the first harmonic and multiplying by the order of each higher
        % harmonic, but my implementation of this method is not yet
        % functioning. Simple multiplication of this implementation omits
        % some fft frequency bins because resolution of frequency bands
        % increases with higher harmonic orders and higher frequencies.
        
        % summing the means of all pseudo IRs at each 1/3 octave band

        for sn=2:nswps;
            
            for p=1:nh
                NY2=vone/p; %the highest valid measured frequency of a harmonic
                [ny2,~,]=find(obfs(:,3)<NY2); %find it in the matrix of frequency band highest frequencies
                nyi2=max(ny2); % the location of the nyquist in the frequency band matrix
                for b=1:nyi2
                    [thrds,~]=find((obfs(b,2))<fft_frequencies_vector(:,p) & fft_frequencies_vector(:,p)<(obfs(b,3)));
                    if  isempty(thrds)
                        mxthrd(b,p,sn)=0;
                        mnthrd(b,p,sn)=0;
                        mean_ampl(b,p,sn)=0;
                    else
                        mxthrd(b,p,sn)=max(thrds);% the location of the minimum and maximum frequency in a band
                        mnthrd(b,p,sn)=min(thrds);

                        mean_ampl(b,p,sn)=mean(harmonic_mags(mnthrd(b,p,sn):mxthrd(b,p,sn),p,sn)); % the mean amplitude in a band
                    end
                end
            end
        end
        
        mean_ampl_db=20*log10(mean_ampl); % the mean level in a band
        
        % calculating THDf at each frequency as per Shmilovitz

        mthdf_db=zeros(nyi,nswps); 
        for sn=2:nswps;
            for b=1:nyi
 
                mthdf_db(b,sn)=20*log10(sqrt(sum((mean_ampl(b,2:nh,sn).^2)))./mean_ampl(b,1,sn)); %THD from frequency band means on a dB scale
                
            end
        end
    end
    
   
    %%%%%%%%%%%%%%PLOTTING THE LEVELS OF THE INDIVIDUAL HARMONICS AVERAGED TO FREQUENCY BANDS%%%%%%%%%%%
    if ave_or_reg==1;
        if indv_harmonic==1
            for sn=2:nswps;
                figure
                for p=1:nh
                    m=mod(p,8)+1;
                    semilogx(fbfv,mean_ampl_db(:,p,sn), ... %plotting each normalised IR, now frequency normalised
                        'Color',c(m,:),...
                        'DisplayName',['Harmonic ',num2str(p)]); %same as plotted Plot the TF of each IR on a dB scale
                    xlabel('Excitation Frequency (Hz)')
                    ylabel('Level (dB)')
                    title(['Individual Harmonics, Averaged Over 1/',num2str(w),' Octave Bands, Sweep Number ' , num2str(sn-1)])
                    xlim([vzero vone]);
                    hold on
                end
                legend('Show','Location','EastOutside')
                hold off
            end
        end
    end
    
    %%%% Plotting the total harmonic distortion per frequency from MEAN
    %%%% levels
    if ave_or_reg==1;
        figure
        for sn=2:nswps
            
            m=mod((sn-1)*3,8);
            semilogx(fbfv,mthdf_db(:,sn),...
                'Color',c(m,:),...
                'DisplayName',['Sweep ', num2str(sn-1)]);
            xlabel('Excitation Frequency (Hz)')
            ylabel('THD (dB)')
            title(['THD Calculated from Harmonic Levels Averaged Over 1/',num2str(w),' Octave Bands '])
            xlim([vzero vone])
            hold on
            
        end
        legend('Show','Location','EastOutside')
        hold off
    end


    %%%%PLOTTING THE TRANSFER FUNCTION OF THE DUT
 
    if plot_TF==1
        figure
        for sn=2:nswps
            m=mod((sn-1)*3,8);
            
            semilogx(fft_frequencies_vector(1:nyq,1),linear_TF_dB(1:nyq,sn),...);
                'Color',c(m,:),...
                'DisplayName',['Sweep', num2str(sn-1)]); 
            xlabel('Frequency (Hz)')
            ylabel('Level (dB)')
            title(['The Transfer Function of the DUT (Linear Response)'])
            xlim([vzero vone])
            hold on
            
        end
        legend('Show','Location','EastOutside')
        hold off
    end

    
    % The code below is a place holder for future version of the code that
    % output the data as a structure.
    
    if isstruct(IN)
        %OUT = IN; % You can replicate the input structure for your output
        %OUT.audio = IR; % And modify the fields you processed
        % Or simply output the fields you consider necessary after
        % processing the input audio data, AARAE will figure out what has
        % changed and complete the structure. But remember, it HAS TO BE a
        % structure if you're returning more than one field:
        %   OUT = audio;  if you just want to return the audio,
        %   or,
        %   OUT.audio = audio; if you want to return two fields.
        %   OUT.fs = fs;
        OUT.funcallback.name = 'THD_via_ESS.m';
        OUT.funcallback.inarg = {nh,ave_or_reg,w,amp,mw,ir_plot,indv_harmonic,ampl_norm,plot_TF};
    else
        % You may increase the functionality of your code by allowing the
        % output to be used as standalone and returning individual
        % arguments instead of a structure.
        OUT = []; % no output
    end
%     varargout{1} = 0;
%     varargout{2} = 0;
%     varargout{3} = 0;
else
     OUT = [];
end
 
%**************************************************************************
% Copyright (c) 2014, Adam Opsata
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
