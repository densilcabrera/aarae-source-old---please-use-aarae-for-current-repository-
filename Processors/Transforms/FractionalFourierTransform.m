function out = FractionalFourierTransform(in)
% This function runs a fractional Fourier transform, using the function by
% meng (2013)

prompt = {'Fractional power'};
dlg_title = 'Settings';
num_lines = 1;
def = {'0.5'};
answer = inputdlg(prompt,dlg_title,num_lines,def);
if isempty(answer)
    out = [];
    return
else
    a = str2double(answer{1,1});
end

out = in;

[~,chans,bands] = size(in.audio);
for ch = 1:chans
    for b = 1:bands
        out.audio(:,ch,b) = frft(in.audio(:,ch,b),a);
    end
end