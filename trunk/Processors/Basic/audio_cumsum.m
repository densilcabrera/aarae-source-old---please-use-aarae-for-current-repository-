function out = audio_cumsum(in)
% Outputs the cumulative sum of the audio input waveform, similar to
% integration of the waveform.
    out = cumsum(in.audio);
end