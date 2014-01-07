function out = audio_angle(in)
% The angle of the input audio is returned 
% (may be useful for complex signals).
    out = angle(in.audio);
end