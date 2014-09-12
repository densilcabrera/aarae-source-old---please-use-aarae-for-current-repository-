function [OUT,varargout] = timealign_from_xcorr(IN,dims,maxlag,lin_or_circ,cthreshold)
% This function aligns the columns of audio in time based on the peak of
% their cross-correlation function with the average of all or a selection
% of columns.
%
% The dims input argument identifies dimensions that are not included in
% the averaging that is used to create the reference waveform. These
% dimensions are therefore time-aligned independently from other
% dimensions. Typically, dimension 3 (which is used in AARAE for bands) is
% not well-suited to cross-correlation-based time-alignment, and so is
% better included in the dims argument.
%
% If all of the available dimensions are listed in dims, then there would
% be nothing to do. So in this circumstance the first column of the audio
% data is used as reference for time-alignment.
%
%
% Code by Densil Cabrera
% 12 September 2014


if isstruct(IN)
    audio = IN.audio;
else
    audio = IN;
end


if ~exist('cthreshold','var')
    cthreshold = 0.5;
end


if ~exist('lin_or_circ','var')
    lin_or_circ = 0;
end


if ~exist('maxlag','var')
    maxlag = 500;
end


if ~exist('dims','var')
    dims = 3;
end




if nargin == 1
    prompt = {'List any dimensions to align independently: channels [2], bands [3], cycles [4], output channel sequence [5]';...
        'Maximum lag in samples';...
        'Circular [0] or linear [1] shift';...
        'Don''t attempt to time-align when correlation coefficient is less than [0:1]'};
    dlg_title = 'Time Alignment Settings';
    num_lines = 1;
    def = {num2str(dims);num2str(maxlag);num2str(lin_or_circ);num2str(cthreshold)};
    answer = inputdlg(prompt,dlg_title,num_lines,def);
    if isempty(answer)
        OUT = [];
        return
    else
        dims = str2num(answer{1});
        maxlag = str2double(answer{2});
        lin_or_circ = str2double(answer{3});
        cthreshold = str2double(answer{4});
    end
end



if ~isempty(audio) && ~isempty(dims)...
        && ~isempty(maxlag) && ~isempty(lin_or_circ)...
        && ~isempty(cthreshold)
    
    [~,chans,bands,dim4,dim5,dim6] = size(audio);
    
    if chans+bands+dim4+dim5+dim6 == 5
        % audio is only one column, so there is nothing to do
        OUT = [];
        return
    end
    
    
    refaudio = audio;
    for n = 2:6
        if isempty(find(dims == n, 1))
            refaudio = mean(refaudio,n);
        end 
    end
    [~,refd2,refd3,refd4,refd5,refd6] = size(refaudio);

    if mean(size(audio) == size(refaudio)) == 1
        % use first column as reference instead
        refaudio = audio(:,1,1,1,1,1);
    end
    
    % zero pad if linear shifting
    if lin_or_circ == 1
        audio = [zeros(maxlag,chans,bands,dim4,dim5,dim6);...
            audio;zeros(maxlag,chans,bands,dim4,dim5,dim6)];
        refaudio = [zeros(maxlag,refd2,refd3,refd4,refd5,refd6);...
            refaudio;...
            zeros(maxlag,refd2,refd3,refd4,refd5,refd6)];
    end

    
    
    % GET LAGS AND SHIFT
    % an alternative to the following would be cross-spectrum (which would
    % not need for loops, but could blow out the calculation size). Consider
    % changing if this is too slow...
    lags = zeros(chans,bands,dim4,dim5,dim6);
    for ch = 1:chans
        for b = 1:bands
            for d4 = 1:dim4
                for d5 = 1:dim5
                    for d6 = 1:dim6
                        [c,lag] = xcorr(audio(:,ch,b,d4,d5,d6),...
                            refaudio(:,min([ch,refd2]),...
                            min([b,refd3]),min([d4,refd4]),...
                            min([d5,refd5]),min([d6,refd6])),...
                            maxlag, 'coeff');
                        if max(c)>=cthreshold
                            lags(ch,b,d4,d5,d6)=lag(c==max(c));
                            audio(:,ch,b,d4,d5,d6) =...
                                circshift(audio(:,ch,b,d4,d5,d6),...
                                -lags(ch,b,d4,d5,d6));
                        end
                    end
                end
            end
        end
    end

    
else
    OUT = [];
    return
end




if isstruct(IN)      
    OUT = IN;
    OUT.audio = audio;
    OUT.properties.lags = lags;
    OUT.funcallback.name = 'timealign_from_xcorr.m';
    OUT.funcallback.inarg = {dims,maxlag,lin_or_circ,cthreshold};
else
    OUT = audio;
    varargout{1} = lags;
end

%**************************************************************************
% Copyright (c) 2014, Densil Cabrera
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