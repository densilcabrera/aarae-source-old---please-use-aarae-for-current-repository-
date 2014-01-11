function out = permute23_aarae(in)
% The 2nd and third dimensions of the input audio are swapped.
% Hence channels become bands and bands become channels.
% ChanID and bandID fields are also swapped (if they exist).
    out.audio = permute(in.audio,[1,3,2]);

    if isfield(in,'bandID')
        out.chanID = in.bandID;

    end

    if isfield(in,'chanID')
        out.bandID = in.chanID;

    end
end