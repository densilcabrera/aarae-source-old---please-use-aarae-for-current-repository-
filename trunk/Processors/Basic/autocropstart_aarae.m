function out = autocropstart_aarae(in,threshold,method)
% This function crops the first part of a sound recording, based on
% threshold conditions. In the case of multidimensional audio, this can be
% done for:
% * individual columns (each column processed independently) - in this case
%   a circular shift is performed after zeroing the audio before the
%   truncation point so that the length of each column is preserved.
% * all columns together, using an ensemble average wave to find the
%     truncation point
% * all columns together, using the earliest truncation point based on the
%     threshold criterion
%
% The threshold can be used in two ways:
% * a negative value is interpreted as a value in decibels relative to the
%       peak value (e.g. -20 dB relative to the peak).
% * a positive value is interpreted directly as a wave absolute amplitude 
%
% Code by Densil Cabrera
% version 1.00 (25 March 2014)

if isstruct(in)
    out = in;
    if nargin < 3
        prompt = {'IF NEGATIVE, Start truncation threshold below peak (in dB); OR IF POSITIVE, threshold amplitude of wave (not in dB)';...
            'Individual audio column truncation [1], Synchronous truncation using ensemble data [2], or Synchronous truncation using smallest truncation point from individual columns [3]'};
        dlg_title = 'Autocrop start';
        num_lines = 1;
        def = {'-20','2'};
        answer = inputdlg(prompt,dlg_title,num_lines,def);
        threshold = str2double(char(answer{1,1}));
        method = str2double(char(answer{2,1}));
    end
else
    %in.audio = in;
    disp('autocropstart_aarae requires a structure as input 1')
    out = [];
    return
end


if ~isempty(answer)
    [len,chans,bands,dim4,dim5,dim6] = size(in.audio);
    switch method
        case 1
            % individual start truncation (with loss of synchrony)
            for ch = 1:chans
                for b = 1:bands
                    for d4 = 1:dim4
                        for d5 = 1:dim5
                            for d6 = 1:dim6
                                if threshold <= 0
                                    threshind = find(abs(in.audio(:,ch,b,d4,d5,d6))...
                                        >= max(abs(in.audio(:,ch,b,d4,d5,d6))) ...
                                        .* 10.^(threshold/20),...
                                        1,'first');
                                else
                                    threshind = find(abs(in.audio(:,ch,b,d4,d5,d6))...
                                        >= threshold,1,'first');
                                end
                                if ~isempty(threshind)
                                    if threshind > 1 && threshind < len
                                        in.audio(1:threshind-1,ch,b,d4,d5,d6) = 0;
                                        in.audio(:,ch,b,d4,d5,d6) = ...
                                            circshift(in.audio(:,ch,b,d4,d5,d6)...
                                            ,-(threshind-1));
                                    end
                                end
                            end
                        end
                    end
                end
            end
            out.audio = in.audio;
        case 2
            % use mixed signal to find truncation point
            mixed = mean(mean(mean(mean(mean(in.audio,6),5),4),3),2);
            if threshold <= 0
                threshind = find(abs(mixed) >= max(abs(mixed))...
                    .* 10.^(threshold/20),1,'first');
            else
                threshind = find(abs(mixed) >= threshold,1,'first');
            end
            if ~isempty(threshind)
                if threshind > 1 && threshind <len
                    out.audio = in.audio(threshind:end,:,:,:,:,:);
                end
            end
            
        case 3
            % find threshold index in each column, but use the smallest one
            % for all the columns
            threshind = len;
            for ch = 1:chans
                for b = 1:bands
                    for d4 = 1:dim4
                        for d5 = 1:dim5
                            for d6 = 1:dim6
                                if threshold <= 0
                                    threshindnew = find(abs(in.audio(:,ch,b,d4,d5,d6))...
                                        >= max(abs(in.audio(:,ch,b,d4,d5,d6))) ...
                                        .* 10.^(threshold/20),...
                                        1,'first');
                                else
                                    threshindnew = find(abs(in.audio(:,ch,b,d4,d5,d6))...
                                        >= threshold,1,'first');
                                end
                                if ~isempty(threshindnew)
                                    if threshindnew < threshind
                                        threshind = threshindnew;
                                    end
                                end
                                
                            end
                        end
                    end
                end
            end
            
            if threshind > 1 && threshind <=len
                out.audio = in.audio(threshind:end,:,:,:,:,:);
            end
            
    end
    
    
    out.funcallback.name = 'autocropstart_aarae.m';
    out.funcallback.inarg = {threshold,method};
else
    out = [];
end

end