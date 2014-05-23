function out = cal_reset_aarae(in,outcal)
% This function resets the .cal field of an AARAE audio object to a
% user-specified value. Gain is applied to the underlying audio waveform to
% compensate for the .cal field change. For multichannel audio, this
% function will reset the .cal to be the same for all channels.
%
% Code by Densil Cabrera
% version 1.00 (23 May 2014)

if isstruct(in)
    %audio = in.audio;
   if isfield(in,'cal')
       cal = in.cal;
       [len,chans,bands,dim4,dim5,dim6] = size(in.audio);
       if length(cal) ~= chans
           if length(cal) == 1
               cal = repmat(cal,[1,chans]);
           else
               disp('Cal size does not match audio channels')
               out = [];
               return
           end
       end
   else
       disp('Cal field does not exist')
       out = [];
       return
   end

else
    disp('Input audio must be in an AARAE structure')
    out = [];
    return
end




if nargin == 1
    prompt = {'Desired cal value (dB)'};
    dlg_title = 'Gain';
    num_lines = 1;
    def = {'0'};
    answer = inputdlg(prompt,dlg_title,num_lines,def);
    if ~isempty(answer)
        outcal = str2num(char(answer{1}));
    else
        out = [];
        return
    end
end


if ~isempty(outcal)
    out = in;
    gain = 10.^((cal - outcal)./20);
    out.cal = repmat(outcal,[1,chans]);
    out.audio = out.audio .* repmat(gain,[len,1,bands,dim4,dim5,dim6]);
    % to do: consider how to operate on audio2
    out.funcallback.name = 'cal_reset_aarae.m';
    out.funcallback.inarg = {outcal};
else
    out = [];
end

end