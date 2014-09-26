function OUT = sphereplotfromMics(IN)
% This function creates a spherical polar plot based on measurements
%
% The input must have chanID data that identifies the position of each
% microphone. These chanIDs can be created using AARAE's

if isstruct(IN)
    audio = IN.audio;
    fs = IN.fs;
    if isfield(IN,'chanID')
        [coords,format] = readchanID(IN.chanID);
        if format ~= 2 && format ~= 3 && format ~= 4
            warndlg('ChanID is not in the correct format for this function')
            OUT = [];
            return
        end
    end
    % reset cal to 0 dB if it exists (this should already have been done by
    % the processor)
    if isfield(IN,'cal')
        audio = cal_reset_aarae(audio,94,IN.cal);
    end
else
    OUT = [];
    return
end

% values to plot
values = permute(rms(audio),[2,3,1]);

% spherical coordinates
[az,el] = cart2sph(coords(:,1),coords(:,2),coords(:,3));

% coordinates on a unit sphere
[x,y,z] = sph2cart(az,el,ones(length(az),1));

% indices for meshing
K = convhulln([x,y,z]);



% Find points that are far enough apart to require interpolation of values,
% and interpolate, using a maximum of two iterations
for it = 1:2
    originalxyzlen = length(x);
    
    % find 'distances' between adjacent points
    d1 = ((x(K(:,1)) - x(K(:,2))).^2 ...
        + (y(K(:,1)) - y(K(:,2))).^2 ...
        + (z(K(:,1)) - z(K(:,2))).^2).^0.5;
    
    d2 = ((x(K(:,3)) - x(K(:,2))).^2 ...
        + (y(K(:,3)) - y(K(:,2))).^2 ...
        + (z(K(:,3)) - z(K(:,2))).^2).^0.5;
    
    d3 = ((x(K(:,1)) - x(K(:,3))).^2 ...
        + (y(K(:,1)) - y(K(:,3))).^2 ...
        + (z(K(:,1)) - z(K(:,3))).^2).^0.5;
    
    if it == 1
        % percentile threshold (only calculate on first iteration)
        percentilethreshold = 90; % to become a user input
        dthresh = prctile([d1;d2;d3],percentilethreshold);
    end
    d1ind = find(d1 > dthresh);
    d2ind = find(d2 > dthresh);
    d3ind = find(d3 > dthresh);
    
    % interpolate between points
    for n = 1:length(d1ind)
        x = [x;mean([x(K(d1ind(n),1)),x(K(d1ind(n),2))])];
        y = [y;mean([y(K(d1ind(n),1)),y(K(d1ind(n),2))])];
        z = [z;mean([z(K(d1ind(n),1)),z(K(d1ind(n),2))])];
    end
    for n = 1:length(d2ind)
        x = [x;mean([x(K(d2ind(n),3)),x(K(d2ind(n),2))])];
        y = [y;mean([y(K(d2ind(n),3)),y(K(d2ind(n),2))])];
        z = [z;mean([z(K(d2ind(n),3)),z(K(d2ind(n),2))])];
    end
    for n = 1:length(d3ind)
        x = [x;mean([x(K(d3ind(n),1)),x(K(d3ind(n),3))])];
        y = [y;mean([y(K(d3ind(n),1)),y(K(d3ind(n),3))])];
        z = [z;mean([z(K(d3ind(n),1)),z(K(d3ind(n),3))])];
    end
    
    % recreate the spherical mesh with the interpolated points
    [az,el] = cart2sph(x,y,z);
    [x,y,z] = sph2cart(az,el,ones(length(az),1));
    K = convhulln([x,y,z]);
    
    
    % extend values with the interpolated values
    if originalxyzlen < length(x)
        values = [values;...
            zeros((length(x)-length(values)),size(values,2))];
        for n = (originalxyzlen+1):length(x)
            % for each new coordinate, find all of its neighbours
            [r,c] = find(K == n);
            % find the distances between it and known values
            neighborvals = NaN(length(r),2,size(values,2));
            neighbordist = NaN(length(r),2);
            for m = 1:length(r)
                if K(r(m),1+mod(c(m),3)) <= originalxyzlen+n-1
                    neighborvals(m,1,:) = values(K(r(m),1+mod(c(m),3)),:);
                    neighbordist(m,1) = ((x(n)-x(K(r(m),1+mod(c(m),3)))).^2 ...
                        + (y(n)-y(K(r(m),1+mod(c(m),3)))).^2 ...
                        + (z(n)-z(K(r(m),1+mod(c(m),3)))).^2).^0.5;
                end
                if K(r(m),1+mod(c(m)+1,3)) <= originalxyzlen+n-1
                    neighborvals(m,2,:) = values(K(r(m),1+mod(c(m)+1,3)),:);
                    neighbordist(m,2) = ((x(n)-x(K(r(m),1+mod(c(m)+1,3)))).^2 ...
                        + (y(n)-y(K(r(m),1+mod(c(m)+1,3)))).^2 ...
                        + (z(n)-z(K(r(m),1+mod(c(m)+1,3)))).^2).^0.5;
                end
            end
            neighborvals = permute([neighborvals(:,1,:);neighborvals(:,2,:)],[1,3,2]);
            neighbordist = [neighbordist(:,1);neighbordist(:,2)];
            idx = ~isnan(neighbordist);
            neighbordist = neighbordist(idx);
            neighborvals = neighborvals(idx,:);
            idx = neighborvals(:,1) > 0;
            neighbordist = neighbordist(idx);
            neighborvals = neighborvals(idx,:);
            neighborinvdist = 1./neighbordist.^2;
          %  values(n,:) = mean(neighborvals);
            values(n,:) = (sum(neighborvals.^2 .* repmat(neighborinvdist,[1,size(values,2)]))...
                ./sum(repmat(neighborinvdist,[1,size(values,2)]))).^0.5;
        end
    end  
end






for b = 1:size(values,2)
    % Cartesian coordinates with values
    [x,y,z] = sph2cart(az,el,values(:,b));
    
    
    % PLOT
    figure
    
    trisurf(K,x,y,z,values(:,b),'FaceColor','interp','FaceLighting','phong',...
        'EdgeLighting','phong','DiffuseStrength',1,'EdgeAlpha',0.1,...
        'AmbientStrength',0.6);
    camlight right
    colormap(autumn)
    hold on
    % plot axis poles
    polelength = 1.1*max(max(abs([x;y;z])));
    plot3([0,0],[0,0],[-polelength, polelength],'LineWidth',2,'Color',[0.8,0.8,0]);
    plot3([0,0],[0,0],[-polelength, polelength],'LineWidth',2,'Color',[0,0,0],'LineStyle','--','Marker','^');
    
    plot3([0,0],[-polelength, polelength],[0,0],'LineWidth',2,'Color',[0.8,0.8,0]);
    plot3([0,0],[-polelength, polelength],[0,0],'LineWidth',2,'Color',[0,0,0],'LineStyle','--','Marker','>');
    
    plot3([-polelength, polelength],[0,0],[0,0],'LineWidth',2,'Color',[0.8,0.8,0]);
    plot3([-polelength, polelength],[0,0],[0,0],'LineWidth',2,'Color',[0,0,0],'LineStyle','--','Marker','>');
    
    grid on
    xlabel('x')
    ylabel('y')
    zlabel('z')
    set(gca, 'DataAspectRatio', [1 1 1])
    set(gca, 'PlotBoxAspectRatio', [1 1 1])
    
    if isfield(IN,'bandID')
        title([num2str(IN.bandID(b)), ' Hz'])
    else
        title(['Band ', num2str(b)])
    end
    
end
OUT.funcallback.name = 'sphereplotfromMics.m';
OUT.funcallback.inarg = {};
