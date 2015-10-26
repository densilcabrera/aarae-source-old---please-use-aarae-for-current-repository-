function Y = psychoacoustic1(X)
% This workflow function runs a set of psychoacoustic analysers to derive 
% loudness, sharpness, roughness and pitch from a 1-channel audio input.
%
% If the audio has more than one channel, then the user is prompted to
% specify which to analyse.
%
% If the audio has not been calibrated, then the user is prompted to apply
% calibration (or specify the sound pressure level).



% 1 channel only
X = choose_from_higher_dimensions(X,1,1);




% check that cal field exists
if ~isfield(X,'cal')
    % get the user to calibrate the selected channel
    X = cal_aarae(X);
    if isempty(X)
        Y = [];
        return
    end
end





% LoudnessCF (also calculates sharpness)
HearingLoss = [0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0];
Overlap = 0;
Y = LoudnessCF(X,HearingLoss,Overlap);




% RoughnessDW
Z = RoughnessDW(X);
Y.tables = [Y.tables Z.tables];




% Pitch Terhardt
timestep = 20;
PitchShift = 1;
MINWEIGHT = 0.1;
MMAX =  12;
SPWEIGHT = 0.5;
maxfrequency = 5000;
ATune = 440;
chromaorder = 1;
Z = Terhardt_VirtualPitch(X,timestep,PitchShift,MINWEIGHT,MMAX,SPWEIGHT,maxfrequency,ATune,chromaorder);
Y.tables = [Y.tables Z.tables];




% Loudness MG&B
fs = []; % not used
filtermethod = 1;
cal = []; % not used
faster = 1;
decay = 1000;
doplot = 1;
Z = Loudness_MGB2b(X,fs,filtermethod,cal,faster,decay,doplot);
Y.tables = [Y.tables Z.tables];
