function out = audio_mixmean(in)
% The input audio waveform is averaged across channels (dimension 2), i.e. a
% mixdown of the channels, by averaging them.
    out.audio = mean(in.audio,2);
    out.chanID = 1;
end