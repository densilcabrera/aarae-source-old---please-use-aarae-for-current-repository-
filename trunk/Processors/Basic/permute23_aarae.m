function out = permute23_aarae(in)
% The 2nd and third dimensions of the input audio are swapped.
% Hence channels become bands and bands become channels.
    out = permute(in.audio,[1,3,2]);
end