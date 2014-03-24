function out = ifftshift_aarae(in)
% Performs Matlab's ifftshift()
    out.audio = ifftshift(in.audio,1);
    out.funcallback.name = 'ifftshift_aarae.m';
    out.funcallback.inarg = {};
end