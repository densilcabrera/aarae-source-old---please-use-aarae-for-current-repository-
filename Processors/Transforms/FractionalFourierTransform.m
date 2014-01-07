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

out.audio = frft(in.audio,a);