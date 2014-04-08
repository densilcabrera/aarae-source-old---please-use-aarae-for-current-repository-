% Generates a exponential sweep and its inverse for IR measurement
%
function OUT = exponential_sweep(dur,start_freq,end_freq,fs)% generates an exponentially swept
% signal S, starting at start_freq Hz and ending at end_freq Hz,
% for duration = dur seconds long, and an
% amplitude of ampl = 0.5, with a raised cosine window applied for rcos_ms = 15 ms.
% Sinv is the inverse of S.
if nargin == 0
    param = inputdlg({'Duration [s]';...
                       'Start frequency [Hz]';...
                       'End frequency [Hz]';...
                       'Sampling Frequency [samples/s]'},...
                       'Sine sweep input parameters',1,{'10';'20';'20000';'48000'});
    param = str2num(char(param));
    if length(param) < 4, param = []; end
    if ~isempty(param)
        dur = param(1);
        start_freq = param(2);
        end_freq = param(3);
        fs = param(4);
    end
else
    param = [];
end
if ~isempty(param) || nargin ~=0
    if ~exist('fs','var')
       fs = 48000;
    end
    SI = 1/fs;
    ampl = 0.5;
    rcos_ms = 15;
    scale_inv = 0;


    w1 = 2*pi*start_freq; w2 = 2*pi*end_freq;
    K = (dur*w1)/(log(w2/w1));
    L = log(w2/w1)/dur;
    t = [0:round(dur/SI)-1]*SI;
    phi = K*(exp(t*L) - 1);
    freq = K*L*exp(t*L);
    freqaxis = freq/(2*pi);
    amp_env = 10.^((log10(0.5))*log2(freq/freq(1)));
    S = ampl*sin(phi);
    rcos_len = round(length(S)*((rcos_ms*1e-3)/dur));
    sig_len = length(S);
    rcoswin = hann(2*rcos_len).';
    S = [S(1:rcos_len).*rcoswin(1:rcos_len),S(rcos_len+1:sig_len-rcos_len),S(sig_len-rcos_len+1:sig_len).*rcoswin((rcos_len+1):(rcos_len*2))];
    Sinv = fliplr(S).*amp_env;

    % correction for allpass delay
    Sinvfft = fft(Sinv);
    Sinvfft = Sinvfft.*exp(1i*2*pi*(0:(sig_len-1))*(sig_len-1)/sig_len);
    Sinv = real(ifft(Sinvfft));

    if scale_inv == 1
       fftS = fft(S);
       mid_freq = (start_freq + end_freq)/2;
       index = round(mid_freq/(fs/sig_len));
       const1 = abs(conj(fftS(index))/(abs(fftS(index))^2));
       const2 = abs(Sinvfft(index));
       ratio = const1/const2;
       Sinv = Sinv * ratio;
    end

    OUT.audio = S';
    OUT.audio2 = Sinv';
    OUT.fs = fs;
    OUT.tag = ['Sine sweep exp' num2str(dur)];
    OUT.properties.dur = dur;
    OUT.properties.freq = [start_freq, end_freq];
    OUT.funcallback.name = 'exponential_sweep.m';
    OUT.funcallback.inarg = {dur,start_freq,end_freq,fs};
else
    OUT = [];
end