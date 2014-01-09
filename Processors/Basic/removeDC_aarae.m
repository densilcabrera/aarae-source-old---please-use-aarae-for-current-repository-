function out = removeDC_aarae(in)
% This function subtracts the average amplitude of the wave from the wave,
% and this is done independently for each channel and band (if more than
% one exists)

len = size(in.audio,1);
out.audio = in.audio - repmat(mean(in.audio),[len,1,1]);
end