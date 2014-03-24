function out = invert_aarae(in)
% The input audio waveform is multiplied by -1
    out.audio = -in.audio;
    out.funcallback.name = 'invert_aarae.m';
    out.funcallback.inarg = {};
end