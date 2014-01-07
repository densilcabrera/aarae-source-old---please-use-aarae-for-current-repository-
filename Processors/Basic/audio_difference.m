function out = audio_difference(in)
% The input audio waveform is differenced, similar to differentiation
    out = diff(in.audio);
end