function out = reverse_aarae(in)
% The input audio waveform is time-reversed
    out.audio = flipdim(in.audio,1);
    out.funcallback.name = 'reverse_aarae.m';
    out.funcallback.inarg = {};
end