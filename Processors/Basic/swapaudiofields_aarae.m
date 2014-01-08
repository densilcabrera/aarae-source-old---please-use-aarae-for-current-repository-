function out = swapaudiofields_aarae(in)
% The primary and secondary audio fields are swapped - i.e.,
% .audio becomes .audio2, and .audio2 becomes .audio.

    if isfield(in, 'audio2')
        out.audio = in.audio2;
        out.audio2 = in.audio;
    else
        out = in;
        disp('Unable to swap audio fields because audio2 does not exist')
    end
end