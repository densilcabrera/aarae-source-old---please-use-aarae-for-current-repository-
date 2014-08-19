function OUT = beamplotting(IN,fs,sphere_cover,start_time,end_time,max_order,hif,lof)
% This function creates a plot of spatial energy distribution from spherical
% harmonic encoded (HOA) multichannel audio input data.
%
% If audio is multiband, then a separate plot is created for each band.
%
% Diffusivity of the soundfield is calculated using the Gover and HOA
% covariance methods.
%
% This function uses the HOAToolbox, by Nicholas Epain.
%
% Code by Daniel Jimenez, Luis Miranda and Densil Cabrera
% Version 1.00 (19 August 2014)



if isstruct(IN)
    hoaSignals = IN.audio;
    fs = IN.fs;
else
    if nargin < 2
        fs = inputdlg({'Sampling frequency [samples/s]'},...
                           'Fs',1,{'48000'});
        fs = str2double(char(fs));
    end
    hoaSignals = IN;
end

if nargin < 6, max_order = 4; end
if nargin < 5, end_time = length(hoaSignals)/fs; end
if nargin < 4, start_time = 0; end
if nargin < 3, sphere_cover = 130; end
if isstruct(IN)
    if nargin < 3
        param = inputdlg({'Number of points on the sphere',...
                          'Start time [s]'...
                          'End time [s]'...
                          'Maximum order'...
                          'High frequency cutoff (Hz)'...
                          'Low frequency cutoff (Hz)'},...
                         'Input parameters',1,...
                         {num2str(sphere_cover),...
                          num2str(start_time),...
                          num2str(end_time),...
                          num2str(max_order),...
                          num2str(fs/2),...
                          '0'});
        if isempty(param) || isempty(param{1,1}) || isempty(param{2,1}) || isempty(param{3,1}) || isempty(param{4,1}) || isempty(param{5,1}) || isempty(param{6,1})
            OUT = [];
            return;
        else
            sphere_cover = str2double(param{1,1});
            if sphere_cover>130,sphere_cover = 130;end
            if sphere_cover<4,sphere_cover = 4;end    
            start_time = str2double(param{2,1});
            start_sample = round(start_time*fs);
            if start_sample == 0, start_sample = 1; end
            end_time = str2double(param{3,1});
            end_sample = round(end_time*fs);
            if end_sample >= length(hoaSignals), end_sample = length(hoaSignals); end
            max_order = str2double(param{4,1});
            hif = str2double(param{5,1});
            lof = str2double(param{6,1});
            if isnan(sphere_cover) || isnan(start_time) || isnan(end_time) || isnan(max_order) || isnan(hif) || isnan(lof), OUT = []; return; end
        end
    end
end

if (hif < fs/2 && hif > lof) || (lof > 0 && lof < hif)
    % bandlimit the spectrum
    filterorder = 48;
    hoaSignals = bandpass(hoaSignals, lof, hif, filterorder, fs);
end


[azim_for_directplot,elev_for_directplot] = SphereCovering(sphere_cover);

beams_for_directplot = GenerateSpkFmt('sphCoord',[azim_for_directplot elev_for_directplot ones(sphere_cover,1)]);

hoa2SpkOpt_for_directplot = GenerateHoa2SpkOpt('decodType','basic','sampFreq',fs,'filterLength',128,'transFreq',6000,...
    'transWidth',200,'spkDistCor',false);

hoaFmt = GenerateHoaFmt('res2d',max_order,'res3d',max_order) ;

hoa2SpkCfg_for_directplot = Hoa2SpkDecodingFilters(hoaFmt,beams_for_directplot,hoa2SpkOpt_for_directplot);

%[~, firstarrivalall_hoaSignals] = max(hoaSignals);

%firstarrival_hoaSignals = min(firstarrivalall_hoaSignals);

direct_sound_HOA = hoaSignals(start_sample:end_sample,:,:);

bands = size(hoaSignals,3);

beamsignals_for_directPlot = zeros(length(direct_sound_HOA),sphere_cover,bands);

for i = 1:size(hoaSignals,2);
    for j = 1:sphere_cover;
        for b = 1:bands
            beamsignals_for_directPlot(:,j,b) = beamsignals_for_directPlot(:,j,b)+(direct_sound_HOA(:,i,b).*hoa2SpkCfg_for_directplot.filters.gainMatrix(j,i));
        end
    end
end

[Goverdif,HOAdif] = deal(zeros(bands,1));
for b = 1:bands
    PlotRobinsonProject([azim_for_directplot,elev_for_directplot],mag2db(sum(abs(beamsignals_for_directPlot(:,:,b)))'));
    
    % Diffuseness calculations and display
    Goverdif(b) = GoverDiffuseness(direct_sound_HOA(:,:,b),hoaFmt);
    HOAdif(b) = HoaDiffuseness(direct_sound_HOA(:,:,b),hoaFmt);
    
    % Band title
    if isstruct(IN)
        if isfield(IN,'bandID')
            title([num2str(IN.bandID(b)), ' Hz, Gover dif. ',...
                num2str(Goverdif(b)),', HOA dif. ', num2str(HOAdif(b))])
        else
            title(['Gover dif. ',...
                num2str(Goverdif(b)),', HOA dif. ', num2str(HOAdif(b))])
        end
    else
        title(['Gover dif. ',...
                num2str(Goverdif(b)),', HOA dif. ', num2str(HOAdif(b))])
    end
    
    
    
    
end

if isstruct(IN)
    OUT.funcallback.name = 'beamplotting.m';
    OUT.funcallback.inarg = {fs,sphere_cover,start_time,end_time,max_order,hif,lof};
else
    OUT = hoaSignals;
end

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2014, Daniel Jimenez, Luis Miranda and Densil Cabrera
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