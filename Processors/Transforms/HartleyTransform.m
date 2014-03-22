function out = HartleyTransform(in)

X = fft(in.audio);
out.audio = (real(X) - imag(X)) ./ size(X,1).^0.5;
out.funcallback.name = 'HartleyTransform.m';
out.funcallback.inarg = {};