function out = real_aarae(in)
% The real part of the input audio is returned.
    out.audio = real(in.audio);
    out.funcallback.name = 'real_aarae.m';
    out.funcallback.inarg = {};
end