function [OUT,varargout] = octbandfilter_linphase(IN,fs,param,order,zeropad)
% This function does zero and linear phase octave band filtering using a
% single large fft. Rather than brick-wall filters, this implementation
% has Butterworth-like magnitude responses. Hence the 'order' input
% argument determines the slope of the filter skirts, in analogy to
% Butterworth filter orders. Use 6  (36 dB/oct skirts) or more for most
% purposes.
%
% param is a list of octave band centre frequencies (nominal freqencies
% only allowed)
%
% zeropad is the number of samples added both before and after the input
% audio, to capture the filters' (acausal) build-up and decay. Hence a
% non-zero zeropad value will result in a delay, making the filter linear
% rather than zero phase.
%
% Code by Densil Cabrera
% Version 1.00 (22 January 2013)


% Spectral resolution can be increased (or reduced) by adjusting the value
% of minfftlenfactor (below). Increasing it increases the minimum FFT 
% length, which may increase computational load (processing time and memory
% utilization).

% minimum number of spectral compoments up to the lowest octave band fc:
minfftlenfactor = 2000; % adjust this to get the required spectral resolution



if nargin < 5
    zeropad = 0;
else
    zeropad = round(abs(zeropad));
end

if nargin < 4
    order = 6; % default filter pseudo-order
else
    order = abs(order); 
end

if isstruct(IN)
    audio = IN.audio;
    fs = IN.fs;
else
    audio = IN;
end

maxfrq = fs / 2.^1.51; % maximum possible octave band centre frequency
% potential nominal centre frequencies
nominalfreq = [31.5,63,125,250,500,1000, ...
    2000,4000,8000,16000,31500,63000,125000,250000,500000,1000000];

exactfreq = 10.^((15:3:60)/10);
% possible nominal frequencies
nominalfreq = nominalfreq(exactfreq <= maxfrq);
exactfreq = exactfreq(exactfreq <= maxfrq);


if nargin < 3
    param = nominalfreq;
    [S,ok] = listdlg('Name','Octave band filter input parameters',...
        'PromptString','Center frequencies [Hz]',...
        'ListString',[num2str(param') repmat(' Hz',length(param),1)]);
    param = param(S);
    exactfreq = exactfreq(S);
else
    S = zeros(size(param));
    for i = 1:length(param)
        check = find(nominalfreq == param(i));
        if isempty(check), check = 0; end
        S(i) = check;
    end
    if all(S)
        exactfreq = exactfreq(S);
        param = sort(param,'ascend');
        exactfreq = sort(exactfreq,'ascend');
        ok = 1; 
    else
        ok = 0; 
    end
end

if ok == 1 && isstruct(IN) && nargin < 4
    param1 = inputdlg({'Pseudo-Butterworth filer order';... 
        'Number of samples to zero-pad before and after the wave data'},...
        'Filter settings',... 
        [1 60],... 
        {num2str(order);num2str(zeropad)}); 
    
    param1 = str2num(char(param1)); 
    
    if length(param1) < 2, param1 = []; end 
    
    if ~isempty(param1) 
        order = param1(1);
        zeropad = param1(2);
    end
end
    


if ok == 1
    chans = size(audio,2);
    if zeropad > 0
        audio = [zeros(zeropad,chans); audio; zeros(zeropad,chans)];
    end
    
    len = size(audio,1);
    filtered = zeros(len,chans,length(param));
    
    
    
    minfftlen = 2.^nextpow2((fs/min(param)) * minfftlenfactor);
    
    if len >= minfftlen
        fftlen = 2.^nextpow2(len);
    else
        fftlen = minfftlen;
    end
    
    spectrum = fft(audio, fftlen);
    
    
    for b = 1: length(param)
        
        % list of fft component frequencies
        f = ((1:fftlen)'-1) * fs / fftlen;
        
        % index of low cut-off
        flo = exactfreq(b) / 10.^0.15;
        %indlo = find(abs(f(1:end/2)-flo) == min(abs(f(1:end/2)-flo)),1,'first');
        
        % index of high cut-off
        fhi = exactfreq(b) * 10.^0.15;
        %indhi = find(abs(f(1:end/2)-fhi) == min(abs(f(1:end/2)-fhi)),1,'first');
        
        % centre frequency index
        indfc = find(abs(f(1:end/2)-exactfreq(b)) ...
            == min(abs(f(1:end/2)-exactfreq(b))),1,'first');
        
        % magnitude envelope
        
        mag = zeros(fftlen,1); % preallocate and set DC to 0
        
        % below centre frequency
        mag(2:indfc-1) = ...
            (1 ./ (1 + (f(2:indfc-1)./ flo ).^(-2*order))).^0.5;
        
        % from centre frequency to Nyquist frequency
        mag(indfc:fftlen/2+1) = ...
            (1 ./ (1 + (f(indfc:fftlen/2+1)./ fhi ).^(2*order))).^0.5;
        
        mag(fftlen/2+2:end) = flipud(mag(2:fftlen/2));
        
        % apply magnitude coefficients
        bandfiltered = ifft(repmat(mag,[1,chans]) .* spectrum);
        
        % truncate waveform and send to filtered waveform matrix
        filtered(:,:,b) = bandfiltered(1:len,:);
    end
    
    if isstruct(IN) && ~isempty(filtered)
        OUT = IN;
        OUT.audio = filtered;
        OUT.bandID = param;
    else
        OUT = filtered;
    end
    varargout{1} = param;
else
    OUT = [];
end
end % eof