function OUT = MicArraysSpecialProcess(IN, fs, mic_coords, cropIR , max_order,method)
% This function can be used to process repeated measurements made with
% microphone transposition and/or rotation. An example of this might be if
% a loudspeaker is repeatedly measured using a turntable to rotate it in
% relation to a fixed arc of microphones.
%
% It is assumed that the repeated measurements are stacked in dimension 4,
% and using this function will make dimension 4 singleton, and will extend
% dimension 2 (either directly by reshaping, or indirectly by HOA
% analysis).
%
% Most simply, the function can be used to reshape the audio matrix into
% channels, with chanIDs created that identify the microphone positions.
%
% Alternatively, the function can be used to derive a spherical harmonic
% (HOA) representation of microphones distributed on a sphere (e.g. around
% a loudspeaker).
%
% To use this processor, a mat file listing the microphone coordinates
% (spherical) for the particular microphone array (with translation and
% rotation steps) must be in the Processors/Beamforming/MicArraysSpecial
% directory (see the examples already present).
%
% This function calls the HOAToolbox by Nicolas Epain.
%
% Code by Densil Cabrera and Luis Miranda
% Version 1.0 (7 September 2014)

if nargin < 6, method = 0; end
if nargin < 5, max_order = 4; end
if nargin < 4, cropIR = 0; end
if nargin < 3, mic_coords = importdata([cd '/Processors/Beamforming/MicArraysSpecial/USydAnechoicRoom2014.mat']); end
if isstruct(IN)
    audio = IN.audio;
    fs = IN.fs;
    if nargin < 4
        param = inputdlg({'Write chanIDs using spherical coordinates in degrees [0]; Write chanIDs using spherical coordinates in radians [1]; Write chanIDs using Cartesian coordinates in degrees [0]; Convert a spherical array of microphone signals to HOA format [3];',...
            'Maximum HOA order (if relevant)',...
            'Apply autocropstart_aarae.m'},...
                       'Input parameters',1,...
                      {num2str(method),num2str(max_order),num2str(cropIR)});
        if isempty(param) || isempty(param{1,1}) || isempty(param{2,1}) || isempty(param{3,1})
            OUT = [];
            return;
        else
            method = str2double(param{1,1});
            max_order = str2double(param{2,1});
            cropIR = str2double(param{3,1});
            if isnan(max_order) || isnan(cropIR), OUT = []; return; end
        end
    end
    if nargin < 3
        mics = what([cd '/Processors/Beamforming/MicArraysSpecial']);
        if isempty(mics.mat), warndlg('No microphone coordinates available. To add new mic coordinate files (*.mat) go to /Processors/Beamforming/MicArraysSpecial','AARAE info','modal'); OUT = []; return; end
        [S,ok] = listdlg('Name','Microphones',...
                         'PromptString','Select microphone coordinates',...
                         'ListString',mics.mat);
        if isempty(S), warndlg('No microphone coordinates selected. To add new mic coordinate files (*.mat) go to /Processors/Beamforming/MicArraysSpecial','AARAE info','modal'); OUT = []; return; end
        mic_coords = importdata([cd '/Processors/Beamforming/MicArraysSpecial/' mics.mat{S,1}]);
        if size(audio,2) ~= size(mic_coords.locations,1), warndlg('The selected microphone coordinates do not match the number of audio channels.','AARAE info','modal'); OUT = []; return; end
    end
else
    if nargin < 2
        fs = inputdlg({'Sampling frequency [samples/s]'},...
                           'Fs',1,{'48000'});
        fs = str2double(char(fs));
    end
    audio = IN;
end

% Pre-treatment IRs
if cropIR == 1,
    audio = autocropstart_aarae(audio,-20,2);
else
    %audio = audio;
end

coords = mic_coords.locations; % the coordinates
format = mic_coords.format; % coordinate format
rotaxis = mic_coords.rotaxis; % axis of rotation
rotstep = mic_coords.rotstep; % angular step of each rotation
if isfield(mic_coords, 'trans')
    trans = mic_coords.trans; % traslation between measurements (zeros for simple rotation)
else
    trans = [0,0,0];
end

if size(mic_coords.locations,2) ~= 3;
    warndlg('Mic coordinates are three columns with spherical or Cartesian coordinates','AARAE info','modal'); OUT = []; return;
end

[len,chans,bands,dim4,dim5,dim6] = size(audio);

% reset cal to 0 dB if it exists
if isstruct(IN)
    if isfield(IN,'cal')
        audio = cal_reset_aarae(audio,0,IN.cal);        
    end
end

% convert to Cart format, with rotation step in degrees
switch format
    case 'deg'
        coords(:,1:2) = pi * coords(:,1:2)./180;
        [coords(:,1),coords(:,2),coords(:,3)] =...
            sph2cart(coords(:,1),coords(:,2),coords(:,3));
    case 'rad'
        [coords(:,1),coords(:,2),coords(:,3)] =...
            sph2cart(coords(:,1),coords(:,2),coords(:,3));
        rotstep = 180*rotstep/pi;
    case 'cart'
        % already in right format
        
    otherwise
        warndlg('Format field not recognised in microphone coordinate mat file. Use ''deg'', ''rad''or ''cart''.','AARAE info','modal'); OUT = []; return;
end

coords = repmat(coords,[dim4,1]);

if dim4 > 1
    for d4 = 2:dim4
        % rotate and translate the microphone coordinates for each step
        coords((d4*(chans-1)+1):end,:) =...
            AxelRot(coords((d4*(chans-1)+1):end,:)', rotstep, rotaxis, [0,0,0])'...
            + repmat(trans,[size(coords((d4*(chans-1)+1):end,:),1),1]);
    end
end



% reshape so that dim4 is concatenated to chans
audio = reshape(audio,[len,chans*dim4,bands,1,dim5,dim6]);

switch method
    case 0
        % chanID using spherical coordinates in degrees
        chanID = makechanID(size(audio,2),2,coords);
    case 1
        % chanID using spherical coordinates in radians
        chanID = makechanID(size(audio,2),3,coords);
    case 2
        % chanID using Cartesian coordinates in metres
        chanID = makechanID(size(audio,2),4,coords);
    case 3
        % In this case we assume that the microphones are distributed
        % approximately equidistant from the sound source, distributed
        % reasonably evenly over the sphere.
        %
        % We need to remove repeated measurements (i.e. at the same
        % location) and measurements that are not at the radius (e.g., some
        % channels might not be part of the spherical array)
        
        % Find typical radius & delete atypical channels
        [~,~,radius] = cart2sph(coords(:,1),coords(:,2),coords(:,3));
        typicalradius = median(radius);
        radiustolerance = 3; % radius tolerance in dB, re inverse square law
        %radiusOK = radius(abs(20*log10(radius./typicalradius))<=radiustolerance);
        radiusOK = true(length(coords),1);
        audio = audio(:,radiusOK); % delete atypical radius audio channels
        coords = coords(radiusOK,:); % delete corresponding atypical coordinates
        
        % find repeat measurements (e.g. at rotation poles) and delete
        % duplicates and near-duplicates
        angletolerance = 0.4; % angle tolerance in degrees
        angletolerance = angletolerance  * pi/180;
        angleOK = ones(length(coords),1);
%         for n = 1:length(coords)-1
%             for m = n+1:length(coords)
%                 theta = subspace(coords(n,:)',coords(m,:)');
%                 if theta < angletolerance
%                     angleOK(m)=0;
%                 end
%             end
%         end
        audio = audio(:,angleOK); % delete close angle audio channels
        coords = coords(angleOK,:); % delete corresponding close coordinates

        % Check that max_order is not impossibly big
        if (max_order+1)^2 > size(audio,2)
            % reduce to maximum possible order for the number of input channels
            max_order = floor(size(audio,2).^0.5)-1;
        end
        
        hoaFmt = GenerateHoaFmt('res2d',max_order,'res3d',max_order) ;
        
        hoaSignals = zeros(length(audio),hoaFmt.nbComp);
        
        [azm,elv] = cart2sph(coords(:,1),coords(:,2),coords(:,3));
        Y = SphericalHarmonicMatrix(hoaFmt,azm,elv);
        
        for I = 1:size(audio,2);
            for J = 1:hoaFmt.nbComp;
                % revisar si se puede hacer matricial
                hoaSignals(:,J) = hoaSignals(:,J) + audio(:,I).*Y(J,I);     
            end
        end
        audio = hoaSignals;
        %chanID = cellstr([repmat('Y ',[size(audio,2),1]),num2str(hoaFmt.index)]);
        chanID = makechanID(size(audio,2),1);
        
        % OTHER CASES TO CONSIDER:
        % reflection for hemispherical measurements with symetry
        % circle measurement - circular harmonics
        % Acoustic holography, etc
end


if isstruct(IN)
    OUT=IN;
    OUT.audio = audio;
    OUT.chanID = chanID;
    OUT.cal = zeros(1,size(OUT.audio,2));
    OUT.funcallback.name = 'MicArraysSpecialProcess.m';
    OUT.funcallback.inarg = {fs, mic_coords, cropIR, max_order};
else
    OUT = audio;
end