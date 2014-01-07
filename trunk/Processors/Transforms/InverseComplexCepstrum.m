function out = InverseComplexCepstrum(in)
% This function returns the inverse complex cepstrum of the input audio
% using Matlab's icceps function.

out.audio = icceps(in.audio);