function out = swapaudiofields_aarae(in)
% The primary and secondary audio fields are swapped - i.e.,
% .audio becomes .audio2, and .audio2 becomes .audio. 
% If .audio2 does not exist, but .audio3 exists, then it is swapped with
% .audio instead.

    if isfield(in, 'audio2')
        out.audio = in.audio2;
        out.audio2 = in.audio;
    elseif isfield(in, 'audio3')
        out.audio = in.audio3;
        out.audio3 = in.audio;
    else
        out = in;
        disp('Unable to swap audio fields because audio2 does not exist')
    end
end