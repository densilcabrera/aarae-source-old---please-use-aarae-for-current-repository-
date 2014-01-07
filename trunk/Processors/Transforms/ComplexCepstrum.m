function out = ComplexCepstrum(in)
% This function returns the complex cepstrum of the input audio
% using Matlab's cceps function.

out.audio = cceps(in.audio);