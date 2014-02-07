function H = minphasefreqdomain(mag)
% this function caclulates the frequency domain complex coefficients 
% equivalent to a minimum phase filter, using a magnitude spectrum as input.

% make sure mag does not contain any zeros, or this won't work!
mag(mag==0) = 1e-99;

[n,chans] = size(mag);
% CALCULATE THE CEPSTRUM, Y
y = real(ifft(log(mag)));

% WINDOW IN CEPSTRUM DOMAIN
w = [1;2*ones(n/2-1,1);ones(1-rem(n,2),1);zeros(n/2-1,1)];
w = repmat(w,[1,chans]);

% GENERATE FREQUENCY DOMAIN COEFFICIENTS
H = exp(fft(w.*y));


% To run this filter, multiply in frequency domain, and then return to time
% domain using real(ifft())