function out = bandsum_aarae(in)
% The input audio waveform is summed across bands (dimension 3), i.e. a
% mixdown of the bands, by summing them.
    out.audio = sum(in.audio,3);
    out.bandID = 1;
end