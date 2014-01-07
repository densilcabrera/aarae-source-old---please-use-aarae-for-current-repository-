function y = hilbert_envelope_smooth(in, fs, filterlength, invmode, doplot)
% This function applies the Hilbert transform to the input wave, and
% derives the wave's envelope from that. Then the envelope is smoothed
% prior to creating the output signal. The output can be created in two
% ways (invmode):
% invmode == 0: An inverse Hilbert transform is done using the original
% phase data, and the modified envelope data.
% invmode == 1: The envelope derived from the Hilbert transform is
% inverted and multiplied by the original audio.
%
% filterlength is the length of a zero phase smoothing filter (in samples),
% which is implemented using filtfilt. However, if 0 is entered when 
% invmode is also 0, then the envelope is replaced entirely by ones.
%
%
% Code by Densil Cabrera
% version 1.02 (22 December 2013)

if isstruct(in)
    audio = in.audio;
    fs = in.fs;
    
    % Dialog box for settings
    prompt = {'Length of smoothing filter in samples', ...
        'Inverse Hilbert transform (0) or Inverse envelope only (1)',...
        'Plot (0|1)'};
    dlg_title = 'Settings';
    num_lines = 1;
    def = {num2str(round(fs/10)),'1','1'};
    answer = inputdlg(prompt,dlg_title,num_lines,def);
    
    if ~isempty(answer)
        filterlength = round(str2num(answer{1,1}));
        invmode = str2num(answer{2,1});
        doplot = str2num(answer{3,1});
    end
    
    
else
    audio = in;
end



[len, chans, bands] = size(audio);

h = zeros(len, chans, bands);
for b = 1:bands
    h(:,:,b) = hilbert(audio(:,:,b));
end

envelope1 = abs(h);

phase = angle(h);

if filterlength > 0
envelope2 = filtfilt(ones(1,filterlength)/filterlength, 1, envelope1);
elseif invmode == 0
    envelope2 = ones(len, chans, bands);
else
    envelope2 = envelope1;
end

if invmode == 0
    y = envelope2 .* cos(phase);
else
    y = 0.25 * audio ./ envelope2;
end

if doplot
    ymix = mean(y,3); % mixdown of bands if multiband
    sound(ymix./max(max(abs(ymix))),fs)
    t = ((1:len)'-1)/fs;
    
    
    figure('Name', 'Hilbert envelope smoothing')



k = 1; % subplot counter


    for ch = 1:chans
        for b = 1:bands
            subplot(chans,bands,k)
            hold on
            plot(t,audio(:,ch,b),'Color',[0.7 0.7 0.7])
            plot(t,y(:,ch,b),'Color',[0.3 0.3 0.3])
            plot(t,envelope1(:,ch,b),'r')
            plot(t,envelope2(:,ch,b),'b')
            if ch == chans
                xlabel('Time (s)')
            end
            if b == 1
                ylabel(['Chan ',num2str(ch)])
            end
            if ch == 1
                title(['Band ',num2str(b)])
            end
            hold off
            k = k+1;
        end
    end
end

%**************************************************************************
% Copyright (c) 2013, Densil Cabrera
% All rights reserved.
%
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions are
% met:
%
%  * Redistributions of source code must retain the above copyright notice,
%    this list of conditions and the following disclaimer.
%  * Redistributions in binary form must reproduce the above copyright
%    notice, this list of conditions and the following disclaimer in the
%    documentation and/or other materials provided with the distribution.
%  * Neither the name of the University of Sydney nor the names of its contributors
%    may be used to endorse or promote products derived from this software
%    without specific prior written permission.
%
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
% "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
% TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
% PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER
% OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
% EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
% PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
% PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
% LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
% NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
% SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
%**************************************************************************