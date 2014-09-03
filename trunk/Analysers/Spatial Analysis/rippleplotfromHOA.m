function OUT = rippleplotfromHOA(IN,fs,planechoice,start_time,end_time,max_order,hif,lof,smoothlen,valtype,plottype,domain)
% This function creates a ripple plot from HOA encoded data, usually for
% impulse response analysis.
% 
% The ripple plot is a representation of the impulse response (or HOA
% waveform) in a plane: either the horizontal plane, median plane or
% transverse plane.
%
% If the plot is time domain, then the radius from the centre represents
% time (between the start time and the end time, which are user inputs).
% The start time is in the centre, and end time at the edge.
%
% If the plot is frequency domain, then the radius from the centre
% represents frequency (between the low and high cutoff frequencies, which
% are user inputs). The low cutoff frequency is in the centre, and the high
% cutoff frequency at the edge.
%
% In the time domain, values can be represented as the waveform itself, the
% waveform's envelope, or the waveform's envelope expressed in decibels. In
% the frequency domain, values can be represented as the spectrum magnitude
% or the spectrum magnitude expressed in decibels (in frequency domain,
% there is no difference between the VALUES input of 0 and 1, except that
% the former cannot be smoothed).
%
% A smoothing filter can be applied to the plotted data, which can increase
% readability.
%
% When the data size is large, and user parameters are set appropriately,
% the data is downsampled prior to plotting.
%
% This function uses the HOAToolbox, by Nicolas Epain.
%
% Code by Densil Cabrera and Luis Miranda
% Version 1.01 (3 September 2014)



if isstruct(IN)
    hoaSignals = IN.audio;
    fs = IN.fs;
    if isfield(IN,'cal')
        hoaSignals = cal_reset_aarae(hoaSignals,0,cal);
    end
else
    if nargin < 2
        fs = inputdlg({'Sampling frequency [samples/s]'},...
            'Fs',1,{'48000'});
        fs = str2double(char(fs));
    end
    hoaSignals = IN;
end

if abs(size(hoaSignals,2)^0.5 - round(size(hoaSignals,2)^0.5)) >1e-20
    h=warndlg('This audio does not appear to be in HOA format. Unable to analyse with rippleplotfromHOA.','AARAE info','modal');
    uiwait(h)
    OUT = [];
    return
end

maxtime = size(hoaSignals,1)/fs;
if nargin < 12, domain = 0; end
if nargin < 11, plottype = 1; end
if nargin < 10, valtype = 40; end
if nargin < 9, smoothlen = round(4*fs/1000); end
if nargin < 8, lof = 0; end
if nargin < 7, hif = fs/2; end
if nargin < 6, max_order=round(size(hoaSignals,2).^0.5-1); end
if nargin < 5, 
    end_time = 0.1;
    if end_time > maxtime, end_time = maxtime; end
end
if nargin < 4, start_time = 0; end
if nargin < 3, planechoice = 0; end
if isstruct(IN)
    if nargin < 3
        param = inputdlg({'Plane: Horizontal [0]; Median [1]; Transverse [2]',...
            'Start time [s]'...
            'End time [s]'...
            'Maximum order'...
            'High frequency cutoff (Hz)'...
            'Low frequency cutoff (Hz)'...
            'Smoothing filter length (samples)'...
            'VALUES: Raw amplitude [0], Envelope in amplitude [1], Envelope in dB with a range of [2:100] dB'...
            'PLOT TYPE: Mesh [1]; Surfn [2]; Surfl [3]'...
            'Domain: Time [0]; Frequency [1]'},...
            'Input parameters',1,...
            {'0',...
            num2str(start_time),...
            num2str(end_time),...
            num2str(max_order),...
            num2str(fs/2),...
            '0',...
            num2str(round(4*fs/1000)),...
            '40',...
            '3',...
            num2str(domain)});
        if isempty(param) || isempty(param{1,1}) || isempty(param{2,1}) || isempty(param{3,1}) || isempty(param{4,1}) || isempty(param{5,1}) || isempty(param{6,1})
            OUT = [];
            return;
        else
            planechoice = str2double(param{1,1});
            start_time = str2double(param{2,1});
            start_sample = round(start_time*fs);
            if start_sample == 0, start_sample = 1; end
            end_time = str2double(param{3,1});
            end_sample = round(end_time*fs);
            if end_sample >= length(hoaSignals), end_sample = length(hoaSignals); end
            max_order = str2double(param{4,1});
            nchans = (max_order+1)^2;
            if size(hoaSignals,2)>nchans % delete unused channels
                hoaSignals = hoaSignals(:,1:nchans);
            elseif size(hoaSignals,2)<nchans % limit max_order to available channels
                max_order = round(size(hoaSignals,2).^0.5-1);
                if nargin < 2
                    warndlg(['Maximum available order for this audio input is ' num2str(max_order) '.'],'AARAE info','modal');
                end
            end
            hif = str2double(param{5,1});
            lof = str2double(param{6,1});
            smoothlen = round(str2double(param{7,1}));
            valtype = abs(str2double(param{8,1}));
            
            plottype = str2double(param{9,1});
            domain= str2double(param{10,1});
            if isnan(start_time) || isnan(end_time) || isnan(max_order) || isnan(hif) || isnan(lof), OUT = []; return; end
        end
    end
end

if (hif < fs/2 && hif > lof) || (lof > 0 && lof < hif)
    % bandlimit the spectrum
    filterorder = 48;
    hoaSignals = bandpass(hoaSignals, lof, hif, filterorder, fs);
end






hoaFmt = GenerateHoaFmt('res2d',max_order,'res3d',max_order) ;


% 1 deg resolution
step = 2*pi/360;
switch planechoice
    case 1 % median plane
        elev_for_directplot1 = -pi/2:step:pi/2;
        elev_for_directplot2 = pi/2-step:-step:-pi/2;
        azim_for_directplot = [zeros(size(elev_for_directplot1)),...
            pi*ones(size(elev_for_directplot2))];
        elev_for_directplot = [elev_for_directplot1,elev_for_directplot2];
    case 2 % transverse plane
        elev_for_directplot1 = -pi/2:step:pi/2;
        elev_for_directplot2 = pi/2-step:-step:-pi/2;
        azim_for_directplot = [pi/2*ones(size(elev_for_directplot1)),...
            3*pi/2*ones(size(elev_for_directplot2))];
        elev_for_directplot = [elev_for_directplot1,elev_for_directplot2];
    otherwise % horizontal plane
        azim_for_directplot = 0:step:2*pi; % azimuth
        elev_for_directplot = zeros(size(azim_for_directplot)); % elevation
end
numberofdirections = numel(azim_for_directplot);

Y = SphericalHarmonicMatrix(hoaFmt,azim_for_directplot,elev_for_directplot);

hoa2SpkCfg_for_directplot.filters.gainMatrix = Y;
direct_sound_HOA = hoaSignals(start_sample:end_sample,:,:);
bands = size(hoaSignals,3);
beamsignals = zeros(length(direct_sound_HOA),numberofdirections,bands);

for i = 1:size(hoaSignals,2);
    for j = 1:numberofdirections;
        for b = 1:bands
            beamsignals(:,j,b) = beamsignals(:,j,b)+(direct_sound_HOA(:,i,b).*hoa2SpkCfg_for_directplot.filters.gainMatrix(i,j));
        end
    end
end

if domain == 1
    fftlen = length(beamsignals);
    if mod(fftlen,2)==1, fftlen = fftlen+1; end
    beamsignals = abs(fft(beamsignals,fftlen));
        % list of fft component frequencies
    f = ((1:fftlen)'-1) * fs / fftlen;
    
    % index of low cut-off
    indlo = find(abs(f(1:end/2)-lof) == min(abs(f(1:end/2)-lof)),1,'first');
    
    % index of high cut-off
    indhi = find(abs(f(1:end/2)-hif) == min(abs(f(1:end/2)-hif)),1,'first');
    beamsignals = beamsignals(indlo:indhi,:,:);
end


switch valtype
    case 0
        % resample the wave is hif is low enough - to avoid plotting
        % excessively large data (but still oversampling by a factor of 2)
        if round(fs/(hif*4)) > 1 && length(beamsignals)>5000 && domain~=1
            beamsignals = resample(beamsignals,1,round(fs/(hif*4)));
        end
        % no smoothing here for freq domain
    case 1
        beamsignals = abs(beamsignals);
        if smoothlen > 0
            beamsignals = filtfilt(hann(smoothlen),1,beamsignals);
            if smoothlen/fs >=0.002  && length(beamsignals)>5000 && domain ~=1
                beamsignals = resample(beamsignals,1,round(1000*smoothlen/fs));
            end
        end
    otherwise
        % values are in dB, with valtype specifying the range of the data
        beamsignals = beamsignals.^2;
        if smoothlen > 0  && smoothlen < length(beamsignals)/4
            beamsignals = filtfilt(hann(smoothlen),1,beamsignals);
            if smoothlen/fs >=0.002 && length(beamsignals)>5000 && domain ~=1
                beamsignals = resample(beamsignals,1,round(1000*smoothlen/fs));
            end
            beamsignals(beamsignals<=0) = 1e-99;
        end
        beamsignals = 10*log10(beamsignals);
        % apply level range
        dBrange = valtype; % (just for clarity)
        for b = 1:bands
            beamsignals(beamsignals(:,:,b) < max(max(beamsignals(:,:,b)))-dBrange)...
                = max(max(beamsignals(:,:,b)))-dBrange;
        end
end




for b = 1:bands
    figure('color','white');
    switch plottype
        % case 1 is taken care of by 'otherwise'
        case 2
            polarplot3d(beamsignals(:,:,b),'plottype','surfn');
            hold on
            switch valtype
                case {0, 1}
                    valrange = max(max(beamsignals(:,:,b)))-min(min(beamsignals(:,:,b)));
                    plot3([0,0],[0,0],[min(min(beamsignals(:,:,b)))-0.2*valrange,max(max(beamsignals(:,:,b)))+0.2*valrange],'LineWidth',2,'Color',[0.8,0.8,0]);
                    plot3([0,0],[0,0],[min(min(beamsignals(:,:,b)))-0.2*valrange,max(max(beamsignals(:,:,b)))+0.2*valrange],'LineWidth',2,'Color',[0,0,0],'LineStyle','--','Marker','^');
                otherwise
                    plot3([0,0],[0,0],[min(min(beamsignals(:,:,b)))-10,max(max(beamsignals(:,:,b)))+10],'LineWidth',2,'Color',[0.8,0.8,0]);
                    plot3([0,0],[0,0],[min(min(beamsignals(:,:,b)))-10,max(max(beamsignals(:,:,b)))+10],'LineWidth',2,'Color',[0,0,0],'LineStyle','--','Marker','^');
            end
        case 3
            [x,y,z] = polarplot3d(beamsignals(:,:,b),'plottype','off');
            surfl(x,y,z,'light');
            shading interp
            colormap(jet)
            hold on
            switch valtype
                case {0,1}
                    valrange = max(max(z))-min(min(z));
                    plot3([0,0],[0,0],[min(min(z))-0.2*valrange,max(max(z))+0.2*valrange],'LineWidth',2,'Color',[0.8,0.8,0]);
                    plot3([0,0],[0,0],[min(min(z))-0.2*valrange,max(max(z))+0.2*valrange],'LineWidth',2,'Color',[0,0,0],'LineStyle','--','Marker','^');
                otherwise
                    plot3([0,0],[0,0],[min(min(z))-10,max(max(z))+10],'LineWidth',2,'Color',[0.8,0.8,0]);
                    plot3([0,0],[0,0],[min(min(z))-10,max(max(z))+10],'LineWidth',2,'Color',[0,0,0],'LineStyle','--','Marker','^');
            end
        otherwise
            % mesh
            polarplot3d(beamsignals(:,:,b),'plottype','mesh');
            hold on
            switch valtype
                case {0, 1}
                    valrange = max(max(beamsignals(:,:,b)))-min(min(beamsignals(:,:,b)));
                    plot3([0,0],[0,0],[min(min(beamsignals(:,:,b)))-0.2*valrange,max(max(beamsignals(:,:,b)))+0.2*valrange],'LineWidth',2,'Color',[0.8,0.8,0]);
                    plot3([0,0],[0,0],[min(min(beamsignals(:,:,b)))-0.2*valrange,max(max(beamsignals(:,:,b)))+0.2*valrange],'LineWidth',2,'Color',[0,0,0],'LineStyle','--','Marker','^');
                otherwise
                    plot3([0,0],[0,0],[min(min(beamsignals(:,:,b)))-10,max(max(beamsignals(:,:,b)))+10],'LineWidth',2,'Color',[0.8,0.8,0]);
                    plot3([0,0],[0,0],[min(min(beamsignals(:,:,b)))-10,max(max(beamsignals(:,:,b)))+10],'LineWidth',2,'Color',[0,0,0],'LineStyle','--','Marker','^');
            end
    end
    
    titlestring = [num2str(start_time), '-', num2str(end_time),' s, '];
    
    switch planechoice
        case 1
            xlabel('x')
            ylabel('z')
            titlestring = [titlestring, 'Median Plane'];
        case 2
            xlabel('y')
            ylabel('z')
            titlestring = [titlestring, 'Transverse Plane'];
        otherwise
            xlabel('y')
            ylabel('x')
            titlestring = [titlestring, 'Horizontal Plane'];
    end
    
    if domain == 1
        titlestring = [titlestring, ', Frequency domain: ',...
            num2str(lof), ' Hz - ', num2str(hif), ' Hz '];
    else
        titlestring = [titlestring, ', Time domain '];
    end
    
    % Band title
    if isstruct(IN)
        if isfield(IN,'bandID')
            title([num2str(IN.bandID(b)), ' Hz, ', titlestring])
        else
            title(['Band ', num2str(b),', ', titlestring])
        end
    else
        title(['Band ', num2str(b),', ', titlestring])
    end
    
    switch valtype
        case {0,1}
            zlabel('Amplitude')
        otherwise
            zlabel('Level (dB)')
    end
    
end

if isstruct(IN)
    OUT.funcallback.name = 'rippleplotfromHOA.m';
    OUT.funcallback.inarg = {fs,planechoice,start_time,end_time,max_order,hif,lof,smoothlen,valtype,plottype,domain};
else
    OUT = hoaSignals;
end

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2014, Densil Cabrera and Luis Miranda
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
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%