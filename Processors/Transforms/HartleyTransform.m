function out = HartleyTransform(in)
% This function performs the Hartley transfrom of the input audio.
% 
% The Hartley transform is closely related to the Fourier transform,
% but the result of transforming a real signal is entirely real. 
% Furthermore, the Hartley transform is its own inverse transform.

X = fft(in.audio);
%X = fft(real(in.audio)); % alternatively only transform real data
out.audio = (real(X) - imag(X)) ./ size(X,1).^0.5;
out.funcallback.name = 'HartleyTransform.m';
out.funcallback.inarg = {};