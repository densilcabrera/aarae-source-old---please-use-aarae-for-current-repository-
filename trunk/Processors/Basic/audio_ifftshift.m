function out = audio_ifftshift(in)
% Performs Matlab's ifftshift()
    out = ifftshift(in.audio,1);
end