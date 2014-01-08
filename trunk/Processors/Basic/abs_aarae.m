function out = abs_aarae(in)
% The input audio waveform is rectified, or if a complex waveform is input
% then its magnitude is returned.
    out = abs(in.audio);
end