function out = angle_aarae(in)
% The angle of the input audio is returned 
% (may be useful for complex signals).
    out.audio = angle(in.audio);
    out.funcallback.name = 'angle_aarae.m';
    out.funcallback.inarg = {};
end