function OUT = RoughnessDW(IN,ov)
% This function calculates time-varying roughness and time-averaged specific 
% roughness using the roughness model by Daniel & Weber:
% Daniel, P., & Weber, R. (1997). Psychoacoustical roughness: implementation 
% of an optimized model. Acustica(83), 113-123.
% reference signal: 60dB 1kHz tone 100% modulated at 70Hz would output 1
% asper.

% INPUT ARGUMENTS
% IN - audio signal (1 channel only)
% ov - time window overlap in percentage
% When run directly from the AARAE GUI ov equals zero. If you wish to
% use non-zero input while using the AARAE GUI, one way is to write a
% workflow function (by adapting code generated in AARAE's log file)
% fs and cal inputs are only used if a non-structure (vector or matrix) is
% the primary input.
%
% OUTPUTS
% * Time-varying Roughness
% * Time-averaged Specific Roughness
% * Time-averaged Roughness statistics

% Author: Matt Flax (http://www.flatmax.org>) original version: March 2006 for psysound
% revised: Farhan Rizwi: July '07 for psysound3
% Adjusted version by Ella Manor for AARAE 23-10-2015

% *************************************************************************

% *************************************************************************
if isstruct(IN) 
    
    IN = choose_from_higher_dimensions(IN,1,1); % only 1 channel analysis at present:

    
    audio = IN.audio; % Extract the audio data
    fs = IN.fs;       % Extract the sampling frequency of the audio data
    
    if isfield(IN,'cal') % Get the calibration offset if it exists
        cal = IN.cal;
    else
        warndlg('Calibration data missing - please calibrate prior to calling this function.','AARAE info','modal');
        IN = cal_aarae(IN);
        cal = IN.cal;
    end
    
    % The name of the audio input could be useful in generating figures
    % (for example, in the title of a figure). This is a string.
    if isfield(IN,'name') % Get the AARAE name if it exists
        name = IN.name;
    else
        name = [];
    end
    
    % *********************************************************************

if ~isempty(audio) && ~isempty(fs) && ~isempty(cal)
       
        [~, nchan, bands] = size(audio);
        if bands > 1
            audio = sum(audio,3);
            disp('Multiband audio has been mixed.')
        end
        
        if nchan > 1
            audio = audio(:,1:2);
            if nchan > 2
                disp('Only the first two channels are analysed by RoughnessDW.')
                nchan = 2;
            end
        end
    
 % signal calibration offset
        calconstant = 83; % by validating 1 kHz at 40 dB = 1 sone
        cal = cal-calconstant;
        if length(cal) == 1
            audio = audio .* 10.^(cal/20);
        else
            audio(:,1) = audio(:,1) .* 10.^(cal(1)/20);
            audio(:,2) = audio(:,2) .* 10.^(cal(2)/20);
        end
        
        disp(['rms level of the entire wave ', num2str(10*log10(mean(audio.^2)+10e-99)+calconstant), ' dB'])
        
     
     
% *************************************************************************
% MAIN analyser starts here
% *************************************************************************    

N = 8192; % window length
window = blackman(N);

samples = length(audio);
if ~(fs == 44100 || fs == 40960 || fs == 48000)
  error(['Incorrect sample rate for this roughness algorithm. Please ' ...
         're-sample original file to be Fs=44100,40960 or 48000 ' ...
         'Hz']);
end

if mod(samples,N) ~= 0
    n = ceil(samples/N)+1;
    nn = n*N-samples;
    if mod(nn,2)
        padStartsamp = zeros(nn/2,nchan);
        padEndsamp = zeros(nn/2,nchan);
    else
        padStartsamp = zeros(nn/2,nchan);
        padEndsamp = zeros(nn/2,nchan);
    end
    audio = [padStartsamp;audio;padEndsamp];
    samples = length(audio);
end
   
        
%  audio = audio*1.71; % added in psysound3 to improve the accuracy of the
%  algorithm, so that a 60dB tone 100% modulated at 70Hz would output an 
% asper value of 1. This line is commented out here as the algorithm produces 
% accurate result. 

% overlap
if ~exist('ov','var')
    ov = 0;
elseif isempty(ov),
    ov = 0;
end
        
%%%%%%%%%%%%%%%%%
% BEGIN InitAll %
%%%%%%%%%%%%%%%%%
Bark = [0     0	   50	 0.5
        1   100	  150	 1.5
        2   200	  250	 2.5
        3   300	  350	 3.5
        4   400	  450	 4.5
        5   510	  570	 5.5
        6   630	  700	 6.5
        7   770	  840	 7.5
        8   920	 1000	 8.5
        9  1080	 1170	 9.5
        10  1270 1370	10.5
        11  1480 1600	11.5
        12  1720 1850	12.5
        13  2000 2150	13.5
        14  2320 2500	14.5
        15  2700 2900	15.5
        16  3150 3400	16.5
        17  3700 4000	17.5
        18  4400 4800	18.5
        19  5300 5800	19.5
        20  6400 7000	20.5
        21  7700 8500	21.5
        22  9500 10500	22.5
        23 12000 13500	23.5
        24 15500 20000	24.5];

Bark2	= [sort([Bark(:,2);Bark(:,3)]),sort([Bark(:,1);Bark(:,4)])];
N0	= round(20*N/fs)+1;
N01	= N0-1;
N50     = round(50*N/fs)-N0+1;
N2	= N/2+1;
Ntop	= round(20000*N/fs)+1;
Ntop2	= Ntop-N0+1;
dFs	= fs/N;

% Make list with Barknumber of each frequency bin
Barkno	  = zeros(1,N2);
f	  = N0:1:Ntop;
Barkno(f) = interp1(Bark2(:,1),Bark2(:,2),(f-1)*dFs);

% Make list of frequency bins closest to Cf's
Cf = ones(2,24);
for a=1:1:24
  Cf(1,a)=round(Bark((a+1),2)*N/fs)+1-N0;
  Cf(2,a)=Bark(a+1,2);
end
%Make list of frequency bins closest to Critical Band Border frequencies
Bf = ones(2,24);
Bf(1,1)=round(Bark(1,3)*N/fs);
for a=1:1:24
  Bf(1,a+1)=round(Bark((a+1),3)*N/fs)+1-N0;
  Bf(2,a)=Bf(1,a)-1;
end
Bf(2,25)=round(Bark((25),3)*N/fs)+1-N0;

%Make list of minimum excitation (Hearing Treshold)
HTres= [	0		130
                0.01   70
                0.17	 60
                0.8	 30
                1		 25
                1.5	 20
                2		 15
                3.3	 10
                4		  8.1
                5		  6.3
                6		  5
                8		  3.5
                10		  2.5
                12		  1.7
                13.3	  0
                15		 -2.5
                16		 -4
                17		 -3.7
                18		 -1.5
                19		  1.4
                20		  3.8
                21		  5
                22		  7.5
                23 	 15
                24 	 48
                24.5 	 60
                25		130];

k = (N0:1:Ntop);
MinExcdB = interp1(HTres(:,1),HTres(:,2),Barkno(k));
  
% Initialize constants and variables
zi    = 0.5:0.5:23.5;
zb    = sort([Bf(1,:),Cf(1,:)]);
MinBf = MinExcdB(zb);
ei    = zeros(47,N);
Fei   = zeros(47,N);

% BarkNo  0     1   2   3   4   5   6   7   8     9     10
%	 11     12  13  14  15  16  17  18  19  20  21  22  23  24 
gr = [ 0,1,2.5,4.9,6.5,8,9,10,11,11.5,13,17.5,21,24;
       0,0.35,0.7,0.7,1.1,1.25,1.26,1.18,1.08,1,0.66,0.46,0.38,0.3];
gzi    = zeros(1,47);
h0     = zeros(1,47);
k      = 1:1:47;
gzi(k) = sqrt(interp1(gr(1,:)',gr(2,:)',k/2));
    
% calculate a0
a0tab =	[ 0	 0
          10	 0
          12	 1.15
          13	 2.31
          14	 3.85
          15	 5.62
          16	 6.92
          16.5	 7.38
          17	 6.92
          18	 4.23
          18.5	 2.31
          19	 0
          20	-1.43
          21	-2.59
          21.5	-3.57
          22	-5.19
        22.5	-7.41
          23	-11.3
          23.5	-20
          24	-40
          25	-130
          26	-999];

a0    = ones(1,N);
k     = (N0:1:Ntop);
a0(k) = db2mag(interp1(a0tab(:,1),a0tab(:,2),Barkno(k)));

%%%%%%%%%%%%%%%
% END InitAll %
%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%
% BEGIN Hweights %
%%%%%%%%%%%%%%%%%%
% weights for freq. bins < N/2

DCbins	= 2;

H2 = [	0	0
        17    0.8
        23	0.95
        25	0.975
        32	1
        37	0.975
        48	0.9
        67    0.8
        90	0.7
        114   0.6
        171   0.4
        206	0.3
        247   0.2
        294	0.1
        358	0 ];

H5 = [	0	0
        32    0.8
        43	0.95
        56	1
        69	0.975
        92	0.9
        120   0.8
        142	0.7
        165   0.6
        231   0.4
        277	0.3
        331   0.2
        397	0.1
        502	0 ];

H16 = [	0	0
        23.5	0.4
        34	0.6
        47	0.8
        56	0.9
        63	0.95
        79	1
        100	0.975
        115	0.95
        135	0.9
        159	0.85
        172	0.8
        194	0.7
        215	0.6
        244	0.5
        290	0.4
        348	0.3
        415	0.2
        500	0.1
        645	0	];

H21 = [	0	0
        19	0.4
        44	0.8
        52.5	0.9
        58	0.95
        75	1
        101.5	0.95
        114.5	0.9
        132.5	0.85
        143.5	0.8
        165.5	0.7
        197.5	0.6
        241	0.5
        290	0.4
        348	0.3
        415	0.2
        500	0.1
        645	0	];


H42 = [ 0	0
        15	0.4
        41	0.8
        49	0.9
        53	0.965
        64	0.99
        71	1
        88	0.95
        94	0.9
        106	0.85
        115	0.8
        137	0.7
        180	0.6
        238	0.5
        290	0.4
        348	0.3
        415	0.2
        500	0.1
        645	0	];

Hweight	= zeros(47,N);

% weighting function H2
last	= floor((358/fs)*N) ;
k	= DCbins+1:1:last;
f	= (k-1)*fs/N;
Hweight(2,k) = interp1(H2(:,1),H2(:,2),f(k-DCbins));

% weighting function H5
last	=	floor((502/fs)*N);
k	=	DCbins+1:1:last;
f	=	(k-1)*fs/N;
Hweight(5,k)	= interp1(H5(:,1),H5(:,2),f(k-DCbins));

% weighting function H16
last	=	floor((645/fs)*N);
k	=	DCbins+1:1:last;
f	=	(k-1)*fs/N;
Hweight(16,k)	= interp1(H16(:,1),H16(:,2),f(k-DCbins));

% weighting function H21
Hweight(21,k)	= interp1(H21(:,1),H21(:,2),f(k-DCbins));

% weighting function H42
Hweight(42,k)	= interp1(H42(:,1),H42(:,2),f(k-DCbins));

% H1-H4
Hweight(1,:) = Hweight(2,:);
Hweight(3,:) = Hweight(2,:);
Hweight(4,:) = Hweight(2,:);

% H5-H15
for l =	6:1:15;
  Hweight(l,:) = Hweight(5,:);
end

% H17-H20
for l =	17:1:20;
  Hweight(l,:) = Hweight(16,:);
end

% H22-H41
for l =	22:1:41;
  Hweight(l,:) = Hweight(21,:);
end

% H43-H47
for l =	43:1:47;
  Hweight(l,:) = Hweight(42,:);
end

%%%%%%%%%%%%%%%%
% END Hweights %
%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%
% BEGIN process window %
%%%%%%%%%%%%%%%%%%%%%%%%

% ov_samp = window*ov/100;
% offset = window - ov_samp;
% period = offset ./ fs;
% windowOverlap = round(1 / period,2);

AmpCal = db2mag(80)*2/(N*mean(blackman(N, 'periodic')));
% Calibration between wav-level and loudness-level (assuming
% blackman window and FFT will follow)

Chno	=	47;
Cal	 	=	0.25;
N2		=	N/2;
q		=	1:1:N;
qb		=	N0:1:Ntop;
freqs	=	(qb+1)*fs/N;
hBPi	=	zeros(Chno,N);
hBPrms	=	zeros(1,Chno);
mdept	=	zeros(1,Chno);
ki		=	zeros(1,Chno-2);
ri		=	zeros(1,Chno);

startIndex = 1;
endIndex = N;
TimePoints = zeros(n,1);
R_mat = [];
ri_mat = [];
SPL_mat = [];

    for windowNum = 1:n

    dataIn = audio(startIndex:endIndex,nchan).*window;
    currentTimePoint = startIndex/fs; 
        % Calculate Excitation Patterns
        TempIn =  dataIn*AmpCal;
        [rt,~]=size(TempIn);
        [r,~]=size(a0);
        if rt~=r; TempIn=TempIn'; end
        
        TempIn	=	a0.*fft(TempIn);
        Lg		=	abs(TempIn(qb));
        LdB		=	mag2db(Lg);
        whichL	=	find(LdB>MinExcdB);
        sizL	=	length(whichL);

        % steepness of slopes (Terhardt)
        S1 = -27;
        S2 = zeros(1,sizL);

        for w = 1:1:sizL;
          % Steepness of upper slope [dB/Bark] in accordance with Terhardt
          steep = -24-(230/freqs(w))+(0.2*LdB(whichL(w)));
          if steep < 0
            S2(w) = steep;
          end
        end
        whichZ	= zeros(2,sizL);
        qd		= 1:1:sizL;
        whichZ(1,:)	= floor(2*Barkno(whichL(qd)+N01));
        whichZ(2,:)	= ceil(2*Barkno(whichL(qd)+N01));

        ExcAmp = zeros(sizL,47);
        Slopes = zeros(sizL,47);
        for k=1:1:sizL
          Ltmp = LdB(whichL(k));
          Btmp = Barkno(whichL(k)+N01);

          for l = 1:1:whichZ(1,k)
            Stemp = (S1*(Btmp-(l*0.5)))+Ltmp;
            if Stemp>MinBf(l)
              Slopes(k,l)=db2mag(Stemp);
            end
          end
          for l = whichZ(2,k):1:47
            Stemp =	(S2(k)*((l*0.5)-Btmp))+Ltmp;
            if Stemp>MinBf(l)
              Slopes(k,l)=db2mag(Stemp);
            end
          end
        end
        for k=1:1:47
          etmp = zeros(1,N);
          for l=1:1:sizL
            N1tmp = whichL(l);
            N2tmp = N1tmp + N01;
            if (whichZ(1,l) == k)
              ExcAmp(N1tmp, k) = 1;
            elseif (whichZ(2,l) == k)
              ExcAmp(N1tmp, k) = 1;
            elseif (whichZ(2,l) > k)
              ExcAmp(N1tmp,k) = Slopes(l,k+1)/Lg(N1tmp);
            else
              ExcAmp(N1tmp,k) = Slopes(l,k-1)/Lg(N1tmp);
            end
            etmp(N2tmp) = ExcAmp(N1tmp,k)*TempIn(N2tmp);
          end
          ei(k,:)	= N*real(ifft(etmp));
          etmp	= abs(ei(k,:));
          h0(k)	= mean(etmp);
          Fei(k,:)	= fft(etmp-h0(k));
          hBPi(k,:)	= 2*real(ifft(Fei(k,:).*Hweight(k,:)));
          hBPrms(k)	= rms(hBPi(k,:));
          if h0(k)>0
            mdept(k) = hBPrms(k)/h0(k);
            if mdept(k)>1
              mdept(k)=1;
            end
          else
            mdept(k)=0;
          end
        end
        % find cross-correlation coefficients
        for k=1:1:45
          cfac	=	cov(hBPi(k,:),hBPi(k+2,:));
          den	=	diag(cfac);
          den	=	sqrt(den*den');
          if den(2,1)>0
            ki(k)	=	cfac(2,1)/den(2,1);
          else
            ki(k)	=	0;
          end
        end

        % Calculate specific roughness ri and total roughness R
        ri(1)	=	(gzi(1)*mdept(1)*ki(1))^2;
        ri(2)	=	(gzi(2)*mdept(2)*ki(2))^2;
        for k = 3:1:45
          ri(k)	=	(gzi(k)*mdept(k)*ki(k-2)*ki(k))^2;
        end
        ri(46)	=	(gzi(46)*mdept(46)*ki(44))^2;
        ri(47)	=	(gzi(47)*mdept(47)*ki(45))^2;
        R		=	Cal*sum(ri);

        SPL = mean(rms(dataIn));
        if SPL > 0
          SPL = mag2db(SPL)+83; % -20 dBFS <--> 60 dB SPL
        else
          SPL = -400;
        end

        % matrices to return
        R_mat(windowNum) = R;
        ri_mat(1:47,windowNum) = ri;
        SPL_mat(windowNum) = SPL;
        
        startIndex = startIndex+N;
        endIndex = endIndex+N;
        TimePoints(windowNum,1) = currentTimePoint;
    end

end

%%%%%%%%%%%%%%%%%%%%%%
% END process window %
%%%%%%%%%%%%%%%%%%%%%%

% *************************************************************************
    % Data Presentation
    % *************************************************************************
    
    % ********* TABLES *********
    
    % Roughness statistics, adopted from Loudness_MG2b code
    Rmean = mean(mean(ri_mat,2));
    Rstd = std(mean(ri_mat,2));
    Rmax = max(mean(ri_mat,2));
    R1 = prctile(mean(ri_mat,2),99);
    R2 = prctile(mean(ri_mat,2),98);
    R3 = prctile(mean(ri_mat,2),97);
    R4 = prctile(mean(ri_mat,2),96);
    R5 = prctile(mean(ri_mat,2),95);
    R10 = prctile(mean(ri_mat,2),90);
    R20 = prctile(mean(ri_mat,2),80);
    R30 = prctile(mean(ri_mat,2),70);
    R40 = prctile(mean(ri_mat,2),60);
    R50 = median(mean(ri_mat,2));
    R60 = prctile(mean(ri_mat,2),40);
    R70 = prctile(mean(ri_mat,2),30);
    R80 = prctile(mean(ri_mat,2),20);
    R90 = prctile(mean(ri_mat,2),10);
    Rmin = min(mean(ri_mat,2));
    
    dataR = [Rmean;Rstd;Rmax;R1;R2;R3;R4;R5;R10;R20;R30;R40;R50;R60;R70;R80;R90;Rmin];
    
    % generate tables of results
    
    fig1 = figure('Name','Time-varying Roughness (D&W) Statistics');
    table1 = uitable('Data',dataR,...
        'ColumnName',{'Roughness'},...
        'RowName',{'Mean','Standard deviation','Maximum',...
        'R1','R2','R3','R4',...
        'R5','R10','R20','R30','R40','R50 (median)','R60',...
        'R70','R80','R90','Minimum'});
    
    [~,tables] = disptables(fig1,table1); % AARAE function
    
    OUT.tables = tables;
    
    % ********* CHARTS *********
    % Figure for charts
    figure('Name',['Roughness (D&W) of ',name])
    
    subplot(2,2,1:2)
    
     % Time-varying roughness
    plot(TimePoints,R_mat,'r-');
    title ('Time-Varying Roughness');
    xlabel('Time (s)');
    ylabel('Rouhghness (aspers)');
    
    % Time-averaged roughness as a fucntion of critical band
    % figure
    subplot(2,2,4)
    plot([1:47]'/2, mean(ri_mat,2),'r-');
    ax=gca;
    ax.Title.String = 'Time-Averaged Roughness';
    ax.XLabel.String = 'Critical Band Rate (Bark)';
%     ax.XLim = [0 length(T_spec_N)+10];
%     ax.XTickLabel = {'0','5','10','15','20','25'};
    ax.YLabel.String = 'Specific Roughness (aspers/Bark)';
    hold off;
 
    % Specific roughness spectrogram
    subplot(2,2,3)
    imagesc(TimePoints, 0.1:0.1:24,mean(ri_mat,2));
%     cH = colorbar;
    set(gca,'YDir','normal');
    ax=gca;
    axis tight;
    ax.Title.String = 'Specific Roughness';
    ax.XLabel.String = 'Time (s)';
    ax.YLabel.String = 'Critical Band Rate (Bark)';
    hold off;
    
  % ******** AARAE RESULTS LEAVES **********
    if isstruct(IN)
        % Time-varying roughness results leaf
        doresultleaf(R_mat','Roughness [asper]',{'time'},...
            'Time',TimePoints','s',true,...
            'roughnesstype', {'Roughness over time'}, 'categorical',[],...
            'name','Time_varying_roughness');

        % Time-averaged Specific roughness results leaf
        doresultleaf(mean(ri_mat,2),'Specific Roughness [sones/Bark]',{'Critical Band Rate'},...
            'Critical Band Rate',[1:47]'/2,'Bark',true,...
            'roughnesstype', {'Roughness over critical band'}, 'categorical', [],...
            'name','Time_averaged_specific_roughness');
        
        % Specific roughness spectrogram results leaf
        doresultleaf(ri_mat','Specific Roughness [sones/Bark]',{'time','Critical Band Rate'},...
            'Critical Band Rate',[1:47]'/2,'Bark',true,...
            'Time',TimePoints','s',true,...
            'roughnesstype', {'Roughness over critical band'}, 'categorical', [],...
            'name','Time_varying_specific_roughness');
        
    end
    
    OUT.funcallback.name = 'RoughnessDW.m';
    OUT.funcallback.inarg = {ov,fs,cal};
    
else
    OUT = [];
end



%**************************************************************************
% Copyright (c) <YEAR>, <OWNER>
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
%  * Neither the name of the <ORGANISATION> nor the names of its contributors
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