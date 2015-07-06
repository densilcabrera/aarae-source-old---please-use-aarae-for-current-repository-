function [OUT,method,scalingmethod] = convolveaudiowithaudio2(IN,method,scalingmethod)
% This function is used by AARAE's convolve audio with audio2 button
% (called from aarae.m). It can also be called with two input arguments to
% replicate most of what is done by the GUI button (apart from truncation
% of the impulse response). Function calls for this are written to the log
% file.


S = IN.audio;
if ~isequal(size(IN.audio),size(IN.audio2))
    rmsize = size(IN.audio);
    if size(IN.audio,2) ~= size(IN.audio2,2)
        invS = repmat(IN.audio2,[1 rmsize(2:end)]);
    else
        invS = repmat(IN.audio2,[1 1 rmsize(3:end)]);
    end
else
    invS = IN.audio2;
end
%fs = IN.fs;
%nbits = audiodata.nbits;

if isfield(IN,'properties') && isfield(IN.properties,'startflag')
    if ~exist('method','var')
        methoddialog = true;
    elseif isempty(method)
        methoddialog = true;
    else
        methoddialog = false;
    end
    
    
    % SETTINGS
    if methoddialog
        [method,ok] = listdlg('ListString',{'Synchronous average (excluding silent cycle)',...
            'Stack IRs in dimension 4',...
            'Convolve without separating',...
            'Select the cleanest IR (multichannel)',...
            'Select the cleanest single IR (best channel)'},...
            'PromptString','Select the convolution method',...
            'Name','AARAE options',...
            'SelectionMode','single',...
            'ListSize',[300 100]);
    else
        ok = 1;
    end
    if ok == 1
        if ndims(S) > 3 && method == 1
            method = 2;
            average = true;
        else
            average = false;
        end
        startflag = IN.properties.startflag;
        len = startflag(2)-startflag(1);
        switch method
            case 1
                % Synchronous average (excluding silent cycle)
                cyclelen = startflag(2)-1;
                % ignore silent cycle if it exists
                if isfield(IN.properties,'relgain')
                    if isinf(IN.properties.relgain(1))
                        startflag = startflag(2:end);
                    end
                end
                tempS = zeros(cyclelen,size(S,2));
                for j = 1:size(S,2)
                    newS = zeros(cyclelen,length(startflag));
                    for i = 1:length(startflag)
                        newS(:,i) = S(startflag(i):startflag(i)+len-1,j);
                    end
                    tempS(:,j) = mean(newS,2);
                end
                S = tempS;
                %invS = invS(:,size(S,2));
                
                % consider returning the silent cycle somehow...
%                 if isinf(IN.properties.relgain(1))
%                         
%                 end
            case {2, 4, 5}
                % Stack IRs in dimension 4
                indices = cat(2,{1:len*length(startflag)},repmat({':'},1,ndims(S)-1));
                S = S(indices{:});
                sizeS = size(S);
                if length(sizeS) == 2, sizeS = [sizeS,1]; end
                if length(sizeS) < 3
                    newS = zeros([len,sizeS(2:end),length(startflag)]);
                    newinvS = zeros([length(IN.audio2),sizeS(2:end),length(startflag)]);
                else
                    sizeS(1,4) = length(startflag);
                    newS = zeros([len,sizeS(2:end)]);
                    newinvS = zeros([length(IN.audio2),sizeS(2:end)]);
                end
                newindices = repmat({':'},1,ndims(newS));
                for j = 1:size(S,2)
                    indices{1,2} = j;
                    newindices{1,2} = j;
                    newS(newindices{:}) = reshape(S(indices{:}),[len,1,sizeS(3:end)]);
                    newsizeS = size(newS);
                    if size(S,2) == size(IN.audio2,2)
                        newinvS(newindices{:}) = repmat(IN.audio2(:,j),[1 1 newsizeS(3:end)]);
                    else
                        newinvS(newindices{:}) = repmat(IN.audio2,[1 1 newsizeS(3:end)]);
                    end
                end
                S = newS;
                invS = newinvS;
                if average
                    % ignore silent cycle if it exists
                    if isfield(IN.properties,'relgain')
                        if isinf(IN.properties.relgain(1))
                            S = mean(S(:,:,:,2:end,:,:),4);
                            invS = mean(invS(:,:,:,2:end,:,:),4);
                        else
                            S = mean(S,4);
                            invS = mean(invS,4);
                        end
                    else
                    S = mean(S,4);
                    invS = mean(invS,4);
                    end
                end
        end
    else
        return
    end
else
    method = 1;
end


% DO THE CONVOLUTION
if method == 1 || method == 2 || method == 3 || method == 4 || method == 5
    maxsize = 1e6; % this could be a user setting 
                   % (maximum size that can be handled to avoid 
                   % out-of-memory error from convolution process)
    if numel(S) <= maxsize
        S_pad = [S; zeros(size(invS))];
        invS_pad = [invS; zeros(size(S))];
        IR = ifft(fft(S_pad) .* fft(invS_pad)); % this replaces the old function call in the next line, which seems to do twice the zero-padding necessary
        %IR = convolvedemo(S_pad, invS_pad, 2, fs); % Calls convolvedemo.m
    else
        % use nested for-loops instead of doing everything at once (could
        % be very slow!) if the audio is too big for vectorized processing
        [~,chans,bands,dim4,dim5,dim6] = size(S);
        %IR = zeros(2*(length(S)+length(invS))-1,chans,bands,dim4,dim5,dim6);
        IR = zeros(length(S)+length(invS),chans,bands,dim4,dim5,dim6);
        for ch = 1:chans
            for b = 1:bands
                for d4 = 1:dim4
                    for d5 = 1:dim5
                        for d6 = 1:dim6
                            S_pad = [S(:,ch,b,d4,d5,d6);zeros(length(invS),1)];
                            invS_pad = [invS(:,ch,b,d4,d5,d6); zeros(length(S),1)];
                            IR(:,ch,b,d4,d5,d6) = ifft(fft(S_pad) .* fft(invS_pad));
%                             IR(:,ch,b,d4,d5,d6) =...
%                                 convolvedemo(S_pad, invS_pad, 2, fs);
                        end
                    end
                end
            end
        end
    end
    indices = cat(2,{1:length(S_pad)},repmat({':'},1,ndims(IR)-1));
    IR = IR(indices{:});
end



% SCALE THE IR
% Currently the scaling method is not used by aarae.m, but it may be useful
% in future (perhaps with modification).
% One option would be for generators to output a properties.scalingfactor
% field value to be used here.

% scaling
if ~exist('scalingmethod','var')
    scalingmethod = 0; % no scaling
else
    switch scalingmethod
        case 1
            % scale based on length of inverse filter
            scalingfactor = 1/size(IN.audio2,1);
        case 2
            % scale based on squared length of inverse filter
            scalingfactor = 1/size(IN.audio2,1).^2;
        case 3
            % or what about this method?
            scalingfactor = 1/(sum(IN.audio2(:,1,1,1,1,1))*size(IN.audio2,1));
        case 4
            % normalize the IR
            scalingfactor = 1/(max(max(max(max(max(max(abs(IR))))))));
        otherwise
            scalingmethod = 0;
            scalingfactor = 1;
    end
    IR = scalingfactor * IR;
end


% APPLY SELECTION CRITERIA OR OTHER POST-PROCESSING
[len,chans,bands,dim4,dim5,dim6] = size(IR);
switch method
    case 4
        % Automatically select the best IR (multichannel)
        % We define the best IR as the one that has the highest max:rms
        % value
        IRtemp = zeros(len,chans,bands,dim4*dim5*dim6);
        for ch = 1:chans
            for b = 1:bands
                IRtemp(:,ch,b,:) = reshape(IR(:,ch,b,:,:,:),[len, 1, 1, dim4 * dim5 * dim6]);
            end
        end
        Quality = max(IRtemp) ./ rms(IRtemp);
        Quality = mean(Quality,2); % average across channels
        Quality = mean(Quality,3); % average across bands
        [~, ind] = max(Quality,[],4);
        IR = IRtemp(:,:,:,ind);
        
    case 5
        % Automatically select the single best IR (best channel)
        IRtemp = zeros(len,chans*dim4*dim5*dim6,bands);
        for b = 1:bands
            IRtemp(:,:,b) = reshape(IR(:,:,b,:,:,:),[len, chans * dim4 * dim5 * dim6]);
        end
        Quality = max(IRtemp) ./ rms(IRtemp);
        Quality = mean(Quality,3); % average across bands
        [~, ind] = max(Quality,[],2);
        IR = IRtemp(:,ind,:);
end
        


if nargin == 1
    % output audio only
    OUT = IR;
else
    % output AARAE audio structure
    OUT = IN;
    OUT = rmfield(OUT,'audio2');
    OUT.audio = IR;
end