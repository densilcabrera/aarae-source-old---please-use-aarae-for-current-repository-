function OUT = choose_from_higher_dimensions(IN,maxdim,method)
% This AARAE utility function addresses the difficulty of having up to
% 6-dimensional audio data but analysers (and perhaps processors) that are
% only capable of dealing with a smaller number of dimensions.
%
% The input argument maxdim is the maximum number of output dimensions;
% The input argument IN is either an AARAE audio structure or audio as a
% vector or matrix. The format of OUT is the same as the format of IN.
%
% In AARAE, dimension 1 is used for time, dimension 2 for channels,
% dimension 3 for bands, dimension 4 for cycles (from multicycle audio test
% signals), dimension 5 for output channels of multicycle sequential output
% (e.g., measuring a series of loudspeakers, one by one), and dimension 6
% does not have a defined role, but is supported in many parts of AARAE.
%
% However, many analysers are not suitable for analysing 6-dimensional
% data, and may be better suited to analysing a subset.
%
% If the number of dimensions of the intput audio is less than or equal to
% maxdim, then the input is returned to the output without any change.
% Otherwise either a dialog box is used for user selection, or if method==0
% then only the first index in each higher dimension is chosen.


% default settings
if ~exist('method','var')
    method = 1;
end


if ~exist('maxdim','var')
    maxdim = 1;
end



% interpret input
if isstruct(IN)
    audio = IN.audio;
    
    if isfield(IN,'chanID')
        chanID = IN.chanID;
    end
    
    if isfield(IN,'cal')
        cal = IN.cal;
    end
    
    if isfield(IN,'bandID')
        bandID = IN.bandID;
    end
    
    if isfield(IN,'properties')
        if isfield(IN.properties,'startflag')
            startflag = IN.properties.startflag;
        end
        if isfield(IN.properties,'relgain')
            relgain = IN.properties.relgain;
        end
    end
    
else
    audio = IN;
end



% Return output to input if there is nothing to do
Sz = size(audio);
if length(Sz) <= maxdim
    OUT = IN;
    return
end
if maxdim == 1 && Sz(2) == 1
    OUT = IN;
    return
end
    

% If we get here, then we do need to do something
nonsingleton = Sz>1; % non singleton dimensions
nonsingleton = [nonsingleton,zeros(1,6-length(Sz))];
nonsingleton(1:maxdim) = 0; % don't worry about dims >= maxdim
numberofdimstochange = sum(nonsingleton);
if method == 0
    % take the first index of each excess dimension
    if nonsingleton(2)
        audio = audio(:,1,:,:,:,:);
        if exist('chanID','var')
            chanID = chanID{1};
        end
        if exist('cal','var')
            cal = cal(1);
        end
    end
    if nonsingleton(3)
        audio = audio(:,:,1,:,:,:);
        if exist('bandID','var')
            bandID = bandID(1);
        end
    end
    if nonsingleton(4)
        audio = audio(:,:,:,1,:,:);
        if exist('startflag','var')
            startflag = startflag(1);
        end
        if exist('relgain','var')
            relgain = relgain(1);
        end
    end
    if nonsingleton(5)
        audio = audio(:,:,:,:,1,:);
    end
    if nonsingleton(6)
        audio = audio(:,:,:,:,:,1);
    end
elseif method ==-1
    % reshape the audio into channels (not implemented yet)
else % method = 1 (or anything else)
    % prompt user for choice of indices in higher dimensions
    prompt = cell(1,numberofdimstochange);
    def = repmat({'1'},[1,numberofdimstochange]);
    dlgtitle = 'Please select one index from each higher dimension';
    m=1;
    if nonsingleton(2)
        prompt{1,m} = ['Select one channel (1-',num2str(size(audio,2)),')'];
        m=m+1;
    end
    if nonsingleton(3)
        prompt{1,m} = ['Select one band (1-',num2str(size(audio,3)),')'];
        m=m+1;
    end
    if nonsingleton(4)
        prompt{1,m} = ['Select one dim4 index (1-',num2str(size(audio,4)),')'];
        m=m+1;
    end
    if nonsingleton(5)
        prompt{1,m} = ['Select one dim5 index (1-',num2str(size(audio,5)),')'];
        m=m+1;
    end
    if nonsingleton(6)
        prompt{1,m} = ['Select one dim6 index (1-',num2str(size(audio,6)),')'];
    end
    answer = inputdlg(prompt,dlgtitle,[1 90],def); 
    m=1;
    if nonsingleton(2)
        if isempty(answer{m})
            selection = 1;
        else
            selection = str2double(answer{m});
        end
        audio = audio(:,selection,:,:,:,:);
        if exist('chanID','var')
            chanID = chanID{selection};
        end
        if exist('cal','var')
            cal = cal(selection);
        end
        m=m+1;
    end
    if nonsingleton(3)
        if isempty(answer{m})
            selection = 1;
        else
            selection = str2double(answer{m});
        end
        audio = audio(:,:,selection,:,:,:);
        if exist('bandID','var')
            bandID = bandID(selection);
        end
        m=m+1;
    end
    if nonsingleton(4)
        if isempty(answer{m})
            selection = 1;
        else
            selection = str2double(answer{m});
        end
        audio = audio(:,:,:,selection,:,:);
        if exist('startflag','var')
            startflag = startflag(selection);
        end
        if exist('relgain','var')
            relgain = relgain(selection);
        end
        m=m+1;
    end
    if nonsingleton(5)
        if isempty(answer{m})
            selection = 1;
        else
            selection = str2double(answer{m});
        end
        audio = audio(:,:,:,:,selection,:);
        m=m+1;
    end
    if nonsingleton(6)
        if isempty(answer{m})
            selection = 1;
        else
            selection = str2double(answer{m});
        end
        audio = audio(:,:,:,:,:,selection);
    end
end



% Provide output
if isstruct(IN)
    OUT = IN;
    OUT.audio = audio;
    if exist('chanID','var')
        OUT.chanID = chanID;
    end
    if exist('cal','var')
        OUT.cal = cal;
    end
    if exist('bandID','var')
        OUT.bandID = bandID;
    end
    if exist('startflag','var')
        OUT.properties.startflag = startflag;
    end
    if exist('relgain','var')
        OUT.properties.relgain = relgain;
    end
else
    OUT = audio;
end