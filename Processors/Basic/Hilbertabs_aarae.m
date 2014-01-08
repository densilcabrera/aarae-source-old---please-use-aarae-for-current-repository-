function out = Hilbertabs_aarae(in)
% A Hilbert transform is applied to the input audio, and its absolute value
% is returned. This is a simple way to derive the envelope function
% of the audio.
    [len,chans,bands] = size(in.audio);
    out.audio = zeros(len,chans,bands);
    for b = 1:bands
        out.audio(:,:,b) = abs(hilbert(in.audio(:,:,b)));
    end
end