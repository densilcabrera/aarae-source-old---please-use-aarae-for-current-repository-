function out = MinimumPhaseFromRCEPS(in)
% This function returns a minimum phase reconstruction of the input audio
% using Matlab's real cepstrum (rceps) function.

[len, chans, bands] = size(in.audio);

out.audio = zeros(len,chans, bands);

for ch = 1:chans
    for bnd = 1:bands
        [~, out.audio(:,ch,bnd)] = rceps(in.audio(:,ch,bnd));
    end
end

out.funcallback.name = 'MinimumPhaseFromRCEPS.m';
out.funcallback.inarg = {};