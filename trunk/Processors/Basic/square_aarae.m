function out = square_aarae(in)
% The input audio waveform is squared
    out.audio = in.audio.^2;
    out.funcallback.name = 'square_aarae.m';
    out.funcallback.inarg = {};
end