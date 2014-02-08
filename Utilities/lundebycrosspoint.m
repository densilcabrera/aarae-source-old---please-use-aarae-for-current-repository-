function crosspoint = lundebycrosspoint(IR2, fs, fc)
% This function implements the crosspoint finding algorithm
% described in:
% A. Lundeby, T.E. Vigran, H. Bietz and M. Vorlaender, "Uncertainties of
% Measurements in Room Acoustics", Acustica 81, 344-355 (1995)
%
% INPUTS:
% IR2 is a squared IR - can be multi channel and multiband
%
% fs is sampling rate in Hz
%
% fc (optional) is the band centre frequencies
%
% OUTPUT:
% crosspoint is an index corresponding to the IR crosspoint. Each band &
% channel has its own crosspoint (chan in dim 2, band in dim 3).
%
% The main difference in this implementation is that the windows used for
% smoothing the squared decay are implemented with a fftfilt (and so do not
% involve any downsampling). Presumably this should slightly improve the
% curve fitting.
%
% Code by Densil Cabrera
% version 0.00 (8 February 2014) - Beta

% if there are any negative values, assume that the IR has not been squared
if min(min(min(IR2))) < 0
    IR2=IR2.^2;
end

[len,chans,bands] = size(IR2);

% window length for step 1
if ~exist('fc','var') && bands > 1
    winlen = round(0.001*fs*linspace(50,10,bands));
elseif exist('fc','var') && bands > 1
    winlen = zeros(1,bands);
    fc_low = fc<=125;
    winlen(fc_low) = round(0.001*fs*50);
    fc_hi = fc>=8000;
    winlen(fc_hi) = round(0.001*fs*10);
    fc_mid = ~(fc_low | fc_hi);
    if sum(fc_mid) >1
        winlen(fc_mid) = round(0.001*fs*linspace(50,10,sum(fc_mid)));
    elseif sum(fc_mid) ==1
        winlen(fc_mid) = round(0.001*fs*25);
    end
else
    winlen = round(0.001*fs*25);
end



% 1. AVERAGE SQUARED IR IN LOCAL TINE INTERVALS
IR2smooth = IR2; %just for preallocation
for b = 1:bands
    IR2smooth(:,:,b) = fftfilt(ones(winlen(b),1)./winlen(b),IR2(:,:,b));
end
IR2smoothdB =  10*log10(IR2smooth);
maxIR2smoothdB = max(IR2smoothdB);
maxind = ones(1,chans,bands);
for ch = 1:chans
    for b = 1:bands
        maxind(1,ch,b) = find(IR2smoothdB(:,ch,b) == maxIR2smoothdB(1,ch,b),1,'first');
        IR2smoothdB(:,ch,b) = IR2smoothdB(:,ch,b) - maxIR2smoothdB(1,ch,b);
    end
end



% 2. ESTIMATE BACKGROUND NOISE LEVEL USING THE TAIL
IR2tail = mean(IR2(round(0.9*end):end,:,:));
IR2taildB = 10*log10(IR2tail) - maxIR2smoothdB;



% 3. ESTIMATE SLOPE OF DECAY FROM 0 dB TO NOISE LEVEL
o = zeros(2,chans, bands);
crosspoint = zeros(1,chans,bands);
for ch = 1:chans
    for b = 1:bands
        tend = find(IR2smoothdB(maxind(1,ch,b):end,ch,b) <= IR2taildB(1,ch,b), 1, 'first')+maxind(1,ch,b)-1; %
        
        o(:,ch,b) = polyfit((maxind(1,ch,b):tend)', ...
            IR2smoothdB(maxind(1,ch,b):tend,ch,b),1)';
        
        % 4. FIND PRELIMINARY CROSSPOINT
        crosspoint(1,ch,b) = -round((o(2,ch,b)-IR2taildB(1,ch,b))/o(1,ch,b));
        
    end
end



% 5. FIND NEW LOCAL TIME INTERVAL LENGTH
slopelength = crosspoint - maxind;

winlen = zeros(1,chans,bands);
for ch = 1:chans
    if ~exist('fc','var') && bands > 1
        winlen(1,ch,:) = round(slopelength(1,ch,:) ./ (-IR2taildB(1,ch,:) ./permute(linspace(3,10,bands),[1,3,2])));
    elseif exist('fc','var') && bands > 1
        winlen(1,ch,fc_low) = round(slopelength(1,ch,fc_low) ./ (-IR2taildB(1,ch,fc_low) ./3));
        winlen(1,ch,fc_hi) = round(slopelength(1,ch,fc_hi) ./ (-IR2taildB(1,ch,fc_hi) ./10));
        if sum(fc_mid) >1
            winlen(1,ch,fc_mid) = round(slopelength(1,ch,fc_mid) ./ (-IR2taildB(1,ch,fc_mid) ./permute(linspace(3,10,sum(fc_mid)),[1,3,2])));
        elseif sum(fc_mid) ==1
            winlen(1,ch,fc_mid) = round(slopelength(1,ch,fc_mid) ./ (-IR2taildB(1,ch,fc_mid) ./6));
        end
    else
        winlen(1,ch,:) = round(slopelength(1,ch,:) ./ (-IR2taildB(1,ch,:) ./6));
    end
end


% 6. AVERAGE SQUARED IR IN NEW LOCAL TIME INTERVALS
for ch = 1:chans
for b = 1:bands
    IR2smooth(:,ch,b) = fftfilt(ones(winlen(1,ch,b),1)./winlen(1,ch,b),IR2(:,ch,b));
end
end
IR2smoothdB =  10*log10(IR2smooth);
maxIR2smoothdB = max(IR2smoothdB);
maxind = ones(1,chans,bands);
for ch = 1:chans
    for b = 1:bands
        maxind(1,ch,b) = find(IR2smoothdB(:,ch,b) == maxIR2smoothdB(1,ch,b),1,'first');
        IR2smoothdB(:,ch,b) = IR2smoothdB(:,ch,b) - maxIR2smoothdB(1,ch,b);
    end
end




% ITERATE STEPS 7-9
for iter = 1:5
    
    
    % 7. ESTIMATE THE BACKGROUND NOISE LEVEL
    noisefloorindex = zeros(1,chans,bands);
    for ch = 1:chans
        for b = 1:bands
            noisefloorindex(1,ch,b) = round((o(2,ch,b)+IR2taildB(1,ch,b)-10)/o(1,ch,b));
        end
    end
    noisefloorindex(noisefloorindex > round(0.9*len)) = round(0.9*len);
    
    for ch = 1:chans
        for b = 1:bands
            IR2tail(1,ch,b) = mean(IR2(noisefloorindex(1,ch,b):end,ch,b));
            IR2taildB(1,ch,b) = 10*log10(IR2tail(1,ch,b))- maxIR2smoothdB(1,ch,b);
        end
    end
    
    
    
    % 8. ESTIMATE THE LATE DECAY SLOPE
    for ch = 1:chans
        for b = 1:bands
            if IR2taildB(1,ch,b) < -35
                LateSlopeEnddB = IR2taildB(1,ch,b) + 10;
                LateSlopeStartdB = IR2taildB(1,ch,b) + 30;
                ok = true;
            elseif IR2taildB(1,ch,b) < -30
                LateSlopeEnddB = IR2taildB(1,ch,b) + 8.5;
                LateSlopeStartdB = IR2taildB(1,ch,b) + 25;
                ok = true;
            elseif IR2taildB(1,ch,b) < -25
                LateSlopeEnddB = IR2taildB(1,ch,b) + 7;
                LateSlopeStartdB = IR2taildB(1,ch,b) + 20;
                ok = true;
            elseif IR2taildB(1,ch,b) < -20
                LateSlopeEnddB = IR2taildB(1,ch,b) + 6;
                LateSlopeStartdB = IR2taildB(1,ch,b) + 16;
                ok = true;
            elseif IR2taildB(1,ch,b) < -15
                LateSlopeEnddB = IR2taildB(1,ch,b) + 5;
                LateSlopeStartdB = IR2taildB(1,ch,b) + 15;
                ok = true;
            else
                ok = false;
            end
            if ok
                tend = find(IR2smoothdB(maxind(1,ch,b):end,ch,b) <= LateSlopeEnddB, 1, 'first')+maxind(1,ch,b)-1; %
                tstart = find(IR2smoothdB(maxind(1,ch,b):end,ch,b) <= LateSlopeStartdB, 1, 'first')+maxind(1,ch,b)-1; %
                
                o(:,ch,b) = polyfit((tstart:tend)', ...
                    IR2smoothdB(tstart:tend,ch,b),1)';
                
                % 9. FIND NEW CROSSPOINT
                crosspoint(1,ch,b) = -round((o(2,ch,b)-IR2taildB(1,ch,b))/o(1,ch,b));
            end
        end
    end
    
    
    
end

