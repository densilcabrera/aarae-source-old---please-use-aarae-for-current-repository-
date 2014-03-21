function out = Hilbert_Transform(in,method)
% A Hilbert transform is applied to the input audio. Note that the
% resulting analytic waveform is complex. This can be dealt with in three
% ways.

if nargin < 2
method = menu('Output Format', ...
              'Complex wave', ...
              'Real (audio) and Imag (audio1)',...
              'Absolute value');
end
% Matlab's hilbert() seems to only work on up to 2-dimensional data,
% hence the following loop to allow for 3 dimensions
[len,chans,bands] = size(in.audio);
transformed = zeros(len,chans,bands);
for b = 1:bands
    transformed(:,:,b) = hilbert(in.audio(:,:,b));
end

switch method
    case 1
        out.audio = transformed;
    case 2
        out.audio = real(transformed);
        out.audio2 = imag(transformed);
    otherwise
        out.audio = abs(transformed);
end
if isstruct(in)
    out.funcallback.name = 'HilbertTransform.m';
    out.funcallback.inarg = {method};
end