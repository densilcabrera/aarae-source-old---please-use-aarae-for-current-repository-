function out = zerophase_aarae(in)
% outputs a zero phase version of the input waveform
    out = ifft(abs(fft(in.audio)));
    out.funcallback.name = 'zerophase_aarae.m';
    out.funcallback.inarg = {};
end