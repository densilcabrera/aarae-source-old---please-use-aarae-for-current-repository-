function out = audio_reverse(in)
% The input audio waveform is time-reversed
    out = flipdim(in.audio,1);
end