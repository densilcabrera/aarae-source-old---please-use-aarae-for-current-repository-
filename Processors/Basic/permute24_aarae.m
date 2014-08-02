function out = permute24_aarae(in)
% The 2nd and 4th dimensions of the input audio are swapped.
%
% Code by Densil Cabrera & Daniel Jimenez
% version 1.0 (5 November 2013)
if ndims(in.audio) > 1
    out.audio = permute(in.audio,[1,4,3,2]);

    out.chanID = cellstr([repmat('chan ',size(out.audio,2),1) num2str((1:size(out.audio,2))')]);
    
    out.funcallback.name = 'permute24_aarae.m';
    out.funcallback.inarg = {};
else
    out = [];
    h = warndlg('Data is one-dimensional','AARAE info','modal');
    uiwait(h)
end