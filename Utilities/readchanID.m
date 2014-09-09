function out = readchanID(chanID)
% This aarae utility function extracts the numerical data from chanIDs,
% assuming that they are in one of the formats supported by makechanID

if ~isempty(regexp(char(chanID{1}),'Chan','once'))
    % generic chanID in the form of 'Chan1', 'Chan2', etc
    out = zeros(length(chanID),1);
    for n = 1:length(chanID)
        out(n) = regexp(chanID{n},'-?\d+\.?\d*|-?\d*\.?\d+','match');
    end
    
elseif ~isempty(regexp(char(chanID{1}),'Y','once'))
    % Spherical harmonic chanIDs, showing order and degree (e.g., for 
        % HOA signals)
    out = zeros(length(chanID),2);
    for n = 1:length(chanID)
        cellval = regexp(chanID{n},'-?\d+\.?\d*|-?\d*\.?\d+','match');
        out(n,:) = [str2double(cellval{1,1}),str2double(cellval{1,2})];
    end
    
elseif ~isempty(regexp(char(chanID{1}),'deg','once'))
    % chanID using spherical coordinates in degrees (az,elev,radius)
    % but output of this function is always Cartesian
    out = zeros(length(chanID),3);
    for n = 1:length(chanID)
        cellval = regexp(chanID{n},'-?\d+\.?\d*|-?\d*\.?\d+','match');
        out(n,:) = [str2double(cellval{1,1}),str2double(cellval{1,2}) ...
            ,str2double(cellval{1,3})];
    end
    out(:,1:2) = out(:,1:2) * pi/180;
    [out(:,1),out(:,2),out(:,3)] = sph2cart(out(:,1),out(:,2),out(:,3));
    
elseif ~isempty(regexp(char(chanID{1}),'rad','once'))
    % chanID using spherical coordinates in radians (az,elev,radius)
    % but output of this function is always Cartesian
    out = zeros(length(chanID),3);
    for n = 1:length(chanID)
        cellval = regexp(chanID{n},'-?\d+\.?\d*|-?\d*\.?\d+','match');
        out(n,:) = [str2double(cellval{1,1}),str2double(cellval{1,2}) ...
            ,str2double(cellval{1,3})];
    end    
    [out(:,1),out(:,2),out(:,3)] = sph2cart(out(:,1),out(:,2),out(:,3));
    
elseif ~isempty(regexp(char(chanID{1}),'m','once'))
    % chanID using Cartesian coordinates (x,y,z)
    out = zeros(length(chanID),3);
    for n = 1:length(chanID)
        cellval = regexp(chanID{n},'-?\d+\.?\d*|-?\d*\.?\d+','match');
        out(n,:) = [str2double(cellval{1,1}),str2double(cellval{1,2}) ...
            ,str2double(cellval{1,3})];
    end
    
else
    out = [];
        
end