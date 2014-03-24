function out = imaginary_aarae(in)
% The imaginary part of the input audio is returned.
    out.audio = imag(in.audio);
    out.funcallback.name = 'imaginary_aarae.m';
    out.funcallback.inarg = {};
end