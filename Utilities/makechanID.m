function chanID = makechanID(nchan,format,param)
% This aarae utility function makes a chanID cell array for the specified
% number of channels (nchan) and format. If channels spatial coordiates are
% used, these are provided by the third input argument, which must be at 
% least as long as the number of channels. See comments in the code.
switch format
    case 0
        % generic chanID in the form of 'Chan1', 'Chan2', etc
        chanID = cellstr([repmat('Chan',[nchan,1]) num2str((1:nchan)')]);
    case 1
        % Spherical harmonic chanIDs, showing order and degree (e.g., for 
        % HOA signals)

        HOA_order = floor(nchan.^0.5)-1;
        if nchan == (HOA_order+1)^2
            hoaFmt = GenerateHoaFmt('res2d',HOA_order,'res3d',HOA_order);
            chanID = cellstr([repmat('Y ',[nchan,1]),num2str(hoaFmt.index)]);
        else
            chanID = [];
        end
    case 2
        % chanID using spherical coordinates in degrees
        % param is a list Cartesian coordinates for each channel in the
        % form [x1,y1,z1; x2,y2,z2;...]
        if length(param)<nchan
            disp('Unable to make chanIDs from param due to channel count mismatch')
            chanID = cellstr([repmat('Chan',[nchan,1]) num2str((1:nchan)')]);
        else
        [param(:,1),param(:,2),param(:,3)] =...
            cart2sph(param(:,1),param(:,2),param(:,3));
        param(:,1:2) = 180 * param(:,1:2)./pi;
        chanID = cellstr([num2str(param(:,1)),repmat(' deg, ',[length(param),1]),...
            num2str(param(:,2)),repmat(' deg, ',[length(param),1]),...
            num2str(param(:,3)),repmat(' m',[length(param),1])]);
        end
    case 3
        % chanID using spherical coordinates in radians
        % param is a list Cartesian coordinates for each channel in the
        % form [x1,y1,z1; x2,y2,z2;...]
        if length(param)<nchan
            disp('Unable to make chanIDs from param due to channel count mismatch')
            chanID = cellstr([repmat('Chan',[nchan,1]) num2str((1:nchan)')]);
        else
        [param(:,1),param(:,2),param(:,3)] =...
            cart2sph(param(:,1),param(:,2),param(:,3));
        chanID = cellstr([num2str(param(:,1)),repmat(' rad, ',[length(param),1]),...
            num2str(param(:,2)),repmat(' rad, ',[length(param),1]),...
            num2str(param(:,3)),repmat(' m',[length(param),1])]);
        end
    case 4
        % chanID using Cartesian coordinates in metres
        % param is a list Cartesian coordinates for each channel in the
        % form [x1,y1,z1; x2,y2,z2;...]
        if length(param)<nchan
            disp('Unable to make chanIDs from param due to channel count mismatch')
            chanID = cellstr([repmat('Chan',[nchan,1]) num2str((1:nchan)')]);
        else
        chanID = cellstr([num2str(param(:,1)),repmat(' m, ',[length(param),1]),...
            num2str(param(:,2)),repmat(' m, ',[length(param),1]),...
            num2str(param(:,3)),repmat(' m',[length(param),1])]);
        end
end