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



% spherical coordinates
[az,el] = cart2sph(coords(:,1),coords(:,2),coords(:,3));

% coordinates on a unit sphere
[x,y,z] = sph2cart(az,el,ones(length(az),1));

% indices for meshing
K = convhulln([x,y,z]);

% values to plot
values = rms(audio);

for b = 1:size(values,3)
    % Cartesian coordinates with values
    [x,y,z] = sph2cart(az,el,permute(values(:,:,b),[2,1]));
    
    
    % PLOT
    figure
    
    trisurf(K,x,y,z,permute(values(:,:,b),[2,1]),'FaceColor','interp','FaceLighting','phong',...
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
end
OUT = [];
