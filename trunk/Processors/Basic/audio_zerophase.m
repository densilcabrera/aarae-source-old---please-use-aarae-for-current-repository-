function out = audio_zerophase(in)
% outputs a zero phase version of the input waveform
    out = ifft(abs(fft(in.audio)));
end