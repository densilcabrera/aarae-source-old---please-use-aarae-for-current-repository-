function OUT = phaseshaped_exp_sweep(dur,start_freq,end_freq,overshoot,order,fs,reverse,phase)
% This function generates an exponential sweep and its inverse filter,
% providing for maximum phase and minimum phase solutions (as well as the
% usual zero phase solution). This may be useful in situations where the
% temporal smear of the impulse response is of particular concern (e.g. low
% frequency measurement of highly damped systems).
%
% The default parameters for this sweep are chosen for low frequency
% measurements (between 20 Hz and 500 Hz), using maximum phase. The
% resulting sweep and inverse sweep yield a very high numerical signal to
% noise ratio in the time period immediately following the impulse.
%


if nargin == 0
    param = inputdlg({'Duration [s]';...
                       'Start frequency [Hz]';...
                       'End frequency [Hz]';...
                       'Overshoot (octaves)';...
                       'Filter order';...
                       'Sampling Frequency [samples/s]';...
                       'Ascending [0] or descending [1] sweep';...
                       'Maximum [-1], zero [0] or minimum [1] phase'},...
                       'Sine sweep input parameters',1,{'60';'20';'500';'2';'24';'48000';'0';'-1'});
    param = str2num(char(param));
    if length(param) < 8, param = []; end
    if ~isempty(param)
        dur = param(1);
        start_freq = param(2);
        end_freq = param(3);
        overshoot = param(4);
        order = param(5);
        fs = param(6);
        reverse = param(7);
        phase = param(8);
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
    scale_inv = 0;
    maxfreq = (fs/2) / 2^overshoot; % maximum possible frequency, taking overshoot into account
    if end_freq > maxfreq, end_freq = maxfreq; end
    
    % generate sweep in time domain
    w1 = 2*pi*start_freq / 2^overshoot; w2 = 2*pi*end_freq * 2^overshoot;
    if w2 > pi*fs, w2=pi*fs; end % this should not be necessary
    K = (dur*w1)/(log(w2/w1));
    L = log(w2/w1)/dur;
    t = (0:round(dur/SI)-1)'*SI;
    phi = K*(exp(t*L) - 1);
    freq = K*L*exp(t*L);
    %freqaxis = freq/(2*pi);
    amp_env = 10.^((log10(0.5))*log2(freq/freq(1)));
    S = ampl*sin(phi);
    Sinv = flipud(S).*amp_env;
    
    S = bandpass(S, start_freq, end_freq, order, fs, phase);
    Sinv = bandpass(Sinv, start_freq, end_freq, order, fs, phase);
    
    % clean up the ends in the time domain?
%     win = tukeywin(length(S),0.05);
%     S = S.*win;
%     Sinv = Sinv.*win;
    
%     rcos_len = round(length(S)*((rcos_ms*1e-3)/dur));
     sig_len = length(S);
%     rcoswin = hann(2*rcos_len).';
%     S = [S(1:rcos_len).*rcoswin(1:rcos_len),S(rcos_len+1:sig_len-rcos_len),S(sig_len-rcos_len+1:sig_len).*rcoswin((rcos_len+1):(rcos_len*2))];
%    Sinv = fliplr(S).*amp_env;
    
    % correction for allpass delay
%     Sinvfft = fft(Sinv);
%     Sinvfft = Sinvfft.*exp(1i*2*pi*(0:(sig_len-1))'*(sig_len-1)/sig_len);
%     Sinv = real(ifft(Sinvfft));

    if scale_inv == 1
       fftS = fft(S);
       mid_freq = (start_freq + end_freq)/2;
       index = round(mid_freq/(fs/sig_len));
       const1 = abs(conj(fftS(index))/(abs(fftS(index))^2));
       const2 = abs(Sinvfft(index));
       ratio = const1/const2;
       Sinv = Sinv * ratio;
    end
    
    if reverse
        S = fliplr(S);
        Sinv = fliplr(Sinv);
    end

    OUT.audio = S;
    OUT.audio2 = Sinv;
    OUT.fs = fs;
    OUT.tag = ['Phase-shaped exp sweep' num2str(dur)];
    OUT.properties.dur = dur;
    OUT.properties.sig_len = sig_len;
    OUT.properties.freq = [start_freq, end_freq];
    OUT.properties.reverse = reverse;
    OUT.properties.overshoot = overshoot;
    OUT.properties.filter_order = order;
    OUT.properties.overshoot = phase;
    OUT.funcallback.name = 'phaseshaped_exp_sweep.m';
    OUT.funcallback.inarg = {dur,start_freq,end_freq,overshoot,order,fs,reverse,phase};
else
    OUT = [];
end

% This function is adapted from an exponential sweep function written by
% Nicolas Epain.
%**************************************************************************
% Copyright (c) 2015, Densil Cabrera
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