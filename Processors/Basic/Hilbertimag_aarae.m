function out = Hilbertimag_aarae(in)
% A Hilbert transform is applied to the input audio, and its imaginary value
% is returned. Hence a quadrature phase shift is applied to the input audio.
    [len,chans,bands] = size(in.audio);
    out.audio = zeros(len,chans,bands);
    for b = 1:bands
        out.audio(:,:,b) = imag(hilbert(in.audio(:,:,b)));
    end
end