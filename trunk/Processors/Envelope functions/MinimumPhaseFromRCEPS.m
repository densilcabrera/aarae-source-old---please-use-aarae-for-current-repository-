function out = MinimumPhaseFromRCEPS(in)
% This function returns a minimum phase reconstruction of the input audio
% using Matlab's real cepstrum (rceps) function.

[len, chans, bands,dim4,dim5,dim6] = size(in.audio);

out.audio = zeros(len,chans, bands,dim4,dim5,dim6);

for ch = 1:chans
    for bnd = 1:bands
        for d4=1:dim4
            for d5 = 1:dim5
                for d6 = 1:dim6
        [~, out.audio(:,ch,bnd,d4,d5,d6)] = rceps(in.audio(:,ch,bnd,d4,d5,d6));
                end
            end
        end
    end
end

out.funcallback.name = 'MinimumPhaseFromRCEPS.m';
out.funcallback.inarg = {};