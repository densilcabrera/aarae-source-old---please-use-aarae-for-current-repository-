function OUT = imagesource_rectangular_room_demo(Lx,Ly,Lz,xs,ys,zs,xr,yr,zr,c,jitter,maxorder,ambiorder)
% image-source model for a rectangular room, by Densil Cabrera
% written for demonstration purposes
%
% creates an impulse response of a rectangular room that has dimensions of
% Lx, Ly and Lz.
% the coordinate system's origin is in a corner of the room, and all
% coordinates within the room are positive
% (xs,ys,zs) are the coordinates of the source
% (xr,yr,zr) are the coordinates of the receiver
% If source and receiver are co-located, then the direct sound is not included
% in the impulse response.
% c is the speed of sound
% jitter introduces a random offset to each reflection time (and consequently amplitude)
% (try a value of 0.1 m). Jitter is not applied to the direct sound.
% maxorder is the maximum order of the image source calculations
% ambiorder is the ambisonics order (0 - 7). A value of 0 yields a single
% (omnidirectional) channel.
%
% Edit the absorption coefficients directly in the code (filtHzalpha). The
% absorption coefficient values are applied to all surfaces.
%
% The function calculates the time and amplitude of the highest order
% reflections first, and this is filtered by the wall reflection filter,
% before the next highest order reflections are added to it, and the wave
% filtered again. This continues until the direct sound is reached (which
% is not filtered by a wall reflection).
%
% a dissipation (air absorption) filter has not yet been implemented.

if nargin < 13, ambiorder = 0; end % ambisonics order of 0 yields 1 omnidirectional channel
if nargin < 12, maxorder = 50; end % maximum reflection order calculated
if nargin < 11, jitter = 0; end % jitter standard deviation in metres (random offset to timing of reflections)
if nargin < 10, c = 344; end % speed of sound

if nargin < 9
    % default receiver position (room dimensions should be larger)
    xr = 1;
    yr = 1;
    zr = 1;
end

if nargin < 6
    % default source position (in the corner of the room)
    xs = 0;
    ys = 0;
    zs = 0;
end

if nargin < 3
    % input via dialog box
    % default room dimensions (Uni of Sydney reverberant room)
    Lx = 6.35;
    Ly = 5.1;
    Lz = 4;
    
    fs = 44100; % default sampling rate of generated wave
    
    % dialog box for settings
    prompt = {'Length, width and height of the room or box (m)', ...
        'Coordinates of the source (m)', ...
        'Coordinates of the receiver (m)', ...
        'Speed of sound (m/s)', ... 
        'Spatial jitter of reflections (m)', ...
        'Maximum order of reflections', ...
        'Ambisonics order', ...
        'Sampling rate (Hz)'};
    dlg_title = 'Settings';
    num_lines = 1;
    def = {[num2str(Lx),', ',num2str(Ly),', ',num2str(Lz)], ...
        [num2str(xs),', ',num2str(ys),', ',num2str(zs)], ...
        [num2str(xr),', ',num2str(yr),', ',num2str(zr)], ...
        num2str(c), num2str(jitter), num2str(maxorder), ...
        num2str(ambiorder), num2str(fs)};
    answer = inputdlg(prompt,dlg_title,num_lines,def);
    
    if isempty(answer)
        OUT = [];
        return
    else
        L = str2num(answer{1,1});
        Lx = L(1); Ly = L(2); Lz = L(3);
        s = str2num(answer{2,1});
        xs = s(1); ys = s(2); zs = s(3);
        r = str2num(answer{3,1});
        xr = s(1); yr = s(2); zr = s(3);
        c = str2num(answer{4,1});
        jitter = str2num(answer{5,1});
        maxorder = str2num(answer{6,1});
        ambiorder = str2num(answer{7,1});
        fs = str2num(answer{8,1});
    end
    
end



% number of channels
nchans = (ambiorder + 1)^2;
if nchans > 64, nchans = 64; end

% generate filter to simulate a single wall reflection. Edit the octave
% band absorption coefficents in the second column below
filtHzalpha = ...
    [0      1;
    31.5	0.01;
    63      0.01;
    125     0.01;
    250     0.01;
    500     0.02;
    1000	0.03;
    2000	0.05;
    4000	0.07;
    8000	0.09;
    16000	0.6
    fs/2    1];

% filterorder is one less than the number of 'a' coefficients
% (feedback taps, which are in the denominator) and 'b' coefficients (in the
% numerator). By increasing the filter order you can increase the accuracy
% of the filter's magnitude response, but this also affects the time and
% phase response of the filter.
filterorder = 6;

% Absorption coefficients (alpha) are converted to reflection coefficients
% (1-alpha), and then the square root is taken to convert to a pressure
% coefficient.
[b,a]=yulewalk(filterorder,filtHzalpha(:,1)./(0.5*fs),(1-filtHzalpha(:,2)).^0.5);

% pre-allocate zeros to output wave
out =  zeros(ceil(fs / c * max([Lx,Ly,Lz]) * (maxorder + 2)) , nchans);

% generally it is preferable not to use for loops in Matlab if there is a
% vectorized alternative availble. Vectorized code tends to use more memory
% but is faster to run. The below uses nested for loops anyway...
for o = 1:maxorder + 1
    order = maxorder + 1 - o; % reflection order
    for nx = -order:order
        x = Lx*(nx+mod(nx,2))+xs*(-2*mod(nx,2)+1); % x coordinate
        for ny = -(order-abs(nx)):order-abs(nx)
            y = Ly*(ny+mod(ny,2))+ys*(-2*mod(ny,2)+1); % y coordinate
            for nz = [-(order-(abs(nx)+abs(ny))),order-(abs(nx)+abs(ny))]
                z = Lz*(nz+mod(nz,2))+zs*(-2*mod(nz,2)+1); % z coordinate
                [theta phi r] = cart2sph(x-xr,y-yr,z-zr); % angle & distance of image-source to receiver
                if order ~= 0
                    r = r + jitter*randn; % distance with jitter (but don't jitter the direct sound)
                end % if order ~= 0
                k = round(r * fs / c)+1; % sample number
                % the following avoids jitter overshoot, and also avoids
                % infinite amplitude at r = 0
                if k>1 && k <=length(out)
                    for ch = 1:nchans
                        out(k, ch) = out(k, ch) + 1/r * spherharmonic(ch, theta, phi); % 1/r is amplitude
                    end % for ch =
                end % if k>=1
            end % for nz =
        end % for ny =
    end % for nx =
    if o <= maxorder
        out = filter(b,a,out); % filter IR for each order
    end %if o <= maxorder
end

% Gains for ambisonics channels
ambichangain = [1, ...
    3^0.5, 3^0.5, 3^0.5, ...
    15^0.5 /2, 15^0.5 /2, 5^0.5 /2, 15^0.5 /2, 15^0.5 /2, ...
    (35/8)^0.5,  105^0.5 /2,  (21/8)^0.5,  7^0.5/2,  (21/8)^0.5,  105^0.5 /2,  (35/8)^0.5, ...
    3/8*35^0.5, 3/2*(35/2)^0.5, 3/4*5^0.5, 3/4*(5/2)^0.5, 3/8, 3/4*(5/2)^0.5, 3/4*5^0.5, 3/2*(35/2)^0.5, 3/8*35^0.5, ...
    3/8*(77/2)^0.5, 3/8*385^0.5, 1/8*(385/2)^0.5, 1155^0.5/4, 165^0.5/8, 11^0.5/8, 165^0.5/8, 1155^0.5/4, 1/8*(385/2)^0.5, 3/8*385^0.5, 3/8*(77/2)^0.5, ...
    1/16*(3003/2)^0.5, 3/8*(1001/2)^0.5, 3/16*91^0.5, 1/8*(1365/2)^0.5, 1/16*(1365/2)^0.5,1/16*273^0.5, 13^0.5/16, 1/16*273^0.5, 1/16*(1365/2)^0.5, 1/8*(1365/2)^0.5, 3/16*91^0.5, 3/8*(1001/2)^0.5, 1/16*(3003/2)^0.5, ...
    3/32*715^0.5, 3/16*(5005/2)^0.5, 3/32*385^0.5, 3/16*385^0.5, 3/32*35^0.5, 3/16*(35/2)^0.5, 1/32*105^0.5, 1/16*15^0.5, 1/32*105^0.5, 3/16*(35/2)^0.5, 3/32*35^0.5, 3/16*385^0.5, 3/32*385^0.5, 3/16*(5005/2)^0.5, 3/32*715^0.5];
% apply channel gains
OUT.audio = out .* repmat(ambichangain(1:nchans),length(out),1);
OUT.fs = fs;
OUT.chanID = cellstr([repmat('Chan',size(OUT.audio,2),1) num2str((1:size(OUT.audio,2))')]);

% AIR ABSORPTION FILTER
% This could be implemented by filtering the IR into a number of bands, and
% applying a decreasing gain funtion over time for each (the slope of which
% depends on the frequency of the band), and then recombining the bands.
% However, from a pragmatic perspective, it is more efficient to factor
% air absorption into the room surface absorption coefficients.

% BASIC ACOUSTICAL PARAMETERS (BROADBAND)
% Schroeder reverse integration
decay = 10*log10(flipud(cumsum(flipud(out(:,1).^2))));
G = decay(1)+20; % strength factor
decay = decay - max(decay);
Tstart = find(decay <= -5, 1, 'first'); % -5 dB
T20end = find(decay <= -25, 1, 'first'); % -25 dB
T30end = find(decay <= -35, 1, 'first'); % -35 dB
p = polyfit((Tstart:T20end)', decay(Tstart:T20end),1); %linear regression
T20 = 3*((p(2)-25)/p(1)-(p(2)-5)/p(1))/fs; % reverberation time, T20
q = polyfit((Tstart:T30end)', decay(Tstart:T30end),1); %linear regression
T30 = 2*((q(2)-35)/q(1)-(q(2)-5)/q(1))/fs; % reverberation time, T20
IRstart = find(decay < 0, 1, 'first'); % direct sound
C50 = 10*log10(1-10^(decay(IRstart+0.05*fs))/10)-decay(IRstart+0.05*fs); % clarity index
%disp(['G ',num2str(G,3),' dB    T20 ',num2str(T20,3),' s    T30 ',num2str(T30,3),' s    C50 ',num2str(C50,3),' dB'])


% visualisation and auralization
figure
subplot(3,1,1)
plot(((1:length(out(:,1)))-1)./fs,out(:,1),'r')
xlabel('Time (s)')
ylabel('Amplitude')

subplot(3,1,2)
plot(((1:length(out(:,1)))-1)./fs,decay,'g')
hold on
plot(((Tstart:T20end)-1)./fs,((Tstart:T20end)-1).*p(1)+p(2),'b')
plot(((Tstart:T30end)-1)./fs,((Tstart:T30end)-1).*q(1)+q(2),'r')
ylim([-100 0])
xlabel('Time (s)')
ylabel('Reverse-Integrated Level (dB)')
hold off

fftlen = fs*10; % 0.1 Hz resolution
magspectrum = 10*log10(abs(fft(out(:,1),fftlen)).^2);
plotcomponents = 1:floor(fftlen/2);
subplot(3,1,3)
plot((plotcomponents-1)./10,magspectrum(plotcomponents),'k')
xlim ([0 200])
xlabel('Frequency (Hz)')
ylabel('Level (dB)')

msgbox({['G     ',num2str(G,3),' dB'];['T20 ',num2str(T20,3),' s'];['T30 ',num2str(T30,3),' s'];['C50 ',num2str(C50,3),' dB']},'Result')

sound(out(:,1)./max(abs(out(:,1))),fs) % play normalized sound wave (ch1 only)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function coef = spherharmonic(ch, theta, phi)
% Based on http://ambisonics.ch/standards/channels/index
% The gain coefficients (normalisation) are not included here - they are
% listed in ambichangain, within the main function.
%
% A succinct alternative to the below hand-written code is to use
% legendre. However the verbose equations below are useful in showing how
% this works.
switch ch
    % Zeroth degree
    case 1
        % W (0,0)
        coef = phi.^0;
        
        
        % First degree
    case 2
        % Y (-1,1)
        coef = cos(phi) .* sin(theta);
    case 3
        % Z (1,0)
        coef = sin(phi);
    case 4
        % X (1,1)
        coef = cos(phi) .* cos(theta);
        
        
        % Second degree
    case 5
        % V (2,-2)
        coef = cos(phi).^2 .* sin(2.*theta);
    case 6
        % T (2,-1)
        coef = sin(2.*phi) .* sin(theta);
    case 7
        % R (2,0)
        coef = (3.* sin(phi).^2 - 1);
    case 8
        % S (2,1)
        coef = sin(2.*phi) .* cos(theta);
    case 9
        % U (2,2)
        coef = cos(phi).^2 .* cos(2.*theta);
        
        
        % Third degree
    case 10
        % Q (3,-3)
        coef = cos(phi).^3 .* sin(3.*theta);
    case 11
        % O (3,-2)
        coef = sin(phi) .* cos(phi).^2 .* sin(2.*theta);
    case 12
        % M (3,-1)
        coef = cos(phi) .* (5 .* sin(phi).^2 - 1) .* sin(theta);
    case 13
        % K (3,0)
        coef = sin(phi) .* (5 .* sin(phi).^2 -3);
    case 14
        % L (3,1)
        coef = cos(phi) .* (5 .* sin(phi).^2 - 1) .* cos(theta);
    case 15
        % N (3,2)
        coef = sin(phi) .* cos(phi).^2 .* cos(2.*theta);
    case 16
        % P (3,3)
        coef = cos(phi).^3 .* cos(3.*theta);
        
        
        % Fourth degree
    case 17
        % (4,-4)
        coef = cos(phi).^4 .* sin(4.*theta);
    case 18
        % (4,-3)
        coef = sin(phi) .* cos(phi).^3 .* sin(3.*theta);
    case 19
        % (4,-2)
        coef = (7.*sin(phi).^2-1).*cos(phi).^2 .* sin(2.*theta);
    case 20
        % (4,-1)
        coef = sin(2.*phi).*(7.*sin(phi).^2-3).*sin(theta);
    case 21
        % (4,0)
        coef = (35.*sin(phi).^4 - 30.*sin(phi).^2 +3);
    case 22
        % (4,1)
        coef = sin(2.*phi) .* (7.*sin(phi).^2-3).*cos(theta);
    case 23
        % (4,2)
        coef = (7.*sin(phi).^2-1).*cos(phi).^2 .* cos(2.*theta);
    case 24
        % (4,3)
        coef = sin(phi) .* cos(phi).^3 .* cos(3.*theta);
    case 25
        % (4,4)
        coef = cos(phi).^4 .* cos(4.*theta);
        
        
        % Fifth degree
    case 26
        % (5,-5)
        coef = cos(phi).^5 .* sin(5.*theta);
    case 27
        % (5,-4)
        coef = sin(phi) .* cos(phi).^4 .* sin(4.*theta);
    case 28
        % (5,-3)
        coef = (9 .* sin(phi).^2 -1) .* cos(phi).^3 .* sin(3.*theta);
    case 29
        % (5,-2)
        coef = sin(phi) .* (3 .* sin(phi).^2 - 1) .* cos (phi).^2 .* sin(2.*theta);
    case 30
        % (5,-1)
        coef = (21 .* sin(phi).^4 - 14 .* sin(phi).^2 +1) .* cos(phi) .* sin(theta);
    case 31
        % (5,0)
        coef = (63 .* sin(phi).^5 - 70 .* sin(phi).^3 + 15 .* sin(phi));
    case 32
        % (5,1)
        coef = (21 .* sin(phi).^4 - 14 .* sin(phi).^2 +1) .* cos(phi) .* cos(theta);
    case 33
        % (5,2)
        coef = sin(phi) .* (3 .* sin(phi).^2 - 1) .* cos (phi).^2 .* cos(2.*theta);
    case 34
        % (5,3)
        coef = (9 .* sin(phi).^2 -1) .* cos(phi).^3 .* cos(3.*theta);
    case 35
        % (5,4)
        coef = sin(phi) .* cos(phi).^4 .* cos(4.*theta);
    case 36
        % (5,5)
        coef = cos(phi).^5 .* cos(5.*theta);
        
        
        % Sixth degree
    case 37
        % (6,-6)
        coef = cos(phi).^6 .* sin(6.*theta);
    case 38
        % (6,-5)
        coef = sin(phi) .* cos(phi).^5 .* sin(5.*theta);
    case 39
        % (6,-4)
        coef = (11.*sin(phi).^2 -1) .* cos(phi).^4 .* sin(4.*theta);
    case 40
        % (6,-3)
        coef = sin(phi) .* (11.*sin(phi).^2 - 3) .* cos(phi).^3 .* sin(3.*theta);
    case 41
        % (6,-2)
        coef = (33 .* sin(phi).^4 - 18 .* sin(phi).^2 +1) .* cos(phi).^2 .* sin(2.*theta);
    case 42
        % (6,-1)
        coef = sin(2.*phi) .* (33 .* sin(phi).^4 - 30 .* sin(phi).^2 + 5) .* sin(theta);
    case 43
        % (6,0)
        coef = (231 .* sin(phi).^6 - 315 .* sin(phi).^4 + 105.*sin(phi).^2 -5);
    case 44
        % (6,1)
        coef = sin(2.*phi) .* (33 .* sin(phi).^4 - 30 .* sin(phi).^2 + 5) .* cos(theta);
    case 45
        % (6,2)
        coef = (33 .* sin(phi).^4 - 18 .* sin(phi).^2 +1) .* cos(phi).^2 .* cos(2.*theta);
    case 46
        % (6,3)
        coef = sin(phi) .* (11.*sin(phi).^2 - 3) .* cos(phi).^3 .* cos(3.*theta);
    case 47
        % (6,4)
        coef = (11.*sin(phi).^2 -1) .* cos(phi).^4 .* cos(4.*theta);
    case 48
        % (6,5)
        coef = sin(phi) .* cos(phi).^5 .* cos(5.*theta);
    case 49
        % (6,6)
        coef = cos(phi).^6 .* cos(6.*theta);
        
        % Seventh degree
    case 50
        % (7,-7)
        coef = cos(phi).^7 .* sin(7.*theta);
    case 51
        % (7,-6)
        coef = sin(phi) .* cos(phi).^6 .* sin(6.*theta);
    case 52
        % (7,-5)
        coef = (13.*sin(phi).^2 - 1) .* cos(phi).^5 .* sin(5.*theta);
    case 53
        % (7,-4)
        coef = (13 .* sin(phi).^3 - 3.*sin(phi)) .* cos(phi).^4 .* sin(4.*theta);
    case 54
        % (7,-3)
        coef = (143 .* sin(phi).^4 - 66 .* sin(phi).^2 + 3) .* cos(phi).^3 .* sin(3.*theta);
    case 55
        % (7,-2)
        coef = (143 .* sin(phi).^5 - 110.*sin(phi).^3 + 15 .* sin(phi)) .* cos(phi).^2 .* sin(2.*theta);
    case 56
        % (7,-1)
        coef = (429 .* sin(phi).^6 - 495.*sin(phi).^4 + 135 .* sin(phi).^2 -5) .* cos(phi) .* sin(theta);
    case 57
        % (7,0)
        coef = (429 .* sin(phi).^7 - 693.*sin(phi).^5 + 315.*sin(phi).^3 - 35.*sin(phi));
    case 58
        % (7,1)
        coef = (429 .* sin(phi).^6 - 495.*sin(phi).^4 + 135 .* sin(phi).^2 -5) .* cos(phi) .* cos(theta);
    case 59
        % (7,2)
        coef = (143 .* sin(phi).^5 - 110.*sin(phi).^3 + 15 .* sin(phi)) .* cos(phi).^2 .* cos(2.*theta);
    case 60
        % (7,3)
        coef = (143 .* sin(phi).^4 - 66 .* sin(phi).^2 + 3) .* cos(phi).^3 .* cos(3.*theta);
    case 61
        % (7,4)
        coef = (13 .* sin(phi).^3 - 3.*sin(phi)) .* cos(phi).^4 .* cos(4.*theta);
    case 62
        % (7,5)
        coef = (13.*sin(phi).^2 - 1) .* cos(phi).^5 .* cos(5.*theta);
    case 63
        % (7,6)
        coef = sin(phi) .* cos(phi).^6 .* cos(6.*theta);
    case 64
        % (7,7)
        coef = cos(phi).^7 .* cos(7.*theta);
end