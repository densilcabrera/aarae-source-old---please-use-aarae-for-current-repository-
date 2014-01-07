function out = InverseFourierTransform(in)

out.audio = ifft(in.audio);